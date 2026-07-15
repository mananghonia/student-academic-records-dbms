"""Student Academic Records - Streamlit app over the PostgreSQL database.

All SQL uses parameterized queries (%s placeholders) so user input is never
interpolated into SQL strings -- this is the standard defence against SQL
injection.

Run with:  streamlit run app.py
"""

import os

import pandas as pd
import psycopg2
import streamlit as st

DB_CONFIG = {
    "host": os.getenv("PGHOST", "localhost"),
    "port": os.getenv("PGPORT", "5432"),
    "dbname": os.getenv("PGDATABASE", "student_records"),
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD", "postgres"),
}

st.set_page_config(page_title="Student Academic Records", page_icon="🎓", layout="wide")


@st.cache_resource
def get_connection():
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True
    return conn


def fetch_df(sql: str, params=None) -> pd.DataFrame:
    """Run a SELECT and return the result as a DataFrame."""
    with get_connection().cursor() as cur:
        cur.execute(sql, params)
        columns = [desc[0] for desc in cur.description]
        return pd.DataFrame(cur.fetchall(), columns=columns)


def execute(sql: str, params=None) -> int:
    """Run an INSERT/UPDATE/DELETE and return the affected row count."""
    with get_connection().cursor() as cur:
        cur.execute(sql, params)
        return cur.rowcount


st.sidebar.title("🎓 Student Academic Records")
page = st.sidebar.radio(
    "Menu",
    ["Dashboard", "Students", "Enrollments", "Enter Marks", "Report Card"],
)
st.sidebar.caption("PostgreSQL 17 · psycopg2 · parameterized queries")


# ---------------------------------------------------------------- Dashboard
if page == "Dashboard":
    st.title("Dashboard")

    counts = fetch_df(
        """
        SELECT (SELECT COUNT(*) FROM STUDENTS)         AS students,
               (SELECT COUNT(*) FROM COURSES)          AS courses,
               (SELECT COUNT(*) FROM SEM_SECTION)      AS sections,
               (SELECT COUNT(*) FROM INTERNAL_MARKS)   AS mark_entries
        """
    ).iloc[0]

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Students", int(counts.students))
    c2.metric("Courses", int(counts.courses))
    c3.metric("Sections", int(counts.sections))
    c4.metric("Mark entries", int(counts.mark_entries))

    left, right = st.columns(2)
    with left:
        st.subheader("Average Final IA per course")
        st.dataframe(
            fetch_df(
                """
                SELECT c.Course_Code, c.Course_Title,
                       ROUND(AVG(im.Final_IA), 1) AS Avg_Final_IA,
                       COUNT(*) AS Entries
                FROM COURSES c
                JOIN INTERNAL_MARKS im ON c.Course_Code = im.Course_Code
                GROUP BY c.Course_Code, c.Course_Title
                ORDER BY Avg_Final_IA DESC
                """
            ),
            hide_index=True,
            use_container_width=True,
        )
    with right:
        st.subheader("Students per section")
        st.dataframe(
            fetch_df(
                """
                SELECT ss.Sec_ID, ss.Semester, ss.Section,
                       COUNT(ce.Roll_No) AS Total_Students
                FROM SEM_SECTION ss
                LEFT JOIN CLASS_ENROLLMENT ce ON ss.Sec_ID = ce.Sec_ID
                GROUP BY ss.Sec_ID, ss.Semester, ss.Section
                ORDER BY ss.Semester, ss.Section
                """
            ),
            hide_index=True,
            use_container_width=True,
        )


# ----------------------------------------------------------------- Students
elif page == "Students":
    st.title("Students")

    st.dataframe(
        fetch_df("SELECT * FROM STUDENTS ORDER BY Roll_No"),
        hide_index=True,
        use_container_width=True,
    )

    st.subheader("Add a student")
    with st.form("add_student", clear_on_submit=True):
        roll_no = st.text_input("Roll No (e.g. gec21cs042)", max_chars=10)
        full_name = st.text_input("Full name", max_chars=25)
        city = st.text_input("City", max_chars=25)
        mobile = st.text_input("Mobile (10 digits)", max_chars=10)
        gender = st.selectbox("Gender", ["M", "F"])
        if st.form_submit_button("Add student"):
            try:
                execute(
                    "INSERT INTO STUDENTS VALUES (%s, %s, %s, %s, %s)",
                    (roll_no.strip(), full_name.strip(), city.strip(), mobile.strip(), gender),
                )
                st.success(f"Added {full_name} ({roll_no}).")
                st.rerun()
            except psycopg2.Error as exc:
                st.error(f"Rejected by the database: {exc.pgerror or exc}")

    st.subheader("Delete a student")
    students = fetch_df("SELECT Roll_No, Full_Name FROM STUDENTS ORDER BY Roll_No")
    if not students.empty:
        label_by_roll = dict(zip(students.roll_no, students.full_name))
        victim = st.selectbox(
            "Student", students.roll_no, format_func=lambda r: f"{r} - {label_by_roll[r]}"
        )
        st.caption("Deleting cascades to the student's enrollments and marks (ON DELETE CASCADE).")
        if st.button("Delete", type="primary"):
            execute("DELETE FROM STUDENTS WHERE Roll_No = %s", (victim,))
            st.success(f"Deleted {victim} and all dependent rows.")
            st.rerun()


# -------------------------------------------------------------- Enrollments
elif page == "Enrollments":
    st.title("Enrollments")

    st.dataframe(
        fetch_df(
            """
            SELECT ce.Roll_No, s.Full_Name, ce.Sec_ID, ss.Semester, ss.Section
            FROM CLASS_ENROLLMENT ce
            JOIN STUDENTS s ON ce.Roll_No = s.Roll_No
            JOIN SEM_SECTION ss ON ce.Sec_ID = ss.Sec_ID
            ORDER BY ce.Roll_No, ce.Sec_ID
            """
        ),
        hide_index=True,
        use_container_width=True,
    )

    st.subheader("Enroll a student in a section")
    students = fetch_df("SELECT Roll_No, Full_Name FROM STUDENTS ORDER BY Roll_No")
    sections = fetch_df("SELECT Sec_ID FROM SEM_SECTION ORDER BY Sec_ID")
    if students.empty or sections.empty:
        st.info("Need at least one student and one section first.")
    else:
        label_by_roll = dict(zip(students.roll_no, students.full_name))
        with st.form("enroll", clear_on_submit=True):
            roll = st.selectbox(
                "Student", students.roll_no, format_func=lambda r: f"{r} - {label_by_roll[r]}"
            )
            sec = st.selectbox("Section", sections.sec_id)
            if st.form_submit_button("Enroll"):
                try:
                    execute("INSERT INTO CLASS_ENROLLMENT VALUES (%s, %s)", (roll, sec))
                    st.success(f"Enrolled {roll} in {sec}.")
                    st.rerun()
                except psycopg2.Error as exc:
                    st.error(f"Rejected by the database: {exc.pgerror or exc}")


# -------------------------------------------------------------- Enter Marks
elif page == "Enter Marks":
    st.title("Enter Marks")
    st.caption(
        "FINAL_IA is not entered here on purpose: the trg_compute_final_ia trigger "
        "computes it (average of the best two tests) on every insert/update."
    )

    students = fetch_df("SELECT Roll_No, Full_Name FROM STUDENTS ORDER BY Roll_No")
    courses = fetch_df("SELECT Course_Code, Course_Title FROM COURSES ORDER BY Course_Code")

    if students.empty or courses.empty:
        st.info("Need students and courses first.")
    else:
        label_by_roll = dict(zip(students.roll_no, students.full_name))
        title_by_code = dict(zip(courses.course_code, courses.course_title))

        roll = st.selectbox(
            "Student", students.roll_no, format_func=lambda r: f"{r} - {label_by_roll[r]}"
        )
        enrolled = fetch_df(
            "SELECT Sec_ID FROM CLASS_ENROLLMENT WHERE Roll_No = %s ORDER BY Sec_ID", (roll,)
        )
        if enrolled.empty:
            st.warning("This student is not enrolled in any section yet.")
        else:
            with st.form("marks", clear_on_submit=True):
                course = st.selectbox(
                    "Course", courses.course_code,
                    format_func=lambda c: f"{c} - {title_by_code[c]}",
                )
                sec = st.selectbox("Section", enrolled.sec_id)
                t1 = st.number_input("Test 1", 0, 25, 0)
                t2 = st.number_input("Test 2", 0, 25, 0)
                t3 = st.number_input("Test 3", 0, 25, 0)
                if st.form_submit_button("Save marks"):
                    try:
                        execute(
                            """
                            INSERT INTO INTERNAL_MARKS (ROLL_NO, COURSE_CODE, SEC_ID, TEST1, TEST2, TEST3)
                            VALUES (%s, %s, %s, %s, %s, %s)
                            ON CONFLICT (ROLL_NO, COURSE_CODE, SEC_ID)
                            DO UPDATE SET TEST1 = EXCLUDED.TEST1,
                                          TEST2 = EXCLUDED.TEST2,
                                          TEST3 = EXCLUDED.TEST3
                            """,
                            (roll, course, sec, t1, t2, t3),
                        )
                        saved = fetch_df(
                            """
                            SELECT Test1, Test2, Test3, Final_IA FROM INTERNAL_MARKS
                            WHERE Roll_No = %s AND Course_Code = %s AND Sec_ID = %s
                            """,
                            (roll, course, sec),
                        ).iloc[0]
                        st.success(
                            f"Saved. The trigger computed Final IA = {saved.final_ia}."
                        )
                    except psycopg2.Error as exc:
                        st.error(f"Rejected by the database: {exc.pgerror or exc}")

        st.subheader("All marks")
        st.dataframe(
            fetch_df("SELECT * FROM INTERNAL_MARKS ORDER BY Roll_No, Course_Code"),
            hide_index=True,
            use_container_width=True,
        )


# -------------------------------------------------------------- Report Card
elif page == "Report Card":
    st.title("Report Card")

    students = fetch_df("SELECT Roll_No, Full_Name, City, Gender FROM STUDENTS ORDER BY Roll_No")
    if students.empty:
        st.info("No students yet.")
    else:
        label_by_roll = dict(zip(students.roll_no, students.full_name))
        roll = st.selectbox(
            "Student", students.roll_no, format_func=lambda r: f"{r} - {label_by_roll[r]}"
        )
        info = students[students.roll_no == roll].iloc[0]
        st.markdown(f"**{info.full_name}** · {info.city} · {info.gender}")

        report = fetch_df(
            """
            SELECT c.Course_Code, c.Course_Title, im.Sec_ID,
                   im.Test1, im.Test2, im.Test3, im.Final_IA,
                   CASE
                       WHEN im.Final_IA BETWEEN 17 AND 20 THEN 'Outstanding'
                       WHEN im.Final_IA BETWEEN 12 AND 16 THEN 'Average'
                       ELSE 'Weak'
                   END AS Category
            FROM INTERNAL_MARKS im
            JOIN COURSES c ON im.Course_Code = c.Course_Code
            WHERE im.Roll_No = %s
            ORDER BY c.Course_Code
            """,
            (roll,),
        )
        if report.empty:
            st.info("No marks recorded for this student yet.")
        else:
            st.dataframe(report, hide_index=True, use_container_width=True)
            st.metric("Overall average Final IA", f"{report.final_ia.mean():.1f}")
