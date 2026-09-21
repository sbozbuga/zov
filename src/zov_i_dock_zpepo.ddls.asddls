@AbapCatalog.sqlViewName: 'ZOVIDOCKZP'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: dockdate from ZPEPO service task'
define view ZOV_I_DOCK_ZPEPO
  as select from qmsm
{
  key qmnum            as qmnum,
  key fenum            as fenum,
      min( erldat )    as dockdate_zp
}
where
      mnkat    = '2'
  and mngrp    = 'ZPEPO'
  and mncod    = '1300'
  and kzloesch = ''
  and erldat  <> '00000000'
group by
      qmnum,
      fenum
