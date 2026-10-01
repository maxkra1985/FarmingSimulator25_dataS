local data = nil
if AchievementMessage ~= nil then
	local old = g_currentMission.hud.achievementMessage
	data = {}
	data.uiScale = old.uiScale
	data.isVisible = old:getVisible()
	old:delete()
end
AchievementMessage = {}
local AchievementMessage_mt = Class(AchievementMessage, HUDDisplay)
function AchievementMessage.new(customMt)
	local self = AchievementMessage:superClass().new(AchievementMessage_mt)
	self.pendingMessages = {}
	self.currentMessage = nil
	self.showNextFrame = false
	self.headerText = utf8ToUpper(g_i18n:getText("message_achievementUnlocked"))
	self.iconOverlay = Overlay.new(nil, 0, 0, 0, 0)
	self.nextMessageTimer = -1
	return self
end
function AchievementMessage:delete()
	self.iconOverlay:delete()
end
function AchievementMessage:storeScaledValues()
	local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 0)
	local posX = 0.5 + offsetX
	local posY = g_hudAnchorBottom + offsetY
	self:setPosition(posX, posY)
	self.width, self.height = self:scalePixelValuesToScreenVector(600, 100)
	posX = posX - self.width * 0.5
	local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(90, 90)
	self.iconOffsetX, self.iconOffsetY = self:scalePixelValuesToScreenVector(5, -5)
	self.iconOverlay:setDimension(iconWidth, iconHeight)
	self.titleTextSize = self:scalePixelToScreenHeight(19)
	self.titleTextOffsetX, self.titleTextOffsetY = self:scalePixelValuesToScreenVector(105, -30)
	self.descriptionTextSize = self:scalePixelToScreenHeight(17)
	self.descriptionTextOffsetX, self.descriptionTextOffsetY = self:scalePixelValuesToScreenVector(105, -50)
	self.descriptionTextMaxWidth = self:scalePixelToScreenWidth(490)
	self.textOffsetY = self:scalePixelToScreenHeight(20)
end
function AchievementMessage:update(dt)
	if self:getAllowDisplay() then
		if self.currentMessage ~= nil then
			self.currentMessage.timeLeft = self.currentMessage.timeLeft - dt
			if self.currentMessage.timeLeft <= 0 then
				self:stopMessage()
			end
		else
			if 0 < self.nextMessageTimer then
				self.nextMessageTimer = self.nextMessageTimer - dt
				return
			end
			if 0 < #self.pendingMessages then
				self:startMessage()
			end
		end
	end
end
function AchievementMessage:draw()
	if self:getAllowDisplay() and self:getVisible() then
		AchievementMessage:superClass().draw(self)
		local message = self.currentMessage
		if message == nil then
			return
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		local posX, posY = self:getPosition()
		posX = posX - self.width * 0.5
		local title = message.title
		local description = message.description
		local height = 2 * self.textOffsetY
		setTextBold(true)
		local titleHeight = getTextHeight(self.titleTextSize, title)
		height = height + titleHeight
		setTextBold(false)
		setTextWrapWidth(self.descriptionTextMaxWidth)
		local textHeight = getTextHeight(self.descriptionTextSize, description)
		setTextWrapWidth(0)
		height = height + textHeight
		height = math.max(self.height, height)
		local color = HUD.COLOR.BACKGROUND
		drawFilledRectRound(posX, posY, self.width, height, 0.5, color[1], color[2], color[3], color[4])
		self.iconOverlay:setPosition(posX + self.iconOffsetX, posY + (height - self.iconOverlay.height) * 0.5)
		self.iconOverlay:render()
		posY = posY + height
		setTextBold(true)
		setTextColor(1, 1, 1, 1)
		renderText(posX + self.titleTextOffsetX, posY + self.titleTextOffsetY, self.titleTextSize, title)
		setTextBold(false)
		setTextColor(1, 1, 1, 0.6)
		setTextWrapWidth(self.descriptionTextMaxWidth)
		renderText(posX + self.descriptionTextOffsetX, posY + self.descriptionTextOffsetY, self.descriptionTextSize, description)
		setTextWrapWidth(0)
	end
end
function AchievementMessage:getAllowDisplay()
	if g_gui:getIsGuiVisible() then
		return false
	elseif self.isGamePaused then
		return false
	elseif g_sleepManager:getIsSleeping() then
		return false
	else
		local hud = g_currentMission.hud
		local contextActionDisplay = hud.contextActionDisplay
		if contextActionDisplay ~= nil and contextActionDisplay:getVisible() then
			return false
		end
		local ingameMessage = hud.ingameMessage
		if ingameMessage ~= nil and ingameMessage:getVisible() then
			return false
		end
		return true
	end
end
function AchievementMessage:showMessage(title, description, iconFilename, iconUVs, duration)
	if g_dedicatedServer ~= nil then
		return
	else
		local message = { title = title, description = description, iconFilename = iconFilename, iconUVs = iconUVs, timeLeft = duration }
		table.insert(self.pendingMessages, message)
	end
end
function AchievementMessage:startMessage()
	local ingameMap = g_currentMission.hud.ingameMap
	ingameMap:setAllowToggle(false)
	ingameMap:turnSmall()
	local pendingMessage = table.remove(self.pendingMessages, 1)
	if pendingMessage ~= nil then
		self.currentMessage = pendingMessage
		self.iconOverlay:setImage(pendingMessage.iconFilename)
		self.iconOverlay:setUVs(pendingMessage.iconUVs)
		self:setVisible(true)
		g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.ACHIEVEMENT)
	end
end
function AchievementMessage:stopMessage()
	if self.currentMessage == nil then
		return
	else
		g_currentMission.hud.ingameMap:setAllowToggle(true)
		self:setVisible(false)
		self.currentMessage = nil
		self.nextMessageTimer = 500
	end
end
if data ~= nil then
	local achievementMessage = AchievementMessage.new()
	achievementMessage:setScale(data.uiScale)
	achievementMessage:setVisible(data.isVisible)
	g_currentMission.hud.achievementMessage = achievementMessage
	g_currentMission.hud.displayComponents.achievementMessage = achievementMessage
	Logging.info("Reloaded AchievementMessage")
end
