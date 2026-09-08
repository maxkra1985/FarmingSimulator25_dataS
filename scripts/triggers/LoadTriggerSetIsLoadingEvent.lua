-- Local values: loadTriggerSetIsLoadingEvent_mt
LoadTriggerSetIsLoadingEvent = {}
local loadTriggerSetIsLoadingEvent_mt = Class(LoadTriggerSetIsLoadingEvent, Event)
InitStaticEventClass(LoadTriggerSetIsLoadingEvent, "LoadTriggerSetIsLoadingEvent")
function LoadTriggerSetIsLoadingEvent.emptyNew()
	-- upvalues: (copy) loadTriggerSetIsLoadingEvent_mt
	return Event.new(loadTriggerSetIsLoadingEvent_mt)
end

-- Local values: self
function LoadTriggerSetIsLoadingEvent.new(object, isLoading, targetObject, fillUnitIndex, fillType)
	local v7_ = LoadTriggerSetIsLoadingEvent.emptyNew()
	v7_.object = object
	v7_.isLoading = isLoading
	v7_.targetObject = targetObject
	v7_.fillUnitIndex = fillUnitIndex
	v7_.fillType = fillType
	return v7_
end

function LoadTriggerSetIsLoadingEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isLoading = streamReadBool(streamId)
	if self.isLoading then
		self.targetObject = NetworkUtil.readNodeObject(streamId)
		self.fillUnitIndex = streamReadUInt8(streamId)
		self.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	end
	self:run(connection)
end

function LoadTriggerSetIsLoadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	if streamWriteBool(streamId, self.isLoading) then
		NetworkUtil.writeNodeObject(streamId, self.targetObject)
		streamWriteUInt8(streamId, self.fillUnitIndex)
		streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
	end
end

function LoadTriggerSetIsLoadingEvent:run(connection)
	self.object:setIsLoading(self.isLoading, self.targetObject, self.fillUnitIndex, self.fillType, true)
	if not connection:getIsServer() then
		g_server:broadcastEvent(LoadTriggerSetIsLoadingEvent.new(self.object, self.isLoading, self.targetObject, self.fillUnitIndex, self.fillType), nil, connection, self.object)
	end
end

function LoadTriggerSetIsLoadingEvent.sendEvent(object, isLoading, targetObject, fillUnitIndex, fillType, noEventSend)
	if isLoading ~= object.isLoading and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(LoadTriggerSetIsLoadingEvent.new(object, isLoading, targetObject, fillUnitIndex, fillType), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(LoadTriggerSetIsLoadingEvent.new(object, isLoading, targetObject, fillUnitIndex, fillType))
	end
end
