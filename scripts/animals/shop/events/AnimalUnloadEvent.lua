AnimalUnloadEvent = {}
AnimalUnloadEvent.UNLOAD_SUCCESS = 0
AnimalUnloadEvent.UNLOAD_ERROR_NO_PERMISSION = 1
AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER = 2
AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS = 3
AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING = 4
AnimalUnloadEvent.UNLOAD_ERROR_TRAILER_DOES_NOT_EXIST = 5
AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE = 6
AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED = 7
AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED = 8
AnimalUnloadEvent.SEND_NUM_BITS = 4
local AnimalUnloadEvent_mt = Class(AnimalUnloadEvent, Event)
InitStaticEventClass(AnimalUnloadEvent, "AnimalUnloadEvent")
function AnimalUnloadEvent.emptyNew()
	local self = Event.new(AnimalUnloadEvent_mt)
	return self
end
function AnimalUnloadEvent.new(trailer, clusterId)
	local self = AnimalUnloadEvent.emptyNew()
	self.trailer = trailer
	self.clusterId = clusterId
	return self
end
function AnimalUnloadEvent.newServerToClient(errorCode)
	local self = AnimalUnloadEvent.emptyNew()
	self.errorCode = errorCode
	return self
end
function AnimalUnloadEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.trailer = NetworkUtil.readNodeObject(streamId)
		self.clusterId = streamReadInt32(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, AnimalUnloadEvent.SEND_NUM_BITS)
	end
	self:run(connection)
end
function AnimalUnloadEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.trailer)
		streamWriteInt32(streamId, self.clusterId)
	else
		streamWriteUIntN(streamId, self.errorCode, AnimalUnloadEvent.SEND_NUM_BITS)
	end
end
function AnimalUnloadEvent:run(connection)
	if not connection:getIsServer() then
		local errorCode = AnimalUnloadEvent.validate(self.trailer, self.clusterId)
		if errorCode ~= nil then
			connection:sendEvent(AnimalUnloadEvent.newServerToClient(errorCode))
			return
		end
		local cluster = self.trailer:getClusterById(self.clusterId)
		local filename = cluster:getRidableFilename()
		local size = StoreItemUtil.getSizeValues(filename, "vehicle", 0, {})
		local x, y, z, place, _, _ = PlacementUtil.getPlace(self.trailer:getAnimalUnloadPlaces(), size, {}, true, true, true, true)
		if x == nil then
			connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE))
			return
		else
			local farmId = self.trailer:getOwnerFarmId()
			local arguments = { cluster = cluster, connection = connection }
			arguments.trailer = self.trailer
			local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
			y = math.max(terrainHeight, y) + 0.5
			local data = VehicleLoadingData.new()
			data:setFilename(filename)
			data:setPosition(x, y, z)
			data:setRotation(0, place.rotY, 0)
			data:setPropertyState(VehiclePropertyState.OWNED)
			data:setOwnerFarmId(farmId)
			data:load(self.onLoadedRideable, self, arguments)
			return
		end
	end
	g_messageCenter:publish(AnimalUnloadEvent, self.errorCode)
end
function AnimalUnloadEvent:onLoadedRideable(vehicles, vehicleLoadState, arguments)
	local cluster = arguments.cluster
	local connection = arguments.connection
	local trailer = arguments.trailer
	if vehicleLoadState ~= VehicleLoadingState.OK or #vehicles == 0 then
		connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED))
		return
	end
	local newCluster = cluster:clone()
	newCluster:changeNumAnimals(1)
	vehicles[1]:setCluster(newCluster)
	local clusterSystem = trailer:getClusterSystem()
	cluster:changeNumAnimals(-1)
	clusterSystem:updateNow()
	connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_SUCCESS))
end
function AnimalUnloadEvent.validate(trailer, clusterId)
	if trailer == nil then
		return AnimalUnloadEvent.UNLOAD_ERROR_TRAILER_DOES_NOT_EXIST
	end
	local cluster = trailer:getClusterById(clusterId)
	if cluster == nil then
		return AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER
	end
	if cluster:getNumAnimals() == 0 then
		return AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS
	end
	local filename = cluster:getRidableFilename()
	if filename == nil then
		return AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING
	end
	local farmId = trailer:getOwnerFarmId()
	if not g_currentMission.husbandrySystem:getCanAddRideable(farmId) then
		return AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED
	else
		return nil
	end
end
