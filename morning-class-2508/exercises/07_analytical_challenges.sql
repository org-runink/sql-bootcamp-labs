-- ==========================================================================
-- Morning class 25/08 — Worksheet 07: Combined analytical challenges
-- ==========================================================================
-- Database: superstore.
--
-- This is the capstone. Nothing here teaches a new keyword — every challenge
-- is a REAL BUSINESS QUESTION, phrased the way a manager would ask it, and
-- your job is to work out which tools it needs and in what order.
--
-- Expect to combine: joins, GROUP BY, CTEs, subqueries, CASE WHEN and window
-- functions. Most challenges need three or four of them together.
--
-- Each challenge ends with a QUESTION TO ANSWER IN WORDS. That part matters
-- as much as the SQL — a number nobody can interpret is not an answer, and
-- several of these have a result that is not what you would expect.
--
-- Work top to bottom; they get harder. These are read-only queries.
-- ==========================================================================

USE superstore;

-- ==========================================================================
-- CHALLENGE 1 — The monthly growth report
-- ==========================================================================
-- Your manager wants a 2012 report: for each month, the revenue, the change
-- from the previous month in currency, and the change as a percentage.
--
-- 1a. Build it.
-- 1b. January's change columns will be empty. Decide what a report SHOULD
--     show there, and defend the choice in a comment.
-- 1c. Which single month had the worst percentage decline? Does that tell
--     you anything real, or is it an artefact of how the business works?


-- ==========================================================================
-- CHALLENGE 2 — Who actually pays the bills
-- ==========================================================================
-- Split customers into "one-time" (exactly one order) and "repeat" (more
-- than one). For each group show the number of customers, total revenue, and
-- each group's share of overall revenue.
--
-- 2a. Build it.
-- 2b. The result is lopsided. State what it implies for where the business
--     should spend its marketing budget — and then argue the OPPOSITE case,
--     because this number is routinely over-read.


-- ==========================================================================
-- CHALLENGE 3 — The Pareto question
-- ==========================================================================
-- "Roughly 20% of our products make 80% of our revenue." Test it.
--
-- 3a. Rank every product by revenue, and compute a running cumulative
--     revenue down that ranking.
-- 3b. How many products does it take to reach 80% of total revenue, and what
--     percentage of the catalogue is that?
--     HINT: a running total compared against the grand total. Both are window
--     functions; you need the ranking BEFORE you can filter on it.
-- 3c. Is the claim true here? Answer with the actual figures.


-- ==========================================================================
-- CHALLENGE 4 — Does discounting work?
-- ==========================================================================
-- Bucket every order line into discount bands — none, low (<=3%), mid (<=6%)
-- and high (>6%) — and for each band show the line count, average discount,
-- total sales, total profit, and the profit margin as a percentage of sales.
--
-- 4a. Build it.
-- 4b. The margin does NOT fall smoothly as discount rises. Describe the
--     actual pattern.
-- 4c. This is the important one: the "none" band has a LOWER margin than the
--     "low" band. Give at least two explanations that would produce that,
--     and say what extra data you would need to tell them apart.
--     (Careful: it is very tempting to conclude "discounting improves
--     margin". Say why that conclusion is not supported.)


-- ==========================================================================
-- CHALLENGE 5 — Return rates by category
-- ==========================================================================
-- Which product category gets returned most? For each category show the
-- number of distinct orders containing it, the number of those orders that
-- were returned, and the return rate as a percentage.
--
-- 5a. Build it. Watch the grain — `returns` is one row per ORDER, `orders`
--     is one row per order LINE.
-- 5b. The three categories come out within about one point of each other.
--     Does that mean category has no effect on returns? Consider what the
--     grain of `returns` prevents you from knowing.


-- ==========================================================================
-- CHALLENGE 6 — Customer cohorts
-- ==========================================================================
-- Group every customer by the YEAR of their first ever order — their cohort.
--
-- 6a. How many customers are in each cohort?
-- 6b. For each cohort, show total revenue and average revenue per customer.
-- 6c. The 2009 cohort is much the largest. Explain why that is guaranteed by
--     how the data was collected, regardless of business performance — and
--     what you would need in order to make a fair comparison between cohorts.


-- ==========================================================================
-- CHALLENGE 7 — Best product in every region
-- ==========================================================================
-- For each region, find the single product with the highest revenue, showing
-- region, product name, and that revenue.
--
-- 7a. Build it.
-- 7b. Rewrite it WITHOUT any window function. (A correlated subquery or a
--     join against a per-region maximum both work.)
-- 7c. Compare the two. Which is easier to read, and what happens to each if
--     two products tie for first in a region?


-- ==========================================================================
-- CHALLENGE 8 — Stretch: the executive summary
-- ==========================================================================
-- Produce ONE query returning a single row of headline numbers for 2012:
--     total revenue, total profit, overall margin %,
--     number of orders, number of distinct customers,
--     average order value, and the revenue of the best month.
--
-- Every one of these has a grain trap in it somewhere. When you are done,
-- check each number against a separate simple query — and say in a comment
-- which one you got wrong first, because most people get at least one.
