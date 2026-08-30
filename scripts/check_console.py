#!/usr/bin/env python3
"""Check that the Jupyter console is serving what is on disk, and has what it needs.

Run this before class. Two checks:

  1. MOUNTS. For every bind mount in docker-compose.yml, compare the inode of
     the host directory against the inode the container sees. If they differ,
     the mount points at an orphaned directory and students see an EMPTY
     folder while the files sit happily in your git clone.

  2. PACKAGES. Ask the RUNNING container for its Python and package versions
     and compare against jupyter-sql/verify_image.py.

Check 2 exists because the build-time guard in the Dockerfile cannot catch a
STALE IMAGE. `podman-compose up -d` without `--build` happily reuses whatever
image is already tagged -- and the console image was SQL-only until commit
c4082db added pandas. A container from before that runs fine, mounts fine, and
fails on `import pandas` in front of a class.

    python3 scripts/check_console.py

Exits non-zero if anything is stale, so it can go in a pre-class check.

WHY THIS HAPPENS
----------------
A bind mount resolves to an inode when the container starts, not to a path.
Anything that DELETES and RECREATES a mounted directory gives it a new inode,
and the container keeps pointing at the old one. The usual culprit is git:

    git checkout <branch-without-that-folder>   # git removes the directory
    git checkout master                         # git recreates it, new inode

Switching between a branch that has a class folder and one that does not is
enough. So is anything that rmtree's and rebuilds a directory.

Restarting the container does NOT always fix it. Recreate:

    podman-compose up -d --force-recreate sql-console
"""

import json
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMPOSE = os.path.join(REPO, "docker-compose.yml")
CONTAINER = "sql-console-lan"


def bind_mounts():
    """Yield (host_relative_path, container_path) for the sql-console service only.

    docker-compose.yml also mounts ./db-init into the MYSQL container, which
    has nothing to do with the console -- checking it here would report a
    permanent false positive.
    """
    service = None
    with open(COMPOSE) as fh:
        for raw in fh:
            svc = re.match(r"^  (\S+):\s*$", raw)
            if svc:
                service = svc.group(1)
                continue
            m = re.match(r"^\s*-\s+\./(\S+):(\S+)$", raw)
            if m and service == "sql-console":
                yield m.group(1), m.group(2)


def container_stat(path):
    """(inode, entry count) as seen from inside the container, or None."""
    r = subprocess.run(
        ["podman", "exec", CONTAINER, "sh", "-c",
         'stat -c%%i "%s" 2>/dev/null; ls "%s" 2>/dev/null | wc -l' % (path, path)],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        return None
    parts = r.stdout.split()
    if len(parts) != 2:
        return None
    return int(parts[0]), int(parts[1])


def check_packages():
    """Run jupyter-sql/verify_image.py inside the RUNNING container.

    Catches the stale-image case the Dockerfile's build-time guard cannot:
    an image tagged before a package was added, reused by `up -d` without
    `--build`.
    """
    script = os.path.join(REPO, "jupyter-sql", "verify_image.py")
    if not os.path.exists(script):
        print("\n  (jupyter-sql/verify_image.py missing -- package check skipped)")
        return True

    print("\npackages in the running container:")
    dest = "/tmp/_verify_image.py"
    try:
        subprocess.run(["podman", "cp", script, "%s:%s" % (CONTAINER, dest)],
                       check=True, capture_output=True)
        r = subprocess.run(["podman", "exec", CONTAINER, "python3", dest],
                           capture_output=True, text=True)
        subprocess.run(["podman", "exec", CONTAINER, "rm", "-f", dest],
                       capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        print("  could not reach the container: %s" % exc)
        return False

    for line in r.stdout.rstrip().split("\n"):
        print("  " + line if line else "")
    if r.returncode != 0:
        print("\nThe running container is missing packages the worksheets need.")
        print("This is usually a STALE IMAGE -- rebuild, do not just restart:")
        print("  podman-compose up -d --build --force-recreate sql-console")
        return False
    return True


def main():
    running = subprocess.run(
        ["podman", "ps", "--filter", "name=" + CONTAINER, "--format", "{{.Names}}"],
        capture_output=True, text=True,
    ).stdout.strip()
    if CONTAINER not in running:
        sys.exit("%s is not running. Start it with: podman-compose up -d" % CONTAINER)

    stale = []
    print("mount".ljust(40), "host".rjust(10), "container".rjust(10), " files")
    print("-" * 78)

    for host_rel, cpath in bind_mounts():
        host_abs = os.path.join(REPO, host_rel)
        if not os.path.isdir(host_abs):
            print("%-40s %10s %10s  MISSING ON HOST" % (host_rel, "-", "-"))
            stale.append(host_rel)
            continue

        h_inode = os.stat(host_abs).st_ino
        # Match `ls` inside the container, which hides dotfiles -- otherwise
        # .ipynb_checkpoints makes every row look off by one.
        h_files = len([n for n in os.listdir(host_abs) if not n.startswith(".")])
        got = container_stat(cpath)
        if got is None:
            print("%-40s %10d %10s  NOT VISIBLE" % (host_rel, h_inode, "-"))
            stale.append(host_rel)
            continue

        c_inode, c_files = got
        flag = "" if h_inode == c_inode else "  <-- STALE"
        if flag:
            stale.append(host_rel)
        print("%-40s %10d %10d  %3d/%-3d%s"
              % (host_rel, h_inode, c_inode, c_files, h_files, flag))

    print()
    if stale:
        print("%d mount(s) stale. The container is serving orphaned directories."
              % len(stale))
        for s in stale:
            print("  -", s)
        print("\nFix:  podman-compose up -d --force-recreate sql-console")
        sys.exit(1)

    print("all mounts healthy — the console is serving what is on disk")

    if not check_packages():
        sys.exit(1)


if __name__ == "__main__":
    main()
