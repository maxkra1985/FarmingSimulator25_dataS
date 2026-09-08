-- Local values: ConstructionBrushNewFence_mt
ConstructionBrushNewFence = {}
local ConstructionBrushNewFence_mt = Class(ConstructionBrushNewFence, ConstructionBrush)
ConstructionBrushNewFence.ERROR = {
	["MININUM_LENGTH"] = 100,
	["MINIMUM_ANGLE"] = 101,
	["MAXIMUM_ANGLE"] = 102,
	["COLLISION"] = 103,
	["NOT_ENOUGH_MONEY"] = 104,
	["CANNOT_BE_PLACED_HERE"] = 105
}
ConstructionBrushNewFence.ERROR_MESSAGES = {
	[ConstructionBrushNewFence.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort",
	[ConstructionBrushNewFence.ERROR.MINIMUM_ANGLE] = "ui_construction_cornerAngleTooLarge",
	[ConstructionBrushNewFence.ERROR.MAXIMUM_ANGLE] = "ui_construction_terrainTooSteep",
	[ConstructionBrushNewFence.ERROR.COLLISION] = "ui_construction_collidesWithItem",
	[ConstructionBrushNewFence.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
	[ConstructionBrushNewFence.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere"
}
ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE = {
	[FenceSegment.ERROR_TOO_SHORT] = "ui_construction_distanceTooShort",
	[FenceSegment.ERROR_TOO_STEEP] = "ui_construction_terrainTooSteep"
}
ConstructionBrushNewFence.STATUS = {
	["SUCCESS"] = 0,
	["CANCELLED"] = 1
}
ConstructionBrushNewFence.MINIMUM_LENGTH = 0.5
ConstructionBrushNewFence.MINIMUM_ANGLE = 0.5235987755982988
ConstructionBrushNewFence.SNAP_DISTANCE = 0.4
ConstructionBrushNewFence.LAST_SNAPPING_STATE = false

-- Upvalues: ConstructionBrushNewFence_mt
-- Local values: self, i3dNode
function ConstructionBrushNewFence.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushNewFence_mt
	local v4_ = ConstructionBrushNewFence:superClass().new(subclass_mt or ConstructionBrushNewFence_mt, cursor)
	v4_.supportsPrimaryButton = true
	v4_.supportsSecondaryButton = true
	v4_.supportsTertiaryButton = true
	v4_.supportsFourthButton = true
	v4_.supportsPrimaryAxis = true
	v4_.supportsSecondaryAxis = true
	v4_.needsOverlayReset = {}
	v4_.segmentIds = {}
	v4_.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
	v4_.isValidating = false
	v4_.canToggleParallelSnapping = false
	v4_.parallelSnappingEnabled = false
	v4_.doFindPlaceable = false
	v4_.supportsSnapping = true
	v4_.snappingActive = ConstructionBrushNewFence.LAST_SNAPPING_STATE
	v4_.snappingAngleDeg = 7.5
	v4_.snappingSize = 0.25
	v4_.overlappingNodes = {}
	local v5_ = g_i3DManager:loadI3DFile("data/shared/visualization/fenceSnapMarker.i3d", false, false)
	if v5_ ~= 0 then
		v4_.snapMarkerStart = getChildAt(v5_, 0)
		v4_.snapMarkerEnd = clone(v4_.snapMarkerStart, false, false, false)
		link(getRootNode(), v4_.snapMarkerStart)
		link(getRootNode(), v4_.snapMarkerEnd)
		setShaderParameter(v4_.snapMarkerStart, "emitColor", 0, 1, 0, 1, false)
		setShaderParameter(v4_.snapMarkerEnd, "emitColor", 0, 1, 0, 1, false)
		setVisibility(v4_.snapMarkerStart, false)
		setVisibility(v4_.snapMarkerEnd, false)
		delete(v5_)
	end
	return v4_
end

function ConstructionBrushNewFence:delete()
	ConstructionBrushNewFence:superClass().delete(self)
	self.doFindPlaceable = false
	if self.snapMarkerStart ~= nil then
		delete(self.snapMarkerStart)
		delete(self.snapMarkerEnd)
	end
end

function ConstructionBrushNewFence:setFenceParentObject(parentObject)
	if parentObject.getFence == nil then
		Logging.error("ConstructionBrushNewFence:setFenceParentObject(): parent object does not have a \'getFence\' function")
	else
		self.fenceParentObject = parentObject
		self:initFence()
	end
end

function ConstructionBrushNewFence:activate()
	ConstructionBrushNewFence:superClass().activate(self)
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	self.cursor:setShapeSize(0.3)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
	self.cursor:setTerrainOnly(true)
	if self.fenceParentObject == nil and self:hasPlayerPermission() then
		self:acquirePlaceable()
	end
end

function ConstructionBrushNewFence:deactivate()
	if self.currentSegment ~= nil then
		self.currentSegment:delete()
		self.currentSegment = nil
	end
	if self.snapMarkerStart ~= nil then
		setWorldTranslation(self.snapMarkerStart, 0, 0, 0)
		setWorldTranslation(self.snapMarkerEnd, 0, 0, 0)
		setVisibility(self.snapMarkerStart, false)
		setVisibility(self.snapMarkerEnd, false)
	end
	self:releasePlaceable()
	self.isValidating = false
	self.segmentIds = {}
	self.fenceParentObject = nil
	self.doFindPlaceable = false
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT, nil)
	g_messageCenter:unsubscribeAll(self)
	self.overlappingNodes = {}
	self:finish(ConstructionBrushNewFence.STATUS.CANCELLED)
	self.cursor:setTerrainOnly(false)
	ConstructionBrushNewFence:superClass().deactivate(self)
end

function ConstructionBrushNewFence:setSnapStartAndEndPositions(startX, startY, startZ, endX, endY, endZ)
	if startX == nil or endX == nil then
		Logging.devError("ConstructionBrushNewFence:setSnapStartAndEndPositions(): Trying to set nil snapping positions")
	else
		self.snapStart = { startX, startY, startZ }
		self.snapEnd = { endX, endY, endZ }
		self.hasSnapPositions = true
		if self.snapMarkerStart ~= nil then
			setWorldTranslation(self.snapMarkerStart, startX, startY, startZ)
			setWorldTranslation(self.snapMarkerEnd, endX, endY, endZ)
			setVisibility(self.snapMarkerStart, true)
			setVisibility(self.snapMarkerEnd, true)
		end
	end
end

function ConstructionBrushNewFence:setFinishCallback(func)
	self.finishCallbackFunc = func
end

function ConstructionBrushNewFence:setValidateCallback(func)
	self.validateCallbackFunc = func
end

-- Local values: metadata, sx, sy, sz
function ConstructionBrushNewFence:setSegmentTemplate(id)
	self.templateId = id
	self.parallelSnappingEnabled = false
	self.canToggleParallelSnapping = false
	local v24_ = self.fence:getSegmentTemplateById(self.templateId)
	if v24_.parallelSnapping ~= nil then
		self.canToggleParallelSnapping = v24_.parallelSnapping.canToggle
		if not self.canToggleParallelSnapping then
			self.parallelSnappingEnabled = true
		end
	end
	self:setInputTextDirty()
	local v25_, v26_, v27_
	if self.currentSegment == nil then
		v25_ = nil
		v26_ = nil
		v27_ = nil
	else
		v25_, v26_, v27_ = self.currentSegment:getStartPos()
		self.currentSegment:delete()
		self.currentSegment = nil
	end
	self.currentSegment = self.fence:createNewSegment(self.templateId)
	self.currentSegment:setParallelSnappingSegment(self.parallelSnappingSegment)
	if v25_ ~= nil then
		self.currentSegment:setStartPos(v25_, v26_, v27_)
	end
end

function ConstructionBrushNewFence:canCancel()
	local v29_
	if self.fenceParentObject == nil then
		v29_ = false
	else
		v29_ = self.currentSegment ~= nil
	end
	return v29_
end

-- Local values: data
function ConstructionBrushNewFence:acquirePlaceable()
	if self.storeItem == nil then
		Logging.warning("ConstructionBrushNewFence has no store item set")
	else
		self.fenceParentObject = self:findPlaceable()
		if self.fenceParentObject == nil then
			local v31_ = BuyPlaceableData.new()
			v31_:setStoreItem(self.storeItem)
			v31_:setPosition(0, PlacementUtil.NETHER_HEIGHT - 1, 0)
			v31_:setRotation(0, 0, 0)
			v31_:setConfigurations({})
			v31_:setOwnerFarmId(AccessHandler.EVERYONE)
			v31_:setDisplacementCosts(0)
			v31_:setModifyTerrain(false)
			v31_:setIsFreeOfCharge(true)
			g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
			g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(v31_))
		else
			self:initFence()
		end
		self:setInputTextDirty()
	end
end

-- Local values: configXMLFilename, existingPlaceableInstance
function ConstructionBrushNewFence:findPlaceable()
	local v33_ = self.storeItem.xmlFilename
	return g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(v33_)
end

function ConstructionBrushNewFence:onPlaceableCreated(errorCode, price, serverObjectId)
	g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
	if errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_couldNotLoadItem"))
	else
		self.doFindPlaceable = true
	end
end

function ConstructionBrushNewFence:initFence()
	if self.fenceParentObject.getFence == nil then
		Logging.xmlError(self.fenceParentObject.configFileName, "Fence parent object is missing \'getFence\' function, check placeableType")
	else
		self.fence = self.fenceParentObject:getFence()
		self:setSegmentTemplate(self.fence:getSegmentTemplates()[1])
		self:setInputTextDirty()
	end
end

function ConstructionBrushNewFence:releasePlaceable()
	if self.storeItem ~= nil and self.fenceParentObject ~= nil then
		if self.fence == nil or self.fence:getNumSegments() == 0 then
			g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
			g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.fenceParentObject, true, false, false, true))
		end
		self.fenceParentObject = nil
		self.fence = nil
		self:setInputTextDirty()
	end
end

function ConstructionBrushNewFence:onPlaceableDestroyed()
	g_messageCenter:unsubscribe(SellPlaceableEvent, self)
end

-- Local values: x, y, z, metadata, snapDistance, allowExtendingOnly, maxCornerAngle, currentSegmentStartX, currentSegmentStartY, currentSegmentStartZ, hasStartPosition, endPos, pole, _distance, px, py, pz, _segmentId, isStartPole, isEndPole, ignore, snappedTargetSegment, ex, ez, lastPole, _distance, _px, _py, _pz, lastSegmentId, _isStartPole, _isEndPole, segment, segmentStartX, _, segmentStartZ, segmentEndX, _, segmentEndZ, distance, currentSegmentDirX, currentSegmentDirZ, lastSegmentDirX, lastSegmentDirZ, cosMax, forwardDot, backwardDot, forwardOK, backwardOK, allowed, ax, az, _, crossY, _, dot, angle, clampedAngle, cos, sin, cx, cz, clampedNewX, clampedNewZ, clampedNewY, parallelSnapCheckDistance, parallelSnapDistance, snappedPole, _distance, snappedPoleX, snappedPoleY, snappedPoleZ, snappedSegment, startX, _, startZ, endX, _, endZ, dx, dz, snapLineX, snapLineZ, x1, z1, x2, z2, distance1, distance2, distancePole, snapX, snapZ, snapY, otherRowPole, _distance, otherRowPoleX, otherRowPoleY, otherRowPoleZ, alignSegment, startX, _, startZ, endX, _, endZ, dx, dz, targetX, targetZ, targetY
function ConstructionBrushNewFence:getSnappedCursorPosition()
	local v40_, v41_, v42_ = self.cursor:getHitTerrainPosition()
	if v40_ == nil then
		return v40_, v41_, v42_, false
	else
		local v43_ = self.fence:getSegmentTemplateById(self.templateId)
		local v44_ = v43_.snapDistance or (self.currentSegment == nil and 2 or (self.currentSegment:getMinimumPanelLength() or 2))
		local v45_
		if v43_.extending == nil then
			v45_ = nil
		else
			v45_ = v43_.extending.allowExtendingOnly or nil
		end
		local v46_
		if v43_.extending == nil then
			v46_ = nil
		else
			v46_ = v43_.extending.maxCornerAngle or nil
		end
		local v47_, v48_, v49_
		if self.currentSegment == nil then
			v47_ = nil
			v48_ = nil
			v49_ = nil
		else
			v48_, v49_, v47_ = self.currentSegment:getStartPos()
		end
		local v50_ = v48_ ~= nil
		if self.hasSnapPositions and v50_ then
			local v51_ = self.snapEnd
			if MathUtil.vector3Length(v51_[1] - v40_, v51_[2] - v41_, v51_[3] - v42_) < v44_ then
				return v51_[1], v51_[2], v51_[3], true
			end
		end
		local v52_, _, v53_, v54_, v55_, _, v56_, v57_ = self.fence:getPoleNear(v40_, v41_, v42_, v44_)
		if v52_ ~= nil and (not v50_ or self.parallelSnappingSegment == nil) and (not v50_ or MathUtil.vector2Length(v53_ - v48_, v55_ - v47_) >= 0.1) then
			local v58_ = self.fence:getSegmentFromNode(v52_)
			if not v45_ or (v56_ or v57_) then
				return v53_, v54_, v55_, true, v58_
			end
		end
		if v46_ ~= nil and (self.currentSegment ~= nil and (v50_ and v40_ ~= nil)) then
			local v59_, _, _, _, _, v60_, _, _ = self.fence:getPoleNear(v48_, v49_, v47_, 0.5)
			if v59_ ~= nil then
				local v61_ = self.fence:getSegmentById(v60_)
				if v61_ ~= nil then
					local v62_, _, v63_ = v61_:getStartPos()
					local v64_, _, v65_ = v61_:getEndPos()
					local v66_ = MathUtil.vector2Length(v40_ - v48_, v42_ - v47_)
					local v67_, v68_ = MathUtil.vector2Normalize(v40_ - v48_, v42_ - v47_)
					local v69_, v70_ = MathUtil.vector2Normalize(v64_ - v62_, v65_ - v63_)
					local v71_ = math.cos(v46_)
					local v72_ = MathUtil.dotProduct(v69_, 0, v70_, v67_, 0, v68_)
					local v73_ = MathUtil.dotProduct(v69_, 0, v70_, -v67_, 0, -v68_)
					if v71_ > v72_ and v71_ > v73_ then
						if v72_ < 0 then
							v67_ = -v67_
							v68_ = -v68_
						end
						local _, v74_, _ = MathUtil.crossProduct(v67_, 0, v68_, v69_, 0, v70_)
						local v75_ = MathUtil.dotProduct(v67_, 0, v68_, v69_, 0, v70_)
						local v76_ = math.atan2(v74_, v75_)
						local v77_ = -v46_
						local v78_ = math.clamp(v76_, v77_, v46_)
						if v73_ > 0 then
							v78_ = v78_ + 3.141592653589793
						end
						local v79_ = math.cos(v78_)
						local v80_ = math.sin(v78_)
						local v81_ = v69_ * v79_ - v70_ * v80_
						local v82_ = v69_ * v80_ + v70_ * v79_
						local v83_, v84_ = MathUtil.vector2Normalize(v81_, v82_)
						local v85_ = v48_ + v83_ * v66_
						local v86_ = v47_ + v84_ * v66_
						return v85_, getTerrainHeightAtWorldPos(g_terrainNode, v85_, 0, v86_), v86_, true
					end
				end
			end
		end
		if self.parallelSnappingEnabled then
			local v87_ = v43_.parallelSnapping.checkDistance
			local v88_ = v43_.parallelSnapping.snapDistance
			local v89_, _, v90_, v91_, v92_ = self.fence:getPoleNear(v40_, v41_, v42_, v87_)
			if v89_ ~= nil and not v50_ then
				local v93_ = self.fence:getSegmentFromNode(v89_)
				self.parallelSnappingSegment = v93_
				if self.currentSegment ~= nil then
					self.currentSegment:setParallelSnappingSegment(v93_)
				end
				local v94_, _, v95_ = v93_:getStartPos()
				local v96_, _, v97_ = v93_:getEndPos()
				local v98_, v99_ = MathUtil.vector2Normalize(v96_ - v94_, v97_ - v95_)
				local v100_, v101_
				if self.snappingActive then
					v100_ = v92_
					v101_ = v90_
				else
					v101_, v100_ = MathUtil.projectOnLine(v40_, v42_, v90_, v92_, v98_, v99_)
				end
				local v102_ = -v99_ * v88_ + v101_
				local v103_ = v98_ * v88_ + v100_
				local v104_ = v99_ * v88_ + v101_
				local v105_ = -v98_ * v88_ + v100_
				local v106_ = MathUtil.vector2Length(v102_ - v40_, v103_ - v42_)
				local v107_ = MathUtil.vector2Length(v104_ - v40_, v105_ - v42_)
				local v108_ = MathUtil.vector2Length(v90_ - v40_, v92_ - v42_)
				if v106_ < v107_ then
					v105_ = v103_
					v104_ = v102_
				end
				local v109_ = getTerrainHeightAtWorldPos(g_terrainNode, v104_, 0, v105_)
				if v46_ == 0 and (v108_ < v44_ and (v56_ or v57_)) then
					return v90_, v91_, v92_, true, v93_
				else
					local v110_, _, v111_, v112_, v113_ = self.fence:getPoleNear(v104_, v109_, v105_, v44_)
					if v110_ then
						return v111_, v112_, v113_, true
					else
						return v104_, v109_, v105_, true
					end
				end
			end
			if self.parallelSnappingSegment ~= nil and v50_ then
				local v114_ = self.parallelSnappingSegment
				local v115_, _, v116_ = v114_:getStartPos()
				local v117_, _, v118_ = v114_:getEndPos()
				local v119_, v120_ = MathUtil.vector2Normalize(v117_ - v115_, v118_ - v116_)
				local v121_, v122_ = MathUtil.projectOnLine(v40_, v42_, v48_, v47_, v119_, v120_)
				return v121_, getTerrainHeightAtWorldPos(g_terrainNode, v121_, 0, v122_), v122_, true
			end
			self.parallelSnappingSegment = nil
			if self.currentSegment ~= nil then
				self.currentSegment:setParallelSnappingSegment(nil)
			end
		end
		if self.snappingActive then
			return MathUtil.snapValue(v40_, self.snappingSize), v41_, MathUtil.snapValue(v42_, self.snappingSize), true
		else
			return v40_, v41_, v42_, false
		end
	end
end

-- Local values: x, y, z, snapped, segment
function ConstructionBrushNewFence:getLimitedSnappedCursorPosition()
	local v124_, v125_, v126_, v127_, v128_ = self:getSnappedCursorPosition()
	return v124_, v125_, v126_, v127_, v128_
end

-- Local values: price
function ConstructionBrushNewFence:getPrice(length)
	if self.gateIndex ~= nil then
		return self.storeItem.price
	end
	if length == nil then
		length = self.fenceParentObject:getSegmentLength(self.fenceParentObject:getPreviewSegment())
	end
	return length * self.storeItem.price
end

function ConstructionBrushNewFence:verifyPreview()
	return nil
end

-- Local values: x, y, z, isSnapped, _snappedSegment, err, overlappingNode, segment, segmentPart, segmentError
function ConstructionBrushNewFence:update(dt)
	ConstructionBrushNewFence:superClass().update(self, dt)
	if self.doFindPlaceable then
		self.fenceParentObject = self:findPlaceable()
		self:setInputTextDirty()
		if self.fenceParentObject ~= nil then
			self:initFence()
			self.doFindPlaceable = false
		end
	end
	if self.fenceParentObject == nil then
		if not self:hasPlayerPermission() then
			self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
			self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.NO_PERMISSION]))
		end
		return
	elseif self.fence == nil then
		return
	else
		self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
		local v133_, v134_, v135_, v136_, _ = self:getLimitedSnappedCursorPosition()
		if self.currentSegment == nil then
			if v136_ then
				self.cursor:setPosition(v133_, v134_, v135_)
			end
			return
		else
			self.currentSegment:draw()
			if self.hasSnapPositions and self.currentSegment:getStartPos() == nil then
				self.currentSegment:setStartPos(self.snapStart[1], self.snapStart[2], self.snapStart[3])
			end
			if v133_ == nil then
				return
			else
				local v137_ = self:verifyAccess(v133_, v134_, v135_)
				if v137_ == nil then
					if v136_ and self.currentSegment:getStartPos() == nil then
						self.cursor:setPosition(v133_, v134_, v135_)
					end
					if self:validateCurrentSegment(v133_, v135_) then
						self.currentSegment:setEndPos(v133_, v134_, v135_)
						if self.currentSegment:updateMeshes() then
							self.currentSegment:update()
							table.clear(self.overlappingNodes)
							self.currentSegment:checkOverlap(self.overlappingNodes)
							for v138_ in pairs(self.overlappingNodes) do
								local v139_ = self.fence:getSegmentFromNode(v138_)
								if v139_ ~= nil then
									local v140_ = v139_:getSegmentPartFromNode(v138_)
									if v140_ ~= nil then
										renderShapeOutline(v140_, true)
									end
								end
							end
							if next(self.overlappingNodes) ~= nil then
								self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
								self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[ConstructionBrushNewFence.ERROR.COLLISION]))
								return
							end
						else
							local v141_ = self.currentSegment:getLastError()
							if v141_ ~= nil then
								self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
								self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE[v141_]))
							end
						end
					end
				else
					self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
					self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[v137_] or ConstructionBrush.ERROR_MESSAGES[v137_]))
				end
			end
		end
	end
end

-- Local values: storeItemNameCleaned
function ConstructionBrushNewFence:draw()
	if g_isDevelopmentVersion and (self.fenceParentObject ~= nil and self.fenceParentObject.configFileName ~= nil) then
		local v143_ = string.gsub(self.fenceParentObject.configFileName, getUserProfileAppPath(), "")
		renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, v143_)
	end
end

-- Local values: sx, _, sz, price
function ConstructionBrushNewFence:validateCurrentSegment(x, z)
	if self.currentSegment == nil then
		return false
	else
		local v147_, _, v148_ = self.currentSegment:getStartPos()
		if v147_ == nil then
			return false
		elseif g_farmlandManager:getIsOwnedByFarmAlongLine(g_localPlayer.farmId, v147_, v148_, x, z) then
			local v149_ = self.currentSegment:getPrice()
			if g_currentMission:getMoney(g_localPlayer.farmId) < v149_ then
				self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[ConstructionBrushNewFence.ERROR.NOT_ENOUGH_MONEY]))
				return false
			else
				if v149_ ~= 0 then
					self.cursor:setMessage(g_i18n:formatMoney(v149_))
				end
				return true
			end
		else
			self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.LAND_UNOWNED]))
			return false
		end
	end
end

-- Local values: x, y, z, _snapped, _segment, err
function ConstructionBrushNewFence:onButtonPrimary()
	if self.isValidating then
		return
	elseif self.fenceParentObject == nil then
		return
	elseif self.fence == nil then
		return
	else
		if self.currentSegment == nil then
			self.currentSegment = self.fence:createNewSegment(self.templateId)
			self.currentSegment:setParallelSnappingSegment(self.parallelSnappingSegment)
		end
		local v151_, v152_, v153_, _, _ = self:getLimitedSnappedCursorPosition()
		if v151_ == nil then
			return
		elseif self:verifyAccess(v151_, v152_, v153_) == nil then
			if self.currentSegment:getStartPos() == nil then
				self.currentSegment:setStartPos(v151_, v152_, v153_)
			else
				if not self:validateCurrentSegment(v151_, v153_) then
					return
				end
				if next(self.overlappingNodes) ~= nil then
					return
				end
				g_messageCenter:subscribeOneshot(FenceNewSegmentEvent, self.onServerCreatedFenceCallback, self)
				g_client:getServerConnection():sendEvent(FenceNewSegmentEvent.newClientToServer(self.fenceParentObject, self.currentSegment))
			end
			self:setInputTextDirty()
		end
	end
end

-- Local values: callback
function ConstructionBrushNewFence:finish(status)
	self.currentSegment = nil
	self.parallelSnappingSegment = nil
	if self.finishCallbackFunc ~= nil then
		local v156_ = self.finishCallbackFunc
		self.finishCallbackFunc = nil
		v156_(status)
	end
end

function ConstructionBrushNewFence:onServerCreatedFenceCallback(statusCode, segmentId, endX, endY, endZ)
	if statusCode == FenceNewSegmentEvent.STATUS_CODE.SUCCESS then
		if self.fenceParentObject.playPlaceSound ~= nil then
			self.fenceParentObject:playPlaceSound()
		end
		if self.currentSegment ~= nil and g_server == nil then
			self.currentSegment:delete()
			self.currentSegment = nil
		end
		table.addElement(self.segmentIds, segmentId)
		if self.hasSnapPositions and MathUtil.vector3Length(self.snapEnd[1] - endX, self.snapEnd[2] - endY, self.snapEnd[3] - endZ) < 0.1 then
			self.currentSegment = nil
			if self.validateCallbackFunc == nil then
				self:finish(ConstructionBrushNewFence.STATUS.SUCCESS)
			else
				self.isValidating = true
				self.validateCallbackFunc(function(p163_)
					-- upvalues: (copy) self
					self.isValidating = false
					if p163_ then
						self:finish(ConstructionBrushNewFence.STATUS.SUCCESS)
					else
						self:deleteLastSeqment()
					end
				end)
			end
		else
			self:createNextSegment(endX, endY, endZ)
			return
		end
	else
		return
	end
end

-- Local values: lastSegmentId, lastSegment, x, y, z
function ConstructionBrushNewFence:deleteLastSeqment()
	if self.fence ~= nil then
		local v_u_165_ = self.segmentIds[#self.segmentIds]
		local v_u_166_ = self.fence:getSegmentById(v_u_165_)
		if v_u_166_ ~= nil then
			local v_u_167_, v_u_168_, v_u_169_ = v_u_166_:getStartPos()
			g_messageCenter:subscribeOneshot(FenceRequestDeleteSegmentEvent, function(self)
				-- upvalues: (copy) self, (copy) v_u_166_, (copy) v_u_165_, (copy) v_u_167_, (copy) v_u_168_, (copy) v_u_169_
				if self.currentSegment ~= nil then
					self.currentSegment:delete()
					self.currentSegment = nil
				end
				if g_server == nil then
					v_u_166_:delete()
				end
				table.removeElement(self.segmentIds, v_u_165_)
				self:createNextSegment(v_u_167_, v_u_168_, v_u_169_)
			end)
			g_client:getServerConnection():sendEvent(FenceRequestDeleteSegmentEvent.new(self.fenceParentObject, v_u_165_))
		end
	end
end

function ConstructionBrushNewFence:createNextSegment(startX, startY, startZ)
	if self.fence ~= nil then
		self.currentSegment = self.fence:createNewSegment(self.templateId)
		self.currentSegment:setParallelSnappingSegment(self.parallelSnappingSegment)
		self.currentSegment:setStartPos(startX, startY, startZ)
	end
end

function ConstructionBrushNewFence:onButtonSecondary()
	if self.snapEnd == nil then
		if self.currentSegment ~= nil then
			self.currentSegment:delete()
			self.currentSegment = nil
			self.parallelSnappingSegment = nil
			self:setInputTextDirty()
		end
	else
		YesNoDialog.show(function(p175_)
			-- upvalues: (copy) self
			if p175_ then
				self:deactivate()
			end
		end, nil, g_i18n:getText("ui_construction_cancelCustomFence"))
	end
end

function ConstructionBrushNewFence:onButtonTertiary()
	if self.canToggleParallelSnapping then
		self.parallelSnappingEnabled = not self.parallelSnappingEnabled
		self:setInputTextDirty()
	end
end

function ConstructionBrushNewFence:onButtonSnapping()
	self.snappingActive = not self.snappingActive
	ConstructionBrushNewFence.LAST_SNAPPING_STATE = self.snappingActive
	self:setInputTextDirty()
end

function ConstructionBrushNewFence:onButtonFourth()
	self:deleteLastSeqment()
end

-- Local values: templates, currentIndex, newIndex, newTemplateId
function ConstructionBrushNewFence:onAxisPrimary(inputValue)
	if self.fence == nil then
		return
	else
		local v181_ = self.fence:getSegmentTemplates()
		if #v181_ ~= 1 then
			self:setSegmentTemplate(v181_[1 + (table.find(v181_, self.templateId) - 1 + inputValue) % #v181_])
			self:setInputTextDirty()
		end
	end
end

-- Local values: templates, currentIndex
function ConstructionBrushNewFence:getAxisPrimaryText()
	if self.fence ~= nil then
		local v183_ = self.fence:getSegmentTemplates()
		if #v183_ <= 1 then
			return nil
		end
		local v184_ = table.find(v183_, self.templateId)
		return string.format("%s (%d/%d)", g_i18n:getText("action_fenceSwitchSegmentType"), v184_, #v183_)
	end
end

function ConstructionBrushNewFence:onAxisSecondary(inputValue)
	if self.currentSegment ~= nil and self.currentSegment.setIsReversed ~= nil then
		self.currentSegment:setIsReversed(not self.currentSegment:getIsReversed())
	end
end

function ConstructionBrushNewFence:getAxisSecondaryText()
	if self.currentSegment == nil or self.currentSegment.setIsReversed == nil then
		return nil
	else
		return g_i18n:getText("action_fenceReverse")
	end
end

function ConstructionBrushNewFence:cancel()
	self:onButtonSecondary()
end

function ConstructionBrushNewFence:getButtonPrimaryText()
	if self.fence == nil then
		return nil
	else
		return self.currentSegment ~= nil and self.currentSegment:getStartPos() == nil and "$l10n_input_CONSTRUCTION_PLACE_POLE" or g_i18n:getText("action_fencePlaceSegment")
	end
end

function ConstructionBrushNewFence:getButtonSecondaryText()
	if self.fence == nil then
		return nil
	elseif self.snapEnd == nil then
		return self.currentSegment ~= nil and self.currentSegment:getStartPos() ~= nil and "$l10n_input_CONSTRUCTION_FINISH" or nil
	else
		return nil
	end
end

function ConstructionBrushNewFence:getButtonTertiaryText()
	if self.fence == nil then
		return nil
	elseif self.canToggleParallelSnapping then
		return string.format(g_i18n:getText("input_CONSTRUCTION_SNAP"), g_i18n:getText(self.parallelSnappingEnabled and "ui_on" or "ui_off"))
	else
		return nil
	end
end

function ConstructionBrushNewFence:getButtonSnappingText()
	if self.fence == nil then
		return nil
	else
		return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
	end
end

function ConstructionBrushNewFence:getButtonFourthText()
	return #self.segmentIds > 0 and "$l10n_action_deleteLastSegment" or nil
end
