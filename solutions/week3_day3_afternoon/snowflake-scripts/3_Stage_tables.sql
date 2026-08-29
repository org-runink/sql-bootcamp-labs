-- ============================================================================
-- STEP 1: SET EXECUTION CONTEXT
-- ============================================================================

-- Switch to the required target database
USE DATABASE LabDB;

-- Switch to the staging schema where raw source data lands
USE SCHEMA RAW;


-- ============================================================================
-- STEP 2: CREATE STAGING TABLES
-- ============================================================================

-- Create the staging table for product master data if it does not already exist
CREATE TABLE IF NOT EXISTS STG_Products (
    PROD_KEY         INTEGER,
    PROD_NAME        VARCHAR(200),
    VOL              FLOAT,
    WGT              FLOAT,
    BRAND_NAME       VARCHAR(100),
    STATUS_CODE      INTEGER,
    STATUS_CODE_NAME VARCHAR(50),
    CATEGORY_KEY     INTEGER,
    CATEGORY_NAME    VARCHAR(100),
    SUBCATEGORY_KEY  INTEGER,
    SUBCATEGORY_NAME VARCHAR(100),
    BATCH_ID         VARCHAR(50), -- Tracks the source file name for lineage
    INSERTED_AT      TIMESTAMP DEFAULT CURRENT_TIMESTAMP() -- Automatically records ingestion time
);

-- Create the staging table for transactional sales data if it does not already exist
CREATE TABLE IF NOT EXISTS STG_Sales (
    TRANS_ID     INTEGER,
    PROD_KEY     INTEGER,
    STORE_KEY    INTEGER,
    TRANS_DT     DATE,
    TRANS_TIME   INTEGER,
    PRIORITY     VARCHAR(50),
    SALES_QTY    FLOAT,
    SALES_PRICE  FLOAT,
    SALES_AMT    FLOAT,
    DISCOUNT     FLOAT,
    SALES_COST   FLOAT,
    SALES_MGRN   FLOAT,
    SHIP_MODE    VARCHAR(50),
    SHIP_COST    FLOAT,
    BATCH_ID     VARCHAR(50), -- Tracks the source file name for lineage
    INSERTED_AT  TIMESTAMP DEFAULT CURRENT_TIMESTAMP() -- Automatically records ingestion time
);


-- ============================================================================
-- STEP 3: DATA INGESTION FROM INTERNAL STAGES (TRANSFORMATIONAL COPY)
-- ============================================================================

-- Ingest product data using a transformational COPY statement to extract metadata
COPY INTO STG_Products (
    PROD_KEY, PROD_NAME, VOL, WGT, BRAND_NAME,
    STATUS_CODE, STATUS_CODE_NAME,
    CATEGORY_KEY, CATEGORY_NAME,
    SUBCATEGORY_KEY, SUBCATEGORY_NAME,
    BATCH_ID
)
FROM (
    SELECT
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
        -- Extract the exact filename from the metadata path to populate BATCH_ID
        SPLIT_PART(METADATA$FILENAME, '/', -1)
    FROM @"PRODUCTS_STAGE"/data_loading_lab/csv_files/products_2013_01_01.csv
)
FILE_FORMAT = (
    TYPE            = 'CSV'
    SKIP_HEADER     = 1 -- Ignores the header row in the source file
    FIELD_DELIMITER = ',' -- Parses fields separated by standard commas
);


-- Ingest sales transaction data using a transformational COPY statement
COPY INTO STG_Sales (
    TRANS_ID, PROD_KEY, STORE_KEY, TRANS_DT, TRANS_TIME,
    PRIORITY, SALES_QTY, SALES_PRICE, SALES_AMT,
    DISCOUNT, SALES_COST, SALES_MGRN, SHIP_MODE, SHIP_COST,
    BATCH_ID
)
FROM (
    SELECT
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
        -- Extract the exact filename from the metadata path to populate BATCH_ID
        SPLIT_PART(METADATA$FILENAME, '/', -1)
    FROM @"SALES_STAGE"/data_loading_lab/csv_files/sales_2013_01_01.csv
)
FILE_FORMAT = (
    TYPE                         = 'CSV'
    SKIP_HEADER                  = 1 -- Ignores the header row in the source file
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' -- Handles text values wrapped in double quotes
    DATE_FORMAT                  = 'MM/DD/YYYY' -- Overrides default date parsing to match source file structure
);