-- Local values: SavegameUploadProgressDialog_mt
SavegameUploadProgressDialog = {}
local SavegameUploadProgressDialog_mt = Class(SavegameUploadProgressDialog, DialogElement)
function SavegameUploadProgressDialog.register()
	local v2_ = SavegameUploadProgressDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SavegameUploadProgressDialog.xml", "SavegameUploadProgressDialog", v2_)
	SavegameUploadProgressDialog.INSTANCE = v2_
	return v2_
end

-- Local values: dialog
function SavegameUploadProgressDialog.show(progress)
	if SavegameUploadProgressDialog.INSTANCE ~= nil then
		local v4_ = SavegameUploadProgressDialog.INSTANCE
		v4_:setDialogType(DialogElement.TYPE_LOADING)
		v4_:setIsCloseAllowed(false)
		v4_:setProgress(progress or 0)
		g_gui:showDialog("SavegameUploadProgressDialog")
	end
end
function SavegameUploadProgressDialog.hide()
	g_gui:closeDialogByName("SavegameUploadProgressDialog")
end

-- Upvalues: SavegameUploadProgressDialog_mt
-- Local values: self
function SavegameUploadProgressDialog.new(target, custom_mt)
	-- upvalues: (copy) SavegameUploadProgressDialog_mt
	return DialogElement.new(target, custom_mt or SavegameUploadProgressDialog_mt)
end

-- Local values: newGui, dialogType, isCloseAllowed, text, progress
function SavegameUploadProgressDialog.createFromExistingGui(gui, guiName)
	local v9_ = SavegameUploadProgressDialog.new()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_)
	local v10_ = gui.dialogType
	local v11_ = gui.isCloseAllowed
	local v12_ = gui.messageText
	local v13_ = gui.progress
	SavegameUploadProgressDialog.show(v12_, v13_, v10_, v11_)
	return v9_
end

function SavegameUploadProgressDialog:onCreate(element)
	self:setDialogType(DialogElement.TYPE_LOADING)
end

function SavegameUploadProgressDialog:onOpen()
	SavegameUploadProgressDialog:superClass().onOpen(self)
	SavegameUploadProgressDialog.INSTANCE.isOpen = true
	if not self.disableOpenSound and self.dialogType ~= DialogElement.TYPE_LOADING then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.QUERY)
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

function SavegameUploadProgressDialog:onClose()
	SavegameUploadProgressDialog:superClass().onClose(self)
	SavegameUploadProgressDialog.INSTANCE.isOpen = false
end

function SavegameUploadProgressDialog:setText(text)
	if self.dialogTextElement ~= nil then
		self.dialogTextElement:setText(Utils.getNoNil(text, self.defaultText))
	end
end
function SavegameUploadProgressDialog.getIsOpen()
	if SavegameUploadProgressDialog.INSTANCE == nil then
		return false
	else
		return SavegameUploadProgressDialog.INSTANCE.isOpen
	end
end

function SavegameUploadProgressDialog:setProgress(progress)
	self.progress = progress
	self.progressElement:setText(string.format("%d%%", progress))
end
