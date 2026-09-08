PlaceableNewFence = {}

function PlaceableNewFence.prerequisitesPresent(self)
	return true
end

function PlaceableNewFence.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onCreateSegment")
end

function PlaceableNewFence.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getFence", PlaceableNewFence.getFence)
	SpecializationUtil.registerFunction(placeableType, "onSegmentCreated", PlaceableNewFence.onSegmentCreated)
	SpecializationUtil.registerFunction(placeableType, "getNumSequments", PlaceableNewFence.getNumSequments)
	SpecializationUtil.registerFunction(placeableType, "getPanelLength", PlaceableNewFence.getPanelLength)
	SpecializationUtil.registerFunction(placeableType, "getIsPanelLengthFixed", PlaceableNewFence.getIsPanelLengthFixed)
	SpecializationUtil.registerFunction(placeableType, "updateDirtyAreas", PlaceableNewFence.updateDirtyAreas)
	SpecializationUtil.registerFunction(placeableType, "getSupportsParallelSnapping", PlaceableNewFence.getSupportsParallelSnapping)
	SpecializationUtil.registerFunction(placeableType, "getSnapDistance", PlaceableNewFence.getSnapDistance)
	SpecializationUtil.registerFunction(placeableType, "getSnapAngle", PlaceableNewFence.getSnapAngle)
	SpecializationUtil.registerFunction(placeableType, "getSnapCheckDistance", PlaceableNewFence.getSnapCheckDistance)
	SpecializationUtil.registerFunction(placeableType, "getAllowExtendingOnly", PlaceableNewFence.getAllowExtendingOnly)
	SpecializationUtil.registerFunction(placeableType, "getMaxCornerAngle", PlaceableNewFence.getMaxCornerAngle)
	SpecializationUtil.registerFunction(placeableType, "getHasParallelSnapping", PlaceableNewFence.getHasParallelSnapping)
end

function PlaceableNewFence.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getIsOnFarmland", PlaceableNewFence.getIsOnFarmland)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableNewFence.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getDestructionMethod", PlaceableNewFence.getDestructionMethod)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "performNodeDestruction", PlaceableNewFence.performNodeDestruction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "previewNodeDestructionNodes", PlaceableNewFence.previewNodeDestructionNodes)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableNewFence.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getOwnerFarmId", PlaceableNewFence.getOwnerFarmId)
end

function PlaceableNewFence.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableNewFence)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableNewFence)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableNewFence)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableNewFence)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableNewFence)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableNewFence)
end

function PlaceableNewFence.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	Fence.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

function PlaceableNewFence.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	Fence.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, i3dFilename, preplacedParent, fenceSegmentIndex, fenceSegmentsNode, i, staticFenceIndex, staticFenceNode, i
function PlaceableNewFence:onLoad(savegame)
	local v10_ = self.spec_newFence
	local v11_ = self.xmlFile
	local v12_ = v11_:getValue("placeable.base.filename")
	if string.isNilOrWhitespace(v12_) then
		Logging.xmlError(v11_, "Unable to load fence, no i3d filename given at \'placeable.base.filename\'!")
		self:setLoadingState(PlaceableLoadingState.ERROR)
		return
	else
		v10_.existingPlaceableInstance = g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.configFileName)
		if v10_.existingPlaceableInstance == nil then
			local v13_ = Utils.getFilename(v12_, self.baseDirectory)
			v10_.segmentsNode = createTransformGroup("segments")
			link(self.rootNode, v10_.segmentsNode)
			v10_.fence = Fence.new(v11_, "placeable.fence", v13_, self.components, self.i3dMappings, self, v10_.segmentsNode)
			if v10_.fence:load(v11_, "placeable.fence") then
				if self:getIsPreplaced() then
					local v14_ = getParent(self.rootNode)
					if v14_ ~= 0 then
						local v15_ = getUserAttribute(v14_, "fenceSegments")
						local v16_ = I3DUtil.indexToObject(v14_, v15_)
						if v16_ ~= nil then
							for v17_ = getNumOfChildren(v16_) - 1, 0, -1 do
								delete(getChildAt(v16_, v17_))
							end
						end
						local v18_ = getUserAttribute(v14_, "staticFence")
						local v19_ = I3DUtil.indexToObject(v14_, v18_)
						if v19_ ~= nil then
							for v20_ = getNumOfChildren(v19_) - 1, 0, -1 do
								delete(getChildAt(v19_, v20_))
							end
						end
					end
				end
			else
				Logging.xmlError(v11_, "Unable to load fence!")
				self:setLoadingState(PlaceableLoadingState.ERROR)
			end
		else
			Logging.info("Instance of fence \'%s\' found. Starting merge process...", self.configFileName)
			return
		end
	end
end

-- Local values: spec
function PlaceableNewFence:onDelete()
	local v22_ = self.spec_newFence
	if v22_.fence ~= nil then
		v22_.fence:delete()
		v22_.fence = nil
	end
end

-- Local values: spec
function PlaceableNewFence:onFinalizePlacement()
	if self.spec_newFence.existingPlaceableInstance ~= nil then
		Logging.info("Finished merge process for fence \'%s\'.", self.configFileName)
		self:delete()
	end
end

-- Local values: spec
function PlaceableNewFence:onReadStream(streamId, connection)
	self.spec_newFence.fence:readStream(streamId, connection)
end

-- Local values: spec
function PlaceableNewFence:onWriteStream(streamId, connection)
	self.spec_newFence.fence:writeStream(streamId, connection)
end

-- Local values: spec
function PlaceableNewFence:onUpdate(dt)
	local v32_ = self.spec_newFence
	if v32_.fence ~= nil then
		v32_.fence:update(dt)
	end
end

function PlaceableNewFence:onSegmentCreated(segment)
	SpecializationUtil.raiseEvent(self, "onCreateSegment", false, segment)
end

function PlaceableNewFence:setOwnerFarmId(superFunc, ownerFarmId, noEventSend) end

function PlaceableNewFence.getOwnerFarmId(self)
	return AccessHandler.EVERYONE
end

-- Local values: spec, fence
function PlaceableNewFence:loadFromXMLFile(xmlFile, key)
	local v38_ = self.spec_newFence
	local v39_ = v38_.fence
	if v38_.existingPlaceableInstance ~= nil then
		v39_ = v38_.existingPlaceableInstance:getFence()
		Logging.info("Merging savegame data into existing fence instance")
	end
	v39_:loadFromXMLFile(xmlFile, key)
end

-- Local values: spec
function PlaceableNewFence:saveToXMLFile(xmlFile, key, usedModNames)
	self.spec_newFence.fence:saveToXMLFile(xmlFile, key, usedModNames)
end

function PlaceableNewFence:getIsOnFarmland(superFunc, farmlandId)
	return false
end

function PlaceableNewFence:getFence()
	return self.spec_newFence.fence
end

function PlaceableNewFence:getSegmentLength(segment)
	return MathUtil.getPointPointDistance(segment.x1, segment.z1, segment.x2, segment.z2)
end

function PlaceableNewFence:getPanelLength()
	return self.spec_newFence.panelLength
end

function PlaceableNewFence:getIsPanelLengthFixed()
	return self.spec_newFence.panelLengthFixed
end

-- Local values: minX, maxX, minZ, maxZ
function PlaceableNewFence:updateDirtyAreas(x1, z1, x2, z2)
	local v52_ = math.min(x1, x2)
	local v53_ = math.max(x1, x2)
	local v54_ = math.min(z1, z2)
	local v55_ = math.max(z1, z2)
	g_densityMapHeightManager:setCollisionMapAreaDirty(v52_, v54_, v53_, v55_, true)
	g_currentMission.aiSystem:setAreaDirty(v52_, v53_, v54_, v55_)
end

-- Local values: spec
function PlaceableNewFence:getNumSequments()
	return self.spec_newFence.fence:getNumSegments()
end

-- Local values: spec
function PlaceableNewFence:getMaxVerticalAngle()
	return self.spec_newFence.maxVerticalAngle
end

-- Local values: spec
function PlaceableNewFence:getMaxVerticalGateAngle()
	return self.spec_newFence.maxVerticalGateAngle
end

function PlaceableNewFence:getSnapDistance()
	return nil
end

function PlaceableNewFence:getSnapAngle()
	return nil
end

function PlaceableNewFence:getSnapCheckDistance()
	return nil
end

function PlaceableNewFence:getAllowExtendingOnly()
	return nil
end

function PlaceableNewFence:getMaxCornerAngle()
	return nil
end

function PlaceableNewFence:getHasParallelSnapping()
	return false
end

function PlaceableNewFence:getSupportsParallelSnapping()
	return false
end

-- Local values: objects, i
function PlaceableNewFence:addPickingNodesForSegment(segment)
	if segment ~= self.spec_newFence.previewSegment then
		if segment.group ~= nil then
			local v61_ = {}
			self:recursivelyAddPickingNodes(v61_, segment.group)
			for v62_ = 1, #v61_ do
				g_currentMission:addNodeObject(v61_[v62_], self)
			end
		end
		self.overlayColorNodes = nil
	end
end

-- Local values: objects, i
function PlaceableNewFence:removePickingNodesForSegment(segment)
	if segment ~= self.spec_newFence.previewSegment then
		if segment.group ~= nil then
			local v65_ = {}
			self:recursivelyAddPickingNodes(v65_, segment.group)
			for v66_ = 1, #v65_ do
				g_currentMission:removeNodeObject(v65_[v66_])
			end
		end
	end
end

-- Local values: numChildren, i
function PlaceableNewFence:recursivelyAddPickingNodes(objects, node)
	if getRigidBodyType(node) ~= RigidBodyType.NONE then
		table.insert(objects, node)
	end
	for v70_ = 1, getNumOfChildren(node) do
		self:recursivelyAddPickingNodes(objects, getChildAt(node, v70_ - 1))
	end
end

function PlaceableNewFence:getDestructionMethod(superFunc)
	return Placeable.DESTRUCTION.PER_NODE
end

function PlaceableNewFence:previewNodeDestructionNodes(superFunc, node)
	return self:getNodesToDeleteForPanel(node)
end

-- Local values: destroyedNode, destroyPlaceable
function PlaceableNewFence:performNodeDestruction(superFunc, node)
	return self:deletePanel(node), self:getNumSequments() == 0
end

function PlaceableNewFence:collectPickObjects(superFunc, node) end
