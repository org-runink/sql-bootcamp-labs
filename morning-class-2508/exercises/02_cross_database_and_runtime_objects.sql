-- ==========================================================================
-- Morning class 25/08 — Worksheet 02: Crossing databases, and run-time objects (WITH / EXISTS)
-- ==========================================================================
-- Two themes, both about objects that exist only while a query runs:
--
--   PART A — reaching data that lives in ANOTHER database
--   PART B — CTEs (WITH) and EXISTS: named result sets and existence tests
--            that are built, used, and thrown away within a single statement
--
-- This lab has TWO databases on one server — `superstore` and `company` —
-- which is exactly what Part A needs.
--
-- SHARED SERVER: as in worksheet 01 (views), create your own scratch database for
-- anything you CREATE:
--     CREATE DATABASE IF NOT EXISTS practice_yourname;
--     USE practice_yourname;
-- Never CREATE or DROP inside `superstore` or `company`.
-- ==========================================================================

-- ==========================================================================
-- PART A — Two databases
-- ==========================================================================

-- A1. Qualified names. Without running USE, return in ONE query the number of
--     rows in company.employee and in superstore.customers side by side.
--     What is the general form of a cross-database reference?


-- A2. Join across databases. Treat `company.employee` as a staff list and
--     `superstore.customers` as clients. Join them on nothing meaningful yet
--     — instead, CROSS JOIN one employee to each Region in superstore and
--     count the pairs. Then say in a comment what a cross join costs.


-- A3. The realistic version. Cross-database joins are just joins: build a
--     query that lists every `company.employee` alongside the number of
--     superstore customers in a region you assign them.
--     HINT: there is no real FK between these databases. Invent the mapping
--     with a CTE (see Part B) or a CASE. Note in a comment WHY there is no
--     foreign key here — can a FK cross databases?


-- A4. What about two different SERVERS? Oracle calls it a DBLINK; MySQL's
--     equivalent is the FEDERATED storage engine. Check whether this server
--     supports it:
--         SHOW ENGINES;                       -- look at the FEDERATED row
--     Report the Support value, and say what that means for a query that
--     needs to join data on this server to data on another one.


-- A5. Given your A4 answer, name two ways a team actually moves data between
--     separate database servers when a live cross-server join is unavailable.


-- ==========================================================================
-- PART B — Run-time objects: WITH (CTE) and EXISTS
-- ==========================================================================

-- B1. Your first CTE. Rewrite this derived-table query using WITH:
--         SELECT * FROM (
--             SELECT OrderDate, SUM(Sales) AS TotSales
--             FROM superstore.orders GROUP BY OrderDate) d
--         ORDER BY d.TotSales DESC LIMIT 3;
--     Both forms are legal. Which reads better, and why?


-- B2. Chained CTEs. Using two CTEs in one statement — the first computing
--     revenue per region, the second adding each region's percentage of the
--     total — list regions by revenue.
--     HINT: WITH a AS (...), b AS (... FROM a ...) SELECT ... FROM b;
--     A later CTE may reference an earlier one.


-- B3. A CTE used twice. Compute each product's total revenue once, then use
--     it BOTH as the row source AND as the benchmark (its average), listing
--     products above average. Compare with worksheet 08 of the afternoon class (subqueries, second pass) Q7, where the same
--     subquery had to be written out twice.


-- B4. RECURSIVE CTE — generating rows that are not in any table. Produce the
--     12 first-of-month dates of 2012:
--         WITH RECURSIVE months(d) AS (
--             SELECT DATE('2012-01-01')
--             UNION ALL
--             SELECT d + INTERVAL 1 MONTH FROM months WHERE d < '2012-12-01')
--         SELECT * FROM months;
--     Identify the two halves (anchor and recursive) and the stopping
--     condition. What happens if you remove the WHERE?


-- B5. Why a date spine matters. Using B4's months, LEFT JOIN 2012 sales onto
--     it so that EVERY month appears — including any with no sales at all.
--     Explain in a comment why grouping the orders table alone cannot
--     produce a row for a month that has no orders.


-- B6. EXISTS. List the 10 customers who HAVE placed at least one order,
--     using EXISTS rather than a join or IN.


-- B7. NOT EXISTS. List the customers who have never placed an order. Compare
--     your row count with the LEFT JOIN … IS NULL answer from worksheet 06 of the afternoon class (joins & set operators) Q3 —
--     they must agree.


-- B8. THE NULL TRAP — the most important question here. Run both of these
--     and explain the difference:
--
--       SELECT COUNT(*) FROM superstore.customers
--       WHERE CustomerID NOT IN (SELECT CustomerID FROM
--             (SELECT 1 AS CustomerID UNION ALL SELECT NULL) z);
--
--       SELECT COUNT(*) FROM superstore.customers c
--       WHERE NOT EXISTS (SELECT 1 FROM
--             (SELECT 1 AS CustomerID UNION ALL SELECT NULL) z
--             WHERE z.CustomerID = c.CustomerID);
--
--     One returns 0 and the other 1832. Work out WHY before reading the
--     solution, and write the rule you will follow from now on.


-- B9. Putting it together. Using a CTE, produce for each region: revenue,
--     the number of customers who ordered, and the number who never did.
--     Use EXISTS or NOT EXISTS for the last two.


-- B10. Clean up: DROP DATABASE practice_yourname;
