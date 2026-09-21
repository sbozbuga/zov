@AbapCatalog.sqlViewName: 'ZOVIENRICH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: composite enrichment by notif item'
define view ZOV_I_ENRICH
  as select from ZOV_I_NOTIFKEY as k
    left outer join ZOV_I_EINLAGER   as ei on  k.qmnum = ei.qmnum and k.fenum = ei.fenum
    left outer join ZOV_I_DOCKRECEIVE as dr on k.qmnum = dr.qmnum and k.fenum = dr.fenum
    left outer join ZOV_I_DOCK_ZPEPO as zp on  k.qmnum = zp.qmnum and k.fenum = zp.fenum
    left outer join ZOV_I_WKTNR_CUST as wc on  k.qmnum = wc.qmnum and k.fenum = wc.fenum
    left outer join ZOV_I_SERIAL     as se on  k.qmnum = se.qmnum and k.fenum = se.fenum
    left outer join ZOV_I_MATPARTNER as mp on  k.qmnum = mp.qmnum and k.fenum = mp.fenum
    left outer join ZOV_I_FAORDER    as fa on  k.qmnum = fa.qmnum and k.fenum = fa.fenum
    left outer join ZOV_I_PRICE      as pr on  k.qmnum = pr.qmnum and k.fenum = pr.fenum
{
  key k.qmnum                as qmnum,
  key k.fenum                as fenum,
      // einlager
      ei.einlagerdate        as einlagerdate,
      ei.akz                 as akz,
      ei.fanumber            as ei_fanumber,
      // dock/receive
      dr.dockdate            as dockdate,
      dr.receivedate         as receivedate,
      // ZPEPO dockdate (primary)
      zp.dockdate_zp         as dockdate_zp,
      // wktnr + cust1
      wc.wktnr               as wktnr,
      wc.werks               as werks,
      wc.fabkl               as fabkl,
      wc.scrap_prc_end       as scrap_prc_end,
      wc.no_invoic_sd        as no_invoic_sd,
      wc.abgru               as abgru,
      wc.rd_dauer            as rd_dauer,
      wc.rd_kaltage          as rd_kaltage,
      wc.rd_rsende           as rd_rsende,
      wc.rd_otdstart         as rd_otdstart,
      wc.cutoff_time         as cutoff_time,
      // serialization
      se.kwmeng              as kwmeng,
      se.sernp               as sernp,
      // material/partner + address
      mp.ctdisapmatnummer    as ctdisapmatnummer,
      mp.partnumberalc       as partnumberalc,
      mp.shipto              as shipto,
      mp.waerk               as waerk,
      mp.prctr               as prctr,
      mp.shipto_name1        as shipto_name1,
      mp.shipto_name2        as shipto_name2,
      mp.shipto_name3        as shipto_name3,
      mp.shipto_street       as shipto_street,
      mp.shipto_house_num    as shipto_house_num,
      mp.shipto_post_code    as shipto_post_code,
      mp.shipto_city1        as shipto_city1,
      mp.shipto_sort1        as shipto_sort1,
      mp.prctr_umsatz        as mp_prctr_umsatz,
      // FA order
      fa.fanumber            as fanumber,
      fa.rsende              as rsende,
      fa.fadate              as fadate,
      fa.kostv               as kostv,
      fa.faend               as faend,
      fa.prctr_umsatz        as fa_prctr_umsatz,
      // prices
      pr.price_zirl          as price_zirl,
      pr.komppreis           as komppreis,
      pr.kpwaers             as kpwaers
}
