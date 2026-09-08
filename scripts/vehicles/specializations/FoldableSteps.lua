FoldableSteps = {}
FoldableSteps.STATE_NUM_BITS = 4
source("dataS/scripts/vehicles/specializations/events/FoldableStepsChangeStateEvent.lua")

function FoldableSteps.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function FoldableSteps.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("FoldableSteps")
	v2_:register(XMLValueType.STRING, "vehicle.foldableSteps#animationName", "Folding Animation Name")
	v2_:register(XMLValueType.FLOAT, "vehicle.foldableSteps#animationSpeed", "Folding Animation Speed", 1)
	v2_:register(XMLValueType.INT, "vehicle.foldableSteps#fillUnitIndex", "Fill unit that is allowed to be filled / blocked to fill")
	v2_:register(XMLValueType.BOOL, "vehicle.foldableSteps#allowFullFoldingAction", "Allow playing the full folding animation at once", true)
	v2_:register(XMLValueType.BOOL, "vehicle.foldableSteps#releaseBrakesWhileFolding", "Release the brake while folding", true)
	v2_:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps#stateTextPos", "State text for positive action with insert for state action text")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps#stateTextNeg", "State text for negrative action with insert for state action text")
	v2_:register(XMLValueType.STRING, "vehicle.foldableSteps.controls#action", "Input action to toggle to full movement from state 1 to max state", "IMPLEMENT_EXTRA2")
	v2_:registerAutoCompletionDataSource("vehicle.foldableSteps.controls#action", "$dataS/inputActions.xml", "actions.action#name")
	v2_:register(XMLValueType.STRING, "vehicle.foldableSteps.controls#actionPos", "Input action to toggle the next fold state")
	v2_:registerAutoCompletionDataSource("vehicle.foldableSteps.controls#actionPos", "$dataS/inputActions.xml", "actions.action#name")
	v2_:register(XMLValueType.STRING, "vehicle.foldableSteps.controls#actionNeg", "Input action to toggle the last fold state")
	v2_:registerAutoCompletionDataSource("vehicle.foldableSteps.controls#actionNeg", "$dataS/inputActions.xml", "actions.action#name")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.controls#posText", "Text to display for full folding in positive direction")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.controls#negText", "Text to display for full folding in negative direction")
	v2_:register(XMLValueType.FLOAT, "vehicle.foldableSteps.state(?)#time", "State time of folding animation (Abs. folding time)")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.state(?)#posText", "State text for toggle in positive direction")
	v2_:register(XMLValueType.STRING, "vehicle.foldableSteps.state(?)#posContext", "Active context to be allowed to toggle in positive direction (PLAYER or VEHICLE)", "VEHICLE")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.state(?)#negText", "State text for toggle in negative direction")
	v2_:register(XMLValueType.STRING, "vehicle.foldableSteps.state(?)#negContext", "Active context to be allowed to toggle in negative direction (PLAYER or VEHICLE)", "VEHICLE")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.state(?)#infoText", "Extra into text to display when this state is active")
	v2_:register(XMLValueType.BOOL, "vehicle.foldableSteps.state(?)#allowTurnOn", "Turn on is allowed while in this state", false)
	v2_:register(XMLValueType.BOOL, "vehicle.foldableSteps.state(?)#allowInfoHud", "Info hud is allowed while in this state", false)
	v2_:register(XMLValueType.BOOL, "vehicle.foldableSteps.state(?)#allowFilling", "Allow filling while in this state", false)
	v2_:addDelayedRegistrationFunc("DynamicMountAttacher:lockPosition", function(p3_, p4_)
		p3_:register(XMLValueType.VECTOR_N, p4_ .. ".foldableSteps#states", "States in which this lock position is active")
	end)
	v2_:setXMLSpecializationType()
	local v5_ = Vehicle.xmlSchemaSavegame
	v5_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).foldableSteps#animTime", "Fold animation time")
	v5_:register(XMLValueType.INT, "vehicles.vehicle(?).foldableSteps#state", "Current fold state index")
	v5_:register(XMLValueType.INT, "vehicles.vehicle(?).foldableSteps#targetState", "Current target fold state index")
end

function FoldableSteps.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setFoldableStepsFoldState", FoldableSteps.setFoldableStepsFoldState)
end

function FoldableSteps.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", FoldableSteps.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", FoldableSteps.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", FoldableSteps.getRequiresPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowHudInfoTrigger", FoldableSteps.getAllowHudInfoTrigger)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", FoldableSteps.getFillUnitSupportsToolType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", FoldableSteps.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDynamicLockPositionFromXML", FoldableSteps.loadDynamicLockPositionFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDynamicLockPositionActive", FoldableSteps.getIsDynamicLockPositionActive)
end

function FoldableSteps.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FoldableSteps)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FoldableSteps)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FoldableSteps)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FoldableSteps)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", FoldableSteps)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", FoldableSteps)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", FoldableSteps)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", FoldableSteps)
end

-- Local values: spec, animationName, hasInfoTexts, _, key, state
function FoldableSteps:onLoad(savegame)
	local v11_ = self.spec_foldableSteps
	if self.xmlFile:getValue("vehicle.foldableSteps#animationName") == nil then
		SpecializationUtil.removeEventListener(self, "onPostLoad", FoldableSteps)
		SpecializationUtil.removeEventListener(self, "onReadStream", FoldableSteps)
		SpecializationUtil.removeEventListener(self, "onWriteStream", FoldableSteps)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", FoldableSteps)
		SpecializationUtil.removeEventListener(self, "onDraw", FoldableSteps)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", FoldableSteps)
	else
		v11_.animationName = self.xmlFile:getValue("vehicle.foldableSteps#animationName")
		v11_.animationSpeed = self.xmlFile:getValue("vehicle.foldableSteps#animationSpeed", 1)
		v11_.action = InputAction[self.xmlFile:getValue("vehicle.foldableSteps.controls#action", "IMPLEMENT_EXTRA2")] or InputAction.IMPLEMENT_EXTRA2
		v11_.actionPos = InputAction[self.xmlFile:getValue("vehicle.foldableSteps.controls#actionPos")]
		v11_.posText = self.xmlFile:getValue("vehicle.foldableSteps.controls#posText", nil, self.customEnvironment, false)
		v11_.actionNeg = InputAction[self.xmlFile:getValue("vehicle.foldableSteps.controls#actionNeg")]
		v11_.negText = self.xmlFile:getValue("vehicle.foldableSteps.controls#negText", nil, self.customEnvironment, false)
		v11_.fillUnitIndex = self.xmlFile:getValue("vehicle.foldableSteps#fillUnitIndex")
		v11_.allowFullFoldingAction = self.xmlFile:getValue("vehicle.foldableSteps#allowFullFoldingAction", true)
		v11_.releaseBrakesWhileFolding = self.xmlFile:getValue("vehicle.foldableSteps#releaseBrakesWhileFolding", true)
		v11_.stateIndex = 1
		v11_.stateTargetIndex = 1
		v11_.states = {}
		local v12_ = false
		for _, v13_ in self.xmlFile:iterator("vehicle.foldableSteps.state") do
			local v14_ = {
				["time"] = self.xmlFile:getValue(v13_ .. "#time")
			}
			if v14_.time == nil then
				Logging.xmlWarning(self.xmlFile, "Invalid state in \'%s\'", v13_)
			else
				v14_.time = v14_.time * 1000 / self:getAnimationDuration(v11_.animationName)
				v14_.posText = self.xmlFile:getValue(v13_ .. "#posText", nil, self.customEnvironment, false)
				v14_.posContext = self.xmlFile:getValue(v13_ .. "#posContext", "VEHICLE")
				v14_.negText = self.xmlFile:getValue(v13_ .. "#negText", nil, self.customEnvironment, false)
				v14_.negContext = self.xmlFile:getValue(v13_ .. "#negContext", "VEHICLE")
				v14_.infoText = self.xmlFile:getValue(v13_ .. "#infoText", nil, self.customEnvironment, false)
				v12_ = v14_.infoText ~= nil and true or v12_
				v14_.allowTurnOn = self.xmlFile:getValue(v13_ .. "#allowTurnOn", false)
				v14_.allowInfoHud = self.xmlFile:getValue(v13_ .. "#allowInfoHud", false)
				v14_.allowFilling = self.xmlFile:getValue(v13_ .. "#allowFilling", false)
				if v14_.posText == nil and v14_.negText == nil then
					Logging.xmlWarning(self.xmlFile, "Missing texts for state in \'%s\'", v13_)
				else
					local v15_ = v11_.states
					table.insert(v15_, v14_)
				end
			end
		end
		v11_.maxState = #v11_.states
		if not v12_ then
			SpecializationUtil.removeEventListener(self, "onDraw", FoldableSteps)
		end
		v11_.texts = {}
		v11_.texts.stateTextPos = self.xmlFile:getValue("vehicle.foldableSteps#stateTextPos", "action_foldableSteps_unfold", self.customEnvironment, false)
		v11_.texts.stateTextNeg = self.xmlFile:getValue("vehicle.foldableSteps#stateTextNeg", "action_foldableSteps_fold", self.customEnvironment, false)
		v11_.texts.warningNotAllowedPlayer = g_i18n:getText("warning_actionNotAllowedPlayer")
		v11_.texts.warningNotAllowedVehicle = g_i18n:getText("warning_actionNotAllowedVehicle")
		v11_.texts.warningUnfoldFirst = string.format(g_i18n:getText("warning_firstUnfoldTheTool"), self.typeDesc)
		if #v11_.states == 0 then
			Logging.xmlWarning(self.xmlFile, "No states found in \'vehicle.foldableSteps\'")
			return
		end
		if savegame ~= nil and not savegame.resetVehicles then
			v11_.loadedAnimTime = savegame.xmlFile:getValue(savegame.key .. ".foldableSteps#animTime", 0)
			v11_.stateIndex = savegame.xmlFile:getValue(savegame.key .. ".foldableSteps#state", v11_.stateIndex)
			v11_.stateTargetIndex = savegame.xmlFile:getValue(savegame.key .. ".foldableSteps#targetState", v11_.stateTargetIndex)
			return
		end
	end
end

-- Local values: spec
function FoldableSteps:onPostLoad(savegame)
	local v17_ = self.spec_foldableSteps
	if v17_.loadedAnimTime ~= nil then
		self:setAnimationTime(v17_.animationName, v17_.loadedAnimTime, true, false)
	end
end

-- Local values: spec
function FoldableSteps:saveToXMLFile(xmlFile, key, usedModNames)
	local v21_ = self.spec_foldableSteps
	if v21_.animationName ~= nil then
		xmlFile:setValue(key .. "#animTime", self:getAnimationTime(v21_.animationName))
		xmlFile:setValue(key .. "#state", v21_.stateIndex)
		xmlFile:setValue(key .. "#targetState", v21_.stateTargetIndex)
	end
end

-- Local values: spec, animTime, targetState
function FoldableSteps:onReadStream(streamId, connection)
	local v24_ = self.spec_foldableSteps
	local v25_ = streamReadFloat32(streamId)
	self:setAnimationTime(v24_.animationName, v25_, true, false)
	v24_.stateIndex = streamReadUIntN(streamId, FoldableSteps.STATE_NUM_BITS)
	self:setFoldableStepsFoldState(streamReadUIntN(streamId, FoldableSteps.STATE_NUM_BITS), true)
end

-- Local values: spec
function FoldableSteps:onWriteStream(streamId, connection)
	local v28_ = self.spec_foldableSteps
	streamWriteFloat32(streamId, self:getAnimationTime(v28_.animationName))
	streamWriteUIntN(streamId, v28_.stateIndex, FoldableSteps.STATE_NUM_BITS)
	streamWriteUIntN(streamId, v28_.stateTargetIndex, FoldableSteps.STATE_NUM_BITS)
end

-- Local values: spec
function FoldableSteps:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v30_ = self.spec_foldableSteps
	if v30_.stateIndex ~= v30_.stateTargetIndex then
		if not self:getIsAnimationPlaying(v30_.animationName) then
			v30_.stateIndex = v30_.stateTargetIndex
			FoldableSteps.updateActionEvents(self, v30_.actionEvents)
		end
		self:raiseActive()
	end
end

-- Local values: spec, targetState
function FoldableSteps:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v32_ = self.spec_foldableSteps
	local v33_ = v32_.states[v32_.stateTargetIndex]
	if v33_.infoText ~= nil then
		g_currentMission:addExtraPrintText(v33_.infoText)
	end
end

-- Local values: spec, _, actionEventId
function FoldableSteps:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v36_ = self.spec_foldableSteps
		self:clearActionEventsTable(v36_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if v36_.allowFullFoldingAction then
				local _, v37_ = self:addPoweredActionEvent(v36_.actionEvents, v36_.action, self, FoldableSteps.actionEventFold, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v37_, GS_PRIO_VERY_HIGH)
			end
			if v36_.actionPos ~= nil then
				local _, v38_ = self:addPoweredActionEvent(v36_.actionEvents, v36_.actionPos, self, FoldableSteps.actionEventFoldPos, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v38_, GS_PRIO_HIGH)
			end
			if v36_.actionNeg ~= nil then
				local _, v39_ = self:addPoweredActionEvent(v36_.actionEvents, v36_.actionNeg, self, FoldableSteps.actionEventFoldNeg, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v39_, GS_PRIO_HIGH)
			end
			FoldableSteps.updateActionEvents(self, v36_.actionEvents)
		end
	end
end

function FoldableSteps:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
	if name == "foldableStepsFull" then
		self:registerExternalActionEvent(trigger, name, FoldableSteps.externalActionEventFoldRegister, FoldableSteps.externalActionEventFoldUpdate)
	elseif name == "foldableStepsNextPos" then
		if self.spec_foldableSteps.actionPos ~= nil then
			self:registerExternalActionEvent(trigger, name, FoldableSteps.externalActionEventFoldPosRegister, FoldableSteps.externalActionEventFoldPosUpdate)
			return
		end
	elseif name == "foldableStepsNextNeg" and self.spec_foldableSteps.actionNeg ~= nil then
		self:registerExternalActionEvent(trigger, name, FoldableSteps.externalActionEventFoldNegRegister, FoldableSteps.externalActionEventFoldNegUpdate)
	end
end

-- Local values: spec, targetState, animationTime, difference
function FoldableSteps:setFoldableStepsFoldState(stateTargetIndex, noEventSend)
	local v46_ = self.spec_foldableSteps
	local v47_ = v46_.maxState
	v46_.stateTargetIndex = math.clamp(stateTargetIndex, 1, v47_)
	local v48_ = v46_.states[v46_.stateTargetIndex]
	local v49_ = self:getAnimationTime(v46_.animationName)
	local v50_ = v49_ - v48_.time
	if math.abs(v50_) > 0.0001 then
		self:setAnimationStopTime(v46_.animationName, v48_.time)
		self:playAnimation(v46_.animationName, v46_.animationSpeed * -math.sign(v50_), v49_, true)
		self:raiseActive()
	end
	FoldableSteps.updateActionEvents(self, v46_.actionEvents)
	FoldableStepsChangeStateEvent.sendEvent(self, v46_.stateTargetIndex, noEventSend)
end

-- Local values: spec, isMoving, actionEvent, text, state, state
function FoldableSteps:updateActionEvents(actionEvents)
	local v53_ = self.spec_foldableSteps
	local v54_ = v53_.stateIndex ~= v53_.stateTargetIndex
	local v55_ = actionEvents[v53_.action]
	if v55_ ~= nil then
		local v56_ = v53_.stateIndex < v53_.maxState and v53_.posText or v53_.negText
		if v56_ ~= nil then
			g_inputBinding:setActionEventText(v55_.actionEventId, string.format(v56_, self.typeDesc))
		end
		g_inputBinding:setActionEventActive(v55_.actionEventId, v56_ ~= nil)
	end
	local v57_ = actionEvents[v53_.actionPos]
	if v57_ ~= nil then
		if v54_ then
			g_inputBinding:setActionEventActive(v57_.actionEventId, false)
		else
			local v58_ = v53_.states[v53_.stateIndex]
			if v58_.posText == nil then
				g_inputBinding:setActionEventActive(v57_.actionEventId, false)
			else
				g_inputBinding:setActionEventText(v57_.actionEventId, string.format(v53_.texts.stateTextPos, string.format(v58_.posText, self.typeDesc)))
				g_inputBinding:setActionEventActive(v57_.actionEventId, true)
			end
		end
	end
	local v59_ = actionEvents[v53_.actionNeg]
	if v59_ ~= nil then
		if not v54_ then
			local v60_ = v53_.states[v53_.stateIndex]
			if v60_.negText == nil then
				g_inputBinding:setActionEventActive(v59_.actionEventId, false)
			else
				g_inputBinding:setActionEventText(v59_.actionEventId, string.format(v53_.texts.stateTextNeg, string.format(v60_.negText, self.typeDesc)))
				g_inputBinding:setActionEventActive(v59_.actionEventId, true)
			end
		end
		g_inputBinding:setActionEventActive(v59_.actionEventId, false)
	end
end

-- Local values: spec, stateTargetIndex
function FoldableSteps:actionEventFold(actionName, inputValue, callbackState, isAnalog)
	local v62_ = self.spec_foldableSteps
	local v63_
	if v62_.stateIndex == v62_.stateTargetIndex then
		v63_ = v62_.stateIndex >= v62_.maxState and 1 or v62_.maxState
	else
		v63_ = v62_.stateIndex < v62_.stateTargetIndex and 1 or v62_.maxState
	end
	if v63_ ~= nil and FoldableSteps.updateFoldStateChangeAllowed(self, v63_) then
		self:setFoldableStepsFoldState(v63_)
	end
end

-- Local values: spec, stateTargetIndex
function FoldableSteps:actionEventFoldPos(actionName, inputValue, callbackState, isAnalog)
	local v65_ = self.spec_foldableSteps.stateTargetIndex + 1
	if FoldableSteps.updateFoldStateChangeAllowed(self, v65_, g_inputBinding:getContextName()) then
		self:setFoldableStepsFoldState(v65_)
	end
end

-- Local values: spec, stateTargetIndex
function FoldableSteps:actionEventFoldNeg(actionName, inputValue, callbackState, isAnalog)
	local v67_ = self.spec_foldableSteps.stateTargetIndex - 1
	if FoldableSteps.updateFoldStateChangeAllowed(self, v67_, g_inputBinding:getContextName()) then
		self:setFoldableStepsFoldState(v67_)
	end
end

-- Local values: spec, allowed, warning, isPowered, powerWarning, oldState
function FoldableSteps:updateFoldStateChangeAllowed(stateTargetIndex, context)
	local v71_ = self.spec_foldableSteps
	local v72_, v73_ = self:getIsFoldAllowed(v71_.stateIndex < stateTargetIndex and self.spec_foldable.turnOnFoldDirection or self.spec_foldable.turnOnFoldDirection, false)
	if v72_ then
		local v74_, v75_ = self:getIsPowered()
		if v74_ then
			if context ~= nil then
				local v76_ = v71_.states[v71_.stateIndex]
				if v71_.stateIndex < stateTargetIndex and v76_.posContext ~= context or stateTargetIndex < v71_.stateIndex and v76_.negContext ~= context then
					if context == Vehicle.INPUT_CONTEXT_NAME then
						g_currentMission:showBlinkingWarning(string.format(v71_.texts.warningNotAllowedPlayer, self.typeDesc), 2000)
					else
						g_currentMission:showBlinkingWarning(string.format(v71_.texts.warningNotAllowedVehicle, self.typeDesc), 2000)
					end
					return false
				end
			end
			return true
		else
			g_currentMission:showBlinkingWarning(v75_, 2000)
			return false
		end
	else
		g_currentMission:showBlinkingWarning(v73_, 2000)
		return false
	end
end

-- Local values: spec, actionEvent, _
function FoldableSteps.externalActionEventFoldRegister(data, vehicle)
	local v79_ = vehicle.spec_foldableSteps
	local _, v84_ = g_inputBinding:registerActionEvent(v79_.action, data, function(_, p80_, p81_, p82_, p83_)
		-- upvalues: (copy) vehicle
		Motorized.tryStartMotor(vehicle)
		FoldableSteps.actionEventFold(vehicle, p80_, p81_, p82_, p83_)
	end, false, true, false, true)
	data.actionEventId = v84_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: spec, text
function FoldableSteps.externalActionEventFoldUpdate(data, vehicle)
	local v87_ = vehicle.spec_foldableSteps
	local v88_ = v87_.stateIndex < v87_.maxState and v87_.posText or v87_.negText
	if v88_ ~= nil then
		g_inputBinding:setActionEventText(data.actionEventId, string.format(v88_, vehicle.typeDesc))
	end
	g_inputBinding:setActionEventActive(data.actionEventId, v88_ ~= nil)
end

-- Local values: spec, actionEvent, _
function FoldableSteps.externalActionEventFoldPosRegister(data, vehicle)
	local v91_ = vehicle.spec_foldableSteps
	local _, v96_ = g_inputBinding:registerActionEvent(v91_.actionPos, data, function(_, p92_, p93_, p94_, p95_)
		-- upvalues: (copy) vehicle
		Motorized.tryStartMotor(vehicle)
		FoldableSteps.actionEventFoldPos(vehicle, p92_, p93_, p94_, p95_)
	end, false, true, false, true)
	data.actionEventId = v96_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: spec, isMoving, state
function FoldableSteps.externalActionEventFoldPosUpdate(data, vehicle)
	local v99_ = vehicle.spec_foldableSteps
	if v99_.stateIndex ~= v99_.stateTargetIndex then
		g_inputBinding:setActionEventActive(data.actionEventId, false)
		return
	else
		local v100_ = v99_.states[v99_.stateIndex]
		if v100_.posText == nil then
			g_inputBinding:setActionEventActive(data.actionEventId, false)
		else
			g_inputBinding:setActionEventText(data.actionEventId, string.format(v99_.texts.stateTextPos, string.format(v100_.posText, vehicle.typeDesc)))
			g_inputBinding:setActionEventActive(data.actionEventId, true)
		end
	end
end

-- Local values: spec, actionEvent, _
function FoldableSteps.externalActionEventFoldNegRegister(data, vehicle)
	local v103_ = vehicle.spec_foldableSteps
	local _, v108_ = g_inputBinding:registerActionEvent(v103_.actionNeg, data, function(_, p104_, p105_, p106_, p107_)
		-- upvalues: (copy) vehicle
		Motorized.tryStartMotor(vehicle)
		FoldableSteps.actionEventFoldNeg(vehicle, p104_, p105_, p106_, p107_)
	end, false, true, false, true)
	data.actionEventId = v108_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: spec, isMoving, state
function FoldableSteps.externalActionEventFoldNegUpdate(data, vehicle)
	local v111_ = vehicle.spec_foldableSteps
	if v111_.stateIndex ~= v111_.stateTargetIndex then
		g_inputBinding:setActionEventActive(data.actionEventId, false)
		return
	else
		local v112_ = v111_.states[v111_.stateIndex]
		if v112_.negText == nil then
			g_inputBinding:setActionEventActive(data.actionEventId, false)
		else
			g_inputBinding:setActionEventText(data.actionEventId, string.format(v111_.texts.stateTextNeg, string.format(v112_.negText, vehicle.typeDesc)))
			g_inputBinding:setActionEventActive(data.actionEventId, true)
		end
	end
end

-- Local values: spec, state
function FoldableSteps:getCanBeTurnedOn(superFunc)
	local v115_ = self.spec_foldableSteps
	if v115_.animationName ~= nil then
		local v116_ = v115_.states[v115_.stateIndex]
		if v115_.stateIndex ~= v115_.stateTargetIndex or not v116_.allowTurnOn then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: spec, state
function FoldableSteps:getTurnedOnNotAllowedWarning(superFunc)
	local v119_ = self.spec_foldableSteps
	if v119_.animationName ~= nil then
		local v120_ = v119_.states[v119_.stateIndex]
		if v119_.stateIndex ~= v119_.stateTargetIndex or not v120_.allowTurnOn then
			return v119_.texts.warningUnfoldFirst
		end
	end
	return superFunc(self)
end

-- Local values: spec
function FoldableSteps:getRequiresPower(superFunc)
	local v123_ = self.spec_foldableSteps
	return v123_.animationName ~= nil and v123_.stateIndex ~= v123_.stateTargetIndex and true or superFunc(self)
end

-- Local values: spec, state
function FoldableSteps:getAllowHudInfoTrigger(superFunc)
	local v126_ = self.spec_foldableSteps
	if v126_.animationName == nil or v126_.states[v126_.stateIndex].allowInfoHud then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec, state
function FoldableSteps:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
	local v131_ = self.spec_foldableSteps
	if v131_.animationName == nil or (toolType == ToolType.UNDEFINED or (fillUnitIndex ~= v131_.fillUnitIndex or v131_.states[v131_.stateIndex].allowFilling)) then
		return superFunc(self, fillUnitIndex, toolType)
	else
		return false
	end
end

-- Local values: spec
function FoldableSteps:getBrakeForce(superFunc)
	local v134_ = self.spec_foldableSteps
	return v134_.releaseBrakesWhileFolding and (v134_.animationName ~= nil and v134_.stateIndex ~= v134_.stateTargetIndex) and 0 or superFunc(self)
end

-- Local values: states, _, state
function FoldableSteps:loadDynamicLockPositionFromXML(superFunc, xmlFile, key, lockPosition)
	if not superFunc(self, xmlFile, key, lockPosition) then
		return false
	end
	local v140_ = xmlFile:getValue(key .. ".foldableSteps#states", nil, true)
	if v140_ ~= nil and #v140_ > 0 then
		lockPosition.foldableStepStates = {}
		for _, v141_ in ipairs(v140_) do
			lockPosition.foldableStepStates[v141_] = true
		end
	end
	return true
end

-- Local values: spec
function FoldableSteps:getIsDynamicLockPositionActive(superFunc, lockPosition)
	if lockPosition.foldableStepStates ~= nil then
		local v145_ = self.spec_foldableSteps
		if not lockPosition.foldableStepStates[v145_.stateIndex] then
			return false
		end
	end
	return superFunc(self, lockPosition)
end
