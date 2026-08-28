#!/usr/bin/env python3
"""Check that the Jupyter console is actually serving what is on disk.

Run this before class. It compares, for every bind mount in
docker-compose.yml, the inode of the host directory against the inode the
container sees. If they differ, the mount is pointing at an orphaned
directory and students will see an EMPTY folder while the files sit happily
in your git clone.

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


if __name__ == "__main__":
    main()
