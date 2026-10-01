local getNumOfBlockedModsLocal = getNumOfBlockedMods
getNumOfBlockedMods = nil
local getBlockedModLocal = getBlockedMod
getBlockedMod = nil
ModSelectionScreen = {}
ModSelectionScreen.BG_PROFILE = "fs25_modSelectionListItemBackground"
ModSelectionScreen.BG_PROFILE_SELECTED = "fs25_modSelectionListItemBackgroundSelected"
ModSelectionScreen.COLOR_MAIN_DARK = { 0.00439, 0.00478, 0.00368, 1 }
ModSelectionScreen.COLOR_MAIN_LIGHT = { 0.89627, 0.92158, 0.81485, 1 }
ModSelectionScreen.AUTHOR_NAME_GIANTS = "GIANTS Software"
local ModSelectionScreen_mt = Class(ModSelectionScreen, ScreenElement)
function ModSelectionScreen.register()
	local modSelectionScreen = ModSelectionScreen.new()
	g_gui:loadGui("dataS/gui/ModSelectionScreen.xml", "ModSelectionScreen", modSelectionScreen)
	return modSelectionScreen
end
function ModSelectionScreen.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or ModSelectionScreen_mt)
	self.availableMods = {}
	self.sectionToData = {}
	self.blockedMods = {}
	self.updatableMods = {}
	self.selectedMods = {}
	self.uniqueTypesInUse = {}
	self.numAddedMods = 0
	self.numAddedModsBesidesMap = 0
	self.showBlockedError = true
	self.crossplayOnly = Platform.isConsole
	self.indexedSearch = IndexedSearch.new({ title = 5, modName = 3, author = 2 })
	self.overlayCache = OverlayCache.new()
	return self
end
function ModSelectionScreen.createFromExistingGui(gui, guiName)
	local newGui = ModSelectionScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	newGui.missionInfo = gui.missionInfo
	newGui.missionDynamicInfo = gui.missionDynamicInfo
	return newGui
end
function ModSelectionScreen:onGuiSetupFinished()
	ModSelectionScreen:superClass().onGuiSetupFinished(self)
	self.defaultTitle = self.title:getText()
end
function ModSelectionScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
end
function ModSelectionScreen:onOpen()
	ModSelectionScreen:superClass().onOpen(self)
	self.mapModName = g_mapManager:getModNameFromMapId(self.missionInfo.mapId)
	self.checkOutdatedMods = true
	self:loadAvailableMods()
	self.buttonToggleCrossplay:setText(self.crossplayOnly and g_i18n:getText("button_modHubShowAll") or g_i18n:getText("button_modHubShowCrossplay"))
	self.buttonToggleCrossplay:setVisible(not Platform.isConsole and self.missionDynamicInfo.isMultiplayer)
	self.buttonToggleCrossplay.parent:invalidateLayout()
	if self.mapModName ~= nil then
		self:setItemState(g_modManager:getModByName(self.mapModName), true)
	end
	local defaultModSetting = true
	if GS_PLATFORM_PLAYSTATION and getModUseAvailability(false) ~= MultiplayerAvailability.AVAILABLE then
		defaultModSetting = false
	end
	if self.missionInfo.isValid then
		for _, modInfo in pairs(self.missionInfo.mods) do
			if modInfo.modName == self.mapModName then
				continue
			end
			local modItem = g_modManager:getModByName(modInfo.modName)
			if modItem == nil then
				continue
			end
			if self:shouldShowModInList(modItem) then
				self:setItemState(modItem, modItem.isDLC or defaultModSetting)
			end
		end
	else
		for _, mod in ipairs(self.availableMods) do
			self:setItemState(mod, mod.isDLC or defaultModSetting)
		end
	end
	if Platform.isMobile or #self.availableMods == 0 then
		self:onClickOk()
	end
	if Platform.autoSelectDLCs then
		local hasMods = false
		for _, mod in ipairs(self.availableMods) do
			if not mod.isDLC then
				hasMods = true
				break
			end
		end
		if not hasMods then
			self:onClickOk()
		end
	end
end
function ModSelectionScreen:onClose()
	self.availableMods = {}
	self.selectedMods = {}
	self.sectionToData = {}
	self.indexedSearch:clear()
	self.uniqueTypesInUse = {}
	self.lastFilterValue = ""
	self.overlayCache:clearCache()
	ModSelectionScreen:superClass().onClose(self)
end
function ModSelectionScreen:toggleAllAction()
	local canSelectAll, hasMods = self:getCanSelectAll()
	if hasMods then
		if canSelectAll then
			local numDlc = 0
			local numMod = 0
			for _, modItem in pairs(self.availableMods) do
				if modItem.isDLC then
					numDlc = numDlc + 1
				else
					numMod = numMod + 1
				end
			end
			if 0 < numMod and (numDlc == 0 and not PlatformPrivilegeUtil.checkModUse(self.performSelectAll, self)) then
				return
			end
			self:performSelectAll()
			return
		end
		for section, data in ipairs(self.sectionToData) do
			for k, mod in ipairs(data.mods) do
				if self.selectedMods[mod] then
					self:setItemState(mod, false)
				end
			end
		end
	end
end
function ModSelectionScreen:performSelectAll()
	local modSetting = getModUseAvailability(false) == MultiplayerAvailability.AVAILABLE
	for section, data in ipairs(self.sectionToData) do
		for k, mod in ipairs(data.mods) do
			self:setItemState(mod, mod.isDLC or modSetting)
		end
	end
end
function ModSelectionScreen:selectCurrentMod()
	local mod = self:getSelectedMod()
	if mod == nil then
		return
	elseif not (not mod.isDLC and not PlatformPrivilegeUtil.checkModUse(self.selectCurrentMod, self)) then
		local newIsSelected = not self:getIsModSelected(mod)
		if newIsSelected and self.blockedMods[mod] then
			local updateableModId = self.updatableMods[mod]
			if updateableModId ~= nil then
				local callback = function(yes)
					if not yes then
						self:installOrUpdateMods({ updateableModId })
					end
				end
				local yesText = g_i18n:getText("button_ok")
				local noText = g_i18n:getText("button_modHubUpdate")
				YesNoDialog.show(callback, nil, g_i18n:getText("ui_modsCannotActivateBlockedModUpdate"), nil, yesText, noText, DialogElement.TYPE_WARNING)
				return
			else
				InfoDialog.show(g_i18n:getText("ui_modsCannotActivateBlockedMod"), nil, nil, DialogElement.TYPE_WARNING)
				return
			end
		end
		local updated = self:setItemState(mod, newIsSelected)
		if not updated then
			local activeUniqueMod = self.uniqueTypesInUse[mod.uniqueType]
			local callback = function(yes)
				if yes then
					self:setItemState(activeUniqueMod, false)
					self:setItemState(mod, true)
				end
			end
			YesNoDialog.show(callback, nil, string.format(g_i18n:getText("ui_modConflictQuestion"), mod.title, activeUniqueMod.title))
		end
	end
end
function ModSelectionScreen:toggleModAction()
	self:selectCurrentMod()
end
function ModSelectionScreen:onClickBack()
	if self.lastFilterValue ~= nil and self.lastFilterValue ~= "" then
		self:filter("")
		return true
	end
	return ModSelectionScreen:superClass().onClickBack(self)
end
function ModSelectionScreen:onClickOk()
	local unresolved = self:verifyDependencies()
	if #unresolved == 0 then
		local mods = {}
		local availableUpdateModIds = {}
		local scriptModsSelected = false
		for _, modItem in pairs(self.selectedMods) do
			table.insert(mods, modItem)
			local modId = self.updatableMods[modItem]
			if modId ~= nil then
				table.addElement(availableUpdateModIds, modId)
			end
			scriptModsSelected = modItem.hasScripts
		end
		for modItem, _ in pairs(self.blockedMods) do
			local modId = self.updatableMods[modItem]
			if modId == nil then
				continue
			end
			table.insert(availableUpdateModIds, modId)
		end
		local startGame = function()
			local mapMod = g_modManager:getModByName(self.mapModName)
			if mapMod ~= nil and self.blockedMods[mapMod] then
				InfoDialog.show(g_i18n:getText("ui_modMapBlocked"), nil, nil, DialogElement.TYPE_WARNING)
				return
			end
			self.missionDynamicInfo.mods = mods
			local returnScreen = ModSelectionScreen
			if #self.availableMods == 0 then
				returnScreen = nil
			end
			g_careerScreen:startGame(self.missionInfo, self.missionDynamicInfo, returnScreen)
		end
		local skipDialog = StartParams.getIsSet("autoStart") or StartParams.getIsSet("skipModUpdateDialog")
		local showIgnoreModUpdatesDialog = function()
			if g_dedicatedServer == nil and (0 < #availableUpdateModIds and not skipDialog) then
				local ignoreUpdates = function(action)
					if action == MultiOptionDialog.ACTION.ACCEPT then
						startGame()
					elseif action == MultiOptionDialog.ACTION.CANCEL then
						self:installOrUpdateMods(availableUpdateModIds)
					end
				end
				local acceptText = g_i18n:getText("button_start")
				local backText = g_i18n:getText("button_back")
				local cancelText = g_i18n:getText("button_modHubUpdate")
				MultiOptionDialog.show(ignoreUpdates, nil, g_i18n:getText("ui_mod_ignoreAvailableUpdates"), nil, acceptText, backText, nil, cancelText, DialogElement.TYPE_WARNING)
				return
			end
			startGame()
		end
		if GS_IS_MSSTORE_VERSION and (self.missionInfo.initialPlatformId == PlatformId.XBOX_SERIES and scriptModsSelected) then
			local startGameWithScriptMods = function(yes)
				if yes then
					self.missionInfo.initialPlatformId = getPlatformId()
					showIgnoreModUpdatesDialog()
				end
			end
			YesNoDialog.show(startGameWithScriptMods, nil, g_i18n:getText("ui_savegameCrossPlatformWarning"), nil, nil, nil, DialogElement.TYPE_WARNING)
			return
		end
		showIgnoreModUpdatesDialog()
	else
		if g_dedicatedServer == nil then
			local modsToActivate = {}
			local modIdsToDownload = {}
			local hasUnavailableMods = false
			local dependencyLines = {}
			for _, item in ipairs(unresolved) do
				if dependencyLines[item.mod.title] == nil then
					dependencyLines[item.mod.title] = item.dependencyTitle
				else
					dependencyLines[item.mod.title] = dependencyLines[item.mod.title] .. ", " .. item.dependencyTitle
				end
				if item.dependencyModId ~= nil then
					table.insert(modIdsToDownload, item.dependencyModId)
				elseif item.canActivate then
					table.insert(modsToActivate, item.dependencyMod)
				else
					hasUnavailableMods = true
				end
			end
			local listText = nil
			for title, deps in pairs(dependencyLines) do
				if listText == nil then
					listText = string.format(g_i18n:getText("ui_mod_required"), title, deps)
				else
					listText = listText .. " " .. string.format(g_i18n:getText("ui_mod_required"), title, deps)
				end
			end
			if 0 < #modsToActivate then
				local callback = function(yes)
					if yes then
						for _, modItem in ipairs(modsToActivate) do
							self:setItemState(modItem, true)
						end
					end
				end
				YesNoDialog.show(callback, nil, listText .. "\n\n" .. g_i18n:getText("ui_mod_selectAllRequired"), nil, nil, nil, DialogElement.TYPE_QUESTION)
				return
			end
			if 0 < #modIdsToDownload then
				local callback = function(yes)
					if yes then
						self:installOrUpdateMods(modIdsToDownload)
					end
				end
				YesNoDialog.show(callback, nil, listText .. "\n\n" .. g_i18n:getText("ui_mod_downloadAllRequired"), nil, nil, nil, DialogElement.TYPE_WARNING)
				return
			end
			if hasUnavailableMods then
				InfoDialog.show(listText, nil, nil, DialogElement.TYPE_WARNING)
			end
		else
			local dependencyLines = {}
			for _, item in ipairs(unresolved) do
				if dependencyLines[item.mod.title] == nil then
					dependencyLines[item.mod.title] = item.dependencyTitle
				else
					dependencyLines[item.mod.title] = dependencyLines[item.mod.title] .. ", " .. item.dependencyTitle
				end
			end
			local listText = nil
			for title, deps in pairs(dependencyLines) do
				if listText == nil then
					listText = "'" .. title .. "' wants " .. deps
				else
					listText = listText .. ";  '" .. title .. "' wants " .. deps
				end
			end
			Logging.error("Could not start dedicated server with current mod setup because some dependencies are missing: " .. listText)
			if g_dedicatedServer ~= nil then
				doExit()
			end
		end
	end
end
function ModSelectionScreen:onDoubleClick(index)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self:selectCurrentMod()
end
function ModSelectionScreen:toggleCrossplay()
	self.crossplayOnly = not self.crossplayOnly
	local selected = self.selectedMods
	self:loadAvailableMods()
	for _, mod in ipairs(self.availableMods) do
		if selected[mod] then
			self:setItemState(mod, true)
		end
	end
	self.buttonToggleCrossplay:setText(self.crossplayOnly and g_i18n:getText("button_modHubShowAll") or g_i18n:getText("button_modHubShowCrossplay"))
end
function ModSelectionScreen:update(dt)
	ModSelectionScreen:superClass().update(self, dt)
	if g_dedicatedServer ~= nil then
		for _, modItem in pairs(self.selectedMods) do
			self:setItemState(modItem, false)
		end
		for _, modName in pairs(g_dedicatedServer.mods) do
			local modItem = g_modManager:getModByName(modName)
			if modItem == nil then
				continue
			end
			if self:shouldShowModInList(modItem) then
				self:setItemState(modItem, true)
			else
				Logging.error("Mod '%s' is not available for current dedicated server setup", modItem.title)
			end
		end
		self:onClickOk()
	else
		if Profiler.IS_INITIALIZED then
			self:onClickOk()
		end
		if g_startMissionInfo.isMultiplayer then
			Platform.verifyMultiplayerAvailabilityInMenu()
		end
	end
end
function ModSelectionScreen:shouldShowModInList(mod)
	local showMod = not self.missionDynamicInfo.isMultiplayer or not mod.isMultiplayerSupported or mod.fileHash ~= nil
	if showMod and (not self.missionDynamicInfo.isMultiplayer and mod.multiplayerOnly) then
		showMod = false
	end
	if not mod.isSelectable then
		showMod = false
	end
	if showMod and (not mod.isDLC and mod.modName ~= self.mapModName) then
		for mapId, _ in pairs(g_mapManager.idToMap) do
			local modName = g_mapManager:getModNameFromMapId(mapId)
			if modName == nil then
				continue
			end
			if modName == mod.modName then
				showMod = false
				break
			end
		end
	end
	if not mod.isDLC and (self.crossplayOnly and (self.missionDynamicInfo.isMultiplayer and showMod)) then
		if mod.hasScripts and not mod.isInternalScriptMod then
			showMod = false
			return showMod
		end
		local modId = getModIdByFilename(mod.modName)
		if modId == 0 or getModMetaAttributeString(modId, "hash") ~= mod.fileHash then
			showMod = false
		end
	end
	return showMod
end
function ModSelectionScreen:isModActivated(name)
	for _, activeMod in pairs(self.selectedMods) do
		if activeMod.modName == name then
			return true
		end
	end
	return false
end
function ModSelectionScreen:verifyDependencies()
	local unresolved = {}
	for _, modItem in pairs(self.selectedMods) do
		if modItem.dependencies == nil then
			continue
		end
		if 0 < #modItem.dependencies then
			for _, depName in ipairs(modItem.dependencies) do
				if self:isModActivated(depName) then
					continue
				end
				local depMod = g_modManager:getModByName(depName)
				if depMod == nil then
					local modId = getModIdByFilename(depName)
					if modId ~= 0 then
						local modInfo = g_modHubController:getModInfo(modId)
						table.insert(unresolved, { mod = modItem, dependencyModId = modId, dependencyTitle = "'" .. modInfo:getName() .. "'" })
					else
						table.insert(unresolved, { mod = modItem, dependencyTitle = "'" .. depName .. ".zip'" })
					end
				else
					table.insert(unresolved, { mod = modItem, dependencyMod = depMod, dependencyTitle = "'" .. depMod.title .. "'", canActivate = true })
				end
			end
		end
	end
	return unresolved
end
function ModSelectionScreen:loadAvailableMods()
	self.indexedSearch:clear()
	self.availableMods = {}
	self.blockedMods = {}
	self.updatableMods = {}
	self.numUpdatableMods = 0
	self.selectedMods = {}
	local outdatedMods = nil
	local isModDownloadManagerLoaded = modDownloadManagerLoaded()
	local showBlockedError = self.showBlockedError
	if isModDownloadManagerLoaded then
		outdatedMods = {}
		for i = 0, getNumOfBlockedModsLocal() - 1 do
			local filename, minVersionStr, maxVersionStr, minModDesc, maxModDesc = getBlockedModLocal(i)
			if MathUtil.getIsOutOfBounds(g_maxModDescVersion, minModDesc, maxModDesc) then
				continue
			end
			local minVersion = minVersionStr ~= "" and Utils.getVersionParts(minVersionStr) or nil
			local maxVersion = Utils.getVersionParts(maxVersionStr)
			outdatedMods[filename] = { minVersion = minVersion, maxVersion = maxVersion }
		end
		self.showBlockedError = false
	else
		outdatedMods = g_outdatedMods
	end
	local mods = g_modManager:getMods()
	for _, mod in ipairs(mods) do
		if self:shouldShowModInList(mod) then
			local blockedVersionData = outdatedMods[mod.modName]
			if blockedVersionData ~= nil and blockedVersionData.maxVersion == nil then
				Logging.devWarning("Blocked mod version data for '%s' is missing a maxVersion, ignoring it.", mod.modName)
				blockedVersionData = nil
			end
			if blockedVersionData ~= nil then
				local versionParts = Utils.getVersionParts(mod.version)
				local minVersion = blockedVersionData.minVersion
				local maxVersion = blockedVersionData.maxVersion
				local isNotNewerThanMax = Utils.compareVersions(versionParts, maxVersion) < 1
				local isNotOlderThanMin = minVersion == nil or 0 <= Utils.compareVersions(versionParts, minVersion)
				if isNotNewerThanMax and isNotOlderThanMin then
					self.blockedMods[mod] = true
					if showBlockedError then
						printError(string.format("Error: Mod '%s' in version '%s' is outdated and not working properly. Please update the mod to resolve this!", mod.modName, mod.version))
					end
				end
			end
			if isModDownloadManagerLoaded then
				local modId = getModIdByFilename(mod.modName)
				if modId ~= 0 then
					local modInfo = g_modHubController:getModInfo(modId)
					local isUpdate = modInfo:getIsUpdate()
					local isExternal = modInfo:getIsExternal()
					local isDirectory = mod.isDirectory
					if modInfo ~= nil and (isUpdate and (not isExternal and (not isDirectory and (Platform.isPC or not modInfo:getIsDLC())))) then
						self.updatableMods[mod] = modId
						self.numUpdatableMods = self.numUpdatableMods + 1
					end
				end
			end
			table.insert(self.availableMods, mod)
			self.indexedSearch:addDocument({ title = mod.title, modName = string.gsub(mod.modName, "FS25_", ""), author = mod.author }, mod)
		end
	end
	self.indexedSearch:build()
	self.numAddedModsBesidesMap = 0
	self.numAddedMods = 0
	self:showMods(nil)
	for _, mod in ipairs(self.availableMods) do
		self:setItemState(mod, false)
	end
end
function ModSelectionScreen:filter(name)
	if string.isNilOrWhitespace(name) then
		name = ""
	end
	local changed = self.lastFilterValue ~= name
	if changed then
		local isSearching = true
		local success = self.indexedSearch:search(name, function(results)
			MessageDialog.hide()
			isSearching = false
			local mods = nil
			if results ~= nil then
				mods = {}
				for _, data in ipairs(results) do
					mods[data.ref] = data.score
				end
			end
			self:showMods(mods)
		end)
		if success then
			if isSearching then
				MessageDialog.show(g_i18n:getText("ui_storeSearching"))
			end
		else
			self:showMods(nil)
		end
		self.lastFilterValue = name
		local title = self.defaultTitle
		if self.lastFilterValue ~= "" then
			title = string.format("%s ('%s')", title, self.lastFilterValue)
		end
		self.title:setText(title)
	end
end
function ModSelectionScreen:showMods(mods)
	local updateables = {}
	local blocked = {}
	local others = {}
	local numMods = 0
	table.clear(self.sectionToData)
	for _, mod in ipairs(self.availableMods) do
		if mods == nil or mods[mod] then
			if self.updatableMods[mod] then
				table.insert(updateables, mod)
			elseif self.blockedMods[mod] then
				table.insert(blocked, mod)
			else
				table.insert(others, mod)
			end
			numMods = numMods + 1
		end
	end
	local sortMods = function(a, b)
		local isDlcA = a.isDLC or a.isFreeDLC
		local isDlcB = b.isDLC or b.isFreeDLC
		if mods ~= nil then
			local scoreA = mods[a]
			local scoreB = mods[b]
			if scoreA and scoreB then
				if scoreB < scoreA then
					return true
				end
				if scoreA < scoreB then
					return false
				end
			end
		end
		if isDlcA and not isDlcB then
			return true
		end
		if not isDlcA and isDlcB then
			return false
		end
		local isABlocked = self.blockedMods[a]
		local isBBlocked = self.blockedMods[b]
		if not isABlocked and isBBlocked then
			return true
		end
		if isABlocked and not isBBlocked then
			return false
		end
		if a.author == ModSelectionScreen.AUTHOR_NAME_GIANTS and b.author ~= ModSelectionScreen.AUTHOR_NAME_GIANTS then
			return true
		end
		if b.author == ModSelectionScreen.AUTHOR_NAME_GIANTS and a.author ~= ModSelectionScreen.AUTHOR_NAME_GIANTS then
			return false
		end
		return a.title < b.title
	end
	table.sort(updateables, sortMods)
	table.sort(blocked, sortMods)
	table.sort(others, sortMods)
	local hasUpdatables = 0 < #updateables
	if hasUpdatables then
		table.insert(self.sectionToData, { mods = updateables, title = g_i18n:getText("ui_modsUpdatesAvailable") })
	end
	if 0 < #blocked then
		table.insert(self.sectionToData, { mods = blocked, title = g_i18n:getText("ui_modsBlocked") })
	end
	table.insert(self.sectionToData, { mods = others, title = g_i18n:getText("ui_modsInstalled") })
	self.modList:reloadData()
	self.buttonSelect:setDisabled(numMods == 0)
	self.buttonSelectAll:setDisabled(false)
	self.noModsDLCsElement:setVisible(false)
end
function ModSelectionScreen:setItemState(item, isSelected)
	if item ~= nil then
		if isSelected and self.blockedMods[item] then
			return false
		end
		if item.uniqueType ~= nil then
			if self.uniqueTypesInUse[item.uniqueType] ~= nil then
				if isSelected then
					return false
				end
				self.uniqueTypesInUse[item.uniqueType] = nil
			elseif isSelected then
				self.uniqueTypesInUse[item.uniqueType] = item
			else
			end
		end
		local isNotUsedMap = self.mapModName == nil or item.modName ~= self.mapModName
		if isSelected then
			if self.selectedMods[item] == nil then
				if isNotUsedMap then
					self.numAddedModsBesidesMap = self.numAddedModsBesidesMap + 1
				end
				self.numAddedMods = self.numAddedMods + 1
			end
			self.selectedMods[item] = item
		elseif isNotUsedMap then
			if self.selectedMods[item] ~= nil then
				self.numAddedModsBesidesMap = self.numAddedModsBesidesMap - 1
				self.numAddedMods = self.numAddedMods - 1
			end
			self.selectedMods[item] = nil
		end
		if not isNotUsedMap then
			if self.blockedMods[item] then
				return false
			end
			isSelected = true
		end
		if item.isDLC and Platform.autoSelectDLCs then
			if self.blockedMods[item] then
				return false
			end
			isSelected = true
		end
		local section, index = self:getSectionAndIndexForItem(item)
		if index ~= nil then
			local cell = self.modList:getElementAtSectionIndex(section, index)
			if cell ~= nil and not cell.isEmptyCell then
				if isSelected then
					cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE_SELECTED)
					cell:getAttribute("title"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_DARK))
					cell:getAttribute("version"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_DARK))
				else
					cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE)
					cell:getAttribute("title"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_LIGHT))
					cell:getAttribute("version"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_LIGHT))
				end
			end
		end
		self.numSelectedModsText:setText(self.numAddedMods .. " / " .. #self.availableMods)
		if self.numSelectedModsBox ~= nil then
			self.numSelectedModsBox:invalidateLayout()
			self.numSelectedModsBoxBg:setSize(self.numSelectedModsBox.flowSizes[1] + 65 * g_pixelSizeScaledX)
		end
	end
	self:updateSelectButton()
	return true
end
function ModSelectionScreen:getSectionAndIndexForItem(item)
	for section, data in ipairs(self.sectionToData) do
		for k, mod in ipairs(data.mods) do
			if mod == item then
				return section, k
			end
		end
	end
	return nil, nil
end
function ModSelectionScreen:getIsModSelected(item)
	return self.selectedMods[item] ~= nil
end
function ModSelectionScreen:getSelectedMod()
	local sectionIndex = self.modList.selectedSectionIndex
	local sections = self.sectionToData[sectionIndex]
	if sections == nil then
		return nil
	else
		local index = self.modList.selectedIndex
		return sections.mods[index]
	end
end
function ModSelectionScreen:updateSelectButton()
	if self.selectedMods[self:getSelectedMod()] == nil then
		self.buttonSelect:setText(g_i18n:getText("button_select"))
	else
		self.buttonSelect:setText(g_i18n:getText("button_deselect"))
	end
	local canSelectAll, hasMods = self:getCanSelectAll()
	if hasMods then
		if canSelectAll then
			self.buttonSelectAll:setText(g_i18n:getText("button_selectAll"))
			return
		end
		self.buttonSelectAll:setText(g_i18n:getText("button_deselectAll"))
	end
end
function ModSelectionScreen:getCanSelectAll()
	local canSelectAll = false
	local hasMods = false
	for section, data in ipairs(self.sectionToData) do
		for k, mod in ipairs(data.mods) do
			if self.blockedMods[mod] == nil then
				hasMods = true
				if self.selectedMods[mod] == nil then
					canSelectAll = true
					break
				end
			end
		end
	end
	return canSelectAll, hasMods
end
function ModSelectionScreen:getNumberOfSections(list)
	return #self.sectionToData
end
function ModSelectionScreen:getTitleForSectionHeader(list, section)
	local data = self.sectionToData[section]
	return data.title
end
function ModSelectionScreen:getNumberOfItemsInSection(list, section)
	local data = self.sectionToData[section]
	return #data.mods
end
function ModSelectionScreen:populateCellForItemInSection(list, section, index, cell)
	local data = self.sectionToData[section]
	local mods = data.mods
	local mod = mods[index]
	local isSelected = self.selectedMods[mod]
	local isBlocked = self.blockedMods[mod]
	local hasUpdate = self.updatableMods[mod]
	if isSelected then
		cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE_SELECTED)
		cell:getAttribute("title"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_DARK))
		cell:getAttribute("version"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_DARK))
	else
		cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE)
		cell:getAttribute("title"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_LIGHT))
		cell:getAttribute("version"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_LIGHT))
	end
	local markerElement = cell:getAttribute("markerBox")
	if markerElement ~= nil then
		local markerUpdate = markerElement:getDescendantByName("markerUpdate")
		if markerUpdate ~= nil then
			markerUpdate:setVisible(hasUpdate)
		end
		local markerBlocked = markerElement:getDescendantByName("markerBlocked")
		if markerBlocked ~= nil then
			markerBlocked:setVisible(isBlocked)
		end
		cell:getAttribute("markerBox"):invalidateLayout()
	end
	if isBlocked then
		cell:getAttribute("title"):setTextColor(0.1, 0.1, 0.1, 1)
		cell:getAttribute("version"):setTextColor(0.1, 0.1, 0.1, 1)
		cell:getAttribute("icon"):setImageColor(nil, 0.2, 0.2, 0.2, 1)
	else
		cell:getAttribute("icon"):setImageColor(1, 1, 1, 1)
	end
	cell:getAttribute("title"):setText(mod.title)
	cell:getAttribute("version"):setText(g_i18n:getText("ui_modVersion") .. " " .. mod.version)
	cell:getAttribute("dlcTag"):setVisible(mod.isDLC or mod.isFreeDLC)
	cell:getAttribute("icon"):setImageFilename(mod.iconFilename)
	self.overlayCache:addOverlay(mod.iconFilename)
end
function ModSelectionScreen:onListSelectionChanged(list, section, index)
	self:updateSelectButton()
end
function ModSelectionScreen:onSearch()
	local dialogPrompt = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	local imePrompt = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	local confirmText = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	TextInputDialog.show(self.onSearchFinished, self, self.lastFilterValue, dialogPrompt, imePrompt, 40, confirmText, nil, nil, false)
end
function ModSelectionScreen:onSearchFinished(text, ok)
	if ok then
		self:filter(text)
	else
		self:filter("")
	end
end
function ModSelectionScreen:installOrUpdateMods(modIds)
	local finishCallback = function(numFailed)
		g_masterServerConnection:disconnectFromMasterServer()
		g_connectionManager:shutdownAll()
		g_modHubScreen:openDownloads()
		if 0 < numFailed then
			InfoDialog.show(g_i18n:getText("modHub_installFailed"))
		end
	end
	g_modHubController:installOrUpdateMods(modIds, finishCallback)
end
