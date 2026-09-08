CraneShovel = {}
source("dataS/scripts/vehicles/specializations/events/CraneShovelEvent.lua")

function CraneShovel.prerequisitesPresent(specializations)
	return true
end
function CraneShovel.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("CraneShovel")
	v1_:addDelayedRegistrationPath("vehicle.craneShovel", "CraneShovel")
	v1_:register(XMLValueType.STRING, "vehicle.craneShovel#inputAction", "Input action name to open and close the shovel")
	v1_:register(XMLValueType.STRING, "vehicle.craneShovel#animationName", "Name of the animation")
	v1_:register(XMLValueType.FLOAT, "vehicle.craneShovel#animationSpeed", "Speed of animation", 1)
	v1_:register(XMLValueType.BOOL, "vehicle.craneShovel#isDefaultOpen", "Shovel is open by default", false)
	v1_:register(XMLValueType.BOOL, "vehicle.craneShovel#closeWhileFolding", "Close shovel while folding", false)
	v1_:register(XMLValueType.INT, "vehicle.craneShovel#fillUnitIndex", "Index of fill unit", 1)
	v1_:register(XMLValueType.INT, "vehicle.craneShovel#dischargeNodeIndex", "Index of discharge node", 1)
	v1_:register(XMLValueType.L10N_STRING, "vehicle.craneShovel.texts#open", "Text for opening", "$l10n_action_craneShovelOpen")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.craneShovel.texts#close", "Text for closing", "$l10n_action_craneShovelClose")
	v1_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).craneShovel#state", "Shovel open/close state", false)
end

function CraneShovel.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCraneShovelFromXML", CraneShovel.loadCraneShovelFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setCraneShovelState", CraneShovel.setCraneShovelState)
	SpecializationUtil.registerFunction(vehicleType, "getCraneShovelStateChangedAllowed", CraneShovel.getCraneShovelStateChangedAllowed)
end

function CraneShovel.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", CraneShovel.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", CraneShovel.getShovelNodeIsActive)
end

function CraneShovel.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CraneShovel)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", CraneShovel)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CraneShovel)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CraneShovel)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", CraneShovel)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CraneShovel)
end

-- Local values: spec
function CraneShovel:onLoad(savegame)
	local v6_ = self.spec_craneShovel
	if self:loadCraneShovelFromXML(v6_, self.xmlFile, "vehicle.craneShovel") then
		v6_.state = v6_.isDefaultOpen
		if not (self.isServer and v6_.closeWhileFolding) then
			SpecializationUtil.removeEventListener(self, "onFoldStateChanged", CraneShovel)
			return
		end
	else
		SpecializationUtil.removeEventListener(self, "onPostLoad", CraneShovel)
		SpecializationUtil.removeEventListener(self, "onReadStream", CraneShovel)
		SpecializationUtil.removeEventListener(self, "onWriteStream", CraneShovel)
		SpecializationUtil.removeEventListener(self, "onFoldStateChanged", CraneShovel)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", CraneShovel)
	end
end

-- Local values: spec, state
function CraneShovel:onPostLoad(savegame)
	local v9_ = self.spec_craneShovel
	local v10_ = v9_.state
	if savegame ~= nil and not savegame.resetVehicles then
		v10_ = savegame.xmlFile:getValue(savegame.key .. ".craneShovel#state", v10_)
	end
	v9_.state = nil
	self:setCraneShovelState(v10_, true, true)
end

-- Local values: spec
function CraneShovel:saveToXMLFile(xmlFile, key, usedModNames)
	local v14_ = self.spec_craneShovel
	if v14_.animationName ~= nil then
		xmlFile:setValue(key .. "#state", v14_.state)
	end
end

-- Local values: state
function CraneShovel:onReadStream(streamId, connection)
	self:setCraneShovelState(streamReadBool(streamId), true, true)
end

-- Local values: spec
function CraneShovel:onWriteStream(streamId, connection)
	local v19_ = self.spec_craneShovel
	streamWriteBool(streamId, v19_.state)
end

-- Local values: spec
function CraneShovel:onFoldStateChanged(direction, moveToMiddle)
	if direction ~= self.spec_foldable.turnOnFoldDirection then
		local v22_ = self.spec_craneShovel
		if v22_.animationName ~= nil and v22_.state then
			self:setCraneShovelState(false)
		end
	end
end

-- Local values: spec, _, actionEventId
function CraneShovel:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	local v25_ = self.spec_craneShovel
	self:clearActionEventsTable(v25_.actionEvents)
	if isActiveForInputIgnoreSelection then
		local _, v26_ = self:addPoweredActionEvent(v25_.actionEvents, v25_.inputAction, self, CraneShovel.actionEvent, true, false, false, true, nil)
		g_inputBinding:setActionEventTextPriority(v26_, GS_PRIO_HIGH)
		CraneShovel.updateActionEvents(self)
	end
end

-- Local values: isAllowed, warning, spec
function CraneShovel:actionEvent(actionName, inputValue, callbackState, isAnalog)
	local v28_, v29_ = self:getCraneShovelStateChangedAllowed(self.spec_craneShovel)
	if v28_ then
		self:setCraneShovelState(not self.spec_craneShovel.state)
	elseif v29_ ~= nil then
		g_currentMission:showBlinkingWarning(v29_, 5000)
	end
end

-- Local values: spec, actionEvent
function CraneShovel:updateActionEvents()
	local v31_ = self.spec_craneShovel
	local v32_ = v31_.actionEvents[v31_.inputAction]
	if v32_ ~= nil then
		g_inputBinding:setActionEventText(v32_.actionEventId, v31_.state and v31_.texts.close or v31_.texts.open)
	end
end

-- Local values: inputActionName
function CraneShovel:loadCraneShovelFromXML(spec, xmlFile, key)
	spec.animationName = xmlFile:getValue(key .. "#animationName")
	if spec.animationName == nil then
		return false
	end
	local v37_ = xmlFile:getValue(key .. "#inputAction")
	spec.inputAction = InputAction[v37_]
	spec.animationSpeed = xmlFile:getValue(key .. "#animationSpeed", 1)
	spec.isDefaultOpen = xmlFile:getValue(key .. "#isDefaultOpen", false)
	spec.closeWhileFolding = xmlFile:getValue(key .. "#closeWhileFolding", false)
	spec.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", 1)
	spec.dischargeNodeIndex = xmlFile:getValue(key .. "#dischargeNodeIndex", 1)
	spec.texts = {}
	spec.texts.open = xmlFile:getValue(key .. ".texts#open", "action_craneShovelOpen", self.customEnvironment)
	spec.texts.close = xmlFile:getValue(key .. ".texts#close", "action_craneShovelClose", self.customEnvironment)
	return true
end

-- Local values: spec, currentTime, direction
function CraneShovel:setCraneShovelState(state, skipAnimation, noEventSend)
	local v42_ = self.spec_craneShovel
	if v42_.state ~= state then
		v42_.state = state
		local v43_ = self:getAnimationTime(v42_.animationName)
		self:stopAnimation(v42_.animationName, true)
		self:playAnimation(v42_.animationName, (state and 1 or -1) * v42_.animationSpeed, v43_, true)
		if skipAnimation then
			AnimatedVehicle.updateAnimationByName(self, v42_.animationName, 9999999, true)
		end
		if self.isClient and v42_.inputAction ~= nil then
			CraneShovel.updateActionEvents(self)
		end
	end
	CraneShovelEvent.sendEvent(self, v42_.state, noEventSend)
end

function CraneShovel:getCraneShovelStateChangedAllowed(spec)
	return true, nil
end

-- Local values: spec
function CraneShovel:getIsDischargeNodeActive(superFunc, dischargeNode)
	local v47_ = self.spec_craneShovel
	if v47_.animationName == nil or (v47_.dischargeNodeIndex == nil or (dischargeNode.index ~= v47_.dischargeNodeIndex or v47_.state)) then
		return superFunc(self, dischargeNode)
	else
		return false
	end
end

-- Local values: spec
function CraneShovel:getShovelNodeIsActive(superFunc, shovelNode)
	local v51_ = self.spec_craneShovel
	if v51_.animationName == nil then
		::l2::
		return superFunc(self, shovelNode)
	else
		if self:getIsAnimationPlaying(v51_.animationName) then
			local v52_ = self:getAnimationSpeed(v51_.animationName)
			if math.sign(v52_) ~= 1 then
				goto l2
			end
		end
		return false
	end
end
