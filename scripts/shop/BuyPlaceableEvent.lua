-- Local values: BuyPlaceableEvent_mt
BuyPlaceableEvent = {}
local BuyPlaceableEvent_mt = Class(BuyPlaceableEvent, Event)
BuyPlaceableEvent.STATE_SUCCESS = 0
BuyPlaceableEvent.STATE_FAILED_TO_LOAD = 1
BuyPlaceableEvent.STATE_NO_SPACE = 2
BuyPlaceableEvent.STATE_NO_PERMISSION = 3
BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY = 4
BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED = 5
InitStaticEventClass(BuyPlaceableEvent, "BuyPlaceableEvent")
function BuyPlaceableEvent.emptyNew()
	-- upvalues: (copy) BuyPlaceableEvent_mt
	return Event.new(BuyPlaceableEvent_mt)
end

-- Local values: self
function BuyPlaceableEvent.new(placeableBuyData)
	local v3_ = BuyPlaceableEvent.emptyNew()
	v3_.placeableBuyData = placeableBuyData
	return v3_
end

-- Local values: self
function BuyPlaceableEvent.newServerToClient(errorCode, placeableBuyData, objectId)
	local v7_ = BuyPlaceableEvent.emptyNew()
	v7_.errorCode = errorCode
	v7_.placeableBuyData = placeableBuyData
	v7_.objectId = objectId
	return v7_
end

function BuyPlaceableEvent:readStream(streamId, connection)
	if self.placeableBuyData == nil then
		self.placeableBuyData = BuyPlaceableData.new()
	end
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
		self.placeableBuyData:readStream(streamId, connection)
		if self.errorCode == BuyPlaceableEvent.STATE_SUCCESS then
			self.objectId = NetworkUtil.readNodeObjectId(streamId)
		end
	else
		self.placeableBuyData:readStream(streamId, connection)
		self.placeableBuyData:updatePrice()
	end
	self:run(connection)
end

function BuyPlaceableEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		self.placeableBuyData:writeStream(streamId, connection)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		self.placeableBuyData:writeStream(streamId, connection)
		if self.errorCode == BuyPlaceableEvent.STATE_SUCCESS then
			NetworkUtil.writeNodeObjectId(streamId, self.objectId)
		end
	end
end

-- Local values: buyData, totalCosts
function BuyPlaceableEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(BuyPlaceableEvent, self.errorCode, self.price, self.objectId)
		return
	else
		local v16_ = self.placeableBuyData
		if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_PLACEABLE, connection) then
			if v16_:isValid() then
				local v17_ = v16_.price + v16_.displacementCosts
				if v16_.isFreeOfCharge or g_currentMission:getMoney(v16_.ownerFarmId) >= v17_ then
					v16_:buy(self.onPlaceableBoughtCallback, self, {
						["connection"] = connection
					})
				else
					connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY, v16_))
				end
			else
				connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_FAILED_TO_LOAD, v16_))
				return
			end
		else
			connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_NO_PERMISSION, v16_))
			return
		end
	end
end

-- Local values: objectId, errorCode
function BuyPlaceableEvent:onPlaceableBoughtCallback(placeable, loadingState, arguments)
	local v22_ = nil
	local v23_ = BuyPlaceableEvent.STATE_FAILED_TO_LOAD
	if loadingState == PlaceableLoadingState.OK then
		v23_ = BuyPlaceableEvent.STATE_SUCCESS
		v22_ = NetworkUtil.getObjectId(placeable)
	elseif loadingState == PlaceableLoadingState.NO_SPACE then
		v23_ = BuyPlaceableEvent.STATE_NO_SPACE
	elseif loadingState == PlaceableLoadingState.DEFORMATION_FAILED then
		v23_ = BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED
	end
	arguments.connection:sendEvent(BuyPlaceableEvent.newServerToClient(v23_, self.placeableBuyData, v22_))
end
