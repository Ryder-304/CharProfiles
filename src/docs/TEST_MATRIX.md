# MVP-Testmatrix

Diese Matrix ist vor einer Veröffentlichung auf zwei getrennten Installationen abzuarbeiten.

| Fall | Erwartetes Ergebnis |
| --- | --- |
| Zwei Charaktere, jeweils drei Profile | Profile erscheinen ausschließlich beim zugehörigen Realm/Charakter. |
| Gleicher Charaktername auf zwei Realms | Die Profile bleiben über Realmname getrennt. |
| Neustart nach Speichern | Alle gültigen Profile bleiben sichtbar. |
| Manipiertes/defektes gespeichertes Profil | Nur das betroffene Profil landet in `quarantined`; übrige bleiben nutzbar. |
| Manuelles Laden eines Profils | Bestätigung erscheint, aktuelle Belegungen werden gesichert, Ergebnis ist vollständig oder teilweise mit Liste. |
| Laden während Kampf | Keine geschützte Änderung; Status meldet Verschiebung; nach Kampf wird einmal fortgesetzt. |
| Fehlender Zauber, Gegenstand oder Makro | Ladevorgang endet teilweise und nennt den betroffenen Platz. |
| Standardprofil nach Login | Wird höchstens einmal pro Sitzung automatisch versucht. |
| Einzelprofil-Code auf zweiter Installation | Vorschau zeigt Herkunft und Inhalt; nach Import ist es gespeichert, aber nicht automatisch geladen. |
| Gesamt-Export mit mehreren Teilen | Fehlende/doppelte/fremde Teile werden ohne Datenänderung abgewiesen. |
| Beschädigte Prüfsumme | Import wird abgewiesen, kein Profil ändert sich. |
| ID-Konflikt `Behalten` | Bestehendes Profil bleibt unverändert. |
| ID-Konflikt `Ersetzen` | Vorherige Fassung liegt in den Sicherungen. |
| ID-Konflikt `Als Kopie` | Beide Profile bleiben mit unterschiedlichen IDs erhalten. |
| Installer: Erstinstallation | Nur `Interface\AddOns\CharProfiles` wird angelegt. |
| Installer: Update | Nur dieser Addon-Ordner wird gesichert/ersetzt; andere Addons und SavedVariables bleiben erhalten. |
| Installer: abgebrochen/unvollständig | Vorheriger Addon-Ordner wird soweit möglich zurückgespielt. |
| Installer: Deinstallation behalten | Addon verschwindet, SavedVariables bleiben. |
| Installer: Deinstallation entfernen | Zweite Bestätigung erforderlich; nur CharProfiles-SavedVariables verschwinden. |
