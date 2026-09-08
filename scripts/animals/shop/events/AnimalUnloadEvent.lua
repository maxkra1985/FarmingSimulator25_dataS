-- Local values: AnimalUnloadEvent_mt
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
	-- upvalues: (copy) AnimalUnloadEvent_mt
	return Event.new(AnimalUnloadEvent_mt)
end

-- Local values: self
function AnimalUnloadEvent.new(trailer, clusterId)
	local v4_ = AnimalUnloadEvent.emptyNew()
	v4_.trailer = trailer
	v4_.clusterId = clusterId
	return v4_
end

-- Local values: self
function AnimalUnloadEvent.newServerToClient(errorCode)
	local v6_ = AnimalUnloadEvent.emptyNew()
	v6_.errorCode = errorCode
	return v6_
end

function AnimalUnloadEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, AnimalUnloadEvent.SEND_NUM_BITS)
	else
		self.trailer = NetworkUtil.readNodeObject(streamId)
		self.clusterId = streamReadInt32(streamId)
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

-- Local values: errorCode, cluster, filename, size, x, y, z, place, _, _, farmId, arguments, terrainHeight, data
function AnimalUnloadEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(AnimalUnloadEvent, self.errorCode)
		return
	else
		local v15_ = AnimalUnloadEvent.validate(self.trailer, self.clusterId)
		if v15_ == nil then
			local v16_ = self.trailer:getClusterById(self.clusterId)
			local v17_ = v16_:getRidableFilename()
			local v18_ = StoreItemUtil.getSizeValues(v17_, "vehicle", 0, {})
			local v19_, v20_, v21_, v22_, _, _ = PlacementUtil.getPlace(self.trailer:getAnimalUnloadPlaces(), v18_, {}, true, true, true, true)
			if v19_ == nil then
				connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE))
			else
				local v23_ = self.trailer:getOwnerFarmId()
				local v24_ = {
					["cluster"] = v16_,
					["connection"] = connection,
					["trailer"] = self.trailer
				}
				local v25_ = getTerrainHeightAtWorldPos(g_terrainNode, v19_, 0, v21_)
				local v26_ = math.max(v25_, v20_) + 0.5
				local v27_ = VehicleLoadingData.new()
				v27_:setFilename(v17_)
				v27_:setPosition(v19_, v26_, v21_)
				v27_:setRotation(0, v22_.rotY, 0)
				v27_:setPropertyState(VehiclePropertyState.OWNED)
				v27_:setOwnerFarmId(v23_)
				v27_:load(self.onLoadedRideable, self, v24_)
			end
		else
			connection:sendEvent(AnimalUnloadEvent.newServerToClient(v15_))
			return
		end
	end
end

-- Local values: cluster, connection, trailer, newCluster, clusterSystem
function AnimalUnloadEvent:onLoadedRideable(vehicles, vehicleLoadState, arguments)
	local v31_ = arguments.cluster
	local v32_ = arguments.connection
	local v33_ = arguments.trailer
	if vehicleLoadState == VehicleLoadingState.OK and #vehicles ~= 0 then
		local v34_ = v31_:clone()
		v34_:changeNumAnimals(1)
		vehicles[1]:setCluster(v34_)
		local v35_ = v33_:getClusterSystem()
		v31_:changeNumAnimals(-1)
		v35_:updateNow()
		v32_:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_SUCCESS))
	else
		v32_:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED))
	end
end

-- Local values: cluster, filename, farmId
function AnimalUnloadEvent.validate(trailer, clusterId)
	if trailer == nil then
		return AnimalUnloadEvent.UNLOAD_ERROR_TRAILER_DOES_NOT_EXIST
	else
		local v38_ = trailer:getClusterById(clusterId)
		if v38_ == nil then
			return AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER
		elseif v38_:getNumAnimals() == 0 then
			return AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS
		elseif v38_:getRidableFilename() == nil then
			return AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING
		else
			local v39_ = trailer:getOwnerFarmId()
			if g_currentMission.husbandrySystem:getCanAddRideable(v39_) then
				return nil
			else
				return AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED
			end
		end
	end
end
