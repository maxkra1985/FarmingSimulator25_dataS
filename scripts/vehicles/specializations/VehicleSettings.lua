source("dataS/scripts/vehicles/specializations/events/VehicleSettingsChangeEvent.lua")
VehicleSettings = {}

function VehicleSettings.prerequisitesPresent(specializations)
	return true
end
function VehicleSettings.initSpecialization() end

function VehicleSettings.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "registerVehicleSetting", VehicleSettings.registerVehicleSetting)
	SpecializationUtil.registerFunction(vehicleType, "setVehicleSettingState", VehicleSettings.setVehicleSettingState)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleSettingState", VehicleSettings.getVehicleSettingState)
	SpecializationUtil.registerFunction(vehicleType, "forceVehicleSettingsUpdate", VehicleSettings.forceVehicleSettingsUpdate)
end

function VehicleSettings.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onVehicleSettingChanged")
end

function VehicleSettings.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", VehicleSettings)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", VehicleSettings)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", VehicleSettings)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", VehicleSettings)
end

-- Local values: spec
function VehicleSettings:onPreLoad(savegame)
	local v5_ = self.spec_vehicleSettings
	v5_.isDirty = false
	v5_.settings = {}
	if self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", VehicleSettings)
	end
end

-- Local values: spec, hasDirtyValue, i
function VehicleSettings:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v7_ = self.spec_vehicleSettings
	if v7_.isDirty then
		local v8_ = false
		for v9_ = 1, #v7_.settings do
			if v7_.settings[v9_].isDirty then
				v8_ = true
				break
			end
		end
		if v8_ and (g_server == nil and g_client ~= nil) then
			g_client:getServerConnection():sendEvent(VehicleSettingsChangeEvent.new(self, v7_.settings))
		end
		v7_.isDirty = false
	end
end

-- Local values: spec, setting
function VehicleSettings:registerVehicleSetting(gameSettingId, isBool)
	local v13_ = self.spec_vehicleSettings
	local v_u_15_ = {
		["index"] = #v13_.settings + 1,
		["gameSettingId"] = gameSettingId,
		["isBool"] = isBool,
		["callback"] = function(_, p14_)
			-- upvalues: (copy) self, (copy) v_u_15_
			if self:getIsActiveForInput(true, true) then
				self:setVehicleSettingState(v_u_15_.index, p14_)
			end
		end
	}
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[gameSettingId], v_u_15_.callback, self)
	local v16_ = v13_.settings
	table.insert(v16_, v_u_15_)
end

-- Local values: spec, i, setting
function VehicleSettings:forceVehicleSettingsUpdate()
	local v18_ = self.spec_vehicleSettings
	for v19_ = 1, #v18_.settings do
		local v20_ = v18_.settings[v19_]
		self:setVehicleSettingState(v20_.index, g_gameSettings:getValue(v20_.gameSettingId), true)
	end
end

-- Local values: spec, setting
function VehicleSettings:setVehicleSettingState(settingIndex, state, noEventSend)
	local v25_ = self.spec_vehicleSettings
	local v26_ = v25_.settings[settingIndex]
	if v26_ ~= nil then
		if (noEventSend == nil or noEventSend == false) and (g_server == nil and g_client ~= nil) then
			g_client:getServerConnection():sendEvent(VehicleSettingsChangeEvent.new(self, v25_.settings))
		end
		v26_.state = state
		v26_.isDirty = true
		v25_.isDirty = true
		SpecializationUtil.raiseEvent(self, "onVehicleSettingChanged", v26_.gameSettingId, state)
	end
end

-- Local values: spec, i, setting
function VehicleSettings:getVehicleSettingState(gameSettingId)
	local v29_ = self.spec_vehicleSettings
	for v30_ = 1, #v29_.settings do
		local v31_ = v29_.settings[v30_]
		if v31_.gameSettingId == gameSettingId then
			return v31_.state
		end
	end
end

function VehicleSettings:onStateChange(state, vehicle, isControlling)
	if isControlling and state == VehicleStateChange.ENTER_VEHICLE then
		self:forceVehicleSettingsUpdate()
	end
end

function VehicleSettings:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self:forceVehicleSettingsUpdate()
end
