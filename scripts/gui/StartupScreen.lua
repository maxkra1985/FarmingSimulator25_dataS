StartupScreen = { EVENTTYPE_VIDEO = 1, EVENTTYPE_PICTURE = 2 }
local StartupScreen_mt = Class(StartupScreen, ScreenElement)
function StartupScreen.register()
	local startupScreen = StartupScreen.new()
	g_gui:loadGui("dataS/gui/StartupScreen.xml", "StartupScreen", startupScreen)
	return startupScreen
end
function StartupScreen.new(target)
	local self = FrameElement.new(target, StartupScreen_mt)
	return self
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
	if not StartParams.getIsSet("skipStartVideos") and (not g_isDevelopmentVersion or not Platform.isPC) then
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
function StartupScreen:addStartupVideo(languagesString, filename, volume, isFullscreen, size)
	if self:shouldAddEvent(languagesString) then
		local videoEvent = { filename = filename, volume = volume, fullscreen = isFullscreen, size = size }
		videoEvent.eventType = StartupScreen.EVENTTYPE_VIDEO
		table.insert(self.eventList, videoEvent)
	end
end
function StartupScreen:addStartupPicture(languagesString, filename, duration)
	if self:shouldAddEvent(languagesString) then
		local pictureEvent = { filename = filename, duration = duration }
		pictureEvent.eventType = StartupScreen.EVENTTYPE_PICTURE
		table.insert(self.eventList, pictureEvent)
	end
end
function StartupScreen:shouldAddEvent(languagesString)
	if Platform.isConsole or not languagesString then
		return true
	end
	local languages = table.toSet(languagesString:split(" "))
	return languages[g_languageShort] ~= nil
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
function StartupScreen:showNextEvent()
	self.currentEventId = self.currentEventId + 1
	local nextEvent = self.eventList[self.currentEventId]
	if not nextEvent then
		self:onStartupEnd()
	elseif nextEvent.eventType == StartupScreen.EVENTTYPE_VIDEO then
		self.videoElement:setVisible(true)
		self.videoElement.onEndVideoCallback = self.videoElementCallback
		self.pictureElement:setVisible(false)
		self:playVideo(nextEvent)
	else
		self.pictureElement:setVisible(true)
		self.videoElement:setVisible(false)
		self.videoElement.onEndVideoCallback = nil
		self:showPicture(nextEvent)
	end
end
function StartupScreen:playVideo(videoEvent)
	self.videoElement:changeVideo(videoEvent.filename, videoEvent.volume)
	local adjustedVideoSizeX = nil
	local adjustedVideoSizeY = nil
	local adjustedVideoPositionX = nil
	local adjustedVideoPositionY = nil
	if videoEvent.fullscreen then
		adjustedVideoSizeX = 1
		adjustedVideoSizeY = 1
		adjustedVideoPositionX = 0
		adjustedVideoPositionY = 0
	else
		local x, y = getScreenModeInfo(getScreenMode())
		local aspectRatio = x / y
		adjustedVideoSizeX = videoEvent.size[1]
		adjustedVideoSizeY = videoEvent.size[2] * aspectRatio
		adjustedVideoPositionX = 0.5 * (1 - adjustedVideoSizeX)
		adjustedVideoPositionY = 0.5 * (1 - adjustedVideoSizeY)
	end
	self.videoElement:setSize(adjustedVideoSizeX, adjustedVideoSizeY)
	self.videoElement:setPosition(adjustedVideoPositionX, adjustedVideoPositionY)
	self.videoElement:playVideo()
	return true
end
function StartupScreen:showPicture(pictureEvent)
	self.pictureElement:setImageFilename(pictureEvent.filename)
	self.pictureTimer = addTimer(pictureEvent.duration, "onStartupEndEvent", self)
end
function StartupScreen:update(dt)
	StartupScreen:superClass().update(self, dt)
	if not isGameFullyInstalled() then
		return
	else
		local anyButtonPressed = false
		for d = 1, getNumOfGamepads() do
			for i = 1, Input.MAX_NUM_BUTTONS do
				local isDown = 0 < getInputButton(i - 1, d - 1)
				if isDown then
					anyButtonPressed = true
					break
				end
			end
		end
		if not anyButtonPressed then
			self.handledButtonPress = false
		end
		if not self.handledButtonPress and anyButtonPressed then
			self.handledButtonPress = true
			self:cancelCurrentEvent()
		end
	end
end
function StartupScreen:mouseEvent(posX, posY, isDown, isUp, button)
	if isDown then
		self:cancelCurrentEvent()
	end
end
function StartupScreen:touchEvent(posX, posY, isDown, isUp, touchId)
	if isDown then
		self:cancelCurrentEvent()
	end
end
function StartupScreen:keyEvent(unicode, sym, modifier, isDown)
	if isDown then
		self:cancelCurrentEvent()
	end
end
function StartupScreen:cancelCurrentEvent()
	local currentEvent = self.eventList[self.currentEventId]
	if currentEvent.eventType == StartupScreen.EVENTTYPE_VIDEO then
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
