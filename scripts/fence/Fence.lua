-- Local values: Fence_mt
source("dataS/scripts/fence/FenceSegment.lua")
source("dataS/scripts/fence/FenceGate.lua")
Fence = {}
local Fence_mt = Class(Fence)

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

-- Upvalues: Fence_mt
-- Local values: self, fenceI3d, sharedLoadRequestId, _
function Fence.new(xmlFile, key, i3dFilename, components, i3dMapping, parentObject, linkNode, customMt)
	-- upvalues: (copy) Fence_mt
	local v13_ = customMt or Fence_mt
	local v14_ = setmetatable({}, v13_)
	v14_.nextUniqueSegmentId = 1
	v14_.xmlFilename = xmlFile:getFilename()
	v14_.i3dFilename = i3dFilename
	local v15_, v16_, _ = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	if v15_ ~= nil then
		v14_.fenceI3DNode = v15_
		v14_.sharedLoadRequestId = v16_
	end
	v14_.components = components
	v14_.i3dMapping = i3dMapping
	v14_.parentObject = parentObject
	v14_.segmentTemplates = {}
	v14_.segmentTemplatesSorted = {}
	v14_.segments = {}
	v14_.nodeCache = NodeCache.new()
	v14_.root = createTransformGroup(Utils.getFilenameFromPath(v14_.xmlFilename))
	link(linkNode or getRootNode(), v14_.root)
	return v14_
end

-- Local values: _, segment
function Fence:delete()
	for _, v18_ in ipairs_reverse(self.segments) do
		v18_:delete()
	end
	table.clear(self.segments)
	table.clear(self.segmentTemplates)
	table.clear(self.segmentTemplatesSorted)
	if self.nodeCache ~= nil then
		self.nodeCache:delete()
		self.nodeCache = nil
	end
	if self.fenceI3DNode ~= nil then
		delete(self.fenceI3DNode)
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.fenceI3DNode = nil
		self.sharedLoadRequestId = nil
	end
	self.parentObject = nil
	if self.root ~= nil and entityExists(self.root) then
		delete(self.root)
	end
	self.root = nil
end

-- Local values: _, segmentKey, className, id, segmentClass, metadata
function Fence:load(xmlFile, key)
	for _, v22_ in xmlFile:iterator(key .. ".segment") do
		local v23_ = xmlFile:getString(v22_ .. "#class")
		local v24_ = xmlFile:getString(v22_ .. "#id")
		if self.segmentTemplates[v24_] == nil then
			local v25_ = ClassUtil.getClassObject(v23_)
			if v25_ == nil then
				Logging.xmlError(xmlFile, "class \'%s\' not defined for \'%s\'", v23_, v22_)
			else
				local v26_ = v25_.loadMetadataFromXML(xmlFile, v22_, v24_, self)
				self.segmentTemplates[v24_] = v26_
				local v27_ = self.segmentTemplatesSorted
				table.insert(v27_, v24_)
			end
		else
			Logging.xmlError(xmlFile, "given segment id %q at %q already in use", v24_, v22_)
		end
	end
	if table.size(self.segmentTemplates) ~= 0 then
		return true
	end
	Logging.xmlError(xmlFile, "No segments defined for \'%s\'", key)
	return false
end

-- Local values: _, segmentKey, id, segment
function Fence:loadFromXMLFile(xmlFile, key)
	for _, v31_ in xmlFile:iterator(key .. ".segment") do
		local v32_ = xmlFile:getString(v31_ .. "#id")
		local v33_ = self:createNewSegment(v32_)
		if v33_ == nil then
			Logging.xmlWarning(xmlFile, "Unable to create fence segment for id %q, ignoring", v32_)
		elseif v33_:loadFromXMLFile(xmlFile, v31_) then
			if not v33_:finalize(true) then
				Logging.xmlWarning(xmlFile, "Unable to finalize fence segment for id %q, ignoring", v32_)
				v33_:delete()
			end
		else
			Logging.xmlWarning(xmlFile, "Unable to load fence segment for id %q, ignoring", v32_)
			v33_:delete()
		end
	end
end

-- Local values: segmentXMLIndex, _, segment, segmentKey
function Fence:saveToXMLFile(xmlFile, key, usedModNames)
	local v37_ = 0
	for _, v38_ in ipairs(self.segments) do
		if v38_.needsSaving == nil or v38_.needsSaving == true then
			local v39_ = string.format("%s.segment(%d)", key, v37_)
			if v38_:saveToXMLFile(xmlFile, v39_) then
				xmlFile:setString(v39_ .. "#id", v38_:getId())
				v37_ = v37_ + 1
			end
		end
	end
end

-- Local values: numSegments, lastSegment, i, segmentTemplateIndex, segment
function Fence:readStream(streamId, connection)
	local v43_ = nil
	for _ = 1, streamReadUInt16(streamId) do
		local v44_ = streamReadUInt8(streamId)
		local v45_ = self:createNewSegment(self.segmentTemplatesSorted[v44_])
		v45_:readStream(streamId, connection, v43_)
		v45_:updateMeshes(true, false)
		v45_:finalize(true)
		v43_ = v45_
	end
end

-- Local values: lastSegment, _, segment, segmentTemplateIndex
function Fence:writeStream(streamId, connection)
	streamWriteUInt16(streamId, #self.segments)
	local v49_ = nil
	for _, v50_ in ipairs(self.segments) do
		local v51_ = self:getSegmentTemplateIndexById(v50_:getId())
		streamWriteUInt8(streamId, v51_)
		v50_:writeStream(streamId, connection, v49_)
		v49_ = v50_
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

-- Local values: metadata, id, segment
function Fence:createNewSegment(segmentId)
	local v61_ = self.segmentTemplates[segmentId]
	if v61_ == nil then
		Logging.error("No metadata for fence segment id %q", segmentId)
		return nil
	end
	local v62_ = self.nextUniqueSegmentId
	self.nextUniqueSegmentId = self.nextUniqueSegmentId + 1
	local v63_ = v61_.class.new(v62_, v61_, self)
	link(self.root, v63_.root)
	return v63_
end

-- Local values: _, s
function Fence:addSegment(segment)
	if table.hasElement(self.segments, segment) then
		Logging.error("Fence segment %q already added to fence", segment)
	else
		for _, v66_ in ipairs(self.segments) do
			if v66_.id == segment.id then
				Logging.error("Fence segment id %q already added to fence", segment.id)
				return
			end
		end
		segment:addNodeObjectMapping()
		local v67_ = self.segments
		table.insert(v67_, segment)
		self:onSegmentCreated(segment)
	end
end

function Fence:removeSegment(segment)
	if segment ~= nil then
		segment:removeNodeObjectMapping()
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
	local v74_ = index or #self.segments
	return self.segments[v74_]
end

-- Local values: _, segment
function Fence:getSegmentById(id)
	for _, v77_ in pairs(self.segments) do
		if v77_.id == id then
			return v77_
		end
	end
	return nil
end

function Fence:getSegmentIndex(segment)
	return table.find(self.segments, segment)
end

-- Local values: parent, _, segment
function Fence:getSegmentFromNode(node)
	while node ~= 0 and node ~= self.root do
		for _, v82_ in ipairs(self.segments) do
			if v82_.root == node then
				return v82_
			end
		end
		node = getParent(node)
	end
	return nil
end

-- Local values: _, segment, x, _, z
function Fence:getIsOnFarmland(farmlandId)
	for _, v85_ in ipairs(self.segments) do
		local v86_, _, v87_ = v85_:getStartPos()
		if g_farmlandManager:getFarmlandIdAtWorldPosition(v86_, v87_) == farmlandId then
			return true
		end
		local v88_, _, v89_ = v85_:getEndPos()
		if g_farmlandManager:getFarmlandIdAtWorldPosition(v88_, v89_) == farmlandId then
			return true
		end
	end
	return false
end

-- Local values: pole, px, py, pz, _, segment
function Fence:getHasPoleNear(x, y, z, r)
	if self:getPoleNear(x, y, z, r) ~= nil then
		return true
	end
	for _, v95_ in ipairs_reverse(self.segments) do
		if v95_.parentBackup == nil then
			local v96_, v97_, v98_ = v95_:getStartPos()
			if MathUtil.vector3Length(v96_ - x, v97_ - y, v98_ - z) < r then
				return true
			end
			local v99_, v100_, v101_ = v95_:getEndPos()
			if v99_ ~= nil and MathUtil.vector3Length(v99_ - x, v100_ - y, v101_ - z) < r then
				return true
			end
		end
	end
	return false
end

-- Local values: _, _, _, _, _, closestSegmentId, isStartPole, px, py, pz, _, segment
function Fence:getNearPoleSegment(x, y, z, r, ignoreId)
	local _, _, _, _, _, v108_, v109_ = self:getPoleNear(x, y, z, r, ignoreId)
	if v108_ == nil then
		for _, v110_ in ipairs_reverse(self.segments) do
			if v110_.parentBackup == nil and v110_.id ~= ignoreId then
				local v111_, v112_, v113_ = v110_:getStartPos()
				if MathUtil.vector3Length(v111_ - x, v112_ - y, v113_ - z) < r then
					v108_ = v110_.id
					v109_ = true
					break
				end
				local v114_, v115_, v116_ = v110_:getEndPos()
				if v114_ ~= nil and MathUtil.vector3Length(v114_ - x, v115_ - y, v116_ - z) < r then
					v108_ = v110_.id
					v109_ = false
					break
				end
			end
		end
	end
	if v108_ == nil then
		return nil
	else
		return self:getSegmentById(v108_), v109_
	end
end

-- Local values: candidate, _, segment, segStartX, segStartY, segStartZ, connectedAtStart, segEndX, segEndY, segEndZ, connectedAtEnd
function Fence:getNeighborSegmentNeedingPoleUpdate(x, y, z, r, ignoreId)
	local v123_ = nil
	for _, v124_ in ipairs(self.segments) do
		if v124_.parentBackup == nil and v124_.id ~= ignoreId then
			local v125_, v126_, v127_ = v124_:getStartPos()
			local v128_
			if v125_ == nil then
				v128_ = false
			else
				v128_ = MathUtil.vector3Length(v125_ - x, v126_ - y, v127_ - z) < r
			end
			local v129_, v130_, v131_ = v124_:getEndPos()
			local v132_
			if v129_ == nil then
				v132_ = false
			else
				v132_ = MathUtil.vector3Length(v129_ - x, v130_ - y, v131_ - z) < r
			end
			if v128_ or v132_ then
				if v128_ and v124_.hasStartPole == true then
					return nil
				end
				if v132_ and v124_.hasEndPole == true then
					return nil
				end
				if v123_ == nil then
					v123_ = v124_
				end
			end
		end
	end
	return v123_
end

function Fence:getPoleNear(x, y, z, r, ignoreId)
	local v139_ = r or 0.05
	self.poleNearTargetX = x
	self.poleNearTargetY = y
	self.poleNearTargetZ = z
	self.poleNearTargetRadius = v139_
	self.closestPoleDistance = math.huge
	self.closestPoleOrPanel = nil
	self.closestSegmentId = nil
	self.poleNearX = nil
	self.poleNearY = nil
	self.poleNearZ = nil
	self.segmentIgnoreId = ignoreId
	self.closestPoleIsStartPole = false
	self.closestPoleIsEndPole = false
	overlapSphere(x, y, z, v139_, "onPoleOverlapSphereCallback", self, CollisionFlag.STATIC_OBJECT, false, false, true, false)
	return self.closestPoleOrPanel, self.closestPoleDistance, self.poleNearX, self.poleNearY, self.poleNearZ, self.closestSegmentId, self.closestPoleIsStartPole, self.closestPoleIsEndPole
end

-- Local values: segment, poleOrPanelRoot, sx, sy, sz, ex, ey, ez, isFirstPole, isLastPole, distanceStart, distanceEnd
function Fence:onPoleOverlapSphereCallback(nodeId, subShapeIndex, isLast)
	local v142_ = self:getSegmentFromNode(nodeId)
	if v142_ == nil then
		return true
	end
	if self.segmentIgnoreId ~= nil and self.segmentIgnoreId == v142_.id then
		return true
	end
	while getParent(nodeId) ~= v142_.root do
		nodeId = getParent(nodeId)
	end
	local v143_, v144_, v145_, v146_, v147_, v148_, v149_, v150_ = v142_:getSegmentPartStartEnd(nodeId)
	local v151_ = MathUtil.vector3Length(self.poleNearTargetX - v143_, self.poleNearTargetY - v144_, self.poleNearTargetZ - v145_)
	local v152_ = MathUtil.vector3Length(self.poleNearTargetX - v146_, self.poleNearTargetY - v147_, self.poleNearTargetZ - v148_)
	if v151_ < self.closestPoleDistance and v151_ < self.poleNearTargetRadius then
		self.closestPoleDistance = v151_
		self.closestPoleOrPanel = nodeId
		self.poleNearX = v143_
		self.poleNearY = v144_
		self.poleNearZ = v145_
		self.closestSegmentId = v142_.id
		self.closestPoleIsStartPole = v149_
		self.closestPoleIsEndPole = v150_
	end
	if v152_ < self.closestPoleDistance and v152_ < self.poleNearTargetRadius then
		self.closestPoleDistance = v152_
		self.closestPoleOrPanel = nodeId
		self.poleNearX = v146_
		self.poleNearY = v147_
		self.poleNearZ = v148_
		self.closestSegmentId = v142_.id
		self.closestPoleIsStartPole = v149_
		self.closestPoleIsEndPole = v150_
	end
	return true
end

function Fence:getAllowSegmentDeletion()
	return (self.parentObject == nil or (self.parentObject.getAllowFenceSegmentDeletion == nil or self.parentObject.getAllowFenceSegmentDeletion())) and true or false
end

-- Local values: sx, sy, sz, ex, ey, ez, first, last, osx, osy, osz, oex, oey, oez, id, newSegment, newSegment
function Fence:deleteSegmentPart(segment, nodeId, wholeSegment)
	local v158_, v159_, v160_, v161_, v162_, v163_, v164_, v165_ = segment:getSegmentPartStartEnd(nodeId)
	if v158_ == nil then
		return false
	end
	local v166_, v167_, v168_ = segment:getStartPos()
	local v169_, v170_, v171_ = segment:getEndPos()
	local v172_ = segment:getId()
	self:removeSegment(segment)
	segment:delete()
	if v165_ and v164_ then
		return true
	end
	if wholeSegment then
		return true
	end
	if not v164_ then
		local v173_ = self:createNewSegment(v172_)
		v173_:setStartPos(v166_, v167_, v168_)
		v173_:setEndPos(v158_, v159_, v160_)
		v173_:updateMeshes()
		v173_:finalize(false)
	end
	if not v165_ then
		local v174_ = self:createNewSegment(v172_)
		v174_:setStartPos(v161_, v162_, v163_)
		v174_:setEndPos(v169_, v170_, v171_)
		v174_:updateMeshes()
		v174_:finalize(false)
	end
	return true
end

function Fence:onSegmentCreated(segment)
	if self.parentObject ~= nil and self.parentObject.onSegmentCreated ~= nil then
		self.parentObject:onSegmentCreated(segment)
	end
end

function Fence:update() end

-- Local values: _, segment
function Fence:draw()
	for _, v178_ in ipairs(self.segments) do
		if v178_.draw ~= nil then
			v178_:draw()
		end
	end
end

function Fence:finalize(loadedFromSavegame)
	self.nodeCache:empty()
end

-- Local values: _, segment
function Fence:setOwnerFarmId(ownerFarmId, noEventSend)
	for _, v183_ in ipairs(self.segments) do
		v183_:setOwnerFarmId(ownerFarmId, noEventSend)
	end
end

-- Local values: alpha
function Fence.getDeterministicRandomValueForPosition(x, y, z, maxInt)
	local v188_ = (x * 11.1 + y * 13.21 + z * 17.39) % 1
	if maxInt == nil then
		return v188_
	end
	local v189_ = v188_ * maxInt
	return math.floor(v189_) + 1
end
