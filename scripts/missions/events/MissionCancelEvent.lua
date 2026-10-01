MissionCancelEvent = {}
local MissionCancelEvent_mt = Class(MissionCancelEvent, Event)
InitStaticEventClass(MissionCancelEvent, "MissionCancelEvent")
function MissionCancelEvent.emptyNew()
	local self = Event.new(MissionCancelEvent_mt)
	return self
end
function MissionCancelEvent.new(mission)
	local self = MissionCancelEvent.emptyNew()
	self.mission = mission
	return self
end
function MissionCancelEvent.newServerToClient(success)
	local self = MissionCancelEvent.emptyNew()
	self.success = success
	return self
end
function MissionCancelEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.mission)
	else
		streamWriteBool(streamId, self.success)
	end
end
function MissionCancelEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.mission = NetworkUtil.readNodeObject(streamId)
	else
		self.success = streamReadBool(streamId)
	end
	self:run(connection)
end
function MissionCancelEvent:run(connection)
	if not connection:getIsServer() then
		local mission = self.mission
		if mission == nil then
			connection:sendEvent(MissionCancelEvent.newServerToClient(false))
			return
		else
			local currentMission = g_currentMission
			local userManager = currentMission.userManager
			local senderUserId = userManager:getUserIdByConnection(connection)
			local senderFarm = g_farmManager:getFarmByUserId(senderUserId)
			local isMasterUser = connection:getIsLocal() or userManager:getIsConnectionMasterUser(connection)
			local success = false
			if currentMission:getHasPlayerPermission("manageContracts", connection, senderFarm.farmId) and (mission.farmId == senderFarm.farmId or isMasterUser) then
				success = g_missionManager:cancelMission(mission)
			end
			connection:sendEvent(MissionCancelEvent.newServerToClient(success))
			return
		end
	end
	g_messageCenter:publish(MissionCancelEvent, self.success)
end
