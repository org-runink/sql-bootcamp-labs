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

CREATE TABLE returns (
    OrderID INT PRIMARY KEY,
    Status VARCHAR(20),
    FOREIGN KEY (OrderID) REFERENCES orders(OrderID)
);
