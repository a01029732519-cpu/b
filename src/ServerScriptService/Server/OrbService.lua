-- Builds each player's personal clickable ASMR model (plot + click model)
-- and rebuilds it when a player equips a different skin.

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

-- Plain clickable ball (Slime / Kinetic Sand / Cloud Foam / default skins).
local function buildBallModel(origin, skin)
	local orb = Instance.new("Part")
	orb.Name = "ClickModel"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(6, 6, 6)
	orb.Anchored = true
	orb.CanCollide = false
	orb.TopSurface = Enum.SurfaceType.Smooth
	orb.BottomSurface = Enum.SurfaceType.Smooth
	orb.Position = origin + Vector3.new(0, 9, 0)
	orb.Color = skin.Color
	orb.Material = skin.Material
	orb.Transparency = skin.Transparency or 0

	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 14
	light.Color = skin.Color
	light.Parent = orb

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = orb

	return orb, { orb }
end

-- Real pop-it / bubble wrap grid: a tray of individually poppable bumps.
-- Each bump has its own ClickDetector and a "Popped" bool attribute that
-- the server treats as authoritative state.
local function buildBubbleWrapModel(origin, skin)
	local grid = GameConfig.BubbleWrapGrid

	local board = Instance.new("Model")
	board.Name = "ClickModel"

	local trayY = origin.Y + 5
	local tray = Instance.new("Part")
	tray.Name = "Tray"
	tray.Size = grid.TraySize
	tray.Anchored = true
	tray.CanCollide = false
	tray.Material = Enum.Material.SmoothPlastic
	tray.Color = skin.Color
	tray.Position = origin + Vector3.new(0, 5, 0)
	tray.Parent = board
	board.PrimaryPart = tray

	local bumpTopY = trayY + grid.TraySize.Y / 2 + grid.BumpSize.Y / 2

	for row = 1, grid.Rows do
		local rowColor = grid.RowColors[((row - 1) % #grid.RowColors) + 1]
		local z = origin.Z - grid.TraySize.Z / 2 + (row - 0.5) * (grid.TraySize.Z / grid.Rows)

		for col = 1, grid.Columns do
			local x = origin.X - grid.TraySize.X / 2 + (col - 0.5) * (grid.TraySize.X / grid.Columns)

			local bump = Instance.new("Part")
			bump.Name = "Bump"
			bump.Shape = Enum.PartType.Ball
			bump.Size = grid.BumpSize
			bump.Anchored = true
			bump.CanCollide = false
			bump.Material = Enum.Material.SmoothPlastic
			bump.Color = rowColor
			bump.Position = Vector3.new(x, bumpTopY, z)
			bump:SetAttribute("Popped", false)
			bump:SetAttribute("OriginalY", bumpTopY)
			bump:SetAttribute("RowColorR", rowColor.R)
			bump:SetAttribute("RowColorG", rowColor.G)
			bump:SetAttribute("RowColorB", rowColor.B)
			bump.Parent = board

			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 16
			clickDetector.Parent = bump
		end
	end

	local bumps = {}
	for _, child in ipairs(board:GetChildren()) do
		if child.Name == "Bump" then
			table.insert(bumps, child)
		end
	end

	return board, bumps
end

local function bumpPopDepth(bump)
	return bump.Size.Y * 0.65
end

-- Pushes a bump down/darkens it (popped) or restores it (unpopped) visually.
-- Shared by both the server (authoritative click handling) and client
-- (instant local feedback) so the two never visually disagree.
function OrbService.SetBumpPopped(bump, popped)
	local originalY = bump:GetAttribute("OriginalY") or bump.Position.Y
	local rowColor = Color3.new(
		bump:GetAttribute("RowColorR") or 1,
		bump:GetAttribute("RowColorG") or 1,
		bump:GetAttribute("RowColorB") or 1
	)

	if popped then
		bump.Position = Vector3.new(bump.Position.X, originalY - bumpPopDepth(bump), bump.Position.Z)
		bump.Color = rowColor:Lerp(Color3.new(0, 0, 0), 0.35)
		bump.Transparency = 0.15
	else
		bump.Position = Vector3.new(bump.Position.X, originalY, bump.Position.Z)
		bump.Color = rowColor
		bump.Transparency = 0
	end
end

-- Builds the correct click model for a skin (Ball by default, or a
-- BubbleWrap grid) and returns (rootInstance, clickableParts).
function OrbService.BuildClickModel(origin, skin)
	if skin.ModelType == "BubbleWrap" then
		return buildBubbleWrapModel(origin, skin)
	end
	return buildBallModel(origin, skin)
end

-- Destroys the plot's current click model (if any) and builds a new one
-- for the given skin. Used both on first spawn and whenever a player
-- equips a different skin.
function OrbService.RebuildClickModel(plotFolder, origin, skin)
	local existing = plotFolder:FindFirstChild("ClickModel")
	if existing then
		existing:Destroy()
	end

	local root, clickTargets = OrbService.BuildClickModel(origin, skin)
	root.Parent = plotFolder
	return root, clickTargets
end

-- Creates a private platform + click model for the player at a unique
-- slot along the X axis. Returns (plotFolder, rootInstance, clickTargets, origin).
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

	plotFolder.Parent = getPlotsFolder()

	local skin = OrbService.GetSkin(equippedSkinId or GameConfig.Skins[1].Id)
	local root, clickTargets = OrbService.RebuildClickModel(plotFolder, origin, skin)

	return plotFolder, root, clickTargets, origin
end

return OrbService
