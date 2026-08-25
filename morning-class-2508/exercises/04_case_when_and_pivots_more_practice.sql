-- ==========================================================================
-- EXTRA 04 — CASE WHEN and pivot tables                       (reinforces L09)
-- ==========================================================================
-- Database: superstore.  Tables: customers, products, orders, returns.
--
-- The shape to remember:
--     CASE WHEN condition THEN value
--          WHEN condition THEN value
--          ELSE value
--     END AS derived_column
--
-- The pivot trick is CASE WHEN *inside* an aggregate:
--     SUM(CASE WHEN <column> = <value> THEN 1 ELSE 0 END)
-- That counts only the rows matching the condition, turning what would be
-- ROWS (one per group) into COLUMNS (one per value). That is all a pivot is.
-- ==========================================================================

USE superstore;

-- 1. Label each order line by size: 'Small' under $100, 'Medium' under $1000,
--    'Large' otherwise. Show how many lines and how much revenue fall in each
--    tier, biggest revenue first.
--    Notice what the answer says about where the money actually comes from.


-- 2. Pivot years into columns. For each ProductCategory show total sales in
--    2009, 2010, 2011 and 2012 as four separate columns.


-- 3. Pivot quarters. For each year show total sales for Q1, Q2, Q3 and Q4 as
--    four columns. HINT: QUARTER(OrderDate).


-- 4. Conditional counting. Per ProductCategory, count how many order lines
--    were profitable (Profit > 0) and how many were not.
--    One of the three categories loses money on MORE lines than it makes it
--    on — which, and does that match what you found in worksheet 02 of the afternoon class (aggregates) Q6?


-- 5. Does discounting pay? Bucket each line by discount —
--    'none' (0), 'low' (<= 0.05), 'mid' (<= 0.15), 'high' (> 0.15) —
--    and show the line count and average profit per bucket.
--    State the conclusion in a comment. Be careful about the 'high' bucket:
--    look at its line count before trusting its average.


-- 6. CASE outside SELECT. List the order priorities with their line counts,
--    sorted in true business order (Critical, High, Medium, Low, Not
--    Specified) rather than alphabetically.
--    HINT: CASE works in ORDER BY too.


-- 7. Returned-or-not flag. Produce a per-region summary showing, for each
--    region, the total lines, the returned lines, and the return rate as a
--    percentage (1 dp).
--    HINT: LEFT JOIN returns, then SUM(CASE WHEN r.OrderID IS NOT NULL …).


-- 8. Two-dimension pivot (stretch). Build a matrix of CustomerSegment (rows)
--    against ProductCategory (columns) holding total sales.


-- 9. Stretch. Using CASE, show for each year the share of sales that came
--    from returned orders, as a percentage (1 dp).
--    HINT: SUM(CASE …) / SUM(Sales). Watch the integer-division trap.
