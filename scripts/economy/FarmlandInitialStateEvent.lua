-- Local values: FarmlandInitialStateEvent_mt
FarmlandInitialStateEvent = {}
local FarmlandInitialStateEvent_mt = Class(FarmlandInitialStateEvent, Event)
InitStaticEventClass(FarmlandInitialStateEvent, "FarmlandStateEvent")
function FarmlandInitialStateEvent.emptyNew()
	-- upvalues: (copy) FarmlandInitialStateEvent_mt
	return Event.new(FarmlandInitialStateEvent_mt)
end
function FarmlandInitialStateEvent.new()
	return FarmlandInitialStateEvent.emptyNew()
end

-- Local values: _, farmlandId, farmId
function FarmlandInitialStateEvent:readStream(streamId, connection)
	for _, v3_ in ipairs(g_farmlandManager.sortedFarmlandIds) do
		if streamReadBool(streamId) then
			local v4_ = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
			g_farmlandManager:setLandOwnership(v3_, v4_, true)
		end
	end
end

-- Local values: _, farmlandId, owner
function FarmlandInitialStateEvent:writeStream(streamId, connection)
	for _, v6_ in ipairs(g_farmlandManager.sortedFarmlandIds) do
		local v7_ = g_farmlandManager:getFarmlandOwner(v6_)
		if streamWriteBool(streamId, v7_ ~= FarmlandManager.NO_OWNER_FARM_ID) then
			streamWriteUIntN(streamId, v7_, FarmManager.FARM_ID_SEND_NUM_BITS)
		end
	end
end
