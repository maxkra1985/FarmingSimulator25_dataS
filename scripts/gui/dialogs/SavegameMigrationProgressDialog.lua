SavegameMigrationProgressDialog = {}
local SavegameMigrationProgressDialog_mt = Class(SavegameMigrationProgressDialog, DialogElement)
function SavegameMigrationProgressDialog.register()
	local savegameMigrationProgressDialog = SavegameMigrationProgressDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SavegameMigrationProgressDialog.xml", "SavegameMigrationProgressDialog", savegameMigrationProgressDialog)
	SavegameMigrationProgressDialog.INSTANCE = savegameMigrationProgressDialog
	return savegameMigrationProgressDialog
end
function SavegameMigrationProgressDialog.show(progress)
	if SavegameMigrationProgressDialog.INSTANCE ~= nil then
		local dialog = SavegameMigrationProgressDialog.INSTANCE
		dialog:setDialogType(DialogElement.TYPE_LOADING)
		dialog:setIsCloseAllowed(false)
		dialog:setProgress(progress or 0)
		g_gui:showDialog("SavegameMigrationProgressDialog")
	end
end
function SavegameMigrationProgressDialog.hide()
	g_gui:closeDialogByName("SavegameMigrationProgressDialog")
end
function SavegameMigrationProgressDialog.new(target, custom_mt)
	local self = DialogElement.new(target, custom_mt or SavegameMigrationProgressDialog_mt)
	return self
end
function SavegameMigrationProgressDialog.createFromExistingGui(gui, guiName)
	local newGui = SavegameMigrationProgressDialog.new()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	local dialogType = gui.dialogType
	local isCloseAllowed = gui.isCloseAllowed
	local text = gui.messageText
	local progress = gui.progress
	SavegameMigrationProgressDialog.show(text, progress, dialogType, isCloseAllowed)
	return newGui
end
function SavegameMigrationProgressDialog:onCreate(element)
	self:setDialogType(DialogElement.TYPE_LOADING)
end
function SavegameMigrationProgressDialog:onOpen()
	SavegameMigrationProgressDialog:superClass().onOpen(self)
	SavegameMigrationProgressDialog.INSTANCE.isOpen = true
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
function SavegameMigrationProgressDialog:onClose()
	SavegameMigrationProgressDialog:superClass().onClose(self)
	SavegameMigrationProgressDialog.INSTANCE.isOpen = false
end
function SavegameMigrationProgressDialog:setText(text)
	if self.dialogTextElement ~= nil then
		self.dialogTextElement:setText(Utils.getNoNil(text, self.defaultText))
	end
end
function SavegameMigrationProgressDialog.getIsOpen()
	if SavegameMigrationProgressDialog.INSTANCE ~= nil then
		return SavegameMigrationProgressDialog.INSTANCE.isOpen
	else
		return false
	end
end
function SavegameMigrationProgressDialog:setProgress(progress)
	self.progress = progress
	self.progressElement:setText(string.format("%d%%", progress))
end
