-- Local values: PlaceableNameEvent_mt
PlaceableNameEvent = {}
local PlaceableNameEvent_mt = Class(PlaceableNameEvent, Event)
InitStaticEventClass(PlaceableNameEvent, "PlaceableNameEvent")
function PlaceableNameEvent.emptyNew()
	-- upvalues: (copy) PlaceableNameEvent_mt
	return Event.new(PlaceableNameEvent_mt)
end

-- Local values: self
function PlaceableNameEvent.new(placeable, name)
	local v4_ = PlaceableNameEvent.emptyNew()
	v4_.placeable = placeable
	v4_.resetName = name == nil
	v4_.name = name or ""
	return v4_
end

function PlaceableNameEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.resetName = streamReadBool(streamId)
	if not self.resetName then
		self.name = streamReadString(streamId)
	end
	self:run(connection)
end

function PlaceableNameEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	if not streamWriteBool(streamId, self.resetName) then
		streamWriteString(streamId, self.name)
	end
end

function PlaceableNameEvent:run(connection)
	if self.placeable ~= nil then
		log("PlaceableNameEvent:run", self.name)
		self.placeable:setName(self.name, true)
		if not connection:getIsServer() then
			g_server:broadcastEvent(self, false)
		end
	end
end

function PlaceableNameEvent.sendEvent(placeable, name, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(PlaceableNameEvent.new(placeable, name), false)
			return
		end
		g_client:getServerConnection():sendEvent(PlaceableNameEvent.new(placeable, name))
	end
end
