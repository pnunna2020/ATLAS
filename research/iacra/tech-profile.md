# IACRA — Integrated Airman Certification and Rating Application

## Overview
IACRA is explicitly a **temporary repository — not a system of record**. It guides applicants through certification, then hands off to CAIS (the Airman Registry) via TIFF over secure FTP. Planned to be absorbed into CARES Phase 2.

## Tech Stack
| Attribute | Value |
|---|---|
| URL | https://iacra.faa.gov/iacra/default.aspx |
| Platform | Web-based (ASP.NET — .aspx URLs) |
| Auth (public) | Username/password + 30-day email MFA (6-digit code) |
| Auth (FAA) | PIV card via MyAccess |
| Output to CAIS | TIFF images over secure FTP |
| Knowledge test ingest | SQL Server link to Atlas Aviation |
| ATO | March 2, 2022 (NIST 800-53 Rev 5) |
| Retention | Deleted when superseded (temp repo only) |

## Role Model
- Applicant (airman)
- Recommending Instructor (CFI)
- Designated Examiner (DPE)
- Aviation Safety Inspector (ASI)
- Aviation Safety Technician (AST)
- School Examiner / Training Center Evaluator
- Certifying Official

## Data Elements
**Registration:** Name, DOB, sex, email, certificate #, 2 security questions
**Application:** Full biographic, SSN (optional), multiple ID types (DL, passport, military, student), citizenship, address, hair/eye/height/weight, drug convictions, prior certs, aviation experience, foreign license, medical cert info, English proficiency, cert/rating tested, approved/disapproved

## Forms Handled
- 8400-3 (Aircraft Dispatcher)
- 8610-1 (Mechanic IA)
- 8610-2 (Mechanic/Parachute Rigger)
- 8710-1 (Airman Cert/Rating)
- 8710-11 (Sport Pilot)
- 8710-13 (Remote Pilot)
- 8060-71 (Foreign License Verification)

## Integration Points
| Direction | System | Protocol | Data |
|---|---|---|---|
| Inbound | MyAccess | SSO | PIV auth for FAA users |
| Inbound | Atlas Aviation | SQL Server link | Knowledge test results by FTN |
| Outbound | AVS Registry (CAIS) | TIFF over secure FTP | Full application package |
| Outbound | TSA (NTSDB) | Secure portal (MOA) | Vetting payload |
| Outbound | SAS | Direct | Inspector + applicant data |
| Outbound | USAS Portal | One-time | Name, email, FTN, DOB |
| Bidirectional | DMS | Direct | Test activity + airman ID |

## Critical Engineering Detail
The **TIFF-over-FTP handoff to CAIS** is the single most important legacy integration — incompatible with modern API-driven systems. This is why CARES was designed.

## Replacement Path
Will be absorbed into CARES Phase 2 (FOC Fall 2027). IACRA's replacement window is open now.
