SeedTreater = {}

function SeedTreater.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end
	return v2_
end
function SeedTreater.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("SeedTreater")
	v3_:register(XMLValueType.INT, "vehicle.seedTreater#fillUnitIndex", "Fill unit index with seed treatment liquid", 1)
	v3_:register(XMLValueType.INT, "vehicle.seedTreater#dischargeNodeIndex", "Discharge node index", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.seedTreater#usagePerLiter", "Usage of treatment liquid", 0.1)
	v3_:register(XMLValueType.FLOAT, "vehicle.seedTreater#fillFromTriggerThreshold", "After this amount is available as free capacity the filling from nearby pallets starts", 5)
	v3_:register(XMLValueType.FLOAT, "vehicle.seedTreater#treatmentSpeedFactor", "Speed factor while treatment is active", 0.1)
	v3_:setXMLSpecializationType()
end

function SeedTreater.registerFunctions(vehicleType) end

function SeedTreater.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "discharge", SeedTreater.discharge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeFillType", SeedTreater.getDischargeFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", SeedTreater.getDischargeNodeEmptyFactor)
end

function SeedTreater.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SeedTreater)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SeedTreater)
end

-- Local values: spec
function SeedTreater:onLoad(savegame)
	local v7_ = self.spec_seedTreater
	v7_.fillUnitIndex = self.xmlFile:getValue("vehicle.seedTreater#fillUnitIndex", 1)
	v7_.dischargeNodeIndex = self.xmlFile:getValue("vehicle.seedTreater#dischargeNodeIndex", 1)
	v7_.usagePerLiter = self.xmlFile:getValue("vehicle.seedTreater#usagePerLiter", 0.1)
	v7_.fillFromTriggerThreshold = self.xmlFile:getValue("vehicle.seedTreater#fillFromTriggerThreshold", 5)
	v7_.treatmentSpeedFactor = self.xmlFile:getValue("vehicle.seedTreater#treatmentSpeedFactor", 0.1)
end

-- Local values: spec, fillUnit, specFillUnit, _, trigger
function SeedTreater:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v9_ = self:getFillUnitByIndex(self.spec_seedTreater.fillUnitIndex)
		if v9_ ~= nil then
			if v9_.capacity - v9_.fillLevel > 5 then
				local v10_ = self.spec_fillUnit
				if not v10_.fillTrigger.isFilling then
					for _, v11_ in ipairs(v10_.fillTrigger.triggers) do
						if v11_:getCurrentFillType() == FillType.LIQUIDSEEDTREATMENT and v11_:getIsActivatable(self) then
							self:setFillUnitIsFilling(true)
						end
					end
					return
				end
			elseif self.spec_fillUnit.fillTrigger.isFilling and (self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF and v9_.capacity - v9_.fillLevel < 0.1) then
				self:setFillUnitIsFilling(false)
			end
		end
	end
end

-- Local values: dischargedLiters, minDropReached, hasMinDropFillLevel, spec, fillType, conversion, usage
function SeedTreater:discharge(superFunc, dischargeNode, emptyLiters)
	local v16_, v17_, v18_ = superFunc(self, dischargeNode, emptyLiters)
	local v19_ = self.spec_seedTreater
	if dischargeNode.index == v19_.dischargeNodeIndex then
		local v20_ = self:getFillUnitFillType(dischargeNode.fillUnitIndex)
		if dischargeNode.fillTypeConverter ~= nil and dischargeNode.fillTypeConverter[v20_] ~= nil then
			local v21_ = -v16_ * v19_.usagePerLiter
			if v21_ > 0 then
				self:addFillUnitFillLevel(self:getOwnerFarmId(), v19_.fillUnitIndex, -v21_, self:getFillUnitFillType(v19_.fillUnitIndex), ToolType.UNDEFINED, nil)
			end
		end
	end
	return v16_, v17_, v18_
end

-- Local values: spec
function SeedTreater:getDischargeFillType(superFunc, dischargeNode)
	local v25_ = self.spec_seedTreater
	if v25_ == nil or self:getFillUnitFillLevel(v25_.fillUnitIndex) ~= 0 then
		return superFunc(self, dischargeNode)
	else
		return self:getFillUnitFillType(dischargeNode.fillUnitIndex), 1
	end
end

-- Local values: spec, fillType, conversion
function SeedTreater:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	local v29_ = self.spec_seedTreater
	local v30_ = self:getFillUnitFillType(dischargeNode.fillUnitIndex)
	if dischargeNode.fillTypeConverter == nil or dischargeNode.fillTypeConverter[v30_] ~= nil then
		if self:getFillUnitFillLevel(v29_.fillUnitIndex) == 0 then
			return superFunc(self, dischargeNode)
		else
			return superFunc(self, dischargeNode) * v29_.treatmentSpeedFactor
		end
	else
		return superFunc(self, dischargeNode)
	end
end
