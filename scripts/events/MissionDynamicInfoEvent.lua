-- Local values: MissionDynamicInfoEvent_mt
MissionDynamicInfoEvent = {}
local MissionDynamicInfoEvent_mt = Class(MissionDynamicInfoEvent, Event)
InitStaticEventClass(MissionDynamicInfoEvent, "MissionDynamicInfoEvent")
MissionDynamicInfoEvent.sendCapNumBits = 4
function MissionDynamicInfoEvent.emptyNew()
	-- upvalues: (copy) MissionDynamicInfoEvent_mt
	return Event.new(MissionDynamicInfoEvent_mt)
end
function MissionDynamicInfoEvent.new()
	return MissionDynamicInfoEvent.emptyNew()
end

-- Local values: serverName, autoAccept, password, capacity, allowOnlyFriends, allowCrossPlay
function MissionDynamicInfoEvent:readStream(streamId, connection)
	local v4_ = streamReadString(streamId)
	local v5_ = streamReadBool(streamId)
	local v6_ = streamReadString(streamId)
	local v7_ = streamReadUIntN(streamId, MissionDynamicInfoEvent.sendCapNumBits) + 1
	local v8_
	if GS_IS_CONSOLE_VERSION then
		v8_ = streamReadBool(streamId)
	else
		v8_ = false
	end
	local v9_ = streamReadBool(streamId)
	g_currentMission:updateMissionDynamicInfo(v4_, v7_, v6_, v5_, v8_, v9_)
	if not connection:getIsServer() then
		g_currentMission:updateMasterServerInfo(connection)
	end
end

function MissionDynamicInfoEvent:writeStream(streamId, connection)
	streamWriteString(streamId, g_currentMission.missionDynamicInfo.serverName)
	streamWriteBool(streamId, g_currentMission.missionDynamicInfo.autoAccept)
	streamWriteString(streamId, g_currentMission.missionDynamicInfo.password)
	streamWriteUIntN(streamId, g_currentMission.missionDynamicInfo.capacity - 1, MissionDynamicInfoEvent.sendCapNumBits)
	if GS_IS_CONSOLE_VERSION then
		streamWriteBool(streamId, g_currentMission.missionDynamicInfo.allowOnlyFriends)
	end
	streamWriteBool(streamId, g_currentMission.missionDynamicInfo.allowCrossPlay)
end

function MissionDynamicInfoEvent:run(connection) end
