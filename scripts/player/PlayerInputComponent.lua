PlayerInputComponent = {}
local PlayerInputComponent_mt = Class(PlayerInputComponent)
PlayerInputComponent.INPUT_CONTEXT_NAME = "PLAYER"
PlayerInputComponent.INPUT_CONTEXT_NAME_ANIMAL_RIDING = "ANIMAL_LOAD_EMPTY"
PlayerInputComponent.DEBUG_GRAPH_BACKGROUND_COLOR = Color.fromPackedValue(2155905152)
function PlayerInputComponent.new(player)
	local self = setmetatable({}, PlayerInputComponent_mt)
	self.player = player
	self.locked = false
	self.enterActionId = nil
	self.radioActionId = nil
	self.toggleFlightActionId = nil
	self.upDownFlightActionId = nil
	self.moveRight = 0
	self.moveForward = 0
	self.lastMoveRight = 0
	self.lastMoveForward = 0
	self.worldDirectionX = 0
	self.worldDirectionZ = 0
	self.lastWorldDirectionX = 0
	self.lastWorldDirectionZ = 0
	self.walkAxis = 0
	self.runAxis = 0
	self.flightAxis = 0
	self.jumpPower = 0
	self.crouchValue = 0
	self.lockedCrouchValue = 0
	self.lastWalkAxis = 0
	self.lastRunAxis = 0
	self.lastFlightAxis = 0
	self.lastJumpPower = 0
	self.lastCrouchValue = 0
	self.cameraRotationX = 0
	self.cameraRotationY = 0
	self.hasMovementInputs = false
	self.lastHasMovementInputs = false
	local flashlightName = g_i18n:getText("storeItem_flashlight")
	self.turnOnFlashlightText = string.format(g_i18n:getText("action_turnOnOBJECT"), flashlightName)
	self.turnOffFlashlightText = string.format(g_i18n:getText("action_turnOffOBJECT"), flashlightName)
	return self
end
function PlayerInputComponent:onPlayerLoad()
	self.player.toggleFlightModeCommand.onEnabled:registerListener(function()
		g_inputBinding:setActionEventActive(self.toggleFlightActionId, true)
	end)
	self.player.toggleFlightModeCommand.onDisabled:registerListener(function()
		g_inputBinding:setActionEventActive(self.toggleFlightActionId, false)
		g_inputBinding:setActionEventActive(self.upDownFlightActionId, false)
	end)
end
function PlayerInputComponent:listenForBindingChanges()
	g_messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.onInputBindingsChanged, self)
end
function PlayerInputComponent:onInputBindingsChanged()
	self:unregisterActionEvents()
	self:registerActionEvents()
end
function PlayerInputComponent:stopListeningForBindingChanges()
	g_messageCenter:unsubscribe(MessageType.INPUT_BINDINGS_CHANGED, self)
end
function PlayerInputComponent:addPauseListeners(isControlling)
	if not isControlling then
		return
	else
		local mission = g_currentMission
		if mission ~= nil then
			mission:addPauseListeners(self, self.onGamePaused)
		end
	end
end
function PlayerInputComponent:registerActionEvents()
	if not self.player.isOwner then
		return
	else
		g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
		self:registerGlobalPlayerActionEvents()
		local _ = nil
		local eventId = nil
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_SIDE_PLAYER, self, self.onInputMoveSide, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_FORWARD_PLAYER, self, self.onInputMoveForward, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER, self, self.onInputLookLeftRight, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_PLAYER, self, self.onInputLookUpDown, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.CAMERA_ZOOM_IN_OUT, self, self.onInputZoomInOut, false, true, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_RUN, self, self.onInputRun, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, self.upDownFlightActionId = g_inputBinding:registerActionEvent(InputAction.DEBUG_PLAYER_UP_DOWN, self, self.onInputChangeAltitude, false, false, true, false, nil, true)
		g_inputBinding:setActionEventTextVisibility(self.upDownFlightActionId, false)
		_, self.toggleFlightActionId = g_inputBinding:registerActionEvent(InputAction.DEBUG_PLAYER_ENABLE, self, self.onInputToggleFlightMode, true, false, false, false, nil, true)
		g_inputBinding:setActionEventTextVisibility(self.toggleFlightActionId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.JUMP, self, self.onInputJump, false, true, false, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.CROUCH, self, self.onInputCrouch, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, self.toggleCameraId = g_inputBinding:registerActionEvent(InputAction.CAMERA_SWITCH, self, self.onInputSwitchCamera, false, true, false, true, nil, true)
		g_inputBinding:setActionEventActive(self.toggleCameraId, self:getCanToggleCamera())
		_, eventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_HANDTOOL, self, self.onInputToggleHandTool, false, true, false, true, nil, true)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.CYCLE_HANDTOOL, self, self.onInputCycleHandTool, false, true, false, true, nil, true)
		_, self.enterActionId = g_inputBinding:registerActionEvent(InputAction.ENTER, self, self.onInputEnter, false, true, false, false, nil, true)
		_, self.toggleFlashlightId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_LIGHTS_FPS, self, self.onInputToggleFlashlight, false, true, false, true, nil, true)
		g_inputBinding:setActionEventText(self.toggleFlashlightId, g_i18n:getText("input_TOGGLE_LIGHTS_FPS"))
		g_inputBinding:endActionEventsModification()
		if g_touchHandler ~= nil then
			self.touchListenerPinch = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_PINCH, PlayerInputComponent.touchEventZoomInOut, self)
			self.touchListenerY = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_Y, PlayerInputComponent.touchEventLookUpDown, self)
			self.touchListenerX = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_X, PlayerInputComponent.touchEventLookLeftRight, self)
			self.touchListenerDoubleTab = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_DOUBLE_TAP, PlayerInputComponent.touchEventCameraSwitch, self)
		end
		self:registerPauseActionEvents()
		local targeter = self.player.targeter
		targeter:addTargetType(PlayerInputComponent, CollisionFlag.ANIMAL + CollisionFlag.VEHICLE + CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT, 0.5, 3)
	end
end
function PlayerInputComponent:registerPauseActionEvents()
	if not self.player.isOwner then
		return
	else
		g_inputBinding:beginActionEventsModification(BaseMission.INPUT_CONTEXT_PAUSE)
		local _ = nil
		local eventId = nil
		if GS_IS_CONSOLE_VERSION then
			_, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onInputConsoleAcceptPause, false, true, false, true)
			g_inputBinding:setActionEventTextVisibility(eventId, false)
		end
		_, eventId = g_inputBinding:registerActionEvent(InputAction.MENU, self, self.onInputToggleMenu, false, true, false, true)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.PAUSE, self, self.onInputPause, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, true)
		g_inputBinding:setActionEventText(eventId, g_i18n:getText("ui_unpause"))
		g_inputBinding:endActionEventsModification()
	end
end
function PlayerInputComponent:registerGlobalPlayerActionEvents(context)
	if not self.player.isOwner then
		return
	else
		local inputBinding = g_inputBinding
		local mission = g_currentMission
		context = context or inputBinding:getContextName()
		local oldContext = inputBinding:getContextName()
		if oldContext ~= context then
			inputBinding:beginActionEventsModification(context)
		end
		local _, eventId = inputBinding:registerActionEvent(InputAction.MENU, self, self.onInputToggleMenu, false, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.PAUSE, self, self.onInputPause, false, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, self, self.onInputToggleHelpText, false, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onInputSwitchVehicle, false, true, false, true, 1)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onInputSwitchVehicle, false, true, false, true, -1)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.TOGGLE_STORE, self, self.onInputToggleStore, false, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.TOGGLE_MAP, self, self.onInputToggleMap, false, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.TOGGLE_HELP, self, self.onInputToggleHelp, false, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.INCREASE_TIMESCALE, self, self.onInputChangeTimescale, false, true, false, true, 1)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.DECREASE_TIMESCALE, self, self.onInputChangeTimescale, false, true, false, true, -1)
		inputBinding:setActionEventTextVisibility(eventId, false)
		mission.hud:registerInput()
		if g_soundPlayer ~= nil then
			_, eventId = inputBinding:registerActionEvent(InputAction.RADIO_TOGGLE, self, self.onInputToggleRadio, false, true, false, false)
			inputBinding:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)
			self.radioActionId = eventId
			local radioEventsActive = mission:getIsRadioPlaying()
			local radioEvents = {}
			_, eventId = inputBinding:registerActionEvent(InputAction.RADIO_PREVIOUS_CHANNEL, g_soundPlayer, g_soundPlayer.previousChannel, false, true, false, radioEventsActive)
			inputBinding:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)
			table.insert(radioEvents, eventId)
			_, eventId = inputBinding:registerActionEvent(InputAction.RADIO_NEXT_CHANNEL, g_soundPlayer, g_soundPlayer.nextChannel, false, true, false, radioEventsActive)
			inputBinding:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)
			table.insert(radioEvents, eventId)
			_, eventId = inputBinding:registerActionEvent(InputAction.RADIO_NEXT_ITEM, g_soundPlayer, g_soundPlayer.nextItem, false, true, false, radioEventsActive)
			inputBinding:setActionEventTextVisibility(eventId, false)
			table.insert(radioEvents, eventId)
			_, eventId = inputBinding:registerActionEvent(InputAction.RADIO_PREVIOUS_ITEM, g_soundPlayer, g_soundPlayer.previousItem, false, true, false, radioEventsActive)
			inputBinding:setActionEventTextVisibility(eventId, false)
			table.insert(radioEvents, eventId)
			if context == PlayerInputComponent.INPUT_CONTEXT_NAME then
				self.playerRadioEvents = radioEvents
			end
			mission.radioEvents = radioEvents
		end
		if mission.missionDynamicInfo.isMultiplayer then
			inputBinding:registerActionEvent(InputAction.CHAT, self, self.onInputToggleChat, false, true, false, true)
		end
		if Platform.hasWardrobe then
			_, eventId = inputBinding:registerActionEvent(InputAction.TOGGLE_CHARACTER_CREATION, self, self.onInputToggleCharacterCreation, false, true, false, true)
			inputBinding:setActionEventTextVisibility(eventId, false)
		end
		_, eventId = inputBinding:registerActionEvent(InputAction.TOGGLE_CONSTRUCTION, self, self.onInputToggleConstructionScreen, false, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.TAKE_SCREENSHOT, self, self.onInputTakeScreenshot, false, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = inputBinding:registerActionEvent(InputAction.PUSH_TO_TALK, self, self.onPushToTalk, true, true, false, true)
		inputBinding:setActionEventTextVisibility(eventId, false)
		if oldContext ~= context then
			g_inputBinding:beginActionEventsModification(oldContext)
		end
	end
end
function PlayerInputComponent:unregisterActionEvents()
	if not self.player.isOwner then
		return
	else
		g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
		g_inputBinding:removeActionEventsByTarget(self)
		g_inputBinding:endActionEventsModification()
		if g_touchHandler ~= nil then
			g_touchHandler:removeGestureListener(self.touchListenerPinch)
			g_touchHandler:removeGestureListener(self.touchListenerY)
			g_touchHandler:removeGestureListener(self.touchListenerX)
		end
		self.player.targeter:removeTargetType(PlayerInputComponent)
		self.toggleFlightActionId = nil
		self.upDownFlightActionId = nil
		self.enterActionId = nil
	end
end
function PlayerInputComponent:makeCurrent()
	if not self.player.isOwner then
		return
	else
		g_inputBinding:setContext(PlayerInputComponent.INPUT_CONTEXT_NAME)
		if self.radioActionId ~= nil then
			g_inputBinding:setActionEventActive(self.radioActionId, false)
		end
		if self.playerRadioEvents ~= nil then
			g_currentMission.radioEvents = self.playerRadioEvents
		end
	end
end
function PlayerInputComponent:update(dt)
	if not self.player.isOwner then
		return
	end
	if g_inputBinding:getContextName() ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
		return
	end
	local mission = g_currentMission
	local accessHandler = mission.accessHandler
	local interactiveVehicle = mission.interactiveVehicleInRange
	local canPlayerEnterVehicle = false
	if interactiveVehicle ~= nil then
		canPlayerEnterVehicle = accessHandler:canPlayerAccess(interactiveVehicle, self.player)
	end
	self.rideablePlaceable = nil
	self.rideableCluster = nil
	local targetNode = self.player.targeter:getClosestTargetedNodeFromType(PlayerInputComponent)
	self.player.hudUpdater:setCurrentRaycastTarget(targetNode)
	if not canPlayerEnterVehicle and targetNode ~= nil then
		local husbandryId, animalId = getAnimalFromCollisionNode(targetNode)
		if husbandryId ~= nil and husbandryId ~= 0 then
			local clusterHusbandry = mission.husbandrySystem:getClusterHusbandryById(husbandryId)
			if clusterHusbandry ~= nil then
				local placeable = clusterHusbandry:getPlaceable()
				local cluster = clusterHusbandry:getClusterByAnimalId(animalId)
				if cluster ~= nil and (accessHandler:canFarmAccess(self.player.farmId, placeable) and placeable:getAnimalSupportsRiding(cluster.id)) then
					self.rideablePlaceable = placeable
					self.rideableCluster = cluster
				end
			end
		end
	end
	if not self.player.mover.isFlightActive then
		if canPlayerEnterVehicle or self.rideablePlaceable ~= nil then
			local text = nil
			if canPlayerEnterVehicle then
				text = interactiveVehicle:getInteractionHelp()
			else
				local rideableName = ""
				if self.rideableCluster.getName ~= nil then
					rideableName = self.rideableCluster:getName()
				end
				text = string.format(g_i18n:getText("action_rideAnimal"), rideableName)
			end
			g_inputBinding:setActionEventText(self.enterActionId, text)
			g_inputBinding:setActionEventActive(self.enterActionId, true)
		else
			g_inputBinding:setActionEventActive(self.enterActionId, false)
		end
	end
	if self.player.isFlashlightActive then
		g_inputBinding:setActionEventText(self.toggleFlashlightId, self.turnOffFlashlightText)
	else
		g_inputBinding:setActionEventText(self.toggleFlashlightId, self.turnOnFlashlightText)
	end
	g_inputBinding:setActionEventActive(self.toggleCameraId, self:getCanToggleCamera())
end
function PlayerInputComponent:resetState()
	self.lastMoveForward = self.moveForward
	self.lastMoveRight = self.moveRight
	self.lastWorldDirectionX = self.worldDirectionX
	self.lastWorldDirectionZ = self.worldDirectionZ
	self.lastHasMovementInputs = self.hasMovementInputs
	self.lastWalkAxis = self.walkAxis
	self.lastRunAxis = self.runAxis
	self.lastFlightAxis = self.flightAxis
	self.lastJumpPower = self.jumpPower
	self.lastCrouchValue = self.crouchValue
	self.moveForward = 0
	self.moveRight = 0
	self.worldDirectionX = 0
	self.worldDirectionZ = 0
	self.jumpPower = 0
	self.runAxis = 0
	self.walkAxis = 0
	self.flightAxis = 0
	if not self.locked then
		self.crouchValue = 0
	end
	self.cameraRotationX = 0
	self.cameraRotationY = 0
	self.hasMovementInputs = false
end
function PlayerInputComponent:lock()
	self.lockedCrouchValue = self.crouchValue
	self.locked = true
end
function PlayerInputComponent:unlock()
	self.locked = false
	if self.lockedCrouchValue ~= self.crouchValue then
		self:onInputCrouch(nil, self.lockedCrouchValue)
	end
end
function PlayerInputComponent:setMovementDirection(movementDirectionX, movementDirectionZ)
	self.hasMovementInputs = movementDirectionX ~= 0 or movementDirectionZ ~= 0
	self.worldDirectionX = movementDirectionX
	self.worldDirectionZ = movementDirectionZ
end
function PlayerInputComponent:calculateNormalisedMovementDirection()
	if self.moveRight ~= 0 or self.moveForward ~= 0 then
		return MathUtil.vector2Normalize(self.moveRight, self.moveForward)
	end
	return 0, 0
end
function PlayerInputComponent:getCanToggleCamera()
	if self.locked then
		return false
	elseif self.player:getCurrentVehicle() ~= nil then
		return false
	elseif self.player.camera:getIsSwitchingLocked() then
		return false
	else
		return true
	end
end
function PlayerInputComponent:calculateNormalisedWorldMovementDirection()
	local localDirectionX, localDirectionZ = self:calculateNormalisedMovementDirection()
	if (localDirectionX ~= 0 or localDirectionZ ~= 0) and self.player.camera.yawNode ~= nil then
		local worldDirectionX, _, worldDirectionZ = localDirectionToWorld(self.player.camera.yawNode, -localDirectionX, 0, localDirectionZ)
		return worldDirectionX, worldDirectionZ
	end
	return 0, 0
end
function PlayerInputComponent:onInputPause()
	local mission = g_currentMission
	if not mission.gameStarted then
		return
	else
		mission:setManualPause(not mission.manualPaused)
	end
end
function PlayerInputComponent:onInputConsoleAcceptPause()
	local mission = g_currentMission
	if mission.gameStarted and mission.manualPaused and GS_IS_CONSOLE_VERSION then
		mission:setManualPause(false)
	end
end
function PlayerInputComponent:onInputToggleHelpText()
	if self.locked then
		return
	else
		local isVisible = not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)
		g_gameSettings:setValue(GameSettings.SETTING.SHOW_HELP_MENU, isVisible)
	end
end
function PlayerInputComponent:onInputSwitchVehicle(_, _, directionValue)
	if self.locked then
		return
	else
		self.player:cycleCurrentVehicle(directionValue)
	end
end
function PlayerInputComponent:onInputToggleMenu()
	if self.locked then
		return
	end
	if g_sleepManager:getIsSleeping() then
		return
	end
	local mission = g_currentMission
	if mission.isSynchronizingWithPlayers then
		return
	else
		g_gui:changeScreen(nil, InGameMenu)
		if GS_IS_MOBILE_VERSION then
			g_inGameMenu:goToPage(g_inGameMenu.pageMain)
		end
	end
end
function PlayerInputComponent:onInputToggleStore()
	if self.locked then
		return
	end
	local mission = g_currentMission
	if mission.isSynchronizingWithPlayers then
		return
	elseif not mission.missionInfo:isa(FSCareerMissionInfo) then
		InfoDialog.show(g_i18n:getText("dialog_shopOnlyWorksInCareer"))
	elseif g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	elseif mission.isPlayerFrozen then
		return
	elseif self.player.farmId ~= FarmManager.SPECTATOR_FARM_ID then
		g_gui:changeScreen(nil, ShopMenu)
	else
		mission:showBlinkingWarning(g_i18n:getText("warning_joinFarmFirst"), 1500)
	end
end
function PlayerInputComponent:onInputToggleMap()
	if self.locked then
		return
	end
	local mission = g_currentMission
	if mission.isSynchronizingWithPlayers then
		return
	end
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
		return
	end
	g_gui:changeScreen(nil, InGameMenu)
	if Platform.isMobile then
		g_inGameMenu:goToPage(g_inGameMenu.pageMapMobile)
	else
		g_inGameMenu:goToPage(g_inGameMenu.pageMapOverview)
	end
end
function PlayerInputComponent:onInputToggleHelp()
	local mission = g_currentMission
	if mission.isSynchronizingWithPlayers then
		return
	else
		local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
		g_inGameMenu.pageHelpLine.closeMenuOneshot = true
		g_inGameMenu.blockNextPageNextEvent = true
		g_helpLineManager:openContextBasedHelp(x, y, z)
	end
end
function PlayerInputComponent:onInputToggleCharacterCreation()
	if self.locked then
		return
	end
	local mission = g_currentMission
	if mission.isSynchronizingWithPlayers then
		return
	elseif g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		g_gui:changeScreen(nil, WardrobeScreen)
	end
end
function PlayerInputComponent:onInputToggleConstructionScreen()
	if self.locked then
		return
	end
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
		return
	end
	local mission = g_currentMission
	if mission.isSynchronizingWithPlayers then
		return
	elseif self.player.farmId ~= FarmManager.SPECTATOR_FARM_ID then
		g_gui:changeScreen(nil, ConstructionScreen)
	else
		mission:showBlinkingWarning(g_i18n:getText("warning_joinFarmFirst"), 1500)
	end
end
function PlayerInputComponent:onInputTakeScreenshot()
	takeScreenshot()
end
function PlayerInputComponent:onPushToTalk(_, value)
	VoiceChatUtil.setIsPushToTalkPressed(value == 1)
end
function PlayerInputComponent:onInputToggleRadio()
	local isActive = g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE)
	g_gameSettings:setValue(GameSettings.SETTING.RADIO_IS_ACTIVE, not isActive)
end
function PlayerInputComponent:onInputChangeTimescale(_, _, indexStep)
	if self.locked then
		return
	else
		local mission = g_currentMission
		if not mission:getIsServer() and not mission.isMasterUser then
			return
		end
		local timeScaleIndex = Utils.getTimeScaleIndex(mission.missionInfo.timeScale)
		local newTimeScale = Utils.getTimeScaleFromIndex(timeScaleIndex + indexStep)
		if newTimeScale ~= nil then
			mission:setTimeScale(newTimeScale)
		end
	end
end
function PlayerInputComponent:onInputToggleChat(isActive)
	local mission = g_currentMission
	if mission.isSynchronizingWithPlayers then
		return
	else
		if isActive == nil or isActive then
			g_gui:showGui("ChatDialog")
			isActive = true
		else
			isActive = false
		end
		mission.hud:setChatDisplayVisible(isActive)
	end
end
function PlayerInputComponent:onInputToggleFlightMode(isActive)
	if self.locked then
		return
	else
		self.player.mover:toggleFlightActive()
		g_inputBinding:setActionEventActive(self.upDownFlightActionId, self.player.mover.isFlightActive)
	end
end
function PlayerInputComponent:onInputMoveSide(_, inputValue)
	if self.locked then
		return
	end
	if math.abs(inputValue) > g_gameSettings:getValue(GameSettings.SETTING.JOYSTICK_DEADZONE) then
		inputValue = math.clamp(inputValue, -1, 1)
		self.moveRight = self.moveRight + inputValue
		self.walkAxis = math.min(MathUtil.vector2Length(self.moveRight, self.moveForward), 1)
		local worldDirectionX, worldDirectionZ = self:calculateNormalisedWorldMovementDirection()
		self:setMovementDirection(worldDirectionX, worldDirectionZ)
	end
end
function PlayerInputComponent:onInputMoveForward(_, inputValue)
	if self.locked then
		return
	end
	if math.abs(inputValue) > g_gameSettings:getValue(GameSettings.SETTING.JOYSTICK_DEADZONE) then
		inputValue = math.clamp(inputValue, -1, 1)
		self.moveForward = self.moveForward - inputValue
		self.walkAxis = math.min(MathUtil.vector2Length(self.moveRight, self.moveForward), 1)
		local worldDirectionX, worldDirectionZ = self:calculateNormalisedWorldMovementDirection()
		self:setMovementDirection(worldDirectionX, worldDirectionZ)
	end
end
function PlayerInputComponent:touchEventLookUpDown(value)
	if g_inputBinding.currentContextName ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
		return
	else
		local factor = g_screenHeight * g_pixelSizeX * -75
		self:onInputLookUpDown(nil, value * factor, nil, nil, false)
	end
end
function PlayerInputComponent:touchEventZoomInOut(value)
	if g_inputBinding.currentContextName ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
		return
	else
		self:onInputZoomInOut(nil, -value * 75, nil, nil, false, nil, nil)
	end
end
function PlayerInputComponent:touchEventLookLeftRight(value)
	if g_inputBinding.currentContextName ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
		return
	else
		local factor = g_screenAspectRatio * 75
		self:onInputLookLeftRight(nil, value * factor, nil, nil, false)
	end
end
function PlayerInputComponent:touchEventCameraSwitch(value)
	if g_inputBinding.currentContextName ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
		return
	end
	if self:getCanToggleCamera() then
		self:onInputSwitchCamera()
	end
end
function PlayerInputComponent:onInputLookLeftRight(_, inputValue, _, _, isMouse)
	if self.locked then
		return
	end
	if math.abs(inputValue) <= g_gameSettings:getValue(GameSettings.SETTING.JOYSTICK_DEADZONE) then
		return
	end
	if isMouse then
		inputValue = inputValue * 0.001 * 16.666
	else
		inputValue = inputValue * 0.001 * g_currentDt
	end
	self.cameraRotationY = self.cameraRotationY + inputValue
	self.isMouseRotation = isMouse
end
function PlayerInputComponent:onInputLookUpDown(_, inputValue, _, _, isMouse)
	if self.locked then
		return
	end
	if math.abs(inputValue) <= g_gameSettings:getValue(GameSettings.SETTING.JOYSTICK_DEADZONE) then
		return
	end
	if g_gameSettings:getValue(GameSettings.SETTING.INVERT_Y_LOOK) then
		inputValue = inputValue * -1
	end
	if isMouse then
		inputValue = inputValue * 0.001 * 16.666
	else
		inputValue = inputValue * 0.001 * g_currentDt
	end
	self.cameraRotationX = self.cameraRotationX + inputValue
	self.isMouseRotation = isMouse
end
function PlayerInputComponent:onInputZoomInOut(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
	if self.locked then
		return
	else
		local offset = -0.2
		if isMouse then
			offset = offset * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
		end
		offset = offset * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_ZOOM_SENSITIVITY)
		self.player.camera:zoomSmoothly(offset * inputValue)
	end
end
function PlayerInputComponent:onInputRun(_, inputValue)
	if self.locked then
		return
	else
		inputValue = math.clamp(inputValue, 0, 1)
		self.runAxis = inputValue
	end
end
function PlayerInputComponent:onInputChangeAltitude(_, inputValue)
	if self.locked then
		return
	else
		inputValue = math.clamp(inputValue, -1, 1)
		self.flightAxis = inputValue
	end
end
function PlayerInputComponent:onInputJump(_, inputValue)
	if self.locked then
		return
	else
		inputValue = math.clamp(inputValue, 0, 1)
		self.jumpPower = inputValue
	end
end
function PlayerInputComponent:onInputCrouch(_, inputValue)
	inputValue = math.clamp(inputValue, 0, 1)
	if self.locked then
		self.lockedCrouchValue = inputValue
	else
		self.crouchValue = inputValue
	end
end
function PlayerInputComponent:onInputSwitchCamera()
	if self.locked then
		return
	end
	if self.player:getCurrentVehicle() == nil then
		self.player.camera:toggleThirdPersonMode()
	end
end
function PlayerInputComponent:onInputEnter()
	local mission = g_currentMission
	if g_time <= mission.lastInteractionTime + 200 then
		return
	elseif mission.interactiveVehicleInRange ~= nil then
		mission.interactiveVehicleInRange:interact(self.player)
	else
		if self.rideablePlaceable ~= nil then
			if self.rideablePlaceable:getAnimalCanBeRidden(self.rideableCluster.id) then
				g_inputBinding:setContext(PlayerInputComponent.INPUT_CONTEXT_NAME_ANIMAL_RIDING, true, false)
				mission:fadeScreen(1, 250, self.onFinishedRideBlending, self, { self.rideablePlaceable, self.rideableCluster, self.player })
				return
			end
			mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("shop_messageAnimalRideableLimitReached"))
		end
	end
end
function PlayerInputComponent:onFinishedRideBlending(arguments)
	local placeable = arguments[1]
	local cluster = arguments[2]
	local player = arguments[3]
	placeable:startRiding(cluster.id, player)
end
function PlayerInputComponent:onInputToggleFlashlight()
	self.player:toggleFlashlight()
end
function PlayerInputComponent:onInputCycleHandTool(_, inputValue)
	if self.locked then
		return
	end
	if self.player:getCurrentVehicle() ~= nil then
		return
	end
	if not self.player.mover.isSwimming then
		self.player:cycleHandTool(math.sign(inputValue))
	end
end
function PlayerInputComponent:onInputToggleHandTool(_, inputValue)
	if self.locked then
		return
	end
	if self.player:getCurrentVehicle() ~= nil then
		return
	end
	if not self.player.mover.isSwimming then
		self.player:toggleHandTool()
	end
end
function PlayerInputComponent:onGamePaused(isPaused)
	if isPaused then
		self:lock()
	else
		self:unlock()
	end
end
function PlayerInputComponent:debugDraw(x, y, textSize)
	y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Input", nil, true)
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Jump power: %.2f", self.lastJumpPower))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Crouch: %.2f", self.lastCrouchValue))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Has movement: %s", self.lastHasMovementInputs))
	y = self:debugDrawMovementGraphs(x, y, textSize)
	return y
end
function PlayerInputComponent:debugDrawMovementGraphs(x, y, textSize)
	local startX = x
	local startY = y
	local pointWidth = 5 * g_pixelSizeX
	local pointHeight = 5 * g_pixelSizeY
	local graphWidth = 75 * g_pixelSizeX
	local graphHeight = 75 * g_pixelSizeY
	local halfGraphWidth = graphWidth / 2
	local halfGraphHeight = graphHeight / 2
	local inputX = nil
	local inputY = nil
	if self.player.isOwner then
		local nextLineY = DebugUtil.renderTextLine(x, startY, textSize, "Local:")
		y = nextLineY
		DebugUtil.renderTextLine(x, nextLineY, textSize, string.format("x: %.2f, z: %.2f", self.lastMoveRight, self.lastMoveForward))
		drawFilledRect(x, y - graphHeight, graphWidth, graphHeight, PlayerInputComponent.DEBUG_GRAPH_BACKGROUND_COLOR:unpack())
		drawFilledRect(x + halfGraphWidth, y - graphHeight, g_pixelSizeX, graphHeight, Color.PRESETS.BLACK:unpack())
		drawFilledRect(x, y - halfGraphHeight, graphWidth, g_pixelSizeY, Color.PRESETS.BLACK:unpack())
		inputX = x + halfGraphWidth + self.lastMoveRight * halfGraphWidth
		inputY = y - halfGraphHeight + self.lastMoveForward * halfGraphHeight
		drawFilledRect(inputX - pointWidth / 2, inputY - pointHeight / 2, pointWidth, pointHeight, Color.PRESETS.RED:unpack())
	end
	x = x + graphWidth + 35 * g_pixelSizeX
	local nextLineY = DebugUtil.renderTextLine(x, startY, textSize, "World:")
	y = nextLineY
	DebugUtil.renderTextLine(x, nextLineY, textSize, string.format("x: %.2f, z: %.2f", self.lastWorldDirectionX, self.lastWorldDirectionZ))
	local runBarY = y - graphHeight - textSize
	drawFilledRect(x, y - graphHeight, graphWidth, graphHeight, PlayerInputComponent.DEBUG_GRAPH_BACKGROUND_COLOR:unpack())
	drawFilledRect(x + halfGraphWidth, y - graphHeight, g_pixelSizeX, graphHeight, Color.PRESETS.BLACK:unpack())
	drawFilledRect(x, y - halfGraphHeight, graphWidth, g_pixelSizeY, Color.PRESETS.BLACK:unpack())
	inputX = x + halfGraphWidth + self.lastWorldDirectionX * halfGraphWidth
	inputY = y - halfGraphHeight + self.lastWorldDirectionZ * halfGraphHeight
	drawFilledRect(inputX - pointWidth / 2, inputY - pointHeight / 2, pointWidth, pointHeight, Color.PRESETS.RED:unpack())
	local combinedMovementValue = self.lastWalkAxis
	if 0 < self.lastRunAxis then
		combinedMovementValue = self.lastWalkAxis * self.lastRunAxis
	end
	x = startX
	y = runBarY
	DebugUtil.renderTextLine(x, runBarY, textSize, string.format("Walk axis: %.2f, run axis: %.2f, combined: %.2f", self.lastWalkAxis, self.lastRunAxis, combinedMovementValue))
	graphWidth = 155 * g_pixelSizeX
	graphHeight = 25 * g_pixelSizeY
	halfGraphWidth = graphWidth / 2
	halfGraphHeight = graphHeight / 2
	drawFilledRect(x, y - graphHeight, graphWidth, graphHeight, PlayerInputComponent.DEBUG_GRAPH_BACKGROUND_COLOR:unpack())
	if 0 < self.lastRunAxis then
		drawFilledRect(x, y - graphHeight, halfGraphWidth, graphHeight, Color.PRESETS.DARKGREEN:unpack())
		local walkBarWidth = halfGraphWidth * self.lastWalkAxis * 0.5
		drawFilledRect(x + halfGraphWidth, y - graphHeight, walkBarWidth, graphHeight, Color.PRESETS.GREEN:unpack())
		drawFilledRect(x + halfGraphWidth + walkBarWidth, y - graphHeight, halfGraphWidth * self.lastRunAxis * 0.5, graphHeight, Color.PRESETS.RED:unpack())
	else
		drawFilledRect(x, y - graphHeight, halfGraphWidth * self.lastWalkAxis, graphHeight, Color.PRESETS.GREEN:unpack())
	end
	drawFilledRect(x + halfGraphWidth, y - graphHeight, g_pixelSizeX, graphHeight, Color.PRESETS.BLACK:unpack())
	y = DebugUtil.renderNewLine(y - graphHeight, textSize * 2)
	return y
end
