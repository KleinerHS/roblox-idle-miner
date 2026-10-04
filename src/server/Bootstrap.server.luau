--!strict
-- Server-Einstiegspunkt. Lädt später alle Services (siehe docs/15_TECHNICAL_ARCHITECTURE.md).
-- Aktuell nur Sync-Check für Rojo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

print(`[Server] {Version.Game} v{Version.Version} ({Version.Phase}) gestartet`)
