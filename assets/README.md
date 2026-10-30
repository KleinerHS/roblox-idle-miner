# assets/ – Sicherung von Studio-only-Inhalten

Diese Inhalte existieren nur in der Place-Datei (nicht in `src/`) und werden hier als Modell gesichert.
Sie werden **nicht** von Rojo synchronisiert.

| Datei | Inhalt in der Place | Stand |
|---|---|---|
| `HallLayout.rbxm` | `Workspace.HallLayout` – Felix' Hallen-Anordnung (Gebäude, Regale, Büro mit Laptop, Schrank, Bett, Stuhl, `LayoutOrigin`); seit 2026-10-19 inkl. der früher losen Objekte und deckungsgleich mit Plot 1 ausgerichtet; seit 2026-10-30 mit der neuen Starter-Blechhütte `Office/StarterHut` und Deko (D-081). Rücktest 6.355 Objekte, 0 Abweichungen | 2026-10-30 |
| `AChassis.rbxm` | `ServerStorage.Vendor.AChassis` – A-Chassis-Kit 1.7.2 (MPL-2.0, siehe `licenses/`) und die Abstimmungen `Tunes/vehicle_pickup`, `vehicle_van`, `vehicle_boxtruck`, `vehicle_truck`, `vehicle_hauler`, `vehicle_roadtrain` (Lastzug, Tempolimit 60 km/h) | 2026-10-19 |
| `VehicleBodies.rbxm` | `ServerStorage.Vendor.VehicleBodies` – Karosserie-Vorlagen aus Felix' Fahrzeugmodellen (`vehicle_pickup`, `vehicle_van`, `vehicle_boxtruck`, `vehicle_truck`, Lastzug `vehicle_roadtrain` + `vehicle_roadtrain_Trailers` 1–3). **Unvollständig:** die ~130 UnionOperations von `vehicle_truck` (DAF) fehlen, zwei unbenannte MeshParts des Pickups heißen nach dem Einfügen leer statt „ “. Seit 2026-10-21 rostiger Pickup (MaterialVariant `RustyPickupPaint`, kommt per Rojo) und dunkle Scheiben (Attribut `Window`); die Scheiben-Unions von DAF, Scania (Seiten) und FH 540 sind wie alle Unions nicht enthalten | 2026-10-21 |
| `Pickaxes.rbxm` | `ServerStorage.Vendor.Pickaxes` – 25 Spitzhacken-Vorlagen aus Felix' Pickaxe-Pack (D-071), MeshParts mit Farben/Materialien, Pivot Unterkante Mitte. Rücktest 195 Objekte, 0 Abweichungen | 2026-10-27 |
| `Backpacks.rbxm` | `ServerStorage.Vendor.Backpacks` – 22 Rucksack-Vorlagen aus Felix' Rucksack-Pack (D-074), MeshParts mit Farben/Materialien, leuchtende Teile Neon + Licht, Pivot = Befestigungspunkt am Rücken. Rücktest 115 Objekte, 0 Abweichungen | 2026-10-28 |
| `Drills.rbxm` | `ServerStorage.Vendor.Drills` – 30 Drill-Vorlagen L01–L30 aus Felix' Paket Industrial_Drills (D-075), Gruppen Rotor/Roller_01–03 mit Drehpunkten aus Drill_Config. Rücktest 408 Objekte, 0 Abweichungen | 2026-10-28 |
| `PremiumOffice.rbxm` | `ServerStorage.Vendor.PremiumOffice` – Premium-Firmenbüro 42 × 48 (Büro-Stufe 2, D-082) aus Felix' Paket, inkl. Farben, Textur-Verweisen, Lichtern, Kollision, Türen, Computer-Prompt, Spawn-Anker und Firmenname-Schildern (D-083). Rücktest 517 Objekte, 0 Abweichungen | 2026-10-30 |
| `DrillCounter.rbxm` | `ServerStorage.Vendor.DrillCounter` – Verkaufstresen des Drill-Shops aus Felix' Paket Drill_Shop_Verkaufstresen (D-080), inkl. Bildschirm-Texturen. Rücktest 28 Objekte, 0 Abweichungen | 2026-10-29 |

## Wiederherstellen

In Studio: Rechtsklick auf `Workspace` bzw. `ServerStorage.Vendor` → **Insert from File…** → Datei wählen.
Vorher das vorhandene Objekt gleichen Namens löschen oder umbenennen.

## Einschränkung

Erzeugt per Skript (`tools/ExportRbxmx.luau`), weil Studio keinen Export per Skript erlaubt.
Rücktest (zuletzt 2026-10-19): alle Dateien in Studio geladen und mit dem Original verglichen (Name, Klasse, CFrame,
Größe, Farbe, Material, Transparenz, Kollision, Werte, Texte, Licht, Mesh/Textur, Skript-Quelltext,
Verknüpfungen, Attribute, Tags, Pivots) – HallLayout und AChassis 0 Abweichungen.

**Nicht enthalten:** 8 UnionOperations aus zwei Creator-Store-Modellen im Büro (per Skript nicht lesbar):
- `Office/Chair/Rolling Chair`: Back Rest, Seat, Left Armrest, Right Armrest (Asset 2095488658)
- `Office/Bed/Cot`: Sheets ×2, Pillow, Matress (Asset 5236086234)

Diese Teile nach dem Einfügen fehlen; bei Bedarf Stuhl und Bett aus dem Creator Store neu einfügen
und an die Stelle der vorhandenen Modelle setzen.
Für eine exakte 1:1-Sicherung: in Studio Rechtsklick auf `HallLayout` → **Save to File…** und die Datei hier ersetzen.
