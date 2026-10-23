ALTER TABLE jarvis_privat.filing_target
  ADD COLUMN contact_email text,
  ADD COLUMN contact_email_source text,
  ADD COLUMN contact_email_source_url text,
  ADD COLUMN contact_email_confirmed_at timestamptz,
  ADD CONSTRAINT filing_target_contact_email_source_chk
    CHECK (contact_email_source IS NULL
           OR contact_email_source IN ('rolf', 'dokument', 'web')),
  ADD CONSTRAINT filing_target_contact_email_confirmed_chk
    CHECK (contact_email IS NULL
           OR (contact_email_source IS NOT NULL
               AND contact_email_confirmed_at IS NOT NULL));
