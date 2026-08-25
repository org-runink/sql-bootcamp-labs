-- ==========================================================================
-- EXTRA 02 — Joins and set operators                          (reinforces L07)
-- ==========================================================================
-- Database: superstore.  Tables: customers, products, orders, returns.
--
-- Reminder: `orders` is one row per ORDER LINE. COUNT(DISTINCT OrderID)
-- counts orders; COUNT(*) counts lines.
--
-- Reminder on the ERD: orders.CustomerID -> customers, orders.ProductID ->
-- products, returns.OrderID -> orders. `returns` holds ONLY returned orders,
-- which is what makes it the natural table to practise outer joins against.
-- ==========================================================================

USE superstore;

-- 1. INNER JOIN. Build an order-detail view: for 10 order lines show OrderID,
--    OrderDate, the product name, its category and sub-category, and Sales.


-- 2. LEFT JOIN + flag. For each region show the number of order lines and how
--    many of those were returned. Most returns first.
--    HINT: LEFT JOIN returns, then SUM(CASE WHEN ... IS NOT NULL THEN 1 ELSE 0 END).
--    Ask yourself why an INNER JOIN would give the wrong denominator here.


-- 3. Anti-join. List the customers who have NEVER placed an order.
--    HINT: LEFT JOIN from customers and keep the rows where the right side is
--    NULL. (There is also a NOT IN form — worksheet 02 of the morning class (subqueries) revisits it.)
--    Then check: does the same trick find products that were never ordered?
--    Report what you get and what that tells you about this dataset.


-- 4. FULL OUTER JOIN — the trap. The slides show FULL OUTER JOIN, but MySQL
--    does NOT implement it: writing one is a syntax error. Prove that to
--    yourself, then write the equivalent for orders vs returns using a LEFT
--    JOIN and a RIGHT JOIN combined with UNION.
--    Then measure: how many rows does the FULL version return that the plain
--    LEFT JOIN does not? Explain the number you get — it is not the number
--    most people expect.


-- 5. Self join. Compute year-over-year revenue: for each year show that
--    year's revenue, the previous year's, and the growth percentage (1 dp).
--    HINT: join a yearly-totals derived table to itself on
--          a.OrderYear = b.OrderYear + 1.


-- 6. Self join on dates. How many distinct customers placed orders on two
--    CONSECUTIVE days?
--    HINT: join orders to itself on the same CustomerID where the second
--          date is the first + INTERVAL 1 DAY.


-- 7. UNION. List the customer IDs that bought at 'Low' priority OR at
--    'Critical' priority, without duplicates.


-- 8. UNION vs UNION ALL — the point of the lesson. Count the rows the same
--    query returns with UNION ALL, then with UNION. Explain the difference
--    in a comment, and say which one is faster and why.


-- 9. INTERSECT. Which products sold MORE THAN $1000 in BOTH the 'Ontario' and
--    the 'West' regions during 2012? Show the first 10 product IDs.
--    (MySQL supports INTERSECT here — confirm it, don't assume.)


-- 10. EXCEPT. Which products sold in 2011 were NOT sold at all in 2012?
--     Show a count, then the first 10 product IDs.
