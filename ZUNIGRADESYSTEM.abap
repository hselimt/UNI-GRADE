REPORT zunigradesystem.

CLASS lcl_grade_converter DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      convertscoretograde
        IMPORTING
          iv_score        TYPE zstudent_score_de
        RETURNING
          VALUE(rv_grade) TYPE zstudent_grade_de.
ENDCLASS.

CLASS lcl_grade_converter IMPLEMENTATION.
  METHOD convertscoretograde.
    IF iv_score >= 95.
      rv_grade = 'AA'.
    ELSEIF iv_score >= 90.
      rv_grade = 'AB'.
    ELSEIF iv_score >= 85.
      rv_grade = 'BB'.
    ELSEIF iv_score >= 75.
      rv_grade = 'BC'.
    ELSEIF iv_score >= 55.
      rv_grade = 'CC'.
    ELSEIF iv_score >= 45.
      rv_grade = 'CD'.
    ELSEIF iv_score >= 35.
      rv_grade = 'DD'.
    ELSE.
      rv_grade = 'FF'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

DATA: gv_studentID     TYPE zstudentid_de,
      gv_studentName   TYPE zstudentname_de,
      gv_studentGender TYPE zstudentgen_de,
      gv_studentScore  TYPE zstudent_score_de,
      gv_studentGrade  TYPE zstudent_grade_de,
      gs_student_t     TYPE zstudent_t,
      gt_student_t     TYPE TABLE OF zstudent_t,
      gs_failed_t      TYPE zfstudent_t,
      gt_failed_t      TYPE TABLE OF zfstudent_t.

DATA: lv_next_student_id   TYPE zstudentid_de,
      ls_max_grade_student TYPE zstudent_t,
      lv_max_grade_student TYPE zstudent_score_de VALUE 0.


SELECTION-SCREEN BEGIN OF BLOCK stud_inf WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_name TYPE zstudentname_de LOWER CASE.
  PARAMETERS: p_score  TYPE zstudent_score_de,
              p_male   RADIOBUTTON GROUP gen,
              p_female RADIOBUTTON GROUP gen.
SELECTION-SCREEN END OF BLOCK stud_inf.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK search WITH FRAME TITLE TEXT-005.

  SELECTION-SCREEN BEGIN OF BLOCK sname.
    PARAMETERS: p_sname TYPE zstudentname_de LOWER CASE.
    PARAMETERS: p_sid TYPE zstudentid_de.
  SELECTION-SCREEN END OF BLOCK sname.

SELECTION-SCREEN END OF BLOCK search.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK update WITH FRAME TITLE TEXT-006.

  SELECTION-SCREEN BEGIN OF BLOCK usid.
    PARAMETERS: P_uid TYPE zstudentid_de.
  SELECTION-SCREEN END OF BLOCK usid.

SELECTION-SCREEN END OF BLOCK update.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK ops WITH FRAME TITLE TEXT-003.
  PARAMETERS: p_add    AS CHECKBOX,
              p_update AS CHECKBOX,
              p_clear  AS CHECKBOX,
              p_stats  AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK ops.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK filter WITH FRAME TITLE TEXT-004.
  SELECT-OPTIONS: s_score FOR gs_student_t-studentscore.
SELECTION-SCREEN END OF BLOCK filter.

INITIALIZATION.

AT SELECTION-SCREEN.

  IF p_add IS INITIAL AND p_clear IS INITIAL AND p_stats IS INITIAL AND p_update IS INITIAL AND p_sid IS INITIAL AND p_sname IS INITIAL AND s_score IS INITIAL.
    MESSAGE 'SELECT AN OPERATION' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  PERFORM initialize_data.

START-OF-SELECTION.

  IF p_add EQ 'X' AND p_score >= 0 AND p_score <= 100.
    PERFORM process_student_data.
    PERFORM handle_failed_students.
  ENDIF.

  IF p_clear EQ 'X'.
    PERFORM clear_all_data_with_popup.
  ENDIF.


  PERFORM display_selected_information.

FORM clear_all_data_with_popup.
  DATA: lv_answer TYPE c.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'CONFIRM DATA DELETION'
      text_question         = 'YOU WANT TO DELETE ALL STUDENT DATA?'
      text_button_1         = 'YES'
      text_button_2         = 'NO'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer = '1'.
    DELETE FROM zstudent_t.
    DELETE FROM zfstudent_t.
    COMMIT WORK.

    lv_next_student_id = 1.
    CLEAR: gt_student_t, gt_failed_t.
    MESSAGE 'ALL STUDENTS HAVE BEEN DELETED' TYPE 'S'.
  ENDIF.
ENDFORM.

FORM display_selected_information.
  NEW-PAGE.

  WRITE: /1 '══════════════════════════════════════════════════════════════════════════'.
  WRITE: /1 '                       UNIVERSITY GRADE SYSTEM REPORT                     '.
  WRITE: /1 '══════════════════════════════════════════════════════════════════════════'.
  WRITE: /.

  IF p_add EQ 'X' AND gs_student_t IS NOT INITIAL AND p_score >= 0 AND p_score <= 100.
    PERFORM display_added_student_details.
  ENDIF.

  IF p_update EQ 'X' AND p_score >= 0 AND p_score <= 100.
    PERFORM update_student_by_id.
  ENDIF.

  IF p_stats EQ 'X'.
    PERFORM display_failed_students.
    PERFORM display_top_student.
    PERFORM display_statistics.
  ENDIF.

  IF s_score IS NOT INITIAL.
    PERFORM list_students_by_score.
  ENDIF.

  IF p_sname IS NOT INITIAL.
    PERFORM search_student_by_name.
  ENDIF.

  IF p_sid IS NOT INITIAL.
    PERFORM search_student_by_id.
  ENDIF.
ENDFORM.

FORM display_added_student_details.
  WRITE: /1 '📝 NEW STUDENT'.
  WRITE: /3 '├─ STUDENT ID     ', gs_student_t-studentid.
  WRITE: /3 '├─ NAME           ', gs_student_t-studentname.
  WRITE: /3 '├─ GENDER         ', gs_student_t-studentgen.
  WRITE: /3 '├─ SCORE          ', gs_student_t-studentscore.
  WRITE: /3 '└─ GRADE          ', gs_student_t-studentgrade.
  WRITE: /.
ENDFORM.

FORM display_failed_students.
  DATA: lv_count TYPE i.

  WRITE: /1 '❌ FAILED STUDENTS'.

  SELECT COUNT(*) FROM zfstudent_t INTO @lv_count.

  IF lv_count > 0.
    SELECT * FROM zfstudent_t INTO TABLE @gt_failed_t.

    LOOP AT gt_failed_t INTO gs_failed_t.
      WRITE: /3 '├─  ', gs_failed_t-studentname.
    ENDLOOP.
  ELSE.
    WRITE: /3 '└─ ⚠️  NO DATA FOUND'.
  ENDIF.
  WRITE: /.
ENDFORM.

FORM display_statistics.
  DATA: lv_total  TYPE i,
        lv_avg    TYPE p DECIMALS 2,
        lv_passed TYPE i,
        lv_failed TYPE i.

  SELECT COUNT(*) FROM zstudent_t INTO @lv_total.
  SELECT AVG( studentscore ) FROM zstudent_t INTO @lv_avg.
  SELECT COUNT(*) FROM zstudent_t INTO @lv_passed WHERE studentscore >= 35.
  lv_failed = lv_total - lv_passed.

  WRITE: /1 '📊 STATS'.
  WRITE: /3 '├─ STUDENTS      ', lv_total.
  WRITE: /3 '├─ AVG SCORE  ', lv_avg.
  WRITE: /3 '├─ PASSED       ', lv_passed.
  WRITE: /3 '└─ FAILED       ', lv_failed.
  WRITE: /.
ENDFORM.

FORM initialize_data.
  PERFORM load_student_data.
  PERFORM load_failed_student_data.
  PERFORM calculate_next_student_id.
ENDFORM.

FORM load_student_data.
  SELECT * FROM zstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_student_t.
ENDFORM.

FORM load_failed_student_data.
  SELECT * FROM zfstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_failed_t.
ENDFORM.

FORM calculate_next_student_id.
  SELECT MAX( studentID ) FROM zstudent_t INTO @lv_next_student_id.

  IF sy-subrc NE 0.
    lv_next_student_id = 1.
  ELSE.
    lv_next_student_id = lv_next_student_id + 1.
  ENDIF.
ENDFORM.

FORM search_student_by_id.

  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentid EQ @p_sid.
  IF sy-subrc = 0.
    WRITE: /1 '📝 SEARCHED STUDENT '.
    WRITE: /3 '├─ STUDENT ID     ', gs_student_t-studentid.
    WRITE: /3 '├─ NAME           ', gs_student_t-studentname.
    WRITE: /3 '├─ GENDER         ', gs_student_t-studentgen.
    WRITE: /3 '├─ SCORE          ', gs_student_t-studentscore.
    WRITE: /3 '└─ GRADE          ', gs_student_t-studentgrade.
    WRITE: /.
  ELSE.
    WRITE: /1 '❌ STUDENT NOT FOUND'.
  ENDIF.

ENDFORM.

FORM search_student_by_name.

  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentname EQ @p_sname.
  IF sy-subrc = 0.
    WRITE: /1 '📝 SEARCHED STUDENT '.
    WRITE: /3 '├─ STUDENT ID     ', gs_student_t-studentid.
    WRITE: /3 '├─ NAME           ', gs_student_t-studentname.
    WRITE: /3 '├─ GENDER         ', gs_student_t-studentgen.
    WRITE: /3 '├─ SCORE          ', gs_student_t-studentscore.
    WRITE: /3 '└─ GRADE          ', gs_student_t-studentgrade.
    WRITE: /.
  ELSE.
    WRITE: /1 '❌ STUDENT NOT FOUND'.
  ENDIF.

ENDFORM.

FORM update_student_by_id.

  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentid EQ @p_uid.

  IF sy-subrc = 0.
    gs_student_t-studentname = p_name.
    gs_student_t-studentscore = p_score.
    gs_student_t-studentgrade = lcl_grade_converter=>convertscoretograde( p_score ).
    IF p_male EQ 'X'.
      gs_student_t-studentgen = 'M'.
    ELSE.
      gs_student_t-studentgen = 'F'.
    ENDIF.

    UPDATE zstudent_t FROM gs_student_t.

    IF sy-subrc = 0.
      COMMIT WORK.
      MESSAGE 'STUDENT UPDATED SUCCESSFULLY' TYPE 'S'.
    ELSE.
      ROLLBACK WORK.
      MESSAGE 'ERROR UPDATING STUDENT' TYPE 'E'.
    ENDIF.
  ENDIF.


ENDFORM.

FORM process_student_data.
  PERFORM prepare_student_record.
  PERFORM save_student_record.
ENDFORM.

FORM prepare_student_record.
  CLEAR gs_student_t.

  gs_student_t-studentid = lv_next_student_id.
  gs_student_t-studentname = p_name.
  gs_student_t-studentscore = p_score.
  gs_student_t-studentgrade = lcl_grade_converter=>convertscoretograde( p_score ).

  IF p_male EQ 'X'.
    gs_student_t-studentgen = 'M'.
  ELSE.
    gs_student_t-studentgen = 'F'.
  ENDIF.

  APPEND gs_student_t TO gt_student_t.
ENDFORM.

FORM save_student_record.
  INSERT zstudent_t FROM @gs_student_t.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE 'STUDENT ADDED' TYPE 'S'.
  ELSE.
    MESSAGE 'ERROR ADDING STUDENT' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM handle_failed_students.
  IF gs_student_t-studentgrade = 'FF'.
    PERFORM process_failed_student.
  ENDIF.
ENDFORM.

FORM process_failed_student.
  MESSAGE 'STUDENT HAS FAILED THE CLASS' TYPE 'I'.

  IF gs_student_t-studentscore BETWEEN 34 AND 35.
    PERFORM upgrade_student_grade.
  ELSE.
    PERFORM add_to_failed_students.
  ENDIF.
ENDFORM.

FORM upgrade_student_grade.
  gs_student_t-studentgrade = 'DD'.
  gs_student_t-studentscore = 35.

  UPDATE zstudent_t SET studentgrade = @gs_student_t-studentgrade,
                        studentscore = @gs_student_t-studentscore
                    WHERE studentid = @gs_student_t-studentid.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE 'GRADE UPGRADED TO DD WITH THE SCORE OF 35' TYPE 'I'.
  ENDIF.
ENDFORM.

FORM add_to_failed_students.
  CLEAR gs_failed_t.
  MOVE-CORRESPONDING gs_student_t TO gs_failed_t.

  INSERT zfstudent_t FROM @gs_failed_t.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE 'STUDENT ADDED TO FAILED STUDENTS LIST' TYPE 'I'.
  ENDIF.
ENDFORM.

FORM display_top_student.
  PERFORM find_top_student.

  IF ls_max_grade_student IS NOT INITIAL.
    WRITE: /1 '🏆 TOP STUDENT'.
    WRITE: /3 '├─ NAME           ', ls_max_grade_student-studentname.
    WRITE: /3 '└─ SCORE          ', ls_max_grade_student-studentscore.
    WRITE: /.
  ELSE.
    WRITE: /1 '└─ ⚠️  NO DATA FOUND'.
    WRITE: /.
  ENDIF.
ENDFORM.

FORM find_top_student.
  CLEAR: ls_max_grade_student, lv_max_grade_student.

  LOOP AT gt_student_t INTO gs_student_t.
    IF gs_student_t-studentscore > lv_max_grade_student.
      lv_max_grade_student = gs_student_t-studentscore.
      ls_max_grade_student = gs_student_t.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM list_students_by_score.
  SELECT * FROM zstudent_t
    INTO TABLE @gt_student_t
    WHERE studentscore IN @s_score.

  WRITE: /1 '🔍 STUDENTS IN RANGE'.

  IF lines( gt_student_t ) > 0.
    LOOP AT gt_student_t INTO gs_student_t.
      WRITE: /3 '├─   ', gs_student_t-studentname, gs_student_t-studentscore.
    ENDLOOP.
  ELSE.
    WRITE: /3 '└─   ⚠️  NO DATA FOUND'.
  ENDIF.
  WRITE: /.
ENDFORM.
