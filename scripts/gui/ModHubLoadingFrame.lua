-- Local values: ModHubLoadingFrame_mt
ModHubLoadingFrame = {}
local ModHubLoadingFrame_mt = Class(ModHubLoadingFrame, TabbedMenuFrameElement)
function ModHubLoadingFrame.register()
	local v2_ = ModHubLoadingFrame.new()
	g_gui:loadGui("dataS/gui/ModHubLoadingFrame.xml", "ModHubLoadingFrame", v2_, true)
end

-- Upvalues: ModHubLoadingFrame_mt
-- Local values: self
function ModHubLoadingFrame.new(target, custom_mt)
	-- upvalues: (copy) ModHubLoadingFrame_mt
	return ModHubLoadingFrame:superClass().new(target, custom_mt or ModHubLoadingFrame_mt)
end

function ModHubLoadingFrame:onFrameOpen()
	ModHubLoadingFrame:superClass().onFrameOpen(self)
	g_modHubScreen.header:setVisible(false)
end

function ModHubLoadingFrame:onFrameClose()
	g_modHubScreen.header:setVisible(true)
	ModHubLoadingFrame:superClass().onFrameClose(self)
end
