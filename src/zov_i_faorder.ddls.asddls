@AbapCatalog.sqlViewName: 'ZOVIFAORDER'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: FA order fields by notif item'
define view ZOV_I_FAORDER
  as select from vbap as repitem
    inner join      vbep as sched on  repitem.vbeln = sched.vbeln
                                   and repitem.posnr = sched.posnr
    left outer join aufk as ord   on  sched.aufnr = ord.aufnr
    left outer join jcds as fin   on  ord.objnr = fin.objnr
                                  and fin.stat  = 'E0001'
                                  and fin.inact = ''
{
  key repitem."/cellag/qmnum" as qmnum,
  key repitem."/cellag/fenum" as fenum,
      max( sched.aufnr )      as fanumber,
      max( sched.edatu )      as rsende,
      max( ord.erdat )        as fadate,
      max( ord.kostv )        as kostv,
      max( fin.udate )        as faend,
      max( repitem.prctr )    as prctr_umsatz
}
where
      repitem.pstyv = 'ZREP'
group by
      repitem."/cellag/qmnum",
      repitem."/cellag/fenum"
