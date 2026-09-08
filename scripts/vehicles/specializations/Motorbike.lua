Motorbike = {}

function Motorbike.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Motorized, specializations)
	end
	return v2_
end
function Motorbike.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Motorbike")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.motorbike.tilt#node", "Tilt Node")
	v3_:register(XMLValueType.ANGLE, "vehicle.motorbike.tilt#maxTilt", "Max. tilt in corners", 0)
	v3_:register(XMLValueType.ANGLE, "vehicle.motorbike.tilt#idleTilt", "Tilt while not driving", 0)
	v3_:register(XMLValueType.ANGLE, "vehicle.motorbike.tilt#backwardTilt", "Tilt while going backward", 0)
	v3_:register(XMLValueType.ANGLE, "vehicle.motorbike.tilt#tiltSpeed", "Tilt speed (deg/sec)", 5)
	v3_:register(XMLValueType.STRING, "vehicle.motorbike.footAnimation#name", "Name of the foot animation")
	v3_:register(XMLValueType.FLOAT, "vehicle.motorbike.footAnimation#speed", "Play speed of the animation", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.motorbike.footAnimation#speedThreshold", "Speed threshold to play the animation", 1)
	v3_:register(XMLValueType.STRING, "vehicle.motorbike.backwardAnimation#name", "Name of the backward walk animation")
	v3_:register(XMLValueType.FLOAT, "vehicle.motorbike.backwardAnimation#speed", "Speed of the animation", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.motorbike.steering#highSpeedScale", "Scale value for max. steering angle when above speed threshold", 0.5)
	v3_:register(XMLValueType.FLOAT, "vehicle.motorbike.steering#highSpeedThreshold", "Threshold at which the steering is reduced to the defined scale", 20)
	v3_:setXMLSpecializationType()
end

function Motorbike.registerFunctions(vehicleType) end

function Motorbike.registerOverwrittenFunctions(vehicleType) end

function Motorbike.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Motorbike)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Motorbike)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Motorbike)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Motorbike)
end

-- Local values: spec
function Motorbike:onLoad(savegame)
	local v6_ = self.spec_motorbike
	v6_.tilt = {}
	v6_.tilt.node = self.xmlFile:getValue("vehicle.motorbike.tilt#node", nil, self.components, self.i3dMappings)
	v6_.tilt.maxTilt = self.xmlFile:getValue("vehicle.motorbike.tilt#maxTilt", 0)
	v6_.tilt.idleTilt = self.xmlFile:getValue("vehicle.motorbike.tilt#idleTilt", 0)
	v6_.tilt.backwardTilt = self.xmlFile:getValue("vehicle.motorbike.tilt#backwardTilt", 0)
	v6_.tilt.tiltSpeed = self.xmlFile:getValue("vehicle.motorbike.tilt#tiltSpeed", 5) * 0.001
	v6_.tilt.currentValue = v6_.tilt.idleTilt
	setRotation(v6_.tilt.node, 0, 0, v6_.tilt.currentValue)
	v6_.footAnimation = {}
	v6_.footAnimation.name = self.xmlFile:getValue("vehicle.motorbike.footAnimation#name")
	v6_.footAnimation.speed = self.xmlFile:getValue("vehicle.motorbike.footAnimation#speed", 1)
	v6_.footAnimation.speedThreshold = self.xmlFile:getValue("vehicle.motorbike.footAnimation#speedThreshold", 1)
	v6_.footAnimation.state = false
	v6_.backwardAnimation = {}
	v6_.backwardAnimation.name = self.xmlFile:getValue("vehicle.motorbike.backwardAnimation#name")
	v6_.backwardAnimation.speed = self.xmlFile:getValue("vehicle.motorbike.backwardAnimation#speed", 1)
	v6_.backwardAnimation.state = false
	v6_.backwardAnimation.maxBackwardSpeed = self:getMotor():getMaximumBackwardSpeed()
	v6_.steering = {}
	v6_.steering.highSpeedScale = self.xmlFile:getValue("vehicle.motorbike.steering#highSpeedScale", 0.5)
	v6_.steering.highSpeedThreshold = self.xmlFile:getValue("vehicle.motorbike.steering#highSpeedThreshold", 20)
end

-- Local values: spec
function Motorbike:onPostLoad(savegame)
	local v8_ = self.spec_motorbike
	v8_.steering.minRotTime = self.minRotTime
	v8_.steering.maxRotTime = self.maxRotTime
	v8_.steering.wheelSteeringDuration = self.wheelSteeringDuration
end

-- Local values: spec, lastSpeed, targetTilt, direction, limit, currentValue, footAnimationState, animationTime, backwardAnimationState, steeringAngleScale
function Motorbike:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v11_ = self.spec_motorbike
	local v12_ = self:getLastSpeed()
	local v13_
	if self.movingDirection < 0 then
		v13_ = v11_.tilt.backwardTilt
	elseif v12_ < 0.5 then
		v13_ = v11_.tilt.idleTilt
	else
		local v14_ = v12_ / 50
		v13_ = -math.min(v14_, 1) * self.rotatedTime * v11_.tilt.maxTilt
	end
	local v15_ = v13_ - v11_.tilt.currentValue
	local v16_ = math.sign(v15_)
	local v17_ = (v16_ > 0 and math.min or math.max)(v11_.tilt.currentValue + v16_ * v11_.tilt.tiltSpeed * dt, v13_)
	if v17_ ~= v11_.tilt.currentValue then
		v11_.tilt.currentValue = v17_
		setRotation(v11_.tilt.node, 0, 0, v11_.tilt.currentValue)
	end
	local v18_ = v12_ < v11_.footAnimation.speedThreshold and true or self.movingDirection < 0
	if v18_ ~= v11_.footAnimation.state then
		v11_.footAnimation.state = v18_
		local v19_ = self:getAnimationTime(v11_.footAnimation.name)
		if v18_ then
			self:playAnimation(v11_.footAnimation.name, -v11_.footAnimation.speed, v19_, true)
		else
			self:playAnimation(v11_.footAnimation.name, v11_.footAnimation.speed, v19_, true)
		end
	end
	local v20_
	if self.movingDirection < 0 then
		v20_ = v12_ > 0.5
	else
		v20_ = false
	end
	if v20_ ~= v11_.backwardAnimation.state then
		v11_.backwardAnimation.state = v20_
		if v20_ then
			self:playAnimation(v11_.backwardAnimation.name, v11_.backwardAnimation.speed, self:getAnimationTime(v11_.backwardAnimation.name), true)
		else
			self:stopAnimation(v11_.backwardAnimation.name)
			self:setAnimationTime(v11_.backwardAnimation.name, 0, true)
		end
	end
	if v11_.backwardAnimation.state then
		self:setAnimationSpeed(v11_.backwardAnimation.name, v11_.backwardAnimation.speed * (v12_ / v11_.backwardAnimation.maxBackwardSpeed))
	end
	local v21_ = v11_.steering.highSpeedScale
	local v22_ = v12_ / v11_.steering.highSpeedThreshold
	local v23_ = v21_ + (1 - math.min(v22_, 1)) * (1 - v11_.steering.highSpeedScale)
	self.minRotTime = v11_.steering.minRotTime * v23_
	self.maxRotTime = v11_.steering.maxRotTime * v23_
	self.wheelSteeringDuration = v11_.steering.wheelSteeringDuration * v23_
end

-- Local values: _, dirY, _, positionX, positionY, positionZ, dirX, _, dirZ, yRot
function Motorbike:onLeaveVehicle()
	if self.isServer then
		local _, v25_, _ = localDirectionToWorld(self.rootNode, 0, 1, 0)
		if v25_ < 0.5 then
			local v26_, v27_, v28_ = getWorldTranslation(self.rootNode)
			local v29_, _, v30_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
			local v31_, v32_ = MathUtil.vector2Normalize(v29_, v30_)
			local v33_ = MathUtil.getYRotationFromDirection(v31_, v32_)
			self:removeFromPhysics()
			self:setAbsolutePosition(v26_, v27_, v28_, 0, v33_, 0)
			self:addToPhysics()
		end
	end
end
