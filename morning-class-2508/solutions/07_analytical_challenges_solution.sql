-- ==========================================================================
-- Morning class 25/08 — Worksheet 07 SOLUTIONS: combined analytical challenges
-- ==========================================================================
-- Every query below was executed against this lab's data; quoted numbers
-- are real. Several results are NOT what you would expect, and the written
-- answers matter as much as the SQL.
-- ==========================================================================

USE superstore;

-- ==========================================================================
-- CHALLENGE 1 — The monthly growth report
-- ==========================================================================

WITH monthly AS (
    SELECT MONTH(OrderDate) AS mo, SUM(Sales) AS revenue
    FROM orders WHERE YEAR(OrderDate) = 2012
    GROUP BY MONTH(OrderDate)
)
SELECT mo,
       ROUND(revenue, 0)                                     AS revenue,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY mo), 0)    AS change_abs,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY mo))
             / LAG(revenue) OVER (ORDER BY mo), 1)            AS change_pct
FROM monthly
ORDER BY mo;
--    -> mo 1 | 290891 |   NULL |  NULL
--       mo 2 | 216233 | -74658 | -25.7
--       mo 3 | 321327 | 105094 | +48.6
--       mo 4 | 258953 | -62374 | -19.4
--       mo 5 | 369028 | 110075 | +42.5
--       ... 12 rows
--
--    1b. WHAT JANUARY SHOULD SHOW: empty, not zero. There is no December
--    2011 in this frame, so the change is UNKNOWN, and NULL is the correct
--    representation of unknown. Writing 0 asserts "no change since a month
--    we did not measure", which is a claim the data cannot support — and it
--    is worse than useless in a chart, where a 0% bar looks like a real
--    measurement of flatness.
--    If the report must show something, show a dash or "n/a". That is a
--    presentation decision, and it belongs in the presentation layer.
--
--    1c. WORST DECLINE: February, -25.7%. (Sort by change_pct and NULL sorts
--    first in MySQL — January is not the worst month, it is the unknown one.
--    That alone catches people.)
--    IS IT REAL? Barely. Look at the neighbours: February -25.7% then March
--    +48.6%, April -19.4% then May +42.5%. The series oscillates violently
--    every month. With ~114 orders a month, a handful of large orders moves
--    the total by tens of percent, so month-over-month change here is mostly
--    NOISE, not trend. February is also the shortest month — about 10% fewer
--    trading days than January before anything else happens.
--    A percentage change is only meaningful when the denominator is stable
--    and the sample is large. Reporting "sales fell 26% in February" from
--    this data would be indefensible; the honest treatment is a moving
--    average (worksheet 06 Q9) or year-on-year comparison.

-- ==========================================================================
-- CHALLENGE 2 — Who actually pays the bills
-- ==========================================================================

WITH per_customer AS (
    SELECT CustomerID, COUNT(DISTINCT OrderID) AS orders_made, SUM(Sales) AS revenue
    FROM orders GROUP BY CustomerID
)
SELECT CASE WHEN orders_made = 1 THEN 'one-time' ELSE 'repeat' END AS customer_type,
       COUNT(*)                                                     AS customers,
       ROUND(SUM(revenue), 0)                                       AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)     AS pct_of_revenue
FROM per_customer
GROUP BY customer_type;
--    -> one-time |  576 |  1377028 | 10.1
--       repeat   | 1236 | 12193782 | 89.9
--
--    2b. THE OBVIOUS READING: 68% of customers are repeat buyers and they
--    produce 90% of revenue, so retention is where the money is — spend on
--    keeping existing customers rather than acquiring new ones. Acquisition
--    is famously more expensive per customer, which reinforces it.
--
--    THE OPPOSITE CASE, and it is strong:
--      * THIS IS ARITHMETIC, NOT INSIGHT. A "repeat" customer has by
--        definition placed at least two orders, so of course they have spent
--        more. The comparison is rigged: you are comparing >=2 orders against
--        exactly 1. It would hold on ANY dataset, including one where
--        retention efforts do nothing at all.
--      * SURVIVORSHIP AND TIME. Someone who first ordered in December 2012
--        had no opportunity to become a repeat customer. They are counted as
--        one-time because the data ends, not because they were not retained.
--      * DIRECTION OF CAUSATION. Repeat customers are not valuable because
--        they repeated; they repeated because they were the kind of customer
--        who would. Spending to convert one-timers assumes the relationship
--        runs the other way, which this data cannot establish.
--      * EVERY REPEAT CUSTOMER WAS ONCE A NEW ONE. Cutting acquisition to
--        fund retention eventually starves the very pool being retained.
--    The defensible version of this analysis is a COHORT study — challenge 6
--    — which at least holds the time window constant.

-- ==========================================================================
-- CHALLENGE 3 — The Pareto question
-- ==========================================================================

WITH product_revenue AS (
    SELECT ProductID, SUM(Sales) AS revenue FROM orders GROUP BY ProductID
),
cumulative AS (
    SELECT ProductID, revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC) AS running_revenue,
           SUM(revenue) OVER ()                      AS total_revenue
    FROM product_revenue
)
SELECT COUNT(*)                                                  AS products_to_reach_80pct,
       (SELECT COUNT(*) FROM product_revenue)                    AS products_in_catalogue,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM product_revenue), 1) AS pct_of_catalogue
FROM cumulative
WHERE running_revenue - revenue < 0.8 * total_revenue;
--    -> 292 | 1234 | 23.7
--
--    3c. THE CLAIM IS ESSENTIALLY TRUE HERE: 23.7% of products generate 80%
--    of revenue. Close enough to "20/80" that the rule of thumb is a fair
--    description, though it is 24/80 rather than 20/80 and you should quote
--    the real figure.
--
--    NOTE THE FILTER: `running_revenue - revenue < 0.8 * total` rather than
--    `running_revenue <= 0.8 * total`. Subtracting the row's own revenue
--    asks "was the threshold still unmet BEFORE this product?", which
--    includes the product that CROSSES 80% rather than stopping just short.
--    Without it you are off by one — a small thing that changes the headline
--    number, and the kind of boundary decision worth stating explicitly in
--    any report rather than leaving the reader to guess.
--
--    WHAT PARETO DOES NOT LICENSE: "so we can drop the other 76% of the
--    catalogue." Long-tail products may be what brings customers in, may be
--    bought alongside the top sellers, and dropping them changes the
--    behaviour of the people who bought them. This analysis measures
--    concentration, not dispensability.

-- ==========================================================================
-- CHALLENGE 4 — Does discounting work?
-- ==========================================================================

SELECT CASE WHEN Discount = 0     THEN 'none'
            WHEN Discount <= 0.03 THEN 'low (<=3%)'
            WHEN Discount <= 0.06 THEN 'mid (<=6%)'
            ELSE                       'high (>6%)' END AS discount_band,
       COUNT(*)                                  AS line_count,
       ROUND(AVG(Discount), 3)                   AS avg_discount,
       ROUND(SUM(Sales), 0)                      AS sales,
       ROUND(SUM(Profit), 0)                     AS profit,
       ROUND(100 * SUM(Profit) / SUM(Sales), 1)  AS margin_pct
FROM orders
GROUP BY discount_band
ORDER BY avg_discount;
--    -> none       |  726 | 0.000 | 1393703 | 181576 | 13.0
--       low (<=3%) | 2257 | 0.020 | 3756099 | 568551 | 15.1
--       mid (<=6%) | 2193 | 0.050 | 3656942 | 318420 |  8.7
--       high (>6%) | 2884 | 0.085 | 4764066 | 416943 |  8.8
--
--    4b. THE PATTERN IS NOT MONOTONIC. Margin RISES from none (13.0%) to low
--    (15.1%), then FALLS sharply to mid (8.7%), then is flat into high
--    (8.8%). So it is neither "discounts destroy margin" nor "discounts help
--    margin" — there is a peak at small discounts and a cliff after 3%.
--
--    4c. WHY "none" MIGHT UNDERPERFORM "low" — at least two mechanisms, and
--    they are indistinguishable in this data:
--      1. PRODUCT MIX. The bands do not contain the same products. If
--         undiscounted lines are disproportionately low-margin categories
--         (say Office Supplies staples), the band's margin reflects WHAT was
--         sold, not the discount policy. Nothing here holds product constant.
--      2. SELECTION ON ORDER SIZE. Small discounts may be attached to larger
--         orders, which carry fixed costs better — the shipping cost per
--         dollar of sale falls as the order grows. The discount would then
--         be a MARKER of profitable orders rather than a cause.
--      3. REVERSE CAUSATION. Discounts may be granted where the margin was
--         already comfortable enough to give something away.
--
--    WHY "DISCOUNTING IMPROVES MARGIN" IS NOT SUPPORTED: this is
--    observational data with no randomisation. The bands differ in every
--    respect at once — product, customer, order size, period — so the
--    comparison is confounded. You would need to hold product and order size
--    constant (compare the SAME product at different discounts) or, properly,
--    run an experiment.
--    WHAT WOULD SETTLE IT: the same analysis within a single sub-category,
--    or a regression with product and order size as controls. The one-line
--    version: a cross-tab of margin by discount band AND category would show
--    immediately whether the pattern survives holding category fixed.

-- ==========================================================================
-- CHALLENGE 5 — Return rates by category
-- ==========================================================================

SELECT p.ProductCategory,
       COUNT(DISTINCT o.OrderID) AS orders_containing,
       COUNT(DISTINCT r.OrderID) AS orders_returned,
       ROUND(100.0 * COUNT(DISTINCT r.OrderID) / COUNT(DISTINCT o.OrderID), 2) AS return_pct
FROM orders o
JOIN products p       ON p.ProductID = o.ProductID
LEFT JOIN returns r   ON r.OrderID   = o.OrderID
GROUP BY p.ProductCategory
ORDER BY return_pct DESC;
--    -> Furniture       | 1437 | 156 | 10.86
--       Technology      | 1725 | 184 | 10.67
--       Office Supplies | 3616 | 360 |  9.96
--
--    5a. THE GRAIN. COUNT(DISTINCT o.OrderID) — not COUNT(*) — because
--    `orders` is order LINES and one order contributes several. The LEFT
--    JOIN is essential: an INNER JOIN would drop every non-returned order
--    and every category would show 100%.
--
--    5b. DOES CATEGORY NOT MATTER? The right answer is: THIS TABLE CANNOT
--    TELL YOU. `returns` is keyed by OrderID alone — it records that an
--    order was returned, not WHAT was returned. So for a mixed order
--    containing furniture and paper, this query credits the return to BOTH
--    categories. Every multi-category order is double-counted, which pushes
--    all three rates toward the same average and mechanically erases
--    whatever difference exists.
--    The three numbers landing within one point of each other is therefore
--    the EXPECTED artefact of the schema, not a finding about products.
--    Worksheet 04 Q10 examines exactly this key choice; fixing the analysis
--    requires fixing the model — returns keyed to the order LINE.
--    This is the most important lesson in the worksheet: a query can be
--    perfectly correct and still answer a question the data does not contain.

-- ==========================================================================
-- CHALLENGE 6 — Customer cohorts
-- ==========================================================================

WITH first_order AS (
    SELECT CustomerID, MIN(YEAR(OrderDate)) AS cohort_year
    FROM orders GROUP BY CustomerID
)
SELECT f.cohort_year,
       COUNT(DISTINCT f.CustomerID)                                AS customers,
       ROUND(SUM(o.Sales), 0)                                      AS revenue,
       ROUND(SUM(o.Sales) / COUNT(DISTINCT f.CustomerID), 0)       AS revenue_per_customer
FROM first_order f
JOIN orders o ON o.CustomerID = f.CustomerID
GROUP BY f.cohort_year
ORDER BY f.cohort_year;
--    -> 2009 | 944 | 9600429 | 10170
--       2010 | 446 | 2554357 |  5727
--       2011 | 255 |  982221 |  3852
--       2012 | 167 |  433804 |  2598
--
--    6c. THE 2009 COHORT IS LARGEST BY CONSTRUCTION. The data begins in
--    2009, so every customer already active at that point is recorded as
--    "first ordered in 2009" regardless of when they really started — the
--    cohort absorbs the entire pre-existing customer base. It is not a
--    cohort at all; it is the backlog.
--    The declining sizes that follow are the same artefact: by 2012 most
--    customers who were ever going to appear already had, so only genuinely
--    new ones land in the 2012 bucket.
--
--    REVENUE PER CUSTOMER IS EVEN MORE MISLEADING: 10,170 for 2009 against
--    2,598 for 2012. The 2009 cohort had FOUR YEARS to accumulate purchases;
--    the 2012 cohort had at most one. The figure measures observation
--    window, not customer quality, and the near-perfect monotonic decline is
--    the signature of that bias rather than of deteriorating customers.
--
--    A FAIR COMPARISON needs the window held constant: revenue in each
--    cohort's FIRST 12 MONTHS, for cohorts old enough to have 12 months of
--    data. That is a genuine cohort analysis and it would exclude the 2012
--    cohort entirely — which is the right call, not a gap to paper over.
--    You would also need a true start date per customer, which this dataset
--    does not have.

-- ==========================================================================
-- CHALLENGE 7 — Best product in every region
-- ==========================================================================

-- 7a. With a window function.
WITH region_product AS (
    SELECT c.Region, p.ProductID, p.ProductName, SUM(o.Sales) AS revenue
    FROM orders o
    JOIN customers c ON c.CustomerID = o.CustomerID
    JOIN products  p ON p.ProductID  = o.ProductID
    GROUP BY c.Region, p.ProductID, p.ProductName
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Region ORDER BY revenue DESC) AS rn
    FROM region_product
)
SELECT Region, ProductName, ROUND(revenue, 0) AS revenue
FROM ranked WHERE rn = 1
ORDER BY revenue DESC;

-- 7b. Without one — join against a per-region maximum.
WITH region_product AS (
    SELECT c.Region, p.ProductName, SUM(o.Sales) AS revenue
    FROM orders o
    JOIN customers c ON c.CustomerID = o.CustomerID
    JOIN products  p ON p.ProductID  = o.ProductID
    GROUP BY c.Region, p.ProductID, p.ProductName
),
best AS (
    SELECT Region, MAX(revenue) AS revenue FROM region_product GROUP BY Region
)
SELECT rp.Region, rp.ProductName, ROUND(rp.revenue, 0) AS revenue
FROM region_product rp
JOIN best b ON b.Region = rp.Region AND b.revenue = rp.revenue
ORDER BY rp.revenue DESC;
--
--    7c. THE WINDOW VERSION READS BETTER — one pass, and the intent
--    ("number them within each region, keep number one") is on the page. The
--    join version computes the maximum separately and then finds the row
--    that matches it, which requires the reader to reconstruct the intent.
--
--    ON TIES, THEY BEHAVE DIFFERENTLY, and this is the substantive point:
--      ROW_NUMBER ... WHERE rn = 1 returns EXACTLY ONE row per region, even
--      if two products tie. Which one wins is arbitrary and may change
--      between runs. Silent.
--      The MAX join returns BOTH tied rows, so that region appears twice.
--      Visible — and possibly unwanted, since a "one row per region" report
--      suddenly has nine rows.
--    Neither is wrong; they answer slightly different questions. Use RANK()
--    instead of ROW_NUMBER() if you want ties surfaced, and decide
--    deliberately rather than discovering it in production. (No ties occur
--    in this data — which is exactly why the behaviour goes unnoticed until
--    it matters.)

-- ==========================================================================
-- CHALLENGE 8 — The executive summary
-- ==========================================================================

SELECT ROUND(SUM(Sales), 0)                                  AS revenue,
       ROUND(SUM(Profit), 0)                                 AS profit,
       ROUND(100 * SUM(Profit) / SUM(Sales), 1)              AS margin_pct,
       COUNT(DISTINCT OrderID)                               AS orders,
       COUNT(DISTINCT CustomerID)                            AS customers,
       ROUND(SUM(Sales) / COUNT(DISTINCT OrderID), 0)        AS avg_order_value,
       (SELECT ROUND(MAX(m), 0) FROM (
            SELECT SUM(Sales) AS m FROM orders
            WHERE YEAR(OrderDate) = 2012 GROUP BY MONTH(OrderDate)) AS x
       )                                                     AS best_month_revenue
FROM orders
WHERE YEAR(OrderDate) = 2012;
--    -> revenue 3356203 | profit 334558 | margin 10.0 | orders 1364 |
--       customers 957 | avg_order_value 2461 | best_month_revenue 369028
--
--    THE GRAIN TRAPS, one per column:
--      revenue/profit — safe, SUM over lines is genuinely the total.
--      orders         — MUST be COUNT(DISTINCT OrderID). COUNT(*) gives
--                       2,020 order LINES against 1,364 real orders, an
--                       overstatement of 48%.
--      customers      — MUST be COUNT(DISTINCT CustomerID). COUNT(CustomerID)
--                       counts non-NULL values on every line, i.e. the line
--                       count again.
--      avg_order_value— MUST divide by DISTINCT orders. AVG(Sales) gives the
--                       average LINE (1,661), not the average order (2,461).
--                       This is the one most people get wrong first, because
--                       AVG(Sales) is the obvious thing to write and returns
--                       a plausible number — only 32% low, which is exactly
--                       the size of error that survives review.
--      best_month     — needs its own aggregation level: total per month,
--                       then take the max. MAX(Sales) would give the largest
--                       single LINE, a completely different quantity.
--
--    THE HABIT WORTH TAKING AWAY: every one of these is checkable with a
--    two-line query, and none of the wrong versions produces an error. In a
--    seven-column summary a single grain mistake looks exactly like a
--    correct report. Build it a column at a time and verify each one.
