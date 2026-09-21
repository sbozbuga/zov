INTERFACE zif_zov_reader
  PUBLIC .

  TYPES: BEGIN OF ty_selection,
           mode    TYPE c LENGTH 1,          " 'N' new / 'O' old
           r_qmnum TYPE RANGE OF qmnum,
           r_otgrp TYPE RANGE OF /cellag/otgrp,
           r_erdat TYPE RANGE OF erdat,
           refdate TYPE dats,
         END OF ty_selection.

  TYPES ty_context_t TYPE STANDARD TABLE OF zif_zov_types=>ty_calc_context WITH DEFAULT KEY.

  METHODS read_contexts
    IMPORTING is_selection  TYPE ty_selection
    RETURNING VALUE(rt_ctx) TYPE ty_context_t.

ENDINTERFACE.
