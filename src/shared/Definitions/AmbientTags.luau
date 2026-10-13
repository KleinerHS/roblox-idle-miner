--!strict
-- Tags und Attribute für das „Hallen-Leben“ (Felix 2026-10-13: „nicht so leer und tot“).
-- Der Server baut die Objekte und setzt Tags/Attribute, der Client (HallAmbienceController)
-- animiert sie rein lokal. Alles ist Optik, keine Spiellogik.
--
--   Spin    (Model oder Part): dreht sich um die eigene Achse.
--           Attribute: SpinAxis "X"|"Y"|"Z" (lokal zum Pivot), SpinSpeed (Grad/s),
--           NeedsRunning (bool, nur wenn das nächste Vorfahren-Model mit Attribut "Running"
--           auf true steht, z. B. die Schmelze)
--   Shuttle (Model): fährt zwischen Startpunkt und Startpunkt + Travel hin und her.
--           Attribute: Travel (Vector3, lokal zum Pivot), Speed (Studs/s), Pause (s)
--   Blink   (Part): Kontroll-LED, blinkt unregelmäßig
--   StaffPath (Model mit unsichtbaren Parts P1..Pn): ein Arbeiter läuft den Weg ab und arbeitet
--           an den Enden (Attribut Vest = Color3 optional)

return table.freeze({
	Spin = "AmbientSpin",
	Shuttle = "AmbientShuttle",
	Blink = "AmbientBlink",
	StaffPath = "AmbientStaffPath",
})
