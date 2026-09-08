-- Local values: HusbandryFenceCustomizeStartEvent_mt
HusbandryFenceCustomizeStartEvent = {}
local HusbandryFenceCustomizeStartEvent_mt = Class(HusbandryFenceCustomizeStartEvent, Event)
InitStaticEventClass(HusbandryFenceCustomizeStartEvent, "HusbandryFenceCustomizeStartEvent")
function HusbandryFenceCustomizeStartEvent.emptyNew()
	-- upvalues: (copy) HusbandryFenceCustomizeStartEvent_mt
	return Event.new(HusbandryFenceCustomizeStartEvent_mt)
end

-- Local values: self
function HusbandryFenceCustomizeStartEvent.new(placeable)
	local v3_ = HusbandryFenceCustomizeStartEvent.emptyNew()
	v3_.placeable = placeable
	return v3_
end

function HusbandryFenceCustomizeStartEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function HusbandryFenceCustomizeStartEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
end

-- Local values: user
function HusbandryFenceCustomizeStartEvent:run(connection)
	if self.placeable ~= nil then
		if not connection:getIsServer() then
			g_server:broadcastEvent(self, false, connection, self.placeable)
		end
		if self.placeable:getIsSynchronized() then
			local v11_
			if connection:getIsServer() then
				v11_ = nil
			else
				v11_ = g_currentMission.userManager:getUserByConnection(connection)
			end
			self.placeable:startFenceCustomization(v11_, true)
		end
	end
end

function HusbandryFenceCustomizeStartEvent.sendEvent(placeable, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(HusbandryFenceCustomizeStartEvent.new(placeable), nil, nil, placeable)
			return
		end
		g_client:getServerConnection():sendEvent(HusbandryFenceCustomizeStartEvent.new(placeable))
	end
end
