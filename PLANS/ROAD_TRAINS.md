# Plan: Lastzüge mit echten Anhängern (Felix 2026-10-18, Antwort „1.a“)

Fahrzeuge: **FH 540 8x8** (Zugmaschine + 2 Kipp-Auflieger, ~85 Studs) und **Scania R** (Zugmaschine + 2 offene Getreide-Auflieger, ~104 Studs).
Ziel: echte Anhänger mit Gelenk, ohne Rückwärtsfahren-Zwang, Beladen und Verkaufen ohne Rangieren.

## 1. Technik der Anhänger (T1)

- Zugmaschine bleibt ein A-Chassis-Fahrzeug (Lenkung, Antrieb, Tune).
- Jeder Auflieger ist ein **eigenes physikalisches Modell**: Rahmen + Aufbau (Karosserie-Vorlage), Achsen mit frei drehenden Rädern (HingeConstraint ohne Motor), eigene Masse.
- Kopplung: **BallSocketConstraint** am Königszapfen ↔ Sattelplatte. Grenzen: Knickwinkel max. ~80° (gegen Einklappen), kaum Kippen.
- 2. Auflieger hängt an der Sattelplatte des 1. Aufliegers (B-Double).
- Netzwerk-Besitz von Zugmaschine **und** Aufliegern beim Fahrer (sonst ruckelt es).
- Stabilität: tiefer Schwerpunkt, Bremsen der Aufliegerräder beim Bremsen (Reibung erhöhen), Geschwindigkeit begrenzen (Tune).

## 2. Daten (T2)

- Fahrzeugdefinition bekommt `Trailers = { "<Vorlage>", ... }`.
- Kapazität = Summe der Auflieger; Ladung wird gleichmäßig verteilt.
- Ladungsanzeige: Scania offen (sichtbare Ladung je Auflieger), FH mit Plane (unsichtbar, Beladen durch Dachöffnung).
- Speicherung unverändert (ein Fahrzeug-Datensatz, `Cargo` gesamt).

## 3. Durchfahr-Verladespur (T3)

- Neue **lange Verladespur** (~130 Studs) außen neben der Garage: vorne rein, hinten raus – kein Rückwärtsfahren.
- Portal mit **mehreren Teleskop-Rüsseln** im Abstand der Auflieger: Zug hält an der Haltelinie, alle Auflieger werden gleichzeitig befüllt (wie heute: nur wenn Ladefläche unter dem Rüssel steht, sonst „Vorfahren/Zurück“).
- Kleine Fahrzeuge nutzen weiter die bisherigen Stellplätze; Lastzüge nur die neue Spur.

## 4. Ausparken, Einparken, Reset (T4)

- Lastzüge erscheinen **am Anfang der Verladespur** (genug Platz in Fahrtrichtung).
- Einparken = am Ende der Spur abstellen (Prompt), kein Rangieren.
- Reset setzt den ganzen Zug gerade an den Spuranfang.

## 5. Verkaufen (T5)

- Verkaufszone vor dem Verkaufsgebäude als **lange Durchfahrzone**; Auslöser ist die Zugmaschine, verkauft wird die Ladung aller Auflieger.

## 6. Straßen und Grundstück (T6)

- Kurvenradien prüfen: Ein- und Ausfahrt der Grundstücke, Kreuzungen am Platz. Wo nötig breitere Kurven bzw. abgeschrägte Ecken.
- Testfahrt-Strecke: Garage → Verladespur → Verkauf → zurück, ohne Steckenbleiben.

## 7. Reihenfolge und Tests

1. T1 + T2 mit dem Scania im leeren Testbereich: geradeaus, Kurven, Bremsen, Stabilität bei Höchstgeschwindigkeit.
2. T4 Ausparken/Einparken/Reset.
3. T3 Verladespur mit mehreren Rüsseln.
4. T5 Verkaufszone.
5. T6 Straßen anpassen, komplette Runde fahren.
6. FH 540 nachziehen (Kipp-Auflieger).

Jeder Schritt mit Checkpoint und Felix' Freigabe.

## Offene Fragen an Felix

- Soll die Verladespur neben der Garage liegen (Platz auf dem Grundstück nötig) oder eigene Station an der Straße?
- Höchstgeschwindigkeit der Lastzüge (Vorschlag: deutlich langsamer als kleine Fahrzeuge)?
