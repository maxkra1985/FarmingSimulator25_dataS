-- Local values: data, old, AchievementMessage_mt, achievementMessage
local v1_
if AchievementMessage == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.achievementMessage
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
AchievementMessage = {}
local data = Class(AchievementMessage, HUDDisplay)

-- Upvalues: AchievementMessage_mt
-- Local values: self
function AchievementMessage.new(customMt)
	-- upvalues: (copy) data
	local v4_ = AchievementMessage:superClass().new(data)
	v4_.pendingMessages = {}
	v4_.currentMessage = nil
	v4_.showNextFrame = false
	v4_.headerText = utf8ToUpper(g_i18n:getText("message_achievementUnlocked"))
	v4_.iconOverlay = Overlay.new(nil, 0, 0, 0, 0)
	v4_.nextMessageTimer = -1
	return v4_
end

function AchievementMessage:delete()
	self.iconOverlay:delete()
end

-- Local values: offsetX, offsetY, posX, posY, iconWidth, iconHeight
function AchievementMessage:storeScaledValues()
	local v7_, v8_ = self:scalePixelValuesToScreenVector(0, 0)
	local v9_ = 0.5 + v7_
	self:setPosition(v9_, g_hudAnchorBottom + v8_)
	local v10_, v11_ = self:scalePixelValuesToScreenVector(600, 100)
	self.width = v10_
	self.height = v11_
	local _ = v9_ - self.width * 0.5
	local v12_, v13_ = self:scalePixelValuesToScreenVector(90, 90)
	local v14_, v15_ = self:scalePixelValuesToScreenVector(5, -5)
	self.iconOffsetX = v14_
	self.iconOffsetY = v15_
	self.iconOverlay:setDimension(v12_, v13_)
	self.titleTextSize = self:scalePixelToScreenHeight(19)
	local v16_, v17_ = self:scalePixelValuesToScreenVector(105, -30)
	self.titleTextOffsetX = v16_
	self.titleTextOffsetY = v17_
	self.descriptionTextSize = self:scalePixelToScreenHeight(17)
	local v18_, v19_ = self:scalePixelValuesToScreenVector(105, -50)
	self.descriptionTextOffsetX = v18_
	self.descriptionTextOffsetY = v19_
	self.descriptionTextMaxWidth = self:scalePixelToScreenWidth(490)
	self.textOffsetY = self:scalePixelToScreenHeight(20)
end

function AchievementMessage:update(dt)
	if self:getAllowDisplay() then
		if self.currentMessage == nil then
			if self.nextMessageTimer > 0 then
				self.nextMessageTimer = self.nextMessageTimer - dt
				return
			end
			if #self.pendingMessages > 0 then
				self:startMessage()
			end
		else
			self.currentMessage.timeLeft = self.currentMessage.timeLeft - dt
			if self.currentMessage.timeLeft <= 0 then
				self:stopMessage()
				return
			end
		end
	end
end

-- Local values: message, posX, posY, title, description, height, titleHeight, textHeight, color
function AchievementMessage:draw()
	if self:getAllowDisplay() and self:getVisible() then
		AchievementMessage:superClass().draw(self)
		local v23_ = self.currentMessage
		if v23_ == nil then
			return
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v24_, v25_ = self:getPosition()
		local v26_ = v24_ - self.width * 0.5
		local v27_ = v23_.title
		local v28_ = v23_.description
		local v29_ = 2 * self.textOffsetY
		setTextBold(true)
		local v30_ = v29_ + getTextHeight(self.titleTextSize, v27_)
		setTextBold(false)
		setTextWrapWidth(self.descriptionTextMaxWidth)
		local v31_ = getTextHeight(self.descriptionTextSize, v28_)
		setTextWrapWidth(0)
		local v32_ = v30_ + v31_
		local v33_ = self.height
		local v34_ = math.max(v33_, v32_)
		local v35_ = HUD.COLOR.BACKGROUND
		drawFilledRectRound(v26_, v25_, self.width, v34_, 0.5, v35_[1], v35_[2], v35_[3], v35_[4])
		self.iconOverlay:setPosition(v26_ + self.iconOffsetX, v25_ + (v34_ - self.iconOverlay.height) * 0.5)
		self.iconOverlay:render()
		local v36_ = v25_ + v34_
		setTextBold(true)
		setTextColor(1, 1, 1, 1)
		renderText(v26_ + self.titleTextOffsetX, v36_ + self.titleTextOffsetY, self.titleTextSize, v27_)
		setTextBold(false)
		setTextColor(1, 1, 1, 0.6)
		setTextWrapWidth(self.descriptionTextMaxWidth)
		renderText(v26_ + self.descriptionTextOffsetX, v36_ + self.descriptionTextOffsetY, self.descriptionTextSize, v28_)
		setTextWrapWidth(0)
	end
end

-- Local values: hud, contextActionDisplay, ingameMessage
function AchievementMessage:getAllowDisplay()
	if g_gui:getIsGuiVisible() then
		return false
	end
	if self.isGamePaused then
		return false
	end
	if g_sleepManager:getIsSleeping() then
		return false
	end
	local v38_ = g_currentMission.hud
	local v39_ = v38_.contextActionDisplay
	if v39_ ~= nil and v39_:getVisible() then
		return false
	end
	local v40_ = v38_.ingameMessage
	return (v40_ == nil or not v40_:getVisible()) and true or false
end

-- Local values: message
function AchievementMessage:showMessage(title, description, iconFilename, iconUVs, duration)
	if g_dedicatedServer == nil then
		local v47_ = self.pendingMessages
		table.insert(v47_, {
			["title"] = title,
			["description"] = description,
			["iconFilename"] = iconFilename,
			["iconUVs"] = iconUVs,
			["timeLeft"] = duration
		})
	end
end

-- Local values: ingameMap, pendingMessage
function AchievementMessage:startMessage()
	local v49_ = g_currentMission.hud.ingameMap
	v49_:setAllowToggle(false)
	v49_:turnSmall()
	local v50_ = table.remove(self.pendingMessages, 1)
	if v50_ ~= nil then
		self.currentMessage = v50_
		self.iconOverlay:setImage(v50_.iconFilename)
		self.iconOverlay:setUVs(v50_.iconUVs)
		self:setVisible(true)
		g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.ACHIEVEMENT)
	end
end

function AchievementMessage:stopMessage()
	if self.currentMessage ~= nil then
		g_currentMission.hud.ingameMap:setAllowToggle(true)
		self:setVisible(false)
		self.currentMessage = nil
		self.nextMessageTimer = 500
	end
end
if v1_ ~= nil then
	local v52_ = AchievementMessage.new()
	v52_:setScale(v1_.uiScale)
	v52_:setVisible(v1_.isVisible)
	g_currentMission.hud.achievementMessage = v52_
	g_currentMission.hud.displayComponents.achievementMessage = v52_
	Logging.info("Reloaded AchievementMessage")
end
