@AbapCatalog.sqlViewName: 'ZOVIPRZIRL'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV: ZIRL Z_SKZ_PRICE sum per item group'
define view ZOV_I_PRICE_ZIRL
  as select from vbap
{
  key vbeln           as vbeln,
  key uepos           as uepos,
      sum( netwr )    as price_zirl
}
where
      pstyv = 'ZIRL'
  and matnr = 'Z_SKZ_PRICE'
group by
      vbeln,
      uepos
