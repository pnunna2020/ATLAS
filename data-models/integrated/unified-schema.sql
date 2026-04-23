-- =============================================================================
-- FAA AVS Unified Certification Portal — Integrated Data Model
-- =============================================================================
-- Consolidates data from RMS, MedXPress/MSS, IACRA, DMS, CARES into a single
-- normalized model organized by business domain. Key design principles:
--
--   1. ONE PERSON RECORD — FTN-backed master resolves 5 legacy identifiers
--      (FTN, Certificate #, Applicant ID, MID, Designee #, legacy SSN hash).
--   2. ONE DOCUMENT STORE — replaces 4 TIFF silos (IMS 174M, DIWS,
--      IACRA staging, DMS attachments) with cloud-native, OCR-indexed,
--      hash-verified object storage.
--   3. ONE WORKFLOW ENGINE — generic case + state machine replaces 4 bespoke
--      approval flows (aircraft reg, airman cert, medical cert, designee mgmt).
--   4. ONE AUDIT TRAIL — FIPS 199 HIGH logging for all reads/writes/disclosures
--      (inherits strictest classification from medical subsystem).
--   5. ONE PAYMENT ADAPTER — Pay.gov integration consolidated to single point
--      (today: 4 separate Pay.gov integrations).
--   6. ONE NOTIFICATION/CORRESPONDENCE FABRIC — email/letter/portal-message
--      templates centralized (today: 4 disparate notification engines).
--   7. RBAC — role + permission model supports applicant, instructor, DPE,
--      AME, FSDO inspector, ACB analyst, CAMI physician, etc.
--
-- Schema organization (PostgreSQL schemas used as domains):
--   core      — identity, org, address, user/role/permission, reference
--   workflow  — cases, case history, signatures, workflow state
--   documents — unified document store + retention
--   payments  — Pay.gov adapter, fees, receipts
--   certification — certificate types, airmen certs, test results
--   medical   — medical applications, exams, SI cases (FIPS HIGH boundary)
--   aircraft  — aircraft records, ownership, liens, N-numbers
--   designee  — designee registry (consolidated DMS)
--   audit     — comprehensive audit + compliance logging
--   notify    — correspondence + notifications
--   integration — outbound/inbound hooks (TSA, FDA, Atlas Aviation, etc.)
--
-- FIPS 199: HIGH (inherits strictest from medical).
-- Retention: per-domain NARA schedules enforced at row level.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SCHEMAS
-- -----------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS workflow;
CREATE SCHEMA IF NOT EXISTS documents;
CREATE SCHEMA IF NOT EXISTS payments;
CREATE SCHEMA IF NOT EXISTS certification;
CREATE SCHEMA IF NOT EXISTS medical;
CREATE SCHEMA IF NOT EXISTS aircraft;
CREATE SCHEMA IF NOT EXISTS designee;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS notify;
CREATE SCHEMA IF NOT EXISTS integration;

-- =============================================================================
-- ENUMERATED TYPES (shared)
-- =============================================================================

CREATE TYPE core.person_type AS ENUM (
    'AIRMAN','APPLICANT','REGISTRANT','DESIGNEE','FAA_STAFF','FAA_CONTRACTOR','MEDICAL_APPLICANT'
);

CREATE TYPE core.identity_assurance_level AS ENUM ('IAL1','IAL2','IAL3');

CREATE TYPE core.entity_type AS ENUM (
    'INDIVIDUAL','PARTNERSHIP','CORPORATION','CO_OWNER','GOVERNMENT','LLC',
    'TRUST','NON_CITIZEN_CORP','NON_CITIZEN_COOWNER','SOLE_PROPRIETOR'
);

CREATE TYPE core.address_type AS ENUM ('MAILING','PHYSICAL','BUSINESS','RESIDENTIAL','ALTERNATE');

CREATE TYPE workflow.case_domain AS ENUM (
    'AIRCRAFT_REGISTRATION',
    'AIRMAN_CERTIFICATION',
    'MEDICAL_CERTIFICATION',
    'DESIGNEE_MANAGEMENT'
);

CREATE TYPE workflow.case_status AS ENUM (
    'DRAFT',
    'SUBMITTED',
    'RECOMMENDED',         -- by instructor/selecting officer
    'ACCEPTED_BY_REVIEWER',
    'IN_REVIEW',
    'ACTION_REQUIRED',
    'PENDING_APPROVAL',
    'APPROVED',
    'DENIED',
    'DEFERRED',            -- medical only
    'ISSUED',
    'CANCELLED',
    'EXPIRED',
    'CLOSED'
);

CREATE TYPE workflow.signature_status AS ENUM (
    'NOT_REQUIRED','PENDING','EXECUTED','DECLINED','VOIDED','EXPIRED'
);

CREATE TYPE documents.retention_schedule AS ENUM (
    'PERMANENT_N1_237_04_03',       -- Aircraft
    'AIRMEN_60Y_N1_237_06_001',     -- Airmen
    'MEDICAL_50Y_N1_237_05_005',    -- Medical
    'DESIGNEE_25Y_DAA_0237_2020_0013',
    'IACRA_TEMP_N1_237_09_14',
    'ENFORCEMENT_5Y_ORDER_1350_15C',
    'FOREIGN_LICENSE_CY_6MO'
);

CREATE TYPE payments.payment_status AS ENUM (
    'PENDING','SUBMITTED','COMPLETED','FAILED','CANCELLED','REFUNDED'
);

CREATE TYPE certification.certificate_type AS ENUM (
    'STUDENT_PILOT','RECREATIONAL','PRIVATE','COMMERCIAL','ATP',
    'CFI','SPORT_PILOT','REMOTE_PILOT','FLIGHT_ENGINEER',
    'AIRCRAFT_DISPATCHER','MECHANIC','REPAIRMAN',
    'FLIGHT_REVIEW','INSTRUMENT_PROFICIENCY_CHECK'
);

CREATE TYPE certification.cert_status AS ENUM (
    'ISSUED','RENEWED','EXPIRED','SUSPENDED','REVOKED',
    'SURRENDERED','DENIED','AWAITING_ISSUE','TEMPORARY'
);

CREATE TYPE medical.medical_class AS ENUM ('FIRST','SECOND','THIRD','REMOTE_PILOT');

CREATE TYPE medical.disposition AS ENUM ('ISSUE','DENY','DEFER','SI_AASI');

CREATE TYPE medical.si_condition AS ENUM (
    'CARDIAC','DIABETES','MENTAL_HEALTH','NEUROLOGICAL',
    'VISION','HEARING','SUBSTANCE_USE','OTHER'
);

CREATE TYPE medical.si_status AS ENUM (
    'PENDING_FAS','APPROVED','DENIED','EXPIRED','RENEWED','SURRENDERED'
);

CREATE TYPE aircraft.aircraft_status AS ENUM (
    'PENDING','ACTIVE','EXPIRED','CANCELLED','DEREGISTERED','SUSPENDED','REVOKED'
);

CREATE TYPE aircraft.lien_type AS ENUM (
    'MORTGAGE','CONDITIONAL_SALES_CONTRACT','SECURITY_AGREEMENT','LEASE'
);

CREATE TYPE designee.designee_type AS ENUM (
    'DPE','SAE','ADMIN_PE','DME','DPRE','DADE','TCE','APD',
    'DAR_T','DAR_F','DMIR','DER','AME','IA','ODA','ODAR','ACSEP','TCSEP','SFAR'
);

CREATE TYPE designee.designation_status AS ENUM (
    'APPLICANT','ACTIVE','SUSPENDED','TERMINATED','REINSTATED','EXPIRED'
);

CREATE TYPE notify.delivery_channel AS ENUM (
    'EMAIL','USPS_LETTER','PORTAL_MESSAGE','SMS','FAX'
);

CREATE TYPE notify.delivery_status AS ENUM (
    'QUEUED','SENT','BOUNCED','DELIVERED','READ','FAILED'
);

-- =============================================================================
-- CORE DOMAIN — Identity, Organization, Address, RBAC, Reference
-- =============================================================================

-- -----------------------------------------------------------------------------
-- COUNTRIES / STATES
-- -----------------------------------------------------------------------------

CREATE TABLE core.countries (
    country_code CHAR(2)      PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL
);
COMMENT ON TABLE core.countries IS 'ISO 3166-1 alpha-2 country reference.';

CREATE TABLE core.us_states (
    state_code CHAR(2)      PRIMARY KEY,
    state_name VARCHAR(100) NOT NULL
);

-- -----------------------------------------------------------------------------
-- PERSONS (golden record — resolves legacy FTN, Cert #, Applicant ID, MID, Designee #)
-- -----------------------------------------------------------------------------

CREATE TABLE core.persons (
    person_id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Federated identity
    ftn                      VARCHAR(12)   UNIQUE,       -- FAA Tracking Number (primary airman key)
    myaccess_subject_id      VARCHAR(255)  UNIQUE,
    login_gov_sub            VARCHAR(255)  UNIQUE,
    piv_card_dn              VARCHAR(512),               -- FAA staff X.500 DN
    -- Biographic
    first_name               VARCHAR(100)  NOT NULL,
    middle_name              VARCHAR(100),
    last_name                VARCHAR(100)  NOT NULL,
    name_suffix              VARCHAR(20),
    full_legal_name          VARCHAR(255)  GENERATED ALWAYS AS (
        TRIM(BOTH ' ' FROM (
            COALESCE(first_name,'') || ' ' ||
            COALESCE(middle_name || ' ','') ||
            COALESCE(last_name,'') ||
            COALESCE(' ' || name_suffix,'')
        ))
    ) STORED,
    other_names_used         TEXT,
    date_of_birth            DATE          NOT NULL,
    sex                      CHAR(1)       CHECK (sex IN ('M','F','U','X')),
    ssn_encrypted            BYTEA,                      -- AES-256 at rest (never a lookup key)
    ssn_last_4               CHAR(4),
    hair_color               VARCHAR(30),
    eye_color                VARCHAR(30),
    height_inches            SMALLINT,
    weight_lbs               SMALLINT,
    citizenship_country      CHAR(2)       REFERENCES core.countries(country_code),
    country_of_birth         CHAR(2)       REFERENCES core.countries(country_code),
    state_of_birth           CHAR(2)       REFERENCES core.us_states(state_code),
    city_of_birth            VARCHAR(100),
    -- Contact (primary)
    email_address            VARCHAR(255)  NOT NULL,
    phone_primary            VARCHAR(30),
    phone_secondary          VARCHAR(30),
    -- Identity proofing
    identity_assurance_level core.identity_assurance_level,
    identity_proofed_at      TIMESTAMPTZ,
    identity_proofing_method VARCHAR(50),
    -- Classification
    person_type              core.person_type NOT NULL,
    -- Legacy aliases (read-only; resolved via identifier_mappings)
    legacy_cert_number       VARCHAR(20),
    legacy_applicant_id      VARCHAR(20),
    legacy_designee_number   VARCHAR(20),
    legacy_mid               VARCHAR(20),
    -- Lifecycle
    created_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    deprecated_at            TIMESTAMPTZ,                -- set when merged into another record
    merged_into_person_id    UUID          REFERENCES core.persons(person_id)
);
CREATE INDEX idx_persons_ftn        ON core.persons(ftn);
CREATE INDEX idx_persons_myaccess   ON core.persons(myaccess_subject_id);
CREATE INDEX idx_persons_name       ON core.persons(last_name, first_name);
CREATE INDEX idx_persons_dob        ON core.persons(date_of_birth);
CREATE INDEX idx_persons_email      ON core.persons(email_address);
COMMENT ON TABLE  core.persons IS 'UNIFIED PERSON MASTER — single record per individual, resolving FTN, Cert #, Applicant ID, MID, Designee # aliases.';
COMMENT ON COLUMN core.persons.ssn_encrypted IS 'AES-256 encrypted per FIPS 199 HIGH; never a lookup key.';

CREATE TABLE core.identifier_mappings (
    mapping_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id          UUID         NOT NULL REFERENCES core.persons(person_id),
    identifier_type    VARCHAR(30)  NOT NULL CHECK (identifier_type IN
        ('FTN','CERTIFICATE_NUMBER','APPLICANT_ID','MID','DESIGNEE_NUMBER','LEGACY_SSN_HASH')),
    identifier_value   VARCHAR(100) NOT NULL,
    source_system      VARCHAR(30)  NOT NULL CHECK (source_system IN
        ('UNIFIED','CARES','CAIS','RMS','MSS','DMS','IACRA')),
    is_primary         BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (identifier_type, identifier_value, source_system)
);
CREATE INDEX idx_id_mappings_person ON core.identifier_mappings(person_id);
CREATE INDEX idx_id_mappings_value  ON core.identifier_mappings(identifier_value);

-- -----------------------------------------------------------------------------
-- ORGANIZATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE core.organizations (
    organization_id        UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_name      VARCHAR(255)     NOT NULL,
    organization_type      VARCHAR(50),                       -- flight_school, fbo, airline, dealer, repair_station
    entity_type            core.entity_type NOT NULL,
    legal_name             VARCHAR(255),
    ein                    VARCHAR(10)      UNIQUE,
    state_of_formation     CHAR(2)          REFERENCES core.us_states(state_code),
    country_of_formation   CHAR(2)          REFERENCES core.countries(country_code),
    primary_contact_person_id UUID          REFERENCES core.persons(person_id),
    business_email         VARCHAR(255),
    business_phone         VARCHAR(30),
    certificate_number     VARCHAR(50),                       -- e.g., repair station cert
    faa_approval_status    VARCHAR(30),
    -- Trust / non-citizen compliance
    is_trust               BOOLEAN          NOT NULL DEFAULT FALSE,
    trustee_person_id      UUID             REFERENCES core.persons(person_id),
    non_citizen_trustee_declaration BOOLEAN,
    intl_ops_declaration   BOOLEAN,
    primarily_used_in_us   BOOLEAN,
    flight_hour_records_location VARCHAR(500),
    created_at             TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_orgs_name ON core.organizations(organization_name);
CREATE INDEX idx_orgs_type ON core.organizations(organization_type);

-- -----------------------------------------------------------------------------
-- ADDRESSES
-- -----------------------------------------------------------------------------

CREATE TABLE core.addresses (
    address_id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id            UUID          REFERENCES core.persons(person_id),
    organization_id      UUID          REFERENCES core.organizations(organization_id),
    address_type         core.address_type NOT NULL,
    street_line_1        VARCHAR(255)  NOT NULL,
    street_line_2        VARCHAR(255),
    street_line_3        VARCHAR(255),
    city                 VARCHAR(100)  NOT NULL,
    state_code           CHAR(2)       REFERENCES core.us_states(state_code),
    province             VARCHAR(100),
    postal_code          VARCHAR(20),
    country_code         CHAR(2)       NOT NULL DEFAULT 'US' REFERENCES core.countries(country_code),
    location_description VARCHAR(500),
    is_po_box            BOOLEAN       NOT NULL DEFAULT FALSE,
    validated            BOOLEAN       NOT NULL DEFAULT FALSE,
    validation_service   VARCHAR(50),
    latitude             NUMERIC(10,8),
    longitude            NUMERIC(11,8),
    effective_from_date  DATE          NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date    DATE,
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_addr_owner CHECK (
        (person_id IS NOT NULL AND organization_id IS NULL)
        OR (person_id IS NULL AND organization_id IS NOT NULL)
    )
);
CREATE INDEX idx_addresses_person    ON core.addresses(person_id);
CREATE INDEX idx_addresses_org       ON core.addresses(organization_id);
CREATE INDEX idx_addresses_city_st   ON core.addresses(city, state_code);
CREATE INDEX idx_addresses_postal    ON core.addresses(postal_code);

-- -----------------------------------------------------------------------------
-- ENTITY PRINCIPALS (partners, officers, trustees, beneficiaries)
-- -----------------------------------------------------------------------------

CREATE TABLE core.entity_principals (
    principal_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID         NOT NULL REFERENCES core.organizations(organization_id) ON DELETE CASCADE,
    person_id           UUID         REFERENCES core.persons(person_id),
    principal_type      VARCHAR(30)  NOT NULL CHECK (principal_type IN
        ('PARTNER','OFFICER','MANAGING_MEMBER','TRUSTEE','BENEFICIARY','GOVT_CONTACT','PRINCIPAL')),
    title               VARCHAR(100),
    ownership_pct       NUMERIC(5,2) CHECK (ownership_pct IS NULL OR (ownership_pct > 0 AND ownership_pct <= 100)),
    citizenship_country CHAR(2)      REFERENCES core.countries(country_code),
    effective_from_date DATE         NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date   DATE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_principals_org    ON core.entity_principals(organization_id);
CREATE INDEX idx_principals_person ON core.entity_principals(person_id);

-- -----------------------------------------------------------------------------
-- RBAC — USERS / ROLES / PERMISSIONS
-- -----------------------------------------------------------------------------

CREATE TABLE core.users (
    user_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id            UUID         REFERENCES core.persons(person_id),
    myaccess_subject_id  VARCHAR(255) UNIQUE,
    login_gov_sub        VARCHAR(255) UNIQUE,
    piv_card_dn          VARCHAR(512) UNIQUE,
    username             VARCHAR(100) UNIQUE,
    email_address        VARCHAR(255) NOT NULL,
    user_type            VARCHAR(30)  NOT NULL CHECK (user_type IN
        ('FAA_EMPLOYEE','FAA_CONTRACTOR','DESIGNEE','PUBLIC_APPLICANT','SERVICE_ACCOUNT')),
    user_status          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE'
        CHECK (user_status IN ('ACTIVE','INACTIVE','SUSPENDED','LOCKED')),
    mfa_enabled          BOOLEAN      NOT NULL DEFAULT TRUE,
    first_login_at       TIMESTAMPTZ,
    last_login_at        TIMESTAMPTZ,
    last_login_ip        INET,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by_user_id   UUID         REFERENCES core.users(user_id)
);
CREATE INDEX idx_users_person ON core.users(person_id);
CREATE INDEX idx_users_email  ON core.users(email_address);

CREATE TABLE core.roles (
    role_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    role_code        VARCHAR(50)  UNIQUE NOT NULL,
    role_name        VARCHAR(100) NOT NULL,
    description      TEXT,
    domain_scope     workflow.case_domain,      -- null = cross-domain role
    is_system_role   BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE core.roles IS 'Role catalog: APPLICANT, INSTRUCTOR, DESIGNEE_DPE, AME, FSDO_INSPECTOR, ACB_ANALYST, CAMI_PHYSICIAN, etc.';

CREATE TABLE core.permissions (
    permission_id    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_code  VARCHAR(100) UNIQUE NOT NULL,
    resource_type    VARCHAR(50)  NOT NULL,
    action           VARCHAR(30)  NOT NULL CHECK (action IN ('CREATE','READ','UPDATE','DELETE','APPROVE','SUBMIT','EXPORT')),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE core.role_permissions (
    role_id          UUID         NOT NULL REFERENCES core.roles(role_id),
    permission_id    UUID         NOT NULL REFERENCES core.permissions(permission_id),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE core.user_role_assignments (
    assignment_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID         NOT NULL REFERENCES core.users(user_id),
    role_id                 UUID         NOT NULL REFERENCES core.roles(role_id),
    office_id               UUID,          -- scoped role (e.g., FSDO inspector at SEA)
    effective_from_date     DATE         NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date       DATE,
    assigned_by_user_id     UUID         REFERENCES core.users(user_id),
    assigned_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, role_id, effective_from_date)
);
CREATE INDEX idx_user_roles_user ON core.user_role_assignments(user_id);

-- -----------------------------------------------------------------------------
-- REFERENCE DATA (shared by all domains)
-- -----------------------------------------------------------------------------

CREATE TABLE core.offices (
    office_id            UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    office_code          VARCHAR(20)      UNIQUE NOT NULL,
    office_name          VARCHAR(255)     NOT NULL,
    office_type          VARCHAR(20)      NOT NULL CHECK (office_type IN ('FSDO','IFO','RHQ','AEG','ACO','CAMI','AAM')),
    responsible_service  VARCHAR(20)      NOT NULL CHECK (responsible_service IN ('AFS','AIR','AAM','REG','ACB')),
    region               VARCHAR(100),
    state_code           CHAR(2)          REFERENCES core.us_states(state_code),
    address_id           UUID             REFERENCES core.addresses(address_id),
    phone                VARCHAR(30),
    email                VARCHAR(255),
    is_active            BOOLEAN          NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

ALTER TABLE core.user_role_assignments
    ADD CONSTRAINT fk_ura_office FOREIGN KEY (office_id) REFERENCES core.offices(office_id);

CREATE TABLE core.aircraft_manufacturers (
    manufacturer_code VARCHAR(10)  PRIMARY KEY,
    manufacturer_name VARCHAR(200) NOT NULL,
    country_code      CHAR(2),
    active            BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE core.aircraft_models (
    mfr_mdl_code       VARCHAR(20)  PRIMARY KEY,
    manufacturer_code  VARCHAR(10)  NOT NULL REFERENCES core.aircraft_manufacturers(manufacturer_code),
    model_name         VARCHAR(200) NOT NULL,
    aircraft_category  VARCHAR(50)  NOT NULL,
    certification_basis VARCHAR(50),
    typical_engine_count SMALLINT,
    type_rating_required BOOLEAN    NOT NULL DEFAULT FALSE,
    active             BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE core.engine_manufacturers (
    engine_mfr_code VARCHAR(10)  PRIMARY KEY,
    engine_mfr_name VARCHAR(200) NOT NULL,
    country_code    CHAR(2),
    active          BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE core.engine_models (
    eng_mfr_mdl_code VARCHAR(20)  PRIMARY KEY,
    engine_mfr_code  VARCHAR(10)  NOT NULL REFERENCES core.engine_manufacturers(engine_mfr_code),
    engine_model_name VARCHAR(200) NOT NULL,
    engine_type      VARCHAR(50)  NOT NULL,
    horsepower       INTEGER,
    thrust_pounds    INTEGER,
    active           BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE core.system_classification (
    system_id           VARCHAR(30)  PRIMARY KEY,
    system_name         VARCHAR(255) NOT NULL,
    fips_199_category   VARCHAR(10)  NOT NULL CHECK (fips_199_category IN ('LOW','MODERATE','HIGH')),
    sorn_scope          VARCHAR(50),   -- DOT/FAA 801, 847, 856, 830
    nara_retention_default VARCHAR(50),
    ato_date            DATE,
    ato_number          VARCHAR(100),
    annual_review_date  DATE
);

-- =============================================================================
-- WORKFLOW DOMAIN — Generic case + state machine
-- =============================================================================

CREATE TABLE workflow.case_types (
    case_type_code        VARCHAR(50)  PRIMARY KEY,
    case_type_name        VARCHAR(200) NOT NULL,
    case_domain           workflow.case_domain NOT NULL,
    form_identifier       VARCHAR(50),                -- AC 8050-1, 8710-1, 8500-8, etc.
    omb_control_number    VARCHAR(20),
    description           TEXT,
    signature_required    BOOLEAN      NOT NULL DEFAULT FALSE,
    payment_required      BOOLEAN      NOT NULL DEFAULT FALSE,
    active                BOOLEAN      NOT NULL DEFAULT TRUE
);
COMMENT ON TABLE workflow.case_types IS 'Consolidated catalog — 50+ case types across RMS/IACRA/MSS/DMS.';

CREATE TABLE workflow.cases (
    case_id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_reference_number   VARCHAR(30)  UNIQUE NOT NULL,
    case_type_code          VARCHAR(50)  NOT NULL REFERENCES workflow.case_types(case_type_code),
    case_domain             workflow.case_domain NOT NULL,
    status                  workflow.case_status NOT NULL DEFAULT 'DRAFT',
    workflow_stage          SMALLINT     NOT NULL DEFAULT 1,
    -- Participants
    applicant_person_id     UUID         REFERENCES core.persons(person_id),
    applicant_organization_id UUID       REFERENCES core.organizations(organization_id),
    assigned_to_user_id     UUID         REFERENCES core.users(user_id),
    responsible_office_id   UUID         REFERENCES core.offices(office_id),
    -- Domain-specific foreign keys (nullable)
    aircraft_id             UUID,
    airman_cert_id          UUID,
    medical_application_id  UUID,
    designation_id          UUID,
    -- Attachments & payment
    document_package_id     UUID,
    payment_id              UUID,
    -- Signature
    signature_envelope_id   VARCHAR(255),
    signature_status        workflow.signature_status NOT NULL DEFAULT 'NOT_REQUIRED',
    -- Timestamps
    opened_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    submitted_at            TIMESTAMPTZ,
    decided_at              TIMESTAMPTZ,
    closed_at               TIMESTAMPTZ,
    deadline_at             TIMESTAMPTZ,   -- SLA / regulatory deadline
    -- Audit
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by_user_id      UUID         REFERENCES core.users(user_id)
);
CREATE INDEX idx_cases_applicant ON workflow.cases(applicant_person_id);
CREATE INDEX idx_cases_domain    ON workflow.cases(case_domain);
CREATE INDEX idx_cases_status    ON workflow.cases(status);
CREATE INDEX idx_cases_office    ON workflow.cases(responsible_office_id);
CREATE INDEX idx_cases_assignee  ON workflow.cases(assigned_to_user_id);
CREATE INDEX idx_cases_deadline  ON workflow.cases(deadline_at);
COMMENT ON TABLE workflow.cases IS 'GENERIC CASE — replaces 4 bespoke workflows (aircraft, airman, medical, designee).';

CREATE TABLE workflow.case_history (
    history_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id               UUID         NOT NULL REFERENCES workflow.cases(case_id) ON DELETE CASCADE,
    status_from           workflow.case_status,
    status_to             workflow.case_status NOT NULL,
    transition_timestamp  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    transition_user_id    UUID         REFERENCES core.users(user_id),
    transition_reason     VARCHAR(500),
    ip_address            INET,
    notes                 TEXT
);
CREATE INDEX idx_case_history_case ON workflow.case_history(case_id);

CREATE TABLE workflow.case_participants (
    participant_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id             UUID         NOT NULL REFERENCES workflow.cases(case_id) ON DELETE CASCADE,
    user_id             UUID         REFERENCES core.users(user_id),
    person_id           UUID         REFERENCES core.persons(person_id),
    participant_role    VARCHAR(50)  NOT NULL,   -- APPLICANT, RECOMMENDING_INSTRUCTOR, DESIGNEE, AME, ASI, REVIEWER
    added_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    removed_at          TIMESTAMPTZ
);
CREATE INDEX idx_case_participants_case ON workflow.case_participants(case_id);
CREATE INDEX idx_case_participants_user ON workflow.case_participants(user_id);

-- =============================================================================
-- DOCUMENTS DOMAIN — Unified store replacing 4 TIFF silos
-- =============================================================================

CREATE TABLE documents.document_type_taxonomy (
    doc_type_id          VARCHAR(50)  PRIMARY KEY,
    doc_type_name        VARCHAR(255) NOT NULL,
    document_class       VARCHAR(50)  NOT NULL,          -- legal_deed, medical_record, exam_result, form_submission
    category_group       VARCHAR(100),
    applicable_domains   workflow.case_domain[],
    default_retention    documents.retention_schedule NOT NULL,
    is_pii               BOOLEAN      NOT NULL DEFAULT FALSE,
    is_phi               BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE documents.documents (
    document_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    doc_type_id            VARCHAR(50)  NOT NULL REFERENCES documents.document_type_taxonomy(doc_type_id),
    document_title         VARCHAR(500),
    document_date          DATE,                        -- date of event (not upload)
    cloud_storage_uri      VARCHAR(2048) NOT NULL,
    file_format            VARCHAR(20)  NOT NULL,
    file_size_bytes        BIGINT       NOT NULL CHECK (file_size_bytes > 0),
    file_hash_sha256       CHAR(64)     NOT NULL,
    page_count             INTEGER,
    -- Intelligence layer
    ocr_applied            BOOLEAN      NOT NULL DEFAULT FALSE,
    ocr_text               TEXT,
    extracted_entities     JSONB,
    document_fingerprint   VARCHAR(64),                  -- perceptual hash for dedup
    -- Security
    virus_scanned          BOOLEAN      NOT NULL DEFAULT FALSE,
    virus_scan_timestamp   TIMESTAMPTZ,
    encryption_algorithm   VARCHAR(30)  DEFAULT 'AES256',
    -- Retention
    retention_schedule     documents.retention_schedule NOT NULL,
    disposal_scheduled_date DATE,
    disposal_executed_date DATE,
    legal_hold_flag        BOOLEAN      NOT NULL DEFAULT FALSE,
    legal_hold_reason      VARCHAR(500),
    -- Signature
    docusign_envelope_id   VARCHAR(255),
    docusign_status        VARCHAR(30),
    signer_user_id         UUID         REFERENCES core.users(user_id),
    signed_at              TIMESTAMPTZ,
    -- Supersession (corrections)
    supersedes_document_id UUID         REFERENCES documents.documents(document_id),
    correction_reason      TEXT,
    -- Audit
    uploaded_by_user_id    UUID         REFERENCES core.users(user_id),
    uploaded_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_docs_case       ON documents.documents(case_id);
CREATE INDEX idx_docs_type       ON documents.documents(doc_type_id);
CREATE INDEX idx_docs_hash       ON documents.documents(file_hash_sha256);
CREATE INDEX idx_docs_retention  ON documents.documents(disposal_scheduled_date) WHERE disposal_executed_date IS NULL;

ALTER TABLE workflow.cases ADD CONSTRAINT fk_case_document_package
    FOREIGN KEY (document_package_id) REFERENCES documents.documents(document_id);

CREATE TABLE documents.document_annotations (
    annotation_id       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id         UUID         NOT NULL REFERENCES documents.documents(document_id) ON DELETE CASCADE,
    annotation_type     VARCHAR(50) NOT NULL,            -- REGISTRATION, RECORDATION, CORRECTION, EXAMINER_NOTE
    annotation_date     TIMESTAMPTZ  NOT NULL,
    annotation_text     TEXT         NOT NULL,
    created_by_user_id  UUID         REFERENCES core.users(user_id),
    supersedes_annotation_id UUID    REFERENCES documents.document_annotations(annotation_id),
    is_immutable        BOOLEAN      NOT NULL DEFAULT TRUE
);

-- =============================================================================
-- PAYMENTS DOMAIN — Single Pay.gov adapter
-- =============================================================================

CREATE TABLE payments.fee_schedule (
    fee_code             VARCHAR(50)  PRIMARY KEY,
    fee_description      VARCHAR(255) NOT NULL,
    amount_cents         INTEGER      NOT NULL,
    case_type_code       VARCHAR(50)  REFERENCES workflow.case_types(case_type_code),
    effective_from_date  DATE         NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date    DATE
);

CREATE TABLE payments.payments (
    payment_id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                  UUID         NOT NULL REFERENCES workflow.cases(case_id),
    fee_code                 VARCHAR(50)  REFERENCES payments.fee_schedule(fee_code),
    originating_system       VARCHAR(30)  NOT NULL DEFAULT 'UNIFIED',
    amount_cents             INTEGER      NOT NULL CHECK (amount_cents >= 0),
    currency_code            CHAR(3)      NOT NULL DEFAULT 'USD',
    service_description      VARCHAR(255),
    pay_gov_transaction_id   VARCHAR(100) UNIQUE,
    pay_gov_agency_tracking_id VARCHAR(100),
    payment_method           VARCHAR(30)  CHECK (payment_method IN ('CREDIT_CARD','ACH','CHECK','MONEY_ORDER')),
    payment_status           payments.payment_status NOT NULL DEFAULT 'PENDING',
    submitted_at             TIMESTAMPTZ,
    confirmed_at             TIMESTAMPTZ,
    confirmation_token       VARCHAR(255),
    payer_person_id          UUID         REFERENCES core.persons(person_id),
    payer_email              VARCHAR(255),
    refund_of_payment_id     UUID         REFERENCES payments.payments(payment_id),
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_payments_case    ON payments.payments(case_id);
CREATE INDEX idx_payments_status  ON payments.payments(payment_status);
CREATE INDEX idx_payments_tx_id   ON payments.payments(pay_gov_transaction_id);

ALTER TABLE workflow.cases ADD CONSTRAINT fk_case_payment
    FOREIGN KEY (payment_id) REFERENCES payments.payments(payment_id);

CREATE TABLE payments.receipts (
    receipt_id       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id       UUID         NOT NULL REFERENCES payments.payments(payment_id),
    receipt_number   VARCHAR(50)  UNIQUE NOT NULL,
    issue_date       DATE         NOT NULL,
    description      TEXT,
    accounting_code  VARCHAR(50),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- AIRCRAFT DOMAIN — consolidated aircraft registration
-- =============================================================================

CREATE TABLE aircraft.aircraft (
    aircraft_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    n_number               VARCHAR(6)   NOT NULL UNIQUE
                               CHECK (n_number ~ '^N[A-Z0-9]{1,5}$'),
    serial_number          VARCHAR(50)  NOT NULL,
    mfr_mdl_code           VARCHAR(20)  REFERENCES core.aircraft_models(mfr_mdl_code),
    eng_mfr_mdl_code       VARCHAR(20)  REFERENCES core.engine_models(eng_mfr_mdl_code),
    year_mfr               SMALLINT     CHECK (year_mfr BETWEEN 1900 AND 2100),
    num_engines            SMALLINT,
    num_seats              SMALLINT,
    aircraft_category      VARCHAR(50)  NOT NULL,
    aircraft_class         VARCHAR(50),
    type_aircraft          VARCHAR(50),
    type_engine            VARCHAR(50),
    mode_s_code_hex        CHAR(6)      UNIQUE CHECK (mode_s_code_hex ~ '^[0-9A-F]{6}$'),
    airworthiness_cert_type VARCHAR(50),
    registration_type      core.entity_type NOT NULL,
    registration_status    aircraft.aircraft_status NOT NULL DEFAULT 'PENDING',
    registration_issue_date DATE,
    registration_expiration_date DATE,
    last_action_date       DATE,
    import_country         CHAR(2) REFERENCES core.countries(country_code),
    is_dealer_aircraft     BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_aircraft_serial      ON aircraft.aircraft(serial_number);
CREATE INDEX idx_aircraft_status      ON aircraft.aircraft(registration_status);
CREATE INDEX idx_aircraft_expiration  ON aircraft.aircraft(registration_expiration_date);

ALTER TABLE workflow.cases ADD CONSTRAINT fk_case_aircraft
    FOREIGN KEY (aircraft_id) REFERENCES aircraft.aircraft(aircraft_id);

CREATE TABLE aircraft.n_number_reservations (
    reservation_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    n_number               VARCHAR(6)   NOT NULL UNIQUE,
    requestor_person_id    UUID         REFERENCES core.persons(person_id),
    requestor_organization_id UUID      REFERENCES core.organizations(organization_id),
    reservation_channel    VARCHAR(20)  NOT NULL,
    reservation_date       DATE         NOT NULL DEFAULT CURRENT_DATE,
    expiration_date        DATE         NOT NULL,
    status                 VARCHAR(20)  NOT NULL DEFAULT 'RESERVED',
    renewable              BOOLEAN      NOT NULL DEFAULT TRUE,
    assigned_aircraft_id   UUID         REFERENCES aircraft.aircraft(aircraft_id),
    special_request        BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE aircraft.ownership (
    ownership_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    aircraft_id         UUID         NOT NULL REFERENCES aircraft.aircraft(aircraft_id) ON DELETE CASCADE,
    person_id           UUID         REFERENCES core.persons(person_id),
    organization_id     UUID         REFERENCES core.organizations(organization_id),
    ownership_start_date DATE        NOT NULL,
    ownership_end_date   DATE,
    ownership_share_pct  NUMERIC(5,2),
    signed_application   BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_ownership_owner CHECK (
        (person_id IS NOT NULL AND organization_id IS NULL)
        OR (person_id IS NULL AND organization_id IS NOT NULL)
    )
);
CREATE INDEX idx_ownership_aircraft ON aircraft.ownership(aircraft_id);
CREATE INDEX idx_ownership_person   ON aircraft.ownership(person_id);
CREATE INDEX idx_ownership_org      ON aircraft.ownership(organization_id);
CREATE UNIQUE INDEX idx_ownership_current
    ON aircraft.ownership(aircraft_id, COALESCE(person_id::text, organization_id::text))
    WHERE ownership_end_date IS NULL;

CREATE TABLE aircraft.ownership_transfers (
    transfer_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    aircraft_id            UUID         NOT NULL REFERENCES aircraft.aircraft(aircraft_id),
    previous_owner_person_id UUID       REFERENCES core.persons(person_id),
    previous_owner_org_id  UUID         REFERENCES core.organizations(organization_id),
    new_owner_person_id    UUID         REFERENCES core.persons(person_id),
    new_owner_org_id       UUID         REFERENCES core.organizations(organization_id),
    transfer_type          VARCHAR(30)  NOT NULL,
    receipt_date           TIMESTAMPTZ  NOT NULL,
    recorded_date          TIMESTAMPTZ,
    recording_fee_payment_id UUID       REFERENCES payments.payments(payment_id),
    evidence_document_id   UUID         REFERENCES documents.documents(document_id),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_transfers_aircraft ON aircraft.ownership_transfers(aircraft_id);
COMMENT ON COLUMN aircraft.ownership_transfers.receipt_date IS '49 USC 44107 priority timestamp.';

CREATE TABLE aircraft.security_interests (
    lien_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    aircraft_id            UUID         NOT NULL REFERENCES aircraft.aircraft(aircraft_id),
    lien_type              aircraft.lien_type NOT NULL,
    lien_holder_name       VARCHAR(255) NOT NULL,
    lien_holder_address_id UUID         REFERENCES core.addresses(address_id),
    amount                 NUMERIC(14,2),
    filing_date            TIMESTAMPTZ  NOT NULL,
    priority_rank          INTEGER,
    expiration_date        DATE,
    is_released            BOOLEAN      NOT NULL DEFAULT FALSE,
    discharge_date         DATE,
    instrument_document_id UUID         REFERENCES documents.documents(document_id),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE aircraft.dealer_registrations (
    dealer_registration_id UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    dealer_number          VARCHAR(20)  UNIQUE NOT NULL,
    dealer_organization_id UUID         NOT NULL REFERENCES core.organizations(organization_id),
    issue_date             DATE         NOT NULL,
    expiration_date        DATE         NOT NULL,
    status                 VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE aircraft.export_certificates (
    export_cert_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id               UUID         REFERENCES workflow.cases(case_id),
    aircraft_id           UUID         NOT NULL REFERENCES aircraft.aircraft(aircraft_id),
    destination_country   CHAR(2)      NOT NULL REFERENCES core.countries(country_code),
    icao_annex_7_cert     BOOLEAN      NOT NULL DEFAULT TRUE,
    issue_date            DATE         NOT NULL,
    validity_days         INTEGER      NOT NULL DEFAULT 60,
    priority_processing   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- CERTIFICATION DOMAIN — Airman certificates, ratings, tests
-- =============================================================================

CREATE TABLE certification.certificate_type_reference (
    cert_type_id          SERIAL       PRIMARY KEY,
    certificate_type      certification.certificate_type UNIQUE NOT NULL,
    minimum_age           SMALLINT,
    requires_medical      BOOLEAN      NOT NULL DEFAULT FALSE,
    requires_knowledge_test BOOLEAN    NOT NULL DEFAULT FALSE,
    requires_practical_test BOOLEAN    NOT NULL DEFAULT FALSE,
    category_class_applicable BOOLEAN  NOT NULL DEFAULT TRUE,
    type_rating_applicable BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE TABLE certification.test_codes (
    test_code          VARCHAR(10)  PRIMARY KEY,
    test_name          VARCHAR(200) NOT NULL,
    valid_certificates certification.certificate_type[],
    expiration_months  SMALLINT     NOT NULL DEFAULT 24,
    is_active          BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE certification.airman_certificates (
    certificate_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id                UUID         NOT NULL REFERENCES core.persons(person_id),
    case_id                  UUID         REFERENCES workflow.cases(case_id),
    certificate_number       VARCHAR(20)  UNIQUE,
    certificate_type         certification.certificate_type NOT NULL,
    certificate_class        VARCHAR(30),
    certificate_level        VARCHAR(30),
    ratings                  TEXT[],
    limitations              TEXT[],
    issue_date               DATE         NOT NULL,
    expiration_date          DATE,
    status                   certification.cert_status NOT NULL DEFAULT 'ISSUED',
    temporary_expiration_date DATE,                         -- 120-day temp cert
    superseded_by_cert_id    UUID         REFERENCES certification.airman_certificates(certificate_id),
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_airman_certs_person  ON certification.airman_certificates(person_id);
CREATE INDEX idx_airman_certs_status  ON certification.airman_certificates(status);

ALTER TABLE workflow.cases ADD CONSTRAINT fk_case_airman_cert
    FOREIGN KEY (airman_cert_id) REFERENCES certification.airman_certificates(certificate_id);

CREATE TABLE certification.knowledge_tests (
    test_result_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id             UUID         NOT NULL REFERENCES core.persons(person_id),
    case_id               UUID         REFERENCES workflow.cases(case_id),
    test_code             VARCHAR(10)  REFERENCES certification.test_codes(test_code),
    exam_title            VARCHAR(200),
    exam_id_external      VARCHAR(50),
    exam_date             DATE         NOT NULL,
    test_site             VARCHAR(100),
    score                 SMALLINT,
    grade                 VARCHAR(10),
    number_of_attempts    SMALLINT,
    expiration_date       DATE,
    is_expired            BOOLEAN      GENERATED ALWAYS AS (expiration_date < CURRENT_DATE) STORED,
    missed_subject_areas  TEXT,
    source_system         VARCHAR(30)  DEFAULT 'ATLAS_AVIATION',
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_knowledge_person ON certification.knowledge_tests(person_id);
CREATE INDEX idx_knowledge_expiry ON certification.knowledge_tests(expiration_date);

CREATE TABLE certification.practical_tests (
    practical_test_id       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                 UUID         NOT NULL REFERENCES workflow.cases(case_id),
    person_id               UUID         NOT NULL REFERENCES core.persons(person_id),
    designee_id             UUID,                         -- FK set below
    test_date               DATE,
    test_location           VARCHAR(200),
    airport_id              VARCHAR(10),
    oral_duration_hours     NUMERIC(4,2),
    practical_duration_hours NUMERIC(4,2),
    outcome                 VARCHAR(20) CHECK (outcome IN ('APPROVE','DISAPPROVE','DISCONTINUE','DELETE')),
    outcome_date            TIMESTAMPTZ,
    failure_reason_code     VARCHAR(50),
    failure_reason_narrative TEXT,
    areas_of_operation_failed JSONB,
    limitations_added       JSONB,
    co_signature_date       TIMESTAMPTZ,
    co_digital_signature_token VARCHAR(255),
    test_aircraft_1_n_number VARCHAR(6),
    test_aircraft_1_mfr_mdl VARCHAR(20),
    test_aircraft_2_n_number VARCHAR(6),
    test_aircraft_2_mfr_mdl VARCHAR(20),
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE certification.pilot_time_records (
    pilot_time_record_id    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                 UUID         NOT NULL REFERENCES workflow.cases(case_id),
    person_id               UUID         NOT NULL REFERENCES core.persons(person_id),
    aircraft_sequence       SMALLINT     NOT NULL DEFAULT 1,
    aircraft_mfr_mdl_code   VARCHAR(20)  REFERENCES core.aircraft_models(mfr_mdl_code),
    aircraft_make_model     VARCHAR(200),
    aircraft_category_class VARCHAR(50),
    total_hours             NUMERIC(6,1) NOT NULL,
    pic_hours               NUMERIC(6,1),
    sic_hours               NUMERIC(6,1),
    instrument_hours        NUMERIC(6,1),
    night_hours             NUMERIC(6,1),
    cross_country_hours     NUMERIC(6,1),
    simulator_device_used   BOOLEAN      NOT NULL DEFAULT FALSE,
    simulator_device_type   VARCHAR(100),
    simulator_hours         NUMERIC(6,1),
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE certification.recommending_endorsements (
    endorsement_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                 UUID         NOT NULL REFERENCES workflow.cases(case_id),
    instructor_user_id      UUID         NOT NULL REFERENCES core.users(user_id),
    instructor_person_id    UUID         NOT NULL REFERENCES core.persons(person_id),
    instructor_cert_number  VARCHAR(20),
    checklist_completed     BOOLEAN      NOT NULL DEFAULT FALSE,
    checklist_json          JSONB,
    endorsement_date        TIMESTAMPTZ,
    digital_signature       VARCHAR(255),
    return_reason           TEXT,
    forwarded_date          TIMESTAMPTZ,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE certification.tsa_vetting (
    vetting_id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id              UUID         NOT NULL REFERENCES core.persons(person_id),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    vetting_required       BOOLEAN      NOT NULL DEFAULT FALSE,
    submission_date        TIMESTAMPTZ,
    status                 VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    approval_date          DATE,
    tsa_reference_number   VARCHAR(50),
    denial_reason          TEXT,
    expiration_date        DATE,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE certification.enforcement_actions (
    enforcement_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id              UUID         NOT NULL REFERENCES core.persons(person_id),
    eis_case_id            VARCHAR(50),
    action_type            VARCHAR(30)  NOT NULL,
    action_date            DATE         NOT NULL,
    regulatory_citation    VARCHAR(200),
    duration_days          INTEGER,
    penalty_amount         NUMERIC(12,2),
    case_status            VARCHAR(30)  NOT NULL DEFAULT 'OPEN',
    case_closed_date       DATE,
    retention_destroy_date DATE GENERATED ALWAYS AS (case_closed_date + INTERVAL '5 years') STORED,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- MEDICAL DOMAIN (FIPS HIGH boundary)
-- =============================================================================

CREATE TABLE medical.disease_condition_codes (
    condition_code            VARCHAR(20)  PRIMARY KEY,
    icd_10_code               VARCHAR(10),
    condition_name            VARCHAR(255) NOT NULL,
    is_part_67_disqualifying  BOOLEAN      NOT NULL DEFAULT FALSE,
    applicable_classes        medical.medical_class[],
    requires_si               BOOLEAN      NOT NULL DEFAULT FALSE,
    si_category               medical.si_condition
);

CREATE TABLE medical.medications (
    medication_id         BIGSERIAL    PRIMARY KEY,
    medication_name       VARCHAR(255) NOT NULL,
    generic_name          VARCHAR(255),
    ndc_code              VARCHAR(20),
    is_contraindicated    BOOLEAN      NOT NULL DEFAULT FALSE,
    applicable_classes    medical.medical_class[]
);

CREATE TABLE medical.medical_applications (
    medical_application_id UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id              UUID         NOT NULL REFERENCES core.persons(person_id),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    confirmation_number    VARCHAR(20)  UNIQUE,
    mid                    UUID         UNIQUE,
    class_applied          medical.medical_class NOT NULL,
    submitted_at           TIMESTAMPTZ,
    expires_at             TIMESTAMPTZ,
    imported_at            TIMESTAMPTZ,
    privacy_act_accepted   BOOLEAN      NOT NULL DEFAULT FALSE,
    -- Form 8500-8 payload
    prior_cert_history     JSONB,
    occupation             VARCHAR(200),
    employer               VARCHAR(200),
    total_pilot_hours      NUMERIC(8,1),
    pilot_hours_6mo        NUMERIC(8,1),
    current_medications    JSONB,
    item_18_conditions     JSONB,
    health_visits_3yr      JSONB,
    convictions            JSONB,
    drug_alcohol_driving   JSONB,
    non_driving_drug_alcohol JSONB,
    disability_benefits    BOOLEAN,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_medapps_person ON medical.medical_applications(person_id);

ALTER TABLE workflow.cases ADD CONSTRAINT fk_case_medical
    FOREIGN KEY (medical_application_id) REFERENCES medical.medical_applications(medical_application_id);

CREATE TABLE medical.exams (
    exam_id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    medical_application_id   UUID         REFERENCES medical.medical_applications(medical_application_id),
    person_id                UUID         NOT NULL REFERENCES core.persons(person_id),
    ame_designee_id          UUID,                              -- FK set below
    case_id                  UUID         REFERENCES workflow.cases(case_id),
    exam_date                DATE         NOT NULL,
    submission_deadline      DATE GENERATED ALWAYS AS (exam_date + INTERVAL '14 days') STORED,
    transmitted_at           TIMESTAMPTZ,
    disposition              medical.disposition,
    disqualifying_condition_code VARCHAR(50),
    pi_number                VARCHAR(30),
    locked                   BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_exams_person ON medical.exams(person_id);
CREATE INDEX idx_exams_date   ON medical.exams(exam_date);

CREATE TABLE medical.exam_findings (
    finding_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id               UUID NOT NULL REFERENCES medical.exams(exam_id) ON DELETE CASCADE,
    category              VARCHAR(50) NOT NULL,   -- VITALS, VISION, HEARING, URINALYSIS, PHYSICAL, ECG
    system_item_num       SMALLINT,
    system_name           VARCHAR(100),
    finding_status        VARCHAR(20),
    finding_data          JSONB,                  -- category-specific structured data
    narrative             TEXT,
    examined_at           TIMESTAMPTZ
);
CREATE INDEX idx_findings_exam ON medical.exam_findings(exam_id);

CREATE TABLE medical.medical_certificates (
    medical_cert_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id               UUID         NOT NULL REFERENCES core.persons(person_id),
    exam_id                 UUID         REFERENCES medical.exams(exam_id),
    certificate_number      VARCHAR(30),
    class                   medical.medical_class NOT NULL,
    issue_date              DATE         NOT NULL,
    expiration_date         DATE,
    limitations             JSONB,
    special_issuance        BOOLEAN      NOT NULL DEFAULT FALSE,
    status                  VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_medcerts_person ON medical.medical_certificates(person_id);

CREATE TABLE medical.special_issuance_cases (
    si_case_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id             UUID         NOT NULL REFERENCES core.persons(person_id),
    exam_id               UUID         REFERENCES medical.exams(exam_id),
    si_condition          medical.si_condition NOT NULL,
    authorization_number  VARCHAR(50),
    status                medical.si_status NOT NULL DEFAULT 'PENDING_FAS',
    authorization_letter_date DATE,
    follow_up_requirements JSONB,
    follow_up_next_due    DATE,
    monitoring_schedule   VARCHAR(30),
    status_history        JSONB,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_si_person    ON medical.special_issuance_cases(person_id);
CREATE INDEX idx_si_condition ON medical.special_issuance_cases(si_condition);
CREATE INDEX idx_si_followup  ON medical.special_issuance_cases(follow_up_next_due);

CREATE TABLE medical.deferred_cases (
    deferred_case_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id               UUID         NOT NULL REFERENCES medical.exams(exam_id),
    person_id             UUID         NOT NULL REFERENCES core.persons(person_id),
    deferral_date         DATE         NOT NULL,
    deferral_reason_code  VARCHAR(50),
    documentation_requested JSONB,
    response_deadline     DATE,
    status                VARCHAR(30),
    resolved_at           TIMESTAMPTZ,
    resolved_disposition  medical.disposition,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE medical.denied_cases (
    denied_case_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id                  UUID         NOT NULL REFERENCES medical.exams(exam_id),
    person_id                UUID         NOT NULL REFERENCES core.persons(person_id),
    denial_date              DATE         NOT NULL,
    disqualifying_condition_code VARCHAR(50),
    disqualifying_condition_narrative TEXT,
    appeal_rights_letter_date DATE,
    appeal_filed             BOOLEAN      NOT NULL DEFAULT FALSE,
    appeal_filed_date        DATE,
    status                   VARCHAR(30)  NOT NULL DEFAULT 'INITIAL_DENIAL',
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- CAMI research (de-identified)
CREATE TABLE medical.research_cases (
    research_case_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_hash           VARCHAR(64),
    exam_id               UUID         REFERENCES medical.exams(exam_id),
    research_cohort       VARCHAR(100),
    age_bracket           VARCHAR(20),
    certificate_class     medical.medical_class,
    findings_summary      JSONB,
    disposition_outcome   medical.disposition,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- DESIGNEE DOMAIN
-- =============================================================================

CREATE TABLE designee.designee_types (
    designee_type_code   designee.designee_type PRIMARY KEY,
    designee_full_name   VARCHAR(255) NOT NULL,
    responsible_service  VARCHAR(20)  NOT NULL,
    regulatory_reference VARCHAR(100) NOT NULL,
    authority_scope      TEXT,
    renewal_cycle_months SMALLINT     NOT NULL DEFAULT 12,
    max_type_ratings_per_auth SMALLINT
);

CREATE TABLE designee.function_codes (
    function_code VARCHAR(10)  PRIMARY KEY,
    description   VARCHAR(500) NOT NULL,
    applicable_designee_types designee.designee_type[] NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE designee.designees (
    designee_id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id                   UUID         NOT NULL UNIQUE REFERENCES core.persons(person_id),
    designee_number             VARCHAR(9)   UNIQUE NOT NULL,
    medical_license_number      VARCHAR(50),
    medical_license_issuing_state CHAR(2),
    npi_number                  VARCHAR(20),
    references_json             JSONB,
    employer_organization_id    UUID         REFERENCES core.organizations(organization_id),
    last_validation_date        DATE,
    photograph_document_id      UUID         REFERENCES documents.documents(document_id),
    created_at                  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_designees_number ON designee.designees(designee_number);

-- FK back-reference for practical tests
ALTER TABLE certification.practical_tests
    ADD CONSTRAINT fk_practical_designee
    FOREIGN KEY (designee_id) REFERENCES designee.designees(designee_id);

-- FK back-reference for medical exams (AME)
ALTER TABLE medical.exams
    ADD CONSTRAINT fk_medical_exam_ame
    FOREIGN KEY (ame_designee_id) REFERENCES designee.designees(designee_id);

CREATE TABLE designee.designations (
    designation_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designee_id            UUID         NOT NULL REFERENCES designee.designees(designee_id),
    designee_type_code     designee.designee_type NOT NULL,
    status                 designee.designation_status NOT NULL DEFAULT 'APPLICANT',
    effective_date         DATE,
    expiration_date        DATE,
    termination_date       DATE,
    termination_type       VARCHAR(30),
    managing_office_id     UUID         REFERENCES core.offices(office_id),
    managing_specialist_user_id UUID    REFERENCES core.users(user_id),
    appointing_official_user_id UUID    REFERENCES core.users(user_id),
    flag_publish_to_locator BOOLEAN     NOT NULL DEFAULT TRUE,
    initial_appointment_date DATE,
    renewal_count          INTEGER      NOT NULL DEFAULT 0,
    cloa_version_current   INTEGER      NOT NULL DEFAULT 0,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (designee_id, designee_type_code)
);
CREATE INDEX idx_designations_designee ON designee.designations(designee_id);
CREATE INDEX idx_designations_status   ON designee.designations(status);
CREATE INDEX idx_designations_expiry   ON designee.designations(expiration_date);

ALTER TABLE workflow.cases ADD CONSTRAINT fk_case_designation
    FOREIGN KEY (designation_id) REFERENCES designee.designations(designation_id);

CREATE TABLE designee.cloas (
    cloa_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id       UUID         NOT NULL REFERENCES designee.designations(designation_id),
    cloa_version         INTEGER      NOT NULL,
    generated_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    effective_date       DATE         NOT NULL,
    expiration_date      DATE         NOT NULL,
    function_codes_json  JSONB        NOT NULL,
    limitations_json     JSONB,
    authorized_make_model_series_json JSONB,
    authorized_type_ratings_json JSONB,
    document_id          UUID         REFERENCES documents.documents(document_id),
    is_active            BOOLEAN      NOT NULL DEFAULT TRUE,
    revoked_date         DATE,
    UNIQUE (designation_id, cloa_version)
);

CREATE TABLE designee.authorizations (
    auth_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id         UUID         NOT NULL REFERENCES designee.designations(designation_id),
    function_code          VARCHAR(10)  NOT NULL REFERENCES designee.function_codes(function_code),
    auto_approval_enabled  BOOLEAN      NOT NULL DEFAULT FALSE,
    make_model_series_json JSONB,
    effective_date         DATE         NOT NULL,
    expiration_date        DATE,
    UNIQUE (designation_id, function_code)
);

CREATE TABLE designee.pre_approval_requests (
    pre_approval_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    designation_id         UUID         NOT NULL REFERENCES designee.designations(designation_id),
    status                 VARCHAR(30)  NOT NULL DEFAULT 'INITIATED',
    activity_type          VARCHAR(50)  NOT NULL,
    authorization_function_code VARCHAR(10) REFERENCES designee.function_codes(function_code),
    applicant_person_id    UUID         REFERENCES core.persons(person_id),
    applicant_ftn          VARCHAR(12),
    test_date              DATE,
    location_facility      VARCHAR(255),
    aircraft_id            UUID         REFERENCES aircraft.aircraft(aircraft_id),
    comments               TEXT,
    auto_approval_applied  BOOLEAN      NOT NULL DEFAULT FALSE,
    approved_by_user_id    UUID         REFERENCES core.users(user_id),
    approval_date          TIMESTAMPTZ,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_preapproval_designation ON designee.pre_approval_requests(designation_id);

CREATE TABLE designee.post_activity_reports (
    post_activity_id       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    pre_approval_request_id UUID        NOT NULL REFERENCES designee.pre_approval_requests(pre_approval_id),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    status                 VARCHAR(30)  NOT NULL DEFAULT 'INITIATED',
    submitted_date         DATE,
    due_date               DATE         NOT NULL,
    is_overdue             BOOLEAN GENERATED ALWAYS AS
        (submitted_date IS NULL AND CURRENT_DATE > due_date) STORED,
    applicant_person_id    UUID REFERENCES core.persons(person_id),
    test_date_actual       DATE,
    test_result            VARCHAR(20),
    test_duration_minutes  INTEGER,
    comments               TEXT,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE designee.corrective_actions (
    corrective_action_id   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id         UUID         NOT NULL REFERENCES designee.designations(designation_id),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    initiated_by_user_id   UUID         REFERENCES core.users(user_id),
    initiated_date         DATE         NOT NULL DEFAULT CURRENT_DATE,
    issue_description      TEXT         NOT NULL,
    finding_description    TEXT,
    required_action_plan   TEXT,
    action_due_date        DATE,
    status                 VARCHAR(30)  NOT NULL DEFAULT 'ASSIGNED',
    designee_response_text TEXT,
    response_submitted_date TIMESTAMPTZ,
    completion_date        DATE,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE designee.performance_evaluations (
    evaluation_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id        UUID         NOT NULL REFERENCES designee.designations(designation_id),
    evaluation_date       DATE         NOT NULL,
    conducting_inspector_user_id UUID REFERENCES core.users(user_id),
    evaluation_number     INTEGER      NOT NULL,
    technical_rating      VARCHAR(30)  NOT NULL,
    procedural_rating     VARCHAR(30)  NOT NULL,
    professional_rating   VARCHAR(30)  NOT NULL,
    overall_rating        VARCHAR(30)  NOT NULL,
    required_action       VARCHAR(30),
    next_evaluation_due_date DATE,
    renewal_recommendation TEXT,
    findings_json         JSONB,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE designee.oversight_activities (
    activity_id     UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id  UUID         NOT NULL REFERENCES designee.designations(designation_id),
    activity_type   VARCHAR(30)  NOT NULL,
    start_date      DATE         NOT NULL,
    end_date        DATE,
    procedure_description TEXT,
    objectives      TEXT,
    findings_json   JSONB,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE designee.training_records (
    training_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id         UUID         NOT NULL REFERENCES designee.designations(designation_id),
    training_course_title  VARCHAR(255) NOT NULL,
    training_type          VARCHAR(30),
    completion_date        DATE,
    training_result        VARCHAR(20),
    next_training_due_date DATE,
    certificate_document_id UUID        REFERENCES documents.documents(document_id),
    training_provider      VARCHAR(200),
    payment_id             UUID         REFERENCES payments.payments(payment_id),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE designee.suspensions (
    suspension_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id         UUID         NOT NULL REFERENCES designee.designations(designation_id),
    suspension_initiated_date DATE      NOT NULL,
    suspension_reason      TEXT         NOT NULL,
    release_due_date       DATE GENERATED ALWAYS AS
        (suspension_initiated_date + INTERVAL '180 days') STORED,
    status                 VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE',
    release_request_submitted_date TIMESTAMPTZ,
    release_outcome        VARCHAR(20),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE designee.terminations (
    termination_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id         UUID         NOT NULL REFERENCES designee.designations(designation_id),
    termination_type       VARCHAR(30)  NOT NULL,
    initiator              VARCHAR(30),
    initiated_date         DATE         NOT NULL,
    final_status           VARCHAR(30),
    for_cause_reason       TEXT,
    designee_response_text TEXT,
    reinstatement_eligible_until_date DATE,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE designee.locator_index (
    locator_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designee_id             UUID         NOT NULL REFERENCES designee.designees(designee_id),
    designation_id          UUID         NOT NULL REFERENCES designee.designations(designation_id),
    designee_name           VARCHAR(255) NOT NULL,
    designation_type        designee.designee_type NOT NULL,
    location_address_id     UUID         REFERENCES core.addresses(address_id),
    phone                   VARCHAR(30),
    published_flag          BOOLEAN      NOT NULL DEFAULT TRUE,
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_locator_type ON designee.locator_index(designation_type) WHERE published_flag = TRUE;

-- =============================================================================
-- NOTIFY DOMAIN — correspondence
-- =============================================================================

CREATE TABLE notify.templates (
    template_id       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    template_code     VARCHAR(100) UNIQUE NOT NULL,
    template_name     VARCHAR(255) NOT NULL,
    delivery_channel  notify.delivery_channel NOT NULL,
    subject_template  VARCHAR(500),
    body_template     TEXT         NOT NULL,
    domain_scope      workflow.case_domain,
    version           INTEGER      NOT NULL DEFAULT 1,
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE notify.correspondence (
    correspondence_id     UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id               UUID         REFERENCES workflow.cases(case_id),
    recipient_person_id   UUID         REFERENCES core.persons(person_id),
    recipient_user_id     UUID         REFERENCES core.users(user_id),
    template_id           UUID         REFERENCES notify.templates(template_id),
    correspondence_type   VARCHAR(50) NOT NULL,
    subject_line          VARCHAR(500),
    body_html             TEXT,
    body_plain_text       TEXT,
    delivery_channel      notify.delivery_channel NOT NULL,
    delivery_address      VARCHAR(500),
    recipient_address_id  UUID         REFERENCES core.addresses(address_id),
    delivery_status       notify.delivery_status NOT NULL DEFAULT 'QUEUED',
    delivery_timestamp    TIMESTAMPTZ,
    viewed_at             TIMESTAMPTZ,
    acknowledged_at       TIMESTAMPTZ,
    delivery_failure_reason TEXT,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_correspondence_case     ON notify.correspondence(case_id);
CREATE INDEX idx_correspondence_recipient ON notify.correspondence(recipient_person_id);
CREATE INDEX idx_correspondence_status   ON notify.correspondence(delivery_status);

-- =============================================================================
-- INTEGRATION DOMAIN — outbound / inbound hooks
-- =============================================================================

CREATE TABLE integration.endpoints (
    endpoint_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    source_system          VARCHAR(50)  NOT NULL,
    target_system          VARCHAR(50)  NOT NULL,
    protocol               VARCHAR(20)  NOT NULL CHECK (protocol IN
        ('REST','SOAP','FTP','SFTP','FILE_DROP','DIRECT_SQL','KAFKA','KINESIS')),
    endpoint_uri           VARCHAR(2048),
    authentication_method  VARCHAR(30),
    is_active              BOOLEAN      NOT NULL DEFAULT TRUE,
    sla_response_time_ms   INTEGER,
    sla_availability_pct   NUMERIC(5,2),
    last_health_check      TIMESTAMPTZ,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE integration.transactions (
    transaction_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    endpoint_id            UUID         REFERENCES integration.endpoints(endpoint_id),
    case_id                UUID         REFERENCES workflow.cases(case_id),
    source_system          VARCHAR(50) NOT NULL,
    target_system          VARCHAR(50) NOT NULL,
    transaction_type       VARCHAR(100) NOT NULL,
    reference_id           VARCHAR(255),
    status                 VARCHAR(30) NOT NULL,
    sent_at                TIMESTAMPTZ,
    received_at            TIMESTAMPTZ,
    request_payload_summary TEXT,
    response_status_code   INTEGER,
    error_message          TEXT,
    retry_count            INTEGER      NOT NULL DEFAULT 0,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_int_tx_endpoint ON integration.transactions(endpoint_id);
CREATE INDEX idx_int_tx_case     ON integration.transactions(case_id);
CREATE INDEX idx_int_tx_status   ON integration.transactions(status);

-- =============================================================================
-- AUDIT DOMAIN — single audit trail (replaces 4 per-system audit logs)
-- =============================================================================

CREATE TABLE audit.events (
    audit_id            BIGSERIAL    PRIMARY KEY,
    event_time          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    event_type          VARCHAR(100) NOT NULL,
    event_domain        workflow.case_domain,
    entity_type         VARCHAR(50)  NOT NULL,
    entity_id           UUID,
    action              VARCHAR(30)  NOT NULL CHECK (action IN
        ('CREATE','READ','UPDATE','DELETE','EXPORT','DISCLOSURE','APPROVE','SUBMIT','LOGIN','LOGOUT')),
    actor_user_id       UUID         REFERENCES core.users(user_id),
    actor_role          VARCHAR(50),
    actor_person_id     UUID         REFERENCES core.persons(person_id),
    case_id             UUID         REFERENCES workflow.cases(case_id),
    ip_address          INET,
    user_agent          TEXT,
    changes_before      JSONB,
    changes_after       JSONB,
    http_status_code    INTEGER,
    error_message       TEXT,
    sorn_scope          VARCHAR(50),
    retention_schedule  VARCHAR(50),
    pii_involved        BOOLEAN      NOT NULL DEFAULT FALSE,
    phi_involved        BOOLEAN      NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_audit_event_time   ON audit.events(event_time);
CREATE INDEX idx_audit_entity       ON audit.events(entity_type, entity_id);
CREATE INDEX idx_audit_actor        ON audit.events(actor_user_id);
CREATE INDEX idx_audit_case         ON audit.events(case_id);
CREATE INDEX idx_audit_domain_type  ON audit.events(event_domain, event_type);
COMMENT ON TABLE audit.events IS 'Unified audit log — FIPS HIGH for medical rows, MODERATE elsewhere; partitioning by month recommended.';

CREATE TABLE audit.disclosure_log (
    disclosure_id       BIGSERIAL    PRIMARY KEY,
    event_time          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    person_id           UUID         REFERENCES core.persons(person_id),
    recipient_name      VARCHAR(255),
    recipient_agency    VARCHAR(255),
    sorn_scope          VARCHAR(50),
    routine_use_basis   VARCHAR(255),
    fields_disclosed    TEXT[],
    reason              TEXT,
    authorized_by_user_id UUID REFERENCES core.users(user_id)
);
COMMENT ON TABLE audit.disclosure_log IS 'Privacy Act (e) disclosure accounting — who received what PII, when, why.';

-- =============================================================================
-- COMPATIBILITY VIEWS — ease migration from legacy system queries
-- =============================================================================

CREATE OR REPLACE VIEW core.v_airman_master AS
SELECT
    p.person_id,
    p.ftn,
    im_cert.identifier_value   AS legacy_certificate_number,
    im_appl.identifier_value   AS legacy_applicant_id,
    im_mid.identifier_value    AS legacy_mid,
    im_des.identifier_value    AS legacy_designee_number,
    p.full_legal_name,
    p.date_of_birth,
    p.email_address,
    p.person_type
FROM core.persons p
LEFT JOIN core.identifier_mappings im_cert
       ON im_cert.person_id = p.person_id AND im_cert.identifier_type = 'CERTIFICATE_NUMBER'
LEFT JOIN core.identifier_mappings im_appl
       ON im_appl.person_id = p.person_id AND im_appl.identifier_type = 'APPLICANT_ID'
LEFT JOIN core.identifier_mappings im_mid
       ON im_mid.person_id = p.person_id AND im_mid.identifier_type = 'MID'
LEFT JOIN core.identifier_mappings im_des
       ON im_des.person_id = p.person_id AND im_des.identifier_type = 'DESIGNEE_NUMBER';
COMMENT ON VIEW core.v_airman_master IS 'Legacy compatibility view — resolves all prior system identifiers to unified person.';

-- =============================================================================
-- END OF UNIFIED SCHEMA
-- =============================================================================
