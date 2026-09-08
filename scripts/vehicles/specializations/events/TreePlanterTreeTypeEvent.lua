-- Local values: TreePlanterTreeTypeEvent_mt
TreePlanterTreeTypeEvent = {}
local TreePlanterTreeTypeEvent_mt = Class(TreePlanterTreeTypeEvent, Event)
InitStaticEventClass(TreePlanterTreeTypeEvent, "TreePlanterTreeTypeEvent")
function TreePlanterTreeTypeEvent.emptyNew()
	-- upvalues: (copy) TreePlanterTreeTypeEvent_mt
	return Event.new(TreePlanterTreeTypeEvent_mt)
end

-- Local values: self
function TreePlanterTreeTypeEvent.new(object, treeTypeIndex, treeVariationIndex)
	local v5_ = TreePlanterTreeTypeEvent.emptyNew()
	v5_.object = object
	v5_.treeTypeIndex = treeTypeIndex
	v5_.treeVariationIndex = treeVariationIndex
	return v5_
end

function TreePlanterTreeTypeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.treeTypeIndex = streamReadUInt32(streamId)
	self.treeVariationIndex = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
	self:run(connection)
end

function TreePlanterTreeTypeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUInt32(streamId, self.treeTypeIndex)
	streamWriteUIntN(streamId, self.treeVariationIndex or 1, TreePlantManager.VARIATION_NUM_BITS)
end

function TreePlanterTreeTypeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setTreePlanterTreeTypeIndex(self.treeTypeIndex, self.treeVariationIndex, true)
	end
end

function TreePlanterTreeTypeEvent.sendEvent(object, treeTypeIndex, treeVariationIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(TreePlanterTreeTypeEvent.new(object, treeTypeIndex, treeVariationIndex), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(TreePlanterTreeTypeEvent.new(object, treeTypeIndex, treeVariationIndex))
	end
end
