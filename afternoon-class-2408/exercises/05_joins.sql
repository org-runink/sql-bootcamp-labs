-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 05: Joins (company-data)   (L07)
-- ==========================================================================
-- Uses the `company` database (employee, hire, hobby, review), already
-- seeded by db-init/. Expected row counts, so you can sanity-check your
-- setup before starting:
--   employee: 7   hobby: 4   hire: 6   review: 6
-- ==========================================================================

/********************************
  Check Database Tables
********************************/

-- List databases


-- Select `company` as the default database


-- Confirm the selected database


-- Check row counts for employee, hobby, hire, review (compare to the
-- expected counts in the header comment above)


/*********************************
               Joins
*********************************/

-- 1. INNER JOIN: for each employee, show their hire_year (only employees
--    that actually have a hire record)


-- 2. LEFT JOIN: show every employee with their team, and their hobby if
--    they logged one (NULL otherwise)


-- 3. RIGHT JOIN: same hobby join as above, but written as a RIGHT JOIN
--    starting from `hobby`


-- 4. FULL OUTER JOIN: MySQL has no FULL JOIN keyword — reproduce it by
--    combining a LEFT JOIN and a RIGHT JOIN with UNION


/****************************************
                Exercise
****************************************/

-- 1. Build a summary with employee_id, team, and hire_year for every
--    employee (don't drop employees with no hire record)


-- 2. Extend the query above to also include performance from `review`.
--    HINT: review's key column is called `name`, not `employee_id` —
--    join on employee.employee_id = review.name


-- 3. What is the average performance score for each team?
