-- Local values: MultiOptionDialog_mt
MultiOptionDialog = {}
MultiOptionDialog.ACTION = {
	["BACK"] = 1,
	["ACCEPT"] = 2,
	["CANCEL"] = 3,
	["ACTIVATE"] = 4
}
local MultiOptionDialog_mt = Class(MultiOptionDialog, MessageDialog)
function MultiOptionDialog.register()
	local v2_ = MultiOptionDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/MultiOptionDialog.xml", "MultiOptionDialog", v2_)
	MultiOptionDialog.INSTANCE = v2_
end

-- Local values: dialog
function MultiOptionDialog.show(callback, target, text, title, acceptText, backText, activateText, cancelText, dialogType, callbackArgs, disableOpenSound)
	if MultiOptionDialog.INSTANCE == nil then
		return nil
	end
	local v14_ = MultiOptionDialog.INSTANCE
	v14_:setCallback(callback, target, callbackArgs)
	v14_:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_QUESTION))
	v14_:setButtonTexts(backText, acceptText, cancelText, activateText)
	v14_:setTitle(title)
	v14_:setText(text)
	v14_:setDisableOpenSound(disableOpenSound)
	g_gui:showDialog("MultiOptionDialog")
	return v14_
end

-- Upvalues: MultiOptionDialog_mt
-- Local values: self
function MultiOptionDialog.new(target, custom_mt)
	-- upvalues: (copy) MultiOptionDialog_mt
	local v17_ = MessageDialog.new(target, custom_mt or MultiOptionDialog_mt)
	v17_.isBackAllowed = false
	v17_.inputDelay = 250
	return v17_
end

-- Local values: title, text, dialogType, callback, target, callbackArgs, backText, acceptText, cancelText, activateText
function MultiOptionDialog.createFromExistingGui(gui, guiName)
	MultiOptionDialog.register()
	local v19_ = gui.dialogTitleElement:getText()
	local v20_ = gui.dialogTextElement:getText()
	local v21_ = gui.dialogType
	local v22_ = gui.callbackFunc
	local v23_ = gui.target
	local v24_ = gui.callbackArgs
	local v25_
	if gui.buttonBack == nil then
		v25_ = nil
	else
		v25_ = gui.buttonBack:getText() or nil
	end
	local v26_
	if gui.buttonAccept == nil then
		v26_ = nil
	else
		v26_ = gui.buttonAccept:getText() or nil
	end
	local v27_
	if gui.buttonCancel == nil then
		v27_ = nil
	else
		v27_ = gui.buttonCancel:getText() or nil
	end
	local v28_
	if gui.buttonActivate == nil then
		v28_ = nil
	else
		v28_ = gui.buttonActivate:getText() or nil
	end
	MultiOptionDialog.show(v22_, v23_, v20_, v19_, v25_, v26_, v27_, v28_, v21_, v24_)
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
	function self.buttonBox.invalidateLayout(p30_, p31_, p32_)
		-- upvalues: (copy) self
		BoxLayoutElement.invalidateLayout(p30_, p31_, p32_)
		local v33_ = self.dialogElement.absSize[1]
		local v34_ = self.buttonBox.maxFlowSize + 44 * g_pixelSizeScaledX
		local v35_ = math.max(v33_, v34_)
		self.dialogElement:setSize(v35_, nil)
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

function MultiOptionDialog:setCallback(callbackFunc, target, callbackArgs)
	self.callbackFunc = callbackFunc
	self.target = target
	self.callbackArgs = callbackArgs
end

-- Local values: textHeight, _
function MultiOptionDialog:setTitle(text)
	if self.dialogTitleElement ~= nil then
		self.dialogTitleElement:setText(Utils.getNoNil(text, self.defaultTitle))
	end
	if Platform.isMobile and self.dialogTextElement ~= nil then
		local v46_, _ = self.dialogTextElement:getTextHeight()
		self:resizeDialog(v46_)
	end
end

-- Local values: titleOffset, element
function MultiOptionDialog:resizeDialog(heightOffset)
	local v49_ = 0
	if Platform.isMobile then
		if self.dialogTitleElement ~= nil and self.dialogTitleElement.text ~= "" then
			local v50_ = self.dialogTitleElement
			v49_ = v50_.size[2] + v50_.margin[2] + v50_.margin[4]
		end
		if self.defaultTextStartPosY ~= nil then
			self.dialogTextElement:setPosition(nil, self.defaultTextStartPosY - v49_)
		end
	end
	MultiOptionDialog:superClass().resizeDialog(self, heightOffset + v49_)
end

-- Local values: firstVisibleButton
function MultiOptionDialog:setButtonTexts(backText, acceptText, cancelText, activateText)
	self.buttonCancel:setVisible(cancelText ~= nil)
	local v56_
	if cancelText == nil then
		v56_ = nil
	else
		self.buttonCancel:setText(cancelText)
		v56_ = self.buttonCancel
		self.buttonActivate:getDescendantByName("separator"):setVisible(true)
	end
	self.buttonActivate:setVisible(activateText ~= nil)
	if activateText ~= nil then
		self.buttonActivate:setText(activateText)
		v56_ = self.buttonActivate
		self.buttonActivate:getDescendantByName("separator"):setVisible(true)
	end
	self.buttonBack:setVisible(backText ~= nil)
	if backText ~= nil then
		self.buttonBack:setText(backText)
		v56_ = self.buttonBack
		self.buttonBack:getDescendantByName("separator"):setVisible(true)
	end
	self.buttonAccept:setVisible(acceptText ~= nil)
	if acceptText ~= nil then
		self.buttonAccept:setText(acceptText)
		v56_ = self.buttonAccept
	end
	if v56_ ~= nil then
		v56_:getDescendantByName("separator"):setVisible(false)
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
	local v65_ = MultiOptionDialog:superClass().inputEvent(self, action, value, eventUsed)
	if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
		self:onNo()
		v65_ = true
	end
	return v65_
end
