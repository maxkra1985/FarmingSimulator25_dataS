-- Local values: SavegameMigrationProgressDialog_mt
SavegameMigrationProgressDialog = {}
local SavegameMigrationProgressDialog_mt = Class(SavegameMigrationProgressDialog, DialogElement)
function SavegameMigrationProgressDialog.register()
	local v2_ = SavegameMigrationProgressDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SavegameMigrationProgressDialog.xml", "SavegameMigrationProgressDialog", v2_)
	SavegameMigrationProgressDialog.INSTANCE = v2_
	return v2_
end

-- Local values: dialog
function SavegameMigrationProgressDialog.show(progress)
	if SavegameMigrationProgressDialog.INSTANCE ~= nil then
		local v4_ = SavegameMigrationProgressDialog.INSTANCE
		v4_:setDialogType(DialogElement.TYPE_LOADING)
		v4_:setIsCloseAllowed(false)
		v4_:setProgress(progress or 0)
		g_gui:showDialog("SavegameMigrationProgressDialog")
	end
end
function SavegameMigrationProgressDialog.hide()
	g_gui:closeDialogByName("SavegameMigrationProgressDialog")
end

-- Upvalues: SavegameMigrationProgressDialog_mt
-- Local values: self
function SavegameMigrationProgressDialog.new(target, custom_mt)
	-- upvalues: (copy) SavegameMigrationProgressDialog_mt
	return DialogElement.new(target, custom_mt or SavegameMigrationProgressDialog_mt)
end

-- Local values: newGui, dialogType, isCloseAllowed, text, progress
function SavegameMigrationProgressDialog.createFromExistingGui(gui, guiName)
	local v9_ = SavegameMigrationProgressDialog.new()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_)
	local v10_ = gui.dialogType
	local v11_ = gui.isCloseAllowed
	local v12_ = gui.messageText
	local v13_ = gui.progress
	SavegameMigrationProgressDialog.show(v12_, v13_, v10_, v11_)
	return v9_
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
	if SavegameMigrationProgressDialog.INSTANCE == nil then
		return false
	else
		return SavegameMigrationProgressDialog.INSTANCE.isOpen
	end
end

function SavegameMigrationProgressDialog:setProgress(progress)
	self.progress = progress
	self.progressElement:setText(string.format("%d%%", progress))
end
