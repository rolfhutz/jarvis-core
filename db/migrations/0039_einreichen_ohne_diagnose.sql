UPDATE jarvis_privat.document_fall
SET entwurf_regeln = entwurf_regeln || E'\nE7. Keine Diagnosen, Befunde, Behandlungs- oder sonstigen Gesundheitsangaben im Text, auch wenn sie im Dokument stehen – sie gehen mit dem Anhang. Nenne nur Dokumentart, Aussteller, Datum, Rechnungs- oder Belegnummer, Betrag und betroffene Person.',
    updated_at = now()
WHERE fall_key = 'einreichen' AND position('E7.' in entwurf_regeln) = 0;
