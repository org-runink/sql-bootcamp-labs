-- ============================================================================
-- 01 — Warehouse, database, schemas, and the grants that make dbt work.
-- Run as ACCOUNTADMIN. Paste into a Snowsight worksheet and run all.
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ---------------------------------------------------------------- compute
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
    WAREHOUSE_SIZE      = 'XSMALL'
    AUTO_SUSPEND        = 60        -- seconds; a running warehouse bills per second
    AUTO_RESUME         = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- ---------------------------------------------------------------- database
CREATE DATABASE IF NOT EXISTS DEMO_DB;

-- One schema per layer.
--   RAW    the two CSVs, untouched          STG    staging + snapshots
--   EDW    the star schema                  MARTS  business reports
--   SEED   dbt seeds
CREATE SCHEMA IF NOT EXISTS DEMO_DB.RAW;
CREATE SCHEMA IF NOT EXISTS DEMO_DB.STG;
CREATE SCHEMA IF NOT EXISTS DEMO_DB.EDW;
CREATE SCHEMA IF NOT EXISTS DEMO_DB.MARTS;
CREATE SCHEMA IF NOT EXISTS DEMO_DB.SEED;

-- ---------------------------------------------------------------- grants
-- THE STEP EVERYONE SKIPS. Whoever runs the CREATEs above owns the result.
-- dbt runs as the role named in the project's profiles.yml (SYSADMIN). If a
-- different role owns these schemas, every model fails with:
--
--   003001 (42501): SQL access control error: Insufficient privileges to
--   operate on schema 'EDW'. Your primary role SYSADMIN must have CREATE
--   TABLE granted on SCHEMA DEMO_DB.EDW.
--
-- and `dbt compile` will NOT warn you, because compiling never touches the
-- warehouse. Only `run` does.
--
-- Change SYSADMIN below if your profiles.yml names a different role.

GRANT OWNERSHIP ON DATABASE DEMO_DB                     TO ROLE SYSADMIN COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL SCHEMAS IN DATABASE DEMO_DB      TO ROLE SYSADMIN COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL TABLES IN DATABASE DEMO_DB       TO ROLE SYSADMIN COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL VIEWS IN DATABASE DEMO_DB        TO ROLE SYSADMIN COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL STAGES IN DATABASE DEMO_DB       TO ROLE SYSADMIN COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL FILE FORMATS IN DATABASE DEMO_DB TO ROLE SYSADMIN COPY CURRENT GRANTS;

GRANT USAGE, OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE SYSADMIN;

-- ---------------------------------------------------------------- verify
-- Every schema must show SYSADMIN as owner. If any does not, dbt will fail.
USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE DEMO_DB;

SHOW SCHEMAS IN DATABASE DEMO_DB;
SELECT "name", "owner" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" IN ('RAW','STG','EDW','MARTS','SEED');
