# RMS — Registry Modernization System: Current-State Analysis

A consolidated technical and operational profile of the FAA's legacy civil aviation registry platform, drawing on the 2025 Aircraft Registration PIA, NARA N1-237-06-001 records schedule, DOT OIG report AV2019052, GAO IMTEC-91-29, the AC Form 8050-1 application, and prior research in `tech-profile.md`. This is the definitive RMS reference for modernization planning, AI/GenAI opportunity scoping, and CARES transition decisions.

---

## 1. System Identity

| Attribute | Value |
|---|---|
| Full name | Registry Modernization System |
| Acronym | RMS (also referenced as "Aircraft Registry", "AVS Registry", "Civil Aviation Registry", "The Registry") |
| Owning organization | FAA Office of Aviation Safety (AVS), Flight Standards Service, Civil Aviation Registry Division |
| Operational branches | Aircraft Registration Branch (AFB-710); Airmen Certification Branch |
| Location | Mike Monroney Aeronautical Center (MMAC), Oklahoma City, OK |
| ATO | April 20, 2022 (NIST SP 800-53 Rev 5) |
| FIPS categorization | Governed under FIPS 200 minimum security requirements (confidentiality/integrity/availability baseline per 800-53 Rev 5) |
| Program Manager (per 2025 PIA) | Carla J. Colwell — AVS/FAA |
| Responsible Official (Aircraft Registry PIA) | Kelly Merritt — Kelly.A.Merritt@faa.gov, (405) 954-3815 |
| Prepared by | Michael Bjorkman, Acting FAA Privacy Officer |
| Chief Privacy Officer (approver) | Karyn Gorman, DOT OCIO |
| NARA schedule contact (historic) | Harol Everett (AFS-700), Janet Stewart (AFS-140) |

**Public URLs (inquiry / self-service):**
- `https://registry.faa.gov/aircraftinquiry/` — Aircraft Inquiry
- `https://amsrvs.registry.faa.gov/airmeninquiry/` — Airmen Inquiry
- `https://amsrvs.registry.faa.gov/amsrvs/` — Airmen Services
- `https://amsrvs.registry.faa.gov/renewregistration/` — Aircraft Registration Renewal
- `https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download` — Releasable airmen CSV (monthly)

---

## 2. Technology Stack Analysis

| Layer | Technology | Notes |
|---|---|---|
| Platform | Mainframe computer-based | Confirmed by OIG AV2019052; single on-site mainframe at MMAC |
| Programming language | **NATURAL** (Software AG) | Explicitly named in OIG AV2019052 footnote 10; described as "outdated programming language" |
| Database | **ADABAS** (Software AG) | Inverted-list hierarchical DBMS; non-relational |
| Document repository | **IMS — Image Management System** | TIFF-based image store holding the authoritative legal record |
| Document format | TIFF (Tagged Image File Format) | Large files, not searchable, no OCR applied |
| Integration protocols | FTP (file transfer protocol), batch files | FAA Form 337 flows via FTP server; USAS Portal received one-time extract |
| Payment integration | Pay.gov (credit card) + FAA cashier/accounting (paper) | Registry does not store payment data; transaction ID only |
| Last major upgrade | 2008 | Over 17 years old as of 2025 |
| Operational status | "Approaching end of service life; suffers intermittent outages" (OIG) |

**Known technology risks:**
- **Language obsolescence** — NATURAL is a proprietary 4GL with a shrinking labor pool; Software AG sunset announcements have intensified the skills-gap concern
- **Vendor lock-in** — Software AG owns both NATURAL and ADABAS; replacement requires dual migration
- **No real-time external access** — online inquiry data is refreshed once per federal workday at midnight, not live
- **Intermittent outages** noted by OIG (2019) with no documented alternate processing site at that time (2013 OIG recommendation #8 still open as of 2019)
- **Historical continuity** — GAO IMTEC-91-29 (April 1991) documented RMS's predecessor as microfilm/microfiche-plus-mainframe; the 2008 upgrade digitized documents but did not replace the mainframe layer

---

## 3. Subsystem Architecture

RMS is an umbrella label for a cluster of mainframe-resident IT systems operated by the Civil Aviation Registry Division. The three principal subsystems are:

### 3.1 CAIS — Comprehensive Airmen Information System
- Authoritative master data file for every certificated airman in the U.S.
- Stores identity, certification, rating, and enforcement data derived from Airmen Certification Documents
- Governed by NARA schedule N1-237-06-001, FAA Item 8060.1.b.1
- Feeds the Releasable Airmen Download (monthly public CSV)
- Receives TIFF scans over secure FTP from IACRA

### 3.2 IMS — Image Management System
- Document/image repository storing ~174 million TIFF images across ~25 million documents
- Houses aircraft registration work packets (front/back scans of every submitted document)
- Digital image copy is the **official legal record** for both aircraft and airman registrations (per 2025 PIA, for part-47 aircraft registrations)
- Records are maintained per 36 CFR 1234.30 and 1234.32 for their entire retention period
- No OCR applied; images are not full-text searchable

### 3.3 Aircraft Registration System (AVS Registry)
- National repository of all U.S. civil aircraft registrations under 49 U.S.C. §§ 44102–44103, 44107, 44108
- Records of ~300,000 registered aircraft (as of 2019 OIG; grown since)
- Satisfies ICAO Annex 7 treaty obligations
- Performs "extensive edit checks" on data entry; database entries cross-validated against scanned images
- Issues U.S. Registration Numbers (N-numbers) and certificates of aircraft registration

**Relationships:**
- CAIS (airman identity/certification) and the Aircraft Registration System (aircraft identity/ownership) are managed as **separate branches** on the same mainframe, sharing the IMS image repository for document evidence
- OIG recommended considering a combined registry under CARES; FAA has kept them separate for now due to distinct workflows and statutory bases
- IMS is the common backing store — every paper submission across both domains is scanned and annotated here before becoming the permanent record

---

## 4. Data Architecture

### 4.1 Data Element Inventory

**Airman identification (CAIS, per NARA N1-237-06-001 Item 8060.1.b.1):**
- Name
- Social Security Number (legacy collection — still retained in historical records)
- Date of birth
- Height, weight, hair color, eye color, gender
- Nationality, place of birth
- Mailing address, physical address, email address

**Airman certification:**
- Certificate type, level, number
- Ratings and limitations
- Date certificate issued
- Names of test administrators and flight instructors
- Enforcement action information

**Aircraft registration (AC Form 8050-1, per 2025 PIA):**
- Owner full name, address, phone, email
- Citizenship certification (U.S. citizen or lawful resident alien)
- Aircraft Registration Number (N-number)
- Manufacturer, model, serial number
- Evidence of ownership (bill of sale, divorce decree, court order, etc.)
- Security/lease agreement documents
- Transaction ID upon payment confirmation (no payment PII stored)

### 4.2 Volumes

| Metric | Value |
|---|---|
| Certificated airmen | ~1.5 million |
| Registered aircraft | ~300,000 |
| Total documents | ~25 million |
| TIFF image files | ~174 million |
| FY2018 airman certificates issued | 400,000+ |
| FY2018 aircraft documents processed | 667,000+ |
| FY2018 aircraft registrations | 200,000+ |
| FY2018 telephone inquiries answered | 89,000+ |
| FY2018 email responses | 31,000+ |
| FY2018 information requests assisted | 90,000+ |
| FY2017 aircraft record CDs mailed | 15,000 |
| Historical baseline (GAO 1991) | 3.6M airmen on microfilm, 279K aircraft on microfiche |

### 4.3 Retention

Per NARA N1-237-06-001:
- **CAIS master file:** delete records when information is ≥60 years old or no longer needed (whichever is longer)
- **Airman certification files (digital image copies + indices):** destroy 60 years after annual cutoff or when no longer needed (whichever is later)
- **Born-digital airman records:** destroy 60 years after annual cutoff
- **Original paper records:** destroy when digital copy is confirmed adequate substitute (supercedes NCJ-237-77-3 Item 20)
- **Enforcement records (electronic):** destroy suspensions/civil penalties and indices 5 years after case closed in EIS (per FAA Order 1350.15C Item 2150.5.a)
- **Foreign license verification files:** cut off at calendar-year end; destroy 6 months after cutoff
- **Aircraft registration records:** designated by NARA as **Permanent Records** under schedule N1-237-04-03

### 4.4 Data Quality Issues

- **No OCR on TIFF corpus** — 174M images are opaque to text search; manual review required for any content-level query
- **Face-value acceptance** — aircraft examiners accept submitted documents without third-party authenticity verification (OIG flagged fraud risk)
- **Inconsistent SPII handling** — sensitive PII occasionally embedded in public aircraft records; redaction is reactive, triggered by subject request
- **Incremental public refresh** — inquiry site updates once nightly at midnight federal workdays; real-time data exists only inside the PDR
- **Legacy SSN capture** — SSNs collected historically remain in CAIS even though current practice has shifted away from SSN as a primary identifier
- **Data-integrity recommendation history** — 2013 OIG recs #1, #3 (periodic reassessment, address currency) closed by 2017 but underlying ingest model (paper-first, no external verification) unchanged

---

## 5. User Roles & Workflows

### 5.1 Aircraft Registration Workflow (paper-first, per 2025 PIA)

1. Applicant obtains **AC Form 8050-1** from the AFB-710 website (OMB Ctrl No. 2120-0042, Expires 10/31/2025)
2. Form + evidence of ownership + $5 fee mailed to FAA
3. FAA **time-stamps** documents on receipt to establish order
4. Documents are **identified by type** (envelope, application, evidence of ownership, correspondence, security/lease agreement) and **scanned** to create a **work packet** (front+back images of every item)
5. Work packet routed to **aircraft registration examination staff**
6. Examiner determines whether requirements are met:
   - If deficient: correction letter sent; originals retained pending reply
   - If met: images annotated with **dated registration/recordation notation**, transferred permanently into the aircraft's record file
7. **Certificate of Aircraft Registration** mailed; optionally, registration letter faxed for immediate NAS operation
8. N-number assigned to the aircraft
9. **Imported and new aircraft are prioritized** (cannot operate without N-number)
10. **Export-related filings** receive processing priority over all other users (per OIG, even over PDR permit holders)
11. Paper originals destroyed after QA confirms digital-image adequacy
12. **Backlog:** up to 6 weeks to process (OIG 2019)

### 5.2 Aircraft Registration Renewal Workflow

- Renewal cycle: every **7 years** (extended from 3 years by the 2018 FAA Reauthorization Act)
- FAA mails **"Notice: Expiration of Aircraft Registration"** letter 6 months before expiration
- Renewal options:
  - Mail paper Aircraft Registration Renewal Application with $5 fee (cashier processes; or Pay.gov for credit card)
  - Online at `amsrvs.registry.faa.gov/renewregistration/` using N-number + random security code from notice letter
- Online path only supports **affirm-no-change**; any change forces paper submission
- 30-day change-of-address notification requirement for part-47 owners

### 5.3 Airmen Certification Workflow

- More automated than aircraft registration because upstream processing (including **TSA security vetting**) happens before data reaches the Registry
- IACRA handles airman application intake and data validation
- CAIS receives TIFF images of certification documents via **secure FTP from IACRA**
- Enforcement actions captured in CAIS and (for electronic copies) destroyed 5 years after case closure

### 5.4 Public Inquiry Workflows

- **Online inquiry** (anyone, anywhere): Airmen Inquiry and Aircraft Inquiry websites — refreshed once daily at midnight federal workdays
- **Monthly Releasable Airmen CSV**: downloadable dataset of airman certification info
- **Real-time access**: only available at the PDR in Oklahoma City
- **Mailed/couriered records**: public can request printed aircraft records or CDs for a small fee
- **FOIA path** for records not otherwise releasable

### 5.5 PDR — Public Documents Room

- Physical access point inside the Registry Building, MMAC, Oklahoma City
- **47 workstations** (42 permit-held, 2 vacant, 3 public) as of June 2018
- **24 permit-holder companies** (aircraft title companies, trust companies, law firms); most have held permits for years
- Permits: $3,441/year per workstation (covers hardware, software licenses, PDR attendant)
- Access permitted month-to-month; FAA may terminate with 30-day notice
- Permit holders need background check; receive security badges (post-9/11 policy change)
- **Public access:** U.S. citizens 2-day advance notice; international users 3 weeks
- FY2017: only **10 non-permit-holders** used the PDR — suggests real-time access demand is concentrated in commercial intermediaries
- Records/print fees go to FAA IT; workstation fees fund Registry service contracts
- Permit holder misuse results in revocation; access monitored by full-time attendant, Contracting Officer, and Registry IT staff
- **FAA plans to phase out PDR once CARES delivers virtual real-time access** — but no firm date

---

## 6. Integration Architecture

### 6.1 CARES — Civil Aviation Registry Electronic Services
- Replacement system for RMS, currently in phased coexistence
- Phase 1 (aircraft) IOC originally targeted Dec 2022; FOC has slipped from Fall 2023 to **Fall 2027**
- Phase 2 (airmen) FOC target Fall 2027
- During transition, CARES and RMS coexist; data flows in both directions

### 6.2 USAS Portal (United States Agent Service)
- **One-time** data exchange of aircraft records from AVS Registry to USAS Portal (per 2025 PIA)
- Fields shared: name, email, N-number, serial number
- Purpose: prepopulation of USAS Portal
- Ongoing bidirectional sync not documented — current posture is one-shot

### 6.3 AVS eForms — Form 337 (Major Repair and Alteration)
- OMB Ctrl No. 2120-0020, Expires 07/31/2026
- Completed Form 337 data sent **via FTP server** to Aircraft Registry
- Payload: aircraft nationality and registration mark, serial number, make, model, series; owner name and address
- Data becomes part of the aircraft record

### 6.4 Pay.gov
- Credit-card payment processor for $5 registration/renewal fees
- Registry stores **no payment data**, only a transaction ID
- Pay.gov PIA: `https://www.fiscal.treasury.gov/files/pia/paygov-pclia.pdf`

### 6.5 TSA NTSDB (National Transportation Security Database)
- Airman security vetting occurs via IACRA, which interfaces with TSA NTSDB
- Vetted data lands in CAIS after TSA clearance
- OIG 2013 recommendation #4 (Intelligence Reform and Terrorism Prevention Act provisions for pilot certifications) still open as of 2019 (target 12/31/2020)

### 6.6 IACRA → CAIS
- IACRA is the primary intake system for airman certification applications
- Posts TIFF images of application documents to CAIS/IMS **over secure FTP**
- Performs security review coordination with TSA upstream

### 6.7 DIWS / MSS ↔ CAIS
- Demographic synchronization pathway between airman medical certification systems and CAIS
- Keeps airman demographic details consistent across aviation-medical and aviation-certification domains
- Not explicitly detailed in the 2025 Aircraft Registration PIA (airman certification addressed in a separate PIA); relationship flagged for CARES Phase 2 scope

### 6.8 Other Integration Points
- **Law enforcement** (FBI, DEA, ATF, state/local): inquiries served via Law Enforcement Assistance Program (LEAP), historically ~16,000/year (GAO 1991)
- **Aircraft title companies / financial institutions:** monthly permits in PDR for real-time title search; bulk CSVs and paid records for offsite customers
- **FAA designee airworthiness inspectors:** read access for safety/commerce under DOT/FAA 801 routine uses

---

## 7. Public-Facing Surfaces

### 7.1 Inquiry Endpoints

| URL | Purpose |
|---|---|
| `https://registry.faa.gov/aircraftinquiry/` | Aircraft Inquiry — search by N-number, serial, make/model, owner |
| `https://amsrvs.registry.faa.gov/airmeninquiry/` | Airmen Inquiry — certificate lookup |
| `https://amsrvs.registry.faa.gov/amsrvs/` | Airmen Services portal |
| `https://amsrvs.registry.faa.gov/renewregistration/` | Aircraft Registration Renewal |

### 7.2 Downloadable Datasets

- **Releasable Airmen Download** — monthly CSV of airman certification info (`faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download`)
- **Aircraft Registration Database** download — document index accessible from `faa.gov` "Download the Aircraft Registration Database" link; updated nightly

### 7.3 Forms Inventory

| Form | OMB Control | Purpose |
|---|---|---|
| AC Form 8050-1 | 2120-0042 (exp 10/31/2025) | Aircraft Registration Application |
| AC Form 8050-1B (equivalent) | — | Aircraft Registration Renewal Application |
| FAA Form 337 | 2120-0020 (exp 07/31/2026) | Major Repair and Alteration |
| Form AFS-760-Exam-02 | — | Foreign license verification (via CAA correspondence) |

### 7.4 Self-Service Capabilities

- **Aircraft owners** can renew online if no changes required (affirm-only flow)
- **Airmen** can use amsrvs portal for limited service functions
- **Public** can search inquiry endpoints, download monthly CSV, request mailed CDs of aircraft records
- **Everything else** (changes, new registrations, document recording, trust registrations, security-interest filings) still requires **paper submission**

---

## 8. Compliance & Governance

### 8.1 Systems of Records Notices (SORNs)
- **DOT/FAA 847** — Aviation Records on Individuals (airman-focused)
- **DOT/FAA 801** — Aviation Registration Records (aircraft-focused; updated August 9, 2023, 88 FR 53951, superseding prior "Aircraft Registration System" SORN)
- 15 additional Department-wide routine uses published in Prefatory Statement of General Routine Uses (75 FR 82132, 77 FR 42796, 84 FR 55222)

### 8.2 NARA Retention Schedules
- **N1-237-04-03** — Civil Aviation Registry aircraft registration records and image indexes, **Permanent Records**
- **N1-237-06-001** — Airman records (CAIS master file 60-year retention; certification files 60-year; enforcement 5-year)
- Supersedes: NCJ-237-77-3 Item 20, NCJ-237-92-2 Item 1, NI-NNA-867 Item 3, NI-237-94-4 Item 5

### 8.3 ATO Details
- Issued **April 20, 2022**
- NIST SP 800-53 Revision 5
- FIPS 200 minimum security controls baseline
- FISMA compliance
- Role-based access controls

### 8.4 Statutory Authority
- **49 U.S.C. § 44101** — Registration requirement
- **49 U.S.C. §§ 44102–44103** — Aircraft registration mandate
- **49 U.S.C. §§ 44107–44108** — Recording of conveyances
- **49 U.S.C. § 44111** — Registry user needs
- **49 U.S.C. §§ 44703, 44709, 44710** — Airman certification
- **14 CFR Part 47** — Aircraft Registration
- **14 CFR Part 49** — Recording of Aircraft Titles and Security Documents
- **14 CFR Parts 61, 63, 65** — Airman certification
- **21 U.S.C. § 802** — Controlled substances law enforcement use
- **ICAO Convention on International Civil Aviation, Annex 7** — treaty obligations

### 8.5 Congressional Mandates
- **Federal Aviation Act of 1958** — original directive to create conveyance filing/indexing/recording system
- **Anti-Drug Abuse Act of 1988** — mandated law-enforcement support improvements (driver of GAO IMTEC-91-29 audit)
- **FAA Modernization and Reform Act of 2012** — fee collection authority for registration/certification
- **FAA Reauthorization Act of 2018 (Pub. L. 115-254)** — **Section 546**: mandates modernization by **October 2021** (missed); paper-based transaction surcharge; Registry must stay open during shutdown/furlough; 7-year registration cycle rulemaking
- **Intelligence Reform and Terrorism Prevention Act** — pilot certification provisions (OIG rec #4 target 12/31/2020, historically open)

### 8.6 OIG/GAO Audit History
- **GAO IMTEC-91-29** (April 1991) — Key Steps Need to Be Performed Before Modernization Proceeds; $23.2M procurement questioned; inadequate requirements definition
- **OIG FI-2013-101** (June 2013) — Civil Aviation Registry Lacks Information Needed for Aviation Safety and Security Measures; 8 recommendations (5 closed by 2017–2018, 3 still open as of 2019)
- **OIG 2014 Management Advisory** — non-citizen trustee trust registrations
- **OIG AV2019052** (May 8, 2019) — FAA Plans To Modernize Its Outdated Civil Aviation Registry Systems, but Key Decisions and Challenges Remain; 4 recommendations (all concurred)
- **GAO-20-164** — Aircraft registration fraud/straw-ownership findings (referenced in modernization scope)

---

## 9. Modernization Status

### 9.1 CARES Program Timeline (vs. original mandate)
- **October 2021**: Congressional deadline for modernization completion (Section 546, 2018 Reauthorization) — **MISSED**
- **Fall 2023**: Original CARES Phase 1 (aircraft) FOC — **MISSED**
- **December 2022**: Phase 1 IOC target
- **Fall 2027**: Current Phase 1 FOC target (aircraft) — **4-year slip**
- **Fall 2027**: Phase 2 FOC target (airmen)

### 9.2 What's Been Modernized
- N-number online reservation (previously printed and hand-keyed; FAA claims automated as of 2019 technical comments)
- Online aircraft registration **renewal** (affirm-only, no-change path)
- Airmen IACRA-side intake with TSA vetting
- Monthly releasable airmen CSV download
- Nightly inquiry refresh to public website
- 2023 SORN update (DOT/FAA 801 republished 8/9/2023)
- USAS Portal one-time prepopulation exchange
- **January 2025 rulemaking**: revised 14 CFR Parts 47/49 to **remove paper-based and stamping requirements**, enabling electronic registration, digital signatures, and electronic payments — the key regulatory unblock for CARES

### 9.3 What Remains on the Mainframe
- Core CAIS airman master file
- Core aircraft registration master file
- IMS TIFF image repository (174M images)
- Examiner work-packet review workflow
- Enforcement action records
- Security interest / lien recordation
- PDR real-time access surface
- Paper-intake scanning pipeline

### 9.4 Remaining Dependencies Blocking Full Replacement
- **Data migration**: 25M documents / 174M TIFFs must move to CARES; format conversion and OCR decisions unresolved
- **AIT coordination**: Office of Information Technology not formally consulted early in planning (OIG 2019)
- **Stakeholder engagement**: title/trust companies, law firms, financial institutions require continuity of PDR-equivalent access
- **Workforce culture**: examiner role must shift from 100% review to risk-based review
- **Funding source**: F&E vs O&M decision needed before CARES enters formal budget
- **Acquisition strategy**: cloud vs server, one-system vs two-system, leverage existing contracts — decisions staged across the Phase 1/2 arc
- **Rulemaking coupling**: January 2025 final rule unblocked the regulatory side, but operational procedures and designee programs still reference paper flows

---

## 10. Technical Debt & Risk Assessment

### 10.1 Mainframe Skills Gap
- NATURAL developers are a shrinking labor pool
- Software AG's product lifecycle direction raises long-term support concerns
- FAA's own AIT office is not natively staffed for deep NATURAL/ADABAS work; most maintenance is contract-delivered

### 10.2 TIFF Corpus Without OCR
- 174M TIFF images are the **legal record** but are unsearchable
- Any entity-level query (e.g., "find all aircraft owned by X entity through Y trust") requires manual image review
- Storage is large and format is unfriendly — OIG flagged this as a core migration obstacle
- Represents the **largest single AI/GenAI opportunity** in the RMS portfolio

### 10.3 Paper-First Workflows
- Aircraft registration still substantially paper-based
- 6-week backlog noted by OIG 2019
- Every paper submission requires scanning, work-packet creation, examiner review
- Even after January 2025 rulemaking, operational transition to electronic-first is incomplete

### 10.4 PDR Physical Dependency
- Only path to real-time aircraft data requires physical presence at MMAC
- 24 permit-holder companies form a commercial intermediary layer between the Registry and aircraft transactions
- Concentrated geographic risk: single Oklahoma City location, no documented alternate processing site (OIG 2013 rec #8 open as of 2019)

### 10.5 Integration Anti-Patterns
- **FTP for Form 337 flows** — unencrypted protocol still referenced in 2025 PIA
- **Batch nightly refresh** for public inquiry — 24-hour staleness
- **One-shot data exports** (USAS Portal) — no sustained sync
- Cross-system identity/demographic synchronization (DIWS/MSS ↔ CAIS) depends on batch jobs

### 10.6 Single Point of Failure Risks
- Single mainframe instance at MMAC
- Intermittent outages documented (OIG 2019)
- No alternate processing site historically; contingency planning weakness flagged in 2013 OIG rec #8
- PII encryption gap flagged in 2013 OIG rec #6 (target 12/31/2019 for closure)

### 10.7 Face-Value Document Acceptance
- Aircraft examiners do not verify authenticity of submitted documents against external sources
- GAO-20-164 documented fraud/straw-ownership vulnerabilities resulting from this posture

---

## 11. AI/GenAI Opportunities

### 11.1 TIFF Image Intelligence (highest-leverage)
- Run OCR + layout extraction across the 174M-image corpus
- Entity resolution: owner names, N-numbers, serial numbers, signatures
- Deduplication: multi-generational scans of the same document
- Full-text index enables CARES-era natural-language search
- Flag SPII that should be redacted (SSN fragments, DOB, medical info)
- Structured data back-fill: populate CARES entity tables from extracted image metadata

### 11.2 Natural Language Query over Registry Data
- GenAI chat layer over the combined structured (ADABAS/CARES) + unstructured (TIFF corpus) data
- Replaces paid PDR workstation intermediary for title search, ownership history, lien tracing
- Eliminates physical travel for LEAP/law-enforcement inquiries
- Supports both public inquiry and internal examiner use cases

### 11.3 Fraud Detection on Aircraft Registration
- Per GAO-20-164, registration fraud and straw-ownership remain vulnerabilities
- Model signals:
  - Cross-matching owner names/addresses against sanctions/watchlists
  - Shell-entity detection (repeated trustee patterns, recycled addresses)
  - Document-authenticity scoring (signature anomalies, forged notarizations)
  - Behavioral: rapid re-registration, unusual ownership chains
- Output: risk-based routing that automates low-risk approvals and focuses examiner attention on high-risk filings (directly addresses OIG 2019 rec #1)

### 11.4 Agentic Migration Assistant for IACRA → CARES
- LLM-backed assistant guides airman applicants and designees through CARES Phase 2 migration
- Form-aware: pre-fills from existing CAIS record, highlights deltas
- Handles transitional edge cases where IACRA and CARES coexist
- Reduces workforce burden during the 2025–2027 dual-run period

### 11.5 Additional Opportunities
- **Document classification at intake**: auto-categorize incoming mail into envelope/application/evidence-of-ownership/security-agreement
- **Examiner copilot**: surfaces relevant regulatory citations, similar prior filings, and completeness checks alongside each work packet
- **Public inquiry chat**: FAQ-level assistant that fronts the inquiry endpoints and handles Form 337, registration, renewal questions

---

## 12. Rationalization Recommendations

### 12.1 Keep
- **DOT/FAA 801 and 847 SORNs** — statutory framework is sound; recent 2023 update to 801 brings it current
- **NARA retention schedules** (N1-237-04-03 and N1-237-06-001) — appropriately calibrated to 60-year permanence needs
- **ICAO Annex 7 alignment** — non-negotiable treaty obligation
- **Pay.gov integration** — clean separation of payment PII; preserve in CARES
- **Releasable Airmen Download** — valuable public artifact; extend with CARES-era richer data model

### 12.2 Replace
- **Mainframe + NATURAL + ADABAS** → CARES (in progress; Phase 1 aircraft, Phase 2 airmen)
- **TIFF/IMS image store** → searchable document repository (PDF/A + OCR + extracted entities + full-text index)
- **FTP Form 337 pipeline** → authenticated, encrypted API with schema validation
- **Nightly inquiry batch refresh** → near-real-time API exposed to public and partners
- **PDR physical workstations** → authenticated web portal with tiered access; phase out PDR per OIG plan
- **Paper AC Form 8050-1** → electronic submission leveraging January 2025 rulemaking

### 12.3 Consolidate
- **Aircraft and Airmen branches** under a unified CARES data model where identity resolution crosses both domains
- **IACRA, AVS eForms, USAS Portal** → single designee/applicant-facing portal feeding CARES
- **Demographic sync** (DIWS/MSS ↔ CAIS) → event-driven identity service rather than batch reconciliation

### 12.4 Priority Actions (sequenced)

1. **OCR and entity-extract the TIFF corpus** — prerequisite for credible CARES data migration; standalone value even without full CARES cutover. (Target: begin within 6 months; unblocks everything downstream.)
2. **Replace FTP Form 337 flow** with authenticated API — low-risk, high-hygiene win; reduces ATO surface.
3. **Build fraud-detection tier** over structured registration data — directly addresses GAO-20-164 and OIG 2019 rec #1 (risk-based oversight).
4. **Expose real-time aircraft inquiry API** — technical prerequisite to PDR phase-out; must be delivered before CARES FOC to enable shutdown of Oklahoma City physical access.
5. **Stand up alternate processing site / DR capability** — closes the still-outstanding 2013 OIG rec #8 before CARES cutover concentrates more workload.
6. **Phase-out plan for NATURAL** — joint FAA/AIT program, skills transition, contractor ramp-down aligned to Phase 2 FOC.
7. **Agentic migration assistant** for dual-run 2025–2027 window — reduces workforce burden and accelerates stakeholder adoption.

### 12.5 Dependencies on Other Systems

| Dependency | Direction | Modernization Action |
|---|---|---|
| IACRA | IACRA → CAIS (airman intake) | Co-migrate to CARES Phase 2; retire FTP hop |
| AVS eForms | eForms → Aircraft Registry (Form 337) | Replace FTP with API; include in CARES intake pipeline |
| Pay.gov | Registry → Pay.gov | No change; preserve integration contract |
| TSA NTSDB | via IACRA | Preserve vetting hop; ensure CARES Phase 2 honors ordering |
| USAS Portal | Registry → USAS (one-time) | Convert to ongoing sustained sync under CARES if bidirectional use emerges |
| DIWS / MSS | CAIS ↔ demographic systems | Event-driven identity service under CARES |
| LEAP / Law enforcement | Registry → LEAP inquiries | Programmatic API + audit logging; retire PDR intermediation |
| PDR permit-holder companies | Commercial layer | Offer authenticated replacement; grandfather transition period |

---

## Document Provenance

- `research/rms/tech-profile.md` — prior baseline profile
- `research/rms/docs/rms-aircraft-registration-pia-2025.pdf` — 2025 DOT/FAA Privacy Impact Assessment for Aircraft Registration System (12 pp)
- `research/rms/docs/nara-n1-237-06-001-cais-schedule.pdf` — NARA Records Disposition Authority N1-237-06-001 for FAA Series 8060 Airman Records (5 pp)
- `research/rms/docs/oig-av2019052-registry-report.pdf` — DOT OIG Report AV2019052 (May 8, 2019), 29 pp
- `research/rms/docs/imtec-91-29.pdf` — GAO/IMTEC-91-29 (April 1991), 18 pp
- `research/rms/docs/ac-form-8050-1-registration.pdf` — AC Form 8050-1 Aircraft Registration Application (OMB 2120-0042)
