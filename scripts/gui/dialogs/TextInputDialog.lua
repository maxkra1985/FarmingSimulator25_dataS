-- Local values: TextInputDialog_mt, NO_CALLBACK
TextInputDialog = {}
local TextInputDialog_mt = Class(TextInputDialog, YesNoDialog)
local function NO_CALLBACK() end
function TextInputDialog.register()
	local v3_ = TextInputDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/TextInputDialog.xml", "TextInputDialog", v3_)
	TextInputDialog.INSTANCE = v3_
end

-- Local values: dialog
function TextInputDialog.show(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, confirmText, callbackArgs, text, applyTextFilter)
	if TextInputDialog.INSTANCE ~= nil then
		local v14_ = TextInputDialog.INSTANCE
		v14_:setText(text)
		v14_:setCallback(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, callbackArgs, applyTextFilter)
		v14_:setButtonTexts(confirmText)
		g_gui:showDialog("TextInputDialog")
	end
end

-- Upvalues: TextInputDialog_mt, NO_CALLBACK
-- Local values: self
function TextInputDialog.new(target, custom_mt)
	-- upvalues: (copy) TextInputDialog_mt, (copy) NO_CALLBACK
	local v17_ = YesNoDialog.new(target, custom_mt or TextInputDialog_mt)
	v17_.onTextEntered = NO_CALLBACK
	v17_.callbackArgs = nil
	v17_.extraInputDisableTime = 0
	local v18_ = GS_IS_CONSOLE_VERSION
	if v18_ then
		v18_ = imeIsSupported()
	end
	v17_.doHide = v18_
	v17_.disableOpenSound = true
	return v17_
end

-- Local values: callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, confirmText, callbackArgs, text, applyTextFilter
function TextInputDialog.createFromExistingGui(gui, guiName)
	TextInputDialog.register()
	local v20_ = gui.onTextEntered
	local v21_ = gui.target
	local v22_ = gui.defaultText
	local v23_ = gui.dialogPrompt
	local v24_ = gui.imePrompt
	local v25_ = gui.maxCharacters
	local v26_ = gui.confirmText
	local v27_ = gui.callbackArgs
	local v28_ = gui.inputText
	local v29_ = gui.applyTextFilter
	TextInputDialog.show(v20_, v21_, v22_, v23_, v24_, v25_, v26_, v27_, v28_, v29_)
end

function TextInputDialog:onOpen()
	TextInputDialog:superClass().onOpen(self)
	self.extraInputDisableTime = getPlatformId() == PlatformId.SWITCH and 0 or 100
	FocusManager:setFocus(self.textElement)
	self.textElement.blockTime = 0
	self.textElement:onFocusActivate()
	self:updateButtonVisibility()
end

function TextInputDialog:onClose()
	TextInputDialog:superClass().onClose(self)
	if not GS_IS_CONSOLE_VERSION then
		self.textElement:setForcePressed(false)
	end
	self:updateButtonVisibility()
end

function TextInputDialog:setText(text)
	TextInputDialog:superClass().setText(self, text)
	self.inputText = text
end

function TextInputDialog:setButtonTexts(yesText, noText)
	TextInputDialog:superClass().setButtonTexts(self, yesText, noText)
	self.confirmText = yesText
end

-- Upvalues: NO_CALLBACK
function TextInputDialog:setCallback(onTextEntered, target, defaultInputText, dialogPrompt, imePrompt, maxCharacters, callbackArgs, applyTextFilter)
	-- upvalues: (copy) NO_CALLBACK
	self.onTextEntered = onTextEntered or NO_CALLBACK
	self.target = target
	self.callbackArgs = callbackArgs
	self.textElement:setText(defaultInputText or "")
	self.textElement.maxCharacters = maxCharacters or self.textElement.maxCharacters
	self.applyTextFilter = Utils.getNoNil(applyTextFilter, true)
	if dialogPrompt ~= nil then
		self.dialogTextElement:setText(dialogPrompt)
	end
	if imePrompt ~= nil then
		self.textElement.applyProfanityFilter = self.applyTextFilter
		self.textElement.imeTitle = imePrompt
		self.textElement.imeDescription = ""
		self.textElement.imePlaceholder = ""
	end
	self.dialogPrompt = dialogPrompt
	self.imePrompt = imePrompt
	self.maxCharacters = maxCharacters
end

-- Local values: text
function TextInputDialog:sendCallback(clickOk)
	local v48_ = self.textElement.text
	self:close()
	if self.target == nil then
		self.onTextEntered(v48_, clickOk, self.callbackArgs)
	else
		self.onTextEntered(self.target, v48_, clickOk, self.callbackArgs)
	end
end

function TextInputDialog:onEnterPressed(element, dismissal)
	return dismissal and true or self:onClickOk()
end

function TextInputDialog:onEscPressed(element)
	return self:onClickBack()
end

function TextInputDialog:onClickBack(forceBack, usedMenuButton)
	if self:isInputDisabled() then
		return true
	end
	self:sendCallback(false)
	return false
end

-- Local values: baseText, filteredText
function TextInputDialog:onClickOk()
	if self:isInputDisabled() then
		return true
	end
	if self.applyTextFilter and not self.textElement.isPassword then
		local v54_ = self.textElement.text
		local v55_ = filterText(v54_, true, true)
		if v54_ ~= "" and v54_ ~= v55_ then
			self.textElement:setText(v55_)
			Logging.info("Entered text contains profanity and has been adjusted.")
			self.reactivateNextFrame = true
			self:updateButtonVisibility()
			return false
		end
	end
	self:sendCallback(true)
	self:updateButtonVisibility()
	return false
end

function TextInputDialog:updateButtonVisibility()
	if self.yesButton ~= nil then
		self.yesButton:setVisible(not self.textElement.imeActive)
	end
	if self.noButton ~= nil then
		self.noButton:setVisible(not self.textElement.imeActive)
	end
end

function TextInputDialog:update(dt)
	TextInputDialog:superClass().update(self, dt)
	if self.reactivateNextFrame then
		self.textElement.blockTime = 0
		self.textElement:onFocusActivate()
		self.reactivateNextFrame = false
		self:updateButtonVisibility()
	end
	if self.extraInputDisableTime > 0 then
		self.extraInputDisableTime = self.extraInputDisableTime - dt
	end
end

function TextInputDialog:isInputDisabled()
	local v60_
	if self.extraInputDisableTime > 0 then
		v60_ = not self.doHide
	else
		v60_ = false
	end
	return v60_
end

function TextInputDialog:disableInputForDuration(duration) end

function TextInputDialog:getIsVisible()
	if self.doHide then
		return false
	else
		return TextInputDialog:superClass().getIsVisible(self)
	end
end
