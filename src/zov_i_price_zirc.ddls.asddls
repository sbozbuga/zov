@AbapCatalog.sqlViewName: 'ZOVIPRZIRC'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV: ZIRC sum per item group'
define view ZOV_I_PRICE_ZIRC
  as select from vbap
{
  key vbeln           as vbeln,
  key uepos           as uepos,
      sum( netwr )    as komppreis,
      max( waerk )    as kpwaers
}
where
      pstyv = 'ZIRC'
group by
      vbeln,
      uepos
