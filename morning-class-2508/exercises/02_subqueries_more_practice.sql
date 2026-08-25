-- ==========================================================================
-- EXTRA 03 — Subqueries                                       (reinforces L08)
-- ==========================================================================
-- Database: superstore.  Tables: customers, products, orders, returns.
--
-- The lecture showed two patterns. Both appear below:
--   Pattern 1 — subquery as a FILTER:  WHERE col IN (SELECT …)
--                                      WHERE col > (SELECT …)   -- scalar
--   Pattern 2 — subquery as a DERIVED TABLE: FROM ( SELECT … ) AS t
--
-- A subquery is always wrapped in parentheses. A DERIVED TABLE must also be
-- given an alias — `) AS t` — or MySQL rejects it.
-- ==========================================================================

USE superstore;

-- 1. Scalar subquery. How many order lines sold for MORE than the average
--    line's sales value? Report the count.
--    Then answer in a comment: why can't you just write
--        WHERE Sales > AVG(Sales)
--    without a subquery?


-- 2. Filter with IN. Total sales and number of distinct orders for orders
--    that were RETURNED — using a subquery against `returns`, not a JOIN.


-- 3. Anti-filter with NOT IN. How many distinct customers have never had a
--    single order returned?
--    WARNING: NOT IN behaves surprisingly if the subquery can return NULL.
--    Check whether returns.OrderID is nullable and say why it matters.


-- 4. Derived table. Which single DAY had the highest total sales? Show the
--    date and the total (2 dp) for the top 3 days.


-- 5. Derived table + HAVING. How many orders contained MORE THAN 3 distinct
--    products? Report the count.
--    HINT: group by OrderID in the inner query, then count the rows it
--          returns.


-- 6. Sales report by year and month, Office Supplies only — total sales and
--    distinct orders per year/month, most recent first, first 12 rows.


-- 7. Comparison against a group. List the products whose TOTAL sales exceed
--    the average total-sales-per-product. Show the top 10 by revenue.
--    HINT: you need per-product totals twice — once to compare, once as the
--          benchmark. A derived table gives you both.


-- 8. Correlated subquery (stretch). For each region, show the single
--    best-selling product name by revenue in that region.
--    HINT: one way is a derived table of (region, product, revenue) joined
--          back to a derived table of (region, MAX(revenue)).


-- 9. Compare approaches (discussion). Question 2 can be written three ways:
--    with IN, with an INNER JOIN, and with EXISTS. Write all three, confirm
--    they agree, and note in a comment when each reads best.
