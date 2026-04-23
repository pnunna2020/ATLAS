# RMS — Functional Requirements

Detailed functional requirements for the Registry Modernization System (RMS), extracted from existing artifacts (2025 Aircraft Registration PIA, NARA N1-237-06-001, DOT OIG AV2019052, GAO IMTEC-91-29, AC Form 8050-1, Federal Register Jan 2025 rulemaking, FAA user-facing portals, CARES program documentation).

**Priority convention (MoSCoW):**
- **Must** — statutory, regulatory, treaty, or core-operational requirement; non-negotiable for modernized platform
- **Should** — strongly warranted by operational, oversight, or stakeholder needs; omission creates significant risk or gap
- **Could** — desirable enhancement or optimization; deferrable without breaking baseline function

**Source artifact legend:**
- **PIA-2025** — DOT/FAA Aircraft Registration Privacy Impact Assessment, 2025
- **NARA-06-001** — NARA Records Disposition Authority N1-237-06-001 (CAIS/airman records)
- **NARA-04-03** — NARA Schedule N1-237-04-03 (aircraft registration records, Permanent)
- **OIG-2019** — DOT OIG Report AV2019052, May 8, 2019
- **OIG-2013** — DOT OIG Report FI-2013-101, June 2013
- **GAO-91** — GAO/IMTEC-91-29, April 1991
- **GAO-20-164** — GAO-20-164 (aircraft registration fraud findings)
- **AC-8050-1** — AC Form 8050-1 Aircraft Registration Application (OMB 2120-0042)
- **FR-2025** — Federal Register final rule, January 2025 (14 CFR Parts 47/49 amendments)
- **SORN-801** — DOT/FAA 801 Aviation Registration Records (88 FR 53951, updated 2023)
- **SORN-847** — DOT/FAA 847 Aviation Records on Individuals
- **USR-GUIDE** — FAA user-facing guidance (amsrvs portal, registry inquiry pages, renewal instructions)
- **RAUTH-2018** — FAA Reauthorization Act of 2018 (Pub. L. 115-254), Section 546
- **CURRENT** — `research/rms/current-state-analysis.md`

---

## FR-RMS-1: Aircraft Registration

Requirements governing the end-to-end aircraft registration lifecycle, from N-number reservation through de-registration. Statutory authorities: 49 U.S.C. §§ 44101–44108, 14 CFR Parts 47/49.

### FR-RMS-1.1: N-number Reservation

| Field | Value |
|---|---|
| ID | FR-RMS-1.1 |
| Description | The system shall allow applicants to reserve a U.S. Registration Number (N-number) through online self-service, telephone request, and mailed paper request. Reservation shall be uniquely assigned, reservable for a statutory period, renewable, and assignable to a specific aircraft upon first registration. |
| Source | CURRENT §9.2 (N-number reservation modernized 2019); PIA-2025; USR-GUIDE (registry.faa.gov); 14 CFR Part 47 |
| Priority | Must |

### FR-RMS-1.2: Initial Registration Application

| Field | Value |
|---|---|
| ID | FR-RMS-1.2 |
| Description | The system shall accept initial aircraft registration applications (AC Form 8050-1, OMB 2120-0042) capturing owner full name, address, phone, email, citizenship certification (U.S. citizen or lawful resident alien), aircraft make/model/serial number, N-number, and evidence of ownership. The system shall enforce extensive edit checks on data entry and cross-validate structured entries against submitted evidence. Per January 2025 rulemaking, the system shall support fully electronic submission with digital signatures in addition to paper intake. |
| Source | AC-8050-1; PIA-2025 §3; FR-2025 (14 CFR Part 47 revision); CURRENT §3.3, §5.1 |
| Priority | Must |

### FR-RMS-1.3: Registration Renewal (7-Year Cycle)

| Field | Value |
|---|---|
| ID | FR-RMS-1.3 |
| Description | The system shall enforce a 7-year registration renewal cycle (per FAA Reauthorization Act of 2018). The system shall send a "Notice: Expiration of Aircraft Registration" letter approximately 6 months before expiration. Renewal shall be available via (a) online affirm-no-change flow using N-number + random security code from the notice letter, and (b) paper Aircraft Registration Renewal Application with a $5 fee. The system shall force paper submission if ownership, address, or other registrable fields change. |
| Source | RAUTH-2018 §546; PIA-2025; USR-GUIDE (amsrvs.registry.faa.gov/renewregistration); CURRENT §5.2 |
| Priority | Must |

### FR-RMS-1.4: Ownership Transfer

| Field | Value |
|---|---|
| ID | FR-RMS-1.4 |
| Description | The system shall process ownership transfers supported by bill of sale, divorce decree, court order, or other legal conveyance documents recognized under 14 CFR Part 49. Transfer shall be indexed and recorded per 49 U.S.C. §§ 44107–44108. The system shall link transfer records to the aircraft's permanent record file and maintain a chain-of-title view. |
| Source | PIA-2025 §3; 49 U.S.C. §§ 44107–44108; 14 CFR Part 49; CURRENT §4.1, §8.4 |
| Priority | Must |

### FR-RMS-1.5: Dealer Registration

| Field | Value |
|---|---|
| ID | FR-RMS-1.5 |
| Description | The system shall support aircraft dealer registration under 14 CFR Part 47 Subpart C, including initial certificate issuance, renewal, and dealer-specific operating privileges that permit flight under the dealer's registration number without individual aircraft registration prior to sale. |
| Source | 14 CFR Part 47 Subpart C; CURRENT §8.4 (statutory authorities); USR-GUIDE |
| Priority | Must |

### FR-RMS-1.6: International Operations Declaration

| Field | Value |
|---|---|
| ID | FR-RMS-1.6 |
| Description | The system shall support filings required to fly outside the United States, including issuance of a registration letter suitable for operation in the National Airspace System (NAS) and satisfaction of ICAO Annex 7 treaty obligations for identifying national registration marks. Export-related filings shall receive priority over all other processing. |
| Source | PIA-2025 §3 (registration letter/fax for immediate NAS operation); OIG-2019 (export priority); ICAO Annex 7; CURRENT §5.1, §8.4 |
| Priority | Must |

### FR-RMS-1.7: Security Agreement Filing

| Field | Value |
|---|---|
| ID | FR-RMS-1.7 |
| Description | The system shall record security agreements, liens, leases, and other encumbrances filed under 14 CFR Part 49 and 49 U.S.C. §§ 44107–44108. The system shall maintain the filing order established by time-stamping of receipt and expose recorded instruments through the public records search surface. |
| Source | 14 CFR Part 49; 49 U.S.C. §§ 44107–44108; PIA-2025 §3 (security/lease agreement document type); CURRENT §5.1 |
| Priority | Must |

### FR-RMS-1.8: De-Registration / Cancellation

| Field | Value |
|---|---|
| ID | FR-RMS-1.8 |
| Description | The system shall process cancellation of aircraft registration (e.g., export, sale to non-U.S. owner, destruction, scrapping) and reflect deregistered status in public inquiry. Cancellation records shall be retained under NARA N1-237-04-03 as Permanent Records. |
| Source | 14 CFR Part 47; NARA-04-03; PIA-2025; CURRENT §4.3 |
| Priority | Must |

---

## FR-RMS-2: Airmen Certification

Requirements governing airman certification records management, downstream of IACRA application intake and TSA security vetting. Statutory authorities: 49 U.S.C. §§ 44703, 44709, 44710; 14 CFR Parts 61, 63, 65.

### FR-RMS-2.1: Certificate Issuance (from IACRA intake)

| Field | Value |
|---|---|
| ID | FR-RMS-2.1 |
| Description | The system shall ingest airman certification records from IACRA (including post-TSA-vetting applications) via secure transport, create or update the airman's master record in CAIS, and produce the airman certificate. Captured elements shall include name, DOB, height, weight, hair/eye color, gender, nationality, place of birth, addresses, email, certificate type/level/number, ratings, limitations, date issued, and names of test administrators and flight instructors. |
| Source | NARA-06-001 (Item 8060.1.b.1); CURRENT §3.1, §4.1, §5.3, §6.6; SORN-847 |
| Priority | Must |

### FR-RMS-2.2: Certificate Replacement

| Field | Value |
|---|---|
| ID | FR-RMS-2.2 |
| Description | The system shall allow airmen to request replacement certificates (lost, stolen, damaged, or reissued for cause) through the Airmen Services portal and by mail, subject to identity verification. |
| Source | USR-GUIDE (amsrvs.registry.faa.gov/amsrvs); 14 CFR Parts 61/63/65; CURRENT §7.1, §7.4 |
| Priority | Must |

### FR-RMS-2.3: Certificate Number Change (SSN Removal)

| Field | Value |
|---|---|
| ID | FR-RMS-2.3 |
| Description | The system shall allow airmen whose certificate numbers are their Social Security Number to request assignment of a unique FAA-generated certificate number, to align with current practice that discontinues SSN as a primary identifier while preserving historical CAIS records. |
| Source | CURRENT §4.1, §4.4 (legacy SSN capture); PIA-2025; SORN-847; USR-GUIDE |
| Priority | Must |

### FR-RMS-2.4: Address Change

| Field | Value |
|---|---|
| ID | FR-RMS-2.4 |
| Description | The system shall allow airmen to update mailing address and contact information through online self-service within statutory notification windows (30 days for part-47 aircraft owners; applicable notification windows for airmen per 14 CFR §61.60). |
| Source | 14 CFR §61.60; PIA-2025 §3 (30-day address change); CURRENT §5.2; USR-GUIDE |
| Priority | Must |

### FR-RMS-2.5: Public Airmen Inquiry

| Field | Value |
|---|---|
| ID | FR-RMS-2.5 |
| Description | The system shall provide a public-facing Airmen Inquiry endpoint permitting searches by name, address, and certificate number, returning only releasable elements as defined under SORN DOT/FAA 847 routine uses. Inquiry data shall be refreshed at least once per federal workday; the modernized platform shall move toward near-real-time refresh. |
| Source | USR-GUIDE (amsrvs.registry.faa.gov/airmeninquiry); SORN-847; CURRENT §5.4, §7.1; OIG-2019 (nightly refresh gap) |
| Priority | Must |

### FR-RMS-2.6: Temporary Authority Issuance

| Field | Value |
|---|---|
| ID | FR-RMS-2.6 |
| Description | The system shall support issuance of temporary airman authority (temporary certificates pending permanent issuance, reissuance pending investigation, and similar interim authorizations) as contemplated under 14 CFR Parts 61/63/65. |
| Source | 14 CFR Parts 61/63/65; USR-GUIDE; CURRENT §8.4 |
| Priority | Should |

### FR-RMS-2.7: Verification of Privileges

| Field | Value |
|---|---|
| ID | FR-RMS-2.7 |
| Description | The system shall support authoritative verification of an airman's current certificate, ratings, and limitations in response to inquiries from employers, foreign civil aviation authorities (CAAs), law enforcement (via LEAP), and internal FAA stakeholders, including structured foreign license verification (AFS-760-Exam-02). |
| Source | CURRENT §6.8 (LEAP), §7.3 (Form AFS-760-Exam-02 foreign verification); SORN-847 routine uses; GAO-91 (LEAP volume) |
| Priority | Must |

---

## FR-RMS-3: Document Management

Requirements governing the ingestion, storage, annotation, and retention of registry documents. The digital image is the authoritative legal record.

### FR-RMS-3.1: Document Scanning (front + back)

| Field | Value |
|---|---|
| ID | FR-RMS-3.1 |
| Description | The system shall scan every incoming paper document, front and back, at a resolution and fidelity sufficient to serve as the authoritative legal record. Scanned images shall be time-stamped to preserve the order of receipt. Modernized intake shall produce searchable formats (PDF/A with OCR and extracted entities) in addition to or in place of TIFF. |
| Source | PIA-2025 §3 (work packet front/back scanning); CURRENT §5.1, §10.2, §12.2; OIG-2019 |
| Priority | Must |

### FR-RMS-3.2: Work Packet Creation

| Field | Value |
|---|---|
| ID | FR-RMS-3.2 |
| Description | The system shall classify each scanned item by document type (envelope, application, evidence of ownership, correspondence, security/lease agreement, other) and assemble classified items into a work packet routed to aircraft registration examination staff. |
| Source | PIA-2025 §3 (work packet definition and document type list); CURRENT §5.1 |
| Priority | Must |

### FR-RMS-3.3: Image Annotation with File Notations

| Field | Value |
|---|---|
| ID | FR-RMS-3.3 |
| Description | Upon examiner determination that registration requirements are met, the system shall annotate the relevant images with a dated registration or recordation notation and transfer the annotated images permanently into the aircraft's or airman's record file. Annotations shall be immutable; subsequent corrections shall create new annotated versions rather than overwrite history. |
| Source | PIA-2025 §3 (dated registration/recordation notation); CURRENT §5.1 |
| Priority | Must |

### FR-RMS-3.4: Document Retention

| Field | Value |
|---|---|
| ID | FR-RMS-3.4 |
| Description | The system shall enforce retention per NARA schedules: (a) aircraft registration records — Permanent (N1-237-04-03); (b) CAIS airman master file — destroy when ≥60 years old or no longer needed; (c) airman certification files (digital image copies and indices) — destroy 60 years after annual cutoff or when no longer needed; (d) born-digital airman records — 60 years after annual cutoff; (e) electronic enforcement records (suspensions, civil penalties, indices) — destroy 5 years after case closed in EIS (per FAA Order 1350.15C Item 2150.5.a); (f) foreign license verification files — cut off at calendar-year end, destroy 6 months after cutoff. Original paper shall be destroyed only when the digital copy is confirmed an adequate substitute. |
| Source | NARA-06-001; NARA-04-03; FAA Order 1350.15C; CURRENT §4.3 |
| Priority | Must |

### FR-RMS-3.5: Quality Review Before Paper Destruction

| Field | Value |
|---|---|
| ID | FR-RMS-3.5 |
| Description | The system shall require a quality assurance review confirming the digital image is a legible and complete substitute for the paper original before the paper original is destroyed. Until QA confirms adequacy, paper originals shall be retained and associated with the active work packet. Records shall be maintained per 36 CFR §§ 1234.30 and 1234.32 for their entire retention period. |
| Source | NARA-06-001 (original paper destroy when digital adequate); 36 CFR §§ 1234.30, 1234.32; PIA-2025; CURRENT §3.2, §4.3 |
| Priority | Must |

---

## FR-RMS-4: Public Access & Inquiry

Requirements governing public-facing data access — online inquiries, bulk downloads, and the physical Public Documents Room — including the path to PDR phase-out.

### FR-RMS-4.1: Aircraft Inquiry (daily refresh)

| Field | Value |
|---|---|
| ID | FR-RMS-4.1 |
| Description | The system shall provide a public Aircraft Inquiry endpoint (today at `registry.faa.gov/aircraftinquiry/`) permitting search by N-number, serial number, make/model, and owner. The current system refreshes once per federal workday at midnight; the modernized platform shall move toward near-real-time refresh as a prerequisite to PDR phase-out. |
| Source | USR-GUIDE; CURRENT §2 (refresh cadence), §7.1, §10.5; OIG-2019 |
| Priority | Must |

### FR-RMS-4.2: Airmen Inquiry (name/address search)

| Field | Value |
|---|---|
| ID | FR-RMS-4.2 |
| Description | The system shall provide a public Airmen Inquiry endpoint (today at `amsrvs.registry.faa.gov/airmeninquiry/`) returning only elements releasable under SORN DOT/FAA 847. Non-releasable fields (e.g., SSN, date of birth, medical information) shall never be exposed. |
| Source | USR-GUIDE; SORN-847; CURRENT §7.1 |
| Priority | Must |

### FR-RMS-4.3: Active Airmen Statistics

| Field | Value |
|---|---|
| ID | FR-RMS-4.3 |
| Description | The system shall publish periodic (at minimum annual) statistics on active certificated airmen, by certificate type, rating, and category, consistent with historical FAA reporting (~1.5M certificated airmen; ~400K certificates issued per year). |
| Source | CURRENT §4.2 (volumes); USR-GUIDE (faa.gov statistics pages); GAO-91 |
| Priority | Should |

### FR-RMS-4.4: Releasable Airmen Database Download

| Field | Value |
|---|---|
| ID | FR-RMS-4.4 |
| Description | The system shall generate and publish a monthly downloadable CSV dataset of releasable airman certification information. Contents shall be limited to elements authorized under SORN DOT/FAA 847 routine uses. |
| Source | USR-GUIDE (`faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download`); SORN-847; CURRENT §6 (public releasable CSV), §7.2 |
| Priority | Must |

### FR-RMS-4.5: PDR Real-Time Access

| Field | Value |
|---|---|
| ID | FR-RMS-4.5 |
| Description | Until CARES delivers an equivalent authenticated real-time inquiry surface, the system shall continue to support real-time aircraft record access at the Public Documents Room (47 workstations at MMAC Oklahoma City — 42 permit-held, 2 vacant, 3 public). Workstations shall support title search, ownership history, lien tracing, and real-time read against the authoritative record. Permits ($3,441/year per workstation) shall be managed month-to-month with 30-day termination notice, background-checked permit holders, and FAA-issued security badges. |
| Source | OIG-2019 (PDR workstation detail, permit economics, background checks); CURRENT §5.5, §10.4, §12.4 |
| Priority | Must (transitional; targeted for phase-out once CARES virtual real-time is in production) |

### FR-RMS-4.6: Certificate Validity Verification

| Field | Value |
|---|---|
| ID | FR-RMS-4.6 |
| Description | The system shall provide a programmatic and human-usable surface for third parties (employers, foreign CAAs, law enforcement, other FAA offices) to verify the current validity of an airman certificate or aircraft registration, returning only releasable data under the applicable SORN. |
| Source | CURRENT §6.8 (LEAP, designee read access); SORN-847, SORN-801 routine uses; GAO-91 (LEAP inquiry volume) |
| Priority | Must |

---

## FR-RMS-5: Integration

Requirements governing data exchange with upstream intake systems, downstream consumers, and peer FAA platforms. The modernization trajectory replaces FTP/batch patterns with authenticated APIs.

### FR-RMS-5.1: IACRA Ingest (TIFF over FTP)

| Field | Value |
|---|---|
| ID | FR-RMS-5.1 |
| Description | The system shall ingest airman certification document images from IACRA. Today, IACRA posts TIFF images over secure FTP to CAIS/IMS. The modernized system shall replace this with an authenticated encrypted API and convert images to searchable formats on ingest. |
| Source | CURRENT §3.1, §6.6, §10.5, §12.4; PIA-2025 |
| Priority | Must |

### FR-RMS-5.2: CARES Coexistence

| Field | Value |
|---|---|
| ID | FR-RMS-5.2 |
| Description | During the CARES transition (Phase 1 aircraft IOC Dec 2022, FOC Fall 2027; Phase 2 airmen FOC Fall 2027), the system shall support bidirectional data flow and consistent record-of-truth rules between RMS and CARES. Dual-run shall ensure that intake, adjudication, and public access remain available without data divergence. |
| Source | CURRENT §6.1, §9.1; OIG-2019 (CARES timeline, coexistence requirement) |
| Priority | Must |

### FR-RMS-5.3: USAS Portal Exchange

| Field | Value |
|---|---|
| ID | FR-RMS-5.3 |
| Description | The system shall support data exchange with the United States Agent Service (USAS) Portal. The current 2025-PIA posture is a one-time prepopulation exchange (name, email, N-number, serial number). If sustained bidirectional synchronization becomes required, it shall be implemented via authenticated API under CARES. |
| Source | PIA-2025 §3 (USAS one-time exchange); CURRENT §6.2 |
| Priority | Should |

### FR-RMS-5.4: AVS eForms Form 337 Ingest

| Field | Value |
|---|---|
| ID | FR-RMS-5.4 |
| Description | The system shall ingest FAA Form 337 (Major Repair and Alteration; OMB 2120-0020) data from AVS eForms. Today this flows via FTP carrying aircraft nationality/registration mark, serial number, make/model/series, and owner name/address. The modernized system shall replace FTP with an authenticated encrypted API with schema validation. |
| Source | PIA-2025 §3 (Form 337 via FTP); CURRENT §6.3, §10.5, §12.2 |
| Priority | Must |

### FR-RMS-5.5: Pay.gov Payment Processing

| Field | Value |
|---|---|
| ID | FR-RMS-5.5 |
| Description | The system shall integrate with Pay.gov for credit-card collection of $5 registration/renewal fees. The system shall store only the Pay.gov transaction ID — no cardholder or payment PII shall be stored in RMS or its successor. |
| Source | PIA-2025 §3 (Pay.gov transaction-ID-only); CURRENT §2, §6.4, §12.1 |
| Priority | Must |

### FR-RMS-5.6: TSA Vetting (via IACRA)

| Field | Value |
|---|---|
| ID | FR-RMS-5.6 |
| Description | The system shall preserve the upstream TSA National Transportation Security Database (NTSDB) vetting flow: airman security vetting occurs in IACRA before data reaches the Registry; vetted results land in CAIS. The modernized platform shall honor the ordering (vet-before-issue) and shall close OIG 2013 rec #4 (IRTPA pilot-certification provisions). |
| Source | CURRENT §6.5, §8.6 (OIG 2013 rec #4); OIG-2013; OIG-2019 |
| Priority | Must |

### FR-RMS-5.7: DIWS/MSS Demographic Sync

| Field | Value |
|---|---|
| ID | FR-RMS-5.7 |
| Description | The system shall maintain demographic consistency between the airman medical certification systems (DIWS, MSS) and CAIS. The modernized platform shall replace batch reconciliation with an event-driven identity service ensuring near-real-time consistency across aviation-medical and aviation-certification domains. |
| Source | CURRENT §6.7, §10.5, §12.3 |
| Priority | Should |

---

## FR-RMS-6: Compliance & Security

Requirements governing statutory, regulatory, treaty, privacy, records-management, and cybersecurity obligations.

### FR-RMS-6.1: NIST SP 800-53 Rev 5 Controls

| Field | Value |
|---|---|
| ID | FR-RMS-6.1 |
| Description | The system shall implement NIST SP 800-53 Revision 5 security controls at the FIPS 200 minimum baseline (confidentiality/integrity/availability) and maintain an active Authority to Operate. The current RMS ATO was issued April 20, 2022. Controls shall include role-based access, encryption in transit and at rest, FISMA compliance, and alternate processing site / DR capability (closing OIG 2013 rec #8). |
| Source | CURRENT §1, §8.3, §10.6; OIG-2013 (recs #6 PII encryption, #8 alternate site); OIG-2019 |
| Priority | Must |

### FR-RMS-6.2: NARA Retention Compliance

| Field | Value |
|---|---|
| ID | FR-RMS-6.2 |
| Description | The system shall comply with NARA records schedules governing the registry: N1-237-04-03 (aircraft registration records — Permanent) and N1-237-06-001 (CAIS master file, airman certification files, enforcement records, foreign verification files — with the retention matrix enumerated in FR-RMS-3.4). Records shall be maintained per 36 CFR §§ 1234.30 and 1234.32 for the full retention period. |
| Source | NARA-04-03; NARA-06-001; 36 CFR §§ 1234.30, 1234.32; CURRENT §4.3, §8.2 |
| Priority | Must |

### FR-RMS-6.3: Privacy Act Compliance (SORNs)

| Field | Value |
|---|---|
| ID | FR-RMS-6.3 |
| Description | The system shall operate consistently with the published System of Records Notices — DOT/FAA 801 Aviation Registration Records (88 FR 53951, August 9, 2023) and DOT/FAA 847 Aviation Records on Individuals — and the 15 Department-wide routine uses (75 FR 82132, 77 FR 42796, 84 FR 55222). Public and internal data access shall be restricted to the releasable elements defined by the applicable SORN. Privacy Act access/amendment rights and subject-driven redaction of sensitive PII from public records shall be supported. |
| Source | SORN-801; SORN-847; PIA-2025; CURRENT §8.1, §4.4 (SPII handling); Privacy Act of 1974 |
| Priority | Must |

### FR-RMS-6.4: 14 CFR Parts 47/49 Regulatory Alignment

| Field | Value |
|---|---|
| ID | FR-RMS-6.4 |
| Description | The system shall implement 14 CFR Part 47 (Aircraft Registration) and Part 49 (Recording of Aircraft Titles and Security Documents) including the January 2025 final-rule amendments that remove paper-based and stamping requirements and enable electronic registration, digital signatures, and electronic payment. The system shall also align with 14 CFR Parts 61, 63, and 65 for airman certification. Operational procedures and designee programs that still reference paper flows shall be brought into compliance with the 2025 rulemaking. |
| Source | FR-2025 (14 CFR Parts 47/49 amendments); 14 CFR Parts 47, 49, 61, 63, 65; CURRENT §8.4, §9.2, §9.4 |
| Priority | Must |

### FR-RMS-6.5: Audit Trail for All Record Modifications

| Field | Value |
|---|---|
| ID | FR-RMS-6.5 |
| Description | The system shall maintain an immutable, time-stamped audit trail of every create, read-for-export, update, annotation, and delete operation on registry records, capturing actor identity, timestamp, source IP, the affected record identifier, and the change payload. Audit records shall be retained per NARA guidance, be queryable by the Registry IT compliance function, and support LEAP/law-enforcement and FOIA responses. |
| Source | OIG-2019 (role-based access, accountability); OIG-2013 rec #6 (PII encryption/controls); CURRENT §8.3, §10.7, §12.4 (fraud detection); GAO-20-164 (straw-ownership detection) |
| Priority | Must |

---

## Cross-Cutting Notes

- **Mandate alignment:** FAA Reauthorization Act of 2018, Section 546, required modernization by October 2021 — a deadline already missed. CARES Phase 1 FOC has slipped from Fall 2023 to Fall 2027. Every *Must* requirement here should be realized within CARES Phase 1 (aircraft) or Phase 2 (airmen) as scope permits; coexistence requirements (FR-RMS-5.2) are load-bearing during the dual-run window.
- **Face-value document acceptance** (OIG-2019, GAO-20-164) is a documented fraud vector. Requirements in FR-RMS-3 (work packet, annotation) and FR-RMS-6.5 (audit trail) presume a modernized examiner workflow that adds risk-based review to the current 100%-human-review posture.
- **PDR phase-out** is bounded by FR-RMS-4.5 (transitional) and is unlocked by FR-RMS-4.1 moving from nightly to near-real-time refresh.
- **TIFF corpus** (~174M images, no OCR) is not a requirement in itself but is the constraint that makes FR-RMS-3.1 (modernized scanning producing searchable formats) and FR-RMS-5.1 (IACRA ingest with OCR) load-bearing for the target state.
