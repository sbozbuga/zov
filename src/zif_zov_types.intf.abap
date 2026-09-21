INTERFACE zif_zov_types
  PUBLIC .

  CONSTANTS:
    BEGIN OF state,
      open    TYPE c LENGTH 1 VALUE 'O',
      closed  TYPE c LENGTH 1 VALUE 'C',
      deleted TYPE c LENGTH 1 VALUE 'D',
    END OF state.

  CONSTANTS:
    BEGIN OF qmart,
      z1 TYPE qmart VALUE 'Z1',
      zx TYPE qmart VALUE 'ZX',
    END OF qmart.

  TYPES: BEGIN OF ty_liefpos,
           vbeln TYPE vbeln_va,
           uepos TYPE uepos,
           abgru TYPE abgru_va,
         END OF ty_liefpos,
         ty_liefpos_t TYPE SORTED TABLE OF ty_liefpos WITH NON-UNIQUE KEY vbeln uepos.

  TYPES: BEGIN OF ty_repdau,
           found    TYPE abap_bool,
           dauer    TYPE /cellag/repdauer,
           kaltage  TYPE /cellag/kaltage,
           rsende   TYPE /cellag/rsende,
           otdstart TYPE c LENGTH 4,
         END OF ty_repdau.

  TYPES: BEGIN OF ty_cust,
           no_invoic_sd    TYPE abap_bool,
           scrap_prc_end   TYPE abap_bool,
           cutoff_time     TYPE syuzeit,
           prctr_from_marc TYPE abap_bool,
         END OF ty_cust.

  TYPES: BEGIN OF ty_calc_context,
           qmnum           TYPE qmnum,
           fenum           TYPE felfd,
           counter         TYPE cim_count,
           qmart           TYPE qmart,
           otgrp           TYPE /cellag/otgrp,
           oteil           TYPE oteil,
           aedat           TYPE aedat,
           vbeln           TYPE vbeln_va,
           posnr           TYPE posnr_va,
           pstyv           TYPE pstyv,
           vkgru           TYPE vkgru,
           kwmeng          TYPE kwmeng,
           werks           TYPE werks_d,
           wktnr           TYPE wktnr,
           wktps           TYPE wktps,
           customergroup   TYPE kvgr1,
           shipto          TYPE kunwe,
           gbstk           TYPE gbstk,
           fksaa           TYPE fksaa,
           fast_good_parts TYPE abap_bool,
           abgru_ret       TYPE abgru_va,
           abgru_aedat     TYPE aedat,
           orderdate       TYPE /cellag/orderdate,
           uhrzeitorder    TYPE /cellag/uhrzeitorder,
           dockdate        TYPE /cellag/dockdate,
           receivedate     TYPE /cellag/receivedate,
           readytoship     TYPE /cellag/readytoship,
           deliverdate     TYPE /cellag/deliverdate,
           einlagerdate    TYPE /cellag/einlagerdate,
           rsende          TYPE /cellag/rsende,
           rechdatum       TYPE /cellag/rechdatum,
           labelprint      TYPE /cellag/labelprint,
           akz             TYPE /cellag/akz,
           akz_lips_ret    TYPE /cellag/akz,
           liefpos         TYPE ty_liefpos_t,
           qmur_found      TYPE abap_bool,
           qmur_aedat      TYPE aedat,
           qmur_erdat      TYPE erdat,
           bemot           TYPE bemot,
           bemot_found     TYPE abap_bool,
           repdau          TYPE ty_repdau,
           cust            TYPE ty_cust,
           fabkl           TYPE wfcid,
           one_day_offset  TYPE int4,
           breakduration   TYPE /cellag/breakduration,  " repair-order interruption days (JEST/JCDS)
           gv_10days_back  TYPE dats,
           refdate         TYPE dats,
           is_deleted      TYPE abap_bool,   " kzloesch OR main-item abgru set
           " per-counter serial (Vereinzelung): set by the reader per unit
           sernrlif        TYPE /cellag/sernrlif,     " outbound delivery serial for this unit
           sernrrec        TYPE /cellag/sernrrec,     " returns delivery serial for this unit
           equipmentnummer TYPE equnr,                " equipment for this unit
           " group A material/partner enrichment
           ctdisapmatnummer TYPE matnr,               " = QMFE-BAUTL
           partnumberalc    TYPE /cellag/partnumberalc, " = MARA-MFRPN of bautl
           waerk            TYPE waerk,                " document currency (VBAP-waerk)
           prctr            TYPE prctr,                " profit center (MARC if otgrp in cust, else VBAP)
           " ship-to address block (VBPA WE -> ADRC)
           shipto_name1     TYPE ad_name1,
           shipto_name2     TYPE ad_name2,
           shipto_name3     TYPE ad_name3,
           shipto_street    TYPE ad_street,
           shipto_house_num TYPE ad_hsnm1,
           shipto_post_code TYPE ad_pstcd1,
           shipto_city1     TYPE ad_city1,
           shipto_sort1     TYPE ad_sort1,
           " group D FA order fields (ZREP item -> VBEP -> AUFK)
           fanumber         TYPE /cellag/fanumber,     " = VBEP-aufnr
           fadate           TYPE /cellag/fadate,       " = AUFK-erdat
           kostv            TYPE aufkostv,             " = AUFK-kostv
           faend            TYPE /cellag/faend,        " = JCDS E0001(WFER) activation udate
           " prices (ZIRL Z_SKZ_PRICE sub-item sum; KONP fallback pending)
           price            TYPE /cellag/price,
           komppreis        TYPE /cellag/komppreis,    " = sum ZIRC sub-item netwr
           kpwaers          TYPE /cellag/kpwaers,      " = ZIRC waerk
           prctr_umsatz     TYPE zd_prctr_umsatz,      " = ZREP item VBAP-prctr (own, not MARC)
         END OF ty_calc_context.

  TYPES: BEGIN OF ty_calc_result,
           orderstatecompl  TYPE /cellag/orderstatecompl,
           dateclosed       TYPE /cellag/dateclosed,
           archivflag       TYPE /cellag/archivflag,
           akz              TYPE /cellag/akz,
           akz_we           TYPE zd_akz_we,
           repdauer         TYPE /cellag/repdauer,
           kaltage          TYPE /cellag/kaltage,
           webaz            TYPE webaz,
           auftragsendesoll TYPE /cellag/auftragsendesoll,
           initcommitdate   TYPE /cellag/initcommitdate,
           tat              TYPE /cellag/tat,
           overdue          TYPE /cellag/overdue,
           no_docking       TYPE /cellag/no_docking,
           skz              TYPE /cellag/skz,
           lieferlager      TYPE /cellag/lieferlager,
           lieferwerk       TYPE /cellag/lieferwerk,
           sernrlif         TYPE /cellag/sernrlif,
           sernrrec         TYPE /cellag/sernrrec,
           equipmentnummer  TYPE equnr,
           ctdisapmatnummer TYPE matnr,
           partnumberalc    TYPE /cellag/partnumberalc,
           shipto           TYPE kunwe,
           waerk            TYPE waerk,
           fanumber         TYPE /cellag/fanumber,
           fadate           TYPE /cellag/fadate,
           rsende           TYPE /cellag/rsende,
           kostv            TYPE aufkostv,
           faend            TYPE /cellag/faend,
           price            TYPE /cellag/price,
           komppreis        TYPE /cellag/komppreis,
           kpwaers          TYPE /cellag/kpwaers,
           prctr_umsatz     TYPE zd_prctr_umsatz,
           prctr            TYPE prctr,
           shipto_name1     TYPE ad_name1,
           shipto_name2     TYPE ad_name2,
           shipto_name3     TYPE ad_name3,
           shipto_street    TYPE ad_street,
           shipto_house_num TYPE ad_hsnm1,
           shipto_post_code TYPE ad_pstcd1,
           shipto_city1     TYPE ad_city1,
           shipto_sort1     TYPE ad_sort1,
           value_capped     TYPE abap_bool,
         END OF ty_calc_result.

ENDINTERFACE.
