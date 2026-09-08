-- Local values: TransportMission_mt
TransportMission = {}
local TransportMission_mt = Class(TransportMission, AbstractMission)
InitStaticObjectClass(TransportMission, "TransportMission")
TransportMission.CONTRACT_DURATION = 115200000
TransportMission.CONTRACT_DURATION_VAR = 57600000
TransportMission.REWARD_PER_METER = 0.5
TransportMission.REWARD_PER_OBJECT = 350
TransportMission.NUM_OBJECTS_PER_DRIVE = 5
TransportMission.TEST_HEIGHT = 50

-- Upvalues: TransportMission_mt
-- Local values: title, description, self
function TransportMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) TransportMission_mt
	local v5_ = g_i18n:getText("contract_transport_title")
	local v6_ = g_i18n:getText("contract_transport_description")
	local v7_ = AbstractMission.new(isServer, isClient, v5_, v6_, customMt or TransportMission_mt)
	v7_.objects = {}
	v7_.objectsAtTrigger = {}
	v7_.numFinished = 0
	return v7_
end

-- Local values: trigger, trigger, _, object
function TransportMission:delete()
	if self.pickup ~= nil then
		local v9_ = g_missionManager.transportTriggers[self.pickup]
		if v9_ ~= nil then
			v9_:setMission(nil)
		end
	end
	if self.dropoff ~= nil then
		local v10_ = g_missionManager.transportTriggers[self.dropoff]
		if v10_ ~= nil then
			v10_:setMission(nil)
		end
	end
	for _, v11_ in pairs(self.objects) do
		v11_:delete()
	end
	self:destroyHotspots()
	TransportMission:superClass().delete(self)
end

-- Local values: index, _, object, x, y, z, rx, ry, rz, objectKey
function TransportMission:saveToXMLFile(xmlFile, key)
	TransportMission:superClass().saveToXMLFile(self, xmlFile, key)
	setXMLInt(xmlFile, key .. "#timeLeft", self.timeLeft)
	setXMLString(xmlFile, key .. "#config", self.missionConfig.name)
	setXMLString(xmlFile, key .. "#pickupTrigger", self.pickup)
	setXMLString(xmlFile, key .. "#dropoffTrigger", self.dropoff)
	setXMLString(xmlFile, key .. "#objectFilename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.objectFilename)))
	setXMLInt(xmlFile, key .. "#numObjects", self.numObjects)
	local v15_ = 0
	for _, v16_ in pairs(self.objects) do
		local v17_, v18_, v19_ = getWorldTranslation(v16_.nodeId)
		local v20_, v21_, v22_ = getWorldRotation(v16_.nodeId)
		local v23_ = string.format("%s.object(%d)", key, v15_)
		setXMLString(xmlFile, v23_ .. "#translation", string.format("%f %f %f", v17_, v18_, v19_))
		setXMLString(xmlFile, v23_ .. "#rotation", string.format("%f %f %f", math.deg(v20_), math.deg(v21_), (math.deg(v22_))))
		v15_ = v15_ + 1
	end
end

-- Local values: name, i, objectKey, x, y, z, rx, ry, rz, object, pickupTrigger, dropoffTrigger
function TransportMission:loadFromXMLFile(xmlFile, key)
	if not TransportMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	self.timeLeft = getXMLInt(xmlFile, key .. "#timeLeft")
	local v27_ = getXMLString(xmlFile, key .. "#config")
	self.missionConfig = g_missionManager:getTransportMissionConfig(v27_)
	if self.missionConfig == nil then
		return false
	end
	self.pickup = getXMLString(xmlFile, key .. "#pickupTrigger")
	self.dropoff = getXMLString(xmlFile, key .. "#dropoffTrigger")
	self.objectFilename = NetworkUtil.convertFromNetworkFilename(getXMLString(xmlFile, key .. "#objectFilename"))
	self.numObjects = getXMLInt(xmlFile, key .. "#numObjects")
	if self.status == MissionStatus.RUNNING then
		local v28_ = 0
		while true do
			local v29_ = string.format("%s.object(%d)", key, v28_)
			if not hasXMLProperty(xmlFile, v29_) then
				break
			end
			local v30_ = string.getVector
			local v31_ = getXMLString(xmlFile, v29_ .. "#translation")
			local v32_, v33_, v34_ = unpack(v30_(v31_, 3))
			local v35_ = string.getVector
			local v36_ = getXMLString(xmlFile, v29_ .. "#rotation")
			local v37_, v38_, v39_ = unpack(v35_(v36_, 3))
			local v40_ = self:createObject(v32_, v33_, v34_, v37_, v38_, v39_)
			self.objects[v40_.nodeId] = v40_
			v28_ = v28_ + 1
		end
	end
	local v41_ = self:getPickupTrigger()
	local v42_ = self:getDropoffTrigger()
	if v41_ == nil or v42_ == nil then
		return false
	end
	v41_:setMission(self)
	v42_:setMission(self)
	return true
end

function TransportMission:writeStream(streamId, connection)
	TransportMission:superClass().writeStream(self, streamId, connection)
	streamWriteString(streamId, self.pickup)
	streamWriteString(streamId, self.dropoff)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.objectFilename))
	streamWriteUInt8(streamId, self.numObjects)
	streamWriteUInt8(streamId, self.missionConfig.id)
end

-- Local values: trigger
function TransportMission:readStream(streamId, connection)
	TransportMission:superClass().readStream(self, streamId, connection)
	self.pickup = streamReadString(streamId)
	self.dropoff = streamReadString(streamId)
	self.objectFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.numObjects = streamReadUInt8(streamId)
	self.missionConfig = g_missionManager:getTransportMissionConfigById(streamReadUInt8(streamId))
	g_missionManager.transportTriggers[self.pickup]:setMission(self)
	g_missionManager.transportTriggers[self.dropoff]:setMission(self)
end

-- Local values: tMission, pickup, dropoff, i, item, trigger, i, item, trigger, object, multiplier
function TransportMission:init(args)
	if not TransportMission:superClass().init(self) then
		return false
	end
	local v50_ = table.getRandomElement(g_missionManager.transportMissions)
	local v51_ = nil
	local v52_ = nil
	for _ = 1, #v50_.pickupTriggers + 1 do
		local v53_ = table.getRandomElement(v50_.pickupTriggers)
		local v54_ = g_missionManager.transportTriggers[v53_.index]
		if v54_ ~= nil and v54_.mission == nil then
			v54_:setMission(self)
			v51_ = v53_
			break
		end
	end
	if v51_ == nil then
		return false
	end
	for _ = 1, #v50_.dropoffTriggers + 1 do
		local v55_ = table.getRandomElement(v50_.dropoffTriggers)
		local v56_ = g_missionManager.transportTriggers[v55_.index]
		if v56_ ~= nil and v56_.mission == nil then
			v56_:setMission(self)
			v52_ = v55_
			break
		end
	end
	if v52_ == nil or v51_.index == v52_.index then
		return false
	end
	local v57_ = table.getRandomElement(v50_.objects)
	self.numObjects = math.random(v57_.min, v57_.max)
	self.pickup = v51_.index
	self.dropoff = v52_.index
	self.objectFilename = v57_.filename
	self.missionConfig = v50_
	self.timeLeft = TransportMission.CONTRACT_DURATION + (2 * math.random() - 1) * TransportMission.CONTRACT_DURATION_VAR
	self.reward = self:calculateReward(v51_.rewardScale * v52_.rewardScale * v57_.rewardScale)
	return true
end

-- Local values: triggerA, triggerB, distance, driveReward, handleReward
function TransportMission:calculateReward(multiplier)
	local v60_ = g_missionManager.transportTriggers[self.pickup]
	local v61_ = g_missionManager.transportTriggers[self.dropoff]
	local v62_ = calcDistanceFrom(v60_.triggerId, v61_.triggerId)
	local v63_ = self.numObjects / TransportMission.NUM_OBJECTS_PER_DRIVE
	return (math.ceil(v63_) * TransportMission.REWARD_PER_METER * v62_ + self.numObjects * TransportMission.REWARD_PER_OBJECT) * multiplier
end

-- Local values: difficultyMultiplier
function TransportMission:getReward()
	local v65_ = self.mission.missionInfo.economicDifficulty == EconomicDifficulty.NORMAL and 1 or (self.mission.missionInfo.economicDifficulty == EconomicDifficulty.EASY and 1.2 or 0.8)
	return self.reward * v65_
end

function TransportMission:start()
	if TransportMission:superClass().start(self) then
		return self:loadObjects() and true or false
	else
		return false
	end
end

function TransportMission:finish(success)
	TransportMission:superClass().finish(self, success)
	if self.mission:getIsServer() then
		self:destroyHotspots()
		if success then
			g_farmManager:getFarmById(self.farmId).stats:updateTransportJobsDone()
		end
	end
	if success then
		self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("contract_transport_finished"))
	else
		self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("contract_transport_failed"))
	end
end

-- Local values: _, object
function TransportMission:dismiss()
	TransportMission:superClass().dismiss(self)
	for _, v70_ in pairs(self.objects) do
		v70_:delete()
	end
	self.objects = {}
end

function TransportMission:update(dt)
	TransportMission:superClass().update(self, dt)
	if not self:hasHotspots() and self.status == MissionStatus.RUNNING then
		self:createHotspots()
		self:updateTriggerVisibility()
	end
end

function TransportMission:hasHotspots()
	local v74_
	if self.pickupHotspot == nil then
		v74_ = false
	else
		v74_ = self.dropoffHotspot ~= nil
	end
	return v74_
end

function TransportMission:createHotspots()
	self.pickupHotspot = self:createHotspot(self:getPickupTrigger())
	self.dropoffHotspot = self:createHotspot(self:getDropoffTrigger())
end

function TransportMission:destroyHotspots()
	if self.pickupHotspot ~= nil then
		self.mission:removeMapHotspot(self.pickupHotspot)
		self.pickupHotspot:delete()
		self.pickupHotspot = nil
	end
	if self.dropoffHotspot ~= nil then
		self.mission:removeMapHotspot(self.dropoffHotspot)
		self.dropoffHotspot:delete()
		self.dropoffHotspot = nil
	end
end

function TransportMission:getPickupTrigger()
	return g_missionManager.transportTriggers[self.pickup]
end

function TransportMission:getDropoffTrigger()
	return g_missionManager.transportTriggers[self.dropoff]
end

-- Local values: x, _, z, mapHotspot
function TransportMission:createHotspot(trigger)
	local v81_, _, v82_ = getWorldTranslation(trigger.triggerId)
	local v83_ = MissionHotspot.new()
	v83_:setWorldPosition(v81_, v82_)
	self.mission:addMapHotspot(v83_)
	return v83_
end

-- Local values: trigger
function TransportMission:updateTriggerVisibility()
	g_missionManager.transportTriggers[self.pickup]:onMissionUpdated()
	g_missionManager.transportTriggers[self.dropoff]:onMissionUpdated()
end

-- Local values: trigger, objectConfig, _, object, sizeX, _, sizeZ, rx, ry, rz, tx, ty, tz, rowOffset, xCellOffset, dirX, dirZ, theta, rcos, rsin, i, dx, dz, object
function TransportMission:loadObjects()
	local v86_ = self:getPickupTrigger()
	local v87_ = nil
	for _, v88_ in pairs(self.missionConfig.objects) do
		if v88_.filename == self.objectFilename then
			v87_ = v88_
			break
		end
	end
	if v87_ == nil then
		return false
	end
	local v89_ = v87_.size
	local v90_, _, v91_ = unpack(v89_)
	local v92_, v93_, v94_ = getWorldRotation(v86_.triggerId)
	local v95_, v96_, v97_ = getWorldTranslation(v86_.triggerId)
	local v98_ = v91_ / 2 + 0.3
	local v99_ = v90_ + 0.1
	local v100_, v101_ = MathUtil.getDirectionFromYRotation(v93_)
	local v102_ = math.atan2(v101_, v100_)
	local v103_ = math.cos(v102_)
	local v104_ = math.sin(v102_)
	if not self:isTriggerEmpty(v86_, v90_, v91_) then
		return false
	end
	for v105_ = 1, self.numObjects do
		local v106_ = 0
		if v105_ >= 5 then
			v106_ = -v99_
		elseif v105_ >= 3 then
			v106_ = v99_
		end
		local v107_
		if v105_ % 2 == 0 then
			v107_ = -v98_
		else
			v107_ = v98_
		end
		local v108_ = v103_ * v106_ - v104_ * v107_
		local v109_ = v104_ * v106_ + v103_ * v107_
		local v110_ = self:createObject(v95_ + v108_, v96_, v97_ + v109_, v92_, v93_, v94_)
		self.objects[v110_.nodeId] = v110_
	end
	return true
end

-- Local values: rx, ry, rz, tx, ty, tz, mask
function TransportMission:isTriggerEmpty(trigger, objectSizeX, objectSizeZ)
	local v115_, v116_, v117_ = getWorldRotation(trigger.triggerId)
	local v118_, v119_, v120_ = getWorldTranslation(trigger.triggerId)
	self.tempHasCollision = false
	local v121_ = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.TREE
	overlapBox(v118_, v119_, v120_, v115_, v116_, v117_, 3 * (objectSizeX + 0.1), TransportMission.TEST_HEIGHT * 0.5, 2 * (objectSizeZ + 0.1), "collisionTestCallback", self, v121_)
	return not self.tempHasCollision
end

function TransportMission:collisionTestCallback(transformId)
	if self.mission.nodeToObject[transformId] ~= nil or (self.mission.players[transformId] ~= nil or self.mission:getNodeObject(transformId) ~= nil) then
		self.tempHasCollision = true
	end
end

-- Local values: transportObject
function TransportMission:createObject(x, y, z, rx, ry, rz)
	local v131_ = MissionPhysicsObject.new(self.mission:getIsServer(), self.mission:getIsClient())
	if not v131_:load(self.objectFilename, x, y, z, rx, ry, rz) then
		v131_:delete()
		return nil
	end
	v131_:register()
	v131_.mission = self
	return v131_
end

function TransportMission:objectEnteredTrigger(trigger, objectId)
	if self.objects[objectId] ~= nil and (trigger == self:getDropoffTrigger() and self.objectsAtTrigger[objectId] ~= true) then
		self.objectsAtTrigger[objectId] = true
		self.numFinished = self.numFinished + 1
	end
end

function TransportMission:objectLeftTrigger(trigger, objectId)
	if self.objects[objectId] ~= nil and (trigger == self:getDropoffTrigger() and self.objectsAtTrigger[objectId] == true) then
		self.objectsAtTrigger[objectId] = false
		self.numFinished = self.numFinished - 1
	end
end

-- Local values: list, _, info
function TransportMission:getTriggerInfo(index, isPickup)
	local v141_ = self.missionConfig.dropoffTriggers
	if isPickup then
		v141_ = self.missionConfig.pickupTriggers
	end
	for _, v142_ in ipairs(v141_) do
		if v142_.index == index then
			return v142_
		end
	end
	return {}
end

-- Local values: info
function TransportMission:getTriggerTitle(index, isPickup)
	local v146_ = self:getTriggerInfo(index, isPickup)
	return v146_ == nil and "" or g_i18n:convertText(Utils.getNoNil(v146_.title, ""))
end

function TransportMission:getNPC()
	return g_npcManager:getNPCByIndex(self.missionConfig.npcIndex)
end

function TransportMission:getCompletion()
	return self.numFinished / self.numObjects
end

function TransportMission.loadMapData(xmlFile, key, baseDirectory)
	return true
end
function TransportMission.unloadMapData() end
function TransportMission.canRun()
	if g_missionManager.numTransportTriggers < 2 then
		return false
	else
		return #g_missionManager.transportMissions ~= 0
	end
end
