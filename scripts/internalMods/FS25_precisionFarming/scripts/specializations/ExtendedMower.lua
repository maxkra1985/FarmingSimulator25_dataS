ExtendedMower = {}

function ExtendedMower.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Mower, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
	end
	return v2_
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

-- Local values: yieldMap, isActive, _, _, _, isOnField
function ExtendedMower:updateMinimapActiveState(forcedState)
	local v10_ = self:getPFYieldMap()
	if forcedState == nil then
		local v11_, v12_, v13_
		v11_, v12_, v13_, forcedState = self:getPFStatisticInfo()
	end
	v10_:setRequireMinimapDisplay(forcedState, self, self:getIsSelected())
end

-- Local values: lastChangedArea, lastTotalArea
function ExtendedMower:processMowerArea(superFunc, workArea, dt)
	if not self.isServer and self.currentUpdateDistance > Mower.CLIENT_DM_UPDATE_RADIUS then
		return superFunc(self, workArea, dt)
	end
	if g_precisionFarming ~= nil then
		g_precisionFarming.harvestExtension:preProcessMowerArea(self, workArea, dt)
	end
	local v18_, v19_ = superFunc(self, workArea, dt)
	if g_precisionFarming ~= nil then
		g_precisionFarming.harvestExtension:postProcessMowerArea(self, workArea, dt, v18_)
	end
	return v18_, v19_
end
