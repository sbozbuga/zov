class ZCL_SCHEDULING definition
  public
  final
  create public .

*"* public components of class ZCL_SCHEDULING
*"* do not include other source files here!!!
public section.
  type-pools ABAP .

  class-methods CLASS_CONSTRUCTOR .
  class-methods GET_1_DAY_OFFSET
    importing
      !IV_WKTNR type WKTNR optional
      !IV_KVGR1 type KVGR1 optional
    returning
      value(RV_DAY) type INT4 .
protected section.
*"* protected components of class ZCL_SCHEDULING
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_SCHEDULING
*"* do not include other source files here!!!

  types:
    TYT_ORDVIEW_CUST2 type HASHED TABLE OF ZORDVIEW_CUST2 WITH UNIQUE key wktnr kvgr1 .

  class-data GT_ORDVIEW_CUST2 type TYT_ORDVIEW_CUST2.
ENDCLASS.



CLASS ZCL_SCHEDULING IMPLEMENTATION.


METHOD class_constructor.
*--- Einmalig cUSTOMIZING einlesen und puffern

  SELECT *
    FROM zordview_cust2
    INTO TABLE gt_ordview_cust2.


ENDMETHOD.


METHOD get_1_day_offset.
  "Regel: Falls Wertkontrakt angegeben: danach suchen
  "falls noch nicht gefunden und Kundengruppe angegeben: nach Kundengruppe suchen
  "keine Kombinationssuche - entweder oder


  DATA:
    lv_found TYPE abap_bool.

  CONSTANTS:
    co_1_day TYPE int4 VALUE 1.

  FIELD-SYMBOLS:
    <ls_ordview_cust2> TYPE zordview_cust2.

  "Init
  CLEAR: rv_day.

  IF iv_wktnr IS SUPPLIED.
    READ TABLE gt_ordview_cust2 WITH TABLE KEY wktnr = iv_wktnr
                                               kvgr1 = space
                                ASSIGNING <ls_ordview_cust2>.
    IF sy-subrc = 0.
      rv_day = co_1_day.
      RETURN.
    ENDIF.
  ENDIF.

  IF iv_kvgr1 IS SUPPLIED.
    READ TABLE gt_ordview_cust2 WITH TABLE KEY wktnr = space
                                               kvgr1 = iv_kvgr1
                                ASSIGNING <ls_ordview_cust2>.
    IF sy-subrc = 0.
      rv_day = co_1_day.
      RETURN.
    ENDIF.
  ENDIF.

ENDMETHOD.
ENDCLASS.