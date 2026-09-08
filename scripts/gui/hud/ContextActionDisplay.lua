-- Local values: data, old, ContextActionDisplay_mt, contextActionDisplay
local v1_
if ContextActionDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.contextActionDisplay
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
ContextActionDisplay = {}
ContextActionDisplay.CONTEXT_ICON = {
	["ATTACH"] = "attach",
	["FUEL"] = "fuel",
	["TIP"] = "tip",
	["FILL_BOWL"] = "fillBowl"
}
ContextActionDisplay.MIN_DISPLAY_DURATION = 100
local data = Class(ContextActionDisplay, HUDDisplay)

-- Upvalues: ContextActionDisplay_mt
-- Local values: self, r, g, b, a
function ContextActionDisplay.new(customMt)
	-- upvalues: (copy) data
	local v4_ = ContextActionDisplay:superClass().new(data)
	v4_.slicesIds = {}
	v4_.slicesIds[ContextActionDisplay.CONTEXT_ICON.ATTACH] = "gui.contextAction_icon_connect"
	v4_.slicesIds[ContextActionDisplay.CONTEXT_ICON.FUEL] = "gui.contextAction_icon_fuel"
	v4_.slicesIds[ContextActionDisplay.CONTEXT_ICON.TIP] = "gui.contextAction_icon_dump"
	v4_.slicesIds[ContextActionDisplay.CONTEXT_ICON.FILL_BOWL] = "gui.contextAction_icon_animalFood"
	v4_.glyphButtonOverlay = GlyphButtonOverlay.new()
	v4_.glyphButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
	v4_.keyButtonOverlay = ButtonOverlay.new()
	v4_.keyButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
	local v5_ = HUD.COLOR.ACTIVE
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.lastSliceId = v4_.slicesIds[ContextActionDisplay.CONTEXT_ICON.ATTACH]
	v4_.iconOverlay = g_overlayManager:createOverlay(v4_.lastSliceId, 0, 0, 0, 0)
	v4_.iconOverlay:setColor(v6_, v7_, v8_, v9_)
	v4_.controls = nil
	v4_.contextPriority = -math.huge
	v4_.text = nil
	v4_.displayTime = 0
	return v4_
end

function ContextActionDisplay:delete()
	self.glyphButtonOverlay:delete()
	self.keyButtonOverlay:delete()
	self.iconOverlay:delete()
end

-- Local values: offsetX, offsetY, posX, posY, iconWidth, iconHeight
function ContextActionDisplay:storeScaledValues()
	local v12_, v13_ = self:scalePixelValuesToScreenVector(0, 0)
	self:setPosition(0.5 + v12_, g_hudAnchorBottom + v13_)
	local v14_, v15_ = self:scalePixelValuesToScreenVector(64, 48)
	self.iconOverlay:setDimension(v14_, v15_)
	local v16_, v17_ = self:scalePixelValuesToScreenVector(5, -4)
	self.iconOffsetX = v16_
	self.iconOffsetY = v17_
	self.titleTextSize = self:scalePixelToScreenHeight(15)
	self.titleTextOffsetY = self:scalePixelToScreenHeight(5)
	self.textSize = self:scalePixelToScreenHeight(26)
	local v18_, v19_ = self:scalePixelValuesToScreenVector(10, 1)
	self.textOffsetX = v18_
	self.textOffsetY = v19_
	self.textMaxWidth = self:scalePixelToScreenWidth(500)
	self.buttonOffsetY = self:scalePixelToScreenHeight(8)
	self.buttonHeight = self:scalePixelToScreenHeight(25)
	self.keyButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
	self.glyphButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
end

function ContextActionDisplay:updateControls()
	if self.contextAction ~= nil then
		self.controls = g_inputDisplayManager:getControllerSymbolOverlays(self.contextAction, "", "", false)
	end
end

-- Local values: isVisible
function ContextActionDisplay:update(dt)
	ContextActionDisplay:superClass().update(self, dt)
	if self:getVisible() then
		self.displayTime = self.displayTime - dt
		if self.displayTime < 0 then
			self:setVisible(false)
			self:resetContext()
		end
	end
end

-- Local values: controls, buttons, keys, isComboButtonMapping, width, title, text, totalButtonWidth, i, key, keyWidth, totalWidth, textHeight, totalHeight, posX, posY, currentPosX, buttonPosY, i, key, iconPosY, activeColor
function ContextActionDisplay:draw()
	if not g_currentMission.hud.ingameMessage:getVisible() then
		local v24_ = self.controls
		if v24_ ~= nil then
			local v25_ = v24_.buttons
			local v26_ = v24_.keys
			local v27_ = v24_.isComboButtonMapping
			local v28_ = self.iconOverlay.width + self.iconOffsetX + self.textOffsetX
			local v29_ = self.actionText
			local v30_ = self.text
			local v31_ = 0
			if #v25_ > 0 then
				v31_ = self.glyphButtonOverlay:getButtonWidth(v25_, v27_, false, self.buttonHeight)
				v28_ = v28_ + v31_
			elseif #v26_ > 0 then
				for v32_ = #v26_, 1, -1 do
					local v33_ = v26_[v32_]
					local v34_ = self.keyButtonOverlay:getButtonWidth(v33_, self.buttonHeight) + g_pixelSizeX
					v28_ = v28_ + v34_
					v31_ = v31_ + v34_
				end
			end
			setTextWrapWidth(self.textMaxWidth)
			local v35_ = v28_ + getTextWidth(self.textSize, v30_)
			local v36_ = getTextHeight(self.textSize, v30_)
			local v37_ = v36_ + self.titleTextOffsetY + self.titleTextSize
			local v38_, v39_ = self:getPosition()
			local v40_ = v38_ - v35_ * 0.5
			local v41_ = v39_ + (v37_ - self.buttonHeight) * 0.5
			if #v25_ > 0 then
				self.glyphButtonOverlay:renderButton(v25_, v27_, false, v40_, v41_, self.buttonHeight)
			else
				for v42_ = #v26_, 1, -1 do
					local v43_ = v26_[v42_]
					self.keyButtonOverlay:renderButton(v43_, v40_, v41_, self.buttonHeight, true)
				end
			end
			local v44_ = v40_ + v31_
			local v45_ = v39_ + (v37_ - self.iconOverlay.height) * 0.5
			self.iconOverlay:setPosition(v44_ + self.iconOffsetX, v45_)
			self.iconOverlay:render()
			local v46_ = self.iconOverlay.x + self.iconOverlay.width
			local v47_ = HUD.COLOR.ACTIVE
			setTextColor(v47_[1], v47_[2], v47_[3], v47_[4])
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(v46_ + self.textOffsetX, v39_ + v36_ + self.titleTextOffsetY, self.titleTextSize, v29_)
			setTextColor(1, 1, 1, 1)
			setTextBold(false)
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
			renderText(v46_ + self.textOffsetX, v39_ + self.textOffsetY, self.textSize, v30_)
			setTextWrapWidth(0)
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		end
	end
end

-- Local values: newSliceId
function ContextActionDisplay:setContext(contextAction, contextIconName, text, priority, actionText)
	local v54_ = priority == nil and 0 or priority
	local v55_ = self.slicesIds[contextIconName]
	if self.contextPriority <= v54_ and v55_ ~= nil then
		self.contextAction = contextAction
		self.text = utf8ToUpper(text)
		self.actionText = utf8ToUpper(actionText)
		self.contextPriority = v54_
		if v55_ ~= self.lastSliceId then
			self.iconOverlay:setSliceId(v55_)
			self.lastSliceId = v55_
		end
		self:updateControls()
		self:setVisible(true)
		self.displayTime = ContextActionDisplay.MIN_DISPLAY_DURATION
	elseif contextAction == self.contextAction then
		self.displayTime = ContextActionDisplay.MIN_DISPLAY_DURATION
	end
end

function ContextActionDisplay:resetContext()
	self.controls = nil
	self.contextPriority = -math.huge
	self.text = nil
end
if v1_ ~= nil then
	local v57_ = ContextActionDisplay.new()
	v57_:setScale(v1_.uiScale)
	v57_:setVisible(v1_.isVisible)
	g_currentMission.hud.contextActionDisplay = v57_
	g_currentMission.hud.displayComponents.contextActionDisplay = v57_
	Logging.info("Reloaded ContextActionDisplay")
end
