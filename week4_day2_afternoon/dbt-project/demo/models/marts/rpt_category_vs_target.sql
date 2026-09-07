-- MARTS — actuals vs plan, the business requirement the category_targets SEED
-- exists to serve.
--
-- The warehouse has no "target" anywhere: it is a planning number that lived in
-- a spreadsheet. Putting it in a seed makes it version-controlled, testable, and
-- joinable — and this model is the payoff: a report the source systems alone
-- could never produce.

with actuals as (

    select
        p.current_category_name as category_name,
        sum(f.sales_amt)        as actual_sales
    from {{ ref('fct_sales') }} f
    join {{ ref('dim_product_t6') }} p on f.product_sk = p.product_sk
    group by 1

)

select
    t.category_name,
    t.annual_sales_target,
    coalesce(a.actual_sales, 0) as actual_sales,
    round(coalesce(a.actual_sales, 0) - t.annual_sales_target, 2) as variance,
    round(100.0 * coalesce(a.actual_sales, 0) / nullif(t.annual_sales_target, 0), 1) as pct_of_target,
    iff(coalesce(a.actual_sales, 0) >= t.annual_sales_target, 'MET', 'MISSED') as target_status
from {{ ref('category_targets') }} t
left join actuals a on t.category_name = a.category_name
