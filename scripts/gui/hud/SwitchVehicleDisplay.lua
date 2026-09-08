-- Local values: data, old, SwitchVehicleDisplay_mt, switchVehicleDisplay, k, elem
local v1_
if SwitchVehicleDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.switchVehicleDisplay
	v1_ = {
		["vehicle"] = v2_.vehicle,
		["player"] = v2_.player,
		["hud"] = v2_.hud,
		["uiScale"] = v2_.uiScale,
		["hudAtlasPath"] = v2_.hudAtlasPath,
		["controlHudAtlasPath"] = v2_.controlHudAtlasPath,
		["lastGyroscopeSteeringState"] = v2_.lastGyroscopeSteeringState
	}
	v2_:delete()
end
SwitchVehicleDisplay = {}
SwitchVehicleDisplay.MOVE_ANIMATION_DURATION = 500
SwitchVehicleDisplay.STATE_TOUCH = 0
SwitchVehicleDisplay.STATE_CONTROLLER = 1
local data = Class(SwitchVehicleDisplay, HUDDisplayElement)

-- Upvalues: SwitchVehicleDisplay_mt
-- Local values: backgroundOverlay, self
function SwitchVehicleDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
	-- upvalues: (copy) data
	local v7_ = SwitchVehicleDisplay.createBackground()
	local v8_ = SwitchVehicleDisplay:superClass().new(v7_, nil, data)
	v8_.hud = hud
	v8_.uiScale = 1
	v8_.hudAtlasPath = hudAtlasPath
	v8_.controlHudAtlasPath = controlHudAtlasPath
	v8_.vehicle = nil
	v8_.player = nil
	v8_.touchButtons = {}
	v8_.hudElements = {}
	v8_.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	v8_.lastGyroscopeSteeringState = false
	v8_.vehicleControls = {}
	v8_:createComponents()
	return v8_
end

-- Local values: _, button
function SwitchVehicleDisplay:delete()
	for _, v10_ in pairs(self.touchButtons) do
		self.hud:removeTouchButton(v10_)
	end
	SwitchVehicleDisplay:superClass().delete(self)
end

function SwitchVehicleDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
	self:updatePositionState()
end

function SwitchVehicleDisplay:setPlayer(player)
	self.player = player
	self:updatePositionState()
end

-- Local values: sizeXLeft, sizeY, sizeXMiddle, _, sizeXRight, _, uvsLeft, uvsMiddle, uvsRight, posXLeft, overlayLeft, posXMiddle, overlayMiddle, middleElement, posXRight, overlayRight, rightElement, width, _, sizeXPressed, _, uvsPressed, overlayLeftPressed, leftPressedElement, overlayRightPressed, rightPressedElement
function SwitchVehicleDisplay:createBackgroundElements(posX, posY)
	local v18_ = getNormalizedScreenValues
	local v19_ = SwitchVehicleDisplay.SIZE.BG_LEFT
	local v20_, v21_ = v18_(unpack(v19_))
	local v22_ = getNormalizedScreenValues
	local v23_ = SwitchVehicleDisplay.SIZE.BG_MIDDLE
	local v24_, _ = v22_(unpack(v23_))
	local v25_ = getNormalizedScreenValues
	local v26_ = SwitchVehicleDisplay.SIZE.BG_RIGHT
	local v27_, _ = v25_(unpack(v26_))
	local v28_ = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_LEFT)
	local v29_ = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_MIDDLE)
	local v30_ = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_RIGHT)
	self.uvsLeft = v28_
	self.uvsMiddle = v29_
	self.uvsRight = v30_
	self.uvsLeftDisabled = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_LEFT_DISABLED)
	self.uvsMiddleDisabled = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_MIDDLE_DISABLED)
	self.uvsRightDisabled = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_RIGHT_DISABLED)
	local v31_ = Overlay.new(self.hudAtlasPath, posX, posY, v20_, v21_)
	v31_:setUVs(v28_)
	self.leftElement = HUDElement.new(v31_)
	self:addChild(self.leftElement)
	local v32_ = posX + v20_
	local v33_ = Overlay.new(self.hudAtlasPath, v32_, posY, v24_, v21_)
	v33_:setUVs(v29_)
	local v34_ = HUDElement.new(v33_)
	self.middleElement = v34_
	self:addChild(v34_)
	local v35_ = v32_ + v24_
	local v36_ = Overlay.new(self.hudAtlasPath, v35_, posY, v27_, v21_)
	v36_:setUVs(v30_)
	local v37_ = HUDElement.new(v36_)
	self.rightElement = v37_
	self:addChild(v37_)
	local v38_ = getNormalizedScreenValues
	local v39_ = SwitchVehicleDisplay.SIZE.BACKGROUND
	local v40_, _ = v38_(unpack(v39_))
	local v41_ = getNormalizedScreenValues
	local v42_ = SwitchVehicleDisplay.SIZE.BG_PRESSED
	local v43_, _ = v41_(unpack(v42_))
	local v44_ = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_PRESSED)
	local v45_ = Overlay.new(self.hudAtlasPath, posX, posY, v43_, v21_)
	v45_:setUVs(v44_)
	local v_u_46_ = HUDElement.new(v45_)
	v_u_46_:setVisible(false)
	self:addChild(v_u_46_)
	local v47_ = Overlay.new(self.hudAtlasPath, posX + v40_ - v43_, posY, v43_, v21_)
	v47_:setUVs(v44_)
	v47_:setInvertX(true)
	local v_u_48_ = HUDElement.new(v47_)
	v_u_48_:setVisible(false)
	self:addChild(v_u_48_)
	function self.pressButtonLeftCallback()
		-- upvalues: (copy) self, (copy) v_u_46_
		if self.isActive then
			v_u_46_:setVisible(true)
			self.leftElement:setVisible(false)
			self.middleElement:setVisible(false)
			self.rightElement:setVisible(false)
		end
	end
	function self.pressButtonRightCallback()
		-- upvalues: (copy) self, (copy) v_u_48_
		if self.isActive then
			v_u_48_:setVisible(true)
			self.leftElement:setVisible(false)
			self.middleElement:setVisible(false)
			self.rightElement:setVisible(false)
		end
	end
	function self.releaseButtonCallback()
		-- upvalues: (copy) self, (copy) v_u_46_, (copy) v_u_48_
		if self.isActive then
			v_u_46_:setVisible(false)
			v_u_48_:setVisible(false)
			self.leftElement:setVisible(true)
			self.middleElement:setVisible(true)
			self.rightElement:setVisible(true)
		end
	end
end

-- Local values: posX, posY, iconOffsetX, iconOffsetY, iconSizeX, iconSizeY, iconOverlay, glyphSwitchVehicleBackOffsetX, glyphSwitchVehicleBackOffsetY, glyphElementBack, glyphSwitchVehicleOffsetX, glyphSwitchVehicleOffsetY, glyphElement, arrowLeftSizeX, arrowLeftSizeY, arrowLeftOffsetX, arrowLeftOffsetY, arrowLeftOverlay, touchOffsetX, arrowRightSizeX, arrowRightSizeY, arrowRightOffsetX, arrowRightOffsetY, arrowRightOverlay, offsetX, offsetY
function SwitchVehicleDisplay:createComponents()
	local v50_, v51_ = self:getPosition()
	self:createBackgroundElements(v50_, v51_)
	local v52_ = getNormalizedScreenValues
	local v53_ = SwitchVehicleDisplay.POSITION.ICON
	local v54_, v55_ = v52_(unpack(v53_))
	local v56_ = getNormalizedScreenValues
	local v57_ = SwitchVehicleDisplay.SIZE.ICON
	local v58_, v59_ = v56_(unpack(v57_))
	local v60_ = Overlay.new(self.controlHudAtlasPath, v50_ + v54_, v51_ + v55_, v58_, v59_)
	v60_:setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ICON))
	self:addChild(HUDElement.new(v60_))
	local v61_ = getNormalizedScreenValues
	local v62_ = SwitchVehicleDisplay.POSITION.GLYPH_SWITCH_VEHICLE_BACK
	local v63_, v64_ = v61_(unpack(v62_))
	local v65_ = InputGlyphMobileElement.new(g_inputDisplayManager)
	v65_:setAction(InputAction.SWITCH_VEHICLE_BACK)
	v65_:setIsLeftAligned(true)
	v65_:setPosition(v50_ + v63_, v51_ + v64_)
	v65_:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
	self.glyphElementBack = v65_
	self:addChild(v65_)
	local v66_ = getNormalizedScreenValues
	local v67_ = SwitchVehicleDisplay.POSITION.GLYPH_SWITCH_VEHICLE
	local v68_, v69_ = v66_(unpack(v67_))
	local v70_ = InputGlyphMobileElement.new(g_inputDisplayManager)
	v70_:setAction(InputAction.SWITCH_VEHICLE)
	v70_:setPosition(v50_ + v68_, v51_ + v69_)
	v70_:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
	self.glyphElement = v70_
	self:addChild(v70_)
	local v71_ = getNormalizedScreenValues
	local v72_ = SwitchVehicleDisplay.SIZE.ARROW_LEFT
	local v73_, v74_ = v71_(unpack(v72_))
	local v75_ = getNormalizedScreenValues
	local v76_ = SwitchVehicleDisplay.POSITION.ARROW_LEFT
	local v77_, v78_ = v75_(unpack(v76_))
	local v79_ = Overlay.new(self.controlHudAtlasPath, v50_ + v77_, v51_ + v78_, v73_, v74_)
	v79_:setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ARROW_LEFT))
	self.switchLeftOverlay = v79_
	self:addChild(HUDElement.new(v79_))
	local v80_ = { 0.1, 0.4 }
	local v81_ = self.touchButtons
	local v82_ = self.hud
	local v83_ = self.onSwitchLeft
	local v84_ = TouchHandler.TRIGGER_UP
	table.insert(v81_, v82_:addTouchButton(v79_, v80_, 0.5, v83_, self, v84_))
	local v85_ = self.touchButtons
	local v86_ = self.hud
	local v87_ = self.pressButtonLeftCallback
	local v88_ = TouchHandler.TRIGGER_DOWN
	table.insert(v85_, v86_:addTouchButton(v79_, v80_, 0.5, v87_, self, v88_))
	local v89_ = self.touchButtons
	local v90_ = self.hud
	local v91_ = self.releaseButtonCallback
	local v92_ = TouchHandler.TRIGGER_UP
	table.insert(v89_, v90_:addTouchButton(v79_, v80_, 0.5, v91_, self, v92_))
	local v93_ = getNormalizedScreenValues
	local v94_ = SwitchVehicleDisplay.SIZE.ARROW_RIGHT
	local v95_, v96_ = v93_(unpack(v94_))
	local v97_ = getNormalizedScreenValues
	local v98_ = SwitchVehicleDisplay.POSITION.ARROW_RIGHT
	local v99_, v100_ = v97_(unpack(v98_))
	local v101_ = Overlay.new(self.controlHudAtlasPath, v50_ + v99_, v51_ + v100_, v95_, v96_)
	v101_:setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ARROW_RIGHT))
	self.switchRightOverlay = v101_
	self:addChild(HUDElement.new(v101_))
	local v102_ = { v80_[2], v80_[1] }
	local v103_ = self.touchButtons
	local v104_ = self.hud
	local v105_ = self.onSwitchRight
	local v106_ = TouchHandler.TRIGGER_UP
	table.insert(v103_, v104_:addTouchButton(v101_, v102_, 0.5, v105_, self, v106_))
	local v107_ = self.touchButtons
	local v108_ = self.hud
	local v109_ = self.pressButtonRightCallback
	local v110_ = TouchHandler.TRIGGER_DOWN
	table.insert(v107_, v108_:addTouchButton(v101_, v102_, 0.5, v109_, self, v110_))
	local v111_ = self.touchButtons
	local v112_ = self.hud
	local v113_ = self.releaseButtonCallback
	local v114_ = TouchHandler.TRIGGER_UP
	table.insert(v111_, v112_:addTouchButton(v101_, v102_, 0.5, v113_, self, v114_))
	local v115_ = getNormalizedScreenValues
	local v116_ = SwitchVehicleDisplay.POSITION.GAMEPAD_OFFSET
	local v117_, v118_ = v115_(unpack(v116_))
	self.positionTouch = { v50_ + v117_, v51_ + v118_ }
	self.positionGamepad = { v50_, v51_ }
end

function SwitchVehicleDisplay:onSwitchLeft(x, y, isCancel)
	if g_sleepManager:getIsSleeping() then
		return
	elseif self.isActive then
		if not isCancel then
			g_localPlayer:cycleCurrentVehicle(-1)
		end
	end
end

function SwitchVehicleDisplay:onSwitchRight(x, y, isCancel)
	if g_sleepManager:getIsSleeping() then
		return
	elseif self.isActive then
		if not isCancel then
			g_localPlayer:cycleCurrentVehicle(1)
		end
	end
end

function SwitchVehicleDisplay:update(dt)
	SwitchVehicleDisplay:superClass().update(self, dt)
	self:updateButton()
end

-- Local values: wasActive, vehicle
function SwitchVehicleDisplay:updateButton()
	local v126_ = self.isActive
	local v127_ = not g_gui:getIsGuiVisible()
	if v127_ then
		v127_ = isButtonActive
	end
	self.isActive = v127_
	if self.isActive then
		self.isActive = g_currentMission:getNextVehicle(1) ~= nil
	end
	if v126_ ~= self.isActive then
		self.glyphElement:setVisible(self.isActive)
		self.glyphElementBack:setVisible(self.isActive)
		if self.isActive then
			self.leftElement:setUVs(self.uvsLeft)
			self.middleElement:setUVs(self.uvsMiddle)
			self.rightElement:setUVs(self.uvsRight)
			return
		end
		self.leftElement:setUVs(self.uvsLeftDisabled)
		self.middleElement:setUVs(self.uvsMiddleDisabled)
		self.rightElement:setUVs(self.uvsRightDisabled)
	end
end

-- Local values: isControllerInput
function SwitchVehicleDisplay:updatePositionState(force)
	local v130_ = self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD and ((Platform.hasTouchSliders and true or false) and self.lastGyroscopeSteeringState)
	if v130_ then
		v130_ = self.vehicle ~= nil
	end
	if v130_ then
		self:setPositionState(SwitchVehicleDisplay.STATE_CONTROLLER, force)
	else
		self:setPositionState(SwitchVehicleDisplay.STATE_TOUCH, force)
	end
end

function SwitchVehicleDisplay:onInputHelpModeChange(inputHelpMode, force)
	self.lastInputHelpMode = inputHelpMode
	self:updatePositionState(force)
end

function SwitchVehicleDisplay:onGyroscopeSteeringChanged(state)
	self.lastGyroscopeSteeringState = state
	self:updatePositionState()
end

-- Local values: startX, startY, targetX, targetY, speed, sequence
function SwitchVehicleDisplay:setPositionState(state, force)
	if Platform.hasTouchSliders then
		if state ~= self.lastPositionState then
			local v139_, v140_ = self:getPosition()
			local v141_ = self.positionGamepad[1]
			local v142_ = self.positionGamepad[2]
			local v143_ = SwitchVehicleDisplay.MOVE_ANIMATION_DURATION
			if state == SwitchVehicleDisplay.STATE_TOUCH then
				v141_ = self.positionTouch[1]
				v142_ = self.positionTouch[2]
				v143_ = SwitchVehicleDisplay.MOVE_ANIMATION_DURATION / 5
			end
			local v144_ = TweenSequence.new(self)
			v144_:insertTween(MultiValueTween.new(self.setPosition, { v139_, v140_ }, { v141_, v142_ }, force and 0.01 or v143_), 0)
			v144_:start()
			self.animation = v144_
			self.lastPositionState = state
		end
	end
end

-- Local values: currentVisibility, posX, posY, offsetX, offsetY
function SwitchVehicleDisplay:setScale(uiScale)
	SwitchVehicleDisplay:superClass().setScale(self, uiScale, uiScale)
	local v147_ = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local v148_, v149_ = SwitchVehicleDisplay.getBackgroundPosition(uiScale, self:getWidth())
	self:setPosition(v148_, v149_)
	local v150_ = getNormalizedScreenValues
	local v151_ = SwitchVehicleDisplay.POSITION.GAMEPAD_OFFSET
	local v152_, v153_ = v150_(unpack(v151_))
	self.positionTouch = { v148_ + v152_ * uiScale, v149_ + v153_ * uiScale }
	self.positionGamepad = { v148_, v149_ }
	self:storeOriginalPosition()
	self:setVisible(v147_, false)
	if self.lastPositionState == SwitchVehicleDisplay.STATE_TOUCH then
		self:setPosition(self.positionTouch[1], self.positionTouch[2])
	end
end

-- Local values: offX, offY
function SwitchVehicleDisplay.getBackgroundPosition(scale, width)
	local v155_ = getNormalizedScreenValues
	local v156_ = SwitchVehicleDisplay.POSITION.BACKGROUND
	local v157_, v158_ = v155_(unpack(v156_))
	return v157_ * scale, v158_ * scale
end
function SwitchVehicleDisplay.createBackground()
	local v159_ = getNormalizedScreenValues
	local v160_ = SwitchVehicleDisplay.SIZE.BACKGROUND
	local v161_, v162_ = v159_(unpack(v160_))
	local v163_, v164_ = SwitchVehicleDisplay.getBackgroundPosition(1, v161_)
	return Overlay.new(nil, v163_, v164_, v161_, v162_)
end
SwitchVehicleDisplay.SIZE = {
	["BACKGROUND"] = { 224, 106 },
	["BG_PRESSED"] = { 224, 106 },
	["BG_LEFT"] = { 25, 106 },
	["BG_MIDDLE"] = { 174, 106 },
	["BG_RIGHT"] = { 25, 106 },
	["ICON"] = { 96, 96 },
	["ARROW_LEFT"] = { 76, 76 },
	["ARROW_RIGHT"] = { 76, 76 },
	["BUTTON_SIZE"] = { 115, 120 }
}
SwitchVehicleDisplay.POSITION = {
	["BACKGROUND"] = { 50, 50 },
	["GAMEPAD_OFFSET"] = { 515, 0 },
	["ICON"] = { 60, 5 },
	["GLYPH_SWITCH_VEHICLE"] = { 237, 81 },
	["GLYPH_SWITCH_VEHICLE_BACK"] = { -17, 81 },
	["ARROW_LEFT"] = { 0, 15 },
	["ARROW_RIGHT"] = { 142, 15 }
}
SwitchVehicleDisplay.UV = {
	["ICON"] = {
		96,
		96,
		96,
		96
	},
	["ARROW_LEFT"] = {
		0,
		96,
		96,
		96
	},
	["ARROW_RIGHT"] = {
		96,
		96,
		-96,
		96
	},
	["BG_LEFT"] = {
		132,
		908,
		25,
		106
	},
	["BG_MIDDLE"] = {
		157,
		908,
		56,
		106
	},
	["BG_RIGHT"] = {
		213,
		908,
		25,
		106
	},
	["BG_PRESSED"] = {
		578,
		908,
		224,
		106
	},
	["BG_LEFT_DISABLED"] = {
		344,
		908,
		25,
		106
	},
	["BG_MIDDLE_DISABLED"] = {
		369,
		908,
		56,
		106
	},
	["BG_RIGHT_DISABLED"] = {
		425,
		908,
		25,
		106
	}
}
if v1_ ~= nil then
	local v165_ = SwitchVehicleDisplay.new(v1_.hud, v1_.hudAtlasPath, v1_.controlHudAtlasPath)
	v165_:setScale(v1_.uiScale)
	v165_:setVehicle(v1_.vehicle)
	v165_:setPlayer(v1_.player)
	v165_.lastGyroscopeSteeringState = v1_.lastGyroscopeSteeringState
	for v166_, v167_ in ipairs(g_currentMission.hud.displayComponents) do
		if v167_ == g_currentMission.hud.switchVehicleDisplay then
			g_currentMission.hud.displayComponents[v166_] = v165_
			break
		end
	end
	g_currentMission.hud.switchVehicleDisplay = v165_
	Logging.info("Reloaded")
end
