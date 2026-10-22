PlaceableHusbandryAnimalWorkerStateEvent = {}
local PlaceableHusbandryAnimalWorkerStateEvent_mt = Class(PlaceableHusbandryAnimalWorkerStateEvent, Event)
InitEventClass(PlaceableHusbandryAnimalWorkerStateEvent, "PlaceableHusbandryAnimalWorkerStateEvent")
function PlaceableHusbandryAnimalWorkerStateEvent.emptyNew()
	local self = Event.new(PlaceableHusbandryAnimalWorkerStateEvent_mt)
	return self
end
function PlaceableHusbandryAnimalWorkerStateEvent.newClientToServer(placeable, task, enabled)
	local self = PlaceableHusbandryAnimalWorkerStateEvent.emptyNew()
	self.placeable = placeable
	self.task = task
	self.enabled = enabled
	self.isServerBroadcast = false
	return self
end
function PlaceableHusbandryAnimalWorkerStateEvent.newServerToClient(placeable, task, enabled)
	local self = PlaceableHusbandryAnimalWorkerStateEvent.emptyNew()
	self.placeable = placeable
	self.task = task
	self.enabled = enabled
	self.isServerBroadcast = true
	return self
end
function PlaceableHusbandryAnimalWorkerStateEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	local taskIndex = streamReadUIntN(streamId, AnimalWorkerTaskSystem.NUM_BITS_TASK_INDEX)
	self.task = g_currentMission.animalWorkerTaskSystem:getTaskByIndex(taskIndex)
	self.enabled = streamReadBool(streamId)
	self.isServerBroadcast = connection:getIsServer()
	self:run(connection)
end
function PlaceableHusbandryAnimalWorkerStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteUIntN(streamId, g_currentMission.animalWorkerTaskSystem:getTaskIndex(self.task), AnimalWorkerTaskSystem.NUM_BITS_TASK_INDEX)
	streamWriteBool(streamId, self.enabled)
end
function PlaceableHusbandryAnimalWorkerStateEvent:run(connection)
	if self.placeable == nil or not self.placeable:getIsSynchronized() then
		return
	end
	if self.task == nil or self.placeable.applyAnimalWorkerStateFromEvent == nil then
		return
	end
	if not self.isServerBroadcast then
		if not PlaceableHusbandryAnimalWorker.getHasConnectionPermission(self.placeable, connection) then
			return
		else
			local applied = self.placeable:applyAnimalWorkerStateFromEvent(self.task, self.enabled)
			g_server:broadcastEvent(PlaceableHusbandryAnimalWorkerStateEvent.newServerToClient(self.placeable, self.task, applied))
			return
		end
	end
	self.placeable:applyAnimalWorkerStateFromEvent(self.task, self.enabled)
end
