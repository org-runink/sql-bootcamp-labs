-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 04 SOLUTIONS: aggregates, second pass   (L06)
-- ==========================================================================
-- Every query below was executed against this lab's data; quoted numbers
-- are real.
-- ==========================================================================

-- ==========================================================================
-- PART A — COUNT is three different functions
-- ==========================================================================

USE company;

-- 1. The three COUNTs.
SELECT e.employee_name,
       COUNT(*)                   AS count_star,
       COUNT(h.employee_id)       AS count_col,
       COUNT(DISTINCT h.hobby)    AS distinct_hobbies
FROM employee e
LEFT JOIN hobby h ON h.employee_id = e.employee_id
GROUP BY e.employee_id, e.employee_name
ORDER BY e.employee_id;
--    -> Alice Chen    1 | 0 | 0
--       Bob Martinez  2 | 2 | 2
--       Carol Singh   1 | 0 | 0
--       David Kim     1 | 0 | 0
--       Emma Johnson  1 | 1 | 1
--       Frank Wilson  1 | 0 | 0
--       Grace Lee     1 | 1 | 1
--
--    ALICE HAS NO HOBBIES, yet count_star says 1. Here is why.
--    The LEFT JOIN guarantees Alice appears, so it manufactures ONE row for
--    her with every hobby column NULL. Her group therefore contains exactly
--    one row — and:
--
--      COUNT(*)            counts ROWS. The row exists. Answer: 1. WRONG.
--      COUNT(h.employee_id) counts NON-NULL VALUES of that column. The
--                          manufactured row is NULL there. Answer: 0. RIGHT.
--      COUNT(DISTINCT h.hobby) counts distinct non-NULL values. Also 0.
--
--    THE RULE: after a LEFT JOIN, never COUNT(*). Count a column from the
--    RIGHT-hand table — that is the only one that can tell "no match" from
--    "one match". This single mistake turns every zero into a one, and the
--    query does not error, so nothing warns you.
--
--    Bob is the case that distinguishes the last two: he has 2 hobby rows.
--    If both were "Chess", count_col would say 2 and distinct_hobbies 1.

-- 2. How many employees have at least one hobby?  -> 3
SELECT COUNT(DISTINCT h.employee_id) AS employees_with_a_hobby
FROM hobby h;
--    Or, if you want it phrased from the employee side:
--        SELECT COUNT(*) FROM employee e
--        WHERE EXISTS (SELECT 1 FROM hobby h WHERE h.employee_id = e.employee_id);
--
--    WHY `COUNT(*) FROM employee LEFT JOIN hobby` IS WRONG: that counts
--    joined ROWS, not employees — 8 here (7 employees, but Bob contributes
--    two). The LEFT JOIN also keeps the four employees with no hobby at all,
--    so the number is wrong in two directions at once.
--    DISTINCT on the employee key is what collapses it back to people.

-- 3. Team salary summary.
SELECT team,
       COUNT(*)             AS headcount,
       SUM(salary)          AS total_salary,
       ROUND(AVG(salary),2) AS avg_salary
FROM employee
GROUP BY team
ORDER BY avg_salary DESC;
--    -> Data        1 |  99000.00 | 99000.00
--       Engineering 2 | 183000.00 | 91500.00
--       Marketing   2 | 146000.00 | 73000.00
--       Sales       2 | 140000.00 | 70000.00
--
--    AVG(salary) = SUM(salary)/COUNT(*) here ONLY BECAUSE `salary` is
--    NOT NULL for every row. AVG ignores NULLs: it divides by the number of
--    NON-NULL values, i.e. COUNT(salary), not COUNT(*).
--    So with even one missing salary, AVG(salary) and SUM(salary)/COUNT(*)
--    give different answers — and AVG is usually the one you meant.
--    If you want missing salaries treated as zero you must say so:
--    AVG(COALESCE(salary, 0)). Silence is not a decision; make it explicit.

-- 4. Members per team on one row.
SELECT team,
       GROUP_CONCAT(employee_name ORDER BY employee_name SEPARATOR ', ') AS members
FROM employee
GROUP BY team
ORDER BY team;
--    -> Data        | Grace Lee
--       Engineering | Alice Chen, Bob Martinez
--       Marketing   | Emma Johnson, Frank Wilson
--       Sales       | Carol Singh, David Kim
--
--    Plain `SELECT team, employee_name` cannot do this: it returns one row
--    per employee, which is a different SHAPE of answer. GROUP BY collapses
--    each team to a single row, and a single row can hold only a single
--    value per column — so to keep the names you must AGGREGATE them into
--    one value. GROUP_CONCAT is the aggregate that does it for text.
--    (Note it has a length cap, group_concat_max_len, default 1024 bytes —
--    it TRUNCATES silently past that. Fine for 7 employees, not for 7,000.)

-- ==========================================================================
-- PART B — Grouping at the wrong grain
-- ==========================================================================

USE superstore;

-- 5. Average order value, both ways.
SELECT ROUND(AVG(Sales), 2)                            AS avg_per_line,
       ROUND(SUM(Sales) / COUNT(DISTINCT OrderID), 2)  AS avg_per_order
FROM orders;
--    -> 1683.72 | 2531.40
--
--    A finance report means avg_per_ORDER: what a customer spends when they
--    buy. avg_per_line is the average value of a single product line, which
--    is a warehouse/picking metric, not a revenue one.
--    The trap is that AVG(Sales) is the obvious thing to type, it runs, and
--    it returns a plausible-looking number ~33% too low. Nothing in the
--    query says "per line" — the grain is a property of the TABLE, not of
--    the query, so you have to know it. That is why worksheet 03 opens with
--    the 8,060 vs 5,361 distinction.

-- 6. Revenue by category AND sub-category.
SELECT p.ProductCategory,
       p.ProductSubCategory,
       COUNT(DISTINCT o.OrderID)  AS orders,
       ROUND(SUM(o.Sales), 0)     AS revenue
FROM orders o
JOIN products p ON p.ProductID = o.ProductID
GROUP BY p.ProductCategory, p.ProductSubCategory
ORDER BY p.ProductCategory, revenue DESC;
--    -> Furniture       | Chairs & Chairmats             | 375 | 1761837
--       Furniture       | Tables                         | 211 | 1043755
--       Furniture       | Bookcases                      | 188 |  822652
--       Furniture       | Office Furnishings             | 757 |  698094
--       Office Supplies | Storage & Organization         | 537 | 1070183
--       Office Supplies | Binders and Binder Accessories | 868 | 1022958
--       ... (17 sub-categories in total)
--
--    Grouping by two columns produces one group per COMBINATION that exists
--    in the data — not one per category plus one per sub-category. Note
--    "Office Furnishings" has the most orders of the Furniture rows but the
--    least revenue: cheap items sold often. Counting orders and summing
--    money answer different questions; show both.

-- 7. Subtotals and a grand total.
SELECT COALESCE(p.ProductCategory, 'ALL CATEGORIES') AS category,
       ROUND(SUM(o.Sales), 0)                        AS revenue
FROM orders o
JOIN products p ON p.ProductID = o.ProductID
GROUP BY p.ProductCategory WITH ROLLUP;
--    -> Furniture       |  4326337
--       Office Supplies |  3745548
--       Technology      |  5498925
--       ALL CATEGORIES  | 13570811
--
--    ROLLUP adds a super-aggregate row. It marks the grouped column NULL on
--    that row to mean "every value of this column" — which is exactly the
--    ambiguity you would expect: a real NULL category and a rollup total
--    would look identical. COALESCE relabels it.
--    If you need to tell them apart for certain, GROUPING(p.ProductCategory)
--    returns 1 only for rollup rows.

-- 8. Sub-categories beating the average sub-category revenue.  -> 8 of 17
SELECT ProductSubCategory, revenue
FROM (
    SELECT p.ProductSubCategory, ROUND(SUM(o.Sales), 0) AS revenue
    FROM orders o
    JOIN products p ON p.ProductID = o.ProductID
    GROUP BY p.ProductSubCategory
) AS per_sub
WHERE revenue > (SELECT AVG(total) FROM (
        SELECT SUM(o.Sales) AS total
        FROM orders o JOIN products p ON p.ProductID = o.ProductID
        GROUP BY p.ProductSubCategory) AS x)
ORDER BY revenue DESC;
--    -> Office Machines               2123674
--       Telephones and Communication  1842197
--       Chairs & Chairmats            1761837
--       Storage & Organization        1070183
--       Tables                        1043755
--       Binders and Binder Accessories 1022958
--       Copiers and Fax                919451
--       Bookcases                      822652
--
--    Only 8 of 17 sub-categories are above average — and the mean is dragged
--    up by the big three, so "above average" here means "in the top half by
--    a wide margin". A median would tell a different story; averages of
--    skewed data usually do.
--
--    WHY THE NESTING: you are comparing each group's total against the
--    AVERAGE OF ALL GROUP TOTALS. That second number is an aggregate OVER
--    an aggregate, and SQL has no way to express it in one level — HAVING
--    can only see the current group. So the inner totals must be materialised
--    first, then averaged.
--    A CTE reads far better and computes it once; worksheet 02 of the
--    morning class covers that.

-- 9. Revenue per ordering customer, by region.
SELECT c.Region,
       ROUND(SUM(o.Sales), 0)                              AS revenue,
       COUNT(DISTINCT o.CustomerID)                        AS customers,
       ROUND(SUM(o.Sales) / COUNT(DISTINCT o.CustomerID), 0) AS revenue_per_customer
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.Region
ORDER BY revenue_per_customer DESC;
--    -> Northwest Territories  781695 |  76 | 10285
--       West                  3312073 | 381 |  8693
--       Prarie                2619153 | 313 |  8368
--       Ontario               2731470 | 334 |  8178
--       Yukon                  860655 | 127 |  6777
--       Quebec                1328624 | 203 |  6545
--       Atlantic              1834002 | 338 |  5426
--       Nunavut                103138 |  40 |  2578
--
--    Note the ranking INVERTS depending on the column you sort by. West and
--    Ontario dominate absolute revenue, but Northwest Territories — eighth
--    by revenue — is first per customer, and Nunavut is last on both. A
--    "top region" claim is meaningless until you say per what.
--
--    THE GRAIN TRAP: COUNT(*) would count order LINES and COUNT(CustomerID)
--    would count non-NULL customer ids on those lines — both give the line
--    count, not the customer count, and the "per customer" figure would come
--    out roughly 4-5x too small. Only COUNT(DISTINCT o.CustomerID) counts
--    people. Any time the phrase is "per X", check that X is counted once.
