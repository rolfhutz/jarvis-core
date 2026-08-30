-- =====================================================================
-- JARVIS Phase 1.0 - Erweiterungstabellen im Kontextschema
-- Grundlage: SPEC_PHASE_1_DOKUMENTENASSISTENT_v4.0.2.md, Abschnitt 7.2
--
-- Diese Datei ist eine VORLAGE mit Platzhaltern und wird nicht direkt
-- ausgefuehrt. Das Rendern erfolgt ausschliesslich ueber
--     python3 tools/render_phase1_tables.py --context <context_id>
-- Das Skript uebernimmt Schemaname, Kontextkennung und Datenbankbenutzer
-- ausschliesslich aus der Kontextkonfiguration und prueft sie gegen die
-- gleichen Muster wie tools/render_context_schema.py aus Phase 0.
-- Freie Textersetzung ist unzulaessig.
--
-- Platzhalter:
--   {{SCHEMA}}      Zielschema, z. B. jarvis_privat
--   {{CONTEXT_ID}}  Kontextkennung, z. B. privat
--   {{DB_USER}}     Datenbankbenutzer des Kontexts, z. B. jv_privat_user
--
-- Grundsatz wie in Phase 0: fachliche Inhalte liegen ausschliesslich im
-- Kontextschema. Jede Tabelle traegt die Pruefbedingung
-- context_id = '{{CONTEXT_ID}}' und erhaelt die Sequenzrechte.
--
-- Die Spaltenauswahl folgt den Phase-1-Vertraegen. Felder, die abgefragt,
-- verknuepft oder eindeutig gehalten werden muessen, stehen als eigene
-- Spalte. Das vollstaendige Vertragsobjekt steht zusaetzlich in body,
-- damit die Datenbank keine zweite Wahrheit neben dem JSON-Schema bildet.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Dokumentregister nach document.schema.json
--
-- Spezifikation 7.2: "document_index aus Phase 0 geht in document auf;
-- der Unique-Index auf content_hash bleibt bestehen." Die Phase-0-Tabelle
-- wird deshalb hier abgeloest. Sie ist zu diesem Zeitpunkt leer, weil vor
-- Phase 1.1 kein Dokumenteingang laeuft.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS {{SCHEMA}}.document_index;

CREATE TABLE {{SCHEMA}}.document (
    document_id           text PRIMARY KEY
                          CHECK (document_id ~ '^doc_[0-9A-HJKMNP-TV-Z]{26}$'),
    schema_version        text NOT NULL,
    context_id            text NOT NULL DEFAULT '{{CONTEXT_ID}}',
    status                text NOT NULL CHECK (status IN (
                              'received','original_secured','text_extracted',
                              'fields_extracted','understood','planned','filed',
                              'duplicate','unreadable','needs_review','failed',
                              'quarantined')),

    -- Eingang
    intake_channel        text NOT NULL CHECK (intake_channel IN (
                              'drive_inbox','scan','mobile_photo','manual_upload','api')),
    intake_adapter_id     text NOT NULL,
    source_external_id    text NOT NULL,
    original_filename     text,
    received_at           timestamptz NOT NULL,
    source_event_id       text NOT NULL,

    -- Datei. content_hash ist der harte Dublettenstopp.
    mime_type             text NOT NULL,
    size_bytes            bigint NOT NULL CHECK (size_bytes >= 0),
    page_count            integer CHECK (page_count >= 0),
    content_hash          text NOT NULL
                          CHECK (content_hash ~ '^sha256:[a-f0-9]{64}$'),
    -- Hash des normalisierten Volltextes. Erzeugt einen Dublettenverdacht,
    -- keinen harten Stopp, und ist deshalb bewusst nicht eindeutig.
    text_fingerprint      text,

    -- Einordnung und Vorgangsbezug
    document_type_key     text CHECK (document_type_key ~ '^[a-z][a-z0-9_]{2,63}$'),
    category_key          text CHECK (category_key ~ '^[a-z][a-z0-9_]{2,63}$'),
    case_id               text,
    case_number           text CHECK (case_number ~ '^V-[0-9]{4}-[0-9]{4}$'),
    case_match_method     text CHECK (case_match_method IN (
                              'identifier_match','created_new','user_confirmed','unresolved')),

    -- Manuelle Pruefung und Wiederanlaufpunkt
    review_required       boolean NOT NULL DEFAULT false,
    review_blocked_stage  text,
    last_completed_stage  text,

    -- Dublette und Verweise auf die Auswertungen
    duplicate_of          text REFERENCES {{SCHEMA}}.document(document_id),
    extraction_result_ref text,
    analysis_ref          text,
    analysis_version      text,

    body                  jsonb NOT NULL,
    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT document_context_chk CHECK (context_id = '{{CONTEXT_ID}}'),
    -- Vertragsregel G02: eine Dublette ohne Verweis auf das Original ist unzulaessig.
    CONSTRAINT document_duplicate_requires_original CHECK (
        status <> 'duplicate' OR duplicate_of IS NOT NULL
    )
);
CREATE UNIQUE INDEX document_content_hash_uq ON {{SCHEMA}}.document (content_hash);
CREATE INDEX document_status_idx           ON {{SCHEMA}}.document (status, received_at DESC);
CREATE INDEX document_case_idx             ON {{SCHEMA}}.document (case_id);
CREATE INDEX document_text_fingerprint_idx ON {{SCHEMA}}.document (text_fingerprint);
CREATE INDEX document_source_external_idx  ON {{SCHEMA}}.document (source_external_id);

-- ---------------------------------------------------------------------
-- Vorgaenge nach case.schema.json
--
-- case ist in PostgreSQL ein reserviertes Schluesselwort und wird deshalb
-- durchgaengig in Anfuehrungszeichen geschrieben. Der Tabellenname bleibt
-- damit genau der aus Abschnitt 7.2.
-- ---------------------------------------------------------------------
CREATE TABLE {{SCHEMA}}."case" (
    case_id           text PRIMARY KEY
                      CHECK (case_id ~ '^cse_[0-9A-HJKMNP-TV-Z]{26}$'),
    schema_version    text NOT NULL,
    context_id        text NOT NULL DEFAULT '{{CONTEXT_ID}}',
    case_number       text NOT NULL CHECK (case_number ~ '^V-[0-9]{4}-[0-9]{4}$'),
    title             text NOT NULL,
    category_key      text NOT NULL CHECK (category_key ~ '^[a-z][a-z0-9_]{2,63}$'),
    status            text NOT NULL CHECK (status IN ('open','waiting','closed','archived')),
    next_deadline_at  timestamptz,
    opened_at         timestamptz NOT NULL,
    closed_at         timestamptz,
    body              jsonb NOT NULL,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT case_context_chk CHECK (context_id = '{{CONTEXT_ID}}'),
    -- Vertragsregel G06: ein abgeschlossener Vorgang ohne Abschlusszeitpunkt
    -- ist unzulaessig.
    CONSTRAINT case_closed_requires_timestamp CHECK (
        status <> 'closed' OR closed_at IS NOT NULL
    )
);
CREATE UNIQUE INDEX case_number_uq ON {{SCHEMA}}."case" (case_number);
CREATE INDEX case_status_deadline_idx ON {{SCHEMA}}."case" (status, next_deadline_at);

-- Der Vorgangsbezug des Dokuments wird erst jetzt verknuepfbar, weil beide
-- Tabellen vorhanden sein muessen.
ALTER TABLE {{SCHEMA}}.document
    ADD CONSTRAINT document_case_fk
    FOREIGN KEY (case_id) REFERENCES {{SCHEMA}}."case"(case_id);

-- ---------------------------------------------------------------------
-- Normalisierte Kennungen je Vorgang
--
-- Grundlage der automatischen Vorgangszuordnung. Der Unique-Index auf
-- (identifier_type, value_normalized) stellt sicher, dass dieselbe Kennung
-- nicht zwei Vorgaenge erzeugt.
-- ---------------------------------------------------------------------
CREATE TABLE {{SCHEMA}}.case_identifier (
    case_identifier_id     bigserial PRIMARY KEY,
    context_id             text NOT NULL DEFAULT '{{CONTEXT_ID}}',
    case_id                text NOT NULL REFERENCES {{SCHEMA}}."case"(case_id),
    identifier_type        text NOT NULL CHECK (identifier_type IN (
                               'policy_number','contract_number','case_number_external',
                               'customer_number','invoice_number','reference_number',
                               'tax_number','other')),
    value_normalized       text NOT NULL
                           CHECK (char_length(value_normalized) BETWEEN 2 AND 100),
    issuer                 text CHECK (issuer IS NULL OR char_length(issuer) <= 200),
    first_seen_document_id text REFERENCES {{SCHEMA}}.document(document_id),
    created_at             timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT case_identifier_context_chk CHECK (context_id = '{{CONTEXT_ID}}')
);
CREATE UNIQUE INDEX case_identifier_value_uq
    ON {{SCHEMA}}.case_identifier (identifier_type, value_normalized);
CREATE INDEX case_identifier_case_idx ON {{SCHEMA}}.case_identifier (case_id);

-- ---------------------------------------------------------------------
-- Volltext und Seitenstruktur
--
-- Ein Dokument hat genau einen gueltigen Textstand, deshalb ist
-- document_id zugleich Primaerschluessel. content_hash bindet den Text an
-- die Datei, aus der er gewonnen wurde.
-- ---------------------------------------------------------------------
CREATE TABLE {{SCHEMA}}.document_text (
    document_id          text PRIMARY KEY REFERENCES {{SCHEMA}}.document(document_id),
    context_id           text NOT NULL DEFAULT '{{CONTEXT_ID}}',
    content_hash         text NOT NULL
                         CHECK (content_hash ~ '^sha256:[a-f0-9]{64}$'),
    page_count           integer NOT NULL CHECK (page_count >= 0),
    text_character_count integer CHECK (text_character_count >= 0),
    mean_confidence      numeric(4,3) CHECK (mean_confidence BETWEEN 0 AND 1),
    is_scanned           boolean,
    detected_language    text CHECK (detected_language IS NULL OR char_length(detected_language) <= 10),
    provider_job_id      text,
    full_text            text NOT NULL,
    pages                jsonb NOT NULL,
    extracted_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT document_text_context_chk CHECK (context_id = '{{CONTEXT_ID}}')
);

-- ---------------------------------------------------------------------
-- Extraktionsergebnisse nach extraction_result.schema.json
--
-- Mehrere Laeufe je Dokument sind moeglich, etwa nach einer Klaerung.
-- Der juengste Lauf gewinnt; aeltere bleiben als Nachweis erhalten.
-- ---------------------------------------------------------------------
CREATE TABLE {{SCHEMA}}.document_extraction (
    extraction_id                  bigserial PRIMARY KEY,
    context_id                     text NOT NULL DEFAULT '{{CONTEXT_ID}}',
    document_id                    text NOT NULL REFERENCES {{SCHEMA}}.document(document_id),
    schema_version                 text NOT NULL,
    extracted_at                   timestamptz NOT NULL,
    model_role                     text NOT NULL,
    model_ref                      text NOT NULL,
    prompt_version                 text NOT NULL,
    normalization_registry_version text NOT NULL,
    field_count                    integer NOT NULL DEFAULT 0 CHECK (field_count >= 0),
    line_item_count                integer NOT NULL DEFAULT 0 CHECK (line_item_count >= 0),
    body                           jsonb NOT NULL,
    created_at                     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT document_extraction_context_chk CHECK (context_id = '{{CONTEXT_ID}}')
);
CREATE INDEX document_extraction_doc_idx
    ON {{SCHEMA}}.document_extraction (document_id, extracted_at DESC);

-- ---------------------------------------------------------------------
-- Analysen nach document_analysis.schema.json
-- ---------------------------------------------------------------------
CREATE TABLE {{SCHEMA}}.document_analysis (
    analysis_id        bigserial PRIMARY KEY,
    context_id         text NOT NULL DEFAULT '{{CONTEXT_ID}}',
    document_id        text NOT NULL REFERENCES {{SCHEMA}}.document(document_id),
    schema_version     text NOT NULL,
    analyzed_at        timestamptz NOT NULL,
    model_role         text NOT NULL,
    model_ref          text NOT NULL,
    prompt_version     text NOT NULL,
    subject_de         text NOT NULL,
    summary_de         text NOT NULL,
    overall_confidence numeric(4,3) NOT NULL CHECK (overall_confidence BETWEEN 0 AND 1),
    proposed_task_count integer NOT NULL DEFAULT 0 CHECK (proposed_task_count >= 0),
    body               jsonb NOT NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT document_analysis_context_chk CHECK (context_id = '{{CONTEXT_ID}}')
);
CREATE INDEX document_analysis_doc_idx
    ON {{SCHEMA}}.document_analysis (document_id, analyzed_at DESC);

-- ---------------------------------------------------------------------
-- Fortlaufende Vorgangsnummer je Kontext und Jahr
--
-- Die Vorgangsnummer hat die Form V-JJJJ-NNNN und ist Bestandteil des
-- Dateinamens. Die Vergabe laeuft ueber next_case_number(): ein einziges
-- INSERT ... ON CONFLICT DO UPDATE sperrt die Jahreszeile und gibt die
-- naechste Nummer zurueck. Zwei parallele Laeufe koennen dadurch nicht
-- dieselbe Nummer erhalten.
-- ---------------------------------------------------------------------
CREATE TABLE {{SCHEMA}}.case_number_seq (
    context_id   text NOT NULL DEFAULT '{{CONTEXT_ID}}',
    year         integer NOT NULL CHECK (year BETWEEN 2000 AND 2999),
    last_number  integer NOT NULL DEFAULT 0 CHECK (last_number BETWEEN 0 AND 9999),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (context_id, year),
    CONSTRAINT case_number_seq_context_chk CHECK (context_id = '{{CONTEXT_ID}}')
);

CREATE OR REPLACE FUNCTION {{SCHEMA}}.next_case_number(p_year integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_number integer;
BEGIN
    INSERT INTO {{SCHEMA}}.case_number_seq (context_id, year, last_number, updated_at)
    VALUES ('{{CONTEXT_ID}}', p_year, 1, now())
    ON CONFLICT (context_id, year) DO UPDATE
        SET last_number = {{SCHEMA}}.case_number_seq.last_number + 1,
            updated_at  = now()
    RETURNING last_number INTO v_number;

    RETURN 'V-' || to_char(p_year, 'FM0000') || '-' || to_char(v_number, 'FM0000');
END;
$$;

-- ---------------------------------------------------------------------
-- Abgegrenzter Testbereich fuer test.record_approved_action
--
-- Klasse C wird in Phase 1 ausschliesslich ueber dieses Werkzeug geprueft.
-- Es loest bewusst keine externe Kommunikation aus.
-- ---------------------------------------------------------------------
CREATE TABLE {{SCHEMA}}.test_approval_record (
    record_id          text PRIMARY KEY,
    context_id         text NOT NULL DEFAULT '{{CONTEXT_ID}}',
    action_id          text NOT NULL,
    approval_id        text NOT NULL,
    action_fingerprint text NOT NULL
                       CHECK (action_fingerprint ~ '^sha256:[a-f0-9]{64}$'),
    test_label         text NOT NULL CHECK (char_length(test_label) BETWEEN 3 AND 200),
    requested_at       timestamptz NOT NULL,
    recorded_at        timestamptz NOT NULL DEFAULT now(),
    result_status      text NOT NULL CHECK (result_status IN (
                           'recorded','rejected_fingerprint_mismatch',
                           'rejected_approval_invalid','rejected_wrong_context')),
    CONSTRAINT test_approval_record_context_chk CHECK (context_id = '{{CONTEXT_ID}}')
);
CREATE INDEX test_approval_record_action_idx
    ON {{SCHEMA}}.test_approval_record (action_id);

-- =====================================================================
-- Rechtevergabe fuer den Kontextbenutzer
--
-- Gleiche Aufteilung wie in Phase 0: Arbeitstabellen lesen, schreiben und
-- aendern; kein DELETE, weil ein Dokument- oder Vorgangssatz fachlich
-- korrigiert und nicht entfernt wird.
-- =====================================================================
GRANT SELECT, INSERT, UPDATE ON
    {{SCHEMA}}.document,
    {{SCHEMA}}."case",
    {{SCHEMA}}.case_identifier,
    {{SCHEMA}}.document_text,
    {{SCHEMA}}.document_extraction,
    {{SCHEMA}}.document_analysis,
    {{SCHEMA}}.case_number_seq,
    {{SCHEMA}}.test_approval_record
TO {{DB_USER}};

-- Die bigserial-Spalten der neuen Tabellen brauchen USAGE auf ihren
-- Sequenzen, sonst schlaegt jedes INSERT fehl.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA {{SCHEMA}} TO {{DB_USER}};

-- Nummernvergabe
GRANT EXECUTE ON FUNCTION {{SCHEMA}}.next_case_number(integer) TO {{DB_USER}};

-- Ausdrueckliche Entzuege
REVOKE DELETE, TRUNCATE ON
    {{SCHEMA}}.document,
    {{SCHEMA}}."case",
    {{SCHEMA}}.case_identifier,
    {{SCHEMA}}.document_text,
    {{SCHEMA}}.document_extraction,
    {{SCHEMA}}.document_analysis,
    {{SCHEMA}}.case_number_seq,
    {{SCHEMA}}.test_approval_record
FROM {{DB_USER}};
