source("dataS/scripts/vehicles/specializations/events/SetSeedIndexEvent.lua")
SowingMachine = {}
SowingMachine.DAMAGED_USAGE_INCREASE = 0.3
SowingMachine.AI_REQUIRED_GROUND_TYPES = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.CULTIVATED,
	FieldGroundType.SEEDBED,
	FieldGroundType.PLOWED,
	FieldGroundType.ROLLED_SEEDBED,
	FieldGroundType.RIDGE
}
SowingMachine.AI_OUTPUT_GROUND_TYPES = {
	FieldGroundType.SOWN,
	FieldGroundType.DIRECT_SOWN,
	FieldGroundType.PLANTED,
	FieldGroundType.RIDGE_SOWN,
	FieldGroundType.ROLLER_LINES,
	FieldGroundType.HARVEST_READY,
	FieldGroundType.HARVEST_READY_OTHER,
	FieldGroundType.GRASS,
	FieldGroundType.GRASS_CUT
}
SowingMachine.CLIENT_DM_UPDATE_RADIUS = 50
function SowingMachine.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("sowingMachine", true, true, true)
	g_storeManager:addSpecType("seedFillTypes", "shopListAttributeIconSeeds", SowingMachine.loadSpecValueSeedFillTypes, SowingMachine.getSpecValueSeedFillTypes, StoreSpecies.VEHICLE)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("SowingMachine")
	v1_:register(XMLValueType.BOOL, "vehicle.sowingMachine.allowFillFromAirWhileTurnedOn#value", "Allow fill from air while turned on")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.sowingMachine.directionNode#node", "Direction node")
	v1_:register(XMLValueType.BOOL, "vehicle.sowingMachine.useDirectPlanting#value", "Use direct planting", false)
	v1_:register(XMLValueType.BOOL, "vehicle.sowingMachine.waterSeeding#value", "Seeding in water is required or prohibited (false: prohibited, true: required)", false)
	v1_:register(XMLValueType.STRING, "vehicle.sowingMachine.seedFruitTypeCategories", "Seed fruit type categories")
	v1_:register(XMLValueType.STRING, "vehicle.sowingMachine.seedFruitTypes", "Seed fruit types")
	v1_:register(XMLValueType.STRING, "vehicle.sowingMachine.seedFillType", "Name of seeds fill type to use", "SEEDS")
	v1_:register(XMLValueType.BOOL, "vehicle.sowingMachine.needsActivation#value", "Needs activation", false)
	v1_:register(XMLValueType.BOOL, "vehicle.sowingMachine.requiresFilling#value", "Requires filling", true)
	v1_:register(XMLValueType.STRING, "vehicle.sowingMachine.fieldGroundType#value", "Defines the field ground type", "SOWN")
	v1_:register(XMLValueType.BOOL, "vehicle.sowingMachine.fieldGroundType#ridgeSeeding", "Defines if the sowing machine can seed into created ridges or destroys them", false)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.sowingMachine.sounds", "work(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.sowingMachine.sounds", "airBlower(?)")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.sowingMachine.animationNodes")
	v1_:register(XMLValueType.STRING, "vehicle.sowingMachine.changeSeedInputButton", "Input action name", "IMPLEMENT_EXTRA3")
	v1_:register(XMLValueType.INT, "vehicle.sowingMachine#fillUnitIndex", "Fill unit index", 1)
	v1_:register(XMLValueType.INT, "vehicle.sowingMachine#unloadInfoIndex", "Unload info index", 1)
	v1_:register(XMLValueType.STRING, "vehicle.sowingMachine#defaultFruitType", "Name if fruit type that is selected by default")
	v1_:register(XMLValueType.STRING, "vehicle.sowingMachine#consumableName", "Define a consumable that is emptied instead of the fill unit")
	v1_:register(XMLValueType.FLOAT, "vehicle.sowingMachine#seedUsageScale", "Seed usage scale (Can be used to increase or decrease the usage for certain tools)", 1)
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.sowingMachine.effects")
	v1_:register(XMLValueType.STRING, "vehicle.storeData.specs.seedFruitTypeCategories", "Seed fruit type categories")
	v1_:register(XMLValueType.STRING, "vehicle.storeData.specs.seedFruitTypes", "Seed fruit types")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.STRING, "vehicles.vehicle(?).sowingMachine#selectedSeedFruitType", "Selected fruit type name")
	v2_:register(XMLValueType.BOOL, "vehicles.vehicle(?).sowingMachine#allowsSeedChanging", "If seed change is allowed")
end

function SowingMachine.prerequisitesPresent(specializations)
	local v4_ = SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations)
	if v4_ then
		v4_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
	return v4_
end

function SowingMachine.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setSeedFruitType", SowingMachine.setSeedFruitType)
	SpecializationUtil.registerFunction(vehicleType, "setSeedIndex", SowingMachine.setSeedIndex)
	SpecializationUtil.registerFunction(vehicleType, "changeSeedIndex", SowingMachine.changeSeedIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsSeedChangeAllowed", SowingMachine.getIsSeedChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setIsSeedChangeAllowed", SowingMachine.setIsSeedChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getSowingMachineFillUnitIndex", SowingMachine.getSowingMachineFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "getSowingMachineSeedFillTypeIndex", SowingMachine.getSowingMachineSeedFillTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSeedTypeIcon", SowingMachine.getCurrentSeedTypeIcon)
	SpecializationUtil.registerFunction(vehicleType, "processSowingMachineArea", SowingMachine.processSowingMachineArea)
	SpecializationUtil.registerFunction(vehicleType, "getUseSowingMachineAIRequirements", SowingMachine.getUseSowingMachineAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "setFillTypeSourceDisplayFillType", SowingMachine.setFillTypeSourceDisplayFillType)
	SpecializationUtil.registerFunction(vehicleType, "updateMissionSowingWarning", SowingMachine.updateMissionSowingWarning)
	SpecializationUtil.registerFunction(vehicleType, "getCanPlantOutsideSeason", SowingMachine.getCanPlantOutsideSeason)
	SpecializationUtil.registerFunction(vehicleType, "getSowingMachineCanConsume", SowingMachine.getSowingMachineCanConsume)
end

function SowingMachine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", SowingMachine.getDrawFirstFillText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", SowingMachine.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", SowingMachine.getFillUnitAllowsFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", SowingMachine.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", SowingMachine.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowFillFromAir", SowingMachine.getAllowFillFromAir)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle", SowingMachine.getDirectionSnapAngle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", SowingMachine.addFillUnitFillLevel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SowingMachine.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", SowingMachine.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", SowingMachine.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", SowingMachine.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", SowingMachine.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", SowingMachine.getCanAIImplementContinueWork)
end

function SowingMachine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", SowingMachine)
end

-- Local values: spec, fruitTypeIndices, fruitTypeCategories, fruitTypeNames, _, fruitTypeIndex, seedFillType, changeSeedInputButtonStr, selectedSeedFruitType, fruitTypeDesc, defaultSeedFruitType, fruitTypeDesc
function SowingMachine:onLoad(savegame)
	local v10_ = self.spec_sowingMachine
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.sowingMachine.animationNodes.animationNode", "sowingMachine")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnScrollers", "vehicle.sowingMachine.scrollerNodes.scrollerNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.useDirectPlanting", "vehicle.sowingMachine.useDirectPlanting#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.needsActivation#value", "vehicle.sowingMachine.needsActivation#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingEffects", "vehicle.sowingMachine.effects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingEffectsWithFixedFillType", "vehicle.sowingMachine.fixedEffects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingMachine#supportsAiWithoutSowingMachine", "vehicle.turnOnVehicle.aiRequiresTurnOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingMachine.directionNode#index", "vehicle.sowingMachine.directionNode#node")
	v10_.allowFillFromAirWhileTurnedOn = self.xmlFile:getValue("vehicle.sowingMachine.allowFillFromAirWhileTurnedOn#value", true)
	v10_.directionNode = self.xmlFile:getValue("vehicle.sowingMachine.directionNode#node", self.components[1].node, self.components, self.i3dMappings)
	v10_.useDirectPlanting = self.xmlFile:getValue("vehicle.sowingMachine.useDirectPlanting#value", false)
	v10_.waterSeeding = self.xmlFile:getValue("vehicle.sowingMachine.waterSeeding#value", false)
	v10_.isWorking = false
	v10_.isProcessing = false
	v10_.stoneLastState = 0
	v10_.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("SOWINGMACHINE")
	v10_.seeds = {}
	local v11_ = {}
	local v12_ = self.xmlFile:getValue("vehicle.sowingMachine.seedFruitTypeCategories")
	local v13_ = self.xmlFile:getValue("vehicle.sowingMachine.seedFruitTypes")
	if v12_ == nil or v13_ ~= nil then
		if v12_ == nil and v13_ ~= nil then
			v11_ = g_fruitTypeManager:getFruitTypeIndicesByNames(v13_, "Warning: \'" .. self.configFileName .. "\' has invalid fruitType \'%s\'.")
		else
			printWarning("Warning: \'" .. self.configFileName .. "\' a sowingMachine needs either the \'seedFruitTypeCategories\' or \'seedFruitTypes\' element.")
		end
	else
		v11_ = g_fruitTypeManager:getFruitTypeIndicesByCategoryNames(v12_, "Warning: \'" .. self.configFileName .. "\' has invalid fruitTypeCategory \'%s\'.")
	end
	if v11_ ~= nil then
		for _, v14_ in pairs(v11_) do
			local v15_ = v10_.seeds
			table.insert(v15_, v14_)
		end
	end
	local v16_ = self.xmlFile:getValue("vehicle.sowingMachine.seedFillType", "SEEDS")
	v10_.seedFillType = FillType[v16_] or FillType.SEEDS
	v10_.needsActivation = self.xmlFile:getValue("vehicle.sowingMachine.needsActivation#value", false)
	v10_.requiresFilling = self.xmlFile:getValue("vehicle.sowingMachine.requiresFilling#value", true)
	v10_.fieldGroundType = FieldGroundType.getValueByName(self.xmlFile:getValue("vehicle.sowingMachine.fieldGroundType#value", "SOWN"))
	v10_.ridgeSeeding = self.xmlFile:getValue("vehicle.sowingMachine.fieldGroundType#ridgeSeeding", false)
	if v10_.fieldGroundType == FieldGroundType.getValueByName("RIDGE") then
		v10_.fieldGroundType = FieldGroundType.getValueByName("RIDGE_SOWN")
	end
	if self.isClient then
		v10_.isWorkSamplePlaying = false
		v10_.samples = {}
		v10_.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.sowingMachine.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v10_.samples.airBlower = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.sowingMachine.sounds", "airBlower", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v10_.sampleFillEnabled = false
		v10_.sampleFillStopTime = -1
		v10_.lastFillLevel = -1
		v10_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.sowingMachine.animationNodes", self.components, self, self.i3dMappings)
		g_animationManager:setFillType(v10_.animationNodes, FillType.UNKNOWN)
		local v17_ = self.xmlFile:getValue("vehicle.sowingMachine.changeSeedInputButton")
		if v17_ ~= nil then
			v10_.changeSeedInputButton = InputAction[v17_]
		end
		v10_.changeSeedInputButton = Utils.getNoNil(v10_.changeSeedInputButton, InputAction.TOGGLE_SEEDS)
	end
	v10_.currentSeed = 1
	v10_.allowsSeedChanging = true
	v10_.showFruitCanNotBePlantedWarning = false
	v10_.showWrongFruitForMissionWarning = false
	v10_.showWaterPlantingRequiredWarning = false
	v10_.showWaterPlantingProhibitedWarning = false
	v10_.showFieldTypeWarningRegularRequired = false
	v10_.showFieldTypeWarningRiceRequired = false
	v10_.warnings = {}
	v10_.warnings.fruitCanNotBePlanted = g_i18n:getText("warning_theSelectedFruitTypeIsNotAvailableOnThisMap")
	v10_.warnings.wrongFruitForMission = g_i18n:getText("warning_theSelectedFruitTypeIsWrongForTheMission")
	v10_.warnings.wrongPlantingTime = g_i18n:getText("warning_theSelectedFruitTypeCantBePlantedInThisPeriod")
	v10_.fillUnitIndex = self.xmlFile:getValue("vehicle.sowingMachine#fillUnitIndex", 1)
	v10_.unloadInfoIndex = self.xmlFile:getValue("vehicle.sowingMachine#unloadInfoIndex", 1)
	v10_.consumableName = self.xmlFile:getValue("vehicle.sowingMachine#consumableName")
	if v10_.consumableName ~= nil and self.updateConsumable == nil then
		Logging.xmlWarning("Sowing machine has consumableName \'%s\' attribute defined but has no consumable specialization!", v10_.consumableName)
		v10_.consumableName = nil
	end
	v10_.seedUsageScale = self.xmlFile:getValue("vehicle.sowingMachine#seedUsageScale", 1)
	if self:getFillUnitByIndex(v10_.fillUnitIndex) == nil then
		Logging.xmlError(self.xmlFile, "FillUnit \'%d\' not defined!", v10_.fillUnitIndex)
		self:setLoadingState(VehicleLoadingState.ERROR)
	else
		v10_.fillTypeSources = {}
		if self.isClient then
			v10_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.sowingMachine.effects", self.components, self, self.i3dMappings)
		end
		v10_.workAreaParameters = {}
		v10_.workAreaParameters.seedsFruitType = nil
		v10_.workAreaParameters.angle = 0
		v10_.workAreaParameters.lastChangedArea = 0
		v10_.workAreaParameters.lastStatsArea = 0
		v10_.workAreaParameters.lastArea = 0
		self:setSeedIndex(1, true)
		if savegame == nil then
			local v18_ = self.xmlFile:getValue("vehicle.sowingMachine#defaultFruitType")
			if v18_ ~= nil then
				local v19_ = g_fruitTypeManager:getFruitTypeByName(v18_)
				if v19_ ~= nil then
					self:setSeedFruitType(v19_.index, true)
				end
			end
		else
			local v20_ = savegame.xmlFile:getValue(savegame.key .. ".sowingMachine#selectedSeedFruitType")
			if v20_ ~= nil then
				local v21_ = g_fruitTypeManager:getFruitTypeByName(v20_)
				if v21_ ~= nil then
					self:setSeedFruitType(v21_.index, true)
				end
			end
			v10_.allowsSeedChanging = savegame.xmlFile:getValue(savegame.key .. ".sowingMachine#allowsSeedChanging", v10_.allowsSeedChanging)
		end
		if not self.isClient then
			SpecializationUtil.removeEventListener(self, "onUpdate", SowingMachine)
			SpecializationUtil.removeEventListener(self, "onUpdateTick", SowingMachine)
		end
		self.needWaterInfo = true
	end
end

function SowingMachine:onPostLoad(savegame)
	SowingMachine.updateAiParameters(self)
end

-- Local values: spec
function SowingMachine:onDelete()
	if self.isClient then
		local v24_ = self.spec_sowingMachine
		if v24_.samples ~= nil then
			g_soundManager:deleteSamples(v24_.samples.work)
			g_soundManager:deleteSamples(v24_.samples.airBlower)
		end
		g_effectManager:deleteEffects(v24_.effects)
		g_animationManager:deleteAnimations(v24_.animationNodes)
	end
end

-- Local values: spec, selectedSeedFruitTypeName, selectedSeedFruitType, fruitType
function SowingMachine:saveToXMLFile(xmlFile, key, usedModNames)
	local v28_ = self.spec_sowingMachine
	local v29_ = v28_.seeds[v28_.currentSeed]
	local v30_ = (v29_ == nil or v29_ == FruitType.UNKNOWN) and "unknown" or g_fruitTypeManager:getFruitTypeByIndex(v29_).name
	xmlFile:setValue(key .. "#selectedSeedFruitType", v30_)
	if v28_.allowsSeedChanging ~= nil then
		xmlFile:setValue(key .. "#allowsSeedChanging", v28_.allowsSeedChanging)
	end
end

-- Local values: seedIndex
function SowingMachine:onReadStream(streamId, connection)
	self:setSeedIndex(streamReadUInt8(streamId), true)
end

-- Local values: spec
function SowingMachine:onWriteStream(streamId, connection)
	local v35_ = self.spec_sowingMachine
	streamWriteUInt8(streamId, v35_.currentSeed)
end

-- Local values: spec, fillType
function SowingMachine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v37_ = self.spec_sowingMachine
	if v37_.isProcessing then
		local v38_ = self:getFillUnitForcedMaterialFillType(v37_.fillUnitIndex)
		if v38_ ~= nil then
			g_effectManager:setEffectTypeInfo(v37_.effects, v38_)
			g_effectManager:startEffects(v37_.effects)
			return
		end
	else
		g_effectManager:stopEffects(v37_.effects)
	end
end

-- Local values: spec, actionEvent
function SowingMachine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v40_ = self.spec_sowingMachine
	local v41_ = v40_.actionEvents[v40_.changeSeedInputButton]
	if v41_ ~= nil then
		g_inputBinding:setActionEventActive(v41_.actionEventId, self:getIsSeedChangeAllowed())
	end
	if self.isActiveForInputIgnoreSelectionIgnoreAI then
		if v40_.showFruitCanNotBePlantedWarning then
			g_currentMission:showBlinkingWarning(v40_.warnings.fruitCanNotBePlanted, 5000)
			return
		end
		if v40_.showWrongFruitForMissionWarning then
			g_currentMission:showBlinkingWarning(v40_.warnings.wrongFruitForMission, 5000)
			return
		end
		if v40_.showWrongPlantingTimeWarning then
			g_currentMission:showBlinkingWarning(string.format(v40_.warnings.wrongPlantingTime, g_i18n:formatPeriod()), 5000)
			return
		end
		if v40_.showWaterPlantingRequiredWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_seedingInWaterRequired"), 5000)
			return
		end
		if v40_.showWaterPlantingProhibitedWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_seedingInWaterProhibited"), 5000)
			return
		end
		if v40_.showFieldTypeWarningRegularRequired then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_seedingOnRegularFieldRequired"), 5000)
			return
		end
		if v40_.showFieldTypeWarningRiceRequired then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_seedingOnRiceFieldRequired"), 5000)
		end
	end
end

-- Local values: spec, fruitTypeIndex, fillType
function SowingMachine:setSeedIndex(seedIndex, noEventSend)
	local v45_ = self.spec_sowingMachine
	SetSeedIndexEvent.sendEvent(self, seedIndex, noEventSend)
	local v46_ = math.max(seedIndex, 1)
	local v47_ = #v45_.seeds
	v45_.currentSeed = math.min(v46_, v47_)
	local v48_ = v45_.seeds[v45_.currentSeed]
	if v48_ ~= nil then
		local v49_ = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v48_)
		if v49_ ~= nil then
			self:setFillUnitFillTypeToDisplay(v45_.fillUnitIndex, v49_, true)
			self:setFillTypeSourceDisplayFillType(v49_)
		end
	end
	SowingMachine.updateAiParameters(self)
	SowingMachine.updateChooseSeedActionEvent(self)
end

-- Local values: spec, seed
function SowingMachine:changeSeedIndex(increment)
	local v52_ = self.spec_sowingMachine
	local v53_ = v52_.currentSeed + increment
	self:setSeedIndex(#v52_.seeds < v53_ and 1 or (v53_ < 1 and #v52_.seeds or v53_))
end

-- Local values: spec, i, v
function SowingMachine:setSeedFruitType(fruitType, noEventSend)
	local v57_ = self.spec_sowingMachine
	for v58_, v59_ in ipairs(v57_.seeds) do
		if v59_ == fruitType then
			self:setSeedIndex(v58_, noEventSend)
			return
		end
	end
end

function SowingMachine:setIsSeedChangeAllowed(isAllowed)
	self.spec_sowingMachine.allowsSeedChanging = isAllowed
end

function SowingMachine:getIsSeedChangeAllowed()
	return self.spec_sowingMachine.allowsSeedChanging
end

function SowingMachine:getSowingMachineFillUnitIndex()
	return self.spec_sowingMachine.fillUnitIndex
end

-- Local values: spec
function SowingMachine:getSowingMachineSeedFillTypeIndex()
	local v65_ = self.spec_sowingMachine
	return g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v65_.seeds[v65_.currentSeed])
end

-- Local values: spec, fillType
function SowingMachine:getCurrentSeedTypeIcon()
	local v67_ = self.spec_sowingMachine
	local v68_ = g_fruitTypeManager:getFillTypeByFruitTypeIndex(v67_.seeds[v67_.currentSeed])
	if v68_ == nil then
		return nil
	else
		return v68_.hudOverlayFilename
	end
end

-- Local values: spec, changedArea, totalArea, rootVehicle, rootVehicle, rootVehicle, sx, _, sz, wx, _, wz, hx, _, hz, fruitTypeDesc, cx, cz, rootVehicle, area, _, area, _
function SowingMachine:processSowingMachineArea(workArea, dt)
	local v71_ = self.spec_sowingMachine
	local v72_ = 0
	local v73_ = 0
	v71_.isWorking = self:getLastSpeed() > 0.5
	if v71_.waterSeeding and not self.isInWater then
		v71_.showWaterPlantingRequiredWarning = true
		if self:getIsAIActive() then
			self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
		end
		return v72_, v73_
	end
	if not v71_.waterSeeding and self.isInWater then
		v71_.showWaterPlantingProhibitedWarning = true
		if self:getIsAIActive() then
			self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
		end
		return v72_, v73_
	end
	if not v71_.workAreaParameters.isActive then
		return v72_, v73_
	end
	if not (self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds) and v71_.workAreaParameters.seedsVehicle == nil then
		if self:getIsAIActive() then
			self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
		end
		return v72_, v73_
	end
	if not v71_.workAreaParameters.canFruitBePlanted then
		return v72_, v73_
	end
	local v74_, _, v75_ = getWorldTranslation(workArea.start)
	local v76_, _, v77_ = getWorldTranslation(workArea.width)
	local v78_, _, v79_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v74_, v75_, v76_, v77_, v78_, v79_)
	if not self.isServer and self.currentUpdateDistance > SowingMachine.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v80_ = g_fruitTypeManager:getFruitTypeByIndex(v71_.workAreaParameters.seedsFruitType)
	if v80_.seedRequiredFieldType ~= nil then
		local v81_ = (v74_ + v76_ + v78_) / 3
		local v82_ = (v75_ + v77_ + v79_) / 3
		if FSDensityMapUtil.getFieldTypeAtWorldPos(v81_, v82_) ~= v80_.seedRequiredFieldType then
			if v80_.seedRequiredFieldType == FieldType.RICE then
				v71_.showFieldTypeWarningRiceRequired = true
				if self:getIsAIActive() then
					self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
				end
			else
				v71_.showFieldTypeWarningRegularRequired = true
			end
		end
	end
	v71_.isProcessing = v71_.isWorking
	local v83_
	if v71_.useDirectPlanting then
		local v84_, _ = FSDensityMapUtil.updateDirectSowingArea(v71_.workAreaParameters.seedsFruitType, v74_, v75_, v76_, v77_, v78_, v79_, v71_.workAreaParameters.fieldGroundType, v71_.workAreaParameters.ridgeSeeding, v71_.workAreaParameters.angle, nil)
		v83_ = v72_ + v84_
	else
		local v85_, _ = FSDensityMapUtil.updateSowingArea(v71_.workAreaParameters.seedsFruitType, v74_, v75_, v76_, v77_, v78_, v79_, v71_.workAreaParameters.fieldGroundType, v71_.workAreaParameters.ridgeSeeding, v71_.workAreaParameters.angle, nil)
		v83_ = v72_ + v85_
	end
	if v71_.isWorking then
		v71_.stoneLastState = FSDensityMapUtil.getStoneArea(v74_, v75_, v76_, v77_, v78_, v79_)
	else
		v71_.stoneLastState = 0
	end
	v71_.workAreaParameters.lastChangedArea = v71_.workAreaParameters.lastChangedArea + v83_
	v71_.workAreaParameters.lastStatsArea = v71_.workAreaParameters.lastStatsArea + v83_
	v71_.workAreaParameters.lastTotalArea = v71_.workAreaParameters.lastTotalArea + 0
	self:updateMissionSowingWarning(v74_, v75_)
	return v83_, v73_
end

-- Local values: spec, mission
function SowingMachine:updateMissionSowingWarning(x, z)
	local v89_ = self.spec_sowingMachine
	v89_.showWrongFruitForMissionWarning = false
	if self:getLastTouchedFarmlandFarmId() == 0 then
		local v90_ = g_missionManager:getMissionAtWorldPosition(x, z)
		if v90_ ~= nil and (v90_.type.name == "sow" and v90_.fruitType ~= v89_.workAreaParameters.seedsFruitType) then
			v89_.showWrongFruitForMissionWarning = true
		end
	end
end

function SowingMachine:getUseSowingMachineAIRequirements()
	return self:getAIRequiresTurnOn() or self:getIsTurnedOn()
end

-- Local values: spec, _, src, vehicle, fillLevel, fillTypes, numFillTypes, fillTypeIndex, state
function SowingMachine:setFillTypeSourceDisplayFillType(fillType)
	local v94_ = self.spec_sowingMachine
	if v94_.fillTypeSources[v94_.seedFillType] ~= nil then
		for _, v95_ in ipairs(v94_.fillTypeSources[v94_.seedFillType]) do
			local v96_ = v95_.vehicle
			local v97_ = v96_:getFillUnitFillLevel(v95_.fillUnitIndex)
			if v97_ > 0 and v96_:getFillUnitFillType(v95_.fillUnitIndex) == v94_.seedFillType then
				v96_:setFillUnitFillTypeToDisplay(v95_.fillUnitIndex, fillType)
				return
			end
			if v97_ == 0 then
				local v98_ = v96_:getFillUnitSupportedFillTypes(v95_.fillUnitIndex)
				local v99_ = 0
				for _, v100_ in pairs(v98_) do
					if v100_ then
						v99_ = v99_ + 1
					end
				end
				if v99_ == 1 and v98_[v94_.seedFillType] == true then
					v96_:setFillUnitFillTypeToDisplay(v95_.fillUnitIndex, fillType)
					return
				end
			end
		end
	end
end

-- Local values: spec
function SowingMachine:getDrawFirstFillText(superFunc)
	local v103_ = self.spec_sowingMachine
	if self.isClient and (self:getIsActiveForInput() and self:getIsSelected()) then
		if v103_.consumableName == nil then
			if self:getFillUnitFillLevel(v103_.fillUnitIndex) <= 0 and self:getFillUnitCapacity(v103_.fillUnitIndex) ~= 0 then
				return true
			end
		elseif not self:getConsumableIsAvailable(v103_.consumableName) then
			return true
		end
	end
	return superFunc(self)
end

-- Local values: spec
function SowingMachine:getAreControlledActionsAllowed(superFunc)
	local v106_ = self.spec_sowingMachine
	if v106_.requiresFilling then
		if v106_.consumableName == nil then
			if self:getFillUnitFillLevel(v106_.fillUnitIndex) <= 0 and self:getFillUnitCapacity(v106_.fillUnitIndex) ~= 0 then
				return false, g_i18n:getText("info_firstFillTheTool")
			end
		elseif not self:getConsumableIsAvailable(v106_.consumableName) then
			return false, g_i18n:getText("info_firstFillTheTool")
		end
	end
	return superFunc(self)
end

-- Local values: specFillUnit, spec
function SowingMachine:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
	if superFunc(self, fillUnitIndex, fillType) then
		return true
	end
	local v111_ = self.spec_fillUnit
	if v111_.fillUnits[fillUnitIndex] ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
		local v112_ = self.spec_sowingMachine
		if fillType == v112_.seedFillType or v111_.fillUnits[fillUnitIndex].fillType == v112_.seedFillType then
			return true
		end
	end
	return false
end

-- Local values: spec
function SowingMachine:getCanBeTurnedOn(superFunc)
	if self.spec_sowingMachine.needsActivation then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec
function SowingMachine:getCanToggleTurnedOn(superFunc)
	if self.spec_sowingMachine.needsActivation then
		return superFunc(self)
	else
		return false
	end
end

function SowingMachine:getCanPlantOutsideSeason()
	return false
end

-- Local values: spec
function SowingMachine:getSowingMachineCanConsume()
	local v118_ = self.spec_sowingMachine
	if v118_.consumableName ~= nil then
		return self:getConsumableIsAvailable(v118_.consumableName)
	end
	if self:getFillUnitFillLevel(v118_.fillUnitIndex) > 0 or self:getFillUnitCapacity(v118_.fillUnitIndex) == 0 then
		return true
	end
end

-- Local values: spec
function SowingMachine:getAllowFillFromAir(superFunc)
	local v121_ = self.spec_sowingMachine
	if self:getIsTurnedOn() and not v121_.allowFillFromAirWhileTurnedOn then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec, seedsFruitType, desc, snapAngle
function SowingMachine:getDirectionSnapAngle(superFunc)
	local v124_ = self.spec_sowingMachine
	local v125_ = v124_.seeds[v124_.currentSeed]
	local v126_ = g_fruitTypeManager:getFruitTypeByIndex(v125_)
	local v127_ = v126_ == nil and 0 or v126_.directionSnapAngle
	return math.max(v127_, superFunc(self))
end

-- Local values: spec, fruitType, seedsFillType
function SowingMachine:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillType, toolType, fillInfo)
	local v136_ = self.spec_sowingMachine
	if fillUnitIndex == v136_.fillUnitIndex then
		if self:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
			fillType = v136_.seedFillType
			self:setFillUnitForcedMaterialFillType(fillUnitIndex, fillType)
		end
		local v137_ = v136_.seeds[v136_.currentSeed]
		if v137_ ~= nil then
			local v138_ = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v137_)
			if v138_ ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, v138_) then
				self:setFillUnitForcedMaterialFillType(fillUnitIndex, v138_)
			end
		end
	end
	return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillType, toolType, fillInfo)
end

-- Local values: spec
function SowingMachine:doCheckSpeedLimit(superFunc)
	local v141_ = self.spec_sowingMachine
	local v142_ = not superFunc(self) and (self.getIsImplementChainLowered == nil or self:getIsImplementChainLowered())
	if v142_ then
		v142_ = not v141_.needsActivation or self:getIsTurnedOn()
	end
	return v142_
end

-- Local values: spec, multiplier
function SowingMachine:getDirtMultiplier(superFunc)
	local v145_ = self.spec_sowingMachine
	local v146_ = superFunc(self)
	if self.movingDirection > 0 and (v145_.isWorking and (not v145_.needsActivation or self:getIsTurnedOn())) then
		v146_ = v146_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v146_
end

-- Local values: spec, multiplier, stoneMultiplier
function SowingMachine:getWearMultiplier(superFunc)
	local v149_ = self.spec_sowingMachine
	local v150_ = superFunc(self)
	if self.movingDirection > 0 and (v149_.isWorking and (not v149_.needsActivation or self:getIsTurnedOn())) then
		local v151_ = (v149_.stoneLastState == 0 or v149_.stoneWearMultiplierData == nil) and 1 or (v149_.stoneWearMultiplierData[v149_.stoneLastState] or 1)
		v150_ = v150_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * v151_
	end
	return v150_
end

-- Local values: retValue
function SowingMachine:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v157_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.SOWINGMACHINE
	end
	return v157_
end

function SowingMachine:getCanBeSelected(superFunc)
	return true
end

-- Local values: canContinue, stopAI, stopReason, spec, fruitDesc
function SowingMachine:getCanAIImplementContinueWork(superFunc, isTurning)
	local v161_, v162_, v163_ = superFunc(self, isTurning)
	if not v161_ then
		return false, v162_, v163_
	end
	if not self:getCanPlantOutsideSeason() and self:getUseSowingMachineAIRequirements() then
		local v164_ = self.spec_sowingMachine
		if v164_.workAreaParameters.seedsFruitType ~= nil and not g_fruitTypeManager:getFruitTypeByIndex(v164_.workAreaParameters.seedsFruitType):getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
			return false, true, AIMessageErrorWrongSeason.new()
		end
	end
	return v161_, v162_, v163_
end

-- Local values: spec, _, actionEventId
function SowingMachine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v167_ = self.spec_sowingMachine
		self:clearActionEventsTable(v167_.actionEvents)
		if isActiveForInputIgnoreSelection and #v167_.seeds > 1 then
			local _, v168_ = self:addActionEvent(v167_.actionEvents, v167_.changeSeedInputButton, self, SowingMachine.actionEventToggleSeedType, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v168_, GS_PRIO_HIGH)
			SowingMachine.updateChooseSeedActionEvent(self)
			local _, v169_ = self:addPoweredActionEvent(v167_.actionEvents, InputAction.TOGGLE_SEEDS_BACK, self, SowingMachine.actionEventToggleSeedTypeBack, false, true, false, true, nil)
			g_inputBinding:setActionEventTextVisibility(v169_, false)
		end
	end
end

-- Local values: spec, actionEvent, additionalText, fillType
function SowingMachine:updateChooseSeedActionEvent()
	local v171_ = self.spec_sowingMachine
	local v172_ = v171_.actionEvents[v171_.changeSeedInputButton]
	if v172_ ~= nil then
		local v173_ = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v171_.seeds[v171_.currentSeed]))
		local v174_ = (v173_ == nil or v173_ == FillType.UNKNOWN) and "" or string.format(" (%s)", v173_.title)
		g_inputBinding:setActionEventText(v172_.actionEventId, string.format("%s%s", g_i18n:getText("action_chooseSeed"), v174_))
	end
end

-- Local values: spec, _, src
function SowingMachine:onTurnedOn()
	local v176_ = self.spec_sowingMachine
	if self.isClient then
		g_soundManager:playSamples(v176_.samples.airBlower)
		g_animationManager:startAnimations(v176_.animationNodes)
	end
	if self.isServer and v176_.fillTypeSources[v176_.seedFillType] ~= nil then
		for _, v177_ in ipairs(v176_.fillTypeSources[v176_.seedFillType]) do
			if v177_.vehicle.setIsTurnedOn ~= nil then
				v177_.vehicle:setIsTurnedOn(true)
			end
		end
	end
	SowingMachine.updateAiParameters(self)
end

-- Local values: spec, _, src
function SowingMachine:onTurnedOff()
	local v179_ = self.spec_sowingMachine
	if self.isClient then
		g_soundManager:stopSamples(v179_.samples.airBlower)
		g_animationManager:stopAnimations(v179_.animationNodes)
	end
	if self.isServer and v179_.fillTypeSources[v179_.seedFillType] ~= nil then
		for _, v180_ in ipairs(v179_.fillTypeSources[v179_.seedFillType]) do
			if v180_.vehicle.setIsTurnedOn ~= nil then
				v180_.vehicle:setIsTurnedOn(false)
			end
		end
	end
	SowingMachine.updateAiParameters(self)
end

-- Local values: spec, seedsFruitType, dx, _, dz, angleRad, desc, angle, seedsVehicle, seedsVehicleFillUnitIndex, seedsVehicleUnloadInfoIndex, isFilled, _, src, vehicle, fillType, isTurnedOn, canFruitBePlanted, isPlantingSeason, fruitDesc, seedVehicleChanged
function SowingMachine:onStartWorkAreaProcessing(dt)
	local v182_ = self.spec_sowingMachine
	v182_.isWorking = false
	v182_.isProcessing = false
	local v183_ = v182_.seeds[v182_.currentSeed]
	local v184_, _, v185_ = localDirectionToWorld(v182_.directionNode, 0, 0, 1)
	local v186_ = MathUtil.getYRotationFromDirection(v184_, v185_)
	local v187_ = g_fruitTypeManager:getFruitTypeByIndex(v183_)
	if v187_ ~= nil and v187_.directionSnapAngle ~= 0 then
		local v188_ = v186_ / v187_.directionSnapAngle + 0.5
		v186_ = math.floor(v188_) * v187_.directionSnapAngle
	end
	local v189_ = FSDensityMapUtil.convertToDensityMapAngle(v186_, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	local v190_ = nil
	local v191_ = nil
	local v192_ = nil
	local v193_
	if v182_.consumableName == nil then
		v193_ = self:getFillUnitFillLevel(v182_.fillUnitIndex) > 0
	else
		v193_ = self:getConsumableIsAvailable(v182_.consumableName)
	end
	local v194_
	if v193_ then
		v191_ = v182_.fillUnitIndex
		v192_ = v182_.unloadInfoIndex
		v194_ = self
	elseif v182_.fillTypeSources[v182_.seedFillType] == nil then
		v194_ = self
		self = v190_
	else
		v194_ = self
		self = v190_
		for _, v195_ in ipairs(v182_.fillTypeSources[v182_.seedFillType]) do
			local v196_ = v195_.vehicle
			if v196_:getFillUnitFillLevel(v195_.fillUnitIndex) > 0 and v196_:getFillUnitFillType(v195_.fillUnitIndex) == v182_.seedFillType then
				v191_ = v195_.fillUnitIndex
				self = v196_
				break
			end
			v190_ = self
			self = v194_
			v194_ = self
			self = v190_
		end
	end
	if self ~= nil and self ~= v194_ then
		local v197_ = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v183_)
		if v197_ ~= nil then
			self:setFillUnitFillTypeToDisplay(v191_, v197_)
		end
	end
	local v198_ = v194_:getIsTurnedOn()
	local v199_ = v187_ ~= nil and v187_.terrainDataPlaneId ~= nil
	if v182_.showWrongFruitForMissionWarning then
		v182_.showWrongFruitForMissionWarning = false
	end
	local v200_ = true
	if not v194_:getCanPlantOutsideSeason() then
		local v201_ = g_fruitTypeManager:getFruitTypeByIndex(v183_)
		if v201_ ~= nil then
			v200_ = v201_:getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod)
		end
	end
	local v202_ = self ~= v182_.workAreaParameters.seedsVehicle and true or v191_ ~= v182_.workAreaParameters.seedsVehicleFillUnitIndex
	v182_.showFruitCanNotBePlantedWarning = not v199_
	local v203_ = not (v200_ or (v198_ or v182_.needsActivation))
	if v203_ then
		v203_ = v194_:getIsLowered()
	end
	v182_.showWrongPlantingTimeWarning = v203_
	v182_.showWaterPlantingRequiredWarning = false
	v182_.showWaterPlantingProhibitedWarning = false
	v182_.showFieldTypeWarningRegularRequired = false
	v182_.showFieldTypeWarningRiceRequired = false
	v182_.workAreaParameters.isActive = not v182_.needsActivation or v198_
	v182_.workAreaParameters.canFruitBePlanted = v199_ and v200_
	v182_.workAreaParameters.seedsFruitType = v183_
	v182_.workAreaParameters.fieldGroundType = v182_.fieldGroundType
	v182_.workAreaParameters.ridgeSeeding = v182_.ridgeSeeding
	v182_.workAreaParameters.angle = v189_
	v182_.workAreaParameters.seedsVehicle = self
	v182_.workAreaParameters.seedsVehicleFillUnitIndex = v191_
	v182_.workAreaParameters.seedsVehicleUnloadInfoIndex = v192_
	v182_.workAreaParameters.lastTotalArea = 0
	v182_.workAreaParameters.lastChangedArea = 0
	v182_.workAreaParameters.lastStatsArea = 0
	if v202_ then
		SowingMachine.updateAiParameters(v194_)
	end
end

-- Local values: spec, farmId, fruitDesc, lastHa, usage, ha, damage, vehicle, fillUnitIndex, unloadInfoIndex, fillType, unloadInfo, price
function SowingMachine:onEndWorkAreaProcessing(dt, hasProcessed)
	local v206_ = self.spec_sowingMachine
	if self.isServer then
		local v207_ = self:getLastTouchedFarmlandFarmId()
		if v206_.workAreaParameters.lastChangedArea > 0 then
			local v208_ = g_fruitTypeManager:getFruitTypeByIndex(v206_.workAreaParameters.seedsFruitType)
			local v209_ = MathUtil.areaToHa(v206_.workAreaParameters.lastChangedArea, g_currentMission:getFruitPixelsToSqm())
			local v210_ = v208_.seedUsagePerSqm * v209_ * 10000 * v206_.seedUsageScale
			local v211_ = MathUtil.areaToHa(v206_.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local v212_ = self:getVehicleDamage()
			if v212_ > 0 then
				v210_ = v210_ * (1 + v212_ * SowingMachine.DAMAGED_USAGE_INCREASE)
			end
			g_farmManager:updateFarmStats(v207_, "seedUsage", v210_)
			g_farmManager:updateFarmStats(v207_, "sownHectares", v211_)
			self:updateLastWorkedArea(v206_.workAreaParameters.lastStatsArea)
			if self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds then
				local v213_ = v210_ * g_currentMission.economyManager:getCostPerLiter(v206_.seedFillType, false) * 1.5
				g_farmManager:updateFarmStats(v207_, "expenses", v213_)
				g_currentMission:addMoney(-v213_, self:getOwnerFarmId(), MoneyType.PURCHASE_SEEDS)
			elseif v206_.consumableName == nil then
				local v214_ = v206_.workAreaParameters.seedsVehicle
				local v215_ = v206_.workAreaParameters.seedsVehicleFillUnitIndex
				local v216_ = v206_.workAreaParameters.seedsVehicleUnloadInfoIndex
				local v217_ = v214_:getFillUnitFillType(v215_)
				local v218_
				if v214_.getFillVolumeUnloadInfo == nil then
					v218_ = nil
				else
					v218_ = v214_:getFillVolumeUnloadInfo(v216_)
				end
				v214_:addFillUnitFillLevel(self:getOwnerFarmId(), v215_, -v210_, v217_, ToolType.UNDEFINED, v218_)
			else
				self:updateConsumable(v206_.consumableName, -v210_, true)
			end
		end
		self:updateLastWorkedArea(0)
		if v206_.isWorking then
			g_farmManager:updateFarmStats(v207_, "sownTime", dt / 60000)
		end
	end
	if self.isClient then
		if v206_.isWorking then
			if not v206_.isWorkSamplePlaying then
				g_soundManager:playSamples(v206_.samples.work)
				v206_.isWorkSamplePlaying = true
				return
			end
		elseif v206_.isWorkSamplePlaying then
			g_soundManager:stopSamples(v206_.samples.work)
			v206_.isWorkSamplePlaying = false
		end
	end
end

-- Local values: spec
function SowingMachine:onDeactivate()
	local v220_ = self.spec_sowingMachine
	if self.isClient then
		g_soundManager:stopSamples(v220_.samples.work)
		g_soundManager:stopSamples(v220_.samples.airBlower)
		v220_.isWorkSamplePlaying = false
	end
end

-- Local values: spec, root, fruitTypeIndex, fillType
function SowingMachine:onStateChange(state, data)
	if state == VehicleStateChange.ATTACH or (state == VehicleStateChange.DETACH or VehicleStateChange.FILLTYPE_CHANGE) then
		local v223_ = self.spec_sowingMachine
		v223_.fillTypeSources = {}
		if v223_.seedFillType ~= nil then
			v223_.fillTypeSources[v223_.seedFillType] = {}
			local v224_ = self.rootVehicle
			FillUnit.addFillTypeSources(v223_.fillTypeSources, v224_, self, { v223_.seedFillType })
			local v225_ = v223_.seeds[v223_.currentSeed]
			if v225_ ~= nil then
				local v226_ = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v225_)
				if v226_ ~= nil then
					self:setFillTypeSourceDisplayFillType(v226_)
				end
			end
		end
	end
end

-- Local values: spec
function SowingMachine:onChangedFillType(fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
	local v230_ = self.spec_sowingMachine
	if fillUnitIndex == v230_.fillUnitIndex then
		g_animationManager:setFillType(v230_.animationNodes, fillTypeIndex)
	end
end

-- Local values: spec
function SowingMachine:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	if self.spec_sowingMachine.fieldGroundType == FieldGroundType.PLANTED then
		fieldCourseSettings.headlandsFirst = true
		fieldCourseSettings.workInitialSegment = true
	end
end

-- Local values: spec, isCultivatorAttached, isWeederAttached, isRollerAttached, vehicles, i, vehicle, fruitTypeIndex, fruitTypeDesc
function SowingMachine:updateAiParameters()
	local v234_ = self.spec_sowingMachine
	if self.addAITerrainDetailRequiredRange ~= nil then
		self:clearAITerrainDetailRequiredRange()
		self:clearAITerrainDetailProhibitedRange()
		self:clearAIFruitProhibitions()
		local v235_ = self.rootVehicle:getChildVehicles()
		local v236_ = false
		local v237_ = false
		local v238_ = false
		for v239_ = 1, #v235_ do
			local v240_ = v235_[v239_]
			if SpecializationUtil.hasSpecialization(Cultivator, v240_.specializations) then
				v240_:updateCultivatorEnabledState()
				if v240_:getIsCultivationEnabled() then
					v240_:updateCultivatorAIRequirements()
					v236_ = true
				end
			end
			if SpecializationUtil.hasSpecialization(Weeder, v240_.specializations) then
				v240_:updateWeederAIRequirements()
				v237_ = true
			end
			if SpecializationUtil.hasSpecialization(Roller, v240_.specializations) then
				v240_:updateRollerAIRequirements()
				v238_ = true
			end
		end
		if v236_ then
			if self:getUseSowingMachineAIRequirements() then
				self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
				self:addAIGroundTypeRequirements(SowingMachine.AI_OUTPUT_GROUND_TYPES)
			end
		elseif v237_ then
			if self:getUseSowingMachineAIRequirements() then
				self:clearAITerrainDetailRequiredRange()
				self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
			end
		elseif v238_ then
			if self:getUseSowingMachineAIRequirements() then
				self:clearAITerrainDetailRequiredRange()
				self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
			end
		else
			self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
			if v234_.useDirectPlanting then
				self:addAIGroundTypeRequirements(SowingMachine.AI_OUTPUT_GROUND_TYPES)
			end
		end
		if self:getUseSowingMachineAIRequirements() then
			local v241_ = v234_.seeds[v234_.currentSeed]
			local v242_ = g_fruitTypeManager:getFruitTypeByIndex(v241_)
			if v242_ ~= nil then
				if v242_.cutState < v242_.maxHarvestingGrowthState then
					self:clearAIFruitProhibitions()
					self:addAIFruitProhibitions(v241_, 0, v242_.cutState - 1)
					self:addAIFruitProhibitions(v241_, v242_.cutState + 1, v242_.maxHarvestingGrowthState)
					return
				end
				self:setAIFruitProhibitions(v241_, 0, v242_.maxHarvestingGrowthState)
			end
		end
	end
end
function SowingMachine.getDefaultSpeedLimit()
	return 15
end

function SowingMachine:actionEventToggleSeedType(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSeedChangeAllowed() then
		self:changeSeedIndex(1)
	end
end

function SowingMachine:actionEventToggleSeedTypeBack(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSeedChangeAllowed() then
		self:changeSeedIndex(-1)
	end
end

-- Local values: categories, names
function SowingMachine.loadSpecValueSeedFillTypes(xmlFile, customEnvironment, baseDir)
	return {
		["categories"] = Utils.getNoNil(xmlFile:getValue("vehicle.storeData.specs.seedFruitTypeCategories"), xmlFile:getValue("vehicle.sowingMachine.seedFruitTypeCategories")),
		["names"] = Utils.getNoNil(xmlFile:getValue("vehicle.storeData.specs.seedFruitTypes"), xmlFile:getValue("vehicle.sowingMachine.seedFruitTypes"))
	}
end

-- Local values: fruitTypes, fruits
function SowingMachine.getSpecValueSeedFillTypes(storeItem, realItem)
	local v247_ = nil
	if storeItem.specs.seedFillTypes ~= nil then
		local v248_ = storeItem.specs.seedFillTypes
		if v248_.categories == nil or v248_.names ~= nil then
			if v248_.categories == nil and v248_.names ~= nil then
				v247_ = g_fruitTypeManager:getFillTypeIndicesByFruitTypeNames(v248_.names, nil)
			end
		else
			v247_ = g_fruitTypeManager:getFillTypeIndicesByFruitTypeCategoryName(v248_.categories, nil)
		end
		if v247_ ~= nil then
			return v247_
		end
	end
	return nil
end
