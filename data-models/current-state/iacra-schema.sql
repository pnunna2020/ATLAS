-- =============================================================================
-- IACRA — Integrated Airman Certification and Rating Application
-- Current-State Schema
-- =============================================================================
-- Purpose: web-based intake of 7 forms (8400-3, 8610-1/2, 8710-1/11/13, 8060-71)
-- with TIFF-over-FTP handoff to CAIS. Built on ASP.NET Web Forms.
-- Forms covered: student-pilot (8710-1), flight-instructor (8710-11),
--   airline-transport (8710-13), military-competence (8710-5),
--   sport-pilot (8710-4), unmanned (8710-6/8060-71), mechanic (8610-1),
--   repairman (8610-2), dispatcher (8400-3).
-- Retention: NARA N1-237-09-14 (temporary record deletion semantics).
-- FIPS 199: MODERATE. SORN: DOT/FAA 847.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS iacra;
SET search_path TO iacra, public;

-- -----------------------------------------------------------------------------
-- ENUM TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE iacra.form_type AS ENUM (
    'FORM_8400_3',      -- Aircraft Dispatcher
    'FORM_8610_1',      -- Mechanic
    'FORM_8610_2',      -- Repairman
    'FORM_8710_1',      -- Airman Cert / Rating
    'FORM_8710_11',     -- Flight Instructor
    'FORM_8710_13',     -- Pilot Cert / Rating Application (ATP)
    'FORM_8060_71'      -- Unmanned Remote Pilot
);

CREATE TYPE iacra.certificate_type AS ENUM (
    'STUDENT_PILOT',
    'RECREATIONAL',
    'PRIVATE',
    'COMMERCIAL',
    'ATP',
    'CFI',
    'SPORT_PILOT',
    'REMOTE_PILOT',
    'FLIGHT_ENGINEER',
    'AIRCRAFT_DISPATCHER',
    'MECHANIC',
    'REPAIRMAN',
    'FLIGHT_REVIEW',
    'INSTRUMENT_PROFICIENCY_CHECK'
);

CREATE TYPE iacra.path_type AS ENUM (
    'CFR_61','CFR_141','CFR_142','CFR_121','CFR_135',
    'MILITARY_COMPETENCY','FOREIGN_BASED','AQP'
);

CREATE TYPE iacra.application_status AS ENUM (
    'DRAFT',
    'SUBMITTED',
    'RECOMMENDED_BY_INSTRUCTOR',
    'ACCEPTED_BY_EXAMINER',
    'PRACTICAL_TEST_PASSED',
    'FACILITATED_TO_ACB',
    'CERTIFICATE_ISSUED',
    'DISAPPROVED',
    'DISCONTINUED',
    'DELETED'
);

CREATE TYPE iacra.role_type AS ENUM (
    'APPLICANT',
    'RECOMMENDING_INSTRUCTOR',
    'DESIGNATED_EXAMINER',
    'ASI',                       -- Aviation Safety Inspector
    'AST',
    'SCHOOL_ADMINISTRATOR',
    'CHIEF_FLIGHT_INSTRUCTOR',
    'ASSISTANT_CHIEF_FLIGHT_INSTRUCTOR',
    'ACR',                       -- Airman Certification Representative
    'TCE',
    'FIRE',
    'APD',
    'AIR_CARRIER_FLIGHT_INSTRUCTOR',
    'TRAINING_CENTER_EVALUATOR',
    'RECOMMENDING_INSTRUCTOR_142',
    'GROUND_INSTRUCTOR'
);

CREATE TYPE iacra.practical_outcome AS ENUM ('APPROVE','DISAPPROVE','DISCONTINUE','DELETE');
CREATE TYPE iacra.tsa_status AS ENUM ('PENDING','SUBMITTED','APPROVED','DENIED','EXPIRED');
CREATE TYPE iacra.medical_class AS ENUM ('FIRST_CLASS','SECOND_CLASS','THIRD_CLASS','REMOTE_PILOT_MEDICAL');

-- -----------------------------------------------------------------------------
-- REFERENCE DATA
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.security_questions (
    question_id     SERIAL       PRIMARY KEY,
    question_text   VARCHAR(500) NOT NULL,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE iacra.aircraft_make_models (
    aircraft_id      SERIAL      PRIMARY KEY,
    make             VARCHAR(100) NOT NULL,
    model            VARCHAR(100) NOT NULL,
    category_class   VARCHAR(50) NOT NULL,
    type_rating_required BOOLEAN  NOT NULL DEFAULT FALSE,
    is_active        BOOLEAN     NOT NULL DEFAULT TRUE,
    UNIQUE (make, model)
);

CREATE TABLE iacra.fsdo_offices (
    fsdo_id      SERIAL      PRIMARY KEY,
    fsdo_code    VARCHAR(10) NOT NULL UNIQUE,
    fsdo_name    VARCHAR(255) NOT NULL,
    office_type  VARCHAR(20) NOT NULL CHECK (office_type IN ('FSDO','IFO','RHQ','AEG','ACO')),
    region       VARCHAR(100),
    state_code   CHAR(2),
    phone        VARCHAR(30),
    email        VARCHAR(255),
    is_active    BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE iacra.test_codes (
    test_code_id       SERIAL      PRIMARY KEY,
    test_code          VARCHAR(10) NOT NULL UNIQUE,    -- PAR, IRA, ATM, etc.
    test_name          VARCHAR(200) NOT NULL,
    valid_certificates TEXT[],
    expiration_months  SMALLINT    NOT NULL DEFAULT 24,
    is_active          BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE iacra.certificate_type_reference (
    cert_type_id         SERIAL       PRIMARY KEY,
    certificate_type     iacra.certificate_type NOT NULL UNIQUE,
    minimum_age          SMALLINT,
    requires_medical     BOOLEAN      NOT NULL DEFAULT FALSE,
    requires_knowledge_test BOOLEAN   NOT NULL DEFAULT FALSE,
    requires_practical_test BOOLEAN   NOT NULL DEFAULT FALSE,
    practical_duration_hrs NUMERIC(3,1),
    category_class_applicable BOOLEAN NOT NULL DEFAULT TRUE,
    type_rating_applicable BOOLEAN    NOT NULL DEFAULT FALSE
);

CREATE TABLE iacra.certificate_flight_minimums (
    flight_min_id          SERIAL PRIMARY KEY,
    certificate_type       iacra.certificate_type NOT NULL,
    category_class         VARCHAR(50) NOT NULL,
    minimum_total_hours    NUMERIC(6,1),
    minimum_pic_hours      NUMERIC(6,1),
    minimum_instrument_hours NUMERIC(6,1),
    minimum_cross_country_hours NUMERIC(6,1),
    minimum_solo_hours     NUMERIC(6,1),
    UNIQUE (certificate_type, category_class)
);

-- -----------------------------------------------------------------------------
-- AIRMAN (central person record)
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.airmen (
    airman_id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    ftn                      VARCHAR(12) NOT NULL UNIQUE,
    ssn                      VARCHAR(11),
    first_name               VARCHAR(100) NOT NULL,
    middle_name              VARCHAR(100),
    last_name                VARCHAR(100) NOT NULL,
    name_suffix              VARCHAR(10),
    date_of_birth            DATE         NOT NULL,
    sex                      CHAR(1)      CHECK (sex IN ('M','F')),
    citizenship_country      VARCHAR(100) NOT NULL,
    country_of_birth         VARCHAR(100) NOT NULL,
    state_of_birth           CHAR(2),
    city_of_birth            VARCHAR(100) NOT NULL,
    county_of_birth          VARCHAR(100),
    hair_color               VARCHAR(30),
    eye_color                VARCHAR(30),
    height_inches            SMALLINT,
    weight_pounds            SMALLINT,
    email_address            VARCHAR(255) NOT NULL UNIQUE,
    phone_number             VARCHAR(30)  NOT NULL,
    mailing_address_line1    VARCHAR(255) NOT NULL,
    mailing_address_line2    VARCHAR(255),
    mailing_address_physical_desc VARCHAR(500),
    mailing_city             VARCHAR(100) NOT NULL,
    mailing_state            CHAR(2),
    mailing_country          VARCHAR(100) NOT NULL,
    mailing_zip_code         VARCHAR(20),
    airman_certificate_number VARCHAR(20),
    airman_registry_lookup_date TIMESTAMPTZ,
    immutable_fields_locked  BOOLEAN      NOT NULL DEFAULT FALSE,
    account_status           VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE'
        CHECK (account_status IN ('ACTIVE','SUSPENDED','DELETED')),
    is_deleted               BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_airman_state_if_us
        CHECK (mailing_country <> 'United States' OR mailing_state IS NOT NULL)
);
CREATE INDEX idx_airmen_name ON iacra.airmen(last_name, first_name);
CREATE INDEX idx_airmen_email ON iacra.airmen(email_address);
COMMENT ON COLUMN iacra.airmen.ftn IS 'Federal Tracking Number — unique cross-system identifier.';
COMMENT ON COLUMN iacra.airmen.immutable_fields_locked IS 'Set true once Airman Registry has supplied Name/DOB/Sex/Citizenship.';

-- -----------------------------------------------------------------------------
-- USER ACCOUNTS + AUTH
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.user_accounts (
    user_id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    ftn                     VARCHAR(12) NOT NULL REFERENCES iacra.airmen(ftn),
    username                VARCHAR(100) NOT NULL UNIQUE,
    password_hash           VARCHAR(255) NOT NULL,
    email_verified          BOOLEAN     NOT NULL DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expires_at TIMESTAMPTZ,
    mfa_enabled             BOOLEAN     NOT NULL DEFAULT TRUE,
    mfa_email_trust_days    SMALLINT    NOT NULL DEFAULT 30,
    mfa_last_verified_at    TIMESTAMPTZ,
    security_q1_id          INTEGER     REFERENCES iacra.security_questions(question_id),
    security_q1_answer_hash VARCHAR(255),
    security_q2_id          INTEGER     REFERENCES iacra.security_questions(question_id),
    security_q2_answer_hash VARCHAR(255),
    password_reset_token    VARCHAR(255),
    password_reset_expires_at TIMESTAMPTZ,
    last_login_at           TIMESTAMPTZ,
    last_login_ip           INET,
    tos_accepted            BOOLEAN     NOT NULL DEFAULT FALSE,
    tos_accepted_at         TIMESTAMPTZ,
    tos_version             VARCHAR(20),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_user_accounts_ftn ON iacra.user_accounts(ftn);

-- -----------------------------------------------------------------------------
-- USER ROLES
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.user_roles (
    user_role_id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID        NOT NULL REFERENCES iacra.user_accounts(user_id),
    role_type               iacra.role_type NOT NULL,
    role_status             VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (role_status IN ('ACTIVE','INACTIVE','SUSPENDED')),
    role_assigned_date      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    role_removed_date       TIMESTAMPTZ,
    certificate_number      VARCHAR(20),
    certificate_issue_date  DATE,
    designee_number         VARCHAR(20),
    school_certificate_number VARCHAR(20),
    school_designation_code VARCHAR(10),
    nvis_validated          BOOLEAN,
    nvis_validation_date    TIMESTAMPTZ,
    school_admin_validated_by UUID REFERENCES iacra.user_accounts(user_id),
    school_admin_validation_date TIMESTAMPTZ,
    piv_card_number         VARCHAR(50),
    piv_validated_at        TIMESTAMPTZ,
    aircraft_type_rating    VARCHAR(10),
    UNIQUE (user_id, role_type)
);
CREATE INDEX idx_user_roles_user ON iacra.user_roles(user_id);

-- -----------------------------------------------------------------------------
-- APPLICATIONS (central form record)
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.applications (
    application_id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    ftn                     VARCHAR(12) NOT NULL REFERENCES iacra.airmen(ftn),
    form_type               iacra.form_type NOT NULL,
    omb_control_number      VARCHAR(20),
    application_type        VARCHAR(50) NOT NULL,  -- Pilot, Crewmember, Airworthiness, MechanicRepairman, Dispatcher
    application_status      iacra.application_status NOT NULL DEFAULT 'DRAFT',
    certificate_type_sought iacra.certificate_type,
    category_class_sought   VARCHAR(50),
    type_rating_sought      VARCHAR(50),
    restricted_privileges   BOOLEAN     NOT NULL DEFAULT FALSE,
    path_type               iacra.path_type,
    graduation_date_121_135 DATE,
    training_program_name   VARCHAR(255),
    military_competency_type VARCHAR(30),
    current_step            SMALLINT    NOT NULL DEFAULT 1 CHECK (current_step BETWEEN 1 AND 6),
    step_1_complete         BOOLEAN     NOT NULL DEFAULT FALSE,
    step_2_complete         BOOLEAN     NOT NULL DEFAULT FALSE,
    step_3_complete         BOOLEAN     NOT NULL DEFAULT FALSE,
    step_4_complete         BOOLEAN     NOT NULL DEFAULT FALSE,
    step_5_complete         BOOLEAN     NOT NULL DEFAULT FALSE,
    step_6_complete         BOOLEAN     NOT NULL DEFAULT FALSE,
    validation_status       JSONB,
    application_submitted_date TIMESTAMPTZ,
    application_deleted_date TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_applications_ftn    ON iacra.applications(ftn);
CREATE INDEX idx_applications_status ON iacra.applications(application_status);
CREATE INDEX idx_applications_ftn_status ON iacra.applications(ftn, application_status);

-- -----------------------------------------------------------------------------
-- BIOGRAPHIC / REQUIRED QUESTION DETAIL
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.application_biographic_detail (
    biographic_detail_id    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id) ON DELETE CASCADE,
    drug_conviction_disclosed BOOLEAN,
    drug_conviction_date    DATE,
    drug_conviction_detail  TEXT,
    english_language_capable BOOLEAN,
    english_language_noncert_reason BOOLEAN,
    prior_failures          BOOLEAN,
    prior_failures_detail   TEXT,
    primary_id_type         VARCHAR(30) CHECK (primary_id_type IN
        ('US_DRIVER_LICENSE','PASSPORT','MILITARY_ID','STUDENT_ID','OTHER_GOV_ID')),
    primary_id_number       VARCHAR(50),
    primary_id_state        CHAR(2),
    primary_id_country      VARCHAR(100),
    primary_id_expiration_date DATE,
    UNIQUE (application_id)
);

-- -----------------------------------------------------------------------------
-- PILOT TIME / EXPERIENCE
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.pilot_time_records (
    pilot_time_record_id    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id) ON DELETE CASCADE,
    aircraft_sequence       SMALLINT    NOT NULL CHECK (aircraft_sequence IN (1,2)),
    aircraft_make_model     VARCHAR(200) NOT NULL,
    aircraft_category_class VARCHAR(50),
    total_hours             NUMERIC(6,1) NOT NULL,
    pic_hours               NUMERIC(6,1),
    sic_hours               NUMERIC(6,1),
    instrument_hours        NUMERIC(6,1),
    night_hours             NUMERIC(6,1),
    cross_country_hours     NUMERIC(6,1),
    simulator_device_used   BOOLEAN     NOT NULL DEFAULT FALSE,
    simulator_device_type   VARCHAR(100),
    simulator_device_hours  NUMERIC(6,1),
    imported_from_application_id UUID REFERENCES iacra.applications(application_id),
    import_date             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_pilot_time_application ON iacra.pilot_time_records(application_id);

-- -----------------------------------------------------------------------------
-- PRIOR CERTIFICATES HELD
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.prior_certificates (
    prior_certificate_id    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id) ON DELETE CASCADE,
    source_system           VARCHAR(30) NOT NULL CHECK (source_system IN ('AIRMAN_REGISTRY','USER_SUPPLIED')),
    certificate_type        VARCHAR(100) NOT NULL,
    category_class_rating   VARCHAR(50),
    type_rating             VARCHAR(50),
    certificate_number      VARCHAR(20) NOT NULL,
    certificate_issue_date  DATE         NOT NULL,
    restrictions_limitations TEXT,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_prior_certs_application ON iacra.prior_certificates(application_id);

-- -----------------------------------------------------------------------------
-- MEDICAL CERTIFICATE (self-attested)
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.medical_certificates (
    medical_cert_id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id) ON DELETE CASCADE,
    has_medical_certificate BOOLEAN     NOT NULL,
    medical_cert_class      iacra.medical_class,
    date_of_issue           DATE,
    examiner_name           VARCHAR(255),
    dob_check               BOOLEAN,
    expiration_date         DATE,
    UNIQUE (application_id)
);

-- -----------------------------------------------------------------------------
-- KNOWLEDGE TESTS (ingested from Atlas Aviation via linked-server)
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.knowledge_test_results (
    knowledge_test_id       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    ftn                     VARCHAR(12) NOT NULL REFERENCES iacra.airmen(ftn),
    exam_title              VARCHAR(200),
    exam_id                 VARCHAR(50) NOT NULL,
    exam_date               DATE        NOT NULL,
    test_site               VARCHAR(100),
    score                   SMALLINT,
    grade                   VARCHAR(10),
    number_of_attempts      SMALLINT,
    test_expiration_date    DATE,
    is_expired              BOOLEAN     GENERATED ALWAYS AS (test_expiration_date < CURRENT_DATE) STORED,
    missed_subject_areas    TEXT,
    sync_date_from_atlas    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    linked_application_id   UUID REFERENCES iacra.applications(application_id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_knowledge_tests_ftn  ON iacra.knowledge_test_results(ftn);
CREATE INDEX idx_knowledge_tests_exp  ON iacra.knowledge_test_results(test_expiration_date);
COMMENT ON TABLE iacra.knowledge_test_results IS 'Synced from Atlas Aviation via SQL linked-server (legacy). Tests valid 24 months.';

-- -----------------------------------------------------------------------------
-- PRACTICAL TESTS
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.practical_tests (
    practical_test_id       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id) ON DELETE CASCADE,
    test_status             VARCHAR(30) NOT NULL DEFAULT 'SCHEDULED'
        CHECK (test_status IN ('SCHEDULED','IN_PROGRESS','COMPLETED','DISCONTINUED','DISAPPROVED')),
    test_date               DATE,
    test_location           VARCHAR(200),
    airport_id              VARCHAR(10),
    oral_duration_hours     NUMERIC(4,2),
    practical_duration_hours NUMERIC(4,2),
    second_aircraft_used    BOOLEAN     NOT NULL DEFAULT FALSE,
    test_aircraft_1_n_number VARCHAR(10),
    test_aircraft_1_make_model VARCHAR(200),
    test_aircraft_1_serial   VARCHAR(50),
    test_aircraft_2_n_number VARCHAR(10),
    test_aircraft_2_make_model VARCHAR(200),
    test_aircraft_2_serial   VARCHAR(50),
    designee_user_id        UUID REFERENCES iacra.user_accounts(user_id),
    designee_number         VARCHAR(20),
    designee_type           VARCHAR(20),
    designee_name           VARCHAR(200),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_practical_tests_app ON iacra.practical_tests(application_id);

CREATE TABLE iacra.practical_test_outcomes (
    outcome_id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    practical_test_id       UUID        NOT NULL REFERENCES iacra.practical_tests(practical_test_id) ON DELETE CASCADE,
    outcome_result          iacra.practical_outcome NOT NULL,
    outcome_date            TIMESTAMPTZ NOT NULL,
    failure_reason_code     VARCHAR(50),
    failure_reason_narrative TEXT,
    areas_of_operation_failed JSONB,
    prior_limitations_from_registry JSONB,
    new_limitations_added   JSONB,
    mandatory_limitations   JSONB,
    co_user_id              UUID        REFERENCES iacra.user_accounts(user_id),
    co_signature_date       TIMESTAMPTZ,
    co_digital_signature_token VARCHAR(255),
    co_designated_fsdo      VARCHAR(100)
);

-- -----------------------------------------------------------------------------
-- RECOMMENDING INSTRUCTOR ENDORSEMENTS
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.recommending_instructor_endorsements (
    ri_endorsement_id       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id) ON DELETE CASCADE,
    ri_user_id              UUID        NOT NULL REFERENCES iacra.user_accounts(user_id),
    ri_name                 VARCHAR(200) NOT NULL,
    ri_certificate_number   VARCHAR(20),
    ri_checklist_completed  BOOLEAN     NOT NULL DEFAULT FALSE,
    ri_checklist_completion_date TIMESTAMPTZ,
    ri_endorsement_date     TIMESTAMPTZ,
    ri_digital_signature    VARCHAR(255),
    ri_return_reason        TEXT,
    ri_forwarded_to_examiner_date TIMESTAMPTZ,
    flight_hours_verified   BOOLEAN,
    min_flight_hours_met    BOOLEAN,
    required_maneuvers_practiced BOOLEAN,
    cross_country_met       BOOLEAN,
    dual_instruction_complete BOOLEAN,
    solo_time_met           BOOLEAN
);
CREATE INDEX idx_ri_endorsements_app ON iacra.recommending_instructor_endorsements(application_id);

-- -----------------------------------------------------------------------------
-- SCHOOL ADMINISTRATION (141/142)
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.school_administrations (
    school_admin_id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_role_id            UUID        NOT NULL REFERENCES iacra.user_roles(user_role_id),
    school_certificate_number VARCHAR(20) NOT NULL,
    school_designation_code VARCHAR(10) NOT NULL,
    school_name             VARCHAR(255),
    school_is_active        BOOLEAN     NOT NULL DEFAULT TRUE,
    part_141_or_142         VARCHAR(10) NOT NULL CHECK (part_141_or_142 IN ('PART_141','PART_142')),
    affiliated_student_ftn  VARCHAR(12) REFERENCES iacra.airmen(ftn),
    affiliation_date        TIMESTAMPTZ,
    affiliation_last_name_match VARCHAR(100),
    curriculum_associated   BOOLEAN     NOT NULL DEFAULT FALSE,
    curriculum_id           VARCHAR(100),
    curriculum_selected_date TIMESTAMPTZ
);

-- -----------------------------------------------------------------------------
-- DOCUMENT / ARTIFACT
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.application_documents (
    document_id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id) ON DELETE CASCADE,
    document_type           VARCHAR(50) NOT NULL
        CHECK (document_type IN ('APPLICATION_FORM','UPLOADED','ENDORSEMENT',
                                 'MEDICAL_CERT','KNOWLEDGE_TEST_REPORT','CERT_OF_COMPLETION')),
    document_format         VARCHAR(10) NOT NULL,
    document_file_path      VARCHAR(500),
    document_file_size_bytes BIGINT,
    document_file_hash_sha256 CHAR(64),
    upload_date             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    document_page_count     SMALLINT,
    ocr_extracted_text      TEXT,
    uploaded_by_user_id     UUID REFERENCES iacra.user_accounts(user_id),
    is_corrected_version    BOOLEAN     NOT NULL DEFAULT FALSE,
    supersedes_document_id  UUID REFERENCES iacra.application_documents(document_id),
    correction_reason       TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_app_documents_app ON iacra.application_documents(application_id);

-- -----------------------------------------------------------------------------
-- CERTIFICATES ISSUED (temp + permanent)
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.airman_certificates_issued (
    certificate_issued_id   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id),
    airman_id               UUID        NOT NULL REFERENCES iacra.airmen(airman_id),
    certificate_type_issued iacra.certificate_type NOT NULL,
    category_class_issued   VARCHAR(50),
    type_rating_issued      VARCHAR(50),
    restrictions_limitations JSONB,
    certificate_number_issued VARCHAR(20),
    certificate_issue_date_cais DATE,
    temporary_cert_issued_date TIMESTAMPTZ,
    temporary_cert_expiration_date DATE,
    temporary_cert_number    VARCHAR(20),
    permanent_cert_received_date DATE,
    is_valid                BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_certs_issued_airman ON iacra.airman_certificates_issued(airman_id);

-- -----------------------------------------------------------------------------
-- TSA VETTING
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.tsa_vetting_records (
    tsa_vetting_id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id),
    airman_ftn              VARCHAR(12) NOT NULL REFERENCES iacra.airmen(ftn),
    tsa_vetting_required    BOOLEAN     NOT NULL DEFAULT FALSE,
    tsa_submission_date     TIMESTAMPTZ,
    tsa_status              iacra.tsa_status NOT NULL DEFAULT 'PENDING',
    tsa_approval_date       DATE,
    tsa_reference_number    VARCHAR(50),
    tsa_denial_reason       TEXT,
    tsa_denial_appeal_available BOOLEAN,
    tsa_vetting_expiration_date DATE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE iacra.tsa_vetting_records IS 'TSA NTSDB vetting — required for foreign students and flight training applicants.';

-- -----------------------------------------------------------------------------
-- APPLICATION STATE HISTORY + AUDIT
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.application_state_history (
    state_history_id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id) ON DELETE CASCADE,
    previous_status         iacra.application_status,
    new_status              iacra.application_status NOT NULL,
    status_change_date      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status_change_user_id   UUID REFERENCES iacra.user_accounts(user_id),
    status_change_reason    TEXT,
    status_change_ip_address INET
);
CREATE INDEX idx_state_history_app ON iacra.application_state_history(application_id);

CREATE TABLE iacra.audit_log (
    audit_log_id            BIGSERIAL   PRIMARY KEY,
    event_type              VARCHAR(50) NOT NULL,
    event_date              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id                 UUID REFERENCES iacra.user_accounts(user_id),
    ftn                     VARCHAR(12),
    application_id          UUID REFERENCES iacra.applications(application_id),
    event_details           JSONB,
    ip_address              INET,
    user_agent              TEXT
);
CREATE INDEX idx_iacra_audit_date ON iacra.audit_log(event_date DESC);
CREATE INDEX idx_iacra_audit_user ON iacra.audit_log(user_id);

-- -----------------------------------------------------------------------------
-- DESIGNEE REGISTRY (read from DMS)
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.designee_registry (
    designee_id             SERIAL      PRIMARY KEY,
    designee_number         VARCHAR(20) NOT NULL UNIQUE,
    designee_name           VARCHAR(255) NOT NULL,
    designee_type           VARCHAR(20) NOT NULL,
    certificate_number      VARCHAR(20),
    authorized_certificate_types TEXT[],
    authorized_aircraft_types TEXT[],
    is_active               BOOLEAN     NOT NULL DEFAULT TRUE,
    activation_date         DATE,
    deactivation_date       DATE
);

-- -----------------------------------------------------------------------------
-- INTEGRATION LOGS
-- -----------------------------------------------------------------------------

CREATE TABLE iacra.cais_handoff_records (
    handoff_id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id          UUID        NOT NULL REFERENCES iacra.applications(application_id),
    tiff_render_date        TIMESTAMPTZ,
    tiff_file_path          VARCHAR(500),
    tiff_file_size_bytes    BIGINT,
    ftp_submission_date     TIMESTAMPTZ,
    ftp_submission_status   VARCHAR(30) NOT NULL DEFAULT 'PENDING'
        CHECK (ftp_submission_status IN ('PENDING','TRANSMITTED','ACKNOWLEDGED','ERROR','RETRYING')),
    cais_acknowledgment_date TIMESTAMPTZ,
    cais_ingestion_status   VARCHAR(30),
    cais_error_message      TEXT,
    ftp_retry_count         INTEGER     NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_cais_handoff_status ON iacra.cais_handoff_records(ftp_submission_status);

CREATE TABLE iacra.external_system_syncs (
    sync_id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    external_system         VARCHAR(50) NOT NULL,
    sync_direction          VARCHAR(20) NOT NULL CHECK (sync_direction IN ('INBOUND','OUTBOUND','BIDIRECTIONAL')),
    sync_date               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sync_status             VARCHAR(30) NOT NULL,
    records_processed       INTEGER,
    records_failed          INTEGER,
    error_detail            TEXT,
    next_retry_scheduled    TIMESTAMPTZ
);

-- =============================================================================
-- END OF IACRA SCHEMA
-- =============================================================================
