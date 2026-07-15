-- ============================================================
-- Transactions: BEGIN / COMMIT / ROLLBACK / SAVEPOINT
--
-- A transaction groups statements so they succeed or fail as a
-- single atomic unit (the A in ACID).
-- ============================================================

-- 1. COMMIT: admit a new student and enroll them -- both happen, or neither.
BEGIN;

INSERT INTO STUDENTS VALUES ('gec21cs099', 'Kavya', 'Jamnagar', '9427315608', 'F');
INSERT INTO CLASS_ENROLLMENT VALUES ('gec21cs099', '5A');

COMMIT;

-- Verify: the student exists and is enrolled.
SELECT s.Roll_No, s.Full_Name, ce.Sec_ID
FROM STUDENTS s
JOIN CLASS_ENROLLMENT ce ON s.Roll_No = ce.Roll_No
WHERE s.Roll_No = 'gec21cs099';

-- 2. ROLLBACK: start deleting a student, then change your mind.
BEGIN;

DELETE FROM STUDENTS WHERE ROLL_NO = 'gec21cs099';

-- Inside the transaction the row is gone...
SELECT COUNT(*) AS during_txn FROM STUDENTS WHERE ROLL_NO = 'gec21cs099';  -- 0

ROLLBACK;

-- ...but after ROLLBACK it is back. Nothing was lost.
SELECT COUNT(*) AS after_rollback FROM STUDENTS WHERE ROLL_NO = 'gec21cs099';  -- 1

-- 3. SAVEPOINT: undo part of a transaction without losing all of it.
BEGIN;

INSERT INTO SEM_SECTION VALUES ('6A', 6, 'A');

SAVEPOINT before_enroll;

INSERT INTO CLASS_ENROLLMENT VALUES ('gec21cs099', '6A');

-- Undo only the enrollment; the new section survives.
ROLLBACK TO SAVEPOINT before_enroll;

COMMIT;

-- Verify: section 6A exists, but no one is enrolled in it.
SELECT * FROM SEM_SECTION WHERE SEC_ID = '6A';
SELECT COUNT(*) AS enrolled_in_6a FROM CLASS_ENROLLMENT WHERE SEC_ID = '6A';  -- 0
