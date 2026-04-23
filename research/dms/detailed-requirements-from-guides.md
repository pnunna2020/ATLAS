# DMS Detailed Requirements — Extracted from DPE External User Software Manual (April 2025, v1.4, 110 pages)

Source: `research/dms/docs/dpe-external-user-manual.pdf`
Contract: `692M15-23-C-00003` (CAN Softtech, Inc.)

This document captures field-level validation rules, workflow state transitions, screen-level business rules, and designee lifecycle mechanics not fully surfaced in the initial `functional-requirements.md`. Section numbers refer to the source manual.

---

## 1. DMS Acronyms and Vocabulary

| Term | Definition |
|------|------------|
| AIT | FAA Information Technology |
| CLOA | **Certificate Letter of Authority** — artifact issued on appointment, contains authorizations with **function codes** and **limitations** |
| DMS | Designee Management System |
| DPE | Designated Pilot Examiner |
| ESUM | External Software User Manual |
| FTN | FAA Tracking Number (source of truth: IACRA) |
| IACRA | Integrated Airman Certification and Rating Application |
| MS | **Managing Specialist** — the FAA oversight role attached to each designee |
| AO | **Appointing Official** — concurrence authority for termination decisions |
| SAE | (referenced in pre-registration check) Existing designee type |
| Admin PE | (referenced in pre-registration check) Admin Pilot Examiner type |

---

## 2. Designee Lifecycle and State Machine (§1.1, §§2–5)

DMS implements a finite state machine for each designee, driven by FAA-side (MS/AO) actions and external-user events.

### 2.1 Primary Designee States (from "Designation Status")
- `Applicant` — application in process, pre-appointment
- `Active` — appointed, CLOA issued
- `Suspended` — MS-initiated; triggers suspension release workflow
- `Terminated` — either Voluntary Surrender (approved) or Termination for Cause
- `Reinstated` — transient state; MS moves designee from Terminated back to Active within 1 year

### 2.2 Application Status Values
Shown on the My Applications panel (§3, Figure 33):
- `Submitted`
- `Pending` (for pre-approval requests)
- `Approved`
- `Canceled`
- `Initiated` / `Saved` / `Completed` (post-activity reports)

### 2.3 Canonical State Transitions
- `Applicant → Active`: MS appointment after evaluation; CLOA auto-generated.
- `Active → Suspended`: MS action; suspension release task opens for designee, **180-day window**.
- `Suspended → Active`: MS approves suspension release.
- `Suspended → Terminated (For Cause)`: MS initiates termination; designation status stays `Suspended` through the response window; flips to `Terminated` only after **AO concurrence**.
- `Active → Terminated`: Voluntary Surrender approved by MS.
- `Terminated → Active` (reinstatement): Available only if termination was **not for cause** and within **1 year** of termination. After 1 year, designee must **reapply from scratch**.

---

## 3. Application Process — Tab-by-Tab Field Rules (§2)

The create-application flow is a linear wizard across 8 tabs: **Agreements → Designee Types → Create Personal Profile → Background Questions → Designation Location → Authorizations/Document Upload → Summary → Applicant Signature**.

### 3.1 Agreements Tab (§2.1)

Two sequential agreements, each with Accept/Decline gating:

1. **Designee Acknowledgement Statement** — click `I Agree` → status becomes `Accepted` and FAA Designee Program section appears below.
2. **FAA Designee Program agreement** — click `Accept` to continue.

**Decline behavior:** Either `Decline` opens a **Cancellation Warning** modal — `Yes` returns to Home page and abandons the application; `No` cancels the decline and stays on Agreements tab.

**Save-and-resume:** Every tab has a `Save` button at the bottom; session not required to be completed in one pass.

### 3.2 Designee Types Tab (§2.2)

- User selects `Designated Pilot Examiner (DPE)` (one of multiple designee types).
- Selection reveals **Designee Questions** — applicant must enter requested data (FTN + type-specific screening).

**Blocking validations:**
- **"Are you an existing DPE, SAE, or Admin PE in DMS?" = Yes** → hard stop; system instructs applicant to exit. A designee of these types cannot create a new application.
- **"Do you currently hold a valid FAA pilot certification with rating appropriate to the authentication sought?" = No** → hard stop; system displays DPE Qualifications message.
- FTN can be looked up by logging into IACRA — DMS guides users there.

### 3.3 Create Personal Profile Tab (§2.3)

Captures:
- Contact information
- Home address
- Mailing address
- Photo upload (optional, in Upload Photo section)

Controls: `Save` (persist entries), `Continue` (advance to Background Questions), `Cancel` (abandon).

### 3.4 Background Questions Tab (§2.4)

- **All questions must be answered** before `Continue` advances to Designation Location tab.

### 3.5 Designation Location Tab (§2.5)

- Step 1: Select the **FAA office** of application.
- Step 2: "Same address as Personal Profile" checkbox — if checked, a confirmation message fires:
  > "You indicated your designation location is the same as your personal profile information. This will be published in the FAA online designee locator. If this is in error, please deselect the box and enter your facility information."
- Step 4 (alternative): if unchecked, user enters a distinct facility address for the designation location.

**Key side-effect:** Designation Location is the **public directory** address — it appears in the Designee Locator (§6).

### 3.6 Authorizations and Document Upload Tab (§2.6)

- Authorizations rendered as **checkboxes + dropdowns**.
- **"Select all" option per category** is available.
- Certain authorization types require a **type rating** to be selected with the authorization.
- **Hard cap: 75 type ratings per authorization.**
- DPE-specific questions in the Designee Application Upload section must be answered.
- **Supplemental Information Sheet** — document must be downloaded, filled in, and uploaded as an attachment.
- Additional supporting attachments may be added via `Choose` file picker.

### 3.7 Summary Tab (§2.7)

- Aggregates all prior-tab entries read-only.
- Controls: `Save`, `Back` (exit application), `Continue` (→ Signature), or click any tab to edit.

### 3.8 Applicant Signature Tab (§2.8)

- **Release of Information** — `I Agree` checkbox required.
- **Certification Statement** — `I Agree` checkbox required.
- **Electronic signature box** must be checked.
- `Submit` finalizes; success modal confirms.

---

## 4. Post-Submission Behavior (§3)

### 4.1 My Applications Panel Schema (Figure 33)

Columns: `ID`, `Type`, `Application Status`, `Submission Date`, `Expiration Date`, `Version(s)`, `Action(s)`.

### 4.2 Edit Gating Rule
Per §3 note: the applicant can edit the application **only while both are true**:
- Application is **not tied to an active designation**, AND
- Application has **not been selected for the Evaluation Process**.

### 4.3 Message Center Confirmation
- Success message on submission: `DPE application is submitted successfully`.
- Body disclaims: *"This message does not imply the applicant is qualified nor guarantee selection and/or appointment."*

---

## 5. Profile Management (§3.1)

- Applicants can edit contact info, name, and address; save with `Save`.
- Acknowledgement modal fires on save (`Click here to Acknowledge`).
- Confirmation: green toast `Save Information` top-right.
- **Off-DMS identity updates:** Email, name, and password changes route to **MyAccess → ManageMyAccessAccount** — not editable directly in DMS.

---

## 6. My Designations Panel (§3.2, Figure 40)

Once appointed, the designee sees:
- Designation Type
- Designation Status
- Effective Date
- Expiration Date
- Termination Date
- CLOA (hyperlink → renders the Certificate Letter of Authority)
- Designation Actions (→ Action Links, §9)

The designee receives a Message Center notification with the name of their Managing Specialist upon appointment.

---

## 7. Change Designation Location (§3.3)

- DPE selects a location from the DPE Location(s) dropdown.
- `Add Authorized Location` button permits adding new locations; `Remove` deletes an added location.
- **Approval workflow:** New/changed location requires **both MS and AO approval** before it enters the designee's DMS record.

---

## 8. CLOA — Certificate Letter of Authority (§3.5)

- Auto-generated **upon appointment**.
- Contains: all granted authorizations, **function codes**, **limitations**.
- Access: Home page → My Designations → `CLOA` link.
- Dynamically updated upon Annual Request to Extend Expiration Date approval — expiration date on CLOA shifts forward by 12 months.
- Also updated when Additional Authorizations are approved.

---

## 9. Action Links (§3.6, Figures 49–50)

Available from Home → Action:

**Activity Links:**
1. Create Practical Test/Proficiency Check Pre-approval
2. View Pre-Approval / Post Activity Reports
3. View Training Record
4. Request Additional Authorizations
5. Create Administrative Pre-Approval
6. Request Voluntary Surrender
7. View Authorizations and Limitations
8. Set default time zone
9. Manage make model series

**Activity History** — summary of completed/submitted activities.

---

## 10. Practical Test / Proficiency Check Pre-Approval (§4.1)

### 10.1 Tab flow: Pre-Approval → Test/Check → Location → Applicant/Application → Documents/Comments → Summary

### 10.2 Blocking Rule
> "The system will not allow the designee to create a new pre-approval request if the designee has Post Activity Reports that are overdue. The designee has **7 (seven) days** to complete the report after completion of the test or check."

### 10.3 Test/Check Tab — Authorization Choice
Two mutually exclusive paths:
- **Select Authorization** — displays all authorizations currently on the designee's CLOA.
- **Temporary Authorization** — displays all authorizations *not* on the CLOA.

**Key rule:**
- Only **one authorization** per pre-approval.
- Temporary Authorizations **always** go through the manual MS approval process (not auto-approved) because they aren't on the CLOA.

### 10.4 Date Rule
> "Pre-approvals dates cannot be set in the past. The user must select a current or future date."

### 10.5 Location Tab — Options
- `Facility on Record` — dropdown of locations on record (if > 1).
- Or manual text entry of facility.

### 10.6 Applicant/Application Tab — Conditional Fields

| Basis Selected | Required Conditional Field | Behavior |
|----------------|----------------------------|----------|
| Graduate of an Approved Course | "Name and designation number of FAA-approved school in which the applicant enrolled" | Type-ahead filter of schools |
| Holder of Foreign License | "Country that issued the foreign pilot license" | Dropdown |
| Air Carrier Training Program | "Name of Air Carrier" | Type-ahead filter |

### 10.7 Documents/Comments Tab
- Optional free-text comments.
- Optional file upload (Choose → Open); uploaded documents can be removed via the Delete column.

### 10.8 Summary Tab — Action Buttons
- `Back` — return to Pre-Approval list.
- `Print` — renders printable PDF.
- `Submit` — finalize.
- `Cancel` — abandon.
- `Copy` — clone entries into a new Pre-Approval Request.

### 10.9 Submit Messaging
On successful submit: "Pre-Approval has been successfully submitted."

---

## 11. Edit / Cancel Pre-Approval (§4 — Edit, Cancel)

### 11.1 Edit
- Allowed **only while status = `Pending`** AND not yet approved by the Managing Specialist.
- Editing a submitted pre-approval causes a submit message stating "any changes will require FAA authorization."

### 11.2 Cancel
- Allowed **regardless of status** (including already-approved pre-approvals).
- Workflow: `Cancel This Request` link → reason dropdown → `Submit`.
- Confirmation toast + activity status updates to `Canceled`.
- After cancellation, designee may submit a **new** pre-approval request.

### 11.3 Default Report View
- Defaults to **past one year** of Pre-Approval/Post Activity data; "All data" option expands view.

### 11.4 Copy
- Designee can copy an existing pre-approval from the Summary tab `Copy` button to seed a new request.

---

## 12. Administrative Pre-Approval (§4.3)

Same tab skeleton as Practical Test Pre-Approval (Pre-Approval → Test/Check → Location → Applicant/Application → Documents/Comments → Summary), with differences:
- **Only one authorization can be selected** (explicit constraint).
- Location tab offers `Facility on Record` vs. `Other Facility` options (manual entry).
- Applicant/Application tab — same conditional fields as §10.6 for Approved Course / Foreign License / Air Carrier Training Program.

---

## 13. Post Activity Report (§4.3–4.4, Figures 86–93)

### 13.1 Entry Points
- Tracked per pre-approval via DMS tracking number link.
- Actionable while status is `Initiated` or `Saved`.

### 13.2 IACRA Integration
- Designee can enter **applicant FTN + Application ID** from IACRA and click `Populate IACRA Data` to auto-populate the Post Activity Report.
- **Fields remain editable** after IACRA population.

### 13.3 Pre-Population from Pre-Approval
- All data pre-populates from the Pre-Approval Request if originally entered.
- All fields editable — designee must change any fields necessary to document what actually happened on the test or check.

### 13.4 Completeness
- Required: activity data, applicant information.
- Optional: comments and attachments.

### 13.5 Overdue Rule
- Report must be completed within **7 days** after test/check completion (see §10.2); overdue status blocks new pre-approval creation.

---

## 14. Training Record (§4.4)

- Read-only view of training information entered by MS.
- MS updates training dates and future training schedule.

---

## 15. Request Additional Authorizations (§4.5)

Tab flow: Expand Request → Submit (Release + Signature).

**Expand Request Tab:**
- Shows existing Function Codes (from CLOA).
- Designee checks additional function codes to request.
- Comments required (max **4000 characters**) explaining need.
- Supplemental Information Sheet (DPE.doc) must be downloaded, filled, saved, chosen via `+Choose`, and uploaded.

**Submit Tab:**
- All "I agree" checkboxes in Release of Information and Certification Statement.
- Electronic signature box.
- `Submit` → Submission Acknowledgement modal → returns to Activity Links.

**Concurrency Constraint (§4.5 note):**
> "The designee is not able to initiate another additional authorization request until the first one is completed. The system displays a pop-up window to notify the designee about the limitation."

---

## 16. Request Voluntary Surrender (§1.6)

Triggered from Activity Links → Voluntary Surrender Request.

Flow:
1. Fill in relevant required fields.
2. Yes/No questions — selecting Yes reveals additional questions; answer and `Submit`.
3. Optional feedback survey modal — `No` ends the flow.
4. On submission, designation status changes `Active → Terminated` after MS approval.

**Reinstatement window (§1.6 note, §5.4):**
- Within **1 year** after termination-not-for-cause, designee can request reinstatement.
- After 1 year, designee must reapply from scratch.

---

## 17. View Authorizations and Limitations (§Authorizations and Limitations)

- Read-only panel listing all current DPE authorizations and limitations.
- Shows **auto-approval status** for each authorization's pre-approvals.

---

## 18. Corrective Action Response (§5.1)

Assigned by MS → appears in Action Required Items.

- Designee Information + Corrective Activity Information are **read-only**.
- Designee enters `Corrective Action Taken` + optional attachments.
- Submit routes back to assigned MS for one of three outcomes:
  1. MS accepts the response.
  2. MS returns for more information.
  3. MS declines — response posted in Message Center.

---

## 19. Annual Request to Extend Expiration Date (§5.2)

### 19.1 Trigger
- Task auto-generated **60 days before designee's expiration date**.
- Applies to both **Active** and **Suspended** designees.

### 19.2 Tab Flow
Questions → User Profile → Background Questions → Attachments → Summary → Sign.

### 19.3 Questions Tab
- Yes/No on Designee Action Questions.

### 19.4 User Profile Tab
- Enter/verify contact and address info.

### 19.5 Background Questions Tab
- Yes/No on each background question.

### 19.6 Attachments Tab
- Upload updated supporting documents (`Choose` → pick files → `Open`).
- Delete via blue X button.

### 19.7 Sign Tab
- Read Release of Information and Certification Statement → check all `I Agree` boxes.
- Read Privacy Act Statement.
- Check signature box.
- `Submit` → success modal.

### 19.8 Effect on CLOA
- On successful completion: **expiration date extends by 12 calendar months**; CLOA updated with new expiration.
- Message Center notification: `Designee Annual Request to Extend Expiration Date Successful`.

### 19.9 Failure Mode
- If updated info "no longer meets basic eligibility or qualification requirements for FAA designation," designee receives `Designee Profile Update Unsuccessful` notification. (Implicit: expiration not extended.)

---

## 20. Suspension Release Request (§5.3)

- Fires automatically when MS suspends a designation.
- Task available to designee for **180 days**.
- Notification subject: `Designee Authorization Suspended`.
- Designee enters **justification** + attaches **supporting documentation**, then Submit.

---

## 21. Request Reinstatement (§5.4)

- Available only within **1 year after termination not-for-cause**.

Tab flow: Questions → Background Questions → Summary → Signature.

- Questions Tab — answer all designee-action questions.
- Background Questions Tab — answer all background questions.
- Summary Tab — review.
- Signature Tab — Release of Information checkboxes + Certification Statement checkboxes + electronic signature box + `Submit`.
- Status transitions in Activity History from `Pending` → `Completed` once submitted.

---

## 22. Respond to Termination For Cause (§5.5)

### 22.1 Trigger
MS initiates Termination for Cause → designee gets external landing page option `Respond to Termination for Cause`. Advisory modal requires `Ok` acknowledgement.

### 22.2 Response Fields (Required)
- Response to Termination For Cause (free text).
- Supporting Evidence (free text).
- Supporting attachments (upload).
- `Submit`.

### 22.3 Time Window
> "Designee will have **15 days** to complete the action required item. After 15 days, the 'Respond to Termination For Cause' link will no longer be accessible."

### 22.4 State Semantics During Process
- Designation status remains `Suspended` throughout the termination-for-cause process until the **AO makes a final decision**.
- On AO concurrence → status flips to `Terminated` on both landing page and activity page.
- Message Center notification sent at decision.

---

## 23. Designee Locator — Public Search (§6)

Entry point: `Find Designees` link on the login page (pre-auth, public).

### 23.1 Search Criteria Sequence
1. Select Designee Type from dropdown (e.g., DPE).
2. Two search modes:
   - **Location Search** — enter any/all address fields, select Designation Type from list, `Search`. Results: designee name, address, class type, managing office.
   - **Designee Search** — enter first name, last name, or both, `Search`. Results: designee name, address, class type, managing office.

### 23.2 Data Published
- Only designees whose Designation Location is flagged published (per §3.5 the "same as personal profile" choice publishes their personal address to the locator).

---

## 24. Cross-Cutting Constraints

| Constraint | Source | Value |
|------------|--------|-------|
| Type ratings per authorization | §2.6 | Max 75 |
| Comment length (Additional Authorizations) | §4.5 | 4000 chars |
| Post-Activity Report deadline after test | §4.1 note | 7 days |
| Suspension Release window | §5.3 | 180 days |
| Reinstatement window (not-for-cause) | §1.6, §5.4 | 1 year |
| Respond to Termination-For-Cause window | §5.5 | 15 days |
| Annual Extension task lead time | §5.2 | 60 days before expiration |
| Annual Extension effect | §5.2 | +12 calendar months |
| Pre-approval date | §4.1 | Must be current or future |
| One authorization per pre-approval | §4.1, §4.3 | Enforced |
| Concurrent Additional Authorizations | §4.5 | Only one open at a time |
| Edit window on pre-approval | §4 | While status = Pending, pre-MS-approval |
| Default report view window | §4 | 1 year (All data expands) |
| Cancellation of pre-approval | §4 | Allowed at any status |

---

## 25. Integration Touch Points

- **IACRA** — FTN authoritative source; Post Activity Reports auto-populate from IACRA via FTN + Application ID lookup.
- **MyAccess / ManageMyAccessAccount** — identity plane (email, name, password are changed there, not in DMS).
- **FAA Designee Program** — acceptance of FAA Designee Program agreement is the second agreement gate.
- **Message Center** — in-app notification hub for all status-changing events (appointment, surrender, termination, extension, suspension, corrective actions, MS decisions).
- **CLOA document generator** — triggered by appointment, additional authorizations, annual extension, location change approvals.
- **MS and AO approvals** — location changes and terminations-for-cause both require dual MS+AO concurrence.

---

## 26. Role Map (DMS External Roles Referenced)

| Role | Context |
|------|---------|
| Applicant | Pre-appointment user; creates application. |
| Designee (DPE / SAE / Admin PE) | Appointed user with an active designation. |
| Managing Specialist (MS) | FAA-side oversight; approves/declines requests, assigns corrective actions, suspends, initiates terminations. |
| Appointing Official (AO) | Approves location changes (with MS), concurs with terminations. |

---

## 27. UI/UX Patterns Worth Implementation Notes

- **Linear wizards with mandatory tab order** — every major workflow (application, pre-approval, annual extension, reinstatement) is gated by "Continue" chaining across tabs.
- **Save-resume at any tab** via bottom-of-tab `Save` button — applies to application creation.
- **Required fields marked with red asterisk** (convention used across all forms).
- **Confirmation modals on destructive actions** — Decline agreement, Cancel pre-approval, Voluntary Surrender submission, Corrective Action response.
- **Success toasts (top-right green box)** on persistent saves ("Save Information").
- **Read-only panels for FAA-managed data** — Training Record, Designation Information, Authorizations/Limitations.
- **Dual-approval patterns** — Location changes (MS + AO), Termination for Cause (MS + AO).
