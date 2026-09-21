INTERFACE zif_zov_engine
  PUBLIC .

  METHODS compute
    IMPORTING is_ctx           TYPE zif_zov_types=>ty_calc_context
    RETURNING VALUE(rs_result) TYPE zif_zov_types=>ty_calc_result.

ENDINTERFACE.
