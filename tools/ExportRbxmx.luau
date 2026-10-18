-- Export von Studio-Instanzen nach rbxmx (Sicherung von Studio-only-Inhalten, siehe assets/README.md).
-- Läuft per Studio-MCP execute_luau (Edit). Liest alle serialisierten Eigenschaften über die
-- ReflectionService (nur Abweichungen vom Standardwert), dazu Attribute, Tags, Pivots und Skript-Quelltext.
-- UnionOperations können per Skript nicht gelesen werden und werden übersprungen (Liste in der Ausgabe).
-- Ergebnis: _G.__export[name] = base64(rbxmx); danach zstd-komprimiert abholen und mit
-- `rojo build` (Projekt mit "$path": "<name>.rbxmx") in .rbxm umwandeln.
local RS = game:GetService("ReflectionService")
local ES = game:GetService("EncodingService")
local CS = game:GetService("CollectionService")

local ALIAS = { Color3uint8 = "Color", size = "Size", shape = "Shape", MaterialVariantSerialized = "MaterialVariant" }
local SKIP_PROPS = { formFactorRaw = true, CollisionGroupId = true, ModelMeshData = true, ModelMeshCFrame = true, ModelMeshSize = true, NeedsPivotMigration = true, WorldPivotData = true, ScaleFactor = true, Velocity = true, RotVelocity = true, Parent = true, Tags = true, AttributesSerialize = true, Attributes = true, UniqueId = true, HistoryId = true, ScriptGuid = true, Capabilities = true, DefinesCapabilities = true, Sandboxed = true }
local SKIP_CLASSES = { UnionOperation = true, NegateOperation = true, IntersectOperation = true }

local propCache = {}
local defaultCache = {}
local function propsOf(class: string)
	local c = propCache[class]
	if c then
		return c
	end
	c = {}
	for _, p in RS:GetPropertiesOfClass(class) do
		if p.Serialized and not SKIP_PROPS[p.Name] and p.Name ~= "Source" then
			table.insert(c, { Name = p.Name, Type = p.Type and p.Type.EngineType or "" })
		end
	end
	propCache[class] = c
	local ok, inst = pcall(Instance.new, class)
	if ok then
		defaultCache[class] = inst
	end
	return c
end

local function esc(s: string): string
	s = s:gsub("[%z\1-\8\11\12\14-\31]", "")
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end
local function num(n: number, double: boolean?): string
	if n ~= n then
		return "NAN"
	elseif n == math.huge then
		return "INF"
	elseif n == -math.huge then
		return "-INF"
	end
	return string.format(if double then "%.17g" else "%.9g", n)
end
local function xyz(v)
	return `<X>{num(v.X)}</X><Y>{num(v.Y)}</Y><Z>{num(v.Z)}</Z>`
end

local referents = {}
local skipped = {}
local function enc(name: string, etype: string, v: any): string?
	local t = typeof(v)
	local n = esc(name)
	if t == "boolean" then
		return `<bool name="{n}">{tostring(v)}</bool>`
	elseif t == "number" then
		if etype == "int" then
			return `<int name="{n}">{string.format("%d", v)}</int>`
		elseif etype == "int64" then
			return `<int64 name="{n}">{string.format("%d", v)}</int64>`
		elseif etype == "double" then
			return `<double name="{n}">{num(v, true)}</double>`
		end
		return `<float name="{n}">{num(v)}</float>`
	elseif t == "string" then
		if etype == "ProtectedString" then
			return `<ProtectedString name="{n}"><![CDATA[{v:gsub("]]>", "]]]]><![CDATA[>")}]]></ProtectedString>`
		elseif etype == "ContentId" or etype == "Content" then
			if v == "" then
				return `<Content name="{n}"><null></null></Content>`
			end
			return `<Content name="{n}"><url>{esc(v)}</url></Content>`
		elseif etype == "BinaryString" then
			return nil
		end
		return `<string name="{n}">{esc(v)}</string>`
	elseif t == "Vector3" then
		return `<Vector3 name="{n}">{xyz(v)}</Vector3>`
	elseif t == "Vector3int16" then
		return `<Vector3int16 name="{n}"><X>{v.X}</X><Y>{v.Y}</Y><Z>{v.Z}</Z></Vector3int16>`
	elseif t == "Vector2" then
		return `<Vector2 name="{n}"><X>{num(v.X)}</X><Y>{num(v.Y)}</Y></Vector2>`
	elseif t == "CFrame" then
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
		return `<CoordinateFrame name="{n}"><X>{num(x)}</X><Y>{num(y)}</Y><Z>{num(z)}</Z><R00>{num(r00)}</R00><R01>{num(r01)}</R01><R02>{num(r02)}</R02><R10>{num(r10)}</R10><R11>{num(r11)}</R11><R12>{num(r12)}</R12><R20>{num(r20)}</R20><R21>{num(r21)}</R21><R22>{num(r22)}</R22></CoordinateFrame>`
	elseif t == "Color3" then
		if etype == "Color3uint8" then
			local r, g, b = math.clamp(math.round(v.R * 255), 0, 255), math.clamp(math.round(v.G * 255), 0, 255), math.clamp(math.round(v.B * 255), 0, 255)
			return `<Color3uint8 name="{n}">{4278190080 + r * 65536 + g * 256 + b}</Color3uint8>`
		end
		return `<Color3 name="{n}"><R>{num(v.R)}</R><G>{num(v.G)}</G><B>{num(v.B)}</B></Color3>`
	elseif t == "BrickColor" then
		return `<int name="{n}">{v.Number}</int>`
	elseif t == "EnumItem" then
		return `<token name="{n}">{v.Value}</token>`
	elseif t == "UDim" then
		return `<UDim name="{n}"><S>{num(v.Scale)}</S><O>{v.Offset}</O></UDim>`
	elseif t == "UDim2" then
		return `<UDim2 name="{n}"><XS>{num(v.X.Scale)}</XS><XO>{v.X.Offset}</XO><YS>{num(v.Y.Scale)}</YS><YO>{v.Y.Offset}</YO></UDim2>`
	elseif t == "Rect" then
		return `<Rect2D name="{n}"><min><X>{num(v.Min.X)}</X><Y>{num(v.Min.Y)}</Y></min><max><X>{num(v.Max.X)}</X><Y>{num(v.Max.Y)}</Y></max></Rect2D>`
	elseif t == "NumberRange" then
		return `<NumberRange name="{n}">{num(v.Min)} {num(v.Max)} </NumberRange>`
	elseif t == "NumberSequence" then
		local parts = {}
		for _, k in v.Keypoints do
			table.insert(parts, `{num(k.Time)} {num(k.Value)} {num(k.Envelope)} `)
		end
		return `<NumberSequence name="{n}">{table.concat(parts)}</NumberSequence>`
	elseif t == "ColorSequence" then
		local parts = {}
		for _, k in v.Keypoints do
			table.insert(parts, `{num(k.Time)} {num(k.Value.R)} {num(k.Value.G)} {num(k.Value.B)} 0 `)
		end
		return `<ColorSequence name="{n}">{table.concat(parts)}</ColorSequence>`
	elseif t == "PhysicalProperties" then
		return `<PhysicalProperties name="{n}"><CustomPhysics>true</CustomPhysics><Density>{num(v.Density)}</Density><Friction>{num(v.Friction)}</Friction><Elasticity>{num(v.Elasticity)}</Elasticity><FrictionWeight>{num(v.FrictionWeight)}</FrictionWeight><ElasticityWeight>{num(v.ElasticityWeight)}</ElasticityWeight></PhysicalProperties>`
	elseif t == "nil" and etype == "PhysicalProperties" then
		return `<PhysicalProperties name="{n}"><CustomPhysics>false</CustomPhysics></PhysicalProperties>`
	elseif t == "Font" then
		return `<Font name="{n}"><Family><url>{esc(v.Family)}</url></Family><Weight>{v.Weight.Value}</Weight><Style>{v.Style.Name}</Style></Font>`
	elseif t == "Faces" then
		local bits = (if v.Right then 1 else 0) + (if v.Top then 2 else 0) + (if v.Back then 4 else 0) + (if v.Left then 8 else 0) + (if v.Bottom then 16 else 0) + (if v.Front then 32 else 0)
		return `<Faces name="{n}"><faces>{bits}</faces></Faces>`
	elseif t == "Axes" then
		local bits = (if v.X then 1 else 0) + (if v.Y then 2 else 0) + (if v.Z then 4 else 0)
		return `<Axes name="{n}"><axes>{bits}</axes></Axes>`
	elseif t == "Instance" or (t == "nil" and etype == "RefType") then
		local ref = v and referents[v]
		return `<Ref name="{n}">{ref or "null"}</Ref>`
	end
	skipped[t .. ":" .. etype] = (skipped[t .. ":" .. etype] or 0) + 1
	return nil
end

local function same(a: any, b: any): boolean
	if a == b then
		return true
	end
	if typeof(a) == "number" and typeof(b) == "number" then
		return math.abs(a - b) < 1e-7
	end
	return false
end

-- Attribute im Roblox-Binärformat (rbx-dom docs/attributes.md)
local function attributesBlob(inst: Instance): string?
	local attrs = inst:GetAttributes()
	local keys = {}
	for k in attrs do
		table.insert(keys, k)
	end
	if #keys == 0 then
		return nil
	end
	table.sort(keys)
	local out = { string.pack("<I4", #keys) }
	for _, k in keys do
		local v = attrs[k]
		table.insert(out, string.pack("<s4", k))
		local t = typeof(v)
		if t == "string" then
			table.insert(out, string.pack("<B s4", 0x02, v))
		elseif t == "boolean" then
			table.insert(out, string.pack("<BB", 0x03, if v then 1 else 0))
		elseif t == "number" then
			table.insert(out, string.pack("<Bd", 0x06, v))
		elseif t == "Vector3" then
			table.insert(out, string.pack("<Bfff", 0x11, v.X, v.Y, v.Z))
		elseif t == "Color3" then
			table.insert(out, string.pack("<Bfff", 0x0F, v.R, v.G, v.B))
		elseif t == "CFrame" then
			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
			table.insert(out, string.pack("<BfffBfffffffff", 0x14, x, y, z, 0, r00, r01, r02, r10, r11, r12, r20, r21, r22))
		else
			error(`Attributtyp {t} nicht unterstützt ({inst:GetFullName()}.{k})`)
		end
	end
	return table.concat(out)
end
local function b64(s: string): string
	return buffer.tostring(ES:Base64Encode(buffer.fromstring(s)))
end

local function export(root: Instance): (string, { string })
	table.clear(referents)
	local notes = {}
	local all = { root }
	for _, d in root:GetDescendants() do
		table.insert(all, d)
	end
	local id = 0
	for _, d in all do
		id += 1
		referents[d] = "RBX" .. id
	end
	local out = { '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">' }
	local function write(inst: Instance)
		if SKIP_CLASSES[inst.ClassName] then
			table.insert(notes, inst:GetFullName() .. " [" .. inst.ClassName .. "]")
			return
		end
		table.insert(out, `<Item class="{inst.ClassName}" referent="{referents[inst]}"><Properties>`)
		local props = propsOf(inst.ClassName)
		local def = defaultCache[inst.ClassName]
		if inst:IsA("LuaSourceContainer") then
			table.insert(out, enc("Source", "ProtectedString", (inst :: any).Source) :: string)
		end
		if inst:IsA("Model") then
			table.insert(out, `<OptionalCoordinateFrame name="WorldPivotData">{(enc("CFrame", "CoordinateFrame", inst:GetPivot()) :: string):gsub('^<CoordinateFrame name="CFrame">', "<CFrame>"):gsub("</CoordinateFrame>$", "</CFrame>")}</OptionalCoordinateFrame>`)
			local scale = (inst :: Model):GetScale()
			if scale ~= 1 then
				table.insert(out, `<float name="ScaleFactor">{num(scale)}</float>`)
			end
			table.insert(out, `<bool name="NeedsPivotMigration">false</bool>`)
		end
		for _, p in props do
			local readName = ALIAS[p.Name] or p.Name
			local ok, v = pcall(function()
				return (inst :: any)[readName]
			end)
			if ok then
				local include = p.Name == "Name" or not def
				if not include then
					local okd, dv = pcall(function()
						return (def :: any)[readName]
					end)
					include = not okd or not same(v, dv)
				end
				if include then
					local s = enc(p.Name, p.Type, v)
					if s then
						table.insert(out, s)
					end
				end
			end
		end
		local blob = attributesBlob(inst)
		if blob then
			table.insert(out, `<BinaryString name="AttributesSerialize">{b64(blob)}</BinaryString>`)
		end
		local tags = CS:GetTags(inst)
		if #tags > 0 then
			table.insert(out, `<BinaryString name="Tags">{b64(table.concat(tags, "\0"))}</BinaryString>`)
		end
		table.insert(out, "</Properties>")
		for _, c in inst:GetChildren() do
			write(c)
		end
		table.insert(out, "</Item>")
	end
	write(root)
	table.insert(out, "</roblox>")
	return table.concat(out, "\n"), notes
end

_G.__export = _G.__export or {}
local results = {}
-- Wurzeln: _G.__exportRoots = { Name = Instanz } oder Standard (Halle + A-Chassis)
local roots = (_G :: any).__exportRoots or { HallLayout = workspace.HallLayout, AChassis = game.ServerStorage.Vendor.AChassis }
for name, root in roots do
	local xml, notes = export(root)
	_G.__export[name] = b64(xml)
	table.insert(results, `{name}: {#xml} Bytes XML, base64 {#_G.__export[name]}, übersprungen: {table.concat(notes, "; ")}`)
end
local sk = {}
for k, v in skipped do
	table.insert(sk, k .. "=" .. v)
end
return table.concat(results, "\n") .. "\nnicht kodiert: " .. table.concat(sk, ", ")
