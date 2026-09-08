-- Local values: ConstructionBrushPaint_mt
ConstructionBrushPaint = {}
local ConstructionBrushPaint_mt = Class(ConstructionBrushPaint, ConstructionBrush)
ConstructionBrushPaint.CURSOR_SIZES = {
	0.5,
	1,
	2,
	4,
	8,
	16
}

-- Upvalues: ConstructionBrushPaint_mt
-- Local values: self
function ConstructionBrushPaint.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushPaint_mt
	local v4_ = ConstructionBrushPaint:superClass().new(subclass_mt or ConstructionBrushPaint_mt, cursor)
	v4_.supportsPrimaryButton = true
	v4_.supportsPrimaryDragging = true
	v4_.requiredPermission = Farm.PERMISSION.LANDSCAPING
	v4_.supportsPrimaryAxis = true
	v4_.primaryAxisIsContinuous = false
	v4_.supportsSecondaryButton = true
	v4_.supportsTertiaryButton = true
	v4_.maxBrushRadius = ConstructionBrushPaint.CURSOR_SIZES[#ConstructionBrushPaint.CURSOR_SIZES] / 2
	v4_.freeMode = false
	return v4_
end

function ConstructionBrushPaint:delete()
	ConstructionBrushPaint:superClass().delete(self)
end

function ConstructionBrushPaint:activate()
	ConstructionBrushPaint:superClass().activate(self)
	self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.PAINTING)
	self.cursor:setTerrainOnly(true)
	self:setBrushSize(1)
	g_messageCenter:subscribe(LandscapingSculptEvent, self.onSculptingFinished, self)
end

function ConstructionBrushPaint:deactivate()
	self.cursor:setTerrainOnly(false)
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushPaint:superClass().deactivate(self)
end

function ConstructionBrushPaint:copyState(from)
	self:setBrushSize(from.cursorSizeIndex)
	self.brushShape = from.brushShape
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	else
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	end
	self.freeMode = Utils.getNoNil(from.freeMode, self.freeMode)
end

-- Local values: layer
function ConstructionBrushPaint:setGroundType(groundTypeName)
	if not self.isActive then
		self.terrainLayer = g_groundTypeManager:getTerrainLayerByType(groundTypeName)
	end
end

function ConstructionBrushPaint:setParameters(groundTypeName)
	self:setGroundType(groundTypeName)
end

-- Local values: size
function ConstructionBrushPaint:setBrushSize(index)
	local v16_ = #ConstructionBrushPaint.CURSOR_SIZES
	self.cursorSizeIndex = math.clamp(index, 1, v16_)
	local v17_ = ConstructionBrushPaint.CURSOR_SIZES[self.cursorSizeIndex]
	self.brushRadius = v17_ / 2
	self.cursor:setShapeSize(v17_)
end

function ConstructionBrushPaint:toggleBrushShape()
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	else
		self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	end
end

-- Local values: x, y, z, err
function ConstructionBrushPaint:update(dt)
	ConstructionBrushPaint:superClass().update(self, dt)
	local v21_, v22_, v23_ = self.cursor:getHitTerrainPosition()
	if v21_ == nil then
		return
	else
		local v24_ = self:verifyAccess(v21_, v22_, v23_)
		if v24_ == nil or self.freeMode and v24_ == ConstructionBrush.ERROR.PLACEMENT_BLOCKED then
			if g_currentMission:getMoney() < Landscaping.PAINT_BASE_COST_PER_M2 * 5 then
				self.cursor:setErrorMessage(g_i18n:getText("ui_construction_notEnoughMoney"))
			end
		else
			self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[v24_]))
			return
		end
	end
end

function ConstructionBrushPaint:onSculptingFinished(isValidation, errorCode, displacedVolumeOrArea) end

-- Local values: x, y, z, validateOnly, err, dx, dz, dist, requestLandscaping
function ConstructionBrushPaint:onButtonPrimary(isDown, isDrag, isUp)
	self:setActiveSound(ConstructionSound.ID.NONE)
	if isUp then
		self.lastX = nil
		return
	else
		local v27_, v28_, v29_ = self.cursor:getHitTerrainPosition()
		if v27_ == nil then
			return
		else
			local v30_ = self:verifyAccess(v27_, v28_, v29_)
			if v30_ == nil or self.freeMode and v30_ == ConstructionBrush.ERROR.PLACEMENT_BLOCKED then
				self:setActiveSound(ConstructionSound.ID.PAINT, 1 - self.brushRadius / self.maxBrushRadius)
				if self.lastX ~= nil then
					local v31_ = v27_ - self.lastX
					local v32_ = v29_ - self.lastZ
					local v33_ = v31_ * v31_ + v32_ * v32_
					if math.sqrt(v33_) < 0.25 then
						return
					end
				end
				self.lastX = v27_
				self.lastZ = v29_
				local v34_ = LandscapingSculptEvent.new(false, Landscaping.OPERATION.PAINT, v27_, v28_, v29_, nil, nil, nil, nil, nil, nil, self.brushRadius, 1, self.brushShape, 1, self.terrainLayer)
				g_client:getServerConnection():sendEvent(v34_)
			end
		end
	end
end

function ConstructionBrushPaint:onAxisPrimary(inputValue)
	self:setBrushSize(self.cursorSizeIndex + inputValue)
end

function ConstructionBrushPaint:onButtonSecondary()
	self:toggleBrushShape()
end

function ConstructionBrushPaint:onButtonTertiary()
	self.freeMode = not self.freeMode
	self:setInputTextDirty()
	if self.freeMode and not g_gameSettings:getValue(GameSettings.SETTING.SHOWN_FREEMODE_WARNING) then
		InfoDialog.show(g_i18n:getText("ui_constructionFreeModeWarning"))
		g_gameSettings:setValue(GameSettings.SETTING.SHOWN_FREEMODE_WARNING, true)
	end
end

function ConstructionBrushPaint:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PAINT"
end

function ConstructionBrushPaint:getAxisPrimaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SIZE"
end

function ConstructionBrushPaint:getButtonSecondaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SHAPE"
end

function ConstructionBrushPaint:getButtonTertiaryText()
	return string.format(g_i18n:getText("input_CONSTRUCTION_FREEMODE"), g_i18n:getText(self.freeMode and "ui_on" or "ui_off"))
end
