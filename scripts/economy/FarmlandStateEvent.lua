-- Local values: FarmlandStateEvent_mt
FarmlandStateEvent = {}
local FarmlandStateEvent_mt = Class(FarmlandStateEvent, Event)
InitStaticEventClass(FarmlandStateEvent, "FarmlandStateEvent")
function FarmlandStateEvent.emptyNew()
	-- upvalues: (copy) FarmlandStateEvent_mt
	return Event.new(FarmlandStateEvent_mt)
end

-- Local values: self
function FarmlandStateEvent.new(id, farmId, price)
	local v5_ = FarmlandStateEvent.emptyNew()
	v5_.id = id
	v5_.farmId = farmId
	v5_.price = price
	return v5_
end

function FarmlandStateEvent:readStream(streamId, connection)
	self.id = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.price = streamReadInt32(streamId)
	self:run(connection)
end

function FarmlandStateEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.id, g_farmlandManager.numberOfBits)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.price)
end

-- Local values: farmland, currentOwner, player, farmAllowed, farmId, money
function FarmlandStateEvent:run(connection)
	local v13_ = g_farmlandManager:getFarmlandById(self.id)
	if v13_ ~= nil then
		local v14_ = g_farmlandManager:getFarmlandOwner(self.id)
		if connection:getIsServer() then
			g_farmlandManager:setLandOwnership(self.id, self.farmId)
			if v14_ ~= FarmlandManager.NO_OWNER_FARM_ID then
				g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, v14_)
			end
			if self.farmId ~= FarmlandManager.NO_OWNER_FARM_ID then
				g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, self.farmId)
			end
		else
			if g_missionManager:getIsMissionRunningOnFarmland(v13_) then
				return
			end
			if self.farmId == FarmlandManager.NO_OWNER_FARM_ID or v14_ == FarmlandManager.NO_OWNER_FARM_ID then
				local v15_ = g_currentMission:getPlayerByConnection(connection)
				local v16_ = v15_ ~= nil and g_currentMission:getHasPlayerPermission("farmManager", connection, v15_.farmId)
				if v16_ then
					v16_ = v15_.farmId == self.farmId and true or v14_ == v15_.farmId
				end
				if v15_ ~= nil and (v15_.farmId > 0 and v16_) then
					if self.price > 0 then
						local v17_ = v15_.farmId
						local v18_ = g_currentMission:getMoney(v17_)
						if self.farmId == FarmlandManager.NO_OWNER_FARM_ID then
							g_currentMission:addMoney(self.price, v17_, MoneyType.FIELD_SELL, true, true)
						else
							if v18_ < self.price then
								return
							end
							g_currentMission:addMoney(-self.price, v17_, MoneyType.FIELD_BUY, true, true)
						end
					end
					g_server:broadcastEvent(self, true)
					return
				end
			end
		end
	end
end
