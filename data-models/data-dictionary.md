# FAA AVS Unified Certification Portal — Data Dictionary

Comprehensive field-level reference for the integrated unified schema (and cross-references back to the source systems that contributed each field). Organized by business domain. All tables referenced live in the unified schema (`data-models/integrated/unified-schema.sql`) unless marked **(current-state only)**.

Legend — Source systems:
- **RMS** = Registry Modernization System (CAIS/IMS — aircraft + airmen mainframe)
- **MSS** = MedXPress / MSS (medical, 6 subsystems: MedXPress, AMCS, DIWS, CPDSS, CAMI, AMCD)
- **IACRA** = Integrated Airman Certification and Rating Application
- **DMS** = Designee Management System
- **CARES** = Civil Aviation Registration Electronic Services (cloud replacement platform)
- **DERIVED** = new field introduced by the unified model
- **EXT** = sourced from an external system (Pay.gov, TSA NTSDB, Atlas Aviation, Login.gov, etc.)

---

## 1. IDENTITY DOMAIN (`core`)

### `core.persons` — Unified person master

The golden record that resolves all legacy identifiers (FTN, Certificate #, Applicant ID, MID, Designee #) to a single row per individual.

| Column | Type | Nullable | Source | Description & Business Rules |
|---|---|---|---|---|
| person_id | UUID | NO | DERIVED | Primary key. |
| ftn | VARCHAR(12) | YES | IACRA/DMS | Federal Tracking Number. Primary lookup key for airmen; assigned at IACRA account creation. Unique where present. |
| myaccess_subject_id | VARCHAR(255) | YES | EXT (MyAccess) | Federated identity subject. |
| login_gov_sub | VARCHAR(255) | YES | EXT (Login.gov) | Future federation key. |
| piv_card_dn | VARCHAR(512) | YES | EXT | X.500 DN for FAA-staff accounts. |
| first_name | VARCHAR(100) | NO | RMS/IACRA/MSS/DMS | Legal first name or "NFN". |
| middle_name | VARCHAR(100) | YES | RMS/IACRA/MSS/DMS | Legal middle name or "NMN". |
| last_name | VARCHAR(100) | NO | RMS/IACRA/MSS/DMS | Legal surname. |
| name_suffix | VARCHAR(20) | YES | IACRA/DMS | Jr, Sr, III, etc. |
| full_legal_name | VARCHAR(255) | GEN | DERIVED | Computed concatenation (STORED). |
| other_names_used | TEXT | YES | MSS | Aliases / maiden names. |
| date_of_birth | DATE | NO | RMS/IACRA/MSS/DMS | Must match across all system attestations. |
| sex | CHAR(1) | YES | RMS/IACRA/MSS | M/F/U/X; immutable once Airman Registry has synced. |
| ssn_encrypted | BYTEA | YES | RMS/IACRA/MSS | AES-256-encrypted SSN; **never a lookup key**. |
| ssn_last_4 | CHAR(4) | YES | RMS | Collected per Privacy Act disclosure only. |
| hair_color | VARCHAR(30) | YES | RMS/MSS | Physical descriptor. |
| eye_color | VARCHAR(30) | YES | RMS/MSS | Physical descriptor. |
| height_inches | SMALLINT | YES | RMS/MSS | Height in inches. |
| weight_lbs | SMALLINT | YES | RMS/MSS | Weight in pounds. |
| citizenship_country | CHAR(2) | YES | IACRA/RMS | ISO 3166-1 alpha-2. Immutable after Registry sync. |
| country_of_birth | CHAR(2) | YES | IACRA/MSS | ISO 3166-1 alpha-2. |
| state_of_birth | CHAR(2) | YES | IACRA | US state (required if born in US). |
| city_of_birth | VARCHAR(100) | YES | IACRA/MSS | Birth city. |
| email_address | VARCHAR(255) | NO | IACRA/MSS/DMS | Must be unique within any one source system; used for MFA. |
| phone_primary | VARCHAR(30) | YES | All | Primary phone (with area code). |
| phone_secondary | VARCHAR(30) | YES | DMS | Secondary phone. |
| identity_assurance_level | ENUM | YES | EXT | NIST 800-63-3 IAL1/IAL2/IAL3. |
| identity_proofed_at | TIMESTAMPTZ | YES | EXT | When identity was proofed (MyAccess / Login.gov). |
| identity_proofing_method | VARCHAR(50) | YES | EXT | myaccess_selfie, piv_card, login_gov, etc. |
| person_type | ENUM | NO | DERIVED | AIRMAN/APPLICANT/REGISTRANT/DESIGNEE/FAA_STAFF/FAA_CONTRACTOR/MEDICAL_APPLICANT. |
| legacy_cert_number | VARCHAR(20) | YES | RMS | Pre-2002 SSN-backed certificate number. |
| legacy_applicant_id | VARCHAR(20) | YES | MSS | MSS applicant identifier. |
| legacy_designee_number | VARCHAR(20) | YES | DMS | 9-char designee number. |
| legacy_mid | VARCHAR(20) | YES | MSS | Per-exam Medical ID (now superseded by exam_id). |
| created_at | TIMESTAMPTZ | NO | DERIVED | Row creation. |
| updated_at | TIMESTAMPTZ | NO | DERIVED | Last modification. |
| deprecated_at | TIMESTAMPTZ | YES | DERIVED | Set when merged into another record. |
| merged_into_person_id | UUID | YES | DERIVED | Forward pointer after dedup merge. |

### `core.identifier_mappings` — Legacy-ID resolver
| Column | Type | Source | Notes |
|---|---|---|---|
| mapping_id | UUID | DERIVED | PK. |
| person_id | UUID | DERIVED | FK to persons. |
| identifier_type | VARCHAR(30) | DERIVED | FTN, CERTIFICATE_NUMBER, APPLICANT_ID, MID, DESIGNEE_NUMBER, LEGACY_SSN_HASH. |
| identifier_value | VARCHAR(100) | Source system | The alias string. |
| source_system | VARCHAR(30) | DERIVED | UNIFIED, CARES, CAIS, RMS, MSS, DMS, IACRA. |
| is_primary | BOOLEAN | DERIVED | Primary alias for the person within source system. |

### `core.organizations` — Partnerships, corps, LLCs, trusts, FBOs, schools
| Column | Type | Source | Notes |
|---|---|---|---|
| organization_id | UUID | DERIVED | PK. |
| organization_name | VARCHAR(255) | RMS/IACRA | Common name. |
| organization_type | VARCHAR(50) | DERIVED | flight_school, fbo, airline, dealer, repair_station, etc. |
| entity_type | ENUM | RMS | INDIVIDUAL, PARTNERSHIP, CORPORATION, LLC, TRUST, NON_CITIZEN_CORP, etc. (preserves AC 8050-1 codes). |
| legal_name | VARCHAR(255) | RMS | Legal registered name. |
| ein | VARCHAR(10) | RMS | Unique Employer ID Number. |
| state_of_formation | CHAR(2) | RMS | US state (corps/LLCs). |
| country_of_formation | CHAR(2) | RMS | ISO alpha-2 (non-citizen corps). |
| primary_contact_person_id | UUID | RMS/DMS | FK to persons. |
| business_email | VARCHAR(255) | All | Contact email. |
| business_phone | VARCHAR(30) | All | Contact phone. |
| certificate_number | VARCHAR(50) | RMS | Repair station cert, etc. |
| faa_approval_status | VARCHAR(30) | DERIVED | approved/pending/revoked. |
| is_trust | BOOLEAN | RMS | Trust ownership flag. |
| trustee_person_id | UUID | RMS | Link to trustee (OIG 2014 compliance). |
| non_citizen_trustee_declaration | BOOLEAN | RMS | Required when trustee is non-citizen. |
| intl_ops_declaration | BOOLEAN | RMS | International operations declaration. |
| primarily_used_in_us | BOOLEAN | RMS | Non-citizen corp attestation. |
| flight_hour_records_location | VARCHAR(500) | RMS | Required for non-citizen corps. |

### `core.addresses` — Unified postal address
| Column | Type | Source | Notes |
|---|---|---|---|
| address_id | UUID | DERIVED | PK. |
| person_id | UUID | DERIVED | FK; mutually exclusive with organization_id. |
| organization_id | UUID | DERIVED | FK; mutually exclusive with person_id. |
| address_type | ENUM | All | MAILING/PHYSICAL/BUSINESS/RESIDENTIAL/ALTERNATE. |
| street_line_1..3 | VARCHAR | RMS | Line 3 handles rural route / PO Box. |
| city | VARCHAR(100) | All | City name. |
| state_code | CHAR(2) | All | US state (required for US). |
| province | VARCHAR(100) | All | Non-US province. |
| postal_code | VARCHAR(20) | All | ZIP or international postal code. |
| country_code | CHAR(2) | All | ISO 3166-1 alpha-2. |
| location_description | VARCHAR(500) | RMS | Required when mailing is a PO Box / rural route (14 CFR Part 47). |
| is_po_box | BOOLEAN | RMS | Affects online-renewal eligibility. |
| validated | BOOLEAN | DERIVED | USPS or SmartyStreets validation flag. |
| latitude, longitude | NUMERIC | DERIVED | Optional geocoding. |
| effective_from_date, effective_to_date | DATE | DERIVED | Address history support. |

### `core.entity_principals` — Partners, officers, trustees, beneficiaries
Records the individuals who represent an organization (partners, corp officers, LLC managing members, trustees, beneficiaries). Replaces `rms.entity_principals`.

### `core.users` / `core.roles` / `core.permissions` / `core.user_role_assignments`
RBAC catalog. Roles include: APPLICANT, RECOMMENDING_INSTRUCTOR, DPE/DME/AME/DAR/etc., SCHOOL_ADMIN, FSDO_INSPECTOR, ACB_ANALYST, CAMI_PHYSICIAN, REGISTRY_EXAMINER, AIRWORTHINESS_INSPECTOR, ADMIN, SYSTEM.

### `core.offices` — FSDO, IFO, AEG, ACO, RHQ, CAMI, AAM
Consolidates FAA field-office reference previously replicated in each system.

### `core.aircraft_manufacturers` / `core.aircraft_models` / `core.engine_manufacturers` / `core.engine_models`
Single authoritative make/model reference — consolidates RMS lookups and IACRA lookups.

### `core.system_classification`
FIPS 199 category, SORN scope, NARA retention default, ATO date — one row per major subsystem.

---

## 2. WORKFLOW DOMAIN (`workflow`)

### `workflow.case_types`
Catalog of 50+ case types replacing separate form inventories in RMS, IACRA, MSS, DMS.

### `workflow.cases` — Single generic case
One row per application / filing / request regardless of domain.

| Column | Type | Source | Notes |
|---|---|---|---|
| case_id | UUID | DERIVED | PK. |
| case_reference_number | VARCHAR(30) | DERIVED | Human-readable ID. |
| case_type_code | VARCHAR(50) | DERIVED | FK to case_types. |
| case_domain | ENUM | DERIVED | AIRCRAFT_REGISTRATION / AIRMAN_CERTIFICATION / MEDICAL_CERTIFICATION / DESIGNEE_MANAGEMENT. |
| status | ENUM | DERIVED | DRAFT/SUBMITTED/RECOMMENDED/IN_REVIEW/ACTION_REQUIRED/APPROVED/DENIED/DEFERRED/ISSUED/CLOSED. |
| workflow_stage | SMALLINT | IACRA | Numeric stage pointer (1-6 in IACRA). |
| applicant_person_id | UUID | All | FK. |
| applicant_organization_id | UUID | RMS | FK for org-backed filings. |
| assigned_to_user_id | UUID | All | Current assignee (examiner / inspector / MS). |
| responsible_office_id | UUID | All | Managing FSDO/IFO/AEG/ACO/CAMI. |
| aircraft_id | UUID | RMS | Nullable FK to aircraft. |
| airman_cert_id | UUID | IACRA | Nullable FK to airman_certificates. |
| medical_application_id | UUID | MSS | Nullable FK to medical_applications. |
| designation_id | UUID | DMS | Nullable FK to designations. |
| document_package_id | UUID | DERIVED | FK to documents (aggregate). |
| payment_id | UUID | DERIVED | FK to payments. |
| signature_envelope_id | VARCHAR(255) | EXT | DocuSign envelope ID. |
| signature_status | ENUM | DERIVED | NOT_REQUIRED/PENDING/EXECUTED/DECLINED/VOIDED/EXPIRED. |
| opened_at, submitted_at, decided_at, closed_at, deadline_at | TIMESTAMPTZ | All | Case lifecycle timestamps. |

### `workflow.case_history`
Append-only log of every status transition (who, when, why, IP). Replaces bespoke state-change logs in each system.

### `workflow.case_participants`
Many-to-many join — users who are involved in a case (applicant, RI, DPE, AME, ASI, school admin, reviewer, appointing official).

---

## 3. DOCUMENTS DOMAIN (`documents`)

### `documents.document_type_taxonomy`
Single taxonomy across all domains — replaces 4 separate document catalogs (RMS IMS codes, MSS DIWS ~80 codes, IACRA document types, DMS attachment types).

| Column | Notes |
|---|---|
| doc_type_id | PK (e.g., BILL_OF_SALE, ECG_STRIP, 8710_FORM, CLOA, POA). |
| document_class | legal_deed / medical_record / exam_result / form_submission / corrective_action / training_cert. |
| applicable_domains | Array of workflow.case_domain values. |
| default_retention | NARA schedule enum. |
| is_pii, is_phi | Classification flags. |

### `documents.documents` — Unified store (replaces 174M TIFF silo + 3 others)

| Column | Type | Source | Notes |
|---|---|---|---|
| document_id | UUID | DERIVED | PK. |
| case_id | UUID | DERIVED | FK. |
| doc_type_id | VARCHAR(50) | DERIVED | FK to taxonomy. |
| document_title | VARCHAR(500) | All | Display title. |
| document_date | DATE | MSS | Date of event (not upload). |
| cloud_storage_uri | VARCHAR(2048) | DERIVED | Object-store key (S3/GCS). Replaces IMS file path + FTP path. |
| file_format | VARCHAR(20) | All | PDF/TIFF/PDF_A/PNG/JPEG/DOCX/XPS. |
| file_size_bytes | BIGINT | All | Legacy 3MB limit (MSS) raised. |
| file_hash_sha256 | CHAR(64) | DERIVED | Integrity + dedup. |
| ocr_applied, ocr_text, extracted_entities | BOOLEAN/TEXT/JSONB | DERIVED | ML enrichment (modernization layer). |
| document_fingerprint | VARCHAR(64) | DERIVED | Perceptual hash for dedup across 174M images. |
| virus_scanned, virus_scan_timestamp | BOOLEAN/TS | DERIVED | Security gate. |
| encryption_algorithm | VARCHAR(30) | DERIVED | AES-256 at rest. |
| retention_schedule | ENUM | DERIVED | NARA schedule bound at row. |
| disposal_scheduled_date, disposal_executed_date | DATE | DERIVED | Retention automation. |
| legal_hold_flag, legal_hold_reason | BOOLEAN/VARCHAR | DERIVED | Litigation hold. |
| docusign_envelope_id, docusign_status, signer_user_id, signed_at | Various | EXT | Signature metadata. |
| supersedes_document_id | UUID | IACRA | Corrected version chain. |
| uploaded_by_user_id, uploaded_at | UUID/TS | All | Ingestion audit. |

### `documents.document_annotations`
Immutable registration / recordation annotations (RMS pattern) — dated decision statements attached to a document.

---

## 4. PAYMENTS DOMAIN (`payments`)

### `payments.fee_schedule`
| Column | Notes |
|---|---|
| fee_code | PK — REG_FEE, RENEW_FEE, RECORDING_FEE, DEALER_FEE, DUPLICATE_CERT_FEE, etc. |
| amount_cents | Integer cents (no float). |
| case_type_code | Optional FK — fee tied to a case type. |
| effective_from_date, effective_to_date | Price history. |

### `payments.payments` — Pay.gov adapter
| Column | Type | Source | Notes |
|---|---|---|---|
| payment_id | UUID | DERIVED | PK. |
| case_id | UUID | DERIVED | FK to cases. |
| fee_code | VARCHAR(50) | DERIVED | FK to fee_schedule. |
| originating_system | VARCHAR(30) | DERIVED | UNIFIED (today: separate per system). |
| amount_cents | INTEGER | RMS/IACRA/MSS/DMS | Fee amount. |
| pay_gov_transaction_id | VARCHAR(100) | EXT | Treasury TX ID. **Only** Pay.gov reference stored — no PAN. |
| pay_gov_agency_tracking_id | VARCHAR(100) | EXT | FAA tracking. |
| payment_method | VARCHAR(30) | EXT | CREDIT_CARD/ACH/CHECK/MONEY_ORDER. |
| payment_status | ENUM | DERIVED | PENDING/SUBMITTED/COMPLETED/FAILED/CANCELLED/REFUNDED. |
| confirmation_token | VARCHAR(255) | EXT | Pay.gov confirmation. |
| payer_person_id, payer_email | UUID/VARCHAR | All | Who paid. |
| refund_of_payment_id | UUID | DERIVED | Self-reference for refunds. |

### `payments.receipts`
| Column | Notes |
|---|---|
| receipt_number | Unique. |
| accounting_code | FAA accounting string. |

---

## 5. AIRCRAFT REGISTRATION DOMAIN (`aircraft`)

### `aircraft.aircraft` — Master registration record
| Column | Type | Source | Notes |
|---|---|---|---|
| aircraft_id | UUID | DERIVED | PK. |
| n_number | VARCHAR(6) | RMS | CHECK regex `^N[A-Z0-9]{1,5}$`; unique, never reassigned after de-registration. |
| serial_number | VARCHAR(50) | RMS | Manufacturer serial. |
| mfr_mdl_code | VARCHAR(20) | RMS | FK to `core.aircraft_models`. |
| eng_mfr_mdl_code | VARCHAR(20) | RMS | FK to `core.engine_models`. |
| year_mfr | SMALLINT | RMS | 1900-2100. |
| num_engines, num_seats | SMALLINT | RMS | Configuration. |
| aircraft_category | VARCHAR(50) | RMS | airplane, rotorcraft, glider, balloon, airship. |
| aircraft_class | VARCHAR(50) | RMS | SEL, MEL, helicopter, etc. |
| type_aircraft | VARCHAR(50) | RMS | general_aviation, commercial. |
| type_engine | VARCHAR(50) | RMS | reciprocating, turboprop, turbojet, electric. |
| mode_s_code_hex | CHAR(6) | RMS | 24-bit ICAO ADS-B identifier; unique per aircraft. |
| airworthiness_cert_type | VARCHAR(50) | RMS | standard/special/provisional/experimental. |
| registration_type | ENUM | RMS | AC 8050-1 type (individual/corp/LLC/trust/non-citizen/etc.). |
| registration_status | ENUM | RMS | PENDING/ACTIVE/EXPIRED/CANCELLED/DEREGISTERED/SUSPENDED/REVOKED. |
| registration_issue_date | DATE | RMS | Most recent issue. |
| registration_expiration_date | DATE | RMS | 7-year cycle per FAA Reauthorization Act 2018. |
| last_action_date | DATE | RMS | Most recent Registry touch. |
| import_country | CHAR(2) | RMS | For imported aircraft. |
| is_dealer_aircraft | BOOLEAN | RMS | 14 CFR Part 47 Subpart C. |

### `aircraft.n_number_reservations`
Pre-registration reservation of an N-number. Channel: online/telephone/mail.

### `aircraft.ownership`
Junction aircraft ↔ (person OR organization). Supports co-ownership with `ownership_share_pct`. Current ownership is the row with `ownership_end_date IS NULL`.

### `aircraft.ownership_transfers`
Bill-of-sale / divorce decree / court order / inheritance / trustee succession / merger / repossession transfers. `receipt_date` is the 49 USC 44107 timestamp establishing recording priority.

### `aircraft.security_interests`
Mortgages, liens, leases, conditional sales contracts per 14 CFR Part 49. Filing order preserved by `filing_date` timestamp; `priority_rank` is derived.

### `aircraft.dealer_registrations`
14 CFR Part 47 Subpart C dealer certificates (12-month cycle).

### `aircraft.export_certificates`
Export / Certificate of Airworthiness (CoA) per ICAO Annex 7. Priority-processed.

---

## 6. CERTIFICATION DOMAIN (`certification`)

### `certification.certificate_type_reference`
Catalog with minimum_age, requires_medical, requires_knowledge_test, requires_practical_test, etc.

### `certification.test_codes`
PAR, IRA, ATM, etc. — with validity period (24 mo default).

### `certification.airman_certificates`
| Column | Type | Source | Notes |
|---|---|---|---|
| certificate_id | UUID | DERIVED | PK. |
| person_id | UUID | DERIVED | FK. |
| case_id | UUID | IACRA | Issuing application. |
| certificate_number | VARCHAR(20) | RMS/IACRA | FAA-assigned (post-2002); unique. |
| certificate_type | ENUM | IACRA | STUDENT_PILOT/PRIVATE/COMMERCIAL/ATP/CFI/REMOTE_PILOT/MECHANIC/REPAIRMAN/DISPATCHER. |
| certificate_class | VARCHAR(30) | IACRA | private/commercial/ATP. |
| certificate_level | VARCHAR(30) | IACRA | recreational/private/commercial/airline. |
| ratings | TEXT[] | RMS/IACRA | ASEL, AMEL, ASES, AMES, Glider, Rotorcraft, Instrument, type-ratings. |
| limitations | TEXT[] | RMS/IACRA | Endorsement-style limitations. |
| issue_date | DATE | IACRA | Certificate date. |
| expiration_date | DATE | IACRA | Nullable (pilot certs generally non-expiring; CFI expires). |
| status | ENUM | RMS/IACRA | ISSUED/RENEWED/EXPIRED/SUSPENDED/REVOKED/SURRENDERED/DENIED/TEMPORARY. |
| temporary_expiration_date | DATE | IACRA | 120-day temp cert at practical test pass. |
| superseded_by_cert_id | UUID | DERIVED | Chain when a new certificate replaces prior. |

### `certification.knowledge_tests`
Ingested from Atlas Aviation (external test vendor). `is_expired` computed from `expiration_date` (24 mo rule).

### `certification.practical_tests` + `.practical_test_outcomes`
Per-test record including aircraft used (1 or 2), examiner (FK to `designee.designees`), outcome (APPROVE/DISAPPROVE/DISCONTINUE/DELETE), failed-areas JSON.

### `certification.pilot_time_records`
Pilot time: PIC, SIC, instrument, night, cross-country, simulator (per aircraft used in test).

### `certification.recommending_endorsements`
RI endorsement with checklist (flight hours verified, cross-country met, solo time met, etc.).

### `certification.tsa_vetting`
TSA NTSDB vetting for foreign-student / flight-training applicants.

### `certification.enforcement_actions`
Suspensions, revocations, civil penalties, denials. `retention_destroy_date = case_closed_date + 5 years` (FAA Order 1350.15C Item 2150.5.a).

---

## 7. MEDICAL DOMAIN (`medical`) — FIPS HIGH

### `medical.disease_condition_codes`
ICD-10 + Part 67 disqualifying conditions with SI category mapping.

### `medical.medications`
FDA medication reference with contraindication flags.

### `medical.medical_applications` — Form 8500-8
Captures all 20 items of the 8500-8 as normalized columns + JSONB (medications, Item 18 conditions, 3-yr health visits, convictions, drug/alcohol driving, disability benefits).

### `medical.exams`
AME-conducted exam. 14-day submission deadline (7-day for student cert) enforced via `submission_deadline` generated column. `locked` after transmission. `pi_number` is lifetime pathology identifier.

### `medical.exam_findings`
Generalized findings table keyed on category (VITALS, VISION, HEARING, URINALYSIS, PHYSICAL, ECG) with JSONB payload — replaces ~6 separate tables in MSS.

### `medical.medical_certificates`
Issued medical certificate: class, issue/expiration, limitations, SI flag.

### `medical.special_issuance_cases`
SI tracking: cardiac/diabetes/mental_health/neuro/vision/hearing/substance/other. `follow_up_next_due` drives monitoring alerts; `monitoring_schedule` = 6_monthly / annual / biennial / per_FAS_order. `status_history` JSONB.

### `medical.deferred_cases` / `medical.denied_cases`
Deferred → documentation requested → response_deadline → resolved disposition.
Denied → appeal_rights_letter → appeal_filed → appeal decision.

### `medical.research_cases`
CAMI de-identified research (person_hash rather than person_id). Toxicology, cardiac review, diabetes research cohorts.

---

## 8. DESIGNEE DOMAIN (`designee`)

### `designee.designee_types`
13+ types (DPE, SAE, Admin PE, DME, DPRE, DADE, TCE, APD, DAR-T, DAR-F, DMIR, DER, AME, IA, ODA, ODAR, ACSEP, TCSEP, SFAR). Renewal cycle and authority scope documented per row.

### `designee.function_codes`
Authority function codes (A1, A2, B1, ...) mapped to applicable designee types.

### `designee.designees`
One row per individual designee. Links to `core.persons.person_id` (1:1). Contains `designee_number` (9-char UNIQUE — one number per person regardless of types held).

### `designee.designations`
One row per type held by a designee. `UNIQUE (designee_id, designee_type_code)` enforces "one designation per type per person."

### `designee.cloas`
Versioned Certificate of Letter of Authority. Only one active per designation (partial unique index). New versions on appointment, additional-auth approval, annual extension, location change.

### `designee.authorizations`
Function-code grants; `auto_approval_enabled` drives pre-approval routing.

### `designee.pre_approval_requests` + `.post_activity_reports`
Pre-approval requests must have `test_date >= CURRENT_DATE`. Post-activity reports due within 7 days — `is_overdue` computed column; new pre-approvals blocked while overdue reports exist.

### `designee.corrective_actions`
Office-initiated remediation with MS response gate, up to 5 returns for clarification.

### `designee.performance_evaluations`
Technical / Procedural / Professional ratings → overall rating → required_action (NONE/OVERSIGHT_PLAN/SUSPEND/REDUCE/TERMINATE). Follow-up in 6–36 months depending on rating.

### `designee.oversight_activities`
Direct observation, counseling, record feedback, training-record update. AME exempt from Direct Observation per Order 8000.95D V2.

### `designee.training_records`
Initial / recurrent / orientation / specialty courses with Pay.gov payment link.

### `designee.suspensions`
180-day window with `release_due_date` generated column; release request → approved/denied; denial or 181 days → termination.

### `designee.terminations`
Voluntary / not-for-cause / for-cause / expired / reinstatement-denied / non-submittal. For-cause: 15-day designee response → panel assembly → AO decision.

### `designee.locator_index`
Published subset for public Designee Locator (no auth required) when `flag_publish_to_locator = true`.

---

## 9. NOTIFY DOMAIN (`notify`)

### `notify.templates`
Centralized email/letter/portal-message templates — one catalog versus four (RMS deficiency notices, IACRA emails, MSS action-required, DMS Message Center).

### `notify.correspondence`
Delivery record with channel (EMAIL/USPS_LETTER/PORTAL_MESSAGE/SMS/FAX), delivery status, viewed_at, acknowledged_at. FK to `notify.templates` and to `workflow.cases`.

---

## 10. INTEGRATION DOMAIN (`integration`)

### `integration.endpoints`
Registry of outbound/inbound integration endpoints (TSA NTSDB, Pay.gov, Atlas Aviation, FDA, Login.gov, MyAccess, DocuSign, CAIS, Aviator).

### `integration.transactions`
Per-transaction log with retry count, latency, SLA deviation tracking.

---

## 11. AUDIT DOMAIN (`audit`)

### `audit.events`
Single unified audit log replacing 4+ per-system audit tables. Every CREATE/READ/UPDATE/DELETE/EXPORT/DISCLOSURE/APPROVE/SUBMIT/LOGIN/LOGOUT event with before/after JSONB diff, IP, SORN scope, PII/PHI flags. Partitioned by month.

### `audit.disclosure_log`
Privacy Act (e) accounting of disclosures — who received what PII, under which SORN routine use, and why.

---

## Domain-by-domain NARA retention summary

| Domain | Retention Schedule | Applies to |
|---|---|---|
| Aircraft records (documents, annotations) | **PERMANENT** N1-237-04-03 | All aircraft-domain documents. |
| Airmen master file + certs | 60 yr (NARA N1-237-06-001) | `core.persons` with `person_type=AIRMAN`, `certification.airman_certificates`. |
| Enforcement records | 5 yr post-closure (FAA Order 1350.15C Item 2150.5.a) | `certification.enforcement_actions`. |
| Foreign license verification | CY + 6 mo | Legacy RMS records migrated. |
| Medical records (applications, exams, SI, documents) | **50 yr** (NARA N1-237-05-005) | All `medical.*` tables + linked documents. |
| Designee records | 25 yr post-inactive (NARA DAA-0237-2020-0013) | All `designee.*` tables + linked documents. |
| IACRA temp records | Per N1-237-09-14 | Draft/deleted applications. |

---

## FIPS 199 classification per domain

| Domain | Classification | Rationale |
|---|---|---|
| `medical.*` | **HIGH** | PHI + Privacy Act high-sensitivity (SSN, HIV, mental health, DUI). |
| `audit.*` | HIGH (inherits) | Retains PHI/PII change snapshots. |
| `core.*` | MODERATE (HIGH for medical-linked rows) | PII pervasive. |
| `aircraft.*`, `designee.*`, `certification.*` | MODERATE | PII + regulatory data. |
| `workflow.*`, `documents.*`, `payments.*`, `notify.*`, `integration.*` | MODERATE | Operational data with PII touchpoints. |

Encryption: AES-256 at rest (TDE + column-level for `ssn_encrypted`); TLS 1.2+ in transit; HSM-backed key management.

---

## Identifier cross-walk

| Legacy ID | Source System | Unified target | Resolver |
|---|---|---|---|
| N-number | RMS | `aircraft.aircraft.n_number` (UNIQUE) | Direct — preserved verbatim. |
| FTN | IACRA (primary) | `core.persons.ftn` | Direct — airman backbone. |
| Airman Certificate # | RMS CAIS | `core.persons.legacy_cert_number` + `identifier_mappings` | Resolve to `person_id`. |
| SSN (pre-2002) | RMS | `core.persons.ssn_encrypted` | Never a key; deprecated. |
| Applicant ID | MSS | `identifier_mappings` | Map to `person_id`. |
| MID | MSS | `identifier_mappings` (per-exam) | Map to `medical.exams.exam_id`. |
| Confirmation # | MedXPress | `medical.medical_applications.confirmation_number` | Short-lived handoff ID. |
| PI Number | MSS AMCD | `medical.exams.pi_number` | Lifetime per-airman pathology ID. |
| Designee # | DMS | `core.persons.legacy_designee_number` + `designee.designees.designee_number` | One per person. |
| MyAccess Subject | MyAccess | `core.persons.myaccess_subject_id` + `core.users.myaccess_subject_id` | Federated. |
| Login.gov Sub | Login.gov | `core.persons.login_gov_sub` + `core.users.login_gov_sub` | Federated (cutover Aug 2025 for DMS). |
| Confirmation # | RMS renewal | `notify.correspondence` security code | Online-renewal auth code. |

---

## Business-rule inventory (abridged, enforced in schema)

| Rule | Enforced by |
|---|---|
| N-number format `N[A-Z0-9]{1,5}` | CHECK on `aircraft.aircraft.n_number`. |
| 7-year aircraft registration cycle | Application layer + `registration_expiration_date`. |
| 12-month dealer cycle | Application layer + `aircraft.dealer_registrations.expiration_date`. |
| 24-month knowledge test validity | `is_expired` generated column on `certification.knowledge_tests`. |
| 120-day temp certificate | `certification.airman_certificates.temporary_expiration_date`. |
| 60-day MedXPress confirmation expiry | `medical.medical_applications.expires_at`. |
| 14-day AME exam submission (7 for student) | `medical.exams.submission_deadline` generated column. |
| 50-year medical retention | `documents.retention_schedule = MEDICAL_50Y_N1_237_05_005`. |
| 7-day post-activity report deadline | `designee.post_activity_reports.is_overdue` generated column. |
| 180-day suspension window | `designee.suspensions.release_due_date` generated column. |
| 1-year reinstatement window | CHECK on `dms.reinstatement_requests`. |
| One active CLOA per designation | Partial unique index on `designee.cloas`. |
| One open Additional Auth per designation | Partial unique index on `dms.additional_authorizations`. |
| Pre-approval test_date ≥ today | CHECK constraint. |
| One designee_number per person | UNIQUE on `designee.designees.designee_number`. |
| Trust requires trustee disclosure | `core.organizations.is_trust` + `trustee_person_id`. |
| Non-citizen trustee declaration | `core.organizations.non_citizen_trustee_declaration`. |
| Ownership share 0 < pct ≤ 100 | CHECK on `aircraft.ownership`. |

---

*Generated as part of the FAA AVS Rationalization Project — Data Model Deliverable.*
