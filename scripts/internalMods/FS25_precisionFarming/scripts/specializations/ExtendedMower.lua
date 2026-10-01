ExtendedMower = {}
function ExtendedMower.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Mower, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function ExtendedMower.registerFunctions(vehicleType) end
function ExtendedMower.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processMowerArea", ExtendedMower.processMowerArea)
end
function ExtendedMower.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExtendedMower)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedMower)
end
function ExtendedMower:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient and self.isActiveForInputIgnoreSelectionIgnoreAI then
		ExtendedMower.updateMinimapActiveState(self)
	end
end
function ExtendedMower:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		if isActiveForInputIgnoreSelection then
			ExtendedMower.updateMinimapActiveState(self)
			return
		end
		ExtendedMower.updateMinimapActiveState(self, false)
	end
end
function ExtendedMower:updateMinimapActiveState(forcedState)
	local yieldMap = self:getPFYieldMap()
	local isActive = forcedState
	if isActive == nil then
		local _, _, _, isOnField = self:getPFStatisticInfo()
		isActive = isOnField
	end
	yieldMap:setRequireMinimapDisplay(isActive, self, self:getIsSelected())
end
function ExtendedMower:processMowerArea(superFunc, workArea, dt)
	if not self.isServer and Mower.CLIENT_DM_UPDATE_RADIUS < self.currentUpdateDistance then
		return superFunc(self, workArea, dt)
	end
	if g_precisionFarming ~= nil then
		g_precisionFarming.harvestExtension:preProcessMowerArea(self, workArea, dt)
	end
	local lastChangedArea, lastTotalArea = superFunc(self, workArea, dt)
	if g_precisionFarming ~= nil then
		g_precisionFarming.harvestExtension:postProcessMowerArea(self, workArea, dt, lastChangedArea)
	end
	return lastChangedArea, lastTotalArea
end
