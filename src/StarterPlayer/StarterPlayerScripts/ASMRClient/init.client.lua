-- ASMR Clicker: client entry point.
-- Builds the HUD, plays local click feedback instantly, and relays
-- purchases/settings to the server which owns the authoritative data.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local UI = require(script.UI)
local Effects = require(script.Effects)

local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyUpgradeRemote = Remotes:WaitForChild("BuyUpgrade")
local DataSyncRemote = Remotes:WaitForChild("DataSync")
local SetAudioSettingRemote = Remotes:WaitForChild("SetAudioSetting")

local data = {
	Points = 0,
	ClickLevel = 0,
	EquippedSkin = GameConfig.Skins[1].Id,
	OwnedSkins = { GameConfig.Skins[1].Id },
	OwnedHelpers = {},
	MusicVolume = 0.4,
	SfxVolume = 0.6,
}

local function getSkin(skinId)
	for _, skin in ipairs(GameConfig.Skins) do
		if skin.Id == skinId then
			return skin
		end
	end
	return GameConfig.Skins[1]
end

local refs = UI.Build(player, GameConfig)

local function refresh()
	UI.Refresh(refs, data, GameConfig)
end

refs.OnBuy = function(kind, id)
	BuyUpgradeRemote:FireServer(kind, id)
end

refs.OnSetAudio = function(setting, value)
	if setting == "Music" then
		data.MusicVolume = value
		if refs.MusicSound then
			refs.MusicSound.Volume = value
		end
	elseif setting == "Sfx" then
		data.SfxVolume = value
	end
	SetAudioSettingRemote:FireServer(setting, value)
end

local currentClickModel = nil -- the plot's own ClickModel, re-resolved whenever it's rebuilt (skin change)

DataSyncRemote.OnClientEvent:Connect(function(newData, reason)
	local previousPoints = data.Points
	for key, value in pairs(newData) do
		data[key] = value
	end
	refresh()
	if reason == "HelperTick" then
		UI.PlayHelperTickFeedback(refs)
	elseif reason == "BoardClear" then
		local bonus = data.Points - previousPoints
		if currentClickModel then
			Effects.PlayBoardClear(currentClickModel, getSkin(data.EquippedSkin), data.SfxVolume)
		end
		if bonus > 0 then
			UI.ShowBonusPopup(refs, ("BOARD CLEAR! +%d"):format(bonus))
		end
	end
end)

-- Ambient background music
local music = Instance.new("Sound")
music.Name = "ASMRAmbientMusic"
music.SoundId = GameConfig.AmbientMusic
music.Looped = true
music.Volume = data.MusicVolume
music.Parent = SoundService
music:Play()
refs.MusicSound = music

-- Hooks whichever ClickModel currently sits in the player's own plot:
-- a plain ball (Effects.PlayClickFeedback) or a BubbleWrap pop-it grid
-- (Effects.PlayBumpPop per bump). Re-runs whenever the server rebuilds the
-- model after an equip, since the old instance is destroyed and a new one
-- with the same name is parented in.
local function hookClickModel(plotFolder)
	local model = plotFolder:FindFirstChild("ClickModel")
	if not model or model == currentClickModel then
		return
	end
	currentClickModel = model

	if model:IsA("BasePart") then
		local clickDetector = model:FindFirstChildOfClass("ClickDetector")
		if clickDetector then
			clickDetector.MouseClick:Connect(function()
				local skin = getSkin(data.EquippedSkin)
				Effects.PlayClickFeedback(model, skin, data.SfxVolume)
				if skin.ModelType == "ChocoPopsicle" then
					Effects.PlayCrumbBurst(model, skin.Color)
				end
			end)
		end
	elseif model:IsA("Model") then
		for _, bump in ipairs(model:GetChildren()) do
			if bump.Name == "Bump" then
				local clickDetector = bump:FindFirstChildOfClass("ClickDetector")
				if clickDetector then
					clickDetector.MouseClick:Connect(function()
						Effects.PlayBumpPop(bump, getSkin(data.EquippedSkin), data.SfxVolume)
					end)
				end
			end
		end
	end
end

-- Wait for and hook this player's personal plot once the server spawns it
task.spawn(function()
	local plotsFolder = workspace:WaitForChild("ASMRPlots", 30)
	if not plotsFolder then
		return
	end
	local plotFolder = plotsFolder:WaitForChild(player.Name .. "_Plot", 30)
	if not plotFolder then
		return
	end

	plotFolder.ChildAdded:Connect(function(child)
		if child.Name == "ClickModel" then
			hookClickModel(plotFolder)
		end
	end)
	hookClickModel(plotFolder)
end)

refresh()
