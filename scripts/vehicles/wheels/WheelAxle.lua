-- Local values: WheelAxle_mt
WheelAxle = {}
local WheelAxle_mt = Class(WheelAxle)

-- Upvalues: WheelAxle_mt
-- Local values: self
function WheelAxle.new(vehicle, customMt)
	-- upvalues: (copy) WheelAxle_mt
	local v4_ = customMt or WheelAxle_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	return v5_
end

function WheelAxle:delete() end

-- Local values: springLoadMultiplier, dampingLoadMultiplier
function WheelAxle:loadFromXML(xmlFile, key)
	self.wheelNode1 = xmlFile:getValue(key .. "#wheel1", nil, self.vehicle.components, self.vehicle.i3dMappings)
	self.wheelNode2 = xmlFile:getValue(key .. "#wheel2", nil, self.vehicle.components, self.vehicle.i3dMappings)
	if self.wheelNode1 == nil or self.wheelNode2 == nil then
		Logging.xmlError(xmlFile, "WheelAxle \'%s\' missing wheel1 or wheel2", key)
		return false
	end
	self.wheel1 = self.vehicle:getWheelByWheelNode(self.wheelNode1)
	self.wheel2 = self.vehicle:getWheelByWheelNode(self.wheelNode2)
	if self.wheel1 == nil or self.wheel2 == nil then
		return false
	end
	local v9_ = xmlFile:getValue(key .. ".dynamicSuspension#springLoadMultiplier", 1)
	local v10_ = xmlFile:getValue(key .. ".dynamicSuspension#dampingLoadMultiplier", 1)
	if v9_ ~= 1 or v10_ ~= 1 then
		self.dynamicSuspension = {}
		self.dynamicSuspension.springLoadMultiplier = v9_
		self.dynamicSuspension.dampingLoadMultiplier = v10_
		self.dynamicSuspension.maxLoad = xmlFile:getValue(key .. ".dynamicSuspension#maxLoad")
		self.dynamicSuspension.interpolationTime = 1 / xmlFile:getValue(key .. ".dynamicSuspension#interpolationTime", 1)
		self.dynamicSuspension.interpolatedAlpha = 0
		self.dynamicSuspension.appliedAlpha = 0
		if self.vehicle.setDependentComponentJointBaseFactors ~= nil then
			self.dynamicSuspension.componentJointIndex = xmlFile:getValue(key .. ".dynamicSuspension.componentJoint#index", nil)
			if self.dynamicSuspension.componentJointIndex ~= nil then
				self.dynamicSuspension.componentSpringLoadMultiplier = xmlFile:getValue(key .. ".dynamicSuspension.componentJoint#springLoadMultiplier", 1)
				self.dynamicSuspension.componentDampingLoadMultiplier = xmlFile:getValue(key .. ".dynamicSuspension.componentJoint#dampingLoadMultiplier", 1)
			end
		end
	end
	return true
end

-- Local values: dynamicSuspension, physics1, physics2, axleLoad, restLoad, maxLoad, targetAlpha, direction, springMultiplier, dampingMultiplier, componentSpringLoadMultiplier, componentDampingLoadMultiplier
function WheelAxle:update(dt)
	if self.dynamicSuspension ~= nil then
		local v13_ = self.dynamicSuspension
		local v14_ = self.wheel1.physics
		local v15_ = self.wheel2.physics
		local v16_ = v14_:getTireLoad() + v15_:getTireLoad()
		if v16_ ~= 0 then
			local v17_ = v14_.restLoad + v15_.restLoad
			local v18_ = self.maxLoad or v14_.restLoad * 2 + v15_.restLoad * 2
			local v19_ = MathUtil.inverseLerp(v17_, v18_, v16_) - v13_.interpolatedAlpha
			local v20_ = math.sign(v19_)
			local v21_ = v13_.interpolatedAlpha + v20_ * dt * v13_.interpolationTime
			v13_.interpolatedAlpha = math.clamp(v21_, 0, 1)
			local v22_ = v13_.interpolatedAlpha - v13_.appliedAlpha
			if math.abs(v22_) > 0.05 then
				v13_.appliedAlpha = v13_.interpolatedAlpha
				local v23_ = MathUtil.lerp(1, v13_.springLoadMultiplier, v13_.appliedAlpha)
				local v24_ = MathUtil.lerp(1, v13_.dampingLoadMultiplier, v13_.appliedAlpha)
				v14_:setSuspensionMultipliers(v23_, v24_)
				v15_:setSuspensionMultipliers(v23_, v24_)
				if self.dynamicSuspension.componentJointIndex ~= nil then
					local v25_ = MathUtil.lerp(1, v13_.componentSpringLoadMultiplier, v13_.appliedAlpha)
					local v26_ = MathUtil.lerp(1, v13_.componentDampingLoadMultiplier, v13_.appliedAlpha)
					self.vehicle:setDependentComponentJointBaseFactors(v13_.componentJointIndex, v25_, v26_, true)
					self.vehicle:updateDependentComponentJointValues(false, true)
				end
			end
		end
	end
end
function WheelAxle.getDebugValueHeader()
	return {
		"w1\n",
		"w2\n",
		"load\n",
		"maxLoad\n",
		"alpha\n",
		"spring\n",
		"damp\n",
		"compJ\n",
		"jSpring\n",
		"jDamp\n"
	}
end

-- Local values: dynamicSuspension, physics1, physics2, maxLoad, springMultiplier, dampingMultiplier, componentSpringMultiplier, componentDampingMultiplier
function WheelAxle:fillDebugValues(debugTable)
	local v29_ = self.dynamicSuspension
	local v30_ = self.wheel1.physics
	local v31_ = self.wheel2.physics
	if v29_ ~= nil then
		debugTable[1] = debugTable[1] .. string.format("%d\n", self.wheel1.wheelIndex)
		debugTable[2] = debugTable[2] .. string.format("%d\n", self.wheel2.wheelIndex)
		debugTable[3] = debugTable[3] .. string.format("%2.2f\n", v30_:getTireLoad() + v31_:getTireLoad())
		local v32_ = v29_.maxLoad or v30_.restLoad * 2 + v31_.restLoad * 2
		debugTable[4] = debugTable[4] .. string.format("%2.2f\n", v32_)
		debugTable[5] = debugTable[5] .. string.format("%.2f\n", v29_.appliedAlpha)
		local v33_ = MathUtil.lerp(1, v29_.springLoadMultiplier, v29_.appliedAlpha)
		local v34_ = MathUtil.lerp(1, v29_.dampingLoadMultiplier, v29_.appliedAlpha)
		debugTable[6] = debugTable[6] .. string.format("x%.2f\n", v33_)
		debugTable[7] = debugTable[7] .. string.format("x%.2f\n", v34_)
		if self.dynamicSuspension.componentJointIndex ~= nil then
			debugTable[8] = debugTable[8] .. string.format("%d\n", self.dynamicSuspension.componentJointIndex)
			local v35_ = MathUtil.lerp(1, v29_.componentSpringLoadMultiplier, v29_.appliedAlpha)
			local v36_ = MathUtil.lerp(1, v29_.componentDampingLoadMultiplier, v29_.appliedAlpha)
			debugTable[9] = debugTable[9] .. string.format("x%.2f\n", v35_)
			debugTable[10] = debugTable[10] .. string.format("x%.2f\n", v36_)
			return
		end
		debugTable[8] = debugTable[8] .. "n/a\n"
		debugTable[9] = debugTable[9] .. "n/a\n"
		debugTable[10] = debugTable[10] .. "n/a\n"
	end
end

function WheelAxle.registerXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#wheel1", "First wheel of the axle")
	schema:register(XMLValueType.NODE_INDEX, key .. "#wheel2", "Second wheel of the axle")
	schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension#springLoadMultiplier", "Multiplier for spring value while maxLoad is applied on the wheels", 1)
	schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension#dampingLoadMultiplier", "Multiplier for damping value while maxLoad is applied on the wheels", 1)
	schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension#maxLoad", "Axle load as reference for springLoadMultiplier/dampingLoadMultiplier to adjust the physics behaviour in high load situations", "restLoad of all wheels multiplied by 2")
	schema:register(XMLValueType.TIME, key .. ".dynamicSuspension#interpolationTime", "Interpolation time for tire load", 1)
	schema:register(XMLValueType.INT, key .. ".dynamicSuspension.componentJoint#index", "Index of the axle component joint")
	schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension.componentJoint#springLoadMultiplier", "Multiplier for component joint spring value while maxLoad is applied on the wheels", 1)
	schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension.componentJoint#dampingLoadMultiplier", "Multiplier for component joint damping value while maxLoad is applied on the wheels", 1)
end
