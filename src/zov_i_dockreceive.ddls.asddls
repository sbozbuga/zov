@AbapCatalog.sqlViewName: 'ZOVIDOCKRCV'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: dock/receive date by notif item'
define view ZOV_I_DOCKRECEIVE
  as select from vbap as repitem
    inner join vbap as retitem on  repitem.vbeln = retitem.vbeln
                               and repitem.uepos = retitem.uepos
                               and retitem.pstyv = 'ZRET'
    inner join lips as retdlv  on  retdlv.vgbel = retitem.vbeln
                               and retdlv.vgpos = retitem.posnr
    inner join likp as rethdr  on  retdlv.vbeln = rethdr.vbeln
{
  key repitem."/cellag/qmnum" as qmnum,
  key repitem."/cellag/fenum" as fenum,
      min( rethdr.bldat )     as dockdate,
      min( rethdr.wadat_ist ) as receivedate
}
where
      repitem.pstyv = 'ZREP'
  and rethdr.vbtyp = 'T'
group by
  repitem."/cellag/qmnum",
  repitem."/cellag/fenum"
