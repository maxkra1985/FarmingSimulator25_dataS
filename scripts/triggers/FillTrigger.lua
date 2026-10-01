FillTrigger = {}
FillTrigger.TRIGGER_MASK = CollisionFlag.FILLABLE
local FillTrigger_mt = Class(FillTrigger)
function FillTrigger:onCreate(id)
	local fillTrigger = FillTrigger.new(id)
	local moneyChangeType = MoneyType.register("other", "finance_purchaseFuel")
	fillTrigger:setMoneyChangeType(moneyChangeType)
	g_currentMission:addNonUpdateable(fillTrigger)
end
function FillTrigger.new(id, sourceObject, fillUnitIndex, fillLitersPerSecond, defaultFillType, customMt)
	local self = setmetatable({}, customMt or FillTrigger_mt)
	self.customEnvironment = g_currentMission.loadingMapModName
	self.triggerId = id
	addTrigger(id, "fillTriggerCallback", self)
	self.soundNode = createTransformGroup("fillTriggerSoundNode")
	link(getParent(id), self.soundNode)
	setTranslation(self.soundNode, getTranslation(id))
	self.sourceObject = sourceObject
	self.vehiclesTriggerCount = {}
	self.vehicleToFillUnitIndices = {}
	self.fillUnitIndex = fillUnitIndex
	self.fillLitersPerSecond = fillLitersPerSecond
	self.isEnabled = true
	self.fillTypeIndex = FillType.DIESEL
	return self
end
function FillTrigger:setMoneyChangeType(moneyChangeType)
	self.moneyChangeType = moneyChangeType
end
function FillTrigger:delete()
	for vehicle, count in pairs(self.vehiclesTriggerCount) do
		if 0 < count then
			if vehicle.removeFillUnitTrigger == nil then
				continue
			end
			vehicle:removeFillUnitTrigger(self)
		end
	end
	g_soundManager:deleteSample(self.sample)
	removeTrigger(self.triggerId)
end
function FillTrigger:onVehicleDeleted(vehicle)
	self.vehiclesTriggerCount[vehicle] = nil
	if self.moneyChangeType ~= nil then
		g_currentMission:showMoneyChange(self.moneyChangeType, nil, false, vehicle:getActiveFarm())
	end
end
function FillTrigger:fillVehicle(vehicle, delta, dt)
	if self.fillLitersPerSecond ~= nil then
		delta = math.min(delta, self.fillLitersPerSecond * 0.001 * dt)
	end
	local farmId = vehicle:getActiveFarm()
	if self.sourceObject ~= nil then
		local sourceFuelFillLevel = self.sourceObject:getFillUnitFillLevel(self.fillUnitIndex)
		if 0 < sourceFuelFillLevel and g_currentMission.accessHandler:canFarmAccess(farmId, self.sourceObject) then
			delta = math.min(delta, sourceFuelFillLevel)
			if delta <= 0 then
				return 0
			end
			local fillType = self:getCurrentFillType()
			local fillUnitIndex = nil
			if self.vehicleToFillUnitIndices[vehicle] ~= nil then
				for _, _fillUnitIndex in pairs(self.vehicleToFillUnitIndices[vehicle]) do
					if vehicle:getFillUnitCanBeFilled(_fillUnitIndex, fillType) then
						fillUnitIndex = _fillUnitIndex
						break
					end
				end
			end
			if fillUnitIndex == nil then
				return 0
			else
				if vehicle.getCustomFillTriggerSpeedFactor ~= nil then
					delta = delta * vehicle:getCustomFillTriggerSpeedFactor(self, fillUnitIndex, fillType)
				end
				delta = vehicle:addFillUnitFillLevel(farmId, fillUnitIndex, delta, fillType, ToolType.TRIGGER, nil)
				if 0 < delta then
					if self.sourceObject ~= nil then
						self.sourceObject:addFillUnitFillLevel(farmId, self.fillUnitIndex, -delta, fillType, ToolType.TRIGGER, nil)
						return delta
					end
					local price = delta * g_currentMission.economyManager:getPricePerLiter(fillType)
					g_farmManager:updateFarmStats(farmId, "expenses", price)
					g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true)
				end
				return delta
			end
		end
		return 0
	end
end
function FillTrigger:getIsActivatable(vehicle)
	if self.sourceObject ~= nil and (0 < self.sourceObject:getFillUnitFillLevel(self.fillUnitIndex) and g_currentMission.accessHandler:canFarmAccess(vehicle:getActiveFarm(), self.sourceObject)) then
		return true
	end
	return false
end
function FillTrigger:fillTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) then
		local vehicle = g_currentMission:getNodeObject(otherId)
		if vehicle ~= nil and (vehicle.addFillUnitTrigger ~= nil and (vehicle.removeFillUnitTrigger ~= nil and (vehicle ~= self and vehicle ~= self.sourceObject))) then
			local count = Utils.getNoNil(self.vehiclesTriggerCount[vehicle], 0)
			if onEnter then
				local fillType = self:getCurrentFillType()
				local fillUnitIndex = vehicle:getFillUnitIndexFromNode(otherId)
				if fillUnitIndex ~= nil and not vehicle:getFillUnitCanBeFilled(fillUnitIndex, fillType) then
					fillUnitIndex = nil
				end
				if fillUnitIndex ~= nil then
					self.vehiclesTriggerCount[vehicle] = count + 1
					if self.vehicleToFillUnitIndices[vehicle] == nil then
						self.vehicleToFillUnitIndices[vehicle] = {}
					end
					self.vehicleToFillUnitIndices[vehicle][otherId] = fillUnitIndex
					if count == 0 then
						vehicle:addFillUnitTrigger(self, fillType, fillUnitIndex)
					end
				end
			else
				self.vehiclesTriggerCount[vehicle] = count - 1
				if self.vehicleToFillUnitIndices[vehicle] ~= nil then
					self.vehicleToFillUnitIndices[vehicle][otherId] = nil
					if next(self.vehicleToFillUnitIndices[vehicle]) == nil then
						self.vehicleToFillUnitIndices[vehicle] = nil
					end
				end
				if count <= 1 then
					self.vehiclesTriggerCount[vehicle] = nil
					vehicle:removeFillUnitTrigger(self)
					if self.moneyChangeType ~= nil then
						g_currentMission:showMoneyChange(self.moneyChangeType, nil, false, vehicle:getActiveFarm())
					end
				end
			end
		end
	end
end
function FillTrigger:getCurrentFillType()
	if self.sourceObject ~= nil then
		return self.sourceObject:getFillUnitFillType(self.fillUnitIndex)
	else
		return self.fillTypeIndex
	end
end
function FillTrigger:setFillSoundIsPlaying(state)
	if state then
		local sharedSample = g_fillTypeManager:getSampleByFillType(self:getCurrentFillType())
		if sharedSample ~= nil then
			if sharedSample ~= self.sharedSample then
				if self.sample ~= nil then
					g_soundManager:deleteSample(self.sample)
				end
				self.sample = g_soundManager:cloneSample(sharedSample, self.soundNode, self)
				self.sharedSample = sharedSample
				g_soundManager:playSample(self.sample)
				return
			end
			if not g_soundManager:getIsSamplePlaying(self.sample) then
				g_soundManager:playSample(self.sample)
			end
		end
	elseif g_soundManager:getIsSamplePlaying(self.sample) then
		g_soundManager:stopSample(self.sample)
	end
end
