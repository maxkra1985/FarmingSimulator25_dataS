-- Local values: MissionStartEvent_mt
MissionStartEvent = {}
local MissionStartEvent_mt = Class(MissionStartEvent, Event)
InitStaticEventClass(MissionStartEvent, "MissionStartEvent")
function MissionStartEvent.emptyNew()
	-- upvalues: (copy) MissionStartEvent_mt
	return Event.new(MissionStartEvent_mt)
end

-- Local values: self
function MissionStartEvent.new(mission, farmId, spawnVehicles)
	local v5_ = MissionStartEvent.emptyNew()
	v5_.mission = mission
	v5_.farmId = farmId
	v5_.spawnVehicles = spawnVehicles or false
	return v5_
end

-- Local values: self
function MissionStartEvent.newServerToClient(startState, spawnVehicles)
	local v8_ = MissionStartEvent.emptyNew()
	v8_.startState = startState
	v8_.spawnVehicles = spawnVehicles or false
	return v8_
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
	if connection:getIsServer() then
		self.startState = MissionStartState.readStream(streamId)
		self.spawnVehicles = streamReadBool(streamId)
	else
		self.mission = NetworkUtil.readNodeObject(streamId)
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.spawnVehicles = streamReadBool(streamId)
	end
	self:run(connection)
end

-- Local values: mission, senderUserId, senderFarm, startState
function MissionStartEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(MissionStartEvent, self.startState, self.spawnVehicles)
		return
	else
		local v17_ = g_currentMission
		local v18_ = v17_.userManager:getUserIdByConnection(connection)
		if v17_:getHasPlayerPermission("manageContracts", connection, g_farmManager:getFarmByUserId(v18_).farmId) then
			local v19_ = g_missionManager:startMission(self.mission, self.farmId, self.spawnVehicles)
			connection:sendEvent(MissionStartEvent.newServerToClient(v19_, self.spawnVehicles))
		else
			connection:sendEvent(MissionStartEvent.newServerToClient(MissionStartState.NO_PERMISSION, self.spawnVehicles))
		end
	end
end
