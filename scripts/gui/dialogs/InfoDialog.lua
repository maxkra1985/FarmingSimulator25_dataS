-- Local values: InfoDialog_mt
InfoDialog = {}
local InfoDialog_mt = Class(InfoDialog, MessageDialog)
function InfoDialog.register()
	local v2_ = InfoDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "InfoDialog", v2_)
	InfoDialog.INSTANCE = v2_
end

-- Local values: dialog
function InfoDialog.show(text, callback, target, dialogType, okText, buttonAction, callbackArgs, disableOpenSound)
	if InfoDialog.INSTANCE ~= nil then
		local v11_ = InfoDialog.INSTANCE
		v11_:setCallback(callback, target, callbackArgs)
		v11_:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_INFO))
		v11_:setButtonTexts(okText)
		v11_:setButtonAction(buttonAction)
		v11_:setText(text)
		v11_:setDisableOpenSound(disableOpenSound)
		g_gui:showDialog("InfoDialog")
	end
end
function InfoDialog.cancel()
	local v12_ = InfoDialog.INSTANCE
	if v12_.isOpen then
		v12_:onClickBack()
	end
end

-- Upvalues: InfoDialog_mt
-- Local values: self
function InfoDialog.new(target, custom_mt)
	-- upvalues: (copy) InfoDialog_mt
	local v15_ = MessageDialog.new(target, custom_mt or InfoDialog_mt)
	v15_.buttonAction = InputAction.MENU_ACCEPT
	v15_.isBackAllowed = false
	v15_.inputDelay = 250
	return v15_
end

-- Local values: dialogType, text, callback, target, okText, buttonAction, callbackArgs
function InfoDialog.createFromExistingGui(gui, guiName)
	InfoDialog.register()
	local v17_ = gui.dialogType
	local v18_ = gui.infoText
	local v19_ = gui.callbackFunc
	local v20_ = gui.target
	local v21_ = gui.okButton.text
	if gui.okButton.textSeparator ~= nil and v21_ ~= nil then
		v21_ = string.gsub(v21_, gui.okButton.textSeparator, "", 1)
	end
	local v22_ = gui.buttonAction
	local v23_ = gui.args
	InfoDialog.show(v18_, v19_, v20_, v17_, v21_, v22_, v23_)
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
	if self.inputDelay > self.time then
		return true
	end
	if inputAction ~= self.buttonAction and not force then
		return true
	end
	self:close()
	if self.onOk ~= nil then
		if self.target == nil then
			self.onOk(self.args)
		else
			self.onOk(self.target, self.args)
		end
		self.onOk = nil
		self.target = nil
		self.args = nil
	end
	return false
end

function InfoDialog:onClickBack(forceBack, usedMenuButton)
	if usedMenuButton then
		return nil
	else
		return self:acceptDialog(InputAction.MENU_BACK, true)
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
	local v47_ = InfoDialog:superClass().inputEvent(self, action, value, eventUsed)
	if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
		self:onClickOk()
		v47_ = true
	end
	return v47_
end
