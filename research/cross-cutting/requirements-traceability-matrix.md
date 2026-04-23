# Cross-System Requirements Traceability Matrix

**Systems:** RMS, MedXPress/MSS, IACRA, DMS, CARES
**Source:** Functional requirements docs at `research/{rms,medxpress-mss,iacra,dms,cares}/functional-requirements.md`
**Date:** 2026-04-23

This matrix identifies duplicate functionality, shared-service consolidation targets, integration anti-patterns, identifier unification, data-element overlap, and rationalization priority across the five FAA systems. It is the load-bearing input for the ATLAS target-state architecture — every duplicate row is an opportunity to collapse parallel investment, and every integration anti-pattern is a boundary that will either be modernized or calcified.

---

## 1. Duplicate Functionality Map

Each row is a capability implemented in two or more of the five systems. A capability counts as duplicative if the business outcome is the same even when the regulatory context (aircraft vs. airman vs. medical vs. designee) differs. The rationalization action is the target-state recommendation for CARES and/or a shared platform service.

| Capability | RMS | MedXPress/MSS | IACRA | DMS | CARES | Rationalization Action |
|---|---|---|---|---|---|---|
| **User account creation (self-service)** | — (consumes IACRA/CARES identity) | FR-MSS-1.1 (local) | FR-IACRA-1.1 (local) | FR-DMS-1.1 (local) | FR-CARES-2.3 (MyAccess proofed) | Consolidate onto MyAccess + Login.gov federation; retire four local stores |
| **Password + security-question credential store** | — | FR-MSS-1.2 (legacy) | FR-IACRA-1.3 (legacy) | FR-DMS-1.2 (legacy) | FR-CARES-2.5 (none — federated) | Retire per system Login.gov/MyAccess migration (DMS §8.6, MSS §5.6, IACRA §1.4) |
| **MFA enforcement for public users** | — | FR-MSS-1.16 (Login.gov) | FR-IACRA-1.4 (email code — AAL2 gap) | FR-DMS-8.6 (pending Login.gov) | FR-CARES-2.3 (MyAccess) | Unify on Login.gov (AAL2) for all non-FAA users |
| **FAA internal staff authentication** | (operational) | FR-MSS-5.5 (PIV via Directory) | FR-IACRA-1.5 / 7.7 (MyAccess PIV) | FR-DMS-8.7 (IWA/AD — zero-trust pending) | FR-CARES-2.2 (MyAccess PIV) | Single PIV-through-MyAccess flow; retire IWA/AD for DMS |
| **Role-based access control** | FR-RMS-6.1 (examiner roles) | FR-MSS-5.5 (AAM/CAMI/RFS) | FR-IACRA-1.6, 3.10 (6 roles) | FR-DMS-2.1–2.2 (office roles) | FR-CARES-2.6 (PIV + proofed) | Shared authZ service keyed on unified identity + system-scoped role claims |
| **Identity profile (name/address/contact) management** | FR-RMS-2.4 (airmen) | FR-MSS-1.4 (applicant) | FR-IACRA-1.7, 2.13–2.16 | FR-DMS-1.3–1.4 | FR-CARES-1.15 | Person master record ("Golden Record") with per-system extension attributes |
| **Application submission workflow** | FR-RMS-1.2 (aircraft) | FR-MSS-1.x (8500-8) | FR-IACRA-2.8–2.12 (7 forms) | FR-DMS-1.x (designee app) | FR-CARES-1.x (14 forms) / 5.x (airmen) | Unified case/workflow engine with form-schema plugins |
| **Save-and-resume draft application** | (paper) | FR-MSS-1.13 (30-day auto-delete) | FR-IACRA-2.9 | (implicit) | FR-CARES-1.17 | Shared draft service with tenant-configurable retention |
| **Application status tracking** | FR-RMS-1.x (implicit) | FR-MSS-1.12 (8 values) | FR-IACRA-2.10 | FR-DMS-3.x | FR-CARES (implicit) | Common status state machine (Draft → Submitted → In Review → Action Required → Decided) |
| **Digital signature capture** | FR-RMS-6.4 (2025 rule) | (AME sign on disposition) | FR-IACRA-3.8 (CO sign) | (CLOA sign) | FR-CARES-3.2 (DocuSign) | DocuSign or equivalent as shared signature service |
| **Role-based progressive workflow (multi-actor review)** | FR-RMS-3.2 (examiner packet) | FR-MSS-3.2 (CAMI/RFS/HQ queues) | FR-IACRA-3.1–3.11 (5 stages) | FR-DMS-2.1–2.2, 3.1–3.2 (pre-approval) | FR-CARES-5.11 | Shared workflow/queue engine with routing rules per domain |
| **Document upload (applicant/designee)** | FR-RMS-3.1 (scanned) | FR-MSS-2.10–2.13 (25 docs, 3 MB, 30+ types) | FR-IACRA-6.4 (CO corrections) | FR-DMS-1.7 (app packet) | FR-CARES-3.1 (legal docs) | Shared document service: common taxonomy, uplifted size/format limits (FR-MSS-3.7) |
| **Document type taxonomy** | FR-RMS-3.2 (envelope/app/evidence/correspondence) | FR-MSS-2.13 (30+ clinical categories) | (TIFF only) | (app packet, certs, transcripts) | FR-CARES-3.1 (bill of sale, LLC, POA) | Unified taxonomy in shared document service, domain-specific extensions |
| **Document imaging/scan of paper intake** | FR-RMS-3.1–3.5 (TIFF today, work packets) | FR-MSS-3.1 (DIWS archive) | FR-IACRA-6.1 (TIFF rendering) | (implicit) | — | One imaging/OCR pipeline; deprecate TIFF in favor of PDF/A + OCR |
| **Image annotation / record notation** | FR-RMS-3.3 (immutable annotations) | FR-MSS-3.1 (DIWS) | — | — | — | Preserve annotation capability in shared document service |
| **Document retention enforcement** | FR-RMS-3.4 (60yr airman / Permanent aircraft / 5yr EIS / 6mo foreign) | FR-MSS-3.6 (50yr) | FR-IACRA-6.6 (temp — superseded by CAIS) | FR-DMS-8.5 (25yr) | FR-CARES-3.4 / 8.5 (Permanent) | Shared retention engine with NARA schedule per record class |
| **Public inquiry / search surface** | FR-RMS-4.1 (aircraft), 4.2 (airmen), 4.6 (validity) | — | — | FR-DMS-6.1–6.3 (designee locator) | FR-CARES-6.1–6.5 | Single unified public inquiry API + UI (aircraft, airmen, designee, cert validity) |
| **Bulk downloadable public dataset** | FR-RMS-4.4 (monthly airmen CSV) | — | — | — | FR-CARES-6.4 (aircraft bulk) | Unified public dataset publishing service |
| **Certificate/authorization issuance** | FR-RMS-2.1 (airman cert from IACRA), 1.x (aircraft reg) | FR-MSS-2.9 (medical cert) | FR-IACRA-5.x (temp cert on CO approve) | FR-DMS-2.3–2.5 (CLOA, Designee #, Designation Cert) | FR-CARES-5.10 (airman cert Phase 2) | Shared credential-issuance service (cert number, document render, registry write) |
| **Certificate replacement / reissue** | FR-RMS-2.2 | — | — | — | (planned Phase 2) | Keep in shared credential service |
| **Temporary / interim authority** | FR-RMS-2.6 | — | FR-IACRA-5.1 (pre-approval), temp cert | FR-DMS-4.4 (suspension release) | — | Temp-authority state in shared credential model |
| **Payment processing (Pay.gov)** | FR-RMS-5.5 ($5 fee, tx-ID only) | — | — | FR-DMS-5.4 (course fees) | FR-CARES-4.1–4.5 / 7.2 | Single Pay.gov broker (CARES FR-4.6 / 7.2) — retire duplicate Pay.gov integrations |
| **TSA NTSDB vetting** | FR-RMS-5.6 (via IACRA) | — | FR-IACRA-7.2 | — | FR-CARES-7.6 (Phase 2) | Single TSA vetting integration from CARES; RMS consumes downstream |
| **FTN (FAA Tracking Number) as identity key** | — (uses cert # / CAIS keys) | (applicant/MID) | FR-IACRA-1.2, 2.24 | FR-DMS-1.5 | FR-CARES-5.8 | Unified person identifier strategy (FTN as keystone for airmen) |
| **Audit logging** | FR-RMS-6.5 | FR-MSS-6.9 | FR-IACRA-1.9, 8.8 | (implicit) | FR-CARES-2.6 | Shared audit/compliance logging service |
| **NIST 800-53 Rev 5 ATO** | FR-RMS-6.1 | FR-MSS-6.1 (HIGH) | FR-IACRA-8.3 | FR-DMS-8.9 | FR-CARES-8.8 | Single FedRAMP-aligned control inheritance; narrow FIPS-HIGH boundary (MSS) |
| **Privacy Act / SORN compliance** | FR-RMS-6.3 (801, 847) | FR-MSS-6.2 (856) | FR-IACRA-8.1 (847) | FR-DMS-8.3 (830) | FR-CARES-8.9 / 8.10 (47/49, 847) | SORN-aware shared disclosure engine; unify 801/847/830/856 on access policies |
| **Periodic PIA refresh** | (required) | FR-MSS-6.8 | FR-IACRA-8.6 | FR-DMS-8.8 | FR-CARES-8.4 | Privacy program standardization; shared PIA template per system scope change |
| **Knowledge/practical test result ingest** | — | — | FR-IACRA-4.1–4.5 (Atlas SQL linked) | FR-DMS-7.6 (ATLAS outbound) | FR-CARES-5.8 (FTN) | Replace SQL link with shared testing-results API |
| **Designee/AME oversight & metrics** | — | FR-MSS-5.3 (AME metrics to DMS) | FR-IACRA-7.3 (test activity to DMS) | FR-DMS-7.2, 7.3 | — | DMS becomes designee master (FR-DMS-7.7); other systems read-only |
| **Correspondence / notification** | FR-RMS-1.3 (renewal notice) | FR-MSS-3.3 (approval/denial letters) | (implicit — status) | FR-DMS-4.1 (corrective action) | (implicit) | Shared notification/correspondence service (email, letter generation, templating) |
| **Activity/case history log** | FR-RMS-6.5 (audit) | FR-MSS-3.1 (case history) | FR-IACRA-8.8 | FR-DMS-3.4, 4.7 | (implicit) | Shared event-sourced case history, consumable by any domain |
| **Address/profile change (30-day statutory)** | FR-RMS-2.4 (airmen §61.60, 30-day aircraft) | FR-MSS-1.4 (applicant-captured) | FR-IACRA-1.7 | FR-DMS-1.4 | FR-CARES-1.15 | Person master record + propagation to all domains |

---

## 2. Shared Service Candidates

Derived from the duplicates above. Each row is a platform service that replaces functionality today implemented 2–5 times. Priority weighs consolidated investment savings × feasibility given CARES scope + Phase 2 timeline (Fall 2027 FOC).

| Shared Service | What It Replaces | Systems Affected | Priority | Complexity |
|---|---|---|---|---|
| **Unified Identity Service** (Login.gov for public + MyAccess/PIV for FAA, with federation) | MedXPress/DMS/IACRA local accounts (pw + security Q) + DMS IWA/AD + IACRA email-MFA (AAL2 gap) | MSS, IACRA, DMS, CARES, RMS (consumer) | **P0** — load-bearing for every other service | Medium — Login.gov adoption proven (MSS Aug 2025); harder for DMS (zero-trust migration pending) |
| **Shared Document Service** (upload, storage, taxonomy, retention, annotation, signature via DocuSign) | RMS TIFF work packets + MSS 25-doc/3 MB/30+ types + IACRA TIFF rendering + DMS packet store + CARES legal-doc store | All 5 | **P0** — enables TIFF/FTP retirement and PDF/A+OCR future | High — size ceilings (FR-MSS-3.7), NARA schedules vary (5yr to Permanent), legal chain-of-custody |
| **Unified Case / Application Workflow Engine** (form-schema plugins, multi-actor role workflows, queues, status state machine, SLAs) | IACRA 5-stage workflow + MSS CAMI/RFS/HQ queues + DMS pre-approval/post-activity + CARES aircraft workflow + RMS examiner packet routing | All 5 | **P1** | High — each domain has distinct rules; plugin boundary must be disciplined |
| **Common Payment Service (Pay.gov broker)** | RMS $5-fee integration + DMS course-fee integration + CARES payment + (future) IACRA/airmen Phase 2 fees | RMS, DMS, CARES; IACRA Phase 2 | **P0** — CARES FR-4.6 / 7.2 already scopes this | Low–Medium — Pay.gov API stable; mostly wiring + tx-ID storage |
| **Shared Notification / Correspondence Service** (templated email, letter generation, renewal notices, adverse-action letters, PDF mailers) | RMS renewal notices + MSS approval/denial letters + DMS corrective-action letters + IACRA status notifications + CARES confirmations | All 5 | **P2** | Medium — templating is easy; audit and multi-channel delivery less so |
| **Unified Public Inquiry API** (aircraft, airmen, designee locator, certificate validity) | RMS aircraft + airmen + validity inquiries + DMS designee locator + CARES Phase 2 consolidation target | RMS, DMS, CARES | **P1** — unblocks PDR phase-out (RMS FR-4.5) | Medium — near-real-time refresh, SORN-aware field filtering |
| **Person / Airman Master Record ("Golden Record")** (unified identity, FTN as keystone, canonical profile fields with per-system extensions) | RMS CAIS + MSS applicant/MID + IACRA FTN profile + DMS designee profile + CARES registrant | All 5 | **P0** — enables retiring DIWS/MSS demographic sync (RMS FR-5.7) | High — reconciliation of 5 existing identity graphs, SSN removal in flight |
| **Shared Audit / Compliance Logging** (tamper-evident, NIST 800-53 AU family, SORN-aware access logs) | RMS audit (FR-6.5) + MSS HIGH audit (FR-6.9) + IACRA auth/access logs + DMS/CARES audit | All 5 | **P1** | Medium — FIPS-HIGH (MSS) boundary requires careful scoping |
| **Retention / Records Disposition Engine** (NARA schedule per record class, legal hold, destruction audit) | RMS 60yr/Permanent/5yr/6mo + MSS 50yr + IACRA temp + DMS 25yr + CARES Permanent | All 5 | **P2** | Medium — schedule drift across systems today; SCS/NARA standardization required |
| **Shared Test-Results API** (knowledge + practical test ingest, FTN-keyed) | IACRA Atlas SQL-linked-server + DMS ATLAS outbound + CARES Phase 2 | IACRA, DMS, CARES | **P1** — retires SQL-linked-server risk (FR-IACRA-4.1) | Low — well-scoped integration |
| **Digital Signature Service (DocuSign adapter)** | CARES DocuSign + IACRA CO digital sig + DMS CLOA sig + MSS AME disposition | CARES, IACRA, DMS, MSS | **P2** | Low — already proven at CARES |

---

## 3. Integration Anti-Pattern Inventory

Every current integration, mapped to the pattern it uses, the risk profile, and the target replacement. Most modernization gains come from replacing TIFF/FTP, SQL-linked-server, and batch reconciliation with authenticated event-driven APIs.

| From | To | Current Pattern | Risk | Target Pattern |
|---|---|---|---|---|
| IACRA | CAIS (RMS) | TIFF images over secure FTP | High — no structured data, no schema validation, FTP plaintext control-plane, lossy rendering | Authenticated REST API with structured airman records (IACRA FR-6.1/7.1, RMS FR-5.1) |
| IACRA | Atlas Aviation (knowledge test) | SQL Server linked-server connection | High — cross-vendor direct DB binding, brittle schema coupling, authZ bypass risk | REST API keyed by FTN (IACRA FR-4.1/7.8) |
| AVS eForms | RMS/CAIS | FTP-delivered Form 337 data | High — same as IACRA TIFF/FTP | Authenticated API with schema validation (RMS FR-5.4) |
| IACRA / applicants | IACRA public auth | Email-delivered 6-digit MFA code (30-day trust) | Medium–High — fails NIST 800-63B AAL2 (phishable) | Login.gov AAL2 (IACRA FR-1.4/8.5; MSS FR-1.16/5.6 as precedent) |
| DMS | FAA internal | IWA / Active Directory | Medium — pre-zero-trust, directory coupling | Zero-trust identity via MyAccess (DMS FR-8.7) |
| MSS | NDR (National Driver Register) | Encrypted file comparison exchange | Medium — batch, no real-time anomaly signal | Preserve encrypted exchange; event-stream anomaly notifications (MSS FR-5.2/5.7) |
| MSS ↔ CAIS (RMS) | Demographic sync | Batch reconciliation | Medium — drift between MSS and CAIS airman records | Event-driven identity service (RMS FR-5.7; MSS FR-5.1/5.7) |
| MSS ↔ DMS | AME metrics + profile sync | Bidirectional point-to-point | Medium — FIPS-HIGH boundary bleeds into DMS | DMS as designee master; MSS as read-only consumer (DMS FR-7.7; MSS FR-5.3) |
| IACRA ↔ DMS | Test/checkride activity | Bidirectional point-to-point | Medium | Shared test-results API + DMS-as-master (DMS FR-7.3, 7.7) |
| Any system | Pay.gov | Multiple parallel integrations | Low–Medium — each system maintains Treasury cert | CARES as single Pay.gov broker (CARES FR-4.6/7.2/7.6) |
| CARES ↔ RMS/CAIS | Phase 1 handoff | Dual-run sync (handover of finalized records) | High — 4-year extended dual-run makes this steady-state | First-class adapters with SLAs (CARES FR-7.4/7.7) |
| RMS | USAS Portal | One-time prepopulation exchange | Low | Authenticated API under CARES if bidirectional needed (RMS FR-5.3) |
| MSS | Aviator (ATCS onboarding) | Point-to-point transmission of clearance | Low–Medium — minimum-necessary controls must hold | Event-driven clearance-granted event (MSS FR-4.4/5.4/5.7) |
| All systems | Their own audit logs | Independent audit stores | Medium — no cross-system correlation for LEAP/FOIA | Shared audit service with tenant scoping |
| RMS | LEAP (law enforcement) | Inquiry surface (implicit) | Low | Preserve via unified public inquiry + authZ-gated detailed lookup (RMS FR-2.7, 4.6) |

---

## 4. Identifier Unification Map

Today each system invents its own identity key. A modernized platform needs one canonical identity model for persons (airmen, applicants, designees, registrants) and one for aircraft, with system-specific aliases mapped through a person-master resolver.

| Current Identifier | System | Purpose | Target |
|---|---|---|---|
| **Certificate Number** (legacy = SSN for pre-reform airmen) | RMS / CAIS | Airman identity across certification/medical records | FTN-keyed with certificate number as display alias (RMS FR-2.3 retires SSN form) |
| **FTN (FAA Tracking Number)** | IACRA (primary), DMS, CARES Phase 2 | Stable airman identifier across systems | **Canonical person ID for airmen** (IACRA FR-1.2, CARES FR-5.8) |
| **Applicant ID** | MedXPress/MSS | Applicant account in MedXPress | Merge into FTN on MSS ↔ CARES federation |
| **MID** (Medical ID) | MSS | Medical case identifier | Preserve as medical-domain alias; bind to FTN |
| **AME Serial Number** | MSS / DMS | AME designee identifier | Alias for Designee Number when AME |
| **Designee Number** (9-digit) | DMS | Unique designee identifier | Canonical designee ID in DMS; person-master link via FTN |
| **Confirmation Number** | MedXPress | Hand-off token to AME | Short-lived transaction token, not identity |
| **Pseudo-SSN** | MedXPress (if SSN withheld) | De-duplication when SSN absent | Eliminated by FTN + Login.gov proofed identity |
| **SSN** | MSS (voluntary), IACRA (optional), RMS (legacy) | Identity + de-dup | Collected only per Privacy Act statement; never the key (RMS FR-2.3) |
| **N-number** | RMS / CARES | Aircraft identifier | Preserved — canonical aircraft ID |
| **Aircraft Serial Number** | RMS / CARES | Aircraft unique mfr ID | Preserved — canonical aircraft attribute |
| **MyAccess subject ID** | CARES | Federated identity subject | Bound to person master (airman/registrant/designee) |
| **Login.gov sub** | MSS (Aug 2025), future IACRA/DMS | Federated identity subject | Bound to person master |
| **PIV subject DN** | All systems (FAA users) | Internal staff identity | Bound to person master via MyAccess |

**Target unification:** one **Person** (with FTN as keystone), one **Aircraft** (N-number + serial), with system-scoped aliases and a resolver service.

---

## 5. Data Overlap Matrix

Which data elements are stored in multiple systems. The "System of Record" column names the target authoritative store for the modernized platform.

| Data Element | RMS / CAIS | IACRA | MedXPress/MSS | DMS | CARES | System of Record (Target) |
|---|---|---|---|---|---|---|
| **Full legal name** | ✓ (airman + aircraft owner) | ✓ | ✓ | ✓ | ✓ | Person master (CARES/MyAccess-backed) |
| **Date of birth** | ✓ | ✓ | ✓ | ✓ | — | Person master |
| **SSN** | ✓ (legacy) | ✓ (optional) | ✓ (voluntary / pseudo) | — | — | Person master — collected per Privacy Act; never a key |
| **Mailing + physical address** | ✓ | ✓ | ✓ | ✓ | ✓ | Person master with per-system use |
| **Phone** | ✓ | ✓ | ✓ | ✓ | ✓ | Person master |
| **Email** | ✓ | ✓ | ✓ | ✓ | ✓ | Person master + Login.gov / MyAccess |
| **Citizenship / country** | ✓ | ✓ | ✓ | ✓ | ✓ | Person master |
| **Sex, height, weight, hair, eye** | ✓ (airman cert) | ✓ | ✓ | ✓ (gender) | — | Person master (physical descriptors) |
| **Certificate number (airman)** | ✓ (authoritative) | ✓ | ✓ | ✓ | ✓ (Phase 2) | CAIS → CARES airmen registry |
| **Certificate class / level / ratings** | ✓ (authoritative) | ✓ | ✓ (medical class) | ✓ (airman cert #) | ✓ (Phase 2) | CAIS → CARES airmen registry |
| **Medical certificate reference** | ✓ | ✓ (optional ref) | ✓ (authoritative) | — | ✓ (Phase 2) | MSS (medical registry) |
| **Medical history (Form 8500-8)** | — | — | ✓ | — | — | MSS (SORN 856) — single-domain |
| **FTN** | (derived) | ✓ (authoritative) | — | ✓ | ✓ | Person master |
| **N-number / aircraft** | ✓ (authoritative) | — | — | — | ✓ | CAIS → CARES aircraft registry |
| **Aircraft make/model/serial** | ✓ | — | — | — | ✓ | CAIS → CARES aircraft registry |
| **Ownership / chain-of-title** | ✓ (14 CFR Part 49) | — | — | — | ✓ | CAIS → CARES aircraft registry |
| **Security agreements / liens** | ✓ | — | — | — | (Phase 1 intake) | CAIS → CARES |
| **Designee profile + CLOA** | — | — | (AME metrics consumer) | ✓ (authoritative) | — | DMS |
| **Flight hours / aviation experience** | ✓ (cert history) | ✓ (authoritative at app) | ✓ (on 8500-8) | — | ✓ (Phase 2) | CAIS → CARES airmen registry |
| **Drug/alcohol declarations (§20, DUI)** | ✓ (enforcement) | ✓ | ✓ | — | ✓ (Phase 2) | Collected per domain; consolidated airman record in CARES Phase 2 |
| **Training / course completion** | — | — | — | ✓ (designee training) | — | DMS (designee) + Blackboard/eLMS (delivery) |
| **Payment transaction ID** | ✓ (Pay.gov) | — | — | ✓ (Pay.gov) | ✓ (Pay.gov) | Pay.gov; local transaction-ID reference only |
| **Security question answers** | — | — | ✓ (legacy) | ✓ (legacy) | — | Retired on Login.gov/MyAccess migration |
| **Photo ID / identity document** | — | ✓ | — | ✓ (optional photo) | ✓ (proofing) | MyAccess identity-proofing ledger |

---

## 6. Rationalization Priority Matrix

Ordered by value × feasibility. Value = # systems consolidated × risk removed × unblocking effect on CARES Phase 1/2. Feasibility = timeline alignment with CARES FOC Fall 2027, ATO boundary movement, and regulatory constraint.

| Priority | Action | Systems | Impact | Effort | Dependencies |
|---|---|---|---|---|---|
| **P0 — 1** | Unified Identity Service (Login.gov + MyAccess federation, retire local stores and IWA/AD) | MSS, IACRA, DMS, CARES, RMS (consumer) | Retires 4 local credential stores; closes IACRA AAL2 gap; enables zero-trust for DMS; pre-req for every other shared service | M (MSS proven Aug 2025; DMS pending; IACRA needs plan) | FR-MSS-5.6, FR-IACRA-1.4/8.5, FR-DMS-8.6/8.7, FR-CARES-2.1 |
| **P0 — 2** | CARES as single Pay.gov broker | RMS, DMS, CARES, IACRA (Phase 2) | One Treasury integration; retires 3 parallel integrations | L (Pay.gov stable; mostly wiring) | FR-CARES-4.6/7.2 |
| **P0 — 3** | Person Master Record (FTN as keystone) + System-of-Record map | All 5 | Eliminates data drift between CAIS/MSS/DMS/CARES/IACRA; enables public-inquiry unification | H (reconciles 5 identity graphs; SSN removal in flight; SORN nuance) | Identity service (P0-1); RMS FR-2.3/5.7, MSS FR-5.1 |
| **P0 — 4** | Shared Document Service (with PDF/A + OCR; DocuSign) | All 5 | Retires TIFF/FTP (IACRA→CAIS, AVS→RMS); lifts 25-doc/3 MB ceiling; shared taxonomy | H (NARA schedule variance; legal chain-of-custody; 174M TIFF corpus) | FR-RMS-3.x, FR-MSS-3.7, FR-IACRA-6.1/7.1, FR-CARES-3.6 |
| **P1 — 5** | Unified Public Inquiry API (aircraft, airmen, designee, cert validity) + near-real-time refresh | RMS, DMS, CARES | Unblocks PDR phase-out (RMS FR-4.5); one SORN-aware disclosure engine | M | FR-RMS-4.1/4.5/6.3, FR-DMS-6.x, FR-CARES-6.x |
| **P1 — 6** | Shared Test-Results API | IACRA, DMS, CARES | Retires SQL-linked-server risk (IACRA → Atlas) | L | FR-IACRA-4.1/7.8 |
| **P1 — 7** | Shared Audit / Compliance Logging | All 5 | Cross-system correlation for LEAP/FOIA; narrow FIPS-HIGH (MSS) boundary | M | Identity service (P0-1) |
| **P1 — 8** | Unified Case / Workflow Engine (form-schema plugins) | All 5 | Consolidates workflow logic from 5 systems; enables new forms without rebuild | H (plugin boundary discipline; each domain has distinct rules) | Identity (P0-1), Documents (P0-4) |
| **P2 — 9** | Shared Notification / Correspondence Service | All 5 | Template reuse; multi-channel delivery | M | Workflow engine (P1-8) |
| **P2 — 10** | Retention / Records Disposition Engine | All 5 | Standardizes NARA schedule enforcement (60yr/50yr/25yr/5yr/Permanent/temp) | M | Document service (P0-4) |
| **P2 — 11** | First-class adapters CARES↔RMS/CAIS, CARES↔IACRA with SLAs | CARES, RMS, IACRA | Engineers the 4-year dual-run as steady-state | M | Identity (P0-1); Schema freeze on Phase 2 |
| **P2 — 12** | Digital Signature Service (DocuSign adapter) | CARES, IACRA, DMS, MSS | Standardizes on one signature capture path | L | Document service (P0-4) |
| **P3 — 13** | MSS event-stream publication (case-submitted, AME-performance-updated, clearance-granted) | MSS, DMS, Aviator, CAIS | Retires 5 MSS point-to-point integrations; shrinks FIPS-HIGH boundary | M | MSS FR-5.7 |
| **P3 — 14** | DMS as designee master (MSS AME sync → read-only) | DMS, MSS | Ends bidirectional sync coupling | L | DMS FR-7.7 |

---

## Cross-Cutting Notes

- **Section 546 mandate (Fall 2027 FOC)** makes CARES the load-bearing platform — every P0 shared service either lives in CARES or is consumed by it.
- **Dual-run is steady-state for 4+ years** (Phase 1 FOC slipped Fall 2023 → Fall 2027). Adapters (P2-11) need first-class SLAs, not afterthought glue.
- **FIPS-HIGH containment (MSS)** is a first-class boundary concern. Shared services (audit, documents, identity) must scope the high-impact perimeter tightly or each new integration widens the MSS ATO boundary.
- **TIFF/FTP + SQL-linked-server** are the two defining legacy integration patterns. Retiring them (P0-4, P1-6) is the single largest modernization lever.
- **Retention schedules differ by 12x** across systems (6 months to Permanent). A retention engine (P2-10) is required to avoid divergent NARA posture.
- **Two systems still use security questions + local passwords** (DMS, IACRA). Login.gov adoption (P0-1) is the prerequisite for collapsing these to one auth model.
