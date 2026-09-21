CLASS zcl_zov_strat_zil DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_process_strategy.
ENDCLASS.



CLASS zcl_zov_strat_zil IMPLEMENTATION.

  METHOD zif_zov_process_strategy~handles.
    rv_yes = xsdbool( iv_otgrp = 'ZIL' ).
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_status.
    IF is_ctx-receivedate IS NOT INITIAL.
      IF cs_result-orderstatecompl <> zif_zov_types=>state-deleted.
        cs_result-orderstatecompl = zif_zov_types=>state-closed.
      ENDIF.
      IF cs_result-dateclosed IS INITIAL.
        cs_result-dateclosed = is_ctx-receivedate.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_commit_date.
    RETURN.
  ENDMETHOD.

  METHOD zif_zov_process_strategy~base_date.
    rv_date = COND #( WHEN is_ctx-repdau-otdstart = '3000'
                      THEN is_ctx-dockdate
                      ELSE is_ctx-receivedate ).
  ENDMETHOD.

ENDCLASS.
