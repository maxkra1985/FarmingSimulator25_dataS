-- Local values: SafeFrameElement_mt
SafeFrameElement = {}
local SafeFrameElement_mt = Class(SafeFrameElement, GuiElement)
Gui.registerGuiElement("SafeFrame", SafeFrameElement)

-- Upvalues: SafeFrameElement_mt
-- Local values: self
function SafeFrameElement.new(target, custom_mt)
	-- upvalues: (copy) SafeFrameElement_mt
	local v4_ = GuiElement.new(target, custom_mt or SafeFrameElement_mt)
	v4_.name = "safeFrame"
	return v4_
end

function SafeFrameElement:draw()
	drawFilledRect(0, 0, 1, 1, 0, 0, 0, 1)
end
