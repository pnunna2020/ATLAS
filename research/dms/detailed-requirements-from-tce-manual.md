# DMS Detailed Requirements — Extracted from TCE External User Manual, Login.gov User Guide, and Order 8000.95D

Scope: deeper requirements extracted from three source documents in `research/dms/docs/`:
- `tce-external-user-manual.pdf` — TCE External User Software Manual (Version 2.0, November 2023, 124 pages, CAN Softtech Contract 692M15-19-C-00009)
- `dms-external-user-manual.pdf` — Login.gov User Guide for DMS (Version 1.0, June 23, 2025, 18 pages, CAN Softtech Contract 692M15-23-C-00003)
- FAA Order 8000.95D, Designee Management Policy — Volume 1 common policy plus designee-type-specific volumes 2–10 (cancels 8000.95C dated 2023-09-21)

These supplement `research/dms/functional-requirements.md` and `current-state-analysis.md`.

---

## 1. Authoritative Policy Framework (Order 8000.95D)

### 1.1 Purpose, authority, and scope

- Order issued by FAA Aviation Safety (AVS). Policy owner: **AVS-60** (ODA Office). AVS-60 authors Volume 1 and coordinates all revisions.
- Legal authority: **49 U.S.C. § 44702(d)** — Administrator's statutory power to delegate to a qualified private person. Implementing regulations: **14 CFR Part 183**.
- Order cancels FAA Order 8000.95C (dated 2023-09-21).
- Order structure: **Volume 1 common policy + Volumes 2–10 designee-type-specific**. Deviations from Volume 1 require AVS-60 approval; deviations from Volumes 2–10 are approved by the responsible service office. Cross-organization deviations must be coordinated with AVS-60.
- Technical support: **AVS National IT Service Desk 844-322-6948 / helpdesk@faa.gov** (system issues).

### 1.2 Designee types covered (Volume assignment)

| Volume | Designee Type(s) | Responsible Office |
|---|---|---|
| 2 | Aviation Medical Examiner (AME) | AAM-400 |
| 3 | Designated Pilot Examiner (DPE), Specialty Aircraft Examiner (SAE), Administrative Pilot Examiner (Admin PE) | AFS-800 |
| 4 | Designated Aircraft Dispatcher Examiner (DADE) | AFS-800 |
| 5 | Designated Mechanic Examiner (DME), Designated Parachute Rigger Examiner (DPRE), Designated Airworthiness Representative – Maintenance (DAR-T) | AFS-800 |
| 6 | Aircrew Program Designee (APD) — encompasses "aircrew designated examiners" in 14 CFR Part 121 | AFS-800 |
| 7 | Training Center Evaluator (TCE) | AFS-800 |
| 8 | Designated Manufacturing Inspection Representative (DMIR), Designated Airworthiness Representative—Manufacturing (DAR-F) | AIR-600 |
| 9 | Designated Engineering Representative (DER) — DER-Y Company and DER-T Consultant | AIR-600 |
| 10 | Designated Control Tower Operator Examiner (DCTO-E) | AOV-200 |

Not covered: Organization Designation Authorization (ODA) holders.

### 1.3 Designation principles (Volume 1 Chapter 1 §3)

- **Privilege, not a right** — FAA may rescind at any time, for any reason.
- **Conduct** — no action that casts doubt on integrity or brings discredit.
- **Knowledgeable** — must be qualified and competent.
- **Risk-Based Approach** — mandatory across all designee programs.
- **Essential** — delegation programs serve an essential FAA function.
- **Need and Ability** — FAA must demonstrate both before appointment.

### 1.4 Employee status

- A designee **is not a U.S. Government employee** and is **not federally protected** for work performed or decisions made as a designee. DMS must display this in the acknowledgment UI.

---

## 2. Application and Eligibility (Order 8000.95D Volume 1 Chapter 2)

### 2.1 Minimum qualifications (all designee types)

- **At least 23 years of age.**
- Meet FAA English language standards per **AC 60-28** (FAA English Language Standard for an FAA Certificate under 14 CFR Parts 61, 63, 65, 107).
- Character: integrity, cooperative attitude, sound judgment, engaged in aviation industry, dependable/professional, objective when performing authorized functions.
- Up-to-date extensive technical knowledge pertinent to the designation sought.
- Any previous FAA working relationship must have been positive.
- May provide 3 verifiable character references and 3 verifiable technical references (references may overlap).

### 2.2 Who is ineligible for appointment

- **Current FAA employees.**
- **Former designees who have been terminated for cause.**

### 2.3 Disqualifying history (7-year lookback, Volume 1 Chapter 2 §4)

Applicant will be disqualified if within the past 7 years they have:
- Been convicted of any local/state/federal **drug or alcohol** violation.
- Been convicted of any **felony offense** (conviction where punishment could have been >1 year, regardless of sentence).
- Been imprisoned, on probation, or on parole because of a felony conviction (civilian or military; includes firearms and explosives violations).
- Been **other than "honorably" discharged** from the military.
- Had an airman certificate (other than medical), rating, or authorization (foreign or domestic) suspended, revoked, or paid a civil penalty for a violation of FAA or foreign CAA regulations.
- Is currently under investigation, charged, indicted, or has a pending action for any of the above.

### 2.4 Application lifecycle in DMS

- **Privilege acknowledgement**: applicant must acknowledge in DMS that designation is a privilege and FAA can terminate any time.
- **Notification model**: DMS emails a generic notification to check the DMS message center; no substantive content in the outbound email.
- **Update cadence**: applicant must validate/verify application data **at least every 12 calendar-months**. Failure to keep current may affect selection eligibility.
- **Retention**: application data saved per **FAA Order 1350.14, Records Management**.
- **Multiple designations**: DMS supports a single individual holding multiple designation types; only **one designee number** per individual across all designations. A separate application is required per designation type.

---

## 3. Selection, Evaluation, and Appointment (Volume 1 Chapters 3–4)

### 3.1 Selection model

- **Applicant pool** — DMS maintains active applicants and produces a list of qualified applicants matching managing office criteria.
- **Selecting Officer (SO)** should complete selection within **30 calendar-days** of list presentation.
- Managing office must validate **need** (new work, increased activity, lost resource, public-driven need) and **ability to manage** (staff skill, workload capacity, travel funding) via DMS questions before selection.
- **Deviation from minimum qualifications**: may be requested if FAA has significant need and applicant meets an equivalent qualification. Service-office-specific rules apply.
- **Evaluation**: SO assigns an evaluation panel; panel lead completes an evaluation checklist in DMS for each candidate. Designee-type-specific policies set the panel composition.

### 3.2 Appointment mechanics

- **Identity verification** required prior to appointment: official government-issued photo ID with signature and residential address (may combine multiple forms).
- **Designee number**: DMS assigns a **unique 9-digit identifier** during application; hidden from the applicant until appointment.
- **CLOA generation**: DMS auto-generates and stores the Certificate Letter of Authority at appointment. CLOA merges letter of authority, certificate of authority, and certificate of designation; it is the record of the designee's authority, limits, and expiration. Designee may print; not required to do so.
- **Appointment duration**: **1 year** from appointment date. Extension handled through the Annual Request to Extend Expiration Date (Chapter 8).

---

## 4. Oversight and Management (Volume 1 Chapter 6)

### 4.1 DMS-recorded oversight activities

DMS captures the following oversight activities (applicability varies by designee type — AME exempted from Direct Observation per Volume 2):
- **Direct Observation**
- **Counseling**
- **Record Feedback**
- **Training Record**
- **Overall Performance Evaluation (OPE)**
- **Suspend**
- **Terminate**

Every oversight activity has: definite beginning + definite end, defined procedures, specific objectives, required report of findings.

### 4.2 Performance measures (used across activities)

- **Technical** — knowledge, skill, correct equipment, appropriate standards, accurate interpretation.
- **Procedural** — correct administrative completion, accurate documentation, compliance with regulations/orders/directives.
- **Professional** — ethics, courtesy, cooperative attitude, tact, effective communication.

### 4.3 Overall Performance Evaluation (Table 1-2)

| Overall Rating | Required Action Against Authority | Follow-up | 6-Month Re-eval? |
|---|---|---|---|
| Satisfactory | None | None | No |
| Needs Improvement | See type-specific volume | Plan + execute oversight | Yes |
| Unsatisfactory — Suspend | Suspend | Plan + execute corrective action | Yes |
| Unsatisfactory — Reduce/Restrict | Change authority | Plan + execute oversight | Yes |
| Unsatisfactory — Terminate | Terminate | N/A | — |

Rules:
- First OPE must occur within **1 year of initial appointment**.
- Satisfactory: next OPE due **12–36 calendar-months** later.
- Needs Improvement / Unsatisfactory: next OPE due **within 6 calendar-months**.
- If a 6-month follow-up OPE is not Satisfactory, designee **will be terminated**.

### 4.4 Authority changes

- **Additional Authorizations**: requested by designee in DMS (or initiated by MS). **Appointing Official (AO)** must approve. If approved, DMS auto-updates the CLOA. Designee shall not exercise any expanded authority until approved and officially notified.
- **Reduce Authority**: MS-initiated or designee-requested. DMS requires MS justification. AO must approve. FAA must re-assess need and ability — if neither holds, the MS initiates "not for cause" termination. DMS auto-updates CLOA when approved.

### 4.5 Investigations

Trigger: oversight findings, internal/external feedback, complaints, alleged misconduct, misuse of authority, or any behavior raising concerns about acting as Representative of the Administrator. Not the same as FAA Order 2150.3 enforcement investigations.

Minimum investigation record elements (recorded in DMS):
- Reason(s) including complaints/allegations
- Evidence collected
- Review of facts and circumstances
- Review of DMS record and relevant FAA databases for patterns
- Designee's response (if any)
- Final decision with specific reasons, additional management actions, designee response, associated documentation

MS may suspend the designee during an investigation (subject to designee-type rules). Suspected criminal activity is referred to the appropriate Law Enforcement Agency after MS consults with management.

### 4.6 Criminal-charge reporting (Volume 1 Chapter 5)

- Designees must **report in writing any arrest, indictment, or conviction** (local/state/federal) to the MS **within 30 days**.
- Upon receipt, MS must **suspend the designee** and initiate an investigation.
- Managing offices forward the report and investigation results to **AVS-60 at 9-AWA-AVS-DesigneeDirectives@faa.gov**.

### 4.7 Record Note feature

- MSs can create a **personal note** in DMS — digital sticky note, **not part of the designee's official record**, visible only to the author. Explicitly not to be used for performance-related documentation.

### 4.8 Messaging

- MSs can send messages to one or more assigned designees via DMS.
- DMS stores send timestamp and the timestamp of when the designee opened the message.
- Designees are required to monitor DMS for new messages.

### 4.9 Feedback capture

- Any FAA employee with DMS access can enter feedback on a designee.
- If feedback author ≠ MS, DMS notifies the MS.
- Feedback categories: **Corrective**, **Evaluative**, **Instructional**, **Compliments/Critiques/Suggestions**.

---

## 5. Annual Request to Extend Expiration Date (Volume 1 Chapter 8)

### 5.1 Timing

- Action item appears on the designee's DMS home page **60 days before expiration**.
- If not completed by expiration, DMS sets status to **"expired"** — designee is no longer authorized to perform duties and has limited DMS access.
- Status returns to active upon completion of the action.

### 5.2 Extension checks (designee must attest)

- In good standing
- No violation history
- Current on all required training
- No arrests or convictions
- No airman certificate/rating/authorization suspension, revocation, or civil penalty for any FAA or CAA regulation violation (foreign or domestic)

### 5.3 Extension effect

- Upon successful submission, expiration date is extended **12 months to the last day of the month**.
- CLOA is updated automatically with the new expiration date.

### 5.4 Non-submittal

- Failure to submit triggers FAA termination under Chapter 9.
- Termination for non-submittal is **"not for cause"** — designee may reapply or be reinstated per designee-specific policy.

### 5.5 Suspended designees

- Suspended designees may qualify for extension but **must be in active status** to submit the annual request.

---

## 6. Termination (Volume 1 Chapter 9) and Suspension (Volume 1 Chapter 10)

### 6.1 Termination types

- **Voluntary surrender** — designee initiated in DMS; each designation surrendered separately; does not preclude reapplication. **Cannot** be submitted once DMS has notified the designee of suspension based on a pending termination for cause.
- **FAA-initiated not for cause** — reasons include lack of need, FAA inability to manage, designee no longer meets minimum qualifications, fails training requirements, physically unable, did not extend, authority expired while suspended, deceased.
- **FAA-initiated for cause** — performance deficiencies, lack of integrity, misconduct, inability to work with FAA/public, improper representation, or any reason considered appropriate by the Administrator.

### 6.2 For-cause process

- **MS initiates termination for cause.** Once initiated, designee **status is set to "suspended"** during the termination process.
- **Designee response window**: **15 calendar days** to respond in DMS after MS initiates the for-cause action.
- **AO initiates a Termination For Cause Review Panel.**
  - Designee with one designation: panel composition per designee-type volume.
  - Designee with multiple designations: panel = AO from initiating office (POC) + AO for each other designation + representative from associated policy offices.
- Panel recommendation must be returned **within 45 calendar-days** of process initiation.
- AO for each designation makes the final termination decision per designation. Decisions are final and conclude the process.

### 6.3 Suspension mechanics

- **Suspended status** in DMS: designee cannot initiate new work; all previously approved activities cancelled where applicable; designee may submit post-activity entries for up to **7 calendar-days** after suspension date.
- **Suspension release**: designee may request release in DMS when they believe requirements are met.
- **Maximum suspension duration**: **180 calendar-days**. If deficiency not corrected by day 180, DMS notifies the MS to remove the suspension and initiate termination.

### 6.4 FAA-initiated suspension triggers

- Lapse in minimum qualifications (lost certificate, rating, license; lost currency/knowledge/proficiency).
- Failure to attend a required meeting.
- Poor performance (unsatisfactory level).
- (Additional type-specific triggers per Volume 2–10.)

---

## 7. TCE External User Software Manual (Version 2.0, Nov 2023)

This section captures screen-level and workflow requirements that the Volume 1 policy makes general. TCE is the DMS reference case — most designee-type UIs mirror it.

### 7.1 Revision history (shows DMS feature trajectory)

| Version | Date | Change |
|---|---|---|
| 1.0 | 2021-02-16 | Initial TCE ESUM release |
| 1.1 | 2021-06-28 | Added Company Administrator Role |
| 1.2 | 2021-08-09 | Added Annual Request to Extend Expiration Dates |
| 1.3 | 2022-06-15 | Updated UI + new Authorizations |
| 1.4 | 2023-11-30 | Updated Background Questions + action links |

### 7.2 Application workflow — tabs and gates

The Create Application process follows a fixed tab sequence; each tab gates the next via a Continue button (Save/Cancel also available on data tabs).

1. **Agreements** — two-part: Designee Acknowledgement Statement (I Agree) + FAA Designee Program (Accept). Decline → warning; persistent decline returns to home.
2. **Designee Types** — select designee type; Designee Questions display based on selection. Answering "No" to the FAA flight engineer certificate question for TCE triggers a pop-up advising exit (ineligibility gate). FTN lookup note directs user to IACRA.
3. **Create Personal Profile** — contact info, optional photo upload, personal address, mailing address (checkbox "Same as Personal Address").
4. **Background Questions** — all required Yes/No. Answers determine "Eligible" vs "Ineligible" pool status.
5. **Designation Location** — select FAA office from dropdown, enter training-center name/certificate designator, enter Primary Work Location Facility.
6. **Qualifications** — select authorizations (Select All per category supported); pick make/model/series (M/M/S) per authorization. Supplemental Information Sheet (SIS) template downloadable; user uploads completed SIS and/or resume.
7. **Summary** — review all entered data.
8. **Signature** — acknowledge Release of Information and Certification, check signature box as electronic signature, Submit. Success pop-up on submit.

Post-submit artifact: "TCE application is submitted successfully" message in Message Center.

### 7.3 Home dashboard layout

Three sections: **My Designations**, **Action Required Items**, **My Applications**. Organization is tab-based within each section.

**My Applications fields** (displayed after submit): ID#, Type, Application Status, Submission Date, Expiration Date, Version(s), Action(s). Edit allowed while in "In Progress" status and before selection for evaluation or tie to an active designation.

**My Designations fields** (post-appointment): Designation, Designation Status, Effective Date, Expiration Date, Termination Date, CLOA link, Designation Actions.

### 7.4 Update Personal Profile

- Directly editable: name, contact info, address info, mailing address.
- **Out of scope for DMS** (handled in MyAccess "ManageMyAccessAccount"): Email address, name updates, password changes.
- Acknowledgement confirmation required to save.

### 7.5 Change Designation Location

- Activity History tracks Pending → Completed.
- MS + AO approval required.
- Add Authorized Location button for multi-location designees.

### 7.6 Designation Action page sections

When Action link clicked: **Designation Information**, **Activity Links**, **Activity History**.

Designation Information fields displayed: Designation Type, Authorization(s), Designation Status, Effective Date, Expiration Date, Managing Specialist, Airman Certification Number, Airman Certification Issue Date, FAA Tracking Number (FTN), **Next Direct Observation Due Date**.

### 7.7 Practical Test / Proficiency Check Pre-Approval Request

Tabs: Pre-Approval, Test/Check, Location, Applicant/Application, Documents/Comments, Summary.

**Gating rules:**
- DMS **blocks** creation of a new Pre-Approval Request when the designee has overdue Post Activity Reports.
- Authorizations displayed on Test/Check tab are drawn from the **CLOA**.
- Checkbox constraints: Ground portion only XOR Flight portion only (Ground hides FSTD/Aircraft section; Flight keeps it). FSTD and Aircraft sections are mutually exclusive within the Flight path.
- FSTD path additional field: **"Simulator FAA ID and M/M/S"** (autocomplete after 3 chars, required).
- Aircraft path additional fields: Aircraft Registration Number (optional), Airline Flight Number (optional), Aircraft M/M/S (required autocomplete).
- Time zone default: **(GMT-06:00) Central Time (US & Canada)**. Required.
- Recommending Instructor: N/A checkbox, name field, certificate number field.

**Auto-approval vs manual:** MS may authorize manual or automatic pre-approval per designee authorization. If not auto-approved on submit, the Pre-Approval Submit Message displays before completion.

### 7.8 Administrative Pre-Approval

- Link visible to all TCE designees regardless of administrative authority.
- Same 6-tab structure.
- Location tab defaults to Facility on Record (address pre-populated from primary designation location or CLOA); override to Other Facility allowed.

### 7.9 View Pre-Approval / Post Activity Reports

- Two sections: Pre-Approval Request(s) and Post Activity Report(s).
- Status transitions: Pending → Approved (by MS) → Post Activity Report auto-generated with "Initiated" status → Completed on Post Activity submission.
- Designee can cancel a submitted/approved Pre-Approval via "Cancel This Request" link.
- Report default window: **past 1 year** — "All Data" expands to full history.
- Editing a Post Activity Report creates a **new version** (version history preserved).

### 7.10 Other activity links on the TCE action page

- **Training Record** — populated by MS. Designee views: training course title, training completed date, result, next training due date.
- **Authorizations and Limitations** — designee can see whether each authorization is set to manual or automatic pre-approval.
- **Request Additional Authorizations** — designee selects additional authorizations, provides Supporting Documents (required), completes Release of Information and Certification, signs and submits. AO approval required. On approval, **CLOA is updated**.
- **Voluntary Surrender Request** — submission includes the request itself plus optional Designee Program Feedback Survey. MS approval required. **Designee may reinstate within 1 year of MS approval**; after 1 year, must re-apply.

### 7.11 Action Required Items tasks

- **Corrective Action** — MS initiates; designee receives "Corrective Action assigned by Managing Specialist" notification. Designee enters response text and optional attachments, submits. **MS may return the corrective action task to the designee up to 5 times.**
- **Suspension Release Request** — task available for **180 days** after suspension. Designee enters justification + supporting documents. On denial: "Request for Suspension Release Denied" notification. If denial is followed by MS termination initiation: "Designee Authorization Suspended" notification.
- **Annual Request to Extend Expiration Date** — full 6-tab flow (Designee Questions, User Profile, Background Questions, Attachments, Summary, Sign). 60 days before expiration. 12-month extension. Failure notification: "Designee Profile Update Unsuccessful".
- **Request Reinstatement** — 4 tabs (Reinstatement info, Background Questions, Summary, Sign). Available within **1 year of Voluntary Surrender** approval. After 1 year, must reapply.
- **Respond to Termination For Cause** — **15-day response window**. Link disappears after day 15. Required acknowledgement of Termination For Cause Advisory popup. Status remains "Suspended" throughout until AO final decision.

### 7.12 Company Administrator Role (TCE-specific, added v1.1)

Role: Training Center Facility Managers overseeing FAA Designees reporting to them.

**Application flow:**
1. Request Company Administrator Role → select Company Administrator Type (e.g., Training Center Company Administrator)
2. Company Admin Questions — "No" to first question displays disqualification message; fields are mandatory on "Yes"
3. Company Administrator Location — select FAA Office + contact info
4. Document Upload (optional, multiple documents supported)
5. Summary
6. Signature (electronic)

**Two-step approval**: Selecting Officer (SO) first, then Appointing Officer (AO) of the facility location. Application statuses: **Submitted, Returned for Modification, Approved, Rejected**. Either SO or AO may reject.

On approval, the "Request Company Administrator Role" link is replaced by "Company Administrator Page" link on the home page.

**Company Administrator capabilities:**
- View designees by location / training center (dropdown-selected, filtered to location only)
- View designee information
- View and print designee CLOA / ID Card
- Run **Oversight Activity Report** (required: Start/End Dates, Designee Status, Oversight Activity; optional: Postal Code, City, TCE M/M/S) — also requires Oversight Status; downloadable to Excel.
- Run **Training Report** (required: Start/End Dates, Designee Status; optional: Postal Code, City, TCE M/M/S) — downloadable to Excel.

### 7.13 Message Center

- Inbox on home panel.
- Designees may send messages to their assigned MS.
- Designee receives system notifications for all state transitions: application submitted, MS assigned at appointment, designation events, corrective action assigned, suspension, termination, denial of suspension release, reinstatement outcomes.

### 7.14 CLOA view

- Link is "CLOA" under My Designations.
- CLOA page displays designee information, authorization details, and Certificate of Designation.

### 7.15 Designee Locator (public function)

- "Find Designees" link on **login page** (no authentication required).
- Filters: Designee Types dropdown.
- Two search modes: **Location Search** (any/all of address fields + Designation Type) and **Designee Search** (first name, last name, or both).
- Result columns: designee name, address, class type, managing office.

---

## 8. Login.gov Migration (DMS Login.gov User Guide, June 2025)

### 8.1 Cutover

- **2025-08-04 (Monday)**: FAA requires all DMS users to authenticate via **Login.gov** to access DMS. Identity verification mandatory.

### 8.2 Three-step link process — existing DMS users

Users access DMS through **MyAccess Login/Register**, select **Customer: Public citizens accessing DOT/FAA resources online**, then **"I am an existing external MyAccess user"**, then **"Did you complete the required steps?"**. Three required steps:

**Step 1 — Create Login.gov account**
- Must use the **same email address listed in the MyAccess profile** to create the Login.gov account.
- Complete Login.gov verification.
- **Critical warning**: after account creation, do NOT click "Sign In" directly — doing so creates a **new DMS account**. Proceed to Step 2 to link existing account.

**Step 2 — Associate Login.gov with MyAccess (one-time)**
- Click Step 2 → MyAccess sign-in page.
- Sign in with MyAccess email + password.
- After email verification, MyAccess Profile displays.
- Click "Ready to link your profile to a login.gov account?".
- Click "Sign in with Login.gov", enter Login.gov credentials, complete authentication.
- Accounts now linked. Close browser.

**Step 3 — Sign in with Login.gov**
- ID verification
- Confirm personal information
- Verify phone number
- Re-enter password
- Redirect to DMS login page.

### 8.3 New user flow

- Same MyAccess starting point, but select **"I am a new external MyAccess user"**.
- Proceed through the same 3-step process. Step 1 creates the Login.gov account; verifiable email required; complete authentication steps; then sign in and follow recommended steps.

### 8.4 Support

- **Login.gov**: sign-in issues only — Login.gov cannot create, delete, or manage accounts. Contact page referenced. Phone: **(844) 875-6446**, 24/7. Manage Account options: change password, delete account, change email, change authentication method, relink accounts.
- **DMS-side**: continues to use AVS National IT Service Desk per Order 8000.95D (844-322-6948 / helpdesk@faa.gov).

### 8.5 Implementation requirements for DMS

- Email match between MyAccess and Login.gov enforced.
- Prevent double-account creation when Login.gov sign-in is attempted before the link step — should produce a guided error.
- Identity proofing (ID verification, personal info confirmation, phone verification) is a pre-DMS-login gate, not an in-DMS step.

---

## 9. Terms, Acronyms, and Authoritative Identifiers

### 9.1 DMS roles

| Role | Definition | Source |
|---|---|---|
| Managing Specialist (MS) | FAA personnel with regulatory oversight responsibility; assigned per designation | 8000.95D V1 Ch6 |
| Appointing Official (AO) | Approves authority changes, terminations, Company Admin applications | 8000.95D V1 Ch6, V1 Ch9 |
| Selecting Officer (SO) | Identifies qualified applicants, validates need/ability, approves Company Admin (step 1) | 8000.95D V1 Ch3 |
| Appointing Official (training-center side) | Second approver for Company Admin application | TCE ESUM §7 |
| Company Administrator | Training center manager with location-scoped designee oversight view | TCE ESUM §7 |

### 9.2 Key DMS artifacts

- **CLOA (Certificate Letter of Authority)** — the authoritative single-record output combining Letter of Authority, Certificate of Authority, Certificate of Designation. Auto-generated and auto-updated by DMS.
- **Designee Number** — unique 9-digit identifier, assigned at application, exposed at appointment.
- **FTN (FAA Tracking Number)** — source-of-truth is IACRA; surfaced on the Designation Information section.
- **SIS (Supplemental Information Sheet)** — downloadable template during Qualifications tab.

### 9.3 Referenced FAA orders and regs

- Order 8000.95D — Designee Management Policy
- Order 8000.95C — cancelled by 8000.95D (dated 2023-09-21)
- Order 1350.14 — Records Management (retention basis)
- Order 2150.3 — FAA Compliance and Enforcement Program (explicitly outside DMS investigation scope)
- AC 60-28 — FAA English Language Standard
- 14 CFR Part 183 — Representatives of the Administrator
- 14 CFR Parts 61, 63, 65, 107 — related pilot/airman certification
- 14 CFR Part 121 — carries the "aircrew designated examiners" equivalent to APD
- 49 U.S.C. § 44702(d) — delegation authority

---

## 10. Cross-Cutting Integration and System Requirements

Derived from intersecting the three sources:

1. **DMS ↔ IACRA integration** — DMS defers FTN lookup to IACRA and requires applicants to retrieve FTN from IACRA. Airman certification number and issue date are stored as designation attributes. Integration must preserve ID consistency across both systems.

2. **DMS ↔ MyAccess ↔ Login.gov three-way identity** — After August 2025, authentication requires all three. DMS is the relying application; Login.gov is the identity provider; MyAccess is the linkage/profile layer. Email address is the join key and must match across layers.

3. **DMS ↔ CLOA as authoritative view** — CLOA is generated, updated, and revoked by DMS as a side effect of oversight and authority actions. External users (Company Admins, external FAA staff) consume CLOA as a read-only record. Any capability change (request additional authorizations, reduce authority, change location, annual extension) must result in a CLOA update.

4. **Records retention** — Order 1350.14 governs DMS application and oversight records. DMS must support the annual-update cycle for applicant data (12-month freshness) and the designee-lifecycle retention for active designees.

5. **Workflow gates are hard gates** — DMS blocks new Pre-Approval Requests when overdue Post Activity Reports exist; blocks voluntary surrender after termination-for-cause suspension; blocks extension for expired designees (requires active status). These are design-level rules, not soft warnings.

6. **Two-approver pattern** — Multiple workflows require two approvers in sequence: Company Administrator application (SO then AO), termination for cause decisions (MS initiates, AO decides via panel), corrective action (MS issues, designee responds, MS approves). DMS must express these explicitly.

7. **Panel workflows** — Termination For Cause Review Panel (45-day SLA) and Evaluation Panel (selection phase) are structured multi-person review activities. DMS must support panel assembly, document/evidence sharing, and recommendation capture.

8. **Timer-driven UI** — Numerous hard deadlines should surface as countdowns or task expiry in DMS: 15-day response to termination for cause, 30-day criminal-charge reporting, 60-day pre-expiration extension task, 180-day suspension release window, 30-day selection timeframe for SO, 45-day panel recommendation SLA, 7-day post-suspension post-activity window, 1-year reinstatement window. These should not be free-form dates — they should drive state transitions automatically.

9. **Notification-only email outbound** — Per Order 8000.95D, DMS sends generic emails to check the Message Center. Substantive content never leaves DMS. All messaging, corrective action text, denial reasons, and acknowledgements are inside the Message Center.

10. **Role-scoped Company Admin visibility** — Company Admins see designees for their location/training center only; reports are location-filtered. DMS must enforce this at the query layer, not just the UI.

---

## 11. Designee-Type Volume Notes

### 11.1 AME (Volume 2, AAM-400)

- **AME is exempt from Direct Observation** (Volume 2 Chapter 6 §1).
- Corrective action may be considered when AMEs are unable to consistently transmit data.
- Termination for cause panel: convened by Deputy Federal Air Surgeon (DFAS) plus others specified in Volume 2.
- Primary audience: Manager/AO, Regional Flight Surgeons / AO (RFS/AO), AME Program Analysts/MS.

### 11.2 DPE / SAE / Admin PE (Volume 3, AFS-800)

- CLOA explicitly lists authorizations at certificate levels (general aviation pilot examiner scope).
- Make/model or type-rating listings on CLOA required per authorization category:
  - FSTD for any make/model: CLOA lists FSTD authorization.
  - Minimum PIC experience not required for certain aircraft shown on CLOA.
  - Pilot type rating: examiner's CLOA must list the specific type rating.
  - Helicopter: each make and model of helicopter listed on CLOA; or class "single-engine turbine" listed.
  - Each BAE (Bi-Annual Examiner?) activity listed on CLOA must be trained and documented.

### 11.3 TCE (Volume 7, AFS-800)

- Full reference case — see Section 7 above for screen-level detail.

### 11.4 Remaining volumes

- Volume 4 (DADE), Volume 5 (DME/DPRE/DAR-T), Volume 6 (APD), Volume 8 (DMIR/DAR-F), Volume 9 (DER — Company DER-Y and Consultant DER-T), Volume 10 (DCTO-E) — each contains specific eligibility, evaluation, oversight, and training requirements layered on Volume 1 common policy. Refer to the source document for field-level detail when implementing each designee type.

---

## 12. Gaps / Items Requiring Additional Source Material

Not covered in the three processed PDFs:
- **Service-office-specific evaluation checklists** (per Chapter 3 of each type-specific volume).
- **Direct Observation procedures** for each designee type (in Chapter 6 of each volume).
- **Training curriculum details** (Chapter 7 of each volume).
- **DMS company-designee workflows** (the order references company-designee voluntary surrender via the designee's MS but doesn't detail full company-designee management).
- **MyAccess profile and staff validation cycles** — DMS references MyAccess for email/name/password but no MyAccess admin manual is in the corpus.
- **Field-level data dictionary for all designee types** — TCE ESUM provides TCE specifics; non-TCE volumes likely have comparable detail in separate user manuals not present in `research/dms/docs/`.
- **DMS ↔ IACRA integration spec** — only referenced via FTN note in the TCE ESUM.
- **DMS reporting data model** for Oversight Activity Report, Training Report, etc.

These should be added to `research/dms/docs/` and re-extracted for a complete requirements baseline.
