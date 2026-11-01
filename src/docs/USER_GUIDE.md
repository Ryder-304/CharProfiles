# CharProfiles – Kurzanleitung

Öffne die Verwaltung mit `/cp` oder `/charprofiles`.

1. Namen eingeben und **Neu erfassen** wählen, um den aktuellen Zustand als Profil zu speichern.
2. Ein Profil in der Liste auswählen. **Aktualisieren** speichert den aktuellen Zustand in dieses Profil; **Laden** legt vorher eine temporäre Sicherung an.
3. Mit **Als Standard** wird das Profil beim nächsten Login dieses Charakters geladen, falls der Spielzustand dies zulässt.
4. Über **Profil exportieren** oder **Alle exportieren** den sichtbaren Text vollständig kopieren. Bei mehreren Teilen müssen alle Zeilen gemeinsam übertragen werden.
5. Auf dem Zielrechner **Importieren**, Code einfügen und **Prüfen** wählen. Die Vorschau nennt Herkunft, Konflikte und Einschränkungen. Erst danach eine Konfliktoption wählen.

Die drei Importoptionen sind:

- **Behalten**: Ein vorhandenes Profil mit derselben ID bleibt unverändert.
- **Ersetzen**: Das vorhandene Profil wird vorher als Sicherung abgelegt und dann ersetzt.
- **Als Kopie**: Das importierte Profil bekommt eine neue ID und bleibt neben dem vorhandenen erhalten.

Wichtige Statusmeldungen: `vollständig` bedeutet, dass der Adapter keinen Fehler meldete; `teilweise` nennt nicht anwendbare Belegungen oder Aktionsplätze; `verschoben` bedeutet, dass während Kampf oder eines gesperrten Zustands auf einen zulässigen Zeitpunkt gewartet wird.
