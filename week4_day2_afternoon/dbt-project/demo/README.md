# `demo` — the dbt project you upload to Snowflake

> **Verified runtime: dbt 1.9.4 with dbt-snowflake 1.9.2**, compiled inside a
> Snowflake Workspace. `compile` resolves the whole project: 10 models,
> 2 snapshots, 1 analysis, 2 seeds, 42 data tests, 2 sources, 1 exposure,
> 11 metrics, 3 semantic models, 3 saved queries, 2 unit tests.
>
> That version matters. Write generic-test parameters at the **top level**, not
> nested under `arguments:` — that key needs dbt 1.12 and 1.9.4 rejects it with
> *"macro 'dbt_macro__test_accepted_values' takes no keyword argument
> 'arguments'"*. The YAML snapshot in `snapshots/sales_snapshot.yml` needs
> ≥ 1.9, so it works here but would not on 1.8.

This is the complete project the lab builds. **Upload this folder to a Snowflake
stage**, then create a `DBT PROJECT` object from it and run it with
`EXECUTE DBT PROJECT`. The notebook (`../../exercises/dbt_lab.ipynb`) drives all
of that; the SQL is there.

## What to upload

Everything in this folder, preserving the directory structure, under one prefix:

```
@DEMO_DB.RAW.DBT_PROJECT_STAGE/demo/
    dbt_project.yml          <- must sit at the root of the prefix
    profiles.yml
    packages.yml
    macros/  models/  seeds/  snapshots/  tests/  analyses/
```

Do **not** upload `target/`, `logs/`, or `profiles.example.yml` — build output and
a local-only template.

## Packages

`packages.yml` is **deliberately empty**, and the project depends on nothing.

Code running inside Snowflake has no outbound internet by default, so `dbt deps`
cannot reach the dbt Hub. If `packages.yml` *lists* a package that is not
installed, every dbt command fails before running anything:

```
Compilation Error
  dbt found 2 package(s) specified in packages.yml, but only 0 package(s)
  installed in dbt_packages. Run "dbt deps" to install package dependencies.
```

So the three things a package would have supplied are written by hand here:

| Would have been | Is now |
|---|---|
| `dbt_utils.generate_surrogate_key` | `macros/surrogate_key.sql` |
| `dbt_utils.date_spine` | Snowflake `GENERATOR` in `models/semantic/metricflow_time_spine.sql` |
| `dbt_expectations` range/shape tests | `tests/generic/column_between.sql`, `tests/generic/row_count_between.sql` |

**If you want packages anyway**, you control the upload, so vendoring is now
easy: run `dbt deps` somewhere with internet and upload the resulting
`dbt_packages/` folder alongside the project (≈400 files, ≈7.5 MB — script it).
Then uncomment the packages in `packages.yml`. The alternative is a network rule
plus an external access integration, which needs an ACCOUNTADMIN.

## The connection

`profiles.yml` carries **no credentials** — running inside Snowflake, dbt
authenticates as the role that executes the project. `database`, `schema`,
`warehouse` and `role` only set the defaults models build into; the custom
`generate_schema_name` macro overrides them per folder.

`profiles.example.yml` is the *local* equivalent, for running this project from a
laptop, and does need account/user/password. Do not upload it.

## Layout

```
demo/
├── dbt_project.yml              project config; routes each folder to a schema
├── packages.yml                 empty, and explains why
├── profiles.yml                 credential-free, for running inside Snowflake
├── macros/
│   ├── generate_schema_name.sql use the layer schema names verbatim
│   ├── surrogate_key.sql        our own hash key (replaces dbt_utils)
│   ├── to_active_flag.sql       the "null close date means current" rule
│   └── pivot_category_amounts.sql  generates one SUM column per category
├── models/
│   ├── staging/     stg_product_incr (merge incremental), stg_sales, docs + tests
│   ├── edw/         dim_product_t6 (Type 6 SCD), dim_store, dim_date,
│   │                fct_sales (delete+insert), tests, unit tests
│   ├── marts/       rpt_sales_by_region, rpt_category_vs_target,
│   │                rpt_category_pivot, properties with YAML config + tests
│   ├── semantic/    time spine, semantic models, metrics, saved queries
│   └── exposures.yml
├── seeds/           store_master, category_targets, and their tests
├── snapshots/       product_snapshot (check), sales_snapshot (timestamp, YAML)
├── tests/generic/   our two custom generic tests
├── analyses/        compile-only query
└── run_dbt.sh       entrypoint if you run this from a laptop instead
```

## The layers

| Folder | Schema | Materialized |
|---|---|---|
| `staging/` | `STG` | views |
| `edw/` | `EDW` | tables — the star schema |
| `marts/` | `MARTS` | tables |
| `semantic/` | `EDW` | the time spine |
| seeds | `SEED` | tables |

## Running it

From the notebook, or in any Snowsight worksheet:

```sql
CREATE OR REPLACE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT
    FROM @DEMO_DB.RAW.DBT_PROJECT_STAGE/demo/;

EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'build';
```

`ARGS` takes the same flags as the CLI: `run --select edw`,
`test --select dim_product_t6`, `build --full-refresh`,
`ls --select +rpt_sales_by_region`.

Re-upload and re-run `CREATE OR REPLACE DBT PROJECT` whenever you change a file —
the object is a snapshot of the stage, not a live link.
