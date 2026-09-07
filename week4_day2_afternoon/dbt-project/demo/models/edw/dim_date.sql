-- EDW — the date dimension, derived from the dates actually present in sales.
--
-- Uses a smart integer key (YYYYMMDD) rather than a hash: date keys are the one
-- place a readable surrogate key is conventional, because it sorts and ranges
-- naturally. Every star schema has one of these; it is what lets the business
-- ask for "last quarter" without writing date arithmetic in every query.

with dates as (

    select distinct cal_dt
    from {{ ref('stg_sales') }}
    where cal_dt is not null

)

select
    to_number(to_char(cal_dt, 'YYYYMMDD'))  as date_key,
    cal_dt                                   as full_date,
    year(cal_dt)                             as year_num,
    quarter(cal_dt)                          as quarter_num,
    month(cal_dt)                            as month_num,
    monthname(cal_dt)                        as month_name,
    day(cal_dt)                              as day_of_month,
    dayofweek(cal_dt)                        as day_of_week,
    dayname(cal_dt)                          as day_name,
    iff(dayofweek(cal_dt) in (0, 6), true, false) as is_weekend
from dates
