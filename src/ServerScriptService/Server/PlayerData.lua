-- Handles loading, caching and saving each player's persistent data.

local DataStoreService = game:GetService("DataStoreService")
local Store = DataStoreService:GetDataStore("ASMRClicker_v1")

local PlayerData = {}
local cache = {}

local DEFAULT_DATA = {
	Points = 0,
	ClickLevel = 0, -- how many entries of GameConfig.ClickUpgrades have been purchased
	EquippedSkin = "Slime",
	OwnedSkins = { "Slime" },
	OwnedHelpers = {},
	MusicVolume = 0.4,
	SfxVolume = 0.6,
}

local function deepCopy(t)
	local copy = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

function PlayerData.Load(userId)
	local data
	local ok, err = pcall(function()
		data = Store:GetAsync("Player_" .. userId)
	end)
	if not ok then
		warn("[PlayerData] Failed to load for", userId, err)
	end

	if not data then
		data = deepCopy(DEFAULT_DATA)
	else
		-- backfill any fields added since this player's last save
		for key, value in pairs(DEFAULT_DATA) do
			if data[key] == nil then
				data[key] = deepCopy(value)
			end
		end
	end

	cache[userId] = data
	return data
end

function PlayerData.Get(userId)
	return cache[userId]
end

function PlayerData.Save(userId)
	local data = cache[userId]
	if not data then
		return
	end
	local ok, err = pcall(function()
		Store:SetAsync("Player_" .. userId, data)
	end)
	if not ok then
		warn("[PlayerData] Failed to save for", userId, err)
	end
end

function PlayerData.Release(userId)
	cache[userId] = nil
end

return PlayerData
