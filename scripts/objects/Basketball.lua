-- Local values: Basketball_mt
Basketball = {}
local Basketball_mt = Class(Basketball, PhysicsObject)
InitStaticObjectClass(Basketball, "Basketball")

-- Local values: basketball, x, y, z, rx, ry, rz, filename
function Basketball:onCreate(id)
	local v3_ = Basketball.new(g_server ~= nil, g_client ~= nil)
	local v4_, v5_, v6_ = getWorldTranslation(id)
	local v7_, v8_, v9_ = getWorldRotation(id)
	local v10_ = Utils.getNoNil(getUserAttribute(id, "filename"), "$data/objects/basketball/basketball.i3d")
	if v3_:load(Utils.getFilename(v10_, g_currentMission.loadingMapBaseDirectory), v4_, v5_, v6_, v7_, v8_, v9_) then
		g_currentMission.onCreateObjectSystem:add(v3_)
		v3_:register(true)
	else
		v3_:delete()
	end
end

-- Upvalues: Basketball_mt
-- Local values: self
function Basketball.new(isServer, isClient, customMt)
	-- upvalues: (copy) Basketball_mt
	local v14_ = PhysicsObject.new(isServer, isClient, customMt or Basketball_mt)
	v14_.forcedClipDistance = 150
	v14_.sharedLoadRequestId = nil
	registerObjectClassName(v14_, "Basketball")
	return v14_
end

function Basketball:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	unregisterObjectClassName(self)
	Basketball:superClass().delete(self)
end

-- Local values: i3dFilename
function Basketball:readStream(streamId, connection)
	if connection:getIsServer() then
		local v19_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		if self.nodeId == 0 then
			self:createNode(v19_)
		end
		Basketball:superClass().readStream(self, streamId, connection)
	end
end

function Basketball:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
		Basketball:superClass().writeStream(self, streamId, connection)
	end
end

-- Local values: basketballRoot, sharedLoadRequestId, basketballId
function Basketball:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	local v25_, v26_ = Utils.getModNameAndBaseDirectory(i3dFilename)
	self.customEnvironment = v25_
	self.baseDirectory = v26_
	local v27_, v28_ = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = v28_
	local v29_ = getChildAt(v27_, 0)
	link(getRootNode(), v29_)
	delete(v27_)
	self:setNodeId(v29_)
end

function Basketball:load(i3dFilename, x, y, z, rx, ry, rz)
	self.i3dFilename = i3dFilename
	local v38_, v39_ = Utils.getModNameAndBaseDirectory(i3dFilename)
	self.customEnvironment = v38_
	self.baseDirectory = v39_
	self:createNode(i3dFilename)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)
	return true
end
