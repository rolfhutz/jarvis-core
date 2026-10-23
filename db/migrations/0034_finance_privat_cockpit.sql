-- Datentrennung DT-1 (Rolf, 23.10.2026): Die persönlichen Startwerte (Periode, Zuordnungen, Buchungsfreigaben) liegen nicht im öffentlichen Repository.
-- Private Ergänzung: Claude-Projekt «JARVIS – Persönlicher KI-Assistent», Datei claude/privat_daten/0034_finance_privat_cockpit.privat.sql
-- Wiederherstellung: zuerst diese Datei, danach die private Ergänzung. In der Datenbank eingespielt ist die
-- Gesamtfassung (Migrationshistorie, Name 0034_finance_privat_cockpit).
ALTER TABLE jarvis_privat.finance_category
  ADD COLUMN cockpit_label text UNIQUE;
ALTER TABLE jarvis_privat.finance_budget_item
  ADD COLUMN cockpit_ref text UNIQUE,
  ADD COLUMN next_due    date,
  ADD COLUMN updated_at  timestamptz NOT NULL DEFAULT now();
ALTER TABLE jarvis_privat.finance_budget_item
  DROP CONSTRAINT finance_budget_item_rhythm_check,
  ADD  CONSTRAINT finance_budget_item_rhythm_check
       CHECK (rhythm IN ('monatlich','zweimonatlich','vierteljaehrlich','halbjaehrlich','jaehrlich','einmalig'));
ALTER TABLE jarvis_privat.finance_transaction
  ADD COLUMN trade_date     date,
  ADD COLUMN review_status  text CHECK (review_status IN ('offen','frei')),
  ADD COLUMN klass          text CHECK (klass IN ('budget','fix','miete','karte','umbuchung','einnahme','extra')),
  ADD COLUMN budget_item_id uuid REFERENCES jarvis_privat.finance_budget_item(item_id),
  ADD COLUMN note           text,
  ADD COLUMN chat           jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN released_at    timestamptz,
  ADD COLUMN cockpit_doc_id text UNIQUE,
  ADD CONSTRAINT finance_transaction_release_check
      CHECK (review_status IS DISTINCT FROM 'frei' OR (klass IS NOT NULL AND released_at IS NOT NULL)),
  ADD CONSTRAINT finance_transaction_fix_ref_check
      CHECK (review_status IS DISTINCT FROM 'frei' OR klass IS DISTINCT FROM 'fix' OR budget_item_id IS NOT NULL),
  ADD CONSTRAINT finance_transaction_chat_check
      CHECK (jsonb_typeof(chat) = 'array');
CREATE INDEX finance_transaction_trade_idx  ON jarvis_privat.finance_transaction (trade_date);
CREATE INDEX finance_transaction_review_idx ON jarvis_privat.finance_transaction (review_status) WHERE review_status = 'offen';
CREATE TABLE jarvis_privat.finance_period (
  period_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  context_id      text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  start_date      date NOT NULL UNIQUE,
  end_date        date NOT NULL,
  end_confirmed   boolean NOT NULL DEFAULT false,
  salary_chf      numeric(14,2) NOT NULL CHECK (salary_chf >= 0),
  bonus_chf       numeric(14,2) NOT NULL DEFAULT 0 CHECK (bonus_chf >= 0),
  salary_source   text,
  fix_chf         numeric(14,2) NOT NULL CHECK (fix_chf >= 0),
  transfer_chf    numeric(14,2) NOT NULL CHECK (transfer_chf >= 0),
  fx_plan         numeric(10,6) NOT NULL DEFAULT 1.0 CHECK (fx_plan > 0),
  carina_eur      numeric(14,2) NOT NULL DEFAULT 0,
  fix_eur         numeric(14,2) NOT NULL CHECK (fix_eur >= 0),
  start_value_eur numeric(14,2) GENERATED ALWAYS AS (round(transfer_chf * fx_plan + carina_eur - fix_eur, 2)) STORED,
  acc_note        text,
  cc_note         text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CHECK (start_date <= end_date)
);
CREATE TABLE jarvis_privat.finance_windfall (
  windfall_key text PRIMARY KEY,
  context_id   text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  period_id    uuid NOT NULL REFERENCES jarvis_privat.finance_period(period_id),
  label        text NOT NULL,
  amount       numeric(14,2) NOT NULL CHECK (amount > 0),
  currency     char(3) NOT NULL DEFAULT 'EUR' CHECK (currency IN ('EUR','CHF')),
  tx_id        uuid REFERENCES jarvis_privat.finance_transaction(tx_id),
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE VIEW jarvis_privat.finance_account_balance_v AS
SELECT DISTINCT ON (i.account_key)
       i.account_key, a.label_de, a.currency, i.balance_end, i.balance_date, i.status AS import_status
FROM jarvis_privat.finance_import i
JOIN jarvis_privat.finance_account a USING (account_key)
WHERE i.balance_end IS NOT NULL
ORDER BY i.account_key, i.balance_date DESC NULLS LAST, i.created_at DESC;
CREATE VIEW jarvis_privat.finance_period_status_v AS
WITH p AS (
  SELECT *, (end_date - start_date + 1) AS days,
         GREATEST(1, LEAST(end_date - start_date + 1, current_date - start_date + 1)) AS day_no
  FROM jarvis_privat.finance_period
), t AS (
  SELECT p.period_id,
         COALESCE(sum(x.amount) FILTER (WHERE x.klass IN ('budget','extra')), 0)                              AS effect_all,
         COALESCE(sum(x.amount) FILTER (WHERE x.klass IN ('budget','extra') AND x.review_status = 'frei'), 0) AS effect_released,
         count(*) FILTER (WHERE x.review_status = 'offen')                                                     AS open_count
  FROM p LEFT JOIN jarvis_privat.finance_transaction x
    ON COALESCE(x.trade_date, x.value_date, x.booking_date) BETWEEN p.start_date AND p.end_date
   AND x.review_status IS NOT NULL
  GROUP BY p.period_id
)
SELECT p.period_id, p.start_date, p.end_date, p.end_confirmed, p.days, p.day_no,
       p.start_value_eur,
       round(p.start_value_eur + t.effect_all, 2)                                  AS free_eur,
       round(p.start_value_eur + t.effect_released, 2)                             AS free_released_eur,
       round((p.start_value_eur + t.effect_all) / (p.days - p.day_no + 1), 2)      AS per_day_eur,
       t.open_count
FROM p JOIN t USING (period_id);
GRANT SELECT, INSERT, UPDATE ON jarvis_privat.finance_period, jarvis_privat.finance_windfall TO jv_privat_user;
GRANT SELECT ON jarvis_privat.finance_account_balance_v, jarvis_privat.finance_period_status_v TO jv_privat_user;
