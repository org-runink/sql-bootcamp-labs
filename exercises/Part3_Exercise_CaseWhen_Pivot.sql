-- ==========================================================================
-- Part 3 Exercise: CASE WHEN and Pivot Tables (superstore-data)
-- ==========================================================================
-- Uses the `superstore` database (customers, products, orders, returns),
-- already seeded by db-init/.
-- ==========================================================================

USE superstore;

/*********************************
  CASE WHEN
*********************************/

-- Warm-up (worked example): bucket each order into a SalesTier —
-- 'Low' if Sales < 50, 'Mid' if 50-100, 'High' otherwise.
-- Write it yourself before checking solutions/.


/****************************************
  EXERCISE
****************************************/

-- 1. Add a column `is_priority_critical` with 'Yes'/'No' depending on
--    whether OrderPriority = 'Critical'


-- 2. Add a column `FinancialQuarter` derived from OrderDate's month:
--    months 1-3 = 'First Quarter', 4-6 = 'Second Quarter',
--    7-9 = 'Third Quarter', 10-12 = 'Fourth Quarter'


/*********************************
  Pivot Tables with Case When
*********************************/

-- How many orders are there per year? Per month?


-- Using SUM(CASE WHEN ...), count how many orders happened in 2009


-- How many orders per year-month, with year and month as separate
-- output columns (use GROUP BY)?


-- Pivot: years as columns, months as rows, order COUNT as the value
-- (one SUM(CASE WHEN YEAR(OrderDate) = <year> THEN 1 ELSE 0 END) column
-- per year you find in the data)


-- Same pivot, but aggregate total Sales instead of order count


/****************************************
  EXERCISE
****************************************/

-- 1. Is there a combination of OrderPriority and ShipMode that loses
--    money overall? Build a table of total profit per
--    (OrderPriority, ShipMode) combination and filter for negative totals.
--    Then pivot it: one row per OrderPriority, one column per ShipMode,
--    total profit as the value.
