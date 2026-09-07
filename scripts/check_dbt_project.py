#!/usr/bin/env python3
"""Check the invariants the week4 dbt project has to hold to run in Snowflake.

Every rule below is here because it FAILED for real, inside Snowflake, in a way
`dbt compile` did not catch. Compiling only renders SQL; the first command that
touches the warehouse is `run`. So a checker that runs on the files is the only
thing standing between a bad edit and a broken class.

    python3 scripts/check_dbt_project.py

Exits non-zero if anything fails, so it can go in a pre-commit hook.

THE TARGET RUNTIME IS dbt 1.9.4 / dbt-snowflake 1.9.2 -- confirmed by running
`compile` in a Snowflake Workspace. That version is older than the dbt on a
current laptop, and several rules exist only because of the gap.

WHAT IT DELIBERATELY DOES NOT CHECK
-----------------------------------
Whether the models are CORRECT. That needs a warehouse with the raw tables
loaded. This checks the things that break before any SQL runs, plus the two
Snowflake-side preconditions (ownership, and build-vs-run) that are documented
in the notebook rather than enforceable from here.
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = os.path.join(REPO, "week4_day2_afternoon", "dbt-project", "demo")

failures = []


def fail(msg):
    failures.append(msg)
    print("  FAIL  " + msg)


def rel(path):
    return os.path.relpath(path, PROJECT)


def walk(*exts):
    for dirpath, dirnames, filenames in os.walk(PROJECT):
        dirnames[:] = [d for d in dirnames
                       if d not in ("target", "logs", "dbt_packages")]
        for name in sorted(filenames):
            if name.endswith(exts):
                yield os.path.join(dirpath, name)


# ---------------------------------------------------------------- 1. layout
def check_layout():
    """dbt_project.yml must sit at the project ROOT.

    CREATE DBT PROJECT / a Workspace points at one prefix and looks for
    dbt_project.yml directly inside it. Nested one level deeper, Snowflake
    reports no project at all.
    """
    required = ["dbt_project.yml", "profiles.yml", "packages.yml"]
    for f in required:
        if not os.path.isfile(os.path.join(PROJECT, f)):
            fail("%s is missing from the project root" % f)

    for d in ["models", "macros", "seeds", "snapshots", "tests"]:
        if not os.path.isdir(os.path.join(PROJECT, d)):
            fail("directory %s/ is missing" % d)


# ------------------------------------------------- 2. generic test arguments
def check_test_arguments():
    """Test parameters must be TOP-LEVEL, not nested under `arguments:`.

    dbt 1.12 wants the nested form and deprecation-warns the flat one. dbt
    1.9.4 -- what Snowflake runs -- rejects the nested form outright:

        macro 'dbt_macro__test_accepted_values' takes no keyword argument
        'arguments'

    A warning is survivable; an error is not. The flat form works on both.
    """
    for path in walk(".yml"):
        for n, line in enumerate(open(path), 1):
            if re.match(r"^\s*arguments:\s*$", line.rstrip("\n")):
                fail("%s:%d nests test parameters under `arguments:` -- "
                     "dbt 1.9.4 in Snowflake rejects this; write them at the "
                     "top level" % (rel(path), n))


# ------------------------------------------------------------- 3. packages
def check_packages():
    """packages.yml must not list a package unless dbt_packages/ is present.

    Code inside Snowflake has no outbound internet by default, so `dbt deps`
    cannot reach the dbt Hub. A listed-but-uninstalled package fails EVERY dbt
    command before it runs anything:

        dbt found 2 package(s) specified in packages.yml, but only 0
        package(s) installed in dbt_packages.
    """
    path = os.path.join(PROJECT, "packages.yml")
    if not os.path.isfile(path):
        return
    listed = [n for n, line in enumerate(open(path), 1)
              if re.match(r"^\s*-\s*(package|git|local)\s*:", line)]
    if listed and not os.path.isdir(os.path.join(PROJECT, "dbt_packages")):
        fail("packages.yml declares %d package(s) at line(s) %s but "
             "dbt_packages/ is not vendored -- every dbt command will fail "
             "inside Snowflake. Either leave packages.yml empty or upload "
             "dbt_packages/ with the project."
             % (len(listed), ", ".join(map(str, listed))))


# ------------------------------------------------------------- 4. profiles
def check_profiles():
    """The uploaded profiles.yml must carry NO credentials.

    Running inside Snowflake, dbt authenticates as the role that executes the
    project. An `account:` key is not merely redundant -- profiles.example.yml
    exists for the laptop case, and must not be the one uploaded.
    """
    path = os.path.join(PROJECT, "profiles.yml")
    if not os.path.isfile(path):
        return
    for n, line in enumerate(open(path), 1):
        if line.lstrip().startswith("#"):
            continue
        key = re.match(r"^\s*(account|user|password|private_key\w*)\s*:", line)
        if key:
            fail("profiles.yml:%d sets `%s` -- the uploaded profile must have "
                 "no credentials; the executing role is the identity"
                 % (n, key.group(1)))


# --------------------------------------------------- 5. Jinja inside comments
def check_jinja_in_comments():
    """No live Jinja tags inside comment lines.

    dbt renders EVERY file as a Jinja template BEFORE parsing it, and does not
    skip `--` or `#` comments. A loop tag written in a comment opens a
    control-flow block and takes the whole project down with

        Compilation Error: Got a block definition inside control flow

    Describe Jinja in words in comments; use it for real in values.
    """
    for path in walk(".sql", ".yml", ".md"):
        for n, line in enumerate(open(path), 1):
            s = line.lstrip()
            if not (s.startswith("--") or s.startswith("#")):
                continue
            if re.search(r"\{%-?\s*(if|for|macro|snapshot|set|endif|endfor)\b", line):
                fail("%s:%d has a live Jinja block tag inside a comment -- dbt "
                     "renders comments too; spell the tag out in words"
                     % (rel(path), n))


# ------------------------------------------------------------ 6. yaml parses
def check_yaml():
    try:
        import yaml
    except ImportError:
        print("  SKIP  pyyaml not installed; not validating YAML syntax")
        return
    for path in walk(".yml"):
        try:
            yaml.safe_load(open(path))
        except Exception as exc:
            fail("%s is not valid YAML: %s" % (rel(path), str(exc)[:90]))


# --------------------------------------------------------- 7. no build output
def check_no_build_output():
    """target/ and logs/ must not be committed -- they are per-run artefacts and
    would be uploaded to the stage along with everything else."""
    for d in ("target", "logs", "dbt_packages"):
        p = os.path.join(PROJECT, d)
        if os.path.isdir(p) and d != "dbt_packages":
            fail("%s/ is present in the project -- build output should not be "
                 "committed or uploaded" % d)


def main():
    if not os.path.isdir(PROJECT):
        sys.exit("no dbt project at %s" % os.path.relpath(PROJECT, REPO))

    print("checking %s" % os.path.relpath(PROJECT, REPO))
    check_layout()
    check_yaml()
    check_test_arguments()
    check_packages()
    check_profiles()
    check_jinja_in_comments()
    check_no_build_output()

    n_models = len(list(walk(".sql")))
    n_yml = len(list(walk(".yml")))
    print("  %d .sql, %d .yml" % (n_models, n_yml))

    print()
    if failures:
        print("FAILED -- %d problem(s)" % len(failures))
        sys.exit(1)
    print("all dbt project invariants hold")
    print()
    print("Reminders this cannot check from here:")
    print("  * the role in profiles.yml must OWN the target schemas, or every")
    print("    model fails with 'Insufficient privileges to operate on schema'.")
    print("    `compile` does not catch it; only `run` does.")
    print("  * use `build`, not `run` -- dim_product_t6 reads a snapshot, and")
    print("    `run` alone never builds snapshots.")
    print("  * RAW.PRODUCT and RAW.SALES must exist and be loaded first.")


if __name__ == "__main__":
    main()
