# Student Academic Records Management System

This project implements a Student Academic Records Management System using PostgreSQL. It includes SQL scripts for table creation, data insertion, and various queries, designed using normalization principles.

## Project Structure

The project is divided into the following SQL script files:

1. **ddl.sql**: Contains Data Definition Language (DDL) commands for creating tables.
2. **dml.sql**: Contains Data Manipulation Language (DML) commands for inserting data into the tables.
3. **queries.sql**: Contains various SQL queries for retrieving and manipulating data.
4. **all_student_records_dbms.sql**: The complete script (DDL + DML + queries) in a single file.

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

## How to Run

1. Install PostgreSQL: Make sure PostgreSQL is installed on your system.
2. Create Database: Create a new database in PostgreSQL (e.g. `student_records`).
3. Execute DDL Script: Run the `ddl.sql` script to create the tables.
4. Execute DML Script: Run the `dml.sql` script to insert data into the tables.
5. Execute Queries: Run the `queries.sql` script to perform the various queries.

Alternatively, run everything at once:

```sh
psql -d student_records -f all_student_records_dbms.sql
```
