# CharProfiles – Umsetzungsplan

**Stand:** 01.11.2026  
**Grundlage:** `CharProfiles_Requirements.md`, Version 0.5  
**Ziel der ersten Version:** WoW TBC Classic/Anniversary unter Windows  
**Architekturziel:** WoW Forever später mit einem eigenen Client-Adapter ergänzen können

## 1. Festgelegter Umfang

- Das Addon verwaltet Profile je Charakter und stellt Tastaturbelegungen und Aktionsleisten wieder her.
- Profile lassen sich im Spiel als Textcode exportieren und importieren. Das gilt für ein einzelnes Profil und für alle Profile zusammen.
- Ein Windows-Installer installiert, aktualisiert und deinstalliert das Addon. Ein separates Windows-Werkzeug für den Profiltransfer ist für die erste Version nicht vorgesehen.
- Alle Kernfunktionen funktionieren ohne Konto, Cloud-Dienst und Internetverbindung.
- Die ursprünglichen Requirements nennen WoW Forever. Für die erste Version gilt die spätere Festlegung auf **TBC Classic/Anniversary**. Die Codebasis wird für WoW Forever vorbereitet; die tatsächliche Unterstützung folgt erst nach einer eigenen Kompatibilitätsprüfung.

## 2. Technischer Vorabcheck – Voraussetzung für die Implementierung

Die genaue Client-Buildnummer ist noch unbekannt. Vor der eigentlichen Entwicklung wird an einer aktuellen TBC-Classic/Anniversary-Installation geprüft:

1. Client-Build, Addon-Interface-Version, Addon-Verzeichnis und Ablageort der gespeicherten Addon-Daten ermitteln.
2. Mit einem kleinen Testaddon prüfen, ob Profildaten nach Ausloggen, Neustart und Charakterwechsel zuverlässig erhalten bleiben.
3. Für jede relevante Kategorie prüfen, was sich auslesen und wiederherstellen lässt: normale Aktionsleisten, Spezialleisten, Zauber, Gegenstände, Makros und Tastaturbelegungen.
4. Die Grenzen bei Kampf, Ladebildschirm, fehlenden Fähigkeiten und gesperrten Aktionen prüfen. Änderungen gegebenenfalls bis zu einem zulässigen Zeitpunkt aufschieben.
5. Prüfen, wie lange ein Textcode im Import-/Exportfenster praktikabel sein darf; bei Bedarf ein Mehrteilformat festlegen.

**Ergebnis:** Eine kurze, je Client wiederverwendbare Kompatibilitätsmatrix mit `vollständig`, `eingeschränkt` oder `nicht möglich` je Datentyp und der bestätigten Client-Buildnummer. Nur bestätigte Funktionen werden für das MVP zugesagt. Für nicht unterstützte Einträge wird eine verständliche Warnung vorgesehen.

## 3. Architektur für eine spätere WoW-Forever-Version

- **Gemeinsamer Kern:** Profilverwaltung, Datenprüfung, Sicherungen, Bedienoberfläche, Textcode-Format, Importkonflikte und Statusmeldungen enthalten keine direkten Aufrufe einer bestimmten WoW-Client-API.
- **Client-Adapter:** Ein klar abgegrenztes Modul liefert Clientkennung und Fähigkeiten und übernimmt das Erfassen, Prüfen und Anwenden von Tastaturbelegungen und Aktionsleisten. Es kapselt abweichende UI- und Ereignis-APIs und entscheidet, wann eine Wiederherstellung zulässig ist. Die erste Implementierung ist der TBC-Adapter; für WoW Forever kommt später ein eigener Adapter hinzu.
- **Ein gemeinsames Profilformat:** Profil- und Exportformat erhalten eine eigene Schema-Version sowie Herkunftsclient und Build als Metadaten. Aktionen werden soweit möglich über stabile Typen und Kennungen beschrieben. Client-spezifische Daten liegen in einem getrennten optionalen Bereich; der gemeinsame Kern interpretiert sie nicht.
- **Kontrollierter Transfer zwischen Clients:** Ein Textcode aus einem anderen Client darf geprüft und in der Vorschau gezeigt werden. Vor einer Übernahme zeigt das Addon nicht unterstützte Einträge an und bewahrt sie im importierten Profil für einen späteren Export auf. Ohne bestätigte Zuordnung und ausdrückliches Laden werden importierte Inhalte nicht angewendet. Eine vollständige Übertragbarkeit zwischen TBC und WoW Forever wird nicht vorausgesetzt.
- **Getrennte Pakete aus einer Codebasis:** Metadaten, Interface-Version und Adapter werden je Zielclient verpackt. Der Installer verwendet je Client eine eigene Erkennungs- und Zielordnerdefinition; Pfade sind nicht im gemeinsamen Kern hinterlegt.
- **Gemeinsame Prüfbeispiele:** Dieselben Beispielprofile, Textcodes und Prüffälle werden gegen jeden Adapter ausgeführt. So bleiben Änderungen für WoW Forever von der TBC-Version nachvollziehbar getrennt.

**Architektur-Abnahme:** Im gemeinsamen Kern und im Textcode-Format gibt es keine fest codierten TBC-Interface-Versionen, Spielordner oder direkten TBC-API-Aufrufe. Der TBC-Adapter ist als austauschbares Modul angebunden.

## 4. Umsetzung in Arbeitspaketen

### AP1 – Addon-Grundgerüst und Datenmodell

- Gemeinsamen Kern, Adapter-Schnittstelle und TBC-spezifisches Addon-Paket anlegen. Die bestätigte TBC-Interface-Version steht nur in dessen Metadaten.
- Versioniertes, clientneutrales Profilschema definieren: stabile Profil-ID, Name, Charakterzuordnung, Standardprofil, Belegungen, Aktionsleisten, Erstellungs-/Änderungszeit und Formatversion. Herkunftsclient und Build werden mitgespeichert.
- Mehrere Profile je Charakter und eine eindeutige Zuordnung auch bei gleichen Charakternamen auf verschiedenen Realms unterstützen.
- Gespeicherte Daten beim Laden prüfen und spätere Formatmigrationen vorbereiten. Defekte Einträge isolieren, damit übrige Profile nutzbar bleiben.
- Änderungen an Profilen so speichern, dass ein Abbruch nicht stillschweigend bestehende Profildaten überschreibt.

**Fertig, wenn:** Zwei Charaktere mit je mehreren Profilen nach Spielneustart korrekt angezeigt werden, ein fehlerhaftes Profil die übrigen nicht blockiert und die Profilverwaltung ohne TBC-spezifische API-Aufrufe arbeitet.

### AP2 – Belegungen erfassen und wiederherstellen

- Standard-Tastaturbelegungen und die im Vorabcheck bestätigten Aktionsleistenplätze ausschließlich über den TBC-Adapter erfassen.
- Für Aktionsplätze portable Referenzen auf Zauber, Gegenstände und Makros verwenden, soweit der Client sie bereitstellt; nicht wiederherstellbare Inhalte protokollieren.
- Vor einem manuellen Ladevorgang Änderungen mit einer Bestätigung und einer temporären Sicherung absichern. Bei automatischem Laden muss die Standardprofil-Zuordnung zuvor bewusst eingerichtet worden sein.
- Zulässigkeit und Zeitpunkt der Wiederherstellung über den Adapter prüfen; bei Bedarf auf später verschieben und den Status anzeigen.
- Ergebnis als `vollständig`, `teilweise` oder `fehlgeschlagen` melden, einschließlich betroffener Plätze/Belegungen. Eine Rücknahme über die Sicherung anbieten.

**Fertig, wenn:** Ein Testprofil mit verschiedenen Belegungs- und Aktionstypen nach einer Änderung reproduzierbar wiederhergestellt wird und fehlende Inhalte sichtbar gemeldet werden.

### AP3 – Profilverwaltung und Bedienung im Spiel

- Übersicht nach Charakter mit Profilname und Kennzeichnung des Standardprofils bauen.
- Erstellen, aktuellen Zustand speichern, laden, umbenennen, duplizieren, löschen und Standardprofil setzen.
- Bestätigung beim Überschreiben und Löschen; manuelle Sicherung/Wiederherstellung innerhalb der Profilverwaltung.
- Standardprofil beim Einloggen oder Charakterwechsel automatisch laden, soweit AP2 dies zulässt. Wiederholtes Laden in derselben Sitzung vermeiden.
- Statusmeldungen und einen einfachen Einstieg per Chatbefehl und/oder Addon-Menü bereitstellen.

**Fertig, wenn:** Die genannten Aktionen ohne Dateibearbeitung möglich sind und ein gesetztes Standardprofil beim Charakterwechsel korrekt geladen wird.

### AP4 – Export und Import per Textcode

- Ein versioniertes, prüfbares und clientneutrales Textformat für ein Profil und ein Gesamtpaket aller Profile festlegen. Der Code enthält Herkunftsclient und Schema-Version, aber keine Zugangsdaten.
- Exportfenster mit markierbarem Code; Importfenster zum Einfügen und Prüfen des Codes.
- Vor dem Import Inhalt, Herkunftsclient, betroffene Charaktere/Profile, mögliche Konflikte und im Zielclient nicht unterstützte Inhalte anzeigen.
- Für Konflikte `behalten`, `ersetzen` oder `als Kopie importieren` anbieten. Vor einem Ersetzen eine Sicherung erzeugen.
- Unbekannte Formatversionen, beschädigte Codes, unzulässige Größen und doppelte Teile mit klarer Fehlermeldung abweisen. Falls nötig, Gesamtpakete in nummerierte Teile mit Prüfsumme aufteilen.
- Importierte Profile zunächst speichern; ihre Anwendung auf einen Charakter erfordert eine bewusste Zuordnung bzw. einen Ladevorgang. Ein Code eines anderen Clients darf keine automatische Wiederherstellung auslösen.

**Fertig, wenn:** Einzelprofil und Gesamtpaket per Kopieren/Einfügen auf einer zweiten Installation importiert werden können; alle drei Konfliktoptionen funktionieren und ein beschädigter Code verändert keine Daten.

### AP5 – Windows-Installer

- Die TBC-Installation anhand einer austauschbaren Client-Definition suchen und bei keinem oder mehreren Treffern eine manuelle Ordnerwahl anbieten. Den Zielordner vor der Installation zeigen und validieren.
- Nur den eigenen Addon-Ordner installieren und bei Aktualisierung gezielt dessen alte Dateien ersetzen. Andere Addons und Spieldateien nicht anfassen.
- Vor Aktualisierung die vorhandenen CharProfiles-Daten am für diesen Client ermittelten Speicherort sichern und nachher die vollständige neue Installation prüfen. Bei Fehler den vorherigen Addon-Zustand wiederherstellen.
- Deinstallation mit Auswahl `persönliche Profile behalten` oder `Profile ebenfalls entfernen`; vor endgültigem Entfernen der Profildaten ausdrücklich bestätigen.
- Installations- und Fehlerergebnis verständlich anzeigen. Keine Online-Versionsprüfung voraussetzen.

**Fertig, wenn:** Erstinstallation, Aktualisierung, abgebrochene Aktualisierung und beide Deinstallationswege auf einer Testinstallation geprüft sind; andere Addons sowie persönliche Profile gemäß Auswahl erhalten bleiben.

### AP6 – Abnahme und Veröffentlichung

- Testmatrix für mindestens zwei Charaktere, mehrere Profile, frische und vorhandene Installation sowie zwei PCs/Installationen abarbeiten.
- Grenzfälle prüfen: Kampf, fehlender Zauber/Gegenstand/Makro, beschädigte Profildaten, ungültiger Textcode, Importkonflikt, mehrere Spielordner, fehlende Schreibrechte und unterbrochene Aktualisierung.
- Kurze Benutzeranleitung für Profilwechsel, Textcode-Transfer, Sicherung und Installer beilegen.
- Addon-Version, Profilschema-Version, Zielclient, getestete Client-Buildnummer und bekannte Einschränkungen in der Veröffentlichung dokumentieren.

**Fertig, wenn:** Alle MVP-Abnahmekriterien erfüllt sind und verbleibende technische Grenzen konkret dokumentiert sind.

## 5. Reihenfolge und Abhängigkeiten

`Vorabcheck → AP1 → AP2 → AP3 → AP4 → AP5 → AP6`

AP5 kann nach Festlegung der Addon-Dateistruktur parallel zu AP3/AP4 vorbereitet werden. Die endgültige Installer-Abnahme benötigt ein fertiges Addon-Paket.

## 6. MVP-Abnahmekriterien

1. Ein Nutzer kann pro Charakter mehrere benannte Profile speichern und ein Standardprofil festlegen.
2. Bestätigte Tastatur- und Aktionsleisteninhalte werden gespeichert und geladen; Einschränkungen werden je Eintrag angezeigt.
3. Das Standardprofil wird beim Charakterwechsel automatisch angewendet, sofern der Spielzustand dies erlaubt.
4. Einzelne und alle Profile können per Textcode ohne Internet zwischen zwei Installationen übertragen werden.
5. Importkonflikte haben die drei vorgesehenen Optionen; Ersetzen und Löschen sind abgesichert.
6. Der Installer findet oder akzeptiert den TBC-Spielordner, ersetzt bei Updates nur CharProfiles-Dateien und erhält persönliche Daten.
7. Bei Installation, Import und Profilwiederherstellung werden Fehler sichtbar gemeldet und vorhandene Daten nicht stillschweigend gelöscht.
8. Profilverwaltung, Import/Export und Bedienoberfläche verwenden für clientabhängige Funktionen ausschließlich die Adapter-Schnittstelle; TBC-spezifische API-Aufrufe und Pfade liegen nur in Adapter beziehungsweise Client-Definition.

## 7. Anschlussarbeit für WoW Forever

1. Den Vorabcheck aus Abschnitt 2 mit einem tatsächlichen WoW-Forever-Client wiederholen und die Ergebnisse mit TBC vergleichen.
2. Den Forever-Adapter für die dort bestätigten Fähigkeiten implementieren; nicht verfügbare Aktionstypen ausdrücklich als solche melden.
3. Eigene Addon-Metadaten und eine Installer-Client-Definition für WoW Forever ergänzen. Beide Spielinstallationen getrennt erkennen, installieren und aktualisieren.
4. Textcode-Import zwischen TBC und Forever mit Vorschau, bewusster Charakterzuordnung und Teilwiederherstellung testen.
5. Die vollständigen Abnahmefälle aus AP6 für Forever erneut ausführen und die unterstützten Funktionen je Client veröffentlichen.

**Freigabebedingung:** Erst nach bestandener Kompatibilitäts- und Regressionprüfung wird ein WoW-Forever-Paket angeboten. Der gemeinsame Kern und das Datenformat sollen dafür nicht neu geschrieben werden müssen.

## 8. Noch zu klären beziehungsweise technisch zu bestätigen

- Exakte TBC-Classic/Anniversary-Buildnummer und Addon-Interface-Version am Zielclient.
- Welche Aktions- und Belegungstypen die aktuelle Client-API tatsächlich vollständig wiederherstellen lässt.
- Praktische maximale Länge eines Textcodes; davon hängt ab, ob der Export aller Profile in mehrere Teile zerlegt werden muss.
- Verhalten der spielinternen charakterbezogenen Tastaturbelegungen im Zusammenspiel mit CharProfiles.
- Spätere WoW-Forever-Fähigkeiten und Unterschiede des Speicherorts, der Addon-Metadaten sowie der Aktionsleisten-API; diese werden beim Forever-Vorabcheck erhoben.

Die TBC-Punkte werden im ersten Vorabcheck vor AP2 und AP4 entschieden. Die WoW-Forever-Punkte gehören zum späteren Vorabcheck aus Abschnitt 7.
