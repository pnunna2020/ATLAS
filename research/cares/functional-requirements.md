# CARES — Functional Requirements

**System:** Civil Aviation Registration Electronic Services
**URL:** https://cares.faa.gov
**Source:** `research/cares/current-state-analysis.md`
**Date:** 2026-04-23
**Priority Scheme:** MoSCoW (Must / Should / Could / Won't)

CARES is the statutorily-mandated (Section 546, FAA Reauthorization Act of 2018) cloud replacement umbrella for Aircraft Registry, Airmen Registry, IACRA, and public inquiry services. As of 2026-04-23 it is in a **hybrid state**: Phase 1 aircraft-registration intake is live, but the legacy adjudication core (RMS, AVS Registry/CAIS, IACRA) still runs behind it. Phase 1 FOC has slipped four years from Fall 2023 to Fall 2027; Phase 2 (Airmen) FOC is now Fall 2027.

Requirements describe **what CARES is being built to do** across Phases 1 and 2 (Phase 3 has been absorbed into Phases 1/2). Phase-dependent requirements are marked. Source references use `CSA §N` for `current-state-analysis.md` section N, `PIA-2022` for the 2022 CARES PIA, and statute/reg/NARA citations as applicable.

---

## FR-CARES-1: Aircraft Registration Services

Aircraft Registry intake — the Phase 1 (live) scope. Covers N-number lifecycle, ownership changes, dealer registration, international operations, security agreements, de-registration, and specialized ownership forms. Fourteen forms are in scope per PIA Appendix A.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-CARES-1.1 | The system SHALL accept an Aircraft Registration Application (AC 8050-1) capturing registrant identity, address, contact, and aircraft make/model/serial. | CSA §4, §5, PIA-2022 App A | Must |
| FR-CARES-1.2 | The system SHALL accept Aircraft Re-registration / Renewal applications via AC 8050-1B and AC 8050-98. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.3 | The system SHALL accept Aircraft Bill of Sale (AC 8050-2) submissions documenting ownership transfer. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.4 | The system SHALL accept Dealer's Aircraft Registration Applications (AC 8050-88 and 88A). | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.5 | The system SHALL accept International Registry / Cape Town filings via AC 8050-4. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.6 | The system SHALL accept Triennial Aircraft Registration Reports (AC 8050-5). | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.7 | The system SHALL accept registration-amendment submissions using the REGAR form series. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.8 | The system SHALL accept Limited Liability Company (LLC) ownership-attestation statements. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.9 | The system SHALL accept Declaration of International Operations (DIO) submissions. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.10 | The system SHALL accept Heir-at-Law affidavits documenting ownership by inheritance. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.11 | The system SHALL accept Power of Attorney (POA) submissions authorizing third-party filings. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.12 | The system SHALL accept supporting Evidence of Ownership documentation as a catch-all for ownership chain. | CSA §5, PIA-2022 App A | Must |
| FR-CARES-1.13 | The system SHALL support N-number request, reservation, and assignment workflows. | CSA §4 | Must |
| FR-CARES-1.14 | The system SHALL support aircraft de-registration workflows (owner-initiated cancellation of registration). | CSA §5 | Must |
| FR-CARES-1.15 | The system SHALL capture registrant name, address, phone, and email on every Phase 1 submission. | CSA §4 | Must |
| FR-CARES-1.16 | The system SHALL capture aircraft make, model, and serial number on every Phase 1 submission. | CSA §4 | Must |
| FR-CARES-1.17 | The system SHALL enforce field-level validation (format, required fields, cross-field consistency) at data entry. | CSA §4 | Must |
| FR-CARES-1.18 | The system SHALL hand off finalized registration records to the AVS Registry / CAIS for authoritative adjudication during the dual-run window. | CSA §4, §7, §8 | Must (current); retire at Phase 1 FOC per §12 Rec 1 |

---

## FR-CARES-2: Identity & Onboarding

Account creation, identity proofing, and authentication for the two user populations CARES serves — FAA staff (PIV) and external public filers (identity-proofed). All authentication is federated to MyAccess; CARES holds no credentials directly.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-CARES-2.1 | The system SHALL federate all authentication to MyAccess for both FAA and public populations. | CSA §2, §6, §7 | Must |
| FR-CARES-2.2 | The system SHALL authenticate FAA employees and contractors via PIV card through MyAccess. | CSA §2, §6 | Must |
| FR-CARES-2.3 | The system SHALL route public filers through MyAccess identity proofing using SSN last-4, government-issued photo ID upload, and selfie liveness match. | CSA §2, §6 | Must |
| FR-CARES-2.4 | The system SHALL gate public-facing registration and account-creation pages with reCAPTCHA to deter automated submissions. | CSA §2, §6 | Must |
| FR-CARES-2.5 | The system SHALL NOT store local user passwords or credential secrets for either user population. | CSA §2, §6 | Must |
| FR-CARES-2.6 | The system SHALL propagate the authenticated identity (MyAccess subject, FAA PIV, or proofed public identity) into every submitted record for audit and non-repudiation. | CSA §2, §6, PIA-2022 | Must |
| FR-CARES-2.7 | The system SHOULD degrade gracefully when MyAccess is unavailable, presenting a clear status to users rather than generic errors (mitigates the coupling risk flagged in CSA §11). | CSA §11 (identity model split) | Should |

---

## FR-CARES-3: Document Management

Capture, signature, preservation, and retrieval of legal documents associated with registration transactions — bills of sale, LLC paperwork, POAs, and evidence of ownership. DocuSign provides digital-signature capture.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-CARES-3.1 | The system SHALL allow filers to upload supporting legal documents (bill of sale, evidence of ownership, LLC/trust paperwork) attached to a registration submission. | CSA §4 | Must |
| FR-CARES-3.2 | The system SHALL integrate DocuSign for digital signature capture on forms requiring signature, replacing wet-ink submission. | CSA §2, §7 | Must |
| FR-CARES-3.3 | The system SHALL receive DocuSign signed-document callbacks and associate the executed artifact with the corresponding submission record. | CSA §7 | Must |
| FR-CARES-3.4 | The system SHALL retain uploaded and DocuSign-signed documents as permanent records per NARA schedule N1-237-04-03. | CSA §2, §9 | Must |
| FR-CARES-3.5 | The system SHALL allow filers and authorized FAA staff to view and download documents attached to a registration record. | CSA §4, §7 | Must |
| FR-CARES-3.6 | The system SHOULD expose a canonical registry document service reusable by Aircraft Registry, Airmen Registry (Phase 2), and downstream consumers (DMS), replacing per-system document stores. | CSA §12 Rec 2 | Should |

---

## FR-CARES-4: Payment Processing

Fee collection for registration transactions. Pay.gov is the sole payment backend; CARES is the integration point and expects to broker payments for legacy systems during dual-run and beyond.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-CARES-4.1 | The system SHALL initiate payments through Pay.gov for registration fees. | CSA §2, §7 | Must |
| FR-CARES-4.2 | The system SHALL calculate the fee applicable to each transaction type based on form and service requested. | CSA §5, §7 | Must |
| FR-CARES-4.3 | The system SHALL receive Pay.gov payment-confirmation callbacks and bind the confirmation to the originating registration record. | CSA §7 | Must |
| FR-CARES-4.4 | The system SHALL persist a transaction history (transaction ID, amount, timestamp, payer, status) for each payment. | CSA §7, PIA-2022 | Must |
| FR-CARES-4.5 | The system SHALL block progression of a registration record past the payment step until Pay.gov confirms success. | CSA §7 | Must |
| FR-CARES-4.6 | The system SHOULD broker Pay.gov access for IACRA and AVS Registry (becoming the single Treasury integration point), replacing parallel integrations. | CSA §12 Rec 3 | Should |

---

## FR-CARES-5: Airmen Certification (Phase 2 — Absorbing IACRA)

Phase 2 scope: absorb the full airmen-certification lifecycle from IACRA. This section mirrors today's IACRA capabilities; deltas from IACRA are captured as modernization notes. Phase 2 FOC is currently Fall 2027 and the data model is not yet frozen.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-CARES-5.1 | The system SHALL support Form 8710-1 (Airman Certificate and/or Rating Application). | CSA §4 (Phase 2), IACRA FR-2.1 | Must (Phase 2) |
| FR-CARES-5.2 | The system SHALL support Form 8710-11 (Sport Pilot Application). | CSA §4 (Phase 2), IACRA FR-2.5 | Must (Phase 2) |
| FR-CARES-5.3 | The system SHALL support Form 8710-13 (Remote Pilot Certificate and/or Rating Application). | CSA §4 (Phase 2), IACRA FR-2.6 | Must (Phase 2) |
| FR-CARES-5.4 | The system SHALL support Form 8610-1 (Application for Inspection Authorization). | CSA §4 (Phase 2), IACRA FR-2.2 | Must (Phase 2) |
| FR-CARES-5.5 | The system SHALL support Form 8610-2 (Mechanic / Parachute Rigger Application). | CSA §4 (Phase 2), IACRA FR-2.3 | Must (Phase 2) |
| FR-CARES-5.6 | The system SHALL support Form 8400-3 (Aircraft Dispatcher Certification). | CSA §4 (Phase 2), IACRA FR-2.4 | Must (Phase 2) |
| FR-CARES-5.7 | The system SHALL support Form 8060-71 (Verification of Authenticity of Foreign License, Rating, and Medical Certification). | CSA §4 (Phase 2), IACRA FR-2.7 | Must (Phase 2) |
| FR-CARES-5.8 | The system SHALL retrieve and display airman knowledge test results keyed by FAA Tracking Number (FTN). | CSA §4 (Phase 2), IACRA FR-4.x | Must (Phase 2) |
| FR-CARES-5.9 | The system SHALL support practical-test result recording with the four IACRA outcomes (Approve, Disapprove, Discontinue, Delete), including failed areas of operation when Disapproved. | CSA §4 (Phase 2), IACRA FR-3.5–3.7 | Must (Phase 2) |
| FR-CARES-5.10 | The system SHALL support certificate issuance and ratings/endorsements assignment upon Certifying Official approval. | CSA §4 (Phase 2) | Must (Phase 2) |
| FR-CARES-5.11 | The system SHALL support the role-based progressive workflow (Applicant → Recommending Instructor → Certifying Official) for each airman application. | IACRA FR-3.x (baseline) | Must (Phase 2) |
| FR-CARES-5.12 | The system SHOULD pull the airmen dataset from IACRA/CAIS as a read-only federation first, and only migrate ownership once the CARES representation has been stable for two or more quarters (avoids schema churn in production). | CSA §12 Rec 6 | Should (Phase 2) |
| FR-CARES-5.13 | The system SHOULD target a narrow airman-certification MVP (intake replacement) for Phase 2 IOC rather than a full big-bang IACRA replacement. | CSA §12 Rec 5 | Should (Phase 2) |

---

## FR-CARES-6: Public Inquiry & Access

Unauthenticated public surfaces for looking up aircraft registration, airmen, active airmen statistics, and downloadable registration datasets. This is the public-facing consolidation target that replaces the separate legacy inquiry sites.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-CARES-6.1 | The system SHALL provide an unauthenticated Aircraft Inquiry search by N-number, make/model, registrant name, serial number, and ZIP. | CSA §1 (scope consolidation) | Must |
| FR-CARES-6.2 | The system SHALL provide an unauthenticated Airmen Inquiry search (Phase 2) exposing the fields permitted under SORN DOT/FAA 847. | CSA §1, §4 (Phase 2) | Must (Phase 2) |
| FR-CARES-6.3 | The system SHALL publish active airmen statistics aggregates for public consumption. | CSA §1 | Must |
| FR-CARES-6.4 | The system SHALL provide downloadable aircraft-registration datasets (bulk export) consistent with the legacy Aircraft Registry public download. | CSA §1 | Must |
| FR-CARES-6.5 | The system SHALL validate N-number availability and allow lookup of reserved/assigned N-numbers. | CSA §4 | Must |
| FR-CARES-6.6 | The system SHALL apply privacy controls limiting public-inquiry fields to those authorized for public release under the applicable SORNs and 14 CFR 47/49. | CSA §9, PIA-2022 | Must |

---

## FR-CARES-7: Integration

External and internal system integrations. CARES is the emerging integration hub; today it coexists with the legacy registry, and Phase 2 will pull IACRA into CARES. A public API is a gap in the current state and a modernization target.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-CARES-7.1 | The system SHALL federate authentication to MyAccess for PIV and public identity-proofed users. | CSA §2, §7 | Must |
| FR-CARES-7.2 | The system SHALL integrate outbound to Pay.gov for payment initiation and inbound callback for confirmation. | CSA §2, §7 | Must |
| FR-CARES-7.3 | The system SHALL integrate outbound to DocuSign for envelope creation and inbound callback for signed documents. | CSA §2, §7 | Must |
| FR-CARES-7.4 | The system SHALL coexist bidirectionally with AVS Registry / CAIS during the Phase 1 → Phase 2 dual-run window, handing over finalized records to the authoritative registry of truth. | CSA §7, §8 | Must (current) |
| FR-CARES-7.5 | The system SHALL absorb IACRA intake, processing, and certificate issuance by Phase 2 FOC, retiring IACRA as an independent application. | CSA §1, §8, §10 | Must (Phase 2) |
| FR-CARES-7.6 | The system SHALL submit pilot-applicant identity data to TSA NTSDB for security vetting for airman applications (Phase 2). | CSA §4 (Phase 2), IACRA FR-7.2 | Must (Phase 2) |
| FR-CARES-7.7 | The system SHALL invest in first-class adapters (CARES→RMS, CARES→CAIS, CARES→IACRA) with defined SLAs to support the extended dual-run window. | CSA §12 Rec 4 | Should |
| FR-CARES-7.8 | The system SHOULD expose a public REST/OAuth API surface for downstream consumers (DMS, designees, airmen workflow tools) rather than forcing screen-scraping or manual handoff. | CSA §11, §12 Rec 7 | Should |
| FR-CARES-7.9 | The system SHOULD become the single intake surface for both aircraft and airman submissions even before Phase 2 FOC, with a thin adapter to IACRA for adjudication during the transition. | CSA §12 Rec 1 | Should |

---

## FR-CARES-8: Compliance

Statutory, privacy, records-retention, and security invariants. The Section 546 mandate makes schedule and scope compliance politically visible; the Parts 47/49 January 2025 update is a recent regulatory change CARES must reflect through both its intake surface and the legacy adjudication core during dual-run.

| ID | Requirement | Source | Priority |
|---|---|---|---|
| FR-CARES-8.1 | The system SHALL operate in fulfillment of Section 546 of the FAA Reauthorization Act of 2018 (statutory modernization mandate). | CSA §1, §9 | Must |
| FR-CARES-8.2 | The system SHALL comply with 14 CFR Parts 47 (aircraft registration) and 49 (recording of aircraft conveyances), including the January 2025 update. | CSA §9 | Must |
| FR-CARES-8.3 | The system SHALL maintain a current Authority to Operate; the September 16, 2022 ATO is the baseline. | CSA §9 | Must |
| FR-CARES-8.4 | The system SHALL comply with the CARES 2022 Privacy Impact Assessment and refresh the PIA as functional scope changes. | CSA §9, PIA-2022 | Must |
| FR-CARES-8.5 | The system SHALL retain registration records per NARA schedule N1-237-04-03 as permanent records. | CSA §2, §9 | Must |
| FR-CARES-8.6 | The system SHALL complete an annual security review. | CSA §9 | Must |
| FR-CARES-8.7 | The system SHALL implement cloud security controls consistent with FedRAMP posture and FAA cloud governance for the chosen CSP. | CSA §2, §9 | Must |
| FR-CARES-8.8 | The system SHALL comply with NIST SP 800-53 Rev 5 security controls. | CSA §9, NIST | Must |
| FR-CARES-8.9 | The system SHALL handle airman PII (Phase 2) consistent with SORN DOT/FAA 847 when absorbing IACRA. | CSA §1, §4 (Phase 2), IACRA SORN | Must (Phase 2) |
| FR-CARES-8.10 | The system SHALL support public-inquiry disclosure in compliance with the applicable SORNs and 14 CFR 47/49 public-release provisions. | CSA §9, PIA-2022 | Must |
| FR-CARES-8.11 | The system SHALL track regulatory changes (e.g., Parts 47/49 updates) across both the CARES intake surface and the legacy adjudication core during the dual-run. | CSA §9, §10 | Must (current; sunsets when hybrid state ends) |

---

## Appendix A — MoSCoW priority summary

| Priority | Count |
|---|---|
| Must | 54 |
| Should | 10 |
| Could | 0 |
| Won't (this baseline) | 0 |

## Appendix B — Phase coverage

| Phase | Status | Requirement areas |
|---|---|---|
| Phase 1 (live) | IOC Dec 2022, FOC Fall 2027 | FR-CARES-1, -2, -3, -4, -6 (aircraft), -7 (current), -8 |
| Phase 2 (planned) | IOC Fall 2025, FOC Fall 2027 | FR-CARES-5 (all), FR-CARES-6.2 (airmen inquiry), FR-CARES-7.5–7.6 (IACRA absorption, TSA), FR-CARES-8.9 |
| Phase 3 | Absorbed into Phases 1/2 | n/a |

## Appendix C — Modernization gaps flagged for CARES

- **No public API** (FR-CARES-7.8) — every downstream consumer today is forced into brittle handoffs.
- **Hybrid state is now steady-state** (FR-CARES-7.4, -7.7) — dual-run for 4+ years means adapters must be engineered as first-class services.
- **Phase 2 data model not yet frozen** (FR-CARES-5.12) — federate IACRA/CAIS data read-only first; migrate ownership only after stability.
- **Identity coupling to MyAccess** (FR-CARES-2.7) — a single IdP outage takes down both PIV and public paths; graceful degradation needs explicit design.
