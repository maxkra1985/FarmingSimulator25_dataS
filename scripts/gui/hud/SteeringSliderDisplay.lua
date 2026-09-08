-- Local values: data, old, SteeringSliderDisplay_mt, steeringSliderDisplay, k, elem
local v1_
if SteeringSliderDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.steeringSliderDisplay
	v1_ = {
		["vehicle"] = v2_.vehicle,
		["player"] = v2_.player,
		["hud"] = v2_.hud,
		["uiScale"] = v2_.uiScale,
		["hudAtlasPath"] = v2_.hudAtlasPath,
		["sliderPosition"] = v2_.sliderPosition,
		["restPosition"] = v2_.restPosition,
		["resetTime"] = v2_.resetTime,
		["lastGyroscopeSteeringState"] = v2_.lastGyroscopeSteeringState
	}
	v2_:delete()
end
SteeringSliderDisplay = {}
local data = Class(SteeringSliderDisplay, HUDDisplayElement)

-- Upvalues: SteeringSliderDisplay_mt
-- Local values: backgroundOverlay, self
function SteeringSliderDisplay.new(hud, hudAtlasPath)
	-- upvalues: (copy) data
	local v6_ = SteeringSliderDisplay.createBackground()
	local v7_ = SteeringSliderDisplay:superClass().new(v6_, nil, data)
	v7_.hud = hud
	v7_.uiScale = 1
	v7_.hudAtlasPath = hudAtlasPath
	v7_.vehicle = nil
	v7_.isRideable = false
	v7_.sliderPosition = 0
	v7_.restPosition = 0.5
	v7_.resetTime = 2500
	v7_.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	v7_.lastGyroscopeSteeringState = false
	v7_:createComponents()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.STEERING_BACK_SPEED], v7_.onSteeringBackSpeedSettingChanged, v7_)
	return v7_
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

-- Local values: bgSizeX, bgSizeY, bgPosX, bgPosY, backgroundOverlay, slSizeX, slSizeY, sliderPosX, sliderPosY, sliderOverlay, iconSizeX, iconSizeY, iconPosX, iconPosY, iconOverlay
function SteeringSliderDisplay:createComponents()
	local v14_ = getNormalizedScreenValues
	local v15_ = SteeringSliderDisplay.SIZE.BACKGROUND
	local v16_, v17_ = v14_(unpack(v15_))
	local v18_ = getNormalizedScreenValues
	local v19_ = SteeringSliderDisplay.POSITION.BACKGROUND
	local v20_, v21_ = v18_(unpack(v19_))
	local v22_ = Overlay.new(self.hudAtlasPath, v20_, v21_, v16_, v17_)
	v22_:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.BACKGROUND))
	self.backgroundHudElement = HUDElement.new(v22_)
	self:addChild(self.backgroundHudElement)
	self.uvs = GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER)
	self.uvsDisabled = GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER_DISABLED)
	local v23_ = getNormalizedScreenValues
	local v24_ = SteeringSliderDisplay.SIZE.SLIDER_SIZE
	local v25_, v26_ = v23_(unpack(v24_))
	local v27_ = v21_ + (v17_ - v26_) * 0.5
	local v28_ = Overlay.new(self.hudAtlasPath, v20_, v27_, v25_, v26_)
	v28_:setUVs(self.uvs)
	self:updateSliderTranslations(1)
	self.sliderHudElement = HUDSliderElement.new(v28_, v22_, { 0.12, 0.05 }, 1, 10, 1, self.sliderMin, self.sliderCenter, self.sliderMax, nil)
	self.sliderHudElement:setCallback(self.onSliderPositionChanged, self)
	self.sliderHudElement:setMoveToCenterSpeedFactor(g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10)
	local v29_ = getNormalizedScreenValues
	local v30_ = SteeringSliderDisplay.SIZE.STEERING
	local v31_, v32_ = v29_(unpack(v30_))
	local v33_ = v20_ + (v25_ - v31_) * 0.5
	local v34_ = v27_ + (v26_ - v32_) * 0.5
	local v35_ = Overlay.new(self.hudAtlasPath, v33_, v34_, v31_, v32_)
	v35_:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.STEERING))
	self.sliderHudElement:addChild(HUDElement.new(v35_))
	self.backgroundHudElement:addChild(self.sliderHudElement)
	self.sliderHudElement:setAxisPosition(self.sliderCenter)
end

-- Local values: width, slSizeX, _
function SteeringSliderDisplay:updateSliderTranslations(uiScale)
	local v37_ = self.backgroundHudElement:getWidth()
	local v38_ = getNormalizedScreenValues
	local v39_ = SteeringSliderDisplay.SIZE.SLIDER_SIZE
	local v40_, _ = v38_(unpack(v39_))
	local v41_ = v40_ * self.uiScale
	self.sliderMin = 0
	self.sliderMax = v37_ - v41_
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

-- Local values: norm, sign
function SteeringSliderDisplay:getSteeringValue()
	local v48_ = self.sliderPosition * 2 - 1
	if v48_ == 0 then
		return v48_
	end
	local v49_ = v48_ / math.abs(v48_)
	return v48_ * v48_ * v49_
end

function SteeringSliderDisplay:getIsSliderActive()
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		return false
	elseif Platform.hasTouchSliders then
		if self.lastGyroscopeSteeringState then
			return false
		elseif self.vehicle == nil or not self.vehicle:getIsAIActive() then
			return self.player == nil
		else
			return false
		end
	else
		return false
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

-- Local values: animationState
function SteeringSliderDisplay:updateVisibilityState()
	local v57_ = self:getIsSliderActive()
	if v57_ ~= self.animationState then
		self:setVisible(v57_, true)
		self.sliderHudElement:setTouchIsActive(v57_)
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

-- Local values: currentVisibility, posX, posY
function SteeringSliderDisplay:setScale(uiScale)
	SteeringSliderDisplay:superClass().setScale(self, uiScale, uiScale)
	local v63_ = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local v64_, v65_ = SteeringSliderDisplay.getBackgroundPosition(uiScale, self:getWidth())
	self:setPosition(v64_, v65_)
	self:updateSliderTranslations(uiScale)
	self.sliderHudElement:setRange(self.sliderMin, self.sliderCenter, self.sliderMax, nil)
	self:storeOriginalPosition()
	self:setVisible(v63_, false)
end

-- Local values: offX, offY
function SteeringSliderDisplay.getBackgroundPosition(scale, width)
	local v67_ = getNormalizedScreenValues
	local v68_ = SteeringSliderDisplay.POSITION.BACKGROUND
	local v69_, v70_ = v67_(unpack(v68_))
	return v69_ * scale, v70_ * scale
end
function SteeringSliderDisplay.createBackground()
	local v71_ = getNormalizedScreenValues
	local v72_ = SteeringSliderDisplay.SIZE.BACKGROUND
	local v73_, v74_ = v71_(unpack(v72_))
	local v75_, v76_ = SteeringSliderDisplay.getBackgroundPosition(1, v73_)
	return Overlay.new(nil, v75_, v76_, v73_, v74_)
end
SteeringSliderDisplay.SIZE = {
	["BACKGROUND"] = { 480, 144 },
	["SLIDER_SIZE"] = { 106, 106 },
	["STEERING"] = { 90, 90 }
}
SteeringSliderDisplay.POSITION = {
	["BACKGROUND"] = { 50, 31 },
	["HIDE_OFFSET"] = { 0, -250 }
}
SteeringSliderDisplay.UV = {
	["BACKGROUND"] = {
		97,
		288,
		480,
		144
	},
	["SLIDER"] = {
		132,
		908,
		106,
		106
	},
	["SLIDER_DISABLED"] = {
		344,
		908,
		106,
		106
	},
	["STEERING"] = {
		384,
		48,
		96,
		96
	}
}
SteeringSliderDisplay.COLOR = {
	["BACKGROUND"] = {
		1,
		1,
		1,
		0.5
	}
}
if v1_ ~= nil then
	local v77_ = SteeringSliderDisplay.new(v1_.hud, v1_.hudAtlasPath)
	v77_:setScale(v1_.uiScale)
	v77_:setVehicle(v1_.vehicle)
	v77_:setPlayer(v1_.player)
	v77_.lastGyroscopeSteeringState = v1_.lastGyroscopeSteeringState
	for v78_, v79_ in ipairs(g_currentMission.hud.displayComponents) do
		if v79_ == g_currentMission.hud.steeringSliderDisplay then
			g_currentMission.hud.displayComponents[v78_] = v77_
			break
		end
	end
	g_currentMission.hud.steeringSliderDisplay = v77_
	Logging.info("Reloaded")
end
