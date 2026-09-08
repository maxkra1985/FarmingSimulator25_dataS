WheelPhysics = {}
WheelPhysics.COLLISION_GROUP = CollisionFlag.VEHICLE
local v1_ = WheelPhysics
local v2_ = CollisionMask.ALL
local v3_ = CollisionFlag.WATER
local v4_ = CollisionFlag.AI_BLOCKING
local v5_ = CollisionFlag.GROUND_TIP_BLOCKING
local v6_ = CollisionFlag.PLACEMENT_BLOCKING
local v7_ = CollisionFlag.CAMERA_BLOCKING
local v8_ = CollisionFlag.PRECIPITATION_BLOCKING
local v9_ = CollisionFlag.ANIMAL_POSITIONING
local v10_ = CollisionFlag.ANIMAL_NAV_MESH_BLOCKING
local v11_ = CollisionFlag.TRAFFIC_VEHICLE_BLOCKING
v1_.COLLISION_MASK = v2_ - bit32.bor(v3_, v4_, v5_, v6_, v7_, v8_, v9_, v10_, v11_)
WheelPhysics.X_DRIVE_MAX_REAL_VALUE = 0.08726646259971647
WheelPhysics.X_DRIVE_NUM_BITS = 9
WheelPhysics.X_DRIVE_MAX_VALUE = 2 ^ WheelPhysics.X_DRIVE_NUM_BITS - 1
WheelPhysics.MAX_SINK = {}
WheelPhysics.MAX_SINK[FieldGroundType.STUBBLE_TILLAGE] = 0.07
WheelPhysics.MAX_SINK[FieldGroundType.CULTIVATED] = 0.08
WheelPhysics.MAX_SINK[FieldGroundType.SEEDBED] = 0.07
WheelPhysics.MAX_SINK[FieldGroundType.PLOWED] = 0.12
WheelPhysics.MAX_SINK[FieldGroundType.ROLLED_SEEDBED] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.RIDGE] = 0.1
WheelPhysics.MAX_SINK[FieldGroundType.SOWN] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.DIRECT_SOWN] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.PLANTED] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.RIDGE_SOWN] = 0.1
WheelPhysics.MAX_SINK[FieldGroundType.ROLLER_LINES] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.HARVEST_READY] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.HARVEST_READY_OTHER] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.GRASS] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.GRASS_CUT] = 0.05
WheelPhysics.WATER_SINK = 0.15

-- Local values: self
function WheelPhysics.new(wheel)
	local v13_ = {
		["__index"] = WheelPhysics
	}
	local v14_ = setmetatable({}, v13_)
	v14_.wheel = wheel
	v14_.vehicle = wheel.vehicle
	v14_.wheelShape = 0
	v14_.wheelShapeCreationFrameIndex = math.huge
	v14_.wheelShapeCreated = false
	v14_.torque = 0
	v14_.torqueDirection = 1
	v14_.dirtAmount = 0
	v14_.trackAlpha = 0
	v14_.groundColor = { 0, 0, 0 }
	v14_.fieldGroundColor = { 0, 0, 0 }
	v14_.trackColor = { 0, 0, 0 }
	v14_.groundDepth = 0
	v14_.colorBlendWithTerrain = 1
	v14_.lastTerrainAttribute = 0
	v14_.contact = WheelContactType.NONE
	v14_.hasWaterContact = false
	v14_.hasSnowContact = false
	v14_.snowScale = 0
	v14_.lastSnowScale = 0
	v14_.steeringAngle = 0
	v14_.hasGroundContact = false
	v14_.lastContactObjectAllowsTireTracks = true
	v14_.densityBits = 0
	v14_.densityType = FieldGroundType.NONE
	v14_.displacementScale = 1
	v14_.displacementAllowed = true
	v14_.displacementCollisionEnabled = true
	v14_.sink = 0
	v14_.sinkTarget = 0
	v14_.hasSoilContact = false
	v14_.tireGroundFrictionCoeff = 1
	return v14_
end

-- Local values: initialCompression, tireTypeName, maxInnerSpacing, offset, x, y, z
function WheelPhysics:loadFromXML(xmlObject)
	self.radius = xmlObject:getValue(".physics#radius")
	if self.radius == nil then
		xmlObject:xmlWarning(".physics#radius", "No radius defined for wheel! Using default value of 0.5!")
		self.radius = 0.5
	end
	self.radiusOriginal = self.radius
	self.width = xmlObject:getValue(".physics#width")
	if self.width == nil then
		xmlObject:xmlWarning(".physics#width", "No width defined for wheel! Using default value of 0.5!")
		self.width = 0.5
	end
	self.wheelShapeWidth = self.width
	self.wheelShapeWidthOffset = 0
	self.mass = xmlObject:getValue(".physics#mass", 0.1)
	self.baseMass = self.mass
	self.restLoad = xmlObject:getValue(".physics#restLoad", 1)
	self.frictionScale = xmlObject:getValue(".physics#frictionScale", 1)
	if self.frictionScale <= 0 then
		self.frictionScale = 0.01
		xmlObject:xmlWarning(".physics#frictionScale", "Wheel \'frictionScale\' set to \'0\'. This is not allowed!")
	end
	self.maxLongStiffness = xmlObject:getValue(".physics#maxLongStiffness", 30)
	self.maxLatStiffness = xmlObject:getValue(".physics#maxLatStiffness", 40)
	self.maxLatStiffnessLoad = xmlObject:getValue(".physics#maxLatStiffnessLoad", 2)
	self.xOffset = xmlObject:getValue(".physics#xOffset", 0)
	self.yOffset = xmlObject:getValue(".physics#yOffset", 0)
	self.zOffset = xmlObject:getValue(".physics#zOffset", 0)
	self.useReprOffset = xmlObject:getValue(".physics#useReprOffset", false)
	if self.xOffset ~= 0 or (self.yOffset ~= 0 or self.zOffset ~= 0) then
		if self.useReprOffset then
			setTranslation(self.wheel.repr, localToLocal(self.wheel.repr, getParent(self.wheel.repr), self.wheel.isLeft and self.xOffset or -self.xOffset, self.yOffset, self.zOffset))
		else
			setTranslation(self.wheel.driveNode, localToLocal(self.wheel.driveNode, getParent(self.wheel.driveNode), self.wheel.isLeft and self.xOffset or -self.xOffset, self.yOffset, self.zOffset))
		end
	end
	self.showSteeringAngle = xmlObject:getValue(".physics#showSteeringAngle")
	self.steeringAngleFactor = xmlObject:getValue(".physics#steeringAngleFactor", self.steeringAngleFactor or 1)
	self.steeringAngleFactorInv = 1 / self.steeringAngleFactor
	self.steeringAngle = xmlObject:getValue(".physics#startSteeringAngle", 0)
	self.suspTravel = xmlObject:getValue(".physics#suspTravel", 0.01)
	local v17_ = xmlObject:getValue(".physics#initialCompression")
	if v17_ == nil then
		self.deltaY = xmlObject:getValue(".physics#deltaY", 0)
	else
		self.deltaY = (1 - v17_ * 0.01) * self.suspTravel
	end
	self.deltaYOriginal = self.deltaY
	self.spring = xmlObject:getValue(".physics#spring", 0) * Vehicle.SPRING_SCALE
	self.brakeFactor = xmlObject:getValue(".physics#brakeFactor", 1)
	self.autoHoldBrakeFactor = xmlObject:getValue(".physics#autoHoldBrakeFactor", self.brakeFactor)
	self.dampingMultiplier = 1
	self.springMultiplier = 1
	self.damperCompressionLowSpeed = xmlObject:getValue(".physics#damperCompressionLowSpeed")
	self.damperRelaxationLowSpeed = xmlObject:getValue(".physics#damperRelaxationLowSpeed")
	if self.damperRelaxationLowSpeed == nil then
		self.damperRelaxationLowSpeed = xmlObject:getValue(".physics#damper", self.damperCompressionLowSpeed or 0)
	end
	self.damperRelaxationHighSpeed = xmlObject:getValue(".physics#damperRelaxationHighSpeed", self.damperRelaxationLowSpeed * 0.7)
	if self.damperCompressionLowSpeed == nil then
		self.damperCompressionLowSpeed = self.damperRelaxationLowSpeed * 0.9
	end
	self.damperCompressionHighSpeed = xmlObject:getValue(".physics#damperCompressionHighSpeed", self.damperCompressionLowSpeed * 0.2)
	self.damperCompressionLowSpeedThreshold = xmlObject:getValue(".physics#damperCompressionLowSpeedThreshold", 0.1016)
	self.damperRelaxationLowSpeedThreshold = xmlObject:getValue(".physics#damperRelaxationLowSpeedThreshold", 0.1524)
	self.forcePointRatio = xmlObject:getValue(".physics#forcePointRatio", 0)
	if self.forcePointRatio < 0 or self.forcePointRatio > 1 then
		xmlObject:xmlWarning(".physics#forcePointRatio", "Invalid value for \'forcePointRatio\'. Must be between 0 and 1. Defaulting to 0!")
		self.forcePointRatio = 0
	end
	self.driveMode = xmlObject:getValue(".physics#driveMode", 0)
	self.isSynchronized = xmlObject:getValue(".physics#isSynchronized", true)
	self.tipOcclusionAreaGroupId = xmlObject:getValue(".physics#tipOcclusionAreaGroupId")
	self.useReprDirection = xmlObject:getValue(".physics#useReprDirection", false)
	self.useDriveNodeDirection = xmlObject:getValue(".physics#useDriveNodeDirection", false)
	self.rotationDamping = xmlObject:getValue(".physics#rotationDamping", self.mass * 0.035)
	local v18_ = xmlObject:getValue(".physics#tireType", "mud")
	self.tireType = WheelsUtil.getTireType(v18_)
	if self.tireType == nil then
		xmlObject:xmlWarning(".physics#tireType", "Failed to find tire type \'%s\'. Defaulting to \'mud\'!", v18_)
		self.tireType = WheelsUtil.getTireType("mud")
	end
	self.fieldDirtMultiplier = xmlObject:getValue(".physics#fieldDirtMultiplier", 75)
	self.streetDirtMultiplier = xmlObject:getValue(".physics#streetDirtMultiplier", -150)
	self.waterWetnessFactor = xmlObject:getValue(".physics#waterWetnessFactor", 20)
	self.minDirtPercentage = xmlObject:getValue(".physics#minDirtPercentage", 0.35)
	self.maxDirtOffset = xmlObject:getValue(".physics#maxDirtOffset", 0.5)
	self.dirtColorChangeSpeed = 1 / (xmlObject:getValue(".physics#dirtColorChangeSpeed", 20) * 1000)
	self.versatileYRot = xmlObject:getValue(".physics#versatileYRot", false)
	self.versatileYRotSpring = xmlObject:getValue(".physics#versatileYRotSpring")
	self.versatileYRotDamping = xmlObject:getValue(".physics#versatileYRotDamping")
	self.versatileYRotFriction = xmlObject:getValue(".physics#versatileYRotFriction", "0.0000015 0.0000010", true)
	self.versatileYRotSpeed = 0
	self.forceVersatility = xmlObject:getValue(".physics#forceVersatility", false)
	local v19_ = xmlObject:getValue(".physics#supportsWheelSink", true)
	if v19_ then
		v19_ = self.vehicle.isServer
	end
	self.supportsWheelSink = v19_
	self.configCollisionMask = xmlObject:getValue(".physics#collisionMask")
	if not (Platform.gameplay.wheelTerrainDisplacement and self.supportsWheelSink) then
		local v20_ = self.configCollisionMask or WheelPhysics.COLLISION_MASK
		local v21_ = CollisionFlag.TERRAIN_DISPLACEMENT
		local v22_ = bit32.bnot(v21_)
		self.collisionMask = bit32.band(v20_, v22_)
	end
	self.extraSinkSupported = xmlObject:getValue(".physics.extraSink#supported", false)
	self.extraSinkMaxValue = xmlObject:getValue(".physics.extraSink#maxValue", self.radius * 0.2)
	self.rotSpeed = xmlObject:getValue(".physics#rotSpeed", 0)
	self.rotSpeedNeg = xmlObject:getValue(".physics#rotSpeedNeg", 0)
	self.rotMax = xmlObject:getValue(".physics#rotMax", 0)
	self.rotMin = xmlObject:getValue(".physics#rotMin", 0)
	self.invertRotLimit = xmlObject:getValue(".physics#invertRotLimit", false)
	self.rotSpeedLimit = xmlObject:getValue(".physics#rotSpeedLimit")
	local v23_ = xmlObject:getValue(".physics#maxInnerSpacing")
	if v23_ ~= nil then
		local v24_ = self.width * 0.5 - v23_
		if v24_ > 0 then
			local v25_, v26_, v27_ = localToLocal(self.wheel.driveNode, getParent(self.wheel.driveNode), self.wheel.isLeft and v24_ and v24_ or -v24_, 0, 0)
			setTranslation(self.wheel.driveNode, v25_, v26_, v27_)
		end
	end
	local v28_, v29_, v30_ = localToLocal(self.wheel.driveNode, self.wheel.node, 0, 0, 0)
	self.positionX = v28_
	self.positionY = v29_
	self.positionZ = v30_
	if self.useReprDirection then
		local v31_, v32_, v33_ = localDirectionToLocal(self.wheel.repr, self.wheel.node, 0, -1, 0)
		self.directionX = v31_
		self.directionY = v32_
		self.directionZ = v33_
		local v34_, v35_, v36_ = localDirectionToLocal(self.wheel.repr, self.wheel.node, 1, 0, 0)
		self.axleX = v34_
		self.axleY = v35_
		self.axleZ = v36_
	elseif self.useDriveNodeDirection then
		local v37_, v38_, v39_ = localDirectionToLocal(self.wheel.driveNodeDirectionNode, self.wheel.node, 0, -1, 0)
		self.directionX = v37_
		self.directionY = v38_
		self.directionZ = v39_
		local v40_, v41_, v42_ = localDirectionToLocal(self.wheel.driveNodeDirectionNode, self.wheel.node, 1, 0, 0)
		self.axleX = v40_
		self.axleY = v41_
		self.axleZ = v42_
	else
		self.directionX = 0
		self.directionY = -1
		self.directionZ = 0
		self.axleX = 1
		self.axleY = 0
		self.axleZ = 0
	end
	self.steeringCenterOffsetX = 0
	self.steeringCenterOffsetY = 0
	self.steeringCenterOffsetZ = 0
	if self.wheel.repr ~= self.wheel.driveNode then
		local v43_, v44_, v45_ = localToLocal(self.wheel.driveNode, self.wheel.repr, 0, 0, 0)
		self.steeringCenterOffsetX = v43_
		self.steeringCenterOffsetY = v44_
		self.steeringCenterOffsetZ = v45_
		self.steeringCenterOffsetX = -self.steeringCenterOffsetX
		self.steeringCenterOffsetY = -self.steeringCenterOffsetY
		self.steeringCenterOffsetZ = -self.steeringCenterOffsetZ
	end
	return true
end

function WheelPhysics:loadAdditionalWheel(xmlObject)
	self.mass = self.mass + xmlObject:getValue(".physics#mass", 0)
	self.maxLatStiffness = self.maxLatStiffness + xmlObject:getValue(".physics#maxLatStiffness", 0)
	self.maxLongStiffness = self.maxLongStiffness + xmlObject:getValue(".physics#maxLongStiffness", 0)
end

-- Local values: positionY, vehicleNode, additionalMass
function WheelPhysics:finalize()
	local v49_ = self.positionY + self.deltaY
	self.netInfo = {}
	self.netInfo.xDrive = 0
	self.netInfo.xDriveDiff = 0
	self.netInfo.xDriveSpeed = 0
	self.netInfo.xDriveLastRaw = 0
	self.netInfo.x = self.positionX
	self.netInfo.y = v49_
	self.netInfo.z = self.positionZ
	self.netInfo.suspensionLength = self.deltaY
	self.netInfo.lastSpeedSmoothed = 0
	self.netInfo.slip = 0
	self.netInfo.sync = {
		["yMin"] = -5,
		["yRange"] = 10
	}
	self.netInfo.yMin = v49_ - 1.2 * self.suspTravel
	local v50_ = self.vehicle.vehicleNodes[self.wheel.node]
	if v50_ ~= nil and (v50_.component ~= nil and v50_.component.motorized == nil) then
		v50_.component.motorized = true
	end
	local v51_ = self.wheel:getMass() - self.baseMass
	self.restLoad = self.restLoad + v51_
	self.maxLatStiffness = self.maxLatStiffness * self.restLoad
	self.maxLatStiffnessLoad = self.maxLatStiffnessLoad * self.restLoad
	self.networkInterpolators = {}
	self.networkInterpolators.xDriveDiff = InterpolatorValue.new(0)
	self.networkInterpolators.position = InterpolatorPosition.new(self.netInfo.x, self.netInfo.y, self.netInfo.z)
	self.networkInterpolators.suspensionLength = InterpolatorValue.new(self.netInfo.suspensionLength)
end

function WheelPhysics:postLoad() end

-- Local values: xDriveDirection, xDriveDiff, y, suspLength, yRot
function WheelPhysics:readStream(streamId, updateInterpolation)
	local v55_ = streamReadBool(streamId) and 1 or -1
	local v56_ = (1 - (1 - streamReadUIntN(streamId, WheelPhysics.X_DRIVE_NUM_BITS) / WheelPhysics.X_DRIVE_MAX_VALUE) ^ 0.25) * WheelPhysics.X_DRIVE_MAX_REAL_VALUE * v55_
	if updateInterpolation then
		self.networkInterpolators.xDriveDiff:setValue(v56_)
	else
		self.networkInterpolators.xDriveDiff:setTargetValue(v56_)
	end
	local v57_ = streamReadUIntN(streamId, 8) / 255 * self.netInfo.sync.yRange + self.netInfo.sync.yMin
	if updateInterpolation then
		self.netInfo.y = v57_
		self.networkInterpolators.position:setPosition(self.netInfo.x, v57_, self.netInfo.z)
	else
		self.networkInterpolators.position:setTargetPosition(self.netInfo.x, v57_, self.netInfo.z)
	end
	local v58_ = streamReadUIntN(streamId, 7)
	if updateInterpolation then
		self.netInfo.suspensionLength = v58_ / 100
		self.networkInterpolators.suspensionLength:setValue(v58_ / 100)
	else
		self.networkInterpolators.suspensionLength:setTargetValue(v58_ / 100)
	end
	if self.wheel.syncContactState then
		self.contact = streamReadUIntN(streamId, 2) + 1
		self.lastContactObjectAllowsTireTracks = streamReadBool(streamId)
	end
	if self.versatileYRot then
		self.steeringAngle = streamReadUIntN(streamId, 9) / 511 * 3.141592653589793 * 2
	end
end

-- Local values: xDriveDiff, yRot
function WheelPhysics:writeStream(streamId)
	local v61_ = self.netInfo.xDriveDiff
	local v62_ = math.abs(v61_) / WheelPhysics.X_DRIVE_MAX_REAL_VALUE
	local v63_ = math.clamp(v62_, 0, 1)
	streamWriteBool(streamId, self.netInfo.xDriveDiff >= 0)
	local v64_ = 1 - (1 - v63_) ^ 4
	streamWriteUIntN(streamId, v64_ * WheelPhysics.X_DRIVE_MAX_VALUE, WheelPhysics.X_DRIVE_NUM_BITS)
	local v65_ = streamWriteUIntN
	local v66_ = (self.netInfo.y - self.netInfo.sync.yMin) / self.netInfo.sync.yRange * 255
	local v67_ = math.floor(v66_)
	v65_(streamId, math.clamp(v67_, 0, 255), 8)
	local v68_ = streamWriteUIntN
	local v69_ = self.netInfo.suspensionLength * 100
	v68_(streamId, math.clamp(v69_, 0, 128), 7)
	if self.wheel.syncContactState then
		streamWriteUIntN(streamId, self.contact - 1, 2)
		streamWriteBool(streamId, self.lastContactObjectAllowsTireTracks)
	end
	if self.versatileYRot then
		local v70_ = self.steeringAngle % 6.283185307179586
		local v71_ = streamWriteUIntN
		local v72_ = v70_ / 6.283185307179586 * 511
		local v73_ = math.floor(v72_)
		v71_(streamId, math.clamp(v73_, 0, 511), 9)
	end
end

-- Local values: nx, ny, nz, cx, cy, cz, wx, wy, wz, mission, contactX, contactY, contactZ, _, contactObject, _, heightTypeIndex, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, densityType, densityHeightBits, numChannels, heightType
function WheelPhysics:updateContact()
	local v75_ = self.netInfo.x
	local v76_ = self.netInfo.y
	local v77_ = self.netInfo.z
	local v78_, v79_, v80_ = localToWorld(self.wheel.node, v75_, v76_, v77_)
	raycastClosestAsync(v78_, v79_, v80_, 0, -1, 0, self.radius + 0.25, "waterRaycastCallback", self, CollisionFlag.WATER)
	local v81_, v82_, v83_ = localToWorld(self.wheel.node, v75_, v76_ - self.radius, v77_)
	local v84_ = g_currentMission
	if g_updateLoopIndex - self.wheelShapeCreationFrameIndex > 2 then
		self.wheelShapeCreated = true
		local v85_, v86_, v87_, _ = getWheelShapeContactPoint(self.wheel.node, self.wheelShape)
		self.hasGroundContact = v85_ ~= nil
		if self.hasGroundContact then
			self.lastContactX = v85_
			self.lastContactY = v86_
			self.lastContactZ = v87_
		end
		local v88_, _ = getWheelShapeContactObject(self.wheel.node, self.wheelShape)
		if v88_ == 0 then
			self.contact = WheelContactType.NONE
			self.lastContactObjectAllowsTireTracks = false
		elseif getDensityMapHeightTypeAtWorldPos(g_densityMapHeightManager.terrainDetailHeightUpdater, v81_, v82_, v83_, 0) == 0 then
			if v88_ == g_terrainNode then
				self.contact = WheelContactType.GROUND
				self.lastContactObjectAllowsTireTracks = true
			elseif self.hasGroundContact then
				self.contact = WheelContactType.OBJECT
				local v89_ = entityExists(v88_)
				if v89_ then
					if getRigidBodyType(v88_) == RigidBodyType.STATIC then
						v89_ = getUserAttribute(v88_, "noTireTracks") ~= true
					else
						v89_ = false
					end
				end
				self.lastContactObjectAllowsTireTracks = v89_
			else
				self.contact = WheelContactType.NONE
				self.lastContactObjectAllowsTireTracks = false
			end
		else
			self.contact = WheelContactType.GROUND_HEIGHT
			self.lastContactObjectAllowsTireTracks = true
		end
	end
	if self.contact == WheelContactType.GROUND then
		local v90_, v91_, v92_ = v84_.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		self.densityBits = getDensityAtWorldPos(v90_, v81_, v82_, v83_)
		local v93_ = self.densityBits
		local v94_ = bit32.rshift(v93_, v91_)
		local v95_ = 2 ^ v92_ - 1
		local v96_ = bit32.band(v94_, v95_)
		self.densityType = FieldGroundType.getTypeByValue(v96_)
	else
		self.densityBits = 0
		self.densityType = FieldGroundType.NONE
	end
	if self.contact == WheelContactType.GROUND_HEIGHT then
		local v97_ = getDensityAtWorldPos(v84_.terrainDetailHeightId, v81_, v82_, v83_)
		local v98_ = 2 ^ g_densityMapHeightManager.heightTypeNumChannels - 1
		self.hasSnowContact = bit32.band(v97_, v98_) == v84_.snowSystem.snowHeightTypeIndex
	else
		self.hasSnowContact = false
	end
end

-- Local values: mission, nx, ny, nz, wx, wy, wz, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, densityType, densityHeightBits, numChannels, heightType
function WheelPhysics:updateContactClient()
	local v100_ = g_currentMission
	local v101_ = self.netInfo.x
	local v102_ = self.netInfo.y
	local v103_ = self.netInfo.z
	local v104_, v105_, v106_ = localToWorld(self.wheel.node, v101_, v102_ - self.radius, v103_)
	if self.contact == WheelContactType.GROUND then
		local v107_, v108_, v109_ = v100_.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		self.densityBits = getDensityAtWorldPos(v107_, v104_, v105_, v106_)
		local v110_ = self.densityBits
		local v111_ = bit32.rshift(v110_, v108_)
		local v112_ = 2 ^ v109_ - 1
		local v113_ = bit32.band(v111_, v112_)
		self.densityType = FieldGroundType.getTypeByValue(v113_)
	else
		self.densityBits = 0
		self.densityType = FieldGroundType.NONE
	end
	if self.contact == WheelContactType.GROUND_HEIGHT then
		local v114_ = getDensityAtWorldPos(v100_.terrainDetailHeightId, v104_, v105_, v106_)
		local v115_ = 2 ^ g_densityMapHeightManager.heightTypeNumChannels - 1
		self.hasSnowContact = bit32.band(v114_, v115_) == v100_.snowSystem.snowHeightTypeIndex
	else
		self.hasSnowContact = false
	end
end

-- Local values: sinkTarget, lastSpeed, interpolationFactor, deltaY
function WheelPhysics:updateSink(dt, groundWetness)
	if self.wheelShape ~= 0 then
		local v118_ = self.sinkTarget
		local v119_ = self.vehicle:getLastSpeed()
		local v120_ = 1
		if self.contact == WheelContactType.NONE or v119_ <= 0.3 then
			if self.contact == WheelContactType.NONE then
				v118_ = 0
				v119_ = 10
				v120_ = 0.075
			end
		else
			local v121_ = WheelPhysics.MAX_SINK[self.densityType] or 0
			if self.hasWaterContact and v121_ ~= 0 then
				local v122_ = WheelPhysics.WATER_SINK
				v121_ = math.max(v121_, v122_)
			end
			local v123_ = self.extraSinkMaxValue
			v118_ = math.min(v121_, v123_)
		end
		if self.sinkTarget < v118_ then
			local v124_ = self.sinkTarget
			local v125_ = v119_ - 0.2
			local v126_ = math.max(0, v125_)
			local v127_ = v124_ + 0.05 * math.min(30, v126_) * (dt / 1000) * v120_
			self.sinkTarget = math.min(v118_, v127_)
		elseif v118_ < self.sinkTarget then
			local v128_ = self.sinkTarget
			local v129_ = v119_ - 0.2
			local v130_ = math.max(0, v129_)
			local v131_ = v128_ - 0.05 * math.min(30, v130_) * (dt / 1000) * v120_
			self.sinkTarget = math.max(v118_, v131_)
		end
		local v132_ = self.sink - self.sinkTarget
		if math.abs(v132_) > 0.001 then
			self.sink = self.sinkTarget
			local v133_ = self.deltaYOriginal + self.sink
			if v133_ ~= self.deltaY then
				self.deltaY = v133_
				self.isPositionDirty = true
			end
		end
	end
end

-- Local values: isOnField, snowScale, groundType, coeff
function WheelPhysics:updateFriction(dt, groundWetness)
	local v136_ = self.densityType ~= FieldGroundType.NONE
	local v137_
	if self.hasSnowContact then
		groundWetness = 0
		v137_ = 1
	else
		v137_ = 0
	end
	local v138_ = WheelsUtil.getGroundType(v136_, self.contact ~= WheelContactType.GROUND, self.groundDepth)
	local v139_ = WheelsUtil.getTireFriction(self.tireType, v138_, groundWetness, v137_)
	if self.vehicle:getLastSpeed() > 0.2 and v139_ ~= self.tireGroundFrictionCoeff then
		self.tireGroundFrictionCoeff = v139_
		self.isFrictionDirty = true
	end
end

-- Local values: positionX, positionY, positionZ, spring, damperCompressionLowSpeed, damperCompressionHighSpeed, damperRelaxationLowSpeed, damperRelaxationHighSpeed, collisionGroup, collisionMask, forcePointY, steeringX, steeringY, steeringZ, direction
function WheelPhysics:updateBase()
	if self.vehicle.isServer and self.vehicle.isAddedToPhysics then
		local v141_ = self.positionX - self.directionX * self.deltaY
		local v142_ = self.positionY - self.directionY * self.deltaY
		local v143_ = self.positionZ - self.directionZ * self.deltaY
		if self.wheelShape == 0 then
			self.wheelShapeCreationFrameIndex = g_updateLoopIndex
			self.wheelShapeCreated = false
		end
		local v144_ = self.spring * self.springMultiplier
		local v145_ = self.damperCompressionLowSpeed * self.dampingMultiplier
		local v146_ = self.damperCompressionHighSpeed * self.dampingMultiplier
		local v147_ = self.damperRelaxationLowSpeed * self.dampingMultiplier
		local v148_ = self.damperRelaxationHighSpeed * self.dampingMultiplier
		local v149_ = WheelPhysics.COLLISION_GROUP
		local v150_ = self.collisionMask or (self.configCollisionMask or WheelPhysics.COLLISION_MASK)
		self.wheelShape = createWheelShape(self.wheel.node, v141_, v142_, v143_, self.radius, self.suspTravel, v144_, v145_, v146_, self.damperCompressionLowSpeedThreshold, v147_, v148_, self.damperRelaxationLowSpeedThreshold, self.wheel:getMass(), v149_, v150_, self.wheelShape)
		local v151_ = v142_ - self.radius * self.forcePointRatio
		local v152_, v153_, v154_ = localToLocal(getParent(self.wheel.repr), self.wheel.node, self.wheel.startPositionX, self.wheel.startPositionY + self.deltaY, self.wheel.startPositionZ)
		setWheelShapeForcePoint(self.wheel.node, self.wheelShape, self.positionX, v151_, v143_)
		setWheelShapeSteeringCenter(self.wheel.node, self.wheelShape, v152_, v153_, v154_)
		local v155_ = self.torqueDirection
		setWheelShapeDirection(self.wheel.node, self.wheelShape, self.directionX, self.directionY, self.directionZ, self.axleX * v155_, self.axleY * v155_, self.axleZ * v155_)
		setWheelShapeWidth(self.wheel.node, self.wheelShape, self.wheelShapeWidth, self.wheelShapeWidthOffset)
		setWheelShapeTerrainDisplacement(self.wheel.node, self.wheelShape, self.displacementAllowed and (self.displacementScale or 0) or 0)
		self.isPositionDirty = false
	end
end

function WheelPhysics:updateShapePosition()
	local v157_, v158_, v159_ = localToLocal(getParent(self.wheel.repr), self.wheel.node, self.wheel.startPositionX - self.steeringCenterOffsetX, self.wheel.startPositionY - self.steeringCenterOffsetY, self.wheel.startPositionZ - self.steeringCenterOffsetZ)
	self.positionX = v157_
	self.positionY = v158_
	self.positionZ = v159_
	if self.useReprDirection then
		local v160_, v161_, v162_ = localDirectionToLocal(self.wheel.repr, self.wheel.node, 0, -1, 0)
		self.directionX = v160_
		self.directionY = v161_
		self.directionZ = v162_
		local v163_, v164_, v165_ = localDirectionToLocal(self.wheel.repr, self.wheel.node, 1, 0, 0)
		self.axleX = v163_
		self.axleY = v164_
		self.axleZ = v165_
	elseif self.useDriveNodeDirection then
		local v166_, v167_, v168_ = localDirectionToLocal(self.wheel.driveNodeDirectionNode, self.wheel.node, 0, -1, 0)
		self.directionX = v166_
		self.directionY = v167_
		self.directionZ = v168_
		local v169_, v170_, v171_ = localDirectionToLocal(self.wheel.driveNodeDirectionNode, self.wheel.node, 1, 0, 0)
		self.axleX = v169_
		self.axleY = v170_
		self.axleZ = v171_
	end
	self.isPositionDirty = true
end

function WheelPhysics:updateTireFriction()
	if self.vehicle.isServer and self.vehicle.isAddedToPhysics then
		setWheelShapeTireFriction(self.wheel.node, self.wheelShape, self.maxLongStiffness, self.maxLatStiffness, self.maxLatStiffnessLoad, self.frictionScale * self.tireGroundFrictionCoeff)
		self.isFrictionDirty = false
	end
end

function WheelPhysics:updatePhysics(brakeForce, torque)
	if self.vehicle.isServer and self.vehicle.isAddedToPhysics then
		setWheelShapeProps(self.wheel.node, self.wheelShape, torque or self.torque, (brakeForce or 0) * self.brakeFactor, self.steeringAngle, self.rotationDamping)
		setWheelShapeAutoHoldBrakeForce(self.wheel.node, self.wheelShape, (brakeForce or 0) * self.autoHoldBrakeFactor)
	end
end

-- Local values: x, y, z, xDrive, suspensionLength
function WheelPhysics:updateNetInfo(dt)
	if self.updateWheel then
		if g_physicsDtNonInterpolated ~= 0 then
			local v177_, v178_, v179_, v180_, v181_ = getWheelShapePosition(self.wheel.node, self.wheelShape)
			if self.torqueDirection < 0 then
				self.netInfo.xDrive = self.netInfo.xDrive - (v180_ - self.netInfo.xDriveLastRaw)
			else
				self.netInfo.xDrive = self.netInfo.xDrive + (v180_ - self.netInfo.xDriveLastRaw)
			end
			self.netInfo.xDriveLastRaw = v180_
			if self.dirtyFlag ~= nil and (self.netInfo.x ~= v177_ or self.netInfo.z ~= v179_) then
				self.vehicle:raiseDirtyFlags(self.dirtyFlag)
			end
			self.netInfo.x = v177_
			self.netInfo.y = v178_
			self.netInfo.z = v179_
			self.netInfo.suspensionLength = v181_
			self.netInfo.xDriveDiff = 0
			self:updateXDriveSpeed(g_physicsDtNonInterpolated)
		end
	else
		self.updateWheel = true
		return
	end
end

-- Local values: steeringAngle, rotatedTime, steeringAxleAngle
function WheelPhysics:updateSteeringAngle(dt)
	local v184_ = self.steeringAngle
	local v185_ = self.vehicle.rotatedTime
	if self.wheel.steering.steeringAxleScale == nil or self.wheel.steering.steeringAxleScale == 0 then
		if self.versatileYRot and self.vehicle:getIsVersatileYRotActive(self.wheel) then
			if self.vehicle.isServer then
				v184_ = self:getVersatileYRotation(dt)
			end
		elseif self.rotSpeed ~= 0 and (self.rotMax ~= nil and self.rotMin ~= nil) or self.wheel.forceSteeringAngleUpdate then
			if v185_ > 0 or self.rotSpeedNeg == nil then
				v184_ = v185_ * self.rotSpeed
			else
				v184_ = v185_ * self.rotSpeedNeg
			end
			if self.rotMax < v184_ then
				v184_ = self.rotMax
			elseif v184_ < self.rotMin then
				v184_ = self.rotMin
			end
			if self.vehicle.customSteeringAngleFunction then
				v184_ = self.vehicle:updateSteeringAngle(self.wheel, dt, v184_)
			end
		end
	else
		local v186_ = (self.vehicle.spec_attachable == nil and 0 or self.vehicle.spec_attachable.steeringAxleAngle) * self.wheel.steering.steeringAxleScale
		local v187_ = self.wheel.steering.steeringAxleRotMin
		local v188_ = self.wheel.steering.steeringAxleRotMax
		v184_ = math.clamp(v186_, v187_, v188_)
	end
	self.steeringAngle = v184_
end

function WheelPhysics:addToPhysics(brakeForce)
	self.netInfo.xDriveLastRaw = 0
	self.updateWheel = false
	self:updateBase()
	self:updateTireFriction()
	self:updatePhysics(brakeForce, 0)
end

function WheelPhysics:removeFromPhysics()
	self.wheelShape = 0
	self.wheelShapeCreationFrameIndex = math.huge
	self.wheelShapeCreated = false
end

function WheelPhysics:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
	self.rotMin = rotMin
	self.rotMax = rotMax
	if self.invertRotLimit then
		inverted = not inverted
	end
	local v198_
	if inverted then
		v198_ = -rotSpeedNeg
		rotSpeedNeg = -rotSpeed
	else
		v198_ = rotSpeed
	end
	self.rotSpeed = v198_
	self.rotSpeedNeg = rotSpeedNeg
end

function WheelPhysics:setWheelShapeWidth(width, offset)
	local v202_ = width or self.wheelShapeWidth
	local v203_ = offset or self.wheelShapeWidthOffset
	self.wheelShapeWidth = v202_
	self.wheelShapeWidthOffset = v203_
	self.isPositionDirty = true
end

function WheelPhysics:setTorqueDirection(torqueDirection)
	local v206_ = torqueDirection >= 0 and 1 or -1
	if v206_ ~= self.torqueDirection then
		self.torqueDirection = v206_
		self:updateBase()
	end
end

function WheelPhysics:setDisplacementAllowed(displacementAllowed)
	self.displacementAllowed = displacementAllowed
	if self.vehicle.isServer and self.vehicle.isAddedToPhysics then
		setWheelShapeTerrainDisplacement(self.wheel.node, self.wheelShape, self.displacementAllowed and self.displacementScale or 0)
	end
end

-- Local values: oldCollisionMask
function WheelPhysics:setDisplacementCollisionEnabled(displacementCollisionEnabled)
	self.displacementCollisionEnabled = displacementCollisionEnabled
	local v211_ = self.collisionMask
	if Platform.gameplay.wheelTerrainDisplacement and (self.supportsWheelSink and self.displacementCollisionEnabled) then
		self.collisionMask = nil
	else
		local v212_ = self.configCollisionMask or WheelPhysics.COLLISION_MASK
		local v213_ = CollisionFlag.TERRAIN_DISPLACEMENT
		local v214_ = bit32.bnot(v213_)
		self.collisionMask = bit32.band(v212_, v214_)
	end
	if self.collisionMask ~= v211_ then
		self:updateBase()
	end
end

function WheelPhysics:setSuspensionMultipliers(springMultiplier, dampingMultiplier)
	self.springMultiplier = springMultiplier or 1
	self.dampingMultiplier = dampingMultiplier or 1
	self.isPositionDirty = true
end

-- Local values: steeringAngle
function WheelPhysics:getVisualInfo()
	local v219_ = self.showSteeringAngle == false and 0 or self.steeringAngle * self.steeringAngleFactorInv
	return self.netInfo.x, self.netInfo.y, self.netInfo.z, self.netInfo.xDrive, self.netInfo.suspensionLength - self.deltaYOriginal, v219_
end

-- Local values: brakeForce
function WheelPhysics:serverUpdate(dt, currentUpdateIndex, groundWetness)
	if self.vehicle.isActive then
		if currentUpdateIndex == self.wheel.updateIndex then
			self:updateContact()
		end
		if self.extraSinkSupported then
			self:updateSink(dt, groundWetness)
		end
		if self.vehicle.isServer then
			self:updateFriction(dt, groundWetness)
		end
		self:updatePhysics(self.wheel.brakePedal <= 0 and 0 or self.vehicle:getBrakeForce() * self.wheel.brakePedal)
		self:updateSteeringAngle(dt)
	end
	self:updateNetInfo(dt)
end

function WheelPhysics:clientUpdate(dt, currentUpdateIndex, groundWetness)
	if self.vehicle.isActive and currentUpdateIndex == self.wheel.updateIndex then
		self:updateContactClient()
	end
end

-- Local values: dir, wx, wy, wz, targetDirtAmount, targetAlpha, isOnField, colorBlendWithTerrain, r, g, b, depth, t, maxTrackLength, speedFactor, i
function WheelPhysics:updateTick(dt, groundWetness, currentUpdateDistance)
	if self.rotSpeedLimit ~= nil then
		local v230_ = self:getLastSpeed() <= self.rotSpeedLimit and 1 or -1
		local v231_ = self.currentRotSpeedAlpha + v230_ * (dt / 1000)
		self.currentRotSpeedAlpha = math.clamp(v231_, 0, 1)
		self.rotSpeed = self.rotSpeedDefault * self.currentRotSpeedAlpha
		self.rotSpeedNeg = self.rotSpeedNegDefault * self.currentRotSpeedAlpha
	end
	if currentUpdateDistance < TireTracks.MAX_CREATION_DISTANCE or currentUpdateDistance < WheelEffects.MAX_UPDATE_DISTANCE then
		self.hasSoilContact = false
		local v232_, v233_, v234_ = getWorldTranslation(self.wheel.driveNode)
		local v235_ = 0
		local v236_ = 0
		if self.contact == WheelContactType.GROUND then
			local v237_ = 1
			local v238_, v239_
			if self.densityType ~= FieldGroundType.NONE then
				local v240_, v241_, v242_
				v240_, v241_, v242_, v238_ = g_currentMission.fieldGroundSystem:getFieldGroundTyreTrackColor(self.densityBits)
				v239_ = 1
				v235_ = 1
				if self.densityType == FieldGroundType.GRASS then
					v235_ = 0.7
				elseif self.densityType == FieldGroundType.GRASS_CUT then
					v235_ = 0.6
				else
					self.hasSoilContact = true
				end
				self.fieldGroundColor[1] = v240_
				self.fieldGroundColor[2] = v241_
				self.fieldGroundColor[3] = v242_
				v237_ = 0.75
			else
				local v243_, v244_, v245_
				v243_, v244_, v245_, v238_, v239_ = getTerrainAttributesAtWorldPos(g_terrainNode, v232_, v233_, v234_, true, true, true, true, false)
				self.groundColor[1] = v243_
				self.groundColor[2] = v244_
				self.groundColor[3] = v245_
				if v238_ > 0 then
					v236_ = 0.5
				end
			end
			self.groundDepth = v238_
			self.colorBlendWithTerrain = v237_
			self.lastTerrainAttribute = v239_
		elseif self.contact == WheelContactType.GROUND_HEIGHT then
			self.groundDepth = 1
			self.colorBlendWithTerrain = 0
			v236_ = 1
		elseif self.contact == WheelContactType.OBJECT then
			self.groundDepth = 0
		end
		if v235_ ~= self.dirtAmount then
			if v235_ < self.dirtAmount then
				local v246_ = 30 * (1 + groundWetness)
				local v247_ = self.vehicle:getLastSpeed()
				local v248_ = v246_ * (2 - math.min(v247_, 20) / 20)
				local v249_ = self.dirtAmount - self.vehicle.lastMovedDistance / v248_
				self.dirtAmount = math.max(v249_, v235_)
			else
				local v250_ = self.dirtAmount + self.vehicle.lastMovedDistance
				self.dirtAmount = math.min(v250_, v235_)
			end
		end
		if v236_ ~= self.trackAlpha then
			if self.trackAlpha < v236_ then
				local v251_ = self.trackAlpha + self.vehicle.lastMovedDistance * 2
				self.trackAlpha = math.min(v251_, v236_)
			else
				local v252_ = self.trackAlpha - self.vehicle.lastMovedDistance * 2
				self.trackAlpha = math.max(v252_, v236_)
			end
		end
		if self.groundDepth > 0 then
			for v253_ = 1, 3 do
				self.trackColor[v253_] = self.fieldGroundColor[v253_] * self.dirtAmount + self.groundColor[v253_] * (1 - self.dirtAmount)
			end
			return
		end
		self.trackColor[1] = self.fieldGroundColor[1]
		self.trackColor[2] = self.fieldGroundColor[2]
		self.trackColor[3] = self.fieldGroundColor[3]
	end
end

function WheelPhysics:postUpdate(dt)
	if self.isPositionDirty then
		self:updateBase()
	end
	if self.isFrictionDirty then
		self:updateTireFriction()
	end
end

-- Local values: xDriveDiff
function WheelPhysics:updateInterpolation(dt, interpolationAlpha)
	local v258_ = self.netInfo
	local v259_ = self.netInfo
	local v260_ = self.netInfo
	local v261_, v262_, v263_ = self.networkInterpolators.position:getInterpolatedValues(interpolationAlpha)
	v258_.x = v261_
	v259_.y = v262_
	v260_.z = v263_
	self.netInfo.suspensionLength = self.networkInterpolators.suspensionLength:getInterpolatedValue(interpolationAlpha)
	local v264_ = self.networkInterpolators.xDriveDiff:getInterpolatedValue(interpolationAlpha)
	self.netInfo.xDrive = (self.netInfo.xDrive + v264_ * dt) % 6.283185307179586
	self:updateXDriveSpeed(dt)
	self:updateSteeringAngle(dt)
end

-- Local values: xDrive, xDriveDiff, speed
function WheelPhysics:updateXDriveSpeed(dt)
	local v267_ = self.netInfo.xDrive
	if self.netInfo.xDriveBefore == nil then
		self.netInfo.xDriveBefore = v267_
	end
	local v268_ = v267_ - self.netInfo.xDriveBefore
	if v268_ > 3.141592653589793 then
		self.netInfo.xDriveBefore = self.netInfo.xDriveBefore + 6.283185307179586
	elseif v268_ < -3.141592653589793 then
		self.netInfo.xDriveBefore = self.netInfo.xDriveBefore - 6.283185307179586
	end
	self.netInfo.xDriveDiff = (v267_ - self.netInfo.xDriveBefore) / dt
	self.netInfo.xDriveSpeed = self.netInfo.xDriveDiff * 1000
	self.netInfo.xDriveBefore = v267_
	local v269_ = MathUtil.rpmToMps(self.netInfo.xDriveSpeed / 6.283185 * 60, self.radius)
	self.netInfo.lastSpeedSmoothed = self.netInfo.lastSpeedSmoothed * 0.9 + v269_ * 0.1
	local v270_ = self.netInfo
	local v271_ = self.netInfo.lastSpeedSmoothed
	local v272_ = self.vehicle.lastSpeedSmoothed
	local v273_ = v271_ / math.max(v272_, 1e-8)
	v270_.slip = math.clamp(v273_, 1, 2) - 1
end

function WheelPhysics:getGroundAttributes()
	local v275_ = self.trackColor[1]
	local v276_ = self.trackColor[2]
	local v277_ = self.trackColor[3]
	local v278_ = self.groundDepth
	local v279_ = self.lastTerrainAttribute
	local v280_ = self.trackAlpha
	local v281_ = self.dirtAmount
	return v275_, v276_, v277_, v278_, v279_, math.max(v280_, v281_), self.colorBlendWithTerrain
end

-- Local values: isOnField
function WheelPhysics:getIsOnField()
	local v283_ = self.hasSnowContact
	return self.densityType ~= FieldGroundType.NONE and (self.densityType ~= FieldGroundType.GRASS and self.densityType ~= FieldGroundType.GRASS_CUT) and true or v283_
end

function WheelPhysics:getSurfaceSoundAttributes()
	if self.contact == WheelContactType.GROUND then
		if self.hasWaterContact then
			return "shallowWater", nil
		elseif self.densityType == FieldGroundType.NONE then
			return nil, self.lastTerrainAttribute
		else
			return "field", nil
		end
	else
		if self.contact == WheelContactType.GROUND_HEIGHT then
			if self.hasSnowContact then
				return "snow", nil
			end
		elseif self.contact == WheelContactType.OBJECT then
			return "asphalt", nil
		end
		return nil, nil
	end
end

-- Local values: gravity, tireLoad, nx, ny, nz, dx, dy, dz
function WheelPhysics:getTireLoad()
	if self.wheelShapeCreated then
		local v286_ = getWheelShapeContactForce(self.wheel.node, self.wheelShape)
		if v286_ ~= nil then
			local v287_, v288_, v289_ = getWheelShapeContactNormal(self.wheel.node, self.wheelShape)
			local v290_, v291_, v292_ = localDirectionToWorld(self.wheel.node, self.directionX, self.directionY, self.directionZ)
			local v293_ = -v286_ * MathUtil.dotProduct(v290_, v291_, v292_, v287_, v288_, v289_)
			local v294_ = v288_ * 9.81
			return (v293_ + math.max(v294_, 0) * self.wheel:getMass()) / 9.81
		end
	end
	return 0
end

-- Local values: steeringAngle, mass, velocityX, velocityY, velocityZ, invDt, velocityImpact, forceX, forceY, forceZ, gravityForceY, localX, _, localZ, localLength, targetRotY, rotio, rotOffset, staticFriction, dynamicFriction, drive
function WheelPhysics:getVersatileYRotation(dt)
	if self.forceVersatility or self.hasGroundContact then
		return Utils.getVersatileRotation(self.wheel.repr, self.wheel.node, dt, self.positionX, self.positionY, self.positionZ, self.steeringAngle, self.rotMin, self.rotMax)
	end
	if self.versatileYRotSpring == nil then
		return self.steeringAngle
	end
	local v297_ = self.steeringAngle
	local v298_ = self.mass * 1000
	local v299_, v300_, v301_ = getVelocityAtLocalPos(self.wheel.node, self.positionX, self.positionY, self.positionZ)
	local v302_ = v299_ * v298_
	local v303_ = v300_ * v298_
	local v304_ = v301_ * v298_
	if self.versatileYRotLastVelocity == nil then
		self.versatileYRotLastVelocity = { v302_, v303_, v304_ }
	end
	local v305_ = 1 / (dt * 0.001)
	local v306_ = (v302_ - self.versatileYRotLastVelocity[1]) * v305_ * 0.2
	local v307_ = (v303_ - self.versatileYRotLastVelocity[2]) * v305_ * 0.2
	local v308_ = (v304_ - self.versatileYRotLastVelocity[3]) * v305_ * 0.2
	local v309_ = self.versatileYRotLastVelocity
	local v310_ = self.versatileYRotLastVelocity
	local v311_ = self.versatileYRotLastVelocity
	v309_[1] = v302_
	v310_[2] = v303_
	v311_[3] = v304_
	local v312_ = 9.81 * v298_
	local v313_, _, v314_ = worldDirectionToLocal(getParent(self.wheel.repr), -v306_, -v307_ - v312_, -v308_)
	local v315_ = MathUtil.vector2Length(v313_, v314_)
	local v316_ = v297_ % 6.283185307179586
	local v317_ = (MathUtil.getYRotationFromDirection(v313_, v314_) + 3.141592653589793) % 6.283185307179586
	local v318_ = MathUtil.normalizeRotationForShortestPath(v317_, v316_)
	local v319_ = v315_ / v312_
	local v320_ = math.clamp(v319_, 0, 1)
	local v321_ = (v318_ - v316_) * v320_
	local v322_ = self.versatileYRotFriction[1]
	local v323_ = self.versatileYRotFriction[2]
	local v324_ = self.versatileYRotSpring * v321_ - self.versatileYRotDamping * self.versatileYRotSpeed
	local v325_ = self.versatileYRotSpeed
	local v326_
	if math.abs(v325_) < 0.00001 then
		if math.abs(v324_) <= v322_ then
			self.versatileYRotSpeed = 0
			v326_ = 0
		else
			v326_ = v324_ - math.sign(v324_) * v323_
		end
	else
		local v327_ = self.versatileYRotSpeed
		v326_ = v324_ - math.sign(v327_) * v323_
	end
	self.versatileYRotSpeed = self.versatileYRotSpeed + v326_ * dt
	return v316_ + self.versatileYRotSpeed * dt
end
function WheelPhysics.waterRaycastCallback(p328_, p329_, p330_, p331_, p332_, _, _, _, _, _, _, p333_, ...)
	if p329_ == 0 then
		if p333_ then
			p328_.hasWaterContact = false
		end
	else
		p328_.hasWaterContact = getTerrainHeightAtWorldPos(g_terrainNode, p330_, 0, p332_) < p331_
	end
end

function WheelPhysics.registerXMLPaths(schema, key)
	schema:register(XMLValueType.FLOAT, key .. ".physics#xOffset", "Moves the default position of the drive node on the X axis", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#yOffset", "Moves the default position of the drive node on the Y axis", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#zOffset", "Moves the default position of the drive node on the Z axis", 0)
	schema:register(XMLValueType.BOOL, key .. ".physics#useReprOffset", "Defines if the x/y/z offset attribute is applied to the repr or driveNode", false)
	schema:register(XMLValueType.BOOL, key .. ".physics#showSteeringAngle", "Show steering angle", true)
	schema:register(XMLValueType.FLOAT, key .. ".physics#steeringAngleFactor", "Scale factor for physics steering angle to steer more than the visuals show", 1)
	schema:register(XMLValueType.ANGLE, key .. ".physics#startSteeringAngle", "Default steering angle after loading of the vehicle", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#suspTravel", "Suspension travel", 0.01)
	schema:register(XMLValueType.FLOAT, key .. ".physics#initialCompression", "Initial compression value")
	schema:register(XMLValueType.FLOAT, key .. ".physics#deltaY", "Delta Y", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#spring", "Spring", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#brakeFactor", "Brake factor", 1)
	schema:register(XMLValueType.FLOAT, key .. ".physics#autoHoldBrakeFactor", "Auto hold brake factor", "brakeFactor")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damper", "Damper", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionLowSpeed", "Damper compression on low speeds")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionHighSpeed", "Damper compression on high speeds")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionLowSpeedThreshold", "Damper compression on low speeds threshold", 0.1016)
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationLowSpeed", "Damper relaxation on low speeds")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationHighSpeed", "Damper relaxation on high speeds")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationLowSpeedThreshold", "Damper relaxation on low speeds threshold", 0.1524)
	schema:register(XMLValueType.FLOAT, key .. ".physics#forcePointRatio", "Force point ratio", 0)
	schema:register(XMLValueType.INT, key .. ".physics#driveMode", "Drive mode", 0)
	schema:register(XMLValueType.BOOL, key .. ".physics#isSynchronized", "Wheel is synchronized in multiplayer", true)
	schema:register(XMLValueType.INT, key .. ".physics#tipOcclusionAreaGroupId", "Tip occlusion area group id")
	schema:register(XMLValueType.BOOL, key .. ".physics#useReprDirection", "Use repr direction instead of component direction", false)
	schema:register(XMLValueType.BOOL, key .. ".physics#useDriveNodeDirection", "Use drive node direction instead of component direction", false)
	schema:register(XMLValueType.FLOAT, key .. ".physics#mass", "Wheel mass (to.)", 0.1)
	schema:register(XMLValueType.FLOAT, key .. ".physics#radius", "Wheel radius", 0.5)
	schema:register(XMLValueType.FLOAT, key .. ".physics#width", "Wheel width", 0.6)
	schema:register(XMLValueType.FLOAT, key .. ".physics#visualOffset", "Radius offset of visual wheel in percentage (0-1). Not used on the game.")
	schema:register(XMLValueType.FLOAT, key .. ".physics#widthOffset", "Wheel width offset", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#restLoad", "Wheel load while resting", 1)
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLongStiffness", "Max. longitude stiffness")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffness", "Max. latitude stiffness")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffnessLoad", "Max. latitude stiffness load")
	schema:register(XMLValueType.FLOAT, key .. ".physics#frictionScale", "Wheel friction scale", 1)
	schema:register(XMLValueType.FLOAT, key .. ".physics#rotationDamping", "Rotation damping ", "mass * 0.035")
	schema:register(XMLValueType.STRING, key .. ".physics#tireType", "Tire type (mud, offRoad, street, crawler)")
	schema:register(XMLValueType.FLOAT, key .. ".physics#fieldDirtMultiplier", "Field dirt multiplier", 75)
	schema:register(XMLValueType.FLOAT, key .. ".physics#streetDirtMultiplier", "Street dirt multiplier", -150)
	schema:register(XMLValueType.FLOAT, key .. ".physics#waterWetnessFactor", "Factor for wheel wetness while driving in water", 20)
	schema:register(XMLValueType.FLOAT, key .. ".physics#minDirtPercentage", "Min. dirt scale while cleaning on street drive", 0.35)
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxDirtOffset", "Max. dirt amount offset to global dirt node", 0.5)
	schema:register(XMLValueType.FLOAT, key .. ".physics#dirtColorChangeSpeed", "Defines speed to change the dirt color (sec)", 20)
	schema:register(XMLValueType.BOOL, key .. ".physics#versatileYRot", "Do versatile Y rotation", false)
	schema:register(XMLValueType.ANGLE, key .. ".physics#versatileYRotSpring", "Spring value while wheels does not have ground contact")
	schema:register(XMLValueType.ANGLE, key .. ".physics#versatileYRotDamping", "Damping value while wheels does not have ground contact")
	schema:register(XMLValueType.VECTOR_2, key .. ".physics#versatileYRotFriction", "Static and dynamic friction values while wheels does not have ground contact", "0.0000015 0.0000010")
	schema:register(XMLValueType.BOOL, key .. ".physics#forceVersatility", "Force versatility, also if no ground contact", false)
	schema:register(XMLValueType.BOOL, key .. ".physics#supportsWheelSink", "The wheel is allowed to deform the terrain displacement collision and \'sink\' into the terrain", true)
	schema:register(XMLValueType.INT, key .. ".physics#collisionMask", "Custom collision mask for the wheel")
	schema:register(XMLValueType.BOOL, key .. ".physics.extraSink#supported", "Additional sinking into the terrain independent of the adjustment of the terrain displacement. (FS22 in prior style)", false)
	schema:register(XMLValueType.FLOAT, key .. ".physics.extraSink#maxValue", "Max. sink value in meter", "20% of the wheel radius")
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotSpeed", "Rotation speed")
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotSpeedNeg", "Rotation speed in negative direction")
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotMin", "Min. rotation")
	schema:register(XMLValueType.BOOL, key .. ".physics#invertRotLimit", "Invert the rotation limits")
	schema:register(XMLValueType.FLOAT, key .. ".physics#rotSpeedLimit", "Rotation speed limit")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxInnerSpacing", "Defines a maximum spacing to the inside which is now allowed to be exceeded by the tire, if so, the tire will be moved out automatically")
end

function WheelPhysics.registerAdditionalWheelXMLPaths(schema, key)
	schema:register(XMLValueType.FLOAT, key .. ".physics#mass", "Wheel mass (to.)", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLongStiffness", "Max. longitude stiffness")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffness", "Max. latitude stiffness")
end
