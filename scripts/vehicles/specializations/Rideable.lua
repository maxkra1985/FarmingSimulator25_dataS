Rideable = {}
source("dataS/scripts/vehicles/specializations/events/JumpEvent.lua")
source("dataS/scripts/vehicles/specializations/events/RideableStableNotificationEvent.lua")
Rideable.GAITTYPES = {
	["MIN"] = 1,
	["BACKWARDS"] = 1,
	["STILL"] = 2,
	["WALK"] = 3,
	["TROT"] = 4,
	["CANTER"] = 5,
	["GALLOP"] = 6,
	["MAX"] = 6
}
Rideable.HOOVES = {
	["FRONT_LEFT"] = 1,
	["FRONT_RIGHT"] = 2,
	["BACK_LEFT"] = 3,
	["BACK_RIGHT"] = 4
}
Rideable.GROUND_RAYCAST_OFFSET = 1.2
Rideable.GROUND_RAYCAST_MAXDISTANCE = 5
Rideable.GROUND_RAYCAST_COLLISIONMASK = CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.ROAD + CollisionFlag.STATIC_OBJECT

function Rideable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(CCTDrivable, specializations)
end
function Rideable.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Rideable")
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#speedBackwards", "Backward speed", -1)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#speedWalk", "Walk speed", 2.5)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#speedCanter", "Canter speed", 3.5)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#speedTrot", "Trot speed", 5)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#speedGallop", "Gallop speed", 10)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusBackwards", "Min turning radius backward", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusWalk", "Min turning radius walk", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusCanter", "Min turning radius canter", 2.5)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusTrot", "Min turning radius trot", 5)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusGallop", "Min turning radius gallop", 10)
	v2_:register(XMLValueType.ANGLE, "vehicle.rideable#turnSpeed", "Turn speed (deg/s)", 45)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable#jumpHeight", "Jump height", 2)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable#proxy", "Proxy node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontLeft#node", "Hoof node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemSlow#node", "Slow step particle emitterShape")
	v2_:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemSlow#particleType", "Slow step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(v2_, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemSlow")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemFast#node", "Fast step particle emitterShape")
	v2_:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemFast#particleType", "Fast step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(v2_, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemFast")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontRight#node", "Hoof node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemSlow#node", "Slow step particle emitterShape")
	v2_:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemSlow#particleType", "Slow step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(v2_, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemSlow")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemFast#node", "Fast step particle emitterShape")
	v2_:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemFast#particleType", "Fast step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(v2_, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemFast")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackLeft#node", "Hoof node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemSlow#node", "Slow step particle emitterShape")
	v2_:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemSlow#particleType", "Slow step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(v2_, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemSlow")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemFast#node", "Fast step particle emitterShape")
	v2_:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemFast#particleType", "Fast step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(v2_, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemFast")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackRight#node", "Hoof node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemSlow#node", "Slow step particle emitterShape")
	v2_:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemSlow#particleType", "Slow step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(v2_, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemSlow")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemFast#node", "Fast step particle emitterShape")
	v2_:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemFast#particleType", "Fast step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(v2_, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemFast")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#animationNode", "Animation node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#meshNode", "Mesh node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#equipmentNode", "Equipment node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#reinsNode", "Reins node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#reinLeftNode", "Rein left node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#reinRightNode", "Rein right node")
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable.sounds#breathIntervalNoEffort", "Breath interval no effort", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable.sounds#breathIntervalEffort", "Breath interval effort", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable.sounds#minBreathIntervalIdle", "Min. breath interval idle", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.rideable.sounds#maxBreathIntervalIdle", "Max. breath interval idle", 1)
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.rideable.sounds", "halt")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.rideable.sounds", "breathingNoEffort")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.rideable.sounds", "breathingEffort")
	ConditionalAnimation.registerXMLPaths(v2_, "vehicle.conditionalAnimation")
	ConditionalAnimation.registerXMLPaths(v2_, "vehicle.riderConditionalAnimation")
	v2_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).rideable#animalType", "Animal type name")
end

function Rideable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsRideableJumpAllowed", Rideable.getIsRideableJumpAllowed)
	SpecializationUtil.registerFunction(vehicleType, "jump", Rideable.jump)
	SpecializationUtil.registerFunction(vehicleType, "setCurrentGait", Rideable.setCurrentGait)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentGait", Rideable.getCurrentGait)
	SpecializationUtil.registerFunction(vehicleType, "setRideableSteer", Rideable.setRideableSteer)
	SpecializationUtil.registerFunction(vehicleType, "resetInputs", Rideable.resetInputs)
	SpecializationUtil.registerFunction(vehicleType, "updateKinematic", Rideable.updateKinematic)
	SpecializationUtil.registerFunction(vehicleType, "testCCTMove", Rideable.testCCTMove)
	SpecializationUtil.registerFunction(vehicleType, "updateAnimation", Rideable.updateAnimation)
	SpecializationUtil.registerFunction(vehicleType, "updateSound", Rideable.updateSound)
	SpecializationUtil.registerFunction(vehicleType, "updateRiding", Rideable.updateRiding)
	SpecializationUtil.registerFunction(vehicleType, "updateDirt", Rideable.updateDirt)
	SpecializationUtil.registerFunction(vehicleType, "calculateLegsDistance", Rideable.calculateLegsDistance)
	SpecializationUtil.registerFunction(vehicleType, "setWorldPositionQuat", Rideable.setWorldPositionQuat)
	SpecializationUtil.registerFunction(vehicleType, "updateFootsteps", Rideable.updateFootsteps)
	SpecializationUtil.registerFunction(vehicleType, "getPosition", Rideable.getPosition)
	SpecializationUtil.registerFunction(vehicleType, "getRotation", Rideable.getRotation)
	SpecializationUtil.registerFunction(vehicleType, "setEquipmentVisibility", Rideable.setEquipmentVisibility)
	SpecializationUtil.registerFunction(vehicleType, "getHoofSurfaceSound", Rideable.getHoofSurfaceSound)
	SpecializationUtil.registerFunction(vehicleType, "groundRaycastCallback", Rideable.groundRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "unlinkReins", Rideable.unlinkReins)
	SpecializationUtil.registerFunction(vehicleType, "updateInputText", Rideable.updateInputText)
	SpecializationUtil.registerFunction(vehicleType, "setPlayerToEnter", Rideable.setPlayerToEnter)
	SpecializationUtil.registerFunction(vehicleType, "endFade", Rideable.endFade)
	SpecializationUtil.registerFunction(vehicleType, "setCluster", Rideable.setCluster)
	SpecializationUtil.registerFunction(vehicleType, "getCluster", Rideable.getCluster)
end

function Rideable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadPositionUpdateStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onWritePositionUpdateStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", Rideable)
end

function Rideable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPosition", Rideable.setWorldPosition)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", Rideable.setWorldPositionQuaternion)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehicleSpeed", Rideable.updateVehicleSpeed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getName", Rideable.getName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName", Rideable.getFullName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Rideable.getCanBeReset)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMapHotspotRotation", Rideable.getMapHotspotRotation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowInVehiclesOverview", Rideable.getShowInVehiclesOverview)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "periodChanged", Rideable.periodChanged)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "dayChanged", Rideable.dayChanged)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getImageFilename", Rideable.getImageFilename)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", Rideable.showInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "deleteVehicleCharacter", Rideable.deleteVehicleCharacter)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSold", Rideable.getCanBeSold)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInteractionHelp", Rideable.getInteractionHelp)
end

-- Local values: spec, loadHoof, animationPlayer, key, parameter, mission, _, surfaceSound, sample, xmlFile, key, subTypeName, subType, cluster
function Rideable:onLoad(savegame)
	local v8_ = self.spec_rideable
	self.highPrecisionPositionSynchronization = true
	v8_.leaveTimer = 15000
	v8_.currentDirtScale = 0
	v8_.abandonTimerDuration = g_gameSettings:getValue(GameSettings.SETTING.HORSE_ABANDON_TIMER_DURATION)
	v8_.abandonTimer = v8_.abandonTimerDuration
	v8_.fadeDuration = 400
	v8_.isRideableRemoved = false
	v8_.justSpawned = true
	v8_.meshNode = nil
	v8_.animationNode = nil
	v8_.charsetId = nil
	v8_.animationPlayer = nil
	v8_.animationParameters = {}
	v8_.animationParameters.forwardVelocity = {
		["id"] = 1,
		["value"] = 0,
		["type"] = 1
	}
	v8_.animationParameters.verticalVelocity = {
		["id"] = 2,
		["value"] = 0,
		["type"] = 1
	}
	v8_.animationParameters.yawVelocity = {
		["id"] = 3,
		["value"] = 0,
		["type"] = 1
	}
	v8_.animationParameters.absForwardVelocity = {
		["id"] = 4,
		["value"] = 0,
		["type"] = 1
	}
	v8_.animationParameters.onGround = {
		["id"] = 5,
		["value"] = false,
		["type"] = 0
	}
	v8_.animationParameters.inWater = {
		["id"] = 6,
		["value"] = false,
		["type"] = 0
	}
	v8_.animationParameters.closeToGround = {
		["id"] = 7,
		["value"] = false,
		["type"] = 0
	}
	v8_.animationParameters.leftRightWeight = {
		["id"] = 8,
		["value"] = 0,
		["type"] = 1
	}
	v8_.animationParameters.absYawVelocity = {
		["id"] = 9,
		["value"] = 0,
		["type"] = 1
	}
	v8_.animationParameters.halted = {
		["id"] = 10,
		["value"] = false,
		["type"] = 0
	}
	v8_.animationParameters.smoothedForwardVelocity = {
		["id"] = 11,
		["value"] = 0,
		["type"] = 1
	}
	v8_.animationParameters.absSmoothedForwardVelocity = {
		["id"] = 12,
		["value"] = 0,
		["type"] = 1
	}
	v8_.acceletateEventId = ""
	v8_.brakeEventId = ""
	v8_.steerEventId = ""
	v8_.jumpEventId = ""
	v8_.currentTurnAngle = 0
	v8_.currentTurnSpeed = 0
	v8_.currentSpeed = 0
	v8_.currentSpeedY = 0
	v8_.cctMoveQueue = {}
	v8_.currentCCTPosX = 0
	v8_.currentCCTPosY = 0
	v8_.currentCCTPosZ = 0
	v8_.lastCCTPosX = 0
	v8_.lastCCTPosY = 0
	v8_.lastCCTPosZ = 0
	v8_.topSpeeds = {}
	v8_.topSpeeds[Rideable.GAITTYPES.BACKWARDS] = self.xmlFile:getValue("vehicle.rideable#speedBackwards", -1)
	v8_.topSpeeds[Rideable.GAITTYPES.STILL] = 0
	v8_.topSpeeds[Rideable.GAITTYPES.WALK] = self.xmlFile:getValue("vehicle.rideable#speedWalk", 2.5)
	v8_.topSpeeds[Rideable.GAITTYPES.CANTER] = self.xmlFile:getValue("vehicle.rideable#speedCanter", 3.5)
	v8_.topSpeeds[Rideable.GAITTYPES.TROT] = self.xmlFile:getValue("vehicle.rideable#speedTrot", 5)
	v8_.topSpeeds[Rideable.GAITTYPES.GALLOP] = self.xmlFile:getValue("vehicle.rideable#speedGallop", 10)
	v8_.minTurnRadius = {}
	v8_.minTurnRadius[Rideable.GAITTYPES.BACKWARDS] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusBackwards", 1)
	v8_.minTurnRadius[Rideable.GAITTYPES.STILL] = 1
	v8_.minTurnRadius[Rideable.GAITTYPES.WALK] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusWalk", 1)
	v8_.minTurnRadius[Rideable.GAITTYPES.CANTER] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusCanter", 2.5)
	v8_.minTurnRadius[Rideable.GAITTYPES.TROT] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusTrot", 5)
	v8_.minTurnRadius[Rideable.GAITTYPES.GALLOP] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusGallop", 10)
	v8_.groundRaycastResult = {}
	v8_.groundRaycastResult.y = 0
	v8_.groundRaycastResult.object = nil
	v8_.groundRaycastResult.distance = 0
	v8_.haltTimer = 0
	v8_.smoothedLeftRightWeight = 0
	v8_.interpolationDt = 16
	v8_.ridingTimer = 0
	v8_.doHusbandryCheck = 0
	v8_.proxy = self.xmlFile:getValue("vehicle.rideable#proxy", nil, self.components, self.i3dMappings)
	if v8_.proxy ~= nil then
		setRigidBodyType(v8_.proxy, RigidBodyType.NONE)
	end
	v8_.collisionMask = getCollisionFilterMask(self.components[1].node)
	v8_.maxAcceleration = 5
	v8_.maxDeceleration = 10
	v8_.gravity = -9.81
	v8_.frontCheckDistance = 0
	v8_.backCheckDistance = 0
	v8_.isOnGround = true
	v8_.isCloseToGround = true
	local v9_ = v8_.topSpeeds[Rideable.GAITTYPES.MIN] < v8_.topSpeeds[Rideable.GAITTYPES.MAX]
	assert(v9_)
	v8_.maxTurnSpeed = self.xmlFile:getValue("vehicle.rideable#turnSpeed", 45)
	v8_.jumpHeight = self.xmlFile:getValue("vehicle.rideable#jumpHeight", 2)
	local function v20_(p10_, p11_, p12_)
		-- upvalues: (copy) self
		local v13_ = {
			["node"] = self.xmlFile:getValue(p12_ .. "#node", nil, self.components, self.i3dMappings),
			["onGround"] = false
		}
		local v14_ = self.xmlFile:getValue(p12_ .. ".particleSystemSlow#node", nil, self.components, self.i3dMappings)
		local v15_ = self.xmlFile:getValue(p12_ .. ".particleSystemSlow#particleType")
		if v15_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing horse step slow particleType in \'%s\'", p12_ .. ".particleSystemSlow")
			return
		else
			local v16_ = g_particleSystemManager:getParticleSystem(v15_)
			if v16_ ~= nil then
				v13_.psSlow = ParticleUtil.copyParticleSystem(self.xmlFile, p12_ .. ".particleSystemSlow", v16_, v14_)
				link(getRootNode(), v13_.psSlow.emitterShape)
			end
			local v17_ = self.xmlFile:getValue(p12_ .. ".particleSystemFast#node", nil, self.components, self.i3dMappings)
			local v18_ = self.xmlFile:getValue(p12_ .. ".particleSystemFast#particleType")
			if v18_ == nil then
				Logging.xmlWarning(self.xmlFile, "Missing horse step fast particleType in \'%s\'", p12_ .. ".particleSystemFast")
			else
				local v19_ = g_particleSystemManager:getParticleSystem(v18_)
				if v19_ ~= nil then
					v13_.psFast = ParticleUtil.copyParticleSystem(self.xmlFile, p12_ .. ".particleSystemFast", v19_, v17_)
					link(getRootNode(), v13_.psFast.emitterShape)
				end
				p10_[p11_] = v13_
			end
		end
	end
	v8_.hooves = {}
	v20_(v8_.hooves, Rideable.HOOVES.FRONT_LEFT, "vehicle.rideable.modelInfo.hoofFrontLeft")
	v20_(v8_.hooves, Rideable.HOOVES.FRONT_RIGHT, "vehicle.rideable.modelInfo.hoofFrontRight")
	v20_(v8_.hooves, Rideable.HOOVES.BACK_LEFT, "vehicle.rideable.modelInfo.hoofBackLeft")
	v20_(v8_.hooves, Rideable.HOOVES.BACK_RIGHT, "vehicle.rideable.modelInfo.hoofBackRight")
	v8_.frontCheckDistance = self:calculateLegsDistance(v8_.hooves[Rideable.HOOVES.FRONT_LEFT].node, v8_.hooves[Rideable.HOOVES.FRONT_RIGHT].node)
	v8_.backCheckDistance = self:calculateLegsDistance(v8_.hooves[Rideable.HOOVES.BACK_LEFT].node, v8_.hooves[Rideable.HOOVES.BACK_RIGHT].node)
	v8_.animationNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#animationNode", nil, self.components, self.i3dMappings)
	v8_.meshNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#meshNode", nil, self.components, self.i3dMappings)
	v8_.equipmentNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#equipmentNode", nil, self.components, self.i3dMappings)
	v8_.reinsNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#reinsNode", nil, self.components, self.i3dMappings)
	v8_.leftReinNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#reinLeftNode", nil, self.components, self.i3dMappings)
	v8_.rightReinNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#reinRightNode", nil, self.components, self.i3dMappings)
	v8_.leftReinParentNode = getParent(v8_.leftReinNode)
	v8_.rightReinParentNode = getParent(v8_.rightReinNode)
	if v8_.animationNode ~= nil then
		v8_.charsetId = getAnimCharacterSet(v8_.animationNode)
		local v21_ = createConditionalAnimation()
		if v21_ ~= 0 then
			v8_.animationPlayer = v21_
			for v22_, v23_ in pairs(v8_.animationParameters) do
				conditionalAnimationRegisterParameter(v8_.animationPlayer, v23_.id, v23_.type, v22_)
			end
			initConditionalAnimation(v8_.animationPlayer, v8_.charsetId, self.configFileName, "vehicle.conditionalAnimation")
			setConditionalAnimationSpecificParameterIds(v8_.animationPlayer, v8_.animationParameters.absForwardVelocity.id, v8_.animationParameters.absYawVelocity.id)
		end
	end
	v8_.surfaceSounds = {}
	v8_.surfaceIdToSound = {}
	v8_.surfaceNameToSound = {}
	v8_.currentSurfaceSound = nil
	local v24_ = g_currentMission
	for _, v25_ in pairs(v24_.surfaceSounds) do
		if v25_.type == "hoofstep" and v25_.sample ~= nil then
			local v26_ = g_soundManager:cloneSample(v25_.sample, self.components[1].node, self)
			v26_.sampleName = v25_.name
			local v27_ = v8_.surfaceSounds
			table.insert(v27_, v26_)
			v8_.surfaceIdToSound[v25_.materialId] = v26_
			v8_.surfaceNameToSound[v25_.name] = v26_
		end
	end
	v8_.horseStopSound = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "halt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	v8_.horseBreathSoundsNoEffort = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "breathingNoEffort", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	v8_.horseBreathSoundsEffort = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "breathingEffort", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	v8_.horseBreathIntervalNoEffort = self.xmlFile:getValue("vehicle.rideable.sounds#breathIntervalNoEffort", 1) * 1000
	v8_.horseBreathIntervalEffort = self.xmlFile:getValue("vehicle.rideable.sounds#breathIntervalEffort", 1) * 1000
	v8_.horseBreathMinIntervalIdle = self.xmlFile:getValue("vehicle.rideable.sounds#minBreathIntervalIdle", 1) * 1000
	v8_.horseBreathMaxIntervalIdle = self.xmlFile:getValue("vehicle.rideable.sounds#maxBreathIntervalIdle", 1) * 1000
	v8_.currentBreathTimer = 0
	v8_.inputValues = {}
	v8_.inputValues.axisSteer = 0
	v8_.inputValues.axisSteerSend = 0
	v8_.inputValues.currentGait = Rideable.GAITTYPES.STILL
	self:resetInputs()
	v8_.interpolatorIsOnGround = InterpolatorValue.new(0)
	if self.isServer then
		v8_.interpolatorTurnAngle = InterpolatorAngle.new(0)
		self.networkTimeInterpolator.maxInterpolationAlpha = 1.2
	end
	v8_.dirtyFlag = self:getNextDirtyFlag()
	if savegame ~= nil then
		local v28_ = savegame.xmlFile
		local v29_ = savegame.key .. ".rideable"
		local v30_ = v28_:getString(v29_ .. "#subType", "HORSE_GRAY")
		local v31_ = v24_.animalSystem:getSubTypeByName(v30_)
		if v31_ == nil then
			Logging.xmlError(self.xmlFile, "Animal sub type \'%s\' not found for \'%s\'!", v30_, v29_)
			self:setLoadingState(VehicleLoadingState.ERROR)
			return
		end
		local v32_ = v24_.animalSystem:createClusterFromSubTypeIndex(v31_.subTypeIndex)
		v32_:loadFromXMLFile(v28_, v29_ .. ".animal")
		self:setCluster(v32_)
	end
	v24_.husbandrySystem:addRideable(self)
	self.needWaterInfo = true
end

function Rideable:onLoadFinished()
	self:raiseActive()
end

-- Local values: spec, dx, _, dz
function Rideable:setWorldPosition(superFunc, x, y, z, xRot, yRot, zRot, i, changeInterp)
	superFunc(self, x, y, z, xRot, yRot, zRot, i, changeInterp)
	if self.isServer and i == 1 then
		local v44_ = self.spec_rideable
		local v45_, _, v46_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		v44_.currentTurnAngle = MathUtil.getYRotationFromDirection(v45_, v46_)
		if changeInterp then
			v44_.interpolatorTurnAngle:setAngle(v44_.currentTurnAngle)
		end
	end
end

-- Local values: spec, dx, _, dz
function Rideable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
	superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
	if self.isServer and i == 1 then
		local v58_ = self.spec_rideable
		local v59_, _, v60_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		v58_.currentTurnAngle = MathUtil.getYRotationFromDirection(v59_, v60_)
		if changeInterp then
			v58_.interpolatorTurnAngle:setAngle(v58_.currentTurnAngle)
		end
	end
end

-- Local values: spec
function Rideable:updateVehicleSpeed(superFunc, dt)
	if self.isServer then
		superFunc(self, self.spec_rideable.interpolationDt)
	else
		superFunc(self, dt)
	end
end

-- Local values: distance, _, _, dzL, _, _, dzR
function Rideable:calculateLegsDistance(leftLegNode, rightLegNode)
	local v67_
	if leftLegNode == nil or rightLegNode == nil then
		v67_ = 0
	else
		local _, _, v68_ = localToLocal(leftLegNode, self.rootNode, 0, 0, 0)
		local _, _, v69_ = localToLocal(rightLegNode, self.rootNode, 0, 0, 0)
		v67_ = (v68_ + v69_) * 0.5
	end
	return v67_
end

-- Local values: spec, mission, _, d
function Rideable:onDelete()
	local v71_ = self.spec_rideable
	g_currentMission.husbandrySystem:removeRideable(self)
	g_soundManager:deleteSamples(v71_.surfaceSounds)
	g_soundManager:deleteSample(v71_.horseStopSound)
	g_soundManager:deleteSample(v71_.horseBreathSoundsNoEffort)
	g_soundManager:deleteSample(v71_.horseBreathSoundsEffort)
	if v71_.hooves ~= nil then
		for _, v72_ in pairs(v71_.hooves) do
			if v72_.psSlow ~= nil then
				ParticleUtil.deleteParticleSystem(v72_.psSlow)
				delete(v72_.psSlow.emitterShape)
			end
			if v72_.psFast ~= nil then
				ParticleUtil.deleteParticleSystem(v72_.psFast)
				delete(v72_.psFast.emitterShape)
			end
		end
	end
	if v71_.animationPlayer ~= nil then
		delete(v71_.animationPlayer)
		v71_.animationPlayer = nil
	end
end

-- Local values: spec, isOnGround, subTypeIndex, mission, cluster, player
function Rideable:onReadStream(streamId, connection)
	local v76_ = self.spec_rideable
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			v76_.interpolatorIsOnGround:setValue(1)
		else
			v76_.interpolatorIsOnGround:setValue(0)
		end
	end
	if streamReadBool(streamId) then
		local v77_ = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_SUB_TYPE)
		local v78_ = g_currentMission.animalSystem:createClusterFromSubTypeIndex(v77_)
		v78_:readStream(streamId, connection)
		self:setCluster(v78_)
	end
	if streamReadBool(streamId) then
		self:setPlayerToEnter((NetworkUtil.readNodeObject(streamId)))
	end
end

-- Local values: spec
function Rideable:onWriteStream(streamId, connection)
	local v82_ = self.spec_rideable
	if not connection:getIsServer() then
		streamWriteBool(streamId, v82_.isOnGround)
	end
	if streamWriteBool(streamId, v82_.cluster ~= nil) then
		streamWriteUIntN(streamId, v82_.cluster:getSubTypeIndex(), AnimalCluster.NUM_BITS_SUB_TYPE)
		v82_.cluster:writeStream(streamId, connection)
	end
	if streamWriteBool(streamId, v82_.playerToEnter ~= nil) then
		NetworkUtil.writeNodeObject(streamId, v82_.playerToEnter)
	end
end

-- Local values: spec
function Rideable:onReadUpdateStream(streamId, timestamp, connection)
	local v86_ = self.spec_rideable
	if connection:getIsServer() then
		v86_.haltTimer = streamReadFloat32(streamId)
		if v86_.haltTimer > 0 then
			v86_.inputValues.currentGait = Rideable.GAITTYPES.STILL
			v86_.inputValues.axisSteerSend = 0
		end
		if streamReadBool(streamId) then
			v86_.cluster:readUpdateStream(streamId, connection)
			self:updateDirt()
		end
	else
		v86_.inputValues.axisSteer = streamReadFloat32(streamId)
		v86_.inputValues.currentGait = streamReadUInt8(streamId)
	end
end

-- Local values: spec
function Rideable:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v90_ = self.spec_rideable
	if connection:getIsServer() then
		streamWriteFloat32(streamId, v90_.inputValues.axisSteerSend)
		streamWriteUInt8(streamId, v90_.inputValues.currentGait)
	else
		streamWriteFloat32(streamId, v90_.haltTimer)
		if streamWriteBool(streamId, v90_.cluster ~= nil) then
			v90_.cluster:writeUpdateStream(streamId, connection)
		end
	end
end

-- Local values: spec, isOnGround
function Rideable:onReadPositionUpdateStream(streamId, connection)
	local v93_ = self.spec_rideable
	if streamReadBool(streamId) then
		v93_.interpolatorIsOnGround:setValue(1)
	else
		v93_.interpolatorIsOnGround:setValue(0)
	end
end

-- Local values: spec
function Rideable:onWritePositionUpdateStream(streamId, connection, dirtyMask)
	local v96_ = self.spec_rideable
	streamWriteBool(streamId, v96_.isOnGround)
end

function Rideable:endFade() end

-- Local values: spec, mission, animalSystem, subTypeIndex, subType
function Rideable:saveToXMLFile(xmlFile, key, usedModNames)
	local v101_ = self.spec_rideable
	if v101_.cluster ~= nil then
		local v102_ = g_currentMission.animalSystem:getSubTypeByIndex((v101_.cluster:getSubTypeIndex()))
		xmlFile:setString(key .. "#subType", v102_.name)
		v101_.cluster:saveToXMLFile(xmlFile, key .. ".animal", usedModNames)
	end
end

-- Local values: spec, mission, animalSystem, subTypeIndex, visual, variation, tileU, tileV
function Rideable:setCluster(cluster)
	local v105_ = self.spec_rideable
	v105_.cluster = cluster
	if cluster ~= nil then
		local v106_ = g_currentMission.animalSystem:getVisualByAge(cluster:getSubTypeIndex(), cluster:getAge()).visualAnimal.variations[1]
		local v107_ = v106_.tileUIndex / v106_.numTilesU
		local v108_ = v106_.tileVIndex / v106_.numTilesV
		I3DUtil.setShaderParameterRec(v105_.meshNode, "atlasInvSizeAndOffsetUV", nil, nil, v107_, v108_)
		self:updateDirt()
	end
end

-- Local values: spec, cluster, dirtFactor
function Rideable:updateDirt()
	local v110_ = self.spec_rideable
	local v111_ = v110_.cluster
	local v112_ = (not Platform.gameplay.needHorseCleaning or (v111_ == nil or v111_.getDirtFactor == nil)) and 0 or v111_:getDirtFactor()
	I3DUtil.setShaderParameterRec(v110_.meshNode, "dirt", v112_, nil, nil, nil)
end

function Rideable:getCluster()
	return self.spec_rideable.cluster
end

-- Local values: spec, isEntered, inputHelpMode, dx, dy, dz, steeringValue, mission, isInRange, husbandry, isInStable, cluster
function Rideable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v117_ = self.spec_rideable
	if self:getIsSynchronized() and (v117_.playerToEnter ~= nil and (v117_.checkPlayerToEnter and v117_.playerToEnter == g_localPlayer)) then
		g_localPlayer:requestToEnterVehicle(self, true)
		v117_.checkPlayerToEnter = false
	end
	if self:getIsEntered() then
		if isActiveForInputIgnoreSelection then
			self:updateInputText()
		end
		if not self.isServer then
			v117_.inputValues.axisSteerSend = v117_.inputValues.axisSteer
			self:raiseDirtyFlags(v117_.dirtyFlag)
			self:resetInputs()
		end
	end
	self:updateAnimation(dt)
	if self.isClient then
		self:updateSound(dt)
	end
	if self.isServer then
		self:updateRiding(dt)
	end
	if v117_.haltTimer > 0 then
		self:setCurrentGait(Rideable.GAITTYPES.STILL)
		v117_.haltTimer = v117_.haltTimer - dt
	end
	if self:getIsActiveForInput(true) and (g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD or GS_PLATFORM_SWITCH) and g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) then
		local v118_, v119_, v120_ = getGravityDirection()
		self:setRideableSteer((MathUtil.getSteeringAngleFromDeviceGravity(v118_, v119_, v120_)))
	end
	if self.isServer and v117_.doHusbandryCheck > 0 then
		v117_.doHusbandryCheck = v117_.doHusbandryCheck - dt
		local v121_, v122_ = g_currentMission.husbandrySystem:getHusbandryInRideableRange(self)
		if v121_ then
			local v123_
			if v122_ == nil then
				v123_ = false
			else
				v122_:addCluster((self:getCluster()))
				self:delete()
				v123_ = true
			end
			if v117_.lastOwner ~= nil then
				v117_.lastOwner:sendEvent(RideableStableNotificationEvent.new(v123_, v117_.cluster:getName()), nil, true)
			end
		end
		v117_.lastOwner = nil
	end
end

-- Local values: spec, interpolationDt, oldestMoveInfo, component, x, y, z, phaseDuration, turnAngle, _, dirY, _, dirX, dirZ, scale, isOnGroundFloat, posX, posY, posZ, dirX, dirY, dirZ, fx, fy, fz, bx, by, bz, dx, dy, dz, posX, posY, posZ
function Rideable:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v126_ = self.spec_rideable
	if self.isServer then
		if not self:getIsControlled() then
			self:setCurrentGait(Rideable.GAITTYPES.STILL)
		end
		local v127_ = v126_.cctMoveQueue[1]
		local v128_
		if v127_ == nil or not getIsPhysicsUpdateIndexSimulated(v127_.physicsIndex) then
			v128_ = dt
		else
			v128_ = v127_.dt
		end
		v126_.interpolationDt = v128_
		self:testCCTMove(v128_)
		self:updateKinematic(dt)
		if self:getIsEntered() then
			self:resetInputs()
		end
		local v129_ = self.components[1]
		local v130_, v131_, v132_ = self:getCCTWorldTranslation()
		v129_.networkInterpolators.position:setTargetPosition(v130_, v131_, v132_)
		v126_.interpolatorTurnAngle:setTargetAngle(v126_.currentTurnAngle)
		v126_.interpolatorIsOnGround:setTargetValue(self:getIsCCTOnGround() and 1 or 0)
		local v133_ = v128_ + 30
		self.networkTimeInterpolator:startNewPhase(v133_)
		self.networkTimeInterpolator:update(v128_)
		local v134_, v135_, v136_ = v129_.networkInterpolators.position:getInterpolatedValues(self.networkTimeInterpolator.interpolationAlpha)
		setTranslation(self.rootNode, v134_, v135_, v136_)
		local v137_ = v126_.interpolatorTurnAngle:getInterpolatedValue(self.networkTimeInterpolator.interpolationAlpha)
		local _, v138_, _ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		local v139_ = math.sin(v137_)
		local v140_ = math.cos(v137_)
		local v141_ = v138_ * v138_
		local v142_ = 1 - math.min(v141_, 0.9)
		local v143_ = math.sqrt(v142_)
		local v144_ = v139_ * v143_
		local v145_ = v140_ * v143_
		setDirection(self.rootNode, v144_, v138_, v145_, 0, 1, 0)
	end
	if not self:getIsEntered() and v126_.leaveTimer > 0 then
		v126_.leaveTimer = v126_.leaveTimer - dt
		self:raiseActive()
	end
	v126_.isOnGround = v126_.interpolatorIsOnGround:getInterpolatedValue(self.networkTimeInterpolator:getAlpha()) > 0.9
	v126_.isCloseToGround = false
	if v126_.isOnGround then
		local v146_ = v126_.currentSpeed
		if math.abs(v146_) > 0.001 then
			::l22::
			local v147_, v148_, v149_ = getWorldTranslation(self.rootNode)
			local v150_, v151_, v152_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
			local v153_ = v147_ + v150_ * v126_.frontCheckDistance
			local v154_ = v148_ + v151_ * v126_.frontCheckDistance
			local v155_ = v149_ + v152_ * v126_.frontCheckDistance
			v126_.groundRaycastResult.y = v154_ + Rideable.GROUND_RAYCAST_OFFSET - Rideable.GROUND_RAYCAST_MAXDISTANCE
			raycastAll(v153_, v154_ + Rideable.GROUND_RAYCAST_OFFSET, v155_, 0, -1, 0, Rideable.GROUND_RAYCAST_MAXDISTANCE, "groundRaycastCallback", self, Rideable.GROUND_RAYCAST_COLLISIONMASK)
			local v156_ = v126_.groundRaycastResult.y
			local v157_ = v147_ + v150_ * v126_.backCheckDistance
			local v158_ = v148_ + v151_ * v126_.backCheckDistance
			local v159_ = v149_ + v152_ * v126_.backCheckDistance
			v126_.groundRaycastResult.y = v158_ + Rideable.GROUND_RAYCAST_OFFSET - Rideable.GROUND_RAYCAST_MAXDISTANCE
			raycastAll(v157_, v158_ + Rideable.GROUND_RAYCAST_OFFSET, v159_, 0, -1, 0, Rideable.GROUND_RAYCAST_MAXDISTANCE, "groundRaycastCallback", self, Rideable.GROUND_RAYCAST_COLLISIONMASK)
			local v160_ = v126_.groundRaycastResult.y
			local v161_ = v153_ - v157_
			local v162_ = v156_ - v160_
			local v163_ = v155_ - v159_
			setDirection(self.rootNode, v161_, v162_, v163_, 0, 1, 0)
			return
		end
		local v164_ = v126_.currentTurnSpeed
		if math.abs(v164_) > 0.001 then
			goto l22
		end
	end
	local v165_, v166_, v167_ = getWorldTranslation(self.rootNode)
	v126_.groundRaycastResult.distance = Rideable.GROUND_RAYCAST_MAXDISTANCE
	raycastAll(v165_, v166_, v167_, 0, -1, 0, Rideable.GROUND_RAYCAST_MAXDISTANCE, "groundRaycastCallback", self, Rideable.GROUND_RAYCAST_COLLISIONMASK)
	v126_.isCloseToGround = v126_.groundRaycastResult.distance < 1.25
end

-- Local values: spec, mission
function Rideable:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v170_ = self.spec_rideable
	if isActiveForInputIgnoreSelection and v170_.cluster ~= nil then
		g_currentMission:addExtraPrintText(string.format("%s: %d %%", g_i18n:getText("infohud_riding"), v170_.cluster:getRidingFactor() * 100))
	end
end

-- Local values: husbandry, spec, isInStable, cluster
function Rideable:onSetBroken()
	self:unlinkReins()
	if self.isServer then
		local v172_ = g_currentMission.husbandrySystem:getFirstAvailableHusbandry(self)
		local v173_ = self.spec_rideable
		local v174_
		if v172_ == nil then
			v174_ = false
		else
			v172_:addCluster((self:getCluster()))
			self:delete()
			v174_ = true
		end
		if v173_.lastOwner ~= nil then
			v173_.lastOwner:sendEvent(RideableStableNotificationEvent.new(v174_, v173_.cluster:getName()), nil, true)
		end
	end
end

-- Local values: spec, expectedMovementX, expectedMovementZ, expectedMovement, movementX, movementZ, movement
function Rideable:testCCTMove(dt)
	local v177_ = self.spec_rideable
	local v178_ = v177_.currentCCTPosX
	local v179_ = v177_.currentCCTPosY
	local v180_ = v177_.currentCCTPosZ
	v177_.lastCCTPosX = v178_
	v177_.lastCCTPosY = v179_
	v177_.lastCCTPosZ = v180_
	local v181_, v182_, v183_ = getWorldTranslation(self.spec_cctdrivable.cctNode)
	v177_.currentCCTPosX = v181_
	v177_.currentCCTPosY = v182_
	v177_.currentCCTPosZ = v183_
	local v184_ = 0
	local v185_ = 0
	while v177_.cctMoveQueue[1] ~= nil and getIsPhysicsUpdateIndexSimulated(v177_.cctMoveQueue[1].physicsIndex) do
		v184_ = v184_ + v177_.cctMoveQueue[1].moveX
		v185_ = v185_ + v177_.cctMoveQueue[1].moveZ
		table.remove(v177_.cctMoveQueue, 1)
	end
	local v186_ = v184_ * v184_ + v185_ * v185_
	local v187_ = math.sqrt(v186_)
	if 0.001 * dt < v187_ then
		local v188_ = v177_.currentCCTPosX - v177_.lastCCTPosX
		local v189_ = v177_.currentCCTPosZ - v177_.lastCCTPosZ
		local v190_ = v188_ * v188_ + v189_ * v189_
		if math.sqrt(v190_) <= v187_ * 0.7 and v177_.haltTimer <= 0 then
			self:setCurrentGait(Rideable.GAITTYPES.STILL)
			v177_.haltTimer = 900
			if v177_.horseStopSound ~= nil then
				g_soundManager:playSample(v177_.horseStopSound)
			end
		end
	end
end

-- Local values: spec
function Rideable:getIsRideableJumpAllowed(allowWhileJump)
	local v193_ = self.spec_rideable
	if v193_.isOnGround or allowWhileJump then
		if v193_.inputValues.currentGait < Rideable.GAITTYPES.CANTER then
			return false
		else
			return not self.isBroken
		end
	else
		return false
	end
end

-- Local values: spec, total, _, jumpHeight, velY
function Rideable:jump()
	local v195_ = self.spec_rideable
	if self.isServer then
		local v196_, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "horseJumpCount", 1)
		if v196_ ~= nil then
			g_achievementManager:tryUnlock("HorseJumpsFirst", v196_)
			g_achievementManager:tryUnlock("HorseJumps", v196_)
		end
	else
		g_client:getServerConnection():sendEvent(JumpEvent.new(self))
	end
	local v197_ = v195_.jumpHeight
	if v195_.inputValues.currentGait == Rideable.GAITTYPES.CANTER then
		v197_ = v197_ * 0.5
	end
	local v198_ = v195_.gravity
	local v199_ = 2 * math.abs(v198_) * v197_
	v195_.currentSpeedY = math.sqrt(v199_)
end

-- Local values: spec
function Rideable:setCurrentGait(gait)
	self.spec_rideable.inputValues.currentGait = gait
end

function Rideable:getCurrentGait()
	return self.spec_rideable.inputValues.currentGait
end

-- Local values: spec
function Rideable:setRideableSteer(axisSteer)
	local v205_ = self.spec_rideable
	if axisSteer ~= 0 then
		v205_.inputValues.axisSteer = -axisSteer
	end
end

-- Local values: spec
function Rideable:resetInputs()
	self.spec_rideable.inputValues.axisSteer = 0
end

-- Local values: spec, dtInSec, desiredSpeed, maxSpeedChange, speedChange, movement, gravitySpeedChange, movementY, slowestSpeed, fastestSpeed, maxTurnSpeedChange, desiredTurnSpeed, turnSpeedChange, movementX, movementZ
function Rideable:updateKinematic(dt)
	local v209_ = self.spec_rideable
	local v210_ = dt * 0.001
	local v211_ = v209_.topSpeeds[v209_.inputValues.currentGait]
	local v212_ = v209_.maxAcceleration
	if v211_ == 0 then
		v212_ = v209_.maxDeceleration
	end
	local v213_ = v212_ * v210_
	if not v209_.isOnGround then
		v213_ = v213_ * 0.2
	end
	local v214_ = v211_ - v209_.currentSpeed
	local v215_ = -v213_
	local v216_ = math.clamp(v214_, v215_, v213_)
	if v209_.haltTimer <= 0 then
		v209_.currentSpeed = v209_.currentSpeed + v216_
	else
		v209_.currentSpeed = 0
	end
	local v217_ = v209_.currentSpeed * v210_
	if v209_.isOnGround and v209_.currentSpeedY < 0 then
		v209_.currentSpeedY = 0
	end
	local v218_ = v209_.gravity * v210_
	v209_.currentSpeedY = v209_.currentSpeedY + v218_
	local v219_ = v209_.currentSpeedY * v210_
	local v220_ = v209_.topSpeeds[Rideable.GAITTYPES.WALK]
	local v221_ = v209_.topSpeeds[Rideable.GAITTYPES.MAX]
	local v222_ = (v221_ - v209_.currentSpeed) / (v221_ - v220_)
	local v223_ = (math.clamp(v222_, 0, 1) * 0.4 + 0.8) * v210_
	if not v209_.isOnGround then
		v223_ = v223_ * 0.25
	end
	if self.isServer and (not self:getIsEntered() and (not self:getIsControlled() and v209_.inputValues.axisSteer ~= 0)) then
		v209_.inputValues.axisSteer = 0
	end
	local v224_ = v209_.maxTurnSpeed * v209_.inputValues.axisSteer - v209_.currentTurnSpeed
	local v225_ = -v223_
	local v226_ = math.clamp(v224_, v225_, v223_)
	v209_.currentTurnSpeed = v209_.currentTurnSpeed + v226_
	v209_.currentTurnAngle = v209_.currentTurnAngle + v209_.currentTurnSpeed * v210_ * (v217_ >= 0 and 1 or -1)
	local v227_ = v209_.currentTurnAngle
	local v228_ = math.sin(v227_) * v217_
	local v229_ = v209_.currentTurnAngle
	local v230_ = math.cos(v229_) * v217_
	self:moveCCT(v228_, v219_, v230_, true)
	local v231_ = v209_.cctMoveQueue
	local v232_ = {
		["physicsIndex"] = getPhysicsUpdateIndex(),
		["moveX"] = v228_,
		["moveY"] = v219_,
		["moveZ"] = v230_,
		["dt"] = dt
	}
	table.insert(v231_, v232_)
end

-- Local values: spec
function Rideable:groundRaycastCallback(hitObjectId, x, y, z, distance)
	local v237_ = self.spec_rideable
	if hitObjectId == self.spec_cctdrivable.cctNode then
		return true
	end
	if getCollisionFilterMask(hitObjectId) == CollisionFlag.DEFAULT then
		return true
	end
	v237_.groundRaycastResult.y = y
	v237_.groundRaycastResult.object = hitObjectId
	v237_.groundRaycastResult.distance = distance
	return false
end

-- Local values: spec, params, speed, smoothedSpeed, turnSpeed, interpQuat, lastDirX, _, lastDirZ, targetDirX, _, targetDirZ, lastTurnAngle, targetTurnAngle, turnAngleDiff, interpPos, speedY, leftRightWeight, closestGait, closestDiff, i, diff, minTurnRadius, _, parameter, isEntered, isControlled, character, _, parameter
function Rideable:updateAnimation(dt)
	local v240_ = self.spec_rideable
	local v241_ = v240_.animationParameters
	local v242_ = self.lastSignedSpeedReal * 1000
	local v243_ = self.lastSignedSpeed * 1000
	local v244_ = v240_.topSpeeds[Rideable.GAITTYPES.BACKWARDS]
	local v245_ = v240_.topSpeeds[Rideable.GAITTYPES.MAX]
	local v246_ = math.clamp(v242_, v244_, v245_)
	local v247_ = v240_.topSpeeds[Rideable.GAITTYPES.BACKWARDS]
	local v248_ = v240_.topSpeeds[Rideable.GAITTYPES.MAX]
	local v249_ = math.clamp(v243_, v247_, v248_)
	local v250_
	if self.isServer then
		v250_ = (v240_.interpolatorTurnAngle.targetValue - v240_.interpolatorTurnAngle.lastValue) / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	else
		local v251_ = self.components[1].networkInterpolators.quaternion
		local v252_, _, v253_ = mathQuaternionRotateVector(v251_.lastQuaternionX, v251_.lastQuaternionY, v251_.lastQuaternionZ, v251_.lastQuaternionW, 0, 0, 1)
		local v254_, _, v255_ = mathQuaternionRotateVector(v251_.targetQuaternionX, v251_.targetQuaternionY, v251_.targetQuaternionZ, v251_.targetQuaternionW, 0, 0, 1)
		local v256_ = MathUtil.getYRotationFromDirection(v252_, v253_)
		local v257_ = MathUtil.getYRotationFromDirection(v254_, v255_) - v256_
		if v257_ > 3.141592653589793 then
			v257_ = v257_ - 6.283185307179586
		elseif v257_ < -3.141592653589793 then
			v257_ = v257_ + 6.283185307179586
		end
		v250_ = v257_ / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	end
	local v258_ = self.components[1].networkInterpolators.position
	local v259_ = (v258_.targetPositionY - v258_.lastPositionY) / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	local v260_
	if math.abs(v246_) > 0.01 then
		local v261_ = Rideable.GAITTYPES.STILL
		local v262_ = math.huge
		for v263_ = 1, Rideable.GAITTYPES.MAX do
			local v264_ = v246_ - v240_.topSpeeds[v263_]
			local v265_ = math.abs(v264_)
			if v265_ < v262_ then
				v261_ = v263_
				v262_ = v265_
			end
		end
		v260_ = v240_.minTurnRadius[v261_] * v250_ / v246_
	else
		v260_ = v250_ / v240_.maxTurnSpeed
	end
	if v260_ < v240_.smoothedLeftRightWeight then
		local v266_ = v240_.smoothedLeftRightWeight - 0.002 * dt
		v240_.smoothedLeftRightWeight = math.max(v260_, v266_, -1)
	else
		local v267_ = v240_.smoothedLeftRightWeight + 0.002 * dt
		v240_.smoothedLeftRightWeight = math.min(v260_, v267_, 1)
	end
	v241_.forwardVelocity.value = v246_
	v241_.absForwardVelocity.value = math.abs(v246_)
	v241_.verticalVelocity.value = v259_
	v241_.yawVelocity.value = v250_
	v241_.absYawVelocity.value = math.abs(v250_)
	v241_.leftRightWeight.value = v240_.smoothedLeftRightWeight
	v241_.onGround.value = v240_.isOnGround
	v241_.closeToGround.value = v240_.isCloseToGround
	v241_.inWater.value = self.isInWater
	v241_.halted.value = v240_.haltTimer > 0
	v241_.smoothedForwardVelocity.value = v249_
	v241_.absSmoothedForwardVelocity.value = math.abs(v249_)
	if v240_.animationPlayer ~= nil then
		for _, v268_ in pairs(v241_) do
			if v268_.type == 0 then
				setConditionalAnimationBoolValue(v240_.animationPlayer, v268_.id, v268_.value)
			elseif v268_.type == 1 then
				setConditionalAnimationFloatValue(v240_.animationPlayer, v268_.id, v268_.value)
			end
		end
		updateConditionalAnimation(v240_.animationPlayer, dt)
	end
	local v269_
	if self.getIsEntered == nil then
		v269_ = false
	else
		v269_ = self:getIsEntered()
	end
	local v270_
	if self.getIsControlled == nil then
		v270_ = false
	else
		v270_ = self:getIsControlled()
	end
	if v269_ or v270_ then
		local v271_ = self:getVehicleCharacter()
		if v271_ ~= nil and (v271_.animationCharsetId ~= nil and v271_.animationPlayer ~= nil) then
			for _, v272_ in pairs(v241_) do
				if v272_.type == 0 then
					setConditionalAnimationBoolValue(v271_.animationPlayer, v272_.id, v272_.value)
				elseif v272_.type == 1 then
					setConditionalAnimationFloatValue(v271_.animationPlayer, v272_.id, v272_.value)
				end
			end
			updateConditionalAnimation(v271_.animationPlayer, dt)
		end
	end
	self:updateFootsteps(dt, (math.abs(v246_)))
end

-- Local values: spec
function Rideable:updateSound(dt)
	local v275_ = self.spec_rideable
	if v275_.horseBreathSoundsEffort ~= nil and (v275_.horseBreathSoundsNoEffort ~= nil and v275_.isOnGround) then
		v275_.currentBreathTimer = v275_.currentBreathTimer - dt
		local v276_ = v275_.currentBreathTimer
		v275_.currentBreathTimer = math.max(v276_, 0)
		if v275_.currentBreathTimer == 0 then
			if v275_.inputValues.currentGait == Rideable.GAITTYPES.GALLOP then
				g_soundManager:playSample(v275_.horseBreathSoundsEffort)
				v275_.currentBreathTimer = v275_.horseBreathIntervalEffort
				return
			end
			g_soundManager:playSample(v275_.horseBreathSoundsNoEffort)
			if v275_.inputValues.currentGait == Rideable.GAITTYPES.STILL then
				v275_.currentBreathTimer = v275_.horseBreathMinIntervalIdle + math.random() * (v275_.horseBreathMaxIntervalIdle - v275_.horseBreathMinIntervalIdle)
				return
			end
			v275_.currentBreathTimer = v275_.horseBreathIntervalNoEffort
		end
	end
end

-- Local values: spec
function Rideable:setWorldPositionQuat(x, y, z, qx, qy, qz, qw, changeInterp)
	setWorldTranslation(self.rootNode, x, y, z)
	setWorldQuaternion(self.rootNode, qx, qy, qz, qw)
	if changeInterp then
		local v286_ = self.spec_rideable
		v286_.networkInterpolators.position:setPosition(x, y, z)
		v286_.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
	end
end

-- Local values: spec, _, actionEventId
function Rideable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v289_ = self.spec_rideable
		self:clearActionEventsTable(v289_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v290_ = self:addActionEvent(v289_.actionEvents, InputAction.AXIS_ACCELERATE_VEHICLE, self, Rideable.actionEventAccelerate, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v290_, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventTextVisibility(v290_, false)
			v289_.acceletateEventId = v290_
			local _, v291_ = self:addActionEvent(v289_.actionEvents, InputAction.AXIS_BRAKE_VEHICLE, self, Rideable.actionEventBrake, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v291_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventTextVisibility(v291_, false)
			v289_.brakeEventId = v291_
			local _, v292_ = self:addActionEvent(v289_.actionEvents, InputAction.AXIS_MOVE_SIDE_VEHICLE, self, Rideable.actionEventSteer, false, false, true, true, nil)
			g_inputBinding:setActionEventTextVisibility(v292_, false)
			v289_.steerEventId = v292_
			local _, v293_ = self:addActionEvent(v289_.actionEvents, InputAction.JUMP, self, Rideable.actionEventJump, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v293_, GS_PRIO_VERY_LOW)
			g_inputBinding:setActionEventTextVisibility(v293_, false)
			v289_.jumpEventId = v293_
		end
	end
end

-- Local values: spec
function Rideable:onEnterVehicle(isControlling)
	local v295_ = self.spec_rideable
	if self.isClient then
		v295_.playerToEnter = nil
		v295_.checkPlayerToEnter = false
		v295_.currentSpeed = 0
		v295_.currentTurnSpeed = 0
		self:setCurrentGait(Rideable.GAITTYPES.STILL)
		v295_.isOnGround = false
	end
	if self.isServer then
		v295_.lastOwner = self:getOwnerConnection()
		v295_.doHusbandryCheck = 0
	end
end

-- Local values: spec, key, parameter, mission
function Rideable:onVehicleCharacterChanged(character)
	if character ~= nil and self.isClient then
		local v298_ = self.spec_rideable
		link(character.playerModel.thirdPersonLeftHandNode, v298_.leftReinNode)
		link(character.playerModel.thirdPersonRightHandNode, v298_.rightReinNode)
		setVisibility(v298_.reinsNode, true)
		if character ~= nil and (character.animationCharsetId ~= nil and character.animationPlayer ~= nil) then
			for v299_, v300_ in pairs(v298_.animationParameters) do
				conditionalAnimationRegisterParameter(character.animationPlayer, v300_.id, v300_.type, v299_)
			end
			initConditionalAnimation(character.animationPlayer, character.animationCharsetId, self.configFileName, "vehicle.riderConditionalAnimation")
			setConditionalAnimationSpecificParameterIds(character.animationPlayer, v298_.animationParameters.absForwardVelocity.id, v298_.animationParameters.absYawVelocity.id)
			self:setEquipmentVisibility(true)
			conditionalAnimationZeroiseTrackTimes(character.animationPlayer)
			conditionalAnimationZeroiseTrackTimes(v298_.animationPlayer)
		end
		if self:getIsControlled() then
			local v301_ = g_currentMission
			if v301_.hud.fadeScreenElement:getAlpha() > 0 then
				v301_:fadeScreen(-1, v298_.fadeDuration, self.endFade, self)
			end
		end
	end
end

-- Local values: spec, mission
function Rideable:onLeaveVehicle()
	local v303_ = self.spec_rideable
	if self.isClient then
		v303_.inputValues.currentGait = Rideable.GAITTYPES.STILL
		self:resetInputs()
		local v304_ = g_currentMission
		if v304_.hud.fadeScreenElement:getAlpha() > 0 then
			v304_:fadeScreen(-1, v303_.fadeDuration, self.endFade, self)
		end
	end
	if self.isServer then
		v303_.doHusbandryCheck = 5000
	end
	v303_.leaveTimer = 15000
end

-- Local values: spec
function Rideable:unlinkReins()
	if self.isClient then
		local v306_ = self.spec_rideable
		link(v306_.leftReinParentNode, v306_.leftReinNode)
		link(v306_.rightReinParentNode, v306_.rightReinNode)
		setVisibility(v306_.reinsNode, false)
	end
end

-- Local values: spec
function Rideable:setEquipmentVisibility(val)
	if self.isClient then
		local v309_ = self.spec_rideable
		if v309_.equipmentNode ~= nil then
			setVisibility(v309_.equipmentNode, val)
			setVisibility(v309_.reinsNode, val)
		end
	end
end

-- Local values: spec, enterable
function Rideable:actionEventAccelerate(actionName, inputValue, callbackState, isAnalog)
	local v311_ = self.spec_rideable
	local v312_ = self.spec_enterable
	if v312_.isEntered and (v312_.isControlled and (v311_.haltTimer <= 0 and v311_.isOnGround)) then
		local v313_ = self:getCurrentGait() + 1
		local v314_ = Rideable.GAITTYPES.MAX
		self:setCurrentGait((math.min(v313_, v314_)))
	end
end

-- Local values: spec
function Rideable:actionEventBrake(actionName, inputValue, callbackState, isAnalog)
	local v316_ = self.spec_rideable
	if self:getIsEntered() and (v316_.haltTimer <= 0 and v316_.isOnGround) then
		local v317_ = self:getCurrentGait() - 1
		self:setCurrentGait((math.max(v317_, 1)))
	end
end

-- Local values: spec
function Rideable:actionEventSteer(actionName, inputValue, callbackState, isAnalog)
	local v320_ = self.spec_rideable
	if self:getIsEntered() and v320_.haltTimer <= 0 then
		self:setRideableSteer(inputValue)
	end
end

function Rideable:actionEventJump(actionName, inputValue, callbackState, isAnalog)
	if self:getIsRideableJumpAllowed() then
		self:jump()
	end
end

-- Local values: spec, epsilon, dirX, _, dirZ, rotY, k, hoofInfo, posX, posY, posZ, hitTerrain, terrainY, onGround, r, g, b, _, _, sample
function Rideable:updateFootsteps(dt, speed)
	local v324_ = self.spec_rideable
	if speed > 0.001 then
		local v325_, _, v326_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		local v327_ = MathUtil.getYRotationFromDirection(v325_, v326_)
		for _, v328_ in pairs(v324_.hooves) do
			local v329_, v330_, v331_ = getWorldTranslation(v328_.node)
			v324_.groundRaycastResult.object = 0
			v324_.groundRaycastResult.y = v330_ - 1
			raycastClosest(v329_, v330_ + Rideable.GROUND_RAYCAST_OFFSET, v331_, 0, -1, 0, Rideable.GROUND_RAYCAST_MAXDISTANCE, "groundRaycastCallback", self, Rideable.GROUND_RAYCAST_COLLISIONMASK)
			local v332_ = v324_.groundRaycastResult.object == g_terrainNode
			local v333_ = v324_.groundRaycastResult.y
			local v334_ = v330_ - v333_ < 0.05
			if v334_ and not v328_.onGround then
				local v335_, v336_, v337_, _, _ = getTerrainAttributesAtWorldPos(g_terrainNode, v329_, v330_, v331_, true, true, true, true, false)
				v328_.onGround = true
				if v324_.inputValues.currentGait < Rideable.GAITTYPES.CANTER then
					if v328_.psSlow ~= nil and v328_.psSlow.emitterShape ~= nil then
						ParticleUtil.resetNumOfEmittedParticles(v328_.psSlow)
						ParticleUtil.setEmittingState(v328_.psSlow, true)
						setShaderParameter(v328_.psSlow.shape, "psColor", v335_, v336_, v337_, 1, false)
						setWorldTranslation(v328_.psSlow.emitterShape, v329_, v333_, v331_)
						setWorldRotation(v328_.psSlow.emitterShape, 0, v327_, 0)
					end
				elseif v328_.psFast ~= nil and v328_.psFast.emitterShape ~= nil then
					ParticleUtil.resetNumOfEmittedParticles(v328_.psFast)
					ParticleUtil.setEmittingState(v328_.psFast, true)
					setShaderParameter(v328_.psFast.shape, "psColor", v335_, v336_, v337_, 1, false)
					setWorldTranslation(v328_.psFast.emitterShape, v329_, v333_, v331_)
					setWorldRotation(v328_.psSlow.emitterShape, 0, v327_, 0)
				end
				local v338_ = self:getHoofSurfaceSound(v329_, v330_, v331_, v332_)
				if v338_ ~= nil then
					v328_.sampleDebug = string.format("%s - %s", v338_.sampleName, v338_.filename)
					g_soundManager:playSample(v338_)
				end
			elseif not v334_ and v328_.onGround then
				v328_.onGround = false
				if v328_.psSlow ~= nil and v328_.psSlow.emitterShape ~= nil then
					ParticleUtil.setEmittingState(v328_.psSlow, false)
				end
				if v328_.psFast ~= nil and v328_.psFast.emitterShape ~= nil then
					ParticleUtil.setEmittingState(v328_.psFast, false)
				end
			end
		end
	end
end

-- Local values: spec, ridingTime, changeDelta, speedFactor, gaitType, distance
function Rideable:updateRiding(dt)
	local v341_ = self.spec_rideable
	if v341_.cluster ~= nil and v341_.currentSpeed ~= 0 then
		local v342_ = v341_.cluster:getDailyRidingTime() / 100
		local v343_ = v341_.inputValues.currentGait
		local v344_ = v343_ == Rideable.GAITTYPES.CANTER and 2 or (v343_ == Rideable.GAITTYPES.GALLOP and 3 or 1)
		v341_.ridingTimer = v341_.ridingTimer + dt * v344_
		if v342_ < v341_.ridingTimer then
			v341_.ridingTimer = 0
			v341_.cluster:changeRiding(1)
			v341_.cluster:changeDirt(1)
		end
		if self.lastMovedDistance > 0.001 then
			local v345_ = self.lastMovedDistance * 0.001
			g_farmManager:updateFarmStats(self:getOwnerFarmId(), "horseDistance", v345_)
		end
		self:updateDirt()
	end
end

-- Local values: spec, mission, snowHeight, isOnField, _, _, _, _, _, materialId
function Rideable:getHoofSurfaceSound(x, y, z, hitTerrain)
	local v351_ = self.spec_rideable
	if not hitTerrain then
		return v351_.surfaceNameToSound.asphalt
	end
	if g_currentMission.snowSystem:getSnowHeightAtArea(x, z, x + 0.1, z + 0.1, x + 0.1, z) > 0 then
		return v351_.surfaceNameToSound.snow
	end
	local v352_, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
	if v352_ then
		return v351_.surfaceNameToSound.field
	end
	if self.isInShallowWater then
		return v351_.surfaceNameToSound.shallowWater
	end
	if self.isInMediumWater then
		return v351_.surfaceNameToSound.mediumWater
	end
	local _, _, _, _, v353_ = getTerrainAttributesAtWorldPos(g_terrainNode, x, y, z, true, true, true, true, false)
	return v351_.surfaceIdToSound[v353_]
end

function Rideable:getPosition()
	return getWorldTranslation(self.rootNode)
end

function Rideable:getRotation()
	return getWorldRotation(self.rootNode)
end

-- Local values: spec
function Rideable:setPlayerToEnter(player)
	local v358_ = self.spec_rideable
	v358_.playerToEnter = player
	v358_.checkPlayerToEnter = true
	self:raiseActive()
end

-- Local values: spec
function Rideable:getName(superFunc)
	return self.spec_rideable.cluster:getName()
end

function Rideable:getFullName(superFunc)
	return self:getName()
end

function Rideable:getCanBeReset(superFunc)
	return false
end

function Rideable:getCanBeSold(superFunc)
	return false
end

function Rideable:getMapHotspotRotation(superFunc, isPlayerHotspot)
	return not isPlayerHotspot and 0 or superFunc(self, isPlayerHotspot)
end

function Rideable:getShowInVehiclesOverview(superFunc)
	return false
end

-- Local values: spec
function Rideable:periodChanged(superFunc)
	superFunc(self)
	local v366_ = self.spec_rideable
	if v366_.cluster ~= nil then
		v366_.cluster:onPeriodChanged()
	end
end

-- Local values: spec
function Rideable:dayChanged(superFunc)
	superFunc(self)
	local v369_ = self.spec_rideable
	if v369_.cluster ~= nil then
		v369_.cluster:onDayChanged()
	end
end

-- Local values: imageFilename, cluster, mission, visual
function Rideable:getImageFilename(superFunc)
	local v372_ = superFunc(self)
	local v373_ = self:getCluster()
	if v373_ ~= nil then
		v372_ = g_currentMission.animalSystem:getVisualByAge(v373_.subTypeIndex, v373_:getAge()).store.imageFilename
	end
	return v372_
end

function Rideable:deleteVehicleCharacter(superFunc)
	self:setEquipmentVisibility(false)
	self:unlinkReins()
	superFunc(self)
end

-- Local values: spec, enterText
function Rideable:getInteractionHelp(superFunc)
	if self.interactionFlag ~= Vehicle.INTERACTION_FLAG_ENTERABLE then
		return superFunc(self)
	end
	local v378_ = self.spec_rideable
	return string.format(g_i18n:getText("action_rideAnimal"), v378_.cluster:getName())
end

-- Local values: spec
function Rideable:showInfo(superFunc, box)
	local v382_ = self.spec_rideable
	if v382_.cluster ~= nil then
		v382_.cluster:showInfo(box)
	end
	superFunc(self, box)
end

-- Local values: spec, k, hoofInfo
function Rideable:updateDebugValues(values)
	local v385_ = self.spec_rideable
	for v386_, v387_ in pairs(v385_.hooves) do
		local v388_ = {
			["name"] = "hoof sample " .. v386_,
			["value"] = v387_.sampleDebug
		}
		table.insert(values, v388_)
	end
end

-- Local values: spec
function Rideable:updateInputText()
	local v390_ = self.spec_rideable
	if v390_.inputValues.currentGait == Rideable.GAITTYPES.BACKWARDS then
		g_inputBinding:setActionEventText(v390_.acceletateEventId, g_i18n:getText("action_stop"))
		g_inputBinding:setActionEventActive(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventActive(v390_.brakeEventId, false)
		g_inputBinding:setActionEventTextVisibility(v390_.brakeEventId, false)
		g_inputBinding:setActionEventActive(v390_.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(v390_.jumpEventId, false)
		return
	elseif v390_.inputValues.currentGait == Rideable.GAITTYPES.STILL then
		g_inputBinding:setActionEventText(v390_.acceletateEventId, g_i18n:getText("action_walk"))
		g_inputBinding:setActionEventActive(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventText(v390_.brakeEventId, g_i18n:getText("action_walkBackwards"))
		g_inputBinding:setActionEventActive(v390_.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.brakeEventId, true)
		g_inputBinding:setActionEventActive(v390_.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(v390_.jumpEventId, false)
		return
	elseif v390_.inputValues.currentGait == Rideable.GAITTYPES.WALK then
		g_inputBinding:setActionEventText(v390_.acceletateEventId, g_i18n:getText("action_trot"))
		g_inputBinding:setActionEventActive(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventText(v390_.brakeEventId, g_i18n:getText("action_stop"))
		g_inputBinding:setActionEventActive(v390_.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.brakeEventId, true)
		g_inputBinding:setActionEventActive(v390_.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(v390_.jumpEventId, false)
		return
	elseif v390_.inputValues.currentGait == Rideable.GAITTYPES.TROT then
		g_inputBinding:setActionEventText(v390_.acceletateEventId, g_i18n:getText("action_canter"))
		g_inputBinding:setActionEventActive(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventText(v390_.brakeEventId, g_i18n:getText("action_walk"))
		g_inputBinding:setActionEventActive(v390_.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.brakeEventId, true)
		g_inputBinding:setActionEventActive(v390_.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(v390_.jumpEventId, false)
		return
	elseif v390_.inputValues.currentGait == Rideable.GAITTYPES.CANTER then
		g_inputBinding:setActionEventText(v390_.acceletateEventId, g_i18n:getText("action_gallop"))
		g_inputBinding:setActionEventActive(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.acceletateEventId, true)
		g_inputBinding:setActionEventText(v390_.brakeEventId, g_i18n:getText("action_trot"))
		g_inputBinding:setActionEventActive(v390_.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.brakeEventId, true)
		g_inputBinding:setActionEventText(v390_.jumpEventId, g_i18n:getText("input_JUMP"))
		g_inputBinding:setActionEventActive(v390_.jumpEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.jumpEventId, true)
	elseif v390_.inputValues.currentGait == Rideable.GAITTYPES.GALLOP then
		g_inputBinding:setActionEventActive(v390_.acceletateEventId, false)
		g_inputBinding:setActionEventTextVisibility(v390_.acceletateEventId, false)
		g_inputBinding:setActionEventText(v390_.brakeEventId, g_i18n:getText("action_canter"))
		g_inputBinding:setActionEventActive(v390_.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.brakeEventId, true)
		g_inputBinding:setActionEventText(v390_.jumpEventId, g_i18n:getText("input_JUMP"))
		g_inputBinding:setActionEventActive(v390_.jumpEventId, true)
		g_inputBinding:setActionEventTextVisibility(v390_.jumpEventId, true)
	end
end
