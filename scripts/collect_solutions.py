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

Safety: the top-level solutions/ is deliberately NOT mounted into the Jupyter
console. docker-compose.yml mounts only each class's exercises/ folder, so
adding this tree does not expose answers in the shared browser console.
"""

import argparse
import filecmp
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(REPO, "solutions")

CLASSES = [
    "afternoon-class-2408",
    "morning-class-2508",
    "afternoon-class-2608",
    "morning-class-2708",
]

SKIP_DIRS = {".ipynb_checkpoints", "__pycache__"}


def sources():
    """Yield (class_folder, path relative to that class's solutions/)."""
    for cls in CLASSES:
        root = os.path.join(REPO, cls, "solutions")
        if not os.path.isdir(root):
            raise SystemExit("missing: %s" % root)
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
            for name in sorted(filenames):
                if not name.endswith(".ipynb"):
                    continue
                full = os.path.join(dirpath, name)
                yield cls, os.path.relpath(full, root)


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
                if not name.endswith(".ipynb"):
                    continue
                rel = os.path.relpath(os.path.join(dirpath, name), DEST)
                if rel not in expected:
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

    verb = "in sync" if args.check else "written"
    print("solutions/ %s — %d notebooks" % (verb, len(pairs)))
    for cls in CLASSES:
        print("  %-22s %d" % (cls, counts.get(cls, 0)))


if __name__ == "__main__":
    main()
