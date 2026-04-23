# FAA AVS Airmen/Aircraft Certification Portfolio — Rationalization Research Pack

**Prepared for:** Portfolio rationalization challenge (BAH / FAA AVS)
**Scope:** Registry Modernization System (RMS), MedXPress (MSS), IACRA, Designee Management System (DMS), plus the CARES replacement umbrella.
**Angle:** Maximum engineering depth — tech stack, data elements, APIs, integrations. Contract/vendor and capture signals are included where they informed the architecture.
**Sources:** Linked inline and in Appendix A. All content is from public government PIAs, OIG reports, NARA schedules, Federal Register notices, and FAA public documentation.

---

## 0. Executive Summary — What This Portfolio Actually Is

The four systems on the slide are **not peers**. They are snapshots of a 25-year modernization attempt that produced a brittle, hub-and-spoke architecture around a single mainframe repository. Rationalization has to be framed in that history:

| System | Role | Layer | Age | Modernization Path |
|---|---|---|---|---|
| **RMS** | Umbrella label for Registry mainframe + surrounding subsystems (CAIS, IMS) | **System of record** | Last major upgrade 2008; runs on NATURAL/ADABAS mainframe | Being replaced by **CARES** (Phase 2 FOC Fall 2025; full replacement Fall 2027) |
| **IACRA** | Front-end for airman cert applications (electronic 8710-1 et al.) | **Intake / temporary repository** | In production since ~2008 | ATO 2022; **to be subsumed into CARES Phase 2** |
| **MedXPress** | Applicant-facing medical application portal | **Intake** for medical data, part of MSS umbrella (MedXPress + AMCS + DIWS + CPDSS + CHAPS/EMRS + DSS) | Launched 2007, built on top of AMCS (1999) | No announced replacement; MSS is its own silo |
| **DMS** | Designee lifecycle management (DPE, AME, DME, DAR, TCE, DER, etc.) | **Identity / authority** layer for FAA's ~17 designee categories | Launched to consolidate ~9 predecessor systems (post-GAO-05-40) | Mature; absorbing DRS training functions in 2025-2026 |

**The core rationalization truth:** three of the four (RMS, IACRA, MedXPress) are **intake funnels into the same mainframe repository** — CAIS (Comprehensive Airmen Information System). The fourth (DMS) is the authority graph that tells the other three *who is allowed to sign what*. CARES is the project to collapse CAIS + IACRA + the public inquiry apps into one cloud-native system. MedXPress/MSS has a separate destiny because medical records have a different SORN (DOT/FAA 856) and 50-year retention regime.

**The integration graph is the rationalization artifact that matters.** Seven internal systems exchange data with this cluster; at least four external dependencies (TSA NTSDB, Atlas Aviation, Pay.gov, DocuSign) are active. Decommissioning RMS without mapping these first will strand downstream consumers.

---

## 1. Architecture at a Glance

### 1.1 The four systems in context

```
                          PUBLIC / APPLICANT TIER
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │  MedXPress   │   │    IACRA     │   │   designee.  │   │   cares.     │
    │  medxpress.  │   │  iacra.      │   │   faa.gov    │   │   faa.gov    │
    │  faa.gov     │   │  faa.gov     │   │   (DMS)      │   │   (new)      │
    └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
           │                  │                  │                  │
           │                  │                  │                  │
       ┌───▼────────┐     ┌───▼────────┐         │                  │
       │   AMCS     │     │ (TIFF over │         │              ┌───▼────────┐
       │  amcs.faa. │     │ secure FTP)│         │              │  MyAccess  │
       │  gov (AME) │     │            │         │              │ (identity) │
       └───┬────────┘     │            │         │              └────────────┘
           │              │            │         │
    ┌──────▼──────────────▼────────────▼─────────▼──────┐
    │                INTERNAL SYSTEMS                     │
    │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐ │
    │  │ DIWS │  │ CAIS │  │ CPDSS│  │ FSTW │  │ SAS  │ │
    │  └──┬───┘  └──┬───┘  └──┬───┘  └──────┘  └──────┘ │
    │     │        │         │                           │
    │  ┌──▼────────▼─────────▼──┐   ┌────────┐  ┌──────┐ │
    │  │ RMS mainframe         │   │ eFSAS  │  │NACIP │ │
    │  │ (NATURAL / ADABAS)    │   └────────┘  └──────┘ │
    │  │ 25M docs, 174M images │                        │
    │  └───────────────────────┘                        │
    └──────────────────────────────────────────────────┘
                      │
                      ▼
             EXTERNAL: TSA (NTSDB), Atlas Aviation,
             Pay.gov, DocuSign, USAS Portal, NDR
```

### 1.2 Ownership and org (for capture/escalation mapping)

All systems are managed under **FAA Aviation Safety (AVS)**, but across three sub-orgs:

- **AVS / Office of Aerospace Medicine (AAM)** — owns MSS (MedXPress, AMCS, DIWS, CPDSS, CHAPS/EMRS, DSS). Responsible official: Kelly Merritt, AAM-300, (405) 954-3815. Location: Civil Aerospace Medical Institute (CAMI), MMAC.
- **AVS / Flight Standards Service / Office of Foundational Business / Airmen Certification Branch AFB-720** — owns IACRA + AVS Registry (RMS/CAIS). Responsible official for the Airmen Certification System: Jay Tevis, (405) 954-0571.
- **AVS / Aviation Data Systems Branch** — owns DMS. Responsible official: Linda Navarro, (405) 954-9808.
- **Registry Services and Information Management Branch** — owns CARES. Point of contact: Craig Whitbeck, (405) 954-3131 (per Federal Register Jan 2025).
- Civil Aviation Registry Division Manager (historical PIA signer): Gerald A. Boots. Another: Debra J. Entricken.

All based at **Mike Monroney Aeronautical Center (MMAC), 6500/6425 S MacArthur Blvd / S Denning, Oklahoma City, OK 73125-73169**.

---

## 2. System Deep Dive: RMS (Registry Modernization System) — including CAIS and IMS

### 2.1 What RMS actually is

"RMS" is **not a single system**. It is a label the FAA uses for the group of IT systems the Registry uses to support aircraft registration and airman certification. The OIG 2019 report (AV2019052) is explicit:

> "RMS is the term for a group of IT systems that the Registry uses to support aircraft registration and airmen certification and the electronic storage of registration records."

The two sub-components you'd encounter most in real work:

- **CAIS — Comprehensive Airmen Information System.** The airman master data file. This is the authoritative record for every certificated airman in the US.
- **IMS — Image Management System.** The document/image repository for scanned registration and certification records.

### 2.2 Technology stack (confirmed from public sources)

| Layer | Detail | Source |
|---|---|---|
| **Platform** | Mainframe computer-based | OIG AV2019052 |
| **Programming language** | **NATURAL** (Software AG) | OIG AV2019052, footnote 10 |
| **Database** | Implied **ADABAS** (the standard pairing with NATURAL — Software AG's mainframe stack) | Strong inference — Software AG's NATURAL is almost exclusively deployed against ADABAS |
| **Last major upgrade** | 2008 | OIG AV2019052 |
| **Document format** | **TIFF** images (not easily searchable; large file size) | OIG AV2019052 |
| **Volume (2018-2019)** | ~25 million documents, ~174 million image files, 300K aircraft, 1.5M airmen | OIG AV2019052 |
| **Throughput (FY2018)** | 400K+ airman certs issued; 667K aircraft docs processed; 200K aircraft registered | OIG AV2019052 Appendix |
| **ATO** | AVS Registry: April 20, 2022; NIST 800-53 Rev 5 | Airmen Cert System PIA 2025 |
| **Known weaknesses** | Intermittent outages; no OCR; no real-time public access (real-time requires physical PDR terminal in Oklahoma City); 6-week backlog on aircraft reg processing | OIG AV2019052 |

**Engineering implication:** Any modernization has to deal with TIFF conversion at scale (174M images). OCR was not applied to legacy records and would "time-consuming and significantly increase storage requirements" per OIG. This is a prime AI/GenAI entry point — **document intelligence on the TIFF corpus is the single largest greenfield opportunity**.

### 2.3 CAIS data dictionary (from NARA schedule N1-237-06-001)

This is the master file schema. NARA-approved records schedule explicitly enumerates fields in CAIS:

**Airman identification:**
- Name
- Social Security Number (legacy — many certs historically used SSN as certificate number; discontinued for new issues June 2002)
- Birth date
- Height, weight
- Hair color, eye color
- Gender (Sex)
- Nationality
- Place of birth

**Contact:**
- Mailing address
- Physical address
- Email address

**Certification:**
- Certificate type
- Certificate level
- Certificate number
- Ratings
- Limitations
- Date certificate issued
- Names of test administrators
- Names of flight instructors
- Enforcement action information

**Retention:** 60 years after annual cutoff (NARA schedule N1-237-06-1).
**Documentation:** Data systems specifications, file specifications, codebooks, record layouts, user guides, and output specifications are themselves retained per GRS 20 item 11.a.

### 2.4 Why RMS is hard to replace (not obvious from the slide)

1. **Aircraft registration is still substantially paper-based.** Users reserve N-numbers online, but FAA **prints the request and manually enters it into RMS** (OIG footnote 13 notes this was stated to be "now automated" in technical comments, but the core pattern held).
2. **Airmen Registry is more automated than Aircraft Registry** because TSA security reviews and automated validation occur *before* the Registry receives data. This bifurcation matters for rationalization — the airmen side has more of a paved path than the aircraft side.
3. **Rulemaking is coupled with IT.** 14 CFR Parts 47 and 49 (aircraft) were updated Jan 17, 2025 (Federal Register 2025-00763 and 2025-00764) specifically to remove paper-document/stamping requirements that blocked full digital workflows in CARES.
4. **PDR (Public Documents Room) is a legal/physical dependency.** Real-time data access is gated through 47 workstations in Oklahoma City, 42 occupied by 24 permit-holding title/law firms. FAA can't phase out the PDR until CARES gives real-time remote access.

### 2.5 Public inquiry endpoints built on RMS

These are the externally-facing read-only surfaces:

- **Airmen Inquiry:** https://amsrvs.registry.faa.gov/airmeninquiry/ (search by name/address; no SSN/cert number search)
- **Aircraft Inquiry:** https://registry.faa.gov/aircraftinquiry/ (daily-refreshed aircraft registration data)
- **Airmen Services (applicant login):** https://amsrvs.registry.faa.gov/amsrvs/ (address change, temp cert request, replace cert, remove SSN as cert number)
- **Aircraft Registration Renewal:** https://amsrvs.registry.faa.gov/renewregistration/
- **Active Airmen totals:** https://registry.faa.gov/activeairmen/
- **Certificate validity check:** https://aie-pa.faa.gov/
- **Downloadable releasable airmen DB:** https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download (monthly; fixed-length ASCII or CSV)
- **Aviation Data Systems Branch contact:** 9-amc-afs620-pa@faa.gov

The downloadable DB is the closest thing to a public API — monthly dumps in TXT/CSV, deliberately excludes cert numbers and opt-out addresses. Commercial resellers (AviationDB, FlightAware) rebuild richer services on top.

### 2.6 SORNs governing RMS/CAIS

- **DOT/FAA 847 — "Aviation Records on Individuals"** — 89 FR 48956 (June 10, 2024) — republished in 2024 to cover *only* airmen certification and training records (aircraft split into its own PIA).
- **DOT/FAA 801 — "Aircraft Registration System"** — 81 FR 54187 (August 15, 2016).
- **DOT/ALL 13 — "Internet/Intranet Activity and Access Records"** — 67 FR 30758 (May 7, 2002).

---

## 3. System Deep Dive: MedXPress (and the full MSS umbrella)

### 3.1 The slide is incomplete — MedXPress is one of six subsystems

The slide shows MedXPress standalone. In reality it is the applicant-facing front door to **Medical Support Systems (MSS)**, which consists of:

| Subsystem | URL | Audience | System Access |
|---|---|---|---|
| **MedXPress** | https://medxpress.faa.gov/medxpress/ | Applicants (pilots, ATCS candidates) | Username/password, security questions |
| **AMCS** (Aerospace Medical Certification Subsystem) | https://amcs.faa.gov | ~5,000 AMEs + FAA Flight Surgeons | Username/password (managed via Support Desk) |
| **DIWS** (Document Imaging Workflow System) | Internal — FAA network only | FAA medical staff (CAMI, Regional Flight Surgeons, HQ) | PIV card |
| **CPDSS** (Covered Position Decision Support Subsystem) | Internal interface to DIWS | FAA Flight Surgeons + authorized AAM | PIV card |
| **CHAPS** (Clinic Health Awareness Program Subsystem) | Internal | FAA occupational health | Being replaced by **EMRS** (Electronic Medical Records System) — planned replacement Aug 2023 |
| **DSS** (Decision Support Subsystem) | Internal | Research | Historical archive, PII-stripped |

Document of record: **MSS PIA, June 2023** — covers MedXPress, AMCS, DIWS, CPDSS (CHAPS has its own separate PIA; DSS has no PIA because no PII).

**ATO:** MSS received ATO on **November 15, 2021**. Categorized as **FIPS 199 HIGH**.

### 3.2 MedXPress technical details

- Web application, user creates account with name + email + 3 security questions (user-authored answers).
- Submits items 1–20 of **FAA Form 8500-8** (Application for Airman Medical Certificate; OMB Control 2120-0034).
- Applicant generates a **confirmation number** → carries this to the AME at exam time.
- Data retention: MedXPress **auto-deletes** applications not completed in 30 days, and expires them if exam is not scheduled within 60 days. Once transmitted to AMCS, only account + personal info stays in MedXPress.

**Built on top of AMCS (which launched Oct 1, 1999).** This is a 25+ year old intake chain.

### 3.3 Identifier taxonomy (MSS)

This is the part that matters most for integration:

| Identifier | Generated by | Purpose | Retained in |
|---|---|---|---|
| **Confirmation Number** | MedXPress | Short-lived handoff to AME | MedXPress, expires |
| **Applicant ID** | AMCS (on first import from MedXPress) | Lifetime unique airman identifier | DIWS (permanent) |
| **MID** (Medical ID) | MedXPress | Unique per exam (different for each exam submitted) | DIWS (official system of record) |
| **PI Number** | Assigned only when applicant has specific pathology | Lifetime pathology marker | DIWS |
| **IP Address** | Captured at submission | Electronic signature / anti-fraud | DIWS |
| **SSN / pseudo-SSN** | Voluntary; pseudo-SSN generated if refused/foreign | Deduplication across systems | DIWS |
| **AME Serial Number** | FAA | AME identity | DMS, AMCS |
| **SODA Serial Number** | FAA | Statement of Demonstrated Ability | AMCS, DIWS |

### 3.4 Data elements collected

**MedXPress (applicant entry):**

- Class of medical certificate / Applicant ID (for ATCS)
- Personal: name, DOB, SSN/pseudo-SSN, mailing address, phone, citizenship, hair color, eye color, sex
- Prior cert: airman certificate type, occupation, employer, prior denial/suspension/revocation, total pilot time, pilot time in past 6 months, date of last FAA medical application
- Health: medication use, contact lens use while flying, full medical history checkbox panel, list of health professional visits (date, name, address, type, reason), free-text notes field
- Arrest history: arrest/conviction, administrative actions

**AMCS (AME-captured physical exam, in addition to above):**

- Height, weight, SODA data
- 20+ body system fields: Head/face/neck/scalp; Nose/sinuses/mouth/throat; Ears; Eyes (ophthalmoscopic, pupils, ocular motility); Lungs/chest; Heart/vascular; Abdomen/viscera/anus; Skin; G-U; Upper/lower extremities; Spine/musculoskeletal; Body marks/scars/tattoos; Lymphatic; Neurologic; Psychiatric; General systemic; Hearing; Vision (distant, near, intermediate, color sense, field of vision, heterophoria); Blood pressure/pulse; Urine test; ECG (attached as PDF if administered)
- Disposition (issue/deny/defer), disqualifying defects, exam certification

**DIWS (supplemental intake):**

- Scanned supplemental medical docs (outpatient charts, specialty consults, operative reports, ER/hospital records, diagnostic imaging, pathology, lab studies)
- Tier 1 and 2 psychological testing documentation (ATCS)

**CPDSS (ATCS-specific, from Form 3900-7):**

- ATCS name, AME name/signature, medical clearances, corrective lenses info

### 3.5 MSS data exchanges (from MSS PIA)

| Direction | System | Data Sent | Data Received |
|---|---|---|---|
| **Bidirectional** | **CAIS** (RMS subsystem) | Name, optional SSN, address, height, weight, hair/eye color, sex, citizen code, exam date, MID, AME number, hearing, vision, ECG date, pathology codes, medications, medical history, cert number, BP info, previous MIDs | Demographic info, name, SSN, address |
| **Outbound** | **Investigation Tracking System (ITS)** | Encrypted file: name, suffix, SSN, DOB, sex, height, weight, state, eye color — for comparison against **National Driving Record (NDR)** | — |
| **Bidirectional** | **DMS** | AME performance metrics: total exams per class, decisions (deferred/denied), time to schedule/conduct, error counts/types, time to submit results, late exam details, error code descriptions | AME profile: designee #, DOB, name, address, phone, email, medical specialty, degree, appointment date, clinic name/location, medical license, AME type, region |
| **Outbound** | **Aviator** (ATCS onboarding tracking) | Name, suffix, applicant ID, DOB, gender, city, state, zip, clearance instruction letter date (via CPDSS) | — |
| **Inbound** | **FAA Directory Service** | — | FAA email addresses for authentication |

### 3.6 Governing framework

- **49 U.S.C. 44703** (statutory authority for medical certification)
- **14 CFR 67.4** (SSN collection authority)
- **FAA Order 3930.3C** (ATCS medical clearance policy)
- **SORN DOT/FAA 856** (Airmen Medical Records, 88 FR 37301, June 7, 2023)
- **SORN OPM/GOVT-10** (Employee Medical File — covers ATCS/applicant ATCS)
- **SORN OPM/GOVT-5** (Recruiting, Examining, Placement — Tier 1/2 psych testing for ATCS)

**Retention:** NARA N1-237-05-005 — medical cert files retained **50 years** after case closed (originals or digital images). NARA GRS 2.7 (employee health), NC1-237-77-07 (comprehensive env health), GRS 3.2 (system access).

**Forms:** FAA Form 8500-8 (OMB 2120-0034), FAA Form 3900-7 (ATCS Health Program Report).

---

## 4. System Deep Dive: IACRA (Integrated Airman Certification and Rating Application)

### 4.1 Architectural role

**IACRA is explicitly a temporary repository — not a system of record.** The 2025 Airmen Certification System PIA is unambiguous:

> "IACRA is the front-end system used by applicants to submit required documentation for certification and registration and serves as a temporary repository until the application information is accepted into the official airmen record maintained in the AVS Registry."

Its job is to guide applicants through the 5-stage workflow (user account → application → review → decision → subsequent services) and then **hand off to CAIS as a TIFF over secure FTP**.

### 4.2 Technology details

| Attribute | Value |
|---|---|
| **URL** | https://iacra.faa.gov/iacra/default.aspx |
| **Help** | https://iacra.faa.gov/IACRA/Help.htm |
| **User guide** | Published on reginfo.gov (objectID 118954701) |
| **Platform** | Web-based enterprise application |
| **Auth (public)** | Username/password + **30-day re-verification via 6-digit email code (MFA)** |
| **Auth (FAA)** | **PIV card via MyAccess** (SSO) |
| **Integration protocol out to CAIS** | **TIFF images over secure FTP** |
| **Knowledge test ingest** | **SQL Server link to Atlas Aviation** (FAA contract knowledge-test vendor, overseen by AFB-630) |
| **ATO** | March 2, 2022 |
| **Standard** | NIST 800-53 Rev 5 (per 2025 PIA) |
| **Retention** | NARA N1-237-09-14 — deleted/destroyed when superseded or obsolete (temp repository only) |
| **Managed by** | Flight Standards Service, Office of Foundational Business, Airmen Certification Branch, AFB-720 |

The **TIFF-over-FTP handoff is the single most important engineering detail** on the slide — it is a legacy integration pattern that is incompatible with modern API-driven systems. This is why CARES was designed.

### 4.3 Roles / access model

IACRA uses a role-based model. Roles include (from the IACRA User Guide):

- **Applicant** (airman)
- **Recommending Instructor** (CFI)
- **Designated Examiner** (DPE)
- **Aviation Safety Inspector (ASI)**
- **Aviation Safety Technician (AST)**
- **School Examiner** (Training Center Evaluator, Aircrew Program Designee)
- **Certifying Official** (umbrella term)

Applicants need an FTN (FAA Tracking Number) — a unique permanent number distinct from the certificate number — to transact.

### 4.4 Data elements collected (IACRA)

**Registration (user account):** Name, DOB, sex, email, certificate # and date (if previously held), 2 security questions.

**Application (per PIA Application section):**

- **Biographic:** Full name, DOB
- **Unique identifiers:** SSN (optional), driver license # + expiration + state, passport # + expiration + country, military ID # + expiration, student ID # + expiration, other gov ID # + expiration + doc type
- **Citizenship:** POB, citizenship
- **Contact:** Residential address (validated against an address standardization service), mailing address, home phone, email
- **Biometric:** Hair color, eye color, height, weight, gender
- **Drug convictions:** Yes/No, dates
- **Prior certs:** Airman Cert #, date of issuance, grade of certificate
- **Aviation experience:** Air carrier name, foreign pilot license # + country + grade + ratings + limitations + copy of license, military competence (rank/grade/service/specialty), record of pilot time, employer/location/work type, senior or military rigger indicator
- **Certification application:** FTN, DE name/designation #/expiration/cert #, Inspector name + cert # + FSDO, training center name/location/school cert #/curriculum, medical cert info (date of issue, class, type of medical, AME name), English proficiency Y/N + medical limitations, cert/rating tested, approved/disapproved, recommending instructor name + cert #

### 4.5 IACRA integration points (from 2025 Airmen Cert System PIA)

| Direction | System | Purpose | Data |
|---|---|---|---|
| **Inbound** | **MyAccess** | Auth for FAA internal users (PIV) | Email address → token |
| **Inbound** | **Atlas Aviation** (knowledge test vendor) | Populate knowledge test results in IACRA | Test title, site ID, expiration, missed subject areas — keyed by FTN |
| **Outbound** | **AVS Registry (CAIS)** | Submit applications for final processing | TIFF images over secure FTP; full application PII |
| **Outbound** | **TSA (NTSDB)** | Security vetting | SSN (if provided), last/first/middle name, suffix, previous name, DOB, citizenship, address, cert info, FTN. TSA returns same fields + vetting result. Governed by MOA. |
| **Outbound** | **FSTW (FAA Safety Team)** | Educational outreach | Airmen contact data (via CAIS) |
| **Outbound** | **SAS (Safety Assurance System)** | Workload/resourcing, surveillance planning | Inspector name, designator, affiliated designator, applicant name/cert #, recommending instructor name/cert # |
| **Outbound** | **USAS Portal (United States Agent Service)** | Build USAS Portal database (one-time) | Name, email, FTN, DOB |
| **Bidirectional** | **DMS** | Designee testing activity | IACRA → DMS: test type, test date, test location, success/failure, aircraft used. DMS → IACRA: airman name, application ID |

### 4.6 Forms handled by IACRA (from PIA Appendix B)

- FAA Form 8400-3 — Aircraft Dispatcher (OMB 2120-0007)
- FAA Form 8610-1 — Mechanic Inspection Authorization (OMB 2120-0022)
- FAA Form 8610-2 — Mechanic / Parachute Rigger (OMB 2120-0022)
- FAA Form 8710-1 — Airman Cert/Rating (OMB 2120-0021)
- FAA Form 8710-11 — Sport Pilot (OMB 2120-0690)
- FAA Form 8710-13 — Remote Pilot (OMB 2120-0021)
- FAA Form 8060-71 — Foreign License Verification (OMB 2120-0724)

### 4.7 Replacement path

Per the 2025 PIA footnote 5:

> "IACRA will be incorporated into the Civil Aviation Registration Electronic Services (CARES) once CARES is fully implemented."

**Phase 2 of CARES = Airman Examination Services (IOC Fall 2024 originally, now Fall 2025) + Airmen Certification and Rating FOC (originally Fall 2025, now Fall 2027 per updated PIA).** IACRA's replacement window is open right now.

---

## 5. System Deep Dive: Designee Management System (DMS)

### 5.1 Architectural role

DMS is the **identity graph for private individuals who act as representatives of the FAA Administrator** under 14 CFR Part 183. It was built in response to GAO-05-40 which called for *one comprehensive system to manage all designees across AVS*. It consolidated what had previously been ~9 independent type-specific designee systems.

Scope: ~10,000+ active designees nationwide (per your slide's figure; FAA hasn't published a newer number publicly).

### 5.2 Technology details

| Attribute | Value |
|---|---|
| **URL** | https://designee.faa.gov |
| **Auth (public designees)** | Username/password; international users route through MyAccess with additional identity verification |
| **Auth (FAA)** | Active Directory via **Integrated Windows Authentication (IWA)**, PIV card |
| **Access model** | **Role-based** — Managing Specialist (full), General user (limited), plus designee roles |
| **Hosting** | Controlled server center within MMAC secure facility (physical) |
| **Help Desk** | MyIT Service Center (1-844-FAA-MyIT / 322-6948), helpdesk@faa.gov |
| **DMS AME-specific mailbox** | 9-avs-dms-ame@faa.gov |
| **Standard** | NIST 800-53 Rev 5 |
| **Retention** | NARA schedule DAA-0237-2020-0013 (proposed 25 years after inactive status) |

**Integrated Windows Authentication is worth flagging** — this is an older pattern that signals on-prem AD dependence and binds DMS to the MMAC network edge. Modernizing DMS would require re-platforming auth.

### 5.3 Designee categories (from DMS PIA)

Thirteen primary categories:

| Code | Full Name | Office |
|---|---|---|
| **DMIR** | Designated Manufacturing Inspection Representative | AIR |
| **DAR-F** | Designated Airworthiness Representative — Manufacturing | AIR |
| **AME** | Aviation Medical Examiner | AAM |
| **DAR-T** | Designated Airworthiness Representative — Maintenance | FS |
| **DPE** | Designated Pilot Examiner | FS |
| **DPRE** | Designated Parachute Rigger Examiner | FS |
| **DME** | Designated Mechanic Examiner | FS |
| **SAE** | Specialty Aircraft Examiner | FS |
| **Admin PE** | Administrative Pilot Examiner | FS |
| **APD** | Aircrew Program Designee | FS |
| **TCE** | Training Center Evaluator | FS |
| **DADE** | Designated Aircraft Dispatch Examiner | FS |
| **DER** | Designated Engineering Representative | AIR |

(ODA — Organization Designation Authorization — is explicitly **excluded** from DMS scope per FAA Order 8000.95.)

### 5.4 Data elements

**Registration:**
- Name, email, username, password, 1 security question + answer (may contain PII)

**Profile (application to become designee):**
- Name, suffix, DOB, Airman Cert #, gender, country of citizenship, phone, photo (optional), personal address, designee's mailing address, FTN
- Character/technical references: name(s), phone number(s)
- Employer name/POC (required for TCE/APD/DADE only)
- Medical License # / NPI (required for AME only)
- Uploaded supporting docs: resume, training/certification info, licenses/certificates

**Background questions (Y/N):** Military service, legal action, felony convictions, probation, imprisonment, airmen cert revocation, English fluency.

**Output on appointment:**
- **Designee Number** (9-digit unique identifier replacing legacy AME number)
- **Certificate Letter of Authority (CLOA)** — contains authorizations, limitations
- **Designation Certificate** — name, type, designation ID, effective date

### 5.5 DMS data exchanges (from DMS PIA)

| Direction | System | Data |
|---|---|---|
| **Outbound** | **NACIP** (National Automated Conformity Inspection Process) | Designee name, ID, phone, type |
| **Outbound** | **MSS** | Designee ID, status (for medical exam scheduling) |
| **Bidirectional** | **IACRA** | IACRA→DMS: test type/date/location/success/failure/aircraft. DMS→IACRA: airman name + application ID |
| **Outbound** | **SAS** | Designee name, ID, type, cert expiration — for workload/resourcing |
| **Outbound** | **eFSAS** (Enhanced Flight Standards Automation System) | Designee name, ID, type, status — used to calculate pay grade |

Plus: public search of designees (https://designee.faa.gov) returns name, address, city, state, zip, phone, country, designee type, office name.

### 5.6 Governing policy

- **14 CFR Part 183** — statutory authority
- **FAA Order 8000.95** (currently 8000.95D, Change 1 in draft as of Nov 24, 2025, docket FAA-2025-1218) — Designee Management Policy
- Draft Change 1 notably: transitions from **DRS (Designee Registration System)** to **DMS** — DMS is absorbing DRS's training/enrollment functions. DRS was a separate training management system using **Pay.gov for course payments and Blackboard for course delivery**.
- **SORN DOT/FAA 830** — "Representatives of the Administrator"
- **OMB Control** 2120-0033

### 5.7 Companion systems often confused with DMS

- **DRS (Designee Registration System)** — separate, Blackboard-based training management, being folded into DMS
- **ODA** — handled in a different process entirely; not in DMS
- **AMCS** — AME exam system; DMS stores AME designee info, AMCS is used for the exams themselves

---

## 6. The Replacement: CARES (Civil Aviation Registration Electronic Services)

### 6.1 Why this belongs in a rationalization doc

You cannot rationalize the 4-system slide without CARES. **CARES is the announced replacement umbrella for Aircraft Registry + Airmen Registry + IACRA + parts of the public inquiry surface**. MedXPress/MSS is not in CARES scope (different SORN, different business owner).

### 6.2 CARES facts

| Attribute | Value |
|---|---|
| **URL (public)** | https://cares.faa.gov |
| **Authentication** | **MyAccess** for both FAA internal (PIV) and public applicants (identity proofing) |
| **Digital signature** | **DocuSign** — encrypted session tokens; signed docs encrypted back to CARES |
| **Payment** | **Pay.gov** — receives CARES-ID + amount; sends back transaction code + fee paid |
| **Deployment model** | Cloud-based (per FAA MONRONeYnews Vol 7 Issue 5 — AIT established "secure, cloud-based technology development project") |
| **ATO** | September 16, 2022; annual security review required |
| **Responsible statute** | Section 546 of FAA Reauthorization Act of 2018 (Pub. L. 115-254) |
| **CARES task order effective date** | **August 28, 2020** |
| **Procurement approach** | Three RFIs prior to task order |
| **Data retention** | NARA N1-237-04-03 — **permanent records** |

### 6.3 Phase plan (original 2022 PIA vs 2024 update)

| Phase | Scope | 2022 PIA estimate | 2024 PIA update |
|---|---|---|---|
| **Phase 1** | Aircraft Registration Services (individuals first) | IOC Dec 2022; FOC Fall 2023 | FOC slipped to **Fall 2027** |
| **Phase 2** | Airman Examination + Airmen Certification & Rating | IOC Fall 2024; FOC Fall 2025 | IOC Fall 2025; FOC Fall 2027 |
| **Phase 3** | UAS (drone) services | Fall 2025 | Absorbed into Phases 1/2 per 2024 update |

**The Fall 2023 → Fall 2027 slip on Phase 1 FOC is the single biggest risk signal in this portfolio.** CARES started as a 3-year mandate; it is now a 7-year program. That is the window in which "rationalization challenge" interventions have maximum leverage.

### 6.4 CARES forms/docs in scope (from CARES PIA Appendix A)

- AC 8050-1 — Aircraft Registration Application
- AC 8050-1B — Aircraft Registration Renewal
- AC 8050-88 — Affidavit of Ownership (amateur-built/non-type certificated)
- AC 8050-88A — Affidavit of Ownership (Light-Sport)
- AC 8050-98 — Aircraft Security Agreement
- AC 8050-2 — Bill of Sale
- AC 8050-4 — Certificate of Repossession
- AC 8050-5 — Dealer's Application
- REGAR-ADCHG-1 — Aircraft Owner Change of Address
- REGAR-LLC-1 — LLC Registration Information Sheet
- REGAR-DIO-1 — Declaration of International Operations
- REGAR-HEIR-1 — Heir-at-Law Form
- Power of Attorney (POA)
- Evidence of Ownership of Business (Certificate of Formation / Articles of Organization / Operating Agreement)

### 6.5 CARES data elements (Phase 1 Aircraft Registration)

Minimal compared to IACRA/MedXPress — because Phase 1 is aircraft only:

- Full name, address, phone, email
- Aircraft Registration Number (N Number)
- Aircraft info: manufacturer make, model, serial number
- Uploaded legal docs (bill of sale, etc.)
- Credit card + billing address (collected by Pay.gov, not stored in CARES)

Phase 2 will pull in the much larger airmen dataset from IACRA/CAIS.

### 6.6 CARES's own external integrations

- **MyAccess** — inbound auth tokens
- **Pay.gov** — outbound payment, inbound confirmation
- **DocuSign** — outbound doc + inbound signed doc
- **AVS Registry (CAIS)** — coexistence / data handover (Phase 1 explicitly hands off approval process to RMS until later phases)

---

## 7. Cross-Cutting: The Integration Map (the #1 artifact for rationalization)

### 7.1 Canonical integration list

| Producer | Consumer | Protocol | Data | Source |
|---|---|---|---|---|
| IACRA | CAIS/RMS | **TIFF over secure FTP** | Application package | 2025 Airmen PIA |
| Atlas Aviation | IACRA | **SQL Server** link | Knowledge test results by FTN | 2025 Airmen PIA |
| IACRA | TSA (NTSDB) | Secure portal (MOA-governed) | Vetting payload | 2025 Airmen PIA |
| IACRA | FSTW | CAIS-mediated | Contact info | 2025 Airmen PIA |
| IACRA | SAS | Direct | Inspector + applicant data | 2025 Airmen PIA |
| IACRA | USAS Portal | One-time prepopulation | Name, email, FTN, DOB | 2025 Airmen PIA |
| IACRA ↔ DMS | IACRA ↔ DMS | Bidirectional | Test activity + airman identification | 2025 Airmen PIA / DMS PIA |
| DIWS ↔ CAIS | DIWS ↔ CAIS | Bidirectional | Demographic sync + medical exam data | 2023 MSS PIA |
| DIWS | Investigation Tracking System (ITS) | Encrypted file | NDR comparison payload | 2023 MSS PIA |
| DIWS ↔ DMS | DIWS ↔ DMS | Bidirectional | AME performance ↔ AME profile | 2023 MSS PIA |
| CPDSS | Aviator | Direct | ATCS onboarding tracking | 2023 MSS PIA |
| MSS | FAA Directory Service | Inbound | FAA email for auth | 2023 MSS PIA |
| DMS | NACIP | Direct | Designee lookup | DMS PIA |
| DMS | MSS | Direct | Medical exam eligibility | DMS PIA |
| DMS | SAS | Direct | Workload/resourcing | DMS PIA |
| DMS | eFSAS | Direct | Pay grade calc | DMS PIA |
| CARES | Pay.gov | Outbound + callback | Payment transaction | CARES PIA |
| CARES | DocuSign | Outbound + callback | Digital signature | CARES PIA |
| CARES | MyAccess | Inbound | Auth tokens | CARES PIA |

### 7.2 The integration antipatterns to flag

1. **TIFF-over-FTP from IACRA → CAIS.** This is the single most indefensible integration in the portfolio. It is also the path that CARES Phase 2 must eliminate.
2. **SQL Server link from Atlas Aviation → IACRA.** Direct SQL connectivity across a vendor boundary is a security and auditability concern.
3. **Email-based MFA in IACRA (6-digit code every 30 days).** Violates modern NIST SP 800-63B AAL2 guidance — email is not a phishing-resistant authenticator. Likely to be flagged in the next FISMA audit cycle.
4. **Integrated Windows Authentication in DMS.** Ties DMS to on-prem AD, blocks zero-trust modernization.
5. **No enterprise-wide airman identifier.** Three competing IDs exist: FTN (IACRA/CAIS), Applicant ID (MSS), Certificate Number (CAIS). Everything has to be joined through SSN, which the FAA is simultaneously trying to minimize.
6. **CHAPS → EMRS** migration announced for Aug 2023; no public confirmation it has actually happened. Worth digging into.

### 7.3 Master integration matrix (simplified)

Each cell = "who talks to whom":

```
            RMS/CAIS  IACRA   MSS    DMS   CARES  External
RMS/CAIS       ―      ✓        ✓     (✓)    ⟶      ―
IACRA          ✓      ―        ―      ✓      ―     Atlas, TSA, FSTW, SAS, USAS
MSS            ✓      ―        ―      ✓      ―     ITS/NDR, Aviator, FAA Dir
DMS            (✓)    ✓        ✓      ―      ―     NACIP, SAS, eFSAS
CARES          ⟶      ―        ―      ―      ―     MyAccess, Pay.gov, DocuSign
```

(⟶ = planned/phased replacement; ✓ = active data exchange)

---

## 8. Cross-Cutting: Public APIs, Data Products, and Open Source Reference

### 8.1 Public endpoints that expose data

- **Airmen Inquiry** — https://amsrvs.registry.faa.gov/airmeninquiry/
- **Aircraft Inquiry** — https://registry.faa.gov/aircraftinquiry/
- **Active Airmen Regional Totals** — https://registry.faa.gov/activeairmen/
- **Airmen Services (self-service login)** — https://amsrvs.registry.faa.gov/amsrvs/
- **Renew Aircraft Registration** — https://amsrvs.registry.faa.gov/renewregistration/
- **Releasable Airmen Download (monthly CSV/fixed-length TXT)** — https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download
- **Certificate Validity Email Request** — https://aie-pa.faa.gov/
- **Interactive Airmen Inquiry** — https://www.faa.gov/licenses_certificates/airmen_certification/interactive_airmen_inquiry
- **Pilot Records Database (PRD)** — https://www.faa.gov/regulations_policies/pilot_records_database

**Note:** No REST APIs are publicly documented for RMS/CAIS. Integrations are all backend (FTP, SQL Server, secure portals). The "public API" surface is effectively: monthly bulk downloads + HTML query apps.

### 8.2 Documentation / training materials

- **IACRA User Guide** (official) — https://www.reginfo.gov/public/do/DownloadDocument?objectID=118954701
- **IACRA Help** — https://iacra.faa.gov/IACRA/Help.htm
- **Airmen Certification overview** — https://www.faa.gov/licenses_certificates/airmen_certification
- **Aircraft Registration (Part 47)** — https://www.faa.gov/licenses_certificates/aircraft_certification/aircraft_registry
- **AMCS / MedXPress AME Support** — https://www.faa.gov/other_visit/aviation_industry/designees_delegations/designee_types/ame/amcs/medxpress
- **AME Guide** — https://www.faa.gov/ame_guide
- **DMS FAQ (external users)** — https://www.faa.gov/sites/faa.gov/files/other_visit/aviation_industry/designees_delegations/dms/dms_faq.pdf
- **DMS landing** — https://www.faa.gov/other_visit/aviation_industry/designees_delegations/dms
- **Federal Air Surgeon's Medical Bulletin (FASMB) Vol 53-2** — details DMS transition for AMEs
- **FAA Order 8000.95D** (Designee Management Policy) — https://www.faa.gov/documentLibrary/media/Order/Order_8000.95D.pdf
- **FAA Order 8000.95D Change 1 (draft)** — Federal Register docket FAA-2025-1218, comments due Jan 23, 2026

### 8.3 Third-party reconstructions

Useful for data model inference and stakeholder understanding:
- **AviationDB** — https://www.aviationdb.com/Aviation/AirmanQuery.shtm (commercial, built on monthly dumps; ~2M+ airmen)
- **FlightAware** registration lookups — built on daily aircraft inquiry scrape

---

## 9. Cross-Cutting: Contract & Vendor Signals

The user specifically asked for engineering depth; contract detail is tagged here to support vendor/recompete analysis.

### 9.1 What we know

- **CARES task order effective Aug 28, 2020**; preceded by three RFIs (2016–2020 evaluation/planning). Specific prime vendor is **not disclosed in public OIG/PIA documents** — normally findable on SAM.gov / USAspending.gov with the task-order #. Worth pulling up in a paid GovTribe/HigherGov seat.
- **FAA ESC IT support contract:** SAIC, 5-year, $122.9M (at MMAC ESC). Not directly CARES but relevant context for MMAC IT delivery model.
- **Atlas Aviation** — FAA knowledge test vendor (overseen by Airman Testing Standards Branch, AFB-630). Provides results to IACRA via SQL Server.
- **DocuSign** — CARES digital signatures (third-party SaaS; CARES uses encrypted session tokens).
- **Pay.gov** — Treasury BFS-operated; CARES and DRS both use it.
- **MyAccess** — FAA identity service; separate PIA exists.
- **Leidos** — dominant FAA prime on NAS-side (NISC IV, $1.76B; Mode S; FFSP; E-IDS). Not directly on registry/certification side based on public disclosures.
- The **Registry Division acquired two consulting studies** prior to CARES: Jan 2017 (evaluate existing processes) + Sep 2017 (modernization options). Consultant names not public.

### 9.2 Congressional/OIG posture

- **FAA Reauthorization Act of 2018, Pub. L. 115-254, Section 546** — mandated registry upgrade by Oct 2021. Missed.
- **OIG AV2019052** — 4 recommendations, all concurred with; deadlines ranged from May 31, 2019 to Oct 31, 2019.
- **GAO-05-40** — originator of the DMS consolidation mandate (2005).
- **GAO-20-164** — "FAA Needs to Better Prevent, Detect, and Respond to Fraud and Abuse Risks in Aircraft Registration" — cited in CARES justification.
- **Jan 17, 2025 Final Rule (2025-00763 and 2025-00764)** — procedural regulations updated to enable CARES (removed original-document stamping requirements).

### 9.3 Where to drill for recompete intel

1. **USAspending.gov / SAM.gov** — search FAA + "CARES" + PSC code D399 (IT Other) + obligated $ FY20–FY24.
2. **HigherGov / GovTribe** — get the CARES task order PIID, look for option periods and expiration.
3. **FAA Small Business Office Active Contracts page** — `sbo.faa.gov` — MMAC Active Contracts List publishes vendor names.
4. **FAA SETIS portfolio** — the IDIQ through which AVS-level work typically gets issued. If CARES or follow-ons land via SETIS task orders, this is where to look.

---

## 10. Rationalization Recommendations (Engineering Angle)

Given the evidence, here are the interventions that will matter most:

### 10.1 The "already decided" path

1. **CARES is the target for RMS + IACRA + public inquiry.** Nothing in the rationalization should propose a competing replacement for that scope.
2. **MSS stays independent.** Medical records have a 50-year retention rule, a separate SORN (DOT/FAA 856), a high-FIPS rating, and AME-specific workflows. Collapsing it into CARES is not on any public roadmap and is probably a bad idea anyway.
3. **DMS stays independent.** It's the authority graph; it needs to outlive both RMS and CARES.

### 10.2 The real rationalization opportunities

1. **The integration fabric (not the systems) is the problem.** Replace point-to-point integrations (TIFF/FTP, direct SQL links, email MFA) with a shared API gateway + standardized identity model. This is a GenAI-era win because a clean integration fabric enables AI agents to read/write the registry safely.
2. **Identifier unification.** FTN (IACRA/CAIS) vs Applicant ID (MSS) vs Certificate Number (CAIS) vs Designee Number (DMS) — standardize on FTN as the person-identity backbone, with system-specific IDs as attributes. SSN has to exit as a join key.
3. **Document intelligence on the TIFF corpus.** 174M images with no OCR. A GenAI layer over this corpus (multimodal extraction + entity linking + duplicate detection) is the highest-value, lowest-risk AI intervention available in this portfolio. It also accelerates CARES migration because it structures the legacy data on the way in.
4. **Airman "golden record" service.** A consolidated read model across CAIS + DIWS + DMS that gives any authorized FAA user a single view of an airman (certs held, medical status, designee relationships). No such service exists today based on the PIAs.
5. **Eliminate the MedXPress → AMCS → DIWS daisy chain for common cases.** A pilot applying for a standard 3rd-class renewal doesn't need the three-subsystem handoff. Consolidation opportunity once EMRS is in place.
6. **Retire CHAPS.** Confirm EMRS replacement is complete (announced for Aug 2023).
7. **DMS 2.0 — auth modernization.** Replace Integrated Windows Authentication with PIV + federated non-PIV (MyAccess) — already partially in place for international users.
8. **CARES Phase 2 hardening.** Phase 2 (airmen cert) slipped from Fall 2025 to Fall 2027. This is a long tail of dual-running IACRA + CARES. Bet on pragmatic adapter services (not swings for the fence).

### 10.3 What NOT to recommend

- Do not recommend replacing MedXPress/MSS as part of CARES. Different SORN, different retention, different stakeholders.
- Do not recommend collapsing DMS into CARES. DMS is the authority layer — it governs who CARES accepts signatures from.
- Do not recommend building a new airman/aircraft public inquiry. The CARES public surface is absorbing that.
- Do not recommend direct mainframe interventions. The NATURAL/ADABAS stack is deliberately being phased out.

### 10.4 AI / GenAI opportunity heat map

Ordered by value × feasibility (given FedRAMP constraints, AVS is not yet AWS-only like EPA):

| # | Opportunity | Why | Where |
|---|---|---|---|
| 1 | **TIFF image intelligence** (OCR + entity extraction + dedup) | 174M untouched images, CAIS/IMS backlog | RMS/CAIS legacy corpus |
| 2 | **Natural language → application status query** | Replaces PDR in-person model; CARES is building only partial public access | CARES public tier |
| 3 | **Form 8500-8 draft validation** | Reduces deferral rate; AMEs already do manual corrections in AMCS | MedXPress/AMCS seam |
| 4 | **Anomaly detection on designee activity reports** | DMS ↔ IACRA activity reports already flow; anomaly detection on test patterns supports GAO-driven oversight | DMS |
| 5 | **Airman "golden record" RAG service** | No cross-system airman view exists; GraphRAG over CAIS + DIWS + DMS would be unique | Cross-cutting |
| 6 | **Fraud detection on aircraft registration** | GAO-20-164 specifically called out | CARES Phase 1 / aircraft side |
| 7 | **Agentic migration assistant** | IACRA → CARES cutover is 2+ years; agent that walks a user through migration is a differentiator | CARES transition |

These are **reusable AI products** for federal/commercial — the TIFF intelligence pattern and golden-record RAG pattern both translate directly to EPA SEMS document intelligence and SEMS enforcement data respectively.

---

## 11. Quick-Reference: System Identity Cards

Pocket summary for the team.

### RMS (umbrella)
- **What:** FAA Registry group of IT systems (CAIS + IMS + Aircraft Registry)
- **Stack:** NATURAL / ADABAS / mainframe; TIFF documents; last major upgrade 2008
- **Volume:** 300K aircraft, 1.5M airmen, 25M docs, 174M images
- **ATO:** April 20, 2022
- **SORN:** DOT/FAA 847, DOT/FAA 801
- **Status:** Being replaced by CARES (Phase 1 aircraft done, Phase 2 airmen FOC Fall 2027)

### MedXPress (via MSS)
- **What:** Applicant-facing medical intake portal → AMCS → DIWS (system of record)
- **Stack:** Web app, part of MSS (FIPS 199 HIGH)
- **URL:** https://medxpress.faa.gov/medxpress/
- **ATO:** November 15, 2021
- **SORN:** DOT/FAA 856
- **Form:** 8500-8 (OMB 2120-0034)
- **Key IDs:** Confirmation #, Applicant ID, MID, PI Number
- **Status:** No announced replacement; CHAPS → EMRS migration pending

### IACRA
- **What:** Applicant-facing airman cert/rating intake (temp repo → CAIS via TIFF/FTP)
- **Stack:** Web app, role-based, email-code MFA, PIV for FAA users
- **URL:** https://iacra.faa.gov
- **ATO:** March 2, 2022
- **SORN:** DOT/FAA 847
- **Forms:** 8400-3, 8610-1, 8610-2, 8710-1, 8710-11, 8710-13, 8060-71
- **Key IDs:** FTN (FAA Tracking Number)
- **Status:** To be absorbed into CARES Phase 2 (FOC Fall 2027)

### DMS
- **What:** Designee lifecycle management (13 designee categories, ~10K+ designees)
- **Stack:** Web app, AD/IWA for FAA, username/password for public; hosted at MMAC
- **URL:** https://designee.faa.gov
- **SORN:** DOT/FAA 830
- **Policy:** FAA Order 8000.95D (Change 1 in draft)
- **Output:** Designee Number + CLOA (Certificate Letter of Authority)
- **Status:** Mature; absorbing DRS training functions in 2025-2026

### CARES (the destination)
- **What:** Cloud-based replacement for Aircraft Registry + Airmen Registry + IACRA
- **Stack:** Web, cloud-hosted, MyAccess auth, DocuSign signatures, Pay.gov payments
- **URL:** https://cares.faa.gov
- **ATO:** September 16, 2022
- **Task order effective:** August 28, 2020
- **Status:** Phase 1 IOC live Dec 2022; FOC slipped to Fall 2027

---

## Appendix A: Primary Source Inventory

1. **OIG AV2019052** — "FAA Plans To Modernize Its Outdated Civil Aviation Registry Systems, but Key Decisions and Challenges Remain" (May 8, 2019) — https://www.oig.dot.gov/sites/default/files/FAA%20Civil%20Aviation%20Registry%20Final%20Report%5E5-8-19.pdf
2. **2025 Airmen Certification System PIA** — https://www.transportation.gov/sites/dot.gov/files/2025-03/Privacy-FAA%20-%20Airmen%20Certification%20System%20-%20PIA.pdf
3. **2023 MSS PIA (MedXPress/AMCS/DIWS/CPDSS)** — https://www.transportation.gov/sites/dot.gov/files/2023-06/Privacy-FAA-MSS%20(MedXPress-AMCS-DIWS-CPDSS)-PIA-2023.pdf
4. **2022 DMS PIA** — https://www.transportation.gov/sites/dot.gov/files/2022-07/Privacy-FAA-DMS-PIA-Final-%202022.pdf
5. **2022 CARES PIA** — https://www.transportation.gov/sites/dot.gov/files/2022-12/Privacy-FAA-CARES-PIA-Final-2022_0.pdf
6. **2024 CARES PIA update** — https://www.transportation.gov/individuals/privacy/civil-aviation-registration-electronic-services-cares-0
7. **Airmen/Aircraft RMS PIA** — https://www.transportation.gov/individuals/privacy/pia-airmenaircraft-registry-modernization-system
8. **NARA Schedule N1-237-06-001** (CAIS data dictionary + airman records) — https://www.archives.gov/files/records-mgmt/rcs/schedules/departments/department-of-transportation/rg-0237/n1-237-06-001_sf115.pdf
9. **GAO IMTEC-91-29** — FAA Registry Systems early modernization analysis
10. **FAA Order 8000.95D** (Designee Management Policy) — https://www.faa.gov/documentLibrary/media/Order/Order_8000.95D.pdf
11. **Federal Register 2025-00763, 2025-00764** (Jan 17, 2025) — CARES-enabling rule changes
12. **FAA Order 8000.95D Change 1 draft** — docket FAA-2025-1218 (comments due Jan 23, 2026)
13. **MONRONeYnews Vol 7 Issue 5** — https://www.esc.gov/monroneynews/archive/Vol_7/CZ/05_2.asp — CARES task-order info
14. **IACRA User Guide** — https://www.reginfo.gov/public/do/DownloadDocument?objectID=118954701

---

*End of research pack. Follow-ups on request: (1) drill into any single integration; (2) build the CARES migration dependency graph as a visualization; (3) extract specific vendor names for the CARES task order from USAspending; (4) map this to specific AI-factory / FMA capabilities from the Federal Modernization Accelerator work.*
