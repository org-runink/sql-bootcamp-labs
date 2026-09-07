-- ============================================================================
-- 03 — Load the two CSVs and prove they arrived correctly.
--
-- UPLOAD FIRST (this is a UI step; a worksheet cannot read your laptop):
--   Snowsight -> Data -> Databases -> DEMO_DB -> RAW -> Stages -> LOAD_STAGE
--   -> "+ Files" -> add data/products.csv and data/sales.csv
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE DEMO_DB;

-- Confirm what actually landed. If a client compressed on upload the names gain
-- .gz and the COPY paths below must match.
LIST @RAW.LOAD_STAGE;

-- ---------------------------------------------------------------- load
COPY INTO RAW.PRODUCT FROM @RAW.LOAD_STAGE/products.csv
    FILE_FORMAT = RAW.CSV_FF
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO RAW.SALES FROM @RAW.LOAD_STAGE/sales.csv
    FILE_FORMAT = RAW.CSV_FF
    ON_ERROR = 'ABORT_STATEMENT';

-- ---------------------------------------------------------------- verify
-- Expect exactly 1,214 and 100,000.
SELECT 'product' AS table_name, COUNT(*) AS row_count FROM RAW.PRODUCT
UNION ALL
SELECT 'sales', COUNT(*) FROM RAW.SALES;

-- A row count only proves arrival. This proves the DATE parse: the range must
-- span 2009-01-01 to 2012-12-30. NULLs or a wrong range mean the file format
-- did not apply -- TRUNCATE both tables and load again.
SELECT MIN(TRANS_DT) AS first_day,
       MAX(TRANS_DT) AS last_day,
       COUNT(DISTINCT TRANS_DT) AS distinct_days
FROM RAW.SALES;

SELECT * FROM RAW.PRODUCT LIMIT 5;
SELECT * FROM RAW.SALES   LIMIT 5;

-- To start over:
--   TRUNCATE TABLE RAW.PRODUCT;
--   TRUNCATE TABLE RAW.SALES;
