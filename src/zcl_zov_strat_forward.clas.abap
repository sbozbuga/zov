CLASS zcl_zov_strat_forward DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_process_strategy.
  PRIVATE SECTION.
    CONSTANTS c_cutoff_default TYPE syuzeit VALUE '160000'.
ENDCLASS.



CLASS zcl_zov_strat_forward IMPLEMENTATION.

  METHOD zif_zov_process_strategy~handles.
    rv_yes = xsdbool( iv_otgrp = 'ZFL'  OR iv_otgrp = 'ZMTO'
                   OR iv_otgrp = 'ZRET' OR iv_otgrp = 'ZTRANS' ).
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_status.
    IF is_ctx-deliverdate IS NOT INITIAL.
      IF cs_result-orderstatecompl <> zif_zov_types=>state-deleted.
        cs_result-orderstatecompl = zif_zov_types=>state-closed.
      ENDIF.
      IF cs_result-dateclosed IS INITIAL.
        cs_result-dateclosed = is_ctx-deliverdate.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_commit_date.
    DATA lv_cutoff TYPE syuzeit.
    CHECK is_ctx-orderdate IS NOT INITIAL.

    lv_cutoff = COND #( WHEN is_ctx-cust-cutoff_time IS NOT INITIAL
                        THEN is_ctx-cust-cutoff_time
                        ELSE c_cutoff_default ).

    cs_result-initcommitdate = COND #(
      WHEN is_ctx-uhrzeitorder >= lv_cutoff
      THEN is_ctx-orderdate + 1
      ELSE is_ctx-orderdate ).
    " legacy corrects onto a factory workday BEFORE deriving auftragsendesoll
    cs_result-initcommitdate = zcl_zov_calc_util=>correct_to_factory_workday(
                                 iv_date = cs_result-initcommitdate iv_fabkl = is_ctx-fabkl ).

    " forward family: Lieferterminsoll = initcommitdate
    cs_result-auftragsendesoll = cs_result-initcommitdate.
  ENDMETHOD.

  METHOD zif_zov_process_strategy~base_date.
    rv_date = COND #( WHEN is_ctx-repdau-otdstart = '3000'
                      THEN is_ctx-dockdate
                      ELSE is_ctx-receivedate ).
  ENDMETHOD.

ENDCLASS.
