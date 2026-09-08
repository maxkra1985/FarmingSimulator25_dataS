-- Local values: PlaceableDestructibleRepairEvent_mt
PlaceableDestructibleRepairEvent = {}
local PlaceableDestructibleRepairEvent_mt = Class(PlaceableDestructibleRepairEvent, Event)
InitStaticEventClass(PlaceableDestructibleRepairEvent, "PlaceableDestructibleRepairEvent")
function PlaceableDestructibleRepairEvent.emptyNew()
	-- upvalues: (copy) PlaceableDestructibleRepairEvent_mt
	return Event.new(PlaceableDestructibleRepairEvent_mt)
end

-- Local values: self
function PlaceableDestructibleRepairEvent.new(placeable)
	local v3_ = PlaceableDestructibleRepairEvent.emptyNew()
	v3_.placeable = placeable
	return v3_
end

-- Local values: self
function PlaceableDestructibleRepairEvent.newServerToClient(placeable, wasSuccessful)
	local v6_ = PlaceableDestructibleRepairEvent.emptyNew()
	v6_.placeable = placeable
	v6_.wasSuccessful = wasSuccessful
	return v6_
end

function PlaceableDestructibleRepairEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	if connection:getIsServer() then
		self.wasSuccessful = streamReadBool(streamId)
	end
	self:run(connection)
end

function PlaceableDestructibleRepairEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	if not connection:getIsServer() then
		streamWriteBool(streamId, self.wasSuccessful)
	end
end

-- Local values: placeable, user, farm, wasSuccessful
function PlaceableDestructibleRepairEvent:run(connection)
	local v15_ = self.placeable
	if v15_ ~= nil and v15_:getIsSynchronized() then
		if not connection:getIsServer() then
			local v16_ = g_currentMission.userManager:getUserByConnection(connection)
			if v16_ == nil then
				connection:sendEvent(PlaceableDestructibleRepairEvent.newServerToClient(v15_, false))
				return
			else
				local v17_ = g_farmManager:getFarmByUserId(v16_:getId())
				if v17_ == nil then
					connection:sendEvent(PlaceableDestructibleRepairEvent.newServerToClient(v15_, false))
				else
					local v18_ = v15_:startRepairDestructible(v17_:getId())
					connection:sendEvent(PlaceableDestructibleRepairEvent.newServerToClient(v15_, v18_))
				end
			end
		end
		v15_:startedRepairDestructible(self.wasSuccessful)
	end
end
