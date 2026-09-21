@AbapCatalog.sqlViewName: 'ZOVIDLVSER'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: outbound delivery serials by notif'
define view ZOV_I_DELIV_SERIAL
  as select from vbap as item
    inner join lips as dlv  on  dlv.vgbel = item.vbeln
                            and dlv.vgpos = item.posnr
    inner join likp as hdr  on  dlv.vbeln = hdr.vbeln
    inner join ser01 as ser on  ser.lief_nr = dlv.vbeln
                            and ser.posnr   = dlv.posnr
    inner join objk  as obj on  obj.obknr = ser.obknr
{
  key item."/cellag/qmnum" as qmnum,
  key item."/cellag/fenum" as fenum,
  key obj.sernr            as sernr,
      obj.equnr            as equnr
}
where
      hdr.vbtyp = 'J'
  and obj.taser = 'SER01'
