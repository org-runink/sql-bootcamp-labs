-- MARTS — sales per store, pivoted into one column per category by the
-- pivot_category_amounts macro. The set tag below defines the category list in
-- one place; the macro call expands it into five SUM(CASE ...) columns.
--
-- Run `dbt compile --select rpt_category_pivot` to see the generated SQL.

{% set categories = ['category-1', 'category-2', 'category-3', 'category-4', 'category-5'] %}

with sales_by_category as (

    select
        st.store_key,
        p.current_category_name as category_name,
        f.sales_amt
    from {{ ref('fct_sales') }} f
    join {{ ref('dim_product_t6') }} p on f.product_sk = p.product_sk
    join {{ ref('dim_store') }} st     on f.store_sk   = st.store_sk

)

select
    store_key,
    {{ pivot_category_amounts('sales_amt', categories) }}
from sales_by_category
group by store_key
