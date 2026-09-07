-- ============================================================================
-- 05 — Look at what dbt built. Run after script 04 succeeds.
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE DEMO_DB;

-- ---------------------------------------------------------------- the layers
-- Staging as views, edw and marts as tables, each in its own schema — the
-- folder-to-schema routing from dbt_project.yml, made physical.
SELECT table_schema, table_name, table_type, row_count
FROM DEMO_DB.INFORMATION_SCHEMA.TABLES
WHERE table_schema IN ('RAW','SEED','STG','EDW','MARTS')
ORDER BY CASE table_schema
             WHEN 'RAW' THEN 1 WHEN 'SEED' THEN 2 WHEN 'STG' THEN 3
             WHEN 'EDW' THEN 4 ELSE 5 END,
         table_name;

-- ---------------------------------------------------------- the Type 6 SCD
-- Type 6 = 1 + 2 + 3. Three answers on every row:
--   category_name           what it was AT THE TIME   (Type 2)
--   current_category_name   today's value, on every row (Type 1)
--   previous_category_name  what it changed FROM       (Type 3)
SELECT product_sk,
       prod_key,
       category_name           AS type2_as_of_then,
       current_category_name   AS type1_today,
       previous_category_name  AS type3_changed_from,
       valid_from, valid_to, is_current
FROM DEMO_DB.EDW.DIM_PRODUCT_T6
ORDER BY prod_key, valid_from
LIMIT 20;

-- Why prod_key cannot key an SCD: rows = distinct surrogate keys, always;
-- but only equals distinct natural keys until a product gains a second version.
SELECT COUNT(*)                   AS rows,
       COUNT(DISTINCT product_sk) AS distinct_surrogate_keys,
       COUNT(DISTINCT prod_key)   AS distinct_natural_keys
FROM DEMO_DB.EDW.DIM_PRODUCT_T6;

-- ---------------------------------------------------------------- the star
SELECT d.year_num, d.month_name, s.region,
       p.current_category_name AS category,
       SUM(f.sales_amt) AS sales_amt,
       SUM(f.sales_qty) AS sales_qty
FROM DEMO_DB.EDW.FCT_SALES f
JOIN DEMO_DB.EDW.DIM_DATE       d ON f.date_key   = d.date_key
JOIN DEMO_DB.EDW.DIM_PRODUCT_T6 p ON f.product_sk = p.product_sk
JOIN DEMO_DB.EDW.DIM_STORE      s ON f.store_sk   = s.store_sk
GROUP BY 1,2,3,4
ORDER BY 1,2,5 DESC
LIMIT 20;

-- Every fact row must find its dimensions. Must be 0.
SELECT COUNT(*) AS orphan_rows
FROM DEMO_DB.EDW.FCT_SALES f
LEFT JOIN DEMO_DB.EDW.DIM_PRODUCT_T6 p ON f.product_sk = p.product_sk
WHERE p.product_sk IS NULL;

-- ---------------------------------------------------------------- the marts
-- Actuals vs a planning target that exists in no source system — it came from
-- a seed in the project. That is what seeds are for.
SELECT * FROM DEMO_DB.MARTS.RPT_CATEGORY_VS_TARGET ORDER BY pct_of_target DESC;
SELECT * FROM DEMO_DB.MARTS.RPT_SALES_BY_REGION LIMIT 10;

-- Same question, two routes: SQL somebody wrote vs metrics somebody declared.
-- If these disagree, the hand-written model has drifted.
SELECT 'hand-written'      AS source, ROUND(SUM(sales_amt))  AS sales
FROM DEMO_DB.MARTS.RPT_SALES_BY_REGION
UNION ALL
SELECT 'metricflow export', ROUND(SUM(total_sales))
FROM DEMO_DB.MARTS.MART_SALES_BY_REGION_MONTHLY;

-- ------------------------------------------------- what dbt actually wrote
-- Nobody wrote CREATE TABLE, yet here is the DDL. The materialization decided
-- the shape: STG_SALES came out a view, DIM_PRODUCT_T6 a table.
SELECT GET_DDL('VIEW',  'DEMO_DB.STG.STG_SALES')        AS staging_view_ddl;
SELECT GET_DDL('TABLE', 'DEMO_DB.EDW.DIM_PRODUCT_T6')   AS type6_dimension_ddl;

-- ------------------------------------------------- make history happen
-- Change a product, then re-run script 04's build, then re-run the Type 6
-- query above for this key: the old row keeps its original category_name but
-- gains a valid_to; BOTH rows now show the new current_category_name; and the
-- new row's previous_category_name names what it changed from.
-- UPDATE DEMO_DB.RAW.PRODUCT
-- SET CATEGORY_NAME = 'category-5'
-- WHERE PROD_KEY = (SELECT MIN(PROD_KEY) FROM DEMO_DB.RAW.PRODUCT);
