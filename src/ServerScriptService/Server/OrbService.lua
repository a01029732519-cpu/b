-- Builds each player's personal clickable ASMR orb plot and applies skins.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local OrbService = {}

local PLOT_SPACING = 40

local function getPlotsFolder()
	local folder = workspace:FindFirstChild("ASMRPlots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ASMRPlots"
		folder.Parent = workspace
	end
	return folder
end

function OrbService.GetSkin(skinId)
	for _, skin in ipairs(GameConfig.Skins) do
		if skin.Id == skinId then
			return skin
		end
	end
	return GameConfig.Skins[1]
end

function OrbService.GetClickValue(clickLevel)
	local value = GameConfig.StartingPointsPerClick
	for i = 1, clickLevel do
		local upgrade = GameConfig.ClickUpgrades[i]
		if upgrade then
			value = upgrade.PointsPerClick
		end
	end
	return value
end

function OrbService.ApplySkin(orb, skinData)
	if not orb then
		return
	end
	orb.Color = skinData.Color
	orb.Material = skinData.Material
	orb.Transparency = skinData.Transparency or 0
	local light = orb:FindFirstChildOfClass("PointLight")
	if light then
		light.Color = skinData.Color
	end
end

-- Creates a private platform + orb for the player at a unique slot along
-- the X axis and returns (plotFolder, orb, clickDetector, origin).
function OrbService.CreatePlot(player, plotIndex, equippedSkinId)
	local origin = Vector3.new((plotIndex - 1) * PLOT_SPACING, 0, 0)

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = player.Name .. "_Plot"

	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(28, 1, 28)
	platform.Anchored = true
	platform.CanCollide = true
	platform.Material = Enum.Material.SmoothPlastic
	platform.Color = Color3.fromRGB(255, 241, 224)
	platform.Position = origin + Vector3.new(0, 4, 0)
	platform.Parent = plotFolder

	local label = Instance.new("BillboardGui")
	label.Name = "NameLabel"
	label.Size = UDim2.new(0, 220, 0, 40)
	label.StudsOffset = Vector3.new(0, 6, 0)
	label.AlwaysOnTop = true
	label.Adornee = platform
	label.Parent = platform

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.GothamMedium
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0.4
	text.Text = player.Name .. "'s ASMR Corner"
	text.Parent = label

	local skin = OrbService.GetSkin(equippedSkinId or GameConfig.Skins[1].Id)

	local orb = Instance.new("Part")
	orb.Name = "ASMROrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(6, 6, 6)
	orb.Anchored = true
	orb.CanCollide = false
	orb.TopSurface = Enum.SurfaceType.Smooth
	orb.BottomSurface = Enum.SurfaceType.Smooth
	orb.Position = origin + Vector3.new(0, 9, 0)
	orb.Parent = plotFolder

	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 14
	light.Parent = orb

	OrbService.ApplySkin(orb, skin)

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = orb

	plotFolder.Parent = getPlotsFolder()

	return plotFolder, orb, clickDetector, origin
end

return OrbService
