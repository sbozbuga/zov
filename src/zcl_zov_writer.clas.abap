CLASS zcl_zov_writer DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_writer.
  PRIVATE SECTION.
    CONSTANTS c_blocksize TYPE i VALUE 1000.
    METHODS cleanup_excess_counters
      IMPORTING it_rows TYPE zif_zov_writer=>ty_rows_t.
ENDCLASS.



CLASS zcl_zov_writer IMPLEMENTATION.

  METHOD zif_zov_writer~save.
    DATA lt_block TYPE zif_zov_writer=>ty_rows_t.
    DATA lv_from  TYPE i VALUE 1.
    DATA lv_to    TYPE i.
    DATA lv_total TYPE i.

    lv_total = lines( it_rows ).

    WHILE lv_from <= lv_total.
      lv_to = lv_from + c_blocksize - 1.
      CLEAR lt_block.
      APPEND LINES OF it_rows FROM lv_from TO lv_to TO lt_block.

      TRY.
          " parallel table ONLY; never /cellag/ordview
          MODIFY zov_ordview FROM TABLE lt_block.
          COMMIT WORK.
        CATCH cx_sy_open_sql_db.
          " fall back to single-row so one bad row does not sink the block
          LOOP AT lt_block ASSIGNING FIELD-SYMBOL(<ls>).
            TRY.
                MODIFY zov_ordview FROM <ls>.
                COMMIT WORK.
              CATCH cx_sy_open_sql_db INTO DATA(lo_db).
                RAISE EXCEPTION TYPE zcx_zov_persist
                  EXPORTING
                    previous = lo_db
                    qmnum    = <ls>-qmnum
                    fenum    = <ls>-fenum
                    counter  = <ls>-counter
                    dbmsg    = lo_db->get_text( ).
            ENDTRY.
          ENDLOOP.
      ENDTRY.

      lv_from = lv_to + 1.
    ENDWHILE.

    " counter-reduction cleanup: if an order quantity shrank, stored COUNTER positions beyond
    " the current max per (qmnum,fenum) are stale -> delete them (legacy SUB ~627/6625).
    cleanup_excess_counters( it_rows ).
  ENDMETHOD.

  METHOD cleanup_excess_counters.
    " highest counter written per notification item this run
    TYPES: BEGIN OF ty_max,
             qmnum   TYPE qmnum,
             fenum   TYPE felfd,
             maxc    TYPE cim_count,
           END OF ty_max.
    DATA lt_max TYPE SORTED TABLE OF ty_max WITH UNIQUE KEY qmnum fenum.

    LOOP AT it_rows INTO DATA(ls_row).
      READ TABLE lt_max ASSIGNING FIELD-SYMBOL(<m>)
        WITH KEY qmnum = ls_row-qmnum fenum = ls_row-fenum.
      IF sy-subrc <> 0.
        INSERT VALUE #( qmnum = ls_row-qmnum fenum = ls_row-fenum maxc = ls_row-counter )
          INTO TABLE lt_max.
      ELSEIF ls_row-counter > <m>-maxc.
        <m>-maxc = ls_row-counter.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_max INTO DATA(ls_max).
      DELETE FROM zov_ordview
        WHERE qmnum   = @ls_max-qmnum
          AND fenum   = @ls_max-fenum
          AND counter > @ls_max-maxc.
    ENDLOOP.
    IF lt_max IS NOT INITIAL.
      COMMIT WORK.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
