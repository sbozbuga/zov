CLASS zcl_zov_service DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_run_log,
             read     TYPE i,
             computed TYPE i,
             written  TYPE i,
             closed   TYPE i,
             open     TYPE i,
             deleted  TYPE i,
           END OF ty_run_log.

    METHODS constructor
      IMPORTING io_reader TYPE REF TO zif_zov_reader
                io_engine TYPE REF TO zif_zov_engine
                io_writer TYPE REF TO zif_zov_writer.

    METHODS run
      IMPORTING is_selection  TYPE zif_zov_reader=>ty_selection
      RETURNING VALUE(rs_log) TYPE ty_run_log
      RAISING   zcx_zov_persist.

  PRIVATE SECTION.
    DATA mo_reader TYPE REF TO zif_zov_reader.
    DATA mo_engine TYPE REF TO zif_zov_engine.
    DATA mo_writer TYPE REF TO zif_zov_writer.

    METHODS serialize
      IMPORTING it_ctx        TYPE zif_zov_reader=>ty_context_t
      RETURNING VALUE(rt_ctx) TYPE zif_zov_reader=>ty_context_t.
ENDCLASS.



CLASS zcl_zov_service IMPLEMENTATION.

  METHOD constructor.
    mo_reader = io_reader.
    mo_engine = io_engine.
    mo_writer = io_writer.
  ENDMETHOD.

  METHOD run.
    DATA lt_rows TYPE zif_zov_writer=>ty_rows_t.

    " 1. gather contexts
    DATA(lt_ctx) = mo_reader->read_contexts( is_selection ).
    rs_log-read = lines( lt_ctx ).

    " 2. serialization (Vereinzelung) — single explicit step
    lt_ctx = serialize( lt_ctx ).

    " 3. compute each row (pure) + build output rows
    LOOP AT lt_ctx INTO DATA(ls_ctx).
      DATA(ls_res) = mo_engine->compute( ls_ctx ).

      DATA ls_row TYPE zov_ordview.
      CLEAR ls_row.
      " keys + reader-owned fields
      ls_row-mandt   = sy-mandt.
      ls_row-qmnum   = ls_ctx-qmnum.
      ls_row-fenum   = ls_ctx-fenum.
      ls_row-counter = ls_ctx-counter.
      ls_row-qmart   = ls_ctx-qmart.
      ls_row-otgrp   = ls_ctx-otgrp.
      ls_row-vbeln   = ls_ctx-vbeln.
      ls_row-posnr   = ls_ctx-posnr.
      ls_row-werks   = ls_ctx-werks.
      ls_row-wktnr   = ls_ctx-wktnr.
      ls_row-wktps   = ls_ctx-wktps.
      " engine-owned fields
      ls_row-orderstatecompl  = ls_res-orderstatecompl.
      ls_row-dateclosed       = ls_res-dateclosed.
      ls_row-archivflag       = ls_res-archivflag.
      ls_row-akz              = ls_res-akz.
      ls_row-akz_we           = ls_res-akz_we.
      ls_row-repdauer         = ls_res-repdauer.
      ls_row-kaltage          = ls_res-kaltage.
      ls_row-webaz            = ls_res-webaz.
      ls_row-auftragsendesoll = ls_res-auftragsendesoll.
      ls_row-initcommitdate   = ls_res-initcommitdate.
      ls_row-tat              = ls_res-tat.
      ls_row-overdue          = ls_res-overdue.
      ls_row-no_docking       = ls_res-no_docking.
      ls_row-skz              = ls_res-skz.
      ls_row-lieferlager      = ls_res-lieferlager.
      ls_row-lieferwerk       = ls_res-lieferwerk.
      ls_row-value_capped     = ls_res-value_capped.
      " enrichment fields (Phase 3 tail + Phase 4 groups A/B/C/D + additive)
      ls_row-sernrlif         = ls_res-sernrlif.
      ls_row-sernrrec         = ls_res-sernrrec.
      ls_row-equipmentnummer  = ls_res-equipmentnummer.
      ls_row-ctdisapmatnummer = ls_res-ctdisapmatnummer.
      ls_row-partnumberalc    = ls_res-partnumberalc.
      ls_row-shipto           = ls_res-shipto.
      ls_row-waerk            = ls_res-waerk.
      ls_row-prctr            = ls_res-prctr.
      ls_row-fanumber         = ls_res-fanumber.
      ls_row-fadate           = ls_res-fadate.
      ls_row-rsende           = ls_res-rsende.
      ls_row-kostv            = ls_res-kostv.
      ls_row-faend            = ls_res-faend.
      ls_row-price            = ls_res-price.
      ls_row-komppreis        = ls_res-komppreis.
      ls_row-kpwaers          = ls_res-kpwaers.
      ls_row-prctr_umsatz     = ls_res-prctr_umsatz.
      ls_row-shipto_name1     = ls_res-shipto_name1.
      ls_row-shipto_name2     = ls_res-shipto_name2.
      ls_row-shipto_name3     = ls_res-shipto_name3.
      ls_row-shipto_street    = ls_res-shipto_street.
      ls_row-shipto_house_num = ls_res-shipto_house_num.
      ls_row-shipto_post_code = ls_res-shipto_post_code.
      ls_row-shipto_city1     = ls_res-shipto_city1.
      ls_row-shipto_sort1     = ls_res-shipto_sort1.
      APPEND ls_row TO lt_rows.

      CASE ls_res-orderstatecompl.
        WHEN 'C'. rs_log-closed  = rs_log-closed  + 1.
        WHEN 'O'. rs_log-open    = rs_log-open    + 1.
        WHEN 'D'. rs_log-deleted = rs_log-deleted + 1.
      ENDCASE.
    ENDLOOP.
    rs_log-computed = lines( lt_rows ).

    " 4. persist (real writer -> ZOV_ORDVIEW ; null writer in test mode)
    mo_writer->save( lt_rows ).
    rs_log-written = lines( lt_rows ).
  ENDMETHOD.

  METHOD serialize.
    " Vereinzelung is performed in the reader (ZCL_ZOV_READER emits one context per unit,
    " COUNTER 1..kwmeng when the material's serial profile is set). This step is therefore a
    " pass-through; kept as an explicit pipeline stage for clarity and future override.
    rt_ctx = it_ctx.
  ENDMETHOD.

ENDCLASS.
