source("dataS/scripts/vehicles/specializations/events/CombineStrawEnableEvent.lua")
Combine = {}
Combine.DAMAGED_YIELD_REDUCTION = 0.4
Combine.RAIN_YIELD_REDUCTION = 0.5
Combine.CLIENT_DM_UPDATE_RADIUS = 50
function Combine.initSpecialization()
	AIFieldWorker.registerDriveStrategy(function(p1_)
		return SpecializationUtil.hasSpecialization(Combine, p1_.specializations)
	end, AIDriveStrategyCombine)
	g_workAreaTypeManager:addWorkAreaType("combineChopper", false, false, false)
	g_workAreaTypeManager:addWorkAreaType("combineSwath", false, false, false)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Combine")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.combine.warning#noCutter", "No cutter warning", "$l10n_warning_noCuttersAttached")
	v2_:register(XMLValueType.FLOAT, "vehicle.combine#fillLevelBufferTime", "Fill level buffer time for forage harvesters", 2000)
	v2_:register(XMLValueType.BOOL, "vehicle.combine#showTrailerWarning", "Show warning if the combine is turned on, but no trailer below the pipe", false)
	v2_:register(XMLValueType.BOOL, "vehicle.combine#allowThreshingDuringRain", "Allow threshing during rain", false)
	v2_:register(XMLValueType.INT, "vehicle.combine#fillUnitIndex", "Fill unit index", 1)
	v2_:register(XMLValueType.BOOL, "vehicle.combine#turnOffWhenFull", "Turn off the combine while it\'s full", true)
	v2_:register(XMLValueType.INT, "vehicle.combine.buffer#fillUnitIndex", "Buffer fill unit index (This fill unit will be filled first until it\'s full. Will be emptied if stopped to harvest)")
	v2_:register(XMLValueType.TIME, "vehicle.combine.buffer#unloadingTime", "Buffer unloading speed", 0)
	v2_:register(XMLValueType.INT, "vehicle.combine#loadInfoIndex", "Load info index", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.combine#threshingScale", "Scales the yield of the combine", 1)
	v2_:register(XMLValueType.TIME, "vehicle.combine.buffer#loadingDelay", "Time until the crops from the cutter are added to the tank", 0)
	v2_:register(XMLValueType.TIME, "vehicle.combine.buffer#unloadingDelay", "Time until the crops are not longer added to the tank after the cutting has been stopped", "same as #loadingDelay")
	v2_:register(XMLValueType.BOOL, "vehicle.combine.swath#available", "Swath is available", false)
	v2_:register(XMLValueType.BOOL, "vehicle.combine.swath#isDefaultActive", "Swath is default active", "true if available")
	v2_:register(XMLValueType.INT, "vehicle.combine.swath#workAreaIndex", "Swath work area index")
	v2_:register(XMLValueType.BOOL, "vehicle.combine.chopper#available", "Chopper is available", false)
	v2_:register(XMLValueType.BOOL, "vehicle.combine.chopper#isPowered", "Vehicle needs to be powered to switch chopper", true)
	v2_:register(XMLValueType.INT, "vehicle.combine.chopper#workAreaIndex", "Chopper work area index")
	v2_:register(XMLValueType.STRING, "vehicle.combine.chopper#animName", "Chopper toggle animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.chopper#animSpeedScale", "Chopper toggle animation speed", 1)
	v2_:register(XMLValueType.STRING, "vehicle.combine.ladder#animName", "Ladder animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.ladder#animSpeedScale", "Ladder animation speed scale", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.ladder#foldMinLimit", "Min. folding time to fold ladder", 0.99)
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.ladder#foldMaxLimit", "Max. folding time to fold ladder", 1)
	v2_:register(XMLValueType.INT, "vehicle.combine.ladder#foldDirection", "Fold direction to unfold ladder", "signed animation speed")
	v2_:register(XMLValueType.BOOL, "vehicle.combine.ladder#unfoldWhileCutterAttached", "Unfold ladder while a cutter is attached", false)
	v2_:register(XMLValueType.TIME, "vehicle.combine#fillTimeThreshold", "After receiving no input for this threshold time we stop the fill effects", 0.5)
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.processing#toggleTime", "Time from crop cutting to dropping straw", 0)
	v2_:register(XMLValueType.STRING, "vehicle.combine.threshingStartAnimation#name", "Threshing start animation")
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.threshingStartAnimation#speedScale", "Threshing start animation speed scale")
	v2_:register(XMLValueType.BOOL, "vehicle.combine.threshingStartAnimation#initialIsStarted", "Threshing start animation is initial started")
	v2_:register(XMLValueType.INT, "vehicle.combine.additives#fillUnitIndex", "Additives fill unit index")
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.additives#usage", "Usage per picked up liter", 2)
	v2_:register(XMLValueType.STRING, "vehicle.combine.additives#fillTypes", "Fill types to apply additives", "CHAFF GRASS_WINDROW")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.combine.automaticTilt.automaticTiltNode(?)#node", "Automatic tilt node")
	v2_:register(XMLValueType.ANGLE, "vehicle.combine.automaticTilt.automaticTiltNode(?)#minAngle", "Min. angle", -5)
	v2_:register(XMLValueType.ANGLE, "vehicle.combine.automaticTilt.automaticTiltNode(?)#maxAngle", "Max. angle", 5)
	v2_:register(XMLValueType.ANGLE, "vehicle.combine.automaticTilt.automaticTiltNode(?)#maxSpeed", "Max. angle change per second", 2)
	v2_:register(XMLValueType.BOOL, "vehicle.combine.automaticTilt.automaticTiltNode(?)#updateAttacherJoint", "Update cutter attacher joint")
	v2_:register(XMLValueType.STRING, "vehicle.combine.automaticTilt.automaticTiltNode(?)#dependentAnimation", "Animation that is updated depending on tilt state")
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.folding#fillLevelThresholdPct", "Max. fill level to be folded (percentage between 0 and 1)", 0.15)
	v2_:register(XMLValueType.INT, "vehicle.combine.folding#direction", "Folding direction", 1)
	v2_:register(XMLValueType.BOOL, "vehicle.combine.folding#allowWhileThreshing", "Allow folding while combine is threshing", false)
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.combine.chopperEffect")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.combine.strawEffect")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.combine.fillEffect")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.combine.effect")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.combine.animationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.combine.chopperAnimationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.combine.strawDropAnimationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.combine.fillingAnimationNodes")
	v2_:register(XMLValueType.FLOAT, "vehicle.combine.animationNodes#speedReverseFillLevel", "If fill level is above the animation nodes will be reversed (Percent 0-1)")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "start")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "stop")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "work")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "chopperStart")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "chopperStop")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "chopperWork")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "chopStraw")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "dropStraw")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.combine.sounds", "fill")
	Dashboard.registerDashboardXMLPaths(v2_, "vehicle.combine.dashboards", { "workedHectars", "workedHectarsSession" })
	v2_:register(XMLValueType.BOOL, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#activeChopper", "Animation is active while chopper is active", true)
	v2_:register(XMLValueType.BOOL, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#activeStrawDrop", "Animation is active while straw drop is active", true)
	v2_:register(XMLValueType.BOOL, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#waitForStraw", "Animation is active as long as straw is dropped", true)
	v2_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. "#strawDropPercentage", "Amount of straw that is dropped in this area [0-1]", 1)
	v2_:setXMLSpecializationType()
	local v3_ = Vehicle.xmlSchemaSavegame
	v3_:register(XMLValueType.BOOL, "vehicles.vehicle(?).combine#isSwathActive", "Swath is active")
	v3_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).combine#workedHectars", "Worked hectars")
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).combine#numAttachedCutters", "Number of last attached cutters")
end

function Combine.prerequisitesPresent(specializations)
	local v5_ = SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(FillUnit, specializations) and (SpecializationUtil.hasSpecialization(Drivable, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	if v5_ then
		v5_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
	return v5_
end

function Combine.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onStartThreshing")
	SpecializationUtil.registerEvent(vehicleType, "onStopThreshing")
end

function Combine.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineSetup", Combine.loadCombineSetup)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineEffects", Combine.loadCombineEffects)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineRotationNodes", Combine.loadCombineRotationNodes)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineSamples", Combine.loadCombineSamples)
	SpecializationUtil.registerFunction(vehicleType, "setIsSwathActive", Combine.setIsSwathActive)
	SpecializationUtil.registerFunction(vehicleType, "processCombineChopperArea", Combine.processCombineChopperArea)
	SpecializationUtil.registerFunction(vehicleType, "processCombineSwathArea", Combine.processCombineSwathArea)
	SpecializationUtil.registerFunction(vehicleType, "setChopperPSEnabled", Combine.setChopperPSEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setStrawPSEnabled", Combine.setStrawPSEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setCombineIsFilling", Combine.setCombineIsFilling)
	SpecializationUtil.registerFunction(vehicleType, "startThreshing", Combine.startThreshing)
	SpecializationUtil.registerFunction(vehicleType, "stopThreshing", Combine.stopThreshing)
	SpecializationUtil.registerFunction(vehicleType, "setWorkedHectars", Combine.setWorkedHectars)
	SpecializationUtil.registerFunction(vehicleType, "addCutterToCombine", Combine.addCutterToCombine)
	SpecializationUtil.registerFunction(vehicleType, "removeCutterFromCombine", Combine.removeCutterFromCombine)
	SpecializationUtil.registerFunction(vehicleType, "addCutterArea", Combine.addCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "getIsThreshingDuringRain", Combine.getIsThreshingDuringRain)
	SpecializationUtil.registerFunction(vehicleType, "verifyCombine", Combine.verifyCombine)
	SpecializationUtil.registerFunction(vehicleType, "getFillLevelDependentSpeed", Combine.getFillLevelDependentSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getCombineLastValidFillType", Combine.getCombineLastValidFillType)
	SpecializationUtil.registerFunction(vehicleType, "getCombineFillLevelPercentage", Combine.getCombineFillLevelPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getCombineLoadPercentage", Combine.getCombineLoadPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getIsCutterCompatible", Combine.getIsCutterCompatible)
end

function Combine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Combine.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", Combine.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Combine.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Combine.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Combine.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Combine.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Combine.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Combine.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadTurnedOnAnimationFromXML", Combine.loadTurnedOnAnimationFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsTurnedOnAnimationActive", Combine.getIsTurnedOnAnimationActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadRandomlyMovingPartFromXML", Combine.loadRandomlyMovingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsRandomlyMovingPartActive", Combine.getIsRandomlyMovingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeFillType", Combine.getDischargeFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getImplementAllowAutomaticSteering", Combine.getImplementAllowAutomaticSteering)
end

function Combine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetachImplement", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Combine)
end

-- Local values: spec
function Combine:onLoad(savegame)
	local v11_ = self.spec_combine
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.combine.chopperSwitch", "vehicle.combine.swath and vehicle.combine.chopper")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.combine.rotationNodes.rotationNode", "combine")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.workedHectars", "vehicle.combine.dashboards.dashboard with valueType \'workedHectars\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.combine.folding#fillLevelThreshold", "vehicle.combine.folding#fillLevelThresholdPct")
	self:loadCombineSetup(self.xmlFile, "vehicle.combine", v11_)
	self:loadCombineEffects(self.xmlFile, "vehicle.combine", v11_)
	self:loadCombineRotationNodes(self.xmlFile, "vehicle.combine", v11_)
	self:loadCombineSamples(self.xmlFile, "vehicle.combine", v11_)
	v11_.attachedCutters = {}
	v11_.numAttachedCutters = 0
	v11_.texts = {}
	v11_.texts.warningFoldingTurnedOn = g_i18n:getText("warning_foldingNotWhileTurnedOn")
	v11_.texts.warningFoldingWhileFilled = g_i18n:getText("warning_foldingNotWhileFilled")
	v11_.texts.warningRainReducesYield = g_i18n:getText("warning_rainReducesYield")
	v11_.texts.warningNoCutter = self.xmlFile:getValue("vehicle.combine.warning#noCutter", g_i18n:getText("warning_noCuttersAttached"), self.customEnvironment)
	v11_.threshingDuringRainWarningDisplayed = false
	v11_.showTrailerWarning = self.xmlFile:getValue("vehicle.combine#showTrailerWarning", false)
	v11_.lastAreaZeroTime = 0
	v11_.lastAreaNonZeroTime = -1000000
	v11_.lastCuttersArea = 0
	v11_.lastCuttersAreaTime = -10000
	v11_.lastInputFruitType = FruitType.UNKNOWN
	v11_.lastValidInputFruitType = FruitType.UNKNOWN
	v11_.lastCuttersFruitType = FruitType.UNKNOWN
	v11_.lastCuttersInputFruitType = FruitType.UNKNOWN
	v11_.lastValidInputFillType = FillType.UNKNOWN
	v11_.lastDischargeTime = 0
	v11_.lastChargeTime = 0
	v11_.fillLevelBufferTime = self.xmlFile:getValue("vehicle.combine#fillLevelBufferTime", 2000)
	v11_.workedHectars = 0
	v11_.workedHectarsSent = 0
	v11_.workedHectarsInitial = 0
	v11_.threshingScale = self.xmlFile:getValue("vehicle.combine#threshingScale", 1)
	v11_.lastLostFillLevel = 0
	v11_.workAreaParameters = {}
	v11_.workAreaParameters.litersToDrop = 0
	v11_.workAreaParameters.droppedLiters = 0
	v11_.workAreaParameters.minLitersToDrop = 0
	v11_.workAreaParameters.isChopperEffectEnabled = 0
	v11_.workAreaParameters.isStrawEffectEnabled = 0
	v11_.workAreaParameters.effectDensity = 0.2
	v11_.workAreaParameters.effectDensitySent = 0.2
	v11_.dirtyFlag = self:getNextDirtyFlag()
	v11_.effectDirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, isSwathActive, fillUnit, ladder, time, foldAnimTime, numAttachedCutters, fillUnit, bufferUnit
function Combine:onPostLoad(savegame)
	local v14_ = self.spec_combine
	if savegame == nil then
		self:setIsSwathActive(v14_.isSwathActive, true, true)
	else
		if v14_.swath.isAvailable then
			self:setIsSwathActive(savegame.xmlFile:getValue(savegame.key .. ".combine#isSwathActive", v14_.isSwathActive), true, true)
		end
		self:setWorkedHectars(savegame.xmlFile:getValue(savegame.key .. ".combine#workedHectars", v14_.workedHectars), true)
	end
	v14_.isBufferCombine = self:getFillUnitCapacity(self.spec_combine.fillUnitIndex) == math.huge
	if v14_.isBufferCombine then
		local v15_ = self:getFillUnitByIndex(self.spec_combine.fillUnitIndex)
		if v15_.showOnInfoHud then
			Logging.xmlWarning(self.xmlFile, "Buffer combine fill unit is displayed in info hud! Add showOnInfoHud=\'false\' to the fill unit.")
		end
		v15_.synchronizeFillLevel = false
	end
	local v16_ = v14_.ladder
	if v16_.animName ~= nil then
		local v17_ = 0
		if self.getFoldAnimTime ~= nil then
			local v18_ = self:getFoldAnimTime()
			v17_ = (v16_.foldMaxLimit < v18_ or v18_ < v16_.foldMinLimit) and 1 or v17_
		end
		local v19_ = v16_.unfoldWhileCutterAttached and (savegame ~= nil and (not savegame.resetVehicles and savegame.xmlFile:getValue(savegame.key .. ".combine#numAttachedCutters", 0) > 0)) and 1 or v17_
		if v16_.foldDirection ~= 1 then
			v19_ = 1 - v19_
		end
		self:setAnimationTime(v16_.animName, v19_, true)
	end
	if v14_.bufferFillUnitIndex ~= nil then
		local v20_ = self:getFillUnitByIndex(v14_.fillUnitIndex)
		local v21_ = self:getFillUnitByIndex(v14_.bufferFillUnitIndex)
		if v20_ ~= nil and v21_ ~= nil then
			v21_.parentUnitOnHud = v14_.fillUnitIndex
			v20_.childUnitOnHud = v14_.bufferFillUnitIndex
		end
	end
	if self:getFillUnitCapacity(v14_.fillUnitIndex) == 0 then
		Logging.xmlWarning(self.xmlFile, "Capacity of fill unit \'%d\' for combine needs to be set greater 0 or not defined! (not defined = infinity)", v14_.fillUnitIndex)
	end
end

-- Local values: spec, workedHectars, workedHectarsSession
function Combine:onRegisterDashboardValueTypes()
	local v_u_23_ = self.spec_combine
	local v24_ = DashboardValueType.new("combine", "workedHectars")
	v24_:setValue(v_u_23_, "workedHectars")
	v24_:setPollUpdate(false)
	self:registerDashboardValueType(v24_)
	local v25_ = DashboardValueType.new("combine", "workedHectarsSession")
	v25_:setValue(v_u_23_, function(_)
		-- upvalues: (copy) v_u_23_
		return v_u_23_.workedHectars - v_u_23_.workedHectarsInitial
	end)
	v25_:setPollUpdate(false)
	self:registerDashboardValueType(v25_)
end

-- Local values: spec
function Combine:onDelete()
	local v27_ = self.spec_combine
	g_effectManager:deleteEffects(v27_.effects)
	g_effectManager:deleteEffects(v27_.fillEffects)
	g_effectManager:deleteEffects(v27_.strawEffects)
	g_effectManager:deleteEffects(v27_.chopperEffects)
	g_animationManager:deleteAnimations(v27_.animationNodes)
	g_animationManager:deleteAnimations(v27_.chopperAnimationNodes)
	g_animationManager:deleteAnimations(v27_.strawDropAnimationNodes)
	g_animationManager:deleteAnimations(v27_.fillingAnimationNodes)
	g_soundManager:deleteSamples(v27_.samples)
end

-- Local values: spec
function Combine:saveToXMLFile(xmlFile, key, usedModNames)
	local v31_ = self.spec_combine
	if v31_.swath.isAvailable then
		xmlFile:setValue(key .. "#isSwathActive", v31_.isSwathActive)
	end
	xmlFile:setValue(key .. "#workedHectars", v31_.workedHectars)
	xmlFile:setValue(key .. "#numAttachedCutters", v31_.numAttachedCutters)
end

-- Local values: spec, combineIsFilling, chopperPSenabled, strawPSenabled, isSwathActive, workedHectars
function Combine:onReadStream(streamId, connection)
	local v34_ = self.spec_combine
	v34_.lastValidInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
	local v35_ = streamReadBool(streamId)
	local v36_ = streamReadBool(streamId)
	local v37_ = streamReadBool(streamId)
	v34_.lastValidInputFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	self:setCombineIsFilling(v35_, false, true)
	self:setChopperPSEnabled(v36_, false, 1, true)
	self:setStrawPSEnabled(v37_, false, 1, true)
	self:setIsSwathActive(streamReadBool(streamId), true)
	self:setWorkedHectars(streamReadFloat32(streamId), true)
end

-- Local values: spec
function Combine:onWriteStream(streamId, connection)
	local v40_ = self.spec_combine
	streamWriteUIntN(streamId, v40_.lastValidInputFruitType, FruitTypeManager.SEND_NUM_BITS)
	streamWriteBool(streamId, v40_.isFilling)
	streamWriteBool(streamId, v40_.chopperPSenabled)
	streamWriteBool(streamId, v40_.strawPSenabled)
	streamWriteUIntN(streamId, self:getCombineLastValidFillType(), FillTypeManager.SEND_NUM_BITS)
	streamWriteBool(streamId, v40_.isSwathActive)
	streamWriteFloat32(streamId, v40_.workedHectars)
end

-- Local values: spec, workedHectars, combineIsFilling, chopperPSenabled, strawPSenabled, effectDensity
function Combine:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v44_ = self.spec_combine
		if streamReadBool(streamId) then
			v44_.lastValidInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
			self:setWorkedHectars((streamReadFloat32(streamId)))
		end
		if streamReadBool(streamId) then
			local v45_ = streamReadBool(streamId)
			local v46_ = streamReadBool(streamId)
			local v47_ = streamReadBool(streamId)
			local v48_ = streamReadUIntN(streamId, 5) / 31
			v44_.lastValidInputFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
			self:setCombineIsFilling(v45_, false, true)
			self:setChopperPSEnabled(v46_, false, v48_, true)
			self:setStrawPSEnabled(v47_, false, v48_, true)
		end
	end
end

-- Local values: spec
function Combine:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v53_ = self.spec_combine
		local v54_ = streamWriteBool
		local v55_ = v53_.dirtyFlag
		if v54_(streamId, bit32.band(dirtyMask, v55_) ~= 0) then
			streamWriteUIntN(streamId, v53_.lastValidInputFruitType, FruitTypeManager.SEND_NUM_BITS)
			streamWriteFloat32(streamId, v53_.workedHectars)
		end
		local v56_ = streamWriteBool
		local v57_ = v53_.effectDirtyFlag
		if v56_(streamId, bit32.band(dirtyMask, v57_) ~= 0) then
			streamWriteBool(streamId, v53_.isFilling)
			streamWriteBool(streamId, v53_.chopperPSenabled)
			streamWriteBool(streamId, v53_.strawPSenabled)
			streamWriteUIntN(streamId, v53_.workAreaParameters.effectDensity * 31, 5)
			streamWriteUIntN(streamId, self:getCombineLastValidFillType(), FillTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, isTurnedOn, fillUnitIndex, fruitType, fruitDesc, fruitDesc, inputBuffer, i, currentDelta, isActive, doReset, _, cutter, i, automaticTiltNode, _, _, curZ, speedScale, rotSpeed, newRotZ, alpha, jointDesc
function Combine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v60_ = self.spec_combine
	if self:getIsTurnedOn() and (self.isServer and v60_.swath.isAvailable) then
		local v61_ = v60_.bufferFillUnitIndex or v60_.fillUnitIndex
		local v62_ = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(self:getFillUnitFillType(v61_))
		if v60_.isSwathActive and (v62_ ~= nil and v62_ ~= FruitType.UNKNOWN) then
			if not g_fruitTypeManager:getFruitTypeByIndex(v62_).hasWindrow then
				self:setIsSwathActive(false)
			end
		elseif (not v60_.chopper.isAvailable or v60_.automatedChopperSwitch) and (not v60_.isSwathActive and (v62_ ~= nil and (v62_ ~= FruitType.UNKNOWN and g_fruitTypeManager:getFruitTypeByIndex(v62_).hasWindrow))) then
			self:setIsSwathActive(true)
			local v63_ = v60_.processing.inputBuffer
			for v64_ = 1, #v63_.buffer do
				v63_.buffer[v64_].area = 0
				v63_.buffer[v64_].liters = 0
				v63_.buffer[v64_].inputLiters = 0
			end
		end
	end
	if self.isServer and self:getFillUnitFillLevel(v60_.fillUnitIndex) < 0.0001 then
		v60_.lastDischargeTime = g_currentMission.time
	end
	if v60_.automaticTilt.hasNodes then
		local _, v65_ = next(v60_.attachedCutters)
		local v66_, v67_, v68_
		if v65_ == nil or not v65_:getCutterTiltIsAvailable() then
			v66_ = false
			v67_ = false
			v68_ = 0
		else
			v68_, v66_, v67_ = v65_:getCutterTiltDelta()
		end
		for v69_ = 1, #v60_.automaticTilt.nodes do
			local v70_ = v60_.automaticTilt.nodes[v69_]
			local _, _, v71_ = getRotation(v70_.node)
			if not v66_ and v67_ then
				v68_ = -v71_
			end
			if math.abs(v68_) > 0.00001 then
				local v72_ = math.abs(v68_) / 0.01745
				local v73_ = math.pow(v72_, 2)
				local v74_ = math.min(v73_, 1) * math.sign(v68_)
				if not v66_ and v67_ then
					v74_ = v74_ * 0.5
				end
				local v75_ = v71_ + v74_ * v70_.maxSpeed * dt
				local v76_ = v70_.minAngle
				local v77_ = v70_.maxAngle
				local v78_ = math.clamp(v75_, v76_, v77_)
				setRotation(v70_.node, 0, 0, v78_)
				if v70_.dependentAnimation ~= nil then
					local v79_ = MathUtil.inverseLerp(v70_.minAngle, v70_.maxAngle, v78_)
					self:setAnimationTime(v70_.dependentAnimation, v79_, true)
				end
				if v65_ ~= nil and v70_.updateAttacherJoint then
					local v80_ = v78_ - v70_.lastJointUpdateRot
					if math.abs(v80_) > 0.00001 then
						v70_.lastJointUpdateRot = v78_
						local v81_ = self:getAttacherJointDescFromObject(v65_)
						if v81_.jointIndex ~= 0 then
							setJointFrame(v81_.jointIndex, 0, v81_.jointTransform)
						end
					end
				end
				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(v70_.node)
				end
			end
		end
	end
end

-- Local values: spec, inputBuffer, density, chopperPSActive, strawPSActive, lastDropIndex, deltaFillLevel, i, slot
function Combine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v84_ = self.spec_combine
	if self.isServer then
		v84_.lastInputFruitType = v84_.lastCuttersInputFruitType
		v84_.lastCuttersArea = 0
		v84_.lastCuttersInputFruitType = FruitType.UNKNOWN
		v84_.lastCuttersFruitType = FruitType.UNKNOWN
		if v84_.lastInputFruitType ~= nil and v84_.lastInputFruitType ~= FruitType.UNKNOWN then
			v84_.lastValidInputFruitType = v84_.lastInputFruitType
		end
		local v85_ = v84_.processing.inputBuffer
		v84_.lastAreaZeroTime = v84_.lastAreaZeroTime + dt
		if v84_.lastAreaZeroTime > v84_.fillTimeThreshold and v84_.fillDisableTime == nil then
			v84_.fillDisableTime = g_currentMission.time + v84_.processing.toggleTime
		end
		if v84_.fillEnableTime ~= nil and v84_.fillEnableTime <= g_currentMission.time then
			self:setCombineIsFilling(true, false, false)
			v84_.fillEnableTime = nil
		end
		if v84_.fillDisableTime ~= nil and v84_.fillDisableTime <= g_currentMission.time then
			self:setCombineIsFilling(false, false, false)
			v84_.fillDisableTime = nil
		end
		local v86_ = v84_.workAreaParameters
		local v87_ = v84_.workAreaParameters.isChopperEffectEnabled - dt
		v86_.isChopperEffectEnabled = math.max(v87_, 0)
		local v88_ = v84_.workAreaParameters
		local v89_ = v84_.workAreaParameters.isStrawEffectEnabled - dt
		v88_.isStrawEffectEnabled = math.max(v89_, 0)
		local v90_ = v84_.workAreaParameters.effectDensity
		local v91_ = v84_.workAreaParameters.isChopperEffectEnabled > 0
		local v92_ = v84_.workAreaParameters.isStrawEffectEnabled > 0
		self:setChopperPSEnabled(v91_, false, v90_, false)
		self:setStrawPSEnabled(v92_, false, v90_, false)
		if v91_ or v92_ then
			self:raiseActive()
		end
		if self:getIsTurnedOn() then
			g_farmManager:updateFarmStats(self:getOwnerFarmId(), "threshedTime", dt / 60000)
			self:updateLastWorkedArea(0)
		end
		v85_.slotTimer = v85_.slotTimer - dt
		if v85_.slotTimer < 0 then
			v85_.slotTimer = v85_.slotDuration
			v85_.fillIndex = v85_.fillIndex + 1
			if v85_.fillIndex > v85_.slotCount then
				v85_.fillIndex = 1
			end
			local v93_ = v85_.dropIndex
			v85_.dropIndex = v85_.dropIndex + 1
			if v85_.dropIndex > v85_.slotCount then
				v85_.dropIndex = 1
			end
			v85_.buffer[v85_.dropIndex].liters = v85_.buffer[v85_.dropIndex].liters + v85_.buffer[v93_].liters
			v85_.buffer[v85_.dropIndex].inputLiters = v85_.buffer[v85_.dropIndex].inputLiters + v85_.buffer[v93_].liters
			v85_.buffer[v93_].area = 0
			v85_.buffer[v93_].liters = 0
			v85_.buffer[v93_].inputLiters = 0
		end
		if v84_.bufferFillUnitIndex ~= nil and (v84_.lastCuttersAreaTime + dt * 10 < g_currentMission.time and self:getFillUnitFillLevel(v84_.bufferFillUnitIndex) > 0) then
			local v94_ = dt * (self:getFillUnitCapacity(v84_.bufferFillUnitIndex) / v84_.bufferUnloadingTime)
			local v95_ = self:addFillUnitFillLevel(self:getOwnerFarmId(), v84_.bufferFillUnitIndex, -v94_, self:getFillUnitFillType(v84_.bufferFillUnitIndex), ToolType.UNDEFINED)
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v84_.fillUnitIndex, -v95_, self:getFillUnitFillType(v84_.bufferFillUnitIndex), ToolType.UNDEFINED, self:getFillVolumeLoadInfo(v84_.loadInfoIndex))
		end
		if v84_.loadingDelay > 0 then
			for v96_ = 1, #v84_.loadingDelaySlots do
				local v97_ = v84_.loadingDelaySlots[v96_]
				if v97_.valid and v97_.time + v84_.loadingDelay < g_currentMission.time then
					v97_.valid = false
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v84_.fillUnitIndex, v97_.fillLevelDelta, v97_.fillType, ToolType.UNDEFINED, self:getFillVolumeLoadInfo(v84_.loadInfoIndex))
				end
			end
		end
		if v84_.isFilling ~= v84_.sentIsFilling or (v84_.chopperPSenabled ~= v84_.sentChopperPSenabled or v84_.strawPSenabled ~= v84_.sentStrawPSenabled) then
			::l43::
			self:raiseDirtyFlags(v84_.effectDirtyFlag)
			v84_.sentIsFilling = v84_.isFilling
			v84_.sentChopperPSenabled = v84_.chopperPSenabled
			v84_.sentStrawPSenabled = v84_.strawPSenabled
			v84_.workAreaParameters.effectDensitySent = v84_.workAreaParameters.effectDensity
			goto l2
		end
		local v98_ = v84_.workAreaParameters.effectDensity - v84_.workAreaParameters.effectDensitySent
		if math.abs(v98_) > 0.05 then
			goto l43
		end
	end
	::l2::
end

-- Local values: spec, isTurnedOn, dischargeNode
function Combine:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v101_ = self.spec_combine
	local v102_ = self:getIsTurnedOn()
	if v102_ and self:getIsThreshingDuringRain(false) then
		if not v101_.threshingDuringRainWarningDisplayed then
			g_currentMission:showBlinkingWarning(v101_.texts.warningRainReducesYield, 4000)
			v101_.threshingDuringRainWarningDisplayed = true
		end
	else
		v101_.threshingDuringRainWarningDisplayed = false
	end
	if v101_.showTrailerWarning and (v102_ and isActiveForInputIgnoreSelection) then
		local v103_ = self:getCurrentDischargeNode()
		if v103_ ~= nil and not v103_.dischargeHitObject then
			g_currentMission:addExtraPrintText(g_i18n:getText("warning_harvesterRequiresTrailer"))
		end
	end
end

-- Local values: i, isDefaultActive, toggleTime, inputBuffer, slotDuration, slotCount, _, additivesFillTypeNames
function Combine:loadCombineSetup(xmlFile, baseKey, entry)
	entry.allowThreshingDuringRain = xmlFile:getValue(baseKey .. "#allowThreshingDuringRain", false)
	entry.fillUnitIndex = xmlFile:getValue(baseKey .. "#fillUnitIndex", 1)
	entry.turnOffWhenFull = xmlFile:getValue(baseKey .. "#turnOffWhenFull", true)
	entry.bufferFillUnitIndex = xmlFile:getValue(baseKey .. ".buffer#fillUnitIndex")
	entry.bufferUnloadingTime = xmlFile:getValue(baseKey .. ".buffer#unloadingTime", 0)
	entry.loadInfoIndex = xmlFile:getValue(baseKey .. "#loadInfoIndex", 1)
	entry.loadingDelay = xmlFile:getValue(baseKey .. ".buffer#loadingDelay", 0)
	if entry.loadingDelay > 0 then
		entry.unloadingDelay = xmlFile:getValue(baseKey .. ".buffer#unloadingDelay", entry.loadingDelay / 1000)
		entry.loadingDelaySlotsDelayedInsert = false
		entry.loadingDelaySlots = {}
		for v108_ = 1, entry.loadingDelay / 1000 * 60 + 1 do
			entry.loadingDelaySlots[v108_] = {
				["time"] = -math.huge,
				["fillLevelDelta"] = 0,
				["fillType"] = 0,
				["valid"] = false
			}
		end
	end
	entry.swath = {}
	entry.swath.isAvailable = xmlFile:getValue(baseKey .. ".swath#available", false)
	local v109_ = xmlFile:getValue(baseKey .. ".swath#isDefaultActive", entry.swath.isAvailable)
	if entry.swath.isAvailable then
		entry.swath.workAreaIndex = xmlFile:getValue(baseKey .. ".swath#workAreaIndex")
		if entry.swath.workAreaIndex == nil then
			entry.swath.isAvailable = false
			Logging.xmlWarning(xmlFile, "Missing \'swath#workAreaIndex\' for combine swath function!")
		end
		entry.warningTime = 0
	end
	entry.chopper = {}
	entry.chopper.isAvailable = xmlFile:getValue(baseKey .. ".chopper#available", false)
	entry.chopper.isPowered = xmlFile:getValue(baseKey .. ".chopper#isPowered", true)
	if entry.chopper.isAvailable then
		entry.chopper.workAreaIndex = xmlFile:getValue(baseKey .. ".chopper#workAreaIndex")
		if entry.chopper.workAreaIndex == nil then
			entry.chopper.isAvailable = false
			Logging.xmlWarning(xmlFile, "Missing \'chopper#workAreaIndex\' for combine chopper function!")
		end
		entry.chopper.animName = xmlFile:getValue(baseKey .. ".chopper#animName")
		entry.chopper.animSpeedScale = xmlFile:getValue(baseKey .. ".chopper#animSpeedScale", 1)
	end
	entry.automatedChopperSwitch = GS_IS_MOBILE_VERSION
	entry.isSwathActive = v109_
	entry.ladder = {}
	entry.ladder.animName = xmlFile:getValue(baseKey .. ".ladder#animName")
	entry.ladder.animSpeedScale = xmlFile:getValue(baseKey .. ".ladder#animSpeedScale", 1)
	entry.ladder.foldMinLimit = xmlFile:getValue(baseKey .. ".ladder#foldMinLimit", 0.99)
	entry.ladder.foldMaxLimit = xmlFile:getValue(baseKey .. ".ladder#foldMaxLimit", 1)
	local v110_ = entry.ladder
	local v111_ = baseKey .. ".ladder#foldDirection"
	local v112_ = entry.ladder.animSpeedScale
	v110_.foldDirection = xmlFile:getValue(v111_, (math.sign(v112_)))
	entry.ladder.unfoldWhileCutterAttached = xmlFile:getValue(baseKey .. ".ladder#unfoldWhileCutterAttached", false)
	entry.fillTimeThreshold = xmlFile:getValue(baseKey .. "#fillTimeThreshold", 0.5)
	entry.processing = {}
	local v113_ = xmlFile:getValue(baseKey .. ".processing#toggleTime")
	if v113_ == nil and entry.chopper.animName ~= nil then
		v113_ = self:getAnimationDurection(entry.chopper.animName)
		if v113_ ~= nil then
			v113_ = v113_ / 1000
		end
	end
	entry.processing.toggleTime = Utils.getNoNil(v113_, 0) * 1000
	local v114_ = {}
	local v115_ = entry.processing.toggleTime / 300
	local v116_ = math.ceil(v115_)
	v114_.slotCount = math.clamp(v116_, 2, 20)
	local v117_ = entry.processing.toggleTime / v114_.slotCount
	v114_.slotDuration = math.ceil(v117_)
	v114_.fillIndex = 1
	v114_.dropIndex = v114_.fillIndex + 1
	v114_.slotTimer = v114_.slotDuration
	v114_.activeTimeout = v114_.slotDuration * (v114_.slotCount + 2)
	v114_.activeTimer = v114_.activeTimeout
	v114_.buffer = {}
	for _ = 1, v114_.slotCount do
		local v118_ = v114_.buffer
		table.insert(v118_, {
			["area"] = 0,
			["liters"] = 0,
			["inputLiters"] = 0,
			["strawRatio"] = 0,
			["effectDensity"] = 0.2
		})
	end
	entry.processing.inputBuffer = v114_
	entry.threshingStartAnimation = xmlFile:getValue(baseKey .. ".threshingStartAnimation#name")
	entry.threshingStartAnimationSpeedScale = xmlFile:getValue(baseKey .. ".threshingStartAnimation#speedScale", 1)
	entry.threshingStartAnimationInitialIsStarted = xmlFile:getValue(baseKey .. ".threshingStartAnimation#initialIsStarted", false)
	entry.foldFillLevelThreshold = xmlFile:getValue(baseKey .. ".folding#fillLevelThresholdPct", Platform.gameplay.automaticVehicleControl and 0 or 0.15) * (self:getFillUnitCapacity(entry.fillUnitIndex) or 0.04)
	entry.foldDirection = xmlFile:getValue(baseKey .. ".folding#direction", 1)
	entry.allowFoldWhileThreshing = xmlFile:getValue(baseKey .. ".folding#allowWhileThreshing", false)
	entry.additives = {}
	entry.additives.fillUnitIndex = xmlFile:getValue(baseKey .. ".additives#fillUnitIndex")
	entry.additives.available = self:getFillUnitByIndex(entry.additives.fillUnitIndex) ~= nil
	entry.additives.usage = xmlFile:getValue(baseKey .. ".additives#usage", 0)
	local v119_ = xmlFile:getValue(baseKey .. ".additives#fillTypes", "CHAFF GRASS_WINDROW")
	entry.additives.fillTypes = g_fillTypeManager:getFillTypesByNames(v119_, "Warning: \'" .. xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
	entry.automaticTilt = {}
	entry.automaticTilt.nodes = {}
	xmlFile:iterate(baseKey .. ".automaticTilt.automaticTiltNode", function(_, p120_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) entry
		local v121_ = {
			["node"] = xmlFile:getValue(p120_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v121_.node ~= nil then
			v121_.minAngle = xmlFile:getValue(p120_ .. "#minAngle", -5)
			v121_.maxAngle = xmlFile:getValue(p120_ .. "#maxAngle", 5)
			v121_.maxSpeed = xmlFile:getValue(p120_ .. "#maxSpeed", 2) / 1000
			v121_.updateAttacherJoint = xmlFile:getValue(p120_ .. "#updateAttacherJoint")
			v121_.dependentAnimation = xmlFile:getValue(p120_ .. "#dependentAnimation")
			v121_.lastJointUpdateRot = 0
			local v122_ = entry.automaticTilt.nodes
			table.insert(v122_, v121_)
		end
	end)
	if not Platform.gameplay.allowAutomaticHeaderTilt and #entry.automaticTilt.nodes > 0 then
		Logging.xmlWarning(self.xmlFile, "Automatic header tilt is not allowed on this platform!")
		entry.automaticTilt.nodes = {}
	end
	entry.automaticTilt.hasNodes = #entry.automaticTilt.nodes > 0
end

function Combine:loadCombineEffects(xmlFile, baseKey, entry)
	if self.isClient then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. ".chopperParticleSystems", baseKey .. ".chopperEffect")
		XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. ".strawParticleSystems", baseKey .. ".strawEffect")
		XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. ".threshingFillParticleSystems", baseKey .. ".fillEffect")
		entry.chopperEffects = g_effectManager:loadEffect(xmlFile, baseKey .. ".chopperEffect", self.components, self, self.i3dMappings)
		entry.strawEffects = g_effectManager:loadEffect(xmlFile, baseKey .. ".strawEffect", self.components, self, self.i3dMappings)
		entry.fillEffects = g_effectManager:loadEffect(xmlFile, baseKey .. ".fillEffect", self.components, self, self.i3dMappings)
		entry.effects = g_effectManager:loadEffect(xmlFile, baseKey .. ".effect", self.components, self, self.i3dMappings)
		entry.strawPSenabled = false
		entry.chopperPSenabled = false
		entry.isFilling = false
		entry.fillEnableTime = nil
		entry.fillDisableTime = nil
		entry.lastEffectFillType = FillType.UNKNOWN
	end
end

function Combine:loadCombineRotationNodes(xmlFile, baseKey, entry)
	if self.isClient then
		entry.animationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".animationNodes", self.components, self, self.i3dMappings)
		entry.chopperAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".chopperAnimationNodes", self.components, self, self.i3dMappings)
		entry.strawDropAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".strawDropAnimationNodes", self.components, self, self.i3dMappings)
		entry.fillingAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".fillingAnimationNodes", self.components, self, self.i3dMappings)
		entry.rotationNodesSpeedReverseFillLevel = xmlFile:getValue(baseKey .. ".animationNodes#speedReverseFillLevel")
	end
end

function Combine:loadCombineSamples(xmlFile, key, entry)
	if self.isClient then
		entry.samples = {}
		entry.samples.start = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.samples.stop = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.samples.work = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.samples.chopperStart = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "chopperStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.samples.chopperStop = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "chopperStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.samples.chopperWork = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "chopperWork", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.samples.chopStraw = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "chopStraw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.samples.dropStraw = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "dropStraw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.samples.fill = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "fill", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
end

-- Local values: spec, anim, dir, inputBuffer, i
function Combine:setIsSwathActive(isSwathActive, noEventSend, force)
	local v139_ = self.spec_combine
	if isSwathActive ~= v139_.isSwathActive or force then
		CombineStrawEnableEvent.sendEvent(self, isSwathActive, noEventSend)
		v139_.isSwathActive = isSwathActive
		local v140_ = v139_.chopper.animName
		if self.playAnimation ~= nil and v140_ ~= nil then
			self:playAnimation(v140_, (isSwathActive and -1 or 1) * v139_.chopper.animSpeedScale, self:getAnimationTime(v140_), true)
			if force then
				AnimatedVehicle.updateAnimationByName(self, v140_, 9999999, true)
			end
		end
		local v141_ = v139_.processing.inputBuffer
		for v142_ = 1, #v141_.buffer do
			v141_.buffer[v142_].liters = 0
		end
		if self:getIsTurnedOn() and self.isClient then
			if v139_.isSwathActive then
				g_animationManager:stopAnimations(v139_.chopperAnimationNodes)
				g_animationManager:startAnimations(v139_.strawDropAnimationNodes)
				if g_soundManager:getIsSamplePlaying(v139_.samples.chopperWork) then
					g_soundManager:stopSample(v139_.samples.chopperWork)
					g_soundManager:playSample(v139_.samples.chopperStop)
				end
			else
				g_animationManager:stopAnimations(v139_.strawDropAnimationNodes)
				g_animationManager:startAnimations(v139_.chopperAnimationNodes)
				g_soundManager:stopSample(v139_.samples.chopperStop)
				g_soundManager:playSample(v139_.samples.chopperStart)
				g_soundManager:playSample(v139_.samples.chopperWork, 0, v139_.samples.chopperStart)
			end
		end
		Combine.updateToggleStrawText(self)
	end
end

-- Local values: spec, litersToDrop, strawRatio, strawGroundType, strawHaulmFruitTypeIndex, xs, _, zs, xw, _, zw, xh, _, zh, area
function Combine:processCombineChopperArea(workArea)
	local v145_ = self.spec_combine
	if not self.isServer and self.currentUpdateDistance > Combine.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	if not v145_.isSwathActive then
		local v146_ = v145_.workAreaParameters.litersToDrop
		local v147_ = v145_.workAreaParameters.strawRatio
		local v148_ = v145_.workAreaParameters.strawGroundType
		local v149_ = v145_.workAreaParameters.strawHaulmFruitTypeIndex
		v145_.workAreaParameters.droppedLiters = v146_
		if v146_ > 0 and v147_ > 0 then
			if v147_ > 0.5 then
				local v150_, _, v151_ = getWorldTranslation(workArea.start)
				local v152_, _, v153_ = getWorldTranslation(workArea.width)
				local v154_, _, v155_ = getWorldTranslation(workArea.height)
				if v149_ == nil then
					if v148_ ~= nil and Platform.gameplay.useSprayDiffuseMaps then
						FSDensityMapUtil.setGroundTypeLayerArea(v150_, v151_, v152_, v153_, v154_, v155_, v148_)
						FSDensityMapUtil.eraseTireTrack(v150_, v151_, v152_, v153_, v154_, v155_)
					end
				elseif FSDensityMapUtil.updateFruitHaulmArea(v149_, v150_, v151_, v152_, v153_, v154_, v155_) > 0 then
					FSDensityMapUtil.eraseTireTrack(v150_, v151_, v152_, v153_, v154_, v155_)
				end
				FSDensityMapUtil.setStubbleShredLevelArea(v150_, v151_, v152_, v153_, v154_, v155_, 1)
			end
			self:raiseActive()
			v145_.workAreaParameters.isChopperEffectEnabled = 500
			return 1, 1
		end
	end
	return 0, 0
end

-- Local values: spec, litersToDrop, droppedLiters, fruitDesc, windrowFillType, sx, sy, sz, ex, ey, ez, dropped, lineOffset
function Combine:processCombineSwathArea(workArea)
	local v158_ = self.spec_combine
	local v159_ = v158_.workAreaParameters.litersToDrop * (workArea.strawDropPercentage or 1)
	if not self.isServer and self.currentUpdateDistance > Combine.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	if not v158_.isSwathActive or v159_ <= 0 then
		return 0, 0
	end
	local v160_ = 0
	local v161_ = g_fruitTypeManager:getFruitTypeByFillTypeIndex(v158_.workAreaParameters.dropFillType)
	if v161_ ~= nil and v161_.windrowLiterPerSqm ~= nil then
		local v162_ = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(v161_.index)
		if v162_ ~= nil then
			local v163_, v164_, v165_, v166_, v167_, v168_ = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height, true)
			local v169_
			v160_, v169_ = DensityMapHeightUtil.tipToGroundAroundLine(self, v159_, v162_, v163_, v164_, v165_, v166_, v167_, v168_, 0, nil, workArea.lineOffset, false, nil, false)
			workArea.lineOffset = v169_
		end
	end
	if v160_ > 0 then
		v158_.workAreaParameters.isStrawEffectEnabled = 500
	end
	if v158_.workAreaParameters.minLitersToDrop <= v159_ then
		v158_.workAreaParameters.droppedLiters = v158_.workAreaParameters.droppedLiters + v159_
	end
	return 1, 1
end

-- Local values: spec
function Combine:setChopperPSEnabled(chopperPSenabled, fruitTypeChanged, density, isSynchronized)
	local v175_ = self.spec_combine
	if v175_.chopperPSenabled ~= chopperPSenabled or fruitTypeChanged then
		v175_.chopperPSenabled = chopperPSenabled
		if self.isServer and isSynchronized then
			v175_.sentChopperPSenabled = chopperPSenabled
		end
		if self.isClient then
			if not chopperPSenabled or fruitTypeChanged then
				g_effectManager:stopEffects(v175_.chopperEffects)
			end
			if chopperPSenabled then
				g_effectManager:setEffectTypeInfo(v175_.chopperEffects, self:getCombineLastValidFillType())
				g_effectManager:startEffects(v175_.chopperEffects)
				if not g_soundManager:getIsSamplePlaying(v175_.samples.chopStraw) then
					g_soundManager:playSample(v175_.samples.chopStraw)
				end
			elseif g_soundManager:getIsSamplePlaying(v175_.samples.chopStraw) then
				g_soundManager:stopSample(v175_.samples.chopStraw)
			end
		end
	end
	if v175_.chopperPSenabled and density ~= nil then
		g_effectManager:setDensity(v175_.chopperEffects, density)
	end
end

-- Local values: spec
function Combine:setStrawPSEnabled(strawPSenabled, fruitTypeChanged, density, isSynchronized)
	local v181_ = self.spec_combine
	if v181_.strawPSenabled ~= strawPSenabled or fruitTypeChanged then
		v181_.strawPSenabled = strawPSenabled
		if self.isServer and isSynchronized then
			v181_.sentStrawPSenabled = strawPSenabled
		end
		if not strawPSenabled then
			v181_.strawToDrop = 0
		end
		if self.isClient then
			if not strawPSenabled or fruitTypeChanged then
				g_effectManager:stopEffects(v181_.strawEffects)
			end
			if strawPSenabled then
				g_effectManager:setEffectTypeInfo(v181_.strawEffects, self:getCombineLastValidFillType())
				g_effectManager:startEffects(v181_.strawEffects)
				if not g_soundManager:getIsSamplePlaying(v181_.samples.dropStraw) then
					g_soundManager:playSample(v181_.samples.dropStraw)
				end
			elseif g_soundManager:getIsSamplePlaying(v181_.samples.dropStraw) then
				g_soundManager:stopSample(v181_.samples.dropStraw)
			end
		end
	end
	if v181_.strawPSenabled and density ~= nil then
		g_effectManager:setDensity(v181_.strawEffects, density)
	end
end

-- Local values: spec
function Combine:setCombineIsFilling(isFilling, fruitTypeChanged, isSynchronized)
	local v186_ = self.spec_combine
	if v186_.isFilling ~= isFilling or fruitTypeChanged then
		v186_.isFilling = isFilling
		if self.isServer and isSynchronized then
			v186_.sentIsFilling = isFilling
		end
		if self.isClient then
			if isFilling then
				g_animationManager:startAnimations(v186_.fillingAnimationNodes)
			else
				g_animationManager:stopAnimations(v186_.fillingAnimationNodes)
			end
			g_animationManager:setFillType(v186_.fillingAnimationNodes, self:getCombineLastValidFillType())
			g_effectManager:setEffectTypeInfo(v186_.effects, self:getCombineLastValidFillType(v186_.fillUnitIndex))
			if not isFilling or fruitTypeChanged then
				g_effectManager:stopEffects(v186_.fillEffects)
			end
			if isFilling then
				g_effectManager:setEffectTypeInfo(v186_.fillEffects, self:getCombineLastValidFillType())
				g_effectManager:startEffects(v186_.fillEffects)
			end
			if isFilling then
				if not g_soundManager:getIsSamplePlaying(v186_.samples.fill) then
					g_soundManager:playSample(v186_.samples.fill)
					return
				end
			elseif g_soundManager:getIsSamplePlaying(v186_.samples.fill) then
				g_soundManager:stopSample(v186_.samples.fill)
			end
		end
	end
end

-- Local values: spec, _, cutter
function Combine:startThreshing()
	local v188_ = self.spec_combine
	if v188_.numAttachedCutters > 0 then
		for _, v189_ in pairs(v188_.attachedCutters) do
			v189_:setIsTurnedOn(true, true)
		end
		if v188_.threshingStartAnimation ~= nil and self.playAnimation ~= nil then
			self:playAnimation(v188_.threshingStartAnimation, v188_.threshingStartAnimationSpeedScale, self:getAnimationTime(v188_.threshingStartAnimation), true)
		end
		if self.isClient then
			g_soundManager:stopSample(v188_.samples.stop)
			g_soundManager:stopSample(v188_.samples.work)
			g_soundManager:playSample(v188_.samples.start)
			g_soundManager:playSample(v188_.samples.work, 0, v188_.samples.start)
		end
		SpecializationUtil.raiseEvent(self, "onStartThreshing")
	end
end

-- Local values: spec, isFull, cutter, _, attacherVehicle
function Combine:stopThreshing()
	local v191_ = self.spec_combine
	if self.isClient then
		g_soundManager:stopSample(v191_.samples.start)
		g_soundManager:stopSample(v191_.samples.work)
		g_soundManager:playSample(v191_.samples.stop)
	end
	self:setCombineIsFilling(false, false, true)
	local v192_ = self:getCombineFillLevelPercentage() > 0.999
	if v192_ and self.rootVehicle.setCruiseControlState ~= nil then
		self.rootVehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
	end
	for v193_, _ in pairs(v191_.attachedCutters) do
		if v192_ then
			if v193_.getAttacherVehicle ~= nil then
				local v194_ = v193_:getAttacherVehicle()
				if v194_ ~= nil then
					v194_:handleLowerImplementEvent(v193_, false)
				end
			end
			if v193_.setFoldMiddleState ~= nil then
				v193_:setFoldMiddleState(false)
			end
		end
		v193_:setIsTurnedOn(false, true)
	end
	if v191_.threshingStartAnimation ~= nil and v191_.playAnimation ~= nil then
		self:playAnimation(v191_.threshingStartAnimation, -v191_.threshingStartAnimationSpeedScale, self:getAnimationTime(v191_.threshingStartAnimation), true)
	end
	SpecializationUtil.raiseEvent(self, "onStopThreshing")
end

-- Local values: spec
function Combine:setWorkedHectars(hectars, isInitial)
	local v198_ = self.spec_combine
	v198_.workedHectars = hectars
	if isInitial then
		v198_.workedHectarsInitial = hectars
	end
	if self.isServer then
		local v199_ = v198_.workedHectars - v198_.workedHectarsSent
		if math.abs(v199_) > 0.01 then
			self:raiseDirtyFlags(v198_.dirtyFlag)
			v198_.workedHectarsSent = v198_.workedHectars
		end
	end
	if self.isClient and self.updateDashboardValueType ~= nil then
		self:updateDashboardValueType("combine.workedHectars")
		self:updateDashboardValueType("combine.workedHectarsSession")
	end
end

-- Local values: spec, ladder
function Combine:addCutterToCombine(cutter)
	local v202_ = self.spec_combine
	if v202_.attachedCutters[cutter] == nil then
		v202_.attachedCutters[cutter] = cutter
		v202_.numAttachedCutters = v202_.numAttachedCutters + 1
		local v203_ = self.spec_combine.ladder
		if v203_.unfoldWhileCutterAttached and (v203_.animName ~= nil and self:getAnimationTime(v203_.animName) < 1) then
			self:playAnimation(v203_.animName, v203_.animSpeedScale, self:getAnimationTime(v203_.animName), true)
		end
	end
end

-- Local values: spec, currentFillType, ladder, fold, foldAnimTime
function Combine:removeCutterFromCombine(cutter)
	local v206_ = self.spec_combine
	if v206_.attachedCutters[cutter] ~= nil then
		v206_.numAttachedCutters = v206_.numAttachedCutters - 1
		if v206_.numAttachedCutters == 0 then
			self:setIsTurnedOn(false, true)
			if v206_.isBufferCombine then
				local v207_ = self:getFillUnitFillType(v206_.fillUnitIndex)
				if v207_ ~= FillType.UNKNOWN then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v206_.fillUnitIndex, -math.huge, v207_, ToolType.UNDEFINED, nil)
				end
			end
		end
		v206_.attachedCutters[cutter] = nil
		local v208_ = self.spec_combine.ladder
		if v208_.unfoldWhileCutterAttached and v208_.animName ~= nil then
			local v209_ = true
			if self.getFoldAnimTime ~= nil then
				local v210_ = self:getFoldAnimTime()
				if v208_.foldMaxLimit < v210_ or v210_ < v208_.foldMinLimit then
					v209_ = false
				end
			end
			if v209_ then
				self:playAnimation(v208_.animName, -v208_.animSpeedScale, self:getAnimationTime(v208_.animName), true)
			end
		end
		if Platform.gameplay.automaticVehicleControl and (next(v206_.attachedCutters) == nil and self:getActionControllerDirection() == -1) then
			self:playControlledActions()
		end
	end
end

-- Local values: spec, deltaFillLevel, worldX, _, worldZ, damage, strawFruitType, inputBuffer, slot, fruitTypeDesc, strawLiters, fillType, fillTypeSupported, i, additivesFillLevel, usage, availableUsage, bufferTime, fillUnitIndex, i, loadInfo
function Combine:addCutterArea(area, liters, inputFruitType, outputFillType, strawRatio, farmId, cutterLoad)
	local v219_ = self.spec_combine
	if area <= 0 and liters <= 0 or v219_.lastCuttersFruitType ~= FruitType.UNKNOWN and (v219_.lastCuttersArea ~= 0 and v219_.lastCuttersOutputFillType ~= outputFillType) then
		return 0
	end
	v219_.lastCuttersArea = v219_.lastCuttersArea + area
	v219_.lastCuttersOutputFillType = outputFillType
	v219_.lastCuttersInputFruitType = inputFruitType
	v219_.lastCuttersAreaTime = g_currentMission.time
	v219_.lastAreaZeroTime = 0
	local v220_ = liters * v219_.threshingScale
	local v221_, _, v222_ = getWorldTranslation(self.rootNode)
	if self:getIsThreshingDuringRain() and g_missionManager:getMissionMapActiveMissionIdAtWorldPosition(v221_, v222_) == 0 then
		v220_ = v220_ * (1 - Combine.RAIN_YIELD_REDUCTION)
	end
	if farmId ~= AccessHandler.EVERYONE then
		local v223_ = self:getVehicleDamage()
		if v223_ > 0 then
			v220_ = v220_ * (1 - v223_ * Combine.DAMAGED_YIELD_REDUCTION)
		end
	end
	if self:getFillUnitLastValidFillType(v219_.fillUnitIndex) == outputFillType or self:getFillUnitLastValidFillType(v219_.bufferFillUnitIndex) == outputFillType then
		if inputFruitType == nil then
			inputFruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(outputFillType)
		end
		if inputFruitType ~= nil then
			local v224_ = v219_.processing.inputBuffer
			local v225_ = v224_.buffer[v224_.fillIndex]
			local v226_ = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)
			if v226_.chopperType == nil then
				if v226_.chopperUseHaulm then
					v225_.strawGroundType = nil
					v225_.strawHaulmFruitTypeIndex = inputFruitType
				end
			else
				v225_.strawGroundType = FieldChopperType.getValueByType(v226_.chopperType)
				v225_.strawHaulmFruitTypeIndex = nil
			end
			local v227_ = liters / v226_.literPerSqm * (v226_.windrowLiterPerSqm or v226_.literPerSqm)
			v225_.area = v225_.area + area
			v225_.liters = v225_.liters + v227_
			v225_.inputLiters = v225_.inputLiters + v227_
			v225_.strawRatio = strawRatio
			v225_.effectDensity = cutterLoad * strawRatio * 0.8 + 0.2
		end
	end
	if v219_.fillEnableTime == nil then
		v219_.fillEnableTime = g_currentMission.time + v219_.processing.toggleTime
	end
	if v219_.additives.available then
		local v228_ = false
		for v229_ = 1, #v219_.additives.fillTypes do
			if outputFillType == v219_.additives.fillTypes[v229_] then
				v228_ = true
				break
			end
		end
		if v228_ then
			local v230_ = self:getFillUnitFillLevel(v219_.additives.fillUnitIndex)
			if v230_ > 0 then
				local v231_ = v219_.additives.usage * v220_
				if v231_ > 0 then
					local v232_ = v230_ / v231_
					v220_ = v220_ * (1 + 0.05 * math.min(v232_, 1))
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v219_.additives.fillUnitIndex, -v231_, self:getFillUnitFillType(v219_.additives.fillUnitIndex), ToolType.UNDEFINED)
				end
			end
		end
	end
	self:setWorkedHectars(v219_.workedHectars + MathUtil.areaToHa(area, g_currentMission:getFruitPixelsToSqm()))
	if self:getFillUnitCapacity(v219_.fillUnitIndex) == math.huge and self:getFillUnitFillLevel(v219_.fillUnitIndex) > 0.001 then
		local v233_ = v219_.fillLevelBufferTime
		local v234_ = self:getIsAIActive() and math.huge or v233_
		if v219_.lastDischargeTime + v234_ < g_currentMission.time then
			return v220_
		end
	end
	local v235_ = v219_.fillUnitIndex
	if v219_.bufferFillUnitIndex ~= nil and self:getFillUnitFreeCapacity(v219_.bufferFillUnitIndex) > 0 then
		v235_ = v219_.bufferFillUnitIndex
	end
	if v219_.loadingDelay > 0 then
		for v236_ = 1, #v219_.loadingDelaySlots do
			if not v219_.loadingDelaySlots[v236_].valid then
				v219_.loadingDelaySlots[v236_].valid = true
				v219_.loadingDelaySlots[v236_].fillLevelDelta = v220_
				v219_.loadingDelaySlots[v236_].fillType = outputFillType
				if v219_.loadingDelaySlotsDelayedInsert then
					v219_.loadingDelaySlots[v236_].time = g_currentMission.time
				else
					v219_.loadingDelaySlots[v236_].time = g_currentMission.time + (v219_.unloadingDelay - v219_.loadingDelay)
				end
				v219_.loadingDelaySlotsDelayedInsert = not v219_.loadingDelaySlotsDelayedInsert
				return v220_
			end
		end
		return v220_
	else
		local v237_ = self:getFillVolumeLoadInfo(v219_.loadInfoIndex)
		return self:addFillUnitFillLevel(self:getOwnerFarmId(), v235_, v220_, outputFillType, ToolType.UNDEFINED, v237_)
	end
end

-- Local values: spec, rainScale, timeSinceLastRain
function Combine:getIsThreshingDuringRain(earlyWarning)
	if not self.spec_combine.allowThreshingDuringRain then
		local v240_ = g_currentMission.environment.weather:getRainFallScale()
		local v241_ = g_currentMission.environment.weather:getTimeSinceLastRain()
		if earlyWarning == nil or earlyWarning ~= true then
			if v240_ >= 0.1 and v241_ < 20 then
				return true
			end
		elseif v240_ >= 0.02 and v241_ < 20 then
			return true
		end
	end
	return false
end

-- Local values: spec, fillUnitIndex, currentFillType, maxFreeCapacity
function Combine:verifyCombine(fruitType, outputFillType)
	local v245_ = self.spec_combine
	local v246_ = v245_.bufferFillUnitIndex or v245_.fillUnitIndex
	if self:getFillUnitFillLevelPercentage(v246_) > self:getFillTypeChangeThreshold() or v245_.isBufferCombine then
		local v247_ = self:getFillUnitFillType(v246_)
		if v247_ ~= FillType.UNKNOWN and (fruitType ~= FruitType.UNKNOWN and v247_ ~= outputFillType) then
			if not v245_.isBufferCombine then
				return nil, self, v247_
			end
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v246_, -math.huge, v247_, ToolType.UNDEFINED, nil)
			return self
		end
	end
	if (v245_.bufferFillUnitIndex == nil and 0 or self:getFillUnitFillLevel(v245_.bufferFillUnitIndex)) >= self:getFillUnitFreeCapacity(v245_.fillUnitIndex) then
		return nil
	else
		return self
	end
end

-- Local values: spec, fillLevelPct
function Combine:getFillLevelDependentSpeed()
	local v249_ = self.spec_combine
	return v249_.rotationNodesSpeedReverseFillLevel == nil and 1 or (self:getFillUnitFillLevel(v249_.fillUnitIndex) / self:getFillUnitCapacity(v249_.fillUnitIndex) > v249_.rotationNodesSpeedReverseFillLevel and -1 or 1)
end

-- Local values: spec, supportedTypes, i, fillType, supportedType, _
function Combine:getIsCutterCompatible(fillTypes)
	local v252_ = self:getFillUnitSupportedFillTypes(self.spec_combine.fillUnitIndex)
	for v253_ = 1, #fillTypes do
		local v254_ = fillTypes[v253_]
		for v255_, _ in pairs(v252_) do
			if v254_ == v255_ then
				return true
			end
		end
	end
	return false
end

-- Local values: spec, fillType, i
function Combine:getCombineLastValidFillType()
	local v257_ = self.spec_combine
	local v258_ = FillType.UNKNOWN
	if v257_.bufferFillUnitIndex ~= nil then
		v258_ = self:getFillUnitLastValidFillType(v257_.bufferFillUnitIndex)
	end
	if v258_ == FillType.UNKNOWN then
		v258_ = self:getFillUnitLastValidFillType(v257_.fillUnitIndex)
	end
	if v258_ == FillType.UNKNOWN and v257_.loadingDelay > 0 then
		for v259_ = 1, #v257_.loadingDelaySlots do
			if v257_.loadingDelaySlots[v259_].valid then
				v258_ = v257_.loadingDelaySlots[v259_].fillType
				break
			end
		end
	end
	if v258_ == FillType.UNKNOWN then
		v258_ = v257_.lastValidInputFillType
	end
	return v258_
end

-- Local values: spec, fillLevel, fillType, _, slot, capacity
function Combine:getCombineFillLevelPercentage()
	local v261_ = self.spec_combine
	local v262_ = self:getFillUnitFillLevel(v261_.fillUnitIndex)
	if v261_.loadingDelay > 0 then
		local v263_ = self:getFillUnitFillType(v261_.fillUnitIndex)
		for _, v264_ in pairs(v261_.loadingDelaySlots) do
			if v264_.valid and v264_.fillType == v263_ then
				v262_ = v262_ + v264_.fillLevelDelta
			end
		end
	end
	local v265_ = v262_ / self:getFillUnitCapacity(v261_.fillUnitIndex)
	return math.min(v265_, 1)
end

-- Local values: spec, loadSum, cutter, _
function Combine:getCombineLoadPercentage()
	local v267_ = self.spec_combine
	if v267_ == nil or v267_.numAttachedCutters <= 0 then
		return 0
	end
	local v268_ = 0
	for v269_, _ in pairs(v267_.attachedCutters) do
		if v269_.getCutterLoad ~= nil then
			v268_ = v268_ + v269_:getCutterLoad()
		end
	end
	return v268_ / v267_.numAttachedCutters
end
g_soundManager:registerModifierType("COMBINE_LOAD", Combine.getCombineLoadPercentage)

-- Local values: spec, cutter, _
function Combine:getCanBeTurnedOn(superFunc)
	local v272_ = self.spec_combine
	if v272_.numAttachedCutters <= 0 then
		return false
	end
	for v273_, _ in pairs(v272_.attachedCutters) do
		if v273_ ~= self and (v273_.getCanBeTurnedOn ~= nil and not v273_:getCanBeTurnedOn()) then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: spec, cutter, _, warning
function Combine:getTurnedOnNotAllowedWarning(superFunc)
	if self:getIsActiveForInput(true) then
		local v276_ = self.spec_combine
		if not self:getCanBeTurnedOn() then
			if v276_.numAttachedCutters == 0 then
				return v276_.texts.warningNoCutter
			end
			for v277_, _ in pairs(v276_.attachedCutters) do
				if v277_ ~= self and v277_.getTurnedOnNotAllowedWarning ~= nil then
					local v278_ = v277_:getTurnedOnNotAllowedWarning()
					if v278_ ~= nil then
						return v278_
					end
				end
			end
		end
	end
	return superFunc(self)
end

-- Local values: spec
function Combine:getAreControlledActionsAllowed(superFunc)
	if self:getActionControllerDirection() == 1 then
		local v281_ = self.spec_combine
		if v281_.numAttachedCutters <= 0 then
			return false, v281_.texts.warningNoCutter
		end
	end
	return superFunc(self)
end

-- Local values: spec, fillLevel
function Combine:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v286_ = self.spec_combine
	if v286_.allowFoldWhileThreshing or not self:getIsTurnedOn() then
		local v287_ = self:getFillUnitFillLevel(v286_.fillUnitIndex)
		if direction == v286_.foldDirection and (v286_.foldFillLevelThreshold < v287_ and self:getFillUnitCapacity(v286_.fillUnitIndex) ~= math.huge) then
			return false, v286_.texts.warningFoldingWhileFilled
		else
			return superFunc(self, direction, onAiTurnOn)
		end
	else
		return false, v286_.texts.warningFoldingTurnedOn
	end
end

function Combine:getCanBeSelected(superFunc)
	return true
end

function Combine:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	if not superFunc(self, workArea, xmlFile, key) then
		return false
	end
	if workArea.type == WorkAreaType.COMBINECHOPPER or workArea.type == WorkAreaType.COMBINESWATH then
		if xmlFile:getValue(key .. "#requiresOwnedFarmland") == nil then
			workArea.requiresOwnedFarmland = false
		end
		if xmlFile:getValue(key .. "#needsSetIsTurnedOn") == nil then
			workArea.needsSetIsTurnedOn = false
		end
		workArea.strawDropPercentage = xmlFile:getValue(key .. "#strawDropPercentage", 1)
	end
	return true
end

-- Local values: spec, cutter, _
function Combine:getDirtMultiplier(superFunc)
	local v295_ = self.spec_combine
	for v296_, _ in pairs(v295_.attachedCutters) do
		if v296_.spec_cutter ~= nil and v296_.spec_cutter.isWorking then
			return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / v296_.speedLimit
		end
	end
	return superFunc(self)
end

-- Local values: spec, cutter, _, stoneMultiplier
function Combine:getWearMultiplier(superFunc)
	local v299_ = self.spec_combine
	for v300_, _ in pairs(v299_.attachedCutters) do
		if v300_.spec_cutter ~= nil and v300_.spec_cutter.isWorking then
			local v301_ = v300_:getCutterStoneMultiplier()
			return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / v300_.speedLimit * v301_
		end
	end
	return superFunc(self)
end

function Combine:loadTurnedOnAnimationFromXML(superFunc, xmlFile, key, turnedOnAnimation)
	turnedOnAnimation.activeChopper = xmlFile:getValue(key .. "#activeChopper", true)
	turnedOnAnimation.activeStrawDrop = xmlFile:getValue(key .. "#activeStrawDrop", true)
	turnedOnAnimation.waitForStraw = xmlFile:getValue(key .. "#waitForStraw", false)
	return superFunc(self, xmlFile, key, turnedOnAnimation)
end

-- Local values: spec
function Combine:getIsTurnedOnAnimationActive(superFunc, turnedOnAnimation)
	local v310_ = self.spec_combine
	if (turnedOnAnimation.activeChopper or v310_.isSwathActive) and (turnedOnAnimation.activeStrawDrop or not v310_.isSwathActive) then
		if turnedOnAnimation.waitForStraw then
			return superFunc(self, turnedOnAnimation) or v310_.workAreaParameters.isChopperEffectEnabled > 0
		else
			return superFunc(self, turnedOnAnimation)
		end
	else
		return false
	end
end

-- Local values: retValue
function Combine:loadRandomlyMovingPartFromXML(superFunc, part, xmlFile, key)
	local v316_ = superFunc(self, part, xmlFile, key)
	part.moveOnlyIfCut = xmlFile:getValue(key .. "#moveOnlyIfCut", false)
	return v316_
end

-- Local values: retValue, spec, isCutting, _, cutter
function Combine:getIsRandomlyMovingPartActive(superFunc, part)
	local v320_ = superFunc(self, part)
	if part.moveOnlyIfCut then
		local v321_ = self.spec_combine
		local v322_ = false
		for _, v323_ in pairs(v321_.attachedCutters) do
			v322_ = v322_ or v323_.spec_cutter.lastAreaBiggerZeroTime >= g_currentMission.time - 150
		end
		v320_ = v320_ and v322_
	end
	return v320_
end

-- Local values: fillType, conversionFactor, spec, i, slot, conversion
function Combine:getDischargeFillType(superFunc, dischargeNode)
	local v327_, v328_ = superFunc(self, dischargeNode)
	if v327_ == FillType.UNKNOWN then
		local v329_ = self.spec_combine
		if v329_.loadingDelay > 0 then
			for v330_ = 1, #v329_.loadingDelaySlots do
				local v331_ = v329_.loadingDelaySlots[v330_]
				if v331_.valid and (v331_.fillLevelDelta > 0 and v331_.fillType ~= 0) then
					local v332_ = v331_.fillType
					if dischargeNode.fillTypeConverter ~= nil then
						local v333_ = dischargeNode.fillTypeConverter[v332_]
						if v333_ ~= nil then
							v332_ = v333_.targetFillTypeIndex
							v328_ = v333_.conversionFactor
						end
					end
					return v332_, v328_
				end
			end
		end
	end
	return v327_, v328_
end

function Combine:getImplementAllowAutomaticSteering(superFunc)
	return true
end

-- Local values: spec, func, _, actionEventId
function Combine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v336_ = self.spec_combine
		self:clearActionEventsTable(v336_.actionEvents)
		if isActiveForInputIgnoreSelection and (v336_.swath.isAvailable and v336_.chopper.isAvailable) then
			local v337_ = self.addActionEvent
			if v336_.chopper.isPowered then
				v337_ = self.addPoweredActionEvent
			end
			local _, v338_ = v337_(self, v336_.actionEvents, InputAction.TOGGLE_CHOPPER, self, Combine.actionEventToggleChopper, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v338_, GS_PRIO_NORMAL)
			Combine.updateToggleStrawText(self)
		end
	end
end

-- Local values: spec, fillUnitIndex, lastValidFillType, inputBuffer, inputLiters, slotFillLevel, litersToDrop, fruitDesc, windrowFillType
function Combine:onStartWorkAreaProcessing(dt)
	local v341_ = self.spec_combine
	v341_.workAreaParameters.droppedLiters = 0
	v341_.workAreaParameters.strawRatio = 0
	v341_.workAreaParameters.dropFillType = FillType.UNKNOWN
	local v342_ = self:getFillUnitLastValidFillType(v341_.bufferFillUnitIndex or v341_.fillUnitIndex)
	if v342_ ~= FillType.UNKNOWN then
		local v343_ = v341_.processing.inputBuffer
		local v344_ = v343_.buffer[v343_.dropIndex].inputLiters
		local v345_ = v343_.buffer[v343_.dropIndex].liters
		if v343_.slotDuration == 0 then
			v341_.workAreaParameters.litersToDrop = v341_.workAreaParameters.litersToDrop + v345_
		else
			local v346_ = dt / v343_.slotDuration * v344_
			local v347_ = math.min(v345_, v346_) + v341_.workAreaParameters.litersToDrop
			if v347_ > 0 then
				local v348_ = g_fruitTypeManager:getFruitTypeByFillTypeIndex(v342_)
				if v348_ ~= nil and v348_.windrowLiterPerSqm ~= nil then
					local v349_ = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(v348_.index)
					if v349_ ~= nil then
						v341_.workAreaParameters.minLitersToDrop = g_densityMapHeightManager:getMinValidLiterValue(v349_)
						local v350_ = v341_.workAreaParameters.minLitersToDrop
						local v351_ = math.min(v350_, v345_)
						v347_ = math.max(v347_, v351_)
					end
				end
			end
			v341_.workAreaParameters.litersToDrop = v347_
		end
		v341_.workAreaParameters.strawRatio = v343_.buffer[v343_.dropIndex].strawRatio
		v341_.workAreaParameters.strawGroundType = v343_.buffer[v343_.dropIndex].strawGroundType
		v341_.workAreaParameters.strawHaulmFruitTypeIndex = v343_.buffer[v343_.dropIndex].strawHaulmFruitTypeIndex
		v341_.workAreaParameters.effectDensity = v343_.buffer[v343_.dropIndex].effectDensity
		v341_.workAreaParameters.dropFillType = v342_
	end
end

-- Local values: spec, inputBuffer
function Combine:onEndWorkAreaProcessing(dt, hasProcessed)
	local v353_ = self.spec_combine
	local v354_ = v353_.processing.inputBuffer
	local v355_ = v354_.buffer[v354_.dropIndex]
	local v356_ = v354_.buffer[v354_.dropIndex].liters - v353_.workAreaParameters.droppedLiters
	v355_.liters = math.max(0, v356_)
	v353_.workAreaParameters.litersToDrop = v353_.workAreaParameters.litersToDrop - v353_.workAreaParameters.droppedLiters
end

-- Local values: spec
function Combine:onChangedFillType(fillUnitIndex, fillTypeIndex)
	local v360_ = self.spec_combine
	if (v360_.bufferFillUnitIndex ~= nil and fillUnitIndex == v360_.bufferFillUnitIndex or fillUnitIndex == v360_.fillUnitIndex) and fillTypeIndex ~= FillType.UNKNOWN then
		if fillTypeIndex ~= v360_.lastEffectFillType then
			if v360_.chopperPSenabled then
				self:setChopperPSEnabled(true, true, 0, true)
			end
			if v360_.strawPSenabled then
				self:setStrawPSEnabled(true, true, 0, true)
			end
			if v360_.isFilling then
				self:setCombineIsFilling(true, true, true)
			end
		end
		v360_.lastEffectFillType = fillTypeIndex
	end
end

-- Local values: spec
function Combine:onDeactivate()
	local v362_ = self.spec_combine
	self:setChopperPSEnabled(false, false, 0, true)
	self:setStrawPSEnabled(false, false, 0, true)
	self:setCombineIsFilling(false, false, true)
	v362_.fillEnableTime = nil
	v362_.fillDisableTime = nil
end

-- Local values: attacherJoint
function Combine:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v365_ = attachable:getActiveInputAttacherJoint()
	if v365_ ~= nil and (v365_.jointType == AttacherJoints.JOINTTYPE_CUTTER or v365_.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
		self:addCutterToCombine(attachable)
	end
end

-- Local values: object, attacherJoint
function Combine:onPostDetachImplement(implementIndex)
	local v368_ = self:getObjectFromImplementIndex(implementIndex)
	if v368_ ~= nil then
		local v369_ = v368_:getActiveInputAttacherJoint()
		if v369_ ~= nil and (v369_.jointType == AttacherJoints.JOINTTYPE_CUTTER or v369_.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
			self:removeCutterFromCombine(v368_)
		end
	end
end

-- Local values: spec
function Combine:onTurnedOn()
	self:startThreshing()
	local v371_ = self.spec_combine
	if self.isClient then
		g_animationManager:startAnimations(v371_.animationNodes)
		if v371_.isSwathActive then
			g_animationManager:startAnimations(v371_.strawDropAnimationNodes)
		else
			g_animationManager:startAnimations(v371_.chopperAnimationNodes)
			g_soundManager:stopSample(v371_.samples.chopperStop)
			g_soundManager:playSample(v371_.samples.chopperStart)
			g_soundManager:playSample(v371_.samples.chopperWork, 0, v371_.samples.chopperStart)
		end
		g_effectManager:setEffectTypeInfo(v371_.effects, self:getCombineLastValidFillType())
		g_effectManager:startEffects(v371_.effects)
	end
	if self.isServer and (v371_.turnOffWhenFull and self:getCombineFillLevelPercentage() == 1) then
		self:setIsTurnedOn(false)
	end
end

-- Local values: spec
function Combine:onTurnedOff()
	self:stopThreshing()
	if self.isClient then
		local v373_ = self.spec_combine
		g_animationManager:stopAnimations(v373_.animationNodes)
		g_animationManager:stopAnimations(v373_.chopperAnimationNodes)
		g_animationManager:stopAnimations(v373_.strawDropAnimationNodes)
		g_effectManager:stopEffects(v373_.effects)
		if g_soundManager:getIsSamplePlaying(v373_.samples.chopperWork) then
			g_soundManager:stopSample(v373_.samples.chopperWork)
			g_soundManager:playSample(v373_.samples.chopperStop)
		end
	end
end

-- Local values: ladder, fold, foldAnimTime
function Combine:onEnterVehicle()
	local v375_ = self.spec_combine.ladder
	if v375_.animName ~= nil then
		local v376_ = true
		if self.getFoldAnimTime ~= nil then
			local v377_ = self:getFoldAnimTime()
			if v375_.foldMaxLimit < v377_ or v377_ < v375_.foldMinLimit then
				v376_ = false
			end
		end
		if v375_.unfoldWhileCutterAttached and self.spec_combine.numAttachedCutters > 0 then
			v376_ = false
		end
		if v376_ then
			self:playAnimation(v375_.animName, -v375_.animSpeedScale, self:getAnimationTime(v375_.animName), true)
		end
	end
end

-- Local values: ladder, fold, foldAnimTime
function Combine:onLeaveVehicle()
	local v379_ = self.spec_combine.ladder
	if v379_.animName ~= nil then
		local v380_ = true
		if self.getFoldAnimTime ~= nil then
			local v381_ = self:getFoldAnimTime()
			if v379_.foldMaxLimit < v381_ or v381_ < v379_.foldMinLimit then
				v380_ = false
			end
		end
		if v379_.unfoldWhileCutterAttached and self.spec_combine.numAttachedCutters > 0 then
			v380_ = false
		end
		if v380_ then
			self:playAnimation(v379_.animName, v379_.animSpeedScale, self:getAnimationTime(v379_.animName), true)
		end
	end
end

-- Local values: ladder, fold
function Combine:onFoldStateChanged(direction, moveToMiddle)
	local v385_ = self.spec_combine.ladder
	if v385_.animName ~= nil and (direction ~= 0 and (direction == self.spec_foldable.turnOnFoldDirection or not moveToMiddle)) and (not v385_.unfoldWhileCutterAttached or self.spec_combine.numAttachedCutters <= 0) then
		self:playAnimation(v385_.animName, direction * v385_.animSpeedScale * v385_.foldDirection, self:getAnimationTime(v385_.animName), true)
	end
end

-- Local values: spec
function Combine:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local v389_ = self.spec_combine
	if fillUnitIndex == v389_.fillUnitIndex then
		if fillLevelDelta < 0 then
			v389_.lastDischargeTime = g_currentMission.time
		end
		if self.isServer and (v389_.turnOffWhenFull and self:getCombineFillLevelPercentage() == 1) then
			self:setIsTurnedOn(false)
		end
	end
end

-- Local values: spec, fillUnitIndex, fruitType, fruitDesc
function Combine:actionEventToggleChopper(actionName, inputValue, callbackState, isAnalog)
	local v391_ = self.spec_combine
	if v391_.swath.isAvailable then
		local v392_ = v391_.bufferFillUnitIndex or v391_.fillUnitIndex
		local v393_ = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(self:getFillUnitFillType(v392_))
		if v393_ ~= nil and v393_ ~= FruitType.UNKNOWN then
			if g_fruitTypeManager:getFruitTypeByIndex(v393_).hasWindrow then
				self:setIsSwathActive(not v391_.isSwathActive)
			else
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_couldNotToggleChopper"), 2000)
			end
		end
		self:setIsSwathActive(not v391_.isSwathActive)
	end
end

-- Local values: spec, actionEvent, text
function Combine:updateToggleStrawText()
	local v395_ = self.spec_combine
	local v396_ = v395_.actionEvents[InputAction.TOGGLE_CHOPPER]
	if v396_ ~= nil and v396_.actionEventId ~= nil then
		local v397_
		if v395_.isSwathActive then
			v397_ = g_i18n:getText("action_disableStrawSwath")
		else
			v397_ = g_i18n:getText("action_enableStrawSwath")
		end
		g_inputBinding:setActionEventText(v396_.actionEventId, v397_)
	end
end
