# MedXPress / MSS — Functional Requirements

Detailed functional requirements for the Medical Support Systems (MSS) platform — MedXPress, AMCS, DIWS, CPDSS, CHAPS/EMRS, DSS — extracted from existing artifacts (MSS PIAs 2023 and 2025, FAA Form 8500-8, MedXPress and AMCS user guides, AME guide, AMCS document-upload and document-type guides, AME/MedXPress procedures, Login.gov transition notice, and 14 CFR Part 67 / 49 U.S.C. § 44703 authorities).

**Priority convention (MoSCoW):**
- **Must** — statutory, regulatory, or core-operational requirement; non-negotiable for a modernized platform
- **Should** — strongly warranted by operational, oversight, or stakeholder needs; omission creates significant risk or gap
- **Could** — desirable enhancement or optimization; deferrable without breaking baseline function

**Source artifact legend:**
- **PIA-2023** — MSS/MedXPress/AMCS Privacy Impact Assessment, 2023
- **PIA-2025** — Consolidated MSS Privacy Impact Assessment, 2025
- **FORM-8500-8** — FAA Form 8500-8, Application for Airman Medical Certificate (OMB 2120-0034)
- **MXP-GUIDE** — MedXPress user guide (`medxpress-user-guide.pdf`)
- **AMCS-GUIDE** — AMCS user guide (`amcs-user-guide.pdf`)
- **AME-GUIDE** — AME guide (`ame-guide.pdf`)
- **DOC-UPLOAD** — AMCS document upload guide (`amcs-document-upload-guide.pdf`)
- **DOC-TYPES** — AMCS document types reference (`amcs-document-types.pdf`)
- **PROC-2012** — AME / MedXPress procedures (`ame-medxpress-procedures-2012.pdf`)
- **MFA-2025** — MFA / Login.gov transition notice (`mfa-login-gov-transition.pdf`)
- **ORDER-3930** — FAA Order 3930.3C, Aviation Medical Examiner System
- **CFR-67** — 14 CFR Part 67, Medical Standards and Certification
- **USC-44703** — 49 U.S.C. § 44703, Airman certification
- **SORN-856** — DOT/FAA 856, Airmen Medical Records System of Records Notice
- **NARA-05-005** — NARA Records Disposition Authority N1-237-05-005
- **CURRENT** — `research/medxpress-mss/current-state-analysis.md`

---

## FR-MSS-1: Medical Application Intake (MedXPress)

Applicant-facing intake of Form 8500-8 data through the public MedXPress portal at `medxpress.faa.gov`. Produces a Confirmation Number handed off to the AME at the in-person examination. Statutory authority: 49 U.S.C. § 44703; 14 CFR § 67.4.

### FR-MSS-1.1: Applicant Account Creation

| Field | Value |
|---|---|
| ID | FR-MSS-1.1 |
| Description | The system shall allow any prospective airman applicant to self-register a MedXPress account with a unique username, password meeting FAA credential-complexity policy, and a verified email address. Account creation shall capture baseline identity data (name, date of birth, SSN or assignment of a pseudo-SSN if withheld) sufficient to enable de-duplication against historical AMCS records. |
| Source | PIA-2023 §3; MXP-GUIDE; CURRENT §3.1, §4.3 |
| Priority | Must |

### FR-MSS-1.2: Security Questions

| Field | Value |
|---|---|
| ID | FR-MSS-1.2 |
| Description | The system shall require the applicant to select and answer a configured set of security questions during account creation, used for self-service password reset and identity verification on legacy (non-Login.gov) applicant flows. Answers shall be stored using one-way hashing. |
| Source | MXP-GUIDE; PIA-2023; CURRENT §2 (authentication evolution) |
| Priority | Must |

### FR-MSS-1.3: Privacy Act Statement & Acceptance

| Field | Value |
|---|---|
| ID | FR-MSS-1.3 |
| Description | The system shall present the Privacy Act Statement required for collection of SSN and medical information, referencing 49 U.S.C. § 44703, 14 CFR Part 67, and SORN DOT/FAA 856. The applicant shall affirmatively accept the statement prior to beginning the Form 8500-8 application. Acceptance and version of statement shall be recorded with timestamp. |
| Source | FORM-8500-8; PIA-2023 §2; PIA-2025; SORN-856; CURRENT §9 |
| Priority | Must |

### FR-MSS-1.4: Form 8500-8 — Identity & Demographics (Items 1–10)

| Field | Value |
|---|---|
| ID | FR-MSS-1.4 |
| Description | The system shall capture Form 8500-8 identity and demographic items including: class of certificate applied for (First / Second / Third); full legal name and any other names used; date of birth; SSN (voluntary, pseudo-SSN assigned if withheld); mailing and residential addresses; phone; email; citizenship / country; sex, hair color, eye color, height, and weight. |
| Source | FORM-8500-8 items 1–10; PIA-2023 §3; CURRENT §4.1 |
| Priority | Must |

### FR-MSS-1.5: Form 8500-8 — Certification History (Items 11–14)

| Field | Value |
|---|---|
| ID | FR-MSS-1.5 |
| Description | The system shall capture prior FAA medical certification history, including class and date of last medical certificate, any prior denial, suspension, or revocation; airman certificate number and ratings held; date of last FAA medical examination. |
| Source | FORM-8500-8 items 11–14; CURRENT §4.1 |
| Priority | Must |

### FR-MSS-1.6: Form 8500-8 — Occupation & Aviation Activity (Items 15–17)

| Field | Value |
|---|---|
| ID | FR-MSS-1.6 |
| Description | The system shall capture occupation, employer, total pilot time, and pilot time logged in the past 6 months. |
| Source | FORM-8500-8 items 15–17; CURRENT §4.1 |
| Priority | Must |

### FR-MSS-1.7: Form 8500-8 — Medication List

| Field | Value |
|---|---|
| ID | FR-MSS-1.7 |
| Description | The system shall accept a list of current medications (prescription and over-the-counter), including name, dosage, purpose, and start date where known. |
| Source | FORM-8500-8; CURRENT §4.1 |
| Priority | Must |

### FR-MSS-1.8: Form 8500-8 — Item 18 Medical History Checklist

| Field | Value |
|---|---|
| ID | FR-MSS-1.8 |
| Description | The system shall present the complete Item 18 medical-history checklist covering 20+ conditions — including frequent/severe headache, dizziness/fainting, unconsciousness, eye/vision trouble, hay fever/allergy, asthma/lung disease, heart/vascular trouble, high/low blood pressure, kidney stone/blood in urine, diabetes, neurological disorders, mental disorders, alcohol dependence, drug use, arrests/convictions for DWI/DUI, and all remaining standard 8500-8 conditions. Each condition shall be answerable Yes/No with an explanation field required for Yes. |
| Source | FORM-8500-8 item 18; CURRENT §4.1 |
| Priority | Must |

### FR-MSS-1.9: Form 8500-8 — Visits to Health Professionals (Item 19)

| Field | Value |
|---|---|
| ID | FR-MSS-1.9 |
| Description | The system shall capture visits to health professionals in the past 3 years, including date, reason, and provider name and address. |
| Source | FORM-8500-8 item 19; CURRENT §4.1 |
| Priority | Must |

### FR-MSS-1.10: Form 8500-8 — Legal & Disability Declarations (Item 20)

| Field | Value |
|---|---|
| ID | FR-MSS-1.10 |
| Description | The system shall capture non-traffic misdemeanor and felony convictions; drug/alcohol-related driving actions (arrests, convictions, administrative actions); non-driving drug/alcohol convictions; and current disability benefits received. |
| Source | FORM-8500-8 item 20; CURRENT §4.1 |
| Priority | Must |

### FR-MSS-1.11: Confirmation Number Generation

| Field | Value |
|---|---|
| ID | FR-MSS-1.11 |
| Description | Upon submission of a completed Form 8500-8, the system shall generate a unique Confirmation Number that the applicant presents to the AME at the scheduled in-person examination. The Confirmation Number shall be displayable on screen and in an applicant-printable summary. |
| Source | MXP-GUIDE; AME-GUIDE; PROC-2012; CURRENT §3.1, §4.3 (Identifier Taxonomy) |
| Priority | Must |

### FR-MSS-1.12: Application Status Tracking (8 Values)

| Field | Value |
|---|---|
| ID | FR-MSS-1.12 |
| Description | The system shall expose the applicant's current application status through a status field supporting the eight observed values: (1) No Application, (2) Submitted, (3) Imported, (4) Transmitted, (5) In Review, (6) Action Required, (7) Cert Issued, (8) Denial / Disqualification. Status transitions shall be event-driven and timestamped. |
| Source | CURRENT §6 (status values); MXP-GUIDE; AMCS-GUIDE |
| Priority | Must |

### FR-MSS-1.13: 30-Day Auto-Delete for Unsubmitted Applications

| Field | Value |
|---|---|
| ID | FR-MSS-1.13 |
| Description | The system shall automatically purge incomplete, unsubmitted MedXPress applications after 30 days of inactivity, and shall notify the applicant prior to deletion. Deletion shall be irreversible and shall not affect historical submitted records. |
| Source | MXP-GUIDE; PIA-2023; PIA-2025 |
| Priority | Must |

### FR-MSS-1.14: 60-Day Expiration of Submitted Applications

| Field | Value |
|---|---|
| ID | FR-MSS-1.14 |
| Description | The system shall expire submitted MedXPress applications that have not been imported by an AME within 60 days of submission. Expired applications shall no longer be importable via Confirmation Number; the applicant shall be required to resubmit. |
| Source | MXP-GUIDE; PROC-2012; CURRENT §3.1 |
| Priority | Must |

### FR-MSS-1.15: Print Summary Sheet for AME Visit

| Field | Value |
|---|---|
| ID | FR-MSS-1.15 |
| Description | The system shall generate an applicant-printable summary sheet containing the Confirmation Number, applicant identity fields, and a machine-readable representation suitable for presentation to the AME at the scheduled exam. |
| Source | MXP-GUIDE; PROC-2012 |
| Priority | Must |

### FR-MSS-1.16: Login.gov Authentication for Applicants

| Field | Value |
|---|---|
| ID | FR-MSS-1.16 |
| Description | The system shall support Login.gov as the identity-proofing and MFA provider for applicant accounts per the August 2025 transition. Legacy username/password + security-question flows shall be supported during transition and retired on a published schedule. |
| Source | MFA-2025; CURRENT §2, §10 |
| Priority | Must |

---

## FR-MSS-2: Medical Examination (AMCS)

AME-facing capture of the in-person medical examination through the AMCS portal at `amcs.faa.gov`. Pulls MedXPress submission by Confirmation Number, records physical-exam findings, attaches supporting documents, and records disposition. Audience: ~5,000 Aviation Medical Examiners.

### FR-MSS-2.1: AME Authentication via Login.gov

| Field | Value |
|---|---|
| ID | FR-MSS-2.1 |
| Description | The system shall authenticate non-FAA AMEs via Login.gov with MFA per the August 2025 transition. FAA AMEs shall authenticate via PIV through the FAA Directory Service. |
| Source | MFA-2025; CURRENT §2, §3.2 |
| Priority | Must |

### FR-MSS-2.2: Exam Import by Confirmation Number

| Field | Value |
|---|---|
| ID | FR-MSS-2.2 |
| Description | The system shall allow an authenticated AME to retrieve a MedXPress submission by Confirmation Number, bind it to an AMCS exam record, and transition the application status from Submitted to Imported. Import shall fail if the Confirmation Number is unknown, already imported, or expired (>60 days). |
| Source | AMCS-GUIDE; AME-GUIDE; PROC-2012; CURRENT §3.2, §6 |
| Priority | Must |

### FR-MSS-2.3: Vitals & Biometrics Capture

| Field | Value |
|---|---|
| ID | FR-MSS-2.3 |
| Description | The system shall capture vitals and biometrics: height, weight, blood pressure (systolic/diastolic), and pulse. |
| Source | FORM-8500-8 (medical examination report); AMCS-GUIDE; CURRENT §4.2 |
| Priority | Must |

### FR-MSS-2.4: Vision Testing

| Field | Value |
|---|---|
| ID | FR-MSS-2.4 |
| Description | The system shall capture distant, near, and intermediate vision for each eye (with and without correction), color vision, and field of vision, per Part 67 class-specific standards. |
| Source | FORM-8500-8; CFR-67; AMCS-GUIDE; CURRENT §4.2 |
| Priority | Must |

### FR-MSS-2.5: Hearing Testing

| Field | Value |
|---|---|
| ID | FR-MSS-2.5 |
| Description | The system shall capture hearing results via audiometric testing and/or whisper/conversational voice testing, per Part 67 class-specific standards. |
| Source | FORM-8500-8; CFR-67; AMCS-GUIDE; CURRENT §4.2 |
| Priority | Must |

### FR-MSS-2.6: Urinalysis

| Field | Value |
|---|---|
| ID | FR-MSS-2.6 |
| Description | The system shall capture urinalysis results including albumin and sugar findings. |
| Source | FORM-8500-8; AMCS-GUIDE; CURRENT §4.2 |
| Priority | Must |

### FR-MSS-2.7: ECG Capture

| Field | Value |
|---|---|
| ID | FR-MSS-2.7 |
| Description | The system shall capture ECG results where required (mandatory at first-class class 35+ and periodically thereafter, and as medically indicated), including interpretation and attachment of the tracing as a document artifact. |
| Source | FORM-8500-8; CFR-67.111; AMCS-GUIDE; CURRENT §4.2 |
| Priority | Must |

### FR-MSS-2.8: Physical Examination — Full Body System Checklist

| Field | Value |
|---|---|
| ID | FR-MSS-2.8 |
| Description | The system shall capture AME findings across the full Form 8500-8 physical-examination checklist covering 25+ body systems, including: head/face/neck/scalp; nose; sinuses; mouth and throat; ears general; eardrums; eyes general (ophthalmoscopic); ophthalmoscopic; pupils (equality and reaction); ocular motility; lungs and chest; heart (precordial activity, rhythm, sounds); vascular system; abdomen and viscera (including hernia); anus; skin; G-U system; upper and lower extremities (strength, range of motion); spine and musculoskeletal; identifying body marks/scars/tattoos; lymphatics; neurologic (reflexes, equilibrium, senses, cranial nerves, coordination); psychiatric (appearance, behavior, mood, communication, memory); general systemic; hearing/ENT referral; and dental as applicable. Each system shall be Normal / Abnormal with a narrative explanation field for Abnormal. |
| Source | FORM-8500-8; AMCS-GUIDE; CURRENT §4.2 |
| Priority | Must |

### FR-MSS-2.9: Disposition — Issue / Deny / Defer

| Field | Value |
|---|---|
| ID | FR-MSS-2.9 |
| Description | The system shall record the AME's disposition as Issue, Deny, or Defer. On Issue, the system shall support in-office certificate printing and record the issuance. On Deny, the system shall record the disqualifying condition and downstream legal/appeal pathway. On Defer, the system shall transmit the case to FAA AAM-300 for review. |
| Source | AMCS-GUIDE; AME-GUIDE; CFR-67; CURRENT §4.2, §6 |
| Priority | Must |

### FR-MSS-2.10: Document Upload — Up to 25 per Exam

| Field | Value |
|---|---|
| ID | FR-MSS-2.10 |
| Description | The system shall permit the AME to upload up to 25 documents per exam record. Each upload shall be associated with a single exam and indexed for DIWS retrieval. |
| Source | DOC-UPLOAD; CURRENT §5 |
| Priority | Must |

### FR-MSS-2.11: Document Upload — Per-File Size Limit

| Field | Value |
|---|---|
| ID | FR-MSS-2.11 |
| Description | The system shall enforce a per-file size limit of 3 MB at upload time. (Note: modern clinical imaging workflows routinely exceed this limit; see current-state §11.4. A modernization should raise this ceiling.) |
| Source | DOC-UPLOAD; CURRENT §5, §11.4 |
| Priority | Must |

### FR-MSS-2.12: Document Upload — Supported Formats

| Field | Value |
|---|---|
| ID | FR-MSS-2.12 |
| Description | The system shall accept uploads in PDF, DOC, DOCX, JPG, JPEG, and XPS formats. Files of unsupported types shall be rejected at upload time with an explanatory message. |
| Source | DOC-UPLOAD; CURRENT §5 |
| Priority | Must |

### FR-MSS-2.13: Document Type Classification

| Field | Value |
|---|---|
| ID | FR-MSS-2.13 |
| Description | The system shall require each uploaded document to be tagged with a document-type category from the formal AMCS/DIWS document taxonomy of 30+ named types across groupings: Cardiac & vascular (ECG/EKG strips and interpretations, stress test/treadmill reports, echocardiogram, Holter/event monitor tracings, cardiology consults); Neurological & psychiatric (neurology consult, psychiatric evaluation, CogScreen-AE, neuropsychological evaluation, EEG); Labs & imaging (CBC/CMP/lipid panel/HbA1c/PSA lab reports, X-ray/CT/MRI imaging reports, biopsy/pathology); Clinical narratives (discharge summary, operative report, treating physician narrative, specialist consults covering ophthalmology/ENT/pulmonology/endocrinology/oncology); Vision & hearing (ophthalmology report per Form 8500-7, audiogram); Legal & administrative (court documents for DUI/arrest/expungement, driver license reinstatement letters, SODA / Authorization for Special Issuance letters, correspondence to/from applicant/FAA/AME); Identity & supporting (government-issued photo ID, passport); and Medications & substance (medication list, substance-abuse treatment records, HIMS reports). |
| Source | DOC-TYPES; CURRENT §5 |
| Priority | Must |

### FR-MSS-2.14: Exam Transmission to FAA

| Field | Value |
|---|---|
| ID | FR-MSS-2.14 |
| Description | Upon AME completion of the exam record (including disposition and document attachments), the system shall transmit the exam package to FAA for DIWS imaging and, as applicable, CPDSS review. Transmission shall transition application status to Transmitted. |
| Source | AMCS-GUIDE; AME-GUIDE; PROC-2012; CURRENT §6 |
| Priority | Must |

---

## FR-MSS-3: Document Imaging & Workflow (DIWS)

Internal FAA document-of-record tier behind AMCS. PIV-gated; serves AAM-300 reviewers. Indexes scanned and uploaded medical documentation, routes cases through workflow queues.

### FR-MSS-3.1: Internal Archive Management

| Field | Value |
|---|---|
| ID | FR-MSS-3.1 |
| Description | The system shall maintain the internal document-of-record archive for all airman medical cases, indexing documents from AMCS uploads, scanned paper submissions, external consults, and correspondence. Documents shall be retrievable by Applicant ID, MID, AME Serial Number, and document type. |
| Source | PIA-2023; PIA-2025; CURRENT §3.3, §5, §11.4 |
| Priority | Must |

### FR-MSS-3.2: Case Queue Routing — CAMI, Regional Flight Surgeons, HQ

| Field | Value |
|---|---|
| ID | FR-MSS-3.2 |
| Description | The system shall route case records to the appropriate FAA reviewer queue based on disposition, class, geography, and case complexity. Queues shall include, at minimum: the Civil Aerospace Medical Institute (CAMI) medical review queue, Regional Flight Surgeon queues (by FAA region), and Aerospace Medical Certification Division (AAM-300) headquarters queues. |
| Source | PIA-2023; ORDER-3930; CURRENT §3.3, §6 |
| Priority | Must |

### FR-MSS-3.3: Approval / Denial / Deferral Routing

| Field | Value |
|---|---|
| ID | FR-MSS-3.3 |
| Description | The system shall route cases along disposition-specific workflow paths: Approval (certificate issuance, correspondence generation, CAIS write-back); Denial (legal/enforcement handoff, appeal-rights letter generation); Deferral (request for additional information, Action Required status, tracking of response deadline). |
| Source | PIA-2023; CURRENT §6 (status values); CFR-67 |
| Priority | Must |

### FR-MSS-3.4: Anomaly Check Workflow

| Field | Value |
|---|---|
| ID | FR-MSS-3.4 |
| Description | The system shall support an anomaly-check workflow in which cases flagged for inconsistencies (e.g., self-reported vs. NDR mismatch, prior denial with undisclosed history, medication conflicts) are routed for human review and tracked to resolution. |
| Source | PIA-2023; CURRENT §7 (NDR integration), §11.1 |
| Priority | Must |

### FR-MSS-3.5: Supplemental Document Intake

| Field | Value |
|---|---|
| ID | FR-MSS-3.5 |
| Description | The system shall accept supplemental documentation submitted after initial exam transmission, including: outpatient charts, specialty consults (cardiology, neurology, ophthalmology, psychiatry, etc.), imaging studies, and pathology reports. Supplemental documents shall be tied to the existing case record and trigger re-review where applicable. |
| Source | DOC-TYPES; PIA-2023; CURRENT §5, §6 |
| Priority | Must |

### FR-MSS-3.6: Document Retention — 50 Years

| Field | Value |
|---|---|
| ID | FR-MSS-3.6 |
| Description | The system shall retain all case documentation for 50 years after case closure, per NARA schedule N1-237-05-005. Retention holds shall pause scheduled disposition for cases under legal hold or active appeal. |
| Source | NARA-05-005; PIA-2025; CURRENT §9, §11.7 |
| Priority | Must |

### FR-MSS-3.7: Raise Document Upload Ceilings (Modernization)

| Field | Value |
|---|---|
| ID | FR-MSS-3.7 |
| Description | A modernized DIWS/document service should raise the 25-documents-per-exam and 3-MB-per-file limits to match current clinical imaging realities (high-resolution DICOM, long embedded-image PDFs, multi-hundred-MB study sets). The taxonomy should be preserved and lifted forward into the shared service. |
| Source | CURRENT §11.4, §12.2; DOC-UPLOAD |
| Priority | Should |

---

## FR-MSS-4: Covered Position Decision Support (CPDSS)

Internal decision-support subsystem for FAA medical review officers handling covered-position certification — Air Traffic Controller Specialists (ATCS), pilots in special review, and other covered categories. PIV-gated; audience: AAM-300 reviewers.

### FR-MSS-4.1: ATCS Medical Clearance — Form 3900-7

| Field | Value |
|---|---|
| ID | FR-MSS-4.1 |
| Description | The system shall support capture and review of the ATCS medical clearance evaluation (FAA Form 3900-7 or successor), including required physical exam elements, psychological evaluation attachments, and final clearance decision. |
| Source | PIA-2023; PIA-2025; ORDER-3930; CURRENT §3.4 |
| Priority | Must |

### FR-MSS-4.2: Clearance Decision Workflow

| Field | Value |
|---|---|
| ID | FR-MSS-4.2 |
| Description | The system shall provide a decision-support workflow that aggregates airman history, flags disqualifying conditions against Part 67 standards, tracks review state, and records final clearance disposition with reviewer identity, timestamp, and rationale. |
| Source | PIA-2023; CFR-67; CURRENT §3.4, §6 |
| Priority | Must |

### FR-MSS-4.3: Tier 1 / Tier 2 Psychological Testing Documentation

| Field | Value |
|---|---|
| ID | FR-MSS-4.3 |
| Description | The system shall capture and attach psychological testing artifacts for ATCS candidates, including Tier 1 screening results and Tier 2 follow-up evaluation documentation (e.g., CogScreen-AE, neuropsychological evaluation) as mandated by FAA covered-position policy. |
| Source | PIA-2023; DOC-TYPES (CogScreen-AE, neuropsych evaluation); CURRENT §3.4, §5 |
| Priority | Must |

### FR-MSS-4.4: Aviator Onboarding Data Transmission

| Field | Value |
|---|---|
| ID | FR-MSS-4.4 |
| Description | Upon favorable clearance, the system shall transmit ATCS medical clearance status to the Aviator hiring system to unblock downstream onboarding steps. Transmission shall include minimum-necessary fields (clearance status, effective date, next-action date) and avoid exposing underlying medical history. |
| Source | PIA-2023; PIA-2025; CURRENT §7 (Aviator integration), §3.4 |
| Priority | Must |

---

## FR-MSS-5: Integration

Cross-system integrations. Today implemented as point-to-point contracts; see current-state §11.6 for FIPS-HIGH boundary implications.

### FR-MSS-5.1: CAIS Bidirectional Demographic & Exam Sync

| Field | Value |
|---|---|
| ID | FR-MSS-5.1 |
| Description | The system shall bidirectionally synchronize airman demographics, exam data, and medical-history snapshots with CAIS (Comprehensive Airman Information System / RMS Registry). CAIS shall serve as the single source of truth for airman identity; MSS shall push exam outcomes to support certificate issuance. |
| Source | PIA-2023 §4; PIA-2025; CURRENT §7 |
| Priority | Must |

### FR-MSS-5.2: National Driver Register Encrypted Comparison

| Field | Value |
|---|---|
| ID | FR-MSS-5.2 |
| Description | The system shall submit an encrypted comparison file (name, DOB, driver-license data) to the Investigation Tracking System / National Driver Register to cross-check for DUI/DWI and driving-related drug/alcohol actions that the applicant may not have self-reported. Matches shall be routed to the anomaly-check workflow (FR-MSS-3.4). |
| Source | PIA-2023; PIA-2025; CURRENT §7, §11 |
| Priority | Must |

### FR-MSS-5.3: DMS Bidirectional AME Metrics & Profile Exchange

| Field | Value |
|---|---|
| ID | FR-MSS-5.3 |
| Description | The system shall bidirectionally exchange data with the Designee Management System (DMS): outbound — AME performance metrics (exam volume, deferral rate, error rate, response times); inbound — AME profile and designation status (active/suspended/terminated). Exchange shall feed DMS AME oversight and shall gate AMCS login on active designation. |
| Source | PIA-2023; PIA-2025; ORDER-3930; CURRENT §7 |
| Priority | Must |

### FR-MSS-5.4: Aviator ATCS Onboarding Transmission

| Field | Value |
|---|---|
| ID | FR-MSS-5.4 |
| Description | The system shall transmit ATCS medical clearance status to the Aviator hiring pipeline to track medical clearance state into the ATCS onboarding flow. See FR-MSS-4.4 for the CPDSS-side requirement. |
| Source | PIA-2023; CURRENT §7, §3.4 |
| Priority | Must |

### FR-MSS-5.5: FAA Directory Service — Email & Identity Auth

| Field | Value |
|---|---|
| ID | FR-MSS-5.5 |
| Description | The system shall consume identity attributes (employee email, PIV linkage, organizational unit) from the FAA Directory Service to authenticate internal FAA staff (AAM-300 reviewers, CAMI staff, Regional Flight Surgeons) across AMCS, DIWS, and CPDSS. |
| Source | PIA-2023; CURRENT §2, §7 |
| Priority | Must |

### FR-MSS-5.6: Login.gov for Non-FAA Users (August 2025)

| Field | Value |
|---|---|
| ID | FR-MSS-5.6 |
| Description | The system shall use Login.gov for identity proofing and MFA for non-FAA users (AMEs and applicants), per the August 2025 transition. Legacy credential flows shall be retired on a published schedule. Login.gov identity assertions shall be bound to the applicable MedXPress applicant account or AMCS AME identity. |
| Source | MFA-2025; CURRENT §2, §10 |
| Priority | Must |

### FR-MSS-5.7: Event-Driven Integration Edge (Modernization)

| Field | Value |
|---|---|
| ID | FR-MSS-5.7 |
| Description | A modernized MSS should publish an event stream (case-submitted, case-imported, case-disposition-changed, AME-performance-updated, clearance-granted) and replace today's five point-to-point integrations with a subscription model. This would shrink the FIPS-HIGH boundary and collapse ATO-adjacent integration work. |
| Source | CURRENT §11.6, §12.5 |
| Priority | Should |

---

## FR-MSS-6: Compliance & Security

Regulatory, privacy, and security obligations governing the MSS platform. ATO: November 15, 2021. FIPS 199: HIGH.

### FR-MSS-6.1: FIPS 199 HIGH Categorization

| Field | Value |
|---|---|
| ID | FR-MSS-6.1 |
| Description | The system shall be operated under FIPS 199 HIGH categorization across confidentiality, integrity, and availability, reflecting the density of PII/PHI and the aviation-safety impact of certification decisions. All NIST 800-53 HIGH baseline controls shall apply to every subsystem, integration endpoint, and document store within the MSS boundary. |
| Source | PIA-2023; PIA-2025; CURRENT §1, §9, §11.6 |
| Priority | Must |

### FR-MSS-6.2: SORN DOT/FAA 856 — Airmen Medical Records

| Field | Value |
|---|---|
| ID | FR-MSS-6.2 |
| Description | The system shall operate under the System of Records Notice DOT/FAA 856, Airmen Medical Records. All collection, use, disclosure, and retention of PII shall conform to the published routine uses; any change shall be preceded by a SORN amendment. |
| Source | SORN-856; PIA-2023; PIA-2025; CURRENT §9 |
| Priority | Must |

### FR-MSS-6.3: 50-Year Retention per NARA N1-237-05-005

| Field | Value |
|---|---|
| ID | FR-MSS-6.3 |
| Description | The system shall retain airman medical case records for 50 years after case closure, per NARA Records Disposition Authority N1-237-05-005. Retention disposition shall be automatable with per-case legal-hold override; destruction shall be auditable and require dual-authorization. |
| Source | NARA-05-005; PIA-2025; CURRENT §9, §11.7 |
| Priority | Must |

### FR-MSS-6.4: Statutory Authority — 49 U.S.C. § 44703

| Field | Value |
|---|---|
| ID | FR-MSS-6.4 |
| Description | The system shall operate as the FAA's medical certification platform under the Administrator's authority in 49 U.S.C. § 44703 to issue airman certificates, including the medical certificate required for exercise of pilot privileges. |
| Source | USC-44703; PIA-2023; CURRENT §9 |
| Priority | Must |

### FR-MSS-6.5: Regulatory Authority — 14 CFR Part 67

| Field | Value |
|---|---|
| ID | FR-MSS-6.5 |
| Description | The system shall implement the medical standards and certification procedures of 14 CFR Part 67, including § 67.4 (issue of medical certificates) and the class-specific standards of §§ 67.101–67.415. Disposition logic and anomaly-check routing shall reflect Part 67 disqualifying conditions. |
| Source | CFR-67; PIA-2023; CURRENT §9 |
| Priority | Must |

### FR-MSS-6.6: FAA Order 3930.3C — AME System

| Field | Value |
|---|---|
| ID | FR-MSS-6.6 |
| Description | The system shall implement the AME designation, oversight, and performance procedures of FAA Order 3930.3C, coordinated with the Designee Management System (see FR-MSS-5.3). |
| Source | ORDER-3930; PIA-2023; CURRENT §9 |
| Priority | Must |

### FR-MSS-6.7: Privacy Act Compliance

| Field | Value |
|---|---|
| ID | FR-MSS-6.7 |
| Description | The system shall enforce Privacy Act requirements: (a) present a Privacy Act Statement for SSN and medical-information collection (FR-MSS-1.3); (b) support applicant access and amendment requests; (c) log and audit disclosures consistent with SORN DOT/FAA 856; (d) enforce minimum-necessary disclosure to integration partners. |
| Source | Privacy Act of 1974; SORN-856; PIA-2023; PIA-2025; CURRENT §9 |
| Priority | Must |

### FR-MSS-6.8: Annual PIA Maintenance

| Field | Value |
|---|---|
| ID | FR-MSS-6.8 |
| Description | The system shall maintain a current Privacy Impact Assessment per DOT and OMB policy; material changes (new integration, new data category, new user population) shall trigger a PIA update before deployment. |
| Source | PIA-2023; PIA-2025; CURRENT §1, §9 |
| Priority | Must |

### FR-MSS-6.9: Audit Logging of All Access to Medical Data

| Field | Value |
|---|---|
| ID | FR-MSS-6.9 |
| Description | The system shall produce tamper-evident audit logs for all access to applicant PII / PHI — including reads, writes, exports, and disclosures — with user identity, timestamp, source IP, record identifier, and action. Logs shall be retained per the applicable NIST 800-53 HIGH control set and made available for audit and incident response. |
| Source | FIPS 199 HIGH / NIST 800-53 AU family; PIA-2023; CURRENT §9 |
| Priority | Must |

### FR-MSS-6.10: Encryption of Data at Rest and in Transit

| Field | Value |
|---|---|
| ID | FR-MSS-6.10 |
| Description | The system shall encrypt all medical data at rest (database, document store, backups) and in transit (portal traffic, integration edges including CAIS, NDR, DMS, Aviator, and FAA Directory) using FIPS 140-validated modules. NDR comparison file submission shall use the specified encrypted exchange format. |
| Source | FIPS 199 HIGH / NIST 800-53 SC family; PIA-2023; CURRENT §7, §9 |
| Priority | Must |

---

*Sources: `research/medxpress-mss/current-state-analysis.md`; MSS PIAs (2023, 2025); FAA Form 8500-8; MedXPress and AMCS user guides; AME guide; AMCS document upload guide and document types reference; AME/MedXPress procedures (2012); Login.gov transition notice; FAA Order 3930.3C; 14 CFR Part 67; 49 U.S.C. § 44703; SORN DOT/FAA 856; NARA N1-237-05-005.*
