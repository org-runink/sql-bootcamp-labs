-- ==========================================================================
-- Morning class 25/08 — Worksheet 02 SOLUTIONS: cross-database access, WITH, EXISTS
-- ==========================================================================

CREATE DATABASE IF NOT EXISTS practice_yourname;
USE practice_yourname;

-- ==========================================================================
-- PART A — Two databases
-- ==========================================================================

-- A1. Qualified names.  -> Employees 7 | Customers 1832
SELECT (SELECT COUNT(*) FROM company.employee)      AS Employees,
       (SELECT COUNT(*) FROM superstore.customers)  AS Customers;
--    Form: database.table  (and database.table.column where needed).
--    On ONE server, a "different database" is just a namespace. There is no
--    link to configure, no driver, no cost beyond the query itself. In MySQL
--    a database is closer to a schema than to a separate installation.

-- A2. CROSS JOIN — every combination.  -> 7 employees x 8 regions = 56 rows.
SELECT COUNT(*) AS Pairs
FROM company.employee e
CROSS JOIN (SELECT DISTINCT Region FROM superstore.customers) r;
--    COST: a cross join produces |left| x |right| rows. Here 56, harmless.
--    Against orders x customers it would be 8,060 x 1,832 = 14.7 MILLION.
--    Use it deliberately (building a spine of all combinations), never by
--    accident — an omitted ON clause is the classic way to produce one.

-- A3. A realistic cross-database join.
--    -> Alice Chen/Bob Martinez (Engineering) -> West 382 customers, etc.
WITH assignment AS (
    SELECT employee_id, employee_name,
           CASE team
               WHEN 'Engineering' THEN 'West'
               WHEN 'Sales'       THEN 'Ontario'
               WHEN 'Marketing'   THEN 'Quebec'
               ELSE 'Atlantic'
           END AS Region
    FROM company.employee
)
SELECT a.employee_name, a.Region, COUNT(c.CustomerID) AS CustomersInRegion
FROM assignment a
LEFT JOIN superstore.customers c ON c.Region = a.Region
GROUP BY a.employee_id, a.employee_name, a.Region
ORDER BY a.employee_name;
--
--    WHY NO FOREIGN KEY: in MySQL/InnoDB a FOREIGN KEY may in fact reference
--    a table in another database on the same server — but it is a bad idea
--    and here it is impossible anyway, because nothing in `company` holds a
--    superstore key. More importantly these are two independent systems: an
--    HR database and a sales database. Coupling them with a hard constraint
--    means neither can be restored, migrated or dropped independently. The
--    mapping above is business logic, and it belongs in a query, not in a
--    constraint.

-- A4. Two different SERVERS.
SHOW ENGINES;
--    -> FEDERATED | Support: NO
--    FEDERATED is MySQL's nearest equivalent to an Oracle DBLINK: a local
--    table that is really a proxy for a table on a remote server. It is
--    DISABLED on this build, so there is no way to write a single SQL
--    statement joining this server to another one. The join has to happen
--    somewhere else — see A5.

-- A5. How teams actually do it.
--    1. MOVE THE DATA. Replication, CDC, or a scheduled ETL/ELT job copies
--       the remote tables into one database, and the join becomes local.
--       This is what a data warehouse is for.
--    2. JOIN OUTSIDE THE DATABASE. Query both servers from the application
--       (or a query engine like Trino/Presto, or pandas) and combine the
--       results there.
--    Both trade freshness or complexity for the ability to join at all.
--    A live cross-server join is rarely the right answer even where it is
--    available: it hides a network round-trip inside an innocent-looking
--    query and the optimiser cannot see across the boundary.

-- ==========================================================================
-- PART B — WITH and EXISTS
-- ==========================================================================

-- B1. Derived table rewritten as a CTE.
--     -> 2009-03-21 114,488.88 | 2009-10-20 69,770.46 | 2011-11-19 62,714.12
WITH daily AS (
    SELECT OrderDate, SUM(Sales) AS TotSales
    FROM superstore.orders
    GROUP BY OrderDate
)
SELECT OrderDate, ROUND(TotSales, 2) AS TotSales
FROM daily
ORDER BY TotSales DESC
LIMIT 3;
--    Identical results and, here, identical performance. The CTE reads
--    better because it is defined BEFORE it is used and it has a NAME: you
--    read top-to-bottom instead of inside-out. With one small subquery the
--    difference is taste; at three levels of nesting it is not.

-- B2. Chained CTEs.
--     -> West 3,312,073 (24.4%) | Ontario 2,731,470 (20.1%) | Prarie 19.3% …
WITH per_region AS (
    SELECT c.Region, SUM(o.Sales) AS Revenue
    FROM superstore.orders o
    JOIN superstore.customers c ON o.CustomerID = c.CustomerID
    GROUP BY c.Region
),
with_share AS (
    SELECT Region, Revenue,
           Revenue / (SELECT SUM(Revenue) FROM per_region) * 100 AS PctOfTotal
    FROM per_region
)
SELECT Region, ROUND(Revenue, 0) AS Revenue, ROUND(PctOfTotal, 1) AS PctOfTotal
FROM with_share
ORDER BY Revenue DESC;
--    Note `with_share` referencing `per_region`: CTEs are visible to those
--    defined after them, so a pipeline reads as a sequence of named steps.

-- B3. One CTE used twice.  -> 298 products above the average.
WITH product_revenue AS (
    SELECT ProductID, SUM(Sales) AS Revenue
    FROM superstore.orders
    GROUP BY ProductID
)
SELECT p.ProductName, ROUND(pr.Revenue, 2) AS Revenue
FROM product_revenue pr
JOIN superstore.products p ON pr.ProductID = p.ProductID
WHERE pr.Revenue > (SELECT AVG(Revenue) FROM product_revenue)
ORDER BY Revenue DESC
LIMIT 10;
--    THE WIN over worksheet 08 of the afternoon class (subqueries, second pass) Q7: the aggregation is written ONCE. In the
--    derived-table version the same SELECT appeared twice, and if you edited
--    one copy and not the other the query would still run — and be wrong.

-- B4. RECURSIVE CTE.  -> 12 rows, 2012-01-01 … 2012-12-01
WITH RECURSIVE months(d) AS (
    SELECT DATE('2012-01-01')                                    -- ANCHOR
    UNION ALL
    SELECT d + INTERVAL 1 MONTH FROM months WHERE d < '2012-12-01'  -- RECURSIVE
)
SELECT * FROM months;
--    The ANCHOR runs once and seeds the result. The RECURSIVE part then runs
--    repeatedly, each pass reading the rows the previous pass produced, until
--    it returns none.
--    REMOVE THE WHERE and there is no stopping condition: it generates rows
--    forever. MySQL stops it at cte_max_recursion_depth (default 1000) with
--    an error rather than hanging — a guard rail, not a reason to omit the
--    condition.

-- B5. Date spine — every month appears, even empty ones.
WITH RECURSIVE months(d) AS (
    SELECT DATE('2012-01-01')
    UNION ALL
    SELECT d + INTERVAL 1 MONTH FROM months WHERE d < '2012-12-01'
)
SELECT MONTH(m.d) AS OrderMonth,
       ROUND(COALESCE(SUM(o.Sales), 0), 0) AS Revenue
FROM months m
LEFT JOIN superstore.orders o
       ON YEAR(o.OrderDate) = YEAR(m.d)
      AND MONTH(o.OrderDate) = MONTH(m.d)
GROUP BY m.d
ORDER BY m.d;
--    -> Jan 290,891 | Feb 216,233 | Mar 321,327 | Apr 258,953 …
--
--    WHY GROUPING ORDERS ALONE CANNOT DO THIS: GROUP BY can only produce a
--    group for a value that EXISTS in the data. A month with no orders has
--    no rows, so it has no group, so it silently disappears — and a chart
--    built on that result shows a line skipping straight over the gap
--    instead of dropping to zero. The spine supplies the missing months and
--    COALESCE turns the resulting NULLs into 0.
--    (All 12 months have sales in 2012, so nothing is missing here. Run it
--    against a sparser filter and the difference appears immediately.)

-- B6. EXISTS.  -> 1812 customers have ordered.
SELECT COUNT(*) AS CustomersWhoOrdered
FROM superstore.customers c
WHERE EXISTS (SELECT 1 FROM superstore.orders o WHERE o.CustomerID = c.CustomerID);
--    `SELECT 1` is idiomatic: EXISTS only asks whether a row comes back, so
--    the select list is never evaluated. `SELECT *` is equally fine.

-- B7. NOT EXISTS.  -> 20 customers have never ordered.
SELECT c.CustomerID, c.CustomerName, c.Province
FROM superstore.customers c
WHERE NOT EXISTS (SELECT 1 FROM superstore.orders o WHERE o.CustomerID = c.CustomerID);
--    Matches worksheet 06 of the afternoon class (joins & set operators) Q3's LEFT JOIN … IS NULL exactly: 1812 + 20 = 1832.

-- B8. THE NULL TRAP.  -> NOT IN gives 0.  NOT EXISTS gives 1832.
--
--    WHY. `x NOT IN (1, NULL)` expands to
--         x <> 1 AND x <> NULL
--    and `x <> NULL` is never TRUE — it is UNKNOWN, because NULL means
--    "unknown value" and nothing can be compared to it. TRUE AND UNKNOWN is
--    UNKNOWN, and WHERE keeps only TRUE. So EVERY row is discarded and you
--    get zero rows — with no error and no warning.
--
--    NOT EXISTS asks a different question: "did the subquery return a
--    matching row?" A NULL in the subquery simply fails to match, and the
--    row is correctly kept.
--
--    THE RULE: use NOT EXISTS for anti-joins unless you can guarantee the
--    subquery column is NOT NULL. If you must use NOT IN, either add
--    `WHERE col IS NOT NULL` to the subquery or rely on a NOT NULL
--    constraint you have actually checked — as in worksheet 08 of the afternoon class (subqueries, second pass) Q3, where
--    returns.OrderID is the primary key. A query that silently returns
--    nothing is far more dangerous than one that fails.

-- B9. Region rollup with EXISTS.
--     -> West 3,312,073 / 381 ordered / 1 never | Ontario 2,731,470 / 334 / 3
--        Prarie 2,619,153 / 313 / 0 | Atlantic 1,834,002 / 338 / 6 …
WITH cust AS (
    SELECT CustomerID, Region FROM superstore.customers
)
SELECT cu.Region,
       ROUND(COALESCE(SUM(o.Sales), 0), 0) AS Revenue,
       COUNT(DISTINCT CASE WHEN EXISTS (
           SELECT 1 FROM superstore.orders x WHERE x.CustomerID = cu.CustomerID
       ) THEN cu.CustomerID END) AS CustomersWhoOrdered,
       COUNT(DISTINCT CASE WHEN NOT EXISTS (
           SELECT 1 FROM superstore.orders x WHERE x.CustomerID = cu.CustomerID
       ) THEN cu.CustomerID END) AS CustomersWhoNeverOrdered
FROM cust cu
LEFT JOIN superstore.orders o ON o.CustomerID = cu.CustomerID
GROUP BY cu.Region
ORDER BY Revenue DESC;

-- B10. Clean up.
DROP DATABASE practice_yourname;
