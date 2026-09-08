-- Local values: StartupScreen_mt
StartupScreen = {
	["EVENTTYPE_VIDEO"] = 1,
	["EVENTTYPE_PICTURE"] = 2
}
local StartupScreen_mt = Class(StartupScreen, ScreenElement)
function StartupScreen.register()
	local v2_ = StartupScreen.new()
	g_gui:loadGui("dataS/gui/StartupScreen.xml", "StartupScreen", v2_)
	return v2_
end

-- Upvalues: StartupScreen_mt
-- Local values: self
function StartupScreen.new(target)
	-- upvalues: (copy) StartupScreen_mt
	return FrameElement.new(target, StartupScreen_mt)
end

function StartupScreen:onClose()
	self.videoElement:disposeVideo()
	self.pictureElement:setImageFilename(nil)
	self.pictureTimer = nil
	self.eventList = nil
	self.currentEventId = nil
	g_gameStateManager:setGameState(GameState.MENU_MAIN)
end

function StartupScreen:onOpen()
	self.eventList = {}
	if not (StartParams.getIsSet("skipStartVideos") or g_isDevelopmentVersion and Platform.isPC) then
		if Platform.showVideoGIANTS then
			self:addStartupVideo("de en cz pl fr es jp ru hu it cs ct nl pt br tr ro kr ea da fi no sv fc", "dataS/videos/GIANTSLogo.ogv", 1, false, { 1, 0.5625 })
		end
		if Platform.showVideoFS then
			self:addStartupVideo("de en cz pl fr es jp ru hu it cs ct nl pt br tr ro kr ea da fi no sv fc", "dataS/videos/FS25Trailer.ogv", 0.25, false, { 1, 0.5625 })
		end
	end
	self.currentEventId = 0
	self:showNextEvent()
end

-- Local values: videoEvent
function StartupScreen:addStartupVideo(languagesString, filename, volume, isFullscreen, size)
	if self:shouldAddEvent(languagesString) then
		local v12_ = {
			["filename"] = filename,
			["volume"] = volume,
			["fullscreen"] = isFullscreen,
			["size"] = size,
			["eventType"] = StartupScreen.EVENTTYPE_VIDEO
		}
		local v13_ = self.eventList
		table.insert(v13_, v12_)
	end
end

-- Local values: pictureEvent
function StartupScreen:addStartupPicture(languagesString, filename, duration)
	if self:shouldAddEvent(languagesString) then
		local v18_ = {
			["filename"] = filename,
			["duration"] = duration,
			["eventType"] = StartupScreen.EVENTTYPE_PICTURE
		}
		local v19_ = self.eventList
		table.insert(v19_, v18_)
	end
end

-- Local values: languages
function StartupScreen:shouldAddEvent(languagesString)
	return (Platform.isConsole or not languagesString) and true or table.toSet(languagesString:split(" "))[g_languageShort] ~= nil
end

function StartupScreen:onVideoElementCreated(videoElement)
	self.videoElement = videoElement
	function self.videoElement.mouseEvent() end
	function self.videoElement.keyEvent() end
	function self.videoElement.inputEvent() end
	self.videoElementCallback = videoElement.onEndVideoCallback
	self.videoElement:setVisible(false)
end

function StartupScreen:onPictureElementCreated(pictureElement)
	self.pictureElement = pictureElement
	self.pictureElement:setVisible(false)
end

-- Local values: nextEvent
function StartupScreen:showNextEvent()
	self.currentEventId = self.currentEventId + 1
	local v26_ = self.eventList[self.currentEventId]
	if v26_ then
		if v26_.eventType == StartupScreen.EVENTTYPE_VIDEO then
			self.videoElement:setVisible(true)
			self.videoElement.onEndVideoCallback = self.videoElementCallback
			self.pictureElement:setVisible(false)
			self:playVideo(v26_)
		else
			self.pictureElement:setVisible(true)
			self.videoElement:setVisible(false)
			self.videoElement.onEndVideoCallback = nil
			self:showPicture(v26_)
		end
	else
		self:onStartupEnd()
		return
	end
end

-- Local values: adjustedVideoSizeX, adjustedVideoSizeY, adjustedVideoPositionX, adjustedVideoPositionY, x, y, aspectRatio
function StartupScreen:playVideo(videoEvent)
	self.videoElement:changeVideo(videoEvent.filename, videoEvent.volume)
	local v29_, v30_, v31_, v32_
	if videoEvent.fullscreen then
		v29_ = 1
		v30_ = 1
		v31_ = 0
		v32_ = 0
	else
		local v33_, v34_ = getScreenModeInfo(getScreenMode())
		local v35_ = v33_ / v34_
		v29_ = videoEvent.size[1]
		v30_ = videoEvent.size[2] * v35_
		v31_ = 0.5 * (1 - v29_)
		v32_ = 0.5 * (1 - v30_)
	end
	self.videoElement:setSize(v29_, v30_)
	self.videoElement:setPosition(v31_, v32_)
	self.videoElement:playVideo()
	return true
end

function StartupScreen:showPicture(pictureEvent)
	self.pictureElement:setImageFilename(pictureEvent.filename)
	self.pictureTimer = addTimer(pictureEvent.duration, "onStartupEndEvent", self)
end

-- Local values: anyButtonPressed, d, i, isDown
function StartupScreen:update(dt)
	StartupScreen:superClass().update(self, dt)
	if not isGameFullyInstalled() then
		return
	end
	local v40_ = false
	for v41_ = 1, getNumOfGamepads() do
		for v42_ = 1, Input.MAX_NUM_BUTTONS do
			if getInputButton(v42_ - 1, v41_ - 1) > 0 then
				v40_ = true
				break
			end
		end
	end
	if not v40_ then
		self.handledButtonPress = false
	end
	if not self.handledButtonPress and v40_ then
		self.handledButtonPress = true
		self:cancelCurrentEvent()
	end
end
function StartupScreen.mouseEvent(p43_, _, _, p44_, _, _)
	if p44_ then
		p43_:cancelCurrentEvent()
	end
end

function StartupScreen:touchEvent(posX, posY, isDown, isUp, touchId)
	if isDown then
		self:cancelCurrentEvent()
	end
end
function StartupScreen.keyEvent(p47_, _, _, _, p48_)
	if p48_ then
		p47_:cancelCurrentEvent()
	end
end

-- Local values: currentEvent
function StartupScreen:cancelCurrentEvent()
	if self.eventList[self.currentEventId].eventType == StartupScreen.EVENTTYPE_VIDEO then
		self.videoElement:stopVideo()
	else
		removeTimer(self.pictureTimer)
	end
	self:onStartupEndEvent()
end

function StartupScreen:onStartupEndEvent()
	self.pictureTimer = nil
	self:showNextEvent()
end

function StartupScreen:onStartupEnd()
	if Platform.needsSignIn then
		g_gui:showGui("GamepadSigninScreen")
	else
		g_gui:showGui("MainScreen")
	end
end

function StartupScreen:exposeControlsAsFields() end
