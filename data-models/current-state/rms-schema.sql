-- =============================================================================
-- RMS (Registry Modernization System) — Current-State Schema
-- Aircraft Registration + Comprehensive Airmen Information System (CAIS)
-- =============================================================================
-- Source systems modeled: CAIS (mainframe NATURAL/ADABAS), IMS (Image
-- Management System), paper-backed work packets.
-- Authority: 14 CFR Parts 47 (aircraft) / 49 (recording) / 61, 63, 65 (airmen);
-- 49 U.S.C. §§ 44107-44108 (recording priority).
-- Retention: Aircraft = permanent (NARA N1-237-04-03); Airmen = 60 yr
-- (NARA N1-237-06-001); Enforcement = 5 yr post-closure; Foreign license
-- verification = CY + 6 mo.
-- Volumes: 300K aircraft, 1.5M airmen, 174M TIFF images, 25M documents.
-- FIPS 199: MODERATE.
-- Privacy Act SORN: DOT/FAA 801 (aircraft), DOT/FAA 847 (airmen).
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS rms;
SET search_path TO rms, public;

-- -----------------------------------------------------------------------------
-- ENUMERATED TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE rms.registration_type AS ENUM (
    'INDIVIDUAL',            -- AC 8050-1 Type 1
    'PARTNERSHIP',           -- Type 2
    'CORPORATION',           -- Type 3
    'CO_OWNER',              -- Type 4
    'GOVERNMENT',            -- Type 5
    -- Type 6 intentionally absent per AC 8050-1 enumeration gap
    'LLC',                   -- Type 7
    'NON_CITIZEN_CORP',      -- Type 8
    'NON_CITIZEN_COOWNER',   -- Type 9
    'TRUST'                  -- Added by modernization (was implied via Individual+trust flag)
);

CREATE TYPE rms.aircraft_status AS ENUM (
    'PENDING',         -- Application under examination
    'ACTIVE',          -- Registered, current, airworthy
    'EXPIRED',         -- Renewal lapsed
    'CANCELLED',       -- Voluntary cancellation
    'DEREGISTERED',    -- Export, sale to non-US, destroyed
    'SUSPENDED',       -- Enforcement action
    'REVOKED'          -- Enforcement action (permanent)
);

CREATE TYPE rms.airman_cert_status AS ENUM (
    'ISSUED',
    'RENEWED',
    'EXPIRED',
    'SUSPENDED',
    'REVOKED',
    'SURRENDERED',
    'DENIED',
    'AWAITING_ISSUE'
);

CREATE TYPE rms.lien_type AS ENUM (
    'MORTGAGE',
    'CONDITIONAL_SALES_CONTRACT',
    'SECURITY_AGREEMENT',
    'LEASE'
);

CREATE TYPE rms.transfer_type AS ENUM (
    'BILL_OF_SALE',
    'DIVORCE_DECREE',
    'COURT_ORDER',
    'INHERITANCE',
    'TRUSTEE_SUCCESSION',
    'MERGER',
    'REPOSSESSION'
);

CREATE TYPE rms.payment_status AS ENUM (
    'PENDING', 'CLEARED', 'RECONCILED', 'FAILED', 'REFUNDED'
);

CREATE TYPE rms.work_packet_status AS ENUM (
    'RECEIVED', 'INDEXED', 'UNDER_REVIEW', 'DEFICIENT_RETURNED',
    'APPROVED', 'COMPLETED', 'REJECTED'
);

CREATE TYPE rms.document_format AS ENUM (
    'TIFF', 'PDF', 'PDF_A', 'PNG', 'JPEG', 'OCR_PDF'
);

CREATE TYPE rms.notice_status AS ENUM (
    'GENERATED', 'MAILED', 'DELIVERED', 'UNDELIVERABLE', 'RESPONSE_RECEIVED', 'CLOSED'
);

CREATE TYPE rms.reservation_status AS ENUM (
    'AVAILABLE', 'RESERVED', 'ASSIGNED', 'EXPIRED', 'CANCELLED', 'RETIRED'
);

-- -----------------------------------------------------------------------------
-- REFERENCE / LOOKUP TABLES
-- -----------------------------------------------------------------------------

CREATE TABLE rms.aircraft_manufacturers (
    manufacturer_code    VARCHAR(10)  PRIMARY KEY,
    manufacturer_name    VARCHAR(200) NOT NULL,
    country_of_origin    CHAR(2),     -- ISO 3166-1 alpha-2
    active               BOOLEAN      NOT NULL DEFAULT TRUE,
    historical_notes     TEXT,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE  rms.aircraft_manufacturers IS 'Reference list of aircraft manufacturers (MFR code).';
COMMENT ON COLUMN rms.aircraft_manufacturers.manufacturer_code IS 'Short FAA-assigned MFR code (e.g., "CESSNA", "PIPER").';

CREATE TABLE rms.aircraft_models (
    mfr_mdl_code         VARCHAR(20)  PRIMARY KEY,
    manufacturer_code    VARCHAR(10)  NOT NULL REFERENCES rms.aircraft_manufacturers(manufacturer_code),
    model_name           VARCHAR(200) NOT NULL,
    aircraft_category    VARCHAR(50)  NOT NULL,   -- airplane, rotorcraft, glider, balloon, airship
    certification_basis  VARCHAR(50),             -- 14 CFR Part 23, 25, 27, 29, etc.
    typical_engine_count SMALLINT CHECK (typical_engine_count >= 0),
    year_introduced      SMALLINT,
    year_discontinued    SMALLINT,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE rms.aircraft_models IS 'Aircraft make/model reference (MFR Mdl Code).';

CREATE TABLE rms.engine_manufacturers (
    engine_mfr_code   VARCHAR(10)  PRIMARY KEY,
    engine_mfr_name   VARCHAR(200) NOT NULL,
    country_of_origin CHAR(2),
    active            BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE rms.engine_manufacturers IS 'Engine manufacturer reference.';

CREATE TABLE rms.engine_models (
    eng_mfr_mdl_code      VARCHAR(20)  PRIMARY KEY,
    engine_mfr_code       VARCHAR(10)  NOT NULL REFERENCES rms.engine_manufacturers(engine_mfr_code),
    engine_model_name     VARCHAR(200) NOT NULL,
    engine_type           VARCHAR(50)  NOT NULL,   -- piston, turbine, turbofan, turboprop, electric
    horsepower            INTEGER,
    thrust_pounds         INTEGER,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE rms.engine_models IS 'Engine model reference (Eng Mfr Mdl).';

CREATE TABLE rms.countries (
    country_code CHAR(2) PRIMARY KEY,        -- ISO 3166-1 alpha-2
    country_name VARCHAR(100) NOT NULL
);
COMMENT ON TABLE rms.countries IS 'ISO country reference.';

CREATE TABLE rms.us_states (
    state_code CHAR(2) PRIMARY KEY,
    state_name VARCHAR(100) NOT NULL
);
COMMENT ON TABLE rms.us_states IS 'US state / territory reference.';

-- -----------------------------------------------------------------------------
-- ADDRESS (shared by owners, registrants, lien-holders, examiners)
-- -----------------------------------------------------------------------------

CREATE TABLE rms.addresses (
    address_id         BIGSERIAL    PRIMARY KEY,
    address_type       VARCHAR(20)  NOT NULL CHECK (address_type IN ('MAILING','PHYSICAL','BUSINESS')),
    street_line_1      VARCHAR(255) NOT NULL,
    street_line_2      VARCHAR(255),
    street_line_3      VARCHAR(255),        -- rural route / PO Box line
    city               VARCHAR(100) NOT NULL,
    state_code         CHAR(2) REFERENCES rms.us_states(state_code),      -- US only
    province           VARCHAR(100),                                      -- non-US only
    postal_code        VARCHAR(20),
    country_code       CHAR(2) NOT NULL DEFAULT 'US' REFERENCES rms.countries(country_code),
    location_description VARCHAR(500),      -- required when mailing is PO Box / rural route
    is_po_box          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_addr_state_or_province CHECK (
        country_code = 'US' AND state_code IS NOT NULL
        OR country_code <> 'US'
    )
);
CREATE INDEX idx_addresses_city_state ON rms.addresses(city, state_code);
CREATE INDEX idx_addresses_postal     ON rms.addresses(postal_code);
COMMENT ON TABLE  rms.addresses IS 'Canonical address record (mailing/physical/business).';
COMMENT ON COLUMN rms.addresses.location_description IS 'Required when mailing is PO Box, mail drop, rural route — 14 CFR Part 47.';

-- -----------------------------------------------------------------------------
-- OWNER (individual or legal entity; backed by registration_type)
-- -----------------------------------------------------------------------------

CREATE TABLE rms.owners (
    owner_id              BIGSERIAL   PRIMARY KEY,
    registration_type     rms.registration_type NOT NULL,
    -- Individual fields
    first_name            VARCHAR(100),
    middle_name           VARCHAR(100),
    last_name             VARCHAR(100),
    suffix                VARCHAR(20),
    date_of_birth         DATE,
    ssn_last4             CHAR(4),             -- Privacy Act collection; never a lookup key
    -- Entity fields (partnership/corp/LLC/trust/gov)
    entity_legal_name     VARCHAR(255),
    state_of_formation    CHAR(2) REFERENCES rms.us_states(state_code),
    country_of_formation  CHAR(2) REFERENCES rms.countries(country_code),
    ein                   VARCHAR(10),
    -- Citizenship & compliance
    is_us_citizen         BOOLEAN,                              -- per 49 USC 40102(a)(15)
    citizenship_country   CHAR(2) REFERENCES rms.countries(country_code),
    resident_alien_form_i551 VARCHAR(50),                       -- I-551 reference if applicable
    -- Trust-specific compliance (OIG 2014)
    trustee_name          VARCHAR(255),
    trustee_citizenship   CHAR(2) REFERENCES rms.countries(country_code),
    non_citizen_trustee_declaration BOOLEAN,
    beneficiary_info      TEXT,
    intl_ops_declaration  BOOLEAN,
    -- Non-citizen corp specific
    primarily_used_in_us  BOOLEAN,
    flight_hour_records_location VARCHAR(500),
    -- Addresses (FKs)
    mailing_address_id    BIGINT REFERENCES rms.addresses(address_id),
    physical_address_id   BIGINT REFERENCES rms.addresses(address_id),
    email                 VARCHAR(255),
    phone                 VARCHAR(30),
    -- Lifecycle
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_owner_individual_or_entity CHECK (
        (registration_type = 'INDIVIDUAL' AND last_name IS NOT NULL)
        OR (registration_type <> 'INDIVIDUAL' AND entity_legal_name IS NOT NULL)
    )
);
CREATE INDEX idx_owners_last_name      ON rms.owners(last_name);
CREATE INDEX idx_owners_entity_name    ON rms.owners(entity_legal_name);
CREATE INDEX idx_owners_mailing_addr   ON rms.owners(mailing_address_id);
CREATE INDEX idx_owners_reg_type       ON rms.owners(registration_type);
COMMENT ON TABLE  rms.owners IS 'Aircraft owner / registrant — individual, entity, or trust.';
COMMENT ON COLUMN rms.owners.non_citizen_trustee_declaration IS 'OIG 2014 compliance — required when trust has non-citizen trustee.';

-- Partnership partners and corporation officers (one-to-many from owners)
CREATE TABLE rms.entity_principals (
    principal_id       BIGSERIAL    PRIMARY KEY,
    owner_id           BIGINT       NOT NULL REFERENCES rms.owners(owner_id) ON DELETE CASCADE,
    principal_type     VARCHAR(30)  NOT NULL CHECK (principal_type IN
                          ('PARTNER','OFFICER','MANAGING_MEMBER','TRUSTEE','BENEFICIARY','GOVT_CONTACT')),
    full_name          VARCHAR(255) NOT NULL,
    title              VARCHAR(100),
    citizenship_country CHAR(2) REFERENCES rms.countries(country_code),
    ownership_percentage NUMERIC(5,2),
    address_id         BIGINT REFERENCES rms.addresses(address_id),
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_principals_owner ON rms.entity_principals(owner_id);
COMMENT ON TABLE rms.entity_principals IS 'Officers / partners / trustees / beneficiaries of an entity owner.';

-- -----------------------------------------------------------------------------
-- N-NUMBER RESERVATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE rms.n_number_reservations (
    reservation_id       BIGSERIAL      PRIMARY KEY,
    n_number             VARCHAR(6)     NOT NULL UNIQUE
                             CHECK (n_number ~ '^N[A-Z0-9]{1,5}$'),
    requestor_name       VARCHAR(255)   NOT NULL,
    requestor_email      VARCHAR(255),
    requestor_phone      VARCHAR(30),
    requestor_address_id BIGINT         REFERENCES rms.addresses(address_id),
    reservation_channel  VARCHAR(20)    NOT NULL CHECK (reservation_channel IN ('ONLINE','TELEPHONE','MAIL')),
    reservation_date     DATE           NOT NULL DEFAULT CURRENT_DATE,
    expiration_date      DATE           NOT NULL,
    status               rms.reservation_status NOT NULL DEFAULT 'RESERVED',
    renewable            BOOLEAN        NOT NULL DEFAULT TRUE,
    assigned_aircraft_id BIGINT,        -- FK set later when reservation converts
    special_request      BOOLEAN        NOT NULL DEFAULT FALSE,
    fee_paid             NUMERIC(10,2),
    created_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_reserv_dates CHECK (expiration_date > reservation_date)
);
CREATE INDEX idx_reservations_status ON rms.n_number_reservations(status);
CREATE INDEX idx_reservations_expiry ON rms.n_number_reservations(expiration_date);
COMMENT ON TABLE  rms.n_number_reservations IS 'N-number reservations (pre-registration).';
COMMENT ON COLUMN rms.n_number_reservations.n_number IS 'N followed by 1-5 alphanumerics; unique across active + reserved + retired.';

-- -----------------------------------------------------------------------------
-- AIRCRAFT (central registration master)
-- -----------------------------------------------------------------------------

CREATE TABLE rms.aircraft (
    aircraft_id            BIGSERIAL    PRIMARY KEY,
    n_number               VARCHAR(6)   NOT NULL UNIQUE
                              CHECK (n_number ~ '^N[A-Z0-9]{1,5}$'),
    serial_number          VARCHAR(50)  NOT NULL,
    mfr_mdl_code           VARCHAR(20)  NOT NULL REFERENCES rms.aircraft_models(mfr_mdl_code),
    eng_mfr_mdl_code       VARCHAR(20)  REFERENCES rms.engine_models(eng_mfr_mdl_code),
    year_mfr               SMALLINT     CHECK (year_mfr BETWEEN 1900 AND 2100),
    num_engines            SMALLINT     CHECK (num_engines >= 0),
    num_seats              SMALLINT     CHECK (num_seats >= 0),
    aircraft_category      VARCHAR(50)  NOT NULL,    -- airplane, rotorcraft, etc.
    aircraft_class         VARCHAR(50),              -- SEL, MEL, helicopter, etc.
    type_aircraft          VARCHAR(50),              -- general aviation, commercial, etc.
    type_engine            VARCHAR(50),              -- reciprocating, turboprop, turbojet, etc.
    mode_s_code_hex        CHAR(6)      UNIQUE
                              CHECK (mode_s_code_hex ~ '^[0-9A-F]{6}$'),
    mode_s_code_octal      CHAR(8),
    airworthiness_cert_type VARCHAR(50),             -- standard, special, provisional, experimental
    registration_type      rms.registration_type NOT NULL,
    registration_status    rms.aircraft_status NOT NULL DEFAULT 'PENDING',
    registration_issue_date DATE,
    last_action_date       DATE,
    certification_expiration_date DATE,              -- 7-year cycle
    certification_issue_date DATE,
    import_country         CHAR(2) REFERENCES rms.countries(country_code),
    is_dealer_aircraft     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_aircraft_dates CHECK (
        certification_expiration_date IS NULL OR registration_issue_date IS NULL
        OR certification_expiration_date > registration_issue_date
    )
);
CREATE INDEX idx_aircraft_serial        ON rms.aircraft(serial_number);
CREATE INDEX idx_aircraft_mfr_mdl       ON rms.aircraft(mfr_mdl_code);
CREATE INDEX idx_aircraft_status        ON rms.aircraft(registration_status);
CREATE INDEX idx_aircraft_expiration    ON rms.aircraft(certification_expiration_date);
CREATE INDEX idx_aircraft_mode_s        ON rms.aircraft(mode_s_code_hex);
COMMENT ON TABLE  rms.aircraft IS 'Aircraft registration master (N-number is primary external identifier).';
COMMENT ON COLUMN rms.aircraft.mode_s_code_hex IS '24-bit ICAO Mode S code (hex); unique per aircraft.';
COMMENT ON COLUMN rms.aircraft.certification_expiration_date IS '7-year renewal cycle per FAA Reauthorization Act of 2018.';

ALTER TABLE rms.n_number_reservations
    ADD CONSTRAINT fk_reservation_aircraft
    FOREIGN KEY (assigned_aircraft_id) REFERENCES rms.aircraft(aircraft_id);

-- -----------------------------------------------------------------------------
-- AIRCRAFT OWNERSHIP (junction table; supports co-ownership)
-- -----------------------------------------------------------------------------

CREATE TABLE rms.aircraft_ownership (
    aircraft_ownership_id BIGSERIAL   PRIMARY KEY,
    aircraft_id         BIGINT        NOT NULL REFERENCES rms.aircraft(aircraft_id) ON DELETE CASCADE,
    owner_id            BIGINT        NOT NULL REFERENCES rms.owners(owner_id),
    ownership_start_date DATE         NOT NULL,
    ownership_end_date   DATE,
    ownership_share_pct  NUMERIC(5,2),    -- null for 100% sole owner
    signed_application   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_ownership_pct CHECK (ownership_share_pct IS NULL OR (ownership_share_pct > 0 AND ownership_share_pct <= 100)),
    CONSTRAINT chk_ownership_dates CHECK (ownership_end_date IS NULL OR ownership_end_date >= ownership_start_date)
);
CREATE INDEX idx_ownership_aircraft ON rms.aircraft_ownership(aircraft_id);
CREATE INDEX idx_ownership_owner    ON rms.aircraft_ownership(owner_id);
CREATE UNIQUE INDEX idx_ownership_current_per_owner
    ON rms.aircraft_ownership(aircraft_id, owner_id)
    WHERE ownership_end_date IS NULL;
COMMENT ON TABLE rms.aircraft_ownership IS 'Junction — aircraft ↔ owner, including co-owners, open-ended current + historical chains.';

-- -----------------------------------------------------------------------------
-- DEALER REGISTRATIONS
-- -----------------------------------------------------------------------------

CREATE TABLE rms.dealer_registrations (
    dealer_registration_id   BIGSERIAL    PRIMARY KEY,
    dealer_number            VARCHAR(20)  NOT NULL UNIQUE,
    dealer_business_name     VARCHAR(255) NOT NULL,
    business_address_id      BIGINT       REFERENCES rms.addresses(address_id),
    principal_officer_name   VARCHAR(255),
    initial_issue_date       DATE         NOT NULL,
    expiration_date          DATE         NOT NULL,
    status                   VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','EXPIRED','REVOKED','SURRENDERED')),
    compliance_notes         TEXT,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_dealer_12mo CHECK (expiration_date <= initial_issue_date + INTERVAL '13 months')
);
COMMENT ON TABLE  rms.dealer_registrations IS '14 CFR Part 47 Subpart C dealer registrations (annual).';
COMMENT ON COLUMN rms.dealer_registrations.expiration_date IS '12-month expiration cycle.';

-- -----------------------------------------------------------------------------
-- OWNERSHIP TRANSFERS
-- -----------------------------------------------------------------------------

CREATE TABLE rms.ownership_transfers (
    transfer_id            BIGSERIAL   PRIMARY KEY,
    aircraft_id            BIGINT      NOT NULL REFERENCES rms.aircraft(aircraft_id),
    previous_owner_id      BIGINT      REFERENCES rms.owners(owner_id),
    new_owner_id           BIGINT      NOT NULL REFERENCES rms.owners(owner_id),
    transfer_type          rms.transfer_type NOT NULL,
    receipt_date           TIMESTAMPTZ NOT NULL,    -- time-stamped per 49 USC 44107
    recorded_date          TIMESTAMPTZ,
    examiner_id            VARCHAR(50),
    approval_status        VARCHAR(30) NOT NULL DEFAULT 'PENDING'
        CHECK (approval_status IN ('PENDING','APPROVED','DENIED','PENDING_DEFICIENCY')),
    recording_fee          NUMERIC(10,2),
    evidence_document_id   BIGINT,      -- FK to documents (set below)
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_transfers_aircraft     ON rms.ownership_transfers(aircraft_id);
CREATE INDEX idx_transfers_receipt_date ON rms.ownership_transfers(receipt_date);
COMMENT ON COLUMN rms.ownership_transfers.receipt_date IS 'Time-stamping establishes recording priority per 49 USC 44107-44108.';

-- -----------------------------------------------------------------------------
-- SECURITY INTERESTS / LIENS
-- -----------------------------------------------------------------------------

CREATE TABLE rms.security_interests (
    lien_id               BIGSERIAL    PRIMARY KEY,
    aircraft_id           BIGINT       NOT NULL REFERENCES rms.aircraft(aircraft_id),
    lien_type             rms.lien_type NOT NULL,
    lien_holder_name      VARCHAR(255) NOT NULL,
    lien_holder_address_id BIGINT      REFERENCES rms.addresses(address_id),
    amount                NUMERIC(14,2),
    filing_date           TIMESTAMPTZ  NOT NULL,
    priority_rank         INTEGER,     -- computed from filing time order
    expiration_date       DATE,
    is_released           BOOLEAN      NOT NULL DEFAULT FALSE,
    discharge_date        DATE,
    recording_fee         NUMERIC(10,2),
    instrument_document_id BIGINT,     -- FK to documents
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_liens_aircraft   ON rms.security_interests(aircraft_id);
CREATE INDEX idx_liens_filing     ON rms.security_interests(filing_date);
COMMENT ON TABLE rms.security_interests IS '14 CFR Part 49 security interests (mortgages, liens, leases).';

-- -----------------------------------------------------------------------------
-- EXPORT / AIRWORTHINESS CERTIFICATES
-- -----------------------------------------------------------------------------

CREATE TABLE rms.export_certificates (
    export_cert_id        BIGSERIAL   PRIMARY KEY,
    aircraft_id           BIGINT      NOT NULL REFERENCES rms.aircraft(aircraft_id),
    destination_country   CHAR(2)     NOT NULL REFERENCES rms.countries(country_code),
    icao_annex_7_cert     BOOLEAN     NOT NULL DEFAULT TRUE,
    issue_date            DATE        NOT NULL,
    validity_days         INTEGER     NOT NULL DEFAULT 60,
    priority_processing   BOOLEAN     NOT NULL DEFAULT TRUE,
    examiner_id           VARCHAR(50),
    registration_letter_id BIGINT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_export_aircraft ON rms.export_certificates(aircraft_id);
COMMENT ON COLUMN rms.export_certificates.priority_processing IS 'Export filings take highest priority per OIG 2019 and ICAO Annex 7.';

-- -----------------------------------------------------------------------------
-- WORK PACKETS / IMAGES (replacement for IMS)
-- -----------------------------------------------------------------------------

CREATE TABLE rms.work_packets (
    work_packet_id    BIGSERIAL   PRIMARY KEY,
    aircraft_id       BIGINT      REFERENCES rms.aircraft(aircraft_id),
    airman_id         BIGINT,     -- FK set below (airmen)
    received_at       TIMESTAMPTZ NOT NULL,       -- priority time-stamp
    indexed_at        TIMESTAMPTZ,
    examiner_id       VARCHAR(50),
    qa_reviewer_id    VARCHAR(50),
    status            rms.work_packet_status NOT NULL DEFAULT 'RECEIVED',
    paper_destroyed_at TIMESTAMPTZ,
    retention_schedule VARCHAR(50) NOT NULL,     -- NARA schedule (permanent aircraft, 60yr airmen)
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_workpackets_aircraft ON rms.work_packets(aircraft_id);
CREATE INDEX idx_workpackets_received ON rms.work_packets(received_at);
CREATE INDEX idx_workpackets_status   ON rms.work_packets(status);
COMMENT ON TABLE rms.work_packets IS 'Intake packet — contains all scanned images for one registration/recordation filing.';

CREATE TABLE rms.documents (
    document_id       BIGSERIAL   PRIMARY KEY,
    work_packet_id    BIGINT      NOT NULL REFERENCES rms.work_packets(work_packet_id) ON DELETE CASCADE,
    document_type     VARCHAR(100) NOT NULL,     -- bill_of_sale, application, trust_instrument, passport_copy, etc.
    page_number       INTEGER     NOT NULL DEFAULT 1,
    image_uri         VARCHAR(2048) NOT NULL,    -- storage location (legacy IMS path or cloud URI)
    file_format       rms.document_format NOT NULL,
    file_hash_sha256  CHAR(64)    NOT NULL,
    file_size_bytes   BIGINT      NOT NULL,
    scan_date         DATE,
    scan_resolution_dpi INTEGER,
    ocr_applied       BOOLEAN     NOT NULL DEFAULT FALSE,
    ocr_text          TEXT,
    extracted_entities JSONB,                    -- names, amounts, dates via ML extraction
    paper_original_destroyed BOOLEAN NOT NULL DEFAULT FALSE,
    paper_destruction_date DATE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_documents_workpacket ON rms.documents(work_packet_id);
CREATE INDEX idx_documents_type       ON rms.documents(document_type);
CREATE INDEX idx_documents_hash       ON rms.documents(file_hash_sha256);
COMMENT ON TABLE  rms.documents IS 'Scanned document images (the 174M TIFFs).';
COMMENT ON COLUMN rms.documents.image_uri IS 'Pointer to IMS (legacy) or object-storage location (modernized).';

ALTER TABLE rms.ownership_transfers
    ADD CONSTRAINT fk_transfer_evidence_doc
    FOREIGN KEY (evidence_document_id) REFERENCES rms.documents(document_id);

ALTER TABLE rms.security_interests
    ADD CONSTRAINT fk_lien_instrument_doc
    FOREIGN KEY (instrument_document_id) REFERENCES rms.documents(document_id);

CREATE TABLE rms.document_annotations (
    annotation_id     BIGSERIAL   PRIMARY KEY,
    document_id       BIGINT      NOT NULL REFERENCES rms.documents(document_id) ON DELETE CASCADE,
    annotation_type   VARCHAR(50) NOT NULL,    -- REGISTRATION, RECORDATION, CORRECTION
    annotation_date   TIMESTAMPTZ NOT NULL,
    annotation_text   TEXT        NOT NULL,
    examiner_id       VARCHAR(50) NOT NULL,
    supersedes_annotation_id BIGINT REFERENCES rms.document_annotations(annotation_id),
    is_immutable      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_annotations_document ON rms.document_annotations(document_id);
COMMENT ON TABLE rms.document_annotations IS 'Immutable registration/recordation annotations; corrections create new versions.';

-- -----------------------------------------------------------------------------
-- AIRMEN (CAIS master)
-- -----------------------------------------------------------------------------

CREATE TABLE rms.airmen (
    airman_id            BIGSERIAL   PRIMARY KEY,
    certificate_number   VARCHAR(20) UNIQUE,     -- FAA-assigned; historically SSN
    ssn                  VARCHAR(11),            -- legacy storage for pre-2002 records
    ftn                  VARCHAR(10) UNIQUE,     -- Federal Tracking Number (IACRA-aligned)
    first_name           VARCHAR(100) NOT NULL,
    middle_name          VARCHAR(100),
    last_name            VARCHAR(100) NOT NULL,
    name_suffix          VARCHAR(20),
    date_of_birth        DATE         NOT NULL,
    sex                  CHAR(1)      CHECK (sex IN ('M','F','U')),
    hair_color           VARCHAR(30),
    eye_color            VARCHAR(30),
    height_inches        SMALLINT,
    weight_lbs           SMALLINT,
    nationality          CHAR(2)      REFERENCES rms.countries(country_code),
    place_of_birth_city  VARCHAR(100),
    place_of_birth_state CHAR(2)      REFERENCES rms.us_states(state_code),
    place_of_birth_country CHAR(2)    REFERENCES rms.countries(country_code),
    mailing_address_id   BIGINT       REFERENCES rms.addresses(address_id),
    physical_address_id  BIGINT       REFERENCES rms.addresses(address_id),
    email                VARCHAR(255),
    phone                VARCHAR(30),
    medical_cert_reference VARCHAR(100),        -- pointer to MSS
    status               rms.airman_cert_status NOT NULL DEFAULT 'ISSUED',
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_airmen_name ON rms.airmen(last_name, first_name);
CREATE INDEX idx_airmen_dob  ON rms.airmen(date_of_birth);
CREATE INDEX idx_airmen_ftn  ON rms.airmen(ftn);
COMMENT ON TABLE  rms.airmen IS 'CAIS airman master record (1.5M records).';
COMMENT ON COLUMN rms.airmen.certificate_number IS 'FAA-assigned airman certificate number (replacing SSN).';

ALTER TABLE rms.work_packets
    ADD CONSTRAINT fk_workpacket_airman
    FOREIGN KEY (airman_id) REFERENCES rms.airmen(airman_id);

-- Airman certificates (one airman → many certificates/ratings)
CREATE TABLE rms.airman_certificates (
    airman_cert_id    BIGSERIAL   PRIMARY KEY,
    airman_id         BIGINT      NOT NULL REFERENCES rms.airmen(airman_id) ON DELETE CASCADE,
    certificate_type  VARCHAR(50) NOT NULL,   -- pilot, mechanic, flight_instructor, dispatcher, etc.
    certificate_class VARCHAR(50),             -- private, commercial, ATP, etc.
    ratings           TEXT[],                  -- array of rating codes
    limitations       TEXT[],
    issue_date        DATE        NOT NULL,
    expiration_date   DATE,
    status            rms.airman_cert_status NOT NULL DEFAULT 'ISSUED',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_airman_certs_airman ON rms.airman_certificates(airman_id);
COMMENT ON TABLE rms.airman_certificates IS 'Certificates + ratings held by an airman.';

CREATE TABLE rms.airman_enforcement_actions (
    enforcement_id       BIGSERIAL   PRIMARY KEY,
    airman_id            BIGINT      NOT NULL REFERENCES rms.airmen(airman_id) ON DELETE CASCADE,
    eis_case_id          VARCHAR(50),
    action_type          VARCHAR(50) NOT NULL,  -- SUSPENSION, REVOCATION, CIVIL_PENALTY, DENIAL
    action_date          DATE        NOT NULL,
    regulatory_citation  VARCHAR(200),
    duration_days        INTEGER,
    penalty_amount       NUMERIC(12,2),
    case_status          VARCHAR(30) NOT NULL DEFAULT 'OPEN'
        CHECK (case_status IN ('OPEN','CLOSED','APPEALED','VACATED')),
    case_closed_date     DATE,
    retention_destroy_date DATE
        GENERATED ALWAYS AS (case_closed_date + INTERVAL '5 years') STORED,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_enforcement_airman ON rms.airman_enforcement_actions(airman_id);
COMMENT ON TABLE rms.airman_enforcement_actions IS '5 yr destroy after close per FAA Order 1350.15C Item 2150.5.a.';

CREATE TABLE rms.airman_temp_authorities (
    temp_authority_id    BIGSERIAL   PRIMARY KEY,
    airman_id            BIGINT      NOT NULL REFERENCES rms.airmen(airman_id),
    authority_type       VARCHAR(100) NOT NULL,
    issue_date           DATE        NOT NULL,
    expiration_date      DATE        NOT NULL,
    privileges           TEXT,
    status               VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rms.airman_foreign_license_verifications (
    verification_id      BIGSERIAL   PRIMARY KEY,
    airman_id            BIGINT      NOT NULL REFERENCES rms.airmen(airman_id),
    foreign_authority_country CHAR(2) NOT NULL REFERENCES rms.countries(country_code),
    foreign_license_number VARCHAR(100),
    request_date         DATE        NOT NULL,
    response_date        DATE,
    verification_status  VARCHAR(30)
        CHECK (verification_status IN ('VALID','EXPIRED','REVOKED','UNKNOWN','PENDING')),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- CERTIFICATES OF AIRCRAFT REGISTRATION + RENEWALS
-- -----------------------------------------------------------------------------

CREATE TABLE rms.aircraft_registration_certificates (
    certificate_id         BIGSERIAL   PRIMARY KEY,
    aircraft_id            BIGINT      NOT NULL REFERENCES rms.aircraft(aircraft_id),
    certificate_number     VARCHAR(30) NOT NULL UNIQUE,
    issue_date             DATE        NOT NULL,
    expiration_date        DATE        NOT NULL,    -- 7 years from issue
    mailing_date           DATE,
    delivery_confirmed_date DATE,
    is_superseded          BOOLEAN     NOT NULL DEFAULT FALSE,
    superseded_by          BIGINT      REFERENCES rms.aircraft_registration_certificates(certificate_id),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_regcerts_aircraft ON rms.aircraft_registration_certificates(aircraft_id);
CREATE INDEX idx_regcerts_expiry   ON rms.aircraft_registration_certificates(expiration_date);

CREATE TABLE rms.registration_renewal_notices (
    notice_id             BIGSERIAL   PRIMARY KEY,
    aircraft_id           BIGINT      NOT NULL REFERENCES rms.aircraft(aircraft_id),
    notice_generation_date DATE       NOT NULL,
    mailing_date          DATE,
    recipient_address_id  BIGINT      REFERENCES rms.addresses(address_id),
    security_code         VARCHAR(20) NOT NULL,     -- for online renewal auth
    status                rms.notice_status NOT NULL DEFAULT 'GENERATED',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_renewal_notices_aircraft ON rms.registration_renewal_notices(aircraft_id);
COMMENT ON COLUMN rms.registration_renewal_notices.security_code IS 'Random code required for online renewal; mailed 6 months before expiration.';

CREATE TABLE rms.registration_renewals (
    renewal_id            BIGSERIAL   PRIMARY KEY,
    aircraft_id           BIGINT      NOT NULL REFERENCES rms.aircraft(aircraft_id),
    previous_certificate_id BIGINT    REFERENCES rms.aircraft_registration_certificates(certificate_id),
    renewal_method        VARCHAR(20) NOT NULL
        CHECK (renewal_method IN ('ONLINE_AFFIRM','PAPER','IN_PERSON')),
    renewal_date          DATE        NOT NULL,
    change_of_address     BOOLEAN     NOT NULL DEFAULT FALSE,
    change_of_ownership   BOOLEAN     NOT NULL DEFAULT FALSE,
    payment_transaction_id VARCHAR(100),
    examiner_id           VARCHAR(50),
    status                VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    new_certificate_id    BIGINT      REFERENCES rms.aircraft_registration_certificates(certificate_id),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- PAYMENTS (Pay.gov integration; we store only tx ID)
-- -----------------------------------------------------------------------------

CREATE TABLE rms.payments (
    payment_id            BIGSERIAL   PRIMARY KEY,
    aircraft_id           BIGINT      REFERENCES rms.aircraft(aircraft_id),
    airman_id             BIGINT      REFERENCES rms.airmen(airman_id),
    transaction_type      VARCHAR(50) NOT NULL,   -- REGISTRATION, RENEWAL, RECORDING, DEALER, DUPLICATE_CERT
    amount                NUMERIC(10,2) NOT NULL,
    pay_gov_tx_id         VARCHAR(100) UNIQUE,
    payment_method        VARCHAR(30) NOT NULL,   -- CREDIT_CARD, ACH, CHECK, MONEY_ORDER
    payment_status        rms.payment_status NOT NULL DEFAULT 'PENDING',
    submitted_at          TIMESTAMPTZ,
    cleared_at            TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_payments_aircraft ON rms.payments(aircraft_id);
CREATE INDEX idx_payments_status   ON rms.payments(payment_status);
COMMENT ON TABLE  rms.payments IS 'Fee/payment records; we store Pay.gov tx ID only — no card PAN.';

CREATE TABLE rms.receipts (
    receipt_id        BIGSERIAL   PRIMARY KEY,
    payment_id        BIGINT      NOT NULL REFERENCES rms.payments(payment_id),
    receipt_number    VARCHAR(50) NOT NULL UNIQUE,
    issue_date        DATE        NOT NULL,
    description       TEXT,
    accounting_code   VARCHAR(50),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- DEFICIENCY NOTICES & CORRESPONDENCE
-- -----------------------------------------------------------------------------

CREATE TABLE rms.deficiency_notices (
    notice_id         BIGSERIAL   PRIMARY KEY,
    work_packet_id    BIGINT      NOT NULL REFERENCES rms.work_packets(work_packet_id),
    notice_date       DATE        NOT NULL,
    description       TEXT        NOT NULL,
    response_deadline DATE,
    delivery_method   VARCHAR(20) NOT NULL CHECK (delivery_method IN ('MAIL','EMAIL','FAX','PORTAL')),
    delivered_at      TIMESTAMPTZ,
    response_received_at TIMESTAMPTZ,
    status            rms.notice_status NOT NULL DEFAULT 'GENERATED',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rms.foia_requests (
    foia_id           BIGSERIAL   PRIMARY KEY,
    request_date      DATE        NOT NULL,
    requester_name    VARCHAR(255) NOT NULL,
    requester_address_id BIGINT   REFERENCES rms.addresses(address_id),
    requester_email   VARCHAR(255),
    description       TEXT        NOT NULL,
    n_numbers_requested TEXT[],
    certificate_nums_requested TEXT[],
    status            VARCHAR(30) NOT NULL DEFAULT 'RECEIVED',
    release_date      DATE,
    redaction_notes   TEXT,
    fee_amount        NUMERIC(10,2),
    fee_paid          BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE rms.foia_requests IS 'FOIA records for aircraft and airmen data.';

CREATE TABLE rms.public_data_extracts (
    extract_id        BIGSERIAL   PRIMARY KEY,
    extract_date      DATE        NOT NULL,
    extract_type      VARCHAR(50) NOT NULL,  -- RELEASABLE_AIRMEN, AIRCRAFT_REGISTRY_SNAPSHOT
    file_name         VARCHAR(200) NOT NULL,
    file_size_bytes   BIGINT,
    record_count      BIGINT,
    fields_included   TEXT[],
    sorn_basis        VARCHAR(50),          -- DOT/FAA 801, DOT/FAA 847
    public_uri        VARCHAR(500),
    superseded_by     BIGINT      REFERENCES rms.public_data_extracts(extract_id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE rms.public_data_extracts IS 'Downloadable public data files (daily aircraft snapshot, monthly releasable airmen).';

-- -----------------------------------------------------------------------------
-- AUDIT TRAIL
-- -----------------------------------------------------------------------------

CREATE TABLE rms.audit_log (
    audit_id       BIGSERIAL   PRIMARY KEY,
    event_time     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    event_type     VARCHAR(100) NOT NULL,
    entity_type    VARCHAR(50)  NOT NULL,
    entity_id      BIGINT,
    actor_id       VARCHAR(100),
    actor_role     VARCHAR(50),
    source_ip      INET,
    user_agent     TEXT,
    changes_before JSONB,
    changes_after  JSONB,
    notes          TEXT
);
CREATE INDEX idx_audit_event_time ON rms.audit_log(event_time);
CREATE INDEX idx_audit_entity     ON rms.audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_actor      ON rms.audit_log(actor_id);

-- =============================================================================
-- END OF RMS SCHEMA
-- =============================================================================
