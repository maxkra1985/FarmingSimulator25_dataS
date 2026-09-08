-- Local values: VehicleMotor_mt, MODULATION_SPEED, MODULATION_RPM_MAX_OFFSET, MODULATION_RPM_MIN_REF_LOAD, MODULATION_RPM_MAX_REF_LOAD, MODULATION_RPM_MIN_INTENSITY, MODULATION_LOAD_MAX_OFFSET, MODULATION_LOAD_MIN_REF_LOAD, MODULATION_LOAD_MAX_REF_LOAD, MODULATION_LOAD_MIN_INTENSITY, MAX_ACCELERATION_LOAD
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

-- Upvalues: VehicleMotor_mt
-- Local values: self, i, i, numKeyFrames, i, v0, v1, torque0, torque1, rpm, torque, power, v, rotSpeed, torque
function VehicleMotor.new(vehicle, minRpm, maxRpm, maxForwardSpeed, maxBackwardSpeed, torqueCurve, brakeForce, forwardGears, backwardGears, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, ptoMotorRpmRatio, minSpeed)
	-- upvalues: (copy) VehicleMotor_mt
	local v27_ = VehicleMotor_mt
	local v28_ = setmetatable({}, v27_)
	v28_.vehicle = vehicle
	v28_.minRpm = minRpm
	v28_.maxRpm = maxRpm
	v28_.minSpeed = minSpeed
	v28_.maxForwardSpeed = maxForwardSpeed
	v28_.maxBackwardSpeed = maxBackwardSpeed
	v28_.maxClutchTorque = 5
	v28_.torqueCurve = torqueCurve
	v28_.brakeForce = brakeForce
	v28_.lastAcceleratorPedal = 0
	v28_.idleGearChangeTimer = 0
	v28_.doSecondBestGearSelection = 0
	v28_.gear = 0
	v28_.bestGearSelected = 0
	v28_.minGearRatio = 0
	v28_.maxGearRatio = 0
	v28_.allowGearChangeTimer = 0
	v28_.allowGearChangeDirection = 0
	v28_.forwardGears = forwardGears
	v28_.backwardGears = backwardGears
	v28_.currentGears = v28_.forwardGears
	v28_.minForwardGearRatio = minForwardGearRatio
	v28_.maxForwardGearRatio = maxForwardGearRatio
	v28_.minBackwardGearRatio = minBackwardGearRatio
	v28_.maxBackwardGearRatio = maxBackwardGearRatio
	v28_.transmissionDirection = 1
	v28_.maxClutchSpeedDifference = 0
	v28_.defaultForwardGear = 1
	if v28_.forwardGears ~= nil then
		for v29_ = 1, #v28_.forwardGears do
			local v30_ = v28_.maxClutchSpeedDifference
			local v31_ = v28_.minRpm / v28_.forwardGears[v29_].ratio * 3.141592653589793 / 30
			v28_.maxClutchSpeedDifference = math.max(v30_, v31_)
			if v28_.forwardGears[v29_].default then
				v28_.defaultForwardGear = v29_
			end
		end
	end
	v28_.defaultBackwardGear = 1
	if v28_.backwardGears ~= nil then
		for v32_ = 1, #v28_.backwardGears do
			local v33_ = v28_.maxClutchSpeedDifference
			local v34_ = v28_.minRpm / v28_.backwardGears[v32_].ratio * 3.141592653589793 / 30
			v28_.maxClutchSpeedDifference = math.max(v33_, v34_)
			if v28_.backwardGears[v32_].default then
				v28_.defaultBackwardGear = v32_
			end
		end
	end
	v28_.gearType = VehicleMotor.TRANSMISSION_TYPE.DEFAULT
	v28_.groupType = VehicleMotor.TRANSMISSION_TYPE.DEFAULT
	v28_.manualTargetGear = nil
	v28_.targetGear = 0
	v28_.previousGear = 0
	v28_.gearChangeTimer = -1
	v28_.gearChangeTime = 250
	v28_.gearChangeTimeOrig = v28_.gearChangeTime
	v28_.autoGearChangeTimer = -1
	v28_.autoGearChangeTime = 1000
	v28_.manualClutchValue = 0
	v28_.stallTimer = 0
	v28_.lastGearChangeTime = 0
	v28_.gearChangeTimeAutoReductionTime = 500
	v28_.gearChangeTimeAutoReductionTimer = 0
	v28_.lastManualShifterActive = false
	v28_.clutchSlippingTime = 1000
	v28_.clutchSlippingTimer = 0
	v28_.clutchSlippingGearRatio = 0
	v28_.groupChangeTime = 500
	v28_.groupChangeTimer = 0
	v28_.gearGroupUpShiftTime = 3000
	v28_.gearGroupUpShiftTimer = 0
	v28_.currentDirection = 1
	v28_.directionChangeTimer = 0
	v28_.directionChangeTime = 500
	v28_.directionChangeUseGear = false
	v28_.directionChangeGearIndex = 1
	v28_.directionLastGear = -1
	v28_.directionChangeUseGroup = false
	v28_.directionChangeGroupIndex = 1
	v28_.directionLastGroup = -1
	v28_.directionChangeUseInverse = true
	v28_.gearChangedIsLocked = false
	v28_.gearGroupChangedIsLocked = false
	v28_.startGearValues = {
		["slope"] = 0,
		["mass"] = 0,
		["lastMass"] = 0,
		["maxForce"] = 0,
		["massDirectionDifferenceXZ"] = 0,
		["massDirectionDifferenceY"] = 0,
		["massDirectionFactor"] = 0,
		["availablePower"] = 0,
		["massFactor"] = 0
	}
	v28_.startGearThreshold = VehicleMotor.GEAR_START_THRESHOLD
	v28_.lastSmoothedClutchPedal = 0
	v28_.lastRealMotorRpm = 0
	v28_.lastMotorRpm = 0
	v28_.lastModulationPercentage = 0
	v28_.lastModulationTimer = 0
	v28_.rawLoadPercentage = 0
	v28_.rawLoadPercentageBuffer = 0
	v28_.rawLoadPercentageBufferIndex = 0
	v28_.smoothedLoadPercentage = 0
	v28_.loadPercentageChangeCharge = 0
	v28_.accelerationLimitLoadScale = 1
	v28_.accelerationLimitLoadScaleTimer = 0
	v28_.accelerationLimitLoadScaleDelay = 2000
	v28_.constantRpmCharge = 0
	v28_.constantAccelerationCharge = 0
	v28_.lastTurboScale = 0
	v28_.blowOffValveState = 0
	v28_.overSpeedTimer = 0
	v28_.rpmLimit = math.huge
	v28_.speedLimit = math.huge
	v28_.speedLimitAcc = math.huge
	v28_.accelerationLimit = 2
	v28_.motorRotationAccelerationLimit = (maxRpm - minRpm) * 3.141592653589793 / 30 / 2
	v28_.equalizedMotorRpm = 0
	v28_.requiredMotorPower = 0
	if v28_.maxForwardSpeed == nil then
		v28_.maxForwardSpeed = v28_:calculatePhysicalMaximumForwardSpeed()
	end
	if v28_.maxBackwardSpeed == nil then
		v28_.maxBackwardSpeed = v28_:calculatePhysicalMaximumBackwardSpeed()
	end
	v28_.maxForwardSpeedOrigin = v28_.maxForwardSpeed
	v28_.maxBackwardSpeedOrigin = v28_.maxBackwardSpeed
	v28_.minForwardGearRatioOrigin = v28_.minForwardGearRatio
	v28_.maxForwardGearRatioOrigin = v28_.maxForwardGearRatio
	v28_.minBackwardGearRatioOrigin = v28_.minBackwardGearRatio
	v28_.maxBackwardGearRatioOrigin = v28_.maxBackwardGearRatio
	v28_.peakMotorTorque = v28_.torqueCurve:getMaximum()
	v28_.peakMotorPower = 0
	v28_.peakMotorPowerRotSpeed = 0
	local v35_ = #v28_.torqueCurve.keyframes
	if v35_ >= 2 then
		for v36_ = 2, v35_ do
			local v37_ = v28_.torqueCurve.keyframes[v36_ - 1]
			local v38_ = v28_.torqueCurve.keyframes[v36_]
			local v39_ = v28_.torqueCurve:getFromKeyframes(v37_, v37_, v36_ - 1, v36_ - 1, 0)
			local v40_ = v28_.torqueCurve:getFromKeyframes(v38_, v38_, v36_, v36_, 0)
			local v41_ = v39_ - v40_
			local v42_
			if math.abs(v41_) > 0.0001 then
				local v43_ = (v38_.time * v39_ - v37_.time * v40_) / (2 * (v39_ - v40_))
				local v44_ = v37_.time
				local v45_ = math.max(v43_, v44_)
				local v46_ = v38_.time
				v42_ = math.min(v45_, v46_)
				v39_ = v28_.torqueCurve:getFromKeyframes(v37_, v38_, v36_ - 1, v36_, (v38_.time - v42_) / (v38_.time - v37_.time))
			else
				v42_ = v37_.time
			end
			local v47_ = v39_ * v42_
			if v28_.peakMotorPower < v47_ then
				v28_.peakMotorPower = v47_
				v28_.peakMotorPowerRotSpeed = v42_
			end
		end
		v28_.peakMotorPower = v28_.peakMotorPower * 3.141592653589793 / 30
		v28_.peakMotorPowerRotSpeed = v28_.peakMotorPowerRotSpeed * 3.141592653589793 / 30
	else
		local v48_ = v28_.torqueCurve.keyframes[1]
		local v49_ = v48_.time * 3.141592653589793 / 30
		v28_.peakMotorPower = v49_ * v28_.torqueCurve:getFromKeyframes(v48_, v48_, 1, 1, 0)
		v28_.peakMotorPowerRotSpeed = v49_
	end
	v28_.ptoMotorRpmRatio = ptoMotorRpmRatio
	v28_.rotInertia = v28_.peakMotorTorque / 600
	v28_.dampingRateFullThrottle = VehicleMotor.DEFAULT_DAMPING_RATE_FULL_THROTTLE
	v28_.dampingRateZeroThrottleClutchEngaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_EN
	v28_.dampingRateZeroThrottleClutchDisengaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_DIS
	v28_.gearRatio = 0
	v28_.motorRotSpeed = 0
	v28_.motorRotSpeedClutchEngaged = 0
	v28_.motorRotAcceleration = 0
	v28_.motorRotAccelerationSmoothed = 0
	v28_.motorAvailableTorque = 0
	v28_.lastMotorAvailableTorque = 0
	v28_.motorAppliedTorque = 0
	v28_.lastMotorAppliedTorque = 0
	v28_.motorExternalTorque = 0
	v28_.lastMotorExternalTorque = 0
	v28_.externalTorqueVirtualMultiplicator = 1
	v28_.differentialRotSpeed = 0
	v28_.differentialRotAcceleration = 0
	v28_.differentialRotAccelerationSmoothed = 0
	v28_.differentialRotAccelerationIndex = 1
	v28_.differentialRotAccelerationSamples = {}
	local v50_ = v28_.differentialRotAccelerationSamples
	table.insert(v50_, 0)
	local v51_ = v28_.differentialRotAccelerationSamples
	table.insert(v51_, 0)
	local v52_ = v28_.differentialRotAccelerationSamples
	table.insert(v52_, 0)
	local v53_ = v28_.differentialRotAccelerationSamples
	table.insert(v53_, 0)
	local v54_ = v28_.differentialRotAccelerationSamples
	table.insert(v54_, 0)
	local v55_ = v28_.differentialRotAccelerationSamples
	table.insert(v55_, 0)
	local v56_ = v28_.differentialRotAccelerationSamples
	table.insert(v56_, 0)
	local v57_ = v28_.differentialRotAccelerationSamples
	table.insert(v57_, 0)
	local v58_ = v28_.differentialRotAccelerationSamples
	table.insert(v58_, 0)
	local v59_ = v28_.differentialRotAccelerationSamples
	table.insert(v59_, 0)
	v28_.lastDifference = 0
	v28_.directionChangeMode = g_gameSettings:getValue(GameSettings.SETTING.DIRECTION_CHANGE_MODE)
	v28_.gearShiftMode = g_gameSettings:getValue(GameSettings.SETTING.GEAR_SHIFT_MODE)
	return v28_
end

function VehicleMotor:postLoad(savegame)
	if self.gearGroups ~= nil then
		SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, 0)
	end
end

function VehicleMotor:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: i, i
function VehicleMotor:setGearGroups(gearGroups, groupType, groupChangeTime)
	self.gearGroups = gearGroups
	self.groupType = VehicleMotor.TRANSMISSION_TYPE[string.upper(groupType)] or VehicleMotor.TRANSMISSION_TYPE.DEFAULT
	self.groupChangeTime = groupChangeTime
	if gearGroups ~= nil then
		self.numGearGroups = #gearGroups
		self.defaultGearGroup = 1
		for v66_ = 1, self.numGearGroups do
			if self.gearGroups[v66_].ratio > 0 then
				self.defaultGearGroup = v66_
				break
			end
		end
		for v67_ = 1, self.numGearGroups do
			if self.gearGroups[v67_].isDefault then
				self.defaultGearGroup = v67_
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
	local v74_ = not directionChangeUseGear
	if v74_ then
		v74_ = not directionChangeUseGroup
	end
	self.directionChangeUseInverse = v74_
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
	local v94_ = self.gearChangeTimer
	self.gearChangeTimer = math.min(v94_, gearChangeTime)
	self.gearType = gearChangeTime == 0 and VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT or VehicleMotor.TRANSMISSION_TYPE.DEFAULT
end

function VehicleMotor:setAutoGearChangeTime(autoGearChangeTime)
	self.autoGearChangeTime = autoGearChangeTime
	local v97_ = self.autoGearChangeTimer
	self.autoGearChangeTimer = math.min(v97_, autoGearChangeTime)
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

-- Local values: motorPtoRpm
function VehicleMotor:getRequiredMotorRpmRange()
	local v103_ = PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio
	local v104_ = self.maxRpm
	local v105_ = math.min(v103_, v104_)
	if v105_ == 0 then
		return self.minRpm, self.maxRpm
	else
		return v105_, self.maxRpm
	end
end

function VehicleMotor:getLastMotorRpm()
	return self.lastMotorRpm
end

-- Upvalues: MODULATION_RPM_MIN_REF_LOAD, MODULATION_RPM_MAX_REF_LOAD, MODULATION_RPM_MIN_INTENSITY, MODULATION_RPM_MAX_OFFSET
-- Local values: modulationIntensity, modulationOffset, loadChangeChargeDrop, rpmRange, dropScale
function VehicleMotor:getLastModulatedMotorRpm()
	-- upvalues: (copy) MODULATION_RPM_MIN_REF_LOAD, (copy) MODULATION_RPM_MAX_REF_LOAD, (copy) MODULATION_RPM_MIN_INTENSITY, (copy) MODULATION_RPM_MAX_OFFSET
	local v108_ = (self.smoothedLoadPercentage - 0.1) / 0.9
	local v109_ = math.clamp(v108_, 0.01, 1)
	local v110_ = self.lastModulationPercentage * (150 * v109_) * self.constantRpmCharge
	local v111_ = 0
	if self:getClutchPedal() < 0.1 and self.minGearRatio > 0 then
		local v112_ = self.maxRpm - self.minRpm
		local v113_ = (self.lastMotorRpm - self.minRpm) / v112_ * 0.5
		v111_ = self.loadPercentageChangeCharge * v112_ * v113_
	else
		self.loadPercentageChangeCharge = 0
	end
	return self.lastMotorRpm == 0 and 0 or self.lastMotorRpm + v110_ - v111_
end

function VehicleMotor:getLastRealMotorRpm()
	return self.lastRealMotorRpm
end

-- Upvalues: MODULATION_LOAD_MIN_REF_LOAD, MODULATION_LOAD_MAX_REF_LOAD, MODULATION_LOAD_MIN_INTENSITY, MODULATION_LOAD_MAX_OFFSET
-- Local values: modulationIntensity
function VehicleMotor:getSmoothLoadPercentage()
	-- upvalues: (copy) MODULATION_LOAD_MIN_REF_LOAD, (copy) MODULATION_LOAD_MAX_REF_LOAD, (copy) MODULATION_LOAD_MIN_INTENSITY, (copy) MODULATION_LOAD_MAX_OFFSET
	local v116_ = (self.smoothedLoadPercentage - 0) / 0.5
	local v117_ = math.clamp(v116_, 0, 1)
	return self.smoothedLoadPercentage - self.lastModulationPercentage * (0.05 * v117_)
end

-- Local values: clutchRpm
function VehicleMotor:getClutchPedal()
	if not self.vehicle.isServer or self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
		return self.manualClutchValue
	end
	local v119_ = self:getNonClampedMotorRpm()
	if v119_ == 0 then
		return 0
	end
	local v120_ = (self:getClutchRotSpeed() * 30 / 3.141592653589793 + 50) / v119_
	local v121_ = math.min(v120_, 1)
	return 1 - math.max(v121_, 0)
end

function VehicleMotor:getSmoothedClutchPedal()
	return self.lastSmoothedClutchPedal
end

function VehicleMotor:getManualClutchPedal()
	return self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and 0 or self.manualClutchValue
end

-- Local values: gearName, gear, gearNameDirection, direction
function VehicleMotor:getGearToDisplay(isDashboard)
	local v126_ = "N"
	if self.backwardGears or self.forwardGears then
		if self.targetGear > 0 then
			local v127_ = self.currentGears[self.targetGear]
			if v127_ ~= nil then
				local v128_ = self.currentGears == self.forwardGears and self.currentDirection or 1
				if isDashboard then
					return v128_ == 1 and (v127_.dashboardName or v127_.name) or (v127_.dashboardReverseName or v127_.reverseName)
				else
					return v128_ == 1 and v127_.name or v127_.reverseName
				end
			end
		end
	else
		local v129_ = self:getDrivingDirection()
		if v129_ > 0 then
			return "D"
		end
		v126_ = v129_ < 0 and "R" or v126_
	end
	return v126_
end

-- Local values: gearName, available, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isAutomatic, isGearChanging, gear, displayDirection, gearNameDirection, prevGear, nextGear, direction
function VehicleMotor:getGearInfoToDisplay()
	local v131_ = "N"
	local v132_ = false
	local v133_ = nil
	local v134_ = nil
	local v135_ = nil
	local v136_ = nil
	local v137_ = false
	local v138_ = false
	if self.backwardGears or self.forwardGears then
		if self.targetGear > 0 then
			local v139_ = self.currentGears[self.targetGear]
			if v139_ ~= nil then
				local v140_ = self.currentDirection
				local v141_ = self.currentGears == self.forwardGears and (self.currentDirection or 1) or 1
				v131_ = v141_ == 1 and v139_.name or v139_.reverseName
				local v142_ = self.currentGears[self.targetGear + 1 * -v140_]
				if v142_ ~= nil then
					v133_ = v141_ == 1 and v142_.name or v142_.reverseName
					local v143_ = self.currentGears[self.targetGear + 2 * -v140_]
					if v143_ ~= nil then
						v135_ = v141_ == 1 and v143_.name or v143_.reverseName
					end
				end
				local v144_ = self.currentGears[self.targetGear + 1 * v140_]
				if v144_ ~= nil then
					v134_ = v141_ == 1 and v144_.name or v144_.reverseName
					local v145_ = self.currentGears[self.targetGear + 2 * v140_]
					if v145_ ~= nil then
						v136_ = v141_ == 1 and v145_.name or v145_.reverseName
					end
				end
				if self.gear ~= self.targetGear then
					v138_ = true
				end
			end
		end
		v132_ = true
	else
		local v146_ = self:getDrivingDirection()
		if v146_ > 0 then
			v131_ = "D"
			v133_ = "N"
		elseif v146_ < 0 then
			v131_ = "R"
			v134_ = "N"
		else
			v133_ = "R"
			v134_ = "D"
		end
		v137_ = true
	end
	return v131_, v132_, v137_, v133_, v134_, v135_, v136_, v138_
end

function VehicleMotor:getDrivingDirection()
	if self.directionChangeMode == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL or (self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_AUTOMATIC or (self.backwardGears or self.forwardGears)) then
		return self.currentDirection * self.transmissionDirection
	else
		return self.vehicle:getLastSpeed() <= 0.95 and 0 or self.vehicle.movingDirection * self.transmissionDirection
	end
end

-- Local values: gearGroupName, available, gearGroup
function VehicleMotor:getGearGroupToDisplay(isDashboard)
	local v150_ = "N"
	local v151_
	if (self.backwardGears or self.forwardGears) and self.gearGroups ~= nil then
		if self.activeGearGroupIndex > 0 then
			local v152_ = self.gearGroups[self.activeGearGroupIndex]
			if v152_ ~= nil then
				if isDashboard then
					v150_ = v152_.dashboardName or v152_.name
				else
					v150_ = v152_.name
				end
			end
		end
		v151_ = true
	else
		v151_ = false
	end
	return v150_, v151_
end

-- Local values: gear, changingGear, activeGearGroupIndex, directionMultiplier
function VehicleMotor:readGearDataFromStream(streamId)
	self.currentDirection = streamReadUIntN(streamId, 2) - 1
	if streamReadBool(streamId) then
		local v155_ = streamReadUIntN(streamId, 6)
		local v156_ = streamReadBool(streamId)
		if streamReadBool(streamId) then
			self.currentGears = self.forwardGears
		else
			self.currentGears = self.backwardGears
		end
		local v157_
		if self.gearGroups == nil then
			v157_ = nil
		else
			v157_ = streamReadUIntN(streamId, 5)
		end
		if v155_ ~= self.gear then
			if v156_ and self.gear ~= 0 then
				self.lastGearChangeTime = g_time
			end
			self.previousGear = self.gear
			self.gear = v156_ and 0 or v155_
			self.targetGear = v155_
			local v158_ = self.directionChangeUseGear and (self.currentDirection or 1) or 1
			SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * v158_, self.targetGear * v158_, 0, self.previousGear)
		end
		if v157_ ~= self.activeGearGroupIndex then
			self.activeGearGroupIndex = v157_
			SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, self.groupType == VehicleMotor.TRANSMISSION_TYPE.DEFAULT and self.groupChangeTime or 0)
		end
	end
end

function VehicleMotor:writeGearDataToStream(streamId)
	local v161_ = streamWriteUIntN
	local v162_ = self.currentDirection
	v161_(streamId, math.sign(v162_) + 1, 2)
	if streamWriteBool(streamId, self.backwardGears ~= nil and true or self.forwardGears ~= nil) then
		streamWriteUIntN(streamId, self.targetGear, 6)
		streamWriteBool(streamId, self.targetGear ~= self.gear)
		streamWriteBool(streamId, self.currentGears == self.forwardGears)
		if self.gearGroups ~= nil then
			streamWriteUIntN(streamId, self.activeGearGroupIndex, 5)
		end
	end
end

-- Local values: oldMotorRpm, interpolationSpeed, rpmPercentage, targetTurboRpm, blowOffValveState
function VehicleMotor:setLastRpm(lastRpm)
	local v165_ = self.lastMotorRpm
	self.lastRealMotorRpm = lastRpm
	local v166_ = self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT and g_time - self.lastGearChangeTime < 200 and 0.2 or 0.05
	self.lastMotorRpm = self.lastMotorRpm * (1 - v166_) + self.lastRealMotorRpm * v166_
	local v167_ = self.lastMotorRpm
	local v168_ = self.lastPtoRpm or self.minRpm
	local v169_ = self.minRpm
	local v170_ = (v167_ - math.max(v168_, v169_)) / (self.maxRpm - self.minRpm) * self:getSmoothLoadPercentage()
	self.lastTurboScale = self.lastTurboScale * 0.95 + v170_ * 0.05
	local v171_ = self.blowOffValveState
	if self.lastAcceleratorPedal == 0 or self.minGearRatio == 0 and self.autoGearChangeTime > 0 then
		self.blowOffValveState = self.lastTurboScale
	else
		self.blowOffValveState = 0
	end
	if self.blowOffValveState > 0 ~= (v171_ > 0) then
		SpecializationUtil.raiseEvent(self.vehicle, "onMotorBlowOffValveChanged", self.blowOffValveState)
	end
	local v172_ = self.lastMotorRpm - v165_
	local v173_ = math.abs(v172_) * 0.15
	self.constantRpmCharge = 1 - math.min(v173_, 1)
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

-- Local values: torque
function VehicleMotor:getTorque(acceleration)
	local v190_ = self.motorRotSpeed * 30 / 3.141592653589793
	local v191_ = self.minRpm
	local v192_ = self.maxRpm
	return self:getTorqueCurveValue((math.clamp(v190_, v191_, v192_))) * math.abs(acceleration)
end

-- Local values: damage
function VehicleMotor:getTorqueCurveValue(rpm)
	local v195_ = 1 - self.vehicle:getVehicleDamage() * VehicleMotor.DAMAGE_TORQUE_REDUCTION
	return self:getTorqueCurve():get(rpm) * v195_
end

-- Local values: rotationSpeeds, torques, _, v
function VehicleMotor:getTorqueAndSpeedValues()
	local v197_ = {}
	local v198_ = {}
	for _, v199_ in ipairs(self:getTorqueCurve().keyframes) do
		local v200_ = v199_.time * 3.141592653589793 / 30
		table.insert(v197_, v200_)
		local v201_ = v199_.time
		table.insert(v198_, self:getTorqueCurveValue(v201_))
	end
	return v198_, v197_
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

-- Local values: minRatio, _, gear
function VehicleMotor.calculatePhysicalMaximumSpeed(minGearRatio, gears, maxRpm)
	if minGearRatio == nil then
		if gears == nil then
			printCallstack()
			return 0
		end
		minGearRatio = math.huge
		for _, v209_ in pairs(gears) do
			local v210_ = v209_.ratio
			minGearRatio = math.min(minGearRatio, v210_)
		end
	end
	return maxRpm * 3.141592653589793 / (30 * minGearRatio)
end

-- Upvalues: MAX_ACCELERATION_LOAD, MODULATION_SPEED
-- Local values: vehicle, lastMotorRotSpeed, lastDiffRotSpeed, minDifferentialSpeed, accelerationPedal, clutchValue, direction, accelerationSpeed, minRotSpeed, maxRotSpeed, motorRotAcceleration, differentialRotAcceleration, _, gearRatio, ptoRpm, clampedMotorRpm, rawLoadPercentage, idleLoadPct, accelerationPercentage, alpha, clutchPedal
function VehicleMotor:update(dt)
	-- upvalues: (copy) MAX_ACCELERATION_LOAD, (copy) MODULATION_SPEED
	local v213_ = self.vehicle
	if next(v213_.spec_motorized.differentials) == nil or v213_.spec_motorized.motorizedNode == nil then
		local _, v214_ = self:getMinMaxGearRatio()
		self.differentialRotSpeed = WheelsUtil.computeDifferentialRotSpeedNonMotor(v213_)
		local v215_ = self.differentialRotSpeed * v214_
		local v216_ = math.abs(v215_)
		self.motorRotSpeed = math.max(v216_, 0)
		self.gearRatio = v214_
	else
		local v217_ = self.motorRotSpeed
		local v218_ = self.differentialRotSpeed
		local v219_, v220_, v221_ = getMotorRotationSpeed(v213_.spec_motorized.motorizedNode)
		self.motorRotSpeed = v219_
		self.differentialRotSpeed = v220_
		self.gearRatio = v221_
		if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (self.backwardGears or self.forwardGears) and (self.gearRatio ~= 0 and (self.maxGearRatio ~= 0 and self.lastAcceleratorPedal ~= 0)) then
			local v222_ = self.minRpm
			local v223_ = self.maxGearRatio
			local v224_ = v222_ / math.abs(v223_) * 3.141592653589793 / 30
			local v225_ = self.differentialRotSpeed
			if math.abs(v225_) < v224_ * 0.75 then
				self.clutchSlippingTimer = self.clutchSlippingTime
				self.clutchSlippingGearRatio = self.gearRatio
			else
				local v226_ = self.clutchSlippingTimer - dt
				self.clutchSlippingTimer = math.max(v226_, 0)
			end
		end
		if not self:getUseAutomaticGearShifting() then
			local v227_ = self.lastAcceleratorPedal * self.currentDirection
			local v228_ = ((self.minGearRatio == 0 and self.maxGearRatio == 0 or self.manualClutchValue > 0.1) and 1 or 0) * v227_
			local v229_ = v228_ == 0 and -1 or v228_
			local v230_ = v229_ > 0 and self.motorRotationAccelerationLimit * 0.02 or self.dampingRateZeroThrottleClutchEngaged * 30 * 3.141592653589793
			local v231_ = self.minRpm * 3.141592653589793 / 30
			local v232_ = self.maxRpm * 3.141592653589793 / 30
			local v233_ = self.motorRotSpeedClutchEngaged + v229_ * v230_ * dt
			local v234_ = math.max(v233_, v231_)
			local v235_ = v231_ + (v232_ - v231_) * v227_
			self.motorRotSpeedClutchEngaged = math.min(v234_, v235_)
			local v236_ = self.motorRotSpeed
			local v237_ = self.motorRotSpeedClutchEngaged
			self.motorRotSpeed = math.max(v236_, v237_)
		end
		if g_physicsDtNonInterpolated > 0 and not getIsSleeping(v213_.rootNode) then
			local v238_, v239_, v240_ = getMotorTorque(v213_.spec_motorized.motorizedNode)
			self.lastMotorAvailableTorque = v238_
			self.lastMotorAppliedTorque = v239_
			self.lastMotorExternalTorque = v240_
		end
		local v241_ = self.lastMotorAvailableTorque
		local v242_ = self.lastMotorAppliedTorque
		local v243_ = self.lastMotorExternalTorque
		self.motorAvailableTorque = v241_
		self.motorAppliedTorque = v242_
		self.motorExternalTorque = v243_
		self.motorAppliedTorque = self.motorAppliedTorque - self.motorExternalTorque
		local v244_ = self.motorExternalTorque * self.externalTorqueVirtualMultiplicator
		local v245_ = self.motorAvailableTorque - self.motorAppliedTorque
		self.motorExternalTorque = math.min(v244_, v245_)
		self.motorAppliedTorque = self.motorAppliedTorque + self.motorExternalTorque
		local v246_, v247_
		if g_physicsDtNonInterpolated > 0 then
			v246_ = (self.motorRotSpeed - v217_) / (g_physicsDtNonInterpolated * 0.001)
			v247_ = (self.differentialRotSpeed - v218_) / (g_physicsDtNonInterpolated * 0.001)
		else
			v246_ = 0
			v247_ = 0
		end
		self.motorRotAcceleration = v246_
		self.motorRotAccelerationSmoothed = 0.8 * self.motorRotAccelerationSmoothed + 0.2 * v246_
		self.differentialRotAcceleration = v247_
		self.differentialRotAccelerationSmoothed = 0.8 * self.differentialRotAccelerationSmoothed + 0.2 * v247_
		self.requiredMotorPower = math.huge
	end
	if self.lastPtoRpm == nil then
		self.lastPtoRpm = self.minRpm
	end
	local v248_ = PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio
	if self.lastPtoRpm < v248_ then
		local v249_ = self.lastPtoRpm + self.maxRpm * dt / 2000
		self.lastPtoRpm = math.min(v248_, v249_)
	elseif v248_ < self.lastPtoRpm then
		local v250_ = self.minRpm
		local v251_ = self.lastPtoRpm - self.maxRpm * dt / 1000
		self.lastPtoRpm = math.max(v250_, v251_)
	end
	if self.vehicle.isServer then
		local v252_ = self.motorRotSpeed * 30 / 3.141592653589793
		local v253_ = self.lastPtoRpm
		local v254_ = self.maxRpm
		local v255_ = math.min(v253_, v254_)
		local v256_ = self.minRpm
		local v257_ = math.max(v252_, v255_, v256_)
		self:setLastRpm(v257_)
		self.equalizedMotorRpm = v257_
		local v258_ = self:getMotorAppliedTorque()
		local v259_ = self:getMotorAvailableTorque()
		local v260_ = v258_ / math.max(v259_, 0.0001)
		self.rawLoadPercentageBuffer = self.rawLoadPercentageBuffer + v260_
		self.rawLoadPercentageBufferIndex = self.rawLoadPercentageBufferIndex + 1
		if self.rawLoadPercentageBufferIndex >= 2 then
			self.rawLoadPercentage = self.rawLoadPercentageBuffer / 2
			self.rawLoadPercentageBuffer = 0
			self.rawLoadPercentageBufferIndex = 0
		end
		if self.rawLoadPercentage < 0.01 and self.lastAcceleratorPedal < 0.2 and (not (self.backwardGears or self.forwardGears) or (self.gear ~= 0 or self.targetGear == 0)) then
			self.rawLoadPercentage = -1
		else
			self.rawLoadPercentage = (self.rawLoadPercentage - 0.05) / 0.95
		end
		local v261_ = self.vehicle.lastSpeedAcceleration * 1000 * 1000 * self.vehicle.movingDirection / self.accelerationLimit
		local v262_ = math.min(v261_, 1)
		if v262_ < 0.95 and self.lastAcceleratorPedal > 0.2 then
			self.accelerationLimitLoadScale = 1
			self.accelerationLimitLoadScaleTimer = self.accelerationLimitLoadScaleDelay
		elseif self.accelerationLimitLoadScaleTimer > 0 then
			self.accelerationLimitLoadScaleTimer = self.accelerationLimitLoadScaleTimer - dt
			local v263_ = self.accelerationLimitLoadScaleTimer / self.accelerationLimitLoadScaleDelay
			local v264_ = (1 - math.max(v263_, 0)) * 3.14
			self.accelerationLimitLoadScale = math.sin(v264_) * 0.85
		end
		if v262_ > 0 then
			local v265_ = self.rawLoadPercentage
			local v266_ = v262_ * self.accelerationLimitLoadScale
			self.rawLoadPercentage = math.max(v265_, v266_)
		end
		local v267_ = self.vehicle.lastSpeedAcceleration
		local v268_ = math.abs(v267_) * 1000 * 1000 / self.accelerationLimit
		self.constantAccelerationCharge = 1 - math.min(v268_, 1)
		if self.rawLoadPercentage > 0 then
			self.rawLoadPercentage = self.rawLoadPercentage * 0.8 + self.rawLoadPercentage * 0.19999999999999996 * self.constantAccelerationCharge
		end
		if (self.backwardGears or self.forwardGears) and self:getUseAutomaticGearShifting() then
			if self.constantRpmCharge > 0.99 then
				if self.maxRpm - v257_ < 50 then
					local v269_ = self.gearChangeTimeAutoReductionTimer + dt
					local v270_ = self.gearChangeTimeAutoReductionTime
					self.gearChangeTimeAutoReductionTimer = math.min(v269_, v270_)
					self.gearChangeTime = self.gearChangeTimeOrig * (1 - self.gearChangeTimeAutoReductionTimer / self.gearChangeTimeAutoReductionTime)
				else
					self.gearChangeTimeAutoReductionTimer = 0
					self.gearChangeTime = self.gearChangeTimeOrig
				end
			else
				self.gearChangeTimeAutoReductionTimer = 0
				self.gearChangeTime = self.gearChangeTimeOrig
			end
		end
	end
	self:updateSmoothLoadPercentage(dt, self.rawLoadPercentage)
	local v271_ = self.idleGearChangeTimer - dt
	self.idleGearChangeTimer = math.max(v271_, 0)
	if self.forwardGears or self.backwardGears then
		self:updateStartGearValues(dt)
		local v272_ = self:getClutchPedal()
		self.lastSmoothedClutchPedal = self.lastSmoothedClutchPedal * 0.9 + v272_ * 0.1
	end
	self.lastModulationTimer = self.lastModulationTimer + dt * 0.0009
	local v273_ = self.lastModulationTimer
	local v274_ = math.sin(v273_)
	local v275_ = (self.lastModulationTimer + 2) * 0.3
	local v276_ = v274_ * math.sin(v275_) * 0.8
	local v277_ = self.lastModulationTimer * 5
	self.lastModulationPercentage = v276_ + math.cos(v277_) * 0.2
end

-- Local values: lastSmoothedLoad, maxSpeed, speedPercentage, factor, invFactor, difference
function VehicleMotor:updateSmoothLoadPercentage(dt, rawLoadPercentage)
	local v281_ = self.smoothedLoadPercentage
	local v282_ = self:getMaximumForwardSpeed() * 3.6
	if self.vehicle.movingDirection < 0 then
		v282_ = self:getMaximumBackwardSpeed() * 3.6
	end
	local v283_ = self.vehicle:getLastSpeed() / v282_
	local v284_ = math.min(v283_, 1)
	local v285_ = 0.05 + (1 - math.max(v284_, 0)) * 0.3
	if rawLoadPercentage < self.smoothedLoadPercentage then
		if self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT and g_time - self.lastGearChangeTime <= 200 then
			v285_ = v285_ * 0.05
		else
			v285_ = v285_ * 0.2
			if self:getClutchPedal() > 0.75 then
				v285_ = v285_ * 5
			end
			if rawLoadPercentage < 0 then
				v285_ = v285_ * 2.5
			end
		end
	end
	self.smoothedLoadPercentage = (1 - v285_) * self.smoothedLoadPercentage + v285_ * rawLoadPercentage
	local v286_ = self.smoothedLoadPercentage - v281_
	local v287_ = math.max(v286_, 0)
	self.loadPercentageChangeCharge = self.loadPercentageChangeCharge + v287_
	local v288_ = self.loadPercentageChangeCharge - dt * 0.0005
	local v289_ = math.max(v288_, 0)
	self.loadPercentageChangeCharge = math.min(v289_, 1)
end

-- Local values: totalMass, totalMassOnGround, vehicleMass, maxForce, vehicles, _, vehicle, multiplier, comX, comY, comZ, dirX, dirY, dirZ, _, vehicle, objectMass, percentage, cx, cy, cz, iDirX, iDirY, iDirZ, vdx, vdy, vdz, vX, vY, vZ, diffXZ, diffY, massDirectionInfluenceFactor, neededPtoTorque, ptoPower, maxForcePowerFactor, mass
function VehicleMotor:updateStartGearValues(dt)
	local v292_ = self.vehicle:getTotalMass()
	local v293_ = 0
	local v294_ = self.vehicle:getTotalMass(true)
	local v295_ = v292_ - self.startGearValues.lastMass
	if math.abs(v295_) > 0.00001 * dt then
		self.startGearValues.lastMass = v292_
		self.idleGearChangeTimer = 500
	end
	local v296_ = self.vehicle:getChildVehicles()
	local v297_ = 0
	for _, v298_ in ipairs(v296_) do
		if v298_ ~= self.vehicle then
			if v298_.spec_powerConsumer ~= nil and (v298_.spec_powerConsumer.maxForce ~= nil and v298_:getPowerMultiplier() ~= 0) then
				v297_ = v297_ + v298_.spec_powerConsumer.maxForce
			end
			if v298_.spec_leveler ~= nil then
				local v299_ = v298_.spec_leveler.lastForce
				v297_ = v297_ + math.abs(v299_)
			end
			if v298_.spec_wheels ~= nil and #v298_.spec_wheels.wheels > 0 then
				v293_ = v293_ + v298_:getTotalMass(true)
			end
		end
	end
	local v300_ = 0
	local v301_ = 0
	local v302_ = 0
	local v303_ = 0
	local v304_ = 0
	local v305_ = 0
	for _, v306_ in ipairs(v296_) do
		if v306_ ~= self.vehicle and (v306_.spec_wheels ~= nil and #v306_.spec_wheels.wheels > 0) then
			local v307_ = v306_:getTotalMass(true) / v293_
			local v308_, v309_, v310_ = v306_:getOverallCenterOfMass()
			v300_ = v300_ + v308_ * v307_
			v301_ = v301_ + v309_ * v307_
			v302_ = v302_ + v310_ * v307_
			local v311_, v312_, v313_ = v306_:getVehicleWorldDirection()
			v303_ = v303_ + v311_ * v307_
			v304_ = v304_ + v312_ * v307_
			v305_ = v305_ + v313_ * v307_
		end
	end
	local v314_, v315_, v316_ = self.vehicle:getVehicleWorldDirection()
	if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
		local v317_, v318_, v319_ = getWorldTranslation(self.vehicle.components[1].node)
		DebugGizmo.renderAtPosition(v300_, v301_, v302_, v303_, v304_, v305_, 0, 1, 0, "TOOLS DIR")
		DebugGizmo.renderAtPosition(v317_, v318_, v319_, v314_, v315_, v316_, 0, 1, 0, "VEHICLE DIR")
	end
	local v320_, v321_
	if v303_ == 0 and (v304_ == 0 and v305_ == 0) then
		v320_ = 0
		v321_ = 0
	else
		local v322_ = v303_ - v314_
		local v323_ = math.abs(v322_)
		local v324_ = v305_ - v316_
		local v325_ = math.abs(v324_)
		v320_ = math.max(v323_, v325_)
		local v326_ = v304_ - v315_
		v321_ = math.max(v326_, 0)
	end
	local v327_ = (v292_ - v294_) / 5
	local v328_ = math.min(v327_, 1)
	self.startGearValues.massDirectionDifferenceXZ = v320_
	self.startGearValues.massDirectionDifferenceY = v321_
	self.startGearValues.massDirectionFactor = (1 + v320_ * v328_) * (1 + v321_ / 0.15 * v328_)
	local v329_ = PowerConsumer.getTotalConsumedPtoTorque(self.vehicle, nil, nil, true) / self:getPtoMotorRpmRatio()
	local v330_ = self.peakMotorPowerRotSpeed * v329_
	self.startGearValues.availablePower = self.peakMotorPower - v330_
	local v331_ = (((v292_ + v297_ * (1 + v330_ / self.peakMotorPower * 0.75)) / v294_ - 1) * 0.5 + 1) * v294_
	self.startGearValues.maxForce = v297_
	self.startGearValues.mass = v331_
	self.startGearValues.slope = self.vehicle:getVehicleWorldXRot()
	self.startGearValues.massFactor = self.startGearValues.mass * self.startGearValues.massDirectionFactor / (((self.startGearValues.availablePower / 100 - 1) * 50 + 100) * 0.4)
end

-- Local values: directionMultiplier, minFactor, minFactorGear, minFactorGroup, maxFactor, maxFactorGear, maxFactorGroup, start, limit, step, j, groupRatio, i, factor, gearRatioMultiplier, i, factor
function VehicleMotor:getBestStartGear(gears)
	local v334_ = self.directionChangeUseGroup and 1 or self.currentDirection
	local v335_ = math.huge
	local v336_ = 1
	local v337_ = 1
	local v338_ = 0
	local v339_ = 1
	local v340_ = 1
	if self.gearGroups == nil then
		local v341_ = self:getGearRatioMultiplier()
		for v342_ = #gears, 1, -1 do
			local v343_ = self:getStartInGearFactor(gears[v342_].ratio * v341_)
			if v343_ < self.startGearThreshold then
				if v338_ == 0 then
					v339_ = v342_
					v338_ = v343_
				end
			end
			if v343_ < v335_ then
				v336_ = v342_
				v335_ = v343_
			end
		end
	elseif self:getUseAutomaticGroupShifting() then
		local v344_ = #self.gearGroups
		local v345_, v346_
		if self.currentDirection < 0 then
			v345_ = #self.gearGroups
			v344_ = 1
			v346_ = 1
		else
			v345_ = 1
			v346_ = -1
		end
		for v347_ = v344_, v345_, v346_ do
			local v348_ = self.gearGroups[v347_].ratio * v334_
			if math.sign(v348_) == self.currentDirection or not self.directionChangeUseGroup then
				for v349_ = #gears, 1, -1 do
					local v350_ = self:getStartInGearFactor(gears[v349_].ratio * v348_)
					if v350_ < self.startGearThreshold then
						if v338_ == 0 then
							v340_ = v347_
							v339_ = v349_
							v338_ = v350_
						end
					end
					if v350_ < v335_ then
						v337_ = v347_
						v336_ = v349_
						v335_ = v350_
					end
				end
			end
		end
	end
	if v338_ == 0 then
		return v336_, v337_
	else
		return v339_, v340_
	end
end

-- Local values: speedLimit
function VehicleMotor:getRequiredRpmAtSpeedLimit(ratio)
	local v353_ = self.vehicle:getSpeedLimit(true)
	local v354_ = self.speedLimitAcc
	local v355_ = self.vehicle.lastSpeedReal * 3600
	local v356_ = math.max(v354_, v355_)
	local v357_ = math.min(v353_, v356_)
	if self.vehicle:getCruiseControlState() == Drivable.CRUISECONTROL_STATE_ACTIVE then
		local v358_ = self.vehicle
		v357_ = math.min(v357_, v358_:getCruiseControlSpeed())
	end
	if ratio > 0 then
		local v359_ = self.maxForwardSpeed * 3.6
		v361_ = math.min(v357_, v359_)
		if v361_ then
			::l5::
			return v361_ / 3.6 * 30 / 3.141592653589793 * math.abs(ratio)
		end
	end
	local v360_ = self.maxBackwardSpeed * 3.6
	local v361_ = math.min(v357_, v360_)
	goto l5
end

-- Local values: slope, slopePowerFactor, slopeFactor
function VehicleMotor:getStartInGearFactor(ratio)
	if self:getRequiredRpmAtSpeedLimit(ratio) < self.minRpm + (self.maxRpm - self.minRpm) * 0.25 then
		return math.huge
	end
	local v364_ = self.startGearValues.slope
	if ratio < 0 then
		v364_ = -v364_
	end
	local v365_ = ((self.startGearValues.availablePower / 100 - 1) / 2) ^ 2 * 2 + 1
	local v366_ = 1 + math.max(v364_, 0) / (v365_ * 0.06981)
	return self.startGearValues.massFactor * v366_ / (math.abs(ratio) / 300)
end

-- Local values: gearRatio, bestMotorPower, bestGearRatio, gearRatio, motorRpm, motorPower
function VehicleMotor:getBestGearRatio(wheelSpeedRpm, minRatio, maxRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
	if requiredMotorRpm ~= 0 then
		local v374_ = requiredMotorRpm - accSafeMotorRpm
		local v375_ = requiredMotorRpm * 0.8
		local v376_ = math.max(v374_, v375_) / math.max(wheelSpeedRpm, 0.001)
		return math.clamp(v376_, minRatio, maxRatio)
	end
	local v377_ = math.max(wheelSpeedRpm, 0.0001)
	local v378_ = 0
	for v379_ = minRatio, maxRatio, 0.5 do
		local v380_ = v377_ * v379_
		if self.maxRpm - accSafeMotorRpm < v380_ then
			break
		end
		local v381_ = self.minRpm
		local v382_ = self:getTorqueCurveValue((math.max(v380_, v381_))) * v380_ * 3.141592653589793 / 30
		if v378_ < v382_ then
			minRatio = v379_
			v378_ = v382_
		end
		if requiredMotorPower <= v382_ then
			break
		end
	end
	return minRatio
end

-- Local values: bestGearRatio, bestGearRatio
function VehicleMotor:getBestGear(acceleration, wheelSpeedRpm, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
	if (math.abs(acceleration) < 0.001 and (wheelSpeedRpm < 0 and -1 or 1) or acceleration) > 0 then
		if self.minForwardGearRatio == nil then
			return 1, self.forwardGears[1].ratio
		else
			return 1, self:getBestGearRatio(math.max(wheelSpeedRpm, 0), self.minForwardGearRatio, self.maxForwardGearRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
		end
	elseif self.minBackwardGearRatio == nil then
		if self.backwardGears == nil then
			return 1, self.forwardGears[1].ratio
		else
			return -1, -self.backwardGears[1].ratio
		end
	else
		local v389_ = -wheelSpeedRpm
		return -1, -self:getBestGearRatio(math.max(v389_, 0), self.minBackwardGearRatio, self.maxBackwardGearRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
	end
end

-- Local values: newGear, gearRatioMultiplier, minAllowedRpm, maxAllowedRpm, gearRatio, differentialRotSpeed, differentialRpm, clutchRpm, diffSpeedAfterChange, brakeAcc, lastMotorRotSpeed, lastDampedMotorRotSpeed, neededInertiaTorque, lastMotorTorque, totalMass, expectedAcc, uncalculatedAccFactor, gravityAcc, maxPower, maxPowerGear, gear, rpm, startInGearFactor, minRpmFactor, power, neededPowerPct, bestTradeoff, gear, validGear, nextRpm, startInGearFactor, minRpmFactor, neededPowerPctGear, nextPower, powerFactor, curSpeedRpm, rpmFactor, gearChangeFactor, rpmPreferenceFactor, factor, tradeoff, minDiffGear, minDiff, gear, rpm, diff
function VehicleMotor:findGearChangeTargetGearPrediction(curGear, gears, gearSign, gearChangeTimer, acceleratorPedal, dt)
	local v396_ = self:getGearRatioMultiplier()
	local v397_ = self.minRpm
	local v398_ = self.maxRpm
	local v399_ = gears[curGear].ratio * v396_
	local v400_ = math.abs(v399_)
	local v401_ = self.differentialRotSpeed * gearSign
	local v402_ = math.max(v401_, 0.0001)
	local v403_ = v402_ * 30 / 3.141592653589793
	local v404_ = v403_ * v400_
	local v405_
	if math.abs(acceleratorPedal) < 0.0001 then
		local v406_ = self.differentialRotAccelerationSmoothed * gearSign * 0.8
		local v407_ = v402_ + math.min(v406_, 0) * self.gearChangeTime * 0.001
		v405_ = math.max(v407_, 0)
	else
		local v408_ = (self.motorRotSpeed - self.motorRotAcceleration * (g_physicsDtLastValidNonInterpolated * 0.001)) / (1 + self.dampingRateFullThrottle / self.rotInertia * g_physicsDtLastValidNonInterpolated * 0.001)
		local v409_ = (self.motorRotSpeed - v408_) / (g_physicsDtLastValidNonInterpolated * 0.001) * self.rotInertia
		local v410_ = self.motorAppliedTorque - self.motorExternalTorque - v409_
		local v411_ = self.vehicle:getTotalMass()
		local v412_ = v410_ * v400_ / v411_ * 0.9
		local v413_ = self.differentialRotAccelerationSmoothed * gearSign
		local v414_ = v412_ - math.max(v413_, 0)
		local v415_ = v402_ - math.max(v414_, 0) * self.gearChangeTime * 0.001
		v405_ = math.max(v415_, 0)
	end
	local v416_ = curGear
	local v417_ = 0
	local v418_ = 0
	for v419_ = 1, #gears do
		local v420_
		if v419_ == curGear then
			v420_ = v404_
		else
			local v421_ = gears[v419_].ratio * v396_
			v420_ = v405_ * math.abs(v421_) * 30 / 3.141592653589793
		end
		local v422_ = self:getStartInGearFactor(gears[v419_].ratio * v396_) < self.startGearThreshold and 0 or 1
		if v420_ <= v398_ and v397_ * v422_ <= v420_ or v419_ == curGear then
			local v423_ = self:getTorqueCurveValue(v420_) * v420_
			if v417_ <= v423_ then
				v418_ = v419_
				v417_ = v423_
			end
		end
	end
	if v418_ ~= 0 then
		local v424_ = 0
		for v425_ = #gears, 1, -1 do
			local v426_ = false
			local v427_
			if v425_ == curGear then
				v427_ = v404_
			else
				local v428_ = gears[v425_].ratio * v396_
				v427_ = v405_ * math.abs(v428_) * 30 / 3.141592653589793
			end
			local v429_ = self:getStartInGearFactor(gears[v425_].ratio * v396_)
			local v430_, v431_
			if v429_ < self.startGearThreshold then
				v430_ = 0
				v431_ = 0
			else
				v430_ = 1
				v431_ = 0.5
			end
			if v427_ <= v398_ and v397_ * v430_ <= v427_ or v425_ == curGear then
				local v432_ = self:getTorqueCurveValue(v427_) * v427_
				if v417_ * v431_ <= v432_ or v425_ == curGear then
					local v433_ = (v432_ - v417_ * v431_) / (v417_ * (1 - v431_))
					local v434_ = gears[v425_].ratio * v396_
					local v435_ = v398_ - v403_ * math.abs(v434_)
					local v436_ = v398_ - v397_
					local v437_ = v435_ / math.max(v436_, 0.001)
					local v438_ = math.clamp(v437_, 0, 2)
					if v438_ > 1 then
						v438_ = 1 - (v438_ - 1) * 4
					end
					local v439_
					if v425_ == curGear then
						v439_ = 1
					else
						local v440_ = -gearChangeTimer / 2000
						v439_ = math.min(v440_, 0.9)
					end
					local v441_
					if v425_ < curGear then
						local v442_ = (v427_ - v404_) / 250
						v441_ = math.clamp(v442_, -1, 0)
					else
						v441_ = 0
					end
					local v443_ = v425_ < self.bestGearSelected and self:getStartInGearFactor(v400_) < self.startGearThreshold and -4 or v439_
					local v444_ = v438_ * 3.141592653589793
					local v445_ = math.sin(v444_) * 5
					local v446_ = v441_ - (1 - math.min(v445_, 2)) * 0.7
					if v425_ == curGear and v446_ > 0 then
						v446_ = v446_ * 1.5
					end
					local v447_
					if math.abs(acceleratorPedal) < 0.0001 then
						v447_ = 1 - v438_
					else
						v447_ = v438_ * 2
					end
					if math.abs(acceleratorPedal) < 0.0001 and (v404_ - v430_) / (v398_ - v430_) > 0.25 then
						if v425_ < curGear then
							v433_ = 0
							v447_ = 0
						elseif v425_ == curGear then
							v433_ = 1
							v447_ = 1
						end
					end
					if curGear < v425_ and v429_ < self.startGearThreshold then
						v433_ = 1
						v446_ = 1
					end
					local v448_ = v433_ + v447_ + v443_ + v446_
					if v424_ <= v448_ then
						v416_ = v425_
						v424_ = v448_
					end
					if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
						gears[v425_].lastTradeoff = v448_
						gears[v425_].lastDiffSpeedAfterChange = v425_ == curGear and v405_ and v405_ or nil
						gears[v425_].lastPowerFactor = v433_
						gears[v425_].lastRpmFactor = v447_
						gears[v425_].lastGearChangeFactor = v443_
						gears[v425_].lastRpmPreferenceFactor = v446_
						gears[v425_].lastNextPower = v432_
						gears[v425_].nextPowerValid = true
						gears[v425_].lastNextRpm = v427_
						gears[v425_].nextRpmValid = true
						gears[v425_].lastMaxPower = v417_
						gears[v425_].lastHasPower = true
						v426_ = true
					else
						v426_ = true
					end
				elseif VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
					gears[v425_].lastNextPower = v432_
				end
			end
			if not v426_ and VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
				gears[v425_].lastTradeoff = 0
				gears[v425_].lastPowerFactor = 0
				gears[v425_].lastRpmFactor = 0
				gears[v425_].lastGearChangeFactor = 0
				gears[v425_].lastRpmPreferenceFactor = 0
				gears[v425_].lastDiffSpeedAfterChange = v425_ == curGear and v405_ and v405_ or nil
				gears[v425_].lastNextRpm = v427_
				local v449_ = gears[v425_]
				local v450_
				if v427_ <= v398_ then
					v450_ = v397_ * v430_ <= v427_
				else
					v450_ = false
				end
				v449_.nextRpmValid = v450_
				gears[v425_].nextPowerValid = false
				gears[v425_].lastMaxPower = v417_
				gears[v425_].lastHasPower = false
			end
		end
		return v416_
	end
	local v451_ = math.huge
	local v452_ = 0
	for v453_ = 1, #gears do
		local v454_ = gears[v453_].ratio * v396_
		local v455_ = v405_ * math.abs(v454_) * 30 / 3.141592653589793
		local v456_ = v455_ - v398_
		local v457_ = v397_ - v455_
		local v458_ = math.max(v456_, v457_)
		if v458_ < v451_ then
			v452_ = v453_
			v451_ = v458_
		end
	end
	return v452_
end

-- Local values: gearRatioMultiplier, directionMultiplier
function VehicleMotor:applyTargetGear()
	local v460_ = self:getGearRatioMultiplier()
	self.gear = self.targetGear
	if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
		if self.currentGears[self.gear] == nil then
			self.minGearRatio = 0
			self.maxGearRatio = 0
		else
			self.minGearRatio = self.currentGears[self.gear].ratio * v460_
			self.maxGearRatio = self.minGearRatio
		end
	end
	self.gearChangeTime = self.gearChangeTimeOrig
	local v461_ = self.directionChangeUseGear and (self.currentDirection or 1) or 1
	SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * v461_, self.targetGear * v461_, 0, self.previousGear)
end

-- Local values: adjAcceleratorPedal, gearSign, newGear, forceGearChange, skipGearChangeTimer, directionChanged, trySelectBestGear, allowGearOverwritting, bestGear, maxFactorGroup, nextRatio, _, maxFactorGroup, directionMultiplier, curRatio, tarRatio, differentialRotSpeed, ratio, factor, motorRpm
function VehicleMotor:updateGear(acceleratorPedal, brakePedal, dt)
	self.lastAcceleratorPedal = acceleratorPedal
	if self.gearChangeTimer >= 0 then
		self.gearChangeTimer = self.gearChangeTimer - dt
		if self.gearChangeTimer < 0 and self.targetGear ~= 0 then
			self.allowGearChangeTimer = 3000
			local v466_ = self.targetGear - self.previousGear
			self.allowGearChangeDirection = math.sign(v466_)
			self:applyTargetGear()
			acceleratorPedal = 0
		else
			acceleratorPedal = 0
		end
	elseif self.groupChangeTimer > 0 or self.directionChangeTimer > 0 then
		self.groupChangeTimer = self.groupChangeTimer - dt
		self.directionChangeTimer = self.directionChangeTimer - dt
		if self.groupChangeTimer < 0 and self.directionChangeTimer < 0 then
			self:applyTargetGear()
		end
	else
		local v467_ = 0
		if acceleratorPedal > 0 then
			if self.minForwardGearRatio == nil then
				v467_ = 1
			else
				self.minGearRatio = self.minForwardGearRatio
				self.maxGearRatio = self.maxForwardGearRatio
			end
		elseif acceleratorPedal < 0 then
			if self.minBackwardGearRatio == nil then
				v467_ = -1
			else
				self.minGearRatio = -self.minBackwardGearRatio
				self.maxGearRatio = -self.maxBackwardGearRatio
			end
		elseif self.maxGearRatio > 0 then
			v467_ = self.minForwardGearRatio == nil and 1 or v467_
		else
			v467_ = self.maxGearRatio < 0 and self.minBackwardGearRatio == nil and -1 or v467_
		end
		local v468_ = self.gear
		local v469_ = false
		local v470_ = false
		local v471_
		if (self.backwardGears or self.forwardGears) and self:getUseAutomaticGearShifting() then
			self.autoGearChangeTimer = self.autoGearChangeTimer - dt
			if self.vehicle:getIsAutomaticShiftingAllowed() or acceleratorPedal ~= 0 then
				local v472_ = self.vehicle.lastSpeed
				local v473_
				if math.abs(v472_) < 0.0003 then
					local v474_ = false
					local v475_ = false
					local v476_ = false
					if v467_ < 0 and (self.currentDirection == 1 or self.gear == 0) then
						self:changeDirection(-1, true)
						v470_ = self.directionChangeTime > 0
						v474_ = true
					elseif v467_ > 0 and (self.currentDirection == -1 or self.gear == 0) then
						self:changeDirection(1, true)
						v470_ = self.directionChangeTime > 0
						v474_ = true
					elseif self.lastAcceleratorPedal == 0 and self.idleGearChangeTimer <= 0 then
						self.doSecondBestGearSelection = 3
						v475_ = true
					elseif self.doSecondBestGearSelection > 0 and self.lastAcceleratorPedal ~= 0 then
						self.doSecondBestGearSelection = self.doSecondBestGearSelection - 1
						if self.doSecondBestGearSelection == 0 then
							v475_ = true
							v476_ = true
						end
					end
					if v474_ then
						if self.targetGear ~= self.gear then
							v468_ = self.targetGear
						end
						v475_ = true
					end
					if v475_ then
						local v477_
						v471_, v477_ = self:getBestStartGear(self.currentGears)
						if v471_ == self.gear and v471_ == self.bestGearSelected then
							v471_ = v468_
						elseif v471_ > 1 or v476_ then
							self.bestGearSelected = v471_
							self.allowGearChangeTimer = 0
						end
						if self:getUseAutomaticGroupShifting() and (v477_ ~= nil and v477_ ~= self.activeGearGroupIndex) then
							self:setGearGroup(v477_)
							v473_ = acceleratorPedal
						else
							v473_ = acceleratorPedal
						end
					else
						v471_ = v468_
						v473_ = acceleratorPedal
					end
				elseif self.gear == 0 then
					v471_ = v468_
					v473_ = acceleratorPedal
				else
					if self.autoGearChangeTimer <= 0 then
						local v478_ = math.sign(acceleratorPedal)
						local v479_ = self.currentDirection
						v473_ = v478_ ~= math.sign(v479_) and 0 or acceleratorPedal
						v468_ = self:findGearChangeTargetGearPrediction(self.gear, self.currentGears, self.currentDirection, self.autoGearChangeTimer, v473_, dt)
						if self:getUseAutomaticGroupShifting() and self.gearGroups ~= nil then
							if self.activeGearGroupIndex < #self.gearGroups then
								local v480_ = self:getLastRealMotorRpm()
								local v481_ = self.maxRpm
								local v482_ = math.min(v480_, v481_) - self.maxRpm
								if math.abs(v482_) < 50 then
									if self.gear == #self.currentGears then
										local v483_ = self.gearGroups[self.activeGearGroupIndex + 1].ratio
										local v484_ = self.gearGroups[self.activeGearGroupIndex].ratio
										if math.sign(v484_) == math.sign(v483_) then
											self:shiftGroup(true)
											v468_ = self:findGearChangeTargetGearPrediction(self.targetGear, self.currentGears, self.currentDirection, self.autoGearChangeTimer, v473_, dt)
											v469_ = true
										end
									elseif self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
										local v485_ = self.gearGroups[self.activeGearGroupIndex].ratio
										local v486_ = math.sign(v485_)
										local v487_ = self.gearGroups[self.activeGearGroupIndex + 1].ratio
										if v486_ == math.sign(v487_) then
											self.gearGroupUpShiftTimer = self.gearGroupUpShiftTimer + dt
											if self.gearGroupUpShiftTimer > self.gearGroupUpShiftTime then
												self.gearGroupUpShiftTimer = 0
												self:shiftGroup(true)
											end
										else
											self.gearGroupUpShiftTimer = 0
										end
									end
								else
									self.gearGroupUpShiftTimer = 0
								end
							else
								self.gearGroupUpShiftTimer = 0
							end
							if self.gear == 1 and self.lastRealMotorRpm < self.minRpm + (self.maxRpm - self.minRpm) * 0.25 then
								local _, v488_ = self:getBestStartGear(self.currentGears)
								if v488_ < self.activeGearGroupIndex then
									local v489_ = self.gearGroups[v488_].ratio
									local v490_ = math.sign(v489_)
									local v491_ = self.gearGroups[self.activeGearGroupIndex].ratio
									if v490_ == math.sign(v491_) then
										self:setGearGroup(v488_)
									end
								end
							end
						end
					else
						v473_ = acceleratorPedal
					end
					local v492_ = math.max(v468_, 1)
					local v493_ = #self.currentGears
					v471_ = math.min(v492_, v493_)
				end
				self.allowGearChangeTimer = self.allowGearChangeTimer - dt
				if self.allowGearChangeTimer > 0 and (v473_ * self.currentDirection > 0 and v471_ < self.gear) then
					local v494_ = self.allowGearChangeDirection
					local v495_ = v471_ - self.gear
					if v494_ ~= math.sign(v495_) then
						v471_ = self.gear
					end
				end
			else
				v471_ = v468_
			end
		else
			v471_ = v468_
		end
		if v471_ ~= self.gear or v469_ then
			if v471_ ~= self.bestGearSelected then
				self.bestGearSelected = -1
			end
			self.targetGear = v471_
			self.previousGear = self.gear
			self.gear = 0
			self.minGearRatio = 0
			self.maxGearRatio = 0
			if not v470_ then
				self.autoGearChangeTimer = self.autoGearChangeTime
				self.gearChangeTimer = self.gearChangeTime
			end
			self.lastGearChangeTime = g_time
			acceleratorPedal = 0
			local v496_ = self.directionChangeUseGear and (self.currentDirection or 1) or 1
			SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * v496_, self.targetGear * v496_, self.gearChangeTimer, self.previousGear)
			if self.gearChangeTimer == 0 then
				self.gearChangeTimer = -1
				self.allowGearChangeTimer = 3000
				local v497_ = self.targetGear - self.previousGear
				self.allowGearChangeDirection = math.sign(v497_)
				self:applyTargetGear()
			end
		end
	end
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (self.backwardGears or self.forwardGears) then
		local v498_, v499_
		if self.currentGears[self.gear] == nil then
			v498_ = nil
			v499_ = nil
		else
			v498_ = self.currentGears[self.gear].ratio * self:getGearRatioMultiplier()
			local v500_ = self.differentialRotSpeed
			local v501_ = math.abs(v500_)
			local v502_ = math.max(v501_, 0.0001)
			local v503_ = self.motorRotSpeed / v502_
			v499_ = math.min(v503_, 5000)
		end
		local v504_
		if v498_ == nil then
			v504_ = 0
		else
			local v505_ = MathUtil.lerp
			local v506_ = math.abs(v498_)
			local v507_ = math.abs(v499_)
			local v508_ = self.manualClutchValue
			v504_ = v505_(v506_, v507_, math.min(v508_, 0.9) / 0.9 * 0.5) * math.sign(v498_)
		end
		self.minGearRatio = v504_
		self.maxGearRatio = v504_
		if self.manualClutchValue == 0 and self.maxGearRatio ~= 0 then
			local v509_ = self:getNonClampedMotorRpm()
			if (v509_ <= 0 and 1 or (self:getClutchRpm() + 50) / v509_) < 0.2 then
				self.stallTimer = self.stallTimer + dt
				if self.stallTimer > 500 then
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
	if self:getUseAutomaticGearShifting() then
		local v510_ = self.vehicle.lastSpeed
		if math.abs(v510_) > 0.0003 and (self.backwardGears or self.forwardGears) then
			if self.currentDirection > 0 and acceleratorPedal < 0 then
				acceleratorPedal = 0
				brakePedal = 1
			elseif self.currentDirection < 0 and acceleratorPedal > 0 then
				acceleratorPedal = 0
				brakePedal = 1
			end
		end
	end
	return acceleratorPedal, brakePedal
end

-- Local values: newGear
function VehicleMotor:shiftGear(up)
	if not self.gearChangedIsLocked then
		if self:getIsGearChangeAllowed() then
			local v513_
			if up then
				v513_ = self.targetGear + 1 * self.currentDirection
			else
				v513_ = self.targetGear - 1 * self.currentDirection
			end
			local v514_
			if self.currentDirection > 0 or self.backwardGears == nil then
				v514_ = #self.forwardGears < v513_ and #self.forwardGears or v513_
			else
				v514_ = (self.currentDirection < 0 or self.backwardGears ~= nil) and #self.backwardGears < v513_ and #self.backwardGears or v513_
			end
			if v514_ ~= self.targetGear then
				if self.currentDirection > 0 then
					if v514_ < 0 then
						self:changeDirection(-1)
						v514_ = 1
					end
				elseif v514_ < 0 then
					self:changeDirection(1)
					v514_ = 1
				end
				self:setGear(v514_)
				self.lastManualShifterActive = false
				return
			end
		else
			SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", true, false)
		end
	end
end

function VehicleMotor:selectGear(gearIndex, activation)
	if activation then
		if self.gear ~= gearIndex then
			if not self:getIsGearChangeAllowed() then
				SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", false, false, gearIndex)
				return
			end
			if self.currentGears[gearIndex] ~= nil then
				self:setGear(gearIndex, true)
				self.lastManualShifterActive = true
				return
			end
		end
	else
		self:setGear(0, false)
		self.lastManualShifterActive = true
	end
end

-- Local values: directionMultiplier
function VehicleMotor:setGear(gearIndex, isLocked)
	if gearIndex ~= self.targetGear then
		if self.gearChangeTime == 0 and gearIndex < self.targetGear then
			self.loadPercentageChangeCharge = 1
		end
		if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
			self.targetGear = gearIndex
			self.previousGear = self.gear
			self.gear = gearIndex
		else
			self.targetGear = gearIndex
			self.previousGear = self.gear
			self.gear = 0
			self.minGearRatio = 0
			self.maxGearRatio = 0
			self.autoGearChangeTimer = self.autoGearChangeTime
			self.gearChangeTimer = self.gearChangeTime
		end
		self.lastGearChangeTime = g_time
		local v520_ = self.directionChangeUseGear and (self.currentDirection or 1) or 1
		SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * v520_, self.targetGear * v520_, self.gearChangeTime, self.previousGear)
	end
end

-- Local values: newGearGroupIndex
function VehicleMotor:shiftGroup(up)
	if not self.gearGroupChangedIsLocked then
		if self:getIsGearGroupChangeAllowed() then
			if self.gearGroups ~= nil then
				local v523_
				if up then
					v523_ = self.activeGearGroupIndex + 1
				else
					v523_ = self.activeGearGroupIndex - 1
				end
				local v524_ = self.numGearGroups
				self:setGearGroup((math.clamp(v523_, 1, v524_)))
				return
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
				return
			end
		elseif self.activeGearGroupIndex ~= groupIndex then
			SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", false, true, nil, groupIndex)
			return
		end
	else
		self:setGearGroup(0, false)
	end
end

-- Local values: lastActiveGearGroupIndex, group
function VehicleMotor:setGearGroup(groupIndex, isLocked)
	local v531_ = self.activeGearGroupIndex
	self.activeGearGroupIndex = groupIndex
	self.gearGroupChangedIsLocked = isLocked
	if self.activeGearGroupIndex ~= v531_ then
		if self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT and v531_ < self.activeGearGroupIndex then
			self.loadPercentageChangeCharge = 1
		end
		if self.directionChangeUseGroup then
			if self.activeGearGroupIndex > 0 then
				local v532_ = self.gearGroups[self.activeGearGroupIndex].ratio
				self.currentDirection = math.sign(v532_)
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

-- Local values: targetDirection, changeAllowed, oldGearGroupIndex, directionMultiplier
function VehicleMotor:changeDirection(direction, force)
	if direction == nil then
		direction = -self.currentDirection
	end
	if self.backwardGears == nil and self.forwardGears == nil then
		self.currentDirection = direction
		SpecializationUtil.raiseEvent(self.vehicle, "onGearDirectionChanged", self.currentDirection)
	else
		local v536_ = ((not self.directionChangeUseGroup or self.gearGroupChangedIsLocked) and true or false) and ((not self.directionChangeUseGear or self.gearChangedIsLocked) and not self.directionChangeUseGear and true or false)
		if v536_ then
			v536_ = not self.directionChangeUseGroup
		end
		if v536_ and (direction ~= self.currentDirection or force) then
			self.currentDirection = direction
			if self.directionChangeTime > 0 then
				self.directionChangeTimer = self.directionChangeTime
				self.gear = 0
				self.minGearRatio = 0
				self.maxGearRatio = 0
			end
			local v537_ = self.activeGearGroupIndex
			if self.currentDirection < 0 then
				if self.directionChangeUseGear then
					self.directionLastGear = self.targetGear
					if not (self:getUseAutomaticGearShifting() and self.lastManualShifterActive) then
						self.targetGear = self.directionChangeGearIndex
					end
					self.currentGears = self.backwardGears or self.forwardGears
				elseif self.directionChangeUseGroup then
					self.directionLastGroup = self.activeGearGroupIndex
					self.activeGearGroupIndex = self.directionChangeGroupIndex
				end
			elseif self.directionChangeUseGear then
				if not (self:getUseAutomaticGearShifting() and self.lastManualShifterActive) then
					if self.directionLastGear > 0 then
						self.targetGear = not self:getUseAutomaticGearShifting() and self.directionLastGear or self.defaultForwardGear
					else
						self.targetGear = self.defaultForwardGear
					end
				end
				self.currentGears = self.forwardGears
			elseif self.directionChangeUseGroup then
				if self.directionLastGroup > 0 then
					self.activeGearGroupIndex = self.directionLastGroup
				else
					self.activeGearGroupIndex = self.defaultGearGroup
				end
			end
			SpecializationUtil.raiseEvent(self.vehicle, "onGearDirectionChanged", self.currentDirection)
			local v538_ = self.directionChangeUseGear and (self.currentDirection or 1) or 1
			SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * v538_, self.targetGear * v538_, self.directionChangeTime, self.previousGear)
			if self.activeGearGroupIndex ~= v537_ then
				SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, self.directionChangeTime)
			end
			if self.directionChangeTime == 0 then
				self:applyTargetGear()
			end
		end
	end
end

function VehicleMotor:onManualClutchChanged(clutchValue)
	self.manualClutchValue = clutchValue
end

function VehicleMotor:getIsGearChangeAllowed()
	return (self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH or self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT) and true or self.manualClutchValue > 0.5
end

function VehicleMotor:getIsGearGroupChangeAllowed()
	if self.gearGroups == nil then
		return false
	else
		return (self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH or self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT) and true or self.manualClutchValue > 0.5
	end
end

function VehicleMotor:setTransmissionDirection(direction)
	if direction > 0 then
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

-- Local values: minRatio, maxRatio
function VehicleMotor:getMinMaxGearRatio()
	local v546_ = self.minGearRatio
	local v547_ = self.maxGearRatio
	if self.minGearRatio ~= 0 or self.maxGearRatio ~= 0 then
		if self.clutchSlippingTimer == self.clutchSlippingTime then
			local v548_ = self.maxGearRatio
			local v549_ = math.max(350, v548_)
			local v550_ = self.maxGearRatio
			return v546_, v549_ * math.sign(v550_)
		end
		if self.clutchSlippingTimer > 0 then
			v546_ = MathUtil.lerp(v546_, self.clutchSlippingGearRatio, self.clutchSlippingTimer / self.clutchSlippingTime)
			v547_ = MathUtil.lerp(v547_, self.clutchSlippingGearRatio, self.clutchSlippingTimer / self.clutchSlippingTime)
		end
	end
	return v546_, v547_
end

function VehicleMotor:getGearRatio()
	return self.gearRatio
end

-- Local values: multiplier, group
function VehicleMotor:getGearRatioMultiplier()
	local v553_ = self.directionChangeUseGroup and 1 or self.currentDirection
	if self.gearGroups ~= nil then
		if self.activeGearGroupIndex == 0 then
			return 0
		end
		local v554_ = self.gearGroups[self.activeGearGroupIndex]
		if v554_ ~= nil then
			return v554_.ratio * v553_
		end
	end
	return v553_
end

function VehicleMotor:getIsInNeutral()
	return (self.backwardGears or self.forwardGears) and (self.gear == 0 and self.targetGear == 0) and true or false
end

-- Local values: factor, motorRpm
function VehicleMotor:getCanMotorRun()
	if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (not self.vehicle:getIsMotorStarted() and (self.backwardGears or self.forwardGears)) and (self.manualClutchValue == 0 and self.maxGearRatio ~= 0) then
		local v557_ = self:getNonClampedMotorRpm()
		if (v557_ <= 0 and 1 or (self:getClutchRpm() + 50) / v557_) < 0.2 then
			return false, VehicleMotor.REASON_CLUTCH_NOT_ENGAGED
		end
	end
	return true
end

-- Local values: maxRpm, gearRatio, speedLimit
function VehicleMotor:getCurMaxRpm()
	local v559_ = self.maxRpm
	local v560_ = self:getGearRatio()
	if v560_ ~= 0 then
		local v561_ = self.speedLimit
		local v562_ = self.speedLimitAcc
		local v563_ = self.vehicle.lastSpeedReal * 3600
		local v564_ = math.max(v562_, v563_)
		local v565_ = math.min(v561_, v564_) * 0.277778
		local v566_
		if v560_ > 0 then
			local v567_ = self.maxForwardSpeed
			v566_ = math.min(v565_, v567_)
		else
			local v568_ = self.maxBackwardSpeed
			v566_ = math.min(v565_, v568_)
		end
		local v569_ = v566_ * 30 / 3.141592653589793 * math.abs(v560_)
		v559_ = math.min(v559_, v569_)
	end
	local v570_ = self.rpmLimit
	return math.min(v559_, v570_)
end

function VehicleMotor:setSpeedLimit(limit)
	local v573_ = self.minSpeed
	self.speedLimit = math.max(limit, v573_)
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
	return self.gearShiftMode == VehicleMotor.SHIFT_MODE_AUTOMATIC and true or not self.manualShiftGears
end

function VehicleMotor:getUseAutomaticGroupShifting()
	return self.gearShiftMode == VehicleMotor.SHIFT_MODE_AUTOMATIC and true or not self.manualShiftGroups
end
