# Student Academic Records Management System

**🌐 Live demo: https://student-academic-records.streamlit.app** (Streamlit Community Cloud + Neon serverless PostgreSQL)

This project implements a Student Academic Records Management System using PostgreSQL, with a Streamlit web app on top for CRUD operations. It includes SQL scripts for table creation with integrity constraints, a PL/pgSQL trigger, data insertion, advanced queries, indexing and transactions — all designed using normalization principles.

## Project Structure

The project is divided into the following SQL script files:

1. **ddl.sql**: Data Definition Language (DDL) commands for creating tables, with integrity constraints (`CHECK`, `NOT NULL`, `UNIQUE`, `ON DELETE CASCADE`).
2. **triggers.sql**: PL/pgSQL trigger that automatically computes `FINAL_IA` on every insert/update of test marks.
3. **dml.sql**: Data Manipulation Language (DML) commands for inserting data into the tables.
4. **queries.sql**: The five core queries for retrieving and manipulating data.
5. **advanced_queries.sql**: Subqueries, correlated subqueries, `EXISTS`, `HAVING` and `LEFT JOIN` examples.
6. **indexes.sql**: Secondary indexes plus `EXPLAIN ANALYZE` query-plan comparisons.
7. **transactions.sql**: `BEGIN` / `COMMIT` / `ROLLBACK` / `SAVEPOINT` demonstration (ACID).
8. **all_student_records_dbms.sql**: The complete script (DDL + trigger + DML + queries) in a single file.
9. **app.py**: Streamlit web app for CRUD on the database (see below).

## Tables

The database consists of the following tables:

- `STUDENTS`: Stores details of students.
- `SEM_SECTION`: Stores information about semesters and sections.
- `CLASS_ENROLLMENT`: Stores information about which student is enrolled in which class.
- `COURSES`: Stores details about courses.
- `INTERNAL_MARKS`: Stores internal assessment marks of students.

## Entity Relationship Diagram

![ER Diagram](er_diagram.svg)

## Entity Relationship Overview

- A student (`STUDENTS`) can be enrolled in multiple semester-sections through `CLASS_ENROLLMENT` (many-to-many).
- Each course (`COURSES`) belongs to a semester.
- `INTERNAL_MARKS` records the three internal test marks of a student for a course in a particular section, along with the computed final internal assessment (best two of three tests).

## Normalization

The schema is in **Third Normal Form (3NF)**:

- **1NF** — every attribute holds a single atomic value; there are no repeating groups (the three tests are separate graded events recorded as separate columns of one marks entry, and each row is uniquely identified by a primary key).
- **2NF** — no partial dependencies on a composite key. In `INTERNAL_MARKS` (key: `ROLL_NO, COURSE_CODE, SEC_ID`) every non-key attribute (the test marks) depends on the *whole* key — a mark is meaningless without knowing the student, the course, *and* the section. Student details like `FULL_NAME` are kept in `STUDENTS`, not repeated in `INTERNAL_MARKS`, precisely because they depend only on `ROLL_NO`.
- **3NF** — no transitive dependencies: in `STUDENTS` every non-key attribute depends directly on `ROLL_NO` alone; in `COURSES` everything depends on `COURSE_CODE` alone.
- The **many-to-many** relationship between students and semester-sections is resolved through the junction table `CLASS_ENROLLMENT`, instead of storing lists of sections inside `STUDENTS`.

## Data Integrity (Constraints)

Defined in `ddl.sql`:

- `CHECK` constraints: test marks must be 0–25, semester 1–8, section A/B/C, gender M/F, credits 1–5, mobile must be exactly 10 digits.
- `NOT NULL` on essential attributes (name, gender, semester, course title, …).
- `UNIQUE` on student mobile numbers.
- `FOREIGN KEY ... ON DELETE CASCADE`: deleting a student automatically removes their enrollments and marks, so no orphan rows can exist.

## Trigger (Automatic Final IA)

`triggers.sql` defines a `BEFORE INSERT OR UPDATE` trigger on `INTERNAL_MARKS`. Whenever test marks are inserted or changed, the trigger recomputes `FINAL_IA` as the average of the best two of the three tests (or `NULL` until all three tests have marks). The stored value can therefore never go stale.

## Indexes & Query Optimization

`indexes.sql` creates secondary indexes on the join columns (`COURSE_CODE`, `SEC_ID`) and filter columns (`CITY`, `(SEMESTER, SECTION)`), and uses `EXPLAIN ANALYZE` to inspect the query plans. On tiny tables PostgreSQL prefers sequential scans; the indexes demonstrate the read-speed vs. write-cost trade-off that matters at scale.

## Transactions (ACID)

`transactions.sql` demonstrates atomicity: a multi-statement admission (`INSERT` student + `INSERT` enrollment) committed as one unit, a `DELETE` safely undone with `ROLLBACK`, and partial undo inside a transaction using `SAVEPOINT`.

## SQL Scripts

### DDL (Data Definition Language)

The `ddl.sql` file contains SQL commands to create the tables.

### DML (Data Manipulation Language)

The `dml.sql` file contains SQL commands to insert/update/delete data in the tables.

### DQL (Data Query Language)

The `queries.sql` file contains SQL commands to fetch data from the tables:

1. List all student details studying in fourth semester 'C' section.
2. Compute the total number of male and female students in each semester and section.
3. Create a view of Test1 marks of a given student in all courses.
4. Calculate the Final IA (average of the best two test marks) and update the table for all students.
5. Categorize 8th semester students as Outstanding / Average / Weak based on their Final IA.

## Web App (Streamlit)

`app.py` is a Streamlit front-end over the same database, demonstrating the full CRUD cycle:

- **Dashboard** — student/course/section/marks counts, average Final IA per course, students per section.
- **Students** — list, add (validated by the database's CHECK constraints) and delete (cascades to enrollments and marks).
- **Enrollments** — enroll students into semester-sections.
- **Enter Marks** — record the three test marks; `FINAL_IA` is filled in by the database trigger, not the app.
- **Report Card** — per-student marks with the Outstanding/Average/Weak category.

Every statement uses **parameterized queries** (`%s` placeholders via psycopg2) — user input is never concatenated into SQL, which prevents SQL injection.

### Screenshots

![Dashboard](screenshots/dashboard.png)

![Report Card](screenshots/report_card.png)

![Enter Marks](screenshots/enter_marks.png)

### Running the app

```sh
pip install -r requirements.txt
streamlit run app.py
```

The app connects to `localhost:5432 / student_records / postgres` by default; override with a `DATABASE_URL` (environment variable or Streamlit secret) or the standard `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` environment variables.

### Deployment

The live demo runs on **Streamlit Community Cloud** (deployed straight from this repo) with the database hosted on **Neon** (serverless PostgreSQL, free tier). The connection string is supplied to the app as the `DATABASE_URL` Streamlit secret — no credentials live in the repository.

## How to Run

1. Install PostgreSQL: Make sure PostgreSQL is installed on your system.
2. Create Database: Create a new database in PostgreSQL (e.g. `student_records`).
3. Run `ddl.sql` to create the tables with their constraints.
4. Run `triggers.sql` to install the Final IA trigger.
5. Run `dml.sql` to insert data (the trigger fills in `FINAL_IA` automatically).
6. Run `queries.sql`, `advanced_queries.sql`, `indexes.sql` and `transactions.sql` to explore the queries.

Alternatively, run everything at once:

```sh
psql -d student_records -f all_student_records_dbms.sql
```
