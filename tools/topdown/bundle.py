"""Draufsicht der Map-Mitte ohne Studio (D-059).

Bündelt die Module aus src/shared und src/server mit einem kleinen Roblox-Nachbau (mock.luau) zu
einer Luau-Datei, die EnvironmentBuilder, CenterBuilder und die Shop-Builder ausführt und alle Teile
als Liste ausgibt. render.py zeichnet daraus eine Draufsicht (PNG). Zufallsdeko (Bäume, Büsche)
weicht vom Spiel ab, weil Random hier ein anderer Generator ist; Lage von Straßen, Shops,
Parkplätzen und Deko-Regeln stimmt. VehicleModelBuilder/DrillModelBuilder sind Platzhalter.

Aufruf (Luau-CLI von github.com/luau-lang/luau/releases, Pillow):
  python3 tools/topdown/bundle.py . /tmp/mitte.luau
  luau /tmp/mitte.luau > /tmp/teile.txt
  python3 tools/topdown/render.py /tmp/teile.txt mitte.png [Ausschnitt=330] [MitteX=0] [MitteZ=0] [px/Stud=3]
"""
import os, re, sys
repo = sys.argv[1]
out = sys.argv[2]
roots = [("ReplicatedStorage/Shared", os.path.join(repo, "src/shared")),
         ("ServerScriptService", os.path.join(repo, "src/server"))]
STUBS = {
 "ServerScriptService/World/VehicleModelBuilder": "local M = {}\nfunction M.build(def, cf, ...) local m = Instance.new('Model'); m.Name = def and def.Id or 'Vehicle'; local p = Instance.new('Part'); p.Size = Vector3.new(8, 6, 20); p.CFrame = cf * CFrame.new(0, 3, 0); p.Color = Color3.fromRGB(200, 60, 60); p.Parent = m; m.PrimaryPart = p; return m end\nreturn M",
 "ServerScriptService/World/DrillModelBuilder": "local M = {}\nfunction M.build(def, cf, ...) local m = Instance.new('Model'); local p = Instance.new('Part'); p.Size = Vector3.new(6, 6, 6); p.CFrame = (typeof(cf) == 'CFrame' and cf or CFrame.identity) * CFrame.new(0, 3, 0); p.Color = Color3.fromRGB(240, 160, 40); p.Parent = m; m.PrimaryPart = p; return m end\nsetmetatable(M, {__index = function() return function(...) local m = Instance.new('Model'); return m end end})\nreturn M",
}
mods = {}
for prefix, base in roots:
    for dp, dn, fn in os.walk(base):
        for f in fn:
            if not f.endswith(".luau"): continue
            name = f[:-5]
            if name.endswith(".server") or name.endswith(".client"): continue
            rel = os.path.relpath(os.path.join(dp, name), base).replace(os.sep, "/")
            path = prefix + "/" + rel
            src = open(os.path.join(dp, f), encoding="utf8").read()
            mods[path] = STUBS.get(path, src)
parts = [open(os.path.join(os.path.dirname(__file__), "mock.luau"), encoding="utf8").read()]
parts.append("local MODULES = {}\nlocal CACHE = {}\n")
for path, src in mods.items():
    src = re.sub(r"^--!strict", "", src, flags=re.M)
    src = re.sub(r"^export type", "type", src, flags=re.M)
    parts.append(f'MODULES["{path}"] = function(script)\n{src}\nend\n')
parts.append(r'''
local function node(path)
	local cur = game
	local first = true
	for seg in string.gmatch(path, "[^/]+") do
		local nxt
		if first then nxt = game:GetService(seg) first = false
		else
			nxt = cur:FindFirstChild(seg)
			if not nxt then nxt = Instance.new("Folder"); nxt.Name = seg; nxt.Parent = cur end
		end
		cur = nxt
	end
	return cur
end
for path in MODULES do
	local inst = node(path)
	inst:SetAttribute("__path", path)
	rawset(inst, "ClassName", "ModuleScript")
end
function require(m)
	local path = m:GetAttribute("__path")
	if CACHE[path] == nil then
		CACHE[path] = MODULES[path](m)
	end
	return CACHE[path]
end
local function mod(path) return require(node(path)) end
local Env = mod("ServerScriptService/World/EnvironmentBuilder")
local Center = mod("ServerScriptService/World/CenterBuilder")
local env = Env.build(workspace)
Center.build(env)
local center = Instance.new("Folder"); center.Name = "Center"; center.Parent = workspace
for _, n in { "SellingBuilder", "EquipmentShopBuilder", "MachineShopBuilder", "VehicleShopBuilder", "TruckShopBuilder" } do
	local ok, err = xpcall(function() mod("ServerScriptService/World/" .. n).build(center) end, debug.traceback)
	if not ok then print("ERR", n, err) end
end
local count = 0
for _, d in workspace:GetDescendants() do
	if d:IsA("BasePart") then
		local cf = d.CFrame
		if math.abs(cf.X) < 420 and math.abs(cf.Z) < 420 then
			local s = d.Size
			local c = d.Color
			local r = cf.r
			print(string.format("P|%s|%s|%.3f,%.3f,%.3f|%.3f,%.3f,%.3f|%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f|%.3f,%.3f,%.3f|%.2f|%s|%s|%s",
				tostring(d.Name), if d.ClassName == "WedgePart" then "Wedge" else tostring(d.Shape or "Block"), s.X, s.Y, s.Z, cf.X, cf.Y, cf.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], c.R, c.G, c.B, d.Transparency or 0, tostring(d.Material),
				if d.CanCollide == false then "0" else "1", d.Parent and d.Parent:GetFullName() or "?"))
			count += 1
		end
	end
end
print("COUNT", count)
''')
open(out, "w", encoding="utf8").write("\n".join(parts))
