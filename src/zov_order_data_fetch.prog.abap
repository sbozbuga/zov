*&---------------------------------------------------------------------*
*& Report ZOV_ORDER_DATA_FETCH
*&---------------------------------------------------------------------*
*& Modern parallel rewrite of /CELLAG/ORDER_DATA_FETCH.
*& Reads notifications via CDS, computes the order view with the pure
*& engine + strategies, and writes to the parallel table ZOV_ORDVIEW.
*& NEVER writes to /CELLAG/ORDVIEW.
*&---------------------------------------------------------------------*
REPORT zov_order_data_fetch.

TABLES: qmel.

SELECTION-SCREEN BEGIN OF BLOCK sel WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_qmnum FOR qmel-qmnum,
                  s_otgrp FOR qmel-qmnum NO INTERVALS.
  PARAMETERS:     p_refdat TYPE dats DEFAULT sy-datum.
SELECTION-SCREEN END OF BLOCK sel.

SELECTION-SCREEN BEGIN OF BLOCK mode WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_test TYPE abap_bool AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK mode.

START-OF-SELECTION.
  PERFORM main.

*&---------------------------------------------------------------------*
FORM main.
  " authorization: guard a real (non-test) ETL run.
  " Enforced via the dedicated ZOV auth object when present, else via the table
  " change-authorization S_TABU_NAM as a fallback. The dedicated object Z_ZOV must be
  " created in SU21 (it cannot be created from ADT):
  "   Object   : Z_ZOV   (class ZOV / custom)
  "   Field    : ACTVT   (data element ACTIV_AUTH), permitted activities 16 (execute), 02 (change)
  " Once Z_ZOV exists, replace the S_TABU_NAM check below with:
  "   AUTHORITY-CHECK OBJECT 'Z_ZOV' ID 'ACTVT' FIELD '16'.
  AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
    ID 'TABLE'  FIELD 'ZOV_ORDVIEW'
    ID 'ACTVT'  FIELD '02'.
  IF sy-subrc <> 0 AND p_test = abap_false.
    MESSAGE 'No authorization to update ZOV_ORDVIEW' TYPE 'E'.
    RETURN.
  ENDIF.

  DATA ls_sel TYPE zif_zov_reader=>ty_selection.
  ls_sel-refdate = p_refdat.
  LOOP AT s_qmnum INTO DATA(ls_q).
    APPEND VALUE #( sign = ls_q-sign option = ls_q-option
                    low = ls_q-low high = ls_q-high ) TO ls_sel-r_qmnum.
  ENDLOOP.
  LOOP AT s_otgrp INTO DATA(ls_o).
    APPEND VALUE #( sign = ls_o-sign option = ls_o-option
                    low = ls_o-low high = ls_o-high ) TO ls_sel-r_otgrp.
  ENDLOOP.

  " wire the pipeline: reader + engine (strategies from factory) + writer
  DATA(lo_reader)  = NEW zcl_zov_reader( ).
  DATA(lo_factory) = NEW zcl_zov_strategy_factory( ).
  DATA(lo_engine)  = NEW zcl_zov_engine(
    it_strategies = lo_factory->zif_zov_strategy_factory~build( )
    io_util       = NEW zcl_zov_calc_util( ) ).

  DATA lo_writer TYPE REF TO zif_zov_writer.
  IF p_test = abap_true.
    lo_writer = NEW zcl_zov_writer_null( ).
  ELSE.
    lo_writer = NEW zcl_zov_writer( ).
  ENDIF.

  DATA(lo_service) = NEW zcl_zov_service(
    io_reader = lo_reader io_engine = lo_engine io_writer = lo_writer ).

  TRY.
      DATA(ls_log) = lo_service->run( ls_sel ).
    CATCH zcx_zov_persist INTO DATA(lx).
      MESSAGE lx->get_text( ) TYPE 'E'.
      RETURN.
  ENDTRY.

  WRITE: / 'ZOV order-view run', p_refdat.
  IF p_test = abap_true.
    WRITE: / '(TEST mode - no data written)'.
  ENDIF.
  WRITE: / 'Contexts read :', ls_log-read.
  WRITE: / 'Rows computed :', ls_log-computed.
  WRITE: / 'Rows written  :', ls_log-written.
  WRITE: / '  closed      :', ls_log-closed.
  WRITE: / '  open        :', ls_log-open.
  WRITE: / '  deleted     :', ls_log-deleted.
ENDFORM.
