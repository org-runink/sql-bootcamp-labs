-- An ANALYSIS: a .sql file dbt COMPILES (so ref() and Jinja resolve) but never
-- runs as part of `dbt run`/`dbt build`, and never materializes. Use it for
-- ad-hoc questions you still want version-controlled and templated.
--
-- `dbt compile --select top_products` writes the resolved SQL to
-- target/compiled/... — paste that into the Snowflake console to run it.

select
    p.prod_key,
    p.current_prod_name,
    p.current_category_name,
    sum(f.sales_amt) as total_sales
from {{ ref('fct_sales') }} f
join {{ ref('dim_product_t6') }} p on f.product_sk = p.product_sk
group by 1, 2, 3
order by total_sales desc
limit 20
