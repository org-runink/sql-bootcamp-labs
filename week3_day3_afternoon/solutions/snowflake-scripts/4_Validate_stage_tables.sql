-- ============================================================================
-- STEP 1: VERIFY PRODUCT STAGING INGESTION
-- ============================================================================

-- Switch to the required database context
USE DATABASE LABDB;

-- Switch to the raw schema context
USE SCHEMA RAW;

-- Aggregate ingested records to audit total row counts per source file batch
SELECT 
    BATCH_ID, 
    INSERTED_AT, 
    COUNT(*) AS row_count
FROM STG_Products
GROUP BY BATCH_ID, INSERTED_AT;


-- ============================================================================
-- STEP 2: VERIFY SALES STAGING INGESTION
-- ============================================================================

-- Aggregate transactional records to validate ingestion consistency and load timing
SELECT 
    BATCH_ID, 
    INSERTED_AT AS loaded_at, 
    COUNT(*) AS row_count
FROM STG_Sales
GROUP BY BATCH_ID, INSERTED_AT;


-- ============================================================================
-- STEP 3: ENVIRONMENT CLEANUP / SCHEMA RESET
-- ============================================================================

-- Remove the old calendar dimension table from the core analytical layer
DROP TABLE CORE.DIM_CALENDAR;