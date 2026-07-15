-- ============================================================
-- Trigger: automatically compute FINAL_IA
-- FINAL_IA = average of the best two of the three test marks.
-- Fires BEFORE INSERT or UPDATE of the test marks, so the value
-- is always consistent -- no manual UPDATE needed.
-- ============================================================

CREATE OR REPLACE FUNCTION compute_final_ia()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.TEST1 IS NULL OR NEW.TEST2 IS NULL OR NEW.TEST3 IS NULL THEN
        -- Cannot compute until all three tests are conducted
        NEW.FINAL_IA := NULL;
    ELSE
        -- Sum of all three minus the lowest = sum of best two
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

-- ------------------------------------------------------------
-- Demonstration (run after dml.sql):
-- ------------------------------------------------------------

-- 1. Insert a new marks row WITHOUT giving FINAL_IA -- the trigger fills it in.
-- INSERT INTO INTERNAL_MARKS (ROLL_NO, COURSE_CODE, SEC_ID, TEST1, TEST2, TEST3)
-- VALUES ('gec21cs011', '21cs158', '5A', 12, 18, 15);
-- SELECT * FROM INTERNAL_MARKS WHERE COURSE_CODE = '21cs158';  -- FINAL_IA = 17

-- 2. Update a test mark -- FINAL_IA is recomputed automatically.
-- UPDATE INTERNAL_MARKS SET TEST3 = 22 WHERE ROLL_NO = 'gec21cs011' AND COURSE_CODE = '21cs158';
-- SELECT * FROM INTERNAL_MARKS WHERE COURSE_CODE = '21cs158';  -- FINAL_IA = 20
