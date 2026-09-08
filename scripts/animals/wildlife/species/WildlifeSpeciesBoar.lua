-- Local values: WildlifeSpeciesBoar_mt
WildlifeSpeciesBoar = {}
local WildlifeSpeciesBoar_mt = Class(WildlifeSpeciesBoar, WildlifeSpeciesCompanion)

-- Upvalues: WildlifeSpeciesBoar_mt
-- Local values: self
function WildlifeSpeciesBoar.new(customMt)
	-- upvalues: (copy) WildlifeSpeciesBoar_mt
	local v3_ = WildlifeSpeciesCompanion.new(customMt or WildlifeSpeciesBoar_mt)
	v3_.companionAnimalType = CompanionAnimalType.BOAR
	return v3_
end

function WildlifeSpeciesBoar:drawDebug()
	WildlifeSpeciesBoar:superClass().drawDebug(self)
	if self.debugLastX ~= nil then
		DebugUtil.drawDebugCubeAtWorldPos(self.debugLastX, self.debugLastY, self.debugLastZ, 0, 0, 1, 0, 1, 0, 3, 3, 3, 1, 0, 0)
	end
end

-- Local values: spawnDistance, x, z, terrainY, isOnField, fruitTypeIndex, growthState, fruitTypeDesc
function WildlifeSpeciesBoar:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
	if WildlifeSpeciesBoar:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
		local v11_ = MathUtil.randomFloat(self.spawnRadiusMin, self.spawnRadiusMax)
		local v_u_12_, v_u_13_ = WildlifeUtil.calculateRandomSpawnPosition(playerX, playerZ, playerRotY, cameraFovY, v11_)
		local v_u_14_ = getTerrainHeightAtWorldPos(g_terrainNode, v_u_12_, 0, v_u_13_)
		self.debugLastX = v_u_12_
		self.debugLastY = v_u_14_
		self.debugLastZ = v_u_13_
		if FSDensityMapUtil.getIsFieldAtWorldPos(v_u_12_, v_u_13_) then
			local v15_, v16_ = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(v_u_12_, v_u_13_)
			local v17_ = g_fruitTypeManager:getFruitTypeByIndex(v15_)
			if v17_ == nil then
				self:finishSpawning(false)
				return true
			elseif WildlifeSpeciesBoar.defaultHarvestableCheck(v17_, v16_) then
				self:spawnInstances(v_u_12_, v_u_14_, v_u_13_)
				return true
			else
				self:finishSpawning(false)
				return true
			end
		else
			self:runForestCheck(v_u_12_, v_u_14_, v_u_13_, function(p18_)
				-- upvalues: (copy) self, (copy) v_u_12_, (copy) v_u_14_, (copy) v_u_13_
				if p18_ then
					self:spawnInstances(v_u_12_, v_u_14_, v_u_13_)
				else
					self:finishSpawning(false)
				end
			end)
			return true
		end
	else
		return false
	end
end

function WildlifeSpeciesBoar.defaultHarvestableCheck(fruitTypeDesc, growthState)
	local v21_ = fruitTypeDesc:getIsGrowing(growthState) or fruitTypeDesc:getIsHarvestable(growthState)
	if v21_ then
		v21_ = math.random() < 0.6
	end
	return v21_
end
