-- Local values: SavegameController_mt, NO_TARGET
SavegameController = {}
local SavegameController_mt = Class(SavegameController)
SavegameController.NUM_SAVEGAMES = saveGetMaxNumOfSaveGames()
if GS_PLATFORM_PC then
	SavegameController.SAVING_DURATION = 0.5
elseif GS_IS_MOBILE_VERSION then
	SavegameController.SAVING_DURATION = 1
else
	SavegameController.SAVING_DURATION = 3
end
SavegameController.SAVE_STATE_NONE = 0
SavegameController.SAVE_STATE_VALIDATE_LIST = 1
SavegameController.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT = 2
SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT = 3
SavegameController.SAVE_STATE_OVERWRITE_DIALOG = 4
SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT = 5
SavegameController.SAVE_STATE_NOP_WRITE = 6
SavegameController.SAVE_STATE_WRITE = 7
SavegameController.SAVE_STATE_WRITE_WAIT = 8
SavegameController.SAVE_TASK_DENSITY_MAP = 0
SavegameController.SAVE_TASK_TERRAIN_HEIGHT_MAP = 1
SavegameController.SAVE_TASK_TERRAIN_LOD_TYPE_MAP = 2
SavegameController.SAVE_TASK_COLLISION_MAP = 3
SavegameController.SAVE_TASK_PLACEMENT_BLOCKING_MAP = 4
SavegameController.SAVE_TASK_SPLIT_SHAPES = 5
SavegameController.SAVE_TASK_BITVECTOR_MAP = 6
SavegameController.SAVE_TASK_NAVIGATION_MAP = 7
SavegameController.UPLOAD_STATE_OK = 0
SavegameController.UPLOAD_STATE_BAD_INDEX = 4
SavegameController.UPLOAD_STATE_LOAD_FAILED = 9
SavegameController.UPLOAD_STATE_PROGRESS = 11
SavegameController.DOWNLOAD_STATE_OK = 0
SavegameController.DOWNLOAD_STATE_NOT_FOUND = 7
SavegameController.DOWNLOAD_STATE_PROGRESS = 11
SavegameController.INFO_INVALID_USER = "invalidUser"
SavegameController.INFO_CORRUPT_FILE = "corrupt"
SavegameController.NO_SAVEGAME = {}
local NO_TARGET = {
	["NO_CALLBACK"] = function() end
}

-- Upvalues: SavegameController_mt, NO_TARGET
-- Local values: self
function SavegameController.new(customMt)
	-- upvalues: (copy) SavegameController_mt, (copy) NO_TARGET
	local v4_ = customMt or SavegameController_mt
	local v5_ = setmetatable({}, v4_)
	v5_.savegames = {}
	v5_.isSavingGame = false
	v5_.waitingForSaveGameInfo = false
	v5_.savingErrorCode = Savegame.ERROR_OK
	v5_.onDeleteCallback = NO_TARGET.NO_CALLBACK
	v5_.onDeleteCallbackTarget = NO_TARGET
	v5_.onSaveCompleteCallback = NO_TARGET.NO_CALLBACK
	v5_.onSaveCompleteCallbackTarget = NO_TARGET
	v5_.onUpdateCompleteCallback = NO_TARGET.NO_CALLBACK
	v5_.onUpdateCompleteTarget = NO_TARGET
	saveSetCloudErrorCallback("onCloudError", v5_)
	return v5_
end

-- Local values: k, missionInfo, savegameFiles, i, savegame, _, info, metadata, conflictedMetadata, _, isSoftConflict, xmlFile
function SavegameController:loadSavegames()
	for v7_, v8_ in pairs(self.savegames) do
		v8_:delete()
		self.savegames[v7_] = nil
	end
	local v9_ = Files.new(getUserProfileAppPath())
	for v10_ = 1, SavegameController.NUM_SAVEGAMES do
		local v11_ = FSCareerMissionInfo.new("", nil, v10_)
		if not Platform.isConsole then
			for _, v12_ in ipairs(v9_.files) do
				if v12_.filename == "savegame" .. v10_ .. ".zip" and not v12_.isDirectory then
					Logging.warning("Savegame %d is loaded from a ZIP file, but saving happens in a directory.", v10_)
					break
				end
			end
		end
		v11_:loadDefaults()
		local v14_, v14_, _, v15_ = saveGetInfoById(v10_)
		local v16_ = nil
		if v14_ ~= "" then
			v11_.hasConflict = v14_ ~= ""
			v11_.isSoftConflict = v15_
			v11_.conflictedMetadata = v14_
			v11_.uploadState = saveGetUploadState(v10_)
			if v11_.hasConflict then
				local _ = v11_.isSoftConflict
			end
			if v14_ == SavegameController.INFO_INVALID_USER then
				v11_.isInvalidUser = true
			elseif v14_ == SavegameController.INFO_CORRUPT_FILE then
				v11_.isCorruptFile = true
			else
				v16_ = loadXMLFileFromMemory("careerSavegameXML", v14_)
			end
		end
		if v16_ ~= nil then
			if not v11_:loadFromXML(v16_) then
				v11_:loadDefaults()
			end
			delete(v16_)
		end
		local v17_ = self.savegames
		table.insert(v17_, v11_)
	end
	g_messageCenter:publish(MessageType.SAVEGAMES_LOADED)
end

function SavegameController:resetStorageDeviceSelection()
	saveResetStorageDeviceSelection()
end

function SavegameController:onDebugSavegameUploadProgress(errorCode, progress)
	if self.debugSavegameUploadCallback ~= nil then
		self.debugSavegameUploadCallback(self.debugSavegameUploadTarget, errorCode, progress)
	end
end

function SavegameController:uploadDebugSavegame(savegameId, uploadKey, callbackFunc, callbackTarget)
	if saveUploadSavegameDebugInfo == nil then
		return false
	end
	self.debugSavegameUploadCallback = callbackFunc
	self.debugSavegameUploadTarget = callbackTarget
	saveUploadSavegameDebugInfo(savegameId, uploadKey, "onDebugSavegameUploadProgress", self)
	return true
end

function SavegameController:downloadDebugSavegame(uploadKey, savegameIndex, savegameId, callbackFunc, callbackTarget)
	if downloadSavegame == nil then
		return false
	end
	self.debugSavegameDownloadCallback = callbackFunc
	self.debugSavegameDownloadTarget = callbackTarget
	downloadSavegame(uploadKey, savegameIndex, savegameId, "onDebugSavegameDownloadProgress", self)
	return true
end

function SavegameController:onDebugSavegameDownloadProgress(errorCode, progress)
	if self.debugSavegameDownloadCallback ~= nil then
		self.debugSavegameDownloadCallback(self.debugSavegameDownloadTarget, errorCode, progress)
	end
end

-- Upvalues: NO_TARGET
function SavegameController:updateSavegames(callback, callbackTarget)
	-- upvalues: (copy) NO_TARGET
	if not self.waitingForSaveGameInfo then
		self.waitingForSaveGameInfo = true
		self.onUpdateCompleteCallback = callback or NO_TARGET.NO_CALLBACK
		self.onUpdateCompleteTarget = callbackTarget or NO_TARGET
		saveUpdateList("onSaveGameUpdateComplete", self)
	end
end

function SavegameController:cancelSavegameUpdate()
	saveCancelUpdateList()
end

function SavegameController:onSaveGameUpdateComplete(errorCode)
	self.waitingForSaveGameInfo = false
	self.onUpdateCompleteCallback(self.onUpdateCompleteTarget, errorCode)
end

function SavegameController:onSaveGameUpdateCompleteCloudError(errorCode)
	self.waitingForSaveGameInfo = false
	self:loadSavegames()
	self:tryToResolveConflict(self.cloudErrorConflictedSavegame)
	self.cloudErrorConflictedSavegame = nil
end

function SavegameController:onCloudError(errorCode, savegameId)
	local v44_ = tonumber(savegameId)
	if errorCode == Savegame.ERROR_CLOUD_CONFLICT then
		self:updateSavegames(self.onSaveGameUpdateCompleteCloudError, self)
		self.cloudErrorConflictedSavegame = v44_
	end
end

-- Local values: savegame
function SavegameController:tryToResolveConflict(savegameId, startCallback, savegameScreenCallback, showKeepBoth)
	local v50_ = self:getSavegame(savegameId)
	if v50_ ~= SavegameController.NO_SAVEGAME and v50_.hasConflict then
		if v50_.isSoftConflict then
			self:resolveConflict(savegameId, SaveGameResolvePolicy.KEEP_REMOTE)
			v50_.hasConflict = false
			return
		end
		SavegameConflictDialog.show(startCallback, savegameScreenCallback, v50_, savegameId, showKeepBoth)
	end
end

-- Local values: text, callback, target, args, yesText, noText
function SavegameController:resolveConflict(savegameId, resolvePolicy)
	if resolvePolicy == SaveGameResolvePolicy.KEEP_BOTH and self:getNumValidSavegames() == SavegameController.NUM_SAVEGAMES then
		InfoDialog.show(g_i18n:getText("ui_savegameConflictResolveKeepBothFailed"), self.savegameConflictResolveKeepBothFailed, self, nil, nil, nil, {
			["savegameId"] = savegameId
		})
		return false
	end
	if g_currentMission ~= nil then
		if resolvePolicy == SaveGameResolvePolicy.KEEP_BOTH then
			self:executeResolveConflict(savegameId, resolvePolicy)
			self:returnToSavegameSelection()
			return true
		end
		if resolvePolicy == SaveGameResolvePolicy.KEEP_REMOTE then
			local v54_ = g_i18n:getText("ui_savegameConflictKeepRemoteYesNo")
			local v55_ = self.onYesNoConflictKeepRemote
			local v56_ = g_i18n:getText("button_continue")
			local v57_ = g_i18n:getText("button_cancel")
			YesNoDialog.show(v55_, self, v54_, nil, v56_, v57_, nil, nil, nil, {
				["savegameId"] = savegameId
			})
			return true
		end
	end
	self:executeResolveConflict(savegameId, resolvePolicy)
	return true
end

function SavegameController:onYesNoConflictKeepRemote(yes, args)
	if yes then
		self:executeResolveConflict(args.savegameId, SaveGameResolvePolicy.KEEP_REMOTE)
		self:returnToSavegameSelection()
	else
		self:tryToResolveConflict(args.savegameId)
	end
end

function SavegameController:savegameConflictResolveKeepBothFailed(args)
	self:tryToResolveConflict(args.savegameId, nil, nil, false)
end

function SavegameController:executeResolveConflict(savegameId, resolvePolicy)
	self.currentSavegameToResolve = savegameId
	saveResolveConflict(savegameId, resolvePolicy, "onResolveConflictComplete", self)
end

-- Local values: resolvedSavegameId, savegame
function SavegameController:onResolveConflictComplete(errorCode, newSavegameId)
	local v68_ = self.currentSavegameToResolve
	self.currentSavegameToResolve = nil
	if errorCode == Savegame.ERROR_RESOLVE_FAILED then
		InfoDialog.show(g_i18n:getText("ui_savegameConflictResolveFailed"), self.returnToSavegameSelection, self)
	elseif v68_ ~= nil then
		local v69_ = self:getSavegame(v68_)
		if v69_ ~= SavegameController.NO_SAVEGAME then
			v69_.hasConflict = false
		end
	end
end

function SavegameController:returnToSavegameSelection()
	OnInGameMenuMenu()
	if g_gui.currentGuiName == "MainScreen" then
		g_mainScreen:onCareerClick(g_mainScreen.careerButton)
	end
end

-- Local values: foundBackups, files, _, v, timeStr, year, month, day, hour, minute
function SavegameController:locateBackups(backupBasePath, backupDirBase)
	local v72_ = Files.new(backupBasePath)
	local v73_ = {}
	for _, v74_ in pairs(v72_.files) do
		if v74_.isDirectory and v74_.filename:startsWith(backupDirBase) then
			local v75_, v76_, v77_, v78_, v79_ = v74_.filename:sub(backupDirBase:len() + 1):match("^(%d%d%d%d)-(%d%d)-(%d%d)_(%d%d)-(%d%d)$")
			local v80_ = tonumber(v75_)
			local v81_ = tonumber(v76_)
			local v82_ = tonumber(v77_)
			local v83_ = tonumber(v78_)
			local v84_ = tonumber(v79_)
			if v80_ ~= nil and (v81_ ~= nil and (v82_ ~= nil and (v83_ ~= nil and v84_ ~= nil))) then
				local v85_ = {
					["filename"] = v74_.filename,
					["toDelete"] = true,
					["time"] = {
						v80_,
						v81_,
						v82_,
						v83_,
						v84_
					}
				}
				table.insert(v73_, v85_)
			end
		end
	end
	return v73_
end

-- Local values: i, year, month, day, hour, _, _, offset, dateWithOffset, year1, month1, day1, hour1, minute1, minTimeDiff, minTimeDiffBackup, _, backup, timeDiff
function SavegameController:assignBackupDeleteFlags(dateNow, backups)
	table.sort(backups, SavegameController.backupSortFunction)
	local v89_ = #backups
	for v90_ = 1, math.min(4, v89_) do
		backups[v90_].toDelete = false
	end
	local v91_, v92_, v93_, v94_, _ = dateNow:match("(%d%d%d%d)-(%d%d)-(%d%d)_(%d%d)-(%d%d)")
	local v95_ = tonumber(v91_)
	local v96_ = tonumber(v92_)
	local v97_ = tonumber(v93_)
	local v98_ = tonumber(v94_)
	for _, v99_ in pairs(self.BACKUP_DATE_OFFSETS) do
		local v100_, v101_, v102_, v103_, v104_ = getDateAt("%Y-%m-%d_%H-%M", v95_, v96_, v97_, v98_, 0, 0, -v99_[1] * 60 * 60, v99_[2] * 60 * 60):match("(%d%d%d%d)-(%d%d)-(%d%d)_(%d%d)-(%d%d)")
		local v105_ = tonumber(v100_)
		local v106_ = tonumber(v101_)
		local v107_ = tonumber(v102_)
		local v108_ = tonumber(v103_)
		local v109_ = tonumber(v104_)
		local v110_ = nil
		local v111_ = 0
		for _, v112_ in pairs(backups) do
			local v113_ = getDateDiffSeconds(v112_.time[1], v112_.time[2], v112_.time[3], v112_.time[4], v112_.time[5], 0, v105_, v106_, v107_, v108_, v109_, 0)
			local v114_ = math.abs(v113_)
			if v110_ == nil or v114_ < v111_ then
				v111_ = v114_
				v110_ = v112_
			end
		end
		if v110_ ~= nil then
			v110_.toDelete = false
		end
	end
end

-- Local values: files, _, file, latestFile
function SavegameController:createBackup(savegame, backupBasePath, backupDirFull, backupDir)
	createFolder(backupBasePath)
	createFolder(backupDirFull)
	local v119_ = Files.new(savegame.savegameDirectory)
	for _, v120_ in pairs(v119_.files) do
		if not v120_.isDirectory then
			copyFile(savegame.savegameDirectory .. "/" .. v120_.filename, backupDirFull .. "/" .. v120_.filename, true)
		end
	end
	local v121_ = io.open(backupBasePath .. "/" .. savegame:getSavegameAutoBackupLatestFilename(savegame.savegameIndex), "w")
	if v121_ ~= nil then
		v121_:write("Latest auto backup directory: " .. backupDir)
		v121_:close()
	end
end

-- Local values: dateNow, backupBasePath, backupDirBase, backupDir, backupDirFull, foundBackups, _, backup
function SavegameController:backupSavegame(savegame)
	if savegame.isValid then
		local v124_ = getDate("%Y-%m-%d_%H-%M")
		local v125_ = savegame:getSavegameAutoBackupBasePath()
		local v126_ = savegame:getSavegameAutoBackupDirectoryBase(savegame.savegameIndex)
		local v127_ = v126_ .. v124_
		local v128_ = v125_ .. "/" .. v127_
		local v129_ = self:locateBackups(v125_, v126_)
		if #v129_ > 0 then
			self:assignBackupDeleteFlags(v124_, v129_)
			for _, v130_ in pairs(v129_) do
				if v130_.toDelete then
					deleteFolder(v125_ .. "/" .. v130_.filename)
				end
			end
		end
		self:createBackup(savegame, v125_, v128_, v127_)
	end
end

-- Local values: taskData
function SavegameController:addSaveTask(taskType, taskParam)
	local v134_ = self.saveTasks
	table.insert(v134_, {
		["type"] = taskType,
		["param"] = taskParam
	})
end

-- Local values: taskData
function SavegameController:executeSaveTask()
	if self.currentSaveTask > #self.saveTasks then
		self:onSaveTaskComplete(true)
		return
	else
		local v136_ = self.saveTasks[self.currentSaveTask]
		self.currentSaveTask = self.currentSaveTask + 1
		if v136_.type == SavegameController.SAVE_TASK_DENSITY_MAP then
			savePreparedDensityMapToFile(v136_.param, "onSaveTaskComplete", self)
			return
		elseif v136_.type == SavegameController.SAVE_TASK_TERRAIN_LOD_TYPE_MAP then
			savePreparedTerrainLodTypeMap(v136_.param, "onSaveTaskComplete", self)
			return
		elseif v136_.type == SavegameController.SAVE_TASK_TERRAIN_HEIGHT_MAP then
			savePreparedTerrainHeightMap(v136_.param, "onSaveTaskComplete", self)
			return
		elseif v136_.type == SavegameController.SAVE_TASK_COLLISION_MAP then
			g_densityMapHeightManager:savePreparedCollisionMap("onSaveTaskComplete", self)
			return
		elseif v136_.type == SavegameController.SAVE_TASK_PLACEMENT_BLOCKING_MAP then
			g_densityMapHeightManager:savePreparedPlacementCollisionMap("onSaveTaskComplete", self)
			return
		elseif v136_.type == SavegameController.SAVE_TASK_SPLIT_SHAPES then
			savePreparedSplitShapesToFile("onSaveTaskComplete", self)
			return
		elseif v136_.type == SavegameController.SAVE_TASK_BITVECTOR_MAP then
			savePreparedBitVectorMapToFile(v136_.param, "onSaveTaskComplete", self)
		elseif v136_.type == SavegameController.SAVE_TASK_NAVIGATION_MAP then
			savePreparedVehicleNavigationCostMapToFile(v136_.param, "onSaveTaskComplete", self)
		end
	end
end

function SavegameController:onSaveTaskComplete(success)
	if self.currentSaveTask > #self.saveTasks then
		saveWriteSavegameFinish(self.savegameMetadata, self.savegameDisplayDesc, "onSaveComplete", self)
	else
		self:executeSaveTask()
	end
end

-- Local values: startedRepeat, savegame, playTimeHoursF, playTimeHours, playTimeMinutes, dir, savedDensityMaps, _, fruitTypeDesc, id, haulmId, filename, filename, weedMapId, filename, path, infoLayer, filename, path, navigationCostMap, filename, path, stoneMapId, filename, densityMaps, _, densityMap, filename, path, decoFoliages, _, decoFoliage, id, filename, i, id, filename, terrainDetailHeightMapFilename
function SavegameController:onSaveStartComplete(errorCode, savegameDirectory)
	self.savingErrorCode = errorCode
	if errorCode == Savegame.ERROR_OK and savegameDirectory ~= nil then
		local v141_
		if self.isSavingBlocking then
			v141_ = startFrameRepeatMode()
		else
			v141_ = false
		end
		self.saveTasks = {}
		self.currentSaveTask = 1
		local v_u_142_ = self.currentSavegame
		v_u_142_:setSavegameDirectory(savegameDirectory)
		v_u_142_:saveToXMLFile()
		local v143_ = v_u_142_.playTime / 60 + 0.0001
		local v144_ = math.floor(v143_)
		local v145_ = (v143_ - v144_) * 60
		local v146_ = math.floor(v145_)
		self.savegameDisplayDesc = v_u_142_.map.title .. "\n" .. g_i18n:formatMoney(0) .. "\n" .. string.format("%02d:%02d", v144_, v146_)
		local v_u_147_ = v_u_142_.savegameDirectory
		local v148_ = {}
		for _, v149_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			local v_u_150_ = v149_.terrainDataPlaneId
			local v_u_151_ = v149_.terrainDataPlaneIdHaulm
			if v_u_150_ ~= nil then
				local v_u_152_ = getDensityMapFilename(v_u_150_)
				if v148_[v_u_152_] == nil then
					v148_[v_u_152_] = true
					if self.isSavingBlocking then
						saveDensityMapToFile(v_u_150_, v_u_147_ .. "/" .. v_u_152_)
					else
						g_asyncTaskManager:addTask(function()
							-- upvalues: (copy) v_u_150_, (copy) v_u_147_, (copy) v_u_152_, (copy) self
							prepareSaveDensityMapToFile(v_u_150_, v_u_147_ .. "/" .. v_u_152_)
							self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, v_u_150_)
						end)
					end
				end
			end
			if v_u_151_ ~= nil then
				local v_u_153_ = getDensityMapFilename(v_u_151_)
				if v148_[v_u_153_] == nil then
					v148_[v_u_153_] = true
					if self.isSavingBlocking then
						saveDensityMapToFile(v_u_151_, v_u_147_ .. "/" .. v_u_153_)
					else
						g_asyncTaskManager:addTask(function()
							-- upvalues: (copy) v_u_151_, (copy) v_u_147_, (copy) v_u_153_, (copy) self
							prepareSaveDensityMapToFile(v_u_151_, v_u_147_ .. "/" .. v_u_153_)
							self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, v_u_151_)
						end)
					end
				end
			end
		end
		local v_u_154_ = g_currentMission.weedSystem:getDensityMapData()
		if v_u_154_ ~= nil then
			local v155_ = getDensityMapFilename(v_u_154_)
			local v_u_156_ = v_u_147_ .. "/" .. v155_
			if v148_[v155_] == nil then
				v148_[v155_] = true
				if self.isSavingBlocking then
					saveDensityMapToFile(v_u_154_, v_u_156_)
				else
					g_asyncTaskManager:addTask(function()
						-- upvalues: (copy) v_u_154_, (copy) v_u_156_, (copy) self
						prepareSaveDensityMapToFile(v_u_154_, v_u_156_)
						self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, v_u_154_)
					end)
				end
			end
		end
		local v_u_157_ = g_currentMission.weedSystem:getInfoLayer()
		if v_u_157_ ~= nil then
			local v158_ = v_u_157_.filename
			local v_u_159_ = v_u_147_ .. "/" .. v158_
			if v148_[v158_] == nil then
				v148_[v158_] = true
				if self.isSavingBlocking then
					saveBitVectorMapToFile(v_u_157_.map, v_u_159_)
				else
					g_asyncTaskManager:addTask(function()
						-- upvalues: (copy) v_u_157_, (copy) v_u_159_, (copy) self
						prepareSaveBitVectorMapToFile(v_u_157_.map, v_u_159_)
						self:addSaveTask(SavegameController.SAVE_TASK_BITVECTOR_MAP, v_u_157_.map)
					end)
				end
			end
		end
		local v_u_160_ = g_currentMission.aiSystem:getNavigationMap()
		if v_u_160_ ~= nil then
			local v161_ = g_currentMission.aiSystem:getNavigationMapFilename()
			local v_u_162_ = v_u_147_ .. "/" .. v161_
			if v148_[v161_] == nil then
				v148_[v161_] = true
				if self.isSavingBlocking then
					saveVehicleNavigationCostMapToFile(v_u_160_, v_u_162_)
				else
					g_asyncTaskManager:addTask(function()
						-- upvalues: (copy) v_u_160_, (copy) v_u_162_, (copy) self
						prepareSaveVehicleNavigationCostMapToFile(v_u_160_, v_u_162_)
						self:addSaveTask(SavegameController.SAVE_TASK_NAVIGATION_MAP, v_u_160_)
					end)
				end
			end
		end
		local v_u_163_ = g_currentMission.stoneSystem:getDensityMapData()
		if v_u_163_ ~= nil then
			local v_u_164_ = getDensityMapFilename(v_u_163_)
			if v148_[v_u_164_] == nil then
				v148_[v_u_164_] = true
				if self.isSavingBlocking then
					saveDensityMapToFile(v_u_163_, v_u_147_ .. "/" .. v_u_164_)
				else
					g_asyncTaskManager:addTask(function()
						-- upvalues: (copy) v_u_163_, (copy) v_u_147_, (copy) v_u_164_, (copy) self
						prepareSaveDensityMapToFile(v_u_163_, v_u_147_ .. "/" .. v_u_164_)
						self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, v_u_163_)
					end)
				end
			end
		end
		local v165_ = g_currentMission.fieldGroundSystem:getDensityMaps()
		for _, v_u_166_ in pairs(v165_) do
			local v167_ = v_u_166_.filename
			local v_u_168_ = v_u_147_ .. "/" .. v167_
			if v148_[v167_] == nil then
				v148_[v167_] = true
				if self.isSavingBlocking then
					if v_u_166_.isBitVector then
						saveBitVectorMapToFile(v_u_166_.map, v_u_168_)
					else
						saveDensityMapToFile(v_u_166_.map, v_u_168_)
					end
				else
					g_asyncTaskManager:addTask(function()
						-- upvalues: (copy) v_u_166_, (copy) v_u_168_, (copy) self
						if v_u_166_.isBitVector then
							prepareSaveBitVectorMapToFile(v_u_166_.map, v_u_168_)
							self:addSaveTask(SavegameController.SAVE_TASK_BITVECTOR_MAP, v_u_166_.map)
						else
							prepareSaveDensityMapToFile(v_u_166_.map, v_u_168_)
							self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, v_u_166_.map)
						end
					end)
				end
			end
		end
		local v169_ = g_currentMission.foliageSystem:getDecoFoliages()
		for _, v170_ in pairs(v169_) do
			local v_u_171_ = v170_.terrainDataPlaneId
			if v_u_171_ ~= nil then
				local v_u_172_ = getDensityMapFilename(v_u_171_)
				if v148_[v_u_172_] == nil then
					v148_[v_u_172_] = true
					if self.isSavingBlocking then
						saveDensityMapToFile(v_u_171_, v_u_147_ .. "/" .. v_u_172_)
					else
						g_asyncTaskManager:addTask(function()
							-- upvalues: (copy) v_u_171_, (copy) v_u_147_, (copy) v_u_172_, (copy) self
							prepareSaveDensityMapToFile(v_u_171_, v_u_147_ .. "/" .. v_u_172_)
							self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, v_u_171_)
						end)
					end
				end
			end
		end
		for v173_ = 1, #g_currentMission.dynamicFoliageLayers do
			local v_u_174_ = g_currentMission.dynamicFoliageLayers[v173_]
			local v_u_175_ = getDensityMapFilename(v_u_174_)
			if v148_[v_u_175_] == nil then
				v148_[v_u_175_] = true
				if self.isSavingBlocking then
					saveDensityMapToFile(v_u_174_, v_u_147_ .. "/" .. v_u_175_)
				else
					g_asyncTaskManager:addTask(function()
						-- upvalues: (copy) v_u_174_, (copy) v_u_147_, (copy) v_u_175_, (copy) self
						prepareSaveDensityMapToFile(v_u_174_, v_u_147_ .. "/" .. v_u_175_)
						self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, v_u_174_)
					end)
				end
			end
		end
		local v_u_176_ = getDensityMapFilename(g_currentMission.terrainDetailHeightId)
		if v_u_176_ ~= nil and v148_[v_u_176_] == nil then
			v148_[v_u_176_] = true
			if self.isSavingBlocking then
				saveDensityMapToFile(g_currentMission.terrainDetailHeightId, v_u_147_ .. "/" .. v_u_176_)
			else
				g_asyncTaskManager:addTask(function()
					-- upvalues: (copy) v_u_147_, (copy) v_u_176_, (copy) self
					prepareSaveDensityMapToFile(g_currentMission.terrainDetailHeightId, v_u_147_ .. "/" .. v_u_176_)
					self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, g_currentMission.terrainDetailHeightId)
				end)
			end
		end
		if self.isSavingBlocking then
			g_currentMission.growthSystem:saveState(v_u_147_)
			g_currentMission.snowSystem:saveState(v_u_147_)
		else
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) v_u_147_
				g_currentMission.growthSystem:saveState(v_u_147_)
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) v_u_147_
				g_currentMission.snowSystem:saveState(v_u_147_)
			end)
		end
		if self.isSavingBlocking then
			saveSplitShapesToFile(v_u_147_ .. "/splitShapes.gmss")
		else
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) v_u_147_, (copy) self
				prepareSaveSplitShapesToFile(v_u_147_ .. "/splitShapes.gmss")
				self:addSaveTask(SavegameController.SAVE_TASK_SPLIT_SHAPES, 0)
			end)
		end
		if not GS_IS_MOBILE_VERSION then
			if self.isSavingBlocking then
				g_densityMapHeightManager:saveCollisionMap(v_u_147_)
			else
				g_asyncTaskManager:addTask(function()
					-- upvalues: (copy) v_u_147_, (copy) self
					g_densityMapHeightManager:prepareSaveCollisionMap(v_u_147_)
					self:addSaveTask(SavegameController.SAVE_TASK_COLLISION_MAP, 0)
				end)
			end
			if self.isSavingBlocking then
				g_densityMapHeightManager:savePlacementCollisionMap(v_u_147_)
			else
				g_asyncTaskManager:addTask(function()
					-- upvalues: (copy) v_u_147_, (copy) self
					g_densityMapHeightManager:prepareSavePlacementCollisionMap(v_u_147_)
					self:addSaveTask(SavegameController.SAVE_TASK_PLACEMENT_BLOCKING_MAP, 0)
				end)
			end
			if self.isSavingBlocking then
				saveTerrainLodTypeMap(g_terrainNode, v_u_147_ .. "/" .. getTerrainLodTypeMapFilename(g_terrainNode))
			else
				g_asyncTaskManager:addTask(function()
					-- upvalues: (copy) v_u_147_, (copy) self
					prepareSaveTerrainLodTypeMap(g_terrainNode, v_u_147_ .. "/" .. getTerrainLodTypeMapFilename(g_terrainNode))
					self:addSaveTask(SavegameController.SAVE_TASK_TERRAIN_LOD_TYPE_MAP, g_terrainNode)
				end)
			end
			if self.isSavingBlocking then
				saveTerrainLodNormalMap(g_terrainNode, v_u_147_ .. "/" .. getTerrainLodNormalMapFilename(g_terrainNode))
			else
				g_asyncTaskManager:addTask(function()
					-- upvalues: (copy) v_u_147_
					saveTerrainLodNormalMap(g_terrainNode, v_u_147_ .. "/" .. getTerrainLodNormalMapFilename(g_terrainNode))
				end)
			end
			if self.isSavingBlocking then
				saveTerrainHeightMap(g_terrainNode, v_u_147_ .. "/" .. getTerrainHeightMapFilename(g_terrainNode))
			else
				g_asyncTaskManager:addTask(function()
					-- upvalues: (copy) v_u_147_, (copy) self
					prepareSaveTerrainHeightMap(g_terrainNode, v_u_147_ .. "/" .. getTerrainHeightMapFilename(g_terrainNode))
					self:addSaveTask(SavegameController.SAVE_TASK_TERRAIN_HEIGHT_MAP, g_terrainNode)
				end)
			end
			if self.isSavingBlocking then
				saveTerrainOccludersCache(g_terrainNode, v_u_147_ .. "/" .. getTerrainOccludersCacheFilename(g_terrainNode))
			else
				g_asyncTaskManager:addTask(function()
					-- upvalues: (copy) v_u_147_
					saveTerrainOccludersCache(g_terrainNode, v_u_147_ .. "/" .. getTerrainOccludersCacheFilename(g_terrainNode))
				end)
			end
		end
		if self.isSavingBlocking then
			self.savegameMetadata = saveXMLFileToMemory(v_u_142_.xmlFile)
		else
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self, (copy) v_u_142_
				self.savegameMetadata = saveXMLFileToMemory(v_u_142_.xmlFile)
			end)
		end
		if self.isSavingBlocking and #self.saveTasks > 0 then
			printWarning("Warning: Blocking saving has async tasks")
		end
		if self.isSavingBlocking then
			self:executeSaveTask()
		else
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				self:executeSaveTask()
			end)
		end
		if v141_ then
			endFrameRepeatMode()
			return
		end
	else
		self:onSaveComplete(errorCode)
	end
end

-- Local values: savegame, directoryName, directoryStr, durationMsStr
function SavegameController:onSaveComplete(errorCode, finalSavegameDirectory)
	self.savingErrorCode = errorCode
	self.isSavingGame = false
	local v180_ = self.currentSavegame
	if v180_ ~= nil and not string.isNilOrWhitespace(finalSavegameDirectory) then
		v180_:setSavegameDirectory(finalSavegameDirectory)
	end
	if errorCode == Savegame.ERROR_OK then
		local v181_ = not string.isNilOrWhitespace(finalSavegameDirectory) and Utils.getDirectoryName(finalSavegameDirectory) or nil
		local v182_ = v181_ and string.format(" (%s)", v181_) or ""
		print(string.format("Game saved successfully%s.%s", v182_, ""))
	else
		printError("Game save failed. Error: " .. tostring(errorCode))
	end
	leaveCpuBoostMode()
	g_asyncTaskManager:setAllowedTimePerFrame(nil)
	self.onSaveCompleteCallback(self.onSaveCompleteCallbackTarget, errorCode)
end

function SavegameController:onSavegameDeleted(errorCode)
	self.onDeleteCallback(self.onDeleteCallbackTarget, errorCode)
end

-- Upvalues: NO_TARGET
-- Local values: savegame
function SavegameController:deleteSavegame(index, callback, callbackTarget)
	-- upvalues: (copy) NO_TARGET
	self.onDeleteCallback = callback or NO_TARGET.NO_CALLBACK
	self.onDeleteCallbackTarget = callbackTarget or NO_TARGET
	local v189_ = self.savegames[index]
	saveDeleteSavegame(v189_.savegameIndex, "onSavegameDeleted", self)
end

function SavegameController:saveSavegame(savegame, blocking)
	if savegame.supportsSaving == false then
		printWarning("Warning: Saving not supported by savegame/mission")
		self.onSaveCompleteCallback(self.onSaveCompleteCallbackTarget, Savegame.ERROR_OK)
		return
	elseif self.isSavingGame then
		printWarning("Warning: Saving while already saving")
		self.onSaveCompleteCallback(self.onSaveCompleteCallbackTarget, Savegame.ERROR_OPERATION_IN_PROGRESS)
	else
		self.isSavingGame = true
		self.isSavingBlocking = blocking
		enterCpuBoostMode()
		g_asyncTaskManager:setAllowedTimePerFrame(33.333333333333336)
		if savegame.isValid and not (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) then
			self:backupSavegame(savegame)
		end
		savegame.isValid = true
		savegame.densityMapRevision = g_densityMapRevision
		savegame.terrainTextureRevision = g_terrainTextureRevision
		savegame.terrainLodTextureRevision = g_terrainLodTextureRevision
		savegame.splitShapesRevision = g_splitShapesRevision
		savegame.tipCollisionRevision = g_tipCollisionRevision
		savegame.placementCollisionRevision = g_placementCollisionRevision
		savegame.navigationCollisionRevision = g_navigationCollisionRevision
		savegame.resetVehicles = false
		savegame:loadFromMission(g_currentMission)
		self.currentSavegame = savegame
		saveWriteSavegameStart(savegame.savegameIndex, savegame.displayName, FSCareerMissionInfo.MaxSavegameSize, "onSaveStartComplete", self)
	end
end

-- Local values: savegame
function SavegameController:getCanStartGame(index, allowConflicted)
	local v196_ = self:getSavegame(index)
	if allowConflicted or (v196_ == SavegameController.NO_SAVEGAME or not v196_.hasConflict) then
		if v196_ == SavegameController.NO_SAVEGAME or (not v196_.isValid or v196_.map ~= nil) then
			return index > 0
		else
			return false
		end
	else
		return false
	end
end

-- Local values: savegame
function SavegameController:getIsSavegameConflicted(index)
	local v199_ = self:getSavegame(index)
	return v199_ ~= SavegameController.NO_SAVEGAME and v199_.hasConflict and true or false
end

-- Local values: isValidSavegame, isInvalidUser, isCorruptSavegame
function SavegameController:getCanDeleteGame(index)
	if index > 0 and self.savegames[index] ~= nil then
		return self.savegames[index].isValid or (self.savegames[index].isInvalidUser or self.savegames[index].isCorruptFile)
	else
		return false
	end
end

function SavegameController:getSavegame(index)
	return self.savegames[index] or SavegameController.NO_SAVEGAME
end

-- Local values: num, i, savegame
function SavegameController:getNumValidSavegames()
	local v205_ = 0
	for v206_ = 1, SavegameController.NUM_SAVEGAMES do
		local v207_ = self:getSavegame(v206_)
		if v207_ ~= SavegameController.NO_SAVEGAME and v207_.isValid then
			v205_ = v205_ + 1
		end
	end
	return v205_
end

function SavegameController:getIsSaving()
	return self.isSavingGame
end

function SavegameController:getSavingErrorCode()
	return self.savingErrorCode
end

function SavegameController:getIsWaitingForSavegameInfo()
	return self.waitingForSaveGameInfo
end

function SavegameController:getNumberOfSavegames()
	return saveGetNumOfSaveGames()
end

function SavegameController:getMaxNumberOfSavegames()
	return SavegameController.NUM_SAVEGAMES
end

function SavegameController:isStorageDeviceUnavailable()
	return saveGetNumOfSaveGames() < 0
end

function SavegameController.backupSortFunction(a, b)
	if a.time[1] == b.time[1] then
		if a.time[2] == b.time[2] then
			if a.time[3] == b.time[3] then
				if a.time[4] == b.time[4] then
					return a.time[5] > b.time[5]
				else
					return a.time[4] > b.time[4]
				end
			else
				return a.time[3] > b.time[3]
			end
		else
			return a.time[2] > b.time[2]
		end
	else
		return a.time[1] > b.time[1]
	end
end
SavegameController.BACKUP_DATE_OFFSETS = {
	{ 1, 1 },
	{ 2, 1 },
	{ 3, 1 },
	{ 4, 1 },
	{ 5, 1 },
	{ 6, 6 },
	{ 12, 12 },
	{ 24, 24 },
	{ 48, 48 },
	{ 96, 96 },
	{ 192, 192 }
}
