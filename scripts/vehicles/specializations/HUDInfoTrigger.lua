HUDInfoTrigger = {}

function HUDInfoTrigger.prerequisitesPresent(self)
	return true
end
function HUDInfoTrigger.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("HUDInfoTrigger")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.hudInfoTrigger#triggerNode", "Player or vehicle trigger node")
	v1_:setXMLSpecializationType()
end

function HUDInfoTrigger.registerFunctions(self)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInHudInfoTrigger", HUDInfoTrigger.getIsPlayerInHudInfoTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getAllowHudInfoTrigger", HUDInfoTrigger.getAllowHudInfoTrigger)
end

function HUDInfoTrigger.registerOverwrittenFunctions(self) end

function HUDInfoTrigger.registerEventListeners(self)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HUDInfoTrigger)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", HUDInfoTrigger)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HUDInfoTrigger)
end

-- Local values: spec
function HUDInfoTrigger:onLoad(savegame)
	local v5_ = self.spec_hudInfoTrigger
	v5_.triggerNode = self.xmlFile:getValue("vehicle.hudInfoTrigger#triggerNode", nil, self.components, self.i3dMappings)
	if v5_.triggerNode == nil then
		SpecializationUtil.removeEventListener(self, "onDelete", HUDInfoTrigger)
		SpecializationUtil.removeEventListener(self, "onUpdate", HUDInfoTrigger)
	else
		v5_.callbackId = addTrigger(v5_.triggerNode, "onHudInfoTriggerCallback", self, false, HUDInfoTrigger.onHudInfoTriggerCallback)
		v5_.enteredObjects = {}
	end
end

-- Local values: spec
function HUDInfoTrigger:onDelete()
	local v7_ = self.spec_hudInfoTrigger
	if v7_.triggerNode ~= nil then
		removeTrigger(v7_.triggerNode, v7_.callbackId)
	end
end

function HUDInfoTrigger:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if not isActiveForInputIgnoreSelection and self:getIsPlayerInHudInfoTrigger() then
		self.rootVehicle:draw()
		self:raiseActive()
	end
end

-- Local values: object, objectId, spec
function HUDInfoTrigger:onHudInfoTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v14_ = g_currentMission:getNodeObject(otherId)
	if v14_ == nil and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		v14_ = g_localPlayer
	end
	if v14_ ~= nil and v14_ ~= self then
		local v15_ = NetworkUtil.getObjectId(v14_)
		if v15_ ~= nil then
			local v16_ = self.spec_hudInfoTrigger
			if onEnter then
				v16_.enteredObjects[v15_] = (v16_.enteredObjects[v15_] or 0) + 1
				self:raiseActive()
				return
			end
			if onLeave then
				v16_.enteredObjects[v15_] = (v16_.enteredObjects[v15_] or 0) - 1
				if v16_.enteredObjects[v15_] <= 0 then
					v16_.enteredObjects[v15_] = nil
				end
			end
		end
	end
end

function HUDInfoTrigger.getAllowHudInfoTrigger(self)
	return true
end

-- Local values: spec, localPlayer, objectId, playerVehicle, childVehicles, _, vehicle, objectId
function HUDInfoTrigger:getIsPlayerInHudInfoTrigger()
	if not self:getAllowHudInfoTrigger() then
		return false
	end
	local v18_ = self.spec_hudInfoTrigger
	local v19_ = g_localPlayer
	if v19_ == nil then
		return false
	end
	if not v19_:getIsInVehicle() then
		local v20_ = NetworkUtil.getObjectId(g_localPlayer)
		return v18_.enteredObjects[v20_] ~= nil
	end
	local v21_ = v19_:getCurrentVehicle()
	if v21_ == nil then
		return false
	end
	local v22_ = v21_.childVehicles
	for _, v23_ in ipairs(v22_) do
		local v24_ = NetworkUtil.getObjectId(v23_)
		if v18_.enteredObjects[v24_] ~= nil then
			return true
		end
	end
	return false
end
