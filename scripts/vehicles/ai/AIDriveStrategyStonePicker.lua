-- Local values: AIDriveStrategyStonePicker_mt
AIDriveStrategyStonePicker = {}
local AIDriveStrategyStonePicker_mt = Class(AIDriveStrategyStonePicker, AIDriveStrategy)

-- Upvalues: AIDriveStrategyStonePicker_mt
-- Local values: self
function AIDriveStrategyStonePicker.new(reconstructionData, customMt)
	-- upvalues: (copy) AIDriveStrategyStonePicker_mt
	local v4_ = AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyStonePicker_mt)
	v4_.stonePickers = {}
	v4_.notificationFullTankShown = false
	return v4_
end

-- Local values: _, implement
function AIDriveStrategyStonePicker:setAIVehicle(vehicle)
	AIDriveStrategyStonePicker:superClass().setAIVehicle(self, vehicle)
	if SpecializationUtil.hasSpecialization(StonePicker, self.vehicle.specializations) then
		local v7_ = self.stonePickers
		local v8_ = self.vehicle
		table.insert(v7_, v8_)
	end
	for _, v9_ in pairs(self.vehicle:getAttachedAIImplements()) do
		if SpecializationUtil.hasSpecialization(StonePicker, v9_.object.specializations) then
			local v10_ = self.stonePickers
			local v11_ = v9_.object
			table.insert(v10_, v11_)
		end
	end
end

function AIDriveStrategyStonePicker:update(dt) end

-- Local values: allowedToDrive, maxSpeed, _, stonePicker, spec, fillLevel, capacity, dischargeNode, targetObject, _, dischargeNode, targetObject, _
function AIDriveStrategyStonePicker:getDriveData(dt, vX, vY, vZ)
	local v13_ = true
	for _, v14_ in pairs(self.stonePickers) do
		local v15_ = v14_.spec_stonePicker
		local v16_ = v14_:getFillUnitFillLevel(v15_.fillUnitIndex)
		local v17_ = v14_:getFillUnitCapacity(v15_.fillUnitIndex)
		if v14_.getDischargeState ~= nil and v14_:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF then
			v13_ = false
			local v18_ = v14_:getCurrentDischargeNode()
			if v18_ ~= nil then
				local v19_, _ = v14_:getDischargeTargetObject(v18_)
				if v19_ == nil or v16_ <= 0 then
					v14_:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
				end
			end
		end
		if v14_.getTipState ~= nil and v14_:getTipState() ~= Trailer.TIPSTATE_CLOSED then
			v13_ = false
		end
		if v17_ <= v16_ then
			v13_ = false
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self.vehicle:addAIDebugText(string.format("STONE PICKER -> full"))
			end
			if self.notificationFullTankShown ~= true then
				g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ai_messageErrorTankIsFull"), self.vehicle:getCurrentHelper().name))
				self.notificationFullTankShown = true
			end
			if v14_.getCurrentDischargeNode ~= nil then
				local v20_ = v14_:getCurrentDischargeNode()
				if v20_ ~= nil then
					local v21_, _ = v14_:getDischargeTargetObject(v20_)
					if v21_ ~= nil then
						v14_:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
					end
				end
			end
		else
			self.notificationFullTankShown = false
		end
	end
	if v13_ then
		return nil, nil, nil, math.huge, nil
	else
		return 0, 1, true, 0, math.huge
	end
end

function AIDriveStrategyStonePicker:updateDriving(dt) end
