-- Local values: TreeTransportMissionTree_mt
TreeTransportMissionTree = {}
local TreeTransportMissionTree_mt = Class(TreeTransportMissionTree, PhysicsObject)
InitStaticObjectClass(TreeTransportMissionTree, "TreeTransportMissionTree")

-- Upvalues: TreeTransportMissionTree_mt
-- Local values: self
function TreeTransportMissionTree.new(isServer, isClient, customMt)
	-- upvalues: (copy) TreeTransportMissionTree_mt
	return PhysicsObject.new(isServer, isClient, customMt or TreeTransportMissionTree_mt)
end

function TreeTransportMissionTree:delete()
	if self.isServer and entityExists(self.nodeId) then
		removeWakeUpReport(self.nodeId)
	end
	self.nodeId = 0
	PhysicsObject:superClass().delete(self)
end

-- Local values: entityId, splitShapeId1, splitShapeId2, x, y, z, xRot, yRot, zRot
function TreeTransportMissionTree:readStream(streamId, connection)
	local v8_, v9_, v10_ = readSplitShapeIdFromStream(streamId)
	local v11_ = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
	local v12_ = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleYPosHighPrecisionCompressionParams)
	local v13_ = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
	local v14_ = NetworkUtil.readCompressedAngle(streamId)
	local v15_ = NetworkUtil.readCompressedAngle(streamId)
	local v16_ = NetworkUtil.readCompressedAngle(streamId)
	if v8_ == 0 then
		if v9_ ~= 0 then
			self.splitShapePart1 = v9_
			self.splitShapePart2 = v10_
			self.splitShapePositionData = {
				v11_,
				v12_,
				v13_,
				v14_,
				v15_,
				v16_
			}
			self:raiseActive()
		end
	else
		self:setNodeId(v8_, v11_, v12_, v13_, v14_, v15_, v16_)
	end
end

-- Local values: x, y, z, xRot, yRot, zRot
function TreeTransportMissionTree:writeStream(streamId, connection)
	writeSplitShapeIdToStream(streamId, self.nodeId)
	local v19_, v20_, v21_ = getWorldTranslation(self.nodeId)
	NetworkUtil.writeCompressedWorldPosition(streamId, v19_, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
	NetworkUtil.writeCompressedWorldPosition(streamId, v20_, g_currentMission.vehicleYPosHighPrecisionCompressionParams)
	NetworkUtil.writeCompressedWorldPosition(streamId, v21_, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
	local v22_, v23_, v24_ = getWorldRotation(self.nodeId)
	NetworkUtil.writeCompressedAngle(streamId, v22_)
	NetworkUtil.writeCompressedAngle(streamId, v23_)
	NetworkUtil.writeCompressedAngle(streamId, v24_)
end

-- Local values: quatX, quatY, quatZ, quatW
function TreeTransportMissionTree:setNodeId(nodeId, x, y, z, xRot, yRot, zRot)
	self.nodeId = nodeId
	setRigidBodyType(self.nodeId, self:getDefaultRigidBodyType())
	addToPhysics(self.nodeId)
	self.forcedClipDistance = getClipDistance(self.nodeId)
	if x == nil or (y == nil or z == nil) then
		x, y, z = getWorldTranslation(self.nodeId)
	end
	if xRot == nil or (yRot == nil or zRot == nil) then
		xRot, yRot, zRot = getWorldRotation(self.nodeId)
	end
	self.sendPosX = x
	self.sendPosY = y
	self.sendPosZ = z
	self.sendRotX = xRot
	self.sendRotY = yRot
	self.sendRotZ = zRot
	if not self.isServer then
		local v33_, v34_, v35_, v36_ = mathEulerToQuaternion(xRot, yRot, zRot)
		self.positionInterpolator = InterpolatorPosition.new(x, y, z)
		self.quaternionInterpolator = InterpolatorQuaternion.new(v33_, v34_, v35_, v36_)
	end
	if self.isServer then
		addWakeUpReport(nodeId, "onPhysicObjectWakeUpCallback", self)
	end
end

-- Local values: entityId, x, y, z, xRot, yRot, zRot
function TreeTransportMissionTree:update(dt)
	if not self.isServer and self.splitShapePart1 ~= nil then
		local v39_ = resolveStreamSplitShapeId(self.splitShapePart1, self.splitShapePart2)
		if v39_ == 0 then
			self:raiseActive()
		else
			self:setNodeId(v39_, self.splitShapePositionData[1], self.splitShapePositionData[2], self.splitShapePositionData[3], self.splitShapePositionData[4], self.splitShapePositionData[5], self.splitShapePositionData[6])
			self.splitShapePart1 = nil
			self.splitShapePart2 = nil
			self.splitShapePositionData = nil
		end
	end
	if entityExists(self.nodeId) then
		TreeTransportMissionTree:superClass().update(self, dt)
	end
end

function TreeTransportMissionTree:updateMove()
	if entityExists(self.nodeId) then
		return TreeTransportMissionTree:superClass().updateMove(self)
	else
		return false
	end
end

function TreeTransportMissionTree:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	return not entityExists(self.nodeId) and 0 or TreeTransportMissionTree:superClass().getUpdatePriority(self, skipCount, x, y, z, coeff, connection, isGuiVisible)
end

function TreeTransportMissionTree:testScope(x, y, z, coeff, isGuiVisible)
	if entityExists(self.nodeId) then
		return TreeTransportMissionTree:superClass().testScope(self, x, y, z, coeff, isGuiVisible)
	else
		return false
	end
end

function TreeTransportMissionTree:onGhostRemove()
	if entityExists(self.nodeId) then
		TreeTransportMissionTree:superClass().onGhostRemove(self)
	end
end

function TreeTransportMissionTree:onGhostAdd()
	if entityExists(self.nodeId) then
		TreeTransportMissionTree:superClass().onGhostAdd(self)
	end
end

function TreeTransportMissionTree:wakeUp()
	if entityExists(self.nodeId) then
		TreeTransportMissionTree:superClass().wakeUp(self)
	end
end

function TreeTransportMissionTree:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	if entityExists(self.nodeId) then
		TreeTransportMissionTree:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	end
end

function TreeTransportMissionTree:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	if entityExists(self.nodeId) then
		TreeTransportMissionTree:superClass().setLocalPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	end
end
