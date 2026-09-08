-- Local values: data, old, SideNotificationMobile_mt, sideNotifications, k, elem
local v1_
if SideNotificationMobile == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.sideNotifications
	v1_ = {
		["notificationQueue"] = v2_.notificationQueue,
		["uiScale"] = v2_.uiScale
	}
	v2_:delete()
end
SideNotificationMobile = {}
local data = Class(SideNotificationMobile, SideNotification)
function SideNotificationMobile.new()
	-- upvalues: (copy) data
	local v4_ = SideNotificationMobile:superClass().new(data)
	v4_.uiScale = 1
	local v5_ = SideNotificationMobile.COLOR.BACKGROUND
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.r = v6_
	v4_.g = v7_
	v4_.b = v8_
	v4_.a = v9_
	v4_:applyValues(v4_.uiScale)
	return v4_
end

-- Local values: posX, posY
function SideNotificationMobile:setScale(uiScale)
	SideNotificationMobile:superClass().setScale(self, uiScale)
	self.uiScale = uiScale
	local v12_, v13_ = SideNotificationMobile.getBackgroundPosition(uiScale)
	self:setPosition(v12_, v13_)
	self:applyValues(uiScale)
end

-- Local values: _, textSize, textOffsetX, textOffsetY, _, bgHeight, _, offsetY
function SideNotificationMobile:applyValues(uiScale)
	local _, v16_ = getNormalizedScreenValues(0, SideNotificationMobile.TEXT_SIZE.DEFAULT_NOTIFICATION)
	self.textSize = v16_ * uiScale
	local v17_ = getNormalizedScreenValues
	local v18_ = SideNotificationMobile.POSITION.TEXT_OFFSET
	local v19_, v20_ = v17_(unpack(v18_))
	local v21_ = v19_ * uiScale
	local v22_ = v20_ * uiScale
	self.textOffsetX = v21_
	self.textOffsetY = v22_
	local _, v23_ = getNormalizedScreenValues(0, SideNotificationMobile.SIZE.BG_HEIGHT)
	self.bgHeight = v23_ * uiScale
	local _, v24_ = getNormalizedScreenValues(0, SideNotificationMobile.POSITION.OFFSET)
	self.offsetY = v24_ * uiScale
end

function SideNotificationMobile:updateSizeAndPositions() end

-- Local values: baseX, baseY, textOffsetX, textOffsetY, textSize, offsetY, bgHeight, r, g, b, a, i, notification, fadeAlpha, textWidth, posX, posY
function SideNotificationMobile:draw()
	if self:getVisible() and #self.notificationQueue > 0 then
		local v26_, v27_ = self:getPosition()
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v28_ = self.textOffsetX
		local v29_ = self.textOffsetY
		local v30_ = self.textSize
		local v31_ = self.offsetY
		local v32_ = self.bgHeight
		local v33_ = self.r
		local v34_ = self.g
		local v35_ = self.b
		local v36_ = self.a
		local v37_ = #self.notificationQueue
		local v38_ = SideNotification.MAX_NOTIFICATIONS
		for v39_ = 1, math.min(v37_, v38_) do
			local v40_ = self.notificationQueue[v39_]
			local v41_ = 1
			if v40_.startDuration - v40_.duration < SideNotification.FADE_DURATION then
				v41_ = (v40_.startDuration - v40_.duration) / SideNotification.FADE_DURATION
			elseif v40_.duration < SideNotification.FADE_DURATION then
				v41_ = v40_.duration / SideNotification.FADE_DURATION
			end
			local v42_ = getTextWidth(v30_, v40_.text) + 2 * v28_
			local v43_ = v26_ - v42_
			local v44_ = v27_ - v39_ * v32_ - (v39_ - 1) * v31_
			drawFilledRectRound(v43_, v44_, v42_, v32_, self.uiScale, v33_, v34_, v35_, v36_ * v41_)
			setTextColor(v40_.color[1], v40_.color[2], v40_.color[3], v40_.color[4] * v41_)
			renderText(v43_ + v28_, v44_ + v29_, v30_, v40_.text)
			setTextColor(1, 1, 1, 1)
		end
	end
end

-- Local values: offX, offY
function SideNotificationMobile.getBackgroundPosition(uiScale)
	local v46_ = getNormalizedScreenValues
	local v47_ = SideNotificationMobile.POSITION.SELF
	local v48_, v49_ = v46_(unpack(v47_))
	return 1 + v48_ * uiScale, 1 + v49_ * uiScale
end

-- Local values: posX, posY, width, height, overlay
function SideNotificationMobile:createBackground()
	local v50_, v51_ = SideNotificationMobile.getBackgroundPosition(1)
	local v52_ = getNormalizedScreenValues
	local v53_ = SideNotificationMobile.SIZE.SELF
	local v54_, v55_ = v52_(unpack(v53_))
	return Overlay.new(nil, v50_ - v54_, v51_ - v55_, v54_, v55_)
end
SideNotificationMobile.POSITION = {
	["SELF"] = { -45, -160 },
	["TEXT_OFFSET"] = { 10, 11 },
	["OFFSET"] = 6
}
SideNotificationMobile.SIZE = {
	["SELF"] = { 1, 1 },
	["BG_HEIGHT"] = 46
}
SideNotificationMobile.COLOR = {
	["BACKGROUND"] = {
		0,
		0,
		0,
		0.4
	}
}
SideNotificationMobile.TEXT_SIZE = {
	["DEFAULT_NOTIFICATION"] = 32
}
if v1_ ~= nil then
	local v56_ = SideNotificationMobile.new(g_baseHUDFilename)
	v56_:setScale(v1_.uiScale)
	v56_.notificationQueue = v1_.notificationQueue
	for v57_, v58_ in ipairs(g_currentMission.hud.displayComponents) do
		if v58_ == g_currentMission.hud.sideNotifications then
			g_currentMission.hud.displayComponents[v57_] = v56_
			break
		end
	end
	g_currentMission.hud.sideNotifications = v56_
	Logging.info("Reloaded")
end
