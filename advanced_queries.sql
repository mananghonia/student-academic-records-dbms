-- ============================================================
-- Advanced queries: subqueries, correlated subqueries, EXISTS,
-- HAVING and LEFT JOIN.
-- ============================================================

-- 1. Subquery: students who scored ABOVE the overall average Final IA.
SELECT s.Roll_No, s.Full_Name, im.Course_Code, im.Final_IA
FROM STUDENTS s
JOIN INTERNAL_MARKS im ON s.Roll_No = im.Roll_No
WHERE im.Final_IA > (SELECT AVG(Final_IA) FROM INTERNAL_MARKS);

-- 2. Correlated subquery: each student's BEST course
--    (the course where they scored their highest Final IA).
SELECT s.Roll_No, s.Full_Name, im.Course_Code, im.Final_IA
FROM STUDENTS s
JOIN INTERNAL_MARKS im ON s.Roll_No = im.Roll_No
WHERE im.Final_IA = (
    SELECT MAX(im2.Final_IA)
    FROM INTERNAL_MARKS im2
    WHERE im2.Roll_No = im.Roll_No
);

-- 3. HAVING: sections that have MORE THAN ONE student enrolled.
SELECT ss.Sec_ID, ss.Semester, ss.Section, COUNT(*) AS Total_Students
FROM SEM_SECTION ss
JOIN CLASS_ENROLLMENT ce ON ss.Sec_ID = ce.Sec_ID
GROUP BY ss.Sec_ID, ss.Semester, ss.Section
HAVING COUNT(*) > 1
ORDER BY Total_Students DESC;

-- 4. LEFT JOIN: courses in which NO marks have been recorded yet.
SELECT c.Course_Code, c.Course_Title, c.Semester
FROM COURSES c
LEFT JOIN INTERNAL_MARKS im ON c.Course_Code = im.Course_Code
WHERE im.Course_Code IS NULL;

-- 5. LEFT JOIN with aggregation: every section and its student count,
--    including sections with ZERO students.
SELECT ss.Sec_ID, ss.Semester, ss.Section, COUNT(ce.Roll_No) AS Total_Students
FROM SEM_SECTION ss
LEFT JOIN CLASS_ENROLLMENT ce ON ss.Sec_ID = ce.Sec_ID
GROUP BY ss.Sec_ID, ss.Semester, ss.Section
ORDER BY ss.Semester, ss.Section;

-- 6. NOT EXISTS: students who have NO internal marks entered at all.
SELECT s.Roll_No, s.Full_Name
FROM STUDENTS s
WHERE NOT EXISTS (
    SELECT 1 FROM INTERNAL_MARKS im WHERE im.Roll_No = s.Roll_No
);

-- 7. Nested aggregate subquery: the course with the HIGHEST average Final IA.
SELECT c.Course_Code, c.Course_Title, AVG(im.Final_IA) AS Avg_Final_IA
FROM COURSES c
JOIN INTERNAL_MARKS im ON c.Course_Code = im.Course_Code
GROUP BY c.Course_Code, c.Course_Title
HAVING AVG(im.Final_IA) = (
    SELECT MAX(course_avg)
    FROM (
        SELECT AVG(Final_IA) AS course_avg
        FROM INTERNAL_MARKS
        GROUP BY Course_Code
    ) AS averages
);

-- 8. IN subquery: details of students enrolled in semester 3.
SELECT s.Roll_No, s.Full_Name, s.City
FROM STUDENTS s
WHERE s.Roll_No IN (
    SELECT ce.Roll_No
    FROM CLASS_ENROLLMENT ce
    JOIN SEM_SECTION ss ON ce.Sec_ID = ss.Sec_ID
    WHERE ss.Semester = 3
);
