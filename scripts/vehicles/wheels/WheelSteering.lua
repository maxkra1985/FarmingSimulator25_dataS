WheelSteering = {}

-- Local values: self
function WheelSteering.new(wheel)
	local v2_ = {
		["__index"] = WheelSteering
	}
	local v3_ = setmetatable({}, v2_)
	v3_.wheel = wheel
	v3_.vehicle = wheel.vehicle
	v3_.steeringNodeMaxRot = 1
	v3_.steeringNodeMinRot = -1
	return v3_
end

-- Local values: i, fenderKey, xmlFile, _, entry
function WheelSteering:loadFromXML(xmlObject)
	self.steeringNode = xmlObject:getValue(".steering#node", nil, self.vehicle.components, self.vehicle.i3dMappings)
	self.steeringRotNode = xmlObject:getValue(".steering#rotNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
	self.steeringNodeMinTransX = xmlObject:getValue(".steering#nodeMinTransX")
	self.steeringNodeMaxTransX = xmlObject:getValue(".steering#nodeMaxTransX")
	self.steeringNodeMinRotY = xmlObject:getValue(".steering#nodeMinRotY")
	self.steeringNodeMaxRotY = xmlObject:getValue(".steering#nodeMaxRotY")
	self.fenders = {}
	local v6_ = 0
	while true do
		local v7_ = string.format(".fender(%d)", v6_)
		local v8_, _ = xmlObject:getXMLFileAndPropertyKey(v7_)
		if v8_ == nil then
			break
		end
		local v9_ = {
			["node"] = xmlObject:getValue(v7_ .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)
		}
		if v9_.node ~= nil then
			v9_.rotMax = xmlObject:getValue(v7_ .. "#rotMax")
			v9_.rotMin = xmlObject:getValue(v7_ .. "#rotMin")
			local v10_ = self.fenders
			table.insert(v10_, v9_)
		end
		v6_ = v6_ + 1
	end
	self.steeringAxleScale = xmlObject:getValue(".steeringAxle#scale", 0)
	self.steeringAxleRotMax = xmlObject:getValue(".steeringAxle#rotMax", 0)
	self.steeringAxleRotMin = xmlObject:getValue(".steeringAxle#rotMin", -0)
	return true
end

-- Local values: i, fender
function WheelSteering:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
	if self.steeringAxleScale ~= 0 then
		if inverted then
			self.steeringAxleScale = -self.steeringAxleScale
		end
		self.steeringAxleRotMax = rotMax
		self.steeringAxleRotMin = rotMin
	end
	for v15_ = 1, #self.fenders do
		local v16_ = self.fenders[v15_]
		v16_.rotMax = v16_.rotMax or rotMax
		v16_.rotMin = v16_.rotMin or rotMin
	end
	local v17_ = self.steeringAxleRotMax
	self.steeringNodeMaxRot = math.max(rotMax, v17_)
	local v18_ = self.steeringAxleRotMin
	self.steeringNodeMinRot = math.min(rotMin, v18_)
end

-- Local values: refAngle, refTrans, refRot, steeringValue, _, sny, snz, snx, rotX, _, rotZ, rotY, i, fender, angleDif
function WheelSteering:update(x, y, z, xDrive, suspensionLength, steeringAngle, changed)
	if self.steeringNode ~= nil then
		local v21_ = self.steeringNodeMaxRot
		local v22_ = self.steeringNodeMaxTransX
		local v23_ = self.steeringNodeMaxRotY
		if steeringAngle < 0 then
			v21_ = self.steeringNodeMinRot
			v22_ = self.steeringNodeMinTransX
			v23_ = self.steeringNodeMinRotY
		end
		local v24_ = v21_ == 0 and 0 or steeringAngle / v21_
		if self.steeringNodeMinTransX ~= nil then
			local _, v25_, v26_ = getTranslation(self.steeringNode)
			local v27_ = v22_ * v24_
			setTranslation(self.steeringNode, v27_, v25_, v26_)
		end
		if self.steeringNodeMinRotY ~= nil then
			local v28_, _, v29_ = getRotation(self.steeringRotNode or self.steeringNode)
			local v30_ = v23_ * v24_
			setRotation(self.steeringRotNode or self.steeringNode, v28_, v30_, v29_)
		end
	end
	for v31_ = 1, #self.fenders do
		local v32_ = self.fenders[v31_]
		local v33_ = 0
		if v32_.rotMax < steeringAngle then
			v33_ = v32_.rotMax - steeringAngle
		elseif steeringAngle < v32_.rotMin then
			v33_ = v32_.rotMin - steeringAngle
		end
		setRotation(v32_.node, 0, v33_, 0)
	end
end

function WheelSteering.registerXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. ".steering#node", "Steering node")
	schema:register(XMLValueType.NODE_INDEX, key .. ".steering#rotNode", "Steering rot node")
	schema:register(XMLValueType.FLOAT, key .. ".steering#nodeMinTransX", "Min. X translation")
	schema:register(XMLValueType.FLOAT, key .. ".steering#nodeMaxTransX", "Max. X translation")
	schema:register(XMLValueType.ANGLE, key .. ".steering#nodeMinRotY", "Min. Y rotation")
	schema:register(XMLValueType.ANGLE, key .. ".steering#nodeMaxRotY", "Max. Y rotation")
	schema:register(XMLValueType.NODE_INDEX, key .. ".fender(?)#node", "Fender node")
	schema:register(XMLValueType.ANGLE, key .. ".fender(?)#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, key .. ".fender(?)#rotMin", "Min. rotation")
	schema:register(XMLValueType.FLOAT, key .. ".steeringAxle#scale", "Steering axle scale")
	schema:register(XMLValueType.ANGLE, key .. ".steeringAxle#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, key .. ".steeringAxle#rotMin", "Min. rotation")
end
