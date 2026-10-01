BuyHandToolEvent = {}
local BuyHandToolEvent_mt = Class(BuyHandToolEvent, Event)
InitStaticEventClass(BuyHandToolEvent, "BuyHandToolEvent")
BuyHandToolEvent.STATE_SUCCESS = 0
BuyHandToolEvent.STATE_NO_PERMISSION = 1
BuyHandToolEvent.STATE_FAILED_TO_LOAD = 2
BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY = 3
function BuyHandToolEvent.emptyNew()
	local self = Event.new(BuyHandToolEvent_mt)
	return self
end
function BuyHandToolEvent.new(handToolBuyData)
	local self = BuyHandToolEvent.emptyNew()
	self.handToolBuyData = handToolBuyData
	return self
end
function BuyHandToolEvent.newServerToClient(errorCode, handToolBuyData, wasPickedUp)
	local self = BuyHandToolEvent.emptyNew()
	self.errorCode = errorCode
	self.handToolBuyData = handToolBuyData
	self.wasPickedUp = wasPickedUp
	return self
end
function BuyHandToolEvent:readStream(streamId, connection)
	if self.handToolBuyData == nil then
		self.handToolBuyData = BuyHandToolData.new()
	end
	if not connection:getIsServer() then
		self.handToolBuyData:readStream(streamId, connection)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
		self.handToolBuyData:readStream(streamId, connection)
		self.wasPickedUp = streamReadBool(streamId)
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
function BuyHandToolEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(BuyHandToolEvent, self.errorCode, self.handToolBuyData.price, self.wasPickedUp)
		return
	end
	local mission = g_currentMission
	if not mission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE, connection) then
		connection:sendEvent(BuyHandToolEvent.newServerToClient(BuyHandToolEvent.STATE_NO_PERMISSION, self.handToolBuyData, false))
	elseif not self.handToolBuyData:isValid() then
		connection:sendEvent(BuyHandToolEvent.newServerToClient(BuyHandToolEvent.STATE_FAILED_TO_LOAD, self.handToolBuyData, false))
	elseif mission:getMoney(self.ownerFarmId) < self.handToolBuyData.price then
		connection:sendEvent(BuyHandToolEvent.newServerToClient(BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY, self.handToolBuyData, false))
	else
		local player = mission.playerSystem:getPlayerByConnection(connection)
		self.handToolBuyData:setHolder(player)
		self.handToolBuyData:buy(self.onHandToolBoughtCallback, self, { connection = connection })
	end
end
function BuyHandToolEvent:onHandToolBoughtCallback(handTool, loadingState, arguments)
	local connection = arguments.connection
	local errorCode = BuyHandToolEvent.STATE_FAILED_TO_LOAD
	local wasPickedUp = false
	if loadingState == HandToolLoadingState.OK then
		errorCode = BuyHandToolEvent.STATE_SUCCESS
		if handTool.pendingHolder == g_localPlayer or handTool:getHolder() == g_localPlayer then
			wasPickedUp = true
		end
	elseif loadingState == HandToolLoadingState.NO_SPACE then
		errorCode = BuyHandToolEvent.STATE_NO_SPACE
	end
	connection:sendEvent(BuyHandToolEvent.newServerToClient(errorCode, self.handToolBuyData, wasPickedUp))
end
