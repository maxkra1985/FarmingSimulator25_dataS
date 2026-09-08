-- Local values: TreeAttachRequestEvent_mt
TreeAttachRequestEvent = {}
local TreeAttachRequestEvent_mt = Class(TreeAttachRequestEvent, Event)
InitStaticEventClass(TreeAttachRequestEvent, "TreeAttachRequestEvent")
function TreeAttachRequestEvent.emptyNew()
	-- upvalues: (copy) TreeAttachRequestEvent_mt
	return Event.new(TreeAttachRequestEvent_mt)
end

-- Local values: self
function TreeAttachRequestEvent.new(object, splitShapeId, x, y, z, ropeIndex, setupRope)
	local v9_ = TreeAttachRequestEvent.emptyNew()
	v9_.object = object
	v9_.splitShapeId = splitShapeId
	v9_.x = x
	v9_.y = y
	v9_.z = z
	v9_.ropeIndex = ropeIndex
	v9_.setupRope = setupRope
	return v9_
end

function TreeAttachRequestEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.splitShapeId = readSplitShapeIdFromStream(streamId)
	self.x = streamReadFloat32(streamId)
	self.y = streamReadFloat32(streamId)
	self.z = streamReadFloat32(streamId)
	if streamReadBool(streamId) then
		self.ropeIndex = streamReadUIntN(streamId, 3)
	end
	if streamReadBool(streamId) then
		self.setupRopeData = ForestryPhysicsRope.readStream(streamId, true)
	end
	self:run(connection)
end

function TreeAttachRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	writeSplitShapeIdToStream(streamId, self.splitShapeId)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
	if streamWriteBool(streamId, self.ropeIndex ~= nil) then
		streamWriteUIntN(streamId, self.ropeIndex, 3)
	end
	if streamWriteBool(streamId, self.setupRope ~= nil) then
		self.setupRope:writeStream(streamId)
	end
end

-- Local values: isAllowed, reason, isAllowed, reason
function TreeAttachRequestEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		if self.object.getIsCarriageTreeAttachAllowed ~= nil then
			local v17_, v18_ = self.object:getIsCarriageTreeAttachAllowed(self.splitShapeId)
			if v17_ then
				self.object:attachTreeToCarriage(self.splitShapeId, self.x, self.y, self.z, self.ropeIndex)
			else
				g_server:broadcastEvent(TreeAttachResponseEvent.new(self.object, v18_, self.ropeIndex), nil, nil, self.object, nil, { connection })
			end
		end
		if self.object.getIsWinchTreeAttachAllowed ~= nil then
			local v19_, v20_ = self.object:getIsWinchTreeAttachAllowed(self.ropeIndex, self.splitShapeId)
			if v19_ then
				self.object:attachTreeToWinch(self.splitShapeId, self.x, self.y, self.z, self.ropeIndex, self.setupRopeData)
				return
			end
			g_server:broadcastEvent(TreeAttachResponseEvent.new(self.object, v20_, self.ropeIndex), nil, nil, self.object, nil, { connection })
		end
	end
end
