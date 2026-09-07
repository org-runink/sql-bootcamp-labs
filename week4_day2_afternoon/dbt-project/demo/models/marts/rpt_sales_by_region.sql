-- MARTS — the business-facing report: sales by region and month.
--
-- This is a pure star-schema query: the fact joined to its dimensions by
-- surrogate key. Note it reports on current_category_name (the Type 1 column),
-- so history is re-stated under today's categories — "as is" reporting. Swap it
-- for category_name to get "as was".

select
    d.year_num,
    d.month_num,
    d.month_name,
    s.region,
    p.current_category_name as category_name,
    sum(f.sales_qty)  as sales_qty,
    sum(f.sales_amt)  as sales_amt,
    sum(f.sales_mgrn) as sales_margin
from {{ ref('fct_sales') }} f
join {{ ref('dim_date') }}        d on f.date_key   = d.date_key
join {{ ref('dim_product_t6') }}  p on f.product_sk = p.product_sk
join {{ ref('dim_store') }}       s on f.store_sk   = s.store_sk
group by 1, 2, 3, 4, 5
