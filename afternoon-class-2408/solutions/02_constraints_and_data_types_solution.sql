-- ==========================================================================
-- Afternoon class 24/08 — Worksheet 02 SOLUTIONS: constraints and data types
-- ==========================================================================
-- Every statement below was executed against this lab's MySQL; the quoted
-- errors and outputs are real, including the exact error numbers.
-- ==========================================================================

CREATE DATABASE IF NOT EXISTS practice_yourname;
USE practice_yourname;

-- ==========================================================================
-- PART A — Choosing a type
-- ==========================================================================

-- 1. Money and FLOAT.
CREATE TABLE money_test (f FLOAT, d DECIMAL(10,2));
INSERT INTO money_test VALUES (0.1, 0.1), (0.2, 0.2);
SELECT SUM(f) AS float_sum, SUM(d) AS decimal_sum, SUM(f) = 0.3 AS float_equals_point3
FROM money_test;
--    -> float_sum 0.30000000447034836 | decimal_sum 0.30 | float_equals_point3 0
--
--    The FLOAT sum is not 0.3, and the equality test returns 0 (false).
--    WHY: FLOAT is binary floating point. 0.1 has no exact representation in
--    base 2, exactly as 1/3 has none in base 10. Every arithmetic step
--    carries a tiny error, and the errors accumulate.
--    DECIMAL stores digits, not a binary approximation, so 0.1 + 0.2 is
--    exactly 0.30.
--
--    THE RULE: never store money in FLOAT or DOUBLE. Use DECIMAL(p, s).
--    The failure mode is nasty — an invoice that is off by 0.01, a
--    reconciliation that never balances, a `WHERE total = 100.00` that
--    matches nothing while the row plainly shows 100.00.

-- 2. How this lab types its own columns.
DESCRIBE superstore.orders;
--    -> Sales DECIMAL(15,5), OrderDate DATE, ShipMode VARCHAR(20) ...
--
--    Two things a real DATE gives you that text does not:
--      * DATE ARITHMETIC AND COMPARISON. `WHERE OrderDate >= '2012-01-01'`,
--        `OrderDate + INTERVAL 1 MONTH`, MONTH(OrderDate), DATEDIFF(...).
--        On a VARCHAR, '2012-1-4' and '2012-01-04' are different strings,
--        and any comparison is alphabetical: '2012-1-9' > '2012-10-1'.
--      * VALIDATION. A DATE column rejects '2012-02-31'. A VARCHAR accepts
--        it, along with 'yesterday', '' and 'N/A'.
--    Storing a date as text moves the work into every query that touches it,
--    forever, and moves the validation nowhere.

-- 3. Phone numbers: VARCHAR, always.
--    An INT drops the leading zero (0044... becomes 44...), cannot hold '+',
--    spaces, parentheses or extensions, and silently overflows past
--    2147483647. It also invites arithmetic that is meaningless — you will
--    never add two phone numbers.
--    THE GENERAL RULE: use a numeric type when you would do MATHS on the
--    value. Identifiers that happen to be made of digits — phone numbers,
--    postcodes, national IDs, product codes — are text.

-- ==========================================================================
-- PART B — Constraints that catch mistakes
-- ==========================================================================

-- 4. NOT NULL, DEFAULT, AUTO_INCREMENT, UNIQUE.
CREATE TABLE member (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(80)  NOT NULL,
    email     VARCHAR(120) UNIQUE,
    joined_on DATE         NOT NULL DEFAULT (CURRENT_DATE),
    status    VARCHAR(20)  NOT NULL DEFAULT 'active'
);

INSERT INTO member (full_name, email) VALUES ('Ana Silva', 'ana@example.com');
SELECT * FROM member;
--    -> 1 | Ana Silva | ana@example.com | <today's date> | active
--
--    Three columns were filled in without being mentioned: the key by
--    AUTO_INCREMENT, and two by DEFAULT. Defaults are how you make the
--    common case require no thought while still forbidding NULL.
--    (Note the parentheses in DEFAULT (CURRENT_DATE) — a function default
--    needs them; MySQL only allowed literal defaults before 8.0.13.)

-- 5. Duplicate email.
INSERT INTO member (full_name, email) VALUES ('Ana Again', 'ana@example.com');
--    -> ERROR 1062 (23000): Duplicate entry 'ana@example.com' for key
--       'member.email'
--
--    The message names the KEY that was violated — `member.email` — and the
--    exact value that collided. That is why naming your constraints matters
--    on bigger tables: the error is only as diagnosable as the key's name.
--    ERROR 1062 always means "a unique index rejected this", whether that
--    index is a PRIMARY KEY or a UNIQUE constraint.

-- 6. Two NULL emails.
INSERT INTO member (full_name, email) VALUES ('No Email One', NULL);
INSERT INTO member (full_name, email) VALUES ('No Email Two', NULL);
SELECT member_id, full_name, email FROM member;
--    -> BOTH INSERTS SUCCEED:
--       1 | Ana Silva    | ana@example.com
--       3 | No Email One | NULL
--       4 | No Email Two | NULL
--
--    Notice member_id jumps 1 -> 3. The FAILED insert in question 5 consumed
--    id 2 and never gave it back. AUTO_INCREMENT hands out numbers, it does
--    not promise a gapless sequence — rollbacks and failed statements leave
--    holes. If your invoice numbers must have no gaps, an AUTO_INCREMENT
--    column cannot give you that; it is an identifier, not a counter.
--
--    WHY: UNIQUE forbids two rows having the SAME value. NULL is not a
--    value — it means "unknown". Two unknowns are not known to be equal, so
--    the constraint has nothing to object to. This is the same three-valued
--    logic that makes `NULL = NULL` return NULL rather than TRUE.
--
--    CONSEQUENCE: "email must be unique AND always present" needs BOTH
--    UNIQUE and NOT NULL. Writing only UNIQUE leaves a hole you will find
--    the hard way, usually as a pile of rows with a missing identifier.

-- 7. PRIMARY KEY vs UNIQUE — two differences.
--      * A PRIMARY KEY is implicitly NOT NULL; a UNIQUE column accepts NULLs
--        (as many as you like, per question 6).
--      * A table has at most ONE primary key, but any number of UNIQUE
--        constraints. The primary key is the row's identity; UNIQUE
--        expresses any other "no duplicates here" rule.
--    Practically: the primary key is also what foreign keys point at, and
--    what the storage engine clusters the table by in InnoDB.

-- 8. CHECK constraints.
CREATE TABLE product_price (
    product_id INT PRIMARY KEY,
    price      DECIMAL(10,2) NOT NULL CHECK (price > 0)
);
INSERT INTO product_price VALUES (1, 19.99);   -- fine
INSERT INTO product_price VALUES (2, -5.00);
--    -> ERROR 3819 (HY000): Check constraint 'product_price_chk_1' is violated.
--
--    Verified enforced on this server. CHECK was accepted-but-ignored before
--    MySQL 8.0.16, which is a genuinely dangerous history: the same DDL runs
--    without complaint on an old server and enforces nothing. If you inherit
--    a schema, test a violating INSERT rather than trusting the CHECK is live.
--    MySQL auto-names the constraint `<table>_chk_<n>`; name it yourself
--    (CONSTRAINT price_positive CHECK (...)) so the error tells a human
--    reader what rule they broke.

-- ==========================================================================
-- PART C — Foreign keys and what happens on delete
-- ==========================================================================

-- 9. The default: RESTRICT.
CREATE TABLE team (
    team_id INT PRIMARY KEY,
    name    VARCHAR(50) NOT NULL
);
CREATE TABLE player (
    player_id INT PRIMARY KEY,
    name      VARCHAR(50) NOT NULL,
    team_id   INT,
    FOREIGN KEY (team_id) REFERENCES team(team_id)
);
INSERT INTO team   VALUES (1, 'Rovers');
INSERT INTO player VALUES (1, 'Ana', 1);

DELETE FROM team WHERE team_id = 1;
--    -> ERROR 1451 (23000): Cannot delete or update a parent row: a foreign
--       key constraint fails (`practice_yourname`.`player`, CONSTRAINT
--       `player_ibfk_1` FOREIGN KEY (`team_id`) REFERENCES `team` (`team_id`))
--
--    The default action is RESTRICT: the delete is refused. MySQL is
--    protecting you from ORPHANS — a player row pointing at a team_id that
--    no longer exists. Referential integrity means every FK value either is
--    NULL or names a row that really exists, and the database will not let
--    you leave it otherwise.

-- 10. The other two behaviours.
DROP TABLE player;
CREATE TABLE player (
    player_id INT PRIMARY KEY,
    name      VARCHAR(50) NOT NULL,
    team_id   INT,
    FOREIGN KEY (team_id) REFERENCES team(team_id) ON DELETE CASCADE
);
INSERT INTO player VALUES (1, 'Ana', 1);
DELETE FROM team WHERE team_id = 1;
SELECT COUNT(*) AS players_left FROM player;
--    -> 0. CASCADE deleted the player along with the team.

INSERT INTO team VALUES (1, 'Rovers');
DROP TABLE player;
CREATE TABLE player (
    player_id INT PRIMARY KEY,
    name      VARCHAR(50) NOT NULL,
    team_id   INT NULL,                        -- <- MUST be nullable
    FOREIGN KEY (team_id) REFERENCES team(team_id) ON DELETE SET NULL
);
INSERT INTO player VALUES (1, 'Ana', 1);
DELETE FROM team WHERE team_id = 1;
SELECT player_id, name, team_id FROM player;
--    -> 1 | Ana | NULL. The player survives, now unattached.
--
--    WHICH IS CORRECT for a disbanded team? SET NULL. A player is a real
--    person who continues to exist; CASCADE would delete them from your
--    records because their team folded, which is absurd. RESTRICT would
--    forbid ever disbanding a team while anyone is on it.
--    CASCADE is right when the child CANNOT MEANINGFULLY EXIST without the
--    parent — order lines without an order, an address book entry's phone
--    numbers. Ask "is this child a part of the parent, or a thing in its own
--    right?"
--    SET NULL REQUIRES the column to be nullable. Declaring team_id NOT NULL
--    and ON DELETE SET NULL is a contradiction, and MySQL rejects the DDL
--    outright rather than at delete time.

-- 11. Where this lab deliberately has no FK.
SHOW CREATE TABLE superstore.returns;
SHOW INDEX FROM superstore.orders;
--    -> On `orders`: PRIMARY on LineID (Non_unique 0), and
--       idx_orders_orderid on OrderID with Non_unique = 1.
--
--    A foreign key must reference a UNIQUELY INDEXED column — the database
--    has to be able to identify exactly ONE parent row. `orders.OrderID` is
--    indexed but NOT unique (Non_unique = 1), because one order spans
--    several rows, one per product. So `REFERENCES orders(OrderID)` is
--    rejected: which of the five rows for that order would be the parent?
--    This is not an oversight. The GRAIN of the table — one row per order
--    LINE — makes the constraint impossible, and the real fix is a separate
--    order-header table. Worksheet 03 of the morning class has you design it.

-- 12. Clean up.
DROP DATABASE practice_yourname;
