CLASS zcl_zov_diff DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_field_stat,
             field    TYPE fieldname,
             compared TYPE i,
             mismatch TYPE i,
           END OF ty_field_stat,
           ty_field_stat_t TYPE STANDARD TABLE OF ty_field_stat WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_mismatch,
             qmnum   TYPE qmnum,
             fenum   TYPE felfd,
             counter TYPE cim_count,
             field   TYPE fieldname,
             legacy  TYPE string,
             zov     TYPE string,
           END OF ty_mismatch,
           ty_mismatch_t TYPE STANDARD TABLE OF ty_mismatch WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_result,
             rows_compared TYPE i,
             rows_missing  TYPE i,   " computed but no stored legacy row (or vice versa)
             field_stats   TYPE ty_field_stat_t,
             samples       TYPE ty_mismatch_t,   " capped sample of mismatches
           END OF ty_result.

    METHODS run
      IMPORTING is_selection    TYPE zif_zov_reader=>ty_selection
                iv_sample_limit TYPE i DEFAULT 50
      RETURNING VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    " the fields ZOV currently sources & is expected to reproduce (compared set).
    " Anything not in this list is intentionally not compared (deferred subsystems).
    METHODS compared_fields
      RETURNING VALUE(rt_fields) TYPE ty_field_stat_t.
ENDCLASS.



CLASS zcl_zov_diff IMPLEMENTATION.

  METHOD compared_fields.
    DATA(lt) = VALUE string_table(
      ( `ORDERSTATECOMPL` ) ( `DATECLOSED` ) ( `ARCHIVFLAG` )
      ( `REPDAUER` ) ( `KALTAGE` ) ( `WEBAZ` )
      ( `AUFTRAGSENDESOLL` ) ( `INITCOMMITDATE` ) ( `TAT` ) ( `OVERDUE` )
      ( `SERNRLIF` )
      ( `CTDISAPMATNUMMER` ) ( `PARTNUMBERALC` ) ( `SHIPTO` ) ( `WAERK` ) ( `PRCTR` )
      ( `SHIPTO_NAME1` ) ( `SHIPTO_NAME2` ) ( `SHIPTO_NAME3` ) ( `SHIPTO_STREET` )
      ( `SHIPTO_HOUSE_NUM` ) ( `SHIPTO_POST_CODE` ) ( `SHIPTO_CITY1` ) ( `SHIPTO_SORT1` )
      ( `FANUMBER` ) ( `FADATE` ) ( `RSENDE` ) ( `KOSTV` ) ( `FAEND` )
      ( `PRICE` ) ( `KOMPPREIS` ) ( `KPWAERS` ) ( `PRCTR_UMSATZ` ) ).
    LOOP AT lt INTO DATA(lv_f).
      APPEND VALUE #( field = lv_f ) TO rt_fields.
    ENDLOOP.
  ENDMETHOD.

  METHOD run.
    DATA(lo_reader)  = NEW zcl_zov_reader( ).
    DATA(lo_factory) = NEW zcl_zov_strategy_factory( ).
    DATA(lo_engine)  = NEW zcl_zov_engine(
      it_strategies = lo_factory->zif_zov_strategy_factory~build( )
      io_util       = NEW zcl_zov_calc_util( ) ).

    rs_result-field_stats = compared_fields( ).

    DATA(lt_ctx) = lo_reader->zif_zov_reader~read_contexts( is_selection ).

    LOOP AT lt_ctx INTO DATA(ls_ctx).
      DATA(ls_res) = lo_engine->zif_zov_engine~compute( ls_ctx ).

      " map computed result into a ZOV_ORDVIEW-shaped row for uniform field access
      DATA ls_zov TYPE zov_ordview.
      CLEAR ls_zov.
      ls_zov-qmnum   = ls_ctx-qmnum.
      ls_zov-fenum   = ls_ctx-fenum.
      ls_zov-counter = ls_ctx-counter.
      ls_zov-orderstatecompl  = ls_res-orderstatecompl.
      ls_zov-dateclosed       = ls_res-dateclosed.
      ls_zov-archivflag       = ls_res-archivflag.
      ls_zov-akz              = ls_res-akz.
      ls_zov-akz_we           = ls_res-akz_we.
      ls_zov-repdauer         = ls_res-repdauer.
      ls_zov-kaltage          = ls_res-kaltage.
      ls_zov-webaz            = ls_res-webaz.
      ls_zov-auftragsendesoll = ls_res-auftragsendesoll.
      ls_zov-initcommitdate   = ls_res-initcommitdate.
      ls_zov-tat              = ls_res-tat.
      ls_zov-overdue          = ls_res-overdue.
      ls_zov-sernrlif         = ls_res-sernrlif.
      ls_zov-sernrrec         = ls_res-sernrrec.
      ls_zov-equipmentnummer  = ls_res-equipmentnummer.
      ls_zov-ctdisapmatnummer = ls_res-ctdisapmatnummer.
      ls_zov-partnumberalc    = ls_res-partnumberalc.
      ls_zov-shipto           = ls_res-shipto.
      ls_zov-waerk            = ls_res-waerk.
      ls_zov-prctr            = ls_res-prctr.
      ls_zov-shipto_name1     = ls_res-shipto_name1.
      ls_zov-shipto_name2     = ls_res-shipto_name2.
      ls_zov-shipto_name3     = ls_res-shipto_name3.
      ls_zov-shipto_street    = ls_res-shipto_street.
      ls_zov-shipto_house_num = ls_res-shipto_house_num.
      ls_zov-shipto_post_code = ls_res-shipto_post_code.
      ls_zov-shipto_city1     = ls_res-shipto_city1.
      ls_zov-shipto_sort1     = ls_res-shipto_sort1.
      ls_zov-fanumber         = ls_res-fanumber.
      ls_zov-fadate           = ls_res-fadate.
      ls_zov-rsende           = ls_res-rsende.
      ls_zov-kostv            = ls_res-kostv.
      ls_zov-faend            = ls_res-faend.
      ls_zov-price            = ls_res-price.
      ls_zov-komppreis        = ls_res-komppreis.
      ls_zov-kpwaers          = ls_res-kpwaers.
      ls_zov-prctr_umsatz     = ls_res-prctr_umsatz.

      " stored legacy row
      SELECT SINGLE * FROM /cellag/ordview
        WHERE qmnum = @ls_ctx-qmnum AND fenum = @ls_ctx-fenum AND counter = @ls_ctx-counter
        INTO @DATA(ls_leg).
      IF sy-subrc <> 0.
        rs_result-rows_missing = rs_result-rows_missing + 1.
        CONTINUE.
      ENDIF.
      rs_result-rows_compared = rs_result-rows_compared + 1.

      " compare each sourced field via RTTI field access
      LOOP AT rs_result-field_stats ASSIGNING FIELD-SYMBOL(<fs>).
        ASSIGN COMPONENT <fs>-field OF STRUCTURE ls_zov TO FIELD-SYMBOL(<z>).
        CHECK sy-subrc = 0.
        ASSIGN COMPONENT <fs>-field OF STRUCTURE ls_leg TO FIELD-SYMBOL(<l>).
        CHECK sy-subrc = 0.
        <fs>-compared = <fs>-compared + 1.
        IF <z> <> <l>.
          <fs>-mismatch = <fs>-mismatch + 1.
          IF lines( rs_result-samples ) < iv_sample_limit.
            APPEND VALUE #( qmnum = ls_ctx-qmnum fenum = ls_ctx-fenum
                            counter = ls_ctx-counter field = <fs>-field
                            legacy = |{ <l> }| zov = |{ <z> }| ) TO rs_result-samples.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
