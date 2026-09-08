-- Local values: WashingStationEvent_mt
WashingStationEvent = {}
local WashingStationEvent_mt = Class(WashingStationEvent, Event)
InitStaticEventClass(WashingStationEvent, "WashingStationEvent")
function WashingStationEvent.emptyNew()
	-- upvalues: (copy) WashingStationEvent_mt
	return Event.new(WashingStationEvent_mt)
end

-- Local values: self
function WashingStationEvent.new(washingStation)
	local v3_ = WashingStationEvent.emptyNew()
	v3_.washingStation = washingStation
	return v3_
end

function WashingStationEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.washingStation = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

function WashingStationEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.washingStation)
	end
end

-- Local values: userId, farm
function WashingStationEvent:run(connection)
	if not connection:getIsServer() then
		local v12_ = g_currentMission.userManager:getUserIdByConnection(connection)
		if v12_ ~= nil then
			local v13_ = g_farmManager:getFarmByUserId(v12_)
			if v13_ ~= nil then
				self.washingStation:startWashing(v13_.farmId)
			end
		end
	end
end
