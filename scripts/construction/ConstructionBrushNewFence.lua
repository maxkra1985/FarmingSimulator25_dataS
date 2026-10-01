ConstructionBrushNewFence = {}
local ConstructionBrushNewFence_mt = Class(ConstructionBrushNewFence, ConstructionBrush)
ConstructionBrushNewFence.ERROR = { MININUM_LENGTH = 100, MINIMUM_ANGLE = 101, MAXIMUM_ANGLE = 102, COLLISION = 103, NOT_ENOUGH_MONEY = 104, CANNOT_BE_PLACED_HERE = 105 }
ConstructionBrushNewFence.ERROR_MESSAGES = { [ConstructionBrushNewFence.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort", [ConstructionBrushNewFence.ERROR.MINIMUM_ANGLE] = "ui_construction_cornerAngleTooLarge", [ConstructionBrushNewFence.ERROR.MAXIMUM_ANGLE] = "ui_construction_terrainTooSteep", [ConstructionBrushNewFence.ERROR.COLLISION] = "ui_construction_collidesWithItem", [ConstructionBrushNewFence.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney", [ConstructionBrushNewFence.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere" }
ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE = { [FenceSegment.ERROR_TOO_SHORT] = "ui_construction_distanceTooShort", [FenceSegment.ERROR_TOO_STEEP] = "ui_construction_terrainTooSteep" }
ConstructionBrushNewFence.STATUS = { SUCCESS = 0, CANCELLED = 1 }
ConstructionBrushNewFence.MINIMUM_LENGTH = 0.5
ConstructionBrushNewFence.MINIMUM_ANGLE = 0.5235987755982988
ConstructionBrushNewFence.SNAP_DISTANCE = 0.4
ConstructionBrushNewFence.LAST_SNAPPING_STATE = false
function ConstructionBrushNewFence.new(subclass_mt, cursor)
	local self = ConstructionBrushNewFence:superClass().new(subclass_mt or ConstructionBrushNewFence_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsSecondaryButton = true
	self.supportsTertiaryButton = true
	self.supportsFourthButton = true
	self.supportsPrimaryAxis = true
	self.supportsSecondaryAxis = true
	self.needsOverlayReset = {}
	self.segmentIds = {}
	self.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
	self.isValidating = false
	self.canToggleParallelSnapping = false
	self.parallelSnappingEnabled = false
	self.doFindPlaceable = false
	self.supportsSnapping = true
	self.snappingActive = ConstructionBrushNewFence.LAST_SNAPPING_STATE
	self.snappingAngleDeg = 7.5
	self.snappingSize = 0.25
	self.overlappingNodes = {}
	local i3dNode = g_i3DManager:loadI3DFile("data/shared/visualization/fenceSnapMarker.i3d", false, false)
	if i3dNode ~= 0 then
		self.snapMarkerStart = getChildAt(i3dNode, 0)
		self.snapMarkerEnd = clone(self.snapMarkerStart, false, false, false)
		link(getRootNode(), self.snapMarkerStart)
		link(getRootNode(), self.snapMarkerEnd)
		setShaderParameter(self.snapMarkerStart, "emitColor", 0, 1, 0, 1, false)
		setShaderParameter(self.snapMarkerEnd, "emitColor", 0, 1, 0, 1, false)
		setVisibility(self.snapMarkerStart, false)
		setVisibility(self.snapMarkerEnd, false)
		delete(i3dNode)
	end
	return self
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
		Logging.error("ConstructionBrushNewFence:setFenceParentObject(): parent object does not have a 'getFence' function")
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
		return
	end
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
function ConstructionBrushNewFence:setFinishCallback(func)
	self.finishCallbackFunc = func
end
function ConstructionBrushNewFence:setValidateCallback(func)
	self.validateCallbackFunc = func
end
function ConstructionBrushNewFence:setSegmentTemplate(id)
	self.templateId = id
	self.parallelSnappingEnabled = false
	self.canToggleParallelSnapping = false
	local metadata = self.fence:getSegmentTemplateById(self.templateId)
	if metadata.parallelSnapping ~= nil then
		self.canToggleParallelSnapping = metadata.parallelSnapping.canToggle
		if not self.canToggleParallelSnapping then
			self.parallelSnappingEnabled = true
		end
	end
	self:setInputTextDirty()
	local sx = nil
	local sy = nil
	local sz = nil
	if self.currentSegment ~= nil then
		sx, sy, sz = self.currentSegment:getStartPos()
		self.currentSegment:delete()
		self.currentSegment = nil
	end
	self.currentSegment = self.fence:createNewSegment(self.templateId)
	self.currentSegment:setParallelSnappingSegment(self.parallelSnappingSegment)
	if sx ~= nil then
		self.currentSegment:setStartPos(sx, sy, sz)
	end
end
function ConstructionBrushNewFence:canCancel()
	return self.fenceParentObject ~= nil and self.currentSegment ~= nil
end
function ConstructionBrushNewFence:acquirePlaceable()
	if self.storeItem == nil then
		Logging.warning("ConstructionBrushNewFence has no store item set")
	else
		self.fenceParentObject = self:findPlaceable()
		if self.fenceParentObject ~= nil then
			self:initFence()
		else
			local data = BuyPlaceableData.new()
			data:setStoreItem(self.storeItem)
			data:setPosition(0, PlacementUtil.NETHER_HEIGHT - 1, 0)
			data:setRotation(0, 0, 0)
			data:setConfigurations({})
			data:setOwnerFarmId(AccessHandler.EVERYONE)
			data:setDisplacementCosts(0)
			data:setModifyTerrain(false)
			data:setIsFreeOfCharge(true)
			g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
			g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(data))
		end
		self:setInputTextDirty()
	end
end
function ConstructionBrushNewFence:findPlaceable()
	local configXMLFilename = self.storeItem.xmlFilename
	local existingPlaceableInstance = g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(configXMLFilename)
	return existingPlaceableInstance
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
		Logging.xmlError(self.fenceParentObject.configFileName, "Fence parent object is missing 'getFence' function, check placeableType")
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
function ConstructionBrushNewFence:getSnappedCursorPosition()
	local x, y, z = self.cursor:getHitTerrainPosition()
	if x == nil then
		return x, y, z, false
	end
	local metadata = self.fence:getSegmentTemplateById(self.templateId)
	if not metadata.snapDistance then
		local snapDistance = self.currentSegment ~= nil and self.currentSegment:getMinimumPanelLength() or 2
	end
	local allowExtendingOnly = metadata.extending ~= nil and metadata.extending.allowExtendingOnly or nil
	local maxCornerAngle = metadata.extending ~= nil and metadata.extending.maxCornerAngle or nil
	local currentSegmentStartX = nil
	local currentSegmentStartY = nil
	local currentSegmentStartZ = nil
	if self.currentSegment ~= nil then
		currentSegmentStartX, currentSegmentStartY, currentSegmentStartZ = self.currentSegment:getStartPos()
	end
	local hasStartPosition = currentSegmentStartX ~= nil
	if self.hasSnapPositions and hasStartPosition then
		local endPos = self.snapEnd
		if MathUtil.vector3Length(endPos[1] - x, endPos[2] - y, endPos[3] - z) < snapDistance then
			return endPos[1], endPos[2], endPos[3], true
		end
	end
	local pole, _distance, px, py, pz, _segmentId, isStartPole, isEndPole = self.fence:getPoleNear(x, y, z, snapDistance)
	if pole ~= nil and (not hasStartPosition or self.parallelSnappingSegment == nil) then
		local ignore = false
		if hasStartPosition and MathUtil.vector2Length(px - currentSegmentStartX, pz - currentSegmentStartZ) < 0.1 then
			ignore = true
		end
		if not ignore then
			local snappedTargetSegment = self.fence:getSegmentFromNode(pole)
			if not allowExtendingOnly or isStartPole or isEndPole then
				return px, py, pz, true, snappedTargetSegment
			end
		end
	end
	if maxCornerAngle ~= nil and self.currentSegment ~= nil then
		local ex = x
		local ez = z
		if hasStartPosition and ex ~= nil then
			local lastPole, _distance, _px, _py, _pz, lastSegmentId, _isStartPole, _isEndPole = self.fence:getPoleNear(currentSegmentStartX, currentSegmentStartY, currentSegmentStartZ, 0.5)
			if lastPole ~= nil then
				local segment = self.fence:getSegmentById(lastSegmentId)
				if segment ~= nil then
					local segmentStartX, _, segmentStartZ = segment:getStartPos()
					local segmentEndX, _, segmentEndZ = segment:getEndPos()
					local distance = MathUtil.vector2Length(ex - currentSegmentStartX, ez - currentSegmentStartZ)
					local currentSegmentDirX, currentSegmentDirZ = MathUtil.vector2Normalize(ex - currentSegmentStartX, ez - currentSegmentStartZ)
					local lastSegmentDirX, lastSegmentDirZ = MathUtil.vector2Normalize(segmentEndX - segmentStartX, segmentEndZ - segmentStartZ)
					local cosMax = math.cos(maxCornerAngle)
					local forwardDot = MathUtil.dotProduct(lastSegmentDirX, 0, lastSegmentDirZ, currentSegmentDirX, 0, currentSegmentDirZ)
					local backwardDot = MathUtil.dotProduct(lastSegmentDirX, 0, lastSegmentDirZ, -currentSegmentDirX, 0, -currentSegmentDirZ)
					local forwardOK = cosMax <= forwardDot
					local backwardOK = cosMax <= backwardDot
					local allowed = forwardOK or backwardOK
					if not allowed then
						local ax = currentSegmentDirX
						local az = currentSegmentDirZ
						if forwardDot < 0 then
							ax = -currentSegmentDirX
							az = -currentSegmentDirZ
						end
						local _, crossY, _ = MathUtil.crossProduct(ax, 0, az, lastSegmentDirX, 0, lastSegmentDirZ)
						local dot = MathUtil.dotProduct(ax, 0, az, lastSegmentDirX, 0, lastSegmentDirZ)
						local angle = math.atan2(crossY, dot)
						local clampedAngle = math.clamp(angle, -maxCornerAngle, maxCornerAngle)
						if 0 < backwardDot then
							clampedAngle = clampedAngle + 3.141592653589793
						end
						local cos = math.cos(clampedAngle)
						local sin = math.sin(clampedAngle)
						local cx = lastSegmentDirX * cos - lastSegmentDirZ * sin
						local cz = lastSegmentDirX * sin + lastSegmentDirZ * cos
						cx, cz = MathUtil.vector2Normalize(cx, cz)
						local clampedNewX = currentSegmentStartX + cx * distance
						local clampedNewZ = currentSegmentStartZ + cz * distance
						local clampedNewY = getTerrainHeightAtWorldPos(g_terrainNode, clampedNewX, 0, clampedNewZ)
						return clampedNewX, clampedNewY, clampedNewZ, true
					end
				end
			end
		end
	end
	if self.parallelSnappingEnabled then
		local parallelSnapCheckDistance = metadata.parallelSnapping.checkDistance
		local parallelSnapDistance = metadata.parallelSnapping.snapDistance
		local snappedPole, _distance, snappedPoleX, snappedPoleY, snappedPoleZ = self.fence:getPoleNear(x, y, z, parallelSnapCheckDistance)
		if snappedPole ~= nil and not hasStartPosition then
			local snappedSegment = self.fence:getSegmentFromNode(snappedPole)
			self.parallelSnappingSegment = snappedSegment
			if self.currentSegment ~= nil then
				self.currentSegment:setParallelSnappingSegment(snappedSegment)
			end
			local startX, _, startZ = snappedSegment:getStartPos()
			local endX, _, endZ = snappedSegment:getEndPos()
			local dx, dz = MathUtil.vector2Normalize(endX - startX, endZ - startZ)
			local snapLineX = snappedPoleX
			local snapLineZ = snappedPoleZ
			if not self.snappingActive then
				snapLineX, snapLineZ = MathUtil.projectOnLine(x, z, snappedPoleX, snappedPoleZ, dx, dz)
			end
			local x1 = -dz * parallelSnapDistance + snapLineX
			local z1 = dx * parallelSnapDistance + snapLineZ
			local x2 = dz * parallelSnapDistance + snapLineX
			local z2 = -dx * parallelSnapDistance + snapLineZ
			local distance1 = MathUtil.vector2Length(x1 - x, z1 - z)
			local distance2 = MathUtil.vector2Length(x2 - x, z2 - z)
			local distancePole = MathUtil.vector2Length(snappedPoleX - x, snappedPoleZ - z)
			local snapX = nil
			local snapZ = nil
			if distance1 < distance2 then
				snapX = x1
				snapZ = z1
			else
				snapX = x2
				snapZ = z2
			end
			local snapY = getTerrainHeightAtWorldPos(g_terrainNode, snapX, 0, snapZ)
			if maxCornerAngle == 0 and (distancePole < snapDistance and (isStartPole or isEndPole)) then
				return snappedPoleX, snappedPoleY, snappedPoleZ, true, snappedSegment
			end
			local otherRowPole, _distance, otherRowPoleX, otherRowPoleY, otherRowPoleZ = self.fence:getPoleNear(snapX, snapY, snapZ, snapDistance)
			if otherRowPole then
				return otherRowPoleX, otherRowPoleY, otherRowPoleZ, true
			else
				return snapX, snapY, snapZ, true
			end
		end
		if self.parallelSnappingSegment ~= nil and hasStartPosition then
			local alignSegment = self.parallelSnappingSegment
			local startX, _, startZ = alignSegment:getStartPos()
			local endX, _, endZ = alignSegment:getEndPos()
			local dx, dz = MathUtil.vector2Normalize(endX - startX, endZ - startZ)
			local targetX, targetZ = MathUtil.projectOnLine(x, z, currentSegmentStartX, currentSegmentStartZ, dx, dz)
			local targetY = getTerrainHeightAtWorldPos(g_terrainNode, targetX, 0, targetZ)
			return targetX, targetY, targetZ, true
		end
		self.parallelSnappingSegment = nil
		if self.currentSegment ~= nil then
			self.currentSegment:setParallelSnappingSegment(nil)
		end
	end
	if self.snappingActive then
		x = MathUtil.snapValue(x, self.snappingSize)
		z = MathUtil.snapValue(z, self.snappingSize)
		return x, y, z, true
	else
		return x, y, z, false
	end
end
function ConstructionBrushNewFence:getLimitedSnappedCursorPosition()
	local x, y, z, snapped, segment = self:getSnappedCursorPosition()
	return x, y, z, snapped, segment
end
function ConstructionBrushNewFence:getPrice(length)
	local price = nil
	if self.gateIndex ~= nil then
		price = self.storeItem.price
		return price
	else
		if length == nil then
			length = self.fenceParentObject:getSegmentLength(self.fenceParentObject:getPreviewSegment())
		end
		price = length * self.storeItem.price
		return price
	end
end
function ConstructionBrushNewFence:verifyPreview()
	return nil
end
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
	end
	if self.fence == nil then
		return
	end
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
	local x, y, z, isSnapped, _snappedSegment = self:getLimitedSnappedCursorPosition()
	if self.currentSegment == nil then
		if isSnapped then
			self.cursor:setPosition(x, y, z)
		end
		return
	end
	self.currentSegment:draw()
	if self.hasSnapPositions and self.currentSegment:getStartPos() == nil then
		self.currentSegment:setStartPos(self.snapStart[1], self.snapStart[2], self.snapStart[3])
	end
	if x == nil then
		return
	end
	local err = self:verifyAccess(x, y, z)
	if err ~= nil then
		self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
		self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[err] or ConstructionBrush.ERROR_MESSAGES[err]))
	else
		if isSnapped and self.currentSegment:getStartPos() == nil then
			self.cursor:setPosition(x, y, z)
		end
		if self:validateCurrentSegment(x, z) then
			self.currentSegment:setEndPos(x, y, z)
			if self.currentSegment:updateMeshes() then
				self.currentSegment:update()
				table.clear(self.overlappingNodes)
				self.currentSegment:checkOverlap(self.overlappingNodes)
				for overlappingNode in pairs(self.overlappingNodes) do
					local segment = self.fence:getSegmentFromNode(overlappingNode)
					if segment == nil then
						continue
					end
					local segmentPart = segment:getSegmentPartFromNode(overlappingNode)
					if segmentPart == nil then
						continue
					end
					renderShapeOutline(segmentPart, true)
				end
				if next(self.overlappingNodes) ~= nil then
					self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
					self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[ConstructionBrushNewFence.ERROR.COLLISION]))
				end
			else
				local segmentError = self.currentSegment:getLastError()
				if segmentError ~= nil then
					self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
					self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE[segmentError]))
				end
			end
		end
	end
end
function ConstructionBrushNewFence:draw()
	if g_isDevelopmentVersion and (self.fenceParentObject ~= nil and self.fenceParentObject.configFileName ~= nil) then
		local storeItemNameCleaned = string.gsub(self.fenceParentObject.configFileName, getUserProfileAppPath(), "")
		renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, storeItemNameCleaned)
	end
end
function ConstructionBrushNewFence:validateCurrentSegment(x, z)
	if self.currentSegment == nil then
		return false
	end
	local sx, _, sz = self.currentSegment:getStartPos()
	if sx == nil then
		return false
	end
	if not g_farmlandManager:getIsOwnedByFarmAlongLine(g_localPlayer.farmId, sx, sz, x, z) then
		self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.LAND_UNOWNED]))
		return false
	end
	local price = self.currentSegment:getPrice()
	if g_currentMission:getMoney(g_localPlayer.farmId) < price then
		self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[ConstructionBrushNewFence.ERROR.NOT_ENOUGH_MONEY]))
		return false
	else
		if price ~= 0 then
			self.cursor:setMessage(g_i18n:formatMoney(price))
		end
		return true
	end
end
function ConstructionBrushNewFence:onButtonPrimary()
	if self.isValidating then
		return
	end
	if self.fenceParentObject == nil then
		return
	end
	if self.fence == nil then
		return
	end
	if self.currentSegment == nil then
		self.currentSegment = self.fence:createNewSegment(self.templateId)
		self.currentSegment:setParallelSnappingSegment(self.parallelSnappingSegment)
	end
	local x, y, z, _snapped, _segment = self:getLimitedSnappedCursorPosition()
	if x == nil then
		return
	end
	local err = self:verifyAccess(x, y, z)
	if err ~= nil then
		return
	else
		if self.currentSegment:getStartPos() == nil then
			self.currentSegment:setStartPos(x, y, z)
		else
			if not self:validateCurrentSegment(x, z) then
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
function ConstructionBrushNewFence:finish(status)
	self.currentSegment = nil
	self.parallelSnappingSegment = nil
	if self.finishCallbackFunc ~= nil then
		local callback = self.finishCallbackFunc
		self.finishCallbackFunc = nil
		callback(status)
	end
end
function ConstructionBrushNewFence:onServerCreatedFenceCallback(statusCode, segmentId, endX, endY, endZ)
	if statusCode ~= FenceNewSegmentEvent.STATUS_CODE.SUCCESS then
		return
	else
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
			if self.validateCallbackFunc ~= nil then
				self.isValidating = true
				self.validateCallbackFunc(function(success)
					self.isValidating = false
					if success then
						self:finish(ConstructionBrushNewFence.STATUS.SUCCESS)
					else
						self:deleteLastSeqment()
					end
				end)
				return
			else
				self:finish(ConstructionBrushNewFence.STATUS.SUCCESS)
				return
			end
		end
		self:createNextSegment(endX, endY, endZ)
	end
end
function ConstructionBrushNewFence:deleteLastSeqment()
	if self.fence == nil then
		return
	else
		local lastSegmentId = self.segmentIds[#self.segmentIds]
		local lastSegment = self.fence:getSegmentById(lastSegmentId)
		if lastSegment ~= nil then
			local x, y, z = lastSegment:getStartPos()
			g_messageCenter:subscribeOneshot(FenceRequestDeleteSegmentEvent, function(success)
				if self.currentSegment ~= nil then
					self.currentSegment:delete()
					self.currentSegment = nil
				end
				if g_server == nil then
					lastSegment:delete()
				end
				table.removeElement(self.segmentIds, lastSegmentId)
				self:createNextSegment(x, y, z)
			end)
			g_client:getServerConnection():sendEvent(FenceRequestDeleteSegmentEvent.new(self.fenceParentObject, lastSegmentId))
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
	if self.snapEnd ~= nil then
		YesNoDialog.show(function(yes)
			if yes then
				self:deactivate()
			end
		end, nil, g_i18n:getText("ui_construction_cancelCustomFence"))
	else
		if self.currentSegment ~= nil then
			self.currentSegment:delete()
			self.currentSegment = nil
			self.parallelSnappingSegment = nil
			self:setInputTextDirty()
		end
	end
end
function ConstructionBrushNewFence:onButtonTertiary()
	if not self.canToggleParallelSnapping then
		return
	else
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
function ConstructionBrushNewFence:onAxisPrimary(inputValue)
	if self.fence == nil then
		return
	end
	local templates = self.fence:getSegmentTemplates()
	if #templates == 1 then
		return
	else
		local currentIndex = table.find(templates, self.templateId)
		local newIndex = 1 + (currentIndex - 1 + inputValue) % #templates
		local newTemplateId = templates[newIndex]
		self:setSegmentTemplate(newTemplateId)
		self:setInputTextDirty()
	end
end
function ConstructionBrushNewFence:getAxisPrimaryText()
	if self.fence == nil then
		return
	end
	local templates = self.fence:getSegmentTemplates()
	if 1 < #templates then
		local currentIndex = table.find(templates, self.templateId)
		return string.format("%s (%d/%d)", g_i18n:getText("action_fenceSwitchSegmentType"), currentIndex, #templates)
	else
		return nil
	end
end
function ConstructionBrushNewFence:onAxisSecondary(inputValue)
	if self.currentSegment ~= nil and self.currentSegment.setIsReversed ~= nil then
		self.currentSegment:setIsReversed(not self.currentSegment:getIsReversed())
	end
end
function ConstructionBrushNewFence:getAxisSecondaryText()
	if self.currentSegment ~= nil and self.currentSegment.setIsReversed ~= nil then
		return g_i18n:getText("action_fenceReverse")
	end
	return nil
end
function ConstructionBrushNewFence:cancel()
	self:onButtonSecondary()
end
function ConstructionBrushNewFence:getButtonPrimaryText()
	if self.fence == nil then
		return nil
	elseif self.currentSegment ~= nil and self.currentSegment:getStartPos() == nil then
		return "$l10n_input_CONSTRUCTION_PLACE_POLE"
	else
		return g_i18n:getText("action_fencePlaceSegment")
	end
end
function ConstructionBrushNewFence:getButtonSecondaryText()
	if self.fence == nil then
		return nil
	elseif self.snapEnd == nil then
		if self.currentSegment ~= nil and self.currentSegment:getStartPos() ~= nil then
			return "$l10n_input_CONSTRUCTION_FINISH"
		end
		return nil
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
	if 0 < #self.segmentIds then
		return "$l10n_action_deleteLastSegment"
	else
		return nil
	end
end
