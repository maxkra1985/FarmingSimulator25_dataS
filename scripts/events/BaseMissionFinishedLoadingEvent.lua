-- Local values: BaseMissionFinishedLoadingEvent_mt
BaseMissionFinishedLoadingEvent = {}
local BaseMissionFinishedLoadingEvent_mt = Class(BaseMissionFinishedLoadingEvent, Event)
InitStaticEventClass(BaseMissionFinishedLoadingEvent, "BaseMissionFinishedLoadingEvent")
function BaseMissionFinishedLoadingEvent.emptyNew()
	-- upvalues: (copy) BaseMissionFinishedLoadingEvent_mt
	return Event.new(BaseMissionFinishedLoadingEvent_mt)
end

-- Local values: self
function BaseMissionFinishedLoadingEvent.new(posX, posY, posZ, viewDistanceCoeff)
	local v6_ = BaseMissionFinishedLoadingEvent.emptyNew()
	v6_.posX = posX
	v6_.posY = posY
	v6_.posZ = posZ
	v6_.viewDistanceCoeff = viewDistanceCoeff
	return v6_
end

function BaseMissionFinishedLoadingEvent:readStream(streamId, connection)
	self.posX = streamReadFloat32(streamId)
	self.posY = streamReadFloat32(streamId)
	self.posZ = streamReadFloat32(streamId)
	self.viewDistanceCoeff = streamReadFloat32(streamId)
	self:run(connection)
end

function BaseMissionFinishedLoadingEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.posX)
	streamWriteFloat32(streamId, self.posY)
	streamWriteFloat32(streamId, self.posZ)
	streamWriteFloat32(streamId, self.viewDistanceCoeff)
end

function BaseMissionFinishedLoadingEvent:run(connection)
	if g_currentMission ~= nil then
		g_currentMission:onConnectionFinishedLoading(connection, self.posX, self.posY, self.posZ, self.viewDistanceCoeff)
	end
end
