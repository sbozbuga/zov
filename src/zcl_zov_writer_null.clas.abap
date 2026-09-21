CLASS zcl_zov_writer_null DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_writer.
ENDCLASS.



CLASS zcl_zov_writer_null IMPLEMENTATION.

  METHOD zif_zov_writer~save.
    RETURN.   " no-op: test mode / unit tests
  ENDMETHOD.

ENDCLASS.
