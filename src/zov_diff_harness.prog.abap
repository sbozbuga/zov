*&---------------------------------------------------------------------*
*& Report ZOV_DIFF_HARNESS
*&---------------------------------------------------------------------*
*& Analysis harness: runs the ZOV pipeline in-memory over a selection and
*& diffs every sourced field against stored /CELLAG/ORDVIEW. Read-only.
*& Shows per-field mismatch counts (ALV) and a sample of mismatches.
*&---------------------------------------------------------------------*
REPORT zov_diff_harness.

TABLES: qmel.

SELECT-OPTIONS: s_qmnum FOR qmel-qmnum.
PARAMETERS:     p_refdat TYPE dats DEFAULT sy-datum,
                p_sample TYPE i DEFAULT 100.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  DATA ls_sel TYPE zif_zov_reader=>ty_selection.
  ls_sel-refdate = p_refdat.
  LOOP AT s_qmnum INTO DATA(ls_q).
    APPEND VALUE #( sign = ls_q-sign option = ls_q-option
                    low = ls_q-low high = ls_q-high ) TO ls_sel-r_qmnum.
  ENDLOOP.

  DATA(lo_diff) = NEW zcl_zov_diff( ).
  DATA(ls_res)  = lo_diff->run( is_selection = ls_sel iv_sample_limit = p_sample ).

  " header summary
  WRITE: / 'ZOV field diff vs /CELLAG/ORDVIEW'.
  WRITE: / 'Rows compared:', ls_res-rows_compared,
         / 'Rows missing :', ls_res-rows_missing.
  ULINE.

  " field stats: only show fields that were actually compared
  DATA lt_stat LIKE ls_res-field_stats.
  LOOP AT ls_res-field_stats INTO DATA(ls_st) WHERE compared > 0.
    APPEND ls_st TO lt_stat.
  ENDLOOP.

  cl_demo_output=>new(
    )->begin_section( 'Per-field mismatch counts'
    )->write_data( lt_stat
    )->begin_section( 'Sample mismatches'
    )->write_data( ls_res-samples
    )->display( ).
ENDFORM.
