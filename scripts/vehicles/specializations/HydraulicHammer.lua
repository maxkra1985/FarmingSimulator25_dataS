HydraulicHammer = {}

function HydraulicHammer.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
	return v2_
end
function HydraulicHammer.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("HydraulicHammer")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.hydraulicHammer.workNode#node", "Cut node where raycast is fired from on -y axis")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.hydraulicHammer.workNode#hitAlignedNode", "Node will be moved and aligned to hit position and normal of worknode raycast")
	v3_:register(XMLValueType.FLOAT, "vehicle.hydraulicHammer.workNode#destructionAmountPerHit", "Damage done to object per hit", 5)
	v3_:register(XMLValueType.TIME, "vehicle.hydraulicHammer.workNode#hitIntervalMin", "Minimum time between cuts in seconds", 0.15)
	v3_:register(XMLValueType.TIME, "vehicle.hydraulicHammer.workNode#hitIntervalMax", "Maximum time between cuts in seconds", 0.25)
	v3_:register(XMLValueType.FLOAT, "vehicle.hydraulicHammer.workNode#raycastDistance", "Raycast distance in meters", 0.3)
	v3_:register(XMLValueType.STRING, "vehicle.hydraulicHammer.workNode#supportedTypes", "Supported destructible types")
	EffectManager.registerEffectXMLPaths(v3_, "vehicle.hydraulicHammer.workNode.effects")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.hydraulicHammer.sounds", "start")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.hydraulicHammer.sounds", "stop")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.hydraulicHammer.sounds", "idle")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.hydraulicHammer.sounds", "work")
	v3_:register(XMLValueType.FLOAT, "vehicle.hydraulicHammer.sounds.work.progressPitch#factor", "Factor applied to sample pitch depending on destruction progress (0-1)")
	AnimationManager.registerAnimationNodesXMLPaths(v3_, "vehicle.hydraulicHammer.animationNodes")
	v3_:register(XMLValueType.STRING, "vehicle.hydraulicHammer.hitAnimation#name", "name of hit animation")
	v3_:setXMLSpecializationType()
end

function HydraulicHammer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "hydraulicHammerRaycastCallback", HydraulicHammer.hydraulicHammerRaycastCallback)
end

function HydraulicHammer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", HydraulicHammer.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", HydraulicHammer.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", HydraulicHammer.getConsumingLoad)
end

function HydraulicHammer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HydraulicHammer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", HydraulicHammer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HydraulicHammer)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", HydraulicHammer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", HydraulicHammer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", HydraulicHammer)
end

-- Local values: spec, node, workNode, supportedDestructibleTypes, hitAnimationName
function HydraulicHammer:onLoad(savegame)
	local v8_ = self.spec_hydraulicHammer
	local v9_ = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#node", nil, self.components, self.i3dMappings)
	if v9_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'node\' for \'vehicle.hydraulicHammer.workNode\'!")
	end
	local v10_ = {
		["node"] = v9_,
		["destructionAmount"] = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#destructionAmountPerHit", 1),
		["hitIntervalMin"] = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#hitIntervalMin", 0.15),
		["hitIntervalMax"] = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#hitIntervalMax", 0.25),
		["raycastDistance"] = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#raycastDistance", 0.4),
		["hitAlignedNode"] = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#hitAlignedNode", nil, self.components, self.i3dMappings)
	}
	if v10_.hitAlignedNode ~= nil then
		v10_.hitAlignedNodeParent = getParent(v10_.hitAlignedNode)
	end
	v10_.lastWorkTime = -1000
	v10_.nextHitTime = 0
	v8_.workNode = v10_
	local v11_ = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#supportedTypes")
	if v11_ ~= nil then
		v8_.supportedDestructibleTypes = table.toSet(string.split(v11_, " "))
	end
	v8_.raycastCollisionMask = CollisionFlag.STATIC_OBJECT
	v8_.lastProgress = 0
	if self.isClient then
		v10_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.hydraulicHammer.workNode.effects", self.components, self, self.i3dMappings)
		g_effectManager:setEffectTypeInfo(v10_.effects, FillType.STONE)
		v8_.samples = {}
		v8_.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.hydraulicHammer.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.samples.stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.hydraulicHammer.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.samples.idle = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.hydraulicHammer.sounds", "idle", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.hydraulicHammer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		if v8_.samples.work ~= nil then
			v8_.samples.work.progressPitchFactor = self.xmlFile:getValue("vehicle.hydraulicHammer.sounds.work.progressPitch#factor", 0)
		end
		v8_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.hydraulicHammer.animationNodes", self.components, self, self.i3dMappings)
		local v12_ = self.xmlFile:getValue("vehicle.hydraulicHammer.hitAnimation#name")
		if self:getAnimationExists(v12_) then
			v8_.hitAnimationName = v12_
		end
	end
	v8_.warningNoAccess = g_i18n:getText("warning_youDontHaveAccessToThisLand")
	v8_.warningToolNotSupportingObject = g_i18n:getText("warning_toolDoesNotSupportThisObject")
end

-- Local values: spec
function HydraulicHammer:onDelete()
	local v14_ = self.spec_hydraulicHammer
	g_soundManager:deleteSamples(v14_.samples)
	g_animationManager:deleteAnimations(v14_.animationNodes)
	if v14_.workNode ~= nil then
		g_effectManager:deleteEffects(v14_.workNode.effects)
	end
end

-- Local values: spec, workNode, x, y, z, dx, dy, dz
function HydraulicHammer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsTurnedOn() then
		local v16_ = self.spec_hydraulicHammer
		local v17_ = v16_.workNode
		if g_time >= v17_.nextHitTime then
			g_effectManager:stopEffects(v16_.workNode.effects)
			local v18_, v19_, v20_ = getWorldTranslation(v17_.node)
			local v21_, v22_, v23_ = localDirectionToWorld(v17_.node, 0, -1, 0)
			raycastClosest(v18_, v19_, v20_, v21_, v22_, v23_, v17_.raycastDistance, "hydraulicHammerRaycastCallback", self, v16_.raycastCollisionMask)
		end
	end
end

-- Local values: spec, destructible, errorCode, ownerFarmId, dx, dy, dz, ux, uy, uz
function HydraulicHammer:hydraulicHammerRaycastCallback(actorId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local v32_ = self.spec_hydraulicHammer
	local v33_, v34_ = g_currentMission.destructibleMapObjectSystem:getDestructibleFromNode(actorId, v32_.supportedDestructibleTypes)
	if v33_ == nil then
		if v34_ ~= DestructibleMapObjectSystem.ERROR_WRONG_DESTRUCTIBLE_TYPE then
			return true
		end
		if self:getRootVehicle() == g_localPlayer:getCurrentVehicle() then
			g_currentMission:showBlinkingWarning(v32_.warningToolNotSupportingObject, 1000)
		end
		return false
	end
	local v35_ = self:getOwnerFarmId()
	if not (g_currentMission.accessHandler:canFarmAccessLand(v35_, x, z) or g_missionManager:getIsMissionDestructible(v35_, v33_)) then
		if self:getRootVehicle() == g_localPlayer:getCurrentVehicle() then
			g_currentMission:showBlinkingWarning(v32_.warningNoAccess, 1000)
		end
		return false
	end
	v32_.lastProgress = g_currentMission.destructibleMapObjectSystem:addDestructibleDamage(v33_, v32_.workNode.destructionAmount)
	if self.isClient then
		if v32_.hitAnimationName ~= nil then
			self:playAnimation(v32_.hitAnimationName, 1, 0, true)
		end
		if v32_.samples.work ~= nil then
			g_soundManager:setSamplePitchOffset(v32_.samples.work, v32_.samples.work.progressPitchFactor * v32_.lastProgress)
			g_soundManager:playSample(v32_.samples.work)
		end
		if v32_.workNode.hitAlignedNode ~= nil then
			setWorldTranslation(v32_.workNode.hitAlignedNode, x, y, z)
			local v36_, v37_, v38_ = worldDirectionToLocal(v32_.workNode.hitAlignedNodeParent, -nx, -ny, -nz)
			local v39_, v40_, v41_ = worldDirectionToLocal(v32_.workNode.hitAlignedNodeParent, 0, 1, 0)
			setDirection(v32_.workNode.hitAlignedNode, v36_, v37_, v38_, v39_, v40_, v41_)
			g_effectManager:resetEffects(v32_.workNode.effects)
			g_effectManager:startEffects(v32_.workNode.effects)
		end
	end
	v32_.workNode.lastWorkTime = g_time
	v32_.workNode.nextHitTime = g_time + math.random(v32_.workNode.hitIntervalMin, v32_.workNode.hitIntervalMax)
	return false
end

-- Local values: spec
function HydraulicHammer:onDeactivate()
	if self.isClient then
		local v43_ = self.spec_hydraulicHammer
		g_effectManager:stopEffects(v43_.workNode.effects)
	end
end

-- Local values: spec
function HydraulicHammer:onTurnedOn()
	if self.isClient then
		local v45_ = self.spec_hydraulicHammer
		g_soundManager:stopSamples(v45_.samples)
		g_soundManager:playSample(v45_.samples.start)
		g_soundManager:playSample(v45_.samples.idle, 0, v45_.samples.start)
		g_animationManager:startAnimations(v45_.animationNodes)
	end
end

-- Local values: spec
function HydraulicHammer:onTurnedOff()
	if self.isClient then
		local v47_ = self.spec_hydraulicHammer
		g_effectManager:stopEffects(v47_.workNode.effects)
		g_soundManager:stopSamples(v47_.samples)
		g_soundManager:playSample(v47_.samples.stop)
		g_animationManager:stopAnimations(v47_.animationNodes)
		if v47_.hitAnimationName then
			self:stopAnimation(v47_.hitAnimationName, true)
		end
	end
end

-- Local values: multiplier, spec
function HydraulicHammer:getDirtMultiplier(superFunc)
	local v50_ = superFunc(self)
	if self.spec_hydraulicHammer.workNode.lastWorkTime + 500 > g_time then
		v50_ = v50_ + self:getWorkDirtMultiplier()
	end
	return v50_
end

-- Local values: multiplier, spec
function HydraulicHammer:getWearMultiplier(superFunc)
	local v53_ = superFunc(self)
	if self.spec_hydraulicHammer.workNode.lastWorkTime + 500 > g_time then
		v53_ = v53_ + self:getWorkWearMultiplier()
	end
	return v53_
end

-- Local values: value, count, spec
function HydraulicHammer:getConsumingLoad(superFunc)
	local v56_, v57_ = superFunc(self)
	if self.spec_hydraulicHammer.workNode.lastWorkTime + 500 > g_time then
		return v56_ + 1, v57_ + 1
	else
		return v56_, v57_
	end
end
