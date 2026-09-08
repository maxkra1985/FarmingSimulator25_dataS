AIModeSelection = {}
AIModeSelection.MODE = {}
AIModeSelection.MODE.WORKER = 1
AIModeSelection.MODE.STEERING_ASSIST = 2
Enum(AIModeSelection.MODE)
AIModeSelection.NUM_MODES = 2
AIModeSelection.NUM_BITS = 1
AIModeSelection.MODE_CHANGE_DURATION = 1000
AIModeSelection.MODE_TEXTS = {}
AIModeSelection.MODE_TEXTS[AIModeSelection.MODE.WORKER] = "ai_modeWorker"
AIModeSelection.MODE_TEXTS[AIModeSelection.MODE.STEERING_ASSIST] = "ai_modeSteeringAssist"
source("dataS/scripts/vehicles/specializations/events/AISetModeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIModeSelectionSettingsEvent.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettings.lua")
source("dataS/scripts/gui/hud/extensions/AIModeHUDExtension.lua")

function AIModeSelection.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AIDrivable, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AIAutomaticSteering, specializations)
	end
	return v2_
end
function AIModeSelection.initSpecialization()
	local v3_ = Vehicle.xmlSchemaSavegame
	v3_:register(XMLValueType.STRING, "vehicles.vehicle(?).aiModeSelection#currentMode", "Currently selected AI mode")
	AIUserSettings.registerXMLPaths(v3_, "vehicles.vehicle(?).aiModeSelection.settings")
end

function AIModeSelection.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIModeChanged")
	SpecializationUtil.registerEvent(vehicleType, "onAIModeSettingsChanged")
end

function AIModeSelection.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setAIModeSelection", AIModeSelection.setAIModeSelection)
	SpecializationUtil.registerFunction(vehicleType, "getAIModeSelection", AIModeSelection.getAIModeSelection)
	SpecializationUtil.registerFunction(vehicleType, "aiModeSettingsChanged", AIModeSelection.aiModeSettingsChanged)
	SpecializationUtil.registerFunction(vehicleType, "initializeLoadedAIModeUserSettings", AIModeSelection.initializeLoadedAIModeUserSettings)
	SpecializationUtil.registerFunction(vehicleType, "getAIModeFieldCourseSettings", AIModeSelection.getAIModeFieldCourseSettings)
	SpecializationUtil.registerFunction(vehicleType, "setAIModeFieldCourseSettings", AIModeSelection.setAIModeFieldCourseSettings)
	SpecializationUtil.registerFunction(vehicleType, "applyReadAIModeSettingsFromStream", AIModeSelection.applyReadAIModeSettingsFromStream)
	SpecializationUtil.registerFunction(vehicleType, "writeAIModeSettingsToStream", AIModeSelection.writeAIModeSettingsToStream)
end

function AIModeSelection.registerOverwrittenFunctions(vehicleType) end

function AIModeSelection.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIModeSelection)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIModeSelection)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIModeSelection)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIModeSelection)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AIModeSelection)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", AIModeSelection)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIModeSelection)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AIModeSelection)
end

-- Local values: spec, currentModeName
function AIModeSelection:onLoad(savegame)
	local v9_ = self.spec_aiModeSelection
	v9_.currentMode = AIModeSelection.MODE.WORKER
	v9_.modeChangeStartTime = 0
	v9_.lastModeChangeTime = -math.huge
	v9_.hudExtension = AIModeHUDExtension.new(self)
	v9_.texts = {}
	v9_.texts.modeSelect = g_i18n:getText("ai_modeSelect")
	if savegame ~= nil and not savegame.resetVehicles then
		local v10_ = savegame.xmlFile:getValue(savegame.key .. ".aiModeSelection#currentMode")
		if v10_ ~= nil then
			v9_.currentMode = AIModeSelection.MODE[string.upper(v10_)] or v9_.currentMode
		end
		if savegame.xmlFile:hasProperty(savegame.key .. ".aiModeSelection.settings") then
			v9_.loadedUserSettings = AIUserSettings.new()
			v9_.loadedUserSettings:loadFromXML(savegame.xmlFile, savegame.key .. ".aiModeSelection.settings")
		end
	end
end

-- Local values: spec
function AIModeSelection:onDelete()
	local v12_ = self.spec_aiModeSelection
	if v12_.hudExtension ~= nil then
		v12_.hudExtension:delete()
	end
end

-- Local values: spec
function AIModeSelection:saveToXMLFile(xmlFile, key, usedModNames)
	local v16_ = self.spec_aiModeSelection
	xmlFile:setValue(key .. "#currentMode", AIModeSelection.MODE.getName(v16_.currentMode))
	if v16_.userSettings ~= nil then
		v16_.userSettings:saveToXML(xmlFile, key .. ".settings")
	end
end

-- Local values: spec
function AIModeSelection:onReadStream(streamId, connection)
	local v20_ = self.spec_aiModeSelection
	v20_.currentMode = streamReadUIntN(streamId, AIModeSelection.NUM_BITS) + 1
	if streamReadBool(streamId) then
		v20_.receivedFieldCourseAttributes = FieldCourseSettings.readStream(streamId, connection)
	end
end

-- Local values: spec
function AIModeSelection:onWriteStream(streamId, connection)
	local v24_ = self.spec_aiModeSelection
	streamWriteUIntN(streamId, v24_.currentMode - 1, AIModeSelection.NUM_BITS)
	if streamWriteBool(streamId, v24_.fieldCourseSettings ~= nil) then
		v24_.fieldCourseSettings:writeStream(streamId, connection)
	end
end

-- Local values: spec
function AIModeSelection:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		AIModeSelection.updateActionEvents(self, false)
	end
	if not g_currentMission.vehicleSystem.isReloadRunning then
		local v26_ = self.spec_aiModeSelection
		if v26_.loadedUserSettings ~= nil then
			self:initializeLoadedAIModeUserSettings()
		end
		if v26_.receivedFieldCourseAttributes ~= nil then
			v26_.fieldCourseSettings = FieldCourseSettings.generate(self)
			v26_.userSettings = AIUserSettings.new(v26_.fieldCourseSettings)
			v26_.fieldCourseSettings:applyAttributes(v26_.receivedFieldCourseAttributes)
			v26_.receivedFieldCourseAttributes = nil
			v26_.userSettings:reinitialize(v26_.fieldCourseSettings, false)
			v26_.userSettings:apply(v26_.fieldCourseSettings, v26_.currentMode)
		end
	end
end

-- Local values: spec, hud
function AIModeSelection:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v28_ = self.spec_aiModeSelection
	if v28_.hudExtension ~= nil then
		g_currentMission.hud:addHelpExtension(v28_.hudExtension)
	end
end

-- Local values: spec
function AIModeSelection:onStateChange(state, data)
	if (state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH) and not g_currentMission.vehicleSystem.isReloadRunning then
		local v31_ = self.spec_aiModeSelection
		v31_.fieldCourseSettings = nil
		v31_.userSettings = nil
	end
end

-- Local values: spec, _, eventId
function AIModeSelection:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v33_ = self.spec_aiModeSelection
		self:clearActionEventsTable(v33_.actionEvents)
		if self:getIsActiveForInput(true, true) then
			local _, v34_ = self:addActionEvent(v33_.actionEvents, InputAction.TOGGLE_AI, self, AIModeSelection.actionEventToggleAIState, true, true, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v34_, GS_PRIO_HIGH)
			AIModeSelection.updateActionEvents(self, true)
		end
	end
end

-- Local values: spec, _, fieldX, fieldZ, _, fieldCourseSettings, isAllowed, warning
function AIModeSelection:actionEventToggleAIState(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding, isReset)
	local v38_ = self.spec_aiModeSelection
	if inputValue == 1 then
		if v38_.modeChangeStartTime == 0 then
			v38_.modeChangeStartTime = g_time
		end
		if v38_.modeChangeStartTime + AIModeSelection.MODE_CHANGE_DURATION < g_time then
			if v38_.fieldCourseSettings == nil then
				local v39_, _ = FieldCourseSettings.generate(self.rootVehicle)
				v38_.fieldCourseSettings = v39_
				if v38_.userSettings ~= nil then
					v38_.userSettings:reinitialize(v38_.fieldCourseSettings, true)
				end
			end
			if v38_.userSettings == nil then
				v38_.userSettings = AIUserSettings.new(v38_.fieldCourseSettings)
			end
			local v40_, v41_, _ = FieldCourse.findClosestField(nil, nil, nil, nil, self.rootVehicle:getActiveFarm(), self.rootVehicle, nil, v38_.fieldCourseSettings)
			local v42_ = v38_.fieldCourseSettings:clone()
			AISettingsDialog.show(v38_.userSettings, v42_, self, v38_.currentMode, v40_, v41_, self.aiModeSettingsChanged, self)
			v38_.modeChangeStartTime = 0
			return
		end
	elseif v38_.modeChangeStartTime ~= 0 then
		v38_.modeChangeStartTime = 0
		if not isReset then
			if v38_.currentMode == AIModeSelection.MODE.WORKER then
				if g_currentMission:getHasPlayerPermission("hireAssistant") then
					self:toggleAIVehicle()
				else
					g_currentMission:showBlinkingWarning(g_i18n:getText("ai_startStateNoPermission"), 2000)
				end
			end
			if v38_.currentMode == AIModeSelection.MODE.STEERING_ASSIST then
				local v43_, v44_ = self:getIsAIAutomaticSteeringAllowed()
				if v43_ then
					self:setAIAutomaticSteeringEnabled()
					return
				end
				g_currentMission:showBlinkingWarning(v44_, 2000)
			end
		end
	end
end

-- Local values: spec, actionEvent
function AIModeSelection:updateActionEvents(updateText)
	local v47_ = self.spec_aiModeSelection
	local v48_ = v47_.actionEvents[InputAction.TOGGLE_AI]
	if v48_ ~= nil and self.isActiveForInputIgnoreSelectionIgnoreAI then
		if updateText then
			g_inputBinding:setActionEventText(v48_.actionEventId, string.format(v47_.texts.modeSelect, g_i18n:getText(AIModeSelection.MODE_TEXTS[v47_.currentMode])))
		end
		g_inputBinding:setActionEventActive(v48_.actionEventId, self:getCanToggleAIVehicle())
	end
end

-- Local values: spec
function AIModeSelection:setAIModeSelection(aiMode, noEventSend)
	local v52_ = self.spec_aiModeSelection
	if aiMode == nil then
		local v53_ = v52_.currentMode + 1
		aiMode = AIModeSelection.NUM_MODES < v53_ and 1 or v53_
	end
	v52_.lastModeChangeTime = g_time
	if aiMode ~= v52_.currentMode then
		v52_.currentMode = aiMode
		SpecializationUtil.raiseEvent(self, "onAIModeChanged", aiMode)
		AIModeSelection.updateActionEvents(self, true)
		AISetModeEvent.sendEvent(self, aiMode, noEventSend)
	end
end

function AIModeSelection:getAIModeSelection()
	return self.spec_aiModeSelection.currentMode
end

-- Local values: spec
function AIModeSelection:aiModeSettingsChanged(aiMode, fieldCourseSettings)
	local v58_ = self.spec_aiModeSelection
	v58_.fieldCourseSettings = fieldCourseSettings
	AIModeSelectionSettingsEvent.sendEvent(self, v58_.fieldCourseSettings, false)
	self:setAIModeSelection(aiMode)
	SpecializationUtil.raiseEvent(self, "onAIModeSettingsChanged", aiMode)
end

-- Local values: spec, _
function AIModeSelection:initializeLoadedAIModeUserSettings()
	local v60_ = self.spec_aiModeSelection
	if v60_.loadedUserSettings ~= nil then
		if v60_.fieldCourseSettings == nil then
			local v61_, _ = FieldCourseSettings.generate(self.rootVehicle)
			v60_.fieldCourseSettings = v61_
		end
		v60_.userSettings = v60_.loadedUserSettings
		v60_.loadedUserSettings = nil
		v60_.userSettings:reinitialize(v60_.fieldCourseSettings, true)
		v60_.userSettings:apply(v60_.fieldCourseSettings, v60_.currentMode)
	end
end

function AIModeSelection:getAIModeFieldCourseSettings()
	return self.spec_aiModeSelection.fieldCourseSettings
end

-- Local values: spec, defaultFieldCourseSettings, _
function AIModeSelection:setAIModeFieldCourseSettings(fieldCourseSettings)
	local v65_ = self.spec_aiModeSelection
	v65_.fieldCourseSettings = fieldCourseSettings
	if v65_.userSettings == nil then
		local v66_, _ = FieldCourseSettings.generate(self.rootVehicle)
		v65_.userSettings = AIUserSettings.new(v66_)
	end
	v65_.userSettings:reinitialize(v65_.fieldCourseSettings, false)
	v65_.userSettings:apply(v65_.fieldCourseSettings, v65_.currentMode)
	SpecializationUtil.raiseEvent(self, "onAIModeSettingsChanged", v65_.currentMode)
end

-- Local values: data
function AIModeSelection.readAIModeSettingsFromStream(streamId, connection)
	return streamReadBool(streamId) and {
		["attributes"] = FieldCourseSettings.readStream(streamId, connection)
	} or nil
end

-- Local values: spec
function AIModeSelection:applyReadAIModeSettingsFromStream(data)
	local v71_ = self.spec_aiModeSelection
	if data ~= nil then
		v71_.fieldCourseSettings = FieldCourseSettings.generate(self)
		v71_.fieldCourseSettings:applyAttributes(data.attributes)
		v71_.loadedUserSettings = nil
	end
end

-- Local values: spec
function AIModeSelection:writeAIModeSettingsToStream(streamId, connection)
	self:initializeLoadedAIModeUserSettings()
	local v75_ = self.spec_aiModeSelection
	if streamWriteBool(streamId, v75_.fieldCourseSettings ~= nil) then
		v75_.fieldCourseSettings:writeStream(streamId, connection)
	end
end
