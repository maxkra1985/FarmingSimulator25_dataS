-- Local values: WheelChock_mt
WheelChock = {}
local WheelChock_mt = Class(WheelChock)

-- Upvalues: WheelChock_mt
-- Local values: self
function WheelChock.new(wheel, customMt)
	-- upvalues: (copy) WheelChock_mt
	local v4_ = customMt or WheelChock_mt
	local v5_ = setmetatable({}, v4_)
	v5_.wheel = wheel
	v5_.isInParkingPosition = false
	v5_.wheelRadiusOffset = 0
	return v5_
end

function WheelChock:delete()
	if self.node ~= nil then
		delete(self.node)
		self.node = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
end

-- Local values: vehicle, material
function WheelChock:loadFromXML(xmlObject, key)
	local v10_ = self.wheel.vehicle
	self.filename = xmlObject:getValue(key .. "#filename", "$data/shared/assets/wheelChocks/wheelChock01.i3d")
	self.filename = Utils.getFilename(self.filename, self.wheel.baseDirectory)
	if self.filename == nil then
		xmlObject:xmlWarning(key .. "#filename", "Invalid filename given for wheel chock")
		return false
	end
	self.parkingNode = xmlObject:getValue(key .. "#parkingNode", nil, v10_.components, v10_.i3dMappings)
	self.scale = xmlObject:getValue(key .. "#scale", "1 1 1", true)
	self.isInverted = xmlObject:getValue(key .. "#isInverted", false)
	self.isParked = xmlObject:getValue(key .. "#isParked", false)
	self.offset = xmlObject:getValue(key .. "#offset", "0 0 0", true)
	local v11_ = VehicleMaterial.new(self.wheel.baseDirectory)
	if v11_:loadFromXML(xmlObject, key, self.wheel.vehicle.customEnvironment) then
		self.material = v11_
	end
	v10_:onLoadWheelChockFromXML(self, xmlObject, key)
	self.sharedLoadRequestId = v10_:loadSubSharedI3DFile(self.filename, false, false, self.onI3DLoaded, self)
	return true
end

-- Local values: _, posRefNode
function WheelChock:onI3DLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		self.node = getChildAt(i3dNode, 0)
		local v14_ = I3DUtil.indexToObject(self.node, getUserAttribute(self.node, "posRefNode"))
		if v14_ == nil then
			Logging.warning("Missing \'posRefNode\'-userattribute for wheel-chock \'%s\'!", self.filename)
		else
			local _, v15_, v16_ = localToLocal(v14_, self.node, 0, 0, 0)
			self.height = v15_
			self.zOffset = v16_
			self.height = self.height * self.scale[2]
			self.zOffset = self.zOffset * self.scale[3]
			setScale(self.node, self.scale[1], self.scale[2], self.scale[3])
			self.parkedNode = I3DUtil.indexToObject(self.node, getUserAttribute(self.node, "parkedNode"))
			self.linkedNode = I3DUtil.indexToObject(self.node, getUserAttribute(self.node, "linkedNode"))
			if self.material ~= nil then
				self.material:apply(self.node, "wheelChock_main_mat")
			end
			self:update(self.isParked)
		end
		delete(i3dNode)
	end
end

-- Local values: wheel, radiusChockHeightOffset, angle, zWheelIntersection, zChockOffset, _, yRot, _, dirX, dirY, dirZ, normX, normY, normZ, posX, posY, posZ
function WheelChock:update(isInParkingPosition)
	if self.node ~= nil then
		if isInParkingPosition == nil then
			isInParkingPosition = self.isInParkingPosition
		end
		local v19_ = not self.wheel.vehicle:getIsWheelChockAllowed(self) and true or isInParkingPosition
		self.isInParkingPosition = v19_
		if v19_ then
			if self.parkingNode == nil then
				setVisibility(self.node, false)
			else
				setTranslation(self.node, 0, 0, 0)
				setRotation(self.node, 0, 0, 0)
				link(self.parkingNode, self.node)
				setVisibility(self.node, true)
			end
		else
			setVisibility(self.node, true)
			setScale(self.node, 1, 1, 1)
			local v20_ = self.wheel
			local v21_ = v20_.physics.radius - self.wheelRadiusOffset - self.height
			local v22_ = math.max(v21_, 0.01) / v20_.physics.radius
			local v23_ = math.acos(v22_)
			local v24_ = -(v20_.physics.radius * math.sin(v23_)) - self.zOffset
			link(v20_.node, self.node)
			local _, v25_, _ = localRotationToLocal(getParent(v20_.repr), v20_.node, getRotation(v20_.repr))
			if self.isInverted then
				v25_ = v25_ + 3.141592653589793
			end
			setRotation(self.node, 0, v25_, 0)
			local v26_, v27_, v28_ = localDirectionToLocal(self.node, v20_.node, 0, 0, 1)
			local v29_, v30_, v31_ = localDirectionToLocal(self.node, v20_.node, 1, 0, 0)
			local v32_, v33_, v34_ = localToLocal(v20_.driveNode, v20_.node, 0, 0, 0)
			local v35_ = v32_ + v29_ * self.offset[1] + v26_ * (v24_ + self.offset[3])
			local v36_ = v33_ + v30_ * self.offset[1] + v27_ * (v24_ + self.offset[3]) - v20_.physics.radius + self.wheelRadiusOffset + self.offset[2]
			local v37_ = v34_ + v31_ * self.offset[1] + v28_ * (v24_ + self.offset[3])
			setTranslation(self.node, v35_, v36_, v37_)
			setScale(self.node, self.scale[1], self.scale[2], self.scale[3])
		end
		if self.parkedNode ~= nil then
			setVisibility(self.parkedNode, v19_)
		end
		if self.linkedNode ~= nil then
			setVisibility(self.linkedNode, not v19_)
		end
		return true
	end
end

function WheelChock.registerXMLPaths(schema, key)
	schema:addDelayedRegistrationPath(key, "WheelChock")
	schema:register(XMLValueType.STRING, key .. "#filename", "Path to wheel chock i3d", "$data/shared/assets/wheelChocks/wheelChock01.i3d")
	schema:register(XMLValueType.VECTOR_SCALE, key .. "#scale", "Scale", "1 1 1")
	schema:register(XMLValueType.NODE_INDEX, key .. "#parkingNode", "Parking node")
	schema:register(XMLValueType.BOOL, key .. "#isInverted", "Is inverted (In front or back of the wheel)", false)
	schema:register(XMLValueType.BOOL, key .. "#isParked", "Default is parked", false)
	schema:register(XMLValueType.VECTOR_TRANS, key .. "#offset", "Translation offset", "0 0 0")
	VehicleMaterial.registerXMLPaths(schema, key)
end
