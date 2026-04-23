# CARES — Civil Aviation Registration Electronic Services

## Overview
Cloud-based replacement umbrella for Aircraft Registry + Airmen Registry + IACRA + public inquiry. Mandated by Section 546 of FAA Reauthorization Act of 2018. MedXPress/MSS is NOT in CARES scope.

## Tech Stack
| Attribute | Value |
|---|---|
| URL | https://cares.faa.gov |
| Platform | Cloud-based |
| Auth | MyAccess (PIV for FAA, identity proofing for public) |
| Digital signature | DocuSign |
| Payment | Pay.gov |
| ATO | September 16, 2022 |
| Task order effective | August 28, 2020 |
| Retention | Permanent records (NARA N1-237-04-03) |

## Phase Plan
| Phase | Scope | Original | Current |
|---|---|---|---|
| Phase 1 | Aircraft Registration (individuals) | IOC Dec 2022, FOC Fall 2023 | FOC slipped to Fall 2027 |
| Phase 2 | Airman Examination + Certification | IOC Fall 2024, FOC Fall 2025 | IOC Fall 2025, FOC Fall 2027 |
| Phase 3 | UAS services | Fall 2025 | Absorbed into Phases 1/2 |

**Critical risk:** Fall 2023 → Fall 2027 slip on Phase 1 FOC is the single biggest risk signal.

## Integration Points
- MyAccess — inbound auth
- Pay.gov — outbound payment + callback
- DocuSign — outbound doc + inbound signed doc
- AVS Registry (CAIS) — coexistence/handover
