CLASS zcl_zov_strategy_factory DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zov_strategy_factory.
ENDCLASS.



CLASS zcl_zov_strategy_factory IMPLEMENTATION.

  METHOD zif_zov_strategy_factory~build.
    rt_strategies = VALUE #(
      ( NEW zcl_zov_strat_zrs4s( ) )
      ( NEW zcl_zov_strat_exchange( ) )
      ( NEW zcl_zov_strat_forward( ) )
      ( NEW zcl_zov_strat_zil( ) )
      ( NEW zcl_zov_strat_zmt1( ) )
      ( NEW zcl_zov_strat_default( ) )   " catch-all, MUST be last
    ).
  ENDMETHOD.

ENDCLASS.
