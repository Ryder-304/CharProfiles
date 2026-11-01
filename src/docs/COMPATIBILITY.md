# Kompatibilitätsmatrix – TBC Classic / Anniversary

Stand: Implementierungsentwurf. Die folgende Matrix ist ausdrücklich **keine** Zusage für einen bestimmten Live-Client, bis der Vorabcheck mit Buildnummer dokumentiert ist.

| Bereich | Status | Adapter-Verhalten | Vor dem Release prüfen |
| --- | --- | --- | --- |
| Gespeicherte Variablen je Charakter | eingeschränkt | Kern speichert Profile in `CharProfilesDB`; defekte Profile werden isoliert | Ausloggen, Neustart, Charakterwechsel |
| Normale Tastaturbelegungen | eingeschränkt | Adapter liest `GetBinding` und schreibt per `SetBinding`/`SaveBindings` | Bindungsset, geschützte Tasten, charakterbezogene Bindungen |
| Zauber auf Aktionsleisten | eingeschränkt | portable Zauber-ID plus Name; Wiederherstellung via `PickupSpell`/`PlaceAction` | alle verfügbaren Leisten und Kampf-Lockdown |
| Gegenstände auf Aktionsleisten | eingeschränkt | Item-ID plus Anzeige-Metadaten; Wiederherstellung per `PickupItem` | ausgerüstete, Taschen- und nicht vorhandene Items |
| Makros auf Aktionsleisten | eingeschränkt | Name und Makrotext; nur vorhandene identische Makros werden zugeordnet | globale/charakterbezogene Makros und Makrolimits |
| Weitere Aktionstypen | nicht möglich | unverändert mitgespeichert, beim Laden klar als fehlend gemeldet | je Typ nach dem Vorabcheck bewerten |
| Wiederherstellung im Kampf | nicht möglich | wird bis `PLAYER_REGEN_ENABLED` aufgeschoben | tatsächliches Clientverhalten prüfen |
| Andere Herkunftsclients | eingeschränkt | Importvorschau warnt; Inhalte werden nicht automatisch angewendet | später mit Forever-Adapter testen |

## Pflichtprotokoll für den Vorabcheck

Vor dem MVP-Release müssen hier ergänzt werden:

1. exakte Clientversion, Buildnummer und bestätigte `.toc`-Interfaceversion;
2. Addon- und SavedVariables-Speicherort;
3. je Matrixzeile Ergebnis `vollständig`, `eingeschränkt` oder `nicht möglich` samt kurzem Reproduktionsschritt;
4. praxisgetestete maximale Exportcode-Länge und gegebenenfalls gewählte Teilgröße;
5. bekannte Einschränkungen, die in die Release Notes gehören.
