# Week 4, day 2 (afternoon) — dbt: from raw to data marts

The WeCloudData *Create a dbt Project* lab and the *dbt Fundamentals* (Data
Warehousing L05) lecture, as **one executable worksheet**. You build a complete,
tested dbt project against **your own Snowflake account**: sources, staging,
snapshots, a **Type 6** slowly-changing dimension, a **star schema** on
surrogate keys, business-driven **seeds**, Great-Expectations-style data-quality
checks, **unit tests**, **lineage** across every layer, and a **MetricFlow
semantic layer** whose saved queries export extra data marts.

New to dbt? Read the **primer** below first — it is the vocabulary the whole
worksheet assumes.

---

## Part 1 — a dbt concepts primer

### What dbt is, and where it sits

Modern pipelines are **ELT**: raw data is *loaded* into the warehouse first, then
*transformed* inside it. dbt owns that **T**. It does not move data and it has no
runtime of its own — it compiles your SQL and asks the warehouse to run it.

You write `SELECT` statements. dbt works out the order, wraps each one in the
right `CREATE TABLE` / `CREATE VIEW` / `MERGE`, runs your tests, and builds the
documentation and lineage graph.

What that replaces: a folder of numbered `.sql` scripts where logic is
copy-pasted, dependencies live in someone's head, and "is this number right?" has
no answer.

### The core objects

| Concept | What it is | In this lab |
|---|---|---|
| **Model** | a `.sql` file containing one `SELECT`. dbt materializes it as a table or view. The filename is the model name. | `stg_sales`, `dim_product_t6`, `fct_sales` |
| **Source** | a declaration of a raw table dbt did *not* build, so it can be referenced and tested | `raw.product`, `raw.sales` |
| **`ref()`** | how one model reads another — `{{ ref('stg_sales') }}`. This is what builds the DAG | everywhere |
| **`source()`** | how a model reads a raw table — `{{ source('stg', 'product') }}` | staging models |
| **Seed** | a CSV in the repo, loaded by `dbt seed`. Reference data under version control | `store_master`, `category_targets` |
| **Snapshot** | records how a *mutable* source changes over time (Type 2 history) | `product_snapshot`, `sales_snapshot` |
| **Test** | an assertion about the data. Failing tests stop the build | `unique`, `not_null`, `relationships`, expectations |
| **Unit test** | an assertion about a model's *logic*, run against mock rows | the Type 6 scenario |
| **Macro** | a Jinja function that returns SQL — reusable logic | `to_active_flag`, `pivot_category_amounts` |
| **Package** | an installable library of macros/tests | `dbt_utils`, `dbt_expectations` |
| **Exposure** | documents a downstream consumer (a dashboard) so it appears in lineage | `sales_dashboard` |
| **Analysis** | a templated query dbt compiles but never runs | `top_products` |
| **Metric** | a business definition in the semantic layer, written once | `margin_rate`, `gross_profit` |

**Never hardcode a table name.** Always `ref()` or `source()`. That single habit
is what gives dbt the dependency graph, and everything else — build order,
lineage, impact analysis — follows from it.

### Materializations — how a model is persisted

Set with `materialized:` in a `config()` block or in `dbt_project.yml`.

| Materialization | What dbt does | Use when |
|---|---|---|
| **view** (default) | `CREATE VIEW` on every run | light transformation; no storage; always fresh |
| **table** | `CREATE TABLE` on every run | queried often; the rebuild is affordable |
| **incremental** | inserts/updates only new rows | the full rebuild is too slow |
| **ephemeral** | not built at all — inlined as a CTE | a small step only one or two models need |
| **materialized view** | a warehouse-maintained MV | the warehouse can keep it current for you |

**Rule of thumb:** start with a *view*; when it is too slow to query, make it a
*table*; when the table is too slow to build, make it *incremental*.

### Incremental models

Three parts, always:

1. a `config` marking the model `incremental`,
2. an `{% if is_incremental() %}` block holding a **cutoff filter**,
3. the filter itself, usually against `{{ this }}` — the model's own existing table.

On the first run (and under `--full-refresh`) the block is skipped and everything
is built. After that, only rows past the watermark are processed.

**Strategies** decide how the new rows are applied:

- **`merge`** (Snowflake default) — update matching rows, insert the rest. For
  keyed dimension/staging rows. Used by `stg_product_incr`.
- **`delete+insert`** — delete the rows whose key matches, then insert. For
  recomputed **aggregates**, which must be *replaced*, not merged. Used by
  `fct_sales`.

### Slowly-changing dimensions, and why Type 6

A source row changes and the old value is lost — unless you capture it.

| Type | Behaviour | Cost |
|---|---|---|
| **Type 1** | overwrite; only "now" exists | no history |
| **Type 2** | new row per version, with validity dates | history, but "as was" only |
| **Type 3** | keep a `previous_*` column | one step back only |
| **Type 6** | **1 + 2 + 3 together** (1 × 2 × 3 = 6) | every question answerable |

`dim_product_t6` carries all three on every row:

| View | Column | Answers |
|---|---|---|
| Type 2 | `category_name` | what was it **at the time**? |
| Type 1 | `current_category_name` | re-state history under **today's** value |
| Type 3 | `previous_category_name` | what did it **change from**? |

That is the payoff: the same fact row can be reported "as was" or "as is" without
touching the fact table. dbt's **snapshot** supplies the Type 2 raw material
(`dbt_valid_from` / `dbt_valid_to`); the model derives the other two.

### Star schema and surrogate keys

A **fact** table surrounded by **dimensions**, joined on **surrogate keys**.

```
                  dim_date
                      │
   dim_product_t6 — fct_sales — dim_store
```

- The **fact** holds only keys and **measures**. Its **grain** — one row per
  (date, product version, store) — is stated explicitly, because every measure
  must be additive at the grain.
- The **dimensions** hold the descriptive attributes.
- A **surrogate key** is a warehouse-generated id with no business meaning
  (`dbt_utils.generate_surrogate_key` hashes `prod_key` + `valid_from`).

Why not just use `prod_key`? Because in an SCD it is **not unique** — a product
has one row per version. The surrogate key is unique per *version*, which is what
lets the fact point at exactly the right one. The `unique` test on `product_sk`
in `edw__models.yml` is that guarantee, enforced.

### The layers

| Layer | Schema | Contains | Materialized |
|---|---|---|---|
| **raw** | `RAW` | the two loaded CSVs. dbt only *reads* these | — |
| **staging** | `STG` | 1:1 with sources: rename, cast, select. No joins, no aggregation | views |
| **edw** | `EDW` | conformed dimensions and facts — the star schema | tables |
| **marts** | `MARTS` | business-facing reports | tables |

Each layer is a **folder** *and* a **schema**, which is what makes the lineage
readable and lets you build one layer at a time (`dbt run --select staging`).

### Tests: data vs unit

- A **data test** runs against what is in the warehouse. Each compiles to a query
  returning offending rows; zero rows = pass. The four generic tests are
  `unique`, `not_null`, `accepted_values`, `relationships`.
- **dbt-expectations** (the dbt port of Great Expectations) adds range,
  distribution, shape and freshness assertions — the defects that pass every
  column-level test and still make a report wrong.
- A **unit test** feeds a model mock rows and asserts exact output. It checks
  *logic*, deterministically, with no warehouse data. Ideal for SCD rules, which
  are otherwise only exercised when a source happens to change.

> Write a generic test's parameters at the **top level** under the test name —
> the form the lecture slides use. dbt 1.12 on a laptop accepts a nested
> `arguments:` key and deprecation-warns the top-level form, but the dbt runtime
> **inside Snowflake is older and rejects the nested form outright**:
> `macro 'dbt_macro__test_accepted_values' takes no keyword argument 'arguments'`.
> The top-level form works on both, so it is the portable one.

### The semantic layer (MetricFlow)

Instead of writing another mart in SQL, you *describe* the star schema —
**entities** (the join keys), **dimensions** (what you slice by), **measures**
(what you aggregate) — and define **metrics** on top. MetricFlow generates the
SQL.

The point: `margin_rate` becomes one reviewed definition instead of a formula
five dashboards each re-implement. And a **saved query** with an `export`
materializes a new mart from those definitions, so extra marts cost a few lines
of YAML and cannot drift from the agreed numbers.

### The commands

```bash
dbt deps          # install packages
dbt debug         # check the connection
dbt seed          # load the CSV seeds
dbt run           # build models only
dbt snapshot      # build snapshots only (stateful — advances history)
dbt test          # run tests only
dbt build         # seeds + snapshots + models + tests, in DAG order  <- the one to schedule
dbt docs generate # build manifest.json / catalog.json for the docs site
dbt ls --select +my_model    # what feeds this?
dbt ls --select my_model+    # what breaks if I change it?
dbt compile --select x       # render the SQL without running it
dbt build --full-refresh     # rebuild incrementals from scratch
mf list metrics              # semantic layer: what metrics exist
mf query --metrics total_sales --group-by store__region
```

`dbt build` stops a downstream model when an upstream test fails, so bad data
does not propagate. That is why it is the command you schedule.

---

## Part 2 — the day

### Two artefacts, and that is all

| What | Where | You do |
|---|---|---|
| **The notebook** | `exercises/dbt_lab.ipynb` | import into Snowsight and work down it |
| **The dbt project** | `dbt-project/demo/` | upload the folder to a Snowflake stage |

The notebook is **26 questions, all SQL**. It contains no inline project code:
every model, macro, test and YAML file is a real file in `dbt-project/demo/`,
which you upload once. Read that folder's `README.md` before uploading — it lists
exactly what to include and why `packages.yml` is empty.

**There are no credentials anywhere.** A Snowflake notebook is already
authenticated, and dbt runs as the role that executes the project.

### Before you start

- A role that can create a database, schemas, stages, tasks and a `DBT PROJECT`,
  with a warehouse attached to the notebook.
- `data/products.csv` (1,214 rows) and `data/sales.csv` (100,000 rows) — uploaded
  in Question 7.
- The `dbt-project/demo/` folder — uploaded in Question 9.

### The worksheet

26 questions plus a given setup cell, in five parts:

| Part | Questions | Covers |
|---|---|---|
| **A** | 1–8 | warehouse, role and grants, database, the five layer schemas, raw tables, named file format, both stages, `COPY INTO`, verification |
| **B** | 9–13 | upload the project, `CREATE DBT PROJECT`, `EXECUTE DBT PROJECT` for build / selectors / full-refresh / saved queries |
| **C** | 14–19 | inspect: staging, snapshots, the **Type 6** dimension, surrogate-key uniqueness, the **star**, the marts, and making history actually happen |
| **D** | 20–22 | **lineage** upstream, downstream, and the physical layers |
| **E** | 23–26 | `GET_DDL` on what dbt wrote, a scheduling **TASK**, task history, teardown |

Question 19 is the one to sit with: change a product, re-snapshot, rebuild, and
watch the Type 6 columns diverge — Type 2 keeping the old value, Type 1 updating
on *both* rows, Type 3 naming what it changed from.

### How dbt runs

```sql
CREATE OR REPLACE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT
    FROM @DEMO_DB.RAW.DBT_PROJECT_STAGE/demo/;

EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'build';
```

`ARGS` takes the same flags as the CLI. The project object is a **snapshot of the
stage, not a live link** — re-upload and re-run `CREATE OR REPLACE` after any
change to a model.

### No packages, on purpose

Code inside Snowflake has no outbound internet by default, so `dbt deps` cannot
reach the dbt Hub. A `packages.yml` that *lists* an uninstalled package makes
every dbt command fail before it runs anything:

```
Compilation Error
  dbt found 2 package(s) specified in packages.yml, but only 0 package(s)
  installed in dbt_packages.
```

So the three things a package would have supplied are written by hand:

| Would have been | Is now |
|---|---|
| `dbt_utils.generate_surrogate_key` | `macros/surrogate_key.sql` |
| `dbt_utils.date_spine` | Snowflake `GENERATOR` in the MetricFlow time spine |
| `dbt_expectations` range/shape tests | `tests/generic/column_between.sql`, `row_count_between.sql` |

Writing a generic test is also the fastest way to see that *every* dbt test is
just a query returning the offending rows. Because you control the upload, you
can vendor `dbt_packages/` and re-enable packages if you want — the project
README explains both routes.

The MetricFlow `mf` CLI does not come along either; it is a local tool. The
semantic models still parse and the saved-query exports still build.

### What the project builds

| Object | Schema | Kind |
|---|---|---|
| `stg_product_incr` / `stg_sales` | STG | incremental (`merge`) / view |
| `product_snapshot` / `sales_snapshot` | STG | snapshots (check / timestamp) |
| `store_master`, `category_targets` | SEED | seeds |
| `dim_product_t6` | EDW | **Type 6** SCD + surrogate key |
| `dim_store`, `dim_date` | EDW | Type 1 dim; smart-key date dim |
| `fct_sales` | EDW | incremental (`delete+insert`) — the star's fact |
| `metricflow_time_spine` | EDW | dense calendar the semantic layer needs |
| `rpt_*` (3) | MARTS | hand-written models |
| `mart_*` (3) | MARTS | exported from MetricFlow saved queries |

Plus 4 macros, 2 custom generic tests, an exposure, an analysis, 42 data tests,
2 unit tests, 3 semantic models and 11 metrics.

### Verification

No cell was executed against Snowflake — this repo has no account — so the
solution ships **without stored output** and each answer states what it should
return. What *was* verified mechanically, in the lab image:

- **The project compiles inside Snowflake.** Confirmed on **dbt 1.9.4 /
  dbt-snowflake 1.9.2** in a Workspace: `compile --target dev` resolves 10
  models, 2 snapshots, 1 analysis, 2 seeds, 42 data tests, 2 sources, 1
  exposure, 11 metrics, 3 semantic models, 3 saved queries and 2 unit tests —
  the same inventory the lab image reports on dbt 1.12, so the project is
  portable across both.
- **`dbt parse` is clean on the project as it sits in the repo, with
  `dbt_packages` absent** — the exact condition that made the packaged version
  fail. `mf validate-configs` reports **ERRORS: 0**.
- The manifest shows 10 models, 42 data tests, the custom generic tests and the
  `surrogate_key` macro all registered.
- Cell metadata is valid for Snowsight import: every cell has a unique `name`
  and every code cell declares its `language`.
- `scripts/check_exercises.py` invariants hold.

Six bugs were found and fixed by that testing, all worth knowing:

1. **dbt renders every file as Jinja before parsing, and does not skip SQL/YAML
   comments** — a literal loop tag inside a `--` comment failed the whole project.
2. Generic-test parameters must be written at the **top level**, not nested
   under `arguments:` — the dbt inside Snowflake predates dbt 1.12 and errors
   on the nested form, while 1.12 accepts the top-level form with only a
   deprecation notice. Portability wins.
3. The semantic layer **requires a time spine model**, or nothing parses.
4. A semantic model with dimensions must declare a **primary entity**.
5. The credential-free `profiles.yml` is **only** valid inside Snowflake; local
   dbt rejects it with *"'account' is a required property"*.
6. A `packages.yml` listing uninstalled packages **fails every command** — the
   error this lab is now built to avoid.

**Not verified**, and labelled where it appears: `CREATE`/`EXECUTE DBT PROJECT`,
the `TASK`, and the warehouse/role DDL are written from Snowflake's documented
syntax but never executed. Nor is anything needing a live warehouse: the load,
the model results, the Type 6 history accumulating, or the test outcomes.

`scripts/run_all_solutions.py` skips this day — it cannot reach Snowflake.
