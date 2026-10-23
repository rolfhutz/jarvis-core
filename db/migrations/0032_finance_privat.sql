-- 0032_finance_privat
-- Finanzmodul F1 (CR-04): Konten, Importe, Buchungen, Kategorien, Budget, Regeln.
-- Kontext: ausschliesslich privat. Keine IBAN im Klartext (nur letzte 4 Stellen).
-- Beträge als numeric(14,2), nie float. Zugriff wie bestehende Tabellen: jv_privat_user ohne DELETE.

CREATE TABLE jarvis_privat.finance_account (
  account_key   text PRIMARY KEY,
  context_id    text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  institution   text NOT NULL,
  label_de      text NOT NULL,
  currency      char(3) NOT NULL CHECK (currency IN ('EUR','CHF')),
  account_type  text NOT NULL CHECK (account_type IN ('giro','kreditkarte')),
  iban_last4    text CHECK (iban_last4 ~ '^[0-9A-Z]{4}$'),
  upload_rhythm text NOT NULL CHECK (upload_rhythm IN ('taeglich','monatlich')),
  role_note     text,
  sort_order    integer NOT NULL DEFAULT 100,
  active        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE jarvis_privat.finance_category (
  category_key  text PRIMARY KEY,
  context_id    text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  label_de      text NOT NULL,
  kind          text NOT NULL CHECK (kind IN ('fix','variabel','einnahme','intern')),
  sort_order    integer NOT NULL DEFAULT 100,
  active        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE jarvis_privat.finance_import (
  import_id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  context_id          text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  account_key         text NOT NULL REFERENCES jarvis_privat.finance_account(account_key),
  source_file_name    text NOT NULL,
  source_sha256       text NOT NULL CHECK (source_sha256 ~ '^[0-9a-f]{64}$'),
  source_format       text NOT NULL CHECK (source_format IN ('pdf','csv','screenshot')),
  period_from         date,
  period_to           date,
  balance_end         numeric(14,2),
  balance_date        date,
  header_debit_total  numeric(14,2),
  header_credit_total numeric(14,2),
  parsed_debit_total  numeric(14,2),
  parsed_credit_total numeric(14,2),
  tx_new              integer NOT NULL DEFAULT 0,
  tx_duplicate        integer NOT NULL DEFAULT 0,
  status              text NOT NULL CHECK (status IN ('parsed','reconciled','incomplete','rejected')),
  note                text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (account_key, source_sha256),
  CHECK (period_from IS NULL OR period_to IS NULL OR period_from <= period_to)
);

CREATE TABLE jarvis_privat.finance_transaction (
  tx_id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  context_id           text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  account_key          text NOT NULL REFERENCES jarvis_privat.finance_account(account_key),
  import_id            uuid NOT NULL REFERENCES jarvis_privat.finance_import(import_id),
  booking_date         date NOT NULL,
  value_date           date,
  amount               numeric(14,2) NOT NULL CHECK (amount <> 0),
  currency             char(3) NOT NULL CHECK (currency IN ('EUR','CHF')),
  counterparty         text,
  description          text NOT NULL,
  category_key         text REFERENCES jarvis_privat.finance_category(category_key),
  category_source      text CHECK (category_source IN ('regel','llm','manuell')),
  is_internal_transfer boolean NOT NULL DEFAULT false,
  cash_purpose         text,
  dedupe_key           text NOT NULL,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  UNIQUE (account_key, dedupe_key)
);
CREATE INDEX finance_transaction_booking_idx ON jarvis_privat.finance_transaction (booking_date);
CREATE INDEX finance_transaction_category_idx ON jarvis_privat.finance_transaction (category_key);

CREATE TABLE jarvis_privat.finance_budget_item (
  item_id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  context_id       text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  category_key     text NOT NULL REFERENCES jarvis_privat.finance_category(category_key),
  label_de         text NOT NULL,
  item_type        text NOT NULL CHECK (item_type IN ('einnahme','ausgabe')),
  amount           numeric(14,2) NOT NULL CHECK (amount >= 0),
  currency         char(3) NOT NULL CHECK (currency IN ('EUR','CHF')),
  rhythm           text NOT NULL CHECK (rhythm IN ('monatlich','zweimonatlich','vierteljaehrlich','halbjaehrlich','jaehrlich')),
  rhythm_confirmed boolean NOT NULL DEFAULT false,
  payment_account  text REFERENCES jarvis_privat.finance_account(account_key),
  payment_method   text NOT NULL DEFAULT 'konto' CHECK (payment_method IN ('konto','bar')),
  due_day          smallint CHECK (due_day BETWEEN 1 AND 31),
  match_pattern    text,
  source           text NOT NULL CHECK (source IN ('budget_tool','entdeckt','manuell')),
  reserve_in_start boolean NOT NULL DEFAULT true,
  active           boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE jarvis_privat.finance_category_rule (
  rule_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  context_id    text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  pattern       text NOT NULL,
  category_key  text NOT NULL REFERENCES jarvis_privat.finance_category(category_key),
  is_internal   boolean NOT NULL DEFAULT false,
  priority      integer NOT NULL DEFAULT 100,
  source        text NOT NULL DEFAULT 'migration' CHECK (source IN ('migration','manuell','gelernt')),
  active        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE jarvis_privat.finance_setting (
  setting_key   text PRIMARY KEY,
  context_id    text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  value         jsonb NOT NULL,
  note          text,
  updated_at    timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE ON
  jarvis_privat.finance_account, jarvis_privat.finance_category, jarvis_privat.finance_import,
  jarvis_privat.finance_transaction, jarvis_privat.finance_budget_item,
  jarvis_privat.finance_category_rule, jarvis_privat.finance_setting
TO jv_privat_user;
