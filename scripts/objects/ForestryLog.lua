-- Local values: ForestryLog_mt
ForestryLog = {}
local ForestryLog_mt = Class(ForestryLog, MountableObject)
InitStaticObjectClass(ForestryLog, "ForestryLog")
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = ItemSystem.xmlSchemaSavegame
	ForestryLog.registerSavegameXMLPaths(v2_, "items.item(?)")
end)

function ForestryLog.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to log i3d file")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "log position")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "log rotation")
	schema:register(XMLValueType.INT, basePath .. "#farmId", "Id of owner farm")
	schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id of log")
end

-- Upvalues: ForestryLog_mt
-- Local values: self
function ForestryLog.new(isServer, isClient, customMt)
	-- upvalues: (copy) ForestryLog_mt
	local v8_ = MountableObject.new(isServer, isClient, customMt or ForestryLog_mt)
	registerObjectClassName(v8_, "ForestryLog")
	v8_.uniqueId = nil
	return v8_
end

function ForestryLog:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	self:setForestryLogAIObstacle(false)
	unregisterObjectClassName(self)
	g_currentMission.itemSystem:removeItem(self)
	ForestryLog:superClass().delete(self)
end

-- Local values: i3dFilename
function ForestryLog:readStream(streamId, connection)
	local v12_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	if self.nodeId == 0 then
		self:loadFromFilename(v12_)
	end
end

function ForestryLog:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
end

function ForestryLog:loadFromFilename(i3dFilename, x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments)
	if i3dFilename == nil then
		return false
	end
	local v26_ = NetworkUtil.convertFromNetworkFilename(i3dFilename)
	if not fileExists(v26_) then
		return false
	end
	self.i3dFilename = v26_
	if self.i3dFilename == nil then
		return false
	end
	local v27_, v28_ = Utils.getModNameAndBaseDirectory(self.i3dFilename)
	self.customEnvironment = v27_
	self.baseDirectory = v28_
	setSplitShapesLoadingFileId(-1)
	setSplitShapesNextFileId(true)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, true, self.onForestryLogLoaded, self, {
		x,
		y,
		z,
		rx,
		ry,
		rz,
		asyncCallback,
		asyncTarget,
		asyncArguments
	})
	return true
end

-- Local values: x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments, numChildren, nodeIndex, curNodeId
function ForestryLog:onForestryLogLoaded(nodeId, failedReason, asyncCallbackArguments)
	local v33_ = asyncCallbackArguments[1]
	local v34_ = asyncCallbackArguments[2]
	local v35_ = asyncCallbackArguments[3]
	local v36_ = asyncCallbackArguments[4]
	local v37_ = asyncCallbackArguments[5]
	local v38_ = asyncCallbackArguments[6]
	local v39_ = asyncCallbackArguments[7]
	local v40_ = asyncCallbackArguments[8]
	local v41_ = asyncCallbackArguments[9]
	if failedReason == LoadI3DFailedReason.NONE then
		local v42_ = getNumOfChildren(nodeId)
		local v43_ = math.random(0, v42_ - 1)
		local v44_ = clone(getChildAt(nodeId, v43_), false, false, true)
		link(getRootNode(), v44_)
		if v33_ ~= nil and (v34_ ~= nil and (v35_ ~= nil and (v36_ ~= nil and (v37_ ~= nil and v38_ ~= nil)))) then
			setTranslation(v44_, v33_, v34_, v35_)
			setRotation(v44_, v36_, v37_, v38_)
		end
		self:setNodeId(v44_)
		self.tensionBeltMeshes = {}
		g_currentMission.itemSystem:addItem(self)
		self:setForestryLogAIObstacle(true)
		delete(nodeId)
		if v39_ ~= nil then
			v39_(v40_, self, true, v41_)
			return
		end
	end
	if v39_ ~= nil then
		v39_(v40_, self, false, v41_)
	end
end

-- Local values: x, y, z, rx, ry, rz, i3dFilename
function ForestryLog:loadAsyncFromXMLFile(xmlFile, key, resetVehicles, asyncCallback, asyncTarget, asyncArguments)
	local v51_, v52_, v53_ = xmlFile:getValue(key .. "#position")
	local v54_, v55_, v56_ = xmlFile:getValue(key .. "#rotation")
	if v51_ == nil or (v52_ == nil or (v53_ == nil or (v54_ == nil or (v55_ == nil or v56_ == nil)))) then
		return asyncCallback(asyncTarget, self, false, asyncArguments)
	end
	self:setUniqueId(xmlFile:getValue(key .. "#uniqueId", nil))
	if not self:loadFromFilename(xmlFile:getValue(key .. "#filename"), v51_, v52_, v53_, v54_, v55_, v56_, asyncCallback, asyncTarget, asyncArguments) then
		return asyncCallback(asyncTarget, self, false, asyncArguments)
	end
end

-- Local values: x, y, z, xRot, yRot, zRot
function ForestryLog:saveToXMLFile(xmlFile, key)
	local v60_, v61_, v62_ = getTranslation(self.nodeId)
	local v63_, v64_, v65_ = getRotation(self.nodeId)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.i3dFilename)))
	xmlFile:setValue(key .. "#position", v60_, v61_, v62_)
	xmlFile:setValue(key .. "#rotation", v63_, v64_, v65_)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
end

function ForestryLog:mount(object, node, x, y, z, rx, ry, rz)
	ForestryLog:superClass().mount(self, object, node, x, y, z, rx, ry, rz)
	g_currentMission.itemSystem:removeItem(self)
	self:setForestryLogAIObstacle(false)
end

function ForestryLog:unmount()
	if not ForestryLog:superClass().unmount(self) then
		return false
	end
	g_currentMission.itemSystem:addItem(self)
	self:setForestryLogAIObstacle(true)
	return true
end

function ForestryLog:mountKinematic(object, node, x, y, z, rx, ry, rz)
	ForestryLog:superClass().mountKinematic(self, object, node, x, y, z, rx, ry, rz)
	g_currentMission.itemSystem:removeItem(self)
	self:setForestryLogAIObstacle(false)
end

function ForestryLog:unmountKinematic()
	if not ForestryLog:superClass().unmountKinematic(self) then
		return false
	end
	g_currentMission.itemSystem:addItem(self)
	self:setForestryLogAIObstacle(true)
	return true
end

function ForestryLog:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
	ForestryLog:superClass().mountDynamic(self, object, objectActorId, jointNode, mountType, forceAcceleration)
	self:setForestryLogAIObstacle(false)
end

function ForestryLog:unmountDynamic(isDelete)
	ForestryLog:superClass().unmountDynamic(self, isDelete)
	self:setForestryLogAIObstacle(true)
end

function ForestryLog:setForestryLogAIObstacle(isActive)
	if isActive and self.obstacleNodeId == nil then
		g_currentMission.aiSystem:addObstacle(self.nodeId, nil, nil, nil, nil, nil, nil, nil)
		self.obstacleNodeId = self.nodeId
	elseif not isActive and self.obstacleNodeId ~= nil then
		g_currentMission.aiSystem:removeObstacle(self.obstacleNodeId)
		self.obstacleNodeId = nil
	end
end

function ForestryLog:getMeshNodes()
	return self.tensionBeltMeshes
end

function ForestryLog:getSupportsTensionBelts()
	return true
end

function ForestryLog:getAllowPickup()
	return false
end

function ForestryLog:getDefaultRigidBodyType()
	return RigidBodyType.KINEMATIC
end

function ForestryLog:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end

function ForestryLog:getUniqueId()
	return self.uniqueId
end
