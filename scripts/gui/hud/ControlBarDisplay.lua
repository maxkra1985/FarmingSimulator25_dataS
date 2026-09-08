-- Local values: data, old, ControlBarDisplay_mt, controlBarDisplay, k, elem
local v1_
if ControlBarDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.controlBarDisplay
	v1_ = {
		["vehicle"] = v2_.vehicle,
		["player"] = v2_.player,
		["hud"] = v2_.hud,
		["uiScale"] = v2_.uiScale,
		["hudAtlasPath"] = v2_.hudAtlasPath,
		["controlHudAtlasPath"] = v2_.controlHudAtlasPath
	}
	v2_:delete()
end
ControlBarDisplay = {}
ControlBarDisplay.MOVE_ANIMATION_DURATION = 500
ControlBarDisplay.STATE_TOUCH = 0
ControlBarDisplay.STATE_CONTROLLER = 1
ControlBarDisplay.STATE_AI_TOUCH = 2
local data = Class(ControlBarDisplay, HUDDisplayElement)

-- Upvalues: ControlBarDisplay_mt
-- Local values: backgroundOverlay, self
function ControlBarDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
	-- upvalues: (copy) data
	local v7_ = ControlBarDisplay.createBackground()
	local v8_ = ControlBarDisplay:superClass().new(v7_, nil, data)
	v8_.hud = hud
	v8_.uiScale = 1
	v8_.hudAtlasPath = hudAtlasPath
	v8_.controlHudAtlasPath = controlHudAtlasPath
	v8_.vehicle = nil
	v8_.lastChildVehicleHash = ""
	v8_.sowingMachine = nil
	v8_.player = nil
	v8_.hudElements = {}
	v8_.buttons = {}
	v8_.controlButtons = {}
	v8_.inputGlyphs = {}
	v8_.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	v8_.lastAIState = false
	v8_.lastGyroscopeSteeringState = false
	v8_.fillLevelBuffer = {}
	v8_.fillLevelBufferAddIndex = 0
	v8_.fillLevelBufferNeedsSorting = false
	v8_.fillLevelControls = {}
	v8_.vehicleControls = {}
	v8_.vehicleControls.attach = {
		["availableFunc"] = "getShowAttachControlBarAction",
		["accessibleFunc"] = "getAttachControlBarActionAccessible",
		["actionFunc"] = "detachAttachedImplement",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.DETACH,
		["prio"] = 3,
		["inputAction"] = InputAction.ATTACH,
		["name"] = "attach"
	}
	v8_.vehicleControls.turnOn = {
		["allowedFunc"] = "getAreControlledActionsAllowed",
		["availableFunc"] = "getAreControlledActionsAvailable",
		["accessibleFunc"] = "getAreControlledActionsAccessible",
		["getIconsFunc"] = "getControlledActionIcons",
		["actionFunc"] = "playControlledActions",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["directionFunc"] = "getActionControllerDirection",
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.TURN_ON,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["prio"] = 4,
		["inputAction"] = InputAction.VEHICLE_ACTION_CONTROL,
		["name"] = "turnOn"
	}
	v8_.vehicleControls.ai = {
		["availableFunc"] = "getCanToggleAIVehicle",
		["accessibleFunc"] = "getShowAIToggleActionEvent",
		["actionFunc"] = "toggleAIVehicle",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["directionFunc"] = "getIsAIActive",
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.AI,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
		["prio"] = 5,
		["inputAction"] = InputAction.TOGGLE_AI,
		["name"] = "ai"
	}
	v8_.vehicleControls.leave = {
		["availableFunc"] = "getCanLeaveVehicle",
		["accessibleFunc"] = "getIsLeavingAllowed",
		["actionFunc"] = "doLeaveVehicle",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.LEAVE_VEHICLE,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
		["prio"] = 6,
		["inputAction"] = InputAction.ENTER,
		["name"] = "leave"
	}
	v8_.vehicleControls.unloadFork = {
		["availableFunc"] = "getCanUnloadFork",
		["accessibleFunc"] = "getIsForkUnloadingAllowed",
		["actionFunc"] = "doUnloadFork",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.UNLOAD_FORK,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
		["prio"] = 7,
		["inputAction"] = InputAction.UNLOAD_FORK,
		["name"] = "unloadFork"
	}
	v8_.vehicleControls.leave_horse = {
		["availableFunc"] = "getCanLeaveRideable",
		["accessibleFunc"] = "getIsLeavingAllowed",
		["actionFunc"] = "doLeaveVehicle",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.LEAVE_HORSE,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
		["prio"] = 6,
		["inputAction"] = InputAction.ENTER,
		["name"] = "leave_horse"
	}
	v8_.playerControls = {}
	v8_.playerControls.enter_vehicle = {
		["availableFunc"] = "getCanEnterVehicle",
		["actionFunc"] = "onInputEnter",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.ENTER_VEHICLE,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
		["prio"] = 7,
		["inputAction"] = InputAction.ENTER,
		["name"] = "enter_vehicle"
	}
	v8_.playerControls.enter_horse = {
		["availableFunc"] = "getCanEnterRideable",
		["actionFunc"] = "onInputEnter",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.ENTER_HORSE,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
		["prio"] = 8,
		["inputAction"] = InputAction.ENTER,
		["name"] = "ride_horse"
	}
	v8_.playerControls.ride = {
		["availableFunc"] = "getIsRideStateAvailable",
		["actionFunc"] = "activateRideState",
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.ENTER_HORSE,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
		["prio"] = 9,
		["inputAction"] = InputAction.ENTER,
		["name"] = "ride_horse"
	}
	v8_.customControls = {}
	v8_.customControls.activateObject = {
		["availableFunc"] = v8_.getIsActivatableObjectAvailable,
		["actionFunc"] = v8_.triggerActivatableObject,
		["triggerType"] = TouchHandler.TRIGGER_UP,
		["fullTapNeeded"] = true,
		["controlButton"] = nil,
		["uvs"] = ControlBarDisplay.UV.ACTIVATABLE_OBJECT,
		["iconColor_pos"] = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
		["iconColor_neg"] = ControlBarDisplay.COLOR.BUTTON,
		["prio"] = 7,
		["inputAction"] = InputAction.ACTIVATE_OBJECT,
		["name"] = "activateObject"
	}
	v8_:createComponents()
	return v8_
end

-- Local values: iconSizeX, iconSizeY, _, control, button, _, control, button, _, control, button, posX, posY, offsetX, offsetY
function ControlBarDisplay:createComponents()
	local v10_ = {}
	local v11_ = getNormalizedScreenValues
	local v12_ = ControlBarDisplay.POSITION.BUTTON_START
	__set_list(v10_, 1, {v11_(unpack(v12_))})
	self.buttonStartPos = v10_
	local v13_ = getNormalizedScreenValues
	local v14_ = ControlBarDisplay.POSITION.BUTTON_OFFSET
	self.buttonOffsetX = v13_(unpack(v14_))
	local v15_ = getNormalizedScreenValues
	local v16_ = ControlBarDisplay.SIZE.FILL_LEVEL_ICON
	local v17_, v18_ = v15_(unpack(v16_))
	self.fillLevelIconSizeX = v17_
	self.fillLevelIconSizeY = v18_
	local v19_ = getNormalizedScreenValues
	local v20_ = ControlBarDisplay.POSITION.FILL_LEVEL_ICON_OFFSET
	local v21_, v22_ = v19_(unpack(v20_))
	self.fillLevelIconOffsetX = v21_
	self.fillLevelIconOffsetY = v22_
	self.hudControls = {}
	local v23_ = self.hudControls
	table.insert(v23_, self:addFillLevelControl())
	local v24_ = self.hudControls
	table.insert(v24_, self:addFillLevelControl())
	local v25_ = getNormalizedScreenValues
	local v26_ = ControlBarDisplay.SIZE.ICON
	local v27_, v28_ = v25_(unpack(v26_))
	for _, v_u_29_ in pairs(self.vehicleControls) do
		local v30_ = HUDButtonElement.new(self.hud, 0, 0)
		v30_:setIcon(self.controlHudAtlasPath, v27_, v28_, GuiUtils.getUVs(v_u_29_.uvs))
		v30_:setAction(v_u_29_.inputAction)
		function v30_.buttonCallback()
			-- upvalues: (copy) v_u_29_
			if not g_sleepManager:getIsSleeping() then
				local v31_ = v_u_29_.vehicle
				if v31_ ~= nil then
					if v_u_29_.allowedFunc ~= nil then
						local v32_, v33_ = v31_[v_u_29_.allowedFunc](v31_)
						if not v32_ then
							g_currentMission:showBlinkingWarning(v33_, 2500)
							return
						end
					end
					v31_[v_u_29_.actionFunc](v31_)
				end
			end
		end
		v30_:addTouchHandler(v30_.buttonCallback, self)
		self:addChild(v30_)
		v_u_29_.button = v30_
		local v34_ = self.hudControls
		table.insert(v34_, v_u_29_)
	end
	for _, v_u_35_ in pairs(self.playerControls) do
		local v36_ = HUDButtonElement.new(self.hud, 0, 0)
		v36_:setIcon(self.controlHudAtlasPath, v27_, v28_, GuiUtils.getUVs(v_u_35_.uvs))
		v36_:setAction(v_u_35_.inputAction)
		function v36_.buttonCallback()
			-- upvalues: (copy) self, (copy) v_u_35_
			if not g_sleepManager:getIsSleeping() then
				local v37_ = self.player
				if v37_ ~= nil then
					v37_[v_u_35_.actionFunc](v37_)
				end
			end
		end
		v36_:addTouchHandler(v36_.buttonCallback, self)
		self:addChild(v36_)
		v_u_35_.button = v36_
		local v38_ = self.hudControls
		table.insert(v38_, v_u_35_)
	end
	for _, v_u_39_ in pairs(self.customControls) do
		local v40_ = HUDButtonElement.new(self.hud, 0, 0)
		v40_:setIcon(self.controlHudAtlasPath, v27_, v28_, GuiUtils.getUVs(v_u_39_.uvs))
		v40_:setAction(v_u_39_.inputAction)
		function v40_.buttonCallback()
			-- upvalues: (copy) v_u_39_
			v_u_39_.actionFunc()
		end
		v40_:addTouchHandler(v40_.buttonCallback, self)
		v_u_39_.button = v40_
		self:addChild(v40_)
		local v41_ = self.hudControls
		table.insert(v41_, v_u_39_)
	end
	self.buttons = {}
	self.controlButtons = {}
	self.hudElements = {}
	local v42_, v43_ = self:getPosition()
	local v44_ = getNormalizedScreenValues
	local v45_ = ControlBarDisplay.POSITION.GAMEPAD_OFFSET
	local v46_, v47_ = v44_(unpack(v45_))
	self.positionTouch = { v42_ + v46_, v43_ + v47_ }
	self.positionGamepad = { v42_, v43_ }
end

-- Local values: glyphOverlay
function ControlBarDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
	self:updatePositionState()
	self:updateFillLevelBuffers(vehicle)
	self:updateButtons()
	if self.buttonToggleSeeds ~= nil then
		local v_u_50_ = self.buttonToggleSeeds.glyphElement.overlay
		function v_u_50_.getIsVisible()
			-- upvalues: (copy) v_u_50_, (copy) self
			local v51_ = v_u_50_.visible
			if v51_ then
				if self.sowingMachine == nil then
					v51_ = false
				else
					v51_ = #self.sowingMachine.spec_sowingMachine.seeds > 1
				end
			end
			return v51_
		end
	end
end

function ControlBarDisplay:setPlayer(player)
	self.player = player
	self:updatePositionState()
end

function ControlBarDisplay:update(dt)
	ControlBarDisplay:superClass().update(self, dt)
	self:updateButtons()
	self:updateButtonPositions()
end

-- Local values: currentVehicle, _, childVehicle, name, vehicleControl, vehicle, isAvailable, isAccessible, availableFunc, _, implement, accessibleFunc, iconsChanged, getIconsFunc, uvNegStr, uvPosStr, allowColorChange, uvs_neg, uvs_pos, iconColor_neg, iconColor_pos, directionFunc, direction, button, uvs, color, player, name, playerControl, isAvailable, availableFunc, name, control, isAvailable
function ControlBarDisplay:updateButtons()
	local v57_ = self.vehicle
	self.sowingMachine = nil
	if self.vehicle ~= nil then
		for _, v58_ in ipairs(self.vehicle.childVehicles) do
			if v58_.spec_sowingMachine ~= nil then
				self.sowingMachine = v58_
				break
			end
		end
	end
	self:updateFillLevelBuffers(v57_)
	for _, v59_ in pairs(self.vehicleControls) do
		local v60_ = nil
		local v61_ = false
		local v62_ = false
		if v57_ ~= nil then
			local v63_ = v57_[v59_.availableFunc]
			if v63_ ~= nil then
				v61_ = v63_(v57_)
				if v61_ then
					v60_ = v57_
				elseif v59_.useAttachables and v57_.getAttachedImplements ~= nil then
					for _, v64_ in ipairs(v57_:getAttachedImplements()) do
						local v65_ = v64_.object[v59_.availableFunc]
						if v65_ ~= nil then
							v61_ = v65_(v64_.object)
							v60_ = v64_.object
						end
					end
				end
			end
		end
		if v60_ ~= nil then
			local v66_ = v60_[v59_.accessibleFunc]
			if v66_ ~= nil then
				v62_ = v66_(v60_)
			end
			local v67_ = false
			if v59_.getIconsFunc ~= nil then
				local v68_ = v60_[v59_.getIconsFunc]
				if v68_ ~= nil then
					local v69_, v70_, v71_ = v68_(v60_)
					local v72_ = ControlBarDisplay.UV[v69_]
					local v73_ = ControlBarDisplay.UV[v70_]
					local v74_ = ControlBarDisplay.COLOR.BUTTON_ACTIVE
					local v75_ = ControlBarDisplay.COLOR.BUTTON
					if not v71_ then
						v74_ = ControlBarDisplay.COLOR.BUTTON
					end
					if v73_ ~= v59_.uvs_pos or v72_ ~= v59_.uvs_neg then
						v59_.uvs_pos = v73_
						v59_.uvs_neg = v72_
						v67_ = true
					end
					if v75_ ~= v59_.iconColor_pos or v74_ ~= v59_.iconColor_neg then
						v59_.iconColor_pos = v75_
						v59_.iconColor_neg = v74_
						v67_ = true
					end
				end
			end
			if v59_.directionFunc ~= nil then
				local v76_ = v60_[v59_.directionFunc]
				if v76_ ~= nil then
					local v77_ = v76_(v60_)
					local v78_ = type(v77_) == "boolean" and (v77_ and 1 or -1) or v77_
					if v78_ ~= v59_.lastDirection or v67_ then
						local v79_ = v59_.button
						local v80_ = v78_ == 1 and v59_.uvs_pos or v59_.uvs_neg
						if v80_ ~= nil and v80_ ~= v59_.uvs then
							v79_:setIcon(nil, nil, nil, GuiUtils.getUVs(v80_), nil, nil)
							v59_.uvs = v80_
						end
						local v81_ = v78_ == 1 and v59_.iconColor_pos or v59_.iconColor_neg
						if v81_ ~= nil and v81_ ~= v59_.color then
							v79_:setIcon(nil, nil, nil, nil, nil, nil, v81_)
							v59_.color = v81_
						end
						v59_.lastDirection = v78_
					end
				end
			end
		end
		v59_.vehicle = v60_
		v59_.button:setVisible(v61_)
		v59_.button:setDisabled(not v62_ or g_gui:getIsGuiVisible())
	end
	local v82_ = self.player
	for _, v83_ in pairs(self.playerControls) do
		local v84_ = false
		if v82_ ~= nil then
			local v85_ = v82_[v83_.availableFunc]
			if v85_ ~= nil then
				v84_ = v85_(v82_)
			end
		end
		v83_.button:setVisible(v84_)
		v83_.button:setDisabled(g_gui:getIsGuiVisible())
	end
	for _, v86_ in pairs(self.customControls) do
		local v87_ = v86_.availableFunc(self)
		v86_.button:setVisible(v87_)
		v86_.button:setDisabled(g_gui:getIsGuiVisible())
	end
end

-- Local values: posX, posY, offsetX, _, control
function ControlBarDisplay:updateButtonPositions()
	local v89_, v90_ = self:getPosition()
	local v91_ = self.buttonOffsetX * self.uiScale
	table.sort(self.hudControls, function(p92_, p93_)
		return p92_.prio < p93_.prio
	end)
	for _, v94_ in ipairs(self.hudControls) do
		if v94_.button:getVisible() then
			v94_.button:setPosition(v89_, v90_)
			v89_ = v89_ + v94_.button:getWidth() + v91_
		end
	end
end

function ControlBarDisplay:onInputHelpModeChange(inputHelpMode, force)
	self.lastInputHelpMode = inputHelpMode
	self:updatePositionState(force)
end

function ControlBarDisplay:onAIVehicleStateChanged(state, vehicle, force)
	self.lastAIState = state
	self:updatePositionState(force)
end

function ControlBarDisplay:onGyroscopeSteeringChanged(state)
	self.lastGyroscopeSteeringState = state
	self:updatePositionState()
end

function ControlBarDisplay:getIsActivatableObjectAvailable()
	return g_currentMission.activatableObjectsSystem:getActivatable() ~= nil
end

-- Local values: object
function ControlBarDisplay:triggerActivatableObject()
	local v103_ = g_currentMission.activatableObjectsSystem:getActivatable()
	if v103_ ~= nil then
		v103_:run()
	end
end

-- Local values: isControllerInput
function ControlBarDisplay:updatePositionState(force)
	if Platform.hasTouchSliders and (self.player ~= nil and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD) then
		self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
		return
	elseif not Platform.hasTouchSliders or (self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and true or self.lastGyroscopeSteeringState) then
		self:setPositionState(ControlBarDisplay.STATE_CONTROLLER, force)
	else
		self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
	end
end

-- Local values: startX, startY, targetX, targetY, speed, sequence
function ControlBarDisplay:setPositionState(state, force)
	if Platform.hasTouchSliders then
		if state ~= self.lastPositionState then
			local v109_, v110_ = self:getPosition()
			local v111_ = self.positionGamepad[1]
			local v112_ = self.positionGamepad[2]
			local v113_ = ControlBarDisplay.MOVE_ANIMATION_DURATION
			if state == ControlBarDisplay.STATE_TOUCH then
				v111_ = self.positionTouch[1]
				v112_ = self.positionTouch[2]
				v113_ = ControlBarDisplay.MOVE_ANIMATION_DURATION / 5
			end
			local v114_ = TweenSequence.new(self)
			v114_:insertTween(MultiValueTween.new(self.setPosition, { v109_, v110_ }, { v111_, v112_ }, force and 0.01 or v113_), 0)
			v114_:start()
			self.animation = v114_
			self.lastPositionState = state
		end
	end
end

-- Local values: fillLevelControl, button, uvs, posX, posY, offsetX, offsetY, sizeX, sizeY, backgroundOverlay, fillLevelBarBackground, fillLevelBarOverlay, fillLevelBar
function ControlBarDisplay:addFillLevelControl()
	local v116_ = {}
	local v117_ = HUDButtonElement.new(self.hud, 0, 0)
	v117_:setIcon(nil, self.fillLevelIconSizeX, self.fillLevelIconSizeY, Overlay.DEFAULT_UVS, self.fillLevelIconOffsetX, self.fillLevelIconOffsetY)
	v117_:setAction(InputAction.TOGGLE_SEEDS)
	v117_:addTouchHandler(ControlBarDisplay.onChangeSeedCallback, v116_)
	self:addChild(v117_)
	v116_.button = v117_
	v116_.prio = #self.fillLevelControls + 1
	local v118_ = self.fillLevelControls
	table.insert(v118_, v116_)
	local v119_ = GuiUtils.getUVs(ControlBarDisplay.UV.FILL_LEVEL_BAR)
	local v120_, v121_ = v117_:getPosition()
	local v122_ = getNormalizedScreenValues
	local v123_ = ControlBarDisplay.POSITION.FILL_LEVEL_BAR_OFFSET
	local v124_, v125_ = v122_(unpack(v123_))
	local v126_ = getNormalizedScreenValues
	local v127_ = ControlBarDisplay.SIZE.FILL_LEVEL_BAR
	local v128_, v129_ = v126_(unpack(v127_))
	local v130_ = Overlay.new(self.hudAtlasPath, v120_ + v124_, v121_ + v125_, v128_, v129_)
	local v131_ = ControlBarDisplay.COLOR.FILL_LEVEL_BAR_BACKGROUND
	v130_:setColor(unpack(v131_))
	v130_:setUVs(v119_)
	local v132_ = HUDElement.new(v130_)
	v117_:addChild(v132_)
	local v133_ = Overlay.new(self.hudAtlasPath, v120_ + v124_, v121_ + v125_, v128_, v129_)
	local v134_ = HUDElement.new(v133_)
	v134_:setUVs(v119_)
	local v135_ = ControlBarDisplay.COLOR.FILL_LEVEL_BAR
	v134_:setColor(unpack(v135_))
	v132_:addChild(v134_)
	v116_.bar = v134_
	v116_.defaultUVs = table.clone(v119_)
	return v116_
end

-- Local values: added, j, fillLevelInformation
function ControlBarDisplay:addFillLevel(fillType, fillLevel, capacity, precision, maxReached)
	local v142_ = false
	for v143_ = 1, #self.fillLevelBuffer do
		local v144_ = self.fillLevelBuffer[v143_]
		if v144_.fillType == fillType then
			v144_.fillLevel = v144_.fillLevel + fillLevel
			v144_.capacity = v144_.capacity + capacity
			v144_.precision = precision
			v144_.maxReached = maxReached
			if self.fillLevelBufferAddIndex == v144_.addIndex then
				v142_ = true
			else
				v144_.addIndex = self.fillLevelBufferAddIndex
				self.fillLevelBufferNeedsSorting = true
				v142_ = true
			end
			break
		end
	end
	if not v142_ then
		local v145_ = self.fillLevelBuffer
		local v146_ = {
			["fillType"] = fillType,
			["fillLevel"] = fillLevel,
			["capacity"] = capacity,
			["precision"] = precision,
			["addIndex"] = self.fillLevelBufferAddIndex,
			["maxReached"] = maxReached
		}
		table.insert(v145_, v146_)
		self.fillLevelBufferNeedsSorting = true
	end
	self.fillLevelBufferAddIndex = self.fillLevelBufferAddIndex + 1
end

-- Local values: i, i, displayIndex, i, fillLevelControl
function ControlBarDisplay:updateFillLevelBuffers(vehicle)
	for v149_ = 1, #self.fillLevelControls do
		self.fillLevelControls[v149_].fillLevelPct = 0
		self.fillLevelControls[v149_].button:setVisible(false)
	end
	if vehicle ~= nil then
		for v150_ = 1, #self.fillLevelBuffer do
			self.fillLevelBuffer[v150_].fillLevel = 0
			self.fillLevelBuffer[v150_].capacity = 0
		end
		self.fillLevelBufferAddIndex = 0
		self.fillLevelBufferNeedsSorting = false
		vehicle:getFillLevelInformation(self)
		if self.fillLevelBufferNeedsSorting then
			table.sort(self.fillLevelBuffer, ControlBarDisplay.sortFillLevelBuffers)
		end
		self.buttonToggleSeeds = nil
		self.buttonShowFillLevel = nil
		local v151_ = 0
		for v152_ = 1, #self.fillLevelBuffer do
			if self.fillLevelBuffer[v152_].capacity ~= 0 then
				v151_ = v151_ + 1
				local v153_ = self.fillLevelControls[v151_]
				if v153_ ~= nil then
					self:updateFillLevelControl(v153_, self.fillLevelBuffer[v152_])
				end
			end
		end
	end
end

function ControlBarDisplay.sortFillLevelBuffers(a, b)
	return a.addIndex < b.addIndex
end

-- Local values: fillLevelPct, bar, fillType, iconFilename, button, fillTypeIndex
function ControlBarDisplay:updateFillLevelControl(fillLevelControl, fillLevelBuffer)
	local v159_ = fillLevelBuffer.fillLevel / fillLevelBuffer.capacity
	fillLevelControl.fillLevelPct = v159_
	local v160_ = fillLevelControl.bar.overlay
	v160_.uvs[5] = (fillLevelControl.defaultUVs[5] - fillLevelControl.defaultUVs[1]) * v159_ + fillLevelControl.defaultUVs[1]
	v160_.uvs[7] = (fillLevelControl.defaultUVs[7] - fillLevelControl.defaultUVs[3]) * v159_ + fillLevelControl.defaultUVs[3]
	v160_:setUVs(v160_.uvs)
	v160_:setScale(v159_ * self.uiScale, self.uiScale)
	local v161_ = g_fillTypeManager:getFillTypeByIndex(fillLevelBuffer.fillType)
	if v161_ ~= nil then
		local v162_ = v161_.hudOverlayFilename
		if v162_ ~= "" then
			fillLevelControl.button:setIcon(v162_)
		end
	end
	fillLevelControl.vehicle = nil
	local v163_ = fillLevelControl.button
	if self.sowingMachine == nil then
		self.buttonShowFillLevel = v163_
	else
		if self.sowingMachine:getSowingMachineSeedFillTypeIndex() == fillLevelBuffer.fillType then
			fillLevelControl.vehicle = self.sowingMachine
		end
		self.buttonToggleSeeds = v163_
	end
	v163_:setIsActive(fillLevelControl.vehicle ~= nil)
	v163_:setVisible(fillLevelBuffer.fillLevel > 0 and true or fillLevelControl.vehicle ~= nil)
end

function ControlBarDisplay.onChangeSeedCallback(fillLevelControl, x, y)
	if not g_sleepManager:getIsSleeping() then
		if fillLevelControl.vehicle ~= nil and not fillLevelControl.vehicle:getIsAIActive() then
			fillLevelControl.vehicle:changeSeedIndex(1)
		end
	end
end

-- Local values: currentVisibility, posX, posY, offsetX, offsetY
function ControlBarDisplay:setScale(uiScale)
	ControlBarDisplay:superClass().setScale(self, uiScale, uiScale)
	local v167_ = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local v168_, v169_ = ControlBarDisplay.getBackgroundPosition(uiScale, self:getWidth())
	self:setPosition(v168_, v169_)
	local v170_ = getNormalizedScreenValues
	local v171_ = ControlBarDisplay.POSITION.GAMEPAD_OFFSET
	local v172_, v173_ = v170_(unpack(v171_))
	self.positionTouch = { v168_ + v172_ * uiScale, v169_ + v173_ * uiScale }
	self.positionGamepad = { v168_, v169_ }
	self:storeOriginalPosition()
	self:setVisible(v167_, false)
	if self.lastPositionState == ControlBarDisplay.STATE_TOUCH then
		self:setPosition(self.positionTouch[1], self.positionTouch[2])
	end
end

-- Local values: offX, offY
function ControlBarDisplay.getBackgroundPosition(scale, width)
	local v175_ = getNormalizedScreenValues
	local v176_ = ControlBarDisplay.POSITION.BACKGROUND
	local v177_, v178_ = v175_(unpack(v176_))
	return v177_ * scale, v178_ * scale
end
function ControlBarDisplay.createBackground()
	local v179_ = getNormalizedScreenValues
	local v180_ = ControlBarDisplay.SIZE.BACKGROUND
	local v181_, v182_ = v179_(unpack(v180_))
	local v183_, v184_ = ControlBarDisplay.getBackgroundPosition(1, v181_)
	return Overlay.new(nil, v183_, v184_, v181_, v182_)
end
ControlBarDisplay.SIZE = {
	["BACKGROUND"] = { 736, 106 },
	["ICON"] = { 84, 84 },
	["FILL_LEVEL_ICON"] = { 75, 75 },
	["FILL_LEVEL_BAR"] = { 82, 21 },
	["ENTER_CABIN_GLYPH"] = { 80, 80 }
}
ControlBarDisplay.POSITION = {
	["BACKGROUND"] = { 320, 50 },
	["BUTTON_START"] = { 0, 0 },
	["BUTTON_OFFSET"] = { 20, 0 },
	["FILL_LEVEL_ICON_OFFSET"] = { 13, 25 },
	["FILL_LEVEL_BAR_OFFSET"] = { 11, 7 },
	["GAMEPAD_OFFSET"] = { 515, 0 }
}
ControlBarDisplay.COLOR = {
	["FILL_LEVEL_BAR"] = {
		0.3763,
		0.6038,
		0.0782,
		1
	},
	["FILL_LEVEL_BAR_BACKGROUND"] = {
		0.172549,
		0.172549,
		0.172549,
		1
	},
	["BUTTON"] = {
		1,
		1,
		1,
		1
	},
	["BUTTON_ACTIVE"] = {
		0.3763,
		0.6038,
		0.0782,
		1
	}
}
ControlBarDisplay.UV = {
	["FILL_LEVEL_BAR"] = {
		480,
		21,
		82,
		21
	},
	["DETACH"] = {
		480,
		0,
		96,
		96
	},
	["TURN_ON"] = {
		384,
		0,
		96,
		96
	},
	["AUTO_LOAD"] = {
		96,
		0,
		96,
		96
	},
	["LOAD_LOG"] = {
		192,
		0,
		96,
		96
	},
	["LOADER_LOWER"] = {
		192,
		96,
		96,
		96
	},
	["LOADER_LIFT"] = {
		288,
		96,
		96,
		96
	},
	["WOOD_SAW"] = {
		384,
		96,
		96,
		96
	},
	["AI"] = {
		288,
		0,
		96,
		96
	},
	["LEAVE_VEHICLE"] = {
		672,
		0,
		96,
		96
	},
	["ENTER_VEHICLE"] = {
		576,
		0,
		96,
		96
	},
	["ENTER_HORSE"] = {
		672,
		96,
		96,
		96
	},
	["LEAVE_HORSE"] = {
		768,
		96,
		96,
		96
	},
	["ACTIVATABLE_OBJECT"] = {
		0,
		0,
		96,
		96
	},
	["UNLOAD_FORK"] = {
		96,
		288,
		96,
		96
	}
}
if v1_ ~= nil then
	local v185_ = ControlBarDisplay.new(v1_.hud, v1_.hudAtlasPath, v1_.controlHudAtlasPath)
	v185_:setScale(v1_.uiScale)
	v185_:setVehicle(v1_.vehicle)
	v185_:setPlayer(v1_.player)
	for v186_, v187_ in ipairs(g_currentMission.hud.displayComponents) do
		if v187_ == g_currentMission.hud.controlBarDisplay then
			g_currentMission.hud.displayComponents[v186_] = v185_
			break
		end
	end
	g_currentMission.hud.controlBarDisplay = v185_
	Logging.info("Reloaded")
end
