local data = nil
if SideNotificationMobile ~= nil then
	local old = g_currentMission.hud.sideNotifications
	data = {}
	data.notificationQueue = old.notificationQueue
	data.uiScale = old.uiScale
	old:delete()
end
SideNotificationMobile = {}
local SideNotificationMobile_mt = Class(SideNotificationMobile, SideNotification)
function SideNotificationMobile.new()
	local self = SideNotificationMobile:superClass().new(SideNotificationMobile_mt)
	self.uiScale = 1
	self.r, self.g, self.b, self.a = unpack(SideNotificationMobile.COLOR.BACKGROUND)
	self:applyValues(self.uiScale)
	return self
end
function SideNotificationMobile:setScale(uiScale)
	SideNotificationMobile:superClass().setScale(self, uiScale)
	self.uiScale = uiScale
	local posX, posY = SideNotificationMobile.getBackgroundPosition(uiScale)
	self:setPosition(posX, posY)
	self:applyValues(uiScale)
end
function SideNotificationMobile:applyValues(uiScale)
	local _, textSize = getNormalizedScreenValues(0, SideNotificationMobile.TEXT_SIZE.DEFAULT_NOTIFICATION)
	self.textSize = textSize * uiScale
	local textOffsetX, textOffsetY = getNormalizedScreenValues(unpack(SideNotificationMobile.POSITION.TEXT_OFFSET))
	self.textOffsetX = textOffsetX * uiScale
	self.textOffsetY = textOffsetY * uiScale
	local _, bgHeight = getNormalizedScreenValues(0, SideNotificationMobile.SIZE.BG_HEIGHT)
	self.bgHeight = bgHeight * uiScale
	local _, offsetY = getNormalizedScreenValues(0, SideNotificationMobile.POSITION.OFFSET)
	self.offsetY = offsetY * uiScale
end
function SideNotificationMobile:updateSizeAndPositions() end
function SideNotificationMobile:draw()
	if self:getVisible() and 0 < #self.notificationQueue then
		local baseX, baseY = self:getPosition()
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		local textOffsetX = self.textOffsetX
		local textOffsetY = self.textOffsetY
		local textSize = self.textSize
		local offsetY = self.offsetY
		local bgHeight = self.bgHeight
		local r = self.r
		local g = self.g
		local b = self.b
		local a = self.a
		for i = 1, math.min(#self.notificationQueue, SideNotification.MAX_NOTIFICATIONS) do
			local notification = self.notificationQueue[i]
			local fadeAlpha = 1
			if notification.startDuration - notification.duration < SideNotification.FADE_DURATION then
				fadeAlpha = (notification.startDuration - notification.duration) / SideNotification.FADE_DURATION
			elseif notification.duration < SideNotification.FADE_DURATION then
				fadeAlpha = notification.duration / SideNotification.FADE_DURATION
			end
			local textWidth = getTextWidth(textSize, notification.text)
			textWidth = textWidth + 2 * textOffsetX
			local posX = baseX - textWidth
			local posY = baseY - i * bgHeight - (i - 1) * offsetY
			drawFilledRectRound(posX, posY, textWidth, bgHeight, self.uiScale, r, g, b, a * fadeAlpha)
			setTextColor(notification.color[1], notification.color[2], notification.color[3], notification.color[4] * fadeAlpha)
			renderText(posX + textOffsetX, posY + textOffsetY, textSize, notification.text)
			setTextColor(1, 1, 1, 1)
		end
	end
end
function SideNotificationMobile.getBackgroundPosition(uiScale)
	local offX, offY = getNormalizedScreenValues(unpack(SideNotificationMobile.POSITION.SELF))
	return 1 + offX * uiScale, 1 + offY * uiScale
end
function SideNotificationMobile:createBackground()
	local posX, posY = SideNotificationMobile.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(SideNotificationMobile.SIZE.SELF))
	local overlay = Overlay.new(nil, posX - width, posY - height, width, height)
	return overlay
end
SideNotificationMobile.POSITION = { SELF = { -45, -160 }, TEXT_OFFSET = { 10, 11 }, OFFSET = 6 }
SideNotificationMobile.SIZE = { SELF = { 1, 1 }, BG_HEIGHT = 46 }
SideNotificationMobile.COLOR = { BACKGROUND = { 0, 0, 0, 0.4 } }
SideNotificationMobile.TEXT_SIZE = { DEFAULT_NOTIFICATION = 32 }
if data ~= nil then
	local sideNotifications = SideNotificationMobile.new(g_baseHUDFilename)
	sideNotifications:setScale(data.uiScale)
	sideNotifications.notificationQueue = data.notificationQueue
	for k, elem in ipairs(g_currentMission.hud.displayComponents) do
		if elem == g_currentMission.hud.sideNotifications then
			g_currentMission.hud.displayComponents[k] = sideNotifications
			break
		end
	end
	g_currentMission.hud.sideNotifications = sideNotifications
	Logging.info("Reloaded")
end
