-- Local values: BuyHandToolEvent_mt
BuyHandToolEvent = {}
local BuyHandToolEvent_mt = Class(BuyHandToolEvent, Event)
InitStaticEventClass(BuyHandToolEvent, "BuyHandToolEvent")
BuyHandToolEvent.STATE_SUCCESS = 0
BuyHandToolEvent.STATE_NO_PERMISSION = 1
BuyHandToolEvent.STATE_FAILED_TO_LOAD = 2
BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY = 3
function BuyHandToolEvent.emptyNew()
	-- upvalues: (copy) BuyHandToolEvent_mt
	return Event.new(BuyHandToolEvent_mt)
end

-- Local values: self
function BuyHandToolEvent.new(handToolBuyData)
	local v3_ = BuyHandToolEvent.emptyNew()
	v3_.handToolBuyData = handToolBuyData
	return v3_
end

-- Local values: self
function BuyHandToolEvent.newServerToClient(errorCode, handToolBuyData, wasPickedUp)
	local v7_ = BuyHandToolEvent.emptyNew()
	v7_.errorCode = errorCode
	v7_.handToolBuyData = handToolBuyData
	v7_.wasPickedUp = wasPickedUp
	return v7_
end

function BuyHandToolEvent:readStream(streamId, connection)
	if self.handToolBuyData == nil then
		self.handToolBuyData = BuyHandToolData.new()
	end
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
		self.handToolBuyData:readStream(streamId, connection)
		self.wasPickedUp = streamReadBool(streamId)
	else
		self.handToolBuyData:readStream(streamId, connection)
	end
	self:run(connection)
end

function BuyHandToolEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		self.handToolBuyData:writeStream(streamId, connection)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		self.handToolBuyData:writeStream(streamId, connection)
		streamWriteBool(streamId, self.wasPickedUp)
	end
end

-- Local values: mission, player
function BuyHandToolEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(BuyHandToolEvent, self.errorCode, self.handToolBuyData.price, self.wasPickedUp)
		return
	else
		local v16_ = g_currentMission
		if v16_:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE, connection) then
			if self.handToolBuyData:isValid() then
				if self.handToolBuyData.price > v16_:getMoney(self.ownerFarmId) then
					connection:sendEvent(BuyHandToolEvent.newServerToClient(BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY, self.handToolBuyData, false))
				else
					local v17_ = v16_.playerSystem:getPlayerByConnection(connection)
					self.handToolBuyData:setHolder(v17_)
					self.handToolBuyData:buy(self.onHandToolBoughtCallback, self, {
						["connection"] = connection
					})
				end
			else
				connection:sendEvent(BuyHandToolEvent.newServerToClient(BuyHandToolEvent.STATE_FAILED_TO_LOAD, self.handToolBuyData, false))
				return
			end
		else
			connection:sendEvent(BuyHandToolEvent.newServerToClient(BuyHandToolEvent.STATE_NO_PERMISSION, self.handToolBuyData, false))
			return
		end
	end
end

-- Local values: connection, errorCode, wasPickedUp
function BuyHandToolEvent:onHandToolBoughtCallback(handTool, loadingState, arguments)
	local v22_ = arguments.connection
	local v23_ = BuyHandToolEvent.STATE_FAILED_TO_LOAD
	local v24_ = false
	if loadingState == HandToolLoadingState.OK then
		v23_ = BuyHandToolEvent.STATE_SUCCESS
		if handTool.pendingHolder == g_localPlayer or handTool:getHolder() == g_localPlayer then
			v24_ = true
		end
	elseif loadingState == HandToolLoadingState.NO_SPACE then
		v23_ = BuyHandToolEvent.STATE_NO_SPACE
	end
	v22_:sendEvent(BuyHandToolEvent.newServerToClient(v23_, self.handToolBuyData, v24_))
end
