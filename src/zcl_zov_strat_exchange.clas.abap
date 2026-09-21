CLASS zcl_zov_strat_exchange DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_process_strategy.
  PRIVATE SECTION.
    CONSTANTS c_cutoff_default TYPE syuzeit VALUE '160000'.
    METHODS is_done
      IMPORTING is_ctx         TYPE zif_zov_types=>ty_calc_context
      RETURNING VALUE(rv_done) TYPE abap_bool.
ENDCLASS.



CLASS zcl_zov_strat_exchange IMPLEMENTATION.

  METHOD zif_zov_process_strategy~handles.
    rv_yes = xsdbool( iv_otgrp = 'ZRL4L' OR iv_otgrp = 'ZRADR' OR iv_otgrp = 'ZRREF'
                   OR iv_otgrp = 'ZRREFRS' OR iv_otgrp = 'ZSWUPDAT' ).
  ENDMETHOD.

  METHOD is_done.
    DATA lv_total TYPE i.
    DATA lv_open  TYPE i.
    LOOP AT is_ctx-liefpos INTO DATA(ls_lp)
         WHERE vbeln = is_ctx-vbeln AND uepos = is_ctx-posnr.
      lv_total = lv_total + 1.
      IF ls_lp-abgru IS INITIAL.
        lv_open = lv_open + 1.
      ENDIF.
    ENDLOOP.
    rv_done = xsdbool( lv_total > 0 AND lv_open = 0 ).
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_status.
    DATA(lv_done)    = is_done( is_ctx ).
    DATA(lv_trigger) = xsdbool( is_ctx-deliverdate IS NOT INITIAL OR lv_done = abap_true ).

    CHECK lv_trigger = abap_true.

    " A) einlager
    IF is_ctx-einlagerdate IS NOT INITIAL.
      IF cs_result-orderstatecompl <> zif_zov_types=>state-deleted.
        cs_result-orderstatecompl = zif_zov_types=>state-closed.
      ENDIF.
      cs_result-dateclosed = is_ctx-einlagerdate.
    ENDIF.

    " B) oteil MM / MO
    IF is_ctx-oteil = 'MM' OR is_ctx-oteil = 'MO'.
      IF cs_result-orderstatecompl <> zif_zov_types=>state-deleted.
        cs_result-orderstatecompl = zif_zov_types=>state-closed.
      ENDIF.
      cs_result-dateclosed = is_ctx-aedat.
    ENDIF.

    " C) return cancelled
    IF is_ctx-abgru_ret IS NOT INITIAL.
      IF cs_result-orderstatecompl <> zif_zov_types=>state-deleted.
        cs_result-orderstatecompl = zif_zov_types=>state-closed.
      ENDIF.
      cs_result-dateclosed = COND #( WHEN is_ctx-deliverdate > is_ctx-abgru_aedat
                                     THEN is_ctx-deliverdate
                                     ELSE is_ctx-abgru_aedat ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_commit_date.
    IF is_ctx-otgrp = 'ZRL4L'.
      IF is_ctx-receivedate IS NOT INITIAL.
        cs_result-initcommitdate = is_ctx-receivedate.
      ENDIF.
      RETURN.
    ENDIF.

    CHECK is_ctx-orderdate IS NOT INITIAL.
    DATA(lv_cutoff) = COND syuzeit( WHEN is_ctx-cust-cutoff_time IS NOT INITIAL
                                    THEN is_ctx-cust-cutoff_time
                                    ELSE c_cutoff_default ).
    cs_result-initcommitdate = COND #( WHEN is_ctx-uhrzeitorder >= lv_cutoff
                                       THEN is_ctx-orderdate + 1
                                       ELSE is_ctx-orderdate ).
    " legacy corrects initcommitdate onto a factory workday (default option '+')
    cs_result-initcommitdate = zcl_zov_calc_util=>correct_to_factory_workday(
                                 iv_date = cs_result-initcommitdate iv_fabkl = is_ctx-fabkl ).
  ENDMETHOD.

  METHOD zif_zov_process_strategy~base_date.
    rv_date = COND #( WHEN is_ctx-repdau-otdstart = '3000'
                      THEN is_ctx-dockdate
                      ELSE is_ctx-receivedate ).
  ENDMETHOD.

ENDCLASS.
