# Release notes

## 20261113-143338 (7b81d16)

## Release Notes

This update introduces dbt and Snowflake integration for Week 4, expands the local development environment with Spark and Polars, and refines existing course materials and console configuration.

### Added
*   **Week 4 Content:** Added Day 2 (dbt on Snowflake, raw to data marts) and Day 3 (governance worksheets) materials.
*   **dbt Tooling:**
    *   Added `scripts/check_dbt_project.py` to validate project structure.
    *   Implemented local dbt parsing as a repository capability.
    *   Added support for linting the Week 4 dbt project locally.
    *   Included plain SQL scripts and updated instructions to utilize them.
    *   Added coverage for dbt project configuration in YAML and `dbt init`.
*   **Environment & Dependencies:**
    *   Added `polars` and `pyspark` (with required JVM) to the console image.
    *   Added dbt and Snowflake toolchain to the console image.
    *   Published Spark UI and added a history server.
*   **Configuration:**
    *   Granted the dbt role on lab schemas prior to execution.
    *   Recorded verified Snowflake dbt runtime version (1.9.4).

### Changed
*   **dbt Project Structure:**
    *   Split the dbt project into individual files and converted the notebook to SQL-only.
    *   Removed package dependencies to ensure the project builds within Snowflake.
    *   Updated generic test parameters to use the portable top-level form.
    *   Merged `core-session/dbt-yaml-config` branch, adding YAML config coverage and a no-package project structure.
*   **Spark Configuration:** Tuned Spark settings for 8 GB workstations.
*   **Console UI:** Set JupyterLab dark theme as the default.
*   **Week 3 Content:** Corrected the Week 3 Day 2 morning exercise.

### Fixed
*   Repaired the Week 3 Day 2 correction exposed by the recent merge.
*   Repaired the console-image section that was truncated by Spark documentation updates.
*   Removed Week 4 Day 2 notebooks (superseded by SQL-only approach).

