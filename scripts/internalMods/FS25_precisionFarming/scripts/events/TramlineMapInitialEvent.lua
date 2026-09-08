-- Local values: TramlineMapInitialEvent_mt
TramlineMapInitialEvent = {}
local TramlineMapInitialEvent_mt = Class(TramlineMapInitialEvent, Event)
InitEventClass(TramlineMapInitialEvent, "TramlineMapInitialEvent")
function TramlineMapInitialEvent.emptyNew()
	-- upvalues: (copy) TramlineMapInitialEvent_mt
	return Event.new(TramlineMapInitialEvent_mt)
end

-- Local values: self
function TramlineMapInitialEvent.new(farmlandTramlineStates)
	local v3_ = TramlineMapInitialEvent.emptyNew()
	v3_.farmlandTramlineStates = farmlandTramlineStates
	return v3_
end

-- Local values: numFarmlandsToReceive, i, farmlandId, state
function TramlineMapInitialEvent:readStream(streamId, connection)
	self.farmlandTramlineStates = {}
	for _ = 1, streamReadUIntN(streamId, g_farmlandManager.numberOfBits) do
		local v7_ = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
		local v8_ = {
			["workingWidth"] = streamReadFloat32(streamId),
			["workDirection"] = streamReadFloat32(streamId),
			["spacing"] = streamReadFloat32(streamId)
		}
		self.farmlandTramlineStates[v7_] = v8_
	end
	self:run(connection)
end

-- Local values: numFarmlandsToSend, farmlandId, state
function TramlineMapInitialEvent:writeStream(streamId, connection)
	local v11_ = table.size(self.farmlandTramlineStates)
	streamWriteUIntN(streamId, v11_, g_farmlandManager.numberOfBits)
	for v12_, v13_ in pairs(self.farmlandTramlineStates) do
		streamWriteUIntN(streamId, v12_, g_farmlandManager.numberOfBits)
		streamWriteFloat32(streamId, v13_.workingWidth)
		streamWriteFloat32(streamId, v13_.workDirection)
		streamWriteFloat32(streamId, v13_.spacing)
	end
end

function TramlineMapInitialEvent:run(connection)
	if g_precisionFarming ~= nil and g_precisionFarming.tramlineMap ~= nil then
		g_precisionFarming.tramlineMap.farmlandTramlineStates = self.farmlandTramlineStates
	end
end
