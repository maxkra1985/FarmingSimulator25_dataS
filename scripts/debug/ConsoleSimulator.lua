ConsoleSimulator = {}
ConsoleSimulator.MP_AVAILABILITY = nil
ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability and MultiplayerAvailability.AVAILABILITY_UNKNOWN or nil
ConsoleSimulator.NETWORK_ERROR = nil
ConsoleSimulator.ACHIEVEMENTS_AVAILABLE = true
ConsoleSimulator.NEW_DLCS = false
ConsoleSimulator.STORE_DLC_CHANGED = false
ConsoleSimulator.ALLOW_CROSSPLAY = nil
ConsoleSimulator.MOD_AVAILABILITY = MultiplayerAvailability and MultiplayerAvailability.NOT_AVAILABLE or nil
ConsoleSimulator.MAIN_USER_PROFILE = true
ConsoleSimulator.HDR_AVAILABLE = true
function ConsoleSimulator.init()
	local v_u_1_ = keyEvent
	function keyEvent(p2_, p3_, p4_, p5_)
		-- upvalues: (copy) v_u_1_
		if p5_ then
			if p3_ == Input.KEY_1 then
				Logging.devInfo("ConsoleSimulator: NETWORK_ERROR - Error")
				ConsoleSimulator.NETWORK_ERROR = "ERROR"
			elseif p3_ == Input.KEY_2 then
				Logging.devInfo("ConsoleSimulator: NETWORK_ERROR - Nil")
				ConsoleSimulator.NETWORK_ERROR = nil
			elseif p3_ == Input.KEY_3 then
				Logging.devInfo("ConsoleSimulator: MP_AVAILABILITY - nil")
				ConsoleSimulator.MP_AVAILABILITY = nil
			elseif p3_ == Input.KEY_4 then
				if MultiplayerAvailability == nil then
					Logging.devError("Multiplayer not available")
				else
					Logging.devInfo("ConsoleSimulator: MP_AVAILABILITY - AVAILABILITY_UNKNOWN")
					ConsoleSimulator.MP_AVAILABILITY = MultiplayerAvailability.AVAILABILITY_UNKNOWN
				end
			elseif p3_ == Input.KEY_5 then
				if MultiplayerAvailability == nil then
					Logging.devError("Multiplayer not available")
				else
					Logging.devInfo("ConsoleSimulator: MP_AVAILABILITY - NOT_AVAILABLE")
					ConsoleSimulator.MP_AVAILABILITY = MultiplayerAvailability.NOT_AVAILABLE
				end
			elseif p3_ == Input.KEY_6 then
				if MultiplayerAvailability == nil then
					Logging.devError("Multiplayer not available")
				else
					Logging.devInfo("ConsoleSimulator: MP_AVAILABILITY - NO_PRIVILEGES")
					ConsoleSimulator.MP_AVAILABILITY = MultiplayerAvailability.NO_PRIVILEGES
				end
			elseif p3_ == Input.KEY_7 then
				Logging.devInfo("ConsoleSimulator: finishedUserProfileSync")
				finishedUserProfileSync()
			elseif p3_ == Input.KEY_9 then
				Logging.devInfo("ConsoleSimulator: onMasterServerConnectionFailed - conenction lost")
				g_currentMission:onMasterServerConnectionFailed(MasterServerConnection.FAILED_CONNECTION_LOST)
			elseif p3_ == Input.KEY_0 then
				Logging.devInfo("ConsoleSimulator: NEW_DLCS")
				ConsoleSimulator.NEW_DLCS = true
				ConsoleSimulator.STORE_DLC_CHANGED = true
			elseif p3_ == Input.KEY_KP_1 then
				ConsoleSimulator.ACHIEVEMENTS_AVAILABLE = not ConsoleSimulator.ACHIEVEMENTS_AVAILABLE
				Logging.devInfo("ConsoleSimulator: ACHIEVEMENTS_AVAILABLE: %s", ConsoleSimulator.ACHIEVEMENTS_AVAILABLE)
			elseif p3_ == Input.KEY_KP_2 then
				if ConsoleSimulator.ALLOW_CROSSPLAY == nil then
					ConsoleSimulator.ALLOW_CROSSPLAY = true
				elseif ConsoleSimulator.ALLOW_CROSSPLAY == true then
					ConsoleSimulator.ALLOW_CROSSPLAY = false
				else
					ConsoleSimulator.ALLOW_CROSSPLAY = nil
				end
				Logging.devInfo("ConsoleSimulator: ALLOW_CROSSPLAY: %s", ConsoleSimulator.ALLOW_CROSSPLAY)
			elseif p3_ == Input.KEY_KP_4 then
				if MultiplayerAvailability == nil then
					Logging.devError("Multiplayer not available")
				else
					Logging.devInfo("ConsoleSimulator: CROSSPLAY_AVAILABILITY - AVAILABILITY_UNKNOWN")
					ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability.AVAILABILITY_UNKNOWN
				end
			elseif p3_ == Input.KEY_KP_5 then
				if MultiplayerAvailability == nil then
					Logging.devError("Multiplayer not available")
				else
					Logging.devInfo("ConsoleSimulator: CROSSPLAY_AVAILABILITY - NOT_AVAILABLE")
					ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability.NOT_AVAILABLE
				end
			elseif p3_ == Input.KEY_KP_6 then
				if MultiplayerAvailability == nil then
					Logging.devError("Multiplayer not available")
				else
					Logging.devInfo("ConsoleSimulator: CROSSPLAY_AVAILABILITY - NO_PRIVILEGES")
					ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability.NO_PRIVILEGES
				end
			elseif p3_ == Input.KEY_KP_7 then
				if MultiplayerAvailability == nil then
					Logging.devError("Multiplayer not available")
				else
					Logging.devInfo("ConsoleSimulator: CROSSPLAY_AVAILABILITY - NO_PRIVILEGES")
					ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability.AVAILABLE
				end
			elseif p3_ == Input.KEY_KP_8 then
				Logging.devInfo("ConsoleSimulator: ToggleUser")
				ConsoleSimulator.MAIN_USER_PROFILE = not ConsoleSimulator.MAIN_USER_PROFILE
			elseif p3_ == Input.KEY_KP_9 then
				Logging.devInfo("ConsoleSimulator: HDR Available")
				ConsoleSimulator.HDR_AVAILABLE = not ConsoleSimulator.HDR_AVAILABLE
			elseif p3_ == Input.KEY_KP_0 then
				ConsoleSimulator.IS_MODHUB_LOADED = not ConsoleSimulator.IS_MODHUB_LOADED
				Logging.devInfo("ConsoleSimulator: ModHub Loaded - %s", ConsoleSimulator.IS_MODHUB_LOADED)
			end
		end
		v_u_1_(p2_, p3_, p4_, p5_)
	end
	if getNetworkError ~= nil then
		local v_u_6_ = getNetworkError
		function getNetworkError()
			-- upvalues: (copy) v_u_6_
			if ConsoleSimulator.NETWORK_ERROR == nil then
				return v_u_6_()
			else
				return ConsoleSimulator.NETWORK_ERROR
			end
		end
	end
	local v_u_7_ = getUserProfileAppPath
	function getUserProfileAppPath()
		-- upvalues: (copy) v_u_7_
		local v8_ = v_u_7_()
		if ConsoleSimulator.MAIN_USER_PROFILE then
			return v8_
		else
			return string.gsub(v8_, "FarmingSimulator2025", "FarmingSimulator2025_SecondUser")
		end
	end
	if getMultiplayerAvailability ~= nil then
		local v_u_9_ = getMultiplayerAvailability
		function getMultiplayerAvailability()
			-- upvalues: (copy) v_u_9_
			if ConsoleSimulator.MP_AVAILABILITY == nil then
				return v_u_9_()
			else
				return ConsoleSimulator.MP_AVAILABILITY, false
			end
		end
	end
	if getCrossPlayAvailability ~= nil then
		local v_u_10_ = getCrossPlayAvailability
		function getCrossPlayAvailability(p11_)
			-- upvalues: (copy) v_u_10_
			if ConsoleSimulator.CROSSPLAY_AVAILABILITY == nil then
				return v_u_10_(p11_)
			else
				return ConsoleSimulator.CROSSPLAY_AVAILABILITY, Platform.isXbox and p11_
			end
		end
	end
	function areAchievementsAvailable()
		return ConsoleSimulator.ACHIEVEMENTS_AVAILABLE
	end
	function modDownloadManagerLoaded()
		return ConsoleSimulator.IS_MODHUB_LOADED
	end
	local v_u_12_ = startFrameRepeatMode
	function startFrameRepeatMode()
		-- upvalues: (copy) v_u_12_
		Logging.devInfo("ConsoleSimulator: startFrameRepeatMode")
		return v_u_12_()
	end
	local v_u_13_ = endFrameRepeatMode
	function endFrameRepeatMode()
		-- upvalues: (copy) v_u_13_
		Logging.devInfo("ConsoleSimulator: endFrameRepeatMode")
		return v_u_13_()
	end
	local v_u_14_ = forceEndFrameRepeatMode
	function forceEndFrameRepeatMode()
		-- upvalues: (copy) v_u_14_
		Logging.devInfo("ConsoleSimulator: forceEndFrameRepeatMode")
		v_u_14_()
	end
	local v_u_15_ = checkForNewDlcs
	function checkForNewDlcs()
		-- upvalues: (copy) v_u_15_
		if not ConsoleSimulator.NEW_DLCS then
			return v_u_15_()
		end
		ConsoleSimulator.NEW_DLCS = false
		return true
	end
	local v_u_16_ = storeHaveDlcsChanged
	function storeHaveDlcsChanged()
		-- upvalues: (copy) v_u_16_
		if not ConsoleSimulator.STORE_DLC_CHANGED then
			return v_u_16_()
		end
		ConsoleSimulator.STORE_DLC_CHANGED = false
		return true
	end
	function getModDownloadAvailability()
		return ConsoleSimulator.MP_AVAILABILITY or MultiplayerAvailability.AVAILABLE, false
	end
	if openMpFriendInvitation ~= nil then
		local v_u_17_ = openMpFriendInvitation
		function openMpFriendInvitation(p18_, p19_)
			-- upvalues: (copy) v_u_17_
			Logging.devInfo("ConsoleSimulator: Open friend invitation. Currently online: %d . Capacity: %d", p18_, p19_)
			v_u_17_(p18_, p19_)
		end
	end
	function getHdrAvailable()
		return ConsoleSimulator.HDR_AVAILABLE
	end
	addConsoleCommand("gsConsoleAcceptInvite", "Console simulator accept invitation", "acceptedGameInvite", ConsoleSimulator)
	printWarning("\n\n  ##################   Warning: Console Simulator active!   ##################\n\n")
end

function ConsoleSimulator.acceptedGameInvite(_, platformServerId, requestUserName)
	acceptedGameInvite(platformServerId or "2", requestUserName or "test -user")
end
