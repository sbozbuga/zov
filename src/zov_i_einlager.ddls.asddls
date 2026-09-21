@AbapCatalog.sqlViewName: 'ZOVIEINLAGER'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: einlagerdate by notification item'
define view ZOV_I_EINLAGER
  as select from vbap as repitem
    inner join      vbep          as sched on  repitem.vbeln = sched.vbeln
                                           and repitem.posnr = sched.posnr
    inner join      ZOV_I_STORAGE as stor  on  sched.aufnr = stor.fanumber
    left outer join ZOV_I_Z2NOTIF as z2    on  sched.aufnr = z2.fanumber
{
  key repitem."/cellag/qmnum" as qmnum,
  key repitem."/cellag/fenum" as fenum,
      sched.aufnr             as fanumber,
      stor.einlagerdate       as einlagerdate,
      z2.akz                  as akz,
      z2.qmnum_z2             as qmnum_z2
}
where
      repitem.pstyv = 'ZREP'
