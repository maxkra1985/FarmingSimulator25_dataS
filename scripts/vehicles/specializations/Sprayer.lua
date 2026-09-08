source("dataS/scripts/vehicles/specializations/events/SprayerDoubledAmountEvent.lua")
Sprayer = {}
Sprayer.SPRAY_TYPE_XML_KEY = "vehicle.sprayer.sprayTypes.sprayType(?)"
Sprayer.AI_REQUIRED_GROUND_TYPES = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.CULTIVATED,
	FieldGroundType.SEEDBED,
	FieldGroundType.PLOWED,
	FieldGroundType.ROLLED_SEEDBED,
	FieldGroundType.RIDGE,
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
Sprayer.CLIENT_DM_UPDATE_RADIUS = 50
function Sprayer.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("sprayer", false, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Sprayer")
	v1_:register(XMLValueType.BOOL, "vehicle.sprayer#allowsSpraying", "Allows spraying", true)
	v1_:register(XMLValueType.BOOL, "vehicle.sprayer#activateTankOnLowering", "Activate tank on lowering", false)
	v1_:register(XMLValueType.BOOL, "vehicle.sprayer#activateOnLowering", "Activate on lowering", false)
	v1_:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales#scale", "Usage scale", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales#workingWidth", "Working width", 12)
	v1_:register(XMLValueType.INT, "vehicle.sprayer.usageScales#workAreaIndex", "Work area that is used for working width reference instead of #workingWidth")
	v1_:register(XMLValueType.STRING, "vehicle.sprayer.usageScales.sprayUsageScale(?)#fillType", "Fill type name")
	v1_:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales.sprayUsageScale(?)#scale", "Scale")
	v1_:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillUnitIndex", "Fill unit index")
	v1_:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#unloadInfoIndex", "Unload info index")
	v1_:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillVolumeIndex", "Fill volume index")
	v1_:register(XMLValueType.BOOL, Sprayer.SPRAY_TYPE_XML_KEY .. "#supportsVariableWorkWidth", "Spray type support variable work width", true)
	SoundManager.registerSampleXMLPaths(v1_, Sprayer.SPRAY_TYPE_XML_KEY .. ".sounds", "work(?)")
	SoundManager.registerSampleXMLPaths(v1_, Sprayer.SPRAY_TYPE_XML_KEY .. ".sounds", "spray(?)")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, Sprayer.SPRAY_TYPE_XML_KEY .. ".animationNodes")
	EffectManager.registerEffectXMLPaths(v1_, Sprayer.SPRAY_TYPE_XML_KEY .. ".effects")
	v1_:register(XMLValueType.STRING, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#name", "Turned animation name")
	v1_:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#turnOnSpeedScale", "Speed Scale while turned on", 1)
	v1_:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#turnOffSpeedScale", "Speed Scale while turned off", "Inversed #turnOnSpeedScale")
	v1_:register(XMLValueType.BOOL, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#externalFill", "Animation is played while sprayer is externally filled", true)
	AIImplement.registerAIImplementBaseXMLPaths(v1_, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai")
	v1_:register(XMLValueType.STRING, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillTypes", "Fill types")
	v1_:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".usageScales#workingWidth", "Work width", 12)
	v1_:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. ".usageScales#workAreaIndex", "Work area that is used for working width reference instead of #workingWidth")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v1_, Sprayer.SPRAY_TYPE_XML_KEY)
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.sprayer.effects")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.sprayer.sounds", "work(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.sprayer.sounds", "spray(?)")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.sprayer.animationNodes")
	v1_:register(XMLValueType.STRING, "vehicle.sprayer.animation#name", "Spray animation name")
	v1_:register(XMLValueType.INT, "vehicle.sprayer#fillUnitIndex", "Fill unit index", 1)
	v1_:register(XMLValueType.INT, "vehicle.sprayer#unloadInfoIndex", "Unload info index", 1)
	v1_:register(XMLValueType.INT, "vehicle.sprayer#fillVolumeIndex", "Fill volume index")
	v1_:register(XMLValueType.VECTOR_3, "vehicle.sprayer#fillVolumeDischargeScrollSpeed", "Fill volume discharge scroll speed", "0 0 0")
	v1_:register(XMLValueType.FLOAT, "vehicle.sprayer.doubledAmount#decreasedSpeed", "Speed while doubled amount is sprayed", "automatically calculated")
	v1_:register(XMLValueType.FLOAT, "vehicle.sprayer.doubledAmount#decreaseFactor", "Decrease factor that is applied on speedLimit while doubled amount is sprayed", 0.5)
	v1_:register(XMLValueType.STRING, "vehicle.sprayer.doubledAmount#toggleButton", "Name of input action to toggle doubled amount", "IMPLEMENT_EXTRA4")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.sprayer.doubledAmount#deactivateText", "Deactivated text", "action_deactivateDoubledSprayAmount")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.sprayer.doubledAmount#activateText", "Activate text", "action_activateDoubledSprayAmount")
	v1_:register(XMLValueType.STRING, "vehicle.sprayer.turnedAnimation#name", "Turned animation name")
	v1_:register(XMLValueType.FLOAT, "vehicle.sprayer.turnedAnimation#turnOnSpeedScale", "Speed Scale while turned on", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.sprayer.turnedAnimation#turnOffSpeedScale", "Speed Scale while turned off", "Inversed #turnOnSpeedScale")
	v1_:register(XMLValueType.BOOL, "vehicle.sprayer.turnedAnimation#externalFill", "Animation is played while sprayer is externally filled", true)
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. "#sprayType", "Spray type index")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#sprayType", "Spray type index")
	v1_:setXMLSpecializationType()
end

function Sprayer.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations)
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
	return v3_
end

function Sprayer.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onSprayTypeChange")
end

function Sprayer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processSprayerArea", Sprayer.processSprayerArea)
	SpecializationUtil.registerFunction(vehicleType, "getIsSprayerExternallyFilled", Sprayer.getIsSprayerExternallyFilled)
	SpecializationUtil.registerFunction(vehicleType, "getExternalFill", Sprayer.getExternalFill)
	SpecializationUtil.registerFunction(vehicleType, "getAreEffectsVisible", Sprayer.getAreEffectsVisible)
	SpecializationUtil.registerFunction(vehicleType, "updateSprayerEffects", Sprayer.updateSprayerEffects)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerUsage", Sprayer.getSprayerUsage)
	SpecializationUtil.registerFunction(vehicleType, "getUseSprayerAIRequirements", Sprayer.getUseSprayerAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", Sprayer.setSprayerAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerFillUnitIndex", Sprayer.getSprayerFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "loadSprayTypeFromXML", Sprayer.loadSprayTypeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getActiveSprayType", Sprayer.getActiveSprayType)
	SpecializationUtil.registerFunction(vehicleType, "getIsSprayTypeActive", Sprayer.getIsSprayTypeActive)
	SpecializationUtil.registerFunction(vehicleType, "setSprayerDoubledAmountActive", Sprayer.setSprayerDoubledAmountActive)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerDoubledAmountActive", Sprayer.getSprayerDoubledAmountActive)
end

function Sprayer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", Sprayer.getDrawFirstFillText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Sprayer.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", Sprayer.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Sprayer.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Sprayer.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Sprayer.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Sprayer.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRawSpeedLimit", Sprayer.getRawSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillVolumeUVScrollSpeed", Sprayer.getFillVolumeUVScrollSpeed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRequiresTurnOffOnHeadland", Sprayer.getAIRequiresTurnOffOnHeadland)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Sprayer.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Sprayer.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getEffectByNode", Sprayer.getEffectByNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVariableWorkWidthUsage", Sprayer.getVariableWorkWidthUsage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", Sprayer.getAIImplementUseVineSegment)
end

function Sprayer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onSprayTypeChange", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onVariableWorkWidthSectionChanged", Sprayer)
end

-- Local values: spec, i, key, fillTypeStr, scale, fillTypeIndex, key, sprayType, decreasedSpeedLimit, decreaseFactor, toggleButtonStr, fillUnitIndex
function Sprayer:onLoad(savegame)
	local v9_ = self.spec_sprayer
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sprayParticles.emitterShape", "vehicle.sprayer.effects.effectNode#effectClass=\'ParticleEffect\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sprayer#needsTankActivation")
	v9_.allowsSpraying = self.xmlFile:getValue("vehicle.sprayer#allowsSpraying", true)
	v9_.activateTankOnLowering = self.xmlFile:getValue("vehicle.sprayer#activateTankOnLowering", false)
	v9_.activateOnLowering = self.xmlFile:getValue("vehicle.sprayer#activateOnLowering", false)
	v9_.usageScale = {}
	v9_.usageScale.default = self.xmlFile:getValue("vehicle.sprayer.usageScales#scale", 1)
	v9_.usageScale.workingWidth = self.xmlFile:getValue("vehicle.sprayer.usageScales#workingWidth", 12)
	v9_.usageScale.workAreaIndex = self.xmlFile:getValue("vehicle.sprayer.usageScales#workAreaIndex")
	v9_.usageScale.fillTypeScales = {}
	local v10_ = 0
	while true do
		local v11_ = string.format("vehicle.sprayer.usageScales.sprayUsageScale(%d)", v10_)
		if not self.xmlFile:hasProperty(v11_) then
			break
		end
		local v12_ = self.xmlFile:getValue(v11_ .. "#fillType")
		local v13_ = self.xmlFile:getValue(v11_ .. "#scale")
		if v12_ ~= nil and v13_ ~= nil then
			local v14_ = g_fillTypeManager:getFillTypeIndexByName(v12_)
			if v14_ == nil then
				printWarning("Warning: Invalid spray usage scale fill type \'" .. v12_ .. "\' in \'" .. self.configFileName .. "\'")
			else
				v9_.usageScale.fillTypeScales[v14_] = v13_
			end
		end
		v10_ = v10_ + 1
	end
	v9_.sprayTypes = {}
	local v15_ = 0
	while true do
		local v16_ = string.format("vehicle.sprayer.sprayTypes.sprayType(%d)", v15_)
		if not self.xmlFile:hasProperty(v16_) then
			break
		end
		local v17_ = {}
		if self:loadSprayTypeFromXML(self.xmlFile, v16_, v17_) then
			local v18_ = v9_.sprayTypes
			table.insert(v18_, v17_)
			v17_.index = #v9_.sprayTypes
		end
		v15_ = v15_ + 1
	end
	v9_.lastActiveSprayType = nil
	if self.isClient then
		v9_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.sprayer.effects", self.components, self, self.i3dMappings)
		v9_.animationName = self.xmlFile:getValue("vehicle.sprayer.animation#name", "")
		v9_.samples = {}
		v9_.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.sprayer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.samples.spray = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.sprayer.sounds", "spray", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.sampleFillEnabled = false
		v9_.sampleFillStopTime = -1
		v9_.lastFillLevel = -1
		v9_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.sprayer.animationNodes", self.components, self, self.i3dMappings)
	end
	if self.addAIGroundTypeRequirements ~= nil then
		self:addAIGroundTypeRequirements(Sprayer.AI_REQUIRED_GROUND_TYPES)
	end
	v9_.supportedSprayTypes = {}
	v9_.fillUnitIndex = self.xmlFile:getValue("vehicle.sprayer#fillUnitIndex", 1)
	v9_.unloadInfoIndex = self.xmlFile:getValue("vehicle.sprayer#unloadInfoIndex", 1)
	v9_.fillVolumeIndex = self.xmlFile:getValue("vehicle.sprayer#fillVolumeIndex")
	v9_.dischargeUVScrollSpeed = self.xmlFile:getValue("vehicle.sprayer#fillVolumeDischargeScrollSpeed", "0 0 0", true)
	if self:getFillUnitByIndex(v9_.fillUnitIndex) == nil then
		Logging.xmlError(self.xmlFile, "FillUnit \'%d\' not defined!", v9_.fillUnitIndex)
		self:setLoadingState(VehicleLoadingState.ERROR)
	else
		local v19_ = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#decreasedSpeed")
		if v19_ == nil then
			local v20_ = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#decreaseFactor", 0.5)
			v19_ = self:getSpeedLimit() * v20_
		end
		v9_.doubledAmountSpeed = v19_
		v9_.doubledAmountIsActive = false
		local v21_ = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#toggleButton")
		if v21_ ~= nil then
			v9_.toggleDoubledAmountInputBinding = InputAction[v21_]
		end
		v9_.toggleDoubledAmountInputBinding = v9_.toggleDoubledAmountInputBinding or InputAction.DOUBLED_SPRAY_AMOUNT
		v9_.doubledAmountDeactivateText = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#deactivateText", "action_deactivateDoubledSprayAmount", self.customEnvironment)
		v9_.doubledAmountActivateText = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#activateText", "action_activateDoubledSprayAmount", self.customEnvironment)
		v9_.turnedAnimation = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#name", "")
		v9_.turnedAnimationTurnOnSpeedScale = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#turnOnSpeedScale", 1)
		v9_.turnedAnimationTurnOffSpeedScale = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#turnOffSpeedScale", -v9_.turnedAnimationTurnOnSpeedScale)
		v9_.turnedAnimationExternalFill = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#externalFill", true)
		v9_.needsToBeFilledToTurnOn = true
		v9_.useSpeedLimit = true
		v9_.isWorking = false
		v9_.lastEffectsState = false
		local v22_ = self:getSprayerFillUnitIndex()
		v9_.isSlurryTanker = self:getFillUnitAllowsFillType(v22_, FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(v22_, FillType.DIGESTATE)
		v9_.isManureSpreader = self:getFillUnitAllowsFillType(v22_, FillType.MANURE)
		local v23_ = not v9_.isSlurryTanker
		if v23_ then
			v23_ = not v9_.isManureSpreader
		end
		v9_.isFertilizerSprayer = v23_
		v9_.hasWorkAreas = self:getWorkAreaByIndex(1) ~= nil
		v9_.workAreaParameters = {}
		v9_.workAreaParameters.sprayVehicle = nil
		v9_.workAreaParameters.sprayVehicleFillUnitIndex = nil
		v9_.workAreaParameters.lastChangedArea = 0
		v9_.workAreaParameters.lastTotalArea = 0
		v9_.workAreaParameters.lastIsExternallyFilled = false
		v9_.workAreaParameters.lastSprayTime = -math.huge
		v9_.workAreaParameters.usage = 0
		v9_.workAreaParameters.usagePerMin = 0
		if not v9_.hasWorkAreas then
			SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Sprayer)
		end
	end
end

-- Local values: spec, _, sprayType
function Sprayer:onDelete()
	local v25_ = self.spec_sprayer
	g_effectManager:deleteEffects(v25_.effects)
	g_animationManager:deleteAnimations(v25_.animationNodes)
	if v25_.samples ~= nil then
		g_soundManager:deleteSamples(v25_.samples.work)
		g_soundManager:deleteSamples(v25_.samples.spray)
	end
	if v25_.sprayTypes ~= nil then
		for _, v26_ in ipairs(v25_.sprayTypes) do
			g_effectManager:deleteEffects(v26_.effects)
			g_animationManager:deleteAnimations(v26_.animationNodes)
			if v26_.samples ~= nil then
				g_soundManager:deleteSamples(v26_.samples.work)
				g_soundManager:deleteSamples(v26_.samples.spray)
			end
		end
	end
end

-- Local values: activeSprayType, spec, _, sprayType, spec, actionEvent, text, _, isAllowed, spec
function Sprayer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v28_ = self:getActiveSprayType()
	if v28_ ~= nil then
		local v29_ = self.spec_sprayer
		if v28_ ~= v29_.lastActiveSprayType then
			for _, v30_ in ipairs(v29_.sprayTypes) do
				if v30_ == v29_.lastActiveSprayType then
					g_effectManager:stopEffects(v30_.effects)
					g_animationManager:stopAnimations(v30_.animationNodes)
				end
			end
			SpecializationUtil.raiseEvent(self, "onSprayTypeChange", v28_)
			v29_.lastActiveSprayType = v28_
			self:updateSprayerEffects(true)
		end
	end
	if self.isClient then
		local v31_ = self.spec_sprayer
		local v32_ = v31_.actionEvents[v31_.toggleDoubledAmountInputBinding]
		if v32_ ~= nil then
			local v33_
			if v31_.doubledAmountIsActive then
				v33_ = v31_.doubledAmountDeactivateText
			else
				v33_ = v31_.doubledAmountActivateText
			end
			g_inputBinding:setActionEventText(v32_.actionEventId, v33_)
			local _, v34_ = self:getSprayerDoubledAmountActive(v31_.workAreaParameters.sprayType)
			g_inputBinding:setActionEventActive(v32_.actionEventId, v34_)
		end
	end
	if self.isServer then
		local v35_ = self.spec_sprayer
		if v35_.pendingActivationAfterLowering and self:getCanBeTurnedOn() then
			self:setIsTurnedOn(true)
			v35_.pendingActivationAfterLowering = false
		end
	end
end

-- Local values: spec, _, actionEventId
function Sprayer:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v38_ = self.spec_sprayer
		self:clearActionEventsTable(v38_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v39_ = self:addActionEvent(v38_.actionEvents, v38_.toggleDoubledAmountInputBinding, self, Sprayer.actionEventDoubledAmount, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v39_, GS_PRIO_HIGH)
		end
	end
end

function Sprayer:actionEventDoubledAmount(actionName, inputValue, callbackState, isAnalog)
	self:setSprayerDoubledAmountActive(not self.spec_sprayer.doubledAmountIsActive)
end

-- Local values: spec, rootVehicle, sx, _, sz, wx, _, wz, hx, _, hz, sprayAmount, changedArea, totalArea
function Sprayer:processSprayerArea(workArea, dt)
	local v43_ = self.spec_sprayer
	if self:getIsAIActive() and (self.isServer and (v43_.workAreaParameters.sprayFillType == nil or v43_.workAreaParameters.sprayFillType == FillType.UNKNOWN)) then
		self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
		return 0, 0
	end
	if v43_.workAreaParameters.sprayFillLevel <= 0 then
		return 0, 0
	end
	local v44_, _, v45_ = getWorldTranslation(workArea.start)
	local v46_, _, v47_ = getWorldTranslation(workArea.width)
	local v48_, _, v49_ = getWorldTranslation(workArea.height)
	if not self.isServer and self.currentUpdateDistance > Sprayer.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v50_ = self:getSprayerDoubledAmountActive(v43_.workAreaParameters.sprayType) and 2 or 1
	local v51_, v52_ = FSDensityMapUtil.updateSprayArea(v44_, v45_, v46_, v47_, v48_, v49_, v43_.workAreaParameters.sprayType, v50_)
	v43_.workAreaParameters.isActive = true
	v43_.workAreaParameters.lastChangedArea = v43_.workAreaParameters.lastChangedArea + v51_
	v43_.workAreaParameters.lastStatsArea = v43_.workAreaParameters.lastStatsArea + v51_
	v43_.workAreaParameters.lastTotalArea = v43_.workAreaParameters.lastTotalArea + v52_
	v43_.workAreaParameters.lastSprayTime = g_time
	if self:getLastSpeed() > 1 then
		v43_.isWorking = true
	end
	return v51_, v52_
end

-- Local values: sprayCapacity, spec, hasSource, _, supportedSprayType, spec
function Sprayer:getIsSprayerExternallyFilled()
	if not self:getIsAIActive() then
		return false
	end
	if self:getFillUnitCapacity(self:getSprayerFillUnitIndex()) == 0 then
		local v54_ = self.spec_sprayer
		local v55_ = false
		for _, v56_ in ipairs(v54_.supportedSprayTypes) do
			if #v54_.fillTypeSources[v56_] > 0 then
				v55_ = true
				break
			end
		end
		if not v55_ then
			return false
		end
	end
	if self.rootVehicle.getIsFieldWorkActive == nil or not self.rootVehicle:getIsFieldWorkActive() then
		return false
	end
	local v57_ = self.spec_sprayer
	local v58_ = ((not v57_.isSlurryTanker or g_currentMission.missionInfo.helperSlurrySource <= 1) and true or false) and (((not v57_.isManureSpreader or g_currentMission.missionInfo.helperManureSource <= 1) and true or false) and v57_.isFertilizerSprayer)
	if v58_ then
		v58_ = g_currentMission.missionInfo.helperBuyFertilizer
	end
	return v58_
end

-- Local values: found, isUnknownFillType, fillUnitIndex, allowLiquidManure, allowDigestate, allowManure, allowLiquidFertilizer, allowFertilizer, allowHerbicide, allowsLiquidManureDigistate, usage, farmId, statsFarmId, price, loadingStation, remainingDelta, price, loadingStation, remainingDelta, price
function Sprayer:getExternalFill(fillType, dt)
	local v62_ = false
	local v63_ = fillType == FillType.UNKNOWN
	local v64_ = self:getSprayerFillUnitIndex()
	local v65_ = self:getFillUnitAllowsFillType(v64_, FillType.LIQUIDMANURE)
	local v66_ = self:getFillUnitAllowsFillType(v64_, FillType.DIGESTATE)
	local v67_ = self:getFillUnitAllowsFillType(v64_, FillType.MANURE)
	local v68_ = self:getFillUnitAllowsFillType(v64_, FillType.LIQUIDFERTILIZER)
	local v69_ = self:getFillUnitAllowsFillType(v64_, FillType.FERTILIZER)
	local v70_ = self:getFillUnitAllowsFillType(v64_, FillType.HERBICIDE)
	local v71_ = 0
	local v72_ = self:getActiveFarm()
	local v73_ = self:getLastTouchedFarmlandFarmId()
	if fillType == FillType.LIQUIDMANURE or (fillType == FillType.DIGESTATE or v63_ and (v65_ or v66_)) then
		if g_currentMission.missionInfo.helperSlurrySource == 2 then
			v62_ = true
			if g_currentMission.economyManager:getCostPerLiter(FillType.LIQUIDMANURE, false) then
				fillType = FillType.LIQUIDMANURE
			else
				fillType = FillType.DIGESTATE
			end
			v71_ = self:getSprayerUsage(fillType, dt)
			if self.isServer then
				local v74_ = v71_ * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5
				g_farmManager:updateFarmStats(v73_, "expenses", v74_)
				g_currentMission:addMoney(-v74_, v72_, MoneyType.PURCHASE_FERTILIZER)
			end
		elseif g_currentMission.missionInfo.helperSlurrySource > 2 then
			local v75_ = g_currentMission.liquidManureLoadingStations[g_currentMission.missionInfo.helperSlurrySource - 2]
			if self.isServer and v75_ ~= nil then
				v71_ = self:getSprayerUsage(FillType.LIQUIDMANURE, dt)
				if v71_ - v75_:removeFillLevel(FillType.LIQUIDMANURE, v71_, v72_ or self:getOwnerFarmId()) > 1e-6 then
					fillType = FillType.LIQUIDMANURE
					v62_ = true
				elseif v71_ - v75_:removeFillLevel(FillType.DIGESTATE, v71_, v72_ or self:getOwnerFarmId()) > 1e-6 then
					fillType = FillType.DIGESTATE
					v62_ = true
				end
			end
		end
	elseif fillType == FillType.MANURE or fillType == FillType.UNKNOWN and v67_ then
		if g_currentMission.missionInfo.helperManureSource == 2 then
			v62_ = true
			fillType = FillType.MANURE
			v71_ = self:getSprayerUsage(fillType, dt)
			if self.isServer then
				local v76_ = v71_ * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5
				g_farmManager:updateFarmStats(v73_, "expenses", v76_)
				g_currentMission:addMoney(-v76_, v72_, MoneyType.PURCHASE_FERTILIZER)
			end
		elseif g_currentMission.missionInfo.helperManureSource > 2 then
			local v77_ = g_currentMission.manureLoadingStations[g_currentMission.missionInfo.helperManureSource - 2]
			if self.isServer and v77_ ~= nil then
				v71_ = self:getSprayerUsage(FillType.MANURE, dt)
				if v71_ - v77_:removeFillLevel(FillType.MANURE, v71_, v72_ or self:getOwnerFarmId()) > 1e-6 then
					fillType = FillType.MANURE
					v62_ = true
				end
			end
		end
	elseif (fillType == FillType.FERTILIZER or (fillType == FillType.LIQUIDFERTILIZER or (fillType == FillType.HERBICIDE or (fillType == FillType.LIME or fillType == FillType.UNKNOWN and (v68_ or (v69_ or v70_)))))) and g_currentMission.missionInfo.helperBuyFertilizer then
		v62_ = true
		if fillType == FillType.UNKNOWN then
			if v68_ then
				fillType = FillType.LIQUIDFERTILIZER
			elseif v69_ then
				fillType = FillType.FERTILIZER
			elseif v70_ then
				fillType = FillType.HERBICIDE
			end
		end
		v71_ = self:getSprayerUsage(fillType, dt)
		if self.isServer then
			local v78_ = v71_ * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5
			g_farmManager:updateFarmStats(v73_, "expenses", v78_)
			g_currentMission:addMoney(-v78_, v72_, MoneyType.PURCHASE_FERTILIZER)
		end
	end
	if v62_ then
		return fillType, v71_
	else
		return FillType.UNKNOWN, 0
	end
end

function Sprayer:getAreEffectsVisible()
	return self.spec_sprayer.workAreaParameters.lastSprayTime + 100 > g_time
end

-- Local values: spec, effectsState, fillUnitIndex, fillType, sprayType, _, sprayType
function Sprayer:updateSprayerEffects(force)
	local v82_ = self.spec_sprayer
	local v83_ = self:getAreEffectsVisible()
	if v83_ ~= v82_.lastEffectsState or force then
		if v83_ then
			local v84_ = self:getSprayerFillUnitIndex()
			local v85_ = self:getFillUnitLastValidFillType(v84_)
			if v85_ == FillType.UNKNOWN then
				v85_ = self:getFillUnitFirstSupportedFillType(v84_)
			end
			g_effectManager:setEffectTypeInfo(v82_.effects, v85_)
			g_effectManager:startEffects(v82_.effects)
			g_soundManager:playSamples(v82_.samples.spray)
			local v86_ = self:getActiveSprayType()
			if v86_ ~= nil then
				g_effectManager:setEffectTypeInfo(v86_.effects, v85_)
				g_effectManager:startEffects(v86_.effects)
				g_animationManager:startAnimations(v86_.animationNodes)
				g_soundManager:playSamples(v86_.samples.spray)
			end
			g_animationManager:startAnimations(v82_.animationNodes)
		else
			g_effectManager:stopEffects(v82_.effects)
			g_animationManager:stopAnimations(v82_.animationNodes)
			g_soundManager:stopSamples(v82_.samples.spray)
			for _, v87_ in ipairs(v82_.sprayTypes) do
				g_effectManager:stopEffects(v87_.effects)
				g_animationManager:stopAnimations(v87_.animationNodes)
				g_soundManager:stopSamples(v87_.samples.spray)
			end
		end
		v82_.lastEffectsState = v83_
	end
end

-- Local values: spec, scale, litersPerSecond, sprayType, usageScale, activeSprayType, workWidth
function Sprayer:getSprayerUsage(fillType, dt)
	if fillType == FillType.UNKNOWN then
		return 0
	end
	local v91_ = self.spec_sprayer
	local v92_ = Utils.getNoNil(v91_.usageScale.fillTypeScales[fillType], v91_.usageScale.default)
	local v93_ = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
	local v94_ = v93_ == nil and 1 or v93_.litersPerSecond
	local v95_ = v91_.usageScale
	local v96_ = self:getActiveSprayType()
	if v96_ ~= nil then
		v95_ = v96_.usageScale
	end
	local v97_
	if v95_.workAreaIndex == nil then
		v97_ = v95_.workingWidth
	else
		v97_ = self:getWorkAreaWidth(v95_.workAreaIndex)
	end
	return v92_ * v94_ * self.speedLimit * v97_ * dt * 0.001
end

function Sprayer:getUseSprayerAIRequirements()
	return true
end

-- Local values: sprayTypeDesc, weedSystem, weedMapId, weedFirstChannel, weedNumChannels, replacementData, startState, lastState, sourceState, targetState, mission, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, sprayLevelMaxValue, mission, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, _, fruitType
function Sprayer:setSprayerAITerrainDetailProhibitedRange(fillType)
	if self:getUseSprayerAIRequirements() and self.addAITerrainDetailProhibitedRange ~= nil then
		self:clearAITerrainDetailRequiredRange()
		self:clearAITerrainDetailProhibitedRange()
		self:clearAIFruitRequirements()
		self:clearAIFruitProhibitions()
		local v100_ = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
		if v100_ ~= nil then
			if v100_.isHerbicide then
				local v101_ = g_currentMission.weedSystem
				if v101_ ~= nil then
					local v102_, v103_, v104_ = v101_:getDensityMapData()
					local v105_ = v101_:getHerbicideReplacements()
					if v105_.weed ~= nil then
						local v106_ = -1
						local v107_ = -1
						for v108_, _ in pairs(v105_.weed.replacements) do
							if v106_ == -1 then
								v106_ = v108_
							elseif v108_ ~= v107_ + 1 then
								self:addAIFruitRequirement(nil, v106_, v107_, v102_, v103_, v104_)
								v106_ = v108_
							end
							v107_ = v108_
						end
						if v106_ ~= -1 then
							self:addAIFruitRequirement(nil, v106_, v107_, v102_, v103_, v104_)
						end
					end
				end
			elseif v100_.isFertilizer then
				self:addAIGroundTypeRequirements(Sprayer.AI_REQUIRED_GROUND_TYPES)
				local v109_ = g_currentMission
				local v110_, v111_, v112_ = v109_.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
				local v113_, v114_, v115_ = v109_.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
				local v116_ = v109_.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
				self:addAIFruitProhibitions(0, v100_.sprayGroundType, v100_.sprayGroundType, v110_, v111_, v112_)
				self:addAIFruitProhibitions(0, v116_, v116_, v113_, v114_, v115_)
			elseif v100_.isLime then
				self:addAIGroundTypeRequirements(Sprayer.AI_REQUIRED_GROUND_TYPES)
				local v117_, v118_, v119_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
				self:addAIFruitProhibitions(0, v100_.sprayGroundType, v100_.sprayGroundType, v117_, v118_, v119_)
			end
			if v100_.isHerbicide or (v100_.isFertilizer or v100_.isLime) then
				for _, v120_ in pairs(g_fruitTypeManager:getFruitTypes()) do
					if v120_.terrainDataPlaneId ~= nil and (string.lower(v120_.name) ~= "grass" and (v120_.minHarvestingGrowthState ~= nil and v120_.maxHarvestingGrowthState ~= nil)) then
						self:addAIFruitProhibitions(v120_.index, v120_.minHarvestingGrowthState, v120_.maxHarvestingGrowthState)
					end
				end
			end
		end
	end
end

-- Local values: sprayType
function Sprayer:getSprayerFillUnitIndex()
	local v122_ = self:getActiveSprayType()
	if v122_ == nil then
		return self.spec_sprayer.fillUnitIndex
	else
		return v122_.fillUnitIndex
	end
end

-- Local values: fillTypesStr
function Sprayer:loadSprayTypeFromXML(xmlFile, key, sprayType)
	sprayType.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", 1)
	sprayType.unloadInfoIndex = xmlFile:getValue(key .. "#unloadInfoIndex", 1)
	sprayType.fillVolumeIndex = xmlFile:getValue(key .. "#fillVolumeIndex")
	sprayType.supportsVariableWorkWidth = xmlFile:getValue(key .. "#supportsVariableWorkWidth", true)
	sprayType.samples = {}
	sprayType.samples.work = g_soundManager:loadSamplesFromXML(xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	sprayType.samples.spray = g_soundManager:loadSamplesFromXML(xmlFile, key .. ".sounds", "spray", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	sprayType.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", self.components, self, self.i3dMappings)
	sprayType.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
	sprayType.turnedAnimation = xmlFile:getValue(key .. ".turnedAnimation#name", "")
	sprayType.turnedAnimationTurnOnSpeedScale = xmlFile:getValue(key .. ".turnedAnimation#turnOnSpeedScale", 1)
	sprayType.turnedAnimationTurnOffSpeedScale = xmlFile:getValue(key .. ".turnedAnimation#turnOffSpeedScale", -sprayType.turnedAnimationTurnOnSpeedScale)
	sprayType.turnedAnimationExternalFill = xmlFile:getValue(key .. ".turnedAnimation#externalFill", true)
	if self.loadAIImplementBaseSetupFromXML ~= nil then
		self:loadAIImplementBaseSetupFromXML(xmlFile, key .. ".ai", function(self)
			-- upvalues: (copy) self, (copy) sprayType
			return self:getIsSprayTypeActive(sprayType)
		end)
	end
	local v127_ = xmlFile:getValue(key .. "#fillTypes")
	if v127_ ~= nil then
		sprayType.fillTypes = v127_:split(" ")
	end
	sprayType.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, sprayType.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(sprayType.objectChanges, false, self, self.setMovingToolDirty)
	sprayType.usageScale = {}
	if xmlFile:hasProperty(key .. ".usageScales") then
		sprayType.usageScale.workingWidth = xmlFile:getValue(key .. ".usageScales#workingWidth", 12)
		sprayType.usageScale.workAreaIndex = xmlFile:getValue(key .. ".usageScales#workAreaIndex")
	else
		sprayType.usageScale.workingWidth = self.spec_sprayer.usageScale.workingWidth
		sprayType.usageScale.workAreaIndex = self.spec_sprayer.usageScale.workAreaIndex
	end
	return true
end

-- Local values: spec, _, sprayType
function Sprayer:getActiveSprayType()
	local v129_ = self.spec_sprayer
	for _, v130_ in ipairs(v129_.sprayTypes) do
		if self:getIsSprayTypeActive(v130_) then
			return v130_
		end
	end
	return nil
end

-- Local values: retValue, currentFillType, _, fillType
function Sprayer:getIsSprayTypeActive(sprayType)
	if sprayType.fillTypes ~= nil then
		local v133_ = self:getFillUnitFillType(sprayType.fillUnitIndex or self.spec_sprayer.fillUnitIndex)
		local v134_ = false
		for _, v135_ in ipairs(sprayType.fillTypes) do
			if v133_ == g_fillTypeManager:getFillTypeIndexByName(v135_) then
				v134_ = true
			end
		end
		if not v134_ then
			return false
		end
	end
	return true
end

-- Local values: spec
function Sprayer:setSprayerDoubledAmountActive(isActive, noEventSend)
	local v139_ = self.spec_sprayer
	if isActive ~= v139_.doubledAmountIsActive then
		v139_.doubledAmountIsActive = isActive
		SprayerDoubledAmountEvent.sendEvent(self, isActive, noEventSend)
	end
end

-- Local values: spec, desc
function Sprayer:getSprayerDoubledAmountActive(sprayTypeIndex)
	local v142_ = self.spec_sprayer
	if not v142_.isFertilizerSprayer then
		if sprayTypeIndex == nil then
			return v142_.doubledAmountIsActive, true
		end
		local v143_ = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if v143_ == nil then
			return v142_.doubledAmountIsActive, true
		end
		if v143_.isFertilizer then
			return v142_.doubledAmountIsActive, true
		end
	end
	return false, false
end

-- Local values: spec, fillUnitIndex
function Sprayer:getDrawFirstFillText(superFunc)
	if self.isClient and (self.spec_sprayer.needsToBeFilledToTurnOn and (self:getIsActiveForInput() and (self:getIsSelected() and not self.isAlwaysTurnedOn))) then
		local v146_ = self:getSprayerFillUnitIndex()
		if not self:getCanBeTurnedOn() and (self:getFillUnitFillLevel(v146_) <= 0 and self:getFillUnitCapacity(v146_) > 0) then
			return true
		end
	end
	return superFunc(self)
end

-- Local values: spec
function Sprayer:getAreControlledActionsAllowed(superFunc)
	local v149_ = self.spec_sprayer
	if v149_.needsToBeFilledToTurnOn and (self:getFillUnitFillLevel(v149_.fillUnitIndex) <= 0 and self:getFillUnitCapacity(v149_.fillUnitIndex) ~= 0) then
		return false, g_i18n:getText("info_firstFillTheTool")
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Sprayer:getCanToggleTurnedOn(superFunc)
	if self.isClient and (self.spec_sprayer.needsToBeFilledToTurnOn and (not self:getCanBeTurnedOn() and self:getFillUnitCapacity(self:getSprayerFillUnitIndex()) <= 0)) then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec, sprayVehicle, _, supportedSprayType, _, src, vehicle
function Sprayer:getCanBeTurnedOn(superFunc)
	local v154_ = self.spec_sprayer
	if not v154_.allowsSpraying then
		return false
	end
	if self:getFillUnitFillLevel(self:getSprayerFillUnitIndex()) <= 0 and (v154_.needsToBeFilledToTurnOn and not self:getIsAIActive()) then
		local v155_ = nil
		for _, v156_ in ipairs(v154_.supportedSprayTypes) do
			for _, v157_ in ipairs(v154_.fillTypeSources[v156_]) do
				local v158_ = v157_.vehicle
				if v158_:getFillUnitFillType(v157_.fillUnitIndex) == v156_ and v158_:getFillUnitFillLevel(v157_.fillUnitIndex) > 0 then
					v155_ = v158_
					break
				end
			end
		end
		if v155_ == nil then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: retValue
function Sprayer:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v164_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.SPRAYER
	end
	workArea.sprayType = xmlFile:getValue(key .. "#sprayType")
	return v164_
end

-- Local values: sprayType
function Sprayer:getIsWorkAreaActive(superFunc, workArea)
	if workArea.sprayType ~= nil then
		local v168_ = self:getActiveSprayType()
		if v168_ ~= nil and v168_.index ~= workArea.sprayType then
			return false
		end
	end
	return superFunc(self, workArea)
end

function Sprayer:doCheckSpeedLimit(superFunc)
	local v171_ = not superFunc(self) and self:getIsTurnedOn()
	if v171_ then
		v171_ = self.spec_sprayer.useSpeedLimit
	end
	return v171_
end

-- Local values: spec, sprayType
function Sprayer:getRawSpeedLimit(superFunc)
	local v174_ = self.spec_sprayer
	local v175_
	if v174_.workAreaParameters == nil then
		v175_ = nil
	else
		v175_ = v174_.workAreaParameters.sprayType
	end
	if self:getSprayerDoubledAmountActive(v175_) and self:getIsTurnedOn() then
		return v174_.doubledAmountSpeed
	else
		return superFunc(self)
	end
end

-- Local values: spec, sprayerFillVolumeIndex, sprayType
function Sprayer:getFillVolumeUVScrollSpeed(superFunc, fillVolumeIndex)
	local v179_ = self.spec_sprayer
	local v180_ = v179_.fillVolumeIndex
	local v181_ = self:getActiveSprayType()
	if v181_ ~= nil then
		v180_ = v181_.fillVolumeIndex or v180_
	end
	if fillVolumeIndex == v180_ and (self:getIsTurnedOn() and not self:getIsSprayerExternallyFilled()) then
		return v179_.dischargeUVScrollSpeed[1], v179_.dischargeUVScrollSpeed[2], v179_.dischargeUVScrollSpeed[3]
	else
		return superFunc(self, fillVolumeIndex)
	end
end

function Sprayer:getAIRequiresTurnOffOnHeadland(superFunc)
	return true
end

-- Local values: spec
function Sprayer:getDirtMultiplier(superFunc)
	if self.spec_sprayer.isWorking then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Sprayer:getWearMultiplier(superFunc)
	if self.spec_sprayer.isWorking then
		return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	else
		return superFunc(self)
	end
end

-- Local values: spec, i, effect, i, sprayType, j, effect
function Sprayer:getEffectByNode(superFunc, node)
	local v189_ = self.spec_sprayer
	for v190_ = 1, #v189_.effects do
		local v191_ = v189_.effects[v190_]
		if node == v191_.node then
			return v191_
		end
	end
	for v192_ = 1, #v189_.sprayTypes do
		local v193_ = v189_.sprayTypes[v192_]
		for v194_ = 1, #v193_.effects do
			local v195_ = v193_.effects[v194_]
			if node == v195_.node then
				return v195_
			end
		end
	end
	return superFunc(self, node)
end

-- Local values: usage
function Sprayer:getVariableWorkWidthUsage(superFunc)
	local v198_ = superFunc(self)
	if v198_ == nil then
		return not self:getIsTurnedOn() and 0 or self.spec_sprayer.workAreaParameters.usagePerMin
	else
		return v198_
	end
end

-- Local values: startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, area, areaTotal
function Sprayer:getAIImplementUseVineSegment(superFunc, placeable, segment, segmentSide)
	local v203_, v204_, v205_, v206_, v207_, v208_ = placeable:getSegmentSideArea(segment, segmentSide)
	local v209_, v210_ = AIVehicleUtil.getAIAreaOfVehicle(self, v203_, v204_, v205_, v206_, v207_, v208_)
	if v210_ > 0 then
		return v209_ / v210_ > 0.1
	else
		return false
	end
end

-- Local values: spec, sprayType
function Sprayer:onTurnedOn()
	local v212_ = self.spec_sprayer
	if self.isClient then
		self:updateSprayerEffects()
		if v212_.animationName ~= "" and self.playAnimation ~= nil then
			self:playAnimation(v212_.animationName, 1, self:getAnimationTime(v212_.animationName), true)
		end
		g_soundManager:playSamples(v212_.samples.work)
		local v213_ = self:getActiveSprayType()
		if v213_ ~= nil then
			g_soundManager:playSamples(v213_.samples.work)
			if v213_.turnedAnimationExternalFill or not self:getIsSprayerExternallyFilled() then
				self:playAnimation(v213_.turnedAnimation, v213_.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(v213_.turnedAnimation), true)
			end
		end
		if v212_.turnedAnimationExternalFill or not self:getIsSprayerExternallyFilled() then
			self:playAnimation(v212_.turnedAnimation, v212_.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(v212_.turnedAnimation), true)
		end
	end
end

-- Local values: spec, _, sprayType
function Sprayer:onTurnedOff()
	local v215_ = self.spec_sprayer
	if self.isClient then
		self:updateSprayerEffects()
		if v215_.animationName ~= "" and self.stopAnimation ~= nil then
			self:stopAnimation(v215_.animationName, true)
		end
		g_soundManager:stopSamples(v215_.samples.work)
		for _, v216_ in ipairs(v215_.sprayTypes) do
			g_soundManager:stopSamples(v216_.samples.work)
			self:playAnimation(v216_.turnedAnimation, v216_.turnedAnimationTurnOffSpeedScale, self:getAnimationTime(v216_.turnedAnimation), true)
		end
		self:playAnimation(v215_.turnedAnimation, v215_.turnedAnimationTurnOffSpeedScale, self:getAnimationTime(v215_.turnedAnimation), true)
	end
end

function Sprayer:onPreDetach(attacherVehicle, jointDescIndex)
	if attacherVehicle.setIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
		attacherVehicle:setIsTurnedOn(false)
	end
end

-- Local values: spec, fillUnitIndex, sprayVehicle, sprayVehicleFillUnitIndex, fillType, usage, sprayFillLevel, _, supportedSprayType, _, src, vehicle, vehicleFillType, vehicleFillLevel, isExternallyFilled, externalFillType, externalUsage, sprayType
function Sprayer:onStartWorkAreaProcessing(dt)
	local v220_ = self.spec_sprayer
	local v221_ = self:getSprayerFillUnitIndex()
	local v222_ = nil
	local v223_ = nil
	local v224_ = self:getFillUnitFillType(v221_)
	local v225_ = self:getSprayerUsage(v224_, dt)
	local v226_ = self:getFillUnitFillLevel(v221_)
	if v226_ > 0 then
		v222_ = self
		v223_ = v221_
	else
		for _, v227_ in ipairs(v220_.supportedSprayTypes) do
			for _, v228_ in ipairs(v220_.fillTypeSources[v227_]) do
				local v229_ = v228_.vehicle
				if v229_:getIsFillUnitActive(v228_.fillUnitIndex) then
					local v230_ = v229_:getFillUnitFillType(v228_.fillUnitIndex)
					local v231_ = v229_:getFillUnitFillLevel(v228_.fillUnitIndex)
					if v231_ > 0 and v230_ == v227_ then
						v223_ = v228_.fillUnitIndex
						v224_ = v229_:getFillUnitFillType(v223_)
						v225_ = self:getSprayerUsage(v224_, dt)
						v222_ = v229_
						v226_ = v231_
						break
					end
				elseif self:getIsAIActive() and (v229_.setIsTurnedOn ~= nil and not v229_:getIsTurnedOn()) then
					v229_:setIsTurnedOn(true)
				end
			end
		end
	end
	local v232_ = self:getIsSprayerExternallyFilled()
	local v233_, v234_
	if v232_ and self:getIsTurnedOn() then
		v233_, v234_ = self:getExternalFill(v224_, dt)
		if v233_ == FillType.UNKNOWN then
			v234_ = v226_
			v233_ = v224_
		else
			v225_ = v234_
			v223_ = nil
			v222_ = nil
		end
	else
		v234_ = v226_
		v233_ = v224_
	end
	if v232_ ~= v220_.workAreaParameters.lastIsExternallyFilled then
		local v235_ = self:getActiveSprayType()
		if v235_ ~= nil then
			if v232_ then
				if not v235_.turnedAnimationExternalFill and self:getIsAnimationPlaying(v235_.turnedAnimation) then
					self:stopAnimation(v235_.turnedAnimation)
				end
			elseif not self:getIsAnimationPlaying(v235_.turnedAnimation) then
				self:playAnimation(v235_.turnedAnimation, v235_.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(v235_.turnedAnimation), true)
			end
		end
		if v232_ then
			if not v220_.turnedAnimationExternalFill and self:getIsAnimationPlaying(v220_.turnedAnimation) then
				self:stopAnimation(v220_.turnedAnimation)
			end
		elseif not self:getIsAnimationPlaying(v220_.turnedAnimation) then
			self:playAnimation(v220_.turnedAnimation, v220_.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(v220_.turnedAnimation), true)
		end
		v220_.workAreaParameters.lastIsExternallyFilled = v232_
	end
	if self.isServer and (v233_ ~= FillType.UNKNOWN and v233_ ~= v220_.workAreaParameters.sprayFillType) then
		self:setSprayerAITerrainDetailProhibitedRange(v233_)
	end
	v220_.workAreaParameters.sprayType = g_sprayTypeManager:getSprayTypeIndexByFillTypeIndex(v233_)
	v220_.workAreaParameters.sprayFillType = v233_
	v220_.workAreaParameters.sprayFillLevel = v234_
	v220_.workAreaParameters.usage = v225_
	v220_.workAreaParameters.usagePerMin = v225_ / dt * 1000 * 60
	v220_.workAreaParameters.sprayVehicle = v222_
	v220_.workAreaParameters.sprayVehicleFillUnitIndex = v223_
	v220_.workAreaParameters.lastChangedArea = 0
	v220_.workAreaParameters.lastTotalArea = 0
	v220_.workAreaParameters.lastStatsArea = 0
	v220_.workAreaParameters.isActive = false
	v220_.isWorking = false
end

-- Local values: spec, sprayVehicle, usage, sprayVehicleFillUnitIndex, sprayFillType, unloadInfoIndex, sprayType, unloadInfo, ha, farmId
function Sprayer:onEndWorkAreaProcessing(dt, hasProcessed)
	local v238_ = self.spec_sprayer
	if self.isServer and v238_.workAreaParameters.isActive then
		local v239_ = v238_.workAreaParameters.sprayVehicle
		local v240_ = v238_.workAreaParameters.usage
		if v239_ ~= nil then
			local v241_ = v238_.workAreaParameters.sprayVehicleFillUnitIndex
			local v242_ = v238_.workAreaParameters.sprayFillType
			local v243_ = v238_.unloadInfoIndex
			local v244_ = self:getActiveSprayType()
			if v244_ ~= nil then
				v243_ = v244_.unloadInfoIndex
			end
			local v245_ = self:getFillVolumeUnloadInfo(v243_)
			v239_:addFillUnitFillLevel(self:getOwnerFarmId(), v241_, -v240_, v242_, ToolType.UNDEFINED, v245_)
		end
		local v246_ = MathUtil.areaToHa(v238_.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
		local v247_ = self:getLastTouchedFarmlandFarmId()
		g_farmManager:updateFarmStats(v247_, "sprayedHectares", v246_)
		g_farmManager:updateFarmStats(v247_, "sprayedTime", dt / 60000)
		g_farmManager:updateFarmStats(v247_, "sprayUsage", v240_)
		self:updateLastWorkedArea(v238_.workAreaParameters.lastStatsArea)
	end
	self:updateSprayerEffects()
end

-- Local values: spec, supportedFillTypes, fillType, supported, root
function Sprayer:onStateChange(state, data)
	if state == VehicleStateChange.ATTACH or (state == VehicleStateChange.DETACH or state == VehicleStateChange.FILLTYPE_CHANGE) then
		local v250_ = self.spec_sprayer
		v250_.fillTypeSources = {}
		local v251_ = self:getFillUnitSupportedFillTypes(self:getSprayerFillUnitIndex())
		v250_.supportedSprayTypes = {}
		if v251_ ~= nil then
			for v252_, v253_ in pairs(v251_) do
				if v253_ then
					v250_.fillTypeSources[v252_] = {}
					local v254_ = v250_.supportedSprayTypes
					table.insert(v254_, v252_)
				end
			end
		end
		local v255_ = self.rootVehicle
		FillUnit.addFillTypeSources(v250_.fillTypeSources, v255_, self, v250_.supportedSprayTypes)
	end
end

-- Local values: spec, _, supportedSprayType, _, src, vehicle, fillLevel
function Sprayer:onSetLowered(isLowered)
	local v258_ = self.spec_sprayer
	if self.isServer then
		if v258_.activateOnLowering then
			if self:getCanBeTurnedOn() then
				self:setIsTurnedOn(isLowered)
			else
				v258_.pendingActivationAfterLowering = true
			end
		end
		if not isLowered then
			v258_.pendingActivationAfterLowering = false
		end
	end
	if v258_.activateTankOnLowering then
		for _, v259_ in ipairs(v258_.supportedSprayTypes) do
			for _, v260_ in ipairs(v258_.fillTypeSources[v259_]) do
				local v261_ = v260_.vehicle
				local v262_ = v261_:getFillUnitFillLevel(v260_.fillUnitIndex)
				if v261_.getIsTurnedOn ~= nil then
					if isLowered then
						if v262_ > 0 and v261_:getCanBeTurnedOn() then
							v261_:setIsTurnedOn(true, true)
						end
					else
						v261_:setIsTurnedOn(false, true)
					end
				end
			end
		end
	end
end

-- Local values: spec, fillLevel, hasValidSource, _, src, vehicle, vehicleFillType, vehicleFillLevel
function Sprayer:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local v266_ = self.spec_sprayer
	if fillUnitIndex == v266_.fillUnitIndex and (self:getFillUnitFillLevel(fillUnitIndex) == 0 and (self:getIsTurnedOn() and not self:getIsAIActive())) then
		local v267_ = false
		if v266_.fillTypeSources[fillType] ~= nil then
			for _, v268_ in ipairs(v266_.fillTypeSources[fillType]) do
				local v269_ = v268_.vehicle
				if v269_:getIsFillUnitActive(v268_.fillUnitIndex) then
					local v270_ = v269_:getFillUnitFillType(v268_.fillUnitIndex)
					if v269_:getFillUnitFillLevel(v268_.fillUnitIndex) > 0 and v270_ == fillType then
						v267_ = true
					end
				end
			end
		end
		if not v267_ then
			self:setIsTurnedOn(false)
			if Platform.gameplay.automaticVehicleControl then
				self.rootVehicle:playControlledActions()
			end
		end
	end
end

-- Local values: spec, _, sprayType
function Sprayer:onSprayTypeChange(activeSprayType)
	local v273_ = self.spec_sprayer
	for _, v274_ in ipairs(v273_.sprayTypes) do
		ObjectChangeUtil.setObjectChanges(v274_.objectChanges, v274_ == activeSprayType, self, self.setMovingToolDirty)
	end
	if self.setVariableWorkWidthActive ~= nil then
		self:setVariableWorkWidthActive(activeSprayType == nil and true or activeSprayType.supportsVariableWorkWidth)
	end
end

-- Local values: spec, _, supportedSprayType, _, src, vehicle
function Sprayer:onAIImplementEnd()
	local v276_ = self.spec_sprayer
	for _, v277_ in ipairs(v276_.supportedSprayTypes) do
		for _, v278_ in ipairs(v276_.fillTypeSources[v277_]) do
			local v279_ = v278_.vehicle
			if v279_.getIsTurnedOn ~= nil and v279_:getIsTurnedOn() then
				v279_:setIsTurnedOn(false, true)
			end
		end
	end
end

function Sprayer:onVariableWorkWidthSectionChanged()
	self:updateSprayerEffects(true)
end
function Sprayer.getDefaultSpeedLimit()
	return 15
end
