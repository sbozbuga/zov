@AbapCatalog.sqlViewName: 'ZOVIREPDAU'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: repair duration by wktnr'
define view ZOV_I_REPDAU
  as select from /cellag/repdau as rd
{
  key rd.wktnr             as wktnr,
      max( rd.dauer )      as dauer,
      max( rd.kaltage )    as kaltage,
      max( rd.rsende )     as rsende,
      max( rd.otdstart )   as otdstart
}
where
      rd.wktnr <> ''
group by
      rd.wktnr
