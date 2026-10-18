--!strict
-- Gemeinsame Darstellung der 3D-Icons (Erze, Kategorien): ein Modell im ViewportFrame, mit
-- einheitlichem Licht und Blickwinkel, damit alle Icons wie aus einem Guss wirken (docs/09 §61).

local ModelIcon = {}

-- Blickrichtung von schräg vorne oben (Teile zur Kamera hin sind gut sichtbar)
ModelIcon.View = Vector3.new(0.9, 0.75, 1).Unit

function ModelIcon.frame(model: Model?, size: number, name: string, zoom: number?): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.Name = name
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundTransparency = 1
	frame.Ambient = Color3.fromRGB(150, 150, 155)
	frame.LightColor = Color3.fromRGB(255, 250, 240)
	frame.LightDirection = Vector3.new(-0.6, -1, -0.4)
	if not model then
		return frame
	end
	local clone = model:Clone()
	clone.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local cf, extents = clone:GetBoundingBox()
	local radius = extents.Magnitude / 2
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * (zoom or 0.82)
	camera.CFrame = CFrame.lookAt(cf.Position + ModelIcon.View * distance, cf.Position)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

return table.freeze(ModelIcon)
