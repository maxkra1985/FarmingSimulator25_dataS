source("dataS/scripts/vehicles/specializations/events/HonkEvent.lua")
Honk = {}

function Honk.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function Honk.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Honk")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.honk", "sound")
	v2_:setXMLSpecializationType()
end

function Honk.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsHonkAvailable", Honk.getIsHonkAvailable)
	SpecializationUtil.registerFunction(vehicleType, "setHonkInput", Honk.setHonkInput)
	SpecializationUtil.registerFunction(vehicleType, "playHonk", Honk.playHonk)
end

function Honk.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Honk)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Honk)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Honk)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Honk)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Honk)
end

-- Local values: spec
function Honk:onLoad(savegame)
	local v6_ = self.spec_honk
	v6_.inputPressed = false
	v6_.isPlaying = false
	if self.isClient then
		v6_.sample = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.honk", "sound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdate", Honk)
	end
end

-- Local values: spec
function Honk:onDelete()
	local v8_ = self.spec_honk
	g_soundManager:deleteSample(v8_.sample)
end

-- Local values: spec
function Honk:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient and isActiveForInputIgnoreSelection then
		local v11_ = self.spec_honk
		if v11_.inputPressed then
			if not g_soundManager:getIsSamplePlaying(v11_.sample) then
				self:playHonk(true)
			end
		elseif v11_.isPlaying then
			self:playHonk(false)
		end
		v11_.inputPressed = false
	end
end

function Honk:onLeaveVehicle()
	self:playHonk(false, true)
end

function Honk:getIsHonkAvailable()
	return true
end

-- Local values: spec
function Honk:setHonkInput()
	self.spec_honk.inputPressed = true
end

-- Local values: spec
function Honk:playHonk(isPlaying, noEventSend)
	HonkEvent.sendEvent(self, isPlaying, noEventSend)
	local v17_ = self.spec_honk
	v17_.isPlaying = isPlaying
	if v17_.sample ~= nil then
		if isPlaying then
			if self:getIsActive() and self.isClient then
				g_soundManager:playSample(v17_.sample)
				return
			end
		else
			g_soundManager:stopSample(v17_.sample)
		end
	end
end

-- Local values: spec, _, actionEventId
function Honk:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v20_ = self.spec_honk
		self:clearActionEventsTable(v20_.actionEvents)
		if isActiveForInputIgnoreSelection and v20_.sample ~= nil then
			local _, v21_ = self:addActionEvent(v20_.actionEvents, InputAction.HONK, self, Honk.actionEventHonk, false, true, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v21_, GS_PRIO_VERY_LOW)
			g_inputBinding:setActionEventActive(v21_, true)
			g_inputBinding:setActionEventText(v21_, g_i18n:getText("action_honk"))
		end
	end
end

function Honk:actionEventHonk(actionName, inputValue, callbackState, isAnalog)
	self:setHonkInput()
end
