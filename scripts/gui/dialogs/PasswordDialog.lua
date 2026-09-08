-- Local values: PasswordDialog_mt
PasswordDialog = {}
local PasswordDialog_mt = Class(PasswordDialog, TextInputDialog)
function PasswordDialog.register()
	local v2_ = PasswordDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/PasswordDialog.xml", "PasswordDialog", v2_)
	PasswordDialog.INSTANCE = v2_
end

-- Local values: dialog
function PasswordDialog.show(callback, target, callbackArgs, defaultPassword, confirmButtonText)
	if PasswordDialog.INSTANCE ~= nil then
		local v8_ = PasswordDialog.INSTANCE
		v8_:setButtonTexts(confirmButtonText)
		v8_:setCallback(callback, target, defaultPassword, nil, nil, nil, callbackArgs, true)
		v8_:setText(nil)
		g_gui:showDialog("PasswordDialog")
	end
end

-- Upvalues: PasswordDialog_mt
-- Local values: self
function PasswordDialog.new(target, custom_mt)
	-- upvalues: (copy) PasswordDialog_mt
	return TextInputDialog.new(target, custom_mt or PasswordDialog_mt)
end

-- Local values: callback, target, defaultPassword, confirmButtonText, callbackArgs
function PasswordDialog.createFromExistingGui(gui, guiName)
	PasswordDialog.register()
	local v12_ = gui.onTextEntered
	local v13_ = gui.target
	local v14_ = gui.defaultText
	local v15_ = gui.confirmText
	local v16_ = gui.callbackArgs
	PasswordDialog.show(v12_, v13_, v16_, v14_, v15_)
end
