@echo off
rem Startet den Rojo-Server fuer Roblox Studio (Doppelklick genuegt).
rem Danach in Studio: Plugins -> Rojo -> Connect. Dieses Fenster offen lassen.
title Rojo - Roblox Idle Miner
set "PATH=%USERPROFILE%\.rokit\bin;%PATH%"
cd /d "%~dp0"
echo Rojo startet ... (Fenster offen lassen, zum Beenden einfach schliessen)
echo.
rojo serve
echo.
echo Rojo wurde beendet. Wenn oben ein Fehler steht (z. B. Port belegt), laeuft Rojo evtl. schon.
pause
