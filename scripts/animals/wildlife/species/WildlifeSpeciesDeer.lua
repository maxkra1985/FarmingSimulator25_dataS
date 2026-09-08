-- Local values: WildlifeSpeciesDeer_mt
WildlifeSpeciesDeer = {}
local WildlifeSpeciesDeer_mt = Class(WildlifeSpeciesDeer, WildlifeSpeciesCompanion)

-- Upvalues: WildlifeSpeciesDeer_mt
-- Local values: self
function WildlifeSpeciesDeer.new(customMt)
	-- upvalues: (copy) WildlifeSpeciesDeer_mt
	local v3_ = WildlifeSpeciesCompanion.new(customMt or WildlifeSpeciesDeer_mt)
	v3_.companionAnimalType = CompanionAnimalType.DEER
	return v3_
end

-- Local values: spawnDistance, x, z, terrainY
function WildlifeSpeciesDeer:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
	if not WildlifeSpeciesDeer:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
		return false
	end
	local v10_ = MathUtil.randomFloat(self.spawnRadiusMin, self.spawnRadiusMax)
	local v_u_11_, v_u_12_ = WildlifeUtil.calculateRandomSpawnPosition(playerX, playerZ, playerRotY, cameraFovY, v10_)
	local v_u_13_ = getTerrainHeightAtWorldPos(g_terrainNode, v_u_11_, 0, v_u_12_)
	self:runForestCheck(v_u_11_, v_u_13_, v_u_12_, function(p14_)
		-- upvalues: (copy) self, (copy) v_u_11_, (copy) v_u_13_, (copy) v_u_12_
		if p14_ then
			self:spawnInstances(v_u_11_, v_u_13_, v_u_12_)
		else
			self:finishSpawning(false)
		end
	end)
	return true
end
