# Week 3, day 1 (afternoon) — 30/08

> Folders and worksheet titles both name the position in the course. The
> calendar date this session was taught on is in the heading above, and
> nowhere else.

Pandas, across three lectures: what a Series and a DataFrame actually are, the
core operations you use on every dataset, and how data gets in and out.

Fifteen worksheets and five extra-practice sheets — 200 questions. Every one was
executed in the lab image before it was written down, and every number quoted in
the solutions is output that was actually observed — not predicted, not rounded
for tidiness.

```
exercises/                 worksheets 01–15
exercises/more-practice/   a second sheet for five of the topics
exercises/wcd-originals/   the course's own notebooks, byte-identical
exercises/data/            the files the worksheets read
solutions/                 the answers, with the real output quoted
```

## Part 1 — Introduction to Pandas (L01), worksheets 01–04

| # | Sheet | Covers |
|---|---|---|
| 01 | [`01_series.ipynb`](exercises/01_series.ipynb) | values and labels, selection, comparisons, alignment on a Series |
| 02 | [`02_dataframes.ipynb`](exercises/02_dataframes.ipynb) | dict-of-columns vs list-of-records, `dtypes`, `info`, `describe`, `count` vs `len` |
| 03 | [`03_the_index.ipynb`](exercises/03_the_index.ipynb) | the `Index` object, duplicate labels, `set_index`, `MultiIndex`, immutability |
| 04 | [`04_loc_and_iloc.ipynb`](exercises/04_loc_and_iloc.ipynb) | labels vs positions, and the slice rule nobody mentions |

## Part 2 — Core functionality (L02), worksheets 05–10

| # | Sheet | Covers |
|---|---|---|
| 05 | [`05_reindexing.ipynb`](exercises/05_reindexing.ipynb) | `reindex` vs selection, `fill_value`, making absent records visible |
| 06 | [`06_dropping.ipynb`](exercises/06_dropping.ipynb) | `drop` returns a copy, `dropna`'s defaults, `errors="ignore"` |
| 07 | [`07_filtering.ipynb`](exercises/07_filtering.ipynb) | boolean masks, `&`/`\|`/`~`, `isin`, `between`'s boundaries |
| 08 | [`08_alignment.ipynb`](exercises/08_alignment.ipynb) | label alignment, case and whitespace mismatches, two-axis alignment |
| 09 | [`09_apply_and_map.ipynb`](exercises/09_apply_and_map.ipynb) | `apply` vs `map`, unmapped values, `axis=1`, vectorising instead |
| 10 | [`10_sorting_and_ranking.ipynb`](exercises/10_sorting_and_ranking.ipynb) | `sort_values` returns a copy, all five tie-breaking rules |

## Part 3 — Reading and writing data (L03), worksheets 11–14

| # | Sheet | Covers |
|---|---|---|
| 11 | [`11_reading_csv.ipynb`](exercises/11_reading_csv.ipynb) | `sep`, `skiprows`, `na_values`, `usecols`, `parse_dates` |
| 12 | [`12_chunked_reading.ipynb`](exercises/12_chunked_reading.ipynb) | `chunksize`, accumulating across chunks, `pd.concat`, float sums |
| 13 | [`13_json_data.ipynb`](exercises/13_json_data.ipynb) | flat vs nested JSON, `json_normalize`, `orient` |
| 14 | [`14_excel_and_capstone.ipynb`](exercises/14_excel_and_capstone.ipynb) | sheets, `ExcelWriter`, `index=False`, and the full pipeline |

## Synthesis — worksheet 15

| # | Sheet | Covers |
|---|---|---|
| 15 | [`15_pipelines_and_roles.ipynb`](exercises/15_pipelines_and_roles.ipynb) | a SQL and Python refresher, then batch and streaming pipelines seen from four job roles |

Twenty questions, and the only sheet that talks to the **real MySQL** from the
SQL sessions as well as to a REST endpoint. It refreshes both languages and then
builds the same flow four times, once per role:

| Role | Owns | The question they are paid to answer |
|---|---|---|
| **ETL/ELT engineer** | getting data out and in, repeatably | "did every row arrive, exactly once?" |
| **Analytics engineer** | what the numbers *mean* | "what is one row of this table?" |
| **Streaming/Platform engineer** | the pipe, while it is running | "what happens when it breaks halfway?" |
| **ML/AI engineer** | features and what the model saw | "would this column have existed at prediction time?" |

It needs the database container running (`mysql-lan`) but **no internet** — the
REST endpoint is served from inside the notebook, on `127.0.0.1:8931`, so the
streaming section works on a classroom network that blocks everything. The
setup cell is deliberately safe to re-run, which is the same idempotency
property its own Q8 asks of an extract job.

## Extra practice

A second sheet for the five topics that most need repetition. Same numbering as
the main worksheets, eight questions each, all on the real sales file.

| # | Sheet | Second pass at |
|---|---|---|
| 01 | [`more-practice/01_series_more.ipynb`](exercises/more-practice/01_series_more.ipynb) | Series, `value_counts`, grouped Series |
| 04 | [`more-practice/04_loc_and_iloc_more.ipynb`](exercises/more-practice/04_loc_and_iloc_more.ipynb) | labels vs positions on a sorted frame |
| 07 | [`more-practice/07_filtering_more.ipynb`](exercises/more-practice/07_filtering_more.ipynb) | compound conditions, dates, writing into a filtered frame |
| 09 | [`more-practice/09_apply_and_map_more.ipynb`](exercises/more-practice/09_apply_and_map_more.ipynb) | partial lookups, `axis=1`, vectorising instead |
| 11 | [`more-practice/11_reading_csv_more.ipynb`](exercises/more-practice/11_reading_csv_more.ipynb) | turning load checks into tests |

These live one directory down, so they read the data as **`../data/sales.csv`**.
That is the only difference from the main sheets.

## The data

Everything in `data/` comes from the same real superstore extract week2_day5_morning
class used — 1,093 orders joined to their customers and products. Nothing is
invented, with one documented exception noted below.

| File | Rows | What it is for |
|---|---|---|
| `sales.csv` | 300 | the default sheet, comma-separated and clean |
| `sales.tsv` | 300 | the same 300 rows, tab-separated |
| `sales_report.csv` | 300 | the same rows behind three metadata lines and a blank one |
| `sales_messy.csv` | 300 | the same rows with `?` and `Missing` used as placeholders |
| `big_sales.csv` | 1,093 | the full file, for chunked reading |
| `customers.json` | 120 | flat JSON, `orient="records"` |
| `orders_nested.json` | 80 | each record has a nested `customer` object |
| `quarterly.xlsx` | 300 | the same 300 orders split across sheets `Q1`–`Q4` |

**The one invented thing** is the missingness in `sales_messy.csv`, injected
deterministically so `na_values` has something real to do: every 7th row's
`Discount` becomes `?`, every 11th row's `Region` becomes `Missing`, and every
13th row's `Profit` is left empty. They overlap on some rows, and the counts the
solutions quote — 43, 28 and 24 — are whatever that real overlap produced.

Three things worth knowing about the real data before you teach from it:

- The region is spelled **`Prarie`**, not `Prairie`. Filtering for the correct
  spelling returns zero rows and no error. Worksheet 07 makes this a question.
- 301 of the 1,237 product names contain a comma and 103 contain a double
  quote. That is what makes the CSV-vs-TSV quoting lesson in worksheet 11 real
  rather than hypothetical.
- Every one of the 300 `Sales` values in the sample is distinct, so ties never
  arise and all five ranking methods agree. Worksheet 10 Q9 says so explicitly,
  because a clean result on a sample proves the code ran, not that it is right.

## The original WeCloudData notebooks

The course's own Pandas notebooks are kept **byte-identical** to what was
shipped, split so the answers do not sit next to the exercises:

| Where | File |
|---|---|
| [`exercises/wcd-originals/`](exercises/wcd-originals) | `Lab2_Pandas_Data_Processing_Starter.ipynb`, `Exercise_Pandas_Data_Processing_Starter.ipynb` |
| [`solutions/wcd-originals/`](solutions/wcd-originals) | the two matching `_Solution.ipynb` files |

**`Lab2` downloads its data at runtime** from
`https://s3.amazonaws.com/weclouddata/datasets/genai/ml_fundamentals/telecom.csv`
— a 7,043-row telecom churn dataset. That was reachable from the lab container
when this was written, but it means the notebook needs working internet in the
classroom. The fourteen worksheets in this folder deliberately do not: every
file they read is in `data/`, on disk.

## This class needs pandas — the base image does not have it

`quay.io/jupyter/base-notebook` ships without pandas; that is the
`scipy-notebook` image. `jupyter-sql/Dockerfile` installs pandas, numpy,
openpyxl, xlrd, pyarrow, lxml, html5lib, beautifulsoup4, tabulate and
matplotlib explicitly. If a worksheet fails on `import pandas`, rebuild:

```bash
podman-compose up -d --build --force-recreate sql-console
```

Verified against **pandas 3.0.5** on Python 3.13.15. The version matters more
than usual here — see the disagreements section below.

## Some cells are supposed to fail

Every sheet ends on a deliberate error, and it is always the **last** question,
so Restart & Run All reaches the bottom of the notebook before anything raises.

| Sheet | Raises | Why it is there |
|---|---|---|
| 01 | `KeyError: 'Nadia'` | adding a missing label is silent; asking for one is not |
| 02 | `KeyError: 'Salary'` | a missing value is filled, a missing column raises |
| 03 | `TypeError: Index does not support mutable operations` | you may replace the whole index, not one label |
| 04 | `IndexError: index 2 is out of bounds for axis 0 with size 2` | **the lecture slide prints this line and gives an answer for it** |
| 05 | `KeyError: "['S4'] not in index"` | `reindex` invents the row, `.loc` refuses |
| 06 | `KeyError: "['Nickname'] not found in axis"` | the strict default that `errors="ignore"` turns off |
| 07 | `ValueError: The truth value of a Series is ambiguous` | `and` is the English word and the wrong operator |
| 08 | `ValueError: Can only compare identically-labeled Series objects` | adding misaligned Series is fine; comparing them is not |
| 09 | `ZeroDivisionError` | `map` returns `NaN` on a bad value, `apply` stops everything |
| 10 | `KeyError: 'Revenue'` | the column is called `Sales`, and both words are in use |
| 11 | `FileNotFoundError` | the loudest and least harmful failure in the sheet |
| 12 | `StopIteration` | a chunk reader is a one-pass iterator |
| 13 | `ValueError: Expected object or value` | a CSV handed to `read_json` |
| 14 | `ValueError: Worksheet named 'Q5' not found` | name your sheets, do not number them |
| 15 | `AttributeError: Can only use .dt accessor...` | the ETL engineer's untyped column, surfacing in the ML engineer's notebook |
| mp 01 | `KeyError: 'Prairie'` | the correctly-spelled word is the one that fails |
| mp 04 | `KeyError: 500` | a label beyond the end of the file |
| mp 07 | `ValueError: The truth value of a Series is ambiguous` | `or` instead of `\|` |
| mp 09 | `ZeroDivisionError` | 30 orders have a `Discount` of exactly 0; none have a `Profit` of 0 |
| mp 11 | `ValueError: Usecols do not match columns` | `usecols` validates against the header |

## Where the slides and Python disagree

Four places where a deck makes a checkable claim that this Pandas contradicts.
Each is a question with the real output quoted.

**1. `Index([...], dtype="object")` — L01.** Pandas 3.0 made a real string dtype
the default, so this prints `dtype='str'`. Every text column in this class reads
`str`, not `object`. Any tutorial testing `== 'object'` now silently fails on
every text column. *(Worksheets 01 Q1, 02 Q3.)*

**2. `ages.mean() # 22.33` — L01.** Python prints `22.333333333333332`, and
`ages.mean() == 22.33` is `False`. The slide is showing a rounded value without
saying so. *(Worksheet 01 Q3.)*

**3. The concat index — L01.** The slide gives the result index as
`11, 12, 13, 14, 12`. There is no `13` in the source data — the previous slide
shows the frame being concatenated onto, and its index is `11, 12, 12, 14`. The
real answer is `11, 12, 12, 14, 12`, and the version printed hides exactly the
problem the slide is trying to teach. *(Worksheet 03 Q7.)*

**4. `df.iloc[0, 2] # 85` — L02.** The frame on that slide has two columns, so
this raises `IndexError`. The very next slide's summary table writes the same
idea as `df.iloc[0, 1]`, which does work and does give `85`. Two consecutive
slides, one of which cannot run. *(Worksheet 04 Q10.)*

And five things the decks simply never mention, each of which will cost someone
an afternoon:

- **`reindex` promotes `int64` to `float64`.** Add one absent label and every
  integer in the column becomes a float, because `NaN` is a float. *(05 Q3.)*
- **`drop` and `sort_values` return copies.** The printed output looks right and
  the original is unchanged. *(06 Q2, 10 Q2.)*
- **`.loc` slices include their end label; `.iloc` slices exclude their end
  position.** The silent way to lose exactly one row. *(04 Q6.)*
- **`map` returns `NaN` for anything its lookup does not cover**, and the dtype
  does not change, so nothing hints at it. *(09 Q4.)*
- **`rank()` defaults to `method="average"`**, which produces `1.5` for a
  two-way tie. Nobody finished 1.5th. *(10 Q6.)*

## A theme worth naming

The same one the SQL sessions ran on: **the dangerous results are the ones that
do not raise.**

Worksheet 11 is the clearest case. Reading `sales_report.csv` with
`skiprows=2`, `3`, `4` and `5` gives four different tables and **zero**
exceptions. `skiprows=3` and `4` both happen to be right. `skiprows=2` produces
a one-column frame headed `Currency: CAD`. `skiprows=5` eats the header, names a
column `8710` after the first order, and returns 299 rows instead of 300 —
which looks entirely plausible if you did not already know the row count.

Worksheet 12 has the sharpest version. Summing the same column of the same file
two ways gives `1605576.2175` and `1605576.2174999998`. Neither is a bug;
floating-point addition is not associative, so changing the order changes the
rounding. Worksheet 14 Q4 hits it again from a completely different direction —
the same 300 orders read back from four Excel sheets total
`236825.00350000002` against the CSV's `236825.0035` — while worksheet 14 Q8's
`groupby` totals reconcile *exactly*. The honest summary is that the difference
is real, unpredictable, sometimes zero, and must never be tested with `==`.

And worksheet 14 Q8 is the one to end on: `groupby` silently drops rows whose
key is missing. On `sales_messy.csv` that discards 28 orders and nearly £8,000
of sales. The report balances internally, contains no errors, and is short by
3%. `dropna=False` is one argument and the difference between a summary and a
wrong summary.

## How to use the solutions

Each solution quotes the actual printed output, so you can see *where* you
diverged rather than only *that* you did. The prose after each answer explains
why the result is what it is, and flags the cases where a correct-looking number
is not a trustworthy one.

If you are a student who found this folder: you will learn more from being stuck
for five minutes than from reading ahead. Use the next line, not the whole
notebook.
