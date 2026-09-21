@AbapCatalog.sqlViewName: 'ZOVISTORAGE'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: einlager (BLDAT) by prod order'
define view ZOV_I_STORAGE
  as select from mkpf as matdoc
    inner join   ser03 as serdoc on  matdoc.mblnr = serdoc.mblnr
                                  and matdoc.mjahr = serdoc.mjahr
    inner join   objk  as serobj on  serdoc.obknr = serobj.obknr
{
  key matdoc.xblnr         as fanumber,
      min( matdoc.bldat )  as einlagerdate
}
where
      serobj.taser = 'SER03'
  and matdoc.bldat < '20991201'
group by
      matdoc.xblnr
