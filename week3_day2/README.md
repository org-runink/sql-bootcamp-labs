# Week 3, day 2 — reshaping and transformation

Pandas continued, across two lectures: getting data into the shape you need
(L04), and cleaning the values once it is there (L05).

Every worksheet was executed in the lab image before it was written down, and
every number quoted in the solutions is output that was actually observed — not
predicted, not rounded for tidiness.

```
exercises/                 the worksheets
exercises/data/            the files they read
exercises/wcd-originals/   the course's own lab, byte-identical
slides/                    the two lecture decks
solutions/                 the answers, with the real output quoted
```

## Part 1 — Reshaping and pivoting (L04), worksheets 01–05

| # | Sheet | Covers |
|---|---|---|
| 01 | [`01_long_and_wide.ipynb`](exercises/01_long_and_wide.ipynb) | the two shapes, and which questions each one makes easy |
| 02 | [`02_multiindex.ipynb`](exercises/02_multiindex.ipynb) | levels, selection, `xs`, `swaplevel`, `reset_index` |
| 03 | [`03_unstack.ipynb`](exercises/03_unstack.ipynb) | moving a row level to columns, `NaN`, `fill_value` |
| 04 | [`04_stack.ipynb`](exercises/04_stack.ipynb) | folding columns into rows, and what pandas 3 changed |
| 05 | [`05_pivot_and_pivot_table.ipynb`](exercises/05_pivot_and_pivot_table.ipynb) | `pivot` vs `pivot_table`, `aggfunc`, `margins` |

## Part 2 — Data transformation (L05), worksheets 06–10

**Not yet built.** The L05 deck is in `slides/`; the worksheets covering
duplicates, `map`/`apply`/`replace`, renaming, binning, outliers, sampling and
one-hot encoding are the next block.

## The data

Derived from the same real superstore extract as the 27/08 and 30/08 classes —
1,093 orders joined to their customers and products.

| File | Rows | What it is for |
|---|---|---|
| `orders_long.csv` | 1,093 | long format: one row per order, with `Year` and `Month` split out |
| `technology_wide.csv` | 8 | a spreadsheet-style export — regions down, **years across** |
| `customers_messy.csv` | 440 | for the L05 block: real duplicates and mixed missing markers |

**`technology_wide.csv` holds Technology orders only**, and that is deliberate.
Across all categories every region-year combination is present — 32 of 32 — so a
wide table would have no gaps and the whole `NaN` lesson would be invisible.
Technology alone genuinely has **no Nunavut orders in 2009 or 2012**, so the
exported grid has two real blank cells. Nothing was injected to create them.

**The one invented thing** is the mess in `customers_messy.csv`, added
deterministically for the L05 block: the first 40 rows are appended again
verbatim, every 9th `Province` becomes `N/A`/`-`/`?`, and every 15th
`CustomerName` gains a trailing space.

## This class needs pandas

Same image requirement as 30/08. `quay.io/jupyter/base-notebook` ships without
pandas; `jupyter-sql/Dockerfile` installs it. If a worksheet fails on
`import pandas`, rebuild:

```bash
podman-compose up -d --build --force-recreate sql-console
```

Verified against **pandas 3.0.5** on Python 3.13.15. The version matters here
more than usual — see the disagreements below.

## The original WeCloudData notebook

Kept **byte-identical**, split so the answers do not sit beside the exercise:

| Where | File |
|---|---|
| [`exercises/wcd-originals/`](exercises/wcd-originals) | `Lab - Pandas Advanced.ipynb` |
| [`solutions/wcd-originals/`](solutions/wcd-originals) | `Lab - Pandas Advanced Solution.ipynb` |

**Half of it will not run here.** The solution reads seven CSVs by bare
filename. `telecom.csv` is fetched from
`https://s3.amazonaws.com/weclouddata/datasets/genai/ml_fundamentals/telecom.csv`
and was reachable from the lab container when this was written — 7,043 rows.
The other six (`employee_departments.csv`, `employee_dept_emp.csv`,
`employee_dept_manager.csv`, `employee_employees.csv`, `employee_salaries.csv`,
`employee_titles.csv`) were **not shipped with the course and exist nowhere in
this repo**, so those cells fail with `FileNotFoundError`. They are the MySQL
`employees` sample schema; substituting invented data would have meant quoting
numbers that describe nothing, so the notebook is left as it came.

The ten worksheets in this folder deliberately depend on neither: every file
they read is in `data/`, on disk.

## Some cells are supposed to fail

Every sheet ends on a deliberate error, always the **last** question, so
Restart & Run All reaches the bottom before anything raises.

| Sheet | Raises | Why it is there |
|---|---|---|
| 01 | `KeyError: '2013'` | in wide format a missing year is a missing column; in long format it is an empty filter and **no error** |
| 02 | `KeyError: ('Nunavut', 2013)` | both halves of the tuple are checked, and the message does not say which failed |
| 03 | `KeyError: 'Level Category not found'` | you can only unstack a level you grouped by |
| 04 | `ValueError: dropna must be unspecified...` | an argument that worked for years, removed in pandas 3 |
| 05 | `KeyError: 'Quarter'` | the file has `Year` and `Month`; a quarter has to be derived |

## Where the slides and Python disagree

**1. `pivot_table`'s worked example shows totals; the code produces averages.**
The deck's 'Build a Summary Table' slide shows cells of `140` and `110` — sums —
beside code with no `aggfunc`. Its own 'Anatomy' slide, two pages later,
correctly states the default is `mean`. On the real data the Ontario/2012 cell
comes out as **`1719.29`** (the mean of 87 orders), not `149578.59` (their sum).
A factor of 87, and nothing in the output says which you are looking at.
*(Worksheet 05 Q4.)*

**2. `pivot()`'s error message.** The deck prints
`# ValueError: duplicate entries cannot reshape`. The real message is
`Index contains duplicate entries, cannot reshape`. *(Worksheet 05 Q3.)*

**3. `stack(dropna=False)` now raises.** The argument appears throughout the
documentation and every tutorial online. In pandas 3 it is a `ValueError`,
because the rewritten `stack()` no longer drops NA rows at all. The behaviour
change is **silent** for anyone who did not pass the argument: round trips now
return more rows than they used to, with no warning. *(Worksheet 04 Q6, Q10.)*

And three things the deck never mentions:

- **`unstack()` promotes integer columns to float** the moment one combination
  is missing, because `NaN` is a float. *(Worksheet 03 Q5.)*
- **`groupby` sorts your result** whether you want it to or not — alphabetically
  by key, which is why text month names come out `Apr, Aug, Dec, Feb…`
  *(Worksheet 02 Q2.)*
- **`margins=True` on a mean is not the mean of the column.** The margin is
  computed from the underlying rows, so it weights every record once instead of
  every group once. *(Worksheet 05 Q8.)*

## A theme worth naming

The same one the SQL and Pandas sessions have run on: **the dangerous results
are the ones that do not raise.**

Worksheet 05 Q8 is the sharpest case. The eight regional averages for 2012
average to `1995.20`; the `All` margin on the same table reads `1522.22`. Both
are printed by the same call. The margin is the correct answer — it weights
Nunavut's 9 orders against Ontario's 302 rather than treating them as equals —
and a reader who checks the column by hand will get the other number and
conclude the table is broken.

Rounding is the quiet version. Worksheet 01 Q5 sums a rounded export and lands a
penny away from the truth; worksheet 02 Q8 does the same thing to an
intermediate result and finds **Prarie and West each `-0.01` out** while the
other six regions reconcile exactly. Round for presentation, never for storage.

And worksheet 04 Q6 is the reshaping version: `unstack().stack()` on data with
gaps returns **32 rows where 30 went in**. The two extra rows are combinations
that never happened, now present in your data as records with missing values.

## How to use the solutions

Each solution quotes the actual printed output, so you can see *where* you
diverged rather than only *that* you did. The prose after each answer explains
why the result is what it is, and flags the cases where a correct-looking number
is not a trustworthy one.

If you are a student who found this folder: you will learn more from being stuck
for five minutes than from reading ahead. Use the next line, not the whole
notebook.
