@AbapCatalog.sqlViewName: 'ZOVIWKTNRBASE'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZOV reader: vbap wktnr/werks pre-agg by notif item'
// Pre-aggregates VBAP to the (qmnum,fenum) grain BEFORE any wktnr/werks lookup joins.
// This lets a qmnum filter (WHERE IN / itab-join) prune VBAP up front, instead of grouping
// all ~17.3M wktnr items and joining cust/repdau/plant/cutoff first. The lookups are moved
// to ZOV_I_WKTNR_CUST which joins onto this small result. wktnr/werks are functionally one
// value per notif item (max() only collapses SD sub-item fan-out).
define view ZOV_I_WKTNR_BASE
  as select from vbap as item
{
  key item."/cellag/qmnum"                                            as qmnum,
  key item."/cellag/fenum"                                            as fenum,
      max( item.wktnr )                                               as wktnr,
      max( item.werks )                                               as werks,
      max( case when item.uepos = '000000' then item.abgru else '' end ) as abgru
}
where
      item.wktnr <> ''
group by
      item."/cellag/qmnum",
      item."/cellag/fenum"
