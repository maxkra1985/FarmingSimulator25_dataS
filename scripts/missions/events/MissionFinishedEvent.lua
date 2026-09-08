-- Local values: MissionFinishedEvent_mt
MissionFinishedEvent = {}
local MissionFinishedEvent_mt = Class(MissionFinishedEvent, Event)
InitStaticEventClass(MissionFinishedEvent, "MissionFinishedEvent")
function MissionFinishedEvent.emptyNew()
	-- upvalues: (copy) MissionFinishedEvent_mt
	return Event.new(MissionFinishedEvent_mt)
end

-- Local values: self
function MissionFinishedEvent.new(mission, finishState, stealingCost)
	local v5_ = MissionFinishedEvent.emptyNew()
	v5_.mission = mission
	v5_.finishState = finishState
	v5_.stealingCost = stealingCost
	return v5_
end

function MissionFinishedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.mission)
	MissionFinishState.writeStream(streamId, self.finishState)
	streamWriteFloat32(streamId, self.stealingCost)
end

function MissionFinishedEvent:readStream(streamId, connection)
	self.mission = NetworkUtil.readNodeObject(streamId)
	self.finishState = MissionFinishState.readStream(streamId)
	self.stealingCost = streamReadFloat32(streamId)
	self:run(connection)
end

function MissionFinishedEvent:run(connection)
	if connection:getIsServer() then
		self.mission.stealingCost = self.stealingCost
		self.mission:finish(self.finishState)
	end
end
