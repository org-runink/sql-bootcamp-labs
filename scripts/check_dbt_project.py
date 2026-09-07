#!/usr/bin/env python3
"""Check the invariants the week4 dbt project has to hold to run in Snowflake.

Every rule below is here because it FAILED for real, inside Snowflake, in a way
`dbt compile` did not catch. Compiling only renders SQL; the first command that
touches the warehouse is `run`. So a checker that runs on the files is the only
thing standing between a bad edit and a broken class.

    python3 scripts/check_dbt_project.py            # file rules only, no container
    python3 scripts/check_dbt_project.py --parse    # also run `dbt parse` in the console

Exits non-zero if anything fails, so it can go in a pre-commit hook.

--parse needs the sql-console-lan container up, with the project mounted (see
docker-compose.yml). It supplies a THROWAWAY profile inside the container,
because the project's committed profiles.yml is the credential-free one for
running inside Snowflake -- local dbt rejects it with

    Credentials in profile "demo", target "dev" invalid:
    'account' is a required property

which is correct, not a bug. Nothing is written into the repo.

THE TARGET RUNTIME IS dbt 1.9.4 / dbt-snowflake 1.9.2 -- confirmed by running
`compile` in a Snowflake Workspace. The console image has a NEWER dbt, so
--parse catches structural errors but will happily accept things Snowflake
rejects; the file rules above are what encode the version gap.

WHAT IT DELIBERATELY DOES NOT CHECK
-----------------------------------
Whether the models are CORRECT. That needs a warehouse with the raw tables
loaded. This checks the things that break before any SQL runs, plus the
Snowflake-side preconditions (ownership, build-vs-run) reported at the end.
"""

import argparse
import os
import re
import subprocess
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
    """Build output must never be COMMITTED, and must not be uploaded.

    Running dbt locally drops target/ and logs/ beside the project. That is
    harmless as long as git ignores them -- so this fails only when they would
    actually be committed, and otherwise just reminds you to leave them out of
    the upload.
    """
    for d in ("target", "logs", "dbt_packages"):
        p = os.path.join(PROJECT, d)
        if not os.path.isdir(p):
            continue
        ignored = subprocess.run(["git", "check-ignore", "-q", p],
                                 cwd=REPO, capture_output=True).returncode == 0
        if ignored:
            print("  note  %s/ exists locally (git-ignored) -- do not include "
                  "it in the upload" % d)
        else:
            fail("%s/ is present and NOT git-ignored -- build output must not "
                 "be committed" % d)


CONTAINER = "sql-console-lan"
MOUNT = "/home/jovyan/work/week4_dbt_project/demo"   # per docker-compose.yml

# A throwaway profile, written inside the container only. The project's own
# profiles.yml is credential-free for running inside Snowflake, which local dbt
# will not accept -- it requires `account` even to parse.
THROWAWAY = """demo:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: none
      user: none
      password: none
      role: SYSADMIN
      database: DEMO_DB
      warehouse: COMPUTE_WH
      schema: dev
      threads: 4
"""


def check_parse():
    """Run `dbt parse` against the mounted project, in the console container."""
    probe = subprocess.run(["podman", "exec", CONTAINER, "test", "-f",
                            MOUNT + "/dbt_project.yml"], capture_output=True)
    if probe.returncode != 0:
        fail("--parse: %s is not reachable in %s. Is the container up, and was "
             "it RECREATED after the mount was added? A bind mount keeps "
             "pointing at a deleted inode, so a restart is not enough:\n"
             "        podman rm -f --depend %s && podman-compose up -d"
             % (MOUNT, CONTAINER, CONTAINER))
        return

    # Heredoc rather than string formatting: the profile is multi-line YAML and
    # the shell command contains printf-style tokens, so % formatting mangles
    # both. `dbt parse`'s exit code is captured before the cleanup runs.
    script = f"""
d=$(mktemp -d)
cat > "$d/profiles.yml" <<'PROFILE_EOF'
{THROWAWAY}PROFILE_EOF
cd {MOUNT} || exit 9
# --target-path / --log-path keep dbt's artefacts in the temp dir, so parsing
# leaves no target/ or logs/ inside the mounted (and version-controlled) project.
dbt parse --profiles-dir "$d" --target-path "$d/target" --log-path "$d/logs" 2>&1
rc=$?
rm -rf "$d"
exit $rc
"""
    r = subprocess.run(["podman", "exec", CONTAINER, "bash", "-lc", script],
                       capture_output=True, text=True)
    out = re.sub(r"\x1b\[[0-9;]*m", "", r.stdout + r.stderr)

    for line in out.splitlines():
        if re.search(r"Found \d+ model|Compilation Error|Runtime Error|\[ERROR\]", line):
            print("    " + line.strip()[:110])

    if r.returncode != 0:
        fail("--parse: dbt parse failed inside %s (rc=%d). Full output:\n%s"
             % (CONTAINER, r.returncode, "\n".join("        " + l
                                                   for l in out.splitlines()[-8:])))
    else:
        print("  dbt parse: clean (dbt in the image is NEWER than Snowflake's "
              "1.9.4, so this does not prove 1.9.4 compatibility)")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--parse", action="store_true",
                    help="also run `dbt parse` in the %s container" % CONTAINER)
    args = ap.parse_args()

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
    if args.parse:
        check_parse()

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
