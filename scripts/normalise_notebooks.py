#!/usr/bin/env python3
"""Rewrite notebooks into this repo's normalised JSON shape.

Key order, nbformat and indentation only -- it never changes a cell's
content. Run it after opening a notebook in JupyterLab, which reorders keys
and sometimes strips cell ids on save, producing a diff that is pure noise.

    python3 scripts/normalise_notebooks.py --check    # report, change nothing
    python3 scripts/normalise_notebooks.py            # rewrite in place
    python3 scripts/normalise_notebooks.py week3_day2 # one class

The shape, matching what scripts/check_exercises.py enforces:

    markdown: cell_type, id, metadata, source
    code:     cell_type, execution_count, id, metadata, outputs, source
    root:     cells, metadata, nbformat(4), nbformat_minor(5)

serialised with 1-space indent and a trailing newline.

Cells with no id get one derived from their position and content, so the
value is stable across runs rather than random.

Vendor files are skipped -- wcd-originals/ and the root
Control_Flow_and_Iteration_Practice/ are kept byte-identical to what
WeCloudData shipped.
"""

import argparse
import glob
import hashlib
import json
import os
import sys
from collections import OrderedDict

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Vendor files, kept byte-identical to what WeCloudData shipped. Normalising
# them would break that guarantee for no benefit.
SKIP = ("wcd-originals", "Control_Flow_and_Iteration_Practice", ".ipynb_checkpoints")

MD_KEYS = ["cell_type", "id", "metadata", "source"]
CODE_KEYS = ["cell_type", "execution_count", "id", "metadata", "outputs", "source"]


def stable_id(path, index, cell):
    """A deterministic 8-hex id, so re-running produces no diff."""
    basis = "%s|%d|%s" % (os.path.basename(path), index, "".join(cell.get("source", [])))
    return hashlib.sha1(basis.encode()).hexdigest()[:8]


def normalise_cell(path, index, cell):
    out = OrderedDict()
    keys = MD_KEYS if cell["cell_type"] == "markdown" else CODE_KEYS
    for k in keys:
        if k == "id":
            out[k] = cell.get("id") or stable_id(path, index, cell)
        elif k == "execution_count":
            out[k] = cell.get("execution_count")
        elif k == "outputs":
            out[k] = cell.get("outputs", [])
        elif k == "metadata":
            out[k] = cell.get("metadata", {})
        else:
            out[k] = cell[k]
    # keep anything unexpected rather than silently dropping it
    for k, v in cell.items():
        if k not in out:
            out[k] = v
    return out


def rendered(path, nb):
    out = OrderedDict()
    out["cells"] = [normalise_cell(path, i, c) for i, c in enumerate(nb["cells"])]
    out["metadata"] = nb.get("metadata", {})
    out["nbformat"] = 4
    out["nbformat_minor"] = 5
    return json.dumps(out, indent=1) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("classes", nargs="*", help="limit to these folders")
    ap.add_argument("--check", action="store_true",
                    help="report what would change; write nothing")
    args = ap.parse_args()

    roots = args.classes or ["."]
    paths = []
    for r in roots:
        paths += glob.glob(os.path.join(REPO, r, "**", "*.ipynb"), recursive=True)
    paths = sorted(p for p in paths if not any(s in p for s in SKIP))

    changed = []
    for p in paths:
        with open(p) as fh:
            before = fh.read()
        try:
            nb = json.loads(before)
        except json.JSONDecodeError as e:
            print("  SKIP (unreadable) %s: %s" % (os.path.relpath(p, REPO), e))
            continue

        after = rendered(p, nb)
        if after == before:
            continue

        # never let this touch content
        old_src = ["".join(c.get("source", [])) for c in nb["cells"]]
        new_src = ["".join(c.get("source", [])) for c in json.loads(after)["cells"]]
        if old_src != new_src:
            sys.exit("REFUSING to write %s -- cell contents would change"
                     % os.path.relpath(p, REPO))

        changed.append(os.path.relpath(p, REPO))
        if not args.check:
            with open(p, "w") as fh:
                fh.write(after)

    print("%d notebooks scanned" % len(paths))
    if not changed:
        print("all already normalised")
        return
    verb = "would be rewritten" if args.check else "rewritten"
    print("%d %s:" % (len(changed), verb))
    for c in changed:
        print("  ", c)
    if args.check:
        sys.exit(1)


if __name__ == "__main__":
    main()
