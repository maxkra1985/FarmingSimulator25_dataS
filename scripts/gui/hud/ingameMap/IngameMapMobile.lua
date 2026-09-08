-- Local values: IngameMapMobile_mt
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutMobile.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutFullscreenMobile.lua")
IngameMapMobile = {}
local IngameMapMobile_mt = Class(IngameMapMobile, IngameMap)
IngameMapMobile.STATE_HIDDEN = 3

-- Upvalues: IngameMapMobile_mt
-- Local values: self, _, layout
function IngameMapMobile.new(hud, hudAtlasPath, controlHudAtlasPath, inputDisplayManager, customMt)
	-- upvalues: (copy) IngameMapMobile_mt
	local v7_ = IngameMap:superClass().new(nil, nil, customMt or IngameMapMobile_mt)
	IngameMapMobile.POSITION.SELF[2] = g_screenHeight * IngameMapMobile.HEIGHT_FACTOR
	v7_.overlay = v7_:createBackground(hudAtlasPath)
	v7_.hud = hud
	v7_.hudAtlasPath = hudAtlasPath
	v7_.controlHudAtlasPath = controlHudAtlasPath
	v7_.inputDisplayManager = inputDisplayManager
	v7_.uiScale = 1
	v7_.isVisible = true
	v7_.mobileLayout = IngameMapLayoutMobile.new()
	v7_.layouts = { v7_.mobileLayout }
	v7_.fullScreenLayout = IngameMapLayoutFullscreenMobile.new()
	v7_.state = 1
	v7_.layout = v7_.layouts[v7_.state]
	v7_.mapOverlay = Overlay.new(nil, 0, 0, 1, 1)
	v7_.mapElement = HUDElement.new(v7_.mapOverlay)
	v7_:createComponents(hudAtlasPath)
	for _, v8_ in ipairs(v7_.layouts) do
		v8_:createComponents(v7_, hudAtlasPath)
	end
	v7_.filter = {}
	v7_.filter[MapHotspot.CATEGORY_FIELD] = true
	v7_.filter[MapHotspot.CATEGORY_ANIMAL] = true
	v7_.filter[MapHotspot.CATEGORY_MISSION] = true
	v7_.filter[MapHotspot.CATEGORY_TOUR] = true
	v7_.filter[MapHotspot.CATEGORY_STEERABLE] = true
	v7_.filter[MapHotspot.CATEGORY_COMBINE] = true
	v7_.filter[MapHotspot.CATEGORY_TRAILER] = true
	v7_.filter[MapHotspot.CATEGORY_TOOL] = true
	v7_.filter[MapHotspot.CATEGORY_UNLOADING] = true
	v7_.filter[MapHotspot.CATEGORY_LOADING] = true
	v7_.filter[MapHotspot.CATEGORY_PRODUCTION] = true
	v7_.filter[MapHotspot.CATEGORY_SHOP] = true
	v7_.filter[MapHotspot.CATEGORY_OTHER] = true
	v7_.filter[MapHotspot.CATEGORY_AI] = true
	v7_.filter[MapHotspot.CATEGORY_PLAYER] = true
	v7_.currentFilter = v7_.filter
	v7_:setWorldSize(2048, 2048)
	v7_.hotspots = {}
	v7_.selectedHotspot = nil
	v7_.allowToggle = true
	v7_.topDownCamera = nil
	v7_.isMapVisible = false
	v7_.toggleSizeAfterDialog = false
	v7_.mapExtensionOffsetX = 0
	v7_.mapExtensionOffsetZ = 0
	v7_.mapExtensionScaleFactor = 1
	v7_.isDrawing = false
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, v7_.updateInsets, v7_)
	return v7_
end

function IngameMapMobile:delete()
	g_messageCenter:unsubscribe(MessageType.INSETS_CHANGED, self)
	IngameMapMobile:superClass().delete(self)
end

function IngameMapMobile:loadMap(filename, worldSizeX, worldSizeZ, fieldColor, grassFieldColor)
	self.mapElement:delete()
	self:setWorldSize(worldSizeX, worldSizeZ)
	self.mapOverlay = Overlay.new(filename, 0, 0, 1, 1)
	self.mapElement = HUDElement.new(self.mapOverlay)
	self:addChild(self.mapElement)
	self:setScale(self.uiScale)
end

-- Local values: baseX, baseY, width, height, posX, posY, sizeX, sizeY, overlay, offsetX, offsetY, circlePosX, circlePosY
function IngameMapMobile:createComponents(hudAtlasPath)
	local v16_, v17_ = self:getPosition()
	self:createFrame(hudAtlasPath, v16_, v17_, self:getWidth(), (self:getHeight()))
	self.buttonUVs = GuiUtils.getUVs(IngameMapMobile.UV.BUTTON)
	self.buttonUVsDisabled = GuiUtils.getUVs(IngameMapMobile.UV.BUTTON_DISABLED)
	self.buttonExtensionUVs = GuiUtils.getUVs(IngameMapMobile.UV.BUTTON_EXTENSION)
	self.buttonExtensionUVsDisabled = GuiUtils.getUVs(IngameMapMobile.UV.BUTTON_EXTENSION_DISABLED)
	self.buttonElement = self:createOverlayElement(IngameMapMobile.POSITION.BUTTON, IngameMapMobile.SIZE.BUTTON, IngameMapMobile.UV.BUTTON, IngameMapMobile.COLOR.MAP_ICON)
	self:addChild(self.buttonElement)
	local v18_, v19_ = self.buttonElement:getPosition()
	local v20_ = getNormalizedScreenValues
	local v21_ = IngameMapMobile.SIZE.BUTTON_EXTENSION
	local v22_, v23_ = v20_(unpack(v21_))
	local v24_ = Overlay.new(self.hudAtlasPath, v18_ - v22_, v19_, v22_, v23_)
	v24_:setUVs(GuiUtils.getUVs(IngameMapMobile.UV.BUTTON_EXTENSION))
	self.buttonExtensionElement = HUDElement.new(v24_)
	self:addChild(self.buttonExtensionElement)
	self.buttonIconElement = self:createOverlayElement(IngameMapMobile.POSITION.BUTTON_ICON, IngameMapMobile.SIZE.BUTTON_ICON, IngameMapMobile.UV.ARROW_RIGHT, IngameMapMobile.COLOR.MAP_ICON, true)
	self:addChild(self.buttonIconElement)
	self.rightBorderElement = self:createOverlayElement(IngameMapMobile.POSITION.RIGHT_BORDER, IngameMapMobile.SIZE.RIGHT_BORDER, HUDElement.UV.FILL, IngameMapMobile.COLOR.RIGHT_BORDER)
	self:addChild(self.rightBorderElement)
	self.toggleButton = self.hud:addTouchButton(self.buttonElement.overlay, 1, 0.4, self.onClickToggleButton, self, TouchHandler.TRIGGER_UP)
	g_touchHandler:setAreaPressedSizeGain(self.toggleButton, 3.5)
	local v25_ = getNormalizedScreenValues
	local v26_ = IngameMapMobile.POSITION.INPUT_GLYPH_OFFSET
	local v27_, v28_ = v25_(unpack(v26_))
	local v29_, v30_ = self.buttonElement:getPosition()
	local v31_ = v29_ + v27_
	local v32_ = v30_ + v28_
	self.glyphElement = InputGlyphMobileElement.new(g_inputDisplayManager)
	self.glyphElement:setAction(InputAction.TOGGLE_MAP_SIZE)
	self.glyphElement:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
	self.glyphElement:setPosition(v31_, v32_)
	self.buttonIconElement:addChild(self.glyphElement)
end

function IngameMapMobile:getHeight()
	return self.overlay.height
end

function IngameMapMobile:setPlayer(player)
	self.player = player
end

function IngameMapMobile:onClickToggleButton(posX, posY)
	if self.isActive then
		self:toggleSize(not self.isMapVisible)
	end
end

-- Local values: baseX, baseY, posX, posY, sizeX, sizeY, overlay
function IngameMapMobile:createOverlayElement(pos, size, uvs, color, isIcon)
	local v43_, v44_ = self:getPosition()
	local v45_, v46_ = getNormalizedScreenValues(unpack(pos))
	local v47_, v48_ = getNormalizedScreenValues(unpack(size))
	local v49_
	if isIcon then
		v49_ = Overlay.new(self.controlHudAtlasPath, v43_ + v45_, v44_ + v46_, v47_, v48_)
	else
		v49_ = Overlay.new(self.hudAtlasPath, v43_ + v45_, v44_ + v46_, v47_, v48_)
	end
	v49_:setUVs(GuiUtils.getUVs(uvs))
	v49_:setColor(unpack(color))
	return HUDElement.new(v49_)
end

function IngameMapMobile:storeScaledValues(uiScale)
	IngameMapMobile:superClass().storeScaledValues(self, uiScale)
	local v52_, v53_ = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP)
	self.mapWidth = v52_
	self.mapHeight = v53_
	local v54_, v55_ = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP)
	self.mapSizeX = v54_
	self.mapSizeY = v55_
	local v56_, v57_ = self:scalePixelToScreenVector(IngameMapMobile.POSITION.MAP)
	self.mapOffsetX = v56_
	self.mapOffsetY = v57_
	self.mapHideWidth = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP_HIDE_WIDTH)
	self.mapToFrameDiffX = self:scalePixelToScreenWidth(IngameMapMobile.SIZE.SELF[1] - IngameMapMobile.SIZE.MAP[1])
	self.mapToFrameDiffY = self:scalePixelToScreenHeight(IngameMapMobile.SIZE.SELF[2] - IngameMapMobile.SIZE.MAP[2])
end

function IngameMapMobile:resetSettings()
	IngameMapMobile:superClass().resetSettings(self)
	if self.overlay ~= nil then
		if not self.isMapVisible then
			self:setPosition(self.mapHideWidth, nil)
		end
	end
end

-- Local values: isButtonActive, wasActive
function IngameMapMobile:updateButton()
	local v60_ = self.isActive
	self.isActive = not g_gui:getIsGuiVisible() and true
	if v60_ ~= self.isActive then
		self.glyphElement:setVisible(self.isActive)
		if self.isActive then
			self.buttonElement:setUVs(self.buttonUVs)
			self.buttonExtensionElement:setUVs(self.buttonExtensionUVs)
			return
		end
		self.buttonElement:setUVs(self.buttonUVsDisabled)
		self.buttonExtensionElement:setUVs(self.buttonExtensionUVsDisabled)
	end
end

function IngameMapMobile:update(dt)
	IngameMapMobile:superClass().update(self, dt)
	if g_gui:getIsDialogVisible() and (self.isMapVisible and not g_inGameMenu.showMap) then
		self:toggleSize(false)
	end
	self:updateButton()
end

function IngameMapMobile:draw()
	if self.isMapVisible then
		IngameMapMobile:superClass().draw(self)
	end
	if self.overlay.visible then
		if self.isMapVisible then
			self.mapFrameElement:draw()
			self.rightBorderElement:draw()
		else
			self.buttonExtensionElement:draw()
		end
		self.buttonElement:draw()
		self.buttonIconElement:draw()
		self.glyphElement:draw()
	end
end

function IngameMapMobile:toggleSize(state, force)
	if g_sleepManager:getIsSleeping() then
		return
	elseif self.isActive then
		IngameMapMobile:superClass().toggleSize(self, 1, force)
		if state == nil then
			state = not self.isMapVisible
		end
		self.isMapVisible = state
		self:setPosition(state and 0 or self.mapHideWidth, nil)
	end
end

function IngameMapMobile:toggleDrawing()
	self.isDrawing = not self.isDrawing
end

-- Local values: leftInset, _, _, _
function IngameMapMobile:setPosition(x, y)
	local v71_, _, _, _ = getSafeFrameInsets()
	local v72_ = x + v71_
	IngameMapMobile:superClass().setPosition(self, v72_, y)
	self.mobileLayout:setOffset(v72_ or 0)
end

-- Local values: posX, posY
function IngameMapMobile:setScale(uiScale)
	IngameMapMobile:superClass().setScale(self, uiScale, uiScale)
	local v75_, v76_ = self:getBackgroundPosition(uiScale)
	self:setPosition(v75_, v76_)
end

function IngameMapMobile:updateInsets()
	self:setScale(self.uiScale)
end

-- Local values: widthOffset, _, _, height, heightOffset, x, y
function IngameMapMobile:getBackgroundPosition(scale)
	local v80_ = getNormalizedScreenValues
	local v81_ = IngameMapMobile.SIZE.MAP_HIDE_WIDTH
	local v82_, _ = v80_(unpack(v81_))
	if self.isMapVisible then
		v82_ = v82_ + IngameMapMobile.MIN_MAP_WIDTH * g_aspectScaleX / g_screenWidth
	end
	local v83_ = getNormalizedScreenValues
	local v84_ = IngameMapMobile.SIZE.SELF
	local _, v85_ = v83_(unpack(v84_))
	local v86_ = IngameMapMobile.HEIGHT_FACTOR
	local v87_, v88_ = GuiUtils.alignToScreenPixels(v82_ * scale, v86_ - v85_ * 0.5 * scale)
	return v87_, v88_
end

-- Local values: width, height, posX, posY
function IngameMapMobile:createBackground()
	local v90_ = getNormalizedScreenValues
	local v91_ = IngameMapMobile.SIZE.SELF
	local v92_, v93_ = v90_(unpack(v91_))
	local v94_, v95_ = self:getBackgroundPosition(1)
	return Overlay.new(nil, v94_, v95_, v92_, v93_)
end

-- Local values: frame
function IngameMapMobile:createFrame(hudAtlasPath, baseX, baseY, width, height)
	local v102_ = HUDFrameElement.new(hudAtlasPath, baseX, baseY, width, height, nil, false, IngameMapMobile.FRAME_THICKNESS)
	local v103_ = IngameMapMobile.COLOR.FRAME
	v102_:setFrameColor(unpack(v103_))
	self.mapFrameElement = v102_
	self:addChild(v102_)
end

function IngameMapMobile:drawPlayersCoordinates() end
IngameMapMobile.MIN_MAP_WIDTH = 464
IngameMapMobile.MIN_MAP_HEIGHT = 470
IngameMapMobile.FRAME_THICKNESS = 2
IngameMapMobile.HEIGHT_FACTOR = 0.55
IngameMapMobile.SIZE = {
	["MAP"] = { IngameMapMobile.MIN_MAP_WIDTH, IngameMapMobile.MIN_MAP_HEIGHT },
	["SELF"] = { IngameMapMobile.MIN_MAP_WIDTH + IngameMapMobile.FRAME_THICKNESS * 2, IngameMapMobile.MIN_MAP_HEIGHT + IngameMapMobile.FRAME_THICKNESS },
	["RIGHT_BORDER"] = { IngameMapMobile.FRAME_THICKNESS, IngameMapMobile.MIN_MAP_HEIGHT + IngameMapMobile.FRAME_THICKNESS },
	["BUTTON"] = { 86, 106 },
	["BUTTON_EXTENSION"] = { 150, 106 },
	["BUTTON_ICON"] = { 96, 96 },
	["MAP_HIDE_WIDTH"] = { -IngameMapMobile.MIN_MAP_WIDTH - IngameMapMobile.FRAME_THICKNESS * 2 - 4, 0 }
}
IngameMapMobile.POSITION = {
	["INPUT_GLYPH_OFFSET"] = { 103, 81 },
	["SELF"] = { 0, 540 },
	["MAP"] = { IngameMapMobile.FRAME_THICKNESS, IngameMapMobile.FRAME_THICKNESS },
	["RIGHT_BORDER"] = { IngameMapMobile.FRAME_THICKNESS + IngameMapMobile.MIN_MAP_WIDTH, 0 },
	["BUTTON"] = { IngameMapMobile.SIZE.RIGHT_BORDER[1] + IngameMapMobile.MIN_MAP_WIDTH, IngameMapMobile.MIN_MAP_HEIGHT / 2 - IngameMapMobile.SIZE.BUTTON[2] / 2 },
	["BUTTON_ICON"] = { IngameMapMobile.SIZE.RIGHT_BORDER[1] + IngameMapMobile.MIN_MAP_WIDTH - 5, IngameMapMobile.MIN_MAP_HEIGHT / 2 - IngameMapMobile.SIZE.BUTTON_ICON[2] / 2 }
}
IngameMapMobile.UV = {
	["BUTTON"] = {
		152,
		908,
		86,
		106
	},
	["BUTTON_EXTENSION"] = {
		160,
		908,
		10,
		106
	},
	["BUTTON_DISABLED"] = {
		364,
		908,
		86,
		106
	},
	["BUTTON_EXTENSION_DISABLED"] = {
		372,
		908,
		10,
		106
	},
	["BUTTON_ICON"] = {
		504,
		96,
		48,
		96
	},
	["ARROW_RIGHT"] = {
		96,
		96,
		-96,
		96
	}
}
IngameMapMobile.COLOR = {
	["RIGHT_BORDER"] = {
		0.098039,
		0.098039,
		0.098039,
		1
	},
	["MAP_ICON"] = {
		1,
		1,
		1,
		1
	},
	["FRAME"] = {
		0.098039,
		0.098039,
		0.098039,
		1
	}
}
