MultiOptionDialog = {}
MultiOptionDialog.ACTION = { BACK = 1, ACCEPT = 2, CANCEL = 3, ACTIVATE = 4 }
local MultiOptionDialog_mt = Class(MultiOptionDialog, MessageDialog)
function MultiOptionDialog.register()
	local multiOptionDialog = MultiOptionDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/MultiOptionDialog.xml", "MultiOptionDialog", multiOptionDialog)
	MultiOptionDialog.INSTANCE = multiOptionDialog
end
function MultiOptionDialog.show(callback, target, text, title, acceptText, backText, activateText, cancelText, dialogType, callbackArgs, disableOpenSound)
	if MultiOptionDialog.INSTANCE ~= nil then
		local dialog = MultiOptionDialog.INSTANCE
		dialog:setCallback(callback, target, callbackArgs)
		dialog:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_QUESTION))
		dialog:setButtonTexts(backText, acceptText, cancelText, activateText)
		dialog:setTitle(title)
		dialog:setText(text)
		dialog:setDisableOpenSound(disableOpenSound)
		g_gui:showDialog("MultiOptionDialog")
		return dialog
	else
		return nil
	end
end
function MultiOptionDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or MultiOptionDialog_mt)
	self.isBackAllowed = false
	self.inputDelay = 250
	return self
end
function MultiOptionDialog.createFromExistingGui(gui, guiName)
	MultiOptionDialog.register()
	local title = gui.dialogTitleElement:getText()
	local text = gui.dialogTextElement:getText()
	local dialogType = gui.dialogType
	local callback = gui.callbackFunc
	local target = gui.target
	local callbackArgs = gui.callbackArgs
	local backText = gui.buttonBack ~= nil and gui.buttonBack:getText() or nil
	local acceptText = gui.buttonAccept ~= nil and gui.buttonAccept:getText() or nil
	local cancelText = gui.buttonCancel ~= nil and gui.buttonCancel:getText() or nil
	local activateText = gui.buttonActivate ~= nil and gui.buttonActivate:getText() or nil
	MultiOptionDialog.show(callback, target, text, title, backText, acceptText, cancelText, activateText, dialogType, callbackArgs)
end
function MultiOptionDialog:onCreate()
	MultiOptionDialog:superClass().onCreate(self)
	if self.dialogTextElement ~= nil then
		self.defaultTextStartPosY = self.dialogTextElement.position[2]
	end
	self:setDialogType(DialogElement.TYPE_QUESTION)
	if self.dialogTitleElement ~= nil then
		self.defaultTitle = self.dialogTitleElement.text
	end
	function self.buttonBox.invalidateLayout(buttonBox, ignoreVisibility, blockLayoutUpdate)
		BoxLayoutElement.invalidateLayout(buttonBox, ignoreVisibility, blockLayoutUpdate)
		local minWidth = math.max(self.dialogElement.absSize[1], self.buttonBox.maxFlowSize + 44 * g_pixelSizeScaledX)
		self.dialogElement:setSize(minWidth, nil)
	end
end
function MultiOptionDialog:onOpen()
	MultiOptionDialog:superClass().onOpen(self)
	self.inputDelay = self.time + 250
end
function MultiOptionDialog:onClose()
	self:setDialogType(DialogElement.TYPE_QUESTION)
	self:setTitle(nil)
	self:setText(nil)
	MultiOptionDialog:superClass().onClose(self)
end
function MultiOptionDialog:sendCallback(value)
	if self.inputDelay < self.time then
		self:close()
		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, value, self.callbackArgs)
			else
				self.callbackFunc(value, self.callbackArgs)
			end
		end
		return false
	else
		return true
	end
end
function MultiOptionDialog:setCallback(callbackFunc, target, callbackArgs)
	self.callbackFunc = callbackFunc
	self.target = target
	self.callbackArgs = callbackArgs
end
function MultiOptionDialog:setTitle(text)
	if self.dialogTitleElement ~= nil then
		self.dialogTitleElement:setText(Utils.getNoNil(text, self.defaultTitle))
	end
	if Platform.isMobile and self.dialogTextElement ~= nil then
		local textHeight, _ = self.dialogTextElement:getTextHeight()
		self:resizeDialog(textHeight)
	end
end
function MultiOptionDialog:resizeDialog(heightOffset)
	local titleOffset = 0
	if Platform.isMobile then
		if self.dialogTitleElement ~= nil and self.dialogTitleElement.text ~= "" then
			local element = self.dialogTitleElement
			titleOffset = element.size[2] + element.margin[2] + element.margin[4]
		end
		if self.defaultTextStartPosY ~= nil then
			self.dialogTextElement:setPosition(nil, self.defaultTextStartPosY - titleOffset)
		end
	end
	MultiOptionDialog:superClass().resizeDialog(self, heightOffset + titleOffset)
end
function MultiOptionDialog:setButtonTexts(backText, acceptText, cancelText, activateText)
	local firstVisibleButton = nil
	self.buttonCancel:setVisible(cancelText ~= nil)
	if cancelText ~= nil then
		self.buttonCancel:setText(cancelText)
		firstVisibleButton = self.buttonCancel
		local _v8 = self.buttonActivate:getDescendantByName("separator")
		_v8:setVisible(_v26)
		local _v9 = self.buttonActivate
		local _v26 = true
		_v8:setVisible(_v26)
	end
	self.buttonActivate:setVisible(activateText ~= nil)
	if activateText ~= nil then
		self.buttonActivate:setText(activateText)
		firstVisibleButton = self.buttonActivate
		local _v12 = self.buttonActivate:getDescendantByName("separator")
		_v12:setVisible(_v31)
		local _v13 = self.buttonBack
		local _v31 = true
		_v12:setVisible(_v31)
	end
	self.buttonBack:setVisible(backText ~= nil)
	if backText ~= nil then
		self.buttonBack:setText(backText)
		firstVisibleButton = self.buttonBack
		local _v16 = self.buttonBack:getDescendantByName("separator")
		_v16:setVisible(_v36)
		local _v17 = self.buttonAccept
		local _v36 = true
		_v16:setVisible(_v36)
	end
	self.buttonAccept:setVisible(acceptText ~= nil)
	if acceptText ~= nil then
		self.buttonAccept:setText(acceptText)
		firstVisibleButton = self.buttonAccept
	end
	if firstVisibleButton ~= nil then
		firstVisibleButton:getDescendantByName("separator"):setVisible(false)
	end
end
function MultiOptionDialog:onBack(sender)
	return self:sendCallback(MultiOptionDialog.ACTION.BACK)
end
function MultiOptionDialog:onAccept(sender)
	return self:sendCallback(MultiOptionDialog.ACTION.ACCEPT)
end
function MultiOptionDialog:onCancel(sender)
	return self:sendCallback(MultiOptionDialog.ACTION.CANCEL)
end
function MultiOptionDialog:onActivate()
	return self:sendCallback(MultiOptionDialog.ACTION.ACTIVATE)
end
function MultiOptionDialog:inputEvent(action, value, eventUsed)
	eventUsed = MultiOptionDialog:superClass().inputEvent(self, action, value, eventUsed)
	if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
		self:onNo()
		eventUsed = true
	end
	return eventUsed
end
