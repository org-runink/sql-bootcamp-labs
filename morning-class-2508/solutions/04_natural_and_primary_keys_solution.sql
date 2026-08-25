-- ==========================================================================
-- Morning class 25/08 — Worksheet 04 SOLUTIONS: natural keys and primary keys
-- ==========================================================================
-- Every query below was executed against this lab's data; quoted numbers
-- and errors are real.
-- ==========================================================================

USE superstore;

-- ==========================================================================
-- PART A — Testing whether a natural key is really unique
-- ==========================================================================

-- 1. Is CustomerName unique?  -> NO. 1832 rows, 796 distinct names.
SELECT COUNT(*)                     AS rows_in_table,
       COUNT(DISTINCT CustomerName) AS distinct_names,
       COUNT(*) - COUNT(DISTINCT CustomerName) AS collisions
FROM customers;
--    -> 1832 | 796 | 1036
--
--    Over half the table collides. The proposal fails on the very first
--    criterion, and it fails LOUDLY — this is not a rare edge case.

-- 2. The worst offenders.
SELECT CustomerName,
       COUNT(*)                   AS times,
       COUNT(DISTINCT CustomerID) AS distinct_ids,
       COUNT(DISTINCT Province)   AS provinces
FROM customers
GROUP BY CustomerName
HAVING COUNT(*) > 1
ORDER BY times DESC
LIMIT 5;
--    -> Eric Barreto     13 | 13 | 7
--       Dan Campbell     10 | 10 | 6
--       Giulietta Dortch 10 | 10 | 6
--       Harold Dahlen    10 | 10 | 6
--       Karl Brown       10 | 10 | 5

-- 3. Eric Barreto in full.
SELECT CustomerID, CustomerName, Province, Region, CustomerSegment
FROM customers
WHERE CustomerName = 'Eric Barreto'
ORDER BY CustomerID;
--    -> 13 rows, 13 distinct CustomerIDs, across Manitoba, Ontario, Nova
--       Scotia, British Columbia (x2), Quebec (x2), Yukon (x2),
--       Newfoundland (x2) — as Consumer and as Small Business.
--
--    CAN YOU TELL FROM THE DATA? No, and that is the point. Thirteen rows
--    named Eric Barreto is consistent with:
--      * thirteen different people who happen to share a common name;
--      * one person recorded thirteen times because the source system had no
--        way to match them (a classic master-data problem);
--      * something in between — two real Erics, each duplicated.
--    Nothing in this table distinguishes those. You would need something
--    genuinely identifying: an email, a date of birth, a customer account
--    number from the source system.
--
--    WHAT BREAKS IF YOU GUESS WRONG:
--      Treat them as ONE person when they are thirteen -> you merge thirteen
--      strangers' purchase histories, and your "best customer" is fictional.
--      Any personalised communication goes to the wrong people, and under
--      data-protection law a subject-access request now exposes twelve other
--      people's data.
--      Treat them as THIRTEEN when they are one -> your customer count is
--      inflated, repeat-purchase rates are understated, and the same person
--      gets thirteen copies of every mailing.
--    Neither error is recoverable after the fact without the identifying
--    data you did not collect. This is why the decision belongs at design
--    time.

-- 4. Rescuing it with a composite key.
SELECT 'name'                  AS candidate_key,
       COUNT(DISTINCT CustomerName) AS distinct_combos, COUNT(*) AS rows_ FROM customers
UNION ALL
SELECT 'name+province',
       COUNT(DISTINCT CustomerName, Province), COUNT(*) FROM customers
UNION ALL
SELECT 'name+province+segment',
       COUNT(DISTINCT CustomerName, Province, CustomerSegment), COUNT(*) FROM customers;
--    -> name                   796 / 1832   not unique
--       name+province         1538 / 1832   still not unique
--       name+province+segment 1832 / 1832   UNIQUE
--
--    So (CustomerName, Province, CustomerSegment) IS a candidate key on
--    today's data. Note it took three columns, and note that the second
--    attempt still left 294 collisions — "add another column until it works"
--    is a bad way to find a key, because you never know when to stop.

-- 5. Why it is still a bad primary key. Two reasons, both fatal:
--
--    NOT STABLE. A customer who moves from Quebec to Ontario changes their
--    own identity. Every order they ever placed now points at a customer who
--    no longer exists. You would have to update the key AND every foreign
--    key referencing it, inside one transaction, forever — and history
--    becomes unreconstructible. A primary key must be IMMUTABLE, and
--    `Province` is a fact about a customer, not part of who they are. The
--    same objection kills CustomerSegment, which is a business
--    classification that is meant to change.
--
--    NOT PRACTICAL. Every table referencing a customer would carry all three
--    columns — `orders` would need CustomerName VARCHAR(50), Province
--    VARCHAR(50) and CustomerSegment VARCHAR(50) on all 8,060 rows instead
--    of one INT, and every join would be a three-column comparison of
--    strings. That is slower, larger, and far easier to get subtly wrong
--    (one mismatched trailing space and the row silently disappears).
--
--    The general lesson: uniqueness is the EASIEST criterion to satisfy and
--    the least important. Stability is what actually decides it.

-- ==========================================================================
-- PART B — Auditing this lab's own keys
-- ==========================================================================

-- 6. Is (OrderID, ProductID) unique?  -> NO. 8060 rows, 8058 pairs.
SELECT COUNT(*) AS rows_in_table,
       COUNT(DISTINCT OrderID, ProductID) AS distinct_pairs
FROM orders;
--    -> 8060 | 8058
--
--    Only two collisions in eight thousand rows — which is exactly the kind
--    of near-miss that makes people declare the key anyway.

-- 7. The offenders.
SELECT OrderID, ProductID, COUNT(*) AS line_count
FROM orders
GROUP BY OrderID, ProductID
HAVING COUNT(*) > 1;
--    -> 32800 | 410393 | 2
--       37603 | 403940 | 2

SELECT LineID, OrderID, ProductID, OrderDate, OrderQuantity, Sales, UnitPrice, Discount
FROM orders
WHERE (OrderID, ProductID) IN (
    SELECT OrderID, ProductID FROM orders
    GROUP BY OrderID, ProductID HAVING COUNT(*) > 1)
ORDER BY OrderID, LineID;
--    -> 5400 | 32800 | 410393 | 2009-01-21 | 19 |  354.13 | 19.98 | 0.09
--       5401 | 32800 | 410393 | 2009-01-21 | 40 |  751.94 | 19.98 | 0.07
--       7987 | 37603 | 403940 | 2010-11-24 | 50 | 2440.26 | 45.19 | 0.00
--       7988 | 37603 | 403940 | 2010-11-24 | 23 | 1008.19 | 45.19 | 0.03
--
--    LOOK AT THE DISCOUNT COLUMN. In both cases the same product appears
--    twice on the same order, same date, same unit price — but at DIFFERENT
--    DISCOUNTS (0.09 vs 0.07; 0.00 vs 0.03).
--
--    That is not corruption. It is a legitimate and common business
--    situation: 19 units at one discount tier and 40 at another, or part of
--    the line fulfilled from different stock under a different agreement.
--    Merging them into one row would destroy real information — you could
--    not reproduce either the price breakdown or the totals.
--    (It is not PROOF of legitimacy either; two rows could be a duplicated
--    import. But identical unit price with deliberately different discounts
--    looks like intent, not accident.)

-- 8. Why the surrogate was right.
--    An order LINE is not identified by which product it is for. Two lines
--    can legitimately reference the same product, so no combination of the
--    table's own business columns identifies a row — the entity simply has
--    no natural key. That is precisely when you invent one.
--
--    HAD SOMEONE DECLARED PRIMARY KEY (OrderID, ProductID): the load of
--    these four rows would have failed with ERROR 1062 on the second of each
--    pair. And the likely response — under time pressure, mid-import — is
--    the damaging one: "de-duplicate the source", quietly dropping the
--    second line of each order. Revenue for those two orders would be
--    understated by 751.94 and 1008.19, permanently, with no error left
--    behind to explain it.
--    A too-strict key does not just reject bad data; it rejects good data,
--    and the workaround is usually silent data loss.

-- 9. Is ProductName unique?  -> YES. 1234 rows, 1234 distinct names.
SELECT COUNT(*) AS rows_in_table,
       COUNT(DISTINCT ProductName) AS distinct_names
FROM products;
--    -> 1234 | 1234
--
--    UNIQUE, BUT STILL A POOR PRIMARY KEY. It passes uniqueness and fails
--    almost everything else:
--      * NOT STABLE — products get renamed constantly ("Xerox 1890" becomes
--        "Xerox 1890 (Discontinued)"). Renaming would cascade into every
--        order line.
--      * WIDE — these names run to 50+ characters, repeated on all 8,060
--        order rows and in every index, versus 4 bytes for an INT.
--      * FRAGILE — trailing spaces, case, and punctuation differences all
--        create phantom mismatches on join.
--      * UNIQUE TODAY IS NOT UNIQUE TOMORROW. Nothing in the schema PREVENTS
--        a duplicate name; the data merely happens not to contain one yet.
--        A key must be guaranteed by a constraint, not by luck.
--    If the business genuinely needs names unique, the right move is what
--    the schema does: surrogate ProductID as the key, and add a UNIQUE
--    constraint on the name to enforce the business rule separately.

-- 10. What `returns.OrderID` as a primary key asserts.
--     It asserts that an order can be returned AT MOST ONCE, and that a
--     return applies to the WHOLE order — there is nowhere to record which
--     product came back, or how many units, or a second return event.
--
--     IS THAT SAFE? Only if the business truly works that way. For a
--     multi-line order — and most orders here have several lines — "the
--     order was returned" is a much weaker statement than it looks. A
--     customer returning one item of five is either recorded as returning
--     everything, or not recorded at all. Both distort any return-rate
--     analysis, and worksheet 07 has you compute exactly such a rate on this
--     very table.
--     The honest model is a return keyed by (OrderID, ProductID) or by its
--     own surrogate, referencing the order LINE rather than the order.

-- ==========================================================================
-- PART C — Making the choice yourself
-- ==========================================================================

CREATE DATABASE IF NOT EXISTS practice_yourname;
USE practice_yourname;

-- 11. Two ways to key a country table.
--     a) natural:
CREATE TABLE country_natural (
    iso_code   CHAR(2) PRIMARY KEY,
    name       VARCHAR(80) NOT NULL,
    population BIGINT
);
--     b) surrogate + unique:
CREATE TABLE country_surrogate (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    iso_code   CHAR(2) NOT NULL UNIQUE,
    name       VARCHAR(80) NOT NULL,
    population BIGINT
);
INSERT INTO country_natural VALUES ('CA','Canada',40000000),('BR','Brazil',215000000);
SELECT * FROM country_natural;

--     WHICH WOULD I SHIP? The natural key, and this is the exception that
--     proves the rule. ISO 3166-1 alpha-2 codes are:
--       * genuinely stable — governed by a standard body, changes are
--         extraordinarily rare and newsworthy;
--       * fixed width and tiny (CHAR(2) — smaller than an INT);
--       * already meaningful to every system you will exchange data with,
--         so a join is often unnecessary: `WHERE iso_code = 'CA'` reads
--         correctly with no lookup at all.
--     That last point is the real prize. A surrogate key here buys you
--     insulation from a change that essentially never happens, at the cost
--     of a join on every single query.
--     THE HONEST CAVEAT: "essentially never" is not never. Codes have been
--     reassigned (CS, YU) after political change. If you needed to survive
--     that cleanly, choice (b) is the safer engineering decision — and that
--     tension is the whole natural-vs-surrogate debate in one example.

-- 12. Enrolment, both ways.
CREATE TABLE student (student_id INT PRIMARY KEY, name VARCHAR(50));
CREATE TABLE course  (course_id  INT PRIMARY KEY, title VARCHAR(50));
INSERT INTO student VALUES (1,'Ana');
INSERT INTO course  VALUES (10,'SQL');

--     a) composite natural key:
CREATE TABLE enrolment_natural (
    student_id  INT,
    course_id   INT,
    enrolled_on DATE NOT NULL,
    grade       CHAR(2),
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES student(student_id),
    FOREIGN KEY (course_id)  REFERENCES course(course_id)
);
INSERT INTO enrolment_natural VALUES (1,10,'2026-01-10',NULL);
INSERT INTO enrolment_natural VALUES (1,10,'2026-02-01',NULL);
--    -> ERROR 1062 (23000): Duplicate entry '1-10' for key
--       'enrolment_natural.PRIMARY'

--     b) surrogate + unique constraint:
CREATE TABLE enrolment_surrogate (
    enrolment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id   INT NOT NULL,
    course_id    INT NOT NULL,
    enrolled_on  DATE NOT NULL,
    grade        CHAR(2),
    CONSTRAINT uq_student_course UNIQUE (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES student(student_id),
    FOREIGN KEY (course_id)  REFERENCES course(course_id)
);
INSERT INTO enrolment_surrogate (student_id,course_id,enrolled_on) VALUES (1,10,'2026-01-10');
INSERT INTO enrolment_surrogate (student_id,course_id,enrolled_on) VALUES (1,10,'2026-02-01');
--    -> ERROR 1062 (23000): Duplicate entry '1-10' for key
--       'enrolment_surrogate.uq_student_course'
--
--    BOTH ENFORCE THE RULE, and the error is nearly identical — note the
--    second names YOUR constraint rather than 'PRIMARY', which is a small
--    but real diagnostic win.

-- 13. When the rule changes: retakes are now allowed.
--     THE SURROGATE VERSION IS FAR EASIER. The rule lives in one named
--     constraint that can be replaced, and no other table references it.
--
--     BUT THE OBVIOUS ORDER FAILS. Dropping the old constraint first gives:
--        ERROR 1553 (HY000): Cannot drop index 'uq_student_course':
--        needed in a foreign key constraint
--     because InnoDB was using that composite index to support the foreign
--     key on `student_id` — an FK needs an index whose LEFTMOST column is
--     the referencing column, and uq_student_course (student_id, course_id)
--     was quietly serving that purpose as well as enforcing uniqueness.
--     One index, two jobs; dropping it would leave the FK unsupported.
--
--     ADD THE REPLACEMENT FIRST. The new index also starts with student_id,
--     so once it exists the FK has what it needs and the old one is free:
ALTER TABLE enrolment_surrogate
    ADD CONSTRAINT uq_student_course_term UNIQUE (student_id, course_id, enrolled_on);
ALTER TABLE enrolment_surrogate DROP INDEX uq_student_course;
INSERT INTO enrolment_surrogate (student_id,course_id,enrolled_on) VALUES (1,10,'2026-02-01');
SELECT enrolment_id, student_id, course_id, enrolled_on FROM enrolment_surrogate;
--    -> the retake is now accepted; existing rows and their ids are untouched:
--       1 | 1 | 10 | 2026-01-10
--       2 | 1 | 10 | 2026-02-01
--
--    Worth keeping: constraints and indexes are not the same thing, but in
--    MySQL a UNIQUE constraint IS implemented as an index, and other things
--    may be leaning on that index without saying so. Always add before you
--    drop — the reverse order fails on exactly the tables that matter most,
--    the ones with foreign keys pointing into them.
--
--    In the NATURAL version the same change means altering the PRIMARY KEY
--    itself — and any table referencing an enrolment (a grade history, an
--    attendance record, a payment) holds the two-column key as a foreign
--    key, so every one of them must gain a third column, in lockstep, in one
--    migration.
--
--    THE GENERAL PRINCIPLE, and the real reason surrogates usually win:
--    a primary key is a promise about IDENTITY, while a unique constraint is
--    a statement of a BUSINESS RULE. Business rules change; identity must
--    not. Encoding a rule into the primary key welds the two together, and
--    you discover the cost only when the rule moves.

-- 14. Clean up.
DROP DATABASE practice_yourname;
