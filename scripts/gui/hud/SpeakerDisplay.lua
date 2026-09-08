-- Local values: data, old, SpeakerDisplay_mt, speakerDisplay
local v1_
if SpeakerDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.speakerDisplay
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
SpeakerDisplay = {}
local data = Class(SpeakerDisplay, HUDDisplay)

-- Upvalues: SpeakerDisplay_mt
-- Local values: self, r, g, b, a
function SpeakerDisplay.new(customMt)
	-- upvalues: (copy) data
	local v4_ = SpeakerDisplay:superClass().new(data)
	local v5_ = HUD.COLOR.BACKGROUND
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.bgScale = g_overlayManager:createOverlay("gui.rectangle_center", 0, 0, 0, 0)
	v4_.bgScale:setColor(v6_, v7_, v8_, v9_)
	v4_.bgLeft = g_overlayManager:createOverlay("gui.rectangle_left", 0, 0, 0, 0)
	v4_.bgLeft:setColor(v6_, v7_, v8_, v9_)
	v4_.bgRight = g_overlayManager:createOverlay("gui.rectangle_right", 0, 0, 0, 0)
	v4_.bgRight:setColor(v6_, v7_, v8_, v9_)
	v4_.iconTalk = g_overlayManager:createOverlay("gui.multiplayer_chatTalk", 0, 0, 0, 0)
	v4_.iconTalk:setColor(1, 1, 1, 0.5)
	v4_.iconMuted = g_overlayManager:createOverlay("gui.multiplayer_soundMute", 0, 0, 0, 0)
	v4_.iconMuted:setColor(1, 1, 1, 0.5)
	v4_.speakingTimer = {}
	return v4_
end

function SpeakerDisplay:delete()
	self.bgScale:delete()
	self.bgLeft:delete()
	self.bgRight:delete()
	self.iconTalk:delete()
	self.iconMuted:delete()
end

-- Local values: offsetX, offsetY, posX, posY, bgRightWidth, bgHeight, bgLeftWidth, iconWidth, iconHeight, iconOffsetX
function SpeakerDisplay:storeScaledValues()
	local v12_, v13_ = self:scalePixelValuesToScreenVector(0, -300)
	self:setPosition(g_hudAnchorRight + v12_, g_hudAnchorTop + v13_)
	local v14_, v15_ = self:scalePixelValuesToScreenVector(10, 25)
	local v16_ = self:scalePixelToScreenWidth(10)
	self.bgRight:setDimension(v14_, v15_)
	self.bgLeft:setDimension(v16_, v15_)
	self.bgScale:setDimension(0, v15_)
	self.textSize = self:scalePixelToScreenHeight(16)
	self.textOffsetY = self:scalePixelToScreenHeight(6)
	self.speakerOffsetY = self:scalePixelToScreenHeight(6)
	local v17_, v18_ = self:scalePixelValuesToScreenVector(24, 24)
	self.iconTalk:setDimension(v17_, v18_)
	self.iconMuted:setDimension(v17_, v18_)
	self.iconTotalOffsetX = v17_ + self:scalePixelToScreenWidth(6)
end

-- Local values: userId, time, newTime
function SpeakerDisplay:update(dt)
	SpeakerDisplay:superClass().update(self, dt)
	for v21_, v22_ in pairs(self.speakingTimer) do
		local v23_ = v22_ - dt
		if v23_ < 0 then
			v23_ = nil
		end
		self.speakingTimer[v21_] = v23_
	end
end

-- Local values: users, posX, posY, _, user, uuid, isSpeakingNow, text, textWidth, scaleWidth, isMuted
function SpeakerDisplay:draw()
	SpeakerDisplay:superClass().draw(self)
	local v25_ = g_currentMission.userManager:getUsers()
	if #v25_ ~= 0 then
		new2DLayer()
		local v26_, v27_ = self:getPosition()
		setTextBold(true)
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		for _, v28_ in ipairs(v25_) do
			local v29_ = v28_:getUniqueUserId()
			local v30_ = VoiceChatUtil.getIsSpeakerActive(v29_)
			if v30_ then
				v30_ = not v28_:getIsBlocked()
			end
			if v30_ then
				self.speakingTimer[v29_] = 500
			end
			if self.speakingTimer[v29_] ~= nil then
				local v31_ = utf8ToUpper(v28_:getNickname())
				v27_ = v27_ - self.bgRight.height - self.speakerOffsetY
				local v32_ = getTextWidth(self.textSize, v31_) + self.iconTotalOffsetX
				self.bgRight:setPosition(v26_ - self.bgRight.width, v27_)
				self.bgRight:render()
				self.bgScale:setDimension(v32_, nil)
				self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, v27_)
				self.bgScale:render()
				self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, v27_)
				self.bgLeft:render()
				if v28_:getVoiceMuted() then
					self.iconMuted:renderCustom(self.bgRight.x - self.iconTalk.width, self.bgRight.y)
				else
					self.iconTalk:renderCustom(self.bgRight.x - self.iconTalk.width, self.bgRight.y)
				end
				renderText(self.bgRight.x - self.iconTotalOffsetX, self.bgRight.y + self.textOffsetY, self.textSize, v31_)
			end
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
end
if v1_ ~= nil then
	local v33_ = SpeakerDisplay.new()
	v33_:setScale(v1_.uiScale)
	v33_:setVisible(v1_.isVisible)
	g_currentMission.hud.speakerDisplay = v33_
	g_currentMission.hud.displayComponents.speakerDisplay = v33_
	Logging.info("Reloaded SpeakerDisplay")
end
