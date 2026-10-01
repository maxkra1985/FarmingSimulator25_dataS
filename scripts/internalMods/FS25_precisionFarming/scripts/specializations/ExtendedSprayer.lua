ExtendedSprayer = {}
ExtendedSprayer.SPEC_NAME = g_currentModName .. ".extendedSprayer"
ExtendedSprayer.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedSprayer"
source(g_currentModDirectory .. "scripts/hud/ExtendedSprayerHUDExtension.lua")
function ExtendedSprayer.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function ExtendedSprayer.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("pulseWidthModulation", g_i18n:getText("configuration_pulseWidthModulation"), "sprayer", VehicleConfigurationItem)
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("ExtendedSprayer")
	schema:register(XMLValueType.BOOL, "vehicle.sprayer.pulseWidthModulationConfigurations#isAlwaysActive", "Pulse width modulation is always active", false)
	schema:register(XMLValueType.BOOL, "vehicle.sprayer.speedDependentApplication#isSupported", "Spreader / sprayer does automatically reduce the application rate while driving slower", "by default supported on all except sprayers")
	schema:setXMLSpecializationType()
end
function ExtendedSprayer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setSprayAmountAutoMode", ExtendedSprayer.setSprayAmountAutoMode)
	SpecializationUtil.registerFunction(vehicleType, "setSprayAmountManualValue", ExtendedSprayer.setSprayAmountManualValue)
	SpecializationUtil.registerFunction(vehicleType, "setSprayAmountAutoFruitTypeIndex", ExtendedSprayer.setSprayAmountAutoFruitTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "setSprayAmountDefaultFruitRequirementIndex", ExtendedSprayer.setSprayAmountDefaultFruitRequirementIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSprayerMode", ExtendedSprayer.getCurrentSprayerMode)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentNitrogenLevelOffset", ExtendedSprayer.getCurrentNitrogenLevelOffset)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentNitrogenUsageLevelOffset", ExtendedSprayer.getCurrentNitrogenUsageLevelOffset)
	SpecializationUtil.registerFunction(vehicleType, "getUseExtendedSprayerHudExtension", ExtendedSprayer.getUseExtendedSprayerHudExtension)
	SpecializationUtil.registerFunction(vehicleType, "getShowExtendedSprayerHudExtension", ExtendedSprayer.getShowExtendedSprayerHudExtension)
	SpecializationUtil.registerFunction(vehicleType, "getIsUsingExactNitrogenAmount", ExtendedSprayer.getIsUsingExactNitrogenAmount)
	SpecializationUtil.registerFunction(vehicleType, "getIsPrecisionSprayingRequired", ExtendedSprayer.getIsPrecisionSprayingRequired)
	SpecializationUtil.registerFunction(vehicleType, "preProcessExtUnderRootFertilizerArea", ExtendedSprayer.preProcessExtUnderRootFertilizerArea)
	SpecializationUtil.registerFunction(vehicleType, "updateWorkAreaSubSectionData", ExtendedSprayer.updateWorkAreaSubSectionData)
	SpecializationUtil.registerFunction(vehicleType, "processWorkAreaSubSectionData", ExtendedSprayer.processWorkAreaSubSectionData)
end
function ExtendedSprayer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateWorkAreaWidth", ExtendedSprayer.updateWorkAreaWidth)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", ExtendedSprayer.getSprayerUsage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSprayerArea", ExtendedSprayer.processSprayerArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "changeSeedIndex", ExtendedSprayer.changeSeedIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerDoubledAmountActive", ExtendedSprayer.getSprayerDoubledAmountActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSprayerEffects", ExtendedSprayer.updateSprayerEffects)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtendedSprayerNozzleEffectState", ExtendedSprayer.updateExtendedSprayerNozzleEffectState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", ExtendedSprayer.setSprayerAITerrainDetailProhibitedRange)
end
function ExtendedSprayer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onVariableWorkWidthSectionChanged", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedSprayer)
end
function ExtendedSprayer:onPreLoad(savegame)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if g_precisionFarming ~= nil then
		spec.soilMap = g_precisionFarming.soilMap
		spec.pHMap = g_precisionFarming.pHMap
		spec.nitrogenMap = g_precisionFarming.nitrogenMap
	end
end
function ExtendedSprayer:onLoad(savegame)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	spec.pwmEnabled = 1 < (self.configurations.pulseWidthModulation or 1)
	spec.spotSprayEnabled = 1 < (self.configurations.weedSpotSpray or 1)
	if self.xmlFile:getValue("vehicle.sprayer.pulseWidthModulationConfigurations#isAlwaysActive", false) then
		spec.pwmEnabled = true
	end
	if self.spec_sowingMachine ~= nil then
		spec.pwmEnabled = true
	end
	spec.texts = {}
	spec.texts.toggleSprayAmountAutoModePos = g_i18n:getText("action_toggleSprayAmountAutoModePos", self.customEnvironment)
	spec.texts.toggleSprayAmountAutoModeNeg = g_i18n:getText("action_toggleSprayAmountAutoModeNeg", self.customEnvironment)
	spec.texts.toggleSprayAmountAutoManual = g_i18n:getText("action_toggleSprayAmountManual", self.customEnvironment)
	spec.texts.toggleSprayDefaultFruitRequirement = g_i18n:getText("action_toggleSprayDefaultFruitRequirement", self.customEnvironment)
	spec.lastLitersPerHectar = 0
	spec.lastNitrogenProportion = 0
	spec.lastRegularUsage = 0
	spec.lastTouchedSoilType = 0
	spec.lastTouchedSoilTypeSent = 0
	spec.lastGroundUpdateDistance = math.huge
	spec.groundUpdateDistance = 2
	spec.phActualValue = 0
	spec.phActualValueSent = 0
	spec.phTargetValue = 0
	spec.phTargetValueSent = 0
	spec.nActualValue = 0
	spec.nActualValueSent = 0
	spec.nTargetValue = 0
	spec.nTargetValueSent = 0
	spec.sprayAmountAutoMode = true
	spec.sprayAmountAutoModeChangeAllowed = true
	spec.sprayAmountManual = 1
	spec.sprayAmountManualMin = 1
	spec.sprayAmountManualMax = 1
	spec.inputActionToggleAuto = InputAction.PRECISIONFARMING_SPRAY_AMOUNT_MODE
	spec.inputActionToggleSprayAmount = InputAction.PRECISIONFARMING_SPRAY_AMOUNT
	spec.isDoingMissionWork = false
	local _, _, nMaxValue = spec.nitrogenMap:getMinMaxValue()
	spec.sprayAmountManualMax = nMaxValue - 1
	spec.attachStateChanged = false
	spec.nApplyAutoModeFruitType = FruitType.UNKNOWN
	spec.nApplyAutoModeFruitTypeSent = FruitType.UNKNOWN
	spec.nApplyAutoModeFruitRequirementDefaultIndex = 1
	spec.nApplyAutoModeFruitTypeRequiresDefaultMode = false
	spec.lastAreaChangeTime = -math.huge
	spec.lastSprayerEffectState = true
	spec.densityMapParallelogram = DensityMapParallelogram.new()
	spec.densityMapPolygon = DensityMapPolygon.new()
	spec.densityMapPolygon:addPolygonPoint(0, 0)
	spec.densityMapPolygon:addPolygonPoint(0, 0)
	spec.densityMapPolygon:addPolygonPoint(0, 0)
	spec.densityMapPolygon:addPolygonPoint(0, 0)
	local sprayerFillUnitIndex = self:getSprayerFillUnitIndex()
	spec.isSlurryTanker = self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.DIGESTATE)
	spec.isManureSpreader = self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.MANURE)
	spec.isSolidFertilizerSprayer = self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.FERTILIZER) or self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.LIME)
	spec.isLiquidFertilizerSprayer = self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.LIQUIDFERTILIZER)
	spec.speedDependentApplication = self.xmlFile:getValue("vehicle.sprayer.speedDependentApplication#isSupported", not spec.isLiquidFertilizerSprayer)
	spec.usageValuesDirtyFlag = self:getNextDirtyFlag()
	if self:getUseExtendedSprayerHudExtension() then
		spec.hudExtension = ExtendedSprayerHUDExtension.new(self)
	end
	spec.sprayerWorkAreas = self:getTypedWorkAreas(WorkAreaType.SPRAYER)
	spec.sowingMachineWorkAreas = self:getTypedWorkAreas(WorkAreaType.SOWINGMACHINE)
	spec.cultivatorWorkAreas = self:getTypedWorkAreas(WorkAreaType.CULTIVATOR)
	spec.workAreas = {}
	for _, workArea in pairs(spec.sprayerWorkAreas) do
		table.insert(spec.workAreas, workArea)
	end
	for _, workArea in pairs(spec.sowingMachineWorkAreas) do
		table.insert(spec.workAreas, workArea)
	end
	for _, workArea in pairs(spec.cultivatorWorkAreas) do
		table.insert(spec.workAreas, workArea)
	end
	spec.useFertilizerSprayType = 0 < #spec.cultivatorWorkAreas or 0 < #spec.sowingMachineWorkAreas
	spec.groundTypeMapId, spec.groundTypeFirstChannel, spec.groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
end
function ExtendedSprayer:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local specName = ExtendedSprayer.SPEC_NAME
		self:setSprayAmountAutoMode(Utils.getNoNil(savegame.xmlFile:getBool(savegame.key .. "." .. specName .. "#sprayAmountAutoMode"), spec.sprayAmountAutoMode), true)
		self:setSprayAmountManualValue(savegame.xmlFile:getInt(savegame.key .. "." .. specName .. "#sprayAmountManual") or spec.sprayAmountManual, true)
	end
end
function ExtendedSprayer:onDelete()
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if spec.hudExtension ~= nil then
		spec.hudExtension:delete()
	end
end
function ExtendedSprayer:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	xmlFile:setBool(key .. "#sprayAmountAutoMode", spec.sprayAmountAutoMode)
	xmlFile:setInt(key .. "#sprayAmountManual", spec.sprayAmountManual)
end
function ExtendedSprayer:onReadStream(streamId, connection)
	local sprayAmountAutoMode = streamReadBool(streamId)
	local sprayAmountManual = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
	self:setSprayAmountAutoMode(sprayAmountAutoMode, true)
	self:setSprayAmountManualValue(sprayAmountManual, true)
end
function ExtendedSprayer:onWriteStream(streamId, connection)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	streamWriteBool(streamId, spec.sprayAmountAutoMode)
	streamWriteUIntN(streamId, spec.sprayAmountManual, NitrogenMap.NUM_BITS)
end
function ExtendedSprayer:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
		if streamReadBool(streamId) then
			spec.phActualValue = streamReadUIntN(streamId, PHMap.NUM_BITS)
			spec.phTargetValue = streamReadUIntN(streamId, PHMap.NUM_BITS)
			spec.nActualValue = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
			spec.nTargetValue = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
			spec.lastTouchedSoilType = streamReadUIntN(streamId, 3)
			if streamReadBool(streamId) then
				self:setSprayAmountAutoFruitTypeIndex(streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS))
				return
			end
			self:setSprayAmountAutoFruitTypeIndex(nil)
		end
	end
end
function ExtendedSprayer:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
		if streamWriteBool(streamId, bit32.band(dirtyMask, spec.usageValuesDirtyFlag) ~= 0) then
			streamWriteUIntN(streamId, spec.phActualValue, PHMap.NUM_BITS)
			streamWriteUIntN(streamId, spec.phTargetValue, PHMap.NUM_BITS)
			streamWriteUIntN(streamId, spec.nActualValue, NitrogenMap.NUM_BITS)
			streamWriteUIntN(streamId, spec.nTargetValue, NitrogenMap.NUM_BITS)
			streamWriteUIntN(streamId, spec.lastTouchedSoilType, 3)
			if streamWriteBool(streamId, spec.nApplyAutoModeFruitType ~= nil) then
				streamWriteUIntN(streamId, spec.nApplyAutoModeFruitType, FruitTypeManager.SEND_NUM_BITS)
			end
		end
	end
end
function ExtendedSprayer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if self.isServer then
		if not self.finishedFirstUpdate then
			spec.isLiming, spec.isFertilizing = self:getCurrentSprayerMode()
			ExtendedSprayer.updateActionEventState(self)
			ExtendedSprayer.updateActionEventAutoModeDefault(self)
		end
		if self.finishedFirstUpdate then
			spec.lastGroundUpdateDistance = spec.lastGroundUpdateDistance + self.lastMovedDistance
			if spec.groundUpdateDistance < spec.lastGroundUpdateDistance then
				spec.lastGroundUpdateDistance = 0
				for _, workArea in pairs(spec.sprayerWorkAreas) do
					local isAllowed = true
					if workArea.sprayType ~= nil then
						local sprayType = self:getActiveSprayType()
						if sprayType ~= nil and sprayType.index ~= workArea.sprayType then
							isAllowed = false
						end
					end
					if isAllowed then
						self:updateWorkAreaSubSectionData(workArea)
					end
				end
				for _, workArea in pairs(spec.sowingMachineWorkAreas) do
					self:updateWorkAreaSubSectionData(workArea)
				end
				for _, workArea in pairs(spec.cultivatorWorkAreas) do
					self:updateWorkAreaSubSectionData(workArea)
				end
				for _, vehicle in ipairs(self.rootVehicle.childVehicles) do
					if vehicle.spec_pdlc_nexatPack.cultivatorSowingMachineExtension == nil then
						continue
					end
					for _, workArea in pairs(vehicle.spec_workArea.workAreas) do
						if workArea.type == WorkAreaType.CULTIVATOR then
							if workArea.subSectionData == nil then
								self:updateWorkAreaWidth(0, workArea)
							end
							self:updateWorkAreaSubSectionData(workArea)
						end
					end
				end
			end
		end
	end
	if self.isActiveForInputIgnoreSelectionIgnoreAI and (self:getShowExtendedSprayerHudExtension() and spec.hudExtension ~= nil) then
		local hud = g_currentMission.hud
		hud:addHelpExtension(spec.hudExtension)
	end
end
function ExtendedSprayer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if self.isClient then
		if self:getIsTurnedOn() then
			ExtendedSprayer.updateSprayerEffectState(self)
		else
			spec.lastSprayerEffectState = true
		end
	end
	local isLiming, isFertilizing = self:getCurrentSprayerMode()
	if isLiming ~= spec.isLiming or isFertilizing ~= spec.isFertilizing then
		spec.isLiming = isLiming
		spec.isFertilizing = isFertilizing
		ExtendedSprayer.updateActionEventState(self)
		ExtendedSprayer.updateActionEventAutoModeDefault(self)
	end
	if self.isActiveForInputIgnoreSelectionIgnoreAI then
		ExtendedSprayer.updateMinimapActiveState(self)
		local _, _, _, _, mission = self:getPFStatisticInfo()
		local isDoingMissionWork = true
		if mission == nil then
			isDoingMissionWork = spec.sprayAmountAutoMode and spec.nApplyAutoModeFruitTypeRequiresDefaultMode
		end
		if spec.isDoingMissionWork ~= isDoingMissionWork then
			spec.isDoingMissionWork = isDoingMissionWork
			ExtendedSprayer.updateMinimapActiveState(self)
		end
	end
end
function ExtendedSprayer:onChangedFillType(fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if spec.isSolidFertilizerSprayer and fillTypeIndex == FillType.LIME then
		local _, _, pHMaxValue = spec.pHMap:getMinMaxValue()
		spec.sprayAmountManualMax = pHMaxValue - 1
		return
	end
	local _, _, nMaxValue = spec.nitrogenMap:getMinMaxValue()
	spec.sprayAmountManualMax = nMaxValue - 1
end
function ExtendedSprayer:onTurnedOn()
	if self.isClient then
		ExtendedSprayer.updateSprayerEffectState(self, true)
	end
end
function ExtendedSprayer:onTurnedOff()
	if self.isClient then
		ExtendedSprayer.updateSprayerEffectState(self, true)
	end
end
function ExtendedSprayer:onStateChange(state, data)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
		spec.attachStateChanged = true
	end
end
function ExtendedSprayer:onVariableWorkWidthSectionChanged()
	local vehicles = self.rootVehicle.childVehicles
	for i = 1, #vehicles do
		local vehicle = vehicles[i]
		if SpecializationUtil.hasSpecialization(CropSensor, vehicle.specializations) then
			vehicle:updateCropSensorWorkingWidth()
		end
	end
	if self.isClient then
		ExtendedSprayer.updateSprayerEffectState(self, true)
	end
end
function ExtendedSprayer:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
		self:clearActionEventsTable(spec.actionEvents)
		spec.pHMap:setRequireMinimapDisplay(false, self)
		spec.nitrogenMap:setRequireMinimapDisplay(false, self)
		if isActiveForInputIgnoreSelection and self == ExtendedSprayer.getValidSprayerToUse(self) then
			if spec.sprayAmountAutoModeChangeAllowed then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionToggleAuto, self, ExtendedSprayer.actionEventToggleAuto, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			end
			local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionToggleSprayAmount, self, ExtendedSprayer.actionEventChangeSprayAmount, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventText(actionEventId, spec.texts.toggleSprayAmountAutoManual)
			if self.spec_sowingMachine == nil then
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_SEEDS, self, ExtendedSprayer.actionEventChangeDefaultFruitRequirement, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
				g_inputBinding:setActionEventText(actionEventId, spec.texts.toggleSprayDefaultFruitRequirement)
			end
			ExtendedSprayer.updateActionEventState(self)
			ExtendedSprayer.updateActionEventAutoModeDefault(self)
			ExtendedSprayer.updateMinimapActiveState(self)
		end
		spec.attachStateChanged = true
	end
end
function ExtendedSprayer:getValidSprayerToUse()
	local vehicleList = self.rootVehicle.childVehicles
	for i = 1, #vehicleList do
		local subVehicle = vehicleList[i]
		if ExtendedSprayer.getIsVehicleValid(subVehicle) then
			return subVehicle
		end
	end
	return nil
end
function ExtendedSprayer.getIsVehicleValid(vehicle)
	if not SpecializationUtil.hasSpecialization(ExtendedSprayer, vehicle.specializations) then
		return false
	elseif not SpecializationUtil.hasSpecialization(WorkArea, vehicle.specializations) then
		return false
	elseif #vehicle.spec_workArea.workAreas == 0 then
		return false
	else
		if SpecializationUtil.hasSpecialization(ManureBarrel, vehicle.specializations) and vehicle.spec_manureBarrel.attachedTool ~= nil then
			return false
		end
		return true
	end
end
function ExtendedSprayer:actionEventToggleAuto(actionName, inputValue, callbackState, isAnalog)
	self:setSprayAmountAutoMode()
end
function ExtendedSprayer:actionEventChangeSprayAmount(actionName, inputValue, callbackState, isAnalog)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	self:setSprayAmountManualValue(spec.sprayAmountManual + math.sign(inputValue))
end
function ExtendedSprayer:actionEventChangeDefaultFruitRequirement(actionName, inputValue, callbackState, isAnalog)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	self:setSprayAmountDefaultFruitRequirementIndex(spec.nitrogenMap:getNextFruitRequirementIndex(spec.nApplyAutoModeFruitRequirementDefaultIndex))
end
function ExtendedSprayer:updateActionEventState()
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local actionEventToggleAuto = spec.actionEvents[spec.inputActionToggleAuto]
	if actionEventToggleAuto ~= nil then
		g_inputBinding:setActionEventActive(actionEventToggleAuto.actionEventId, spec.isLiming or spec.isFertilizing)
		g_inputBinding:setActionEventText(actionEventToggleAuto.actionEventId, spec.sprayAmountAutoMode and spec.texts.toggleSprayAmountAutoModeNeg or spec.texts.toggleSprayAmountAutoModePos)
	end
	local actionEventToggleSprayAmount = spec.actionEvents[spec.inputActionToggleSprayAmount]
	if actionEventToggleSprayAmount ~= nil then
		g_inputBinding:setActionEventActive(actionEventToggleSprayAmount.actionEventId, not spec.sprayAmountAutoMode)
	end
end
function ExtendedSprayer:updateActionEventAutoModeDefault()
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_SEEDS]
	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.isFertilizing and spec.sprayAmountAutoMode and spec.nApplyAutoModeFruitType ~= nil and spec.nApplyAutoModeFruitType == FruitType.UNKNOWN)
	end
end
function ExtendedSprayer.getFillTypeSourceVehicle(sprayer)
	local firstEmptySource = nil
	local firstEmptySourceFillUnitIndex = 1
	local fillUnitIndex = sprayer:getSprayerFillUnitIndex()
	if sprayer:getFillUnitFillLevel(fillUnitIndex) <= 0 then
		local spec = sprayer.spec_sprayer
		for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
			for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
				local vehicle = src.vehicle
				local fillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)
				if vehicle:getFillUnitFillType(src.fillUnitIndex) == supportedSprayType then
					if 0 < fillLevel then
						return vehicle, src.fillUnitIndex
					end
				elseif fillLevel == 0 then
					if vehicle:getFillUnitSupportsFillType(src.fillUnitIndex, supportedSprayType) then
						firstEmptySource = vehicle
						firstEmptySourceFillUnitIndex = src.fillUnitIndex
					end
				end
			end
		end
	end
	if sprayer:getIsAIActive() and sprayer:getFillUnitCapacity(fillUnitIndex) == 0 then
		return firstEmptySource or sprayer, firstEmptySourceFillUnitIndex or fillUnitIndex
	end
	return sprayer, fillUnitIndex
end
function ExtendedSprayer:getCurrentSprayerMode()
	local sprayer, fillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
	local fillType = sprayer:getFillUnitFillType(fillUnitIndex)
	if fillType == FillType.UNKNOWN then
		if self:getIsAIActive() then
			return false, true
		end
		fillType = sprayer:getFillUnitLastValidFillType(fillUnitIndex)
	end
	if fillType == FillType.LIME then
		return true, false
	end
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if spec.nitrogenMap:getFillTypeIsFertilizer(fillType) then
		return false, true
	elseif fillType == FillType.HERBICIDE then
		return false, false
	else
		return false, false
	end
end
function ExtendedSprayer:getCurrentNitrogenLevelOffset(lastChangeLevels)
	return 0
end
function ExtendedSprayer:getCurrentNitrogenUsageLevelOffset(lastChangeLevels)
	return 0
end
function ExtendedSprayer:getUseExtendedSprayerHudExtension()
	if not SpecializationUtil.hasSpecialization(WorkArea, self.specializations) then
		return false
	elseif #self.spec_workArea.workAreas == 0 then
		return false
	else
		return true
	end
end
function ExtendedSprayer:getShowExtendedSprayerHudExtension()
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if not self.isClient then
		return false
	elseif self.spec_manureBarrel ~= nil and self.spec_manureBarrel.attachedTool ~= nil then
		return false
	else
		if not spec.isSlurryTanker and not spec.isManureSpreader then
			local sourceVehicle, sourceFillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
			if sourceVehicle:getFillUnitFillLevel(sourceFillUnitIndex) <= 0 and not self:getIsAIActive() then
				return false
			end
			if not spec.isLiming and not spec.isFertilizing then
				return false
			end
		end
		return true
	end
end
function ExtendedSprayer:getIsUsingExactNitrogenAmount()
	return true
end
function ExtendedSprayer:updateMinimapActiveState()
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local _, _, _, isOnField = self:getPFStatisticInfo()
	local isActive = isOnField
	if isActive then
		local sprayer, fillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
		local _v23 = isActive
		if _v23 and not (0 < sprayer:getFillUnitFillLevel(fillUnitIndex)) then
			self:getIsAIActive()
		end
		isActive = _v23
	end
	isActive = isActive
	if spec.isLiming then
		spec.pHMap:setRequireMinimapDisplay(isActive, self, self:getIsSelected())
	else
		if spec.isFertilizing then
			spec.nitrogenMap:setRequireMinimapDisplay(isActive, self, self:getIsSelected())
			spec.nitrogenMap:setMinimapMissionState(spec.isDoingMissionWork)
		end
	end
end
function ExtendedSprayer:getIsPrecisionSprayingRequired()
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if spec.isDoingMissionWork then
		return true
	else
		if spec.sprayAmountAutoMode then
			local dataUncovered = false
			for _, workArea in pairs(spec.workAreas) do
				if workArea.isPrecisionFarmingDataUncovered then
					dataUncovered = true
					break
				end
			end
			if not dataUncovered then
				return true
			end
			if not spec.pwmEnabled then
				if spec.isLiming then
					if spec.phTargetValue <= spec.phActualValue then
						return false
					end
				elseif spec.isFertilizing then
					if spec.nTargetValue <= spec.nActualValue then
						return false
					end
				end
			end
		end
		return true
	end
end
function ExtendedSprayer:updateSprayerEffectState(force)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local effectState = self:getIsPrecisionSprayingRequired() and self:getAreEffectsVisible() and self:getIsTurnedOn()
	if spec.lastSprayerEffectState ~= effectState or force then
		local specSprayer = self.spec_sprayer
		local sprayType = self:getActiveSprayType()
		if effectState then
			local fillType = self:getFillUnitLastValidFillType(self:getSprayerFillUnitIndex())
			if fillType == FillType.UNKNOWN then
				fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
			end
			g_effectManager:setEffectTypeInfo(specSprayer.effects, fillType)
			g_effectManager:startEffects(specSprayer.effects)
			g_soundManager:playSamples(specSprayer.samples.spray)
			if sprayType ~= nil then
				g_effectManager:setEffectTypeInfo(sprayType.effects, fillType)
				g_effectManager:startEffects(sprayType.effects)
				g_animationManager:startAnimations(sprayType.animationNodes)
				g_soundManager:playSamples(sprayType.samples.spray)
			end
			g_animationManager:startAnimations(specSprayer.animationNodes)
		else
			g_effectManager:stopEffects(specSprayer.effects)
			g_soundManager:stopSamples(specSprayer.samples.spray)
			for _, _sprayType in ipairs(specSprayer.sprayTypes) do
				g_effectManager:stopEffects(_sprayType.effects)
				g_animationManager:stopAnimations(_sprayType.animationNodes)
				g_soundManager:stopSamples(_sprayType.samples.spray)
			end
			g_animationManager:stopAnimations(specSprayer.animationNodes)
		end
		spec.lastSprayerEffectState = effectState
	end
end
function ExtendedSprayer:updateWorkAreaWidth(superFunc, workAreaIndex, workArea)
	superFunc(self, workAreaIndex)
	local specWorkArea = self.spec_workArea
	workArea = workArea or specWorkArea.workAreas[workAreaIndex]
	if workArea == nil then
		return
	else
		local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local xOffset, _, _ = localToLocal(workArea.start, self.rootNode, 0, 0, 0)
		local isFertilizerSpreader = math.abs(xOffset) < 0.1
		local numMainDivisions = 1
		local numSubDivisions = math.ceil(workArea.workWidth * 0.5)
		if isFertilizerSpreader then
			numMainDivisions = 2
			numSubDivisions = math.ceil(workArea.workWidth * 0.5 * 0.5)
		end
		if numMainDivisions ~= workArea.numMainDivisions or numSubDivisions ~= workArea.numSubDivisions then
			workArea.numMainDivisions = numMainDivisions
			workArea.numSubDivisions = numSubDivisions
			workArea.maxPHApplicationOffset = 0
			workArea.maxNApplicationOffset = 0
			local subSectionIndex = 1
			workArea.subSectionData = {}
			for mainIndex = 1, workArea.numMainDivisions do
				for subIndex = 1, workArea.numSubDivisions do
					local subSectionData = nil
					if workArea.subSectionData[subSectionIndex] == nil then
						workArea.subSectionData[subSectionIndex] = {}
						subSectionData = workArea.subSectionData[subSectionIndex]
					end
					subSectionData.index = subSectionIndex
					subSectionData.mainIndex = mainIndex
					subSectionData.subIndex = subIndex
					subSectionData.isValid = false
					subSectionData.nitrogenLevel = 0
					subSectionData.nitrogenTargetLevel = 0
					subSectionData.phLevel = 0
					subSectionData.phTargetLevel = 0
					subSectionData.soilTypeIndex = 0
					subSectionData.fruitType = FruitType.UNKNOWN
					subSectionData.growthState = 0
					subSectionData.lastSpeed = 0
					subSectionData.phApplicationOffset = 0
					subSectionData.nApplicationOffset = 0
					if 1 < workArea.numMainDivisions and 1 < workArea.numSubDivisions then
						subSectionData.phApplicationOffset = -math.floor((subIndex - 1) / (workArea.numSubDivisions - 1) * 2.01)
						subSectionData.nApplicationOffset = -math.floor((subIndex - 1) / (workArea.numSubDivisions - 1) * 4.01)
						workArea.maxPHApplicationOffset = math.max(workArea.maxPHApplicationOffset, math.abs(subSectionData.phApplicationOffset))
						workArea.maxNApplicationOffset = math.max(workArea.maxNApplicationOffset, math.abs(subSectionData.nApplicationOffset))
					end
					subSectionData.lastDetectionX = 0
					subSectionData.lastDetectionZ = 0
					subSectionIndex = subSectionIndex + 1
				end
			end
			workArea.numSubSections = subSectionIndex - 1
			workArea.nitrogenLevel = 0
			workArea.nitrogenTargetLevel = 0
			workArea.phLevel = 0
			workArea.phTargetLevel = 0
			workArea.lastSpeed = 0
			workArea.fruitType = FruitType.UNKNOWN
			if workArea.fruitTypes == nil then
				workArea.fruitTypes = {}
			end
			for index, _ in pairs(g_fruitTypeManager:getFruitTypes()) do
				workArea.fruitTypes[index] = 0
			end
			workArea.growthState = 0
			workArea.soilTypeIndex = 0
			if workArea.soilTypes == nil then
				workArea.soilTypes = {}
			end
			if spec.soilMap ~= nil and spec.soilMap.soilTypes ~= nil then
				for index, _ in pairs(spec.soilMap.soilTypes) do
					workArea.soilTypes[index] = 0
				end
			end
			spec.lastGroundUpdateDistance = math.huge
		end
	end
end
function ExtendedSprayer:updateWorkAreaSubSectionData(workArea)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local specSpray = self.spec_sprayer
	local sprayType = specSpray.workAreaParameters.sprayType
	if sprayType == nil then
		local fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
		sprayType = g_sprayTypeManager:getSprayTypeIndexByFillTypeIndex(fillType)
	end
	local lockSprayType = sprayType
	if spec.useFertilizerSprayType then
		lockSprayType = SprayType.FERTILIZER
	end
	if workArea.subSectionData == nil then
		self:updateWorkAreaWidth(workArea.index)
	end
	local checkSubSectionPos = function(subSectionData, x, y, z, dirX, dirZ)
		local lx, ly, lz = worldToLocal(self.rootNode, x, y, z)
		local vx, _, vz = getVelocityAtLocalPos(self.rootNode, lx, ly, lz)
		subSectionData.lastSpeed = MathUtil.vector2Length(vx, vz) * 3.6
		subSectionData.isValid = spec.isLiming or spec.isFertilizing
		subSectionData.isUncovered = spec.isLiming or spec.isFertilizing
		local ox = x
		local oz = z
		local foundUncovered = false
		if spec.isLiming then
			ox, oz, foundUncovered = spec.pHMap:getNextValidDetectionPoint(x, z, dirX, dirZ, 10, lockSprayType)
			if ox == nil then
				ox = x
				oz = z
				subSectionData.isValid = false
			end
			if not foundUncovered then
				subSectionData.isUncovered = false
			end
		end
		if spec.isFertilizing then
			ox, oz, foundUncovered = spec.nitrogenMap:getNextValidDetectionPoint(x, z, dirX, dirZ, 10, lockSprayType)
			if ox == nil then
				ox = x
				oz = z
				subSectionData.isValid = false
			end
			if not foundUncovered then
				subSectionData.isUncovered = false
			end
		end
		if 0.01 < math.abs(x - subSectionData.lastDetectionX) or 0.01 < math.abs(z - subSectionData.lastDetectionZ) then
			subSectionData.soilTypeIndex = spec.soilMap:getTypeIndexAtWorldPos(ox, oz)
			if subSectionData.soilTypeIndex == 0 then
				subSectionData.isValid = false
			end
			if spec.isLiming then
				subSectionData.phLevel = spec.pHMap:getLevelAtWorldPos(ox, oz)
				subSectionData.phTargetLevel = spec.pHMap:getOptimalPHValueForSoilTypeIndex(subSectionData.soilTypeIndex) or subSectionData.phLevel
			end
			if spec.isFertilizing then
				subSectionData.nitrogenLevel = spec.nitrogenMap:getLevelAtWorldPos(ox, oz)
				if self.spec_sowingMachine ~= nil then
					subSectionData.fruitTypeIndex = self.spec_sowingMachine.seeds[self.spec_sowingMachine.currentSeed]
					subSectionData.growthState = 0
				else
					subSectionData.fruitTypeIndex, subSectionData.growthState = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
					subSectionData.fruitTypeIndex = subSectionData.fruitTypeIndex or FruitType.UNKNOWN
					subSectionData.growthState = subSectionData.growthState or 0
					if subSectionData.fruitTypeIndex ~= FruitType.UNKNOWN then
						local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(subSectionData.fruitTypeIndex)
						if fruitTypeDesc.maxHarvestingGrowthState < subSectionData.growthState then
							subSectionData.fruitTypeIndex = FruitType.UNKNOWN
						end
					end
				end
				local applicationRate, _ = spec.nitrogenMap:getNitrogenApplicationRate(subSectionData.nitrogenLevel, subSectionData.fruitTypeIndex, subSectionData.soilTypeIndex, sprayType)
				subSectionData.nitrogenTargetLevel = subSectionData.nitrogenLevel + (applicationRate or 0)
			end
			subSectionData.lastDetectionX = x
			subSectionData.lastDetectionZ = z
		end
	end
	if workArea.subSectionData ~= nil then
		local moveDirX, _, moveDirZ = localDirectionToWorld(workArea.start, 0, 0, 1)
		moveDirX, moveDirZ = MathUtil.vector2Normalize(moveDirX, moveDirZ)
		local worldStartX, y, worldStartZ = getWorldTranslation(workArea.start)
		local worldWidthX, _, worldWidthZ = getWorldTranslation(workArea.width)
		local worldHeightX, _, worldHeightZ = getWorldTranslation(workArea.height)
		if workArea.numMainDivisions == 1 then
			local dirX = worldWidthX - worldStartX
			local dirZ = worldWidthZ - worldStartZ
			local width = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / width
			dirZ = dirZ / width
			local subSectionWidth = width / workArea.numSubDivisions
			for i = 1, workArea.numSubDivisions do
				local subSectionData = workArea.subSectionData[i]
				local checkX = worldStartX + dirX * (i - 0.5) * subSectionWidth
				local checkZ = worldStartZ + dirZ * (i - 0.5) * subSectionWidth
				checkSubSectionPos(subSectionData, checkX, y, checkZ, moveDirX, moveDirZ)
			end
		else
			local dirX = worldWidthX - worldStartX
			local dirZ = worldWidthZ - worldStartZ
			local width = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / width
			dirZ = dirZ / width
			local subSectionWidth = width / workArea.numSubDivisions
			for i = 1, workArea.numSubDivisions do
				local subSectionData = workArea.subSectionData[i]
				local checkX = worldStartX + dirX * (i - 0.5) * subSectionWidth
				local checkZ = worldStartZ + dirZ * (i - 0.5) * subSectionWidth
				checkSubSectionPos(subSectionData, checkX, y, checkZ, moveDirX, moveDirZ)
			end
			dirX = worldHeightX - worldStartX
			dirZ = worldHeightZ - worldStartZ
			width = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / width
			dirZ = dirZ / width
			subSectionWidth = width / workArea.numSubDivisions
			for i = 1, workArea.numSubDivisions do
				local subSectionData = workArea.subSectionData[i + workArea.numSubDivisions]
				local checkX = worldStartX + dirX * (i - 0.5) * subSectionWidth
				local checkZ = worldStartZ + dirZ * (i - 0.5) * subSectionWidth
				checkSubSectionPos(subSectionData, checkX, y, checkZ, moveDirX, moveDirZ)
			end
		end
		workArea.nitrogenLevel = 0
		workArea.nitrogenLevelMax = 0
		workArea.nitrogenTargetLevel = 0
		workArea.phLevel = 0
		workArea.phLevelMax = 0
		workArea.phTargetLevel = 0
		workArea.lastSpeed = 0
		workArea.fruitTypeIndex = 0
		workArea.growthState = 0
		workArea.soilTypeIndex = 0
		workArea.isPrecisionFarmingDataUncovered = false
		if 0 < workArea.numSubSections then
			for index, _ in ipairs(workArea.fruitTypes) do
				workArea.fruitTypes[index] = 0
			end
			for index, _ in ipairs(workArea.soilTypes) do
				workArea.soilTypes[index] = 0
			end
			local numValidSubSections = 0
			local numValidNTargetSections = 0
			for i = 1, workArea.numSubSections do
				local subSectionData = workArea.subSectionData[i]
				if subSectionData.isValid then
					workArea.nitrogenLevel = workArea.nitrogenLevel + subSectionData.nitrogenLevel
					workArea.nitrogenLevelMax = math.max(workArea.nitrogenLevelMax, subSectionData.nitrogenLevel)
					workArea.phLevel = workArea.phLevel + subSectionData.phLevel
					workArea.phLevelMax = math.max(workArea.phLevelMax, subSectionData.phLevel)
					workArea.phTargetLevel = workArea.phTargetLevel + subSectionData.phTargetLevel
					workArea.lastSpeed = workArea.lastSpeed + subSectionData.lastSpeed
					if subSectionData.fruitTypeIndex ~= nil and subSectionData.fruitTypeIndex ~= FruitType.UNKNOWN then
						workArea.fruitTypes[subSectionData.fruitTypeIndex] = workArea.fruitTypes[subSectionData.fruitTypeIndex] + 1
						workArea.nitrogenTargetLevel = workArea.nitrogenTargetLevel + subSectionData.nitrogenTargetLevel
						numValidNTargetSections = numValidNTargetSections + 1
					end
					workArea.growthState = math.max(workArea.growthState, subSectionData.growthState)
					if subSectionData.soilTypeIndex ~= nil and subSectionData.soilTypeIndex ~= 0 then
						workArea.soilTypes[subSectionData.soilTypeIndex] = workArea.soilTypes[subSectionData.soilTypeIndex] + 1
					end
					numValidSubSections = numValidSubSections + 1
				end
				if subSectionData.isUncovered then
					workArea.isPrecisionFarmingDataUncovered = true
				end
			end
			if 0 < numValidSubSections then
				workArea.nitrogenLevel = math.ceil(workArea.nitrogenLevel / numValidSubSections)
				workArea.phLevel = math.ceil(workArea.phLevel / numValidSubSections)
				workArea.phTargetLevel = math.ceil(workArea.phTargetLevel / numValidSubSections)
				if 0 < numValidNTargetSections then
					workArea.nitrogenTargetLevel = math.ceil(workArea.nitrogenTargetLevel / numValidNTargetSections)
				end
				workArea.lastSpeed = MathUtil.round(workArea.lastSpeed / numValidSubSections)
			else
				for i = 1, workArea.numSubSections do
					local subSectionData = workArea.subSectionData[i]
					workArea.nitrogenLevel = workArea.nitrogenLevel + subSectionData.nitrogenLevel
					workArea.nitrogenLevelMax = math.max(workArea.nitrogenLevelMax, subSectionData.nitrogenLevel)
					workArea.nitrogenTargetLevel = workArea.nitrogenTargetLevel + subSectionData.nitrogenTargetLevel
					workArea.phLevel = workArea.phLevel + subSectionData.phLevel
					workArea.phLevelMax = math.max(workArea.phLevelMax, subSectionData.phLevel)
					workArea.phTargetLevel = workArea.phTargetLevel + subSectionData.phTargetLevel
					if subSectionData.fruitTypeIndex ~= nil and subSectionData.fruitTypeIndex ~= FruitType.UNKNOWN then
						workArea.fruitTypes[subSectionData.fruitTypeIndex] = workArea.fruitTypes[subSectionData.fruitTypeIndex] + 1
					end
					workArea.growthState = math.max(workArea.growthState, subSectionData.growthState)
					if subSectionData.soilTypeIndex == nil or subSectionData.soilTypeIndex == 0 then
						continue
					end
					workArea.soilTypes[subSectionData.soilTypeIndex] = workArea.soilTypes[subSectionData.soilTypeIndex] + 1
				end
				workArea.nitrogenLevel = math.ceil(workArea.nitrogenLevel / workArea.numSubSections)
				workArea.nitrogenTargetLevel = math.ceil(workArea.nitrogenTargetLevel / workArea.numSubSections)
				workArea.phLevel = math.ceil(workArea.phLevel / workArea.numSubSections)
				workArea.phTargetLevel = math.ceil(workArea.phTargetLevel / workArea.numSubSections)
			end
			local maxSoilTypeIndex = 0
			local maxSoilTypeCount = 0
			for index, count in ipairs(workArea.soilTypes) do
				if maxSoilTypeCount < count then
					maxSoilTypeIndex = index
					maxSoilTypeCount = count
				end
			end
			workArea.soilTypeIndex = maxSoilTypeIndex
			spec.lastTouchedSoilType = workArea.soilTypeIndex
			if self.spec_sowingMachine ~= nil then
				workArea.fruitTypeIndex = self.spec_sowingMachine.seeds[self.spec_sowingMachine.currentSeed]
			else
				local maxFruitTypeIndex = 0
				local maxFruitTypeCount = 0
				for index, count in ipairs(workArea.fruitTypes) do
					if maxFruitTypeCount < count then
						maxFruitTypeIndex = index
						maxFruitTypeCount = count
					end
				end
				workArea.fruitTypeIndex = maxFruitTypeIndex
				if workArea.fruitTypeIndex == FruitType.UNKNOWN then
					local fruitTypeIndex = spec.nApplyAutoModeFruitRequirementDefaultIndex
					local applicationRate, _ = spec.nitrogenMap:getNitrogenApplicationRate(workArea.nitrogenLevel, fruitTypeIndex, workArea.soilTypeIndex, sprayType)
					workArea.nitrogenTargetLevel = workArea.nitrogenLevel + (applicationRate or 0)
					for i = 1, workArea.numSubSections do
						local subSectionData = workArea.subSectionData[i]
						if subSectionData.isValid then
							subSectionData.nitrogenTargetLevel = workArea.nitrogenTargetLevel
							subSectionData.fruitTypeIndex = workArea.fruitTypeIndex
						end
					end
				end
			end
			if 0 < workArea.maxNApplicationOffset and workArea.nitrogenLevel < workArea.nitrogenTargetLevel then
				local difference = workArea.nitrogenLevelMax - workArea.nitrogenLevel
				if 0 < difference and difference <= workArea.maxNApplicationOffset + 0.01 then
					workArea.nitrogenLevel = workArea.nitrogenLevelMax
				end
			end
			if 0 < workArea.maxPHApplicationOffset and workArea.phLevel < workArea.phTargetLevel then
				local difference = workArea.phLevelMax - workArea.phLevel
				if 0 < difference and difference <= workArea.maxPHApplicationOffset + 0.01 then
					workArea.phLevel = workArea.phLevelMax
				end
			end
			for i = 1, workArea.numSubSections do
				local subSectionData = workArea.subSectionData[i]
				if subSectionData.isValid then
					continue
				end
				subSectionData.nitrogenLevel = workArea.nitrogenLevel
				subSectionData.nitrogenTargetLevel = workArea.nitrogenTargetLevel
				subSectionData.phLevel = workArea.phLevel
				subSectionData.phTargetLevel = workArea.phTargetLevel
				subSectionData.fruitTypeIndex = workArea.fruitTypeIndex
				subSectionData.soilTypeIndex = workArea.soilTypeIndex
			end
			if spec.lastTouchedSoilTypeSent ~= spec.lastTouchedSoilType then
				self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
				spec.lastTouchedSoilTypeSent = spec.lastTouchedSoilType
			end
			spec.phActualValue = workArea.phLevel
			spec.phTargetValue = spec.pHMap:getOptimalPHValueForSoilTypeIndex(workArea.soilTypeIndex) or workArea.phLevel
			if spec.phActualValue ~= spec.phActualValueSent or spec.phTargetValue ~= spec.phTargetValueSent then
				self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
				spec.phActualValueSent = spec.phActualValue
				spec.phTargetValueSent = spec.phTargetValue
			end
			spec.nActualValue = workArea.nitrogenLevel
			local nApplyAutoModeFruitType = FruitType.UNKNOWN
			if workArea.fruitTypeIndex ~= FruitType.UNKNOWN then
				local _, adjustedToFruitType = spec.nitrogenMap:getNitrogenApplicationRate(workArea.nitrogenLevel, workArea.fruitTypeIndex, workArea.soilTypeIndex, self.spec_sprayer.workAreaParameters.sprayType)
				if adjustedToFruitType then
					nApplyAutoModeFruitType = workArea.fruitTypeIndex
				end
			end
			spec.nTargetValue = workArea.nitrogenTargetLevel
			if spec.nActualValue ~= spec.nActualValueSent or spec.nTargetValue ~= spec.nTargetValueSent then
				self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
				spec.nActualValueSent = spec.nActualValue
				spec.nTargetValueSent = spec.nTargetValue
			end
			self:setSprayAmountAutoFruitTypeIndex(nApplyAutoModeFruitType)
			if spec.nApplyAutoModeFruitType ~= spec.nApplyAutoModeFruitTypeSent then
				self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
				spec.nApplyAutoModeFruitTypeSent = spec.nApplyAutoModeFruitType
			end
		end
	end
end
function ExtendedSprayer:processWorkAreaSubSectionData(workArea)
	if workArea.subSectionData ~= nil then
		local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local specSpray = self.spec_sprayer
		local sprayType = specSpray.workAreaParameters.sprayType
		local sprayVehicle = specSpray.workAreaParameters.sprayVehicle
		if sprayVehicle == nil then
			sprayVehicle = ExtendedSprayer.getFillTypeSourceVehicle(self)
		end
		local phDelta = 0
		if spec.isLiming then
			if not spec.sprayAmountAutoMode then
				phDelta = spec.sprayAmountManual
			elseif workArea.soilTypeIndex == 0 then
				phDelta = spec.pHMap:getDefaultLimeStateChange()
			else
				phDelta = math.max(spec.phTargetValue - workArea.phLevel, 0)
			end
			if phDelta == 0 and not spec.pwmEnabled then
				return
			end
		end
		local nitrogenDelta = 0
		if spec.isFertilizing then
			if not spec.sprayAmountAutoMode then
				nitrogenDelta = spec.sprayAmountManual
			elseif workArea.soilTypeIndex == 0 then
				nitrogenDelta = spec.nitrogenMap:getDefaultNitrogenStateChange()
			else
				nitrogenDelta = math.max(spec.nTargetValue - workArea.nitrogenLevel, 0)
			end
			if nitrogenDelta == 0 and not spec.pwmEnabled then
				return
			end
		end
		local speedLimit = self:getRawSpeedLimit()
		local processSubSectionPos = function(subSectionData, shape)
			if spec.isLiming then
				if spec.sprayAmountAutoMode then
					spec.pHMap:updatePHLevelAtArea(shape, sprayType, subSectionData.phTargetLevel)
				else
					spec.pHMap:addPHLevelAtArea(shape, sprayType, phDelta)
				end
			end
			if spec.isFertilizing then
				local levelOffset = 0
				if sprayVehicle.getCurrentNitrogenLevelOffset ~= nil then
					levelOffset = sprayVehicle:getCurrentNitrogenLevelOffset(subSectionData.nitrogenTargetLevel - subSectionData.nitrogenLevel)
				end
				if spec.pwmEnabled then
					if spec.sprayAmountAutoMode then
						spec.nitrogenMap:updateNitrogenLevelAtArea(shape, sprayType, subSectionData.nitrogenTargetLevel + levelOffset)
						return
					else
						spec.nitrogenMap:addNitrogenLevelAtArea(shape, sprayType, nitrogenDelta)
						return
					end
				end
				local speedDifference = 1
				if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
					speedDifference = math.min(1 / math.max(subSectionData.lastSpeed / speedLimit, 0.01), 2)
				end
				local applicationOffset = 0
				if spec.pHMap.realisticSpreadPatternEnabled then
					applicationOffset = subSectionData.nApplicationOffset
				end
				local subSectionDelta = MathUtil.round(nitrogenDelta * speedDifference) + levelOffset + applicationOffset
				subSectionDelta = math.max(subSectionDelta, 1)
				spec.nitrogenMap:addNitrogenLevelAtArea(shape, sprayType, subSectionDelta)
			end
		end
		local worldStartX, _, worldStartZ = getWorldTranslation(workArea.start)
		local worldWidthX, _, worldWidthZ = getWorldTranslation(workArea.width)
		local worldHeightX, _, worldHeightZ = getWorldTranslation(workArea.height)
		if workArea.numMainDivisions == 1 then
			local dirX = worldWidthX - worldStartX
			local dirZ = worldWidthZ - worldStartZ
			local width = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / width
			dirZ = dirZ / width
			local subSectionWidth = width / workArea.numSubDivisions
			for i = 1, workArea.numSubDivisions do
				local subSectionData = workArea.subSectionData[i]
				local sx = worldStartX + dirX * (i - 1) * subSectionWidth
				local sz = worldStartZ + dirZ * (i - 1) * subSectionWidth
				local wx = worldStartX + dirX * i * subSectionWidth
				local wz = worldStartZ + dirZ * i * subSectionWidth
				local hx = worldHeightX + dirX * (i - 1) * subSectionWidth
				local hz = worldHeightZ + dirZ * (i - 1) * subSectionWidth
				spec.densityMapParallelogram:updateFromWorldPositions(sx, sz, wx, wz, hx, hz)
				processSubSectionPos(subSectionData, spec.densityMapParallelogram)
			end
		else
			local cornerX = worldStartX + (worldWidthX - worldStartX) + (worldHeightX - worldStartX)
			local cornerZ = worldStartZ + (worldWidthZ - worldStartZ) + (worldHeightZ - worldStartZ)
			local cornerDirX = worldWidthX - cornerX
			local cornerDirZ = worldWidthZ - cornerZ
			local cornerDistance = MathUtil.vector2Length(cornerDirX, cornerDirZ)
			cornerDirX = cornerDirX / cornerDistance
			cornerDirZ = cornerDirZ / cornerDistance
			local widthDirX = worldWidthX - worldStartX
			local widthDirZ = worldWidthZ - worldStartZ
			local width1 = MathUtil.vector2Length(widthDirX, widthDirZ)
			widthDirX = widthDirX / width1
			widthDirZ = widthDirZ / width1
			local subSectionWidth1 = width1 / workArea.numSubDivisions
			local subSectionWidth2 = cornerDistance / workArea.numSubDivisions
			for i = 1, workArea.numSubDivisions do
				local x1 = worldStartX + widthDirX * i * subSectionWidth1
				local z1 = worldStartZ + widthDirZ * i * subSectionWidth1
				local x2 = worldStartX + widthDirX * (i - 1) * subSectionWidth1
				local z2 = worldStartZ + widthDirZ * (i - 1) * subSectionWidth1
				local x3 = cornerX + cornerDirX * (i - 1) * subSectionWidth2
				local z3 = cornerZ + cornerDirZ * (i - 1) * subSectionWidth2
				local x4 = cornerX + cornerDirX * i * subSectionWidth2
				local z4 = cornerZ + cornerDirZ * i * subSectionWidth2
				spec.densityMapPolygon:setPolygonPoint(1, x1, z1)
				spec.densityMapPolygon:setPolygonPoint(2, x2, z2)
				spec.densityMapPolygon:setPolygonPoint(3, x3, z3)
				spec.densityMapPolygon:setPolygonPoint(4, x4, z4)
				local subSectionData = workArea.subSectionData[i]
				processSubSectionPos(subSectionData, spec.densityMapPolygon)
			end
			local heightDirX = worldHeightX - worldStartX
			local heightDirZ = worldHeightZ - worldStartZ
			local width2 = MathUtil.vector2Length(heightDirX, heightDirZ)
			heightDirX = heightDirX / width2
			heightDirZ = heightDirZ / width2
			cornerDirX = worldHeightX - cornerX
			cornerDirZ = worldHeightZ - cornerZ
			cornerDistance = MathUtil.vector2Length(cornerDirX, cornerDirZ)
			cornerDirX = cornerDirX / cornerDistance
			cornerDirZ = cornerDirZ / cornerDistance
			subSectionWidth1 = width2 / workArea.numSubDivisions
			subSectionWidth2 = cornerDistance / workArea.numSubDivisions
			for i = 1, workArea.numSubDivisions do
				local x1 = worldStartX + heightDirX * i * subSectionWidth1
				local z1 = worldStartZ + heightDirZ * i * subSectionWidth1
				local x2 = worldStartX + heightDirX * (i - 1) * subSectionWidth1
				local z2 = worldStartZ + heightDirZ * (i - 1) * subSectionWidth1
				local x3 = cornerX + cornerDirX * (i - 1) * subSectionWidth2
				local z3 = cornerZ + cornerDirZ * (i - 1) * subSectionWidth2
				local x4 = cornerX + cornerDirX * i * subSectionWidth2
				local z4 = cornerZ + cornerDirZ * i * subSectionWidth2
				spec.densityMapPolygon:setPolygonPoint(1, x1, z1)
				spec.densityMapPolygon:setPolygonPoint(2, x2, z2)
				spec.densityMapPolygon:setPolygonPoint(3, x3, z3)
				spec.densityMapPolygon:setPolygonPoint(4, x4, z4)
				local subSectionData = workArea.subSectionData[i + workArea.numSubDivisions]
				processSubSectionPos(subSectionData, spec.densityMapPolygon)
			end
		end
	end
end
function ExtendedSprayer:getSprayerUsage(superFunc, fillType, dt)
	local usage = superFunc(self, fillType, dt)
	if self:getIsTurnedOn() then
		local specSpray = self.spec_sprayer
		local usageScale = specSpray.usageScale
		local activeSprayType = self:getActiveSprayType()
		if activeSprayType ~= nil then
			usageScale = activeSprayType.usageScale
		end
		local workWidth = nil
		if usageScale.workAreaIndex ~= nil then
			workWidth = self:getWorkAreaWidth(usageScale.workAreaIndex)
		else
			workWidth = usageScale.workingWidth
		end
		local lastSpeed = math.max(self:getLastSpeed(), 1)
		local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local dataUncovered = false
		for _, workArea in pairs(spec.workAreas) do
			if workArea.isPrecisionFarmingDataUncovered then
				dataUncovered = true
				break
			end
		end
		local minRate = spec.sprayAmountAutoMode and 0 or 1
		if spec.isLiming then
			if spec.pHMap ~= nil then
				local changeValue = nil
				if spec.sprayAmountAutoMode then
					if spec.pwmEnabled then
						local accumulatedChange = 0
						local numSections = 0
						for _, workArea in pairs(spec.workAreas) do
							if 0 < workArea.numSubSections then
								for _, subSectionData in ipairs(workArea.subSectionData) do
									accumulatedChange = accumulatedChange + math.max(subSectionData.phTargetLevel - subSectionData.phLevel, 0)
									numSections = numSections + 1
								end
							end
						end
						changeValue = 0 < numSections and accumulatedChange / numSections or 0
					else
						changeValue = math.ceil(spec.phTargetValue - spec.phActualValue)
						if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
							lastSpeed = self:getRawSpeedLimit()
						end
					end
					if not dataUncovered then
						changeValue = spec.pHMap:getDefaultLimeStateChange()
					end
				else
					changeValue = math.max(spec.sprayAmountManual, 1)
					if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
						lastSpeed = self:getRawSpeedLimit()
					end
				end
				if self.getNumExtendedSprayerNozzleEffectsActive ~= nil then
					local _, alpha = self:getNumExtendedSprayerNozzleEffectsActive()
					changeValue = changeValue * alpha
				end
				local litersPerUpdate, literPerHectar, regularUsage = spec.pHMap:getLimeUsage(workWidth, lastSpeed, changeValue, dt)
				spec.lastRegularUsage = regularUsage
				usage = litersPerUpdate
				spec.lastLitersPerHectar = literPerHectar
				spec.lastNitrogenProportion = 0
			end
		elseif spec.isFertilizing then
			if spec.nitrogenMap ~= nil then
				if not spec.isDoingMissionWork then
					local sprayVehicle = specSpray.workAreaParameters.sprayVehicle
					if sprayVehicle == nil then
						sprayVehicle = ExtendedSprayer.getFillTypeSourceVehicle(self)
					end
					local changeValue = nil
					if spec.sprayAmountAutoMode then
						if spec.pwmEnabled then
							local accumulatedChange = 0
							local numSections = 0
							for _, workArea in pairs(spec.sprayerWorkAreas) do
								if 0 < workArea.numSubSections then
									for _, subSectionData in ipairs(workArea.subSectionData) do
										accumulatedChange = accumulatedChange + math.max(subSectionData.nitrogenTargetLevel - subSectionData.nitrogenLevel, 0)
										numSections = numSections + 1
									end
								end
							end
							for _, workArea in pairs(spec.sowingMachineWorkAreas) do
								if 0 < workArea.numSubSections then
									for _, subSectionData in ipairs(workArea.subSectionData) do
										accumulatedChange = accumulatedChange + math.max(subSectionData.nitrogenTargetLevel - subSectionData.nitrogenLevel, 0)
										numSections = numSections + 1
									end
								end
							end
							changeValue = 0 < numSections and accumulatedChange / numSections or 0
						else
							changeValue = math.ceil(spec.nTargetValue - spec.nActualValue)
							if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
								lastSpeed = self:getRawSpeedLimit()
							end
						end
						if not dataUncovered then
							changeValue = spec.nitrogenMap:getDefaultNitrogenStateChange()
						end
					else
						changeValue = math.max(spec.sprayAmountManual, 1)
						if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
							lastSpeed = self:getRawSpeedLimit()
						end
					end
					if self.getNumExtendedSprayerNozzleEffectsActive ~= nil then
						local _, alpha = self:getNumExtendedSprayerNozzleEffectsActive()
						changeValue = changeValue * alpha
					end
					local nitrogenUsageLevelOffset = sprayVehicle ~= nil and sprayVehicle.getCurrentNitrogenUsageLevelOffset ~= nil and sprayVehicle:getCurrentNitrogenUsageLevelOffset(changeValue) or 0
					local litersPerUpdate, literPerHectar, regularUsage, nitrogenProportion = spec.nitrogenMap:getFertilizerUsage(workWidth, lastSpeed, math.max(changeValue, minRate), fillType, dt, spec.sprayAmountAutoMode, spec.nApplyAutoModeFruitType, spec.nActualValue, nitrogenUsageLevelOffset)
					spec.lastRegularUsage = regularUsage
					usage = litersPerUpdate
					spec.lastLitersPerHectar = literPerHectar
					spec.lastNitrogenProportion = nitrogenProportion
				else
					spec.lastRegularUsage = usage
					spec.lastLitersPerHectar = usage / dt * (10000 / workWidth) / (self.speedLimit / 3600)
					spec.lastNitrogenProportion = 0
				end
			end
		end
		if self:getIsAIActive() and usage == 0 then
			usage = 0.0001
		end
	end
	return usage
end
function ExtendedSprayer:processSprayerArea(superFunc, workArea, dt)
	local specSpray = self.spec_sprayer
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if specSpray.workAreaParameters.sprayFillLevel <= 0 then
		return superFunc(self, workArea, dt)
	end
	if not spec.isLiming and not spec.isFertilizing then
		return superFunc(self, workArea, dt)
	end
	local sx, _, sz = getWorldTranslation(workArea.start)
	local wx, _, wz = getWorldTranslation(workArea.width)
	local hx, _, hz = getWorldTranslation(workArea.height)
	if self.isServer then
		if specSpray.workAreaParameters.sprayType ~= workArea.lastSprayTypeIndex then
			workArea.lastSprayTypeIndex = specSpray.workAreaParameters.sprayType
			self:updateWorkAreaSubSectionData(workArea)
		end
		spec.densityMapParallelogram:updateFromWorldPositions(sx, sz, wx, wz, hx, hz)
		if spec.isLiming then
			spec.pHMap:preUpdatePHLevelAtArea(spec.densityMapParallelogram, specSpray.workAreaParameters.sprayType)
		end
		if spec.isFertilizing then
			spec.nitrogenMap:preUpdateNitrogenLevelAtArea(spec.densityMapParallelogram, specSpray.workAreaParameters.sprayType)
		end
		self:processWorkAreaSubSectionData(workArea)
		local changedArea = 0
		local totalArea = 0
		if self:getIsPrecisionSprayingRequired() then
			changedArea, totalArea = superFunc(self, workArea, dt)
			if 0 < changedArea then
				spec.nitrogenMap:setMinimapRequiresUpdate(true)
			end
		end
		local desc = g_sprayTypeManager:getSprayTypeByIndex(specSpray.workAreaParameters.sprayType)
		if desc ~= nil then
			FSDensityMapUtil.setGroundTypeLayerArea(sx, sz, wx, wz, hx, hz, desc.sprayGroundType)
		end
		return changedArea, totalArea
	else
		local changedArea = 0
		local totalArea = 0
		if self:getIsPrecisionSprayingRequired() then
			changedArea, totalArea = superFunc(self, workArea, dt)
			if 0 < changedArea then
				spec.nitrogenMap:setMinimapRequiresUpdate(true)
			end
		end
		local desc = g_sprayTypeManager:getSprayTypeByIndex(specSpray.workAreaParameters.sprayType)
		if desc ~= nil then
			FSDensityMapUtil.setGroundTypeLayerArea(sx, sz, wx, wz, hx, hz, desc.sprayGroundType)
		end
		return changedArea, totalArea
	end
end
function ExtendedSprayer:changeSeedIndex(superFunc, ...)
	superFunc(self, ...)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	spec.lastGroundUpdateDistance = math.huge
end
function ExtendedSprayer:getSprayerDoubledAmountActive(superFunc, sprayTypeIndex)
	return false, false
end
function ExtendedSprayer:updateSprayerEffects(superFunc, force) end
function ExtendedSprayer:updateExtendedSprayerNozzleEffectState(superFunc, effectData, dt, isTurnedOn, lastSpeed)
	local isActive, amountScale = superFunc(self, effectData, dt, isTurnedOn, lastSpeed)
	if isActive then
		local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
		if (spec.pwmEnabled or spec.spotSprayEnabled) and (spec.isLiming or spec.isFertilizing) then
			local x, y, z = localToWorld(effectData.effectNode, 0, 0, 1)
			local densityBitsGround = getDensityAtWorldPos(spec.groundTypeMapId, x, y, z)
			local groundTypeValue = bit32.band(bit32.rshift(densityBitsGround, spec.groundTypeFirstChannel), 2 ^ spec.groundTypeNumChannels - 1)
			local groundType = FieldGroundType.getTypeByValue(groundTypeValue)
			if groundType == FieldGroundType.NONE then
				isActive = false
			end
		end
	end
	return isActive, amountScale
end
function ExtendedSprayer:setSprayerAITerrainDetailProhibitedRange(superFunc, fillType)
	superFunc(self, fillType)
	if self:getUseSprayerAIRequirements() and self.addAITerrainDetailProhibitedRange ~= nil then
		self:clearAIFruitProhibitions()
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
		if sprayTypeDesc ~= nil then
			if sprayTypeDesc.isFertilizer then
				local mission = g_currentMission
				local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
				self:addAIFruitProhibitions(0, sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
			elseif sprayTypeDesc.isLime then
				local mission = g_currentMission
				local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
				self:addAIFruitProhibitions(0, sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
			end
			if sprayTypeDesc.isHerbicide or sprayTypeDesc.isFertilizer or sprayTypeDesc.isLime then
				for _, fruitType in pairs(g_fruitTypeManager:getFruitTypes()) do
					if fruitType.terrainDataPlaneId == nil or string.lower(fruitType.name) == "grass" or fruitType.minHarvestingGrowthState == nil or fruitType.maxHarvestingGrowthState == nil then
						continue
					end
					self:addAIFruitProhibitions(fruitType.index, fruitType.minHarvestingGrowthState, fruitType.maxHarvestingGrowthState)
				end
			end
		end
	end
end
function ExtendedSprayer:preProcessExtUnderRootFertilizerArea(workArea, dt)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if self.isServer then
		local sx, _, sz = getWorldTranslation(workArea.start)
		local wx, _, wz = getWorldTranslation(workArea.width)
		local hx, _, hz = getWorldTranslation(workArea.height)
		if spec.nitrogenMap ~= nil then
			spec.densityMapParallelogram:updateFromWorldPositions(sx, sz, wx, wz, hx, hz)
			local sprayTypeIndex = SprayType.FERTILIZER
			spec.nitrogenMap:preUpdateNitrogenLevelAtArea(spec.densityMapParallelogram, sprayTypeIndex)
			self:processWorkAreaSubSectionData(workArea)
		end
	end
end
function ExtendedSprayer:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local specSprayer = self.spec_sprayer
	if self.isServer and specSprayer.workAreaParameters.isActive then
		local sprayVehicle = specSprayer.workAreaParameters.sprayVehicle
		local usage = specSprayer.workAreaParameters.usage
		local fillType = specSprayer.workAreaParameters.sprayFillType
		if (sprayVehicle ~= nil or self:getIsAIActive()) and self:getIsTurnedOn() then
			local usageRegular = spec.lastRegularUsage
			if fillType == FillType.LIME then
				self:updatePFStatistic("usedLime", usage)
				self:updatePFStatistic("usedLimeRegular", usageRegular)
				return
			end
			if fillType == FillType.FERTILIZER then
				self:updatePFStatistic("usedMineralFertilizer", usage)
				self:updatePFStatistic("usedMineralFertilizerRegular", usageRegular)
				return
			end
			if fillType == FillType.LIQUIDFERTILIZER then
				self:updatePFStatistic("usedLiquidFertilizer", usage)
				self:updatePFStatistic("usedLiquidFertilizerRegular", usageRegular)
				return
			end
			if fillType == FillType.MANURE then
				self:updatePFStatistic("usedManure", usage)
				self:updatePFStatistic("usedManureRegular", usageRegular)
				return
			end
			if fillType == FillType.LIQUIDMANURE or fillType == FillType.DIGESTATE then
				self:updatePFStatistic("usedLiquidManure", usage)
				self:updatePFStatistic("usedLiquidManureRegular", usageRegular)
			end
		end
	end
end
function ExtendedSprayer:setSprayAmountAutoMode(state, noEventSend)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if state == nil then
		state = not spec.sprayAmountAutoMode
	end
	if not spec.sprayAmountAutoModeChangeAllowed then
		state = false
	end
	spec.sprayAmountAutoMode = state
	ExtendedSprayer.updateActionEventState(self)
	ExtendedSprayer.updateActionEventAutoModeDefault(self)
	ExtendedSprayerAmountEvent.sendEvent(self, spec.sprayAmountAutoMode, spec.sprayAmountManual, noEventSend)
end
function ExtendedSprayer:setSprayAmountManualValue(value, noEventSend)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	spec.sprayAmountManual = math.clamp(value, spec.sprayAmountManualMin, spec.sprayAmountManualMax)
	ExtendedSprayer.updateActionEventState(self)
	ExtendedSprayerAmountEvent.sendEvent(self, spec.sprayAmountAutoMode, spec.sprayAmountManual, noEventSend)
end
function ExtendedSprayer:setSprayAmountAutoFruitTypeIndex(index)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if index ~= spec.nApplyAutoModeFruitType then
		spec.nApplyAutoModeFruitType = index
		spec.nApplyAutoModeFruitTypeRequiresDefaultMode = spec.nitrogenMap:getFruitTypeRequirementRequiresDefaultMode(index)
		ExtendedSprayer.updateActionEventAutoModeDefault(self)
	end
end
function ExtendedSprayer:setSprayAmountDefaultFruitRequirementIndex(index, noEventSend)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	spec.nApplyAutoModeFruitRequirementDefaultIndex = index
	spec.lastGroundUpdateDistance = math.huge
	ExtendedSprayerDefaultFruitTypeEvent.sendEvent(self, index, noEventSend)
end
function ExtendedSprayer:updateDebugValues(values)
	local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local addWorkArea = function(workArea, name)
		if workArea.subSectionData ~= nil then
			local nitrogenValue = spec.nitrogenMap:getNitrogenValueFromInternalValue(workArea.nitrogenLevel)
			local nitrogenTargetValue = spec.nitrogenMap:getNitrogenValueFromInternalValue(workArea.nitrogenTargetLevel)
			local phValue = spec.pHMap:getPhValueFromInternalValue(workArea.phLevel)
			local phTargetValue = spec.pHMap:getPhValueFromInternalValue(workArea.phTargetLevel)
			local fruitTypeName = g_fruitTypeManager:getFruitTypeNameByIndex(workArea.fruitTypeIndex)
			local soilTypeName = nil
			local soilType = spec.soilMap:getSoilTypeByIndex(workArea.soilTypeIndex)
			soilTypeName = soilType ~= nil and soilType.name or "Unknown"
			table.insert(values, { name = string.format("Detected (%s)", name), value = string.format("N %dkg pH %.3f FruitType: %s|%d Soil: %s (Target: N: %dkg | pH %.3f)", nitrogenValue, phValue, fruitTypeName, workArea.growthState, soilTypeName, nitrogenTargetValue, phTargetValue) })
			for subSectionDataIndex, subSectionData in ipairs(workArea.subSectionData) do
				fruitTypeName = g_fruitTypeManager:getFruitTypeNameByIndex(subSectionData.fruitTypeIndex)
				nitrogenValue = spec.nitrogenMap:getNitrogenValueFromInternalValue(subSectionData.nitrogenLevel)
				nitrogenTargetValue = spec.nitrogenMap:getNitrogenValueFromInternalValue(subSectionData.nitrogenTargetLevel)
				phValue = spec.pHMap:getPhValueFromInternalValue(subSectionData.phLevel)
				phTargetValue = spec.pHMap:getPhValueFromInternalValue(subSectionData.phTargetLevel)
				soilType = spec.soilMap:getSoilTypeByIndex(subSectionData.soilTypeIndex)
				soilTypeName = soilType ~= nil and soilType.name or "Unknown"
				table.insert(values, { name = string.format("Sub Section %d", subSectionDataIndex), value = string.format("%dkg/%dkg pH %.3f/%.3f FruitType: %s|%d Soil: %s Speed: %.2fkm/h (%s)", nitrogenValue, nitrogenTargetValue, phValue, phTargetValue, fruitTypeName, subSectionData.growthState, soilTypeName, subSectionData.lastSpeed, subSectionData.isValid and "Valid" or "Invalid") })
			end
		end
	end
	for i, workArea in pairs(spec.sprayerWorkAreas) do
		local isAllowed = true
		if workArea.sprayType ~= nil then
			local sprayType = self:getActiveSprayType()
			if sprayType ~= nil and sprayType.index ~= workArea.sprayType then
				isAllowed = false
			end
		end
		if isAllowed then
			addWorkArea(workArea, "SPRAYER" .. tostring(i))
		end
	end
	for i, workArea in pairs(spec.sowingMachineWorkAreas) do
		addWorkArea(workArea, "SOWINGMACHINE" .. tostring(i))
	end
	for i, workArea in pairs(spec.cultivatorWorkAreas) do
		addWorkArea(workArea, "CULTIVATOR" .. tostring(i))
	end
end
