# Morning class — 25/08

Subqueries, `CASE WHEN`/pivots, and then past the lectures: views, what
"materialized" really means here, cross-database queries, and ER modelling.

Work through `exercises/` in order; the numbers are the teaching order.
Answers are in `solutions/`, same numbering.

| # | Worksheet | Covers | Lecture |
|---|---|---|---|
| 01 | `01_subqueries.sql` | scalar subqueries, `IN`, `EXISTS`, derived tables | L08 |
| 02 | `02_subqueries_more_practice.sql` | more of the same, incl. the `NOT IN` NULL trap | L08 |
| 03 | `03_case_when_and_pivots.sql` | `CASE WHEN`, conditional aggregation, pivots | L09 |
| 04 | `04_case_when_and_pivots_more_practice.sql` | more pivots and bucketing | L09 |
| 05 | `05_views_and_materialization.sql` | views, updatable views, `WITH CHECK OPTION` | beyond |
| 06 | `06_cross_database_and_runtime_objects.sql` | cross-database queries, DB links, CTEs (`WITH`), recursive CTEs, `EXISTS` | beyond |
| 07 | `07_er_modelling_challenges.ipynb` | six ER modelling problems, drawn in Mermaid | beyond |

Worksheets 01 and 03 are the main lab; 02 and 04 are extra repetitions on the
same material. 05–07 go past what the lectures cover.

## Worksheet 07 is a notebook, not a `.sql` file

Its ER diagrams are written in [Mermaid](https://mermaid.js.org/), and
JupyterLab renders them as actual pictures inside the notebook. You read the
problem, draw your answer by editing a Markdown cell, run it to see the
diagram, and write the DDL in a `%%sql` cell directly underneath — all in one
place, no external drawing tool. Double-click any diagram to see its source.

## Worksheets 05–07 CREATE things

Everyone shares one MySQL server, so those three ask you to work in your own
scratch database and drop it when you're done:

```sql
CREATE DATABASE practice_yourname;
USE practice_yourname;
```

Never create or drop anything inside `superstore` or `company`.

## Where the slides and MySQL disagree

Worth knowing before you hit it:

- **There are no materialized views**, and this is the nasty one:
  `CREATE MATERIALIZED VIEW` does **not** fail. It quietly creates an
  ordinary view, so you get live re-execution while believing you have a
  precomputed snapshot. Worksheet 05 makes you prove it.
- **No cross-*server* links.** Querying `superstore` and `company` together
  works because they share one server; the FEDERATED engine (MySQL's answer
  to an Oracle DBLINK) is disabled here. Worksheet 06 has you check.
- **`NOT IN` with NULLs silently returns nothing.** Not an error, not a
  warning — zero rows. Worksheet 02 makes you hit it, then fixes it with
  `NOT EXISTS`.

## How to use the solutions

Each solution quotes the **actual expected result**, so you can check yourself
without guessing — and diagnose *where* you diverged rather than only *that*
you did. Try to finish a question before opening it; when you're stuck for
more than a few minutes, read only the next line.
