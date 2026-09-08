-- Local values: AnimalNameEvent_mt
AnimalNameEvent = {}
local AnimalNameEvent_mt = Class(AnimalNameEvent, Event)
InitStaticEventClass(AnimalNameEvent, "AnimalNameEvent")
function AnimalNameEvent.emptyNew()
	-- upvalues: (copy) AnimalNameEvent_mt
	return Event.new(AnimalNameEvent_mt)
end

-- Local values: self
function AnimalNameEvent.new(husbandry, clusterId, name)
	local v5_ = AnimalNameEvent.emptyNew()
	v5_.husbandry = husbandry
	v5_.clusterId = clusterId
	v5_.name = name
	return v5_
end

function AnimalNameEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.clusterId = streamReadInt32(streamId)
	self.name = streamReadString(streamId)
	self:run(connection)
end

function AnimalNameEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	streamWriteInt32(streamId, self.clusterId)
	streamWriteString(streamId, self.name)
end

function AnimalNameEvent:run(connection)
	self.husbandry:renameAnimal(self.clusterId, self.name, true)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false)
	end
end

function AnimalNameEvent.sendEvent(husbandry, clusterId, name, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(AnimalNameEvent.new(husbandry, clusterId, name), false)
			return
		end
		g_client:getServerConnection():sendEvent(AnimalNameEvent.new(husbandry, clusterId, name))
	end
end
