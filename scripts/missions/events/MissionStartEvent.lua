MissionStartEvent = {}
local MissionStartEvent_mt = Class(MissionStartEvent, Event)
InitStaticEventClass(MissionStartEvent, "MissionStartEvent")
function MissionStartEvent.emptyNew()
	local self = Event.new(MissionStartEvent_mt)
	return self
end
function MissionStartEvent.new(mission, farmId, spawnVehicles)
	local self = MissionStartEvent.emptyNew()
	self.mission = mission
	self.farmId = farmId
	self.spawnVehicles = spawnVehicles or false
	return self
end
function MissionStartEvent.newServerToClient(startState, spawnVehicles)
	local self = MissionStartEvent.emptyNew()
	self.startState = startState
	self.spawnVehicles = spawnVehicles or false
	return self
end
function MissionStartEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.mission)
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteBool(streamId, self.spawnVehicles)
	else
		MissionStartState.writeStream(streamId, self.startState)
		streamWriteBool(streamId, self.spawnVehicles)
	end
end
function MissionStartEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.mission = NetworkUtil.readNodeObject(streamId)
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.spawnVehicles = streamReadBool(streamId)
	else
		self.startState = MissionStartState.readStream(streamId)
		self.spawnVehicles = streamReadBool(streamId)
	end
	self:run(connection)
end
function MissionStartEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(MissionStartEvent, self.startState, self.spawnVehicles)
		return
	end
	local mission = g_currentMission
	local senderUserId = mission.userManager:getUserIdByConnection(connection)
	local senderFarm = g_farmManager:getFarmByUserId(senderUserId)
	if not mission:getHasPlayerPermission("manageContracts", connection, senderFarm.farmId) then
		connection:sendEvent(MissionStartEvent.newServerToClient(MissionStartState.NO_PERMISSION, self.spawnVehicles))
	else
		local startState = g_missionManager:startMission(self.mission, self.farmId, self.spawnVehicles)
		connection:sendEvent(MissionStartEvent.newServerToClient(startState, self.spawnVehicles))
	end
end
