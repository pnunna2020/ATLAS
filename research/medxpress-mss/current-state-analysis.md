# MedXPress / Medical Support Systems (MSS) — Current-State Analysis

This analysis captures the MSS platform as it stands in 2026: what it is, how the pieces fit together, where the data and identifiers live, and where the architectural seams cause pain. It is intentionally built around the *umbrella* view — MedXPress is only the public face of a six-subsystem federation, and any modernization story has to start with that whole picture.

---

## 1. System Identity

**Umbrella:** Medical Support Systems (MSS) is the FAA Office of Aerospace Medicine's portfolio of applications supporting airman medical certification. MedXPress is the public-facing intake, but MSS spans six tightly-coupled subsystems:

| Subsystem | Role |
|---|---|
| **MedXPress** | Applicant-facing web intake (Form 8500-8 equivalent) |
| **AMCS** (Aerospace Medical Certification Subsystem) | AME exam processing, disposition, document upload |
| **DIWS** (Document Imaging & Workflow Subsystem) | Internal document imaging, indexing, and workflow routing |
| **CPDSS** (Covered Position Decision Support Subsystem) | Internal decision support for certification review |
| **CHAPS / EMRS** | Clinic Health & Physiological Subsystem, being replaced by the Employee Medical Records Subsystem (EMRS) |
| **DSS** (Decision Support Subsystem) | Research / analytics archive, no PII |

**Responsible official:** Kelly Merritt, AAM-300 (Aerospace Medical Certification Division), FAA Office of Aerospace Medicine.

**Authority to Operate:** November 15, 2021.

**FIPS 199 categorization:** HIGH (confidentiality, integrity, availability all HIGH — driven by the PII density and the aviation-safety impact of certification decisions).

**Governing Privacy Impact Assessments:** MSS/MedXPress/AMCS PIA (2023) and consolidated MSS PIA (2025).

---

## 2. Technology Stack Analysis

**Platform:** Classic ASP.NET web application. `.aspx` URLs are visible across public entry points (`medxpress.faa.gov/medxpress/...aspx`, `amcs.faa.gov/amcs/...aspx`), which pins the stack to Microsoft IIS / ASP.NET Web Forms.

**Release cadence:** Current production release is **5.5.2**, consistent with a long-lived major-version lineage rather than a recent rewrite.

**Longevity:** AMCS launched **October 1, 1999**. MedXPress layered on top in the mid-2000s. Every subsequent subsystem (DIWS, CPDSS, CHAPS) was bolted onto the AMCS spine. The platform is therefore a **25+ year application chain**, with the outer shell modernized (HTTPS, MFA, Login.gov) but the core data model and workflow engine rooted in late-1990s design assumptions.

**Authentication evolution:**
- **Applicants** — username/password + security questions (legacy flow).
- **AMEs and non-FAA users** — migrated to **Login.gov** in August 2025 (see `mfa-login-gov-transition.pdf`).
- **Internal FAA staff** — PIV card via FAA Directory Service.

**Observable stack signals:**
- IIS + ASP.NET Web Forms.
- SQL Server (implicit from the integration patterns and document metadata schema).
- Server-rendered pages, minimal JavaScript framework use (Web Forms postback model).
- Document storage handled through DIWS as a separate imaging tier rather than an object store.

---

## 3. Subsystem Architecture

### 3.1 MedXPress
- **URL:** `medxpress.faa.gov`
- **Audience:** Airman applicants (public)
- **Auth:** Username/password + security questions
- **Function:** Collects Form 8500-8 data; issues a **Confirmation Number** the applicant hands to the AME at the in-person exam
- **Output:** Submission record held for AME import (typically within 60 days)

### 3.2 AMCS — Aerospace Medical Certification Subsystem
- **URL:** `amcs.faa.gov`
- **Audience:** ~5,000 Aviation Medical Examiners (AMEs) worldwide
- **Auth:** Login.gov (since Aug 2025) for non-FAA AMEs; PIV for FAA AMEs
- **Function:** Retrieves MedXPress submission via Confirmation Number, captures physical-exam findings, supports document upload, records disposition (Issue / Deny / Defer)
- **Output:** Exam record transmitted to FAA for review

### 3.3 DIWS — Document Imaging & Workflow Subsystem
- **Audience:** Internal FAA reviewers (AAM-300 staff)
- **Auth:** PIV-gated
- **Function:** Indexes scanned and uploaded medical documentation, routes cases through workflow queues, maintains the imaged record of the airman file
- **Role:** Acts as the document-of-record tier behind AMCS

### 3.4 CPDSS — Covered Position Decision Support Subsystem
- **Audience:** FAA medical review officers making certification decisions on covered positions (e.g., ATCS, pilots in special review)
- **Auth:** PIV-gated
- **Function:** Decision support for reviewers — aggregates history, flags conditions, tracks review status

### 3.5 CHAPS → EMRS
- **Audience:** FAA clinic staff and FAA employees receiving occupational/physiological health services
- **Status:** CHAPS (Clinic Health & Physiological Subsystem) is being **replaced** by EMRS (Employee Medical Records Subsystem)
- **Function:** Clinic scheduling, physiological training records, occupational health documentation

### 3.6 DSS — Decision Support Subsystem
- **Audience:** FAA researchers, policy analysts, CAMI (Civil Aerospace Medical Institute)
- **Data:** De-identified / no PII
- **Function:** Research archive, trend analysis, policy support

---

## 4. Data Architecture

### 4.1 MedXPress Applicant Data (derived from Form 8500-8, OMB 2120-0034)

**Identity & demographics**
- Class of certificate applied for (First / Second / Third)
- Full legal name, any other names used
- Date of birth
- SSN (voluntary but near-universal; pseudo-SSN assigned if withheld)
- Mailing address, residential address
- Phone, email
- Citizenship / country
- Sex, hair color, eye color, height, weight

**Certification history**
- Prior FAA medical certificate details (class, date, any denial/suspension/revocation)
- Airman certificate number and ratings held
- Date of last FAA medical exam

**Occupation & aviation activity**
- Occupation, employer
- Total pilot time, pilot time past 6 months

**Medical declarations**
- Current medication list (prescription and OTC)
- Full Item 18 medical-history checkbox set (20+ conditions — frequent/severe headache, dizziness/fainting, unconsciousness, eye/vision trouble, hay fever/allergy, asthma/lung disease, heart/vascular trouble, high/low blood pressure, kidney stone/blood in urine, diabetes, neurological disorders, mental disorders, alcohol dependence, drug use, arrests/convictions for DWI/DUI, etc.)
- Visits to health professionals in past 3 years (dates, reasons, providers)
- Non-traffic misdemeanor and felony convictions; drug/alcohol-related driving actions; non-driving drug/alcohol convictions
- Current disability benefits

### 4.2 AMCS Exam Data (captured by AME)

**Vitals & biometrics**
- Height, weight, blood pressure (systolic/diastolic), pulse
- Distant / near / intermediate vision (each eye, with/without correction)
- Color vision, field of vision
- Hearing (audiometric and whisper / conversational voice)
- Urinalysis (albumin, sugar)

**Physical examination — 25+ body systems**
1. Head, face, neck, scalp
2. Nose
3. Sinuses
4. Mouth and throat
5. Ears, general (internal and external canals)
6. Eardrums (perforation)
7. Eyes — general (ophthalmoscopic)
8. Ophthalmoscopic
9. Pupils (equality and reaction)
10. Ocular motility (associated parallel movement, nystagmus)
11. Lungs and chest (not including breast exam)
12. Heart (precordial activity, rhythm, sounds)
13. Vascular system (pulse, amplitude and character, arms, legs, etc.)
14. Abdomen and viscera (including hernia)
15. Anus (not including digital exam)
16. Skin
17. G-U system (not including pelvic exam)
18. Upper and lower extremities (strength, range of motion)
19. Spine, other musculoskeletal
20. Identifying body marks, scars, tattoos
21. Lymphatics
22. Neurologic (tendon reflexes, equilibrium, senses, cranial nerves, coordination, etc.)
23. Psychiatric (appearance, behavior, mood, communication, memory)
24. General systemic
25. Hearing / ear, nose, throat referral
26. Dental (as applicable)

**Studies**
- ECG (required at first-class 35+ and periodically thereafter)
- Lab studies as required by class / medical history

**Disposition**
- Issue (certificate issued in-office)
- Deny (disqualifying condition)
- Defer (insufficient data; refer to FAA for review)

### 4.3 Identifier Taxonomy

| Identifier | Generated By | Lifetime | Purpose |
|---|---|---|---|
| **Confirmation Number** | MedXPress | Short (until AME import; typically 60 days) | Handoff from applicant to AME |
| **Applicant ID** | AMCS | Lifetime | Unique airman identifier across all exams |
| **MID** (Medical ID) | MedXPress | Per exam | Unique per submission instance |
| **PI Number** | Assigned on pathology | Lifetime | Pathology marker once a disqualifying or deferred condition enters review |
| **SSN / pseudo-SSN** | Applicant / FAA | Lifetime | De-duplication across systems; pseudo-SSN assigned when applicant withholds |
| **AME Serial Number** | FAA | Lifetime of designation | AME identity, credentialing, performance tracking |
| **SODA Serial Number** | FAA | Lifetime of waiver | Statement of Demonstrated Ability (medical waiver) reference |

The coexistence of **seven overlapping identifiers** for what is essentially one airman-case concept is the single most visible symptom of the subsystem-layered design. Each subsystem invented its own primary key; none was ever retired.

---

## 5. Document Taxonomy

AMCS accepts up to **25 documents per exam**, each up to **3 MB**, in **PDF, DOC, DOCX, JPG, JPEG, or XPS** format. Each document is tagged with a category from a formal document-type taxonomy used for DIWS indexing:

**Cardiac & vascular**
- ECG / EKG strips and interpretations
- Stress test / treadmill reports
- Echocardiogram reports
- Holter monitor / cardiac event-monitor tracings
- Cardiology consult / narrative

**Neurological & psychiatric**
- Neurology consult
- Psychiatric evaluation
- CogScreen-AE (cognitive screening for pilots)
- Neuropsychological evaluation
- EEG reports

**Labs & imaging**
- Lab reports (CBC, CMP, lipid panel, HbA1c, PSA, etc.)
- Imaging reports (X-ray, CT, MRI)
- Biopsy / pathology reports

**Clinical narratives**
- Discharge summary (inpatient)
- Operative report
- Treating physician narrative / status report
- Specialist consult (ophthalmology, ENT, pulmonology, endocrinology, oncology, etc.)

**Vision & hearing**
- Ophthalmology report (Form 8500-7 or equivalent)
- Audiogram

**Legal & administrative**
- Court documents (DUI dispositions, arrest records, expungement orders)
- Driver license reinstatement letters
- SODA / Authorization for Special Issuance letters
- Correspondence (letters to/from applicant, FAA, AME)

**Identity & supporting**
- Government-issued photo ID
- Passport

**Medications & substance**
- Medication list
- Substance-abuse treatment records / HIMS reports

In aggregate the taxonomy runs to **several dozen named document types**, each mapped to a DIWS index code so that reviewers can retrieve by category across an airman's full history. This taxonomy is one of the platform's genuine strengths — and a concrete asset that any modernization should preserve.

---

## 6. User Roles & Workflows

### Primary actors
- **Applicant** (airman / applicant pilot / ATCS candidate)
- **AME** (Aviation Medical Examiner — designated private-practice physician)
- **FAA Medical Review Officer** (AAM-300)
- **FAA Legal / Enforcement** (on denial / revocation pathways)
- **Clinic staff** (CHAPS/EMRS)

### End-to-end flow

```
 Applicant                AME                       FAA Reviewer
 ─────────                ────                      ────────────
 MedXPress  ──Confirm#──▶ AMCS  ──transmit──▶ DIWS → CPDSS → Disposition
  (intake)                 (exam)              (imaging) (decision support)
```

1. Applicant creates a MedXPress account → fills Form 8500-8 data → receives **Confirmation Number**.
2. Applicant presents the Confirmation Number to the AME at the scheduled exam.
3. AME **imports** the submission into AMCS → performs physical → uploads documents → records disposition.
4. On Issue, AMCS prints the certificate in-office; transmission to FAA still occurs for records.
5. On Defer or complex Deny, AMCS **transmits** the case to FAA; documents flow into **DIWS**.
6. **CPDSS** surfaces the case to the appropriate reviewer with decision-support context.
7. Final action (Cert Issued, Denial, Disqualification, or Authorization for Special Issuance) is recorded; correspondence issued to applicant.

### Status values (observed across MedXPress / AMCS / DIWS)

| Status | Meaning |
|---|---|
| **No Application** | Applicant has an account but no submitted 8500-8 |
| **Submitted** | MedXPress submission complete, awaiting AME import |
| **Imported** | AME has pulled the submission into AMCS |
| **Transmitted** | AME has completed exam and sent record to FAA |
| **In Review** | FAA AAM-300 reviewer has the case |
| **Action Required** | Additional documentation requested from applicant / AME |
| **Cert Issued** | Medical certificate granted |
| **Denial / Disqualification** | Certificate denied; appeal rights apply |

---

## 7. Integration Architecture

| Direction | System | Data Exchanged | Purpose |
|---|---|---|---|
| **Bidirectional** | **CAIS** (Comprehensive Airman Information System / RMS Registry) | Airman demographics, exam data, medical history snapshot | Single source of truth for airman identity; feeds certificate issuance |
| **Outbound** | **Investigation Tracking System / National Driver Register (NDR)** | Encrypted comparison file (name, DOB, DL data) | Cross-check for DUI/DWI and driving-related drug/alcohol actions the applicant may not have self-reported |
| **Bidirectional** | **DMS** (Designee Management System) | AME performance metrics ↔ AME profile and designation status | Feeds AME oversight; poor performance can drive decertification |
| **Outbound** | **Aviator** | ATCS (Air Traffic Controller Specialist) onboarding status | Tracks medical clearance into the ATCS hiring pipeline |
| **Inbound** | **FAA Directory Service** | Employee email / identity attributes | Internal auth; supports PIV linkage |
| **Inbound (2025+)** | **Login.gov** | Authenticated identity assertion | MFA and identity verification for non-FAA users (AMEs, applicants) |

Integrations are point-to-point; there is no enterprise integration bus mediating these flows. Each edge is its own contract, its own authentication, and its own failure mode.

---

## 8. Public-Facing Surfaces

| Surface | URL / Artifact | Audience |
|---|---|---|
| **MedXPress portal** | `medxpress.faa.gov` | Applicants |
| **AMCS portal** | `amcs.faa.gov` | AMEs |
| **MedXPress FAQ** | Public FAQ page under medxpress.faa.gov | Applicants |
| **MedXPress user guide** | `medxpress-user-guide.pdf` | Applicants |
| **AME guide** | `ame-guide.pdf` | AMEs |
| **AMCS user guide** | `amcs-user-guide.pdf` | AMEs |
| **AMCS document upload guide** | `amcs-document-upload-guide.pdf` | AMEs |
| **AMCS document types** | `amcs-document-types.pdf` | AMEs |
| **AME / MedXPress procedures** | `ame-medxpress-procedures-2012.pdf` | AMEs (reference) |
| **MFA / Login.gov transition notice** | `mfa-login-gov-transition.pdf` | AMEs, applicants |

Volume: **400,000+ medical-certificate applications annually** flow through this public surface.

---

## 9. Compliance & Governance

**System of Records Notice**
- **DOT/FAA 856 — Airmen Medical Records**

**Records retention**
- **50 years after case closed**, per NARA schedule **N1-237-05-005**.

**Statutory / regulatory authorities**
- **49 U.S.C. § 44703** — Airman certification (includes medical certification authority).
- **14 CFR Part 67** — Medical Standards and Certification (67.4 Issue of medical certificates; 67.101–67.415 class-specific standards).
- **FAA Order 3930.3C** — Aviation Medical Examiner System.

**Form**
- **FAA Form 8500-8** — Application for Airman Medical Certificate (OMB 2120-0034).

**FISMA / NIST posture**
- ATO: Nov 15, 2021.
- FIPS 199: HIGH.
- Governed under the MSS PIAs (2023 and 2025).

---

## 10. Modernization Status

**In flight**
- **CHAPS → EMRS migration.** CHAPS (Clinic Health & Physiological Subsystem) is being retired in favor of EMRS (Employee Medical Records Subsystem). This is the only in-progress replacement of a major subsystem.
- **Login.gov adoption (Aug 2025).** Non-FAA users (AMEs, applicants) have been moved off legacy credential flows to Login.gov for MFA and identity proofing. This does not change any backend subsystem but removes a significant credential-management liability.

**Not in flight**
- No announced replacement program for **MedXPress, AMCS, DIWS, CPDSS, or DSS**. The current release train (5.5.2) is evolutionary, not modernizing.
- No public architecture-refresh roadmap; no cloud-migration posture published.
- Form 8500-8 data model is stable (no redesign).

**Implication.** The 25-year AMCS spine and its five bolted-on subsystems will remain the operating reality for the foreseeable future absent a formal modernization initiative. The CHAPS/EMRS work establishes a precedent but is the narrowest of the six subsystems.

---

## 11. Technical Debt & Risk Assessment

### 11.1 Fragmented subsystem architecture
Six subsystems, six UIs, six data models, six deployment cadences — each addressing a slice of what is conceptually one case lifecycle. Every cross-subsystem feature requires coordinated change across teams and systems. Onboarding cost (for reviewers, AMEs, and engineers) is high.

### 11.2 Daisy-chain workflow
The workflow literally runs MedXPress → AMCS → DIWS → CPDSS → CHAPS, with data handed off at each seam via batch or point-to-point integration. Each handoff is a potential failure point and a latency contributor. There is no single "case object" that travels the pipeline; instead, each subsystem rehydrates a local projection.

### 11.3 Identity sprawl
Seven identifiers (Confirmation #, Applicant ID, MID, PI Number, SSN/pseudo-SSN, AME Serial #, SODA Serial #) exist because no subsystem accepted another's primary key. Reconciliation relies on SSN/pseudo-SSN plus name/DOB — workable but error-prone, especially for name changes, pseudo-SSN collisions, and dual-citizenship cases.

### 11.4 Document sprawl
Documents live in DIWS keyed to AMCS cases, but correspondence, SODA letters, and CPDSS decision artifacts may exist in adjacent stores. The 25-docs-per-exam / 3 MB ceiling is a 2000s-era constraint that constrains modern imaging (high-res DICOM, long PDFs with embedded imagery) and forces AMEs into workaround splits.

### 11.5 Classic ASP.NET Web Forms stack
Web Forms is still supported but is effectively an end-of-road framework. Talent is scarce; modern accessibility, security, and responsive-UX expectations are hard to meet without a rewrite. The release numbering (5.5.2) suggests a mature but frozen codebase.

### 11.6 FIPS 199 HIGH with point-to-point integrations
HIGH categorization plus six subsystems and five external integrations means every edge is in scope for HIGH controls. Each added integration is a multi-month ATO-adjacent effort. The architecture makes the security boundary larger than it needs to be.

### 11.7 Retention horizon vs. stack lifetime
50-year retention on a stack whose core launched in 1999 means the platform will have to migrate data forward at least once more within the retention window of current records — and any successor must prove it can read the legacy document and exam corpus.

---

## 12. Rationalization Recommendations

The opportunity is **not** "replace MedXPress." MedXPress is the thinnest layer and the most approachable for the applicant. The opportunity is to **collapse the six-subsystem layered model into one case architecture** with shared services.

### 12.1 Unify around a single Case object
One airman case — identified by a single stable Case ID — that carries the 8500-8 data, exam data, documents, dispositions, and correspondence across its full lifecycle. Retire the Confirmation-Number / Applicant-ID / MID handoff in favor of a single canonical ID, with the legacy identifiers preserved as secondary keys for historical lookup only.

### 12.2 Shared document service, preserving the existing taxonomy
The AMCS / DIWS document-type taxonomy is one of the platform's real assets — dozens of categories, decades of reviewer familiarity, mapped to real workflow. A modernization should **lift this taxonomy forward** into a shared document service (object storage, metadata index, retention policy aligned to the 50-year schedule) and retire DIWS's bespoke imaging tier. Raise the 3 MB-per-file / 25-file limits to match current clinical imaging realities.

### 12.3 Consolidate UIs into role-based workspaces, not system-based portals
Today a reviewer moves between AMCS, DIWS, and CPDSS because those are how the *systems* are organized. A future-state UI should be organized by *role and task* — applicant workspace, AME workspace, reviewer workspace — each backed by the same Case service.

### 12.4 Single identity layer
Extend the Login.gov / PIV work already underway into a unified identity plane for all six subsystems, retiring the last legacy username/password flow.

### 12.5 Replace point-to-point integrations with an event-driven edge
CAIS, DMS, Aviator, NDR, FAA Directory — today all point-to-point. A published event stream (case-submitted, case-disposition-changed, AME-performance-updated) would collapse five bespoke integrations into one subscription model and shrink the FIPS-HIGH boundary.

### 12.6 Treat CHAPS → EMRS as the template
The CHAPS → EMRS migration is the only live replacement in the portfolio. The lessons from that effort — data-migration approach, identity mapping, user-transition cadence — should be captured as the pattern for the eventual AMCS / DIWS / CPDSS replacement cycle, not left as a one-off.

---

*Sources: `research/medxpress-mss/tech-profile.md`; MedXPress & AMCS user guides; MSS PIA (2023); MSS PIA (2025); Login.gov transition notice; AMCS document-type and upload guides; AME guide; AME/MedXPress procedures (2012).*
