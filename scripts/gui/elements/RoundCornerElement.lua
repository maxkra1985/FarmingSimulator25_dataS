-- Local values: RoundCornerElement_mt
RoundCornerElement = {}
local RoundCornerElement_mt = Class(RoundCornerElement, GuiElement)
Gui.registerGuiElement("RoundCorner", RoundCornerElement)

-- Upvalues: RoundCornerElement_mt
-- Local values: self
function RoundCornerElement.new(target, custom_mt)
	-- upvalues: (copy) RoundCornerElement_mt
	local v4_ = GuiElement.new(target, custom_mt or RoundCornerElement_mt)
	v4_.color = {
		1,
		1,
		1,
		1
	}
	v4_.cornerSize = 1
	return v4_
end

-- Local values: color
function RoundCornerElement:loadFromXML(xmlFile, key)
	RoundCornerElement:superClass().loadFromXML(self, xmlFile, key)
	local v8_ = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#color"))
	if v8_ ~= nil then
		self.color = v8_
	end
	local v9_ = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorDisabled"))
	if v9_ ~= nil then
		self.colorDisabled = v9_
	end
	local v10_ = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorHighlighted"))
	if v10_ ~= nil then
		self.colorHighlighted = v10_
	end
	local v11_ = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorSelected"))
	if v11_ ~= nil then
		self.colorSelected = v11_
	end
	local v12_ = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorFocused"))
	if v12_ ~= nil then
		self.colorFocused = v12_
	end
	local v13_ = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorPressed"))
	if v13_ ~= nil then
		self.colorPressed = v13_
	end
	self.cornerSize = getXMLFloat(xmlFile, key .. "#cornerSize") or self.cornerSize
end

-- Local values: color
function RoundCornerElement:loadProfile(profile, applyProfile)
	RoundCornerElement:superClass().loadProfile(self, profile, applyProfile)
	local v17_ = GuiUtils.getColorGradientArray(profile:getValue("color"))
	if v17_ ~= nil then
		self.color = v17_
	end
	local v18_ = GuiUtils.getColorGradientArray(profile:getValue("colorDisabled"))
	if v18_ ~= nil then
		self.colorDisabled = v18_
	end
	local v19_ = GuiUtils.getColorGradientArray(profile:getValue("colorFocused"))
	if v19_ ~= nil then
		self.colorFocused = v19_
	end
	local v20_ = GuiUtils.getColorGradientArray(profile:getValue("colorSelected"))
	if v20_ ~= nil then
		self.colorSelected = v20_
	end
	local v21_ = GuiUtils.getColorGradientArray(profile:getValue("colorHighlighted"))
	if v21_ ~= nil then
		self.colorHighlighted = v21_
	end
	local v22_ = GuiUtils.getColorGradientArray(profile:getValue("colorPressed"))
	if v22_ ~= nil then
		self.colorPressed = v22_
	end
	local v23_ = self.cornerSize
	self.cornerSize = tonumber(profile:getValue("cornerSize", v23_))
end

function RoundCornerElement:copyAttributes(src)
	RoundCornerElement:superClass().copyAttributes(self, src)
	self.color = table.copyIndex(src.color)
	if src.colorDisabled ~= nil then
		self.colorDisabled = table.copyIndex(src.colorDisabled)
	end
	if src.colorFocused ~= nil then
		self.colorFocused = table.copyIndex(src.colorFocused)
	end
	if src.colorSelected ~= nil then
		self.colorSelected = table.copyIndex(src.colorSelected)
	end
	if src.colorPressed ~= nil then
		self.colorPressed = table.copyIndex(src.colorPressed)
	end
	if src.colorHighlighted ~= nil then
		self.colorHighlighted = table.copyIndex(src.colorHighlighted)
	end
	self.cornerSize = src.cornerSize
end

-- Local values: returnColor
function RoundCornerElement:getColor()
	local v27_ = nil
	if self:getIsDisabled() then
		v27_ = self.colorDisabled
	elseif self.getIsPressed == nil or not self:getIsPressed() then
		if self:getIsSelected() then
			v27_ = self.colorSelected
		elseif self:getIsFocused() then
			v27_ = self.colorFocused
		elseif self:getIsHighlighted() then
			v27_ = self.colorHighlighted
		end
	else
		v27_ = self.colorPressed
	end
	return v27_ or self.color
end

-- Local values: color
function RoundCornerElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v33_ = self:getColor()
	drawFilledRectRound(self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.cornerSize, v33_[1], v33_[2], v33_[3], v33_[4], clipX1, clipY1, clipX2, clipY2)
	RoundCornerElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
