PrecisionFarmingStatistic = {}
PrecisionFarmingStatistic.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".precisionFarmingStatistic"

function PrecisionFarmingStatistic.prerequisitesPresent(vehicleType)
	return true
end

function PrecisionFarmingStatistic.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getPFStatisticInfo", PrecisionFarmingStatistic.getPFStatisticInfo)
	SpecializationUtil.registerFunction(vehicleType, "updatePFStatistic", PrecisionFarmingStatistic.updatePFStatistic)
	SpecializationUtil.registerFunction(vehicleType, "getPFYieldMap", PrecisionFarmingStatistic.getPFYieldMap)
end

function PrecisionFarmingStatistic.registerOverwrittenFunctions(vehicleType) end

function PrecisionFarmingStatistic.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PrecisionFarmingStatistic)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", PrecisionFarmingStatistic)
end

-- Local values: spec
function PrecisionFarmingStatistic:onLoad(savegame)
	local v4_ = self[PrecisionFarmingStatistic.SPEC_TABLE_NAME]
	if g_precisionFarming ~= nil then
		v4_.soilMap = g_precisionFarming.soilMap
		v4_.phMap = g_precisionFarming.phMap
		v4_.yieldMap = g_precisionFarming.yieldMap
		v4_.farmlandStatistics = g_precisionFarming.farmlandStatistics
	end
	v4_.isOnField = false
	v4_.isOnFieldSmoothed = false
	v4_.isOnFieldLastPos = { 0, 0 }
	v4_.farmlandId = 0
	v4_.farmlandAccess = false
	v4_.mission = nil
	v4_.lastUpdateDistance = 0
	v4_.updateDistance = 0.5
end

-- Local values: spec, x, _, z, landOwner, isOnField, distance
function PrecisionFarmingStatistic:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v6_ = self[PrecisionFarmingStatistic.SPEC_TABLE_NAME]
	v6_.lastUpdateDistance = v6_.lastUpdateDistance + self.lastMovedDistance
	if v6_.lastUpdateDistance > v6_.updateDistance or v6_.farmlandId == 0 then
		v6_.lastUpdateDistance = 0
		local v7_, _, v8_ = getWorldTranslation(self.rootNode)
		v6_.farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(v7_, v8_)
		if v6_.farmlandId == 0 then
			v6_.farmlandAccess = false
		else
			local v9_ = g_farmlandManager:getFarmlandOwner(v6_.farmlandId)
			local v10_
			if v9_ == 0 then
				v10_ = false
			else
				v10_ = g_currentMission.accessHandler:canFarmAccessOtherId(self:getActiveFarm(), v9_)
			end
			v6_.farmlandAccess = v10_
		end
		v6_.mission = g_missionManager:getMissionAtWorldPosition(v7_, v8_)
		local v11_ = self.isOnField
		if v11_ ~= v6_.isOnField then
			if v11_ then
				v6_.isOnFieldSmoothed = true
			else
				v6_.isOnFieldLastPos[1] = v7_
				v6_.isOnFieldLastPos[2] = v8_
			end
		end
		if v6_.isOnFieldSmoothed ~= v11_ and MathUtil.vector2Length(v7_ - v6_.isOnFieldLastPos[1], v8_ - v6_.isOnFieldLastPos[2]) > 20 then
			v6_.isOnFieldSmoothed = v11_
		end
		v6_.isOnField = v11_
	end
end

-- Local values: spec
function PrecisionFarmingStatistic:getPFStatisticInfo()
	local v13_ = self[PrecisionFarmingStatistic.SPEC_TABLE_NAME]
	return v13_.farmlandStatistics, v13_.isOnField, v13_.farmlandId, v13_.isOnFieldSmoothed, v13_.mission
end

-- Local values: spec
function PrecisionFarmingStatistic:updatePFStatistic(name, value)
	local v17_ = self[PrecisionFarmingStatistic.SPEC_TABLE_NAME]
	if v17_.farmlandStatistics ~= nil and (v17_.farmlandId ~= nil and (v17_.farmlandAccess and v17_.mission == nil)) then
		v17_.farmlandStatistics:updateStatistic(v17_.farmlandId, name, value)
	end
end

-- Local values: spec
function PrecisionFarmingStatistic:getPFYieldMap()
	return self[PrecisionFarmingStatistic.SPEC_TABLE_NAME].yieldMap
end
