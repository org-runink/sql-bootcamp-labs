-- STAGING — 1:1 with raw.sales. Rename, cast, select. NOTHING else.
--
-- Staging models are deliberately boring: same grain as the source, no joins and
-- no aggregation (those belong in edw/). Materialized as a view, so it costs no
-- storage and always reflects the latest raw rows.

select
    trans_id,
    trans_dt   as cal_dt,
    store_key,
    prod_key,
    priority,
    sales_qty,
    sales_price,
    sales_amt,
    sales_cost,
    sales_mgrn,
    discount,
    shipmode   as ship_mode,
    ship_cost
from {{ source('stg', 'sales') }}
