INTERFACE zif_zov_writer
  PUBLIC .

  TYPES ty_rows_t TYPE STANDARD TABLE OF zov_ordview WITH DEFAULT KEY.

  METHODS save
    IMPORTING it_rows TYPE ty_rows_t
    RAISING   zcx_zov_persist.

ENDINTERFACE.
