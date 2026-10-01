SavegameUploadDialog = {}
local SavegameUploadDialog_mt = Class(SavegameUploadDialog, TextInputDialog)
function SavegameUploadDialog.register()
	local savegameUploadDialog = SavegameUploadDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SavegameUploadDialog.xml", "SavegameUploadDialog", savegameUploadDialog)
	SavegameUploadDialog.INSTANCE = savegameUploadDialog
end
function SavegameUploadDialog.show(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, confirmText, callbackArgs, text)
	if SavegameUploadDialog.INSTANCE ~= nil then
		local dialog = SavegameUploadDialog.INSTANCE
		dialog:setButtonTexts(confirmText)
		dialog:setText(text)
		dialog:setCallback(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, callbackArgs, false)
		g_gui:showDialog("SavegameUploadDialog")
	end
end
function SavegameUploadDialog.new(target, custom_mt)
	local self = TextInputDialog.new(target, custom_mt or SavegameUploadDialog_mt)
	return self
end
function SavegameUploadDialog.createFromExistingGui(gui, guiName)
	SavegameUploadDialog.register()
	local callback = gui.onTextEntered
	local target = gui.target
	local defaultText = gui.defaultText
	local dialogPrompt = gui.dialogPrompt
	local imePrompt = gui.imePrompt
	local maxCharacters = gui.maxCharacters
	local confirmText = gui.confirmText
	local callbackArgs = gui.callbackArgs
	local text = gui.inputText
	SavegameUploadDialog.show(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, confirmText, callbackArgs, text)
end
