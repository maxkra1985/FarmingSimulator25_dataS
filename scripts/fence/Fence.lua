source("dataS/scripts/fence/FenceSegment.lua")
source("dataS/scripts/fence/FenceGate.lua")
Fence = {}
local Fence_mt = Class(Fence)
Fence.SMOOTH_RANDOM_SPREAD = 2.5
Fence.VARIANT_NOISE_FREQUENCY = 0.53
Fence.VARIANT_NOISE_OFFSET_PANEL = 11.7
Fence.VARIANT_NOISE_OFFSET_POLE = 53.9
Fence.CONNECTED_END_DISTANCE = 0.1
function Fence.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	schema:register(XMLValueType.STRING, basePath .. ".fence.segment(?)#id", "", nil, true)
	schema:register(XMLValueType.STRING, basePath .. ".fence.segment(?)#class", "", nil, true)
	FenceSegment.registerXMLPaths(schema, basePath .. ".fence.segment(?)")
	FenceGate.registerXMLPaths(schema, basePath .. ".fence.segment(?)")
end
g_xmlManager:addInitSchemaFunction(function()
	Fence.xmlSchema = XMLSchema.new("fence")
	Fence.registerXMLPaths(Fence.xmlSchema, "placeable")
end)
function Fence.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".segment(?)#id", "Segment id from config xml")
	FenceSegment.registerSavegameXMLPaths(schema, basePath .. ".segment(?)")
	FenceGate.registerSavegameXMLPaths(schema, basePath .. ".segment(?)")
end
function Fence.new(xmlFile, key, i3dFilename, components, i3dMapping, parentObject, linkNode, customMt)
	local self = setmetatable({}, customMt or Fence_mt)
	self.nextUniqueSegmentId = 1
	self.xmlFilename = xmlFile:getFilename()
	self.i3dFilename = i3dFilename
	local fenceI3d, sharedLoadRequestId, _ = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	if fenceI3d ~= nil and fenceI3d ~= 0 then
		delete(fenceI3d)
		self.sharedLoadRequestId = sharedLoadRequestId
	end
	self.components = components
	self.i3dMapping = i3dMapping
	self.parentObject = parentObject
	self.segmentTemplates = {}
	self.segmentTemplatesSorted = {}
	self.segments = {}
	self.segmentsById = {}
	self.sourceNodes = {}
	self.nodeCache = NodeCache.new()
	self.root = createTransformGroup(Utils.getFilenameFromPath(self.xmlFilename))
	link(linkNode or getRootNode(), self.root)
	return self
end
function Fence:delete()
	self.isBeingDeleted = true
	for _, segment in ipairs_reverse(self.segments) do
		segment:delete()
	end
	table.clear(self.segments)
	table.clear(self.segmentTemplates)
	table.clear(self.segmentTemplatesSorted)
	if self.nodeCache ~= nil then
		self.nodeCache:delete()
		self.nodeCache = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	for _, sourceNode in ipairs(self.sourceNodes) do
		if entityExists(sourceNode) then
			delete(sourceNode)
		end
	end
	table.clear(self.sourceNodes)
	self.parentObject = nil
	if self.root ~= nil and entityExists(self.root) then
		delete(self.root)
	end
	self.root = nil
end
function Fence:load(xmlFile, key)
	for _, segmentKey in xmlFile:iterator(key .. ".segment") do
		local className = xmlFile:getString(segmentKey .. "#class")
		local id = xmlFile:getString(segmentKey .. "#id")
		if self.segmentTemplates[id] ~= nil then
			Logging.xmlError(xmlFile, "given segment id %q at %q already in use", id, segmentKey)
		else
			local segmentClass = ClassUtil.getClassObject(className)
			if segmentClass == nil then
				Logging.xmlError(xmlFile, "class '%s' not defined for '%s'", className, segmentKey)
			else
				local metadata = segmentClass.loadMetadataFromXML(xmlFile, segmentKey, id, self)
				self.segmentTemplates[id] = metadata
				table.insert(self.segmentTemplatesSorted, id)
			end
		end
	end
	if table.size(self.segmentTemplates) == 0 then
		Logging.xmlError(xmlFile, "No segments defined for '%s'", key)
		return false
	else
		self:detachSourceNodes()
		return true
	end
end
function Fence:addSourceNode(node)
	if node == nil or not entityExists(node) then
		return
	end
	if table.hasElement(self.sourceNodes, node) then
		return
	else
		table.insert(self.sourceNodes, node)
	end
end
function Fence:detachSourceNodes()
	for _, sourceNode in ipairs(self.sourceNodes) do
		if getParent(sourceNode) == 0 then
			continue
		end
		removeFromPhysics(sourceNode)
		unlink(sourceNode)
	end
end
function Fence:loadFromXMLFile(xmlFile, key)
	for _, segmentKey in xmlFile:iterator(key .. ".segment") do
		local id = xmlFile:getString(segmentKey .. "#id")
		local segment = self:createNewSegment(id)
		if segment == nil then
			Logging.xmlWarning(xmlFile, "Unable to create fence segment for id %q, ignoring", id)
		elseif not segment:loadFromXMLFile(xmlFile, segmentKey) then
			Logging.xmlWarning(xmlFile, "Unable to load fence segment for id %q, ignoring", id)
			segment:delete()
		elseif not segment:finalize(true) then
			Logging.xmlWarning(xmlFile, "Unable to finalize fence segment for id %q, ignoring", id)
			segment:delete()
		else
		end
	end
end
function Fence:saveToXMLFile(xmlFile, key, usedModNames)
	local segmentXMLIndex = 0
	for _, segment in ipairs(self.segments) do
		if segment.needsSaving == nil or segment.needsSaving == true then
			local segmentKey = string.format("%s.segment(%d)", key, segmentXMLIndex)
			if segment:saveToXMLFile(xmlFile, segmentKey) then
				xmlFile:setString(segmentKey .. "#id", segment:getId())
				segmentXMLIndex = segmentXMLIndex + 1
			end
		end
	end
end
function Fence:readStream(streamId, connection)
	local numSegments = streamReadUInt16(streamId)
	local lastSegment = nil
	for i = 1, numSegments do
		local segmentTemplateIndex = streamReadUInt8(streamId)
		local segment = self:createNewSegment(self.segmentTemplatesSorted[segmentTemplateIndex])
		segment:readStream(streamId, connection, lastSegment)
		segment:updateMeshes(true, false)
		segment:finalize(true)
		lastSegment = segment
	end
end
function Fence:writeStream(streamId, connection)
	streamWriteUInt16(streamId, #self.segments)
	local lastSegment = nil
	for _, segment in ipairs(self.segments) do
		local segmentTemplateIndex = self:getSegmentTemplateIndexById(segment:getId())
		streamWriteUInt8(streamId, segmentTemplateIndex)
		segment:writeStream(streamId, connection, lastSegment)
		lastSegment = segment
	end
end
function Fence:getSegmentTemplateIndexById(segmentId)
	return table.find(self.segmentTemplatesSorted, segmentId)
end
function Fence:getSegmentTemplateIdByIndex(segmentTemplateIndex)
	return self.segmentTemplatesSorted[segmentTemplateIndex]
end
function Fence:getSegmentTemplateById(segmentId)
	return self.segmentTemplates[segmentId]
end
function Fence:getSegmentTemplates()
	return self.segmentTemplatesSorted
end
function Fence:createNewSegment(segmentId)
	local metadata = self.segmentTemplates[segmentId]
	if metadata == nil then
		Logging.error("No metadata for fence segment id %q", segmentId)
		return nil
	else
		local id = self.nextUniqueSegmentId
		self.nextUniqueSegmentId = self.nextUniqueSegmentId + 1
		local segment = metadata.class.new(id, metadata, self)
		link(self.root, segment.root)
		return segment
	end
end
function Fence:addSegment(segment)
	local existing = self.segmentsById[segment.id]
	if existing == segment then
		Logging.error("Fence segment %q already added to fence", segment)
	elseif existing ~= nil then
		Logging.error("Fence segment id %q already added to fence", segment.id)
	else
		segment:addNodeObjectMapping()
		table.insert(self.segments, segment)
		self.segmentsById[segment.id] = segment
		self:onSegmentCreated(segment)
	end
end
function Fence:removeSegment(segment)
	if segment ~= nil then
		segment:removeNodeObjectMapping()
		if self.segmentsById[segment.id] == segment then
			self.segmentsById[segment.id] = nil
		end
	end
	return table.removeElement(self.segments, segment)
end
function Fence:getNumSegments()
	return #self.segments
end
function Fence:getSegments()
	return self.segments
end
function Fence:getSegment(index)
	index = index or #self.segments
	return self.segments[index]
end
function Fence:getSegmentById(id)
	return self.segmentsById[id]
end
function Fence:getSegmentIndex(segment)
	return table.find(self.segments, segment)
end
function Fence:getSegmentFromNode(node)
	local parent = node
	while parent ~= 0 do
		if parent == self.root then
			break
		end
		for _, segment in ipairs(self.segments) do
			if segment.root == parent then
				return segment
			end
		end
		parent = getParent(parent)
	end
	return nil
end
function Fence:getIsOnFarmland(farmlandId)
	for _, segment in ipairs(self.segments) do
		local x, _, z = segment:getStartPos()
		if g_farmlandManager:getFarmlandIdAtWorldPosition(x, z) == farmlandId then
			return true
		end
		x, _, z = segment:getEndPos()
		if g_farmlandManager:getFarmlandIdAtWorldPosition(x, z) == farmlandId then
			return true
		end
	end
	return false
end
function Fence:getHasPoleNear(x, y, z, r)
	local pole = self:getPoleNear(x, y, z, r)
	if pole ~= nil then
		return true
	else
		local px = nil
		local py = nil
		local pz = nil
		for _, segment in ipairs_reverse(self.segments) do
			if segment.parentBackup == nil then
				px, py, pz = segment:getStartPos()
				if MathUtil.vector3Length(px - x, py - y, pz - z) < r then
					return true
				end
				px, py, pz = segment:getEndPos()
				if px == nil then
					continue
				end
				if MathUtil.vector3Length(px - x, py - y, pz - z) < r then
					return true
				end
			end
		end
		return false
	end
end
function Fence:getHasSegmentEndNear(x, z, radius, ignoreSegment)
	for _, segment in ipairs_reverse(self.segments) do
		if segment.parentBackup == nil then
			if segment == ignoreSegment then
				continue
			end
			local startX, _, startZ = segment:getStartPos()
			if startX ~= nil and MathUtil.vector2Length(startX - x, startZ - z) < radius then
				return true
			end
			local endX, _, endZ = segment:getEndPos()
			if endX == nil then
				continue
			end
			if MathUtil.vector2Length(endX - x, endZ - z) < radius then
				return true
			end
		end
	end
	return false
end
function Fence:getNearPoleSegment(x, y, z, r, ignoreId)
	local _, _, _, _, _, closestSegmentId, isStartPole, isEndPole = self:getPoleNear(x, y, z, r, ignoreId)
	if closestSegmentId == nil then
		local px = nil
		local py = nil
		local pz = nil
		for _, segment in ipairs_reverse(self.segments) do
			if segment.parentBackup == nil then
				if segment.id == ignoreId then
					continue
				end
				px, py, pz = segment:getStartPos()
				if MathUtil.vector3Length(px - x, py - y, pz - z) < r then
					closestSegmentId = segment.id
					isStartPole = true
					isEndPole = false
					break
				end
				px, py, pz = segment:getEndPos()
				if px == nil then
					continue
				end
				if MathUtil.vector3Length(px - x, py - y, pz - z) < r then
					closestSegmentId = segment.id
					isStartPole = false
					isEndPole = true
					break
				end
			end
		end
	end
	if closestSegmentId ~= nil then
		local segment = self:getSegmentById(closestSegmentId)
		return segment, isStartPole, isEndPole
	else
		return nil
	end
end
function Fence:getNeighborSegmentNeedingPoleUpdate(x, y, z, r, ignoreId)
	local candidate = nil
	for _, segment in ipairs(self.segments) do
		if segment.parentBackup == nil then
			if segment.id == ignoreId then
				continue
			end
			local segStartX, segStartY, segStartZ = segment:getStartPos()
			local connectedAtStart = segStartX ~= nil and MathUtil.vector3Length(segStartX - x, segStartY - y, segStartZ - z) < r
			local segEndX, segEndY, segEndZ = segment:getEndPos()
			local connectedAtEnd = segEndX ~= nil and MathUtil.vector3Length(segEndX - x, segEndY - y, segEndZ - z) < r
			if connectedAtStart or connectedAtEnd then
				if connectedAtStart and segment:getHasOwnStartPole() then
					return nil
				end
				if connectedAtEnd and segment:getHasOwnEndPole() then
					return nil
				end
				if candidate == nil then
					local canRenderStartPole = connectedAtStart and segment:getHasVisualStartPole()
					local canRenderEndPole = connectedAtEnd and segment:getHasVisualEndPole()
					if canRenderStartPole or canRenderEndPole then
						candidate = segment
					end
				end
			end
		end
	end
	return candidate
end
function Fence:getPoleNear(x, y, z, r, ignoreId)
	r = r or 0.05
	self.poleNearTargetX = x
	self.poleNearTargetY = y
	self.poleNearTargetZ = z
	self.poleNearTargetRadius = r
	self.closestPoleDistance = math.huge
	self.closestPoleOrPanel = nil
	self.closestSegmentId = nil
	self.poleNearX = nil
	self.poleNearY = nil
	self.poleNearZ = nil
	self.segmentIgnoreId = ignoreId
	self.closestPoleIsStartPole = false
	self.closestPoleIsEndPole = false
	overlapSphere(x, y, z, r, "onPoleOverlapSphereCallback", self, CollisionFlag.STATIC_OBJECT, false, false, true, false)
	return self.closestPoleOrPanel, self.closestPoleDistance, self.poleNearX, self.poleNearY, self.poleNearZ, self.closestSegmentId, self.closestPoleIsStartPole, self.closestPoleIsEndPole
end
function Fence:onPoleOverlapSphereCallback(nodeId, subShapeIndex, isLast)
	local segment = self:getSegmentFromNode(nodeId)
	if segment == nil then
		return true
	elseif self.segmentIgnoreId ~= nil and self.segmentIgnoreId == segment.id then
		return true
	else
		local poleOrPanelRoot = nodeId
		while getParent(poleOrPanelRoot) ~= segment.root do
			poleOrPanelRoot = getParent(poleOrPanelRoot)
		end
		local sx, sy, sz, ex, ey, ez, isFirstPole, isLastPole = segment:getSegmentPartStartEnd(poleOrPanelRoot)
		local distanceStart = MathUtil.vector3Length(self.poleNearTargetX - sx, self.poleNearTargetY - sy, self.poleNearTargetZ - sz)
		local distanceEnd = MathUtil.vector3Length(self.poleNearTargetX - ex, self.poleNearTargetY - ey, self.poleNearTargetZ - ez)
		if distanceStart < self.closestPoleDistance and distanceStart < self.poleNearTargetRadius then
			self.closestPoleDistance = distanceStart
			self.closestPoleOrPanel = poleOrPanelRoot
			self.poleNearX = sx
			self.poleNearY = sy
			self.poleNearZ = sz
			self.closestSegmentId = segment.id
			self.closestPoleIsStartPole = isFirstPole
			self.closestPoleIsEndPole = isLastPole
		end
		if distanceEnd < self.closestPoleDistance and distanceEnd < self.poleNearTargetRadius then
			self.closestPoleDistance = distanceEnd
			self.closestPoleOrPanel = poleOrPanelRoot
			self.poleNearX = ex
			self.poleNearY = ey
			self.poleNearZ = ez
			self.closestSegmentId = segment.id
			self.closestPoleIsStartPole = isFirstPole
			self.closestPoleIsEndPole = isLastPole
		end
		return true
	end
end
function Fence:getAllowSegmentDeletion()
	if self.parentObject ~= nil and (self.parentObject.getAllowFenceSegmentDeletion ~= nil and not self.parentObject.getAllowFenceSegmentDeletion()) then
		return false
	end
	return true
end
function Fence:deleteSegmentPart(segment, nodeId, wholeSegment)
	local panelNode = segment:getDeletablePanelFromNode(nodeId)
	if panelNode == nil then
		return nil
	end
	local sx, sy, sz, ex, ey, ez, first, last = segment:getSegmentPartStartEnd(panelNode)
	if sx == nil then
		return nil
	else
		local osx, osy, osz = segment:getStartPos()
		local oex, oey, oez = segment:getEndPos()
		local templateId = segment:getId()
		local seedOriginX, seedOriginY, seedOriginZ = segment:getSeedOrigin()
		local willRebuildParts = not wholeSegment and not (first and last)
		if willRebuildParts then
			segment:onSegmentSplit(panelNode, first, last)
		end
		self:removeSegment(segment)
		segment:delete()
		local newSegments = {}
		if not first or not last then
			if wholeSegment then
			else
				local rebuildPart = function(startX, startY, startZ, endX, endY, endZ)
					local newSegment = self:createNewSegment(templateId)
					if newSegment == nil then
						return
					end
					newSegment:setStartPos(startX, startY, startZ)
					newSegment:setEndPos(endX, endY, endZ)
					newSegment:setSeedOrigin(seedOriginX, seedOriginY, seedOriginZ)
					if not newSegment:updateMeshes(true, false) then
						newSegment:delete()
						return
					end
					newSegment.isRebuiltFromSplit = true
					if not newSegment:finalize(false) then
						newSegment:delete()
					else
						table.insert(newSegments, newSegment)
					end
				end
				if not first then
					rebuildPart(osx, osy, osz, sx, sy, sz)
				end
				if not last then
					rebuildPart(ex, ey, ez, oex, oey, oez)
				end
				return newSegments
			end
		end
		return newSegments
	end
end
function Fence:onSegmentCreated(segment)
	if self.parentObject ~= nil and self.parentObject.onSegmentCreated ~= nil then
		self.parentObject:onSegmentCreated(segment)
	end
end
function Fence:update() end
function Fence:draw()
	for _, segment in ipairs(self.segments) do
		if segment.draw == nil then
			continue
		end
		segment:draw()
	end
end
function Fence:finalize(loadedFromSavegame)
	self.nodeCache:empty()
end
function Fence:setOwnerFarmId(ownerFarmId, noEventSend)
	for _, segment in ipairs(self.segments) do
		segment:setOwnerFarmId(ownerFarmId, noEventSend)
	end
end
function Fence.getDeterministicRandomValueForPosition(x, y, z, maxInt)
	local alpha = (x * 11.1 + y * 13.21 + z * 17.39) % 1
	if maxInt == nil then
		return alpha
	else
		return math.floor(alpha * maxInt) + 1
	end
end
function Fence.getSmoothRandomValueForPosition(x, y, z, frequency, sampleOffset)
	local noiseValue = math.noise(x * frequency + sampleOffset, y * frequency + sampleOffset, z * frequency + sampleOffset)
	return math.clamp(noiseValue * Fence.SMOOTH_RANDOM_SPREAD, -1, 1) * 0.5 + 0.5
end
function Fence.getSmoothRandomAngleForPosition(x, y, z, frequency, sampleOffset)
	local scaledX = x * frequency
	local scaledY = y * frequency
	local scaledZ = z * frequency
	local dirX = math.noise(scaledX + sampleOffset, scaledY + sampleOffset, scaledZ + sampleOffset)
	local dirZ = math.noise(scaledX - sampleOffset, scaledY - sampleOffset, scaledZ - sampleOffset)
	return math.atan2(dirZ, dirX)
end
function Fence.getSmoothRandomIndexForPosition(x, y, z, frequency, sampleOffset, maxInt)
	local alpha = Fence.getSmoothRandomValueForPosition(x, y, z, frequency, sampleOffset)
	return math.min(math.floor(alpha * maxInt) + 1, maxInt)
end
