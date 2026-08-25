# Afternoon class — 24/08

Building tables, aggregate functions, and joins.

Work through `exercises/` in order; the numbers are the teaching order.
Answers are in `solutions/`, same numbering.

| # | Worksheet | Covers | Lecture |
|---|---|---|---|
| 01 | `01_build_database_and_tables.sql` | `CREATE TABLE`, primary/foreign keys, `LOAD DATA LOCAL INFILE` | DDL foundation |
| 02 | `02_aggregates_group_by_having.sql` | `COUNT`/`SUM`/`AVG`/`MIN`/`MAX`, `GROUP BY`, `HAVING` vs `WHERE` | L06 |
| 03 | `03_joins.sql` | `INNER`/`LEFT`/`RIGHT`/`FULL` joins on `company` | L07 |
| 04 | `04_joins_and_unions_more_practice.sql` | anti-joins, self joins, `UNION`/`UNION ALL`, `INTERSECT`, `EXCEPT` | L07 |

Worksheets 01 and 03 are the main lab; 02 and 04 are extra repetitions on the
same material — use them when a topic didn't land, or after class.

## Running worksheet 01

Run this one from a `mysql` client on your **host** machine, not from the
Jupyter console: `LOAD DATA LOCAL INFILE` reads files from the *client's*
filesystem, and the console runs inside a container that can't see your disk.
Its CSVs are in `exercises/data/`.

Every other worksheet runs fine in the Jupyter console.

## Two things that trip people up

**`orders` is one row per ORDER LINE, not per order.** One `OrderID` appears
once per product in that order, so `COUNT(*)` counts lines (8,060) while
`COUNT(DISTINCT OrderID)` counts orders (5,361). Most wrong answers come from
this one distinction.

**Table names are plural here.** The lecture slides say `superstore.customer`
and `superstore.product`; this lab uses `customers`, `products`, `orders`,
`returns`. Same data and columns — only the name differs.

## Where the slides and MySQL disagree

- **`FULL OUTER JOIN` does not exist in MySQL.** The slides show it; writing
  one is a syntax error. Emulate it with `LEFT JOIN … UNION … RIGHT JOIN`
  (worksheet 04 walks through this, and measures how many rows it really adds
  on this data — the answer is surprising).
- **`INTERSECT` and `EXCEPT` do work** on the version this lab runs. Don't
  assume from older MySQL documentation that they're unavailable — worksheet
  04 uses them.

## How to use the solutions

Each solution quotes the **actual expected result**, so you can check yourself
without guessing — and diagnose *where* you diverged rather than only *that*
you did. Try to finish a question before opening it; when you're stuck for
more than a few minutes, read only the next line.
