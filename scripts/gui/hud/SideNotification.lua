local data = nil
if SideNotification ~= nil then
	local mission = g_currentMission
	local old = mission.hud.sideNotifications
	data = {}
	data.uiScale = old.uiScale
	data.isVisible = old:getVisible()
	data.progressBars = old.progressBars
	old:delete()
end
SideNotification = {}
SideNotification.MAX_NOTIFICATIONS = 5
local SideNotification_mt = Class(SideNotification, HUDDisplay)
function SideNotification.new(customMt)
	local self = SideNotification:superClass().new(SideNotification_mt)
	self.notificationQueue = {}
	self.progressBars = {}
	local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
	self.bgScale = g_overlayManager:createOverlay("gui.rectangle_center", 0, 0, 0, 0)
	self.bgScale:setColor(r, g, b, a)
	self.bgLeft = g_overlayManager:createOverlay("gui.rectangle_left", 0, 0, 0, 0)
	self.bgLeft:setColor(r, g, b, a)
	self.bgRight = g_overlayManager:createOverlay("gui.rectangle_right", 0, 0, 0, 0)
	self.bgRight:setColor(r, g, b, a)
	self.progressBarBgScale = g_overlayManager:createOverlay("gui.progressBackground_middle", 0, 0, 0, 0)
	self.progressBarBgScale:setColor(r, g, b, a)
	self.progressBarBgTop = g_overlayManager:createOverlay("gui.progressBackground_top", 0, 0, 0, 0)
	self.progressBarBgTop:setColor(r, g, b, a)
	self.progressBarBgBottom = g_overlayManager:createOverlay("gui.progressBackground_bottom", 0, 0, 0, 0)
	self.progressBarBgBottom:setColor(r, g, b, a)
	self.bar = ThreePartOverlay.new()
	self.bar:setLeftPart("gui.progressbar_left", 0, 0)
	self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	self.bar:setRightPart("gui.progressbar_right", 0, 0)
	self.savingIcon = g_overlayManager:createOverlay("gui.savingInProgress", 0, 0, 0, 0)
	self.saveText = g_i18n:getText("ui_savegameSaveInProgress")
	self.savingIcon:setColor(1, 1, 1, 0.5)
	return self
end
function SideNotification:delete()
	self.bgScale:delete()
	self.bgLeft:delete()
	self.bgRight:delete()
	self.progressBarBgScale:delete()
	self.progressBarBgTop:delete()
	self.progressBarBgBottom:delete()
	self.savingIcon:delete()
	self.bar:delete()
end
function SideNotification:storeScaledValues()
	local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, -65)
	local posX = g_hudAnchorRight + offsetX
	local posY = g_hudAnchorTop + offsetY
	self:setPosition(posX, posY)
	local bgRightWidth, bgHeight = self:scalePixelValuesToScreenVector(10, 25)
	local bgLeftWidth = self:scalePixelToScreenWidth(10)
	self.bgRight:setDimension(bgRightWidth, bgHeight)
	self.bgLeft:setDimension(bgLeftWidth, bgHeight)
	self.bgScale:setDimension(0, bgHeight)
	self.textSize = self:scalePixelToScreenHeight(16)
	self.textOffsetY = self:scalePixelToScreenHeight(6)
	self.notificationOffsetY = self:scalePixelToScreenHeight(6)
	self.textMaxWidth = self:scalePixelToScreenWidth(330)
	local progressBarBgWidth, progressBarBgPartHeight = self:scalePixelValuesToScreenVector(400, 6)
	self.progressBarBgBottom:setDimension(progressBarBgWidth, progressBarBgPartHeight)
	self.progressBarBgTop:setDimension(progressBarBgWidth, progressBarBgPartHeight)
	self.progressBarBgScale:setDimension(progressBarBgWidth, 0)
	self.progressBarTextSize = self:scalePixelToScreenHeight(12)
	self.progressBarMaxTextWidth = self:scalePixelToScreenWidth(330)
	self.progressBarTitleOffsetX, self.progressBarTitleOffsetY = self:scalePixelValuesToScreenVector(14, -21)
	self.progressBarTextOffsetX, self.progressBarTextOffsetY = self:scalePixelValuesToScreenVector(0, 21)
	self.progressBarSectionOffsetY = self:scalePixelToScreenHeight(5)
	self.progressBarProgressTextOffsetX, self.progressBarProgressTextOffsetY = self:scalePixelValuesToScreenVector(-8, 8)
	self.progressBarProgressTextSize = self:scalePixelToScreenHeight(15)
	local backgroundPosX = posX - self.progressBarBgBottom.width
	self.progressBarBgBottom:setPosition(backgroundPosX, nil)
	self.progressBarBgScale:setPosition(backgroundPosX, nil)
	self.progressBarBgTop:setPosition(backgroundPosX, nil)
	self.helpAnchorPosX = self.progressBarBgTop.x + self:scalePixelToScreenWidth(-15)
	self.helpAnchorPosY = posY + self:scalePixelToScreenHeight(-25)
	local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(3, 6)
	local barTotalWidth, _ = self:scalePixelValuesToScreenVector(330, 0)
	self.barMaxScaleWidth = barTotalWidth - 2 * barPartWidth
	self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
	self.bar:setMiddlePart(nil, self.barMaxScaleWidth, barPartHeight)
	self.bar:setRightPart(nil, barPartWidth, barPartHeight)
	self.barOffsetX, self.barOffsetY = self:scalePixelValuesToScreenVector(14, 10)
	self.barHeight = self:scalePixelToScreenHeight(20)
	local width, height = self:scalePixelValuesToScreenVector(19, 19)
	self.savingIcon:setDimension(width, height)
	self.savingIconOffsetX, self.savingIconOffsetY = self:scalePixelValuesToScreenVector(6, 3)
end
function SideNotification:update(dt)
	for i = math.min(#self.notificationQueue, SideNotification.MAX_NOTIFICATIONS), 1, -1 do
		local notification = self.notificationQueue[i]
		if notification.duration <= 0 then
			table.remove(self.notificationQueue, i)
		else
			notification.duration = math.max(0, notification.duration - dt)
		end
	end
end
function SideNotification:draw()
	SideNotification:superClass().draw(self)
	local posX, posY = self:getPosition()
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	local barBgColor = HUD.COLOR.BACKGROUND_DARK
	local activeColor = HUD.COLOR.ACTIVE
	local hasProgressBars = false
	local textMaxWidth = self.textMaxWidth
	for _, progressBar in ipairs(self.progressBars) do
		if progressBar.isVisible then
			posY = posY - self.notificationOffsetY
			local progress = math.clamp(progressBar.progress, 0, 1)
			local title = ""
			if progressBar.title ~= nil then
				title = utf8ToUpper(progressBar.title .. (progressBar.text ~= nil and ": " or ""))
			end
			local text = ""
			if progressBar.text ~= nil then
				text = utf8ToUpper(progressBar.text)
			end
			local textWidth = getTextWidth(self.progressBarTextSize, text)
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_LEFT)
			local titleWidth = getTextWidth(self.progressBarTextSize, title)
			if self.textMaxWidth < textWidth + titleWidth then
				if textWidth < titleWidth then
					titleWidth = self.textMaxWidth - textWidth
					title = Utils.limitTextToWidth(title, self.progressBarTextSize, self.textMaxWidth - textWidth, false, "...")
				else
					text = Utils.limitTextToWidth(text, self.progressBarTextSize, self.textMaxWidth - textWidth, false, "...")
				end
			end
			textMaxWidth = self.textMaxWidth - titleWidth
			setTextWrapWidth(textMaxWidth)
			local textHeight = getTextHeight(self.progressBarTextSize, text)
			setTextWrapWidth(0)
			local totalHeight = textHeight + self.textOffsetY * 2 + self.barHeight
			self.progressBarBgScale:setDimension(nil, totalHeight - self.progressBarBgTop.height - self.progressBarBgBottom.height)
			self.progressBarBgTop:setPosition(nil, posY - self.progressBarBgTop.height)
			self.progressBarBgTop:render()
			self.progressBarBgScale:setPosition(nil, self.progressBarBgTop.y - self.progressBarBgScale.height)
			self.progressBarBgScale:render()
			self.progressBarBgBottom:setPosition(nil, self.progressBarBgScale.y - self.progressBarBgBottom.height)
			self.progressBarBgBottom:render()
			self.bar:setColor(barBgColor[1], barBgColor[2], barBgColor[3], barBgColor[4])
			self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
			self.bar:setPosition(self.progressBarBgBottom.x + self.barOffsetX, self.progressBarBgBottom.y + self.barOffsetY)
			self.bar:render()
			if 0.01 <= progress then
				self.bar:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
				self.bar:setMiddlePart(nil, self.barMaxScaleWidth * progress, nil)
				self.bar:setPosition(self.progressBarBgBottom.x + self.barOffsetX, self.progressBarBgBottom.y + self.barOffsetY)
				self.bar:render()
			end
			local textPosX = self.progressBarBgTop.x + self.progressBarTitleOffsetX
			local textPosY = posY + self.progressBarTitleOffsetY
			renderText(textPosX, textPosY, self.progressBarTextSize, title)
			setTextBold(false)
			textMaxWidth = self.textMaxWidth - titleWidth
			setTextWrapWidth(textMaxWidth)
			renderText(textPosX + titleWidth, textPosY, self.progressBarTextSize, text)
			setTextWrapWidth(0)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			local progressText = string.format("%d%%", progress * 100)
			renderText(posX + self.progressBarProgressTextOffsetX, self.progressBarBgBottom.y + self.progressBarProgressTextOffsetY, self.progressBarProgressTextSize, progressText)
			hasProgressBars = true
			posY = posY - totalHeight
		end
		progressBar.isVisible = false
	end
	if hasProgressBars then
		posY = posY - self.progressBarSectionOffsetY
	end
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	if self.isSaving then
		posY = posY - self.bgRight.height - self.notificationOffsetY
		local text = self.saveText
		local textWidth = getTextWidth(self.textSize, text)
		textWidth = textWidth + self.savingIconOffsetX + self.savingIcon.width
		self.bgRight:setPosition(posX - self.bgRight.width, posY)
		self.bgRight:render()
		self.bgScale:setDimension(textWidth, nil)
		self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, posY)
		self.bgScale:render()
		self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, posY)
		self.bgLeft:render()
		self.savingIcon:setPosition(self.bgLeft.x + self.savingIconOffsetX, self.bgLeft.y + self.savingIconOffsetY)
		local deltaRot = 0.0041887902047863905 * g_currentDt
		self.savingIcon:setRotation(self.savingIcon.rotation + deltaRot, self.savingIcon.width * 0.5, self.savingIcon.height * 0.5)
		self.savingIcon:render()
		setTextColor(1, 1, 1, 1)
		renderText(self.bgRight.x, self.bgRight.y + self.textOffsetY, self.textSize, text)
	end
	for i = 1, math.min(#self.notificationQueue, SideNotification.MAX_NOTIFICATIONS) do
		posY = posY - self.bgRight.height - self.notificationOffsetY
		local notification = self.notificationQueue[i]
		local textWidth = getTextWidth(self.textSize, notification.text)
		self.bgRight:setPosition(posX - self.bgRight.width, posY)
		self.bgRight:render()
		self.bgScale:setDimension(textWidth, nil)
		self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, posY)
		self.bgScale:render()
		self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, posY)
		self.bgLeft:render()
		setTextColor(notification.color[1], notification.color[2], notification.color[3], notification.color[4])
		renderText(self.bgRight.x, self.bgRight.y + self.textOffsetY, self.textSize, notification.text)
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	setTextBold(false)
end
function SideNotification:addNotification(text, color, displayDuration)
	local notification = { text = text, color = color, duration = displayDuration, startDuration = displayDuration }
	table.insert(self.notificationQueue, notification)
end
function SideNotification:addProgressBar(title, text, progress)
	local progressBar = { title = title, text = text, progress = progress, isVisible = false }
	table.addElement(self.progressBars, progressBar)
	return progressBar
end
function SideNotification:removeProgressBar(progressBar)
	table.removeElement(self.progressBars, progressBar)
end
function SideNotification:setIsSaving(isSaving)
	self.isSaving = isSaving
end
function SideNotification:markProgressBarForDrawing(progressBar)
	progressBar.isVisible = true
end
function SideNotification:getHelpAnchorPosition()
	local posX = self.helpAnchorPosX
	local posY = self.helpAnchorPosY
	return posX, posY
end
if data ~= nil then
	local sideNotifications = SideNotification.new()
	sideNotifications:setScale(data.uiScale)
	sideNotifications:setVisible(data.isVisible)
	for _, progressBar in ipairs(data.progressBars) do
		table.addElement(sideNotifications.progressBars, progressBar)
	end
	local mission = g_currentMission
	local hud = mission.hud
	hud.sideNotifications = sideNotifications
	hud.displayComponents.sideNotifications = sideNotifications
	Logging.info("Reloaded SideNotification")
end
