-- Local values: FarmDestroyEvent_mt
FarmDestroyEvent = {}
local FarmDestroyEvent_mt = Class(FarmDestroyEvent, Event)
InitStaticEventClass(FarmDestroyEvent, "FarmDestroyEvent")
function FarmDestroyEvent.emptyNew()
	-- upvalues: (copy) FarmDestroyEvent_mt
	return Event.new(FarmDestroyEvent_mt)
end

-- Local values: self
function FarmDestroyEvent.new(farmId)
	local v3_ = FarmDestroyEvent.emptyNew()
	v3_.farmId = farmId
	return v3_
end

function FarmDestroyEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function FarmDestroyEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self:run(connection)
end

-- Local values: farm
function FarmDestroyEvent:run(connection)
	if not connection:getIsServer() and (connection:getIsLocal() or g_currentMission.userManager:getIsConnectionMasterUser(connection)) then
		local v11_ = g_farmManager:getFarmById(self.farmId)
		if v11_ ~= nil and v11_:canBeDestroyed() then
			g_farmManager:destroyFarm(self.farmId)
			g_server:broadcastEvent(self)
		end
	end
end
