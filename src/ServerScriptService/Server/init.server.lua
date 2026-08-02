-- ASMR Clicker: server entry point.
-- Owns all authoritative state: points, purchases, saving, and orb plots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local PlayerData = require(script.PlayerData)
local OrbService = require(script.OrbService)
local PlotManager = require(script.PlotManager)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyUpgradeRemote = Remotes:WaitForChild("BuyUpgrade")
local DataSyncRemote = Remotes:WaitForChild("DataSync")
local SetAudioSettingRemote = Remotes:WaitForChild("SetAudioSetting")

local playerOrbs = {} -- [userId] = { Orb, PlotFolder, PlotIndex, Origin }
local clickTimestamps = {} -- [userId] = { recent click os.clock() times }

local function getLeaderstatPoints(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Points")
end

local function syncPoints(player, data)
	local points = getLeaderstatPoints(player)
	if points then
		points.Value = data.Points
	end
end

local function pushData(player, reason)
	local data = PlayerData.Get(player.UserId)
	if data then
		DataSyncRemote:FireClient(player, data, reason)
	end
end

local function isRateLimited(player)
	local now = os.clock()
	local times = clickTimestamps[player.UserId]
	if not times then
		times = {}
		clickTimestamps[player.UserId] = times
	end
	while #times > 0 and now - times[1] > 1 do
		table.remove(times, 1)
	end
	if #times >= GameConfig.MaxClicksPerSecond then
		return true
	end
	table.insert(times, now)
	return false
end

local function onOrbClicked(player)
	local data = PlayerData.Get(player.UserId)
	if not data then
		return
	end
	if isRateLimited(player) then
		return
	end

	data.Points += OrbService.GetClickValue(data.ClickLevel)
	syncPoints(player, data)
end

local function teleportToPlot(player, origin)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		hrp.CFrame = CFrame.new(origin + Vector3.new(0, 6, 10))
	end
end

local function setupPlayer(player)
	local data = PlayerData.Load(player.UserId)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Value = data.Points
	points.Parent = leaderstats
	leaderstats.Parent = player

	clickTimestamps[player.UserId] = {}

	local plotIndex = PlotManager.Assign()
	local plotFolder, orb, clickDetector, origin = OrbService.CreatePlot(player, plotIndex, data.EquippedSkin)

	playerOrbs[player.UserId] = {
		Orb = orb,
		PlotFolder = plotFolder,
		PlotIndex = plotIndex,
		Origin = origin,
	}

	clickDetector.MouseClick:Connect(onOrbClicked)

	player.CharacterAdded:Connect(function()
		teleportToPlot(player, origin)
	end)
	teleportToPlot(player, origin)

	pushData(player, "Init")
end

local function teardownPlayer(player)
	PlayerData.Save(player.UserId)
	PlayerData.Release(player.UserId)
	clickTimestamps[player.UserId] = nil

	local info = playerOrbs[player.UserId]
	if info then
		if info.PlotFolder then
			info.PlotFolder:Destroy()
		end
		PlotManager.Release(info.PlotIndex)
		playerOrbs[player.UserId] = nil
	end
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(teardownPlayer)

task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerData.Save(player.UserId)
		end
	end
end)

local function tryBuyClickUpgrade(data)
	local nextUpgrade = GameConfig.ClickUpgrades[data.ClickLevel + 1]
	if not nextUpgrade or data.Points < nextUpgrade.Cost then
		return false
	end
	data.Points -= nextUpgrade.Cost
	data.ClickLevel += 1
	return true
end

local function tryEquipOrBuySkin(player, data, skinId)
	local skin = OrbService.GetSkin(skinId)
	if not skin then
		return false
	end

	if not table.find(data.OwnedSkins, skin.Id) then
		if data.Points < skin.Cost then
			return false
		end
		data.Points -= skin.Cost
		table.insert(data.OwnedSkins, skin.Id)
	end

	data.EquippedSkin = skin.Id
	local info = playerOrbs[player.UserId]
	if info then
		OrbService.ApplySkin(info.Orb, skin)
	end
	return true
end

local function tryBuyHelper(data, helperId)
	if table.find(data.OwnedHelpers, helperId) then
		return false
	end
	local helperConfig
	for _, helper in ipairs(GameConfig.Helpers) do
		if helper.Id == helperId then
			helperConfig = helper
			break
		end
	end
	if not helperConfig or data.Points < helperConfig.Cost then
		return false
	end
	data.Points -= helperConfig.Cost
	table.insert(data.OwnedHelpers, helperId)
	return true
end

BuyUpgradeRemote.OnServerEvent:Connect(function(player, kind, id)
	local data = PlayerData.Get(player.UserId)
	if not data then
		return
	end

	local success = false
	if kind == "ClickUpgrade" then
		success = tryBuyClickUpgrade(data)
	elseif kind == "Skin" and type(id) == "string" then
		success = tryEquipOrBuySkin(player, data, id)
	elseif kind == "Helper" and type(id) == "string" then
		success = tryBuyHelper(data, id)
	end

	if success then
		syncPoints(player, data)
		pushData(player, "Purchase")
	end
end)

SetAudioSettingRemote.OnServerEvent:Connect(function(player, setting, value)
	local data = PlayerData.Get(player.UserId)
	if not data or type(value) ~= "number" then
		return
	end

	if setting == "Music" then
		data.MusicVolume = math.clamp(value, 0, 1)
	elseif setting == "Sfx" then
		data.SfxVolume = math.clamp(value, 0, 1)
	end
end)

task.spawn(function()
	while true do
		task.wait(GameConfig.HelperTickSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerData.Get(player.UserId)
			if data and #data.OwnedHelpers > 0 then
				local total = 0
				for _, helperId in ipairs(data.OwnedHelpers) do
					for _, helper in ipairs(GameConfig.Helpers) do
						if helper.Id == helperId then
							total += helper.PointsPerTick
						end
					end
				end
				if total > 0 then
					data.Points += total
					syncPoints(player, data)
					DataSyncRemote:FireClient(player, data, "HelperTick")
				end
			end
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerData.Save(player.UserId)
	end
end)
