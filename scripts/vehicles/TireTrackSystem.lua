-- Local values: TireTrackSystem_mt
TireTrackSystem = {}
local TireTrackSystem_mt = Class(TireTrackSystem)
TireTrackSystem.maxNumTracks = 512
TireTrackSystem.maxNumSegments = 4096
TireTrackSystem.atlasSize = 32

-- Local values: tireTrackSystem
function TireTrackSystem.onCreateTireTrackSystem(_, id)
	if g_currentMission.tireTrackSystem == nil then
		local v3_ = TireTrackSystem.new()
		if v3_:load(id) then
			g_currentMission.tireTrackSystem = v3_
		else
			v3_:delete()
		end
	else
		return
	end
end

-- Upvalues: TireTrackSystem_mt
-- Local values: self
function TireTrackSystem.new(mt)
	-- upvalues: (copy) TireTrackSystem_mt
	local v5_ = mt or TireTrackSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.tireTrackSystemId = 0
	return v6_
end

function TireTrackSystem:load(id)
	self.tireTrackSystemId = createTyreTrackSystem(getRootNode(), id, TireTrackSystem.maxNumTracks, TireTrackSystem.maxNumSegments, TireTrackSystem.atlasSize, g_terrainNode)
	if g_addTestCommands then
		addConsoleCommand("gsTireTracksRemoveAll", "Remove all tire tracks from terrain", "TireTrackSystem.consoleCommandRemoveAllTireTracks", nil)
		addConsoleCommand("gsTireTracksDebug", "Toggle tire track debug mode with permanently active and colored tracks", "TireTrackSystem.consoleCommandTireTrackDebug", nil)
	end
	return self.tireTrackSystemId ~= 0
end

function TireTrackSystem:delete()
	if self.tireTrackSystemId ~= 0 then
		delete(self.tireTrackSystemId)
	end
	removeConsoleCommand("gsTireTracksRemoveAll")
	removeConsoleCommand("gsTireTracksDebug")
end

function TireTrackSystem:createTrack(width, atlasIndex)
	return createTrack(self.tireTrackSystemId, width, atlasIndex)
end

function TireTrackSystem:destroyTrack(id)
	destroyTrack(self.tireTrackSystemId, id)
end

function TireTrackSystem:addTrackPoint(id, x, y, z, upX, upY, upZ, r, g, b, a, bumpiness, wheelDirection, renderOnTerrainOnly, colorBlendWithTerrain)
	addTrackPoint(self.tireTrackSystemId, id, x, y, z, upX, upY, upZ, r, g, b, a, bumpiness, wheelDirection, renderOnTerrainOnly, colorBlendWithTerrain)
end

function TireTrackSystem:cutTrack(id)
	cutTrack(self.tireTrackSystemId, id)
end

function TireTrackSystem:eraseParallelogram(x0, z0, dx1, dz1, dx2, dz2)
	eraseParallelogram(self.tireTrackSystemId, x0, z0, dx1, dz1, dx2, dz2)
end

function TireTrackSystem:erasePolygon(vertexPositionsXZ)
	erasePolygon(self.tireTrackSystemId, vertexPositionsXZ)
end

-- Local values: halfSize
function TireTrackSystem:consoleCommandRemoveAllTireTracks()
	if g_currentMission.tireTrackSystem ~= nil then
		local v42_ = g_currentMission.terrainSize / 2 + 1
		g_currentMission.tireTrackSystem:eraseParallelogram(-v42_, -v42_, v42_, -v42_, -v42_, v42_)
		executeConsoleCommand("vtRedrawAll")
		return "Removed all tiretracks!"
	end
	printError("Error: no tireTrackSystem found!")
end

-- Local values: newAddTrackPoint
function TireTrackSystem:consoleCommandTireTrackDebug()
	if g_currentMission.tireTrackSystem == nil then
		return "Error: no tireTrackSystem found!"
	elseif self.addTrackPointFuncBackup == nil then
		self.addTrackPointFuncBackup = addTrackPoint
		function addTrackPoint(p44_, p45_, p46_, p47_, p48_, p49_, p50_, p51_, _, _, _, p52_, p53_, p54_, p55_, p56_)
			-- upvalues: (copy) self
			local v57_, v58_, v59_ = DebugUtil.getDebugColor(p45_):unpack()
			self.addTrackPointFuncBackup(p44_, p45_, p46_, p47_, p48_, p49_, p50_, p51_, v57_, v58_, v59_, p52_, p53_, p54_, p55_, p56_)
		end
		return "Enabled TireTrack debug"
	else
		addTrackPoint = self.addTrackPointFuncBackup
		self.addTrackPointFuncBackup = nil
		return "Disabled TireTrack debug"
	end
end
