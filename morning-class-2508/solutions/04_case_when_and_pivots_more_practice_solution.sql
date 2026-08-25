-- ==========================================================================
-- EXTRA 04 — SOLUTIONS: CASE WHEN and pivots                  (reinforces L09)
-- ==========================================================================

USE superstore;

-- 1. Sales tiers.
--    -> Large 2714 lines / 12,047,393.72 | Medium 3911 / 1,447,508.61
--       Small 1435 / 75,908.29
--    Read it: the FEWEST lines carry ~89% of the revenue. Counting rows and
--    summing money answer different questions — a report that showed only
--    line counts would rank these tiers almost backwards.
SELECT CASE WHEN Sales < 100  THEN 'Small'
            WHEN Sales < 1000 THEN 'Medium'
            ELSE 'Large'
       END                     AS SalesTier,
       COUNT(*)                AS OrderLines,
       ROUND(SUM(Sales), 2)    AS Revenue
FROM orders
GROUP BY SalesTier
ORDER BY Revenue DESC;

-- 2. Category × year pivot.
--    -> Technology leads every year; Furniture is the only category that ends
--       LOWER in 2012 (958,554) than it started in 2009 (1,328,108).
SELECT p.ProductCategory,
       ROUND(SUM(CASE WHEN YEAR(o.OrderDate) = 2009 THEN o.Sales ELSE 0 END), 0) AS Y2009,
       ROUND(SUM(CASE WHEN YEAR(o.OrderDate) = 2010 THEN o.Sales ELSE 0 END), 0) AS Y2010,
       ROUND(SUM(CASE WHEN YEAR(o.OrderDate) = 2011 THEN o.Sales ELSE 0 END), 0) AS Y2011,
       ROUND(SUM(CASE WHEN YEAR(o.OrderDate) = 2012 THEN o.Sales ELSE 0 END), 0) AS Y2012
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
GROUP BY p.ProductCategory;

-- 3. Quarterly pivot.
--    -> 2009 Q1 is the standout quarter (1,198,204) — it contains the record
--       day found in worksheet 02 (subqueries) Q4 (2009-03-21).
SELECT YEAR(OrderDate) AS OrderYear,
       ROUND(SUM(CASE WHEN QUARTER(OrderDate) = 1 THEN Sales ELSE 0 END), 0) AS Q1,
       ROUND(SUM(CASE WHEN QUARTER(OrderDate) = 2 THEN Sales ELSE 0 END), 0) AS Q2,
       ROUND(SUM(CASE WHEN QUARTER(OrderDate) = 3 THEN Sales ELSE 0 END), 0) AS Q3,
       ROUND(SUM(CASE WHEN QUARTER(OrderDate) = 4 THEN Sales ELSE 0 END), 0) AS Q4
FROM orders
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;

-- 4. Profitable vs loss-making lines per category.
--    -> Office Supplies 2134 profitable / 2448 loss-making  <-- the answer
--       Technology 1102 / 800 | Furniture 754 / 822
--    Office Supplies loses money on more lines than it makes it on. Note this
--    does NOT contradict worksheet 02 of the afternoon class (aggregates) Q6, where the loss-making SUB-categories
--    were Tables and Bookcases (both Furniture): Office Supplies loses on many
--    small lines but still nets positive overall, while Furniture's losses are
--    concentrated in a few heavy, expensive-to-ship sub-categories. Counting
--    lines and summing profit tell different stories — report both.
SELECT p.ProductCategory,
       SUM(CASE WHEN o.Profit > 0  THEN 1 ELSE 0 END) AS ProfitableLines,
       SUM(CASE WHEN o.Profit <= 0 THEN 1 ELSE 0 END) AS LossMakingLines
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
GROUP BY p.ProductCategory;

-- 5. Discount bands.
--    -> none 726 lines / avg profit 250.11 | low 3747 / 217.18
--       mid  3583 / 136.96              | high    4 / -145.61
--    The trend is real and monotonic: the more we discount, the less we make.
--    BUT the 'high' bucket holds FOUR lines. An average over four rows is
--    noise, not evidence — quote the count beside any average, or someone
--    will build a pricing policy on it.
SELECT CASE WHEN Discount = 0     THEN 'none'
            WHEN Discount <= 0.05 THEN 'low'
            WHEN Discount <= 0.15 THEN 'mid'
            ELSE 'high'
       END                    AS DiscountBand,
       COUNT(*)               AS OrderLines,
       ROUND(AVG(Profit), 2)  AS AvgProfit
FROM orders
GROUP BY DiscountBand
ORDER BY AvgProfit DESC;

-- 6. CASE in ORDER BY — business order, not alphabetical.
--    -> Critical 1542, High 1695, Medium 1569, Low 1647, Not Specified 1607.
--    CASE returns a value, so it works anywhere a value is allowed: SELECT,
--    WHERE, ORDER BY, even inside aggregates (which is exactly the pivot).
SELECT OrderPriority, COUNT(*) AS OrderLines
FROM orders
GROUP BY OrderPriority
ORDER BY CASE OrderPriority
             WHEN 'Critical' THEN 1
             WHEN 'High'     THEN 2
             WHEN 'Medium'   THEN 3
             WHEN 'Low'      THEN 4
             ELSE 5
         END;

-- 7. Return rate by region.
--    -> Ontario 225/1741 = 12.9% | West 187/1921 = 9.7% |
--       Prarie 185/1640 = 11.3% | Atlantic 96/1038 = 9.2% …
SELECT c.Region,
       COUNT(*) AS OrderLines,
       SUM(CASE WHEN r.OrderID IS NOT NULL THEN 1 ELSE 0 END) AS ReturnedLines,
       ROUND(SUM(CASE WHEN r.OrderID IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS ReturnRatePct
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
LEFT JOIN returns r ON o.OrderID = r.OrderID
GROUP BY c.Region
ORDER BY ReturnRatePct DESC;

-- 8. Two-dimension pivot: segment × category.
--    -> Corporate is the largest segment in every category
--       (Tech 2,135,875 | Furniture 1,595,682 | Office 1,338,391).
SELECT c.CustomerSegment,
       ROUND(SUM(CASE WHEN p.ProductCategory = 'Technology'      THEN o.Sales ELSE 0 END), 0) AS Technology,
       ROUND(SUM(CASE WHEN p.ProductCategory = 'Furniture'       THEN o.Sales ELSE 0 END), 0) AS Furniture,
       ROUND(SUM(CASE WHEN p.ProductCategory = 'Office Supplies' THEN o.Sales ELSE 0 END), 0) AS OfficeSupplies
FROM orders o
JOIN products p   ON o.ProductID  = p.ProductID
JOIN customers c  ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerSegment;

-- 9. Share of sales from returned orders, per year.
--    -> 2009 12.1% | 2010 11.4% | 2011 7.9% | 2012 12.0%
--    THE INTEGER-DIVISION TRAP: in many databases `SUM(int)/SUM(int)` does
--    integer division and silently yields 0. Sales here is DECIMAL so the
--    division is exact — but multiplying by 100.0 (or casting) before
--    dividing is the habit that survives a change of column type or engine.
SELECT YEAR(o.OrderDate) AS OrderYear,
       ROUND(SUM(CASE WHEN r.OrderID IS NOT NULL THEN o.Sales ELSE 0 END)
             / SUM(o.Sales) * 100, 1) AS ReturnedSalesPct
FROM orders o
LEFT JOIN returns r ON o.OrderID = r.OrderID
GROUP BY YEAR(o.OrderDate)
ORDER BY OrderYear;
