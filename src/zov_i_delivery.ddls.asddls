@AbapCatalog.sqlViewName: 'ZOVIDELIV'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: delivery GI date by sales doc'
define view ZOV_I_DELIVERY
  as select from lips as dlvitem
    inner join   likp as dlvhdr on dlvitem.vbeln = dlvhdr.vbeln
{
  key dlvitem.vgbel        as sales_vbeln,   // source sales document
  key dlvitem.vgpos        as sales_posnr,   // source sales item
  key dlvitem.vbeln        as delivery,
  key dlvitem.posnr        as delivery_posnr,
      dlvhdr.wadat_ist     as deliverdate,   // goods-issue date
      dlvhdr.erdat         as likp_erdat,
      dlvhdr.vbtyp         as vbtyp
}
