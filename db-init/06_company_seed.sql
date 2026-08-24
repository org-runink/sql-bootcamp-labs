-- ==========================================================================
-- company database — seed data
-- Row counts intentionally match the reference solutions used in class:
--   employee: 7   hobby: 4   hire: 6   review: 6
-- ==========================================================================

USE company;

INSERT INTO employee (employee_id, employee_name, team, salary) VALUES
(1, 'Alice Chen',     'Engineering', 95000.00),
(2, 'Bob Martinez',   'Engineering', 88000.00),
(3, 'Carol Singh',    'Sales',       72000.00),
(4, 'David Kim',      'Sales',       68000.00),
(5, 'Emma Johnson',   'Marketing',   75000.00),
(6, 'Frank Wilson',   'Marketing',   71000.00),
(7, 'Grace Lee',      'Data',        99000.00);

-- Employee 7 (Grace Lee) is a brand-new hire: no hire_year yet.
INSERT INTO hire (employee_id, hire_year) VALUES
(1, 2018),
(2, 2019),
(3, 2017),
(4, 2020),
(5, 2021),
(6, 2016);

-- Only 4 of 7 employees logged a hobby; employee 2 logged two.
INSERT INTO hobby (employee_id, hobby) VALUES
(2, 'Chess'),
(2, 'Painting'),
(5, 'Hiking'),
(7, 'Cooking');

-- Employee 7 (new hire) has no review yet.
INSERT INTO review (name, performance) VALUES
(1, 88),
(2, 91),
(3, 76),
(4, 82),
(5, 95),
(6, 71);
