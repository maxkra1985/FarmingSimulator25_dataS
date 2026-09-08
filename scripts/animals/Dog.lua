-- Local values: Dog_mt
Dog = {}
source("dataS/scripts/animals/events/DogFetchItemEvent.lua")
source("dataS/scripts/animals/events/DogFollowEvent.lua")
source("dataS/scripts/animals/events/DogPetEvent.lua")
source("dataS/scripts/animals/DogPetActivatable.lua")
local Dog_mt = Class(Dog, Object)
InitStaticObjectClass(Dog, "Dog")
Dog.FETCH_RANGE = 30
g_xmlManager:addCreateSchemaFunction(function()
	Dog.xmlSchema = XMLSchema.new("dog")
	Dog.registerXMLPaths(Dog.xmlSchema)
end)

function Dog.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.STRING, "dog.annotation", "Copyright annotation")
	AnimalCompanionManager.registerXMLPaths(xmlSchema, "dog")
end

-- Upvalues: Dog_mt
-- Local values: self
function Dog.new(isServer, isClient, customMt)
	-- upvalues: (copy) Dog_mt
	local v6_ = Object.new(isServer, isClient, customMt or Dog_mt)
	v6_.dogInstance = nil
	v6_.animalId = nil
	v6_.spawner = nil
	v6_.xmlFilename = nil
	v6_.entityFollow = nil
	v6_.entityThrower = nil
	v6_.isStaying = false
	v6_.abandonTimer = 0
	v6_.abandonTimerDuration = 6000
	v6_.abandonRange = 100
	v6_.name = ""
	v6_.tileIndexU = 0
	v6_.tileIndexV = 0
	v6_.spawnX = 0
	v6_.spawnY = 0
	v6_.spawnZ = 0
	v6_.forcedClipDistance = 80
	v6_.activatable = DogPetActivatable.new(v6_)
	registerObjectClassName(v6_, "Dog")
	v6_.dirtyFlag = v6_:getNextDirtyFlag()
	return v6_
end

-- Local values: dogInstance, groundMask, obstacleMask
function Dog:load(spawner, xmlFilename, spawnX, spawnY, spawnZ)
	self.spawner = spawner
	self.animalId = 0
	self.spawnX = spawnX
	self.spawnY = spawnY
	self.spawnZ = spawnZ
	self.xmlFilename = xmlFilename
	self.name = g_currentMission.animalNameSystem:getRandomName()
	local v13_ = createAnimalCompanionManager(CompanionAnimalType.DOG, self.xmlFilename, "dog", self.spawnX, self.spawnY, self.spawnZ, g_terrainNode, self.isServer, self.isClient, 1, AudioGroup.ENVIRONMENT)
	if v13_ == 0 then
		return false
	end
	self.dogInstance = v13_
	setCompanionWaterDetectionOffset(self.dogInstance, 0.45)
	setCompanionTrigger(self.dogInstance, self.animalId, "playerInteractionTriggerCallback", self)
	setCompanionTextureTile(self.dogInstance, self.animalId, 1, 1)
	local v14_ = CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT
	local v15_ = CollisionFlag.STATIC_OBJECT + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.BUILDING
	setCompanionCollisionMask(self.dogInstance, v14_, v15_, CollisionFlag.WATER)
	g_soundManager:addIndoorStateChangedListener(self)
	setCompanionUseOutdoorAudioSetup(self.dogInstance, not g_soundManager:getIsIndoor())
	return true
end

function Dog:delete()
	self.isDeleted = true
	if self.dogInstance ~= nil then
		delete(self.dogInstance)
	end
	if self.isServer then
		g_messageCenter:unsubscribeAll(self)
	end
	unregisterObjectClassName(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	g_soundManager:removeIndoorStateChangedListener(self)
	Dog:superClass().delete(self)
end

function Dog:loadFromXMLFile(xmlFile, key, resetVehicles)
	self:setName(xmlFile:getValue(key .. "#name", ""))
	return true
end

function Dog:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#name", HTMLUtil.encodeToHTML(self.name))
end

-- Local values: spawner, xmlFilename, spawnX, spawnY, spawnZ, name, isNew
function Dog:readStream(streamId, connection)
	if connection:getIsServer() then
		local v26_ = NetworkUtil.readNodeObject(streamId)
		local v27_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		local v28_ = streamReadFloat32(streamId)
		local v29_ = streamReadFloat32(streamId)
		local v30_ = streamReadFloat32(streamId)
		local v31_ = streamReadString(streamId)
		self.tileIndexU = streamReadUIntN(streamId, 3)
		self.tileIndexV = streamReadUIntN(streamId, 3)
		if self.xmlFilename == nil then
			self:load(v26_, v27_, v28_, v29_, v30_)
			if v26_ ~= nil then
				v26_.dog = self
			end
		end
		self:setTextureTileIndices(self.tileIndexU, self.tileIndexV)
		self:setName(v31_)
	end
	Dog:superClass().readStream(self, streamId, connection)
end

function Dog:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.spawner)
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))
		streamWriteFloat32(streamId, self.spawnX)
		streamWriteFloat32(streamId, self.spawnY)
		streamWriteFloat32(streamId, self.spawnZ)
		streamWriteString(streamId, self.name)
		streamWriteUIntN(streamId, self.tileIndexU, 3)
		streamWriteUIntN(streamId, self.tileIndexV, 3)
	end
	Dog:superClass().writeStream(self, streamId, connection)
end

function Dog:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		writeAnimalCompanionManagerToStream(self.dogInstance, streamId)
	end
end

function Dog:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		readAnimalCompanionManagerFromStream(self.dogInstance, streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
	end
end

function Dog:update(dt)
	if self.isServer then
		if self.isStaying and self:isAbandoned(dt) then
			self:teleportToSpawn()
		end
		self:raiseActive()
	end
	Dog:superClass().update(self, dt)
end

function Dog:updateTick(dt)
	if self.isServer and (self.dogInstance ~= nil and getAnimalCompanionNeedNetworkUpdate(self.dogInstance)) then
		self:raiseDirtyFlags(self.dirtyFlag)
	end
	Dog:superClass().updateTick(self, dt)
end

-- Local values: distance, clipDistance, clipDist
function Dog:testScope(x, y, z, coeff, isGuiVisible)
	local v50_, v51_ = getCompanionClosestDistance(self.dogInstance, x, y, z)
	local v52_ = v51_ * coeff
	local v53_ = self.forcedClipDistance
	return v50_ < math.min(v52_, v53_)
end

-- Local values: distance, clipDistance, clipDist, result
function Dog:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	local v60_, v61_ = getCompanionClosestDistance(self.dogInstance, x, y, z)
	if v61_ == 0 then
		return 0
	end
	local v62_ = v61_ * coeff
	local v63_ = self.forcedClipDistance
	return (1 - v60_ / math.min(v62_, v63_)) * 0.8 + 0.5 * skipCount * 0.2
end

function Dog:onGhostRemove()
	self:setVisibility(false)
end

function Dog:onGhostAdd()
	self:setVisibility(true)
end

function Dog:hourChanged()
	if self.isServer then
		if self.dogInstance ~= nil then
			setCompanionDaytime(self.dogInstance, g_currentMission.environment.dayTime)
		end
	end
end

function Dog:setName(name)
	self.name = name or ""
end

function Dog:setVisibility(state)
	if self.dogInstance ~= nil then
		setCompanionsVisibility(self.dogInstance, state)
		setCompanionsPhysicsUpdate(self.dogInstance, state)
	end
end

function Dog:playerInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			if g_currentMission.accessHandler:canFarmAccess(g_localPlayer.farmId, self, false) then
				g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
				return
			end
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

function Dog:followEntity(player)
	self.entityFollow = player.rootNode
	self.entityThrower = nil
	if self.isServer then
		setCompanionBehaviorFollowEntity(self.dogInstance, self.animalId, self.entityFollow)
		self.isStaying = false
	else
		g_client:getServerConnection():sendEvent(DogFollowEvent.new(self, player))
	end
end

-- Local values: distance, _
function Dog:getDistanceTo(x, y, z)
	local v81_, _ = getCompanionClosestDistance(self.dogInstance, x, y, z)
	return v81_
end

function Dog:goToSpawn()
	self.entityFollow = nil
	self.entityThrower = nil
	if self.isServer then
		setCompanionBehaviorGotoEntity(self.dogInstance, self.animalId, self.spawner:getSpawnNode())
	else
		g_client:getServerConnection():sendEvent(DogFollowEvent.new(self, nil))
	end
end

function Dog:onFoodBowlFilled(foodBowlNode)
	self.entityFollow = nil
	self.entityThrower = nil
	setCompanionBehaviorFeed(self.dogInstance, self.animalId, foodBowlNode)
end

-- Local values: x, y, z
function Dog:fetchItem(player, ball)
	if self.isServer then
		local v88_, v89_, v90_ = getWorldTranslation(ball.nodeId)
		ball.throwPos = { v88_, v89_, v90_ }
		setCompanionBehaviorFetch(self.dogInstance, self.animalId, ball.nodeId, player.rootNode)
		self.entityThrower = player.rootNode
	else
		g_client:getServerConnection():sendEvent(DogFetchItemEvent.new(self, player, ball))
	end
end

-- Local values: total, _
function Dog:pet()
	if self.isServer then
		setCompanionBehaviorPet(self.dogInstance, self.animalId)
		local v92_, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "petDogCount", 1)
		if v92_ ~= nil then
			g_achievementManager:tryUnlock("PetDog", v92_)
		end
	else
		g_client:getServerConnection():sendEvent(DogPetEvent.new(self))
	end
end

function Dog:idleStay()
	self.entityFollow = nil
	self.entityThrower = nil
	setCompanionBehaviorDefault(self.dogInstance, self.animalId)
	self.isStaying = true
end

function Dog:idleWander() end

function Dog:setTextureTileIndices(tileIndexU, tileIndexV)
	if self.dogInstance ~= 0 then
		setCompanionTextureTile(self.dogInstance, self.animalId, tileIndexU, tileIndexV)
	end
end

-- Local values: isEntityInRange, _, player, entityX, entityY, entityZ, distance, _, _, enterable, entityX, entityY, entityZ, distance, _
function Dog:isAbandoned(dt)
	local v99_ = false
	for _, v100_ in pairs(g_currentMission.players) do
		if v100_.isControlled then
			local v101_, v102_, v103_ = getWorldTranslation(v100_.rootNode)
			local v104_, _ = getCompanionClosestDistance(self.dogInstance, v101_, v102_, v103_)
			if v104_ < self.abandonRange then
				v99_ = true
				break
			end
		end
	end
	if not v99_ then
		for _, v105_ in pairs(g_currentMission.vehicleSystem.enterables) do
			if v105_.spec_enterable ~= nil and v105_.spec_enterable.isControlled then
				local v106_, v107_, v108_ = getWorldTranslation(v105_.rootNode)
				local v109_, _ = getCompanionClosestDistance(self.dogInstance, v106_, v107_, v108_)
				if v109_ < self.abandonRange then
					v99_ = true
					break
				end
			end
		end
	end
	if v99_ then
		self.abandonTimer = self.abandonTimerDuration
	else
		self.abandonTimer = self.abandonTimer - dt
		if self.abandonTimer <= 0 then
			return true
		end
	end
	return false
end

function Dog:resetSteeringParms() end

function Dog:teleportToSpawn()
	if self.isServer then
		setCompanionPosition(self.dogInstance, self.animalId, self.spawnX, self.spawnY, self.spawnZ)
		self:idleWander()
		self:resetSteeringParms()
		self.isStaying = false
		self.entityFollow = nil
		self.entityThrower = nil
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ingameNotification_dogInDogHouse"))
	end
end

function Dog:playerFarmChanged(player)
	if self.isServer and (self.entityFollow == player.rootNode or self.entityThrower == player.rootNode) then
		self:idleStay()
	end
end

function Dog:onPlayerLeave(player)
	if self.isServer and (self.entityFollow == player.rootNode or self.entityThrower == player.rootNode) then
		self:idleStay()
	end
end

function Dog:finalizePlacement()
	self:setVisibility(true)
	if self.isServer then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
		g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, Dog.playerFarmChanged, self)
	end
end

function Dog:onIndoorStateChanged(isIndoor)
	setCompanionUseOutdoorAudioSetup(self.dogInstance, not g_soundManager:getIsIndoor())
end

function Dog.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of dog")
end
