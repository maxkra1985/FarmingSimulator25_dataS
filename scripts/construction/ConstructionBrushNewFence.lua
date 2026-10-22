ConstructionBrushNewFence = {}
local ConstructionBrushNewFence_mt = Class(ConstructionBrushNewFence, ConstructionBrush)
ConstructionBrushNewFence.ERROR = { MININUM_LENGTH = 100, MINIMUM_ANGLE = 101, MAXIMUM_ANGLE = 102, COLLISION = 103, NOT_ENOUGH_MONEY = 104, CANNOT_BE_PLACED_HERE = 105 }
ConstructionBrushNewFence.ERROR_MESSAGES = { [ConstructionBrushNewFence.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort", [ConstructionBrushNewFence.ERROR.MINIMUM_ANGLE] = "ui_construction_cornerAngleTooLarge", [ConstructionBrushNewFence.ERROR.MAXIMUM_ANGLE] = "ui_construction_terrainTooSteep", [ConstructionBrushNewFence.ERROR.COLLISION] = "ui_construction_collidesWithItem", [ConstructionBrushNewFence.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney", [ConstructionBrushNewFence.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere" }
ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE = { [FenceSegment.ERROR_TOO_SHORT] = "ui_construction_distanceTooShort", [FenceSegment.ERROR_TOO_STEEP] = "ui_construction_terrainTooSteep" }
ConstructionBrushNewFence.STATUS = { SUCCESS = 0, CANCELLED = 1 }
ConstructionBrushNewFence.MINIMUM_LENGTH = 0.5
ConstructionBrushNewFence.CORNER_ANGLE_SNAP_TOLERANCE = 0.3490658503988659
ConstructionBrushNewFence.POLE_CONNECTION_DISTANCE = 0.5
ConstructionBrushNewFence.SNAP_DISTANCE = 0.4
ConstructionBrushNewFence.LAST_SNAPPING_STATE = false
ConstructionBrushNewFence.RAISED_SNAP_PICK_RADIUS = 1.5
ConstructionBrushNewFence.SNAP_END_TOLERANCE = 0.1
ConstructionBrushNewFence.SNAP_RESULT = { NONE = 0, SNAPPED = 1, CORNER_ANGLE_TOO_LARGE = 2 }
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
	self.cornerAngleTooLarge = false
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
function ConstructionBrushNewFence:setFinishCheckCallback(func)
	self.finishCheckCallbackFunc = func
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
	self.cornerAngleTooLarge = false
	local x, y, z = self.cursor:getHitTerrainPosition()
	if x == nil then
		return x, y, z, false
	end
	local metadata = self.fence:getSegmentTemplateById(self.templateId)
	if not metadata.snapDistance then
		local snapDistance = self.currentSegment ~= nil and self.currentSegment:getMinimumPanelLength() or 2
	end
	local maxCornerAngle = metadata.extending ~= nil and metadata.extending.maxCornerAngle or nil
	local currentSegmentStartX = nil
	local currentSegmentStartY = nil
	local currentSegmentStartZ = nil
	if self.currentSegment ~= nil then
		local startX, startY, startZ = self.currentSegment:getStartPos()
		currentSegmentStartX = startX
		currentSegmentStartY = startY
		currentSegmentStartZ = startZ
	end
	local hasStartPosition = currentSegmentStartX ~= nil
	if self.hasSnapPositions and hasStartPosition then
		local endPos = self.snapEnd
		if MathUtil.vector3Length(endPos[1] - x, endPos[2] - y, endPos[3] - z) < snapDistance then
			return endPos[1], endPos[2], endPos[3], true
		end
	end
	local pickX, pickY, pickZ = self:getRaisedPickPosition(y)
	if pickX ~= nil then
		local pickGroundY = getTerrainHeightAtWorldPos(g_terrainNode, pickX, 0, pickZ)
		local pickRadius = math.min(ConstructionBrushNewFence.RAISED_SNAP_PICK_RADIUS, snapDistance)
		local pickResult, pickSnapX, pickSnapY, pickSnapZ, pickSnapSegment = self:getTargetSnapPosition(pickX, pickY, pickZ, pickGroundY, pickRadius)
		if pickResult == ConstructionBrushNewFence.SNAP_RESULT.SNAPPED then
			return pickSnapX, pickSnapY, pickSnapZ, true, pickSnapSegment
		end
		if pickResult == ConstructionBrushNewFence.SNAP_RESULT.CORNER_ANGLE_TOO_LARGE then
			self.cornerAngleTooLarge = true
			return x, y, z, false
		end
	end
	local groundResult, groundSnapX, groundSnapY, groundSnapZ, groundSnapSegment = self:getTargetSnapPosition(x, y, z, y, snapDistance)
	if groundResult == ConstructionBrushNewFence.SNAP_RESULT.SNAPPED then
		return groundSnapX, groundSnapY, groundSnapZ, true, groundSnapSegment
	end
	if groundResult == ConstructionBrushNewFence.SNAP_RESULT.CORNER_ANGLE_TOO_LARGE then
		self.cornerAngleTooLarge = true
		return x, y, z, false
	end
	local cornerDistance = 0
	if maxCornerAngle ~= nil and hasStartPosition then
		cornerDistance = MathUtil.vector2Length(x - currentSegmentStartX, z - currentSegmentStartZ)
	end
	if 0 < cornerDistance then
		local currentSegmentDirX, currentSegmentDirZ = MathUtil.vector2Normalize(x - currentSegmentStartX, z - currentSegmentStartZ)
		local angle, refDirX, refDirZ = self:getCornerAngleAtPole(currentSegmentStartX, currentSegmentStartY, currentSegmentStartZ, currentSegmentDirX, currentSegmentDirZ, false)
		if angle ~= nil and maxCornerAngle < math.abs(angle) then
			if ConstructionBrushNewFence.CORNER_ANGLE_SNAP_TOLERANCE < math.abs(angle) - maxCornerAngle then
				self.cornerAngleTooLarge = true
				return x, y, z, false
			else
				local clampedAngle = math.clamp(angle, -maxCornerAngle, maxCornerAngle)
				local cos = math.cos(clampedAngle)
				local sin = math.sin(clampedAngle)
				local cx = refDirX * cos - refDirZ * sin
				local cz = refDirX * sin + refDirZ * cos
				cx, cz = MathUtil.vector2Normalize(cx, cz)
				local clampedNewX = currentSegmentStartX + cx * cornerDistance
				local clampedNewZ = currentSegmentStartZ + cz * cornerDistance
				local clampedNewY = getTerrainHeightAtWorldPos(g_terrainNode, clampedNewX, 0, clampedNewZ)
				return clampedNewX, clampedNewY, clampedNewZ, true
			end
		end
	end
	if self.parallelSnappingEnabled then
		local parallelSnapCheckDistance = metadata.parallelSnapping.checkDistance
		local parallelSnapDistance = metadata.parallelSnapping.snapDistance
		local snappedPole, _distance, snappedPoleX, snappedPoleY, snappedPoleZ = self.fence:getPoleNear(x, y, z, parallelSnapCheckDistance)
		local snappedSegment = nil
		local dx = nil
		local dz = nil
		if snappedPole ~= nil then
			snappedSegment = self.fence:getSegmentFromNode(snappedPole)
			if snappedSegment ~= nil then
				dx, dz = snappedSegment:getDirectionXZ()
			end
		end
		if dx ~= nil and not hasStartPosition then
			self.parallelSnappingSegment = snappedSegment
			if self.currentSegment ~= nil then
				self.currentSegment:setParallelSnappingSegment(snappedSegment)
			end
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
			if maxCornerAngle == 0 then
				local _, _, _, _, _, _, isStartPole, isEndPole = self.fence:getPoleNear(x, y, z, snapDistance)
				if distancePole < snapDistance and (isStartPole or isEndPole) then
					return snappedPoleX, snappedPoleY, snappedPoleZ, true, snappedSegment
				end
			end
			local otherRowPole, _distance, otherRowPoleX, otherRowPoleY, otherRowPoleZ = self.fence:getPoleNear(snapX, snapY, snapZ, snapDistance)
			if otherRowPole then
				return otherRowPoleX, otherRowPoleY, otherRowPoleZ, true
			else
				return snapX, snapY, snapZ, true
			end
		end
		if self.parallelSnappingSegment ~= nil and hasStartPosition then
			local alignDirX, alignDirZ = self.parallelSnappingSegment:getDirectionXZ()
			if alignDirX ~= nil then
				local targetX, targetZ = MathUtil.projectOnLine(x, z, currentSegmentStartX, currentSegmentStartZ, alignDirX, alignDirZ)
				local targetY = getTerrainHeightAtWorldPos(g_terrainNode, targetX, 0, targetZ)
				return targetX, targetY, targetZ, true
			end
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
function ConstructionBrushNewFence:getRaisedPickPosition(groundY)
	if self.currentSegment == nil then
		return nil
	end
	local pickHeight = self.currentSegment:getSnapPickHeight()
	if pickHeight == nil then
		return nil
	end
	local ray = self.cursor.ray
	if ray.dy == nil or 0 <= ray.dy then
		return nil
	end
	local pickY = groundY + pickHeight
	local rayDistance = (pickY - ray.y) / ray.dy
	if rayDistance <= 0 then
		return nil
	else
		local pickX = ray.x + ray.dx * rayDistance
		local pickZ = ray.z + ray.dz * rayDistance
		return pickX, pickY, pickZ
	end
end
function ConstructionBrushNewFence:getTargetSnapPosition(x, y, z, groundY, snapDistance)
	local metadata = self.fence:getSegmentTemplateById(self.templateId)
	local allowExtendingOnly = metadata.extending ~= nil and metadata.extending.allowExtendingOnly or nil
	local maxCornerAngle = metadata.extending ~= nil and metadata.extending.maxCornerAngle or nil
	local currentSegmentStartX = nil
	local currentSegmentStartZ = nil
	if self.currentSegment ~= nil then
		local startX, _, startZ = self.currentSegment:getStartPos()
		currentSegmentStartX = startX
		currentSegmentStartZ = startZ
	end
	local hasStartPosition = currentSegmentStartX ~= nil
	if self.currentSegment ~= nil then
		local snapX, snapY, snapZ = self.currentSegment:getSnapPosition(x, y, z, 0, 0, 0)
		local isSnapInRange = snapX ~= nil and MathUtil.vector3Length(snapX - x, snapY - y, snapZ - z) < snapDistance
		if isSnapInRange then
			if self:getIsSnappedCornerAngleTooLarge(snapX, snapY, snapZ, maxCornerAngle) then
				return ConstructionBrushNewFence.SNAP_RESULT.CORNER_ANGLE_TOO_LARGE
			else
				return ConstructionBrushNewFence.SNAP_RESULT.SNAPPED, snapX, snapY, snapZ
			end
		end
	end
	local pole, _, px, py, pz, _, isStartPole, isEndPole = self.fence:getPoleNear(x, groundY, z, snapDistance)
	if pole ~= nil and (not hasStartPosition or self.parallelSnappingSegment == nil) then
		local isCurrentStartPole = hasStartPosition and MathUtil.vector2Length(px - currentSegmentStartX, pz - currentSegmentStartZ) < 0.1
		local isAllowedPole = not allowExtendingOnly or isStartPole or isEndPole
		if not isCurrentStartPole and isAllowedPole then
			if self:getIsSnappedCornerAngleTooLarge(px, py, pz, maxCornerAngle) then
				return ConstructionBrushNewFence.SNAP_RESULT.CORNER_ANGLE_TOO_LARGE
			else
				local snappedTargetSegment = self.fence:getSegmentFromNode(pole)
				return ConstructionBrushNewFence.SNAP_RESULT.SNAPPED, px, py, pz, snappedTargetSegment
			end
		end
	end
	return ConstructionBrushNewFence.SNAP_RESULT.NONE
end
function ConstructionBrushNewFence:getIsSnappedCornerAngleTooLarge(endX, endY, endZ, maxCornerAngle)
	if maxCornerAngle == nil or maxCornerAngle <= 0 or self.currentSegment == nil then
		return false
	end
	local startX, startY, startZ = self.currentSegment:getStartPos()
	if startX == nil then
		return false
	end
	local distance = MathUtil.vector2Length(endX - startX, endZ - startZ)
	if distance <= 0 then
		return false
	else
		local dirX, dirZ = MathUtil.vector2Normalize(endX - startX, endZ - startZ)
		local startAngle = self:getCornerAngleAtPole(startX, startY, startZ, dirX, dirZ, false)
		if startAngle ~= nil and maxCornerAngle < math.abs(startAngle) then
			return true
		end
		local endAngle = self:getCornerAngleAtPole(endX, endY, endZ, dirX, dirZ, true)
		local isEndTooLarge = endAngle ~= nil and maxCornerAngle < math.abs(endAngle)
		return isEndTooLarge
	end
end
function ConstructionBrushNewFence:getCornerAngleAtPole(poleX, poleY, poleZ, dirX, dirZ, isEndPole)
	local bestAbsAngle = math.huge
	local bestAngle = nil
	local bestRefDirX = nil
	local bestRefDirZ = nil
	for _, segment in ipairs(self.fence:getSegments()) do
		local awayDirX, awayDirZ = self:getSegmentDirectionAwayFromPole(segment, poleX, poleZ)
		if awayDirX == nil then
			continue
		end
		local angle, refDirX, refDirZ = ConstructionBrushNewFence.getCornerAngle(dirX, dirZ, awayDirX, awayDirZ, isEndPole)
		if math.abs(angle) < bestAbsAngle then
			bestAbsAngle = math.abs(angle)
			bestAngle = angle
			bestRefDirX = refDirX
			bestRefDirZ = refDirZ
		end
	end
	local snapDirX, snapDirZ = self:getSnapTargetDirectionAtPole(poleX, poleY, poleZ)
	if snapDirX ~= nil then
		local angle, refDirX, refDirZ = ConstructionBrushNewFence.getCornerAngle(dirX, dirZ, snapDirX, snapDirZ, isEndPole)
		if math.abs(angle) < bestAbsAngle then
			bestAngle = angle
			bestRefDirX = refDirX
			bestRefDirZ = refDirZ
		end
	end
	return bestAngle, bestRefDirX, bestRefDirZ
end
function ConstructionBrushNewFence:getSegmentDirectionAwayFromPole(segment, poleX, poleZ)
	if segment == self.currentSegment or segment.parentBackup ~= nil then
		return nil
	end
	local segmentStartX, _, segmentStartZ = segment:getStartPos()
	local segmentEndX, _, segmentEndZ = segment:getEndPos()
	if segmentStartX == nil or segmentEndX == nil then
		return nil
	end
	local connectionDistance = ConstructionBrushNewFence.POLE_CONNECTION_DISTANCE
	local connectedAtStart = MathUtil.vector2Length(segmentStartX - poleX, segmentStartZ - poleZ) < connectionDistance
	local connectedAtEnd = MathUtil.vector2Length(segmentEndX - poleX, segmentEndZ - poleZ) < connectionDistance
	if not connectedAtStart and not connectedAtEnd then
		return nil
	end
	local otherEndX = segmentStartX
	local otherEndZ = segmentStartZ
	if connectedAtStart then
		otherEndX = segmentEndX
		otherEndZ = segmentEndZ
	end
	local distance = MathUtil.vector2Length(otherEndX - poleX, otherEndZ - poleZ)
	if distance <= 0 then
		return nil
	else
		local awayDirX, awayDirZ = MathUtil.vector2Normalize(otherEndX - poleX, otherEndZ - poleZ)
		return awayDirX, awayDirZ
	end
end
function ConstructionBrushNewFence:getSnapTargetDirectionAtPole(poleX, poleY, poleZ)
	if self.currentSegment == nil then
		return nil
	end
	local snapX, _, snapZ, dirX, dirZ = self.currentSegment:getSnapPosition(poleX, poleY, poleZ, 0, 0, 0)
	if snapX == nil or dirX == nil then
		return nil
	end
	if ConstructionBrushNewFence.POLE_CONNECTION_DISTANCE <= MathUtil.vector2Length(snapX - poleX, snapZ - poleZ) then
		return nil
	else
		return dirX, dirZ
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
	elseif self.cornerAngleTooLarge then
		self.currentSegment:setEndPos(x, y, z)
		self.currentSegment:updateMeshes()
		self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
		self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[ConstructionBrushNewFence.ERROR.MINIMUM_ANGLE]))
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
					return
				end
				if self:validateSegmentRestrictions() then
					self:validateFinishSegment()
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
	if not self:getIsLineClearOfRiceFields(sx, sz, x, z) then
		self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[ConstructionBrushNewFence.ERROR.COLLISION]))
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
function ConstructionBrushNewFence:validateSegmentRestrictions()
	local segment = self.currentSegment
	if segment == nil or segment.getCanBeBuilt == nil then
		return true
	end
	local canBeBuilt, warning = segment:getCanBeBuilt(g_localPlayer.farmId)
	if canBeBuilt then
		return true
	else
		self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
		if warning ~= nil then
			self.cursor:setErrorMessage(warning)
		end
		return false
	end
end
function ConstructionBrushNewFence:validateFinishSegment()
	local segment = self.currentSegment
	local hasFinishCheck = false
	if self.finishCheckCallbackFunc ~= nil then
		hasFinishCheck = self.hasSnapPositions
	end
	if not hasFinishCheck or segment == nil then
		return true
	end
	local endX, endY, endZ = segment:getEndPos()
	if endX == nil then
		return true
	end
	local snapEnd = self.snapEnd
	if ConstructionBrushNewFence.SNAP_END_TOLERANCE <= MathUtil.vector3Length(snapEnd[1] - endX, snapEnd[2] - endY, snapEnd[3] - endZ) then
		return true
	end
	local canFinish, warning = self.finishCheckCallbackFunc(segment)
	if canFinish then
		return true
	else
		self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
		if warning ~= nil then
			self.cursor:setErrorMessage(warning)
		end
		return false
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
			if self.cornerAngleTooLarge then
				return
			end
			if not self:validateCurrentSegment(x, z) then
				return
			end
			if not self:validateSegmentRestrictions() then
				return
			end
			if not self:validateFinishSegment() then
				return
			end
			if self.currentSegment:getLastError() ~= nil then
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
		if self.hasSnapPositions and MathUtil.vector3Length(self.snapEnd[1] - endX, self.snapEnd[2] - endY, self.snapEnd[3] - endZ) < ConstructionBrushNewFence.SNAP_END_TOLERANCE then
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
function ConstructionBrushNewFence.getCornerAngle(dirX, dirZ, awayDirX, awayDirZ, isEndPole)
	local refDirX = awayDirX
	local refDirZ = awayDirZ
	if not isEndPole then
		refDirX = -awayDirX
		refDirZ = -awayDirZ
	end
	local _, crossY, _ = MathUtil.crossProduct(dirX, 0, dirZ, refDirX, 0, refDirZ)
	local dot = MathUtil.dotProduct(refDirX, 0, refDirZ, dirX, 0, dirZ)
	local angle = math.atan2(crossY, dot)
	return angle, refDirX, refDirZ
end
