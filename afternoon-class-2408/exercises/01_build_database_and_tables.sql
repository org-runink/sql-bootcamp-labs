-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 01: Build Database and Tables (superstore-data)
-- ==========================================================================
--
-- The `superstore` database in this lab is already created and seeded
-- automatically when the MySQL container starts (see db-init/ and the
-- README). You do NOT need to build it to use it for the other worksheets.
--
-- This exercise instead has you practice the DDL + data-loading workflow
-- from scratch, against a separate `superstore_practice` database, using
-- the CSV files in afternoon-class-2408/exercises/data/. Run these from a `mysql` client on
-- your HOST machine (not inside the container) so LOAD DATA LOCAL INFILE
-- can see the CSV files at their local path.
--
--   mysql --local-infile=1 -h 127.0.0.1 -P 3306 -u root -p
--
-- ==========================================================================

/**********************************************************
 *                 Working with databases                 *
 **********************************************************/
-- Task: Create a `superstore_practice` database

-- Step 1: List all databases


-- Step 2: Drop `superstore_practice` if it exists (be careful with this command)


-- Step 3: Create a new database named `superstore_practice`


-- Step 4: Select it as the default database for the rest of this session


-- Step 5: Verify the currently selected database


/*****************************************************************
 *           Creating Tables with Pre-defined PK & FK             *
 *****************************************************************/
-- Task: Create and load the `customers` table
--   Columns: CustomerID (PK), CustomerName, Province, Region, CustomerSegment
--   Data:    afternoon-class-2408/exercises/data/customers.csv (tab-delimited, header row)

-- Step 1: List all tables in the current database


-- Step 2: Drop `customers` if it already exists


-- Step 3: Create the `customers` table


-- Step 4: DESCRIBE the table to check your column types


-- Step 5: Load afternoon-class-2408/exercises/data/customers.csv into `customers`
--   Hint: LOAD DATA LOCAL INFILE '<absolute-path-to-csv>' INTO TABLE customers
--         FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' IGNORE 1 ROWS;


-- Step 6: Verify — SELECT the first 10 rows


-- Task: Create and load the `products` table
--   Columns: ProductID (PK), ProductName, ProductCategory, ProductSubCategory,
--            ProductContainer, ProductBaseMargin
--   Data:    afternoon-class-2408/exercises/data/products.csv


-- Task: Create and load the `orders` table
--   Columns: OrderID (PK), ProductID (FK -> products), CustomerID (FK -> customers),
--            OrderDate, OrderPriority, OrderQuantity, Sales, Discount, ShipMode,
--            Profit, UnitPrice, ShippingCost
--   Data:    afternoon-class-2408/exercises/data/orders.csv
--   Hint: create products and customers first so the foreign keys resolve


/***********************************************************
 *       Exercise: Create and load the returns table       *
 ***********************************************************/
-- Columns: OrderID (PK, FK -> orders), Status
-- Data:    afternoon-class-2408/exercises/data/returns.csv


/***********************************************************
 *            Exercise: Alter the orders table              *
 ***********************************************************/
-- If you created `orders` before `products` existed, add the missing
-- foreign key constraint now with ALTER TABLE ... ADD CONSTRAINT.
