OnCreateLoadedObjectEvent = {}
local OnCreateLoadedObjectEvent_mt = Class(OnCreateLoadedObjectEvent, Event)
InitStaticEventClass(OnCreateLoadedObjectEvent, "OnCreateLoadedObjectEvent")
function OnCreateLoadedObjectEvent.emptyNew()
	return Event.new(OnCreateLoadedObjectEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function OnCreateLoadedObjectEvent.new()
	return OnCreateLoadedObjectEvent.emptyNew()
end
function OnCreateLoadedObjectEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		local numObjects = streamReadUInt16(streamId)
		Assert.areEqual(numObjects, g_currentMission.onCreateObjectSystem:getNumObjects())
		for i = 1, numObjects do
			local serverId = NetworkUtil.readNodeObjectId(streamId)
			local object = g_currentMission.onCreateObjectSystem:get(i)
			object:readStream(streamId, connection)
			g_client:finishRegisterObject(object, serverId)
		end
	end
end
function OnCreateLoadedObjectEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		local numObjects = g_currentMission.onCreateObjectSystem:getNumObjects()
		streamWriteUInt16(streamId, numObjects)
		for i = 1, numObjects do
			local object = g_currentMission.onCreateObjectSystem:get(i)
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(object))
			object:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, object)
		end
	end
end
function OnCreateLoadedObjectEvent:run(connection) end
