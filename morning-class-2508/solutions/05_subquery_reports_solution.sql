-- ==========================================================================
-- Morning class 25/08 — Worksheet 05 SOLUTIONS: building reports with subqueries
-- ==========================================================================
-- Every query below was executed against this lab's data; quoted numbers
-- are real.
-- ==========================================================================

USE superstore;

-- ==========================================================================
-- PART A — Scalar subqueries: adding context to every row
-- ==========================================================================

-- 1. Regional share of company revenue.
SELECT c.Region,
       ROUND(SUM(o.Sales), 0) AS revenue,
       ROUND(100 * SUM(o.Sales) / (SELECT SUM(Sales) FROM orders), 1) AS pct_of_total
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.Region
ORDER BY revenue DESC;
--    -> West 3312073 24.4 | Ontario 2731470 20.1 | Prarie 2619153 19.3 |
--       Atlantic 1834002 13.5 | Quebec 1328624 9.8 | Yukon 860655 6.3 |
--       Northwest Territories 781695 5.8 | Nunavut 103138 0.8
--
--    `(SELECT SUM(Sales) FROM orders)` is a SCALAR subquery: it returns
--    exactly one row and one column, so SQL can use it anywhere a single
--    value is allowed. It is UNCORRELATED — it mentions nothing from the
--    outer query — so the server evaluates it ONCE and reuses the result for
--    all eight rows.
--    If a "scalar" subquery ever returns two rows you get
--    ERROR 1242: Subquery returns more than 1 row. That is usually a missing
--    GROUP BY or a forgotten filter.

-- 2. Adding a comparison against the average region.
SELECT c.Region,
       ROUND(SUM(o.Sales), 0) AS revenue,
       ROUND(SUM(o.Sales) - (
           SELECT AVG(region_total) FROM (
               SELECT SUM(o2.Sales) AS region_total
               FROM orders o2
               JOIN customers c2 ON c2.CustomerID = o2.CustomerID
               GROUP BY c2.Region
           ) AS per_region
       ), 0) AS vs_average_region
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.Region
ORDER BY revenue DESC;
--    -> West +1615722 | Ontario +1035119 | Prarie +922802 | Atlantic +137651 |
--       Quebec -367727 | Yukon -835696 | Northwest Territories -914656 |
--       Nunavut -1593213
--
--    WHY AVG(Sales) IS WRONG. AVG(Sales) is the average ORDER LINE, about
--    1,684 — a number about individual lines, not about regions. "Average
--    revenue per region" means: total each region first, then average those
--    eight totals (1,696,351). Two levels of aggregation, so you need a
--    derived table; there is no way to write an aggregate of an aggregate in
--    one step.
--    Note the eight deltas sum to zero, which is a free sanity check.

-- 3. Every product next to the catalogue's best seller.
SELECT p.ProductName,
       p.ProductCategory,
       ROUND(SUM(o.Sales), 0) AS revenue,
       (SELECT ROUND(MAX(total), 0) FROM (
            SELECT SUM(Sales) AS total FROM orders GROUP BY ProductID
        ) AS t) AS best_product_revenue
FROM orders o
JOIN products p ON p.ProductID = o.ProductID
GROUP BY p.ProductID, p.ProductName, p.ProductCategory
ORDER BY revenue DESC
LIMIT 10;
--    -> the top row's revenue equals best_product_revenue, by definition.
--
--    UNCORRELATED. You can tell by looking: the subquery mentions no table
--    or alias from the outer query — you could copy it into a new window and
--    run it standalone. That is the test.
--    Because it is independent, it is evaluated ONCE for the whole
--    statement, not once per product. A CORRELATED subquery (question 9)
--    references the outer row and is conceptually re-run for each one, which
--    is why it can be dramatically more expensive.

-- ==========================================================================
-- PART B — Derived tables: reporting on a summary
-- ==========================================================================

-- 4. Customers above 30,000 lifetime revenue.  -> 62 customers
SELECT customer_name, province, orders_made, ROUND(revenue, 0) AS revenue
FROM (
    SELECT c.CustomerID,
           c.CustomerName AS customer_name,
           c.Province     AS province,
           COUNT(DISTINCT o.OrderID) AS orders_made,
           SUM(o.Sales)   AS revenue
    FROM orders o
    JOIN customers c ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName, c.Province
) AS per_customer
WHERE revenue > 30000
ORDER BY revenue DESC;

--    The HAVING version — same result, less machinery:
SELECT c.CustomerName, c.Province,
       COUNT(DISTINCT o.OrderID) AS orders_made,
       ROUND(SUM(o.Sales), 0)    AS revenue
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.Province
HAVING SUM(o.Sales) > 30000
ORDER BY revenue DESC;
--
--    HAVING READS BETTER and should be your default — it says "filter the
--    groups" in one clause instead of wrapping the whole query.
--    WHEN ONLY THE DERIVED TABLE WORKS:
--      * you need to filter on a WINDOW function (HAVING runs before
--        windows are computed — see worksheet 06 Q5);
--      * you need to filter on an alias rather than repeat the expression
--        (MySQL tolerates `HAVING revenue > 30000`, but that is a MySQL
--        extension; standard SQL and other engines require you to repeat
--        SUM(o.Sales), and the derived table avoids the duplication);
--      * you need to aggregate the aggregate, as in question 2.

-- 5. Region report built from per-customer totals.
SELECT region,
       COUNT(*)                       AS customers,
       ROUND(SUM(revenue), 0)         AS revenue,
       ROUND(AVG(revenue), 0)         AS revenue_per_customer
FROM (
    SELECT c.Region AS region, c.CustomerID, SUM(o.Sales) AS revenue
    FROM orders o
    JOIN customers c ON c.CustomerID = o.CustomerID
    GROUP BY c.Region, c.CustomerID
) AS per_customer
GROUP BY region
ORDER BY revenue DESC;
--    -> West 381 customers 3312073 revenue 8693 per customer
--       Ontario 334 2731470 8178 | Prarie 313 2619153 8368 | ...
--
--    The revenue column matches a direct `GROUP BY c.Region` exactly,
--    because summing per-customer totals and summing all lines are the same
--    arithmetic. That agreement is the check: if it did NOT match, the inner
--    query would be joining or grouping at the wrong grain and inflating
--    rows.
--    COUNT(*) on the derived table counts CUSTOMERS, because the inner query
--    already produced one row per customer. In a direct GROUP BY you would
--    have to write COUNT(DISTINCT o.CustomerID) — the derived table makes
--    the grain explicit instead of relying on you to remember it.

-- 6. The same as a CTE.
WITH per_customer AS (
    SELECT c.Region AS region, c.CustomerID, SUM(o.Sales) AS revenue
    FROM orders o
    JOIN customers c ON c.CustomerID = o.CustomerID
    GROUP BY c.Region, c.CustomerID
)
SELECT region,
       COUNT(*)               AS customers,
       ROUND(SUM(revenue), 0) AS revenue,
       ROUND(AVG(revenue), 0) AS revenue_per_customer
FROM per_customer
GROUP BY region
ORDER BY revenue DESC;
--
--    WHAT THE CTE GIVES YOU: it can be referenced MORE THAN ONCE in the same
--    query, and a derived table cannot. If this report also needed, say, the
--    top customer per region, the CTE is written once and used twice; the
--    derived table would have to be copy-pasted — and then the two copies
--    can drift apart when someone edits only one.
--    It also reads top-to-bottom instead of inside-out, and it can be
--    RECURSIVE. See worksheet 02.

-- ==========================================================================
-- PART C — Subqueries as filters
-- ==========================================================================

-- 7. Customers who never ordered.  -> 20, all three ways.
SELECT c.CustomerID, c.CustomerName, c.Province
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.CustomerID = c.CustomerID);

SELECT c.CustomerID, c.CustomerName, c.Province
FROM customers c
WHERE c.CustomerID NOT IN (SELECT CustomerID FROM orders);

SELECT c.CustomerID, c.CustomerName, c.Province
FROM customers c
LEFT JOIN orders o ON o.CustomerID = c.CustomerID
WHERE o.CustomerID IS NULL;
--    -> All three return the same 20 rows. (1812 ordered + 20 = 1832.)
--
--    THE CHECK THAT MAKES NOT IN SAFE HERE:
SELECT COUNT(*) - COUNT(CustomerID) AS nulls_in_orders_customerid FROM orders;
--    -> 0
--
--    That zero is the whole justification. `x NOT IN (subquery)` returns NO
--    ROWS AT ALL if the subquery yields even one NULL, silently — so
--    "it returned 20 rows" proves nothing on its own; it would have returned
--    0 with no error. Because the column has no NULLs, NOT IN is safe here.
--    Rely on a NOT NULL constraint or an explicit check, never on the
--    current data looking fine. NOT EXISTS needs no such caveat, which is
--    why it is the better habit.
--
--    THE PRODUCTS VERSION RETURNS NOTHING — every product has been ordered.
--    An empty result and a broken query look identical, so verify the
--    opposite: `SELECT COUNT(DISTINCT ProductID) FROM orders` gives 1234,
--    which equals COUNT(*) FROM products. The zero is real.

-- 8. Ordered in 2012 but not in 2011.  -> 457 customers
SELECT c.CustomerName, c.Province
FROM customers c
WHERE EXISTS (
        SELECT 1 FROM orders o
        WHERE o.CustomerID = c.CustomerID AND YEAR(o.OrderDate) = 2012)
  AND NOT EXISTS (
        SELECT 1 FROM orders o
        WHERE o.CustomerID = c.CustomerID AND YEAR(o.OrderDate) = 2011)
ORDER BY c.CustomerName;
--
--    Both subqueries are CORRELATED — each references c.CustomerID from the
--    outer row. EXISTS stops at the first matching row it finds, which is
--    why `SELECT 1` is idiomatic: the select list is never evaluated, so
--    there is no point computing anything in it.
--    This shape — one EXISTS and one NOT EXISTS — is how you express set
--    difference when the two sets come from the same table under different
--    conditions. A self-join would need care to avoid duplicating rows.

-- 9. Products above their OWN category's average.  -> 295 products
SELECT COUNT(*) AS products_above_own_category_average
FROM (
    SELECT p.ProductID, p.ProductCategory, SUM(o.Sales) AS revenue
    FROM orders o
    JOIN products p ON p.ProductID = o.ProductID
    GROUP BY p.ProductID, p.ProductCategory
) AS t
WHERE t.revenue > (
    SELECT AVG(cat.revenue) FROM (
        SELECT p2.ProductCategory AS cat_name, p2.ProductID, SUM(o2.Sales) AS revenue
        FROM orders o2
        JOIN products p2 ON p2.ProductID = o2.ProductID
        GROUP BY p2.ProductCategory, p2.ProductID
    ) AS cat
    WHERE cat.cat_name = t.ProductCategory        -- <- the correlation
);
--    -> 295 of 1234 products
--
--    THIS ONE IS CORRELATED: the inner query filters on t.ProductCategory
--    from the outer row, so the threshold is different for each product
--    depending on which category it sits in. Remove that WHERE and you get
--    the overall average instead — a different, easier question with a
--    different answer.
--    A window function does this far more cheaply:
--        AVG(revenue) OVER (PARTITION BY ProductCategory)
--    computes all three category averages in ONE pass rather than
--    re-deriving them per row. Worksheet 06 covers it. Correlated
--    subqueries are the portable way; windows are the efficient way.

-- ==========================================================================
-- PART D — Subqueries in HAVING, and putting it together
-- ==========================================================================

-- 10. Provinces above the average province.  -> 7 provinces
SELECT Province, COUNT(*) AS customers
FROM customers
GROUP BY Province
HAVING COUNT(*) > (
    SELECT AVG(n) FROM (SELECT COUNT(*) AS n FROM customers GROUP BY Province) AS z
)
ORDER BY customers DESC;
--    -> Ontario 337 | British Columbia 239 | Quebec 210 | Nova Scotia 187 |
--       Manitoba 172 | Alberta 143 | Saskachewan 141
--
--    HAVING is evaluated after grouping, so it can compare a group's
--    aggregate against a value fetched from elsewhere. The inner derived
--    table is needed for the same reason as question 2 — the average of
--    counts is an aggregate over aggregates.
--    (Note `Saskachewan` is spelled that way in the source data. Do not
--    "fix" it in a query; a report that silently renames its inputs cannot
--    be reconciled against the system of record.)

-- 11. Products earning over 10,000, by category.
SELECT p.ProductCategory,
       COUNT(*) AS products_in_category,
       SUM(CASE WHEN sub.revenue > 10000 THEN 1 ELSE 0 END) AS over_10k,
       ROUND(100.0 * SUM(CASE WHEN sub.revenue > 10000 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_over_10k
FROM (
    SELECT ProductID, SUM(Sales) AS revenue FROM orders GROUP BY ProductID
) AS sub
JOIN products p ON p.ProductID = sub.ProductID
GROUP BY p.ProductCategory
ORDER BY pct_over_10k DESC;
--
--    Conditional aggregation (SUM of a CASE) counts a subset without a
--    second pass — the pattern from the afternoon's CASE WHEN worksheets.
--    Note the 100.0 rather than 100: integer division would floor the ratio
--    to 0 before ROUND ever saw it.

-- 12. The full 2012 regional report.
WITH regional AS (
    SELECT c.Region                        AS region,
           SUM(o.Sales)                    AS revenue,
           COUNT(DISTINCT o.CustomerID)    AS customers
    FROM orders o
    JOIN customers c ON c.CustomerID = o.CustomerID
    WHERE YEAR(o.OrderDate) = 2012
    GROUP BY c.Region
)
SELECT r.region,
       ROUND(r.revenue, 0)                                   AS revenue,
       ROUND(100 * r.revenue / (SELECT SUM(revenue) FROM regional), 1) AS pct_of_2012,
       r.customers,
       ROUND(r.revenue / r.customers, 0)                     AS revenue_per_customer,
       (SELECT p.ProductName
          FROM orders o2
          JOIN products p  ON p.ProductID = o2.ProductID
          JOIN customers c2 ON c2.CustomerID = o2.CustomerID
         WHERE c2.Region = r.region AND YEAR(o2.OrderDate) = 2012
         GROUP BY p.ProductID, p.ProductName
         ORDER BY SUM(o2.Sales) DESC
         LIMIT 1)                                            AS best_selling_product,
       CASE WHEN r.revenue > (SELECT AVG(revenue) FROM regional)
            THEN 'above' ELSE 'below' END                    AS vs_average_region
FROM regional r
ORDER BY revenue DESC;
--
--    FIVE DIFFERENT TECHNIQUES IN ONE STATEMENT:
--      - a CTE to compute the per-region base once and reuse it three times
--        (a derived table could not be referenced repeatedly like this);
--      - an uncorrelated scalar subquery for the 2012 grand total;
--      - plain arithmetic for revenue per customer;
--      - a CORRELATED subquery with ORDER BY ... LIMIT 1 for the best
--        product — it filters on r.region, so it runs per region;
--      - CASE WHEN against another scalar subquery for the label.
--
--    THE HONEST CAVEAT on best_selling_product: LIMIT 1 picks ONE row even
--    when two products tie for the top. It will not tell you a tie happened.
--    RANK() OVER (PARTITION BY region ORDER BY SUM(Sales) DESC) would show
--    both — see worksheet 06 Q4.
--    BUILD REPORTS LIKE THIS ONE COLUMN AT A TIME. Every column above is
--    individually checkable against a two-line query; assembled in one go,
--    a single wrong join silently corrupts every figure at once.
