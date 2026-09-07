-- SNAPSHOT — dbt's built-in Type 2 history capture, in the classic SQL block.
--
-- raw.product is MUTABLE: a category or a name can change in place, and the old
-- value is lost. A snapshot records each state so history survives. It is the
-- foundation the Type 6 dimension is built on.
--
-- strategy='check' with check_cols='all': raw.product has no reliable
-- "updated_at" column, so dbt compares every column per prod_key. When anything
-- differs it closes the old row (dbt_valid_to = now) and inserts a new one
-- (dbt_valid_from = now, dbt_valid_to = null).
--
-- Built by `dbt snapshot` (or `dbt build`) — NOT by `dbt run`.

{% snapshot product_snapshot %}

{{
    config(
        target_schema='stg',
        strategy='check',
        unique_key='prod_key',
        check_cols='all',
    )
}}

select
    *
from
    {{ source('stg', 'product') }}
order by
    prod_key

{% endsnapshot %}
