CLASS zcl_zov_strat_zrs4s DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_process_strategy.
ENDCLASS.



CLASS zcl_zov_strat_zrs4s IMPLEMENTATION.

  METHOD zif_zov_process_strategy~handles.
    rv_yes = xsdbool( iv_otgrp = 'ZRS4S' ).
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_status.
    " 1) ready to ship
    IF is_ctx-readytoship IS NOT INITIAL.
      IF cs_result-orderstatecompl <> zif_zov_types=>state-deleted.
        cs_result-orderstatecompl = zif_zov_types=>state-closed.
      ENDIF.
      cs_result-dateclosed = is_ctx-readytoship.
    ENDIF.

    " 2) delivered
    IF is_ctx-deliverdate IS NOT INITIAL.
      IF cs_result-orderstatecompl <> zif_zov_types=>state-deleted.
        cs_result-orderstatecompl = zif_zov_types=>state-closed.
      ENDIF.
      IF cs_result-dateclosed IS INITIAL.
        cs_result-dateclosed = is_ctx-deliverdate.
      ENDIF.
    ENDIF.

    " 3) Z2 cause present (QMUR, resolved by reader)
    IF is_ctx-qmur_found = abap_true.
      IF cs_result-orderstatecompl <> zif_zov_types=>state-deleted.
        cs_result-orderstatecompl = zif_zov_types=>state-closed.
      ENDIF.
      IF cs_result-dateclosed IS INITIAL.
        cs_result-dateclosed = is_ctx-qmur_aedat.
      ENDIF.
      IF cs_result-dateclosed IS INITIAL.
        cs_result-dateclosed = is_ctx-qmur_erdat.
      ENDIF.
    ENDIF.

    " scrap-is-process-end special (akz 'A*' = Aussonderung)
    IF is_ctx-cust-scrap_prc_end = abap_true
       AND cs_result-akz(1) = 'A'
       AND cs_result-orderstatecompl = zif_zov_types=>state-open
       AND is_ctx-labelprint IS NOT INITIAL.
      cs_result-orderstatecompl = zif_zov_types=>state-closed.
      cs_result-dateclosed      = is_ctx-labelprint.
    ENDIF.
  ENDMETHOD.

  METHOD zif_zov_process_strategy~determine_commit_date.
    IF cs_result-auftragsendesoll IS NOT INITIAL.
      cs_result-initcommitdate = cs_result-auftragsendesoll.
    ENDIF.
  ENDMETHOD.

  METHOD zif_zov_process_strategy~base_date.
    rv_date = COND #( WHEN is_ctx-repdau-otdstart = '3000'
                      THEN is_ctx-dockdate
                      ELSE is_ctx-receivedate ).
  ENDMETHOD.

ENDCLASS.
