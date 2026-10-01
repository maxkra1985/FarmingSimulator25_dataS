WildlifeSpeciesDeer = {}
local WildlifeSpeciesDeer_mt = Class(WildlifeSpeciesDeer, WildlifeSpeciesCompanion)
function WildlifeSpeciesDeer.new(customMt)
	local self = WildlifeSpeciesCompanion.new(customMt or WildlifeSpeciesDeer_mt)
	self.companionAnimalType = CompanionAnimalType.DEER
	return self
end
function WildlifeSpeciesDeer:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
	if not WildlifeSpeciesDeer:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
		return false
	else
		local spawnDistance = MathUtil.randomFloat(self.spawnRadiusMin, self.spawnRadiusMax)
		local x, z = WildlifeUtil.calculateRandomSpawnPosition(playerX, playerZ, playerRotY, cameraFovY, spawnDistance)
		local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		self:runForestCheck(x, terrainY, z, function(isForest)
			if isForest then
				self:spawnInstances(x, terrainY, z)
			else
				self:finishSpawning(false)
			end
		end)
		return true
	end
end
