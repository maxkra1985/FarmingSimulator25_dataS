-- Local values: TextBackdropElement_mt
TextBackdropElement = {}
local TextBackdropElement_mt = Class(TextBackdropElement, BitmapElement)
Gui.registerGuiElement("TextBackdrop", TextBackdropElement)

-- Upvalues: TextBackdropElement_mt
-- Local values: self
function TextBackdropElement.new(target, custom_mt)
	-- upvalues: (copy) TextBackdropElement_mt
	local v4_ = BitmapElement.new(target, custom_mt or TextBackdropElement_mt)
	v4_.padding = {
		0,
		0,
		0,
		0
	}
	return v4_
end

function TextBackdropElement:loadFromXML(xmlFile, key)
	TextBackdropElement:superClass().loadFromXML(self, xmlFile, key)
	self.padding = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#padding"), self.padding)
end

function TextBackdropElement:loadProfile(profile, applyProfile)
	TextBackdropElement:superClass().loadProfile(self, profile, applyProfile)
	self.padding = GuiUtils.getNormalizedScreenValues(profile:getValue("padding"), self.padding)
end

function TextBackdropElement:copyAttributes(src)
	TextBackdropElement:superClass().copyAttributes(self, src)
	self.padding = table.clone(src.padding)
end

-- Local values: clonedElement
function TextBackdropElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	local v18_ = TextBackdropElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	v18_:installTextElement()
	return v18_
end

function TextBackdropElement:onGuiSetupFinished()
	TextBackdropElement:superClass().onGuiSetupFinished(self)
	self:installTextElement()
end

function TextBackdropElement:installTextElement()
	assertWithCallstack(#self.elements > 0)
	self.textElement = self.elements[1]
	assertWithCallstack(self.textElement:isa(TextElement))
	self.textElement.setSize = Utils.overwrittenFunction(self.textElement.setSize, function(p21_, p22_, p23_, p24_)
		-- upvalues: (copy) self
		p22_(p21_, p23_, p24_)
		self:updateSizeAndContents(p23_ * g_aspectScaleX)
	end)
	self:updateSizeAndContents(self.textElement.absSize[1])
end

-- Local values: width
function TextBackdropElement:updateSizeAndContents(textElementWidth)
	self:setSize(textElementWidth + self.padding[1] + self.padding[3], nil)
	self.elements[1]:setPosition(self.padding[1])
end
