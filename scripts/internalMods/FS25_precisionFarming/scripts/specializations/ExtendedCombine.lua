ExtendedCombine = {}
ExtendedCombine.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedCombine"
ExtendedCombine.YIELD_NUM_BITS = 11
ExtendedCombine.YIELD_MAX_VALUE = 2 ^ ExtendedCombine.YIELD_NUM_BITS - 1
ExtendedCombine.YIELD_PCT_NUM_BITS = 7
ExtendedCombine.YIELD_PCT_MAX_VALUE = 2 ^ ExtendedCombine.YIELD_PCT_NUM_BITS - 1
source(g_currentModDirectory .. "scripts/hud/ExtendedCombineHUDExtension.lua")

function ExtendedCombine.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Combine, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
	end
	return v2_
end

function ExtendedCombine.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setLastYieldValues", ExtendedCombine.setLastYieldValues)
end

function ExtendedCombine.registerOverwrittenFunctions(vehicleType) end

function ExtendedCombine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedCombine)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedCombine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ExtendedCombine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ExtendedCombine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedCombine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExtendedCombine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedCombine)
end

-- Local values: spec
function ExtendedCombine:onLoad(savegame)
	local v6_ = self[ExtendedCombine.SPEC_TABLE_NAME]
	v6_.lastYieldWeight = 0
	v6_.lastYieldPercentage = 0
	v6_.lastYieldPotential = 0
	v6_.usageValuesDirtyFlag = self:getNextDirtyFlag()
	v6_.hudExtension = ExtendedCombineHUDExtension.new(self)
end

-- Local values: spec
function ExtendedCombine:onDelete()
	local v8_ = self[ExtendedCombine.SPEC_TABLE_NAME]
	if v8_.hudExtension ~= nil then
		v8_.hudExtension:delete()
	end
end

-- Local values: spec
function ExtendedCombine:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v12_ = self[ExtendedCombine.SPEC_TABLE_NAME]
		if streamReadBool(streamId) then
			v12_.lastYieldWeight = streamReadUIntN(streamId, ExtendedCombine.YIELD_NUM_BITS) / 10
			v12_.lastYieldPercentage = streamReadUIntN(streamId, ExtendedCombine.YIELD_PCT_NUM_BITS)
			v12_.lastYieldPotential = streamReadUIntN(streamId, ExtendedCombine.YIELD_PCT_NUM_BITS)
		end
	end
end

-- Local values: spec
function ExtendedCombine:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v17_ = self[ExtendedCombine.SPEC_TABLE_NAME]
		local v18_ = streamWriteBool
		local v19_ = v17_.usageValuesDirtyFlag
		if v18_(streamId, bit32.band(dirtyMask, v19_) ~= 0) then
			local v20_ = streamWriteUIntN
			local v21_ = v17_.lastYieldWeight * 10
			local v22_ = math.floor(v21_)
			local v23_ = ExtendedCombine.YIELD_MAX_VALUE
			v20_(streamId, math.min(v22_, v23_), ExtendedCombine.YIELD_NUM_BITS)
			local v24_ = streamWriteUIntN
			local v25_ = v17_.lastYieldPercentage
			local v26_ = math.floor(v25_)
			local v27_ = ExtendedCombine.YIELD_PCT_MAX_VALUE
			v24_(streamId, math.min(v26_, v27_), ExtendedCombine.YIELD_PCT_NUM_BITS)
			local v28_ = streamWriteUIntN
			local v29_ = v17_.lastYieldPotential
			local v30_ = math.floor(v29_)
			local v31_ = ExtendedCombine.YIELD_PCT_MAX_VALUE
			v28_(streamId, math.min(v30_, v31_), ExtendedCombine.YIELD_PCT_NUM_BITS)
		end
	end
end

-- Local values: spec, hud
function ExtendedCombine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v33_ = self[ExtendedCombine.SPEC_TABLE_NAME]
	if self.isActiveForInputIgnoreSelectionIgnoreAI and v33_.hudExtension ~= nil then
		g_currentMission.hud:addHelpExtension(v33_.hudExtension)
	end
end

function ExtendedCombine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient and self.isActiveForInputIgnoreSelectionIgnoreAI then
		ExtendedCombine.updateMinimapActiveState(self)
	end
end

function ExtendedCombine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		if isActiveForInputIgnoreSelection then
			ExtendedCombine.updateMinimapActiveState(self)
			return
		end
		ExtendedCombine.updateMinimapActiveState(self, false)
	end
end

-- Local values: yieldMap, isActive, _, _, _, isOnField, mission
function ExtendedCombine:updateMinimapActiveState(forcedState)
	local v39_ = self:getPFYieldMap()
	if v39_ ~= nil then
		if forcedState == nil then
			local v40_, v41_, v42_, v43_
			v40_, v41_, v42_, forcedState, v43_ = self:getPFStatisticInfo()
			if forcedState then
				if self.spec_combine.numAttachedCutters > 0 then
					forcedState = v43_ == nil
				else
					forcedState = false
				end
			end
		end
		v39_:setRequireMinimapDisplay(forcedState, self, self:getIsSelected())
	end
end

-- Local values: spec
function ExtendedCombine:setLastYieldValues(lastYieldWeight, lastYieldPercentage, lastYieldPotential)
	local v48_ = self[ExtendedCombine.SPEC_TABLE_NAME]
	if lastYieldWeight ~= v48_.lastYieldWeight or (lastYieldPercentage ~= v48_.lastYieldPercentage or lastYieldPotential ~= v48_.lastYieldPotential) then
		v48_.lastYieldWeight = lastYieldWeight
		v48_.lastYieldPercentage = lastYieldPercentage
		v48_.lastYieldPotential = lastYieldPotential
		self:raiseDirtyFlags(v48_.usageValuesDirtyFlag)
	end
end
