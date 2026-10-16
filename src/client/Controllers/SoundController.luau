--!strict
-- Zentrale Audio-Verwaltung auf dem Client (Phase 13d, docs/09 §60: „Audio muss zentral
-- verwaltet werden“). Alle IDs und Lautstärken stehen in Shared/Config/AmbienceConfig.
--   * Musik: ruhige Playlist, unter Tage leiser
--   * Grundgeräusch je Ort: Vögel/Wind oben, Höhle unten (weich überblendet)
--   * Maschinen räumlich: Schmelze (Teil "FurnaceGlow" im Model mit Attribut "Running") und
--     Förderbänder (Tag "Conveyor", Attribut "Running") – nur solange sie laufen
--   * Ereignisse: SoundController.Play(key, at?) – mit `at` räumlich an dieser Stelle
--   * Klick-Sound für alle Buttons im eigenen PlayerGui
-- Unter Tage: Hall (AmbientReverb) und warme Farbkorrektur, oben neutral.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AmbienceConfig = require(Shared.Config.AmbienceConfig)

type SoundDef = AmbienceConfig.SoundDef

local SoundController = {}

local folder = Instance.new("Folder")
folder.Name = "GameAudio"
local music: Sound
local musicIndex = 0
local ambience: { [string]: Sound } = {}
local underground = false
local grade: ColorCorrectionEffect

local function asset(id: number): string
	return `rbxassetid://{id}`
end

local function pick(def: SoundDef): string
	return asset(def.Ids[math.random(1, #def.Ids)])
end

local function pitch(def: SoundDef): number
	local lo, hi = def.PitchMin or 1, def.PitchMax or 1
	return lo + (hi - lo) * math.random()
end

local function spatial(sound: Sound, def: SoundDef)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = def.MinDistance or 10
	sound.RollOffMaxDistance = def.MaxDistance or 80
end

local function fade(sound: Sound, volume: number, seconds: number)
	TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Volume = volume }):Play()
end

-- Ereignis-Sound abspielen; mit `at` räumlich an dieser Stelle
function SoundController.Play(key: string, at: Vector3?)
	local def = (AmbienceConfig.Sounds :: any)[key] :: SoundDef?
	if not def then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = pick(def)
	sound.Volume = def.Volume
	sound.PlaybackSpeed = pitch(def)
	if at then
		local anchor = Instance.new("Attachment")
		anchor.Name = `Sfx_{key}`
		anchor.WorldPosition = at
		anchor.Parent = workspace.Terrain
		spatial(sound, def)
		sound.Parent = anchor
		sound.Ended:Once(function()
			anchor:Destroy()
		end)
		Debris:AddItem(anchor, 10)
	else
		sound.Parent = folder
		sound.Ended:Once(function()
			sound:Destroy()
		end)
		Debris:AddItem(sound, 20)
	end
	sound:Play()
end

-- Förderkorb-Fahrt: Motorgeräusch, nach `seconds` ausblenden
function SoundController.PlayFor(key: string, seconds: number)
	local def = (AmbienceConfig.Sounds :: any)[key] :: SoundDef?
	if not def then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = pick(def)
	sound.Volume = def.Volume
	sound.Parent = folder
	sound:Play()
	task.delay(seconds, function()
		fade(sound, 0, 0.8)
		task.wait(0.9)
		sound:Destroy()
	end)
end

local function musicVolume(): number
	local m = AmbienceConfig.Music
	return m.Volume * (if underground then m.MineFactor else 1)
end

local function nextTrack()
	local ids = AmbienceConfig.Music.Ids
	musicIndex = musicIndex % #ids + 1
	music.SoundId = asset(ids[musicIndex])
	music.Volume = 0
	music:Play()
	fade(music, musicVolume(), AmbienceConfig.Music.FadeSeconds)
end

-- Ort gewechselt (Oberwelt ↔ Mine): Grundgeräusch überblenden, Hall und Farbkorrektur
function SoundController.SetUnderground(inMine: boolean)
	underground = inMine
	local seconds = AmbienceConfig.Ambience.FadeSeconds
	for place, sound in ambience do
		local active = (place == "Mine") == inMine
		local def = (AmbienceConfig.Ambience :: any)[place] :: SoundDef
		if active and not sound.IsPlaying then
			sound.Volume = 0
			sound:Play()
		end
		fade(sound, if active then def.Volume else 0, seconds)
	end
	if music then
		fade(music, musicVolume(), seconds)
	end
	SoundService.AmbientReverb = if inMine then AmbienceConfig.MineReverb else Enum.ReverbType.NoReverb
	local g = if inMine then AmbienceConfig.Grade.Mine else AmbienceConfig.Grade.Surface
	TweenService:Create(grade, TweenInfo.new(seconds), g):Play()
end

-- Maschinenklang an einem Teil; spielt nur, solange running() true ist
local function attachMachine(part: BasePart, def: SoundDef, owner: Instance)
	if part:FindFirstChild("MachineSound") then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "MachineSound"
	sound.SoundId = pick(def)
	sound.Looped = true
	sound.Volume = def.Volume
	spatial(sound, def)
	sound.Parent = part
	local function update()
		local running = owner:GetAttribute("Running") == true
		if running and not sound.IsPlaying then
			sound.TimePosition = math.random() * 10
			sound:Play()
		elseif not running and sound.IsPlaying then
			sound:Stop()
		end
	end
	owner:GetAttributeChangedSignal("Running"):Connect(update)
	update()
end

local function onConveyor(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if part then
		attachMachine(part, AmbienceConfig.Machines.Conveyor, model)
	end
end

local function onWorldDescendant(inst: Instance)
	if inst.Name == "FurnaceGlow" and inst:IsA("BasePart") then
		-- Model der Schmelze = nächstes Vorfahren-Model mit Attribut "Running"
		local owner = inst.Parent
		while owner and owner:GetAttribute("Running") == nil do
			owner = owner.Parent
		end
		if owner then
			attachMachine(inst, AmbienceConfig.Machines.Smelter, owner)
		end
	end
end

local function hookButton(inst: Instance)
	if inst:IsA("GuiButton") and not inst:GetAttribute("NoClickSound") then
		inst.Activated:Connect(function()
			SoundController.Play("UiClick")
		end)
	end
end

function SoundController.Init()
	folder.Parent = SoundService

	grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "AmbienceGrade"
	for k, v in AmbienceConfig.Grade.Surface do
		(grade :: any)[k] = v
	end
	grade.Parent = Lighting

	music = Instance.new("Sound")
	music.Name = "Music"
	music.Parent = folder
	music.Ended:Connect(nextTrack)

	for _, place in { "Surface", "Mine" } do
		local def = (AmbienceConfig.Ambience :: any)[place] :: SoundDef
		local sound = Instance.new("Sound")
		sound.Name = `Ambience{place}`
		sound.SoundId = pick(def)
		sound.Looped = true
		sound.Volume = 0
		sound.Parent = folder
		ambience[place] = sound
	end
end

function SoundController.Start()
	musicIndex = math.random(0, #AmbienceConfig.Music.Ids - 1)
	nextTrack()
	SoundController.SetUnderground(underground)

	for _, model in CollectionService:GetTagged("Conveyor") do
		onConveyor(model)
	end
	CollectionService:GetInstanceAddedSignal("Conveyor"):Connect(onConveyor)
	for _, d in workspace:GetDescendants() do
		onWorldDescendant(d)
	end
	workspace.DescendantAdded:Connect(onWorldDescendant)

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, d in playerGui:GetDescendants() do
		hookButton(d)
	end
	playerGui.DescendantAdded:Connect(hookButton)
end

return SoundController
