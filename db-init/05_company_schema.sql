-- ==========================================================================
-- company database — schema
-- Used for: SQL Part 2 (Joins) and SQL Part 3 (Subqueries) exercises
-- ==========================================================================

DROP DATABASE IF EXISTS company;
CREATE DATABASE company;
USE company;

-- Core roster. One row per employee.
CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    team VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2) NOT NULL
);

-- When each employee was hired. Intentionally NOT 1:1 with employee —
-- one employee (7) has no hire record yet, to demonstrate LEFT/RIGHT JOIN
-- behavior with missing matches.
CREATE TABLE hire (
    employee_id INT NOT NULL,
    hire_year INT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);

-- Employee hobbies. Intentionally sparse (only 4 rows across 7 employees,
-- and one employee has two hobbies) to demonstrate LEFT JOIN row
-- multiplication and NULL handling.
CREATE TABLE hobby (
    employee_id INT NOT NULL,
    hobby VARCHAR(50) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);

-- Performance reviews. Column is named `name` (not `employee_id`) on
-- purpose — it mirrors the original lab data and is a deliberate
-- "gotcha" for students practicing JOIN ... ON conditions across
-- differently-named key columns.
CREATE TABLE review (
    name INT NOT NULL,
    performance INT NOT NULL,
    FOREIGN KEY (name) REFERENCES employee(employee_id)
);
