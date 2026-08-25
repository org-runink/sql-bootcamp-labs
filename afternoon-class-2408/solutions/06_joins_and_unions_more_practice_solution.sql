-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 06 SOLUTIONS: joins and set operators   (L07)
-- ==========================================================================
-- All results below were produced against the seeded superstore database.
-- ==========================================================================

USE superstore;

-- 1. Order detail with product attributes (INNER JOIN).
--    An INNER JOIN is right here: every order line has a product, and a line
--    with no product would be a data error we WANT to drop.
SELECT o.OrderID, o.OrderDate, p.ProductName,
       p.ProductCategory, p.ProductSubCategory,
       ROUND(o.Sales, 2) AS Sales
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
ORDER BY o.OrderDate
LIMIT 10;

-- 2. Return rate by region.
--    -> Ontario 225/1741 | West 187/1921 | Prarie 185/1640 | Atlantic 96/1038 …
--    The LEFT JOIN matters: `returns` holds only returned orders, so an INNER
--    JOIN would drop every non-returned line and the denominator would become
--    "returned lines" — making the rate 100% everywhere. Classic mistake.
SELECT c.Region,
       COUNT(*) AS OrderLines,
       SUM(CASE WHEN r.OrderID IS NOT NULL THEN 1 ELSE 0 END) AS ReturnedLines,
       ROUND(SUM(CASE WHEN r.OrderID IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS ReturnRatePct
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
LEFT JOIN returns r ON o.OrderID = r.OrderID
GROUP BY c.Region
ORDER BY ReturnedLines DESC;

-- 3. Anti-join.
--    -> 20 customers have never placed an order.
SELECT c.CustomerID, c.CustomerName, c.Province
FROM customers c
LEFT JOIN orders o ON c.CustomerID = o.CustomerID
WHERE o.CustomerID IS NULL
ORDER BY c.CustomerID;

--    And products never ordered:
--    -> ZERO rows. Every product in the catalogue has been sold at least once.
--    An empty anti-join is a RESULT, not a failed query — it proves a
--    property of the data. Always sanity-check that the join key is right
--    before concluding "none": an empty set from a typo'd ON clause looks
--    identical to an empty set from a real absence.
SELECT p.ProductID, p.ProductName
FROM products p
LEFT JOIN orders o ON p.ProductID = o.ProductID
WHERE o.ProductID IS NULL;

-- 4. FULL OUTER JOIN.
--    This is a SYNTAX ERROR in MySQL — there is no FULL OUTER JOIN:
--        SELECT … FROM orders o FULL OUTER JOIN returns r ON …;
--        ERROR 1064 (42000): You have an error in your SQL syntax …
--    The portable emulation is LEFT ∪ RIGHT:
SELECT o.OrderID AS OrderKey, r.OrderID AS ReturnKey, r.Status
FROM orders o
LEFT JOIN returns r ON o.OrderID = r.OrderID
UNION
SELECT o.OrderID, r.OrderID, r.Status
FROM orders o
RIGHT JOIN returns r ON o.OrderID = r.OrderID;

--    HOW MANY ROWS DOES FULL ADD HERE? -> ZERO. Both sides return 5361 rows.
--    Why: FULL only differs from LEFT when the RIGHT table has rows with no
--    match on the left — here, returns referencing a non-existent order.
--    This database has none:
SELECT COUNT(*) AS OrphanReturns          -- -> 0
FROM returns r
LEFT JOIN orders o ON r.OrderID = o.OrderID
WHERE o.OrderID IS NULL;
--    That is not luck. The source returns.csv DID contain 14 rows whose
--    OrderID matched no order; they were dropped when the data was loaded
--    (see the header of db-init/04_superstore_returns.sql). So on THIS data
--    LEFT and FULL agree — and the lesson is that "which join do I need"
--    depends on the data's referential integrity, not on preference.

-- 5. Year-over-year revenue (self join on a derived table).
--    -> 2010: 3,177,019.95 (-19.2%) | 2011: 3,107,206.26 (-2.2%)
--       2012: 3,356,203.19 (+8.0%)
--    2009 has no row: there is no prior year to join to, and an INNER JOIN
--    correctly drops it rather than inventing a 0% baseline.
SELECT a.OrderYear,
       ROUND(a.Revenue, 2) AS Revenue,
       ROUND(b.Revenue, 2) AS PrevYearRevenue,
       ROUND((a.Revenue - b.Revenue) / b.Revenue * 100, 1) AS GrowthPct
FROM      (SELECT YEAR(OrderDate) AS OrderYear, SUM(Sales) AS Revenue
           FROM orders GROUP BY YEAR(OrderDate)) a
JOIN      (SELECT YEAR(OrderDate) AS OrderYear, SUM(Sales) AS Revenue
           FROM orders GROUP BY YEAR(OrderDate)) b
       ON a.OrderYear = b.OrderYear + 1
ORDER BY a.OrderYear;

-- 6. Customers ordering on two consecutive days.
--    -> 10 customers.
SELECT COUNT(DISTINCT a.CustomerID) AS CustomersWithConsecutiveDays
FROM orders a
JOIN orders b
  ON a.CustomerID = b.CustomerID
 AND b.OrderDate = a.OrderDate + INTERVAL 1 DAY;

-- 7. UNION — customers at Low OR Critical priority.
--    -> 1247 distinct customer IDs.
SELECT CustomerID FROM orders WHERE OrderPriority = 'Low'
UNION
SELECT CustomerID FROM orders WHERE OrderPriority = 'Critical';

-- 8. UNION vs UNION ALL.
--    -> UNION ALL: 3189 rows.  UNION: 1247 rows.
--    UNION ALL concatenates and keeps every row, duplicates included — here
--    one row per matching ORDER LINE. UNION additionally removes duplicates,
--    leaving one row per customer.
--    UNION ALL is FASTER: de-duplicating means sorting or hashing the whole
--    result. Use UNION ALL whenever you know the inputs are disjoint, or when
--    duplicates are meaningful. Reach for UNION only when you actually want
--    distinct rows — you are paying for it.
SELECT COUNT(*) AS WithUnionAll FROM (
  SELECT CustomerID FROM orders WHERE OrderPriority = 'Low'
  UNION ALL
  SELECT CustomerID FROM orders WHERE OrderPriority = 'Critical'
) t;

SELECT COUNT(*) AS WithUnion FROM (
  SELECT CustomerID FROM orders WHERE OrderPriority = 'Low'
  UNION
  SELECT CustomerID FROM orders WHERE OrderPriority = 'Critical'
) t;

-- 9. INTERSECT — products over $1000 in BOTH Ontario and West during 2012.
--    -> 34 products.
--    Each branch aggregates independently and HAVING filters each side; the
--    INTERSECT then keeps only the IDs present in both result sets.
SELECT o.ProductID
FROM orders o JOIN customers c ON o.CustomerID = c.CustomerID
WHERE YEAR(o.OrderDate) = 2012 AND c.Region = 'Ontario'
GROUP BY o.ProductID
HAVING SUM(o.Sales) > 1000
INTERSECT
SELECT o.ProductID
FROM orders o JOIN customers c ON o.CustomerID = c.CustomerID
WHERE YEAR(o.OrderDate) = 2012 AND c.Region = 'West'
GROUP BY o.ProductID
HAVING SUM(o.Sales) > 1000
LIMIT 10;

-- 10. EXCEPT — sold in 2011 but not at all in 2012.
--     -> 211 products.
--     EXCEPT keeps the distinct rows of the left query that do not appear in
--     the right one — the set-operator spelling of a NOT IN anti-join.
SELECT DISTINCT ProductID FROM orders WHERE YEAR(OrderDate) = 2011
EXCEPT
SELECT DISTINCT ProductID FROM orders WHERE YEAR(OrderDate) = 2012
LIMIT 10;
