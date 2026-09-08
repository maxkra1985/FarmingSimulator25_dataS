-- Local values: FenceSegment_mt
source("dataS/scripts/std.lua")
source("dataS/scripts/utils/MathUtil.lua")
source("dataS/scripts/utils/Utils.lua")
source("dataS/scripts/misc/Logging.lua")
source("dataS/scripts/fence/FenceNewSegmentEvent.lua")
source("dataS/scripts/fence/FenceSegmentEvent.lua")
source("dataS/scripts/fence/FenceDeleteSegmentEvent.lua")
source("dataS/scripts/fence/FenceRequestDeleteSegmentEvent.lua")
FenceSegment = {}
FenceSegment.DEFAULT_PRICE_PER_M = 100
FenceSegment.USER_ATTRIBUTE_VARIATION = "variationName"
FenceSegment.ERROR_TOO_SHORT = 1
FenceSegment.ERROR_TOO_STEEP = 2
local FenceSegment_mt = Class(FenceSegment)

function FenceSegment.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	schema:register(XMLValueType.ANGLE, basePath .. "#maxVerticalAngle", "")
	schema:register(XMLValueType.ANGLE, basePath .. "#maxSlopeAngle", "")
	schema:register(XMLValueType.FLOAT, basePath .. "#snapDistance", "snap distance")
	schema:register(XMLValueType.FLOAT, basePath .. "#boundingCheckWidth", "Optional bounding check width")
	schema:register(XMLValueType.FLOAT, basePath .. ".settings.parallelSnapping#snapDistance", "Parallel snap distance")
	schema:register(XMLValueType.FLOAT, basePath .. ".settings.parallelSnapping#snapCheckDistance", "Parallel snap check distance")
	schema:register(XMLValueType.BOOL, basePath .. ".settings.parallelSnapping#canToggle", "If parallel snapping can be toggled")
	schema:register(XMLValueType.BOOL, basePath .. ".settings.extending#allowExtendingOnly", "Segments can be attached to a middle pole")
	schema:register(XMLValueType.ANGLE, basePath .. ".settings.extending#maxCornerAngle", "Max angle of extending segments")
	schema:register(XMLValueType.FLOAT, basePath .. "#price", "price per segment")
	schema:register(XMLValueType.STRING, basePath .. ".poles.pole(?)#variationName", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".poles.pole(?)#node", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".poles.pole(?)#radius", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".poles.pole(?)#height", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".panels#maxScale", "", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".panels#useRandomization", "If true and multiple panels are defined for the same length they will be used randomly, otherwise only the first panel is used", false)
	schema:register(XMLValueType.STRING, basePath .. ".panels.panel(?)#variationName", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".panels.panel(?)#node", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".panels.panel(?)#collisionNode", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".panels.panel(?)#length", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".panels.panel(?)#width", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".panels.panel(?)#height", "")
	schema:register(XMLValueType.BOOL, basePath .. ".panels.panel(?)#alignY", "")
end

function FenceSegment.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#start", "Segment start position")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#end", "Segment end position")
end

-- Local values: metadata, extendingKey, parallelSnappingKey, parallelSnapDistance, poles, variationNameToPole, panels, variationNameToPanel, _, poleKey, variationName, node, radius, height, nodeClone, templateId, pole, _, panelKey, variationName, node, collisionNode, length, width, height, alignY, nodeClone, templateId, collisionIndexPath, colPosX, colPosY, colPosZ, panel, maxScale, panelsUseRandomization, panelsByLength, currentLength, currentGroup, index, panelData
function FenceSegment.loadMetadataFromXML(xmlFile, key, id, fence)
	local v10_ = {
		["class"] = FenceSegment,
		["id"] = id,
		["maxWidth"] = 0.1,
		["maxHeight"] = 0.1,
		["maxVerticalAngle"] = xmlFile:getFloat(key .. "#maxVerticalAngle", 45),
		["maxSlopeAngle"] = xmlFile:getAngle(key .. "#maxSlopeAngle", 45),
		["snapAngle"] = xmlFile:getFloat(key .. "#snapAngle", nil),
		["snapDistance"] = xmlFile:getFloat(key .. "#snapDistance", nil),
		["boundingCheckWidth"] = xmlFile:getFloat(key .. "#boundingCheckWidth", nil),
		["allowExtendingOnly"] = xmlFile:getBool(key .. "#allowExtendingOnly", false),
		["price"] = xmlFile:getFloat(key .. "#price")
	}
	local v11_ = key .. ".settings.extending"
	if xmlFile:hasProperty(v11_) then
		v10_.extending = {}
		v10_.extending.allowExtendingOnly = xmlFile:getBool(v11_ .. "#allowExtendingOnly", nil)
		v10_.extending.maxCornerAngle = xmlFile:getAngle(v11_ .. "#maxCornerAngle", nil)
	end
	local v12_ = key .. ".settings.parallelSnapping"
	local v13_ = xmlFile:getFloat(v12_ .. "#snapDistance", nil)
	if v13_ ~= nil then
		v10_.parallelSnapping = {}
		v10_.parallelSnapping.snapDistance = v13_
		v10_.parallelSnapping.checkDistance = xmlFile:getFloat(v12_ .. "#snapCheckDistance", v13_)
		v10_.parallelSnapping.canToggle = xmlFile:getBool(v12_ .. "#canToggle", nil)
	end
	local v14_ = {}
	local v15_ = {}
	local v16_ = {}
	local v17_ = {}
	for _, v18_ in xmlFile:iterator(key .. ".poles.pole") do
		local v19_ = xmlFile:getString(v18_ .. "#variationName")
		local v20_ = xmlFile:getNode(v18_ .. "#node", nil, fence.components, fence.i3dMapping)
		if v20_ ~= nil then
			local v21_ = xmlFile:getFloat(v18_ .. "#radius", 0)
			local v22_ = xmlFile:getFloat(v18_ .. "#height", 2)
			local v23_ = clone(v20_, false, false, false)
			local v24_ = fence.nodeCache:addTemplate(v23_)
			local v25_ = v10_.maxWidth
			local v26_ = v21_ * 2
			v10_.maxWidth = math.max(v25_, v26_)
			local v27_ = v10_.maxHeight
			v10_.maxHeight = math.max(v27_, v22_)
			v10_.poleNames = v10_.poleNames or {}
			v10_.poleNames[getName(v20_)] = true
			local v28_ = {
				["node"] = v20_,
				["radius"] = v21_,
				["height"] = v22_,
				["template"] = v24_,
				["variationName"] = v19_
			}
			if v19_ == nil then
				::l11::
				table.insert(v14_, v28_)
			else
				if v15_[v19_] == nil then
					v15_[v19_] = v28_
					goto l11
				end
				Logging.xmlWarning(xmlFile, "Variation name already defined for \'%s\'", v18_)
			end
		end
	end
	if #v14_ > 0 then
		v10_.variationNameToPole = v15_
		v10_.poles = v14_
	end
	for _, v29_ in xmlFile:iterator(key .. ".panels.panel") do
		local v30_ = xmlFile:getString(v29_ .. "#variationName")
		local v31_ = xmlFile:getNode(v29_ .. "#node", nil, fence.components, fence.i3dMapping)
		local v32_ = xmlFile:getNode(v29_ .. "#collisionNode", nil, fence.components, fence.i3dMapping)
		local v33_ = xmlFile:getFloat(v29_ .. "#length")
		local v34_ = xmlFile:getFloat(v29_ .. "#width", 0)
		local v35_ = xmlFile:getFloat(v29_ .. "#height", 2)
		local v36_ = xmlFile:getBool(v29_ .. "#alignY")
		local v37_ = clone(v31_, false, false, false)
		local v38_ = fence.nodeCache:addTemplate(v37_)
		local v39_ = v10_.maxWidth
		v10_.maxWidth = math.max(v39_, v34_)
		local v40_ = v10_.maxHeight
		v10_.maxHeight = math.max(v40_, v35_)
		local v41_, v42_, v43_, v44_
		if v32_ == nil then
			v41_ = nil
			v42_ = nil
			v43_ = nil
			v44_ = nil
		else
			v41_ = I3DUtil.getNodePathIndices(v32_, v31_, false)
			v42_, v43_, v44_ = getTranslation(v32_)
		end
		local v45_ = {
			["node"] = v31_,
			["collisionIndexPath"] = v41_,
			["length"] = v33_,
			["height"] = v35_,
			["alignY"] = v36_,
			["template"] = v38_,
			["colPosX"] = v42_,
			["colPosY"] = v43_,
			["colPosZ"] = v44_,
			["variationName"] = v30_
		}
		if v30_ == nil then
			::l22::
			table.insert(v17_, v45_)
		else
			if v16_[v30_] == nil then
				v16_[v30_] = v45_
				goto l22
			end
			Logging.xmlWarning(xmlFile, "Variation name already defined for \'%s\'", v29_)
		end
	end
	if #v17_ > 0 then
		table.sort(v17_, function(p46_, p47_)
			if p46_.length == p47_.length then
				return p46_.template < p47_.template
			else
				return p46_.length > p47_.length
			end
		end)
		v10_.panels = v17_
		local v48_ = xmlFile:getFloat(key .. ".panels#maxScale")
		if v48_ ~= nil then
			if v48_ < 1 then
				Logging.xmlWarning(xmlFile, "Panels max scale %.3f at %q needs to be >= 1", v48_, key .. ".panels#maxScale")
			else
				v10_.panelsMaxScale = v48_
			end
		end
		local v49_ = xmlFile:getBool(key .. ".panels#useRandomization")
		if v49_ then
			v10_.panelsUseRandomization = v49_
		end
		local v50_ = math.huge
		local v51_ = nil
		local v52_ = {}
		for _, v53_ in ipairs(v10_.panels) do
			if v53_.length < v50_ then
				if v51_ == nil then
					v51_ = {}
				else
					table.insert(v52_, v51_)
					v51_ = {}
				end
			end
			table.insert(v51_, v53_)
			v50_ = v53_.length
		end
		table.insert(v52_, v51_)
		v10_.panelsGroupedByLength = v52_
		v10_.variationNameToPanel = v16_
	end
	return v10_
end

-- Upvalues: FenceSegment_mt
-- Local values: self
function FenceSegment.new(id, metadata, fence, customMt)
	-- upvalues: (copy) FenceSegment_mt
	local v58_ = customMt or FenceSegment_mt
	local v59_ = setmetatable({}, v58_)
	v59_.id = id
	if g_isDevelopmentVersion and g_server == nil then
		v59_.id = math.random(1, 99999999)
	end
	v59_.metadata = metadata
	v59_.fence = fence
	v59_.startPosX = nil
	v59_.startPosY = nil
	v59_.startPosZ = nil
	v59_.endPosX = nil
	v59_.endPosY = nil
	v59_.endPosZ = nil
	v59_.hasStartPole = nil
	v59_.hasEndPole = nil
	v59_.root = createTransformGroup("fenceSegmentRoot_" .. v59_.metadata.id .. "_" .. tostring(v59_):sub(10))
	v59_.notYetFinalized = true
	return v59_
end

-- Local values: terrainDeformationSyncer, cellId, _, cellX, cellZ, startNeighbor, endNeighbor
function FenceSegment:delete()
	if self.cellIdUpdateListeners ~= nil then
		local v61_ = g_currentMission.terrainDeformationSyncer
		if v61_ ~= nil then
			for v62_, _ in pairs(self.cellIdUpdateListeners) do
				local v63_, v64_ = v61_:getCellIndicesById(v62_)
				v61_:removeCellUpdateListener(self, v63_, v64_)
			end
		end
		self.cellIdUpdateListeners = nil
	end
	if self.pendingUpdateTimer ~= nil then
		self.pendingUpdateTimer:delete()
		self.pendingUpdateTimer = nil
	end
	local v65_ = nil
	local v66_ = nil
	if self.fence ~= nil then
		if self.startPosX ~= nil then
			v65_ = self.fence:getNeighborSegmentNeedingPoleUpdate(self.startPosX, self.startPosY, self.startPosZ, 0.1, self.id)
		end
		if self.endPosX ~= nil then
			v66_ = self.fence:getNeighborSegmentNeedingPoleUpdate(self.endPosX, self.endPosY, self.endPosZ, 0.1, self.id)
		end
	end
	if self.fence ~= nil then
		self.fence:removeSegment(self)
		self.fence = nil
	end
	if v65_ ~= nil then
		v65_:removeNodeObjectMapping()
		v65_:removeFromPhysics()
		v65_:updateMeshes(true, false)
		v65_:addToPhysics()
		v65_:addNodeObjectMapping()
	end
	if v66_ ~= nil and v66_ ~= v65_ then
		v66_:removeNodeObjectMapping()
		v66_:removeFromPhysics()
		v66_:updateMeshes(true, false)
		v66_:addToPhysics()
		v66_:addNodeObjectMapping()
	end
	if self.root ~= nil then
		if not self.notYetFinalized then
			self:setCollisionAreaDirty()
		end
		if entityExists(self.root) then
			delete(self.root)
		end
		self.root = nil
	end
end

-- Local values: sx, sy, sz, ex, ey, ez
function FenceSegment:loadFromXMLFile(xmlFile, key)
	local v70_, v71_, v72_ = xmlFile:getTranslation(key .. "#start")
	local v73_, v74_, v75_ = xmlFile:getTranslation(key .. "#end")
	if MathUtil.isNan(v70_) or (MathUtil.isNan(v72_) or (MathUtil.isNan(v73_) or MathUtil.isNan(v75_))) then
		return false
	end
	self.startPosX = v70_
	self.startPosY = v71_
	self.startPosZ = v72_
	self.endPosX = v73_
	self.endPosY = v74_
	self.endPosZ = v75_
	self:updateMeshes(true, false)
	return true
end

function FenceSegment:saveToXMLFile(xmlFile, key)
	if self.startPosX == nil or self.endPosX == nil then
		Logging.devInfo("FenceSegment:saveToXMLFile incomplete fence %s %s %s - %s %s %s", self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
		return false
	end
	xmlFile:setTranslation(key .. "#start", self.startPosX, self.startPosY, self.startPosZ)
	xmlFile:setTranslation(key .. "#end", self.endPosX, self.endPosY, self.endPosZ)
	return true
end

-- Local values: paramsXZ, paramsY
function FenceSegment:readStream(streamId, connection, lastSegment)
	local v83_ = g_currentMission.vehicleXZPosCompressionParams
	local v84_ = g_currentMission.vehicleYPosCompressionParams
	if connection:getIsServer() then
		self.id = streamReadUInt16(streamId)
	end
	if streamReadBool(streamId) then
		self.startPosX = NetworkUtil.readCompressedWorldPosition(streamId, v83_)
		self.startPosY = NetworkUtil.readCompressedWorldPosition(streamId, v84_)
		self.startPosZ = NetworkUtil.readCompressedWorldPosition(streamId, v83_)
	else
		self.startPosX = lastSegment.endPosX
		self.startPosY = lastSegment.endPosY
		self.startPosZ = lastSegment.endPosZ
	end
	self.endPosX = NetworkUtil.readCompressedWorldPosition(streamId, v83_)
	self.endPosY = NetworkUtil.readCompressedWorldPosition(streamId, v84_)
	self.endPosZ = NetworkUtil.readCompressedWorldPosition(streamId, v83_)
	if self.metadata.poles and #self.metadata.poles > 0 then
		self.hasStartPole = streamReadBool(streamId)
		self.hasEndPole = streamReadBool(streamId)
	end
	self:registerTerrainHeightChangeCallbacks()
end

-- Local values: paramsXZ, paramsY, sendStartPos
function FenceSegment:writeStream(streamId, connection, lastSegment)
	local v89_ = g_currentMission.vehicleXZPosCompressionParams
	local v90_ = g_currentMission.vehicleYPosCompressionParams
	if not connection:getIsServer() then
		streamWriteUInt16(streamId, self.id)
	end
	local v91_ = lastSegment == nil or (lastSegment.endPosX ~= self.startPosX or (lastSegment.endPosY ~= self.startPosY or lastSegment.endPosZ ~= self.startPosZ))
	if streamWriteBool(streamId, v91_) then
		NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosX, v89_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosY, v90_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosZ, v89_)
	end
	NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosX, v89_)
	NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosY, v90_)
	NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosZ, v89_)
	if self.metadata.poles and #self.metadata.poles > 0 then
		streamWriteBool(streamId, Utils.getNoNil(self.hasStartPole, false))
		streamWriteBool(streamId, Utils.getNoNil(self.hasEndPole, false))
	end
end

-- Local values: dirX, dirZ, length, terrainDeformationSyncer, offset, stepSize, x, z, cellX, cellZ, cellId
function FenceSegment:registerTerrainHeightChangeCallbacks()
	local v93_ = self.endPosX - self.startPosX
	local v94_ = self.endPosZ - self.startPosZ
	if v93_ == 0 and v94_ == 0 then
		return
	end
	local v95_ = MathUtil.vector2Length(v93_, v94_)
	local v96_, v97_ = MathUtil.vector2Normalize(v93_, v94_)
	local v98_ = g_currentMission.terrainDeformationSyncer
	local v99_ = 0
	while true do
		local v100_, v101_ = v98_:getCellIndicesAtWorldPosition(self.startPosX + v96_ * v99_, self.startPosZ + v97_ * v99_)
		if v100_ ~= nil then
			local v102_ = v98_:getCellId(v100_, v101_)
			if self.cellIdUpdateListeners == nil then
				self.cellIdUpdateListeners = {}
			end
			if self.cellIdUpdateListeners[v102_] == nil then
				self.cellIdUpdateListeners[v102_] = true
				v98_:addCellUpdateListener(self, v100_, v101_)
			end
		end
		if v95_ <= v99_ then
			return
		end
		local v103_ = v99_ + 0.5
		v99_ = math.min(v103_, v95_)
	end
end

function FenceSegment:onTerrainDeformationSyncerUpdate(cellX, cellZ, cellId)
	if self.pendingUpdateTimer == nil then
		self.pendingUpdateTimer = Timer.new(5000)
		self.pendingUpdateTimer:setFinishCallback(function()
			-- upvalues: (copy) self
			self:removeNodeObjectMapping()
			removeFromPhysics(self.root)
			self:updateMeshes(true, false)
			addToPhysics(self.root)
			self:addNodeObjectMapping()
			self:setCollisionAreaDirty()
			self.pendingUpdateTimer = nil
		end)
		self.pendingUpdateTimer:start()
	end
end

function FenceSegment:addNodeObjectMapping()
	I3DUtil.iterateRecursively(self.root, function(p106_)
		-- upvalues: (copy) self
		if getHasClassId(p106_, ClassIds.SHAPE) and getRigidBodyType(p106_) ~= RigidBodyType.NONE then
			g_currentMission:addNodeObject(p106_, self.fence)
		end
	end)
end

function FenceSegment:removeNodeObjectMapping()
	if self.root ~= nil then
		I3DUtil.iterateRecursively(self.root, function(p108_)
			if getHasClassId(p108_, ClassIds.SHAPE) and getRigidBodyType(p108_) ~= RigidBodyType.NONE then
				g_currentMission:removeNodeObject(p108_)
			end
		end)
	end
end

function FenceSegment:setStartPos(x, y, z)
	if x ~= self.startPosX or (y ~= self.startPosY or z ~= self.startPosZ) then
		self.startPosX = x
		self.startPosY = y
		self.startPosZ = z
		self.isDirty = true
	end
end

-- Local values: x, y, z
function FenceSegment:setStartNode(node)
	local v115_, v116_, v117_ = getWorldTranslation(node)
	self:setStartPos(v115_, v116_, v117_)
end

function FenceSegment:setEndPos(x, y, z)
	if x ~= self.endPosX or (y ~= self.endPosY or z ~= self.endPosZ) then
		self.endPosX = x
		self.endPosY = y
		self.endPosZ = z
		self.isDirty = true
	end
end

-- Local values: x, y, z
function FenceSegment:setEndNode(node)
	local v124_, v125_, v126_ = getWorldTranslation(node)
	self:setEndPos(v124_, v125_, v126_)
end

function FenceSegment:getStartPos()
	return self.startPosX, self.startPosY, self.startPosZ
end

function FenceSegment:getLength()
	return (self.startPosX == nil or self.endPosX == nil) and 0 or MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ)
end

function FenceSegment:getActualLength()
	return (self.startPosX == nil or self.actualEndX == nil) and 0 or MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
end

function FenceSegment:getPrice()
	return self:getActualLength() * (self.metadata.price or FenceSegment.DEFAULT_PRICE_PER_M)
end

function FenceSegment:getEndPos()
	return self.endPosX, self.endPosY, self.endPosZ
end

function FenceSegment:getActualEndPos()
	return self.actualEndX, self.actualEndY, self.actualEndZ
end

-- Local values: panels
function FenceSegment:getMinimumPanelLength()
	local v134_ = self.metadata.panels
	if v134_ == nil or #v134_ == 0 then
		return nil
	else
		return v134_[#v134_].length
	end
end

function FenceSegment:getLastError()
	return self.lastError
end

-- Local values: terrain, i, child, length, segmentLengthXZ, curLen, dx, dz, x, y, z, lastY, previousPanel, previousPanelLength, previousPanelData, maxScaleDiff, minScale, maxScale, shortestPanelLength, isFirstPole, _, panelGroup, panelGroupLength, randomPanelIndex, panelData, poleTemplate, needsPole, segment, isStartPole, hasVisualStartPole, hasAlreadyStartPole, hasVisualEndPole, hasAlreadyEndPole, remainingLength, maxPanelLength, panelLength, _, yTest, _, slopeAngle, panel, scale, actualPanelLength, endX, endY, endZ, dirX, dirY, dirZ, alignedLength, needsPole, segment, isStartPole, hasStartPole
function FenceSegment:updateMeshes(force, validatePlacement)
	local v139_ = Utils.getNoNil(force, false)
	local v140_ = Utils.getNoNil(validatePlacement, true)
	if g_server ~= nil then
		self.hasStartPole = nil
		self.hasEndPole = nil
	end
	self.lastError = nil
	if not (v139_ or self.isDirty) then
		return true
	end
	if self.startPosX == nil or self.endPosX == nil then
		return false
	end
	if not entityExists(self.root) then
		return false
	end
	local v141_ = g_terrainNode or getChild(getRootNode(), "terrain")
	for v142_ = getNumOfChildren(self.root) - 1, 0, -1 do
		local v143_ = getChildAt(self.root, v142_)
		removeFromPhysics(v143_)
		unlink(v143_)
		self.fence.nodeCache:returnNodeToCache(v143_)
	end
	if MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ) < 0.1 then
		if self.metadata.poles and #self.metadata.poles > 0 then
			self:placePole(self.startPosX, self.startPosY, self.startPosZ, 1, 0)
		end
		self.lastError = FenceSegment.ERROR_TOO_SHORT
		return false
	end
	if MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ) < 0.1 then
		self.lastError = FenceSegment.ERROR_TOO_SHORT
		return false
	end
	local v144_ = MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
	local v145_, v146_ = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
	local v147_ = self.startPosY
	local v148_ = (self.metadata.panelsMaxScale or 1) - 1
	local v149_ = 1 - v148_
	local v150_ = 1 + v148_
	local v151_ = self.metadata.panels[#self.metadata.panels].length
	local v152_ = true
	local v153_ = nil
	local v154_ = 0
	local v155_ = 0
	local v156_ = nil
	for _, v157_ in ipairs(self.metadata.panelsGroupedByLength) do
		local v158_ = v157_[1].length
		while v144_ - v154_ >= v158_ * v149_ - 0.01 do
			local v159_ = v157_[not self.metadata.panelsUseRandomization and 1 or Fence.getDeterministicRandomValueForPosition(self.startPosX + v154_ / 5, self.startPosY + v154_, self.startPosZ + v154_ / 3, #v157_)]
			if self.metadata.poles and #self.metadata.poles > 0 then
				local v160_, v161_, v162_ = self:lerpOnTerrain(v141_, v154_ / v144_)
				local v163_ = self.metadata.poles[Fence.getDeterministicRandomValueForPosition(v160_, v161_, v162_, #self.metadata.poles)]
				local v164_ = true
				if v152_ then
					if g_server == nil then
						v164_ = self.hasStartPole
					else
						local v165_ = self.fence
						local v166_ = v163_.radius
						local v167_, v168_ = v165_:getNearPoleSegment(v160_, v161_, v162_, math.max(v166_, 0.05), self.id)
						if v167_ ~= nil then
							if v168_ then
								local v169_
								if v167_.getHasVisualStartPole == nil then
									v169_ = false
								else
									v169_ = v167_:getHasVisualStartPole()
								end
								if v169_ and v167_.hasStartPole then
									v164_ = false
								end
							else
								local v170_
								if v167_.getHasVisualEndPole == nil then
									v170_ = false
								else
									v170_ = v167_:getHasVisualEndPole()
								end
								if v170_ and v167_.hasEndPole then
									v164_ = false
								end
							end
						end
						self.hasStartPole = v164_
					end
				end
				if v164_ then
					self:placePole(v160_, v161_, v162_, v145_, v146_)
				end
				v154_ = v154_ + v163_.radius
				v152_ = false
			end
			local v171_ = v144_ - v154_
			local v172_ = v159_.length
			if v171_ - v159_.length < v151_ * v149_ then
				v172_ = v159_.length * v150_
			end
			local v173_ = v144_ - v154_
			local v174_ = v159_.length * v149_
			local v175_ = math.clamp(v173_, v174_, v172_)
			local v176_, v177_, v178_ = self:lerpOnTerrain(v141_, v154_ / v144_)
			if v153_ ~= nil then
				FenceSegment.adjustPanelOffset(v156_, v153_, v155_, v177_ - v147_)
				self:updatePanel(v156_, v153_, v155_, v177_ - v147_)
			end
			if v140_ then
				local _, v179_, _ = self:lerpOnTerrain(v141_, (v154_ + v175_) / v144_)
				local v180_ = (v177_ - v179_) / v175_
				local v181_ = math.atan(v180_)
				if math.abs(v181_) > self.metadata.maxSlopeAngle then
					self.lastError = FenceSegment.ERROR_TOO_STEEP
					return false
				end
			end
			v153_ = self.fence.nodeCache:getNodeInstance(v159_.template)
			removeFromPhysics(v153_)
			link(self.root, v153_)
			setWorldTranslation(v153_, v176_, v177_, v178_)
			setWorldDirection(v153_, v145_, 0, v146_, 0, 1, 0)
			if v159_.variationName == nil then
				removeUserAttribute(v153_, FenceSegment.USER_ATTRIBUTE_VARIATION)
			else
				setUserAttribute(v153_, FenceSegment.USER_ATTRIBUTE_VARIATION, UserAttributeType.STRING, v159_.variationName)
			end
			local v182_ = v175_ / v159_.length
			if v159_.alignY then
				local v183_, v184_, v185_ = self:lerpOnTerrain(v141_, (v154_ + v175_) / v144_)
				local v186_, v187_, v188_ = MathUtil.vector3Normalize(v183_ - v176_, v184_ - v177_, v185_ - v178_)
				local v189_ = v176_ + v186_ * v175_
				local v190_ = v177_ + v187_ * v175_
				local v191_ = v178_ + v188_ * v175_
				if v141_ ~= nil and v141_ ~= 0 then
					v190_ = getTerrainHeightAtWorldPos(v141_, v189_, 0, v191_)
				end
				local v192_, v193_, v194_ = MathUtil.vector3Normalize(v189_ - v176_, v190_ - v177_, v191_ - v178_)
				setWorldDirection(v153_, v192_, v193_, v194_, 0, 1, 0)
				v155_ = MathUtil.vector2Length(v189_ - v176_, v191_ - v178_)
				v182_ = MathUtil.vector3Length(v189_ - v176_, v190_ - v177_, v191_ - v178_) / v159_.length
			else
				v155_ = v175_
			end
			if v182_ ~= 1 then
				setScale(v153_, 1, 1, v182_)
			end
			v154_ = v154_ + v155_
			v156_ = v159_
			v147_ = v177_
		end
	end
	local v195_, v196_, v197_ = self:lerpOnTerrain(v141_, v154_ / v144_)
	if self.metadata.poles and #self.metadata.poles > 0 then
		local v198_ = true
		if g_server == nil then
			v198_ = self.hasEndPole
		else
			local v199_, v200_ = self.fence:getNearPoleSegment(v195_, v196_, v197_, 0.05, self.id)
			if v199_ ~= nil then
				if v200_ then
					if v199_.getHasVisualStartPole ~= nil and v199_:getHasVisualStartPole() then
						v198_ = false
					end
				elseif v199_.getHasVisualEndPole ~= nil and v199_:getHasVisualEndPole() then
					v198_ = false
				end
			end
			self.hasEndPole = v198_
		end
		if v198_ then
			self:placePole(v195_, v196_, v197_, v145_, v146_)
		end
	end
	if v153_ ~= nil then
		FenceSegment.adjustPanelOffset(v156_, v153_, v155_, v196_ - v147_)
		self:updatePanel(v156_, v153_, v155_, v196_ - v147_)
	end
	self.actualEndX = v195_
	self.actualEndY = v196_
	self.actualEndZ = v197_
	self.isDirty = false
	return true
end

-- Local values: sx, sy, sz, distance, randomIndex, poleTemplate, pole
function FenceSegment:placePole(x, y, z, dx, dz)
	local v207_, v208_, v209_ = self:getStartPos()
	local v210_ = MathUtil.vector2Length(x - v207_, z - v209_)
	local v211_ = Fence.getDeterministicRandomValueForPosition(v207_ + v210_ / 5, v208_ + v210_, v209_ + v210_ / 3, #self.metadata.poles)
	local v212_ = self.metadata.poles[v211_]
	local v213_ = self.fence.nodeCache:getNodeInstance(v212_.template)
	removeFromPhysics(v213_)
	link(self.root, v213_)
	setWorldTranslation(v213_, x, y, z)
	setWorldDirection(v213_, dx, 0, dz, 0, 1, 0)
	if v212_.variationName == nil then
		removeUserAttribute(v213_, FenceSegment.USER_ATTRIBUTE_VARIATION)
	else
		setUserAttribute(v213_, FenceSegment.USER_ATTRIBUTE_VARIATION, UserAttributeType.STRING, v212_.variationName)
	end
end

-- Local values: x, y, z
function FenceSegment:lerpOnTerrain(terrain, alpha)
	if terrain == nil or terrain == 0 then
		local v217_, v218_, v219_ = MathUtil.vector3Lerp(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, alpha)
		return v217_, v218_, v219_
	else
		local v220_, v221_ = MathUtil.vector2Lerp(self.startPosX, self.startPosZ, self.endPosX, self.endPosZ, alpha)
		return v220_, getTerrainHeightAtWorldPos(terrain, v220_, 0, v221_), v221_
	end
end

-- Local values: cx, cy, cz, rx, ry, rz, width, height, ex, ey, ez, boundingCheckWidth
function FenceSegment:getOverlapBox(length)
	local v224_ = length or MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
	local v225_ = (self.startPosX + self.actualEndX) / 2
	local v226_ = (self.startPosY + self.actualEndY) / 2
	local v227_ = (self.startPosZ + self.actualEndZ) / 2
	local v228_ = self.actualEndX - self.startPosX
	local v229_ = self.actualEndZ - self.startPosZ
	local v230_ = math.atan2(v228_, v229_) + 6.283185307179586
	local v231_ = self.metadata.maxWidth
	local v232_ = self.metadata.maxHeight
	local v233_ = v231_ / 2
	local v234_ = self.actualEndY - self.startPosY
	local v235_ = math.abs(v234_) / 2 + v232_
	local v236_ = v224_ / 2
	local v237_ = self.metadata.boundingCheckWidth
	if v237_ ~= nil then
		v233_ = v237_ * 0.5
		v236_ = v224_ * 0.5 + v237_ * 0.5
	end
	return v225_, v226_, v227_, 0, v230_, 0, v233_, v235_, v236_
end

-- Local values: length, cx, cy, cz, rx, ry, rz, ex, ey, ez, mask
function FenceSegment:checkOverlap(hitNodesTable, ignoreChildrenNode)
	if self.actualEndX ~= nil then
		local v241_ = MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
		if v241_ ~= 0 then
			local v242_, v243_, v244_, v245_, v246_, v247_, v248_, v249_, v250_ = self:getOverlapBox(v241_)
			self.numOverlapHits = 0
			self.hitNodesTable = hitNodesTable
			self.ignoreChildrenNode = ignoreChildrenNode
			local v251_ = CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING + CollisionFlag.PLAYER + CollisionFlag.VEHICLE + CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT
			overlapCylinder(self.startPosX, self.startPosY + 0.5, self.startPosZ, 0.15, 3, Axis.Y, "onOverlapCylinderCallback", self, v251_, false, true, true, true)
			overlapCylinder(self.actualEndX, self.actualEndY + 0.5, self.actualEndZ, 0.15, 3, Axis.Y, "onOverlapCylinderCallback", self, v251_, false, true, true, true)
			overlapBox(v242_, v243_, v244_, v245_, v246_, v247_, v248_, v249_, v250_, "onOverlapBoxCallback", self, v251_, true, true, true, true)
			self.hitNodesTable = nil
			self.ignoreNodes = nil
			return hitNodesTable
		end
	end
end

function FenceSegment:onOverlapCylinderCallback(hitNode)
	self.ignoreNodes = self.ignoreNodes or {}
	self.ignoreNodes[hitNode] = not self.ignoreNodes[hitNode]
end

-- Local values: segment
function FenceSegment:onOverlapBoxCallback(hitNode)
	if hitNode == 0 then
		return
	elseif self:getIsNodePartOfSegment(hitNode) then
		return
	elseif self.ignoreChildrenNode == nil or not I3DUtil.getIsLinkedToNode(self.ignoreChildrenNode, hitNode) then
		if self.ignoreNodes == nil or not self.ignoreNodes[hitNode] then
			if self.parallelSnappingSegment == nil or self.fence:getSegmentFromNode(hitNode) ~= self.parallelSnappingSegment then
				if self.hitNodesTable ~= nil then
					self.hitNodesTable[hitNode] = true
				end
				self.numOverlapHits = self.numOverlapHits + 1
			end
		else
			return
		end
	else
		return
	end
end

function FenceSegment:getHasBlockingOverlap(farmId)
	if self.actualEndX == nil then
		return false
	else
		return not g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, self.startPosX, self.startPosZ, self.actualEndX, self.actualEndZ)
	end
end

-- Local values: parent
function FenceSegment:getIsNodePartOfSegment(node)
	local v260_ = getParent(node)
	while v260_ ~= 0 do
		if self.root == v260_ then
			return true
		end
		v260_ = getParent(v260_)
	end
	return false
end

function FenceSegment:getSegmentPartFromNode(node)
	while node ~= 0 do
		if self.root == getParent(node) then
			return node, getChildIndex(node)
		end
		node = getParent(node)
	end
	return nil
end

-- Local values: sx, sy, sz, childIndex, isFirst, ex, ey, ez, parent, nextPart, isLast
function FenceSegment:getSegmentPartStartEnd(node)
	local v265_ = self:getSegmentPartFromNode(node)
	if v265_ == nil then
		return nil
	end
	local v266_, v267_, v268_ = getWorldTranslation(v265_)
	local v269_ = getChildIndex(v265_)
	local v270_ = MathUtil.vector3Length(v266_ - self.startPosX, v267_ - self.startPosY, v268_ - self.startPosZ) < 0.01
	local v271_ = getParent(v265_)
	local v272_ = getNumOfChildren(v271_) > v269_ + 1 and getChildAt(v271_, v269_ + 1) or nil
	local v273_, v274_, v275_
	if v272_ == nil then
		v273_ = self.endPosX
		v274_ = self.endPosY
		v275_ = self.endPosZ
	else
		v273_, v274_, v275_ = getWorldTranslation(v272_)
	end
	return v266_, v267_, v268_, v273_, v274_, v275_, v270_, MathUtil.vector3Length(v273_ - self.endPosX, v274_ - self.endPosY, v275_ - self.endPosZ) < 0.01
end

function FenceSegment:getId()
	return self.metadata.id
end

function FenceSegment:getHasVisualEndPole()
	local v278_
	if self.metadata.poles == nil then
		v278_ = false
	else
		v278_ = #self.metadata.poles > 0
	end
	return v278_
end

function FenceSegment:getHasVisualStartPole()
	local v280_
	if self.metadata.poles == nil then
		v280_ = false
	else
		v280_ = #self.metadata.poles > 0
	end
	return v280_
end

-- Local values: currentChildIndex, endIndex, currentPanelIndex, iterator
function FenceSegment:iteratorPanels()
	local v_u_282_ = 0
	local v_u_283_ = getNumOfChildren(self.root)
	local v_u_284_ = 0
	return function()
		-- upvalues: (ref) v_u_282_, (copy) v_u_283_, (copy) self, (ref) v_u_284_
		if v_u_283_ <= v_u_282_ then
			return nil
		end
		if self.metadata.poles ~= nil then
			while self.metadata.poleNames[getName(getChildAt(self.root, v_u_282_))] ~= nil do
				v_u_282_ = v_u_282_ + 1
				if v_u_283_ <= v_u_282_ then
					return nil
				end
			end
		end
		v_u_282_ = v_u_282_ + 1
		v_u_284_ = v_u_284_ + 1
		return v_u_284_, getChildAt(self.root, v_u_282_ - 1)
	end
end

-- Local values: currentChildIndex, endIndex, currentPoleIndex, iterator
function FenceSegment:iteratorPoles()
	local v_u_286_ = 0
	local v_u_287_ = getNumOfChildren(self.root)
	local v_u_288_ = 0
	return self.metadata.poles == nil and function()
		return nil
	end or function()
		-- upvalues: (ref) v_u_286_, (copy) v_u_287_, (copy) self, (ref) v_u_288_
		if v_u_287_ <= v_u_286_ then
			return nil
		end
		while self.metadata.poleNames[getName(getChildAt(self.root, v_u_286_))] == nil do
			v_u_286_ = v_u_286_ + 1
			if v_u_287_ <= v_u_286_ then
				return nil
			end
		end
		v_u_286_ = v_u_286_ + 1
		v_u_288_ = v_u_288_ + 1
		return v_u_288_, getChildAt(self.root, v_u_286_ - 1)
	end
end

-- Local values: hitNodes
function FenceSegment:update()
	self:checkOverlap({})
end

function FenceSegment:draw()
	if self.startPosX ~= nil and self.endPosX ~= nil then
	end
end

function FenceSegment:finalize(loadedFromSavegame)
	if self.actualEndX == nil then
		return false
	end
	self.startPosX = self.actualStartX or self.startPosX
	self.startPosY = self.actualStartY or self.startPosY
	self.startPosZ = self.actualStartZ or self.startPosZ
	self.endPosX = self.actualEndX or self.endPosX
	self.endPosY = self.actualEndY or self.endPosY
	self.endPosZ = self.actualEndZ or self.endPosZ
	self:addToPhysics()
	self.fence:addSegment(self)
	self.notYetFinalized = nil
	return true
end

function FenceSegment:addToPhysics()
	addToPhysics(self.root)
	self:setCollisionAreaDirty()
end

function FenceSegment:removeFromPhysics()
	removeFromPhysics(self.root)
	self:setCollisionAreaDirty()
end

-- Local values: minX, maxX, minZ, maxZ
function FenceSegment:setCollisionAreaDirty()
	if self.startPosX ~= nil and self.endPosX ~= nil then
		local v295_ = self.startPosX
		local v296_ = self.endPosX
		local v297_ = math.min(v295_, v296_)
		local v298_ = self.startPosX
		local v299_ = self.endPosX
		local v300_ = math.max(v298_, v299_)
		local v301_ = self.startPosZ
		local v302_ = self.endPosZ
		local v303_ = math.min(v301_, v302_)
		local v304_ = self.startPosZ
		local v305_ = self.endPosZ
		local v306_ = math.max(v304_, v305_)
		if g_densityMapHeightManager ~= nil then
			g_densityMapHeightManager:setCollisionMapAreaDirty(v297_, v303_, v300_, v306_, true)
		end
		if g_currentMission ~= nil and g_currentMission.aiSystem ~= nil then
			g_currentMission.aiSystem:setAreaDirty(v297_, v300_, v303_, v306_)
		end
	end
end

function FenceSegment:setOwnerFarmId(ownerFarmId, noEventSend) end

-- Local values: farmId
function FenceSegment:getOwnerFarmId()
	return g_farmlandManager:getOwnerIdAtWorldPosition(self.startPosX, self.startPosZ)
end

-- Local values: startFarmId, endFarmId
function FenceSegment:getCanBeModifiedByFarmId(farmId)
	return g_farmlandManager:getOwnerIdAtWorldPosition(self.startPosX, self.startPosZ) == farmId and true or g_farmlandManager:getOwnerIdAtWorldPosition(self.endPosX, self.endPosZ) == farmId
end

function FenceSegment:updatePanel(panelData, panelNode, panelLength, deltaY) end

function FenceSegment:setParallelSnappingSegment(segment)
	self.parallelSnappingSegment = segment
end

-- Local values: collisionIndexPath, collisionNode, panelLengthCorrected, scale, offsetY, length, xDir, yDir, zDir, offset, colX, colY, colZ
function FenceSegment.adjustPanelOffset(panelData, panelNode, panelLength, deltaY)
	if not panelData.alignY then
		setShaderParameterRecursive(panelNode, "yOffset", deltaY, nil, nil, nil, false)
	end
	local v316_ = panelData.collisionIndexPath
	if v316_ ~= nil then
		local v317_ = I3DUtil.indexToObject(panelNode, v316_)
		if v317_ ~= nil then
			local v318_
			if panelData.alignY then
				v318_ = panelLength
				deltaY = 0
			else
				local v319_ = deltaY * deltaY + panelLength * panelLength
				v318_ = math.sqrt(v319_)
			end
			local v320_ = v318_ / panelData.length
			local v321_ = deltaY * v320_
			local v322_ = v318_ * v320_
			local v323_, v324_, v325_ = MathUtil.vector3Normalize(0, v321_, v322_)
			local v326_ = (v318_ - panelLength) * 0.5
			local v327_ = panelData.colPosX + v323_ * v326_
			local v328_ = panelData.colPosY + v324_ * v326_
			local v329_ = panelData.colPosZ + v325_ * v326_
			setDirection(v317_, v323_, v324_, v325_, 0, 1, 0)
			setTranslation(v317_, v327_, v328_, v329_)
		end
	end
end
