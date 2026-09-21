@AbapCatalog.sqlViewName: 'ZOVIZ2NOTIF'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: Z2 return notification by prod order'
define view ZOV_I_Z2NOTIF
  as select from qmel as z2
{
  key z2.aufnr            as fanumber,      // production order (link to Z1 via VBEP)
      max( z2.qmnum )     as qmnum_z2,
      max( z2.qmcod )     as akz,           // reclamation code = AKZ (e.g. 'A' = scrap)
      max( z2.serialnr )  as serialnr,
      max( z2.objnr )     as objnr_z2
}
where
      z2.qmart = 'Z2'
  and z2.aufnr <> ''
group by
      z2.aufnr
