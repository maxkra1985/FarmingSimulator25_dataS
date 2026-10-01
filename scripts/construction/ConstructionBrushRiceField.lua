ConstructionBrushRiceField = {}
local ConstructionBrushRiceField_mt = Class(ConstructionBrushRiceField, ConstructionBrush)
ConstructionBrushRiceField.ERROR = { MININUM_LENGTH = 1, COLLISION = 2, NOT_ENOUGH_MONEY = 3, CANNOT_BE_PLACED_HERE = 4 }
ConstructionBrushRiceField.ERROR_MESSAGES = { [ConstructionBrushRiceField.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort", [ConstructionBrushRiceField.ERROR.COLLISION] = "ui_construction_collidesWithItem", [ConstructionBrushRiceField.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney", [ConstructionBrushRiceField.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere" }
ConstructionBrushRiceField.HEIGHT_CHANGE_INCREMENT = 0.25
function ConstructionBrushRiceField.new(subclass_mt, cursor)
	local self = ConstructionBrushRiceField:superClass().new(subclass_mt or ConstructionBrushRiceField_mt, cursor)
	self.overlapCollisionMask = CollisionFlag.WATER + CollisionFlag.PLACEMENT_BLOCKING
	self.supportsPrimaryButton = true
	self.supportsSecondaryButton = true
	self.supportsTertiaryButton = true
	self.supportsPrimaryAxis = true
	self.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
	self.parallelSnappingEnabled = false
	self.doFindPlaceable = false
	self.supportsSnapping = true
	self.snappingActive = ConstructionBrushRiceField.LAST_SNAPPING_STATE
	self.minDistanceToExistingFields = 3
	self.isVertexValid = false
	self.pendingCreation = false
	self.heightMapUnitSize = getTerrainHeightmapUnitSize(g_terrainNode)
	self.lineVisualization = Line3D.new()
	self.debugBox = DebugBox.new()
	return self
end
function ConstructionBrushRiceField:delete()
	ConstructionBrushRiceField:superClass().delete(self)
	self.doFindPlaceable = false
	self.lineVisualization:delete()
end
function ConstructionBrushRiceField:activate()
	ConstructionBrushRiceField:superClass().activate(self)
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	self.cursor:setShapeSize(0.5)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
	self.cursor:setTerrainOnly(true)
	self:acquirePlaceable()
end
function ConstructionBrushRiceField:deactivate()
	self.lineVisualization:clearVisualization()
	self:releasePlaceable()
	self.doFindPlaceable = false
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT, nil)
	ConstructionBrushRiceField:superClass().deactivate(self)
end
function ConstructionBrushRiceField:setFilename(xmlFilename)
	if not self.isActive then
		self.xmlFilename = xmlFilename
	end
end
function ConstructionBrushRiceField:setParameters(filename)
	self:setFilename(filename)
end
function ConstructionBrushRiceField:setStoreItem(storeItem)
	if not self.isActive then
		self.storeItem = storeItem
	end
end
function ConstructionBrushRiceField:canCancel()
	return self.currentField ~= nil and 0 < self.currentField.polygon:getNumVertices()
end
function ConstructionBrushRiceField:acquirePlaceable()
	if self.xmlFilename == nil then
		Logging.warning("Rice Field brush has no placeable set")
	else
		self.placeable = self:findPlaceable()
		self:setInputTextDirty()
		if self.placeable == nil then
			local data = BuyPlaceableData.new()
			local storeItem = g_storeManager:getItemByXMLFilename(self.xmlFilename)
			data:setStoreItem(storeItem)
			data:setPosition(0, 0, 0)
			data:setRotation(0, 0, 0)
			data:setConfigurations({})
			data:setOwnerFarmId(g_localPlayer.farmId)
			data:setDisplacementCosts(0)
			data:setModifyTerrain(false)
			data:setIsFreeOfCharge(true)
			g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
			g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(data))
		end
	end
end
function ConstructionBrushRiceField:findPlaceable()
	local farmId = g_currentMission:getFarmId()
	local existingPlaceableInstance = g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.xmlFilename, farmId, true)
	return existingPlaceableInstance
end
function ConstructionBrushRiceField:onPlaceableCreated(errorCode, price)
	g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
	if errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
		self.cursor:setErrorMessage("Loading failed")
	else
		self.doFindPlaceable = true
	end
end
function ConstructionBrushRiceField:releasePlaceable()
	if self.placeable ~= nil then
		if not self.placeable:getHasValidFields() then
			g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.placeable, true, false, false))
		end
		self.placeable = nil
	end
end
function ConstructionBrushRiceField:getSnappedCursorPosition()
	local x, y, z = self.cursor:getHitTerrainPosition()
	if x ~= nil and self.snappingActive then
		local offset = 0
		x = MathUtil.snapValue(x, self.heightMapUnitSize) + 0
		z = MathUtil.snapValue(z, self.heightMapUnitSize) + 0
		if self.currentField ~= nil then
			y = self.currentField.height
			local vx, vz, lvx, lvz = self.placeable:getFirstAndLastVertex(self.currentField)
			local cvx = lvx or vx
			local cvz = lvz or vz
			if cvx ~= nil then
				if math.abs(cvz - z) < math.abs(cvx - x) then
					z = cvz
				else
					x = cvx
				end
				if lvx ~= nil then
					if math.abs(vx - x) < 2 then
						x = vx
					elseif math.abs(vz - z) < 2 then
						z = vz
					end
				end
			end
		end
	end
	return x, y, z, false
end
function ConstructionBrushRiceField:getLimitedSnappedCursorPosition()
	local x, y, z, snapped = self:getSnappedCursorPosition()
	return x, y, z, snapped
end
function ConstructionBrushRiceField:update(dt)
	ConstructionBrushRiceField:superClass().update(self, dt)
	self.cursor:setMessage("")
	self.lineVisualization:clearVisualization()
	self.finalVertexX = nil
	self.finalVertexZ = nil
	if self.currentField ~= nil then
		local numEdges = self.currentField.polygon:getNumEdges()
		local height = self.currentField.height + 0.05
		local canFinish = self.placeable:getCanFinish(self.currentField, self.snappingActive)
		if canFinish then
			local fvx, fvz, lvx, lvz = self.placeable:getFirstAndLastVertex(self.currentField)
			self.lineVisualization:visualizeLine(lvx, height, lvz, fvx, height, fvz, false, Color.PRESETS.GREEN)
		elseif 2 <= numEdges then
			local fvx, fvz, lvx, lvz = self.placeable:getFirstAndLastVertex(self.currentField)
			local getIsNewVertexValid = function(x, z)
				for _, x1, z1, x2, z2 in self.currentField.polygon:iteratorEdges() do
					if (x1 ~= x or z1 ~= z) and (x2 ~= x or z2 ~= z) then
						if MathUtil.getAreLineSegmentsIntersecting(x1, z1, x2, z2, fvx, fvz, x, z, true) then
							return false
						end
						if MathUtil.getAreLineSegmentsIntersecting(x1, z1, x2, z2, lvx, lvz, x, z, true) then
							return false
						end
					end
				end
				if not self.placeable:getCanAddVertex(self.currentField, x, z) then
					return false
				else
					return true
				end
			end
			local getFinalVertex = function()
				local ix = fvx
				local iz = lvz
				if getIsNewVertexValid(ix, iz) then
					return ix, iz
				end
				ix = lvx
				iz = fvz
				if getIsNewVertexValid(ix, iz) then
					return ix, iz
				else
					return nil
				end
			end
			if self.snappingActive then
				local ix = fvx
				local iz = lvz
				if getIsNewVertexValid(ix, iz) then
					local x = ix
					local z = iz
				else
					ix = lvx
					iz = fvz
					if getIsNewVertexValid(ix, iz) then
						x = ix
						z = iz
					else
						x = nil
						z = nil
					end
				end
				if x ~= nil then
					self.lineVisualization:visualizeLine(x, height, z, fvx, height, fvz, false, Color.PRESETS.GREEN)
					self.lineVisualization:visualizeLine(x, height, z, lvx, height, lvz, false, Color.PRESETS.GREEN)
					self.finalVertexX = x
					self.finalVertexZ = z
				end
			end
		end
		for index, x1, z1, x2, z2 in self.currentField.polygon:iteratorEdges(nil, 1) do
			self.lineVisualization:visualizeLine(x1, height, z1, x2, height, z2, false, canFinish and Color.PRESETS.GREEN or Color.PRESETS.ORANGE)
		end
	end
	if self.doFindPlaceable then
		self.placeable = self:findPlaceable()
		if self.placeable == nil then
			return
		end
		self.doFindPlaceable = false
	end
	local x, y, z, _, _ = self:getLimitedSnappedCursorPosition()
	if x == nil then
		return
	end
	local err = self:verifyAccess(x, y, z)
	if err ~= nil then
		local message = g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[err])
		self.cursor:setErrorMessage(message)
	elseif self.placeable ~= nil then
		if self.currentField == nil and not self.placeable:getCanCreateNewField() then
			self.cursor:setErrorMessage(g_i18n:getText("ui_construction_maxNumberOfFieldsReached"))
			return
		end
		if self.currentField ~= nil then
			local canAdd, errorMessage = self.placeable:getCanAddVertex(self.currentField, x, z)
			if not canAdd then
				self.cursor:setErrorMessage(errorMessage)
				return
			end
			if self.currentField.polygon:getIsCircleIntersecting(x, z, 1) then
				return
			end
			local vx, vz, lvx, lvz = self.placeable:getFirstAndLastVertex(self.currentField)
			vx = lvx or vx
			vz = lvz or vz
			if vx ~= nil then
				local cx = (x + vx) / 2
				local cz = (z + vz) / 2
				local ry = MathUtil.getYRotationFromDirection(x - vx, z - vz)
				local width = MathUtil.vector2Length(x - vx, z - vz)
				local height = self.currentField.height
				self.lineVisualization:visualizeLine(vx, height, vz, x, height, z, false, self.isVertexValid and Color.PRESETS.ORANGE or Color.PRESETS.RED)
				overlapBoxAsync(cx, y, cz, 0, ry, 0, 1, 1, width / 2, "onEdgeBoxOverlap", self, self.overlapCollisionMask, false, false, true, true)
			end
		end
		overlapSphereAsync(x, y, z, self.minDistanceToExistingFields, "onCursorSphereOverlap", self, self.overlapCollisionMask, false, false, true, true)
	end
end
function ConstructionBrushRiceField:onCursorSphereOverlap(actorId, subShapeIndex)
	if actorId ~= 0 then
		self.isVertexValid = false
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_overlapsWithObject"))
		return false
	else
		self.isVertexValid = true
		return true
	end
end
function ConstructionBrushRiceField:onEdgeBoxOverlap(actorId, subShapeIndex)
	if actorId ~= 0 then
		self.isVertexValid = false
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_overlapsWithObject"))
		return false
	else
		self.isVertexValid = true
		return true
	end
end
function ConstructionBrushRiceField:draw()
	if self.currentField == nil then
		return
	elseif self.isVertexValid then
		return
	end
end
function ConstructionBrushRiceField:onButtonPrimary()
	if self.placeable == nil then
		return
	end
	local x, y, z, _, _ = self:getLimitedSnappedCursorPosition()
	if x == nil then
		return
	end
	local err = self:verifyAccess(x, y, z)
	if err ~= nil then
		return
	else
		if self.currentField == nil and self.placeable:getCanCreateNewField() then
			self.currentField = self.placeable:createNewField(y)
		end
		self.placeable:addVertex(self.currentField, x, z)
		self:setInputTextDirty()
	end
end
function ConstructionBrushRiceField:onButtonSecondary()
	if self.currentField ~= nil and not self.pendingCreation then
		if self.finalVertexX ~= nil then
			self.placeable:addVertex(self.currentField, self.finalVertexX, self.finalVertexZ)
		end
		if self.placeable:getCanFinish(self.currentField, self.snappingActive) then
			self.pendingCreation = true
			self.placeable:finalizeNewField(self.currentField, false, function(buildStatus)
				self.pendingCreation = false
				if buildStatus == PlaceableRiceField.BUILD_STATUS.OK then
					self.currentField = nil
					if self.placeable ~= nil and self.placeable.playPlaceSound ~= nil then
						self.placeable:playPlaceSound()
					end
				else
					local text = g_i18n:getText(PlaceableRiceField.BUILD_STATUS_LOCA_KEYS[buildStatus])
					if text ~= nil then
						g_currentMission:showBlinkingWarning(text)
					end
				end
				self:setInputTextDirty()
			end)
		end
	end
	self:setInputTextDirty()
end
function ConstructionBrushRiceField:onButtonTertiary()
	if self.currentField ~= nil and 1 < self.placeable:getNumVertices(self.currentField) then
		self.placeable:removeLastVertex(self.currentField)
	end
	self:setInputTextDirty()
end
function ConstructionBrushRiceField:onButtonSnapping()
	self.snappingActive = not self.snappingActive
	ConstructionBrushRiceField.LAST_SNAPPING_STATE = self.snappingActive
	self:setInputTextDirty()
end
function ConstructionBrushRiceField:onAxisPrimary(inputValue)
	if self.currentField ~= nil then
		local newHeight = self.currentField.height + inputValue * ConstructionBrushRiceField.HEIGHT_CHANGE_INCREMENT
		for vertexIndex, xPos, zPos in self.currentField.polygon:iteratorVertices() do
			if PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN < math.abs(getTerrainHeightAtWorldPos(g_terrainNode, xPos, 0, zPos) - newHeight) then
				self.cursor:setErrorMessage(g_i18n:getText("ui_construction_heightDifferenceTooLarge"))
				return
			end
		end
		self.currentField.height = newHeight
	end
end
function ConstructionBrushRiceField:cancel()
	if self.currentField ~= nil then
		if 4 < self.currentField.polygon:getNumVertices() then
			YesNoDialog.show(function(yes)
				if yes then
					self.currentField = nil
				end
			end, nil, g_i18n:getText("ui_construction_cancelCurrentField"))
		else
			self.currentField = nil
		end
	end
	self:setInputTextDirty()
end
function ConstructionBrushRiceField:getButtonPrimaryText()
	if self.currentField == nil or self.placeable:getNumVertices(self.currentField) == 0 then
		return "$l10n_action_startNewField"
	end
	return "$l10n_action_addCorner"
end
function ConstructionBrushRiceField:getButtonSecondaryText()
	if self.currentField ~= nil and (self.placeable:getCanFinish(self.currentField, self.snappingActive) or self.finalVertexX ~= nil) then
		return "$l10n_input_CONSTRUCTION_FINISH"
	end
	return nil
end
function ConstructionBrushRiceField:getButtonTertiaryText()
	if self.currentField ~= nil and 1 < self.placeable:getNumVertices(self.currentField) then
		return "$l10n_action_removeLastCorner"
	end
	return nil
end
function ConstructionBrushRiceField:getAxisPrimaryText()
	if self.currentField ~= nil then
		return "$l10n_action_changePlacementHeight"
	else
		return nil
	end
end
function ConstructionBrushRiceField:getButtonSnappingText()
	return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
end
