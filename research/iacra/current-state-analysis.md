# IACRA — Integrated Airman Certification and Rating Application: Current-State Analysis

This analysis captures IACRA as it stands in 2026: what it does, what it explicitly is *not*, how it hands data off to the authoritative registry, and where its architectural seams create modernization pressure. IACRA is an unusual system in the AVS portfolio — by design it is a **temporary repository, not a system of record**. Every architectural decision below has to be read through that lens: IACRA's job is to marshal an application, route it to reviewers, and then surrender the final artifact to CAIS. Understanding the handoff surface is understanding IACRA.

---

## 1. System Identity

| Attribute | Value |
|---|---|
| Full name | Integrated Airman Certification and Rating Application |
| Acronym | IACRA |
| Role in portfolio | **Temporary repository** for airman certification intake — explicitly *not* a system of record |
| System of record | CAIS (Comprehensive Airmen Information System), part of RMS / AVS Registry |
| Public URL | `https://iacra.faa.gov/iacra/default.aspx` |
| Owning organization | FAA Office of Aviation Safety (AVS), Flight Standards Service |
| Operational branch | Airmen Certification Branch (AFB-720), Civil Aviation Registry Division |
| Location | Mike Monroney Aeronautical Center (MMAC), Oklahoma City, OK |
| ATO | March 2, 2022 |
| Security baseline | NIST SP 800-53 Rev 5 |
| Replacement target | CARES Phase 2 (FOC Fall 2027) |

**Why the temp-repo distinction matters.** IACRA's data has no independent legal authority — the authoritative record lives in CAIS once the TIFF package is ingested. Records in IACRA are deleted when superseded. This drives everything: there is no long-term retention strategy inside IACRA, there is no internal analytics platform, and the outbound TIFF-over-FTP pipe is the contract that matters. Modernization conversations that treat IACRA as a standalone application miss the point; it is half of a two-system workflow and the other half (CAIS) is the constraint.

---

## 2. Technology Stack Analysis

| Layer | Technology | Notes |
|---|---|---|
| Platform | **ASP.NET Web Forms** | `.aspx` URLs visible across every public entry point |
| Server | Microsoft IIS | Consistent with ASP.NET Web Forms pattern |
| Database | SQL Server | Implicit from the Atlas Aviation SQL Server linked-server integration |
| Public auth | Username + password + **30-day email MFA** (6-digit code) | Email-based MFA is the critical compliance gap |
| FAA auth | **PIV card via MyAccess** | Federated SSO for all FAA internal users |
| Outbound to CAIS | **TIFF images over secure FTP** | The single most important legacy integration |
| Inbound from Atlas Aviation | **SQL Server linked-server link** | Knowledge test results pulled by FTN |
| Payment | No payment layer (IACRA does not take fees) | |
| Release cadence | Active — release notes are publicly posted | Not a frozen legacy system |

**Stack signals worth calling out:**

- **ASP.NET Web Forms.** The `.aspx` extension confirms classic Web Forms, not MVC or Core. This aligns IACRA with MedXPress/AMCS (also .aspx) and contrasts with CARES (modern stack). Any modernization has to assume a Web Forms postback UI pattern, server-rendered state, and ViewState-dependent page flows.
- **Email MFA is a compliance gap.** A 30-day email code is not phishing-resistant and does not meet NIST SP 800-63B AAL2. The public-applicant auth stack is the weakest security surface in the system.
- **SQL Server linked server to Atlas Aviation.** A vendor-hosted database joined directly to an FAA SQL instance is a strong coupling — credential rotation, schema drift, and availability are all bilateral concerns.
- **TIFF-over-FTP to CAIS.** This is not a modern integration pattern. There is no API, no streaming, no schema validation beyond whatever CAIS applies on ingest. It works because it has worked for decades, but it is incompatible with API-driven replacements by design.

---

## 3. Application Architecture

IACRA is architected around **role-based page flows**. Rather than a single unified application model, the system presents different sets of `.aspx` pages to each role, with the shared data model stitched underneath. Role binding happens at account registration (the user picks a role) and is validated against credential evidence where applicable (certificate number for RIs/DEs, PIV for FAA staff, school ID for school admins).

**Primary roles served:**

| Role | Who | Primary actions |
|---|---|---|
| **Applicant** | Airman seeking cert or rating | Register account, start/submit application, provide biographic + experience data |
| **Recommending Instructor (RI)** | CFI endorsing the applicant | Run the RI checklist, attach endorsement, forward to DE/ASI |
| **Designated Examiner (DE)** | DPE conducting the practical | Retrieve application, record practical test outcome |
| **Aviation Safety Inspector / Technician (ASI/AST)** | FAA internal | Review, countersign, route for decision |
| **School Examiner / Training Center Evaluator** | Part 141/142 school admin | Manage student applications, endorse on behalf of school |
| **Certifying Official (CO)** | FAA signatory | Apply final decision: approve, disapprove, discontinue, delete |

**Architectural consequences of the role model:**

- The same underlying application record is **progressively enriched** by each role — applicant biographic → RI endorsement → DE test outcome → CO decision. This sequencing is the workflow, and it is implemented in page flow rather than in an orchestration engine.
- There is **no single "application service"** exposed as an API; each role's interactions are embedded in their role-specific pages. This makes the system hard to extend, hard to test in isolation, and hard to plug into CARES without rewriting workflow logic.
- Authorization is enforced by role-to-page binding, not by a domain permission model. A user sees a given page or they don't.

---

## 4. Data Architecture

IACRA holds **two logical record types**: a lightweight *account/registration* record, and a heavyweight *application* record that grows as each role touches it.

**Account / registration fields** (from the PIA):
- Name, date of birth, sex, email address, certificate number, two security questions.

**Application fields** (from the PIA, progressively captured):
- Full biographic (name, DOB, sex, birthplace, citizenship)
- Optional SSN
- Multiple ID types: driver's license, passport, military ID, student ID
- Mailing/physical address
- Hair, eye, height, weight
- Drug convictions disclosure
- Prior FAA certificates and ratings
- Aviation experience (hours, aircraft types, conditions)
- Foreign license information (if applicable)
- Medical certificate reference (class, date)
- English language proficiency attestation
- Certificate or rating sought
- Test outcome: approved / disapproved / discontinued

**FTN — the key identifier.** The FAA Tracking Number (FTN) is the stable key that threads the application through every system: IACRA, Atlas Aviation (knowledge test results), CAIS (final record), DMS, TSA/NTSDB. FTN is what makes the hand-off to CAIS possible, and what makes the knowledge-test pull from Atlas Aviation deterministic. Any replacement system must preserve FTN as a first-class identifier or provide a crosswalk.

**Retention.** Per the system's "temp repo" nature, application records are deleted once superseded by the authoritative CAIS record (NARA schedule N1-237-09-14). IACRA is not the place to ask historical questions.

---

## 5. Forms Handled

IACRA replaces and routes the paper-form equivalents of the airman certification process. Each form has an OMB control number and a matching IACRA page flow.

| Form | Title | OMB number (per PIA) |
|---|---|---|
| **8400-3** | Application for Aircraft Dispatcher Certification | OMB 2120-0022 |
| **8610-1** | Application for Inspection Authorization (IA) | OMB 2120-0022 |
| **8610-2** | Mechanic / Parachute Rigger Application | OMB 2120-0022 |
| **8710-1** | Airman Certificate and/or Rating Application | OMB 2120-0021 |
| **8710-11** | Sport Pilot Application | OMB 2120-0021 |
| **8710-13** | Remote Pilot Certificate and/or Rating Application | OMB 2120-0021 |
| **8060-71** | Verification of Authenticity of Foreign License, Rating, and Medical Certification | OMB 2120-0022 |

Each form translates into a distinct IACRA application path, but they share the same underlying data model and role workflow — another reason the right modernization unit is "the application service," not "each form."

---

## 6. User Roles and Workflows

IACRA's end-to-end flow is a **five-stage progressive workflow**:

**Stage 1 — Account creation (applicant self-service).**
User registers with name, DOB, email, optional certificate number, and security questions. Email MFA is activated. A system-generated FTN is assigned.

**Stage 2 — Application entry (applicant).**
Applicant selects the certificate/rating sought, picks the appropriate form, and completes biographic, identity, medical, and experience sections. Knowledge test results may auto-populate from the Atlas Aviation linked server.

**Stage 3 — Recommending Instructor review (RI).**
RI runs the **RI checklist** (endorsement prerequisites — flight hours, required maneuvers, cross-country, etc.) and signs the recommendation. The application moves to the DE or ASI queue.

**Stage 4 — Practical test / decision (DE, ASI, AST, School Examiner).**
The Certifying Official records the practical test outcome. The PIA explicitly enumerates four possible outcomes:
- **Approve** — certificate/rating issued, package advances to CAIS
- **Disapprove** — applicant failed the test
- **Discontinue** — test interrupted (weather, equipment, etc.)
- **Delete** — application withdrawn or erroneously created

**Stage 5 — Subsequent activity.**
Approved applications are rendered to TIFF and pushed to CAIS over secure FTP. The IACRA record is then subject to deletion once superseded. The CO's final certificate stands as the legal artifact in CAIS.

This five-stage pattern is implemented entirely in page flow. There is no externally callable workflow engine; the state machine lives in the page-to-page navigation and stored procedures.

---

## 7. Integration Architecture

IACRA sits at the center of a web of internal and external integrations. Unlike MedXPress/AMCS (which holds state internally for years) or RMS (which *is* the authoritative store), IACRA's value is almost entirely in how it marshals data across these integration boundaries.

| Direction | Counterpart | Protocol | Payload / purpose |
|---|---|---|---|
| Inbound | **MyAccess** | Federated SSO | PIV-card authentication for all FAA internal users |
| Inbound | **Atlas Aviation** | SQL Server linked server | Knowledge test results pulled by FTN |
| Outbound | **CAIS (AVS Registry)** | **TIFF images over secure FTP** | Full approved application package — the official handoff |
| Outbound | **TSA NTSDB** | Secure portal (per MOA) | Vetting payload for pilot applicants |
| Outbound | **SAS** (Safety Assurance System) | Direct | Inspector + applicant data for oversight |
| Outbound | **USAS Portal** | One-time extract | Name, email, FTN, DOB |
| Bidirectional | **DMS** (Designee Management System) | Direct | Test activity + airman ID for designee oversight |
| Bidirectional | **FSTW** (Flight Standards Training Website) | Direct | Training and currency records for FAA staff |
| Outbound | **PTRS** (Program Tracking and Reporting Subsystem) | Direct | Inspector activity reporting |

**Critical integration — TIFF-over-FTP to CAIS.** This is the single most important pipe in the system. When a CO approves an application, IACRA generates TIFF images of the completed forms and pushes them to CAIS via secure FTP. There is no API contract; the ingest is file-based. CAIS is the one doing edit-checks and cross-validation against its ADABAS master record (see RMS analysis). Any IACRA replacement must either continue producing the same TIFF/FTP artifact or require a coordinated change to CAIS — which is why CARES was designed to absorb both sides.

**Critical integration — SQL Server linked server to Atlas Aviation.** Knowledge test scores are pulled from Atlas Aviation (the vendor operating FAA knowledge testing) via a SQL Server linked-server join. This is a strong coupling: schema changes on either side break the pull, credentials are bilateral, and outages cascade. FTN is the join key.

---

## 8. Public-Facing Surfaces

IACRA is unusually public for an FAA system — it has to be, because applicants and instructors outside the FAA are its primary users. The surfaces that modernization has to preserve or replace:

- **`/iacra/default.aspx`** — main landing and login.
- **Help pages** — context-specific help for each role and form (pilot cert, mechanic, remote pilot, etc.).
- **User guides** — consolidated PDF user guide, IA renewal guide, registration info guide (all shipped with the system and publicly downloadable).
- **Training site** — walk-through environment for new users (schools often use it to onboard students).
- **Release notes** — publicly posted, confirming IACRA is on an active release stream, not a frozen legacy system.
- **FAQ** — covering registration, login recovery, MFA, role selection.

The breadth of public documentation is itself a modernization constraint: any replacement has to re-produce equivalent external documentation or carry a large user-education burden at cutover.

---

## 9. Compliance and Governance

| Framework | Application |
|---|---|
| **SORN** | DOT/FAA 847, "General Air Transportation Records on Individuals" |
| **NARA records schedule** | **N1-237-09-14** — temporary records, deleted when superseded by CAIS |
| **Security baseline** | NIST SP 800-53 Rev 5 |
| **ATO** | March 2, 2022 |
| **Privacy** | Governed by two PIAs: `iacra-airmen-certification-pia.pdf` and `iacra-airman-certification-pia-2023.pdf` |
| **Form OMB control** | 2120-0021 (8710-series), 2120-0022 (8610/8400/8060 series) |

**Key governance point.** The NARA N1-237-09-14 temporary designation is what allows IACRA to delete records when they are superseded by CAIS. Without this, IACRA would be subject to long-term retention obligations and the "temp repo" architecture would not be legally viable. Any replacement must preserve this records-management split or re-negotiate the schedule.

---

## 10. Modernization Status

**Replacement path.** IACRA is targeted for absorption into **CARES Phase 2**, with **Full Operational Capability in Fall 2027**. CARES is the modernization program for both IACRA (intake) and CAIS/RMS (system of record), and its design goal is to close the TIFF-over-FTP seam by placing intake and system-of-record on a unified platform.

**Why CARES replaces IACRA and RMS/CAIS together.** The TIFF-over-FTP handoff only makes sense as a compromise between two legacy systems. Replacing IACRA alone would leave the new system still rendering TIFFs to feed the mainframe; replacing CAIS alone would leave modern intake generating a mainframe-shaped artifact. CARES is scoped to absorb both ends of the pipe.

**Active release stream.** Despite being slated for replacement, IACRA is still receiving functional updates, security patches, and release notes in 2025–2026. This is appropriate — retiring a system that serves tens of thousands of applicants a year requires the system to stay healthy until cutover — but it creates a dual-run cost (see §11).

**Known modernization gaps:**
- **Email MFA violates NIST SP 800-63B AAL2.** Email-delivered codes are neither phishing-resistant nor recommended for federal authenticators. This is the clearest single compliance risk in the system.
- **No public API.** Schools, AMEs, CFIs, and third-party training platforms have no way to integrate programmatically. All entry is manual through the web UI.
- **TIFF-over-FTP** is the defining legacy integration and cannot be incrementally modernized without a coordinated CAIS change.

---

## 11. Technical Debt and Risk Assessment

| Risk | Severity | Why it matters |
|---|---|---|
| **Email MFA (30-day code)** | High | Violates NIST 800-63B AAL2; email is not phishing-resistant; applicant account is the primary attack surface for identity fraud |
| **TIFF-over-FTP to CAIS** | High | Non-API, non-schema-validated file transfer; incompatible with modern integration; single most important pipe in the system |
| **SQL Server linked server to Atlas Aviation** | High | Direct vendor-to-FAA database coupling; credential rotation, schema drift, and availability are bilateral concerns |
| **ASP.NET Web Forms** | Medium | Dwindling labor pool; ViewState-dependent UI is hard to modernize incrementally |
| **Role-to-page authorization model** | Medium | No coherent permission model; hard to audit and hard to extend |
| **No public API** | Medium | Blocks ecosystem modernization; every integration is manual through the UI |
| **Dual-run with CARES through 2027** | Medium | Two systems serving the same workflow during cutover; data reconciliation risk and doubled operational cost |
| **Active release stream on a replacement-bound system** | Low–Medium | Necessary, but investment should be carefully scoped to avoid sunk-cost pull on IACRA beyond CARES FOC |

---

## 12. Rationalization Recommendations

IACRA's replacement is already decided — the question is not *whether* to replace it but *how to extract the most reusable architecture for CARES during the replacement window*. Recommendations:

1. **Separate reusable services from page flows.** The five-stage workflow (account → application → review → decision → subsequent activity) is an orchestration pattern that transcends .aspx. Extract it into a standalone application service that CARES can adopt or adapt, rather than carrying the Web Forms page flow into the new system.

2. **Converge the identity model with CARES.** Retire email-MFA-as-primary-authenticator for public applicants in favor of a modern identity provider (Login.gov is the obvious candidate — already adopted by MedXPress/MSS in August 2025). This closes the NIST 800-63B gap and unifies applicant identity across the AVS public surface.

3. **Converge the document model with CARES and CAIS.** TIFF-over-FTP is the artifact of a two-system design. A unified document model — where applications are structured records, not rendered images — removes the need for the handoff entirely. This is the core CARES thesis and should be explicitly preserved.

4. **Converge the case model with CARES.** The progressively-enriched application record (applicant → RI → DE → CO) is a generic case-management pattern. Modeling it as a case with role-based actions (rather than a sequence of .aspx pages) aligns with CARES's modernization approach and provides a path to reuse in future FAA systems.

5. **Lock FTN as the cross-system identifier.** FTN already threads IACRA, Atlas Aviation, CAIS, DMS, and TSA/NTSDB. Any CARES replacement must preserve FTN as a first-class identifier (or a crosswalk) to avoid breaking every downstream integration.

6. **Decommission the Atlas Aviation linked-server coupling.** Replace the SQL Server linked server with an API-based integration (or have Atlas Aviation publish knowledge-test results into a broker). The linked-server pattern is the highest-risk vendor coupling in the system.

7. **Treat the 2025–2027 release stream as bridge maintenance only.** Feature work that does not accelerate CARES cutover adds to the sunk cost of a system slated for retirement. Keep the security-patch cadence; resist scope creep on functional changes.

8. **Preserve the public documentation surface.** IACRA's help pages, training site, FAQ, and user guides are a substantial user-facing asset. Any CARES cutover plan should budget for the external re-documentation effort, or risk a large education gap at go-live.
