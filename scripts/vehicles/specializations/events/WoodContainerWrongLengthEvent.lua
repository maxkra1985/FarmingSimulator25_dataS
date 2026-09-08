-- Local values: WoodContainerWrongLengthEvent_mt
WoodContainerWrongLengthEvent = {}
local WoodContainerWrongLengthEvent_mt = Class(WoodContainerWrongLengthEvent, Event)
InitStaticEventClass(WoodContainerWrongLengthEvent, "WoodContainerWrongLengthEvent")
function WoodContainerWrongLengthEvent.emptyNew()
	-- upvalues: (copy) WoodContainerWrongLengthEvent_mt
	return Event.new(WoodContainerWrongLengthEvent_mt)
end

-- Local values: self
function WoodContainerWrongLengthEvent.new(object, state, x, y, z)
	local v3_ = WoodContainerWrongLengthEvent.emptyNew()
	v3_.object = object
	return v3_
end

function WoodContainerWrongLengthEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function WoodContainerWrongLengthEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

-- Local values: spec
function WoodContainerWrongLengthEvent:run(connection)
	if self.object ~= nil and (self.object:getIsSynchronized() and (g_currentMission:getFarmId() == self.object:getOwnerFarmId() and calcDistanceFrom(getCamera(), self.object.rootNode) < 40)) then
		local v10_ = self.object.spec_woodContainer
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(v10_.texts.warningWoodContainerWrongLength, v10_.targetLength))
	end
end
