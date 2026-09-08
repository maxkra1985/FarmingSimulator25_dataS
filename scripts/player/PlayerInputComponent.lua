-- Local values: PlayerInputComponent_mt
PlayerInputComponent = {}
local PlayerInputComponent_mt = Class(PlayerInputComponent)
PlayerInputComponent.INPUT_CONTEXT_NAME = "PLAYER"
PlayerInputComponent.INPUT_CONTEXT_NAME_ANIMAL_RIDING = "ANIMAL_LOAD_EMPTY"
PlayerInputComponent.DEBUG_GRAPH_BACKGROUND_COLOR = Color.fromPackedValue(2155905152)

-- Upvalues: PlayerInputComponent_mt
-- Local values: self, flashlightName
function PlayerInputComponent.new(player)
	-- upvalues: (copy) PlayerInputComponent_mt
	local v3_ = PlayerInputComponent_mt
	local v4_ = setmetatable({}, v3_)
	v4_.player = player
	v4_.locked = false
	v4_.enterActionId = nil
	v4_.radioActionId = nil
	v4_.toggleFlightActionId = nil
	v4_.upDownFlightActionId = nil
	v4_.moveRight = 0
	v4_.moveForward = 0
	v4_.lastMoveRight = 0
	v4_.lastMoveForward = 0
	v4_.worldDirectionX = 0
	v4_.worldDirectionZ = 0
	v4_.lastWorldDirectionX = 0
	v4_.lastWorldDirectionZ = 0
	v4_.walkAxis = 0
	v4_.runAxis = 0
	v4_.flightAxis = 0
	v4_.jumpPower = 0
	v4_.crouchValue = 0
	v4_.lockedCrouchValue = 0
	v4_.lastWalkAxis = 0
	v4_.lastRunAxis = 0
	v4_.lastFlightAxis = 0
	v4_.lastJumpPower = 0
	v4_.lastCrouchValue = 0
	v4_.cameraRotationX = 0
	v4_.cameraRotationY = 0
	v4_.hasMovementInputs = false
	v4_.lastHasMovementInputs = false
	local v5_ = g_i18n:getText("storeItem_flashlight")
	v4_.turnOnFlashlightText = string.format(g_i18n:getText("action_turnOnOBJECT"), v5_)
	v4_.turnOffFlashlightText = string.format(g_i18n:getText("action_turnOffOBJECT"), v5_)
	return v4_
end

function PlayerInputComponent:onPlayerLoad()
	self.player.toggleFlightModeCommand.onEnabled:registerListener(function()
		-- upvalues: (copy) self
		g_inputBinding:setActionEventActive(self.toggleFlightActionId, true)
	end)
	self.player.toggleFlightModeCommand.onDisabled:registerListener(function()
		-- upvalues: (copy) self
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

-- Local values: mission
function PlayerInputComponent:addPauseListeners(isControlling)
	if isControlling then
		local v12_ = g_currentMission
		if v12_ ~= nil then
			v12_:addPauseListeners(self, self.onGamePaused)
		end
	end
end

-- Local values: _, eventId, targeter
function PlayerInputComponent:registerActionEvents()
	if self.player.isOwner then
		g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
		self:registerGlobalPlayerActionEvents()
		local _, v14_ = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_SIDE_PLAYER, self, self.onInputMoveSide, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(v14_, false)
		local _, v15_ = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_FORWARD_PLAYER, self, self.onInputMoveForward, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(v15_, false)
		local _, v16_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER, self, self.onInputLookLeftRight, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(v16_, false)
		local _, v17_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_PLAYER, self, self.onInputLookUpDown, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(v17_, false)
		local _, v18_ = g_inputBinding:registerActionEvent(InputAction.CAMERA_ZOOM_IN_OUT, self, self.onInputZoomInOut, false, true, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(v18_, false)
		local _, v19_ = g_inputBinding:registerActionEvent(InputAction.AXIS_RUN, self, self.onInputRun, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(v19_, false)
		local _, v20_ = g_inputBinding:registerActionEvent(InputAction.DEBUG_PLAYER_UP_DOWN, self, self.onInputChangeAltitude, false, false, true, false, nil, true)
		self.upDownFlightActionId = v20_
		g_inputBinding:setActionEventTextVisibility(self.upDownFlightActionId, false)
		local _, v21_ = g_inputBinding:registerActionEvent(InputAction.DEBUG_PLAYER_ENABLE, self, self.onInputToggleFlightMode, true, false, false, false, nil, true)
		self.toggleFlightActionId = v21_
		g_inputBinding:setActionEventTextVisibility(self.toggleFlightActionId, false)
		local _, v22_ = g_inputBinding:registerActionEvent(InputAction.JUMP, self, self.onInputJump, false, true, false, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(v22_, false)
		local _, v23_ = g_inputBinding:registerActionEvent(InputAction.CROUCH, self, self.onInputCrouch, false, false, true, true, nil, true)
		g_inputBinding:setActionEventTextVisibility(v23_, false)
		local _, v24_ = g_inputBinding:registerActionEvent(InputAction.CAMERA_SWITCH, self, self.onInputSwitchCamera, false, true, false, true, nil, true)
		self.toggleCameraId = v24_
		g_inputBinding:setActionEventActive(self.toggleCameraId, self:getCanToggleCamera())
		local _, _ = g_inputBinding:registerActionEvent(InputAction.TOGGLE_HANDTOOL, self, self.onInputToggleHandTool, false, true, false, true, nil, true)
		local _, _ = g_inputBinding:registerActionEvent(InputAction.CYCLE_HANDTOOL, self, self.onInputCycleHandTool, false, true, false, true, nil, true)
		local _, v25_ = g_inputBinding:registerActionEvent(InputAction.ENTER, self, self.onInputEnter, false, true, false, false, nil, true)
		self.enterActionId = v25_
		local _, v26_ = g_inputBinding:registerActionEvent(InputAction.TOGGLE_LIGHTS_FPS, self, self.onInputToggleFlashlight, false, true, false, true, nil, true)
		self.toggleFlashlightId = v26_
		g_inputBinding:setActionEventText(self.toggleFlashlightId, g_i18n:getText("input_TOGGLE_LIGHTS_FPS"))
		g_inputBinding:endActionEventsModification()
		if g_touchHandler ~= nil then
			self.touchListenerPinch = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_PINCH, PlayerInputComponent.touchEventZoomInOut, self)
			self.touchListenerY = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_Y, PlayerInputComponent.touchEventLookUpDown, self)
			self.touchListenerX = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_X, PlayerInputComponent.touchEventLookLeftRight, self)
			self.touchListenerDoubleTab = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_DOUBLE_TAP, PlayerInputComponent.touchEventCameraSwitch, self)
		end
		self:registerPauseActionEvents()
		self.player.targeter:addTargetType(PlayerInputComponent, CollisionFlag.ANIMAL + CollisionFlag.VEHICLE + CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT, 0.5, 3)
	end
end

-- Local values: _, eventId
function PlayerInputComponent:registerPauseActionEvents()
	if self.player.isOwner then
		g_inputBinding:beginActionEventsModification(BaseMission.INPUT_CONTEXT_PAUSE)
		if GS_IS_CONSOLE_VERSION then
			local _, v28_ = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onInputConsoleAcceptPause, false, true, false, true)
			g_inputBinding:setActionEventTextVisibility(v28_, false)
		end
		local _, _ = g_inputBinding:registerActionEvent(InputAction.MENU, self, self.onInputToggleMenu, false, true, false, true)
		local _, v29_ = g_inputBinding:registerActionEvent(InputAction.PAUSE, self, self.onInputPause, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v29_, true)
		g_inputBinding:setActionEventText(v29_, g_i18n:getText("ui_unpause"))
		g_inputBinding:endActionEventsModification()
	end
end

-- Local values: inputBinding, mission, oldContext, _, eventId, radioEventsActive, radioEvents
function PlayerInputComponent:registerGlobalPlayerActionEvents(context)
	if self.player.isOwner then
		local v32_ = g_inputBinding
		local v33_ = g_currentMission
		local v34_ = context or v32_:getContextName()
		local v35_ = v32_:getContextName()
		if v35_ ~= v34_ then
			v32_:beginActionEventsModification(v34_)
		end
		local _, v36_ = v32_:registerActionEvent(InputAction.MENU, self, self.onInputToggleMenu, false, true, false, true)
		v32_:setActionEventTextVisibility(v36_, false)
		local _, v37_ = v32_:registerActionEvent(InputAction.PAUSE, self, self.onInputPause, false, true, false, true)
		v32_:setActionEventTextVisibility(v37_, false)
		local _, v38_ = v32_:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, self, self.onInputToggleHelpText, false, true, false, true)
		v32_:setActionEventTextVisibility(v38_, false)
		local _, v39_ = v32_:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onInputSwitchVehicle, false, true, false, true, 1)
		v32_:setActionEventTextVisibility(v39_, false)
		local _, v40_ = v32_:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onInputSwitchVehicle, false, true, false, true, -1)
		v32_:setActionEventTextVisibility(v40_, false)
		local _, v41_ = v32_:registerActionEvent(InputAction.TOGGLE_STORE, self, self.onInputToggleStore, false, true, false, true)
		v32_:setActionEventTextVisibility(v41_, false)
		local _, v42_ = v32_:registerActionEvent(InputAction.TOGGLE_MAP, self, self.onInputToggleMap, false, true, false, true)
		v32_:setActionEventTextVisibility(v42_, false)
		local _, v43_ = v32_:registerActionEvent(InputAction.TOGGLE_HELP, self, self.onInputToggleHelp, false, true, false, true)
		v32_:setActionEventTextVisibility(v43_, false)
		local _, v44_ = v32_:registerActionEvent(InputAction.INCREASE_TIMESCALE, self, self.onInputChangeTimescale, false, true, false, true, 1)
		v32_:setActionEventTextVisibility(v44_, false)
		local _, v45_ = v32_:registerActionEvent(InputAction.DECREASE_TIMESCALE, self, self.onInputChangeTimescale, false, true, false, true, -1)
		v32_:setActionEventTextVisibility(v45_, false)
		v33_.hud:registerInput()
		if g_soundPlayer ~= nil then
			local _, v46_ = v32_:registerActionEvent(InputAction.RADIO_TOGGLE, self, self.onInputToggleRadio, false, true, false, false)
			v32_:setActionEventTextVisibility(v46_, GS_IS_CONSOLE_VERSION)
			self.radioActionId = v46_
			local v47_ = v33_:getIsRadioPlaying()
			local v48_ = {}
			local _, v49_ = v32_:registerActionEvent(InputAction.RADIO_PREVIOUS_CHANNEL, g_soundPlayer, g_soundPlayer.previousChannel, false, true, false, v47_)
			v32_:setActionEventTextVisibility(v49_, GS_IS_CONSOLE_VERSION)
			table.insert(v48_, v49_)
			local _, v50_ = v32_:registerActionEvent(InputAction.RADIO_NEXT_CHANNEL, g_soundPlayer, g_soundPlayer.nextChannel, false, true, false, v47_)
			v32_:setActionEventTextVisibility(v50_, GS_IS_CONSOLE_VERSION)
			table.insert(v48_, v50_)
			local _, v51_ = v32_:registerActionEvent(InputAction.RADIO_NEXT_ITEM, g_soundPlayer, g_soundPlayer.nextItem, false, true, false, v47_)
			v32_:setActionEventTextVisibility(v51_, false)
			table.insert(v48_, v51_)
			local _, v52_ = v32_:registerActionEvent(InputAction.RADIO_PREVIOUS_ITEM, g_soundPlayer, g_soundPlayer.previousItem, false, true, false, v47_)
			v32_:setActionEventTextVisibility(v52_, false)
			table.insert(v48_, v52_)
			if v34_ == PlayerInputComponent.INPUT_CONTEXT_NAME then
				self.playerRadioEvents = v48_
			end
			v33_.radioEvents = v48_
		end
		if v33_.missionDynamicInfo.isMultiplayer then
			v32_:registerActionEvent(InputAction.CHAT, self, self.onInputToggleChat, false, true, false, true)
		end
		if Platform.hasWardrobe then
			local _, v53_ = v32_:registerActionEvent(InputAction.TOGGLE_CHARACTER_CREATION, self, self.onInputToggleCharacterCreation, false, true, false, true)
			v32_:setActionEventTextVisibility(v53_, false)
		end
		local _, v54_ = v32_:registerActionEvent(InputAction.TOGGLE_CONSTRUCTION, self, self.onInputToggleConstructionScreen, false, true, false, true)
		v32_:setActionEventTextVisibility(v54_, false)
		local _, v55_ = v32_:registerActionEvent(InputAction.TAKE_SCREENSHOT, self, self.onInputTakeScreenshot, false, true, false, true)
		v32_:setActionEventTextVisibility(v55_, false)
		local _, v56_ = v32_:registerActionEvent(InputAction.PUSH_TO_TALK, self, self.onPushToTalk, true, true, false, true)
		v32_:setActionEventTextVisibility(v56_, false)
		if v35_ ~= v34_ then
			g_inputBinding:beginActionEventsModification(v35_)
		end
	end
end

function PlayerInputComponent:unregisterActionEvents()
	if self.player.isOwner then
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
	if self.player.isOwner then
		g_inputBinding:setContext(PlayerInputComponent.INPUT_CONTEXT_NAME)
		if self.radioActionId ~= nil then
			g_inputBinding:setActionEventActive(self.radioActionId, false)
		end
		if self.playerRadioEvents ~= nil then
			g_currentMission.radioEvents = self.playerRadioEvents
		end
	end
end

-- Local values: mission, accessHandler, interactiveVehicle, canPlayerEnterVehicle, targetNode, husbandryId, animalId, clusterHusbandry, placeable, cluster, text, rideableName
function PlayerInputComponent:update(dt)
	if self.player.isOwner then
		if g_inputBinding:getContextName() == PlayerInputComponent.INPUT_CONTEXT_NAME then
			local v60_ = g_currentMission
			local v61_ = v60_.accessHandler
			local v62_ = v60_.interactiveVehicleInRange
			local v63_
			if v62_ == nil then
				v63_ = false
			else
				v63_ = v61_:canPlayerAccess(v62_, self.player)
			end
			self.rideablePlaceable = nil
			self.rideableCluster = nil
			local v64_ = self.player.targeter:getClosestTargetedNodeFromType(PlayerInputComponent)
			self.player.hudUpdater:setCurrentRaycastTarget(v64_)
			if not v63_ and v64_ ~= nil then
				local v65_, v66_ = getAnimalFromCollisionNode(v64_)
				if v65_ ~= nil and v65_ ~= 0 then
					local v67_ = v60_.husbandrySystem:getClusterHusbandryById(v65_)
					if v67_ ~= nil then
						local v68_ = v67_:getPlaceable()
						local v69_ = v67_:getClusterByAnimalId(v66_)
						if v69_ ~= nil and (v61_:canFarmAccess(self.player.farmId, v68_) and v68_:getAnimalSupportsRiding(v69_.id)) then
							self.rideablePlaceable = v68_
							self.rideableCluster = v69_
						end
					end
				end
			end
			if self.player.mover.isFlightActive or not v63_ and self.rideablePlaceable == nil then
				g_inputBinding:setActionEventActive(self.enterActionId, false)
			else
				local v70_
				if v63_ then
					v70_ = v62_:getInteractionHelp()
				else
					local v71_ = self.rideableCluster.getName == nil and "" or self.rideableCluster:getName()
					v70_ = string.format(g_i18n:getText("action_rideAnimal"), v71_)
				end
				g_inputBinding:setActionEventText(self.enterActionId, v70_)
				g_inputBinding:setActionEventActive(self.enterActionId, true)
			end
			if self.player.isFlashlightActive then
				g_inputBinding:setActionEventText(self.toggleFlashlightId, self.turnOffFlashlightText)
			else
				g_inputBinding:setActionEventText(self.toggleFlashlightId, self.turnOnFlashlightText)
			end
			g_inputBinding:setActionEventActive(self.toggleCameraId, self:getCanToggleCamera())
		end
	else
		return
	end
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
	self.hasMovementInputs = movementDirectionX ~= 0 and true or movementDirectionZ ~= 0
	self.worldDirectionX = movementDirectionX
	self.worldDirectionZ = movementDirectionZ
end

function PlayerInputComponent:calculateNormalisedMovementDirection()
	if self.moveRight == 0 and self.moveForward == 0 then
		return 0, 0
	else
		return MathUtil.vector2Normalize(self.moveRight, self.moveForward)
	end
end

function PlayerInputComponent:getCanToggleCamera()
	if self.locked then
		return false
	elseif self.player:getCurrentVehicle() == nil then
		return not self.player.camera:getIsSwitchingLocked()
	else
		return false
	end
end

-- Local values: localDirectionX, localDirectionZ, worldDirectionX, _, worldDirectionZ
function PlayerInputComponent:calculateNormalisedWorldMovementDirection()
	local v81_, v82_ = self:calculateNormalisedMovementDirection()
	if v81_ == 0 and v82_ == 0 or self.player.camera.yawNode == nil then
		return 0, 0
	end
	local v83_, _, v84_ = localDirectionToWorld(self.player.camera.yawNode, -v81_, 0, v82_)
	return v83_, v84_
end

-- Local values: mission
function PlayerInputComponent:onInputPause()
	local v85_ = g_currentMission
	if v85_.gameStarted then
		v85_:setManualPause(not v85_.manualPaused)
	end
end

-- Local values: mission
function PlayerInputComponent:onInputConsoleAcceptPause()
	local v86_ = g_currentMission
	if v86_.gameStarted and (v86_.manualPaused and GS_IS_CONSOLE_VERSION) then
		v86_:setManualPause(false)
	end
end

-- Local values: isVisible
function PlayerInputComponent:onInputToggleHelpText()
	if not self.locked then
		local v88_ = not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)
		g_gameSettings:setValue(GameSettings.SETTING.SHOW_HELP_MENU, v88_)
	end
end

function PlayerInputComponent:onInputSwitchVehicle(_, _, directionValue)
	if not self.locked then
		self.player:cycleCurrentVehicle(directionValue)
	end
end

-- Local values: mission
function PlayerInputComponent:onInputToggleMenu()
	if self.locked then
		return
	elseif g_sleepManager:getIsSleeping() then
		return
	elseif not g_currentMission.isSynchronizingWithPlayers then
		g_gui:changeScreen(nil, InGameMenu)
		if GS_IS_MOBILE_VERSION then
			g_inGameMenu:goToPage(g_inGameMenu.pageMain)
		end
	end
end

-- Local values: mission
function PlayerInputComponent:onInputToggleStore()
	if self.locked then
		return
	else
		local v93_ = g_currentMission
		if v93_.isSynchronizingWithPlayers then
			return
		elseif v93_.missionInfo:isa(FSCareerMissionInfo) then
			if g_guidedTourManager:getIsTourRunning() then
				InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
				return
			elseif v93_.isPlayerFrozen then
				return
			elseif self.player.farmId == FarmManager.SPECTATOR_FARM_ID then
				v93_:showBlinkingWarning(g_i18n:getText("warning_joinFarmFirst"), 1500)
			else
				g_gui:changeScreen(nil, ShopMenu)
			end
		else
			InfoDialog.show(g_i18n:getText("dialog_shopOnlyWorksInCareer"))
			return
		end
	end
end

-- Local values: mission
function PlayerInputComponent:onInputToggleMap()
	if self.locked then
		return
	elseif g_currentMission.isSynchronizingWithPlayers then
		return
	elseif g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
		return
	else
		g_gui:changeScreen(nil, InGameMenu)
		if Platform.isMobile then
			g_inGameMenu:goToPage(g_inGameMenu.pageMapMobile)
		else
			g_inGameMenu:goToPage(g_inGameMenu.pageMapOverview)
		end
	end
end

-- Local values: mission, x, y, z
function PlayerInputComponent:onInputToggleHelp()
	if not g_currentMission.isSynchronizingWithPlayers then
		local v95_, v96_, v97_ = getWorldTranslation(g_cameraManager:getActiveCamera())
		g_inGameMenu.pageHelpLine.closeMenuOneshot = true
		g_inGameMenu.blockNextPageNextEvent = true
		g_helpLineManager:openContextBasedHelp(v95_, v96_, v97_)
	end
end

-- Local values: mission
function PlayerInputComponent:onInputToggleCharacterCreation()
	if self.locked then
		return
	elseif g_currentMission.isSynchronizingWithPlayers then
		return
	elseif g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		g_gui:changeScreen(nil, WardrobeScreen)
	end
end

-- Local values: mission
function PlayerInputComponent:onInputToggleConstructionScreen()
	if self.locked then
		return
	elseif g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
		return
	else
		local v100_ = g_currentMission
		if v100_.isSynchronizingWithPlayers then
			return
		elseif self.player.farmId == FarmManager.SPECTATOR_FARM_ID then
			v100_:showBlinkingWarning(g_i18n:getText("warning_joinFarmFirst"), 1500)
		else
			g_gui:changeScreen(nil, ConstructionScreen)
		end
	end
end

function PlayerInputComponent:onInputTakeScreenshot()
	takeScreenshot()
end

function PlayerInputComponent:onPushToTalk(_, value)
	VoiceChatUtil.setIsPushToTalkPressed(value == 1)
end

-- Local values: isActive
function PlayerInputComponent:onInputToggleRadio()
	local v102_ = g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE)
	g_gameSettings:setValue(GameSettings.SETTING.RADIO_IS_ACTIVE, not v102_)
end

-- Local values: mission, timeScaleIndex, newTimeScale
function PlayerInputComponent:onInputChangeTimescale(_, _, indexStep)
	if self.locked then
		return
	else
		local v105_ = g_currentMission
		if v105_:getIsServer() or v105_.isMasterUser then
			local v106_ = Utils.getTimeScaleIndex(v105_.missionInfo.timeScale)
			local v107_ = Utils.getTimeScaleFromIndex(v106_ + indexStep)
			if v107_ ~= nil then
				v105_:setTimeScale(v107_)
			end
		end
	end
end

-- Local values: mission
function PlayerInputComponent:onInputToggleChat(isActive)
	local v109_ = g_currentMission
	if not v109_.isSynchronizingWithPlayers then
		local v110_
		if isActive == nil or isActive then
			g_gui:showGui("ChatDialog")
			v110_ = true
		else
			v110_ = false
		end
		v109_.hud:setChatDisplayVisible(v110_)
	end
end

function PlayerInputComponent:onInputToggleFlightMode(isActive)
	if not self.locked then
		self.player.mover:toggleFlightActive()
		g_inputBinding:setActionEventActive(self.upDownFlightActionId, self.player.mover.isFlightActive)
	end
end

-- Local values: worldDirectionX, worldDirectionZ
function PlayerInputComponent:onInputMoveSide(_, inputValue)
	if self.locked then
		return
	elseif math.abs(inputValue) > g_gameSettings:getValue(GameSettings.SETTING.JOYSTICK_DEADZONE) then
		local v114_ = math.clamp(inputValue, -1, 1)
		self.moveRight = self.moveRight + v114_
		local v115_ = MathUtil.vector2Length(self.moveRight, self.moveForward)
		self.walkAxis = math.min(v115_, 1)
		local v116_, v117_ = self:calculateNormalisedWorldMovementDirection()
		self:setMovementDirection(v116_, v117_)
	end
end

-- Local values: worldDirectionX, worldDirectionZ
function PlayerInputComponent:onInputMoveForward(_, inputValue)
	if self.locked then
		return
	elseif math.abs(inputValue) > g_gameSettings:getValue(GameSettings.SETTING.JOYSTICK_DEADZONE) then
		local v120_ = math.clamp(inputValue, -1, 1)
		self.moveForward = self.moveForward - v120_
		local v121_ = MathUtil.vector2Length(self.moveRight, self.moveForward)
		self.walkAxis = math.min(v121_, 1)
		local v122_, v123_ = self:calculateNormalisedWorldMovementDirection()
		self:setMovementDirection(v122_, v123_)
	end
end

-- Local values: factor
function PlayerInputComponent:touchEventLookUpDown(value)
	if g_inputBinding.currentContextName == PlayerInputComponent.INPUT_CONTEXT_NAME then
		self:onInputLookUpDown(nil, value * (g_screenHeight * g_pixelSizeX * -75), nil, nil, false)
	end
end

function PlayerInputComponent:touchEventZoomInOut(value)
	if g_inputBinding.currentContextName == PlayerInputComponent.INPUT_CONTEXT_NAME then
		self:onInputZoomInOut(nil, -value * 75, nil, nil, false, nil, nil)
	end
end

-- Local values: factor
function PlayerInputComponent:touchEventLookLeftRight(value)
	if g_inputBinding.currentContextName == PlayerInputComponent.INPUT_CONTEXT_NAME then
		self:onInputLookLeftRight(nil, value * (g_screenAspectRatio * 75), nil, nil, false)
	end
end

function PlayerInputComponent:touchEventCameraSwitch(value)
	if g_inputBinding.currentContextName == PlayerInputComponent.INPUT_CONTEXT_NAME then
		if self:getCanToggleCamera() then
			self:onInputSwitchCamera()
		end
	else
		return
	end
end

function PlayerInputComponent:onInputLookLeftRight(_, inputValue, _, _, isMouse)
	if self.locked then
		return
	elseif math.abs(inputValue) > g_gameSettings:getValue(GameSettings.SETTING.JOYSTICK_DEADZONE) then
		local v134_
		if isMouse then
			v134_ = inputValue * 0.001 * 16.666
		else
			v134_ = inputValue * 0.001 * g_currentDt
		end
		self.cameraRotationY = self.cameraRotationY + v134_
		self.isMouseRotation = isMouse
	end
end

function PlayerInputComponent:onInputLookUpDown(_, inputValue, _, _, isMouse)
	if self.locked then
		return
	elseif math.abs(inputValue) > g_gameSettings:getValue(GameSettings.SETTING.JOYSTICK_DEADZONE) then
		if g_gameSettings:getValue(GameSettings.SETTING.INVERT_Y_LOOK) then
			inputValue = inputValue * -1
		end
		local v138_
		if isMouse then
			v138_ = inputValue * 0.001 * 16.666
		else
			v138_ = inputValue * 0.001 * g_currentDt
		end
		self.cameraRotationX = self.cameraRotationX + v138_
		self.isMouseRotation = isMouse
	end
end

-- Local values: offset
function PlayerInputComponent:onInputZoomInOut(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
	if not self.locked then
		local v142_ = -0.2
		if isMouse then
			v142_ = v142_ * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
		end
		local v143_ = v142_ * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_ZOOM_SENSITIVITY)
		self.player.camera:zoomSmoothly(v143_ * inputValue)
	end
end

function PlayerInputComponent:onInputRun(_, inputValue)
	if not self.locked then
		self.runAxis = math.clamp(inputValue, 0, 1)
	end
end

function PlayerInputComponent:onInputChangeAltitude(_, inputValue)
	if not self.locked then
		self.flightAxis = math.clamp(inputValue, -1, 1)
	end
end

function PlayerInputComponent:onInputJump(_, inputValue)
	if not self.locked then
		self.jumpPower = math.clamp(inputValue, 0, 1)
	end
end

function PlayerInputComponent:onInputCrouch(_, inputValue)
	local v152_ = math.clamp(inputValue, 0, 1)
	if self.locked then
		self.lockedCrouchValue = v152_
	else
		self.crouchValue = v152_
	end
end

function PlayerInputComponent:onInputSwitchCamera()
	if self.locked then
		return
	elseif self.player:getCurrentVehicle() == nil then
		self.player.camera:toggleThirdPersonMode()
	end
end

-- Local values: mission
function PlayerInputComponent:onInputEnter()
	local v155_ = g_currentMission
	if g_time <= v155_.lastInteractionTime + 200 then
		return
	elseif v155_.interactiveVehicleInRange == nil then
		if self.rideablePlaceable ~= nil then
			if self.rideablePlaceable:getAnimalCanBeRidden(self.rideableCluster.id) then
				g_inputBinding:setContext(PlayerInputComponent.INPUT_CONTEXT_NAME_ANIMAL_RIDING, true, false)
				v155_:fadeScreen(1, 250, self.onFinishedRideBlending, self, { self.rideablePlaceable, self.rideableCluster, self.player })
				return
			end
			v155_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("shop_messageAnimalRideableLimitReached"))
		end
	else
		v155_.interactiveVehicleInRange:interact(self.player)
	end
end

-- Local values: placeable, cluster, player
function PlayerInputComponent:onFinishedRideBlending(arguments)
	local v157_ = arguments[1]
	local v158_ = arguments[2]
	local v159_ = arguments[3]
	v157_:startRiding(v158_.id, v159_)
end

function PlayerInputComponent:onInputToggleFlashlight()
	self.player:toggleFlashlight()
end

function PlayerInputComponent:onInputCycleHandTool(_, inputValue)
	if self.locked then
		return
	elseif self.player:getCurrentVehicle() == nil then
		if not self.player.mover.isSwimming then
			self.player:cycleHandTool((math.sign(inputValue)))
		end
	else
		return
	end
end

function PlayerInputComponent:onInputToggleHandTool(_, inputValue)
	if self.locked then
		return
	elseif self.player:getCurrentVehicle() == nil then
		if not self.player.mover.isSwimming then
			self.player:toggleHandTool()
		end
	else
		return
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
	local v170_ = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Input", nil, true)
	local v171_ = DebugUtil.renderTextLine(x, v170_, textSize, string.format("Jump power: %.2f", self.lastJumpPower))
	local v172_ = DebugUtil.renderTextLine(x, v171_, textSize, string.format("Crouch: %.2f", self.lastCrouchValue))
	return self:debugDrawMovementGraphs(x, DebugUtil.renderTextLine(x, v172_, textSize, string.format("Has movement: %s", self.lastHasMovementInputs)), textSize)
end

-- Local values: startX, startY, pointWidth, pointHeight, graphWidth, graphHeight, halfGraphWidth, halfGraphHeight, inputX, inputY, nextLineY, nextLineY, runBarY, combinedMovementValue, walkBarWidth
function PlayerInputComponent:debugDrawMovementGraphs(x, y, textSize)
	local v177_ = 5 * g_pixelSizeX
	local v178_ = 5 * g_pixelSizeY
	local v179_ = 75 * g_pixelSizeX
	local v180_ = 75 * g_pixelSizeY
	local v181_ = v179_ / 2
	local v182_ = v180_ / 2
	if self.player.isOwner then
		local v183_ = DebugUtil.renderTextLine(x, y, textSize, "Local:")
		DebugUtil.renderTextLine(x, v183_, textSize, string.format("x: %.2f, z: %.2f", self.lastMoveRight, self.lastMoveForward))
		drawFilledRect(x, v183_ - v180_, v179_, v180_, PlayerInputComponent.DEBUG_GRAPH_BACKGROUND_COLOR:unpack())
		drawFilledRect(x + v181_, v183_ - v180_, g_pixelSizeX, v180_, Color.PRESETS.BLACK:unpack())
		drawFilledRect(x, v183_ - v182_, v179_, g_pixelSizeY, Color.PRESETS.BLACK:unpack())
		local v184_ = x + v181_ + self.lastMoveRight * v181_
		local v185_ = v183_ - v182_ + self.lastMoveForward * v182_
		drawFilledRect(v184_ - v177_ / 2, v185_ - v178_ / 2, v177_, v178_, Color.PRESETS.RED:unpack())
	end
	local v186_ = x + v179_ + 35 * g_pixelSizeX
	local v187_ = DebugUtil.renderTextLine(v186_, y, textSize, "World:")
	DebugUtil.renderTextLine(v186_, v187_, textSize, string.format("x: %.2f, z: %.2f", self.lastWorldDirectionX, self.lastWorldDirectionZ))
	local v188_ = v187_ - v180_ - textSize
	drawFilledRect(v186_, v187_ - v180_, v179_, v180_, PlayerInputComponent.DEBUG_GRAPH_BACKGROUND_COLOR:unpack())
	drawFilledRect(v186_ + v181_, v187_ - v180_, g_pixelSizeX, v180_, Color.PRESETS.BLACK:unpack())
	drawFilledRect(v186_, v187_ - v182_, v179_, g_pixelSizeY, Color.PRESETS.BLACK:unpack())
	local v189_ = v186_ + v181_ + self.lastWorldDirectionX * v181_
	local v190_ = v187_ - v182_ + self.lastWorldDirectionZ * v182_
	drawFilledRect(v189_ - v177_ / 2, v190_ - v178_ / 2, v177_, v178_, Color.PRESETS.RED:unpack())
	local v191_ = self.lastWalkAxis
	if self.lastRunAxis > 0 then
		v191_ = self.lastWalkAxis * self.lastRunAxis
	end
	DebugUtil.renderTextLine(x, v188_, textSize, string.format("Walk axis: %.2f, run axis: %.2f, combined: %.2f", self.lastWalkAxis, self.lastRunAxis, v191_))
	local v192_ = 155 * g_pixelSizeX
	local v193_ = 25 * g_pixelSizeY
	local v194_ = v192_ / 2
	local _ = v193_ / 2
	drawFilledRect(x, v188_ - v193_, v192_, v193_, PlayerInputComponent.DEBUG_GRAPH_BACKGROUND_COLOR:unpack())
	if self.lastRunAxis > 0 then
		drawFilledRect(x, v188_ - v193_, v194_, v193_, Color.PRESETS.DARKGREEN:unpack())
		local v195_ = v194_ * self.lastWalkAxis * 0.5
		drawFilledRect(x + v194_, v188_ - v193_, v195_, v193_, Color.PRESETS.GREEN:unpack())
		drawFilledRect(x + v194_ + v195_, v188_ - v193_, v194_ * self.lastRunAxis * 0.5, v193_, Color.PRESETS.RED:unpack())
	else
		drawFilledRect(x, v188_ - v193_, v194_ * self.lastWalkAxis, v193_, Color.PRESETS.GREEN:unpack())
	end
	drawFilledRect(x + v194_, v188_ - v193_, g_pixelSizeX, v193_, Color.PRESETS.BLACK:unpack())
	return DebugUtil.renderNewLine(v188_ - v193_, textSize * 2)
end
