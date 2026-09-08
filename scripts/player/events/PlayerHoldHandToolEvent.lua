-- Local values: PlayerHoldHandToolEvent_mt
PlayerHoldHandToolEvent = {}
local PlayerHoldHandToolEvent_mt = Class(PlayerHoldHandToolEvent, Event)
InitStaticEventClass(PlayerHoldHandToolEvent, "PlayerHoldHandToolEvent")
function PlayerHoldHandToolEvent.emptyNew()
	-- upvalues: (copy) PlayerHoldHandToolEvent_mt
	return Event.new(PlayerHoldHandToolEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function PlayerHoldHandToolEvent.new(player, handToolId, isHolding)
	local v4_ = PlayerHoldHandToolEvent.emptyNew()
	v4_.player = player
	v4_.handToolId = handToolId
	return v4_
end

function PlayerHoldHandToolEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	if streamReadBool(streamId) then
		self.handToolId = NetworkUtil.readNodeObjectId(streamId)
	end
	self:run(connection)
end

function PlayerHoldHandToolEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	if streamWriteBool(streamId, self.handToolId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, self.handToolId)
	end
end

-- Local values: handTool
function PlayerHoldHandToolEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection)
	end
	if self.player ~= nil then
		if self.handToolId == nil then
			self.player:setCurrentHandTool(nil, true)
		else
			local v12_ = NetworkUtil.getObject(self.handToolId)
			if v12_ ~= nil and v12_:getIsSynchronized() then
				self.player:setCurrentHandTool(v12_, true)
				return
			end
		end
	end
end

function PlayerHoldHandToolEvent.sendEvent(player, handToolId, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlayerHoldHandToolEvent.new(player, handToolId))
			return
		end
		g_client:getServerConnection():sendEvent(PlayerHoldHandToolEvent.new(player, handToolId))
	end
end
