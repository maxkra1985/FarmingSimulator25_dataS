-- Local values: MessageDialog_mt
MessageDialog = {}
local MessageDialog_mt = Class(MessageDialog, DialogElement)
function MessageDialog.register()
	local v2_ = MessageDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/MessageDialog.xml", "MessageDialog", v2_)
	MessageDialog.INSTANCE = v2_
	return v2_
end

-- Local values: dialog
function MessageDialog.show(text, callback, target, dialogType, isCloseAllowed, callbackArgs)
	if MessageDialog.INSTANCE ~= nil then
		local v9_ = MessageDialog.INSTANCE
		v9_:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_LOADING))
		v9_:setIsCloseAllowed(Utils.getNoNil(isCloseAllowed, true))
		v9_:setText(text)
		v9_:setUpdateCallback(callback, target, callbackArgs)
		g_gui:showDialog("MessageDialog")
	end
end
function MessageDialog.hide()
	g_gui:closeDialogByName("MessageDialog")
end

-- Upvalues: MessageDialog_mt
-- Local values: self
function MessageDialog.new(target, custom_mt)
	-- upvalues: (copy) MessageDialog_mt
	local v12_ = DialogElement.new(target, custom_mt or MessageDialog_mt)
	v12_.defaultDialogHeight = 0
	v12_.isBackAllowed = false
	return v12_
end

-- Local values: newGui, dialogType, isCloseAllowed, text, updateCallback, updateCallbackTarget
function MessageDialog.createFromExistingGui(gui, guiName)
	local v15_ = MessageDialog.new()
	g_gui:loadGui(gui.xmlFilename, guiName, v15_)
	local v16_ = gui.dialogType
	local v17_ = gui.isCloseAllowed
	local v18_ = gui.messageText
	local v19_ = gui.updateCallback
	local v20_ = gui.updateCallbackTarget
	MessageDialog.show(v18_, v19_, v20_, v16_, v17_)
	return v15_
end

-- Local values: defaultTextHeight, _
function MessageDialog:onCreate(element)
	if self.dialogElement ~= nil then
		self.defaultDialogHeight = self.dialogElement.size[2]
	end
	if self.dialogTextElement ~= nil then
		local v22_, _ = self.dialogTextElement:getTextHeight()
		self.defaultDialogHeight = self.defaultDialogHeight - v22_
		self.defaultText = self.dialogTextElement.text
	end
	self:setDialogType(DialogElement.TYPE_WARNING)
end

function MessageDialog:onOpen()
	MessageDialog:superClass().onOpen(self)
	self.isOpen = true
	if not self.disableOpenSound then
		if self.dialogType == DialogElement.TYPE_WARNING then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		elseif self.dialogType ~= DialogElement.TYPE_LOADING then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.QUERY)
		end
	end
	if self.dialogBg ~= nil then
		if g_gui:getIsMenuVisible() then
			self.dialogBg:applyProfile("dialogFullscreenBgWithMenu", true)
		else
			self.dialogBg:applyProfile("dialogFullscreenBgNoMenu", true)
		end
	end
	if self.dialogElement ~= nil then
		if g_gui:getIsMenuVisible() then
			self.dialogElement:applyProfile("dialogElementWithMenu", true)
			return
		end
		self.dialogElement:applyProfile("dialogElementNoMenu", true)
	end
end

function MessageDialog:onClose()
	MessageDialog:superClass().onClose(self)
	self.isOpen = false
end

-- Local values: textHeight, _
function MessageDialog:setText(text)
	if self.dialogTextElement ~= nil then
		self.dialogTextElement:setText(Utils.getNoNil(text, self.defaultText))
		local v27_, _ = self.dialogTextElement:getTextHeight()
		self:resizeDialog(v27_)
	end
end

function MessageDialog:setDisableOpenSound(disableOpenSound)
	if disableOpenSound == nil or not disableOpenSound then
		disableOpenSound = false
	end
	self.disableOpenSound = disableOpenSound
end
function MessageDialog.getIsOpen()
	if MessageDialog.INSTANCE == nil then
		return false
	else
		return MessageDialog.INSTANCE.isOpen
	end
end

function MessageDialog:resizeDialog(heightOffset)
	if self.dialogElement ~= nil then
		self.dialogElement:setSize(nil, self.defaultDialogHeight + heightOffset)
	end
end

function MessageDialog:setUpdateCallback(callback, callbackTarget, args)
	self.updateCallback = callback
	self.updateCallbackTarget = callbackTarget
	self.updateCallbackArgs = args
end

function MessageDialog:update(dt)
	MessageDialog:superClass().update(self, dt)
	if self.updateCallback ~= nil then
		if self.updateCallbackTarget ~= nil then
			self.updateCallback(self.updateCallbackTarget, dt, self.updateCallbackArgs)
			return
		end
		self.updateCallback(dt, self.updateCallbackArgs)
	end
end
