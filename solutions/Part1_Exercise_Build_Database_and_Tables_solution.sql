-- ==========================================================================
-- Part 1 Exercise: Build Database and Tables (superstore-data) — SOLUTION
-- ==========================================================================
-- Run against a `superstore_practice` database from a HOST mysql client
-- (LOAD DATA LOCAL INFILE reads files from the *client's* filesystem):
--
--   mysql --local-infile=1 -h 127.0.0.1 -P 3306 -u root -p
--
-- Adjust the absolute paths below to wherever you cloned this repo.
-- ==========================================================================

SHOW DATABASES;
DROP DATABASE IF EXISTS superstore_practice;
CREATE DATABASE superstore_practice;
USE superstore_practice;
SELECT DATABASE();

-- ---- customers ----
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  CustomerID INT PRIMARY KEY,
  CustomerName VARCHAR(100),
  Province VARCHAR(50),
  Region VARCHAR(30),
  CustomerSegment VARCHAR(20)
);
DESCRIBE customers;

LOAD DATA LOCAL INFILE '/absolute/path/to/sql-bootcamp-labs/exercises/data/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM customers LIMIT 10;

-- ---- products ----
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(200),
    ProductCategory VARCHAR(20),
    ProductSubCategory VARCHAR(50),
    ProductContainer VARCHAR(20),
    ProductBaseMargin DECIMAL(4,2)
);

LOAD DATA LOCAL INFILE '/absolute/path/to/sql-bootcamp-labs/exercises/data/products.csv'
INTO TABLE products
CHARACTER SET 'latin1'
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM products LIMIT 10;

-- ---- orders ----
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    OrderID INT PRIMARY KEY,
    ProductID INT,
    CustomerID INT,
    OrderDate DATE,
    OrderPriority VARCHAR(20),
    OrderQuantity INT,
    Sales DECIMAL(15,5),
    Discount DECIMAL(3,2),
    ShipMode VARCHAR(20),
    Profit DECIMAL(15,2),
    UnitPrice DECIMAL(15,2),
    ShippingCost DECIMAL(15,2),
    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES products(ProductID)
);

LOAD DATA LOCAL INFILE '/absolute/path/to/sql-bootcamp-labs/exercises/data/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM orders LIMIT 10;

-- ---- returns ----
DROP TABLE IF EXISTS returns;
CREATE TABLE returns (
    OrderID INT PRIMARY KEY,
    Status VARCHAR(20),
    FOREIGN KEY (OrderID) REFERENCES orders(OrderID)
);

LOAD DATA LOCAL INFILE '/absolute/path/to/sql-bootcamp-labs/exercises/data/returns.csv'
INTO TABLE returns
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM returns LIMIT 10;

-- ---- Alter Table exercise ----
-- (Not needed here since ProductID's FK was declared inline above, but
-- if you create orders before products, add it after the fact with:)
-- ALTER TABLE orders ADD CONSTRAINT fk_orders_products FOREIGN KEY (ProductID) REFERENCES products(ProductID);
