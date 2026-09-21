CLASS zcl_zov_engine DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_engine.
    METHODS constructor
      IMPORTING it_strategies TYPE zif_zov_strategy_factory=>ty_strategy_t
                io_util       TYPE REF TO zcl_zov_calc_util.
  PRIVATE SECTION.
    DATA mt_strategies TYPE zif_zov_strategy_factory=>ty_strategy_t.
    DATA mo_util       TYPE REF TO zcl_zov_calc_util.
    METHODS strategy_for
      IMPORTING iv_otgrp  TYPE /cellag/otgrp
      RETURNING VALUE(ro) TYPE REF TO zif_zov_process_strategy.
ENDCLASS.



CLASS zcl_zov_engine IMPLEMENTATION.

  METHOD constructor.
    mt_strategies = it_strategies.
    mo_util       = io_util.
  ENDMETHOD.

  METHOD strategy_for.
    LOOP AT mt_strategies INTO DATA(lo_s).
      IF lo_s->handles( iv_otgrp ) = abap_true.
        ro = lo_s.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_zov_engine~compute.
    DATA(lo_strat) = strategy_for( is_ctx-otgrp ).

    rs_result-akz    = is_ctx-akz.
    rs_result-akz_we = is_ctx-akz_lips_ret.

    " per-counter serials (Vereinzelung) pass through from context
    rs_result-sernrlif        = is_ctx-sernrlif.
    rs_result-sernrrec        = is_ctx-sernrrec.
    rs_result-equipmentnummer = is_ctx-equipmentnummer.

    " group A material/partner enrichment pass through
    rs_result-ctdisapmatnummer = is_ctx-ctdisapmatnummer.
    rs_result-partnumberalc    = is_ctx-partnumberalc.
    rs_result-shipto           = is_ctx-shipto.
    rs_result-waerk            = is_ctx-waerk.
    rs_result-prctr            = is_ctx-prctr.
    rs_result-shipto_name1     = is_ctx-shipto_name1.
    rs_result-shipto_name2     = is_ctx-shipto_name2.
    rs_result-shipto_name3     = is_ctx-shipto_name3.
    rs_result-shipto_street    = is_ctx-shipto_street.
    rs_result-shipto_house_num = is_ctx-shipto_house_num.
    rs_result-shipto_post_code = is_ctx-shipto_post_code.
    rs_result-shipto_city1     = is_ctx-shipto_city1.
    rs_result-shipto_sort1     = is_ctx-shipto_sort1.

    " group D FA order fields pass through
    rs_result-fanumber = is_ctx-fanumber.
    rs_result-fadate   = is_ctx-fadate.
    rs_result-rsende   = is_ctx-rsende.
    rs_result-kostv    = is_ctx-kostv.
    rs_result-faend    = is_ctx-faend.
    rs_result-price     = is_ctx-price.
    rs_result-komppreis = is_ctx-komppreis.
    rs_result-kpwaers   = is_ctx-kpwaers.
    rs_result-prctr_umsatz = is_ctx-prctr_umsatz.

    " DELETED is terminal: kzloesch or main-item abgru -> DELETED + archive, skip strategy.
    IF is_ctx-is_deleted = abap_true.
      rs_result-orderstatecompl = zif_zov_types=>state-deleted.
      rs_result-archivflag      = abap_true.
      RETURN.
    ENDIF.

    " default state is OPEN; strategies set CLOSED.
    rs_result-orderstatecompl = zif_zov_types=>state-open.

    lo_strat->determine_status( EXPORTING is_ctx = is_ctx CHANGING cs_result = rs_result ).
    mo_util->derive_target_end_date( EXPORTING is_ctx = is_ctx CHANGING cs_result = rs_result ).

    DATA(lv_base) = lo_strat->base_date( is_ctx ).
    mo_util->derive_tat_overdue( EXPORTING is_ctx = is_ctx iv_base = lv_base
                                 CHANGING cs_result = rs_result ).

    lo_strat->determine_commit_date( EXPORTING is_ctx = is_ctx CHANGING cs_result = rs_result ).
    mo_util->clamp_numerics( CHANGING cs_result = rs_result ).
  ENDMETHOD.

ENDCLASS.
