source("dataS/scripts/vehicles/specializations/events/TrailerToggleTipSideEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TrailerToggleManualTipEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TrailerToggleManualDoorEvent.lua")
Trailer = {}
Trailer.TIPSTATE_CLOSED = 0
Trailer.TIPSTATE_OPENING = 1
Trailer.TIPSTATE_OPEN = 2
Trailer.TIPSTATE_CLOSING = 3
Trailer.TIP_SIDE_NUM_BITS = 3
Trailer.TIP_STATE_NUM_BITS = 2

function Trailer.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
	return v2_
end
function Trailer.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("trailer", g_i18n:getText("configuration_trailer"), "trailer", VehicleConfigurationItem)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Trailer")
	v3_:register(XMLValueType.L10N_STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer#infoText", "Info text", "action_toggleTipSide")
	v3_:register(XMLValueType.STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?)#name", "Tip side name")
	v3_:register(XMLValueType.INT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?)#dischargeNodeIndex", "Discharge node index")
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?)#canTipIfEmpty", "Can tip if empty", true)
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?)#canTip", "Can tip (if false, only back door control is allowed)", true)
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualTipToggle#enabled", "Tip animation can be toggled manually without dischargeable", false)
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualTipToggle#stopOnDeactivate", "Stop manual tipping while vehicle is deactivated (detached, exited etc)", true)
	v3_:register(XMLValueType.STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualTipToggle#inputAction", "Input action to toggle tipping", "IMPLEMENT_EXTRA4")
	v3_:register(XMLValueType.L10N_STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualTipToggle#inputActionTextPos", "Positive input text to display", "action_startTipping")
	v3_:register(XMLValueType.L10N_STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualTipToggle#inputActionTextNeg", "Negative input text to display", "action_stopTipping")
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualDoorToggle#enabled", "Door animation can be toggled manually without dischargeable", false)
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualDoorToggle#openWhileTipping", "Still automatically open the door while tipping", false)
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualDoorToggle#resetWhileTipping", "Snap the door back to closed instantly when starting to tip", false)
	v3_:register(XMLValueType.STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualDoorToggle#inputAction", "Input action to toggle tipping", "IMPLEMENT_EXTRA3")
	v3_:register(XMLValueType.L10N_STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualDoorToggle#inputActionTextPos", "Positive input text to display", "action_openBackDoor")
	v3_:register(XMLValueType.L10N_STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualDoorToggle#inputActionTextNeg", "Negative input text to display", "action_closeBackDoor")
	v3_:register(XMLValueType.INT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualDoorToggle.fillUnit#index", "Reference fill unit index for fill level detection")
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).manualDoorToggle.fillUnit#allowWhileFilled", "Allow manual door opening when fill unit is filled", true)
	v3_:register(XMLValueType.STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).animation#name", "Tip animation name")
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).animation#speedScale", "Tip animation speed scale", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).animation#closeSpeedScale", "Tip animation speed scale while stopping to tip", "inversed speed scale")
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).animation#startTipTime", "Tip animation start tip time", 0)
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).animation#resetTipSideChange", "Reset tip animation to zero while tip side is activated", false)
	v3_:register(XMLValueType.STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).doorAnimation#name", "Door animation name")
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).doorAnimation#speedScale", "Door animation speed scale", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).doorAnimation#closeSpeedScale", "Door animation speed scale while stopping to tip", "inversed speed scale")
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).doorAnimation#startTipTime", "Door animation start tip time", 0)
	v3_:register(XMLValueType.BOOL, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).doorAnimation#delayedClosing", "Play door animation after tip animation while closing", false)
	v3_:register(XMLValueType.STRING, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).tippingAnimation#name", "Tipping animation name (continuously played while tipping)")
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).tippingAnimation#speedScale", "Tipping animation speed scale", 1)
	v3_:register(XMLValueType.INT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).fillLevel#fillUnitIndex", "Fill unit index to check")
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).fillLevel#minFillLevelPct", "Min. trailer fill level pct to select tip side", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).fillLevel#maxFillLevelPct", "Max. trailer fill level pct to select tip side", 1)
	AnimationManager.registerAnimationNodesXMLPaths(v3_, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?).animationNodes")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v3_, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?)")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?)", "unloadSound")
	v3_:addDelayedRegistrationFunc("AnimatedVehicle:part", function(p4_, p5_)
		p4_:register(XMLValueType.FLOAT, p5_ .. "#startTipSideEmptyFactor", "Start tip side empty factor")
		p4_:register(XMLValueType.FLOAT, p5_ .. "#endTipSideEmptyFactor", "End tip side empty factor")
		p4_:register(XMLValueType.FLOAT, p5_ .. "#startDoorAnimationMaxTime", "Max. time of door animation")
		p4_:register(XMLValueType.FLOAT, p5_ .. "#endDoorAnimationMaxTime", "Max. time of door animation")
	end)
	v3_:addDelayedRegistrationFunc("ExternalVehicleControl:function", function(p6_, p7_)
		p6_:register(XMLValueType.INT, p7_ .. ".trailer#tipSideIndex", "Index of tip side to control")
	end)
	v3_:register(XMLValueType.BOOL, Pickup.PICKUP_XML_KEY .. "#allowWhileTipping", "Allow pickup movement while tipping", true)
	v3_:register(XMLValueType.BOOL, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#playWhileTipping", "Animation is active while tipping", false)
	v3_:setXMLSpecializationType()
	local v8_ = Vehicle.xmlSchemaSavegame
	v8_:register(XMLValueType.INT, "vehicles.vehicle(?).trailer#tipSideIndex", "Current tip side index")
	v8_:register(XMLValueType.BOOL, "vehicles.vehicle(?).trailer#doorState", "Current back door state")
	v8_:register(XMLValueType.INT, "vehicles.vehicle(?).trailer#tipState", "Current tip state")
	v8_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).trailer#tipAnimationTime", "Current tip animation time")
end

function Trailer.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onStartTipping")
	SpecializationUtil.registerEvent(vehicleType, "onOpenBackDoor")
	SpecializationUtil.registerEvent(vehicleType, "onStopTipping")
	SpecializationUtil.registerEvent(vehicleType, "onCloseBackDoor")
	SpecializationUtil.registerEvent(vehicleType, "onEndTipping")
end

function Trailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadTipSide", Trailer.loadTipSide)
	SpecializationUtil.registerFunction(vehicleType, "getCanTogglePreferdTipSide", Trailer.getCanTogglePreferdTipSide)
	SpecializationUtil.registerFunction(vehicleType, "getIsTipSideAvailable", Trailer.getIsTipSideAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getNextAvailableTipSide", Trailer.getNextAvailableTipSide)
	SpecializationUtil.registerFunction(vehicleType, "setPreferedTipSide", Trailer.setPreferedTipSide)
	SpecializationUtil.registerFunction(vehicleType, "setTipSideUpdateDirty", Trailer.setTipSideUpdateDirty)
	SpecializationUtil.registerFunction(vehicleType, "startTipping", Trailer.startTipping)
	SpecializationUtil.registerFunction(vehicleType, "stopTipping", Trailer.stopTipping)
	SpecializationUtil.registerFunction(vehicleType, "endTipping", Trailer.endTipping)
	SpecializationUtil.registerFunction(vehicleType, "setTrailerDoorState", Trailer.setTrailerDoorState)
	SpecializationUtil.registerFunction(vehicleType, "getAllowTrailerDoorToggle", Trailer.getAllowTrailerDoorToggle)
	SpecializationUtil.registerFunction(vehicleType, "getTipState", Trailer.getTipState)
	SpecializationUtil.registerFunction(vehicleType, "setTipState", Trailer.setTipState)
	SpecializationUtil.registerFunction(vehicleType, "updateTrailerAutomaticRedischarge", Trailer.updateTrailerAutomaticRedischarge)
end

function Trailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", Trailer.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", Trailer.getCanDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToObject", Trailer.getCanDischargeToObject)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsNextCoverStateAllowed", Trailer.getIsNextCoverStateAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Trailer.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIHasFinishedDischarge", Trailer.getAIHasFinishedDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "startAIDischarge", Trailer.startAIDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPickupFromXML", Trailer.loadPickupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanChangePickupState", Trailer.getCanChangePickupState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsTurnedOnAnimationActive", Trailer.getIsTurnedOnAnimationActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadTurnedOnAnimationFromXML", Trailer.loadTurnedOnAnimationFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", Trailer.getRequiresPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setManualDischargeState", Trailer.setManualDischargeState)
end

function Trailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Trailer)
end

-- Local values: spec, trailerConfigurationId, configKey, i, key, entry
function Trailer:onLoad(savegame)
	local v14_ = self.spec_trailer
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.tipScrollerNodes.tipScrollerNode", "vehicle.trailer.trailerConfigurations.trailerConfiguration.trailer.tipSide.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.tipRotationNodes.tipRotationNode", "vehicle.trailer.trailerConfigurations.trailerConfiguration.trailer.tipSide.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.tipAnimations.tipAnimation", "vehicle.trailer.trailerConfigurations.trailerConfiguration.trailer.tipSide")
	local v15_ = Utils.getNoNil(self.configurations.trailer, 1)
	local v16_ = string.format("vehicle.trailer.trailerConfigurations.trailerConfiguration(%d).trailer", v15_ - 1)
	v14_.fillLevelDependentTipSides = false
	v14_.tipSideUpdateDirty = false
	v14_.tipSides = {}
	v14_.dischargeNodeIndexToTipSide = {}
	local v17_ = 0
	while true do
		local v18_ = string.format("%s.tipSide(%d)", v16_, v17_)
		if not self.xmlFile:hasProperty(v18_) then
			break
		end
		local v19_ = {}
		if self:loadTipSide(self.xmlFile, v18_, v19_) then
			local v20_ = v14_.tipSides
			table.insert(v20_, v19_)
			v19_.index = #v14_.tipSides
			if v19_.dischargeNodeIndex ~= nil then
				v14_.dischargeNodeIndexToTipSide[v19_.dischargeNodeIndex] = v19_
			end
		end
		v17_ = v17_ + 1
	end
	v14_.infoText = self.xmlFile:getValue(v16_ .. "#infoText", "action_toggleTipSide", self.customEnvironment, false)
	v14_.tipSideCount = #v14_.tipSides
	v14_.preferedTipSideIndex = 1
	v14_.currentTipSideIndex = nil
	v14_.tipState = Trailer.TIPSTATE_CLOSED
	v14_.remainingFillDelta = 0
	v14_.redischarge = {}
	v14_.redischarge.isDisabled = false
	v14_.redischarge.dischargeObject = nil
	v14_.redischarge.dischargeNodeLastPos = { 0, 0, 0 }
	v14_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, tipSideIndex, tipSide, tipSideIndex, doorState, tipAnimationTime, tipSide
function Trailer:onPostLoad(savegame)
	local v23_ = self.spec_trailer
	for v24_, v25_ in ipairs(v23_.tipSides) do
		if v25_.dischargeNodeIndex ~= nil and self:getDischargeNodeByIndex(v25_.dischargeNodeIndex) == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown dischargeNodeIndex \'%s\' for tipSide index \'%s\'", v25_.dischargeNodeIndex, v24_)
		end
	end
	if savegame == nil then
		if v23_.tipSideCount > 0 then
			self:setPreferedTipSide(v23_.preferedTipSideIndex, true)
		end
	elseif v23_.tipSideCount > 0 then
		if v23_.tipSideCount > 1 then
			local v26_ = savegame.xmlFile:getValue(savegame.key .. ".trailer#tipSideIndex")
			if v26_ ~= nil then
				self:setPreferedTipSide(v26_, true)
			end
		end
		local v27_ = savegame.xmlFile:getValue(savegame.key .. ".trailer#doorState")
		if v27_ ~= nil then
			self:setTrailerDoorState(v23_.preferedTipSideIndex, v27_, true, true)
		end
		v23_.tipState = savegame.xmlFile:getValue(savegame.key .. ".trailer#tipState", v23_.tipState)
		if v23_.tipState == Trailer.TIPSTATE_OPENING or v23_.tipState == Trailer.TIPSTATE_OPEN then
			v23_.currentTipSideIndex = v23_.preferedTipSideIndex
			self:setTipState(true)
		end
		local v28_ = savegame.xmlFile:getValue(savegame.key .. ".trailer#tipAnimationTime")
		if v28_ ~= nil then
			self:setAnimationTime(v23_.tipSides[v23_.preferedTipSideIndex].animation.name, v28_, true, false)
			return
		end
	end
end

-- Local values: spec
function Trailer:onLoadFinished(savegame)
	local v30_ = self.spec_trailer
	if v30_.tipSideCount > 1 and not self:getIsTipSideAvailable(v30_.preferedTipSideIndex) then
		self:setTipSideUpdateDirty()
	end
end

-- Local values: spec, _, tipSide
function Trailer:onDelete()
	local v32_ = self.spec_trailer
	if v32_.tipSides ~= nil then
		for _, v33_ in ipairs(v32_.tipSides) do
			g_animationManager:deleteAnimations(v33_.animationNodes)
			g_soundManager:deleteSample(v33_.unloadSound)
		end
	end
end

-- Local values: spec, doorState, tipSide, tipAnimationTime, tipSide, doorAnimationTime
function Trailer:onReadStream(streamId, connection)
	local v36_ = self.spec_trailer
	if v36_.tipSideCount > 1 then
		self:setPreferedTipSide(streamReadUIntN(streamId, Trailer.TIP_SIDE_NUM_BITS), true)
	end
	v36_.tipState = streamReadUIntN(streamId, Trailer.TIP_STATE_NUM_BITS)
	if streamReadBool(streamId) then
		v36_.currentTipSideIndex = streamReadUIntN(streamId, Trailer.TIP_SIDE_NUM_BITS)
	end
	if streamReadBool(streamId) then
		local v37_ = streamReadBool(streamId)
		self:setTrailerDoorState(v36_.preferedTipSideIndex, v37_, true, true)
	end
	if streamReadBool(streamId) then
		local v38_ = v36_.tipSides[v36_.preferedTipSideIndex]
		local v39_ = streamReadFloat32(streamId)
		if v39_ ~= nil then
			self:setAnimationTime(v38_.animation.name, v39_, true, false)
		end
		if streamReadBool(streamId) then
			if streamReadBool(streamId) then
				self:playAnimation(v38_.animation.name, v38_.animation.speedScale, v39_, true)
			else
				self:playAnimation(v38_.animation.name, v38_.animation.closeSpeedScale, v39_, true)
			end
		end
	end
	if streamReadBool(streamId) then
		local v40_ = v36_.tipSides[v36_.preferedTipSideIndex]
		local v41_ = streamReadFloat32(streamId)
		if v41_ ~= nil then
			self:setAnimationTime(v40_.doorAnimation.name, v41_, true, false)
		end
		if streamReadBool(streamId) then
			if streamReadBool(streamId) then
				self:setAnimationStopTime(v40_.doorAnimation.name, v40_.doorAnimation.maxTime)
				self:playAnimation(v40_.doorAnimation.name, v40_.doorAnimation.speedScale, v41_, true)
				return
			end
			self:playAnimation(v40_.doorAnimation.name, v40_.doorAnimation.closeSpeedScale, v41_, true)
		end
	end
end

-- Local values: spec, tipSide
function Trailer:onWriteStream(streamId, connection)
	local v44_ = self.spec_trailer
	if v44_.tipSideCount > 1 then
		streamWriteUIntN(streamId, v44_.preferedTipSideIndex, Trailer.TIP_SIDE_NUM_BITS)
	end
	streamWriteUIntN(streamId, v44_.tipState, Trailer.TIP_STATE_NUM_BITS)
	if streamWriteBool(streamId, v44_.currentTipSideIndex ~= nil) then
		streamWriteUIntN(streamId, v44_.currentTipSideIndex, Trailer.TIP_SIDE_NUM_BITS)
	end
	local v45_ = v44_.tipSides[v44_.preferedTipSideIndex]
	local v46_ = streamWriteBool
	local v47_
	if v45_ == nil then
		v47_ = false
	else
		v47_ = v45_.manualDoorToggle
	end
	if v46_(streamId, v47_) then
		streamWriteBool(streamId, v45_.doorAnimation.state)
	end
	local v48_ = streamWriteBool
	local v49_
	if v45_ == nil then
		v49_ = false
	else
		v49_ = v45_.animation.name ~= nil
	end
	if v48_(streamId, v49_) then
		streamWriteFloat32(streamId, self:getAnimationTime(v45_.animation.name))
		if streamWriteBool(streamId, self:getIsAnimationPlaying(v45_.animation.name)) then
			streamWriteBool(streamId, self:getAnimationSpeed(v45_.animation.name) > 0)
		end
	end
	local v50_ = streamWriteBool
	local v51_ = v45_ ~= nil and not v45_.manualDoorToggle
	if v51_ then
		v51_ = v45_.doorAnimation.name ~= nil
	end
	if v50_(streamId, v51_) then
		streamWriteFloat32(streamId, self:getAnimationTime(v45_.doorAnimation.name))
		if streamWriteBool(streamId, self:getIsAnimationPlaying(v45_.doorAnimation.name)) then
			streamWriteBool(streamId, self:getAnimationSpeed(v45_.doorAnimation.name) > 0)
		end
	end
end

-- Local values: spec, actionEvent, state, text, tipState, tipSide, actionEvent, text, tipState, actionEvent, text
function Trailer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v53_ = self.spec_trailer
	if v53_.tipSideCount > 1 then
		local v54_ = v53_.actionEvents[InputAction.TOGGLE_TIPSIDE]
		if v54_ ~= nil then
			local v55_ = self:getCanTogglePreferdTipSide()
			g_inputBinding:setActionEventActive(v54_.actionEventId, v55_)
			if v55_ then
				local v56_ = string.format(v53_.infoText, v53_.tipSides[v53_.preferedTipSideIndex].name)
				g_inputBinding:setActionEventText(v54_.actionEventId, v56_)
			end
		end
		if v53_.tipSideUpdateDirty and self:getTipState() == Trailer.TIPSTATE_CLOSED then
			self:setPreferedTipSide(self:getNextAvailableTipSide(v53_.preferedTipSideIndex), true)
			v53_.tipSideUpdateDirty = false
		end
	end
	local v57_ = v53_.tipSides[v53_.preferedTipSideIndex]
	if v57_ ~= nil then
		if v57_.manualTipToggle then
			local v58_ = v53_.actionEvents[v57_.manualTipToggleAction]
			if v58_ ~= nil then
				local v59_ = self:getTipState()
				local v60_
				if v59_ == Trailer.TIPSTATE_CLOSED or v59_ == Trailer.TIPSTATE_CLOSING then
					v60_ = v57_.manualTipToggleActionTextPos
				else
					v60_ = v57_.manualTipToggleActionTextNeg
				end
				g_inputBinding:setActionEventText(v58_.actionEventId, v60_)
			end
		end
		if v57_.manualDoorToggle then
			local v61_ = v53_.actionEvents[v57_.manualDoorToggleAction]
			if v61_ ~= nil then
				local v62_
				if self:getIsAnimationPlaying(v57_.doorAnimation.name) then
					if self:getAnimationSpeed(v57_.doorAnimation.name) > 0 then
						v62_ = v57_.manualDoorToggleActionTextNeg
					else
						v62_ = v57_.manualDoorToggleActionTextPos
					end
				elseif self:getAnimationTime(v57_.doorAnimation.name) <= 0 then
					v62_ = v57_.manualDoorToggleActionTextPos
				else
					v62_ = v57_.manualDoorToggleActionTextNeg
				end
				g_inputBinding:setActionEventText(v61_.actionEventId, v62_)
			end
		end
	end
	if v53_.tipState == Trailer.TIPSTATE_OPENING then
		local v63_ = v53_.tipSides[v53_.currentTipSideIndex]
		if v63_ ~= nil and (self:getAnimationTime(v63_.animation.name) >= 1 or self:getAnimationDuration(v63_.animation.name) == 0) then
			v53_.tipState = Trailer.TIPSTATE_OPEN
		end
	elseif v53_.tipState == Trailer.TIPSTATE_CLOSING then
		local v64_ = v53_.tipSides[v53_.currentTipSideIndex]
		if v64_ ~= nil and (self:getAnimationTime(v64_.animation.name) <= 0 or (self:getAnimationDuration(v64_.animation.name) == 0 or v64_.animation.closeSpeedScale == 0)) then
			v53_.tipState = Trailer.TIPSTATE_CLOSED
			self:endTipping()
		end
	end
	if self.isServer and (self.rootVehicle.getIsControlled == nil or not self.rootVehicle:getIsControlled()) and v53_.redischarge.dischargeObject ~= nil then
		if self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OFF then
			self:updateTrailerAutomaticRedischarge()
		end
		self:raiseActive()
	end
end

-- Local values: name, manualTipToggleActionName, manualDoorToggleActionName
function Trailer:loadTipSide(xmlFile, key, entry)
	local v69_ = xmlFile:getValue(key .. "#name")
	entry.name = g_i18n:convertText(v69_, self.customEnvironment)
	if entry.name == nil then
		Logging.xmlWarning(self.xmlFile, "Given tipSide name \'%s\' not found for \'%s\'!", tostring(v69_), key)
		return false
	end
	entry.dischargeNodeIndex = xmlFile:getValue(key .. "#dischargeNodeIndex")
	entry.canTipIfEmpty = xmlFile:getValue(key .. "#canTipIfEmpty", true)
	entry.canTip = xmlFile:getValue(key .. "#canTip", true)
	entry.manualTipToggle = xmlFile:getValue(key .. ".manualTipToggle#enabled", false)
	if entry.manualTipToggle then
		local v70_ = xmlFile:getValue(key .. ".manualTipToggle#inputAction")
		entry.manualTipToggleAction = InputAction[v70_] or InputAction.IMPLEMENT_EXTRA4
		entry.manualTipToggleStopOnDeactivate = xmlFile:getValue(key .. ".manualTipToggle#stopOnDeactivate", true)
		entry.manualTipToggleActionTextPos = xmlFile:getValue(key .. ".manualTipToggle#inputActionTextPos", "action_startTipping", self.customEnvironment, false)
		entry.manualTipToggleActionTextNeg = xmlFile:getValue(key .. ".manualTipToggle#inputActionTextNeg", "action_stopTipping", self.customEnvironment, false)
	end
	entry.manualDoorToggle = xmlFile:getValue(key .. ".manualDoorToggle#enabled", false)
	if entry.manualDoorToggle then
		entry.manualDoorToggleWhileTipping = xmlFile:getValue(key .. ".manualDoorToggle#openWhileTipping", false)
		entry.manualDoorResetWhileTipping = xmlFile:getValue(key .. ".manualDoorToggle#resetWhileTipping", false)
		local v71_ = xmlFile:getValue(key .. ".manualDoorToggle#inputAction")
		entry.manualDoorToggleAction = InputAction[v71_] or InputAction.IMPLEMENT_EXTRA3
		entry.manualDoorToggleActionTextPos = xmlFile:getValue(key .. ".manualDoorToggle#inputActionTextPos", "action_openBackDoor", self.customEnvironment, false)
		entry.manualDoorToggleActionTextNeg = xmlFile:getValue(key .. ".manualDoorToggle#inputActionTextNeg", "action_closeBackDoor", self.customEnvironment, false)
		entry.manualDoorToggleFillUnitIndex = xmlFile:getValue(key .. ".manualDoorToggle.fillUnit#index")
		entry.manualDoorToggleFillUnitAllowWhileFilled = xmlFile:getValue(key .. ".manualDoorToggle.fillUnit#allowWhileFilled", true)
	end
	entry.animation = {}
	entry.animation.name = xmlFile:getValue(key .. ".animation#name")
	if entry.animation.name == nil or not self:getAnimationExists(entry.animation.name) then
		Logging.xmlWarning(self.xmlFile, "Missing animation name for \'%s\'!", key)
		return false
	end
	entry.animation.speedScale = xmlFile:getValue(key .. ".animation#speedScale", 1) * Platform.gameplay.dischargeSpeedFactor
	entry.animation.closeSpeedScale = -xmlFile:getValue(key .. ".animation#closeSpeedScale", entry.animation.speedScale)
	entry.animation.startTipTime = xmlFile:getValue(key .. ".animation#startTipTime", 0)
	entry.animation.resetTipSideChange = xmlFile:getValue(key .. ".animation#resetTipSideChange", false)
	entry.doorAnimation = {}
	entry.doorAnimation.name = xmlFile:getValue(key .. ".doorAnimation#name")
	entry.doorAnimation.speedScale = xmlFile:getValue(key .. ".doorAnimation#speedScale", 1)
	entry.doorAnimation.closeSpeedScale = -xmlFile:getValue(key .. ".doorAnimation#closeSpeedScale", entry.doorAnimation.speedScale)
	entry.doorAnimation.startTipTime = xmlFile:getValue(key .. ".doorAnimation#startTipTime", 0)
	entry.doorAnimation.delayedClosing = xmlFile:getValue(key .. ".doorAnimation#delayedClosing", false)
	entry.doorAnimation.state = false
	entry.doorAnimation.maxTime = 1
	if entry.doorAnimation.name ~= nil and not self:getAnimationExists(entry.doorAnimation.name) then
		Logging.xmlWarning(self.xmlFile, "Unknown door animation name for \'%s\'!", key)
		return false
	end
	entry.tippingAnimation = {}
	entry.tippingAnimation.name = xmlFile:getValue(key .. ".tippingAnimation#name")
	entry.tippingAnimation.speedScale = xmlFile:getValue(key .. ".tippingAnimation#speedScale", 1)
	entry.fillLevel = {}
	entry.fillLevel.fillUnitIndex = xmlFile:getValue(key .. ".fillLevel#fillUnitIndex")
	entry.fillLevel.minFillLevelPct = xmlFile:getValue(key .. ".fillLevel#minFillLevelPct", 0)
	entry.fillLevel.maxFillLevelPct = xmlFile:getValue(key .. ".fillLevel#maxFillLevelPct", 1)
	if entry.fillLevel.fillUnitIndex ~= nil then
		self.spec_trailer.fillLevelDependentTipSides = true
	end
	if self.isClient then
		entry.animationNodes = g_animationManager:loadAnimations(self.xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
		entry.unloadSound = g_soundManager:loadSampleFromXML(self.xmlFile, key, "unloadSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	entry.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty)
	entry.currentEmptyFactor = 1
	return true
end

-- Local values: spec, tipSide
function Trailer:saveToXMLFile(xmlFile, key, usedModNames)
	local v75_ = self.spec_trailer
	if v75_.tipSideCount > 1 then
		xmlFile:setValue(key .. "#tipSideIndex", v75_.preferedTipSideIndex)
	end
	local v76_ = v75_.tipSides[v75_.preferedTipSideIndex]
	if v76_ ~= nil then
		xmlFile:setValue(key .. "#doorState", self:getAnimationTime(v76_.doorAnimation.name) > 0)
		xmlFile:setValue(key .. "#tipAnimationTime", self:getAnimationTime(v76_.animation.name))
	end
	xmlFile:setValue(key .. "#tipState", v75_.tipState)
end

-- Local values: spec
function Trailer:getCanTogglePreferdTipSide()
	local v78_ = self.spec_trailer
	local v79_
	if v78_.tipState == Trailer.TIPSTATE_CLOSED then
		v79_ = v78_.tipSideCount > 0
	else
		v79_ = false
	end
	return v79_
end

-- Local values: spec, tipSide, fillLevelPct
function Trailer:getIsTipSideAvailable(sideIndex)
	local v82_ = self.spec_trailer.tipSides[sideIndex]
	if v82_ == nil then
		return false
	end
	if v82_.fillLevel.fillUnitIndex ~= nil then
		local v83_ = self:getFillUnitFillLevelPercentage(v82_.fillLevel.fillUnitIndex)
		if v83_ < v82_.fillLevel.minFillLevelPct or v82_.fillLevel.maxFillLevelPct < v83_ then
			return false
		end
	end
	return true
end

-- Local values: spec, newTipSideIndex, checkCount, tipSideToCheck
function Trailer:getNextAvailableTipSide(index)
	local v86_ = self.spec_trailer
	local v87_ = v86_.tipSideCount
	local v88_ = index
	while v87_ > 0 do
		local v89_ = index + 1
		index = v86_.tipSideCount < v89_ and 1 or v89_
		if self:getIsTipSideAvailable(index) then
			return index
		end
		v87_ = v87_ - 1
	end
	return v88_
end

-- Local values: spec, tipState, i, oldTipSide, newTipSide
function Trailer:setPreferedTipSide(index, noEventSend)
	local v93_ = self.spec_trailer
	local v94_ = v93_.tipSideCount
	local v95_ = math.min(v94_, index)
	local v96_ = math.max(1, v95_)
	local v97_ = self:getTipState()
	if v97_ ~= Trailer.TIPSTATE_CLOSED and v97_ ~= Trailer.TIPSTATE_CLOSING then
		self:stopTipping(true)
	end
	if v96_ ~= v93_.preferedTipSideIndex and (v93_.tipSideCount > 1 and (noEventSend == nil or noEventSend == false)) then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(TrailerToggleTipSideEvent.new(self, v96_))
		else
			g_server:broadcastEvent(TrailerToggleTipSideEvent.new(self, v96_), nil, nil, self)
		end
	end
	for v98_ = 1, #v93_.tipSides do
		ObjectChangeUtil.setObjectChanges(v93_.tipSides[v98_].objectChanges, v98_ == v96_, self, self.setMovingToolDirty)
	end
	local v99_ = v93_.tipSides[v93_.preferedTipSideIndex]
	v93_.preferedTipSideIndex = v96_
	local v100_ = v93_.tipSides[v96_]
	if v99_ ~= nil and (v100_.doorAnimation.name ~= v99_.doorAnimation.name and (v99_.doorAnimation.name ~= nil and self:getAnimationTime(v99_.doorAnimation.name) > 0)) then
		self:setTrailerDoorState(v99_.index, false, true)
	end
	if v100_.animation.resetTipSideChange then
		self:setAnimationTime(v100_.animation.name, 0, true, false)
	end
	if v100_.dischargeNodeIndex ~= nil then
		self:setCurrentDischargeNodeIndex(v100_.dischargeNodeIndex)
	end
	self:requestActionEventUpdate()
end

-- Local values: spec
function Trailer:setTipSideUpdateDirty()
	self.spec_trailer.tipSideUpdateDirty = true
end

-- Local values: spec, tipSide, animTime
function Trailer:startTipping(tipSideIndex, noEventSend)
	local v104_ = self.spec_trailer
	local v105_ = tipSideIndex or v104_.preferedTipSideIndex
	local v106_ = v104_.tipSides[v105_]
	if v106_ ~= nil then
		local v107_ = self:getAnimationTime(v106_.animation.name)
		self:playAnimation(v106_.animation.name, v106_.animation.speedScale, v107_, true)
		if v106_.manualDoorToggle and not v106_.manualDoorToggleWhileTipping or v106_.doorAnimation.name == nil then
			if v106_.manualDoorResetWhileTipping then
				self:setTrailerDoorState(v104_.preferedTipSideIndex, false, true, true)
			end
		else
			self:setTrailerDoorState(v104_.preferedTipSideIndex, true, true)
		end
		if v106_.tippingAnimation.name ~= nil then
			self:playAnimation(v106_.tippingAnimation.name, v106_.tippingAnimation.speedScale, self:getAnimationTime(v106_.tippingAnimation.name), true)
		end
		if self.isClient then
			g_animationManager:startAnimations(v106_.animationNodes)
			g_soundManager:playSample(v106_.unloadSound)
		end
		v104_.tipState = Trailer.TIPSTATE_OPENING
		v104_.currentTipSideIndex = v105_
		if v106_.dischargeNodeIndex ~= nil then
			self:setCurrentDischargeNodeIndex(v106_.dischargeNodeIndex)
		end
		v104_.remainingFillDelta = 0
		SpecializationUtil.raiseEvent(self, "onStartTipping", v105_)
		self:raiseActive()
	end
end

-- Local values: spec, tipSide, animTime
function Trailer:stopTipping(noEventSend)
	local v109_ = self.spec_trailer
	local v110_ = v109_.tipSides[v109_.currentTipSideIndex]
	if v110_ ~= nil then
		if v110_.animation.closeSpeedScale == 0 then
			if self:getIsAnimationPlaying(v110_.animation.name) then
				self:stopAnimation(v110_.animation.name, true)
			end
		else
			local v111_ = self:getAnimationTime(v110_.animation.name)
			self:playAnimation(v110_.animation.name, v110_.animation.closeSpeedScale, v111_, true)
		end
		if (not v110_.manualDoorToggle or v110_.manualDoorToggleWhileTipping) and (v110_.doorAnimation.name ~= nil and not v110_.doorAnimation.delayedClosing) then
			self:setTrailerDoorState(v109_.currentTipSideIndex, false, true)
		end
		if v110_.tippingAnimation.name ~= nil then
			self:setAnimationStopTime(v110_.tippingAnimation.name, 1)
		end
		if self.isClient then
			g_animationManager:stopAnimations(v110_.animationNodes)
			g_soundManager:stopSample(v110_.unloadSound)
		end
		v109_.tipState = Trailer.TIPSTATE_CLOSING
		v109_.remainingFillDelta = 0
		SpecializationUtil.raiseEvent(self, "onStopTipping")
		self:raiseActive()
	end
end

-- Local values: spec, tipSide
function Trailer:endTipping(noEventSend)
	local v113_ = self.spec_trailer
	local v114_ = v113_.tipSides[v113_.currentTipSideIndex]
	if v114_ ~= nil and (not v114_.manualDoorToggle or v114_.manualDoorToggleWhileTipping) and (v114_.doorAnimation.name ~= nil and v114_.doorAnimation.delayedClosing) then
		self:setTrailerDoorState(v113_.currentTipSideIndex, false, true)
	end
	v113_.tipState = Trailer.TIPSTATE_CLOSED
	v113_.currentTipSideIndex = nil
	SpecializationUtil.raiseEvent(self, "onEndTipping")
end

-- Local values: spec, tipSide
function Trailer:setTrailerDoorState(tipSideIndex, state, noEventSend, instantUpdate)
	local v120_ = self.spec_trailer.tipSides[tipSideIndex]
	if v120_ ~= nil then
		if state == nil then
			state = not v120_.doorAnimation.state
		end
		v120_.doorAnimation.state = state
		self:setAnimationStopTime(v120_.doorAnimation.name, state and (v120_.doorAnimation.maxTime or 0) or 0)
		self:playAnimation(v120_.doorAnimation.name, state and v120_.doorAnimation.speedScale or v120_.doorAnimation.closeSpeedScale, self:getAnimationTime(v120_.doorAnimation.name), true)
		if instantUpdate then
			AnimatedVehicle.updateAnimationByName(self, v120_.doorAnimation.name, 999999, true)
		end
		if v120_.manualDoorToggle and v120_.doorAnimation.name ~= nil then
			if state then
				SpecializationUtil.raiseEvent(self, "onOpenBackDoor", tipSideIndex)
			else
				SpecializationUtil.raiseEvent(self, "onCloseBackDoor", tipSideIndex)
			end
		end
		TrailerToggleManualDoorEvent.sendEvent(self, tipSideIndex, state, noEventSend)
	end
end

-- Local values: spec, tipSide
function Trailer:getAllowTrailerDoorToggle(tipSideIndex)
	local v123_ = self.spec_trailer
	local v124_ = v123_.tipSides[tipSideIndex]
	if v124_ ~= nil then
		if v124_.manualDoorToggleFillUnitIndex ~= nil and (not v124_.manualDoorToggleFillUnitAllowWhileFilled and self:getFillUnitFillLevel(v124_.manualDoorToggleFillUnitIndex) > 0) then
			return false
		end
		if v124_.doorAnimation.state then
			if v123_.tipState == Trailer.TIPSTATE_OPENING or v123_.tipState == Trailer.TIPSTATE_OPEN then
				return false
			end
		elseif v124_.manualDoorResetWhileTipping and (v123_.tipState == Trailer.TIPSTATE_OPENING or (v123_.tipState == Trailer.TIPSTATE_OPEN or v123_.tipState == Trailer.TIPSTATE_CLOSING)) then
			return false
		end
	end
	return true
end

function Trailer:getTipState()
	return self.spec_trailer.tipState
end

-- Local values: spec, tipSide
function Trailer:setTipState(isOpen)
	local v128_ = self.spec_trailer
	local v129_ = v128_.tipSides[v128_.currentTipSideIndex]
	if v129_ ~= nil then
		if isOpen then
			self:playAnimation(v129_.animation.name, v129_.animation.speedScale, self:getAnimationTime(v129_.animation.name), true)
			if not v129_.manualDoorToggle and v129_.doorAnimation.name ~= nil then
				self:setAnimationStopTime(v129_.doorAnimation.name, v129_.doorAnimation.maxTime)
				self:playAnimation(v129_.doorAnimation.name, v129_.doorAnimation.speedScale, self:getAnimationTime(v129_.doorAnimation.name), true)
			end
		else
			self:playAnimation(v129_.animation.name, v129_.animation.closeSpeedScale, self:getAnimationTime(v129_.animation.name), true)
			if not v129_.manualDoorToggle and v129_.doorAnimation.name ~= nil then
				self:playAnimation(v129_.doorAnimation.name, v129_.doorAnimation.closeSpeedScale, self:getAnimationTime(v129_.doorAnimation.name), true)
			end
		end
		AnimatedVehicle.updateAnimationByName(self, v129_.animation.name, 999999, true)
		AnimatedVehicle.updateAnimationByName(self, v129_.doorAnimation.name, 999999, true)
	end
end

-- Local values: spec, dischargeNode, failed, x, y, z, pos, distance, dischargeObject, dischargeFillUnitIndex, fillLevel, dischargeAllowed, threshold, capacity, freeCapacity
function Trailer:updateTrailerAutomaticRedischarge()
	local v131_ = self.spec_trailer
	local v132_ = self:getCurrentDischargeNode()
	if v132_ ~= nil then
		local v133_ = false
		local v134_, v135_, v136_ = getWorldTranslation(v132_.node)
		local v137_ = v131_.redischarge.dischargeNodeLastPos
		if MathUtil.vector3Length(v137_[1] - v134_, v137_[2] - v135_, v137_[3] - v136_) < 1.5 then
			local v138_, v139_ = self:getDischargeTargetObject(v132_)
			if v138_ ~= nil and v138_ == v131_.redischarge.dischargeObject then
				local v140_ = self:getFillUnitFillLevel(v132_.fillUnitIndex)
				if v140_ > 0 then
					local v141_ = true
					local v142_ = 0.5
					if v138_.getTrailerAutomaticRedischargeThreshold ~= nil then
						v142_ = v138_:getTrailerAutomaticRedischargeThreshold() or v142_
					end
					if v138_.getFillUnitCapacity ~= nil and v138_.getFillUnitFreeCapacity ~= nil then
						local v143_ = v138_:getFillUnitCapacity(v139_)
						local v144_ = v138_:getFillUnitFreeCapacity(v139_, self:getDischargeFillType(v132_), self:getActiveFarm())
						v141_ = v143_ * v142_ < v144_ and true or v140_ < v144_
					end
					if v141_ then
						v131_.redischarge.isDisabled = true
						self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
						v131_.redischarge.isDisabled = false
					end
				else
					v133_ = true
				end
			end
		else
			v133_ = true
		end
		if v133_ then
			v131_.redischarge.dischargeObject = nil
			local v145_ = v131_.redischarge.dischargeNodeLastPos
			local v146_ = v131_.redischarge.dischargeNodeLastPos
			local v147_ = v131_.redischarge.dischargeNodeLastPos
			v145_[1] = 0
			v146_[2] = 0
			v147_[3] = 0
		end
	end
end

-- Local values: spec, tipSide
function Trailer:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	local v151_ = self.spec_trailer.dischargeNodeIndexToTipSide[dischargeNode.index]
	if v151_ == nil then
		return superFunc(self, dischargeNode)
	else
		return v151_.animation.name ~= nil and (v151_.animation.startTipTime ~= 0 and (self:getAnimationDuration(v151_.animation.name) > 0 and self:getAnimationTime(v151_.animation.name) < v151_.animation.startTipTime)) and 0 or (v151_.doorAnimation.name ~= nil and (v151_.doorAnimation.startTipTime ~= 0 and (self:getAnimationDuration(v151_.doorAnimation.name) > 0 and self:getAnimationTime(v151_.doorAnimation.name) < v151_.doorAnimation.startTipTime)) and 0 or v151_.currentEmptyFactor)
	end
end

-- Local values: canTip, spec, tipSide, fillUnitIndex
function Trailer:getCanDischargeToGround(superFunc, dischargeNode)
	local v155_ = superFunc(self, dischargeNode)
	if dischargeNode ~= nil then
		local v156_ = self.spec_trailer
		local v157_ = v156_.tipSides[v156_.currentTipSideIndex or v156_.preferedTipSideIndex]
		if v157_ ~= nil then
			if not v157_.canTip then
				return false
			end
			local v158_ = dischargeNode.fillUnitIndex
			if not v157_.canTipIfEmpty and self:getFillUnitFillLevel(v158_) == 0 then
				v155_ = false
			end
		end
	end
	return v155_
end

-- Local values: canTip, spec, tipSide
function Trailer:getCanDischargeToObject(superFunc, dischargeNode)
	local v162_ = superFunc(self, dischargeNode)
	if dischargeNode ~= nil then
		local v163_ = self.spec_trailer
		local v164_ = v163_.tipSides[v163_.currentTipSideIndex or v163_.preferedTipSideIndex]
		if v164_ ~= nil and not v164_.canTip then
			v162_ = false
		end
	end
	return v162_
end

-- Local values: spec, tipSide, preferedTipSide, dischargeNode, cover
function Trailer:getIsNextCoverStateAllowed(superFunc, nextState)
	local v168_ = self.spec_trailer
	local v169_
	if v168_.currentTipSideIndex == nil then
		v169_ = nil
	else
		v169_ = v168_.tipSides[v168_.currentTipSideIndex]
	end
	local v170_
	if v168_.preferedTipSideIndex == nil then
		v170_ = v169_
	else
		v170_ = v168_.tipSides[v168_.preferedTipSideIndex]
		if v170_ == nil or not v170_.manualDoorToggle then
			v170_ = v169_
		elseif not v170_.doorAnimation.state then
			v170_ = v169_
		end
	end
	if v170_ ~= nil and v170_.dischargeNodeIndex ~= nil then
		local v171_ = self:getCoverByFillUnitIndex(self:getDischargeNodeByIndex(v170_.dischargeNodeIndex).fillUnitIndex)
		if v171_ ~= nil and nextState ~= v171_.index then
			return false
		end
	end
	return superFunc(self, nextState)
end

function Trailer:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec, _, actionEventId, tipSide, _, actionEventId, _, actionEventId
function Trailer:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v174_ = self.spec_trailer
		self:clearActionEventsTable(v174_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if v174_.tipSideCount > 1 then
				local _, v175_ = self:addActionEvent(v174_.actionEvents, InputAction.TOGGLE_TIPSIDE, self, Trailer.actionEventToggleTipSide, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v175_, GS_PRIO_NORMAL)
			end
			local v176_ = v174_.tipSides[v174_.preferedTipSideIndex]
			if v176_ ~= nil then
				if v176_.manualTipToggle then
					local _, v177_ = self:addPoweredActionEvent(v174_.actionEvents, v176_.manualTipToggleAction, self, Trailer.actionEventManualToggleTip, false, true, false, true, nil)
					g_inputBinding:setActionEventTextPriority(v177_, GS_PRIO_NORMAL)
				end
				if v176_.manualDoorToggle then
					local _, v178_ = self:addPoweredActionEvent(v174_.actionEvents, v176_.manualDoorToggleAction, self, Trailer.actionEventManualToggleDoor, false, true, false, true, nil)
					g_inputBinding:setActionEventTextPriority(v178_, GS_PRIO_NORMAL)
				end
			end
		end
	end
end

-- Local values: spec, dischargeNode, dischargeObject, _
function Trailer:onDischargeStateChanged(dischargeState)
	local v181_ = self.spec_trailer
	if dischargeState == Dischargeable.DISCHARGE_STATE_OFF then
		self:stopTipping(true)
	elseif dischargeState == Dischargeable.DISCHARGE_STATE_GROUND or dischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
		self:startTipping(nil, true)
	end
	if not v181_.redischarge.isDisabled and dischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
		local v182_ = self:getCurrentDischargeNode()
		if v182_ ~= nil then
			local v183_, _ = self:getDischargeTargetObject(v182_)
			v181_.redischarge.dischargeObject = v183_
			local v184_ = v181_.redischarge.dischargeNodeLastPos
			local v185_ = v181_.redischarge.dischargeNodeLastPos
			local v186_ = v181_.redischarge.dischargeNodeLastPos
			local v187_, v188_, v189_ = getWorldTranslation(v182_.node)
			v184_[1] = v187_
			v185_[2] = v188_
			v186_[3] = v189_
		end
	end
end

-- Local values: spec, tipSide, tipState
function Trailer:onDeactivate()
	local v191_ = self.spec_trailer
	local v192_ = v191_.tipSides[v191_.preferedTipSideIndex]
	if v192_ ~= nil and (v192_.manualTipToggle and v192_.manualTipToggleStopOnDeactivate) then
		local v193_ = self:getTipState()
		if v193_ == Trailer.TIPSTATE_OPEN or v193_ == Trailer.TIPSTATE_OPENING then
			self:stopTipping(true)
		end
	end
end

function Trailer:getAIHasFinishedDischarge(superFunc, dischargeNode)
	if self:getTipState() == Trailer.TIPSTATE_CLOSED then
		return superFunc(self, dischargeNode)
	else
		return false
	end
end

-- Local values: spec, tipSide
function Trailer:startAIDischarge(superFunc, dischargeNode, task)
	local v201_ = self.spec_trailer.dischargeNodeIndexToTipSide[dischargeNode.index]
	if v201_ ~= nil then
		self:setPreferedTipSide(v201_.index)
	end
	superFunc(self, dischargeNode, task)
end

function Trailer:loadPickupFromXML(superFunc, xmlFile, key, spec)
	spec.allowWhileTipping = xmlFile:getValue(key .. "#allowWhileTipping", true)
	return superFunc(self, xmlFile, key, spec)
end

function Trailer:getCanChangePickupState(superFunc, spec, newState)
	if superFunc(self, spec, newState) then
		return spec.allowWhileTipping and true or self:getTipState() == Trailer.TIPSTATE_CLOSED
	else
		return false
	end
end

function Trailer:loadTurnedOnAnimationFromXML(superFunc, xmlFile, key, turnedOnAnimation)
	turnedOnAnimation.playWhileTipping = xmlFile:getValue(key .. "#playWhileTipping", false)
	return superFunc(self, xmlFile, key, turnedOnAnimation)
end

-- Local values: tipState
function Trailer:getRequiresPower(superFunc)
	local v218_ = self:getTipState()
	return (v218_ == Trailer.TIPSTATE_OPENING or v218_ == Trailer.TIPSTATE_CLOSING) and true or superFunc(self)
end

-- Local values: spec
function Trailer:setManualDischargeState(superFunc, state, noEventSend)
	if state == Dischargeable.DISCHARGE_STATE_OFF then
		local v223_ = self.spec_trailer
		v223_.redischarge.dischargeObject = nil
		local v224_ = v223_.redischarge.dischargeNodeLastPos
		local v225_ = v223_.redischarge.dischargeNodeLastPos
		local v226_ = v223_.redischarge.dischargeNodeLastPos
		v224_[1] = 0
		v225_[2] = 0
		v226_[3] = 0
	end
	return superFunc(self, state, noEventSend)
end

function Trailer:getIsTurnedOnAnimationActive(superFunc, turnedOnAnimation)
	if not turnedOnAnimation.playWhileTipping then
		return superFunc(self, turnedOnAnimation)
	end
	local v230_ = superFunc(self, turnedOnAnimation)
	if not v230_ then
		if self:getTipState() == Trailer.TIPSTATE_CLOSED then
			v230_ = false
		else
			v230_ = self:getDischargeNodeEmptyFactor(self:getCurrentDischargeNode()) > 0
		end
	end
	return v230_
end

function Trailer:onRegisterAnimationValueTypes()
	self:registerAnimationValueType("tipSideEmptyFactor", "startTipSideEmptyFactor", "endTipSideEmptyFactor", false, AnimationValueFloat, function(p232_, p233_, p234_)
		p232_.node = p233_:getValue(p234_ .. "#node", nil, p232_.part.components, p232_.part.i3dMappings)
		if p232_.node == nil then
			return false
		end
		p232_:setWarningInformation("node: " .. getName(p232_.node))
		p232_:addCompareParameters("node")
		return true
	end, function(p235_)
		if p235_.tipSide == nil then
			local v236_ = p235_.vehicle:getDischargeNodeByNode(p235_.node)
			local v237_
			if v236_ == nil then
				v237_ = nil
			else
				v237_ = p235_.vehicle.spec_trailer.dischargeNodeIndexToTipSide[v236_.index]
			end
			if v236_ == nil or v237_ == nil then
				Logging.xmlWarning(p235_.xmlFile, "Could not update discharge emptyFactor. No tipSide or dischargeNode defined for node \'%s\'!", getName(p235_.node))
				return 0
			end
			p235_.tipSide = v237_
		end
		return p235_.tipSide.currentEmptyFactor
	end, function(p238_, p239_)
		if p238_.tipSide ~= nil then
			p238_.tipSide.currentEmptyFactor = p239_
		end
	end)
	self:registerAnimationValueType("doorAnimationMaxTime", "startDoorAnimationMaxTime", "endDoorAnimationMaxTime", false, AnimationValueFloat, function(p240_, p241_, p242_)
		p240_.node = p241_:getValue(p242_ .. "#node", nil, p240_.part.components, p240_.part.i3dMappings)
		if p240_.node == nil then
			return false
		end
		p240_:setWarningInformation("node: " .. getName(p240_.node))
		p240_:addCompareParameters("node")
		return true
	end, function(p243_)
		if p243_.tipSide == nil then
			local v244_ = p243_.vehicle:getDischargeNodeByNode(p243_.node)
			local v245_
			if v244_ == nil then
				v245_ = nil
			else
				v245_ = p243_.vehicle.spec_trailer.dischargeNodeIndexToTipSide[v244_.index]
			end
			if v244_ == nil or v245_ == nil then
				return 0
			end
			p243_.tipSide = v245_
		end
		return p243_.tipSide.doorAnimation.maxTime
	end, function(p246_, p247_)
		-- upvalues: (copy) self
		if p246_.tipSide ~= nil then
			p246_.tipSide.doorAnimation.maxTime = p247_
			if p246_.tipSide.doorAnimation.state then
				local v248_ = self:getAnimationTime(p246_.tipSide.doorAnimation.name)
				if p247_ < v248_ then
					self:setAnimationStopTime(p246_.tipSide.doorAnimation.name, p247_)
					self:playAnimation(p246_.tipSide.doorAnimation.name, -9999, v248_, true)
					AnimatedVehicle.updateAnimationByName(self, p246_.tipSide.doorAnimation.name, 999999, true)
					return
				end
				if v248_ < p247_ then
					self:setAnimationStopTime(p246_.tipSide.doorAnimation.name, p247_)
					self:playAnimation(p246_.tipSide.doorAnimation.name, p246_.tipSide.doorAnimation.speedScale, v248_, true)
				end
			end
		end
	end)
end

-- Local values: data
function Trailer:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
	if name == "trailerDoorToggle" then
		self:registerExternalActionEvent(trigger, name, Trailer.externalActionEventDoorToggleRegister, Trailer.externalActionEventDoorToggleUpdate).trailerTipSideIndex = xmlFile:getValue(key .. ".trailer#tipSideIndex", 1)
	end
end

-- Local values: spec, tipSide, actionEvent, _
function Trailer.externalActionEventDoorToggleRegister(data, vehicle)
	local v256_ = vehicle.spec_trailer.tipSides[data.trailerTipSideIndex]
	if v256_ ~= nil and v256_.manualDoorToggle then
		local _, v261_ = g_inputBinding:registerActionEvent(v256_.manualDoorToggleAction, data, function(_, p257_, p258_, p259_, p260_)
			-- upvalues: (copy) vehicle, (copy) data
			if vehicle:getIsTipSideAvailable(data.trailerTipSideIndex) then
				vehicle:setPreferedTipSide(data.trailerTipSideIndex)
				Trailer.actionEventManualToggleDoor(vehicle, p257_, p258_, p259_, p260_)
			end
		end, false, true, false, true)
		data.actionEventId = v261_
		g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
	end
end

-- Local values: spec, tipSide, text
function Trailer.externalActionEventDoorToggleUpdate(data, vehicle)
	local v264_ = vehicle.spec_trailer.tipSides[data.trailerTipSideIndex]
	if v264_ ~= nil and v264_.manualDoorToggle then
		local v265_
		if vehicle:getIsAnimationPlaying(v264_.doorAnimation.name) then
			if vehicle:getAnimationSpeed(v264_.doorAnimation.name) > 0 then
				v265_ = v264_.manualDoorToggleActionTextNeg
			else
				v265_ = v264_.manualDoorToggleActionTextPos
			end
		elseif vehicle:getAnimationTime(v264_.doorAnimation.name) <= 0 then
			v265_ = v264_.manualDoorToggleActionTextPos
		else
			v265_ = v264_.manualDoorToggleActionTextNeg
		end
		g_inputBinding:setActionEventText(data.actionEventId, v265_)
	end
end

-- Local values: spec, tipState, tipSideIndex, tipSide
function Trailer:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local v269_ = self.spec_trailer
	if v269_.fillLevelDependentTipSides and (fillLevelDelta ~= 0 and not self:getIsTipSideAvailable(v269_.preferedTipSideIndex)) then
		if self:getTipState() == Trailer.TIPSTATE_CLOSED then
			self:setPreferedTipSide(self:getNextAvailableTipSide(v269_.preferedTipSideIndex))
		else
			self:setTipSideUpdateDirty()
		end
	end
	if self.isServer then
		for v270_, v271_ in ipairs(v269_.tipSides) do
			if v271_.manualDoorToggle and (not v271_.manualDoorToggleFillUnitAllowWhileFilled and (fillLevelDelta > 0 and (v271_.manualDoorToggleFillUnitIndex == fillUnitIndex and self:getFillUnitFillLevel(fillUnitIndex) > 0))) then
				self:setTrailerDoorState(v270_, false)
			end
		end
	end
end

-- Local values: spec
function Trailer:actionEventToggleTipSide(actionName, inputValue, callbackState, isAnalog)
	local v273_ = self.spec_trailer
	if self:getCanTogglePreferdTipSide() then
		self:setPreferedTipSide(self:getNextAvailableTipSide(v273_.preferedTipSideIndex))
	end
end

-- Local values: tipState
function Trailer:actionEventManualToggleTip(actionName, inputValue, callbackState, isAnalog)
	local v275_ = self:getTipState()
	if v275_ == Trailer.TIPSTATE_CLOSED or v275_ == Trailer.TIPSTATE_CLOSING then
		self:startTipping(nil, false)
		TrailerToggleManualTipEvent.sendEvent(self, true)
	else
		self:stopTipping()
		TrailerToggleManualTipEvent.sendEvent(self, false)
	end
end

-- Local values: spec
function Trailer:actionEventManualToggleDoor(actionName, inputValue, callbackState, isAnalog)
	local v277_ = self.spec_trailer
	if self:getAllowTrailerDoorToggle(v277_.preferedTipSideIndex) then
		self:setTrailerDoorState(v277_.preferedTipSideIndex)
	else
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedNow"), 5000)
	end
end
