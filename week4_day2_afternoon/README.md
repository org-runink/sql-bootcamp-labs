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

> A generic test's parameters go under `arguments:` in current dbt. The lecture
> slides show the older top-level form; it still runs but dbt warns.

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

### One notebook, imported into Snowflake

The whole lab is a single notebook — `exercises/dbt_lab.ipynb` — that you
**import into Snowsight** (Projects → Notebooks → Import .ipynb). It mixes two
kinds of cell:

| Cell type | Does |
|---|---|
| **SQL** (18) | the warehouse work: schemas, raw tables, stages, `COPY INTO`, `EXECUTE DBT PROJECT`, inspection, the schedule |
| **Python** (34) | writes the dbt project files, and uploads them to a stage |

**There are no credentials anywhere in it.** `get_active_session()` returns the
session you are already authenticated in, and dbt runs as the executing role.
Nothing to configure, nothing to leak, nothing to rotate.

### Before you start

- A role that can create a database, schemas, stages, tasks and a `DBT PROJECT`,
  plus a warehouse attached to the notebook.
- The two CSVs to hand — `data/products.csv` (1,214 rows) and `data/sales.csv`
  (100,000 rows). Question 4 uploads them to `DEMO_DB.RAW.LOAD_STAGE` through
  the Snowsight stage UI, then `COPY INTO`s them.

Both stages live in the **RAW** schema: `RAW.LOAD_STAGE` for the CSVs and
`RAW.DBT_PROJECT_STAGE` for the dbt project the notebook uploads.

### The worksheet

52 questions plus one given setup cell, in eight parts:

| Part | Questions | Covers |
|---|---|---|
| **A** | 1–5 | database, the five layer schemas, raw tables, stages, load + verify |
| **B** | 6–15 | writing the dbt project: config, credential-free profile, packages, custom-schema macro, sources, staging models, docs |
| **C** | 16–27 | seeds, snapshots (check *and* timestamp), the **Type 6 SCD**, the **star schema**, tests and **unit tests** |
| **D** | 28–37 | marts, the Jinja pivot macro, dbt-expectations checks, the **MetricFlow** time spine, semantic models, metrics and saved queries |
| **E** | 38–43 | upload to the stage, `CREATE DBT PROJECT`, `EXECUTE DBT PROJECT` for deps/build/selectors |
| **F** | 44–46 | **lineage** upstream, downstream, and by layer |
| **G** | 47–50 | inspect the Type 6 dimension and the star; watch history actually accumulate |
| **H** | 51–52 | scheduling with a Snowflake **TASK** |

Question 50 is the one to sit with: it changes a product, re-snapshots, rebuilds,
and shows the Type 6 columns diverging — Type 2 keeping the old value, Type 1
updating on *both* rows, Type 3 naming what it changed from.

### How dbt actually runs

The notebook writes the project to `/tmp/demo`, uploads it to
`RAW.DBT_PROJECT_STAGE` with `session.file.put(...)`, then:

```sql
CREATE OR REPLACE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT
    FROM @DEMO_DB.RAW.DBT_PROJECT_STAGE/demo/;

EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'build';
```

`ARGS` takes the same flags as the CLI — `run --select edw`, `test --select
dim_product_t6`, `build --full-refresh`, `ls --select +rpt_sales_by_region`.

**The packages problem.** `dbt deps` fetches dbt_utils and dbt_expectations over
the internet, and code inside Snowflake has no outbound network by default.
Either have an ACCOUNTADMIN create a network rule plus an external access
integration for `hub.getdbt.com`, or vendor `dbt_packages/` into the upload. The
notebook documents both; vendoring is the predictable classroom choice.

**What does not come along:** the MetricFlow `mf` CLI (`mf query`, `mf list
metrics`) is a local tool. The semantic models and metrics still parse, and the
saved-query exports still build — you just cannot run `mf` from inside Snowflake.

### What the project builds

| Object | Schema | Kind |
|---|---|---|
| `stg_product_incr` | STG | incremental, `merge` |
| `stg_sales` | STG | view |
| `product_snapshot` / `sales_snapshot` | STG | snapshots (check / timestamp) |
| `store_master`, `category_targets` | SEED | seeds |
| `dim_product_t6` | EDW | **Type 6** SCD + surrogate key |
| `dim_store`, `dim_date` | EDW | Type 1 dim; smart-key date dim |
| `fct_sales` | EDW | incremental, `delete+insert` — the star's fact |
| `metricflow_time_spine` | EDW | dense calendar the semantic layer needs |
| `rpt_sales_by_region`, `rpt_category_vs_target`, `rpt_category_pivot` | MARTS | hand-written |
| `mart_*` (3) | MARTS | exported from MetricFlow saved queries |

Plus 3 macros, an exposure, an analysis, 44 data tests, 2 unit tests, 3 semantic
models and 11 metrics.

The same project is browsable at `solutions/dbt-project/demo/` — the notebook
writes exactly those files, verified byte-for-byte.

### Verification

No cell was executed against Snowflake: this repo has no account, so the
solution ships **without stored output** and each answer states what it should
return instead. What *was* verified mechanically, in the lab image:

- **The notebook's Python cells were actually executed.** All 33 file-writing
  cells run without error and produce a 32-file project **byte-identical** to
  the committed reference.
- **`dbt parse` succeeds** on that project and **`mf validate-configs` reports
  ERRORS: 0** — models, macros, seeds, snapshots, tests, unit tests, exposures
  and the semantic layer all resolve.
- `mf list metrics` returns **11 metrics** with dimensions resolved across the
  entity graph, which is proof the semantic joins onto the star schema work.
- Cell metadata is valid for Snowsight import: every cell has a unique `name`,
  and every code cell declares `language` as `sql` or `python`.
- `scripts/check_exercises.py` invariants hold.

Five bugs were found and fixed by that testing, all worth knowing:

1. **dbt renders every file as a Jinja template before parsing, and does not skip
   SQL/YAML comments.** A literal loop tag inside a `--` comment opened a
   control-flow block and failed the project with *"block definition inside
   control flow"*. The project's comments describe Jinja in words for that reason.
2. Generic-test parameters must nest under `arguments:` in current dbt.
3. **The semantic layer requires a time spine model**, or the project will not
   parse at all.
4. **A semantic model with dimensions must declare a primary entity** — the fact
   has no single natural key, so it uses `primary_entity:`.
5. **The credential-free `profiles.yml` is only valid inside Snowflake.** Local
   dbt rejects it with *"'account' is a required property"* — which is correct,
   and worth knowing before someone tries to run this project on a laptop.

**Not verified**, and labelled as such where it appears: the
`CREATE DBT PROJECT` / `EXECUTE DBT PROJECT` / `TASK` statements (written from
Snowflake's documented syntax, never run — it is a young feature), and anything
needing a live warehouse: the load, the model results, the Type 6 history
accumulating, and the test outcomes.

`scripts/run_all_solutions.py` skips this day — it cannot reach Snowflake.

### A note on the older files

`exercises/snowflake-console/*.sql` predates the single-notebook design: every
statement in it now lives in the notebook itself. It is kept only as a standalone
SQL reference and **can be deleted** — I was blocked from removing it. If you
keep it, note it duplicates the notebook and can drift.

The local JupyterLab path (the `docker-compose.yml` mount and the dbt / faker /
metricflow additions to `jupyter-sql/Dockerfile`) is still in place. Students do
not need it for this Snowsight notebook, but it is what makes the verification
above possible, so it is worth keeping.
