-- ============================================================================
-- 02 — File format, stages, and the two raw tables.
-- Run as SYSADMIN (the role that now owns the schemas).
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE DEMO_DB;
USE SCHEMA RAW;

-- ---------------------------------------------------------------- file format
-- DATE_FORMAT is the one that bites: TRANS_DT in sales.csv is written M/D/YYYY
-- (e.g. 3/7/2010). Without it, every date whose day and month are both <= 12 is
-- silently misread rather than rejected — a wrong answer instead of an error.
CREATE OR REPLACE FILE FORMAT RAW.CSV_FF
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_DELIMITER = ','
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'MM/DD/YYYY'
    NULL_IF = ('', 'NULL')
    EMPTY_FIELD_AS_NULL = TRUE;

-- ---------------------------------------------------------------- stages
-- For the two CSVs.
CREATE STAGE IF NOT EXISTS RAW.LOAD_STAGE
    DIRECTORY = (ENABLE = TRUE)
    FILE_FORMAT = RAW.CSV_FF;

-- For the dbt project folder. SNOWFLAKE_SSE is required: a DBT PROJECT object
-- can only be created from a server-side-encrypted stage.
CREATE STAGE IF NOT EXISTS RAW.DBT_PROJECT_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- ---------------------------------------------------------------- raw tables
-- Types declared deliberately rather than inferred by a load wizard.
-- TRANS_DT must be a real DATE: the date dimension depends on it.
CREATE OR REPLACE TABLE RAW.PRODUCT (
    PROD_KEY          NUMBER,
    PROD_NAME         VARCHAR,
    VOL               FLOAT,
    WGT               FLOAT,
    BRAND_NAME        VARCHAR,
    STATUS_CODE       NUMBER,
    STATUS_CODE_NAME  VARCHAR,
    CATEGORY_KEY      NUMBER,
    CATEGORY_NAME     VARCHAR,
    SUBCATEGORY_KEY   NUMBER,
    SUBCATEGORY_NAME  VARCHAR
);

CREATE OR REPLACE TABLE RAW.SALES (
    TRANS_ID     NUMBER,
    PROD_KEY     NUMBER,
    STORE_KEY    NUMBER,
    TRANS_DT     DATE,
    TRANS_TIME   NUMBER,
    PRIORITY     VARCHAR,
    SALES_QTY    FLOAT,
    SALES_PRICE  FLOAT,
    SALES_AMT    FLOAT,
    DISCOUNT     FLOAT,
    SALES_COST   FLOAT,
    SALES_MGRN   FLOAT,
    SHIPMODE     VARCHAR,
    SHIP_COST    FLOAT
);

SHOW TABLES IN SCHEMA RAW;
SHOW STAGES IN SCHEMA RAW;
