-- ==========================================================================================================
--        __      __          ____    ___                       __  ____              __
--       /\ \  __/\ \        /\  _`\ /\_ \                     /\ \/\  _`\           /\ \__
--       \ \ \/\ \ \ \     __\ \ \/\_\\/\ \     ___   __  __   \_\ \ \ \/\ \     __  \ \ ,_\    __
--        \ \ \ \ \ \ \  /'__`\ \ \/_/_\ \ \   / __`\/\ \/\ \  /'_` \ \ \ \ \  /'__`\ \ \ \/  /'__`\
--         \ \ \_/ \_\ \ /\  __/\ \ \L\ \\_\ \_/\ \L\ \ \ \_\ \/\ \L\ \ \ \_\ \/\ \L\._\ \ \_\/\ \L\._\
--          \ `\___x___/\ \____\\ \____//\____\ \____/\ \____/\ \___,_\ \____/\ \__/\.\_\\ \__\ \__/\.\_\
--           ' \/__//__/  \/____/ \/___/ \/____/\/___/  \/___/  \/__,_ /\/___/  \/__/\/_/ \/__/\/__/\/_/
-- ==========================================================================================================
-- Afternoon class 24/08 — Worksheet 05 SOLUTIONS: joins (company-data)   (L07)
-- File: Joins
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

-- Check database/tables
SELECT COUNT(*) FROM employee; -- 7
SELECT COUNT(*) FROM hobby; -- 4
SELECT COUNT(*) FROM hire; -- 6
SELECT COUNT(*) FROM review; -- 6


/*********************************
               Joins
*********************************/

-- 1. Inner Join (Employee with their hire year)
SELECT employee.*, hire.hire_year
FROM employee
INNER JOIN hire ON employee.employee_id = hire.employee_id;

-- Inner join (default)
-- `INNER JOIN` is the default join type when using just JOIN.
SELECT employee.*, hire.hire_year
FROM employee
JOIN hire ON employee.employee_id = hire.employee_id;

-- Using alias in join
SELECT e.*, h.hire_year
FROM employee e
JOIN hire h ON e.employee_id = h.employee_id;

-- 2. Left Join (All employees with possible hobbies)
SELECT e.employee_id, e.team, h.hobby
FROM employee e
LEFT JOIN hobby h ON e.employee_id = h.employee_id;

-- 3. Right Join (Employees with hobbies)
SELECT e.employee_id, e.team, h.hobby
FROM employee e
RIGHT JOIN hobby h ON e.employee_id = h.employee_id;

-- 4. Full Outer Join (Union of left and right joins)
-- MySQL does not support FULL OUTER JOIN directly.
-- However, you can achieve the same result by using a combination of LEFT JOIN and RIGHT JOIN with UNION.
SELECT e.employee_id, e.team, h.hobby
FROM employee e
LEFT JOIN hobby h ON e.employee_id = h.employee_id
UNION
SELECT e.employee_id, e.team, h.hobby
FROM employee e
RIGHT JOIN hobby h ON e.employee_id = h.employee_id;

/****************************************
                Exercise
****************************************/

-- Create a summary table with employee_id, team, and hire_year
SELECT e.employee_id, e.team, h.hire_year
FROM employee e
LEFT JOIN hire h ON e.employee_id = h.employee_id;

-- Create a summary table with employee_id, team, hire_year, and performance
-- HINT: just add the second join after the first in the same query
SELECT e.employee_id, e.team, h.hire_year, r.performance
FROM employee e
LEFT JOIN hire h ON e.employee_id = h.employee_id
LEFT JOIN review r ON e.employee_id = r.name;

-- What is the average performance score for each team?
SELECT e.team, AVG(r.performance) AS avg_performance
FROM employee e
JOIN review r ON e.employee_id = r.name
GROUP BY e.team;   
