#!/usr/bin/env python3
"""Mirror every class folder's solutions/ into one top-level solutions/ tree.

The per-class `solutions/` folders remain the source of truth. This script
copies them into `solutions/<class-folder>/` at the repo root so all the
answers for every session can be opened from one place.

    python3 scripts/collect_solutions.py            # rebuild the mirror
    python3 scripts/collect_solutions.py --check    # verify it is in sync

`--check` exits non-zero if the mirror has drifted, so it is safe to run
before committing. Never edit anything under the top-level solutions/ — it is
overwritten wholesale on every rebuild.

Note: the top-level solutions/ IS mounted into the Jupyter console as
SOLUTIONS/, so everything copied here is readable by every student on the
classroom LAN. That is a deliberate instructor choice -- see solutions/README.md.
"""

import argparse
import filecmp
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(REPO, "solutions")

CLASSES = [
    "week2_day2_afternoon",
    "week2_day3_morning",
    "week2_day4_afternoon",
    "week2_day5_morning",
    "week3_day1_afternoon",
    "week3_day2_afternoon",
    "week3_day3_afternoon",
]

SKIP_DIRS = {".ipynb_checkpoints", "__pycache__"}

# Notebooks, plus the data files a notebook needs beside it. Several solutions
# read data/ with a RELATIVE path, so the mirror has to carry those too or the
# published answer cannot be re-run from the console:
#   27/08 worksheet 08          .csv
#   30/08 worksheets 11-14      .csv .tsv .json .xlsx
#
# week3_day3_afternoon adds .sql and .html: worksheet 05 question 10 greps
# snowflake-scripts/*.sql and labs/*.html by relative path, and its answer
# quotes the file list it finds. Without them the published solution reports
# a different number of files than its own text says.
KEEP_SUFFIXES = (".ipynb", ".csv", ".tsv", ".json", ".xlsx", ".sql", ".html")


def sources():
    """Yield (class_folder, path relative to that class's solutions/)."""
    for cls in CLASSES:
        root = os.path.join(REPO, cls, "solutions")
        if not os.path.isdir(root):
            raise SystemExit("missing: %s" % root)
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
            for name in sorted(filenames):
                if not name.endswith(KEEP_SUFFIXES):
                    continue
                full = os.path.join(dirpath, name)
                yield cls, os.path.relpath(full, root)


def relink_lab_data():
    """Restore the fetched Advanced-lab CSVs the rebuild just removed.

    scripts/fetch_lab_data.py downloads ~136 MB into
    <class>/exercises/wcd-originals/ and hardlinks it into the published
    mirror so the lab runs offline. This function rmtree's that mirror, so
    the links have to be remade -- hardlinked again, not copied, so the data
    still occupies its space once.

    The files are gitignored; this only keeps the working tree usable.
    """
    for cls in CLASSES:
        src_dir = os.path.join(REPO, cls, "exercises", "wcd-originals")
        if not os.path.isdir(src_dir):
            continue
        csvs = [n for n in sorted(os.listdir(src_dir)) if n.endswith(".csv")]
        if not csvs:
            continue
        dst_dir = os.path.join(DEST, cls, "wcd-originals")
        os.makedirs(dst_dir, exist_ok=True)
        for name in csvs:
            src, dst = os.path.join(src_dir, name), os.path.join(dst_dir, name)
            if os.path.exists(dst):
                continue
            try:
                os.link(src, dst)
            except OSError:
                shutil.copy2(src, dst)
        print("  relinked %d lab data file(s) into %s/wcd-originals" % (len(csvs), cls))


def build(check):
    pairs = list(sources())
    problems = []

    if not check:
        # Clear only the generated per-class trees. Do NOT rmtree(DEST):
        # solutions/README.md is hand-written and lives here too.
        for cls in CLASSES:
            target = os.path.join(DEST, cls)
            if os.path.isdir(target):
                shutil.rmtree(target)

    for cls, rel in pairs:
        src = os.path.join(REPO, cls, "solutions", rel)
        dst = os.path.join(DEST, cls, rel)
        if check:
            if not os.path.exists(dst):
                problems.append("missing from mirror: %s/%s" % (cls, rel))
            elif not filecmp.cmp(src, dst, shallow=False):
                problems.append("differs from source: %s/%s" % (cls, rel))
        else:
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst)

    if check:
        # anything in the mirror that no longer has a source
        expected = {os.path.join(cls, rel) for cls, rel in pairs}
        for dirpath, dirnames, filenames in os.walk(DEST):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
            for name in filenames:
                if not name.endswith(KEEP_SUFFIXES):
                    continue
                rel = os.path.relpath(os.path.join(dirpath, name), DEST)
                if rel in expected:
                    continue
                # The Advanced-lab datasets live under wcd-originals/ and are
                # owned by scripts/fetch_lab_data.py, not by this mirror --
                # they are hardlinked in by relink_lab_data() and gitignored.
                if "wcd-originals" in rel and name.endswith(".csv"):
                    continue
                problems.append("stale, no longer in any class folder: %s" % rel)

    return pairs, problems


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true",
                    help="verify the mirror matches the class folders; do not write")
    args = ap.parse_args()

    pairs, problems = build(args.check)

    counts = {}
    for cls, _ in pairs:
        counts[cls] = counts.get(cls, 0) + 1

    if problems:
        print("OUT OF SYNC (%d)" % len(problems))
        for p in problems:
            print("  -", p)
        print("\nRun: python3 scripts/collect_solutions.py")
        sys.exit(1)

    if not args.check:
        relink_lab_data()

    verb = "in sync" if args.check else "written"
    print("solutions/ %s — %d files" % (verb, len(pairs)))
    for cls in CLASSES:
        print("  %-22s %d" % (cls, counts.get(cls, 0)))


if __name__ == "__main__":
    main()
