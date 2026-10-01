local data = nil
if SteeringSliderDisplay ~= nil then
	local old = g_currentMission.hud.steeringSliderDisplay
	data = {}
	data.vehicle = old.vehicle
	data.player = old.player
	data.hud = old.hud
	data.uiScale = old.uiScale
	data.hudAtlasPath = old.hudAtlasPath
	data.sliderPosition = old.sliderPosition
	data.restPosition = old.restPosition
	data.resetTime = old.resetTime
	data.lastGyroscopeSteeringState = old.lastGyroscopeSteeringState
	old:delete()
end
SteeringSliderDisplay = {}
local SteeringSliderDisplay_mt = Class(SteeringSliderDisplay, HUDDisplayElement)
function SteeringSliderDisplay.new(hud, hudAtlasPath)
	local backgroundOverlay = SteeringSliderDisplay.createBackground()
	local self = SteeringSliderDisplay:superClass().new(backgroundOverlay, nil, SteeringSliderDisplay_mt)
	self.hud = hud
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.vehicle = nil
	self.isRideable = false
	self.sliderPosition = 0
	self.restPosition = 0.5
	self.resetTime = 2500
	self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	self.lastGyroscopeSteeringState = false
	self:createComponents()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.STEERING_BACK_SPEED], self.onSteeringBackSpeedSettingChanged, self)
	return self
end
function SteeringSliderDisplay:delete()
	g_messageCenter:unsubscribeAll(self)
	SteeringSliderDisplay:superClass().delete(self)
end
function SteeringSliderDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
	if vehicle ~= nil then
		self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
		self.sliderHudElement:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER))
	end
end
function SteeringSliderDisplay:setPlayer(player)
	self.player = player
	self:updateVisibilityState()
end
function SteeringSliderDisplay:createComponents()
	local bgSizeX, bgSizeY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.BACKGROUND))
	local bgPosX, bgPosY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.POSITION.BACKGROUND))
	local backgroundOverlay = Overlay.new(self.hudAtlasPath, bgPosX, bgPosY, bgSizeX, bgSizeY)
	backgroundOverlay:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.BACKGROUND))
	self.backgroundHudElement = HUDElement.new(backgroundOverlay)
	self:addChild(self.backgroundHudElement)
	self.uvs = GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER)
	self.uvsDisabled = GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER_DISABLED)
	local slSizeX, slSizeY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.SLIDER_SIZE))
	local sliderPosY = bgPosY + (bgSizeY - slSizeY) * 0.5
	local sliderOverlay = Overlay.new(self.hudAtlasPath, bgPosX, sliderPosY, slSizeX, slSizeY)
	sliderOverlay:setUVs(self.uvs)
	self:updateSliderTranslations(1)
	self.sliderHudElement = HUDSliderElement.new(sliderOverlay, backgroundOverlay, { 0.12, 0.05 }, 1, 10, 1, self.sliderMin, self.sliderCenter, self.sliderMax, nil)
	self.sliderHudElement:setCallback(self.onSliderPositionChanged, self)
	self.sliderHudElement:setMoveToCenterSpeedFactor(g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10)
	local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.STEERING))
	local iconPosX = bgPosX + (slSizeX - iconSizeX) * 0.5
	local iconPosY = sliderPosY + (slSizeY - iconSizeY) * 0.5
	local iconOverlay = Overlay.new(self.hudAtlasPath, iconPosX, iconPosY, iconSizeX, iconSizeY)
	iconOverlay:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.STEERING))
	self.sliderHudElement:addChild(HUDElement.new(iconOverlay))
	self.backgroundHudElement:addChild(self.sliderHudElement)
	self.sliderHudElement:setAxisPosition(self.sliderCenter)
end
function SteeringSliderDisplay:updateSliderTranslations(uiScale)
	local width = self.backgroundHudElement:getWidth()
	local slSizeX, _ = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.SLIDER_SIZE))
	slSizeX = slSizeX * self.uiScale
	self.sliderMin = 0
	self.sliderMax = width - slSizeX
	self.sliderCenter = MathUtil.lerp(self.sliderMin, self.sliderMax, 0.5)
end
function SteeringSliderDisplay:setVisible(isVisible, animate)
	if not isVisible or g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD then
		SteeringSliderDisplay:superClass().setVisible(self, isVisible, animate)
	end
end
function SteeringSliderDisplay:onSliderPositionChanged(position)
	self.sliderPosition = math.clamp(position, 0, 1)
end
function SteeringSliderDisplay:getSteeringValue()
	local norm = self.sliderPosition * 2 - 1
	if norm == 0 then
		return norm
	else
		local sign = norm / math.abs(norm)
		return norm * norm * sign
	end
end
function SteeringSliderDisplay:getIsSliderActive()
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		return false
	end
	if not Platform.hasTouchSliders then
		return false
	end
	if self.lastGyroscopeSteeringState then
		return false
	end
	if self.vehicle ~= nil and self.vehicle:getIsAIActive() then
		return false
	end
	if self.player ~= nil then
		return false
	else
		return true
	end
end
function SteeringSliderDisplay:onInputHelpModeChange(inputHelpMode)
	self.lastInputHelpMode = inputHelpMode
	self:updateVisibilityState()
end
function SteeringSliderDisplay:onAIVehicleStateChanged(state, vehicle)
	self:updateVisibilityState()
end
function SteeringSliderDisplay:onGyroscopeSteeringChanged(state)
	self.lastGyroscopeSteeringState = state
	self:updateVisibilityState()
end
function SteeringSliderDisplay:updateVisibilityState()
	local animationState = self:getIsSliderActive()
	if animationState ~= self.animationState then
		self:setVisible(animationState, true)
		self.sliderHudElement:setTouchIsActive(animationState)
	end
end
function SteeringSliderDisplay:onSteeringBackSpeedSettingChanged()
	if self.sliderHudElement ~= nil then
		self.sliderHudElement:setMoveToCenterSpeedFactor(g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10)
	end
end
function SteeringSliderDisplay:update(dt)
	SteeringSliderDisplay:superClass().update(self, dt)
	if not g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) and self.vehicle ~= nil then
		if self.isRideable then
			self.vehicle:setRideableSteer(self:getSteeringValue())
		elseif self.vehicle.setSteeringInput ~= nil then
			self.vehicle:setSteeringInput(self:getSteeringValue(), true, InputDevice.CATEGORY.WHEEL)
		end
	end
	if self.sliderHudElement ~= nil then
		self.sliderHudElement:update(dt)
	end
end
function SteeringSliderDisplay:setScale(uiScale)
	SteeringSliderDisplay:superClass().setScale(self, uiScale, uiScale)
	local currentVisibility = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local posX, posY = SteeringSliderDisplay.getBackgroundPosition(uiScale, self:getWidth())
	self:setPosition(posX, posY)
	self:updateSliderTranslations(uiScale)
	self.sliderHudElement:setRange(self.sliderMin, self.sliderCenter, self.sliderMax, nil)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
end
function SteeringSliderDisplay.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.POSITION.BACKGROUND))
	return offX * scale, offY * scale
end
function SteeringSliderDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.BACKGROUND))
	local posX, posY = SteeringSliderDisplay.getBackgroundPosition(1, width)
	local overlay = Overlay.new(nil, posX, posY, width, height)
	return overlay
end
SteeringSliderDisplay.SIZE = { BACKGROUND = { 480, 144 }, SLIDER_SIZE = { 106, 106 }, STEERING = { 90, 90 } }
SteeringSliderDisplay.POSITION = { BACKGROUND = { 50, 31 }, HIDE_OFFSET = { 0, -250 } }
SteeringSliderDisplay.UV = { BACKGROUND = { 97, 288, 480, 144 }, SLIDER = { 132, 908, 106, 106 }, SLIDER_DISABLED = { 344, 908, 106, 106 }, STEERING = { 384, 48, 96, 96 } }
SteeringSliderDisplay.COLOR = { BACKGROUND = { 1, 1, 1, 0.5 } }
if data ~= nil then
	local steeringSliderDisplay = SteeringSliderDisplay.new(data.hud, data.hudAtlasPath)
	steeringSliderDisplay:setScale(data.uiScale)
	steeringSliderDisplay:setVehicle(data.vehicle)
	steeringSliderDisplay:setPlayer(data.player)
	steeringSliderDisplay.lastGyroscopeSteeringState = data.lastGyroscopeSteeringState
	for k, elem in ipairs(g_currentMission.hud.displayComponents) do
		if elem == g_currentMission.hud.steeringSliderDisplay then
			g_currentMission.hud.displayComponents[k] = steeringSliderDisplay
			break
		end
	end
	g_currentMission.hud.steeringSliderDisplay = steeringSliderDisplay
	Logging.info("Reloaded")
end
