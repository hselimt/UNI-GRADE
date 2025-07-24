CLASS lcl_grade_converter DEFINITION. " define grade converter
  PUBLIC SECTION.
    CLASS-METHODS:
      convertscoretograde " create method
        IMPORTING
          iv_score        TYPE zstudent_score_de " import score
        RETURNING
          VALUE(rv_grade) TYPE zstudent_grade_de. " return grade
ENDCLASS.

CLASS lcl_grade_converter IMPLEMENTATION. " implement grade converter
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

CLASS lcl_age_calculator DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      calculate_age
        IMPORTING
          iv_bdate    TYPE zstudentbdate_de " import b date
        RETURNING
          VALUE(rv_age) TYPE zstudentage_de. " return age
ENDCLASS.

CLASS lcl_age_calculator IMPLEMENTATION.
  METHOD calculate_age.
    rv_age = sy-datum(4) - iv_bdate(4). " current year - b date year

    IF sy-datum+4(4) < iv_bdate+4(4).
      rv_age = rv_age - 1. " substract 1 if current month and date is lower than b date month and date
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_set_cell_color DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      set_cell_color
        IMPORTING
          iv_grade TYPE zstudent_grade_de
        RETURNING
          VALUE(rv_color) TYPE lvc_s_scol. " lvc_s_scol is a structure used to define the color properties
ENDCLASS.

CLASS lcl_set_cell_color IMPLEMENTATION.
  METHOD set_cell_color.
    CLEAR rv_color.
    rv_color-fname = 'STUDENTGRADE'.
    rv_color-color-int = '1'. " set color intensity to make it vibrant

    CASE iv_grade.
      WHEN 'FF'.
        rv_color-color-col = col_negative. " red
      WHEN 'DD' OR 'CD'.
        rv_color-color-col = col_total. " yellow
      WHEN 'CC' OR 'BC' OR 'BB'.
        rv_color-color-col = col_key. " blue
      WHEN 'AB' OR 'AA'.
        rv_color-color-col = col_positive. " green
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
