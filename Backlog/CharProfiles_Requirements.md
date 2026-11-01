# CharProfiles – Anforderungen

**Version:** 0.5  
**Status:** Entwurf  
**Zielplattform:** WoW Forever und Windows

## 1. Ziel des Projekts

CharProfiles soll die persönlichen Tastaturbelegungen und Skill-Anordnungen je WoW-Charakter einfach verwalten. Gespeicherte Profile sollen sich bequem wiederherstellen und zwischen mehreren PCs übertragen lassen. Die Installation und Aktualisierung soll über einen benutzerfreundlichen Windows-Installer möglich sein.

Das Projekt soll ohne Cloud-Konto und ohne Online-Synchronisierung nutzbar sein.

## 2. Charakterbezogene Profile

- Für jeden Charakter sollen eigene Profile angelegt und gespeichert werden können.
- Profile sollen die Zuordnung von Tasten zu Aktionen sowie die Belegung der Aktionsleisten mit Fähigkeiten enthalten.
- Beim Wechsel auf einen anderen Charakter soll automatisch dessen zugeordnetes Profil geladen werden können.
- Eine manuelle Profilauswahl und ein manueller Ladevorgang sollen ebenfalls möglich sein.
- Der Nutzer soll Profile verständlich benennen können.
- Es soll möglich sein, mehrere Profile für einen Charakter anzulegen, zum Beispiel für PvE und PvP.

## 3. Tastaturbelegungen und Aktionsleisten

- Tastaturbelegungen sollen als Bestandteil eines Profils gespeichert werden.
- Die Anordnung von Fähigkeiten und Aktionen auf den Aktionsleisten soll als Bestandteil eines Profils gespeichert werden.
- Die gespeicherten Belegungen sollen beim Laden eines Profils so weit wie möglich wiederhergestellt werden.
- Vor dem Ersetzen bestehender Belegungen soll bei Bedarf eine Bestätigung oder Sicherung angeboten werden.
- Falls bestimmte Aktionen nicht wiederhergestellt werden können, soll eine verständliche Meldung erscheinen.

## 4. Profilverwaltung

- Profile erstellen, speichern, laden, umbenennen und löschen.
- Bestehende Profile duplizieren.
- Ein Standardprofil pro Charakter festlegen.
- Vorhandene Profile und ihre Zuordnung übersichtlich anzeigen.
- Beim Überschreiben oder Löschen eine Bestätigung anbieten.
- Eine manuelle Sicherung und Wiederherstellung ermöglichen.

## 5. Export und Import zwischen PCs

- Ein einzelnes Profil oder alle Profile gemeinsam exportieren.
- Exportierte Profile auf einem anderen PC importieren.
- Die Übertragung soll beispielsweise per USB-Stick, Netzwerkordner oder beliebigem Dateispeicher möglich sein.
- Beim Import soll erkennbar sein, welche Profile enthalten sind.
- Bei gleichnamigen oder bereits vorhandenen Profilen soll der Nutzer zwischen Behalten, Ersetzen und Importieren als Kopie wählen können.
- Vor dem Ersetzen vorhandener Daten soll eine Sicherung möglich sein.
- Der Export und Import soll ohne Anmeldung und ohne Cloud-Dienst funktionieren.

## 6. Benutzeroberfläche im Spiel

- Übersichtliche Bedienung zur Verwaltung der Charakterprofile.
- Einfacher Zugriff auf die wichtigsten Funktionen: Speichern, Laden, Profilwechsel, Export/Import (soweit im Spiel möglich).
- Klare Status- und Fehlermeldungen.
- Möglichst wenig manuelle Schritte für alltägliche Aufgaben.

## 7. Windows-Installer

### 7.1 Erstinstallation

- Den Installationsordner von WoW Forever nach Möglichkeit automatisch erkennen.
- Wird der Spielordner nicht gefunden oder gibt es mehrere Installationen, soll eine manuelle Auswahl möglich sein.
- Den gewählten Zielordner vor der Installation anzeigen.
- Die Addon-Dateien an der richtigen Stelle installieren.
- Eine erfolgreiche Installation verständlich bestätigen.

### 7.2 Erneute Installation / Aktualisierung

- Erkennen, ob CharProfiles bereits installiert ist.
- Vor dem Austausch auf Wunsch beziehungsweise nach Möglichkeit vorhandene Profile und Einstellungen sichern.
- Bei einer erneuten Installation die **alten CharProfiles-Addon-Dateien entfernen** und anschließend die **neuen Dateien installieren**.
- Persönliche Profile und Einstellungen dürfen dabei nicht unbeabsichtigt gelöscht werden.
- Andere Addons und die WoW-Installation selbst dürfen nicht verändert oder entfernt werden.
- Nach der Installation prüfen, ob die neue Version vollständig vorhanden ist.
- Bei einem Fehler möglichst eine Wiederherstellung des vorherigen Zustands anbieten.
- Für diesen Ablauf ist keine automatische Prüfung auf neue Versionen im Internet erforderlich.

### 7.3 Deinstallation

- CharProfiles gezielt entfernen können.
- Dem Nutzer die Wahl lassen, ob persönliche Profile und Einstellungen aufbewahrt oder ebenfalls entfernt werden sollen.
- Andere Spieldaten und Addons unangetastet lassen.

## 8. Datensicherheit und Verlässlichkeit

- Bestehende Profile möglichst vor riskanten Änderungen sichern.
- Keine stillschweigenden Löschungen oder Überschreibungen persönlicher Einstellungen.
- Verständliche Hinweise bei unvollständigen oder fehlerhaften Profilen.
- Die Kernfunktionen sollen ohne aktive Internetverbindung nutzbar sein.

## 9. Nicht vorgesehen

- Keine eigene CharProfiles-Cloud.
- Keine automatische Synchronisierung zwischen PCs.
- Kein verpflichtendes Nutzerkonto.
- Keine dauerhafte Hintergrundanwendung nur zur Cloud-Synchronisierung.

## 10. Prioritäten

### Erste Version (MVP)

- Charakterbezogene Profile.
- Speichern und Wiederherstellen von Tastatur- und Skill-Belegungen.
- Automatisches Laden des zugeordneten Charakterprofils, soweit unterstützt.
- Grundlegende Profilverwaltung.
- Manueller Export und Import zwischen PCs.
- Windows-Installer mit automatischer Pfadsuche und manueller Ausweichmöglichkeit.
- Saubere Neuinstallation bei vorhandener Addon-Version unter Erhalt persönlicher Einstellungen.

### Mögliche spätere Erweiterungen

- Erweiterte Profilvorlagen und komfortables Kopieren zwischen Charakteren.
- Zusätzliche Sicherungsoptionen und Verlauf früherer Profile.
- Verbesserte Vorschau und Vergleich von Profiländerungen.

## 11. Offene Punkte zur späteren Klärung

- Welche konkrete WoW-Forever-Clientversion wird verwendet?
- Welche Aktionsleisten und Belegungen sind in dieser Version durch Addons zugänglich und wiederherstellbar?
- Welche Profilaktionen sollen direkt im Spiel möglich sein, und welche im Windows-Installer beziehungsweise einem optionalen Begleitwerkzeug?

**Hinweis:** Dieses Dokument beschreibt gewünschte Funktionen, nicht deren technische Umsetzung. Die tatsächliche Umsetzbarkeit einzelner Spielfunktionen muss für die verwendete WoW-Forever-Version geprüft werden.
