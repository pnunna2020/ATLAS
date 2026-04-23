# RMS — Registry Modernization System

## Overview
FAA's system for aircraft registration and airmen certification. "RMS" is an umbrella label for a group of IT systems: CAIS (Comprehensive Airmen Information System) and IMS (Image Management System). CAIS is the authoritative master data file for every certificated airman in the US.

## Tech Stack
| Attribute | Value |
|---|---|
| Platform | Mainframe computer-based |
| Language | NATURAL (Software AG) |
| Database | ADABAS (Software AG) |
| Last major upgrade | 2008 |
| Document format | TIFF images (not OCR'd) |
| ATO | April 20, 2022 (NIST 800-53 Rev 5) |

## Volume
- ~25 million documents
- ~174 million image files
- 300,000 aircraft registered
- 1.5 million certificated airmen
- FY2018: 400K+ airman certs issued, 667K aircraft docs processed

## Key Data Elements (CAIS — from NARA N1-237-06-001)
- Name, SSN (legacy), DOB, height, weight, hair/eye color, gender, nationality, place of birth
- Mailing and physical address, email
- Certificate type/level/number, ratings, limitations, date issued
- Names of test administrators and flight instructors
- Enforcement action information
- Retention: 60 years after annual cutoff

## Public Endpoints
- Airmen Inquiry: https://amsrvs.registry.faa.gov/airmeninquiry/
- Aircraft Inquiry: https://registry.faa.gov/aircraftinquiry/
- Airmen Services: https://amsrvs.registry.faa.gov/amsrvs/
- Aircraft Registration Renewal: https://amsrvs.registry.faa.gov/renewregistration/
- Releasable Airmen Download (monthly CSV): https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download

## Integration Points
- CARES (replacement, coexistence during transition)
- USAS Portal (one-time aircraft record exchange)
- AVS eForms (Form 337 data via FTP)
- Pay.gov (renewal payments)
- TSA NTSDB (vetting, via IACRA)

## SORNs
- DOT/FAA 847 — Aviation Records on Individuals
- DOT/FAA 801 — Aircraft Registration System

## Modernization Path
**Highest priority target.** Federal Register Jan 2025 explicitly states: legacy mainframe, last updated 2008, costly to support. Being replaced by CARES (Phase 1 aircraft done, Phase 2 airmen FOC Fall 2027).

## Key Risks
1. Aircraft registration still substantially paper-based
2. 174M TIFF images with no OCR — prime AI/document intelligence opportunity
3. PDR (Public Documents Room) physical dependency — 47 workstations in OKC
4. Rulemaking coupled with IT (14 CFR Parts 47/49 updated Jan 2025 to enable CARES)
5. CARES Phase 1 FOC slipped from Fall 2023 to Fall 2027
