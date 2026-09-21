# Data-sanity scan — /CELLAG/ORDVIEW on SA2A (2026-09-18)

Context: SA2A is a ~year-old production copy; the fetch job has kept running against
frozen transactional data. Goal: gauge how "not ideal" the stored data is before using it.
Scope: non-archived / reprocessable set (~200K rows) unless noted.

## Internal consistency — CLEAN
| Check | Count | Meaning |
|---|---:|---|
| orderstatecompl = C AND dateclosed = 0 | 0 | closed rows always have a close date |
| orderstatecompl = O AND dateclosed <> 0 | 0 | no contradictory open+closed rows |
| bad orderstatecompl (not O/C/D) | 0 | (checked implicitly; distribution earlier showed only O/C/D + blank OTGRP) |

=> The legacy computation is internally self-consistent. Good: that consistency is what
the rewrite must reproduce.

## Overflow sentinels (999 clamp)
| Field = 999 | Count (non-arch) | Note |
|---|---:|---|
| tat | 9 | negligible |
| overdue | 1,646 | ALL QMART = Z1 (not ZX). ~0.8% of non-arch. |

=> Include a few overdue=999 Z1 rows in the sample so the rewrite reproduces the clamp.

## Sandbox drift fingerprint — EXPECTED, NOT A LOGIC BUG
| Check | Count | Meaning |
|---|---:|---|
| open orders with 300 < overdue < 999 | 10,607 | orders stuck OPEN & long overdue because the frozen copy never received the production events (delivery/GR/confirmation) that would have closed them |

=> These are the CORRECT output of the logic over STALE inputs. On live production most
would be closed. Confirms: do NOT treat stored values as "ground truth for correct".

## Consequence for golden-master strategy (confirmed)
- Validate "does the rewrite compute what the legacy code computes for the SAME inputs",
  NOT "is the stored value business-correct".
- Drift is harmless for this purpose: both legacy and ZOV read identical stale inputs, so
  it cancels in the diff.
- Stored /CELLAG/ORDVIEW = COVERAGE guide + (fresh-run) comparison target, produced by a
  controlled legacy run, not the accumulated table values.
- When sampling, deliberately include: overdue=999 Z1 rows; long-overdue open orders;
  COUNTER>1 serialization; closed_exception; cancellations (abgru filled); ZX rows.

## Full-table note
Aggregate scans over all 8.2M rows with multiple CASE aggregates returned HTTP 500
(timeout/complexity). Scan non-archived subset or single-metric COUNTs instead.
