-- Local values: DeadwoodMissionTreeEvent_mt
DeadwoodMissionTreeEvent = {}
local DeadwoodMissionTreeEvent_mt = Class(DeadwoodMissionTreeEvent, Event)
InitStaticEventClass(DeadwoodMissionTreeEvent, "DeadwoodMissionTreeEvent")
function DeadwoodMissionTreeEvent.emptyNew()
	-- upvalues: (copy) DeadwoodMissionTreeEvent_mt
	return Event.new(DeadwoodMissionTreeEvent_mt)
end

-- Local values: self
function DeadwoodMissionTreeEvent.new(mission)
	local v3_ = DeadwoodMissionTreeEvent.emptyNew()
	v3_.mission = mission
	return v3_
end

function DeadwoodMissionTreeEvent:readStream(streamId, connection)
	self.mission = NetworkUtil.readNodeObject(streamId)
	self.mission:readDeadTreesStream(streamId)
	self.mission:raiseActive()
end

function DeadwoodMissionTreeEvent:writeStream(streamId, connection)
	local v9_ = not connection:getIsServer()
	assert(v9_, "DeadwoodMissionTreeEvent is a server to client event")
	NetworkUtil.writeNodeObject(streamId, self.mission)
	self.mission:writeDeadTreesStream(streamId)
end
