-- Local values: FillTrigger_mt
FillTrigger = {}
FillTrigger.TRIGGER_MASK = CollisionFlag.FILLABLE
local FillTrigger_mt = Class(FillTrigger)

-- Local values: fillTrigger, moneyChangeType
function FillTrigger:onCreate(id)
	local v3_ = FillTrigger.new(id)
	v3_:setMoneyChangeType((MoneyType.register("other", "finance_purchaseFuel")))
	g_currentMission:addNonUpdateable(v3_)
end

-- Upvalues: FillTrigger_mt
-- Local values: self
function FillTrigger.new(id, sourceObject, fillUnitIndex, fillLitersPerSecond, defaultFillType, customMt)
	-- upvalues: (copy) FillTrigger_mt
	local v9_ = customMt or FillTrigger_mt
	local v10_ = setmetatable({}, v9_)
	v10_.customEnvironment = g_currentMission.loadingMapModName
	v10_.triggerId = id
	addTrigger(id, "fillTriggerCallback", v10_)
	v10_.soundNode = createTransformGroup("fillTriggerSoundNode")
	link(getParent(id), v10_.soundNode)
	setTranslation(v10_.soundNode, getTranslation(id))
	v10_.sourceObject = sourceObject
	v10_.vehiclesTriggerCount = {}
	v10_.vehicleToFillUnitIndices = {}
	v10_.fillUnitIndex = fillUnitIndex
	v10_.fillLitersPerSecond = fillLitersPerSecond
	v10_.isEnabled = true
	v10_.fillTypeIndex = FillType.DIESEL
	return v10_
end

function FillTrigger:setMoneyChangeType(moneyChangeType)
	self.moneyChangeType = moneyChangeType
end

-- Local values: vehicle, count
function FillTrigger:delete()
	for v14_, v15_ in pairs(self.vehiclesTriggerCount) do
		if v15_ > 0 and v14_.removeFillUnitTrigger ~= nil then
			v14_:removeFillUnitTrigger(self)
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

-- Local values: farmId, sourceFuelFillLevel, fillType, fillUnitIndex, _, _fillUnitIndex, price
function FillTrigger:fillVehicle(vehicle, delta, dt)
	if self.fillLitersPerSecond ~= nil then
		local v22_ = self.fillLitersPerSecond * 0.001 * dt
		delta = math.min(delta, v22_)
	end
	local v23_ = vehicle:getActiveFarm()
	if self.sourceObject ~= nil then
		local v24_ = self.sourceObject:getFillUnitFillLevel(self.fillUnitIndex)
		if v24_ <= 0 or not g_currentMission.accessHandler:canFarmAccess(v23_, self.sourceObject) then
			return 0
		end
		delta = math.min(delta, v24_)
		if delta <= 0 then
			return 0
		end
	end
	local v25_ = self:getCurrentFillType()
	local v26_ = nil
	if self.vehicleToFillUnitIndices[vehicle] ~= nil then
		for _, v27_ in pairs(self.vehicleToFillUnitIndices[vehicle]) do
			if vehicle:getFillUnitCanBeFilled(v27_, v25_) then
				v26_ = v27_
				break
			end
		end
	end
	if v26_ == nil then
		return 0
	end
	if vehicle.getCustomFillTriggerSpeedFactor ~= nil then
		delta = delta * vehicle:getCustomFillTriggerSpeedFactor(self, v26_, v25_)
	end
	local v28_ = vehicle:addFillUnitFillLevel(v23_, v26_, delta, v25_, ToolType.TRIGGER, nil)
	if v28_ > 0 then
		if self.sourceObject ~= nil then
			self.sourceObject:addFillUnitFillLevel(v23_, self.fillUnitIndex, -v28_, v25_, ToolType.TRIGGER, nil)
			return v28_
		end
		local v29_ = v28_ * g_currentMission.economyManager:getPricePerLiter(v25_)
		g_farmManager:updateFarmStats(v23_, "expenses", v29_)
		g_currentMission:addMoney(-v29_, v23_, self.moneyChangeType, true)
	end
	return v28_
end

function FillTrigger:getIsActivatable(vehicle)
	return self.sourceObject ~= nil and (self.sourceObject:getFillUnitFillLevel(self.fillUnitIndex) > 0 and g_currentMission.accessHandler:canFarmAccess(vehicle:getActiveFarm(), self.sourceObject)) and true or false
end

-- Local values: vehicle, count, fillType, fillUnitIndex
function FillTrigger:fillTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) then
		local v36_ = g_currentMission:getNodeObject(otherId)
		if v36_ ~= nil and (v36_.addFillUnitTrigger ~= nil and (v36_.removeFillUnitTrigger ~= nil and (v36_ ~= self and v36_ ~= self.sourceObject))) then
			local v37_ = Utils.getNoNil(self.vehiclesTriggerCount[v36_], 0)
			if onEnter then
				local v38_ = self:getCurrentFillType()
				local v39_ = v36_:getFillUnitIndexFromNode(otherId)
				if v39_ ~= nil and not v36_:getFillUnitCanBeFilled(v39_, v38_) then
					v39_ = nil
				end
				if v39_ ~= nil then
					self.vehiclesTriggerCount[v36_] = v37_ + 1
					if self.vehicleToFillUnitIndices[v36_] == nil then
						self.vehicleToFillUnitIndices[v36_] = {}
					end
					self.vehicleToFillUnitIndices[v36_][otherId] = v39_
					if v37_ == 0 then
						v36_:addFillUnitTrigger(self, v38_, v39_)
						return
					end
				end
			else
				self.vehiclesTriggerCount[v36_] = v37_ - 1
				if self.vehicleToFillUnitIndices[v36_] ~= nil then
					self.vehicleToFillUnitIndices[v36_][otherId] = nil
					if next(self.vehicleToFillUnitIndices[v36_]) == nil then
						self.vehicleToFillUnitIndices[v36_] = nil
					end
				end
				if v37_ <= 1 then
					self.vehiclesTriggerCount[v36_] = nil
					v36_:removeFillUnitTrigger(self)
					if self.moneyChangeType ~= nil then
						g_currentMission:showMoneyChange(self.moneyChangeType, nil, false, v36_:getActiveFarm())
					end
				end
			end
		end
	end
end

function FillTrigger:getCurrentFillType()
	if self.sourceObject == nil then
		return self.fillTypeIndex
	else
		return self.sourceObject:getFillUnitFillType(self.fillUnitIndex)
	end
end

-- Local values: sharedSample
function FillTrigger:setFillSoundIsPlaying(state)
	if state then
		local v43_ = g_fillTypeManager:getSampleByFillType(self:getCurrentFillType())
		if v43_ ~= nil then
			if v43_ ~= self.sharedSample then
				if self.sample ~= nil then
					g_soundManager:deleteSample(self.sample)
				end
				self.sample = g_soundManager:cloneSample(v43_, self.soundNode, self)
				self.sharedSample = v43_
				g_soundManager:playSample(self.sample)
				return
			end
			if not g_soundManager:getIsSamplePlaying(self.sample) then
				g_soundManager:playSample(self.sample)
				return
			end
		end
	elseif g_soundManager:getIsSamplePlaying(self.sample) then
		g_soundManager:stopSample(self.sample)
	end
end
