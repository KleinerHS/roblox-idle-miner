--!strict
-- Client-Einstiegspunkt. Lädt später alle Controller (siehe docs/15_TECHNICAL_ARCHITECTURE.md).
-- Aktuell nur Sync-Check für Rojo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

print(`[Client] {Version.Game} v{Version.Version} ({Version.Phase}) gestartet`)
