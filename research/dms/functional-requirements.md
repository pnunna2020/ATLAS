# DMS — Functional Requirements

**System:** Designee Management System
**URL:** https://designee.faa.gov
**Source:** `research/dms/current-state-analysis.md`
**Date:** 2026-04-23
**Priority Scheme:** MoSCoW (Must / Should / Could / Won't)

---

## FR-DMS-1: Designee Registration & Application

Onboarding of prospective designees from initial account creation through completed application submission, including type-specific fields and document collection.

| ID | Requirement | Source Artifact | Priority |
|---|---|---|---|
| FR-DMS-1.1 | Prospective designees SHALL self-register by creating an account with name, email, chosen username, and password. | Current-State §4 (Registration fields) | Must |
| FR-DMS-1.2 | The system SHALL require each account to have one security question/answer for legacy credential recovery, pending Login.gov migration. | Current-State §2, §4 | Must |
| FR-DMS-1.3 | The system SHALL capture a profile record containing legal name, suffix, date of birth, gender, citizenship, and airman certificate number. | Current-State §4 (Profile fields) | Must |
| FR-DMS-1.4 | The system SHALL capture contact information: phone number(s), mailing address, and physical address. | Current-State §4 | Must |
| FR-DMS-1.5 | The system SHALL associate the designee's FAA Tracking Number (FTN) with the profile record. | Current-State §4 | Must |
| FR-DMS-1.6 | The system SHALL collect background/suitability questions as part of the application. | Current-State §4 | Must |
| FR-DMS-1.7 | The system SHALL support upload of supporting documents (application packet, transcripts, certificate copies) and retain them with the designee record. | Current-State §4 | Must |
| FR-DMS-1.8 | The system SHALL capture medical license number and NPI for AME applicants. | Current-State §4 | Must |
| FR-DMS-1.9 | The system SHALL capture employer point-of-contact information for TCE, APD, and DADE applicants. | Current-State §3, §4 | Must |
| FR-DMS-1.10 | The system SHOULD allow an optional applicant photograph on the profile record. | Current-State §4 | Should |
| FR-DMS-1.11 | The system SHALL capture references supplied by the applicant. | Current-State §4 | Must |

---

## FR-DMS-2: Appointment & CLOA Management

Appointment lifecycle from applicant pool through designation, including generation of the Designee Number, CLOA, and Designation Certificate, plus ongoing authorization management.

| ID | Requirement | Source Artifact | Priority |
|---|---|---|---|
| FR-DMS-2.1 | The system SHALL place completed applications into an applicant pool visible to the responsible office (AIR, AAM, FS). | Current-State §5 (Appointment lifecycle) | Must |
| FR-DMS-2.2 | The system SHALL support evaluation workflows where the responsible office screens qualifications, records interview outcomes, and selects candidates. | Current-State §5 | Must |
| FR-DMS-2.3 | The system SHALL generate a unique 9-digit Designee Number upon appointment. | Current-State §4 (System-generated outputs) | Must |
| FR-DMS-2.4 | The system SHALL generate a Certificate of Letter of Authorization (CLOA) stating the designee's functions, limitations, and expiration. | Current-State §4 | Must |
| FR-DMS-2.5 | The system SHALL generate a Designation Certificate as a display credential for the designee. | Current-State §4 | Must |
| FR-DMS-2.6 | The system SHALL maintain authorizations and limitations on each CLOA and make them the authoritative source for designee scope. | Current-State §4, §12 (Recommendation 3) | Must |
| FR-DMS-2.7 | The system SHALL allow a designee to submit an additional-authorization request to expand authorized functions. | Current-State §5 (Operational workflows) | Must |
| FR-DMS-2.8 | The system SHOULD expose CLOA / authorization data as a versioned API for downstream consumers (IACRA, SAS, eFSAS successor). | Current-State §12 (Recommendation 3) | Should |

---

## FR-DMS-3: Operational Workflows

Day-to-day oversight workflows once a designee is active: pre-approvals, activity reporting, history, and annual extensions.

| ID | Requirement | Source Artifact | Priority |
|---|---|---|---|
| FR-DMS-3.1 | The system SHALL allow a designee to submit a pre-approval request for a specific activity before performance. | Current-State §5 | Must |
| FR-DMS-3.2 | The responsible office SHALL review and approve/deny pre-approval requests through the system. | Current-State §5 | Must |
| FR-DMS-3.3 | The system SHALL require designees to submit post-activity reports within 7 days of the activity. | Current-State §5 | Must |
| FR-DMS-3.4 | The system SHALL maintain a continuous activity history log of all completed authorized actions per designee. | Current-State §5 | Must |
| FR-DMS-3.5 | The system SHALL block further activity for a designee with overdue post-activity reports. | Current-State §5 (7-day due timing) | Must |
| FR-DMS-3.6 | The system SHALL support annual extension of designee authority, updating the CLOA expiration date upon approval. | Current-State §5 | Must |

---

## FR-DMS-4: Corrective Action & Lifecycle

Adverse-action and end-of-life workflows: corrective action, voluntary surrender, suspension, termination, and reinstatement — all with regulated due-process timelines.

| ID | Requirement | Source Artifact | Priority |
|---|---|---|---|
| FR-DMS-4.1 | The system SHALL support office-initiated corrective-action workflows with designee response and resolution tracking. | Current-State §5 | Must |
| FR-DMS-4.2 | The system SHALL support voluntary surrender of designation. | Current-State §5 | Must |
| FR-DMS-4.3 | The system SHALL allow reinstatement of a voluntarily-surrendered designation within a 1-year window from surrender date. | Current-State §5 | Must |
| FR-DMS-4.4 | The system SHALL support temporary suspension of a designee with a release task that must be completed within 180 days. | Current-State §5 | Must |
| FR-DMS-4.5 | The system SHALL enforce a 15-day designee response window on termination-for-cause due-process workflows. | Current-State §5 | Must |
| FR-DMS-4.6 | The system SHALL support reinstatement workflows for terminated designees subject to office approval. | Current-State §5 | Must |
| FR-DMS-4.7 | The system SHALL retain full lifecycle history (appointment, corrective actions, surrender, suspension, termination, reinstatement) for each designee. | Current-State §5, §8 (25-year retention) | Must |

---

## FR-DMS-5: Training Management

Training enrollment, delivery, and record-keeping — including functions absorbed from the retiring Designee Registration System (DRS).

| ID | Requirement | Source Artifact | Priority |
|---|---|---|---|
| FR-DMS-5.1 | The system SHALL absorb DRS course registration and enrollment functions per Releases 8.0 / 8.1. | Current-State §9 (DRS Absorption) | Must |
| FR-DMS-5.2 | The system SHALL transition applicable course-delivery and training workflows to the FAA eLMS platform where designated. | Current-State §9, §10 | Must |
| FR-DMS-5.3 | The system SHALL delegate training-course delivery to Blackboard (replacing legacy DRS LMS) while retaining enrollment records in DMS. | Current-State §9 | Must |
| FR-DMS-5.4 | The system SHALL delegate course-fee payment processing to Pay.gov and record transaction confirmations on the designee record. | Current-State §9 | Must |
| FR-DMS-5.5 | The system SHALL maintain training records per designee, including required, completed, initial, and recurrent training. | Current-State §5 (Training records) | Must |
| FR-DMS-5.6 | The system SHALL track orientation completion for newly-appointed designees. | Current-State §5 | Must |

---

## FR-DMS-6: Public Directory (Designee Locator)

Public-facing search surface exposing active designee contact information, with privacy controls over which fields are published.

| ID | Requirement | Source Artifact | Priority |
|---|---|---|---|
| FR-DMS-6.1 | The system SHALL provide a public Designee Locator searchable without authentication. | Current-State §7 | Must |
| FR-DMS-6.2 | The Locator SHALL support search by name, address, city, state, ZIP, phone, country, designee type, and responsible office. | Current-State §7 | Must |
| FR-DMS-6.3 | The Locator SHALL publish for each active designee: name, address, city, state, ZIP, phone, country, designee type, and responsible office. | Current-State §7 | Must |
| FR-DMS-6.4 | The system SHALL apply privacy controls limiting published fields to those authorized under SORN DOT/FAA 830. | Current-State §7, §8, §11 (PII exposure risk) | Must |
| FR-DMS-6.5 | The system SHOULD allow individual designees to suppress optional published fields subject to policy. | Current-State §11 | Should |

---

## FR-DMS-7: Integration

Interfaces to downstream and partner systems that consume or exchange designee data.

| ID | Requirement | Source Artifact | Priority |
|---|---|---|---|
| FR-DMS-7.1 | The system SHALL provide outbound designee lookup (name, ID, phone, type) to NACIP. | Current-State §6 | Must |
| FR-DMS-7.2 | The system SHALL support bidirectional exchange with MSS for AME activity metrics and designee profile synchronization. | Current-State §6 | Must |
| FR-DMS-7.3 | The system SHALL support bidirectional exchange with IACRA for test/checkride activity linked to airman identification. | Current-State §6 | Must |
| FR-DMS-7.4 | The system SHALL provide outbound workload and resourcing data (designee name, ID, type, certificate expiration) to SAS. | Current-State §6 | Must |
| FR-DMS-7.5 | The system SHALL provide outbound pay-grade calculation data (designee name, ID, type, status) to eFSAS or its designated successor system. | Current-State §6, §10 (eFSAS decommission), §12 (Recommendation 6) | Must |
| FR-DMS-7.6 | The system SHALL provide outbound designee identity to the ATLAS Aviation testing/assessment platform. | Current-State §6 | Must |
| FR-DMS-7.7 | The system SHOULD establish DMS as the master for designee identity and convert MSS bidirectional profile sync to read-only downstream consumption. | Current-State §12 (Recommendation 1) | Should |

---

## FR-DMS-8: Compliance

Statutory, privacy, records, and identity-governance obligations the system must satisfy.

| ID | Requirement | Source Artifact | Priority |
|---|---|---|---|
| FR-DMS-8.1 | The system SHALL operate in accordance with 14 CFR Part 183 (FAA designee statutory authority). | Current-State §1, §8 | Must |
| FR-DMS-8.2 | The system SHALL implement operational policy per FAA Order 8000.95D, including pending Change 1 under docket FAA-2025-1218. | Current-State §8, §10 | Must |
| FR-DMS-8.3 | The system SHALL handle designee PII in accordance with SORN DOT/FAA 830. | Current-State §8 | Must |
| FR-DMS-8.4 | The system SHALL maintain information collections under OMB Control 2120-0033 (PRA clearance). | Current-State §8 | Must |
| FR-DMS-8.5 | The system SHALL retain designee records for 25 years after inactive status per NARA schedule DAA-0237-2020-0013. | Current-State §8 | Must |
| FR-DMS-8.6 | The system SHALL migrate non-FAA user authentication to Login.gov and retire the local password + security-question credential store. | Current-State §2, §10, §12 (Recommendation 4) | Must |
| FR-DMS-8.7 | The system SHALL upgrade FAA internal authentication from IWA / Active Directory to a zero-trust identity posture in lockstep with FAA identity modernization. | Current-State §10, §11, §12 (Recommendation 5) | Should |
| FR-DMS-8.8 | The system SHALL maintain a current Privacy Impact Assessment (2022 PIA on file; refresh pending). | Current-State §8, §10 | Must |
| FR-DMS-8.9 | The system SHALL enforce NIST SP 800-53 Rev 5 security controls. | Current-State §1 | Must |
