-- Local values: OptionDialog_mt
OptionDialog = {}
local OptionDialog_mt = Class(OptionDialog, YesNoDialog)
function OptionDialog.register()
	local v2_ = OptionDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/OptionDialog.xml", "OptionDialog", v2_)
	OptionDialog.INSTANCE = v2_
end

-- Local values: dialog
function OptionDialog.show(callback, text, title, options, defaultOptionIndex)
	if OptionDialog.INSTANCE ~= nil then
		local v8_ = OptionDialog.INSTANCE
		v8_:setCallback(callback)
		v8_:setText(text)
		v8_:setTitle(title)
		v8_:setOptions(options, defaultOptionIndex)
		g_gui:showDialog("OptionDialog")
	end
end

-- Upvalues: OptionDialog_mt
-- Local values: self
function OptionDialog.new(target, custom_mt)
	-- upvalues: (copy) OptionDialog_mt
	return YesNoDialog.new(target, custom_mt or OptionDialog_mt)
end

-- Local values: callback, text, title, options
function OptionDialog.createFromExistingGui(gui, guiName)
	OptionDialog.register()
	local v12_ = gui.callbackFunc
	local v13_ = gui.optionText
	local v14_ = gui.optionTitle
	local v15_ = gui.options
	OptionDialog.show(v12_, v13_, v14_, v15_)
end

function OptionDialog:onClickOk()
	if self.areButtonsDisabled then
		return true
	end
	self:sendCallback(self.optionElement:getState())
	return false
end

function OptionDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(0)
	return false
end

function OptionDialog:setOptions(options, defaultOptionIndex)
	self.options = options
	self.optionElement:setTexts(options)
	self.optionElement:setState(defaultOptionIndex or 1)
end

function OptionDialog:setText(text)
	OptionDialog:superClass().setText(self, text)
	self.optionText = text
end

function OptionDialog:setTitle(title)
	OptionDialog:superClass().setTitle(self, title)
	self.optionTitle = title
end
