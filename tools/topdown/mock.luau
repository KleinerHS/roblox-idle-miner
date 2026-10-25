-- Minimaler Roblox-Nachbau für Draufsicht-Renderings (nur was die Builder brauchen)
local V3 = {}
V3.__index = function(t, k)
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
	if k == "Unit" then local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z); if m == 0 then return t end return Vector3.new(t.X / m, t.Y / m, t.Z / m) end
	return V3[k]
end
Vector3 = {}
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, __kind = "Vector3" }, V3) end
V3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
	return Vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3.__tostring = function(a) return string.format("%g, %g, %g", a.X, a.Y, a.Z) end
function V3.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
function V3.Cross(a, b) return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
function V3.Lerp(a, b, t) return a + (b - a) * t end
function V3.Abs(a) return Vector3.new(math.abs(a.X), math.abs(a.Y), math.abs(a.Z)) end
function V3.Max(a, b) return Vector3.new(math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z)) end
function V3.Min(a, b) return Vector3.new(math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z)) end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
Vector3.xAxis = Vector3.new(1, 0, 0)
Vector3.yAxis = Vector3.new(0, 1, 0)
Vector3.zAxis = Vector3.new(0, 0, 1)

local V2 = {}
V2.__index = function(t, k)
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y) end
	if k == "Unit" then local m = math.sqrt(t.X * t.X + t.Y * t.Y); return Vector2.new(t.X / m, t.Y / m) end
	return V2[k]
end
Vector2 = {}
function Vector2.new(x, y) return setmetatable({ X = x or 0, Y = y or 0, __kind = "Vector2" }, V2) end
V2.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
V2.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
V2.__unm = function(a) return Vector2.new(-a.X, -a.Y) end
V2.__mul = function(a, b)
	if type(a) == "number" then return Vector2.new(a * b.X, a * b.Y) end
	if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end
	return Vector2.new(a.X * b.X, a.Y * b.Y)
end
V2.__div = function(a, b) if type(b) == "number" then return Vector2.new(a.X / b, a.Y / b) end return Vector2.new(a.X / b.X, a.Y / b.Y) end
function V2.Dot(a, b) return a.X * b.X + a.Y * b.Y end
function V2.Lerp(a, b, t) return a + (b - a) * t end
Vector2.zero = Vector2.new(0, 0)
Vector2.one = Vector2.new(1, 1)

-- CFrame: Rotationsmatrix (Zeilen) r00..r22 und Position
local CF = {}
CFrame = {}
local function mk(px, py, pz, r) return setmetatable({ px = px, py = py, pz = pz, r = r, __kind = "CFrame" }, CF) end
local I = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function mmul(a, b)
	local o = {}
	for i = 0, 2 do for j = 0, 2 do
		local s = 0
		for k = 0, 2 do s += a[i * 3 + k + 1] * b[k * 3 + j + 1] end
		o[i * 3 + j + 1] = s
	end end
	return o
end
local function mvec(r, x, y, z) return r[1] * x + r[2] * y + r[3] * z, r[4] * x + r[5] * y + r[6] * z, r[7] * x + r[8] * y + r[9] * z end
local function transpose(r) return { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] } end
CF.__index = function(t, k)
	if k == "Position" or k == "p" then return Vector3.new(t.px, t.py, t.pz) end
	if k == "X" then return t.px end
	if k == "Y" then return t.py end
	if k == "Z" then return t.pz end
	if k == "LookVector" then return Vector3.new(-t.r[3], -t.r[6], -t.r[9]) end
	if k == "RightVector" or k == "XVector" then return Vector3.new(t.r[1], t.r[4], t.r[7]) end
	if k == "UpVector" or k == "YVector" then return Vector3.new(t.r[2], t.r[5], t.r[8]) end
	if k == "ZVector" then return Vector3.new(t.r[3], t.r[6], t.r[9]) end
	if k == "Rotation" then return mk(0, 0, 0, t.r) end
	return CF[k]
end
CF.__mul = function(a, b)
	if getmetatable(b) == CF then
		local x, y, z = mvec(a.r, b.px, b.py, b.pz)
		return mk(x + a.px, y + a.py, z + a.pz, mmul(a.r, b.r))
	end
	local x, y, z = mvec(a.r, b.X, b.Y, b.Z)
	return Vector3.new(x + a.px, y + a.py, z + a.pz)
end
CF.__add = function(a, v) return mk(a.px + v.X, a.py + v.Y, a.pz + v.Z, a.r) end
CF.__sub = function(a, v) return mk(a.px - v.X, a.py - v.Y, a.pz - v.Z, a.r) end
function CF.Inverse(a)
	local rt = transpose(a.r)
	local x, y, z = mvec(rt, a.px, a.py, a.pz)
	return mk(-x, -y, -z, rt)
end
function CF.PointToObjectSpace(a, v) local x, y, z = mvec(transpose(a.r), v.X - a.px, v.Y - a.py, v.Z - a.pz); return Vector3.new(x, y, z) end
function CF.PointToWorldSpace(a, v) return a * v end
function CF.VectorToObjectSpace(a, v) local x, y, z = mvec(transpose(a.r), v.X, v.Y, v.Z); return Vector3.new(x, y, z) end
function CF.VectorToWorldSpace(a, v) local x, y, z = mvec(a.r, v.X, v.Y, v.Z); return Vector3.new(x, y, z) end
function CF.ToObjectSpace(a, b) return a:Inverse() * b end
function CF.ToWorldSpace(a, b) return a * b end
function CF.GetComponents(a) local r = a.r; return a.px, a.py, a.pz, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9] end
function CF.Lerp(a, b, t) return mk(a.px + (b.px - a.px) * t, a.py + (b.py - a.py) * t, a.pz + (b.pz - a.pz) * t, if t < 0.5 then a.r else b.r) end
function CF.ToEulerAnglesYXZ(a) return 0, math.atan2(a.r[3], a.r[9]), 0 end
function CFrame.new(a, b, c, ...)
	if a == nil then return mk(0, 0, 0, I) end
	if type(a) == "number" then
		local rest = { ... }
		if #rest == 9 then return mk(a, b, c, rest) end
		return mk(a, b, c, I)
	end
	if b ~= nil then return CFrame.lookAt(a, b) end
	return mk(a.X, a.Y, a.Z, I)
end
function CFrame.fromMatrix(p, vx, vy, vz)
	vz = vz or vx:Cross(vy)
	return mk(p.X, p.Y, p.Z, { vx.X, vy.X, vz.X, vx.Y, vy.Y, vz.Y, vx.Z, vy.Z, vz.Z })
end
function CFrame.lookAt(at, target, up)
	up = up or Vector3.yAxis
	local look = (target - at).Unit
	local right = look:Cross(up).Unit
	local up2 = right:Cross(look)
	return CFrame.fromMatrix(at, right, up2, -look)
end
local function rx(a) local c, s = math.cos(a), math.sin(a); return { 1, 0, 0, 0, c, -s, 0, s, c } end
local function ry(a) local c, s = math.cos(a), math.sin(a); return { c, 0, s, 0, 1, 0, -s, 0, c } end
local function rz(a) local c, s = math.cos(a), math.sin(a); return { c, -s, 0, s, c, 0, 0, 0, 1 } end
function CFrame.Angles(x, y, z) return mk(0, 0, 0, mmul(mmul(rx(x), ry(y)), rz(z))) end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.fromEulerAnglesYXZ(x, y, z) return mk(0, 0, 0, mmul(mmul(ry(y), rx(x)), rz(z))) end
CFrame.fromOrientation = CFrame.fromEulerAnglesYXZ
function CFrame.fromAxisAngle(axis, a)
	local u = axis.Unit; local c, s = math.cos(a), math.sin(a); local t = 1 - c
	local x, y, z = u.X, u.Y, u.Z
	return mk(0, 0, 0, { t*x*x+c, t*x*y-s*z, t*x*z+s*y, t*x*y+s*z, t*y*y+c, t*y*z-s*x, t*x*z-s*y, t*y*z+s*x, t*z*z+c })
end
CFrame.identity = mk(0, 0, 0, I)

Color3 = {}
local C3 = {}
C3.__index = C3
function Color3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3) end
function Color3.fromRGB(r, g, b) return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end
function Color3.fromHSV(h, s, v) return Color3.new(v, v, v) end
function C3.Lerp(a, b, t) return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end
function C3.ToHSV(a) return 0, 0, a.R end

local function enumProxy(path)
	return setmetatable({ __path = path, Name = path:match("[^%.]+$") }, {
		__index = function(t, k) local v = enumProxy(path .. "." .. k); rawset(t, k, v); return v end,
		__tostring = function() return path end,
	})
end
Enum = enumProxy("Enum")

function typeof(v)
	if type(v) == "table" then
		local mt = getmetatable(v)
		if mt == V3 then return "Vector3" end
		if mt == V2 then return "Vector2" end
		if mt == CF then return "CFrame" end
		if mt == C3 then return "Color3" end
		if rawget(v, "__isInstance") then return "Instance" end
	end
	return type(v)
end

local RNG = {}
RNG.__index = RNG
Random = {}
function Random.new(seed)
	return setmetatable({ s = (seed or 1) % 2147483647 }, RNG)
end
function RNG.raw(self) self.s = (self.s * 48271) % 2147483647; return self.s / 2147483647 end
function RNG.NextNumber(self, a, b) local r = self:raw(); if a == nil then return r end return a + (b - a) * r end
function RNG.NextInteger(self, a, b) return a + math.floor(self:raw() * (b - a + 1)) end
function RNG.NextUnitVector(self) local a = self:raw() * math.pi * 2; return Vector3.new(math.cos(a), 0, math.sin(a)) end

UDim2 = { new = function(...) return { ... } end, fromScale = function(...) return { ... } end, fromOffset = function(...) return { ... } end }
UDim = { new = function(...) return { ... } end }
Font = { new = function(...) return { ... } end, fromEnum = function(...) return { ... } end, fromName = function(...) return { ... } end }
PhysicalProperties = { new = function(...) return { ... } end }
NumberSequence = { new = function(...) return { ... } end }
NumberSequenceKeypoint = { new = function(...) return { ... } end }
ColorSequence = { new = function(...) return { ... } end }
ColorSequenceKeypoint = { new = function(...) return { ... } end }
NumberRange = { new = function(...) return { ... } end }
Rect = { new = function(...) return { ... } end }
TweenInfo = { new = function(...) return { ... } end }
BrickColor = { new = function(...) return { Color = Color3.new(0.5, 0.5, 0.5) } end }
function warn(...) print("WARN", ...) end
task = { spawn = function(f, ...) f(...) end, defer = function() end, delay = function() end, wait = function() return 0 end }

-- Instanzen
ALL = {}
local INST = {}
local BASEPARTS = { Part = true, WedgePart = true, MeshPart = true, TrussPart = true, CornerWedgePart = true, UnionOperation = true, Seat = true, VehicleSeat = true, SpawnLocation = true }
local function isA(self, cls)
	local c = rawget(self, "ClassName")
	if c == cls or cls == "Instance" then return true end
	if cls == "BasePart" or cls == "PVInstance" then return BASEPARTS[c] == true end
	if cls == "Light" then return c == "PointLight" or c == "SpotLight" or c == "SurfaceLight" end
	if cls == "Constraint" then return c and c:match("Constraint$") ~= nil end
	if cls == "LuaSourceContainer" or cls == "BaseScript" then return c == "Script" or c == "LocalScript" or c == "ModuleScript" end
	return false
end
INST.__index = function(t, k)
	local props = rawget(t, "__props")
	if props[k] ~= nil then return props[k] end
	if k == "Position" and props.CFrame and BASEPARTS[rawget(t, "ClassName")] then return props.CFrame.Position end
	if k == "Orientation" then return Vector3.zero end
	local m = INST[k]
	if m then return m end
	local child = t:FindFirstChild(k)
	if child then return child end
	if k == "Parent" then return nil end
	if k == "Size" then return Vector3.new(4, 1, 2) end
	if k == "CFrame" and BASEPARTS[rawget(t, "ClassName")] then return CFrame.identity end
	return nil
end
INST.__newindex = function(t, k, v)
	local props = rawget(t, "__props")
	if k == "Parent" then
		local old = props.Parent
		if old then
			local list = rawget(old, "__children")
			for i, c in list do if c == t then table.remove(list, i) break end end
		end
		props.Parent = v
		if v then table.insert(rawget(v, "__children"), t) end
		return
	end
	if k == "Position" and BASEPARTS[rawget(t, "ClassName")] then
		local cf = props.CFrame or CFrame.identity
		props.CFrame = cf.Rotation + v
		return
	end
	props[k] = v
end
INST.__tostring = function(t) return rawget(t, "__props").Name or rawget(t, "ClassName") end
function INST.FindFirstChild(self, name, recursive)
	for _, c in rawget(self, "__children") do
		if c.Name == name then return c end
		if recursive then local f = c:FindFirstChild(name, true); if f then return f end end
	end
	return nil
end
function INST.WaitForChild(self, name) return self:FindFirstChild(name) end
function INST.FindFirstChildOfClass(self, cls) for _, c in rawget(self, "__children") do if rawget(c, "ClassName") == cls then return c end end return nil end
function INST.FindFirstChildWhichIsA(self, cls) for _, c in rawget(self, "__children") do if isA(c, cls) then return c end end return nil end
function INST.FindFirstAncestorWhichIsA(self, cls) local p = self.Parent; while p do if isA(p, cls) then return p end p = p.Parent end return nil end
function INST.GetChildren(self) return table.clone(rawget(self, "__children")) end
function INST.GetDescendants(self)
	local out = {}
	local function rec(n) for _, c in rawget(n, "__children") do table.insert(out, c); rec(c) end end
	rec(self)
	return out
end
function INST.IsA(self, cls) return isA(self, cls) end
function INST.IsDescendantOf(self, other) local p = self.Parent; while p do if p == other then return true end p = p.Parent end return false end
function INST.SetAttribute(self, k, v) rawget(self, "__attrs")[k] = v end
function INST.GetAttribute(self, k) return rawget(self, "__attrs")[k] end
function INST.GetAttributes(self) return rawget(self, "__attrs") end
function INST.GetAttributeChangedSignal() return { Connect = function() return { Disconnect = function() end } end } end
function INST.GetPropertyChangedSignal() return { Connect = function() return { Disconnect = function() end } end } end
function INST.Destroy(self) self.Parent = nil end
function INST.ClearAllChildren(self) for _, c in self:GetChildren() do c.Parent = nil end end
function INST.AddTag() end
function INST.HasTag() return false end
local function boundsOf(model)
	local parts = {}
	for _, d in model:GetDescendants() do if isA(d, "BasePart") then table.insert(parts, d) end end
	return parts
end
function INST.GetPivot(self)
	local props = rawget(self, "__props")
	if props.CFrame then return props.CFrame end
	if props.WorldPivot then return props.WorldPivot end
	if props.PrimaryPart then return props.PrimaryPart.CFrame end
	local parts = boundsOf(self)
	if #parts > 0 then return parts[1].CFrame.Rotation + parts[1].CFrame.Position end
	return CFrame.identity
end
function INST.PivotTo(self, cf)
	local pivot = self:GetPivot()
	local delta = cf * pivot:Inverse()
	if rawget(self, "__props").CFrame then rawget(self, "__props").CFrame = cf return end
	for _, p in boundsOf(self) do p.CFrame = delta * p.CFrame end
	rawget(self, "__props").WorldPivot = cf
end
function INST.SetPrimaryPartCFrame(self, cf) self:PivotTo(cf) end
function INST.GetBoundingBox(self) return self:GetPivot(), Vector3.new(10, 10, 10) end
function INST.GetExtentsSize() return Vector3.new(10, 10, 10) end
function INST.ScaleTo() end
function INST.Clone(self)
	local c = Instance.new(rawget(self, "ClassName"))
	for k, v in rawget(self, "__props") do if k ~= "Parent" then rawget(c, "__props")[k] = v end end
	for k, v in rawget(self, "__attrs") do rawget(c, "__attrs")[k] = v end
	for _, ch in rawget(self, "__children") do ch:Clone().Parent = c end
	return c
end
function INST.GetFullName(self) local n = {}; local p = self; while p do table.insert(n, 1, p.Name or "?"); p = p.Parent end return table.concat(n, ".") end
Instance = {}
function Instance.new(cls, parent)
	local t = setmetatable({ ClassName = cls, __props = { Name = cls }, __children = {}, __attrs = {}, __isInstance = true }, INST)
	if BASEPARTS[cls] then rawget(t, "__props").Size = Vector3.new(4, 1, 2); rawget(t, "__props").Color = Color3.new(0.64, 0.64, 0.64); rawget(t, "__props").Transparency = 0 end
	table.insert(ALL, t)
	if parent then t.Parent = parent end
	return t
end

local services = {}
game = Instance.new("DataModel")
game.Name = "Game"
function game.GetService(self, name)
	if not services[name] then
		local s = Instance.new(name)
		s.Name = name
		s.Parent = game
		services[name] = s
	end
	return services[name]
end
workspace = game:GetService("Workspace")
