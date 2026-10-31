-- 0046_sicherung_export.sql
-- CR-19 / TS-13 (Rolf 31.10.2026: Sicherung «n8n → eigenes Drive»): Lesende Exportfunktion für die wöchentliche Sicherung.
-- Liefert alle Basistabellen eines JARVIS-Schemas als JSON. SECURITY INVOKER: jede Kontextrolle sieht nur,
-- was sie ohnehin lesen darf (jv_privat_user: jarvis_privat + jarvis_ops; jv_visolva_user: jarvis_visolva + jarvis_ops).
-- Keine Daten, keine Zugangsdaten. Wiederholbar (create or replace).

begin;

create or replace function jarvis_ops.f_sicherung(p_schema text)
returns jsonb
language plpgsql stable security invoker
set search_path = pg_catalog
as $$
declare
  r record;
  daten jsonb;
  tabellen jsonb := '{}'::jsonb;
  zeilen jsonb := '{}'::jsonb;
begin
  if p_schema is null or p_schema not in ('jarvis_privat', 'jarvis_visolva', 'jarvis_ops') then
    raise exception 'Sicherung: Schema % nicht zulaessig', p_schema using errcode = '22023';
  end if;
  for r in
    select c.relname as tabelle
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = p_schema and c.relkind in ('r', 'p')
    order by c.relname
  loop
    execute format('select coalesce(jsonb_agg(to_jsonb(x)), ''[]''::jsonb) from %I.%I x', p_schema, r.tabelle) into daten;
    tabellen := tabellen || jsonb_build_object(r.tabelle, daten);
    zeilen := zeilen || jsonb_build_object(r.tabelle, jsonb_array_length(daten));
  end loop;
  return jsonb_build_object(
    'format', 'jarvis-sicherung-1',
    'schema', p_schema,
    'erstellt', to_char(now() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'zeilen', zeilen,
    'tabellen', tabellen);
end
$$;

comment on function jarvis_ops.f_sicherung(text) is
  'CR-19/TS-13: Export aller Basistabellen eines JARVIS-Schemas als JSON fuer die woechentliche Sicherung. Nur lesend, Rechte des Aufrufers.';

revoke all on function jarvis_ops.f_sicherung(text) from public;
grant execute on function jarvis_ops.f_sicherung(text) to jv_privat_user, jv_visolva_user;

commit;
