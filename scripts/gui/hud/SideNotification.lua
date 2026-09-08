-- Local values: data, mission, old, SideNotification_mt, sideNotifications, _, progressBar, mission, hud
local v1_
if SideNotification == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.sideNotifications
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible(),
		["progressBars"] = v2_.progressBars
	}
	v2_:delete()
end
SideNotification = {}
SideNotification.MAX_NOTIFICATIONS = 5
local data = Class(SideNotification, HUDDisplay)

-- Upvalues: SideNotification_mt
-- Local values: self, r, g, b, a
function SideNotification.new(customMt)
	-- upvalues: (copy) data
	local v4_ = SideNotification:superClass().new(data)
	v4_.notificationQueue = {}
	v4_.progressBars = {}
	local v5_ = HUD.COLOR.BACKGROUND
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.bgScale = g_overlayManager:createOverlay("gui.rectangle_center", 0, 0, 0, 0)
	v4_.bgScale:setColor(v6_, v7_, v8_, v9_)
	v4_.bgLeft = g_overlayManager:createOverlay("gui.rectangle_left", 0, 0, 0, 0)
	v4_.bgLeft:setColor(v6_, v7_, v8_, v9_)
	v4_.bgRight = g_overlayManager:createOverlay("gui.rectangle_right", 0, 0, 0, 0)
	v4_.bgRight:setColor(v6_, v7_, v8_, v9_)
	v4_.progressBarBgScale = g_overlayManager:createOverlay("gui.progressBackground_middle", 0, 0, 0, 0)
	v4_.progressBarBgScale:setColor(v6_, v7_, v8_, v9_)
	v4_.progressBarBgTop = g_overlayManager:createOverlay("gui.progressBackground_top", 0, 0, 0, 0)
	v4_.progressBarBgTop:setColor(v6_, v7_, v8_, v9_)
	v4_.progressBarBgBottom = g_overlayManager:createOverlay("gui.progressBackground_bottom", 0, 0, 0, 0)
	v4_.progressBarBgBottom:setColor(v6_, v7_, v8_, v9_)
	v4_.bar = ThreePartOverlay.new()
	v4_.bar:setLeftPart("gui.progressbar_left", 0, 0)
	v4_.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	v4_.bar:setRightPart("gui.progressbar_right", 0, 0)
	v4_.savingIcon = g_overlayManager:createOverlay("gui.savingInProgress", 0, 0, 0, 0)
	v4_.saveText = g_i18n:getText("ui_savegameSaveInProgress")
	v4_.savingIcon:setColor(1, 1, 1, 0.5)
	return v4_
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

-- Local values: offsetX, offsetY, posX, posY, bgRightWidth, bgHeight, bgLeftWidth, progressBarBgWidth, progressBarBgPartHeight, backgroundPosX, barPartWidth, barPartHeight, barTotalWidth, _, width, height
function SideNotification:storeScaledValues()
	local v12_, v13_ = self:scalePixelValuesToScreenVector(0, -65)
	local v14_ = g_hudAnchorRight + v12_
	local v15_ = g_hudAnchorTop + v13_
	self:setPosition(v14_, v15_)
	local v16_, v17_ = self:scalePixelValuesToScreenVector(10, 25)
	local v18_ = self:scalePixelToScreenWidth(10)
	self.bgRight:setDimension(v16_, v17_)
	self.bgLeft:setDimension(v18_, v17_)
	self.bgScale:setDimension(0, v17_)
	self.textSize = self:scalePixelToScreenHeight(16)
	self.textOffsetY = self:scalePixelToScreenHeight(6)
	self.notificationOffsetY = self:scalePixelToScreenHeight(6)
	self.textMaxWidth = self:scalePixelToScreenWidth(330)
	local v19_, v20_ = self:scalePixelValuesToScreenVector(400, 6)
	self.progressBarBgBottom:setDimension(v19_, v20_)
	self.progressBarBgTop:setDimension(v19_, v20_)
	self.progressBarBgScale:setDimension(v19_, 0)
	self.progressBarTextSize = self:scalePixelToScreenHeight(12)
	self.progressBarMaxTextWidth = self:scalePixelToScreenWidth(330)
	local v21_, v22_ = self:scalePixelValuesToScreenVector(14, -21)
	self.progressBarTitleOffsetX = v21_
	self.progressBarTitleOffsetY = v22_
	local v23_, v24_ = self:scalePixelValuesToScreenVector(0, 21)
	self.progressBarTextOffsetX = v23_
	self.progressBarTextOffsetY = v24_
	self.progressBarSectionOffsetY = self:scalePixelToScreenHeight(5)
	local v25_, v26_ = self:scalePixelValuesToScreenVector(-8, 8)
	self.progressBarProgressTextOffsetX = v25_
	self.progressBarProgressTextOffsetY = v26_
	self.progressBarProgressTextSize = self:scalePixelToScreenHeight(15)
	local v27_ = v14_ - self.progressBarBgBottom.width
	self.progressBarBgBottom:setPosition(v27_, nil)
	self.progressBarBgScale:setPosition(v27_, nil)
	self.progressBarBgTop:setPosition(v27_, nil)
	self.helpAnchorPosX = self.progressBarBgTop.x + self:scalePixelToScreenWidth(-15)
	self.helpAnchorPosY = v15_ + self:scalePixelToScreenHeight(-25)
	local v28_, v29_ = self:scalePixelValuesToScreenVector(3, 6)
	local v30_, _ = self:scalePixelValuesToScreenVector(330, 0)
	self.barMaxScaleWidth = v30_ - 2 * v28_
	self.bar:setLeftPart(nil, v28_, v29_)
	self.bar:setMiddlePart(nil, self.barMaxScaleWidth, v29_)
	self.bar:setRightPart(nil, v28_, v29_)
	local v31_, v32_ = self:scalePixelValuesToScreenVector(14, 10)
	self.barOffsetX = v31_
	self.barOffsetY = v32_
	self.barHeight = self:scalePixelToScreenHeight(20)
	local v33_, v34_ = self:scalePixelValuesToScreenVector(19, 19)
	self.savingIcon:setDimension(v33_, v34_)
	local v35_, v36_ = self:scalePixelValuesToScreenVector(6, 3)
	self.savingIconOffsetX = v35_
	self.savingIconOffsetY = v36_
end

-- Local values: i, notification
function SideNotification:update(dt)
	local v39_ = #self.notificationQueue
	local v40_ = SideNotification.MAX_NOTIFICATIONS
	for v41_ = math.min(v39_, v40_), 1, -1 do
		local v42_ = self.notificationQueue[v41_]
		if v42_.duration <= 0 then
			table.remove(self.notificationQueue, v41_)
		else
			local v43_ = v42_.duration - dt
			v42_.duration = math.max(0, v43_)
		end
	end
end

-- Local values: posX, posY, barBgColor, activeColor, hasProgressBars, textMaxWidth, _, progressBar, progress, title, text, textWidth, titleWidth, textHeight, totalHeight, textPosX, textPosY, progressText, text, textWidth, deltaRot, i, notification, textWidth
function SideNotification:draw()
	SideNotification:superClass().draw(self)
	local v45_, v46_ = self:getPosition()
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	local v47_ = HUD.COLOR.BACKGROUND_DARK
	local v48_ = HUD.COLOR.ACTIVE
	local _ = self.textMaxWidth
	local v49_ = false
	for _, v50_ in ipairs(self.progressBars) do
		if v50_.isVisible then
			local v51_ = v46_ - self.notificationOffsetY
			local v52_ = v50_.progress
			local v53_ = math.clamp(v52_, 0, 1)
			local v54_ = v50_.title == nil and "" or utf8ToUpper(v50_.title .. (v50_.text == nil and "" or ": "))
			local v55_ = v50_.text == nil and "" or utf8ToUpper(v50_.text)
			local v56_ = getTextWidth(self.progressBarTextSize, v55_)
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_LEFT)
			local v57_ = getTextWidth(self.progressBarTextSize, v54_)
			if v56_ + v57_ > self.textMaxWidth then
				if v56_ < v57_ then
					v57_ = self.textMaxWidth - v56_
					v54_ = Utils.limitTextToWidth(v54_, self.progressBarTextSize, self.textMaxWidth - v56_, false, "...")
				else
					v55_ = Utils.limitTextToWidth(v55_, self.progressBarTextSize, self.textMaxWidth - v56_, false, "...")
				end
			end
			local v58_ = self.textMaxWidth - v57_
			setTextWrapWidth(v58_)
			local v59_ = getTextHeight(self.progressBarTextSize, v55_)
			setTextWrapWidth(0)
			local v60_ = v59_ + self.textOffsetY * 2 + self.barHeight
			self.progressBarBgScale:setDimension(nil, v60_ - self.progressBarBgTop.height - self.progressBarBgBottom.height)
			self.progressBarBgTop:setPosition(nil, v51_ - self.progressBarBgTop.height)
			self.progressBarBgTop:render()
			self.progressBarBgScale:setPosition(nil, self.progressBarBgTop.y - self.progressBarBgScale.height)
			self.progressBarBgScale:render()
			self.progressBarBgBottom:setPosition(nil, self.progressBarBgScale.y - self.progressBarBgBottom.height)
			self.progressBarBgBottom:render()
			self.bar:setColor(v47_[1], v47_[2], v47_[3], v47_[4])
			self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
			self.bar:setPosition(self.progressBarBgBottom.x + self.barOffsetX, self.progressBarBgBottom.y + self.barOffsetY)
			self.bar:render()
			if v53_ >= 0.01 then
				self.bar:setColor(v48_[1], v48_[2], v48_[3], v48_[4])
				self.bar:setMiddlePart(nil, self.barMaxScaleWidth * v53_, nil)
				self.bar:setPosition(self.progressBarBgBottom.x + self.barOffsetX, self.progressBarBgBottom.y + self.barOffsetY)
				self.bar:render()
			end
			local v61_ = self.progressBarBgTop.x + self.progressBarTitleOffsetX
			local v62_ = v51_ + self.progressBarTitleOffsetY
			renderText(v61_, v62_, self.progressBarTextSize, v54_)
			setTextBold(false)
			local v63_ = self.textMaxWidth - v57_
			setTextWrapWidth(v63_)
			renderText(v61_ + v57_, v62_, self.progressBarTextSize, v55_)
			setTextWrapWidth(0)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			local v64_ = string.format("%d%%", v53_ * 100)
			renderText(v45_ + self.progressBarProgressTextOffsetX, self.progressBarBgBottom.y + self.progressBarProgressTextOffsetY, self.progressBarProgressTextSize, v64_)
			v46_ = v51_ - v60_
			v49_ = true
		end
		v50_.isVisible = false
	end
	if v49_ then
		v46_ = v46_ - self.progressBarSectionOffsetY
	end
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	if self.isSaving then
		v46_ = v46_ - self.bgRight.height - self.notificationOffsetY
		local v65_ = self.saveText
		local v66_ = getTextWidth(self.textSize, v65_) + self.savingIconOffsetX + self.savingIcon.width
		self.bgRight:setPosition(v45_ - self.bgRight.width, v46_)
		self.bgRight:render()
		self.bgScale:setDimension(v66_, nil)
		self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, v46_)
		self.bgScale:render()
		self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, v46_)
		self.bgLeft:render()
		self.savingIcon:setPosition(self.bgLeft.x + self.savingIconOffsetX, self.bgLeft.y + self.savingIconOffsetY)
		local v67_ = 0.0041887902047863905 * g_currentDt
		self.savingIcon:setRotation(self.savingIcon.rotation + v67_, self.savingIcon.width * 0.5, self.savingIcon.height * 0.5)
		self.savingIcon:render()
		setTextColor(1, 1, 1, 1)
		renderText(self.bgRight.x, self.bgRight.y + self.textOffsetY, self.textSize, v65_)
	end
	local v68_ = #self.notificationQueue
	local v69_ = SideNotification.MAX_NOTIFICATIONS
	for v70_ = 1, math.min(v68_, v69_) do
		v46_ = v46_ - self.bgRight.height - self.notificationOffsetY
		local v71_ = self.notificationQueue[v70_]
		local v72_ = getTextWidth(self.textSize, v71_.text)
		self.bgRight:setPosition(v45_ - self.bgRight.width, v46_)
		self.bgRight:render()
		self.bgScale:setDimension(v72_, nil)
		self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, v46_)
		self.bgScale:render()
		self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, v46_)
		self.bgLeft:render()
		setTextColor(v71_.color[1], v71_.color[2], v71_.color[3], v71_.color[4])
		renderText(self.bgRight.x, self.bgRight.y + self.textOffsetY, self.textSize, v71_.text)
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	setTextBold(false)
end

-- Local values: notification
function SideNotification:addNotification(text, color, displayDuration)
	local v77_ = self.notificationQueue
	table.insert(v77_, {
		["text"] = text,
		["color"] = color,
		["duration"] = displayDuration,
		["startDuration"] = displayDuration
	})
end

-- Local values: progressBar
function SideNotification:addProgressBar(title, text, progress)
	local v82_ = {
		["title"] = title,
		["text"] = text,
		["progress"] = progress,
		["isVisible"] = false
	}
	table.addElement(self.progressBars, v82_)
	return v82_
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

-- Local values: posX, posY
function SideNotification:getHelpAnchorPosition()
	return self.helpAnchorPosX, self.helpAnchorPosY
end
if v1_ ~= nil then
	local v89_ = SideNotification.new()
	v89_:setScale(v1_.uiScale)
	v89_:setVisible(v1_.isVisible)
	for _, v90_ in ipairs(v1_.progressBars) do
		table.addElement(v89_.progressBars, v90_)
	end
	local v91_ = g_currentMission.hud
	v91_.sideNotifications = v89_
	v91_.displayComponents.sideNotifications = v89_
	Logging.info("Reloaded SideNotification")
end
