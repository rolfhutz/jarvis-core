CREATE UNIQUE INDEX filing_target_person_uq ON jarvis_privat.filing_target (context_id, person_key, category_key, COALESCE(sub_key, ''::text), provider_key);
