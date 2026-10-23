-- DT-1: In der Repository-Fassung ist die Beispiel-Versicherungsnummer in Regel N6 neutralisiert (1.234.567);
-- eingespielt ist die Fassung mit der echten Nummer (Migrationshistorie). Fachlich gleichwertig.
alter table jarvis_privat.document_fall
  add column versandform_standard text not null default 'email';

alter table jarvis_privat.document_fall
  add constraint document_fall_versandform_chk
  check (versandform_standard in ('email','brief','brief_email','brief_email_post'));

comment on column jarvis_privat.document_fall.versandform_standard is
  'CR-16 E1: Vorgeschlagene Versandform. Wird durch formerfordernis aus der Analyse und durch Rolfs Auswahl je Aktion übersteuert (gespeichert in task.body.versandform).';

insert into jarvis_privat.document_fall
  (fall_key, context_id, label_de, kurzinfo_de, gruppe, analyse_tiefe,
   hinweis_platzhalter, hinweis_pflicht, titel_vorlage, auftrag_satz, entwurf_regeln,
   betreff_muster, adresse_zweck, termin_label, termin_standard,
   empfaenger_ist_absender, mit_anhang, versandform_standard, sort_order, active)
values
  ('nachreichen', 'privat', 'Unterschrieben nachreichen',
   'Brief zum Unterschreiben plus E-Mail-Entwurf – Versand per E-Mail und Post durch dich.',
   'entwurf', 'voll',
   'Was soll nachgereicht werden? z. B. Kündigung erneut, diesmal unterschrieben',
   false,
   'Unterschriebenes Schreiben an {name} senden',
   'das vom Absender beanstandete oder nachgeforderte Schreiben neu und vollständig zu erstellen, damit Rolf es unterschreibt und erneut einreicht',
   'N1. Erstelle das nachgeforderte Schreiben vollständig neu (nicht nur einen Begleitsatz). Beispiel: Wurde eine Kündigung wegen fehlender Unterschrift zurückgewiesen, erstelle eine vollständige Kündigungserklärung.
N2. Nenne Datum und Bezugsnummer des beanstandenden Schreibens und alle Vertrags- oder Policennummern.
N3. Der Brief endet mit Ort, Datum und einer Unterschriftszeile für Rolf (Name in Druckschrift darunter).
N4. Inhaltliche Angaben (z. B. Kündigungstermin, Grund) nur aus Rolfs Hinweis oder aus dem Dokument; sonst nächstmöglicher Termin bzw. [bitte ergänzen: …].
N5. formvorschrift: Verlangt das Dokument Unterschrift, Original oder eingeschriebenen Brief, setze schriftlich bzw. eingeschrieben mit Beleg.
N6. betreff: Bezug auf das beanstandete Schreiben und die Bezugsnummer, z. B. «Kündigung – erneut mit Unterschrift – Vers.-Nr. 1.234.567».
N7. Der begleitende E-Mail-Text ist kurz: Verweis auf das unterschriebene Schreiben im Anhang und den zusätzlichen Versand per Post.',
   null, 'die Einreichung eines unterschriebenen Schreibens', null, null,
   true, false, 'brief_email_post', 95, true);

insert into jarvis_privat.vorgang_typ
  (vorgang_key, context_id, label_de, erkennung_de, sort_order, active)
values
  ('nachforderung', 'privat', 'Nachforderung / Zurückweisung',
   'Die Gegenseite weist eine Einreichung zurück oder fordert etwas nach: fehlende Unterschrift, fehlende Unterlagen, unvollständiger Antrag, unwirksame Kündigung.',
   75, true);

insert into jarvis_privat.vorgang_option
  (vorgang_key, fall_key, label_de, bedingung_de, hinweis_de, sort_order, active)
values
  ('nachforderung', 'nachreichen', 'Unterschrieben nachreichen (Brief + E-Mail + Post)', null,
   'Empfohlen, wenn Unterschrift oder Original verlangt wird.', 10, true),
  ('nachforderung', 'antworten', 'Rückfrage an den Absender', null, null, 20, true),
  ('nachforderung', 'einreichen', 'Fehlende Unterlagen einreichen',
   'Das Dokument fordert Unterlagen oder Belege nach.', null, 30, true),
  ('nachforderung', 'ablegen', 'Nur ablegen', null,
   'Die ursprüngliche Einreichung bleibt dann unwirksam.', 90, true);
