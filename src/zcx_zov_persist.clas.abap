CLASS zcx_zov_persist DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    DATA qmnum   TYPE qmnum.
    DATA fenum   TYPE felfd.
    DATA counter TYPE cim_count.
    DATA dbmsg   TYPE string.

    METHODS constructor
      IMPORTING textid   LIKE if_t100_message=>t100key OPTIONAL
                previous TYPE REF TO cx_root OPTIONAL
                qmnum    TYPE qmnum      OPTIONAL
                fenum    TYPE felfd      OPTIONAL
                counter  TYPE cim_count  OPTIONAL
                dbmsg    TYPE string     OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_zov_persist IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->qmnum   = qmnum.
    me->fenum   = fenum.
    me->counter = counter.
    me->dbmsg   = dbmsg.
    CLEAR me->if_t100_message~t100key.
    IF textid IS SUPPLIED.
      me->if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
