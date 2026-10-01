PrecisionFarmingDebug = {}
PrecisionFarmingDebug.MOD_NAME = g_currentModName
local PrecisionFarmingDebug_mt = Class(PrecisionFarmingDebug)
function PrecisionFarmingDebug.new(precisionFarming, customMt)
	local self = setmetatable({}, customMt or PrecisionFarmingDebug_mt)
	self.precisionFarming = precisionFarming
	addConsoleCommand("pfToggleGroundDebug", "Enables debug display of ground data", "toggleGroundDebug", self)
	return self
end
function PrecisionFarmingDebug:delete()
	removeConsoleCommand("pfToggleGroundDebug")
end
function PrecisionFarmingDebug:toggleGroundDebug()
	if self.groundDebugArea == nil then
		local nitrogenMap = self.precisionFarming.nitrogenMap
		local coverMap = self.precisionFarming.coverMap
		local pHMap = self.precisionFarming.pHMap
		local data = {}
		self.groundDebugArea = DebugBitVectorMap.newSimple(20, 2, false, 0.01, 0.1)
		self.groundDebugArea:createWithCustomFunc(function(_, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			local centerX = (startWorldX + widthWorldX) * 0.5
			local centerZ = (startWorldZ + heightWorldZ) * 0.5
			centerX, centerZ = ValueMap.roundToPixelCenter(centerX, centerZ, g_terrainSize, coverMap.sizeX)
			data.valid = coverMap:getIsUncoveredAtPos(centerX, centerZ, true)
			if data.valid then
				data.nLevel = nitrogenMap:getLevelAtWorldPos(centerX, centerZ)
				data.nLevelLocked = nitrogenMap:getIsLockedAtWorldPos(centerX, centerZ, SprayType.FERTILIZER)
				data.nOffsetIsLocked, data.nOffset = nitrogenMap:getNOffsetDataAtWorldPos(centerX, centerZ)
				data.phLevel = pHMap:getLevelAtWorldPos(centerX, centerZ)
				data.phLevelLocked = pHMap:getIsLockedAtWorldPos(centerX, centerZ, SprayType.LIME)
				data.coverValue = coverMap:getLevelAtWorldPos(centerX, centerZ)
				data.curSprayType = g_currentMission.fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.SPRAY_TYPE, centerX, 0, centerZ)
				if -g_terrainSize * 0.5 - 0.01 < startWorldX and (startWorldX < g_terrainSize * 0.5 - 0.01 and (-g_terrainSize * 0.5 - 0.01 < startWorldZ and startWorldZ < g_terrainSize * 0.5 - 0.01)) then
					startWorldX = startWorldX + 0.05
					startWorldZ = startWorldZ + 0.05
					widthWorldX = widthWorldX - 0.05
					widthWorldZ = widthWorldZ + 0.05
					heightWorldX = heightWorldX + 0.05
					heightWorldZ = heightWorldZ - 0.05
					DebugPlane.renderWithPositions(startWorldX, 0, startWorldZ, widthWorldX, 0, widthWorldZ, heightWorldX, 0, heightWorldZ, nil, true, false, false, false)
					local centerY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, centerX, 0, centerZ)
					drawDebugPoint(centerX, centerY, centerZ, 0, 1, 0, 1, false)
				end
			end
			return 1, 0
		end)
		self.groundDebugArea:setAdditionalDrawInfoFunc(function(_, x, z, area, totalArea)
			if data.valid then
				local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
				local nLevelReal = nitrogenMap:getNitrogenValueFromInternalValue(data.nLevel)
				local phLevelReal = pHMap:getPhValueFromInternalValue(data.phLevel)
				Utils.renderTextAtWorldPosition(x, y, z, string.format("N: %dkg %s(off: %d%s)\npH: %.3f %s\ncoverValue %d\n sprayType: %d", nLevelReal, data.nLevelLocked and "L " or "", data.nOffset, data.nOffsetIsLocked and " locked" or "", phLevelReal, data.phLevelLocked and "L " or "", data.coverValue, data.curSprayType), getCorrectTextSize(0.01), 0)
			end
		end)
		g_debugManager:addElement(self.groundDebugArea)
	else
		g_debugManager:removeElement(self.groundDebugArea)
		self.groundDebugArea = nil
	end
end
