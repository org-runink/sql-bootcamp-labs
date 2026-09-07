#!/usr/bin/env bash
# Scheduler entrypoint. Point cron (or Airflow / Dagster / Prefect / dbt Cloud)
# at this script to run the whole project on a schedule. `dbt build` runs seeds,
# snapshots, models and tests in dependency order and exits non-zero if anything
# fails — which is what a scheduler watches for.
set -euo pipefail
cd "$(dirname "$0")"
export DBT_PROFILES_DIR="$(pwd)"
dbt build 2>&1
