PlatformPrivilegeUtil = {}
function PlatformPrivilegeUtil.checkModDownload(callback, callbackTarget)
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		return false
	end
	local availability, showsNativeGUI = getModDownloadAvailability()
	if availability ~= MultiplayerAvailability.AVAILABLE then
		if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			local updateCallback = PlatformPrivilegeUtil.checkModDownloadUpdateCallback
			local updateArgs = { showsNativeGUI = showsNativeGUI, callback = callback, callbackTarget = callbackTarget }
			local text = g_i18n:getText("ui_connectingPleaseWait")
			ConnectionPendingDialog.show(updateCallback, nil, text, nil, nil, updateArgs)
		elseif not showsNativeGUI then
			InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
		end
		return false
	else
		return true
	end
end
function PlatformPrivilegeUtil.checkModDownloadUpdateCallback(dt, args)
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	else
		local availability, showsNativeGUI = getModDownloadAvailability()
		args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI
		if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			ConnectionPendingDialog.hide()
			if availability == MultiplayerAvailability.AVAILABLE then
				if args.callback ~= nil then
					if args.callbackTarget ~= nil then
						args.callback(args.callbackTarget)
					else
						args.callback()
					end
				end
			elseif not args.showsNativeGUI then
				InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
			end
		end
	end
end
function PlatformPrivilegeUtil.checkModUse(callback, callbackTarget)
	local availability, showsNativeGUI = getModUseAvailability(true)
	if availability ~= MultiplayerAvailability.AVAILABLE then
		if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			local updateCallback = PlatformPrivilegeUtil.checkModUseUpdateCallback
			local updateArgs = { showsNativeGUI = showsNativeGUI, callback = callback, callbackTarget = callbackTarget }
			local text = g_i18n:getText("ui_connectingPleaseWait")
			ConnectionPendingDialog.show(updateCallback, nil, text, nil, nil, updateArgs)
		elseif not showsNativeGUI then
			InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
		end
		return false
	else
		return true
	end
end
function PlatformPrivilegeUtil.checkModUseUpdateCallback(dt, args)
	local availability, showsNativeGUI = getModUseAvailability(true)
	args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI
	if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
		ConnectionPendingDialog.hide()
		if availability == MultiplayerAvailability.AVAILABLE then
			if args.callback ~= nil then
				if args.callbackTarget ~= nil then
					args.callback(args.callbackTarget)
				else
					args.callback()
				end
			end
		elseif not args.showsNativeGUI then
			InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
		end
	end
end
function PlatformPrivilegeUtil.checkMultiplayer(callback, callbackTarget, callbackArgs, networkTimeout)
	local availability, showsNativeGUI = getMultiplayerAvailability()
	if getNetworkError() then
		if networkTimeout ~= nil then
			local updateCallback = PlatformPrivilegeUtil.checkMultiplayerUpdateCallback
			local updateArgs = { showsNativeGUI = showsNativeGUI, callback = callback, callbackTarget = callbackTarget, callbackArgs = callbackArgs, networkTimeout = networkTimeout }
			local text = g_i18n:getText("ui_connectingPleaseWait")
			ConnectionPendingDialog.show(updateCallback, nil, text, nil, nil, updateArgs)
		else
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
		return false
	elseif availability ~= MultiplayerAvailability.AVAILABLE then
		if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			local updateCallback = PlatformPrivilegeUtil.checkMultiplayerUpdateCallback
			local updateArgs = { showsNativeGUI = showsNativeGUI, callback = callback, callbackTarget = callbackTarget, callbackArgs = callbackArgs, networkTimeout = networkTimeout }
			local text = g_i18n:getText("ui_connectingPleaseWait")
			ConnectionPendingDialog.show(updateCallback, nil, text, nil, nil, updateArgs)
		elseif not showsNativeGUI then
			if GS_PLATFORM_XBOX then
				if availability == MultiplayerAvailability.NOT_AVAILABLE then
					InfoDialog.show(g_i18n:getText("ui_missingGoldForMultiplayer_xbox"))
				elseif availability == MultiplayerAvailability.NO_PRIVILEGES then
					InfoDialog.show(g_i18n:getText("ui_missingPrivilegeMultiplayerSession_xbox"))
				end
			end
		end
		return false
	else
		return true
	end
end
function PlatformPrivilegeUtil.checkMultiplayerUpdateCallback(dt, args)
	if args.networkTimeout ~= nil then
		args.networkTimeout = args.networkTimeout - dt
		if args.networkTimeout <= 0 then
			args.networkTimeout = nil
		end
	end
	if getNetworkError() then
		if args.networkTimeout == nil then
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
	else
		local availability, showsNativeGUI = getMultiplayerAvailability()
		args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI
		if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			ConnectionPendingDialog.hide()
			if availability == MultiplayerAvailability.AVAILABLE then
				if args.callback ~= nil then
					if args.callbackTarget ~= nil then
						args.callback(args.callbackTarget, args.callbackArgs)
					else
						args.callback(args.callbackArgs)
					end
				end
			elseif not args.showsNativeGUI then
				if GS_PLATFORM_XBOX then
					if availability == MultiplayerAvailability.NOT_AVAILABLE then
						InfoDialog.show(g_i18n:getText("ui_missingGoldForMultiplayer_xbox"))
						return
					end
					if availability == MultiplayerAvailability.NO_PRIVILEGES then
						InfoDialog.show(g_i18n:getText("ui_missingPrivilegeMultiplayerSession_xbox"))
					end
				end
			end
		end
	end
end
function PlatformPrivilegeUtil.getCanInvitePlayer(misson)
	return GS_IS_CONSOLE_VERSION
end
