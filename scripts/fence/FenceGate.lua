-- Local values: FenceGate_mt
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

-- Upvalues: FenceGate_mt
-- Local values: self, xmlFile, i3dFilename, fenceI3d, sharedLoadRequestId, _, components, i3dMapping, gate, node, _, animatedObjectKey, animatedObject, useAIBlockingRegion
function FenceGate.new(id, metadata, fence, customMt)
	-- upvalues: (copy) FenceGate_mt
	local v_u_10_ = FenceGate:superClass().new(id, metadata, fence, customMt or FenceGate_mt)
	v_u_10_.isReversed = false
	v_u_10_.rootHidden = nil
	local v11_ = XMLFile.load("fenceGateXML", v_u_10_.fence.xmlFilename, Fence.xmlSchema)
	local v12_ = fence.i3dFilename
	local v13_, v14_, _ = g_i3DManager:loadSharedI3DFile(v12_, false, false)
	local v15_ = I3DUtil.loadI3DComponents(v13_)
	local v16_ = I3DUtil.loadI3DMapping(v11_, nil, v15_)
	local v17_ = v_u_10_.metadata.gate
	local v18_ = v11_:getNode(v17_.xmlKey .. "#node", nil, v15_, v16_)
	unlink(v18_)
	v_u_10_.rootHidden = v18_
	delete(v13_)
	g_i3DManager:releaseSharedI3DFile(v14_)
	for _, v19_ in v11_:iterator(v17_.xmlKey .. ".animatedObject") do
		local v_u_20_ = AnimatedObject.new(g_server ~= nil, g_client ~= nil)
		v_u_20_:load(v18_, v11_, v19_, v11_:getFilename(), v16_)
		v_u_20_.getCanBeTriggered = Utils.overwrittenFunction(v_u_20_.getCanBeTriggered, function(_, p21_)
			-- upvalues: (copy) v_u_20_, (copy) v_u_10_
			if not p21_(v_u_20_) then
				return false
			end
			local v22_ = g_currentMission:getFarmId()
			local v23_ = g_missionManager:getMissionByFarmlandId(v_u_10_.farmlandId)
			if v23_ ~= nil and g_currentMission.accessHandler:canFarmAccessOtherId(v22_, v23_.farmId) then
				return true
			end
			local v24_ = g_farmlandManager:getFarmlandOwner(v_u_10_.farmlandId)
			return g_currentMission.accessHandler:canFarmAccessOtherId(v22_, v24_) and true or false
		end)
		if v11_:getBool(v19_ .. "#useAIBlockingRegion") and v_u_10_.metadata.gate.length > FenceGate.MIN_WIDTH_AI_BLOCKING_REGION then
			v_u_20_.aiBlockingRegion = {
				["stopDistance"] = v11_:getFloat(v19_ .. ".aiBlockingRegion#stopDistance"),
				["openedStateAnimTime"] = v11_:getFloat(v19_ .. ".aiBlockingRegion#openedStateAnimTime") or 1
			}
		end
		v_u_10_.animatedObjects = v_u_10_.animatedObjects or {}
		local v25_ = v_u_10_.animatedObjects
		table.insert(v25_, v_u_20_)
		v_u_20_:register(true)
	end
	v11_:delete()
	return v_u_10_
end

-- Local values: metadata, gateKey, length, depth, depthOffset, alignY, hasStartPole, hasEndPole
function FenceGate.loadMetadataFromXML(xmlFile, key, id, fence)
	local v30_ = FenceSegment.loadMetadataFromXML(xmlFile, key, id, fence)
	v30_.class = FenceGate
	local v31_ = key .. ".gate"
	local v32_ = xmlFile:getFloat(v31_ .. "#length")
	local v33_ = xmlFile:getFloat(v31_ .. "#depth")
	local v34_ = xmlFile:getFloat(v31_ .. "#depthOffset")
	v30_.gate = {
		["xmlKey"] = v31_,
		["length"] = v32_,
		["depth"] = v33_,
		["alignY"] = xmlFile:getBool(v31_ .. "#alignY"),
		["depthOffset"] = v34_,
		["hasStartPole"] = xmlFile:getBool(v31_ .. "#hasStartPole", true),
		["hasEndPole"] = xmlFile:getBool(v31_ .. "#hasEndPole", true)
	}
	return v30_
end

-- Local values: _, animatedObject
function FenceGate:delete()
	if self.animatedObjects ~= nil then
		for _, v36_ in ipairs(self.animatedObjects) do
			if v36_.aiBlockingRegion ~= nil then
				g_currentMission.aiSystem:removeBlockingRegion(v36_.aiBlockingRegion.blockingRegionId)
				v36_.aiBlockingRegion = nil
			end
			v36_:delete()
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

-- Local values: needsUpdate, isNewSavegame, startY, endY, _, animatedObjectKey, id, _, animatedObject
function FenceGate:loadFromXMLFile(xmlFile, key)
	self.isReversed = xmlFile:getBool(key .. "#reversed", false)
	if not FenceGate:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	local v40_ = not g_currentMission.missionInfo.isValid
	local v41_ = getTerrainHeightAtWorldPos(g_terrainNode, self.startPosX, 0, self.startPosZ)
	local v42_
	if v40_ or self.startPosY < v41_ then
		self.startPosY = v41_
		v42_ = true
	else
		v42_ = false
	end
	local v43_ = getTerrainHeightAtWorldPos(g_terrainNode, self.endPosX, 0, self.endPosZ)
	if v40_ or self.endPosY < v43_ then
		self.endPosY = v43_
		v42_ = true
	end
	if v42_ then
		self:updateMeshes(true, false)
	end
	for _, v44_ in xmlFile:iterator(key .. ".animatedObject") do
		local v45_ = xmlFile:getString(v44_ .. "#id")
		for _, v46_ in ipairs(self.animatedObjects) do
			if v46_.saveId == v45_ then
				v46_:loadFromXMLFile(xmlFile, v44_)
			end
		end
	end
	return true
end

-- Local values: index, _, animatedObject, animatedObjectKey
function FenceGate:saveToXMLFile(xmlFile, key)
	if not FenceGate:superClass().saveToXMLFile(self, xmlFile, key) then
		return false
	end
	if self.isReversed then
		xmlFile:setBool(key .. "#reversed", self.isReversed)
	end
	if self.animatedObjects ~= nil then
		local v50_ = 0
		for _, v51_ in ipairs(self.animatedObjects) do
			local v52_ = string.format("%s.animatedObject(%d)", key, v50_)
			xmlFile:setString(v52_ .. "#id", v51_.saveId)
			v51_:saveToXMLFile(xmlFile, v52_)
			v50_ = v50_ + 1
		end
	end
	return true
end

-- Local values: _, animatedObject, animatedObjectId
function FenceGate:readStream(streamId, connection, lastSegment)
	FenceGate:superClass().readStream(self, streamId, connection, lastSegment)
	self.isReversed = streamReadBool(streamId)
	if connection:getIsServer() and self.animatedObjects ~= nil then
		for _, v57_ in ipairs(self.animatedObjects) do
			local v58_ = NetworkUtil.readNodeObjectId(streamId)
			v57_:readStream(streamId, connection)
			g_client:finishRegisterObject(v57_, v58_)
		end
	end
end

-- Local values: _, animatedObject
function FenceGate:writeStream(streamId, connection, lastSegment)
	FenceGate:superClass().writeStream(self, streamId, connection, lastSegment)
	streamWriteBool(streamId, self.isReversed)
	if not connection:getIsServer() and self.animatedObjects ~= nil then
		for _, v63_ in ipairs(self.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v63_))
			v63_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v63_)
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

-- Local values: terrain, i, child, length, lengthXZ, curLen, dx, dz, x, y, z, gate, _x, yTest, _z, slopeAngle, gateNode, actualPanelLength, posX, posY, posZ, dirX, dirY, dirZ, endX, endY, endZ, _, animatedObject
function FenceGate:updateMeshes(force, validatePlacement)
	local v71_ = Utils.getNoNil(force, false)
	local v72_ = Utils.getNoNil(validatePlacement, true)
	self.lastError = nil
	if not (v71_ or self.isDirty) then
		return true
	end
	if self.startPosX == nil or self.endPosX == nil then
		return false
	end
	if not entityExists(self.root) then
		return false
	end
	local v73_ = g_terrainNode or getChild(getRootNode(), "terrain")
	for v74_ = getNumOfChildren(self.root) - 1, 0, -1 do
		local v75_ = getChildAt(self.root, v74_)
		removeFromPhysics(v75_)
		unlink(v75_)
		self.rootHidden = v75_
	end
	if v72_ then
		if MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ) < 0.1 then
			self.lastError = FenceSegment.ERROR_TOO_SHORT
			return false
		end
		if MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ) < 0.1 then
			self.lastError = FenceSegment.ERROR_TOO_SHORT
			return false
		end
	end
	local v76_ = MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
	local v77_ = 0
	local v78_, v79_ = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
	local v80_ = self.metadata.gate
	if v76_ - v77_ >= 0.1 then
		local v81_ = self.startPosX
		local v82_ = self.startPosY
		local v83_ = self.startPosZ
		local v84_ = self.endPosX
		local v85_ = self.endPosY
		local v86_ = self.endPosZ
		if v72_ then
			v81_, v82_, v83_ = self:lerpOnTerrain(v73_, v77_ / v76_)
			v84_, v85_, v86_ = self:lerpOnTerrain(v73_, (v77_ + v80_.length) / v76_)
			local v87_ = (v82_ - v85_) / v80_.length
			local v88_ = math.atan(v87_)
			if math.abs(v88_) > self.metadata.maxSlopeAngle then
				self.lastError = FenceSegment.ERROR_TOO_STEEP
				return false
			end
		end
		local v89_ = self.rootHidden
		removeFromPhysics(v89_)
		link(self.root, v89_)
		self.rootHidden = nil
		local v90_ = v80_.length
		local v91_
		if v80_.alignY then
			v78_, v91_, v79_ = MathUtil.vector3Normalize(v84_ - v81_, v85_ - v82_, v86_ - v83_)
			if v72_ then
				v84_ = v81_ + v78_ * v80_.length
				v85_ = v82_ + v91_ * v80_.length
				v86_ = v83_ + v79_ * v80_.length
				if v73_ ~= nil and v73_ ~= 0 then
					v85_ = getTerrainHeightAtWorldPos(v73_, v84_, 0, v86_)
				end
				v78_, v91_, v79_ = MathUtil.vector3Normalize(v84_ - v81_, v85_ - v82_, v86_ - v83_)
			end
			v90_ = MathUtil.vector2Length(v84_ - v81_, v86_ - v83_)
		else
			v91_ = 0
		end
		v77_ = v77_ + v90_
		if self.isReversed then
			v78_ = -v78_
			v91_ = -v91_
			v79_ = -v79_
		else
			v86_ = v83_
			v85_ = v82_
			v84_ = v81_
		end
		setWorldTranslation(v89_, v84_, v85_, v86_)
		setWorldDirection(v89_, v78_, v91_, v79_, 0, 1, 0)
	end
	local v92_, v93_, v94_ = self:lerpOnTerrain(v73_, v77_ / v76_)
	self.actualEndX = v92_
	self.actualEndY = v93_
	self.actualEndZ = v94_
	if self.notYetFinalized and self.animatedObjects ~= nil then
		for _, v95_ in ipairs(self.animatedObjects) do
			v95_:setAnimTime(0.4)
		end
	end
	self.isDirty = false
	return true
end

-- Local values: x, y, z
function FenceGate:lerpOnTerrain(terrain, alpha)
	if terrain == nil or terrain == 0 then
		local v99_, v100_, v101_ = MathUtil.vector3Lerp(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, alpha)
		return v99_, v100_, v101_
	else
		local v102_, v103_ = MathUtil.vector2Lerp(self.startPosX, self.startPosZ, self.endPosX, self.endPosZ, alpha)
		return v102_, getTerrainHeightAtWorldPos(terrain, v102_, 0, v103_), v103_
	end
end

-- Local values: gate, dx, dz, cx, cy, cz, halfWidth, widthOffset, rx, ry, rz, height, ex, ey, ez
function FenceGate:getOverlapBox()
	local v105_ = self.metadata.gate
	local v106_, v107_ = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
	local v108_ = (self.startPosX + self.actualEndX) / 2
	local v109_ = (self.startPosY + self.actualEndY) / 2
	local v110_ = (self.startPosZ + self.actualEndZ) / 2
	local v111_ = v105_.depth or v105_.length / 2
	local v112_ = (v105_.depthOffset or v111_) / 2
	local v113_ = v108_ - v107_ * v112_ * (self.isReversed and -1 or 1)
	local v114_ = v110_ + v106_ * v112_ * (self.isReversed and -1 or 1)
	local v115_ = self.actualEndX - self.startPosX
	local v116_ = self.actualEndZ - self.startPosZ
	local v117_ = math.atan2(v115_, v116_) + 6.283185307179586
	local v118_ = v105_.height or 2
	local v119_ = v111_ / 2
	local v120_ = math.max(v119_, 0.05)
	local v121_ = self.actualEndY - self.startPosY
	return v113_, v109_, v114_, 0, v117_, 0, v120_, math.abs(v121_) / 2 + v118_, v105_.length / 2
end

-- Local values: hitNodes
function FenceGate:update()
	self:checkOverlap({})
end

-- Local values: _, animatedObject, aiBlockingRegion, x, y, z, rx, ry, rz, ex, ey, ez, stopDistance
function FenceGate:finalize(loadedFromSavegame)
	if not FenceGate:superClass().finalize(self, loadedFromSavegame) then
		return false
	end
	if self.animatedObjects ~= nil then
		for _, v125_ in ipairs(self.animatedObjects) do
			if not loadedFromSavegame then
				v125_:setAnimTime(0)
			end
			if g_server ~= nil and (v125_.aiBlockingRegion ~= nil and (g_currentMission ~= nil and g_currentMission.aiSystem ~= nil)) then
				local v126_ = v125_.aiBlockingRegion or {}
				local v127_, v128_, v129_, v130_, v131_, v132_, v133_, v134_, v135_ = self:getOverlapBox()
				local v136_ = v126_.stopDistance or 2
				v126_.blockingRegionId = g_currentMission.aiSystem:addBlockingRegion(v127_, v128_, v129_, v130_, v131_, v132_, v133_ * 2, v134_ * 2, v135_ * 2, v136_, "blockingPositionCallback", self)
			end
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

-- Local values: _, animatedObject, openedStateAnimTime
function FenceGate:blockingPositionCallback(_, agentId, blockerId)
	for _, v139_ in ipairs(self.animatedObjects) do
		local v140_ = v139_.aiBlockingRegion.openedStateAnimTime
		if v139_.animation.time == 1 - v140_ then
			v139_:setDirection(v140_)
		end
		if v139_.animation.time == v140_ then
			g_currentMission.aiSystem:setBlockingRegionState(blockerId, false)
		end
	end
end

-- Local values: _, animatedObject
function FenceGate:setOwnerFarmId(ownerFarmId, noEventSend)
	FenceGate:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
	if self.animatedObjects ~= nil then
		for _, v144_ in ipairs(self.animatedObjects) do
			v144_:setOwnerFarmId(ownerFarmId, true)
		end
	end
end

function FenceGate:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
	if self.farmlandId == farmlandId then
		self:updateOwnerFarmId()
	end
end

-- Local values: farmId, _, animatedObject
function FenceGate:updateOwnerFarmId()
	local v148_ = g_farmlandManager:getFarmlandOwner(self.farmlandId)
	if self.animatedObjects ~= nil then
		for _, v149_ in ipairs(self.animatedObjects) do
			v149_:setOwnerFarmId(v148_, true)
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

-- Local values: sx, sy, sz, isFirst, isLast
function FenceGate:getSegmentPartStartEnd(node)
	local v154_ = self:getSegmentPartFromNode(node)
	if v154_ == nil then
		return nil
	end
	local v155_, v156_, v157_ = getWorldTranslation(v154_)
	local v158_ = MathUtil.vector3Length(v155_ - self.startPosX, v156_ - self.startPosY, v157_ - self.startPosZ) < 0.01
	local v159_ = MathUtil.vector3Length(v155_ - self.endPosX, v156_ - self.endPosY, v157_ - self.endPosZ) < 0.01
	return self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, v158_, v159_
end
