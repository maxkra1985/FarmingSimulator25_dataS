-- Local values: data, old, SpeedSliderDisplay_mt, speedSliderDisplay, k, elem
local v1_
if SpeedSliderDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.speedSliderDisplay
	v1_ = {
		["vehicle"] = v2_.vehicle,
		["player"] = v2_.player,
		["hud"] = v2_.hud,
		["uiScale"] = v2_.uiScale,
		["hudAtlasPath"] = v2_.hudAtlasPath,
		["controlHudAtlasPath"] = v2_.controlHudAtlasPath,
		["sliderState"] = v2_.sliderState
	}
	v2_:delete()
end
SpeedSliderDisplay = {}
local data = Class(SpeedSliderDisplay, HUDDisplayElement)
SpeedSliderDisplay.GAMEPAD_SWITCH_TIME = 500
SpeedSliderDisplay.SPEED_NEED_OFFSET = 0.20943951023931956
SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS = {
	0,
	0.2,
	0.4,
	0.6,
	0.8,
	1
}

-- Upvalues: SpeedSliderDisplay_mt
-- Local values: backgroundOverlay, self
function SpeedSliderDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
	-- upvalues: (copy) data
	local v7_ = SpeedSliderDisplay.createBackground()
	local v8_ = SpeedSliderDisplay:superClass().new(v7_, nil, data)
	v8_.hud = hud
	v8_.uiScale = 1
	v8_.hudAtlasPath = hudAtlasPath
	v8_.controlHudAtlasPath = controlHudAtlasPath
	v8_.vehicle = nil
	v8_.player = nil
	v8_.isRideable = false
	v8_.sliderPosition = 0
	v8_.restPosition = 0.25
	v8_.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	v8_.sliderState = nil
	v8_:createComponents()
	g_messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, v8_.onGuiOpen, v8_)
	g_messageCenter:subscribe(MessageType.GUI_DIALOG_OPENED, v8_.onDialogOpened, v8_)
	g_messageCenter:subscribe(MessageType.GUIDED_TOUR_DIALOG, v8_.onTourDialog, v8_)
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, v8_.updateInsets, v8_)
	return v8_
end

function SpeedSliderDisplay:delete()
	g_messageCenter:unsubscribeAll(self)
	SpeedSliderDisplay:superClass().delete(self)
end

-- Local values: baseX, baseY, bgSizeX, bgSizeY, backgroundOverlay, _, negativeBarSizeY, _, textSize, slOffX, slOffY, slSizeX, slSizeY, sliderOverlay, pljbgPosX, pljbgPosY, playerJumpIconSizeX, playerJumpIconSizeY, gpbgPosX, gpbgPosY, gpbgSizeX, gpbgSizeY, gamepadBackgroundOverlay, _, yOffset
function SpeedSliderDisplay:createComponents()
	local v11_, v12_ = self:getPosition()
	local v13_ = getNormalizedScreenValues
	local v14_ = SpeedSliderDisplay.SIZE.BACKGROUND
	local v15_, v16_ = v13_(unpack(v14_))
	local v17_ = Overlay.new(self.hudAtlasPath, v11_, v12_, v15_, v16_)
	v17_:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND))
	self.sliderBackgroundElement = HUDElement.new(v17_)
	self:addChild(self.sliderBackgroundElement)
	self.positiveBarHudElement = self:createBar(SpeedSliderDisplay.POSITION.POSITIVE_BAR, SpeedSliderDisplay.SIZE.POSITIVE_BAR, SpeedSliderDisplay.COLOR.POSITIVE_BAR)
	self.sliderBackgroundElement:addChild(self.positiveBarHudElement)
	self.negativeBarHudElement = self:createBar(SpeedSliderDisplay.POSITION.NEGATIVE_BAR, SpeedSliderDisplay.SIZE.NEGATIVE_BAR, SpeedSliderDisplay.COLOR.NEGATIVE_BAR)
	self.sliderBackgroundElement:addChild(self.negativeBarHudElement)
	local v18_ = getNormalizedScreenValues
	local v19_ = SpeedSliderDisplay.POSITION.NEGATIVE_BAR
	local v20_, v21_ = v18_(unpack(v19_))
	self.negativeBarPosX = v20_
	self.negativeBarPosY = v21_
	local v22_ = getNormalizedScreenValues
	local v23_ = SpeedSliderDisplay.SIZE.NEGATIVE_BAR
	local _, v24_ = v22_(unpack(v23_))
	self.negativeBarSizeY = v24_
	local v25_ = getNormalizedScreenValues
	local v26_ = SpeedSliderDisplay.POSITION.SPEED_TEXT
	local v27_, v28_ = v25_(unpack(v26_))
	self.textPosX = v27_
	self.textPosY = v28_
	local v29_ = getNormalizedScreenValues
	local v30_ = SpeedSliderDisplay.POSITION.SPEED_TEXT_GAMEPAD
	local v31_, v32_ = v29_(unpack(v30_))
	self.textPosGamepadX = v31_
	self.textPosGamepadY = v32_
	local v33_ = getNormalizedScreenValues
	local v34_ = SpeedSliderDisplay.POSITION.SPEED_TEXT_GAMEPAD_OFFSET_KMH
	local v35_, _ = v33_(unpack(v34_))
	self.textOffsetXkmh = v35_
	local v36_ = getNormalizedScreenValues
	local v37_ = SpeedSliderDisplay.SIZE.SPEED_TEXT
	local _, v38_ = v36_(unpack(v37_))
	self.textSize = v38_
	self.sliderUVs = GuiUtils.getUVs(SpeedSliderDisplay.UV.SLIDER)
	self.sliderUVsDisabled = GuiUtils.getUVs(SpeedSliderDisplay.UV.SLIDER_DISABLED)
	local v39_ = getNormalizedScreenValues
	local v40_ = SpeedSliderDisplay.POSITION.SLIDER_OFFSET
	local v41_, v42_ = v39_(unpack(v40_))
	local v43_ = getNormalizedScreenValues
	local v44_ = SpeedSliderDisplay.SIZE.SLIDER_SIZE
	local v45_, v46_ = v43_(unpack(v44_))
	local v47_ = Overlay.new(self.hudAtlasPath, v11_ + v41_, v12_ + v42_, v45_, v46_)
	v47_:setUVs(self.sliderUVs)
	self:updateSliderTranslations(1)
	self.sliderHudElement = HUDSliderElement.new(v47_, v17_, 1.5, 0, 100, 2, self.sliderMin, self.sliderCenter, self.sliderMax, self.sliderMax)
	self.sliderHudElement:setCallback(self.onSliderPositionChanged, self)
	self.sliderBackgroundElement:addChild(self.sliderHudElement)
	local v48_ = getNormalizedScreenValues
	local v49_ = SpeedSliderDisplay.POSITION.JUMP_BUTTON
	local v50_, v51_ = v48_(unpack(v49_))
	local v52_ = getNormalizedScreenValues
	local v53_ = SpeedSliderDisplay.SIZE.PLAYER_JUMP_ICON
	local v54_, v55_ = v52_(unpack(v53_))
	self.playerJumpButtonElement = HUDButtonElement.new(self.hud, v11_ + v50_, v12_ + v51_)
	self.playerJumpButtonElement:setIcon(self.controlHudAtlasPath, v54_, v55_, GuiUtils.getUVs(SpeedSliderDisplay.UV.JUMP_PLAYER))
	self.playerJumpButtonElement:setAction(InputAction.JUMP)
	self.playerJumpButtonElement:addTouchHandler(self.onJumpEventCallback, self)
	self:addChild(self.playerJumpButtonElement)
	self.horseJumpButtonElement = HUDButtonElement.new(self.hud, v11_ + v50_, v12_ + v51_)
	self.horseJumpButtonElement:setIcon(self.controlHudAtlasPath, v54_, v55_, GuiUtils.getUVs(SpeedSliderDisplay.UV.JUMP_HORSE))
	self.horseJumpButtonElement:setAction(InputAction.JUMP)
	self.horseJumpButtonElement:addTouchHandler(self.onJumpEventCallback, self)
	self:addChild(self.horseJumpButtonElement)
	local v56_ = getNormalizedScreenValues
	local v57_ = SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND
	local v58_, v59_ = v56_(unpack(v57_))
	local v60_ = getNormalizedScreenValues
	local v61_ = SpeedSliderDisplay.SIZE.GAMEPAD_BACKGROUND
	local v62_, v63_ = v60_(unpack(v61_))
	local v64_ = Overlay.new(self.hudAtlasPath, v11_ + v58_, v12_ + v59_, v62_, v63_)
	v64_:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.GAMEPAD_BACKGROUND))
	self.gamepadBackgroundHudElement = HUDElement.new(v64_)
	self:addChild(self.gamepadBackgroundHudElement)
	self.sliderHudElement:setAxisPosition(self.sliderCenter)
	self.positionVisible = { v11_, v12_ }
	local v65_ = getNormalizedScreenValues
	local v66_ = SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND
	local _, v67_ = v65_(unpack(v66_))
	self.positionInvisible = { v11_, v12_ - v67_ }
end

-- Local values: height, slOffX, slOffY, _, slAreaY, _, slCenterY
function SpeedSliderDisplay:updateSliderTranslations(uiScale)
	local v70_ = self.sliderBackgroundElement:getHeight()
	local v71_ = getNormalizedScreenValues
	local v72_ = SpeedSliderDisplay.POSITION.SLIDER_OFFSET
	local v73_, v74_ = v71_(unpack(v72_))
	self.sliderPosX = v73_ * uiScale
	self.sliderPosY = v74_ * uiScale
	self.backgroundSizeY = v70_ - v74_ * 2
	local v75_ = getNormalizedScreenValues
	local v76_ = SpeedSliderDisplay.SIZE.SLIDER_AREA
	local _, v77_ = v75_(unpack(v76_))
	local v78_ = v77_ * uiScale
	self.sliderAreaY = v78_
	local v79_ = getNormalizedScreenValues
	local v80_ = SpeedSliderDisplay.POSITION.SLIDER_CENTER
	local _, v81_ = v79_(unpack(v80_))
	self.restPosition = v81_ * uiScale / v78_
	self.sliderMin = self.sliderPosY
	self.sliderMax = self.sliderMin + self.sliderAreaY
	self.sliderCenter = self.sliderMin + self.sliderAreaY * self.restPosition
end

function SpeedSliderDisplay:setSliderState(state)
	if self.sliderState ~= state then
		if state then
			self:showSlider()
			return
		end
		self:hideSlider()
	end
end

-- Local values: startX, startY, sequence
function SpeedSliderDisplay:hideSlider()
	local v85_, v86_ = self:getPosition()
	local v87_ = TweenSequence.new(self)
	v87_:insertTween(MultiValueTween.new(self.setPosition, { v85_, v86_ }, self.positionInvisible, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
	v87_:start()
	self.animation = v87_
	self.sliderState = false
	self.sliderHudElement:setTouchIsActive(false)
	self:updateElementsVisibility()
end

-- Local values: startX, startY, sequence
function SpeedSliderDisplay:showSlider()
	local v89_, v90_ = self:getPosition()
	local v91_ = TweenSequence.new(self)
	v91_:insertTween(MultiValueTween.new(self.setPosition, { v89_, v90_ }, self.positionVisible, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
	v91_:addCallback(self.onSliderVisibilityChangeFinished, true)
	v91_:start()
	self.animation = v91_
	self.sliderState = true
	self.sliderHudElement:resetSlider()
	self.sliderHudElement:setTouchIsActive(true)
end

function SpeedSliderDisplay:updateElementsVisibility()
	local v93_ = self.gamepadBackgroundHudElement
	local v94_ = not self.sliderState
	if v94_ then
		if self.player == nil then
			local v95_
			if self.vehicle == nil then
				v95_ = false
			else
				v95_ = self.isRideable
			end
			v94_ = not v95_
		else
			v94_ = false
		end
	end
	v93_:setVisible(v94_)
	self.sliderBackgroundElement:setVisible(self.sliderState)
end

function SpeedSliderDisplay:onSliderVisibilityChangeFinished(visibility)
	if visibility then
		self:updateElementsVisibility()
	end
end

-- Local values: i, sizeX, sizeY, sizeX, sizeY
function SpeedSliderDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
	if vehicle ~= nil then
		self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
		if self.player ~= nil then
			self:setPlayer(nil)
		end
		self.sliderHudElement:resetSlider()
		self.sliderHudElement:clearSnapPositions()
		if self.isRideable then
			for v100_ = 1, #SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS do
				self.sliderHudElement:addSnapPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[v100_])
			end
		end
	end
	if self.isRideable then
		self.sliderBackgroundElement:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND_HORSE))
		local v101_ = getNormalizedScreenValues
		local v102_ = SpeedSliderDisplay.SIZE.BACKGROUND_HORSE
		local v103_, v104_ = v101_(unpack(v102_))
		self.sliderBackgroundElement:setDimension(v103_ * self.uiScale, v104_ * self.uiScale)
	else
		self.sliderBackgroundElement:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND))
		local v105_ = getNormalizedScreenValues
		local v106_ = SpeedSliderDisplay.SIZE.BACKGROUND
		local v107_, v108_ = v105_(unpack(v106_))
		self.sliderBackgroundElement:setDimension(v107_ * self.uiScale, v108_ * self.uiScale)
	end
	self:updateElementsVisibility()
end

function SpeedSliderDisplay:setPlayer(player)
	self.player = player
	if player ~= nil and self.vehicle ~= nil then
		self:setVehicle(nil)
	end
	self:updateVisibilityState()
	self:updateElementsVisibility()
end

-- Local values: isPlayerJumpVisible, isGuiVisible
function SpeedSliderDisplay:updateButton()
	local v112_
	if self.player == nil then
		v112_ = false
	else
		v112_ = not self.sliderState
	end
	self.playerJumpButtonElement:setVisible(v112_)
	g_gui:getIsGuiVisible()
end

-- Local values: baseX, baseY, posX, posY, sizeX, sizeY, barOverlay
function SpeedSliderDisplay:createBar(position, size, color)
	local v117_, v118_ = self:getPosition()
	local v119_, v120_ = getNormalizedScreenValues(unpack(position))
	local v121_, v122_ = getNormalizedScreenValues(unpack(size))
	local v123_ = g_overlayManager:createOverlay(g_plainColorSliceId, v117_ + v119_, v118_ + v120_, v121_, v122_)
	v123_:setColor(unpack(color))
	return HUDElement.new(v123_)
end

-- Local values: selfX, selfY, acc, brake, x, y, gait
function SpeedSliderDisplay:onSliderPositionChanged(position)
	self.sliderPosition = math.clamp(position, 0, 1)
	local v126_, v127_ = self:getPosition()
	local v128_, v129_ = self:getAccelerateAndBrakeValue()
	self.positiveBarHudElement:setScale(self.uiScale, v128_ * self.uiScale)
	local v130_ = self.positiveBarHudElement
	local v131_ = self.cruiseControlIsActive and SpeedSliderDisplay.COLOR.CRUISE_CONTROL or SpeedSliderDisplay.COLOR.POSITIVE_BAR
	v130_:setColor(unpack(v131_))
	local v132_ = v126_ + self.negativeBarPosX * self.uiScale
	local v133_ = v127_ + (self.negativeBarPosY + self.negativeBarSizeY * (1 - v129_)) * self.uiScale
	self.negativeBarHudElement:setPosition(v132_, v133_)
	self.negativeBarHudElement:setScale(self.uiScale, v129_ * self.uiScale)
	if self.vehicle ~= nil and self.isRideable then
		for v134_ = 1, #SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS do
			local v135_ = position - SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[v134_]
			if math.abs(v135_) < 0.01 then
				self.vehicle:setCurrentGait(v134_)
				self.lastGait = v134_
				self.lastGaitTime = g_time
				return
			end
		end
	end
end

function SpeedSliderDisplay:getAccelerateAndBrakeValue()
	local v137_ = (self.sliderPosition - self.restPosition) / (1 - self.restPosition)
	local v138_ = math.clamp(v137_, 0, 1)
	local v139_ = self.sliderPosition / self.restPosition
	return v138_, 1 - math.clamp(v139_, 0, 1)
end

function SpeedSliderDisplay:onJumpEventCallback()
	if not g_sleepManager:getIsSleeping() then
		if self.vehicle ~= nil and (self.isRideable and self.vehicle:getIsRideableJumpAllowed()) then
			self.vehicle:jump()
		end
		if self.player ~= nil then
			self.player:onInputJump(nil, 1)
		end
	end
end

-- Local values: acceleration, brake, direction, currentGait
function SpeedSliderDisplay:update(dt)
	SpeedSliderDisplay:superClass().update(self, dt)
	self:updateButton()
	if self.sliderHudElement ~= nil then
		self.sliderHudElement:update(dt)
	end
	if self.vehicle ~= nil then
		if self.vehicle.setAccelerationPedalInput ~= nil then
			local v143_, v144_ = self:getAccelerateAndBrakeValue()
			local v145_ = v143_ > 0 and 1 or (v144_ > 0 and -1 or 0)
			local v146_ = self.vehicle
			local v147_ = v143_ + v144_
			v146_:setTargetSpeedAndDirection(math.abs(v147_), v145_)
		end
		if self.isRideable then
			local v148_ = self.vehicle:getCurrentGait()
			if v148_ ~= self.lastGait and (self.lastGaitTime < g_time - 250 and SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[v148_] ~= nil) then
				self.sliderHudElement:setAxisPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[v148_])
				self.lastGait = v148_
			end
		end
	end
end

function SpeedSliderDisplay:getIsSliderActive()
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		return false
	elseif Platform.hasTouchSliders then
		if self.vehicle == nil or not self.vehicle:getIsAIActive() then
			return self.player == nil
		else
			return false
		end
	else
		return false
	end
end

function SpeedSliderDisplay:onInputHelpModeChange(inputHelpMode)
	self.lastInputHelpMode = inputHelpMode
	if inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		self.sliderHudElement:setAxisPosition(self.sliderPosY + self.sliderAreaY * self.restPosition)
	end
	self:updateVisibilityState()
end

function SpeedSliderDisplay:onAIVehicleStateChanged(state, vehicle)
	if vehicle == self.vehicle then
		self:updateVisibilityState()
	end
end

-- Local values: sliderState
function SpeedSliderDisplay:updateVisibilityState()
	local v155_ = self:getIsSliderActive()
	if v155_ ~= self.sliderState then
		self:setSliderState(v155_, true)
	end
end

-- Local values: speed, baseX, baseY, width, posX, posY, text, useLongSpeedStr
function SpeedSliderDisplay:draw()
	SpeedSliderDisplay:superClass().draw(self)
	if self.vehicle ~= nil and not self.isRideable then
		local v157_ = MathUtil.round(g_i18n:getSpeed(self.vehicle:getLastSpeed()))
		local v158_, v159_ = self:getPosition()
		local v160_ = self:getWidth()
		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		local v161_, v162_
		if self.vehicle:getIsAIActive() or (self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and true or not Platform.hasTouchSliders) then
			v158_ = self.gamepadBackgroundHudElement:getPosition()
			v160_ = self.gamepadBackgroundHudElement:getWidth()
			v161_ = v159_ + self.textPosGamepadY * self.uiScale
			v162_ = string.format("%02d %s", v157_, g_i18n:getSpeedMeasuringUnit())
		else
			v161_ = v159_ + self.textPosY * self.uiScale
			v162_ = string.format("%02d", v157_)
		end
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(v158_ + v160_ * 0.5, v161_, self.textSize * self.uiScale, v162_)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
end

-- Local values: inputMode
function SpeedSliderDisplay:getIsVehicleThrottleActive()
	if Platform.hasTouchSliders then
		return g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_GAMEPAD
	else
		return false
	end
end

function SpeedSliderDisplay:onDialogOpened(guiName, overlappingDialog)
	if not overlappingDialog then
		self.sliderHudElement:resetSlider()
	end
end

function SpeedSliderDisplay:onGuiOpen()
	self.sliderHudElement:resetSlider()
end

function SpeedSliderDisplay:onTourDialog()
	self.sliderHudElement:resetSlider()
end

-- Local values: currentVisibility, posX, posY, _, yOffset
function SpeedSliderDisplay:setScale(uiScale)
	SpeedSliderDisplay:superClass().setScale(self, uiScale, uiScale)
	local v169_ = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local v170_, v171_ = SpeedSliderDisplay.getBackgroundPosition(uiScale, self:getWidth())
	self:setPosition(v170_, v171_)
	self.positionVisible = { v170_, v171_ }
	local v172_ = getNormalizedScreenValues
	local v173_ = SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND
	local _, v174_ = v172_(unpack(v173_))
	self.positionInvisible = { v170_, v171_ - v174_ * uiScale }
	self:updateSliderTranslations(uiScale)
	self.sliderHudElement:setRange(self.sliderMin, self.sliderCenter, self.sliderMax, self.sliderMax)
	self:storeOriginalPosition()
	self:setVisible(v169_, false)
	if not self:getIsSliderActive() then
		self:setPosition(self.positionInvisible[1], self.positionInvisible[2])
	end
end

function SpeedSliderDisplay:updateInsets()
	self:setScale(self.uiScale)
end

-- Local values: offX, offY, posX, posY, _, rightInset, _, _, maxPosX
function SpeedSliderDisplay.getBackgroundPosition(scale, width)
	local v178_ = getNormalizedScreenValues
	local v179_ = SpeedSliderDisplay.POSITION.BACKGROUND
	local v180_, v181_ = v178_(unpack(v179_))
	local v182_ = 1 + v180_ * scale
	local v183_ = v181_ * scale
	local _, v184_, _, _ = getSafeFrameInsets()
	local v185_ = 1 - v184_ - width
	return math.min(v182_, v185_), v183_
end
function SpeedSliderDisplay.createBackground()
	local v186_ = getNormalizedScreenValues
	local v187_ = SpeedSliderDisplay.SIZE.BACKGROUND
	local v188_, v189_ = v186_(unpack(v187_))
	local v190_, v191_ = SpeedSliderDisplay.getBackgroundPosition(1, v188_)
	return Overlay.new(nil, v190_, v191_, v188_, v189_)
end
SpeedSliderDisplay.SIZE = {
	["BACKGROUND"] = { 91, 635 },
	["BACKGROUND_HORSE"] = { 91, 549 },
	["POSITIVE_BAR"] = { 67, 400 },
	["NEGATIVE_BAR"] = { 67, 100 },
	["PLAYER_JUMP_ICON"] = { 90, 90 },
	["JUMP_BUTTON"] = { 106, 106 },
	["JUMP_BUTTON_ICON"] = { 90, 90 },
	["SLIDER_SIZE"] = { 192, 124 },
	["SLIDER_AREA"] = { 192, 500 },
	["GAMEPAD_BACKGROUND"] = { 264, 84 },
	["SPEED_TEXT"] = { 0, 55 },
	["GAMEPAD_OFFSET"] = { 0, -557 }
}
SpeedSliderDisplay.POSITION = {
	["BACKGROUND"] = { -160, 50 },
	["JUMP_BUTTON"] = { -7, 558 },
	["SPEED_TEXT"] = { 45, 574 },
	["SPEED_TEXT_GAMEPAD"] = { 84, 578 },
	["SPEED_TEXT_GAMEPAD_OFFSET_KMH"] = { 15, 0 },
	["SNAP1"] = { 8, 224 },
	["SNAP2"] = { 8, 324 },
	["SNAP3"] = { 8, 424 },
	["NEGATIVE_BAR"] = { 12, 24 },
	["POSITIVE_BAR"] = { 12, 124 },
	["SLIDER_OFFSET"] = { -49, -41 },
	["SLIDER_CENTER"] = { 0, 100 },
	["GAMEPAD_BACKGROUND"] = { -143, 557 }
}
SpeedSliderDisplay.UV = {
	["BACKGROUND"] = {
		5,
		293,
		91,
		635
	},
	["BACKGROUND_HORSE"] = {
		5,
		379,
		91,
		549
	},
	["SLIDER"] = {
		97,
		432,
		192,
		142
	},
	["SLIDER_DISABLED"] = {
		779,
		0,
		192,
		142
	},
	["JUMP_HORSE"] = {
		96,
		192,
		96,
		96
	},
	["JUMP_PLAYER"] = {
		768,
		0,
		96,
		96
	},
	["GAMEPAD_BACKGROUND"] = {
		288,
		528,
		264,
		84
	}
}
SpeedSliderDisplay.COLOR = {
	["BACKGROUND"] = {
		1,
		1,
		1,
		0.5
	},
	["POSITIVE_BAR"] = {
		0,
		0.486274,
		0.8549019,
		0.5
	},
	["NEGATIVE_BAR"] = {
		1,
		0.1,
		0.1,
		0.5
	},
	["CRUISE_CONTROL"] = {
		0.0227,
		0.5346,
		0.8519,
		0.9
	}
}
if v1_ ~= nil then
	local v192_ = SpeedSliderDisplay.new(v1_.hud, v1_.hudAtlasPath, v1_.controlHudAtlasPath)
	v192_:setScale(v1_.uiScale)
	v192_:setVehicle(v1_.vehicle)
	v192_:setPlayer(v1_.player)
	for v193_, v194_ in ipairs(g_currentMission.hud.displayComponents) do
		if v194_ == g_currentMission.hud.speedSliderDisplay then
			g_currentMission.hud.displayComponents[v193_] = v192_
			break
		end
	end
	g_currentMission.hud.speedSliderDisplay = v192_
	Logging.info("Reloaded")
end
