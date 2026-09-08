-- Local values: HUDButtonElement_mt
HUDButtonElement = {}
local HUDButtonElement_mt = Class(HUDButtonElement, HUDElement)

-- Upvalues: HUDButtonElement_mt
-- Local values: uvsNormal, sizeX, sizeY, overlay, self
function HUDButtonElement.new(hud, posX, posY, parent, customMt)
	-- upvalues: (copy) HUDButtonElement_mt
	local v7_ = GuiUtils.getUVs(HUDButtonElement.UV.BUTTON_NORMAL)
	local v8_ = getNormalizedScreenValues
	local v9_ = HUDButtonElement.SIZE.BUTTON
	local v10_, v11_ = v8_(unpack(v9_))
	local v12_ = Overlay.new(g_baseHUDFilename, posX, posY, v10_, v11_)
	v12_:setUVs(v7_)
	local v13_ = HUDElement.new(v12_, parent, customMt or HUDButtonElement_mt)
	v13_.hud = hud
	v13_.uvsNormal = v7_
	v13_.uvsPressed = GuiUtils.getUVs(HUDButtonElement.UV.BUTTON_PRESSED)
	v13_.uvsDisabled = GuiUtils.getUVs(HUDButtonElement.UV.BUTTON_DISABLED)
	v13_.iconElement = nil
	v13_.touchAreas = {}
	v13_.isActive = true
	v13_.isPressed = false
	v13_.isDisabled = false
	return v13_
end

function HUDButtonElement:delete()
	self:removeTouchHandler()
	HUDButtonElement:superClass().delete(self)
end

-- Local values: slice
function HUDButtonElement:setIconSlice(sliceId, sizeX, sizeY, offsetX, offsetY, color)
	local v22_ = g_overlayManager:getSliceInfoById(sliceId)
	self:setIcon(v22_.filename, sizeX, sizeY, v22_.uvs, offsetX, offsetY, color)
end

-- Local values: posX, posY, width, height, iconPosX, iconPosY, iconOverlay
function HUDButtonElement:setIcon(filename, sizeX, sizeY, uvs, offsetX, offsetY, color)
	local v31_, v32_ = self:getPosition()
	local v33_ = self:getWidth()
	local v34_ = self:getHeight()
	local v35_, v36_
	if self.iconElement == nil then
		v35_ = sizeX or v33_
		v36_ = sizeY or v34_
	else
		v35_ = sizeX or self.iconElement:getWidth()
		v36_ = sizeY or self.iconElement:getHeight()
	end
	local v37_ = v31_ + (offsetX or (v33_ - v35_) * 0.5)
	local v38_ = v32_ + (offsetY or (v34_ - v36_) * 0.5)
	local v39_
	if self.iconElement == nil then
		v39_ = Overlay.new(filename, v37_, v38_, v35_, v36_)
		self.iconElement = HUDElement.new(v39_)
	else
		v39_ = self.iconElement.overlay
		if filename ~= nil then
			v39_:setImage(filename)
		end
	end
	if uvs ~= nil then
		v39_:setUVs(uvs)
	end
	if color ~= nil then
		v39_:setColor(unpack(color))
	end
	self:addChild(self.iconElement)
end

function HUDButtonElement:setIsPressed(isPressed)
	if self.isPressed ~= isPressed then
		self.isPressed = isPressed
		self:updateUVs()
	end
end

function HUDButtonElement:setDisabled(isDisabled)
	if self.isDisabled ~= isDisabled then
		self.isDisabled = isDisabled
		self:updateUVs()
		self:updateButtonState()
	end
end

function HUDButtonElement:updateUVs()
	if self.isDisabled then
		self:setUVs(self.uvsDisabled)
		return
	elseif self.isPressed then
		self:setUVs(self.uvsPressed)
	else
		self:setUVs(self.uvsNormal)
	end
end

-- Local values: pressButton, releaseButton, buttonCb
function HUDButtonElement:addTouchHandler(callback, target)
	local v48_ = self.touchAreas
	local v49_ = self.hud
	local v50_ = self.overlay
	local v51_ = TouchHandler.TRIGGER_UP
	table.insert(v48_, v49_:addTouchButton(v50_, 0.2, 0.2, function(_, p52_, p53_, p54_)
		-- upvalues: (copy) callback, (copy) target
		if not p54_ then
			callback(target, p52_, p53_)
		end
	end, self, v51_, { self }))
	local v55_ = self.touchAreas
	local v56_ = self.hud
	local v57_ = self.overlay
	local v58_ = TouchHandler.TRIGGER_DOWN
	table.insert(v55_, v56_:addTouchButton(v57_, 0.2, 0.2, function(_)
		-- upvalues: (copy) self
		self:setIsPressed(true)
	end, self, v58_))
	local v59_ = self.touchAreas
	local v60_ = self.hud
	local v61_ = self.overlay
	local v62_ = TouchHandler.TRIGGER_UP
	table.insert(v59_, v60_:addTouchButton(v61_, 0.2, 0.2, function(_)
		-- upvalues: (copy) self
		self:setIsPressed(false)
	end, self, v62_))
end

-- Local values: _, area
function HUDButtonElement:removeTouchHandler()
	for _, v64_ in ipairs(self.touchAreas) do
		g_currentMission.hud:removeTouchButton(v64_)
	end
	self.touchAreas = {}
end

-- Local values: baseX, baseY, offsetX, offsetY, posX, posY
function HUDButtonElement:setAction(inputAction)
	if self.glyphElement ~= nil then
		self.glyphElement:delete()
		self.glyphElement = nil
	end
	if inputAction ~= nil then
		local v67_, v68_ = self:getPosition()
		local v69_ = getNormalizedScreenValues
		local v70_ = HUDButtonElement.POSITION.INPUT_GLYPH_OFFSET
		local v71_, v72_ = v69_(unpack(v70_))
		local v73_ = v67_ + v71_
		local v74_ = v68_ + v72_
		self.glyphElement = InputGlyphMobileElement.new(g_inputDisplayManager)
		self.glyphElement:setAction(inputAction)
		self.glyphElement:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
		self.glyphElement:setPosition(v73_, v74_)
		self:addChild(self.glyphElement)
	end
end

function HUDButtonElement:setIsActive(isActive)
	self.isActive = isActive
	self:updateButtonState()
end

-- Local values: isActive, _, area
function HUDButtonElement:updateButtonState()
	local v78_ = self.isActive and not self.isDisabled
	if v78_ then
		v78_ = self:getVisible()
	end
	for _, v79_ in ipairs(self.touchAreas) do
		g_touchHandler:setTouchAreaVisibility(v79_, v78_)
	end
	if self.glyphElement ~= nil then
		self.glyphElement:setVisible(v78_)
	end
end

function HUDButtonElement:setVisible(isVisible)
	HUDButtonElement:superClass().setVisible(self, isVisible)
	self:updateButtonState()
end
HUDButtonElement.POSITION = {
	["INPUT_GLYPH_OFFSET"] = { 123, 81 },
	["INPUT_GLYPH_ICON_OFFSET"] = { -2, -1 }
}
HUDButtonElement.SIZE = {
	["BUTTON"] = { 106, 106 },
	["INPUT_GLYPH_BG_LEFT"] = { 46, 96 },
	["INPUT_GLYPH_BG_MIDDLE"] = { 34, 96 },
	["INPUT_GLYPH_BG_RIGHT"] = { 46, 96 },
	["INPUT_GLYPH_ICON"] = { 48, 48 }
}
HUDButtonElement.UV = {
	["BUTTON_NORMAL"] = {
		132,
		908,
		106,
		106
	},
	["BUTTON_PRESSED"] = {
		238,
		908,
		106,
		106
	},
	["BUTTON_DISABLED"] = {
		344,
		908,
		106,
		106
	},
	["GLYPH_BG_LEFT"] = {
		288,
		432,
		46,
		96
	},
	["GLYPH_BG_MIDDLE"] = {
		334,
		432,
		38,
		96
	},
	["GLYPH_BG_RIGHT"] = {
		372,
		432,
		46,
		96
	}
}
HUDButtonElement.COLOR = {
	["INPUT_GLYPH"] = {
		0,
		0,
		0,
		1
	}
}
