AnimalMoveEvent = {}
AnimalMoveEvent.MOVE_SUCCESS = 0
AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION = 1
AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST = 2
AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST = 3
AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER = 4
AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED = 5
AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE = 6
AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS = 7
AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_MONEY = 2
local AnimalMoveEvent_mt = Class(AnimalMoveEvent, Event)
InitStaticEventClass(AnimalMoveEvent, "AnimalMoveEvent")
function AnimalMoveEvent.emptyNew()
	local self = Event.new(AnimalMoveEvent_mt)
	return self
end
function AnimalMoveEvent.new(sourceObject, targetObject, clusterId, numAnimals)
	local self = AnimalMoveEvent.emptyNew()
	self.sourceObject = sourceObject
	self.targetObject = targetObject
	self.clusterId = clusterId
	self.numAnimals = numAnimals
	return self
end
function AnimalMoveEvent.newServerToClient(errorCode)
	local self = AnimalMoveEvent.emptyNew()
	self.errorCode = errorCode
	return self
end
function AnimalMoveEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.sourceObject = NetworkUtil.readNodeObject(streamId)
		self.targetObject = NetworkUtil.readNodeObject(streamId)
		self.clusterId = streamReadInt32(streamId)
		self.numAnimals = streamReadUInt8(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
	end
	self:run(connection)
end
function AnimalMoveEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.sourceObject)
		NetworkUtil.writeNodeObject(streamId, self.targetObject)
		streamWriteInt32(streamId, self.clusterId)
		streamWriteUInt8(streamId, self.numAnimals)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
	end
end
function AnimalMoveEvent:run(connection)
	if not connection:getIsServer() then
		local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
		local farmId = farm.farmId
		local errorCode = AnimalMoveEvent.validate(self.sourceObject, self.targetObject, self.clusterId, self.numAnimals, farmId)
		if errorCode ~= nil then
			connection:sendEvent(AnimalMoveEvent.newServerToClient(errorCode))
			return
		else
			local cluster = self.sourceObject:getClusterById(self.clusterId)
			local newCluster = cluster:clone()
			newCluster:changeNumAnimals(self.numAnimals)
			self.targetObject:addCluster(newCluster)
			local clusterSystem = self.sourceObject:getClusterSystem()
			cluster:changeNumAnimals(-self.numAnimals)
			clusterSystem:updateNow()
			connection:sendEvent(AnimalMoveEvent.newServerToClient(AnimalMoveEvent.MOVE_SUCCESS))
			return
		end
	end
	g_messageCenter:publish(AnimalMoveEvent, self.errorCode)
end
function AnimalMoveEvent.validate(sourceObject, targetObject, clusterId, numAnimals, farmId)
	if sourceObject == nil then
		return AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST
	end
	if targetObject == nil then
		return AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST
	end
	if not g_currentMission.accessHandler:canFarmAccess(farmId, sourceObject) then
		return AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION
	end
	if not g_currentMission.accessHandler:canFarmAccess(farmId, targetObject) then
		return AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION
	end
	local cluster = sourceObject:getClusterById(clusterId)
	if cluster == nil then
		return AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER
	elseif cluster:getNumAnimals() < numAnimals then
		return AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS
	elseif not targetObject:getSupportsAnimalSubType(cluster:getSubTypeIndex()) then
		return AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED
	elseif targetObject:getNumOfFreeAnimalSlots(cluster:getSubTypeIndex()) < numAnimals then
		return AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE
	else
		return nil
	end
end
