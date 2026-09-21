@AbapCatalog.sqlViewName: 'ZOVINOTIFKY'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: distinct notif-item keys'
define view ZOV_I_NOTIFKEY
  as select from vbap as item
{
  key item."/cellag/qmnum" as qmnum,
  key item."/cellag/fenum" as fenum
}
where
      item."/cellag/qmnum" <> ''
group by
      item."/cellag/qmnum",
      item."/cellag/fenum"
