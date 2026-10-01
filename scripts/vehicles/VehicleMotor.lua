VehicleMotor = {}
local VehicleMotor_mt = Class(VehicleMotor)
VehicleMotor.DAMAGE_TORQUE_REDUCTION = 0.3
VehicleMotor.DEFAULT_DAMPING_RATE_FULL_THROTTLE = 0.00025
VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_EN = 0.0015
VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_DIS = 0.0015
VehicleMotor.GEAR_START_THRESHOLD = 1.5
VehicleMotor.REASON_CLUTCH_NOT_ENGAGED = 0
VehicleMotor.SHIFT_MODE_AUTOMATIC = 1
VehicleMotor.SHIFT_MODE_MANUAL = 2
VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH = 3
VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC = 1
VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL = 2
VehicleMotor.TRANSMISSION_TYPE = {}
VehicleMotor.TRANSMISSION_TYPE.DEFAULT = 1
VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT = 2
local MODULATION_SPEED = 0.0009
local MODULATION_RPM_MAX_OFFSET = 150
local MODULATION_RPM_MIN_REF_LOAD = 0.1
local MODULATION_RPM_MAX_REF_LOAD = 1
local MODULATION_RPM_MIN_INTENSITY = 0.01
local MODULATION_LOAD_MAX_OFFSET = 0.05
local MODULATION_LOAD_MIN_REF_LOAD = 0
local MODULATION_LOAD_MAX_REF_LOAD = 0.5
local MODULATION_LOAD_MIN_INTENSITY = 0
local MAX_ACCELERATION_LOAD = 0.8
function VehicleMotor.new(vehicle, minRpm, maxRpm, maxForwardSpeed, maxBackwardSpeed, torqueCurve, brakeForce, forwardGears, backwardGears, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, ptoMotorRpmRatio, minSpeed)
	local self = setmetatable({}, VehicleMotor_mt)
	self.vehicle = vehicle
	self.minRpm = minRpm
	self.maxRpm = maxRpm
	self.minSpeed = minSpeed
	self.maxForwardSpeed = maxForwardSpeed
	self.maxBackwardSpeed = maxBackwardSpeed
	self.maxClutchTorque = 5
	self.torqueCurve = torqueCurve
	self.brakeForce = brakeForce
	self.lastAcceleratorPedal = 0
	self.idleGearChangeTimer = 0
	self.doSecondBestGearSelection = 0
	self.gear = 0
	self.bestGearSelected = 0
	self.minGearRatio = 0
	self.maxGearRatio = 0
	self.allowGearChangeTimer = 0
	self.allowGearChangeDirection = 0
	self.forwardGears = forwardGears
	self.backwardGears = backwardGears
	self.currentGears = self.forwardGears
	self.minForwardGearRatio = minForwardGearRatio
	self.maxForwardGearRatio = maxForwardGearRatio
	self.minBackwardGearRatio = minBackwardGearRatio
	self.maxBackwardGearRatio = maxBackwardGearRatio
	self.transmissionDirection = 1
	self.maxClutchSpeedDifference = 0
	self.defaultForwardGear = 1
	if self.forwardGears ~= nil then
		for i = 1, #self.forwardGears do
			self.maxClutchSpeedDifference = math.max(self.maxClutchSpeedDifference, self.minRpm / self.forwardGears[i].ratio * 3.141592653589793 / 30)
			if self.forwardGears[i].default then
				self.defaultForwardGear = i
			end
		end
	end
	self.defaultBackwardGear = 1
	if self.backwardGears ~= nil then
		for i = 1, #self.backwardGears do
			self.maxClutchSpeedDifference = math.max(self.maxClutchSpeedDifference, self.minRpm / self.backwardGears[i].ratio * 3.141592653589793 / 30)
			if self.backwardGears[i].default then
				self.defaultBackwardGear = i
			end
		end
	end
	self.gearType = VehicleMotor.TRANSMISSION_TYPE.DEFAULT
	self.groupType = VehicleMotor.TRANSMISSION_TYPE.DEFAULT
	self.manualTargetGear = nil
	self.targetGear = 0
	self.previousGear = 0
	self.gearChangeTimer = -1
	self.gearChangeTime = 250
	self.gearChangeTimeOrig = self.gearChangeTime
	self.autoGearChangeTimer = -1
	self.autoGearChangeTime = 1000
	self.manualClutchValue = 0
	self.stallTimer = 0
	self.lastGearChangeTime = 0
	self.gearChangeTimeAutoReductionTime = 500
	self.gearChangeTimeAutoReductionTimer = 0
	self.lastManualShifterActive = false
	self.clutchSlippingTime = 1000
	self.clutchSlippingTimer = 0
	self.clutchSlippingGearRatio = 0
	self.groupChangeTime = 500
	self.groupChangeTimer = 0
	self.gearGroupUpShiftTime = 3000
	self.gearGroupUpShiftTimer = 0
	self.currentDirection = 1
	self.directionChangeTimer = 0
	self.directionChangeTime = 500
	self.directionChangeUseGear = false
	self.directionChangeGearIndex = 1
	self.directionLastGear = -1
	self.directionChangeUseGroup = false
	self.directionChangeGroupIndex = 1
	self.directionLastGroup = -1
	self.directionChangeUseInverse = true
	self.gearChangedIsLocked = false
	self.gearGroupChangedIsLocked = false
	self.startGearValues = { slope = 0, mass = 0, lastMass = 0, maxForce = 0, massDirectionDifferenceXZ = 0, massDirectionDifferenceY = 0, massDirectionFactor = 0, availablePower = 0, massFactor = 0 }
	self.startGearThreshold = VehicleMotor.GEAR_START_THRESHOLD
	self.lastSmoothedClutchPedal = 0
	self.lastRealMotorRpm = 0
	self.lastMotorRpm = 0
	self.lastModulationPercentage = 0
	self.lastModulationTimer = 0
	self.rawLoadPercentage = 0
	self.rawLoadPercentageBuffer = 0
	self.rawLoadPercentageBufferIndex = 0
	self.smoothedLoadPercentage = 0
	self.loadPercentageChangeCharge = 0
	self.accelerationLimitLoadScale = 1
	self.accelerationLimitLoadScaleTimer = 0
	self.accelerationLimitLoadScaleDelay = 2000
	self.constantRpmCharge = 0
	self.constantAccelerationCharge = 0
	self.lastTurboScale = 0
	self.blowOffValveState = 0
	self.overSpeedTimer = 0
	self.rpmLimit = math.huge
	self.speedLimit = math.huge
	self.speedLimitAcc = math.huge
	self.accelerationLimit = 2
	self.motorRotationAccelerationLimit = (maxRpm - minRpm) * 3.141592653589793 / 30 / 2
	self.equalizedMotorRpm = 0
	self.requiredMotorPower = 0
	if self.maxForwardSpeed == nil then
		self.maxForwardSpeed = self:calculatePhysicalMaximumForwardSpeed()
	end
	if self.maxBackwardSpeed == nil then
		self.maxBackwardSpeed = self:calculatePhysicalMaximumBackwardSpeed()
	end
	self.maxForwardSpeedOrigin = self.maxForwardSpeed
	self.maxBackwardSpeedOrigin = self.maxBackwardSpeed
	self.minForwardGearRatioOrigin = self.minForwardGearRatio
	self.maxForwardGearRatioOrigin = self.maxForwardGearRatio
	self.minBackwardGearRatioOrigin = self.minBackwardGearRatio
	self.maxBackwardGearRatioOrigin = self.maxBackwardGearRatio
	self.peakMotorTorque = self.torqueCurve:getMaximum()
	self.peakMotorPower = 0
	self.peakMotorPowerRotSpeed = 0
	local numKeyFrames = #self.torqueCurve.keyframes
	if 2 <= numKeyFrames then
		for i = 2, numKeyFrames do
			local v0 = self.torqueCurve.keyframes[i - 1]
			local v1 = self.torqueCurve.keyframes[i]
			local torque0 = self.torqueCurve:getFromKeyframes(v0, v0, i - 1, i - 1, 0)
			local torque1 = self.torqueCurve:getFromKeyframes(v1, v1, i, i, 0)
			local rpm = nil
			local torque = nil
			if 0.0001 < math.abs(torque0 - torque1) then
				rpm = (v1.time * torque0 - v0.time * torque1) / (2 * (torque0 - torque1))
				rpm = math.min(math.max(rpm, v0.time), v1.time)
				torque = self.torqueCurve:getFromKeyframes(v0, v1, i - 1, i, (v1.time - rpm) / (v1.time - v0.time))
			else
				rpm = v0.time
				torque = torque0
			end
			local power = torque * rpm
			if self.peakMotorPower < power then
				self.peakMotorPower = power
				self.peakMotorPowerRotSpeed = rpm
			end
		end
		self.peakMotorPower = self.peakMotorPower * 3.141592653589793 / 30
		self.peakMotorPowerRotSpeed = self.peakMotorPowerRotSpeed * 3.141592653589793 / 30
	else
		local v = self.torqueCurve.keyframes[1]
		local rotSpeed = v.time * 3.141592653589793 / 30
		local torque = self.torqueCurve:getFromKeyframes(v, v, 1, 1, 0)
		self.peakMotorPower = rotSpeed * torque
		self.peakMotorPowerRotSpeed = rotSpeed
	end
	self.ptoMotorRpmRatio = ptoMotorRpmRatio
	self.rotInertia = self.peakMotorTorque / 600
	self.dampingRateFullThrottle = VehicleMotor.DEFAULT_DAMPING_RATE_FULL_THROTTLE
	self.dampingRateZeroThrottleClutchEngaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_EN
	self.dampingRateZeroThrottleClutchDisengaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_DIS
	self.gearRatio = 0
	self.motorRotSpeed = 0
	self.motorRotSpeedClutchEngaged = 0
	self.motorRotAcceleration = 0
	self.motorRotAccelerationSmoothed = 0
	self.motorAvailableTorque = 0
	self.lastMotorAvailableTorque = 0
	self.motorAppliedTorque = 0
	self.lastMotorAppliedTorque = 0
	self.motorExternalTorque = 0
	self.lastMotorExternalTorque = 0
	self.externalTorqueVirtualMultiplicator = 1
	self.differentialRotSpeed = 0
	self.differentialRotAcceleration = 0
	self.differentialRotAccelerationSmoothed = 0
	self.differentialRotAccelerationIndex = 1
	self.differentialRotAccelerationSamples = {}
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	table.insert(self.differentialRotAccelerationSamples, 0)
	self.lastDifference = 0
	self.directionChangeMode = g_gameSettings:getValue(GameSettings.SETTING.DIRECTION_CHANGE_MODE)
	self.gearShiftMode = g_gameSettings:getValue(GameSettings.SETTING.GEAR_SHIFT_MODE)
	return self
end
function VehicleMotor:postLoad(savegame)
	if self.gearGroups ~= nil then
		SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, 0)
	end
end
function VehicleMotor:delete()
	g_messageCenter:unsubscribeAll(self)
end
function VehicleMotor:setGearGroups(gearGroups, groupType, groupChangeTime)
	self.gearGroups = gearGroups
	self.groupType = VehicleMotor.TRANSMISSION_TYPE[string.upper(groupType)] or VehicleMotor.TRANSMISSION_TYPE.DEFAULT
	self.groupChangeTime = groupChangeTime
	if gearGroups ~= nil then
		self.numGearGroups = #gearGroups
		self.defaultGearGroup = 1
		for i = 1, self.numGearGroups do
			if 0 < self.gearGroups[i].ratio then
				self.defaultGearGroup = i
				break
			end
		end
		for i = 1, self.numGearGroups do
			if self.gearGroups[i].isDefault then
				self.defaultGearGroup = i
				break
			end
		end
		self.activeGearGroupIndex = self.defaultGearGroup
	end
end
function VehicleMotor:setDirectionChange(directionChangeUseGear, directionChangeGearIndex, directionChangeUseGroup, directionChangeGroupIndex, directionChangeTime)
	self.directionChangeUseGear = directionChangeUseGear
	self.directionChangeGearIndex = directionChangeGearIndex
	self.directionChangeUseGroup = directionChangeUseGroup
	self.directionChangeGroupIndex = directionChangeGroupIndex
	self.directionChangeTime = directionChangeTime
	self.directionChangeUseInverse = not directionChangeUseGear and not directionChangeUseGroup
end
function VehicleMotor:setManualShift(manualShiftGears, manualShiftGroups)
	self.manualShiftGears = manualShiftGears
	self.manualShiftGroups = manualShiftGroups
end
function VehicleMotor:setStartGearThreshold(startGearThreshold)
	self.startGearThreshold = startGearThreshold
end
function VehicleMotor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit)
	self.lowBrakeForceScale = lowBrakeForceScale
	self.lowBrakeForceSpeedLimit = lowBrakeForceSpeedLimit
end
function VehicleMotor:getMaxClutchTorque()
	return self.maxClutchTorque
end
function VehicleMotor:getRotInertia()
	return self.rotInertia
end
function VehicleMotor:setRotInertia(rotInertia)
	self.rotInertia = rotInertia
end
function VehicleMotor:getDampingRateFullThrottle()
	return self.dampingRateFullThrottle
end
function VehicleMotor:getDampingRateZeroThrottleClutchEngaged()
	return self.dampingRateZeroThrottleClutchEngaged
end
function VehicleMotor:getDampingRateZeroThrottleClutchDisengaged()
	return self.dampingRateZeroThrottleClutchDisengaged
end
function VehicleMotor:setDampingRateScale(dampingRateScale)
	self.dampingRateFullThrottle = VehicleMotor.DEFAULT_DAMPING_RATE_FULL_THROTTLE * dampingRateScale
	self.dampingRateZeroThrottleClutchEngaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_EN * dampingRateScale
	self.dampingRateZeroThrottleClutchDisengaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_DIS * dampingRateScale
end
function VehicleMotor:setGearChangeTime(gearChangeTime)
	self.gearChangeTime = gearChangeTime
	self.gearChangeTimeOrig = gearChangeTime
	self.gearChangeTimer = math.min(self.gearChangeTimer, gearChangeTime)
	self.gearType = gearChangeTime == 0 and VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT or VehicleMotor.TRANSMISSION_TYPE.DEFAULT
end
function VehicleMotor:setAutoGearChangeTime(autoGearChangeTime)
	self.autoGearChangeTime = autoGearChangeTime
	self.autoGearChangeTimer = math.min(self.autoGearChangeTimer, autoGearChangeTime)
end
function VehicleMotor:getPeakTorque()
	return self.peakMotorTorque
end
function VehicleMotor:getBrakeForce()
	return self.brakeForce
end
function VehicleMotor:getMinRpm()
	return self.minRpm
end
function VehicleMotor:getMaxRpm()
	return self.maxRpm
end
function VehicleMotor:getRequiredMotorRpmRange()
	local motorPtoRpm = math.min(PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio, self.maxRpm)
	if motorPtoRpm ~= 0 then
		return motorPtoRpm, self.maxRpm
	else
		return self.minRpm, self.maxRpm
	end
end
function VehicleMotor:getLastMotorRpm()
	return self.lastMotorRpm
end
function VehicleMotor:getLastModulatedMotorRpm()
	local modulationIntensity = math.clamp((self.smoothedLoadPercentage - 0.1) / 0.9, 0.01, 1)
	local modulationOffset = self.lastModulationPercentage * (150 * modulationIntensity) * self.constantRpmCharge
	local loadChangeChargeDrop = 0
	if self:getClutchPedal() < 0.1 then
		if 0 < self.minGearRatio then
			local rpmRange = self.maxRpm - self.minRpm
			local dropScale = (self.lastMotorRpm - self.minRpm) / rpmRange * 0.5
			loadChangeChargeDrop = self.loadPercentageChangeCharge * rpmRange * dropScale
		else
			self.loadPercentageChangeCharge = 0
		end
	end
	if self.lastMotorRpm == 0 then
		return 0
	else
		return self.lastMotorRpm + modulationOffset - loadChangeChargeDrop
	end
end
function VehicleMotor:getLastRealMotorRpm()
	return self.lastRealMotorRpm
end
function VehicleMotor:getSmoothLoadPercentage()
	local modulationIntensity = math.clamp((self.smoothedLoadPercentage - 0) / 0.5, 0, 1)
	return self.smoothedLoadPercentage - self.lastModulationPercentage * (0.05 * modulationIntensity)
end
function VehicleMotor:getClutchPedal()
	if not self.vehicle.isServer or self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
		return self.manualClutchValue
	end
	local clutchRpm = self:getNonClampedMotorRpm()
	if clutchRpm == 0 then
		return 0
	else
		return 1 - math.max(math.min((self:getClutchRotSpeed() * 30 / 3.141592653589793 + 50) / clutchRpm, 1), 0)
	end
end
function VehicleMotor:getSmoothedClutchPedal()
	return self.lastSmoothedClutchPedal
end
function VehicleMotor:getManualClutchPedal()
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
		return self.manualClutchValue
	else
		return 0
	end
end
function VehicleMotor:getGearToDisplay(isDashboard)
	local gearName = "N"
	if self.backwardGears or self.forwardGears then
		if 0 < self.targetGear then
			local gear = self.currentGears[self.targetGear]
			if gear ~= nil then
				local gearNameDirection = self.currentGears == self.forwardGears and self.currentDirection or 1
				if isDashboard then
					if gearNameDirection == 1 then
						local _v11 = gear.dashboardName or gear.name or gear.dashboardReverseName or gear.reverseName
					end
					gearName = _v11
					return gearName
				else
					gearName = gearNameDirection == 1 and gear.name or gear.reverseName
					return gearName
				end
			end
		end
		return gearName
	end
	local direction = self:getDrivingDirection()
	if 0 < direction then
		gearName = "D"
		return gearName
	elseif direction < 0 then
		gearName = "R"
	end
end
function VehicleMotor:getGearInfoToDisplay()
	local gearName = "N"
	local available = false
	local prevGearName = nil
	local nextGearName = nil
	local prevPrevGearName = nil
	local nextNextGearName = nil
	local isAutomatic = false
	local isGearChanging = false
	if self.backwardGears or self.forwardGears then
		if 0 < self.targetGear then
			local gear = self.currentGears[self.targetGear]
			if gear ~= nil then
				local displayDirection = self.currentDirection
				local gearNameDirection = self.currentGears == self.forwardGears and self.currentDirection or 1
				if gearNameDirection == 1 then
					local _v32 = gear.name or gear.reverseName
				end
				gearName = _v32
				local prevGear = self.currentGears[self.targetGear + 1 * -displayDirection]
				if prevGear ~= nil then
					prevGearName = gearNameDirection == 1 and prevGear.name or prevGear.reverseName
					prevGear = self.currentGears[self.targetGear + 2 * -displayDirection]
					if prevGear ~= nil then
						prevPrevGearName = gearNameDirection == 1 and prevGear.name or prevGear.reverseName
					end
				end
				local nextGear = self.currentGears[self.targetGear + 1 * displayDirection]
				if nextGear ~= nil then
					nextGearName = gearNameDirection == 1 and nextGear.name or nextGear.reverseName
					nextGear = self.currentGears[self.targetGear + 2 * displayDirection]
					if nextGear ~= nil then
						nextNextGearName = gearNameDirection == 1 and nextGear.name or nextGear.reverseName
					end
				end
				if self.gear ~= self.targetGear then
					isGearChanging = true
				end
			end
		end
		available = true
	else
		local direction = self:getDrivingDirection()
		if 0 < direction then
			gearName = "D"
			prevGearName = "N"
		elseif direction < 0 then
			gearName = "R"
			nextGearName = "N"
		else
			nextGearName = "D"
			prevGearName = "R"
		end
		isAutomatic = true
	end
	return gearName, available, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging
end
function VehicleMotor:getDrivingDirection()
	if self.directionChangeMode == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL or self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_AUTOMATIC or self.backwardGears or self.forwardGears then
		return self.currentDirection * self.transmissionDirection
	end
	if 0.95 < self.vehicle:getLastSpeed() then
		return self.vehicle.movingDirection * self.transmissionDirection
	else
		return 0
	end
end
function VehicleMotor:getGearGroupToDisplay(isDashboard)
	local gearGroupName = "N"
	local available = false
	if (self.backwardGears or self.forwardGears) and self.gearGroups ~= nil then
		if 0 < self.activeGearGroupIndex then
			local gearGroup = self.gearGroups[self.activeGearGroupIndex]
			if gearGroup ~= nil then
				if isDashboard then
					gearGroupName = gearGroup.dashboardName or gearGroup.name
				else
					gearGroupName = gearGroup.name
				end
			end
		end
		available = true
	end
	return gearGroupName, available
end
function VehicleMotor:readGearDataFromStream(streamId)
	self.currentDirection = streamReadUIntN(streamId, 2) - 1
	if streamReadBool(streamId) then
		local gear = streamReadUIntN(streamId, 6)
		local changingGear = streamReadBool(streamId)
		if streamReadBool(streamId) then
			self.currentGears = self.forwardGears
		else
			self.currentGears = self.backwardGears
		end
		local activeGearGroupIndex = nil
		if self.gearGroups ~= nil then
			activeGearGroupIndex = streamReadUIntN(streamId, 5)
		end
		if gear ~= self.gear then
			if changingGear and self.gear ~= 0 then
				self.lastGearChangeTime = g_time
			end
			self.previousGear = self.gear
			self.gear = changingGear and 0 or gear
			self.targetGear = gear
			local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
			SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, 0, self.previousGear)
		end
		if activeGearGroupIndex ~= self.activeGearGroupIndex then
			self.activeGearGroupIndex = activeGearGroupIndex
			SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, self.groupType == VehicleMotor.TRANSMISSION_TYPE.DEFAULT and self.groupChangeTime or 0)
		end
	end
end
function VehicleMotor:writeGearDataToStream(streamId)
	streamWriteUIntN(streamId, math.sign(self.currentDirection) + 1, 2)
	if streamWriteBool(streamId, self.backwardGears ~= nil or self.forwardGears ~= nil) then
		streamWriteUIntN(streamId, self.targetGear, 6)
		streamWriteBool(streamId, self.targetGear ~= self.gear)
		streamWriteBool(streamId, self.currentGears == self.forwardGears)
		if self.gearGroups ~= nil then
			streamWriteUIntN(streamId, self.activeGearGroupIndex, 5)
		end
	end
end
function VehicleMotor:setLastRpm(lastRpm)
	local oldMotorRpm = self.lastMotorRpm
	self.lastRealMotorRpm = lastRpm
	local interpolationSpeed = 0.05
	if self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT and g_time - self.lastGearChangeTime < 200 then
		interpolationSpeed = 0.2
	end
	self.lastMotorRpm = self.lastMotorRpm * (1 - interpolationSpeed) + self.lastRealMotorRpm * interpolationSpeed
	local rpmPercentage = (self.lastMotorRpm - math.max(self.lastPtoRpm or self.minRpm, self.minRpm)) / (self.maxRpm - self.minRpm)
	local targetTurboRpm = rpmPercentage * self:getSmoothLoadPercentage()
	self.lastTurboScale = self.lastTurboScale * 0.95 + targetTurboRpm * 0.05
	local blowOffValveState = self.blowOffValveState
	if self.lastAcceleratorPedal == 0 or self.minGearRatio == 0 and 0 < self.autoGearChangeTime then
		self.blowOffValveState = self.lastTurboScale
	else
		self.blowOffValveState = 0
	end
	if 0 < self.blowOffValveState ~= (0 < blowOffValveState) then
		SpecializationUtil.raiseEvent(self.vehicle, "onMotorBlowOffValveChanged", self.blowOffValveState)
	end
	self.constantRpmCharge = 1 - math.min(math.abs(self.lastMotorRpm - oldMotorRpm) * 0.15, 1)
end
function VehicleMotor:getMotorAppliedTorque()
	return self.motorAppliedTorque
end
function VehicleMotor:getMotorExternalTorque()
	return self.motorExternalTorque
end
function VehicleMotor:getMotorAvailableTorque()
	return self.motorAvailableTorque
end
function VehicleMotor:getEqualizedMotorRpm()
	return self.equalizedMotorRpm
end
function VehicleMotor:setEqualizedMotorRpm(rpm)
	self.equalizedMotorRpm = rpm
	self:setLastRpm(rpm)
end
function VehicleMotor:getPtoMotorRpmRatio()
	return self.ptoMotorRpmRatio
end
function VehicleMotor:setExternalTorqueVirtualMultiplicator(externalTorqueVirtualMultiplicator)
	self.externalTorqueVirtualMultiplicator = externalTorqueVirtualMultiplicator or 1
end
function VehicleMotor:getNonClampedMotorRpm()
	return self.motorRotSpeed * 30 / 3.141592653589793
end
function VehicleMotor:getMotorRotSpeed()
	return self.motorRotSpeed
end
function VehicleMotor:getClutchRpm()
	return self.differentialRotSpeed * self.gearRatio * 30 / 3.141592653589793
end
function VehicleMotor:getClutchRotSpeed()
	return self.differentialRotSpeed * self.gearRatio
end
function VehicleMotor:getTorqueCurve()
	return self.torqueCurve
end
function VehicleMotor:getTorque(acceleration)
	local torque = self:getTorqueCurveValue(math.clamp(self.motorRotSpeed * 30 / 3.141592653589793, self.minRpm, self.maxRpm))
	torque = torque * math.abs(acceleration)
	return torque
end
function VehicleMotor:getTorqueCurveValue(rpm)
	local damage = 1 - self.vehicle:getVehicleDamage() * VehicleMotor.DAMAGE_TORQUE_REDUCTION
	return self:getTorqueCurve():get(rpm) * damage
end
function VehicleMotor:getTorqueAndSpeedValues()
	local rotationSpeeds = {}
	local torques = {}
	for _, v in ipairs(self:getTorqueCurve().keyframes) do
		table.insert(rotationSpeeds, v.time * 3.141592653589793 / 30)
		table.insert(torques, self:getTorqueCurveValue(v.time))
	end
	return torques, rotationSpeeds
end
function VehicleMotor:getMaximumForwardSpeed()
	return self.maxForwardSpeed
end
function VehicleMotor:getMaximumBackwardSpeed()
	return self.maxBackwardSpeed
end
function VehicleMotor:calculatePhysicalMaximumForwardSpeed()
	return VehicleMotor.calculatePhysicalMaximumSpeed(self.minForwardGearRatio, self.forwardGears, self.maxRpm)
end
function VehicleMotor:calculatePhysicalMaximumBackwardSpeed()
	return VehicleMotor.calculatePhysicalMaximumSpeed(self.minBackwardGearRatio, self.backwardGears or self.forwardGears, self.maxRpm)
end
function VehicleMotor.calculatePhysicalMaximumSpeed(minGearRatio, gears, maxRpm)
	local minRatio = nil
	if minGearRatio ~= nil then
		minRatio = minGearRatio
	elseif gears ~= nil then
		minRatio = math.huge
		for _, gear in pairs(gears) do
			minRatio = math.min(minRatio, gear.ratio)
		end
	else
		printCallstack()
		return 0
	end
	return maxRpm * 3.141592653589793 / (30 * minRatio)
end
function VehicleMotor:update(dt)
	local vehicle = self.vehicle
	if next(vehicle.spec_motorized.differentials) ~= nil then
		if vehicle.spec_motorized.motorizedNode ~= nil then
			local lastMotorRotSpeed = self.motorRotSpeed
			local lastDiffRotSpeed = self.differentialRotSpeed
			self.motorRotSpeed, self.differentialRotSpeed, self.gearRatio = getMotorRotationSpeed(vehicle.spec_motorized.motorizedNode)
			if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and ((self.backwardGears or self.forwardGears) and (self.gearRatio ~= 0 and (self.maxGearRatio ~= 0 and self.lastAcceleratorPedal ~= 0))) then
				local minDifferentialSpeed = self.minRpm / math.abs(self.maxGearRatio) * 3.141592653589793 / 30
				if math.abs(self.differentialRotSpeed) < minDifferentialSpeed * 0.75 then
					self.clutchSlippingTimer = self.clutchSlippingTime
					self.clutchSlippingGearRatio = self.gearRatio
				else
					self.clutchSlippingTimer = math.max(self.clutchSlippingTimer - dt, 0)
				end
			end
			if not self:getUseAutomaticGearShifting() then
				local accelerationPedal = self.lastAcceleratorPedal * self.currentDirection
				local clutchValue = 0
				if self.minGearRatio == 0 and (self.maxGearRatio == 0 or 0.1 < self.manualClutchValue) then
					clutchValue = 1
				end
				local direction = clutchValue * accelerationPedal
				if direction == 0 then
					direction = -1
				end
				local accelerationSpeed = 0 < direction and self.motorRotationAccelerationLimit * 0.02 or self.dampingRateZeroThrottleClutchEngaged * 30 * 3.141592653589793
				local minRotSpeed = self.minRpm * 3.141592653589793 / 30
				local maxRotSpeed = self.maxRpm * 3.141592653589793 / 30
				self.motorRotSpeedClutchEngaged = math.min(math.max(self.motorRotSpeedClutchEngaged + direction * accelerationSpeed * dt, minRotSpeed), minRotSpeed + (maxRotSpeed - minRotSpeed) * accelerationPedal)
				self.motorRotSpeed = math.max(self.motorRotSpeed, self.motorRotSpeedClutchEngaged)
			end
			if 0 < g_physicsDtNonInterpolated and not getIsSleeping(vehicle.rootNode) then
				self.lastMotorAvailableTorque, self.lastMotorAppliedTorque, self.lastMotorExternalTorque = getMotorTorque(vehicle.spec_motorized.motorizedNode)
			end
			self.motorAvailableTorque = self.lastMotorAvailableTorque
			self.motorAppliedTorque = self.lastMotorAppliedTorque
			self.motorExternalTorque = self.lastMotorExternalTorque
			self.motorAppliedTorque = self.motorAppliedTorque - self.motorExternalTorque
			self.motorExternalTorque = math.min(self.motorExternalTorque * self.externalTorqueVirtualMultiplicator, self.motorAvailableTorque - self.motorAppliedTorque)
			self.motorAppliedTorque = self.motorAppliedTorque + self.motorExternalTorque
			local motorRotAcceleration = 0
			local differentialRotAcceleration = 0
			if 0 < g_physicsDtNonInterpolated then
				motorRotAcceleration = (self.motorRotSpeed - lastMotorRotSpeed) / (g_physicsDtNonInterpolated * 0.001)
				differentialRotAcceleration = (self.differentialRotSpeed - lastDiffRotSpeed) / (g_physicsDtNonInterpolated * 0.001)
			end
			self.motorRotAcceleration = motorRotAcceleration
			self.motorRotAccelerationSmoothed = 0.8 * self.motorRotAccelerationSmoothed + 0.2 * motorRotAcceleration
			self.differentialRotAcceleration = differentialRotAcceleration
			self.differentialRotAccelerationSmoothed = 0.8 * self.differentialRotAccelerationSmoothed + 0.2 * differentialRotAcceleration
			self.requiredMotorPower = math.huge
		else
			local _, gearRatio = self:getMinMaxGearRatio()
			self.differentialRotSpeed = WheelsUtil.computeDifferentialRotSpeedNonMotor(vehicle)
			self.motorRotSpeed = math.max(math.abs(self.differentialRotSpeed * gearRatio), 0)
			self.gearRatio = gearRatio
		end
	end
	if self.lastPtoRpm == nil then
		self.lastPtoRpm = self.minRpm
	end
	local ptoRpm = PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio
	if self.lastPtoRpm < ptoRpm then
		self.lastPtoRpm = math.min(ptoRpm, self.lastPtoRpm + self.maxRpm * dt / 2000)
	elseif ptoRpm < self.lastPtoRpm then
		self.lastPtoRpm = math.max(self.minRpm, self.lastPtoRpm - self.maxRpm * dt / 1000)
	end
	if self.vehicle.isServer then
		local clampedMotorRpm = math.max(self.motorRotSpeed * 30 / 3.141592653589793, math.min(self.lastPtoRpm, self.maxRpm), self.minRpm)
		self:setLastRpm(clampedMotorRpm)
		self.equalizedMotorRpm = clampedMotorRpm
		local rawLoadPercentage = self:getMotorAppliedTorque() / math.max(self:getMotorAvailableTorque(), 0.0001)
		self.rawLoadPercentageBuffer = self.rawLoadPercentageBuffer + rawLoadPercentage
		self.rawLoadPercentageBufferIndex = self.rawLoadPercentageBufferIndex + 1
		if 2 <= self.rawLoadPercentageBufferIndex then
			self.rawLoadPercentage = self.rawLoadPercentageBuffer / 2
			self.rawLoadPercentageBuffer = 0
			self.rawLoadPercentageBufferIndex = 0
		end
		if self.rawLoadPercentage < 0.01 and (self.lastAcceleratorPedal < 0.2 and not self.backwardGears) then
			if not self.forwardGears or self.gear ~= 0 or self.targetGear == 0 then
				self.rawLoadPercentage = -1
			else
				local idleLoadPct = 0.05
				self.rawLoadPercentage = (self.rawLoadPercentage - 0.05) / 0.95
			end
		end
		local accelerationPercentage = math.min(self.vehicle.lastSpeedAcceleration * 1000 * 1000 * self.vehicle.movingDirection / self.accelerationLimit, 1)
		if accelerationPercentage < 0.95 then
			if 0.2 < self.lastAcceleratorPedal then
				self.accelerationLimitLoadScale = 1
				self.accelerationLimitLoadScaleTimer = self.accelerationLimitLoadScaleDelay
			elseif 0 < self.accelerationLimitLoadScaleTimer then
				self.accelerationLimitLoadScaleTimer = self.accelerationLimitLoadScaleTimer - dt
				local alpha = math.max(self.accelerationLimitLoadScaleTimer / self.accelerationLimitLoadScaleDelay, 0)
				self.accelerationLimitLoadScale = math.sin((1 - alpha) * 3.14) * 0.85
			end
		end
		if 0 < accelerationPercentage then
			self.rawLoadPercentage = math.max(self.rawLoadPercentage, accelerationPercentage * self.accelerationLimitLoadScale)
		end
		self.constantAccelerationCharge = 1 - math.min(math.abs(self.vehicle.lastSpeedAcceleration) * 1000 * 1000 / self.accelerationLimit, 1)
		if 0 < self.rawLoadPercentage then
			self.rawLoadPercentage = self.rawLoadPercentage * 0.8 + self.rawLoadPercentage * 0.19999999999999996 * self.constantAccelerationCharge
		end
		if (self.backwardGears or self.forwardGears) and self:getUseAutomaticGearShifting() then
			if 0.99 >= self.constantRpmCharge then
				self.gearChangeTimeAutoReductionTimer = 0
				self.gearChangeTime = self.gearChangeTimeOrig
			elseif self.maxRpm - clampedMotorRpm >= 50 then
				self.gearChangeTimeAutoReductionTimer = 0
				self.gearChangeTime = self.gearChangeTimeOrig
			else
				self.gearChangeTimeAutoReductionTimer = math.min(self.gearChangeTimeAutoReductionTimer + dt, self.gearChangeTimeAutoReductionTime)
				self.gearChangeTime = self.gearChangeTimeOrig * (1 - self.gearChangeTimeAutoReductionTimer / self.gearChangeTimeAutoReductionTime)
			end
		end
	end
	self:updateSmoothLoadPercentage(dt, self.rawLoadPercentage)
	self.idleGearChangeTimer = math.max(self.idleGearChangeTimer - dt, 0)
	if self.forwardGears or self.backwardGears then
		self:updateStartGearValues(dt)
		local clutchPedal = self:getClutchPedal()
		self.lastSmoothedClutchPedal = self.lastSmoothedClutchPedal * 0.9 + clutchPedal * 0.1
	end
	self.lastModulationTimer = self.lastModulationTimer + dt * 0.0009
	self.lastModulationPercentage = math.sin(self.lastModulationTimer) * math.sin((self.lastModulationTimer + 2) * 0.3) * 0.8 + math.cos(self.lastModulationTimer * 5) * 0.2
end
function VehicleMotor:updateSmoothLoadPercentage(dt, rawLoadPercentage)
	local lastSmoothedLoad = self.smoothedLoadPercentage
	local maxSpeed = self:getMaximumForwardSpeed() * 3.6
	if self.vehicle.movingDirection < 0 then
		maxSpeed = self:getMaximumBackwardSpeed() * 3.6
	end
	local speedPercentage = math.max(math.min(self.vehicle:getLastSpeed() / maxSpeed, 1), 0)
	local factor = 0.05 + (1 - speedPercentage) * 0.3
	if rawLoadPercentage < self.smoothedLoadPercentage then
		if self.gearType ~= VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT or 200 < g_time - self.lastGearChangeTime then
			factor = factor * 0.2
			if 0.75 < self:getClutchPedal() then
				factor = factor * 5
			end
			if rawLoadPercentage < 0 then
				factor = factor * 2.5
			end
		else
			factor = factor * 0.05
		end
	end
	local invFactor = 1 - factor
	self.smoothedLoadPercentage = invFactor * self.smoothedLoadPercentage + factor * rawLoadPercentage
	local difference = math.max(self.smoothedLoadPercentage - lastSmoothedLoad, 0)
	self.loadPercentageChangeCharge = self.loadPercentageChangeCharge + difference
	self.loadPercentageChangeCharge = math.min(math.max(self.loadPercentageChangeCharge - dt * 0.0005, 0), 1)
end
function VehicleMotor:updateStartGearValues(dt)
	local totalMass = self.vehicle:getTotalMass()
	local totalMassOnGround = 0
	local vehicleMass = self.vehicle:getTotalMass(true)
	if 0.00001 * dt < math.abs(totalMass - self.startGearValues.lastMass) then
		self.startGearValues.lastMass = totalMass
		self.idleGearChangeTimer = 500
	end
	local maxForce = 0
	local vehicles = self.vehicle:getChildVehicles()
	for _, vehicle in ipairs(vehicles) do
		if vehicle == self.vehicle then
			continue
		end
		if vehicle.spec_powerConsumer ~= nil and vehicle.spec_powerConsumer.maxForce ~= nil then
			local multiplier = vehicle:getPowerMultiplier()
			if multiplier ~= 0 then
				maxForce = maxForce + vehicle.spec_powerConsumer.maxForce
			end
		end
		if vehicle.spec_leveler ~= nil then
			maxForce = maxForce + math.abs(vehicle.spec_leveler.lastForce)
		end
		if vehicle.spec_wheels == nil then
			continue
		end
		if 0 < #vehicle.spec_wheels.wheels then
			totalMassOnGround = totalMassOnGround + vehicle:getTotalMass(true)
		end
	end
	local comX = 0
	local comY = 0
	local comZ = 0
	local dirX = 0
	local dirY = 0
	local dirZ = 0
	for _, vehicle in ipairs(vehicles) do
		if vehicle == self.vehicle or vehicle.spec_wheels == nil then
			continue
		end
		if 0 < #vehicle.spec_wheels.wheels then
			local objectMass = vehicle:getTotalMass(true)
			local percentage = objectMass / totalMassOnGround
			local cx, cy, cz = vehicle:getOverallCenterOfMass()
			comX = comX + cx * percentage
			comY = comY + cy * percentage
			comZ = comZ + cz * percentage
			local iDirX, iDirY, iDirZ = vehicle:getVehicleWorldDirection()
			dirX = dirX + iDirX * percentage
			dirY = dirY + iDirY * percentage
			dirZ = dirZ + iDirZ * percentage
		end
	end
	local vdx, vdy, vdz = self.vehicle:getVehicleWorldDirection()
	if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
		local vX, vY, vZ = getWorldTranslation(self.vehicle.components[1].node)
		DebugGizmo.renderAtPosition(comX, comY, comZ, dirX, dirY, dirZ, 0, 1, 0, "TOOLS DIR")
		DebugGizmo.renderAtPosition(vX, vY, vZ, vdx, vdy, vdz, 0, 1, 0, "VEHICLE DIR")
	end
	local diffXZ = 0
	local diffY = 0
	if dirX ~= 0 or dirY ~= 0 or dirZ ~= 0 then
		diffXZ = math.max(math.abs(dirX - vdx), math.abs(dirZ - vdz))
		diffY = math.max(dirY - vdy, 0)
	end
	local massDirectionInfluenceFactor = math.min((totalMass - vehicleMass) / 5, 1)
	self.startGearValues.massDirectionDifferenceXZ = diffXZ
	self.startGearValues.massDirectionDifferenceY = diffY
	self.startGearValues.massDirectionFactor = (1 + diffXZ * massDirectionInfluenceFactor) * (1 + diffY / 0.15 * massDirectionInfluenceFactor)
	local neededPtoTorque = PowerConsumer.getTotalConsumedPtoTorque(self.vehicle, nil, nil, true) / self:getPtoMotorRpmRatio()
	local ptoPower = self.peakMotorPowerRotSpeed * neededPtoTorque
	self.startGearValues.availablePower = self.peakMotorPower - ptoPower
	local maxForcePowerFactor = 1 + ptoPower / self.peakMotorPower * 0.75
	local mass = (totalMass + maxForce * maxForcePowerFactor) / vehicleMass
	mass = ((mass - 1) * 0.5 + 1) * vehicleMass
	self.startGearValues.maxForce = maxForce
	self.startGearValues.mass = mass
	self.startGearValues.slope = self.vehicle:getVehicleWorldXRot()
	self.startGearValues.massFactor = self.startGearValues.mass * self.startGearValues.massDirectionFactor / (((self.startGearValues.availablePower / 100 - 1) * 50 + 100) * 0.4)
end
function VehicleMotor:getBestStartGear(gears)
	local directionMultiplier = self.directionChangeUseGroup and 1 or self.currentDirection
	local minFactor = math.huge
	local minFactorGear = 1
	local minFactorGroup = 1
	local maxFactor = 0
	local maxFactorGear = 1
	local maxFactorGroup = 1
	if self.gearGroups ~= nil then
		if self:getUseAutomaticGroupShifting() then
			local start = #self.gearGroups
			local limit = 1
			local step = -1
			if self.currentDirection < 0 then
				start = 1
				limit = #self.gearGroups
				step = 1
			end
			for j = start, limit, step do
				local groupRatio = self.gearGroups[j].ratio * directionMultiplier
				if math.sign(groupRatio) == self.currentDirection or not self.directionChangeUseGroup then
					for i = #gears, 1, -1 do
						local factor = self:getStartInGearFactor(gears[i].ratio * groupRatio)
						if factor < self.startGearThreshold and maxFactor == 0 then
							maxFactor = factor
							maxFactorGear = i
							maxFactorGroup = j
						end
						if factor < minFactor then
							minFactor = factor
							minFactorGear = i
							minFactorGroup = j
						end
					end
				end
			end
		end
	else
		local gearRatioMultiplier = self:getGearRatioMultiplier()
		for i = #gears, 1, -1 do
			local factor = self:getStartInGearFactor(gears[i].ratio * gearRatioMultiplier)
			if factor < self.startGearThreshold and maxFactor == 0 then
				maxFactor = factor
				maxFactorGear = i
			end
			if factor < minFactor then
				minFactor = factor
				minFactorGear = i
			end
		end
	end
	if maxFactor == 0 then
		return minFactorGear, minFactorGroup
	else
		return maxFactorGear, maxFactorGroup
	end
end
function VehicleMotor:getRequiredRpmAtSpeedLimit(ratio)
	local speedLimit = math.min(self.vehicle:getSpeedLimit(true), math.max(self.speedLimitAcc, self.vehicle.lastSpeedReal * 3600))
	if self.vehicle:getCruiseControlState() == Drivable.CRUISECONTROL_STATE_ACTIVE then
		speedLimit = math.min(speedLimit, self.vehicle:getCruiseControlSpeed())
	end
	speedLimit = 0 < ratio and math.min(speedLimit, self.maxForwardSpeed * 3.6) or math.min(speedLimit, self.maxBackwardSpeed * 3.6)
	return speedLimit / 3.6 * 30 / 3.141592653589793 * math.abs(ratio)
end
function VehicleMotor:getStartInGearFactor(ratio)
	if self:getRequiredRpmAtSpeedLimit(ratio) < self.minRpm + (self.maxRpm - self.minRpm) * 0.25 then
		return math.huge
	else
		local slope = self.startGearValues.slope
		if ratio < 0 then
			slope = -slope
		end
		local slopePowerFactor = ((self.startGearValues.availablePower / 100 - 1) / 2) ^ 2 * 2 + 1
		local slopeFactor = 1 + math.max(slope, 0) / (slopePowerFactor * 0.06981)
		return self.startGearValues.massFactor * slopeFactor / (math.abs(ratio) / 300)
	end
end
function VehicleMotor:getBestGearRatio(wheelSpeedRpm, minRatio, maxRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
	if requiredMotorRpm ~= 0 then
		local gearRatio = math.max(requiredMotorRpm - accSafeMotorRpm, requiredMotorRpm * 0.8) / math.max(wheelSpeedRpm, 0.001)
		gearRatio = math.clamp(gearRatio, minRatio, maxRatio)
		return gearRatio
	end
	wheelSpeedRpm = math.max(wheelSpeedRpm, 0.0001)
	local bestMotorPower = 0
	local bestGearRatio = minRatio
	for gearRatio = minRatio, maxRatio, 0.5 do
		local motorRpm = wheelSpeedRpm * gearRatio
		if self.maxRpm - accSafeMotorRpm < motorRpm then
			break
		end
		local motorPower = self:getTorqueCurveValue(math.max(motorRpm, self.minRpm)) * motorRpm * 3.141592653589793 / 30
		if bestMotorPower < motorPower then
			bestMotorPower = motorPower
			bestGearRatio = gearRatio
		end
		if not (requiredMotorPower <= motorPower) then
			continue
		end
		return bestGearRatio
	end
end
function VehicleMotor:getBestGear(acceleration, wheelSpeedRpm, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
	if math.abs(acceleration) < 0.001 then
		acceleration = 1
		if wheelSpeedRpm < 0 then
			acceleration = -1
		end
	end
	if 0 < acceleration then
		if self.minForwardGearRatio ~= nil then
			wheelSpeedRpm = math.max(wheelSpeedRpm, 0)
			local bestGearRatio = self:getBestGearRatio(wheelSpeedRpm, self.minForwardGearRatio, self.maxForwardGearRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
			return 1, bestGearRatio
		else
			return 1, self.forwardGears[1].ratio
		end
	elseif self.minBackwardGearRatio ~= nil then
		wheelSpeedRpm = math.max(-wheelSpeedRpm, 0)
		local bestGearRatio = self:getBestGearRatio(wheelSpeedRpm, self.minBackwardGearRatio, self.maxBackwardGearRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
		return -1, -bestGearRatio
	elseif self.backwardGears ~= nil then
		return -1, -self.backwardGears[1].ratio
	else
		return 1, self.forwardGears[1].ratio
	end
end
function VehicleMotor:findGearChangeTargetGearPrediction(curGear, gears, gearSign, gearChangeTimer, acceleratorPedal, dt)
	local newGear = curGear
	local gearRatioMultiplier = self:getGearRatioMultiplier()
	local minAllowedRpm = self.minRpm
	local maxAllowedRpm = self.maxRpm
	local gearRatio = math.abs(gears[curGear].ratio * gearRatioMultiplier)
	local differentialRotSpeed = math.max(self.differentialRotSpeed * gearSign, 0.0001)
	local differentialRpm = differentialRotSpeed * 30 / 3.141592653589793
	local clutchRpm = differentialRpm * gearRatio
	local diffSpeedAfterChange = nil
	if math.abs(acceleratorPedal) < 0.0001 then
		local brakeAcc = math.min(self.differentialRotAccelerationSmoothed * gearSign * 0.8, 0)
		diffSpeedAfterChange = math.max(differentialRotSpeed + brakeAcc * self.gearChangeTime * 0.001, 0)
	else
		local lastMotorRotSpeed = self.motorRotSpeed - self.motorRotAcceleration * (g_physicsDtLastValidNonInterpolated * 0.001)
		local lastDampedMotorRotSpeed = lastMotorRotSpeed / (1 + self.dampingRateFullThrottle / self.rotInertia * g_physicsDtLastValidNonInterpolated * 0.001)
		local neededInertiaTorque = (self.motorRotSpeed - lastDampedMotorRotSpeed) / (g_physicsDtLastValidNonInterpolated * 0.001) * self.rotInertia
		local lastMotorTorque = self.motorAppliedTorque - self.motorExternalTorque - neededInertiaTorque
		local totalMass = self.vehicle:getTotalMass()
		local expectedAcc = lastMotorTorque * gearRatio / totalMass
		local uncalculatedAccFactor = 0.9
		local gravityAcc = math.max(expectedAcc * 0.9 - math.max(self.differentialRotAccelerationSmoothed * gearSign, 0), 0)
		diffSpeedAfterChange = math.max(differentialRotSpeed - gravityAcc * self.gearChangeTime * 0.001, 0)
	end
	local maxPower = 0
	local maxPowerGear = 0
	for gear = 1, #gears do
		local rpm = nil
		if gear == curGear then
			rpm = clutchRpm
		else
			rpm = diffSpeedAfterChange * math.abs(gears[gear].ratio * gearRatioMultiplier) * 30 / 3.141592653589793
		end
		local startInGearFactor = self:getStartInGearFactor(gears[gear].ratio * gearRatioMultiplier)
		local minRpmFactor = 1
		if startInGearFactor < self.startGearThreshold then
			minRpmFactor = 0
		end
		if rpm <= maxAllowedRpm and (not (minAllowedRpm * minRpmFactor <= rpm) and gear == curGear) then
			local power = self:getTorqueCurveValue(rpm) * rpm
			if maxPower <= power then
				maxPower = power
				maxPowerGear = gear
			end
		end
	end
	local neededPowerPct = 0.5
	if maxPowerGear ~= 0 then
		local bestTradeoff = 0
		for gear = #gears, 1, -1 do
			local validGear = false
			local nextRpm = nil
			if gear == curGear then
				nextRpm = clutchRpm
			else
				nextRpm = diffSpeedAfterChange * math.abs(gears[gear].ratio * gearRatioMultiplier) * 30 / 3.141592653589793
			end
			local startInGearFactor = self:getStartInGearFactor(gears[gear].ratio * gearRatioMultiplier)
			local minRpmFactor = 1
			local neededPowerPctGear = 0.5
			if startInGearFactor < self.startGearThreshold then
				neededPowerPctGear = 0
				minRpmFactor = 0
			end
			if nextRpm <= maxAllowedRpm then
				local nextPower = self:getTorqueCurveValue(nextRpm) * nextRpm
				if not (minAllowedRpm * minRpmFactor <= nextRpm) and gear == curGear and maxPower * neededPowerPctGear <= nextPower or maxPower * neededPowerPctGear <= nextPower or gear == curGear then
					local powerFactor = (nextPower - maxPower * neededPowerPctGear) / (maxPower * (1 - neededPowerPctGear))
					local curSpeedRpm = differentialRpm * math.abs(gears[gear].ratio * gearRatioMultiplier)
					local rpmFactor = math.clamp((maxAllowedRpm - curSpeedRpm) / math.max(maxAllowedRpm - minAllowedRpm, 0.001), 0, 2)
					if 1 < rpmFactor then
						rpmFactor = 1 - (rpmFactor - 1) * 4
					end
					local gearChangeFactor = nil
					gearChangeFactor = gear == curGear and 1 or math.min(-gearChangeTimer / 2000, 0.9)
					local rpmPreferenceFactor = 0
					if gear < curGear then
						rpmPreferenceFactor = math.clamp((nextRpm - clutchRpm) / 250, -1, 0)
					end
					if gear < self.bestGearSelected then
						local factor = self:getStartInGearFactor(gearRatio)
						if factor < self.startGearThreshold then
							gearChangeFactor = -4
						end
					end
					rpmPreferenceFactor = rpmPreferenceFactor - (1 - math.min(math.sin(rpmFactor * 3.141592653589793) * 5, 2)) * 0.7
					if gear == curGear and 0 < rpmPreferenceFactor then
						rpmPreferenceFactor = rpmPreferenceFactor * 1.5
					end
					rpmFactor = math.abs(acceleratorPedal) < 0.0001 and 1 - rpmFactor or rpmFactor * 2
					if math.abs(acceleratorPedal) < 0.0001 and 0.25 < (clutchRpm - minRpmFactor) / (maxAllowedRpm - minRpmFactor) then
						if gear < curGear then
							powerFactor = 0
							rpmFactor = 0
						elseif gear == curGear then
							powerFactor = 1
							rpmFactor = 1
						end
					end
					if curGear < gear and startInGearFactor < self.startGearThreshold then
						powerFactor = 1
						rpmPreferenceFactor = 1
					end
					local tradeoff = powerFactor + rpmFactor + gearChangeFactor + rpmPreferenceFactor
					if bestTradeoff <= tradeoff then
						bestTradeoff = tradeoff
						newGear = gear
					end
					if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
						gears[gear].lastTradeoff = tradeoff
						gears[gear].lastDiffSpeedAfterChange = gear == curGear and diffSpeedAfterChange or nil
						gears[gear].lastPowerFactor = powerFactor
						gears[gear].lastRpmFactor = rpmFactor
						gears[gear].lastGearChangeFactor = gearChangeFactor
						gears[gear].lastRpmPreferenceFactor = rpmPreferenceFactor
						gears[gear].lastNextPower = nextPower
						gears[gear].nextPowerValid = true
						gears[gear].lastNextRpm = nextRpm
						gears[gear].nextRpmValid = true
						gears[gear].lastMaxPower = maxPower
						gears[gear].lastHasPower = true
					end
					validGear = true
				else
					if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
						gears[gear].lastNextPower = nextPower
					end
				end
			end
			if validGear then
				continue
			end
			if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
				gears[gear].lastTradeoff = 0
				gears[gear].lastPowerFactor = 0
				gears[gear].lastRpmFactor = 0
				gears[gear].lastGearChangeFactor = 0
				gears[gear].lastRpmPreferenceFactor = 0
				gears[gear].lastDiffSpeedAfterChange = gear == curGear and diffSpeedAfterChange or nil
				gears[gear].lastNextRpm = nextRpm
				gears[gear].nextRpmValid = nextRpm <= maxAllowedRpm and minAllowedRpm * minRpmFactor <= nextRpm
				gears[gear].nextPowerValid = false
				gears[gear].lastMaxPower = maxPower
				gears[gear].lastHasPower = false
			end
		end
	else
		local minDiffGear = 0
		local minDiff = math.huge
		for gear = 1, #gears do
			local rpm = diffSpeedAfterChange * math.abs(gears[gear].ratio * gearRatioMultiplier) * 30 / 3.141592653589793
			local diff = math.max(rpm - maxAllowedRpm, minAllowedRpm - rpm)
			if diff < minDiff then
				minDiff = diff
				minDiffGear = gear
			end
		end
		newGear = minDiffGear
	end
	return newGear
end
function VehicleMotor:applyTargetGear()
	local gearRatioMultiplier = self:getGearRatioMultiplier()
	self.gear = self.targetGear
	if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
		if self.currentGears[self.gear] ~= nil then
			self.minGearRatio = self.currentGears[self.gear].ratio * gearRatioMultiplier
			self.maxGearRatio = self.minGearRatio
		else
			self.minGearRatio = 0
			self.maxGearRatio = 0
		end
	end
	self.gearChangeTime = self.gearChangeTimeOrig
	local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
	SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, 0, self.previousGear)
end
function VehicleMotor:updateGear(acceleratorPedal, brakePedal, dt)
	self.lastAcceleratorPedal = acceleratorPedal
	local adjAcceleratorPedal = acceleratorPedal
	if 0 <= self.gearChangeTimer then
		self.gearChangeTimer = self.gearChangeTimer - dt
		if self.gearChangeTimer < 0 and self.targetGear ~= 0 then
			self.allowGearChangeTimer = 3000
			self.allowGearChangeDirection = math.sign(self.targetGear - self.previousGear)
			self:applyTargetGear()
		end
		adjAcceleratorPedal = 0
	elseif 0 < self.groupChangeTimer or 0 < self.directionChangeTimer then
		self.groupChangeTimer = self.groupChangeTimer - dt
		self.directionChangeTimer = self.directionChangeTimer - dt
		if self.groupChangeTimer < 0 and self.directionChangeTimer < 0 then
			self:applyTargetGear()
		end
	else
		local gearSign = 0
		if 0 < acceleratorPedal then
			if self.minForwardGearRatio ~= nil then
				self.minGearRatio = self.minForwardGearRatio
				self.maxGearRatio = self.maxForwardGearRatio
			else
				gearSign = 1
			end
		elseif acceleratorPedal < 0 then
			if self.minBackwardGearRatio ~= nil then
				self.minGearRatio = -self.minBackwardGearRatio
				self.maxGearRatio = -self.maxBackwardGearRatio
			else
				gearSign = -1
			end
		elseif 0 < self.maxGearRatio then
			if self.minForwardGearRatio == nil then
				gearSign = 1
			end
		elseif self.maxGearRatio < 0 then
			if self.minBackwardGearRatio == nil then
				gearSign = -1
			end
		end
		local newGear = self.gear
		local forceGearChange = false
		local skipGearChangeTimer = false
		if (self.backwardGears or self.forwardGears) and self:getUseAutomaticGearShifting() then
			self.autoGearChangeTimer = self.autoGearChangeTimer - dt
			if self.vehicle:getIsAutomaticShiftingAllowed() or acceleratorPedal ~= 0 then
				if math.abs(self.vehicle.lastSpeed) < 0.0003 then
					local directionChanged = false
					local trySelectBestGear = false
					local allowGearOverwritting = false
					if gearSign < 0 then
						if self.currentDirection == 1 or self.gear == 0 then
							self:changeDirection(-1, true)
							directionChanged = true
							skipGearChangeTimer = 0 < self.directionChangeTime
						else
							if 0 < gearSign then
								if self.currentDirection == -1 or self.gear == 0 then
									self:changeDirection(1, true)
									directionChanged = true
									skipGearChangeTimer = 0 < self.directionChangeTime
								else
									if self.lastAcceleratorPedal == 0 then
										if self.idleGearChangeTimer <= 0 then
											trySelectBestGear = true
											self.doSecondBestGearSelection = 3
										elseif 0 < self.doSecondBestGearSelection then
											if self.lastAcceleratorPedal ~= 0 then
												self.doSecondBestGearSelection = self.doSecondBestGearSelection - 1
												if self.doSecondBestGearSelection == 0 then
													trySelectBestGear = true
													allowGearOverwritting = true
												end
											end
										end
									end
								end
							end
						end
					end
					if directionChanged then
						if self.targetGear ~= self.gear then
							newGear = self.targetGear
						end
						trySelectBestGear = true
					end
					if trySelectBestGear then
						local bestGear, maxFactorGroup = self:getBestStartGear(self.currentGears)
						if bestGear ~= self.gear or bestGear ~= self.bestGearSelected then
							newGear = bestGear
							if 1 < bestGear or allowGearOverwritting then
								self.bestGearSelected = bestGear
								self.allowGearChangeTimer = 0
							end
						end
						if self:getUseAutomaticGroupShifting() and (maxFactorGroup ~= nil and maxFactorGroup ~= self.activeGearGroupIndex) then
							self:setGearGroup(maxFactorGroup)
						end
					end
				elseif self.gear ~= 0 then
					if self.autoGearChangeTimer <= 0 then
						if math.sign(acceleratorPedal) ~= math.sign(self.currentDirection) then
							acceleratorPedal = 0
						end
						newGear = self:findGearChangeTargetGearPrediction(self.gear, self.currentGears, self.currentDirection, self.autoGearChangeTimer, acceleratorPedal, dt)
						if self:getUseAutomaticGroupShifting() and self.gearGroups ~= nil then
							if self.activeGearGroupIndex >= #self.gearGroups then
								self.gearGroupUpShiftTimer = 0
							elseif math.abs(math.min(self:getLastRealMotorRpm(), self.maxRpm) - self.maxRpm) >= 50 then
								self.gearGroupUpShiftTimer = 0
							else
								if self.gear == #self.currentGears then
									local nextRatio = self.gearGroups[self.activeGearGroupIndex + 1].ratio
									if math.sign(self.gearGroups[self.activeGearGroupIndex].ratio) == math.sign(nextRatio) then
										self:shiftGroup(true)
										newGear = self:findGearChangeTargetGearPrediction(self.targetGear, self.currentGears, self.currentDirection, self.autoGearChangeTimer, acceleratorPedal, dt)
										forceGearChange = true
									end
								elseif self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
									if math.sign(self.gearGroups[self.activeGearGroupIndex].ratio) == math.sign(self.gearGroups[self.activeGearGroupIndex + 1].ratio) then
										self.gearGroupUpShiftTimer = self.gearGroupUpShiftTimer + dt
										if self.gearGroupUpShiftTime < self.gearGroupUpShiftTimer then
											self.gearGroupUpShiftTimer = 0
											self:shiftGroup(true)
										end
									else
										self.gearGroupUpShiftTimer = 0
									end
								end
							end
							if self.gear == 1 and self.lastRealMotorRpm < self.minRpm + (self.maxRpm - self.minRpm) * 0.25 then
								local _, maxFactorGroup = self:getBestStartGear(self.currentGears)
								if maxFactorGroup < self.activeGearGroupIndex and math.sign(self.gearGroups[maxFactorGroup].ratio) == math.sign(self.gearGroups[self.activeGearGroupIndex].ratio) then
									self:setGearGroup(maxFactorGroup)
								end
							end
						end
					end
					newGear = math.min(math.max(newGear, 1), #self.currentGears)
				end
				self.allowGearChangeTimer = self.allowGearChangeTimer - dt
				if 0 < self.allowGearChangeTimer and (0 < acceleratorPedal * self.currentDirection and (newGear < self.gear and self.allowGearChangeDirection ~= math.sign(newGear - self.gear))) then
					newGear = self.gear
				end
			end
		end
		if newGear ~= self.gear or forceGearChange then
			if newGear ~= self.bestGearSelected then
				self.bestGearSelected = -1
			end
			self.targetGear = newGear
			self.previousGear = self.gear
			self.gear = 0
			self.minGearRatio = 0
			self.maxGearRatio = 0
			if not skipGearChangeTimer then
				self.autoGearChangeTimer = self.autoGearChangeTime
				self.gearChangeTimer = self.gearChangeTime
			end
			self.lastGearChangeTime = g_time
			adjAcceleratorPedal = 0
			local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
			SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, self.gearChangeTimer, self.previousGear)
			if self.gearChangeTimer == 0 then
				self.gearChangeTimer = -1
				self.allowGearChangeTimer = 3000
				self.allowGearChangeDirection = math.sign(self.targetGear - self.previousGear)
				self:applyTargetGear()
			end
		end
	end
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (self.backwardGears or self.forwardGears) then
		local curRatio = nil
		local tarRatio = nil
		if self.currentGears[self.gear] ~= nil then
			tarRatio = self.currentGears[self.gear].ratio * self:getGearRatioMultiplier()
			local differentialRotSpeed = math.max(math.abs(self.differentialRotSpeed), 0.0001)
			curRatio = math.min(self.motorRotSpeed / differentialRotSpeed, 5000)
		end
		local ratio = 0
		if tarRatio ~= nil then
			ratio = MathUtil.lerp(math.abs(tarRatio), math.abs(curRatio), math.min(self.manualClutchValue, 0.9) / 0.9 * 0.5) * math.sign(tarRatio)
		end
		self.minGearRatio = ratio
		self.maxGearRatio = ratio
		if self.manualClutchValue == 0 then
			if self.maxGearRatio ~= 0 then
				local factor = 1
				local motorRpm = self:getNonClampedMotorRpm()
				if 0 < motorRpm then
					factor = (self:getClutchRpm() + 50) / motorRpm
				end
				if factor < 0.2 then
					self.stallTimer = self.stallTimer + dt
					if 500 < self.stallTimer then
						self.vehicle:stopMotor()
						self.stallTimer = 0
					end
				else
					self.stallTimer = 0
				end
			else
				self.stallTimer = 0
			end
		end
	end
	if self:getUseAutomaticGearShifting() and (0.0003 < math.abs(self.vehicle.lastSpeed) and ((self.backwardGears or self.forwardGears) and (0 < self.currentDirection and (adjAcceleratorPedal < 0 or self.currentDirection < 0 and 0 < adjAcceleratorPedal)))) then
		adjAcceleratorPedal = 0
		brakePedal = 1
	end
	return adjAcceleratorPedal, brakePedal
end
function VehicleMotor:shiftGear(up)
	if not self.gearChangedIsLocked then
		if self:getIsGearChangeAllowed() then
			local newGear = nil
			newGear = up and self.targetGear + 1 * self.currentDirection or self.targetGear - 1 * self.currentDirection
			if 0 < self.currentDirection or self.backwardGears == nil then
				if #self.forwardGears < newGear then
					newGear = #self.forwardGears
				end
			else
				if (self.currentDirection < 0 or self.backwardGears ~= nil) and #self.backwardGears < newGear then
					newGear = #self.backwardGears
				end
			end
			if newGear ~= self.targetGear then
				if 0 < self.currentDirection then
					if newGear < 0 then
						self:changeDirection(-1)
						newGear = 1
					end
				elseif newGear < 0 then
					self:changeDirection(1)
					newGear = 1
				end
				self:setGear(newGear)
				self.lastManualShifterActive = false
			end
		else
			SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", true, false)
		end
	end
end
function VehicleMotor:selectGear(gearIndex, activation)
	if activation then
		if self.gear ~= gearIndex then
			if self:getIsGearChangeAllowed() then
				if self.currentGears[gearIndex] ~= nil then
					self:setGear(gearIndex, true)
					self.lastManualShifterActive = true
				end
			else
				SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", false, false, gearIndex)
			end
		end
	else
		self:setGear(0, false)
		self.lastManualShifterActive = true
	end
end
function VehicleMotor:setGear(gearIndex, isLocked)
	if gearIndex ~= self.targetGear then
		if self.gearChangeTime == 0 and gearIndex < self.targetGear then
			self.loadPercentageChangeCharge = 1
		end
		if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
			self.targetGear = gearIndex
			self.previousGear = self.gear
			self.gear = 0
			self.minGearRatio = 0
			self.maxGearRatio = 0
			self.autoGearChangeTimer = self.autoGearChangeTime
			self.gearChangeTimer = self.gearChangeTime
		else
			self.targetGear = gearIndex
			self.previousGear = self.gear
			self.gear = gearIndex
		end
		self.lastGearChangeTime = g_time
		local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
		SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, self.gearChangeTime, self.previousGear)
	end
end
function VehicleMotor:shiftGroup(up)
	if not self.gearGroupChangedIsLocked then
		if self:getIsGearGroupChangeAllowed() then
			if self.gearGroups ~= nil then
				local newGearGroupIndex = nil
				newGearGroupIndex = up and self.activeGearGroupIndex + 1 or self.activeGearGroupIndex - 1
				self:setGearGroup(math.clamp(newGearGroupIndex, 1, self.numGearGroups))
			end
		else
			SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", true, true)
		end
	end
end
function VehicleMotor:selectGroup(groupIndex, activation)
	if activation then
		if self:getIsGearGroupChangeAllowed() then
			if self.gearGroups ~= nil and self.gearGroups[groupIndex] ~= nil then
				self:setGearGroup(groupIndex, true)
			end
		elseif self.activeGearGroupIndex ~= groupIndex then
			SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", false, true, nil, groupIndex)
		end
	else
		self:setGearGroup(0, false)
	end
end
function VehicleMotor:setGearGroup(groupIndex, isLocked)
	local lastActiveGearGroupIndex = self.activeGearGroupIndex
	self.activeGearGroupIndex = groupIndex
	self.gearGroupChangedIsLocked = isLocked
	if self.activeGearGroupIndex ~= lastActiveGearGroupIndex then
		if self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT and lastActiveGearGroupIndex < self.activeGearGroupIndex then
			self.loadPercentageChangeCharge = 1
		end
		if self.directionChangeUseGroup then
			if 0 < self.activeGearGroupIndex then
				local group = self.gearGroups[self.activeGearGroupIndex]
				self.currentDirection = math.sign(group.ratio)
			else
				self.currentDirection = 1
			end
		end
		if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
			if self.groupType == VehicleMotor.TRANSMISSION_TYPE.DEFAULT then
				self.groupChangeTimer = self.groupChangeTime
				self.gear = 0
				self.minGearRatio = 0
				self.maxGearRatio = 0
			elseif self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
				self:applyTargetGear()
			end
		end
		SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, self.groupType == VehicleMotor.TRANSMISSION_TYPE.DEFAULT and self.groupChangeTime or 0)
	end
end
function VehicleMotor:changeDirection(direction, force)
	local targetDirection = nil
	targetDirection = direction == nil and -self.currentDirection or direction
	if self.backwardGears == nil and self.forwardGears == nil then
		self.currentDirection = targetDirection
		SpecializationUtil.raiseEvent(self.vehicle, "onGearDirectionChanged", self.currentDirection)
		return
	end
	if (not self.directionChangeUseGroup or not not self.gearGroupChangedIsLocked) and (not self.directionChangeUseGear or not not self.gearChangedIsLocked) then
		local changeAllowed = not self.directionChangeUseGear and not self.directionChangeUseGroup
	end
	if changeAllowed and (targetDirection ~= self.currentDirection or force) then
		self.currentDirection = targetDirection
		if 0 < self.directionChangeTime then
			self.directionChangeTimer = self.directionChangeTime
			self.gear = 0
			self.minGearRatio = 0
			self.maxGearRatio = 0
		end
		local oldGearGroupIndex = self.activeGearGroupIndex
		if self.currentDirection < 0 then
			if self.directionChangeUseGear then
				self.directionLastGear = self.targetGear
				if not self:getUseAutomaticGearShifting() or not self.lastManualShifterActive then
					self.targetGear = self.directionChangeGearIndex
				end
				self.currentGears = self.backwardGears or self.forwardGears
			elseif self.directionChangeUseGroup then
				self.directionLastGroup = self.activeGearGroupIndex
				self.activeGearGroupIndex = self.directionChangeGroupIndex
			end
		elseif self.directionChangeUseGear then
			if not self:getUseAutomaticGearShifting() or not self.lastManualShifterActive then
				if 0 < self.directionLastGear then
					if not self:getUseAutomaticGearShifting() then
						local _v36 = self.directionLastGear or self.defaultForwardGear
					end
					self.targetGear = _v36
				else
					self.targetGear = self.defaultForwardGear
				end
			end
			self.currentGears = self.forwardGears
		elseif self.directionChangeUseGroup then
			if 0 < self.directionLastGroup then
				self.activeGearGroupIndex = self.directionLastGroup
			else
				self.activeGearGroupIndex = self.defaultGearGroup
			end
		end
		SpecializationUtil.raiseEvent(self.vehicle, "onGearDirectionChanged", self.currentDirection)
		local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
		SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, self.directionChangeTime, self.previousGear)
		if self.activeGearGroupIndex ~= oldGearGroupIndex then
			SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, self.directionChangeTime)
		end
		if self.directionChangeTime == 0 then
			self:applyTargetGear()
		end
	end
end
function VehicleMotor:onManualClutchChanged(clutchValue)
	self.manualClutchValue = clutchValue
end
function VehicleMotor:getIsGearChangeAllowed()
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and self.gearType ~= VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
		return 0.5 < self.manualClutchValue
	end
	return true
end
function VehicleMotor:getIsGearGroupChangeAllowed()
	if self.gearGroups == nil then
		return false
	elseif self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and self.groupType ~= VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
		return 0.5 < self.manualClutchValue
	else
		return true
	end
end
function VehicleMotor:setTransmissionDirection(direction)
	if 0 < direction then
		self.maxForwardSpeed = self.maxForwardSpeedOrigin
		self.maxBackwardSpeed = self.maxBackwardSpeedOrigin
		self.minForwardGearRatio = self.minForwardGearRatioOrigin
		self.maxForwardGearRatio = self.maxForwardGearRatioOrigin
		self.minBackwardGearRatio = self.minBackwardGearRatioOrigin
		self.maxBackwardGearRatio = self.maxBackwardGearRatioOrigin
	else
		self.maxForwardSpeed = self.maxBackwardSpeedOrigin
		self.maxBackwardSpeed = self.maxForwardSpeedOrigin
		self.minForwardGearRatio = self.minBackwardGearRatioOrigin
		self.maxForwardGearRatio = self.maxBackwardGearRatioOrigin
		self.minBackwardGearRatio = self.minForwardGearRatioOrigin
		self.maxBackwardGearRatio = self.maxForwardGearRatioOrigin
	end
	self.transmissionDirection = direction
end
function VehicleMotor:getMinMaxGearRatio()
	local minRatio = self.minGearRatio
	local maxRatio = self.maxGearRatio
	if self.minGearRatio ~= 0 or self.maxGearRatio ~= 0 then
		if self.clutchSlippingTimer == self.clutchSlippingTime then
			maxRatio = math.max(350, self.maxGearRatio) * math.sign(self.maxGearRatio)
			return minRatio, maxRatio
		end
		if 0 < self.clutchSlippingTimer then
			minRatio = MathUtil.lerp(minRatio, self.clutchSlippingGearRatio, self.clutchSlippingTimer / self.clutchSlippingTime)
			maxRatio = MathUtil.lerp(maxRatio, self.clutchSlippingGearRatio, self.clutchSlippingTimer / self.clutchSlippingTime)
		end
	end
	return minRatio, maxRatio
end
function VehicleMotor:getGearRatio()
	return self.gearRatio
end
function VehicleMotor:getGearRatioMultiplier()
	local multiplier = self.directionChangeUseGroup and 1 or self.currentDirection
	if self.gearGroups ~= nil then
		if self.activeGearGroupIndex == 0 then
			return 0
		end
		local group = self.gearGroups[self.activeGearGroupIndex]
		if group ~= nil then
			return group.ratio * multiplier
		end
	end
	return multiplier
end
function VehicleMotor:getIsInNeutral()
	if (self.backwardGears or self.forwardGears) and (self.gear == 0 and self.targetGear == 0) then
		return true
	end
	return false
end
function VehicleMotor:getCanMotorRun()
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (not self.vehicle:getIsMotorStarted() and ((self.backwardGears or self.forwardGears) and (self.manualClutchValue == 0 and self.maxGearRatio ~= 0))) then
		local factor = 1
		local motorRpm = self:getNonClampedMotorRpm()
		if 0 < motorRpm then
			factor = (self:getClutchRpm() + 50) / motorRpm
		end
		if factor < 0.2 then
			return false, VehicleMotor.REASON_CLUTCH_NOT_ENGAGED
		end
	end
	return true
end
function VehicleMotor:getCurMaxRpm()
	local maxRpm = self.maxRpm
	local gearRatio = self:getGearRatio()
	if gearRatio ~= 0 then
		local speedLimit = math.min(self.speedLimit, math.max(self.speedLimitAcc, self.vehicle.lastSpeedReal * 3600)) * 0.277778
		if 0 < gearRatio then
			speedLimit = math.min(speedLimit, self.maxForwardSpeed)
		else
			speedLimit = math.min(speedLimit, self.maxBackwardSpeed)
		end
		maxRpm = math.min(maxRpm, speedLimit * 30 / 3.141592653589793 * math.abs(gearRatio))
	end
	maxRpm = math.min(maxRpm, self.rpmLimit)
	return maxRpm
end
function VehicleMotor:setSpeedLimit(limit)
	self.speedLimit = math.max(limit, self.minSpeed)
end
function VehicleMotor:getSpeedLimit()
	return self.speedLimit
end
function VehicleMotor:setAccelerationLimit(accelerationLimit)
	self.accelerationLimit = accelerationLimit
end
function VehicleMotor:getAccelerationLimit()
	return self.accelerationLimit
end
function VehicleMotor:setRpmLimit(rpmLimit)
	self.rpmLimit = rpmLimit
end
function VehicleMotor:setMotorRotationAccelerationLimit(limit)
	self.motorRotationAccelerationLimit = limit
end
function VehicleMotor:getMotorRotationAccelerationLimit()
	return self.motorRotationAccelerationLimit
end
function VehicleMotor:setDirectionChangeMode(directionChangeMode)
	self.directionChangeMode = directionChangeMode
end
function VehicleMotor:setGearShiftMode(gearShiftMode)
	self.gearShiftMode = gearShiftMode
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
		self.gearShiftMode = VehicleMotor.SHIFT_MODE_MANUAL
	end
end
function VehicleMotor:getUseAutomaticGearShifting()
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_AUTOMATIC then
		return true
	elseif not self.manualShiftGears then
		return true
	else
		return false
	end
end
function VehicleMotor:getUseAutomaticGroupShifting()
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_AUTOMATIC then
		return true
	elseif not self.manualShiftGroups then
		return true
	else
		return false
	end
end
