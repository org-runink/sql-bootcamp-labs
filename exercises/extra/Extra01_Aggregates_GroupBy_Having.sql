-- ==========================================================================
-- EXTRA 01 — Aggregate functions, GROUP BY, HAVING            (reinforces L06)
-- ==========================================================================
-- Database: superstore.  Tables: customers, products, orders, returns.
--
-- Note on table names: the lecture slides write `superstore.customer` and
-- `superstore.product` (singular). THIS lab uses the plural names —
-- customers, products, orders, returns. Same data, same columns; only the
-- table name differs. Use the plural form here.
--
-- Note on `orders`: one row is one ORDER LINE, not one order. A single
-- OrderID appears once per product in that order, so:
--     COUNT(*)                 -> number of order LINES
--     COUNT(DISTINCT OrderID)  -> number of ORDERS
-- Getting this wrong is the single most common mistake in these exercises.
-- ==========================================================================

USE superstore;

-- 1. Warm-up. For the whole orders table report, in one row:
--    the number of order lines, the number of distinct orders, the number of
--    distinct customers, total sales, and average sales per line.


-- 2. Which ProductCategory earns the most? For each category show the number
--    of distinct orders, total sales (2 dp) and the average product base
--    margin (3 dp). Order by revenue, highest first.
--    HINT: the category lives on `products`, the money on `orders`.


-- 3. Which ShipMode costs us most to run? Per ship mode show the line count,
--    the average shipping cost (2 dp) and total profit (2 dp), dearest
--    average shipping first.
--    CAREFUL: `LineCount` is a fine alias; `Lines` is a reserved word and
--    will not parse.


-- 4. Monthly extremes for 2012: for each month show the smallest and largest
--    OrderQuantity and the smallest and largest Sales.


-- 5. HAVING vs WHERE. List the provinces with more than 100 customers, most
--    customers first.
--    Then answer in a comment: why can this filter NOT be written with WHERE?


-- 6. Which product sub-categories LOSE money? Show sub-categories whose total
--    profit is negative, worst first.


-- 7. Repeat customers: list the 10 customers with the most distinct orders,
--    showing customer name, province, order count and total sales.


-- 8. Stretch. For each region show total sales and that region's share of
--    overall sales as a percentage (1 dp), largest share first.
--    HINT: a scalar subquery in the SELECT list gives you the grand total.
