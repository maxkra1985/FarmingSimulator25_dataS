-- Local values: TreeAttachResponseEvent_mt
TreeAttachResponseEvent = {}
TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT = 0
TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY = 1
TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_MANY = 2
TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_NUM_BITS = 3
local TreeAttachResponseEvent_mt = Class(TreeAttachResponseEvent, Event)
InitStaticEventClass(TreeAttachResponseEvent, "TreeAttachResponseEvent")
function TreeAttachResponseEvent.emptyNew()
	-- upvalues: (copy) TreeAttachResponseEvent_mt
	return Event.new(TreeAttachResponseEvent_mt)
end

-- Local values: self
function TreeAttachResponseEvent.new(object, failedReason, ropeIndex)
	local v5_ = TreeAttachResponseEvent.emptyNew()
	v5_.object = object
	v5_.failedReason = failedReason
	v5_.ropeIndex = ropeIndex
	return v5_
end

function TreeAttachResponseEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.failedReason = streamReadUIntN(streamId, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_NUM_BITS)
	if streamReadBool(streamId) then
		self.ropeIndex = streamReadUIntN(streamId, 3)
	end
	self:run(connection)
end

function TreeAttachResponseEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.failedReason, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_NUM_BITS)
	if streamWriteBool(streamId, self.ropeIndex ~= nil) then
		streamWriteUIntN(streamId, self.ropeIndex, 3)
	end
end

function TreeAttachResponseEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		if self.object.showCarriageTreeMountFailedWarning ~= nil then
			self.object:showCarriageTreeMountFailedWarning(self.ropeIndex, self.failedReason)
			return
		end
		if self.object.showWinchTreeMountFailedWarning ~= nil then
			self.object:showWinchTreeMountFailedWarning(self.ropeIndex, self.failedReason)
		end
	end
end
