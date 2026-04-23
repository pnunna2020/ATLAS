# FAA AVS Portfolio — User Profiles, Current-State Journeys, and Rationalized Journeys

**Scope:** RMS, MedXPress/AMCS/MSS, IACRA, DMS, CARES (with DIWS/CPDSS, CAIS, Pay.gov, Login.gov/MyAccess, Atlas Aviation as supporting systems)
**Date:** 2026-04-23
**Companion docs:** `requirements-traceability-matrix.md`, `integration-map.md`, `{system}/detailed-requirements-from-guides.md`

This document translates the system-level findings in the traceability matrix into the people who actually live in these systems. It catalogs the 14 personas that touch the portfolio, walks the end-to-end journeys they take today (with the pain points surfaced in the user manuals and requirements docs), and then re-draws those same journeys against the ATLAS rationalized target-state (unified identity, shared document service, unified case/workflow engine, event-driven integration). Every rationalization claim in Section 3 is backed by a specific shared-service row in the traceability matrix.

---

## 1. User Profiles (Personas)

### External Users (Applicants / Public)

#### P1 — Student Pilot Applicant (First-Time Airman)
- **Description:** Adult/student U.S. citizen applying for a first FAA airman certificate (Private, Sport, or Recreational Pilot). Has no FTN, no medical on file, no prior FAA interactions.
- **Systems touched:** MedXPress (8500-8 application) → AMCS (AME indirectly) → DIWS (medical record, indirect) → IACRA (Form 8710-1, knowledge test link, practical test) → CAIS (final airman cert record, indirect) → Atlas Aviation (knowledge test vendor).
- **Frequency:** Once for each certificate level; typically 3–6 months of continuous touchpoints.
- **Pain points (current state):**
  - Must create **two separate accounts** with different usernames/passwords: MedXPress (3 security questions) and IACRA (2 security questions + email-MFA 6-digit code).
  - MedXPress account expires after 60 days of inactivity without a medical on file (MSS §1.x).
  - Must hand-carry a MedXPress confirmation-number printout to the AME office; nothing in IACRA knows the medical exists until DIWS syncs.
  - Knowledge test result flow from Atlas Aviation into IACRA is via SQL-linked-server — status visibility to the applicant is delayed.
  - Has to re-key identity fields (name, address, DOB) in MedXPress and again in IACRA.
  - No mobile-first experience; IACRA has a 1024×768-era UI.
  - No single "where am I in the process" dashboard.
- **What the modernized system must give them:**
  - One identity (Login.gov) across all FAA portals.
  - One address/phone/name profile that propagates to every downstream workflow.
  - A personalized "Certification Path" dashboard showing every remaining step.
  - Real-time status on medical, knowledge test, practical test, and certificate issuance.
  - Mobile app parity for non-examination tasks (status checks, documents, notifications).

#### P2 — Experienced Pilot (Cert Upgrade / Renewal)
- **Description:** Existing airman adding a rating (Instrument, Commercial, ATP), renewing a CFI, or replacing a lost certificate. Has an FTN, an existing DIWS medical record, and (likely) a MedXPress account from a prior cycle.
- **Systems touched:** MedXPress (renewal 8500-8) → AMCS → DIWS → IACRA (rating application or FIRC renewal) → CAIS (airmen lookup), occasionally Airmen Online Services (address change, cert replacement).
- **Frequency:** Every 1–5 years depending on medical class + CFI renewal (every 24 months) + rating additions.
- **Pain points (current state):**
  - Duplicate data entry across MedXPress and IACRA each cycle.
  - MedXPress password/account often forgotten between uses (60-day inactivity expiry).
  - Address change under §61.60 must be filed in multiple places (IACRA, airmen services, MedXPress self-captured field).
  - Form 8710-1 in IACRA requires re-entering currency data that FAA already has.
  - Knowledge-test retake results flow through legacy SQL linked server with no applicant-side status.
- **What the modernized system must give them:**
  - Pre-fill from the Person Master Record; edit-in-place for changed fields only.
  - "My certificates" view with expiration dates, renewal calendar, and one-click renewal flows.
  - A single §61.60 address-change action that propagates to every domain.

#### P3 — Aircraft Owner (Individual or LLC)
- **Description:** Private individual, trust, partnership, or LLC registering, renewing, or transferring ownership of an aircraft.
- **Systems touched:** CARES (registration, bill of sale, renewal, transfer, N-number reservation) → RMS/CAIS (until CARES Phase 2 airman integration) → DocuSign → Pay.gov → TSA NTSDB (vetting).
- **Frequency:** Registration once at purchase, renewal every 3 years (new rule), transfer on sale, N-number changes ad hoc.
- **Pain points (current state):**
  - During the 4-year CARES/RMS dual-run, identical records exist in both; applicants occasionally see inconsistent status.
  - Renewal notice timing has historically lagged; certificate-pending-cancellation confusion.
  - Legal documents (trust instrument, LLC formation, POA) must be uploaded as PDFs that the Registry later scans into TIFF for CAIS — lossy and wastes time.
  - No structured status tracking for "I mailed paperwork, is it in?" during RMS paper-intake paths.
- **What the modernized system must give them:**
  - A single aircraft-registration workflow in CARES, no RMS round-trip.
  - PDF/A-native document capture (no TIFF degradation).
  - Real-time status, push notifications on state changes, DocuSign round-trip inside the portal.

#### P4 — Remote Pilot (Part 107)
- **Description:** sUAS / drone operator seeking Remote Pilot Certificate with sUAS Rating. Simplest airman path — no medical, no practical test, just a knowledge test.
- **Systems touched:** IACRA (Form 8710-13) → Atlas Aviation (knowledge test) → CAIS (airmen cert record).
- **Frequency:** Initial cert + recurrent training every 24 months (FAA online recurrent, not a test since 2021).
- **Pain points (current state):**
  - IACRA account creation friction is disproportionate to the simplicity of the task.
  - No medical → no MedXPress, so the duplicate-account pain is smaller, but IACRA email-MFA still fails AAL2.
  - Knowledge test result visibility still gated by SQL-linked-server sync.
- **What the modernized system must give them:**
  - Fastest path — a streamlined "Part 107" flow that skips medical, skips practical.
  - Mobile-first cert download and display (drone operators are often in the field).

#### P5 — Mechanic / Parachute Rigger / Other Non-Pilot Airman
- **Description:** Applicants for A&P Mechanic, Inspection Authorization (IA), Parachute Rigger, or Dispatcher certificates.
- **Systems touched:** IACRA (Forms 8610-2, 8610-3, 8710-1 variants) → Atlas Aviation → CAIS → occasionally DMS (as DME Examiner scenario differs; here they are applicant-only).
- **Frequency:** Initial cert, then rating add-ons (e.g., IA every 2 years).
- **Pain points (current state):**
  - Same duplicate-account story (IACRA only; no MedXPress for most paths).
  - Limited non-pilot path awareness in the existing IACRA UI — flows are pilot-first and non-pilot applicants report confusion.
- **What the modernized system must give them:**
  - Role-based dashboards that tailor the certification path (not one-size-fits-pilot).
  - Rating-addition flows that pre-populate from existing cert data.

#### P6 — ATCS Candidate (Air Traffic Control Specialist)
- **Description:** Candidate for FAA ATC employment (Academy entry or Collegiate Training Initiative). Requires a Class II medical cleared via the specialist ATCS path.
- **Systems touched:** MedXPress → AMCS (AME) → DIWS → CPDSS (ATCS clearance scoring) → Aviator (HR onboarding handoff).
- **Frequency:** Once at hire + periodic renewal per FAA Order.
- **Pain points (current state):**
  - ATCS path has distinct rules (vision, psychiatric, substance) and flows through CPDSS with no applicant visibility.
  - Clearance handoff to Aviator is point-to-point with minimum-necessary controls that are painful to test.
  - Results/status latency can delay start dates.
- **What the modernized system must give them:**
  - A candidate-visible status queue with realistic ETAs ("Your ATCS clearance is with the Regional Flight Surgeon").
  - Event-driven handoff to Aviator so start-date coordination is not gated by batch.

### Designated Representatives

#### P7 — Aviation Medical Examiner (AME)
- **Description:** Physician designated by the FAM (Federal Air Surgeon) to conduct Airman Medical Examinations. Runs a medical practice and sees 5–50 airman applicants per month.
- **Systems touched:** Login.gov / MyAccess → AMCS (application import, exam entry, document upload, disposition) → DIWS (case history, denial review context) → DMS (designee oversight/metrics, read-only today from MSS).
- **Frequency:** Heavy daily use — AMCS is their primary clinical record system for FAA work.
- **Pain points (current state):**
  - **20-minute hard session timeout** with 15-minute warning — disruptive during long exams; unsaved page-level data is lost.
  - **90-day staff validation cycle:** AMEs must re-validate every staff account every 90 days, otherwise AMCS becomes inaccessible for that staff member with a generic "not authorized" message.
  - AME Guide (2026, 882 pages) carries 60+ disposition tables that are manually cross-referenced; not embedded in AMCS UI.
  - Document upload limits (3 MB per doc, 25-doc ceiling) and 30+ document-type taxonomy — cumbersome for complex special-issuance cases.
  - Pop-up blockers must be disabled; UI assumes 1024×768 resolution.
  - AMCS doesn't talk directly to DMS — AME oversight metrics flow via batch sync (MSS→DMS), so corrective-action context is always slightly stale.
- **What the modernized system must give them:**
  - Clinical decision support — disposition tables embedded contextually next to the finding.
  - Larger, more document-types, PDF/A-native uploads.
  - Responsive UI; no session timeouts on data-entry screens with auto-save.
  - A single unified "my AME work" view (exams, documents, oversight, corrective actions, CE requirements).

#### P8 — Designated Pilot Examiner (DPE)
- **Description:** Designated examiner authorized to administer practical (checkride) tests. Appointed by FAA; oversight by a Managing Specialist (MS).
- **Systems touched:** DMS (CLOA, applications, pre-approvals, post-activity reports, annual extension, corrective action response, LOIs) → IACRA (acts as Certifying Officer during practical test) → occasionally Airmen Online Services.
- **Frequency:** Varies by region/demand; active DPEs conduct 5–30 checkrides/month plus administrative DMS touchpoints.
- **Pain points (current state):**
  - **Lives in two systems:** pre-approval (Pre-ACR) in DMS, then must switch to IACRA to actually record the practical test result as Certifying Officer, then switch back to DMS for the post-activity report.
  - DMS → IACRA and IACRA → DMS handoffs are bidirectional point-to-point integrations with known sync drift.
  - DMS external user manual is 110 pages — the UX carries its complexity onto the user.
  - CLOA authorizations (function codes + limitations) are PDF artifacts, not queryable — DPE must read the CLOA to know what they can and can't do.
  - 180-day suspension-release window is calendar-driven with no proactive reminders.
  - Post-activity report submission is a separate session per checkride rather than a natural continuation of the IACRA practical test entry.
- **What the modernized system must give them:**
  - **One session, one tool:** pre-approval → checkride → post-activity report is a single linear flow.
  - Structured, queryable authorizations (not PDF CLOAs).
  - Pre-populated post-activity reports from the practical test record.

#### P9 — Training Center Evaluator (TCE)
- **Description:** Part 142 training-center representative who administers evaluations and issues certificates under a center's FAA-approved program. Often acts as a company-admin role for other 142 staff.
- **Systems touched:** DMS (evaluator designation + company admin validation workflow for School Administrators, §2.5) → IACRA (certifying officer role on applications + validating School Administrators). May also validate Chief / Assistant Chief Flight Instructors.
- **Frequency:** Continuous (multiple evaluations per week) + periodic admin work (quarterly or per-hire).
- **Pain points (current state):**
  - Dual-system company administration: School Administrator activation can require an FAA NSD phone call *or* IACRA validation by an ACR/TCE — different channels for the same goal.
  - Chief/Assistant Chief Flight Instructor NVIS nomenclature mismatches cause activation delays with no self-service correction.
  - TCE role semantically can act as either RI or CO on a given application — users report mode-switching confusion.
- **What the modernized system must give them:**
  - Single company-admin dashboard spanning 141/142 staff onboarding, with inline name-match resolution.
  - Clear role-mode indicator and switch UX.

#### P10 — Designated Engineering Representative (DER)
- **Description:** Designated engineer authorized to approve/recommend approval of engineering data on behalf of the FAA (AIR domain). Works primarily within DMS.
- **Systems touched:** DMS (designation, oversight, post-activity reports, annual extension) → no direct IACRA or MedXPress touch.
- **Frequency:** Project-based; activity reports cluster around certification milestones.
- **Pain points (current state):**
  - DMS UI is pilot-examiner-centric (the 110-page manual focuses on DPEs); DER-specific workflows are buried.
  - Same CLOA-as-PDF and corrective-action opacity as DPEs.
- **What the modernized system must give them:**
  - Designee-type-aware dashboards and forms (DER, DAR, DMIR, DPE, ACR, TCE, FIRE, APD each see their tailored UI).
  - Structured authorization data.

### FAA Internal Users

#### P11 — Aviation Safety Inspector / Technician (ASI/AST)
- **Description:** FAA-employed inspector (FS or AIR). Oversight role over applicants and designees; can act as Certifying Officer in IACRA; manages Air Carrier Flight Instructor authorizations.
- **Systems touched:** IACRA (CO + designee oversight) → DMS (designee oversight from the FAA side as MS or support) → SAS (Safety Assurance System, inspection workflows) → Airmen Online Services.
- **Frequency:** Daily.
- **Pain points (current state):**
  - Multiple PIV logins across IACRA (via MyAccess), DMS (via IWA/AD, zero-trust migration pending), SAS, and airmen services.
  - Cross-system case context must be assembled manually — no unified case view across an applicant's IACRA application, DMS-related designee involvement, and medical status.
  - "Manage Air Carrier Flight Instructors" in IACRA is a separate screen from the rest of the role-management UI.
- **What the modernized system must give them:**
  - Single PIV-through-MyAccess (traceability matrix P0 recommendation).
  - Cross-domain person/designee view.
  - Unified case/workflow inbox across all AVS domains.

#### P12 — Registry Examiner (Aircraft or Airmen)
- **Description:** FAA Registry staff (AVP-200, AFS-760) who adjudicate registration applications, airmen records, paper-intake scanning, and correspondence.
- **Systems touched:** RMS / CAIS (airmen + aircraft record stores) → incoming TIFF work packets from IACRA (airman cert issuance) and AVS eForms (Form 337) → Pay.gov (for the $5 fee) → outgoing correspondence.
- **Frequency:** Daily, queue-driven.
- **Pain points (current state):**
  - **TIFF-over-FTP** inbound from IACRA is the defining pain point — no structured data, lossy rendering, FTP plaintext control-plane.
  - Paper intake still dominant for aircraft registrations that don't go through CARES; scanning backlog produces latency visible to applicants.
  - Separate record systems for airmen (CAIS) and aircraft, even though both go through the same Registry office.
  - Retention rules differ (60yr airmen, Permanent aircraft, 5yr EIS, 6mo foreign) and are enforced manually per record class.
- **What the modernized system must give them:**
  - Structured REST API inbound from IACRA and CARES (no TIFF, no FTP).
  - PDF/A + OCR as the imaging default, with automated retention.
  - A unified public-inquiry / examiner-lookup surface.

#### P13 — FAA Flight Surgeon (Regional or FAM / AAM)
- **Description:** FAA physician who reviews deferred medical exams, adverse dispositions, and special issuance cases. Part of AAM (Office of Aerospace Medicine) organizational review chain.
- **Systems touched:** DIWS (medical record and case history, authoritative store) → CPDSS (ATCS clearance scoring) → indirectly AMCS and MSS for context on submitted exams → correspondence to applicants.
- **Frequency:** Daily, queue-driven.
- **Pain points (current state):**
  - DIWS is a FIPS-HIGH enclave; pulling cross-system context (applicant history in IACRA, prior registration for ATCS) requires separate logins and manual stitching.
  - Approval/denial letter generation is system-specific (MSS §3.3) and not unified with IACRA status notifications.
  - Queue management (CAMI / RFS / HQ) in MSS has 8 application status values that don't fully align with downstream tracking in DIWS.
- **What the modernized system must give them:**
  - FIPS-HIGH-aware unified case view (MSS data in an AAM-scoped partition, still viewable alongside IACRA airman history under appropriate access).
  - Shared correspondence/notification service with medical-specific templates.
  - Common case-history event log so the reviewer sees the full narrative in one place.

#### P14 — Managing Specialist (MS) / Appointing Official (AO)
- **Description:** FAA oversight role attached to every designee in DMS. Appoints, evaluates, suspends, reinstates, terminates designees; issues LOIs, corrective actions, CLOAs.
- **Systems touched:** DMS (primary) → MSS (indirectly, for AME oversight metrics sync into DMS) → IACRA (designee test-activity data).
- **Frequency:** Daily.
- **Pain points (current state):**
  - DMS designee-master claim is aspirational; point-to-point syncs from MSS and IACRA mean the MS sees stale oversight metrics during high-volume periods.
  - Corrective-action and LOI letter generation is local to DMS; no shared templating with IACRA/MSS.
  - Suspension release (180-day window) and annual extension timing require manual tickler-file management.
- **What the modernized system must give them:**
  - DMS as unambiguous designee master (traceability matrix recommendation FR-DMS-7.7).
  - Proactive timeline-management (suspension releases, annual extensions, CE requirements).
  - Shared correspondence/notification service for LOIs, corrective actions, and AO concurrences.

---

## 2. Current-State User Journeys (AS-IS)

Each journey is a step-by-step flow. The tag after each step indicates the system the user is in. ⚠️ flags a pain point. 🔄 flags a cross-system handoff or integration discontinuity.

### Journey 1 — First-Time Pilot Certification (P1)

**Goal:** "I want to become a Private Pilot" → physical certificate in hand.

| # | Step | System | Friction |
|---|------|--------|----------|
| 1 | Decide to pursue certificate; research requirements on faa.gov and third-party pilot blogs | External web | — |
| 2 | Create MedXPress account (username, password, 3 security questions, email) | MedXPress | ⚠️ First of two portals with separate credentials (MSS FR-1.1) |
| 3 | Complete Form 8500-8 online: identity, medical history, medications, visual/hearing, substance history | MedXPress | ⚠️ 60-day auto-delete if not submitted (MSS FR-1.13) |
| 4 | Submit; receive confirmation number and summary sheet; **print and hand-carry to AME** | MedXPress | ⚠️ Paper step |
| 5 | Find and schedule AME appointment (external directory search) | External | — |
| 6 | Visit AME office; AME imports application into AMCS using confirmation number | AMCS (AME) | 🔄 Handoff #1: MedXPress → AMCS (same data, different system) |
| 7 | AME conducts physical exam; enters findings, dispositions (60+ tables in AME Guide); uploads supporting documents (max 3 MB each, 25 per exam) | AMCS | ⚠️ Document limits (MSS FR-2.10–2.13) |
| 8 | AME signs and transmits to DIWS; case enters CAMI/RFS/HQ queue as appropriate | DIWS | 🔄 Handoff #2: AMCS → DIWS |
| 9 | Applicant waits for medical certificate; status (1 of 8 values) visible in MedXPress but not elsewhere | MedXPress | ⚠️ No cross-portal status; no push notification |
| 10 | Medical certificate issued (paper-mailed or digitally delivered depending on class); airman confirmed in DIWS | DIWS / mail | — |
| 11 | Separately, create **IACRA account**: different username, different password, 2 security questions, email-delivered 6-digit MFA code (30-day trust) | IACRA | ⚠️ Second portal, second credential set (IACRA FR-1.1/1.3/1.4; AAL2 gap per traceability matrix) |
| 12 | Receive FTN (FAA Tracking Number) on IACRA registration | IACRA | — |
| 13 | Re-enter personal info (name, address, DOB, contact) that MedXPress already has | IACRA | ⚠️ Duplicate data entry (IACRA FR-1.7, 2.13–2.16) |
| 14 | Study and schedule knowledge test at Atlas Aviation testing center (external vendor) | Atlas Aviation | — |
| 15 | Take knowledge test (PAR — Private Pilot Airplane); result recorded in Atlas Aviation | Atlas Aviation | — |
| 16 | Knowledge test result flows to IACRA via **SQL Server linked-server connection** (nightly/periodic) | IACRA | 🔄 Handoff #3: SQL-linked-server cross-DB binding (high risk, IACRA FR-4.1/7.8) |
| 17 | Train with a CFI; CFI reviews logbook, endorses applicant, recommends in IACRA as Recommending Instructor (RI) — signs Form 8710-1 | IACRA | — |
| 18 | Find a DPE; scheduling coordination outside the system | External | — |
| 19 | **DPE switches from DMS to IACRA** to accept the pre-approval; DPE views the 8710-1 in IACRA | DMS → IACRA | 🔄 Handoff #4: DPE lives across two systems (DMS FR-3.1, IACRA FR-3.1–3.11) |
| 20 | Practical test day: DPE administers oral + flight; enters results in IACRA as Certifying Officer; issues temporary airman certificate | IACRA | — |
| 21 | DPE **switches back to DMS** to file post-activity report | IACRA → DMS | 🔄 Handoff #5: Back to DMS |
| 22 | IACRA generates TIFF image of application + supporting docs and sends to CAIS via **secure FTP** | IACRA → CAIS | 🔄 Handoff #6: TIFF-over-FTP (highest-risk integration, IACRA FR-6.1, RMS FR-5.1) |
| 23 | Registry examiner reviews TIFF packet, adjudicates, writes airman record to CAIS, mails permanent certificate | RMS / Registry | ⚠️ Paper mail for final certificate |
| 24 | Applicant receives plastic certificate 6–8 weeks later | Physical mail | ⚠️ No real-time status; no digital equivalent |

**Totals:** 4 applicant-facing systems (MedXPress, IACRA, Atlas Aviation, airmen services for follow-up), 2 separate accounts (MedXPress + IACRA), 6 integration handoffs (2 are high-risk legacy patterns), 3 paper steps (summary printout, temp cert, permanent cert), typical elapsed time 12–26 weeks.

---

### Journey 2 — Aircraft Registration (P3)

**Goal:** Register a newly purchased aircraft (new registration) OR renew at 3-year boundary OR transfer on sale.

| # | Step | System | Friction |
|---|------|--------|----------|
| 1 | Reserve N-number (optional) | CARES (Phase 1) | ✓ Modernized path |
| 2 | Create MyAccess account (identity-proofed); Login.gov federation where applicable | MyAccess | ✓ Modernized (CARES FR-2.3) |
| 3 | Complete registration application (Form 8050-1 for new, 8050-1B for reregistration); upload bill of sale, LLC/trust formation docs, POA if applicable | CARES | — |
| 4 | DocuSign the application; identity proofing runs | CARES | ✓ Modernized (CARES FR-3.2) |
| 5 | Pay fee via Pay.gov integration in CARES | CARES / Pay.gov | ✓ Modernized (CARES FR-4.x) |
| 6 | TSA NTSDB vetting runs (planned Phase 2 full integration) | CARES → TSA | ⚠️ Phase 2 gap (CARES FR-7.6) |
| 7 | **During Phase 1 dual-run (through ~2029):** record written to CARES AND reconciled against RMS/CAIS via adapter | CARES ↔ RMS | 🔄 4-year dual-run (high-risk steady state, CARES FR-7.4/7.7) |
| 8 | Registry examiner reviews in CARES or RMS depending on which record is authoritative for that transaction | CARES / RMS | ⚠️ Authoritative-record ambiguity during dual-run |
| 9 | Certificate of Registration mailed | Physical mail | ⚠️ No digital cert in Phase 1 |
| 10 | 3 years later: renewal notice sent | RMS correspondence | ⚠️ Historical notice-timing issues |
| 11 | Transfer on sale: new bill of sale, buyer does full new-registration flow; seller notifies within 21 days | CARES | — |

**Totals:** 1 primary system (CARES is already the modernized path), but the 4-year RMS dual-run creates the major handoff complexity, plus 1 physical-mail step.

---

### Journey 3 — AME Conducting an Exam (P7)

**Goal:** AME sees an airman applicant in office, completes the 8500-8 exam, and transmits to DIWS.

| # | Step | System | Friction |
|---|------|--------|----------|
| 1 | Navigate to AMCS login URL; click MyAccess login | AMCS / MyAccess | — |
| 2 | Enter email → password → OKTA code | MyAccess | ✓ MFA via MyAccess |
| 3 | Accept security banner | AMCS | — |
| 4 | AMCS Home Page loads; check Message Center for confirmation-required messages | AMCS | ⚠️ Confirmation-required messages **block all application links** until acknowledged |
| 5 | Click Import Application; enter applicant's MedXPress confirmation number | AMCS | 🔄 Handoff: AMCS pulls from MedXPress/MSS |
| 6 | Verify applicant identity (photo ID check); begin exam page-by-page | AMCS | ⚠️ 20-minute session timeout with 15-min warning (MSS AMCS §1.3) |
| 7 | Enter findings across vision, hearing, BP, urinalysis, mental/substance, cardiovascular, etc.; cross-reference AME Guide disposition tables (paper or separate tab, 882-page PDF) | AMCS + AME Guide | ⚠️ AME Guide not embedded; manual cross-reference |
| 8 | Upload supporting documents (labs, ECG, specialist letters) per 30+ document-type taxonomy; max 3 MB per doc, 25 per exam | AMCS | ⚠️ Document limits (MSS FR-2.13, FR-3.7) |
| 9 | Select disposition (issue, defer, deny); apply any limitations | AMCS | — |
| 10 | Sign and transmit to DIWS | AMCS → DIWS | 🔄 Handoff: AMCS → DIWS |
| 11 | Quarterly: ensure every staff AMCS account is re-validated within 90 days or they lose access | AMCS Admin | ⚠️ 90-day staff-validation cycle (MSS AMCS §1.2) |
| 12 | AME-oversight metrics batch-sync to DMS for MS visibility | MSS → DMS | 🔄 Handoff: bidirectional point-to-point (MSS FR-5.3, DMS FR-7.2) |

**Totals:** 1 primary system (AMCS) but with significant session/admin friction; 2 integration handoffs (DIWS, DMS oversight sync).

---

### Journey 4 — DPE Practical Test (P8)

**Goal:** DPE conducts a checkride and records it end-to-end, from pre-approval to post-activity report.

| # | Step | System | Friction |
|---|------|--------|----------|
| 1 | DPE receives CLOA on appointment — a PDF with function codes + limitations | DMS | ⚠️ Authorizations are PDF, not queryable |
| 2 | Applicant contacts DPE; DPE reviews applicant's 8710-1 readiness | External coordination | — |
| 3 | DPE logs into DMS; navigates to pre-approval request workflow | DMS | — |
| 4 | DPE submits Pre-Approval for the specific checkride activity | DMS | — |
| 5 | MS reviews and approves pre-approval | DMS (MS) | — |
| 6 | Applicant appears for practical test; DPE **switches to IACRA** | DMS → IACRA | 🔄 Handoff #1: DPE context switch |
| 7 | DPE logs into IACRA (separate auth unless same MyAccess session bridges; IACRA FR-1.5/7.7) | IACRA | ⚠️ Potentially second login |
| 8 | DPE reviews 8710-1, CFI recommendation, knowledge test result | IACRA | — |
| 9 | Administers oral + flight; if pass: enters results as Certifying Officer; signs; issues temporary certificate | IACRA | ✓ Core function works |
| 10 | IACRA generates TIFF packet → FTP to CAIS | IACRA → CAIS | 🔄 Handoff #2: TIFF/FTP (legacy) |
| 11 | DPE **switches back to DMS** to file post-activity report (manually re-entering some checkride data) | IACRA → DMS | 🔄 Handoff #3: back to DMS + re-entry |
| 12 | MS oversight / designee metrics updated via IACRA → DMS sync | IACRA → DMS | 🔄 Handoff #4: test activity sync (DMS FR-7.3) |
| 13 | If checkride failed: DPE enters result in IACRA; applicant cannot re-test without additional training; DPE files post-activity report in DMS | IACRA + DMS | — |
| 14 | Annual extension: DPE completes DMS annual extension workflow within window | DMS | ⚠️ No proactive reminders |
| 15 | Corrective action (if any): MS issues LOI in DMS; DPE responds within window | DMS | — |

**Totals:** 2 primary systems, 4 integration handoffs, 1 legacy TIFF/FTP handoff, re-entry of checkride data for the post-activity report.

---

### Journey 5 — Medical Certificate Renewal (P2)

**Goal:** Existing pilot's Class I/II/III medical is expiring; renew before it lapses.

| # | Step | System | Friction |
|---|------|--------|----------|
| 1 | Log into MedXPress (often password-reset because of 60-day inactivity + infrequent use) | MedXPress | ⚠️ Account recovery friction |
| 2 | Start new 8500-8; form pre-fills from prior exam (partial) | MedXPress | ⚠️ Pre-fill is imperfect; re-enter identity/address |
| 3 | Submit; print confirmation | MedXPress | ⚠️ Paper step |
| 4 | Visit AME; AME imports into AMCS using confirmation number | MedXPress → AMCS | 🔄 Handoff |
| 5 | AME conducts exam (often shorter for Class III renewals); transmits to DIWS | AMCS → DIWS | 🔄 Handoff |
| 6 | Certificate issued (often immediately for unremarkable Class III; deferred for I/II or special issuance) | DIWS / mail | — |
| 7 | If deferred: applicant waits; reviewed by Regional Flight Surgeon or AAM HQ | DIWS / CPDSS | ⚠️ Opaque queue |

**Totals:** 2 systems, 2 handoffs, 1 paper step, re-entry of unchanged identity data.

---

### Journey 6 — Designee Annual Lifecycle (P8)

**Goal:** An active DPE navigates a full 12-month designation cycle, from appointment through renewal.

| # | Step | System | Friction |
|---|------|--------|----------|
| 1 | Applicant → Active transition; MS appoints; CLOA auto-generated with function codes + limitations | DMS | — |
| 2 | DPE conducts activities (see Journey 4) — pre-approvals + post-activity reports | DMS + IACRA | 🔄 Per-checkride handoffs |
| 3 | CE (continuing education) requirements tracked; due dates managed manually | DMS | ⚠️ No proactive reminders |
| 4 | Annual extension window opens; DPE submits extension application | DMS | — |
| 5 | MS reviews extension; approves → Active continues, or declines → terminates | DMS | — |
| 6 | If LOI issued: corrective action response required within window | DMS | ⚠️ Timeline manually managed |
| 7 | If suspended: 180-day suspension-release window; DPE submits release request | DMS | ⚠️ No proactive countdown reminder |
| 8 | On release: MS approves → Suspended → Active | DMS | — |
| 9 | Voluntary surrender or termination for cause: Active → Terminated; 1-year reinstatement eligibility | DMS | — |
| 10 | Reinstated (within 1 year): Terminated → Reinstated → Active | DMS | — |

**Totals:** 1 primary system (DMS), but timeline management is manual, and every per-checkride event requires the Journey 4 multi-system dance.

---

## 3. Rationalized User Journeys (TO-BE)

Target-state assumptions (backed by traceability-matrix shared-service rows):
- **Unified Identity Service** (Login.gov for public, MyAccess/PIV for FAA) — replaces 4 local credential stores + IACRA email-MFA AAL2 gap + DMS IWA/AD.
- **Person/Airman Master Record ("Golden Record")** — FTN as the keystone; address/name/contact changes propagate once.
- **Shared Document Service** — PDF/A-native, unified taxonomy, uplifted size limits, DocuSign-integrated signature, NARA-aligned retention.
- **Unified Case/Application Workflow Engine** — form-schema plugins per domain, shared state machine (Draft → Submitted → In Review → Action Required → Decided), shared queues, SLAs.
- **Shared Test-Results API** — replaces IACRA↔Atlas SQL linked server and IACRA↔DMS batch sync.
- **Shared Credential-Issuance Service** — unified cert/number issuance, digital-first delivery.
- **Shared Notification/Correspondence Service** — templated email, push, letter generation.
- **Common Pay.gov Broker** — single CARES-hosted Treasury integration.
- **Single ATLAS Portal** — one URL, mobile-responsive, role-aware dashboards.

### Journey 1 Rationalized — First-Time Pilot Certification

| # | Step | System |
|---|------|--------|
| 1 | Visit ATLAS portal; create Login.gov identity (identity-proofed, AAL2) — one account forever | ATLAS / Login.gov |
| 2 | Dashboard: "Start your Certification Path" — choose Private Pilot; see every step visualized (medical, knowledge, practical, certificate) | ATLAS |
| 3 | Complete Form 8500-8 in ATLAS (shared workflow engine, medical-domain form plugin); personal info pre-populated from Person Master Record | ATLAS |
| 4 | Submit; FTN assigned at identity creation time | ATLAS |
| 5 | Schedule AME from in-portal directory (real-time availability); appointment confirmation + push notification | ATLAS |
| 6 | AME opens the same ATLAS portal (MyAccess PIV), imports exam via shared workflow engine (no separate AMCS login) | ATLAS |
| 7 | AME records findings with **embedded disposition decision support** (AME Guide logic inline); uploads documents via shared document service (larger limits, PDF/A, unified taxonomy) | ATLAS |
| 8 | AME signs digitally via shared DocuSign adapter; transmits to AAM review queue (DIWS-partitioned, FIPS-HIGH preserved) | ATLAS |
| 9 | Applicant sees real-time status on dashboard; push notification on disposition | ATLAS |
| 10 | Medical certificate issued digitally, available in ATLAS wallet | ATLAS |
| 11 | Knowledge test: schedule and see results flow back via shared test-results API (real-time, no SQL-linked-server) | ATLAS ↔ Atlas Aviation |
| 12 | CFI endorses 8710-1 from mobile app — shared signature service | ATLAS |
| 13 | DPE conducts practical test: pre-approval, checkride result entry, and post-activity report are **one linear flow** in ATLAS (no DMS↔IACRA swap) | ATLAS |
| 14 | Certificate issued digitally immediately; DMS designee-oversight metrics updated via event stream (not batch) | ATLAS |
| 15 | Applicant sees cert in ATLAS wallet; plastic card optional (mailed later, not blocking) | ATLAS |

**Totals:** 1 system, 1 account, 0 handoffs (events, not handoffs), 0 paper steps required, ~3–8 weeks elapsed time (gated only by training + scheduling, not system latency).

---

### Journey 2 Rationalized — Aircraft Registration

| # | Step | System |
|---|------|--------|
| 1 | ATLAS portal → Aircraft tab; reserve N-number | ATLAS |
| 2 | New registration: submit bill of sale, formation docs via shared document service (PDF/A, not TIFF); DocuSign inline | ATLAS |
| 3 | TSA NTSDB vetting via shared broker (CARES Phase 2 integration promoted to shared service) | ATLAS ↔ TSA |
| 4 | Pay.gov via common broker | ATLAS |
| 5 | **RMS/CAIS dual-run eliminated** — single authoritative aircraft record in unified registry store | ATLAS |
| 6 | Certificate of Registration issued digitally, plus optional physical card | ATLAS |
| 7 | 3-year renewal: proactive reminder + one-click renewal from wallet | ATLAS |
| 8 | §61.60-equivalent aircraft address change: one action, propagates across domains | ATLAS |

**Totals:** 1 system, 0 dual-run ambiguity, fully digital path.

---

### Journey 3 Rationalized — AME Exam

| # | Step | System |
|---|------|--------|
| 1 | MyAccess PIV login to ATLAS; no MyAccess→AMCS secondary hop | ATLAS |
| 2 | Dashboard: today's appointments, messages (non-blocking notifications), oversight tasks | ATLAS |
| 3 | Click applicant; exam form loads; decision-support panels show disposition guidance contextually | ATLAS |
| 4 | Findings entered with auto-save (no hard 20-minute timeout; continuous session with idle reauth for HIGH data) | ATLAS |
| 5 | Upload documents via shared document service — larger limits, PDF/A, unified taxonomy | ATLAS |
| 6 | Digital signature + transmit; event flows to AAM review queue (FIPS-HIGH-scoped) and to DMS oversight via event stream | ATLAS |
| 7 | Staff-validation: AMEs re-authorize staff through role management; risk-based reminders replace the rigid 90-day cycle | ATLAS |

**Totals:** 1 system, 0 session-timeout disruption, embedded decision support.

---

### Journey 4 Rationalized — DPE Practical Test

| # | Step | System |
|---|------|--------|
| 1 | MyAccess PIV login to ATLAS; role = Designated Pilot Examiner | ATLAS |
| 2 | Dashboard: today's checkrides, pre-approvals pending, CE reminders, timeline widgets (annual extension countdown, CE due dates, LOI response windows) | ATLAS |
| 3 | Click checkride → pre-approval request → MS approves (push notification) — all in one linear workflow | ATLAS |
| 4 | Checkride day: DPE records practical test result (no system swap); temporary cert issued digitally to applicant instantly | ATLAS |
| 5 | Post-activity report pre-populated from practical test record; DPE reviews and submits | ATLAS |
| 6 | Event stream updates DMS-equivalent oversight metrics in real time (no batch) | ATLAS |
| 7 | Authorizations are structured data (function codes + limitations as queryable records), not PDF CLOAs | ATLAS |

**Totals:** 1 system, 0 handoffs, 1 linear flow per checkride, structured authorizations.

---

### Journey 5 Rationalized — Medical Certificate Renewal

| # | Step | System |
|---|------|--------|
| 1 | Push notification 90 days before medical expiry: "Renew your Class III" | ATLAS |
| 2 | Tap notification → ATLAS → 8500-8 renewal form pre-filled from last exam + Person Master Record | ATLAS |
| 3 | Submit from mobile; schedule AME from in-portal directory | ATLAS |
| 4 | AME conducts exam in ATLAS (Journey 3 rationalized) | ATLAS |
| 5 | Digital medical cert issued to ATLAS wallet | ATLAS |
| 6 | If deferred: applicant sees queue position and realistic ETA on dashboard | ATLAS |

**Totals:** 1 system, 0 paper steps, 0 re-entry, mobile-native.

---

### Journey 6 Rationalized — Designee Annual Lifecycle

| # | Step | System |
|---|------|--------|
| 1 | Appointment: Applicant → Active; structured authorizations (not PDF CLOA) issued and rendered in dashboard | ATLAS |
| 2 | Activities (see Journey 4 rationalized): every pre-approval + post-activity-report pair is a single linear flow | ATLAS |
| 3 | CE requirements tracked with proactive reminders (push + email via shared notification service) | ATLAS |
| 4 | Annual-extension window opens: countdown widget on dashboard; 1-click submit when within window | ATLAS |
| 5 | LOI / corrective-action: shared correspondence service delivers structured letter + response form; response window visible | ATLAS |
| 6 | Suspension release: 180-day countdown visible from day 1 of suspension; release-request form pre-populated | ATLAS |
| 7 | Voluntary surrender / termination / reinstatement: state transitions with full audit trail in shared audit service | ATLAS |
| 8 | AME oversight metrics (for MS of AMEs): real-time via event stream from the exam workflow, not batch from MSS | ATLAS |

**Totals:** 1 system, proactive timeline management, structured authorizations, event-driven oversight.

---

## 4. Journey Comparison Matrix

| Metric | Current State | Rationalized | Improvement |
|--------|---------------|--------------|-------------|
| **Systems touched (avg external user journey)** | 4 (MedXPress, IACRA, Atlas Aviation, airmen services) | 1 (ATLAS) + external test vendor via API | −75% |
| **Accounts / credential sets needed** | 2–3 (MedXPress, IACRA, often also MyAccess) | 1 (Login.gov or MyAccess) | −67% |
| **Integration handoffs per journey** | 4–6 per cert journey; 3–4 per designee journey | 0 (replaced by event streams internal to platform) | −100% |
| **TIFF/FTP legacy integrations** | 2 (IACRA→CAIS, AVS eForms→RMS) | 0 | −100% |
| **SQL-linked-server cross-DB bindings** | 1 (IACRA↔Atlas Aviation) | 0 | −100% |
| **Elapsed time (first-time cert)** | 12–26 weeks | 3–8 weeks (gated by training, not system latency) | ~−70% |
| **Paper-mail steps (first-time cert)** | 3 (MedXPress summary, temp cert, permanent cert) | 0 required; physical card optional | −100% |
| **Duplicate identity data entry** | Yes (MedXPress + IACRA + DMS + AMCS + CARES each capture) | No (Person Master Record + propagation) | Eliminated |
| **Real-time cross-domain status** | No (batch syncs, siloed dashboards) | Yes (shared case/workflow engine + event stream) | New capability |
| **Mobile access** | No (IACRA/DMS 1024×768 web UI) | Yes (mobile-responsive + push notifications) | New capability |
| **Proactive timeline management (renewals, CE, suspension release)** | No (manual tickler files) | Yes (shared notification service + countdown widgets) | New capability |
| **Session-timeout disruption (AMEs)** | 20-minute hard timeout with unsaved-data loss | Continuous session + auto-save (risk-based re-auth on HIGH fields) | Eliminated |
| **Document upload limits (AMEs)** | 3 MB/doc, 25 docs, 30+ types with hard ceilings | Shared document service with uplifted limits (MSS FR-3.7) | Capacity increase |
| **Structured designee authorizations** | PDF CLOA (not queryable) | Function codes + limitations as queryable records | Structured data |
| **Public inquiry surfaces** | 3 separate (RMS airmen, RMS aircraft, DMS locator) | 1 unified inquiry API + UI | −67% |
| **Pay.gov integrations** | 3 parallel (RMS, DMS, CARES) | 1 CARES-hosted broker | −67% |
| **AAL2 compliance for public auth** | Gap (IACRA email-MFA is phishable) | Login.gov AAL2 | Compliance restored |

---

## 5. Rationalization Impact Summary by Shared Service

For each shared service from the traceability matrix (§2), this shows which journeys improve and how.

### Unified Identity Service (P0)
- **Journey 1 (First-time pilot):** Eliminates the two-account, two-password ordeal between MedXPress and IACRA; also replaces IACRA email-MFA (AAL2 gap).
- **Journey 2 (Aircraft registration):** CARES already uses MyAccess; adding the aircraft-owner persona to the same identity covers cross-domain users (owner-who-is-also-a-pilot).
- **Journey 3 (AME exam):** Removes the MyAccess → AMCS secondary hop; role claim "AME" is issued once.
- **Journey 4 (DPE checkride):** DPE's one identity covers the old DMS (IWA/AD) + IACRA (MyAccess PIV) split.
- **Journey 5 (Medical renewal):** Eliminates forgotten-password friction on infrequent MedXPress reuse.
- **Journey 6 (Designee lifecycle):** Unified identity underpins structured authorizations and role-aware dashboards.

### Person/Airman Master Record — "Golden Record" (P0)
- **Journeys 1, 2, 5:** §61.60-style address change happens once; propagates to MedXPress-equivalent, IACRA-equivalent, and registration records.
- **Journey 3:** AMEs no longer see mismatched applicant demographics between MedXPress import and DIWS.
- **Journey 6:** DMS-equivalent designee master identity aligns with airman FTN (DPE is often both applicant and designee).

### Shared Document Service (P0)
- **Journey 1:** PDF/A replaces IACRA→CAIS TIFF; applicant-submitted documents never re-rendered lossy.
- **Journey 2:** Bill of sale, LLC/trust docs stored once, readable by Registry, auditable.
- **Journey 3:** AME document limits uplifted; 30+ taxonomy unified; chain-of-custody preserved.
- **Journey 4:** CLOA and post-activity-report documents in one taxonomy.
- **All journeys:** NARA-aligned retention automated.

### Unified Case / Application Workflow Engine (P1)
- **Journey 1:** "Certification Path" dashboard is the shared state machine rendered for the applicant.
- **Journey 4:** Pre-approval → checkride → post-activity report as one linear workflow instance.
- **Journey 5:** Deferred medical appears in the same shared queue engine AAM reviewers already use.
- **Journey 6:** Annual extension, suspension release, corrective action are all workflow-engine instances with shared SLAs.

### Shared Test-Results API (P1)
- **Journey 1:** Real-time knowledge-test result visibility (replaces SQL-linked-server).
- **Journey 4:** DPE checkride activity flows to designee oversight via event stream (replaces IACRA↔DMS batch).

### Shared Credential-Issuance Service
- **Journey 1:** Temporary and permanent certificates issued digitally to ATLAS wallet; plastic card optional and non-blocking.
- **Journey 2:** Certificate of Registration digital-native.
- **Journey 5:** Medical cert digital-native, viewable on mobile.

### Shared Notification / Correspondence Service (P2)
- **Journey 1:** Push notifications on every state change ("knowledge test result posted", "DPE pre-approval granted", "your cert is ready").
- **Journey 2:** 3-year renewal reminder proactive; not dependent on mail.
- **Journey 5:** 90-day expiry reminder drives the renewal.
- **Journey 6:** CE due dates, annual-extension window, LOI response windows, suspension-release countdown all delivered through the same service.

### Common Pay.gov Broker (P0)
- **Journey 1 (Phase 2):** Airman cert fees (if introduced) use same broker.
- **Journey 2:** CARES already uses this; RMS fees collapse into it.
- **Journey 6:** DMS course-fee payment consolidates here.

### Unified Public Inquiry API (P1)
- All external users benefit from a single certificate-validity lookup surface (pilots, aircraft, designees).
- Retires RMS/PDR-phase-out dependency (RMS FR-4.5).

### Shared Audit / Compliance Logging (P1)
- FAA internal journeys (P11, P12, P13, P14): cross-system correlation for LEAP/FOIA and oversight cases.
- Replaces 5 independent audit stores.

### Retention / Records Disposition Engine (P2)
- Normalizes 60yr/Permanent/5yr/6mo/25yr/50yr schedule drift across systems.
- Invisible to applicants; critical for FAA internal compliance.

### Digital Signature Service (DocuSign adapter) (P2)
- **Journey 1:** CFI endorsement, DPE checkride certification, AME disposition all use the same signature primitive.
- **Journey 2:** DocuSign round-trip already native to CARES; now portable to other domains.
- **Journey 6:** CLOA issuance and corrective-action acknowledgments signed via the same service.

---

**Next steps referenced in this doc:**
- The shared-service priorities (P0/P1/P2) drive sprint sequencing for the ATLAS target-state roadmap.
- Each rationalized journey should seed a user-story backlog in the corresponding domain team.
- The journey comparison matrix (§4) is the baseline for measuring modernization ROI post-delivery.
