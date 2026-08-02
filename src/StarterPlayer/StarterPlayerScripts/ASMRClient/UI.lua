-- Builds and refreshes the ASMR Clicker HUD: points display, shop
-- (click power / skins / helpers) and audio settings panel.

local UserInputService = game:GetService("UserInputService")

local UI = {}

local PASTEL_BG = Color3.fromRGB(255, 247, 240)
local PASTEL_ACCENT = Color3.fromRGB(255, 176, 190)
local PASTEL_TEXT = Color3.fromRGB(90, 70, 60)
local PASTEL_MUTED = Color3.fromRGB(180, 165, 155)

local function formatNumber(n)
	n = math.floor(n)
	local formatted = tostring(n)
	while true do
		local newFormatted, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = newFormatted
		if count == 0 then
			break
		end
	end
	return formatted
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 12)
	c.Parent = parent
	return c
end

local function makeButton(parent, size, text, bgColor)
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = bgColor or PASTEL_ACCENT
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.Parent = parent
	corner(button, UDim.new(0, 10))
	return button
end

local function createSlider(parent, layoutOrder, labelText, initialValue, onChanged)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 50)
	container.BackgroundTransparency = 1
	container.LayoutOrder = layoutOrder
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 15
	label.TextColor3 = PASTEL_TEXT
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.Parent = container

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 0, 0, 26)
	track.Size = UDim2.new(1, 0, 0, 10)
	track.BackgroundColor3 = Color3.fromRGB(235, 220, 210)
	track.BorderSizePixel = 0
	track.Parent = container
	corner(track, UDim.new(1, 0))

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = PASTEL_ACCENT
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(initialValue, 0, 1, 0)
	fill.Parent = track
	corner(fill, UDim.new(1, 0))

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(initialValue, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.ZIndex = 2
	knob.Parent = track
	corner(knob, UDim.new(1, 0))

	local dragging = false

	local function setFromX(inputX)
		local trackAbsPos = track.AbsolutePosition.X
		local trackAbsSize = track.AbsoluteSize.X
		if trackAbsSize <= 0 then
			return
		end
		local relative = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
		fill.Size = UDim2.new(relative, 0, 1, 0)
		knob.Position = UDim2.new(relative, 0, 0.5, 0)
		onChanged(relative)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return {
		SetValue = function(value)
			fill.Size = UDim2.new(value, 0, 1, 0)
			knob.Position = UDim2.new(value, 0, 0.5, 0)
		end,
	}
end

local function buildRow(parent, layoutOrder, titleText, subtitleText, buttonText, buttonEnabled, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 64)
	row.BackgroundColor3 = Color3.fromRGB(255, 253, 250)
	row.LayoutOrder = layoutOrder
	row.Parent = parent
	corner(row, UDim.new(0, 10))

	local title = Instance.new("TextLabel")
	title.Position = UDim2.new(0, 14, 0, 8)
	title.Size = UDim2.new(1, -140, 0, 22)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = PASTEL_TEXT
	title.Text = titleText
	title.Parent = row

	local subtitle = Instance.new("TextLabel")
	subtitle.Position = UDim2.new(0, 14, 0, 32)
	subtitle.Size = UDim2.new(1, -140, 0, 20)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 13
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextColor3 = PASTEL_MUTED
	subtitle.Text = subtitleText
	subtitle.Parent = row

	local button = makeButton(row, UDim2.new(0, 110, 0, 40), buttonText, buttonEnabled and PASTEL_ACCENT or Color3.fromRGB(215, 210, 205))
	button.Position = UDim2.new(1, -122, 0.5, -20)
	button.Active = buttonEnabled
	button.AutoButtonColor = buttonEnabled
	if buttonEnabled then
		button.Activated:Connect(onClick)
	end

	return row
end

function UI.Build(player, GameConfig)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ASMRGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Top-left points display
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(0, 200, 0, 54)
	topBar.Position = UDim2.new(0, 16, 0, 16)
	topBar.BackgroundColor3 = PASTEL_BG
	topBar.Parent = screenGui
	corner(topBar, UDim.new(0, 16))

	local pointsLabel = Instance.new("TextLabel")
	pointsLabel.Size = UDim2.new(1, -20, 1, 0)
	pointsLabel.Position = UDim2.new(0, 10, 0, 0)
	pointsLabel.BackgroundTransparency = 1
	pointsLabel.Font = Enum.Font.GothamBold
	pointsLabel.TextSize = 22
	pointsLabel.TextColor3 = PASTEL_TEXT
	pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
	pointsLabel.Text = "✨ 0"
	pointsLabel.Parent = topBar

	-- Bottom-right toggle buttons
	local buttonHolder = Instance.new("Frame")
	buttonHolder.Size = UDim2.new(0, 140, 0, 100)
	buttonHolder.Position = UDim2.new(1, -156, 1, -116)
	buttonHolder.BackgroundTransparency = 1
	buttonHolder.Parent = screenGui

	local shopToggle = makeButton(buttonHolder, UDim2.new(1, 0, 0, 44), "🛍 Shop")
	shopToggle.Position = UDim2.new(0, 0, 0, 0)

	local settingsToggle = makeButton(buttonHolder, UDim2.new(1, 0, 0, 44), "⚙ Settings", Color3.fromRGB(190, 200, 230))
	settingsToggle.Position = UDim2.new(0, 0, 0, 56)

	-- Shop panel
	local shopFrame = Instance.new("Frame")
	shopFrame.Size = UDim2.new(0, 420, 0, 420)
	shopFrame.Position = UDim2.new(0.5, -210, 0.5, -210)
	shopFrame.BackgroundColor3 = PASTEL_BG
	shopFrame.Visible = false
	shopFrame.Parent = screenGui
	corner(shopFrame, UDim.new(0, 20))

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.new(1, -50, 0, 40)
	shopTitle.Position = UDim2.new(0, 16, 0, 10)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.TextSize = 22
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.TextColor3 = PASTEL_TEXT
	shopTitle.Text = "ASMR Shop"
	shopTitle.Parent = shopFrame

	local shopClose = makeButton(shopFrame, UDim2.new(0, 34, 0, 34), "✕", Color3.fromRGB(230, 150, 150))
	shopClose.Position = UDim2.new(1, -46, 0, 12)
	shopClose.Activated:Connect(function()
		shopFrame.Visible = false
	end)

	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -32, 0, 36)
	tabBar.Position = UDim2.new(0, 16, 0, 56)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = shopFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabBar

	local tabButtons = {}
	local function makeTab(id, text)
		local tab = makeButton(tabBar, UDim2.new(0, 120, 1, 0), text, Color3.fromRGB(230, 224, 218))
		tabButtons[id] = tab
		return tab
	end
	makeTab("ClickUpgrade", "Click Power")
	makeTab("Skin", "Skins")
	makeTab("Helper", "Helpers")

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -32, 1, -104)
	listFrame.Position = UDim2.new(0, 16, 0, 100)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 6
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent = shopFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = listFrame

	-- Settings panel
	local settingsFrame = Instance.new("Frame")
	settingsFrame.Size = UDim2.new(0, 340, 0, 220)
	settingsFrame.Position = UDim2.new(0.5, -170, 0.5, -110)
	settingsFrame.BackgroundColor3 = PASTEL_BG
	settingsFrame.Visible = false
	settingsFrame.Parent = screenGui
	corner(settingsFrame, UDim.new(0, 20))

	local settingsTitle = Instance.new("TextLabel")
	settingsTitle.Size = UDim2.new(1, -50, 0, 40)
	settingsTitle.Position = UDim2.new(0, 16, 0, 10)
	settingsTitle.BackgroundTransparency = 1
	settingsTitle.Font = Enum.Font.GothamBold
	settingsTitle.TextSize = 20
	settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
	settingsTitle.TextColor3 = PASTEL_TEXT
	settingsTitle.Text = "Audio Settings"
	settingsTitle.Parent = settingsFrame

	local settingsClose = makeButton(settingsFrame, UDim2.new(0, 34, 0, 34), "✕", Color3.fromRGB(230, 150, 150))
	settingsClose.Position = UDim2.new(1, -46, 0, 12)
	settingsClose.Activated:Connect(function()
		settingsFrame.Visible = false
	end)

	local slidersHolder = Instance.new("Frame")
	slidersHolder.Size = UDim2.new(1, -32, 1, -70)
	slidersHolder.Position = UDim2.new(0, 16, 0, 60)
	slidersHolder.BackgroundTransparency = 1
	slidersHolder.Parent = settingsFrame

	local slidersLayout = Instance.new("UIListLayout")
	slidersLayout.Padding = UDim.new(0, 12)
	slidersLayout.Parent = slidersHolder

	shopToggle.Activated:Connect(function()
		settingsFrame.Visible = false
		shopFrame.Visible = not shopFrame.Visible
	end)
	settingsToggle.Activated:Connect(function()
		shopFrame.Visible = false
		settingsFrame.Visible = not settingsFrame.Visible
	end)

	local refs = {
		ScreenGui = screenGui,
		PointsLabel = pointsLabel,
		ShopFrame = shopFrame,
		SettingsFrame = settingsFrame,
		ListFrame = listFrame,
		TabButtons = tabButtons,
		CurrentTab = "ClickUpgrade",
		SlidersHolder = slidersHolder,
		AudioSynced = false,
		OnBuy = function() end,
		OnSetAudio = function() end,
	}

	local musicSlider = createSlider(slidersHolder, 1, "Music Volume", 0.4, function(value)
		refs.OnSetAudio("Music", value)
	end)
	local sfxSlider = createSlider(slidersHolder, 2, "SFX Volume", 0.6, function(value)
		refs.OnSetAudio("Sfx", value)
	end)
	refs.MusicSlider = musicSlider
	refs.SfxSlider = sfxSlider

	for id, tab in pairs(tabButtons) do
		tab.Activated:Connect(function()
			refs.CurrentTab = id
			refs.RefreshList()
		end)
	end

	return refs
end

local function refreshListFrame(refs, data, GameConfig)
	local listFrame = refs.ListFrame
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for id, tab in pairs(refs.TabButtons) do
		tab.BackgroundColor3 = (id == refs.CurrentTab) and PASTEL_ACCENT or Color3.fromRGB(230, 224, 218)
	end

	if refs.CurrentTab == "ClickUpgrade" then
		for i, upgrade in ipairs(GameConfig.ClickUpgrades) do
			local owned = data.ClickLevel >= upgrade.Level
			local isNext = data.ClickLevel + 1 == upgrade.Level
			local affordable = data.Points >= upgrade.Cost

			local buttonText, enabled
			if owned then
				buttonText, enabled = "Owned ✓", false
			elseif isNext then
				buttonText, enabled = ("Buy - %d pts"):format(upgrade.Cost), affordable
			else
				buttonText, enabled = "Locked", false
			end

			buildRow(
				listFrame,
				i,
				("Level %d: +%d pts/click"):format(upgrade.Level, upgrade.PointsPerClick),
				owned and "Unlocked" or (("Cost: %d pts"):format(upgrade.Cost)),
				buttonText,
				enabled,
				function()
					refs.OnBuy("ClickUpgrade")
				end
			)
		end
	elseif refs.CurrentTab == "Skin" then
		for i, skin in ipairs(GameConfig.Skins) do
			local owned = table.find(data.OwnedSkins, skin.Id) ~= nil
			local equipped = data.EquippedSkin == skin.Id
			local affordable = data.Points >= skin.Cost

			local buttonText, enabled
			if equipped then
				buttonText, enabled = "Equipped", false
			elseif owned then
				buttonText, enabled = "Equip", true
			else
				buttonText, enabled = ("Buy - %d pts"):format(skin.Cost), affordable
			end

			buildRow(
				listFrame,
				i,
				skin.Name,
				owned and "Owned" or (("Cost: %d pts"):format(skin.Cost)),
				buttonText,
				enabled,
				function()
					refs.OnBuy("Skin", skin.Id)
				end
			)
		end
	elseif refs.CurrentTab == "Helper" then
		for i, helper in ipairs(GameConfig.Helpers) do
			local owned = table.find(data.OwnedHelpers, helper.Id) ~= nil
			local affordable = data.Points >= helper.Cost

			local buttonText, enabled
			if owned then
				buttonText, enabled = "Owned ✓", false
			else
				buttonText, enabled = ("Buy - %d pts"):format(helper.Cost), affordable
			end

			buildRow(
				listFrame,
				i,
				helper.Name,
				("+%d pts every %ds"):format(helper.PointsPerTick, GameConfig.HelperTickSeconds),
				buttonText,
				enabled,
				function()
					refs.OnBuy("Helper", helper.Id)
				end
			)
		end
	end
end

function UI.Refresh(refs, data, GameConfig)
	refs.PointsLabel.Text = "✨ " .. formatNumber(data.Points)

	if not refs.AudioSynced then
		refs.MusicSlider.SetValue(data.MusicVolume)
		refs.SfxSlider.SetValue(data.SfxVolume)
		refs.AudioSynced = true
	end

	refs.RefreshList = function()
		refreshListFrame(refs, data, GameConfig)
	end
	refs.RefreshList()
end

function UI.PlayHelperTickFeedback(refs)
	local label = refs.PointsLabel
	local originalColor = label.TextColor3
	label.TextColor3 = PASTEL_ACCENT
	task.delay(0.25, function()
		label.TextColor3 = originalColor
	end)
end

return UI
