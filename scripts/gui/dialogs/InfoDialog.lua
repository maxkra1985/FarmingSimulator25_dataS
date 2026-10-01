InfoDialog = {}
local InfoDialog_mt = Class(InfoDialog, MessageDialog)
function InfoDialog.register()
	local infoDialog = InfoDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "InfoDialog", infoDialog)
	InfoDialog.INSTANCE = infoDialog
end
function InfoDialog.show(text, callback, target, dialogType, okText, buttonAction, callbackArgs, disableOpenSound)
	if InfoDialog.INSTANCE ~= nil then
		local dialog = InfoDialog.INSTANCE
		dialog:setCallback(callback, target, callbackArgs)
		dialog:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_INFO))
		dialog:setButtonTexts(okText)
		dialog:setButtonAction(buttonAction)
		dialog:setText(text)
		dialog:setDisableOpenSound(disableOpenSound)
		g_gui:showDialog("InfoDialog")
	end
end
function InfoDialog.cancel()
	local dialog = InfoDialog.INSTANCE
	if dialog.isOpen then
		dialog:onClickBack()
	end
end
function InfoDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or InfoDialog_mt)
	self.buttonAction = InputAction.MENU_ACCEPT
	self.isBackAllowed = false
	self.inputDelay = 250
	return self
end
function InfoDialog.createFromExistingGui(gui, guiName)
	InfoDialog.register()
	local dialogType = gui.dialogType
	local text = gui.infoText
	local callback = gui.callbackFunc
	local target = gui.target
	local okText = gui.okButton.text
	if gui.okButton.textSeparator ~= nil and okText ~= nil then
		okText = string.gsub(okText, gui.okButton.textSeparator, "", 1)
	end
	local buttonAction = gui.buttonAction
	local callbackArgs = gui.args
	InfoDialog.show(text, callback, target, dialogType, okText, buttonAction, callbackArgs)
end
function InfoDialog:onCreate()
	InfoDialog:superClass().onCreate(self)
	self:setDialogType(DialogElement.TYPE_INFO)
	self.defaultOkText = self.okButton.text
	if self.okButton.textSeparator ~= nil then
		self.defaultOkText = string.gsub(self.defaultOkText, self.okButton.textSeparator, "", 1)
	end
end
function InfoDialog:onOpen()
	InfoDialog:superClass().onOpen(self)
	self.inputDelay = self.time + 250
end
function InfoDialog:onClose()
	InfoDialog:superClass().onClose(self)
	self:setButtonTexts(self.defaultOkText)
	self.buttonAction = InputAction.MENU_ACCEPT
	self:setButtonAction(InputAction.MENU_ACCEPT)
	self:setText("")
end
function InfoDialog:setText(text)
	InfoDialog:superClass().setText(self, text)
	self.infoText = text
end
function InfoDialog:acceptDialog(inputAction, force)
	if self.time < self.inputDelay then
		return true
	elseif inputAction == self.buttonAction or force then
		self:close()
		if self.onOk ~= nil then
			if self.target ~= nil then
				self.onOk(self.target, self.args)
			else
				self.onOk(self.args)
			end
			self.onOk = nil
			self.target = nil
			self.args = nil
		end
		return false
	else
		return true
	end
end
function InfoDialog:onClickBack(forceBack, usedMenuButton)
	if not usedMenuButton then
		return self:acceptDialog(InputAction.MENU_BACK, true)
	else
		return nil
	end
end
function InfoDialog:onClickOk()
	return self:acceptDialog(self.buttonAction, false)
end
function InfoDialog:setCallback(onOk, target, args)
	self.onOk = onOk
	self.target = target
	self.args = args
end
function InfoDialog:setButtonTexts(okText)
	if self.okButton ~= nil then
		self.okButton:setText(Utils.getNoNil(okText, self.defaultOkText))
	end
end
function InfoDialog:setButtonAction(buttonAction)
	if buttonAction ~= nil then
		self.buttonAction = buttonAction
		self.okButton:setInputAction(buttonAction)
	end
end
function InfoDialog:inputEvent(action, value, eventUsed)
	eventUsed = InfoDialog:superClass().inputEvent(self, action, value, eventUsed)
	if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
		self:onClickOk()
		eventUsed = true
	end
	return eventUsed
end
