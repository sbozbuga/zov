# Golden-Master Snapshot — design

Purpose: capture the **pre-refresh behavioral output** of the legacy program
`/CELLAG/ORDER_DATA_FETCH` for a known input set, so the ZOV rewrite can be proven to
reproduce current behavior. Source code and DDIC come back after the SA2A refresh; this
output does not. **This is the one must-do before the refresh window.**

Captured baseline facts (SA2A, 2026-09-18):
- /cellag/ordview total ≈ 8,202,643 rows; 97.5% archived (archivflag = X).
- Non-archived (reprocessable) ≈ 200K. Batch stamped lastupdate = today on ~173K of them,
  so lastupdate is NOT a usable "when did it happen" slice. orderdate is sparse for
  non-archived rows (only 26 with orderdate > 2026-06-01). => slice by QMNUM via QM tables.

## Branch-coverage matrix (OTGRP x orderstatecompl, from live SA2A)
Goal is COVERAGE, not volume: a handful of each cell so every calc branch in
build_calculated_fields is exercised at least once.

| OTGRP     | O (open) | C (closed) | D (deleted) | notes / calc branch |
|-----------|:--------:|:----------:|:-----------:|---------------------|
| ZFL       | 99,870   | 7,011,025  | 381,317     | forward logistics (deliverdate) |
| ZMTO      | 41       | 34,010     | 724         | forward group |
| ZRET      | 5,024    | 33,678     | 336         | forward group |
| ZTRANS    | 1,364    | 62,270     | 225         | forward group |
| ZIL       | 17,695   | 48,173     | 3,270       | reverse logistics (receivedate) |
| ZMT1      | 26,915   | —          | 479         | service+invoice (rechdatum); NOTE: no C rows exist |
| ZRS4S     | 12,511   | 214,593    | 11,535      | same-4-same (readytoship/scrap) |
| ZRADR     | 15,906   | 181,945    | 1,236       | exchange group |
| ZRREF     | 343      | 11,894     | 192         | exchange group |
| ZRREFRS   | 554      | 23,634     | 308         | exchange group |
| ZSWUPDAT  | 32       | 1,496      | 20          | exchange group (rare) |
| ZRL4L     | 2        | 8          | —           | exchange (VERY rare — grab ALL 10) |
| (blank)   | 18       | —          | —           | edge: no OTGRP |

Also cross with QMART: ZX (~18.4K rows, mostly archived) has its own TAT/overdue branch —
must include some ZX notifications, incl. non-archived (only 1,365 ZX non-archived).

## Sampling plan (target ~1,500–2,500 rows)
Pick per non-empty cell above:
- Rare cells (ZRL4L, ZSWUPDAT, ZMTO-O, blank-OTGRP): take ALL rows.
- Common cells: take ~50 rows each (spread across serialization COUNTER 1 and >1 where present).
- Ensure inclusion of:
  - both QMART Z1 and ZX,
  - some archivflag = X rows (to test archive-flag logic) AND non-archived,
  - rows with COUNTER > 1 (serialization / Vereinzelung),
  - rows with closed_exception = X, and with abgru filled (cancellations),
  - ZMT1 with orderstatecompl = D (no C exists — document that C is unreachable here).

## What to export (per selected QMNUM/FENUM/COUNTER)
1. INPUT keys: the selected notification list (QMNUM, FENUM, QMART, OTGRP).
2. EXPECTED output:
   - all matching rows from /CELLAG/ORDVIEW (187 fields)
   - all matching rows from /CELLAG/ORD_ADD
3. Store as CSV or XLSX under golden-master/data/ with a manifest (selection criteria,
   row counts per cell, capture timestamp, system+client).

## How the rewrite uses it
- The ZOV engine runs against the SAME source data for the SAME QMNUM set, writes to
  ZOV_ORDVIEW, and is diffed field-by-field against the exported /CELLAG/ORDVIEW snapshot.
- Any diff is either a rewrite bug (fix) or a deliberately-corrected legacy bug (document
  in a known-deviations list). No silent differences.

## Open decisions before running the export
1. Export format: CSV (git-diff friendly) vs XLSX (easier to eyeball). Recommend BOTH:
   CSV for the machine diff, XLSX for human review.
2. Field scope: full 187 fields (recommended — the rewrite must match all) vs a KPI subset.
3. Do we snapshot the underlying SOURCE data too (QMEL/QMFE/VBAP/... for the selected
   QMNUMs), so the rewrite can be re-run offline after refresh? Heavier, but makes the
   golden master fully self-contained. Recommend: at least snapshot the QMNUM input list +
   expected output now; decide on full source capture separately.
