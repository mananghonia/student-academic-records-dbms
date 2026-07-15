-- ============================================
-- Student Academic Records DBMS - Complete Script
-- (DDL + Trigger + DML + Queries in one file)
-- ============================================

-- Create STUDENTS table
CREATE TABLE STUDENTS (
    ROLL_NO VARCHAR(10) PRIMARY KEY,
    FULL_NAME VARCHAR(25) NOT NULL,
    CITY VARCHAR(25),
    MOBILE VARCHAR(10) UNIQUE CHECK (MOBILE ~ '^[0-9]{10}$'),
    GENDER CHAR(1) NOT NULL CHECK (GENDER IN ('M', 'F'))
);

-- Create SEM_SECTION table
CREATE TABLE SEM_SECTION (
    SEC_ID VARCHAR(5) PRIMARY KEY,
    SEMESTER INTEGER NOT NULL CHECK (SEMESTER BETWEEN 1 AND 8),
    SECTION CHAR(1) NOT NULL CHECK (SECTION IN ('A', 'B', 'C'))
);

-- Create CLASS_ENROLLMENT table
CREATE TABLE CLASS_ENROLLMENT (
    ROLL_NO VARCHAR(10),
    SEC_ID VARCHAR(5),
    PRIMARY KEY (ROLL_NO, SEC_ID),
    FOREIGN KEY (ROLL_NO) REFERENCES STUDENTS(ROLL_NO) ON DELETE CASCADE,
    FOREIGN KEY (SEC_ID) REFERENCES SEM_SECTION(SEC_ID) ON DELETE CASCADE
);

-- Create COURSES table
CREATE TABLE COURSES (
    COURSE_CODE VARCHAR(8) PRIMARY KEY,
    COURSE_TITLE VARCHAR(20) NOT NULL,
    SEMESTER INTEGER NOT NULL CHECK (SEMESTER BETWEEN 1 AND 8),
    CREDITS INTEGER NOT NULL CHECK (CREDITS BETWEEN 1 AND 5)
);

-- Create INTERNAL_MARKS table
CREATE TABLE INTERNAL_MARKS (
    ROLL_NO VARCHAR(10),
    COURSE_CODE VARCHAR(8),
    SEC_ID VARCHAR(5),
    TEST1 INTEGER CHECK (TEST1 BETWEEN 0 AND 25),
    TEST2 INTEGER CHECK (TEST2 BETWEEN 0 AND 25),
    TEST3 INTEGER CHECK (TEST3 BETWEEN 0 AND 25),
    FINAL_IA INTEGER CHECK (FINAL_IA BETWEEN 0 AND 25),
    PRIMARY KEY (ROLL_NO, COURSE_CODE, SEC_ID),
    FOREIGN KEY (ROLL_NO) REFERENCES STUDENTS(ROLL_NO) ON DELETE CASCADE,
    FOREIGN KEY (COURSE_CODE) REFERENCES COURSES(COURSE_CODE) ON DELETE CASCADE,
    FOREIGN KEY (SEC_ID) REFERENCES SEM_SECTION(SEC_ID) ON DELETE CASCADE
);

-- Trigger: automatically compute FINAL_IA (average of best two tests)
CREATE OR REPLACE FUNCTION compute_final_ia()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.TEST1 IS NULL OR NEW.TEST2 IS NULL OR NEW.TEST3 IS NULL THEN
        NEW.FINAL_IA := NULL;
    ELSE
        NEW.FINAL_IA := ROUND(
            (NEW.TEST1 + NEW.TEST2 + NEW.TEST3
             - LEAST(NEW.TEST1, NEW.TEST2, NEW.TEST3)) / 2.0
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_compute_final_ia
BEFORE INSERT OR UPDATE OF TEST1, TEST2, TEST3 ON INTERNAL_MARKS
FOR EACH ROW
EXECUTE FUNCTION compute_final_ia();

-- Insert values into STUDENTS table
INSERT INTO STUDENTS VALUES ('gec21cs011', 'Manan', 'Rajkot', '9824105536', 'M');
INSERT INTO STUDENTS VALUES ('gec21cs024', 'Priya', 'Surat', '9106442718', 'F');
INSERT INTO STUDENTS VALUES ('gec22me047', 'Rohan', 'Ahmedabad', '7859663120', 'M');
INSERT INTO STUDENTS VALUES ('gec20ec038', 'Sneha', 'Vadodara', '9512078465', 'F');
INSERT INTO STUDENTS VALUES ('gec21ee052', 'Aditya', 'Bhavnagar', '9033551247', 'M');

-- Insert values into SEM_SECTION table
INSERT INTO SEM_SECTION VALUES ('5A', 5, 'A');
INSERT INTO SEM_SECTION VALUES ('3B', 3, 'B');
INSERT INTO SEM_SECTION VALUES ('7A', 7, 'A');
INSERT INTO SEM_SECTION VALUES ('2C', 2, 'C');
INSERT INTO SEM_SECTION VALUES ('4B', 4, 'B');
INSERT INTO SEM_SECTION VALUES ('4C', 4, 'C');

-- Insert values into CLASS_ENROLLMENT table
INSERT INTO CLASS_ENROLLMENT VALUES ('gec21cs011', '5A');
INSERT INTO CLASS_ENROLLMENT VALUES ('gec21cs024', '5A');
INSERT INTO CLASS_ENROLLMENT VALUES ('gec22me047', '3B');
INSERT INTO CLASS_ENROLLMENT VALUES ('gec20ec038', '7A');
INSERT INTO CLASS_ENROLLMENT VALUES ('gec21ee052', '3B');
INSERT INTO CLASS_ENROLLMENT VALUES ('gec21ee052', '4C');
INSERT INTO CLASS_ENROLLMENT VALUES ('gec21cs024', '4C');

-- Insert values into COURSES table
INSERT INTO COURSES VALUES ('21CS81', 'ML', 8, 4);
INSERT INTO COURSES VALUES ('21cs53', 'Dbms', 5, 4);
INSERT INTO COURSES VALUES ('21cs33', 'Dsa', 3, 4);
INSERT INTO COURSES VALUES ('21cs34', 'Coa', 3, 4);
INSERT INTO COURSES VALUES ('21cs158', 'Python', 5, 2);
INSERT INTO COURSES VALUES ('21cs71', 'Ai', 7, 4);

-- Insert values into INTERNAL_MARKS table
-- (FINAL_IA is filled in automatically by the trigger)
INSERT INTO INTERNAL_MARKS VALUES ('gec21cs011', '21cs53', '5A', 17, 20, 14, NULL);
INSERT INTO INTERNAL_MARKS VALUES ('gec21cs024', '21cs53', '5A', 16, 15, 18, NULL);
INSERT INTO INTERNAL_MARKS VALUES ('gec22me047', '21cs33', '3B', 11, 14, 17, NULL);
INSERT INTO INTERNAL_MARKS VALUES ('gec20ec038', '21cs71', '7A', 19, 18, 20, NULL);
INSERT INTO INTERNAL_MARKS VALUES ('gec21ee052', '21cs33', '3B', 15, 19, 18, NULL);
INSERT INTO INTERNAL_MARKS VALUES ('gec21ee052', '21cs53', '4C', 20, 18, 19, NULL);

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
--    NOTE: the trg_compute_final_ia trigger already computes Final_IA automatically,
--    so this manual UPDATE affects 0 rows. It is kept to show the set-based calculation.
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
