InGameMenuHintFrame = {}
local InGameMenuHintFrame_mt = Class(InGameMenuHintFrame, TabbedMenuFrameElement)
function InGameMenuHintFrame.register()
	local inGameMenuHintFrame = InGameMenuHintFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuHintFrame.xml", "HintFrame", inGameMenuHintFrame, true)
end
function InGameMenuHintFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuHintFrame_mt)
	self.hasCustomMenuButtons = true
	return self
end
function InGameMenuHintFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuHintFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
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
	local _v7 = self
	InGameMenuHintFrame:superClass().onFrameOpen(_v7)
	self:updateContents()
	self.layout:registerActionEvents()
	_v7.inputAction = InputAction.MENU_BACK
	self.menuButtonInfo = { {} }
end
function InGameMenuHintFrame:onFrameClose()
	self.layout:removeActionEvents()
	InGameMenuHintFrame:superClass().onFrameClose(self)
end
function InGameMenuHintFrame:updateContents()
	self.headerText:setLocaKey("ui_hint")
	for i = #self.layout.elements, 1, -1 do
		self.layout.elements[i]:delete()
	end
	self.layout:invalidateLayout()
	local hints = g_currentMission.introductionHelpSystem:getShownHints()
	local _, offsetYBottomTop = getNormalizedScreenValues(0, 60)
	for index, hintText in ipairs(hints) do
		local row = self.contentItem:clone(self.layout)
		local textElement = row:getDescendantByName("text")
		local profile = "hintMenuItem"
		if index == #hints then
			profile = "hintMenuItemCurrent"
		elseif index % 2 == 1 then
			profile = "hintMenuItemAlt"
		end
		row:applyProfile(profile)
		textElement:setText(hintText)
		local height = textElement:getTextHeight()
		textElement:setSize(nil, height)
		height = height + offsetYBottomTop
		row:setSize(nil, height)
	end
	self.layout:invalidateLayout()
	self.layout:scrollToEnd()
end
