-- Local values: FarmsInitialStateEvent_mt
FarmsInitialStateEvent = {}
local FarmsInitialStateEvent_mt = Class(FarmsInitialStateEvent, Event)
InitStaticEventClass(FarmsInitialStateEvent, "FarmsInitialStateEvent")
function FarmsInitialStateEvent.emptyNew()
	-- upvalues: (copy) FarmsInitialStateEvent_mt
	return Event.new(FarmsInitialStateEvent_mt)
end

-- Local values: self
function FarmsInitialStateEvent.new(playerFarmId)
	local v3_ = FarmsInitialStateEvent.emptyNew()
	v3_.playerFarmId = playerFarmId
	v3_.farms = g_farmManager.farms
	return v3_
end

-- Local values: _, farm
function FarmsInitialStateEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, #self.farms)
	for _, v6_ in ipairs(self.farms) do
		NetworkUtil.writeNodeObject(streamId, v6_)
	end
	streamWriteUIntN(streamId, self.playerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

-- Local values: numFarms, _, farm
function FarmsInitialStateEvent:readStream(streamId, connection)
	self.farms = {}
	for _ = 1, streamReadUInt8(streamId) do
		local v10_ = NetworkUtil.readNodeObject(streamId)
		local v11_ = self.farms
		table.insert(v11_, v10_)
	end
	self.playerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self:run(connection)
end

function FarmsInitialStateEvent:run(connection)
	if connection:getIsServer() then
		g_farmManager:updateFarms(self.farms, self.playerFarmId)
	end
end
