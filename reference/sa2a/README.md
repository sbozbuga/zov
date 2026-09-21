# Reference copy — /CELLAG/ORDER_DATA_FETCH (SA2A)

Durable, off-system copy of the legacy program and its data model, taken before the
planned SA2A refresh (system will be deleted/rebuilt from a production copy in a few
months). This is the **behavioral reference** for the ZORDV migration/rewrite project.

## Captured on
- Date: 2026-09-18
- System: **SA2A** — S/4HANA, release 816, client 100 (CTDI ERP 6.04 Produktion)
- Source: read-only download via ABAP FS MCP

## Why this copy exists
SA2A already contains an **S/4HANA-adapted** version of the program (SAP custom-code
Quick Fixes applied via transport `SA2K902251`, wave "RM S4HANA Custom Code 2.1 ADOPT
2508-614"). When SA2A is refreshed, anything living only on the sandbox is lost, so this
is our snapshot of the exact source we are rewriting against.

## Contents

### legacy/order_data_fetch/
Main report `/CELLAG/ORDER_DATA_FETCH` (report id `/CELLAG/ORDER_FETCH_NEW`) + 7 includes.

| File (includes/) | ABAP object | SA2A lines | Role |
|---|---|---|---|
| ../∕CELLAG∕ORDER_DATA_FETCH.prog.abap | /CELLAG/ORDER_DATA_FETCH | ~379 | Main shell (INCLUDEs only) |
| TOP | /CELLAG/ORDER_DATA_FETCH_TOP | 948 | Global data / types / tables |
| SEL | /CELLAG/ORDER_DATA_FETCH_SEL | 34 | Selection screen |
| EVE | /CELLAG/ORDER_DATA_FETCH_EVE | 74 | Events (START-OF-SELECTION etc.) |
| MOD | /CELLAG/ORDER_DATA_FETCH_MOD | 21 | PBO/PAI for ALV screen 0100 |
| SUB | /CELLAG/ORDER_DATA_FETCH_SUB | 8193 | Engine: 61 FORMs (get_data, build_data, build_calculated_fields, update_database, ...) |
| F01 | /CELLAG/ORDER_DATA_FETCH_F01 | 588 | Vendor PO enrichment (2 FORMs) |
| F02 | /CELLAG/ORDER_DATA_FETCH_F02 | 2906 | Process-specific logic (25 FORMs) |

Integrity check: SUB downloaded with 8193 lines, ends with `ENDFORM " GET_PSPNR` (last form) — complete.

### legacy/tables/
- ORDVIEW  — `/CELLAG/ORDVIEW`  (target reporting table, key MANDT+QMNUM+FENUM+COUNTER, 187 fields)
- ORD_ADD  — `/CELLAG/ORD_ADD`  (comments / additional data)

## S/4 adaptations already present (18 Quick-Fix markers)
These show where the legacy code was bridged to S/4, i.e. where the new CDS reader layer
should read S/4-native instead of via compat views:
- TOP: data element `VBTYP` -> `VBTYPL`
- SUB: `VBUK`/`VBUP` joins -> `V_VBUK_S4` / `V_VBUP_S4` (get_vbeln_data); delivery join VBUP -> `V_VBUP_S4`;
  2x "Add condition DRAFT = SPACE" (S/4 draft handling); `VBTYP` -> `VBTYPL`
- F01: `VBUK` access -> `LIKP` access
- F02: `VBUP` -> `V_VBUP_S4`

ATC `S4HANA_READINESS_2025`: 0 findings on SUB and F02 (readiness already remediated).

### legacy/customizing/
Captured control tables:
- ZORDVIEW_CUST1  (archive-flag / scrap-process-end rules per WKTNR)
- ZORDVIEW_CUST2  ("Tag 1 / no base day" — used by ZCL_SCHEDULING)
- ZORDVIEW_CUTOFFT (cut-off times for delivery-due date)
- ZORDVIEW_CLOS_EX (closed-exception list)
- ZORDVIEW_PRCTR  (PRCTR-from-MARC rules)
- CELLAG_REPDAU   (/CELLAG/REPDAU — repair-duration matrix; core of KPI calc)

### legacy/orderview_reader/
Reader program /CELLAG/ORDERVIEW (main + TOP/SEL/EVE/SUB/MOD/F02 includes) — consumes /CELLAG/ORDVIEW.

### legacy/classes/
- ZCL_SCHEDULING — provides GET_1_DAY_OFFSET( wktnr, kvgr1 ) used in TAT / due-date calc.

## NOT yet captured (add before refresh if needed)
- Extra customizing tables: ZORDVIEW_GSIREPL / NONOMAT / REMARKS (only if their logic proves in-scope)
- Reader variants: /CELLAG/ORDERVIEW_DTAG, YRP_ORDERVIEW_FUJITSU, Y_TRAKEN_YORDERVIEW*
- Helper FUGRs (/CELLAG/ORDERVIEW_HELP, /CELLAG/ORDVIEW update task), class ycl_base (replog)
- **Golden-master data snapshot**: export /CELLAG/ORDVIEW rows for a representative
  notification set (date window x spread of OTGRP process types) to a data file. [MUST do before refresh]

## Project package & naming (decided)
- **Package: `ZOV`** — transportable, released to transports so it survives the SA2A refresh.
- **Object prefix: `ZOV_*`** — distinct from legacy `ZORDVIEW_*` and `/CELLAG/*` (no shadowing).
- Parallel output table: `ZOV_ORDVIEW` (same key as `/CELLAG/ORDVIEW`, for row-by-row comparison).

## Guardrails for the rewrite (parallel build)
- Never modify legacy `/CELLAG/*` or `ZORDVIEW_*` objects.
- New objects go in the transportable `ZOV` package, released to transports so they
  survive the SA2A refresh.
- New engine reads legacy sources read-only; writes only to the parallel `ZOV_ORDVIEW` table.
- Legacy remains system of record until proven equivalent and cutover is approved.
