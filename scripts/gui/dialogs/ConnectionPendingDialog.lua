-- Local values: ConnectionPendingDialog_mt
ConnectionPendingDialog = {}
local ConnectionPendingDialog_mt = Class(ConnectionPendingDialog, MessageDialog)
function ConnectionPendingDialog.register()
	local v2_ = ConnectionPendingDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ConnectionPendingDialog.xml", "ConnectionPendingDialog", v2_)
	ConnectionPendingDialog.INSTANCE = v2_
	return v2_
end

-- Local values: dialog
function ConnectionPendingDialog.show(callback, target, text, dialogType, isCloseAllowed, callbackArgs)
	if ConnectionPendingDialog.INSTANCE ~= nil then
		local v9_ = ConnectionPendingDialog.INSTANCE
		v9_:setDialogType(Utils.getNoNil(dialogType, DialogElement.TYPE_LOADING))
		v9_:setIsCloseAllowed(Utils.getNoNil(isCloseAllowed, true))
		v9_:setText(text)
		v9_:setUpdateCallback(callback, target, callbackArgs)
		g_gui:showDialog("ConnectionPendingDialog")
	end
end
function ConnectionPendingDialog.hide()
	g_gui:closeDialogByName("ConnectionPendingDialog")
end

-- Upvalues: ConnectionPendingDialog_mt
-- Local values: self
function ConnectionPendingDialog.new(target, custom_mt)
	-- upvalues: (copy) ConnectionPendingDialog_mt
	return MessageDialog.new(target, custom_mt or ConnectionPendingDialog_mt)
end

function ConnectionPendingDialog:onClickCancel()
	ConnectionPendingDialog.hide()
	if g_gui.currentGuiName ~= "MainScreen" then
		g_gui:changeScreen(nil, MainScreen)
	end
end
