-- ============================================================================
-- 06 — Schedule it, and clean up afterwards.
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE DEMO_DB;


-- ============================================================================
-- SCHEDULE — inside Snowflake the scheduler is already there. No cron, no
-- external orchestrator.
-- ============================================================================

CREATE OR REPLACE TASK DEMO_DB.PUBLIC.SALES_DBT_DAILY
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 0 6 * * * UTC'
AS
    EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'build';

-- Tasks are created SUSPENDED.
ALTER TASK DEMO_DB.PUBLIC.SALES_DBT_DAILY RESUME;

SHOW TASKS IN SCHEMA DEMO_DB.PUBLIC;

-- How you find out a scheduled run failed. Because the task runs `build`, a
-- failing test stops the run and surfaces here rather than publishing bad data.
SELECT name, state, scheduled_time, completed_time, error_message
FROM TABLE(DEMO_DB.INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME => 'SALES_DBT_DAILY'))
ORDER BY scheduled_time DESC
LIMIT 20;


-- ============================================================================
-- TEARDOWN — run this when the class ends. A resumed task keeps billing.
-- ============================================================================

-- 1. STOP THE CLOCK FIRST, or a scheduled run can fire against half-dropped
--    objects.
ALTER TASK IF EXISTS DEMO_DB.PUBLIC.SALES_DBT_DAILY SUSPEND;

-- 2. Drop the lab objects.
DROP TASK        IF EXISTS DEMO_DB.PUBLIC.SALES_DBT_DAILY;
DROP DBT PROJECT IF EXISTS DEMO_DB.PUBLIC.SALES_DBT;

-- 3. The database takes the schemas, tables, views, stages and file format with
--    it. Comment out to keep the results. Recoverable with UNDROP DATABASE
--    DEMO_DB for the Time Travel retention period.
DROP DATABASE IF EXISTS DEMO_DB;

-- 4. Suspending the warehouse is usually enough.
ALTER WAREHOUSE IF EXISTS COMPUTE_WH SUSPEND;
-- DROP WAREHOUSE IF EXISTS COMPUTE_WH;

SHOW DATABASES LIKE 'DEMO_DB';
