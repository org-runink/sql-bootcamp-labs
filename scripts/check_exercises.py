#!/usr/bin/env python3
"""Check the invariants every worksheet in this repo is supposed to hold.

Run it before committing, or before a class. It reads the notebooks on disk
and verifies the things that are easy to get wrong and invisible once wrong:

  1. every exercise has a matching solution
  2. no exercise ships with the answers in it -- code cells are stubs, and
     nothing has stored outputs or execution counts
  3. the solution has one code cell per question, plus the setup
  4. notebooks are nbformat 4.5 with this repo's normalised key order
  5. where a solution reads data/ by a RELATIVE path, that data is present
     and identical under solutions/, so the published copy still runs

    python3 scripts/check_exercises.py            # all classes
    python3 scripts/check_exercises.py week3_day2_afternoon # one class

Exits non-zero if anything fails, so it can go in a pre-commit hook.

WHAT IT DELIBERATELY DOES NOT CHECK
-----------------------------------
Whether the numbers quoted in a solution are correct. That cannot be done
from the files -- it needs the notebooks executed in the lab image and the
output compared against the prose. See the class READMEs for how each set
was verified.

The WeCloudData originals under wcd-originals/ are skipped throughout: they
are vendor files kept byte-identical and do not follow these conventions.
"""

import filecmp
import glob
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The two SQL classes use a different worksheet convention from the Python
# ones: a `%%sql` cell with blank space under a comment, rather than a
# `## Your Code Here` stub. Both are "an empty cell for the student"; they
# just look different, so the check has to know which to expect.
CLASSES = {
    "week2_day2_afternoon": "sql",
    "week2_day3_morning": "sql",
    "week2_day4_afternoon": "python",
    "week2_day5_morning": "python",
    "week3_day1_afternoon": "python",
    "week3_day2_afternoon": "python",
    "week3_day3_afternoon": "python",
    "week3_day4_morning": "python",
    "week3_recap": "python",
}

MD_KEYS = ["cell_type", "id", "metadata", "source"]
CODE_KEYS = ["cell_type", "execution_count", "id", "metadata", "outputs", "source"]
STUB_MARKER = "Your Code Here"
SKIP = ("wcd-originals", ".ipynb_checkpoints")

# Some worksheets have NO code cells, because there is nothing here that could
# run them: week3_day3_afternoon 01-02 need the student's own Snowflake account,
# and week3_day4_morning 11 is a pen-and-paper group design activity. An empty
# Python cell in either would be a trap. Their answer space is a markdown block,
# and a notebook with no code cells is recognised as this convention.
MD_STUB_MARKERS = ("Your query, and the result", "Your group's answer")

failures = []


def fail(msg):
    failures.append(msg)
    print("  FAIL  " + msg)


def notebooks(class_dir, kind):
    """Every generated notebook under <class>/<kind>/, recursively."""
    pattern = os.path.join(REPO, class_dir, kind, "**", "*.ipynb")
    return sorted(p for p in glob.glob(pattern, recursive=True)
                  if not any(s in p for s in SKIP))


def is_stub(cell, convention):
    """Is this code cell an empty space for the student to fill in?"""
    src = "".join(cell["source"])
    if convention == "python":
        return STUB_MARKER in src
    # SQL: a %%sql cell whose only content is comments -- the prompt is
    # written as `-- Your DDL for Challenge 1:` with blank space under it.
    if not src.lstrip().startswith("%%sql"):
        return False
    body = [ln.strip() for ln in src.replace("%%sql", "", 1).splitlines()]
    return all(ln == "" or ln.startswith("--") for ln in body)


def check_class(cls):
    convention = CLASSES[cls]
    ex = notebooks(cls, "exercises")
    so = notebooks(cls, "solutions")
    print("\n%s  (%d exercises, %d solutions)" % (cls, len(ex), len(so)))

    if not ex:
        fail("%s: no exercise notebooks found" % cls)
        return

    # 1 + 3: pairing, and one solution cell per question
    for e in ex:
        want = e.replace("/exercises/", "/solutions/").replace(".ipynb", "_solution.ipynb")
        rel = os.path.relpath(e, REPO)
        if not os.path.exists(want):
            fail("%s has no solution" % rel)
            continue

        enb, snb = json.load(open(e)), json.load(open(want))
        if not any(c["cell_type"] == "code" for c in enb["cells"]):
            # Markdown-only worksheet: the answer space is a markdown block, and
            # the solution must have one commentary cell per question on top of
            # the shared title, question and banner cells.
            questions = sum(1 for c in enb["cells"]
                            if c["cell_type"] == "markdown"
                            and any(m in "".join(c["source"])
                                    for m in MD_STUB_MARKERS))
            if questions == 0:
                fail("%s has no code cells and no markdown answer blocks" % rel)
            elif any(c["cell_type"] == "code" for c in snb["cells"]):
                fail("%s: exercise has no code cells but its solution does" % rel)
            continue

        questions = sum(1 for c in enb["cells"]
                        if c["cell_type"] == "code" and is_stub(c, convention))
        sol_cells = sum(1 for c in snb["cells"] if c["cell_type"] == "code")
        if questions == 0:
            fail("%s has no empty answer cells -- is it generated?" % rel)
        elif convention == "python" and sol_cells != questions + 1:
            # Python sheets have one shared setup cell plus one per question.
            # The SQL sheets predate that convention and vary, so only the
            # generated Python ones are checked this strictly.
            fail("%s: %d questions but %d solution code cells (expected %d)"
                 % (rel, questions, sol_cells, questions + 1))

    # 2: exercises must not leak answers
    for e in ex:
        nb = json.load(open(e))
        rel = os.path.relpath(e, REPO)
        for c in nb["cells"]:
            if c["cell_type"] != "code":
                continue
            if c.get("outputs"):
                fail("%s has stored outputs" % rel); break
            if c.get("execution_count") is not None:
                fail("%s has execution counts" % rel); break

    # 4: nbformat and key order, both sides
    for p in ex + so:
        nb = json.load(open(p))
        rel = os.path.relpath(p, REPO)
        if (nb.get("nbformat"), nb.get("nbformat_minor")) != (4, 5):
            fail("%s is nbformat %s.%s, expected 4.5"
                 % (rel, nb.get("nbformat"), nb.get("nbformat_minor")))
            continue
        for c in nb["cells"]:
            want = MD_KEYS if c["cell_type"] == "markdown" else CODE_KEYS
            if list(c.keys()) != want:
                fail("%s has a cell with non-normalised keys: %s"
                     % (rel, list(c.keys())))
                break

    # 5: data parity -- only required where a solution reads data/ by a
    # RELATIVE path. The SQL classes use the absolute container path
    # (/home/jovyan/work/<class>/data/...), which resolves to the mounted
    # exercises folder, so they need no copy under solutions/.
    needs_parity = any(
        ('"data/' in open(p).read() or '"../data/' in open(p).read())
        for p in so)
    a = os.path.join(REPO, cls, "exercises", "data")
    b = os.path.join(REPO, cls, "solutions", "data")
    if os.path.isdir(a) and needs_parity:
        if not os.path.isdir(b):
            fail("%s: solutions read data/ by a relative path but solutions/data does not exist"
                 % cls)
        else:
            # Walk, rather than listdir: data/ may contain subfolders. The
            # medallion landing zone in week3_day1_afternoon is data/bronze/,
            # and filecmp.cmp on a directory is not a comparison.
            for dirpath, dirnames, filenames in os.walk(a):
                dirnames[:] = sorted(d for d in dirnames if d not in SKIP)
                for name in sorted(filenames):
                    rel = os.path.relpath(os.path.join(dirpath, name), a)
                    pa, pb = os.path.join(a, rel), os.path.join(b, rel)
                    if not os.path.exists(pb):
                        fail("%s: data/%s missing from solutions/" % (cls, rel))
                    elif not filecmp.cmp(pa, pb, shallow=False):
                        fail("%s: data/%s differs between exercises/ and solutions/"
                             % (cls, rel))

    print("  %d exercise/solution pairs" % len(ex))


def main():
    wanted = sys.argv[1:] or list(CLASSES)
    unknown = [c for c in wanted if c not in CLASSES]
    if unknown:
        sys.exit("unknown class(es): %s\nknown: %s"
                 % (", ".join(unknown), ", ".join(CLASSES)))

    for cls in wanted:
        check_class(cls)

    print()
    if failures:
        print("FAILED -- %d problem(s)" % len(failures))
        sys.exit(1)
    print("all invariants hold")


if __name__ == "__main__":
    main()
