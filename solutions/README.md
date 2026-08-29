# All solutions, in one place

Every answer notebook from all seven sessions, gathered here so you don't
have to hop between class folders while teaching.

| Session | Notebooks | Covers |
|---|---|---|
| [`week2_day2_afternoon/`](week2_day2_afternoon) | 10 | SQL: DDL, aggregates, joins, subqueries, `CASE WHEN` |
| [`week2_day3_morning/`](week2_day3_morning) | 7 | SQL: views, cross-database, modelling, keys, windows, capstone |
| [`week2_day4_afternoon/`](week2_day4_afternoon) | 19 | Python: the four data structures, built-ins, strings/loops, capstone, data-engineering applications — plus `more-practice/` and the WeCloudData originals |
| [`week2_day5_morning/`](week2_day5_morning) | 28 | Python, two lectures: L05 control flow and iteration (01–08), then L06 functions and code reusability (09–14) — plus `more-practice/` and the WeCloudData originals |
| [`week3_day1_afternoon/`](week3_day1_afternoon) | 22 | Pandas, three lectures: L01 Series/DataFrame/Index (01–04), L02 core functionality (05–10), L03 reading and writing (11–14), plus a pipelines-and-roles synthesis sheet (15) — and `more-practice/` and the WeCloudData originals |
| [`week3_day2_afternoon/`](week3_day2_afternoon) | 19 | Pandas continued: L04 reshaping and pivoting (01–05), L05 data transformation (06–10) — plus `more-practice/` and the WeCloudData Advanced lab |
| [`week3_day3_afternoon/`](week3_day3_afternoon) | 5 | Snowflake: Snowsight and `TPCH_SF1` (01), stages and `COPY INTO` (02) — both **not executed**, they run in your own account — then the same lab CSVs taken apart locally, where every number is observed (03–05) |

110 notebooks in total, plus 30 supporting files — 20 `.csv`, 4 `.sql`,
2 `.html`, 2 `.json`, 1 `.tsv`, 1 `.xlsx`. Several solutions read `data/` by a
**relative** path, so the data has to travel with them or the published answer
cannot be re-run from the console:

- `week2_day5_morning/08_reading_real_files_solution.ipynb` — four `.csv`
- `week3_day1_afternoon/` worksheets 11–14 — `.csv`, `.tsv`, `.json`, `.xlsx`
- `week3_day2_afternoon/` — all sheets read `data/`, and `more-practice/` reads `../data/`
- `week3_day3_afternoon/` — worksheets 03–05 read `data/`, and worksheet 05
  question 10 also reads `snowflake-scripts/*.sql` and `labs/*.html`, so those
  travel too — its answer quotes the file list it finds

## This folder is generated — do not edit it

The **source of truth is each class folder's own `solutions/`**. This tree is
a copy, rebuilt wholesale by a script, so any edit made here is silently
destroyed the next time it runs.

```bash
python3 scripts/collect_solutions.py           # rebuild
python3 scripts/collect_solutions.py --check   # verify it matches; exits 1 if not
```

Fix an answer in `week2_day5_morning/solutions/…`, then re-run the script.
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
