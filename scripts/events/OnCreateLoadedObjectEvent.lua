-- Local values: OnCreateLoadedObjectEvent_mt
OnCreateLoadedObjectEvent = {}
local OnCreateLoadedObjectEvent_mt = Class(OnCreateLoadedObjectEvent, Event)
InitStaticEventClass(OnCreateLoadedObjectEvent, "OnCreateLoadedObjectEvent")
function OnCreateLoadedObjectEvent.emptyNew()
	-- upvalues: (copy) OnCreateLoadedObjectEvent_mt
	return Event.new(OnCreateLoadedObjectEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function OnCreateLoadedObjectEvent.new()
	return OnCreateLoadedObjectEvent.emptyNew()
end

-- Local values: numObjects, i, serverId, object
function OnCreateLoadedObjectEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		local v4_ = streamReadUInt16(streamId)
		Assert.areEqual(v4_, g_currentMission.onCreateObjectSystem:getNumObjects())
		for v5_ = 1, v4_ do
			local v6_ = NetworkUtil.readNodeObjectId(streamId)
			local v7_ = g_currentMission.onCreateObjectSystem:get(v5_)
			v7_:readStream(streamId, connection)
			g_client:finishRegisterObject(v7_, v6_)
		end
	end
end

-- Local values: numObjects, i, object
function OnCreateLoadedObjectEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		local v10_ = g_currentMission.onCreateObjectSystem:getNumObjects()
		streamWriteUInt16(streamId, v10_)
		for v11_ = 1, v10_ do
			local v12_ = g_currentMission.onCreateObjectSystem:get(v11_)
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v12_))
			v12_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v12_)
		end
	end
end

function OnCreateLoadedObjectEvent:run(connection) end
