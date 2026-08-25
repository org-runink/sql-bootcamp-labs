-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 03 SOLUTIONS: aggregates, GROUP BY, HAVING   (L06)
-- ==========================================================================
-- Every query below was run against the seeded superstore database; the
-- expected results are quoted so you can check yourself without guessing.
-- ==========================================================================

USE superstore;

-- 1. One-row overview.
--    -> 8060 lines, 5361 orders, 1812 customers, 13,570,810.63 total,
--       1683.72 average per line.
--    Note lines (8060) > orders (5361): a single order spans several products.
SELECT COUNT(*)                    AS OrderLines,
       COUNT(DISTINCT OrderID)     AS Orders,
       COUNT(DISTINCT CustomerID)  AS Customers,
       ROUND(SUM(Sales), 2)        AS TotalSales,
       ROUND(AVG(Sales), 2)        AS AvgSalesPerLine
FROM orders;

-- 2. Revenue by category.
--    -> Technology 5,498,925.46 | Furniture 4,326,337.49 | Office Supplies 3,745,547.68
--    Furniture carries the best margin (0.574) but Technology sells more.
SELECT p.ProductCategory,
       COUNT(DISTINCT o.OrderID)         AS Orders,
       ROUND(SUM(o.Sales), 2)            AS Revenue,
       ROUND(AVG(p.ProductBaseMargin), 3) AS AvgMargin
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
GROUP BY p.ProductCategory
ORDER BY Revenue DESC;

-- 3. Ship mode cost.
--    -> Delivery Truck averages 43.84 shipping vs ~7.7 for the air modes,
--       yet Regular Air carries the most volume (6117 lines) and profit.
SELECT ShipMode,
       COUNT(*)                    AS LineCount,
       ROUND(AVG(ShippingCost), 2) AS AvgShippingCost,
       ROUND(SUM(Profit), 2)       AS TotalProfit
FROM orders
GROUP BY ShipMode
ORDER BY AvgShippingCost DESC;

-- 4. Monthly extremes in 2012.
--    -> Every month spans the full 1..50 quantity range; sales swing from a
--       few dollars to >20k, which is why AVG alone hides the picture.
SELECT MONTH(OrderDate)      AS OrderMonth,
       MIN(OrderQuantity)    AS MinQty,
       MAX(OrderQuantity)    AS MaxQty,
       ROUND(MIN(Sales), 2)  AS MinSales,
       ROUND(MAX(Sales), 2)  AS MaxSales
FROM orders
WHERE YEAR(OrderDate) = 2012
GROUP BY MONTH(OrderDate)
ORDER BY OrderMonth;

-- 5. Provinces with more than 100 customers.
--    -> Ontario 337, British Columbia 239, Quebec 210, Nova Scotia 187,
--       Manitoba 172, Alberta 143, Saskachewan 141, Yukon 130.
--
--    WHY NOT `WHERE`: WHERE filters individual ROWS *before* grouping, so at
--    that point COUNT(*) does not exist yet — there are no groups to count.
--    HAVING filters the GROUPS *after* aggregation. Rule of thumb: conditions
--    on raw columns go in WHERE, conditions on aggregates go in HAVING.
SELECT Province, COUNT(*) AS Customers
FROM customers
GROUP BY Province
HAVING COUNT(*) > 100
ORDER BY Customers DESC;

-- 6. Loss-making sub-categories.
--    -> Tables -62,176.37 | Bookcases -33,582.13 |
--       Scissors, Rulers and Trimmers -7,799.25 | Rubber Bands -102.67
--    Bulky furniture loses money — compare with the Delivery Truck shipping
--    cost found in Q3. The two answers explain each other.
SELECT p.ProductSubCategory,
       ROUND(SUM(o.Profit), 2) AS TotalProfit
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
GROUP BY p.ProductSubCategory
HAVING SUM(o.Profit) < 0
ORDER BY TotalProfit;

-- 7. Top 10 repeat customers.
--    -> Patrick Jones (New Brunswick) and Michael Dominguez (Ontario) lead
--       with 16 orders each.
--    GROUP BY CustomerID (not just the name): two people can share a name.
SELECT c.CustomerName,
       c.Province,
       COUNT(DISTINCT o.OrderID) AS Orders,
       ROUND(SUM(o.Sales), 2)    AS TotalSales
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.Province
ORDER BY Orders DESC, TotalSales DESC
LIMIT 10;

-- 8. Regional share of total sales.
--    -> West 24.4% | Ontario 20.1% | Prarie 19.3% | Atlantic 13.5% |
--       Quebec 9.8% | Yukon 6.3% | Northwest Territories 5.8% | Nunavut 0.8%
--    The scalar subquery runs once and returns a single value, so it can sit
--    directly in the SELECT list. ("Prarie" is spelled that way in the data —
--    real datasets have typos; don't "fix" it in a WHERE clause by accident.)
SELECT c.Region,
       ROUND(SUM(o.Sales), 2) AS RegionSales,
       ROUND(SUM(o.Sales) / (SELECT SUM(Sales) FROM orders) * 100, 1) AS PctOfTotal
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
GROUP BY c.Region
ORDER BY RegionSales DESC;
