source("dataS/scripts/vehicles/specializations/events/SetWorkModeEvent.lua")
WorkMode = {}
source("dataS/scripts/gui/hud/extensions/WorkModeHUDExtension.lua")
WorkMode.WORKMODE_SEND_NUM_BITS = 4

function WorkMode.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
	return v2_
end
function WorkMode.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("workMode", g_i18n:getText("configuration_workMode"), "workModes", VehicleConfigurationItem)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("WorkMode")
	WorkMode.registerWorkModeXMLPaths(v3_, "vehicle.workModes")
	WorkMode.registerWorkModeXMLPaths(v3_, "vehicle.workModes.workModeConfigurations.workModeConfiguration(?)")
	v3_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).workMode#state", "Current work mode", 1)
end

function WorkMode.registerWorkModeXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMaxLimit", "Fold max. limit to change mode", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMinLimit", "Fold min. limit to change mode", 0)
	schema:register(XMLValueType.BOOL, basePath .. "#allowChangeOnLowered", "Allow change while lowered", true)
	schema:register(XMLValueType.BOOL, basePath .. "#allowChangeWhileTurnedOn", "Allow change while turned on", true)
	schema:addDelayedRegistrationPath(basePath .. ".workMode(?)", "WorkMode:workMode")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".workMode(?)#name", "Work mode name")
	schema:register(XMLValueType.STRING, basePath .. ".workMode(?)#inputBindingName", "Input action name for quick access")
	schema:register(XMLValueType.BOOL, basePath .. ".workMode(?)#isDefault", "Work mode is active by default", false)
	schema:register(XMLValueType.STRING, basePath .. ".workMode(?).turnedOnAnimations.turnedOnAnimation(?)#name", "Turned on animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).turnedOnAnimations.turnedOnAnimation(?)#turnOnFadeTime", "Turn on fade time (sec.)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).turnedOnAnimations.turnedOnAnimation(?)#turnOffFadeTime", "Turn off fade time (sec.)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).turnedOnAnimations.turnedOnAnimation(?)#speedScale", "Speed scale", 1)
	schema:register(XMLValueType.STRING, basePath .. ".workMode(?).loweringAnimations.loweringAnimation(?)#name", "Lowering animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).loweringAnimations.loweringAnimation(?)#speed", "Speed scale", 1)
	schema:register(XMLValueType.INT, basePath .. ".workMode(?).workAreas.workArea(?)#workAreaIndex", "Work area index")
	schema:register(XMLValueType.INT, basePath .. ".workMode(?).workAreas.workArea(?)#dropAreaIndex", "Drop area index")
	schema:register(XMLValueType.STRING, basePath .. ".workMode(?).animation(?)#name", "Mode change animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).animation(?)#speed", "Mode change animation speed", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).animation(?)#stopTime", "Mode change animation stop time")
	schema:register(XMLValueType.BOOL, basePath .. ".workMode(?).animation(?)#repeatAfterUnfolding", "Repeat animation after unfolding", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".workMode(?).animation(?)#repeatStartTime", "Repeat start time")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".workMode(?).movingToolLimit#node", "Target moving tool node")
	schema:register(XMLValueType.ANGLE, basePath .. ".workMode(?).movingToolLimit#minRot", "Min. rotation", 0)
	schema:register(XMLValueType.ANGLE, basePath .. ".workMode(?).movingToolLimit#maxRot", "Max. rotation", 0)
	schema:register(XMLValueType.INT, basePath .. ".workMode(?).variableWorkWidth#leftState", "Forced index on left side")
	schema:register(XMLValueType.INT, basePath .. ".workMode(?).variableWorkWidth#rightState", "Forced index on right side")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".workMode(?).windrowerEffect")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".workMode(?).animationNodes")
	AIImplement.registerAIImplementBaseXMLPaths(schema, basePath .. ".workMode(?).ai")
	schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#workModeIndex", "Index of work mode to activate spray type")
	schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(p6_, p7_)
		p6_:register(XMLValueType.BOOL, p7_ .. "#allowWhileChangingWorkMode", "Allow movement while changing work mode", true)
	end)
end

function WorkMode.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onWorkModeChanged")
end

function WorkMode.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWorkModeFromXML", WorkMode.loadWorkModeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setWorkMode", WorkMode.setWorkMode)
	SpecializationUtil.registerFunction(vehicleType, "getWorkMode", WorkMode.getWorkMode)
	SpecializationUtil.registerFunction(vehicleType, "getIsWorkModeChangeAllowed", WorkMode.getIsWorkModeChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "deactivateWindrowerEffects", WorkMode.deactivateWindrowerEffects)
end

function WorkMode.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", WorkMode.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", WorkMode.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", WorkMode.getAllowsLowering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSprayTypeFromXML", WorkMode.loadSprayTypeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSprayTypeActive", WorkMode.getIsSprayTypeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", WorkMode.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", WorkMode.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", WorkMode.getAreEffectsVisible)
end

function WorkMode.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", WorkMode)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", WorkMode)
end

-- Local values: spec, baseKey, configurationId, configKey, _, key, entry
function WorkMode:onLoad(savegame)
	local v13_ = self.spec_workMode
	local v14_ = self.configurations.workMode or 1
	local v15_ = string.format("vehicle.workModes.workModeConfigurations.workModeConfiguration(%d)", v14_ - 1)
	local v16_ = not self.xmlFile:hasProperty(v15_) and "vehicle.workModes" or v15_
	if self.xmlFile:hasProperty(v16_) then
		v13_.state = 1
		v13_.stateMax = 0
		v13_.foldMaxLimit = self.xmlFile:getValue(v16_ .. "#foldMaxLimit", 1)
		v13_.foldMinLimit = self.xmlFile:getValue(v16_ .. "#foldMinLimit", 0)
		v13_.allowChangeOnLowered = self.xmlFile:getValue(v16_ .. "#allowChangeOnLowered", true)
		v13_.allowChangeWhileTurnedOn = self.xmlFile:getValue(v16_ .. "#allowChangeWhileTurnedOn", true)
		v13_.workModes = {}
		v13_.defaultWorkModeIndex = 1
		for _, v17_ in self.xmlFile:iterator(v16_ .. ".workMode") do
			local v18_ = {}
			if self:loadWorkModeFromXML(self.xmlFile, v17_, v18_) then
				local v19_ = v13_.workModes
				table.insert(v19_, v18_)
				if v18_.isDefault then
					v13_.defaultWorkModeIndex = #v13_.workModes
				end
			end
		end
		v13_.stateMax = #v13_.workModes
		if v13_.stateMax > 2 ^ WorkMode.WORKMODE_SEND_NUM_BITS - 1 then
			printError("Error: WorkMode only supports " .. 2 ^ WorkMode.WORKMODE_SEND_NUM_BITS - 1 .. " modes!")
		end
		if v13_.stateMax > 0 then
			self:setWorkMode(v13_.defaultWorkModeIndex, true)
			v13_.hudExtension = WorkModeHUDExtension.new(self)
		end
		v13_.accumulatedFruitType = FruitType.UNKNOWN
		v13_.dirtyFlag = self:getNextDirtyFlag()
	end
	if v13_.stateMax == nil or v13_.stateMax == 0 then
		SpecializationUtil.removeEventListener(self, "onPostLoad", WorkMode)
		SpecializationUtil.removeEventListener(self, "onDelete", WorkMode)
		SpecializationUtil.removeEventListener(self, "onReadStream", WorkMode)
		SpecializationUtil.removeEventListener(self, "onWriteStream", WorkMode)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", WorkMode)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", WorkMode)
		SpecializationUtil.removeEventListener(self, "onUpdate", WorkMode)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", WorkMode)
		SpecializationUtil.removeEventListener(self, "onDraw", WorkMode)
		SpecializationUtil.removeEventListener(self, "onTurnedOn", WorkMode)
		SpecializationUtil.removeEventListener(self, "onTurnedOff", WorkMode)
		SpecializationUtil.removeEventListener(self, "onDeactivate", WorkMode)
		SpecializationUtil.removeEventListener(self, "onSetLowered", WorkMode)
		SpecializationUtil.removeEventListener(self, "onFoldStateChanged", WorkMode)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", WorkMode)
	end
end

-- Local values: spec, workMode, foldAnimTime
function WorkMode:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local v22_ = self.spec_workMode
		if v22_.stateMax > 0 and savegame.xmlFile:hasProperty(savegame.key .. ".workMode#state") then
			local v23_ = savegame.xmlFile:getValue(savegame.key .. ".workMode#state", v22_.defaultWorkModeIndex)
			local v24_ = v22_.stateMax
			self:setWorkMode(math.clamp(v23_, 1, v24_), true)
			AnimatedVehicle.updateAnimations(self, 99999999, true)
			if self.spec_foldable ~= nil and (self.spec_foldable.hasFoldingParts and self.spec_foldable.foldMoveDirection == 0) then
				local v25_ = self:getFoldAnimTime()
				if v25_ <= 0 then
					self.spec_foldable.foldMoveDirection = -1
					return
				end
				if self.spec_foldable.foldMiddleAnimTime == v25_ then
					self.spec_foldable.moveToMiddle = true
				end
				self.spec_foldable.foldMoveDirection = 1
			end
		end
	end
end

-- Local values: spec
function WorkMode:saveToXMLFile(xmlFile, key, usedModNames)
	local v29_ = self.spec_workMode
	if v29_.state ~= nil then
		xmlFile:setValue(key .. "#state", v29_.state)
	end
end

-- Local values: spec, _, mode
function WorkMode:onDelete()
	local v31_ = self.spec_workMode
	if v31_.workModes ~= nil then
		for _, v32_ in ipairs(v31_.workModes) do
			g_effectManager:deleteEffects(v32_.windrowerEffects)
			g_animationManager:deleteAnimations(v32_.animationNodes)
		end
	end
	if v31_.hudExtension ~= nil then
		v31_.hudExtension:delete()
	end
end

-- Local values: state
function WorkMode:onReadStream(streamId, connection)
	self:setWorkMode(streamReadUIntN(streamId, WorkMode.WORKMODE_SEND_NUM_BITS), true)
end

-- Local values: spec
function WorkMode:onWriteStream(streamId, connection)
	local v37_ = self.spec_workMode
	streamWriteUIntN(streamId, v37_.state, WorkMode.WORKMODE_SEND_NUM_BITS)
end

-- Local values: spec, mode, _, effect
function WorkMode:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v41_ = self.spec_workMode
		local v42_ = v41_.workModes[v41_.state]
		for _, v43_ in ipairs(v42_.windrowerEffects) do
			if streamReadBool(streamId) then
				v43_.lastChargeTime = g_currentMission.time
			end
		end
		v41_.accumulatedFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
	end
end

-- Local values: spec, mode, _, effect
function WorkMode:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v48_ = self.spec_workMode
		local v49_ = streamWriteBool
		local v50_ = v48_.dirtyFlag
		if v49_(streamId, bit32.band(dirtyMask, v50_) ~= 0) then
			local v51_ = v48_.workModes[v48_.state]
			for _, v52_ in ipairs(v51_.windrowerEffects) do
				streamWriteBool(streamId, v52_.lastChargeTime + 500 > g_currentMission.time)
			end
			streamWriteUIntN(streamId, v48_.accumulatedFruitType, FruitTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, mode, i, _, turnedOnAnimation, duration, min, max, _, effect, fillType, allowWorkModeChange, actionEvent, _, workMode, mode, fruitType, workAreaCharge, _, area, workArea, _, effect
function WorkMode:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v55_ = self.spec_workMode
	if self.isClient then
		local v56_ = v55_.workModes[v55_.state]
		for v57_ = 1, #v55_.workModes do
			for _, v58_ in pairs(v55_.workModes[v57_].turnedOnAnimations) do
				if v58_.speedDirection ~= 0 then
					local v59_ = v58_.turnOnFadeTime
					if v58_.speedDirection == -1 then
						v59_ = v58_.turnOffFadeTime
					end
					local v60_, v61_
					if v58_.speedDirection == 1 then
						v60_ = -1
						v61_ = 1
					else
						v60_ = 0
						v61_ = 1
					end
					local v62_ = v58_.currentSpeed + v58_.speedDirection * dt / v59_
					v58_.currentSpeed = math.clamp(v62_, v60_, v61_)
					if self:getIsAnimationPlaying(v58_.name) then
						self:setAnimationSpeed(v58_.name, v58_.currentSpeed * v58_.speedScale)
					else
						self:playAnimation(v58_.name, v58_.currentSpeed * v58_.speedScale, self:getAnimationTime(v58_.name), true)
					end
					if v58_.speedDirection == -1 and v58_.currentSpeed == 0 then
						self:stopAnimation(v58_.name, true)
					end
					if v58_.currentSpeed == 1 or v58_.currentSpeed == 0 then
						v58_.speedDirection = 0
					end
				end
			end
		end
		for _, v63_ in pairs(v56_.windrowerEffects) do
			if v63_.lastChargeTime + 500 > g_currentMission.time then
				local v64_ = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(v55_.accumulatedFruitType)
				if v64_ ~= nil then
					v63_:setFillType(v64_)
					if not v63_:isRunning() then
						g_effectManager:startEffect(v63_)
					end
				end
			elseif v63_.turnOffRequiredEffect == 0 or v63_.turnOffRequiredEffect ~= 0 and not v56_.windrowerEffects[v63_.turnOffRequiredEffect]:isRunning() then
				g_effectManager:stopEffect(v63_)
			end
		end
		local v65_ = self:getIsWorkModeChangeAllowed()
		local v66_ = v55_.actionEvents[InputAction.TOGGLE_WORKMODE]
		if v66_ ~= nil then
			g_inputBinding:setActionEventActive(v66_.actionEventId, v65_)
		end
		for _, v67_ in ipairs(v55_.workModes) do
			if v67_.inputAction ~= nil then
				local v68_ = v55_.actionEvents[v67_.inputAction]
				if v68_ ~= nil then
					g_inputBinding:setActionEventActive(v68_.actionEventId, v65_)
				end
			end
		end
	end
	if self.isServer then
		local v69_ = v55_.workModes[v55_.state]
		local v70_ = nil
		local v71_ = nil
		for _, v72_ in ipairs(v69_.workAreas) do
			local v73_ = self.spec_workArea.workAreas[v72_.workAreaIndex]
			if v73_ ~= nil then
				if v73_.lastValidPickupFruitType ~= FruitType.UNKNOWN then
					v71_ = v73_.lastValidPickupFruitType
				end
				v70_ = v70_ or v73_.lastPickupLiters ~= 0
			end
		end
		if v71_ ~= nil and v71_ ~= v55_.accumulatedFruitType then
			v55_.accumulatedFruitType = v71_
			self:raiseDirtyFlags(v55_.dirtyFlag)
		end
		for _, v74_ in pairs(v69_.windrowerEffects) do
			if v70_ then
				v74_.lastChargeTime = g_currentMission.time
				self:raiseDirtyFlags(v55_.dirtyFlag)
			end
		end
	end
end

-- Local values: spec, foldAnimTime, mode, _, anim, curTime, speed
function WorkMode:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v76_ = self.spec_workMode
	if self.getFoldAnimTime ~= nil then
		local v77_ = self:getFoldAnimTime()
		if v77_ == 0 or v77_ == self.spec_foldable.foldMiddleAnimTime then
			local v78_ = v76_.workModes[v76_.state]
			for _, v79_ in pairs(v78_.animations) do
				if v79_.repeatAfterUnfolding and not v79_.repeated then
					local v80_ = self:getAnimationTime(v79_.animName)
					if v79_.stopTime == nil then
						self:playAnimation(v79_.animName, v79_.animSpeed, Utils.getNoNil(v79_.repeatStartTime, v80_), true)
					else
						self:setAnimationStopTime(v79_.animName, v79_.stopTime)
						local v81_ = v79_.animSpeed
						local v82_ = math.abs(v81_)
						if v79_.stopTime < v80_ then
							local v83_ = v79_.animSpeed
							v82_ = -math.abs(v83_)
						end
						self:playAnimation(v79_.animName, v82_, Utils.getNoNil(v79_.repeatStartTime, v80_), true)
					end
					v79_.repeated = true
				end
			end
		end
		if v76_.playDelayedLoweringAnimation ~= nil and (v77_ == 1 or (v77_ == 0 or v77_ == self.spec_foldable.foldMiddleAnimTime)) then
			WorkMode.onSetLowered(self, v76_.playDelayedLoweringAnimation)
			v76_.playDelayedLoweringAnimation = nil
		end
	end
end

-- Local values: spec, hud
function WorkMode:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v85_ = self.spec_workMode
	if v85_.hudExtension ~= nil then
		g_currentMission.hud:addHelpExtension(v85_.hudExtension)
	end
end

function WorkMode:onDeactivate()
	WorkMode.deactivateWindrowerEffects(self)
end

-- Local values: spec, _, mode
function WorkMode:deactivateWindrowerEffects()
	if self.isClient then
		local v88_ = self.spec_workMode
		for _, v89_ in pairs(v88_.workModes) do
			if v89_.windrowerEffects ~= nil then
				g_effectManager:stopEffects(v89_.windrowerEffects)
			end
		end
	end
end

-- Local values: inputBindingName, _, animKey, turnedOnAnimation, _, animKey, loweringAnimation, i, workAreaKey, workArea, _, animKey, animation, movingToolLimitNode
function WorkMode:loadWorkModeFromXML(xmlFile, key, workMode)
	workMode.name = xmlFile:getValue(key .. "#name", nil, self.customEnvironment)
	local v94_ = xmlFile:getValue(key .. "#inputBindingName")
	if v94_ ~= nil and InputAction[v94_] ~= nil then
		workMode.inputAction = InputAction[v94_]
	end
	workMode.isDefault = xmlFile:getValue(key .. "#isDefault", false)
	workMode.turnedOnAnimations = {}
	for _, v95_ in xmlFile:iterator(key .. ".turnedOnAnimations.turnedOnAnimation") do
		local v96_ = {
			["name"] = xmlFile:getValue(v95_ .. "#name"),
			["turnOnFadeTime"] = xmlFile:getValue(v95_ .. "#turnOnFadeTime", 1) * 1000,
			["turnOffFadeTime"] = xmlFile:getValue(v95_ .. "#turnOffFadeTime", 1) * 1000,
			["speedScale"] = xmlFile:getValue(v95_ .. "#speedScale", 1),
			["speedDirection"] = 0,
			["currentSpeed"] = 0
		}
		if self:getAnimationExists(v96_.name) then
			local v97_ = workMode.turnedOnAnimations
			table.insert(v97_, v96_)
		end
	end
	workMode.loweringAnimations = {}
	for _, v98_ in xmlFile:iterator(key .. ".loweringAnimations.loweringAnimation") do
		local v99_ = {
			["name"] = xmlFile:getValue(v98_ .. "#name"),
			["speed"] = xmlFile:getValue(v98_ .. "#speed", 1)
		}
		if self:getAnimationExists(v99_.name) then
			local v100_ = workMode.loweringAnimations
			table.insert(v100_, v99_)
		end
	end
	workMode.workAreas = {}
	for v101_, v102_ in xmlFile:iterator(key .. ".workAreas.workArea") do
		local v103_ = {
			["workAreaIndex"] = xmlFile:getValue(v102_ .. "#workAreaIndex", v101_),
			["dropAreaIndex"] = xmlFile:getValue(v102_ .. "#dropAreaIndex", v101_)
		}
		local v104_ = workMode.workAreas
		table.insert(v104_, v103_)
	end
	workMode.animations = {}
	for _, v105_ in xmlFile:iterator(key .. ".animation") do
		local v106_ = {
			["animName"] = xmlFile:getValue(v105_ .. "#name"),
			["animSpeed"] = xmlFile:getValue(v105_ .. "#speed", 1),
			["stopTime"] = xmlFile:getValue(v105_ .. "#stopTime"),
			["repeatAfterUnfolding"] = xmlFile:getValue(v105_ .. "#repeatAfterUnfolding", false),
			["repeatStartTime"] = xmlFile:getValue(v105_ .. "#repeatStartTime"),
			["repeated"] = false
		}
		if self:getAnimationExists(v106_.animName) then
			local v107_ = workMode.animations
			table.insert(v107_, v106_)
		end
	end
	local v108_ = xmlFile:getValue(key .. ".movingToolLimit#node", nil, self.components, self.i3dMappings)
	if v108_ ~= nil then
		workMode.movingTool = self:getMovingToolByNode(v108_)
		workMode.movingToolMinRot = xmlFile:getValue(key .. ".movingToolLimit#minRot", 0)
		workMode.movingToolMaxRot = xmlFile:getValue(key .. ".movingToolLimit#maxRot", 0)
	end
	if self.setSectionsActive ~= nil then
		workMode.variableWorkWidth = {}
		workMode.variableWorkWidth.leftState = xmlFile:getValue(key .. ".variableWorkWidth#leftState")
		workMode.variableWorkWidth.rightState = xmlFile:getValue(key .. ".variableWorkWidth#rightState")
	end
	workMode.windrowerEffects = g_effectManager:loadEffect(xmlFile, string.format("%s.windrowerEffect", key), self.components, self, self.i3dMappings)
	workMode.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
	if self.loadAIImplementBaseSetupFromXML ~= nil then
		self:loadAIImplementBaseSetupFromXML(xmlFile, key .. ".ai", function(_)
			-- upvalues: (copy) self, (copy) workMode
			local v109_ = self.spec_workMode
			return v109_.workModes[v109_.state] == workMode
		end)
	end
	return true
end

-- Local values: spec, currentMode, newMode, _, anim, curTime, _, anim, curTime, speed, isTurnedOn, _, turnedOnAnimation, i, otherMode, j, otherAnimation, animationSpeed, alpha, _, effect, workAreaSpec, workAreas, _, workArea, workAreaToSet, movingTool
function WorkMode:setWorkMode(state, noEventSend)
	local v113_ = self.spec_workMode
	if noEventSend == nil or noEventSend == false then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(SetWorkModeEvent.new(self, state))
		else
			g_server:broadcastEvent(SetWorkModeEvent.new(self, state), nil, nil, self)
		end
	end
	local v114_ = v113_.workModes[v113_.state]
	local v115_ = v113_.workModes[state]
	if v115_ ~= nil then
		if state ~= v113_.state then
			if v114_.animations ~= nil then
				for _, v116_ in pairs(v114_.animations) do
					local v117_ = self:getAnimationTime(v116_.animName)
					if v116_.stopTime == nil then
						self:playAnimation(v116_.animName, -v116_.animSpeed, v117_, noEventSend)
					end
				end
				g_animationManager:stopAnimations(v114_.animationNodes)
			end
			if v115_.animations ~= nil then
				for _, v118_ in pairs(v115_.animations) do
					local v119_ = self:getAnimationTime(v118_.animName)
					if v118_.stopTime == nil then
						self:playAnimation(v118_.animName, v118_.animSpeed, v119_, noEventSend)
					else
						self:setAnimationStopTime(v118_.animName, v118_.stopTime)
						local v120_ = v118_.animSpeed
						local v121_ = math.abs(v120_)
						if v118_.stopTime < v119_ then
							local v122_ = v118_.animSpeed
							v121_ = -math.abs(v122_)
						end
						self:playAnimation(v118_.animName, v121_, v119_, noEventSend)
					end
				end
			end
			if self.getIsTurnedOn ~= nil then
				local v123_ = self:getIsTurnedOn()
				if v115_.animations ~= nil and v123_ then
					g_animationManager:startAnimations(v115_.animationNodes)
				end
				if v123_ then
					for _, v124_ in pairs(v115_.turnedOnAnimations) do
						if self:getIsAnimationPlaying(v124_.name) then
							for v125_ = 1, #v113_.workModes do
								local v126_ = v113_.workModes[v125_]
								if v126_ ~= v115_ then
									for v127_ = 1, #v126_.turnedOnAnimations do
										local v128_ = v126_.turnedOnAnimations[v127_]
										if v128_.name == v124_.name then
											local v129_ = self.spec_animatedVehicle.animations[v124_.name].currentSpeed
											if v129_ ~= 0 then
												v124_.currentSpeed = v129_ / v124_.speedScale
												v128_.currentSpeed = 0
												v128_.speedDirection = 0
											end
										end
									end
								end
							end
						end
						v124_.speedDirection = 1
					end
				end
			end
			if v115_.variableWorkWidth ~= nil then
				if v115_.variableWorkWidth.leftState ~= nil then
					self:setSectionsActive(v115_.variableWorkWidth.leftState, self.spec_variableWorkWidth.rightSide, true)
				end
				if v115_.variableWorkWidth.rightState ~= nil then
					self:setSectionsActive(self.spec_variableWorkWidth.leftSide, v115_.variableWorkWidth.rightState, true)
				end
			end
			for _, v130_ in pairs(v114_.windrowerEffects) do
				g_effectManager:stopEffect(v130_)
			end
			v113_.state = state
		end
		local v131_ = self.spec_workArea
		if v131_ ~= nil then
			local v132_ = v131_.workAreas
			for _, v133_ in pairs(v113_.workModes[state].workAreas) do
				local v134_ = v132_[v133_.workAreaIndex]
				if v134_ ~= nil then
					v134_.dropWindrowWorkAreaIndex = v133_.dropAreaIndex
					v134_.dropAreaIndex = v133_.dropAreaIndex
				end
			end
		end
		if v115_.movingTool ~= nil then
			local v135_ = v115_.movingTool
			if v115_.movingToolMinRot ~= nil then
				v135_.rotMin = v115_.movingToolMinRot
			end
			if v115_.movingToolMaxRot ~= nil then
				v135_.rotMax = v115_.movingToolMaxRot
			end
			if self.isClient then
				v135_.networkInterpolators.rotation:setMinMax(v135_.rotMin, v135_.rotMax)
			end
		end
		SpecializationUtil.raiseEvent(self, "onWorkModeChanged", v115_, v114_)
	end
end

-- Local values: spec
function WorkMode:getWorkMode()
	local v137_ = self.spec_workMode
	if v137_.workModes == nil then
		return nil
	else
		return v137_.workModes[v137_.state]
	end
end

-- Local values: spec, _, workArea2
function WorkMode:getIsWorkAreaActive(superFunc, workArea)
	local v141_ = self.spec_workMode
	if v141_.stateMax ~= nil and v141_.stateMax > 0 then
		for _, v142_ in pairs(v141_.workModes[v141_.state].workAreas) do
			if workArea.index == v142_.workAreaIndex and v142_.dropAreaIndex == 0 then
				return false
			end
		end
	end
	return superFunc(self, workArea)
end

function WorkMode:getCanBeSelected(superFunc)
	return true
end

-- Local values: allowLowering, warning, spec, hasLoweringAnimations
function WorkMode:getAllowsLowering(superFunc)
	local v145_, v146_ = superFunc(self)
	local v147_ = self.spec_workMode
	local v148_
	if v147_.workModes == nil or #v147_.workModes <= 0 then
		v148_ = false
	else
		v148_ = #v147_.workModes[v147_.state].loweringAnimations > 0
	end
	return v145_ or v148_, v146_
end

function WorkMode:loadSprayTypeFromXML(superFunc, xmlFile, key, sprayType)
	sprayType.workModeIndex = xmlFile:getValue(key .. "#workModeIndex")
	return superFunc(self, xmlFile, key, sprayType)
end

function WorkMode:getIsSprayTypeActive(superFunc, sprayType)
	if sprayType.workModeIndex == nil or self.spec_workMode.state == sprayType.workModeIndex then
		return superFunc(self, sprayType)
	else
		return false
	end
end

function WorkMode:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.allowWhileChangingWorkMode = xmlFile:getValue(key .. "#allowWhileChangingWorkMode", true)
	return true
end

-- Local values: spec, i, workMode, j
function WorkMode:getIsMovingToolActive(superFunc, movingTool)
	if not movingTool.allowWhileChangingWorkMode then
		local v165_ = self.spec_workMode
		if v165_.stateMax ~= nil then
			for v166_ = 1, #v165_.workModes do
				local v167_ = v165_.workModes[v166_]
				for v168_ = 1, #v167_.animations do
					if self:getIsAnimationPlaying(v167_.animations[v168_].animName) then
						return false
					end
				end
			end
		end
	end
	return superFunc(self, movingTool)
end

-- Local values: spec, i, workMode, j
function WorkMode:getAreEffectsVisible(superFunc)
	if not superFunc(self) then
		return false
	end
	local v171_ = self.spec_workMode
	if v171_.stateMax ~= nil and v171_.stateMax > 0 then
		for v172_ = 1, #v171_.workModes do
			local v173_ = v171_.workModes[v172_]
			for v174_ = 1, #v173_.animations do
				if self:getIsAnimationPlaying(v173_.animations[v174_].animName) then
					return false
				end
			end
		end
	end
	return true
end

-- Local values: spec, attacherVehicle, index, attacherJoint
function WorkMode:getIsWorkModeChangeAllowed()
	local v176_ = self.spec_workMode
	if self.getFoldAnimTime ~= nil and (self:getFoldAnimTime() > v176_.foldMaxLimit or self:getFoldAnimTime() < v176_.foldMinLimit) then
		return false
	end
	if not v176_.allowChangeOnLowered then
		local v177_ = self:getAttacherVehicle()
		if v177_ ~= nil and v177_:getAttacherJointByJointDescIndex((v177_:getAttacherJointIndexFromObject(self))).moveDown then
			return false
		end
	end
	return true
end

-- Local values: spec, mode, _, turnedOnAnimation
function WorkMode:onTurnedOff()
	local v179_ = self.spec_workMode
	if self.isClient then
		WorkMode.deactivateWindrowerEffects(self)
		local v180_ = v179_.workModes[v179_.state]
		for _, v181_ in pairs(v180_.turnedOnAnimations) do
			v181_.speedDirection = -1
		end
		g_animationManager:stopAnimations(v180_.animationNodes)
	end
end

-- Local values: spec, mode, _, turnedOnAnimation
function WorkMode:onTurnedOn()
	local v183_ = self.spec_workMode
	if self.isClient then
		local v184_ = v183_.workModes[v183_.state]
		for _, v185_ in pairs(v184_.turnedOnAnimations) do
			v185_.speedDirection = 1
		end
		g_animationManager:startAnimations(v184_.animationNodes)
	end
end

-- Local values: spec, foldAnimTime, mode, _, loweringAnimation
function WorkMode:onSetLowered(lowered)
	local v188_ = self.spec_workMode
	if self.getFoldAnimTime ~= nil then
		local v189_ = self:getFoldAnimTime()
		if v189_ ~= 1 and (v189_ ~= 0 and v189_ ~= self.foldMiddleAnimTime) then
			v188_.playDelayedLoweringAnimation = lowered
			return
		end
	end
	local v190_ = v188_.workModes[v188_.state]
	for _, v191_ in pairs(v190_.loweringAnimations) do
		if lowered then
			if self:getAnimationTime(v191_.name) < 1 then
				self:playAnimation(v191_.name, v191_.speed, nil, true)
			end
		elseif self:getAnimationTime(v191_.name) > 0 then
			self:playAnimation(v191_.name, -v191_.speed, nil, true)
		end
	end
end

-- Local values: spec, mode, _, anim, attacherVehicle
function WorkMode:onFoldStateChanged(direction, moveToMiddle)
	local v194_ = self.spec_workMode
	if direction > 0 then
		local v195_ = v194_.workModes[v194_.state]
		for _, v196_ in pairs(v195_.animations) do
			if v196_.repeatAfterUnfolding then
				v196_.repeated = false
			end
		end
		if self:getIsLowered() and self.getAttacherVehicle ~= nil then
			local v197_ = self:getAttacherVehicle()
			if v197_ ~= nil then
				v197_:handleLowerImplementEvent()
			end
		end
	end
end

-- Local values: spec, _, actionEventId, _, mode
function WorkMode:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v200_ = self.spec_workMode
		if v200_.stateMax > 0 then
			self:clearActionEventsTable(v200_.actionEvents)
			if isActiveForInputIgnoreSelection then
				local _, v201_ = self:addPoweredActionEvent(v200_.actionEvents, InputAction.TOGGLE_WORKMODE, self, WorkMode.actionEventWorkModeChange, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v201_, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventActive(v201_, false)
				for _, v202_ in ipairs(v200_.workModes) do
					if v202_.inputAction ~= nil then
						local _, v203_ = self:addPoweredActionEvent(v200_.actionEvents, v202_.inputAction, self, WorkMode.actionEventWorkModeChangeDirect, false, true, false, true, nil)
						g_inputBinding:setActionEventTextVisibility(v203_, false)
						g_inputBinding:setActionEventActive(v203_, false)
					end
				end
			end
		end
	end
end

-- Local values: spec, state
function WorkMode:actionEventWorkModeChange(actionName, inputValue, callbackState, isAnalog)
	local v205_ = self.spec_workMode
	local v206_ = v205_.state + 1
	local v207_ = v205_.stateMax < v206_ and 1 or v206_
	if v207_ ~= v205_.state then
		self:setWorkMode(v207_)
	end
end

-- Local values: spec, state, mode
function WorkMode:actionEventWorkModeChangeDirect(actionName, inputValue, callbackState, isAnalog)
	local v210_ = self.spec_workMode
	for v211_, v212_ in ipairs(v210_.workModes) do
		if v212_.inputAction == InputAction[actionName] and v211_ ~= v210_.state then
			self:setWorkMode(v211_)
		end
	end
end
