-- 1. List all the student details studying in fourth semester 'C' section.
SELECT s.Roll_No, s.Full_Name, s.City, s.Mobile, s.Gender
FROM STUDENTS s
JOIN CLASS_ENROLLMENT ce ON s.Roll_No = ce.Roll_No
JOIN SEM_SECTION ss ON ce.Sec_ID = ss.Sec_ID
WHERE ss.Semester = 4 AND ss.Section = 'C';

-- 2. Compute the total number of male and female students in each semester and in each section.
SELECT ss.Semester, ss.Section, s.Gender, COUNT(*) AS Total
FROM STUDENTS s
JOIN CLASS_ENROLLMENT ce ON s.Roll_No = ce.Roll_No
JOIN SEM_SECTION ss ON ce.Sec_ID = ss.Sec_ID
GROUP BY ss.Semester, ss.Section, s.Gender
ORDER BY ss.Semester, ss.Section, s.Gender;

-- 3. Create a view of Test1 marks of student Roll No 'gec21cs011' in all courses.
CREATE VIEW Test1_Report AS
SELECT Course_Code, Test1
FROM INTERNAL_MARKS
WHERE Roll_No = 'gec21cs011';

-- To see the view
SELECT * FROM Test1_Report;

-- 4. Calculate the Final_IA (average of best two test marks) and update the corresponding table for all students.
--    NOTE: with triggers.sql installed, the trg_compute_final_ia trigger computes Final_IA
--    automatically on every INSERT/UPDATE, so this manual UPDATE affects 0 rows.
--    It is kept to show the set-based calculation.
UPDATE INTERNAL_MARKS
SET Final_IA = ROUND((Test1 + Test2 + Test3 - LEAST(Test1, Test2, Test3)) / 2.0)
WHERE Final_IA IS NULL;

-- 5. Categorize students based on the following criterion for 8th semester A, B, and C section students:
--    If Final_IA = 17 to 20 then CATEGORY = 'Outstanding'
--    If Final_IA = 12 to 16 then CATEGORY = 'Average'
--    If Final_IA < 12 then CATEGORY = 'Weak'

SELECT s.Roll_No, s.Full_Name, s.City, s.Mobile, s.Gender,
       CASE
           WHEN im.Final_IA BETWEEN 17 AND 20 THEN 'Outstanding'
           WHEN im.Final_IA BETWEEN 12 AND 16 THEN 'Average'
           ELSE 'Weak'
       END AS CATEGORY
FROM STUDENTS s
JOIN CLASS_ENROLLMENT ce ON s.Roll_No = ce.Roll_No
JOIN SEM_SECTION ss ON ce.Sec_ID = ss.Sec_ID
JOIN INTERNAL_MARKS im ON s.Roll_No = im.Roll_No
JOIN COURSES c ON im.Course_Code = c.Course_Code
WHERE ss.Semester = 8 AND ss.Section IN ('A', 'B', 'C');
