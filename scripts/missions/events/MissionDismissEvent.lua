-- Local values: MissionDismissEvent_mt
MissionDismissEvent = {}
local MissionDismissEvent_mt = Class(MissionDismissEvent, Event)
InitStaticEventClass(MissionDismissEvent, "MissionDismissEvent")
function MissionDismissEvent.emptyNew()
	-- upvalues: (copy) MissionDismissEvent_mt
	return Event.new(MissionDismissEvent_mt)
end

-- Local values: self
function MissionDismissEvent.new(mission)
	local v3_ = MissionDismissEvent.emptyNew()
	v3_.mission = mission
	return v3_
end

-- Local values: self
function MissionDismissEvent.newServerToClient(missionObjectId, success)
	local v6_ = MissionDismissEvent.emptyNew()
	v6_.missionObjectId = missionObjectId
	v6_.success = success
	return v6_
end

function MissionDismissEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.mission)
	else
		NetworkUtil.writeNodeObjectId(streamId, self.missionObjectId)
		streamWriteBool(streamId, self.success)
	end
end

function MissionDismissEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.missionObjectId = NetworkUtil.readNodeObjectId(streamId)
		self.success = streamReadBool(streamId)
	else
		self.mission = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

-- Local values: mission, currentMission, userManager, senderUserId, senderFarm, isMasterUser, missionObjectId, success, mission
function MissionDismissEvent:run(connection)
	if connection:getIsServer() then
		local v15_ = NetworkUtil.getObject(self.missionObjectId)
		if v15_ ~= nil then
			g_missionManager:removeMission(v15_)
		end
		g_messageCenter:publish(MissionDismissEvent, self.success)
		return
	else
		local v16_ = self.mission
		if v16_ ~= nil then
			local v17_ = g_currentMission
			local v18_ = v17_.userManager
			local v19_ = v18_:getUserIdByConnection(connection)
			local v20_ = g_farmManager:getFarmByUserId(v19_)
			local v21_ = connection:getIsLocal() or v18_:getIsConnectionMasterUser(connection)
			local v22_ = NetworkUtil.getObjectId(v16_)
			local v23_
			if v17_:getHasPlayerPermission("manageContracts", connection, v20_.farmId) and (self.mission.farmId == v20_.farmId or v21_) then
				v23_ = g_missionManager:dismissMission(self.mission)
			else
				v23_ = false
			end
			connection:sendEvent(MissionDismissEvent.newServerToClient(v22_, v23_))
		end
	end
end
