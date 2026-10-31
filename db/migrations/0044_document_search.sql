-- 0044_document_search.sql
-- CR-12 E4 A (freigegeben 31.10.2026 «alles A»): Suche über Volltext und Metadaten im Kontext privat.
-- Nur lesende Suchfunktion + Suchspalten/Indizes. Keine Fachdaten, keine Zugangsdaten.
-- Repository-Fassung: Beispielnummern in Kommentaren neutralisiert (DT-1); Code identisch mit der eingespielten Fassung.

begin;

create extension if not exists pg_trgm with schema extensions;
create extension if not exists unaccent with schema extensions;

-- Suchnormalisierung: klein, ohne Akzente, Umlaut-Schreibweisen vereinheitlicht (ä/ae -> a usw.), nur a-z0-9 und Leerzeichen.
create or replace function jarvis_privat.f_suchnorm(t text)
returns text language sql immutable strict parallel safe as $$
  select btrim(regexp_replace(
           replace(replace(replace(
             lower(extensions.unaccent('extensions.unaccent'::regdictionary, replace(replace(replace(replace(lower(t), 'ä', 'a'), 'ö', 'o'), 'ü', 'u'), 'ß', 'ss'))),
           'ae', 'a'), 'oe', 'o'), 'ue', 'u'),
         '[^a-z0-9]+', ' ', 'g'))
$$;

-- Nummernnormalisierung: nur a-z0-9 ohne Trennzeichen (1.234.567 = 1-234-567 = 1234567).
create or replace function jarvis_privat.f_suchkompakt(t text)
returns text language sql immutable strict parallel safe as $$
  select regexp_replace(lower(t), '[^a-z0-9]+', '', 'g')
$$;

alter table jarvis_privat.document_text
  add column search_text    text generated always as (jarvis_privat.f_suchnorm(coalesce(full_text, ''))) stored,
  add column search_kompakt text generated always as (jarvis_privat.f_suchkompakt(coalesce(full_text, ''))) stored;

create index document_text_search_text_trgm    on jarvis_privat.document_text using gin (search_text extensions.gin_trgm_ops);
create index document_text_search_kompakt_trgm on jarvis_privat.document_text using gin (search_kompakt extensions.gin_trgm_ops);

-- Suchfunktion: jedes Suchwort muss vorkommen (UND). Wort -> Wortstamm (german_stem) als Teilstring,
-- Nummernwoerter (mind. 5 Zeichen mit Ziffer) kompakt gegen Kennungen und Text; Kennung trifft auch, wenn sie (ab 7 Zeichen, >= 60 %) in der Suchnummer steckt (12345678901/2X = 12345678901-2).
-- Durchsucht Volltext, Dateiname, Absender, Betreff, Dokumentart, Kennungen. Verworfene/fehlgeleitete Dokumente ausgeschlossen.
create or replace function jarvis_privat.document_search(
  p_q text, p_person text default null, p_kategorie text default null,
  p_von date default null, p_bis date default null, p_limit integer default 30)
returns table (document_id text, person_key text, status text, kategorie_key text, dokumentdatum text, titel text, absender text,
               ablage text, link text, ausschnitt text, quelle_volltext boolean, treffer_rang real)
language sql stable security invoker set search_path = jarvis_privat, extensions, pg_catalog as $$
  with w as (
    select x.wort, nullif(jarvis_privat.f_suchkompakt(x.roh), '') as kompakt,
           coalesce((ts_lexize('german_stem', x.wort))[1], x.wort) as stamm,
           (x.roh ~ '[0-9]' and length(jarvis_privat.f_suchkompakt(x.roh)) >= 5) as ist_nummer
    from (select r as roh, jarvis_privat.f_suchnorm(r) as wort
            from regexp_split_to_table(btrim(coalesce(p_q, '')), '\s+') r) x
    where length(x.wort) >= 2
  ),
  n as (select count(*) as anzahl from w),
  d as (
    select dd.document_id, dd.person_key, dd.status, dd.category_key, dd.original_filename, dd.body->'filing' as f, a.body->'ki' as ki,
           t.search_text, t.search_kompakt, t.full_text,
           jarvis_privat.f_suchnorm(concat_ws(' ', dd.body->'filing'->>'file_name', dd.original_filename, a.body->'ki'->>'absender', a.body->'ki'->>'absender_kurz',
             a.body->'ki'->>'betreff_kurz', a.body->'ki'->>'dokumentart', a.body->'ki'->>'kernvorgang')) as meta_text,
           coalesce((select string_agg(jarvis_privat.f_suchkompakt(k->>'wert'), ' ') from jsonb_array_elements(
             case when jsonb_typeof(a.body->'ki'->'kennungen') = 'array' then a.body->'ki'->'kennungen' else '[]'::jsonb end) k), '') as kenn_kompakt
    from jarvis_privat.document dd
    left join jarvis_privat.document_text t on t.document_id = dd.document_id
    left join lateral (select y.body from jarvis_privat.document_analysis y where y.document_id = dd.document_id
                       order by y.analyzed_at desc, y.analysis_id desc limit 1) a on true
    where dd.context_id = 'privat' and dd.status not in ('discarded', 'misrouted')
      and (p_person is null or dd.person_key = p_person)
      and (p_kategorie is null or coalesce(dd.body->'filing'->'anfrage'->>'kategorie_key', dd.category_key) = p_kategorie)
  ),
  m as (
    select d.*,
      (select count(*) from w where
         (w.ist_nummer and (strpos(coalesce(d.search_kompakt, ''), w.kompakt) > 0 or exists (select 1 from unnest(string_to_array(d.kenn_kompakt, ' ')) kk(k)
                      where strpos(kk.k, w.kompakt) > 0
                         or (length(kk.k) >= 7 and strpos(w.kompakt, kk.k) > 0 and length(kk.k) >= 0.6 * length(w.kompakt))) or strpos(jarvis_privat.f_suchkompakt(d.meta_text), w.kompakt) > 0))
         or (not w.ist_nummer and (strpos(coalesce(d.search_text, ''), w.stamm) > 0 or strpos(d.meta_text, w.stamm) > 0))) as getroffen,
      (select count(*) from w where not w.ist_nummer and strpos(d.meta_text, w.stamm) > 0) as meta_treffer,
      (select min(nullif(strpos(coalesce(d.search_text, ''), w.stamm), 0)) from w where not w.ist_nummer) as pos
    from d
  )
  select m.document_id, m.person_key, m.status, coalesce(m.f->'anfrage'->>'kategorie_key', m.category_key),
         m.ki->>'dokumentdatum', coalesce(m.ki->>'betreff_kurz', m.ki->>'dokumentart', m.original_filename), m.ki->>'absender_kurz',
         m.f->>'target_path', m.f->>'web_link',
         case when m.pos is not null then left(substr(m.search_text, greatest(m.pos - 80, 1), 220), 220) end,
         m.full_text is not null,
         (m.meta_treffer * 2 + m.getroffen)::real
  from m, n
  where n.anzahl > 0 and m.getroffen = n.anzahl
    and (p_von is null or (m.ki->>'dokumentdatum') >= p_von::text)
    and (p_bis is null or (m.ki->>'dokumentdatum') <= p_bis::text)
  order by (m.meta_treffer * 2 + m.getroffen) desc, m.ki->>'dokumentdatum' desc nulls last
  limit least(greatest(coalesce(p_limit, 30), 1), 100)
$$;

revoke all on function jarvis_privat.document_search(text, text, text, date, date, integer) from public;
grant execute on function jarvis_privat.document_search(text, text, text, date, date, integer) to jv_privat_user;
grant execute on function jarvis_privat.f_suchnorm(text), jarvis_privat.f_suchkompakt(text) to jv_privat_user;
-- Test 31.10.2026: ohne USAGE auf Schema extensions scheitert unaccent fuer jv_privat_user.
grant usage on schema extensions to jv_privat_user;

comment on function jarvis_privat.document_search(text, text, text, date, date, integer) is
  'CR-12 E4: Suche ueber Volltext + Metadaten (Dateiname, Absender, Betreff, Kennungen); Woerter UND-verknuepft, Wortstamm als Teilstring, Nummern schreibweisenunabhaengig. Nur lesend.';

commit;
