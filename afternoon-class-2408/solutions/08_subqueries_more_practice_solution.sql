-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 08 SOLUTIONS: subqueries, second pass   (L08)
-- ==========================================================================

USE superstore;

-- 1. Scalar subquery.  -> 1931 order lines beat the average line.
--
--    WHY YOU NEED THE SUBQUERY: `WHERE Sales > AVG(Sales)` is illegal. WHERE
--    is evaluated row by row, BEFORE any aggregation happens — at that moment
--    AVG(Sales) does not exist yet. The subquery is evaluated first, collapses
--    to a single number, and the outer query then compares each row to it.
SELECT COUNT(*) AS AboveAverageLines
FROM orders
WHERE Sales > (SELECT AVG(Sales) FROM orders);

-- 2. Filter with IN.  -> 558 returned orders, 1,485,707.73 of revenue at risk.
SELECT COUNT(DISTINCT OrderID) AS ReturnedOrders,
       ROUND(SUM(Sales), 2)    AS RevenueAtRisk
FROM orders
WHERE OrderID IN (SELECT OrderID FROM returns);

-- 3. NOT IN.  -> 1353 customers have never had an order returned.
--
--    THE NULL TRAP: if the subquery returns even ONE NULL, `x NOT IN (…)`
--    can never be TRUE — it evaluates to UNKNOWN, and the outer query returns
--    ZERO rows. Silent, total, and easy to blame on the data.
--    Here it is safe: returns.OrderID is the PRIMARY KEY, hence NOT NULL
--    (confirm with: SHOW COLUMNS FROM returns;). When you cannot guarantee
--    that, write `NOT EXISTS` instead — it is NULL-proof.
SELECT COUNT(DISTINCT c.CustomerID) AS CustomersNeverReturned
FROM customers c
WHERE c.CustomerID NOT IN (
    SELECT o.CustomerID
    FROM orders o
    JOIN returns r ON o.OrderID = r.OrderID
);

-- 4. Derived table — best sales day.
--    -> 2009-03-21: 114,488.88 | 2009-10-20: 69,770.46 | 2011-11-19: 62,714.12
--    The inner query collapses lines to one row per day; the outer query then
--    ranks those rows. Note the mandatory alias `AS d`.
SELECT d.OrderDate, ROUND(d.TotalSales, 2) AS TotalSales
FROM (
    SELECT OrderDate, SUM(Sales) AS TotalSales
    FROM orders
    GROUP BY OrderDate
) AS d
ORDER BY d.TotalSales DESC
LIMIT 3;

-- 5. Derived table + HAVING.  -> 115 orders contained more than 3 products.
--    You cannot answer this in one flat query: the thing being counted is
--    GROUPS, and only a derived table turns groups back into countable rows.
SELECT COUNT(*) AS OrdersWithMoreThan3Products
FROM (
    SELECT OrderID
    FROM orders
    GROUP BY OrderID
    HAVING COUNT(DISTINCT ProductID) > 3
) AS t;

-- 6. Office Supplies sales by year and month.
--    -> 2012-12: 83,245.58 (69 orders) | 2012-11: 79,640.25 (56) |
--       2012-10: 109,849.20 (92) …
SELECT YEAR(o.OrderDate)          AS OrderYear,
       MONTH(o.OrderDate)         AS OrderMonth,
       ROUND(SUM(o.Sales), 2)     AS TotalSales,
       COUNT(DISTINCT o.OrderID)  AS Orders
FROM orders o
WHERE o.ProductID IN (
    SELECT ProductID FROM products WHERE ProductCategory = 'Office Supplies'
)
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY OrderYear DESC, OrderMonth DESC
LIMIT 12;

-- 7. Products beating the average product.
--    -> 298 of the 1234 products are above the mean.
--    The same aggregation appears twice: once as the row source, once inside
--    a scalar subquery as the benchmark. That the mean sits so far from the
--    midpoint (298 of 1234, not ~617) tells you the distribution is skewed —
--    a few big sellers drag the average up.
SELECT p.ProductName, ROUND(t.Revenue, 2) AS Revenue
FROM (
    SELECT ProductID, SUM(Sales) AS Revenue
    FROM orders
    GROUP BY ProductID
) AS t
JOIN products p ON t.ProductID = p.ProductID
WHERE t.Revenue > (
    SELECT AVG(Revenue) FROM (
        SELECT ProductID, SUM(Sales) AS Revenue FROM orders GROUP BY ProductID
    ) AS benchmark
)
ORDER BY Revenue DESC
LIMIT 10;

-- 8. Best-selling product per region (stretch).
--    -> Ontario & Quebec: "Global Troy Executive Leather Low-Back Tilter";
--       Atlantic & West: "Polycom ViewStation ISDN Videoconferencing Unit".
--    Pattern: build (region, product, revenue), build (region, MAX(revenue)),
--    then join them back together to recover WHICH product hit the max — an
--    aggregate alone tells you the value but not the row it came from.
SELECT r.Region, p.ProductName, ROUND(r.Revenue, 2) AS Revenue
FROM (
    SELECT c.Region, o.ProductID, SUM(o.Sales) AS Revenue
    FROM orders o JOIN customers c ON o.CustomerID = c.CustomerID
    GROUP BY c.Region, o.ProductID
) AS r
JOIN (
    SELECT Region, MAX(Revenue) AS MaxRevenue FROM (
        SELECT c.Region, o.ProductID, SUM(o.Sales) AS Revenue
        FROM orders o JOIN customers c ON o.CustomerID = c.CustomerID
        GROUP BY c.Region, o.ProductID
    ) AS inner_r
    GROUP BY Region
) AS m ON r.Region = m.Region AND r.Revenue = m.MaxRevenue
JOIN products p ON r.ProductID = p.ProductID
ORDER BY Revenue DESC;

-- 9. Three spellings of the same question — all return 558.
--
--    IN       — reads best when the inner list is a simple set of keys.
--    JOIN     — best when you also need COLUMNS from the other table. But it
--               can MULTIPLY rows if the right side has duplicate keys, which
--               is why COUNT(DISTINCT …) appears here.
--    EXISTS   — best for pure existence checks and on large tables: it can
--               stop at the first match, and it is immune to the NULL trap
--               from Q3.
SELECT COUNT(DISTINCT OrderID) AS ViaIn
FROM orders WHERE OrderID IN (SELECT OrderID FROM returns);

SELECT COUNT(DISTINCT o.OrderID) AS ViaJoin
FROM orders o JOIN returns r ON o.OrderID = r.OrderID;

SELECT COUNT(DISTINCT o.OrderID) AS ViaExists
FROM orders o
WHERE EXISTS (SELECT 1 FROM returns r WHERE r.OrderID = o.OrderID);
