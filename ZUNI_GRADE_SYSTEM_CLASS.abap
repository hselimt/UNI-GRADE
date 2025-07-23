REPORT zunigradesystem.

INCLUDE <icon>.
INCLUDE zuni_grade_system_data.
INCLUDE zuni_grade_system_class.

SELECTION-SCREEN BEGIN OF BLOCK stud_inf WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_name    TYPE zstudentname_de LOWER CASE,
              p_lname   TYPE zstudentlname_de LOWER CASE,
              p_bdate   TYPE zstudentbdate_de,
              p_score   TYPE zstudent_score_de,
              p_mail    TYPE zstudentmail_de,
              p_male    RADIOBUTTON GROUP gen,
              p_female  RADIOBUTTON GROUP gen.
SELECTION-SCREEN END OF BLOCK stud_inf.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK search WITH FRAME TITLE TEXT-005.
  SELECTION-SCREEN BEGIN OF BLOCK sname.
    PARAMETERS: p_sname TYPE zstudentname_de LOWER CASE,
                p_slname TYPE zstudentlname_de LOWER CASE,
                p_sid   TYPE zstudentid_de.
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
  PARAMETERS: p_add     AS CHECKBOX,
              p_update  AS CHECKBOX,
              p_clear   AS CHECKBOX,
              p_stats   AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK ops.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK filter WITH FRAME TITLE TEXT-004.
  SELECT-OPTIONS: s_score FOR gs_student_t-studentscore.
SELECTION-SCREEN END OF BLOCK filter.

INITIALIZATION.

AT SELECTION-SCREEN.
  IF p_add IS INITIAL AND p_update IS INITIAL AND p_clear IS INITIAL AND p_stats IS INITIAL AND p_sid IS INITIAL AND p_sname IS INITIAL AND p_slname IS INITIAL AND s_score IS INITIAL.
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
  DATA lv_answer TYPE c.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar            = 'CONFIRM DATA DELETION'
      text_question       = 'YOU WANT TO DELETE ALL STUDENT DATA?'
      text_button_1       = 'YES'
      text_button_2       = 'NO'
      default_button      = '2'
      display_cancel_button = space
    IMPORTING
      answer              = lv_answer.

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
  WRITE: /1 '══════════════════════════════════════════════════════════════════════════'.
  WRITE: /1 '         UNIVERSITY GRADE SYSTEM REPORT                                 '.
  WRITE: /1 '══════════════════════════════════════════════════════════════════════════'.
  WRITE: /.

  IF p_add EQ 'X' AND gs_student_t IS NOT INITIAL AND p_score >= 0 AND p_score <= 100.
    PERFORM display_added_student_details.
  ENDIF.

  IF p_update EQ 'X' AND p_uid IS NOT INITIAL.
    PERFORM update_student_by_id.
  ENDIF.

  IF p_stats EQ 'X'.
    PERFORM create_student_salv.
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
  WRITE: /1  '@0V@', 'NEW STUDENT'.
  WRITE: /3 '├─ STUDENT ID:      ', gs_student_t-studentid COLOR COL_HEADING.
  WRITE: /3 '├─ NAME:            ', gs_student_t-studentname COLOR COL_NORMAL.
  WRITE: /3 '├─ LASTNAME:        ', gs_student_t-studentlname COLOR COL_NORMAL.
  WRITE: /3 '├─ BIRTH DATE:      ', gs_student_t-studentbdate COLOR COL_NORMAL.
  WRITE: /3 '├─ AGE:             ', gs_student_t-studentage COLOR COL_NORMAL.
  WRITE: /3 '├─ MAIL:            ', gs_student_t-studentmail COLOR COL_NORMAL.
  WRITE: /3 '├─ GENDER:          ', gs_student_t-studentgen COLOR COL_NORMAL.
  WRITE: /3 '├─ SCORE:           ', gs_student_t-studentscore COLOR COL_NORMAL.
  WRITE: /3 '└─ GRADE:           ', gs_student_t-studentgrade COLOR COL_NORMAL.
  WRITE: /.
ENDFORM.

FORM display_failed_students.
  DATA lv_count TYPE i.

  WRITE: /1 '@17@', 'FAILED STUDENTS'.

  SELECT COUNT(*) FROM zfstudent_t INTO @lv_count.

  IF lv_count > 0.
    SELECT * FROM zfstudent_t INTO TABLE @gt_failed_t.

    LOOP AT gt_failed_t INTO gs_failed_t.
      WRITE: /3 '├─  ', gs_failed_t-studentname.
    ENDLOOP.
  ELSE.
    WRITE: /3 '└─ ','@0A@','NO DATA FOUND'.
  ENDIF.
  WRITE: /.
ENDFORM.

FORM display_statistics.
  DATA lv_total   TYPE i.
  DATA lv_avg     TYPE p DECIMALS 2.
  DATA lv_passed  TYPE i.
  DATA lv_failed  TYPE i.

  SELECT COUNT(*) FROM zstudent_t INTO @lv_total.
  SELECT AVG( studentscore ) FROM zstudent_t INTO @lv_avg.
  SELECT COUNT(*) FROM zstudent_t INTO @lv_passed WHERE studentscore >= 35.
  lv_failed = lv_total - lv_passed.

  WRITE: /1  '@17@', 'STATS'.
  WRITE: /3 '├─ STUDENTS:        ', lv_total.
  WRITE: /3 '├─ PASSED:          ', lv_passed.
  WRITE: /3 '├─ FAILED:          ', lv_failed.
  WRITE: /3 '└─ AVG SCORE:     ', lv_avg.
  WRITE: /.
ENDFORM.

FORM initialize_data.
  PERFORM load_student_data.
  PERFORM load_failed_student_data.
  PERFORM calculate_next_student_id.
  PERFORM update_age_of_all_students.
ENDFORM.

FORM load_student_data.
  SELECT * FROM zstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_student_t.
ENDFORM.

FORM update_age_of_all_students.
  SELECT * FROM zstudent_t
    INTO TABLE gt_student_t.

  LOOP AT gt_student_t INTO gs_student_t.
    DATA(lv_new_age) = lcl_age_calculator=>calculate_age( gs_student_t-studentbdate ).

    IF lv_new_age NE gs_student_t-studentage.
      gs_student_t-studentage = lv_new_age.

      UPDATE zstudent_t SET studentage = lv_new_age
                        WHERE studentid = gs_student_t-studentid.
    ENDIF.

  ENDLOOP.

  COMMIT WORK.

 ENDFORM.


FORM load_failed_student_data.
  SELECT * FROM zfstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_failed_t.
ENDFORM.

FORM create_student_salv.
  SELECT * FROM zstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_student_t.
    TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_salv_students
        CHANGING
          t_table      = gt_student_t
      ).
    CATCH CX_SALV_MSG.
    ENDTRY.

  go_salv_students->display( ).
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
    WRITE: /1  '@08@', 'SEARCHED STUDENT'.
    WRITE: /3 '├─ STUDENT ID:      ', gs_student_t-studentid.
    WRITE: /3 '├─ NAME:            ', gs_student_t-studentname.
    WRITE: /3 '├─ LASTNAME:        ', gs_student_t-studentlname.
    WRITE: /3 '├─ BIRTH DATE:      ', gs_student_t-studentbdate.
    WRITE: /3 '├─ AGE:             ', gs_student_t-studentage.
    WRITE: /3 '├─ MAIL:            ', gs_student_t-studentmail.
    WRITE: /3 '├─ GENDER:          ', gs_student_t-studentgen.
    WRITE: /3 '├─ SCORE:           ', gs_student_t-studentscore.
    WRITE: /3 '└─ GRADE:           ', gs_student_t-studentgrade.
    WRITE: /.
  ELSE.
    WRITE: /1 '@0A@', 'STUDENT NOT FOUND'.
  ENDIF.
ENDFORM.

FORM search_student_by_name.
  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentname EQ @p_sname AND studentlname EQ @p_slname.
  IF sy-subrc = 0.
    WRITE: /1  '@08@', 'SEARCHED STUDENT'.
    WRITE: /3 '├─ STUDENT ID:      ', gs_student_t-studentid COLOR COL_HEADING.
    WRITE: /3 '├─ NAME:            ', gs_student_t-studentname COLOR COL_NORMAL.
    WRITE: /3 '├─ LASTNAME:        ', gs_student_t-studentlname COLOR COL_NORMAL.
    WRITE: /3 '├─ BIRTH DATE:      ', gs_student_t-studentbdate COLOR COL_NORMAL.
    WRITE: /3 '├─ AGE:             ', gs_student_t-studentage COLOR COL_NORMAL.
    WRITE: /3 '├─ MAIL:            ', gs_student_t-studentmail COLOR COL_NORMAL.
    WRITE: /3 '├─ GENDER:          ', gs_student_t-studentgen COLOR COL_NORMAL.
    WRITE: /3 '├─ SCORE:           ', gs_student_t-studentscore COLOR COL_NORMAL.
    WRITE: /3 '└─ GRADE:           ', gs_student_t-studentgrade COLOR COL_NORMAL.
    WRITE: /.
  ELSE.
    WRITE: /1 '@0A@', 'STUDENT NOT FOUND'.
  ENDIF.
ENDFORM.

FORM update_student_by_id.
  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentid EQ @p_uid.

  IF sy-subrc = 0.
    IF p_name IS NOT INITIAL.
      gs_student_t-studentname = p_name.
    ENDIF.

    IF p_lname IS NOT INITIAL.
      gs_student_t-studentlname = p_lname.
    ENDIF.

    IF p_bdate IS NOT INITIAL.
      gs_student_t-studentbdate = p_bdate.
      gs_student_t-studentage = lcl_age_calculator=>calculate_age( p_bdate ).
    ENDIF.

    IF p_score IS NOT INITIAL.
      gs_student_t-studentscore = p_score.
      gs_student_t-studentgrade = lcl_grade_converter=>convertscoretograde( p_score ).
    ENDIF.

    IF p_mail IS NOT INITIAL.
      gs_student_t-studentmail = p_mail.
    ENDIF.

    IF p_male EQ 'X'.
      gs_student_t-studentgen = 'M'.
    ELSEIF p_female EQ 'X'.
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
  ELSE.
    MESSAGE 'STUDENT NOT FOUND FOR UPDATE' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM process_student_data.
  PERFORM prepare_student_record.
  PERFORM save_student_record.
ENDFORM.

FORM prepare_student_record.
  CLEAR gs_student_t.

  gs_student_t-studentid  = lv_next_student_id.
  gs_student_t-studentname  = p_name.
  gs_student_t-studentlname = p_lname.
  gs_student_t-studentbdate = p_bdate.
  gs_student_t-studentmail  = p_mail.
  gs_student_t-studentscore = p_score.
  gs_student_t-studentgrade = lcl_grade_converter=>convertscoretograde( p_score ).
  gs_student_t-studentage   = lcl_age_calculator=>calculate_age( p_bdate ).

  IF p_male EQ 'X'.
    gs_student_t-studentgen = 'M'.
  ELSEIF p_female EQ 'X'.
    gs_student_t-studentgen = 'F'.
  ENDIF.

  IF p_bdate <= sy-datum AND p_mail CS '@' AND p_mail CS '.'.
    APPEND gs_student_t TO gt_student_t.
  ELSE.
    MESSAGE 'MAKE SURE TO ENTER VALID VALUES' TYPE 'E'.
  ENDIF.

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
  IF gs_student_t-studentscore BETWEEN 34 AND 35.
    PERFORM upgrade_student_grade.
    MESSAGE 'STUDENT''S GRADE UPGRADED TO DD WITH THE SCORE OF 35' TYPE 'I'.
  ELSE.
    PERFORM add_to_failed_students.
    MESSAGE 'STUDENT HAS FAILED THE CLASS AND ADDED TO FAILED LIST' TYPE 'I'.
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
  ENDIF.
ENDFORM.

FORM add_to_failed_students.
  CLEAR gs_failed_t.
  MOVE-CORRESPONDING gs_student_t TO gs_failed_t.

  INSERT zfstudent_t FROM @gs_failed_t.

  IF sy-subrc = 0.
    COMMIT WORK.
  ENDIF.
ENDFORM.

FORM display_top_student.
  PERFORM find_top_student.

  IF ls_max_grade_student IS NOT INITIAL.
    WRITE: /1  '@10@', 'TOP STUDENT'.
    WRITE: /3 '├─ FULLNAME:        ', ls_max_grade_student-studentname.
    WRITE: /3 '├─ NAME:            ', ls_max_grade_student-studentlname.
    WRITE: /3 '├─ ID:              ', ls_max_grade_student-studentid.
    WRITE: /3 '└─ SCORE:           ', ls_max_grade_student-studentscore.
    WRITE: /.
  ELSE.
    WRITE: /1 '@0A@', '└─ ⚠️  NO DATA FOUND'.
    WRITE: /.
  ENDIF.
ENDFORM.

FORM find_top_student.
  CLEAR: ls_max_grade_student, lv_highest_score.

  SELECT MAX( studentscore ) FROM zstudent_t INTO @lv_highest_score.
  IF sy-subrc = 0 AND lv_highest_score IS NOT INITIAL.
    SELECT SINGLE * FROM zstudent_t
      INTO @ls_max_grade_student
      WHERE studentscore EQ @lv_highest_score.
  ENDIF.
ENDFORM.

FORM list_students_by_score.
  SELECT * FROM zstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_student_t
    WHERE studentscore IN @s_score.

  WRITE: /1 '@08@', 'STUDENTS IN RANGE'.

  IF lines( gt_student_t ) > 0.
    LOOP AT gt_student_t INTO gs_student_t.
      WRITE: /3 '├─   ', gs_student_t-studentname, gs_student_t-studentlname, gs_student_t-studentscore.
    ENDLOOP.
  ELSE.
    WRITE: /3 '└─   ','@0A@','   NO DATA FOUND'.
  ENDIF.
  WRITE: /.
ENDFORM.
