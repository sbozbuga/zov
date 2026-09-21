@AbapCatalog.sqlViewName: 'ZOVISERIAL'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: kwmeng + serial profile by notif item'
define view ZOV_I_SERIAL
  as select from vbap as item
    inner join      qmfe as fe  on  item."/cellag/qmnum" = fe.qmnum
                                and item."/cellag/fenum" = fe.fenum
    left outer join marc as mat on  fe.bautl    = mat.matnr
                                and item.werks  = mat.werks
{
  key item."/cellag/qmnum"  as qmnum,
  key item."/cellag/fenum"  as fenum,
      max( item.kwmeng )    as kwmeng,
      max( mat.sernp )      as sernp
}
where
      item."/cellag/qmnum" <> ''
group by
      item."/cellag/qmnum",
      item."/cellag/fenum"
