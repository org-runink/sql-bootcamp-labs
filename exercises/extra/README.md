# Extra practice

Additional exercises reinforcing the lecture material, in lecture order. They
are **optional** — the numbered `Part1`–`Part3` worksheets one directory up are
the main lab. Use these when you want more repetitions on a topic that didn't
click, or after class to consolidate.

| File | Reinforces | Topics |
|---|---|---|
| `Extra01_Aggregates_GroupBy_Having.sql` | L06 | `COUNT`/`SUM`/`AVG`/`MIN`/`MAX`, `GROUP BY`, `HAVING` vs `WHERE` |
| `Extra02_Joins_and_Unions.sql` | L07 | inner/left/right joins, anti-joins, self joins, `UNION`/`UNION ALL`, `INTERSECT`, `EXCEPT` |
| `Extra03_Subqueries.sql` | L08 | scalar subqueries, `IN`/`NOT IN`/`EXISTS`, derived tables |
| `Extra04_CaseWhen_Pivot.sql` | L09 | `CASE WHEN`, conditional aggregation, pivot tables |

Everything runs against the `superstore` database, which is already seeded —
no setup beyond `docker compose up -d`.

## How to use them

Work top to bottom; questions get harder down each file. Write your query
under the comment and run it. Solutions are in `solutions/extra/`, and each
one quotes the **actual expected result**, so you can check yourself without
guessing — and diagnose *where* you diverged rather than only *that* you did.

Try to finish a question before opening the solution. When you're stuck for
more than a few minutes, read only the next line of the solution.

## Two things that trip people up

**`orders` is one row per ORDER LINE, not per order.** One `OrderID` appears
once per product in that order, so `COUNT(*)` counts lines (8,060) while
`COUNT(DISTINCT OrderID)` counts orders (5,361). Most wrong answers in these
files come from this one distinction.

**Table names are plural here.** The lecture slides say `superstore.customer`
and `superstore.product`; this lab uses `customers`, `products`, `orders`,
`returns`. Same data and columns — only the name differs.

## Where the slides and MySQL disagree

Worth knowing before you hit it:

- **`FULL OUTER JOIN` does not exist in MySQL.** The slides show it; writing
  one is a syntax error. Emulate it with `LEFT JOIN … UNION … RIGHT JOIN`
  (Extra 02 Q4 walks through this, and measures how many rows it really adds
  on this data — the answer is surprising).
- **`INTERSECT` and `EXCEPT` do work** on the version this lab runs. Don't
  assume from older MySQL documentation that they're unavailable — Extra 02
  Q9 and Q10 use them.
