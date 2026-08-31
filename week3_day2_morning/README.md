# Week 3, day 2 — reshaping and transformation

Pandas continued, across two lectures: getting data into the shape you need
(L04), and cleaning the values once it is there (L05).

Ten worksheets, four extra-practice sheets and a four-tier graded ladder —
**170 questions**. Every one was
executed in the lab image before it was written down, and every number quoted in the solutions is output that was
actually observed — not predicted, not rounded for tidiness.

```
exercises/                 worksheets 01–10, organised by topic
exercises/graded/          a four-tier ladder, organised by difficulty
exercises/more-practice/   a second sheet for four of the topics
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

| # | Sheet | Covers |
|---|---|---|
| 06 | [`06_duplicates.ipynb`](exercises/06_duplicates.ipynb) | `duplicated`, `drop_duplicates`, `subset`/`keep`, and near-duplicates |
| 07 | [`07_transform_values.ipynb`](exercises/07_transform_values.ipynb) | `replace` vs `map`, and `.loc[mask]` for conditions |
| 08 | [`08_binning.ipynb`](exercises/08_binning.ipynb) | `cut` and `qcut`, boundaries, and values that fall outside |
| 09 | [`09_outliers.ipynb`](exercises/09_outliers.ipynb) | the IQR fence, the z-score, and what removing them costs |
| 10 | [`10_encoding_and_capstone.ipynb`](exercises/10_encoding_and_capstone.ipynb) | `get_dummies`, `sample`, and the whole day end to end |

## Extra practice

A second sheet for four of the topics — eight questions each, same numbering as
the main worksheets, all on the same real files.

| # | Sheet | Second pass at |
|---|---|---|
| 03 | [`more-practice/03_unstack_more.ipynb`](exercises/more-practice/03_unstack_more.ipynb) | `unstack` on counts and means, and when `fill_value=0` is a lie |
| 05 | [`more-practice/05_pivot_table_more.ipynb`](exercises/more-practice/05_pivot_table_more.ipynb) | `aggfunc`, per-column aggregates, ratio-of-sums vs mean-of-ratios |
| 07 | [`more-practice/07_transform_more.ipynb`](exercises/more-practice/07_transform_more.ipynb) | standardising a join key, and rule order with overlapping conditions |
| 09 | [`more-practice/09_outliers_more.ipynb`](exercises/more-practice/09_outliers_more.ipynb) | fences within group, and three rules compared side by side |

These live one directory down, so they read the data as **`../data/`**. That is
the only difference from the main sheets.

## Graded ladder — organised by difficulty, not by topic

The numbered worksheets cover L04 and L05 **by subject**, one topic per sheet.
These four cover the same ground **by difficulty**, mixing both lectures
throughout. Start at tier 1 and stop when it hurts.

| Tier | Sheet | Shape of every question |
|---|---|---|
| 1 | [`graded/01_tier1_foundations.ipynb`](exercises/graded/01_tier1_foundations.ipynb) | one operation, one or two lines |
| 2 | [`graded/02_tier2_combining.ipynb`](exercises/graded/02_tier2_combining.ipynb) | chain two or three; in three of them the order matters |
| 3 | [`graded/03_tier3_diagnosis.ipynb`](exercises/graded/03_tier3_diagnosis.ipynb) | here is code that **ran fine and is wrong** — find why |
| 4 | [`graded/04_tier4_open.ipynb`](exercises/graded/04_tier4_open.ipynb) | a business question, no method prescribed |

Difficulty rises **within** each sheet as well as between them, and every
question is tagged `[easy]`, `[medium]`, `[harder]` or `[error]`.

**Tier 3 is the one that matters.** Nine of its ten questions hand you code
that produces a confident, plausible, wrong number — a `pivot_table` reporting
means as if they were totals, a `cut` that silently drops 17% of revenue, a
`groupby` that discards 50 rows, an outlier filter that removes 57% of the
business. Only the tenth raises. That ratio is the point.

**Tier 4 asks for three things per answer**: the figure, the denominator it is
computed over, and one sentence on what would change it. Its first question —
"which region is growing?" — has `Nunavut +728.5%` as the headline answer, off
**nine orders in the entire file**.

These live one directory down, so they read the data as `../data/`.

## The data

Derived from the same real superstore extract as week2_day5_morning and
week3_day1_afternoon —
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
deterministically for the L05 block:

- the first 40 rows are appended again — **28 as exact copies, 12 with a
  trailing space on the name**, so some are duplicates and some only look like
  it. `drop_duplicates()` removes 29 and leaves 11 pairs that differ by one
  invisible character;
- every 9th `Province` becomes `N/A`, `-` or `?` in rotation;
- every 15th `CustomerName` gains a trailing space.

Two things about that file were **not** planted and are worth knowing. The
source spells it **`Saskachewan`**, missing a `t` — the same kind of error as
`Prarie` in the region column. And `read_csv` silently converts the `N/A`
markers to `NaN` while leaving `-` and `?` as text, so the file arrives with two
different encodings of "missing" and only one of them is visible to
`isna()`.

## This class needs pandas

Same image requirement as week3_day1_afternoon. `quay.io/jupyter/base-notebook`
ships without
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

**It runs offline, after a one-time fetch.** The notebook downloads seven
CSVs with `!curl -sS -o ...` from
`https://s3.amazonaws.com/weclouddata/datasets/genai/ml_fundamentals/` — the
telecom dataset, and six tables of the MySQL `employees` sample schema. Needing
the network mid-class is no good, so fetch them once:

```bash
python3 scripts/fetch_lab_data.py            # ~136 MB, run once per machine
python3 scripts/fetch_lab_data.py --verify   # check they are in place
```

After that the lab works with the network **down**. The `curl` cells fail
visibly and harmlessly — curl gives up at DNS resolution, *before* it opens the
output file, so the pre-placed CSV is untouched — and the `read_csv` cells that
follow find the data already there. Verified: with the host unreachable, both
files came through byte-identical and `read_csv` returned `(7043, 21)` and
`(9, 2)`.

The data is **not committed**. `employee_salaries.csv` alone is 94 MB — past
GitHub's warning threshold and near its hard limit — so all seven are in
`.gitignore`. The copy under `solutions/` is hardlinked to the one under
`exercises/`, so 136 MB is used once rather than twice, and
`collect_solutions.py` re-links them after it rebuilds the mirror.

`curl` itself is not in `base-notebook`; `jupyter-sql/Dockerfile` installs it,
so the vendor notebook runs exactly as shipped rather than being edited.

The ten worksheets in this folder deliberately depend on none of that: every
file they read is in `data/`, on disk, and they work with the network down.

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
| 06 | `KeyError: Index(['Customer_ID'])` | one underscore |
| 07 | `AttributeError: 'float' object has no attribute 'split'` | `map` with a *function* meets the `NaN`s; with a *dict* it stayed silent |
| 08 | `ValueError: Bin edges must be unique` | too few distinct values to quarter |
| 09 | `TypeError: Cannot perform reduction 'mean' with string dtype` | neither outlier rule checks that its input is numeric |
| 10 | `KeyError: "None of [Index(['Segment'])] are in the [columns]"` | the column exists — in the *other* file |
| mp 03 | `ValueError: index must be a MultiIndex to unstack` | nothing to move |
| mp 05 | `AttributeError: 'total' is not a valid function` | the name is `sum` |
| mp 07 | `AttributeError: Can only use .str accessor with string values` | `.str` on a float column |
| mp 09 | `ArrowNotImplementedError: Function 'quantile' has no kernel...` | pandas 3 backs strings with Arrow, so the error names a layer you did not know you were using |
| graded 1 | `ValueError: Index contains duplicate entries` | `pivot` where `pivot_table` was needed |
| graded 2 | `ValueError: Bin edges must be unique` | 10 quantiles from 4 distinct years |
| graded 3 | `ValueError: Index contains duplicate entries` | the only one of ten that raises — the other nine just lie |
| graded 4 | `TypeError: Cannot perform reduction 'mean' with string dtype` | "what is the average region?" is a category error, not a hard question |

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

**4. `get_dummies` returns booleans, not `0`/`1`.** The L05 slide shows the
encoded cells as `0` and `1`, and that was right until pandas 2.0 changed the
default to `bool`. The values are equivalent; the dtype is not, and it matters
when the result is concatenated with numeric data or written to CSV. Pass
`dtype=int` for the deck's version. *(Worksheet 10 Q2.)*

**5. `unique()` returns neither a NumPy array nor `dtype=object`.** The L05
slide asserts both. In this Pandas a text column gives an **`ArrowStringArray`**
with `dtype: str`. Code that checked `isinstance(x, np.ndarray)` or
`dtype == object` now takes the wrong branch silently. *(Worksheet 06 Q7.)*

And these the decks never mention:

- **`unstack()` promotes integer columns to float** the moment one combination
  is missing, because `NaN` is a float. *(Worksheet 03 Q5.)*
- **`groupby` sorts your result** whether you want it to or not — alphabetically
  by key, which is why text month names come out `Apr, Aug, Dec, Feb…`
  *(Worksheet 02 Q2.)*
- **`margins=True` on a mean is not the mean of the column.** The margin is
  computed from the underlying rows, so it weights every record once instead of
  every group once. *(Worksheet 05 Q8.)*
- **`cut` discards anything outside its outermost edges**, silently — including
  values sitting exactly on the lowest edge, because intervals are right-closed.
  *(Worksheet 08 Q3, Q4.)*
- **`read_csv` already treats `N/A` as missing** but not `-` or `?`, so a file
  using all three arrives with two different encodings of the same idea.
  *(Worksheet 07 Q2.)*
- **`replace` keeps the values you did not list; `map` discards them.** Same
  dictionary, same column, and `map` turned 62% of it into `NaN`.
  *(Worksheet 07 Q6.)*

## A theme worth naming

The same one the SQL and Pandas sessions have run on: **the dangerous results
are the ones that do not raise.**

Worksheet 05 Q8 is the sharpest case. The eight regional averages for 2012
average to `1995.2`; the `All` margin on the same table reads `1522.22`. Both
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

The transformation half has its own version, and it is the sharpest number in
the folder. Worksheet 09 flags outliers with the standard 1.5xIQR fence and
removes them — **11.3% of the rows, carrying 56.8% of the revenue.** Mean order
value drops from `1468.96` to `715.08`. Every one of those 123 orders is real;
they are the large customers. The z-score rule on the same column flags 27 rows
rather than 123, a factor of 4.6, and neither answer is wrong. 'Remove the
outliers' names no method, and the two obvious methods disagree by five times.

Worksheet 08 Q4 is the quiet one: binning `Sales` with a top edge of 10,000
leaves 19 orders unbinned and **274,216 of revenue — 17% — outside every band**,
while `value_counts()` prints four tidy bands that look complete.

## How to use the solutions

Each solution quotes the actual printed output, so you can see *where* you
diverged rather than only *that* you did. The prose after each answer explains
why the result is what it is, and flags the cases where a correct-looking number
is not a trustworthy one.

If you are a student who found this folder: you will learn more from being stuck
for five minutes than from reading ahead. Use the next line, not the whole
notebook.
