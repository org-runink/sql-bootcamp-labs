# Morning class — 25/08

Past the lectures: views and what "materialized" really means here,
cross-database queries and run-time objects, and ER modelling.

This session assumes the afternoon class of 24/08 — aggregates, joins,
subqueries and `CASE WHEN`. If any of those are shaky, the extra-practice
sheets there (04, 06, 08, 10) are the place to go back to.

Work through `exercises/` in order. Answers are in `solutions/`, same
numbering.

| # | Worksheet | Covers |
|---|---|---|
| 01 | `01_views_and_materialization.sql` | views, updatable views, `WITH CHECK OPTION`, and the materialized-view trap |
| 02 | `02_cross_database_and_runtime_objects.sql` | cross-database queries, DB links / FEDERATED, CTEs (`WITH`), recursive CTEs, `EXISTS` |
| 03 | `03_er_modelling_challenges.ipynb` | six ER modelling problems, drawn in Mermaid |

## Worksheet 03 is a notebook, not a `.sql` file

Its ER diagrams are written in [Mermaid](https://mermaid.js.org/), and
JupyterLab renders them as actual pictures inside the notebook. You read the
problem, draw your answer by editing a Markdown cell, run it to see the
diagram, and write the DDL in a `%%sql` cell directly underneath — all in one
place, no external drawing tool. Double-click any diagram to see its source.

## All three worksheets CREATE things

Everyone shares one MySQL server, so each one asks you to work in your own
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
  precomputed snapshot. Worksheet 01 makes you prove it.
- **No cross-*server* links.** Querying `superstore` and `company` together
  works because they share one server; the FEDERATED engine (MySQL's answer
  to an Oracle DBLINK) is disabled here. Worksheet 02 has you check.
- **A foreign key needs a *uniquely* indexed target.** `superstore.returns`
  cannot reference `superstore.orders` because `OrderID` isn't unique there —
  one row per order line. Worksheet 03 has you design the fix.

## How to use the solutions

Each solution quotes the **actual expected result**, so you can check yourself
without guessing — and diagnose *where* you diverged rather than only *that*
you did. Try to finish a question before opening it; when you're stuck for
more than a few minutes, read only the next line.
