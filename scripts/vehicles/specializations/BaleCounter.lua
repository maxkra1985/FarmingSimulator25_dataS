BaleCounter = {}
BaleCounter.SEND_NUM_BITS = 16
source("dataS/scripts/vehicles/specializations/events/BaleCounterResetEvent.lua")
source("dataS/scripts/gui/hud/extensions/BaleCounterHUDExtension.lua")

function BaleCounter.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Baler, specializations)
end
function BaleCounter.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("BaleCounter")
	Dashboard.registerDashboardXMLPaths(v2_, "vehicle.baleCounter.dashboards", { "sessionCounter", "lifetimeCounter" })
	v2_:setXMLSpecializationType()
	local v3_ = Vehicle.xmlSchemaSavegame
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).baleCounter#sessionCounter", "Session counter")
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).baleCounter#lifetimeCounter", "Lifetime counter")
end

function BaleCounter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "doBaleCounterReset", BaleCounter.doBaleCounterReset)
end

function BaleCounter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "dropBale", BaleCounter.dropBale)
end

function BaleCounter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", BaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", BaleCounter)
end

-- Local values: spec
function BaleCounter:onLoad(savegame)
	local v9_ = self.spec_baleCounter
	v9_.sessionCounter = 0
	v9_.lifetimeCounter = 0
	if savegame ~= nil and not savegame.resetVehicles then
		v9_.sessionCounter = savegame.xmlFile:getValue(savegame.key .. ".baleCounter#sessionCounter", v9_.sessionCounter)
		v9_.lifetimeCounter = savegame.xmlFile:getValue(savegame.key .. ".baleCounter#lifetimeCounter", v9_.lifetimeCounter)
	end
	v9_.hudExtension = BaleCounterHUDExtension.new(self)
end

-- Local values: spec
function BaleCounter:onDelete()
	local v11_ = self.spec_baleCounter
	if v11_.hudExtension ~= nil then
		g_currentMission.hud:removeInfoExtension(v11_.hudExtension)
		v11_.hudExtension:delete()
	end
end

-- Local values: spec
function BaleCounter:onDraw()
	local v13_ = self.spec_baleCounter
	if v13_.hudExtension ~= nil then
		g_currentMission.hud:addInfoExtension(v13_.hudExtension)
	end
end

-- Local values: spec, sessionCounter, lifetimeCounter
function BaleCounter:onRegisterDashboardValueTypes()
	local v15_ = self.spec_baleCounter
	local v16_ = DashboardValueType.new("baleCounter", "sessionCounter")
	v16_:setValue(v15_, "sessionCounter")
	v16_:setPollUpdate(false)
	self:registerDashboardValueType(v16_)
	local v17_ = DashboardValueType.new("baleCounter", "lifetimeCounter")
	v17_:setValue(v15_, "lifetimeCounter")
	v17_:setPollUpdate(false)
	self:registerDashboardValueType(v17_)
end

-- Local values: spec
function BaleCounter:saveToXMLFile(xmlFile, key, usedModNames)
	local v21_ = self.spec_baleCounter
	xmlFile:setValue(key .. "#sessionCounter", v21_.sessionCounter)
	xmlFile:setValue(key .. "#lifetimeCounter", v21_.lifetimeCounter)
end

-- Local values: spec
function BaleCounter:onReadStream(streamId, connection)
	local v24_ = self.spec_baleCounter
	v24_.sessionCounter = streamReadUIntN(streamId, BaleCounter.SEND_NUM_BITS)
	v24_.lifetimeCounter = streamReadUIntN(streamId, BaleCounter.SEND_NUM_BITS)
end

-- Local values: spec
function BaleCounter:onWriteStream(streamId, connection)
	local v27_ = self.spec_baleCounter
	streamWriteUIntN(streamId, v27_.sessionCounter, BaleCounter.SEND_NUM_BITS)
	streamWriteUIntN(streamId, v27_.lifetimeCounter, BaleCounter.SEND_NUM_BITS)
end

-- Local values: spec, _, actionEventId
function BaleCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v30_ = self.spec_baleCounter
		self:clearActionEventsTable(v30_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v31_ = self:addPoweredActionEvent(v30_.actionEvents, InputAction.BALE_COUNTER_RESET, self, BaleCounter.actionEventResetCounter, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v31_, GS_PRIO_HIGH)
		end
	end
end

function BaleCounter:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
	if name == "baleCounterReset" then
		self:registerExternalActionEvent(trigger, name, BaleCounter.externalActionEventRegister, BaleCounter.externalActionEventUpdate)
	end
end

function BaleCounter:actionEventResetCounter(actionName, inputValue, callbackState, isAnalog)
	self:doBaleCounterReset()
end

-- Local values: actionEvent, _
function BaleCounter.externalActionEventRegister(data, vehicle)
	local _, v38_ = g_inputBinding:registerActionEvent(InputAction.BALE_COUNTER_RESET, data, function(_, _, _, _, _)
		-- upvalues: (copy) vehicle
		vehicle:doBaleCounterReset()
	end, false, true, false, true)
	data.actionEventId = v38_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

function BaleCounter.externalActionEventUpdate(data, vehicle) end

-- Local values: spec
function BaleCounter:doBaleCounterReset(noEventSend)
	self.spec_baleCounter.sessionCounter = 0
	BaleCounterResetEvent.sendEvent(self, noEventSend)
end

-- Local values: spec
function BaleCounter:dropBale(superFunc, baleIndex)
	superFunc(self, baleIndex)
	local v44_ = self.spec_baleCounter
	v44_.sessionCounter = v44_.sessionCounter + 1
	v44_.lifetimeCounter = v44_.lifetimeCounter + 1
	if self.updateDashboardValueType ~= nil then
		self:updateDashboardValueType("baleCounter.sessionCounter")
		self:updateDashboardValueType("baleCounter.lifetimeCounter")
	end
end
