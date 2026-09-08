-- Local values: InGameMenuHintFrame_mt
InGameMenuHintFrame = {}
local InGameMenuHintFrame_mt = Class(InGameMenuHintFrame, TabbedMenuFrameElement)
function InGameMenuHintFrame.register()
	local v2_ = InGameMenuHintFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuHintFrame.xml", "HintFrame", v2_, true)
end

-- Upvalues: InGameMenuHintFrame_mt
-- Local values: self
function InGameMenuHintFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuHintFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuHintFrame_mt)
	v5_.hasCustomMenuButtons = true
	return v5_
end

-- Local values: newGui
function InGameMenuHintFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuHintFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function InGameMenuHintFrame:delete()
	self.contentItem:delete()
	self.controlItem:delete()
	InGameMenuHintFrame:superClass().delete(self)
end

function InGameMenuHintFrame:initialize()
	self.contentItem:unlinkElement()
	self.controlItem:unlinkElement()
end

function InGameMenuHintFrame:onFrameOpen()
	InGameMenuHintFrame:superClass().onFrameOpen(self)
	self:updateContents()
	self.layout:registerActionEvents()
	self.menuButtonInfo = {
		{
			["inputAction"] = InputAction.MENU_BACK
		}
	}
end

function InGameMenuHintFrame:onFrameClose()
	self.layout:removeActionEvents()
	InGameMenuHintFrame:superClass().onFrameClose(self)
end

-- Local values: i, hints, _, offsetYBottomTop, index, hintText, row, textElement, profile, height
function InGameMenuHintFrame:updateContents()
	self.headerText:setLocaKey("ui_hint")
	for v14_ = #self.layout.elements, 1, -1 do
		self.layout.elements[v14_]:delete()
	end
	self.layout:invalidateLayout()
	local v15_ = g_currentMission.introductionHelpSystem:getShownHints()
	local _, v16_ = getNormalizedScreenValues(0, 60)
	for v17_, v18_ in ipairs(v15_) do
		local v19_ = self.contentItem:clone(self.layout)
		local v20_ = v19_:getDescendantByName("text")
		v19_:applyProfile(v17_ == #v15_ and "hintMenuItemCurrent" or (v17_ % 2 == 1 and "hintMenuItemAlt" or "hintMenuItem"))
		v20_:setText(v18_)
		local v21_ = v20_:getTextHeight()
		v20_:setSize(nil, v21_)
		v19_:setSize(nil, v21_ + v16_)
	end
	self.layout:invalidateLayout()
	self.layout:scrollToEnd()
end
