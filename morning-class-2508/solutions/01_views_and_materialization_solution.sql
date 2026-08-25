-- ==========================================================================
-- Morning class 25/08 — Worksheet 01 SOLUTIONS: views and materialization
-- ==========================================================================
-- Every result below was produced on this lab's MySQL. Replace `yourname`.
-- ==========================================================================

CREATE DATABASE IF NOT EXISTS practice_yourname;
USE practice_yourname;

-- 1. A view over another database's tables.
CREATE OR REPLACE VIEW vw_region_sales AS
SELECT c.Region,
       COUNT(DISTINCT o.OrderID) AS Orders,
       ROUND(SUM(o.Sales), 2)    AS Revenue
FROM superstore.orders o
JOIN superstore.customers c ON o.CustomerID = c.CustomerID
GROUP BY c.Region;

SELECT * FROM vw_region_sales ORDER BY Revenue DESC;
-- -> West 3,312,072.65 | Ontario 2,731,470.21 | Prarie 2,619,152.69 … (8 rows)

-- 2. What got stored?
SHOW CREATE VIEW vw_region_sales;
--    -> The SELECT statement, verbatim. Not one row of data.
--    A view is a NAMED QUERY. `Table_type` is VIEW, it has no rows of its
--    own, and it occupies no space beyond its definition.

-- 3. A view is re-executed on every reference.
CREATE TABLE demo_src (n INT);
INSERT INTO demo_src VALUES (1), (2);
CREATE OR REPLACE VIEW vw_demo AS SELECT SUM(n) AS total FROM demo_src;

SELECT total FROM vw_demo;          -- -> 3
INSERT INTO demo_src VALUES (100);
SELECT total FROM vw_demo;          -- -> 103
--    The total changed although nobody touched the view. That IS the
--    definition of a view: the query runs again, against current data.

-- 4. THE MATERIALIZED VIEW TRAP.
CREATE MATERIALIZED VIEW mv_demo AS SELECT SUM(n) AS total FROM demo_src;
--    -> This does NOT fail. No error, no warning.

SHOW FULL TABLES LIKE 'mv_demo';
--    -> Table_type: VIEW      <-- a PLAIN view. Nothing was materialized.

SELECT total FROM mv_demo;          -- -> 103
INSERT INTO demo_src VALUES (1000);
SELECT total FROM mv_demo;          -- -> 1103   (a real MV would still say 103)

--    CONCLUSION: MySQL has NO materialized views. The word `MATERIALIZED`
--    is accepted and then effectively ignored — you get an ordinary view.
--    This is worse than an error, because the statement SUCCEEDS and you
--    walk away believing you have a precomputed snapshot. Every later
--    reasoning about performance and staleness is then wrong.
--
--    Other engines differ, and the differences matter:
--      PostgreSQL — real MVs, refreshed manually (REFRESH MATERIALIZED VIEW)
--      Oracle     — real MVs, can refresh ON COMMIT or on a schedule
--      MySQL      — none; you build and refresh the snapshot yourself (Q5/Q6)
--    Never carry an assumption about MVs across engines. Verify on the
--    engine you are actually running, exactly as you just did.

-- 5. Materializing by hand: a real table holding real rows.
CREATE TABLE mv_region_sales AS SELECT * FROM vw_region_sales;

EXPLAIN SELECT * FROM vw_region_sales;
--    -> cost≈4842, scans ~8004 rows: it joins and re-aggregates every time.
EXPLAIN SELECT * FROM mv_region_sales;
--    -> cost≈1.05, rows=8: it just reads the 8 stored rows.
--
--    That gap is the entire reason materialization exists. The view is
--    always correct and always pays full price; the table is cheap and is
--    only as correct as its last refresh.

-- 6. Refreshing the snapshot.
START TRANSACTION;
TRUNCATE TABLE mv_region_sales;
INSERT INTO mv_region_sales SELECT * FROM vw_region_sales;
COMMIT;

SELECT COUNT(*) AS RowsAfterRefresh FROM mv_region_sales;   -- -> 8
--
--    THE TRADE-OFF YOU JUST ACCEPTED: staleness. Between refreshes the
--    snapshot is wrong, and nothing warns you. You have traded correctness
--    for speed, and taken on a new duty — deciding how often to refresh and
--    making sure it actually runs.
--    (TRUNCATE is DDL in MySQL and causes an implicit commit, so it is not
--    truly atomic here. For a snapshot that must never appear empty to
--    readers, build the new copy in a second table and RENAME TABLE it into
--    place — rename IS atomic.)

-- 7. Updatable views.
CREATE TABLE t (id INT PRIMARY KEY, region VARCHAR(20), amt INT);
INSERT INTO t VALUES (1, 'West', 10), (2, 'East', 20);
CREATE OR REPLACE VIEW v_west AS SELECT * FROM t WHERE region = 'West';
CREATE OR REPLACE VIEW v_agg  AS SELECT region, SUM(amt) AS total FROM t GROUP BY region;

UPDATE v_west SET amt = 11 WHERE id = 1;   -- works
UPDATE v_agg  SET total = 999 WHERE region = 'West';
--    -> ERROR 1288 (HY000): The target table v_agg of the UPDATE is not updatable
--
--    WHY: v_west maps each of its rows to exactly one row of `t`, so the
--    server knows which row to change. v_agg's rows are SUMs over many rows
--    — "set this total to 999" has no single meaning. Aggregation, DISTINCT,
--    GROUP BY, UNION all destroy that one-to-one mapping.

SELECT TABLE_NAME, IS_UPDATABLE
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE();
--    -> v_agg NO | v_west YES   (the server tells you, so you needn't guess)

-- 8. WITH CHECK OPTION.
CREATE OR REPLACE VIEW v_west AS
SELECT * FROM t WHERE region = 'West' WITH CHECK OPTION;

INSERT INTO v_west VALUES (3, 'East', 30);
--    -> ERROR 1369 (HY000): CHECK OPTION failed 'practice_yourname.v_west'
--
--    Without the clause that INSERT SUCCEEDS — and the row promptly vanishes
--    from the view, because it fails the view's own WHERE. You would have
--    written a row through a window that cannot show it back to you.
--    WITH CHECK OPTION forbids exactly that.

-- 9. A view as a privacy interface.
CREATE OR REPLACE VIEW vw_customer_safe AS
SELECT CustomerID, Region, CustomerSegment
FROM superstore.customers;
--    Grant an analyst SELECT on this view and nothing on the base table, and
--    they can do regional analysis while never reading CustomerName. The view
--    is the boundary: column-level exposure without copying data.

-- 10. Clean up.
DROP DATABASE practice_yourname;
