@AbapCatalog.sqlViewName: 'ZOVIPRICE'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: sub-item prices by notif item'
define view ZOV_I_PRICE
  as select from vbap as repitem
    left outer join ZOV_I_PRICE_ZIRL as zirl on  repitem.vbeln = zirl.vbeln
                                             and repitem.uepos = zirl.uepos
    left outer join ZOV_I_PRICE_ZIRC as zirc on  repitem.vbeln = zirc.vbeln
                                             and repitem.uepos = zirc.uepos
{
  key repitem."/cellag/qmnum" as qmnum,
  key repitem."/cellag/fenum" as fenum,
      max( zirl.price_zirl )  as price_zirl,
      max( zirc.komppreis )   as komppreis,
      max( zirc.kpwaers )     as kpwaers
}
where
      repitem.pstyv = 'ZREP'
group by
      repitem."/cellag/qmnum",
      repitem."/cellag/fenum"
