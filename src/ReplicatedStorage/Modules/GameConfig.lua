-- Shared configuration for the ASMR Clicker game.
-- Used by both server (authoritative logic) and client (UI + local effects).

local GameConfig = {}

GameConfig.StartingPointsPerClick = 1
GameConfig.MaxClicksPerSecond = 12 -- basic server-side anti-exploit throttle
GameConfig.HelperTickSeconds = 4

-- Orb "skins" change the look of a player's orb and the ASMR sound pack
-- used when clicking it. The SoundIds below are built-in Roblox engine
-- sounds (rbxasset://) so the game works immediately with no uploads.
-- Swap them for your own uploaded ASMR SFX (bubble wrap pops, slime
-- squishes, kinetic sand taps, tapping/scratching, etc.) from the
-- Creator Marketplace for a much more authentic ASMR feel.
GameConfig.Skins = {
	{
		Id = "Slime",
		Name = "Slime Orb",
		Cost = 0,
		Color = Color3.fromRGB(150, 224, 172),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.05,
		ClickSounds = {
			"rbxasset://sounds/impact_water.mp3",
			"rbxasset://sounds/snap.mp3",
		},
	},
	{
		Id = "BubbleWrap",
		Name = "Bubble Wrap",
		Cost = 150,
		Color = Color3.fromRGB(210, 230, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.2,
		ClickSounds = {
			"rbxasset://sounds/clickfast.wav",
			"rbxasset://sounds/switch3.wav",
		},
	},
	{
		Id = "KineticSand",
		Name = "Kinetic Sand",
		Cost = 400,
		Color = Color3.fromRGB(235, 197, 145),
		Material = Enum.Material.Sand,
		Transparency = 0,
		ClickSounds = {
			"rbxasset://sounds/step.mp3",
			"rbxasset://sounds/action_footsteps_plastic.mp3",
		},
	},
	{
		Id = "CloudFoam",
		Name = "Cloud Foam",
		Cost = 900,
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.Foil,
		Transparency = 0.1,
		ClickSounds = {
			"rbxasset://sounds/electronicpingshort.wav",
			"rbxasset://sounds/bell.wav",
		},
	},
}

-- Click power upgrades: each level increases points earned per click.
GameConfig.ClickUpgrades = {
	{ Level = 1, Cost = 25,   PointsPerClick = 2 },
	{ Level = 2, Cost = 75,   PointsPerClick = 3 },
	{ Level = 3, Cost = 200,  PointsPerClick = 5 },
	{ Level = 4, Cost = 500,  PointsPerClick = 8 },
	{ Level = 5, Cost = 1200, PointsPerClick = 13 },
	{ Level = 6, Cost = 3000, PointsPerClick = 21 },
}

-- Passive "ASMR helpers" that generate points automatically every
-- GameConfig.HelperTickSeconds and play a soft ambient sound on each tick.
GameConfig.Helpers = {
	{
		Id = "PurringCat",
		Name = "Purring Cat",
		Cost = 50,
		PointsPerTick = 1,
		Sound = "rbxasset://sounds/bell.wav",
	},
	{
		Id = "RainCloud",
		Name = "Rain Cloud",
		Cost = 250,
		PointsPerTick = 4,
		Sound = "rbxasset://sounds/impact_water.mp3",
	},
	{
		Id = "SandTimer",
		Name = "Sand Timer",
		Cost = 800,
		PointsPerTick = 10,
		Sound = "rbxasset://sounds/step.mp3",
	},
	{
		Id = "WindChime",
		Name = "Wind Chime",
		Cost = 2000,
		PointsPerTick = 25,
		Sound = "rbxasset://sounds/electronicpingshort.wav",
	},
}

-- Calm looping background track. Replace with a lofi/ASMR ambient track id.
GameConfig.AmbientMusic = "rbxasset://sounds/impact_water.mp3"

return GameConfig
