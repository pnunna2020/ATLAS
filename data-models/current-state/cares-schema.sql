-- =============================================================================
-- CARES — Civil Aviation Registration Electronic Services
-- Current-State Schema (cloud replacement platform)
-- =============================================================================
-- Mandate: FAA Reauthorization Act of 2018 §546.
-- Scope (phased):
--   Phase 1 — Aircraft Registration (IOC Dec 2022, FOC Fall 2027)
--   Phase 2 — Airman Examination/Certification/Rating (IOC Fall 2025)
--   Phase 3 — Descoped (UAS absorbed into Phases 1/2)
-- Acts as intake surface during hybrid state; legacy CAIS remains system
-- of record through FOC. Operates on AWS GovCloud, authoritative identity
-- via MyAccess (migrating to Login.gov).
-- FIPS 199: MODERATE. Replaces: RMS/CAIS, IACRA, fragmented public inquiry.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS cares;
SET search_path TO cares, public;

-- -----------------------------------------------------------------------------
-- ENUMERATED TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE cares.case_type AS ENUM (
    'AIRCRAFT_REGISTRATION',
    'AIRCRAFT_RENEWAL',
    'AIRCRAFT_NAME_CHANGE',
    'AIRCRAFT_ADDRESS_CHANGE',
    'AIRCRAFT_CANCELLATION',
    'N_NUMBER_REQUEST',
    'N_NUMBER_RESERVATION',
    'BILL_OF_SALE_RECORDING',
    'LIEN_RECORDING',
    'DEALER_REGISTRATION',
    'EXPORT_CERTIFICATE',
    'AIRMAN_APPLICATION',
    'AIRMAN_CERT_REPLACEMENT',
    'AIRMAN_ADDRESS_CHANGE',
    'KNOWLEDGE_TEST',
    'PRACTICAL_TEST'
);

CREATE TYPE cares.case_status AS ENUM (
    'DRAFT',
    'SUBMITTED',
    'IN_REVIEW',
    'ACTION_REQUIRED',
    'DECIDED',
    'COMPLETED',
    'CANCELLED',
    'REJECTED'
);

CREATE TYPE cares.signature_status AS ENUM (
    'NOT_REQUIRED','PENDING','EXECUTED','DECLINED','VOIDED','EXPIRED'
);

CREATE TYPE cares.handoff_status AS ENUM (
    'PENDING','SUBMITTED','CONFIRMED_IN_CAIS','ERROR','RETRYING','ABANDONED'
);

CREATE TYPE cares.payment_status AS ENUM (
    'PENDING','SUBMITTED','COMPLETED','FAILED','CANCELLED','REFUNDED'
);

CREATE TYPE cares.aircraft_status AS ENUM (
    'PENDING','ACTIVE','EXPIRED','CANCELLED','DEREGISTERED','SUSPENDED','REVOKED'
);

CREATE TYPE cares.airman_cert_status AS ENUM (
    'VALID','EXPIRED','REVOKED','SUSPENDED','DENIED','ISSUED','AWAITING_ISSUE'
);

CREATE TYPE cares.practical_outcome AS ENUM (
    'APPROVED','DISAPPROVED','DISCONTINUE','DELETE'
);

CREATE TYPE cares.tsa_vetting_status AS ENUM (
    'NOT_REQUIRED','PENDING','SUBMITTED','APPROVED','DENIED','EXPIRED'
);

-- -----------------------------------------------------------------------------
-- PERSONS (Phase 1 + Phase 2 unified identity)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.persons (
    person_id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    ftn                     VARCHAR(12)  UNIQUE,            -- airmen only
    myaccess_subject_id     VARCHAR(255) UNIQUE,
    login_gov_sub           VARCHAR(255) UNIQUE,
    piv_card_dn             VARCHAR(512),                   -- FAA employees/contractors
    identity_proofing_status VARCHAR(30) NOT NULL DEFAULT 'PENDING'
        CHECK (identity_proofing_status IN ('PENDING','VERIFIED','FAILED')),
    identity_proofing_level VARCHAR(10)  CHECK (identity_proofing_level IN ('IAL1','IAL2','IAL3')),
    identity_proofed_at     TIMESTAMPTZ,
    full_name               VARCHAR(255) NOT NULL,
    first_name              VARCHAR(100),
    middle_name             VARCHAR(100),
    last_name               VARCHAR(100),
    suffix                  VARCHAR(20),
    ssn_last_4              CHAR(4),                        -- never a lookup key
    date_of_birth           DATE,
    sex                     CHAR(1) CHECK (sex IN ('M','F','U')),
    citizenship_country     CHAR(2)      DEFAULT 'US',
    hair_color              VARCHAR(30),
    eye_color               VARCHAR(30),
    height_inches           SMALLINT,
    weight_lbs              SMALLINT,
    email_address           VARCHAR(255) NOT NULL,
    phone_number            VARCHAR(30),
    person_type             VARCHAR(30) NOT NULL CHECK (person_type IN
        ('AIRMAN','REGISTRANT','DESIGNEE','APPLICANT','FAA_STAFF')),
    -- Legacy identifier aliases (all map to this single master)
    legacy_certificate_number VARCHAR(20),
    legacy_applicant_id     VARCHAR(20),
    legacy_designee_number  VARCHAR(20),
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    audit_user_id           VARCHAR(255)
);
CREATE INDEX idx_persons_ftn ON cares.persons(ftn);
CREATE INDEX idx_persons_myaccess ON cares.persons(myaccess_subject_id);
CREATE INDEX idx_persons_email ON cares.persons(email_address);
CREATE INDEX idx_persons_name ON cares.persons(last_name, first_name);

-- -----------------------------------------------------------------------------
-- ORGANIZATIONS (corps, partnerships, LLCs, trusts, FBOs, schools)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.organizations (
    organization_id     UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_name   VARCHAR(255) NOT NULL,
    entity_type         VARCHAR(50)  NOT NULL CHECK (entity_type IN
        ('CORPORATION','PARTNERSHIP','LLC','TRUST','GOVERNMENT','SOLE_PROPRIETOR','NON_CITIZEN_CORP')),
    ein                 VARCHAR(10),
    state_of_formation  CHAR(2),
    country_of_formation CHAR(2),
    business_email      VARCHAR(255),
    business_phone      VARCHAR(30),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (ein)
);

-- -----------------------------------------------------------------------------
-- ADDRESSES
-- -----------------------------------------------------------------------------

CREATE TABLE cares.addresses (
    address_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id           UUID         REFERENCES cares.persons(person_id),
    organization_id     UUID         REFERENCES cares.organizations(organization_id),
    address_type        VARCHAR(20)  NOT NULL CHECK (address_type IN ('MAILING','PHYSICAL','BUSINESS','ALTERNATE')),
    street_line_1       VARCHAR(255) NOT NULL,
    street_line_2       VARCHAR(255),
    city                VARCHAR(100) NOT NULL,
    state_province      VARCHAR(50),
    zip_postal_code     VARCHAR(20),
    country_code        CHAR(2)      NOT NULL DEFAULT 'US',
    validated           BOOLEAN      NOT NULL DEFAULT FALSE,
    validation_service  VARCHAR(50),
    latitude            NUMERIC(10,8),
    longitude           NUMERIC(11,8),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    ceased_date         DATE,
    CONSTRAINT chk_addr_owner CHECK (
        (person_id IS NOT NULL AND organization_id IS NULL)
        OR (person_id IS NULL AND organization_id IS NOT NULL)
    )
);
CREATE INDEX idx_addresses_person ON cares.addresses(person_id);
CREATE INDEX idx_addresses_org    ON cares.addresses(organization_id);

-- -----------------------------------------------------------------------------
-- AIRCRAFT (Phase 1)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.aircraft (
    aircraft_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    n_number                 VARCHAR(6)   NOT NULL UNIQUE
                                 CHECK (n_number ~ '^N[A-Z0-9]{1,5}$'),
    manufacturer_make        VARCHAR(100),
    model                    VARCHAR(100),
    manufacturer_serial_number VARCHAR(50),
    year_manufactured        SMALLINT,
    airworthiness_cert_type  VARCHAR(50),
    aircraft_category        VARCHAR(50),
    registration_status      cares.aircraft_status NOT NULL DEFAULT 'PENDING',
    n_number_assignment_date DATE,
    registration_issue_date  DATE,
    registration_renewal_due_date DATE,
    mode_s_code_hex          CHAR(6) UNIQUE,
    legacy_cais_record_id    VARCHAR(100),
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_aircraft_nnum   ON cares.aircraft(n_number);
CREATE INDEX idx_aircraft_status ON cares.aircraft(registration_status);
CREATE INDEX idx_aircraft_serial ON cares.aircraft(manufacturer_serial_number);
COMMENT ON COLUMN cares.aircraft.legacy_cais_record_id IS 'Reference to authoritative CAIS record during hybrid state.';

-- -----------------------------------------------------------------------------
-- CASES (workflow-bound application record)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.cases (
    case_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_reference_number  VARCHAR(30)  UNIQUE,
    myaccess_subject_id    VARCHAR(255),
    case_type              cares.case_type NOT NULL,
    form_type              VARCHAR(30),            -- AC_8050_1, AC_8050_1B, AC_8050_2, 8710-x, etc.
    status                 cares.case_status NOT NULL DEFAULT 'DRAFT',
    case_opened_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    case_submitted_at      TIMESTAMPTZ,
    case_decided_at        TIMESTAMPTZ,
    case_closed_at         TIMESTAMPTZ,
    aircraft_id            UUID         REFERENCES cares.aircraft(aircraft_id),
    person_id              UUID         REFERENCES cares.persons(person_id),
    organization_id        UUID         REFERENCES cares.organizations(organization_id),
    document_package_id    UUID,
    payment_transaction_id UUID,
    signature_envelope_id  VARCHAR(255),
    signature_status       cares.signature_status NOT NULL DEFAULT 'NOT_REQUIRED',
    assigned_to_user_id    VARCHAR(255),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    audit_user_id          VARCHAR(255)
);
CREATE INDEX idx_cases_status     ON cares.cases(status);
CREATE INDEX idx_cases_applicant  ON cares.cases(myaccess_subject_id);
CREATE INDEX idx_cases_type       ON cares.cases(case_type);
CREATE INDEX idx_cases_aircraft   ON cares.cases(aircraft_id);

CREATE TABLE cares.case_history (
    history_id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                UUID         NOT NULL REFERENCES cares.cases(case_id) ON DELETE CASCADE,
    status_from            cares.case_status,
    status_to              cares.case_status NOT NULL,
    transition_reason      VARCHAR(500),
    transition_timestamp   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    transition_user_id     VARCHAR(255),
    notes                  TEXT
);
CREATE INDEX idx_case_history_case ON cares.case_history(case_id);

-- -----------------------------------------------------------------------------
-- DOCUMENTS (unified store replacing 174M TIFFs)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.documents (
    document_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                UUID         REFERENCES cares.cases(case_id) ON DELETE CASCADE,
    document_type          VARCHAR(100) NOT NULL,    -- bill_of_sale, llc_statement, poa, evidence_of_ownership, etc.
    document_title         VARCHAR(255),
    cloud_storage_uri      VARCHAR(2048) NOT NULL,   -- S3/GCS URI
    file_format            VARCHAR(20)  NOT NULL,
    file_size_bytes        BIGINT       NOT NULL CHECK (file_size_bytes > 0),
    file_hash_sha256       CHAR(64)     NOT NULL,
    upload_timestamp       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    uploaded_by_user_id    VARCHAR(255),
    ocr_text_extracted     TEXT,
    extracted_entities     JSONB,                   -- ML extraction output
    virus_scanned          BOOLEAN      NOT NULL DEFAULT FALSE,
    virus_scan_timestamp   TIMESTAMPTZ,
    encryption_algorithm   VARCHAR(30)  DEFAULT 'AES256',
    nara_retention_schedule VARCHAR(50) NOT NULL,    -- N1-237-04-03 (perm), N1-237-06-001, etc.
    disposal_scheduled_date DATE,
    disposal_executed_date DATE,
    signature_envelope_id  VARCHAR(255),
    signature_status       cares.signature_status,
    signer_user_id         VARCHAR(255),
    signed_at              TIMESTAMPTZ,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_documents_case ON cares.documents(case_id);
CREATE INDEX idx_documents_type ON cares.documents(document_type);
CREATE INDEX idx_documents_hash ON cares.documents(file_hash_sha256);
COMMENT ON TABLE cares.documents IS 'Unified document store — modernizes 174M TIFFs with OCR, hash integrity, cloud storage.';

-- -----------------------------------------------------------------------------
-- PAYMENTS (Pay.gov integration)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.payments (
    payment_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                 UUID         NOT NULL REFERENCES cares.cases(case_id),
    form_type               VARCHAR(30),
    service_description     VARCHAR(255),
    fee_amount_cents        INTEGER      NOT NULL CHECK (fee_amount_cents >= 0),
    currency_code           CHAR(3)      NOT NULL DEFAULT 'USD',
    pay_gov_transaction_id  VARCHAR(100) UNIQUE,
    pay_gov_agency_tracking_id VARCHAR(100),
    payment_status          cares.payment_status NOT NULL DEFAULT 'PENDING',
    submitted_at            TIMESTAMPTZ,
    confirmed_at            TIMESTAMPTZ,
    confirmation_token      VARCHAR(255),
    payer_email             VARCHAR(255),
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    audit_user_id           VARCHAR(255)
);
CREATE INDEX idx_payments_case   ON cares.payments(case_id);
CREATE INDEX idx_payments_status ON cares.payments(payment_status);

ALTER TABLE cares.cases
    ADD CONSTRAINT fk_case_payment
    FOREIGN KEY (payment_transaction_id) REFERENCES cares.payments(payment_id);

-- -----------------------------------------------------------------------------
-- CAIS HANDOFF (dual-run during hybrid state)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.cais_handoff_records (
    handoff_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                 UUID         NOT NULL REFERENCES cares.cases(case_id),
    cais_record_id          VARCHAR(100),
    handoff_status          cares.handoff_status NOT NULL DEFAULT 'PENDING',
    handoff_payload_json    JSONB,
    handoff_timestamp       TIMESTAMPTZ,
    handoff_user_id         VARCHAR(255),
    cais_confirmation_token VARCHAR(255),
    cais_confirmation_timestamp TIMESTAMPTZ,
    error_message           TEXT,
    retry_count             INTEGER      NOT NULL DEFAULT 0,
    last_retry_timestamp    TIMESTAMPTZ,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_handoff_status ON cares.cais_handoff_records(handoff_status);
CREATE INDEX idx_handoff_case   ON cares.cais_handoff_records(case_id);
COMMENT ON TABLE cares.cais_handoff_records IS 'Hybrid-state intake-to-CAIS replication; legacy CAIS remains authoritative until FOC.';

-- -----------------------------------------------------------------------------
-- PHASE 2 — AIRMEN CERTIFICATION (when Phase 2 goes live)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.airman_certificates (
    certificate_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id                UUID         NOT NULL REFERENCES cares.persons(person_id),
    ftn                      VARCHAR(12)  NOT NULL,
    certificate_number       VARCHAR(20)  UNIQUE,
    certificate_type         VARCHAR(50),
    certificate_class        VARCHAR(30),
    certificate_level        VARCHAR(30),
    ratings                  TEXT[],
    limitations              TEXT[],
    medical_certificate_reference UUID,
    issue_date               DATE         NOT NULL,
    expiration_date          DATE,
    status                   cares.airman_cert_status NOT NULL DEFAULT 'ISSUED',
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_airman_certs_ftn     ON cares.airman_certificates(ftn);
CREATE INDEX idx_airman_certs_status  ON cares.airman_certificates(status);

CREATE TABLE cares.airman_knowledge_tests (
    test_result_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    ftn                      VARCHAR(12)  NOT NULL,
    test_type                VARCHAR(50),
    test_name                VARCHAR(255),
    test_date                DATE,
    test_site_id             VARCHAR(50),
    score                    SMALLINT,
    status                   VARCHAR(20) CHECK (status IN ('PASSED','FAILED','EXPIRED')),
    passed_at                TIMESTAMPTZ,
    expiration_date          DATE,
    failed_areas             TEXT[],
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_knowledge_ftn ON cares.airman_knowledge_tests(ftn);

CREATE TABLE cares.airman_practical_tests (
    practical_test_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                  UUID         NOT NULL REFERENCES cares.cases(case_id),
    ftn                      VARCHAR(12)  NOT NULL,
    designated_examiner_id   VARCHAR(20),
    test_type                VARCHAR(50),
    test_date                DATE,
    test_aircraft_n_number   VARCHAR(6),
    outcome                  cares.practical_outcome,
    disapproved_areas        TEXT[],
    examiner_notes           TEXT,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_practical_ftn ON cares.airman_practical_tests(ftn);

CREATE TABLE cares.tsa_vetting_records (
    vetting_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id                 UUID         NOT NULL REFERENCES cares.persons(person_id),
    ftn                       VARCHAR(12),
    vetting_request_sent_at   TIMESTAMPTZ,
    vetting_response_received_at TIMESTAMPTZ,
    vetting_status            cares.tsa_vetting_status NOT NULL DEFAULT 'PENDING',
    tsa_vetting_result        VARCHAR(255),
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- IDENTIFIER MAPPING (resolves legacy keys across systems)
-- -----------------------------------------------------------------------------

CREATE TABLE cares.identifier_mappings (
    mapping_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id            UUID         NOT NULL REFERENCES cares.persons(person_id),
    identifier_type      VARCHAR(30) NOT NULL CHECK (identifier_type IN
        ('FTN','CERTIFICATE_NUMBER','APPLICANT_ID','MID','DESIGNEE_NUMBER','LEGACY_SSN_HASH')),
    identifier_value     VARCHAR(100) NOT NULL,
    source_system        VARCHAR(30)  NOT NULL CHECK (source_system IN
        ('CARES','CAIS','RMS','MSS','DMS','IACRA')),
    is_primary           BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (identifier_type, identifier_value, source_system)
);
CREATE INDEX idx_id_mappings_person ON cares.identifier_mappings(person_id);
CREATE INDEX idx_id_mappings_value  ON cares.identifier_mappings(identifier_value);
COMMENT ON TABLE cares.identifier_mappings IS 'Resolves legacy identifiers (FTN, Cert #, Applicant ID, MID, Designee #) to unified person_id.';

-- -----------------------------------------------------------------------------
-- INTEGRATION ENDPOINTS & TRANSACTION LOG
-- -----------------------------------------------------------------------------

CREATE TABLE cares.integration_endpoints (
    endpoint_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    source_system          VARCHAR(30)  NOT NULL,
    target_system          VARCHAR(30)  NOT NULL,
    protocol               VARCHAR(20) NOT NULL CHECK (protocol IN
        ('REST','SOAP','FTP','SFTP','FILE_DROP','DIRECT_SQL','KAFKA','KINESIS')),
    endpoint_uri           VARCHAR(2048),
    authentication_method  VARCHAR(30),
    is_active              BOOLEAN      NOT NULL DEFAULT TRUE,
    sla_response_time_ms   INTEGER,
    sla_availability_pct   NUMERIC(5,2),
    last_health_check      TIMESTAMPTZ,
    last_error             TEXT,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE cares.integration_transactions (
    transaction_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    source_system          VARCHAR(30) NOT NULL,
    target_system          VARCHAR(30) NOT NULL,
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
CREATE INDEX idx_int_tx_status  ON cares.integration_transactions(status);
CREATE INDEX idx_int_tx_sent    ON cares.integration_transactions(sent_at);

-- -----------------------------------------------------------------------------
-- SYSTEM CLASSIFICATION
-- -----------------------------------------------------------------------------

CREATE TABLE cares.system_classification (
    system_id                VARCHAR(30)  PRIMARY KEY,
    system_name              VARCHAR(255) NOT NULL,
    fips_199_category        VARCHAR(10)  NOT NULL CHECK (fips_199_category IN ('LOW','MODERATE','HIGH')),
    ato_date                 DATE,
    annual_review_date       DATE,
    nist_800_53_baseline     VARCHAR(50),
    ato_number               VARCHAR(100),
    csp_name                 VARCHAR(255),
    cloud_boundary           BOOLEAN,
    pii_processing           BOOLEAN,
    payment_processing       BOOLEAN,
    external_integrations    INTEGER,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- NOTIFICATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE cares.notifications (
    notification_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id                UUID         REFERENCES cares.cases(case_id),
    person_id              UUID         REFERENCES cares.persons(person_id),
    notification_type      VARCHAR(50) NOT NULL,
    subject_line           VARCHAR(500),
    template_id            VARCHAR(100),
    message_body           TEXT,
    delivery_channel       VARCHAR(30) CHECK (delivery_channel IN ('EMAIL','USPS_LETTER','PORTAL_MESSAGE','SMS')),
    delivery_status        VARCHAR(30) CHECK (delivery_status IN ('PENDING','SENT','FAILED','BOUNCED','DELIVERED')),
    sent_at                TIMESTAMPTZ,
    read_at                TIMESTAMPTZ,
    recipient_email        VARCHAR(255),
    recipient_address_id   UUID REFERENCES cares.addresses(address_id),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notifications_case   ON cares.notifications(case_id);
CREATE INDEX idx_notifications_status ON cares.notifications(delivery_status);

-- -----------------------------------------------------------------------------
-- AUDIT LOG
-- -----------------------------------------------------------------------------

CREATE TABLE cares.audit_log (
    audit_id           BIGSERIAL    PRIMARY KEY,
    event_timestamp    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    event_type         VARCHAR(100) NOT NULL,
    entity_type        VARCHAR(50)  NOT NULL,
    entity_id          UUID,
    actor_user_id      VARCHAR(255),
    actor_role         VARCHAR(50),
    action_description TEXT,
    changes_before     JSONB,
    changes_after      JSONB,
    ip_address         INET,
    user_agent         TEXT,
    http_status_code   INTEGER,
    error_message      TEXT,
    sorn_scope         VARCHAR(50),
    retention_schedule VARCHAR(50),
    pii_involved       BOOLEAN      NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_cares_audit_event_type ON cares.audit_log(event_type);
CREATE INDEX idx_cares_audit_entity     ON cares.audit_log(entity_type, entity_id);
CREATE INDEX idx_cares_audit_actor      ON cares.audit_log(actor_user_id);
CREATE INDEX idx_cares_audit_time       ON cares.audit_log(event_timestamp);

-- =============================================================================
-- END OF CARES SCHEMA
-- =============================================================================
