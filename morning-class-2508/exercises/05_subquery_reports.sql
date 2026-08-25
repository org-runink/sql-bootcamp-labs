-- ==========================================================================
-- Morning class 25/08 — Worksheet 05: Building reports with subqueries
-- ==========================================================================
-- Database: superstore.  Read-only — no scratch database needed.
--
-- The afternoon class covered what a subquery IS. This one is about what
-- they are FOR: assembling a report where the numbers have to be compared
-- against something the query has not calculated yet.
--
-- Almost every real report needs a figure that is not in the row you are
-- looking at — a grand total to divide by, a group average to beat, a
-- threshold from somewhere else. A subquery is how you fetch it.
--
-- The four positions a subquery can occupy, and what each is for:
--
--   IN SELECT   a scalar subquery — ONE value, attached to every row.
--               "...and here is the company total, for comparison."
--   IN FROM     a derived table — a whole result set you then query again.
--               "First summarise, then report on the summary."
--   IN WHERE    a filter — IN / NOT IN / EXISTS / a comparison.
--               "...only the rows that qualify against this other thing."
--   IN HAVING   a filter on GROUPS, after aggregation.
--               "...only the groups whose total beats this figure."
--
-- CORRELATED vs UNCORRELATED matters throughout: an uncorrelated subquery is
-- computed ONCE; a correlated one references the outer query and is
-- conceptually re-evaluated per row. Know which you have written.
-- ==========================================================================

USE superstore;

-- ==========================================================================
-- PART A — Scalar subqueries: adding context to every row
-- ==========================================================================

-- 1. A regional revenue report: region, revenue, and that region's share of
--    company-wide revenue as a percentage (1 dp), biggest first.
--    Get the grand total with a scalar subquery in the SELECT list.


-- 2. Extend question 1 with a `vs_average_region` column: the region's
--    revenue minus the average revenue per region.
--    CAREFUL: "average revenue per region" is not AVG(Sales). Work out what
--    it actually is, and get it with a subquery over a derived table.


-- 3. A product report: product name, category, revenue, and the revenue of
--    the best-selling product in the WHOLE catalogue, for reference.
--    Top 10 by revenue.
--    Is your subquery correlated or uncorrelated? How can you tell by
--    looking at it, and what does that mean for how often it runs?


-- ==========================================================================
-- PART B — Derived tables: reporting on a summary
-- ==========================================================================

-- 4. You cannot filter on an aggregate in WHERE. Produce the list of
--    customers whose lifetime revenue exceeds 30,000 — customer name,
--    province, order count, revenue — by summarising first in a derived
--    table and filtering the result.
--    Then write the same thing using HAVING. Which reads better, and is
--    there any case where only the derived table will do?


-- 5. A two-level report. For each region show:
--       the number of customers, total revenue, and revenue per customer,
--    where each customer's revenue is computed first and then aggregated up.
--    Build it as a derived table of per-customer totals, grouped by region.
--    Check your answer against a direct GROUP BY on region — the revenue
--    figures must match. If they do not, you have a grain bug.


-- 6. Rewrite question 5 as a CTE. Same result, different syntax.
--    In a comment: name one thing the CTE version gives you that the derived
--    table does not.
--    (Worksheet 02 covered CTEs — this is the direct comparison.)


-- ==========================================================================
-- PART C — Subqueries as filters
-- ==========================================================================

-- 7. List every customer who has NEVER placed an order — id, name, province.
--    Write it THREE ways: NOT IN, NOT EXISTS, and LEFT JOIN ... IS NULL.
--    Confirm all three agree.
--    THEN: before trusting the NOT IN version, run the check that proves it
--    is safe here. Worksheet 08 of the afternoon class shows what happens
--    when it is not — and the failure is silent, so "it returned rows" is
--    not evidence of correctness. Say in a comment what you checked.
--    (Try the same three against `products` too. That one returns nothing at
--    all — which is a valid answer, not a broken query. How would you tell
--    the difference?)


-- 8. Which customers ordered in 2012 but NOT in 2011? Name and province.
--    This is a set-difference question; EXISTS and NOT EXISTS express it
--    directly.


-- 9. Products that sold above the average revenue FOR THEIR OWN CATEGORY —
--    not the overall average. Return the count, then the top 10 with name,
--    category and revenue.
--    This one needs a CORRELATED subquery: the comparison value depends on
--    which category the current row belongs to.


-- ==========================================================================
-- PART D — Subqueries in HAVING, and putting it together
-- ==========================================================================

-- 10. Which provinces have more customers than the average province?
--     Province and customer count, biggest first, filtered in HAVING.


-- 11. For each category, the number of products that individually earned
--     more than 10,000 — and that count as a percentage of all products in
--     the category.


-- 12. Stretch — the report a manager would actually ask for.
--     For 2012 only, one row per region containing:
--       - revenue
--       - share of 2012 company revenue (%)
--       - number of distinct customers who ordered
--       - revenue per ordering customer
--       - the name of that region's single best-selling product
--       - whether the region beat the average regional revenue ('above' /
--         'below')
--     Every column needs a different technique. Build it up one column at a
--     time and check each against a simple query before adding the next —
--     that is how these are actually written, not in one go.
