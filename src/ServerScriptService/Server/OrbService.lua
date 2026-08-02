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

-- Squishy stress ball: a smaller matte ball with two simple eyes pressed
-- onto the front so it reads as a hand-squeeze toy rather than a plain orb.
local function buildStressBallModel(origin, skin)
	local ball, targets = buildBallModel(origin, skin)
	ball.Size = Vector3.new(5, 5, 5)
	ball.Position = origin + Vector3.new(0, 8.5, 0)

	local eyeColor = Color3.fromRGB(40, 32, 28)
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.7, 0.7, 0.35)
		eye.Anchored = true
		eye.CanCollide = false
		eye.CanQuery = false
		eye.Material = Enum.Material.SmoothPlastic
		eye.Color = eyeColor
		eye.Position = ball.Position + Vector3.new(side * 0.9, 0.4, -2.15)
		eye.Parent = ball
	end

	return ball, targets
end

-- Wrapped salted-butter block: a rectangular slab with a paper "wrapper"
-- band around the middle, like the reference footage's butter platforms.
local function buildSaltedButterModel(origin, skin)
	local block = Instance.new("Part")
	block.Name = "ClickModel"
	block.Size = Vector3.new(5, 3.2, 3.6)
	block.Anchored = true
	block.CanCollide = false
	block.Position = origin + Vector3.new(0, 7.5, 0)
	block.Color = skin.Color
	block.Material = skin.Material or Enum.Material.SmoothPlastic

	local light = Instance.new("PointLight")
	light.Brightness = 1.6
	light.Range = 12
	light.Color = skin.Color
	light.Parent = block

	local band = Instance.new("Part")
	band.Name = "WrapperBand"
	band.Size = Vector3.new(5.2, 1.1, 3.8)
	band.Anchored = true
	band.CanCollide = false
	band.CanQuery = false
	band.Material = Enum.Material.SmoothPlastic
	band.Color = skin.BandColor or Color3.fromRGB(196, 140, 70)
	band.Position = block.Position
	band.Parent = block

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = band

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 250, 240)
	label.Text = "BUTTER"
	label.Parent = gui

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = block

	return block, { block }
end

-- Choco popsicle: an ellipsoid choco head on a stick. The head is the click
-- target; Effects.PlayCrumbBurst (client) adds the "bite breaking off" look.
local function buildChocoPopsicleModel(origin, skin)
	local head = Instance.new("Part")
	head.Name = "ClickModel"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(3.6, 4.4, 1.6)
	head.Anchored = true
	head.CanCollide = false
	head.Position = origin + Vector3.new(0, 9, 0)
	head.Color = skin.Color
	head.Material = skin.Material or Enum.Material.SmoothPlastic

	local light = Instance.new("PointLight")
	light.Brightness = 1.6
	light.Range = 12
	light.Color = skin.Color
	light.Parent = head

	local stick = Instance.new("Part")
	stick.Name = "Stick"
	stick.Size = Vector3.new(0.5, 2.4, 0.15)
	stick.Anchored = true
	stick.CanCollide = false
	stick.CanQuery = false
	stick.Material = Enum.Material.SmoothPlastic
	stick.Color = skin.StickColor or Color3.fromRGB(232, 201, 155)
	stick.Position = head.Position - Vector3.new(0, head.Size.Y / 2 + stick.Size.Y / 2 - 0.3, 0)
	stick.Parent = head

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = head

	return head, { head }
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

-- Stacked ABC letter-block tower: a smaller multi-target combo than
-- BubbleWrap. Blocks reuse the exact "Bump" naming/attribute convention so
-- OrbService.SetBumpPopped and the client's generic bump hookup work as-is.
local function buildABCBlocksModel(origin, skin)
	local stack = GameConfig.ABCBlocksStack
	local board = Instance.new("Model")
	board.Name = "ClickModel"

	local blockSize = stack.BlockSize
	local baseY = origin.Y + 5.5

	for i, letter in ipairs(stack.Letters) do
		local color = stack.RowColors[((i - 1) % #stack.RowColors) + 1]
		local topY = baseY + (i - 1) * (blockSize.Y + stack.Gap) + blockSize.Y / 2

		local block = Instance.new("Part")
		block.Name = "Bump"
		block.Size = blockSize
		block.Anchored = true
		block.CanCollide = false
		block.Material = Enum.Material.SmoothPlastic
		block.Color = color
		block.Position = Vector3.new(origin.X, topY, origin.Z)
		block:SetAttribute("Popped", false)
		block:SetAttribute("OriginalY", topY)
		block:SetAttribute("RowColorR", color.R)
		block:SetAttribute("RowColorG", color.G)
		block:SetAttribute("RowColorB", color.B)
		block.Parent = board

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = block

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0.5
		label.Text = letter
		label.Parent = gui

		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 18
		clickDetector.Parent = block
	end

	local blocks = {}
	for _, child in ipairs(board:GetChildren()) do
		if child.Name == "Bump" then
			table.insert(blocks, child)
		end
	end

	return board, blocks
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

local MODEL_BUILDERS = {
	StressBall = buildStressBallModel,
	SaltedButter = buildSaltedButterModel,
	ChocoPopsicle = buildChocoPopsicleModel,
	BubbleWrap = buildBubbleWrapModel,
	ABCBlocks = buildABCBlocksModel,
}

-- Model types with several independently-clickable targets (pop-it grid,
-- letter-block tower) that combo into a bonus + reset when fully cleared,
-- as opposed to a single click target like a ball or butter block.
local MULTI_TARGET_TYPES = {
	BubbleWrap = true,
	ABCBlocks = true,
}

function OrbService.IsMultiTarget(modelType)
	return MULTI_TARGET_TYPES[modelType] == true
end

-- Builds the correct click model for a skin (plain ball by default, or one
-- of the named MODEL_BUILDERS) and returns (rootInstance, clickableParts).
function OrbService.BuildClickModel(origin, skin)
	local builder = MODEL_BUILDERS[skin.ModelType]
	if builder then
		return builder(origin, skin)
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
