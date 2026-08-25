-- ==========================================================================
-- EXTRA 05 — Views, and what "materialized" really means
-- ==========================================================================
-- A VIEW is a stored QUERY, not stored DATA. Nothing is precomputed: every
-- time you select from a view, the database runs the underlying query again.
-- That is the single idea this whole file is built around.
--
-- ---------------------------------------------------------------------
-- SHARED SERVER — READ THIS FIRST
-- ---------------------------------------------------------------------
-- Everyone in the class is on the SAME MySQL server. If you all create a
-- view called `vw_region_sales` you will overwrite each other's work.
--
-- So give yourself a private scratch database and work inside it:
--
--     CREATE DATABASE IF NOT EXISTS practice_yourname;
--     USE practice_yourname;
--
-- Replace `yourname` everywhere below. Your objects live in your database;
-- the shared `superstore` data is read cross-database as
-- `superstore.orders`, which is also the topic of Extra 06.
--
-- Never CREATE or DROP anything inside `superstore` itself.
-- ==========================================================================

-- CREATE DATABASE IF NOT EXISTS practice_yourname;
-- USE practice_yourname;


-- 1. Create a view `vw_region_sales` over the shared data: region, number of
--    distinct orders, and total sales. Then select from it, ordered by
--    revenue.
--    NOTE the two-part names — superstore.orders, superstore.customers —
--    because your view lives in a different database from the data.


-- 2. Prove a view stores no data. Run SHOW CREATE VIEW vw_region_sales and
--    read what actually got stored. Write in a comment what the server kept:
--    the rows, or the query?


-- 3. A view is re-run every time. Build a tiny table of your own, wrap it in
--    a view that SUMs it, note the total, INSERT another row, then select
--    from the view again WITHOUT touching it.
--        CREATE TABLE demo_src (n INT);
--        INSERT INTO demo_src VALUES (1),(2);
--        CREATE VIEW vw_demo AS SELECT SUM(n) AS total FROM demo_src;
--    Did the total change? Explain why in a comment.


-- 4. THE MATERIALIZED VIEW TRAP. Run this:
--        CREATE MATERIALIZED VIEW mv_demo AS SELECT SUM(n) AS total FROM demo_src;
--    Does it fail? Then check what you actually got:
--        SHOW FULL TABLES LIKE 'mv_demo';           -- look at Table_type
--    Then repeat the experiment from Q3 against mv_demo: note the total,
--    INSERT a row, select again.
--    Write down what you conclude. This is the most important question in
--    the file: the answer is NOT the one the keyword suggests.


-- 5. So how DO you materialize in MySQL? Build the snapshot yourself:
--        CREATE TABLE mv_region_sales AS SELECT * FROM vw_region_sales;
--    That is a real table holding real rows. Query it and compare its plan
--    with the view's:
--        EXPLAIN SELECT * FROM vw_region_sales;
--        EXPLAIN SELECT * FROM mv_region_sales;
--    Which one reads the 8,060-row orders table, and which reads 8 rows?


-- 6. The cost of materializing: staleness. Your snapshot does NOT track the
--    source. Write the "refresh" statement that brings it up to date.
--    HINT: the simple version is TRUNCATE + INSERT ... SELECT, in a
--    transaction so readers never see an empty table.
--    In a comment, name the trade-off you have just accepted.


-- 7. Updatable views. Some views accept INSERT/UPDATE; some cannot.
--        CREATE TABLE t (id INT PRIMARY KEY, region VARCHAR(20), amt INT);
--        INSERT INTO t VALUES (1,'West',10),(2,'East',20);
--        CREATE VIEW v_west AS SELECT * FROM t WHERE region='West';
--        CREATE VIEW v_agg  AS SELECT region, SUM(amt) AS total FROM t GROUP BY region;
--    Try UPDATE on each. One fails — predict WHICH before you run it, and
--    say why. Then confirm with:
--        SELECT TABLE_NAME, IS_UPDATABLE FROM information_schema.VIEWS
--        WHERE TABLE_SCHEMA = DATABASE();


-- 8. WITH CHECK OPTION. Recreate v_west with `WITH CHECK OPTION` on the end,
--    then try to insert a row whose region is 'East' THROUGH the view.
--    What happens, and what is that clause protecting you from?


-- 9. Views as an interface. Create `vw_customer_safe` exposing only
--    CustomerID, Region and CustomerSegment from superstore.customers —
--    no names. Explain in a comment what this is useful for.


-- 10. Clean up after yourself:
--         DROP DATABASE practice_yourname;
--     (Never drop `superstore` or `company`.)
