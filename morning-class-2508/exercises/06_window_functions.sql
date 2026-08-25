-- ==========================================================================
-- Morning class 25/08 — Worksheet 06: Window functions
-- ==========================================================================
-- Database: superstore.
--
-- GROUP BY answers "what is the total per region?" and gives you one row per
-- region. A window function answers "what is the total for THIS row's region,
-- next to this row?" and gives you back every row you started with.
--
-- That one difference — aggregating WITHOUT collapsing — is what makes
-- running totals, rankings, month-over-month deltas and top-N-per-group
-- possible in a single query. Before window functions, each of those needed
-- a self-join or a correlated subquery.
--
-- The shape is always:
--     <function>() OVER (PARTITION BY <group> ORDER BY <sort> <frame>)
-- All three parts inside OVER() are optional.
--
-- These are read-only queries — no scratch database needed.
-- ==========================================================================

USE superstore;

-- ==========================================================================
-- PART A — Aggregating without collapsing
-- ==========================================================================

-- 1. First, the contrast. Write TWO queries against `customers`:
--       a) GROUP BY Region, returning one row per region with COUNT(*)
--       b) SELECT Region, CustomerName, COUNT(*) OVER (PARTITION BY Region)
--    Run both. In a comment, describe exactly how the two result sets differ
--    and when you would want each.


-- 2. Revenue by region, with each region's share of the grand total as a
--    percentage (1 dp), biggest first.
--    Do it WITHOUT a subquery — use SUM(SUM(Sales)) OVER () for the total.
--    HINT: that double-SUM looks strange. The inner SUM is the GROUP BY
--    aggregate; the outer one is a window over the already-grouped rows.
--    Compare with worksheet 04 Q8 of the afternoon class, which needed a
--    nested subquery to do the same thing.


-- 3. For every order line, show OrderID, Sales, and the total Sales of the
--    whole order it belongs to. First 10 rows is plenty.
--    Then explain in a comment why GROUP BY cannot produce this shape.


-- ==========================================================================
-- PART B — Ranking, and what happens on ties
-- ==========================================================================

-- 4. List the top 8 customers by number of distinct orders, showing customer
--    name, the order count, and THREE rank columns side by side:
--    ROW_NUMBER(), RANK() and DENSE_RANK().
--    There are genuine ties in this data. Describe in a comment exactly how
--    the three differ where a tie occurs, and name a situation where each is
--    the right choice.


-- 5. Top 2 customers by revenue IN EACH REGION.
--    This is the classic use of window functions. You cannot put a window
--    function in WHERE — work out why, and what you must do instead.
--    HINT: compute the ranking in a CTE, then filter the CTE.


-- 6. Which product sub-categories are in the top quartile by revenue?
--    Use NTILE(4) to bucket them, then keep bucket 1.


-- ==========================================================================
-- PART C — Looking at other rows: ORDER BY and frames
-- ==========================================================================

-- 7. Monthly revenue for 2012 with a RUNNING TOTAL alongside it.
--    HINT: adding ORDER BY inside OVER() changes the default frame from
--    "the whole partition" to "everything up to this row".


-- 8. Extend question 7: add a `vs_prev_month` column showing the change in
--    revenue from the previous month, using LAG().
--    What is in that column for January, and why is that correct rather than
--    a bug to be patched to zero?


-- 9. Add a 3-month moving average to the same query, using an explicit frame:
--        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--    Explain in a comment what the first two rows of that column mean, given
--    there is no month before January.


-- 10. Stretch. For each region, show every month of 2012, that month's
--     revenue, and the region's rank among all regions FOR THAT MONTH.
--     A region that is first in January and fifth in June should show both.
--     HINT: PARTITION BY the month, ORDER BY the revenue.
