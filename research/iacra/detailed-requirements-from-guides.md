# IACRA Detailed Requirements — Extracted from IACRA Consolidated User Guide (Dec 2018, v1.0, 210 pages)

Source: `research/iacra/docs/iacra-consolidated-user-guide.pdf`

This document captures field-level validation rules, workflow state transitions, screen flows, role behaviors, and business rules that were not fully surfaced in the initial `functional-requirements.md`. Section numbers refer to the source user manual.

---

## 1. Role Catalog and Access Semantics (§1.1, Table 1-1)

The IACRA role model is the authoritative list and the source of access control. Each role has both a registration pathway and distinct runtime privileges.

| Role | Description (verbatim from manual) | Key access behavior |
|------|------------------------------------|---------------------|
| Applicant | Any person applying for an airman certificate. | Default registration; creates FTN. |
| Recommending Instructor (RI) | Any person authorized to instruct applicants and considers them ready for the practical test. | Signs/recommends applications. Validated against NVIS. |
| Designated Examiner | Any person authorized by the Administrator to issue airman certificates. Prepares applicants and issues practical tests. | Certifying Officer (CO) role. Designee Number required. |
| Aviation Safety Inspector / Technician (ASI/AST) | FAA personnel authorized to issue specific airman certificates. | CO role + Designee Oversight. FAA PIV login. |
| School Administrator | 14 CFR 141 School / 14 CFR part 142. Completes all sections of student applications that students can complete. Cannot complete RI/CO sections, cannot sign for student. | Requires ACR/TCE validation OR FAA NSD call before first login. |
| Chief / Assistant Chief Flight Instructors | Instructs applicants and authorizes them to take a practical test. Does NOT include regular flight instructors. | Must match NVIS listing exactly. |
| Airman Certification Representative (ACR) | Authorized by Administrator to issue specific airman certificates. | Can validate School Administrators. Designee Number required. |
| Training Center Evaluator (TCE) | Part 142 training center representative. Performs evaluations and issues certificates. | Can act as either RI or CO on a given application. Can validate School Administrators. Designee Number required. |
| Flight Instructor Renewal Examiner (FIRE) | Designated Examiner authorized to renew CFI certificates via Renewal by Activities and Renewal by FIRC. | Specialized CO subtype. |
| Aircrew Program Designee (APD) | Authorized to perform airman certification in one type of aircraft for an operator's pilots trained under the operator's FAA-approved training program. | Type-aircraft-scoped CO. |
| 142 Recommending Instructor | Associated with a particular 142 training program. Does NOT need a current Flight Instructor certificate. | Exception to RI certificate-holding rule. |
| Air Carrier Flight Instructor | Can sign applicant's training records/logbook and make required endorsements. Can sign CFR 121/135 pilot applications if applicant previously failed a rating, and sign 121/135 Second in Command applications. | Managed/authorized by ASI/AST via "Manage Air Carrier Flight Instructors." |

**Role transitions (§2.5.2):**
- `Add Role` — user adds an additional authorization while retaining existing roles.
- `Change Role` — user switches session role without logging out (only visible if ≥ 2 authorized roles).
- `Remove Role` — user relinquishes a role (only visible if ≥ 2 authorized roles).

---

## 2. Registration Process — Field-Level Rules (§2.2, §2.4)

### 2.1 Pre-Registration Data Identifier Requirements (CFR 141/142 staff only, §2.2.1–2.2.2)

Required inputs for School Administrator, Chief/Assistant Chief Flight Instructor, ACR, or TCE registration:
- Airman Certificate number + Date of Issuance.
- School Certificate Number.
- School Designation Code — 4-character alphanumeric, usually first 4 characters of the certificate number.
- Designee Number (ACR or TCE only).

**NVIS matching constraint:** Chief/Assistant Chief Flight Instructors are warned that any nomenclature difference between the name on file and NVIS will delay registration. IACRA reads existing credentials from NVIS.

**School Administrator activation gate:** Must be validated by an ACR or TCE through IACRA, *or* by calling the National FAA IT Service Desk, before they can log in.

### 2.2 Personal Information Fields (§2.4.3, §10.2.1)

Rules pulled from both the registration flow and the Crewmember personal-info section:

- **First Name** — full first name; if none, enter literal `"NFN"` (via "No First Name" checkbox in UI).
- **Middle Name** — full middle name; if none, enter `"NMN"` (via "No Middle Name" checkbox). If only an initial, enter the initial. Use no more than one middle name.
- **Legal Last Name** — required.
- **Name Suffix** — optional, from drop-down.
- **Name change rule:** Do not change name on subsequent applications unless done in accordance with **FAR §61.25**. If applicant holds an FAA pilot certificate, name must match the certificate.
- **Social Security Number (SSN)** — one of three mutually exclusive states:
  1. Provide a valid U.S. SSN (voluntary disclosure).
  2. Check **"Do Not Use"** — the application will render "Do Not Use" on the form; system assigns a unique internal number.
  3. Check **"None"** — applicant has no SSN.
  - **Enforcement:** SSN must be a U.S. SSN only. SSN is cross-referenced with airman certificate number for record lookup but is *not* shown on airman certificates.
- **Date of Birth** — format `mm/dd/yyyy` (8 digits) or calendar widget; must match medical certificate DOB.
- **Sex** — Male/Female radio; keyboard-navigable.
- **Hair Color, Eye Color** — drop-down.
- **Weight** — in pounds.
- **Height** — numeric + unit of measurement drop-down; IACRA converts to inches internally.
- **Phone** — with area code.
- **Email Address** — must be unique across IACRA; cannot be reused by another existing user.

### 2.3 Citizenship (§2.4.4, §10.2.1.2)

- Country of Citizenship (drop-down). Select `USA` for U.S. territories not separately listed.
- City of Birth.
- County of Birth.
- Country of Birth.
- State of Birth — required only when Country of Birth = USA.

### 2.4 Permanent Mailing Address (§2.4.5, §10.2.2.1)

- **FAA policy requires the permanent mailing address.**
- **Residential / Street / Line 1** — street address (USA) or first line of foreign address.
- **PO Box, Rural Route, Commercial** — PO Box / RR / "General Delivery" (USA) or second foreign-address line.
- **Physical Description** — required when no street address is entered (must describe the residence location).
- **City** — Canadian residents must include Province after city name.
- **State** — drop-down (USA addresses only).
- **Country** — drop-down.
- **Zip Code**.

### 2.5 Security Questions, Username, Password (§2.4.7, §2.4.8)

- One security question selected from drop-down, plus free-text answer — used for password reset.
- Username (logon) and Password (entered twice for confirmation).

### 2.6 Post-Registration Artifacts (§2.4.9, §2.5.1)

- System issues **FAA Tracking Number (FTN)** — permanent, unique, applicant-identifying; displayed on applicant console.
- FTN, username, and current role always visible on left navigation.

---

## 3. Authentication and Session (§1.3, §2.5, §2.6)

- Supported browsers: **IE 11, Chrome, Firefox**.
- Three login paths:
  1. Username + password (public web form).
  2. **"FAA Employee Login"** — valid FAA PIV card.
  3. Registration for new users.
- All users must **accept the Terms of Service** before every session-level use.
- **Forgot Username/Password flow (§2.6.1–2.6.2):** user enters email, username, or both; system emails a temporary password; user is forced to change password on first login afterwards.
- **Change Password (§2.6.3):** requires login; accessed via left-nav under the specific role; user is logged out and must re-login with new password.
- **NSD contact (§1.4):** 24/7, toll-free `1-844-FAA-MYIT (322-6948)`, email `helpdesk@faa.gov`. Users must attempt online/email password recovery *before* contacting NSD.

---

## 4. Applicant Console — Workflow States (§2.5.4)

The Applicant Console exposes application lifecycle actions gated by application state:

| State / Action | Condition | Behavior |
|----------------|-----------|----------|
| Start New Application | Always available | Begins new application flow. |
| Continue an Application | Application started but not submitted | Appears under Available Actions; user picks `Continue` + `GO`. |
| Delete an Application | Only available **prior to submission** (§2.1.1 confirms trashcan on Retrieve page) | Irreversible — deleted applications cannot be retrieved. |
| View/Print | Application is `Submitted` or `Signed by Applicant` | Only available option in those two states. |
| Airman Information | Any state | Reads current Airman Certificate data + ratings from Airman database. |

**User Preferences (§2.5.2):** user can choose default document view format — **TIFF or PDF**. Selection is persistent and applies to all document renders.

---

## 5. Application Workflow States and Transitions

### 5.1 Six-Step Linear Flow (Pilot path — §4, §9, §10)

1. **Application Type** — select Pilot / Crewmember / Airworthiness / etc.
2. **Certifications** — select certificate sought + path (CFR 61 / 141 / 142 / 121 / 135 / Military Competency / Foreign-Based / AQP).
3. **Personal Information** — pre-filled from registration, verified against Airman Registry (see §5.3).
4. **Required Questions** — Medical Certificate, Drug Conviction, Language, Failures.
5. **Certificate-Specific Data** — certificate held, category/class rating, type rating, pilot time grid.
6. **Review and Submit** — summary validation, digital signature.

### 5.2 Step Indicator Semantics (§9.5, §10.6)

On the step navigation bar:
- **Green check mark** — all required information provided and validation passed.
- **Yellow question mark** — required info missing for that step.
- **Red "X"** — step has not been accessed.

All validations must resolve (no yellow/red) before `Review Applicant's Certificate Summary` enables; then the Certificate Summary must be reviewed before `Review Application` enables; then the Application must be reviewed before `Submit Application` enables.

### 5.3 Registry-Sourced Data (Immutable Fields, §4.5)

After first registration, the following cannot be updated through IACRA because they live in the Airman Registry:
- Full Name
- Date of Birth
- Sex
- Citizenship country

IACRA surfaces a link to Airman Registry update guidelines instead of an edit widget.

### 5.4 Post-Submission Rules (§9.5, §10.6)

- Once submitted, **the applicant cannot access the application file again**.
- Corrections require an RI or Examiner/Evaluator to **reset** the application.
- Applicants can view and print an **Unofficial Copy** after submission.
- End-state documents are one of: **Temporary Certificate**, **Notice of Disapproval**, or **Letter of Discontinuance**.

### 5.5 Pilot Time Import (§4.9.1)

- IACRA auto-imports pilot hours from any *previous* application the FTN has submitted.
- The applicant may also explicitly `Import` hours from another selected prior application into the aeronautical experience grid.

---

## 6. Certification Path Coverage (§3, §4.2)

The system supports these pilot certificate paths, each with distinct required-question branches and validation rules:

**Airline Transport Pilot (ATP)** — Standard and With Restricted Privileges (§61.160):
- CFR 61 (Completion of Required Test) — Original Issuance / Added Cat-Class / Added Type / Vintage Aircraft Authorization / Second in Command.
- CFR 141 (Graduate of Approved Course) — adds "Added Instrument Rating" path.
- CFR 142 (Graduate of Approved Course).
- CFR 121 — Training Program and Advanced Qualification Program (AQP); sub-types: Initial / Upgrade / Transition / Second in Command (§4.3.3).
- CFR 135 (Training Program).
- Military Competency (PIC military hours, PIC qualification / AGL-230 training program).

**Commercial, Private, Recreational, Sport, Student, Remote Pilot** — each has CFR 61 / 141 / 142 sub-paths plus Foreign-Based and Foreign-Based (Add U.S. Test Passed) for Private.

**Flight Review / Instrument Proficiency Check** — separate non-certification path under Pilot Type.

**Crewmember:** Flight Engineer (Standard / Restricted Foreign-Based CFR 63.42 / Restricted Special Purpose CFR 63.23 / Original / Renewal) and Aircraft Dispatcher (Experience / Graduate Certificate).

**UI mode selector (§4.4):**
- Horizontal tabs: Commercial, Private, Recreational, Sport.
- Vertical pull-downs: ATP, Student, Remote, Flight Review/IPC.

---

## 7. Certificate Sought — Field Validation

### 7.1 Category/Class Rating Selection (§4.6.1, §9.4.2)

- Single Selection Search screen — user enters at least one alpha character, clicks Search, picks one rating.
- **Constraint:** only one Category/Class rating per application.

### 7.2 Type Rating Selection (§4.3.2)

- Single Selection Search — enter one alpha character of the aircraft model description, select model, `Start or update application`.
- **Constraint:** only one aircraft type rating per application.

### 7.3 Completion of Required Tests (§4.6.2, §4.8.1)

- Aircraft 1: Make/Model (search-by-first-letter), Total Time, PIC Time.
- Aircraft 2: optional second-aircraft test information.
- Simulator/Training Device information.
- All hours numeric; PIC Time optional; Total Time required.

### 7.4 Certificates Held (§4.7)

- **English Language Question (§4.7.1):** Yes/No. If No → "Non-medical reason?" follow-up → if Non-medical reason = Yes → **hard stop**: *"If you have a non-medical reason for not using the English language, you cannot use IACRA at this time."*
- **FAA Certificate (§4.7.2–4.7.3):** existing certificates pre-populated from Airman Database with Add / Modify / Save Certificate / Delete Certificate actions. To add a certificate not in the Airman Database, user checks a box and selects type (US Standard Pilot Certificate, etc.), expands the tree (Commercial Category/Class Ratings, etc.), picks category + ratings, enters Certificate Number and Date Issued.
- **Medical Certificate (§4.7.4, §9.4.3, §10.4.3):** if Yes → required fields: Date of Issue, Class (First / Second / Third), Examiner's name (as shown on medical certificate).
- **Drug Conviction (§4.7.5, §9.4.4, §10.4.4):** radio Yes/No. Only click Yes if *actually convicted* — not merely charged. If Yes → Date of Conviction `mm/dd/yyyy`.

### 7.5 Summary Page Validation (§9.5, §10.6)

Review order strictly enforced by button-enabling:
1. All validations green.
2. `Review Applicant's Certificate Summary` — required before next button enables.
3. `Review Application` — required before Submit enables.
4. `Submit Application` — terminal; no further applicant edits.

---

## 8. Certifying Officer (CO) Checklist — Workflow (§11)

### 8.1 Retrieval (§11 figure 11-1)

- Console supports **multi-criteria search**: FTN, applicant full/partial name, Application ID (exact or starts-with), CO full/partial name, From/To Date (default From = 1 year ago, To = today), Designee type (DE / ASI / AST / ACR / TCE / APD / All).

### 8.2 Checklist Steps (§11.1)

| Step | Link | Mandatory? | Behavior |
|------|------|-----------|----------|
| 11.1.1 | Application Options | Conditional | Edit (minor changes — returns to applicant for re-submit), Return application (major — returns to applicant's console), Add Comments on 8710. |
| 11.1.2 | Airman's Identification | **Mandatory** for all certifications | Select Form of ID: USA Driver's License (default, requires number, state, expiration), Passport (number, expiration, issuing country), Military ID, Student ID, Other Government Issued Document (requires free-text type + number + expiration). |
| 11.1.3 | Aviation English Language Standard | Auto | Pre-verified from earlier step. |
| 11.1.4 | Knowledge Test | View-only | Renders Airman Knowledge Test Report in new window. |
| 11.1.5 | Applicant Signature | Mandatory | CO reviews application, checks **Privacy Act** checkbox, checks **Pilot's Bill of Rights** checkbox → Applicant Login button enables. Applicant signs Pilot's Bill of Rights Acknowledgment first, then Reviews and Signs Application. |
| 11.1.9 | Graduation Date (121/135 only) | Conditional | Graduation date must be within **12 calendar months** of application submission date. Displays in Section IIE on 8710-1. |
| 11.1.10 | Limitations | Mandatory (CO must open) | Previous limitations auto-loaded; CO can Add (search 1-char, Show All, or paginate) / Remove / enter free-text for certain limitations. **Mandatory limitations are lock-icon protected — system-generated, cannot be removed.** |
| 11.1.11 | Summary Information | Review step | Certificate Summary + Application Status. |
| 11.1.12 | Sign Application | Mandatory | If applicant did not sign Pilot's Bill of Rights Acknowledgment, CO must sign the lower portion certifying they provided a copy to the applicant. Then Click to Sign → Sign Application. Returns to Sign Another / Logoff. |

### 8.3 Pilot's Bill of Rights Gate (§11.1.12)

The CO cannot sign until one of two preconditions is true:
- Applicant signed the Pilot's Bill of Rights Acknowledgment during Applicant Signature, OR
- CO has signed the lower portion of that acknowledgment attesting that a copy was provided to the applicant.

### 8.4 Edit Pathway — Session Hand-off (§11.1.1)

When CO selects `Edit` on the application, system:
1. Logs CO out of the application.
2. Returns to **applicant login** screen so applicant can complete changes.
3. After applicant resubmits with validation, system presents a **CO login box** on the applicant summary page — CO re-authenticates (password) and `Accept TOS & Log In` returns to CO Checklist.

---

## 9. Designee Oversight (§11.2)

Accessible from ASI/AST Options (left nav). Search criteria:
- **From Date / To Date** — From defaults to 1 year ago, To to today; user cannot set From earlier than 1 year before current date.
- **Certifying Officer Type** — All Types / DE / ASI / AST / ACR / TCE / APD.
- **Certifying Officer Name** — full or partial.
- **Application ID** — exact or starts-with.
- **Applicant Name** — full or partial.
- **Certificate Type** — All Types / ATP / Commercial / Flight Instructor / Flight Instructor Sport Pilot / Ground Instructor / Private / Recreational / Repairman Light Sport Aircraft / Sport Pilot / Student.

Result set ordered oldest-first, paginated. Review column displays a drop-down of available forms — **the form set varies by certificate type**.

---

## 10. Manage School Admins / Air Carrier Flight Instructors (§11.4)

- ASI/AST authority — manages Air Agency authorizations.
- Default view lists Air Agencies the role is authorized to manage.
- Search by Air Agency: minimum **1 character** of School/Air Operator name; dropdown shows Designation Codes for matching agencies.
- Per-selected agency, manage School Administrator or Air Carrier Flight Instructor list:
  - Find person by full/partial name or phone.
  - **Disable** action → confirm → authorization removed.
  - **Enable** action → confirm → authorization granted.

---

## 11. School Administrator Workflow (§12)

### 11.1 Affiliation Prerequisites (§12.2.1)

- Student must be **pre-registered in IACRA** before affiliation is possible.
- Affiliation key is the student's **FTN + Last Name**.
- If student lacks an FTN, administrator directs them to register first.
- Page must be **manually refreshed** to see new affiliations appear.

### 11.2 Curriculum Association (§12.2.2)

- Applications that require a curriculum cannot proceed until administrator clicks `Click Here to Add Curriculum` → picks curriculum → `Select Curriculum & Continue`.
- Only then can the student log in and submit.

### 11.3 Upload Documents — Format Constraints (§12.2.3.5)

- Every document page must be uploaded as a **separate file**. Example cited: a three-page foreign verification letter requires three separate uploads.
- **Accepted formats: `.jpg`, `.tif`, `.png` only.**
- Documents viewable/removable from the Uploaded Documents list.

### 11.4 School Admin Retrieval Actions (§12.2.3)

Available actions per application (gated by application state):
- `View/Print` — launches pop-up with Print, Save as TIFF, View/Print PDF, Zoom options.
- `Edit` — pop-up warns application must be resubmitted; on confirm, redirects to Personal Information section.
- `Continue` — appears if prior Edit was abandoned mid-flow.
- `Delete` — prompt + OK confirmation; removes from student's profile.
- `Upload Docs` — opens upload page.
- `Checklist` — routes to Checklist Section or Air Agency Administrator's Checklist (depending on certificate).

### 11.5 Checklist Section (§12.3.1)

- Enter **Knowledge Test Exam ID** → Search → if found, details display → `Associate` to link test to application. `Remove` button unlinks.
- **Final Stage Check link** enters practical test results (see §11.6).

### 11.6 Final Stage Check Data (§12.3.2.2)

Required fields for Final Stage Check:
1. Airport ID + location (via `Select Airport` picker).
2. Oral Test Duration — hours + tenths of hours.
3. Practical Test Duration — hours + tenths of hours (first aircraft).
4. Aircraft Registration number (first aircraft).
5. Make/Model of first aircraft (via `Edit Make, Model` picker).
6. Second Aircraft fields — optional (two aircraft may be used).

### 11.7 Training Center Evaluator Branching (§12.1.1)

On entering the School Admin console, a TCE must first choose whether to perform **Recommending Instructor tasks** or **Certifying Officer tasks** for that session.

### 11.8 Inactive School Gate (§12.1)

If the selected school is inactive, guidance is displayed on the panel and progression is blocked.

---

## 12. Airman Knowledge Test Report Schema (§12.3.2.1)

Reading the Knowledge Test Report generates a pop-up with these fields:
- Student's name
- Applicant's (Application) ID
- Exam title
- Exam ID
- Exam date
- Test site
- Score
- Grade
- Number of attempts
- Certification expiration date

Report can be printed, saved as **TIFF**, or viewed/printed as **PDF**.

---

## 13. Document Format / Output Rules

| Artifact | Formats supported |
|----------|-------------------|
| User default document view (§2.5.2) | TIFF or PDF (user preference, persisted) |
| School Admin View/Print pop-up (§12.2.3.1) | Print, Save as TIFF, View/Print PDF, Zoom |
| School Admin upload (§12.2.3.5) | `.jpg`, `.tif`, `.png` only; one page per file |
| Knowledge Test Report (§12.3.2.1) | Print, TIFF, PDF |

---

## 14. Validation Rules Not Previously Captured

- **Email uniqueness** across IACRA users (§2.4.3) — hard registration blocker.
- **SSN format** — U.S. SSN only; no foreign numbers.
- **Name conformance** — name on application must match name on held FAA pilot certificate unless changed per FAR §61.25.
- **NVIS nomenclature match** — for Chief/Assistant Chief Flight Instructors, any difference with NVIS record blocks or delays registration.
- **School Activation** — School Administrator cannot log in until validated by ACR/TCE or NSD.
- **Single-rating constraint** — one Category/Class and one Type Rating per application.
- **Graduation Date window** — within 12 calendar months of submission for 121/135 curricula.
- **Designee Oversight date range** — From Date cannot be > 1 year before today.
- **Affiliation gate** — Student must be registered and affiliated before Administrator actions unlock.
- **Application Edit by CO** — forces applicant re-auth + re-submission; CO must re-auth on return.
- **English Language non-medical disqualification** — hard stop, cannot proceed in IACRA.
- **Drug Conviction wording** — conviction only, not unresolved charges.
- **Limitations** — mandatory (lock-icon) limitations cannot be removed by CO.

---

## 15. Integration / External System Dependencies Surfaced by the Guide

- **Airman Registry** — pre-fills Name, DOB, Sex, Citizenship; stores certificate holdings and ratings; ground truth for immutable personal data.
- **National Vitals Information System (NVIS)** — pre-registration validation of Chief/Assistant Chief Flight Instructor credentials.
- **Airman Knowledge Test system** — Knowledge Test Exam ID lookup and association; generates Airman Knowledge Test Report.
- **Program Tracking and Reporting Subsystem (PTRS)** — ASI views/reviews designee PTRS records within IACRA.
- **FAA PIV / MyAccess** — FAA Employee Login authentication.
- **Flight Standards District Offices (FSDO)** — CO acknowledges FSDO assignment on Sign Application (§8.3.4).

---

## 16. Acronym Glossary (§1.5) — full list

ACR, APD, AQP, ASI/AST, ATP, CFR/FAR, CO, FAA, FAQ, FIRC, FIRE, FSDO, FTD, FTN, IACRA, IATA, ID, LTA, NFN, NMI, NSD, NVIS, PCATD, PDF, PIC, PTRS, SIC, SSN, TCE, TIFF, TOS.
