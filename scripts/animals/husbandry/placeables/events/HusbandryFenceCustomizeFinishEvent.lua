-- Local values: HusbandryFenceCustomizeFinishEvent_mt
HusbandryFenceCustomizeFinishEvent = {}
local HusbandryFenceCustomizeFinishEvent_mt = Class(HusbandryFenceCustomizeFinishEvent, Event)
InitStaticEventClass(HusbandryFenceCustomizeFinishEvent, "HusbandryFenceCustomizeFinishEvent")
function HusbandryFenceCustomizeFinishEvent.emptyNew()
	-- upvalues: (copy) HusbandryFenceCustomizeFinishEvent_mt
	return Event.new(HusbandryFenceCustomizeFinishEvent_mt)
end

-- Local values: self
function HusbandryFenceCustomizeFinishEvent.new(placeable, success)
	local v4_ = HusbandryFenceCustomizeFinishEvent.emptyNew()
	v4_.placeable = placeable
	v4_.success = success
	return v4_
end

function HusbandryFenceCustomizeFinishEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.success = streamReadBool(streamId)
	self:run(connection)
end

function HusbandryFenceCustomizeFinishEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteBool(streamId, self.success)
end

-- Local values: user
function HusbandryFenceCustomizeFinishEvent:run(connection)
	if self.placeable ~= nil then
		if not connection:getIsServer() then
			g_server:broadcastEvent(self, false, connection, self.placeable)
		end
		if self.placeable:getIsSynchronized() then
			local v12_
			if connection:getIsServer() then
				v12_ = nil
			else
				v12_ = g_currentMission.userManager:getUserByConnection(connection)
			end
			self.placeable:finishFenceCustomization(v12_, self.success, true)
		end
	end
end

function HusbandryFenceCustomizeFinishEvent.sendEvent(placeable, success, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(HusbandryFenceCustomizeFinishEvent.new(placeable, success), nil, nil, placeable)
			return
		end
		g_client:getServerConnection():sendEvent(HusbandryFenceCustomizeFinishEvent.new(placeable, success))
	end
end
