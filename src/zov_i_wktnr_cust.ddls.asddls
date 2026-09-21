@AbapCatalog.sqlViewName: 'ZOVIWKTNRCUST'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: wktnr + cust1 by notif item'
// PERFORMANCE: reads from the pre-aggregated ZOV_I_WKTNR_BASE (VBAP already collapsed to the
// (qmnum,fenum) grain with a qmnum filter that prunes early) and joins the wktnr/werks lookups
// onto that small result — 1:1 joins, no GROUP BY over ~17.3M VBAP rows. Previously this view
// grouped all wktnr items and joined cust/repdau/plant/cutoff before any qmnum pruning could
// apply, which made itab-join / FOR ALL ENTRIES reads slow. Field list & semantics unchanged.
define view ZOV_I_WKTNR_CUST
  as select from ZOV_I_WKTNR_BASE as base
    left outer join zordview_cust1   as cust on base.wktnr = cust.wktnr
    left outer join ZOV_I_REPDAU     as rd   on base.wktnr = rd.wktnr
    left outer join t001w            as plnt on base.werks = plnt.werks
    left outer join zordview_cutofft as coff on base.wktnr = coff.wktnr
{
  key base.qmnum          as qmnum,
  key base.fenum          as fenum,
      base.wktnr          as wktnr,
      base.werks          as werks,
      plnt.fabkl          as fabkl,
      cust.scrap_prc_end  as scrap_prc_end,
      cust.no_invoic_sd   as no_invoic_sd,
      base.abgru          as abgru,
      rd.dauer            as rd_dauer,
      rd.kaltage          as rd_kaltage,
      rd.rsende           as rd_rsende,
      rd.otdstart         as rd_otdstart,
      coff.ab_uzeit       as cutoff_time
}
