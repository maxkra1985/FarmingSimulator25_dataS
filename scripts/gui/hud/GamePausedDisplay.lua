-- Local values: data, old, GamePausedDisplay_mt, gamePausedDisplay
local v1_
if GamePausedDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.gamePausedDisplay
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
GamePausedDisplay = {}
local data = Class(GamePausedDisplay, HUDDisplay)
function GamePausedDisplay.new()
	-- upvalues: (copy) data
	local v4_ = SideNotification:superClass().new(data)
	v4_.syncBackground = Overlay.new("shared/splash.png", 0, 0, 1, g_screenAspectRatio)
	v4_.pauseText = utf8ToUpper("Pausiert")
	return v4_
end

function GamePausedDisplay:delete()
	self.syncBackground:delete()
end

-- Local values: posX, posY
function GamePausedDisplay:storeScaledValues()
	self:setPosition(0.5, 0.5)
	self.width = 1
	self.height = self:scalePixelToScreenHeight(75)
	self.textSize = self:scalePixelToScreenHeight(26)
	self.textOffsetY = self:scalePixelToScreenHeight(28)
end

-- Local values: posX, posY
function GamePausedDisplay:draw(drawBackground)
	if self:getVisible() then
		GamePausedDisplay:superClass().draw(self)
		if drawBackground then
			self.syncBackground:render()
		end
		local v9_, v10_ = self:getPosition()
		local v11_ = v10_ - self.height * 0.5
		drawFilledRect(0, v11_, 1, self.height, 0, 0, 0, 0.8)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(1, 1, 1, 1)
		renderText(v9_, v11_ + self.textOffsetY, self.textSize, self.pauseText)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
end

function GamePausedDisplay:setPauseText(text)
	self.pauseText = utf8ToUpper(text)
end
if v1_ ~= nil then
	local v14_ = GamePausedDisplay.new()
	v14_:setScale(v1_.uiScale)
	v14_:setVisible(v1_.isVisible)
	g_currentMission.hud.gamePausedDisplay = v14_
	g_currentMission.hud.displayComponents.gamePausedDisplay = v14_
	Logging.info("Reloaded GamePausedDisplay")
end
