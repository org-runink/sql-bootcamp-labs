# Week 2, day 3 (morning) — 25/08

> Folders and worksheet titles both name the position in the course. The
> calendar date this session was taught on is in the heading above, and
> nowhere else.

Past the lectures: views, cross-database queries, data modelling, key design,
report building, window functions, and a set of combined analytical
challenges.

This session assumes week 2, day 2 (afternoon) — aggregates, joins,
subqueries and `CASE WHEN`. If any of those are shaky, the extra-practice
sheets there (04, 06, 08, 10) are the place to go back to.

Work through `exercises/` in order. Answers are in `solutions/`, same
numbering.

| # | Worksheet | Covers |
|---|---|---|
| 01 | `01_views_and_materialization.ipynb` | views, updatable views, `WITH CHECK OPTION`, and the materialized-view trap |
| 02 | `02_cross_database_and_runtime_objects.ipynb` | cross-database queries, DB links / FEDERATED, CTEs (`WITH`), recursive CTEs, `EXISTS` |
| 03 | `03_er_modelling_challenges.ipynb` | six ER modelling problems, drawn in Mermaid |
| 04 | `04_natural_and_primary_keys.ipynb` | candidate/natural/surrogate/composite keys, and how to choose a primary key |
| 05 | `05_subquery_reports.ipynb` | building reports with subqueries in `SELECT`, `FROM`, `WHERE` and `HAVING` |
| 06 | `06_window_functions.ipynb` | `OVER (PARTITION BY ...)`, ranking, running totals, `LAG`, frames |
| 07 | `07_analytical_challenges.ipynb` | capstone — eight real business questions, combining everything |

Roughly: 01–03 are about how data is **stored and modelled**, 04–06 about how
it is **queried and reported**, and 07 puts it together.

## Every worksheet is a Jupyter notebook

Open one, run the connection cell at the top once, then work down: each
question is a Markdown cell with an empty `%%sql` cell underneath it for your
answer. Run a cell with `Shift+Enter` and the result appears immediately below
it, so you can iterate on a query without leaving the page.

Worksheet 03 additionally has its ER diagrams written in
[Mermaid](https://mermaid.js.org/), and
JupyterLab renders them as actual pictures inside the notebook. You read the
problem, draw your answer by editing a Markdown cell, run it to see the
diagram, and write the DDL in a `%%sql` cell directly underneath — all in one
place, no external drawing tool. Double-click any diagram to see its source.

## Which worksheets create things

01, 02 and 04 create tables. Everyone shares one MySQL server, so each asks
you to work in your own scratch database and drop it when you're done:

```sql
CREATE DATABASE practice_yourname;
USE practice_yourname;
```

Never create or drop anything inside `superstore` or `company`.
Worksheets 03, 05, 06 and 07 are read-only.

## Where the slides and MySQL disagree

- **There are no materialized views**, and this is the nasty one:
  `CREATE MATERIALIZED VIEW` does **not** fail. It quietly creates an
  ordinary view, so you get live re-execution while believing you have a
  precomputed snapshot. Worksheet 01 makes you prove it.
- **No cross-*server* links.** Querying `superstore` and `company` together
  works because they share one server; the FEDERATED engine (MySQL's answer
  to an Oracle DBLINK) is disabled here. Worksheet 02 has you check.
- **A foreign key needs a *uniquely* indexed target.** `superstore.returns`
  cannot reference `superstore.orders` because `OrderID` isn't unique there.
  Worksheets 03 and 04 both come at this from different directions.
- **A window function cannot go in `WHERE` or `HAVING`.** They're evaluated
  after those clauses run. Wrap the query and filter outside — worksheet 06
  Q5.

## A theme worth naming

Several worksheets end with a result that is technically correct and
substantively meaningless — the return rates in 07 that are an artefact of
how `returns` is keyed, the cohort revenues that measure observation window
rather than customer quality, the discount bands that are confounded by
product mix.

That is deliberate, and it is the most useful thing in this session. Writing
the query is the easy half; knowing what it does **not** entitle you to
conclude is the half that matters.

## How to use the solutions

Each solution quotes the **actual expected result**, so you can check yourself
without guessing — and diagnose *where* you diverged rather than only *that*
you did. Try to finish a question before opening it; when you're stuck for
more than a few minutes, read only the next line.
