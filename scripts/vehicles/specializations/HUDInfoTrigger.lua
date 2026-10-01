HUDInfoTrigger = {}
function HUDInfoTrigger.prerequisitesPresent(specializations)
	return true
end
function HUDInfoTrigger.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("HUDInfoTrigger")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.hudInfoTrigger#triggerNode", "Player or vehicle trigger node")
	schema:setXMLSpecializationType()
end
function HUDInfoTrigger.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInHudInfoTrigger", HUDInfoTrigger.getIsPlayerInHudInfoTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getAllowHudInfoTrigger", HUDInfoTrigger.getAllowHudInfoTrigger)
end
function HUDInfoTrigger.registerOverwrittenFunctions(vehicleType) end
function HUDInfoTrigger.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HUDInfoTrigger)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", HUDInfoTrigger)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HUDInfoTrigger)
end
function HUDInfoTrigger:onLoad(savegame)
	local spec = self.spec_hudInfoTrigger
	spec.triggerNode = self.xmlFile:getValue("vehicle.hudInfoTrigger#triggerNode", nil, self.components, self.i3dMappings)
	if spec.triggerNode ~= nil then
		spec.callbackId = addTrigger(spec.triggerNode, "onHudInfoTriggerCallback", self, false, HUDInfoTrigger.onHudInfoTriggerCallback)
		spec.enteredObjects = {}
	else
		SpecializationUtil.removeEventListener(self, "onDelete", HUDInfoTrigger)
		SpecializationUtil.removeEventListener(self, "onUpdate", HUDInfoTrigger)
	end
end
function HUDInfoTrigger:onDelete()
	local spec = self.spec_hudInfoTrigger
	if spec.triggerNode ~= nil then
		removeTrigger(spec.triggerNode, spec.callbackId)
	end
end
function HUDInfoTrigger:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if not isActiveForInputIgnoreSelection and self:getIsPlayerInHudInfoTrigger() then
		self.rootVehicle:draw()
		self:raiseActive()
	end
end
function HUDInfoTrigger:onHudInfoTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local object = g_currentMission:getNodeObject(otherId)
	if object == nil and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		object = g_localPlayer
	end
	if object ~= nil and object ~= self then
		local objectId = NetworkUtil.getObjectId(object)
		if objectId ~= nil then
			local spec = self.spec_hudInfoTrigger
			if onEnter then
				spec.enteredObjects[objectId] = (spec.enteredObjects[objectId] or 0) + 1
				self:raiseActive()
				return
			end
			if onLeave then
				spec.enteredObjects[objectId] = (spec.enteredObjects[objectId] or 0) - 1
				if spec.enteredObjects[objectId] <= 0 then
					spec.enteredObjects[objectId] = nil
				end
			end
		end
	end
end
function HUDInfoTrigger:getAllowHudInfoTrigger()
	return true
end
function HUDInfoTrigger:getIsPlayerInHudInfoTrigger()
	if not self:getAllowHudInfoTrigger() then
		return false
	end
	local spec = self.spec_hudInfoTrigger
	local localPlayer = g_localPlayer
	if localPlayer == nil then
		return false
	end
	if not localPlayer:getIsInVehicle() then
		local objectId = NetworkUtil.getObjectId(g_localPlayer)
		return spec.enteredObjects[objectId] ~= nil
	end
	local playerVehicle = localPlayer:getCurrentVehicle()
	if playerVehicle == nil then
		return false
	else
		local childVehicles = playerVehicle.childVehicles
		for _, vehicle in ipairs(childVehicles) do
			local objectId = NetworkUtil.getObjectId(vehicle)
			if spec.enteredObjects[objectId] == nil then
				continue
			end
			return true
		end
		return false
	end
end
