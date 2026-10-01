source("dataS/scripts/objects/AnimatedObject.lua")
FenceGate = {}
FenceGate.DEFAULT_PRICE_PER_M = FenceSegment.DEFAULT_PRICE_PER_M * 2
FenceGate.MIN_WIDTH_AI_BLOCKING_REGION = 3
local FenceGate_mt = Class(FenceGate, FenceSegment)
function FenceGate.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".gate#node", "")
	schema:register(XMLValueType.BOOL, basePath .. ".gate#alignY", "")
	schema:register(XMLValueType.BOOL, basePath .. ".gate#hasStartPole", "")
	schema:register(XMLValueType.BOOL, basePath .. ".gate#hasEndPole", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".gate#length", "length resp. width of the gate")
	schema:register(XMLValueType.FLOAT, basePath .. ".gate#depth", "depth of the gate including its doors used for overlap checking", "length / 2")
	schema:register(XMLValueType.FLOAT, basePath .. ".gate#depthOffset", "offset of overlap area", "depth / 2")
	AnimatedObject.registerXMLPaths(schema, basePath .. ".gate")
	schema:register(XMLValueType.BOOL, basePath .. ".gate.animatedObject(?)#useAIBlockingRegion", "Flag to enable AI blocking regions for the fence gate causing GoTo-AI agents to wait in front of gate and automatically open it", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".gate.animatedObject(?).aiBlockingRegion#stopDistance", "Distance the GoTo-AI agent waits in front of the blocking region", 2)
	schema:register(XMLValueType.FLOAT, basePath .. ".gate.animatedObject(?).aiBlockingRegion#openedStateAnimTime", "Normalized time [0..1] of the animation where the gate is in its opened state", 1)
end
function FenceGate.registerSavegameXMLPaths(schema, basePath)
	FenceSegment.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#reversed", "Segment is reversed")
	schema:register(XMLValueType.STRING, basePath .. ".animatedObject(?)#id")
	AnimatedObject.registerSavegameXMLPaths(schema, basePath .. ".animatedObject(?)")
end
function FenceGate.new(id, metadata, fence, customMt)
	local self = FenceGate:superClass().new(id, metadata, fence, customMt or FenceGate_mt)
	self.isReversed = false
	self.rootHidden = nil
	local xmlFile = XMLFile.load("fenceGateXML", self.fence.xmlFilename, Fence.xmlSchema)
	local i3dFilename = fence.i3dFilename
	local fenceI3d, sharedLoadRequestId, _ = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	local components = I3DUtil.loadI3DComponents(fenceI3d)
	local i3dMapping = I3DUtil.loadI3DMapping(xmlFile, nil, components)
	local gate = self.metadata.gate
	local node = xmlFile:getNode(gate.xmlKey .. "#node", nil, components, i3dMapping)
	unlink(node)
	self.rootHidden = node
	delete(fenceI3d)
	g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
	for _, animatedObjectKey in xmlFile:iterator(gate.xmlKey .. ".animatedObject") do
		local animatedObject = AnimatedObject.new(g_server ~= nil, g_client ~= nil)
		animatedObject:load(node, xmlFile, animatedObjectKey, xmlFile:getFilename(), i3dMapping)
		animatedObject.getCanBeTriggered = Utils.overwrittenFunction(animatedObject.getCanBeTriggered, function(_, superFunc)
			if not superFunc(animatedObject) then
				return false
			end
			local playerFarmId = g_currentMission:getFarmId()
			local mission = g_missionManager:getMissionByFarmlandId(self.farmlandId)
			if mission ~= nil and g_currentMission.accessHandler:canFarmAccessOtherId(playerFarmId, mission.farmId) then
				return true
			end
			local farmlandOwnerFarmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)
			if not g_currentMission.accessHandler:canFarmAccessOtherId(playerFarmId, farmlandOwnerFarmId) then
				return false
			else
				return true
			end
		end)
		local useAIBlockingRegion = xmlFile:getBool(animatedObjectKey .. "#useAIBlockingRegion")
		if useAIBlockingRegion and FenceGate.MIN_WIDTH_AI_BLOCKING_REGION < self.metadata.gate.length then
			animatedObject.aiBlockingRegion = { stopDistance = xmlFile:getFloat(animatedObjectKey .. ".aiBlockingRegion#stopDistance"), openedStateAnimTime = xmlFile:getFloat(animatedObjectKey .. ".aiBlockingRegion#openedStateAnimTime") or 1 }
		end
		self.animatedObjects = self.animatedObjects or {}
		table.insert(self.animatedObjects, animatedObject)
		animatedObject:register(true)
	end
	xmlFile:delete()
	return self
end
function FenceGate.loadMetadataFromXML(xmlFile, key, id, fence)
	local metadata = FenceSegment.loadMetadataFromXML(xmlFile, key, id, fence)
	metadata.class = FenceGate
	local gateKey = key .. ".gate"
	local length = xmlFile:getFloat(gateKey .. "#length")
	local depth = xmlFile:getFloat(gateKey .. "#depth")
	local depthOffset = xmlFile:getFloat(gateKey .. "#depthOffset")
	local alignY = xmlFile:getBool(gateKey .. "#alignY")
	local hasStartPole = xmlFile:getBool(gateKey .. "#hasStartPole", true)
	local hasEndPole = xmlFile:getBool(gateKey .. "#hasEndPole", true)
	metadata.gate = { xmlKey = gateKey, length = length, depth = depth, alignY = alignY, depthOffset = depthOffset, hasStartPole = hasStartPole, hasEndPole = hasEndPole }
	return metadata
end
function FenceGate:delete()
	if self.animatedObjects ~= nil then
		for _, animatedObject in ipairs(self.animatedObjects) do
			if animatedObject.aiBlockingRegion ~= nil then
				g_currentMission.aiSystem:removeBlockingRegion(animatedObject.aiBlockingRegion.blockingRegionId)
				animatedObject.aiBlockingRegion = nil
			end
			animatedObject:delete()
		end
		self.animatedObjects = nil
	end
	if self.rootHidden ~= nil then
		delete(self.rootHidden)
		self.rootHidden = nil
	end
	g_messageCenter:unsubscribe(MessageType.FARMLAND_OWNER_CHANGED, self)
	FenceGate:superClass().delete(self)
end
function FenceGate:loadFromXMLFile(xmlFile, key)
	self.isReversed = xmlFile:getBool(key .. "#reversed", false)
	if not FenceGate:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	else
		local needsUpdate = false
		local isNewSavegame = not g_currentMission.missionInfo.isValid
		local startY = getTerrainHeightAtWorldPos(g_terrainNode, self.startPosX, 0, self.startPosZ)
		if isNewSavegame or self.startPosY < startY then
			self.startPosY = startY
			needsUpdate = true
		end
		local endY = getTerrainHeightAtWorldPos(g_terrainNode, self.endPosX, 0, self.endPosZ)
		if isNewSavegame or self.endPosY < endY then
			self.endPosY = endY
			needsUpdate = true
		end
		if needsUpdate then
			self:updateMeshes(true, false)
		end
		for _, animatedObjectKey in xmlFile:iterator(key .. ".animatedObject") do
			local id = xmlFile:getString(animatedObjectKey .. "#id")
			for _, animatedObject in ipairs(self.animatedObjects) do
				if animatedObject.saveId == id then
					animatedObject:loadFromXMLFile(xmlFile, animatedObjectKey)
				end
			end
		end
		return true
	end
end
function FenceGate:saveToXMLFile(xmlFile, key)
	if not FenceGate:superClass().saveToXMLFile(self, xmlFile, key) then
		return false
	else
		if self.isReversed then
			xmlFile:setBool(key .. "#reversed", self.isReversed)
		end
		if self.animatedObjects ~= nil then
			local index = 0
			for _, animatedObject in ipairs(self.animatedObjects) do
				local animatedObjectKey = string.format("%s.animatedObject(%d)", key, index)
				xmlFile:setString(animatedObjectKey .. "#id", animatedObject.saveId)
				animatedObject:saveToXMLFile(xmlFile, animatedObjectKey)
				index = index + 1
			end
		end
		return true
	end
end
function FenceGate:readStream(streamId, connection, lastSegment)
	FenceGate:superClass().readStream(self, streamId, connection, lastSegment)
	self.isReversed = streamReadBool(streamId)
	if connection:getIsServer() and self.animatedObjects ~= nil then
		for _, animatedObject in ipairs(self.animatedObjects) do
			local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
			animatedObject:readStream(streamId, connection)
			g_client:finishRegisterObject(animatedObject, animatedObjectId)
		end
	end
end
function FenceGate:writeStream(streamId, connection, lastSegment)
	FenceGate:superClass().writeStream(self, streamId, connection, lastSegment)
	streamWriteBool(streamId, self.isReversed)
	if not connection:getIsServer() and self.animatedObjects ~= nil then
		for _, animatedObject in ipairs(self.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
			animatedObject:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, animatedObject)
		end
	end
end
function FenceGate:registerTerrainHeightChangeCallbacks() end
function FenceGate:getPrice()
	return self:getActualLength() * (self.metadata.price or FenceGate.DEFAULT_PRICE_PER_M)
end
function FenceGate:setIsReversed(isReversed)
	self.isReversed = isReversed
	self:updateMeshes(true)
end
function FenceGate:getIsReversed()
	return self.isReversed
end
function FenceGate:updateMeshes(force, validatePlacement)
	force = Utils.getNoNil(force, false)
	validatePlacement = Utils.getNoNil(validatePlacement, true)
	self.lastError = nil
	if not force and not self.isDirty then
		return true
	end
	if self.startPosX == nil or self.endPosX == nil then
		return false
	end
	if not entityExists(self.root) then
		return false
	else
		local terrain = g_terrainNode or getChild(getRootNode(), "terrain")
		for i = getNumOfChildren(self.root) - 1, 0, -1 do
			local child = getChildAt(self.root, i)
			removeFromPhysics(child)
			unlink(child)
			self.rootHidden = child
		end
		if validatePlacement then
			local length = MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ)
			if length < 0.1 then
				self.lastError = FenceSegment.ERROR_TOO_SHORT
				return false
			end
			if MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ) < 0.1 then
				self.lastError = FenceSegment.ERROR_TOO_SHORT
				return false
			end
		end
		local lengthXZ = MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
		local curLen = 0
		local dx, dz = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
		local x = nil
		local y = nil
		local z = nil
		local gate = self.metadata.gate
		if 0.1 <= lengthXZ - curLen then
			x = self.startPosX
			y = self.startPosY
			z = self.startPosZ
			local _x = self.endPosX
			local yTest = self.endPosY
			local _z = self.endPosZ
			if validatePlacement then
				x, y, z = self:lerpOnTerrain(terrain, curLen / lengthXZ)
				_x, yTest, _z = self:lerpOnTerrain(terrain, (curLen + gate.length) / lengthXZ)
				local slopeAngle = math.abs(math.atan((y - yTest) / gate.length))
				if self.metadata.maxSlopeAngle < slopeAngle then
					self.lastError = FenceSegment.ERROR_TOO_STEEP
					return false
				end
			end
			local gateNode = self.rootHidden
			removeFromPhysics(gateNode)
			link(self.root, gateNode)
			self.rootHidden = nil
			local actualPanelLength = gate.length
			local posX = x
			local posY = y
			local posZ = z
			local dirX = dx
			local dirY = 0
			local dirZ = dz
			local endX = _x
			local endY = yTest
			local endZ = _z
			if gate.alignY then
				dirX, dirY, dirZ = MathUtil.vector3Normalize(endX - x, endY - y, endZ - z)
				if validatePlacement then
					endX = x + dirX * gate.length
					endY = y + dirY * gate.length
					endZ = z + dirZ * gate.length
					if terrain ~= nil and terrain ~= 0 then
						endY = getTerrainHeightAtWorldPos(terrain, endX, 0, endZ)
					end
					dirX, dirY, dirZ = MathUtil.vector3Normalize(endX - x, endY - y, endZ - z)
				end
				actualPanelLength = MathUtil.vector2Length(endX - x, endZ - z)
			end
			curLen = curLen + actualPanelLength
			if self.isReversed then
				posX = endX
				posY = endY
				posZ = endZ
				dirX = -dirX
				dirY = -dirY
				dirZ = -dirZ
			end
			setWorldTranslation(gateNode, posX, posY, posZ)
			setWorldDirection(gateNode, dirX, dirY, dirZ, 0, 1, 0)
		end
		x, y, z = self:lerpOnTerrain(terrain, curLen / lengthXZ)
		self.actualEndX = x
		self.actualEndY = y
		self.actualEndZ = z
		if self.notYetFinalized and self.animatedObjects ~= nil then
			for _, animatedObject in ipairs(self.animatedObjects) do
				animatedObject:setAnimTime(0.4)
			end
		end
		self.isDirty = false
		return true
	end
end
function FenceGate:lerpOnTerrain(terrain, alpha)
	local x = nil
	local y = nil
	local z = nil
	if terrain == nil or terrain == 0 then
		return MathUtil.vector3Lerp(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, alpha)
	end
	x, z = MathUtil.vector2Lerp(self.startPosX, self.startPosZ, self.endPosX, self.endPosZ, alpha)
	y = getTerrainHeightAtWorldPos(terrain, x, 0, z)
	return x, y, z
end
function FenceGate:getOverlapBox()
	local gate = self.metadata.gate
	local dx, dz = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
	local cx = (self.startPosX + self.actualEndX) / 2
	local cy = (self.startPosY + self.actualEndY) / 2
	local cz = (self.startPosZ + self.actualEndZ) / 2
	local halfWidth = gate.depth or gate.length / 2
	local widthOffset = (gate.depthOffset or halfWidth) / 2
	cx = cx - dz * widthOffset * (self.isReversed and -1 or 1)
	cz = cz + dx * widthOffset * (self.isReversed and -1 or 1)
	local rx = 0
	local ry = math.atan2(self.actualEndX - self.startPosX, self.actualEndZ - self.startPosZ) + 6.283185307179586
	local rz = 0
	local height = gate.height or 2
	local ex = math.max(halfWidth / 2, 0.05)
	local ey = math.abs(self.actualEndY - self.startPosY) / 2 + height
	local ez = gate.length / 2
	return cx, cy, cz, 0, ry, 0, ex, ey, ez
end
function FenceGate:update()
	local hitNodes = {}
	self:checkOverlap(hitNodes)
end
function FenceGate:finalize(loadedFromSavegame)
	if not FenceGate:superClass().finalize(self, loadedFromSavegame) then
		return false
	else
		if self.animatedObjects ~= nil then
			for _, animatedObject in ipairs(self.animatedObjects) do
				if not loadedFromSavegame then
					animatedObject:setAnimTime(0)
				end
				if g_server == nil or animatedObject.aiBlockingRegion == nil or g_currentMission == nil or g_currentMission.aiSystem == nil then
					continue
				end
				local aiBlockingRegion = animatedObject.aiBlockingRegion or {}
				local x, y, z, rx, ry, rz, ex, ey, ez = self:getOverlapBox()
				local stopDistance = aiBlockingRegion.stopDistance or 2
				aiBlockingRegion.blockingRegionId = g_currentMission.aiSystem:addBlockingRegion(x, y, z, rx, ry, rz, ex * 2, ey * 2, ez * 2, stopDistance, "blockingPositionCallback", self)
			end
		end
		if g_farmlandManager ~= nil then
			self.farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(self.startPosX, self.startPosZ)
			self:updateOwnerFarmId()
		end
		if g_messageCenter ~= nil then
			g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
		end
		return true
	end
end
function FenceGate:blockingPositionCallback(_, agentId, blockerId)
	for _, animatedObject in ipairs(self.animatedObjects) do
		local openedStateAnimTime = animatedObject.aiBlockingRegion.openedStateAnimTime
		if animatedObject.animation.time == 1 - openedStateAnimTime then
			animatedObject:setDirection(openedStateAnimTime)
		end
		if animatedObject.animation.time == openedStateAnimTime then
			g_currentMission.aiSystem:setBlockingRegionState(blockerId, false)
		end
	end
end
function FenceGate:setOwnerFarmId(ownerFarmId, noEventSend)
	FenceGate:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
	if self.animatedObjects ~= nil then
		for _, animatedObject in ipairs(self.animatedObjects) do
			animatedObject:setOwnerFarmId(ownerFarmId, true)
		end
	end
end
function FenceGate:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
	if self.farmlandId == farmlandId then
		self:updateOwnerFarmId()
	end
end
function FenceGate:updateOwnerFarmId()
	local farmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)
	if self.animatedObjects ~= nil then
		for _, animatedObject in ipairs(self.animatedObjects) do
			animatedObject:setOwnerFarmId(farmId, true)
		end
	end
end
function FenceGate:getHasVisualStartPole()
	if self.isReversed then
		return self.metadata.gate.hasEndPole
	else
		return self.metadata.gate.hasStartPole
	end
end
function FenceGate:getHasVisualEndPole()
	if self.isReversed then
		return self.metadata.gate.hasStartPole
	else
		return self.metadata.gate.hasEndPole
	end
end
function FenceGate:getSegmentPartStartEnd(node)
	node = self:getSegmentPartFromNode(node)
	if node == nil then
		return nil
	else
		local sx, sy, sz = getWorldTranslation(node)
		local isFirst = MathUtil.vector3Length(sx - self.startPosX, sy - self.startPosY, sz - self.startPosZ) < 0.01
		local isLast = MathUtil.vector3Length(sx - self.endPosX, sy - self.endPosY, sz - self.endPosZ) < 0.01
		return self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, isFirst, isLast
	end
end
