# IACRA — Functional Requirements

This document extracts functional requirements for the Integrated Airman Certification and Rating Application (IACRA) from the current-state analysis, PIAs, and public artifacts. Requirements are organized by functional area and prioritized using MoSCoW (Must / Should / Could / Won't).

Each requirement is worded to describe **what IACRA does today** — it is a requirements baseline for the replacement (CARES Phase 2, FOC Fall 2027), not a forward-looking specification. Where modernization gaps exist (email MFA, TIFF/FTP), requirements are marked so the successor system can address them.

**Source key:**
- `CSA §N` — current-state-analysis.md, section N
- `PIA-2019` — iacra-airmen-certification-pia.pdf
- `PIA-2023` — iacra-airman-certification-pia-2023.pdf
- `SORN` — DOT/FAA 847
- `NARA` — N1-237-09-14
- `NIST` — NIST SP 800-53 Rev 5 / 800-63B

---

## FR-IACRA-1 — User Account Management

Account creation, authentication, and profile management for the public and FAA user populations. IACRA serves a mixed population — external applicants, CFIs, DEs, school admins, and internal FAA staff — so the account model spans public and federated authentication.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-IACRA-1.1 | The system shall allow a prospective user to register a public account by providing name, date of birth, sex, email address, and (if applicable) an existing FAA certificate number. | PIA-2019, CSA §4 | Must |
| FR-IACRA-1.2 | The system shall assign a unique FAA Tracking Number (FTN) to each registered user and retain the FTN as the stable cross-system identifier. | CSA §4, CSA §12 (Rec 5) | Must |
| FR-IACRA-1.3 | The system shall require the user to select and answer two security questions at registration for account recovery. | PIA-2019, CSA §4 | Must |
| FR-IACRA-1.4 | The system shall enforce multi-factor authentication for public accounts via a 6-digit email-delivered code with a 30-day trust window. | CSA §2, CSA §10 | Must (current); replacement should meet NIST 800-63B AAL2 |
| FR-IACRA-1.5 | The system shall authenticate FAA internal users via PIV card through MyAccess federated SSO. | CSA §2, CSA §7 | Must |
| FR-IACRA-1.6 | The system shall bind a role (Applicant, Recommending Instructor, Designated Examiner, ASI/AST, School Examiner, Certifying Official) to each account at registration and validate it against credential evidence where applicable (certificate number for RIs/DEs, PIV for FAA staff, school ID for school admins). | CSA §3 | Must |
| FR-IACRA-1.7 | The system shall allow users to update profile information (contact, address, email) after registration. | PIA-2019 | Should |
| FR-IACRA-1.8 | The system shall support account recovery via security questions and email verification. | PIA-2019, CSA §8 (FAQ) | Must |
| FR-IACRA-1.9 | The system shall log authentication events and MFA verifications for audit. | NIST, CSA §9 | Must |

---

## FR-IACRA-2 — Application Processing

Intake and lifecycle management for the seven airman-certification forms IACRA handles. Each form maps to a distinct application path but shares the underlying data model and role workflow.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-IACRA-2.1 | The system shall support Form 8710-1 (Airman Certificate and/or Rating Application) per OMB 2120-0021. | CSA §5, PIA-2019 | Must |
| FR-IACRA-2.2 | The system shall support Form 8610-1 (Application for Inspection Authorization) per OMB 2120-0022. | CSA §5, PIA-2019 | Must |
| FR-IACRA-2.3 | The system shall support Form 8610-2 (Mechanic / Parachute Rigger Application) per OMB 2120-0022. | CSA §5, PIA-2019 | Must |
| FR-IACRA-2.4 | The system shall support Form 8400-3 (Aircraft Dispatcher Certification) per OMB 2120-0022. | CSA §5, PIA-2019 | Must |
| FR-IACRA-2.5 | The system shall support Form 8710-11 (Sport Pilot Application) per OMB 2120-0021. | CSA §5, PIA-2019 | Must |
| FR-IACRA-2.6 | The system shall support Form 8710-13 (Remote Pilot Certificate and/or Rating Application) per OMB 2120-0021. | CSA §5, PIA-2019 | Must |
| FR-IACRA-2.7 | The system shall support Form 8060-71 (Verification of Authenticity of Foreign License, Rating, and Medical Certification) per OMB 2120-0022. | CSA §5, PIA-2019 | Must |
| FR-IACRA-2.8 | The system shall allow an applicant to start a new application, selecting the certificate/rating sought and the appropriate form. | CSA §6 (Stage 2) | Must |
| FR-IACRA-2.9 | The system shall allow an applicant to continue (resume) a partially completed application. | CSA §8 (user guides) | Must |
| FR-IACRA-2.10 | The system shall allow an applicant to view a previously submitted or in-progress application. | CSA §8 (user guides) | Must |
| FR-IACRA-2.11 | The system shall allow an applicant to delete an in-progress application prior to submission. | CSA §6 (Stage 4 — delete outcome) | Must |
| FR-IACRA-2.12 | The system shall allow an applicant to print a completed or in-progress application. | CSA §8 (user guides) | Should |
| FR-IACRA-2.13 | The system shall capture applicant biographic data: full name, date of birth, sex, birthplace, citizenship. | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.14 | The system shall optionally capture applicant SSN. | PIA-2019, CSA §4 | Should |
| FR-IACRA-2.15 | The system shall capture applicant identity documents: driver's license, passport, military ID, student ID (one or more). | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.16 | The system shall capture mailing and physical address, and physical description (hair, eye, height, weight). | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.17 | The system shall capture a drug convictions disclosure. | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.18 | The system shall capture prior FAA certificates and ratings held by the applicant. | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.19 | The system shall capture aviation experience: hours, aircraft types, and flight conditions. | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.20 | The system shall capture foreign license information when Form 8060-71 applies. | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.21 | The system shall capture medical certificate reference (class, date). | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.22 | The system shall capture English language proficiency attestation. | PIA-2019, CSA §4 | Must |
| FR-IACRA-2.23 | The system shall perform field-level validation at data entry (format, required fields, ranges, cross-field consistency). | CSA §3 (page flow enforcement) | Must |
| FR-IACRA-2.24 | The system shall preserve FTN as a first-class identifier on every application record. | CSA §4, CSA §12 (Rec 5) | Must |

---

## FR-IACRA-3 — Role-Based Workflows

The progressive five-stage workflow from applicant submission through CO decision. The application record is enriched by each role in sequence; authorization is enforced by role-to-page binding.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-IACRA-3.1 | The system shall allow an Applicant to submit a completed application, transitioning it to the RI queue. | CSA §6 (Stage 2→3) | Must |
| FR-IACRA-3.2 | The system shall present a Recommending Instructor (RI) with a checklist of endorsement prerequisites (flight hours, required maneuvers, cross-country, etc.) and allow the RI to review, annotate, and either endorse or return the application to the applicant. | CSA §6 (Stage 3) | Must |
| FR-IACRA-3.3 | The system shall allow the RI to attach a digital endorsement and forward the application to the DE, ASI, or School Examiner queue. | CSA §6 (Stage 3) | Must |
| FR-IACRA-3.4 | The system shall allow a Certifying Official (CO) — DE, ASI, AST, or School Examiner — to retrieve and conduct the practical test. | CSA §3, CSA §6 (Stage 4) | Must |
| FR-IACRA-3.5 | The system shall allow a CO to record one of four practical-test outcomes: **Approve**, **Disapprove**, **Discontinue**, or **Delete**. | CSA §6 (Stage 4), PIA-2023 | Must |
| FR-IACRA-3.6 | The system shall require the CO to capture a reason when the outcome is Disapprove or Discontinue. | CSA §6 (Stage 4) | Must |
| FR-IACRA-3.7 | The system shall allow the CO to select specific tasks (areas of operation) that were failed when recording a Disapprove outcome. | CSA §6 (Stage 4) | Must |
| FR-IACRA-3.8 | The system shall capture a digital signature from the CO on the final decision. | CSA §6 (Stage 4), PIA-2019 | Must |
| FR-IACRA-3.9 | The system shall progressively enrich a single application record through each role (Applicant → RI → CO) rather than creating parallel records. | CSA §3 | Must |
| FR-IACRA-3.10 | The system shall enforce role-based access control by presenting each role only the pages and actions permitted to that role. | CSA §3 | Must |
| FR-IACRA-3.11 | The system shall support School Examiner / Training Center Evaluator workflows for Part 141/142 endorsements on behalf of a school. | CSA §3 | Must |

---

## FR-IACRA-4 — Knowledge Test Integration

Retrieval of airman knowledge test results from Atlas Aviation, the vendor operating FAA knowledge testing. Results are keyed by FTN and displayed to the applicant and CO during application processing.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-IACRA-4.1 | The system shall retrieve airman knowledge test results from Atlas Aviation via a SQL Server linked-server connection. | CSA §2, CSA §7 | Must (current); replacement should use API |
| FR-IACRA-4.2 | The system shall look up knowledge test results by FTN. | CSA §4, CSA §7 | Must |
| FR-IACRA-4.3 | The system shall display the knowledge test title, test site, expiration date, and missed subject areas on the application. | CSA §6 (Stage 2) | Must |
| FR-IACRA-4.4 | The system shall auto-populate knowledge test data onto the relevant application form when a matching result exists. | CSA §6 (Stage 2) | Should |
| FR-IACRA-4.5 | The system shall alert the CO when a knowledge test result is expired or missing. | CSA §3 (CO decision model) | Should |

---

## FR-IACRA-5 — Practical Test Processing

End-to-end handling of the practical test, from pre-approval through outcome recording and PTRS reporting. Includes aircraft lookup for test event records.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-IACRA-5.1 | The system shall support pre-approval of an application by an ASI before a DE administers the practical test. | CSA §3, CSA §6 (Stage 3–4) | Must |
| FR-IACRA-5.2 | The system shall allow a DE or ASI to record practical-test scheduling information (date, location, aircraft). | CSA §6 (Stage 4) | Should |
| FR-IACRA-5.3 | The system shall allow the CO to record the practical-test result and the areas of operation evaluated. | CSA §6 (Stage 4) | Must |
| FR-IACRA-5.4 | The system shall generate a PTRS (Program Tracking and Reporting Subsystem) record reflecting the inspector's activity. | CSA §7 | Must |
| FR-IACRA-5.5 | The system shall provide an aircraft search capability to attach the test aircraft to the application record. | CSA §6 (Stage 4) | Should |

---

## FR-IACRA-6 — Document Management

Generation, rendering, and correction of application documents. The TIFF rendering capability is the artifact of the IACRA→CAIS handoff; the application viewer is the shared read-surface across roles.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-IACRA-6.1 | The system shall generate a TIFF image rendering of each approved application suitable for CAIS ingestion. | CSA §2, CSA §7 | Must (current); replacement should use structured records |
| FR-IACRA-6.2 | The system shall generate PDF output of the application for applicant and role printing. | CSA §8 (user guides) | Must |
| FR-IACRA-6.3 | The system shall provide an application viewer that presents a consolidated view of the record to the applicant and each role. | CSA §3, CSA §8 | Must |
| FR-IACRA-6.4 | The system shall allow the CO to upload corrected or supplemental documents attached to an application. | CSA §3, CSA §6 (Stage 4) | Should |
| FR-IACRA-6.5 | The system shall allow the user to select the output document format (TIFF or PDF) where applicable. | CSA §2, CSA §8 | Could |
| FR-IACRA-6.6 | The system shall retain application documents until superseded by the authoritative CAIS record, consistent with NARA N1-237-09-14. | CSA §4, CSA §9 | Must |

---

## FR-IACRA-7 — Integration

The integration surface that defines IACRA as the marshaling point between applicants, FAA internal systems, and the authoritative registry. The integrations are the contract that any replacement must preserve or coordinate.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-IACRA-7.1 | The system shall transmit approved application packages to CAIS as TIFF images over secure FTP. | CSA §2, CSA §7 | Must (current); replace with API in successor |
| FR-IACRA-7.2 | The system shall submit pilot-applicant identity data to TSA NTSDB for security vetting via the agreed secure portal. | CSA §7 | Must |
| FR-IACRA-7.3 | The system shall exchange test activity and airman identifier data with DMS (Designee Management System) bidirectionally. | CSA §7 | Must |
| FR-IACRA-7.4 | The system shall publish inspector and applicant activity data to SAS (Safety Assurance System). | CSA §7 | Must |
| FR-IACRA-7.5 | The system shall provide a one-time extract (name, email, FTN, DOB) to the USAS Portal. | CSA §7 | Should |
| FR-IACRA-7.6 | The system shall exchange training and currency records with FSTW (Flight Standards Training Website) for FAA staff. | CSA §7 | Must |
| FR-IACRA-7.7 | The system shall authenticate FAA internal users via MyAccess federated SSO. | CSA §2, CSA §7 | Must |
| FR-IACRA-7.8 | The system shall pull airman knowledge test results from Atlas Aviation keyed by FTN. | CSA §2, CSA §7 | Must (current); replacement should use API |
| FR-IACRA-7.9 | The system shall publish PTRS activity records for inspector reporting. | CSA §7 | Must |

---

## FR-IACRA-8 — Compliance

Regulatory, privacy, records-management, and security obligations that govern the system. These are effectively invariants for any replacement — the legal framework does not change when the technology does.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-IACRA-8.1 | The system shall operate within the boundaries of SORN DOT/FAA 847, "General Air Transportation Records on Individuals". | SORN, CSA §9 | Must |
| FR-IACRA-8.2 | The system shall treat application records as temporary under NARA schedule N1-237-09-14 and support deletion once superseded by the authoritative CAIS record. | NARA, CSA §4, CSA §9 | Must |
| FR-IACRA-8.3 | The system shall comply with NIST SP 800-53 Rev 5 security controls and maintain an active Authority to Operate. | NIST, CSA §9 | Must |
| FR-IACRA-8.4 | The system shall enforce multi-factor authentication for all user accounts. | CSA §2, CSA §10 | Must |
| FR-IACRA-8.5 | The public-applicant MFA mechanism shall meet NIST SP 800-63B AAL2 (phishing-resistant authenticator). | CSA §10 (gap), NIST 800-63B | Should (current gap — replacement must meet) |
| FR-IACRA-8.6 | The system shall comply with the privacy assessments documented in the 2019 and 2023 IACRA PIAs. | PIA-2019, PIA-2023, CSA §9 | Must |
| FR-IACRA-8.7 | The system shall produce the forms consistent with OMB control numbers 2120-0021 (8710-series) and 2120-0022 (8610/8400/8060 series). | CSA §5, CSA §9 | Must |
| FR-IACRA-8.8 | The system shall log role-based access, state transitions, and decision events for audit and reconciliation with CAIS. | NIST, CSA §3 | Must |

---

## Appendix A — MoSCoW priority summary

| Priority | Count | Notes |
|---|---|---|
| Must | 55 | Core capabilities and compliance invariants that must be preserved in any replacement. |
| Should | 11 | Important capabilities where a modernization improvement is expected (API-based integration, stronger MFA, corrections). |
| Could | 1 | Useful format-selection flexibility. |
| Won't (this baseline) | 0 | All captured capabilities are in scope for the replacement baseline. |

## Appendix B — Known modernization deltas

The following requirements describe IACRA **as-is** but are flagged for the CARES replacement to address:

- **FR-IACRA-1.4 / FR-IACRA-8.5** — Email-MFA does not meet NIST 800-63B AAL2; replacement should move public applicants to Login.gov or equivalent (consistent with MedXPress/MSS August 2025 adoption).
- **FR-IACRA-4.1 / FR-IACRA-7.8** — SQL Server linked-server to Atlas Aviation is a high-risk vendor coupling; replace with API or broker-based integration.
- **FR-IACRA-6.1 / FR-IACRA-7.1** — TIFF-over-FTP to CAIS is the defining legacy integration; unified document model under CARES removes the handoff entirely.
