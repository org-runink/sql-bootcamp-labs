# Week 4, day 2 (afternoon) — dbt on Snowflake

Build a complete dbt warehouse — raw → staging → EDW star schema → marts — and
run it inside Snowflake.

Two things to move:

| | What | Where it goes |
|---|---|---|
| **SQL scripts** | `snowflake-sql/*.sql` | paste into a Snowsight worksheet, in order |
| **dbt project** | `dbt-project/demo/` | upload to a Workspace or a stage |

Plus `data/products.csv` and `data/sales.csv`, which you upload to a stage.

---

## Run it

### 1. Set up and grant — `snowflake-sql/01_setup_and_grants.sql`

Run as **ACCOUNTADMIN**. Creates the warehouse, `DEMO_DB`, and the five layer
schemas — then hands ownership to `SYSADMIN`.

> **Do not skip the grants.** Whoever runs the `CREATE`s owns the result. dbt
> runs as the role in `profiles.yml` (`SYSADMIN`), and if a different role owns
> the schemas every model fails with *"Insufficient privileges to operate on
> schema"*. `dbt compile` will not warn you — compiling never touches the
> warehouse.

The script ends by printing each schema's owner. All five must say `SYSADMIN`.

### 2. Raw objects — `snowflake-sql/02_raw_objects.sql`

File format, two stages, two raw tables.

> `DATE_FORMAT = 'MM/DD/YYYY'` matters. `TRANS_DT` is written `M/D/YYYY`;
> without it, every date whose day and month are both ≤ 12 is silently misread
> rather than rejected.

### 3. Load the CSVs — `snowflake-sql/03_load_and_verify.sql`

**Upload first** (a worksheet cannot read your laptop):
Snowsight → **Data → Databases → DEMO_DB → RAW → Stages → LOAD_STAGE → + Files**
→ add `data/products.csv` and `data/sales.csv`.

Then run the script. Expect **1,214** products and **100,000** sales, with dates
spanning **2009-01-01 to 2012-12-30**. The row count proves arrival; the date
range proves the parse.

### 4. Upload the dbt project

Everything in `dbt-project/demo/`, preserving folders, so `dbt_project.yml`
lands at the **root** of wherever you point dbt.

- **Workspace** — Snowsight → Projects → Workspaces, upload or clone the folder.
- **Stage** — upload to `@DEMO_DB.RAW.DBT_PROJECT_STAGE/demo/`.

Do not upload `target/`, `logs/`, or `profiles.example.yml`.

### 5. Run dbt — `snowflake-sql/04_run_dbt.sql`

Pick the Workspace or the stage route; the script has both.

> **Use `build`, not `run`.** `dim_product_t6` reads `product_snapshot`, and
> `run` never builds snapshots. `build` sequences seeds → snapshots → models →
> tests, and stops a downstream model when an upstream test fails.

### 6. Inspect — `snowflake-sql/05_inspect.sql`

The layers, the Type 6 dimension, the star, the marts, and `GET_DDL` on what dbt
wrote.

### 7. Schedule / clean up — `snowflake-sql/06_schedule_and_teardown.sql`

A `TASK` for the schedule, and the teardown. **Suspend the task when you finish**
or it keeps consuming credits.

---

## When it breaks

| Error | Cause |
|---|---|
| `Insufficient privileges to operate on schema` | Script 01's grants not run, or `profiles.yml` names a different role |
| `found N package(s)... only 0 installed` | Something added packages. `packages.yml` ships empty — Snowflake has no outbound internet, so `dbt deps` cannot fetch them |
| `takes no keyword argument 'arguments'` | A test's parameters got nested under `arguments:`. Snowflake runs dbt 1.9.4, which needs them top-level |
| `RAW.PRODUCT does not exist` | Run scripts 02 and 03 first |
| `Got a block definition inside control flow` | A live Jinja tag inside a comment — dbt renders comments too |

Before uploading a changed project, run `python3 scripts/check_dbt_project.py`.
It catches all of the above on disk.

**Verified runtime: dbt 1.9.4 / dbt-snowflake 1.9.2.** `compile` resolves the
whole project: 10 models, 2 snapshots, 1 analysis, 2 seeds, 42 data tests,
2 sources, 1 exposure, 11 metrics, 3 semantic models, 3 saved queries,
2 unit tests.

---

## What gets built

```
RAW  ──▶  STG  ──▶  EDW  ──▶  MARTS
 │         │         │          │
 │         │         │          ├─ rpt_*   hand-written models
 │         │         │          └─ mart_*  exported from MetricFlow saved queries
 │         │         └─ dim_product_t6 (Type 6) / dim_store / dim_date / fct_sales
 │         └─ stg_product_incr / stg_sales + the snapshots
 └─ product / sales               + seeds: store_master, category_targets
```

| Object | Schema | Kind |
|---|---|---|
| `stg_product_incr` / `stg_sales` | STG | incremental (`merge`) / view |
| `product_snapshot` / `sales_snapshot` | STG | snapshots (check / timestamp) |
| `store_master`, `category_targets` | SEED | seeds |
| `dim_product_t6` | EDW | **Type 6** SCD + surrogate key |
| `dim_store`, `dim_date` | EDW | Type 1 dim; smart-key date dim |
| `fct_sales` | EDW | incremental (`delete+insert`) — the star's fact |
| `metricflow_time_spine` | EDW | dense calendar the semantic layer needs |
| `rpt_*` (3) | MARTS | hand-written |
| `mart_*` (3) | MARTS | MetricFlow saved-query exports |

Plus 4 macros, 2 custom generic tests, an exposure, an analysis, 42 data tests,
2 unit tests, 3 semantic models, 11 metrics.

**No packages, on purpose.** Snowflake has no outbound internet, so `dbt deps`
cannot reach the dbt Hub, and a `packages.yml` listing an uninstalled package
fails *every* dbt command. The three things a package would have supplied are
written by hand: `macros/surrogate_key.sql`, a Snowflake `GENERATOR` time spine,
and `tests/generic/{column_between,row_count_between}.sql`.

---

## The concepts

### Materializations

| | dbt does | Use when |
|---|---|---|
| **view** (default) | `CREATE VIEW` each run | light transformation, no storage |
| **table** | `CREATE TABLE` each run | queried often |
| **incremental** | insert/update new rows only | full rebuild too slow |
| **ephemeral** | nothing — inlined as a CTE | a step one or two models need |

Start with a view; when it is slow to query make it a table; when the table is
slow to build make it incremental.

### Configuring a model — three routes, highest priority first

1. `config()` **inside the `.sql`** — for things intrinsic to the query
   (incremental strategy, `unique_key`)
2. `config:` in a **properties `.yml`** — per-model settings, beside the docs
   and tests
3. **`dbt_project.yml`** under `models:` — folder-wide defaults

Sources, seeds, snapshots, exposures, unit tests, semantic models and metrics
are **YAML-only**; the `.sql` files hold the `SELECT` and nothing else.
Elsewhere you would scaffold all this with `dbt init`.

### Slowly-changing dimensions

| Type | Behaviour |
|---|---|
| 1 | overwrite; only "now" exists |
| 2 | a new row per version, with validity dates |
| 3 | keep a `previous_*` column |
| **6** | **1 + 2 + 3 together** (1 × 2 × 3 = 6) |

`dim_product_t6` carries all three per row — `category_name` (as it was),
`current_category_name` (today's, on every row), `previous_category_name` (what
it changed from) — so the same fact can be reported "as was" or "as is" without
touching the fact table. The **snapshot** supplies the Type 2 raw material.

### Star schema

A fact surrounded by dimensions, joined on **surrogate keys**. The fact holds
only keys and measures, at a stated grain: one row per date / product version /
store. A surrogate key is warehouse-generated — `prod_key` alone cannot key an
SCD, because a product has one row per version.

### Tests

- **Data tests** run against the warehouse; each compiles to a query returning
  the offending rows, so zero rows = pass. The four generics are `unique`,
  `not_null`, `accepted_values`, `relationships`.
- **Unit tests** feed a model mock rows and assert exact output — logic, no
  warehouse data. Ideal for SCD rules.
- Write test parameters at the **top level**, not under `arguments:`.

---

## Files

```
week4_day2_afternoon/
├── snowflake-sql/          01–06, paste into Snowsight in order
├── dbt-project/demo/       the dbt project — upload this folder
├── data/                   products.csv, sales.csv — upload to LOAD_STAGE
└── exercises/ solutions/   the same lab as a notebook, if you prefer that route
```

`dbt-project/demo/README.md` covers the project itself — what to upload, the
packages trade-off, and the layout.
