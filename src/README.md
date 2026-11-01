# CharProfiles – Quellcode

Dieses Verzeichnis enthält die erste TBC-Classic/Anniversary-Implementierung. Das Addon benötigt keine Cloud, kein Konto und keine Netzwerkverbindung.

## Struktur

- `CharProfiles/Core`: clientneutraler Profilspeicher, Schema, Sicherungen und Textcode.
- `CharProfiles/Adapters/TBCClassic.lua`: einzige Stelle für TBC-spezifische Bindungs- und Aktionsleisten-APIs.
- `CharProfiles/UI`: gemeinsame In-Game-Bedienung.
- `installer`: Inno-Setup-Quelle samt separater TBC-Clientdefinition.
- `docs`: Kompatibilitätsstatus, Testmatrix und Benutzeranleitung.

Zum lokalen Testen den Ordner `CharProfiles` nach `<WoW>\Interface\AddOns\CharProfiles` kopieren. Die `.toc` nutzt vorläufig Interface `20505`; sie muss gegen den tatsächlich geprüften Zielbuild bestätigt und bei Bedarf angepasst werden.

## Entwicklungsgrenzen

Der aktuelle Clientbuild und die unterstützten APIs sind noch nicht gegen eine reale Zielinstallation geprüft. Die Implementierung verschiebt Wiederherstellungen im Kampf, speichert nicht anwendbare Einträge mit und meldet Teilwiederherstellungen. Erst die in `docs/COMPATIBILITY.md` beschriebene Prüfung entscheidet, welche Funktionen als vollständig unterstützt veröffentlicht werden dürfen.
