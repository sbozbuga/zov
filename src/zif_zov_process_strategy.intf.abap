INTERFACE zif_zov_process_strategy
  PUBLIC .

  METHODS handles
    IMPORTING iv_otgrp      TYPE /cellag/otgrp
    RETURNING VALUE(rv_yes) TYPE abap_bool.

  METHODS determine_status
    IMPORTING is_ctx    TYPE zif_zov_types=>ty_calc_context
    CHANGING  cs_result TYPE zif_zov_types=>ty_calc_result.

  METHODS determine_commit_date
    IMPORTING is_ctx    TYPE zif_zov_types=>ty_calc_context
    CHANGING  cs_result TYPE zif_zov_types=>ty_calc_result.

  METHODS base_date
    IMPORTING is_ctx         TYPE zif_zov_types=>ty_calc_context
    RETURNING VALUE(rv_date) TYPE dats.

ENDINTERFACE.
