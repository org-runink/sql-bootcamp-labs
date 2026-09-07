#!/usr/bin/env bash
# Run this project from a LAPTOP, not from inside Snowflake.
#
# Inside Snowflake you do not need this at all -- use
#   EXECUTE DBT PROJECT <name> ARGS = 'build'
# or a TASK, which is what the notebook's scheduling section sets up.
#
# `build` and not `run`: dim_product_t6 reads product_snapshot, and `run` never
# builds snapshots. `build` sequences seeds -> snapshots -> models -> tests and
# stops a downstream model when an upstream test fails, so bad data does not
# propagate. That is why it is also the command a scheduler should call.
#
# It exits non-zero on any failure, which is what cron/Airflow watch for.
#
# PRECONDITIONS -- none of these are things dbt can fix for you:
#   1. RAW.PRODUCT and RAW.SALES exist and are loaded.
#   2. The role in profiles.yml OWNS the target schemas. If a different role
#      created them, every model fails with "Insufficient privileges to operate
#      on schema" -- and `compile` will not warn you, because compiling never
#      touches the warehouse.
#   3. profiles.yml here has real connection details. The committed profiles.yml
#      is the credential-free one for running INSIDE Snowflake; for local use,
#      copy profiles.example.yml over it and fill it in.
set -euo pipefail
cd "$(dirname "$0")"
export DBT_PROFILES_DIR="$(pwd)"

dbt build "$@" 2>&1
