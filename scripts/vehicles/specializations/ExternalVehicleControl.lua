-- Local values: ExternalVehicleControlActivatable_mt
ExternalVehicleControl = {}
ExternalVehicleControl.FUNCTION_XML_PATH = "vehicle.externalVehicleControl.trigger(?).function(?)"

function ExternalVehicleControl.prerequisitesPresent(self)
	return true
end
function ExternalVehicleControl.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("ExternalVehicleControl")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.externalVehicleControl.trigger(?)#node", "Player trigger node")
	v1_:addDelayedRegistrationPath(ExternalVehicleControl.FUNCTION_XML_PATH, "ExternalVehicleControl:function")
	v1_:register(XMLValueType.STRING, ExternalVehicleControl.FUNCTION_XML_PATH .. "#name", "Name of the function to be available")
	v1_:setXMLSpecializationType()
end

function ExternalVehicleControl.registerEvents(self)
	SpecializationUtil.registerEvent(vehicleType, "onRegisterExternalActionEvents")
end

function ExternalVehicleControl.registerFunctions(self)
	SpecializationUtil.registerFunction(vehicleType, "registerExternalActionEvent", ExternalVehicleControl.registerExternalActionEvent)
end

function ExternalVehicleControl.registerOverwrittenFunctions(self) end

function ExternalVehicleControl.registerEventListeners(self)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ExternalVehicleControl)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExternalVehicleControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExternalVehicleControl)
end

-- Local values: spec, _, key, trigger, _, funcKey, name
function ExternalVehicleControl:onLoadFinished(savegame)
	local v6_ = self.spec_externalVehicleControl
	v6_.triggers = {}
	for _, v7_ in self.xmlFile:iterator("vehicle.externalVehicleControl.trigger") do
		local v8_ = {
			["node"] = self.xmlFile:getValue(v7_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v8_.node ~= nil then
			if not CollisionFlag.getHasMaskFlagSet(v8_.node, CollisionFlag.PLAYER) then
				Logging.xmlWarning(self.xmlFile, "Invalid collision mask flags set in \'%s\'. Player bit missing!", v7_)
			end
			v8_.vehicle = self
			v8_.isPlayerInRange = false
			v8_.controlFunctions = {}
			v8_.callbackId = addTrigger(v8_.node, "onExternalVehicleControlTriggerCallback", v8_, false, ExternalVehicleControl.onExternalVehicleControlTriggerCallback)
			for _, v9_ in self.xmlFile:iterator(v7_ .. ".function") do
				local v10_ = self.xmlFile:getValue(v9_ .. "#name")
				if v10_ ~= nil then
					SpecializationUtil.raiseEvent(self, "onRegisterExternalActionEvents", v8_, v10_, self.xmlFile, v9_)
				end
			end
			v8_.activatable = ExternalVehicleControlActivatable.new(self, v8_)
			local v11_ = v6_.triggers
			table.insert(v11_, v8_)
		end
	end
	if #v6_.triggers == 0 then
		SpecializationUtil.removeEventListener(self, "onDelete", ExternalVehicleControl)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", ExternalVehicleControl)
	end
end

-- Local values: spec, _, trigger
function ExternalVehicleControl:onDelete()
	local v13_ = self.spec_externalVehicleControl
	if v13_.triggers ~= nil then
		for _, v14_ in ipairs(v13_.triggers) do
			if v14_.node ~= nil then
				removeTrigger(v14_.node, v14_.callbackId)
			end
			g_currentMission.activatableObjectsSystem:removeActivatable(v14_.activatable)
		end
	end
end

-- Local values: spec, _, trigger
function ExternalVehicleControl:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v16_ = self.spec_externalVehicleControl
	for _, v17_ in ipairs(v16_.triggers) do
		if v17_.isPlayerInRange then
			v17_.activatable:updateText()
			self:raiseActive()
		end
	end
end

-- Local values: controlFunction
function ExternalVehicleControl:registerExternalActionEvent(trigger, name, registerFunc, updateFunc)
	local v21_ = {
		["registerFunc"] = registerFunc,
		["updateFunc"] = updateFunc
	}
	local v22_ = trigger.controlFunctions
	table.insert(v22_, v21_)
	return v21_
end

function ExternalVehicleControl.onExternalVehicleControlTriggerCallback(trigger, triggerId, otherId, onEnter, onLeave, onStay)
	if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
		if onEnter then
			trigger.isPlayerInRange = true
			trigger.vehicle:raiseActive()
			trigger.activatable:updateText()
			g_currentMission.activatableObjectsSystem:addActivatable(trigger.activatable)
			return
		end
		trigger.isPlayerInRange = false
		g_currentMission.activatableObjectsSystem:removeActivatable(trigger.activatable)
	end
end
ExternalVehicleControlActivatable = {}
local v_u_26_ = Class(ExternalVehicleControlActivatable)

-- Upvalues: ExternalVehicleControlActivatable_mt
-- Local values: self
function ExternalVehicleControlActivatable.new(vehicle, trigger)
	-- upvalues: (copy) v_u_26_
	local v29_ = v_u_26_
	local v30_ = setmetatable({}, v29_)
	v30_.vehicle = vehicle
	v30_.trigger = trigger
	v30_.activateText = ""
	v30_:updateText()
	return v30_
end

-- Local values: i, controlFunction
function ExternalVehicleControlActivatable:registerCustomInput(inputContext)
	if inputContext == PlayerInputComponent.INPUT_CONTEXT_NAME then
		for _, v33_ in ipairs(self.trigger.controlFunctions) do
			if v33_.registerFunc ~= nil then
				v33_:registerFunc(self.vehicle)
			end
		end
	end
end

-- Local values: i, controlFunction
function ExternalVehicleControlActivatable:removeCustomInput(inputContext)
	for _, v35_ in ipairs(self.trigger.controlFunctions) do
		g_inputBinding:removeActionEventsByTarget(v35_)
	end
end

function ExternalVehicleControlActivatable:getIsActivatable()
	if g_currentMission.accessHandler:canPlayerAccess(self.vehicle) then
		return self.trigger.isPlayerInRange
	else
		return false
	end
end

function ExternalVehicleControlActivatable.run(self) end

-- Local values: tx, ty, tz
function ExternalVehicleControlActivatable:getDistance(x, y, z)
	local v41_, v42_, v43_ = getWorldTranslation(self.trigger.node)
	return MathUtil.vector3Length(x - v41_, y - v42_, z - v43_)
end

-- Local values: i, controlFunction
function ExternalVehicleControlActivatable:updateText()
	for _, v45_ in ipairs(self.trigger.controlFunctions) do
		if v45_.updateFunc ~= nil then
			v45_:updateFunc(self.vehicle)
		end
	end
end
