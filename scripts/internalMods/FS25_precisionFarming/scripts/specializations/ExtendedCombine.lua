ExtendedCombine = {}
ExtendedCombine.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedCombine"
ExtendedCombine.YIELD_NUM_BITS = 11
ExtendedCombine.YIELD_MAX_VALUE = 2 ^ ExtendedCombine.YIELD_NUM_BITS - 1
ExtendedCombine.YIELD_PCT_NUM_BITS = 7
ExtendedCombine.YIELD_PCT_MAX_VALUE = 2 ^ ExtendedCombine.YIELD_PCT_NUM_BITS - 1
source(g_currentModDirectory .. "scripts/hud/ExtendedCombineHUDExtension.lua")
function ExtendedCombine.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Combine, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
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
function ExtendedCombine:onLoad(savegame)
	local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
	spec.lastYieldWeight = 0
	spec.lastYieldPercentage = 0
	spec.lastYieldPotential = 0
	spec.usageValuesDirtyFlag = self:getNextDirtyFlag()
	spec.hudExtension = ExtendedCombineHUDExtension.new(self)
end
function ExtendedCombine:onDelete()
	local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
	if spec.hudExtension ~= nil then
		spec.hudExtension:delete()
	end
end
function ExtendedCombine:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
		if streamReadBool(streamId) then
			spec.lastYieldWeight = streamReadUIntN(streamId, ExtendedCombine.YIELD_NUM_BITS) / 10
			spec.lastYieldPercentage = streamReadUIntN(streamId, ExtendedCombine.YIELD_PCT_NUM_BITS)
			spec.lastYieldPotential = streamReadUIntN(streamId, ExtendedCombine.YIELD_PCT_NUM_BITS)
		end
	end
end
function ExtendedCombine:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
		if streamWriteBool(streamId, bit32.band(dirtyMask, spec.usageValuesDirtyFlag) ~= 0) then
			streamWriteUIntN(streamId, math.min(math.floor(spec.lastYieldWeight * 10), ExtendedCombine.YIELD_MAX_VALUE), ExtendedCombine.YIELD_NUM_BITS)
			streamWriteUIntN(streamId, math.min(math.floor(spec.lastYieldPercentage), ExtendedCombine.YIELD_PCT_MAX_VALUE), ExtendedCombine.YIELD_PCT_NUM_BITS)
			streamWriteUIntN(streamId, math.min(math.floor(spec.lastYieldPotential), ExtendedCombine.YIELD_PCT_MAX_VALUE), ExtendedCombine.YIELD_PCT_NUM_BITS)
		end
	end
end
function ExtendedCombine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
	if self.isActiveForInputIgnoreSelectionIgnoreAI and spec.hudExtension ~= nil then
		local hud = g_currentMission.hud
		hud:addHelpExtension(spec.hudExtension)
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
function ExtendedCombine:updateMinimapActiveState(forcedState)
	local yieldMap = self:getPFYieldMap()
	if yieldMap ~= nil then
		local isActive = forcedState
		if isActive == nil then
			local _, _, _, isOnField, mission = self:getPFStatisticInfo()
			isActive = isOnField and 0 < self.spec_combine.numAttachedCutters and mission == nil
		end
		yieldMap:setRequireMinimapDisplay(isActive, self, self:getIsSelected())
	end
end
function ExtendedCombine:setLastYieldValues(lastYieldWeight, lastYieldPercentage, lastYieldPotential)
	local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
	if lastYieldWeight ~= spec.lastYieldWeight or lastYieldPercentage ~= spec.lastYieldPercentage or lastYieldPotential ~= spec.lastYieldPotential then
		spec.lastYieldWeight = lastYieldWeight
		spec.lastYieldPercentage = lastYieldPercentage
		spec.lastYieldPotential = lastYieldPotential
		self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
	end
end
