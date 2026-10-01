TreeTransportMissionTree = {}
local TreeTransportMissionTree_mt = Class(TreeTransportMissionTree, PhysicsObject)
InitStaticObjectClass(TreeTransportMissionTree, "TreeTransportMissionTree")
function TreeTransportMissionTree.new(isServer, isClient, customMt)
	local self = PhysicsObject.new(isServer, isClient, customMt or TreeTransportMissionTree_mt)
	return self
end
function TreeTransportMissionTree:delete()
	if self.isServer and entityExists(self.nodeId) then
		removeWakeUpReport(self.nodeId)
	end
	self.nodeId = 0
	PhysicsObject:superClass().delete(self)
end
function TreeTransportMissionTree:readStream(streamId, connection)
	local entityId, splitShapeId1, splitShapeId2 = readSplitShapeIdFromStream(streamId)
	local x = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
	local y = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleYPosHighPrecisionCompressionParams)
	local z = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
	local xRot = NetworkUtil.readCompressedAngle(streamId)
	local yRot = NetworkUtil.readCompressedAngle(streamId)
	local zRot = NetworkUtil.readCompressedAngle(streamId)
	if entityId ~= 0 then
		self:setNodeId(entityId, x, y, z, xRot, yRot, zRot)
	else
		if splitShapeId1 ~= 0 then
			self.splitShapePart1 = splitShapeId1
			self.splitShapePart2 = splitShapeId2
			self.splitShapePositionData = { x, y, z, xRot, yRot, zRot }
			self:raiseActive()
		end
	end
end
function TreeTransportMissionTree:writeStream(streamId, connection)
	writeSplitShapeIdToStream(streamId, self.nodeId)
	local x, y, z = getWorldTranslation(self.nodeId)
	NetworkUtil.writeCompressedWorldPosition(streamId, x, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
	NetworkUtil.writeCompressedWorldPosition(streamId, y, g_currentMission.vehicleYPosHighPrecisionCompressionParams)
	NetworkUtil.writeCompressedWorldPosition(streamId, z, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
	local xRot, yRot, zRot = getWorldRotation(self.nodeId)
	NetworkUtil.writeCompressedAngle(streamId, xRot)
	NetworkUtil.writeCompressedAngle(streamId, yRot)
	NetworkUtil.writeCompressedAngle(streamId, zRot)
end
function TreeTransportMissionTree:setNodeId(nodeId, x, y, z, xRot, yRot, zRot)
	self.nodeId = nodeId
	setRigidBodyType(self.nodeId, self:getDefaultRigidBodyType())
	addToPhysics(self.nodeId)
	self.forcedClipDistance = getClipDistance(self.nodeId)
	if x == nil or y == nil or z == nil then
		x, y, z = getWorldTranslation(self.nodeId)
	end
	if xRot == nil or yRot == nil or zRot == nil then
		xRot, yRot, zRot = getWorldRotation(self.nodeId)
	end
	self.sendPosX = x
	self.sendPosY = y
	self.sendPosZ = z
	self.sendRotX = xRot
	self.sendRotY = yRot
	self.sendRotZ = zRot
	if not self.isServer then
		local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(xRot, yRot, zRot)
		self.positionInterpolator = InterpolatorPosition.new(x, y, z)
		self.quaternionInterpolator = InterpolatorQuaternion.new(quatX, quatY, quatZ, quatW)
	end
	if self.isServer then
		addWakeUpReport(nodeId, "onPhysicObjectWakeUpCallback", self)
	end
end
function TreeTransportMissionTree:update(dt)
	if not self.isServer and self.splitShapePart1 ~= nil then
		local entityId = resolveStreamSplitShapeId(self.splitShapePart1, self.splitShapePart2)
		if entityId ~= 0 then
			local x = self.splitShapePositionData[1]
			local y = self.splitShapePositionData[2]
			local z = self.splitShapePositionData[3]
			local xRot = self.splitShapePositionData[4]
			local yRot = self.splitShapePositionData[5]
			local zRot = self.splitShapePositionData[6]
			self:setNodeId(entityId, x, y, z, xRot, yRot, zRot)
			self.splitShapePart1 = nil
			self.splitShapePart2 = nil
			self.splitShapePositionData = nil
		else
			self:raiseActive()
		end
	end
	if entityExists(self.nodeId) then
		TreeTransportMissionTree:superClass().update(self, dt)
	end
end
function TreeTransportMissionTree:updateMove()
	if not entityExists(self.nodeId) then
		return false
	else
		return TreeTransportMissionTree:superClass().updateMove(self)
	end
end
function TreeTransportMissionTree:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	if not entityExists(self.nodeId) then
		return 0
	else
		return TreeTransportMissionTree:superClass().getUpdatePriority(self, skipCount, x, y, z, coeff, connection, isGuiVisible)
	end
end
function TreeTransportMissionTree:testScope(x, y, z, coeff, isGuiVisible)
	if not entityExists(self.nodeId) then
		return false
	else
		return TreeTransportMissionTree:superClass().testScope(self, x, y, z, coeff, isGuiVisible)
	end
end
function TreeTransportMissionTree:onGhostRemove()
	if not entityExists(self.nodeId) then
		return
	else
		TreeTransportMissionTree:superClass().onGhostRemove(self)
	end
end
function TreeTransportMissionTree:onGhostAdd()
	if not entityExists(self.nodeId) then
		return
	else
		TreeTransportMissionTree:superClass().onGhostAdd(self)
	end
end
function TreeTransportMissionTree:wakeUp()
	if not entityExists(self.nodeId) then
		return
	else
		TreeTransportMissionTree:superClass().wakeUp(self)
	end
end
function TreeTransportMissionTree:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	if not entityExists(self.nodeId) then
		return
	else
		TreeTransportMissionTree:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	end
end
function TreeTransportMissionTree:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	if not entityExists(self.nodeId) then
		return
	else
		TreeTransportMissionTree:superClass().setLocalPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	end
end
