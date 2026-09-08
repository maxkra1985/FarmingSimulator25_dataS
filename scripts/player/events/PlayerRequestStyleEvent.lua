-- Local values: PlayerRequestStyleEvent_mt
PlayerRequestStyleEvent = {}
local PlayerRequestStyleEvent_mt = Class(PlayerRequestStyleEvent, Event)
InitStaticEventClass(PlayerRequestStyleEvent, "PlayerRequestStyleEvent")
function PlayerRequestStyleEvent.emptyNew()
	-- upvalues: (copy) PlayerRequestStyleEvent_mt
	return Event.new(PlayerRequestStyleEvent_mt)
end

-- Local values: self
function PlayerRequestStyleEvent.new(playerObjectId)
	local v3_ = PlayerRequestStyleEvent.emptyNew()
	v3_.playerObjectId = playerObjectId
	return v3_
end

function PlayerRequestStyleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.playerObjectId)
end

function PlayerRequestStyleEvent:readStream(streamId, connection)
	self.playerObjectId = NetworkUtil.readNodeObjectId(streamId)
	self.player = NetworkUtil.getObject(self.playerObjectId)
	self:run(connection)
end

-- Local values: style
function PlayerRequestStyleEvent:run(connection)
	if not connection:getIsServer() then
		if self.player ~= nil then
			local v11_ = self.player.graphicsComponent:getStyle()
			connection:sendEvent(PlayerSetStyleEvent.new(self.player, v11_))
			return
		end
		Logging.info("PlayerRequestStyleEvent - Player not found or already left the game")
	end
end
