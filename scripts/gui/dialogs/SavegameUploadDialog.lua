-- Local values: SavegameUploadDialog_mt
SavegameUploadDialog = {}
local SavegameUploadDialog_mt = Class(SavegameUploadDialog, TextInputDialog)
function SavegameUploadDialog.register()
	local v2_ = SavegameUploadDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SavegameUploadDialog.xml", "SavegameUploadDialog", v2_)
	SavegameUploadDialog.INSTANCE = v2_
end

-- Local values: dialog
function SavegameUploadDialog.show(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, confirmText, callbackArgs, text, applyTextFilter)
	if SavegameUploadDialog.INSTANCE ~= nil then
		local v13_ = SavegameUploadDialog.INSTANCE
		v13_:setButtonTexts(confirmText)
		v13_:setText(text)
		v13_:setCallback(callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, callbackArgs, applyTextFilter)
		g_gui:showDialog("SavegameUploadDialog")
	end
end

-- Upvalues: SavegameUploadDialog_mt
-- Local values: self
function SavegameUploadDialog.new(target, custom_mt)
	-- upvalues: (copy) SavegameUploadDialog_mt
	return TextInputDialog.new(target, custom_mt or SavegameUploadDialog_mt)
end

-- Local values: callback, target, defaultText, dialogPrompt, imePrompt, maxCharacters, confirmText, callbackArgs, text, applyTextFilter
function SavegameUploadDialog.createFromExistingGui(gui, guiName)
	SavegameUploadDialog.register()
	local v17_ = gui.onTextEntered
	local v18_ = gui.target
	local v19_ = gui.defaultText
	local v20_ = gui.dialogPrompt
	local v21_ = gui.imePrompt
	local v22_ = gui.maxCharacters
	local v23_ = gui.confirmText
	local v24_ = gui.callbackArgs
	local v25_ = gui.inputText
	local v26_ = gui.applyTextFilter
	SavegameUploadDialog.show(v17_, v18_, v19_, v20_, v21_, v22_, v23_, v24_, v25_, v26_)
end
