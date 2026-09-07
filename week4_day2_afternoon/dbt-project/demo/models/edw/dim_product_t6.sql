-- EDW — the product dimension as a TYPE 6 slowly-changing dimension.
--
-- Type 6 is the hybrid "1 + 2 + 3" (1 x 2 x 3 = 6, which is where the name comes
-- from). Each row of this table carries all three views of an attribute:
--
--   TYPE 2  category_name           the value AS OF that version. One row per
--                                   version, bounded by valid_from/valid_to.
--                                   Answers "what was it at the time?"
--   TYPE 1  current_category_name   the CURRENT value, repeated on every
--                                   historical row of the same product.
--                                   Answers "show me all history re-stated
--                                   under today's category."
--   TYPE 3  previous_category_name  the value from the version immediately
--                                   before this one. Answers "what did it
--                                   change from?" without a self-join.
--
-- That combination is what makes Type 6 useful: the same fact can be reported
-- "as was" (join on the Type 2 column) or "as is" (join on the Type 1 column)
-- with no change to the fact table.
--
-- History comes from the snapshot, so this model is pure SQL over dbt's
-- dbt_valid_from / dbt_valid_to. Materialized as a table (edw default).

with versions as (

    select
        prod_key,
        prod_name,
        brand_name,
        category_name,
        subcategory_name,
        status_code_name,
        dbt_valid_from as valid_from,
        dbt_valid_to   as valid_to
    from {{ ref('product_snapshot') }}

),

-- TYPE 1: the current value per product, to be stamped onto every row.
current_values as (

    select
        prod_key,
        category_name    as current_category_name,
        prod_name        as current_prod_name,
        subcategory_name as current_subcategory_name
    from versions
    where valid_to is null

),

-- TYPE 3: the value from the previous version, via lag over the version order.
with_previous as (

    select
        v.*,
        lag(v.category_name) over (
            partition by v.prod_key order by v.valid_from
        ) as previous_category_name
    from versions v

)

select
    -- The surrogate key: unique per VERSION, not per product. This is the column
    -- the fact table joins on.
    {{ surrogate_key(['w.prod_key', 'w.valid_from']) }} as product_sk,

    w.prod_key,                                 -- natural key

    -- Type 2 — as of this version
    w.prod_name,
    w.brand_name,
    w.category_name,
    w.subcategory_name,
    w.status_code_name,

    -- Type 1 — today's value, on every row
    c.current_prod_name,
    c.current_category_name,
    c.current_subcategory_name,

    -- Type 3 — the value it changed from
    w.previous_category_name,

    -- validity window
    w.valid_from,
    w.valid_to,
    {{ to_active_flag('w.valid_to') }} as is_current

from with_previous w
left join current_values c
    on w.prod_key = c.prod_key
