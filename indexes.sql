-- ============================================================
-- Indexes and query-plan analysis
--
-- Primary keys already get indexes automatically. These extra
-- indexes speed up the columns our queries actually filter and
-- join on. Use EXPLAIN ANALYZE to see the planner's choice.
-- ============================================================

-- Foreign-key columns used in joins
CREATE INDEX idx_marks_course   ON INTERNAL_MARKS (COURSE_CODE);
CREATE INDEX idx_marks_section  ON INTERNAL_MARKS (SEC_ID);
CREATE INDEX idx_enroll_section ON CLASS_ENROLLMENT (SEC_ID);

-- Filter columns
CREATE INDEX idx_students_city  ON STUDENTS (CITY);
CREATE INDEX idx_semsec_sem_sec ON SEM_SECTION (SEMESTER, SECTION);

-- ------------------------------------------------------------
-- Compare query plans (run these and read the output):
-- ------------------------------------------------------------

-- Query plan for a join that can use idx_marks_course:
EXPLAIN ANALYZE
SELECT s.Full_Name, im.Final_IA
FROM STUDENTS s
JOIN INTERNAL_MARKS im ON s.Roll_No = im.Roll_No
WHERE im.Course_Code = '21cs53';

-- Query plan for a filter that can use idx_students_city:
EXPLAIN ANALYZE
SELECT * FROM STUDENTS WHERE CITY = 'Rajkot';

-- NOTE: on a tiny table (5 rows) the planner will often still choose a
-- sequential scan because reading the whole table is cheaper than using
-- the index. Indexes pay off as row counts grow -- that is exactly the
-- trade-off (extra storage + slower writes vs. faster reads) to discuss
-- in an interview.

-- To list all indexes on a table:
-- \d INTERNAL_MARKS
