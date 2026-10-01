ForestryLog = {}
local ForestryLog_mt = Class(ForestryLog, MountableObject)
InitStaticObjectClass(ForestryLog, "ForestryLog")
g_xmlManager:addInitSchemaFunction(function()
	local savegameSchema = ItemSystem.xmlSchemaSavegame
	local basePath = "items.item(?)"
	ForestryLog.registerSavegameXMLPaths(savegameSchema, "items.item(?)")
end)
function ForestryLog.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to log i3d file")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "log position")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "log rotation")
	schema:register(XMLValueType.INT, basePath .. "#farmId", "Id of owner farm")
	schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id of log")
end
function ForestryLog.new(isServer, isClient, customMt)
	local self = MountableObject.new(isServer, isClient, customMt or ForestryLog_mt)
	registerObjectClassName(self, "ForestryLog")
	self.uniqueId = nil
	return self
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
function ForestryLog:readStream(streamId, connection)
	local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	if self.nodeId == 0 then
		self:loadFromFilename(i3dFilename)
	end
end
function ForestryLog:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
end
function ForestryLog:loadFromFilename(i3dFilename, x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments)
	if i3dFilename == nil then
		return false
	end
	i3dFilename = NetworkUtil.convertFromNetworkFilename(i3dFilename)
	if not fileExists(i3dFilename) then
		return false
	end
	self.i3dFilename = i3dFilename
	if self.i3dFilename ~= nil then
		self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.i3dFilename)
		setSplitShapesLoadingFileId(-1)
		setSplitShapesNextFileId(true)
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, true, self.onForestryLogLoaded, self, { x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments })
		return true
	else
		return false
	end
end
function ForestryLog:onForestryLogLoaded(nodeId, failedReason, asyncCallbackArguments)
	local x = asyncCallbackArguments[1]
	local y = asyncCallbackArguments[2]
	local z = asyncCallbackArguments[3]
	local rx = asyncCallbackArguments[4]
	local ry = asyncCallbackArguments[5]
	local rz = asyncCallbackArguments[6]
	local asyncCallback = asyncCallbackArguments[7]
	local asyncTarget = asyncCallbackArguments[8]
	local asyncArguments = asyncCallbackArguments[9]
	if failedReason == LoadI3DFailedReason.NONE then
		local numChildren = getNumOfChildren(nodeId)
		local nodeIndex = math.random(0, numChildren - 1)
		local curNodeId = clone(getChildAt(nodeId, nodeIndex), false, false, true)
		link(getRootNode(), curNodeId)
		if x ~= nil and (y ~= nil and (z ~= nil and (rx ~= nil and (ry ~= nil and rz ~= nil)))) then
			setTranslation(curNodeId, x, y, z)
			setRotation(curNodeId, rx, ry, rz)
		end
		self:setNodeId(curNodeId)
		self.tensionBeltMeshes = {}
		g_currentMission.itemSystem:addItem(self)
		self:setForestryLogAIObstacle(true)
		delete(nodeId)
		if asyncCallback ~= nil then
			asyncCallback(asyncTarget, self, true, asyncArguments)
			return
		end
	end
	if asyncCallback ~= nil then
		asyncCallback(asyncTarget, self, false, asyncArguments)
	end
end
function ForestryLog:loadAsyncFromXMLFile(xmlFile, key, resetVehicles, asyncCallback, asyncTarget, asyncArguments)
	local x, y, z = xmlFile:getValue(key .. "#position")
	local rx, ry, rz = xmlFile:getValue(key .. "#rotation")
	if x == nil or y == nil or z == nil or rx == nil or ry == nil or rz == nil then
		return asyncCallback(asyncTarget, self, false, asyncArguments)
	end
	self:setUniqueId(xmlFile:getValue(key .. "#uniqueId", nil))
	local i3dFilename = xmlFile:getValue(key .. "#filename")
	if not self:loadFromFilename(i3dFilename, x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments) then
		return asyncCallback(asyncTarget, self, false, asyncArguments)
	else
		return
	end
end
function ForestryLog:saveToXMLFile(xmlFile, key)
	local x, y, z = getTranslation(self.nodeId)
	local xRot, yRot, zRot = getRotation(self.nodeId)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.i3dFilename)))
	xmlFile:setValue(key .. "#position", x, y, z)
	xmlFile:setValue(key .. "#rotation", xRot, yRot, zRot)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
end
function ForestryLog:mount(object, node, x, y, z, rx, ry, rz)
	ForestryLog:superClass().mount(self, object, node, x, y, z, rx, ry, rz)
	g_currentMission.itemSystem:removeItem(self)
	self:setForestryLogAIObstacle(false)
end
function ForestryLog:unmount()
	if ForestryLog:superClass().unmount(self) then
		g_currentMission.itemSystem:addItem(self)
		self:setForestryLogAIObstacle(true)
		return true
	else
		return false
	end
end
function ForestryLog:mountKinematic(object, node, x, y, z, rx, ry, rz)
	ForestryLog:superClass().mountKinematic(self, object, node, x, y, z, rx, ry, rz)
	g_currentMission.itemSystem:removeItem(self)
	self:setForestryLogAIObstacle(false)
end
function ForestryLog:unmountKinematic()
	if ForestryLog:superClass().unmountKinematic(self) then
		g_currentMission.itemSystem:addItem(self)
		self:setForestryLogAIObstacle(true)
		return true
	else
		return false
	end
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
		return
	end
	if not isActive and self.obstacleNodeId ~= nil then
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
