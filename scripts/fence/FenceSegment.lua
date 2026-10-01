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
function FenceSegment.loadMetadataFromXML(xmlFile, key, id, fence)
	local metadata = {}
	metadata.class = FenceSegment
	metadata.id = id
	metadata.maxWidth = 0.1
	metadata.maxHeight = 0.1
	metadata.maxVerticalAngle = xmlFile:getFloat(key .. "#maxVerticalAngle", 45)
	metadata.maxSlopeAngle = xmlFile:getAngle(key .. "#maxSlopeAngle", 45)
	metadata.snapAngle = xmlFile:getFloat(key .. "#snapAngle", nil)
	metadata.snapDistance = xmlFile:getFloat(key .. "#snapDistance", nil)
	metadata.boundingCheckWidth = xmlFile:getFloat(key .. "#boundingCheckWidth", nil)
	metadata.allowExtendingOnly = xmlFile:getBool(key .. "#allowExtendingOnly", false)
	metadata.price = xmlFile:getFloat(key .. "#price")
	local extendingKey = key .. ".settings.extending"
	if xmlFile:hasProperty(extendingKey) then
		metadata.extending = {}
		metadata.extending.allowExtendingOnly = xmlFile:getBool(extendingKey .. "#allowExtendingOnly", nil)
		metadata.extending.maxCornerAngle = xmlFile:getAngle(extendingKey .. "#maxCornerAngle", nil)
	end
	local parallelSnappingKey = key .. ".settings.parallelSnapping"
	local parallelSnapDistance = xmlFile:getFloat(parallelSnappingKey .. "#snapDistance", nil)
	if parallelSnapDistance ~= nil then
		metadata.parallelSnapping = {}
		metadata.parallelSnapping.snapDistance = parallelSnapDistance
		metadata.parallelSnapping.checkDistance = xmlFile:getFloat(parallelSnappingKey .. "#snapCheckDistance", parallelSnapDistance)
		metadata.parallelSnapping.canToggle = xmlFile:getBool(parallelSnappingKey .. "#canToggle", nil)
	end
	local poles = {}
	local variationNameToPole = {}
	local panels = {}
	local variationNameToPanel = {}
	for _, poleKey in xmlFile:iterator(key .. ".poles.pole") do
		local variationName = xmlFile:getString(poleKey .. "#variationName")
		local node = xmlFile:getNode(poleKey .. "#node", nil, fence.components, fence.i3dMapping)
		if node == nil then
			continue
		end
		local radius = xmlFile:getFloat(poleKey .. "#radius", 0)
		local height = xmlFile:getFloat(poleKey .. "#height", 2)
		local nodeClone = clone(node, false, false, false)
		local templateId = fence.nodeCache:addTemplate(nodeClone)
		metadata.maxWidth = math.max(metadata.maxWidth, radius * 2)
		metadata.maxHeight = math.max(metadata.maxHeight, height)
		metadata.poleNames = metadata.poleNames or {}
		metadata.poleNames[getName(node)] = true
		local pole = { node = node, radius = radius, height = height, template = templateId, variationName = variationName }
		if variationName ~= nil then
			if variationNameToPole[variationName] ~= nil then
				Logging.xmlWarning(xmlFile, "Variation name already defined for '%s'", poleKey)
			else
				variationNameToPole[variationName] = pole
				table.insert(poles, pole)
			end
		end
	end
	if 0 < #poles then
		metadata.variationNameToPole = variationNameToPole
		metadata.poles = poles
	end
	for _, panelKey in xmlFile:iterator(key .. ".panels.panel") do
		local variationName = xmlFile:getString(panelKey .. "#variationName")
		local node = xmlFile:getNode(panelKey .. "#node", nil, fence.components, fence.i3dMapping)
		local collisionNode = xmlFile:getNode(panelKey .. "#collisionNode", nil, fence.components, fence.i3dMapping)
		local length = xmlFile:getFloat(panelKey .. "#length")
		local width = xmlFile:getFloat(panelKey .. "#width", 0)
		local height = xmlFile:getFloat(panelKey .. "#height", 2)
		local alignY = xmlFile:getBool(panelKey .. "#alignY")
		local nodeClone = clone(node, false, false, false)
		local templateId = fence.nodeCache:addTemplate(nodeClone)
		metadata.maxWidth = math.max(metadata.maxWidth, width)
		metadata.maxHeight = math.max(metadata.maxHeight, height)
		local collisionIndexPath = nil
		local colPosX = nil
		local colPosY = nil
		local colPosZ = nil
		if collisionNode ~= nil then
			collisionIndexPath = I3DUtil.getNodePathIndices(collisionNode, node, false)
			colPosX, colPosY, colPosZ = getTranslation(collisionNode)
		end
		local panel = { node = node, collisionIndexPath = collisionIndexPath, length = length, height = height, alignY = alignY, template = templateId, colPosX = colPosX, colPosY = colPosY, colPosZ = colPosZ, variationName = variationName }
		if variationName ~= nil then
			if variationNameToPanel[variationName] ~= nil then
				Logging.xmlWarning(xmlFile, "Variation name already defined for '%s'", panelKey)
			else
				variationNameToPanel[variationName] = panel
				table.insert(panels, panel)
			end
		end
	end
	if 0 < #panels then
		table.sort(panels, function(a, b)
			if a.length ~= b.length then
				return b.length < a.length
			else
				return a.template < b.template
			end
		end)
		metadata.panels = panels
		local maxScale = xmlFile:getFloat(key .. ".panels#maxScale")
		if maxScale ~= nil then
			if maxScale < 1 then
				Logging.xmlWarning(xmlFile, "Panels max scale %.3f at %q needs to be >= 1", maxScale, key .. ".panels#maxScale")
			else
				metadata.panelsMaxScale = maxScale
			end
		end
		local panelsUseRandomization = xmlFile:getBool(key .. ".panels#useRandomization")
		if panelsUseRandomization then
			metadata.panelsUseRandomization = panelsUseRandomization
		end
		local panelsByLength = {}
		local currentLength = math.huge
		local currentGroup = nil
		for index, panelData in ipairs(metadata.panels) do
			if panelData.length < currentLength then
				if currentGroup ~= nil then
					table.insert(panelsByLength, currentGroup)
				end
				currentGroup = {}
			end
			table.insert(currentGroup, panelData)
			currentLength = panelData.length
		end
		table.insert(panelsByLength, currentGroup)
		metadata.panelsGroupedByLength = panelsByLength
		metadata.variationNameToPanel = variationNameToPanel
	end
	return metadata
end
function FenceSegment.new(id, metadata, fence, customMt)
	local self = setmetatable({}, customMt or FenceSegment_mt)
	self.id = id
	if g_isDevelopmentVersion and g_server == nil then
		self.id = math.random(1, 99999999)
	end
	self.metadata = metadata
	self.fence = fence
	self.startPosX = nil
	self.startPosY = nil
	self.startPosZ = nil
	self.endPosX = nil
	self.endPosY = nil
	self.endPosZ = nil
	self.hasStartPole = nil
	self.hasEndPole = nil
	self.root = createTransformGroup("fenceSegmentRoot_" .. self.metadata.id .. "_" .. tostring(self):sub(10))
	self.notYetFinalized = true
	return self
end
function FenceSegment:delete()
	if self.cellIdUpdateListeners ~= nil then
		local terrainDeformationSyncer = g_currentMission.terrainDeformationSyncer
		if terrainDeformationSyncer ~= nil then
			for cellId, _ in pairs(self.cellIdUpdateListeners) do
				local cellX, cellZ = terrainDeformationSyncer:getCellIndicesById(cellId)
				terrainDeformationSyncer:removeCellUpdateListener(self, cellX, cellZ)
			end
		end
		self.cellIdUpdateListeners = nil
	end
	if self.pendingUpdateTimer ~= nil then
		self.pendingUpdateTimer:delete()
		self.pendingUpdateTimer = nil
	end
	local startNeighbor = nil
	local endNeighbor = nil
	if self.fence ~= nil then
		if self.startPosX ~= nil then
			startNeighbor = self.fence:getNeighborSegmentNeedingPoleUpdate(self.startPosX, self.startPosY, self.startPosZ, 0.1, self.id)
		end
		if self.endPosX ~= nil then
			endNeighbor = self.fence:getNeighborSegmentNeedingPoleUpdate(self.endPosX, self.endPosY, self.endPosZ, 0.1, self.id)
		end
	end
	if self.fence ~= nil then
		self.fence:removeSegment(self)
		self.fence = nil
	end
	if startNeighbor ~= nil then
		startNeighbor:removeNodeObjectMapping()
		startNeighbor:removeFromPhysics()
		startNeighbor:updateMeshes(true, false)
		startNeighbor:addToPhysics()
		startNeighbor:addNodeObjectMapping()
	end
	if endNeighbor ~= nil and endNeighbor ~= startNeighbor then
		endNeighbor:removeNodeObjectMapping()
		endNeighbor:removeFromPhysics()
		endNeighbor:updateMeshes(true, false)
		endNeighbor:addToPhysics()
		endNeighbor:addNodeObjectMapping()
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
function FenceSegment:loadFromXMLFile(xmlFile, key)
	local sx, sy, sz = xmlFile:getTranslation(key .. "#start")
	local ex, ey, ez = xmlFile:getTranslation(key .. "#end")
	if MathUtil.isNan(sx) or MathUtil.isNan(sz) or MathUtil.isNan(ex) or MathUtil.isNan(ez) then
		return false
	end
	self.startPosX = sx
	self.startPosY = sy
	self.startPosZ = sz
	self.endPosX = ex
	self.endPosY = ey
	self.endPosZ = ez
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
function FenceSegment:readStream(streamId, connection, lastSegment)
	local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
	local paramsY = g_currentMission.vehicleYPosCompressionParams
	if connection:getIsServer() then
		self.id = streamReadUInt16(streamId)
	end
	if streamReadBool(streamId) then
		self.startPosX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		self.startPosY = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		self.startPosZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
	else
		self.startPosX = lastSegment.endPosX
		self.startPosY = lastSegment.endPosY
		self.startPosZ = lastSegment.endPosZ
	end
	self.endPosX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
	self.endPosY = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
	self.endPosZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
	if self.metadata.poles and 0 < #self.metadata.poles then
		self.hasStartPole = streamReadBool(streamId)
		self.hasEndPole = streamReadBool(streamId)
	end
	self:registerTerrainHeightChangeCallbacks()
end
function FenceSegment:writeStream(streamId, connection, lastSegment)
	local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
	local paramsY = g_currentMission.vehicleYPosCompressionParams
	if not connection:getIsServer() then
		streamWriteUInt16(streamId, self.id)
	end
	local sendStartPos = true
	if lastSegment ~= nil and (lastSegment.endPosX == self.startPosX and (lastSegment.endPosY == self.startPosY and lastSegment.endPosZ == self.startPosZ)) then
		sendStartPos = false
	end
	if streamWriteBool(streamId, sendStartPos) then
		NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosX, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosY, paramsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosZ, paramsXZ)
	end
	NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosX, paramsXZ)
	NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosY, paramsY)
	NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosZ, paramsXZ)
	if self.metadata.poles and 0 < #self.metadata.poles then
		streamWriteBool(streamId, Utils.getNoNil(self.hasStartPole, false))
		streamWriteBool(streamId, Utils.getNoNil(self.hasEndPole, false))
	end
end
function FenceSegment:registerTerrainHeightChangeCallbacks()
	local dirX = self.endPosX - self.startPosX
	local dirZ = self.endPosZ - self.startPosZ
	if dirX == 0 and dirZ == 0 then
		return
	end
	local length = MathUtil.vector2Length(dirX, dirZ)
	dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
	local terrainDeformationSyncer = g_currentMission.terrainDeformationSyncer
	local offset = 0
	local stepSize = 0.5
	while true do
		local x = self.startPosX + dirX * offset
		local z = self.startPosZ + dirZ * offset
		local cellX, cellZ = terrainDeformationSyncer:getCellIndicesAtWorldPosition(x, z)
		if cellX == nil then
			break
		end
		local cellId = terrainDeformationSyncer:getCellId(cellX, cellZ)
		if self.cellIdUpdateListeners == nil then
			self.cellIdUpdateListeners = {}
		end
		if self.cellIdUpdateListeners[cellId] == nil then
			self.cellIdUpdateListeners[cellId] = true
			terrainDeformationSyncer:addCellUpdateListener(self, cellX, cellZ)
			break
		end
		if not (length <= offset) then
			offset = math.min(offset + 0.5, length)
			continue
		end
		return
	end
end
function FenceSegment:onTerrainDeformationSyncerUpdate(cellX, cellZ, cellId)
	if self.pendingUpdateTimer ~= nil then
		return
	else
		self.pendingUpdateTimer = Timer.new(5000)
		self.pendingUpdateTimer:setFinishCallback(function()
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
	I3DUtil.iterateRecursively(self.root, function(node)
		if getHasClassId(node, ClassIds.SHAPE) and getRigidBodyType(node) ~= RigidBodyType.NONE then
			g_currentMission:addNodeObject(node, self.fence)
		end
	end)
end
function FenceSegment:removeNodeObjectMapping()
	if self.root ~= nil then
		I3DUtil.iterateRecursively(self.root, function(node)
			if getHasClassId(node, ClassIds.SHAPE) and getRigidBodyType(node) ~= RigidBodyType.NONE then
				g_currentMission:removeNodeObject(node)
			end
		end)
	end
end
function FenceSegment:setStartPos(x, y, z)
	if x ~= self.startPosX or y ~= self.startPosY or z ~= self.startPosZ then
		self.startPosX = x
		self.startPosY = y
		self.startPosZ = z
		self.isDirty = true
	end
end
function FenceSegment:setStartNode(node)
	local x, y, z = getWorldTranslation(node)
	self:setStartPos(x, y, z)
end
function FenceSegment:setEndPos(x, y, z)
	if x ~= self.endPosX or y ~= self.endPosY or z ~= self.endPosZ then
		self.endPosX = x
		self.endPosY = y
		self.endPosZ = z
		self.isDirty = true
	end
end
function FenceSegment:setEndNode(node)
	local x, y, z = getWorldTranslation(node)
	self:setEndPos(x, y, z)
end
function FenceSegment:getStartPos()
	return self.startPosX, self.startPosY, self.startPosZ
end
function FenceSegment:getLength()
	if self.startPosX == nil or self.endPosX == nil then
		return 0
	end
	return MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ)
end
function FenceSegment:getActualLength()
	if self.startPosX == nil or self.actualEndX == nil then
		return 0
	end
	return MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
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
function FenceSegment:getMinimumPanelLength()
	local panels = self.metadata.panels
	if panels == nil or #panels == 0 then
		return nil
	end
	return panels[#panels].length
end
function FenceSegment:getLastError()
	return self.lastError
end
function FenceSegment:updateMeshes(force, validatePlacement)
	force = Utils.getNoNil(force, false)
	validatePlacement = Utils.getNoNil(validatePlacement, true)
	if g_server ~= nil then
		self.hasStartPole = nil
		self.hasEndPole = nil
	end
	self.lastError = nil
	if not force and not self.isDirty then
		return true
	end
	if self.startPosX == nil or self.endPosX == nil then
		return false
	end
	if not entityExists(self.root) then
		return false
	end
	local terrain = g_terrainNode or getChild(getRootNode(), "terrain")
	for i = getNumOfChildren(self.root) - 1, 0, -1 do
		local child = getChildAt(self.root, i)
		removeFromPhysics(child)
		unlink(child)
		self.fence.nodeCache:returnNodeToCache(child)
	end
	local length = MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ)
	if length < 0.1 then
		if self.metadata.poles and 0 < #self.metadata.poles then
			self:placePole(self.startPosX, self.startPosY, self.startPosZ, 1, 0)
		end
		self.lastError = FenceSegment.ERROR_TOO_SHORT
		return false
	elseif MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ) < 0.1 then
		self.lastError = FenceSegment.ERROR_TOO_SHORT
		return false
	else
		local segmentLengthXZ = MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
		local curLen = 0
		local dx, dz = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
		local x = nil
		local y = nil
		local z = nil
		local lastY = self.startPosY
		local previousPanel = nil
		local previousPanelLength = 0
		local previousPanelData = nil
		local maxScaleDiff = (self.metadata.panelsMaxScale or 1) - 1
		local minScale = 1 - maxScaleDiff
		local maxScale = 1 + maxScaleDiff
		local shortestPanelLength = self.metadata.panels[#self.metadata.panels].length
		local isFirstPole = true
		for _, panelGroup in ipairs(self.metadata.panelsGroupedByLength) do
			local panelGroupLength = panelGroup[1].length
			while panelGroupLength * minScale - 0.01 <= segmentLengthXZ - curLen do
				local randomPanelIndex = 1
				if self.metadata.panelsUseRandomization then
					randomPanelIndex = Fence.getDeterministicRandomValueForPosition(self.startPosX + curLen / 5, self.startPosY + curLen, self.startPosZ + curLen / 3, #panelGroup)
				end
				local panelData = panelGroup[randomPanelIndex]
				if self.metadata.poles and 0 < #self.metadata.poles then
					x, y, z = self:lerpOnTerrain(terrain, curLen / segmentLengthXZ)
					local poleTemplate = self.metadata.poles[Fence.getDeterministicRandomValueForPosition(x, y, z, #self.metadata.poles)]
					local needsPole = true
					if isFirstPole then
						if g_server ~= nil then
							local segment, isStartPole = self.fence:getNearPoleSegment(x, y, z, math.max(poleTemplate.radius, 0.05), self.id)
							if segment ~= nil then
								if isStartPole then
									local hasVisualStartPole = false
									if segment.getHasVisualStartPole ~= nil then
										hasVisualStartPole = segment:getHasVisualStartPole()
									end
									local hasAlreadyStartPole = segment.hasStartPole
									if hasVisualStartPole and hasAlreadyStartPole then
										needsPole = false
									end
								else
									local hasVisualEndPole = false
									if segment.getHasVisualEndPole ~= nil then
										hasVisualEndPole = segment:getHasVisualEndPole()
									end
									local hasAlreadyEndPole = segment.hasEndPole
									if hasVisualEndPole and hasAlreadyEndPole then
										needsPole = false
									end
								end
							end
							self.hasStartPole = needsPole
						else
							needsPole = self.hasStartPole
						end
					end
					if needsPole then
						self:placePole(x, y, z, dx, dz)
					end
					curLen = curLen + poleTemplate.radius
					isFirstPole = false
				end
				local remainingLength = segmentLengthXZ - curLen
				local maxPanelLength = panelData.length
				if remainingLength - panelData.length < shortestPanelLength * minScale then
					maxPanelLength = panelData.length * maxScale
				end
				local panelLength = math.clamp(segmentLengthXZ - curLen, panelData.length * minScale, maxPanelLength)
				x, y, z = self:lerpOnTerrain(terrain, curLen / segmentLengthXZ)
				if previousPanel ~= nil then
					FenceSegment.adjustPanelOffset(previousPanelData, previousPanel, previousPanelLength, y - lastY)
					self:updatePanel(previousPanelData, previousPanel, previousPanelLength, y - lastY)
				end
				if validatePlacement then
					local _, yTest, _ = self:lerpOnTerrain(terrain, (curLen + panelLength) / segmentLengthXZ)
					local slopeAngle = math.abs(math.atan((y - yTest) / panelLength))
					if self.metadata.maxSlopeAngle < slopeAngle then
						self.lastError = FenceSegment.ERROR_TOO_STEEP
						return false
					end
				end
				local panel = self.fence.nodeCache:getNodeInstance(panelData.template)
				removeFromPhysics(panel)
				link(self.root, panel)
				setWorldTranslation(panel, x, y, z)
				setWorldDirection(panel, dx, 0, dz, 0, 1, 0)
				if panelData.variationName ~= nil then
					setUserAttribute(panel, FenceSegment.USER_ATTRIBUTE_VARIATION, UserAttributeType.STRING, panelData.variationName)
				else
					removeUserAttribute(panel, FenceSegment.USER_ATTRIBUTE_VARIATION)
				end
				local scale = panelLength / panelData.length
				local actualPanelLength = panelLength
				if panelData.alignY then
					local endX, endY, endZ = self:lerpOnTerrain(terrain, (curLen + panelLength) / segmentLengthXZ)
					local dirX, dirY, dirZ = MathUtil.vector3Normalize(endX - x, endY - y, endZ - z)
					endX = x + dirX * panelLength
					endY = y + dirY * panelLength
					endZ = z + dirZ * panelLength
					if terrain ~= nil and terrain ~= 0 then
						endY = getTerrainHeightAtWorldPos(terrain, endX, 0, endZ)
					end
					dirX, dirY, dirZ = MathUtil.vector3Normalize(endX - x, endY - y, endZ - z)
					setWorldDirection(panel, dirX, dirY, dirZ, 0, 1, 0)
					actualPanelLength = MathUtil.vector2Length(endX - x, endZ - z)
					local alignedLength = MathUtil.vector3Length(endX - x, endY - y, endZ - z)
					scale = alignedLength / panelData.length
				end
				if scale ~= 1 then
					setScale(panel, 1, 1, scale)
				end
				curLen = curLen + actualPanelLength
				lastY = y
				previousPanel = panel
				previousPanelLength = actualPanelLength
				previousPanelData = panelData
			end
		end
		x, y, z = self:lerpOnTerrain(terrain, curLen / segmentLengthXZ)
		if self.metadata.poles and 0 < #self.metadata.poles then
			local needsPole = true
			if g_server ~= nil then
				local segment, isStartPole = self.fence:getNearPoleSegment(x, y, z, 0.05, self.id)
				if segment ~= nil then
					if isStartPole then
						if segment.getHasVisualStartPole ~= nil then
							local hasStartPole = segment:getHasVisualStartPole()
							if hasStartPole then
								needsPole = false
							end
						end
					elseif segment.getHasVisualEndPole ~= nil then
						if segment:getHasVisualEndPole() then
							needsPole = false
						end
					end
				end
				self.hasEndPole = needsPole
			else
				needsPole = self.hasEndPole
			end
			if needsPole then
				self:placePole(x, y, z, dx, dz)
			end
		end
		if previousPanel ~= nil then
			FenceSegment.adjustPanelOffset(previousPanelData, previousPanel, previousPanelLength, y - lastY)
			self:updatePanel(previousPanelData, previousPanel, previousPanelLength, y - lastY)
		end
		self.actualEndX = x
		self.actualEndY = y
		self.actualEndZ = z
		self.isDirty = false
		return true
	end
end
function FenceSegment:placePole(x, y, z, dx, dz)
	local sx, sy, sz = self:getStartPos()
	local distance = MathUtil.vector2Length(x - sx, z - sz)
	local randomIndex = Fence.getDeterministicRandomValueForPosition(sx + distance / 5, sy + distance, sz + distance / 3, #self.metadata.poles)
	local poleTemplate = self.metadata.poles[randomIndex]
	local pole = self.fence.nodeCache:getNodeInstance(poleTemplate.template)
	removeFromPhysics(pole)
	link(self.root, pole)
	setWorldTranslation(pole, x, y, z)
	setWorldDirection(pole, dx, 0, dz, 0, 1, 0)
	if poleTemplate.variationName ~= nil then
		setUserAttribute(pole, FenceSegment.USER_ATTRIBUTE_VARIATION, UserAttributeType.STRING, poleTemplate.variationName)
	else
		removeUserAttribute(pole, FenceSegment.USER_ATTRIBUTE_VARIATION)
	end
end
function FenceSegment:lerpOnTerrain(terrain, alpha)
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
function FenceSegment:getOverlapBox(length)
	length = length or MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
	local cx = (self.startPosX + self.actualEndX) / 2
	local cy = (self.startPosY + self.actualEndY) / 2
	local cz = (self.startPosZ + self.actualEndZ) / 2
	local rx = 0
	local ry = math.atan2(self.actualEndX - self.startPosX, self.actualEndZ - self.startPosZ) + 6.283185307179586
	local rz = 0
	local width = self.metadata.maxWidth
	local height = self.metadata.maxHeight
	local ex = width / 2
	local ey = math.abs(self.actualEndY - self.startPosY) / 2 + height
	local ez = length / 2
	local boundingCheckWidth = self.metadata.boundingCheckWidth
	if boundingCheckWidth ~= nil then
		ex = boundingCheckWidth * 0.5
		ez = length * 0.5 + boundingCheckWidth * 0.5
	end
	return cx, cy, cz, 0, ry, 0, ex, ey, ez
end
function FenceSegment:checkOverlap(hitNodesTable, ignoreChildrenNode)
	if self.actualEndX == nil then
		return
	end
	local length = MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
	if length == 0 then
		return
	else
		local cx, cy, cz, rx, ry, rz, ex, ey, ez = self:getOverlapBox(length)
		self.numOverlapHits = 0
		self.hitNodesTable = hitNodesTable
		self.ignoreChildrenNode = ignoreChildrenNode
		local mask = CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING + CollisionFlag.PLAYER + CollisionFlag.VEHICLE + CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT
		overlapCylinder(self.startPosX, self.startPosY + 0.5, self.startPosZ, 0.15, 3, Axis.Y, "onOverlapCylinderCallback", self, mask, false, true, true, true)
		overlapCylinder(self.actualEndX, self.actualEndY + 0.5, self.actualEndZ, 0.15, 3, Axis.Y, "onOverlapCylinderCallback", self, mask, false, true, true, true)
		overlapBox(cx, cy, cz, rx, ry, rz, ex, ey, ez, "onOverlapBoxCallback", self, mask, true, true, true, true)
		self.hitNodesTable = nil
		self.ignoreNodes = nil
		return hitNodesTable
	end
end
function FenceSegment:onOverlapCylinderCallback(hitNode)
	self.ignoreNodes = self.ignoreNodes or {}
	self.ignoreNodes[hitNode] = not self.ignoreNodes[hitNode]
end
function FenceSegment:onOverlapBoxCallback(hitNode)
	if hitNode == 0 then
		return
	end
	if self:getIsNodePartOfSegment(hitNode) then
		return
	end
	if self.ignoreChildrenNode ~= nil and I3DUtil.getIsLinkedToNode(self.ignoreChildrenNode, hitNode) then
		return
	end
	if self.ignoreNodes ~= nil and self.ignoreNodes[hitNode] then
		return
	end
	if self.parallelSnappingSegment ~= nil then
		local segment = self.fence:getSegmentFromNode(hitNode)
		if self.parallelSnappingSegment == segment then
			return
		end
	end
	if self.hitNodesTable ~= nil then
		self.hitNodesTable[hitNode] = true
	end
	self.numOverlapHits = self.numOverlapHits + 1
end
function FenceSegment:getHasBlockingOverlap(farmId)
	if self.actualEndX == nil then
		return false
	elseif not g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, self.startPosX, self.startPosZ, self.actualEndX, self.actualEndZ) then
		return true
	else
		return false
	end
end
function FenceSegment:getIsNodePartOfSegment(node)
	local parent = getParent(node)
	while parent ~= 0 do
		if self.root == parent then
			return true
		end
		parent = getParent(parent)
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
function FenceSegment:getSegmentPartStartEnd(node)
	node = self:getSegmentPartFromNode(node)
	if node == nil then
		return nil
	else
		local sx, sy, sz = getWorldTranslation(node)
		local childIndex = getChildIndex(node)
		local isFirst = MathUtil.vector3Length(sx - self.startPosX, sy - self.startPosY, sz - self.startPosZ) < 0.01
		local ex = nil
		local ey = nil
		local ez = nil
		local parent = getParent(node)
		local nextPart = childIndex + 1 < getNumOfChildren(parent) and getChildAt(parent, childIndex + 1) or nil
		if nextPart ~= nil then
			ex, ey, ez = getWorldTranslation(nextPart)
		else
			ex = self.endPosX
			ey = self.endPosY
			ez = self.endPosZ
		end
		local isLast = MathUtil.vector3Length(ex - self.endPosX, ey - self.endPosY, ez - self.endPosZ) < 0.01
		return sx, sy, sz, ex, ey, ez, isFirst, isLast
	end
end
function FenceSegment:getId()
	return self.metadata.id
end
function FenceSegment:getHasVisualEndPole()
	return self.metadata.poles ~= nil and 0 < #self.metadata.poles
end
function FenceSegment:getHasVisualStartPole()
	return self.metadata.poles ~= nil and 0 < #self.metadata.poles
end
function FenceSegment:iteratorPanels()
	local currentChildIndex = 0
	local endIndex = getNumOfChildren(self.root)
	local currentPanelIndex = 0
	local iterator = function()
		if endIndex <= currentChildIndex then
			return nil
		else
			if self.metadata.poles ~= nil then
				while self.metadata.poleNames[getName(getChildAt(self.root, currentChildIndex))] ~= nil do
					currentChildIndex = currentChildIndex + 1
					if endIndex <= currentChildIndex then
						return nil
					end
				end
			end
			currentChildIndex = currentChildIndex + 1
			currentPanelIndex = currentPanelIndex + 1
			return currentPanelIndex, getChildAt(self.root, currentChildIndex - 1)
		end
	end
	return iterator
end
function FenceSegment:iteratorPoles()
	local currentChildIndex = 0
	local endIndex = getNumOfChildren(self.root)
	local currentPoleIndex = 0
	if self.metadata.poles == nil then
		return function()
			return nil
		end
	else
		local iterator = function()
			if endIndex <= currentChildIndex then
				return nil
			else
				while self.metadata.poleNames[getName(getChildAt(self.root, currentChildIndex))] == nil do
					currentChildIndex = currentChildIndex + 1
					if endIndex <= currentChildIndex then
						return nil
					end
				end
				currentChildIndex = currentChildIndex + 1
				currentPoleIndex = currentPoleIndex + 1
				return currentPoleIndex, getChildAt(self.root, currentChildIndex - 1)
			end
		end
		return iterator
	end
end
function FenceSegment:update()
	local hitNodes = {}
	self:checkOverlap(hitNodes)
end
function FenceSegment:draw()
	if self.startPosX == nil or self.endPosX == nil then
		return
	end
end
function FenceSegment:finalize(loadedFromSavegame)
	if self.actualEndX == nil then
		return false
	else
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
end
function FenceSegment:addToPhysics()
	addToPhysics(self.root)
	self:setCollisionAreaDirty()
end
function FenceSegment:removeFromPhysics()
	removeFromPhysics(self.root)
	self:setCollisionAreaDirty()
end
function FenceSegment:setCollisionAreaDirty()
	if self.startPosX == nil or self.endPosX == nil then
		return
	end
	local minX = math.min(self.startPosX, self.endPosX)
	local maxX = math.max(self.startPosX, self.endPosX)
	local minZ = math.min(self.startPosZ, self.endPosZ)
	local maxZ = math.max(self.startPosZ, self.endPosZ)
	if g_densityMapHeightManager ~= nil then
		g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
	end
	if g_currentMission ~= nil and g_currentMission.aiSystem ~= nil then
		g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
	end
end
function FenceSegment:setOwnerFarmId(ownerFarmId, noEventSend) end
function FenceSegment:getOwnerFarmId()
	local farmId = g_farmlandManager:getOwnerIdAtWorldPosition(self.startPosX, self.startPosZ)
	return farmId
end
function FenceSegment:getCanBeModifiedByFarmId(farmId)
	local startFarmId = g_farmlandManager:getOwnerIdAtWorldPosition(self.startPosX, self.startPosZ)
	if startFarmId == farmId then
		return true
	end
	local endFarmId = g_farmlandManager:getOwnerIdAtWorldPosition(self.endPosX, self.endPosZ)
	if endFarmId == farmId then
		return true
	else
		return false
	end
end
function FenceSegment:updatePanel(panelData, panelNode, panelLength, deltaY) end
function FenceSegment:setParallelSnappingSegment(segment)
	self.parallelSnappingSegment = segment
end
function FenceSegment.adjustPanelOffset(panelData, panelNode, panelLength, deltaY)
	if not panelData.alignY then
		setShaderParameterRecursive(panelNode, "yOffset", deltaY, nil, nil, nil, false)
	end
	local collisionIndexPath = panelData.collisionIndexPath
	if collisionIndexPath ~= nil then
		local collisionNode = I3DUtil.indexToObject(panelNode, collisionIndexPath)
		if collisionNode ~= nil then
			local panelLengthCorrected = panelLength
			if panelData.alignY then
				deltaY = 0
			else
				panelLengthCorrected = math.sqrt(deltaY * deltaY + panelLength * panelLength)
			end
			local scale = panelLengthCorrected / panelData.length
			local offsetY = deltaY * scale
			local length = panelLengthCorrected * scale
			local xDir, yDir, zDir = MathUtil.vector3Normalize(0, offsetY, length)
			local offset = (panelLengthCorrected - panelLength) * 0.5
			local colX = panelData.colPosX + xDir * offset
			local colY = panelData.colPosY + yDir * offset
			local colZ = panelData.colPosZ + zDir * offset
			setDirection(collisionNode, xDir, yDir, zDir, 0, 1, 0)
			setTranslation(collisionNode, colX, colY, colZ)
		end
	end
end
