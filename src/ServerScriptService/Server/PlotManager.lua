-- Assigns/releases numbered plot slots for players so leaving players
-- free up their slot for the next joiner instead of growing forever.

local PlotManager = {}

local usedPlots = {}
local nextIndex = 1

function PlotManager.Assign()
	for i = 1, nextIndex - 1 do
		if not usedPlots[i] then
			usedPlots[i] = true
			return i
		end
	end
	local index = nextIndex
	usedPlots[index] = true
	nextIndex += 1
	return index
end

function PlotManager.Release(index)
	usedPlots[index] = nil
end

return PlotManager
