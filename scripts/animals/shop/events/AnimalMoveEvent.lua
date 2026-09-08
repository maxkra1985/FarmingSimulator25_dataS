-- Local values: AnimalMoveEvent_mt
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
	-- upvalues: (copy) AnimalMoveEvent_mt
	return Event.new(AnimalMoveEvent_mt)
end

-- Local values: self
function AnimalMoveEvent.new(sourceObject, targetObject, clusterId, numAnimals)
	local v6_ = AnimalMoveEvent.emptyNew()
	v6_.sourceObject = sourceObject
	v6_.targetObject = targetObject
	v6_.clusterId = clusterId
	v6_.numAnimals = numAnimals
	return v6_
end

-- Local values: self
function AnimalMoveEvent.newServerToClient(errorCode)
	local v8_ = AnimalMoveEvent.emptyNew()
	v8_.errorCode = errorCode
	return v8_
end

function AnimalMoveEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
	else
		self.sourceObject = NetworkUtil.readNodeObject(streamId)
		self.targetObject = NetworkUtil.readNodeObject(streamId)
		self.clusterId = streamReadInt32(streamId)
		self.numAnimals = streamReadUInt8(streamId)
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

-- Local values: uniqueUserId, farm, farmId, errorCode, cluster, newCluster, clusterSystem
function AnimalMoveEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(AnimalMoveEvent, self.errorCode)
		return
	else
		local v17_ = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local v18_ = g_farmManager:getFarmForUniqueUserId(v17_).farmId
		local v19_ = AnimalMoveEvent.validate(self.sourceObject, self.targetObject, self.clusterId, self.numAnimals, v18_)
		if v19_ == nil then
			local v20_ = self.sourceObject:getClusterById(self.clusterId)
			local v21_ = v20_:clone()
			v21_:changeNumAnimals(self.numAnimals)
			self.targetObject:addCluster(v21_)
			local v22_ = self.sourceObject:getClusterSystem()
			v20_:changeNumAnimals(-self.numAnimals)
			v22_:updateNow()
			connection:sendEvent(AnimalMoveEvent.newServerToClient(AnimalMoveEvent.MOVE_SUCCESS))
		else
			connection:sendEvent(AnimalMoveEvent.newServerToClient(v19_))
		end
	end
end

-- Local values: cluster
function AnimalMoveEvent.validate(sourceObject, targetObject, clusterId, numAnimals, farmId)
	if sourceObject == nil then
		return AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST
	elseif targetObject == nil then
		return AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST
	elseif g_currentMission.accessHandler:canFarmAccess(farmId, sourceObject) then
		if g_currentMission.accessHandler:canFarmAccess(farmId, targetObject) then
			local v28_ = sourceObject:getClusterById(clusterId)
			if v28_ == nil then
				return AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER
			elseif v28_:getNumAnimals() < numAnimals then
				return AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS
			elseif targetObject:getSupportsAnimalSubType(v28_:getSubTypeIndex()) then
				if targetObject:getNumOfFreeAnimalSlots(v28_:getSubTypeIndex()) < numAnimals then
					return AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE
				else
					return nil
				end
			else
				return AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED
			end
		else
			return AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION
		end
	else
		return AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION
	end
end
