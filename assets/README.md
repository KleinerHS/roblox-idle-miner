# assets/ – Sicherung von Studio-only-Inhalten

Diese Inhalte existieren nur in der Place-Datei (nicht in `src/`) und werden hier als Modell gesichert.
Sie werden **nicht** von Rojo synchronisiert.

| Datei | Inhalt in der Place | Stand |
|---|---|---|
| `HallLayout.rbxm` | `Workspace.HallLayout` – Felix' Hallen-Anordnung (Gebäude, Regale, Büro mit Laptop, Schrank, Bett, Stuhl, `LayoutOrigin`) | 2026-10-17 |
| `AChassis.rbxm` | `ServerStorage.Vendor.AChassis` – A-Chassis-Kit 1.7.2 (MPL-2.0, siehe `licenses/`) und die Abstimmungen `Tunes/vehicle_pickup`, `vehicle_van`, `vehicle_boxtruck`, `vehicle_truck`, `vehicle_hauler` | 2026-10-17 |
| `WorkspaceExtras.rbxm` | Folder `WorkspaceExtras` mit allen losen Objekten direkt im Workspace (außerhalb HallLayout, von Felix absichtlich platziert): 3× Rack2, Zaun-, Rohr-/Aufhänger-Gruppen, LaneCones, Bollards, Railing – 15 Objekte | 2026-10-18 |

## Wiederherstellen

In Studio: Rechtsklick auf `Workspace` bzw. `ServerStorage.Vendor` → **Insert from File…** → Datei wählen.
Bei `WorkspaceExtras.rbxm` die Objekte nach dem Einfügen aus dem Folder direkt in den Workspace ziehen.
Vorher das vorhandene Objekt gleichen Namens löschen oder umbenennen.

## Einschränkung

Erzeugt per Skript (`tools/ExportRbxmx.luau`), weil Studio keinen Export per Skript erlaubt.
Rücktest: alle Dateien in Studio geladen und mit dem Original verglichen (Name, Klasse, CFrame,
Größe, Farbe, Material, Transparenz, Kollision, Werte, Texte, Licht, Mesh/Textur, Skript-Quelltext,
Verknüpfungen, Attribute, Tags, Pivots) – 0 Abweichungen.

**Nicht enthalten:** 8 UnionOperations aus zwei Creator-Store-Modellen im Büro (per Skript nicht lesbar):
- `Office/Chair/Rolling Chair`: Back Rest, Seat, Left Armrest, Right Armrest (Asset 2095488658)
- `Office/Bed/Cot`: Sheets ×2, Pillow, Matress (Asset 5236086234)

Diese Teile nach dem Einfügen fehlen; bei Bedarf Stuhl und Bett aus dem Creator Store neu einfügen
und an die Stelle der vorhandenen Modelle setzen.
Für eine exakte 1:1-Sicherung: in Studio Rechtsklick auf `HallLayout` → **Save to File…** und die Datei hier ersetzen.
