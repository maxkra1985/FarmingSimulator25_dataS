-- Local values: InputGlyphElementUI_mt
InputGlyphElementUI = {}
local InputGlyphElementUI_mt = Class(InputGlyphElementUI, GuiElement)
Gui.registerGuiElement("InputGlyph", InputGlyphElementUI)

-- Upvalues: InputGlyphElementUI_mt
-- Local values: self
function InputGlyphElementUI.new(target, custom_mt)
	-- upvalues: (copy) InputGlyphElementUI_mt
	local v4_ = GuiElement.new(target, custom_mt or InputGlyphElementUI_mt)
	v4_.glyphColor = {
		1,
		1,
		1,
		1
	}
	v4_.buttonGlyphColor = {
		1,
		1,
		1,
		1
	}
	v4_.glyphBackgroundColor = {
		0.00913,
		0.01033,
		0.00651,
		1
	}
	v4_.isLeftAligned = false
	v4_.actionNames = {}
	return v4_
end

function InputGlyphElementUI:delete()
	if self.glyphElement ~= nil then
		self.glyphElement:delete()
		self.glyphElement = nil
	end
	InputGlyphElementUI:superClass().delete(self)
end

-- Local values: actionNames, actionName, actionName2
function InputGlyphElementUI:loadFromXML(xmlFile, key)
	InputGlyphElementUI:superClass().loadFromXML(self, xmlFile, key)
	self.glyphColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#glyphColor"), self.glyphColor)
	self.buttonGlyphColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#buttonGlyphColor"), self.buttonGlyphColor)
	self.glyphBackgroundColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#glyphBackgroundColor"), self.glyphBackgroundColor)
	self.isLeftAligned = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isLeftAligned"), self.isLeftAligned)
	self:buildGlyph()
	local v9_ = {}
	local v10_ = getXMLString(xmlFile, key .. "#inputAction")
	if v10_ == nil or InputAction[v10_] == nil then
		if self.actionNames ~= nil and #self.actionNames > 0 then
			self:setActions(self.actionNames, nil, nil, nil)
		end
	else
		table.insert(v9_, v10_)
		local v11_ = getXMLString(xmlFile, key .. "#inputAction2")
		if v11_ ~= nil and InputAction[v11_] ~= nil then
			table.insert(v9_, v11_)
		end
		self.actionNames = table.clone(v9_)
		self:setActions(v9_, nil, nil, nil)
	end
end

-- Local values: actionNames, actionName, actionName2
function InputGlyphElementUI:loadProfile(profile, applyProfile)
	InputGlyphElementUI:superClass().loadProfile(self, profile, applyProfile)
	self.glyphColor = GuiUtils.getColorArray(profile:getValue("glyphColor"), self.glyphColor)
	self.buttonGlyphColor = GuiUtils.getColorArray(profile:getValue("buttonGlyphColor"), self.buttonGlyphColor)
	self.glyphBackgroundColor = GuiUtils.getColorArray(profile:getValue("glyphBackgroundColor"), self.glyphBackgroundColor)
	self.isLeftAligned = Utils.getNoNil(profile:getBool("isLeftAligned"), self.isLeftAligned)
	self:buildGlyph()
	local v15_ = {}
	local v16_ = profile:getValue("inputAction", self.inputActionName)
	if v16_ ~= nil and InputAction[v16_] ~= nil then
		table.insert(v15_, v16_)
		local v17_ = profile:getValue("inputAction2", self.inputActionName)
		if v17_ ~= nil and InputAction[v17_] ~= nil then
			table.insert(v15_, v17_)
		end
		self.actionNames = table.clone(v15_)
	end
end

-- Local values: actionNames
function InputGlyphElementUI:copyAttributes(src)
	InputGlyphElementUI:superClass().copyAttributes(self, src)
	self.glyphColor = table.clone(src.glyphColor)
	self.buttonGlyphColor = table.clone(src.buttonGlyphColor)
	self.glyphBackgroundColor = table.clone(src.glyphBackgroundColor)
	self.isLeftAligned = src.isLeftAligned
	local v20_ = table.clone(src.actionNames)
	self.actionNames = table.clone(v20_)
	if src.glyphElement ~= nil then
		self:buildGlyph()
		if #v20_ > 0 then
			self:setActions(v20_, nil, nil, nil)
		end
	end
end

function InputGlyphElementUI:buildGlyph()
	if self.glyphElement == nil then
		if Platform.isMobile then
			self.glyphElement = InputGlyphMobileElement.new(g_inputDisplayManager)
		else
			self.glyphElement = InputGlyphElement.new(g_inputDisplayManager, self.absSize[1], self.absSize[2])
		end
	end
	self.glyphElement:setButtonGlyphColor(self.buttonGlyphColor)
	self.glyphElement:setKeyboardGlyphColor(self.glyphColor, self.glyphBackgroundColor)
	self.glyphElement:setIsLeftAligned(self.isLeftAligned)
end

function InputGlyphElementUI:updateAbsolutePosition()
	InputGlyphElementUI:superClass().updateAbsolutePosition(self)
	if self.glyphElement ~= nil then
		self.glyphElement:setPosition(self.absPosition[1], self.absPosition[2])
		if not Platform.isMobile then
			self.glyphElement:setDimension(self.originalWidth or self.absSize[1], self.absSize[2])
			self.glyphElement:setBaseSize(self.originalWidth or self.absSize[1], self.absSize[2])
		end
		self.didSetAbsolutePosition = true
	end
end

function InputGlyphElementUI:draw(clipX1, clipY1, clipX2, clipY2)
	InputGlyphElementUI:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
	if self.glyphElement ~= nil then
		self.glyphElement:draw(clipX1, clipY1, clipX2, clipY2)
	end
end

function InputGlyphElementUI:setActions(actions, actionText, actionTextSize, noModifiers, customBinding)
	if self.glyphElement ~= nil then
		self.glyphElement:setActions(actions, actionText, actionTextSize, noModifiers, customBinding)
		if not self.didSetAbsolutePosition then
			self:updateAbsolutePosition()
		end
		if self.originalWidth == nil then
			self.originalWidth = self.absSize[1]
		end
		self.glyphElement:setBaseSize(self.originalWidth, self.absSize[2])
		self:setSize(self.glyphElement:getGlyphWidth())
		if self.parent ~= nil and self.parent.invalidateLayout ~= nil then
			self.parent:invalidateLayout()
		end
	end
end
