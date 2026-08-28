#!/usr/bin/env python3
"""Push local commits to GitHub as SIGNED commits authored by runink-core[bot].

This is a drop-in replacement for `git push` on this repo. Commit locally as
normal, then run this instead of pushing; each local commit is replayed through
the GraphQL `createCommitOnBranch` mutation using a runink-core installation
token, which is the only mechanism that produces a green **Verified** badge.

    export RUNINK_CORE_PEM=~/Downloads/runink-core.<date>.private-key.pem
    git commit -m "Add worksheet 15"
    python3 scripts/core_commit.py               # replay onto the current branch
    python3 scripts/core_commit.py --dry-run     # show what would be sent

Why not just `git push`? Because GitHub only signs commits that GitHub itself
constructs. A pushed commit -- or one made with the REST `POST /git/commits`
plumbing endpoint -- is stored verbatim and stays "Unverified" forever. App bot
accounts have no GPG key settings, so we cannot sign locally either. Routing
through createCommitOnBranch is the whole trick.

Consequences of that mechanism, which are not obvious:

  * Author and committer come from the TOKEN, not from your git config. You
    cannot set them, and they will always be runink-core[bot]. Your local
    authorship is discarded on replay.
  * Only single-parent commits exist. Merge commits cannot be created this way,
    so this script refuses to replay a range containing one. Merge through the
    GitHub UI instead -- those are signed by GitHub anyway.
  * The rewritten commits get new SHAs, so the script resyncs your clone at the
    end (stashing any dirty files first -- this repo usually has a few notebooks
    dirtied by lab runs).
"""

import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

APP_ID = 4368699
INSTALLATION_ID = 148987871
OWNER, REPO = "org-runink", "sql-bootcamp-labs"

API = "https://api.github.com"
GRAPHQL = API + "/graphql"

# GitHub rejects oversized GraphQL bodies. Notebooks are chunky, so warn early
# rather than failing halfway through a multi-commit replay.
MAX_PAYLOAD_BYTES = 10 * 1024 * 1024

MUTATION = """
mutation($input: CreateCommitOnBranchInput!) {
  createCommitOnBranch(input: $input) {
    commit { oid url signature { isValid state } }
  }
}
"""


def git(*args, binary=False):
    r = subprocess.run(["git"] + list(args), capture_output=True, check=True)
    return r.stdout if binary else r.stdout.decode().strip()


def b64url(raw):
    return base64.urlsafe_b64encode(raw).rstrip(b"=")


def make_jwt(pem_path):
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding

    with open(os.path.expanduser(pem_path), "rb") as fh:
        key = serialization.load_pem_private_key(fh.read(), password=None)

    now = int(time.time())
    header = b64url(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    payload = b64url(json.dumps({"iat": now - 60, "exp": now + 540, "iss": APP_ID}).encode())
    signing_input = header + b"." + payload
    sig = key.sign(signing_input, padding.PKCS1v15(), hashes.SHA256())
    return (signing_input + b"." + b64url(sig)).decode()


def http(method, url, token, body=None, bearer=False):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", ("Bearer " if bearer else "token ") + token)
    req.add_header("Accept", "application/vnd.github+json")
    if data:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as e:
        sys.exit("%s %s -> %s\n%s" % (method, url, e.code, e.read().decode()))


def graphql(token, query, variables):
    out = http("POST", GRAPHQL, token, {"query": query, "variables": variables})
    if "errors" in out:
        sys.exit("GraphQL error:\n" + json.dumps(out["errors"], indent=2))
    return out["data"]


def file_changes(commit):
    """Additions/deletions introduced by `commit`, relative to its parent."""
    # --no-renames keeps the status set to A/M/D; a rename becomes a delete plus
    # an add, which is exactly the shape createCommitOnBranch wants.
    raw = git("diff-tree", "--no-commit-id", "--name-status", "--no-renames",
              "-r", commit + "^", commit)

    additions, deletions = [], []
    for line in raw.splitlines():
        if not line.strip():
            continue
        status, path = line.split("\t", 1)
        if status == "D":
            deletions.append({"path": path})
        else:
            blob = git("show", "%s:%s" % (commit, path), binary=True)
            additions.append({"path": path,
                              "contents": base64.b64encode(blob).decode()})
    return additions, deletions


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pem", default=os.environ.get("RUNINK_CORE_PEM"),
                    help="app private key (default: $RUNINK_CORE_PEM)")
    ap.add_argument("--branch", help="target branch (default: current)")
    ap.add_argument("--dry-run", action="store_true",
                    help="show the plan; contact no remote and change nothing")
    args = ap.parse_args()

    branch = args.branch or git("rev-parse", "--abbrev-ref", "HEAD")

    # What is on the remote right now? A branch that does not exist yet gets
    # created at the first commit's parent, which must already be pushed.
    try:
        remote_head = git("rev-parse", "origin/%s" % branch)
        base_missing = False
    except subprocess.CalledProcessError:
        remote_head, base_missing = None, True

    rng = "%s..HEAD" % (remote_head if remote_head else "origin/master")
    todo = git("rev-list", "--reverse", rng).split()
    if not todo:
        print("nothing to replay -- %s is level with the remote" % branch)
        return

    merges = [c for c in todo if len(git("rev-list", "--parents", "-n", "1", c).split()) > 2]
    if merges:
        sys.exit("refusing: createCommitOnBranch cannot make merge commits.\n"
                 "  offending: %s\nMerge via the GitHub UI instead."
                 % ", ".join(c[:9] for c in merges))

    print("branch %s -- %d commit(s) to replay as runink-core[bot]\n" % (branch, len(todo)))
    plans = []
    for c in todo:
        adds, dels = file_changes(c)
        size = sum(len(a["contents"]) for a in adds)
        subject = git("log", "-1", "--format=%s", c)
        plans.append((c, adds, dels, subject))
        print("  %s  +%-3d -%-3d  %6.1f KB  %s"
              % (c[:9], len(adds), len(dels), size / 1024.0, subject[:52]))

    total = sum(len(a["contents"]) for _, adds, _, _ in plans for a in adds)
    if total > MAX_PAYLOAD_BYTES:
        print("\nWARNING: %.1f MB of file content; GraphQL may reject a commit this large."
              % (total / 1024.0 / 1024.0))

    if args.dry_run:
        print("\nDry run. Drop --dry-run to send.")
        return
    if not args.pem:
        sys.exit("no private key: pass --pem or set RUNINK_CORE_PEM")

    token = http("POST", "%s/app/installations/%d/access_tokens" % (API, INSTALLATION_ID),
                 make_jwt(args.pem), bearer=True)["token"]

    if base_missing:
        base = git("rev-parse", todo[0] + "^")
        http("POST", "%s/repos/%s/%s/git/refs" % (API, OWNER, REPO), token,
             {"ref": "refs/heads/%s" % branch, "sha": base})
        remote_head = base
        print("\ncreated remote branch %s at %s" % (branch, base[:9]))

    print()
    head = remote_head
    for c, adds, dels, subject in plans:
        message = git("log", "-1", "--format=%B", c)
        headline, _, body = message.partition("\n")
        data = graphql(token, MUTATION, {"input": {
            "branch": {"repositoryNameWithOwner": "%s/%s" % (OWNER, REPO),
                       "branchName": branch},
            "expectedHeadOid": head,
            "message": {"headline": headline.strip(), "body": body.strip()},
            "fileChanges": {"additions": adds, "deletions": dels},
        }})
        commit = data["createCommitOnBranch"]["commit"]
        head = commit["oid"]
        sig = commit.get("signature") or {}
        print("  %s -> %s  signature=%s  %s"
              % (c[:9], head[:9], sig.get("state", "?"), subject[:44]))

    print("\n%s now at %s" % (branch, head[:9]))

    # Adopt the signed commits locally; their SHAs differ from what we replayed.
    dirty = bool(git("status", "--porcelain"))
    if dirty:
        git("stash", "push", "-m", "core_commit autostash")
    git("fetch", "origin")
    git("reset", "--hard", "origin/%s" % branch)
    if dirty:
        git("stash", "pop")
    print("local clone resynced%s" % (" (dirty files restored)" if dirty else ""))


if __name__ == "__main__":
    main()
