-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 07: Subqueries (company-data, superstore-data)   (L08)
-- ==========================================================================

/********************************
  Check Database Tables
********************************/

USE company;

/*********************************
            Subqueries
*********************************/

-- 1. What is the highest performance score in `review`?


-- 2. Which employee(s) had that highest performance score?
--    HINT: review's key column is called `name`, holding employee_id values


-- 3. What is the average salary of employees with the highest
--    performance score? (nest the query from #2 inside a subquery
--    against `employee`)


/****************************************
                EXERCISE
****************************************/

USE superstore;

-- 1. What was the total Sales lost to returned products?
--    HINT: SUM Sales from `orders` where OrderID is in the set of
--    returned OrderIDs from `returns` (Status = 'Returned')


-- 2. What is the highest single-day total sales number?
--    HINT: subquery sums Sales per OrderDate; outer query picks the max
