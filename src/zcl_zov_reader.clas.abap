CLASS zcl_zov_reader DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_reader.
ENDCLASS.



CLASS zcl_zov_reader IMPLEMENTATION.

  METHOD zif_zov_reader~read_contexts.
    " PILOT scope (status + dates): notification + sales header + delivery GI date.
    " Full parity (repdau, cust, serials, prices, ...) is added incrementally.
    CLEAR rt_ctx.

    " 1. notification + sales header
    SELECT qmnum, fenum, qmart, otgrp, oteil, item_aedat, kzloesch,
           vbeln, orderdate, uhrzeitorder, customergroup
      FROM zov_i_notif_sales
      WHERE qmnum IN @is_selection-r_qmnum
        AND otgrp IN @is_selection-r_otgrp
      INTO TABLE @DATA(lt_ns).

    " 2. delivery GI dates for the involved sales docs (branch by delivery type):
    "    VBTYP 'J' outbound -> deliverdate ; VBTYP 'T' returns -> receivedate
    IF lt_ns IS NOT INITIAL.
      " Enrichment reads use internal-table INNER JOINs (driver @lt_ns) instead of FOR ALL
      " ENTRIES. Benchmark (17892 items, 5 reps, ZOV_I_WKTNR_CUST): FAE 338ms vs JOIN 278ms
      " (~18% faster) with identical rows; join preserves exact-key semantics and bounds memory
      " unlike a ranged qmnum superset read. See PHASE6-VALIDATION.md.
      " De-dup the vbeln driver so a vbeln shared by several notif items yields the header once
      " (FOR ALL ENTRIES de-duplicated implicitly; INNER JOIN does not).
      DATA lt_vb TYPE SORTED TABLE OF vbeln_va WITH UNIQUE KEY table_line.
      LOOP AT lt_ns INTO DATA(ls_vb) WHERE vbeln IS NOT INITIAL.
        INSERT ls_vb-vbeln INTO TABLE lt_vb.
      ENDLOOP.

      SELECT v~sales_vbeln, v~deliverdate, v~likp_erdat, v~vbtyp
        FROM @lt_vb AS d INNER JOIN zov_i_delivery AS v
          ON v~sales_vbeln = d~table_line
        INTO TABLE @DATA(lt_dlv).
      SORT lt_dlv BY sales_vbeln.

      " invoices (billing date) per sales doc; ignore cancelled
      SELECT v~sales_vbeln, v~rechdatum, v~fksto
        FROM @lt_vb AS d INNER JOIN zov_i_invoice AS v
          ON v~sales_vbeln = d~table_line
        INTO TABLE @DATA(lt_inv).
      SORT lt_inv BY sales_vbeln.

      " Per-notification-item enrichment via targeted internal-table JOINs on the notif driver
      " (@lt_ns). NOTE: a single composite view (ZOV_I_ENRICH) was tried but its 8-deep
      " nested-LEFT-JOIN graph is materialized per call and made single-QMNUM reads ~3s each.
      " Targeted joins with tight ON keys prune far better. (Composite view retained for potential
      " true-bulk use; see PHASE6-VALIDATION.md.) lt_ns is unique per (qmnum,fenum) so no fan-out.
      SELECT v~qmnum, v~fenum, v~einlagerdate, v~akz, v~fanumber
        FROM @lt_ns AS d INNER JOIN zov_i_einlager AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_einl).
      SORT lt_einl BY qmnum fenum.

      " repair break (HOLD/E0003 on order objnr OR<fanumber>) -> breakstart/end -> breakduration.
      DATA lt_objnr TYPE SORTED TABLE OF j_objnr WITH UNIQUE KEY table_line.
      LOOP AT lt_einl INTO DATA(ls_faobj) WHERE fanumber IS NOT INITIAL.
        INSERT CONV j_objnr( |OR{ ls_faobj-fanumber }| ) INTO TABLE lt_objnr.
      ENDLOOP.
      IF lt_objnr IS NOT INITIAL.
        SELECT v~objnr, v~breakstart, v~breakend
          FROM @lt_objnr AS d INNER JOIN zov_i_break AS v
            ON v~objnr = d~table_line
          INTO TABLE @DATA(lt_brk).
        SORT lt_brk BY objnr.
      ENDIF.

      " dockdate/receivedate per notification item (ZREP->uepos sibling ZRET returns delivery)
      SELECT v~qmnum, v~fenum, v~dockdate, v~receivedate
        FROM @lt_ns AS d INNER JOIN zov_i_dockreceive AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_dr).
      SORT lt_dr BY qmnum fenum.

      " dockdate PRIMARY = ZPEPO service-task completion (overrides returns-delivery fallback)
      SELECT v~qmnum, v~fenum, v~dockdate_zp
        FROM @lt_ns AS d INNER JOIN zov_i_dock_zpepo AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_zp).
      SORT lt_zp BY qmnum fenum.

      " wktnr + cust1 flags + main-item abgru + fabkl + repdau
      SELECT v~qmnum, v~fenum, v~wktnr, v~werks, v~fabkl, v~scrap_prc_end, v~no_invoic_sd, v~abgru,
             v~rd_dauer, v~rd_kaltage, v~rd_rsende, v~rd_otdstart, v~cutoff_time
        FROM @lt_ns AS d INNER JOIN zov_i_wktnr_cust AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_wc).
      SORT lt_wc BY qmnum fenum.

      " serialization: kwmeng + serial profile
      SELECT v~qmnum, v~fenum, v~kwmeng, v~sernp
        FROM @lt_ns AS d INNER JOIN zov_i_serial AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_ser).
      SORT lt_ser BY qmnum fenum.

      " material/partner core + ADRC address + prctr + prctr_umsatz
      SELECT v~qmnum, v~fenum, v~ctdisapmatnummer, v~partnumberalc, v~shipto, v~waerk, v~prctr,
             v~shipto_name1, v~shipto_name2, v~shipto_name3, v~shipto_street,
             v~shipto_house_num, v~shipto_post_code, v~shipto_city1, v~shipto_sort1, v~prctr_umsatz
        FROM @lt_ns AS d INNER JOIN zov_i_matpartner AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_mp).
      SORT lt_mp BY qmnum fenum.

      " FA order fields
      SELECT v~qmnum, v~fenum, v~fanumber, v~rsende, v~fadate, v~kostv, v~faend, v~prctr_umsatz
        FROM @lt_ns AS d INNER JOIN zov_i_faorder AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_fa).
      SORT lt_fa BY qmnum fenum.

      " prices (ZIRL/ZIRC sub-item aggregation)
      SELECT v~qmnum, v~fenum, v~price_zirl, v~komppreis, v~kpwaers
        FROM @lt_ns AS d INNER JOIN zov_i_price AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_pr).
      SORT lt_pr BY qmnum fenum.

      " per-unit outbound delivery serials (1:n per item)
      SELECT v~qmnum, v~fenum, v~sernr, v~equnr
        FROM @lt_ns AS d INNER JOIN zov_i_deliv_serial AS v
          ON v~qmnum = d~qmnum AND v~fenum = d~fenum
        INTO TABLE @DATA(lt_dser).
      SORT lt_dser BY qmnum fenum sernr.
    ENDIF.

    " 3. build one context per notification item
    LOOP AT lt_ns INTO DATA(ls_ns).
      APPEND INITIAL LINE TO rt_ctx ASSIGNING FIELD-SYMBOL(<ctx>).
      <ctx>-qmnum         = ls_ns-qmnum.
      <ctx>-fenum         = ls_ns-fenum.
      <ctx>-counter       = 1.
      <ctx>-qmart         = ls_ns-qmart.
      <ctx>-otgrp         = ls_ns-otgrp.
      <ctx>-oteil         = ls_ns-oteil.
      <ctx>-aedat         = ls_ns-item_aedat.
      <ctx>-vbeln         = ls_ns-vbeln.
      <ctx>-orderdate     = ls_ns-orderdate.
      <ctx>-uhrzeitorder  = ls_ns-uhrzeitorder.
      <ctx>-customergroup = ls_ns-customergroup.
      <ctx>-refdate       = is_selection-refdate.

      LOOP AT lt_dlv INTO DATA(ls_dlv) WHERE sales_vbeln = ls_ns-vbeln.
        CASE ls_dlv-vbtyp.
          WHEN 'T'.        " returns delivery -> inbound goods receipt (FALLBACK, shared-vbeln)
            <ctx>-receivedate = ls_dlv-deliverdate.
            " dockdate fallback (legacy gt_lips_ret): returns-delivery date when not set by ZPEPO
            IF <ctx>-dockdate IS INITIAL.
              <ctx>-dockdate = ls_dlv-deliverdate.
            ENDIF.
          WHEN OTHERS.     " 'J' and other outbound -> delivery date
            <ctx>-deliverdate = ls_dlv-deliverdate.
        ENDCASE.
      ENDLOOP.

      " PRIMARY dockdate/receivedate: per-FENUM returns delivery (ZREP->uepos sibling ZRET),
      " then ZPEPO service-task date overrides dockdate.
      READ TABLE lt_dr INTO DATA(ls_dr)
        WITH KEY qmnum = ls_ns-qmnum fenum = ls_ns-fenum BINARY SEARCH.
      IF sy-subrc = 0.
        <ctx>-receivedate = ls_dr-receivedate.
        <ctx>-dockdate    = ls_dr-dockdate.
      ENDIF.
      READ TABLE lt_zp INTO DATA(ls_zp)
        WITH KEY qmnum = ls_ns-qmnum fenum = ls_ns-fenum BINARY SEARCH.
      IF sy-subrc = 0 AND ls_zp-dockdate_zp IS NOT INITIAL.
        <ctx>-dockdate = ls_zp-dockdate_zp.
      ENDIF.

      " rechdatum = latest non-cancelled invoice date for the sales doc
      LOOP AT lt_inv INTO DATA(ls_inv) WHERE sales_vbeln = ls_ns-vbeln
                                         AND fksto = abap_false.
        IF ls_inv-rechdatum > <ctx>-rechdatum.
          <ctx>-rechdatum = ls_inv-rechdatum.
        ENDIF.
      ENDLOOP.

      " material-doc BLDAT (via ZREP->VBEP->MKPF/SER03/OBJK) drives BOTH labelprint and
      " einlagerdate. Legacy: labelprint = bldat always; einlagerdate = bldat only when
      " otgrp <> ZRS4S (fill_missing_data lines ~6790/6796).
      " material-doc BLDAT drives labelprint (always) + einlagerdate (only when otgrp<>ZRS4S)
      READ TABLE lt_einl INTO DATA(ls_einl)
        WITH KEY qmnum = ls_ns-qmnum fenum = ls_ns-fenum BINARY SEARCH.
      IF sy-subrc = 0.
        <ctx>-labelprint = ls_einl-einlagerdate.
        IF ls_ns-otgrp <> 'ZRS4S'.
          <ctx>-einlagerdate = ls_einl-einlagerdate.
        ENDIF.
        <ctx>-akz = ls_einl-akz.

        " breakduration = breakend - breakstart (HOLD/E0003 on the FA order objnr)
        IF ls_einl-fanumber IS NOT INITIAL.
          READ TABLE lt_brk INTO DATA(ls_brk)
            WITH KEY objnr = |OR{ ls_einl-fanumber }| BINARY SEARCH.
          IF sy-subrc = 0 AND ls_brk-breakstart IS NOT INITIAL
                          AND ls_brk-breakend IS NOT INITIAL.
            <ctx>-breakduration = ls_brk-breakend - ls_brk-breakstart.
          ENDIF.
        ENDIF.
      ENDIF.

      " wktnr + customizing flags + main-item abgru + repdau
      READ TABLE lt_wc INTO DATA(ls_wc)
        WITH KEY qmnum = ls_ns-qmnum fenum = ls_ns-fenum BINARY SEARCH.
      IF sy-subrc = 0.
        <ctx>-wktnr               = ls_wc-wktnr.
        <ctx>-werks               = ls_wc-werks.
        <ctx>-fabkl               = ls_wc-fabkl.
        <ctx>-cust-scrap_prc_end  = ls_wc-scrap_prc_end.
        <ctx>-cust-no_invoic_sd   = ls_wc-no_invoic_sd.
        <ctx>-cust-cutoff_time    = ls_wc-cutoff_time.
        IF ls_wc-rd_dauer IS NOT INITIAL OR ls_wc-rd_rsende IS NOT INITIAL.
          <ctx>-repdau-found    = abap_true.
          <ctx>-repdau-dauer    = ls_wc-rd_dauer.
          <ctx>-repdau-kaltage  = ls_wc-rd_kaltage.
          <ctx>-repdau-rsende   = ls_wc-rd_rsende.
          <ctx>-repdau-otdstart = ls_wc-rd_otdstart.
        ENDIF.
      ENDIF.

      " one_day_offset (legacy ZCL_SCHEDULING=>GET_1_DAY_OFFSET, table ZORDVIEW_CUST2):
      " 1 if this record's wktnr (kvgr1=space) or customergroup (wktnr=space) is configured,
      " else 0. Used by auftragsendesoll and TAT.
      <ctx>-one_day_offset = zcl_scheduling=>get_1_day_offset(
                               iv_wktnr = <ctx>-wktnr
                               iv_kvgr1 = <ctx>-customergroup ).

      " DELETED: notification item deletion flag (kzloesch) OR main sales item cancelled (abgru)
      IF ls_ns-kzloesch IS NOT INITIAL OR ls_wc-abgru IS NOT INITIAL.
        <ctx>-is_deleted = abap_true.
      ENDIF.

      " Vereinzelung: emit one context per unit (counter 1..kwmeng) when the material is
      " serial-managed (serial profile sernp set); otherwise a single counter=1 (legacy guard
      " "IF counter > 1 AND sernp IS INITIAL. EXIT."). counter=1 is the base <ctx> already added.
      " group A material/partner + address
      READ TABLE lt_mp INTO DATA(ls_mp)
        WITH KEY qmnum = ls_ns-qmnum fenum = ls_ns-fenum BINARY SEARCH.
      IF sy-subrc = 0.
        <ctx>-ctdisapmatnummer = ls_mp-ctdisapmatnummer.
        <ctx>-partnumberalc    = ls_mp-partnumberalc.
        <ctx>-shipto           = ls_mp-shipto.
        <ctx>-waerk            = ls_mp-waerk.
        <ctx>-prctr            = ls_mp-prctr.
        <ctx>-shipto_name1     = ls_mp-shipto_name1.
        <ctx>-shipto_name2     = ls_mp-shipto_name2.
        <ctx>-shipto_name3     = ls_mp-shipto_name3.
        <ctx>-shipto_street    = ls_mp-shipto_street.
        <ctx>-shipto_house_num = ls_mp-shipto_house_num.
        <ctx>-shipto_post_code = ls_mp-shipto_post_code.
        <ctx>-shipto_city1     = ls_mp-shipto_city1.
        <ctx>-shipto_sort1     = ls_mp-shipto_sort1.
        " prctr_umsatz = notif item's own prctr (non-repair too); FA-order ZREP value overrides below.
        <ctx>-prctr_umsatz     = ls_mp-prctr_umsatz.
      ENDIF.

      " group D FA order fields
      READ TABLE lt_fa INTO DATA(ls_fao)
        WITH KEY qmnum = ls_ns-qmnum fenum = ls_ns-fenum BINARY SEARCH.
      IF sy-subrc = 0.
        <ctx>-fanumber = ls_fao-fanumber.
        <ctx>-fadate   = ls_fao-fadate.
        <ctx>-rsende   = ls_fao-rsende.
        <ctx>-kostv    = ls_fao-kostv.
        <ctx>-faend    = ls_fao-faend.
        IF ls_fao-prctr_umsatz IS NOT INITIAL.
          <ctx>-prctr_umsatz = ls_fao-prctr_umsatz.   " ZREP item prctr (repair families)
        ENDIF.
      ENDIF.

      " prices (ZIRL/ZIRC sub-item aggregation; KONP fallback pending)
      READ TABLE lt_pr INTO DATA(ls_pr)
        WITH KEY qmnum = ls_ns-qmnum fenum = ls_ns-fenum BINARY SEARCH.
      IF sy-subrc = 0.
        <ctx>-price     = ls_pr-price_zirl.
        <ctx>-komppreis = ls_pr-komppreis.
        <ctx>-kpwaers   = ls_pr-kpwaers.
      ENDIF.

      <ctx>-counter = 1.

      " outbound-delivery serials for this notif item, in serial order -> one per counter.
      DATA lt_unit_ser LIKE lt_dser.
      CLEAR lt_unit_ser.
      LOOP AT lt_dser INTO DATA(ls_dser2)
        WHERE qmnum = ls_ns-qmnum AND fenum = ls_ns-fenum.
        APPEND ls_dser2 TO lt_unit_ser.
      ENDLOOP.
      " counter 1 gets the first serial
      READ TABLE lt_unit_ser INTO DATA(ls_s1) INDEX 1.
      IF sy-subrc = 0.
        <ctx>-sernrlif        = ls_s1-sernr.
        <ctx>-equipmentnummer = ls_s1-equnr.
      ENDIF.

      READ TABLE lt_ser INTO DATA(ls_ser)
        WITH KEY qmnum = ls_ns-qmnum fenum = ls_ns-fenum BINARY SEARCH.
      IF sy-subrc = 0 AND ls_ser-sernp IS NOT INITIAL AND ls_ser-kwmeng > 1.
        DATA(ls_base) = <ctx>.                      " snapshot (field-symbol invalid after APPEND)
        CLEAR: ls_base-sernrlif, ls_base-equipmentnummer.
        DATA(lv_c)    = 2.
        WHILE lv_c <= ls_ser-kwmeng.
          DATA(ls_unit) = ls_base.
          ls_unit-counter = lv_c.
          READ TABLE lt_unit_ser INTO DATA(ls_sn) INDEX lv_c.
          IF sy-subrc = 0.
            ls_unit-sernrlif        = ls_sn-sernr.
            ls_unit-equipmentnummer = ls_sn-equnr.
          ENDIF.
          APPEND ls_unit TO rt_ctx.
          lv_c = lv_c + 1.
        ENDWHILE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
