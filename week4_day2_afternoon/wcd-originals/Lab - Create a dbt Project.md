# Lab: Create a dbt Project

*Week 4 — Data Transformation & Cloud Data Foundations · dbt · v2*

*(WeCloudData teaching-plan material, transcribed verbatim from the lab page for
offline reference. The attached archive is `create_dbt_project_datasets.zip` —
`sales.csv` and `products.csv`.)*

---

## Prerequisites

- Make sure you have an active Snowflake account.
- Create a new database, or use an existing one, and create a `raw` schema inside that database.
- Upload the attached csv files — `sales.csv` and `products.csv` — to Snowflake.
- Create two new tables using the uploaded csvs:
  - `raw.sales`
  - `raw.product`

## Install dbt on Your Computer

dbt is distributed as a Python package, so you will install it using pip, Python's package manager. You will install two packages: `dbt-core`, which provides the dbt command line tool itself, and `dbt-snowflake`, the adapter that lets dbt connect to Snowflake. Installing `dbt-snowflake` pulls in `dbt-core` automatically as a dependency, but the command below lists both explicitly so it is clear what is being installed.

### Prerequisite: Python

dbt requires Python 3.9 or later. Check whether Python is already installed:

```
# Windows
python --version

# Mac
python3 --version
```

If you see a version number of 3.9 or higher, you are ready. If not, download and install Python from python.org.

> 📝 Windows users: during the Python installation, make sure to check the box labeled "Add Python to PATH" on the first screen of the installer.

### Install dbt on Windows

```
python -m pip install dbt-core dbt-snowflake
```

### Install dbt on Mac

```
python3 -m pip install dbt-core dbt-snowflake
```

### Verify the dbt Installation

```
dbt --version
```

## Initiating a dbt Project

Use a descriptive project name (letters, digits, and underscores only; no spaces, special characters, or leading digit).

1. Initiate a dbt project named "demo".
   ```
   dbt init demo
   ```
2. Choose a suitable adapter to connect to your data source, such as BigQuery, Snowflake, Redshift, or Postgres. For demo purposes, we will choose snowflake.
3. Create Database and Schema in Snowflake and ingest data. Download the attached zip file for this material. Create tables in the schema you created and load data from the downloaded csv files.

### Advanced: Customizing a Profile Directory (Optional)

1. Examine `profiles.yml` file. After you initiate your dbt project, the `.dbt` directory will be created at your `$HOME` path by default. The `profiles.yml` will contain project-specific connectivity information of the data warehouse.
   ```
   cat ~/.dbt/profiles.yml
   vi ~/.dbt/profiles.yml   # or vim, or nano

   cd demo
   dbt debug
   dbt debug --config-dir
   ```
2. Update `profiles.yml` to connect to Snowflake. You may want it stored in a different directory than `~/.dbt/`.
   ```
   pwd
   mv ~/.dbt/profiles.yml path/to/directory
   export DBT_PROFILES_DIR=path/to/directory
   cd demo
   dbt debug
   ```
   > 📝 the file always needs to be called `profiles.yml`, regardless of directory.

### Advanced: Custom Schemas

dbt uses a default macro `generate_schema_name` to determine the schema a model is built in. Default logic:

```jinja
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

To use custom schema names verbatim (no `default_schema_` prefix), override the macro:

```jinja
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

Use the `schema` configuration key to specify a custom schema for a model (config block, properties.yml, or `dbt_project.yml`).

## Streamlining Sales Data Integration

### Add Sources to DAG

Sources make it possible to name and describe the data loaded into your warehouse. By declaring source tables in dbt you can `select` from them via `{{ source() }}`, define lineage, test assumptions, and calculate freshness. Sources are defined in `.yml` files nested under a `sources:` key.

> 📝 By default, `schema` will be the same as `name`. Add `schema` only if you want a source name that differs from the existing schema.

### Product table

Objective: employ both the **merge incremental** materialization strategy and the **dbt snapshot** technique to optimize inserting/updating records into the product table, and compare the two approaches.

**Tasks**

1. Create two subfolders named `staging` and `mart` within the `models` directory.
2. Implement the merge incremental materialization strategy.
   1. Generate `stg_product_incr` within `staging`. Use the merge incremental strategy to capture changes of `raw.product`, add a `start_date` attribute, output to the `stage` schema.
      ```jinja
      {{
        config(
          materialized = 'incremental',
          incremental_strategy='merge',
          unique_key = ['prod_key', 'prod_name', 'vol', 'wgt', 'brand_name', 'status_code', 'status_code_name', 'category_key', 'category_name', 'subcategory_key', 'subcategory_name']
        )
      }}

      {% if is_incremental() %}
        {% set MAX_START_DATE_query %}
          select ifnull(max(start_date), '1900-01-01') from {{this}} as MAX_START_DT
        {% endset %}
        {% if execute %}
          {% set MAX_START_DT = run_query(MAX_START_DATE_query).columns[0][0] %}
        {% endif %}
      {% endif %}

      select
        prod_key, prod_name, vol, wgt, brand_name, status_code, status_code_name,
        category_key, category_name, subcategory_key, subcategory_name,
        sysdate() as start_date
      from
        {{ source('stg', 'product') }}
      {% if is_incremental() %}
        where start_date >= '{{ MAX_START_DT }}'
      {% endif %}
      ```
   2. Develop `dim_product_incr` within `mart`. Reference `stg_product_incr`, use a window function to include `deactivate_date`, create a flag `active_status`, output to the `entp` schema.
      ```jinja
      select
        *,
        lag(start_date, 1) over(partition by prod_key order by start_date desc) as deactivate_date,
        iff(deactivate_date is null, true, false) as active_status
      from
        {{ ref('stg_product_incr')}}
      ```
3. Apply the dbt snapshot technique.
   1. Generate `stg_product_snapshot` under the `snapshots` directory to capture changes of `raw.product`, output to the `stage` schema.
      ```jinja
      {% snapshot stg_product_snapshot %}
        {{
          config(
            target_schema='stage',
            strategy='check',
            unique_key='prod_key',
            check_cols='all',
          )
        }}
        select * from {{ source('stg', 'product') }} order by prod_key
      {% endsnapshot %}
      ```
   2. Develop `dim_product_snapshot` within `mart`. Reference `stg_product_snapshot`, use `dbt_valid_from` / `dbt_valid_to` to add `start_date`, `deactivate_date`, and a flag `active_status`, output to the `entp` schema.
      ```jinja
      select
        prod_key, prod_name, vol, wgt, brand_name, status_code, status_code_name,
        category_key, category_name, subcategory_key, subcategory_name,
        dbt_valid_from as start_date,
        dbt_valid_to as deactivate_date,
        iff(dbt_valid_to is null, true, false) as active_status
      from
        {{ ref('stg_product_snapshot') }}
      ```

### Sales table

**Task** — Implement the delete+insert incremental materialization strategy.

Create `fct_daily_sales` inside `mart`. Use delete+insert to capture changes from `raw.sales`, aggregate to daily granularity, and add an `update_time` attribute.

```jinja
{{
  config(
    materialized = 'incremental',
    incremental_strategy='delete+insert',
    unique_key = ['cal_dt', 'prod_key', 'store_key']
  )
}}

{% if is_incremental() %}
  {% set MAX_CAL_DATE_query %}
    select ifnull(max(cal_dt), '1900-01-01') from {{this}} as MAX_CAL_DT
  {% endset %}
  {% if execute %}
    {% set MAX_CAL_DT = run_query(MAX_CAL_DATE_query).columns[0][0] %}
  {% endif %}
{% endif %}

select
  trans_dt as cal_dt,
  store_key as store_key,
  prod_key as prod_key,
  sum(sales_qty) as sales_qty,
  sum(sales_amt) as sales_amt,
  avg(sales_price) as sales_price,
  sum(sales_cost) as sales_cost,
  sum(sales_mgrn) as sales_mgrn,
  avg(discount) as discount,
  sum(ship_cost) as ship_cost,
  current_date() as update_time
from
  {{ source('stg', 'sales') }}
{% if is_incremental() %}
  where trans_dt >= '{{ MAX_CAL_DT }}'
{% endif %}
group by 1,2,3
```

## Packages

Extend dbt with community/custom packages. Steps: find a package (dbt Hub), add it to `packages.yml`, run `dbt deps`, then use it.

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
```

For a GitHub package:

```yaml
packages:
  - git: "https://github.com/dbt-labs/dbt-utils.git"
    revision: 0.9.2
```

```
dbt deps
```

## Tests

### Column-level (generic) tests

Common generic tests: `unique`, `not_null`, `accepted_values`, `relationships`, `expression_is_true`. Defined in a `schema.yml`:

```yaml
version: 2
models:
  - name: dim_product_incr
    columns:
      - name: prod_key
        tests:
          - unique
          - not_null
```

```
dbt test
```

### Model-level tests (dbt-expectations)

`dbt-expectations` provides pre-built data-quality tests. Add to `packages.yml`:

```yaml
packages:
  - package: calogica/dbt_expectations
    version: [">=0.9.0", "<0.10.0"]
```

Run `dbt deps`. Define the timezone variable in `dbt_project.yml`:

```yaml
vars:
  "dbt_date:time_zone": "America/Los_Angeles"
```

Use in `schema.yml`:

```yaml
version: 2
models:
  - name: fct_daily_sales
    tests:
      - dbt_expectations.expect_grouped_row_values_to_have_recent_data:
          group_by: [store_key]
          timestamp_column: cal_dt
          datepart: day
          interval: 1
      - dbt_expectations.expect_grouped_row_values_to_have_recent_data:
          group_by: [store_key]
          timestamp_column: update_time
          datepart: day
          interval: 2
```

## Running dbt models

```
dbt run                       # all models, except snapshots and tests
dbt build                     # models, tests, snapshots, and seeds
dbt build <folder_name>*      # everything in a folder
dbt run <folder_name>*
dbt run --select <model_name>
dbt build --select <model_name>
dbt build --full-refresh      # rebuild incrementals from scratch
```

## Attached resources

- `create_dbt_project_datasets.zip` (2.8 MB) — `sales.csv`, `products.csv`.
