@AbapCatalog.sqlViewName: 'ZOVINOTIFSALE'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: notification + sales header'
define view ZOV_I_NOTIF_SALES
  as select from qmel as notif
    inner join   qmfe as item on notif.qmnum = item.qmnum
    left outer join vbak as sohdr on notif.vbeln = sohdr.vbeln
{
  key notif.qmnum          as qmnum,
  key item.fenum           as fenum,
      notif.qmart          as qmart,
      item.otgrp           as otgrp,
      item.oteil           as oteil,
      item.aedat           as item_aedat,
      item.kzloesch        as kzloesch,
      notif.vbeln          as vbeln,
      sohdr.erdat          as orderdate,
      sohdr.erzet          as uhrzeitorder,
      sohdr.vkorg          as vkorg,
      sohdr.vtweg          as vtweg,
      sohdr.spart          as spart,
      sohdr.kvgr1          as customergroup
}
where
      notif.qmart = 'Z1'
   or notif.qmart = 'ZX'
