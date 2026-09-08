-- Local values: ConstructionBrushFoliage_mt
ConstructionBrushFoliage = {}
local ConstructionBrushFoliage_mt = Class(ConstructionBrushFoliage, ConstructionBrush)
ConstructionBrushFoliage.CURSOR_SIZES = {
	0.5,
	1,
	2,
	4,
	8,
	16
}

-- Upvalues: ConstructionBrushFoliage_mt
-- Local values: self
function ConstructionBrushFoliage.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushFoliage_mt
	local v4_ = ConstructionBrushFoliage:superClass().new(subclass_mt or ConstructionBrushFoliage_mt, cursor)
	v4_.supportsPrimaryButton = true
	v4_.supportsPrimaryDragging = true
	v4_.supportsSecondaryButton = true
	v4_.supportsSecondaryDragging = true
	v4_.requiredPermission = Farm.PERMISSION.LANDSCAPING
	v4_.supportsPrimaryAxis = true
	v4_.primaryAxisIsContinuous = false
	v4_.supportsTertiaryButton = true
	v4_.maxBrushRadius = ConstructionBrushFoliage.CURSOR_SIZES[#ConstructionBrushFoliage.CURSOR_SIZES] / 2
	return v4_
end

function ConstructionBrushFoliage:delete()
	ConstructionBrushFoliage:superClass().delete(self)
end

function ConstructionBrushFoliage:activate()
	ConstructionBrushFoliage:superClass().activate(self)
	self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
	self.cursor:setTerrainOnly(true)
	self:setBrushSize(1)
	g_messageCenter:subscribe(LandscapingSculptEvent, self.onSculptingFinished, self)
end

function ConstructionBrushFoliage:deactivate()
	self.cursor:setTerrainOnly(false)
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushFoliage:superClass().deactivate(self)
end

function ConstructionBrushFoliage:copyState(from)
	self:setBrushSize(from.cursorSizeIndex)
	self.brushShape = from.brushShape
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	else
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	end
end

function ConstructionBrushFoliage:setFoliageType(foliageName, foliageState)
	if not self.isActive then
		self.foliagePaint = g_currentMission.foliageSystem:getFoliagePaintByName(foliageName)
		self.foliageState = foliageState
	end
end

function ConstructionBrushFoliage:setParameters(foliageName, foliageState)
	self:setFoliageType(foliageName, (tonumber(foliageState)))
end

-- Local values: size
function ConstructionBrushFoliage:setBrushSize(index)
	local v18_ = #ConstructionBrushFoliage.CURSOR_SIZES
	self.cursorSizeIndex = math.clamp(index, 1, v18_)
	local v19_ = ConstructionBrushFoliage.CURSOR_SIZES[self.cursorSizeIndex]
	self.brushRadius = v19_ / 2
	self.cursor:setShapeSize(v19_)
end

function ConstructionBrushFoliage:toggleBrushShape()
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	else
		self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	end
end

-- Local values: x, y, z, err
function ConstructionBrushFoliage:update(dt)
	ConstructionBrushFoliage:superClass().update(self, dt)
	if self.foliagePaint == nil then
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_plantNotSupported"))
		return
	else
		local v23_, v24_, v25_ = self.cursor:getHitTerrainPosition()
		if v23_ == nil then
			return
		else
			local v26_ = self:verifyAccess(v23_, v24_, v25_)
			if v26_ == nil then
				if g_currentMission:getMoney() < self:getPrice() then
					self.cursor:setErrorMessage(g_i18n:getText("ui_construction_notEnoughMoney"))
				end
			else
				self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[v26_]))
				return
			end
		end
	end
end

function ConstructionBrushFoliage:getPrice()
	return Landscaping.FOLIAGE_BASE_COST_PER_M2 * 5
end

function ConstructionBrushFoliage:onSculptingFinished(isValidation, errorCode, displacedVolumeOrArea) end

-- Local values: x, y, z, radius, validateOnly, err, dx, dz, dist, requestLandscaping
function ConstructionBrushFoliage:performBrush(isDown, isDrag, isUp, direction)
	self:setActiveSound(ConstructionSound.ID.NONE)
	if isUp then
		self.lastX = nil
		return
	elseif self.foliagePaint == nil then
		return
	else
		local v30_, v31_, v32_ = self.cursor:getHitTerrainPosition()
		if v30_ == nil then
			return
		else
			local v33_ = self.brushRadius
			if self:verifyAccess(v30_, v31_, v32_) == nil then
				self:setActiveSound(ConstructionSound.ID.FOLIAGE, 1 - self.brushRadius / self.maxBrushRadius)
				if self.lastX ~= nil then
					local v34_ = v30_ - self.lastX
					local v35_ = v32_ - self.lastZ
					local v36_ = v34_ * v34_ + v35_ * v35_
					if math.sqrt(v36_) < 0.25 then
						return
					end
				end
				self.lastX = v30_
				self.lastZ = v32_
				local v37_
				if direction > 0 then
					v37_ = LandscapingSculptEvent.new(false, Landscaping.OPERATION.FOLIAGE, v30_, v31_, v32_, nil, nil, nil, nil, nil, nil, v33_, 1, self.brushShape, 0, nil, self.foliagePaint.id, self.foliageState)
				else
					v37_ = LandscapingSculptEvent.new(false, Landscaping.OPERATION.PAINT, v30_, v31_, v32_, nil, nil, nil, nil, nil, nil, v33_, 1, self.brushShape, 0, TerrainDeformation.NO_TERRAIN_BRUSH)
				end
				g_client:getServerConnection():sendEvent(v37_)
			end
		end
	end
end

function ConstructionBrushFoliage:onButtonPrimary(isDown, isDrag, isUp)
	self:performBrush(isDown, isDrag, isUp, 1)
end

function ConstructionBrushFoliage:onButtonSecondary(isDown, isDrag, isUp)
	self:performBrush(isDown, isDrag, isUp, -1)
end

function ConstructionBrushFoliage:onAxisPrimary(inputValue)
	self:setBrushSize(self.cursorSizeIndex + inputValue)
end

function ConstructionBrushFoliage:onButtonTertiary()
	self:toggleBrushShape()
end

function ConstructionBrushFoliage:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PLACE"
end

function ConstructionBrushFoliage:getButtonSecondaryText()
	return "$l10n_input_CONSTRUCTION_REMOVE"
end

function ConstructionBrushFoliage:getAxisPrimaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SIZE"
end

function ConstructionBrushFoliage:getButtonTertiaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SHAPE"
end
