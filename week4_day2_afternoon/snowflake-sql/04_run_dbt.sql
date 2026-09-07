-- ============================================================================
-- 04 — Run the dbt project.
--
-- UPLOAD FIRST: the dbt-project/demo/ folder, either into a Workspace or onto
-- the stage. dbt_project.yml must end up at the ROOT of the prefix you point at.
--
-- Pick ONE of the two routes below.
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE DEMO_DB;


-- ============================================================================
-- ROUTE A — Workspace  (Snowsight -> Projects -> Workspaces)
-- Upload or git-clone demo/ into the workspace, then:
-- ============================================================================

-- EXECUTE DBT PROJECT FROM WORKSPACE "USER$"."PUBLIC"."dbt_demo"
--     project_root='/demo' args='build --target dev';


-- ============================================================================
-- ROUTE B — Stage + DBT PROJECT object
-- ============================================================================

-- Upload demo/ to @RAW.DBT_PROJECT_STAGE/demo/ preserving folders, then check:
LIST @DEMO_DB.RAW.DBT_PROJECT_STAGE;
-- You want demo/dbt_project.yml near the top, plus demo/models/, demo/macros/,
-- demo/seeds/, demo/snapshots/, demo/tests/, demo/profiles.yml.

CREATE OR REPLACE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT
    FROM @DEMO_DB.RAW.DBT_PROJECT_STAGE/demo/;

SHOW DBT PROJECTS IN DATABASE DEMO_DB;

-- ---------------------------------------------------------------- build it
-- USE `build`, NOT `run`.
--   build = seeds -> snapshots -> models -> tests, in dependency order.
--   run   = models only, and never builds snapshots. dim_product_t6 reads
--           product_snapshot, so a bare `run` fails on it.
-- build also stops a downstream model when an upstream test fails, so bad data
-- does not propagate. That is why it is the command you schedule.
EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'build --target dev';

-- ---------------------------------------------------------------- variations
-- ARGS takes the same flags as the dbt CLI.
-- EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'compile --target dev';
-- EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'run --select staging';
-- EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'run --select edw';
-- EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'test --select dim_product_t6';
-- EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'build --full-refresh';
-- EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'build --select saved_query:*';

-- Lineage, both directions:
-- EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'ls --select +rpt_sales_by_region';
-- EXECUTE DBT PROJECT DEMO_DB.PUBLIC.SALES_DBT ARGS = 'ls --select stg_sales+';


-- ============================================================================
-- IF IT FAILS
--
--   "Insufficient privileges to operate on schema"
--       -> script 01's grants were not run, or profiles.yml names a role other
--          than SYSADMIN. compile will not warn you; only run/build does.
--
--   "found N package(s) specified in packages.yml, but only 0 installed"
--       -> something re-added packages. packages.yml ships empty on purpose:
--          Snowflake has no outbound internet, so dbt deps cannot fetch them.
--
--   "takes no keyword argument 'arguments'"
--       -> a test's parameters got nested under `arguments:`. Snowflake runs
--          dbt 1.9.4, which needs them at the top level.
--
--   "does not exist or not authorized" on RAW.PRODUCT / RAW.SALES
--       -> run scripts 02 and 03 first.
-- ============================================================================
