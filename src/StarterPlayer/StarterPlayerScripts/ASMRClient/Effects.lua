-- Local (client-only) visual + audio feedback played the instant a
-- player clicks something, before the server round-trip confirms points.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Effects = {}

local baseSizes = {} -- [orb] = original Size, cached so repeated squishes don't drift

-- Matches OrbService.SetBumpPopped's push-down depth so the client's instant
-- prediction lines up with the server's authoritative position when it
-- replicates a moment later (no visible snap/correction).
local BUMP_POP_DEPTH_FACTOR = 0.65

local function playRandomSound(parent, skin, sfxVolume, soundIdOverride)
	local soundId = soundIdOverride
	if not soundId and skin and skin.ClickSounds and #skin.ClickSounds > 0 then
		soundId = skin.ClickSounds[math.random(1, #skin.ClickSounds)]
	end
	if not soundId then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = sfxVolume or 0.6
	sound.PlaybackSpeed = 0.92 + math.random() * 0.16
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function spawnRing(cframe, color, startSize, endSize, duration)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = startSize
	ring.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.3
	ring.Parent = workspace

	local ringTween = TweenService:Create(
		ring,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = endSize, Transparency = 1 }
	)
	ringTween:Play()
	Debris:AddItem(ring, duration + 0.1)
end

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

	spawnRing(orb.CFrame, orb.Color, Vector3.new(0.2, 6, 6), Vector3.new(0.2, 14, 14), 0.4)
	playRandomSound(orb, skin, sfxVolume)
end

-- Presses a single pop-it bump down and darkens it, matching the server's
-- authoritative OrbService.SetBumpPopped so the later replication update
-- doesn't visibly correct/snap the bump.
function Effects.PlayBumpPop(bump, skin, sfxVolume)
	if not bump or not bump.Parent then
		return
	end
	if bump:GetAttribute("Popped") then
		return -- already popped locally, don't double-animate
	end
	bump:SetAttribute("Popped", true)

	local originalY = bump:GetAttribute("OriginalY") or bump.Position.Y
	local rowColor = Color3.new(
		bump:GetAttribute("RowColorR") or bump.Color.R,
		bump:GetAttribute("RowColorG") or bump.Color.G,
		bump:GetAttribute("RowColorB") or bump.Color.B
	)
	local poppedColor = rowColor:Lerp(Color3.new(0, 0, 0), 0.35)
	local poppedY = originalY - bump.Size.Y * BUMP_POP_DEPTH_FACTOR

	local pressTween = TweenService:Create(
		bump,
		TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = Vector3.new(bump.Position.X, poppedY, bump.Position.Z), Transparency = 0.15 }
	)
	pressTween:Play()
	bump.Color = poppedColor

	spawnRing(bump.CFrame, rowColor, Vector3.new(0.15, 2, 2), Vector3.new(0.15, 5, 5), 0.25)
	playRandomSound(bump, skin, sfxVolume)
end

-- Big celebratory burst played when every bump on a board has been popped
-- and the board is about to reset (the "climax" moment of the pop-it loop).
function Effects.PlayBoardClear(board, skin, sfxVolume)
	if not board or not board.Parent then
		return
	end
	local tray = board:FindFirstChild("Tray")
	if not tray then
		return
	end

	spawnRing(tray.CFrame, Color3.fromRGB(255, 255, 255), Vector3.new(0.2, 4, 4), Vector3.new(0.2, 30, 30), 0.6)

	local flash = TweenService:Create(
		tray,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{ Color = Color3.fromRGB(255, 245, 200) }
	)
	flash:Play()

	local clearSoundId = skin and skin.ClearSound
	playRandomSound(tray, skin, (sfxVolume or 0.6) + 0.1, clearSoundId)
end

return Effects
