-- Local values: mudTireCoeffs, mudTireCoeffsWet, mudTireCoeffsSnow, offRoadTireCoeffs, offRoadTireCoeffsWet, offRoadTireCoeffsSnow, streetTireCoeffs, streetTireCoeffsWet, streetTireCoeffsSnow, crawlerCoeffs, crawlerCoeffsWet, crawlerCoeffsSnow, chainsCoeffs, chainsCoeffsWet, chainsCoeffsSnow, metalCoeffs, metalCoeffsWet, metalCoeffsSnow, SMOOTHING_SPEED_SCALE
WheelsUtil = {}
WheelsUtil.GROUND_ROAD = 1
WheelsUtil.GROUND_HARD_TERRAIN = 2
WheelsUtil.GROUND_SOFT_TERRAIN = 3
WheelsUtil.GROUND_FIELD = 4
WheelsUtil.NUM_GROUNDS = 4
WheelsUtil.tireTypes = {}

-- Local values: getNoNilCoeffs, tireType
function WheelsUtil.registerTireType(name, frictionCoeffs, frictionCoeffsWet, frictionCoeffsSnow)
	local v5_ = string.upper(name)
	if WheelsUtil.getTireType(v5_) == nil then
		local function v10_(p6_)
			local v7_ = {}
			if p6_[1] == nil then
				v7_[1] = 1.15
				for v8_ = 2, WheelsUtil.NUM_GROUNDS do
					if p6_[v8_] ~= nil then
						v7_[1] = p6_[v8_]
						break
					end
				end
			else
				v7_[1] = p6_[1]
			end
			for v9_ = 2, WheelsUtil.NUM_GROUNDS do
				v7_[v9_] = p6_[v9_] or p6_[v9_ - 1]
			end
			return v7_
		end
		local v11_ = {
			["name"] = v5_,
			["frictionCoeffs"] = v10_(frictionCoeffs),
			["frictionCoeffsWet"] = v10_(frictionCoeffsWet or frictionCoeffs)
		}
		v11_.frictionCoeffsSnow = v10_(frictionCoeffsSnow or v11_.frictionCoeffsWet)
		local v12_ = WheelsUtil.tireTypes
		table.insert(v12_, v11_)
	else
		printWarning("Warning: Tire type \'" .. v5_ .. "\' already registered, ignoring this definition")
	end
end

-- Local values: i, tireType
function WheelsUtil.unregisterTireType(name)
	local v14_ = string.upper(name)
	for v15_, v16_ in ipairs(WheelsUtil.tireTypes) do
		if v16_.name == v14_ then
			table.remove(WheelsUtil.tireTypes, v15_)
			return
		end
	end
end

-- Local values: i, t
function WheelsUtil.getTireType(name)
	local v18_ = string.upper(name)
	for v19_, v20_ in pairs(WheelsUtil.tireTypes) do
		if v20_.name == v18_ then
			return v19_
		end
	end
	return nil
end

function WheelsUtil.getTireTypeName(index)
	return WheelsUtil.tireTypes[index] == nil and "unknown" or WheelsUtil.tireTypes[index].name
end
local v22_ = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.1,
	[WheelsUtil.GROUND_FIELD] = 0.95
}
local v23_ = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1,
	[WheelsUtil.GROUND_FIELD] = 0.7
}
local v24_ = {
	[WheelsUtil.GROUND_ROAD] = 0.45,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 0.45,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.4,
	[WheelsUtil.GROUND_FIELD] = 0.35
}
WheelsUtil.registerTireType("mud", v22_, v23_, v24_)
local v25_ = {
	[WheelsUtil.GROUND_ROAD] = 1.2,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_FIELD] = 1
}
local v26_ = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.95,
	[WheelsUtil.GROUND_FIELD] = 0.6
}
local v27_ = {
	[WheelsUtil.GROUND_ROAD] = 0.45,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 0.4,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.35,
	[WheelsUtil.GROUND_FIELD] = 0.3
}
WheelsUtil.registerTireType("offRoad", v25_, v26_, v27_)
local v28_ = {
	[WheelsUtil.GROUND_ROAD] = 1.25,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1,
	[WheelsUtil.GROUND_FIELD] = 0.9
}
local v29_ = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.85,
	[WheelsUtil.GROUND_FIELD] = 0.45
}
local v30_ = {
	[WheelsUtil.GROUND_ROAD] = 0.55,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 0.4,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.3,
	[WheelsUtil.GROUND_FIELD] = 0.35
}
WheelsUtil.registerTireType("street", v28_, v29_, v30_)
local v31_ = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
local v32_ = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_FIELD] = 0.85
}
local v33_ = {
	[WheelsUtil.GROUND_ROAD] = 0.65,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 0.65,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.65,
	[WheelsUtil.GROUND_FIELD] = 0.65
}
WheelsUtil.registerTireType("crawler", v31_, v32_, v33_)
local v34_ = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
local v35_ = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_FIELD] = 0.95
}
local v36_ = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_FIELD] = 1.05
}
WheelsUtil.registerTireType("chains", v34_, v35_, v36_)
local v37_ = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
local v38_ = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
local v39_ = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
WheelsUtil.registerTireType("metalSpikes", v37_, v38_, v39_)
local v_u_40_ = 0.002

-- Upvalues: SMOOTHING_SPEED_SCALE
-- Local values: appliedAcc, decSpeed, appliedBrake, decSpeed
function WheelsUtil:getSmoothedAcceleratorAndBrakePedals(acceleratorPedal, brakePedal, dt)
	-- upvalues: (copy) v_u_40_
	if self.wheelsUtilSmoothedAcceleratorPedal == nil then
		self.wheelsUtilSmoothedAcceleratorPedal = 0
	end
	local v45_ = 0
	if acceleratorPedal > 0 then
		if self.wheelsUtilSmoothedAcceleratorPedal < acceleratorPedal then
			local v46_ = self.wheelsUtilSmoothedAcceleratorPedal + 0.002 * dt
			local v47_ = math.max(v46_, 0.002)
			v45_ = math.min(v47_, acceleratorPedal)
		else
			v45_ = acceleratorPedal
		end
		self.wheelsUtilSmoothedAcceleratorPedal = v45_
	elseif acceleratorPedal < 0 then
		if acceleratorPedal < self.wheelsUtilSmoothedAcceleratorPedal then
			local v48_ = self.wheelsUtilSmoothedAcceleratorPedal - 0.002 * dt
			local v49_ = math.min(v48_, -0.002)
			v45_ = math.max(v49_, acceleratorPedal)
		else
			v45_ = acceleratorPedal
		end
		self.wheelsUtilSmoothedAcceleratorPedal = v45_
	else
		local v50_ = 0.0005 + 0.001 * brakePedal
		if self.wheelsUtilSmoothedAcceleratorPedal > 0 then
			local v51_ = self.wheelsUtilSmoothedAcceleratorPedal - v50_ * dt
			self.wheelsUtilSmoothedAcceleratorPedal = math.max(v51_, 0)
		else
			local v52_ = self.wheelsUtilSmoothedAcceleratorPedal + v50_ * dt
			self.wheelsUtilSmoothedAcceleratorPedal = math.min(v52_, 0)
		end
	end
	if self.wheelsUtilSmoothedBrakePedal == nil then
		self.wheelsUtilSmoothedBrakePedal = 0
	end
	local v53_ = 0
	if brakePedal > 0 then
		if self.wheelsUtilSmoothedBrakePedal < brakePedal then
			local v54_ = self.wheelsUtilSmoothedBrakePedal + 0.0025 * dt
			brakePedal = math.min(v54_, brakePedal)
		end
		self.wheelsUtilSmoothedBrakePedal = brakePedal
		return v45_, brakePedal
	end
	local v55_ = 0.0005 + 0.001 * acceleratorPedal
	local v56_ = self.wheelsUtilSmoothedBrakePedal - v55_ * dt
	self.wheelsUtilSmoothedBrakePedal = math.max(v56_, 0)
	return v45_, v53_
end

-- Local values: acceleratorPedal, brakePedal, reverserDirection, motor, isManualTransmission, useManualDirectionChange, absCurrentSpeed, accSign, automaticBrake, isSlow, isArticulatedSteering, factor, maxSpeed, overSpeedLimit, factor, absAcceleratorPedal, minGearRatio, maxGearRatio, acceleratorPedalControlsSpeed, maxAcceleration, maxMotorRotAcceleration, minMotorRpm, maxMotorRpm, neededPtoTorque, ptoTorqueVirtualMultiplicator, neutralActive
function WheelsUtil:updateWheelsPhysics(dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking)
	local v63_ = 0
	local v64_ = 0
	local v65_ = self.spec_drivable == nil and 1 or self.spec_drivable.reverserDirection
	local v66_ = self.spec_motorized.motor
	local v67_ = v66_.backwardGears ~= nil and true or v66_.forwardGears ~= nil
	local v68_ = self:getIsManualDirectionChangeActive()
	local v69_
	if v68_ then
		v69_ = acceleration * v66_.currentDirection
	else
		v69_ = acceleration * v65_
	end
	local v70_ = math.abs(currentSpeed)
	local v71_ = math.sign(v69_)
	self.nextMovingDirection = self.nextMovingDirection or 0
	self.nextMovingDirectionTimer = self.nextMovingDirectionTimer or 0
	local v72_ = false
	if math.abs(v69_) < 0.001 then
		v72_ = true
		if stopAndGoBraking or currentSpeed * self.nextMovingDirection < 0.0003 then
			self.nextMovingDirection = 0
		end
	else
		if self.nextMovingDirection * currentSpeed < -0.0014 then
			self.nextMovingDirection = 0
		end
		if v71_ == self.nextMovingDirection or currentSpeed * v71_ > -0.0003 and (stopAndGoBraking or self.nextMovingDirection == 0) then
			local v73_ = self.nextMovingDirectionTimer - dt
			self.nextMovingDirectionTimer = math.max(v73_, 0)
			if self.nextMovingDirectionTimer == 0 then
				self.nextMovingDirection = v71_
				v63_ = v69_
				v64_ = 0
			else
				v64_ = math.abs(v69_)
				v63_ = 0
			end
		else
			v63_ = 0
			v64_ = math.abs(v69_)
			if stopAndGoBraking then
				self.nextMovingDirectionTimer = 100
			end
		end
	end
	if v68_ and (v63_ ~= 0 and math.sign(v63_) ~= v66_.currentDirection) then
		v64_ = math.abs(v63_)
		v63_ = 0
	end
	local v74_, v75_ = v66_:updateGear(v72_ and 0 or v63_, v64_, dt)
	if v66_.gear == 0 and v66_.targetGear ~= 0 then
		local v76_ = v66_.targetGear
		v72_ = currentSpeed * math.sign(v76_) < 0 and v70_ < v66_.lowBrakeForceSpeedLimit and true or v72_
	end
	if v66_.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and v67_ then
		v72_ = false
	end
	if v71_ ~= 0 and v66_.lowBrakeForceLocked then
		v66_.lowBrakeForceLocked = false
	end
	if v72_ then
		local v77_ = v70_ < v66_.lowBrakeForceSpeedLimit
		local v78_
		if self.spec_articulatedAxis == nil or self.spec_articulatedAxis.componentJoint == nil then
			v78_ = false
		else
			local v79_ = self.rotatedTime
			v78_ = math.abs(v79_) > 0.01
		end
		if (v77_ or doHandbrake) and not v78_ or v66_.lowBrakeForceLocked then
			v75_ = 1
			if not v66_.lowBrakeForceLocked and v71_ == 0 then
				v66_.lowBrakeForceLocked = true
			end
		else
			local v80_ = v70_ / 0.001
			local v81_ = math.min(v80_, 1)
			v75_ = MathUtil.lerp(1, v66_.lowBrakeForceScale, v81_)
		end
	end
	SpecializationUtil.raiseEvent(self, "onVehiclePhysicsUpdate", v74_, v75_, v72_, currentSpeed)
	local v82_, v83_ = WheelsUtil.getSmoothedAcceleratorAndBrakePedals(self, v74_, v75_, dt)
	local v84_ = v66_:getMaximumForwardSpeed() * 3.6
	if self.movingDirection < 0 then
		v84_ = v66_:getMaximumBackwardSpeed() * 3.6
	end
	local v85_ = self:getLastSpeed()
	local v86_ = v66_:getSpeedLimit()
	local v87_ = v85_ - math.min(v86_, v84_)
	local v88_
	if v87_ > 0 then
		if v87_ > 0.3 then
			local v89_ = v66_.overSpeedTimer + dt
			v66_.overSpeedTimer = math.min(v89_, 2000)
		else
			local v90_ = v66_.overSpeedTimer - dt
			v66_.overSpeedTimer = math.max(v90_, 0)
		end
		local v91_ = v87_ * (0.5 + v66_.overSpeedTimer / 2000 * 1)
		local v92_ = math.pow(v91_, 2)
		local v93_ = math.min(v92_, 1)
		v83_ = math.max(v93_, v83_)
		local v94_ = 1 - v87_ / 0.2
		v88_ = 0.2 * math.max(v94_, 0) * v82_
	else
		local v95_ = math.abs(v87_) / 0.3 + 0.2
		v88_ = v82_ * math.min(v95_, 1)
		v66_.overSpeedTimer = 0
	end
	if next(self.spec_motorized.differentials) ~= nil and self.spec_motorized.motorizedNode ~= nil then
		local v96_ = math.abs(v88_)
		local v97_, v98_ = v66_:getMinMaxGearRatio()
		local v99_
		if v98_ >= 0 then
			v99_ = v66_:getMaximumForwardSpeed()
		else
			v99_ = v66_:getMaximumBackwardSpeed()
		end
		local v100_ = v66_:getSpeedLimit() / 3.6
		local v101_ = math.min(v99_, v100_)
		local v102_ = v66_:getAccelerationLimit()
		local v103_ = v66_:getMotorRotationAccelerationLimit()
		local v104_, v105_ = v66_:getRequiredMotorRpmRange()
		local v106_, v107_ = PowerConsumer.getTotalConsumedPtoTorque(self)
		local v108_ = v106_ / v66_:getPtoMotorRpmRatio()
		local v109_ = v97_ == 0 and v98_ == 0 and true or v66_:getManualClutchPedal() > 0.9
		v66_:setExternalTorqueVirtualMultiplicator(v107_)
		if v109_ then
			self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
			v83_ = math.max(v83_, 0.03)
		else
			self:controlVehicle(v96_, v101_, v102_, v104_ * 3.141592653589793 / 30, v105_ * 3.141592653589793 / 30, v103_, v97_, v98_, v66_:getMaxClutchTorque(), v108_)
		end
	end
	self:brake(v83_)
end

-- Local values: wheelSpeed, numWheels, _, wheel, axleSpeed
function WheelsUtil:computeDifferentialRotSpeedNonMotor()
	if not self.isServer or (self.spec_wheels == nil or #self.spec_wheels.wheels == 0) then
		return self.lastSpeedReal * 1000
	end
	local v111_ = 0
	local v112_ = 0
	for _, v113_ in pairs(self.spec_wheels.wheels) do
		local v114_ = getWheelShapeAxleSpeed(v113_.node, v113_.physics.wheelShape)
		if v113_.physics.hasGroundContact then
			v111_ = v111_ + v114_ * v113_.physics.radius
			v112_ = v112_ + 1
		end
	end
	return v112_ <= 0 and 0 or v111_ / v112_
end

-- Local values: coeff, coeffWet, coeffSnow
function WheelsUtil.getTireFriction(tireType, groundType, wetScale, snowScale)
	local v119_ = wetScale == nil and 0 or wetScale
	local v120_ = WheelsUtil.tireTypes[tireType].frictionCoeffs[groundType]
	local v121_ = WheelsUtil.tireTypes[tireType].frictionCoeffsWet[groundType]
	local v122_ = WheelsUtil.tireTypes[tireType].frictionCoeffsSnow[groundType]
	return v120_ + (v121_ - v120_) * v119_ + (v122_ - v120_) * snowScale
end

function WheelsUtil.getGroundType(isField, isRoad, depth)
	if isField then
		return WheelsUtil.GROUND_FIELD
	elseif isRoad or depth < 0.1 then
		return WheelsUtil.GROUND_ROAD
	elseif depth > 0.8 then
		return WheelsUtil.GROUND_SOFT_TERRAIN
	else
		return WheelsUtil.GROUND_HARD_TERRAIN
	end
end
