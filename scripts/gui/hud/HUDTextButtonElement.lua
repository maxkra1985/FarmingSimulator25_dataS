-- Local values: HUDTextButtonElement_mt
HUDTextButtonElement = {}
local HUDTextButtonElement_mt = Class(HUDTextButtonElement)

-- Upvalues: HUDTextButtonElement_mt
-- Local values: self
function HUDTextButtonElement.new(posX, posY, width, height, textSize, text, onClickedCallback)
	-- upvalues: (copy) HUDTextButtonElement_mt
	local v9_ = HUDTextButtonElement_mt
	local v10_ = setmetatable({}, v9_)
	v10_.positionX = posX
	v10_.positionY = posY
	v10_.width = width
	v10_.height = height
	v10_.frameNormalColor = {
		["r"] = 0.0284,
		["g"] = 0.0284,
		["b"] = 0.0284,
		["a"] = 0.85
	}
	v10_.frameHoveredColor = {
		["r"] = 0.0184,
		["g"] = 0.0184,
		["b"] = 0.0184,
		["a"] = 0.95
	}
	v10_.frame = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, width, height)
	v10_.frame:setColor(v10_.frameNormalColor.r, v10_.frameNormalColor.g, v10_.frameNormalColor.b, v10_.frameNormalColor.a)
	v10_.textDisplayOffsetX = width * 0.5
	v10_.textDisplayOffsetY = height * 0.5 - textSize * 0.5
	v10_.textDisplay = HUDTextDisplay.new(posX + v10_.textDisplayOffsetX, posY + v10_.textDisplayOffsetY, textSize * g_referenceScreenHeight, RenderText.ALIGN_CENTER)
	v10_.textDisplay:setText(text)
	v10_.onClickedCallback = onClickedCallback
	return v10_
end

function HUDTextButtonElement:delete()
	self.frame:delete()
	self.textDisplay:delete()
	self.onClickedCallback = nil
end

function HUDTextButtonElement:setVisible(isVisible)
	self.frame:setVisible(isVisible)
	self.textDisplay:setVisible(isVisible)
end

function HUDTextButtonElement:setText(text, textSize, textAlignment, textColor, textBold)
	self.textDisplay:setText(text, textSize, textAlignment, textColor, textBold)
end

function HUDTextButtonElement:setPosition(newX, newY)
	self.positionX = newX or self.positionX
	self.positionY = newY or self.positionY
	self.frame:setPosition(self.positionX, self.positionY)
	self.textDisplay:setPosition(self.positionX + self.textDisplayOffsetX, self.positionY + self.textDisplayOffsetY)
end

function HUDTextButtonElement:setFrameColor(r, g, b, a)
	self.frameNormalColor = {
		["r"] = r or self.frameNormalColor.r,
		["g"] = g or self.frameNormalColor.g,
		["b"] = b or self.frameNormalColor.b,
		["a"] = a or self.frameNormalColor.a
	}
	self.frame:setColor(self.frameNormalColor.r, self.frameNormalColor.g, self.frameNormalColor.b, self.frameNormalColor.a)
end

function HUDTextButtonElement:setFrameHoveredColor(r, g, b, a)
	self.frameHoveredColor = {
		["r"] = r or self.frameHoveredColor.r,
		["g"] = g or self.frameHoveredColor.g,
		["b"] = b or self.frameHoveredColor.b,
		["a"] = a or self.frameHoveredColor.a
	}
end
HUDTextButtonElement.setFrameColor = HUDTextButtonElement.setFrameColor
HUDTextButtonElement.setFrameHoveredColor = HUDTextButtonElement.setFrameHoveredColor

function HUDTextButtonElement:draw()
	self.frame:render()
	self.textDisplay:draw()
end

function HUDTextButtonElement:update(dt)
	self.textDisplay:update(dt)
end

function HUDTextButtonElement:mouseEvent(posX, posY, isDown, isUp, button)
	if self.positionX <= posX and (posX < self.positionX + self.width and (self.positionY <= posY and posY < self.positionY + self.height)) then
		if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.onClickedCallback) then
			self.onClickedCallback()
		end
		self.frame:setColor(self.frameHoveredColor.r, self.frameHoveredColor.g, self.frameHoveredColor.b, self.frameHoveredColor.a)
	else
		self.frame:setColor(self.frameNormalColor.r, self.frameNormalColor.g, self.frameNormalColor.b, self.frameNormalColor.a)
	end
end
