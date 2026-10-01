ConnectionFailedDialog = {}
local ConnectionFailedDialog_mt = Class(ConnectionFailedDialog, InfoDialog)
local localRemoveActivation = removeActivation
removeActivation = nil
function ConnectionFailedDialog.register()
	local connectionFailedDialog = ConnectionFailedDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ConnectionFailedDialog.xml", "ConnectionFailedDialog", connectionFailedDialog)
	ConnectionFailedDialog.INSTANCE = connectionFailedDialog
	return connectionFailedDialog
end
function ConnectionFailedDialog.show(text, callback, target, callbackArgs)
	if ConnectionFailedDialog.INSTANCE ~= nil then
		local dialog = ConnectionFailedDialog.INSTANCE
		dialog:setCallback(callback, target, callbackArgs)
		dialog:setButtonTexts(nil)
		dialog:setDialogType(DialogElement.TYPE_WARNING)
		dialog:setText(text)
		g_gui:showDialog("ConnectionFailedDialog")
	end
end
function ConnectionFailedDialog.new(target, custom_mt)
	local self = InfoDialog.new(target, custom_mt or ConnectionFailedDialog_mt)
	return self
end
function ConnectionFailedDialog.createFromExistingGui(gui, guiName)
	ConnectionFailedDialog.register()
	local text = gui.connectionFailedText
	local callback = gui.onOk
	local target = gui.target
	local args = gui.args
	ConnectionFailedDialog.show(text, callback, target, args)
end
function ConnectionFailedDialog:setText(text)
	ConnectionFailedDialog:superClass().setText(self, text)
	if g_dedicatedServer ~= nil then
		printError("Error: " .. text)
	end
	self.connectionFailedText = text
end
function ConnectionFailedDialog:onWrongVersion(args)
	openWebFile(Platform.urlUpdate, "")
	if args ~= nil then
		g_gui:showGui(args[1])
	end
end
function ConnectionFailedDialog:onInvalidKey(args)
	openWebFile(Platform.urlBuyNow, "")
	if args ~= nil then
		g_gui:showGui(args[1])
	end
end
function ConnectionFailedDialog:onOkCallback(args)
	if args ~= nil then
		g_gui:showGui(args[1])
	end
end
function ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, nextScreenName)
	printError("Error: Failed to connect: " .. reason)
	local networkError = nil
	if GS_PLATFORM_PLAYSTATION then
		networkError = getNetworkError()
		if networkError then
			networkError = string.gsub(networkError, "Network", "dialog_network")
			nextScreenName = "MainScreen"
		end
	end
	if MasterServerConnection.FAILED_NONE == reason then
		printError("Error: reason is none, this should never happen.")
	elseif MasterServerConnection.FAILED_WRONG_VERSION == reason then
		ConnectionFailedDialog.show(g_i18n:getText("ui_outdatedGameVersion"), g_connectionFailedDialog.onWrongVersion, g_connectionFailedDialog, { nextScreenName })
	elseif MasterServerConnection.FAILED_PERMANENT_BAN == reason then
		if g_dedicatedServer ~= nil then
			localRemoveActivation()
		end
		ConnectionFailedDialog.show(g_i18n:getText("ui_permanentBan"), g_connectionFailedDialog.onInvalidKey, g_connectionFailedDialog, { nextScreenName })
	else
		local text = ""
		if MasterServerConnection.FAILED_UNKNOWN == reason then
			text = g_i18n:getText(networkError or "ui_connectionFailed")
		elseif MasterServerConnection.FAILED_MAINTENANCE == reason then
			text = g_i18n:getText("ui_serverMaintenance")
		elseif MasterServerConnection.FAILED_TEMPORARY_BAN == reason then
			if g_dedicatedServer ~= nil then
				localRemoveActivation()
			end
			text = g_i18n:getText("ui_temporaryBan")
		elseif MasterServerConnection.FAILED_CONNECTION_LOST == reason then
			text = g_i18n:getText(networkError or "ui_masterServerConnectionLost")
		elseif MasterServerConnection.FAILED_WRONG_PASSWORD == reason then
			text = g_i18n:getText(networkError or "ui_wrongPassword")
		elseif MasterServerConnection.FAILED_CONSOLE_USER_FAILED_AUTHENTICATION == reason then
			text = g_i18n:getText(networkError or "ui_connectionFailed")
		end
		ConnectionFailedDialog.show(text, g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { nextScreenName })
	end
	g_deepLinkingInfo = nil
	if g_dedicatedServer ~= nil then
		doExit()
	end
end
