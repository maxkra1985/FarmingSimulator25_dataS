-- Local values: AIDriveStrategyCombine_mt
AIDriveStrategyCombine = {}
local AIDriveStrategyCombine_mt = Class(AIDriveStrategyCombine, AIDriveStrategy)

-- Upvalues: AIDriveStrategyCombine_mt
-- Local values: self
function AIDriveStrategyCombine.new(reconstructionData, customMt)
	-- upvalues: (copy) AIDriveStrategyCombine_mt
	local v4_ = AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyCombine_mt)
	v4_.combines = {}
	v4_.notificationFullGrainTankShown = false
	v4_.notificationGrainTankWarningShown = false
	v4_.beaconLightsActive = false
	v4_.slowDownFillLevel = 200
	v4_.slowDownStartSpeed = 20
	v4_.forageHarvesterFoundTimer = 0
	v4_.waitForStrawModeActive = false
	v4_.waitForStrawModeStartPosition = { 0, 0 }
	v4_.waitForStrawModeLastPosition = { 0, 0 }
	v4_.waitForStrawModeReturnToStart = false
	v4_.waitForStrawModeReturnToStartDistance = 0
	return v4_
end

-- Local values: _, childVehicle
function AIDriveStrategyCombine:setAIVehicle(vehicle)
	AIDriveStrategyCombine:superClass().setAIVehicle(self, vehicle)
	for _, v7_ in pairs(self.vehicle.rootVehicle.childVehicles) do
		if SpecializationUtil.hasSpecialization(Combine, v7_.specializations) then
			local v8_ = self.combines
			table.insert(v8_, v7_)
		end
	end
end

-- Local values: _, combine, capacity, dischargeNode, rootVehicle, trailer, trailerFillUnitIndex, fillType
function AIDriveStrategyCombine:update(dt)
	for _, v10_ in pairs(self.combines) do
		if v10_.spec_pipe ~= nil then
			local v11_ = v10_:getCurrentDischargeNode()
			if (v11_ == nil and 0 or v10_:getFillUnitCapacity(v11_.fillUnitIndex)) == math.huge then
				local v12_ = self.vehicle.rootVehicle
				if v12_.getAIFieldWorkerIsTurning ~= nil and not v12_:getAIFieldWorkerIsTurning() then
					local v13_ = NetworkUtil.getObject(v10_.spec_pipe.nearestObjectInTriggers.objectId)
					if v13_ ~= nil then
						local v14_ = v10_.spec_pipe.nearestObjectInTriggers.fillUnitIndex
						if v10_:getDischargeFillType(v11_) == FillType.UNKNOWN then
							local v15_ = v13_:getFillUnitFillType(v14_)
							if v15_ == FillType.UNKNOWN then
								v15_ = v13_:getFillUnitFirstSupportedFillType(v14_)
							end
							v10_:setForcedFillTypeIndex(v15_)
						else
							v10_:setForcedFillTypeIndex(nil)
						end
					end
				end
			end
		end
	end
end

-- Local values: rootVehicle, isTurning, isCornerCutOutActive, allowedToDrive, waitForStraw, maxSpeed, _, combine, trailerInTrigger, invalidTrailerInTrigger, fillLevel, capacity, dischargeNode, trailer, currentPipeTargetState, currentPipeState, turnOnAllowedStates, targetObject, _, pipeState, i, implement, i, implement, freeFillLevel, spec_combine, i, slot, fillLevel, i, implement, x, _, z, dist, movedDistance, x, z, dist
function AIDriveStrategyCombine:getDriveData(dt, vX, vY, vZ)
	local v19_ = self.vehicle.rootVehicle
	local v20_
	if v19_.getAIFieldWorkerIsTurning == nil then
		v20_ = false
	else
		v20_ = v19_:getAIFieldWorkerIsTurning()
	end
	local v21_
	if v19_.getAIFieldWorkerIsCornerCutOutActive == nil then
		v21_ = false
	else
		v21_ = v19_:getAIFieldWorkerIsCornerCutOutActive()
	end
	local v22_ = true
	local v23_ = false
	local v24_ = math.huge
	for _, v25_ in pairs(self.combines) do
		if v25_.spec_pipe == nil then
			if v25_:getFillUnitFillLevel(v25_.spec_combine.fillUnitIndex) < 0.1 and (not v25_:getIsTurnedOn() and v25_:getCanBeTurnedOn()) then
				v25_:aiImplementStartLine()
				for _, v26_ in ipairs(self.vehicle:getAttachedAIImplements()) do
					v26_.object:aiImplementStartLine()
				end
			end
		else
			local v27_ = false
			local v28_ = false
			local v29_ = v25_:getCurrentDischargeNode()
			local v30_, v31_
			if v29_ == nil then
				v30_ = 0
				v31_ = 0
			else
				v30_ = v25_:getFillUnitFillLevel(v29_.fillUnitIndex)
				v31_ = v25_:getFillUnitCapacity(v29_.fillUnitIndex)
			end
			local v32_ = NetworkUtil.getObject(v25_.spec_pipe.nearestObjectInTriggers.objectId) ~= nil and true or v27_
			local v33_ = v25_.spec_pipe.nearestObjectInTriggerIgnoreFillLevel and true or v28_
			local v34_ = v25_.spec_pipe.targetState
			local v35_ = v25_.spec_pipe.currentState
			local v36_ = v25_.spec_pipe.turnOnAllowedStates
			if next(v36_) == nil then
				v36_ = nil
			end
			if v31_ == math.huge then
				if v34_ ~= 2 then
					v25_:setPipeState(2)
				end
				if not (v20_ or v21_) then
					local v37_, _ = v25_:getDischargeTargetObject(v29_)
					if v32_ then
						v22_ = v37_ ~= nil
					else
						v22_ = v32_
					end
					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						if v32_ then
							if v32_ and v37_ == nil then
								self.vehicle:addAIDebugText("COMBINE -> Waiting for pipe hitting the trailer")
							end
						else
							self.vehicle:addAIDebugText("COMBINE -> Waiting for trailer enter the trigger")
						end
					end
				end
			else
				if 0.8 * v31_ < v30_ then
					if not self.beaconLightsActive then
						self.vehicle:setAIMapHotspotBlinking(true)
						self.vehicle:setBeaconLightsVisibility(true)
						self.beaconLightsActive = true
					end
					if not self.notificationGrainTankWarningShown and self.vehicle:getOwnerFarmId() == g_localPlayer.farmId then
						g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ai_messageErrorTankIsNearlyFull"), self.vehicle:getCurrentHelper().name))
						self.notificationGrainTankWarningShown = true
					end
				else
					if self.beaconLightsActive then
						self.vehicle:setAIMapHotspotBlinking(false)
						self.vehicle:setBeaconLightsVisibility(false)
						self.beaconLightsActive = false
					end
					self.notificationGrainTankWarningShown = false
				end
				local v38_
				if v30_ == v31_ then
					v38_ = 2
					self.wasCompletelyFull = true
					if not self.notificationFullGrainTankShown and self.vehicle:getOwnerFarmId() == g_localPlayer.farmId then
						g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ai_messageErrorTankIsFull"), self.vehicle:getCurrentHelper().name))
						self.notificationFullGrainTankShown = true
					end
				else
					self.notificationFullGrainTankShown = false
					v38_ = v34_
				end
				if v32_ then
					v38_ = (v36_ == nil or v36_[2] == true) and 2 or (v30_ > 0.1 and 2 or v38_)
				end
				if not v32_ and v30_ < v31_ * 0.8 then
					self.wasCompletelyFull = false
					if not v25_:getIsTurnedOn() and v25_:getCanBeTurnedOn() then
						v25_:aiImplementStartLine()
						for _, v39_ in ipairs(self.vehicle:getAttachedAIImplements()) do
							v39_.object:aiImplementStartLine()
						end
					end
				end
				local v40_ = not v32_ and (not v33_ and v30_ < v31_) and 1 or v38_
				if v30_ < 0.1 then
					if not v25_.spec_pipe.aiFoldedPipeUsesTrailerSpace then
						v40_ = not (v32_ or v33_) and 1 or v40_
						if not v25_:getIsTurnedOn() and v25_:getCanBeTurnedOn() then
							v25_:aiImplementStartLine()
							for _, v41_ in ipairs(self.vehicle:getAttachedAIImplements()) do
								v41_.object:aiImplementStartLine()
							end
						end
					end
					self.wasCompletelyFull = false
				end
				if v34_ ~= v40_ then
					v25_:setPipeState(v40_)
				end
				v22_ = v30_ < v31_
				if v36_ ~= nil and v36_[v35_] ~= true then
					v22_ = false
					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						self.vehicle:addAIDebugText("COMBINE -> Stopping AI because we cannot overload while harvesting")
					end
				end
				if v40_ == 2 and self.wasCompletelyFull then
					v22_ = false
					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						self.vehicle:addAIDebugText("COMBINE -> Waiting for trailer to unload")
					end
				end
				local v42_ = v31_ - v30_
				if v42_ < self.slowDownFillLevel then
					v24_ = 2 + v42_ / self.slowDownFillLevel * self.slowDownStartSpeed
					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						self.vehicle:addAIDebugText(string.format("COMBINE -> Slow down because nearly full: %.2f", v24_))
					end
				end
			end
			if v20_ and (v32_ and (v31_ ~= math.huge and v25_:getCanDischargeToObject(v29_))) then
				local v43_ = v25_.spec_combine
				if v43_.loadingDelay > 0 then
					for v44_ = 1, #v43_.loadingDelaySlots do
						local v45_ = v43_.loadingDelaySlots[v44_]
						if v45_.valid then
							v30_ = v30_ + v45_.fillLevelDelta
						end
					end
				end
				if v30_ > 0 then
					v22_ = false
				end
				if VehicleDebug.state == VehicleDebug.DEBUG_AI and not v22_ then
					self.vehicle:addAIDebugText("COMBINE -> Unload to trailer on headland")
				end
			end
			if not v32_ and (v25_.spec_combine.isSwathActive and v25_.spec_combine.strawPSenabled) then
				v23_ = true
			end
		end
	end
	if v20_ and v23_ then
		if not self.waitForStrawModeActive then
			self.waitForStrawModeActive = true
			local v46_ = self.waitForStrawModeStartPosition
			local v47_ = self.waitForStrawModeStartPosition
			v46_[1] = vX
			v47_[2] = vZ
		end
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			self.vehicle:addAIDebugText("COMBINE -> Waiting for straw to drop")
		end
		local v48_, _, v49_ = localToWorld(self.vehicle:getAIDirectionNode(), 0, 0, -10)
		return v48_, v49_, false, 6, MathUtil.vector2Length(vX - v48_, vZ - v49_)
	else
		if self.waitForStrawModeActive then
			self.waitForStrawModeActive = false
			self.waitForStrawModeReturnToStart = true
			local v50_ = self.waitForStrawModeLastPosition
			local v51_ = self.waitForStrawModeLastPosition
			v50_[1] = vX
			v51_[2] = vZ
			self.waitForStrawModeReturnToStartDistance = MathUtil.vector2Length(vX - self.waitForStrawModeStartPosition[1], vZ - self.waitForStrawModeStartPosition[2])
		end
		if self.waitForStrawModeReturnToStart then
			local v52_ = MathUtil.vector2Length(vX - self.waitForStrawModeLastPosition[1], vZ - self.waitForStrawModeLastPosition[2])
			local v53_ = self.waitForStrawModeLastPosition
			local v54_ = self.waitForStrawModeLastPosition
			v53_[1] = vX
			v54_[2] = vZ
			self.waitForStrawModeReturnToStartDistance = self.waitForStrawModeReturnToStartDistance - v52_
			if self.waitForStrawModeReturnToStartDistance >= 0 then
				if VehicleDebug.state == VehicleDebug.DEBUG_AI then
					self.vehicle:addAIDebugText(string.format("COMBINE -> Returning to turn start position (%.1fm)", self.waitForStrawModeReturnToStartDistance))
				end
				local v55_ = self.waitForStrawModeStartPosition[1]
				local v56_ = self.waitForStrawModeStartPosition[2]
				return v55_, v56_, true, 10, MathUtil.vector2Length(vX - v55_, vZ - v56_)
			end
			self.waitForStrawModeReturnToStart = false
		end
		if v22_ then
			return nil, nil, nil, v24_, nil
		else
			return 0, 1, true, 0, math.huge
		end
	end
end

function AIDriveStrategyCombine:updateDriving(dt) end
