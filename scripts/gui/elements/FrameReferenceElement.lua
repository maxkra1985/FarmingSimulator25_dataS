-- Local values: FrameReferenceElement_mt
FrameReferenceElement = {}
local FrameReferenceElement_mt = Class(FrameReferenceElement, GuiElement)
Gui.registerGuiElement("FrameReference", FrameReferenceElement)
Gui.registerGuiElementProcFunction("FrameReference", Gui.resolveFrameReference)

-- Upvalues: FrameReferenceElement_mt
-- Local values: self
function FrameReferenceElement.new(target, custom_mt)
	-- upvalues: (copy) FrameReferenceElement_mt
	local v4_ = GuiElement.new(target, custom_mt or FrameReferenceElement_mt)
	v4_.referencedFrameName = ""
	return v4_
end

function FrameReferenceElement:loadFromXML(xmlFile, key)
	FrameReferenceElement:superClass().loadFromXML(self, xmlFile, key)
	self.referencedFrameName = getXMLString(xmlFile, key .. "#ref") or ""
end

function FrameReferenceElement:copyAttributes(src)
	FrameReferenceElement:superClass().copyAttributes(self, src)
	self.referencedFrameName = src.referencedFrameName
end
