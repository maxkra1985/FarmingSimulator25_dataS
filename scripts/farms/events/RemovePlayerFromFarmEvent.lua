-- Local values: RemovePlayerFromFarmEvent_mt
RemovePlayerFromFarmEvent = {}
local RemovePlayerFromFarmEvent_mt = Class(RemovePlayerFromFarmEvent, Event)
InitStaticEventClass(RemovePlayerFromFarmEvent, "RemovePlayerFromFarmEvent")
function RemovePlayerFromFarmEvent.emptyNew()
	-- upvalues: (copy) RemovePlayerFromFarmEvent_mt
	return Event.new(RemovePlayerFromFarmEvent_mt)
end

-- Local values: self
function RemovePlayerFromFarmEvent.new(userId)
	local v3_ = RemovePlayerFromFarmEvent.emptyNew()
	v3_.userId = userId
	return v3_
end

function RemovePlayerFromFarmEvent:writeStream(streamId, connection)
	User.streamWriteUserId(streamId, self.userId)
end

function RemovePlayerFromFarmEvent:readStream(streamId, connection)
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end

-- Local values: farmId, player, _, p
function RemovePlayerFromFarmEvent:run(connection)
	local v11_ = g_currentMission:getFarmId(connection)
	if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_RIGHTS, connection, v11_) then
		local v12_ = nil
		for _, v13_ in pairs(g_currentMission.players) do
			if v13_.userId == self.userId then
				v12_ = v13_
				break
			end
		end
		if v12_ ~= nil then
			g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(v12_, FarmManager.SPECTATOR_FARM_ID, nil))
		end
	end
end
