# Golden-Master snapshot — MANIFEST

Captured: 2026-09-18 from **SA2A** (S/4HANA 816, client 100), read-only via ABAP FS MCP.
Strategy: **Option A** — snapshot stored `/CELLAG/ORDVIEW` + `/CELLAG/ORD_ADD` rows for a
coverage-driven set. NOT a controlled fresh run (see caveat below).

## Files (data/)
| File | Table | Rows | Cols | Selection |
|---|---|---:|---:|---|
| ordview_rare_cells.csv | /CELLAG/ORDVIEW | 1,576 | 187 | ALL rows where OTGRP in (ZRL4L, ZSWUPDAT, '' blank) |
| ordview_nonarch_coverage.csv | /CELLAG/ORDVIEW | 4,000 | 187 | archivflag = '' , ordered OTGRP/state/qmart, COUNTER desc first (capped 4000) |
| ordview_overdue999.csv | /CELLAG/ORDVIEW | 500 | 187 | archivflag = '' AND overdue = 999 (clamp branch) |
| ordview_zx.csv | /CELLAG/ORDVIEW | 2,000 | 187 | qmart = 'ZX' , archived+non-archived, overdue desc (capped 2000) |
| ord_add_nonarch.csv | /CELLAG/ORD_ADD | 5,000 | 29 | ORD_ADD joined to non-archived ORDVIEW (comments) (capped 5000) |

Total ORDVIEW rows captured ≈ 8,076 (with some overlap between coverage/zx/overdue999 sets).

## Coverage rationale (why these)
- **rare_cells**: process types with too few rows to risk missing (ZRL4L=10, ZSWUPDAT~1.5K, blank-OTGRP). Taken in full.
- **nonarch_coverage**: the realistic reprocessable population (~200K); 4000-row cap ordered to
  surface all OTGRP x state x qmart combos and serialization (COUNTER>1) rows first.
- **overdue999**: exercises the numeric-overflow clamp branch (all Z1 on SA2A).
- **zx**: ZX has its own TAT/OVERDUE/auftragsendesoll branch (RSENDE+2 factory days) — sampled separately.
- **ord_add_nonarch**: the comment/additional-data table that update_database also writes.

## What this proves / does NOT prove
- Purpose: verify the ZOV rewrite computes the SAME values the LEGACY code computes for the
  SAME source inputs. Field-by-field diff of ZOV_ORDVIEW vs these CSVs (matched on QMNUM/FENUM/COUNTER).
- CAVEAT (see ../golden-master/DATA-SANITY.md): SA2A is a ~1-year-old prod copy with the job
  still running over frozen data. These stored values are self-consistent but reflect
  sandbox drift (e.g. 10,607 open orders 300-999 days overdue). They are NOT "business-correct"
  ground truth — they are the legacy computation over stale inputs. That is fine for
  equivalence testing (both sides read identical stale inputs), but do not treat values as canonical.

## Known limitations to revisit
- Option A snapshots accumulated table state, not a run we controlled. If a controlled
  baseline is later needed, re-run legacy in test mode (pa_test=X, does NOT write) for a
  small QMNUM set and export the ALV — see investigation notes in chat.
- Row caps (4000/2000/5000) chosen for coverage, not completeness. Rare cells are complete.
- ORD_ADD capture is scoped to non-archived; extend if archived comment logic needs testing.
- Format is CSV only so far. XLSX for human review can be generated on request.

## How to regenerate (after refresh, if needed)
Same SELECTs via abapfs_run_sql_query displayMode=download_to_file. Note: after the SA2A
refresh the DATA will differ (new prod copy), so THIS snapshot is the pre-refresh reference —
keep it in git; do not overwrite.
