-- Local values: data, old, TopNotification_mt, topNotification
local v1_
if TopNotification == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.topNotification
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
TopNotification = {}
TopNotification.DEFAULT_DURATION = 5000
local data = Class(TopNotification, HUDDisplay)
function TopNotification.new()
	-- upvalues: (copy) data
	local v4_ = TopNotification:superClass().new(data)
	v4_.currentNotification = {
		["title"] = "",
		["text"] = "",
		["info"] = "",
		["icon"] = nil,
		["duration"] = 0,
		["isValid"] = false
	}
	local v5_ = HUD.COLOR.BACKGROUND
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.bgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
	v4_.bgScale:setColor(v6_, v7_, v8_, v9_)
	v4_.bgLeft = g_overlayManager:createOverlay("gui.gameInfo_left", 0, 0, 0, 0)
	v4_.bgLeft:setColor(v6_, v7_, v8_, v9_)
	v4_.bgRight = g_overlayManager:createOverlay("gui.gameInfo_right", 0, 0, 0, 0)
	v4_.bgRight:setColor(v6_, v7_, v8_, v9_)
	v4_.icons = {}
	return v4_
end

-- Local values: _, overlay
function TopNotification:delete()
	self.bgLeft:delete()
	self.bgScale:delete()
	self.bgRight:delete()
	for _, v11_ in pairs(self.icons) do
		v11_:delete()
	end
end

-- Local values: bgRightWidth, bgHeight, bgLeftWidth, bgScaleWidth
function TopNotification:storeScaledValues()
	self:setPosition(0.5, g_hudAnchorTop)
	local v13_, v14_ = self:scalePixelValuesToScreenVector(10, 65)
	local v15_ = self:scalePixelToScreenWidth(10)
	local v16_ = self:scalePixelToScreenWidth(460)
	self.bgRight:setDimension(v13_, v14_)
	self.bgScale:setDimension(v16_, v14_)
	self.bgLeft:setDimension(v15_, v14_)
	local v17_, v18_ = self:scalePixelValuesToScreenVector(80, 40)
	self.iconWidth = v17_
	self.iconHeight = v18_
	local v19_, v20_ = self:scalePixelValuesToScreenVector(7, 13)
	self.iconOffsetX = v19_
	self.iconOffsetY = v20_
	self.titleTextSize = self:scalePixelToScreenHeight(17)
	self.titleTextOffsetY = self:scalePixelToScreenHeight(40)
	self.textSize = self:scalePixelToScreenHeight(12)
	self.textOffsetY = self:scalePixelToScreenHeight(24)
	self.infoTextSize = self:scalePixelToScreenHeight(12)
	self.infoTextOffsetY = self:scalePixelToScreenHeight(11)
end

function TopNotification:hide()
	if self.currentNotification.isValid then
		self.currentNotification.duration = 0
	end
end

function TopNotification:update(dt)
	if self.currentNotification.isValid then
		if self.currentNotification.duration <= 0 then
			self.currentNotification.isValid = false
			return
		end
		self.currentNotification.duration = self.currentNotification.duration - dt
	end
end

-- Local values: notification, posX, posY, centerX, icon, maxTextWidth, title, text, info
function TopNotification:draw()
	TopNotification:superClass().draw(self)
	local v25_ = self.currentNotification
	if v25_.isValid then
		local v26_, v27_ = self:getPosition()
		local v28_ = v27_ - self.bgScale.height
		self.bgScale:setPosition(v26_ - self.bgScale.width * 0.5, v28_)
		self.bgScale:render()
		self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, v28_)
		self.bgLeft:render()
		self.bgRight:setPosition(self.bgScale.x + self.bgScale.width, v28_)
		self.bgRight:render()
		local v29_ = v25_.icon
		if v29_ ~= nil then
			v29_:setPosition(self.bgLeft.x + self.iconOffsetX, self.bgLeft.y + self.iconOffsetY)
			v29_:render()
		end
		local v30_
		if v29_ == nil then
			v30_ = self.bgScale.width
		else
			v30_ = self.bgScale.width - 2 * self.iconWidth
		end
		local v31_ = Utils.limitTextToWidth(v25_.title, self.titleTextSize, v30_, false, "...")
		local v32_ = Utils.limitTextToWidth(v25_.text, self.textSize, v30_, false, "...")
		local v33_ = Utils.limitTextToWidth(v25_.info, self.infoTextSize, v30_, false, "...")
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(1, 1, 1, 1)
		renderText(v26_, v28_ + self.titleTextOffsetY, self.titleTextSize, v31_)
		renderText(v26_, v28_ + self.textOffsetY, self.textSize, v32_)
		setTextColor(1, 1, 1, 0.3)
		renderText(v26_, v28_ + self.infoTextOffsetY, self.infoTextSize, v33_)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
end

-- Local values: icon
function TopNotification:setNotification(title, text, info, iconFilename, duration)
	local v40_ = self.icons[iconFilename]
	if iconFilename ~= nil and v40_ == nil then
		v40_ = Overlay.new(iconFilename, 0, 0, self.iconWidth, self.iconHeight)
		self.icons[iconFilename] = v40_
	end
	self.currentNotification.title = utf8ToUpper(title)
	self.currentNotification.text = utf8ToUpper(text)
	self.currentNotification.info = info
	self.currentNotification.icon = v40_
	self.currentNotification.duration = duration or TopNotification.DEFAULT_DURATION
	self.currentNotification.isValid = true
end
if v1_ ~= nil then
	local v41_ = TopNotification.new()
	v41_:setScale(v1_.uiScale)
	v41_:setVisible(v1_.isVisible)
	g_currentMission.hud.topNotification = v41_
	g_currentMission.hud.displayComponents.topNotification = v41_
	Logging.info("Reloaded TopNotification")
end
