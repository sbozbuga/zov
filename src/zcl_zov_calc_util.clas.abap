CLASS zcl_zov_calc_util DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS derive_target_end_date
      IMPORTING is_ctx    TYPE zif_zov_types=>ty_calc_context
      CHANGING  cs_result TYPE zif_zov_types=>ty_calc_result.
    METHODS derive_tat_overdue
      IMPORTING is_ctx    TYPE zif_zov_types=>ty_calc_context
                iv_base   TYPE dats
      CHANGING  cs_result TYPE zif_zov_types=>ty_calc_result.
    METHODS clamp_numerics
      CHANGING cs_result  TYPE zif_zov_types=>ty_calc_result.
    " correct a date forward ('+') onto the next factory workday. Shared by strategies for
    " initcommitdate (legacy applies DATE_CONVERT_TO_FACTORYDATE default option '+').
    CLASS-METHODS correct_to_factory_workday
      IMPORTING iv_date        TYPE dats
                iv_fabkl       TYPE wfcid
      RETURNING VALUE(rv_date) TYPE dats.
  PROTECTED SECTION.
    METHODS to_factory_date
      IMPORTING iv_date        TYPE dats
                iv_fabkl       TYPE wfcid
                iv_dir         TYPE c
      RETURNING VALUE(rv_date) TYPE dats.
    METHODS add_factory_days
      IMPORTING iv_date        TYPE dats
                iv_days        TYPE i
                iv_fabkl       TYPE wfcid
      RETURNING VALUE(rv_date) TYPE dats.
    " sequential factory-day index for a calendar date (corrected backward onto a workday).
    " Difference of two indices = number of working days between the dates. Used for TAT.
    METHODS factory_day_index
      IMPORTING iv_date         TYPE dats
                iv_fabkl        TYPE wfcid
      RETURNING VALUE(rv_index) TYPE i.
  PRIVATE SECTION.
    CONSTANTS c_max999 TYPE i VALUE 999.
ENDCLASS.



CLASS zcl_zov_calc_util IMPLEMENTATION.

  METHOD derive_target_end_date.
    IF is_ctx-repdau-found = abap_true.
      cs_result-repdauer = is_ctx-repdau-dauer.
      cs_result-kaltage  = is_ctx-repdau-kaltage.
      cs_result-webaz    = is_ctx-repdau-rsende.
    ENDIF.

    DATA(lv_base) = COND dats( WHEN is_ctx-repdau-otdstart = '3000'
                               THEN is_ctx-dockdate ELSE is_ctx-receivedate ).

    " ZX special
    IF is_ctx-qmart = zif_zov_types=>qmart-zx.
      cs_result-kaltage = abap_true.
      IF is_ctx-rsende IS NOT INITIAL.
        cs_result-auftragsendesoll =
          to_factory_date( iv_date  = CONV dats( is_ctx-rsende + 2 )
                           iv_fabkl = is_ctx-fabkl iv_dir = '+' ).
      ENDIF.
      RETURN.
    ENDIF.

    " forward family: end-date handled by strategy
    IF is_ctx-otgrp = 'ZFL' OR is_ctx-otgrp = 'ZMTO'
       OR is_ctx-otgrp = 'ZRET' OR is_ctx-otgrp = 'ZTRANS'.
      RETURN.
    ENDIF.

    CHECK lv_base IS NOT INITIAL.
    IF cs_result-kaltage = abap_true.
      cs_result-auftragsendesoll =
        to_factory_date(
          iv_date  = CONV dats( lv_base + cs_result-repdauer - 1 + is_ctx-one_day_offset )
          iv_fabkl = is_ctx-fabkl iv_dir = '-' ).
    ELSE.
      DATA(lv_start) = to_factory_date( iv_date  = CONV dats( lv_base - 1 )
                                        iv_fabkl = is_ctx-fabkl iv_dir = '-' ).
      cs_result-auftragsendesoll =
        add_factory_days( iv_date  = lv_start
                          iv_days  = CONV i( cs_result-repdauer + is_ctx-one_day_offset )
                          iv_fabkl = is_ctx-fabkl ).
    ENDIF.
  ENDMETHOD.

  METHOD derive_tat_overdue.
    DATA(lv_to) = COND dats( WHEN cs_result-dateclosed IS NOT INITIAL
                             THEN cs_result-dateclosed ELSE is_ctx-refdate ).
    CHECK iv_base IS NOT INITIAL.

    TRY.
        IF cs_result-kaltage = abap_true.
          cs_result-tat = lv_to - iv_base + 1.
        ELSE.
          " working-day span: difference of factory-day INDICES (not corrected dates),
          " matching legacy lv_fdateto - lv_fdatefrom + 1.
          DATA(lv_fto)   = factory_day_index( iv_date = lv_to  iv_fabkl = is_ctx-fabkl ).
          DATA(lv_ffrom) = factory_day_index( iv_date = iv_base iv_fabkl = is_ctx-fabkl ).
          cs_result-tat = lv_fto - lv_ffrom + 1.
        ENDIF.
        " legacy subtracts interruption (Unterbrechung) days from TAT
        cs_result-tat = cs_result-tat - is_ctx-breakduration.
      CATCH cx_sy_arithmetic_overflow.
        cs_result-tat = c_max999.
    ENDTRY.
    IF cs_result-tat > 0.
      cs_result-tat = cs_result-tat - is_ctx-one_day_offset.
    ENDIF.

    IF is_ctx-qmart = zif_zov_types=>qmart-zx.
      IF cs_result-auftragsendesoll IS NOT INITIAL.
        TRY.
            cs_result-overdue = COND #(
              WHEN cs_result-dateclosed IS INITIAL
              THEN is_ctx-refdate - cs_result-auftragsendesoll
              ELSE cs_result-dateclosed - cs_result-auftragsendesoll ).
          CATCH cx_sy_arithmetic_overflow.
            cs_result-overdue = c_max999.
        ENDTRY.
      ENDIF.
    ELSE.
      TRY.
          cs_result-overdue = cs_result-tat - cs_result-repdauer.
        CATCH cx_sy_arithmetic_overflow.
          cs_result-overdue = c_max999.
      ENDTRY.
    ENDIF.
    IF cs_result-overdue < 0.
      cs_result-overdue = 0.
    ENDIF.
  ENDMETHOD.

  METHOD clamp_numerics.
    DATA lv_capped TYPE abap_bool.
    IF cs_result-repdauer < 0 OR cs_result-repdauer > c_max999.
      cs_result-repdauer = c_max999. lv_capped = abap_true.
    ENDIF.
    IF cs_result-webaz < 0 OR cs_result-webaz > c_max999.
      cs_result-webaz = c_max999. lv_capped = abap_true.
    ENDIF.
    IF cs_result-tat < 0 OR cs_result-tat > c_max999.
      cs_result-tat = c_max999. lv_capped = abap_true.
    ENDIF.
    IF cs_result-overdue < 0 OR cs_result-overdue > c_max999.
      cs_result-overdue = c_max999. lv_capped = abap_true.
    ENDIF.
    cs_result-value_capped = lv_capped.
  ENDMETHOD.

  METHOD to_factory_date.
    " Correct a calendar date onto a working day of the factory calendar.
    " iv_dir '+' = forward to next workday, '-' = back to previous workday.
    DATA lv_date TYPE sydatum.
    lv_date = iv_date.
    IF iv_fabkl IS INITIAL OR iv_date IS INITIAL.
      rv_date = iv_date.
      RETURN.
    ENDIF.
    CALL FUNCTION 'DATE_CONVERT_TO_FACTORYDATE'
      EXPORTING
        correct_option               = iv_dir
        date                         = lv_date
        factory_calendar_id          = iv_fabkl
      IMPORTING
        date                         = rv_date
      EXCEPTIONS
        calendar_buffer_not_loadable = 1
        correct_option_invalid       = 2
        date_after_range             = 3
        date_before_range            = 4
        date_invalid                 = 5
        factory_calendar_not_found   = 6
        OTHERS                       = 7.
    IF sy-subrc <> 0.
      rv_date = iv_date.
    ENDIF.
  ENDMETHOD.

  METHOD add_factory_days.
    " Add iv_days working days on the factory calendar.
    DATA lv_fkday TYPE mdcal-fkday.
    IF iv_fabkl IS INITIAL OR iv_date IS INITIAL.
      rv_date = iv_date.
      RETURN.
    ENDIF.
    lv_fkday = iv_days.
    CALL FUNCTION 'WDKAL_DATE_ADD_FKDAYS'
      EXPORTING
        i_date  = iv_date
        i_fkday = lv_fkday
        i_fabkl = iv_fabkl
      IMPORTING
        e_date  = rv_date
      EXCEPTIONS
        error   = 1
        OTHERS  = 2.
    IF sy-subrc <> 0.
      rv_date = iv_date.
    ENDIF.
  ENDMETHOD.

  METHOD correct_to_factory_workday.
    IF iv_fabkl IS INITIAL OR iv_date IS INITIAL.
      rv_date = iv_date.
      RETURN.
    ENDIF.
    CALL FUNCTION 'DATE_CONVERT_TO_FACTORYDATE'
      EXPORTING
        correct_option               = '+'
        date                         = iv_date
        factory_calendar_id          = iv_fabkl
      IMPORTING
        date                         = rv_date
      EXCEPTIONS
        calendar_buffer_not_loadable = 1
        correct_option_invalid       = 2
        date_after_range             = 3
        date_before_range            = 4
        date_invalid                 = 5
        factory_calendar_not_found   = 6
        OTHERS                       = 7.
    IF sy-subrc <> 0.
      rv_date = iv_date.
    ENDIF.
  ENDMETHOD.

  METHOD factory_day_index.
    " Returns the factory-calendar day index (factorydate) for a date, correcting backward
    " ('-') onto the nearest workday. Legacy TAT = fdateto - fdatefrom + 1 uses this index.
    DATA lv_factorydate TYPE scal-facdate.
    IF iv_fabkl IS INITIAL OR iv_date IS INITIAL.
      rv_index = iv_date.   " fallback: calendar days (no calendar available)
      RETURN.
    ENDIF.
    CALL FUNCTION 'DATE_CONVERT_TO_FACTORYDATE'
      EXPORTING
        correct_option               = '-'
        date                         = iv_date
        factory_calendar_id          = iv_fabkl
      IMPORTING
        factorydate                  = lv_factorydate
      EXCEPTIONS
        calendar_buffer_not_loadable = 1
        correct_option_invalid       = 2
        date_after_range             = 3
        date_before_range            = 4
        date_invalid                 = 5
        factory_calendar_not_found   = 6
        OTHERS                       = 7.
    IF sy-subrc = 0.
      rv_index = lv_factorydate.
    ELSE.
      rv_index = iv_date.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
