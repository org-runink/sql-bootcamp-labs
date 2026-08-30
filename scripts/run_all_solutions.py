#!/usr/bin/env python3
"""Execute every published solution notebook and report anything that CHANGED.

check_exercises.py reads the notebooks. This one runs them, in the lab image,
and is the only check that can catch a solution that stopped working -- a cell
that now raises, a data file that moved, a pandas behaviour that shifted under
a version bump.

    python3 scripts/run_all_solutions.py                  # compare to baseline
    python3 scripts/run_all_solutions.py --update-baseline # re-record it

Takes about fifteen minutes. Run it before a class, after a dependency change,
or after touching shared data.

WHY A BASELINE, AND NOT "ERRORS ARE BAD"
----------------------------------------
Many solutions END IN A DELIBERATE ERROR, because the error is the lesson --
assigning to a tuple, `int("twelve")`, a merge that fails validation. The
count differs per class: week2_day4_afternoon documents eleven of them, and
they are NOT in the last cell.

So "any error is a regression" is wrong, and "the error must be in the last
cell" is also wrong -- it holds for the generated week3 sheets and not for the
hand-written week2 ones. The honest model is a recorded baseline of how many
errors each notebook currently produces. A CHANGE is the signal; a count is
not.

The baseline lives in scripts/solution_errors.json. When you deliberately add
or remove a raising question, re-record it in the same commit.

WHAT IT SKIPS
-------------
wcd-originals/ -- the WeCloudData vendor notebooks read their data from S3 over
the network, so their result depends on the internet rather than on this repo.
Run those by hand.
"""

import argparse
import json
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASELINE = os.path.join(REPO, "scripts", "solution_errors.json")
CONTAINER = "sql-console-lan"
INNER = "/tmp/_run_all_solutions_inner.py"

# Executed inside the container, where SOLUTIONS/ carries each class's data/
# so the notebooks' relative paths resolve.
INNER_SRC = r'''
import json, os, subprocess, sys
ROOT = "/home/jovyan/work/SOLUTIONS"
SKIP = {"wcd-originals", ".ipynb_checkpoints", "data", "bronze",
        "more-practice-data"}
result = {}
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = sorted(d for d in dirnames if d not in SKIP)
    for name in sorted(filenames):
        if not name.endswith(".ipynb") or "__exec" in name:
            continue
        path = os.path.join(dirpath, name)
        rel = os.path.relpath(path, ROOT)
        out = path.replace(".ipynb", ".__exec.ipynb")
        subprocess.run(["jupyter", "nbconvert", "--to", "notebook", "--execute",
                        "--allow-errors", "--output", out, path],
                       capture_output=True, text=True, cwd=dirpath)
        if not os.path.exists(out):
            result[rel] = None          # could not execute at all
            continue
        nb = json.load(open(out))
        result[rel] = sum(1 for c in nb["cells"] if c["cell_type"] == "code"
                          for o in c["outputs"] if o["output_type"] == "error")
        os.remove(out)
        sys.stderr.write(".")
        sys.stderr.flush()
print(json.dumps(result))
'''


def run_in_container():
    inner = os.path.join(REPO, "scripts", ".inner.tmp.py")
    with open(inner, "w") as fh:
        fh.write(INNER_SRC)
    try:
        subprocess.run(["podman", "cp", inner, "%s:%s" % (CONTAINER, INNER)],
                       check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        os.remove(inner)
        sys.exit("could not reach container %s: %s" % (CONTAINER, exc))
    os.remove(inner)

    print("executing every solution notebook in %s (this takes ~15 min)"
          % CONTAINER)
    r = subprocess.run(["podman", "exec", CONTAINER, "python3", INNER],
                       capture_output=True, text=True)
    subprocess.run(["podman", "exec", CONTAINER, "rm", "-f", INNER],
                   capture_output=True)
    print()
    if r.returncode != 0 or not r.stdout.strip():
        sys.exit("the run failed:\n%s" % r.stderr.strip()[-800:])
    return json.loads(r.stdout)


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--update-baseline", action="store_true",
                    help="re-record the expected error counts")
    args = ap.parse_args()

    actual = run_in_container()

    if args.update_baseline:
        with open(BASELINE, "w") as fh:
            json.dump(actual, fh, indent=1, sort_keys=True)
            fh.write("\n")
        raising = {k: v for k, v in actual.items() if v}
        print("baseline written: %d notebooks, %d of which end in a "
              "deliberate error" % (len(actual), len(raising)))
        return

    if not os.path.exists(BASELINE):
        sys.exit("no baseline yet -- run with --update-baseline first")
    expected = json.load(open(BASELINE))

    problems = []
    for rel in sorted(set(expected) | set(actual)):
        want, got = expected.get(rel, "absent"), actual.get(rel, "absent")
        if want == got:
            continue
        if got is None:
            problems.append((rel, "FAILED TO EXECUTE AT ALL"))
        elif want == "absent":
            problems.append((rel, "new notebook, %s error(s) -- record it" % got))
        elif got == "absent":
            problems.append((rel, "notebook is gone -- update the baseline"))
        else:
            problems.append((rel, "expected %s error(s), got %s" % (want, got)))

    print("%d notebooks executed" % len(actual))
    if not problems:
        print("every one matches the baseline")
        return
    print("\n%d DIFFER FROM BASELINE:" % len(problems))
    for rel, why in problems:
        print("  %-62s %s" % (rel, why))
    print("\nIf a change was deliberate, re-record with --update-baseline.")
    sys.exit(1)


if __name__ == "__main__":
    main()
