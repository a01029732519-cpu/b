-- Local (client-only) visual + audio feedback played the instant a
-- player clicks their orb, before the server round-trip confirms points.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Effects = {}

local baseSizes = {} -- [orb] = original Size, cached so repeated squishes don't drift

function Effects.PlayClickFeedback(orb, skin, sfxVolume)
	if not orb or not orb.Parent then
		return
	end

	local originalSize = baseSizes[orb]
	if not originalSize then
		originalSize = orb.Size
		baseSizes[orb] = originalSize
	end

	-- squish on impact, then bounce back with a soft elastic ease
	local squish = TweenService:Create(
		orb,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = originalSize * 0.85 }
	)
	local bounce = TweenService:Create(
		orb,
		TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{ Size = originalSize }
	)
	squish:Play()
	squish.Completed:Once(function()
		bounce:Play()
	end)

	-- soft expanding ripple ring
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 6, 6)
	ring.CFrame = orb.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = orb.Color
	ring.Transparency = 0.3
	ring.Parent = workspace

	local ringTween = TweenService:Create(
		ring,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.2, 14, 14), Transparency = 1 }
	)
	ringTween:Play()
	Debris:AddItem(ring, 0.5)

	-- pop / squish sound picked randomly from the equipped skin's ASMR pack,
	-- with a touch of pitch variation so it never feels too repetitive
	if skin and skin.ClickSounds and #skin.ClickSounds > 0 then
		local soundId = skin.ClickSounds[math.random(1, #skin.ClickSounds)]
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = sfxVolume or 0.6
		sound.PlaybackSpeed = 0.92 + math.random() * 0.16
		sound.Parent = orb
		sound:Play()
		Debris:AddItem(sound, 2)
	end
end

return Effects
