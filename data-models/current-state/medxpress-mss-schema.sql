-- =============================================================================
-- MedXPress / MSS — Current-State Schema (Medical Certification)
-- Covers 6 subsystems:
--   1. MedXPress — Applicant intake (Form 8500-8)
--   2. AMCS      — Aerospace Medical Certification Subsystem (AME exams)
--   3. DIWS      — Document Imaging & Workflow System
--   4. CPDSS     — Covered Position Decision Support (ATCS clearance)
--   5. CAMI      — Civil Aerospace Medical Institute (research)
--   6. AMCD      — Aeromedical Certification Database (airman medical history)
-- Retention: 50 years (NARA N1-237-05-005).
-- FIPS 199: HIGH. SORN: DOT/FAA 856.
-- Privacy: HIPAA + Privacy Act; PII/PHI encrypted at rest (AES-256).
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS mss;
SET search_path TO mss, public;

-- -----------------------------------------------------------------------------
-- ENUMERATED TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE mss.medical_class AS ENUM ('1ST','2ND','3RD');
CREATE TYPE mss.certificate_class AS ENUM (
    '1ST','2ND','3RD',
    'SI_1ST','SI_2ND','SI_3RD',
    'AASI_1ST','AASI_2ND','AASI_3RD'
);
CREATE TYPE mss.application_status AS ENUM (
    'NO_APPLICATION',
    'SUBMITTED',
    'IMPORTED',
    'TRANSMITTED',
    'IN_REVIEW',
    'ACTION_REQUIRED',
    'CERT_ISSUED',
    'DENIED',
    'DISQUALIFIED',
    'EXPIRED'
);
CREATE TYPE mss.exam_status AS ENUM ('IN_PROGRESS','SUBMITTED','TRANSMITTED','LOCKED');
CREATE TYPE mss.disposition AS ENUM ('ISSUE','DENY','DEFER','SI_AASI');
CREATE TYPE mss.ame_status AS ENUM ('ACTIVE','SUSPENDED','TERMINATED','INACTIVE');
CREATE TYPE mss.finding_status AS ENUM ('NORMAL','ABNORMAL','NOT_EXAMINED');
CREATE TYPE mss.si_condition AS ENUM (
    'CARDIAC','DIABETES','MENTAL_HEALTH','NEUROLOGICAL',
    'VISION','HEARING','SUBSTANCE_USE','OTHER'
);
CREATE TYPE mss.si_status AS ENUM (
    'PENDING_FAS','APPROVED','DENIED','EXPIRED','RENEWED','SURRENDERED'
);
CREATE TYPE mss.deferred_status AS ENUM (
    'PENDING_RESPONSE','RESPONSE_RECEIVED','UNDER_REVIEW','RESOLVED'
);
CREATE TYPE mss.denied_status AS ENUM (
    'INITIAL_DENIAL','UNDER_APPEAL','APPEAL_DENIED','APPEAL_GRANTED','CASE_CLOSED'
);
CREATE TYPE mss.queue_type AS ENUM (
    'CAMI_MEDICAL_REVIEW',
    'REGIONAL_FLIGHT_SURGEON',
    'AAM300_HQ',
    'ANOMALY_CHECK',
    'ACTION_REQUIRED',
    'SUPPLEMENTAL_INTAKE',
    'LEGAL_REVIEW'
);

-- -----------------------------------------------------------------------------
-- REFERENCE DATA
-- -----------------------------------------------------------------------------

CREATE TABLE mss.disease_condition_codes (
    condition_code        VARCHAR(20)  PRIMARY KEY,
    icd_10_code           VARCHAR(10),
    condition_name        VARCHAR(255) NOT NULL,
    is_part_67_disqualifying BOOLEAN  NOT NULL DEFAULT FALSE,
    applicable_classes    mss.medical_class[],
    requires_si           BOOLEAN      NOT NULL DEFAULT FALSE,
    si_category           mss.si_condition,
    disposition_table_ref VARCHAR(100),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE mss.disease_condition_codes IS 'ICD-10 + Part 67 disqualifying conditions.';

CREATE TABLE mss.medications (
    medication_id         BIGSERIAL    PRIMARY KEY,
    medication_name       VARCHAR(255) NOT NULL,
    generic_name          VARCHAR(255),
    ndc_code              VARCHAR(20),
    is_contraindicated    BOOLEAN      NOT NULL DEFAULT FALSE,
    applicable_classes    mss.medical_class[],
    stability_requirement VARCHAR(255),
    fda_status_as_of      DATE,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE mss.document_type_taxonomy (
    doc_type_id           VARCHAR(50)  PRIMARY KEY,
    doc_type_name         VARCHAR(255) NOT NULL,
    category_group        VARCHAR(100) NOT NULL,
    is_pilot_applicable   BOOLEAN      NOT NULL DEFAULT TRUE,
    is_atc_applicable     BOOLEAN      NOT NULL DEFAULT FALSE,
    required_for_conditions TEXT[],
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE mss.document_type_taxonomy IS '~80 DIWS document categories.';

CREATE TABLE mss.sorn_856_routine_uses (
    routine_use_id        SERIAL       PRIMARY KEY,
    routine_use_name      VARCHAR(255) NOT NULL,
    disclosure_reason     TEXT         NOT NULL,
    authorized_recipient  VARCHAR(255) NOT NULL,
    encryption_required   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- APPLICANTS (accounts)
-- -----------------------------------------------------------------------------

CREATE TABLE mss.applicants (
    applicant_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    username              VARCHAR(100) NOT NULL UNIQUE,
    email                 VARCHAR(255) NOT NULL UNIQUE,
    email_verified        BOOLEAN      NOT NULL DEFAULT FALSE,
    password_hash         VARCHAR(255) NOT NULL,
    security_questions    JSONB,
    status                VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','INACTIVE','DELETED_UNSUBMITTED_30D','LOCKED')),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    last_login_at         TIMESTAMPTZ
);
CREATE INDEX idx_applicants_email ON mss.applicants(email);

CREATE TABLE mss.applicant_demographics (
    applicant_id          UUID         PRIMARY KEY REFERENCES mss.applicants(applicant_id) ON DELETE CASCADE,
    full_legal_name       VARCHAR(255) NOT NULL,
    other_names_used      VARCHAR(500),
    date_of_birth         DATE         NOT NULL,
    ssn_encrypted         BYTEA,                      -- AES-256 encrypted
    pseudo_ssn            VARCHAR(15),                -- deterministic hash if SSN withheld
    sex                   CHAR(1)      CHECK (sex IN ('M','F','X')),
    hair_color            VARCHAR(30),
    eye_color             VARCHAR(30),
    height_inches         SMALLINT,
    weight_lbs            SMALLINT,
    citizenship_country   CHAR(2),
    mailing_street_1      VARCHAR(255),
    mailing_street_2      VARCHAR(255),
    mailing_city          VARCHAR(100),
    mailing_state         CHAR(2),
    mailing_postal        VARCHAR(20),
    mailing_country       CHAR(2),
    residential_street_1  VARCHAR(255),
    residential_city      VARCHAR(100),
    residential_state     CHAR(2),
    residential_postal    VARCHAR(20),
    residential_country   CHAR(2),
    phone                 VARCHAR(30),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON COLUMN mss.applicant_demographics.ssn_encrypted IS 'AES-256 encrypted per FIPS 199 HIGH.';

-- -----------------------------------------------------------------------------
-- MEDXPRESS APPLICATIONS (Form 8500-8)
-- -----------------------------------------------------------------------------

CREATE TABLE mss.medxpress_applications (
    application_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    confirmation_number   VARCHAR(20)  NOT NULL UNIQUE,
    mid                   UUID         UNIQUE,       -- per-exam Medical ID
    class_applied         mss.medical_class NOT NULL,
    status                mss.application_status NOT NULL DEFAULT 'NO_APPLICATION',
    submitted_at          TIMESTAMPTZ,
    expires_at            TIMESTAMPTZ,
    imported_at           TIMESTAMPTZ,
    transmitted_at        TIMESTAMPTZ,
    privacy_act_accepted  BOOLEAN      NOT NULL DEFAULT FALSE,
    privacy_act_version   VARCHAR(20),
    is_expired            BOOLEAN      GENERATED ALWAYS AS
        (submitted_at IS NOT NULL AND submitted_at + INTERVAL '60 days' < NOW()) STORED,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_medxpress_app_applicant ON mss.medxpress_applications(applicant_id);
CREATE INDEX idx_medxpress_app_status    ON mss.medxpress_applications(status);
COMMENT ON COLUMN mss.medxpress_applications.confirmation_number IS 'Short-lived (60-day) confirmation for handoff to AMCS.';

-- Form 8500-8 detail — items 11-20
CREATE TABLE mss.medxpress_forms (
    application_id        UUID         PRIMARY KEY REFERENCES mss.medxpress_applications(application_id) ON DELETE CASCADE,
    -- Item 11-14 Cert history
    prior_cert_class      mss.medical_class,
    prior_cert_date       DATE,
    prior_denial          BOOLEAN,
    prior_suspension      BOOLEAN,
    prior_revocation      BOOLEAN,
    airman_cert_number    VARCHAR(20),
    airman_ratings        TEXT,
    last_medical_exam     DATE,
    -- Item 15-17
    occupation            VARCHAR(200),
    employer              VARCHAR(200),
    total_pilot_hours     NUMERIC(8,1),
    pilot_hours_6mo       NUMERIC(8,1),
    -- Item 17a medications
    current_medications   JSONB,      -- [{name, dosage, purpose, start_date}]
    -- Item 18 conditions (20+ yes/no + explanation)
    item_18_conditions    JSONB,      -- [{condition_id, yes_no, explanation}]
    -- Item 19 visits
    health_visits_3yr     JSONB,      -- [{date, reason, provider_name, provider_address}]
    -- Item 20
    convictions           JSONB,
    drug_alcohol_driving  JSONB,
    non_driving_drug_alcohol JSONB,
    disability_benefits   BOOLEAN,
    data_entry_method     VARCHAR(30) NOT NULL DEFAULT 'MEDXPRESS_ONLINE'
        CHECK (data_entry_method IN ('MEDXPRESS_ONLINE','AMCS_MANUAL_ENTRY')),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON COLUMN mss.medxpress_forms.item_18_conditions IS 'Medical history yes/no on 20+ conditions per Form 8500-8 Item 18.';

-- -----------------------------------------------------------------------------
-- AME DESIGNATIONS (populated from DMS, bidirectional sync)
-- -----------------------------------------------------------------------------

CREATE TABLE mss.ame_designations (
    ame_serial_num        VARCHAR(20)  PRIMARY KEY,
    full_name             VARCHAR(255) NOT NULL,
    credentials           VARCHAR(50),                -- MD, DO
    ssn_encrypted         BYTEA,
    status                mss.ame_status NOT NULL DEFAULT 'ACTIVE',
    is_senior_ame         BOOLEAN      NOT NULL DEFAULT FALSE,
    is_hims_ame           BOOLEAN      NOT NULL DEFAULT FALSE,
    practice_locations    JSONB,                      -- [{street, city, state, zip}]
    authorization_scope   JSONB,                      -- {class_1, class_2, class_3, atcs}
    designation_date      DATE,
    expiration_date       DATE,
    last_renewal_date     DATE,
    training_dates        JSONB,
    contact_email         VARCHAR(255),
    contact_phone         VARCHAR(30),
    last_validated_staff_at TIMESTAMPTZ,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_ame_status   ON mss.ame_designations(status);
CREATE INDEX idx_ame_expiry   ON mss.ame_designations(expiration_date);

-- -----------------------------------------------------------------------------
-- AMCS EXAMS
-- -----------------------------------------------------------------------------

CREATE TABLE mss.amcs_exams (
    exam_id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    ame_serial_num        VARCHAR(20)  NOT NULL REFERENCES mss.ame_designations(ame_serial_num),
    application_id        UUID         REFERENCES mss.medxpress_applications(application_id),
    confirmation_number   VARCHAR(20),
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    mid                   UUID         UNIQUE,
    exam_date             DATE         NOT NULL,
    status                mss.exam_status NOT NULL DEFAULT 'IN_PROGRESS',
    submission_deadline   DATE         GENERATED ALWAYS AS (exam_date + INTERVAL '14 days') STORED,
    transmitted_at        TIMESTAMPTZ,
    disposition           mss.disposition,
    disqualifying_condition VARCHAR(100),
    pi_number             VARCHAR(30),               -- Pathology Identifier (lifetime)
    locked_for_transmission BOOLEAN    NOT NULL DEFAULT FALSE,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_exams_applicant ON mss.amcs_exams(applicant_id);
CREATE INDEX idx_exams_ame       ON mss.amcs_exams(ame_serial_num);
CREATE INDEX idx_exams_date      ON mss.amcs_exams(exam_date);
CREATE INDEX idx_exams_status    ON mss.amcs_exams(status);
COMMENT ON COLUMN mss.amcs_exams.submission_deadline IS '14 days standard; 7 days for student certs (enforced by trigger).';

CREATE TABLE mss.exam_vitals (
    exam_id               UUID         PRIMARY KEY REFERENCES mss.amcs_exams(exam_id) ON DELETE CASCADE,
    height_inches         SMALLINT,
    weight_lbs            SMALLINT,
    bp_systolic           SMALLINT,
    bp_diastolic          SMALLINT,
    pulse_bpm             SMALLINT,
    measured_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE mss.exam_vision (
    exam_id                      UUID PRIMARY KEY REFERENCES mss.amcs_exams(exam_id) ON DELETE CASCADE,
    distant_right_uncorrected    VARCHAR(20),
    distant_right_corrected      VARCHAR(20),
    distant_left_uncorrected     VARCHAR(20),
    distant_left_corrected       VARCHAR(20),
    near_right                   VARCHAR(20),
    near_left                    VARCHAR(20),
    intermediate_right           VARCHAR(20),
    intermediate_left            VARCHAR(20),
    color_vision                 VARCHAR(20) CHECK (color_vision IN ('PASS','FAIL','NOT_TESTED','REFER')),
    color_vision_test_type       VARCHAR(50),   -- CAD, RCCT, Waggoner, other
    field_of_vision              VARCHAR(20) CHECK (field_of_vision IN ('NORMAL','ABNORMAL','REFER')),
    field_test_method            VARCHAR(50),
    tested_at                    TIMESTAMPTZ
);

CREATE TABLE mss.exam_hearing (
    exam_id               UUID PRIMARY KEY REFERENCES mss.amcs_exams(exam_id) ON DELETE CASCADE,
    left_500hz_db         SMALLINT,
    left_1000hz_db        SMALLINT,
    left_2000hz_db        SMALLINT,
    left_3000hz_db        SMALLINT,
    right_500hz_db        SMALLINT,
    right_1000hz_db       SMALLINT,
    right_2000hz_db       SMALLINT,
    right_3000hz_db       SMALLINT,
    whisper_left          VARCHAR(10),
    whisper_right         VARCHAR(10),
    conversational_left   VARCHAR(10),
    conversational_right  VARCHAR(10),
    tested_at             TIMESTAMPTZ
);

CREATE TABLE mss.exam_urinalysis (
    exam_id               UUID PRIMARY KEY REFERENCES mss.amcs_exams(exam_id) ON DELETE CASCADE,
    albumin               VARCHAR(20),
    sugar                 VARCHAR(20),
    tested_at             TIMESTAMPTZ
);

CREATE TABLE mss.exam_physical_findings (
    finding_id                BIGSERIAL  PRIMARY KEY,
    exam_id                   UUID       NOT NULL REFERENCES mss.amcs_exams(exam_id) ON DELETE CASCADE,
    system_item_num           SMALLINT   NOT NULL CHECK (system_item_num BETWEEN 25 AND 48),
    system_name               VARCHAR(100) NOT NULL,
    finding_status            mss.finding_status NOT NULL,
    abnormal_finding_narrative TEXT,
    examined_at               TIMESTAMPTZ
);
CREATE INDEX idx_findings_exam ON mss.exam_physical_findings(exam_id);

CREATE TABLE mss.exam_comments (
    comment_id           BIGSERIAL  PRIMARY KEY,
    exam_id              UUID       NOT NULL REFERENCES mss.amcs_exams(exam_id) ON DELETE CASCADE,
    comment_type         VARCHAR(50) NOT NULL
        CHECK (comment_type IN ('PHYSICAL_FINDINGS','PAGE_1_MODIFICATIONS','APPLICANT_EXPLANATIONS','HISTORY_AND_FINDINGS')),
    comment_text         TEXT        NOT NULL,
    referenced_item      VARCHAR(50),
    applicant_authorized_mod BOOLEAN,
    created_by           VARCHAR(100) NOT NULL,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE mss.exam_disposition (
    exam_id              UUID PRIMARY KEY REFERENCES mss.amcs_exams(exam_id) ON DELETE CASCADE,
    disposition          mss.disposition NOT NULL,
    certificate_class    mss.certificate_class,
    certificate_number   VARCHAR(30),
    certificate_issue_date DATE,
    certificate_expiration_date DATE,
    issued_in_office     BOOLEAN     NOT NULL DEFAULT FALSE,
    limitations          JSONB,
    special_issuance     BOOLEAN     NOT NULL DEFAULT FALSE,
    si_condition_codes   TEXT[],
    denial_reason_code   VARCHAR(50),
    appeal_rights_letter_generated BOOLEAN,
    defer_reason_code    VARCHAR(50),
    defer_doc_request    TEXT,
    decided_by           VARCHAR(100),
    decided_at           TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- DIWS — Document Imaging & Workflow
-- -----------------------------------------------------------------------------

CREATE TABLE mss.amcs_documents (
    document_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id               UUID         REFERENCES mss.amcs_exams(exam_id),
    applicant_id          UUID         REFERENCES mss.applicants(applicant_id),
    ame_serial_num        VARCHAR(20)  REFERENCES mss.ame_designations(ame_serial_num),
    document_name         VARCHAR(255) NOT NULL,
    doc_type_id           VARCHAR(50)  NOT NULL REFERENCES mss.document_type_taxonomy(doc_type_id),
    document_date         DATE,
    file_size_bytes       BIGINT       NOT NULL CHECK (file_size_bytes > 0),
    file_format           VARCHAR(20)  NOT NULL CHECK (file_format IN ('PDF','DOC','DOCX','JPG','JPEG','XPS','TIFF','PNG')),
    tiff_scanned_pages    INTEGER,
    physical_file_uri     VARCHAR(2048) NOT NULL,
    file_hash_sha256      CHAR(64),
    scan_date             DATE,
    kofax_index_data      JSONB,
    is_supplemental       BOOLEAN      NOT NULL DEFAULT FALSE,
    uploaded_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    indexed_at            TIMESTAMPTZ,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_docs_exam        ON mss.amcs_documents(exam_id, doc_type_id);
CREATE INDEX idx_docs_applicant   ON mss.amcs_documents(applicant_id, document_date);
CREATE INDEX idx_docs_ame         ON mss.amcs_documents(ame_serial_num, uploaded_at);
COMMENT ON COLUMN mss.amcs_documents.file_size_bytes IS 'Legacy 3MB limit; modernization should raise to 500MB.';

CREATE TABLE mss.diws_workflow_queues (
    queue_id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id               UUID         REFERENCES mss.amcs_exams(exam_id),
    applicant_id          UUID         REFERENCES mss.applicants(applicant_id),
    queue_type            mss.queue_type NOT NULL,
    queue_region          VARCHAR(50),
    queue_assignment_reason VARCHAR(200),
    assigned_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    assigned_to_user_id   VARCHAR(100),
    queue_status          VARCHAR(30)  NOT NULL DEFAULT 'PENDING'
        CHECK (queue_status IN ('PENDING','IN_PROGRESS','ESCALATED','RESOLVED')),
    resolved_at           TIMESTAMPTZ,
    resolved_by_user_id   VARCHAR(100),
    resolution_action     VARCHAR(50),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_queues_status ON mss.diws_workflow_queues(queue_status);
CREATE INDEX idx_queues_exam   ON mss.diws_workflow_queues(exam_id);

CREATE TABLE mss.document_retention_schedules (
    exam_id               UUID         PRIMARY KEY REFERENCES mss.amcs_exams(exam_id) ON DELETE CASCADE,
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    case_closed_date      DATE,
    retention_deadline    DATE         GENERATED ALWAYS AS (case_closed_date + INTERVAL '50 years') STORED,
    legal_hold_flag       BOOLEAN      NOT NULL DEFAULT FALSE,
    legal_hold_reason     VARCHAR(500),
    legal_hold_release_date DATE,
    destruction_scheduled_date DATE,
    destruction_executed  BOOLEAN      NOT NULL DEFAULT FALSE,
    destruction_executed_at TIMESTAMPTZ,
    destruction_executed_by VARCHAR(100),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE mss.document_retention_schedules IS '50-yr retention per NARA N1-237-05-005; dual-auth destruction.';

-- -----------------------------------------------------------------------------
-- CPDSS — Covered Position / ATCS Clearance
-- -----------------------------------------------------------------------------

CREATE TABLE mss.atcs_clearance_evaluations (
    clearance_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    exam_id               UUID         REFERENCES mss.amcs_exams(exam_id),
    form_3900_7_submitted BOOLEAN      NOT NULL DEFAULT FALSE,
    clearance_status      VARCHAR(50)  NOT NULL DEFAULT 'PENDING_REVIEW',
    tier_1_result         JSONB,
    tier_2_submitted      BOOLEAN      NOT NULL DEFAULT FALSE,
    tier_2_evaluations    JSONB,
    disqualifying_conditions JSONB,
    reviewer_id           UUID,
    decision_rationale    TEXT,
    clearance_decision_at TIMESTAMPTZ,
    conditions_for_clearance JSONB,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE mss.aviator_transmissions (
    transmission_id       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    clearance_id          UUID         NOT NULL REFERENCES mss.atcs_clearance_evaluations(clearance_id),
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    clearance_status_transmitted VARCHAR(50) NOT NULL,
    effective_date        DATE,
    next_action_date      DATE,
    minimum_necessary_fields JSONB,
    transmission_status   VARCHAR(30)  NOT NULL DEFAULT 'PENDING',
    transmitted_at        TIMESTAMPTZ,
    acknowledged_at       TIMESTAMPTZ,
    retry_count           INTEGER      NOT NULL DEFAULT 0,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- AMCD — Airman Medical History
-- -----------------------------------------------------------------------------

CREATE TABLE mss.airman_medical_history (
    airman_id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_id          UUID         NOT NULL UNIQUE REFERENCES mss.applicants(applicant_id),
    ssn_encrypted         BYTEA,
    full_name             VARCHAR(255) NOT NULL,
    date_of_birth         DATE,
    exam_count            INTEGER      NOT NULL DEFAULT 0,
    last_exam_date        DATE,
    most_recent_status    VARCHAR(30),
    most_recent_class     mss.certificate_class,
    deferred_case_count   INTEGER      NOT NULL DEFAULT 0,
    denied_case_count     INTEGER      NOT NULL DEFAULT 0,
    revocation_count      INTEGER      NOT NULL DEFAULT 0,
    appeal_count          INTEGER      NOT NULL DEFAULT 0,
    si_condition_tags     TEXT[],
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_airman_history_name ON mss.airman_medical_history(full_name);
CREATE INDEX idx_airman_history_dob  ON mss.airman_medical_history(date_of_birth);

CREATE TABLE mss.deferred_cases (
    deferred_case_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id               UUID         NOT NULL REFERENCES mss.amcs_exams(exam_id),
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    airman_id             UUID         REFERENCES mss.airman_medical_history(airman_id),
    deferral_date         DATE         NOT NULL,
    deferral_reason_code  VARCHAR(50),
    documentation_requested JSONB,
    response_deadline     DATE,
    follow_up_exam_date   DATE,
    case_status           mss.deferred_status NOT NULL DEFAULT 'PENDING_RESPONSE',
    resolved_at           TIMESTAMPTZ,
    resolved_disposition  mss.disposition,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_deferred_airman ON mss.deferred_cases(airman_id);
CREATE INDEX idx_deferred_status ON mss.deferred_cases(case_status);

CREATE TABLE mss.denied_cases (
    denied_case_id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id               UUID         NOT NULL REFERENCES mss.amcs_exams(exam_id),
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    airman_id             UUID         REFERENCES mss.airman_medical_history(airman_id),
    denial_date           DATE         NOT NULL,
    disqualifying_condition_code VARCHAR(50),
    disqualifying_condition_narrative TEXT,
    legal_review_completed BOOLEAN     NOT NULL DEFAULT FALSE,
    appeal_rights_letter_issued BOOLEAN NOT NULL DEFAULT FALSE,
    appeal_rights_letter_date DATE,
    appeal_filed          BOOLEAN      NOT NULL DEFAULT FALSE,
    appeal_filed_date     DATE,
    case_status           mss.denied_status NOT NULL DEFAULT 'INITIAL_DENIAL',
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE mss.revocation_cases (
    revocation_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    airman_id             UUID         NOT NULL REFERENCES mss.airman_medical_history(airman_id),
    revocation_date       DATE         NOT NULL,
    effective_date        DATE,
    reason_code           VARCHAR(50),
    reason_narrative      TEXT,
    enforcement_action    VARCHAR(200),
    rehab_eligible_date   DATE,
    appeal_filed          BOOLEAN      NOT NULL DEFAULT FALSE,
    appeal_decision       VARCHAR(30),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE mss.special_issuance_cases (
    si_case_id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    airman_id             UUID         NOT NULL REFERENCES mss.airman_medical_history(airman_id),
    exam_id               UUID         REFERENCES mss.amcs_exams(exam_id),
    si_condition          mss.si_condition NOT NULL,
    authorization_letter_issued BOOLEAN NOT NULL DEFAULT FALSE,
    authorization_letter_date DATE,
    authorization_number  VARCHAR(50),
    status                mss.si_status NOT NULL DEFAULT 'PENDING_FAS',
    follow_up_requirements JSONB,
    follow_up_next_due    DATE,
    cardiac_monitoring    BOOLEAN      NOT NULL DEFAULT FALSE,
    cardiac_schedule      VARCHAR(30),
    endocrine_monitoring  BOOLEAN      NOT NULL DEFAULT FALSE,
    endocrine_schedule    VARCHAR(30),
    last_follow_up_date   DATE,
    follow_up_status      VARCHAR(30) CHECK (follow_up_status IN ('CURRENT','OVERDUE','DOCUMENTATION_PENDING')),
    status_history        JSONB,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_si_cases_airman    ON mss.special_issuance_cases(airman_id);
CREATE INDEX idx_si_cases_condition ON mss.special_issuance_cases(si_condition);
CREATE INDEX idx_si_followup_due    ON mss.special_issuance_cases(follow_up_next_due);

-- -----------------------------------------------------------------------------
-- CAMI — Research (de-identified)
-- -----------------------------------------------------------------------------

CREATE TABLE mss.aeromedical_research_cases (
    research_case_id      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_hash        VARCHAR(64),       -- hashed for linkage only
    exam_id               UUID         REFERENCES mss.amcs_exams(exam_id),
    research_cohort       VARCHAR(100),
    age_bracket           VARCHAR(20),
    certificate_class     mss.certificate_class,
    medical_findings_summary JSONB,
    disposition_outcome   mss.disposition,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE mss.toxicology_data (
    tox_case_id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_hash        VARCHAR(64),
    sample_type           VARCHAR(30)  NOT NULL CHECK (sample_type IN ('BLOOD','URINE','BREATH','TISSUE')),
    sample_date           DATE,
    substance_screened    VARCHAR(100),
    result_quantitative   NUMERIC(10,3),
    forensic_context      VARCHAR(255),
    de_identified         BOOLEAN      NOT NULL DEFAULT TRUE,
    archived_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- AUDIT LOG & INTEGRATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE mss.audit_log (
    audit_id              BIGSERIAL    PRIMARY KEY,
    event_time            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    record_type           VARCHAR(50)  NOT NULL,
    record_id             UUID,
    action                VARCHAR(30)  NOT NULL CHECK (action IN ('READ','WRITE','EXPORT','DISCLOSURE','DELETE')),
    user_identity         VARCHAR(100) NOT NULL,
    source_ip             INET,
    data_fields_accessed  TEXT[],
    disclosure_recipient  VARCHAR(255)
);
CREATE INDEX idx_mss_audit_time   ON mss.audit_log(event_time);
CREATE INDEX idx_mss_audit_user   ON mss.audit_log(user_identity);
CREATE INDEX idx_mss_audit_record ON mss.audit_log(record_type, record_id);
COMMENT ON TABLE mss.audit_log IS 'FIPS 199 HIGH — every read/write/export logged.';

CREATE TABLE mss.cais_sync_status (
    sync_id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    last_cais_pull        TIMESTAMPTZ,
    last_mss_push         TIMESTAMPTZ,
    demographics_in_sync  BOOLEAN,
    exam_data_in_sync     BOOLEAN,
    sync_status           VARCHAR(30),
    error_log             TEXT
);

CREATE TABLE mss.ndr_comparisons (
    ndr_id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_id          UUID         NOT NULL REFERENCES mss.applicants(applicant_id),
    comparison_file_encrypted BYTEA,
    submission_date       DATE         NOT NULL,
    match_found           BOOLEAN,
    match_details         JSONB,
    anomaly_routed        BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE mss.ndr_comparisons IS 'National Driver Register cross-check for DUI/drug-alcohol history.';

CREATE TABLE mss.dms_ame_metrics (
    dms_metric_id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    ame_serial_num        VARCHAR(20)  NOT NULL REFERENCES mss.ame_designations(ame_serial_num),
    reporting_period      DATE         NOT NULL,
    exam_volume           INTEGER,
    deferral_rate_pct     NUMERIC(5,2),
    denial_rate_pct       NUMERIC(5,2),
    avg_response_days     NUMERIC(6,1),
    error_rate_pct        NUMERIC(5,2),
    dms_designation_status mss.ame_status,
    last_synced           TIMESTAMPTZ
);

-- =============================================================================
-- END OF MEDXPRESS/MSS SCHEMA
-- =============================================================================
