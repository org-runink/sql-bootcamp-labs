-- ==========================================================================
-- superstore database — schema
-- Used for: SQL Part 1 (DDL), Part 2 (Joins), Part 3 (Case/Pivot, Subqueries)
-- Mirrors the ERD: customers ─< orders >─ products, orders ─< returns
-- ==========================================================================

DROP DATABASE IF EXISTS superstore;
CREATE DATABASE superstore;
USE superstore;

CREATE TABLE customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    Province VARCHAR(50),
    Region VARCHAR(30),
    CustomerSegment VARCHAR(20)
);

CREATE TABLE products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(200),
    ProductCategory VARCHAR(20),
    ProductSubCategory VARCHAR(50),
    ProductContainer VARCHAR(20),
    ProductBaseMargin DECIMAL(4,2)
);

-- OrderID is NOT unique here: a single order can contain multiple product
-- line items (one row per line item), so LineID is the real primary key.
CREATE TABLE orders (
    LineID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
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
    FOREIGN KEY (ProductID) REFERENCES products(ProductID),
    INDEX idx_orders_orderid (OrderID)
);

-- No FOREIGN KEY to orders(OrderID): MySQL requires FK targets to be
-- uniquely indexed, and OrderID repeats in orders (see above).
CREATE TABLE returns (
    OrderID INT PRIMARY KEY,
    Status VARCHAR(20)
);
