CLASS zcl_zov_strat_default DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_process_strategy.
ENDCLASS.



CLASS zcl_zov_strat_default IMPLEMENTATION.

  METHOD zif_zov_process_strategy~handles.
    rv_yes = abap_true.
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_status.
    RETURN.
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
