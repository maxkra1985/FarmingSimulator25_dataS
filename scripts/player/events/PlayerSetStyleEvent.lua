-- Local values: PlayerSetStyleEvent_mt
PlayerSetStyleEvent = {}
local PlayerSetStyleEvent_mt = Class(PlayerSetStyleEvent, Event)
InitStaticEventClass(PlayerSetStyleEvent, "PlayerSetStyleEvent")
function PlayerSetStyleEvent.emptyNew()
	-- upvalues: (copy) PlayerSetStyleEvent_mt
	return Event.new(PlayerSetStyleEvent_mt)
end

-- Local values: self
function PlayerSetStyleEvent.new(player, style, playerObjectId)
	local v5_ = PlayerSetStyleEvent.emptyNew()
	v5_.player = player
	v5_.style = style
	v5_.playerObjectId = playerObjectId
	return v5_
end

function PlayerSetStyleEvent:writeStream(streamId, connection)
	if self.playerObjectId == nil then
		NetworkUtil.writeNodeObject(streamId, self.player)
	else
		NetworkUtil.writeNodeObjectId(streamId, self.playerObjectId)
	end
	self.style:writeStream(streamId, connection)
end

function PlayerSetStyleEvent:readStream(streamId, connection)
	self.playerObjectId = NetworkUtil.readNodeObjectId(streamId)
	self.player = NetworkUtil.getObject(self.playerObjectId)
	self.style = PlayerStyle.new()
	self.style:readStream(streamId, connection)
	self:run(connection)
end

function PlayerSetStyleEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end
	self.player:setStyleAsync(self.style, false, nil, true)
end

function PlayerSetStyleEvent.sendEvent(player, style, playerObjectId, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlayerSetStyleEvent.new(player, style, playerObjectId), nil, nil, player)
			return
		end
		g_client:getServerConnection():sendEvent(PlayerSetStyleEvent.new(player, style, playerObjectId))
	end
end
