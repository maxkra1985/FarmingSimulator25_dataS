source("dataS/scripts/vehicles/specializations/events/EnterablePassengerEnterRequestEvent.lua")
source("dataS/scripts/vehicles/specializations/events/EnterablePassengerEnterResponseEvent.lua")
source("dataS/scripts/vehicles/specializations/events/EnterablePassengerLeaveEvent.lua")
EnterablePassenger = {}
EnterablePassenger.DEBUG_ACTIVE = false
EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS = 4

function EnterablePassenger.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Enterable, specializations)
end
function EnterablePassenger.initSpecialization()
	Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER = Vehicle.registerInteractionFlag("ENTERABLE_PASSENGER")
	g_vehicleConfigurationManager:addConfigurationType("enterablePassenger", g_i18n:getText("shop_configuration"), "enterable", VehicleConfigurationItem)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("EnterablePassenger")
	EnterablePassenger.registerXMLPaths("vehicle.enterable.passengerSeats", v2_)
	EnterablePassenger.registerXMLPaths("vehicle.enterable.enterablePassengerConfigurations.enterablePassengerConfiguration(?)", v2_)
	v2_:setXMLSpecializationType()
end

function EnterablePassenger.registerXMLPaths(basePath, schema)
	schema:register(XMLValueType.BOOL, basePath .. "#allowInSingleplayer", "Allow usage of passenger in singleplayer", false)
	schema:register(XMLValueType.BOOL, basePath .. "#allowPassengerOnly", "Allow entering of passenger seat when no one is controlling the vehicle", false)
	schema:register(XMLValueType.BOOL, basePath .. "#allowVehicleControl", "Allow control of vehicle from passenger seat", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".passengerSeat(?)#node", "Seat reference node to calculate entering distance to")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".passengerSeat(?)#exitPoint", "Player spawn point when leaving the vehicle")
	schema:register(XMLValueType.INT, basePath .. ".passengerSeat(?)#outdoorCameraIndex", "Index of regular outdoor camera if it should be available as well")
	schema:register(XMLValueType.FLOAT, basePath .. ".passengerSeat(?)#nicknameOffset", "Nickname rendering offset", 1.5)
	VehicleCamera.registerCameraXMLPaths(schema, basePath .. ".passengerSeat(?).camera(?)")
	VehicleCharacter.registerCharacterXMLPaths(schema, basePath .. ".passengerSeat(?).characterNode")
end

function EnterablePassenger.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getClosestSeatIndex", EnterablePassenger.getClosestSeatIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsPassengerSeatAvailable", EnterablePassenger.getIsPassengerSeatAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getIsPassengerSeatIndexAvailable", EnterablePassenger.getIsPassengerSeatIndexAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getFirstAvailablePassengerSeat", EnterablePassenger.getFirstAvailablePassengerSeat)
	SpecializationUtil.registerFunction(vehicleType, "getPlayerNameBySeatIndex", EnterablePassenger.getPlayerNameBySeatIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCanUsePassengerSeats", EnterablePassenger.getCanUsePassengerSeats)
	SpecializationUtil.registerFunction(vehicleType, "enterVehiclePassengerSeat", EnterablePassenger.enterVehiclePassengerSeat)
	SpecializationUtil.registerFunction(vehicleType, "leaveLocalPassengerSeat", EnterablePassenger.leaveLocalPassengerSeat)
	SpecializationUtil.registerFunction(vehicleType, "leavePassengerSeat", EnterablePassenger.leavePassengerSeat)
	SpecializationUtil.registerFunction(vehicleType, "getPassengerSeatIndexByPlayer", EnterablePassenger.getPassengerSeatIndexByPlayer)
	SpecializationUtil.registerFunction(vehicleType, "copyEnterableActiveCameraIndex", EnterablePassenger.copyEnterableActiveCameraIndex)
	SpecializationUtil.registerFunction(vehicleType, "setPassengerActiveCameraIndex", EnterablePassenger.setPassengerActiveCameraIndex)
	SpecializationUtil.registerFunction(vehicleType, "enablePassengerActiveCamera", EnterablePassenger.enablePassengerActiveCamera)
	SpecializationUtil.registerFunction(vehicleType, "setPassengerSeatCharacter", EnterablePassenger.setPassengerSeatCharacter)
	SpecializationUtil.registerFunction(vehicleType, "updatePassengerSeatCharacter", EnterablePassenger.updatePassengerSeatCharacter)
	SpecializationUtil.registerFunction(vehicleType, "onPassengerPlayerStyleChanged", EnterablePassenger.onPassengerPlayerStyleChanged)
end

function EnterablePassenger.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInteractionHelp", EnterablePassenger.getInteractionHelp)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "interact", EnterablePassenger.interact)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDistanceToNode", EnterablePassenger.getDistanceToNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", EnterablePassenger.getIsEnterable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getExitNode", EnterablePassenger.getExitNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", EnterablePassenger.getIsInUse)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", EnterablePassenger.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInteractive", EnterablePassenger.getIsInteractive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnteredForInput", EnterablePassenger.getIsEnteredForInput)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", EnterablePassenger.getRequiresPower)
end

function EnterablePassenger.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onDrawUIInfo", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onPreRegisterActionEvents", EnterablePassenger)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", EnterablePassenger)
end

-- Local values: spec, baseKey, configIndex, configKey, _, key, seatEntry, outdoorCameraIndex, specEnterable
function EnterablePassenger:onLoad(savegame)
	local v9_ = self.spec_enterablePassenger
	v9_.currentSeatIndex = 1
	v9_.passengerEntered = false
	local v10_ = "vehicle.enterable.passengerSeats"
	local v11_ = self.configurations.enterablePassenger
	local v12_
	if v11_ == nil then
		v12_ = v10_
	else
		v12_ = string.format("vehicle.enterable.enterablePassengerConfigurations.enterablePassengerConfiguration(%d)", v11_ - 1)
		if not self.xmlFile:hasProperty(v12_) then
			v12_ = v10_
		end
	end
	v9_.allowInSingleplayer = self.xmlFile:getValue(v12_ .. "#allowInSingleplayer", false)
	v9_.allowPassengerOnly = self.xmlFile:getValue(v12_ .. "#allowPassengerOnly", false)
	v9_.allowVehicleControl = self.xmlFile:getValue(v12_ .. "#allowVehicleControl", false)
	v9_.passengerSeats = {}
	for _, v13_ in self.xmlFile:iterator(v12_ .. ".passengerSeat") do
		local v_u_14_ = {
			["node"] = self.xmlFile:getValue(v13_ .. "#node", nil, self.components, self.i3dMappings),
			["exitPoint"] = self.xmlFile:getValue(v13_ .. "#exitPoint", nil, self.components, self.i3dMappings)
		}
		if v_u_14_.node == nil then
			Logging.xmlWarning(self.xmlFile, "Missing node for \'%s\'", v13_)
		else
			v_u_14_.cameras = {}
			v_u_14_.camIndex = 1
			local v15_ = self.xmlFile:getValue(v13_ .. "#outdoorCameraIndex")
			if v15_ ~= nil then
				local v16_ = self.spec_enterable
				if v16_.cameras ~= nil and v16_.cameras[v15_] ~= nil then
					local v17_ = v_u_14_.cameras
					local v18_ = v16_.cameras[v15_]
					table.insert(v17_, v18_)
				end
			end
			self.xmlFile:iterate(v13_ .. ".camera", function(p19_, p20_)
				-- upvalues: (copy) self, (copy) v_u_14_
				local v21_ = VehicleCamera.new(self)
				if v21_:loadFromXML(self.xmlFile, p20_, nil, p19_) then
					v21_.isPassengerCamera = true
					local v22_ = v_u_14_.cameras
					table.insert(v22_, v21_)
				end
			end)
			v_u_14_.nicknameOffset = self.xmlFile:getValue(v13_ .. "#nicknameOffset", 1.5)
			v_u_14_.vehicleCharacter = VehicleCharacter.new(self)
			if v_u_14_.vehicleCharacter ~= nil and not v_u_14_.vehicleCharacter:load(self.xmlFile, v13_ .. ".characterNode") then
				v_u_14_.vehicleCharacter = nil
			end
			v_u_14_.isUsed = false
			v_u_14_.playerStyle = nil
			v_u_14_.lastUserId = nil
			v_u_14_.userId = nil
			local v23_ = v9_.passengerSeats
			table.insert(v23_, v_u_14_)
		end
	end
	local v24_
	if #v9_.passengerSeats > 0 then
		v24_ = g_currentMission.missionDynamicInfo.isMultiplayer or v9_.allowInSingleplayer
	else
		v24_ = false
	end
	v9_.available = v24_
	v9_.texts = {}
	v9_.texts.enterVehicleDriver = string.format("%s (%s)", g_i18n:getText("button_enterVehicle"), g_i18n:getText("passengerSeat_driver"))
	v9_.texts.enterVehiclePassenger = string.format("%s (%s)", g_i18n:getText("button_enterVehicle"), g_i18n:getText("passengerSeat_passenger"))
	v9_.texts.switchSeatDriver = g_i18n:getText("passengerSeat_switchSeatDriver")
	v9_.texts.switchSeatPassenger = g_i18n:getText("passengerSeat_switchSeatPassenger")
	v9_.texts.switchNextSeat = g_i18n:getText("passengerSeat_switchNextSeat")
	v9_.minEnterDistance = 3
	if v9_.available then
		g_messageCenter:subscribe(MessageType.PLAYER_STYLE_CHANGED, self.onPassengerPlayerStyleChanged, self)
	end
end

-- Local values: spec, seatIndex, passengerSeat, player, _, camera
function EnterablePassenger:onDelete()
	local v26_ = self.spec_enterablePassenger
	if v26_.passengerEntered then
		g_localPlayer:leaveVehicle(self, true)
		self:leavePassengerSeat(true, v26_.currentSeatIndex)
	end
	if v26_.passengerSeats ~= nil then
		for v27_ = 1, #v26_.passengerSeats do
			local v28_ = v26_.passengerSeats[v27_]
			if v28_.isUsed then
				local v29_ = g_currentMission.playerSystem:getPlayerByUserId(v28_.userId)
				if v29_ ~= nil then
					v29_:leaveVehicle(self, true)
				end
				self:leavePassengerSeat(false, v27_)
			end
			for _, v30_ in ipairs(v28_.cameras) do
				if v30_.isPassengerCamera then
					v30_:delete()
				end
			end
			if v28_.vehicleCharacter ~= nil then
				v28_.vehicleCharacter:delete()
			end
		end
	end
end

-- Local values: spec, seatIndex, userId, player
function EnterablePassenger:onReadStream(streamId, connection)
	for v33_ = 1, #self.spec_enterablePassenger.passengerSeats do
		if streamReadBool(streamId) then
			local v34_ = User.streamReadUserId(streamId)
			local v35_ = g_playerSystem:getPlayerByUserId(v34_)
			if v35_ ~= nil then
				v35_:onEnterVehicleAsPassenger(self, v33_)
			end
		end
	end
end

-- Local values: spec, seatIndex, passengerSeat
function EnterablePassenger:onWriteStream(streamId, connection)
	local v38_ = self.spec_enterablePassenger
	for v39_ = 1, #v38_.passengerSeats do
		local v40_ = v38_.passengerSeats[v39_]
		if streamWriteBool(streamId, v40_.isUsed) then
			User.streamWriteUserId(streamId, v40_.userId)
		end
	end
end

-- Local values: spec, specEnterable
function EnterablePassenger:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v43_ = self.spec_enterablePassenger
	if v43_.available and self.isClient then
		local v44_ = self.spec_enterable
		if v44_.activeCamera ~= nil then
			v44_.activeCamera:update(dt)
		end
		EnterablePassenger.updateActionEvents(self)
		if v43_.passengerEntered then
			self:raiseActive()
		end
		self:updatePassengerSeatCharacter(dt)
	end
end

-- Local values: spec, visible, seatIndex, passengerSeat, distance, x, y, z
function EnterablePassenger:onDrawUIInfo()
	local v46_ = self.spec_enterablePassenger
	if v46_.available then
		local v47_ = not (g_gui:getIsGuiVisible() or g_noHudModeEnabled)
		if v47_ then
			v47_ = g_gameSettings:getValue(GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES)
		end
		if self.isClient and v47_ then
			for v48_ = 1, #v46_.passengerSeats do
				local v49_ = v46_.passengerSeats[v48_]
				if v49_.isUsed and (not v46_.passengerEntered or v48_ ~= v46_.currentSeatIndex) and calcDistanceFrom(v49_.node, getCamera()) < Enterable.NICKNAME_RENDER_DISTANCE then
					local v50_, v51_, v52_ = getWorldTranslation(v49_.node)
					local v53_ = v51_ + v49_.nicknameOffset
					Utils.renderTextAtWorldPosition(v50_, v53_, v52_, self:getPlayerNameBySeatIndex(v48_), getCorrectTextSize(0.02), 0)
				end
			end
		end
	end
end

-- Local values: spec
function EnterablePassenger:onSetBroken()
	if self.spec_enterablePassenger.passengerEntered then
		g_localPlayer:leaveVehicle()
	end
end

-- Local values: spec, seatIndex, spec, _, seat
function EnterablePassenger:onEnterVehicle()
	if EnterablePassenger.DEBUG_ACTIVE then
		for v56_ = 1, #self.spec_enterablePassenger.passengerSeats do
			self:setPassengerSeatCharacter(v56_, self:getUserPlayerStyle())
		end
	end
	local v57_ = self.spec_enterablePassenger
	for _, v58_ in ipairs(v57_.passengerSeats) do
		if v58_.lastUserId == self.spec_enterable.controllerUserId then
			v58_.lastUserId = nil
		end
	end
end

-- Local values: spec, seatIndex
function EnterablePassenger:onLeaveVehicle()
	if EnterablePassenger.DEBUG_ACTIVE then
		for v60_ = 1, #self.spec_enterablePassenger.passengerSeats do
			self:setPassengerSeatCharacter(v60_, nil)
		end
	end
end

-- Local values: spec
function EnterablePassenger:getInteractionHelp(superFunc)
	if self.spec_enterablePassenger.available and self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER then
		return self.spec_enterablePassenger.texts.enterVehiclePassenger
	else
		return superFunc(self)
	end
end

-- Local values: seatIndex
function EnterablePassenger:interact(superFunc, player)
	if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER then
		player:requestToEnterVehicleAsPassenger(self, (self:getClosestSeatIndex(player.rootNode)))
	else
		superFunc(self, player)
	end
end

function EnterablePassenger:getIsInteractive(superFunc)
	if self.isBroken then
		return false
	elseif self:getIsControlled() then
		return self:getCanUsePassengerSeats()
	else
		return superFunc(self)
	end
end

-- Local values: spec
function EnterablePassenger:getIsEnteredForInput(superFunc)
	if superFunc(self) then
		return true
	end
	local v70_ = self.spec_enterablePassenger
	return v70_.available and (v70_.passengerEntered and v70_.allowVehicleControl) and true or false
end

-- Local values: spec, seatIndex, passengerSeat
function EnterablePassenger:getRequiresPower(superFunc)
	if superFunc(self) then
		return true
	end
	local v73_ = self.spec_enterablePassenger
	if v73_.available and v73_.allowVehicleControl then
		for v74_ = 1, #v73_.passengerSeats do
			if v73_.passengerSeats[v74_].isUsed then
				return true
			end
		end
	end
	return false
end

-- Local values: superDistance, seatIndex, distance
function EnterablePassenger:getDistanceToNode(superFunc, node)
	local v78_ = superFunc(self, node)
	if self:getIsControlled() or self.spec_enterablePassenger.allowPassengerOnly then
		local v79_, v80_ = self:getClosestSeatIndex(node)
		if v79_ ~= nil and v80_ < v78_ then
			self.interactionFlag = Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER
			return v80_
		end
	end
	return v78_
end

-- Local values: spec
function EnterablePassenger:getIsEnterable(superFunc)
	if not self.spec_enterablePassenger.available then
		return superFunc(self)
	end
	local v83_ = not self:getCanUsePassengerSeats()
	if v83_ then
		v83_ = superFunc(self)
	end
	return v83_
end

-- Local values: spec, seatIndex, passengerSeat
function EnterablePassenger:getExitNode(superFunc, player)
	local v87_ = self.spec_enterablePassenger
	if v87_.available then
		for v88_ = 1, #v87_.passengerSeats do
			local v89_ = v87_.passengerSeats[v88_]
			if v89_.lastUserId == player.userId then
				return v89_.exitPoint
			end
		end
	end
	return superFunc(self, player)
end

-- Local values: spec, seatIndex, passengerSeat
function EnterablePassenger:getIsInUse(superFunc, connection)
	local v93_ = self.spec_enterablePassenger
	if v93_.available then
		for v94_ = 1, #v93_.passengerSeats do
			if v93_.passengerSeats[v94_].isUsed then
				return true
			end
		end
	end
	return superFunc(self, connection)
end

-- Local values: spec, seatIndex, passengerSeat
function EnterablePassenger:getDeactivateOnLeave(superFunc, connection)
	local v98_ = self.spec_enterablePassenger
	if v98_.available then
		for v99_ = 1, #v98_.passengerSeats do
			if v98_.passengerSeats[v99_].isUsed then
				return false
			end
		end
	end
	return superFunc(self, connection)
end

-- Local values: spec
function EnterablePassenger:onPreRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	local v101_ = self.spec_enterablePassenger
	if v101_.available then
		self:clearActionEventsTable(v101_.actionEvents)
	end
end

-- Local values: spec, actionEventId, _, currentSeat, _, actionEventId
function EnterablePassenger:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	local v103_ = self.spec_enterablePassenger
	if v103_.available then
		if v103_.passengerEntered then
			g_localPlayer.inputComponent:registerGlobalPlayerActionEvents(Vehicle.INPUT_CONTEXT_NAME)
			local _, v104_ = self:addActionEvent(v103_.actionEvents, InputAction.ENTER, self, EnterablePassenger.actionEventLeave, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v104_, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventTextVisibility(v104_, false)
			local v105_ = v103_.passengerSeats[v103_.currentSeatIndex]
			if v105_ ~= nil and #v105_.cameras > 0 then
				local _, v106_ = self:addActionEvent(v103_.actionEvents, InputAction.CAMERA_SWITCH, self, EnterablePassenger.actionEventCameraSwitch, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v106_, GS_PRIO_LOW)
				g_inputBinding:setActionEventTextVisibility(v106_, true)
			end
			local _, v107_ = self:addActionEvent(v103_.actionEvents, InputAction.CAMERA_ZOOM_IN_OUT, self, Enterable.actionEventCameraZoomInOut, false, true, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v107_, GS_PRIO_LOW)
			g_inputBinding:setActionEventTextVisibility(v107_, false)
			local _, v108_ = self:addActionEvent(v103_.actionEvents, InputAction.SWITCH_SEAT, self, EnterablePassenger.actionEventSwitchSeat, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v108_, GS_PRIO_HIGH)
		elseif self:getIsEntered() and self:getIsActiveForInput(true, true) then
			local _, v109_ = self:addActionEvent(v103_.actionEvents, InputAction.SWITCH_SEAT, self, EnterablePassenger.actionEventSwitchSeat, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v109_, GS_PRIO_HIGH)
		end
		EnterablePassenger.updateActionEvents(self)
	end
end

-- Local values: spec
function EnterablePassenger:actionEventLeave(actionName, inputValue, callbackState, isAnalog, isMouse)
	if self.spec_enterablePassenger.passengerEntered then
		g_localPlayer:leaveVehicle()
	end
end

-- Local values: spec
function EnterablePassenger:actionEventCameraSwitch(actionName, inputValue, callbackState, isAnalog, isMouse)
	if self.spec_enterablePassenger.passengerEntered then
		self:setPassengerActiveCameraIndex()
	end
end

-- Local values: spec, nextSeatIndex, seatIndex
function EnterablePassenger:actionEventSwitchSeat(actionName, inputValue, callbackState, isAnalog, isMouse)
	local v113_ = self.spec_enterablePassenger
	if v113_.passengerEntered then
		local v114_ = self:getFirstAvailablePassengerSeat(v113_.currentSeatIndex)
		if v114_ ~= nil then
			self:copyEnterableActiveCameraIndex(v114_)
			g_localPlayer:requestToEnterVehicleAsPassenger(self, v114_)
			return
		end
		if not self:getIsControlled() and g_currentMission.accessHandler:canPlayerAccess(self) then
			self:copyEnterableActiveCameraIndex()
			g_localPlayer:requestToEnterVehicle(self)
			return
		end
	end
	local v115_ = self:getFirstAvailablePassengerSeat()
	if v115_ ~= nil then
		self:copyEnterableActiveCameraIndex(v115_)
		g_localPlayer:requestToEnterVehicleAsPassenger(self, v115_)
	end
end

-- Local values: spec, switchSeatEvent, isActive, nextSeatIndex, seatIndex
function EnterablePassenger:updateActionEvents()
	local v117_ = self.spec_enterablePassenger
	local v118_ = v117_.actionEvents[InputAction.SWITCH_SEAT]
	if v118_ ~= nil then
		local v119_ = false
		if v117_.passengerEntered then
			if self:getFirstAvailablePassengerSeat(v117_.currentSeatIndex) == nil then
				if not self:getIsControlled() and g_currentMission.accessHandler:canPlayerAccess(self) then
					g_inputBinding:setActionEventText(v118_.actionEventId, v117_.texts.switchSeatDriver)
					v119_ = true
				end
			else
				g_inputBinding:setActionEventText(v118_.actionEventId, v117_.texts.switchNextSeat)
				v119_ = true
			end
		end
		if not v119_ and self:getFirstAvailablePassengerSeat() ~= nil then
			g_inputBinding:setActionEventText(v118_.actionEventId, v117_.texts.switchSeatPassenger)
			v119_ = true
		end
		g_inputBinding:setActionEventActive(v118_.actionEventId, v119_)
	end
end

-- Local values: spec, minDistance, minIndex, i, passengerSeat, distance
function EnterablePassenger:getClosestSeatIndex(playerNode)
	local v122_ = self.spec_enterablePassenger
	local v123_ = math.huge
	local v124_ = nil
	for v125_ = 1, #v122_.passengerSeats do
		local v126_ = v122_.passengerSeats[v125_]
		if self:getIsPassengerSeatAvailable(v126_) then
			local v127_ = calcDistanceFrom(playerNode, v126_.node)
			if v127_ < v122_.minEnterDistance and v127_ < v123_ then
				v124_ = v125_
				v123_ = v127_
			end
		end
	end
	return v124_, v123_
end

function EnterablePassenger:getIsPassengerSeatAvailable(passengerSeat)
	return not passengerSeat.isUsed
end

-- Local values: spec, passengerSeat
function EnterablePassenger:getIsPassengerSeatIndexAvailable(seatIndex)
	local v131_ = self.spec_enterablePassenger.passengerSeats[seatIndex]
	if v131_ == nil then
		return false
	else
		return self:getIsPassengerSeatAvailable(v131_)
	end
end

-- Local values: spec, i, passengerSeat
function EnterablePassenger:getFirstAvailablePassengerSeat(startIndex)
	local v134_ = self.spec_enterablePassenger
	for v135_ = startIndex or 1, #v134_.passengerSeats do
		if self:getIsPassengerSeatAvailable(v134_.passengerSeats[v135_]) then
			return v135_
		end
	end
	return nil
end

-- Local values: spec, passengerSeat, user
function EnterablePassenger:getPlayerNameBySeatIndex(seatIndex)
	local v138_ = self.spec_enterablePassenger.passengerSeats[seatIndex]
	if v138_ ~= nil then
		local v139_ = g_currentMission.userManager:getUserByUserId(v138_.userId)
		if v139_ ~= nil then
			return v139_:getNickname()
		end
	end
	return ""
end

function EnterablePassenger:getCanUsePassengerSeats()
	if self.isBroken then
		return false
	else
		return self:getIsControlled() and true or not g_currentMission.accessHandler:canPlayerAccess(self)
	end
end

-- Local values: spec, index, seat, isEmpty, i, currentSeat, otherSeatIndex, otherSeat
function EnterablePassenger:enterVehiclePassengerSeat(isOwner, seatIndex, playerStyle, userId)
	local v146_ = self.spec_enterablePassenger
	if isOwner then
		if v146_.passengerEntered then
			self:leaveLocalPassengerSeat(true)
		end
		v146_.currentSeatIndex = seatIndex
		v146_.passengerEntered = true
		self:enablePassengerActiveCamera()
		self:setPassengerSeatCharacter(seatIndex, playerStyle)
		if self.spec_enterable.playerHotspot ~= nil then
			self.spec_enterable.playerHotspot:setOwnerFarmId(g_currentMission:getFarmId())
			g_currentMission:addMapHotspot(self.spec_enterable.playerHotspot)
		end
		if self.isClient then
			g_messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.requestActionEventUpdate, self)
			self:requestActionEventUpdate()
		end
	else
		for v147_, v148_ in ipairs(v146_.passengerSeats) do
			if v148_.isUsed and v148_.userId == userId then
				self:leavePassengerSeat(false, v147_)
				break
			end
		end
		self:setPassengerSeatCharacter(seatIndex, playerStyle)
	end
	local v149_ = true
	for v150_ = 1, #v146_.passengerSeats do
		if v146_.passengerSeats[v150_].isUsed then
			v149_ = false
			break
		end
	end
	if v149_ and not self:getIsControlled() then
		self:activate()
	end
	local v151_ = v146_.passengerSeats[seatIndex]
	if v151_ ~= nil then
		v151_.isUsed = true
		v151_.playerStyle = playerStyle
		v151_.userId = userId
		v151_.lastUserId = userId
		for v152_, v153_ in ipairs(v146_.passengerSeats) do
			if v152_ ~= seatIndex and v153_.lastUserId == userId then
				v153_.lastUserId = nil
			end
		end
	end
end

-- Local values: spec
function EnterablePassenger:leaveLocalPassengerSeat(noEventSend)
	local v156_ = self.spec_enterablePassenger
	if v156_.passengerEntered then
		if noEventSend ~= true then
			g_client:getServerConnection():sendEvent(EnterablePassengerLeaveEvent.new(self, g_localPlayer.userId))
		end
		self:leavePassengerSeat(true, v156_.currentSeatIndex)
	end
end

-- Local values: spec, specEnterable, currentSeat, isEmpty, i
function EnterablePassenger:leavePassengerSeat(isOwner, seatIndex)
	local v160_ = self.spec_enterablePassenger
	if isOwner then
		local v161_ = self.spec_enterable
		if v161_.activeCamera ~= nil and v160_.passengerEntered then
			v161_.activeCamera:onDeactivate()
			g_soundManager:setIsIndoor(false)
			g_currentMission.ambientSoundSystem:setIsIndoor(false)
			g_currentMission.environment.environmentMaskSystem:setIsIndoor(false)
			g_currentMission.activatableObjectsSystem:deactivate(Vehicle.INPUT_CONTEXT_NAME)
			v161_.activeCamera = nil
		end
		self:setMirrorVisible(false)
		self:setPassengerSeatCharacter(seatIndex, nil)
		v160_.currentSeatIndex = 1
		v160_.passengerEntered = false
		if self.spec_enterable.playerHotspot ~= nil then
			g_currentMission:removeMapHotspot(self.spec_enterable.playerHotspot)
		end
		if self.isClient then
			g_messageCenter:unsubscribe(MessageType.INPUT_BINDINGS_CHANGED, self)
			self:requestActionEventUpdate()
			if g_touchHandler ~= nil then
				g_touchHandler:removeGestureListener(self.touchListenerDoubleTab)
			end
		end
	else
		self:setPassengerSeatCharacter(seatIndex, nil)
	end
	local v162_ = v160_.passengerSeats[seatIndex]
	if v162_ ~= nil then
		v162_.isUsed = false
		v162_.playerStyle = nil
		v162_.userId = nil
	end
	if not self:getIsControlled() then
		local v163_ = true
		for v164_ = 1, #v160_.passengerSeats do
			if v160_.passengerSeats[v164_].isUsed then
				v163_ = false
				break
			end
		end
		if v163_ then
			self:deactivate()
		end
	end
end

-- Local values: spec, i
function EnterablePassenger:getPassengerSeatIndexByPlayer(userId)
	local v167_ = self.spec_enterablePassenger
	for v168_ = 1, #v167_.passengerSeats do
		if v167_.passengerSeats[v168_].userId == userId then
			return v168_
		end
	end
	return nil
end

-- Local values: spec, specEnterable, passengerSeat, foundCamera, camIndex, camera, camIndex, camera, passengerSeat, foundCamera, camIndex, camera, camIndex, camera
function EnterablePassenger:copyEnterableActiveCameraIndex(seatIndex)
	local v171_ = self.spec_enterablePassenger
	local v172_ = self.spec_enterable
	if v172_.activeCamera ~= nil then
		if seatIndex == nil then
			if v171_.passengerSeats[v171_.currentSeatIndex] ~= nil then
				local v173_ = false
				for v174_ = 1, #v172_.cameras do
					if v172_.cameras[v174_] == v172_.activeCamera then
						v172_.camIndex = v174_
						v173_ = true
					end
				end
				if not v173_ then
					for v175_ = 1, #v172_.cameras do
						if v172_.cameras[v175_].isInside == v172_.activeCamera.isInside then
							v172_.camIndex = v175_
							return
						end
					end
				end
			end
		else
			local v176_ = v171_.passengerSeats[seatIndex]
			if v176_ ~= nil then
				local v177_ = false
				for v178_ = 1, #v176_.cameras do
					if v176_.cameras[v178_] == v172_.activeCamera then
						v176_.camIndex = v178_
						v177_ = true
					end
				end
				if not v177_ then
					for v179_ = 1, #v176_.cameras do
						if v176_.cameras[v179_].isInside == v172_.activeCamera.isInside then
							v176_.camIndex = v179_
							return
						end
					end
					return
				end
			end
		end
	end
end

-- Local values: spec, currentSeat
function EnterablePassenger:setPassengerActiveCameraIndex(cameraIndex, seatIndex)
	local v183_ = self.spec_enterablePassenger
	local v184_ = v183_.passengerSeats[seatIndex or v183_.currentSeatIndex]
	if v184_ ~= nil then
		v184_.camIndex = cameraIndex or v184_.camIndex + 1
		if v184_.camIndex > #v184_.cameras then
			v184_.camIndex = 1
		end
	end
	self:enablePassengerActiveCamera()
end

-- Local values: spec, specEnterable, currentSeat, activeCamera
function EnterablePassenger:enablePassengerActiveCamera()
	local v186_ = self.spec_enterablePassenger
	local v187_ = self.spec_enterable
	if v187_.activeCamera ~= nil then
		v187_.activeCamera:onDeactivate()
	end
	local v188_ = v186_.passengerSeats[v186_.currentSeatIndex]
	if v188_ ~= nil then
		local v189_ = v188_.cameras[v188_.camIndex]
		v187_.activeCamera = v189_
		v187_.activeCamera:onActivate()
		self:setMirrorVisible(v189_.useMirror)
		g_currentMission.environmentAreaSystem:setReferenceNode(v189_.cameraNode)
	end
	self:updatePassengerSeatCharacter(99999)
	self:raiseActive()
end

-- Local values: spec, currentSeat
function EnterablePassenger:setPassengerSeatCharacter(seatIndex, playerStyle)
	local v193_ = self.spec_enterablePassenger.passengerSeats[seatIndex]
	if v193_ ~= nil and v193_.vehicleCharacter ~= nil then
		v193_.vehicleCharacter:unloadCharacter()
		if playerStyle ~= nil then
			v193_.vehicleCharacter:loadCharacter(playerStyle, self, EnterablePassenger.vehiclePassengerCharacterLoaded, { v193_ })
		end
	end
end

-- Local values: spec, _, seat
function EnterablePassenger:updatePassengerSeatCharacter(dt)
	local v196_ = self.spec_enterablePassenger
	for _, v197_ in ipairs(v196_.passengerSeats) do
		if v197_.isUsed and v197_.vehicleCharacter ~= nil then
			v197_.vehicleCharacter:updateVisibility()
			v197_.vehicleCharacter:update(dt)
		end
	end
end

-- Local values: spec, seatIndex, passengerSeat
function EnterablePassenger:onPassengerPlayerStyleChanged(style, userId)
	local v201_ = self.spec_enterablePassenger
	for v202_ = 1, #v201_.passengerSeats do
		if v201_.passengerSeats[v202_].userId == userId then
			self:setPassengerSeatCharacter(v202_, style)
		end
	end
end

-- Local values: currentSeat
function EnterablePassenger:vehiclePassengerCharacterLoaded(loadingState, arguments)
	if loadingState == HumanModelLoadingState.OK then
		local v205_ = arguments[1]
		if v205_ ~= nil then
			v205_.vehicleCharacter:updateVisibility()
			v205_.vehicleCharacter:updateIKChains()
			if EnterablePassenger.DEBUG_ACTIVE then
				v205_.vehicleCharacter:setCharacterVisibility(true)
			end
		end
	end
end
function EnterablePassenger.consoleCommandDebugPassengerSeat()
	EnterablePassenger.DEBUG_ACTIVE = not EnterablePassenger.DEBUG_ACTIVE
	local v206_ = g_localPlayer:getCurrentVehicle()
	if v206_ ~= nil and v206_.spec_enterablePassenger ~= nil then
		if EnterablePassenger.DEBUG_ACTIVE then
			for v207_ = 1, #v206_.spec_enterablePassenger.passengerSeats do
				v206_:setPassengerSeatCharacter(v207_, v206_:getUserPlayerStyle())
			end
		else
			for v208_ = 1, #v206_.spec_enterablePassenger.passengerSeats do
				v206_:setPassengerSeatCharacter(v208_, nil)
			end
		end
	end
	local v209_ = Logging.info
	local v210_ = EnterablePassenger.DEBUG_ACTIVE
	v209_("Passenger Seat Debug: %s", (tostring(v210_)))
end
addConsoleCommand("gsVehicleDebugPassengerSeats", "Enables debugging for passenger seat character targets", "consoleCommandDebugPassengerSeat", EnterablePassenger)
