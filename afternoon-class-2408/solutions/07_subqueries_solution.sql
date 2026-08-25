-- ==========================================================================================================
--        __      __          ____    ___                       __  ____              __
--       /\ \  __/\ \        /\  _`\ /\_ \                     /\ \/\  _`\           /\ \__
--       \ \ \/\ \ \ \     __\ \ \/\_\\/\ \     ___   __  __   \_\ \ \ \/\ \     __  \ \ ,_\    __
--        \ \ \ \ \ \ \  /'__`\ \ \/_/_\ \ \   / __`\/\ \/\ \  /'_` \ \ \ \ \  /'__`\ \ \ \/  /'__`\
--         \ \ \_/ \_\ \ /\  __/\ \ \L\ \\_\ \_/\ \L\ \ \ \_\ \/\ \L\ \ \ \_\ \/\ \L\._\ \ \_\/\ \L\._\
--          \ `\___x___/\ \____\\ \____//\____\ \____/\ \____/\ \___,_\ \____/\ \__/\.\_\\ \__\ \__/\.\_\
--           ' \/__//__/  \/____/ \/___/ \/____/\/___/  \/___/  \/__,_ /\/___/  \/__/\/_/ \/__/\/__/\/_/
-- ==========================================================================================================
-- Afternoon class 24/08 — Worksheet 07 SOLUTIONS: subqueries   (L08)
-- File: Subqueries
-- Developed by: WeCloudData
-- ==========================================================================================================


/********************************
  Check Database Tables
********************************/

-- List databases
SHOW DATABASES;

-- Select default database
USE company;

-- Check selected database
SELECT DATABASE();


/*********************************
            Subqueries
*********************************/

-- 1. What is the highest performance score?
SELECT MAX(performance)
FROM review;

-- 2. Which employee(s) had the highest performance score?
SELECT name as employee_id, performance
FROM review
WHERE performance = (SELECT MAX(performance) FROM review);

-- 3. What is the average salary of employees with the highest performance score?
SELECT AVG(salary) AS avg_salary_high_performance
FROM employee
WHERE employee_id IN (
    SELECT name as employee_id
    FROM review
    WHERE performance = (SELECT MAX(performance) FROM review)
);


/****************************************
                EXERCISE
****************************************/
-- Use superstore data to answer the following questions
USE superstore;

-- 1. What was the total Sales loss due to returned products?
-- Hint: Total sales loss is calculated by summing the 'Sales' from the 'orders' table
SELECT SUM(Sales) as tot_loss
FROM orders o
WHERE OrderID IN (SELECT OrderID FROM returns WHERE Status = 'Returned');

-- 2. What is the highest single-day total sales number?
-- Hint: The subquery calculates the total sales per day, and the outer query selects the highest total.
SELECT OrderDate, total_sales
FROM (
    SELECT OrderDate, SUM(Sales) AS total_sales
    FROM orders
    GROUP BY OrderDate
) AS daily_sales
ORDER BY total_sales DESC
LIMIT 1;
