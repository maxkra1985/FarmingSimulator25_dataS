
-- Local values: modName, missionClass
function OnLoadingScreen(missionInfo, missionDynamicInfo, loadingScreen)
	local v4_ = Utils.getModNameAndBaseDirectory(missionInfo.scriptFilename)
	source(missionInfo.scriptFilename, v4_)
	if v4_ == nil or ClassUtil.getClassModName(missionInfo.scriptClass) == v4_ then
		local v_u_5_ = ClassUtil.getClassObject(missionInfo.scriptClass)
		if v_u_5_ == nil then
			printError("Error: mission class " .. missionInfo.scriptClass .. " could not be found.")
			OnInGameMenuMenu()
		else
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) v_u_5_, (copy) missionInfo, (copy) missionDynamicInfo
				if g_server ~= nil or g_client ~= nil then
					g_currentMission = v_u_5_.new(missionInfo.baseDirectory, nil)
					g_currentMission.missionInfo = missionInfo
					g_currentMission.missionDynamicInfo = missionDynamicInfo
					g_masterServerConnection:setCallbackTarget(g_currentMission)
				end
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) loadingScreen
				if g_server ~= nil or g_client ~= nil then
					g_currentMission:initialize()
					g_currentMission:setLoadingScreen(loadingScreen)
				end
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) missionInfo, (copy) missionDynamicInfo
				if g_server ~= nil or g_client ~= nil then
					g_currentMission:setMissionInfo(missionInfo, missionDynamicInfo)
				end
			end, "menu - OnLoadingScreen - setMissionInfo")
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) missionDynamicInfo
				if g_server ~= nil or g_client ~= nil then
					if not g_currentMission.cancelLoading then
						if missionDynamicInfo.isMultiplayer then
							if missionDynamicInfo.isClient then
								g_client:setNetworkListener(g_currentMission)
								g_client:start(missionDynamicInfo.serverAddress, missionDynamicInfo.serverPort, missionDynamicInfo.relayHeader)
								g_masterServerConnection:disconnectFromMasterServer()
							else
								g_server:setNetworkListener(g_currentMission)
								g_client:setNetworkListener(g_currentMission)
							end
						else
							g_server:setNetworkListener(g_currentMission)
							g_client:setNetworkListener(g_currentMission)
							g_server:startLocal()
						end
						if g_server ~= nil then
							g_server:init()
						end
						if not (missionDynamicInfo.isMultiplayer and missionDynamicInfo.isClient) then
							g_client:startLocal()
						end
					end
				end
			end)
		end
	else
		printError("Error: mission class " .. missionInfo.scriptClass .. " does not match expected mod name " .. v4_)
		OnInGameMenuMenu()
		return
	end
end

-- Local values: terrainSize, xzCoordinateMax, isCareer, goToMainMenu, restartScreen
function OnInGameMenuMenu(goToSignIn, wasNetworkError, restartArgs)
	print("quit savegame")
	setTextureStreamingPaused(true)
	saveReadSavegameFinish("", nil)
	startFrameRepeatMode()
	setPresenceMode(PresenceModes.PRESENCE_IDLE)
	if g_isDevelopmentVersion then
		local v_u_9_ = (g_currentMission == nil and 2048 or (g_currentMission.terrainSize or 2048)) * 0.6
		I3DUtil.iterateRecursively(getRootNode(), function(p10_)
			-- upvalues: (copy) v_u_9_
			if getHasClassId(p10_, ClassIds.SHAPE) and getRigidBodyType(p10_) == RigidBodyType.DYNAMIC then
				local v11_, v12_, v13_ = getWorldTranslation(p10_)
				if v12_ < -200 then
					Logging.warning("Object %q far below map at %d %d %d", I3DUtil.getNodePath(p10_), v11_, v12_, v13_)
					return
				end
				if v_u_9_ < math.abs(v11_) or v_u_9_ < math.abs(v13_) then
					Logging.warning("Object %q far out of bounds at %d %d %d", I3DUtil.getNodePath(p10_), v11_, v12_, v13_)
					return
				end
			end
		end)
	end
	if g_currentMission ~= nil then
		g_currentMission.cancelLoading = true
	end
	cancelAllStreamedI3DFiles()
	cancelAllStreamedI3DFiles()
	g_asyncTaskManager:flushAllTasks()
	g_asyncTaskManager:flushAllTasks()
	setStreamLowPriorityI3DFiles(true)
	if g_currentMission ~= nil and (g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer) then
		netSetIsEventProcessingEnabled(true)
	end
	g_masterServerConnection:disconnectFromMasterServer()
	g_masterServerConnection:setCallbackTarget(nil)
	if g_client ~= nil then
		g_client:stop()
	end
	if g_server ~= nil then
		g_server:stop()
	end
	local v14_ = false
	local v15_
	if g_currentMission == nil then
		v15_ = false
		v14_ = true
	else
		v15_ = g_currentMission.missionInfo == nil and true or g_currentMission.missionInfo:isa(FSCareerMissionInfo)
	end
	if g_currentMission ~= nil then
		g_gui:showGui("")
		g_currentMission:delete()
	end
	g_currentMission = nil
	g_server = nil
	g_client = nil
	g_connectionManager:shutdownAll()
	g_i3DManager:clearEntireSharedI3DFileCache(g_isDevelopmentVersion)
	g_mpLoadingScreen:unloadGameRelatedData()
	g_gameStateManager:setGameState(GameState.MENU_MAIN)
	forceEndFrameRepeatMode()
	if wasNetworkError and GS_PLATFORM_PLAYSTATION then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	else
		if v15_ then
			local v16_ = RestartManager.START_SCREEN_MAIN
			if goToSignIn then
				v16_ = RestartManager.START_SCREEN_GAMEPAD_SIGNIN
			end
			RestartManager:setStartScreen(v16_)
			doRestart(false, restartArgs or "")
			return
		end
		if v14_ then
			g_gui:showGui("MainScreen")
		else
			g_gameSettings:save()
			if goToSignIn then
				g_gui:showGui("GamepadSigninScreen")
			else
				g_gui:showGui("MainScreen")
			end
		end
	end
	g_inputBinding:setShowMouseCursor(true)
	simulatePhysics(false)
end
