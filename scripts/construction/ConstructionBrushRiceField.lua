-- Local values: ConstructionBrushRiceField_mt
ConstructionBrushRiceField = {}
local ConstructionBrushRiceField_mt = Class(ConstructionBrushRiceField, ConstructionBrush)
ConstructionBrushRiceField.ERROR = {
	["MININUM_LENGTH"] = 1,
	["COLLISION"] = 2,
	["NOT_ENOUGH_MONEY"] = 3,
	["CANNOT_BE_PLACED_HERE"] = 4
}
ConstructionBrushRiceField.ERROR_MESSAGES = {
	[ConstructionBrushRiceField.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort",
	[ConstructionBrushRiceField.ERROR.COLLISION] = "ui_construction_collidesWithItem",
	[ConstructionBrushRiceField.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
	[ConstructionBrushRiceField.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere"
}
ConstructionBrushRiceField.HEIGHT_CHANGE_INCREMENT = 0.25

-- Upvalues: ConstructionBrushRiceField_mt
-- Local values: self
function ConstructionBrushRiceField.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushRiceField_mt
	local v4_ = ConstructionBrushRiceField:superClass().new(subclass_mt or ConstructionBrushRiceField_mt, cursor)
	v4_.overlapCollisionMask = CollisionFlag.WATER + CollisionFlag.PLACEMENT_BLOCKING
	v4_.supportsPrimaryButton = true
	v4_.supportsSecondaryButton = true
	v4_.supportsTertiaryButton = true
	v4_.supportsPrimaryAxis = true
	v4_.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
	v4_.parallelSnappingEnabled = false
	v4_.doFindPlaceable = false
	v4_.supportsSnapping = true
	v4_.snappingActive = ConstructionBrushRiceField.LAST_SNAPPING_STATE
	v4_.minDistanceToExistingFields = 3
	v4_.isVertexValid = false
	v4_.pendingCreation = false
	v4_.heightMapUnitSize = getTerrainHeightmapUnitSize(g_terrainNode)
	v4_.lineVisualization = Line3D.new()
	v4_.debugBox = DebugBox.new()
	return v4_
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
	local v15_
	if self.currentField == nil then
		v15_ = false
	else
		v15_ = self.currentField.polygon:getNumVertices() > 0
	end
	return v15_
end

-- Local values: data, storeItem
function ConstructionBrushRiceField:acquirePlaceable()
	if self.xmlFilename == nil then
		Logging.warning("Rice Field brush has no placeable set")
	else
		self.placeable = self:findPlaceable()
		self:setInputTextDirty()
		if self.placeable == nil then
			local v17_ = BuyPlaceableData.new()
			v17_:setStoreItem((g_storeManager:getItemByXMLFilename(self.xmlFilename)))
			v17_:setPosition(0, 0, 0)
			v17_:setRotation(0, 0, 0)
			v17_:setConfigurations({})
			v17_:setOwnerFarmId(g_localPlayer.farmId)
			v17_:setDisplacementCosts(0)
			v17_:setModifyTerrain(false)
			v17_:setIsFreeOfCharge(true)
			g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
			g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(v17_))
		end
	end
end

-- Local values: farmId, existingPlaceableInstance
function ConstructionBrushRiceField:findPlaceable()
	local v19_ = g_currentMission:getFarmId()
	return g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.xmlFilename, v19_, true)
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

-- Local values: x, y, z, offset, vx, vz, lvx, lvz, cvx, cvz
function ConstructionBrushRiceField:getSnappedCursorPosition()
	local v24_, v25_, v26_ = self.cursor:getHitTerrainPosition()
	if v24_ ~= nil and self.snappingActive then
		local v27_ = MathUtil.snapValue(v24_, self.heightMapUnitSize) + 0
		local v28_ = MathUtil.snapValue(v26_, self.heightMapUnitSize) + 0
		if self.currentField == nil then
			v26_ = v28_
			v24_ = v27_
		else
			v25_ = self.currentField.height
			local v29_, v30_, v31_
			v29_, v26_, v30_, v31_ = self.placeable:getFirstAndLastVertex(self.currentField)
			v24_ = v30_ or v29_
			local v32_ = v31_ or v26_
			if v24_ == nil then
				v26_ = v28_
				v24_ = v27_
			else
				local v33_ = v24_ - v27_
				local v34_ = math.abs(v33_)
				local v35_ = v32_ - v28_
				if math.abs(v35_) < v34_ then
					v28_ = v32_
					v24_ = v27_
				end
				if v30_ == nil then
					v26_ = v28_
				else
					local v36_ = v29_ - v24_
					if math.abs(v36_) < 2 then
						v26_ = v28_
						v24_ = v29_
					else
						local v37_ = v26_ - v28_
						if math.abs(v37_) >= 2 then
							v26_ = v28_
						end
					end
				end
			end
		end
	end
	return v24_, v25_, v26_, false
end

-- Local values: x, y, z, snapped
function ConstructionBrushRiceField:getLimitedSnappedCursorPosition()
	local v39_, v40_, v41_, v42_ = self:getSnappedCursorPosition()
	return v39_, v40_, v41_, v42_
end

-- Local values: numEdges, height, canFinish, fvx, fvz, lvx, lvz, fvx, fvz, lvx, lvz, getIsNewVertexValid, getFinalVertex, ix, iz, x, z, index, x1, z1, x2, z2, x, y, z, _, _, err, message, canAdd, errorMessage, vx, vz, lvx, lvz, cx, cz, ry, width, height
function ConstructionBrushRiceField:update(dt)
	ConstructionBrushRiceField:superClass().update(self, dt)
	self.cursor:setMessage("")
	self.lineVisualization:clearVisualization()
	self.finalVertexX = nil
	self.finalVertexZ = nil
	if self.currentField ~= nil then
		local v45_ = self.currentField.polygon:getNumEdges()
		local v46_ = self.currentField.height + 0.05
		local v47_ = self.placeable:getCanFinish(self.currentField, self.snappingActive)
		if v47_ then
			local v48_, v49_, v50_, v51_ = self.placeable:getFirstAndLastVertex(self.currentField)
			self.lineVisualization:visualizeLine(v50_, v46_, v51_, v48_, v46_, v49_, false, Color.PRESETS.GREEN)
		elseif v45_ >= 2 then
			local v_u_52_, v_u_53_, v_u_54_, v_u_55_ = self.placeable:getFirstAndLastVertex(self.currentField)
			local function v62_(p56_, p57_)
				-- upvalues: (copy) self, (copy) v_u_52_, (copy) v_u_53_, (copy) v_u_54_, (copy) v_u_55_
				for _, v58_, v59_, v60_, v61_ in self.currentField.polygon:iteratorEdges() do
					if (v58_ ~= p56_ or v59_ ~= p57_) and (v60_ ~= p56_ or v61_ ~= p57_) then
						if MathUtil.getAreLineSegmentsIntersecting(v58_, v59_, v60_, v61_, v_u_52_, v_u_53_, p56_, p57_, true) then
							return false
						end
						if MathUtil.getAreLineSegmentsIntersecting(v58_, v59_, v60_, v61_, v_u_54_, v_u_55_, p56_, p57_, true) then
							return false
						end
					end
				end
				return self.placeable:getCanAddVertex(self.currentField, p56_, p57_) and true or false
			end
			if self.snappingActive then
				local v63_, v64_
				if v62_(v_u_52_, v_u_55_) then
					v63_ = v_u_55_
					v64_ = v_u_52_
				elseif v62_(v_u_54_, v_u_53_) then
					v63_ = v_u_53_
					v64_ = v_u_54_
				else
					v64_ = nil
					v63_ = nil
				end
				if v64_ ~= nil then
					self.lineVisualization:visualizeLine(v64_, v46_, v63_, v_u_52_, v46_, v_u_53_, false, Color.PRESETS.GREEN)
					self.lineVisualization:visualizeLine(v64_, v46_, v63_, v_u_54_, v46_, v_u_55_, false, Color.PRESETS.GREEN)
					self.finalVertexX = v64_
					self.finalVertexZ = v63_
				end
			end
		end
		for _, v65_, v66_, v67_, v68_ in self.currentField.polygon:iteratorEdges(nil, 1) do
			self.lineVisualization:visualizeLine(v65_, v46_, v66_, v67_, v46_, v68_, false, v47_ and Color.PRESETS.GREEN or Color.PRESETS.ORANGE)
		end
	end
	if self.doFindPlaceable then
		self.placeable = self:findPlaceable()
		if self.placeable == nil then
			return
		end
		self.doFindPlaceable = false
	end
	local v69_, v70_, v71_, _, _ = self:getLimitedSnappedCursorPosition()
	if v69_ == nil then
		return
	else
		local v72_ = self:verifyAccess(v69_, v70_, v71_)
		if v72_ == nil then
			if self.placeable == nil then
				return
			elseif self.currentField == nil and not self.placeable:getCanCreateNewField() then
				self.cursor:setErrorMessage(g_i18n:getText("ui_construction_maxNumberOfFieldsReached"))
			else
				if self.currentField ~= nil then
					local v73_, v74_ = self.placeable:getCanAddVertex(self.currentField, v69_, v71_)
					if not v73_ then
						self.cursor:setErrorMessage(v74_)
						return
					end
					if self.currentField.polygon:getIsCircleIntersecting(v69_, v71_, 1) then
						return
					end
					local v75_, v76_, v77_, v78_ = self.placeable:getFirstAndLastVertex(self.currentField)
					local v79_ = v77_ or v75_
					local v80_ = v78_ or v76_
					if v79_ ~= nil then
						local v81_ = (v69_ + v79_) / 2
						local v82_ = (v71_ + v80_) / 2
						local v83_ = MathUtil.getYRotationFromDirection(v69_ - v79_, v71_ - v80_)
						local v84_ = MathUtil.vector2Length(v69_ - v79_, v71_ - v80_)
						local v85_ = self.currentField.height
						self.lineVisualization:visualizeLine(v79_, v85_, v80_, v69_, v85_, v71_, false, self.isVertexValid and Color.PRESETS.ORANGE or Color.PRESETS.RED)
						overlapBoxAsync(v81_, v70_, v82_, 0, v83_, 0, 1, 1, v84_ / 2, "onEdgeBoxOverlap", self, self.overlapCollisionMask, false, false, true, true)
					end
				end
				overlapSphereAsync(v69_, v70_, v71_, self.minDistanceToExistingFields, "onCursorSphereOverlap", self, self.overlapCollisionMask, false, false, true, true)
			end
		else
			local v86_ = g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[v72_])
			self.cursor:setErrorMessage(v86_)
			return
		end
	end
end

function ConstructionBrushRiceField:onCursorSphereOverlap(actorId, subShapeIndex)
	if actorId == 0 then
		self.isVertexValid = true
		return true
	end
	self.isVertexValid = false
	self.cursor:setErrorMessage(g_i18n:getText("ui_construction_overlapsWithObject"))
	return false
end

function ConstructionBrushRiceField:onEdgeBoxOverlap(actorId, subShapeIndex)
	if actorId == 0 then
		self.isVertexValid = true
		return true
	end
	self.isVertexValid = false
	self.cursor:setErrorMessage(g_i18n:getText("ui_construction_overlapsWithObject"))
	return false
end

function ConstructionBrushRiceField:draw()
	if self.placeable ~= nil then
		local _ = self.currentField == nil
	end
	if self.currentField == nil then
		return
	elseif not self.isVertexValid then
	end
end

-- Local values: x, y, z, _, _, err
function ConstructionBrushRiceField:onButtonPrimary()
	if self.placeable == nil then
		return
	else
		local v93_, v94_, v95_, _, _ = self:getLimitedSnappedCursorPosition()
		if v93_ == nil then
			return
		elseif self:verifyAccess(v93_, v94_, v95_) == nil then
			if self.currentField == nil and self.placeable:getCanCreateNewField() then
				self.currentField = self.placeable:createNewField(v94_)
			end
			self.placeable:addVertex(self.currentField, v93_, v95_)
			self:setInputTextDirty()
		end
	end
end

function ConstructionBrushRiceField:onButtonSecondary()
	if self.currentField ~= nil and not self.pendingCreation then
		if self.finalVertexX ~= nil then
			self.placeable:addVertex(self.currentField, self.finalVertexX, self.finalVertexZ)
		end
		if self.placeable:getCanFinish(self.currentField, self.snappingActive) then
			self.pendingCreation = true
			self.placeable:finalizeNewField(self.currentField, false, function(p97_)
				-- upvalues: (copy) self
				self.pendingCreation = false
				if p97_ == PlaceableRiceField.BUILD_STATUS.OK then
					self.currentField = nil
					if self.placeable ~= nil and self.placeable.playPlaceSound ~= nil then
						self.placeable:playPlaceSound()
					end
				else
					local v98_ = g_i18n:getText(PlaceableRiceField.BUILD_STATUS_LOCA_KEYS[p97_])
					if v98_ ~= nil then
						g_currentMission:showBlinkingWarning(v98_)
					end
				end
				self:setInputTextDirty()
			end)
		end
	end
	self:setInputTextDirty()
end

function ConstructionBrushRiceField:onButtonTertiary()
	if self.currentField ~= nil and self.placeable:getNumVertices(self.currentField) > 1 then
		self.placeable:removeLastVertex(self.currentField)
	end
	self:setInputTextDirty()
end

function ConstructionBrushRiceField:onButtonSnapping()
	self.snappingActive = not self.snappingActive
	ConstructionBrushRiceField.LAST_SNAPPING_STATE = self.snappingActive
	self:setInputTextDirty()
end

-- Local values: newHeight, vertexIndex, xPos, zPos
function ConstructionBrushRiceField:onAxisPrimary(inputValue)
	if self.currentField ~= nil then
		local v103_ = self.currentField.height + inputValue * ConstructionBrushRiceField.HEIGHT_CHANGE_INCREMENT
		for _, v104_, v105_ in self.currentField.polygon:iteratorVertices() do
			local v106_ = getTerrainHeightAtWorldPos(g_terrainNode, v104_, 0, v105_) - v103_
			if math.abs(v106_) > PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN then
				self.cursor:setErrorMessage(g_i18n:getText("ui_construction_heightDifferenceTooLarge"))
				return
			end
		end
		self.currentField.height = v103_
	end
end

function ConstructionBrushRiceField:cancel()
	if self.currentField ~= nil then
		if self.currentField.polygon:getNumVertices() > 4 then
			YesNoDialog.show(function(p108_)
				-- upvalues: (copy) self
				if p108_ then
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
	return (self.currentField == nil or self.placeable:getNumVertices(self.currentField) == 0) and "$l10n_action_startNewField" or "$l10n_action_addCorner"
end

function ConstructionBrushRiceField:getButtonSecondaryText()
	return self.currentField ~= nil and (self.placeable:getCanFinish(self.currentField, self.snappingActive) or self.finalVertexX ~= nil) and "$l10n_input_CONSTRUCTION_FINISH" or nil
end

function ConstructionBrushRiceField:getButtonTertiaryText()
	return self.currentField ~= nil and self.placeable:getNumVertices(self.currentField) > 1 and "$l10n_action_removeLastCorner" or nil
end

function ConstructionBrushRiceField:getAxisPrimaryText()
	return self.currentField ~= nil and "$l10n_action_changePlacementHeight" or nil
end

function ConstructionBrushRiceField:getButtonSnappingText()
	return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
end
