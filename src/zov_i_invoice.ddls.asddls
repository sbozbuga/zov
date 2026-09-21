@AbapCatalog.sqlViewName: 'ZOVIINVOICE'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: invoice date by sales doc'
define view ZOV_I_INVOICE
  as select from vbfa as flow
    inner join   vbrk as bill on flow.vbeln = bill.vbeln
{
  key flow.vbelv           as sales_vbeln,   // source sales document
  key flow.vbeln           as invoice,
      bill.fkdat           as rechdatum,      // billing date
      bill.fksto           as fksto
}
where
      flow.vbtyp_n = 'M'    // invoice
