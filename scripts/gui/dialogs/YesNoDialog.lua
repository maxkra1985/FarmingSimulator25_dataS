-- Local values: YesNoDialog_mt
YesNoDialog = {}
local YesNoDialog_mt = Class(YesNoDialog, MessageDialog)
function YesNoDialog.register()
	local v2_ = YesNoDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/YesNoDialog.xml", "YesNoDialog", v2_)
	YesNoDialog.INSTANCE = v2_
end

-- Local values: dialog
function YesNoDialog.show(callback, target, text, title, yesText, noText, dialogType, yesSound, noSound, callbackArgs, disableOpenSound)
	if YesNoDialog.INSTANCE == nil then
		return nil
	end
	local v14_ = YesNoDialog.INSTANCE
	v14_:setCallback(callback, target, callbackArgs)
	v14_:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_QUESTION))
	v14_:setButtonTexts(yesText, noText)
	v14_:setButtonSounds(yesSound, noSound)
	v14_:setTitle(title)
	v14_:setText(text)
	v14_:setDisableOpenSound(disableOpenSound)
	g_gui:showDialog("YesNoDialog")
	return v14_
end

-- Upvalues: YesNoDialog_mt
-- Local values: self
function YesNoDialog.new(target, custom_mt)
	-- upvalues: (copy) YesNoDialog_mt
	local v17_ = MessageDialog.new(target, custom_mt or YesNoDialog_mt)
	v17_.isBackAllowed = false
	v17_.inputDelay = 250
	return v17_
end
function YesNoDialog.cancel()
	local v18_ = YesNoDialog.INSTANCE
	if v18_.isOpen then
		v18_:onNo()
	end
end

-- Local values: title, text, dialogType, callback, target, yesText, noText, yesSound, noSound, callbackArgs
function YesNoDialog.createFromExistingGui(gui, guiName)
	YesNoDialog.register()
	local v20_ = gui.yesNoTitle
	local v21_ = gui.yesNoText
	local v22_ = gui.dialogType
	local v23_ = gui.callbackFunc
	local v24_ = gui.target
	local v25_ = gui.yesButton.yesText
	if gui.yesButton.textSeparator ~= nil and v25_ ~= nil then
		v25_ = string.gsub(v25_, gui.yesButton.textSeparator, "", 1)
	end
	local v26_ = gui.noButton.noText
	if gui.noButton.textSeparator ~= nil and v26_ ~= nil then
		v26_ = string.gsub(v26_, gui.noButton.textSeparator, "", 1)
	end
	local v27_ = gui.yesButton.clickSoundName
	local v28_ = gui.noButton.clickSoundName
	local v29_ = gui.callbackArgs
	YesNoDialog.show(v23_, v24_, v21_, v20_, v25_, v26_, v22_, v27_, v28_, v29_)
end

function YesNoDialog:onCreate()
	YesNoDialog:superClass().onCreate(self)
	if self.dialogTextElement ~= nil then
		self.defaultTextStartPosY = self.dialogTextElement.position[2]
	end
	self:setDialogType(DialogElement.TYPE_QUESTION)
	if self.dialogTitleElement ~= nil then
		self.defaultTitle = self.dialogTitleElement.text
	end
	self.defaultYesText = self.yesButton.text
	if self.yesButton.textSeparator ~= nil then
		self.defaultYesText = string.gsub(self.defaultYesText, self.yesButton.textSeparator, "", 1)
	end
	self.defaultNoText = self.noButton.text
	if self.noButton.textSeparator ~= nil then
		self.defaultNoText = string.gsub(self.defaultNoText, self.noButton.textSeparator, "", 1)
	end
end

function YesNoDialog:onOpen()
	YesNoDialog:superClass().onOpen(self)
	self.inputDelay = self.time + 250
end

function YesNoDialog:onClose()
	self:setDialogType(DialogElement.TYPE_QUESTION)
	self:setTitle(nil)
	self:setText(nil)
	self:setButtonTexts(self.defaultYesText, self.defaultNoText)
	YesNoDialog:superClass().onClose(self)
end

function YesNoDialog:sendCallback(value)
	if self.inputDelay >= self.time then
		return true
	end
	self:close()
	if self.callbackFunc ~= nil then
		if self.target == nil then
			self.callbackFunc(value, self.callbackArgs)
		else
			self.callbackFunc(self.target, value, self.callbackArgs)
		end
	end
	return false
end

function YesNoDialog:setCallback(callbackFunc, target, callbackArgs)
	self.callbackFunc = callbackFunc
	self.target = target
	self.callbackArgs = callbackArgs
end

-- Local values: textHeight, _
function YesNoDialog:setTitle(text)
	if self.dialogTitleElement ~= nil then
		self.dialogTitleElement:setText(Utils.getNoNil(text, self.defaultTitle))
	end
	if GS_IS_MOBILE_VERSION and self.dialogTextElement ~= nil then
		local v41_, _ = self.dialogTextElement:getTextHeight()
		self:resizeDialog(v41_)
	end
end

-- Local values: titleOffset, element
function YesNoDialog:resizeDialog(heightOffset)
	local v44_ = 0
	if GS_IS_MOBILE_VERSION then
		if self.dialogTitleElement ~= nil and self.dialogTitleElement.text ~= "" then
			local v45_ = self.dialogTitleElement
			v44_ = v45_.size[2] + v45_.margin[2] + v45_.margin[4]
		end
		if self.defaultTextStartPosY ~= nil then
			self.dialogTextElement:setPosition(nil, self.defaultTextStartPosY - v44_)
		end
	end
	YesNoDialog:superClass().resizeDialog(self, heightOffset + v44_)
end

function YesNoDialog:setButtonTexts(yesText, noText)
	self.yesButton:setText(Utils.getNoNil(yesText, self.defaultYesText))
	self.noButton:setText(Utils.getNoNil(noText, self.defaultNoText))
end

function YesNoDialog:setButtonSounds(yesSound, noSound)
	self.yesButton.clickSoundName = Utils.getNoNil(yesSound, self.yesButton.clickSoundName)
	self.noButton.clickSoundName = Utils.getNoNil(noSound, self.noButton.clickSoundName)
end

function YesNoDialog:onYes(sender)
	return self:sendCallback(true)
end

function YesNoDialog:onNo(sender)
	return self:sendCallback(false)
end

function YesNoDialog:inputEvent(action, value, eventUsed)
	local v58_ = YesNoDialog:superClass().inputEvent(self, action, value, eventUsed)
	if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
		self:onNo()
		v58_ = true
	end
	return v58_
end
