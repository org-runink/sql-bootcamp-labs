#!/usr/bin/env python3
"""Fetch the WeCloudData Advanced-lab datasets once, so the lab runs offline.

`week3_day2/.../Lab - Pandas Advanced` downloads seven CSVs with
`!curl -sS -o <name> <url>` and then reads them by bare filename. That needs
internet every time it is run, which is no good in a classroom.

This script downloads them once into the notebook's own directory. After
that the lab works with the network down: the `curl` cells fail visibly and
harmlessly -- curl gives up at DNS resolution, **before** it opens the output
file, so the pre-placed CSV is left untouched -- and the `read_csv` cells
that follow find the data already there.

    python3 scripts/fetch_lab_data.py            # download what is missing
    python3 scripts/fetch_lab_data.py --verify   # check only, download nothing
    python3 scripts/fetch_lab_data.py --force    # re-download everything

About 142 MB, most of it employee_salaries.csv (2.8M rows). NOTHING is
committed -- the files are in .gitignore. Run it once per machine, as part
of setting the lab up, not before each class.

The copy under solutions/ is HARDLINKED to the one under exercises/, so the
data occupies its 142 MB once rather than twice. Both notebooks then find
their files in their own working directory.
"""

import argparse
import os
import sys
import urllib.error
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = "https://s3.amazonaws.com/weclouddata/datasets/genai/ml_fundamentals"

# Where the notebooks actually run from.
PRIMARY = os.path.join(REPO, "week3_day2", "exercises", "wcd-originals")
MIRROR = os.path.join(REPO, "solutions", "week3_day2", "wcd-originals")

# name -> (expected size in bytes, has a header row)
FILES = {
    "telecom.csv":                  (977501,   True),
    "employee_departments.csv":     (153,      False),
    "employee_dept_manager.csv":    (816,      False),
    "employee_dept_emp.csv":        (11175033, False),
    "employee_employees.csv":       (13821993, False),
    "employee_titles.csv":          (17718376, False),
    "employee_salaries.csv":        (98781181, False),
}


def human(n):
    for unit in ("B", "KB", "MB"):
        if n < 1024 or unit == "MB":
            return "%.1f %s" % (n, unit) if unit != "B" else "%d B" % n
        n /= 1024.0


def present(path, expected):
    return os.path.exists(path) and os.path.getsize(path) == expected


def download(name, dest):
    url = "%s/%s" % (BASE, name)
    tmp = dest + ".part"
    with urllib.request.urlopen(url, timeout=120) as r, open(tmp, "wb") as fh:
        while True:
            chunk = r.read(1 << 20)
            if not chunk:
                break
            fh.write(chunk)
    os.replace(tmp, dest)


def link_into_mirror(name):
    """Hardlink, so the second copy costs no disk. Fall back to a copy."""
    src = os.path.join(PRIMARY, name)
    dst = os.path.join(MIRROR, name)
    if os.path.exists(dst):
        if os.path.samefile(src, dst):
            return "linked"
        os.remove(dst)
    try:
        os.link(src, dst)
        return "linked"
    except OSError:
        import shutil
        shutil.copy2(src, dst)
        return "copied"


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--verify", action="store_true", help="check only; download nothing")
    ap.add_argument("--force", action="store_true", help="re-download even if present")
    args = ap.parse_args()

    for d in (PRIMARY, MIRROR):
        os.makedirs(d, exist_ok=True)

    total = sum(size for size, _ in FILES.values())
    missing = [n for n, (size, _) in FILES.items()
               if args.force or not present(os.path.join(PRIMARY, n), size)]

    if args.verify:
        ok = True
        for name, (size, _) in sorted(FILES.items()):
            p = os.path.join(PRIMARY, name)
            if present(p, size):
                print("  ok      %-28s %s" % (name, human(size)))
            else:
                ok = False
                why = "missing" if not os.path.exists(p) else (
                    "wrong size: %s" % human(os.path.getsize(p)))
                print("  MISSING %-28s %s" % (name, why))
        print()
        if ok:
            print("all present -- the Advanced lab will run offline")
            return
        print("run: python3 scripts/fetch_lab_data.py")
        sys.exit(1)

    if not missing:
        print("all %d files already present (%s)" % (len(FILES), human(total)))
    else:
        need = sum(FILES[n][0] for n in missing)
        print("downloading %d of %d files (%s)\n" % (len(missing), len(FILES), human(need)))
        for name in sorted(missing, key=lambda n: FILES[n][0]):
            size = FILES[name][0]
            print("  %-28s %10s ..." % (name, human(size)), end="", flush=True)
            try:
                download(name, os.path.join(PRIMARY, name))
            except (urllib.error.URLError, OSError) as e:
                print(" FAILED: %s" % e)
                sys.exit("\nDownload failed. This step needs internet; the lab "
                         "itself will not, once it succeeds.")
            got = os.path.getsize(os.path.join(PRIMARY, name))
            print(" done" if got == size else " done (%s, expected %s)"
                  % (human(got), human(size)))

    print("\nlinking into the published solutions folder:")
    for name in sorted(FILES):
        how = link_into_mirror(name)
        print("  %-28s %s" % (name, how))

    print("\nverifying each file parses:")
    try:
        import pandas as pd
    except ImportError:
        print("  (pandas not available here -- skipped; the lab image has it)")
    else:
        for name, (_, has_header) in sorted(FILES.items()):
            df = pd.read_csv(os.path.join(PRIMARY, name),
                             header=0 if has_header else None, nrows=5)
            print("  %-28s %d columns" % (name, df.shape[1]))

    print("\ndone -- the Advanced lab now runs with the network down")


if __name__ == "__main__":
    main()
