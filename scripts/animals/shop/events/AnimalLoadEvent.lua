-- Local values: AnimalLoadEvent_mt
AnimalLoadEvent = {}
AnimalLoadEvent.LOAD_SUCCESS = 0
AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION = 1
AnimalLoadEvent.LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST = 2
AnimalLoadEvent.LOAD_ERROR_TRAILER_DOES_NOT_EXIST = 3
AnimalLoadEvent.LOAD_ERROR_INVALID_CLUSTER = 4
AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_ANIMALS = 5
AnimalLoadEvent.LOAD_ERROR_ANIMAL_NOT_SUPPORTED = 6
AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_SPACE = 7
local AnimalLoadEvent_mt = Class(AnimalLoadEvent, Event)
InitStaticEventClass(AnimalLoadEvent, "AnimalLoadEvent")
function AnimalLoadEvent.emptyNew()
	-- upvalues: (copy) AnimalLoadEvent_mt
	return Event.new(AnimalLoadEvent_mt)
end

-- Local values: self
function AnimalLoadEvent.new(trailer, rideable)
	local v4_ = AnimalLoadEvent.emptyNew()
	v4_.trailer = trailer
	v4_.rideable = rideable
	return v4_
end

-- Local values: self
function AnimalLoadEvent.newServerToClient(errorCode)
	local v6_ = AnimalLoadEvent.emptyNew()
	v6_.errorCode = errorCode
	return v6_
end

function AnimalLoadEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
	else
		self.trailer = NetworkUtil.readNodeObject(streamId)
		self.rideable = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

function AnimalLoadEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.trailer)
		NetworkUtil.writeNodeObject(streamId, self.rideable)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
	end
end

-- Local values: uniqueUserId, farm, farmId, errorCode, cluster
function AnimalLoadEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(AnimalLoadEvent, self.errorCode)
		return
	else
		local v15_ = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local v16_ = g_farmManager:getFarmForUniqueUserId(v15_).farmId
		local v17_ = AnimalLoadEvent.validate(self.trailer, self.rideable, v16_)
		if v17_ == nil then
			local v18_ = self.rideable:getCluster()
			self.trailer:addCluster(v18_)
			self.rideable:delete()
			connection:sendEvent(AnimalLoadEvent.newServerToClient(AnimalLoadEvent.LOAD_SUCCESS))
		else
			connection:sendEvent(AnimalLoadEvent.newServerToClient(v17_))
		end
	end
end

-- Local values: cluster
function AnimalLoadEvent.validate(trailer, rideable, farmId)
	if trailer == nil then
		return AnimalLoadEvent.LOAD_ERROR_TRAILER_DOES_NOT_EXIST
	elseif rideable == nil then
		return AnimalLoadEvent.LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST
	elseif g_currentMission.accessHandler:canFarmAccess(farmId, trailer) then
		if g_currentMission.accessHandler:canFarmAccess(farmId, rideable) then
			local v22_ = rideable:getCluster()
			if v22_ == nil then
				return AnimalLoadEvent.LOAD_ERROR_INVALID_CLUSTER
			elseif v22_:getNumAnimals() == 0 then
				return AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_ANIMALS
			elseif trailer:getSupportsAnimalSubType(v22_:getSubTypeIndex()) then
				if trailer:getNumOfFreeAnimalSlots(v22_:getSubTypeIndex()) == 0 then
					return AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_SPACE
				else
					return nil
				end
			else
				return AnimalLoadEvent.LOAD_ERROR_ANIMAL_NOT_SUPPORTED
			end
		else
			return AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION
		end
	else
		return AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION
	end
end
