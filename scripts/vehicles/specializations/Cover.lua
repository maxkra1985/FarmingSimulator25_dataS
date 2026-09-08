source("dataS/scripts/vehicles/specializations/events/SetCoverStateEvent.lua")
Cover = {}
Cover.SEND_NUM_BITS = 4
Cover.COVER_XML_KEY = "vehicle.cover.coverConfigurations.coverConfiguration(?).cover(?)"

function Cover.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function Cover.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("cover", g_i18n:getText("configuration_cover"), "cover", VehicleConfigurationItem)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Cover")
	v2_:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#openAnimation", "Open animation name")
	v2_:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#openAnimationStopTime", "Open animation stop time")
	v2_:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#openAnimationStartTime", "Open animation start time")
	v2_:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#closeAnimation", "Close animation name")
	v2_:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#closeAnimationStopTime", "Close animation stop time")
	v2_:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#openOnBuy", "Open after buying", false)
	v2_:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#forceOpenOnTip", "Open while tipping", true)
	v2_:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#autoReactToTrigger", "Automatically open in triggers", true)
	v2_:register(XMLValueType.VECTOR_N, Cover.COVER_XML_KEY .. "#fillUnitIndices", "Fill unit indices to cover")
	v2_:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#blockedToolTypes", "List with blocked tool types", "dischargeable bale trigger pallet")
	v2_:register(XMLValueType.BOOL, "vehicle.cover.coverConfigurations.coverConfiguration(?)#closeCoverIfNotAllowed", "Close cover if not allowed to open it", false)
	v2_:register(XMLValueType.BOOL, "vehicle.cover.coverConfigurations.coverConfiguration(?)#openCoverWhileTipping", "Open cover while tipping", false)
	v2_:register(XMLValueType.L10N_STRING, "vehicle.cover.coverConfigurations.coverConfiguration(?).texts#openCover", "Open cover text", "$l10n_action_openCover")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.cover.coverConfigurations.coverConfiguration(?).texts#closeCover", "Close cover text", "$l10n_action_closeCover")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.cover.coverConfigurations.coverConfiguration(?).texts#nextCover", "Next cover text", "$l10n_action_nextCover")
	v2_:register(XMLValueType.INT, "vehicle.pipe#coverMinState", "Min. cover state to allow pipe state change", 0)
	v2_:register(XMLValueType.INT, "vehicle.pipe#coverMaxState", "Max. cover state to allow pipe state change", "Max. cover state")
	v2_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).cover#state", "Current cover state")
end

function Cover.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCoverFromXML", Cover.loadCoverFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsNextCoverStateAllowed", Cover.getIsNextCoverStateAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsNextCoverStateAllowedWarning", Cover.getIsNextCoverStateAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "setCoverState", Cover.setCoverState)
	SpecializationUtil.registerFunction(vehicleType, "playCoverAnimation", Cover.playCoverAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getCoverByFillUnitIndex", Cover.getCoverByFillUnitIndex)
end

function Cover.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", Cover.getFillUnitSupportsToolType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Cover.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPipeNodes", Cover.loadPipeNodes)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPipeStateChangeAllowed", Cover.getIsPipeStateChangeAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiPrepareLoading", Cover.aiPrepareLoading)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiFinishLoading", Cover.aiFinishLoading)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "finishedAIDischarge", Cover.finishedAIDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setFillUnitInTriggerRange", Cover.setFillUnitInTriggerRange)
end

function Cover.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onStartTipping", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onOpenBackDoor", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitTriggerChanged", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onRemovedFillUnitTrigger", Cover)
end

-- Local values: spec, coverConfigurationId, configKey, i, key, cover, j, index
function Cover:onLoad(savegame)
	local v7_ = self.spec_cover
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cover#animationName", "vehicle.cover.coverConfigurations.coverConfiguration.cover#openAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#closeCoverOnFold", "vehicle.cover.coverConfigurations.coverConfiguration.cover#closeCoverIfNotAllowed")
	local v8_ = Utils.getNoNil(self.configurations.cover, 1)
	local v9_ = string.format("vehicle.cover.coverConfigurations.coverConfiguration(%d)", v8_ - 1)
	v7_.state = 0
	v7_.runningAnimations = {}
	v7_.covers = {}
	v7_.fillUnitIndexToCovers = {}
	v7_.isStateSetAutomatically = false
	local v10_ = 0
	while true do
		local v11_ = string.format("%s.cover(%d)", v9_, v10_)
		if not self.xmlFile:hasProperty(v11_) then
			break
		end
		local v12_ = {}
		if self:loadCoverFromXML(self.xmlFile, v11_, v12_) then
			for v13_ = #v12_.fillUnitIndices, 1, -1 do
				local v14_ = v12_.fillUnitIndices[v13_]
				if v7_.fillUnitIndexToCovers[v14_] == nil then
					v7_.fillUnitIndexToCovers[v14_] = { v12_ }
				else
					local v15_ = v7_.fillUnitIndexToCovers[v14_]
					table.insert(v15_, v12_)
				end
			end
			local v16_ = v7_.covers
			table.insert(v16_, v12_)
			v12_.index = #v7_.covers
		end
		v10_ = v10_ + 1
	end
	v7_.closeCoverIfNotAllowed = self.xmlFile:getValue(v9_ .. "#closeCoverIfNotAllowed", false)
	v7_.openCoverWhileTipping = self.xmlFile:getValue(v9_ .. "#openCoverWhileTipping", false)
	v7_.texts = {}
	v7_.texts.openCover = self.xmlFile:getValue(v9_ .. ".texts#openCover", "action_openCover", self.customEnvironment)
	v7_.texts.closeCover = self.xmlFile:getValue(v9_ .. ".texts#closeCover", "action_closeCover", self.customEnvironment)
	v7_.texts.nextCover = self.xmlFile:getValue(v9_ .. ".texts#nextCover", "action_nextCover", self.customEnvironment)
	v7_.hasCovers = #v7_.covers > 0
	v7_.isDirty = false
	if not v7_.hasCovers then
		SpecializationUtil.removeEventListener(self, "onReadStream", Cover)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Cover)
		SpecializationUtil.removeEventListener(self, "onUpdate", Cover)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Cover)
		SpecializationUtil.removeEventListener(self, "onStartTipping", Cover)
		SpecializationUtil.removeEventListener(self, "onFillUnitTriggerChanged", Cover)
		SpecializationUtil.removeEventListener(self, "onRemovedFillUnitTrigger", Cover)
	end
end

-- Local values: spec, state, i, cover, i, animation
function Cover:onPostLoad(savegame)
	local v19_ = self.spec_cover
	if v19_.hasCovers then
		local v20_ = 0
		if savegame == nil then
			for v21_ = 1, #v19_.covers do
				if v19_.covers[v21_].startOpenState then
					v20_ = v21_
				end
			end
		else
			v20_ = savegame.xmlFile:getValue(savegame.key .. ".cover#state", v20_)
		end
		if v20_ == 0 then
			v19_.state = #v19_.covers
		end
		self:setCoverState(v20_, true)
		for v22_ = #v19_.runningAnimations, 1, -1 do
			local v23_ = v19_.runningAnimations[v22_]
			AnimatedVehicle.updateAnimationByName(self, v23_.name, 9999999, true)
			table.remove(v19_.runningAnimations, v22_)
		end
		v19_.isDirty = false
	end
end

-- Local values: spec
function Cover:saveToXMLFile(xmlFile, key, usedModNames)
	local v27_ = self.spec_cover
	if v27_.hasCovers then
		xmlFile:setValue(key .. "#state", v27_.state)
	end
end

-- Local values: spec, state, i, animation
function Cover:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v31_ = self.spec_cover
		self:setCoverState(streamReadUIntN(streamId, Cover.SEND_NUM_BITS), true)
		for v32_ = #v31_.runningAnimations, 1, -1 do
			local v33_ = v31_.runningAnimations[v32_]
			AnimatedVehicle.updateAnimationByName(self, v33_.name, 9999999, true)
			table.remove(v31_.runningAnimations, v32_)
		end
		v31_.isDirty = false
	end
end

function Cover:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.spec_cover.state, Cover.SEND_NUM_BITS)
	end
end

-- Local values: spec, animation, nextAnim, nextAnimation, newState
function Cover:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v38_ = self.spec_cover
	if v38_.isDirty then
		local v39_ = v38_.runningAnimations[1]
		if v39_ ~= nil then
			local v40_ = v38_.runningAnimations[2]
			if v40_ ~= nil and (v40_.name == v39_.name and v40_.startTime == nil) then
				table.remove(v38_.runningAnimations, 1)
				self:stopAnimation(v39_.name, true)
				self:playCoverAnimation(v40_)
			end
			if not self:getIsAnimationPlaying(v39_.name) then
				table.remove(v38_.runningAnimations, 1)
				local v41_ = v38_.runningAnimations[1]
				if v41_ == nil then
					v38_.isDirty = false
				else
					self:playCoverAnimation(v41_)
				end
			end
		end
	end
	if v38_.closeCoverIfNotAllowed and v38_.state ~= 0 then
		local v42_ = v38_.state + 1
		if not self:getIsNextCoverStateAllowed(#v38_.covers < v42_ and 0 or v42_) then
			self:setCoverState(0, true)
		end
	end
end

-- Local values: strBlockedToolTypes, _, toolType, index
function Cover:loadCoverFromXML(xmlFile, key, cover)
	cover.openAnimation = xmlFile:getValue(key .. "#openAnimation")
	cover.openAnimationStartTime = xmlFile:getValue(key .. "#openAnimationStartTime")
	cover.openAnimationStopTime = xmlFile:getValue(key .. "#openAnimationStopTime")
	if cover.openAnimation == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'openAnimation\' for cover \'%s\'!", key)
		return false
	end
	cover.closeAnimation = xmlFile:getValue(key .. "#closeAnimation")
	cover.closeAnimationStopTime = xmlFile:getValue(key .. "#closeAnimationStopTime")
	cover.startOpenState = xmlFile:getValue(key .. "#openOnBuy", false)
	cover.forceOpenOnTip = xmlFile:getValue(key .. "#forceOpenOnTip", true)
	cover.autoReactToTrigger = xmlFile:getValue(key .. "#autoReactToTrigger", true)
	cover.fillUnitIndices = xmlFile:getValue(key .. "#fillUnitIndices", nil, true)
	if cover.fillUnitIndices == nil or #cover.fillUnitIndices == 0 then
		Logging.xmlWarning(self.xmlFile, "Missing \'fillUnitIndices\' for cover \'%s\'!", key)
		return false
	end
	cover.blockedToolTypes = {}
	local v47_ = xmlFile:getValue(key .. "#blockedToolTypes", "dischargeable bale trigger pallet"):trim():split(" ")
	for _, v48_ in ipairs(v47_) do
		local v49_ = g_toolTypeManager:getToolTypeIndexByName(v48_)
		if v49_ ~= ToolType.UNDEFINED then
			cover.blockedToolTypes[v49_] = true
		end
	end
	return true
end

-- Local values: spec, startAnim, cover, animation, stopTime, cover
function Cover:setCoverState(state, noEventSend)
	local v53_ = self.spec_cover
	if v53_.hasCovers and (state >= 0 and (state <= #v53_.covers and v53_.state ~= state)) then
		SetCoverStateEvent.sendEvent(self, state, noEventSend)
		local v54_ = #v53_.runningAnimations == 0
		if v53_.state > 0 then
			local v55_ = v53_.covers[v53_.state]
			local v56_ = v55_.closeAnimation
			local v57_ = v55_.closeAnimationStopTime or 1
			if v56_ == nil then
				v56_ = v55_.openAnimation
				v57_ = v55_.openAnimationStopTime or 0
			end
			if self:getAnimationExists(v56_) then
				local v58_ = v53_.runningAnimations
				table.insert(v58_, {
					["name"] = v56_,
					["stopTime"] = v57_
				})
			end
		end
		if state > 0 then
			local v59_ = v53_.covers[state]
			local v60_ = v53_.runningAnimations
			local v61_ = {
				["name"] = v59_.openAnimation,
				["startTime"] = v59_.openAnimationStartTime,
				["stopTime"] = v59_.openAnimationStopTime or 1
			}
			table.insert(v60_, v61_)
		end
		v53_.state = state
		v53_.isDirty = #v53_.runningAnimations > 0
		if v54_ and #v53_.runningAnimations > 0 then
			self:playCoverAnimation(v53_.runningAnimations[1])
		end
		Cover.updateActionText(self)
	end
end

-- Local values: dir
function Cover:playCoverAnimation(animation)
	if animation.startTime ~= nil then
		self:setAnimationTime(animation.name, animation.startTime, true)
	end
	local v64_ = animation.stopTime - self:getAnimationTime(animation.name)
	local v65_ = math.sign(v64_)
	self:setAnimationStopTime(animation.name, animation.stopTime)
	self:playAnimation(animation.name, v65_, animation.startTime or self:getAnimationTime(animation.name), true)
end

-- Local values: covers
function Cover:getCoverByFillUnitIndex(fillUnitIndex)
	local v68_ = self.spec_cover.fillUnitIndexToCovers[fillUnitIndex]
	if v68_ == nil then
		return nil
	else
		return v68_[1]
	end
end

-- Local values: spec
function Cover:getIsNextCoverStateAllowed(nextState)
	return #self.spec_cover.runningAnimations <= 1
end

function Cover:getIsNextCoverStateAllowedWarning(nextState)
	return nil
end

-- Local values: spec, covers, isOpen, i, cover
function Cover:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
	local v74_ = self.spec_cover
	if v74_.hasCovers then
		local v75_ = v74_.fillUnitIndexToCovers[fillUnitIndex]
		if v75_ ~= nil and #v75_ > 0 then
			local v76_ = false
			for v77_ = 1, #v75_ do
				local v78_ = v75_[v77_]
				if v74_.state == v78_.index then
					v76_ = true
					break
				end
			end
			if not v76_ and v75_[1].blockedToolTypes[toolType] then
				return false
			end
		end
	end
	return superFunc(self, fillUnitIndex, toolType)
end

function Cover:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec
function Cover:loadPipeNodes(superFunc, pipeNodes, xmlFile, baseKey)
	superFunc(self, pipeNodes, xmlFile, baseKey)
	local v84_ = self.spec_pipe
	v84_.coverMinState = xmlFile:getValue("vehicle.pipe#coverMinState", 0)
	v84_.coverMaxState = xmlFile:getValue("vehicle.pipe#coverMaxState", #self.spec_cover.covers)
end
function Cover.getIsPipeStateChangeAllowed(p85_, p86_, p87_, ...)
	if not p86_(p85_, p87_, ...) then
		return false
	end
	local v88_ = p85_.spec_pipe
	local v89_ = p85_.spec_cover
	return v89_.state >= v88_.coverMinState and v89_.state <= v88_.coverMaxState
end

-- Local values: spec, state, actionEventId, _
function Cover:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v92_ = self.spec_cover
		self:clearActionEventsTable(v92_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local v93_, v94_ = self:addActionEvent(v92_.actionEvents, InputAction.TOGGLE_COVER, self, Cover.actionEventToggleCover, false, true, false, true, nil, nil, true, true)
			if not v93_ then
				local v95_
				v95_, v94_ = self:addActionEvent(v92_.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, Cover.actionEventToggleCover, false, true, false, true, nil, nil, true, true)
			end
			g_inputBinding:setActionEventTextPriority(v94_, GS_PRIO_NORMAL)
			Cover.updateActionText(self)
		end
	end
end

-- Local values: trailerSpec, tipSideDesc, dischargeNode, cover
function Cover:onStartTipping(tipSide)
	if self.spec_cover.openCoverWhileTipping then
		local v98_ = self:getCoverByFillUnitIndex(self:getDischargeNodeByIndex(self.spec_trailer.tipSides[tipSide].dischargeNodeIndex).fillUnitIndex)
		if v98_ ~= nil then
			self:setCoverState(v98_.index, true)
		end
	end
end

-- Local values: trailerSpec, tipSideDesc, dischargeNode, cover
function Cover:onOpenBackDoor(tipSide)
	if self.spec_cover.openCoverWhileTipping then
		local v101_ = self:getCoverByFillUnitIndex(self:getDischargeNodeByIndex(self.spec_trailer.tipSides[tipSide].dischargeNodeIndex).fillUnitIndex)
		if v101_ ~= nil then
			self:setCoverState(v101_.index, true)
		end
	end
end

-- Local values: spec
function Cover:finishedAIDischarge(superFunc)
	if self.spec_cover.hasCovers then
		self:setCoverState(0)
	end
	superFunc(self)
end

-- Local values: cover
function Cover:aiPrepareLoading(superFunc, fillUnitIndex, task)
	local v108_ = self:getCoverByFillUnitIndex(fillUnitIndex)
	if v108_ ~= nil then
		self:setCoverState(v108_.index)
	end
	superFunc(self, fillUnitIndex, task)
end

-- Local values: spec
function Cover:aiFinishLoading(superFunc, fillUnitIndex, task)
	if self.spec_cover.hasCovers then
		self:setCoverState(0)
	end
	superFunc(self, fillUnitIndex, task)
end

-- Local values: spec, covers, isDifferentState, _, cover, isStateChangedAllowed, cover
function Cover:setFillUnitInTriggerRange(superFunc, fillUnitIndex, isInRange)
	superFunc(self, fillUnitIndex, isInRange)
	local v117_ = self.spec_cover
	local v118_ = v117_.fillUnitIndexToCovers[fillUnitIndex]
	if v118_ ~= nil then
		if isInRange then
			local v119_ = true
			for _, v120_ in pairs(v118_) do
				if v119_ then
					v119_ = v117_.state ~= v120_.index
				end
			end
			local v121_ = self:getIsNextCoverStateAllowed(v118_[1].index)
			if v118_[1].autoReactToTrigger and (v119_ and v121_) then
				self:setCoverState(v118_[1].index, true)
				v117_.isStateSetAutomatically = true
				return
			end
		else
			local v122_ = v117_.covers[v117_.state]
			if v122_ ~= nil and (v117_.isStateSetAutomatically and v122_.autoReactToTrigger) then
				self:setCoverState(0, true)
				v117_.isStateSetAutomatically = false
			end
		end
	end
end

-- Local values: spec, covers, isDifferentState, _, cover, isStateChangedAllowed
function Cover:onFillUnitTriggerChanged(fillTrigger, fillTypeIndex, fillUnitIndex, numTriggers)
	local v125_ = self.spec_cover
	local v126_ = v125_.fillUnitIndexToCovers[fillUnitIndex]
	if v126_ ~= nil then
		local v127_ = true
		for _, v128_ in pairs(v126_) do
			if v127_ then
				v127_ = v125_.state ~= v128_.index
			end
		end
		local v129_ = self:getIsNextCoverStateAllowed(v126_[1].index)
		if v126_[1].autoReactToTrigger and (v127_ and v129_) then
			self:setCoverState(v126_[1].index, true)
			v125_.isStateSetAutomatically = true
		end
	end
end

-- Local values: spec, cover
function Cover:onRemovedFillUnitTrigger(numTriggers)
	local v132_ = self.spec_cover
	if numTriggers == 0 then
		local v133_ = v132_.covers[v132_.state]
		if v133_ ~= nil and (v132_.isStateSetAutomatically and v133_.autoReactToTrigger) then
			self:setCoverState(0, true)
			v132_.isStateSetAutomatically = false
		end
	end
end

-- Local values: spec, actionEvent, text
function Cover:updateActionText()
	local v135_ = self.spec_cover
	if next(v135_.actionEvents) ~= nil then
		local v136_ = v135_.actionEvents[next(v135_.actionEvents)]
		if v136_ ~= nil then
			local v137_ = v135_.texts.nextCover
			if v135_.state == #v135_.covers then
				v137_ = v135_.texts.closeCover
			elseif v135_.state == 0 then
				v137_ = v135_.texts.openCover
			end
			g_inputBinding:setActionEventText(v136_.actionEventId, v137_)
		end
	end
end

-- Local values: spec, newState, warning
function Cover:actionEventToggleCover(actionName, inputValue, callbackState, isAnalog)
	local v139_ = self.spec_cover
	local v140_ = v139_.state + 1
	local v141_ = #v139_.covers < v140_ and 0 or v140_
	if self:getIsNextCoverStateAllowed(v141_) then
		self:setCoverState(v141_)
		v139_.isStateSetAutomatically = false
	else
		local v142_ = self:getIsNextCoverStateAllowedWarning(v141_)
		if v142_ ~= nil then
			g_currentMission:showBlinkingWarning(v142_, 3000)
		end
	end
end
