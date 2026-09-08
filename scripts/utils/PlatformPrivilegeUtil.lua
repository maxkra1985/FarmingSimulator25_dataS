PlatformPrivilegeUtil = {}

-- Local values: availability, showsNativeGUI, updateCallback, updateArgs, text
function PlatformPrivilegeUtil.checkModDownload(callback, callbackTarget)
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		return false
	end
	local v3_, v4_ = getModDownloadAvailability()
	if v3_ == MultiplayerAvailability.AVAILABLE then
		return true
	end
	if v3_ == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
		local v5_ = PlatformPrivilegeUtil.checkModDownloadUpdateCallback
		local v6_ = g_i18n:getText("ui_connectingPleaseWait")
		ConnectionPendingDialog.show(v5_, nil, v6_, nil, nil, {
			["showsNativeGUI"] = v4_,
			["callback"] = callback,
			["callbackTarget"] = callbackTarget
		})
	elseif not v4_ then
		InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
	end
	return false
end

-- Local values: availability, showsNativeGUI
function PlatformPrivilegeUtil.checkModDownloadUpdateCallback(dt, args)
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	else
		local v8_, v9_ = getModDownloadAvailability()
		args.showsNativeGUI = args.showsNativeGUI or v9_
		if v8_ ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			ConnectionPendingDialog.hide()
			if v8_ == MultiplayerAvailability.AVAILABLE then
				if args.callback ~= nil then
					if args.callbackTarget == nil then
						args.callback()
					else
						args.callback(args.callbackTarget)
					end
				end
			elseif not args.showsNativeGUI then
				InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
			end
		end
	end
end

-- Local values: availability, showsNativeGUI, updateCallback, updateArgs, text
function PlatformPrivilegeUtil.checkModUse(callback, callbackTarget)
	local v12_, v13_ = getModUseAvailability(true)
	if v12_ == MultiplayerAvailability.AVAILABLE then
		return true
	end
	if v12_ == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
		local v14_ = PlatformPrivilegeUtil.checkModUseUpdateCallback
		local v15_ = g_i18n:getText("ui_connectingPleaseWait")
		ConnectionPendingDialog.show(v14_, nil, v15_, nil, nil, {
			["showsNativeGUI"] = v13_,
			["callback"] = callback,
			["callbackTarget"] = callbackTarget
		})
	elseif not v13_ then
		InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
	end
	return false
end

-- Local values: availability, showsNativeGUI
function PlatformPrivilegeUtil.checkModUseUpdateCallback(dt, args)
	local v17_, v18_ = getModUseAvailability(true)
	args.showsNativeGUI = args.showsNativeGUI or v18_
	if v17_ ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
		ConnectionPendingDialog.hide()
		if v17_ == MultiplayerAvailability.AVAILABLE then
			if args.callback ~= nil then
				if args.callbackTarget == nil then
					args.callback()
				else
					args.callback(args.callbackTarget)
				end
			end
		elseif not args.showsNativeGUI then
			InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
		end
	end
end

-- Local values: availability, showsNativeGUI, updateCallback, updateArgs, text, updateCallback, updateArgs, text
function PlatformPrivilegeUtil.checkMultiplayer(callback, callbackTarget, callbackArgs, networkTimeout)
	local v23_, v24_ = getMultiplayerAvailability()
	if getNetworkError() then
		if networkTimeout == nil then
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		else
			local v25_ = PlatformPrivilegeUtil.checkMultiplayerUpdateCallback
			local v26_ = g_i18n:getText("ui_connectingPleaseWait")
			ConnectionPendingDialog.show(v25_, nil, v26_, nil, nil, {
				["showsNativeGUI"] = v24_,
				["callback"] = callback,
				["callbackTarget"] = callbackTarget,
				["callbackArgs"] = callbackArgs,
				["networkTimeout"] = networkTimeout
			})
		end
		return false
	end
	if v23_ == MultiplayerAvailability.AVAILABLE then
		return true
	end
	if v23_ == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
		local v27_ = PlatformPrivilegeUtil.checkMultiplayerUpdateCallback
		local v28_ = g_i18n:getText("ui_connectingPleaseWait")
		ConnectionPendingDialog.show(v27_, nil, v28_, nil, nil, {
			["showsNativeGUI"] = v24_,
			["callback"] = callback,
			["callbackTarget"] = callbackTarget,
			["callbackArgs"] = callbackArgs,
			["networkTimeout"] = networkTimeout
		})
	elseif not v24_ and GS_PLATFORM_XBOX then
		if v23_ == MultiplayerAvailability.NOT_AVAILABLE then
			InfoDialog.show(g_i18n:getText("ui_missingGoldForMultiplayer_xbox"))
		elseif v23_ == MultiplayerAvailability.NO_PRIVILEGES then
			InfoDialog.show(g_i18n:getText("ui_missingPrivilegeMultiplayerSession_xbox"))
		end
	end
	return false
end

-- Local values: availability, showsNativeGUI
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
		local v31_, v32_ = getMultiplayerAvailability()
		args.showsNativeGUI = args.showsNativeGUI or v32_
		if v31_ ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			ConnectionPendingDialog.hide()
			if v31_ == MultiplayerAvailability.AVAILABLE then
				if args.callback ~= nil then
					if args.callbackTarget == nil then
						args.callback(args.callbackArgs)
					else
						args.callback(args.callbackTarget, args.callbackArgs)
					end
				end
			elseif not args.showsNativeGUI and GS_PLATFORM_XBOX then
				if v31_ == MultiplayerAvailability.NOT_AVAILABLE then
					InfoDialog.show(g_i18n:getText("ui_missingGoldForMultiplayer_xbox"))
					return
				end
				if v31_ == MultiplayerAvailability.NO_PRIVILEGES then
					InfoDialog.show(g_i18n:getText("ui_missingPrivilegeMultiplayerSession_xbox"))
				end
			end
		end
	end
end

function PlatformPrivilegeUtil.getCanInvitePlayer(misson)
	return GS_IS_CONSOLE_VERSION
end
