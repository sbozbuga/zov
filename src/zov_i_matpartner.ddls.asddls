@AbapCatalog.sqlViewName: 'ZOVIMATPART'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: material/partner core by notif'
define view ZOV_I_MATPARTNER
  as select from vbap as item
    inner join      qmfe            as fe   on  item."/cellag/qmnum" = fe.qmnum
                                            and item."/cellag/fenum" = fe.fenum
    left outer join mara            as mat  on  fe.bautl = mat.matnr
    left outer join marc            as mc   on  fe.bautl   = mc.matnr
                                            and item.werks = mc.werks
    left outer join zordview_prctr  as pc   on  fe.otgrp = pc.otgrp
    left outer join vbpa            as we   on  item.vbeln = we.vbeln
                                            and we.posnr   = '000000'
                                            and we.parvw   = 'WE'
    left outer join adrc            as ad   on  we.adrnr = ad.addrnumber
{
  key item."/cellag/qmnum"    as qmnum,
  key item."/cellag/fenum"    as fenum,
      max( fe.bautl )         as ctdisapmatnummer,
      max( mat.mfrpn )        as partnumberalc,
      max( we.kunnr )         as shipto,
      max( item.waerk )       as waerk,
      max( case when pc.otgrp is not null then mc.prctr else item.prctr end ) as prctr,
      max( ad.name1 )         as shipto_name1,
      max( ad.name2 )         as shipto_name2,
      max( ad.name3 )         as shipto_name3,
      max( ad.street )        as shipto_street,
      max( ad.house_num1 )    as shipto_house_num,
      max( ad.post_code1 )    as shipto_post_code,
      max( ad.city1 )         as shipto_city1,
      max( ad.sort1 )         as shipto_sort1,
      max( item.prctr )       as prctr_umsatz
}
where
      item."/cellag/qmnum" <> ''
group by
      item."/cellag/qmnum",
      item."/cellag/fenum" 
