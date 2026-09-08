-- Local values: SellHandToolEvent_mt
SellHandToolEvent = {}
SellHandToolEvent.STATE_SUCCESS = 0
SellHandToolEvent.STATE_FAILED = 1
SellHandToolEvent.STATE_NO_PERMISSION = 2
SellHandToolEvent.STATE_IN_USE = 3
local SellHandToolEvent_mt = Class(SellHandToolEvent, Event)
InitStaticEventClass(SellHandToolEvent, "SellHandToolEvent")
function SellHandToolEvent.emptyNew()
	-- upvalues: (copy) SellHandToolEvent_mt
	return Event.new(SellHandToolEvent_mt)
end

-- Local values: self
function SellHandToolEvent.new(handTool)
	local v3_ = SellHandToolEvent.emptyNew()
	v3_.handTool = handTool
	return v3_
end

-- Local values: self
function SellHandToolEvent.newServerToClient(errorCode)
	local v5_ = SellHandToolEvent.emptyNew()
	v5_.errorCode = errorCode
	return v5_
end

function SellHandToolEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 2)
	else
		self.handTool = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

function SellHandToolEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.handTool)
	else
		streamWriteUIntN(streamId, self.errorCode, 2)
	end
end

-- Local values: errorCode, sellPrice, seller
function SellHandToolEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publishDelayedAfterFrames(SellHandToolEvent, 2, self.errorCode)
	else
		local v14_ = SellHandToolEvent.STATE_SUCCESS
		if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE, connection, self.handTool:getOwnerFarmId()) then
			local v15_ = g_currentMission:getPlayerByConnection(connection)
			if self.handTool:getHolder() == nil or self.handTool:getHolder() == v15_ then
				local v16_ = self.handTool:getSellPrice()
				self.handTool:delete()
				g_currentMission:addMoney(v16_, self.handTool:getOwnerFarmId(), MoneyType.SHOP_HANDTOOL_SELL, true)
			else
				v14_ = SellHandToolEvent.STATE_IN_USE
			end
		else
			v14_ = SellHandToolEvent.STATE_NO_PERMISSION
		end
		connection:sendEvent(SellHandToolEvent.newServerToClient(v14_))
	end
end
