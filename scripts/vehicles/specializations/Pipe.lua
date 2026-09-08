source("dataS/scripts/vehicles/specializations/events/SetPipeStateEvent.lua")
source("dataS/scripts/vehicles/specializations/events/SetPipeDischargeToGroundEvent.lua")
Pipe = {}

function Pipe.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	end
	return v2_
end
function Pipe.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("pipe", g_i18n:getText("configuration_pipe"), "pipe", VehicleConfigurationItem)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Pipe")
	AnimationManager.registerAnimationNodesXMLPaths(v3_, "vehicle.pipe.animationNodes")
	v3_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p4_, p5_)
		p4_:register(XMLValueType.VECTOR_N, p5_ .. "#freezingPipeStates", "Freezing pipe states")
	end)
	v3_:register(XMLValueType.INT, Cover.COVER_XML_KEY .. "#minPipeState", "Min. pipe state", 0)
	v3_:register(XMLValueType.INT, Cover.COVER_XML_KEY .. "#maxPipeState", "Max. pipe state", "inf.")
	Pipe.registers(v3_, "vehicle.pipe")
	Pipe.registers(v3_, "vehicle.pipe.pipeConfigurations.pipeConfiguration(?)")
	v3_:setXMLSpecializationType()
	local v6_ = Vehicle.xmlSchemaSavegame
	v6_:register(XMLValueType.INT, "vehicles.vehicle(?).pipe#state", "Current pipe state")
	v6_:register(XMLValueType.BOOL, "vehicles.vehicle(?).pipe#isStateChangeAllowed", "If pipe state change is allowed")
end

function Pipe.registers(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#pipeInText", "Text to show for pipe extending action", "action_pipeIn")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#pipeOutText", "Text to show for pipe retracting action", "action_pipeOut")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#turnOnStateWarning", "Turn on warning", "warning_firstSetPipeState")
	schema:register(XMLValueType.INT, basePath .. "#dischargeNodeIndex", "Discharge node index", 1)
	schema:register(XMLValueType.BOOL, basePath .. "#forceDischargeNodeIndex", "Force discharge node selection while changing pipe state. Can be deactivated e.g. if the selection is done by trailer spec etc.", true)
	schema:register(XMLValueType.BOOL, basePath .. "#automaticDischarge", "Pipe is automatically starting to discharge as soon as it hits the trailer", true)
	schema:register(XMLValueType.BOOL, basePath .. "#toggleableDischargeToGround", "Defines if the discharge to ground can be enabled separately", false)
	schema:register(XMLValueType.BOOL, basePath .. "#defaultDischargeToGroundState", "Discharge to ground is enabled by default if #toggleableDischargeToGround is set", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".unloadingTriggers.unloadingTrigger(?)#node", "Unload trigger node")
	schema:register(XMLValueType.STRING, basePath .. ".animation#name", "Pipe animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".animation#speedScale", "Pipe animation speed scale", 1)
	schema:register(XMLValueType.INT, basePath .. ".states#num", "Number of pipe states", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".pipeNodes.pipeNode(?)#node", "Pipe node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".pipeNodes.pipeNode(?)#subPipeNode", "Sub pipe node (Target rotation is divided between these two nodes depending on the X rotation ratio between #node and #node parent and #subPipeNode and #node parent)")
	schema:register(XMLValueType.FLOAT, basePath .. ".pipeNodes.pipeNode(?)#subPipeNodeRatio", "Ratio between usage of this pipe node and sub node [0-1]", "Calculated based on rotation in i3d file")
	schema:register(XMLValueType.BOOL, basePath .. ".pipeNodes.pipeNode(?)#autoAimXRotation", "Auto aim X rotation", false)
	schema:register(XMLValueType.BOOL, basePath .. ".pipeNodes.pipeNode(?)#autoAimYRotation", "Auto aim Y rotation", false)
	schema:register(XMLValueType.BOOL, basePath .. ".pipeNodes.pipeNode(?)#autoAimInvertZ", "Auto aim invert Z axis", false)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".pipeNodes.pipeNode(?).state(?)#translation", "State translation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".pipeNodes.pipeNode(?).state(?)#rotation", "State translation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".pipeNodes.pipeNode(?)#translationSpeeds", "Translation speeds")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".pipeNodes.pipeNode(?)#rotationSpeeds", "Rotation speeds")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".pipeNodes.pipeNode(?)#minRotationLimits", "Min. rotation limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".pipeNodes.pipeNode(?)#maxRotationLimits", "Max. rotation limit")
	schema:register(XMLValueType.INT, basePath .. ".pipeNodes.pipeNode(?)#foldPriority", "Fold priority", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".pipeNodes.pipeNode(?)#bendingRegulation", "Bending angle regulation", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".pipeNodes.pipeNode(?).bendingRegulationNode(?)#node", "Bending regulation node", 0)
	schema:register(XMLValueType.INT, basePath .. ".pipeNodes.pipeNode(?).bendingRegulationNode(?)#axis", "Bending regulation axis", 0)
	schema:register(XMLValueType.INT, basePath .. ".pipeNodes.pipeNode(?).bendingRegulationNode(?)#direction", "Bending regulation direction", 0)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".pipeNodes.pipeNode(?)", "moveSound(?)")
	schema:register(XMLValueType.VECTOR_N, basePath .. ".states#unloading", "Unloading states")
	schema:register(XMLValueType.VECTOR_N, basePath .. ".states#autoAiming", "Auto aim states")
	schema:register(XMLValueType.VECTOR_N, basePath .. ".states#turnOnAllowed", "Turn on allowed states")
	schema:register(XMLValueType.INT, basePath .. ".states.state(?)#stateIndex", "State index")
	schema:register(XMLValueType.INT, basePath .. ".states.state(?)#dischargeNodeIndex", "Discharge node index")
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMinLimit", "Fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMaxLimit", "Fold max. limit", 1)
	schema:register(XMLValueType.INT, basePath .. "#foldMinState", "Fold min. state", 1)
	schema:register(XMLValueType.INT, basePath .. "#foldMaxState", "Fold max. state", "Num. of states")
	schema:register(XMLValueType.BOOL, basePath .. "#aiFoldedPipeUsesTrailerSpace", "Defines if the folded pipe uses the space of the trailer to discharge", false)
end

function Pipe.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadUnloadingTriggers", Pipe.loadUnloadingTriggers)
	SpecializationUtil.registerFunction(vehicleType, "loadPipeNodes", Pipe.loadPipeNodes)
	SpecializationUtil.registerFunction(vehicleType, "getIsPipeStateChangeAllowed", Pipe.getIsPipeStateChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setPipeState", Pipe.setPipeState)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentPipeState", Pipe.getCurrentPipeState)
	SpecializationUtil.registerFunction(vehicleType, "updatePipeNodes", Pipe.updatePipeNodes)
	SpecializationUtil.registerFunction(vehicleType, "updateBendingRegulationNodes", Pipe.updateBendingRegulationNodes)
	SpecializationUtil.registerFunction(vehicleType, "unloadingTriggerCallback", Pipe.unloadingTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "updateNearestObjectInTriggers", Pipe.updateNearestObjectInTriggers)
	SpecializationUtil.registerFunction(vehicleType, "updateActionEventText", Pipe.updateActionEventText)
	SpecializationUtil.registerFunction(vehicleType, "onDeletePipeObject", Pipe.onDeletePipeObject)
	SpecializationUtil.registerFunction(vehicleType, "getPipeDischargeNodeIndex", Pipe.getPipeDischargeNodeIndex)
	SpecializationUtil.registerFunction(vehicleType, "setPipeDischargeToGround", Pipe.setPipeDischargeToGround)
	SpecializationUtil.registerFunction(vehicleType, "setIsPipeStateChangeAllowed", Pipe.setIsPipeStateChangeAllowed)
end

function Pipe.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", Pipe.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Pipe.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", Pipe.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Pipe.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischarge", Pipe.handleDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", Pipe.handleDischargeRaycast)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToObject", Pipe.getCanToggleDischargeToObject)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToGround", Pipe.getCanToggleDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", Pipe.getRequiresPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", Pipe.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", Pipe.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadCoverFromXML", Pipe.loadCoverFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsNextCoverStateAllowed", Pipe.getIsNextCoverStateAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Pipe.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", Pipe.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", Pipe.getIsAIPreparingToDrive)
end

function Pipe.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onMovingToolChanged", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementPrepareForTransport", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Pipe)
end

-- Local values: spec, pipeConfigurationId, baseKey, _, trigger, loadState, target, xmlFile, key, i, states, _, state, target, xmlFile, key, i, states, _, state, target, xmlFile, key, i, states, _, state, i, stateKey, stateIndex, dischargeNodeIndex
function Pipe:onLoad(savegame)
	local v13_ = self.spec_pipe
	local v14_ = Utils.getNoNil(self.configurations.pipe, 1)
	local v15_ = string.format("vehicle.pipe.pipeConfigurations.pipeConfiguration(%d)", v14_ - 1)
	local v16_ = not self.xmlFile:hasProperty(v15_) and "vehicle.pipe" or v15_
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipeEffect.effectNode", v16_ .. ".pipeEffect.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.overloading.trailerTriggers.trailerTrigger(0)#index", v16_ .. ".unloadingTriggers.unloadingTrigger(0)#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#raycastNodeIndex", v16_ .. ".raycast#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#raycastDistance", v16_ .. ".raycast#maxDistance")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#effectExtraDistanceOnTrailer", v16_ .. ".raycast#extraDistance")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#animName", v16_ .. ".animation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#animSpeedScale", v16_ .. ".animation#speedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#animSpeedScale", v16_ .. ".animation#speedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe.node#node", v16_ .. ".node#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#numStates", v16_ .. ".states#num")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#unloadingStates", v16_ .. ".states#unloading")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#autoAimingStates", v16_ .. ".states#autoAiming")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipe#turnOnAllowed", v16_ .. ".states#turnOnAllowed")
	v13_.dischargeNodeIndex = self.xmlFile:getValue(v16_ .. "#dischargeNodeIndex", 1)
	v13_.forceDischargeNodeIndex = self.xmlFile:getValue(v16_ .. "#forceDischargeNodeIndex", true)
	if v13_.forceDischargeNodeIndex then
		self:setCurrentDischargeNodeIndex(v13_.dischargeNodeIndex)
	end
	v13_.isStateChangeAllowed = true
	v13_.automaticDischarge = self.xmlFile:getValue(v16_ .. "#automaticDischarge", true)
	v13_.toggleableDischargeToGround = self.xmlFile:getValue(v16_ .. "#toggleableDischargeToGround", false)
	v13_.dischargeToGroundState = self.xmlFile:getValue(v16_ .. "#defaultDischargeToGroundState", false)
	v13_.unloadingTriggers = {}
	v13_.objectsInTriggers = {}
	v13_.unloadTriggersInTriggers = {}
	v13_.numObjectsInTriggers = 0
	v13_.numUnloadTriggersInTriggers = 0
	v13_.nearestObjectInTriggers = {
		["objectId"] = nil,
		["fillUnitIndex"] = 0,
		["isDischargeObject"] = false
	}
	v13_.nearestObjectInTriggersSent = {
		["objectId"] = nil,
		["fillUnitIndex"] = 0,
		["isDischargeObject"] = false
	}
	self:loadUnloadingTriggers(v13_.unloadingTriggers, self.xmlFile, v16_ .. ".unloadingTriggers.unloadingTrigger")
	if #v13_.unloadingTriggers == 0 then
		Logging.xmlWarning(self.xmlFile, "No \'unloadingTriggers\' defined for pipe \'vehicle.pipe\'!")
	else
		for _, v17_ in pairs(v13_.unloadingTriggers) do
			addTrigger(v17_.node, "unloadingTriggerCallback", self)
			setTriggerReportStatics(v17_.node, true)
		end
	end
	v13_.animation = {}
	v13_.animation.name = self.xmlFile:getValue(v16_ .. ".animation#name")
	v13_.animation.speedScale = self.xmlFile:getValue(v16_ .. ".animation#speedScale", 1)
	v13_.currentState = 1
	v13_.targetState = 1
	v13_.numStates = self.xmlFile:getValue(v16_ .. ".states#num", 0)
	v13_.nodes = {}
	self:loadPipeNodes(v13_.nodes, self.xmlFile, v16_ .. ".pipeNodes.pipeNode")
	v13_.hasMovablePipe = #v13_.nodes > 0 and true or v13_.animation.name ~= nil
	v13_.unloadingStates = {}
	v13_.autoAimingStates = {}
	v13_.turnOnAllowedStates = {}
	local v18_ = v13_.unloadingStates
	local v19_ = 0
	local v20_ = self.xmlFile:getValue(v16_ .. ".states#unloading", nil, true)
	if v20_ ~= nil then
		for _, v21_ in ipairs(v20_) do
			v18_[v21_] = true
			v19_ = v19_ + 1
		end
	end
	v13_.numUnloadingStates = v19_
	local v22_ = v13_.autoAimingStates
	local v23_ = 0
	local v24_ = self.xmlFile:getValue(v16_ .. ".states#autoAiming", nil, true)
	if v24_ ~= nil then
		for _, v25_ in ipairs(v24_) do
			v22_[v25_] = true
			v23_ = v23_ + 1
		end
	end
	v13_.numAutoAimingStates = v23_
	local v26_ = v13_.turnOnAllowedStates
	local v27_ = 0
	local v28_ = self.xmlFile:getValue(v16_ .. ".states#turnOnAllowed", nil, true)
	if v28_ ~= nil then
		for _, v29_ in ipairs(v28_) do
			v26_[v29_] = true
			v27_ = v27_ + 1
		end
	end
	v13_.numTurnOnAllowedStates = v27_
	v13_.dischargeNodeMapping = {}
	local v30_ = 0
	while true do
		local v31_ = string.format("%s.states.state(%d)", v16_, v30_)
		if not self.xmlFile:hasProperty(v31_) then
			break
		end
		local v32_ = self.xmlFile:getValue(v31_ .. "#stateIndex")
		local v33_ = self.xmlFile:getValue(v31_ .. "#dischargeNodeIndex")
		if v32_ ~= nil and v33_ ~= nil then
			v13_.dischargeNodeMapping[v32_] = v33_
		end
		v30_ = v30_ + 1
	end
	if self.isClient then
		v13_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.pipe.animationNodes", self.components, self, self.i3dMappings)
	end
	v13_.foldMinTime = self.xmlFile:getValue(v16_ .. "#foldMinLimit", 0)
	v13_.foldMaxTime = self.xmlFile:getValue(v16_ .. "#foldMaxLimit", 1)
	v13_.foldMinState = self.xmlFile:getValue(v16_ .. "#foldMinState", 1)
	v13_.foldMaxState = self.xmlFile:getValue(v16_ .. "#foldMaxState", v13_.numStates)
	v13_.aiFoldedPipeUsesTrailerSpace = self.xmlFile:getValue(v16_ .. "#aiFoldedPipeUsesTrailerSpace", false)
	v13_.texts = {}
	v13_.texts.warningFoldingPipe = g_i18n:getText("warning_foldingNotWhilePipeExtended")
	v13_.texts.turnOnStateWarning = string.format(self.xmlFile:getValue(v16_ .. "#turnOnStateWarning", "warning_firstSetPipeState", self.customEnvironment), self.typeDesc)
	v13_.texts.pipeIn = self.xmlFile:getValue(v16_ .. "#pipeInText", "action_pipeIn", self.customEnvironment)
	v13_.texts.pipeOut = self.xmlFile:getValue(v16_ .. "#pipeOutText", "action_pipeOut", self.customEnvironment)
	v13_.texts.startTipToGround = g_i18n:getText("action_startTipToGround")
	v13_.texts.stopTipToGround = g_i18n:getText("action_stopTipToGround")
	v13_.sideNotificationData = {}
	v13_.sideNotificationData.objectId = nil
	v13_.sideNotificationData.fillUnitIndex = nil
	v13_.sideNotificationData.progressBar = g_currentMission.hud:addSideNotificationProgressBar("", "", "")
	v13_.sideNotificationTime = 0
	v13_.dirtyFlag = self:getNextDirtyFlag()
	v13_.lastFillTime = -1000
	v13_.lastEmptyTime = -1000
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Pipe)
	end
end

-- Local values: spec, pipeState, targetTime
function Pipe:onPostLoad(savegame)
	local v36_ = self.spec_pipe
	if savegame ~= nil and not savegame.resetVehicles then
		v36_.isStateChangeAllowed = savegame.xmlFile:getValue(savegame.key .. ".pipe#isStateChangeAllowed", v36_.isStateChangeAllowed)
		local v37_ = savegame.xmlFile:getValue(savegame.key .. ".pipe#state", v36_.currentState)
		self:setPipeState(v37_, true)
		self:updatePipeNodes(999999)
		v36_.currentState = v36_.targetState
		if v36_.animation.name ~= nil then
			local v38_ = v37_ == 1 and 0 or 1
			self:setAnimationTime(v36_.animation.name, v38_, true)
		end
	end
end

-- Local values: spec, object, _, object, _, _, trigger, _, pipeNode
function Pipe:onDelete()
	local v40_ = self.spec_pipe
	if v40_.objectsInTriggers ~= nil then
		for v41_, _ in pairs(v40_.objectsInTriggers) do
			if v41_.removeDeleteListener ~= nil then
				v41_:removeDeleteListener(self, "onDeletePipeObject")
			end
		end
		table.clear(v40_.objectsInTriggers)
	end
	if v40_.unloadTriggersInTriggers ~= nil then
		for v42_, _ in pairs(v40_.unloadTriggersInTriggers) do
			if v42_.removeDeleteListener ~= nil then
				v42_:removeDeleteListener(self, "onDeletePipeObject")
			end
		end
		table.clear(v40_.unloadTriggersInTriggers)
	end
	if v40_.unloadingTriggers ~= nil then
		for _, v43_ in pairs(v40_.unloadingTriggers) do
			removeTrigger(v43_.node)
		end
		table.clear(v40_.unloadingTriggers)
	end
	if v40_.nodes ~= nil then
		for _, v44_ in ipairs(v40_.nodes) do
			g_soundManager:deleteSamples(v44_.moveSamples)
		end
	end
	if v40_.sideNotificationData ~= nil then
		g_currentMission.hud:removeSideNotificationProgressBar(v40_.sideNotificationData.progressBar)
	end
	g_animationManager:deleteAnimations(v40_.animationNodes)
end

-- Local values: spec
function Pipe:saveToXMLFile(xmlFile, key, usedModNames)
	local v48_ = self.spec_pipe
	if v48_.numStates > 0 then
		local v49_ = key .. "#state"
		local v50_ = v48_.currentState
		local v51_ = v48_.numStates
		xmlFile:setValue(v49_, (math.clamp(v50_, 1, v51_)))
	end
	xmlFile:setValue(key .. "#isStateChangeAllowed", v48_.isStateChangeAllowed)
end

-- Local values: spec, pipeState
function Pipe:onReadStream(streamId, connection)
	local v54_ = self.spec_pipe
	self:setPipeState(streamReadUIntN(streamId, 2), true)
	if streamReadBool(streamId) then
		v54_.nearestObjectInTriggers.objectId = NetworkUtil.readNodeObjectId(streamId)
		v54_.nearestObjectInTriggers.fillUnitIndex = streamReadUIntN(streamId, 4)
		v54_.nearestObjectInTriggers.isDischargeObject = streamReadBool(streamId)
	end
end

-- Local values: spec
function Pipe:onWriteStream(streamId, connection)
	local v57_ = self.spec_pipe
	streamWriteUIntN(streamId, v57_.targetState, 2)
	if streamWriteBool(streamId, v57_.nearestObjectInTriggersSent.objectId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, v57_.nearestObjectInTriggersSent.objectId)
		streamWriteUIntN(streamId, v57_.nearestObjectInTriggersSent.fillUnitIndex, 4)
		streamWriteBool(streamId, v57_.nearestObjectInTriggersSent.isDischargeObject)
	end
end

-- Local values: spec
function Pipe:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v61_ = self.spec_pipe
		if streamReadBool(streamId) then
			v61_.nearestObjectInTriggers.objectId = NetworkUtil.readNodeObjectId(streamId)
			v61_.nearestObjectInTriggers.fillUnitIndex = streamReadUIntN(streamId, 4)
			v61_.nearestObjectInTriggers.isDischargeObject = streamReadBool(streamId)
			return
		end
		v61_.nearestObjectInTriggers.objectId = nil
		v61_.nearestObjectInTriggers.fillUnitIndex = 0
		v61_.nearestObjectInTriggers.isDischargeObject = false
	end
end

-- Local values: spec
function Pipe:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v66_ = self.spec_pipe
		local v67_ = streamWriteBool
		local v68_ = v66_.dirtyFlag
		if v67_(streamId, bit32.band(dirtyMask, v68_) ~= 0) and streamWriteBool(streamId, v66_.nearestObjectInTriggersSent.objectId ~= nil) then
			NetworkUtil.writeNodeObjectId(streamId, v66_.nearestObjectInTriggersSent.objectId)
			streamWriteUIntN(streamId, v66_.nearestObjectInTriggersSent.fillUnitIndex, 4)
			streamWriteBool(streamId, v66_.nearestObjectInTriggersSent.isDischargeObject)
		end
	end
end

-- Local values: spec, targetObject, fillUnitIndex, fillType, fillLevel, capacity, fillLevelPct, fillTypeDesc, text, progressBar
function Pipe:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v72_ = self.spec_pipe
	self:updateActionEventText()
	if v72_.hasMovablePipe then
		self:updatePipeNodes(dt)
	end
	if self.isClient then
		if v72_.sideNotificationTime > 0 then
			local v73_ = v72_.sideNotificationTime - dt
			v72_.sideNotificationTime = math.max(v73_, 0)
		end
		if isActiveForInputIgnoreSelection then
			local v74_ = NetworkUtil.getObject(v72_.nearestObjectInTriggers.objectId)
			local v75_ = v72_.nearestObjectInTriggers.fillUnitIndex
			if not v72_.nearestObjectInTriggers.isDischargeObject then
				v74_ = nil
			end
			if v74_ == nil and (v72_.sideNotificationTime > 0 and v72_.sideNotificationData.objectId ~= nil) then
				v74_ = NetworkUtil.getObject(v72_.sideNotificationData.objectId)
				v75_ = v72_.sideNotificationData.fillUnitIndex
				if v74_ == nil then
					v72_.sideNotificationData.objectId = nil
				end
			end
			if v74_ ~= nil then
				local v76_ = v74_:getFillUnitFillType(v75_)
				if v76_ ~= FillType.UNKNOWN then
					local v77_ = v74_:getFillUnitFillLevel(v75_)
					local v78_ = v74_:getFillUnitCapacity(v75_)
					if v78_ ~= nil and v78_ > 0 then
						local v79_ = v77_ / v78_
						local v80_ = g_fillTypeManager:getFillTypeByIndex(v76_)
						local v81_ = string.format("%d%s %s", v77_, v80_.unitShort or "", v80_.title)
						if v72_.nearestObjectInTriggers.objectId ~= nil then
							v72_.sideNotificationData.objectId = v72_.nearestObjectInTriggers.objectId
							v72_.sideNotificationData.fillUnitIndex = v75_
							v72_.sideNotificationTime = 5000
						end
						local v82_ = v72_.sideNotificationData.progressBar
						v82_.title = v74_:getFullName()
						v82_.text = v81_
						v82_.progress = v79_
						g_currentMission.hud:markSideNotificationProgressBarForDrawing(v82_)
					end
				end
			end
		end
	end
end

-- Local values: spec, objectChanged, fillUnitChanged, dischargeObjectChanged, unfoldPipe, dischargeNode, capacity, fillLevel, unloadingState, _
function Pipe:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		self:updateNearestObjectInTriggers()
		local v84_ = self.spec_pipe
		if v84_.nearestObjectInTriggers.objectId ~= v84_.nearestObjectInTriggersSent.objectId or (v84_.nearestObjectInTriggers.fillUnitIndex ~= v84_.nearestObjectInTriggersSent.fillUnitIndex or v84_.nearestObjectInTriggers.isDischargeObject ~= v84_.nearestObjectInTriggersSent.isDischargeObject) then
			v84_.nearestObjectInTriggersSent.objectId = v84_.nearestObjectInTriggers.objectId
			v84_.nearestObjectInTriggersSent.fillUnitIndex = v84_.nearestObjectInTriggers.fillUnitIndex
			v84_.nearestObjectInTriggersSent.isDischargeObject = v84_.nearestObjectInTriggers.isDischargeObject
			self:raiseDirtyFlags(v84_.dirtyFlag)
		end
		if v84_.numAutoAimingStates == 0 and (Platform.gameplay.automaticPipeUnfolding and not self:getIsAIActive()) then
			local v85_ = v84_.nearestObjectInTriggers.objectId ~= nil and true or v84_.numUnloadTriggersInTriggers > 0
			local v86_ = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())
			if v86_ ~= nil then
				local v87_ = self:getFillUnitCapacity(v86_.fillUnitIndex)
				local v88_ = self:getFillUnitFillLevel(v86_.fillUnitIndex)
				v85_ = not v85_ or v87_ == math.huge and (self.getIsTurnedOn == nil or self:getIsTurnedOn()) or v88_ > 0
			end
			if v85_ then
				if v84_.targetState == 1 then
					local v89_, _ = next(v84_.unloadingStates)
					if self:getIsPipeStateChangeAllowed(v89_) then
						self:setPipeState(v89_)
					end
				end
			elseif v84_.targetState > 1 and self:getIsPipeStateChangeAllowed(1) then
				self:setPipeState(1)
			end
			if v85_ then
				self:raiseActive()
			end
		end
	end
end

-- Local values: i, key, node
function Pipe:loadUnloadingTriggers(unloadingTriggers, xmlFile, baseKey)
	local v94_ = 0
	while true do
		local v95_ = string.format("%s(%d)", baseKey, v94_)
		if not xmlFile:hasProperty(v95_) then
			break
		end
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v95_ .. "#index", v95_ .. "#node")
		local v96_ = xmlFile:getValue(v95_ .. "#node", nil, self.components, self.i3dMappings)
		if v96_ ~= nil then
			if CollisionFlag.getHasMaskFlagSet(v96_, CollisionFlag.FILLABLE) then
				table.insert(unloadingTriggers, {
					["node"] = v96_
				})
			else
				Logging.xmlWarning(self.xmlFile, "Missing collision filter mask %s. Please add this bit to unload trigger node \'%s\' in \'%s\'", CollisionFlag.getBitAndName(CollisionFlag.FILLABLE), getName(v96_), v95_)
			end
		end
		v94_ = v94_ + 1
	end
end

-- Local values: spec, maxPriority, i, key, node, entry, x1, _, _, x2, _, _, state, stateKey, x, y, z, x, y, z, j, regKey, regulationNode, axis, direction, _, pipeNode
function Pipe:loadPipeNodes(pipeNodes, xmlFile, baseKey)
	local v101_ = self.spec_pipe
	local v102_ = 0
	local v103_ = 0
	while true do
		local v104_ = string.format("%s(%d)", baseKey, v102_)
		if not xmlFile:hasProperty(v104_) then
			break
		end
		local v105_ = xmlFile:getValue(v104_ .. "#node", nil, self.components, self.i3dMappings)
		if v105_ ~= nil then
			local v106_ = {
				["node"] = v105_,
				["autoAimXRotation"] = xmlFile:getValue(v104_ .. "#autoAimXRotation", false),
				["autoAimYRotation"] = xmlFile:getValue(v104_ .. "#autoAimYRotation", false),
				["autoAimInvertZ"] = xmlFile:getValue(v104_ .. "#autoAimInvertZ", false),
				["states"] = {},
				["subPipeNode"] = xmlFile:getValue(v104_ .. "#subPipeNode", nil, self.components, self.i3dMappings)
			}
			if v106_.subPipeNode ~= nil then
				local v107_, _, _ = getRotation(v106_.node)
				local v108_, _, _ = localRotationToLocal(v106_.subPipeNode, getParent(v106_.node), 0, 0, 0)
				local v109_ = v104_ .. "#subPipeNodeRatio"
				local v110_ = v107_ / v108_
				v106_.subPipeNodeRatio = xmlFile:getValue(v109_, (math.abs(v110_)))
			end
			XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v104_ .. ".state1", v104_ .. ".state")
			for v111_ = 1, v101_.numStates do
				local v112_ = v104_ .. string.format(".state(%d)", v111_ - 1)
				v106_.states[v111_] = {}
				local v113_, v114_, v115_ = xmlFile:getValue(v112_ .. "#translation", { getTranslation(v105_) })
				if v111_ == 1 then
					setTranslation(v105_, v113_, v114_, v115_)
				end
				v106_.states[v111_].translation = { v113_, v114_, v115_ }
				local v116_, v117_, v118_ = xmlFile:getValue(v112_ .. "#rotation", { getRotation(v105_) })
				if v111_ == 1 then
					setRotation(v105_, v116_, v117_, v118_)
				end
				v106_.states[v111_].rotation = { v116_, v117_, v118_ }
			end
			local v119_, v120_, v121_ = xmlFile:getValue(v104_ .. "#translationSpeeds")
			if v119_ ~= nil and (v120_ ~= nil and v121_ ~= nil) then
				local v122_ = v119_ * 0.001
				local v123_ = v120_ * 0.001
				local v124_ = v121_ * 0.001
				if v122_ ~= 0 or (v123_ ~= 0 or v124_ ~= 0) then
					v106_.translationSpeeds = { v122_, v123_, v124_ }
				end
			end
			local v125_, v126_, v127_ = xmlFile:getValue(v104_ .. "#rotationSpeeds")
			if v125_ ~= nil and (v126_ ~= nil and v127_ ~= nil) then
				local v128_ = v125_ * 0.001
				local v129_ = v126_ * 0.001
				local v130_ = v127_ * 0.001
				if v128_ ~= 0 or (v129_ ~= 0 or v130_ ~= 0) then
					v106_.rotationSpeeds = { v128_, v129_, v130_ }
				end
			end
			v106_.minRotationLimits = xmlFile:getValue(v104_ .. "#minRotationLimits", nil, true)
			v106_.maxRotationLimits = xmlFile:getValue(v104_ .. "#maxRotationLimits", nil, true)
			v106_.foldPriority = xmlFile:getValue(v104_ .. "#foldPriority", 0)
			local v131_ = v106_.foldPriority
			v103_ = math.max(v131_, v103_)
			local v132_, v133_, v134_ = getTranslation(v105_)
			v106_.curTranslation = { v132_, v133_, v134_ }
			local v135_, v136_, v137_ = getRotation(v105_)
			v106_.curRotation = { v135_, v136_, v137_ }
			v106_.lastTargetRotation = { v135_, v136_, v137_ }
			v106_.bendingRegulation = xmlFile:getValue(v104_ .. "#bendingRegulation", 0)
			v106_.regulationNodes = {}
			local v138_ = 0
			while true do
				local v139_ = string.format("%s.bendingRegulationNode(%d)", v104_, v138_)
				if not xmlFile:hasProperty(v139_) then
					break
				end
				local v140_ = {
					["node"] = xmlFile:getValue(v139_ .. "#node", nil, self.components, self.i3dMappings)
				}
				if v140_.node == nil then
					Logging.xmlWarning(self.xmlFile, "Failed to load bendingRegulationNode \'%s\'", v139_)
				else
					v140_.startRotation = { getRotation(v140_.node) }
					local v141_ = xmlFile:getValue(v139_ .. "#axis", 1)
					local v142_ = xmlFile:getValue(v139_ .. "#direction", 1)
					v140_.weights = { 0, 0, 0 }
					v140_.weights[math.clamp(v141_, 1, 3)] = v142_
					local v143_ = v106_.regulationNodes
					table.insert(v143_, v140_)
				end
				v138_ = v138_ + 1
			end
			v106_.moveSamples = g_soundManager:loadSamplesFromXML(self.xmlFile, v104_, "moveSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
			v106_.moveSamplesPlayTimer = 0
			table.insert(pipeNodes, v106_)
		end
		v102_ = v102_ + 1
	end
	for _, v144_ in ipairs(pipeNodes) do
		v144_.inverseFoldPriority = v103_ - v144_.foldPriority
	end
end

-- Local values: spec, foldAnimTime
function Pipe:getIsPipeStateChangeAllowed(pipeState)
	local v146_ = self.spec_pipe
	if not v146_.isStateChangeAllowed then
		return false
	end
	local v147_
	if self.getFoldAnimTime == nil then
		v147_ = nil
	else
		v147_ = self:getFoldAnimTime()
	end
	return v147_ == nil or v147_ >= v146_.foldMinTime and v146_.foldMaxTime >= v147_
end

-- Local values: spec
function Pipe:setIsPipeStateChangeAllowed(isAllowed)
	self.spec_pipe.isStateChangeAllowed = isAllowed
end

-- Local values: spec
function Pipe:setPipeState(pipeState, noEventSend)
	local v153_ = self.spec_pipe
	local v154_ = v153_.numStates
	local v155_ = math.min(pipeState, v154_)
	if v153_.targetState ~= v155_ then
		if noEventSend == nil or noEventSend == false then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(SetPipeStateEvent.new(self, v155_), nil, nil, self)
			else
				g_server:broadcastEvent(SetPipeStateEvent.new(self, v155_))
			end
		end
		v153_.targetState = v155_
		v153_.currentState = 0
		if v153_.animation ~= nil then
			if v155_ == 1 then
				self:playAnimation(v153_.animation.name, -v153_.animation.speedScale, self:getAnimationTime(v153_.animation.name), true)
			else
				self:playAnimation(v153_.animation.name, v153_.animation.speedScale, self:getAnimationTime(v153_.animation.name), true)
			end
		end
		if v153_.forceDischargeNodeIndex then
			self:setCurrentDischargeNodeIndex(self:getPipeDischargeNodeIndex(v155_))
		end
	end
end

function Pipe:getCurrentPipeState()
	return self.spec_pipe.currentState
end

-- Local values: spec, object, doAutoAiming, priority, fillAutoAimTargetNode, autoAimX, autoAimY, autoAimZ, moved, i, nodeMoved, pipeNode, nodeAutoAimY, distance, regulation, state, axis, changed, axis, targetRotation, x, y, z, x1, y1, z1, x2, y2, z2, _, lDirY, lDirZ, x, y, z, lDirX, _, lDirZ, rotationAllowed, j, pipeNodeToCheck, dischargeNode, _, pipeNode, _, pipeNode
function Pipe:updatePipeNodes(dt)
	local v159_ = self.spec_pipe
	local v160_
	if v159_.nearestObjectInTriggers.objectId == nil then
		v160_ = nil
	else
		v160_ = NetworkUtil.getObject(v159_.nearestObjectInTriggers.objectId)
		if v160_ ~= nil and not v160_:getIsSynchronized() then
			v160_ = nil
		end
		if v160_ ~= nil and (v160_.rootNode == nil or not entityExists(v160_.rootNode)) then
			v160_ = nil
		end
	end
	local v161_
	if v160_ == nil then
		v161_ = false
	else
		v161_ = v159_.autoAimingStates[v159_.currentState]
	end
	if v159_.currentState == v159_.targetState and not v161_ then
		if self:getDischargeState() == Dischargeable.DISCHARGE_STATE_GROUND then
			local v162_ = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())
			if v162_ ~= nil then
				for _, v163_ in ipairs(v159_.nodes) do
					if v163_.bendingRegulation > 0 then
						self:updateBendingRegulationNodes(v163_, v162_.dischargeDistance)
					end
				end
			end
		end
	else
		local v164_ = v159_.targetState == v159_.numStates and "inverseFoldPriority" or "foldPriority"
		local v165_, v166_, v167_, v168_
		if v161_ then
			v165_ = v160_:getFillUnitAutoAimTargetNode(v159_.nearestObjectInTriggers.fillUnitIndex)
			if v165_ == nil then
				v165_ = v160_:getFillUnitExactFillRootNode(v159_.nearestObjectInTriggers.fillUnitIndex)
			end
			v166_, v167_, v168_ = getWorldTranslation(v165_)
			if VehicleDebug.state == VehicleDebug.DEBUG then
				DebugGizmo.renderAtPositionSimple(v166_, v167_, v168_, getName(v165_))
			end
			if v160_.isActive and self.updateLoopIndex ~= v160_.updateLoopIndex then
				v160_:addExactFillRootAimToUpdate(self, self.updatePipeNodes)
				return
			end
		else
			v167_ = nil
			v165_ = nil
			v166_ = nil
			v168_ = nil
		end
		local v169_ = false
		for v170_ = 1, #v159_.nodes do
			local v171_ = false
			local v172_ = v159_.nodes[v170_]
			local v173_
			if v172_.bendingRegulation > 0 and v165_ ~= nil then
				v173_ = v167_ - self:updateBendingRegulationNodes(v172_, (calcDistanceFrom(v172_.node, v165_)))
			else
				v173_ = v167_
			end
			local v174_ = v172_.states[v159_.targetState]
			if v172_.translationSpeeds ~= nil then
				for v175_ = 1, 3 do
					local v176_ = v172_.curTranslation[v175_] - v174_.translation[v175_]
					if math.abs(v176_) > 1e-6 then
						v171_ = true
						if v172_.curTranslation[v175_] < v174_.translation[v175_] then
							local v177_ = v172_.curTranslation
							local v178_ = v172_.curTranslation[v175_] + dt * v172_.translationSpeeds[v175_]
							local v179_ = v174_.translation[v175_]
							v177_[v175_] = math.min(v178_, v179_)
						else
							local v180_ = v172_.curTranslation
							local v181_ = v172_.curTranslation[v175_] - dt * v172_.translationSpeeds[v175_]
							local v182_ = v174_.translation[v175_]
							v180_[v175_] = math.max(v181_, v182_)
						end
					end
				end
				setTranslation(v172_.node, v172_.curTranslation[1], v172_.curTranslation[2], v172_.curTranslation[3])
			end
			if v172_.rotationSpeeds ~= nil then
				local v183_ = false
				for v184_ = 1, 3 do
					local v185_ = v174_.rotation[v184_]
					if v161_ then
						if v172_.autoAimXRotation and v184_ == 1 then
							local v186_, v187_, v188_ = getWorldTranslation(v172_.node)
							if VehicleDebug.state == VehicleDebug.DEBUG then
								if v172_.subPipeNode == nil then
									drawDebugLine(v186_, v187_, v188_, 1, 0, 0, v166_, v173_, v168_, 1, 0, 0)
								else
									local v189_, v190_, v191_ = getWorldTranslation(v172_.node)
									local v192_, v193_, v194_ = localToWorld(v172_.node, 0, 0, 3)
									drawDebugLine(v189_, v190_, v191_, 1, 1, 0, v192_, v193_, v194_, 1, 1, 0)
									DebugGizmo.renderAtPositionSimple(v192_, v193_, v194_, string.format("ratio: %.2f", v172_.subPipeNodeRatio))
								end
							end
							local _, v195_, v196_ = worldDirectionToLocal(getParent(v172_.node), v166_ - v186_, v173_ - v187_, v168_ - v188_)
							local v197_ = -math.atan2(v195_, v196_)
							if v172_.subPipeNode ~= nil then
								v197_ = v197_ * v172_.subPipeNodeRatio
							end
							if v172_.autoAimInvertZ then
								v197_ = v197_ + 3.141592653589793
							end
							v185_ = MathUtil.normalizeRotationForShortestPath(v197_, v172_.curRotation[v184_])
						elseif v172_.autoAimYRotation and v184_ == 2 then
							local v198_, v199_, v200_ = getWorldTranslation(v172_.node)
							local v201_, _, v202_ = worldDirectionToLocal(getParent(v172_.node), v166_ - v198_, v173_ - v199_, v168_ - v200_)
							local v203_ = math.atan2(v201_, v202_)
							if v172_.autoAimInvertZ then
								v203_ = v203_ + 3.141592653589793
							end
							v185_ = MathUtil.normalizeRotationForShortestPath(v203_, v172_.curRotation[v184_])
						end
					end
					if v172_.minRotationLimits ~= nil and v172_.maxRotationLimits ~= nil then
						if math.abs(v185_) > 6.283185307179586 then
							v185_ = v185_ % 6.283185307179586
						end
						if v172_.minRotationLimits[v184_] ~= nil then
							local v204_ = v172_.minRotationLimits[v184_]
							v185_ = math.max(v185_, v204_)
						end
						if v172_.maxRotationLimits[v184_] ~= nil then
							local v205_ = v172_.maxRotationLimits[v184_]
							v185_ = math.min(v185_, v205_)
						end
					end
					local v206_ = v172_.curRotation[v184_] - v185_
					if math.abs(v206_) > 0.00001 then
						v183_ = true
						local v207_ = true
						if not v161_ then
							for v208_ = 1, #v159_.nodes do
								local v209_ = v159_.nodes[v208_]
								if v209_[v164_] > v172_[v164_] then
									if v209_.curRotation[1] == v209_.lastTargetRotation[1] then
										if v209_.curRotation[2] == v209_.lastTargetRotation[2] then
											if v209_.curRotation[3] ~= v209_.lastTargetRotation[3] then
												v207_ = false
											end
										else
											v207_ = false
										end
									else
										v207_ = false
									end
								end
							end
						end
						if v207_ then
							local v210_ = v172_.curRotation[v184_] - v185_
							if math.abs(v210_) > dt * v172_.rotationSpeeds[v184_] * 0.95 then
								if v172_.moveSamplesPlayTimer <= 0 then
									g_soundManager:playSamples(v172_.moveSamples)
								end
								v172_.moveSamplesPlayTimer = 250
							end
							v171_ = true
							if v172_.curRotation[v184_] < v185_ then
								local v211_ = v172_.curRotation
								local v212_ = v172_.curRotation[v184_] + dt * v172_.rotationSpeeds[v184_]
								v211_[v184_] = math.min(v212_, v185_)
							else
								local v213_ = v172_.curRotation
								local v214_ = v172_.curRotation[v184_] - dt * v172_.rotationSpeeds[v184_]
								v213_[v184_] = math.max(v214_, v185_)
							end
							if v172_.curRotation[v184_] > 6.283185307179586 then
								v172_.curRotation[v184_] = v172_.curRotation[v184_] - 6.283185307179586
							elseif v172_.curRotation[v184_] < -6.283185307179586 then
								v172_.curRotation[v184_] = v172_.curRotation[v184_] + 6.283185307179586
							end
							v172_.lastTargetRotation[v184_] = v185_
						end
					end
				end
				if v183_ then
					setRotation(v172_.node, v172_.curRotation[1], v172_.curRotation[2], v172_.curRotation[3])
				end
			end
			v169_ = v169_ or v171_
			if v171_ and self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(v172_.node)
			end
		end
		if (#v159_.nodes ~= 0 or (v159_.animation.name == nil or not self:getIsAnimationPlaying(v159_.animation.name))) and not v169_ then
			v159_.currentState = v159_.targetState
		end
	end
	for _, v215_ in ipairs(v159_.nodes) do
		v215_.moveSamplesPlayTimer = v215_.moveSamplesPlayTimer - dt
		if v215_.moveSamplesPlayTimer < 0 then
			g_soundManager:stopSamples(v215_.moveSamples)
			v215_.moveSamplesPlayTimer = 0
		end
	end
end

-- Local values: _, dirY, _, _, regulationNode, regulationAngle, weights, startRotation, x1, y1, z1, x2, y2, z2
function Pipe:updateBendingRegulationNodes(pipeNode, distance)
	local _, v218_, _ = localDirectionToWorld(pipeNode.node, 0, 1, 0)
	for _, v219_ in ipairs(pipeNode.regulationNodes) do
		local v220_ = v218_ * pipeNode.bendingRegulation
		local v221_ = v219_.weights
		local v222_ = v219_.startRotation
		setRotation(v219_.node, v222_[1] + v221_[1] * v220_, v222_[2] + v221_[2] * v220_, v222_[3] + v221_[3] * v220_)
		if VehicleDebug.state == VehicleDebug.DEBUG then
			local v223_, v224_, v225_ = getWorldTranslation(v219_.node)
			local v226_, v227_, v228_ = localToWorld(v219_.node, 0, -10, 0)
			drawDebugLine(v223_, v224_, v225_, 0, 0, 1, v226_, v227_, v228_, 0, 0, 1)
		end
	end
	local v229_ = v218_ * pipeNode.bendingRegulation
	return math.sin(v229_) * distance
end

-- Local values: object, fillUnitIndex, spec, dischargeNode, fillTypes, objectSupportsFillType, fillType, _, spec
function Pipe:unloadingTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		local v234_ = g_currentMission:getNodeObject(otherId)
		if v234_ == nil or (v234_ == self or not v234_:isa(Vehicle)) then
			if v234_ ~= nil and (v234_ ~= self and v234_:isa(UnloadTrigger)) then
				local v235_ = self.spec_pipe
				if onEnter then
					if v235_.unloadTriggersInTriggers[v234_] == nil then
						v235_.unloadTriggersInTriggers[v234_] = 0
						v235_.numUnloadTriggersInTriggers = v235_.numUnloadTriggersInTriggers + 1
						if v234_.addDeleteListener ~= nil then
							v234_:addDeleteListener(self, "onDeletePipeObject")
						end
					end
					v235_.unloadTriggersInTriggers[v234_] = v235_.unloadTriggersInTriggers[v234_] + 1
					self:raiseActive()
					return
				end
				v235_.unloadTriggersInTriggers[v234_] = v235_.unloadTriggersInTriggers[v234_] - 1
				if v235_.unloadTriggersInTriggers[v234_] == 0 then
					v235_.unloadTriggersInTriggers[v234_] = nil
					v235_.numUnloadTriggersInTriggers = v235_.numUnloadTriggersInTriggers - 1
					if v234_.removeDeleteListener ~= nil then
						v234_:removeDeleteListener(self, "onDeletePipeObject")
					end
				end
			end
		elseif v234_.getFillUnitIndexFromNode ~= nil then
			local v236_ = v234_:getFillUnitIndexFromNode(otherId)
			if v236_ ~= nil then
				local v237_ = self.spec_pipe
				local v238_ = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())
				if v238_ ~= nil then
					local v239_ = self:getFillUnitSupportedFillTypes(v238_.fillUnitIndex)
					local v240_ = false
					for v241_, _ in pairs(v239_) do
						if v234_:getFillUnitSupportsFillType(v236_, v241_) then
							v240_ = true
							break
						end
					end
					if v240_ then
						if onEnter then
							if v237_.objectsInTriggers[v234_] == nil then
								v237_.objectsInTriggers[v234_] = 0
								v237_.numObjectsInTriggers = v237_.numObjectsInTriggers + 1
								if v234_.addDeleteListener ~= nil then
									v234_:addDeleteListener(self, "onDeletePipeObject")
								end
							end
							v237_.objectsInTriggers[v234_] = v237_.objectsInTriggers[v234_] + 1
							self:raiseActive()
							return
						end
						v237_.objectsInTriggers[v234_] = v237_.objectsInTriggers[v234_] - 1
						if v237_.objectsInTriggers[v234_] == 0 then
							v237_.objectsInTriggers[v234_] = nil
							v237_.numObjectsInTriggers = v237_.numObjectsInTriggers - 1
							if v234_.removeDeleteListener ~= nil then
								v234_:removeDeleteListener(self, "onDeletePipeObject")
								return
							end
						end
					end
				end
			end
		end
	end
end

-- Local values: spec, minDistance, dischargeNode, checkNode, object, _, outputFillType, fillUnitIndex, _, allowedToFillByPipe, supportsFillType, freeCapacity, targetPoint, exactFillRootNode, distance
function Pipe:updateNearestObjectInTriggers()
	local v243_ = self.spec_pipe
	v243_.nearestObjectInTriggers.objectId = nil
	v243_.nearestObjectInTriggers.fillUnitIndex = 0
	v243_.nearestObjectInTriggers.isDischargeObject = false
	local v244_ = math.huge
	local v245_ = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())
	if v245_ == nil then
		Logging.xmlWarning(self.xmlFile, "Unable to find discharge node index \'%d\' for pipe", self:getPipeDischargeNodeIndex())
	else
		local v246_ = Utils.getNoNil(v245_.node, self.components[1].node)
		for v247_, _ in pairs(v243_.objectsInTriggers) do
			local v248_ = self:getFillUnitLastValidFillType(v245_.fillUnitIndex)
			for v249_, _ in ipairs(v247_.spec_fillUnit.fillUnits) do
				if v247_:getFillUnitSupportsToolType(v249_, ToolType.DISCHARGEABLE) and ((v247_:getFillUnitSupportsFillType(v249_, v248_) or v248_ == FillType.UNKNOWN) and v247_:getFillUnitFreeCapacity(v249_, v248_, self:getOwnerFarmId()) > 0) then
					local v250_ = v247_:getFillUnitAutoAimTargetNode(v249_)
					local v251_ = v247_:getFillUnitExactFillRootNode(v249_)
					if v250_ ~= nil then
						v251_ = v250_
					end
					if v251_ ~= nil then
						local v252_ = calcDistanceFrom(v246_, v251_)
						if v252_ < v244_ then
							v243_.nearestObjectInTriggers.objectId = NetworkUtil.getObjectId(v247_)
							v243_.nearestObjectInTriggers.fillUnitIndex = v249_
							if v247_ == v245_.dischargeObject and v249_ == v245_.dischargeFillUnitIndex then
								v243_.nearestObjectInTriggers.isDischargeObject = true
								v244_ = v252_
							else
								v244_ = v252_
							end
						end
					end
				end
			end
		end
	end
end

-- Local values: spec, actionEvent, showAction, nextState, pipeStateName, dischargeNodeIndex, dischargeNode, fillTypeIndex, fillType
function Pipe:updateActionEventText()
	local v254_ = self.spec_pipe
	local v255_ = v254_.actionEvents[InputAction.TOGGLE_PIPE]
	if v255_ ~= nil then
		local v256_ = false
		if v254_.targetState == v254_.numStates then
			if self:getIsPipeStateChangeAllowed(1) then
				g_inputBinding:setActionEventText(v255_.actionEventId, v254_.texts.pipeIn)
				v256_ = true
			end
		else
			local v257_ = v254_.targetState + 1
			if self:getIsPipeStateChangeAllowed(v257_) then
				local v258_
				if v254_.numUnloadingStates > 1 and v254_.numUnloadingStates ~= v254_.numStates then
					v258_ = string.format(" [%d]", v257_ - 1)
					local v259_ = self:getFillUnitFillType(self:getDischargeNodeByIndex((self:getPipeDischargeNodeIndex(v257_))).fillUnitIndex)
					if v259_ ~= FillType.UNKNOWN then
						local v260_ = g_fillTypeManager:getFillTypeByIndex(v259_)
						if v260_ ~= nil then
							v258_ = string.format(" [%d, %s]", v257_ - 1, v260_.title)
						end
					end
				else
					v258_ = ""
				end
				g_inputBinding:setActionEventText(v255_.actionEventId, string.format(v254_.texts.pipeOut, v258_))
				v256_ = true
			end
		end
		g_inputBinding:setActionEventActive(v255_.actionEventId, v256_)
	end
end

-- Local values: spec
function Pipe:getIsDischargeNodeActive(superFunc, dischargeNode)
	local v264_ = self.spec_pipe
	if dischargeNode.index == self:getPipeDischargeNodeIndex() then
		return v264_.unloadingStates[v264_.currentState] == true
	else
		return superFunc(self, dischargeNode)
	end
end

-- Local values: spec, isAllowed, pipeState, _
function Pipe:getCanBeTurnedOn(superFunc)
	local v267_ = self.spec_pipe
	if v267_.hasMovablePipe and next(v267_.turnOnAllowedStates) ~= nil then
		local v268_ = false
		for v269_, _ in pairs(v267_.turnOnAllowedStates) do
			if v269_ == v267_.currentState then
				v268_ = true
				break
			end
		end
		if not v268_ then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: spec, isAllowed, pipeState, _
function Pipe:getTurnedOnNotAllowedWarning(superFunc)
	local v272_ = self.spec_pipe
	if v272_.hasMovablePipe and next(v272_.turnOnAllowedStates) ~= nil then
		local v273_ = false
		for v274_, _ in pairs(v272_.turnOnAllowedStates) do
			if v274_ == v272_.currentState then
				v273_ = true
				break
			end
		end
		if not v273_ then
			return v272_.texts.turnOnStateWarning
		end
	end
	return superFunc(self)
end

-- Local values: spec
function Pipe:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v279_ = self.spec_pipe
	if v279_.hasMovablePipe and (v279_.currentState > v279_.foldMaxState or v279_.currentState < v279_.foldMinState) then
		return false, v279_.texts.warningFoldingPipe
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end

-- Local values: spec
function Pipe:handleDischarge(superFunc, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	if self.spec_pipe.automaticDischarge then
		if dischargeNode.index ~= self:getPipeDischargeNodeIndex() then
			superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
			return
		end
	else
		superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

-- Local values: spec, stopDischarge, fillType, allowFillType
function Pipe:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	local v294_ = self.spec_pipe
	if v294_.automaticDischarge then
		local v295_ = false
		if self:getIsPowered() and hitObject ~= nil then
			local v296_ = self:getDischargeFillType(dischargeNode)
			if hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, v296_) and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex, v296_, self:getOwnerFarmId()) > 0 then
				self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
			else
				v295_ = true
			end
		elseif self:getIsPowered() and (v294_.toggleableDischargeToGround and v294_.dischargeToGroundState) then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND, true)
		else
			v295_ = true
		end
		if v295_ and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
		end
	else
		superFunc(self, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	end
end

-- Local values: spec
function Pipe:getCanToggleDischargeToObject(superFunc)
	if self.spec_pipe.automaticDischarge then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Pipe:getCanToggleDischargeToGround(superFunc)
	local v301_ = self.spec_pipe
	if v301_.automaticDischarge and v301_.toggleableDischargeToGround then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec, dischargeNode
function Pipe:getRequiresPower(superFunc)
	local v304_ = self.spec_pipe
	if v304_.automaticDischarge then
		local v305_ = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())
		if v305_ ~= nil then
			if v304_.isAsyncRaycastActive and v305_.lastDischargeObject ~= nil then
				return true
			end
			if not v304_.isAsyncRaycastActive and v305_.dischargeObject ~= nil then
				return true
			end
		end
	end
	return v304_.currentState ~= v304_.targetState and true or superFunc(self)
end

function Pipe:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.freezingPipeStates = xmlFile:getValue(key .. "#freezingPipeStates", nil, true)
	return true
end

-- Local values: spec, _, state
function Pipe:getIsMovingToolActive(superFunc, movingTool)
	local v314_ = self.spec_pipe
	if movingTool.freezingPipeStates ~= nil then
		for _, v315_ in pairs(movingTool.freezingPipeStates) do
			if v314_.currentState == v315_ or (v314_.targetState == v315_ or v314_.currentState == 0) then
				return false
			end
		end
	end
	return superFunc(self, movingTool)
end

function Pipe:loadCoverFromXML(superFunc, xmlFile, key, cover)
	cover.minPipeState = xmlFile:getValue(key .. "#minPipeState", 0)
	cover.maxPipeState = xmlFile:getValue(key .. "#maxPipeState", math.huge)
	return superFunc(self, xmlFile, key, cover)
end

-- Local values: spec, cover
function Pipe:getIsNextCoverStateAllowed(superFunc, nextState)
	if not superFunc(self, nextState) then
		return false
	end
	local v324_ = self.spec_pipe
	local v325_ = self.spec_cover.covers[nextState]
	return nextState == 0 or v324_.currentState >= v325_.minPipeState and v324_.currentState <= v325_.maxPipeState
end

-- Local values: spec
function Pipe:onDeletePipeObject(object)
	local v328_ = self.spec_pipe
	if v328_.objectsInTriggers[object] ~= nil then
		v328_.objectsInTriggers[object] = nil
		v328_.numObjectsInTriggers = v328_.numObjectsInTriggers - 1
	end
	if v328_.unloadTriggersInTriggers[object] ~= nil then
		v328_.unloadTriggersInTriggers[object] = nil
		v328_.numUnloadTriggersInTriggers = v328_.numUnloadTriggersInTriggers - 1
	end
end

-- Local values: spec
function Pipe:getPipeDischargeNodeIndex(state)
	local v331_ = self.spec_pipe
	if state == nil then
		state = v331_.currentState
	end
	if v331_.dischargeNodeMapping[state] == nil then
		return v331_.dischargeNodeIndex
	else
		return v331_.dischargeNodeMapping[state]
	end
end

-- Local values: spec, actionEvent
function Pipe:setPipeDischargeToGround(state, noEventSend)
	local v335_ = self.spec_pipe
	if state == nil then
		state = not v335_.dischargeToGroundState
	end
	if state ~= v335_.dischargeToGroundState then
		v335_.dischargeToGroundState = state
		local v336_ = v335_.actionEvents[InputAction.TOGGLE_TIPSTATE_GROUND]
		if v336_ ~= nil then
			g_inputBinding:setActionEventText(v336_.actionEventId, state and v335_.texts.stopTipToGround or v335_.texts.startTipToGround)
		end
		SetPipeDischargeToGroundEvent.sendEvent(self, state, noEventSend)
	end
end

function Pipe:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec
function Pipe:getIsAIReadyToDrive(superFunc)
	local v339_ = self.spec_pipe
	if v339_.hasMovablePipe and v339_.currentState ~= 1 then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Pipe:getIsAIPreparingToDrive(superFunc)
	local v342_ = self.spec_pipe
	return v342_.hasMovablePipe and v342_.currentState ~= v342_.targetState and true or superFunc(self)
end

-- Local values: spec, _, pipeNode
function Pipe:onMovingToolChanged(tool, transSpeed, dt)
	local v345_ = self.spec_pipe
	for _, v346_ in ipairs(v345_.nodes) do
		if v346_.node == tool.node then
			v346_.curTranslation = { tool.curTrans[1], tool.curTrans[2], tool.curTrans[3] }
			v346_.curRotation = { tool.curRot[1], tool.curRot[2], tool.curRot[3] }
		end
	end
end

-- Local values: spec, _, actionEventId
function Pipe:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v349_ = self.spec_pipe
		self:clearActionEventsTable(v349_.actionEvents)
		if isActiveForInputIgnoreSelection and v349_.hasMovablePipe then
			local _, v350_ = self:addPoweredActionEvent(v349_.actionEvents, InputAction.TOGGLE_PIPE, self, Pipe.actionEventTogglePipe, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v350_, GS_PRIO_HIGH)
			self:updateActionEventText()
			if v349_.toggleableDischargeToGround then
				local _, v351_ = self:addActionEvent(v349_.actionEvents, InputAction.TOGGLE_TIPSTATE_GROUND, self, Pipe.actionEventToggleDischargeToGround, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v351_, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventText(v351_, v349_.dischargeToGroundState and v349_.texts.stopTipToGround or v349_.texts.startTipToGround)
			end
		end
	end
end

-- Local values: spec, dischargeNode, dischargeNodeIndex
function Pipe:onDischargeStateChanged(state)
	if self.isClient then
		local v354_ = self.spec_pipe
		local v355_ = self:getCurrentDischargeNode()
		local v356_
		if v355_ == nil then
			v356_ = nil
		else
			v356_ = v355_.index
		end
		if v356_ == self:getPipeDischargeNodeIndex() then
			if state == Dischargeable.DISCHARGE_STATE_OFF then
				g_animationManager:stopAnimations(v354_.animationNodes)
				return
			end
			g_animationManager:startAnimations(v354_.animationNodes)
			g_animationManager:setFillType(v354_.animationNodes, self:getFillUnitLastValidFillType(v355_.fillUnitIndex))
		end
	end
end

-- Local values: spec
function Pipe:onAIImplementPrepareForTransport()
	if self.spec_pipe.hasMovablePipe and self:getIsPipeStateChangeAllowed(1) then
		self:setPipeState(1)
	end
end

-- Local values: spec, actionController, autoAimState, _
function Pipe:onRootVehicleChanged(rootVehicle)
	local v360_ = self.spec_pipe
	if v360_.hasMovablePipe and v360_.numAutoAimingStates > 0 then
		local v361_ = rootVehicle.actionController
		if v361_ ~= nil then
			if v360_.controlledAction == nil then
				local v362_, _ = next(v360_.autoAimingStates)
				v360_.controlledAction = v361_:registerAction("pipe", nil, 2)
				v360_.controlledAction:setCallback(self, Pipe.actionControllerPipeEvent)
				v360_.controlledAction:addAIEventListener(self, "onAIFieldWorkerEnd", -1)
				v360_.controlledAction:setFinishedFunctions(self, Pipe.getCurrentPipeState, v362_, 1)
			else
				v360_.controlledAction:updateParent(v361_)
			end
		end
		if v360_.controlledAction ~= nil then
			v360_.controlledAction:remove()
			v360_.controlledAction = nil
		end
	end
end

-- Local values: spec, autoAimState, _
function Pipe:actionControllerPipeEvent(direction)
	local v365_ = self.spec_pipe
	if direction > 0 then
		local v366_, _ = next(v365_.autoAimingStates)
		self:setPipeState(v366_)
	else
		self:setPipeState(1)
	end
	return true
end

-- Local values: spec, nextState
function Pipe:actionEventTogglePipe(actionName, inputValue, callbackState, isAnalog)
	local v368_ = self.spec_pipe
	local v369_ = v368_.targetState + 1
	local v370_ = v368_.numStates < v369_ and 1 or v369_
	if self:getIsPipeStateChangeAllowed(v370_) then
		self:setPipeState(v370_)
	elseif v370_ ~= 1 and self:getIsPipeStateChangeAllowed(1) then
		self:setPipeState(1)
	end
end

function Pipe:actionEventToggleDischargeToGround(actionName, inputValue, callbackState, isAnalog)
	self:setPipeDischargeToGround()
end
