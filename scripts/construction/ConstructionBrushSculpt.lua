-- Local values: ConstructionBrushSculpt_mt
ConstructionBrushSculpt = {}
local ConstructionBrushSculpt_mt = Class(ConstructionBrushSculpt, ConstructionBrush)
ConstructionBrushSculpt.MODE = {
	["SHIFT"] = 1,
	["LEVEL"] = 2,
	["SOFTEN"] = 3,
	["SLOPE"] = 4
}
ConstructionBrushSculpt.CURSOR_SIZES = {
	2,
	4,
	8,
	16,
	32
}
ConstructionBrushSculpt.CURSOR_STRENGTHS = {
	0.25,
	0.5,
	1,
	2,
	4
}

-- Upvalues: ConstructionBrushSculpt_mt
-- Local values: self
function ConstructionBrushSculpt.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushSculpt_mt
	local v4_ = ConstructionBrushSculpt:superClass().new(subclass_mt or ConstructionBrushSculpt_mt, cursor)
	v4_.supportsPrimaryButton = true
	v4_.supportsPrimaryDragging = true
	v4_.supportsSecondaryButton = true
	v4_.supportsSecondaryDragging = true
	v4_.supportsTertiaryButton = true
	v4_.supportsPrimaryAxis = true
	v4_.supportsSecondaryAxis = true
	v4_.requiredPermission = Farm.PERMISSION.LANDSCAPING
	v4_.maxBrushRadius = ConstructionBrushSculpt.CURSOR_SIZES[#ConstructionBrushSculpt.CURSOR_SIZES] / 2
	v4_.maxBrushStrength = ConstructionBrushSculpt.CURSOR_STRENGTHS[#ConstructionBrushSculpt.CURSOR_STRENGTHS]
	v4_.smoothingDistance = 1
	return v4_
end

function ConstructionBrushSculpt:delete()
	ConstructionBrushSculpt:superClass().delete(self)
end

function ConstructionBrushSculpt:activate()
	ConstructionBrushSculpt:superClass().activate(self)
	self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	self.cursor:setTerrainOnly(true)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SCULPTING)
	self.cursor:setCursorTerrainOffset(true)
	self.pendingSculptCallbacks = 0
	self:setBrushSize(2)
	self:setBrushStrength(1)
end

function ConstructionBrushSculpt:deactivate()
	self.cursor:setTerrainOnly(false)
	g_messageCenter:unsubscribe(LandscapingSculptEvent, self)
	ConstructionBrushSculpt:superClass().deactivate(self)
end

function ConstructionBrushSculpt:copyState(from)
	self:setBrushSize(from.cursorSizeIndex)
	self:setBrushStrength(from.cursorStrengthIndex)
	self.brushShape = from.brushShape
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	else
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	end
end

function ConstructionBrushSculpt:setParameters(mode)
	self.mode = mode
end

-- Local values: size
function ConstructionBrushSculpt:setBrushSize(index)
	local v14_ = #ConstructionBrushSculpt.CURSOR_SIZES
	self.cursorSizeIndex = math.clamp(index, 2, v14_)
	local v15_ = ConstructionBrushSculpt.CURSOR_SIZES[self.cursorSizeIndex]
	self.brushRadius = v15_ / 2
	self.cursor:setShapeSize(v15_)
end

-- Local values: alpha
function ConstructionBrushSculpt:setBrushStrength(index)
	local v18_ = #ConstructionBrushSculpt.CURSOR_STRENGTHS
	self.cursorStrengthIndex = math.clamp(index, 1, v18_)
	self.brushStrength = ConstructionBrushSculpt.CURSOR_STRENGTHS[self.cursorStrengthIndex]
	local v19_ = self.brushStrength / ConstructionBrushSculpt.CURSOR_STRENGTHS[#ConstructionBrushSculpt.CURSOR_STRENGTHS]
	local v20_ = math.sqrt(v19_) * 0.8
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SCULPTING, v20_)
end

function ConstructionBrushSculpt:toggleBrushShape()
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	else
		self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	end
end

-- Local values: x, y, z, err, message
function ConstructionBrushSculpt:update(dt)
	ConstructionBrushSculpt:superClass().update(self, dt)
	if self.showNoTargetHeightError then
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_noTargetHeightSet"))
		return
	elseif g_currentMission:getMoney() < Landscaping.SCULPT_BASE_COST_PER_M3 then
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_notEnoughMoney"))
		return
	elseif self.slopeAngle == nil then
		local v24_, v25_, v26_ = self.cursor:getHitTerrainPosition()
		if v24_ ~= nil then
			local v27_ = self:verifyAccess(v24_, v25_, v26_)
			if v27_ ~= nil then
				local v28_ = g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[v27_])
				self.cursor:setErrorMessage(v28_)
			end
		end
	else
		self.cursor:setMessage(string.format("%d%%", self.slopeAngle * 100))
	end
end

function ConstructionBrushSculpt:onSculptCallback(validateOnly, errorCode, displacedVolumeOrArea)
	self.pendingSculptCallbacks = self.pendingSculptCallbacks - 1
	if self.pendingSculptCallbacks == 0 then
		g_messageCenter:unsubscribe(LandscapingSculptEvent, self)
	end
end

-- Local values: currentRadius, validateOnly, operation, requestLandscaping
function ConstructionBrushSculpt:shift(x, y, z, direction)
	local v35_ = self.brushRadius
	local v36_ = direction > 0 and Landscaping.OPERATION.RAISE or Landscaping.OPERATION.LOWER
	local v37_ = LandscapingSculptEvent.new(false, v36_, x, y, z, nil, nil, nil, nil, nil, nil, v35_, self.brushStrength, self.brushShape, self.smoothingDistance)
	g_client:getServerConnection():sendEvent(v37_)
end

-- Local values: validateOnly, operation, requestLandscaping
function ConstructionBrushSculpt:flatten(x, y, z)
	local v42_ = Landscaping.OPERATION.FLATTEN
	if self.flattenHeight == nil then
		self.flattenHeight = y
	end
	local v43_ = LandscapingSculptEvent.new(false, v42_, x, self.flattenHeight, z, nil, nil, nil, nil, nil, nil, self.brushRadius, self.brushStrength, self.brushShape, self.smoothingDistance)
	g_client:getServerConnection():sendEvent(v43_)
end

-- Local values: validateOnly, operation, requestLandscaping
function ConstructionBrushSculpt:smooth(x, y, z)
	local v48_ = Landscaping.OPERATION.SMOOTH
	local v49_ = LandscapingSculptEvent.new(false, v48_, x, y, z, nil, nil, nil, nil, nil, nil, self.brushRadius, self.brushStrength * 2, self.brushShape, self.smoothingDistance)
	g_client:getServerConnection():sendEvent(v49_)
end

-- Local values: x1, y1, z1, x2, y2, z2, vx1, vy1, vz1, slope, vx2, vy2, vz2, nx, ny, nz, validateOnly, strength, operation, requestLandscaping
function ConstructionBrushSculpt:slope(x, y, z)
	if self.slopeTargetX == nil then
		self.showNoTargetHeightError = true
	else
		self.showNoTargetHeightError = false
		if self.slopeSourceX == nil then
			local v54_ = self.slopeTargetX
			local v55_ = self.slopeTargetY
			local v56_ = self.slopeTargetZ
			if MathUtil.vector3Length(v54_ - x, v55_ - y, v56_ - z) < 0.01 then
				return
			end
			self.slopeSourceX = x
			self.slopeSourceY = y
			self.slopeSourceZ = z
			local v57_, v58_, v59_ = MathUtil.vector3Normalize(v54_ - x, v55_ - y, v56_ - z)
			local v60_ = y - v55_
			local v61_ = MathUtil.vector2Length(x - v54_, z - v56_)
			local v62_ = v60_ / math.max(v61_, 1e-6)
			local v63_ = math.abs(v62_)
			self.slopeAngle = math.clamp(v63_, 0, 1)
			local v64_, v65_, v66_ = MathUtil.vector3Normalize(-v59_, 0, v57_)
			local v67_, v68_, v69_ = MathUtil.crossProduct(v64_, v65_, v66_, v57_, v58_, v59_)
			self.slopeNX = v67_
			self.slopeNY = v68_
			self.slopeNZ = v69_
			self.slopeD = -(v67_ * x + v68_ * y + v69_ * z)
			self.slopeMinY = math.min(y, v55_)
			self.slopeMaxY = math.max(y, v55_)
		end
		local v70_ = Landscaping.OPERATION.SLOPE
		local v71_ = LandscapingSculptEvent.new(false, v70_, x, y, z, self.slopeNX, self.slopeNY, self.slopeNZ, self.slopeD, self.slopeMinY, self.slopeMaxY, self.brushRadius, 5, self.brushShape, self.smoothingDistance)
		g_client:getServerConnection():sendEvent(v71_)
	end
end

function ConstructionBrushSculpt:slopeSetTarget(x, y, z)
	self.slopeTargetX = x
	self.slopeTargetY = y
	self.slopeTargetZ = z
	self.slopeAngle = nil
	self.showNoTargetHeightError = false
end

-- Local values: x, y, z, err
function ConstructionBrushSculpt:onButtonPrimary(isDown, isDrag, isUp)
	self:setActiveSound(ConstructionSound.ID.NONE)
	if isUp then
		self.flattenHeight = nil
		self.slopeSourceX = nil
		self.slopeSourceY = nil
		self.slopeSourceZ = nil
		self.showNoTargetHeightError = false
		self.slopeAngle = nil
		return
	else
		local v78_, v79_, v80_ = self.cursor:getHitTerrainPosition()
		if v78_ == nil then
			return
		elseif self:verifyAccess(v78_, v79_, v80_) == nil then
			if self.pendingSculptCallbacks == 0 then
				g_messageCenter:subscribe(LandscapingSculptEvent, self.onSculptCallback, self)
			end
			self.pendingSculptCallbacks = self.pendingSculptCallbacks + 1
			if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
				self:shift(v78_, v79_, v80_, 1)
			elseif self.mode == ConstructionBrushSculpt.MODE.LEVEL then
				self:flatten(v78_, v79_, v80_)
			elseif self.mode == ConstructionBrushSculpt.MODE.SOFTEN then
				self:smooth(v78_, v79_, v80_)
			elseif self.mode == ConstructionBrushSculpt.MODE.SLOPE then
				self:slope(v78_, v79_, v80_)
			end
			self:setActiveSound(ConstructionSound.ID.SCULPT, 1 - self.brushRadius / self.maxBrushRadius * 0.75 - self.brushStrength / self.maxBrushStrength * 0.25)
		end
	end
end

-- Local values: x, y, z, err
function ConstructionBrushSculpt:onButtonSecondary(isDown, isDrag, isUp)
	self:setActiveSound(ConstructionSound.ID.NONE)
	if isUp then
		return
	else
		local v83_, v84_, v85_ = self.cursor:getHitTerrainPosition()
		if v83_ == nil then
			return
		elseif self:verifyAccess(v83_, v84_, v85_) == nil then
			if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
				self:shift(v83_, v84_, v85_, -1)
				self:setActiveSound(ConstructionSound.ID.SCULPT, 1 - self.brushRadius / self.maxBrushRadius * 0.75 - self.brushStrength / self.maxBrushStrength * 0.25)
			elseif self.mode == ConstructionBrushSculpt.MODE.SLOPE then
				self:slopeSetTarget(v83_, v84_, v85_)
			end
		else
			return
		end
	end
end

function ConstructionBrushSculpt:onButtonTertiary()
	self:toggleBrushShape()
end

function ConstructionBrushSculpt:onAxisPrimary(inputValue)
	self:setBrushSize(self.cursorSizeIndex + inputValue)
end

function ConstructionBrushSculpt:onAxisSecondary(inputValue)
	self:setBrushStrength(self.cursorStrengthIndex + inputValue)
end

function ConstructionBrushSculpt:getButtonPrimaryText()
	return self.mode == ConstructionBrushSculpt.MODE.SHIFT and "$l10n_input_CONSTRUCTION_SHIFT_UP" or (self.mode == ConstructionBrushSculpt.MODE.LEVEL and "$l10n_input_CONSTRUCTION_LEVEL" or (self.mode == ConstructionBrushSculpt.MODE.SOFTEN and "$l10n_input_CONSTRUCTION_SOFTEN" or (self.mode == ConstructionBrushSculpt.MODE.SLOPE and "$l10n_input_CONSTRUCTION_SLOPE" or nil)))
end

function ConstructionBrushSculpt:getButtonSecondaryText()
	if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
		return "$l10n_input_CONSTRUCTION_SHIFT_DOWN"
	elseif self.mode == ConstructionBrushSculpt.MODE.LEVEL then
		return nil
	elseif self.mode == ConstructionBrushSculpt.MODE.SOFTEN then
		return nil
	else
		return self.mode == ConstructionBrushSculpt.MODE.SLOPE and "$l10n_input_CONSTRUCTION_SLOPE_START" or nil
	end
end

function ConstructionBrushSculpt:getAxisPrimaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SIZE"
end

function ConstructionBrushSculpt:getAxisSecondaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_STRENGTH"
end

function ConstructionBrushSculpt:getButtonTertiaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SHAPE"
end
