Rideable = {}
source("dataS/scripts/vehicles/specializations/events/JumpEvent.lua")
source("dataS/scripts/vehicles/specializations/events/RideableStableNotificationEvent.lua")
Rideable.GAITTYPES = { MIN = 1, BACKWARDS = 1, STILL = 2, WALK = 3, TROT = 4, CANTER = 5, GALLOP = 6, MAX = 6 }
Rideable.HOOVES = { FRONT_LEFT = 1, FRONT_RIGHT = 2, BACK_LEFT = 3, BACK_RIGHT = 4 }
Rideable.GROUND_RAYCAST_OFFSET = 1.2
Rideable.GROUND_RAYCAST_MAXDISTANCE = 5
Rideable.GROUND_RAYCAST_COLLISIONMASK = CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.ROAD + CollisionFlag.STATIC_OBJECT
function Rideable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(CCTDrivable, specializations)
end
function Rideable.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("Rideable")
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#speedBackwards", "Backward speed", -1)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#speedWalk", "Walk speed", 2.5)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#speedCanter", "Canter speed", 3.5)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#speedTrot", "Trot speed", 5)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#speedGallop", "Gallop speed", 10)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusBackwards", "Min turning radius backward", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusWalk", "Min turning radius walk", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusCanter", "Min turning radius canter", 2.5)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusTrot", "Min turning radius trot", 5)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#minTurnRadiusGallop", "Min turning radius gallop", 10)
	schema:register(XMLValueType.ANGLE, "vehicle.rideable#turnSpeed", "Turn speed (deg/s)", 45)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable#jumpHeight", "Jump height", 2)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable#proxy", "Proxy node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontLeft#node", "Hoof node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemSlow#node", "Slow step particle emitterShape")
	schema:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemSlow#particleType", "Slow step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemSlow")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemFast#node", "Fast step particle emitterShape")
	schema:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemFast#particleType", "Fast step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "vehicle.rideable.modelInfo.hoofFrontLeft.particleSystemFast")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontRight#node", "Hoof node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemSlow#node", "Slow step particle emitterShape")
	schema:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemSlow#particleType", "Slow step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemSlow")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemFast#node", "Fast step particle emitterShape")
	schema:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemFast#particleType", "Fast step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "vehicle.rideable.modelInfo.hoofFrontRight.particleSystemFast")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackLeft#node", "Hoof node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemSlow#node", "Slow step particle emitterShape")
	schema:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemSlow#particleType", "Slow step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemSlow")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemFast#node", "Fast step particle emitterShape")
	schema:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemFast#particleType", "Fast step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "vehicle.rideable.modelInfo.hoofBackLeft.particleSystemFast")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackRight#node", "Hoof node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemSlow#node", "Slow step particle emitterShape")
	schema:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemSlow#particleType", "Slow step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemSlow")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemFast#node", "Fast step particle emitterShape")
	schema:register(XMLValueType.STRING, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemFast#particleType", "Fast step particle type")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "vehicle.rideable.modelInfo.hoofBackRight.particleSystemFast")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#animationNode", "Animation node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#meshNode", "Mesh node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#equipmentNode", "Equipment node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#reinsNode", "Reins node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#reinLeftNode", "Rein left node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.rideable.modelInfo#reinRightNode", "Rein right node")
	schema:register(XMLValueType.FLOAT, "vehicle.rideable.sounds#breathIntervalNoEffort", "Breath interval no effort", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable.sounds#breathIntervalEffort", "Breath interval effort", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable.sounds#minBreathIntervalIdle", "Min. breath interval idle", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.rideable.sounds#maxBreathIntervalIdle", "Max. breath interval idle", 1)
	SoundManager.registerSampleXMLPaths(schema, "vehicle.rideable.sounds", "halt")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.rideable.sounds", "breathingNoEffort")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.rideable.sounds", "breathingEffort")
	ConditionalAnimation.registerXMLPaths(schema, "vehicle.conditionalAnimation")
	ConditionalAnimation.registerXMLPaths(schema, "vehicle.riderConditionalAnimation")
	schema:setXMLSpecializationType()
	local savegameSchema = Vehicle.xmlSchemaSavegame
	savegameSchema:register(XMLValueType.STRING, "vehicles.vehicle(?).rideable#animalType", "Animal type name")
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
function Rideable:onLoad(savegame)
	local spec = self.spec_rideable
	self.highPrecisionPositionSynchronization = true
	spec.leaveTimer = 15000
	spec.currentDirtScale = 0
	spec.abandonTimerDuration = g_gameSettings:getValue(GameSettings.SETTING.HORSE_ABANDON_TIMER_DURATION)
	spec.abandonTimer = spec.abandonTimerDuration
	spec.fadeDuration = 400
	spec.isRideableRemoved = false
	spec.justSpawned = true
	spec.meshNode = nil
	spec.animationNode = nil
	spec.charsetId = nil
	spec.animationPlayer = nil
	spec.animationParameters = {}
	spec.animationParameters.forwardVelocity = { id = 1, value = 0, type = 1 }
	spec.animationParameters.verticalVelocity = { id = 2, value = 0, type = 1 }
	spec.animationParameters.yawVelocity = { id = 3, value = 0, type = 1 }
	spec.animationParameters.absForwardVelocity = { id = 4, value = 0, type = 1 }
	spec.animationParameters.onGround = { id = 5, value = false, type = 0 }
	spec.animationParameters.inWater = { id = 6, value = false, type = 0 }
	spec.animationParameters.closeToGround = { id = 7, value = false, type = 0 }
	spec.animationParameters.leftRightWeight = { id = 8, value = 0, type = 1 }
	spec.animationParameters.absYawVelocity = { id = 9, value = 0, type = 1 }
	spec.animationParameters.halted = { id = 10, value = false, type = 0 }
	spec.animationParameters.smoothedForwardVelocity = { id = 11, value = 0, type = 1 }
	spec.animationParameters.absSmoothedForwardVelocity = { id = 12, value = 0, type = 1 }
	spec.acceletateEventId = ""
	spec.brakeEventId = ""
	spec.steerEventId = ""
	spec.jumpEventId = ""
	spec.currentTurnAngle = 0
	spec.currentTurnSpeed = 0
	spec.currentSpeed = 0
	spec.currentSpeedY = 0
	spec.cctMoveQueue = {}
	spec.currentCCTPosX = 0
	spec.currentCCTPosY = 0
	spec.currentCCTPosZ = 0
	spec.lastCCTPosX = 0
	spec.lastCCTPosY = 0
	spec.lastCCTPosZ = 0
	spec.topSpeeds = {}
	spec.topSpeeds[Rideable.GAITTYPES.BACKWARDS] = self.xmlFile:getValue("vehicle.rideable#speedBackwards", -1)
	spec.topSpeeds[Rideable.GAITTYPES.STILL] = 0
	spec.topSpeeds[Rideable.GAITTYPES.WALK] = self.xmlFile:getValue("vehicle.rideable#speedWalk", 2.5)
	spec.topSpeeds[Rideable.GAITTYPES.CANTER] = self.xmlFile:getValue("vehicle.rideable#speedCanter", 3.5)
	spec.topSpeeds[Rideable.GAITTYPES.TROT] = self.xmlFile:getValue("vehicle.rideable#speedTrot", 5)
	spec.topSpeeds[Rideable.GAITTYPES.GALLOP] = self.xmlFile:getValue("vehicle.rideable#speedGallop", 10)
	spec.minTurnRadius = {}
	spec.minTurnRadius[Rideable.GAITTYPES.BACKWARDS] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusBackwards", 1)
	spec.minTurnRadius[Rideable.GAITTYPES.STILL] = 1
	spec.minTurnRadius[Rideable.GAITTYPES.WALK] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusWalk", 1)
	spec.minTurnRadius[Rideable.GAITTYPES.CANTER] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusCanter", 2.5)
	spec.minTurnRadius[Rideable.GAITTYPES.TROT] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusTrot", 5)
	spec.minTurnRadius[Rideable.GAITTYPES.GALLOP] = self.xmlFile:getValue("vehicle.rideable#minTurnRadiusGallop", 10)
	spec.groundRaycastResult = {}
	spec.groundRaycastResult.y = 0
	spec.groundRaycastResult.object = nil
	spec.groundRaycastResult.distance = 0
	spec.haltTimer = 0
	spec.smoothedLeftRightWeight = 0
	spec.interpolationDt = 16
	spec.ridingTimer = 0
	spec.doHusbandryCheck = 0
	spec.proxy = self.xmlFile:getValue("vehicle.rideable#proxy", nil, self.components, self.i3dMappings)
	if spec.proxy ~= nil then
		setRigidBodyType(spec.proxy, RigidBodyType.NONE)
	end
	spec.collisionMask = getCollisionFilterMask(self.components[1].node)
	spec.maxAcceleration = 5
	spec.maxDeceleration = 10
	spec.gravity = -9.81
	spec.frontCheckDistance = 0
	spec.backCheckDistance = 0
	spec.isOnGround = true
	spec.isCloseToGround = true
	assert(spec.topSpeeds[Rideable.GAITTYPES.MIN] < spec.topSpeeds[Rideable.GAITTYPES.MAX])
	spec.maxTurnSpeed = self.xmlFile:getValue("vehicle.rideable#turnSpeed", 45)
	spec.jumpHeight = self.xmlFile:getValue("vehicle.rideable#jumpHeight", 2)
	local loadHoof = function(target, index, key)
		local hoof = {}
		hoof.node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		hoof.onGround = false
		local nodeSlow = self.xmlFile:getValue(key .. ".particleSystemSlow#node", nil, self.components, self.i3dMappings)
		local particleType = self.xmlFile:getValue(key .. ".particleSystemSlow#particleType")
		if particleType == nil then
			Logging.xmlWarning(self.xmlFile, "Missing horse step slow particleType in '%s'", key .. ".particleSystemSlow")
			return
		end
		local particleSystem = g_particleSystemManager:getParticleSystem(particleType)
		if particleSystem ~= nil then
			hoof.psSlow = ParticleUtil.copyParticleSystem(self.xmlFile, key .. ".particleSystemSlow", particleSystem, nodeSlow)
			link(getRootNode(), hoof.psSlow.emitterShape)
		end
		local nodeFast = self.xmlFile:getValue(key .. ".particleSystemFast#node", nil, self.components, self.i3dMappings)
		local particleTypeFast = self.xmlFile:getValue(key .. ".particleSystemFast#particleType")
		if particleTypeFast == nil then
			Logging.xmlWarning(self.xmlFile, "Missing horse step fast particleType in '%s'", key .. ".particleSystemFast")
		else
			local particleSystemFast = g_particleSystemManager:getParticleSystem(particleTypeFast)
			if particleSystemFast ~= nil then
				hoof.psFast = ParticleUtil.copyParticleSystem(self.xmlFile, key .. ".particleSystemFast", particleSystemFast, nodeFast)
				link(getRootNode(), hoof.psFast.emitterShape)
			end
			target[index] = hoof
		end
	end
	spec.hooves = {}
	loadHoof(spec.hooves, Rideable.HOOVES.FRONT_LEFT, "vehicle.rideable.modelInfo.hoofFrontLeft")
	loadHoof(spec.hooves, Rideable.HOOVES.FRONT_RIGHT, "vehicle.rideable.modelInfo.hoofFrontRight")
	loadHoof(spec.hooves, Rideable.HOOVES.BACK_LEFT, "vehicle.rideable.modelInfo.hoofBackLeft")
	loadHoof(spec.hooves, Rideable.HOOVES.BACK_RIGHT, "vehicle.rideable.modelInfo.hoofBackRight")
	spec.frontCheckDistance = self:calculateLegsDistance(spec.hooves[Rideable.HOOVES.FRONT_LEFT].node, spec.hooves[Rideable.HOOVES.FRONT_RIGHT].node)
	spec.backCheckDistance = self:calculateLegsDistance(spec.hooves[Rideable.HOOVES.BACK_LEFT].node, spec.hooves[Rideable.HOOVES.BACK_RIGHT].node)
	spec.animationNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#animationNode", nil, self.components, self.i3dMappings)
	spec.meshNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#meshNode", nil, self.components, self.i3dMappings)
	spec.equipmentNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#equipmentNode", nil, self.components, self.i3dMappings)
	spec.reinsNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#reinsNode", nil, self.components, self.i3dMappings)
	spec.leftReinNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#reinLeftNode", nil, self.components, self.i3dMappings)
	spec.rightReinNode = self.xmlFile:getValue("vehicle.rideable.modelInfo#reinRightNode", nil, self.components, self.i3dMappings)
	spec.leftReinParentNode = getParent(spec.leftReinNode)
	spec.rightReinParentNode = getParent(spec.rightReinNode)
	if spec.animationNode ~= nil then
		spec.charsetId = getAnimCharacterSet(spec.animationNode)
		local animationPlayer = createConditionalAnimation()
		if animationPlayer ~= 0 then
			spec.animationPlayer = animationPlayer
			for key, parameter in pairs(spec.animationParameters) do
				conditionalAnimationRegisterParameter(spec.animationPlayer, parameter.id, parameter.type, key)
			end
			initConditionalAnimation(spec.animationPlayer, spec.charsetId, self.configFileName, "vehicle.conditionalAnimation")
			setConditionalAnimationSpecificParameterIds(spec.animationPlayer, spec.animationParameters.absForwardVelocity.id, spec.animationParameters.absYawVelocity.id)
		end
	end
	spec.surfaceSounds = {}
	spec.surfaceIdToSound = {}
	spec.surfaceNameToSound = {}
	spec.currentSurfaceSound = nil
	local mission = g_currentMission
	for _, surfaceSound in pairs(mission.surfaceSounds) do
		if surfaceSound.type == "hoofstep" then
			if surfaceSound.sample == nil then
				continue
			end
			local sample = g_soundManager:cloneSample(surfaceSound.sample, self.components[1].node, self)
			sample.sampleName = surfaceSound.name
			table.insert(spec.surfaceSounds, sample)
			spec.surfaceIdToSound[surfaceSound.materialId] = sample
			spec.surfaceNameToSound[surfaceSound.name] = sample
		end
	end
	spec.horseStopSound = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "halt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	spec.horseBreathSoundsNoEffort = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "breathingNoEffort", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	spec.horseBreathSoundsEffort = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "breathingEffort", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	spec.horseBreathIntervalNoEffort = self.xmlFile:getValue("vehicle.rideable.sounds#breathIntervalNoEffort", 1) * 1000
	spec.horseBreathIntervalEffort = self.xmlFile:getValue("vehicle.rideable.sounds#breathIntervalEffort", 1) * 1000
	spec.horseBreathMinIntervalIdle = self.xmlFile:getValue("vehicle.rideable.sounds#minBreathIntervalIdle", 1) * 1000
	spec.horseBreathMaxIntervalIdle = self.xmlFile:getValue("vehicle.rideable.sounds#maxBreathIntervalIdle", 1) * 1000
	spec.currentBreathTimer = 0
	spec.inputValues = {}
	spec.inputValues.axisSteer = 0
	spec.inputValues.axisSteerSend = 0
	spec.inputValues.currentGait = Rideable.GAITTYPES.STILL
	self:resetInputs()
	spec.interpolatorIsOnGround = InterpolatorValue.new(0)
	if self.isServer then
		spec.interpolatorTurnAngle = InterpolatorAngle.new(0)
		self.networkTimeInterpolator.maxInterpolationAlpha = 1.2
	end
	spec.dirtyFlag = self:getNextDirtyFlag()
	if savegame ~= nil then
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".rideable"
		local subTypeName = xmlFile:getString(key .. "#subType", "HORSE_GRAY")
		local subType = mission.animalSystem:getSubTypeByName(subTypeName)
		if subType ~= nil then
			local cluster = mission.animalSystem:createClusterFromSubTypeIndex(subType.subTypeIndex)
			cluster:loadFromXMLFile(xmlFile, key .. ".animal")
			self:setCluster(cluster)
		else
			Logging.xmlError(self.xmlFile, "Animal sub type '%s' not found for '%s'!", subTypeName, key)
			self:setLoadingState(VehicleLoadingState.ERROR)
			return
		end
	end
	mission.husbandrySystem:addRideable(self)
	self.needWaterInfo = true
end
function Rideable:onLoadFinished()
	self:raiseActive()
end
function Rideable:setWorldPosition(superFunc, x, y, z, xRot, yRot, zRot, i, changeInterp)
	superFunc(self, x, y, z, xRot, yRot, zRot, i, changeInterp)
	if self.isServer and i == 1 then
		local spec = self.spec_rideable
		local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
		spec.currentTurnAngle = MathUtil.getYRotationFromDirection(dx, dz)
		if changeInterp then
			spec.interpolatorTurnAngle:setAngle(spec.currentTurnAngle)
		end
	end
end
function Rideable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
	superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
	if self.isServer and i == 1 then
		local spec = self.spec_rideable
		local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
		spec.currentTurnAngle = MathUtil.getYRotationFromDirection(dx, dz)
		if changeInterp then
			spec.interpolatorTurnAngle:setAngle(spec.currentTurnAngle)
		end
	end
end
function Rideable:updateVehicleSpeed(superFunc, dt)
	if self.isServer then
		local spec = self.spec_rideable
		superFunc(self, spec.interpolationDt)
	else
		superFunc(self, dt)
	end
end
function Rideable:calculateLegsDistance(leftLegNode, rightLegNode)
	local distance = 0
	if leftLegNode ~= nil and rightLegNode ~= nil then
		local _, _, dzL = localToLocal(leftLegNode, self.rootNode, 0, 0, 0)
		local _, _, dzR = localToLocal(rightLegNode, self.rootNode, 0, 0, 0)
		distance = (dzL + dzR) * 0.5
	end
	return distance
end
function Rideable:onDelete()
	local spec = self.spec_rideable
	local mission = g_currentMission
	mission.husbandrySystem:removeRideable(self)
	g_soundManager:deleteSamples(spec.surfaceSounds)
	g_soundManager:deleteSample(spec.horseStopSound)
	g_soundManager:deleteSample(spec.horseBreathSoundsNoEffort)
	g_soundManager:deleteSample(spec.horseBreathSoundsEffort)
	if spec.hooves ~= nil then
		for _, d in pairs(spec.hooves) do
			if d.psSlow ~= nil then
				ParticleUtil.deleteParticleSystem(d.psSlow)
				delete(d.psSlow.emitterShape)
			end
			if d.psFast == nil then
				continue
			end
			ParticleUtil.deleteParticleSystem(d.psFast)
			delete(d.psFast.emitterShape)
		end
	end
	if spec.animationPlayer ~= nil then
		delete(spec.animationPlayer)
		spec.animationPlayer = nil
	end
end
function Rideable:onReadStream(streamId, connection)
	local spec = self.spec_rideable
	if connection:getIsServer() then
		local isOnGround = streamReadBool(streamId)
		if isOnGround then
			spec.interpolatorIsOnGround:setValue(1)
		else
			spec.interpolatorIsOnGround:setValue(0)
		end
	end
	if streamReadBool(streamId) then
		local subTypeIndex = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_SUB_TYPE)
		local mission = g_currentMission
		local cluster = mission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
		cluster:readStream(streamId, connection)
		self:setCluster(cluster)
	end
	if streamReadBool(streamId) then
		local player = NetworkUtil.readNodeObject(streamId)
		self:setPlayerToEnter(player)
	end
end
function Rideable:onWriteStream(streamId, connection)
	local spec = self.spec_rideable
	if not connection:getIsServer() then
		streamWriteBool(streamId, spec.isOnGround)
	end
	if streamWriteBool(streamId, spec.cluster ~= nil) then
		streamWriteUIntN(streamId, spec.cluster:getSubTypeIndex(), AnimalCluster.NUM_BITS_SUB_TYPE)
		spec.cluster:writeStream(streamId, connection)
	end
	if streamWriteBool(streamId, spec.playerToEnter ~= nil) then
		NetworkUtil.writeNodeObject(streamId, spec.playerToEnter)
	end
end
function Rideable:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_rideable
	if not connection:getIsServer() then
		spec.inputValues.axisSteer = streamReadFloat32(streamId)
		spec.inputValues.currentGait = streamReadUInt8(streamId)
	else
		spec.haltTimer = streamReadFloat32(streamId)
		if 0 < spec.haltTimer then
			spec.inputValues.currentGait = Rideable.GAITTYPES.STILL
			spec.inputValues.axisSteerSend = 0
		end
		if streamReadBool(streamId) then
			spec.cluster:readUpdateStream(streamId, connection)
			self:updateDirt()
		end
	end
end
function Rideable:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_rideable
	if connection:getIsServer() then
		streamWriteFloat32(streamId, spec.inputValues.axisSteerSend)
		streamWriteUInt8(streamId, spec.inputValues.currentGait)
	else
		streamWriteFloat32(streamId, spec.haltTimer)
		if streamWriteBool(streamId, spec.cluster ~= nil) then
			spec.cluster:writeUpdateStream(streamId, connection)
		end
	end
end
function Rideable:onReadPositionUpdateStream(streamId, connection)
	local spec = self.spec_rideable
	local isOnGround = streamReadBool(streamId)
	if isOnGround then
		spec.interpolatorIsOnGround:setValue(1)
	else
		spec.interpolatorIsOnGround:setValue(0)
	end
end
function Rideable:onWritePositionUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_rideable
	streamWriteBool(streamId, spec.isOnGround)
end
function Rideable:endFade() end
function Rideable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_rideable
	if spec.cluster ~= nil then
		local mission = g_currentMission
		local animalSystem = mission.animalSystem
		local subTypeIndex = spec.cluster:getSubTypeIndex()
		local subType = animalSystem:getSubTypeByIndex(subTypeIndex)
		xmlFile:setString(key .. "#subType", subType.name)
		spec.cluster:saveToXMLFile(xmlFile, key .. ".animal", usedModNames)
	end
end
function Rideable:setCluster(cluster)
	local spec = self.spec_rideable
	spec.cluster = cluster
	if cluster ~= nil then
		local mission = g_currentMission
		local animalSystem = mission.animalSystem
		local subTypeIndex = cluster:getSubTypeIndex()
		local visual = animalSystem:getVisualByAge(subTypeIndex, cluster:getAge())
		local variation = visual.visualAnimal.variations[1]
		local tileU = variation.tileUIndex / variation.numTilesU
		local tileV = variation.tileVIndex / variation.numTilesV
		I3DUtil.setShaderParameterRec(spec.meshNode, "atlasInvSizeAndOffsetUV", nil, nil, tileU, tileV)
		self:updateDirt()
	end
end
function Rideable:updateDirt()
	local spec = self.spec_rideable
	local cluster = spec.cluster
	local dirtFactor = 0
	if Platform.gameplay.needHorseCleaning and (cluster ~= nil and cluster.getDirtFactor ~= nil) then
		dirtFactor = cluster:getDirtFactor()
	end
	I3DUtil.setShaderParameterRec(spec.meshNode, "dirt", dirtFactor, nil, nil, nil)
end
function Rideable:getCluster()
	return self.spec_rideable.cluster
end
function Rideable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_rideable
	if self:getIsSynchronized() and (spec.playerToEnter ~= nil and (spec.checkPlayerToEnter and spec.playerToEnter == g_localPlayer)) then
		g_localPlayer:requestToEnterVehicle(self, true)
		spec.checkPlayerToEnter = false
	end
	local isEntered = self:getIsEntered()
	if isEntered then
		if isActiveForInputIgnoreSelection then
			self:updateInputText()
		end
		if not self.isServer then
			spec.inputValues.axisSteerSend = spec.inputValues.axisSteer
			self:raiseDirtyFlags(spec.dirtyFlag)
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
	if 0 < spec.haltTimer then
		self:setCurrentGait(Rideable.GAITTYPES.STILL)
		spec.haltTimer = spec.haltTimer - dt
	end
	if self:getIsActiveForInput(true) then
		local inputHelpMode = g_inputBinding:getInputHelpMode()
		if (inputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD or GS_PLATFORM_SWITCH) and g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) then
			local dx, dy, dz = getGravityDirection()
			local steeringValue = MathUtil.getSteeringAngleFromDeviceGravity(dx, dy, dz)
			self:setRideableSteer(steeringValue)
		end
	end
	if self.isServer and 0 < spec.doHusbandryCheck then
		spec.doHusbandryCheck = spec.doHusbandryCheck - dt
		local mission = g_currentMission
		local isInRange, husbandry = mission.husbandrySystem:getHusbandryInRideableRange(self)
		if isInRange then
			local isInStable = nil
			if husbandry ~= nil then
				local cluster = self:getCluster()
				husbandry:addCluster(cluster)
				self:delete()
				isInStable = true
			else
				isInStable = false
			end
			if spec.lastOwner ~= nil then
				spec.lastOwner:sendEvent(RideableStableNotificationEvent.new(isInStable, spec.cluster:getName()), nil, true)
			end
		end
		spec.lastOwner = nil
	end
end
function Rideable:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_rideable
	if self.isServer then
		if not self:getIsControlled() then
			self:setCurrentGait(Rideable.GAITTYPES.STILL)
		end
		local interpolationDt = dt
		local oldestMoveInfo = spec.cctMoveQueue[1]
		if oldestMoveInfo ~= nil and getIsPhysicsUpdateIndexSimulated(oldestMoveInfo.physicsIndex) then
			interpolationDt = oldestMoveInfo.dt
		end
		spec.interpolationDt = interpolationDt
		self:testCCTMove(interpolationDt)
		self:updateKinematic(dt)
		if self:getIsEntered() then
			self:resetInputs()
		end
		local component = self.components[1]
		local x, y, z = self:getCCTWorldTranslation()
		component.networkInterpolators.position:setTargetPosition(x, y, z)
		spec.interpolatorTurnAngle:setTargetAngle(spec.currentTurnAngle)
		spec.interpolatorIsOnGround:setTargetValue(self:getIsCCTOnGround() and 1 or 0)
		local phaseDuration = interpolationDt + 30
		self.networkTimeInterpolator:startNewPhase(phaseDuration)
		self.networkTimeInterpolator:update(interpolationDt)
		x, y, z = component.networkInterpolators.position:getInterpolatedValues(self.networkTimeInterpolator.interpolationAlpha)
		setTranslation(self.rootNode, x, y, z)
		local turnAngle = spec.interpolatorTurnAngle:getInterpolatedValue(self.networkTimeInterpolator.interpolationAlpha)
		local _, dirY, _ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		local dirX = math.sin(turnAngle)
		local dirZ = math.cos(turnAngle)
		local scale = math.sqrt(1 - math.min(dirY * dirY, 0.9))
		dirX = dirX * scale
		dirZ = dirZ * scale
		setDirection(self.rootNode, dirX, dirY, dirZ, 0, 1, 0)
	end
	if not self:getIsEntered() and 0 < spec.leaveTimer then
		spec.leaveTimer = spec.leaveTimer - dt
		self:raiseActive()
	end
	local isOnGroundFloat = spec.interpolatorIsOnGround:getInterpolatedValue(self.networkTimeInterpolator:getAlpha())
	spec.isOnGround = 0.9 < isOnGroundFloat
	spec.isCloseToGround = false
	if spec.isOnGround and (0.001 < math.abs(spec.currentSpeed) or 0.001 < math.abs(spec.currentTurnSpeed)) then
		local posX, posY, posZ = getWorldTranslation(self.rootNode)
		local dirX, dirY, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		local fx = posX + dirX * spec.frontCheckDistance
		local fy = posY + dirY * spec.frontCheckDistance
		local fz = posZ + dirZ * spec.frontCheckDistance
		spec.groundRaycastResult.y = fy + Rideable.GROUND_RAYCAST_OFFSET - Rideable.GROUND_RAYCAST_MAXDISTANCE
		raycastAll(fx, fy + Rideable.GROUND_RAYCAST_OFFSET, fz, 0, -1, 0, Rideable.GROUND_RAYCAST_MAXDISTANCE, "groundRaycastCallback", self, Rideable.GROUND_RAYCAST_COLLISIONMASK)
		fy = spec.groundRaycastResult.y
		local bx = posX + dirX * spec.backCheckDistance
		local by = posY + dirY * spec.backCheckDistance
		local bz = posZ + dirZ * spec.backCheckDistance
		spec.groundRaycastResult.y = by + Rideable.GROUND_RAYCAST_OFFSET - Rideable.GROUND_RAYCAST_MAXDISTANCE
		raycastAll(bx, by + Rideable.GROUND_RAYCAST_OFFSET, bz, 0, -1, 0, Rideable.GROUND_RAYCAST_MAXDISTANCE, "groundRaycastCallback", self, Rideable.GROUND_RAYCAST_COLLISIONMASK)
		by = spec.groundRaycastResult.y
		local dx = fx - bx
		local dy = fy - by
		local dz = fz - bz
		setDirection(self.rootNode, dx, dy, dz, 0, 1, 0)
		return
	end
	local posX, posY, posZ = getWorldTranslation(self.rootNode)
	spec.groundRaycastResult.distance = Rideable.GROUND_RAYCAST_MAXDISTANCE
	raycastAll(posX, posY, posZ, 0, -1, 0, Rideable.GROUND_RAYCAST_MAXDISTANCE, "groundRaycastCallback", self, Rideable.GROUND_RAYCAST_COLLISIONMASK)
	spec.isCloseToGround = spec.groundRaycastResult.distance < 1.25
end
function Rideable:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_rideable
	if isActiveForInputIgnoreSelection and spec.cluster ~= nil then
		local mission = g_currentMission
		mission:addExtraPrintText(string.format("%s: %d %%", g_i18n:getText("infohud_riding"), spec.cluster:getRidingFactor() * 100))
	end
end
function Rideable:onSetBroken()
	self:unlinkReins()
	if self.isServer then
		local husbandry = g_currentMission.husbandrySystem:getFirstAvailableHusbandry(self)
		local spec = self.spec_rideable
		local isInStable = nil
		if husbandry ~= nil then
			local cluster = self:getCluster()
			husbandry:addCluster(cluster)
			self:delete()
			isInStable = true
		else
			isInStable = false
		end
		if spec.lastOwner ~= nil then
			spec.lastOwner:sendEvent(RideableStableNotificationEvent.new(isInStable, spec.cluster:getName()), nil, true)
		end
	end
end
function Rideable:testCCTMove(dt)
	local spec = self.spec_rideable
	spec.lastCCTPosX = spec.currentCCTPosX
	spec.lastCCTPosY = spec.currentCCTPosY
	spec.lastCCTPosZ = spec.currentCCTPosZ
	spec.currentCCTPosX, spec.currentCCTPosY, spec.currentCCTPosZ = getWorldTranslation(self.spec_cctdrivable.cctNode)
	local expectedMovementX = 0
	local expectedMovementZ = 0
	while spec.cctMoveQueue[1] ~= nil do
		if getIsPhysicsUpdateIndexSimulated(spec.cctMoveQueue[1].physicsIndex) then
			expectedMovementX = expectedMovementX + spec.cctMoveQueue[1].moveX
			expectedMovementZ = expectedMovementZ + spec.cctMoveQueue[1].moveZ
			table.remove(spec.cctMoveQueue, 1)
		end
	end
	local expectedMovement = math.sqrt(expectedMovementX * expectedMovementX + expectedMovementZ * expectedMovementZ)
	if 0.001 * dt < expectedMovement then
		local movementX = spec.currentCCTPosX - spec.lastCCTPosX
		local movementZ = spec.currentCCTPosZ - spec.lastCCTPosZ
		local movement = math.sqrt(movementX * movementX + movementZ * movementZ)
		if movement <= expectedMovement * 0.7 and spec.haltTimer <= 0 then
			self:setCurrentGait(Rideable.GAITTYPES.STILL)
			spec.haltTimer = 900
			if spec.horseStopSound ~= nil then
				g_soundManager:playSample(spec.horseStopSound)
			end
		end
	end
end
function Rideable:getIsRideableJumpAllowed(allowWhileJump)
	local spec = self.spec_rideable
	if not spec.isOnGround and not allowWhileJump then
		return false
	end
	if spec.inputValues.currentGait < Rideable.GAITTYPES.CANTER then
		return false
	elseif self.isBroken then
		return false
	else
		return true
	end
end
function Rideable:jump()
	local spec = self.spec_rideable
	if not self.isServer then
		g_client:getServerConnection():sendEvent(JumpEvent.new(self))
	else
		local total, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "horseJumpCount", 1)
		if total ~= nil then
			g_achievementManager:tryUnlock("HorseJumpsFirst", total)
			g_achievementManager:tryUnlock("HorseJumps", total)
		end
	end
	local jumpHeight = spec.jumpHeight
	if spec.inputValues.currentGait == Rideable.GAITTYPES.CANTER then
		jumpHeight = jumpHeight * 0.5
	end
	local velY = math.sqrt(2 * math.abs(spec.gravity) * jumpHeight)
	spec.currentSpeedY = velY
end
function Rideable:setCurrentGait(gait)
	local spec = self.spec_rideable
	spec.inputValues.currentGait = gait
end
function Rideable:getCurrentGait()
	return self.spec_rideable.inputValues.currentGait
end
function Rideable:setRideableSteer(axisSteer)
	local spec = self.spec_rideable
	if axisSteer ~= 0 then
		spec.inputValues.axisSteer = -axisSteer
	end
end
function Rideable:resetInputs()
	local spec = self.spec_rideable
	spec.inputValues.axisSteer = 0
end
function Rideable:updateKinematic(dt)
	local spec = self.spec_rideable
	local dtInSec = dt * 0.001
	local desiredSpeed = spec.topSpeeds[spec.inputValues.currentGait]
	local maxSpeedChange = spec.maxAcceleration
	if desiredSpeed == 0 then
		maxSpeedChange = spec.maxDeceleration
	end
	maxSpeedChange = maxSpeedChange * dtInSec
	if not spec.isOnGround then
		maxSpeedChange = maxSpeedChange * 0.2
	end
	local speedChange = desiredSpeed - spec.currentSpeed
	speedChange = math.clamp(speedChange, -maxSpeedChange, maxSpeedChange)
	if spec.haltTimer <= 0 then
		spec.currentSpeed = spec.currentSpeed + speedChange
	else
		spec.currentSpeed = 0
	end
	local movement = spec.currentSpeed * dtInSec
	if spec.isOnGround and spec.currentSpeedY < 0 then
		spec.currentSpeedY = 0
	end
	local gravitySpeedChange = spec.gravity * dtInSec
	spec.currentSpeedY = spec.currentSpeedY + gravitySpeedChange
	local movementY = spec.currentSpeedY * dtInSec
	local slowestSpeed = spec.topSpeeds[Rideable.GAITTYPES.WALK]
	local fastestSpeed = spec.topSpeeds[Rideable.GAITTYPES.MAX]
	local maxTurnSpeedChange = math.clamp((fastestSpeed - spec.currentSpeed) / (fastestSpeed - slowestSpeed), 0, 1) * 0.4 + 0.8
	maxTurnSpeedChange = maxTurnSpeedChange * dtInSec
	if not spec.isOnGround then
		maxTurnSpeedChange = maxTurnSpeedChange * 0.25
	end
	if self.isServer and (not self:getIsEntered() and (not self:getIsControlled() and spec.inputValues.axisSteer ~= 0)) then
		spec.inputValues.axisSteer = 0
	end
	local desiredTurnSpeed = spec.maxTurnSpeed * spec.inputValues.axisSteer
	local turnSpeedChange = desiredTurnSpeed - spec.currentTurnSpeed
	turnSpeedChange = math.clamp(turnSpeedChange, -maxTurnSpeedChange, maxTurnSpeedChange)
	spec.currentTurnSpeed = spec.currentTurnSpeed + turnSpeedChange
	spec.currentTurnAngle = spec.currentTurnAngle + spec.currentTurnSpeed * dtInSec * (0 <= movement and 1 or -1)
	local movementX = math.sin(spec.currentTurnAngle) * movement
	local movementZ = math.cos(spec.currentTurnAngle) * movement
	self:moveCCT(movementX, movementY, movementZ, true)
	table.insert(spec.cctMoveQueue, { moveX = movementX, moveY = movementY, moveZ = movementZ, dt = dt, physicsIndex = getPhysicsUpdateIndex() })
end
function Rideable:groundRaycastCallback(hitObjectId, x, y, z, distance)
	local spec = self.spec_rideable
	if hitObjectId == self.spec_cctdrivable.cctNode then
		return true
	elseif getCollisionFilterMask(hitObjectId) == CollisionFlag.DEFAULT then
		return true
	else
		spec.groundRaycastResult.y = y
		spec.groundRaycastResult.object = hitObjectId
		spec.groundRaycastResult.distance = distance
		return false
	end
end
function Rideable:updateAnimation(dt)
	local spec = self.spec_rideable
	local params = spec.animationParameters
	local speed = self.lastSignedSpeedReal * 1000
	local smoothedSpeed = self.lastSignedSpeed * 1000
	speed = math.clamp(speed, spec.topSpeeds[Rideable.GAITTYPES.BACKWARDS], spec.topSpeeds[Rideable.GAITTYPES.MAX])
	smoothedSpeed = math.clamp(smoothedSpeed, spec.topSpeeds[Rideable.GAITTYPES.BACKWARDS], spec.topSpeeds[Rideable.GAITTYPES.MAX])
	local turnSpeed = nil
	if self.isServer then
		turnSpeed = (spec.interpolatorTurnAngle.targetValue - spec.interpolatorTurnAngle.lastValue) / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	else
		local interpQuat = self.components[1].networkInterpolators.quaternion
		local lastDirX, _, lastDirZ = mathQuaternionRotateVector(interpQuat.lastQuaternionX, interpQuat.lastQuaternionY, interpQuat.lastQuaternionZ, interpQuat.lastQuaternionW, 0, 0, 1)
		local targetDirX, _, targetDirZ = mathQuaternionRotateVector(interpQuat.targetQuaternionX, interpQuat.targetQuaternionY, interpQuat.targetQuaternionZ, interpQuat.targetQuaternionW, 0, 0, 1)
		local lastTurnAngle = MathUtil.getYRotationFromDirection(lastDirX, lastDirZ)
		local targetTurnAngle = MathUtil.getYRotationFromDirection(targetDirX, targetDirZ)
		local turnAngleDiff = targetTurnAngle - lastTurnAngle
		if 3.141592653589793 < turnAngleDiff then
			turnAngleDiff = turnAngleDiff - 6.283185307179586
		elseif turnAngleDiff < -3.141592653589793 then
			turnAngleDiff = turnAngleDiff + 6.283185307179586
		end
		turnSpeed = turnAngleDiff / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	end
	local interpPos = self.components[1].networkInterpolators.position
	local speedY = (interpPos.targetPositionY - interpPos.lastPositionY) / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	local leftRightWeight = nil
	if 0.01 < math.abs(speed) then
		local closestGait = Rideable.GAITTYPES.STILL
		local closestDiff = math.huge
		for i = 1, Rideable.GAITTYPES.MAX do
			local diff = math.abs(speed - spec.topSpeeds[i])
			if diff < closestDiff then
				closestGait = i
				closestDiff = diff
			end
		end
		local minTurnRadius = spec.minTurnRadius[closestGait]
		leftRightWeight = minTurnRadius * turnSpeed / speed
	else
		leftRightWeight = turnSpeed / spec.maxTurnSpeed
	end
	if leftRightWeight < spec.smoothedLeftRightWeight then
		spec.smoothedLeftRightWeight = math.max(leftRightWeight, spec.smoothedLeftRightWeight - 0.002 * dt, -1)
	else
		spec.smoothedLeftRightWeight = math.min(leftRightWeight, spec.smoothedLeftRightWeight + 0.002 * dt, 1)
	end
	params.forwardVelocity.value = speed
	params.absForwardVelocity.value = math.abs(speed)
	params.verticalVelocity.value = speedY
	params.yawVelocity.value = turnSpeed
	params.absYawVelocity.value = math.abs(turnSpeed)
	params.leftRightWeight.value = spec.smoothedLeftRightWeight
	params.onGround.value = spec.isOnGround
	params.closeToGround.value = spec.isCloseToGround
	params.inWater.value = self.isInWater
	params.halted.value = 0 < spec.haltTimer
	params.smoothedForwardVelocity.value = smoothedSpeed
	params.absSmoothedForwardVelocity.value = math.abs(smoothedSpeed)
	if spec.animationPlayer ~= nil then
		for _, parameter in pairs(params) do
			if parameter.type == 0 then
				setConditionalAnimationBoolValue(spec.animationPlayer, parameter.id, parameter.value)
			elseif parameter.type == 1 then
				setConditionalAnimationFloatValue(spec.animationPlayer, parameter.id, parameter.value)
			end
		end
		updateConditionalAnimation(spec.animationPlayer, dt)
	end
	local isEntered = false
	if self.getIsEntered ~= nil then
		isEntered = self:getIsEntered()
	end
	local isControlled = false
	if self.getIsControlled ~= nil then
		isControlled = self:getIsControlled()
	end
	if isEntered or isControlled then
		local character = self:getVehicleCharacter()
		if character ~= nil and (character.animationCharsetId ~= nil and character.animationPlayer ~= nil) then
			for _, parameter in pairs(params) do
				if parameter.type == 0 then
					setConditionalAnimationBoolValue(character.animationPlayer, parameter.id, parameter.value)
				elseif parameter.type == 1 then
					setConditionalAnimationFloatValue(character.animationPlayer, parameter.id, parameter.value)
				end
			end
			updateConditionalAnimation(character.animationPlayer, dt)
		end
	end
	self:updateFootsteps(dt, math.abs(speed))
end
function Rideable:updateSound(dt)
	local spec = self.spec_rideable
	if spec.horseBreathSoundsEffort ~= nil and (spec.horseBreathSoundsNoEffort ~= nil and spec.isOnGround) then
		spec.currentBreathTimer = spec.currentBreathTimer - dt
		spec.currentBreathTimer = math.max(spec.currentBreathTimer, 0)
		if spec.currentBreathTimer == 0 then
			if spec.inputValues.currentGait == Rideable.GAITTYPES.GALLOP then
				g_soundManager:playSample(spec.horseBreathSoundsEffort)
				spec.currentBreathTimer = spec.horseBreathIntervalEffort
				return
			end
			g_soundManager:playSample(spec.horseBreathSoundsNoEffort)
			if spec.inputValues.currentGait == Rideable.GAITTYPES.STILL then
				spec.currentBreathTimer = spec.horseBreathMinIntervalIdle + math.random() * (spec.horseBreathMaxIntervalIdle - spec.horseBreathMinIntervalIdle)
				return
			end
			spec.currentBreathTimer = spec.horseBreathIntervalNoEffort
		end
	end
end
function Rideable:setWorldPositionQuat(x, y, z, qx, qy, qz, qw, changeInterp)
	setWorldTranslation(self.rootNode, x, y, z)
	setWorldQuaternion(self.rootNode, qx, qy, qz, qw)
	if changeInterp then
		local spec = self.spec_rideable
		spec.networkInterpolators.position:setPosition(x, y, z)
		spec.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
	end
end
function Rideable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_rideable
		self:clearActionEventsTable(spec.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _ = nil
			local actionEventId = nil
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_ACCELERATE_VEHICLE, self, Rideable.actionEventAccelerate, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			spec.acceletateEventId = actionEventId
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_BRAKE_VEHICLE, self, Rideable.actionEventBrake, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			spec.brakeEventId = actionEventId
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_MOVE_SIDE_VEHICLE, self, Rideable.actionEventSteer, false, false, true, true, nil)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			spec.steerEventId = actionEventId
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.JUMP, self, Rideable.actionEventJump, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			spec.jumpEventId = actionEventId
		end
	end
end
function Rideable:onEnterVehicle(isControlling)
	local spec = self.spec_rideable
	if self.isClient then
		spec.playerToEnter = nil
		spec.checkPlayerToEnter = false
		spec.currentSpeed = 0
		spec.currentTurnSpeed = 0
		self:setCurrentGait(Rideable.GAITTYPES.STILL)
		spec.isOnGround = false
	end
	if self.isServer then
		spec.lastOwner = self:getOwnerConnection()
		spec.doHusbandryCheck = 0
	end
end
function Rideable:onVehicleCharacterChanged(character)
	if character ~= nil and self.isClient then
		local spec = self.spec_rideable
		link(character.playerModel.thirdPersonLeftHandNode, spec.leftReinNode)
		link(character.playerModel.thirdPersonRightHandNode, spec.rightReinNode)
		setVisibility(spec.reinsNode, true)
		if character ~= nil and (character.animationCharsetId ~= nil and character.animationPlayer ~= nil) then
			for key, parameter in pairs(spec.animationParameters) do
				conditionalAnimationRegisterParameter(character.animationPlayer, parameter.id, parameter.type, key)
			end
			initConditionalAnimation(character.animationPlayer, character.animationCharsetId, self.configFileName, "vehicle.riderConditionalAnimation")
			setConditionalAnimationSpecificParameterIds(character.animationPlayer, spec.animationParameters.absForwardVelocity.id, spec.animationParameters.absYawVelocity.id)
			self:setEquipmentVisibility(true)
			conditionalAnimationZeroiseTrackTimes(character.animationPlayer)
			conditionalAnimationZeroiseTrackTimes(spec.animationPlayer)
		end
		if self:getIsControlled() then
			local mission = g_currentMission
			if 0 < mission.hud.fadeScreenElement:getAlpha() then
				mission:fadeScreen(-1, spec.fadeDuration, self.endFade, self)
			end
		end
	end
end
function Rideable:onLeaveVehicle()
	local spec = self.spec_rideable
	if self.isClient then
		spec.inputValues.currentGait = Rideable.GAITTYPES.STILL
		self:resetInputs()
		local mission = g_currentMission
		if 0 < mission.hud.fadeScreenElement:getAlpha() then
			mission:fadeScreen(-1, spec.fadeDuration, self.endFade, self)
		end
	end
	if self.isServer then
		spec.doHusbandryCheck = 5000
	end
	spec.leaveTimer = 15000
end
function Rideable:unlinkReins()
	if self.isClient then
		local spec = self.spec_rideable
		link(spec.leftReinParentNode, spec.leftReinNode)
		link(spec.rightReinParentNode, spec.rightReinNode)
		setVisibility(spec.reinsNode, false)
	end
end
function Rideable:setEquipmentVisibility(val)
	if self.isClient then
		local spec = self.spec_rideable
		if spec.equipmentNode ~= nil then
			setVisibility(spec.equipmentNode, val)
			setVisibility(spec.reinsNode, val)
		end
	end
end
function Rideable:actionEventAccelerate(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_rideable
	local enterable = self.spec_enterable
	if enterable.isEntered and (enterable.isControlled and (spec.haltTimer <= 0 and spec.isOnGround)) then
		self:setCurrentGait(math.min(self:getCurrentGait() + 1, Rideable.GAITTYPES.MAX))
	end
end
function Rideable:actionEventBrake(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_rideable
	if self:getIsEntered() and (spec.haltTimer <= 0 and spec.isOnGround) then
		self:setCurrentGait(math.max(self:getCurrentGait() - 1, 1))
	end
end
function Rideable:actionEventSteer(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_rideable
	if self:getIsEntered() and spec.haltTimer <= 0 then
		self:setRideableSteer(inputValue)
	end
end
function Rideable:actionEventJump(actionName, inputValue, callbackState, isAnalog)
	if self:getIsRideableJumpAllowed() then
		self:jump()
	end
end
function Rideable:updateFootsteps(dt, speed)
	local spec = self.spec_rideable
	local epsilon = 0.001
	if epsilon < speed then
		local dirX, _, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		local rotY = MathUtil.getYRotationFromDirection(dirX, dirZ)
		for k, hoofInfo in pairs(spec.hooves) do
			local posX, posY, posZ = getWorldTranslation(hoofInfo.node)
			spec.groundRaycastResult.object = 0
			spec.groundRaycastResult.y = posY - 1
			raycastClosest(posX, posY + Rideable.GROUND_RAYCAST_OFFSET, posZ, 0, -1, 0, Rideable.GROUND_RAYCAST_MAXDISTANCE, "groundRaycastCallback", self, Rideable.GROUND_RAYCAST_COLLISIONMASK)
			local hitTerrain = spec.groundRaycastResult.object == g_terrainNode
			local terrainY = spec.groundRaycastResult.y
			local onGround = posY - terrainY < 0.05
			if onGround then
				if not hoofInfo.onGround then
					local r, g, b, _, _ = getTerrainAttributesAtWorldPos(g_terrainNode, posX, posY, posZ, true, true, true, true, false)
					hoofInfo.onGround = true
					if spec.inputValues.currentGait < Rideable.GAITTYPES.CANTER then
						if hoofInfo.psSlow ~= nil and hoofInfo.psSlow.emitterShape ~= nil then
							ParticleUtil.resetNumOfEmittedParticles(hoofInfo.psSlow)
							ParticleUtil.setEmittingState(hoofInfo.psSlow, true)
							setShaderParameter(hoofInfo.psSlow.shape, "psColor", r, g, b, 1, false)
							setWorldTranslation(hoofInfo.psSlow.emitterShape, posX, terrainY, posZ)
							setWorldRotation(hoofInfo.psSlow.emitterShape, 0, rotY, 0)
						end
					elseif hoofInfo.psFast ~= nil then
						if hoofInfo.psFast.emitterShape ~= nil then
							ParticleUtil.resetNumOfEmittedParticles(hoofInfo.psFast)
							ParticleUtil.setEmittingState(hoofInfo.psFast, true)
							setShaderParameter(hoofInfo.psFast.shape, "psColor", r, g, b, 1, false)
							setWorldTranslation(hoofInfo.psFast.emitterShape, posX, terrainY, posZ)
							setWorldRotation(hoofInfo.psSlow.emitterShape, 0, rotY, 0)
						end
					end
					local sample = self:getHoofSurfaceSound(posX, posY, posZ, hitTerrain)
					if sample == nil then
						continue
					end
					hoofInfo.sampleDebug = string.format("%s - %s", sample.sampleName, sample.filename)
					g_soundManager:playSample(sample)
				else
					if onGround then
						continue
					end
					if hoofInfo.onGround then
						hoofInfo.onGround = false
						if hoofInfo.psSlow ~= nil and hoofInfo.psSlow.emitterShape ~= nil then
							ParticleUtil.setEmittingState(hoofInfo.psSlow, false)
						end
						if hoofInfo.psFast == nil or hoofInfo.psFast.emitterShape == nil then
							continue
						end
						ParticleUtil.setEmittingState(hoofInfo.psFast, false)
					end
				end
			end
		end
	end
end
function Rideable:updateRiding(dt)
	local spec = self.spec_rideable
	if spec.cluster ~= nil and spec.currentSpeed ~= 0 then
		local ridingTime = spec.cluster:getDailyRidingTime()
		local changeDelta = ridingTime / 100
		local speedFactor = 1
		local gaitType = spec.inputValues.currentGait
		if gaitType == Rideable.GAITTYPES.CANTER then
			speedFactor = 2
		elseif gaitType == Rideable.GAITTYPES.GALLOP then
			speedFactor = 3
		end
		spec.ridingTimer = spec.ridingTimer + dt * speedFactor
		if changeDelta < spec.ridingTimer then
			spec.ridingTimer = 0
			spec.cluster:changeRiding(1)
			spec.cluster:changeDirt(1)
		end
		if 0.001 < self.lastMovedDistance then
			local distance = self.lastMovedDistance * 0.001
			g_farmManager:updateFarmStats(self:getOwnerFarmId(), "horseDistance", distance)
		end
		self:updateDirt()
	end
end
function Rideable:getHoofSurfaceSound(x, y, z, hitTerrain)
	local spec = self.spec_rideable
	if hitTerrain then
		local mission = g_currentMission
		local snowHeight = mission.snowSystem:getSnowHeightAtArea(x, z, x + 0.1, z + 0.1, x + 0.1, z)
		if 0 < snowHeight then
			return spec.surfaceNameToSound.snow
		end
		local isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
		if isOnField then
			return spec.surfaceNameToSound.field
		elseif self.isInShallowWater then
			return spec.surfaceNameToSound.shallowWater
		elseif self.isInMediumWater then
			return spec.surfaceNameToSound.mediumWater
		else
			local _, _, _, _, materialId = getTerrainAttributesAtWorldPos(g_terrainNode, x, y, z, true, true, true, true, false)
			return spec.surfaceIdToSound[materialId]
		end
	end
	return spec.surfaceNameToSound.asphalt
end
function Rideable:getPosition()
	return getWorldTranslation(self.rootNode)
end
function Rideable:getRotation()
	return getWorldRotation(self.rootNode)
end
function Rideable:setPlayerToEnter(player)
	local spec = self.spec_rideable
	spec.playerToEnter = player
	spec.checkPlayerToEnter = true
	self:raiseActive()
end
function Rideable:getName(superFunc)
	local spec = self.spec_rideable
	return spec.cluster:getName()
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
	if not isPlayerHotspot then
		return 0
	else
		return superFunc(self, isPlayerHotspot)
	end
end
function Rideable:getShowInVehiclesOverview(superFunc)
	return false
end
function Rideable:periodChanged(superFunc)
	superFunc(self)
	local spec = self.spec_rideable
	if spec.cluster ~= nil then
		spec.cluster:onPeriodChanged()
	end
end
function Rideable:dayChanged(superFunc)
	superFunc(self)
	local spec = self.spec_rideable
	if spec.cluster ~= nil then
		spec.cluster:onDayChanged()
	end
end
function Rideable:getImageFilename(superFunc)
	local imageFilename = superFunc(self)
	local cluster = self:getCluster()
	if cluster ~= nil then
		local mission = g_currentMission
		local visual = mission.animalSystem:getVisualByAge(cluster.subTypeIndex, cluster:getAge())
		imageFilename = visual.store.imageFilename
	end
	return imageFilename
end
function Rideable:deleteVehicleCharacter(superFunc)
	self:setEquipmentVisibility(false)
	self:unlinkReins()
	superFunc(self)
end
function Rideable:getInteractionHelp(superFunc)
	if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE then
		local spec = self.spec_rideable
		local enterText = string.format(g_i18n:getText("action_rideAnimal"), spec.cluster:getName())
		return enterText
	else
		return superFunc(self)
	end
end
function Rideable:showInfo(superFunc, box)
	local spec = self.spec_rideable
	if spec.cluster ~= nil then
		spec.cluster:showInfo(box)
	end
	superFunc(self, box)
end
function Rideable:updateDebugValues(values)
	local spec = self.spec_rideable
	for k, hoofInfo in pairs(spec.hooves) do
		table.insert(values, { name = "hoof sample " .. k, value = hoofInfo.sampleDebug })
	end
end
function Rideable:updateInputText()
	local spec = self.spec_rideable
	if spec.inputValues.currentGait == Rideable.GAITTYPES.BACKWARDS then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_stop"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventActive(spec.brakeEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, false)
		g_inputBinding:setActionEventActive(spec.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, false)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.STILL then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_walk"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_walkBackwards"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventActive(spec.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, false)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.WALK then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_trot"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_stop"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventActive(spec.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, false)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.TROT then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_canter"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_walk"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventActive(spec.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, false)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.CANTER then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_gallop"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_trot"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventText(spec.jumpEventId, g_i18n:getText("input_JUMP"))
		g_inputBinding:setActionEventActive(spec.jumpEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, true)
	else
		if spec.inputValues.currentGait == Rideable.GAITTYPES.GALLOP then
			g_inputBinding:setActionEventActive(spec.acceletateEventId, false)
			g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, false)
			g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_canter"))
			g_inputBinding:setActionEventActive(spec.brakeEventId, true)
			g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
			g_inputBinding:setActionEventText(spec.jumpEventId, g_i18n:getText("input_JUMP"))
			g_inputBinding:setActionEventActive(spec.jumpEventId, true)
			g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, true)
		end
	end
end
