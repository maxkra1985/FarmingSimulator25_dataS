PlaceableFence = {}
PlaceableFence.EPSILON = 0.00001
source("dataS/scripts/placeables/specializations/events/PlaceableFenceAddGateEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableFenceAddSegmentEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableFenceRemoveSegmentEvent.lua")

function PlaceableFence.prerequisitesPresent(self)
	return true
end

function PlaceableFence.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onCreateSegmentPanel")
end

function PlaceableFence.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "addSegment", PlaceableFence.addSegment)
	SpecializationUtil.registerFunction(placeableType, "addSegmentShapesToUpdate", PlaceableFence.addSegmentShapesToUpdate)
	SpecializationUtil.registerFunction(placeableType, "createSegment", PlaceableFence.createSegment)
	SpecializationUtil.registerFunction(placeableType, "deletePanel", PlaceableFence.deletePanel)
	SpecializationUtil.registerFunction(placeableType, "deleteSegment", PlaceableFence.deleteSegment)
	SpecializationUtil.registerFunction(placeableType, "doDeletePanel", PlaceableFence.doDeletePanel)
	SpecializationUtil.registerFunction(placeableType, "fakeRandomValueForPosition", PlaceableFence.fakeRandomValueForPosition)
	SpecializationUtil.registerFunction(placeableType, "findRaycastInfo", PlaceableFence.findRaycastInfo)
	SpecializationUtil.registerFunction(placeableType, "generateSegmentPoles", PlaceableFence.generateSegmentPoles)
	SpecializationUtil.registerFunction(placeableType, "getGate", PlaceableFence.getGate)
	SpecializationUtil.registerFunction(placeableType, "getMaxVerticalAngle", PlaceableFence.getMaxVerticalAngle)
	SpecializationUtil.registerFunction(placeableType, "getMaxVerticalAngleAndYForPreview", PlaceableFence.getMaxVerticalAngleAndYForPreview)
	SpecializationUtil.registerFunction(placeableType, "getMaxVerticalGateAngle", PlaceableFence.getMaxVerticalGateAngle)
	SpecializationUtil.registerFunction(placeableType, "getNodesToDeleteForPanel", PlaceableFence.getNodesToDeleteForPanel)
	SpecializationUtil.registerFunction(placeableType, "getNumSequments", PlaceableFence.getNumSequments)
	SpecializationUtil.registerFunction(placeableType, "getPanelLength", PlaceableFence.getPanelLength)
	SpecializationUtil.registerFunction(placeableType, "getIsPanelLengthFixed", PlaceableFence.getIsPanelLengthFixed)
	SpecializationUtil.registerFunction(placeableType, "getPoleNear", PlaceableFence.getPoleNear)
	SpecializationUtil.registerFunction(placeableType, "getPoleNearOverlapCallback", PlaceableFence.getPoleNearOverlapCallback)
	SpecializationUtil.registerFunction(placeableType, "getPolePosition", PlaceableFence.getPolePosition)
	SpecializationUtil.registerFunction(placeableType, "getPoleShapeForPreview", PlaceableFence.getPoleShapeForPreview)
	SpecializationUtil.registerFunction(placeableType, "getPreviewSegment", PlaceableFence.getPreviewSegment)
	SpecializationUtil.registerFunction(placeableType, "getSegment", PlaceableFence.getSegment)
	SpecializationUtil.registerFunction(placeableType, "getSegmentLength", PlaceableFence.getSegmentLength)
	SpecializationUtil.registerFunction(placeableType, "isPoleInAnySegment", PlaceableFence.isPoleInAnySegment)
	SpecializationUtil.registerFunction(placeableType, "recursivelyAddPickingNodes", PlaceableFence.recursivelyAddPickingNodes)
	SpecializationUtil.registerFunction(placeableType, "addPickingNodesForSegment", PlaceableFence.addPickingNodesForSegment)
	SpecializationUtil.registerFunction(placeableType, "removePickingNodesForSegment", PlaceableFence.removePickingNodesForSegment)
	SpecializationUtil.registerFunction(placeableType, "setPreviewSegment", PlaceableFence.setPreviewSegment)
	SpecializationUtil.registerFunction(placeableType, "updatePanelVisuals", PlaceableFence.updatePanelVisuals)
	SpecializationUtil.registerFunction(placeableType, "updateSegmentShapes", PlaceableFence.updateSegmentShapes)
	SpecializationUtil.registerFunction(placeableType, "updateSegmentUpdateQueue", PlaceableFence.updateSegmentUpdateQueue)
	SpecializationUtil.registerFunction(placeableType, "updateDirtyAreas", PlaceableFence.updateDirtyAreas)
	SpecializationUtil.registerFunction(placeableType, "getSupportsParallelSnapping", PlaceableFence.getSupportsParallelSnapping)
	SpecializationUtil.registerFunction(placeableType, "getBoundingCheckWidth", PlaceableFence.getBoundingCheckWidth)
	SpecializationUtil.registerFunction(placeableType, "getSnapDistance", PlaceableFence.getSnapDistance)
	SpecializationUtil.registerFunction(placeableType, "getSnapAngle", PlaceableFence.getSnapAngle)
	SpecializationUtil.registerFunction(placeableType, "getSnapCheckDistance", PlaceableFence.getSnapCheckDistance)
	SpecializationUtil.registerFunction(placeableType, "getAllowExtendingOnly", PlaceableFence.getAllowExtendingOnly)
	SpecializationUtil.registerFunction(placeableType, "getMaxCornerAngle", PlaceableFence.getMaxCornerAngle)
	SpecializationUtil.registerFunction(placeableType, "getHasParallelSnapping", PlaceableFence.getHasParallelSnapping)
	SpecializationUtil.registerFunction(placeableType, "registerTerrainHeightChangeCallbacks", PlaceableFence.registerTerrainHeightChangeCallbacks)
	SpecializationUtil.registerFunction(placeableType, "onTerrainDeformationSyncerUpdate", PlaceableFence.onTerrainDeformationSyncerUpdate)
end

function PlaceableFence.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableFence.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getDestructionMethod", PlaceableFence.getDestructionMethod)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "performNodeDestruction", PlaceableFence.performNodeDestruction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "previewNodeDestructionNodes", PlaceableFence.previewNodeDestructionNodes)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableFence.setOwnerFarmId)
end

function PlaceableFence.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFence)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableFence)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableFence)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableFence)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableFence)
end

function PlaceableFence.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".fence.poles#node", "Group of pole variants")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".fence.panels#node", "Group of panel variants")
	schema:register(XMLValueType.FLOAT, basePath .. ".fence.panels#length", "Length of the panels", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".fence.panels#fixedLength", "Panel length is fixed", false)
	schema:register(XMLValueType.ANGLE, basePath .. ".fence#maxVerticalAngle", "Maximum angle for vertical offset")
	schema:register(XMLValueType.ANGLE, basePath .. ".fence#maxVerticalGateAngle", "Maximum angle for vertical offset with gates")
	schema:register(XMLValueType.FLOAT, basePath .. ".fence#boundingCheckWidth", "Width of the bounding box used to check collision", 0.25)
	schema:register(XMLValueType.FLOAT, basePath .. ".fence#snapDistance", "Snap distance", nil)
	schema:register(XMLValueType.INT, basePath .. ".fence#snapAngle", "Snap angle in degrees", nil)
	schema:register(XMLValueType.FLOAT, basePath .. ".fence#snapCheckDistance", "Snap distance", nil)
	schema:register(XMLValueType.BOOL, basePath .. ".fence#extendingOnly", "Whether to only allow extending a segment and no attaching to the center", false)
	schema:register(XMLValueType.ANGLE, basePath .. ".fence#maxCornerAngle", "Maximum angle between two connected segments", 180)
	schema:register(XMLValueType.BOOL, basePath .. ".fence#supportsParallelSnapping", "Whether parallel snapping is an option", false)
	schema:register(XMLValueType.BOOL, basePath .. ".fence#hasInvisiblePoles", "Poles are not visible so another display method is used", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".fence.gate(?)#node", "Gate node")
	schema:register(XMLValueType.FLOAT, basePath .. ".fence.gate(?)#length", "Length of the gate from pole to pole", 1)
	schema:register(XMLValueType.INT, basePath .. ".fence.gate(?)#triggerNode", "Gate trigger node index from gate node")
	schema:register(XMLValueType.STRING, basePath .. ".fence.gate(?)#openText", "Action open text")
	schema:register(XMLValueType.STRING, basePath .. ".fence.gate(?)#closeText", "Action close text")
	schema:register(XMLValueType.FLOAT, basePath .. ".fence.gate(?)#openDuration", "Duration of animation in seconds")
	schema:register(XMLValueType.INT, basePath .. ".fence.gate(?).door(?)#node", "Node of the door")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".fence.gate(?).door(?)#openRotation", "Rotation of the node when fully open")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".fence.gate(?).door(?)#openTranslation", "Translation of the node when fully open")
	AnimatedObjectBuilder.registerXMLPaths(schema, basePath .. ".fence.gate(?)")
	schema:setXMLSpecializationType()
end

function PlaceableFence.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".segments.segment(?)#start", "Segment start position")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".segments.segment(?)#end", "Segment end position")
	schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#first", "Segment has first pole visible", true)
	schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#last", "Segment has last pole visible", true)
	schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#gateIndex", "Gate index")
	AnimatedObject.registerSavegameXMLPaths(schema, basePath .. ".segments.segment(?).animatedObject")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, polesNode, i, panelsNode, i
function PlaceableFence:onLoad(savegame)
	local v_u_10_ = self.spec_fence
	local v_u_11_ = self.xmlFile
	v_u_10_.pickObjects = {}
	v_u_10_.segments = {}
	v_u_10_.segmentsToUpdate = {}
	v_u_10_.animatedObjects = {}
	v_u_10_.previewSegment = nil
	v_u_10_.panelLength = v_u_11_:getValue("placeable.fence.panels#length")
	v_u_10_.panelLengthFixed = v_u_11_:getValue("placeable.fence.panels#fixedLength")
	v_u_10_.maxVerticalAngle = v_u_11_:getValue("placeable.fence#maxVerticalAngle", 35)
	v_u_10_.maxVerticalGateAngle = v_u_11_:getValue("placeable.fence#maxVerticalGateAngle", 5)
	v_u_10_.hasInvisiblePoles = v_u_11_:getValue("placeable.fence#hasInvisiblePoles", false)
	v_u_10_.supportsParallelSnapping = v_u_11_:getValue("placeable.fence#supportsParallelSnapping", false)
	v_u_10_.boundingCheckWidth = v_u_11_:getValue("placeable.fence#boundingCheckWidth", 0.25)
	v_u_10_.snapDistance = v_u_11_:getValue("placeable.fence#snapDistance", nil)
	v_u_10_.snapAngle = v_u_11_:getValue("placeable.fence#snapAngle", nil)
	v_u_10_.snapCheckDistance = v_u_11_:getValue("placeable.fence#snapCheckDistance", 0.25)
	v_u_10_.allowExtendingOnly = v_u_11_:getValue("placeable.fence#extendingOnly", false)
	v_u_10_.maxCornerAngle = v_u_11_:getValue("placeable.fence#maxCornerAngle", 180)
	v_u_10_.poles = {}
	local v12_ = v_u_11_:getValue("placeable.fence.poles#node", nil, self.components, self.i3dMappings)
	if v12_ ~= nil then
		for v13_ = 1, getNumOfChildren(v12_) do
			v_u_10_.poles[v13_] = getChildAt(v12_, v13_ - 1)
		end
	end
	v_u_10_.panels = {}
	local v14_ = v_u_11_:getValue("placeable.fence.panels#node", nil, self.components, self.i3dMappings)
	if v14_ ~= nil then
		for v15_ = 1, getNumOfChildren(v14_) do
			v_u_10_.panels[v15_] = getChildAt(v14_, v15_ - 1)
		end
	end
	v_u_10_.gates = {}
	v_u_11_:iterate("placeable.fence.gate", function(_, p16_)
		-- upvalues: (copy) v_u_11_, (copy) self, (copy) v_u_10_
		local v17_ = v_u_11_:getValue(p16_ .. "#node", nil, self.components, self.i3dMappings)
		if v17_ == nil then
			Logging.xmlWarning(v_u_11_, "Gate node does not exist at %s", p16_)
		else
			local v_u_18_ = {}
			v_u_11_:iterate(p16_ .. ".door", function(_, p19_)
				-- upvalues: (ref) v_u_11_, (copy) v_u_18_
				local v20_ = v_u_11_:getValue(p19_ .. "#node")
				if v20_ == nil then
					Logging.xmlWarning(v_u_11_, "Door node does not exist at %s", p19_)
				else
					local v21_ = v_u_18_
					local v22_ = {
						["node"] = v20_,
						["rotation"] = v_u_11_:getValue(p19_ .. "#openRotation", nil, true),
						["translation"] = v_u_11_:getValue(p19_ .. "#openTranslation", nil, true)
					}
					table.insert(v21_, v22_)
				end
			end)
			local v23_ = v_u_10_.gates
			local v24_ = {
				["node"] = v17_,
				["length"] = v_u_11_:getValue(p16_ .. "#length", 1),
				["triggerNode"] = v_u_11_:getValue(p16_ .. "#triggerNode"),
				["openText"] = v_u_11_:getValue(p16_ .. "#openText", "action_openGate"),
				["closeText"] = v_u_11_:getValue(p16_ .. "#closeText", "action_closeGate"),
				["animationDuration"] = v_u_11_:getValue(p16_ .. "#openDuration", 3),
				["doors"] = v_u_18_
			}
			table.insert(v23_, v24_)
		end
	end)
end

-- Local values: spec, _, segment, terrainDeformationSyncer, cellId, cellX, cellZ, _, animatedObject
function PlaceableFence:onDelete()
	local v26_ = self.spec_fence
	if v26_.segments ~= nil then
		for _, v27_ in pairs(v26_.segments) do
			if v27_.pendingUpdateTimer ~= nil then
				v27_.pendingUpdateTimer:delete()
				v27_.pendingUpdateTimer = nil
			end
		end
	end
	if self.cellIdToSegments ~= nil then
		local v28_ = g_currentMission.terrainDeformationSyncer
		if v28_ ~= nil then
			for v29_ in pairs(self.cellIdToSegments) do
				local v30_, v31_ = v28_:getCellIndicesById(v29_)
				v28_:removeCellUpdateListener(self, v30_, v31_)
			end
		end
		self.cellIdToSegments = nil
	end
	if v26_.animatedObjects ~= nil then
		for _, v32_ in ipairs(v26_.animatedObjects) do
			v32_:delete()
		end
	end
end

-- Local values: spec, numSegments, i, segment, i, segment, animatedObject, animatedObjectId
function PlaceableFence:onReadStream(streamId, connection)
	local v36_ = self.spec_fence
	local v37_ = streamReadInt32(streamId)
	for _ = 1, v37_ do
		local v38_ = {
			["x1"] = streamReadFloat32(streamId),
			["z1"] = streamReadFloat32(streamId),
			["x2"] = streamReadFloat32(streamId),
			["z2"] = streamReadFloat32(streamId),
			["gateIndex"] = streamReadUInt8(streamId)
		}
		if v38_.gateIndex == 0 then
			v38_.gateIndex = nil
		end
		v38_.renderFirst = streamReadBool(streamId)
		v38_.renderLast = streamReadBool(streamId)
		v38_.poles = {}
		local v39_ = v36_.segments
		table.insert(v39_, v38_)
	end
	for v40_ = 1, v37_ do
		local v41_ = v36_.segments[v40_]
		self:generateSegmentPoles(v41_, true)
		if v41_.gateIndex ~= nil and v41_.animatedObject ~= nil then
			local v42_ = v41_.animatedObject
			local v43_ = NetworkUtil.readNodeObjectId(streamId)
			v42_:readStream(streamId, connection)
			g_client:finishRegisterObject(v42_, v43_)
		end
		self:registerTerrainHeightChangeCallbacks(v41_)
	end
end

-- Local values: spec, numSegments, i, segment, i, segment, animatedObject
function PlaceableFence:onWriteStream(streamId, connection)
	local v47_ = self.spec_fence
	local v48_ = #v47_.segments
	streamWriteInt32(streamId, v48_)
	for v49_ = 1, v48_ do
		local v50_ = v47_.segments[v49_]
		streamWriteFloat32(streamId, v50_.x1)
		streamWriteFloat32(streamId, v50_.z1)
		streamWriteFloat32(streamId, v50_.x2)
		streamWriteFloat32(streamId, v50_.z2)
		streamWriteUInt8(streamId, v50_.gateIndex or 0)
		streamWriteBool(streamId, v50_.renderFirst)
		streamWriteBool(streamId, v50_.renderLast)
	end
	for v51_ = 1, v48_ do
		local v52_ = v47_.segments[v51_]
		if v52_.gateIndex ~= nil and v52_.animatedObject ~= nil then
			local v53_ = v52_.animatedObject
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v53_))
			v53_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v53_)
		end
	end
end

function PlaceableFence:onUpdate(dt)
	self:updateSegmentUpdateQueue()
end

-- Local values: spec, _, animatedObject
function PlaceableFence:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	local v59_ = self.spec_fence
	superFunc(self, ownerFarmId, noEventSend)
	if v59_.animatedObjects ~= nil then
		for _, v60_ in ipairs(v59_.animatedObjects) do
			v60_:setOwnerFarmId(ownerFarmId, true)
		end
	end
end

-- Local values: spec, i, segment
function PlaceableFence:loadFromXMLFile(xmlFile, key)
	local v_u_64_ = self.spec_fence
	xmlFile:iterate(key .. ".segments.segment", function(_, p65_)
		-- upvalues: (copy) xmlFile, (copy) v_u_64_
		local v66_, v67_ = xmlFile:getValue(p65_ .. "#start")
		local v68_, v69_ = xmlFile:getValue(p65_ .. "#end")
		if v66_ == nil or (v67_ == nil or (v68_ == nil or v69_ == nil)) then
			Logging.xmlError(xmlFile, "Invalid segment position for \'%s\'. Ignoring segment!", p65_)
		else
			local v70_ = {
				["x1"] = v66_,
				["z1"] = v67_,
				["x2"] = v68_,
				["z2"] = v69_,
				["renderFirst"] = xmlFile:getValue(p65_ .. "#first", true),
				["renderLast"] = xmlFile:getValue(p65_ .. "#last", true),
				["gateIndex"] = xmlFile:getValue(p65_ .. "#gateIndex"),
				["poles"] = {},
				["segmentKey"] = p65_
			}
			local v71_ = v_u_64_.segments
			table.insert(v71_, v70_)
		end
	end)
	for v72_ = 1, #v_u_64_.segments do
		local v73_ = v_u_64_.segments[v72_]
		self:generateSegmentPoles(v73_, true)
		if v73_.gateIndex ~= nil and v73_.animatedObject ~= nil then
			v73_.animatedObject:loadFromXMLFile(xmlFile, v73_.segmentKey .. ".animatedObject")
		end
		v73_.segmentKey = nil
	end
end

-- Local values: spec
function PlaceableFence:saveToXMLFile(xmlFile, key, usedModNames)
	local v78_ = self.spec_fence
	xmlFile:setTable(key .. ".segments.segment", v78_.segments, function(p79_, p80_, _)
		-- upvalues: (copy) xmlFile, (copy) usedModNames
		xmlFile:setValue(p79_ .. "#start", p80_.x1, p80_.z1)
		xmlFile:setValue(p79_ .. "#end", p80_.x2, p80_.z2)
		if p80_.gateIndex ~= nil then
			xmlFile:setValue(p79_ .. "#gateIndex", p80_.gateIndex)
			if p80_.animatedObject ~= nil then
				p80_.animatedObject:saveToXMLFile(xmlFile, p79_ .. ".animatedObject", usedModNames)
			end
		end
		if not p80_.renderFirst then
			xmlFile:setValue(p79_ .. "#first", false)
		end
		if not p80_.renderLast then
			xmlFile:setValue(p79_ .. "#last", false)
		end
	end)
end

-- Local values: startPosX, startPosZ, dirX, dirZ, length, terrainDeformationSyncer, offset, stepSize, x, z, cellX, cellZ, cellId
function PlaceableFence:registerTerrainHeightChangeCallbacks(segment)
	if self.isServer or not g_currentMission.missionDynamicInfo.isMultiplayer then
		return
	end
	local v83_ = segment.x1
	local v84_ = segment.z1
	local v85_ = segment.x2 - v83_
	local v86_ = segment.z2 - v84_
	local v87_ = MathUtil.vector2Length(v85_, v86_)
	local v88_, v89_ = MathUtil.vector2Normalize(v85_, v86_)
	local v90_ = g_currentMission.terrainDeformationSyncer
	local v91_ = 0
	while true do
		local v92_, v93_ = v90_:getCellIndicesAtWorldPosition(v83_ + v88_ * v91_, v84_ + v89_ * v91_)
		if v92_ ~= nil then
			local v94_ = v90_:getCellId(v92_, v93_)
			if self.cellIdToSegments == nil then
				self.cellIdToSegments = {}
			end
			if self.cellIdToSegments[v94_] == nil then
				self.cellIdToSegments[v94_] = {}
				v90_:addCellUpdateListener(self, v92_, v93_)
			end
			self.cellIdToSegments[v94_][segment] = true
		end
		if v87_ <= v91_ then
			return
		end
		local v95_ = v91_ + 0.5
		v91_ = math.min(v95_, v87_)
	end
end

-- Local values: segments, segment, _
function PlaceableFence:onTerrainDeformationSyncerUpdate(cellX, cellZ, cellId)
	if self.cellIdToSegments == nil then
		return
	else
		local v98_ = self.cellIdToSegments[cellId]
		if v98_ ~= nil then
			for v_u_99_, _ in pairs(v98_) do
				if v_u_99_.pendingUpdateTimer == nil then
					v_u_99_.pendingUpdateTimer = Timer.new(5000)
					v_u_99_.pendingUpdateTimer:setFinishCallback(function()
						-- upvalues: (copy) self, (copy) v_u_99_
						self:addSegmentShapesToUpdate(v_u_99_)
						v_u_99_.pendingUpdateTimer = nil
					end)
					v_u_99_.pendingUpdateTimer:start()
				end
			end
		end
	end
end

-- Local values: spec, pole_x, pole_y, pole_z
function PlaceableFence:getPoleNear(x, y, z, maxDistance)
	local v105_ = self.spec_fence
	v105_.getPoleNearResult = nil
	v105_.getPoleNearResultSegment = nil
	v105_.getPoleNearResultDistance = math.huge
	v105_.getPoleNearResultPosition = { x, y, z }
	overlapSphere(x, y, z, maxDistance, "getPoleNearOverlapCallback", self, CollisionFlag.STATIC_OBJECT, false, false, true, true)
	if v105_.getPoleNearResult == nil then
		return nil
	end
	local v106_, v107_, v108_ = getWorldTranslation(v105_.getPoleNearResult)
	return v106_, v107_, v108_, v105_.getPoleNearResult, v105_.getPoleNearResultSegment
end

-- Local values: sGroup, spec, x, y, z, distance, _, segment
function PlaceableFence:getPoleNearOverlapCallback(hitObjectId)
	if hitObjectId ~= 0 and hitObjectId ~= g_terrainNode then
		local v111_ = getParent(getParent(hitObjectId))
		local v112_ = self.spec_fence
		local v113_, v114_, v115_ = getWorldTranslation(hitObjectId)
		local v116_ = MathUtil.vector3Length(v113_ - v112_.getPoleNearResultPosition[1], v114_ - v112_.getPoleNearResultPosition[2], v115_ - v112_.getPoleNearResultPosition[3])
		if v116_ < v112_.getPoleNearResultDistance then
			for _, v117_ in ipairs(v112_.segments) do
				if v117_.group == v111_ and getNumOfChildren(hitObjectId) < 3 then
					v112_.getPoleNearResult = hitObjectId
					v112_.getPoleNearResultSegment = v117_
					v112_.getPoleNearResultDistance = v116_
				end
			end
		end
		return true
	end
end

-- Local values: spec, collision, item, parent, parent2, i, segment, x, y, z, x, y, z
function PlaceableFence:getPolePosition(node, allowPanel)
	local v121_ = self.spec_fence
	local v122_ = getParent(node)
	local v123_ = getParent(v122_)
	local v124_
	if allowPanel and v123_ ~= getRootNode() then
		v124_ = getParent(v123_)
	else
		v124_ = nil
	end
	for v125_ = 1, #v121_.segments do
		local v126_ = v121_.segments[v125_]
		if v123_ == v126_.group then
			local v127_, v128_, v129_ = getWorldTranslation(v122_)
			return v127_, v128_, v129_, v126_
		end
		if v124_ == v126_.group then
			local v130_, v131_, v132_ = getWorldTranslation(v123_)
			return v130_, v131_, v132_, v126_
		end
	end
	return nil
end

-- Local values: spec, pole
function PlaceableFence:getPoleShapeForPreview()
	local v134_ = self.spec_fence
	if v134_.hasInvisiblePoles then
		return nil
	elseif #v134_.poles > 0 then
		if getNumOfChildren(v134_.poles[1]) == 0 then
			return nil
		else
			local v135_ = clone(v134_.poles[1], false, false, false)
			if v135_ == 0 then
				return nil
			else
				return v135_
			end
		end
	else
		return nil
	end
end

-- Local values: spec, segment, maxAngle, minY, maxY, i, x1, z1, x2, z2, horizontalDifference, y1, y2, heightDifference, angle
function PlaceableFence:getMaxVerticalAngleAndYForPreview()
	local v137_ = self.spec_fence.previewSegment
	local v138_ = 1000
	local v139_ = -1000
	local v140_ = 0
	for v141_ = 1, #v137_.poles - 2, 2 do
		local v142_ = v137_.poles[v141_]
		local v143_ = v137_.poles[v141_ + 1]
		local v144_ = v137_.poles[v141_ + 2]
		local v145_ = v137_.poles[v141_ + 3]
		local v146_ = MathUtil.getPointPointDistance(v142_, v143_, v144_, v145_)
		local v147_ = getTerrainHeightAtWorldPos(g_terrainNode, v142_, 0, v143_)
		local v148_ = getTerrainHeightAtWorldPos(g_terrainNode, v144_, 0, v145_)
		local v149_ = v147_ - v148_
		local v150_ = math.abs(v149_)
		v138_ = math.min(v138_, v147_, v148_)
		v139_ = math.max(v139_, v147_, v148_)
		if v146_ > 0 then
			local v151_ = v150_ / v146_
			local v152_ = math.atan(v151_)
			if v140_ < v152_ then
				v140_ = v152_
			end
		end
	end
	return v140_, v138_, v139_
end

function PlaceableFence:getSegmentLength(segment)
	return MathUtil.getPointPointDistance(segment.x1, segment.z1, segment.x2, segment.z2)
end

function PlaceableFence:getPanelLength()
	return self.spec_fence.panelLength
end

function PlaceableFence:getIsPanelLengthFixed()
	return self.spec_fence.panelLengthFixed
end

function PlaceableFence:createSegment(x1, z1, x2, z2, renderFirst, gateIndex)
	return {
		["x1"] = x1,
		["z1"] = z1,
		["x2"] = x2,
		["z2"] = z2,
		["renderFirst"] = renderFirst,
		["renderLast"] = true,
		["gateIndex"] = gateIndex,
		["poles"] = {}
	}
end

-- Local values: spec
function PlaceableFence:addSegment(segment, sync)
	local v165_ = self.spec_fence
	v165_.segments[#v165_.segments + 1] = segment
	self:generateSegmentPoles(segment, sync)
end

-- Local values: spec, terrainDeformationSyncer, cellId, segments, cellX, cellZ
function PlaceableFence:deleteSegment(segment)
	local v168_ = self.spec_fence
	if segment.animatedObject ~= nil then
		segment.animatedObject:delete()
		segment.animatedObject = nil
	end
	if segment.group ~= nil then
		delete(segment.group)
		segment.group = nil
	end
	if segment.pendingUpdateTimer ~= nil then
		segment.pendingUpdateTimer:delete()
		segment.pendingUpdateTimer = nil
	end
	if self.cellIdToSegments ~= nil then
		local v169_ = g_currentMission.terrainDeformationSyncer
		for v170_, v171_ in pairs(self.cellIdToSegments) do
			v171_[segment] = nil
			if next(v171_) == nil then
				self.cellIdToSegments[v170_] = nil
				local v172_, v173_ = v169_:getCellIndicesById(v170_)
				v169_:removeCellUpdateListener(self, v172_, v173_)
			end
		end
	end
	table.removeElement(v168_.segments, segment)
	self:updateDirtyAreas(segment.x1, segment.z1, segment.x2, segment.z2)
end

-- Local values: minX, maxX, minZ, maxZ
function PlaceableFence:updateDirtyAreas(x1, z1, x2, z2)
	local v178_ = math.min(x1, x2)
	local v179_ = math.max(x1, x2)
	local v180_ = math.min(z1, z2)
	local v181_ = math.max(z1, z2)
	g_densityMapHeightManager:setCollisionMapAreaDirty(v178_, v180_, v179_, v181_, true)
	g_currentMission.aiSystem:setAreaDirty(v178_, v179_, v180_, v181_)
end

-- Local values: spec
function PlaceableFence:setPreviewSegment(segment)
	local v184_ = self.spec_fence
	if v184_.previewSegment ~= nil and (v184_.previewSegment.group ~= nil and segment ~= v184_.previewSegment) then
		delete(v184_.previewSegment.group)
		v184_.previewSegment.group = nil
	end
	v184_.previewSegment = segment
	if segment ~= nil then
		self:generateSegmentPoles(segment, false)
	end
end

-- Local values: spec
function PlaceableFence:getPreviewSegment()
	return self.spec_fence.previewSegment
end

-- Local values: spec
function PlaceableFence:getGate(index)
	return self.spec_fence.gates[index]
end

-- Local values: spec
function PlaceableFence:getSegment(index)
	return self.spec_fence.segments[index]
end

-- Local values: spec
function PlaceableFence:getNumSequments()
	return #self.spec_fence.segments
end

-- Local values: spec
function PlaceableFence:getMaxVerticalAngle()
	return self.spec_fence.maxVerticalAngle
end

-- Local values: spec
function PlaceableFence:getMaxVerticalGateAngle()
	return self.spec_fence.maxVerticalGateAngle
end

function PlaceableFence:getBoundingCheckWidth()
	return self.spec_fence.boundingCheckWidth
end

function PlaceableFence:getSnapDistance()
	return self.spec_fence.snapDistance
end

function PlaceableFence:getSnapAngle()
	return self.spec_fence.snapAngle
end

function PlaceableFence:getSnapCheckDistance()
	return self.spec_fence.snapCheckDistance
end

function PlaceableFence:getAllowExtendingOnly()
	return self.spec_fence.allowExtendingOnly
end

function PlaceableFence:getMaxCornerAngle()
	return self.spec_fence.maxCornerAngle
end

function PlaceableFence.getHasParallelSnapping(self)
	return false
end

function PlaceableFence:getSupportsParallelSnapping()
	return self.spec_fence.supportsParallelSnapping
end

-- Local values: spec, panel, _, segment, _, poleIndex, segmentIndex, i
function PlaceableFence:deletePanel(node)
	if node == nil or (node == 0 or getCollisionFilterMask(node) == 0) then
		return
	end
	local v202_ = self.spec_fence
	local v203_, _, v204_, _, v205_ = self:findRaycastInfo(node)
	if v203_ == nil then
		return nil
	end
	local v206_ = 1
	for v207_ = 1, #v202_.segments do
		if v202_.segments[v207_] == v204_ then
			v206_ = v207_
			break
		end
	end
	if self.isServer then
		self:doDeletePanel(v204_, v206_, v205_)
		g_server:broadcastEvent(PlaceableFenceRemoveSegmentEvent.new(self, v206_, v205_), false)
	else
		setCollisionFilterMask(node, 0)
		g_client:getServerConnection():sendEvent(PlaceableFenceRemoveSegmentEvent.new(self, v206_, v205_))
	end
	return true
end

-- Local values: terrainDeformationSyncer, cellId, segments, cellX, cellZ, deletedPoles, x1OrigSeg, x2OrigSeg, z1OrigSeg, z2OrigSeg, segmentSizeChanged, newSegment, i, x, z, neighborSegment, isStart
function PlaceableFence:doDeletePanel(segment, segmentIndex, poleIndex)
	if segment ~= nil and #segment.poles >= poleIndex then
		if segment.pendingUpdateTimer ~= nil then
			segment.pendingUpdateTimer:delete()
			segment.pendingUpdateTimer = nil
		end
		if self.cellIdToSegments ~= nil then
			local v211_ = g_currentMission.terrainDeformationSyncer
			for v212_, v213_ in pairs(self.cellIdToSegments) do
				v213_[segment] = nil
				if next(v213_) == nil then
					self.cellIdToSegments[v212_] = nil
					local v214_, v215_ = v211_:getCellIndicesById(v212_)
					v211_:removeCellUpdateListener(self, v214_, v215_)
				end
			end
		end
		local v216_ = {}
		local v217_ = segment.x1
		local v218_ = segment.x2
		local v219_ = segment.z1
		local v220_ = segment.z2
		local v221_ = false
		if poleIndex == 1 then
			if segment.renderFirst then
				v216_[#v216_ + 1] = segment.poles[1]
				v216_[#v216_ + 1] = segment.poles[2]
			end
			if poleIndex + 2 == #segment.poles - 1 then
				if segment.renderLast then
					v216_[#v216_ + 1] = segment.poles[3]
					v216_[#v216_ + 1] = segment.poles[4]
				end
				self:removePickingNodesForSegment(segment)
				self:deleteSegment(segment)
			else
				segment.x1 = segment.poles[3]
				segment.z1 = segment.poles[4]
				segment.renderFirst = true
				v221_ = true
			end
		elseif poleIndex + 2 == #segment.poles - 1 then
			if segment.renderLast then
				v216_[#v216_ + 1] = segment.poles[#segment.poles - 1]
				v216_[#v216_ + 1] = segment.poles[#segment.poles]
			end
			segment.x2 = segment.poles[#segment.poles - 3]
			segment.z2 = segment.poles[#segment.poles - 2]
			segment.renderLast = true
			v221_ = true
		else
			local v222_ = self:createSegment(segment.poles[poleIndex + 2], segment.poles[poleIndex + 3], segment.x2, segment.z2, true, nil)
			v222_.renderLast = segment.renderLast
			v222_.renderFirst = true
			segment.x2 = segment.poles[poleIndex]
			segment.z2 = segment.poles[poleIndex + 1]
			segment.renderLast = true
			self:addSegment(v222_)
			self:registerTerrainHeightChangeCallbacks(v222_)
			v221_ = true
		end
		if v221_ then
			self:generateSegmentPoles(segment, true)
			self:registerTerrainHeightChangeCallbacks(segment)
		end
		for v223_ = 1, #v216_, 2 do
			local v224_, v225_ = self:isPoleInAnySegment(v216_[v223_], v216_[v223_ + 1], segment)
			if v224_ ~= nil then
				if v225_ then
					v224_.renderFirst = true
				else
					v224_.renderLast = true
				end
				self:generateSegmentPoles(v224_, true)
			end
		end
		self:updateDirtyAreas(v217_, v219_, v218_, v220_)
		return true
	end
end

-- Local values: spec, collision, panel, panelVisuals, segment, pole, sGroup, si, seg, si, seg, poleIndex, poleIndex
function PlaceableFence:findRaycastInfo(node)
	local v228_ = self.spec_fence
	local v229_ = getParent(node)
	local v230_ = getChildAt(v229_, 1)
	local v231_ = getParent(v229_)
	local v232_ = getParent(v231_)
	local v233_ = nil
	for v234_ = 1, #v228_.segments do
		local v235_ = v228_.segments[v234_]
		if v235_.group == v232_ then
			v233_ = v235_
			break
		end
		if v235_.group == v231_ and v235_.gateIndex ~= nil then
			local v236_ = getChildAt(v231_, getNumOfChildren(v231_) - 1)
			v230_ = getChildAt(v236_, 1)
			v231_ = v229_
			v229_ = v236_
			v233_ = v235_
			break
		end
	end
	if v233_ ~= nil then
		return v229_, v230_, v233_, v231_, v233_.gateIndex ~= nil and 1 or getChildIndex(v231_) * 2 + 1
	end
	local v237_ = getParent(node)
	local v238_ = getParent(v237_)
	for v239_ = 1, #v228_.segments do
		local v240_ = v228_.segments[v239_]
		if v240_.group == v238_ then
			v233_ = v240_
			break
		end
	end
	if v233_ == nil then
		return nil
	else
		return nil, nil, v233_, v237_, getChildIndex(v237_) * 2 + 1
	end
end

-- Local values: spec, panel, panelVisuals, segment, pole, poleIndex, nodes, gateInfo, _, door, doorNode, addPole, poleNode, x, z, visualPole, poleNode, x, z, visualPole
function PlaceableFence:getNodesToDeleteForPanel(node)
	local v243_ = self.spec_fence
	local v244_, v245_, v246_, v247_, v248_ = self:findRaycastInfo(node)
	if v244_ == nil or node == 0 then
		return nil
	end
	local v249_ = {}
	if v246_.gateIndex == nil then
		v249_[1] = v245_
	else
		local v250_ = v243_.gates[v246_.gateIndex]
		for _, v251_ in ipairs(v250_.doors) do
			local v252_ = getChildAt(v244_, v251_.node)
			v249_[#v249_ + 1] = getChildAt(v252_, 0)
		end
	end
	if v248_ == 1 and (v246_.renderFirst and self:isPoleInAnySegment(v246_.poles[1], v246_.poles[2], v246_) == nil) then
		local v253_ = getChildAt(v247_, 1)
		if v253_ ~= 0 then
			table.insert(v249_, v253_)
		end
	end
	if v248_ + 2 == #v246_.poles - 1 and v246_.renderLast then
		local v254_ = getChildAt(v246_.group, #v246_.poles / 2 - 1)
		if self:isPoleInAnySegment(v246_.poles[#v246_.poles - 1], v246_.poles[#v246_.poles], v246_) == nil then
			local v255_ = getChildAt(v254_, 1)
			if v255_ ~= 0 then
				table.insert(v249_, v255_)
			end
		end
	end
	return v249_
end

-- Local values: spec, i, segment
function PlaceableFence:isPoleInAnySegment(x, z, ignoreSegment)
	local v260_ = self.spec_fence
	for v261_ = 1, #v260_.segments do
		local v262_ = v260_.segments[v261_]
		if v262_ ~= ignoreSegment then
			local v263_ = v262_.x1 - x
			if math.abs(v263_) < PlaceableFence.EPSILON then
				local v264_ = v262_.z1 - z
				if math.abs(v264_) < PlaceableFence.EPSILON then
					return v262_, true, false
				end
			end
			local v265_ = v262_.x2 - x
			if math.abs(v265_) < PlaceableFence.EPSILON then
				local v266_ = v262_.z2 - z
				if math.abs(v266_) < PlaceableFence.EPSILON then
					return v262_, false, true
				end
			end
		end
	end
	return nil
end

-- Local values: alpha
function PlaceableFence:fakeRandomValueForPosition(x, y, z, n)
	local v270_ = (x * 0.13 + z * 0.23) % 1
	if n == nil then
		return v270_
	end
	local v271_ = v270_ * (n - 1) + 0.5
	return math.floor(v271_) + 1
end

-- Local values: spec, totalDistance, numWholeFences, i, nextPole, j, alpha, restDistance, numRestFences, restFenceSize, j, alpha
function PlaceableFence:generateSegmentPoles(segment, sync)
	local v275_ = self.spec_fence
	local v276_ = MathUtil.getPointPointDistance(segment.x1, segment.z1, segment.x2, segment.z2)
	local v277_ = v276_ / v275_.panelLength
	local v278_ = math.floor(v277_) - 1
	local v279_ = math.max(v278_, 0)
	for v280_ = 1, #segment.poles do
		segment.poles[v280_] = nil
	end
	if v276_ >= 0.01 then
		if segment.gateIndex == nil then
			local v281_ = 1
			for v282_ = 0, v279_ do
				local v283_ = v275_.panelLength * v282_ / v276_
				segment.poles[v281_] = MathUtil.lerp(segment.x1, segment.x2, v283_)
				segment.poles[v281_ + 1] = MathUtil.lerp(segment.z1, segment.z2, v283_)
				v281_ = v281_ + 2
			end
			local v284_ = v276_ - v279_ * v275_.panelLength
			local v285_ = v284_ <= v275_.panelLength * 1.2 and 1 or 2
			local v286_ = v284_ / v285_
			for v287_ = 0, v285_ - 1 do
				local v288_ = (v279_ * v275_.panelLength + (v287_ + 1) * v286_) / v276_
				segment.poles[v281_] = MathUtil.lerp(segment.x1, segment.x2, v288_)
				segment.poles[v281_ + 1] = MathUtil.lerp(segment.z1, segment.z2, v288_)
				v281_ = v281_ + 2
			end
		else
			segment.poles[1] = segment.x1
			segment.poles[2] = segment.z1
			segment.poles[3] = segment.x2
			segment.poles[4] = segment.z2
		end
		if sync then
			self:removePickingNodesForSegment(segment)
			self:updateSegmentShapes(segment)
			self:addPickingNodesForSegment(segment)
		else
			self:addSegmentShapesToUpdate(segment)
		end
		if v275_.previewSegment ~= segment then
			self:updateDirtyAreas(segment.x1, segment.z1, segment.x2, segment.z2)
		end
	end
end

-- Local values: spec, isPreviewSegment, enablePhysics, gateTime, i, x, z, y, pole, poleIsFake, poleIndex, prevX, prevZ, dx, dz, rotY, nextX, nextZ, nextY, dx, dy, dz, rotY, panelIndex, panel, fenceLength, col, xDir, yDir, zDir, length, offset, colX, colY, colZ, prevX, prevZ, dx, dz, rotY, gateInfo, gate, segmentTerrainY, dx, dz, rotY, animatedObject, saveId, builder, _, door, doorNode, triggerNode, i, _, door, doorNode, alpha, x1, y1, z1, x2, y2, z2, x1, y1, z1, x2, y2, z2
function PlaceableFence:updateSegmentShapes(segment)
	local v291_ = self.spec_fence
	local v292_ = segment == v291_.previewSegment
	local v293_ = not v292_
	local v294_
	if segment.animatedObject == nil then
		v294_ = nil
	else
		v294_ = segment.animatedObject.animation.time
		segment.animatedObject:delete()
		segment.animatedObject = nil
	end
	if segment.group ~= nil then
		delete(segment.group)
	end
	segment.group = createTransformGroup("fence_segment")
	link(self.rootNode, segment.group)
	for v295_ = 1, #segment.poles, 2 do
		local v296_ = segment.poles[v295_]
		local v297_ = segment.poles[v295_ + 1]
		local v298_ = getTerrainHeightAtWorldPos(g_terrainNode, v296_, 0, v297_)
		local v299_ = false
		local v300_
		if #v291_.poles > 0 and (v295_ > 1 or segment.renderFirst) and (v295_ < #segment.poles - 2 or segment.renderLast) then
			local v301_ = self:fakeRandomValueForPosition(v296_, v298_, v297_, #v291_.poles)
			v300_ = clone(v291_.poles[v301_], false, false, false)
		else
			v300_ = createTransformGroup("fence_firstPole")
			v299_ = true
		end
		link(segment.group, v300_)
		setWorldTranslation(v300_, v296_, v298_, v297_)
		if segment.gateIndex == nil then
			if v295_ < #segment.poles - 2 then
				local v302_ = segment.poles[v295_ + 2]
				local v303_ = segment.poles[v295_ + 3]
				local v304_ = getTerrainHeightAtWorldPos(g_terrainNode, v302_, 0, v303_)
				local v305_ = v296_ - v302_
				local v306_ = v298_ - v304_
				local v307_ = v297_ - v303_
				local v308_ = math.atan2(v305_, v307_) + 3.141592653589793
				setWorldRotation(v300_, 0, v308_, 0)
				local v309_ = self:fakeRandomValueForPosition(v296_, v298_, v297_, #v291_.panels)
				local v310_ = clone(v291_.panels[v309_], false, false, false)
				link(v300_, v310_)
				local v311_ = MathUtil.getPointPointDistance(v296_, v297_, v302_, v303_)
				self:updatePanelVisuals(v310_, v306_, segment, v295_, v311_)
				local v312_ = getChildAt(v310_, 0)
				local v313_ = -v306_
				local v314_, v315_, v316_ = MathUtil.vector3Normalize(0, v313_, v311_)
				local v317_ = v305_ * v305_ + v306_ * v306_ + v307_ * v307_
				local v318_ = (math.sqrt(v317_) - v311_) * 0.5
				local v319_, v320_, v321_ = getTranslation(v312_)
				local v322_ = v319_ + v314_ * v318_
				local v323_ = v320_ + v315_ * v318_
				local v324_ = v321_ + v316_ * v318_
				setDirection(v312_, v314_, v315_, v316_, 0, 1, 0)
				setTranslation(v312_, v322_, v323_, v324_)
				if v293_ then
					addToPhysics(v312_)
				end
				SpecializationUtil.raiseEvent(self, "onCreateSegmentPanel", v292_, segment, v310_, v295_, v306_)
				if v293_ and not v299_ then
					addToPhysics(getChildAt(v300_, 0))
				end
			elseif segment.renderLast and v295_ > 2 then
				local v325_ = segment.poles[v295_ - 2]
				local v326_ = segment.poles[v295_ - 1]
				local v327_ = v296_ - v325_
				local v328_ = v297_ - v326_
				local v329_ = math.atan2(v327_, v328_) + 3.141592653589793
				setWorldRotation(v300_, 0, v329_, 0)
				if v293_ and not v299_ then
					addToPhysics(getChildAt(v300_, 0))
				end
			end
		else
			local v330_ = segment.poles[(v295_ + 2) % 4]
			local v331_ = segment.poles[(v295_ + 2) % 4 + 1]
			local v332_ = v296_ - v330_
			local v333_ = v297_ - v331_
			local v334_ = math.atan2(v332_, v333_) + 3.141592653589793
			setWorldRotation(v300_, 0, v334_, 0)
			if v293_ and not v299_ then
				addToPhysics(getChildAt(v300_, 0))
			end
		end
	end
	if segment.gateIndex ~= nil then
		local v335_ = v291_.gates[segment.gateIndex]
		local v336_ = clone(v335_.node, false, false, false)
		link(segment.group, v336_)
		local v337_ = getTerrainHeightAtWorldPos(g_terrainNode, segment.x1, 0, segment.z1)
		setWorldTranslation(v336_, segment.x1, v337_, segment.z1)
		local v338_ = segment.x1 - segment.x2
		local v339_ = segment.z1 - segment.z2
		local v340_ = math.atan2(v338_, v339_) + 3.141592653589793
		setWorldRotation(v336_, 0, v340_, 0)
		if v292_ then
			for _, v341_ in ipairs(v335_.doors) do
				local v342_ = getChildAt(v336_, v341_.node)
				if v341_.translation ~= nil then
					local v343_, v344_, v345_ = getTranslation(v342_)
					local v346_ = v341_.translation
					local v347_, v348_, v349_ = unpack(v346_)
					setTranslation(v342_, v343_ + (v347_ - v343_) * 0.3, v344_ + (v348_ - v344_) * 0.3, v345_ + (v349_ - v345_) * 0.3)
				end
				if v341_.rotation ~= nil then
					local v350_, v351_, v352_ = getRotation(v342_)
					local v353_ = v341_.rotation
					local v354_, v355_, v356_ = unpack(v353_)
					setRotation(v342_, v350_ + (v354_ - v350_) * 0.3, v351_ + (v355_ - v351_) * 0.3, v352_ + (v356_ - v352_) * 0.3)
				end
			end
		else
			local v357_ = AnimatedObject.new(self.isServer, self.isClient)
			v357_:setOwnerFarmId(self:getOwnerFarmId(), false)
			local v358_ = string.format("AnimatedObject_%s_gate_%d_%d_%d_%d", self.configFileName, segment.x1, segment.z1, segment.x2, segment.x2)
			local v359_ = v357_:builder(self.configFileName, v358_)
			for _, v360_ in ipairs(v335_.doors) do
				local v361_ = getChildAt(v336_, v360_.node)
				v359_:addSimplePart(v361_, v360_.rotation, v360_.translation)
				addToPhysics(v361_)
			end
			local v362_ = getChildAt(v336_, v335_.triggerNode)
			v359_:setTrigger(v362_)
			addToPhysics(v362_)
			v359_:setActions("ACTIVATE_HANDTOOL", v335_.openText, nil, v335_.closeText)
			v359_:setDuration(v335_.animationDuration * 1000)
			if self.xmlFile == nil then
				self.xmlFile = XMLFile.load("placeableFence", self.configFileName)
			end
			v359_:setSounds(self.xmlFile.handle, string.format("placeable.fence.gate(%d).sounds", segment.gateIndex - 1), v336_)
			if not v359_:build() then
				v357_:delete()
				return
			end
			v357_:register(true)
			local v363_ = v291_.animatedObjects
			table.insert(v363_, v357_)
			segment.animatedObject = v357_
			if v294_ ~= nil then
				v357_:setAnimTime(v294_, true)
			end
			if self.isServer then
				for v364_ = 1, #v291_.segments do
					if v291_.segments[v364_] == segment then
						g_server:broadcastEvent(PlaceableFenceAddGateEvent.new(self, v364_, v357_), false, nil, self)
						return
					end
				end
				return
			end
		end
	end
end

-- Local values: spec
function PlaceableFence:updatePanelVisuals(panelNode, dy, segment, polesIndex, length)
	local v369_ = self.spec_fence
	if length ~= v369_.panelLength then
		setScale(panelNode, 1, 1, length / v369_.panelLength)
	end
	setShaderParameterRecursive(getChildAt(panelNode, 1), "yOffset", -dy, nil, nil, nil, false, nil)
end

-- Local values: spec
function PlaceableFence:addSegmentShapesToUpdate(segment)
	local v372_ = self.spec_fence
	v372_.segmentsToUpdate[#v372_.segmentsToUpdate + 1] = segment
	self:raiseActive()
end

-- Local values: spec, segment
function PlaceableFence:updateSegmentUpdateQueue()
	local v374_ = self.spec_fence
	if #v374_.segmentsToUpdate > 0 then
		local v375_ = v374_.segmentsToUpdate[1]
		table.remove(v374_.segmentsToUpdate, 1)
		self:removePickingNodesForSegment(v375_)
		self:updateSegmentShapes(v375_)
		self:addPickingNodesForSegment(v375_)
		self:raiseActive()
	end
end

-- Local values: objects, i
function PlaceableFence:addPickingNodesForSegment(segment)
	if segment ~= self.spec_fence.previewSegment then
		if segment.group ~= nil then
			local v378_ = {}
			self:recursivelyAddPickingNodes(v378_, segment.group)
			for v379_ = 1, #v378_ do
				g_currentMission:addNodeObject(v378_[v379_], self)
			end
		end
		self.overlayColorNodes = nil
	end
end

-- Local values: objects, i
function PlaceableFence:removePickingNodesForSegment(segment)
	if segment ~= self.spec_fence.previewSegment then
		if segment.group ~= nil then
			local v382_ = {}
			self:recursivelyAddPickingNodes(v382_, segment.group)
			for v383_ = 1, #v382_ do
				g_currentMission:removeNodeObject(v382_[v383_])
			end
		end
	end
end

-- Local values: numChildren, i
function PlaceableFence:recursivelyAddPickingNodes(objects, node)
	if getRigidBodyType(node) ~= RigidBodyType.NONE then
		table.insert(objects, node)
	end
	for v387_ = 1, getNumOfChildren(node) do
		self:recursivelyAddPickingNodes(objects, getChildAt(node, v387_ - 1))
	end
end

function PlaceableFence:getDestructionMethod(superFunc)
	return Placeable.DESTRUCTION.PER_NODE
end

function PlaceableFence:previewNodeDestructionNodes(superFunc, node)
	return self:getNodesToDeleteForPanel(node)
end

-- Local values: destroyedNode, destroyPlaceable
function PlaceableFence:performNodeDestruction(superFunc, node)
	return self:deletePanel(node), self:getNumSequments() == 0
end

function PlaceableFence:collectPickObjects(superFunc, node) end
