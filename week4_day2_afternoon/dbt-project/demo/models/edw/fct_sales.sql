-- EDW — the FACT table at the centre of the star.
--
--                    dim_date
--                        |
--     dim_product_t6 — fct_sales — dim_store
--
-- GRAIN: one row per (date, product version, store). Every fact table must have
-- a stated grain, and every measure must be additive at that grain.
--
-- The fact carries only SURROGATE KEYS and MEASURES — no descriptive attributes.
-- That is what makes it a star: descriptions live in the dimensions, so a
-- category rename does not require touching the fact.
--
-- It joins dim_product_t6 on is_current, so each sale attaches to the product's
-- CURRENT version. (Joining on the validity window instead —
-- cal_dt between valid_from and valid_to — would give you "as was" reporting;
-- with Type 6 you get that anyway from the Type 2 columns.)
--
-- Materialization: incremental with the DELETE+INSERT strategy. For a recomputed
-- aggregate, an updated day's rows must be REPLACED, not merged column by
-- column — delete+insert deletes the matching unique_key rows and re-inserts
-- them. On a later run only dates at/after the current max are reprocessed.

{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['date_key', 'product_sk', 'store_sk']
    )
}}

{% if is_incremental() %}

{% set MAX_CAL_DATE_query %}
select ifnull(max(full_date), '1900-01-01') from {{ this }} as MAX_CAL_DT
{% endset %}

{% if execute %}
{% set MAX_CAL_DT = run_query(MAX_CAL_DATE_query).columns[0][0] %}
{% endif %}

{% endif %}

select
    -- foreign keys into the dimensions
    to_number(to_char(s.cal_dt, 'YYYYMMDD')) as date_key,
    p.product_sk,
    st.store_sk,

    -- kept for readability / the incremental filter
    s.cal_dt as full_date,

    -- additive measures at this grain
    sum(s.sales_qty)   as sales_qty,
    sum(s.sales_amt)   as sales_amt,
    sum(s.sales_cost)  as sales_cost,
    sum(s.sales_mgrn)  as sales_mgrn,
    sum(s.ship_cost)   as ship_cost,

    -- non-additive: an average cannot be summed further, so it is flagged here
    avg(s.sales_price) as avg_sales_price,
    avg(s.discount)    as avg_discount,

    current_timestamp() as dbt_loaded_at

from {{ ref('stg_sales') }} s
left join {{ ref('dim_product_t6') }} p
    on s.prod_key = p.prod_key
   and p.is_current
left join {{ ref('dim_store') }} st
    on s.store_key = st.store_key
{% if is_incremental() %}
where s.cal_dt >= '{{ MAX_CAL_DT }}'
{% endif %}
group by 1, 2, 3, 4
