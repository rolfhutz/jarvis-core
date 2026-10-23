ALTER TABLE jarvis_ops.context_document_settings ADD COLUMN IF NOT EXISTS todo_list_name text;
UPDATE jarvis_ops.context_document_settings SET todo_list_name = 'JARVIS privat' WHERE context_id = 'privat';
CREATE INDEX IF NOT EXISTS task_document_idx ON jarvis_privat.task ((body->>'document_id'));
