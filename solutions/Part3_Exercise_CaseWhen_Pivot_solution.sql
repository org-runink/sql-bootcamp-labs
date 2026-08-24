-- ==========================================================================================================
--        __      __          ____    ___                       __  ____              __
--       /\ \  __/\ \        /\  _`\ /\_ \                     /\ \/\  _`\           /\ \__
--       \ \ \/\ \ \ \     __\ \ \/\_\//\ \     ___   __  __   \_\ \ \ \/\ \     __  \ \ ,_\    __
--        \ \ \ \ \ \ \  /'__`\ \ \/_/_\ \ \   / __`\/\ \/\ \  /'_` \ \ \ \ \  /'__`\ \ \ \/  /'__`\
--         \ \ \_/ \_\ \/\  __/\ \ \L\ \\_\ \_/\ \L\ \ \ \_\ \/\ \L\ \ \ \_\ \/\ \L\.\_\ \ \_/\ \L\.\_
--          \ `\___x___/\ \____\\ \____//\____\ \____/\ \____/\ \___,_\ \____/\ \__/.\_\\ \__\ \__/.\_\
--           '\/__//__/  \/____/ \/___/ \/____/\/___/  \/___/  \/__,_ /\/___/  \/__/\/_/ \/__/\/__/\/_/
--
-- ==========================================================================================================
--
-- File: Case When and Pivot Table
-- Developed by: WeCloudData
--
-- ==========================================================================================================


-- Use superstore database
USE superstore;

/*********************************
  CASE WHEN
*********************************/

-- Case when with multiple conditions
-- Indent for easier readability (Syntax style)
-- Want to divide ShippingTiers into 3 categories: (low: < 50, mid: 50-100, high: 100+)
SELECT
    OrderID,
    CASE
        WHEN Sales < 50 THEN 'Low'
        WHEN Sales BETWEEN 50 AND 100 THEN 'Mid'
        ELSE 'High'
    END AS SalesTier
FROM orders;


/****************************************
  EXERCISE
****************************************/

-- 1. Query the orders table and create a column called is_priority_critical
--    with values yes or no depending on whether OrderPriority is 'critical'
SELECT
    OrderID,
    CASE
        WHEN OrderPriority = 'Critical' THEN 'Yes'
        ELSE 'No'
    END AS is_priority_critical
FROM orders;

-- 2. Create a table from orders with two columns: OrderDate and financial_quarter
--    where the values of financial_quarter are: 'First Quarter` for months 1-3, 'Second Quarter` for months 4-6, etc.
SELECT
    OrderDate,
    CASE
        WHEN MONTH(OrderDate) BETWEEN 1 AND 3 THEN 'First Quarter'
        WHEN MONTH(OrderDate) BETWEEN 4 AND 6 THEN 'Second Quarter'
        WHEN MONTH(OrderDate) BETWEEN 7 AND 9 THEN 'Third Quarter'
        ELSE 'Fourth Quarter'
    END AS FinancialQuarter
FROM orders;


/*********************************
  Pivot Tables with Case When
*********************************/

-- How many orders are there per year?
SELECT YEAR(OrderDate) AS OrderYear, COUNT(OrderID) AS OrderCount
FROM orders
GROUP BY OrderYear
ORDER BY OrderYear;

-- How many orders are there per month?
SELECT MONTH(OrderDate) AS OrderMonth, COUNT(OrderID) AS OrderCount
FROM orders
GROUP BY OrderMonth
ORDER BY OrderMonth;

-- Replace the year 2009 with 1 and all other years as 0
SELECT
    YEAR(OrderDate) AS OrderYear,
    CASE
        WHEN YEAR(OrderDate) = 2009 THEN 1
        ELSE 0
    END AS Is2009
FROM orders;

-- Sum up these values to get the count of orders for 2009
SELECT
    SUM(CASE WHEN YEAR(OrderDate) = 2009 THEN 1 ELSE 0 END) AS OrdersIn2009
FROM orders;

-- How many orders are there per year-month using group by? Return OrderYear and OrderMonth in separate columns
SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth, COUNT(OrderID) AS OrderCount
FROM orders
GROUP BY OrderYear, OrderMonth
ORDER BY OrderYear, OrderMonth;

-- Display the years as columns, the months as rows, and the order counts as values
SELECT
    MONTH(OrderDate) AS OrderMonth,
    SUM(CASE WHEN YEAR(OrderDate) = 2009 THEN 1 ELSE 0 END) AS Year_2009,
    SUM(CASE WHEN YEAR(OrderDate) = 2010 THEN 1 ELSE 0 END) AS Year_2010,
    SUM(CASE WHEN YEAR(OrderDate) = 2011 THEN 1 ELSE 0 END) AS Year_2011,
    SUM(CASE WHEN YEAR(OrderDate) = 2012 THEN 1 ELSE 0 END) AS Year_2012
FROM orders
GROUP BY OrderMonth
ORDER BY OrderMonth;


-- How many orders are there per year-month using group by? Return OrderYear and OrderMonth in separate columns
SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth, SUM(Sales) AS Total_Sales
FROM orders
GROUP BY OrderYear, OrderMonth
ORDER BY OrderYear, OrderMonth;

-- Aggregate by Sales instead of Order Count
-- Display the years as columns, the months as rows, and the total sales as values
SELECT
    MONTH(OrderDate) AS OrderMonth,
    SUM(CASE WHEN YEAR(OrderDate) = 2009 THEN Sales END) AS Year_2009,
    SUM(CASE WHEN YEAR(OrderDate) = 2010 THEN Sales END) AS Year_2010,
    SUM(CASE WHEN YEAR(OrderDate) = 2011 THEN Sales END) AS Year_2011,
    SUM(CASE WHEN YEAR(OrderDate) = 2012 THEN Sales END) AS Year_2012
FROM orders
GROUP BY OrderMonth
ORDER BY OrderMonth;


/****************************************
  EXERCISE
****************************************/

-- 1. Is there a combination of OrderPriority and ShipMode that loses money?
-- Hint: Create a table with the total profits for each combination of
    -- OrderPriority and ShipMode:
    -- (Low, Regular Air, total profit)
    -- (Low, Express Air, total profit)
    -- (Low, Delivery Truck, total profit)
    -- etc.

SELECT OrderPriority, ShipMode, SUM(Profit) AS TotalProfit
FROM orders
GROUP BY OrderPriority, ShipMode
HAVING TotalProfit < 0;

select
    OrderPriority,
    sum(case when ShipMode = 'Regular Air' then Profit else 0 end) as RegularAir,
    sum(case when ShipMode = 'Express Air' then Profit else 0 end) as ExpressAir,
    sum(case when ShipMode = 'Delivery Truck' then Profit else 0 end) as DeliveryTruck
from orders
group by OrderPriority;