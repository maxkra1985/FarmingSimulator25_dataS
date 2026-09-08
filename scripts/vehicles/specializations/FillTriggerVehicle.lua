FillTriggerVehicle = {}

function FillTriggerVehicle.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function FillTriggerVehicle.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("FillTriggerVehicle")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.fillTriggerVehicle#triggerNode", "Fill trigger node")
	v2_:register(XMLValueType.INT, "vehicle.fillTriggerVehicle#fillUnitIndex", "Fill unit index", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.fillTriggerVehicle#litersPerSecond", "Liter per second", 200)
	v2_:setXMLSpecializationType()
end

function FillTriggerVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", FillTriggerVehicle.getDrawFirstFillText)
end

function FillTriggerVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillTriggerVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillTriggerVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FillTriggerVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FillTriggerVehicle)
end

-- Local values: spec, triggerNode, moneyChangeType
function FillTriggerVehicle:onLoad(savegame)
	local v6_ = self.spec_fillTriggerVehicle
	local v7_ = self.xmlFile:getValue("vehicle.fillTriggerVehicle#triggerNode", nil, self.components, self.i3dMappings)
	if v7_ ~= nil then
		v6_.fillUnitIndex = self.xmlFile:getValue("vehicle.fillTriggerVehicle#fillUnitIndex", 1)
		v6_.litersPerSecond = self.xmlFile:getValue("vehicle.fillTriggerVehicle#litersPerSecond", 200)
		v6_.fillTrigger = FillTrigger.new(v7_, self, v6_.fillUnitIndex, v6_.litersPerSecond)
		if self:getPropertyState() ~= VehiclePropertyState.SHOP_CONFIG and self.isServer then
			local v8_ = MoneyType.register("other", "finance_purchaseFuel")
			v6_.fillTrigger:setMoneyChangeType(v8_)
		end
	end
end

-- Local values: spec
function FillTriggerVehicle:onDelete()
	local v10_ = self.spec_fillTriggerVehicle
	if v10_.fillTrigger ~= nil then
		v10_.fillTrigger:delete()
		v10_.fillTrigger = nil
	end
end

-- Local values: spec, moneyTypeId, moneyChangeType
function FillTriggerVehicle:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v14_ = self.spec_fillTriggerVehicle
		if v14_.fillTrigger ~= nil then
			local v15_ = streamReadUInt16(streamId)
			local v16_ = MoneyType.registerWithId(v15_, "other", "finance_purchaseFuel")
			v14_.fillTrigger:setMoneyChangeType(v16_)
		end
	end
end

-- Local values: spec
function FillTriggerVehicle:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v20_ = self.spec_fillTriggerVehicle
		if v20_.fillTrigger ~= nil then
			streamWriteUInt16(streamId, v20_.fillTrigger.moneyChangeType.id)
		end
	end
end

-- Local values: spec
function FillTriggerVehicle:getDrawFirstFillText(superFunc)
	local v23_ = self.spec_fillTriggerVehicle
	return self.isClient and (v23_.fillUnitIndex ~= nil and (self:getFillUnitFillLevel(v23_.fillUnitIndex) <= 0 and self:getFillUnitCapacity(v23_.fillUnitIndex) ~= 0)) and true or superFunc(self)
end
