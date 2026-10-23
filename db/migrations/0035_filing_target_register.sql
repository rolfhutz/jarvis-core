-- Datentrennung DT-1 (Rolf, 23.10.2026): Die persönlichen Registerziele (Anbieter, Vertragsnummern, Drive-Ordner) liegen nicht im öffentlichen Repository.
-- Private Ergänzung: Claude-Projekt «JARVIS – Persönlicher KI-Assistent», Datei claude/privat_daten/0035_filing_target_register.privat.sql
-- Wiederherstellung: zuerst diese Datei, danach die private Ergänzung. In der Datenbank eingespielt ist die
-- Gesamtfassung (Migrationshistorie, Name 0035_filing_target_register).
create table jarvis_privat.filing_target (
    target_id        text primary key,
    context_id       text not null default 'privat' check (context_id = 'privat'),
    category_key     text not null,
    sub_key          text,
    provider_key     text not null,
    provider_label   text not null,
    folder_name      text not null,
    drive_folder_id  text unique,
    aliases          text[] not null default '{}',
    identifiers      text[] not null default '{}',
    active           boolean not null default true,
    created_by       text not null default 'migration',
    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now(),
    constraint filing_target_provider_key_fmt check (provider_key ~ '^[a-z0-9_]+$'),
    constraint filing_target_rule_fk foreign key (category_key)
        references jarvis_privat.filing_rule (category_key)
);

create unique index filing_target_uq
    on jarvis_privat.filing_target (context_id, category_key, coalesce(sub_key, ''), provider_key);
create index filing_target_aliases_gin     on jarvis_privat.filing_target using gin (aliases);
create index filing_target_identifiers_gin on jarvis_privat.filing_target using gin (identifiers);

comment on table jarvis_privat.filing_target is
  'CR-06: Ablageregister. Vorrang vor KI-Kategorie (E3 A). Ein Ordner je Anbieter und Sparte (E2 A); Vertragsnummern in identifiers.';

grant select, insert, update on jarvis_privat.filing_target to jv_privat_user;

update jarvis_privat.filing_rule
   set label_de    = 'Gesundheit, Arzt & Behandlung',
       folder_name = '08_Gesundheit_Arzt_Behandlung',
       updated_at  = now()
 where category_key = 'gesundheit_krankenkasse' and context_id = 'privat';
