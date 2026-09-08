-- Local values: SleepManager_mt
SleepManager = {}
SleepManager.INPUT_CONTEXT_NAME = "SLEEPING"
SleepManager.SLEEPING_TIME_SCALE = 5000
SleepManager.TIME_TO_ANSWER_REQUEST = 20000
SleepManager.TIME_TO_NEXT_REQUEST = 20000
SleepManager.NUM_SLEEP_ANIMATION_STATES = 16
SleepManager.ANIMATION_SLICE_ID = "gui.sleep"
local SleepManager_mt = Class(SleepManager, AbstractManager)

-- Upvalues: SleepManager_mt
-- Local values: self
function SleepManager.new(customMt)
	-- upvalues: (copy) SleepManager_mt
	local v3_ = AbstractManager.new(customMt or SleepManager_mt)
	v3_.isSleeping = false
	v3_.wakeUpTime = 0
	v3_.previousCamera = nil
	v3_.previousInputContext = nil
	v3_.fallbackCamera = nil
	v3_.isRequestPending = false
	v3_.requestAnswer = true
	v3_.requestedTime = 0
	v3_.requestedTargetTime = 0
	v3_.curerntSleepAnimationState = SleepManager.NUM_SLEEP_ANIMATION_STATES
	return v3_
end

-- Local values: width, height, xOffset, yOffset
function SleepManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	local v5_, v6_ = getNormalizedScreenValues(128, 128)
	self.animationNumFrames = 16
	self.animationTimer = 0
	self.animationSpeed = 50
	self.animationOffset = 0
	self.animationFrameSize = 128
	self.animationRefSize = { 2048, 128 }
	local v7_, v8_ = getNormalizedScreenValues(-4, 0)
	self.animationOverlay = g_overlayManager:createOverlay(SleepManager.ANIMATION_SLICE_ID, 0.5 + v7_, 0.5 + v8_, v5_, v6_)
	self.animationOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	self.animationOverlay:setColor(0.22323, 0.40724, 0.00368, 1)
	local v9_, v10_ = getNormalizedScreenValues(200, 200)
	self.animationBackgroundOverlay = Overlay.new("dataS/menu/hud/ui_elements.png", 0.5, 0.5, v9_, v10_)
	self.animationBackgroundOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	self.animationBackgroundOverlay:setUVs(GuiUtils.getUVs({
		294,
		390,
		100,
		100
	}, { 1024, 1024 }))
	self.animationBackgroundOverlay:setColor(0, 0, 0, 0.75)
	g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
end

function SleepManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
	if self.fallbackCamera ~= nil then
		g_cameraManager:removeCamera(self.fallbackCamera)
		delete(self.fallbackCamera)
		self.fallbackCamera = nil
	end
	if self.animationOverlay ~= nil then
		self.animationOverlay:delete()
		self.animationOverlay = nil
	end
	if self.animationBackgroundOverlay ~= nil then
		self.animationBackgroundOverlay:delete()
		self.animationBackgroundOverlay = nil
	end
end

-- Local values: sleepAnimationSliceId
function SleepManager:update(dt)
	if g_currentMission:getIsServer() then
		if self.wakeUpTime < g_currentMission.time and self.isSleeping then
			self:stopSleep()
		end
		if self.isRequestPending then
			if #self.userRequestIds == 0 then
				if self.requestAnswer then
					self:startSleep(self.requestedTargetTime)
					self:resetRequest()
				else
					g_server:broadcastEvent(SleepRequestDeniedEvent.new(self.requestDeniedUserId), g_dedicatedServer == nil)
					self:resetRequest()
				end
			elseif self.requestedTime + SleepManager.TIME_TO_ANSWER_REQUEST < g_currentMission.time then
				g_server:broadcastEvent(SleepRequestTimeoutEvent.new(), false)
				self:resetRequest()
			end
		end
	end
	if self.isSleeping then
		self.animationTimer = self.animationTimer - dt
		if self.animationTimer < 0 then
			self.animationTimer = self.animationSpeed
			self.animationOffset = self.animationOffset + 1
			if self.animationOffset > self.animationNumFrames - 1 then
				self.animationOffset = 0
			end
			self.curerntSleepAnimationState = self.curerntSleepAnimationState + 1
			if self.curerntSleepAnimationState > SleepManager.NUM_SLEEP_ANIMATION_STATES then
				self.curerntSleepAnimationState = 1
			end
			local v14_ = SleepManager.ANIMATION_SLICE_ID
			if self.curerntSleepAnimationState < 10 then
				v14_ = v14_ .. "0" .. self.curerntSleepAnimationState
			elseif self.curerntSleepAnimationState < SleepManager.NUM_SLEEP_ANIMATION_STATES then
				v14_ = v14_ .. self.curerntSleepAnimationState
			end
			self.animationOverlay:setSliceId(v14_)
		end
	end
end

function SleepManager:draw()
	if self.isSleeping and not g_currentMission.paused then
		if self.animationBackgroundOverlay ~= nil then
			self.animationBackgroundOverlay:render()
		end
		if self.animationOverlay ~= nil then
			self.animationOverlay:render()
		end
	end
end

-- Local values: k, id
function SleepManager:onUserRemoved(user)
	if self.isRequestPending then
		for v18_, v19_ in ipairs(self.userRequestIds) do
			if v19_ == user:getId() then
				table.remove(self.userRequestIds, v18_)
				return
			end
		end
	end
end

function SleepManager:getCanSleep()
	return not self.isSleeping
end

function SleepManager:getIsSleeping()
	return self.isSleeping
end

function SleepManager:onSleepNotAllowed()
	InfoDialog.cancel()
	InfoDialog.show(g_i18n:getText("ui_inGameSleepNotAllowed"), nil, self, DialogElement.TYPE_WARNING)
end

-- Local values: nickname, user
function SleepManager:onSleepRequestDenied(userId)
	local v25_ = ""
	if userId > 0 then
		local v26_ = g_currentMission.userManager:getUserByUserId(userId)
		if v26_ ~= nil then
			v25_ = string.format(" (%s)", v26_:getNickname())
		end
	end
	InfoDialog.cancel()
	InfoDialog.show(g_i18n:getText("ui_inGameSleepRequestDenied") .. v25_, nil, self, DialogElement.TYPE_WARNING)
end

function SleepManager:onSleepRequestTimeout()
	if self.isSleepRequestAnswerPending then
		YesNoDialog.cancel()
	end
	InfoDialog.show(g_i18n:getText("ui_inGameSleepRequestTimeout"), nil, self, DialogElement.TYPE_WARNING)
end

function SleepManager:onSleepRequestPending()
	InfoDialog.cancel()
	InfoDialog.show(g_i18n:getText("ui_inGameSleepRequestPending"), nil, self, DialogElement.TYPE_WARNING)
end

-- Local values: user, name
function SleepManager:onSleepRequest(userId, targetTime)
	local v31_ = g_currentMission.userManager:getUserByUserId(userId)
	local v32_ = v31_ == nil and "Unknown" or v31_:getNickname()
	self.isSleepRequestAnswerPending = true
	YesNoDialog.show(self.onSleepRequestYesNo, self, string.format(g_i18n:getText("ui_inGameSleepRequest"), v32_))
end

function SleepManager:onSleepRequestYesNo(yesNo)
	self.isSleepRequestAnswerPending = false
	g_client:getServerConnection():sendEvent(SleepResponseEvent.new(yesNo))
end

-- Local values: userId, k, id
function SleepManager:onSleepResponse(connection, answer)
	local v38_ = g_currentMission:getIsServer()
	assert(v38_, "SleepManager:onSleepResponse is a server-only function")
	if self.isRequestPending then
		self.requestAnswer = self.requestAnswer and answer
		local v39_ = g_currentMission.userManager:getUserIdByConnection(connection)
		if not answer and self.requestDeniedUserId == nil then
			self.requestDeniedUserId = v39_
		end
		if v39_ ~= nil then
			for v40_, v41_ in ipairs(self.userRequestIds) do
				if v41_ == v39_ then
					table.remove(self.userRequestIds, v40_)
					return
				end
			end
		end
	end
end

-- Local values: text
function SleepManager:showDialog()
	if self:getCanSleep() then
		local v43_ = g_i18n:getText("ui_inGameSleepTargetTime") .. "\n" .. g_i18n:getText("ui_currentTime") .. ": " .. g_i18n:formatCurrentTime()
		SleepDialog.show(v43_, self.sleepDialogYesNo, self)
	else
		InfoDialog.cancel()
		InfoDialog.show(g_i18n:getText("ui_inGameSleepWrongTime"), nil, nil, DialogElement.TYPE_WARNING)
	end
end

function SleepManager:sleepDialogYesNo(yes, targetTime)
	if yes then
		if g_currentMission:getIsServer() then
			self:startSleepRequest(g_currentMission.playerUserId, targetTime)
			return
		end
		g_client:getServerConnection():sendEvent(SleepRequestEvent.new(g_currentMission.playerUserId, targetTime))
	end
end

-- Local values: user, userConnection, isInCoolDownPhase, connections, _, otherUser
function SleepManager:startSleepRequest(userId, targetTime)
	local v50_ = g_currentMission:getIsServer()
	assert(v50_, "SleepManager:startSleepRequest is a server-only function")
	local v51_ = g_currentMission.userManager:getUserByUserId(userId)
	local v52_
	if v51_ == nil then
		v52_ = nil
	else
		v52_ = v51_:getConnection()
	end
	if self.isRequestPending then
		if v52_ ~= nil then
			v52_:sendEvent(SleepRequestPendingEvent.new())
		end
		return
	else
		local _ = self.requestedTime + SleepManager.TIME_TO_NEXT_REQUEST > g_currentMission.time
		if self:getCanSleep() then
			self.isRequestPending = true
			self.requestedTime = g_currentMission.time
			self.requestedTargetTime = targetTime
			self.requestAnswer = true
			self.userRequestIds = {}
			local v53_ = {}
			for _, v54_ in ipairs(g_currentMission.userManager:getUsers()) do
				if v54_:getId() ~= userId and (g_dedicatedServer == nil or v54_:getId() ~= g_currentMission:getServerUserId()) and v54_:getState() == FSBaseMission.USER_STATE_INGAME then
					local v55_ = self.userRequestIds
					table.insert(v55_, v54_:getId())
					table.insert(v53_, v54_:getConnection())
				end
			end
			g_server:broadcastEvent(SleepRequestEvent.new(userId, targetTime), g_dedicatedServer == nil, v52_, nil, nil, v53_)
		elseif v52_ ~= nil then
			v52_:sendEvent(SleepNotAllowedEvent.new())
		end
	end
end

function SleepManager:resetRequest()
	self.isRequestPending = false
	self.requestedTargetTime = 0
	self.requestAnswer = true
	self.requestDeniedUserId = nil
end

-- Local values: currentHour, duration, sleepCamera, x, y, z
function SleepManager:startSleep(targetTime)
	g_currentMission.environment.weather.cloudUpdater:setSlowModeEnabled(true)
	if g_currentMission:getIsServer() then
		local v59_ = targetTime * 1000 * 60 * 60
		local v60_ = (v59_ - (g_currentMission.environment.dayTime + 1)) % 86400000
		self.wakeUpTime = g_currentMission.time + v60_ / SleepManager.SLEEPING_TIME_SCALE
		self.startTimeScale = g_currentMission.missionInfo.timeScale
		g_currentMission:setTimeScale(SleepManager.SLEEPING_TIME_SCALE)
		g_currentMission:setTimeScaleMultiplier(1)
		g_server:broadcastEvent(StartSleepStateEvent.new(v59_), false)
	end
	self.isSleeping = true
	g_currentMission.hud:setIsVisible(false)
	g_currentMission.isPlayerFrozen = true
	g_inputBinding:setContext(SleepManager.INPUT_CONTEXT_NAME, true)
	self.previousCamera = g_cameraManager:getActiveCamera()
	local v61_ = self:getSleepCamera()
	if v61_ ~= nil then
		local v62_, v63_, v64_ = getWorldTranslation(v61_)
		local v65_ = getTerrainHeightAtWorldPos(g_terrainNode, v62_, v63_, v64_) + 60
		local v66_ = math.max(v65_, v63_)
		setWorldTranslation(v61_, v62_, v66_, v64_)
		setWorldRotation(v61_, 1.3962634015954636, 0, 0)
		g_cameraManager:setActiveCamera(v61_)
	end
	g_messageCenter:publish(MessageType.SLEEPING, true)
end

-- Local values: localPlayer
function SleepManager:stopSleep()
	g_currentMission.environment.weather.cloudUpdater:setSlowModeEnabled(false)
	if g_currentMission:getIsServer() then
		g_currentMission:setTimeScale(self.startTimeScale)
		g_server:broadcastEvent(StopSleepStateEvent.new(), false)
	end
	local v68_ = g_localPlayer
	if self.previousCamera == nil or not entityExists(self.previousCamera) then
		if v68_ ~= nil then
			g_cameraManager:setActiveCamera(v68_:getCurrentCameraNode())
		end
	else
		g_cameraManager:setActiveCamera(self.previousCamera)
	end
	self.previousCamera = nil
	if g_inputBinding:getContextName() == SleepManager.INPUT_CONTEXT_NAME then
		g_inputBinding:revertContext(true)
	end
	g_currentMission.isPlayerFrozen = false
	g_currentMission.hud:setIsVisible(true)
	self.isSleeping = false
	g_messageCenter:publish(MessageType.SLEEPING, false)
end

function SleepManager:getSleepCamera()
	return g_farmManager:getSleepCamera(g_localPlayer:getFarmId()) or self:getFallbackCamera()
end

function SleepManager:getFallbackCamera()
	if self.fallbackCamera == nil then
		self.fallbackCamera = createCamera("sleepingFallbackCamera", 1.0471975511965976, 1, 10000)
		link(getRootNode(), self.fallbackCamera)
		g_cameraManager:addCamera(self.fallbackCamera, nil, false)
	end
	return self.fallbackCamera
end
g_sleepManager = SleepManager.new()
