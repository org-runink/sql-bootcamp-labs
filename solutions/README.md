# All solutions, in one place

Every answer notebook from all three sessions, gathered here so you don't
have to hop between class folders while teaching.

| Session | Notebooks | Covers |
|---|---|---|
| [`afternoon-class-2408/`](afternoon-class-2408) | 10 | SQL: DDL, aggregates, joins, subqueries, `CASE WHEN` |
| [`morning-class-2508/`](morning-class-2508) | 7 | SQL: views, cross-database, modelling, keys, windows, capstone |
| [`afternoon-class-2608/`](afternoon-class-2608) | 18 | Python: the four data structures, built-ins, strings/loops, capstone — plus `more-practice/` and the WeCloudData originals |

35 notebooks in total.

## This folder is generated — do not edit it

The **source of truth is each class folder's own `solutions/`**. This tree is
a copy, rebuilt wholesale by a script, so any edit made here is silently
destroyed the next time it runs.

```bash
python3 scripts/collect_solutions.py           # rebuild
python3 scripts/collect_solutions.py --check   # verify it matches; exits 1 if not
```

Fix an answer in `afternoon-class-2608/solutions/…`, then re-run the script.
Running `--check` before you commit will catch a mirror that has drifted.

## It is not served to students

`docker-compose.yml` mounts only each class's `exercises/` folder into the
shared Jupyter console, never a `solutions/` folder — including this one. The
answers are in the git repo for whoever clones it, but they do not appear in
the browser console at `:8888`.

That is the same reason the WeCloudData `_Solution` notebooks live under
`afternoon-class-2608/solutions/wcd-originals/` rather than beside the
questions they answer.

## How to use them

Each solution quotes the **actual result** — real query output for the SQL
sessions, real printed output for the Python one — so a student can check
themselves without guessing, and see *where* they diverged rather than only
*that* they did.

If you're a student who found this folder: you'll learn more from being stuck
for five minutes than from reading ahead. Use the next line, not the whole
notebook.
