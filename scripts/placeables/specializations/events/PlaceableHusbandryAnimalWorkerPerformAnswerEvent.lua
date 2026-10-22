PlaceableHusbandryAnimalWorkerPerformAnswerEvent = {}
local PlaceableHusbandryAnimalWorkerPerformAnswerEvent_mt = Class(PlaceableHusbandryAnimalWorkerPerformAnswerEvent, Event)
InitStaticEventClass(PlaceableHusbandryAnimalWorkerPerformAnswerEvent, "PlaceableHusbandryAnimalWorkerPerformAnswerEvent")
function PlaceableHusbandryAnimalWorkerPerformAnswerEvent.emptyNew()
	local self = Event.new(PlaceableHusbandryAnimalWorkerPerformAnswerEvent_mt, NetworkNode.CHANNEL_MAIN)
	return self
end
function PlaceableHusbandryAnimalWorkerPerformAnswerEvent.new(placeable, task, numHandled, cost)
	local self = PlaceableHusbandryAnimalWorkerPerformAnswerEvent.emptyNew()
	self.placeable = placeable
	self.task = task
	self.numHandled = numHandled
	self.cost = cost
	return self
end
function PlaceableHusbandryAnimalWorkerPerformAnswerEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	local taskIndex = streamReadUIntN(streamId, AnimalWorkerTaskSystem.NUM_BITS_TASK_INDEX)
	self.task = g_currentMission.animalWorkerTaskSystem:getTaskByIndex(taskIndex)
	self.numHandled = streamReadUInt16(streamId)
	self.cost = streamReadInt32(streamId)
	self:run(connection)
end
function PlaceableHusbandryAnimalWorkerPerformAnswerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteUIntN(streamId, g_currentMission.animalWorkerTaskSystem:getTaskIndex(self.task), AnimalWorkerTaskSystem.NUM_BITS_TASK_INDEX)
	streamWriteUInt16(streamId, self.numHandled)
	streamWriteInt32(streamId, self.cost)
end
function PlaceableHusbandryAnimalWorkerPerformAnswerEvent:run(connection)
	if self.placeable ~= nil and self.placeable:getIsSynchronized() and self.task ~= nil then
		g_messageCenter:publish(PlaceableHusbandryAnimalWorkerPerformAnswerEvent, self.placeable, self.task, self.numHandled, self.cost)
	end
end
