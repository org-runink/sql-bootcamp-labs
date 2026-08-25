-- ==========================================================================
-- Morning class 25/08 — Worksheet 06 SOLUTIONS: window functions
-- ==========================================================================
-- Every query below was executed against this lab's data; quoted numbers
-- are real.
-- ==========================================================================

USE superstore;

-- ==========================================================================
-- PART A — Aggregating without collapsing
-- ==========================================================================

-- 1a. GROUP BY — one row per region (8 rows).
SELECT Region, COUNT(*) AS customers
FROM customers
GROUP BY Region
ORDER BY customers DESC;

-- 1b. Window — every customer row kept, with their region's count attached.
SELECT Region, CustomerName,
       COUNT(*) OVER (PARTITION BY Region) AS customers_in_region
FROM customers
ORDER BY Region, CustomerName
LIMIT 10;
--
--    THE DIFFERENCE. (a) returns 8 rows: the detail is GONE, replaced by one
--    summary row per group. (b) returns all 1,832 rows: every customer is
--    still there, each carrying their group's total as an extra column.
--
--    GROUP BY when the summary IS the answer — a report of totals by region.
--    OVER() when you need the detail AND the context together: "show me each
--    customer next to their region's size", "flag orders above their
--    category's average". Anything phrased as "compared to its group" wants
--    a window function, because the comparison needs both numbers on one row.

-- 2. Region share of total, with no subquery.
SELECT c.Region,
       ROUND(SUM(o.Sales), 0)                                       AS revenue,
       ROUND(100 * SUM(o.Sales) / SUM(SUM(o.Sales)) OVER (), 1)     AS pct_of_total
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.Region
ORDER BY revenue DESC;
--    -> West 3312073 24.4 | Ontario 2731470 20.1 | Prarie 2619153 19.3 |
--       Atlantic 1834002 13.5 | Quebec 1328624 9.8 | Yukon 860655 6.3 |
--       Northwest Territories 781695 5.8 | Nunavut 103138 0.8
--
--    READING `SUM(SUM(Sales)) OVER ()`: the inner SUM(Sales) is the ordinary
--    GROUP BY aggregate, producing one value per region. The outer SUM(...)
--    OVER () is a window over THOSE eight rows, with an empty OVER() meaning
--    "the whole result set" — so it totals all regions.
--    Window functions run AFTER GROUP BY, which is exactly why this works and
--    why you cannot reference a window function in HAVING.
--    The afternoon's nested-subquery version computed the same total by
--    re-scanning the table; this does it in one pass over the grouped rows.

-- 3. Each line's share of its own order.
SELECT OrderID,
       Sales,
       SUM(Sales) OVER (PARTITION BY OrderID) AS order_total
FROM orders
ORDER BY OrderID
LIMIT 10;
--
--    WHY GROUP BY CANNOT DO THIS: GROUP BY OrderID would return one row per
--    order, and `Sales` would no longer be a single value — there are several
--    lines per order, so the server has no defensible value to show. The
--    window keeps all 8,060 rows and computes the total per partition
--    alongside each one. Same arithmetic, different SHAPE of answer.

-- ==========================================================================
-- PART B — Ranking, and what happens on ties
-- ==========================================================================

-- 4. Three ranking functions on the same data.
SELECT c.CustomerName,
       COUNT(DISTINCT o.OrderID) AS orders_made,
       ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT o.OrderID) DESC) AS row_number_,
       RANK()       OVER (ORDER BY COUNT(DISTINCT o.OrderID) DESC) AS rank_,
       DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT o.OrderID) DESC) AS dense_rank_
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY orders_made DESC
LIMIT 8;
--    -> Michael Dominguez 16 | 1 | 1 | 1
--       Patrick Jones     16 | 2 | 1 | 1
--       Sally Hughsby     15 | 3 | 3 | 2
--       Jonathan Doherty  14 | 4 | 4 | 3
--       Keith Dawkins     13 | 5 | 5 | 4
--       Edward Nazzal     13 | 6 | 5 | 4
--       Muhammed Yedwab   12 | 7 | 7 | 5
--       Jim Epp           12 | 8 | 7 | 5
--
--    Michael and Patrick are TIED on 16 orders. Watch what each does:
--
--      ROW_NUMBER  1, 2  — never ties. It invents an order between equals,
--                  and WHICH of them gets 1 is arbitrary and can change
--                  between runs.
--      RANK        1, 1, then 3 — ties share a rank, and the next value
--                  SKIPS. "Joint first, so nobody is second." Two people at
--                  16 means the 15 is third.
--      DENSE_RANK  1, 1, then 2 — ties share a rank, and the next value does
--                  NOT skip. Ranks stay contiguous.
--
--    WHEN TO USE WHICH:
--      ROW_NUMBER  — deduplication ("keep one row per customer"), or
--                    pagination, where you need exactly one row per number
--                    and do not care which.
--      RANK        — competition scoring, where joint-first genuinely means
--                    there is no second place.
--      DENSE_RANK  — "top 3 price tiers" or any banding, where you want three
--                    DISTINCT VALUES rather than three rows.
--    The trap: using ROW_NUMBER for a "top 10" report silently drops a
--    genuinely tied 10th place, and nothing tells you it happened.

-- 5. Top 2 customers by revenue in each region.
WITH cust AS (
    SELECT c.Region, c.CustomerID, c.CustomerName, SUM(o.Sales) AS revenue
    FROM orders o
    JOIN customers c ON c.CustomerID = o.CustomerID
    GROUP BY c.Region, c.CustomerID, c.CustomerName
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Region ORDER BY revenue DESC) AS rn
    FROM cust
)
SELECT Region, CustomerName, ROUND(revenue, 0) AS revenue, rn
FROM ranked
WHERE rn <= 2
ORDER BY Region, rn;
--    -> Atlantic              | Emily Phan      | 97011 | 1
--       Atlantic              | Liz MacKendrick | 67285 | 2
--       Northwest Territories | Grant Carroll   | 54369 | 1
--       Northwest Territories | Sylvia Foulston | 48176 | 2
--       Nunavut               | Edward Hooks    | 14224 | 1
--       Nunavut               | Barry Weirich   | 10373 | 2
--       ... 16 rows (2 per region x 8 regions)
--
--    WHY YOU CANNOT WRITE `WHERE rn <= 2` DIRECTLY: SQL evaluates WHERE
--    BEFORE window functions. At the moment WHERE runs, `rn` does not exist
--    yet — the window has not been computed. The clause order is roughly
--        FROM -> WHERE -> GROUP BY -> HAVING -> WINDOW -> SELECT -> ORDER BY
--    so anything that filters ON a window function must happen in an OUTER
--    query: a CTE (as here) or a derived table.
--    This is the single most common window-function error, and the message
--    ("Window function is allowed only in SELECT and ORDER BY") does explain
--    it — but only if you already know the clause order.

-- 6. Top quartile of sub-categories by revenue.
WITH per_sub AS (
    SELECT p.ProductSubCategory, SUM(o.Sales) AS revenue
    FROM orders o
    JOIN products p ON p.ProductID = o.ProductID
    GROUP BY p.ProductSubCategory
),
bucketed AS (
    SELECT *, NTILE(4) OVER (ORDER BY revenue DESC) AS quartile
    FROM per_sub
)
SELECT ProductSubCategory, ROUND(revenue, 0) AS revenue
FROM bucketed
WHERE quartile = 1
ORDER BY revenue DESC;
--    -> Office Machines 2123674 | Telephones and Communication 1842197 |
--       Chairs & Chairmats 1761837 | Storage & Organization 1070183 |
--       Tables 1043755
--
--    NTILE(4) splits the ordered rows into 4 groups as evenly as it can.
--    With 17 sub-categories that is 5/4/4/4 — NTILE distributes the
--    remainder to the EARLIEST buckets, so quartile 1 has five members, not
--    four. NTILE divides by ROW COUNT, not by value: it does not care that
--    the top row earns twice the fifth. If you need "everything above the
--    75th percentile by value", that is a different question and NTILE is
--    the wrong tool.

-- ==========================================================================
-- PART C — Looking at other rows: ORDER BY and frames
-- ==========================================================================

-- 7-9. Monthly 2012 revenue: running total, month-over-month, moving average.
WITH monthly AS (
    SELECT MONTH(OrderDate) AS mo, SUM(Sales) AS revenue
    FROM orders
    WHERE YEAR(OrderDate) = 2012
    GROUP BY MONTH(OrderDate)
)
SELECT mo,
       ROUND(revenue, 0)                                          AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY mo), 0)                  AS running_total,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY mo), 0)        AS vs_prev_month,
       ROUND(AVG(revenue) OVER (ORDER BY mo
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0)        AS moving_avg_3
FROM monthly
ORDER BY mo;
--    -> mo 1 | 290891 |  290891 |   NULL | 290891
--       mo 2 | 216233 |  507124 | -74658 | 253562
--       mo 3 | 321327 |  828450 | 105094 | 276150
--       mo 4 | 258953 | 1087403 | -62374 | 265504
--       mo 5 | 369028 | 1456431 | 110075 | 316436
--       ... 12 rows
--
--    Q7 — RUNNING TOTAL. Adding ORDER BY inside OVER() silently changes the
--    default frame. With no ORDER BY, the frame is the ENTIRE partition, so
--    SUM() gives the same grand total on every row. With ORDER BY, the
--    default becomes RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW —
--    everything up to and including this row — which is a running total.
--    That default is worth memorising; it is the difference between a
--    running total and a constant, and the syntax barely changes.
--
--    Q8 — JANUARY IS NULL, AND THAT IS CORRECT. LAG() looks one row back.
--    There is no row before January, so the answer is "unknown", which is
--    what NULL means. Writing COALESCE(..., 0) would assert that January
--    grew by exactly zero from a December that is not in the result — a
--    claim the data does not support. If you need a number for a chart,
--    that is a presentation decision; make it in the presentation layer, or
--    at least knowingly. LAG(revenue, 1, 0) supplies a default if you really
--    want one.
--
--    Q9 — THE FIRST TWO MOVING-AVERAGE VALUES ARE PARTIAL. The frame asks
--    for two rows back plus this one, but January has none behind it, so its
--    "3-month average" is just January (290891). February averages two
--    months (253562). Only from March is it a true 3-month figure.
--    The window does NOT return NULL for an incomplete frame — it quietly
--    averages what it has. On a chart the first points are therefore noisier
--    than the rest, and nothing in the output says so. Real reports usually
--    blank them deliberately.

-- 10. Each region's rank among regions, month by month, 2012.
WITH region_month AS (
    SELECT MONTH(o.OrderDate) AS mo, c.Region, SUM(o.Sales) AS revenue
    FROM orders o
    JOIN customers c ON c.CustomerID = o.CustomerID
    WHERE YEAR(o.OrderDate) = 2012
    GROUP BY MONTH(o.OrderDate), c.Region
)
SELECT mo, Region, ROUND(revenue, 0) AS revenue,
       RANK() OVER (PARTITION BY mo ORDER BY revenue DESC) AS rank_in_month
FROM region_month
ORDER BY mo, rank_in_month;
--
--    PARTITION BY mo restarts the ranking for every month — that is the whole
--    idea: the partition defines WHERE the numbering resets. Drop it and you
--    get one ranking across all 96 region-months, which answers a completely
--    different question.
--    Note this needs GROUP BY and a window together: the GROUP BY builds one
--    row per region-month, then the window ranks within each month. They are
--    not alternatives; windows operate on whatever rows the query produced.
