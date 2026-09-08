-- Local values: data, old, ChatDisplay_mt, chatDisplay
local v1_
if ChatDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.chatDisplay
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
ChatDisplay = {}
ChatDisplay.DISPLAY_DURATION = 15000
local data = Class(ChatDisplay, HUDDisplay)
function ChatDisplay.new()
	-- upvalues: (copy) data
	local v4_ = ChatDisplay:superClass().new(data)
	local v5_ = HUD.COLOR.BACKGROUND
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.bgScale = g_overlayManager:createOverlay("gui.chat_middle", 0, 0, 0, 0)
	v4_.bgScale:setColor(v6_, v7_, v8_, v9_)
	v4_.bgTop = g_overlayManager:createOverlay("gui.chat_top", 0, 0, 0, 0)
	v4_.bgTop:setColor(v6_, v7_, v8_, v9_)
	v4_.bgBottom = g_overlayManager:createOverlay("gui.chat_bottom", 0, 0, 0, 0)
	v4_.bgBottom:setColor(v6_, v7_, v8_, v9_)
	v4_.messages = {}
	v4_.maxNumMessages = 50
	v4_.scrollOffset = 0
	v4_.closeTime = 0
	v4_.duration = 10000
	return v4_
end

function ChatDisplay:delete()
	self.bgScale:delete()
	self.bgTop:delete()
	self.bgBottom:delete()
end

-- Local values: offsetX, offsetY, minOffsetY, bgWidth, bgBottomHeight, bgTopHeight
function ChatDisplay:storeScaledValues()
	local v12_, v13_ = self:scalePixelValuesToScreenVector(0, 300)
	local v14_ = v13_ / self.uiScale
	self:setPosition(g_hudAnchorLeft + v12_, g_hudAnchorBottom + math.max(v13_, v14_))
	local v15_, v16_ = self:scalePixelValuesToScreenVector(300, 6)
	local v17_ = self:scalePixelToScreenHeight(6)
	self.bgBottom:setDimension(v15_, v16_)
	self.bgTop:setDimension(v15_, v17_)
	self.bgScale:setDimension(v15_, 0)
	self.messageOffsetY = self:scalePixelToScreenHeight(5)
	local v18_, v19_ = self:scalePixelValuesToScreenVector(6, -28)
	self.textOffsetX = v18_
	self.textOffsetY = v19_
	self.textSize = self:scalePixelToScreenHeight(12)
	self.maxTextWidth = v15_ - 2 * self.textOffsetX
	self.maxHeight = self:scalePixelToScreenHeight(300)
	local v20_, v21_ = self:scalePixelValuesToScreenVector(6, -13)
	self.titleOffsetX = v20_
	self.titleOffsetY = v21_
	self.titleHeight = self:scalePixelToScreenHeight(20)
	self.titleTextSize = self:scalePixelToScreenHeight(13)
end

function ChatDisplay:update(dt)
	if self:getVisible() and g_time > self.closeTime then
		self:setVisible(false)
	end
end

-- Local values: posX, posY, currentPosY, maxY, i, message, title, text, farmId, scaleHeight, r, g, b, a, farm, color
function ChatDisplay:draw()
	if not self:getVisible() then
		return
	end
	if #self.messages == 0 then
		return
	end
	if g_gui:getIsMenuVisible() and g_gui.currentGuiName ~= "ChatDialog" then
		return
	end
	ChatDisplay:superClass().draw(self)
	local v24_, v25_ = self:getPosition()
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	setTextWrapWidth(self.maxTextWidth, true)
	local v26_ = v25_ + self.maxHeight
	for v27_ = #self.messages - self.scrollOffset, 1, -1 do
		local v28_ = self.messages[v27_]
		local v29_ = v28_.title
		local v30_ = v28_.text
		local v31_ = v28_.farmId
		setTextBold(false)
		local v32_ = getTextHeight(self.textSize, v30_) + self.titleHeight
		if v26_ < v25_ + v32_ + self.bgTop.height + self.bgBottom.height then
			break
		end
		self.bgBottom:setPosition(v24_, v25_)
		self.bgBottom:render()
		self.bgScale:setPosition(v24_, self.bgBottom.y + self.bgBottom.height)
		self.bgScale:setDimension(nil, v32_)
		self.bgScale:render()
		self.bgTop:setPosition(v24_, self.bgScale.y + self.bgScale.height)
		self.bgTop:render()
		setTextColor(1, 1, 1, 1)
		renderText(v24_ + self.textOffsetX, self.bgTop.y + self.textOffsetY, self.textSize, v30_)
		setTextBold(true)
		local v33_ = 1
		local v34_ = 1
		local v35_ = 1
		local v36_ = 1
		if v31_ ~= 0 then
			local v37_ = g_farmManager:getFarmById(v31_)
			if v37_ ~= nil then
				local v38_ = v37_:getColor()
				v33_ = v38_[1]
				v34_ = v38_[2]
				v35_ = v38_[3]
				v36_ = 1
			end
		end
		setTextColor(v33_, v34_, v35_, v36_)
		local v39_ = string.format("(%d) %s", v27_, v29_)
		renderText(v24_ + self.titleOffsetX, self.bgTop.y + self.titleOffsetY, self.titleTextSize, v39_)
		v25_ = self.bgTop.y + self.bgTop.height + self.messageOffsetY
	end
	setTextBold(false)
	setTextWrapWidth(0)
end

function ChatDisplay:addMessage(text, sender, farmId)
	while #self.messages >= self.maxNumMessages do
		table.remove(self.messages, 1)
	end
	local v44_ = self.messages
	local v45_ = {
		["text"] = text,
		["title"] = string.format("%s %s", getDate("%H:%M:%S"), sender),
		["farmId"] = farmId
	}
	table.insert(v44_, v45_)
	self:scrollChatMessages(0)
end

function ChatDisplay:setVisible(isVisible)
	ChatDisplay:superClass().setVisible(self, isVisible)
	if isVisible then
		self.closeTime = g_time + self.duration
	end
end

function ChatDisplay:scrollChatMessages(delta)
	local v50_ = self.scrollOffset + delta
	local v51_ = #self.messages - 1
	local v52_ = math.max(0, v51_)
	self.scrollOffset = math.clamp(v50_, 0, v52_)
end

function ChatDisplay:getHasNewMessages()
	return false
end
if v1_ ~= nil then
	local v53_ = ChatDisplay.new()
	v53_:setScale(v1_.uiScale)
	v53_:setVisible(v1_.isVisible)
	g_currentMission.hud.chatDisplay = v53_
	g_currentMission.hud.displayComponents.chatDisplay = v53_
	Logging.info("Reloaded ChatDisplay")
end
