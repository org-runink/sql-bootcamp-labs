# All solutions, in one place

Every answer notebook from all four sessions, gathered here so you don't
have to hop between class folders while teaching.

| Session | Notebooks | Covers |
|---|---|---|
| [`afternoon-class-2408/`](afternoon-class-2408) | 10 | SQL: DDL, aggregates, joins, subqueries, `CASE WHEN` |
| [`morning-class-2508/`](morning-class-2508) | 7 | SQL: views, cross-database, modelling, keys, windows, capstone |
| [`afternoon-class-2608/`](afternoon-class-2608) | 19 | Python: the four data structures, built-ins, strings/loops, capstone, data-engineering applications — plus `more-practice/` and the WeCloudData originals |
| [`morning-class-2708/`](morning-class-2708) | 28 | Python, two lectures: L05 control flow and iteration (01–08), then L06 functions and code reusability (09–14) — plus `more-practice/` and the WeCloudData originals |

64 notebooks in total, plus the four `.csv` files that
`morning-class-2708/08_reading_real_files_solution.ipynb` reads — it uses a
relative path, so the data has to travel with it.

## This folder is generated — do not edit it

The **source of truth is each class folder's own `solutions/`**. This tree is
a copy, rebuilt wholesale by a script, so any edit made here is silently
destroyed the next time it runs.

```bash
python3 scripts/collect_solutions.py           # rebuild
python3 scripts/collect_solutions.py --check   # verify it matches; exits 1 if not
```

Fix an answer in `morning-class-2708/solutions/…`, then re-run the script.
Running `--check` before you commit will catch a mirror that has drifted.

## It IS served to students

This folder is mounted into the shared JupyterLab as `SOLUTIONS/`, so
everyone on the classroom LAN who opens `:8888` can read every answer to
every session — including exercises they have not attempted yet.

That is a deliberate instructor choice, made so the answers are reachable
from the same place as the worksheets. If you would rather they weren't,
delete the `./solutions` line from `docker-compose.yml` and run
`podman-compose up -d --force-recreate sql-console`; the answers then live in
git only.

Note the per-class `solutions/` folders are still *not* mounted individually —
this mirror is the single published copy.

## How to use them

Each solution quotes the **actual result** — real query output for the SQL
sessions, real printed output for the Python one — so a student can check
themselves without guessing, and see *where* they diverged rather than only
*that* they did.

If you're a student who found this folder: you'll learn more from being stuck
for five minutes than from reading ahead. Use the next line, not the whole
notebook.
