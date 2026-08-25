-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 04: Aggregates, second pass   (L06)
-- ==========================================================================
-- Databases: superstore AND company.
--
-- Worksheet 03 covered the shape of GROUP BY. This one is about the ways
-- aggregates quietly give you the WRONG NUMBER while running perfectly.
-- Every question here has a plausible answer that is wrong.
--
-- Reminder: in `orders`, one row is one ORDER LINE, not one order.
-- ==========================================================================

-- ==========================================================================
-- PART A — COUNT is three different functions
-- ==========================================================================

USE company;

-- 1. List every employee with the number of hobbies they have. Show THREE
--    columns beside the name: COUNT(*), COUNT(h.employee_id), and
--    COUNT(DISTINCT h.hobby). Use a LEFT JOIN from employee to hobby so
--    everyone appears.
--
--    Then answer in a comment: Alice Chen has no hobbies recorded. What does
--    each of the three columns say about her, and which one is telling the
--    truth? Why do they differ?


-- 2. Following from 1: write the query that correctly answers "how many
--    employees have at least one hobby recorded?" — as a single number.
--    Beware: `SELECT COUNT(*) FROM employee LEFT JOIN hobby ...` is wrong.
--    Say in a comment why.


-- 3. Per team, show headcount, total salary and average salary.
--    Then answer in a comment: here AVG(salary) equals SUM(salary)/COUNT(*)
--    exactly. Name the one condition that has to hold for that to be true,
--    and what AVG does differently when it does not.


-- 4. Show each team on one row with a comma-separated list of its members,
--    alphabetically. (Look up GROUP_CONCAT.)
--    Why can you not get this with plain SELECT team, employee_name?


-- ==========================================================================
-- PART B — Grouping at the wrong grain
-- ==========================================================================

USE superstore;

-- 5. The average order value. Produce BOTH numbers in one row:
--       - average Sales per order LINE
--       - average Sales per ORDER
--    They differ by about 50%. Explain in a comment which one a finance
--    report should quote, and why the other is so easy to produce by
--    accident.


-- 6. Revenue by category AND sub-category: for each pair show the number of
--    distinct orders and total sales (0 dp), sorted by category then revenue
--    descending.
--    HINT: grouping by two columns makes one group per COMBINATION.


-- 7. Add a subtotal row per category and a grand-total row to question 6's
--    category-level figures, using one query. (Look up WITH ROLLUP.)
--    Use COALESCE to label the total rows rather than leaving them NULL —
--    and note in a comment why those cells come back NULL in the first place.


-- 8. Which product sub-categories beat the AVERAGE sub-category revenue?
--    Show sub-category and revenue, best first.
--    CAREFUL: you cannot put an aggregate inside HAVING's comparison against
--    another aggregate of the whole table directly — you need a subquery.


-- 9. Stretch. For each region show: total revenue, the number of customers
--    who ordered, and revenue per ordering customer (0 dp), richest region
--    per customer first.
--    Watch the grain — a customer with three orders must count ONCE.
