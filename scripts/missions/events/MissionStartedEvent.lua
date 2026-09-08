-- Local values: MissionStartedEvent_mt
MissionStartedEvent = {}
local MissionStartedEvent_mt = Class(MissionStartedEvent, Event)
InitStaticEventClass(MissionStartedEvent, "MissionStartedEvent")
function MissionStartedEvent.emptyNew()
	-- upvalues: (copy) MissionStartedEvent_mt
	return Event.new(MissionStartedEvent_mt)
end

-- Local values: self
function MissionStartedEvent.new(mission)
	local v3_ = MissionStartedEvent.emptyNew()
	v3_.mission = mission
	return v3_
end

function MissionStartedEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.mission)
		self.mission:writeStreamMissionStartedInfo(streamId, connection)
	end
end

function MissionStartedEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.mission = NetworkUtil.readNodeObject(streamId)
		self.mission:readStreamMissionStartedInfo(streamId, connection)
	end
	self:run(connection)
end

function MissionStartedEvent:run(connection)
	if connection:getIsServer() then
		self.mission:started()
		g_messageCenter:publish(MissionStartedEvent, self.mission)
	end
end
