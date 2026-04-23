# DMS — Current-State Analysis

**System:** Designee Management System
**URL:** https://designee.faa.gov
**Analysis Date:** 2026-04-23

---

## 1. System Identity

| Attribute | Value |
|---|---|
| Public URL | https://designee.faa.gov |
| System Owner | Aviation Data Systems Branch |
| Point of Contact | Linda Navarro |
| Hosting Facility | Mike Monroney Aeronautical Center (MMAC), controlled server center |
| Security Framework | NIST SP 800-53 Rev 5 |
| Regulatory Authority | 14 CFR Part 183 |
| Mission | Lifecycle management of FAA-designated representatives (appointment, renewal, activity reporting, termination) under FAA Order 8000.95D |

DMS consolidates ~9 predecessor systems identified in GAO-05-40 into a single authoritative registry of FAA designees. It is the system of record for designee identity, authorization scope, and activity history across AIR, AAM, and FS lines of business.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Delivery | Web application (browser-accessed) |
| Auth — FAA internal | Integrated Windows Authentication (IWA) against Active Directory + PIV card |
| Auth — external/public | Username + password with security question (legacy); Login.gov migration underway for non-FAA users (2025) |
| Hosting | MMAC secure facility, controlled server center |
| Contractor | CAN Softtech (per external-user manual branding) |
| Compliance Baseline | NIST 800-53 Rev 5 |
| Records Retention | 25 years after inactive status (NARA DAA-0237-2020-0013) |

Auth posture is split: FAA employees authenticate through IWA/AD+PIV tied to the on-prem domain, while public designees and applicants use locally-managed credentials that are in the process of migrating to Login.gov.

---

## 3. Designee Architecture — 13 Categories

ODA (Organization Designation Authorization) is explicitly **excluded** from DMS and managed separately.

| Code | Designee Type | Responsible Office |
|---|---|---|
| DMIR | Designated Manufacturing Inspection Representative | AIR |
| DAR-F | Designated Airworthiness Representative — Manufacturing | AIR |
| AME | Aviation Medical Examiner | AAM |
| DAR-T | Designated Airworthiness Representative — Maintenance | FS |
| DPE | Designated Pilot Examiner | FS |
| DPRE | Designated Parachute Rigger Examiner | FS |
| DME | Designated Mechanic Examiner | FS |
| SAE | Specialty Aircraft Examiner | FS |
| Admin PE | Administrative Pilot Examiner | FS |
| APD | Aircrew Program Designee | FS |
| TCE | Training Center Evaluator | FS |
| DADE | Designated Aircraft Dispatch Examiner | FS |
| DER | Designated Engineering Representative | AIR |

Distribution: **AIR** owns 3 types (manufacturing/engineering airworthiness), **AAM** owns 1 (medical), **FS** owns 9 (the full examiner spectrum for pilots, mechanics, riggers, dispatchers, and aircrew programs).

---

## 4. Data Architecture

**Registration fields (initial account creation):**
- Name, email, chosen username, password, one security question/answer

**Profile / application fields (post-registration):**
- Legal name, suffix, date of birth
- Airman certificate number
- Gender, citizenship
- Contact — phone(s), mailing/physical addresses
- Optional photograph
- FAA Tracking Number (FTN)
- References, employer point-of-contact
- Medical license number / NPI (AME applicants only)
- Background/suitability questions
- Uploaded supporting documents (application packet, transcripts, cert copies)

**System-generated outputs:**
- **Designee Number** — 9-digit unique identifier issued on appointment
- **Certificate of Letter of Authorization (CLOA)** — authoritative statement of functions, limitations, and expiration
- **Designation Certificate** — display credential

Uploaded documents are retained with the designee record for the full 25-year retention period.

---

## 5. User Roles & Workflows

### Appointment lifecycle (applicant → designee)
1. **Applicant pool** — interested candidates self-register and submit profile + supporting docs
2. **Evaluation** — responsible office screens qualifications, interviews, and selects
3. **Appointment** — Designee Number is issued, CLOA generated, Designation Certificate produced
4. **Issuance** — applicant becomes an active designee

### Operational workflows (active designee)
| Workflow | Description | Timing |
|---|---|---|
| Pre-approval requests | Designee seeks authorization for a specific activity prior to performance | Before activity |
| Post-activity reports | Report of activity performed (tests, inspections, medical exams) | **Due within 7 days** of activity |
| Activity history | Running log of all completed authorized actions | Continuous |
| Training records | Tracks required/completed training (initial, recurrent) | Per training requirement |
| Additional-authorization request | Designee requests expansion of authorized functions | On demand |
| Annual extension | Yearly renewal of designee authority | Annual |
| Corrective action | Office-initiated remediation for performance/compliance issues | Event-driven |
| Voluntary surrender | Designee voluntarily relinquishes designation; **1-year window** for reinstatement | On surrender |
| Suspension & release | Temporary suspension; release must occur within **180 days** | Time-bound |
| Termination for cause | Involuntary termination; **15-day** due-process timeline | Event-driven |

These workflows are the operational heart of DMS — the system is as much a case-management platform for designee oversight as it is a registry.

---

## 6. Integration Architecture

| Direction | Partner System | Data Exchanged |
|---|---|---|
| Outbound | NACIP | Designee name, ID, phone, type |
| Bidirectional | MSS | AME activity metrics, designee profile sync |
| Bidirectional | IACRA | Test/checkride activity ↔ airman identification |
| Outbound | SAS | Designee name, ID, type, certificate expiration (workload data) |
| Outbound | eFSAS | Designee name, ID, type, status (pay-grade calculation) |
| Outbound | ATLAS Aviation | Designee identity for testing/assessment platform |

DMS is the authoritative source for designee identity; downstream systems (NACIP, SAS, eFSAS) consume it. Bidirectional links with MSS and IACRA reflect the tight coupling between medical-examiner workflows (MSS) and check-airman/examiner activity (IACRA).

---

## 7. Public-Facing Surfaces

**Designee Locator (public search):** open query over the active designee population, searchable by:
- Name
- Address
- City, State, ZIP
- Phone
- Country
- Designee Type
- Responsible Office

**Public documentation:**
- DPE External User Manual
- TCE External User Manual
- General DMS External User Manual
- Public FAQ

The locator is the primary public-facing surface that exposes designee contact information to applicants and the general public seeking an examiner.

---

## 8. Compliance & Governance

| Instrument | Role |
|---|---|
| 14 CFR Part 183 | Statutory authority for FAA designees |
| FAA Order 8000.95D | Operational policy; **Change 1 is in draft** under docket **FAA-2025-1218** |
| SORN DOT/FAA 830 | Privacy Act System of Records Notice covering designee PII |
| OMB Control 2120-0033 | Paperwork Reduction Act clearance for DMS collections |
| NARA DAA-0237-2020-0013 | Records schedule — **25-year retention** after inactive status |
| PIA (2022) | Current Privacy Impact Assessment on file |

Compliance posture is mature: active SORN, current PIA, approved NARA schedule, and an open policy-update docket reflect ongoing governance attention.

---

## 9. DRS Absorption

The **Designee Registration System (DRS)** is being folded into DMS. DRS historically owned training-enrollment and registration flows for designees; DMS Releases **8.0** and **8.1** are documented deviation/absorption releases that migrate DRS functions under the DMS umbrella.

| DRS Function | Disposition in DMS |
|---|---|
| Course registration | Absorbed — tracked inside DMS training records |
| Payment processing | Delegated to **Pay.gov** |
| Course delivery (LMS) | Delegated to **Blackboard** |
| Enrollment records | Absorbed into DMS designee profile |

Net effect: DMS becomes the single designee-facing registry; payment and course delivery are pushed to purpose-built external services (Pay.gov, Blackboard).

---

## 10. Modernization Status

DMS is under **active modernization** — **not** a candidate for wholesale replacement.

| Modernization Thread | Status |
|---|---|
| Login.gov migration for non-FAA users | In progress (2025) |
| DRS absorption (Releases 8.0 / 8.1) | In progress |
| IWA → zero-trust identity upgrade | Needed; not yet scoped |
| FAA Order 8000.95D Change 1 | In draft (docket FAA-2025-1218) |
| PIA refresh | Last completed 2022 |

Strategy is **interface retirement + shared master-data cleanup**, not a ground-up rebuild. The system's core domain model (designees, authorizations, activity) is sound; modernization focuses on identity, integrations, and obsolete dual-entry elimination.

---

## 11. Technical Debt & Risk Assessment

| Risk | Description | Impact |
|---|---|---|
| On-prem AD dependency | IWA auth ties DMS to Active Directory inside the MMAC perimeter, blocking cloud-native and zero-trust postures | Medium-High — limits hosting flexibility |
| Public designee directory PII exposure | Locator publishes name, address, city, state, ZIP, phone, and type for every active designee | Medium — SORN-authorized but large public surface |
| eFSAS decommission in progress | Outbound pay-grade feed depends on a system being retired; replacement path must be established | Medium — integration churn during transition |
| Identity sprawl | FAA users via IWA+PIV, public users via local passwords transitioning to Login.gov, plus integration-account credentials across NACIP/MSS/IACRA/SAS/eFSAS/ATLAS | High — multiple IdPs, inconsistent posture |
| Dual-entry with MSS | AME profile data flows both ways with MSS; divergence risk unless master-data ownership is clarified | Medium — data-quality risk |
| Legacy security-question auth | Single security question on public accounts is below current NIST 800-63 guidance | Mitigated by Login.gov migration |

---

## 12. Rationalization Recommendations

1. **Normalize the designee profile across DMS / MSS / SAS.** Establish DMS as the single authoritative source for designee identity and push — don't sync — downstream. Eliminate bidirectional profile syncing with MSS by designating DMS as the master and MSS as a read consumer.

2. **Eliminate obsolete dual-entry.** Audit the outbound feeds (NACIP, SAS, eFSAS, ATLAS) for fields that designees currently re-enter in downstream systems and collapse them into DMS-sourced attributes.

3. **Expose an authoritative CLOA / authorization model as an API.** The CLOA is the canonical statement of what a designee may do; downstream systems (IACRA check activity, SAS workload, eFSAS pay) should consume a versioned authorization API rather than deriving scope from designee type + local rules.

4. **Complete the Login.gov migration and retire local password store.** Use the migration as the forcing function to deprecate the security-question credential model entirely.

5. **Plan the IWA → zero-trust cutover** in lockstep with broader FAA identity modernization, so DMS is not left tethered to on-prem AD after other FAA systems move off it.

6. **Formalize the eFSAS successor integration** before eFSAS decommission completes; pay-grade calculation is a live downstream dependency.
