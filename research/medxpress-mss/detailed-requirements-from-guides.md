# MedXPress / AMCS — Detailed Requirements from User Guides

Source documents extracted:
- AMCS User Guide (April 2024, 95 pages) — screen-by-screen AME workflow
- AMCS Document Upload Quick Start Guide (6 pages)
- AMCS Document Type List (Revised 02/01/2026, 6 pages)
- AME Guide (2026, 882 pages) — clinical standards, disposition tables
- Information for Aviation Medical Examiners Processing MedXPress Applications (2012)

Note: The `medxpress-user-guide.pdf` is a scanned image-only PDF and yielded no extractable text. Airman-facing MedXPress screen flow requirements are inferred from the AMCS import flow and the 2012 AME Procedures document.

---

## 1. Authentication & Account Lifecycle (AMCS)

### 1.1 Login via MyAccess / OKTA
- AMCS login requires completion of the FAA "MyAccess" registration process.
- Sequence: navigate to AMCS Login → Security Banner → Accept → MyAccess page → email → password → OKTA code → Home page.
- Three distinct denial states must be handled with specific error messages:
  - **No AMCS role:** "The user 'XXXX' is not authorized to access this site."
  - **Staff not validated in 90 days:** "Access to AMCS has been denied as your AME has not validated staff within the last 90 days or has not authorized access to AMCS for this account. Please ask your AME to perform account validation using the AME Administration application to restore your access."
  - **Tied to inactive AME serial number:** same "not authorized" message as no role.

### 1.2 Staff Validation (90-day Cycle)
- Each AME must validate AMCS accounts for their staff every 90 days.
- If not validated, the AMCS link appears disabled with a yellow triangle; hovering displays the denial message.
- Staff must contact their AME for reactivation; self-service recovery is not available.

### 1.3 Session Management
- Hard timeout: 20 minutes of inactivity → session ends and user is returned to the Login screen.
- Warning: at 15 minutes of inactivity on data-entry screens, a timeout warning modal is shown with a Continue button.
- If Continue is not clicked within 5 more minutes, the session ends.
- Unsaved data is lost on timeout; saved page-level data persists in the database (page 1 data remains if saved before losing connectivity mid page 2).

### 1.4 Browser/Environment Requirements
- Pop-up blockers must be disabled; cookies must be enabled.
- Optimal resolution: 1024 × 768.
- Technical support: AMCSsupport@faa.gov, 405-954-3238; MyAccess escalation: helpdesk@FAA.gov, 1-844-FAA-MyIT.

---

## 2. Home Page and Messaging

### 2.1 Home Page Behavior
- AME users always land on Home Page.
- AME staff members only see the Home Page when there are new messages; otherwise they are routed directly to Pending Exams (or Import Application if no pending exams).

### 2.2 Message Center
- Two tabs: "New" (unconfirmed messages) and "All" (all active messages).
- Messages flagged as **requires confirmation** block all application links until acknowledged: a check mark displays under the "Required" header; application links are disabled until the user clicks View → reads → checks the box → clicks Confirm.
- Messages can be printed.

---

## 3. Pending Exams Workflow

### 3.1 Grid Functions
The Pending Exams screen lists all exams in the AME office in pending status, sortable by Last Name, First Name, Middle Name, SSN, or Exam Date (column header click).

Per-row actions:
1. **Open** — launches Form 8500-8 Data Entry (Page 1).
2. **Attach ECG icon** — ECG Import window.
3. **Upload Documents icon** — multi-document upload dialog.
4. **Exam HX icon** — Pre-Exam Report (MedXPress-sourced exams only).
5. **Print icon** — PDF view of exam.

Navigation tabs:
- Search Applicants
- Import Application (retrieve exam entered by applicant via MedXPress)

### 3.2 ECG Attachment Rules
- Only one ECG per exam; uploading a new one replaces the previously attached ECG.
- Warning banner must be shown if an ECG is already attached.
- File constraint: PDF only, less than 3 MB.
- Required metadata: Document Date (ECG performed date) + optional Comments.
- AMCS will deny submission and transmission of the exam if an ECG is required (by disposition rules) and not attached.
- Success confirmation must be displayed after upload.

---

## 4. Document Upload (AMCS)

### 4.1 Constraints
- Maximum 25 documents per exam. Total count must be displayed in the dialog.
- Max file size: 3 MB per file.
- Allowed extensions: doc, docx, jpg, jpeg, pdf, xps.
- Security restriction: JPG/JPEG cannot be viewed inline by users after upload; other formats are preferred.
- Per-upload required attributes: Document Name (file), Document Type (single-select from taxonomy), Document Date (≤ tomorrow — future-dated selection disabled).
- Document Date represents the date of the medical event or service noted on the document, not the date uploaded.

### 4.2 Per-Document Actions (Pre-Transmission)
- **View** (eye icon): downloads the file for viewing.
- **Edit** (pencil icon): allows modifying Document Type and Document Date only (not the file itself).
- **Delete** (trash icon): requires confirmation; removes document from the transmission queue.

### 4.3 Post-Transmission Behavior
- After transmission, documents cannot be edited or deleted by the AME.
- The AME of record may upload additional documents to an already-transmitted exam via Search Applicant tab → Actions column → Up Arrow icon — but only until a new exam is transmitted.
- Upon transmission, documents are routed to the Aerospace Medical Certification Division (AMCD) Document Handling section where technicians may:
  1. Correct Document Date
  2. Correct Document Type
  3. Rotate the document
  4. Combine/separate documents per AMCD naming convention
- The original is retained but renamed to one of: "Document Error - Miscellaneous," "Document Error - Multiple Reports," or "Document Error - Wrong Applicant," and this updated name is visible in AMCS.

### 4.4 Document Type Taxonomy (Pilot Exams)
Prefix-grouped. Selecting an incorrect type delays processing. Full pilot taxonomy extracted from the February 2026 list:

**Administrative:** Admin - Coversheet; Admin - Driver License/Passport/ID.

**Airman General:** Airman Personal Statement; AME Letter of Denial; Character Witness Statement; Chief/Peer Pilot Report; Correspondence from Airline/Airman/AME; Court Documents; Flight Instructor Report; Narrative; Privacy Act - 8065-2 Request Airman Medical Records; School Transcript/Grades; Treatment Records; VA Benefit Summary; Deceased.

**Behavioral Health (Beh Hlth):** ADHD FAST Track Summary; ADHD Personal Statement; ADHD Psychology or Neuropsychology Report; Anxiety/Depression FAST Track Summary; CogScreen; Neuropsychology Report; Neuropsychology Test Results; Psychiatric Evaluation; Psychological Evaluation; Therapy Notes.

**Cancer:** Narrative.

**Cardiac:** Afib Narrative; Afib Status Summary; Cath Rpt; CHD/CAD Recert Status Summary; Continuous Cardiac Monitoring Report; Echocardiogram; Exercise Stress Test (EST) + Report + Tracings; Holter Monitor Report + Tracings; Narrative; Pacemaker Info; Pharmaceutical Stress Test + Report; Radionuclide Stress (RS) Test + Report; Stress Echo + Report.

**Drug/Alcohol (DA):** Aftercare Rpts; Alcohol Event Status Report; Driving Record; Drug/Alcohol Test; IMS Narrative; Monitoring Program; Police Report; Substance Abuse Evaluation.

**Endocrine:** Diabetes Blood Glucose Worksheet; Diabetes CGM Data; Diabetes Endocrinology Rpt; Diabetes Finger Stick Data; Diabetes Flight Activity; Diabetes Misc; Diabetes Narrative; Diabetes on Insulin Recer Stat; DMO Worksheet.

**Eye:** Color Vision Limitation Review; Color Vision Test; Evaluation/8500-7/14; Lens Implant Status Summary; Plaquenil Status Report; Quality of Vision Questionnaire Pilots/ATCS; Refractive Surgery Status Summary; Vision Narrative; Visual Field Graphs.

**HIMS (Human Intervention Motivational Study):** AME Checklist; AME Report; Neuropsychologist Report; Psychiatrist Report; Psychologist Report.

**Hospital:** Admission Summary; Consultation Rpt; Discharge Summary; EMS/Ambulance Report; History & Physical; Operative Report; Procedure Report; Records.

**Imaging:** CT Scan; MRI; PET Scan; Radiology Reports; Ultrasound; Ultrasound - Carotid; Ultrasound - Vascular.

**Other clinical:** Gender Dysphoria Status Report; Hearing Test/Audiogram; Infectious Disease - Narrative; Lab Results; Legal - Release of Driving Records; Low Testosterone Hypogonadism Status Summary; Medication List; Nephrology/Kidney - Narrative.

**Neuro:** Airman Seizure Questionnaire; Electroencephalogram (EEG); Narrative.

**OSA (Obstructive Sleep Apnea):** AM Compliance; CPAP Data; Dental Device; Initial Status Report; Narrative; Recert Status Report; Reports; Sleep Study.

**Pulmonary:** 6 Minute Walk Test; Function Test; Narrative.

**Rheumatology:** Narrative.

**Misc:** Pathology Rpt; Pharmacy Records.

### 4.5 Document Type Taxonomy (ATC / ATC Applicant Exams)
Separate "ATC - " prefixed set used for FAA-employed Air Traffic Controllers and ATC applicants. AME-Employee Examiners only. For ATC/pilot combo exams, the ATC-prefixed types are preferred. Full list includes: ATC - 3900-7, ATC - 8500-8, ATC - Allergy, ATC - Anxiety/Depression Report, ATC - Asthma Report, ATC - Beh Hlth - ADHD Documents / Personal Statement / Psychology or Neuropsychology Report, ATC - Cancer Reports, ATC - Cardiac Afib / Reports / Cath Report / Echocardiogram / EST Report-Tracings / Holter Monitor Report, ATC - CogScreen, ATC - Color Vision, ATC - Correspondence, ATC - Court Documents, ATC - Detailed Clinical Progress Note, ATC - Diabetes CGM Data, ATC - Diabetic Reports, ATC - Driving Record, ATC - DUI, ATC - EAP/TRP, ATC - ECG, ATC - EMS/Ambulance Report, ATC - Endocrinology Report, ATC - ER Records, ATC - Eye - Evaluation (8500-7/14, Visual Field Graphs), ATC - Eye - Refractive Surgery Records, ATC - Gender Dysphoria, ATC - Headache, ATC - Hearing/Audio Report, ATC - HIMS AME Report / Drug-Alcohol Tests / Psychiatrist / Psychologist, ATC - HIV Reports, ATC - Hospital Admission Summary / Discharge Summary, ATC - Hypertension, ATC - Lab, ATC - Mental Health-Other, ATC - Misc. Test Results, ATC - Miscellaneous, ATC - Narrative, ATC - Nephrology/Kidney, ATC - Neurology, ATC - Neuropsychology Report/Evaluation, ATC - Neurovascular, ATC - Obesity Pre-DM treated with meds, ATC - OSA Compliance Data / Signed Compliance Memo / Sleep Study-Titration Study / Status Reports, ATC - Pathology Report, ATC - Personal Statement, ATC - Pharmacy Records, ATC - Police Reports, ATC - Psychiatric Records, ATC - Psychological Records, ATC - Pulmonary Function Test/Spirometry Results, ATC - Pulmonology/Lung, ATC - Radiology/Imaging Reports, ATC - Release of Records, ATC - Return to Duty, ATC - Rheumatology, ATC - School Transcripts/Grades, ATC - Sleep Disorders/Non OSA, ATC - SSRI, ATC - Substance Abuse Evaluation / Substance Consumption Narrative, ATC - Surgical/Operative Report, ATC - Thyroid Disorders, ATC - VA Benefit Summary / Medical Records, ATC - Vision.

Shared (Pilot + ATC): Eye - Lens Implant Status Summary; Eye - Quality of Vision Questionnaire; Eye - Refractive Surgery Status Summary; Privacy Act - 8065-2.

---

## 5. MedXPress → AMCS Import Workflow

From the 2012 AME Procedures document (still current-policy):

### 5.1 Airman-Facing Rules
- MedXPress is at `https://medxpress.faa.gov`.
- MedXPress use has been **mandatory** since October 1, 2012 (was optional 2007–2012).
- Only a valid email account is required to create a MedXPress account.
- FAA-employed ATCs may **not** use MedXPress.
- MedXPress captures applicant-supplied Items 1–20 of FAA Form 8500-8.
- The applicant **cannot make updates to a submitted MedXPress application**.
- Applications **expire if not imported into AMCS within 60 days**.
- Applicant receives a confirmation number after submission; the confirmation number is required to import.

### 5.2 AME Office Procedures
- Applicant brings Confirmation Number + valid photo ID + printed Summary Sheet.
- AME logs into AMCS → Import Application tab → enters Confirmation Number → Search.
- Results grid allows selecting existing applicant or choosing "New Applicant" for first-time applicants.
- If an applicant has an FAA record but is not shown, AME must call AMCS Support.
- Click Process Selection → AMCS assigns a certificate number → Summary Sheet printed.
- Applications must be imported before the applicant leaves the AME office.
- An imported MedXPress application becomes a signed FAA form at the moment of import.
- MedXPress applications can be imported only **once**; subsequent access goes through Pending Exams.
- Do **not** mail any portion of the MedXPress application (import captures the e-signature).

### 5.3 Changes to Page 1 During Import
- Any change to Items 1–20 made during the exam requires:
  1. Discussion with and approval from the applicant.
  2. Entry of the change in AMCS.
  3. A comment per change in the Modification section of the Comments Screen.
  4. Check "Check here to certify" after reading the certification statement to confirm the applicant authorized the change.

### 5.4 Exam Submission Timelines
- AME must submit the exam through AMCS within **14 days** of the exam date.
- If a student certificate is issued, exam must be submitted within **7 days**.

### 5.5 Confirmation Number Recovery
- Applicant retrieves from MedXPress or email.
- If not retrievable, AMCS Support must be contacted (405-954-3238).

---

## 6. Form 8500-8 Data Entry Screens (AMCS)

### 6.1 Page Structure
- Page 1: Items 1–16 (demographics, certificate request, occupation, visual/hearing info), Item 17a (Current Medication), Item 18 (Medical History), Items 19 and 20 (Health Professional Visits, Declaration Statement).
- Page 2: Items 25–48 (physical examination findings by body system), Item 63 (Disqualifying Defects), Item 64 (AME Declaration).
- Page 3: (disposition / certification output).

### 6.2 Page 1 Menu Actions
- Tabs: Search Applicants; Pending Exams; Import Application.
- Actions: Page 1 / Page 2 / Page 3 menu items; AME Actions menu (pilots only); Comments menu; Check for Errors; Display Summary; Attach Current ECG to New Exam; Upload Document to New Exam; Print Certificate (pilots only — Medical Certificate Quick Print).

### 6.3 Page 2 (Items 25–48) Batch Entry Aids
Two explicit buttons on Page 2:
- **Set All Blank Items in 25–48 to Normal** — marks any body-system row without a finding as Normal.
- **Set All Normal Items in 25–48 to Blank** — inverse: clears all normal rows back to blank.

These are critical workflow accelerators and their behavior must not discard applicant-specific findings already entered.

### 6.4 Comments Screens
Four distinct comment contexts exist:
1. Comments on Physical Findings.
2. Modifications to Page 1 of Imported Exams (one row per change, with applicant authorization confirmation).
3. Applicant Explanations.
4. Comments on History and Findings.

### 6.5 Certificate Disposition (Pilots)
Three outcomes on Page 3:
- **No Certificate Issued (Deferred).**
- **Certificate Issued.**
- Special handling screens:
  - **Certificate Data Mismatch Verification** — when printed certificate data diverges from Page 1.
  - **Certificate Issued With Certificate Eligibility Warning** — AME must acknowledge.
  - **Exam Submission Confirmation** — final transmission confirmation.
- AMEs must not print or issue a certificate if deferring or denying.

### 6.6 SI/AASI Medical Certificate
Dedicated screens to handle Special Issuance (SI) and AME Assisted Special Issuance (AASI) cases with a preview before print. AASI disposition tables span dozens of conditions (see AME Guide inventory below).

---

## 7. Search Applicants

- Searchable by demographics + SSN or FAA record identifiers.
- "Found Exams" returns applicant's exam history.
- Buttons: Search; Clear; Add Exam to Selected Applicant's FAA Medical Record; Create New Applicant Record.
- Function tabs available from within Search Applicants: Pending Exams, Import Application.

---

## 8. Clinical Standards and Disposition Tables (from AME Guide)

### 8.1 General Legal/Authority Framework
- Authority: 49 U.S.C. §§ 109(9), 40113(a), 44701–44703, 44709.
- Approximately 450,000 applications processed each year.
- AME role: examine, test, and inspect applicants, and issue, defer, or deny certificates based on 14 CFR Part 67.
- AMEs may NOT: self-examine, issue to themselves or immediate family, or author their own medical status reports.
- An AME-issued certificate is affirmed as issued unless reversed within 60 days of examination by the Federal Air Surgeon, a Regional Flight Surgeon (RFS), or the Manager of AMCD. If the FAA requests additional information within 60 days, the officials have another 60 days after receipt of that information to reverse.
- Criminal falsification: 18 U.S.C. §§ 1001, 3571 — fine up to $250,000 and/or 5 years imprisonment.

### 8.2 AME Equipment Requirements (8/27/2025 update)
Required testing equipment must be certified at designation, re-designation, and on request:
- **Visual Acuity:** Standard Snellen distance chart with eye lane and lighting; FAA Form 8500-1 Near Vision Acuity Card; opaque eye occluder. (Or commercial device giving distance + near acuity in Snellen equivalents as Exception 1.B.)
- **Phoria Testing:** Must have at least one of (Risley rotary prism, prism bars horizontal+vertical, individual hand prisms); a Maddox Rod (Risley-integrated or handheld); and an eye muscle test light (muscle light, ophthalmoscope light, or 0.5 cm penlight).
- **Color Vision:** Must have or refer to one of Color Assessment & Diagnosis (CAD), Rabin Cone Test (RCCT, Air Force/Army/Navy/Coast Guard version), or Waggoner Computerized Color Vision Test.
- **Field of Vision:** Direct confrontation (4 quadrants) OR 50-inch black felt/dull wall target with 2 mm white test pin OR visual field perimeter (4 quadrants).
- **Other Office Equipment:** Computer with internet + printer; diagnostic instruments; height/weight equipment; urinalysis dipsticks for albumin + sugar (dipstick expiration date must be tracked).
- **Senior AME Additional Equipment:** Access to 12-lead EKG/ECG equipment, recorded at 25 mm/sec at 10 mV. Anything less is not accepted.

### 8.3 Medical History Items (Item 18)
Item 18 drives downstream document requirements. Applicant yes/no medical history covers prior conditions across all body systems. Each "yes" may trigger a disposition table requiring specific evaluations, narratives, and status reports. These should be enforced at data-entry time to prevent incomplete submissions.

### 8.4 Certification Authorities — AASI, SI, and CACI
The AME Guide documents three certification pathways beyond direct issuance:
- **Regular issuance** — AME issues certificate directly.
- **AME Assisted Special Issuance (AASI)** — dedicated disposition tables for ~40 conditions including: Aortic Insufficiency; Arthritis/Psoriasis; Asthma; Atrial Fibrillation; Bladder/Breast/Colon/Colorectal/Prostate/Renal/Testicular Cancer; Single Valve Replacement; Cerebrovascular Disease (CVA/Stroke/TIA); Chronic Kidney Disease (CKD); Chronic Lymphocytic Leukemia (CLL)/Small Lymphocytic Lymphoma (SLL); COPD; Colitis (UC/Crohn's)/IBS; Mitral Valve Disease; Neurofibromatosis Type 1 (NF1); Paroxysmal Atrial Tachycardia (PAT); Prediabetes or Overweight/Obesity treated with medication; Psoriasis; Renal Calculi; Sleep Apnea/OSA; Thrombocytopenia.
- **Conditions AMEs Can Issue (CACI)** — pre-defined worksheets at `www.faa.gov/go/caci`.
- **Special Issuance (SI)** — by Federal Air Surgeon; managed outside AME authority.

### 8.5 Disposition Tables (Partial Inventory — Item 25–48 Body Systems)
- Item 25 - Head
- Item 26 - Nose
- Item 27 - Sinuses
- Item 28 - Mouth and Throat
- Item 29 - Ears, General
- Items 31–34 - Eye (Distant/Near/Intermediate vision, ophthalmoscopic, pupils, ocular motility)
- Item 35 - Lungs and Chest
- Item 36 - Heart (including Coronary Heart Disease)
- Item 37 - Vascular System
- Item 38 - Abdomen and Viscera
- Item 39 - Anus
- Item 40 - Skin
- Item 41 - G-U System
- Items 42–43 - Musculoskeletal
- Item 44 - Identifying Body Marks, Scars, Tattoos
- Item 45 - Lymphatics
- Item 46 - Neurologic
- Item 47 - Psychiatric
- Item 48 - General Systemic
- Items 50–52 - Distant/Near/Intermediate/Color Vision
- Plus protocols: CAC scoring / CCTA, Cardiac Transplant, Cardiac Valve Replacement, Conductive Keratoplasty, CHD 1st/2nd class + ATCS vs. 3rd class, SSRI (neuropsychological evaluation specifications), Diabetes Mellitus (diet-controlled, meds-not-insulin, ITDM CGM option, ITDM non-CGM 3rd class option), Maximal Graded Exercise Stress Test, HIV, Initial Pacemaker Evaluation, Medication-Controlled Metabolic Syndrome, Musculoskeletal Evaluation, Neurologic Evaluation, OSA, Peptic Ulcer, Psychiatric Evaluations.

### 8.6 Medication / Substance Rules
The Medications section of the AME Guide indexes acceptable and disqualifying medications by category: Contraceptives/Hormone Replacement, Controlled Substances and CBD Products, COVID-19 Medication, Diabetes (Insulin-Treated and Type II Medication-Controlled + Acceptable Combinations), Erectile Dysfunction and Benign Prostatic Hyperplasia, Eye Medications, Glaucoma and Ocular Hypertension, Plaquenil Status Report, Malaria Medications, Over-the-Counter (OTC) Reference Guide, Sedatives, Sleep Aids, Vaccines, Weight Loss Medication.

### 8.7 Substances of Dependence / Abuse and HIMS
HIMS (Human Intervention Motivational Study) program requires a dedicated workflow: AME Checklist; AME Report; Neuropsychologist Report; Psychiatrist Report; Psychologist Report — tracked through document taxonomy. HIMS AME locator at `https://www.faa.gov/pilots/amelocator`.

### 8.8 Update Cadence
AME Guide updates are published on the **last Wednesday of each month**, except November and December. Implementations should reference the guide version string (e.g., "Version 03/25/2026") and provide a mechanism to notify AMEs when disposition tables change.

---

## 9. AMCS Home Page Links

The AMCS Home page exposes:
- Aerospace Medical Certification Subsystem (AMCS) application link.
- AME Administration application link (used by AME to validate staff every 90 days — see 1.2).
- Messages box.
- Change Password.
- Logout.

---

## 10. Integration / Inter-System Requirements Surfaced

- MedXPress confirmation number must be traceable across systems (MedXPress → AMCS Import → AMCS Exam → certificate number assigned on import).
- AME serial number lifecycle governs AMCS staff access — inactive serial triggers staff lockouts.
- ECG upload is a gating requirement for transmission when disposition requires ECG.
- Post-transmission document uploads tie to AME-of-record until the next exam transmission overwrites the association.
- AMCD Document Handling (downstream, internal FAA) modifies document metadata after transmission and may rename files with "Document Error - …" prefixes that are visible in AMCS.

---

## 11. Gaps / Items Not Extracted

- **MedXPress screen-by-screen applicant flow:** `medxpress-user-guide.pdf` is a scanned image-only PDF. Applicant-side field validation, privacy acceptance flow, confirmation number generation, and item-by-item 8500-8 entry rules must be sourced from the running system or a text-based copy of the user guide (requires OCR or an updated source document).
- Exact data dictionary for Items 1–20 and 21–48 is partially inferable from the taxonomy above but full field-level validations (min/max, formats, conditional required) require live-system inspection or the PIA data-flow appendix.
