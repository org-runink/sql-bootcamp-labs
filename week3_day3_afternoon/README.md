# Week 3, day 3 — Snowflake: Snowsight and batch ingestion

Two WeCloudData labs — *Getting Started with Snowflake and Snowsight* and
*Ingest Data in Snowflake* — as five worksheets, fifty questions.

The day splits in half, and the split is deliberate.

**Worksheets 01 and 02 run in Snowflake**, in your own account. They carry the
lab's real SQL: the sample-data queries, the stages, the `COPY INTO`. Nothing in
this container can execute them, so they have **no code cells at all** — an empty
Python cell in a notebook that cannot reach Snowflake is a trap, and a student
who runs it and sees nothing happen learns the wrong thing. Their answer space is
a markdown block to paste your query and Snowsight's output into.

**Worksheets 03, 04 and 05 run here**, on the exact two CSVs the ingestion lab
loads. Every number quoted in those solutions is output that was observed in the
lab image — not predicted, not rounded for tidiness.

That asymmetry is stated in every one of the five notebooks, and the repo's
checks enforce it: `scripts/check_exercises.py` requires 01 and 02 to have no
code cells and their solutions to say they were not executed.

```
exercises/                    worksheets 01–05
exercises/data/               the two CSVs the lab loads
exercises/snowflake-scripts/  the lab's four .sql scripts, unmodified
exercises/labs/               both lab pages, saved for offline reading
solutions/                    the answers, with the real output quoted
```

## The worksheets

| # | Sheet | Runs | Covers |
|---|---|---|---|
| 01 | [`01_snowsight_and_sample_data.ipynb`](exercises/01_snowsight_and_sample_data.ipynb) | Snowflake | context and warehouse, `TPCH_SF1`, the five lab tasks, query profile, the result cache |
| 02 | [`02_ingest_stages_and_copy.ipynb`](exercises/02_ingest_stages_and_copy.ipynb) | Snowflake | named internal stages, querying a stage directly, `COPY INTO`, load metadata, `STG_SALES_2` |
| 03 | [`03_inspect_before_you_load.ipynb`](exercises/03_inspect_before_you_load.ipynb) | here | the file as bytes, the filename's claim, duplicate keys, the grain |
| 04 | [`04_what_copy_into_does.ipynb`](exercises/04_what_copy_into_does.ipynb) | here | each `FILE_FORMAT` setting rebuilt in pandas, and what breaks without it |
| 05 | [`05_validate_the_load.ipynb`](exercises/05_validate_the_load.ipynb) | here | what the lab's validation script checks, and the eight things it does not |

Read them in order. 03 to 05 refer back to the SQL in 01 and 02, and 02's last
question hands off to 03.

## The data

`data/products_2013_01_01.csv` and `data/sales_2013_01_01.csv` — the lab's own
files, unmodified, from `Lab_Ingest_Data_in_Snowflake_Datasets_and_Scripts.zip`
and `products.zip`. They are here so worksheets 03 to 05 run with the network
down, and so you have something to upload in worksheet 02 without hunting for
the download.

| File | Rows | Columns |
|---|---|---|
| `products_2013_01_01.csv` | 1,215 | 11 — the product master |
| `sales_2013_01_01.csv` | 100,000 | 14 — the transactions |

Nothing was injected. Everything worksheets 03 to 05 find was already in the
files WeCloudData ships.

## The four SQL scripts

Copied unmodified into `exercises/snowflake-scripts/`, in the order they run:

| Script | What it does |
|---|---|
| `1_environment_setup.sql` | `LABDB`, and the `RAW` / `CORE` schemas |
| `2_create_internal_stage.sql` | `PRODUCTS_STAGE` and `SALES_STAGE` |
| `3_Stage_tables.sql` | `CREATE TABLE IF NOT EXISTS` + the two transformational `COPY INTO` statements |
| `4_Validate_stage_tables.sql` | row counts per `BATCH_ID` — and one statement that fails |

Worksheet 05 question 10 reads these files, which is why they are mirrored into
`solutions/` as well: the published answer quotes the file list it finds, and
would report a different one if they were missing.

## What the local worksheets find

All of it in a table that loads cleanly, reports `LOADED`, and passes
`4_Validate_stage_tables.sql` with 100,000 rows under one batch.

| Finding | Where |
|---|---|
| The file is named `sales_2013_01_01.csv`; the dates run **2009-01-01 to 2012-12-30**, and **zero rows** fall on 2013-01-01 — while the COPY stores that filename as `BATCH_ID` "for lineage" | 03 Q3 |
| The CSV header says `SHIPMODE`; the table declares `SHIP_MODE`. Positional loading never notices | 03 Q4, 03 Q10 |
| Text values arrive with **three** quote characters a side, so `FIELD_OPTIONALLY_ENCLOSED_BY` strips one pair and one pair becomes data. `WHERE PRIORITY = 'High'` returns **0** rows; 21,117 are there | 03 Q5, 04 Q6 |
| `TRANS_ID` repeats **92,084** times. Adding `PROD_KEY` changes nothing; adding `STORE_KEY` makes every row unique — the grain is per store, not per line item | 03 Q6 |
| The 1,215-row product master has **3 duplicate `PROD_KEY`s**, two of them with contradictory categories | 03 Q7 |
| `SALES_AMT` equals `SALES_QTY x SALES_PRICE` in **33 rows of 100,000** | 03 Q9 |
| **38.1%** of dates would land on a different valid date under `DD/MM/YYYY`. The whole-column reparse only fails because one row happens to have a day above 12 | 04 Q7, Q8 |
| **49 days** in the range have no rows at all — and the gaps are spread evenly across weekdays, so it is not weekend closure | 05 Q5, Q6 |
| **50,039 rows — exactly 50.0% — have a negative margin**, and `SALES_COST` has a minimum of `-8.31` | 05 Q7, Q8 |
| `SALES_AMT - SALES_COST` equals `SALES_MGRN` in **41 rows**. In total: revenue 146.6M, cost 159.9M — a 13.4M loss — while the margin column sums to a 19.1M profit | 05 Q8 |
| Joining sales to products gains **324 rows** and invents **606,705.92** of revenue — 0.414%, small enough to pass review | 05 Q9 |
| `4_Validate_stage_tables.sql` ends with `DROP TABLE CORE.DIM_CALENDAR;`. Nothing in either lab creates that table | 05 Q10, 02 Q10 |

## Some cells are supposed to fail

Two, both in the local sheets, both making a point that needs the error to make
it:

| Sheet | Q | Raises | Why it is there |
|---|---|---|---|
| 03 | 10 | `ValueError: Usecols do not match columns... ['SHIP_MODE']` | reading by **name** catches the header mismatch that loading by **position** cannot |
| 04 | 4 | `TypeError: can only concatenate str (not "float") to str` | a header loaded as data splits one column into 65,536 strings and 34,465 floats — and 65,536 is pandas' chunk size, not anything in the file |

Worksheet 04 Q4 is the one to sit with. Had the file been under 65,536 rows,
`sum()` would have **succeeded** and returned a 400 KB string of concatenated
digits. The exception is the lucky outcome.

## The theme

Same one the SQL and Pandas sessions ran on, arriving from a new direction:
**the dangerous results are the ones that do not raise.**

Every finding in the table above sits in a table that loaded successfully. The
`COPY INTO` reported `LOADED`, `rows_parsed` matched `rows_loaded`,
`errors_seen` was 0, and the validation script returned one tidy row per batch.

Row counts prove **arrival**. They cannot prove the dates are what the filename
says, that a text column is queryable, that a key is unique, or that three money
columns describe the same transaction. Those checks cost about ten lines each and
somebody has to decide to write them.

Worksheet 05 question 10 turns that on the pipeline itself. The lab's
*validation* script — the file whose whole job is to tell you whether something
failed — has a statement in it that fails every time it runs, because nobody ever
executed it end to end in a clean account. Validate the data, not just the load;
then validate the validation.

## Verification

Worksheets 03 to 05 were executed in the lab image with
`jupyter nbconvert --to notebook --execute --allow-errors`, and the only two
cells that errored are the two intended ones above.

**145 distinct numeric literals** quoted in those three solutions were then
matched, one by one, against the output of that execution. Two of them are
cross-references — worksheet 05 cites the duplicate `PROD_KEY`s worksheet 03
found — and the check reports those explicitly rather than accepting them
silently.

Worksheets 01 and 02 have no such guarantee, and say so in their own text.
Where they quote a figure, it is either the lab's own claim, a cardinality fixed
by the TPC-H specification, or a count worksheets 03 to 05 measured locally on
the same file — and the answer says which.

Verified against **pandas 3.0.5** on Python 3.13.15.

## How to use the solutions

Each local solution shows the code, then the actual printed output, then the
reasoning — so you can see *where* you diverged rather than only *that* you did.

The Snowflake solutions are structured the same way, but you are the one who
runs them. Paste what Snowsight gave you into the exercise notebook as you go;
when your number differs from the solution's, that difference is the lesson.
