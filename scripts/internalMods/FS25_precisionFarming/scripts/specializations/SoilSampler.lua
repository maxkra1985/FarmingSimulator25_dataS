SoilSampler = {}
SoilSampler.SPEC_NAME = g_currentModName .. ".soilSampler"
SoilSampler.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".soilSampler"
SoilSampler.SEND_NUM_BITS = 9

function SoilSampler.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function SoilSampler.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("SoilSampler")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.soilSampler#node", "Sampling Node")
	v2_:register(XMLValueType.FLOAT, "vehicle.soilSampler#radius", "Sampling radius", 10)
	v2_:register(XMLValueType.STRING, "vehicle.soilSampler#actionNameTake", "Take sample input action name", "IMPLEMENT_EXTRA")
	v2_:register(XMLValueType.STRING, "vehicle.soilSampler#actionNameSend", "Send sample input action name", "IMPLEMENT_EXTRA3")
	v2_:register(XMLValueType.STRING, "vehicle.soilSampler#animationName", "Sampling animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.soilSampler#animationSpeed", "Sampling animation speed", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.soilSampler#foldMinLimit", "Fold min. limit", 0)
	v2_:register(XMLValueType.FLOAT, "vehicle.soilSampler#foldMaxLimit", "Fold max. limit", 1)
	v2_:register(XMLValueType.STRING, "vehicle.soilSampler.samplesAnimation#name", "Samples animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.soilSampler.samplesAnimation#speed", "Samples animation speed", 1)
	v2_:register(XMLValueType.INT, "vehicle.soilSampler.samplesAnimation#minSamples", "Min. samples", 0)
	v2_:register(XMLValueType.INT, "vehicle.soilSampler.samplesAnimation#maxSamples", "Max. samples", 0)
	v2_:register(XMLValueType.FLOAT, "vehicle.soilSampler.visualSamples#updateTime", "Update time", 0.5)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.soilSampler.visualSamples.visualSample(?)#node", "Visual sample node")
	v2_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)." .. SoilSampler.SPEC_NAME .. "#numCollectedSamples", "Num collected samples")
end

function SoilSampler.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "startSoilSampling", SoilSampler.startSoilSampling)
	SpecializationUtil.registerFunction(vehicleType, "setNumCollectedSoilSamples", SoilSampler.setNumCollectedSoilSamples)
	SpecializationUtil.registerFunction(vehicleType, "getNormalizedSampleIndex", SoilSampler.getNormalizedSampleIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCanStartSoilSampling", SoilSampler.getCanStartSoilSampling)
	SpecializationUtil.registerFunction(vehicleType, "processSoilSampling", SoilSampler.processSoilSampling)
	SpecializationUtil.registerFunction(vehicleType, "sendTakenSoilSamples", SoilSampler.sendTakenSoilSamples)
end

function SoilSampler.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SoilSampler.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", SoilSampler.getIsFoldAllowed)
end

function SoilSampler.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SoilSampler)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", SoilSampler)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SoilSampler)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SoilSampler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SoilSampler)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", SoilSampler)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveRootVehicle", SoilSampler)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", SoilSampler)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SoilSampler)
end

-- Local values: spec, baseName, actionNameTake, actionNameSend, i, visualSampleKey, node
function SoilSampler:onLoad(savegame)
	local v7_ = self[SoilSampler.SPEC_TABLE_NAME]
	v7_.samplingNode = self.xmlFile:getValue("vehicle.soilSampler#node", nil, self.components, self.i3dMappings)
	v7_.samplingRadius = self.xmlFile:getValue("vehicle.soilSampler#radius", 10)
	v7_.densityMapCircle = DensityMapCircle.new()
	local v8_ = self.xmlFile:getValue("vehicle.soilSampler#actionNameTake", "IMPLEMENT_EXTRA")
	v7_.inputActionTake = InputAction[v8_] or InputAction.IMPLEMENT_EXTRA
	local v9_ = self.xmlFile:getValue("vehicle.soilSampler#actionNameSend", "IMPLEMENT_EXTRA3")
	v7_.inputActionSend = InputAction[v9_] or InputAction.IMPLEMENT_EXTRA
	v7_.isSampling = false
	v7_.animationName = self.xmlFile:getValue("vehicle.soilSampler#animationName")
	v7_.animationSpeed = self.xmlFile:getValue("vehicle.soilSampler#animationSpeed", 1)
	v7_.numCollectedSamples = 0
	v7_.foldMinLimit = self.xmlFile:getValue("vehicle.soilSampler#foldMinLimit", 0)
	v7_.foldMaxLimit = self.xmlFile:getValue("vehicle.soilSampler#foldMaxLimit", 1)
	v7_.samplesAnimation = {}
	v7_.samplesAnimation.name = self.xmlFile:getValue("vehicle.soilSampler.samplesAnimation#name")
	v7_.samplesAnimation.speed = self.xmlFile:getValue("vehicle.soilSampler.samplesAnimation#speed", 1)
	v7_.samplesAnimation.minSamples = self.xmlFile:getValue("vehicle.soilSampler.samplesAnimation#minSamples", 0)
	v7_.samplesAnimation.maxSamples = self.xmlFile:getValue("vehicle.soilSampler.samplesAnimation#maxSamples", 0)
	v7_.visualSampleUpdateTime = self.xmlFile:getValue("vehicle.soilSampler.visualSamples#updateTime", 0.5)
	v7_.visualSampleUpdated = true
	v7_.visualSamples = {}
	local v10_ = 0
	while true do
		local v11_ = string.format("%s.visualSamples.visualSample(%d)", "vehicle.soilSampler", v10_)
		if not self.xmlFile:hasProperty(v11_) then
			break
		end
		local v12_ = self.xmlFile:getValue(v11_ .. "#node", nil, self.components, self.i3dMappings)
		if v12_ ~= nil then
			setVisibility(v12_, false)
			local v13_ = v7_.visualSamples
			table.insert(v13_, v12_)
		end
		v10_ = v10_ + 1
	end
	v7_.texts = {}
	v7_.texts.takeSample = g_i18n:getText("action_takeSoilSample", self.customEnvironment)
	v7_.texts.sendSoilSamples = g_i18n:getText("action_sendSoilSamples", self.customEnvironment)
	v7_.texts.numSamplesTaken = g_i18n:getText("info_numSamplesTaken", self.customEnvironment)
	v7_.texts.infoSamplesSend = g_i18n:getText("info_samplesSend", self.customEnvironment)
	if g_precisionFarming ~= nil then
		v7_.soilMap = g_precisionFarming.soilMap
		v7_.coverMap = g_precisionFarming.coverMap
		v7_.farmlandStatistics = g_precisionFarming.farmlandStatistics
	end
end

-- Local values: spec, numSamples
function SoilSampler:onPostLoad(savegame)
	local v16_ = self[SoilSampler.SPEC_TABLE_NAME]
	if savegame ~= nil and not savegame.resetVehicles then
		self:setNumCollectedSoilSamples(savegame.xmlFile:getValue(savegame.key .. "." .. SoilSampler.SPEC_NAME .. "#numCollectedSamples", v16_.numCollectedSamples), true)
	end
end

-- Local values: spec
function SoilSampler:saveToXMLFile(xmlFile, key, usedModNames)
	local v20_ = self[SoilSampler.SPEC_TABLE_NAME]
	xmlFile:setValue(key .. "#numCollectedSamples", v20_.numCollectedSamples)
end

-- Local values: spec, numSamples
function SoilSampler:onReadStream(streamId, connection)
	local v23_ = self[SoilSampler.SPEC_TABLE_NAME]
	self:setNumCollectedSoilSamples(streamReadUIntN(streamId, SoilSampler.SEND_NUM_BITS) or v23_.numCollectedSamples, true)
end

-- Local values: spec
function SoilSampler:onWriteStream(streamId, connection)
	local v26_ = self[SoilSampler.SPEC_TABLE_NAME]
	streamWriteUIntN(streamId, v26_.numCollectedSamples, SoilSampler.SEND_NUM_BITS)
end

-- Local values: spec, sampleIndex, i
function SoilSampler:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v29_ = self[SoilSampler.SPEC_TABLE_NAME]
	if v29_.isSampling then
		if self.isClient and (not v29_.visualSampleUpdated and self:getAnimationTime(v29_.animationName) >= v29_.visualSampleUpdateTime) then
			local v30_ = self:getNormalizedSampleIndex()
			for v31_ = 1, #v29_.visualSamples do
				setVisibility(v29_.visualSamples[v31_], v31_ <= v30_)
			end
			v29_.visualSampleUpdated = false
		end
		if not self:getIsAnimationPlaying(v29_.animationName) then
			v29_.isSampling = false
			self:setAnimationTime(v29_.animationName, 0, false)
			if v29_.soilMap:getMinimapAdditionalElementLinkNode() == v29_.samplingNode then
				v29_.soilMap:setMinimapSamplingState(false)
			end
			self:processSoilSampling()
			self.speedLimit = math.huge
		end
	end
	if isActiveForInputIgnoreSelection and v29_.numCollectedSamples > 0 then
		g_currentMission:addExtraPrintText(string.format(v29_.texts.numSamplesTaken, v29_.numCollectedSamples))
	end
end

-- Local values: spec
function SoilSampler:onFoldStateChanged(direction, moveToMiddle)
	local v34_ = self[SoilSampler.SPEC_TABLE_NAME]
	if self:getIsActiveForInput(true) then
		v34_.soilMap:setRequireMinimapDisplay(direction == 1, self, self:getIsSelected())
	end
end

-- Local values: spec
function SoilSampler:onLeaveRootVehicle()
	local v36_ = self[SoilSampler.SPEC_TABLE_NAME]
	if v36_.soilMap:getMinimapAdditionalElementLinkNode() == v36_.samplingNode then
		v36_.soilMap:setRequireMinimapDisplay(false, self)
		v36_.soilMap:setMinimapAdditionalElementLinkNode(nil)
		v36_.soilMap:setMinimapSamplingState(false)
	end
end

-- Local values: spec
function SoilSampler:onPreDetach()
	local v38_ = self[SoilSampler.SPEC_TABLE_NAME]
	if v38_.soilMap:getMinimapAdditionalElementLinkNode() == v38_.samplingNode then
		v38_.soilMap:setRequireMinimapDisplay(false, self)
		v38_.soilMap:setMinimapAdditionalElementLinkNode(nil)
		v38_.soilMap:setMinimapSamplingState(false)
	end
end

-- Local values: spec, attacherVehicle, jointDesc, jointDescIndex, _, isOnField, _, i, sampleIndex, stopTime
function SoilSampler:startSoilSampling(noEventSend)
	local v41_ = self[SoilSampler.SPEC_TABLE_NAME]
	v41_.isSampling = true
	if self.isServer then
		if not self:getIsLowered(false) then
			local v42_ = self:getAttacherVehicle()
			if v42_ ~= nil and v42_:getAttacherJointDescFromObject(self).allowsLowering then
				v42_:setJointMoveDown(v42_:getAttacherJointIndexFromObject(self), true, false)
			end
		end
		local _, v43_, _ = self:getPFStatisticInfo()
		if v43_ then
			self:updatePFStatistic("numSoilSamples", 1)
			self:updatePFStatistic("soilSampleCosts", v41_.soilMap:getPricePerSoilSample())
		end
		self.speedLimit = 0
	end
	self:playAnimation(v41_.animationName, v41_.animationSpeed, self:getAnimationTime(v41_.animationName), true)
	self:setNumCollectedSoilSamples(v41_.numCollectedSamples + 1, false)
	if self:getIsActiveForInput(true) then
		v41_.soilMap:setMinimapSamplingState(true)
	end
	if self.isClient then
		if (v41_.numCollectedSamples - 1) % #v41_.visualSamples == 0 then
			for v44_ = 1, #v41_.visualSamples do
				setVisibility(v41_.visualSamples[v44_], false)
			end
			self:playAnimation(v41_.samplesAnimation.name, -v41_.samplesAnimation.speed, self:getAnimationTime(v41_.samplesAnimation.name), true)
		else
			local v45_ = (self:getNormalizedSampleIndex() - v41_.samplesAnimation.minSamples) / (v41_.samplesAnimation.maxSamples - v41_.samplesAnimation.minSamples)
			if self:getAnimationTime(v41_.samplesAnimation.name) < v45_ then
				self:setAnimationStopTime(v41_.samplesAnimation.name, v45_)
				self:playAnimation(v41_.samplesAnimation.name, v41_.samplesAnimation.speed, self:getAnimationTime(v41_.samplesAnimation.name), true)
			end
		end
		v41_.visualSampleUpdated = false
	end
	SoilSampler.updateActionEventState(self)
	SoilSamplerStartEvent.sendEvent(self, noEventSend)
end

-- Local values: spec, sampleIndex, j, stopTime
function SoilSampler:setNumCollectedSoilSamples(num, updateVisuals)
	local v49_ = self[SoilSampler.SPEC_TABLE_NAME]
	v49_.numCollectedSamples = num or v49_.numCollectedSamples + 1
	if updateVisuals then
		local v50_ = self:getNormalizedSampleIndex()
		for v51_ = 1, #v49_.visualSamples do
			setVisibility(v49_.visualSamples[v51_], v51_ <= v50_)
		end
		local v52_ = (v50_ - v49_.samplesAnimation.minSamples) / (v49_.samplesAnimation.maxSamples - v49_.samplesAnimation.minSamples)
		self:setAnimationTime(v49_.samplesAnimation.name, v52_, true)
	end
end

-- Local values: spec, sampleIndex
function SoilSampler:getNormalizedSampleIndex()
	local v54_ = self[SoilSampler.SPEC_TABLE_NAME]
	local v55_ = v54_.numCollectedSamples % #v54_.visualSamples
	return v54_.numCollectedSamples == 0 and 0 or (v55_ == 0 and #v54_.visualSamples or v55_)
end

-- Local values: spec, x, _, z, farmlandId, landOwner, accessible, rootAttacherVehicle, time
function SoilSampler:getCanStartSoilSampling()
	local v57_ = self[SoilSampler.SPEC_TABLE_NAME]
	local v58_, _, v59_ = getWorldTranslation(v57_.samplingNode)
	local v60_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v58_, v59_)
	if v60_ == nil then
		return false, g_i18n:getText("warning_youDontHaveAccessToThisLand")
	end
	local v61_ = g_farmlandManager:getFarmlandOwner(v60_)
	local v62_
	if v61_ == 0 then
		v62_ = false
	else
		v62_ = g_currentMission.accessHandler:canFarmAccessOtherId(self:getActiveFarm(), v61_)
	end
	if not v62_ then
		return false, g_i18n:getText("warning_youDontHaveAccessToThisLand")
	end
	if self.getIsMotorStarted == nil then
		local v63_ = self:getRootVehicle()
		if v63_ ~= self and (v63_.getIsMotorStarted ~= nil and not v63_:getIsMotorStarted()) then
			return false, g_i18n:getText("warning_motorNotStarted")
		end
	elseif not self:getIsMotorStarted() then
		return false, g_i18n:getText("warning_motorNotStarted")
	end
	if self.getFoldAnimTime ~= nil then
		local v64_ = self:getFoldAnimTime()
		if v57_.foldMaxLimit < v64_ or v64_ < v57_.foldMinLimit then
			return false, self.spec_foldable.unfoldWarning
		end
	end
	return not self[SoilSampler.SPEC_TABLE_NAME].isSampling
end

-- Local values: spec, worldX, _, worldZ
function SoilSampler:processSoilSampling()
	if self.isServer then
		local v66_ = self[SoilSampler.SPEC_TABLE_NAME]
		if v66_.soilMap ~= nil then
			local v67_, _, v68_ = getWorldTranslation(v66_.samplingNode)
			v66_.densityMapCircle:updateFromWorldPosition(v67_, v68_, v66_.samplingRadius, 20)
			v66_.coverMap:analyseArea(v66_.densityMapCircle, nil, self:getOwnerFarmId())
		end
	end
end

-- Local values: spec, i
function SoilSampler:sendTakenSoilSamples(noEventSend)
	local v71_ = self[SoilSampler.SPEC_TABLE_NAME]
	if self.isServer and v71_.soilMap ~= nil then
		v71_.soilMap:analyseSoilSamples(self:getOwnerFarmId(), v71_.numCollectedSamples)
	end
	if self.isClient then
		for v72_ = 1, #v71_.visualSamples do
			setVisibility(v71_.visualSamples[v72_], false)
		end
		self:playAnimation(v71_.samplesAnimation.name, -v71_.samplesAnimation.speed, self:getAnimationTime(v71_.samplesAnimation.name), true)
	end
	v71_.numCollectedSamples = 0
	SoilSampler.updateActionEventState(self)
	SoilSamplerSendEvent.sendEvent(self, noEventSend)
end

-- Local values: spec, _, actionEventId
function SoilSampler:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v75_ = self[SoilSampler.SPEC_TABLE_NAME]
		self:clearActionEventsTable(v75_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v76_ = self:addActionEvent(v75_.actionEvents, v75_.inputActionTake, self, SoilSampler.actionEventStartSample, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v76_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventText(v76_, v75_.texts.takeSample)
			local _, v77_ = self:addActionEvent(v75_.actionEvents, v75_.inputActionSend, self, SoilSampler.actionEventSendSamples, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v77_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventText(v77_, v75_.texts.sendSoilSamples)
			SoilSampler.updateActionEventState(self)
			v75_.soilMap:setRequireMinimapDisplay(self:getFoldAnimTime() > 0, self, self:getIsSelected())
			v75_.soilMap:setMinimapAdditionalElementLinkNode(v75_.samplingNode)
			v75_.soilMap:setMinimapAdditionalElementRealSize(v75_.samplingRadius * 2, v75_.samplingRadius * 2)
		end
	end
end

-- Local values: spec, actionEventSend
function SoilSampler:updateActionEventState()
	local v79_ = self[SoilSampler.SPEC_TABLE_NAME]
	local v80_ = v79_.actionEvents[v79_.inputActionSend]
	if v80_ ~= nil then
		g_inputBinding:setActionEventActive(v80_.actionEventId, v79_.numCollectedSamples > 0)
	end
end

-- Local values: canStart, warning
function SoilSampler:actionEventStartSample(actionName, inputValue, callbackState, isAnalog)
	local v82_, v83_ = self:getCanStartSoilSampling()
	if v82_ then
		self:startSoilSampling()
	elseif v83_ ~= nil then
		g_currentMission:showBlinkingWarning(v83_, 2000)
	end
end

-- Local values: spec
function SoilSampler:actionEventSendSamples(actionName, inputValue, callbackState, isAnalog)
	local v85_ = self[SoilSampler.SPEC_TABLE_NAME]
	if v85_.numCollectedSamples > 0 and not v85_.isSampling then
		InfoDialog.show(v85_.texts.infoSamplesSend, SoilSampler.onSendSoilSamplesDialog, self)
	end
end

-- Local values: spec
function SoilSampler:onSendSoilSamplesDialog()
	local v87_ = self[SoilSampler.SPEC_TABLE_NAME]
	if v87_.soilMap ~= nil then
		v87_.soilMap:sendSoilSamplesByFarm(self:getOwnerFarmId())
	end
end

function SoilSampler:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self[SoilSampler.SPEC_TABLE_NAME].isSampling
end

function SoilSampler:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v94_ = not self[SoilSampler.SPEC_TABLE_NAME].isSampling
	if v94_ then
		v94_ = superFunc(self, direction, onAiTurnOn)
	end
	return v94_
end
