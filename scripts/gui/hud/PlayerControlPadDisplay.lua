-- Local values: data, old, PlayerControlPadDisplay_mt, playerControlPadDisplay, k, elem
local v1_
if PlayerControlPadDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.playerControlPadDisplay
	v1_ = {
		["player"] = v2_.player,
		["hud"] = v2_.hud,
		["uiScale"] = v2_.uiScale,
		["hudAtlasPath"] = v2_.hudAtlasPath
	}
	v2_:delete()
end
PlayerControlPadDisplay = {}
local data = Class(PlayerControlPadDisplay, HUDDisplayElement)

-- Upvalues: PlayerControlPadDisplay_mt
-- Local values: backgroundOverlay, self
function PlayerControlPadDisplay.new(hud, hudAtlasPath)
	-- upvalues: (copy) data
	local v6_ = PlayerControlPadDisplay.createBackground()
	local v7_ = PlayerControlPadDisplay:superClass().new(v6_, nil, data)
	v7_.hud = hud
	v7_.uiScale = 1
	v7_.hudAtlasPath = hudAtlasPath
	v7_.player = nil
	v7_.joystickPosX = 0.5
	v7_.joystickPosY = 0.5
	v7_.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	v7_:createComponents()
	return v7_
end

function PlayerControlPadDisplay:setPlayer(player)
	self.player = player
	self:updateVisibilityState()
end

-- Local values: baseX, baseY, bgSizeX, bgSizeY, backgroundOverlay, joySizeX, joySizeY, joystickOverlay, joystickOverlayX, joystickOverlayY
function PlayerControlPadDisplay:createComponents()
	local v11_, v12_ = self:getPosition()
	local v13_ = getNormalizedScreenValues
	local v14_ = PlayerControlPadDisplay.SIZE.BACKGROUND
	local v15_, v16_ = v13_(unpack(v14_))
	local v17_ = Overlay.new(self.hudAtlasPath, v11_, v12_, v15_, v16_)
	v17_:setUVs(GuiUtils.getUVs(PlayerControlPadDisplay.UV.BACKGROUND))
	self.backgroundHudElement = HUDElement.new(v17_)
	self:addChild(self.backgroundHudElement)
	self.uvs = GuiUtils.getUVs(PlayerControlPadDisplay.UV.JOYSTICK)
	self.uvsDisabled = GuiUtils.getUVs(PlayerControlPadDisplay.UV.JOYSTICK_DISABLED)
	local v18_ = getNormalizedScreenValues
	local v19_ = PlayerControlPadDisplay.SIZE.JOYSTICK
	local v20_, v21_ = v18_(unpack(v19_))
	local v22_ = Overlay.new(self.hudAtlasPath, v11_ + v20_ * 0.5, v12_ + v21_ * 0.5, v20_, v21_)
	v22_:setUVs(self.uvs)
	self.joystickElement = HUDElement.new(v22_)
	self:addChild(self.joystickElement)
	local v23_ = Overlay.new(nil, v11_ + v20_ * 0.5, v12_ + v21_ * 0.5, v20_, v21_)
	local v24_ = Overlay.new(nil, v11_ + v20_ * 0.5, v12_ + v21_ * 0.5, v20_, v21_)
	self.joystickXHudElement = HUDSliderElement.new(v23_, v17_, 1, 1, 20, 1, 0, 0.5, 1, nil)
	self.joystickXHudElement:setCallback(self.onSliderPositionChangedX, self)
	self.joystickXHudElement.radius = v15_ / 2
	self:addChild(self.joystickXHudElement)
	self.joystickYHudElement = HUDSliderElement.new(v24_, v17_, 1, 1, 20, 2, 0, 0.5, 1, nil)
	self.joystickYHudElement:setCallback(self.onSliderPositionChangedY, self)
	self.joystickYHudElement.radius = v16_ / 2
	self:addChild(self.joystickYHudElement)
	self:updateSliderTranslations(1)
	self.joystickXHudElement:setAxisPosition(self.joystickXHudElement.centerTrans)
	self.joystickYHudElement:setAxisPosition(self.joystickYHudElement.centerTrans)
end

-- Local values: width, height, joySizeX, joySizeY, joySizeXHalf, joySizeYHalf, sliderMinX, sliderCenterX, sliderMaxX, sliderMinY, sliderCenterY, sliderMaxY
function PlayerControlPadDisplay:updateSliderTranslations(uiScale)
	local v27_ = self:getWidth()
	local v28_ = self:getHeight()
	local v29_ = getNormalizedScreenValues
	local v30_ = PlayerControlPadDisplay.SIZE.JOYSTICK
	local v31_, v32_ = v29_(unpack(v30_))
	local v33_ = v31_ * 0.5 * uiScale
	local v34_ = v32_ * 0.5 * uiScale
	local v35_ = -v33_
	local v36_ = v27_ * 0.5 - v33_
	local v37_ = v27_ - v33_
	local v38_ = -v34_
	local v39_ = v28_ * 0.5 - v34_
	local v40_ = v28_ - v34_
	self.joystickXHudElement:setRange(v35_, v36_, v37_, nil)
	self.joystickXHudElement.radius = v27_ * 0.5
	self.joystickYHudElement:setRange(v38_, v39_, v40_, nil)
	self.joystickYHudElement.radius = v28_ * 0.5
end

function PlayerControlPadDisplay:setVisible(isVisible, animate)
	if not isVisible or g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD then
		PlayerControlPadDisplay:superClass().setVisible(self, isVisible, animate)
	end
end

-- Local values: posX, _
function PlayerControlPadDisplay:onSliderPositionChangedX(position)
	self.joystickPosX = position * 2 - 1
	local v46_, _ = self:updateJoystickPosition()
	self.joystickElement:setPosition(v46_, nil)
	return v46_
end

-- Local values: _, posY
function PlayerControlPadDisplay:onSliderPositionChangedY(position)
	self.joystickPosY = position * 2 - 1
	local _, v49_ = self:updateJoystickPosition()
	return v49_
end

-- Local values: distance, posX, posY
function PlayerControlPadDisplay:updateJoystickPosition()
	local v51_ = self.joystickPosX ^ 2 + self.joystickPosY ^ 2
	local v52_ = math.sqrt(v51_)
	if v52_ <= 1 then
		return nil
	end
	self.joystickPosX = self.joystickPosX / v52_
	local v53_ = self.joystickXHudElement.minTrans + (self.joystickXHudElement.maxTrans - self.joystickXHudElement.minTrans) * (self.joystickPosX / 2 + 0.5)
	self.joystickXHudElement:setAxisPosition(v53_, true)
	self.joystickPosY = self.joystickPosY / v52_
	local v54_ = self.joystickYHudElement.minTrans + (self.joystickYHudElement.maxTrans - self.joystickYHudElement.minTrans) * (self.joystickPosY / 2 + 0.5)
	self.joystickYHudElement:setAxisPosition(v54_, true)
	return v53_, v54_
end

function PlayerControlPadDisplay:onInputHelpModeChange(inputHelpMode)
	self.lastInputHelpMode = inputHelpMode
	self:updateVisibilityState()
end

-- Local values: animationState
function PlayerControlPadDisplay:updateVisibilityState()
	local v58_ = self:getIsPlayerMoveActive()
	if v58_ ~= self.animationState then
		self:setVisible(v58_, true)
		self.joystickXHudElement:setTouchIsActive(v58_)
		self.joystickYHudElement:setTouchIsActive(v58_)
	end
end

-- Local values: canControl, posX, _, _, posY
function PlayerControlPadDisplay:update(dt)
	PlayerControlPadDisplay:superClass().update(self, dt)
	self.joystickElement:setUVs(self.uvs)
	local v61_, _ = self.joystickXHudElement:getPosition()
	local _, v62_ = self.joystickYHudElement:getPosition()
	self.joystickElement:setPosition(v61_, v62_)
	if self.player ~= nil then
		if self.joystickXHudElement ~= nil and self.joystickYHudElement ~= nil then
			self.joystickXHudElement:update(dt)
			self.joystickYHudElement:update(dt)
		end
		self.player:onInputMoveSide(nil, self.joystickPosX, nil, nil, false)
		self.player:onInputMoveForward(nil, -self.joystickPosY, nil, nil, false)
	end
end

function PlayerControlPadDisplay:onAnimateVisibilityFinished(isVisible)
	PlayerControlPadDisplay:superClass().onAnimateVisibilityFinished(self, isVisible)
	if isVisible then
		self.joystickXHudElement:resetSlider()
		self.joystickYHudElement:resetSlider()
	end
end

function PlayerControlPadDisplay:getIsPlayerMoveActive()
	if g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD then
		return false
	elseif Platform.hasTouchSliders then
		return self.player ~= nil
	else
		return false
	end
end

-- Local values: currentVisibility, posX, posY
function PlayerControlPadDisplay:setScale(uiScale)
	PlayerControlPadDisplay:superClass().setScale(self, uiScale, uiScale)
	local v68_ = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local v69_, v70_ = PlayerControlPadDisplay.getBackgroundPosition(uiScale, self:getWidth())
	self:setPosition(v69_, v70_)
	self:storeOriginalPosition()
	self:setVisible(v68_, false)
	self:updateVisibilityState()
	self:updateSliderTranslations(uiScale)
end

-- Local values: offX, offY
function PlayerControlPadDisplay.getBackgroundPosition(scale, width)
	local v72_ = getNormalizedScreenValues
	local v73_ = PlayerControlPadDisplay.POSITION.BACKGROUND
	local v74_, v75_ = v72_(unpack(v73_))
	return v74_ * scale, v75_ * scale
end
function PlayerControlPadDisplay.createBackground()
	local v76_ = getNormalizedScreenValues
	local v77_ = PlayerControlPadDisplay.SIZE.BACKGROUND
	local v78_, v79_ = v76_(unpack(v77_))
	local v80_, v81_ = PlayerControlPadDisplay.getBackgroundPosition(1, v78_)
	return Overlay.new(nil, v80_, v81_, v78_, v79_)
end
PlayerControlPadDisplay.SIZE = {
	["BACKGROUND"] = { 264, 264 },
	["JOYSTICK"] = { 174, 174 }
}
PlayerControlPadDisplay.POSITION = {
	["BACKGROUND"] = { 100, 50 },
	["HIDE_OFFSET"] = { 0, -250 }
}
PlayerControlPadDisplay.UV = {
	["BACKGROUND"] = {
		624,
		432,
		264,
		264
	},
	["JOYSTICK"] = {
		194,
		670,
		174,
		174
	},
	["JOYSTICK_DISABLED"] = {
		370,
		670,
		174,
		174
	}
}
PlayerControlPadDisplay.COLOR = {
	["BACKGROUND"] = {
		1,
		1,
		1,
		0.5
	}
}
if v1_ ~= nil then
	local v82_ = PlayerControlPadDisplay.new(v1_.hud, v1_.hudAtlasPath)
	v82_:setScale(v1_.uiScale)
	v82_:setPlayer(v1_.player)
	for v83_, v84_ in ipairs(g_currentMission.hud.displayComponents) do
		if v84_ == g_currentMission.hud.playerControlPadDisplay then
			g_currentMission.hud.displayComponents[v83_] = v82_
			break
		end
	end
	g_currentMission.hud.playerControlPadDisplay = v82_
	Logging.info("Reloaded")
end
