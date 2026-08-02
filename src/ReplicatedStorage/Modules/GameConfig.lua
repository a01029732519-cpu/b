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
-- ModelType selects which OrbService builder renders the skin:
--   nil / "Ball"    -> plain clickable sphere (buildBallModel)
--   "StressBall"    -> ball + a cute pressed-on face (buildStressBallModel)
--   "SaltedButter"  -> wrapped butter block (buildSaltedButterModel)
--   "ChocoPopsicle" -> popsicle with a crumb-burst "bite" click effect
--   "BubbleWrap"    -> rainbow pop-it grid, multi-target combo (see GameConfig.BubbleWrapGrid)
--   "ABCBlocks"     -> stacked letter-block tower, multi-target combo (see GameConfig.ABCBlocksStack)
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
		Id = "StressBall",
		Name = "Squishy Stress Ball",
		Cost = 60,
		ModelType = "StressBall",
		Color = Color3.fromRGB(255, 197, 110),
		Material = Enum.Material.Plastic,
		Transparency = 0,
		ClickSounds = {
			"rbxasset://sounds/switch3.wav",
			"rbxasset://sounds/snap.mp3",
		},
	},
	{
		Id = "BubbleWrap",
		Name = "Bubble Wrap",
		Cost = 150,
		-- BubbleWrap renders as a real pop-it grid (see GameConfig.BubbleWrapGrid)
		-- instead of a plain ball. Every other skin defaults to "Ball".
		ModelType = "BubbleWrap",
		Color = Color3.fromRGB(210, 230, 255),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
		ClickSounds = {
			"rbxasset://sounds/clickfast.wav",
			"rbxasset://sounds/switch3.wav",
		},
		ClearSound = "rbxasset://sounds/bell.wav",
	},
	{
		Id = "SaltedButter",
		Name = "Salted Butter",
		Cost = 350,
		ModelType = "SaltedButter",
		Color = Color3.fromRGB(255, 232, 163),
		Material = Enum.Material.SmoothPlastic,
		BandColor = Color3.fromRGB(196, 140, 70),
		Transparency = 0,
		ClickSounds = {
			"rbxasset://sounds/step.mp3",
			"rbxasset://sounds/action_footsteps_plastic.mp3",
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
		Id = "SoapBubble",
		Name = "Soap Bubble",
		Cost = 600,
		-- plain Ball model, just glassy + translucent
		Color = Color3.fromRGB(214, 233, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.45,
		ClickSounds = {
			"rbxasset://sounds/electronicpingshort.wav",
			"rbxasset://sounds/bell.wav",
		},
	},
	{
		Id = "ABCBlocks",
		Name = "ABC Blocks",
		Cost = 850,
		ModelType = "ABCBlocks",
		Color = Color3.fromRGB(255, 209, 128),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
		ClickSounds = {
			"rbxasset://sounds/clickfast.wav",
			"rbxasset://sounds/switch3.wav",
		},
		ClearSound = "rbxasset://sounds/bell.wav",
	},
	{
		Id = "ChocoPopsicle",
		Name = "Choco Popsicle",
		Cost = 1100,
		ModelType = "ChocoPopsicle",
		Color = Color3.fromRGB(91, 58, 34),
		Material = Enum.Material.SmoothPlastic,
		StickColor = Color3.fromRGB(232, 201, 155),
		Transparency = 0,
		ClickSounds = {
			"rbxasset://sounds/snap.mp3",
			"rbxasset://sounds/step.mp3",
		},
	},
	{
		Id = "CloudFoam",
		Name = "Cloud Foam",
		Cost = 1400,
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.Foil,
		Transparency = 0.1,
		ClickSounds = {
			"rbxasset://sounds/electronicpingshort.wav",
			"rbxasset://sounds/bell.wav",
		},
	},
}

-- Layout + rainbow row colors for the BubbleWrap pop-it grid model
-- (inspired by the rainbow pop-it ramps from the reference ASMR tower
-- footage). Rows run front-to-back, each row is one color band.
GameConfig.BubbleWrapGrid = {
	Rows = 4,
	Columns = 6,
	TraySize = Vector3.new(22, 1, 14),
	BumpSize = Vector3.new(2.6, 1.4, 2.6),
	RowColors = {
		Color3.fromRGB(255, 99, 99),
		Color3.fromRGB(255, 178, 102),
		Color3.fromRGB(255, 241, 118),
		Color3.fromRGB(129, 212, 129),
	},
	-- bonus points multiplier applied to (points-per-click * bump count)
	-- when a player pops every bump and the board resets
	ClearBonusMultiplier = 0.5,
}

-- Stacked letter-block tower (ABCBlocks skin): a smaller multi-target combo
-- than BubbleWrap, so each block is worth a bigger bonus share when cleared.
GameConfig.ABCBlocksStack = {
	Letters = { "A", "B", "C" },
	BlockSize = Vector3.new(3.4, 3.4, 3.4),
	Gap = 0.4,
	RowColors = {
		Color3.fromRGB(255, 209, 128),
		Color3.fromRGB(178, 223, 255),
		Color3.fromRGB(255, 176, 214),
	},
	ClearBonusMultiplier = 1.5,
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
