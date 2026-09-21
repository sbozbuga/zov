INTERFACE zif_zov_strategy_factory
  PUBLIC .

  TYPES ty_strategy_t TYPE STANDARD TABLE OF REF TO zif_zov_process_strategy WITH DEFAULT KEY.

  METHODS build
    RETURNING VALUE(rt_strategies) TYPE ty_strategy_t.

ENDINTERFACE.
