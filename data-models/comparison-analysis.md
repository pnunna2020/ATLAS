# Comparison Analysis — Current-State vs. Integrated Unified Model

Side-by-side analysis of the five current-state data models against the consolidated unified model. Captures consolidation gains, duplicate-entity mappings, migration complexity, and key integration trade-offs.

---

## 1. Headline metrics

| Metric | Current-state (5 systems) | Unified (integrated) | Change |
|---|---|---|---|
| **CREATE TABLE count** | **141** (RMS 33 + MSS 33 + IACRA 27 + DMS 29 + CARES 19) | **75** | **−47% (−66 tables)** |
| Distinct "person" tables | 5 (rms.owners, rms.airmen, mss.applicants, iacra.airmen, dms.designees + cares.persons) | 1 (`core.persons`) | **5 → 1** |
| Distinct "address" tables | 5 (inline + 3 separate address tables) | 1 (`core.addresses`) | **5 → 1** |
| Audit log tables | 5 (one per system) | 2 (unified `audit.events` + `audit.disclosure_log`) | **5 → 2** |
| Document stores (physical) | 4 silos (IMS 174M TIFFs, DIWS ~9.5M/yr, IACRA FTP staging, DMS attachments) | 1 (`documents.documents`) | **4 → 1** |
| Workflow/case tables | 4 bespoke | 1 generic (`workflow.cases` + history + participants) | **4 → 1** |
| Payment integrations | 4 separate Pay.gov hooks | 1 (`payments.payments`) | **4 → 1** |
| Notification/correspondence | 4 (RMS notices, IACRA emails, MSS action-required, DMS Message Center) | 1 (`notify.correspondence` + templates) | **4 → 1** |
| Identity keys (primary lookup) | 7 (N-number, FTN, Cert #, Applicant ID, MID, PI #, Designee #) | 2 (`person_id` + aliases via `identifier_mappings`) | N→2 |
| RBAC models | 4+ siloed | 1 (`core.users`/`roles`/`permissions`) | **4+ → 1** |
| FIPS 199 boundary | MODERATE spread + HIGH island | HIGH only on `medical.*`; MODERATE elsewhere | Boundary minimized |

The table-count drop comes mostly from collapsing duplicated reference data, per-subsystem audit tables, and the 4 parallel workflow engines.

---

## 2. Duplicate-entity mapping (many → one)

Where five legacy tables map to one unified entity.

### 2.1 Person / Airman / Applicant / Designee → `core.persons`

| Source table | Source columns preserved | Where mapped in unified |
|---|---|---|
| `rms.owners` (individual type) | name, DOB, SSN, citizenship, physical/mailing address | `core.persons` + `core.addresses` (address_type=MAILING/PHYSICAL) |
| `rms.airmen` | certificate_number, SSN, name, DOB, ratings, height/weight/hair/eye | `core.persons` (certificate_number → `legacy_cert_number` + `identifier_mappings`) |
| `mss.applicants` + `mss.applicant_demographics` | username, email, SSN (enc), demographics | `core.persons` + `core.users` |
| `iacra.airmen` | ftn, ssn, full demographics | `core.persons.ftn` (primary backbone) |
| `dms.designees` | designee_number, full demographics, credentials | `core.persons` + `designee.designees` (1:1) |
| `cares.persons` | person_id, FTN, legacy aliases | `core.persons` (replaces) |

**Net**: five physical person tables + embedded person data in ~10 other tables → **one `core.persons` master + `core.identifier_mappings` alias resolver**.

### 2.2 Address — five variants → `core.addresses`

| Source | Notes |
|---|---|
| `rms.addresses` | Nearly identical to target; direct map. |
| Inline in `mss.applicant_demographics` (mailing_* + residential_* columns) | Split into two `core.addresses` rows per applicant. |
| Inline in `iacra.airmen` (mailing_address_line1/2, mailing_city, etc.) | Split into `core.addresses` row. |
| Inline in `dms.designees` (personal_mailing_address, personal_physical_address, designation_location_address) | Split into three `core.addresses` rows. |
| `cares.addresses` | Direct map. |

### 2.3 Document store — four silos → `documents.documents`

| Source | Volume | Storage | Retention | Unified target |
|---|---|---|---|---|
| RMS IMS (TIFF) | ~174M images, ~25M documents | On-prem NAS | Permanent aircraft / 60yr airmen | `documents.documents` with `retention_schedule = PERMANENT_N1_237_04_03` or `AIRMEN_60Y_N1_237_06_001` |
| MSS DIWS | ~9.5M/yr | Kofax + bespoke store | 50 yr (N1-237-05-005) | `documents.documents` with `retention_schedule = MEDICAL_50Y_N1_237_05_005` |
| IACRA staging | Temp pre-FTP | Local disk | Deleted post-transmission | Eliminated — documents go straight into unified store |
| DMS attachments | Low-volume per designee | Separate disk | 25 yr | `documents.documents` with `retention_schedule = DESIGNEE_25Y_DAA_0237_2020_0013` |

**Consolidation enablers:** SHA-256 file hash for dedup; `document_fingerprint` for perceptual dedup (near-duplicate TIFFs); OCR text and extracted_entities JSONB for searchability across all 174M previously-opaque images.

### 2.4 Workflow / case — four bespoke → `workflow.cases`

| Current bespoke workflow | Forms covered | Unified `case_domain` |
|---|---|---|
| RMS aircraft registration | AC 8050-1/1B/2/3, renewal notices | `AIRCRAFT_REGISTRATION` |
| IACRA airman cert | 8400-3, 8610-1/2, 8710-1/11/13, 8060-71 | `AIRMAN_CERTIFICATION` |
| MSS medical cert | Form 8500-8 → AMCS exam | `MEDICAL_CERTIFICATION` |
| DMS designee cycles | Pre-approval / post-activity / annual extension / corrective-action / termination / reinstatement | `DESIGNEE_MANAGEMENT` |

Unified `workflow.cases.case_type_code` references `workflow.case_types` — **a catalog of ~50+ case types** (one row per legacy form). `case_history` captures every status transition. `case_participants` replaces four domain-specific participant tables.

### 2.5 Payments — four Pay.gov integrations → `payments.payments`

Currently each system owns its own Pay.gov adapter:
- RMS: `rms.payments` (Pay.gov tx ID only)
- IACRA: implicit in `airman_certificates_issued` payment validation
- MSS: out of scope (no applicant fees currently)
- DMS: `training_records.pay_gov_payment_confirmation` (training fees)
- CARES: `cares.payments`

**Unified:** one `payments.payments` table + `payments.fee_schedule` (priced per `case_type_code`). Single Treasury endpoint.

### 2.6 Audit logs — five → `audit.events`

Each current system has its own audit table with its own schema. Unified:
- Single `audit.events` table, partitioned monthly, with `event_domain` discriminator.
- Separate `audit.disclosure_log` for Privacy Act (e) accounting (who received what PII, when, under which SORN).
- Retention per domain enforced at row level (MSS-linked rows retain per HIGH FIPS 199 rules; rest per MODERATE).

---

## 3. Entity-by-entity mapping table

Columns: (Unified target) ← (legacy table → legacy table → ...)

| Unified entity | Legacy counterparts | Notes |
|---|---|---|
| `core.persons` | `rms.owners` (INDIVIDUAL), `rms.airmen`, `mss.applicants`+`mss.applicant_demographics`, `iacra.airmen`, `dms.designees`, `cares.persons` | 5+ legacy tables merged; FTN is primary lookup; SSN preserved (encrypted) but never a key. |
| `core.organizations` | `rms.owners` (non-INDIVIDUAL types — partnership/corp/LLC/trust/non-citizen-corp) | All non-individual entity rows moved here; trust-specific fields preserved (is_trust, trustee_person_id, non_citizen_trustee_declaration). |
| `core.addresses` | `rms.addresses`, inline in `mss.applicant_demographics`, `iacra.airmen`, `dms.designees`, `cares.addresses` | One canonical address record per person/org × address_type. |
| `core.entity_principals` | `rms.entity_principals` | 1:1 mapping. |
| `core.users` / `core.roles` / `core.user_role_assignments` | `iacra.user_accounts` + `iacra.user_roles`, partial in `mss.applicants`, `dms.designees.username`/`password_hash` | Unified RBAC; Login.gov replaces bespoke password columns. |
| `core.offices` | `iacra.fsdo_offices`, `dms.managing_offices` | Single FSDO/IFO/AEG/ACO/CAMI/AAM reference. |
| `core.aircraft_manufacturers`, `.aircraft_models`, `.engine_manufacturers`, `.engine_models` | `rms.*` lookups + `iacra.aircraft_make_models` | Single make/model reference. |
| `workflow.cases` + `.case_history` + `.case_participants` | RMS `work_packets`, IACRA `applications`+`application_state_history`, MSS `medxpress_applications`+`amcs_exams` (as cases), DMS `applications`/`pre_approval_requests`/`annual_extensions`/`corrective_actions` | Single generic case model across 4 domains. |
| `workflow.case_types` | Implicit in each legacy schema (form_type enums, case_type strings) | Explicit catalog replaces enum fragmentation. |
| `documents.documents` | `rms.documents` (174M images), `mss.amcs_documents` (9.5M/yr), `iacra.application_documents`, `dms` attachments via JSONB | One cloud-native store with OCR + hash-dedup + retention automation. |
| `documents.document_type_taxonomy` | `mss.document_type_taxonomy` (~80 codes) + RMS doc types + IACRA types + DMS types | Single taxonomy. |
| `documents.document_annotations` | `rms.document_annotations` | Preserved immutable annotation pattern. |
| `payments.payments` | `rms.payments`, DMS training fees, CARES payments | Single Pay.gov adapter. |
| `payments.fee_schedule` | Hard-coded in legacy app code | Now data-driven. |
| `aircraft.aircraft` | `rms.aircraft`, `cares.aircraft` | Direct. |
| `aircraft.n_number_reservations` | `rms.n_number_reservations` | Direct + FK to core.persons/organizations. |
| `aircraft.ownership` | `rms.aircraft_ownership` | Supports person OR organization ownership (CHECK constraint). |
| `aircraft.ownership_transfers` | `rms.ownership_transfers` | Adds FK to `workflow.cases`. |
| `aircraft.security_interests` | `rms.security_interests` | Direct. |
| `aircraft.dealer_registrations` | `rms.dealer_registrations` | Direct; now links to `core.organizations`. |
| `aircraft.export_certificates` | `rms.export_certificates` | Direct. |
| `certification.airman_certificates` | `rms.airman_certificates` + `iacra.airman_certificates_issued` + `cares.airman_certificates` | Unified certificate record. |
| `certification.knowledge_tests` | `iacra.knowledge_test_results` | Same shape; source_system tag preserves Atlas Aviation provenance. |
| `certification.practical_tests` | `iacra.practical_tests` + `.practical_test_outcomes` + `cares.airman_practical_tests` | Merged. |
| `certification.pilot_time_records` | `iacra.pilot_time_records` | Direct. |
| `certification.recommending_endorsements` | `iacra.recommending_instructor_endorsements` | Direct. |
| `certification.tsa_vetting` | `iacra.tsa_vetting_records` + `cares.tsa_vetting_records` | Merged. |
| `certification.enforcement_actions` | `rms.airman_enforcement_actions` | Direct; retention enforced via GENERATED column. |
| `medical.medical_applications` | `mss.medxpress_applications` + `mss.medxpress_forms` | Merged; Form 8500-8 items 11-20 normalized via JSONB columns. |
| `medical.exams` | `mss.amcs_exams` | Direct. |
| `medical.exam_findings` | `mss.exam_vitals` + `.exam_vision` + `.exam_hearing` + `.exam_urinalysis` + `.exam_physical_findings` + `.exam_comments` | **6 fixed tables → 1 category-keyed table with JSONB payload**. |
| `medical.medical_certificates` | `mss.exam_disposition` (issued certs) | Cert-focused view. |
| `medical.special_issuance_cases` | `mss.special_issuance_cases` | Direct. |
| `medical.deferred_cases` / `.denied_cases` | `mss.deferred_cases` / `mss.denied_cases` | Direct. |
| `medical.research_cases` | `mss.aeromedical_research_cases` + `mss.toxicology_data` | CAMI de-identified data. |
| `designee.designees` | `dms.designees` (with identity 1:1 to `core.persons`) | Cleaner separation. |
| `designee.designations` | `dms.designations` | Direct. |
| `designee.cloas` | `dms.cloas` | Preserved versioning + one-active constraint. |
| `designee.authorizations` | `dms.designee_authorizations` | Direct. |
| `designee.pre_approval_requests` + `.post_activity_reports` | `dms.*` | Direct; wired into `workflow.cases`. |
| `designee.corrective_actions`, `.performance_evaluations`, `.oversight_activities`, `.training_records`, `.suspensions`, `.terminations`, `.locator_index` | `dms.*` | All direct. |
| `notify.templates` + `.correspondence` | `rms.deficiency_notices`, `rms.registration_renewal_notices`, IACRA emails, DMS Messages, MSS action-required | Single fabric. |
| `integration.endpoints` + `.transactions` | Scattered across 4 systems | Registry + transaction log. |
| `audit.events` | 5 per-system audit tables | Single monthly-partitioned log. |
| `audit.disclosure_log` | Partial in legacy (mostly paper) | New — Privacy Act (e) accounting. |

---

## 4. Data migration complexity

Rated 🟢 easy / 🟡 moderate / 🔴 complex, with the primary risk per entity.

| Entity | Complexity | Primary risk |
|---|---|---|
| `core.countries`, `.us_states` | 🟢 | Static reference. |
| `core.aircraft_models`, `.engine_models` | 🟡 | Slight schema variance across RMS vs IACRA lookup codes; requires reconciliation. |
| `core.persons` | 🔴 | **Deduplication is the hardest migration task.** Same physical person appears in up to 5 systems, keyed differently (FTN here, Cert# there, Applicant ID elsewhere). Requires probabilistic matching (name + DOB + partial SSN + email) + manual review for conflicts. Expect 1–3% residual ambiguity. |
| `core.organizations` | 🟡 | Extract non-individual rows from `rms.owners`; EIN dedup across RMS repeats. |
| `core.addresses` | 🟡 | Split inline addresses from 5 sources; USPS-validate + normalize. |
| `core.entity_principals` | 🟢 | Direct map. |
| `core.users` / RBAC | 🟡 | Consolidate 4 credential stores; Login.gov federation migration. |
| `workflow.cases` | 🟡 | Requires mapping every legacy form/case to a `case_type_code`; legacy status enums map to unified `case_status`. |
| `documents.documents` | 🔴 | **174M TIFFs need:** OCR pass, SHA-256 hashing, perceptual fingerprinting for dedup, retention-schedule binding per document. Estimated 6-12 months of ingestion + OCR compute. |
| `payments.payments` | 🟢 | We only store tx IDs; no PII migration risk. |
| `aircraft.aircraft` + ownership + transfers + liens | 🟡 | Straightforward but 300K records × average 80 years of history = multi-million-row migration; priority-rank order must be preserved exactly (49 USC 44107). |
| `certification.airman_certificates` | 🟡 | Ratings/limitations stored as text in legacy; must parse into TEXT[]. |
| `certification.knowledge_tests` | 🟢 | IACRA linked-server replaced by API; shape preserved. |
| `certification.practical_tests` | 🟡 | Merge IACRA tests + CARES Phase 2 tests + historical CAIS outcomes. |
| `medical.medical_applications` | 🔴 | Form 8500-8 items 11-20 currently stored as either (a) rigid columns in MSS, (b) free-text AMCS notes, or (c) scanned-image-only. OCR + structured extraction required for older cases. 50-yr retention implies ~50M historical records to migrate. |
| `medical.exams` + `.exam_findings` | 🔴 | Collapsing 6 finding tables into generic category+JSONB requires per-row translation; test data re-shape under FIPS HIGH boundary. |
| `medical.special_issuance_cases` | 🟡 | Monitoring-schedule data is often implicit in narrative comments; extraction needed. |
| `designee.*` | 🟡 | DMS is newest system — data is cleanest. Main work is 1:1 person matching to `core.persons`. |
| `notify.correspondence` | 🟢 | Forward-going only; no backfill needed beyond last 2 yrs of audit. |
| `integration.*` | 🟢 | New — no migration. |
| `audit.events` | 🟡 | Backfill 5 yrs of legacy audit logs for enforcement-record retention requirements (5 yr post-close). |

---

## 5. Key integration decisions & trade-offs

### 5.1 FTN as primary airman identifier — trade-offs

**Decision:** `core.persons.ftn` is the primary external lookup key for airmen (not SSN, not legacy certificate number). Legacy identifiers stored as alias rows in `identifier_mappings`.

**Trade-offs:**
- ✅ Eliminates SSN as join key across systems (privacy + Privacy Act compliance win).
- ✅ Matches FAA modernization direction (IACRA + DMS already FTN-based).
- ⚠️ ~1.5M pre-FTN airmen records need FTN assignment during migration.
- ⚠️ Aircraft owners without airman status have NO FTN — must resolve via `person_id` only (FTN is nullable).

### 5.2 Generic `workflow.cases` vs. domain-specific tables

**Decision:** One generic cases table with domain discriminator + nullable FKs to domain-specific entities (`aircraft_id`, `airman_cert_id`, `medical_application_id`, `designation_id`).

**Trade-offs:**
- ✅ Collapses 4 bespoke workflow engines into one state machine.
- ✅ Cross-domain queries become trivial ("show me all cases for this person across all systems").
- ⚠️ Domain-specific constraints (e.g., MSS 14-day submission deadline, DMS 7-day post-activity deadline) live in domain tables, not in `workflow.cases`. Requires careful cross-table triggers.
- ⚠️ Some legacy workflows have subtle state machines that flatten imperfectly to the unified `case_status` enum.

**Alternative considered:** STI (Single Table Inheritance) via one table per domain. Rejected because of 3× code complexity for little benefit — the nullable FK approach is simpler and PostgreSQL-native.

### 5.3 Unified document store with retention at row level

**Decision:** One `documents.documents` table; retention schedule (NARA bucket) stored on each row via enum.

**Trade-offs:**
- ✅ Eliminates 4 separate storage silos and 4 different retention automations.
- ✅ Legal holds, disposal automation, and disclosure logging are universal.
- ⚠️ Same physical table holds FIPS HIGH (medical) and MODERATE (aircraft) content — requires row-level security policies and encrypted-at-rest boundary per key.
- ⚠️ 174M-image OCR pass is a prerequisite capital expense.

### 5.4 FIPS 199 HIGH only on `medical.*` (vs. elevating everything)

**Decision:** Maintain MODERATE classification for non-medical domains; apply HIGH only to `medical.*` tables and audit rows referencing them.

**Trade-offs:**
- ✅ Keeps ATO scope manageable — the HIGH subset is small.
- ✅ Reduces encryption-key / HSM overhead.
- ⚠️ Cross-domain queries that join `medical.*` with others must enforce the HIGH boundary programmatically (e.g., redaction proxy).
- ⚠️ Audit log's HIGH partition must be segregated from MODERATE partitions.

### 5.5 Deprecating SSN as lookup key

**Decision:** SSN stored encrypted (`ssn_encrypted`) + last-4 for display only; no indexes on it; never a join key.

**Trade-offs:**
- ✅ Major privacy win; Privacy Act compliance improved.
- ✅ Reduces risk surface for PII breach.
- ⚠️ Pre-2002 CAIS records where Cert # == SSN require mass migration to FAA-assigned Cert #. 1.5M airmen × need new numbering.

### 5.6 Exam findings normalization: 6 tables → 1 with JSONB

**Decision:** Collapse `exam_vitals`, `exam_vision`, `exam_hearing`, `exam_urinalysis`, `exam_physical_findings`, `exam_comments` into a single `medical.exam_findings` table with `category` enum + JSONB `finding_data`.

**Trade-offs:**
- ✅ 6 tables → 1 — huge simplification for 25+ physical systems per exam.
- ✅ Easier schema evolution when Form 8500-8 changes.
- ⚠️ Loses strict type-checking on, e.g., vision Snellen values (VARCHAR(20) ✓ but JSONB field shape needs application validation).
- ⚠️ Reporting queries must use JSONB operators instead of straight columns.

**Alternative considered:** Keep as 6 tables. Rejected — the JSONB path mirrors modern practice (CMS FHIR, for example).

### 5.7 One Designee Number per person

**Decision:** `designee.designees.person_id` is UNIQUE (1:1 with `core.persons`); `designee_number` is UNIQUE; designations (type-specific) are many-per-designee.

**Trade-offs:**
- ✅ Aligns with DMS rule: one Designee Number per individual regardless of types held.
- ✅ Simplifies locator queries (one name/contact per designee).
- ⚠️ When designees are also airmen/applicants (common — DPEs are pilots), the 1:1 to `core.persons` means their `person_type` is DESIGNEE but they still have all other attributes (ratings, medical history, etc.) — intentional unification.

### 5.8 Eliminating TIFF-over-FTP and SQL linked-server

**Current state:**
- IACRA → CAIS: TIFFs over FTP (fragile, unencrypted).
- IACRA ← Atlas Aviation: SQL linked-server (tight coupling).
- MSS ↔ CAIS: batch demographic sync (delayed, out-of-sync windows).

**Decision:** Replace with `integration.endpoints` registered REST/event APIs; in-flight cases reference documents and test results directly instead of shipping them around.

**Trade-offs:**
- ✅ Eliminates brittle transport layers and OIG-flagged security gaps.
- ⚠️ Requires retiring legacy FTP targets cleanly during CARES cutover.

---

## 6. Text entity-relationship summary

```
┌──────────────────────────────────────────────────────────────────────┐
│                              core.persons                            │
│    (FTN | MyAccess | Login.gov | legacy: Cert#, Applicant ID,       │
│     MID, Designee#)  ◀── identifier_mappings ──▶ all legacy aliases │
└──┬─────────┬─────────┬─────────┬─────────┬─────────┬────────────────┘
   │         │         │         │         │         │
   │         │         │         │         │         │
   ▼         ▼         ▼         ▼         ▼         ▼
addresses  users    aircraft  airman_    medical_  designees
           │         │ ownership│ certificates apps  │ (1:1 person)
           │         │          │            │      │
           │         │          │            ▼      │
           │         │          │         exams ──▶ findings, certs,
           │         │          │                   SI, deferred,
           │         │          │                   denied cases
           │         │          │
           ▼         ▼          ▼
        roles   (aircraft    (certification
                 registry)    workflow)
                    │
                    └──── workflow.cases ◀─── all domains participate
                                │
                          ┌─────┼─────┬───────────┬─────────┐
                          ▼     ▼     ▼           ▼         ▼
                      documents payments  notify.corresp.  audit.events
                                                      │
                                                      └──▶ disclosure_log


╔══════════════════════════════════════════════════════════════════════╗
║  Integration plane                                                   ║
║  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐          ║
║  │ Pay.gov  │   │ Login.gov│   │ TSA NTSDB│   │ DocuSign │   ...    ║
║  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘          ║
║       ▼              ▼              ▼              ▼                 ║
║              integration.endpoints (registry)                        ║
║                         │                                            ║
║                         ▼                                            ║
║              integration.transactions (log)                          ║
╚══════════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════════════╗
║  FIPS 199 boundaries                                                 ║
║                                                                      ║
║  ┌──────────────────────────────────────────────────────────────┐    ║
║  │ FIPS HIGH boundary (medical. + audit rows referencing it)    │    ║
║  │  ┌─────────────────────────────────────────────────────┐     │    ║
║  │  │ medical.medical_applications, exams, findings,      │     │    ║
║  │  │ medical_certificates, SI cases, deferred/denied,    │     │    ║
║  │  │ research_cases (de-identified)                      │     │    ║
║  │  └─────────────────────────────────────────────────────┘     │    ║
║  └──────────────────────────────────────────────────────────────┘    ║
║                                                                      ║
║  ┌──────────────────────────────────────────────────────────────┐    ║
║  │ FIPS MODERATE                                                │    ║
║  │  core.*, workflow.*, documents.*, payments.*, aircraft.*,    │    ║
║  │  certification.*, designee.*, notify.*, integration.*        │    ║
║  └──────────────────────────────────────────────────────────────┘    ║
╚══════════════════════════════════════════════════════════════════════╝
```

**Key cardinalities:**
- 1 person : many aircraft ownerships, many airman certs, many medical exams, many cases, at most 1 designee record.
- 1 aircraft : many owners (co-ownership via `aircraft.ownership` junction).
- 1 case : many documents, at most 1 payment, many participants, many history events.
- 1 designee : many designations (one per type held).
- 1 designation : many CLOA versions (one active), many pre-approvals, one concurrent Additional Auth request.

---

## 7. Consolidation summary by dimension

| Dimension | Before | After | Benefit |
|---|---|---|---|
| **Tables** | 141 | 75 | −47% operational surface; fewer joins; simpler ETL. |
| **Person records** | Duplicated in 5 systems | 1 master + N aliases | One-identity-per-person → cross-system queries trivial. |
| **Document silos** | 4 physical stores, 174M+ TIFFs | 1 cloud store, OCR + dedup | Searchable corpus; automated retention. |
| **Workflow engines** | 4 bespoke | 1 generic case + state machine | One audit trail; one UX pattern; cheaper to evolve. |
| **Pay.gov integrations** | 4 | 1 | Single Treasury contract; consistent PII minimization. |
| **Audit logs** | 5 | 1 unified + 1 disclosure | Privacy Act (e) compliance + SORN-scoped queries. |
| **RBAC systems** | 4+ | 1 | Single identity federation (MyAccess → Login.gov). |
| **FIPS HIGH boundary** | Spread across MSS subsystems + spillover | `medical.*` only | Smaller ATO scope; clearer accreditation. |
| **Retention automation** | Per-system cron jobs | Row-level enum + central job | Consistent NARA compliance. |
| **Notification fabric** | 4 templates/engines | 1 template catalog | Consistent branding; reviewable messaging. |

---

## 8. Known gaps & future work

| Gap | Resolution path |
|---|---|
| CAMI toxicology research data remains de-identified — linkage to unified person requires deliberate policy decision. | Policy review before migration; likely keep `person_hash` only. |
| Pre-2002 airman records with SSN-as-cert# must be renumbered. | Batch conversion during Phase 2 migration. |
| MSS confidentiality boundary — ADADE/AMCD access controls need mapping to unified RBAC. | Role mapping workshop with CAMI. |
| Trust ownership compliance (OIG 2014) — `non_citizen_trustee_declaration` must be enforced for existing trusts, not just new registrations. | Backfill validation sweep. |
| CARES hybrid-state: while CAIS remains authoritative, unified schema must dual-write. | `integration.transactions` tracks both legs; authoritative source clearly labelled per case. |

---

*Generated as part of the FAA AVS Rationalization Project — Data Model Deliverable (Part 4).*
