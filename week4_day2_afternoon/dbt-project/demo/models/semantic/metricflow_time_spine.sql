-- TIME SPINE -- a dense, gap-free list of dates, one row per day.
--
-- MetricFlow REQUIRES one. Without it, dbt fails to parse at all with "the
-- semantic layer requires a time spine model with granularity DAY or smaller".
--
-- Why a spine and not dim_date: dim_date only contains days that actually appear
-- in sales, so it has holes. Cumulative and windowed metrics -- sales_rolling_28d,
-- sales_to_date -- must land on EVERY day, including ones with no sales, or a
-- rolling window silently skips them and the trend is wrong.
--
-- Built with Snowflake's own GENERATOR rather than dbt_utils.date_spine, so the
-- project needs no packages. GENERATOR makes rows out of nothing; SEQ4() numbers
-- them 0,1,2...; DATEADD turns that into consecutive days.

{{ config(materialized='table') }}

with days as (

    select
        dateadd(day, seq4(), to_date('2008-01-01')) as date_day
    from table(generator(rowcount => 3000))

)

select
    date_day
from days
where date_day < to_date('2015-01-01')
