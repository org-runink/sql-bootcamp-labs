-- ==========================================================================
-- Morning class 25/08 — Worksheet 04: Natural keys and primary keys
-- ==========================================================================
-- Databases: superstore (read-only investigation) and your own scratch
-- database for the DDL questions.
--
-- Choosing a primary key looks like a formality. It is one of the few schema
-- decisions that is genuinely expensive to reverse: every foreign key, every
-- join, every report and every downstream system depends on it.
--
-- The vocabulary you need:
--   CANDIDATE KEY  any column or set of columns that uniquely identifies a
--                  row. A table can have several.
--   NATURAL KEY    a candidate key made of real-world data the business
--                  already uses — an email, an ISBN, a national ID.
--   SURROGATE KEY  an invented identifier with no meaning outside the
--                  database — usually an AUTO_INCREMENT integer.
--   COMPOSITE KEY  a key made of more than one column.
--   PRIMARY KEY    the ONE candidate key you nominate as the row's identity.
--
-- A good key is UNIQUE, NOT NULL, MINIMAL (no unnecessary columns) and above
-- all STABLE — it must never need to change. Most natural keys fail on that
-- last one, and this worksheet is largely about finding out how.
--
-- SHARED SERVER: Part C creates tables. Work in your own scratch database.
-- ==========================================================================

USE superstore;

-- ==========================================================================
-- PART A — Testing whether a natural key is really unique
-- ==========================================================================

-- 1. Someone proposes using `CustomerName` as the primary key of `customers`
--    — "names identify people, and it saves a join."
--    Test it: how many rows does the table have, and how many DISTINCT
--    customer names? Report both numbers.


-- 2. Show the five most-duplicated customer names, with how many times each
--    appears and how many distinct CustomerIDs share it.


-- 3. Take the single worst offender and list every row for it — id, name,
--    province, region, segment.
--    In a comment: are these one person recorded many times, or many
--    different people who share a name? Can you tell from the data alone?
--    What would you need to know to decide, and what breaks if you guess
--    wrong in each direction?


-- 4. Try to rescue the natural key by making it composite. Test, in order,
--    whether these are unique across all 1,832 rows:
--       a) CustomerName
--       b) CustomerName + Province
--       c) CustomerName + Province + CustomerSegment
--    HINT: COUNT(DISTINCT a, b, c) accepts several columns.
--    Which is the first one that works?


-- 5. You now have a composite natural key that IS unique on today's data.
--    Give two reasons it is still a bad primary key.
--    HINT: think about what happens when a customer moves province, and
--    about every foreign key that would have to carry all three columns.


-- ==========================================================================
-- PART B — Auditing this lab's own keys
-- ==========================================================================

-- 6. `orders` uses `LineID`, an AUTO_INCREMENT surrogate, as its primary key.
--    The obvious natural alternative is (OrderID, ProductID) — "one row per
--    product per order."
--    Test whether that pair is unique across all 8,060 rows.


-- 7. It is not. Find the offending pairs, then list their full rows —
--    LineID, OrderID, ProductID, OrderDate, OrderQuantity, Sales, UnitPrice
--    and Discount.
--    In a comment: is this corrupt data, or a legitimate business situation?
--    Look carefully at the discount column before answering.


-- 8. Given question 7, explain why the surrogate `LineID` was the right
--    choice here — and what would have happened to the data if someone had
--    declared PRIMARY KEY (OrderID, ProductID) when the table was created.


-- 9. `products.ProductName` — test whether it is unique.
--    If it is, does that make it a good primary key? Answer in a comment,
--    and be careful: uniqueness today is only one of the four criteria.


-- 10. `returns` has `OrderID` as its primary key. State what that choice
--     asserts about the business — specifically, what it makes IMPOSSIBLE to
--     record. Is that assertion safe?


-- ==========================================================================
-- PART C — Making the choice yourself
-- ==========================================================================

CREATE DATABASE IF NOT EXISTS practice_yourname;
USE practice_yourname;

-- 11. Design a `country` table. Countries have a name, an ISO 3166-1 alpha-2
--     code ('CA', 'BR'), and a population.
--     There are two plausible key strategies. Write the DDL BOTH ways:
--        a) the ISO code as a natural primary key
--        b) a surrogate id, with the ISO code as a UNIQUE constraint
--     Then argue which you would ship. This is one of the rare cases where
--     the natural key has a serious case — say why.


-- 12. Design an `enrolment` table linking students to courses, where a
--     student may take a course only once.
--     Write it with a composite natural primary key. Then write the version
--     with a surrogate key plus a UNIQUE constraint.
--     Prove BOTH versions reject a duplicate enrolment.


-- 13. Following on: suppose the rule changes and a student MAY retake a
--     course in a later term. Which of your two designs from question 12 is
--     easier to migrate, and why? Make the change to the easier one.
--     WARNING: the obvious sequence fails with ERROR 1553. Read the message
--     carefully — it tells you what else was depending on that index. Work
--     out the order that succeeds, and explain why it does.


-- 14. Clean up.
DROP DATABASE practice_yourname;
