-- Local values: MissionPhysicsObject_mt
MissionPhysicsObject = {}
local MissionPhysicsObject_mt = Class(MissionPhysicsObject, MountableObject)
InitStaticObjectClass(MissionPhysicsObject, "MissionPhysicsObject")

-- Upvalues: MissionPhysicsObject_mt
-- Local values: self
function MissionPhysicsObject.new(isServer, isClient, customMt)
	-- upvalues: (copy) MissionPhysicsObject_mt
	local v5_ = MountableObject.new(isServer, isClient, customMt or MissionPhysicsObject_mt)
	v5_.forcedClipDistance = 80
	v5_.meshNodes = {}
	v5_.sharedLoadRequestId = nil
	return v5_
end

function MissionPhysicsObject:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	MissionPhysicsObject:superClass().delete(self)
end

-- Local values: i3dFilename
function MissionPhysicsObject:readStream(streamId, connection)
	local v10_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	if self.nodeId == 0 then
		self:createNode(v10_)
	end
	MissionPhysicsObject:superClass().readStream(self, streamId, connection)
end

function MissionPhysicsObject:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
	MissionPhysicsObject:superClass().writeStream(self, streamId, connection)
end

-- Local values: rootNode, sharedLoadRequestId, nodeId
function MissionPhysicsObject:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	local v16_, v17_ = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = v17_
	local v18_ = getChildAt(v16_, 0)
	link(getRootNode(), v18_)
	delete(v16_)
	self:setNodeId(v18_)
end

-- Local values: meshNode
function MissionPhysicsObject:setNodeId(nodeId)
	MissionPhysicsObject:superClass().setNodeId(self, nodeId)
	local v21_ = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "meshNode"))
	if v21_ ~= nil then
		self.meshNodes = { v21_ }
	end
end

function MissionPhysicsObject:load(i3dFilename, x, y, z, rx, ry, rz)
	self.i3dFilename = i3dFilename
	self:createNode(i3dFilename)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)
	return true
end

function MissionPhysicsObject:loadFromMemory(nodeId, i3dFilename)
	self.i3dFilename = i3dFilename
	self:setNodeId(nodeId)
end

function MissionPhysicsObject:getSupportsTensionBelts()
	return true
end

function MissionPhysicsObject:getTensionBeltNodeId()
	return self.nodeId
end

function MissionPhysicsObject:getMeshNodes()
	return self.meshNodes
end
