-- =============================================================================
-- DMS — Designee Management System
-- Current-State Schema
-- =============================================================================
-- Authority: 14 CFR Part 183; FAA Order 8000.95D.
-- Purpose: registry for FAA-designated representatives (13 categories) from
--   appointment through termination. Covers DPE, SAE, Admin PE, DME, DPRE,
--   DADE, TCE, APD, DAR-T, DAR-F, DMIR, DER, AME (plus ODA/ODAR/ACSEP/TCSEP).
-- Retention: 25 years after inactive (NARA DAA-0237-2020-0013).
-- FIPS 199: MODERATE. Privacy Act SORN: DOT/FAA 830.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS dms;
SET search_path TO dms, public;

-- -----------------------------------------------------------------------------
-- ENUMERATED TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE dms.designee_type_code AS ENUM (
    'DPE',       -- Designated Pilot Examiner
    'SAE',       -- Specialty Aircraft Examiner
    'ADMIN_PE',  -- Administrative Pilot Examiner
    'DME',       -- Designated Mechanic Examiner
    'DPRE',      -- Designated Parachute Rigger Examiner
    'DADE',      -- Designated Aircraft Dispatcher Examiner
    'TCE',       -- Training Center Evaluator
    'APD',       -- Aircrew Program Designee
    'DAR_T',     -- Designated Airworthiness Rep — Maintenance
    'DAR_F',     -- Designated Airworthiness Rep — Manufacturing
    'DMIR',      -- Designated Manufacturing Inspection Rep
    'DER',       -- Designated Engineering Representative
    'AME',       -- Aviation Medical Examiner
    'IA',        -- Inspection Authorization
    'ODA',       -- Organization Designation Authorization
    'ODAR',      -- Organizational DAR
    'ACSEP',
    'TCSEP',
    'SFAR'
);

CREATE TYPE dms.designation_status AS ENUM (
    'APPLICANT',
    'ACTIVE',
    'SUSPENDED',
    'TERMINATED',
    'REINSTATED',
    'EXPIRED'
);

CREATE TYPE dms.termination_type AS ENUM (
    'VOLUNTARY_SURRENDER',
    'NOT_FOR_CAUSE',
    'FOR_CAUSE',
    'EXPIRED',
    'REINSTATEMENT_DENIED',
    'NON_SUBMITTAL'
);

CREATE TYPE dms.application_status AS ENUM (
    'SUBMITTED','IN_PROGRESS','PENDING_SELECTION',
    'SELECTED','EVALUATED','APPOINTED','REJECTED','WITHDRAWN','EXPIRED'
);

CREATE TYPE dms.activity_type AS ENUM (
    'DIRECT_OBSERVATION',
    'COUNSELING',
    'RECORD_FEEDBACK',
    'TRAINING_RECORD',
    'OVERALL_PERFORMANCE_EVALUATION',
    'SUSPEND',
    'TERMINATE'
);

CREATE TYPE dms.evaluation_rating AS ENUM (
    'SATISFACTORY',
    'NEEDS_IMPROVEMENT',
    'UNSATISFACTORY'
);

CREATE TYPE dms.overall_rating AS ENUM (
    'SATISFACTORY',
    'NEEDS_IMPROVEMENT',
    'UNSATISFACTORY_SUSPEND',
    'UNSATISFACTORY_REDUCE_RESTRICT',
    'UNSATISFACTORY_TERMINATE'
);

CREATE TYPE dms.preapproval_status AS ENUM (
    'INITIATED','SAVED','PENDING','APPROVED','DENIED','CANCELED','EXPIRED'
);

CREATE TYPE dms.post_activity_status AS ENUM (
    'INITIATED','SAVED','COMPLETED','OVERDUE'
);

CREATE TYPE dms.activity_test_result AS ENUM (
    'PASS','FAIL','INCONCLUSIVE','NOT_CONDUCTED'
);

CREATE TYPE dms.corrective_action_status AS ENUM (
    'ASSIGNED','RESPONDED','ACCEPTED','RETURNED_FOR_MORE_INFO','DECLINED','COMPLETED'
);

CREATE TYPE dms.suspension_status AS ENUM ('ACTIVE','RELEASED','CONVERTED_TO_TERMINATION');

CREATE TYPE dms.office_type AS ENUM ('FSDO','IFO','AEG','ACO','RHQ');

CREATE TYPE dms.message_type AS ENUM ('SYSTEM_NOTIFICATION','USER_MESSAGE','FORMAL_NOTICE');

-- -----------------------------------------------------------------------------
-- REFERENCE DATA
-- -----------------------------------------------------------------------------

CREATE TABLE dms.designee_types (
    designee_type_code   dms.designee_type_code PRIMARY KEY,
    designee_full_name   VARCHAR(255) NOT NULL,
    responsible_office   VARCHAR(100) NOT NULL,    -- AFS, AIR, AAM
    regulatory_reference VARCHAR(100) NOT NULL,    -- 14 CFR 183 / Order 8000.95D
    authority_scope      TEXT         NOT NULL,
    eligibility_requirements TEXT,
    renewal_cycle_months SMALLINT     NOT NULL DEFAULT 12,
    max_type_ratings_per_auth SMALLINT DEFAULT 75,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE dms.designee_types IS '13+ designee categories with authority and renewal rules.';

CREATE TABLE dms.managing_offices (
    office_code       VARCHAR(20)  PRIMARY KEY,
    office_name       VARCHAR(255) NOT NULL,
    office_type       dms.office_type NOT NULL,
    responsible_service VARCHAR(20) NOT NULL CHECK (responsible_service IN ('AFS','AIR','AAM')),
    region            VARCHAR(100),
    state_code        CHAR(2),
    phone             VARCHAR(30),
    email             VARCHAR(255),
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE dms.function_codes (
    function_code        VARCHAR(10)  PRIMARY KEY,
    description          VARCHAR(500) NOT NULL,
    applicable_designee_types dms.designee_type_code[] NOT NULL,
    scope_notes          TEXT,
    is_active            BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE dms.function_codes IS 'A1, A2, B1, ... authority scope codes per designee type.';

-- -----------------------------------------------------------------------------
-- DESIGNEES (core individuals)
-- -----------------------------------------------------------------------------

CREATE TABLE dms.designees (
    designee_id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designee_number             VARCHAR(9)   NOT NULL UNIQUE,
    ftn                         VARCHAR(12),
    username                    VARCHAR(100) UNIQUE,
    email                       VARCHAR(255) NOT NULL UNIQUE,
    password_hash               VARCHAR(255),      -- deprecated; migrating to Login.gov
    security_question_id        INTEGER,
    legal_name_first            VARCHAR(100) NOT NULL,
    legal_name_last             VARCHAR(100) NOT NULL,
    legal_name_suffix           VARCHAR(20),
    date_of_birth               DATE         NOT NULL,
    gender                      CHAR(1),
    citizenship_country         CHAR(2)      NOT NULL DEFAULT 'US',
    airman_certificate_number   VARCHAR(20),
    airman_certificate_issue_date DATE,
    phone_primary               VARCHAR(30),
    phone_secondary             VARCHAR(30),
    personal_mailing_address    TEXT,
    personal_physical_address   TEXT,
    designation_location_address TEXT,
    designation_location_office VARCHAR(20) REFERENCES dms.managing_offices(office_code),
    photograph_uri              VARCHAR(2048),
    medical_license_number      VARCHAR(50),        -- AME only
    medical_license_issuing_state CHAR(2),          -- AME only
    npi_number                  VARCHAR(20),        -- AME only
    references_json             JSONB,              -- up to 3 character + 3 technical
    employer_name               VARCHAR(255),
    employer_poc_name           VARCHAR(200),
    employer_poc_phone          VARCHAR(30),
    last_validation_date        DATE,
    created_at                  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_designees_number ON dms.designees(designee_number);
CREATE INDEX idx_designees_email  ON dms.designees(email);
CREATE INDEX idx_designees_name   ON dms.designees(legal_name_last, legal_name_first);
COMMENT ON TABLE  dms.designees IS 'Individual designees — one Designee Number per person across all types held.';
COMMENT ON COLUMN dms.designees.last_validation_date IS 'Order 8000.95D V1 Ch2 — designee must validate profile every 12 months.';

-- -----------------------------------------------------------------------------
-- DESIGNATIONS (one per designee-type held; one designee may hold many)
-- -----------------------------------------------------------------------------

CREATE TABLE dms.designations (
    designation_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designee_id            UUID         NOT NULL REFERENCES dms.designees(designee_id),
    designee_type_code     dms.designee_type_code NOT NULL REFERENCES dms.designee_types(designee_type_code),
    status                 dms.designation_status NOT NULL DEFAULT 'APPLICANT',
    effective_date         DATE,
    expiration_date        DATE,
    termination_date       DATE,
    termination_type       dms.termination_type,
    managing_office_code   VARCHAR(20)  REFERENCES dms.managing_offices(office_code),
    managing_specialist_name VARCHAR(200),
    managing_specialist_email VARCHAR(255),
    appointing_official_name VARCHAR(200),
    appointing_official_email VARCHAR(255),
    flag_publish_to_locator BOOLEAN     NOT NULL DEFAULT TRUE,
    initial_appointment_date DATE,
    renewal_count          INTEGER      NOT NULL DEFAULT 0,
    cloa_version_current   INTEGER      NOT NULL DEFAULT 0,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (designee_id, designee_type_code),
    CONSTRAINT chk_term_fields CHECK (
        (status <> 'TERMINATED') OR (termination_date IS NOT NULL AND termination_type IS NOT NULL)
    )
);
CREATE INDEX idx_designations_designee ON dms.designations(designee_id);
CREATE INDEX idx_designations_status   ON dms.designations(status);
CREATE INDEX idx_designations_expiry   ON dms.designations(expiration_date);
CREATE INDEX idx_designations_office   ON dms.designations(managing_office_code);

-- -----------------------------------------------------------------------------
-- CLOAs — Certificates of Letter of Authority
-- -----------------------------------------------------------------------------

CREATE TABLE dms.cloas (
    cloa_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id         UUID         NOT NULL REFERENCES dms.designations(designation_id),
    cloa_version           INTEGER      NOT NULL,
    generated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    effective_date         DATE         NOT NULL,
    expiration_date        DATE         NOT NULL,
    function_codes_json    JSONB        NOT NULL,   -- [{code, description}]
    limitations_json       JSONB,
    authorized_make_model_series_json JSONB,
    authorized_type_ratings_json JSONB,
    authority_start_date   DATE,
    authority_end_date     DATE,
    document_uri           VARCHAR(2048),
    revoked_date           DATE,
    is_active              BOOLEAN      NOT NULL DEFAULT TRUE,
    UNIQUE (designation_id, cloa_version)
);
CREATE INDEX idx_cloas_designation ON dms.cloas(designation_id);
CREATE UNIQUE INDEX idx_cloas_one_active_per_designation
    ON dms.cloas(designation_id) WHERE is_active = TRUE;
COMMENT ON TABLE dms.cloas IS 'Immutable per version; new versions on authority changes, annual extension, location change.';

-- -----------------------------------------------------------------------------
-- DESIGNEE AUTHORIZATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.designee_authorizations (
    auth_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id         UUID         NOT NULL REFERENCES dms.designations(designation_id),
    function_code          VARCHAR(10)  NOT NULL REFERENCES dms.function_codes(function_code),
    authorization_name     VARCHAR(255),
    auto_approval_enabled  BOOLEAN      NOT NULL DEFAULT FALSE,
    make_model_series_json JSONB,
    effective_date         DATE         NOT NULL,
    expiration_date        DATE,
    cloa_version_granted   INTEGER,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (designation_id, function_code)
);
CREATE INDEX idx_auths_designation ON dms.designee_authorizations(designation_id);

-- -----------------------------------------------------------------------------
-- APPLICATIONS (applicant to become designee)
-- -----------------------------------------------------------------------------

CREATE TABLE dms.applications (
    application_id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designee_id                    UUID         REFERENCES dms.designees(designee_id),
    designee_type_requested        dms.designee_type_code NOT NULL,
    application_status             dms.application_status NOT NULL DEFAULT 'SUBMITTED',
    submission_date                DATE         NOT NULL DEFAULT CURRENT_DATE,
    last_validation_date           DATE,
    expiration_date_applicant_pool DATE,
    background_questions_json      JSONB,
    eligible_for_appointment       BOOLEAN,
    documents_json                 JSONB,
    selecting_officer_name         VARCHAR(200),
    selecting_officer_email        VARCHAR(255),
    evaluation_panel_lead_name     VARCHAR(200),
    evaluation_checklist_json      JSONB,
    evaluation_date                DATE,
    evaluation_notes               TEXT,
    created_at                     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_applications_designee ON dms.applications(designee_id);
CREATE INDEX idx_applications_status   ON dms.applications(application_status);

-- -----------------------------------------------------------------------------
-- PRE-APPROVAL REQUESTS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.pre_approval_requests (
    pre_approval_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id               UUID         NOT NULL REFERENCES dms.designations(designation_id),
    status                       dms.preapproval_status NOT NULL DEFAULT 'INITIATED',
    requested_date               DATE         NOT NULL DEFAULT CURRENT_DATE,
    approval_date                TIMESTAMPTZ,
    activity_type                VARCHAR(50)  NOT NULL
        CHECK (activity_type IN ('PRACTICAL_TEST','PROFICIENCY_CHECK','ADMINISTRATIVE','SPECIAL_AUTHORIZATION')),
    authorization_function_code  VARCHAR(10)  REFERENCES dms.function_codes(function_code),
    temporary_authorization      BOOLEAN      NOT NULL DEFAULT FALSE,
    applicant_ftn                VARCHAR(12),
    applicant_name               VARCHAR(200),
    applicant_certificate_number VARCHAR(20),
    test_date                    DATE,
    location_facility            VARCHAR(255),
    facility_address             TEXT,
    basis_type                   VARCHAR(50)
        CHECK (basis_type IN ('APPROVED_COURSE_GRADUATE','FOREIGN_LICENSE_HOLDER','AIR_CARRIER_TRAINING_PROGRAM','OTHER')),
    approved_course_school       VARCHAR(255),
    foreign_license_country      VARCHAR(100),
    air_carrier_name             VARCHAR(255),
    ground_only                  BOOLEAN      NOT NULL DEFAULT FALSE,
    flight_portion               BOOLEAN      NOT NULL DEFAULT FALSE,
    fstd_used                    BOOLEAN      NOT NULL DEFAULT FALSE,
    fstd_id_and_mms              VARCHAR(255),
    aircraft_n_number            VARCHAR(10),
    aircraft_mms                 VARCHAR(200),
    aircraft_airline_flight_num  VARCHAR(50),
    recommending_instructor_name VARCHAR(200),
    recommending_instructor_cert VARCHAR(20),
    time_zone                    VARCHAR(30)  NOT NULL DEFAULT 'GMT-06:00',
    comments                     TEXT,
    attached_documents_json      JSONB,
    auto_approval_applied        BOOLEAN      NOT NULL DEFAULT FALSE,
    approved_by_name             VARCHAR(200),
    approved_by_email            VARCHAR(255),
    created_at                   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_test_date_future CHECK (test_date IS NULL OR test_date >= CURRENT_DATE OR status IN ('APPROVED','DENIED','CANCELED','EXPIRED'))
);
CREATE INDEX idx_preapproval_designation ON dms.pre_approval_requests(designation_id);
CREATE INDEX idx_preapproval_status      ON dms.pre_approval_requests(status);
CREATE INDEX idx_preapproval_test_date   ON dms.pre_approval_requests(test_date);

-- -----------------------------------------------------------------------------
-- POST-ACTIVITY REPORTS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.post_activity_reports (
    post_activity_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    pre_approval_request_id    UUID         NOT NULL REFERENCES dms.pre_approval_requests(pre_approval_id),
    status                     dms.post_activity_status NOT NULL DEFAULT 'INITIATED',
    submitted_date             DATE,
    due_date                   DATE         NOT NULL,
    is_overdue                 BOOLEAN      GENERATED ALWAYS AS
        (submitted_date IS NULL AND CURRENT_DATE > due_date) STORED,
    applicant_name             VARCHAR(200) NOT NULL,
    applicant_certificate_number VARCHAR(20),
    applicant_ftn              VARCHAR(12),
    test_date_actual           DATE,
    test_result                dms.activity_test_result,
    test_duration_minutes      INTEGER,
    testing_notes              TEXT,
    iacra_applicant_id         VARCHAR(50),
    iacra_application_id       VARCHAR(50),
    iacra_auto_populated_date  TIMESTAMPTZ,
    post_activity_comments     TEXT,
    attached_documents_json    JSONB,
    version_number             INTEGER      NOT NULL DEFAULT 1,
    previous_version_id        UUID         REFERENCES dms.post_activity_reports(post_activity_id),
    created_at                 TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_postactivity_preapproval ON dms.post_activity_reports(pre_approval_request_id);
CREATE INDEX idx_postactivity_overdue     ON dms.post_activity_reports(is_overdue);
COMMENT ON TABLE dms.post_activity_reports IS '7-day submission deadline; overdue block prevents new pre-approvals.';

-- -----------------------------------------------------------------------------
-- CORRECTIVE ACTIONS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.corrective_actions (
    corrective_action_id     UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id           UUID         NOT NULL REFERENCES dms.designations(designation_id),
    initiated_by_name        VARCHAR(200),
    initiated_by_email       VARCHAR(255),
    initiated_date           DATE         NOT NULL DEFAULT CURRENT_DATE,
    issue_description        TEXT         NOT NULL,
    finding_description      TEXT,
    required_action_plan     TEXT,
    action_due_date          DATE,
    required_attachments_json JSONB,
    status                   dms.corrective_action_status NOT NULL DEFAULT 'ASSIGNED',
    designee_response_text   TEXT,
    designee_supporting_attachments JSONB,
    response_submitted_date  TIMESTAMPTZ,
    response_return_count    INTEGER      NOT NULL DEFAULT 0
        CHECK (response_return_count <= 5),
    reviewed_by_name         VARCHAR(200),
    reviewed_date            TIMESTAMPTZ,
    review_outcome           VARCHAR(30),
    completion_date          DATE,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_corrective_designation ON dms.corrective_actions(designation_id);

-- -----------------------------------------------------------------------------
-- PERFORMANCE EVALUATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.performance_evaluations (
    evaluation_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id           UUID         NOT NULL REFERENCES dms.designations(designation_id),
    evaluation_date          DATE         NOT NULL,
    conducting_inspector_name VARCHAR(200),
    conducting_inspector_email VARCHAR(255),
    evaluation_number        INTEGER      NOT NULL,
    technical_rating         dms.evaluation_rating NOT NULL,
    procedural_rating        dms.evaluation_rating NOT NULL,
    professional_rating      dms.evaluation_rating NOT NULL,
    overall_rating           dms.overall_rating    NOT NULL,
    required_action          VARCHAR(50) CHECK (required_action IN
        ('NONE','OVERSIGHT_PLAN','SUSPEND','REDUCE_AUTHORITY','TERMINATE')),
    next_evaluation_due_date DATE,
    renewal_recommendation   TEXT,
    evaluation_report_uri    VARCHAR(2048),
    findings_json            JSONB,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_evals_designation ON dms.performance_evaluations(designation_id);

-- -----------------------------------------------------------------------------
-- OVERSIGHT ACTIVITIES
-- -----------------------------------------------------------------------------

CREATE TABLE dms.oversight_activities (
    activity_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id      UUID         NOT NULL REFERENCES dms.designations(designation_id),
    activity_type       dms.activity_type NOT NULL,
    start_date          DATE         NOT NULL,
    end_date            DATE,
    procedure_description TEXT,
    objectives          TEXT,
    report_of_findings_uri VARCHAR(2048),
    findings_json       JSONB,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_oversight_designation ON dms.oversight_activities(designation_id);
CREATE INDEX idx_oversight_type        ON dms.oversight_activities(activity_type);

-- -----------------------------------------------------------------------------
-- TRAINING RECORDS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.training_records (
    training_id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id            UUID         NOT NULL REFERENCES dms.designations(designation_id),
    training_course_title     VARCHAR(255) NOT NULL,
    training_type             VARCHAR(30) CHECK (training_type IN
        ('INITIAL','RECURRENT','ORIENTATION','SPECIALTY','REQUIRED','OPTIONAL')),
    completion_date           DATE,
    training_result           VARCHAR(20) CHECK (training_result IN ('PASS','FAIL','IN_PROGRESS','PENDING')),
    next_training_due_date    DATE,
    certificate_uri           VARCHAR(2048),
    training_provider         VARCHAR(200),
    training_enrollment_status VARCHAR(30),
    pay_gov_payment_confirmation VARCHAR(100),
    orientation_completed_flag BOOLEAN,
    orientation_completed_date DATE,
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_training_designation ON dms.training_records(designation_id);

-- -----------------------------------------------------------------------------
-- SUSPENSIONS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.suspensions (
    suspension_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id               UUID         NOT NULL REFERENCES dms.designations(designation_id),
    suspension_initiated_date    DATE         NOT NULL,
    suspension_reason            TEXT         NOT NULL,
    max_suspension_duration_days INTEGER      NOT NULL DEFAULT 180,
    suspension_release_due_date  DATE         GENERATED ALWAYS AS
        (suspension_initiated_date + INTERVAL '180 days') STORED,
    status                       dms.suspension_status NOT NULL DEFAULT 'ACTIVE',
    release_request_justification TEXT,
    release_request_supporting_docs JSONB,
    release_request_submitted_date TIMESTAMPTZ,
    release_request_approved_date TIMESTAMPTZ,
    release_outcome              VARCHAR(20) CHECK (release_outcome IN ('APPROVED','DENIED')),
    if_denied_termination_initiated BOOLEAN  NOT NULL DEFAULT FALSE,
    created_at                   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_suspensions_designation ON dms.suspensions(designation_id);
CREATE INDEX idx_suspensions_release     ON dms.suspensions(suspension_release_due_date);

-- -----------------------------------------------------------------------------
-- TERMINATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.terminations (
    termination_id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id             UUID         NOT NULL REFERENCES dms.designations(designation_id),
    termination_type           dms.termination_type NOT NULL,
    initiator                  VARCHAR(30) CHECK (initiator IN ('DESIGNEE','MANAGING_SPECIALIST')),
    initiated_date             DATE         NOT NULL,
    ms_approval_date           TIMESTAMPTZ,
    final_status               VARCHAR(30) CHECK (final_status IN ('APPROVED','PENDING','DENIED')),
    for_cause_reason           TEXT,
    for_cause_allegations      TEXT,
    for_cause_evidence_json    JSONB,
    designee_response_window_days INTEGER DEFAULT 15,
    designee_response_text     TEXT,
    designee_response_due_date DATE,
    designee_response_submitted_date TIMESTAMPTZ,
    termination_review_panel_assembled_date DATE,
    panel_composition_json     JSONB,
    panel_recommendation_due_date DATE,
    panel_recommendation_json  JSONB,
    appointing_official_final_decision VARCHAR(30),
    final_decision_date        TIMESTAMPTZ,
    reinstatement_eligible_flag BOOLEAN     NOT NULL DEFAULT FALSE,
    reinstatement_eligible_until_date DATE,
    created_at                 TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_terminations_designation ON dms.terminations(designation_id);

-- -----------------------------------------------------------------------------
-- REINSTATEMENT REQUESTS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.reinstatement_requests (
    reinstatement_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id             UUID         NOT NULL REFERENCES dms.designations(designation_id),
    original_termination_date  DATE         NOT NULL,
    reinstatement_request_date DATE         NOT NULL DEFAULT CURRENT_DATE,
    reinstatement_status       VARCHAR(30) NOT NULL DEFAULT 'REQUESTED'
        CHECK (reinstatement_status IN ('REQUESTED','UNDER_REVIEW','APPROVED','DENIED')),
    reinstatement_questions_json JSONB,
    background_questions_json  JSONB,
    supporting_attachments_json JSONB,
    reviewed_by_name           VARCHAR(200),
    reviewed_date              TIMESTAMPTZ,
    approval_date              TIMESTAMPTZ,
    approval_by_name           VARCHAR(200),
    approval_by_email          VARCHAR(255),
    created_at                 TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_reinstatement_window CHECK (
        reinstatement_request_date <= original_termination_date + INTERVAL '1 year'
    )
);
CREATE INDEX idx_reinstatement_designation ON dms.reinstatement_requests(designation_id);

-- -----------------------------------------------------------------------------
-- ANNUAL EXTENSIONS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.annual_extensions (
    extension_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id            UUID         NOT NULL REFERENCES dms.designations(designation_id),
    task_generated_date       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    due_date                  DATE         NOT NULL,
    extension_status          VARCHAR(30)  NOT NULL DEFAULT 'PENDING'
        CHECK (extension_status IN ('PENDING','COMPLETED','EXPIRED','FAILED')),
    designee_action_questions JSONB,
    background_questions      JSONB,
    current_on_training_flag  BOOLEAN,
    no_violation_history_flag BOOLEAN,
    airman_cert_status        JSONB,
    supporting_attachments    JSONB,
    submitted_date            TIMESTAMPTZ,
    reviewed_by_name          VARCHAR(200),
    reviewed_date             TIMESTAMPTZ,
    approval_outcome          VARCHAR(30),
    new_expiration_date       DATE,
    cloa_updated_flag         BOOLEAN      NOT NULL DEFAULT FALSE,
    cloa_version_on_extension INTEGER,
    failure_reason            TEXT,
    notification_sent         BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_extensions_designation ON dms.annual_extensions(designation_id);
CREATE INDEX idx_extensions_due         ON dms.annual_extensions(due_date);

-- -----------------------------------------------------------------------------
-- ADDITIONAL AUTHORIZATION REQUESTS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.additional_authorizations (
    additional_auth_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id            UUID         NOT NULL REFERENCES dms.designations(designation_id),
    status                    VARCHAR(30)  NOT NULL DEFAULT 'REQUESTED'
        CHECK (status IN ('REQUESTED','UNDER_REVIEW','APPROVED','DENIED')),
    requested_date            DATE         NOT NULL DEFAULT CURRENT_DATE,
    existing_function_codes_json JSONB,
    requested_function_codes_json JSONB    NOT NULL,
    justification_comments    TEXT         NOT NULL CHECK (length(justification_comments) <= 4000),
    supplemental_information_sheet_uri VARCHAR(2048),
    supporting_documents_json JSONB,
    documents_attached_date   DATE,
    reviewed_by_name          VARCHAR(200),
    reviewed_date             TIMESTAMPTZ,
    approved_by_name          VARCHAR(200),
    approved_date             TIMESTAMPTZ,
    cloa_updated_flag         BOOLEAN      NOT NULL DEFAULT FALSE,
    cloa_version_on_approval  INTEGER,
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_one_open_additional_auth_per_designation
    ON dms.additional_authorizations(designation_id)
    WHERE status IN ('REQUESTED','UNDER_REVIEW');
COMMENT ON INDEX dms.idx_one_open_additional_auth_per_designation IS 'Only one concurrent Additional Auth request per designation per §4.5.';

-- -----------------------------------------------------------------------------
-- LOCATION CHANGES
-- -----------------------------------------------------------------------------

CREATE TABLE dms.location_changes (
    location_change_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id            UUID         NOT NULL REFERENCES dms.designations(designation_id),
    new_location_address      TEXT         NOT NULL,
    new_faa_office_code       VARCHAR(20)  REFERENCES dms.managing_offices(office_code),
    requested_date            DATE         NOT NULL DEFAULT CURRENT_DATE,
    status                    VARCHAR(30)  NOT NULL DEFAULT 'REQUESTED'
        CHECK (status IN ('REQUESTED','PENDING_MS_REVIEW','PENDING_AO_REVIEW','APPROVED','DENIED')),
    ms_reviewed_date          TIMESTAMPTZ,
    ms_approval_outcome       VARCHAR(20),
    ao_reviewed_date          TIMESTAMPTZ,
    ao_approval_outcome       VARCHAR(20),
    cloa_updated_flag         BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- INVESTIGATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.investigations (
    investigation_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id            UUID         NOT NULL REFERENCES dms.designations(designation_id),
    initiated_date            DATE         NOT NULL,
    initiated_reason          TEXT         NOT NULL,
    evidence_collected_json   JSONB,
    facts_and_circumstances   TEXT,
    dms_record_review_summary TEXT,
    designee_response_text    TEXT,
    criminal_activity_suspected_flag BOOLEAN NOT NULL DEFAULT FALSE,
    referred_to_law_enforcement_flag BOOLEAN NOT NULL DEFAULT FALSE,
    law_enforcement_agency_name VARCHAR(255),
    referral_date             DATE,
    final_decision            TEXT,
    investigation_closed_date DATE,
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE dms.criminal_reports (
    criminal_report_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id            UUID         NOT NULL REFERENCES dms.designations(designation_id),
    report_submitted_date     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    arrest_indictment_date    DATE         NOT NULL,
    charge_description        TEXT         NOT NULL,
    jurisdiction_level        VARCHAR(20) CHECK (jurisdiction_level IN ('LOCAL','STATE','FEDERAL')),
    jurisdictional_authority  VARCHAR(255),
    auto_suspension_triggered BOOLEAN      NOT NULL DEFAULT TRUE,
    investigation_initiated   BOOLEAN      NOT NULL DEFAULT TRUE,
    investigation_id          UUID         REFERENCES dms.investigations(investigation_id),
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE dms.criminal_reports IS '30-day reporting requirement per Order 8000.95D V1 Ch5.';

-- -----------------------------------------------------------------------------
-- FEEDBACK
-- -----------------------------------------------------------------------------

CREATE TABLE dms.feedback_records (
    feedback_id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designation_id            UUID         NOT NULL REFERENCES dms.designations(designation_id),
    feedback_author_name      VARCHAR(200),
    feedback_author_email     VARCHAR(255),
    feedback_date             DATE         NOT NULL DEFAULT CURRENT_DATE,
    feedback_category         VARCHAR(30) CHECK (feedback_category IN
        ('CORRECTIVE','EVALUATIVE','INSTRUCTIONAL','COMPLIMENT','CRITIQUE','SUGGESTION')),
    feedback_text             TEXT         NOT NULL,
    notify_ms_flag            BOOLEAN      NOT NULL DEFAULT FALSE,
    ms_notified_date          TIMESTAMPTZ,
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- MESSAGE CENTER
-- -----------------------------------------------------------------------------

CREATE TABLE dms.messages (
    message_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_designee_id     UUID         REFERENCES dms.designees(designee_id),
    recipient_staff_email     VARCHAR(255),
    sender_designee_id        UUID         REFERENCES dms.designees(designee_id),
    sender_name               VARCHAR(200),
    message_type              dms.message_type NOT NULL,
    subject                   VARCHAR(500) NOT NULL,
    body                      TEXT         NOT NULL,
    sent_timestamp            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    opened_timestamp          TIMESTAMPTZ,
    is_read                   BOOLEAN      NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_messages_recipient ON dms.messages(recipient_designee_id);

-- -----------------------------------------------------------------------------
-- PUBLIC DESIGNEE LOCATOR
-- -----------------------------------------------------------------------------

CREATE TABLE dms.locator_index (
    locator_id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designee_id              UUID         NOT NULL REFERENCES dms.designees(designee_id),
    designation_id           UUID         NOT NULL REFERENCES dms.designations(designation_id),
    designee_name            VARCHAR(255) NOT NULL,
    designation_type         dms.designee_type_code NOT NULL,
    designation_location_address TEXT,
    city                     VARCHAR(100),
    state_code               CHAR(2),
    zip_code                 VARCHAR(20),
    phone                    VARCHAR(30),
    country                  CHAR(2),
    managing_office_code     VARCHAR(20),
    published_flag           BOOLEAN      NOT NULL DEFAULT TRUE,
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_locator_state_type ON dms.locator_index(state_code, designation_type) WHERE published_flag = TRUE;
CREATE INDEX idx_locator_city_state ON dms.locator_index(city, state_code)               WHERE published_flag = TRUE;

-- -----------------------------------------------------------------------------
-- TCE COMPANY ADMINISTRATORS
-- -----------------------------------------------------------------------------

CREATE TABLE dms.company_administrator_roles (
    company_admin_id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designee_id                  UUID         NOT NULL REFERENCES dms.designees(designee_id),
    company_admin_type           VARCHAR(50) NOT NULL DEFAULT 'TRAINING_CENTER_COMPANY_ADMINISTRATOR',
    application_status           VARCHAR(30) CHECK (application_status IN
        ('SUBMITTED','RETURNED_FOR_MODIFICATION','APPROVED','REJECTED')),
    company_admin_questions_json JSONB,
    company_admin_location_office VARCHAR(20) REFERENCES dms.managing_offices(office_code),
    company_admin_contact_info   TEXT,
    supporting_documents_json    JSONB,
    selecting_officer_name       VARCHAR(200),
    selecting_officer_approval_date TIMESTAMPTZ,
    selecting_officer_approval   VARCHAR(20),
    appointing_official_name     VARCHAR(200),
    appointing_official_approval_date TIMESTAMPTZ,
    appointing_official_approval VARCHAR(20),
    created_at                   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE dms.company_admin_reports (
    report_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    company_admin_id       UUID         NOT NULL REFERENCES dms.company_administrator_roles(company_admin_id),
    report_type            VARCHAR(30) CHECK (report_type IN ('OVERSIGHT_ACTIVITY','TRAINING')),
    start_date             DATE         NOT NULL,
    end_date               DATE         NOT NULL,
    designee_status_filter VARCHAR(30),
    oversight_activity_filter VARCHAR(100),
    postal_code_filter     VARCHAR(20),
    city_filter            VARCHAR(100),
    mms_filter             VARCHAR(100),
    report_generated_date  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    report_file_uri        VARCHAR(2048)
);

-- -----------------------------------------------------------------------------
-- IDENTITY PROOFING (MyAccess / Login.gov transition)
-- -----------------------------------------------------------------------------

CREATE TABLE dms.identity_proofing (
    identity_id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    designee_id                 UUID         NOT NULL REFERENCES dms.designees(designee_id),
    legacy_myaccess_username    VARCHAR(100),
    login_gov_uuid              VARCHAR(255) UNIQUE,
    email_verified_by_login_gov BOOLEAN      NOT NULL DEFAULT FALSE,
    identity_proofed_flag       BOOLEAN      NOT NULL DEFAULT FALSE,
    linked_to_myaccess_date     TIMESTAMPTZ,
    first_login_gov_signin_date TIMESTAMPTZ,
    authentication_method_current VARCHAR(30) NOT NULL DEFAULT 'LEGACY_PASSWORD'
        CHECK (authentication_method_current IN ('LEGACY_PASSWORD','LOGIN_GOV'))
);
COMMENT ON TABLE dms.identity_proofing IS 'Login.gov cutover August 4, 2025.';

-- -----------------------------------------------------------------------------
-- AUDIT LOG
-- -----------------------------------------------------------------------------

CREATE TABLE dms.audit_log (
    audit_id       BIGSERIAL   PRIMARY KEY,
    event_time     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    event_type     VARCHAR(100) NOT NULL,
    entity_type    VARCHAR(50)  NOT NULL,
    entity_id      UUID,
    actor_id       VARCHAR(100) NOT NULL,
    actor_role     VARCHAR(50),
    source_ip      INET,
    changes_before JSONB,
    changes_after  JSONB,
    notes          TEXT
);
CREATE INDEX idx_dms_audit_event_time ON dms.audit_log(event_time);
CREATE INDEX idx_dms_audit_entity     ON dms.audit_log(entity_type, entity_id);

-- =============================================================================
-- END OF DMS SCHEMA
-- =============================================================================
