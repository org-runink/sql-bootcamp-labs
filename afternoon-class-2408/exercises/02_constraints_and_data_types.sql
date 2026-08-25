-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 02: Constraints and data types
-- ==========================================================================
-- Worksheet 01 built tables. This one is about the choices you make WHILE
-- building them: which type to use, and which rules the database should
-- enforce for you.
--
-- The theme: a constraint is not paperwork. It is the difference between
-- "our data is wrong and nobody noticed for eight months" and "that INSERT
-- failed immediately." Every question here has you BREAK something on
-- purpose so you see the error the database gives.
--
-- SHARED SERVER: this worksheet CREATEs tables. Work in your own scratch
-- database and drop it at the end. Never create anything in `superstore`
-- or `company`.
-- ==========================================================================

CREATE DATABASE IF NOT EXISTS practice_yourname;
USE practice_yourname;

-- ==========================================================================
-- PART A — Choosing a type
-- ==========================================================================

-- 1. Money and FLOAT.
--    Create a table with one FLOAT column and one DECIMAL(10,2) column.
--    Insert 0.1 and 0.2 into both. Then SELECT the SUM of each, and also
--    test whether the FLOAT sum = 0.3.
--    Report what you see, and write a one-line rule about storing money.


-- 2. Look at how this lab's own schema types its money and its dates:
--        DESCRIBE superstore.orders;
--    `Sales` is DECIMAL(15,5) and `OrderDate` is DATE, not VARCHAR.
--    In a comment: name two things that become possible with a DATE column
--    that are painful if you store '2012-03-14' as text.


-- 3. Storing a phone number: INT or VARCHAR? Argue it in two lines.
--    HINT: try INSERTing the value 0044123456789 into an INT column.


-- ==========================================================================
-- PART B — Constraints that catch mistakes
-- ==========================================================================

-- 4. NOT NULL and DEFAULT. Create a `member` table with:
--       member_id   auto-incrementing primary key
--       full_name   text, required
--       email       text, must be unique
--       joined_on   a date that defaults to today if not supplied
--       status      text, defaults to 'active'
--    Insert one row supplying ONLY full_name and email, then SELECT it.
--    What did the database fill in for you?


-- 5. Now try to insert a second member with the SAME email.
--    Record the exact error. Which constraint fired, and how do you know
--    from the message alone which column caused it?


-- 6. Insert a member with email NULL. Then a SECOND one with email NULL.
--    Does UNIQUE stop you? Explain the result — this surprises most people,
--    and it follows from what NULL means.


-- 7. PRIMARY KEY vs UNIQUE. Given what you just saw, state the two
--    differences between them.


-- 8. CHECK constraints. Add a table `product_price` with a `price` column
--    that must be greater than zero, then try to insert a negative price.
--    Record the error. (Note: CHECK is only actually ENFORCED from MySQL
--    8.0.16 onward — older versions parse and silently ignore it. Verify
--    yours enforces it rather than assuming.)


-- ==========================================================================
-- PART C — Foreign keys and what happens on delete
-- ==========================================================================

-- 9. Create `team` and `player`, where each player references a team.
--    Insert one team and one player on it. Now DELETE the team.
--    What happens, and what is MySQL protecting you from?


-- 10. Recreate `player` twice more, once with
--        FOREIGN KEY (team_id) REFERENCES team(team_id) ON DELETE CASCADE
--     and once with ... ON DELETE SET NULL.
--     Delete the parent team in each case and describe what happened to the
--     player row.
--     Then answer: for a `player` whose team is disbanded, which of the
--     three behaviours is correct — and what does SET NULL require of the
--     team_id column?


-- 11. Look at this lab's real schema and find a place where a foreign key is
--     deliberately ABSENT:
--        SHOW CREATE TABLE superstore.returns;
--        SHOW INDEX FROM superstore.orders;
--     `returns.OrderID` points at `orders.OrderID`, but no FK enforces it.
--     Work out why one cannot be created here. (The answer is visible in the
--     index list.) Worksheet 03 of the morning class explores this further.


-- 12. Clean up.
DROP DATABASE practice_yourname;
