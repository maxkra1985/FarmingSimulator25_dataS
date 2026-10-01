local data = nil
if ControlBarDisplay ~= nil then
	local old = g_currentMission.hud.controlBarDisplay
	data = {}
	data.vehicle = old.vehicle
	data.player = old.player
	data.hud = old.hud
	data.uiScale = old.uiScale
	data.hudAtlasPath = old.hudAtlasPath
	data.controlHudAtlasPath = old.controlHudAtlasPath
	old:delete()
end
ControlBarDisplay = {}
ControlBarDisplay.MOVE_ANIMATION_DURATION = 500
ControlBarDisplay.STATE_TOUCH = 0
ControlBarDisplay.STATE_CONTROLLER = 1
ControlBarDisplay.STATE_AI_TOUCH = 2
local ControlBarDisplay_mt = Class(ControlBarDisplay, HUDDisplayElement)
function ControlBarDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
	local backgroundOverlay = ControlBarDisplay.createBackground()
	local self = ControlBarDisplay:superClass().new(backgroundOverlay, nil, ControlBarDisplay_mt)
	self.hud = hud
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.controlHudAtlasPath = controlHudAtlasPath
	self.vehicle = nil
	self.lastChildVehicleHash = ""
	self.sowingMachine = nil
	self.player = nil
	self.hudElements = {}
	self.buttons = {}
	self.controlButtons = {}
	self.inputGlyphs = {}
	self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	self.lastAIState = false
	self.lastGyroscopeSteeringState = false
	self.fillLevelBuffer = {}
	self.fillLevelBufferAddIndex = 0
	self.fillLevelBufferNeedsSorting = false
	self.fillLevelControls = {}
	self.vehicleControls = {}
	self.vehicleControls.attach = { availableFunc = "getShowAttachControlBarAction", accessibleFunc = "getAttachControlBarActionAccessible", actionFunc = "detachAttachedImplement", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, controlButton = nil, uvs = ControlBarDisplay.UV.DETACH, prio = 3, inputAction = InputAction.ATTACH, name = "attach" }
	self.vehicleControls.turnOn = { allowedFunc = "getAreControlledActionsAllowed", availableFunc = "getAreControlledActionsAvailable", accessibleFunc = "getAreControlledActionsAccessible", getIconsFunc = "getControlledActionIcons", actionFunc = "playControlledActions", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, directionFunc = "getActionControllerDirection", controlButton = nil, uvs = ControlBarDisplay.UV.TURN_ON, iconColor_pos = ControlBarDisplay.COLOR.BUTTON, iconColor_neg = ControlBarDisplay.COLOR.BUTTON_ACTIVE, prio = 4, inputAction = InputAction.VEHICLE_ACTION_CONTROL, name = "turnOn" }
	self.vehicleControls.ai = { availableFunc = "getCanToggleAIVehicle", accessibleFunc = "getShowAIToggleActionEvent", actionFunc = "toggleAIVehicle", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, directionFunc = "getIsAIActive", controlButton = nil, uvs = ControlBarDisplay.UV.AI, iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE, iconColor_neg = ControlBarDisplay.COLOR.BUTTON, prio = 5, inputAction = InputAction.TOGGLE_AI, name = "ai" }
	self.vehicleControls.leave = { availableFunc = "getCanLeaveVehicle", accessibleFunc = "getIsLeavingAllowed", actionFunc = "doLeaveVehicle", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, controlButton = nil, uvs = ControlBarDisplay.UV.LEAVE_VEHICLE, iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE, iconColor_neg = ControlBarDisplay.COLOR.BUTTON, prio = 6, inputAction = InputAction.ENTER, name = "leave" }
	self.vehicleControls.unloadFork = { availableFunc = "getCanUnloadFork", accessibleFunc = "getIsForkUnloadingAllowed", actionFunc = "doUnloadFork", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, controlButton = nil, uvs = ControlBarDisplay.UV.UNLOAD_FORK, iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE, iconColor_neg = ControlBarDisplay.COLOR.BUTTON, prio = 7, inputAction = InputAction.UNLOAD_FORK, name = "unloadFork" }
	self.vehicleControls.leave_horse = { availableFunc = "getCanLeaveRideable", accessibleFunc = "getIsLeavingAllowed", actionFunc = "doLeaveVehicle", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, controlButton = nil, uvs = ControlBarDisplay.UV.LEAVE_HORSE, iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE, iconColor_neg = ControlBarDisplay.COLOR.BUTTON, prio = 6, inputAction = InputAction.ENTER, name = "leave_horse" }
	self.playerControls = {}
	self.playerControls.enter_vehicle = { availableFunc = "getCanEnterVehicle", actionFunc = "onInputEnter", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, controlButton = nil, uvs = ControlBarDisplay.UV.ENTER_VEHICLE, iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE, iconColor_neg = ControlBarDisplay.COLOR.BUTTON, prio = 7, inputAction = InputAction.ENTER, name = "enter_vehicle" }
	self.playerControls.enter_horse = { availableFunc = "getCanEnterRideable", actionFunc = "onInputEnter", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, controlButton = nil, uvs = ControlBarDisplay.UV.ENTER_HORSE, iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE, iconColor_neg = ControlBarDisplay.COLOR.BUTTON, prio = 8, inputAction = InputAction.ENTER, name = "ride_horse" }
	self.playerControls.ride = { availableFunc = "getIsRideStateAvailable", actionFunc = "activateRideState", triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, controlButton = nil, uvs = ControlBarDisplay.UV.ENTER_HORSE, iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE, iconColor_neg = ControlBarDisplay.COLOR.BUTTON, prio = 9, inputAction = InputAction.ENTER, name = "ride_horse" }
	self.customControls = {}
	self.customControls.activateObject = { availableFunc = self.getIsActivatableObjectAvailable, actionFunc = self.triggerActivatableObject, triggerType = TouchHandler.TRIGGER_UP, fullTapNeeded = true, controlButton = nil, uvs = ControlBarDisplay.UV.ACTIVATABLE_OBJECT, iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE, iconColor_neg = ControlBarDisplay.COLOR.BUTTON, prio = 7, inputAction = InputAction.ACTIVATE_OBJECT, name = "activateObject" }
	self:createComponents()
	return self
end
function ControlBarDisplay:createComponents()
	self.buttonStartPos = { getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.BUTTON_START)) }
	self.buttonOffsetX = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.BUTTON_OFFSET))
	self.fillLevelIconSizeX, self.fillLevelIconSizeY = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.FILL_LEVEL_ICON))
	self.fillLevelIconOffsetX, self.fillLevelIconOffsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.FILL_LEVEL_ICON_OFFSET))
	self.hudControls = {}
	table.insert(self.hudControls, self:addFillLevelControl())
	table.insert(self.hudControls, self:addFillLevelControl())
	local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.ICON))
	for _, control in pairs(self.vehicleControls) do
		local button = HUDButtonElement.new(self.hud, 0, 0)
		button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
		button:setAction(control.inputAction)
		function button.buttonCallback()
			if g_sleepManager:getIsSleeping() then
				return
			else
				local vehicle = control.vehicle
				if vehicle ~= nil then
					if control.allowedFunc ~= nil then
						local allowed, warning = vehicle[control.allowedFunc](vehicle)
						if not allowed then
							g_currentMission:showBlinkingWarning(warning, 2500)
							return
						end
					end
					vehicle[control.actionFunc](vehicle)
				end
			end
		end
		button:addTouchHandler(button.buttonCallback, self)
		self:addChild(button)
		control.button = button
		table.insert(self.hudControls, control)
	end
	for _, control in pairs(self.playerControls) do
		local button = HUDButtonElement.new(self.hud, 0, 0)
		button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
		button:setAction(control.inputAction)
		function button.buttonCallback()
			if g_sleepManager:getIsSleeping() then
				return
			else
				local player = self.player
				if player ~= nil then
					player[control.actionFunc](player)
				end
			end
		end
		button:addTouchHandler(button.buttonCallback, self)
		self:addChild(button)
		control.button = button
		table.insert(self.hudControls, control)
	end
	for _, control in pairs(self.customControls) do
		local button = HUDButtonElement.new(self.hud, 0, 0)
		button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
		button:setAction(control.inputAction)
		function button.buttonCallback()
			control.actionFunc()
		end
		button:addTouchHandler(button.buttonCallback, self)
		control.button = button
		self:addChild(button)
		table.insert(self.hudControls, control)
	end
	self.buttons = {}
	self.controlButtons = {}
	self.hudElements = {}
	local posX, posY = self:getPosition()
	local offsetX, offsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.GAMEPAD_OFFSET))
	self.positionTouch = { posX + offsetX, posY + offsetY }
	self.positionGamepad = { posX, posY }
end
function ControlBarDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
	self:updatePositionState()
	self:updateFillLevelBuffers(vehicle)
	self:updateButtons()
	if self.buttonToggleSeeds ~= nil then
		local glyphOverlay = self.buttonToggleSeeds.glyphElement.overlay
		function glyphOverlay.getIsVisible()
			return glyphOverlay.visible and self.sowingMachine ~= nil and 1 < #self.sowingMachine.spec_sowingMachine.seeds
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
function ControlBarDisplay:updateButtons()
	local currentVehicle = self.vehicle
	self.sowingMachine = nil
	if self.vehicle ~= nil then
		for _, childVehicle in ipairs(self.vehicle.childVehicles) do
			if childVehicle.spec_sowingMachine ~= nil then
				self.sowingMachine = childVehicle
				break
			end
		end
	end
	self:updateFillLevelBuffers(currentVehicle)
	for name, vehicleControl in pairs(self.vehicleControls) do
		local vehicle = nil
		local isAvailable = false
		local isAccessible = false
		if currentVehicle ~= nil then
			local availableFunc = currentVehicle[vehicleControl.availableFunc]
			if availableFunc ~= nil then
				isAvailable = availableFunc(currentVehicle)
				if isAvailable then
					vehicle = currentVehicle
				elseif vehicleControl.useAttachables then
					if currentVehicle.getAttachedImplements ~= nil then
						for _, implement in ipairs(currentVehicle:getAttachedImplements()) do
							availableFunc = implement.object[vehicleControl.availableFunc]
							if availableFunc == nil then
								continue
							end
							isAvailable = availableFunc(implement.object)
							vehicle = implement.object
						end
					end
				end
			end
		end
		if vehicle ~= nil then
			local accessibleFunc = vehicle[vehicleControl.accessibleFunc]
			if accessibleFunc ~= nil then
				isAccessible = accessibleFunc(vehicle)
			end
			local iconsChanged = false
			if vehicleControl.getIconsFunc ~= nil then
				local getIconsFunc = vehicle[vehicleControl.getIconsFunc]
				if getIconsFunc ~= nil then
					local uvNegStr, uvPosStr, allowColorChange = getIconsFunc(vehicle)
					local uvs_neg = ControlBarDisplay.UV[uvNegStr]
					local uvs_pos = ControlBarDisplay.UV[uvPosStr]
					local iconColor_neg = ControlBarDisplay.COLOR.BUTTON_ACTIVE
					local iconColor_pos = ControlBarDisplay.COLOR.BUTTON
					if not allowColorChange then
						iconColor_neg = ControlBarDisplay.COLOR.BUTTON
					end
					if uvs_pos ~= vehicleControl.uvs_pos or uvs_neg ~= vehicleControl.uvs_neg then
						vehicleControl.uvs_pos = uvs_pos
						vehicleControl.uvs_neg = uvs_neg
						iconsChanged = true
					end
					if iconColor_pos ~= vehicleControl.iconColor_pos or iconColor_neg ~= vehicleControl.iconColor_neg then
						vehicleControl.iconColor_pos = iconColor_pos
						vehicleControl.iconColor_neg = iconColor_neg
						iconsChanged = true
					end
				end
			end
			if vehicleControl.directionFunc ~= nil then
				local directionFunc = vehicle[vehicleControl.directionFunc]
				if directionFunc ~= nil then
					local direction = directionFunc(vehicle)
					if type(direction) == "boolean" then
						direction = direction and 1 or -1
					end
					if direction ~= vehicleControl.lastDirection or iconsChanged then
						local button = vehicleControl.button
						local uvs = direction == 1 and vehicleControl.uvs_pos or vehicleControl.uvs_neg
						if uvs ~= nil and uvs ~= vehicleControl.uvs then
							button:setIcon(nil, nil, nil, GuiUtils.getUVs(uvs), nil, nil)
							vehicleControl.uvs = uvs
						end
						local color = direction == 1 and vehicleControl.iconColor_pos or vehicleControl.iconColor_neg
						if color ~= nil and color ~= vehicleControl.color then
							button:setIcon(nil, nil, nil, nil, nil, nil, color)
							vehicleControl.color = color
						end
						vehicleControl.lastDirection = direction
					end
				end
			end
		end
		vehicleControl.vehicle = vehicle
		vehicleControl.button:setVisible(isAvailable)
		vehicleControl.button:setDisabled(not isAccessible or g_gui:getIsGuiVisible())
	end
	local player = self.player
	for name, playerControl in pairs(self.playerControls) do
		local isAvailable = false
		if player ~= nil then
			local availableFunc = player[playerControl.availableFunc]
			if availableFunc ~= nil then
				isAvailable = availableFunc(player)
			end
		end
		playerControl.button:setVisible(isAvailable)
		playerControl.button:setDisabled(g_gui:getIsGuiVisible())
	end
	for name, control in pairs(self.customControls) do
		local isAvailable = control.availableFunc(self)
		control.button:setVisible(isAvailable)
		control.button:setDisabled(g_gui:getIsGuiVisible())
	end
end
function ControlBarDisplay:updateButtonPositions()
	local posX, posY = self:getPosition()
	local offsetX = self.buttonOffsetX * self.uiScale
	table.sort(self.hudControls, function(a, b)
		return a.prio < b.prio
	end)
	for _, control in ipairs(self.hudControls) do
		if control.button:getVisible() then
			control.button:setPosition(posX, posY)
			posX = posX + control.button:getWidth() + offsetX
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
function ControlBarDisplay:triggerActivatableObject()
	local object = g_currentMission.activatableObjectsSystem:getActivatable()
	if object ~= nil then
		object:run()
	end
end
function ControlBarDisplay:updatePositionState(force)
	if Platform.hasTouchSliders and (self.player ~= nil and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD) then
		self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
		return
	end
	if not not Platform.hasTouchSliders then
		local isControllerInput = true
		if self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
			isControllerInput = self.lastGyroscopeSteeringState
		end
	end
	if isControllerInput then
		self:setPositionState(ControlBarDisplay.STATE_CONTROLLER, force)
	else
		self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
	end
end
function ControlBarDisplay:setPositionState(state, force)
	if not Platform.hasTouchSliders then
		return
	else
		if state ~= self.lastPositionState then
			local startX, startY = self:getPosition()
			local targetX = self.positionGamepad[1]
			local targetY = self.positionGamepad[2]
			local speed = ControlBarDisplay.MOVE_ANIMATION_DURATION
			if state == ControlBarDisplay.STATE_TOUCH then
				targetX = self.positionTouch[1]
				targetY = self.positionTouch[2]
				speed = ControlBarDisplay.MOVE_ANIMATION_DURATION / 5
			end
			if force then
				speed = 0.01
			end
			local sequence = TweenSequence.new(self)
			sequence:insertTween(MultiValueTween.new(self.setPosition, { startX, startY }, { targetX, targetY }, speed), 0)
			sequence:start()
			self.animation = sequence
			self.lastPositionState = state
		end
	end
end
function ControlBarDisplay:addFillLevelControl()
	local fillLevelControl = {}
	local button = HUDButtonElement.new(self.hud, 0, 0)
	button:setIcon(nil, self.fillLevelIconSizeX, self.fillLevelIconSizeY, Overlay.DEFAULT_UVS, self.fillLevelIconOffsetX, self.fillLevelIconOffsetY)
	button:setAction(InputAction.TOGGLE_SEEDS)
	button:addTouchHandler(ControlBarDisplay.onChangeSeedCallback, fillLevelControl)
	self:addChild(button)
	fillLevelControl.button = button
	fillLevelControl.prio = #self.fillLevelControls + 1
	table.insert(self.fillLevelControls, fillLevelControl)
	local uvs = GuiUtils.getUVs(ControlBarDisplay.UV.FILL_LEVEL_BAR)
	local posX, posY = button:getPosition()
	local offsetX, offsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.FILL_LEVEL_BAR_OFFSET))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.FILL_LEVEL_BAR))
	local backgroundOverlay = Overlay.new(self.hudAtlasPath, posX + offsetX, posY + offsetY, sizeX, sizeY)
	backgroundOverlay:setColor(unpack(ControlBarDisplay.COLOR.FILL_LEVEL_BAR_BACKGROUND))
	backgroundOverlay:setUVs(uvs)
	local fillLevelBarBackground = HUDElement.new(backgroundOverlay)
	button:addChild(fillLevelBarBackground)
	local fillLevelBarOverlay = Overlay.new(self.hudAtlasPath, posX + offsetX, posY + offsetY, sizeX, sizeY)
	local fillLevelBar = HUDElement.new(fillLevelBarOverlay)
	fillLevelBar:setUVs(uvs)
	fillLevelBar:setColor(unpack(ControlBarDisplay.COLOR.FILL_LEVEL_BAR))
	fillLevelBarBackground:addChild(fillLevelBar)
	fillLevelControl.bar = fillLevelBar
	fillLevelControl.defaultUVs = table.clone(uvs)
	return fillLevelControl
end
function ControlBarDisplay:addFillLevel(fillType, fillLevel, capacity, precision, maxReached)
	local added = false
	for j = 1, #self.fillLevelBuffer do
		local fillLevelInformation = self.fillLevelBuffer[j]
		if fillLevelInformation.fillType == fillType then
			fillLevelInformation.fillLevel = fillLevelInformation.fillLevel + fillLevel
			fillLevelInformation.capacity = fillLevelInformation.capacity + capacity
			fillLevelInformation.precision = precision
			fillLevelInformation.maxReached = maxReached
			if self.fillLevelBufferAddIndex ~= fillLevelInformation.addIndex then
				fillLevelInformation.addIndex = self.fillLevelBufferAddIndex
				self.fillLevelBufferNeedsSorting = true
				added = true
				break
			else
				break
			end
		end
	end
	if not added then
		table.insert(self.fillLevelBuffer, { fillType = fillType, fillLevel = fillLevel, capacity = capacity, precision = precision, maxReached = maxReached, addIndex = self.fillLevelBufferAddIndex })
		self.fillLevelBufferNeedsSorting = true
	end
	self.fillLevelBufferAddIndex = self.fillLevelBufferAddIndex + 1
end
function ControlBarDisplay:updateFillLevelBuffers(vehicle)
	for i = 1, #self.fillLevelControls do
		self.fillLevelControls[i].fillLevelPct = 0
		self.fillLevelControls[i].button:setVisible(false)
	end
	if vehicle == nil then
		return
	else
		for i = 1, #self.fillLevelBuffer do
			self.fillLevelBuffer[i].fillLevel = 0
			self.fillLevelBuffer[i].capacity = 0
		end
		self.fillLevelBufferAddIndex = 0
		self.fillLevelBufferNeedsSorting = false
		vehicle:getFillLevelInformation(self)
		if self.fillLevelBufferNeedsSorting then
			table.sort(self.fillLevelBuffer, ControlBarDisplay.sortFillLevelBuffers)
		end
		self.buttonToggleSeeds = nil
		self.buttonShowFillLevel = nil
		local displayIndex = 0
		for i = 1, #self.fillLevelBuffer do
			if self.fillLevelBuffer[i].capacity == 0 then
				continue
			end
			displayIndex = displayIndex + 1
			local fillLevelControl = self.fillLevelControls[displayIndex]
			if fillLevelControl == nil then
				continue
			end
			self:updateFillLevelControl(fillLevelControl, self.fillLevelBuffer[i])
		end
	end
end
function ControlBarDisplay.sortFillLevelBuffers(a, b)
	return a.addIndex < b.addIndex
end
function ControlBarDisplay:updateFillLevelControl(fillLevelControl, fillLevelBuffer)
	local fillLevelPct = fillLevelBuffer.fillLevel / fillLevelBuffer.capacity
	fillLevelControl.fillLevelPct = fillLevelPct
	local bar = fillLevelControl.bar.overlay
	bar.uvs[5] = (fillLevelControl.defaultUVs[5] - fillLevelControl.defaultUVs[1]) * fillLevelPct + fillLevelControl.defaultUVs[1]
	bar.uvs[7] = (fillLevelControl.defaultUVs[7] - fillLevelControl.defaultUVs[3]) * fillLevelPct + fillLevelControl.defaultUVs[3]
	bar:setUVs(bar.uvs)
	bar:setScale(fillLevelPct * self.uiScale, self.uiScale)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillLevelBuffer.fillType)
	if fillType ~= nil then
		local iconFilename = fillType.hudOverlayFilename
		if iconFilename ~= "" then
			fillLevelControl.button:setIcon(iconFilename)
		end
	end
	fillLevelControl.vehicle = nil
	local button = fillLevelControl.button
	if self.sowingMachine ~= nil then
		local fillTypeIndex = self.sowingMachine:getSowingMachineSeedFillTypeIndex()
		if fillTypeIndex == fillLevelBuffer.fillType then
			fillLevelControl.vehicle = self.sowingMachine
		end
		self.buttonToggleSeeds = button
	else
		self.buttonShowFillLevel = button
	end
	button:setIsActive(fillLevelControl.vehicle ~= nil)
	button:setVisible(0 < fillLevelBuffer.fillLevel or fillLevelControl.vehicle ~= nil)
end
function ControlBarDisplay.onChangeSeedCallback(fillLevelControl, x, y)
	if g_sleepManager:getIsSleeping() then
		return
	else
		if fillLevelControl.vehicle ~= nil and not fillLevelControl.vehicle:getIsAIActive() then
			fillLevelControl.vehicle:changeSeedIndex(1)
		end
	end
end
function ControlBarDisplay:setScale(uiScale)
	ControlBarDisplay:superClass().setScale(self, uiScale, uiScale)
	local currentVisibility = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local posX, posY = ControlBarDisplay.getBackgroundPosition(uiScale, self:getWidth())
	self:setPosition(posX, posY)
	local offsetX, offsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.GAMEPAD_OFFSET))
	self.positionTouch = { posX + offsetX * uiScale, posY + offsetY * uiScale }
	self.positionGamepad = { posX, posY }
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
	if self.lastPositionState == ControlBarDisplay.STATE_TOUCH then
		self:setPosition(self.positionTouch[1], self.positionTouch[2])
	end
end
function ControlBarDisplay.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.BACKGROUND))
	return offX * scale, offY * scale
end
function ControlBarDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.BACKGROUND))
	local posX, posY = ControlBarDisplay.getBackgroundPosition(1, width)
	local overlay = Overlay.new(nil, posX, posY, width, height)
	return overlay
end
ControlBarDisplay.SIZE = { BACKGROUND = { 736, 106 }, ICON = { 84, 84 }, FILL_LEVEL_ICON = { 75, 75 }, FILL_LEVEL_BAR = { 82, 21 }, ENTER_CABIN_GLYPH = { 80, 80 } }
ControlBarDisplay.POSITION = { BACKGROUND = { 320, 50 }, BUTTON_START = { 0, 0 }, BUTTON_OFFSET = { 20, 0 }, FILL_LEVEL_ICON_OFFSET = { 13, 25 }, FILL_LEVEL_BAR_OFFSET = { 11, 7 }, GAMEPAD_OFFSET = { 515, 0 } }
ControlBarDisplay.COLOR = { FILL_LEVEL_BAR = { 0.3763, 0.6038, 0.0782, 1 }, FILL_LEVEL_BAR_BACKGROUND = { 0.172549, 0.172549, 0.172549, 1 }, BUTTON = { 1, 1, 1, 1 }, BUTTON_ACTIVE = { 0.3763, 0.6038, 0.0782, 1 } }
ControlBarDisplay.UV = { FILL_LEVEL_BAR = { 480, 21, 82, 21 }, DETACH = { 480, 0, 96, 96 }, TURN_ON = { 384, 0, 96, 96 }, AUTO_LOAD = { 96, 0, 96, 96 }, LOAD_LOG = { 192, 0, 96, 96 }, LOADER_LOWER = { 192, 96, 96, 96 }, LOADER_LIFT = { 288, 96, 96, 96 }, WOOD_SAW = { 384, 96, 96, 96 }, AI = { 288, 0, 96, 96 }, LEAVE_VEHICLE = { 672, 0, 96, 96 }, ENTER_VEHICLE = { 576, 0, 96, 96 }, ENTER_HORSE = { 672, 96, 96, 96 }, LEAVE_HORSE = { 768, 96, 96, 96 }, ACTIVATABLE_OBJECT = { 0, 0, 96, 96 }, UNLOAD_FORK = { 96, 288, 96, 96 } }
if data ~= nil then
	local controlBarDisplay = ControlBarDisplay.new(data.hud, data.hudAtlasPath, data.controlHudAtlasPath)
	controlBarDisplay:setScale(data.uiScale)
	controlBarDisplay:setVehicle(data.vehicle)
	controlBarDisplay:setPlayer(data.player)
	for k, elem in ipairs(g_currentMission.hud.displayComponents) do
		if elem == g_currentMission.hud.controlBarDisplay then
			g_currentMission.hud.displayComponents[k] = controlBarDisplay
			break
		end
	end
	g_currentMission.hud.controlBarDisplay = controlBarDisplay
	Logging.info("Reloaded")
end
