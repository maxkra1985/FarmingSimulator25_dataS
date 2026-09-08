-- Local values: MissionCancelEvent_mt
MissionCancelEvent = {}
local MissionCancelEvent_mt = Class(MissionCancelEvent, Event)
InitStaticEventClass(MissionCancelEvent, "MissionCancelEvent")
function MissionCancelEvent.emptyNew()
	-- upvalues: (copy) MissionCancelEvent_mt
	return Event.new(MissionCancelEvent_mt)
end

-- Local values: self
function MissionCancelEvent.new(mission)
	local v3_ = MissionCancelEvent.emptyNew()
	v3_.mission = mission
	return v3_
end

-- Local values: self
function MissionCancelEvent.newServerToClient(success)
	local v5_ = MissionCancelEvent.emptyNew()
	v5_.success = success
	return v5_
end

function MissionCancelEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.mission)
	else
		streamWriteBool(streamId, self.success)
	end
end

function MissionCancelEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.success = streamReadBool(streamId)
	else
		self.mission = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

-- Local values: mission, currentMission, userManager, senderUserId, senderFarm, isMasterUser, success
function MissionCancelEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(MissionCancelEvent, self.success)
		return
	else
		local v14_ = self.mission
		if v14_ == nil then
			connection:sendEvent(MissionCancelEvent.newServerToClient(false))
		else
			local v15_ = g_currentMission
			local v16_ = v15_.userManager
			local v17_ = v16_:getUserIdByConnection(connection)
			local v18_ = g_farmManager:getFarmByUserId(v17_)
			local v19_ = connection:getIsLocal() or v16_:getIsConnectionMasterUser(connection)
			local v20_
			if v15_:getHasPlayerPermission("manageContracts", connection, v18_.farmId) and (v14_.farmId == v18_.farmId or v19_) then
				v20_ = g_missionManager:cancelMission(v14_)
			else
				v20_ = false
			end
			connection:sendEvent(MissionCancelEvent.newServerToClient(v20_))
		end
	end
end
