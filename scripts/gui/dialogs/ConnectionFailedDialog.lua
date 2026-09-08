-- Local values: ConnectionFailedDialog_mt, localRemoveActivation
ConnectionFailedDialog = {}
local ConnectionFailedDialog_mt = Class(ConnectionFailedDialog, InfoDialog)
local localRemoveActivation = removeActivation
removeActivation = nil
function ConnectionFailedDialog.register()
	local v3_ = ConnectionFailedDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ConnectionFailedDialog.xml", "ConnectionFailedDialog", v3_)
	ConnectionFailedDialog.INSTANCE = v3_
	return v3_
end

-- Local values: dialog
function ConnectionFailedDialog.show(text, callback, target, callbackArgs)
	if ConnectionFailedDialog.INSTANCE ~= nil then
		local v8_ = ConnectionFailedDialog.INSTANCE
		v8_:setCallback(callback, target, callbackArgs)
		v8_:setButtonTexts(nil)
		v8_:setDialogType(DialogElement.TYPE_WARNING)
		v8_:setText(text)
		g_gui:showDialog("ConnectionFailedDialog")
	end
end

-- Upvalues: ConnectionFailedDialog_mt
-- Local values: self
function ConnectionFailedDialog.new(target, custom_mt)
	-- upvalues: (copy) ConnectionFailedDialog_mt
	return InfoDialog.new(target, custom_mt or ConnectionFailedDialog_mt)
end

-- Local values: text, callback, target, args
function ConnectionFailedDialog.createFromExistingGui(gui, guiName)
	ConnectionFailedDialog.register()
	local v12_ = gui.connectionFailedText
	local v13_ = gui.onOk
	local v14_ = gui.target
	local v15_ = gui.args
	ConnectionFailedDialog.show(v12_, v13_, v14_, v15_)
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

-- Upvalues: localRemoveActivation
-- Local values: networkError, text
function ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, nextScreenName)
	-- upvalues: (copy) localRemoveActivation
	printError("Error: Failed to connect: " .. reason)
	local v23_
	if GS_PLATFORM_PLAYSTATION then
		v23_ = getNetworkError()
		if v23_ then
			v23_ = string.gsub(v23_, "Network", "dialog_network")
			nextScreenName = "MainScreen"
		end
	else
		v23_ = nil
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
		local v24_ = ""
		if MasterServerConnection.FAILED_UNKNOWN == reason then
			v24_ = g_i18n:getText(v23_ or "ui_connectionFailed")
		elseif MasterServerConnection.FAILED_MAINTENANCE == reason then
			v24_ = g_i18n:getText("ui_serverMaintenance")
		elseif MasterServerConnection.FAILED_TEMPORARY_BAN == reason then
			if g_dedicatedServer ~= nil then
				localRemoveActivation()
			end
			v24_ = g_i18n:getText("ui_temporaryBan")
		elseif MasterServerConnection.FAILED_CONNECTION_LOST == reason then
			v24_ = g_i18n:getText(v23_ or "ui_masterServerConnectionLost")
		elseif MasterServerConnection.FAILED_WRONG_PASSWORD == reason then
			v24_ = g_i18n:getText(v23_ or "ui_wrongPassword")
		elseif MasterServerConnection.FAILED_CONSOLE_USER_FAILED_AUTHENTICATION == reason then
			v24_ = g_i18n:getText(v23_ or "ui_connectionFailed")
		end
		ConnectionFailedDialog.show(v24_, g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { nextScreenName })
	end
	g_deepLinkingInfo = nil
	if g_dedicatedServer ~= nil then
		doExit()
	end
end
