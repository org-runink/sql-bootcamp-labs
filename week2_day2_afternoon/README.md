# Week 2, day 2 (afternoon) — 24/08

> Folders and worksheet titles both name the position in the course. The
> calendar date this session was taught on is in the heading above, and
> nowhere else.

The full taught syllabus: building tables, aggregate functions, joins,
subqueries and `CASE WHEN`.

Work through `exercises/` in order; the numbers are the teaching order.
Answers are in `solutions/`, same numbering.

| # | Worksheet | Covers | Lecture |
|---|---|---|---|
| 01 | `01_build_database_and_tables.ipynb` | `CREATE TABLE`, primary/foreign keys, `LOAD DATA LOCAL INFILE` | DDL |
| 02 | `02_constraints_and_data_types.ipynb` | data types, `NOT NULL`/`UNIQUE`/`DEFAULT`/`CHECK`, FK delete actions | DDL |
| 03 | `03_aggregates_group_by_having.ipynb` | `COUNT`/`SUM`/`AVG`/`MIN`/`MAX`, `GROUP BY`, `HAVING` vs `WHERE` | L06 |
| 04 | `04_aggregates_more_practice.ipynb` | the three `COUNT`s, `GROUP_CONCAT`, `ROLLUP`, grain traps | L06 |
| 05 | `05_joins.ipynb` | `INNER`/`LEFT`/`RIGHT`/`FULL` joins on `company` | L07 |
| 06 | `06_joins_and_unions_more_practice.ipynb` | anti-joins, self joins, `UNION`/`UNION ALL`, `INTERSECT`, `EXCEPT` | L07 |
| 07 | `07_subqueries.ipynb` | scalar subqueries, `IN`, `EXISTS`, derived tables | L08 |
| 08 | `08_subqueries_more_practice.ipynb` | more of the same, incl. the `NOT IN` NULL trap | L08 |
| 09 | `09_case_when_and_pivots.ipynb` | `CASE WHEN`, conditional aggregation, pivots | L09 |
| 10 | `10_case_when_and_pivots_more_practice.ipynb` | more pivots and bucketing | L09 |

The odd-numbered sheets from 05 on are the course's own exercises; the
even-numbered ones are extra repetitions on the same topic — use them when a
topic didn't land, or after class.

## Every worksheet is a Jupyter notebook

Open one, run the connection cell at the top once, then work down: each
question is a Markdown cell with an empty `%%sql` cell underneath it for your
answer. Run a cell with `Shift+Enter` and the result appears immediately below
it, so you can iterate on a query without leaving the page.

## Worksheet 02 needs a scratch database

**02** creates tables. Everyone shares one MySQL server, so it asks you to
work in your own scratch database and drop it at the end:

```sql
CREATE DATABASE practice_yourname;
USE practice_yourname;
```

Never create or drop anything inside `superstore` or `company`.

**01** also creates a database (`superstore_practice`) and loads the CSVs in
`exercises/data/` into it, then drops it at the end. It runs entirely in the
notebook — the lab enables `LOAD DATA LOCAL INFILE` on both the server and the
connection so you can practise the real loading workflow from the browser.

Every other worksheet is read-only.

## Two things that trip people up

**`orders` is one row per ORDER LINE, not per order.** One `OrderID` appears
once per product in that order, so `COUNT(*)` counts lines (8,060) while
`COUNT(DISTINCT OrderID)` counts orders (5,361). Most wrong answers come from
this one distinction — worksheet 04 is largely built around it.

**Table names are plural here.** The lecture slides say `superstore.customer`
and `superstore.product`; this lab uses `customers`, `products`, `orders`,
`returns`. Same data and columns — only the name differs.

## Where the slides and MySQL disagree

- **`FULL OUTER JOIN` does not exist in MySQL.** The slides show it; writing
  one is a syntax error. Emulate it with `LEFT JOIN … UNION … RIGHT JOIN`
  (worksheet 06 walks through this, and measures how many rows it really adds
  on this data — the answer is surprising).
- **`INTERSECT` and `EXCEPT` do work** on the version this lab runs. Don't
  assume from older MySQL documentation that they're unavailable — worksheet
  06 uses them.
- **`NOT IN` with NULLs silently returns nothing.** Not an error, not a
  warning — zero rows. Worksheet 08 makes you hit it, then fixes it with
  `NOT EXISTS`.
- **`CHECK` was ignored before MySQL 8.0.16.** It is enforced on this server
  (worksheet 02 proves it), but the same DDL silently enforces nothing on an
  older one.

## How to use the solutions

Each solution quotes the **actual expected result**, so you can check yourself
without guessing — and diagnose *where* you diverged rather than only *that*
you did. Try to finish a question before opening it; when you're stuck for
more than a few minutes, read only the next line.
