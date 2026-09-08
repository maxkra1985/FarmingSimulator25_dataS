-- Local values: PrecisionFarmingDebug_mt
PrecisionFarmingDebug = {}
PrecisionFarmingDebug.MOD_NAME = g_currentModName
local PrecisionFarmingDebug_mt = Class(PrecisionFarmingDebug)

-- Upvalues: PrecisionFarmingDebug_mt
-- Local values: self
function PrecisionFarmingDebug.new(precisionFarming, customMt)
	-- upvalues: (copy) PrecisionFarmingDebug_mt
	local v4_ = customMt or PrecisionFarmingDebug_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	addConsoleCommand("pfToggleGroundDebug", "Enables debug display of ground data", "toggleGroundDebug", v5_)
	return v5_
end

function PrecisionFarmingDebug:delete()
	removeConsoleCommand("pfToggleGroundDebug")
end

-- Local values: nitrogenMap, coverMap, pHMap, data
function PrecisionFarmingDebug:toggleGroundDebug()
	if self.groundDebugArea == nil then
		local v_u_7_ = self.precisionFarming.nitrogenMap
		local v_u_8_ = self.precisionFarming.coverMap
		local v_u_9_ = self.precisionFarming.pHMap
		local v_u_10_ = {}
		self.groundDebugArea = DebugBitVectorMap.newSimple(20, 2, false, 0.01, 0.1)
		self.groundDebugArea:createWithCustomFunc(function(_, p11_, p12_, p13_, p14_, p15_, p16_)
			-- upvalues: (copy) v_u_8_, (copy) v_u_10_, (copy) v_u_7_, (copy) v_u_9_
			local v17_ = (p11_ + p13_) * 0.5
			local v18_ = (p12_ + p16_) * 0.5
			local v19_, v20_ = ValueMap.roundToPixelCenter(v17_, v18_, g_terrainSize, v_u_8_.sizeX)
			v_u_10_.valid = v_u_8_:getIsUncoveredAtPos(v19_, v20_, true)
			if v_u_10_.valid then
				v_u_10_.nLevel = v_u_7_:getLevelAtWorldPos(v19_, v20_)
				v_u_10_.nLevelLocked = v_u_7_:getIsLockedAtWorldPos(v19_, v20_, SprayType.FERTILIZER)
				local v21_ = v_u_10_
				local v22_ = v_u_10_
				local v23_, v24_ = v_u_7_:getNOffsetDataAtWorldPos(v19_, v20_)
				v21_.nOffsetIsLocked = v23_
				v22_.nOffset = v24_
				v_u_10_.phLevel = v_u_9_:getLevelAtWorldPos(v19_, v20_)
				v_u_10_.phLevelLocked = v_u_9_:getIsLockedAtWorldPos(v19_, v20_, SprayType.LIME)
				v_u_10_.coverValue = v_u_8_:getLevelAtWorldPos(v19_, v20_)
				v_u_10_.curSprayType = g_currentMission.fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.SPRAY_TYPE, v19_, 0, v20_)
				if -g_terrainSize * 0.5 - 0.01 < p11_ and (p11_ < g_terrainSize * 0.5 - 0.01 and (-g_terrainSize * 0.5 - 0.01 < p12_ and p12_ < g_terrainSize * 0.5 - 0.01)) then
					local v25_ = p11_ + 0.05
					local v26_ = p12_ + 0.05
					local v27_ = p13_ - 0.05
					local v28_ = p14_ + 0.05
					local v29_ = p15_ + 0.05
					local v30_ = p16_ - 0.05
					DebugPlane.renderWithPositions(v25_, 0, v26_, v27_, 0, v28_, v29_, 0, v30_, nil, true, false, false, false)
					local v31_ = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, v19_, 0, v20_)
					drawDebugPoint(v19_, v31_, v20_, 0, 1, 0, 1, false)
				end
			end
			return 1, 0
		end)
		self.groundDebugArea:setAdditionalDrawInfoFunc(function(_, p32_, p33_, _, _)
			-- upvalues: (copy) v_u_10_, (copy) v_u_7_, (copy) v_u_9_
			if v_u_10_.valid then
				local v34_ = getTerrainHeightAtWorldPos(g_terrainNode, p32_, 0, p33_) + 0.1
				local v35_ = v_u_7_:getNitrogenValueFromInternalValue(v_u_10_.nLevel)
				local v36_ = v_u_9_:getPhValueFromInternalValue(v_u_10_.phLevel)
				Utils.renderTextAtWorldPosition(p32_, v34_, p33_, string.format("N: %dkg %s(off: %d%s)\npH: %.3f %s\ncoverValue %d\n sprayType: %d", v35_, v_u_10_.nLevelLocked and "L " or "", v_u_10_.nOffset, v_u_10_.nOffsetIsLocked and " locked" or "", v36_, v_u_10_.phLevelLocked and "L " or "", v_u_10_.coverValue, v_u_10_.curSprayType), getCorrectTextSize(0.01), 0)
			end
		end)
		g_debugManager:addElement(self.groundDebugArea)
	else
		g_debugManager:removeElement(self.groundDebugArea)
		self.groundDebugArea = nil
	end
end
