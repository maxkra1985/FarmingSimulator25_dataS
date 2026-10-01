WheelsUtil = {}
WheelsUtil.GROUND_ROAD = 1
WheelsUtil.GROUND_HARD_TERRAIN = 2
WheelsUtil.GROUND_SOFT_TERRAIN = 3
WheelsUtil.GROUND_FIELD = 4
WheelsUtil.NUM_GROUNDS = 4
WheelsUtil.tireTypes = {}
function WheelsUtil.registerTireType(name, frictionCoeffs, frictionCoeffsWet, frictionCoeffsSnow)
	name = string.upper(name)
	if WheelsUtil.getTireType(name) ~= nil then
		printWarning("Warning: Tire type '" .. name .. "' already registered, ignoring this definition")
	else
		local getNoNilCoeffs = function(frictionCoeffs)
			local localCoeffs = {}
			if frictionCoeffs[1] == nil then
				localCoeffs[1] = 1.15
				for i = 2, WheelsUtil.NUM_GROUNDS do
					if frictionCoeffs[i] ~= nil then
						localCoeffs[1] = frictionCoeffs[i]
						break
					end
				end
			else
				localCoeffs[1] = frictionCoeffs[1]
			end
			for i = 2, WheelsUtil.NUM_GROUNDS do
				localCoeffs[i] = frictionCoeffs[i] or frictionCoeffs[i - 1]
			end
			return localCoeffs
		end
		local tireType = {}
		tireType.name = name
		tireType.frictionCoeffs = getNoNilCoeffs(frictionCoeffs)
		tireType.frictionCoeffsWet = getNoNilCoeffs(frictionCoeffsWet or frictionCoeffs)
		tireType.frictionCoeffsSnow = getNoNilCoeffs(frictionCoeffsSnow or tireType.frictionCoeffsWet)
		table.insert(WheelsUtil.tireTypes, tireType)
	end
end
function WheelsUtil.unregisterTireType(name)
	name = string.upper(name)
	for i, tireType in ipairs(WheelsUtil.tireTypes) do
		if tireType.name == name then
			table.remove(WheelsUtil.tireTypes, i)
			return
		end
	end
end
function WheelsUtil.getTireType(name)
	name = string.upper(name)
	for i, t in pairs(WheelsUtil.tireTypes) do
		if t.name == name then
			return i
		end
	end
	return nil
end
function WheelsUtil.getTireTypeName(index)
	if WheelsUtil.tireTypes[index] ~= nil then
		return WheelsUtil.tireTypes[index].name
	else
		return "unknown"
	end
end
local mudTireCoeffs = {}
mudTireCoeffs[WheelsUtil.GROUND_ROAD] = 1.15
mudTireCoeffs[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15
mudTireCoeffs[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.1
mudTireCoeffs[WheelsUtil.GROUND_FIELD] = 0.95
local mudTireCoeffsWet = {}
mudTireCoeffsWet[WheelsUtil.GROUND_ROAD] = 1.05
mudTireCoeffsWet[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05
mudTireCoeffsWet[WheelsUtil.GROUND_SOFT_TERRAIN] = 1
mudTireCoeffsWet[WheelsUtil.GROUND_FIELD] = 0.7
local mudTireCoeffsSnow = {}
mudTireCoeffsSnow[WheelsUtil.GROUND_ROAD] = 0.45
mudTireCoeffsSnow[WheelsUtil.GROUND_HARD_TERRAIN] = 0.45
mudTireCoeffsSnow[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.4
mudTireCoeffsSnow[WheelsUtil.GROUND_FIELD] = 0.35
WheelsUtil.registerTireType("mud", mudTireCoeffs, mudTireCoeffsWet, mudTireCoeffsSnow)
local offRoadTireCoeffs = {}
offRoadTireCoeffs[WheelsUtil.GROUND_ROAD] = 1.2
offRoadTireCoeffs[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15
offRoadTireCoeffs[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05
offRoadTireCoeffs[WheelsUtil.GROUND_FIELD] = 1
local offRoadTireCoeffsWet = {}
offRoadTireCoeffsWet[WheelsUtil.GROUND_ROAD] = 1.05
offRoadTireCoeffsWet[WheelsUtil.GROUND_HARD_TERRAIN] = 1
offRoadTireCoeffsWet[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.95
offRoadTireCoeffsWet[WheelsUtil.GROUND_FIELD] = 0.6
local offRoadTireCoeffsSnow = {}
offRoadTireCoeffsSnow[WheelsUtil.GROUND_ROAD] = 0.45
offRoadTireCoeffsSnow[WheelsUtil.GROUND_HARD_TERRAIN] = 0.4
offRoadTireCoeffsSnow[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.35
offRoadTireCoeffsSnow[WheelsUtil.GROUND_FIELD] = 0.3
WheelsUtil.registerTireType("offRoad", offRoadTireCoeffs, offRoadTireCoeffsWet, offRoadTireCoeffsSnow)
local streetTireCoeffs = {}
streetTireCoeffs[WheelsUtil.GROUND_ROAD] = 1.25
streetTireCoeffs[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15
streetTireCoeffs[WheelsUtil.GROUND_SOFT_TERRAIN] = 1
streetTireCoeffs[WheelsUtil.GROUND_FIELD] = 0.9
local streetTireCoeffsWet = {}
streetTireCoeffsWet[WheelsUtil.GROUND_ROAD] = 1.15
streetTireCoeffsWet[WheelsUtil.GROUND_HARD_TERRAIN] = 1
streetTireCoeffsWet[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.85
streetTireCoeffsWet[WheelsUtil.GROUND_FIELD] = 0.45
local streetTireCoeffsSnow = {}
streetTireCoeffsSnow[WheelsUtil.GROUND_ROAD] = 0.55
streetTireCoeffsSnow[WheelsUtil.GROUND_HARD_TERRAIN] = 0.4
streetTireCoeffsSnow[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.3
streetTireCoeffsSnow[WheelsUtil.GROUND_FIELD] = 0.35
WheelsUtil.registerTireType("street", streetTireCoeffs, streetTireCoeffsWet, streetTireCoeffsSnow)
local crawlerCoeffs = {}
crawlerCoeffs[WheelsUtil.GROUND_ROAD] = 1.15
crawlerCoeffs[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15
crawlerCoeffs[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15
crawlerCoeffs[WheelsUtil.GROUND_FIELD] = 1.15
local crawlerCoeffsWet = {}
crawlerCoeffsWet[WheelsUtil.GROUND_ROAD] = 1.05
crawlerCoeffsWet[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05
crawlerCoeffsWet[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05
crawlerCoeffsWet[WheelsUtil.GROUND_FIELD] = 0.85
local crawlerCoeffsSnow = {}
crawlerCoeffsSnow[WheelsUtil.GROUND_ROAD] = 0.65
crawlerCoeffsSnow[WheelsUtil.GROUND_HARD_TERRAIN] = 0.65
crawlerCoeffsSnow[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.65
crawlerCoeffsSnow[WheelsUtil.GROUND_FIELD] = 0.65
WheelsUtil.registerTireType("crawler", crawlerCoeffs, crawlerCoeffsWet, crawlerCoeffsSnow)
local chainsCoeffs = {}
chainsCoeffs[WheelsUtil.GROUND_ROAD] = 1.15
chainsCoeffs[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15
chainsCoeffs[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15
chainsCoeffs[WheelsUtil.GROUND_FIELD] = 1.15
local chainsCoeffsWet = {}
chainsCoeffsWet[WheelsUtil.GROUND_ROAD] = 1.05
chainsCoeffsWet[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05
chainsCoeffsWet[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05
chainsCoeffsWet[WheelsUtil.GROUND_FIELD] = 0.95
local chainsCoeffsSnow = {}
chainsCoeffsSnow[WheelsUtil.GROUND_ROAD] = 1.05
chainsCoeffsSnow[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05
chainsCoeffsSnow[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05
chainsCoeffsSnow[WheelsUtil.GROUND_FIELD] = 1.05
WheelsUtil.registerTireType("chains", chainsCoeffs, chainsCoeffsWet, chainsCoeffsSnow)
local metalCoeffs = {}
metalCoeffs[WheelsUtil.GROUND_ROAD] = 1.15
metalCoeffs[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15
metalCoeffs[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15
metalCoeffs[WheelsUtil.GROUND_FIELD] = 1.15
local metalCoeffsWet = {}
metalCoeffsWet[WheelsUtil.GROUND_ROAD] = 1.15
metalCoeffsWet[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15
metalCoeffsWet[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15
metalCoeffsWet[WheelsUtil.GROUND_FIELD] = 1.15
local metalCoeffsSnow = {}
metalCoeffsSnow[WheelsUtil.GROUND_ROAD] = 1.15
metalCoeffsSnow[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15
metalCoeffsSnow[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15
metalCoeffsSnow[WheelsUtil.GROUND_FIELD] = 1.15
WheelsUtil.registerTireType("metalSpikes", metalCoeffs, metalCoeffsWet, metalCoeffsSnow)
local SMOOTHING_SPEED_SCALE = 0.002
function WheelsUtil:getSmoothedAcceleratorAndBrakePedals(acceleratorPedal, brakePedal, dt)
	if self.wheelsUtilSmoothedAcceleratorPedal == nil then
		self.wheelsUtilSmoothedAcceleratorPedal = 0
	end
	local appliedAcc = 0
	if 0 < acceleratorPedal then
		if self.wheelsUtilSmoothedAcceleratorPedal < acceleratorPedal then
			appliedAcc = math.min(math.max(self.wheelsUtilSmoothedAcceleratorPedal + 0.002 * dt, 0.002), acceleratorPedal)
		else
			appliedAcc = acceleratorPedal
		end
		self.wheelsUtilSmoothedAcceleratorPedal = appliedAcc
	elseif acceleratorPedal < 0 then
		if acceleratorPedal < self.wheelsUtilSmoothedAcceleratorPedal then
			appliedAcc = math.max(math.min(self.wheelsUtilSmoothedAcceleratorPedal - 0.002 * dt, -0.002), acceleratorPedal)
		else
			appliedAcc = acceleratorPedal
		end
		self.wheelsUtilSmoothedAcceleratorPedal = appliedAcc
	else
		local decSpeed = 0.0005 + 0.001 * brakePedal
		if 0 < self.wheelsUtilSmoothedAcceleratorPedal then
			self.wheelsUtilSmoothedAcceleratorPedal = math.max(self.wheelsUtilSmoothedAcceleratorPedal - decSpeed * dt, 0)
		else
			self.wheelsUtilSmoothedAcceleratorPedal = math.min(self.wheelsUtilSmoothedAcceleratorPedal + decSpeed * dt, 0)
		end
	end
	if self.wheelsUtilSmoothedBrakePedal == nil then
		self.wheelsUtilSmoothedBrakePedal = 0
	end
	local appliedBrake = 0
	if 0 < brakePedal then
		if self.wheelsUtilSmoothedBrakePedal < brakePedal then
			appliedBrake = math.min(self.wheelsUtilSmoothedBrakePedal + 0.0025 * dt, brakePedal)
		else
			appliedBrake = brakePedal
		end
		self.wheelsUtilSmoothedBrakePedal = appliedBrake
		return appliedAcc, appliedBrake
	else
		local decSpeed = 0.0005 + 0.001 * acceleratorPedal
		self.wheelsUtilSmoothedBrakePedal = math.max(self.wheelsUtilSmoothedBrakePedal - decSpeed * dt, 0)
		return appliedAcc, appliedBrake
	end
end
function WheelsUtil:updateWheelsPhysics(dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking)
	local acceleratorPedal = 0
	local brakePedal = 0
	local reverserDirection = 1
	if self.spec_drivable ~= nil then
		reverserDirection = self.spec_drivable.reverserDirection
	end
	local motor = self.spec_motorized.motor
	local isManualTransmission = motor.backwardGears ~= nil or motor.forwardGears ~= nil
	local useManualDirectionChange = self:getIsManualDirectionChangeActive()
	if useManualDirectionChange then
		acceleration = acceleration * motor.currentDirection
	else
		acceleration = acceleration * reverserDirection
	end
	local absCurrentSpeed = math.abs(currentSpeed)
	local accSign = math.sign(acceleration)
	self.nextMovingDirection = self.nextMovingDirection or 0
	self.nextMovingDirectionTimer = self.nextMovingDirectionTimer or 0
	local automaticBrake = false
	if math.abs(acceleration) < 0.001 then
		automaticBrake = true
		if stopAndGoBraking or currentSpeed * self.nextMovingDirection < 0.0003 then
			self.nextMovingDirection = 0
		end
	else
		if self.nextMovingDirection * currentSpeed < -0.0014 then
			self.nextMovingDirection = 0
		end
		if accSign ~= self.nextMovingDirection and (-0.0003 < currentSpeed * accSign and not stopAndGoBraking) then
			if self.nextMovingDirection == 0 then
				self.nextMovingDirectionTimer = math.max(self.nextMovingDirectionTimer - dt, 0)
				if self.nextMovingDirectionTimer == 0 then
					acceleratorPedal = acceleration
					brakePedal = 0
					self.nextMovingDirection = accSign
				else
					acceleratorPedal = 0
					brakePedal = math.abs(acceleration)
				end
			else
				acceleratorPedal = 0
				brakePedal = math.abs(acceleration)
				if stopAndGoBraking then
					self.nextMovingDirectionTimer = 100
				end
			end
		end
	end
	if useManualDirectionChange and (acceleratorPedal ~= 0 and math.sign(acceleratorPedal) ~= motor.currentDirection) then
		brakePedal = math.abs(acceleratorPedal)
		acceleratorPedal = 0
	end
	if automaticBrake then
		acceleratorPedal = 0
	end
	acceleratorPedal, brakePedal = motor:updateGear(acceleratorPedal, brakePedal, dt)
	if motor.gear == 0 and (motor.targetGear ~= 0 and (currentSpeed * math.sign(motor.targetGear) < 0 and absCurrentSpeed < motor.lowBrakeForceSpeedLimit)) then
		automaticBrake = true
	end
	if motor.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and isManualTransmission then
		automaticBrake = false
	end
	if accSign ~= 0 and motor.lowBrakeForceLocked then
		motor.lowBrakeForceLocked = false
	end
	if automaticBrake then
		local isSlow = absCurrentSpeed < motor.lowBrakeForceSpeedLimit
		local _v141 = math.abs(self.rotatedTime)
		local isArticulatedSteering = self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.componentJoint ~= nil and 0.01 < _v141
		if not isSlow and (doHandbrake and isArticulatedSteering) then
			brakePedal = 1
			local factor = math.min(absCurrentSpeed / 0.001, 1)
			brakePedal = MathUtil.lerp(1, motor.lowBrakeForceScale, factor)
			factor = motor.lowBrakeForceLocked and motor.lowBrakeForceLocked or _v141
			if _v141 then
				brakePedal = 1
				if accSign == 0 then
					motor.lowBrakeForceLocked = true
				end
			else
				local factor = math.min(absCurrentSpeed / 0.001, 1)
				brakePedal = MathUtil.lerp(1, motor.lowBrakeForceScale, factor)
			end
		end
	end
	SpecializationUtil.raiseEvent(self, "onVehiclePhysicsUpdate", acceleratorPedal, brakePedal, automaticBrake, currentSpeed)
	acceleratorPedal, brakePedal = WheelsUtil.getSmoothedAcceleratorAndBrakePedals(self, acceleratorPedal, brakePedal, dt)
	local maxSpeed = motor:getMaximumForwardSpeed() * 3.6
	if self.movingDirection < 0 then
		maxSpeed = motor:getMaximumBackwardSpeed() * 3.6
	end
	local overSpeedLimit = self:getLastSpeed() - math.min(motor:getSpeedLimit(), maxSpeed)
	if 0 < overSpeedLimit then
		if 0.3 < overSpeedLimit then
			motor.overSpeedTimer = math.min(motor.overSpeedTimer + dt, 2000)
		else
			motor.overSpeedTimer = math.max(motor.overSpeedTimer - dt, 0)
		end
		local factor = 0.5 + motor.overSpeedTimer / 2000 * 1
		brakePedal = math.max(math.min(math.pow(overSpeedLimit * factor, 2), 1), brakePedal)
		acceleratorPedal = 0.2 * math.max(1 - overSpeedLimit / 0.2, 0) * acceleratorPedal
	else
		acceleratorPedal = acceleratorPedal * math.min(math.abs(overSpeedLimit) / 0.3 + 0.2, 1)
		motor.overSpeedTimer = 0
	end
	if next(self.spec_motorized.differentials) ~= nil and self.spec_motorized.motorizedNode ~= nil then
		local absAcceleratorPedal = math.abs(acceleratorPedal)
		local minGearRatio, maxGearRatio = motor:getMinMaxGearRatio()
		if 0 <= maxGearRatio then
			maxSpeed = motor:getMaximumForwardSpeed()
		else
			maxSpeed = motor:getMaximumBackwardSpeed()
		end
		local acceleratorPedalControlsSpeed = false
		maxSpeed = math.min(maxSpeed, motor:getSpeedLimit() / 3.6)
		local maxAcceleration = motor:getAccelerationLimit()
		local maxMotorRotAcceleration = motor:getMotorRotationAccelerationLimit()
		local minMotorRpm, maxMotorRpm = motor:getRequiredMotorRpmRange()
		local neededPtoTorque, ptoTorqueVirtualMultiplicator = PowerConsumer.getTotalConsumedPtoTorque(self)
		neededPtoTorque = neededPtoTorque / motor:getPtoMotorRpmRatio()
		if minGearRatio == 0 then
			local neutralActive = maxGearRatio == 0 or 0.9 < motor:getManualClutchPedal()
			local _v110 = true
		end
		local _v17 = motor:getManualClutchPedal()
		local _v193 = 0.9
		motor:setExternalTorqueVirtualMultiplicator(ptoTorqueVirtualMultiplicator)
		if not neutralActive then
			self:controlVehicle(absAcceleratorPedal, maxSpeed, maxAcceleration, minMotorRpm * 3.141592653589793 / 30, maxMotorRpm * 3.141592653589793 / 30, maxMotorRotAcceleration, minGearRatio, maxGearRatio, motor:getMaxClutchTorque(), neededPtoTorque)
		else
			self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
			brakePedal = math.max(brakePedal, 0.03)
		end
	end
	self:brake(brakePedal)
end
function WheelsUtil:computeDifferentialRotSpeedNonMotor()
	if self.isServer and (self.spec_wheels ~= nil and #self.spec_wheels.wheels ~= 0) then
		local wheelSpeed = 0
		local numWheels = 0
		for _, wheel in pairs(self.spec_wheels.wheels) do
			local axleSpeed = getWheelShapeAxleSpeed(wheel.node, wheel.physics.wheelShape)
			if wheel.physics.hasGroundContact then
				wheelSpeed = wheelSpeed + axleSpeed * wheel.physics.radius
				numWheels = numWheels + 1
			end
		end
		if 0 < numWheels then
			return wheelSpeed / numWheels
		else
			return 0
		end
	end
	return self.lastSpeedReal * 1000
end
function WheelsUtil.getTireFriction(tireType, groundType, wetScale, snowScale)
	if wetScale == nil then
		wetScale = 0
	end
	local coeff = WheelsUtil.tireTypes[tireType].frictionCoeffs[groundType]
	local coeffWet = WheelsUtil.tireTypes[tireType].frictionCoeffsWet[groundType]
	local coeffSnow = WheelsUtil.tireTypes[tireType].frictionCoeffsSnow[groundType]
	return coeff + (coeffWet - coeff) * wetScale + (coeffSnow - coeff) * snowScale
end
function WheelsUtil.getGroundType(isField, isRoad, depth)
	if isField then
		return WheelsUtil.GROUND_FIELD
	end
	if isRoad or depth < 0.1 then
		return WheelsUtil.GROUND_ROAD
	end
	if 0.8 < depth then
		return WheelsUtil.GROUND_SOFT_TERRAIN
	else
		return WheelsUtil.GROUND_HARD_TERRAIN
	end
end
