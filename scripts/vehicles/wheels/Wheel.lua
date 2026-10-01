Wheel = {}
Wheel.VISUAL_WHEEL_UPDATE_DISTANCE = 300
Wheel.STEERING_ANGLE_THRESHOLD = 0.00034
Wheel.SUSPENSION_THRESHOLD = 0.001
source("dataS/scripts/vehicles/wheels/WheelXMLObject.lua")
source("dataS/scripts/vehicles/wheels/WheelPhysics.lua")
source("dataS/scripts/vehicles/wheels/WheelDestruction.lua")
source("dataS/scripts/vehicles/wheels/WheelEffects.lua")
source("dataS/scripts/vehicles/wheels/WheelSteering.lua")
source("dataS/scripts/vehicles/wheels/WheelVisual.lua")
source("dataS/scripts/vehicles/wheels/WheelDebug.lua")
source("dataS/scripts/vehicles/wheels/WheelChock.lua")
local Wheel_mt = Class(Wheel)
function Wheel.new(vehicle, xmlFile, baseKey, wheelKey, wheelIndex, configIndex, indexToParentIndex, baseDirectory, customMt)
	local self = setmetatable({}, customMt or Wheel_mt)
	self.vehicle = vehicle
	self.xmlFile = xmlFile
	self.xmlObject = WheelXMLObject.new(xmlFile, baseKey, configIndex, wheelKey, indexToParentIndex)
	self.baseDirectory = baseDirectory
	self.name = nil
	self.wheelIndex = wheelIndex
	self.updateIndex = (wheelIndex - 1) % 4 + 1
	self.brakePedal = 0
	self.syncContactState = false
	self.lastSteeringAngle = 0
	self.lastXDrive = 0
	self.lastSuspensionLength = 0
	self.additionalMass = 0
	self.physics = WheelPhysics.new(self)
	self.steering = WheelSteering.new(self)
	self.destruction = WheelDestruction.new(self)
	self.effects = WheelEffects.new(self)
	self.debug = WheelDebug.new(self)
	return self
end
function Wheel:loadFromXML()
	self.repr = self.xmlObject:getValue(".physics#repr", nil, self.vehicle.components, self.vehicle.i3dMappings)
	if self.repr == nil then
		self.xmlObject:xmlWarning(".physics#repr", "Failed to load wheel! Missing repr node.")
		return false
	elseif not self.vehicle:getIsNodeActive(self.repr) then
		return false
	else
		self.isLeft = self.xmlObject:getValue("#isLeft", true)
		self.rimOffset = self.xmlObject:getValue("#rimOffset", 0)
		self.node = self.vehicle:getParentComponent(self.repr)
		if self.node ~= 0 then
			self.driveNode = self.xmlObject:getValue(".physics#driveNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
			if self.driveNode == self.repr then
				self.xmlObject:xmlWarning("", "repr and driveNode may not be equal. Using default driveNode instead!")
				self.driveNode = nil
			end
			self.linkNode = self.xmlObject:getValue(".physics#linkNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
			if self.driveNode == nil then
				local newRepr = createTransformGroup("wheelReprNode")
				local reprIndex = getChildIndex(self.repr)
				link(getParent(self.repr), newRepr, reprIndex)
				setTranslation(newRepr, getTranslation(self.repr))
				setRotation(newRepr, getRotation(self.repr))
				setScale(newRepr, getScale(self.repr))
				self.driveNode = self.repr
				link(newRepr, self.driveNode)
				setTranslation(self.driveNode, 0, 0, 0)
				setRotation(self.driveNode, 0, 0, 0)
				setScale(self.driveNode, 1, 1, 1)
				self.repr = newRepr
			end
			if self.driveNode ~= nil then
				local driveNodeDirectionNode = createTransformGroup("driveNodeDirectionNode")
				link(self.repr, driveNodeDirectionNode)
				setWorldTranslation(driveNodeDirectionNode, getWorldTranslation(self.driveNode))
				setWorldRotation(driveNodeDirectionNode, getWorldRotation(self.driveNode))
				self.driveNodeDirectionNode = driveNodeDirectionNode
				local defaultX, defaultY, defaultZ = getRotation(self.driveNode)
				if 0.0001 < math.abs(defaultX) or 0.0001 < math.abs(defaultY) or 0.0001 < math.abs(defaultZ) then
					self.xmlObject:xmlWarning("", "Rotation of driveNode '%s' is not 0/0/0 in the i3d file (%.1f/%.1f/%.1f).", getName(self.driveNode), math.deg(defaultX), math.deg(defaultY), math.deg(defaultZ))
				end
			end
			if self.linkNode == nil then
				self.linkNode = self.driveNode
			end
			self.transRatio = self.xmlObject:getValue(".physics#transRatio", 0)
			if not self.physics:loadFromXML(self.xmlObject) then
				return false
			elseif not self.steering:loadFromXML(self.xmlObject) then
				return false
			elseif not self.destruction:loadFromXML(self.xmlObject) then
				return false
			elseif not self.effects:loadFromXML(self.xmlObject) then
				return false
			else
				self.startPositionX, self.startPositionY, self.startPositionZ = getTranslation(self.repr)
				self.driveNodeStartPosX, self.driveNodeStartPosY, self.driveNodeStartPosZ = getTranslation(self.driveNode)
				self.xmlObject:checkDeprecatedXMLElements(".tire#widthOffset", ".tire#offset")
				self.xmlObject:checkDeprecatedXMLElements("#color", "#material")
				self.xmlObject:checkDeprecatedXMLElements("#additionalColor", "#additionalMaterial")
				self.material = self.xmlObject:getValue("#material")
				self.additionalMaterial = self.xmlObject:getValue("#additionalMaterial")
				self.wheelChocks = {}
				local i = 0
				while true do
					local key = string.format(".wheelChock(%d)", i)
					local xmlFile, _ = self.xmlObject:getXMLFileAndPropertyKey(key)
					if xmlFile == nil then
						break
					end
					local wheelChock = WheelChock.new(self)
					if wheelChock:loadFromXML(self.xmlObject, key) then
						table.insert(self.wheelChocks, wheelChock)
					end
					i = i + 1
				end
				self.visualWheels = {}
				local visualWheel = WheelVisual.new(self.vehicle, self, self.linkNode, self.isLeft, self.rimOffset, self.baseDirectory)
				if visualWheel:loadFromXML(self.xmlObject) then
					self.additionalMass = self.additionalMass + visualWheel:getAdditionalMass()
					table.insert(self.visualWheels, visualWheel)
				else
					visualWheel:delete()
				end
				local defaultFilename = self.xmlObject:getValue("#filename")
				self.name = self.name or self.xmlObject.externalWheelName
				i = 0
				while true do
					local key = string.format(".additionalWheel(%d)", i)
					self.xmlObject:setXMLLoadKey("")
					local xmlFile, _ = self.xmlObject:getXMLFileAndPropertyKey(key)
					if xmlFile == nil then
						break
					end
					self.xmlObject:setXMLLoadKey(key, defaultFilename)
					local isLeft = self.xmlObject:getValue("#isLeft", self.isLeft)
					visualWheel = WheelVisual.new(self.vehicle, self, self.linkNode, isLeft, 0, self.baseDirectory)
					if visualWheel:loadFromXML(self.xmlObject) then
						self.additionalMass = self.additionalMass + visualWheel:getAdditionalMass()
						local lastVisualWheel = self.visualWheels[#self.visualWheels]
						if lastVisualWheel ~= nil then
							visualWheel:setConnectedWheel(lastVisualWheel, self.rimOffset + self.xmlObject:getValue("#offset", 0))
						end
						self.physics:loadAdditionalWheel(self.xmlObject)
						table.insert(self.visualWheels, visualWheel)
					else
						visualWheel:delete()
					end
					i = i + 1
				end
				return true
			end
		end
		self.xmlObject:xmlWarning("", "Invalid repr for wheel. Needs to be a child of a collision!")
		return false
	end
end
function Wheel:finalize()
	local minX = math.huge
	local maxX = -math.huge
	for _, visualWheel in ipairs(self.visualWheels) do
		local width, offset = visualWheel:getWidthAndOffset()
		minX = math.min(minX, offset - width * 0.5)
		maxX = math.max(maxX, offset + width * 0.5)
	end
	if minX ~= math.huge then
		local shapeWidth = maxX - minX
		local shapeOffset = minX + shapeWidth * 0.5
		self.physics:setWheelShapeWidth(shapeWidth, shapeOffset)
	end
	self.physics:finalize()
	self.destruction:finalize()
	self.effects:finalize()
	if self.xmlObject ~= nil then
		self.xmlObject:delete()
		self.xmlObject = nil
	end
end
function Wheel:postLoad()
	for _, visualWheel in ipairs(self.visualWheels) do
		visualWheel:postLoad()
	end
	self.physics:postLoad()
	self.effects:postLoad()
end
function Wheel:delete()
	for _, visualWheel in ipairs(self.visualWheels) do
		visualWheel:delete()
	end
	for _, wheelChock in ipairs(self.wheelChocks) do
		wheelChock:delete()
	end
	self.effects:delete()
	self.debug:delete()
	if self.xmlObject ~= nil then
		self.xmlObject:delete()
		self.xmlObject = nil
	end
end
function Wheel:readStream(streamId, updateInterpolation)
	self.physics:readStream(streamId, updateInterpolation)
end
function Wheel:writeStream(streamId)
	self.physics:writeStream(streamId)
end
function Wheel:update(dt, currentUpdateIndex, groundWetness, force)
	if self.vehicle.isServer then
		if self.vehicle.isAddedToPhysics then
			self.physics:serverUpdate(dt, currentUpdateIndex, groundWetness)
		end
	else
		self.physics:clientUpdate(dt, currentUpdateIndex, groundWetness)
	end
	if self.vehicle.currentUpdateDistance < Wheel.VISUAL_WHEEL_UPDATE_DISTANCE or force then
		local x, y, z, xDrive, suspensionLength, steeringAngle = self.physics:getVisualInfo()
		local changed = false
		if Wheel.STEERING_ANGLE_THRESHOLD < math.abs(steeringAngle - self.lastSteeringAngle) then
			setRotation(self.repr, 0, steeringAngle, 0)
			self.lastSteeringAngle = steeringAngle
			changed = true
		end
		if Wheel.STEERING_ANGLE_THRESHOLD < math.abs(xDrive - self.lastXDrive) then
			setRotation(self.driveNode, xDrive, 0, 0)
			self.lastXDrive = xDrive
			changed = true
		end
		local initialSuspensionLength = suspensionLength
		for _, visualWheel in ipairs(self.visualWheels) do
			changed, suspensionLength = visualWheel:update(x, y, z, xDrive, initialSuspensionLength, steeringAngle, changed)
		end
		local wheelRadiusOffset = suspensionLength - initialSuspensionLength
		if Wheel.SUSPENSION_THRESHOLD < math.abs(self.lastSuspensionLength - suspensionLength) then
			local dirX, dirY, dirZ = localDirectionToLocal(self.repr, getParent(self.repr), 0, -1, 0)
			local movement = suspensionLength * self.transRatio
			setTranslation(self.repr, self.startPositionX + dirX * movement, self.startPositionY + dirY * movement, self.startPositionZ + dirZ * movement)
			if self.transRatio < 1 then
				movement = suspensionLength * (1 - self.transRatio)
				setTranslation(self.driveNode, self.driveNodeStartPosX + dirX * movement, self.driveNodeStartPosY + dirY * movement, self.driveNodeStartPosZ + dirZ * movement)
			end
			self.lastSuspensionLength = suspensionLength
			changed = true
		end
		self.steering:update(x, y, z, xDrive, suspensionLength, steeringAngle, changed)
		if changed then
			for _, wheelChock in ipairs(self.wheelChocks) do
				if wheelChock.isInParkingPosition then
					continue
				end
				wheelChock.wheelRadiusOffset = wheelRadiusOffset
				wheelChock:update()
			end
		end
		self.effects:update(dt, groundWetness, currentUpdateIndex)
	end
end
function Wheel:updateInterpolation(dt, interpolationAlpha)
	self.physics:updateInterpolation(dt, interpolationAlpha)
end
function Wheel:updateTick(dt, groundWetness, currentUpdateDistance)
	self.physics:updateTick(dt, groundWetness, currentUpdateDistance)
	self.effects:updateTick(dt, groundWetness, currentUpdateDistance)
end
function Wheel:postUpdate(dt)
	self.physics:postUpdate(dt)
end
function Wheel:onUpdateEnd(dt)
	self.effects:onUpdateEnd(dt)
end
function Wheel:onPreAttach()
	for _, wheelChock in ipairs(self.wheelChocks) do
		wheelChock:update(true)
	end
end
function Wheel:onPostDetach()
	for _, wheelChock in ipairs(self.wheelChocks) do
		wheelChock:update(false)
	end
end
function Wheel:addToPhysics(brakeForce)
	self.physics:addToPhysics(brakeForce)
end
function Wheel:updatePhysics(brakeForce)
	self.physics:updatePhysics(brakeForce)
end
function Wheel:removeFromPhysics()
	self.physics:removeFromPhysics()
end
function Wheel:getMass()
	return self.physics.mass + self.additionalMass
end
function Wheel:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
	self.physics:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
	self.steering:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
end
function Wheel:setBrakePedal(brakePedal)
	self.brakePedal = brakePedal
	self.physics:updatePhysics(self.vehicle:getBrakeForce() * self.brakePedal)
end
function Wheel:setIsCareWheel(isCareWheel)
	self.destruction:setIsCareWheel(isCareWheel)
end
function Wheel:getFirstTireNode()
	for _, visualWheel in ipairs(self.visualWheels) do
		local tireNode = visualWheel:getTireNode()
		if tireNode == nil then
			continue
		end
		return tireNode
	end
	return nil
end
function Wheel.registerXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. ".physics#repr", "Repr node")
	schema:register(XMLValueType.NODE_INDEX, key .. ".physics#driveNode", "Drive node")
	schema:register(XMLValueType.NODE_INDEX, key .. ".physics#linkNode", "Link node")
	schema:register(XMLValueType.FLOAT, key .. ".physics#transRatio", "Suspension translation ratio between repr and drive node (1: repr only, 0: drive node only)", 0)
	schema:register(XMLValueType.INT, key .. "#material", "Wheel material id")
	schema:register(XMLValueType.INT, key .. "#additionalMaterial", "Additional wheel material id")
	schema:register(XMLValueType.BOOL, key .. "#isLeft", "Is left", true)
	schema:register(XMLValueType.FLOAT, key .. "#rimOffset", "Offset that is only applied to the outer rim and the wheel itself, inner rim stays the same.", 0)
	schema:register(XMLValueType.STRING, key .. "#filename", "Filename")
	schema:registerAutoCompletionDataSource(key .. "#filename", "data/shared/wheels/wheels.xml", "wheels.wheel#filename")
	schema:register(XMLValueType.STRING, key .. "#dimensions", "List of dimensions for automatic branded wheel configuration generation")
	schema:register(XMLValueType.STRING, key .. "#configId", "Wheel config id", "default")
	WheelPhysics.registerXMLPaths(schema, key)
	WheelSteering.registerXMLPaths(schema, key)
	WheelDestruction.registerXMLPaths(schema, key)
	WheelEffects.registerXMLPaths(schema, key)
	WheelVisual.registerXMLPaths(schema, key)
	local additionalWheelKey = key .. ".additionalWheel(?)"
	schema:register(XMLValueType.STRING, additionalWheelKey .. "#filename", "Filename")
	schema:registerAutoCompletionDataSource(additionalWheelKey .. "#filename", "data/shared/wheels/wheels.xml", "wheels.wheel#filename")
	schema:register(XMLValueType.BOOL, additionalWheelKey .. "#isLeft", "Is left", "Same value as parent wheel")
	schema:register(XMLValueType.STRING, additionalWheelKey .. "#configId", "Wheel config id", "default")
	schema:register(XMLValueType.FLOAT, additionalWheelKey .. "#offset", "X Offset of additional wheel")
	WheelVisual.registerXMLPaths(schema, additionalWheelKey)
	WheelPhysics.registerAdditionalWheelXMLPaths(schema, additionalWheelKey)
	WheelChock.registerXMLPaths(schema, key .. ".wheelChock(?)")
end
