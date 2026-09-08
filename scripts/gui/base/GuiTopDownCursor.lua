-- Local values: GuiTopDownCursor_mt
GuiTopDownCursor = {}
local GuiTopDownCursor_mt = Class(GuiTopDownCursor)
GuiTopDownCursor.ROTATION_SPEED = 0.002
GuiTopDownCursor.SHAPES_FILENAME = "data/shared/assets/constructionCursorSimple.i3d"
GuiTopDownCursor.RAYCAST_DISTANCE = -2 * GuiTopDownCamera.DISTANCE_RANGE_Z
GuiTopDownCursor.SNAP_STATE_INACTIVE = 0
GuiTopDownCursor.SNAP_STATE_POSITIVE = 1
GuiTopDownCursor.SNAP_STATE_NEGATIVE = 2
GuiTopDownCursor.SNAP_STATE_USED = 3
GuiTopDownCursor.SHAPES = {
	["NONE"] = 0,
	["CIRCLE"] = 1,
	["SQUARE"] = 2
}
GuiTopDownCursor.SHAPES_COLORS = {
	["SUCCESS"] = 0,
	["ERROR"] = 1,
	["SCULPTING"] = 2,
	["SELECT"] = 3,
	["PAINTING"] = 4
}
local v2_ = GuiTopDownCursor
local v3_ = CollisionFlag.TERRAIN
local v4_ = CollisionFlag.TERRAIN_DELTA
local v5_ = CollisionFlag.STATIC_OBJECT
local v6_ = CollisionFlag.BUILDING
local v7_ = CollisionFlag.ROAD
v2_.RAYCAST_COLLISION_MASK_DEFAULT = bit32.bor(v3_, v4_, v5_, v6_, v7_)

-- Upvalues: GuiTopDownCursor_mt
-- Local values: self
function GuiTopDownCursor.new(subclass_mt)
	-- upvalues: (copy) GuiTopDownCursor_mt
	local v9_ = subclass_mt or GuiTopDownCursor_mt
	local v10_ = setmetatable({}, v9_)
	v10_.isActive = false
	v10_.ray = {}
	v10_.cursorShapeHeights = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	v10_.isVisible = true
	v10_.rotationY = 0
	v10_.targetRotation = 0
	v10_.inputRotate = 0
	v10_.lastActionFrame = 0
	v10_.isCatchingCursor = false
	v10_.shapeScale = 1
	v10_.rotationEnabled = false
	v10_.lightEnabled = false
	v10_.selectionMode = false
	v10_.rayCollisionMask = GuiTopDownCursor.RAYCAST_COLLISION_MASK_DEFAULT
	v10_:setTerrainOnly(false)
	v10_.shapesLoaded = false
	v10_.snapAngle = nil
	v10_.snapUpdateState = GuiTopDownCursor.SNAP_STATE_INACTIVE
	return v10_
end

function GuiTopDownCursor:delete()
	if self.isActive then
		self:deactivate()
	end
	if self.cursorOverlay ~= nil then
		self.cursorOverlay:delete()
		self.cursorOverlay = nil
	end
	if self.rootNode ~= nil then
		delete(self.rootNode)
	end
	if self.loadRequestId ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
		self.loadRequestId = nil
	end
end

function GuiTopDownCursor:loadShapes()
	if self.loadRequestId == nil then
		self.loadRequestId = g_i3DManager:loadI3DFileAsync(GuiTopDownCursor.SHAPES_FILENAME, false, false, self.onLoadedI3D, self, nil)
	end
end

-- Local values: uiScale, width, height
function GuiTopDownCursor:onLoadedI3D(nodeId, failedReason, asyncCallbackArguments)
	self.loadRequestId = nil
	if failedReason == LoadI3DFailedReason.NONE then
		self.rootNode = createTransformGroup("topDownCursorRootNode")
		link(getRootNode(), self.rootNode)
		self.shapeNode = getChildAt(nodeId, 0)
		link(self.rootNode, self.shapeNode)
		delete(nodeId)
		setScale(self.shapeNode, self.shapeScale, self.shapeScale, self.shapeScale)
		setVisibility(self.rootNode, false)
		setWorldRotation(self.rootNode, 0, self.rotationY, 0)
		self:setShape(GuiTopDownCursor.SHAPES.NONE)
		self:setShapeSize(1)
		self:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT)
		self:setCursorTerrainOffset(false)
		self.shapesLoaded = true
		local v16_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
		local v17_, v18_ = getNormalizedScreenValues(20 * v16_, 20 * v16_)
		self.cursorOverlay = g_overlayManager:createOverlay("gui.whiteCircleFat", 0.5, 0.5, v17_, v18_)
		self.cursorOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
		self.cursorOverlay:setColor(1, 1, 1, 0.3)
		setVisibility(self.rootNode, self.isVisible)
	end
end

function GuiTopDownCursor:activate()
	self.isActive = true
	self:onInputModeChanged({ g_inputBinding:getLastInputMode() })
	if not self.shapesLoaded then
		self:loadShapes()
	end
	if self.rootNode ~= nil then
		setVisibility(self.rootNode, self.isVisible)
	end
	self:registerActionEvents()
	g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
end

function GuiTopDownCursor:deactivate()
	if self.rootNode ~= nil then
		setVisibility(self.rootNode, false)
	end
	g_messageCenter:unsubscribeAll(self)
	self:removeActionEvents()
	self.isActive = false
end

-- Local values: ray
function GuiTopDownCursor:setCameraRay(x, y, z, dx, dy, dz)
	local v28_ = self.ray
	v28_.x = x
	v28_.y = y
	v28_.z = z
	v28_.dx = dx
	v28_.dy = dy
	v28_.dz = dz
end

-- Local values: material
function GuiTopDownCursor:setShape(shape)
	self.shape = shape
	if self.shapeNode ~= nil then
		setVisibility(self.shapeNode, shape ~= GuiTopDownCursor.SHAPES.NONE)
		local v31_ = getMaterial(self.shapeNode, 0)
		if shape == GuiTopDownCursor.SHAPES.CIRCLE then
			setMaterialCustomShaderVariation(v31_, "circle", true)
			return
		end
		if shape == GuiTopDownCursor.SHAPES.SQUARE then
			setMaterialCustomShaderVariation(v31_, "square", true)
		end
	end
end

function GuiTopDownCursor:setVisible(isVisible)
	self.isVisible = isVisible
	if self.rootNode ~= nil then
		setVisibility(self.rootNode, isVisible)
	end
end

function GuiTopDownCursor:setIsWaterDetectionActive(isActive)
	if isActive then
		local v36_ = self.rayCollisionMask
		local v37_ = CollisionFlag.WATER
		self.rayCollisionMask = bit32.bor(v36_, v37_)
	else
		local v38_ = self.rayCollisionMask
		local v39_ = CollisionFlag.WATER
		local v40_ = bit32.bnot(v39_)
		self.rayCollisionMask = bit32.band(v38_, v40_)
	end
end

function GuiTopDownCursor:setTerrainOnly(terrainOnly)
	self.hitTerrainOnly = terrainOnly
	if terrainOnly then
		self.rayCollisionMask = CollisionFlag.TERRAIN
	else
		self.rayCollisionMask = GuiTopDownCursor.RAYCAST_COLLISION_MASK_DEFAULT
	end
end

function GuiTopDownCursor:setSelectionMode(isSelection)
	self.selectionMode = isSelection
	if isSelection then
		self.rayCollisionMask = CollisionMask.ALL - CollisionFlag.TRIGGER - CollisionFlag.FILLABLE - CollisionFlag.TERRAIN_DISPLACEMENT
	else
		self.rayCollisionMask = GuiTopDownCursor.RAYCAST_COLLISION_MASK_DEFAULT
	end
end

function GuiTopDownCursor:setRotationEnabled(isEnabled)
	if self.rotationEnabled ~= isEnabled then
		self.rotationEnabled = isEnabled
		if self.rotateEventId ~= nil then
			g_inputBinding:setActionEventActive(self.rotateEventId, self.rotationEnabled)
		end
	end
end

function GuiTopDownCursor:setRotation(rotY)
	self.targetRotation = rotY
	self.rotationY = rotY
end

function GuiTopDownCursor:setLightEnabled(isEnabled)
	self.lightEnabled = isEnabled
end

function GuiTopDownCursor:setShapeSize(size)
	if self.shapeNode ~= nil then
		setScale(self.shapeNode, size, size, size)
	end
	self.shapeScale = size
end

function GuiTopDownCursor:getMessagePosition()
	if self.isCatchingCursor then
		return self.lockedMousePosX, self.lockedMousePosY
	else
		return self.mousePosX, self.mousePosY
	end
end

-- Local values: x, y, textSize
function GuiTopDownCursor:setErrorMessage(message)
	local v56_, v57_ = self:getMessagePosition()
	if v56_ ~= nil then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		local v58_ = getCorrectTextSize(0.016)
		local v59_ = v56_ + 0.01
		setTextColor(0, 0, 0, 0.75)
		renderText(v59_, v57_ - 0.0015, v58_, message)
		setTextColor(1, 0.5, 0.5, 1)
		renderText(v59_, v57_, v58_, message)
		setTextColor(1, 1, 1, 1)
	end
end

-- Local values: x, y, textSize
function GuiTopDownCursor:setMessage(message)
	local v62_, v63_ = self:getMessagePosition()
	if v62_ ~= nil then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(false)
		local v64_ = getCorrectTextSize(0.016)
		local v65_ = v63_ + 0.01
		setTextColor(0, 0, 0, 0.75)
		renderText(v62_, v65_ - 0.0015, v64_, message)
		setTextColor(1, 1, 1, 1)
		renderText(v62_, v65_, v64_, message)
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

function GuiTopDownCursor:setColor(r, g, b, a)
	if self.shapeNode ~= nil then
		setShaderParameter(self.shapeNode, "colorInside", r, g, b, a, true)
		setShaderParameter(self.shapeNode, "colorOutside", r, g, b, 1, true)
	end
end

function GuiTopDownCursor:setGradientColor(ri, gi, bi, ro, go, bo, a)
	if self.shapeNode ~= nil then
		setShaderParameter(self.shapeNode, "colorInside", ri, gi, bi, a, true)
		setShaderParameter(self.shapeNode, "colorOutside", ro, go, bo, 1, true)
	end
end

function GuiTopDownCursor:setColorMode(mode, alpha)
	local v82_ = alpha == nil and 0.3 or alpha
	if mode == GuiTopDownCursor.SHAPES_COLORS.SUCCESS then
		self:setColor(0, 1, 0, v82_)
		return
	elseif mode == GuiTopDownCursor.SHAPES_COLORS.ERROR then
		self:setColor(1, 0, 0, v82_)
		return
	elseif mode == GuiTopDownCursor.SHAPES_COLORS.SCULPTING then
		self:setGradientColor(1, 0, 0, 0, 1, 0, v82_)
		return
	elseif mode == GuiTopDownCursor.SHAPES_COLORS.SELECT then
		self:setColor(1, 1, 1, v82_)
	elseif mode == GuiTopDownCursor.SHAPES_COLORS.PAINTING then
		self:setColor(1, 1, 1, 0.25)
	end
end

function GuiTopDownCursor:setCursorTerrainOffset(isLarge)
	if isLarge then
		self.terrainBrushOffset = 0.5
	else
		self.terrainBrushOffset = 0.05
	end
end

function GuiTopDownCursor:setSnapAngle(angle)
	self.snapAngle = angle
	self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_INACTIVE
end

function GuiTopDownCursor:getHitNode()
	if self.currentHitId == g_terrainNode then
		return nil
	else
		return self.currentHitId
	end
end

-- Local values: object
function GuiTopDownCursor:getHitPlaceable()
	if self.currentHitId == nil or self.currentHitId == g_terrainNode then
		return nil
	else
		local v89_ = g_currentMission:getNodeObject(self.currentHitId)
		if v89_ == nil or not v89_:isa(Placeable) then
			return nil
		else
			return v89_
		end
	end
end

function GuiTopDownCursor:getHitObject()
	if self.currentHitId == nil or self.currentHitId == g_terrainNode then
		return nil
	else
		return g_currentMission:getNodeObject(self.currentHitId)
	end
end

function GuiTopDownCursor:getHitTerrainPosition()
	if self.currentHitId == g_terrainNode then
		return self.currentHitX, self.currentHitY, self.currentHitZ
	else
		return nil, nil, nil
	end
end

function GuiTopDownCursor:getRotation()
	return self.rotationY % 6.283185307179586
end

function GuiTopDownCursor:getPosition()
	return self.currentHitX, self.currentHitY, self.currentHitZ
end

function GuiTopDownCursor:update(dt)
	if self.isActive then
		self:updateRaycast()
		self:updateRotation(dt)
	end
end

function GuiTopDownCursor:draw()
	if self.cursorOverlay ~= nil then
		if not self.isMouseMode and self.selectionMode then
			self.cursorOverlay:render()
		end
	end
end

-- Local values: ray, cursorShouldBeVisible, id, x, y, z
function GuiTopDownCursor:updateRaycast()
	local v98_ = self.ray
	local v99_ = false
	if v98_.x == nil then
		self.currentHitId = nil
	else
		local v100_, v101_, v102_, v103_ = RaycastUtil.raycastClosest(v98_.x, v98_.y, v98_.z, v98_.dx, v98_.dy, v98_.dz, GuiTopDownCursor.RAYCAST_DISTANCE, self.rayCollisionMask)
		self.currentHitId = v100_
		self.currentHitX = v101_
		self.currentHitY = v102_
		self.currentHitZ = v103_
		v99_ = self:setPosition(v101_, v102_, v103_)
	end
	self:setVisible(v99_)
end

-- Local values: cursorShouldBeVisible
function GuiTopDownCursor:setPosition(x, y, z)
	local v108_ = false
	if self.currentHitId ~= nil and x ~= nil then
		if self.rootNode ~= nil then
			setWorldTranslation(self.rootNode, x, y, z)
		end
		if self.shapeNode ~= nil then
			v108_ = not self.hitTerrainOnly or g_terrainNode == self.currentHitId
			if v108_ and getVisibility(self.shapeNode) then
				self:updateCursorHeights(x, y, z, self.shapeScale)
			end
		end
	end
	return v108_
end

-- Local values: inputRotate, dir, snappedRotation, rotateChange
function GuiTopDownCursor:updateRotation(dt)
	local v111_ = self.inputRotate
	self.inputRotate = 0
	if self.snapAngle ~= nil then
		if self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_USED then
			return
		end
		if self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_POSITIVE or self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_NEGATIVE then
			local v112_ = self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_POSITIVE and 1 or -1
			local v113_ = MathUtil.snapValue
			local v114_ = self.rotationY + v112_ * self.snapAngle
			local v115_ = math.deg(v114_)
			local v116_ = self.snapAngle
			local v117_ = v113_(v115_, (math.deg(v116_)))
			self:setRotation(math.rad(v117_) % 6.283185307179586)
			self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_USED
			return
		end
	end
	self.targetRotation = self.targetRotation - dt * v111_ * GuiTopDownCursor.ROTATION_SPEED
	local v118_ = (self.targetRotation - self.rotationY) / dt * 5
	if v118_ < 0.0001 and v118_ > -0.0001 then
		self.rotationY = self.targetRotation
	else
		self.rotationY = self.rotationY + v118_
	end
	if self.snapAngle ~= nil then
		local v119_ = MathUtil.snapValue
		local v120_ = self.rotationY
		local v121_ = math.deg(v120_)
		local v122_ = self.snapAngle
		local v123_ = v119_(v121_, (math.deg(v122_)))
		self.rotationY = math.rad(v123_)
	end
end

-- Local values: offsetY, terrain, h, i, offsetZ, zs, j, offsetX, row, col
function GuiTopDownCursor:updateCursorHeights(x, y, z, scale)
	if self.shapeNode ~= nil then
		local v129_ = self.terrainBrushOffset - y
		local v130_ = g_terrainNode
		local v131_ = self.cursorShapeHeights
		for v132_ = 1, 8 do
			local v133_ = z + (0.14285714285714285 * (v132_ - 1) - 0.5) * scale
			for v134_ = 1, 8 do
				local v135_ = (0.14285714285714285 * (v134_ - 1) - 0.5) * scale
				v131_[v134_] = getTerrainHeightAtWorldPos(v130_, x + v135_, 0, v133_) + v129_
			end
			local v136_ = v132_ / 2
			local v137_ = math.ceil(v136_)
			local v138_ = (v132_ - 1) % 2 + 1
			setShaderParameter(self.shapeNode, "heights" .. v137_ .. v138_ * 2 - 1, v131_[1], v131_[2], v131_[3], v131_[4], true)
			setShaderParameter(self.shapeNode, "heights" .. v137_ .. v138_ * 2, v131_[5], v131_[6], v131_[7], v131_[8], true)
		end
	end
end

-- Local values: _, eventId
function GuiTopDownCursor:registerActionEvents()
	local _, v140_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CURSOR_ROTATE, self, self.onRotate, false, false, true, false)
	self.rotateEventId = v140_
	g_inputBinding:setActionEventActive(self.rotateEventId, self.rotationEnabled)
	g_inputBinding:setActionEventTextPriority(self.rotateEventId, GS_PRIO_NORMAL)
end

function GuiTopDownCursor:removeActionEvents()
	self.rotateEventId = nil
	g_inputBinding:removeActionEventsByTarget(self)
end

function GuiTopDownCursor:mouseEvent(posX, posY, isDown, isUp, button)
	if self.mouseDisabled then
		return
	elseif self.lastActionFrame >= g_time then
		return
	elseif self.isCatchingCursor then
		self.isCatchingCursor = false
		g_inputBinding:setShowMouseCursor(true, true)
		wrapMousePosition(self.lockedMousePosX, self.lockedMousePosY)
		local v145_ = g_inputBinding
		local v146_ = g_inputBinding
		local v147_ = self.lockedMousePosX
		local v148_ = self.lockedMousePosY
		v145_.mousePosXLast = v147_
		v146_.mousePosYLast = v148_
		self.mousePosX = self.lockedMousePosX
		self.mousePosY = self.lockedMousePosY
	elseif self.isMouseMode then
		self.mousePosX = posX
		self.mousePosY = posY
	end
end

function GuiTopDownCursor:onRotate(_, inputValue, _, isAnalog, isMouse, category, binding)
	if not (isMouse and self.mouseDisabled) then
		if isMouse then
			self.lastActionFrame = g_time
			if not self.isCatchingCursor then
				local v154_ = g_inputBinding.mousePosXLast or 0.5
				local v155_ = g_inputBinding.mousePosYLast or 0.5
				self.lockedMousePosX = v154_
				self.lockedMousePosY = v155_
				g_inputBinding:setShowMouseCursor(false, true)
				self.isCatchingCursor = true
			end
			if isAnalog then
				inputValue = inputValue * 3
			end
			self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_INACTIVE
		elseif self.snapAngle ~= nil then
			if binding.isUpFlank then
				self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_INACTIVE
			elseif self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_INACTIVE and binding.isDownFlank then
				self.snapUpdateState = inputValue > 0 and GuiTopDownCursor.SNAP_STATE_POSITIVE or GuiTopDownCursor.SNAP_STATE_NEGATIVE
			end
		end
		self.inputRotate = inputValue
	end
end

function GuiTopDownCursor:onInputModeChanged(inputMode)
	self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD
	if not self.isMouseMode then
		self.mousePosX = 0.5
		self.mousePosY = 0.5
	end
end
