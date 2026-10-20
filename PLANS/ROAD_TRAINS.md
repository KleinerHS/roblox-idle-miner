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

## Entscheidungen (D-050, D-052)

- Verladespur: erledigt in 18b als Durchfahr-Verladestraße durch die Garage (D-052) – Einfahrt links durch die Hallenwand, ein Rüssel, Ausfahrt durchs Rolltor; Zufahrt über eine neue Straße neben dem Grundstück. T3 entfällt in der ursprünglichen Form; mit echten Anhängern wird nur noch geprüft, ob die Kurve zum Tor (Radius 32) reicht.
- Höchstgeschwindigkeit: ca. 60 % der kleinen Fahrzeuge.

## Stand 18c (2026-10-19)

- T1/T2 umgesetzt für den Scania (D-053): `World/TrailerBuilder.luau`, Vorlagen in `ServerStorage.Vendor.VehicleBodies.vehicle_roadtrain` und `vehicle_roadtrain_Trailers`.
- T4 teilweise: Lastzug erscheint auf der Zufahrt neben dem Grundstück; Reset dorthin.
- Vorlagen neu erzeugen (Studio, Edit; Quelle `ServerStorage._VehicleCandidates`, Creator-Store-Modell 15557972363 neu einfügen):
  1. `V6_ScaniaTractor` = Body, Wheels, DriveSeat des Modells „SCANIA R visor 2“; `tools/PrepareVehicleBodies.luau` mit
     `vehicle_roadtrain = { Source = "V6_ScaniaTractor", Wheels = "named", Remove = { "placa" }, RemoveMeshes = { "rbxassetid://6658790299", "rbxassetid://5616208782", "rbxassetid://5703034461" } }`, danach CargoFill der Zugmaschine löschen.
  2. `V6_Scania` = komplettes Modell; `tools/PrepareTrailers.luau` mit Kupplungspunkten Trailer1 (-0.2, -2.7, -14.7) → 0, Trailer2 (-0.3, -2.1, 16.9) → 1, Trailer3 (-0.3, -2.6, 33.7) → 2 (Pivot-Rahmen der Quelle), Ladung im Untermodell „boiadeiro“.
- Offen: Freigabe im Autohaus nach Felix' Fahrtest, FH 540 (Kipp-Auflieger) mit derselben Technik.

## Stand 18d (2026-10-20)

- FH 540 (`vehicle_hauler`) mit derselben Technik: Quelle Creator-Store 15853678225, Untermodell „FH 540 8x8 V2“. Vor dem Vorbereiten die leicht geknickten Anhänger um ihre Kupplungspunkte gerade drehen (Achswinkel aus „Wheels Left/Right“), Kipp-Aufbau „Model“ → „Tub“ umbenennen.
  - Zugmaschine: `PrepareVehicleBodies` mit `Wheels = "named"`, `Remove = { "license plates", "placa" }`, danach Logo-MeshParts 6020548390/461/218 und Decal 6857365666 entfernen, CargoFill löschen.
  - Anhänger: `PrepareTrailers` mit Kupplungen Trailer1 (0, -0.6, -6.1) → 0, Trailer2 (-0.41, -0.8, -36.3) → 1, Trailer3 (-0.47, -0.8, -48.78) → 2 (nach dem Geraderichten), Ladung „Tub“; CargoFill danach um 1,9 nach oben (Planenhöhe) und `CargoHidden = true`.
- Beide Lastzüge per DevTool testbar; im Autohaus weiter „Coming soon“ bis Felix' Freigabe.
