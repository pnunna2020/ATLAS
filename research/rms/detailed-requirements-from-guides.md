# RMS Detailed Requirements — Extracted from OIG Report, NARA Schedule, and AC Form 8050-1

Scope: deeper requirements pulled from three source documents already in `research/rms/docs/`:
- `oig-av2019052-registry-report.pdf` — DOT OIG audit of the Civil Aviation Registry (May 2019), 29 pages
- `nara-n1-237-06-001-cais-schedule.pdf` — NARA records-disposition schedule for airman records, 5 pages
- `ac-form-8050-1-registration.pdf` — Aircraft Registration Application (AC Form 8050-1, 04/24 revision), 3 pages

These supplement `research/rms/functional-requirements.md` and `current-state-analysis.md` with primary-source evidence.

---

## 1. System Landscape and Scale (OIG AV2019052)

The Civil Aviation Registry consists of two functional branches — **Aircraft Registration Branch** and **Airmen Certification Branch** — both running on the same underlying platform.

### 1.1 Current system (RMS)

- **Name:** Registry Modernization System (RMS). OIG defines RMS as "a group of IT systems that the Registry uses to support aircraft registration and airmen certification and the electronic storage of registration records."
- **Platform:** Mainframe-based.
- **Language:** NATURAL programming language.
- **Last significant upgrade:** 2008 (≥10 years before the 2019 audit).
- **Known problems:** approaching end of service life, intermittent outages, outdated language, cannot support online access outside the Oklahoma City Registry offices.

### 1.2 Replacement system (CARES)

- **Name:** Civil Aviation Registry Electronic Services (CARES).
- **Statutory driver:** 2018 FAA Reauthorization Act (Pub. L. 115-254) — **modernize the Registry by October 2021**.
- **Funding:** F&E account eligible per statute; FAA also considering O&M per its Acquisition Management Policy. Funding source had not been selected at audit time.
- **Intended capabilities (per FAA):** streamline/automate processes, allow electronic form submission, improve online data availability, add security controls (including cross-checks against non-DOT databases).

### 1.3 FY2018 workload baseline (FAA's own numbers, cited in agency response)

- 400,000+ airmen certificates issued
- 89,000+ telephone inquiries answered
- 31,000+ emails responded to
- 667,000+ aircraft documents processed
- 200,000+ aircraft registered
- 90,000+ requests for information

Registry holdings as of audit: **~300,000 aircraft records**, **~1.5 million airman records**, **25 million documents**, **174 million image files** (predominantly TIFF).

---

## 2. OIG-Identified Capability Gaps and Decision Points

CARES requirements work identified the following open decisions that the modernization must resolve (extracted verbatim from "FAA Faces Key Decisions Before Modernization Can Proceed"):

### 2.1 Risk-based oversight and increased automation

- Current state: Registry examiners review **100% of documents submitted** — the primary driver of the aircraft-registration backlog.
- Target state: automated approvals for **low-risk applications** (example given: single-owner low-risk general aviation aircraft).
- Requirement implication: CARES must implement a risk-scoring layer with detailed system rules to validate submission accuracy; examiner work shifts to exception review.

### 2.2 Fraud/accuracy controls

- Current state: aircraft examiners accept documents **at face value**, without independent verification.
- Requirement implication: CARES must introduce verification logic to detect fraudulent or incorrect submissions. (Airmen data, by contrast, is already vetted by TSA and automated validation before it reaches RMS.)

### 2.3 Security controls

Open capabilities FAA indicated interest in:
- Requiring aircraft owners to submit additional identifying information.
- Cross-checking aircraft registration data with non-DOT databases prior to acceptance.
- Business-intelligence/anomaly-detection software to detect application errors.

### 2.4 Registry structure

- FAA had not decided whether to keep Aircraft and Airmen as separate branches or merge them under CARES. This is a core architecture decision that shapes the data model.

### 2.5 Data storage

- Cloud vs. server not decided. OMB "Cloud First" (2011) applies. Considerations called out: integration with external government agency data feeds; sensitive-data security requirements.

### 2.6 Data transition

- **25M documents, 174M image files** must be migrated.
- Large share stored as **TIFF** — explicitly called out as large, not text-searchable.
- Open: whether to convert to a more compact, searchable format; whether to run OCR over legacy images (time and storage impact flagged).

### 2.7 Rulemaking dependency

- 14 CFR Parts 47 and 49 do not reflect current technology (e.g., digital signatures, electronic payments, online form submission).
- FAA was developing a rulemaking to revise Parts 47 and 49 but had no timeline; DOT/OMB review process and mandatory public-comment period apply.
- Example cited: the FAA registration-fee rulemaking (raise aircraft registration fee from $5 to $22; add $229 legal-review fee for certain filings) has been on the Unified Agenda since Fall 2016 and was still not published for comment in 2019.
- **Dependency:** CARES capability set is bounded by rulemaking completion. If rulemaking lags, CARES must either ship without those capabilities or delay.

### 2.8 Stakeholder feedback mechanism

- No formal procedure existed for collecting stakeholder input on CARES scope. Key external stakeholders named:
  - Aircraft title companies
  - Financial institutions
  - Aircraft manufacturers
  - Airmen
  - Other government agencies (federal, state, local)
  - Industry groups named in the audit: **NATA, NBAA, AATL** (Association of Aircraft Title Lawyers)
- Permit-holder companies interviewed included **AEROTitle, Dixie Aire, Wright Brothers, Insured Aircraft Title, AIC Title**.

---

## 3. OIG Recommendations (FAA Concurred — All 4)

These are now binding on the modernization program:

| # | Recommendation | FAA committed completion date |
|---|---|---|
| 1 | Develop and implement a **timeline for key CARES decisions** (requirements, one system vs. two, cloud vs. server, risk-based policies, automation scope) | 2019-05-31 |
| 2 | **Define desired capabilities** technologically feasible within the timeline, **in consultation with AIT** (Office of Information Technology) | 2019-12-31 |
| 3 | Develop and implement a **procedure to obtain feedback on CARES from internal and external stakeholders** | 2019-10-31 |
| 4 | Develop and implement a **plan for maintaining real-time access to aircraft registration data prior to any PDR closure** | 2019-06-30 |

Carryover items from the 2013 OIG audit that were still open at 2019 audit time:
- Rec 4 — IRTPA pilot-certification provisions (open; target 2020-12-31)
- Rec 6 — Encrypt PII, mitigate vulnerabilities on Registry computers (open; target 2019-12-31)
- Rec 8 — Alternate processing site + contingency tests (open; target 2019-12-31)

Closed items (for context on what RMS already delivered): periodic data-integrity reassessments (2017), trust-registration policy (2015), airman-address currency (2017), access monitoring + MFA on Registry (2018), FISMA compliance for contractor systems (2017).

---

## 4. Public Documents Room (PDR) — Real-Time Access Model to Replace

The PDR is the user-facing artifact of RMS's inability to serve real-time data online. CARES must replace it.

### 4.1 Facts from the audit

- Location: Registry Building, Mike Monroney Aeronautical Center, Oklahoma City, OK.
- **47 workstations** as of June 2018: 42 held by permit holders, 2 vacant, 3 reserved for public use.
- **24 permit-holder companies**; a single company may hold multiple permits but **no more than 3 workstations**.
- Lottery system exists but has never been used.
- Permit fee: **$3,441 per year per permit** (covers workstation, hardware, software licenses, PDR attendant).
- Revenue flow: space fees fund Registry service contracts; record-access fees offset FAA's Registry IT costs.
- Termination: FAA may terminate a permit with **30 days' notice**.
- Public access: **2 days' advance notice for U.S. citizens, 3 weeks for international users**; background check required before access to a government computer.
- CY2017 public use was very low: **only 10 non-permit holders** used the PDR.
- FY2017 mail-out channel: **15,000 CDs** of aircraft records mailed.
- Authority for permits: 49 U.S.C. 106; fee authority: 31 U.S.C. § 9701 and 49 U.S.C. § 106(l)(6).

### 4.2 Current online channel (gap being addressed)

- The public website exposes aircraft information but updates **once per day**, not real-time.
- Export filings get priority processing regardless of permit status.

### 4.3 CARES real-time access requirements (derived from Rec 4 + stakeholder input)

- Real-time aircraft data must be available online outside Oklahoma City.
- Transactional users (title companies, lenders, brokers) need live ownership status prior to closing a sale, lease, or export. This is the primary driver for real-time.
- PDR cannot be phased out until CARES delivers that capability.

---

## 5. Airman Data Model — CAIS Field Inventory (NARA N1-237-06-001)

NARA Job N1-237-06-001 approves the Registry's disposition authority for airman records. The Master Files description is the authoritative field inventory for the **Comprehensive Airmen Information System (CAIS)** — the airmen-side master file that RMS maintains and CARES must replace.

### 5.1 CAIS master-file fields (FAA Item 8060.1.b.1)

**Airman identification:**
- Name
- Social Security Number
- Birth date
- Height, weight
- Hair color, eye color
- Gender
- Nationality
- Place of birth

**Contact information:**
- Mailing address
- Physical address
- Email address

**Certification information:**
- Certificate type, level, and number
- Ratings
- Limitations
- Date certificate issued
- Names of test administrators
- Names of flight instructors
- Information about enforcement actions

### 5.2 Inputs — the source records that feed CAIS

Per FAA Item 8060.1.a.1, Airman Certification Files include:
- Certification applications
- Temporary airman certificates
- Knowledge test results
- Notices of disapproval
- Enforcement actions
- Correspondence on replacement certificates and record changes
- Student Pilot Certification Files (formerly a separate item, now filed with Airman Certification Files per FAA Item 8060.2)

### 5.3 Retention requirements (must carry into CARES)

| Record class | Disposition |
|---|---|
| Original paper records (8060.1.a.1.a) | Destroy when digital/microfilm copy is an adequate substitute for the original |
| Microfilm (not digitized) (8060.1.a.1.b.1) | Cut off annually; destroy when 60 years old or no longer needed, whichever is later |
| Microfilm (digitized) (8060.1.a.1.b.2) | Destroy when the digital copy is an adequate substitute |
| Digital image copies + indices (8060.1.a.1.c) | Cut off annually; destroy 60 years after cutoff or when no longer needed |
| Born-digital records (8060.1.a.1.d) | Cut off annually; destroy 60 years after cutoff or when no longer needed |
| CAIS master file (8060.1.b.1) | Delete records when the information is **at least 60 years old** or no longer needed, whichever is longer |
| Outputs (reports, certificates, document copies) (8060.1.c) | Destroy when no longer needed for agency business |
| Documentation (specs, codebooks, layouts, user guides) (8060.1.d) | Destroy when superseded/obsolete, or upon authorized deletion of the master file, or upon destruction of output needed to protect legal rights — whichever is latest |
| Foreign License Verification Files (8060.6) | Cut off at end of calendar year of verification; destroy **6 months after cutoff** |
| Enforcement Records electronic + indices (2150.5.a) | Destroy suspension and civil-penalties records and associated indices **5 years after case is closed in EIS** |

### 5.4 Retention system requirements for CARES

- 36 CFR 1234.30 and 1234.32 compliance applies to digital image copies and born-digital records **for the entire retention period** (FAA agreed to this in the schedule).
- Annual cutoff automation required for four separate record classes.
- 60-year destruction clock on both airman master-file records and digital images.
- Separate 5-year retention path for Enforcement Records tied to EIS case-closure events; requires integration with the Enforcement Information System (EIS) to get the closure signal.
- Indices pertaining to Enforcement Records follow the Enforcement Records schedule, not the main airman schedule — CARES metadata model must track lineage so the right schedule applies.

### 5.5 Statutory basis

NARA schedule cites **49 U.S.C. §§ 44703, 44709, 44710** as the authority for maintaining the U.S. Civil Airmen Register. CARES must continue to satisfy these sections.

---

## 6. Aircraft Registration Application Data Model (AC Form 8050-1, 04/24)

Form 8050-1 is the statutorily required entry point for aircraft registration under 14 CFR Part 47. Its field list is the minimum data model CARES must capture online.

### 6.1 Form metadata

- OMB Control Number: **2120-0042**
- Expiration: 2025-10-31 (form must be recertified)
- PRA burden estimate: ~30 minutes per response
- SORN: **DOT/FAA 801, Aviation Registration System** (88 FR 53951, 2023-08-09)
- Online submission URL referenced on the form itself: **CARES.FAA.gov**
- Paper-submission addresses remain:
  - USPS: FAA Aircraft Registration Branch, P.O. Box 25504, Oklahoma City, OK 73125-0504
  - Courier: 6425 S Denning Avenue, Oklahoma City, OK 73169

### 6.2 Required data fields

| # | Field | Notes |
|---|---|---|
| 1 | U.S. Registration Number (N-number) | |
| 2 | Aircraft Manufacturer | |
| 3 | Aircraft Model | |
| 4 | Aircraft Serial Number | |
| 5 | Type of Registration (checkbox, one of: 1-Individual, 2-Partnership, 3-Corporation, 4-Co-Owner, 5-Government, 7-LLC, 8-Non-Citizen Corporation, 9-Non-Citizen Corporation Co-Owner) | Note: option 6 is absent from the form; CARES must faithfully mirror the enumeration |
| 6 | Name(s) of Applicant(s) | Individual: last, first, middle initial |
| 7 | Telephone Number | |
| 8 | Email Address | |
| 9 | Mailing Address | Number/street, apt/suite, rural route, P.O. Box, city, state (or foreign province/state/country), ZIP |
| 10 | Physical Address/Location | Required when PO Box, mail drop, or rural route used for mailing; includes description-of-location field |
| 11 | Change-of-Address checkbox | |
| 12 | Certification | Must check one of (a) U.S. citizen per 49 USC 40102(a)(15); (b) resident alien with Form I-551; (c) non-citizen corporation organized under laws of [state], aircraft based and primarily used in U.S., flight-hour records available at [physical address]; (d) corporation using a voting trust to qualify, with trustee name |
| 13 | Signature block for first applicant | Digital or ink signature, date, typed/printed name of signer, title |
| 14–17 | (Page 2) Restatement of N-number, manufacturer, model, serial | Page 2 reprises identifiers for multi-applicant signatures |
| 18–26 | Additional applicant signature blocks (co-ownership) | Nine additional signature blocks on page 2 |

### 6.3 Required behaviors and legal warnings CARES must carry online

- **Incomplete submission returned to applicant** — form explicitly requires all data and signatures.
- **Digital signatures acceptable** on this revision (resolves a gap OIG flagged around Parts 47/49 modernization).
- **If co-ownership, all applicants must sign.**
- **Change of address must be reported within 30 days.**
- **Temporary authority to operate (14 CFR 47.31(c))**: applicant must carry a copy of the signed application in the aircraft; validity expires on issuance of certificate, denial, or by the paragraph (c)(2) limits. Not available when 12 months have passed since receipt of the first application following transfer of ownership by the last registered owner. CARES must generate and return a printable/displayable signed-application copy.
- **Citizenship evidence for non-citizen corporations**: CARES must support attachment of a certified copy of the certificate of incorporation.
- **Evidence of ownership**: AC Form 8050-2 (Aircraft Bill of Sale) or equivalent, or contract of conditional sale. If applicant didn't purchase from the last registered owner, CARES must accept conveyance documents that complete the chain of ownership.
- **Recording fee** applies when a conditional sales contract is submitted as evidence of ownership (14 CFR 47.17, 14 CFR 49.15).
- **Required penalty language on any signature capture UI** — 18 U.S.C. §§ 1001 and 3571 (up to $500,000 fine or 5 years imprisonment for falsification), 49 U.S.C. § 46306 (criminal prosecution + registration delay/denial/revocation for knowingly false/inaccurate submissions).

### 6.4 SORN routine uses CARES must preserve

Per DOT/FAA 801 (88 FR 53951, 2023-08-09), disclosure permitted to:
- The public (including government entities, title companies, financial institutions, international organizations): owner's name, address, U.S. Registration Number, aircraft type, legal documents related to title/financing, ADS-B summary reports.
- Carve-out: **sUAS owner emails and phone numbers registered under 14 CFR Part 48 are NOT disclosed to the public** under this routine use — CARES must enforce this field-level suppression.
- Law enforcement for FAA enforcement activities.
- Government agencies (Fed/State/Tribal/local/foreign) for investigation or threat detection in connection with critical infrastructure.

---

## 7. Regulatory Authorities — Complete Reference Set

Pulled from the three source documents; these are binding on any CARES design:

**Statutes:**
- 44 U.S.C. § 3303a — NARA records disposition authority
- 49 U.S.C. § 106 — FAA authority to enter agreements, charge fees
- 49 U.S.C. § 106(l)(6) — fee authority
- 49 U.S.C. § 40102(a)(15) — U.S. citizen definition
- 49 U.S.C. §§ 44703, 44709, 44710 — U.S. Civil Airmen Register basis
- 49 U.S.C. § 46306 — penalties for false registration statements
- 31 U.S.C. § 9701 — fee authority
- 18 U.S.C. §§ 1001, 3571 — false-statement penalties
- 5 U.S.C. § 552a — Privacy Act
- Pub. L. 115-254 (2018 FAA Reauthorization Act) — Oct 2021 Registry modernization mandate; paper-transaction surcharge; Registry open during shutdown; 7-year noncommercial general-aviation registration rulemaking

**Regulations:**
- 14 CFR Part 47 — Aircraft registration
- 14 CFR Part 48 — sUAS registration (special disclosure rules)
- 14 CFR Part 49 — Conveyances, leases, security instruments
- 14 CFR Parts 61, 63, 65 — Airman certification
- 14 CFR 47.17 — Registration fees
- 14 CFR 47.31(c) — Temporary operating authority from application
- 14 CFR 49.15 — Recording fees
- 36 CFR 1234.30, 1234.32 — Electronic records storage requirements
- 36 CFR 1228 — NARA records disposition

**Executive / policy:**
- E.O. 12866 — OMB review of proposed regulations
- DOT Order 2100.5 — OST concurrence on significant regulations
- OMB Digital Government Strategy (2012-05-23)
- White House Cloud First Policy (2011-02-08)
- GAO Report 12-7, "Critical Factors Underlying Successful Major Acquisitions"
- FAA Order 1350.15C (cited as the schedule-numbering reference for the NARA authority)
- FAA Order 1280.1B (cited in 2013 PII remediation recommendation)
- FAA Acquisition Management Policy

---

## 8. Cross-Cutting Integration Requirements

Derived by intersecting the three documents:

1. **EIS integration.** Enforcement Records follow a separate 5-years-after-closure retention schedule (NARA 2150.5.a), while enforcement information appears as a CAIS data field (8060.1.b.1). CARES needs an integration with EIS to retrieve closure events and to maintain the bi-directional enforcement-status link.

2. **Airmen-side pre-Registry vetting pipeline.** OIG specifically notes Airmen processing is already more automated because TSA security reviews and automated validation occur **before** Registry ingest. CARES must preserve the inbound pipeline: TSA vetting gate, automated data validation, then Registry ingest.

3. **External database cross-checks for aircraft.** OIG recommends cross-checking aircraft registrations against non-DOT databases before acceptance. Candidates implied in the audit: law-enforcement databases, threat-detection feeds, international organization data.

4. **Title-industry real-time access.** Twenty-four permit-holder companies, almost all aircraft title companies or law firms, currently depend on PDR workstations for live data. CARES must offer a role-based real-time access path that replaces the PDR permit model.

5. **PII handling for sUAS Part 48 owners.** CARES must field-level-suppress email and phone number from public disclosure for Part 48 registrants, while preserving those fields for law enforcement and internal use.

6. **Field consistency with AMCS/MedXPress.** CAIS captures airman identification attributes (height, weight, hair color, eye color, gender, nationality, birthplace) that overlap with medical-system identity fields. CARES identity model should align with AMCS to avoid duplicative applicant-maintained records.

7. **60-year retention across all storage tiers.** Digital storage architecture must support 60-year lifecycle management on born-digital, digital-image, and indexed-microfilm record classes, with annual cutoff automation.

8. **Document conversion from TIFF.** 174M TIFF files require a conversion strategy; if OCR is applied, storage and processing cost grows significantly. This is called out explicitly as an unmade decision and must be an explicit CARES requirement.

---

## 9. Gaps / Items Requiring Additional Source Material

The three PDFs processed here do not cover:

- **CARES detailed technical design** — post-2019 documentation (solicitation materials, PWS, SORN revisions) needed for current requirements baseline.
- **AC Form 8050-2 (Aircraft Bill of Sale)** — referenced as mandatory evidence of ownership but not in the extracted set.
- **Conveyance, security-instrument, and lease forms** filed under 14 CFR Part 49 — not in extracted set.
- **EIS data model** — only referenced; needed for the enforcement-closure integration.
- **FAA Order 1350.15C** full text — the records-management order that governs item numbering; extracted only by reference.
- **14 CFR Part 48 sUAS registration data model** — referenced only by the disclosure carve-out.

These should be added to `research/rms/docs/` and a follow-up extraction performed before finalizing CARES requirements.
