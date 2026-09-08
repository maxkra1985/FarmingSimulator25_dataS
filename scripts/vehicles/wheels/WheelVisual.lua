-- Local values: WheelVisual_mt
WheelVisual = {}
source("dataS/scripts/vehicles/wheels/WheelVisualPart.lua")
source("dataS/scripts/vehicles/wheels/WheelVisualPartConnector.lua")
source("dataS/scripts/vehicles/wheels/WheelVisualPartTire.lua")
local v1_ = WheelVisual
local v2_ = {
	["tire"] = {
		["class"] = WheelVisualPartTire,
		["name"] = "Tire"
	},
	["outerRim"] = {
		["class"] = WheelVisualPart,
		["name"] = "Outer Rim"
	},
	["innerRim"] = {
		["class"] = WheelVisualPart,
		["name"] = "Inner Rim"
	},
	["additional"] = {
		["class"] = WheelVisualPart,
		["name"] = "Additional"
	},
	["connector"] = {
		["class"] = WheelVisualPartConnector,
		["name"] = "Connector"
	}
}
v1_.PARTS = v2_
local WheelVisual_mt = Class(WheelVisual)

-- Upvalues: WheelVisual_mt
-- Local values: self
function WheelVisual.new(vehicle, wheel, linkNode, isLeft, rimOffset, baseDirectory, customMt)
	-- upvalues: (copy) WheelVisual_mt
	local v11_ = customMt or WheelVisual_mt
	local v12_ = setmetatable({}, v11_)
	v12_.vehicle = vehicle
	v12_.wheel = wheel
	v12_.isLeft = isLeft
	v12_.rimOffset = rimOffset
	v12_.baseDirectory = baseDirectory
	v12_.width = 0.5
	v12_.radius = 0.5
	v12_.mass = 0
	v12_.linkNode = linkNode
	v12_.node = createTransformGroup("visualWheel")
	link(linkNode, v12_.node)
	v12_.visualParts = {}
	return v12_
end

-- Local values: _, visualPart
function WheelVisual:delete()
	for _, v14_ in ipairs(self.visualParts) do
		v14_:delete()
	end
	self:removeShallowWaterObstacle()
	delete(self.node)
end

-- Local values: widthAndDiam, rimMaterialTemplateName, rimMaterial, xmlName, data, i, key, xmlFile, _, visualPart
function WheelVisual:loadFromXML(xmlObject)
	if xmlObject.externalXMLFile ~= nil then
		self.externalXMLFilename = xmlObject.externalXMLFile.filename
	end
	self.externalConfigId = xmlObject.externalConfigId
	self.width = xmlObject:getValue(".physics#width", self.width)
	self.radius = xmlObject:getValue(".physics#radius", self.radius)
	local v17_ = xmlObject:getValue(".outerRim(0)#widthAndDiam", nil, true)
	if v17_ ~= nil then
		self.rimDiameter = v17_[2]
	end
	local v18_ = xmlObject:getValue("#rimMaterialTemplateName")
	if v18_ ~= nil then
		local v19_ = VehicleMaterial.new()
		if v19_:setTemplateName(v18_, nil, self.vehicle.customEnvironment) then
			self.rimMaterial = v19_
		end
	end
	for v20_, v21_ in pairs(WheelVisual.PARTS) do
		local v22_ = 0
		while true do
			local v23_ = string.format(".%s(%d)", v20_, v22_)
			local v24_, _ = xmlObject:getXMLFileAndPropertyKey(v23_)
			if v24_ == nil then
				break
			end
			local v25_ = v21_.class.new(v20_, self, self.node)
			if v25_:loadFromXML(xmlObject, v23_) then
				if v20_ ~= "innerRim" and v20_ ~= "additional" then
					v25_.offset = v25_.offset + self.rimOffset
				end
				local v26_ = self.visualParts
				table.insert(v26_, v25_)
			end
			v22_ = v22_ + 1
		end
	end
	return #self.visualParts > 0
end

-- Local values: _, visualPart
function WheelVisual:postLoad()
	for _, v28_ in ipairs(self.visualParts) do
		if self.rimMaterial ~= nil and (v28_.name == "innerRim" or v28_.name == "outerRim") then
			self.rimMaterial:apply(v28_.node, v28_:getDefaultMaterialSlotName())
		end
		v28_:postLoad()
	end
end

-- Local values: otherX, _, _, invertOffset
function WheelVisual:setConnectedWheel(connectedVisualWheel, offset)
	self.connectedVisualWheel = connectedVisualWheel
	self.connectedVisualWheelOffset = offset
	local v32_, _, _ = getTranslation(connectedVisualWheel.node)
	local v33_ = offset < 0
	local v34_ = offset + self.width * 0.5 + connectedVisualWheel.width * 0.5
	if not self.isLeft then
		v34_ = -v34_
	end
	if v33_ then
		v34_ = -v34_
	end
	self.connectedVisualWheelOffsetDirection = math.sign(v34_)
	setTranslation(self.node, v32_ + v34_, 0, 0)
end

-- Local values: offsetX, _, _, _, visualPart
function WheelVisual:getWidthAndOffset()
	local v36_, _, _ = getTranslation(self.node)
	for _, v37_ in ipairs(self.visualParts) do
		if v37_:isa(WheelVisualPartTire) then
			return self.width, v36_ + (self.isLeft and v37_.offset or -v37_.offset)
		end
	end
	return self.width, v36_
end

-- Local values: _, visualPart
function WheelVisual:getIsTireInverted()
	for _, v39_ in ipairs(self.visualParts) do
		if v39_:isa(WheelVisualPartTire) then
			return self.isInverted
		end
	end
	return false
end

-- Local values: _, visualPart
function WheelVisual:getTireNode()
	for _, v41_ in ipairs(self.visualParts) do
		if v41_:isa(WheelVisualPartTire) then
			return v41_.node
		end
	end
	return nil
end

-- Local values: additionalMass, _, visualPart
function WheelVisual:getAdditionalMass()
	local v43_ = 0
	for _, v44_ in ipairs(self.visualParts) do
		v43_ = v43_ + v44_:getMass()
	end
	return v43_
end

-- Local values: _, visualPart
function WheelVisual:update(x, y, z, xDrive, suspensionLength, steeringAngle, changed)
	for _, v53_ in ipairs(self.visualParts) do
		if v53_.update ~= nil then
			changed, suspensionLength = v53_:update(x, y, z, xDrive, suspensionLength, steeringAngle, changed)
		end
	end
	return changed, suspensionLength
end

function WheelVisual:addShallowWaterObstacle()
	if g_currentMission.shallowWaterSimulation == nil then
		return
	elseif self.vehicle.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
		if self.wheel == nil then
			self.shallowWaterRotationNode = createTransformGroup("shallowWaterRotationNode")
			link(getParent(self.linkNode), self.shallowWaterRotationNode)
			setWorldTranslation(self.shallowWaterRotationNode, getWorldTranslation(self.node))
			setWorldRotation(self.shallowWaterRotationNode, getWorldRotation(self.node))
		else
			self.shallowWaterRotationNode = self.wheel.driveNodeDirectionNode
		end
		self.shallowWaterObstacle = g_currentMission.shallowWaterSimulation:addObstacle(self.node, self.width, self.radius * 2, self.radius * 1.75, self.getShallowWaterParameters, self)
	end
end

function WheelVisual:removeShallowWaterObstacle()
	if self.shallowWaterObstacle ~= nil then
		g_currentMission.shallowWaterSimulation:removeObstacle(self.shallowWaterObstacle)
		self.shallowWaterObstacle = nil
	end
end

-- Local values: velocity, ox, oz, slip, dx, _, dz, yRot
function WheelVisual:getShallowWaterParameters()
	local v57_ = self.vehicle.lastSignedSpeed * 1000
	local v58_ = 0
	local v59_ = 0
	if self.wheel.physics ~= nil then
		local v60_ = self.wheel.physics.netInfo.slip
		if v60_ > 0.1 then
			v58_ = math.random() * 2 - 1 * v60_
			v59_ = math.random() * 2 - 1 * v60_
		end
	end
	if v58_ == 0 and math.abs(v57_) > 0.27 then
		v58_ = math.random() * 2 - 1
		v59_ = math.random() * 2 - 1
	end
	local v61_, _, v62_ = localDirectionToWorld(self.shallowWaterRotationNode, 0, 0, 1)
	local v63_ = MathUtil.getYRotationFromDirection(v61_, v62_)
	local v64_ = v61_ * v57_
	local v65_ = v62_ * v57_
	return v64_ + v58_, v65_ + v59_, v63_
end

-- Local values: xmlName, data
function WheelVisual.registerXMLPaths(schema, key)
	schema:register(XMLValueType.FLOAT, key .. ".physics#radius", "Wheel radius", 0.5)
	schema:register(XMLValueType.FLOAT, key .. ".physics#width", "Wheel width", 0.6)
	schema:register(XMLValueType.STRING, key .. "#rimMaterialTemplateName", "Material template to apply to the inner and outer rim")
	for v68_, v69_ in pairs(WheelVisual.PARTS) do
		v69_.class.registerXMLPaths(schema, key .. "." .. v68_ .. "(?)", v69_.name)
	end
end
