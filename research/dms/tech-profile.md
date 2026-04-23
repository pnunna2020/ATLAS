# DMS — Designee Management System

## Overview
DMS manages the lifecycle of FAA-designated representatives under 14 CFR Part 183. Built to consolidate ~9 predecessor systems per GAO-05-40. Manages ~10,000+ active designees across 13 categories.

## Tech Stack
| Attribute | Value |
|---|---|
| URL | https://designee.faa.gov |
| Auth (FAA) | Active Directory via IWA (Integrated Windows Authentication) + PIV |
| Auth (public) | Username/password; Login.gov migration for non-FAA users (2025) |
| Hosting | Controlled server center, MMAC secure facility |
| Standard | NIST 800-53 Rev 5 |
| Contractor | CAN Softtech (per manual branding) |
| Retention | 25 years after inactive (NARA DAA-0237-2020-0013) |

## 13 Designee Categories
| Code | Name | Office |
|---|---|---|
| DMIR | Designated Manufacturing Inspection Rep | AIR |
| DAR-F | Designated Airworthiness Rep — Manufacturing | AIR |
| AME | Aviation Medical Examiner | AAM |
| DAR-T | Designated Airworthiness Rep — Maintenance | FS |
| DPE | Designated Pilot Examiner | FS |
| DPRE | Designated Parachute Rigger Examiner | FS |
| DME | Designated Mechanic Examiner | FS |
| SAE | Specialty Aircraft Examiner | FS |
| Admin PE | Administrative Pilot Examiner | FS |
| APD | Aircrew Program Designee | FS |
| TCE | Training Center Evaluator | FS |
| DADE | Designated Aircraft Dispatch Examiner | FS |
| DER | Designated Engineering Representative | AIR |

Note: ODA (Organization Designation Authorization) is explicitly excluded from DMS.

## Data Elements
**Registration:** Name, email, username, password, 1 security question
**Profile:** Name, suffix, DOB, airman cert #, gender, citizenship, phone, photo (optional), addresses, FTN, references, employer POC, medical license/NPI (AME only), uploaded docs
**Output:** Designee Number (9-digit), CLOA, Designation Certificate

## Integration Points
| Direction | System | Data |
|---|---|---|
| Outbound | NACIP | Designee name, ID, phone, type |
| Outbound | MSS | Designee ID, status |
| Bidirectional | IACRA | Test activity ↔ airman identification |
| Outbound | SAS | Designee name, ID, type, cert expiration |
| Outbound | eFSAS | Designee name, ID, type, status (pay grade) |

Public search: designee name, address, city, state, zip, phone, country, type, office.

## Policy Framework
- 14 CFR Part 183 (statutory authority)
- FAA Order 8000.95D (Change 1 in draft, docket FAA-2025-1218)
- SORN DOT/FAA 830
- OMB Control 2120-0033

## Modernization Status
Active modernization in place — NOT needing wholesale replacement:
- Login.gov migration for non-FAA users (2025)
- DRS training functions being absorbed (Releases 8.0, 8.1)
- IWA auth needs modernization for zero-trust
- Focus: interface retirement + shared master-data cleanup
