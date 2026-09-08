-- Local values: Wheel_mt
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

-- Upvalues: Wheel_mt
-- Local values: self
function Wheel.new(vehicle, xmlFile, baseKey, wheelKey, wheelIndex, configIndex, indexToParentIndex, baseDirectory, customMt)
	-- upvalues: (copy) Wheel_mt
	local v11_ = customMt or Wheel_mt
	local v12_ = setmetatable({}, v11_)
	v12_.vehicle = vehicle
	v12_.xmlFile = xmlFile
	v12_.xmlObject = WheelXMLObject.new(xmlFile, baseKey, configIndex, wheelKey, indexToParentIndex)
	v12_.baseDirectory = baseDirectory
	v12_.name = nil
	v12_.wheelIndex = wheelIndex
	v12_.updateIndex = (wheelIndex - 1) % 4 + 1
	v12_.brakePedal = 0
	v12_.syncContactState = false
	v12_.lastSteeringAngle = 0
	v12_.lastXDrive = 0
	v12_.lastSuspensionLength = 0
	v12_.additionalMass = 0
	v12_.physics = WheelPhysics.new(v12_)
	v12_.steering = WheelSteering.new(v12_)
	v12_.destruction = WheelDestruction.new(v12_)
	v12_.effects = WheelEffects.new(v12_)
	v12_.debug = WheelDebug.new(v12_)
	return v12_
end

-- Local values: newRepr, reprIndex, driveNodeDirectionNode, defaultX, defaultY, defaultZ, i, key, xmlFile, _, wheelChock, visualWheel, defaultFilename, key, xmlFile, _, isLeft, lastVisualWheel
function Wheel:loadFromXML()
	self.repr = self.xmlObject:getValue(".physics#repr", nil, self.vehicle.components, self.vehicle.i3dMappings)
	if self.repr == nil then
		self.xmlObject:xmlWarning(".physics#repr", "Failed to load wheel! Missing repr node.")
		return false
	end
	if not self.vehicle:getIsNodeActive(self.repr) then
		return false
	end
	self.isLeft = self.xmlObject:getValue("#isLeft", true)
	self.rimOffset = self.xmlObject:getValue("#rimOffset", 0)
	self.node = self.vehicle:getParentComponent(self.repr)
	if self.node == 0 then
		self.xmlObject:xmlWarning("", "Invalid repr for wheel. Needs to be a child of a collision!")
		return false
	end
	self.driveNode = self.xmlObject:getValue(".physics#driveNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
	if self.driveNode == self.repr then
		self.xmlObject:xmlWarning("", "repr and driveNode may not be equal. Using default driveNode instead!")
		self.driveNode = nil
	end
	self.linkNode = self.xmlObject:getValue(".physics#linkNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
	if self.driveNode == nil then
		local v14_ = createTransformGroup("wheelReprNode")
		local v15_ = getChildIndex(self.repr)
		link(getParent(self.repr), v14_, v15_)
		setTranslation(v14_, getTranslation(self.repr))
		setRotation(v14_, getRotation(self.repr))
		setScale(v14_, getScale(self.repr))
		self.driveNode = self.repr
		link(v14_, self.driveNode)
		setTranslation(self.driveNode, 0, 0, 0)
		setRotation(self.driveNode, 0, 0, 0)
		setScale(self.driveNode, 1, 1, 1)
		self.repr = v14_
	end
	if self.driveNode ~= nil then
		local v16_ = createTransformGroup("driveNodeDirectionNode")
		link(self.repr, v16_)
		setWorldTranslation(v16_, getWorldTranslation(self.driveNode))
		setWorldRotation(v16_, getWorldRotation(self.driveNode))
		self.driveNodeDirectionNode = v16_
		local v17_, v18_, v19_ = getRotation(self.driveNode)
		if math.abs(v17_) > 0.0001 or (math.abs(v18_) > 0.0001 or math.abs(v19_) > 0.0001) then
			self.xmlObject:xmlWarning("", "Rotation of driveNode \'%s\' is not 0/0/0 in the i3d file (%.1f/%.1f/%.1f).", getName(self.driveNode), math.deg(v17_), math.deg(v18_), (math.deg(v19_)))
		end
	end
	if self.linkNode == nil then
		self.linkNode = self.driveNode
	end
	self.transRatio = self.xmlObject:getValue(".physics#transRatio", 0)
	if not self.physics:loadFromXML(self.xmlObject) then
		return false
	end
	if not self.steering:loadFromXML(self.xmlObject) then
		return false
	end
	if not self.destruction:loadFromXML(self.xmlObject) then
		return false
	end
	if not self.effects:loadFromXML(self.xmlObject) then
		return false
	end
	local v20_, v21_, v22_ = getTranslation(self.repr)
	self.startPositionX = v20_
	self.startPositionY = v21_
	self.startPositionZ = v22_
	local v23_, v24_, v25_ = getTranslation(self.driveNode)
	self.driveNodeStartPosX = v23_
	self.driveNodeStartPosY = v24_
	self.driveNodeStartPosZ = v25_
	self.xmlObject:checkDeprecatedXMLElements(".tire#widthOffset", ".tire#offset")
	self.xmlObject:checkDeprecatedXMLElements("#color", "#material")
	self.xmlObject:checkDeprecatedXMLElements("#additionalColor", "#additionalMaterial")
	self.material = self.xmlObject:getValue("#material")
	self.additionalMaterial = self.xmlObject:getValue("#additionalMaterial")
	self.wheelChocks = {}
	local v26_ = 0
	while true do
		local v27_ = string.format(".wheelChock(%d)", v26_)
		local v28_, _ = self.xmlObject:getXMLFileAndPropertyKey(v27_)
		if v28_ == nil then
			break
		end
		local v29_ = WheelChock.new(self)
		if v29_:loadFromXML(self.xmlObject, v27_) then
			local v30_ = self.wheelChocks
			table.insert(v30_, v29_)
		end
		v26_ = v26_ + 1
	end
	self.visualWheels = {}
	local v31_ = WheelVisual.new(self.vehicle, self, self.linkNode, self.isLeft, self.rimOffset, self.baseDirectory)
	if v31_:loadFromXML(self.xmlObject) then
		self.additionalMass = self.additionalMass + v31_:getAdditionalMass()
		local v32_ = self.visualWheels
		table.insert(v32_, v31_)
	else
		v31_:delete()
	end
	local v33_ = self.xmlObject:getValue("#filename")
	self.name = self.name or self.xmlObject.externalWheelName
	local v34_ = 0
	while true do
		local v35_ = string.format(".additionalWheel(%d)", v34_)
		self.xmlObject:setXMLLoadKey("")
		local v36_, _ = self.xmlObject:getXMLFileAndPropertyKey(v35_)
		if v36_ == nil then
			break
		end
		self.xmlObject:setXMLLoadKey(v35_, v33_)
		local v37_ = self.xmlObject:getValue("#isLeft", self.isLeft)
		local v38_ = WheelVisual.new(self.vehicle, self, self.linkNode, v37_, 0, self.baseDirectory)
		if v38_:loadFromXML(self.xmlObject) then
			self.additionalMass = self.additionalMass + v38_:getAdditionalMass()
			local v39_ = self.visualWheels[#self.visualWheels]
			if v39_ ~= nil then
				v38_:setConnectedWheel(v39_, self.rimOffset + self.xmlObject:getValue("#offset", 0))
			end
			self.physics:loadAdditionalWheel(self.xmlObject)
			local v40_ = self.visualWheels
			table.insert(v40_, v38_)
		else
			v38_:delete()
		end
		v34_ = v34_ + 1
	end
	return true
end

-- Local values: minX, maxX, _, visualWheel, width, offset, shapeWidth, shapeOffset
function Wheel:finalize()
	local v42_ = math.huge
	local v43_ = -math.huge
	for _, v44_ in ipairs(self.visualWheels) do
		local v45_, v46_ = v44_:getWidthAndOffset()
		local v47_ = v46_ - v45_ * 0.5
		v42_ = math.min(v42_, v47_)
		local v48_ = v46_ + v45_ * 0.5
		v43_ = math.max(v43_, v48_)
	end
	if v42_ ~= math.huge then
		local v49_ = v43_ - v42_
		local v50_ = v42_ + v49_ * 0.5
		self.physics:setWheelShapeWidth(v49_, v50_)
	end
	self.physics:finalize()
	self.destruction:finalize()
	self.effects:finalize()
	if self.xmlObject ~= nil then
		self.xmlObject:delete()
		self.xmlObject = nil
	end
end

-- Local values: _, visualWheel
function Wheel:postLoad()
	for _, v52_ in ipairs(self.visualWheels) do
		v52_:postLoad()
	end
	self.physics:postLoad()
	self.effects:postLoad()
end

-- Local values: _, visualWheel, _, wheelChock
function Wheel:delete()
	for _, v54_ in ipairs(self.visualWheels) do
		v54_:delete()
	end
	for _, v55_ in ipairs(self.wheelChocks) do
		v55_:delete()
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

-- Local values: x, y, z, xDrive, suspensionLength, steeringAngle, changed, initialSuspensionLength, _, visualWheel, wheelRadiusOffset, dirX, dirY, dirZ, movement, _, wheelChock
function Wheel:update(dt, currentUpdateIndex, groundWetness, force)
	if self.vehicle.isServer then
		if self.vehicle.isAddedToPhysics then
			self.physics:serverUpdate(dt, currentUpdateIndex, groundWetness)
		end
	else
		self.physics:clientUpdate(dt, currentUpdateIndex, groundWetness)
	end
	if self.vehicle.currentUpdateDistance < Wheel.VISUAL_WHEEL_UPDATE_DISTANCE or force then
		local v66_, v67_, v68_, v69_, v70_, v71_ = self.physics:getVisualInfo()
		local v72_ = v71_ - self.lastSteeringAngle
		local v73_
		if math.abs(v72_) > Wheel.STEERING_ANGLE_THRESHOLD then
			setRotation(self.repr, 0, v71_, 0)
			self.lastSteeringAngle = v71_
			v73_ = true
		else
			v73_ = false
		end
		local v74_ = v69_ - self.lastXDrive
		if math.abs(v74_) > Wheel.STEERING_ANGLE_THRESHOLD then
			setRotation(self.driveNode, v69_, 0, 0)
			self.lastXDrive = v69_
			v73_ = true
		end
		local v75_ = v70_
		for _, v76_ in ipairs(self.visualWheels) do
			v73_, v75_ = v76_:update(v66_, v67_, v68_, v69_, v70_, v71_, v73_)
		end
		local v77_ = v75_ - v70_
		local v78_ = self.lastSuspensionLength - v75_
		if math.abs(v78_) > Wheel.SUSPENSION_THRESHOLD then
			local v79_, v80_, v81_ = localDirectionToLocal(self.repr, getParent(self.repr), 0, -1, 0)
			local v82_ = v75_ * self.transRatio
			setTranslation(self.repr, self.startPositionX + v79_ * v82_, self.startPositionY + v80_ * v82_, self.startPositionZ + v81_ * v82_)
			if self.transRatio < 1 then
				local v83_ = v75_ * (1 - self.transRatio)
				setTranslation(self.driveNode, self.driveNodeStartPosX + v79_ * v83_, self.driveNodeStartPosY + v80_ * v83_, self.driveNodeStartPosZ + v81_ * v83_)
			end
			self.lastSuspensionLength = v75_
			v73_ = true
		end
		self.steering:update(v66_, v67_, v68_, v69_, v75_, v71_, v73_)
		if v73_ then
			for _, v84_ in ipairs(self.wheelChocks) do
				if not v84_.isInParkingPosition then
					v84_.wheelRadiusOffset = v77_
					v84_:update()
				end
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

-- Local values: _, wheelChock
function Wheel:onPreAttach()
	for _, v97_ in ipairs(self.wheelChocks) do
		v97_:update(true)
	end
end

-- Local values: _, wheelChock
function Wheel:onPostDetach()
	for _, v99_ in ipairs(self.wheelChocks) do
		v99_:update(false)
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

-- Local values: _, visualWheel, tireNode
function Wheel:getFirstTireNode()
	for _, v117_ in ipairs(self.visualWheels) do
		local v118_ = v117_:getTireNode()
		if v118_ ~= nil then
			return v118_
		end
	end
	return nil
end

-- Local values: additionalWheelKey
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
	local v121_ = key .. ".additionalWheel(?)"
	schema:register(XMLValueType.STRING, v121_ .. "#filename", "Filename")
	schema:registerAutoCompletionDataSource(v121_ .. "#filename", "data/shared/wheels/wheels.xml", "wheels.wheel#filename")
	schema:register(XMLValueType.BOOL, v121_ .. "#isLeft", "Is left", "Same value as parent wheel")
	schema:register(XMLValueType.STRING, v121_ .. "#configId", "Wheel config id", "default")
	schema:register(XMLValueType.FLOAT, v121_ .. "#offset", "X Offset of additional wheel")
	WheelVisual.registerXMLPaths(schema, v121_)
	WheelPhysics.registerAdditionalWheelXMLPaths(schema, v121_)
	WheelChock.registerXMLPaths(schema, key .. ".wheelChock(?)")
end
