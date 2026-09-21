@AbapCatalog.sqlViewName: 'ZOVIBREAK'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: repair break (HOLD/E0003) by FA'
define view ZOV_I_BREAK
  as select from jcds
{
  key objnr                                          as objnr,
      min( case when inact = '' then udate end )     as breakstart,
      max( case when inact = 'X' then udate end )    as breakend
}
where
      objnr like 'OR%'
  and stat  =    'E0003'
group by
      objnr
