#!/usr/bin/env python3
"""Retitle worksheet H1 headings from calendar dates to course positions.

The class folders were renamed to course positions in commit 484af3e, but the
225 notebooks inside them kept titles like:

    # Afternoon class 24/08 — Worksheet 01: Build database and tables

That was deliberate at the time -- rewriting verified content during a rename is
how mistakes get in. Since then week3_day3_afternoon and week3_day4_morning have
shipped with position-based titles, so the repo now has two conventions. This
script closes that, turning the line above into:

    # Week 2, day 2 (afternoon) — Worksheet 01: Build database and tables

    python3 scripts/retitle_worksheets.py            # show what would change
    python3 scripts/retitle_worksheets.py --write    # apply it

WHAT IT DELIBERATELY DOES NOT TOUCH
-----------------------------------
Only H1 lines matching `# <Morning|Afternoon> class DD/MM` are rewritten, and
only the leading `# ... class DD/MM` part of them -- everything after the em
dash is left byte-identical.

Prose that mentions a date is NOT touched. Sentences like "same pandas
requirement as 30/08" or "derived from the same extract as the 27/08 class" are
cross-references a human wrote, and blanket-replacing dates inside prose is how
you end up with "the Week 3, day 1 (afternoon) class" mid-sentence and a broken
sentence somewhere else. Those are edited by hand, in the READMEs.

The WeCloudData originals under wcd-originals/ are skipped: vendor files kept
byte-identical.

The calendar date is not lost -- each class README carries it in its own H1.
"""

import argparse
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP = ("wcd-originals", ".ipynb_checkpoints", "Control_Flow_and_Iteration_Practice")

# The top-level solutions/ tree is a generated mirror -- collect_solutions.py
# rebuilds it wholesale from each class's own solutions/, so editing it here
# would be undone on the next run. Retitle the sources, then regenerate.
GENERATED = "solutions" + os.sep

# folder -> the course position its worksheets should announce
POSITION = {
    "week2_day2_afternoon": "Week 2, day 2 (afternoon)",
    "week2_day3_morning":   "Week 2, day 3 (morning)",
    "week2_day4_afternoon": "Week 2, day 4 (afternoon)",
    "week2_day5_morning":   "Week 2, day 5 (morning)",
    "week3_day1_afternoon": "Week 3, day 1 (afternoon)",
    "week3_day2_afternoon": "Week 3, day 2 (afternoon)",
}

# `# Afternoon class 24/08` at the start of a line, and nothing more.
TITLE = re.compile(r"^# (?:Morning|Afternoon) class \d\d/\d\d(?= |$)", re.M)

# Three week2_day2_afternoon solutions open with a WeCloudData ASCII-art banner,
# and the title sits INSIDE it, indented by one space rather than being an H1:
#
#     ' Afternoon class 24/08 — Worksheet 05 SOLUTIONS: joins (company-data)'
#
# The art is vendor; that line is not -- it uses this repo's own worksheet
# numbering, so it was written here. It gets the same treatment, and only this
# exact shape: one leading space, then the dated prefix.
BANNER_TITLE = re.compile(r"^ (?:Morning|Afternoon) class \d\d/\d\d(?= |$)", re.M)


def class_of(path):
    rel = os.path.relpath(path, REPO)
    return rel.split(os.sep)[0]


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--write", action="store_true",
                    help="apply the changes; otherwise only report them")
    args = ap.parse_args()

    paths = [p for p in sorted(glob.glob(os.path.join(REPO, "**", "*.ipynb"),
                                         recursive=True))
             if not any(s in p for s in SKIP)
             and not os.path.relpath(p, REPO).startswith(GENERATED)]

    changed_files = 0
    changed_lines = 0
    skipped_no_mapping = set()
    samples = []

    for path in paths:
        cls = class_of(path)
        position = POSITION.get(cls)
        nb = json.load(open(path))
        touched = False

        for cell in nb["cells"]:
            if cell["cell_type"] != "markdown":
                continue
            src = "".join(cell["source"])
            if not (TITLE.search(src) or BANNER_TITLE.search(src)):
                continue
            if position is None:
                skipped_no_mapping.add(cls)
                continue
            new_src = TITLE.sub("# " + position, src)
            new_src = BANNER_TITLE.sub(" " + position, new_src)
            if new_src == src:
                continue
            n = len(TITLE.findall(src)) + len(BANNER_TITLE.findall(src))
            changed_lines += n
            touched = True
            if len(samples) < 6:
                m = TITLE.search(src) or BANNER_TITLE.search(src)
                samples.append((os.path.relpath(path, REPO), m.group(0).strip(),
                                position))
            # nbformat source: a list of lines, each keeping its \n but the last
            lines = new_src.split("\n")
            cell["source"] = [l + "\n" for l in lines[:-1]] + [lines[-1]]

        if touched:
            changed_files += 1
            if args.write:
                with open(path, "w") as fh:
                    json.dump(nb, fh, indent=1)
                    fh.write("\n")

    print("notebooks scanned: %d" % len(paths))
    print("notebooks with a dated title: %d" % changed_files)
    print("title lines rewritten: %d" % changed_lines)
    if skipped_no_mapping:
        print("\nNO MAPPING for these folders -- left alone:")
        for c in sorted(skipped_no_mapping):
            print("   ", c)
    print("\nexamples:")
    for rel, old, new in samples:
        print("  %s" % rel)
        print("      %-34s ->  %s" % (old, new))

    if not args.write:
        print("\ndry run -- nothing written. Re-run with --write to apply.")
    else:
        print("\nwritten. Now run:")
        print("  python3 scripts/normalise_notebooks.py")
        print("  python3 scripts/check_exercises.py")
        print("  python3 scripts/collect_solutions.py")

    if skipped_no_mapping:
        sys.exit(1)


if __name__ == "__main__":
    main()
