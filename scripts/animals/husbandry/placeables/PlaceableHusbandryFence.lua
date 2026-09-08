source("dataS/scripts/animals/husbandry/placeables/events/HusbandryFenceUpdateEvent.lua")
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryFenceCustomizeStartEvent.lua")
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryFenceCustomizeFinishEvent.lua")
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryFenceValidateEvent.lua")
PlaceableHusbandryFence = {}

function PlaceableHusbandryFence.prerequisitesPresent(self)
	return true
end

function PlaceableHusbandryFence.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onHusbandryFenceCustomizingUserLeft")
end

function PlaceableHusbandryFence.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getHasCustomizableFence", PlaceableHusbandryFence.getHasCustomizableFence)
	SpecializationUtil.registerFunction(placeableType, "getFence", PlaceableHusbandryFence.getFence)
	SpecializationUtil.registerFunction(placeableType, "getCustomizeableSectionStartAndEndPositions", PlaceableHusbandryFence.getCustomizeableSectionStartAndEndPositions)
	SpecializationUtil.registerFunction(placeableType, "getDefaultFenceOrientation", PlaceableHusbandryFence.getDefaultFenceOrientation)
	SpecializationUtil.registerFunction(placeableType, "getFenceContourPositions", PlaceableHusbandryFence.getFenceContourPositions)
	SpecializationUtil.registerFunction(placeableType, "updateHusbandryFence", PlaceableHusbandryFence.updateHusbandryFence)
	SpecializationUtil.registerFunction(placeableType, "finalizeHusbandryFence", PlaceableHusbandryFence.finalizeHusbandryFence)
	SpecializationUtil.registerFunction(placeableType, "createDefaultFence", PlaceableHusbandryFence.createDefaultFence)
	SpecializationUtil.registerFunction(placeableType, "deleteCustomizableSegments", PlaceableHusbandryFence.deleteCustomizableSegments)
	SpecializationUtil.registerFunction(placeableType, "onFenceI3DLoaded", PlaceableHusbandryFence.onFenceI3DLoaded)
	SpecializationUtil.registerFunction(placeableType, "startFenceCustomization", PlaceableHusbandryFence.startFenceCustomization)
	SpecializationUtil.registerFunction(placeableType, "finishFenceCustomization", PlaceableHusbandryFence.finishFenceCustomization)
	SpecializationUtil.registerFunction(placeableType, "onHusbandryFenceUserRemoved", PlaceableHusbandryFence.onHusbandryFenceUserRemoved)
	SpecializationUtil.registerFunction(placeableType, "hideDefaultFence", PlaceableHusbandryFence.hideDefaultFence)
	SpecializationUtil.registerFunction(placeableType, "restoreDefaultFence", PlaceableHusbandryFence.restoreDefaultFence)
	SpecializationUtil.registerFunction(placeableType, "tryFinalizeFence", PlaceableHusbandryFence.tryFinalizeFence)
	SpecializationUtil.registerFunction(placeableType, "getAllowFenceSegmentDeletion", PlaceableHusbandryFence.getAllowFenceSegmentDeletion)
end

function PlaceableHusbandryFence.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setPreviewPosition", PlaceableHusbandryFence.setPreviewPosition)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableHusbandryFence.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "createNavigationMesh", PlaceableHusbandryFence.createNavigationMesh)
end

function PlaceableHusbandryFence.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onPreFinalizePlacement", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryFence)
end

function PlaceableHusbandryFence.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v7_ = basePath .. ".husbandry.fence"
	schema:register(XMLValueType.STRING, v7_ .. "#xmlFilename", "Fence xml filename")
	schema:register(XMLValueType.STRING, v7_ .. ".sections.section(?)#segmentId", "segment id from fence xml to use for this section", nil, true)
	schema:register(XMLValueType.BOOL, v7_ .. ".sections.section(?)#isReversed", "Reverse segment (gate)")
	schema:register(XMLValueType.BOOL, v7_ .. ".sections.section(?)#customizable", "User has the option to place this section manually")
	schema:register(XMLValueType.NODE_INDEX, v7_ .. ".sections.section(?).node(?)#node", "Fence node")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryFence.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	Fence.registerSavegameXMLPaths(schema, basePath .. ".fence")
	schema:setXMLSpecializationType()
end

-- Local values: spec, fenceXmlFilename, fenceI3dFilename, loadingTask, arguments
function PlaceableHusbandryFence:onLoad(savegame)
	local v11_ = self.spec_husbandryFence
	v11_.userIsCustomizing = false
	v11_.hasCustomizableFence = nil
	v11_.canBePlaced = true
	if _G.g_iconGenerator == nil then
		local v12_ = self.xmlFile:getValue("placeable.husbandry.fence#xmlFilename")
		if v12_ == nil then
			return
		else
			local v13_ = Utils.getFilename(v12_, self.baseDirectory)
			if v13_ == nil then
				Logging.xmlWarning(self.xmlFile, "No fence xml filename defined at %q", "placeable.husbandry.fence.xmlFilename")
				return
			else
				self.fenceXmlFile = XMLFile.load("placeableHusbandryfence", v13_, Fence.xmlSchema)
				if self.fenceXmlFile == nil then
					Logging.xmlWarning(self.xmlFile, "Could not load fence xml file")
					return
				else
					local v14_ = self.fenceXmlFile:getString("placeable.base.filename")
					if string.isNilOrWhitespace(v14_) then
						Logging.xmlWarning(self.fenceXmlFile, "No fence i3d file defined at %q", "placeable.base.filename")
						self.fenceXmlFile:delete()
						self.fenceXmlFile = nil
					else
						local v15_ = Utils.getFilename(v14_, self.baseDirectory)
						local v16_ = {
							["fenceI3dFilename"] = v15_,
							["loadingTask"] = self:createLoadingTask()
						}
						v11_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v15_, false, false, self.onFenceI3DLoaded, self, v16_)
					end
				end
			end
		end
	else
		return
	end
end

-- Local values: spec, fenceI3dFilename, loadingTask, components, i3dMappings, _, sectionKey, sectionSegmentId, isReversed, customizable, sectionNodes, _, sectionNodeKey, node
function PlaceableHusbandryFence:onFenceI3DLoaded(i3dNode, failedReason, args)
	local v20_ = self.spec_husbandryFence
	local v21_ = args.fenceI3dFilename
	local v22_ = args.loadingTask
	if i3dNode ~= 0 then
		local v23_ = I3DUtil.loadI3DComponents(i3dNode)
		local v24_ = I3DUtil.loadI3DMapping(self.fenceXmlFile, "placeable", v23_)
		v20_.fence = Fence.new(self.fenceXmlFile, "placeable.fence", v21_, v23_, v24_, self)
		if v20_.fence:load(self.fenceXmlFile, "placeable.fence") then
			v20_.fenceSegmentsData = {}
			for _, v25_ in self.xmlFile:iterator("placeable.husbandry.fence.sections.section") do
				if v20_.hasCustomizableFence then
					Logging.xmlError(self.xmlFile, "Customizable section needs to be the last section. No more section definitions allowed: %q", v25_)
					break
				end
				local v26_ = self.xmlFile:getValue(v25_ .. "#segmentId")
				if v26_ == nil then
					Logging.xmlError(self.xmlFile, "Missing segment id for %q", v25_)
				elseif v20_.fence:getSegmentTemplateById(v26_) == nil then
					Logging.xmlError(self.xmlFile, "Segment id %q does not exist in %q", v26_, self.fenceXmlFile:getFilename())
				else
					local v27_ = self.xmlFile:getValue(v25_ .. "#isReversed")
					local v28_ = self.xmlFile:getValue(v25_ .. "#customizable")
					local v29_ = {}
					for _, v30_ in self.xmlFile:iterator(v25_ .. ".node") do
						local v31_ = self.xmlFile:getValue(v30_ .. "#node", nil, self.components, self.i3dMappings)
						table.insert(v29_, v31_)
					end
					local v32_ = v20_.fenceSegmentsData
					table.insert(v32_, {
						["segmentId"] = v26_,
						["nodes"] = v29_,
						["isReversed"] = v27_,
						["isCustomizable"] = v28_
					})
					if v28_ then
						v20_.hasCustomizableFence = true
					end
				end
			end
			v20_.hasFence = #v20_.fenceSegmentsData > 0
			if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
				self:createDefaultFence()
			end
		end
		delete(i3dNode)
	end
	if self.fenceXmlFile ~= nil then
		self.fenceXmlFile:delete()
		self.fenceXmlFile = nil
	end
	self:finishLoadingTask(v22_)
end

-- Local values: spec, _, segment
function PlaceableHusbandryFence:onDelete()
	local v34_ = self.spec_husbandryFence
	if self.fenceXmlFile ~= nil then
		self.fenceXmlFile:delete()
		self.fenceXmlFile = nil
	end
	if v34_.previewSegments ~= nil then
		for _, v35_ in ipairs(v34_.previewSegments) do
			v35_:delete()
		end
		v34_.previewSegments = nil
	end
	if v34_.fence ~= nil then
		v34_.fence:delete()
		v34_.fence = nil
	end
	if v34_.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v34_.sharedLoadRequestId)
		v34_.sharedLoadRequestId = nil
	end
end

-- Local values: spec, _, segment, _, segment
function PlaceableHusbandryFence:onReadStream(streamId, connection)
	local v39_ = self.spec_husbandryFence
	if v39_.fence ~= nil then
		for _, v40_ in ipairs_reverse(v39_.fence:getSegments()) do
			v40_:delete()
		end
		v39_.fence:readStream(streamId, connection)
		for _, v41_ in ipairs(v39_.fence:getSegments()) do
			v41_.husbandryFenceIsCustomizable = streamReadBool(streamId)
			v41_.husbandryFenceIsDefaultSegment = streamReadBool(streamId)
		end
		self:finalizeHusbandryFence()
		v39_.userIsCustomizing = streamReadBool(streamId)
		if v39_.userIsCustomizing then
			self:hideDefaultFence()
		end
	end
end

-- Local values: spec, _, segment
function PlaceableHusbandryFence:onWriteStream(streamId, connection)
	local v45_ = self.spec_husbandryFence
	if v45_.fence ~= nil then
		v45_.fence:writeStream(streamId, connection)
		for _, v46_ in ipairs(v45_.fence:getSegments()) do
			streamWriteBool(streamId, Utils.getNoNil(v46_.husbandryFenceIsCustomizable, false))
			streamWriteBool(streamId, Utils.getNoNil(v46_.husbandryFenceIsDefaultSegment, false))
		end
		streamWriteBool(streamId, v45_.userIsCustomizing)
	end
end

-- Local values: spec, adjustNeedsSaving, _, segment
function PlaceableHusbandryFence:saveToXMLFile(xmlFile, key, usedModNames)
	local v51_ = self.spec_husbandryFence
	if v51_.fence ~= nil then
		if v51_.customizingUser ~= nil then
			local v52_ = false
			for _, v53_ in ipairs(v51_.fence:getSegments()) do
				if v53_.husbandryFenceIsCustomizable then
					v52_ = true
				elseif v52_ then
					v53_.needsSaving = false
				end
			end
		end
		v51_.fence:saveToXMLFile(xmlFile, key .. ".fence", usedModNames)
	end
end

-- Local values: spec
function PlaceableHusbandryFence:loadFromXMLFile(xmlFile, key)
	local v57_ = self.spec_husbandryFence
	if v57_.fence ~= nil and xmlFile:hasProperty(key .. ".fence") then
		v57_.fence:loadFromXMLFile(xmlFile, key .. ".fence")
	end
end

-- Local values: spec, _, segment
function PlaceableHusbandryFence:onPreFinalizePlacement()
	local v59_ = self.spec_husbandryFence
	if v59_.fence == nil then
		Logging.devInfo("PlaceableHusbandryFence:onPreFinalizePlacement() fence nil, return")
	elseif self.isServer and not self.isLoadedFromSavegame then
		self:createDefaultFence()
		for _, v60_ in ipairs(v59_.previewSegments) do
			Logging.devInfo("PlaceableHusbandryFence.finalizeHusbandryFence: Finalize segments")
			v60_:finalize()
		end
		Logging.devInfo("PlaceableHusbandryFence.finalizeHusbandryFence: Finalize fence")
		v59_.fence:finalize()
	end
end

function PlaceableHusbandryFence:onPostFinalizePlacement()
	if self.isServer then
		self:finalizeHusbandryFence()
	end
end

-- Local values: spec, contourPositions3D, success
function PlaceableHusbandryFence:finalizeHusbandryFence()
	if self.spec_husbandryFence.fence == nil then
		return true
	end
	local v63_ = self:getFenceContourPositions()
	local v64_
	if #v63_ >= 9 then
		v64_ = self:createNavigationMeshFromContour(v63_)
	else
		v64_ = false
	end
	return v64_
end

-- Local values: spec, contourPositions3D, addPosition, segments, segmentIndex, segment, x, y, z, x2, y2, z2
function PlaceableHusbandryFence:getFenceContourPositions(ignoreCustomizableSegments)
	local v_u_67_ = {}
	local v68_ = self.spec_husbandryFence.fence:getSegments()
	local function v76_(p69_, p70_, p71_)
		-- upvalues: (copy) v_u_67_
		local v72_ = v_u_67_[#v_u_67_ - 2]
		local v73_ = v_u_67_[#v_u_67_]
		if MathUtil.equalEpsilon(v72_, p69_, 0.1) and MathUtil.equalEpsilon(v73_, p71_, 0.1) then
			return
		else
			local v74_ = v_u_67_[1]
			local v75_ = v_u_67_[3]
			if not (MathUtil.equalEpsilon(v74_, p69_, 0.1) and MathUtil.equalEpsilon(v75_, p71_, 0.1)) then
				v_u_67_[#v_u_67_ + 1] = p69_
				v_u_67_[#v_u_67_ + 1] = p70_
				v_u_67_[#v_u_67_ + 1] = p71_
			end
		end
	end
	for _, v77_ in ipairs(v68_) do
		if not (ignoreCustomizableSegments and v77_.husbandryFenceIsCustomizable) then
			local v78_, v79_, v80_ = v77_:getStartPos()
			local v81_, v82_, v83_ = v77_:getEndPos()
			v76_(v78_, v79_, v80_)
			v76_(v81_, v82_, v83_)
		end
	end
	return v_u_67_
end

-- Local values: spec
function PlaceableHusbandryFence:createNavigationMesh(superFunc)
	local v86_ = self.spec_husbandryFence
	if v86_.fence == nil or #v86_.fence:getSegments() == 0 then
		superFunc(self)
	end
end

-- Local values: spec
function PlaceableHusbandryFence:startFenceCustomization(user, noEventSend)
	local v90_ = self.spec_husbandryFence
	if v90_.fence ~= nil then
		g_debugManager:removeGroup("NM-Contour")
		HusbandryFenceCustomizeStartEvent.sendEvent(self, noEventSend)
		if self.isServer then
			v90_.customizingUser = user
			g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onHusbandryFenceUserRemoved, self)
		end
		v90_.userIsCustomizing = true
		self:deleteNavigationMeshPlacementCollision()
		self:hideDefaultFence()
	end
end

-- Local values: spec, _, segment, contourPositions3D
function PlaceableHusbandryFence:finishFenceCustomization(user, success, noEventSend)
	local v94_ = self.spec_husbandryFence
	if v94_.fence ~= nil then
		HusbandryFenceCustomizeFinishEvent.sendEvent(self, success, noEventSend)
		v94_.userIsCustomizing = false
		if success then
			v94_.previewSegments = {}
		else
			self:restoreDefaultFence()
			Logging.devWarning("PlaceableHusbandryFence:finishFenceCustomization: fence customization failed or cancelled")
		end
		if self.isServer then
			g_messageCenter:unsubscribe(MessageType.USER_REMOVED, self)
			v94_.customizingUser = nil
			for _, v95_ in ipairs(v94_.fence:getSegments()) do
				v95_.needsSaving = nil
			end
			g_server:broadcastEvent(HusbandryFenceUpdateEvent.new(self, success), true)
		end
		self:createNavigationMeshPlacementCollision((self:getFenceContourPositions()))
	end
end

-- Local values: spec, contourPositions3D, success
function PlaceableHusbandryFence:tryFinalizeFence()
	if self.spec_husbandryFence.fence == nil then
		return true
	end
	local v97_ = self:getFenceContourPositions(true)
	local v98_
	if #v97_ >= 9 then
		v98_ = self:createNavigationMeshFromContour(v97_)
	else
		v98_ = false
	end
	return v98_
end

-- Local values: spec, _, segment
function PlaceableHusbandryFence:hideDefaultFence()
	local v100_ = self.spec_husbandryFence
	for _, v101_ in ipairs(v100_.fence:getSegments()) do
		if v101_.husbandryFenceIsCustomizable then
			v101_.parentBackup = getParent(v101_.root)
			unlink(v101_.root)
			removeFromPhysics(v101_.root)
		end
	end
end

-- Local values: spec, _, segment
function PlaceableHusbandryFence:restoreDefaultFence()
	local v103_ = self.spec_husbandryFence
	for _, v104_ in ipairs_reverse(v103_.fence:getSegments()) do
		if v104_.husbandryFenceIsDefaultSegment or v104_.husbandryFenceIsCustomizable then
			if v104_.parentBackup ~= nil then
				link(v104_.parentBackup, v104_.root)
				addToPhysics(v104_.root)
				v104_.parentBackup = nil
			end
		else
			v103_.fence:removeSegment(v104_)
			v104_:delete()
		end
	end
end

-- Local values: spec
function PlaceableHusbandryFence:onHusbandryFenceUserRemoved(user)
	local v107_ = self.spec_husbandryFence
	if v107_.customizingUser ~= nil and user == v107_.customizingUser then
		v107_.customizingUser = nil
		self:finishFenceCustomization(user, false)
		SpecializationUtil.raiseEvent(self, "onHusbandryFenceCustomizingUserLeft", user)
		Logging.devInfo("Modifying user left the game")
	end
end

-- Local values: spec, polygon, _, section, nodeIndex, node, segment
function PlaceableHusbandryFence:createDefaultFence()
	local v109_ = self.spec_husbandryFence
	local v110_ = Polygon2D.new()
	v109_.previewSegments = {}
	for _, v111_ in ipairs(v109_.fenceSegmentsData) do
		for v112_, v113_ in ipairs(v111_.nodes) do
			if v112_ == #v111_.nodes then
				break
			end
			local v114_ = v109_.fence:createNewSegment(v111_.segmentId)
			v114_:setStartPos(getWorldTranslation(v113_))
			v114_:setEndPos(getWorldTranslation(v111_.nodes[v112_ + 1]))
			if v111_.isReversed ~= nil and v114_.setIsReversed ~= nil then
				v114_:setIsReversed(v111_.isReversed)
			end
			v114_.husbandryFenceIsDefaultSegment = true
			v110_:addNode(v113_)
			local v115_ = v109_.previewSegments
			table.insert(v115_, v114_)
			if v111_.isCustomizable then
				v114_.husbandryFenceIsCustomizable = true
			end
		end
	end
	v109_.fenceOrientation = v110_:getCurveOrientation()
	self:updateHusbandryFence()
end

-- Local values: spec, _, segment
function PlaceableHusbandryFence:deleteCustomizableSegments()
	local v117_ = self.spec_husbandryFence
	for _, v118_ in ipairs_reverse(v117_.fence:getSegments()) do
		if v118_.husbandryFenceIsCustomizable then
			if g_server ~= nil then
				g_server:broadcastEvent(FenceDeleteSegmentEvent.new(self, v118_.id), false)
			end
			v117_.fence:removeSegment(v118_)
			v118_:delete()
		end
	end
end

function PlaceableHusbandryFence.getAllowFenceSegmentDeletion(self)
	return false
end

-- Local values: spec, hitNodes, isBlocked, segmentIndex, segments, _, section, nodeIndex, node, segment, node, hasOverlap
function PlaceableHusbandryFence:updateHusbandryFence()
	local v120_ = self.spec_husbandryFence
	if v120_.fenceSegmentsData == nil then
		return true
	end
	v120_.lastFenceError = nil
	local v121_ = v120_.previewSegments
	local v122_ = 1
	local v123_ = {}
	local v124_ = false
	for _, v125_ in ipairs(v120_.fenceSegmentsData) do
		for v126_, v127_ in ipairs(v125_.nodes) do
			if v126_ == #v125_.nodes then
				break
			end
			local v128_ = v121_[v122_]
			v128_:setStartPos(getWorldTranslation(v127_))
			v128_:setEndPos(getWorldTranslation(v125_.nodes[v126_ + 1]))
			if not v128_:updateMeshes() then
				v120_.lastFenceError = v128_.lastError
				return false
			end
			v128_:checkOverlap(v123_)
			v124_ = v128_:getHasBlockingOverlap(self.ownerFarmId) and true or v124_
			v122_ = v122_ + 1
		end
	end
	for v129_ in pairs(v123_) do
		DebugShapeOutline.render(v129_)
	end
	local v130_ = next(v123_) == nil
	if v130_ then
		v130_ = not v124_
	end
	return v130_
end

-- Local values: spec, canBePlaced
function PlaceableHusbandryFence:setPreviewPosition(superFunc, x, y, z, rotX, rotY, rotZ)
	superFunc(self, x, y, z, rotX, rotY, rotZ)
	local v139_ = self.spec_husbandryFence
	v139_.canBePlaced = true
	local v140_ = self:updateHusbandryFence()
	v139_.canBePlaced = v139_.canBePlaced and v140_
end

-- Local values: spec
function PlaceableHusbandryFence:getHasCustomizableFence()
	return self.spec_husbandryFence.hasCustomizableFence
end

-- Local values: spec
function PlaceableHusbandryFence:getFence()
	return self.spec_husbandryFence.fence
end

-- Local values: spec, startX, startY, startZ, endX, endY, endZ, _, segment
function PlaceableHusbandryFence:getCustomizeableSectionStartAndEndPositions()
	local v144_ = self.spec_husbandryFence
	local v145_ = nil
	local v146_ = nil
	local v147_ = nil
	local v148_ = nil
	local v149_ = nil
	local v150_ = nil
	for _, v151_ in ipairs(v144_.fence:getSegments()) do
		if v151_.husbandryFenceIsCustomizable then
			if v145_ == nil then
				v145_, v146_, v147_ = v151_:getStartPos()
			end
			v148_, v149_, v150_ = v151_:getEndPos()
		end
	end
	return v145_, v146_, v147_, v148_, v149_, v150_
end

-- Local values: spec
function PlaceableHusbandryFence:getDefaultFenceOrientation()
	return self.spec_husbandryFence.fenceOrientation
end

-- Local values: spec, lastError, errorMessageLocaKey
function PlaceableHusbandryFence:getCanBePlacedAt(superFunc, x, y, z, farmId)
	local v159_ = self.spec_husbandryFence
	if self.spec_husbandryFence.canBePlaced then
		return superFunc(self, x, y, z, farmId)
	end
	local v160_ = v159_.lastFenceError
	local v161_ = ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE[v160_] or "warning_canNotPlaceFence"
	return false, g_i18n:getText(v161_)
end
