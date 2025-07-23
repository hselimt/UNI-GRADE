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
