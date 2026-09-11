-- =====================================================================
-- JARVIS Phase 1.1b - Migration 0022 - Kontextwurzel verpflichtend
--
-- Entscheidung 1.1b-E1 vom 11.09.2026 (Rolf). Schritt 3 von 3 (siehe 0020).
-- Bricht ab, wenn ein Kontext ohne Wurzel oder mit einem anderen Stand als
-- config_version 1.1.0 geladen ist; dann zuerst 0021 einspielen.
--
-- Wiederholbar: SET NOT NULL auf einer bereits verpflichtenden Spalte ist
-- wirkungslos; die Selbstpruefung laeuft erneut.
-- Haengt ab von: 0020, 0021.
-- =====================================================================

DO $$
DECLARE
    v_bad text;
BEGIN
    SELECT string_agg(context_id || ':' || coalesce(context_root_ref, 'ohne_wurzel') || ':' || config_version, ', ')
      INTO v_bad
      FROM jarvis_ops.context_document_settings
     WHERE context_root_ref IS NULL OR config_version <> '1.1.0';
    IF v_bad IS NOT NULL THEN
        RAISE EXCEPTION 'context_root_missing: % (zuerst 0021 einspielen)', v_bad USING ERRCODE = '23502';
    END IF;
END
$$;

ALTER TABLE jarvis_ops.context_document_settings
    ALTER COLUMN context_root_ref SET NOT NULL;

-- Selbstpruefung: jeder aktive Kontext hat Einstellungen mit Wurzel.
DO $$
DECLARE
    v_bad text;
BEGIN
    SELECT string_agg(r.context_id, ', ') INTO v_bad
      FROM jarvis_ops.context_registry r
      LEFT JOIN jarvis_ops.context_document_settings s ON s.context_id = r.context_id
     WHERE r.status = 'active' AND s.context_root_ref IS NULL;
    IF v_bad IS NOT NULL THEN
        RAISE EXCEPTION 'context_root_missing: aktiver Kontext ohne Wurzel: %', v_bad USING ERRCODE = '23502';
    END IF;
END
$$;
