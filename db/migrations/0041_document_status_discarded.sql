ALTER TABLE jarvis_privat.document DROP CONSTRAINT document_status_check;
ALTER TABLE jarvis_privat.document ADD CONSTRAINT document_status_check CHECK (status = ANY (ARRAY[
  'received','original_secured','text_extracted','fields_extracted','understood','planned','filed',
  'duplicate','unreadable','needs_review','failed','quarantined','discarded','misrouted']::text[]));
ALTER TABLE jarvis_visolva.document DROP CONSTRAINT document_status_check;
ALTER TABLE jarvis_visolva.document ADD CONSTRAINT document_status_check CHECK (status = ANY (ARRAY[
  'received','original_secured','text_extracted','fields_extracted','understood','planned','filed',
  'duplicate','unreadable','needs_review','failed','quarantined','discarded','misrouted']::text[]));
