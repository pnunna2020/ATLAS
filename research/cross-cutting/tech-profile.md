# Cross-Cutting Concerns — FAA AVS Portfolio

## Overview

Several themes cut across all systems in the FAA AVS portfolio. This document captures the shared challenges, migration patterns, and integration dependencies that affect multiple systems simultaneously.

---

## 1. Identity Modernization (Login.gov)

| System | Current Auth | Target Auth | Status |
|--------|-------------|-------------|--------|
| RMS/CAIS | CAIS internal | N/A (decommissioning) | — |
| MedXPress/MSS | Legacy FAA identity | Login.gov | In progress |
| IACRA | Email MFA | N/A (absorbed into CARES) | Deferred to CARES Phase 2 |
| DMS | IWA | Login.gov | In progress |
| CARES | — | MyAccess | Phase 1 |

**Key risk:** Two parallel identity migrations (Login.gov for MedXPress/MSS and DMS; MyAccess for CARES) with different timelines. Account linking and identity continuity across systems must be coordinated.

---

## 2. TIFF Document Migration

The legacy document ecosystem is TIFF-heavy:
- 174M TIFF images in RMS
- IACRA generates TIFFs and transfers to CAIS via FTP

CARES Phase 1 must establish a cloud document store capable of ingesting and serving this TIFF archive. Format conversion strategy (TIFF → PDF or cloud-native) is a key architectural decision.

---

## 3. CAIS as Identity Backbone

CAIS (a subsystem of RMS) currently serves as the authoritative airmen identity store used by:
- IACRA (record submission)
- DMS (designee identity verification)
- MedXPress/MSS (applicant identity)

CAIS cannot be decommissioned until all downstream systems have migrated to CARES or Login.gov. Decommission sequencing is the highest-risk dependency in the portfolio.

---

## 4. ASP.NET Legacy Framework

Both MedXPress/MSS and IACRA are built on ASP.NET Web Forms — an aging Microsoft framework with limited long-term support. Modernization pressure exists, but both systems have near-term plans (Login.gov migration, CARES absorption) that may defer full framework rewrites.

---

## 5. Contractor Concentration

- **DMS:** CAN Softtech
- **CARES:** TBD (prime contractor)
- **MedXPress/MSS, IACRA, RMS:** Various FAA contractors

Contractor knowledge concentration is a risk — especially for mainframe NATURAL/ADABAS (RMS) where expertise is scarce.

---

## 6. Schedule Dependencies

```
RMS decommission → requires CARES Phase 1 FOC (Fall 2027)
IACRA absorption  → requires CARES Phase 2 (post Phase 1)
CAIS decommission → requires all downstream systems migrated
```

The Phase 1 FOC slip to Fall 2027 cascades across all downstream milestones.

---

## 7. Data Retention

| System | Retention Requirement |
|--------|----------------------|
| MedXPress/MSS | 50 years (PHI + airmen records) |
| RMS | Long-term (174M images) |
| IACRA | Temporary (staging only; permanent records in CAIS) |
| CARES | Inherits RMS retention obligations |

CARES must be designed with 50-year retention compliance from day one.
