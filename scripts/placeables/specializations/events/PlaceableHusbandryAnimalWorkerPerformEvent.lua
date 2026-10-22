PlaceableHusbandryAnimalWorkerPerformEvent = {}
local PlaceableHusbandryAnimalWorkerPerformEvent_mt = Class(PlaceableHusbandryAnimalWorkerPerformEvent, Event)
InitEventClass(PlaceableHusbandryAnimalWorkerPerformEvent, "PlaceableHusbandryAnimalWorkerPerformEvent")
function PlaceableHusbandryAnimalWorkerPerformEvent.emptyNew()
	local self = Event.new(PlaceableHusbandryAnimalWorkerPerformEvent_mt)
	return self
end
function PlaceableHusbandryAnimalWorkerPerformEvent.new(placeable, task)
	local self = PlaceableHusbandryAnimalWorkerPerformEvent.emptyNew()
	self.placeable = placeable
	self.task = task
	return self
end
function PlaceableHusbandryAnimalWorkerPerformEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	local taskIndex = streamReadUIntN(streamId, AnimalWorkerTaskSystem.NUM_BITS_TASK_INDEX)
	self.task = g_currentMission.animalWorkerTaskSystem:getTaskByIndex(taskIndex)
	self:run(connection)
end
function PlaceableHusbandryAnimalWorkerPerformEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteUIntN(streamId, g_currentMission.animalWorkerTaskSystem:getTaskIndex(self.task), AnimalWorkerTaskSystem.NUM_BITS_TASK_INDEX)
end
function PlaceableHusbandryAnimalWorkerPerformEvent:run(connection)
	if self.placeable == nil or not self.placeable:getIsSynchronized() then
		return
	end
	if self.task == nil or self.placeable.performAnimalWorkerTask == nil then
		return
	end
	if connection:getIsServer() then
		return
	elseif not PlaceableHusbandryAnimalWorker.getHasConnectionPermission(self.placeable, connection) then
		connection:sendEvent(PlaceableHusbandryAnimalWorkerPerformAnswerEvent.new(self.placeable, self.task, 0, 0))
	else
		local numHandled, cost = self.placeable:performAnimalWorkerTask(self.task)
		connection:sendEvent(PlaceableHusbandryAnimalWorkerPerformAnswerEvent.new(self.placeable, self.task, numHandled, cost))
	end
end
