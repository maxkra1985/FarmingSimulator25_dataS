-- Local values: ModSelectionScreen_mt
ModSelectionScreen = {}
ModSelectionScreen.BG_PROFILE = "fs25_modSelectionListItemBackground"
ModSelectionScreen.BG_PROFILE_SELECTED = "fs25_modSelectionListItemBackgroundSelected"
ModSelectionScreen.COLOR_MAIN_DARK = {
	0.00439,
	0.00478,
	0.00368,
	1
}
ModSelectionScreen.COLOR_MAIN_LIGHT = {
	0.89627,
	0.92158,
	0.81485,
	1
}
ModSelectionScreen.AUTHOR_NAME_GIANTS = "GIANTS Software"
local ModSelectionScreen_mt = Class(ModSelectionScreen, ScreenElement)
function ModSelectionScreen.register()
	local v2_ = ModSelectionScreen.new()
	g_gui:loadGui("dataS/gui/ModSelectionScreen.xml", "ModSelectionScreen", v2_)
	return v2_
end

-- Upvalues: ModSelectionScreen_mt
-- Local values: self
function ModSelectionScreen.new(target, custom_mt)
	-- upvalues: (copy) ModSelectionScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or ModSelectionScreen_mt)
	v5_.availableMods = {}
	v5_.sectionToData = {}
	v5_.blockedMods = {}
	v5_.updatableMods = {}
	v5_.selectedMods = {}
	v5_.uniqueTypesInUse = {}
	v5_.numAddedMods = 0
	v5_.numAddedModsBesidesMap = 0
	v5_.showBlockedError = true
	v5_.crossplayOnly = Platform.isConsole
	v5_.indexedSearch = IndexedSearch.new({
		["title"] = 5,
		["modName"] = 3,
		["author"] = 2
	})
	v5_.overlayCache = OverlayCache.new()
	return v5_
end

-- Local values: newGui
function ModSelectionScreen.createFromExistingGui(gui, guiName)
	local v8_ = ModSelectionScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	v8_.missionInfo = gui.missionInfo
	v8_.missionDynamicInfo = gui.missionDynamicInfo
	return v8_
end

function ModSelectionScreen:onGuiSetupFinished()
	ModSelectionScreen:superClass().onGuiSetupFinished(self)
	self.defaultTitle = self.title:getText()
end

function ModSelectionScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
end

-- Local values: defaultModSetting, _, modInfo, modItem, _, mod, hasMods, _, mod
function ModSelectionScreen:onOpen()
	ModSelectionScreen:superClass().onOpen(self)
	self.mapModName = g_mapManager:getModNameFromMapId(self.missionInfo.mapId)
	self.checkOutdatedMods = true
	self:loadAvailableMods()
	self.buttonToggleCrossplay:setText(self.crossplayOnly and g_i18n:getText("button_modHubShowAll") or g_i18n:getText("button_modHubShowCrossplay"))
	local v14_ = self.buttonToggleCrossplay
	local v15_ = not Platform.isConsole
	if v15_ then
		v15_ = self.missionDynamicInfo.isMultiplayer
	end
	v14_:setVisible(v15_)
	self.buttonToggleCrossplay.parent:invalidateLayout()
	if self.mapModName ~= nil then
		self:setItemState(g_modManager:getModByName(self.mapModName), true)
	end
	local v16_ = (not GS_PLATFORM_PLAYSTATION or getModUseAvailability(false) == MultiplayerAvailability.AVAILABLE) and true or false
	if self.missionInfo.isValid then
		for _, v17_ in pairs(self.missionInfo.mods) do
			if v17_.modName ~= self.mapModName then
				local v18_ = g_modManager:getModByName(v17_.modName)
				if v18_ ~= nil and self:shouldShowModInList(v18_) then
					self:setItemState(v18_, v18_.isDLC or v16_)
				end
			end
		end
	else
		for _, v19_ in ipairs(self.availableMods) do
			self:setItemState(v19_, v19_.isDLC or v16_)
		end
	end
	if Platform.isMobile or #self.availableMods == 0 then
		self:onClickOk()
	end
	if Platform.autoSelectDLCs then
		local v20_ = false
		for _, v21_ in ipairs(self.availableMods) do
			if not v21_.isDLC then
				v20_ = true
				break
			end
		end
		if not v20_ then
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

-- Local values: canSelectAll, hasMods, numDlc, numMod, _, modItem, section, data, k, mod
function ModSelectionScreen:toggleAllAction()
	local v24_, v25_ = self:getCanSelectAll()
	if v25_ then
		if v24_ then
			local v26_ = 0
			local v27_ = 0
			for _, v28_ in pairs(self.availableMods) do
				if v28_.isDLC then
					v26_ = v26_ + 1
				else
					v27_ = v27_ + 1
				end
			end
			if v27_ <= 0 or (v26_ ~= 0 or PlatformPrivilegeUtil.checkModUse(self.performSelectAll, self)) then
				self:performSelectAll()
			end
		end
		for _, v29_ in ipairs(self.sectionToData) do
			for _, v30_ in ipairs(v29_.mods) do
				if self.selectedMods[v30_] then
					self:setItemState(v30_, false)
				end
			end
		end
	end
end

-- Local values: modSetting, section, data, k, mod
function ModSelectionScreen:performSelectAll()
	local v32_ = getModUseAvailability(false) == MultiplayerAvailability.AVAILABLE
	for _, v33_ in ipairs(self.sectionToData) do
		for _, v34_ in ipairs(v33_.mods) do
			self:setItemState(v34_, v34_.isDLC or v32_)
		end
	end
end

-- Local values: mod, newIsSelected, updateableModId, callback, yesText, noText, updated, activeUniqueMod, callback
function ModSelectionScreen:selectCurrentMod()
	local v_u_36_ = self:getSelectedMod()
	if v_u_36_ == nil then
		return
	elseif v_u_36_.isDLC or PlatformPrivilegeUtil.checkModUse(self.selectCurrentMod, self) then
		local v37_ = not self:getIsModSelected(v_u_36_)
		if v37_ and self.blockedMods[v_u_36_] then
			local v_u_38_ = self.updatableMods[v_u_36_]
			if v_u_38_ == nil then
				InfoDialog.show(g_i18n:getText("ui_modsCannotActivateBlockedMod"), nil, nil, DialogElement.TYPE_WARNING)
			else
				local v39_ = g_i18n:getText("button_ok")
				local v40_ = g_i18n:getText("button_modHubUpdate")
				YesNoDialog.show(function(p41_)
					-- upvalues: (copy) self, (copy) v_u_38_
					if not p41_ then
						self:installOrUpdateMods({ v_u_38_ })
					end
				end, nil, g_i18n:getText("ui_modsCannotActivateBlockedModUpdate"), nil, v39_, v40_, DialogElement.TYPE_WARNING)
			end
		else
			if not self:setItemState(v_u_36_, v37_) then
				local v_u_42_ = self.uniqueTypesInUse[v_u_36_.uniqueType]
				YesNoDialog.show(function(p43_)
					-- upvalues: (copy) self, (copy) v_u_42_, (copy) v_u_36_
					if p43_ then
						self:setItemState(v_u_42_, false)
						self:setItemState(v_u_36_, true)
					end
				end, nil, string.format(g_i18n:getText("ui_modConflictQuestion"), v_u_36_.title, v_u_42_.title))
			end
			return
		end
	else
		return
	end
end

function ModSelectionScreen:toggleModAction()
	self:selectCurrentMod()
end

function ModSelectionScreen:onClickBack()
	if self.lastFilterValue == nil or self.lastFilterValue == "" then
		return ModSelectionScreen:superClass().onClickBack(self)
	end
	self:filter("")
	return true
end

-- Local values: unresolved, mods, availableUpdateModIds, scriptModsSelected, _, modItem, modId, modItem, _, modId, startGame, skipDialog, showIgnoreModUpdatesDialog, startGameWithScriptMods, modsToActivate, modIdsToDownload, hasUnavailableMods, dependencyLines, _, item, listText, title, deps, callback, callback, dependencyLines, _, item, listText, title, deps
function ModSelectionScreen:onClickOk()
	local v47_ = self:verifyDependencies()
	if #v47_ == 0 then
		local v_u_48_ = {}
		local v_u_49_ = {}
		local v50_ = false
		for _, v51_ in pairs(self.selectedMods) do
			table.insert(v_u_48_, v51_)
			local v52_ = self.updatableMods[v51_]
			if v52_ ~= nil then
				table.addElement(v_u_49_, v52_)
			end
			v50_ = v51_.hasScripts
		end
		for v53_, _ in pairs(self.blockedMods) do
			local v54_ = self.updatableMods[v53_]
			if v54_ ~= nil then
				table.insert(v_u_49_, v54_)
			end
		end
		local function v_u_57_()
			-- upvalues: (copy) self, (copy) v_u_48_
			local v55_ = g_modManager:getModByName(self.mapModName)
			if v55_ == nil or not self.blockedMods[v55_] then
				self.missionDynamicInfo.mods = v_u_48_
				local v56_ = ModSelectionScreen
				if #self.availableMods == 0 then
					v56_ = nil
				end
				g_careerScreen:startGame(self.missionInfo, self.missionDynamicInfo, v56_)
			else
				InfoDialog.show(g_i18n:getText("ui_modMapBlocked"), nil, nil, DialogElement.TYPE_WARNING)
			end
		end
		local v_u_58_ = StartParams.getIsSet("autoStart") or StartParams.getIsSet("skipModUpdateDialog")
		local function v_u_64_()
			-- upvalues: (copy) v_u_49_, (copy) v_u_58_, (copy) v_u_57_, (copy) self
			if g_dedicatedServer == nil and (#v_u_49_ > 0 and not v_u_58_) then
				local function v60_(p59_)
					-- upvalues: (ref) v_u_57_, (ref) self, (ref) v_u_49_
					if p59_ == MultiOptionDialog.ACTION.ACCEPT then
						v_u_57_()
						return
					elseif p59_ == MultiOptionDialog.ACTION.CANCEL then
						self:installOrUpdateMods(v_u_49_)
					end
				end
				local v61_ = g_i18n:getText("button_start")
				local v62_ = g_i18n:getText("button_back")
				local v63_ = g_i18n:getText("button_modHubUpdate")
				MultiOptionDialog.show(v60_, nil, g_i18n:getText("ui_mod_ignoreAvailableUpdates"), nil, v61_, v62_, nil, v63_, DialogElement.TYPE_WARNING)
			else
				v_u_57_()
			end
		end
		if GS_IS_MSSTORE_VERSION and (self.missionInfo.initialPlatformId == PlatformId.XBOX_SERIES and v50_) then
			YesNoDialog.show(function(p65_)
				-- upvalues: (copy) self, (copy) v_u_64_
				if p65_ then
					self.missionInfo.initialPlatformId = getPlatformId()
					v_u_64_()
				end
			end, nil, g_i18n:getText("ui_savegameCrossPlatformWarning"), nil, nil, nil, DialogElement.TYPE_WARNING)
		else
			v_u_64_()
		end
	else
		if g_dedicatedServer == nil then
			local v66_ = {}
			local v_u_67_ = {}
			local v_u_68_ = {}
			local v69_ = false
			for _, v70_ in ipairs(v47_) do
				if v66_[v70_.mod.title] == nil then
					v66_[v70_.mod.title] = v70_.dependencyTitle
				else
					v66_[v70_.mod.title] = v66_[v70_.mod.title] .. ", " .. v70_.dependencyTitle
				end
				if v70_.dependencyModId == nil then
					if v70_.canActivate then
						local v71_ = v70_.dependencyMod
						table.insert(v_u_67_, v71_)
					else
						v69_ = true
					end
				else
					local v72_ = v70_.dependencyModId
					table.insert(v_u_68_, v72_)
				end
			end
			local v73_ = nil
			for v74_, v75_ in pairs(v66_) do
				if v73_ == nil then
					v73_ = string.format(g_i18n:getText("ui_mod_required"), v74_, v75_)
				else
					v73_ = v73_ .. " " .. string.format(g_i18n:getText("ui_mod_required"), v74_, v75_)
				end
			end
			if #v_u_67_ > 0 then
				YesNoDialog.show(function(p76_)
					-- upvalues: (copy) v_u_67_, (copy) self
					if p76_ then
						for _, v77_ in ipairs(v_u_67_) do
							self:setItemState(v77_, true)
						end
					end
				end, nil, v73_ .. "\n\n" .. g_i18n:getText("ui_mod_selectAllRequired"), nil, nil, nil, DialogElement.TYPE_QUESTION)
				return
			end
			if #v_u_68_ > 0 then
				YesNoDialog.show(function(p78_)
					-- upvalues: (copy) self, (copy) v_u_68_
					if p78_ then
						self:installOrUpdateMods(v_u_68_)
					end
				end, nil, v73_ .. "\n\n" .. g_i18n:getText("ui_mod_downloadAllRequired"), nil, nil, nil, DialogElement.TYPE_WARNING)
				return
			end
			if v69_ then
				InfoDialog.show(v73_, nil, nil, DialogElement.TYPE_WARNING)
				return
			end
		else
			local v79_ = {}
			for _, v80_ in ipairs(v47_) do
				if v79_[v80_.mod.title] == nil then
					v79_[v80_.mod.title] = v80_.dependencyTitle
				else
					v79_[v80_.mod.title] = v79_[v80_.mod.title] .. ", " .. v80_.dependencyTitle
				end
			end
			local v81_ = nil
			for v82_, v83_ in pairs(v79_) do
				if v81_ == nil then
					v81_ = "\'" .. v82_ .. "\' wants " .. v83_
				else
					v81_ = v81_ .. ";  \'" .. v82_ .. "\' wants " .. v83_
				end
			end
			Logging.error("Could not start dedicated server with current mod setup because some dependencies are missing: " .. v81_)
			if g_dedicatedServer ~= nil then
				doExit()
			end
		end
		return
	end
end

function ModSelectionScreen:onDoubleClick(index)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self:selectCurrentMod()
end

-- Local values: selected, _, mod
function ModSelectionScreen:toggleCrossplay()
	self.crossplayOnly = not self.crossplayOnly
	local v86_ = self.selectedMods
	self:loadAvailableMods()
	for _, v87_ in ipairs(self.availableMods) do
		if v86_[v87_] then
			self:setItemState(v87_, true)
		end
	end
	self.buttonToggleCrossplay:setText(self.crossplayOnly and g_i18n:getText("button_modHubShowAll") or g_i18n:getText("button_modHubShowCrossplay"))
end

-- Local values: _, modItem, _, modName, modItem
function ModSelectionScreen:update(dt)
	ModSelectionScreen:superClass().update(self, dt)
	if g_dedicatedServer == nil then
		if Profiler.IS_INITIALIZED then
			self:onClickOk()
		end
		if g_startMissionInfo.isMultiplayer then
			Platform.verifyMultiplayerAvailabilityInMenu()
		end
	else
		for _, v90_ in pairs(self.selectedMods) do
			self:setItemState(v90_, false)
		end
		for _, v91_ in pairs(g_dedicatedServer.mods) do
			local v92_ = g_modManager:getModByName(v91_)
			if v92_ ~= nil then
				if self:shouldShowModInList(v92_) then
					self:setItemState(v92_, true)
				else
					Logging.error("Mod \'%s\' is not available for current dedicated server setup", v92_.title)
				end
			end
		end
		self:onClickOk()
	end
end

-- Local values: showMod, mapId, _, modName, modId
function ModSelectionScreen:shouldShowModInList(mod)
	local v95_ = (self.missionDynamicInfo.isMultiplayer and true or false) and mod.isMultiplayerSupported
	if v95_ then
		v95_ = mod.fileHash ~= nil
	end
	if v95_ and (not self.missionDynamicInfo.isMultiplayer and mod.multiplayerOnly) then
		v95_ = false
	end
	if not mod.isSelectable then
		v95_ = false
	end
	if v95_ and (not mod.isDLC and mod.modName ~= self.mapModName) then
		for v96_, _ in pairs(g_mapManager.idToMap) do
			local v97_ = g_mapManager:getModNameFromMapId(v96_)
			if v97_ ~= nil and v97_ == mod.modName then
				v95_ = false
				break
			end
		end
	end
	if not mod.isDLC and (self.crossplayOnly and (self.missionDynamicInfo.isMultiplayer and v95_)) then
		if mod.hasScripts and not mod.isInternalScriptMod then
			return false
		end
		local v98_ = getModIdByFilename(mod.modName)
		if v98_ == 0 or getModMetaAttributeString(v98_, "hash") ~= mod.fileHash then
			v95_ = false
		end
	end
	return v95_
end

-- Local values: _, activeMod
function ModSelectionScreen:isModActivated(name)
	for _, v101_ in pairs(self.selectedMods) do
		if v101_.modName == name then
			return true
		end
	end
	return false
end

-- Local values: unresolved, _, modItem, _, depName, depMod, modId, modInfo
function ModSelectionScreen:verifyDependencies()
	local v103_ = {}
	for _, v104_ in pairs(self.selectedMods) do
		if v104_.dependencies ~= nil and #v104_.dependencies > 0 then
			for _, v105_ in ipairs(v104_.dependencies) do
				if not self:isModActivated(v105_) then
					local v106_ = g_modManager:getModByName(v105_)
					if v106_ == nil then
						local v107_ = getModIdByFilename(v105_)
						if v107_ == 0 then
							local v108_ = {
								["mod"] = v104_,
								["dependencyTitle"] = "\'" .. v105_ .. ".zip\'"
							}
							table.insert(v103_, v108_)
						else
							local v109_ = {
								["mod"] = v104_,
								["dependencyTitle"] = "\'" .. g_modHubController:getModInfo(v107_):getName() .. "\'",
								["dependencyModId"] = v107_
							}
							table.insert(v103_, v109_)
						end
					else
						local v110_ = {
							["mod"] = v104_,
							["dependencyTitle"] = "\'" .. v106_.title .. "\'",
							["dependencyMod"] = v106_,
							["canActivate"] = true
						}
						table.insert(v103_, v110_)
					end
				end
			end
		end
	end
	return v103_
end

-- Local values: outdatedMods, isModDownloadManagerLoaded, showBlockedError, i, filename, versionStr, minModDesc, maxModDesc, versionParts, i, part, mods, _, mod, blockedVersion, versionParts, i, part, modId, modInfo, isUpdate, isExternal, isDirectory, _, mod
function ModSelectionScreen:loadAvailableMods()
	self.indexedSearch:clear()
	self.availableMods = {}
	self.blockedMods = {}
	self.updatableMods = {}
	self.numUpdatableMods = 0
	self.selectedMods = {}
	local v112_ = modDownloadManagerLoaded()
	local v113_ = self.showBlockedError
	local v114_
	if v112_ then
		v114_ = {}
		for v115_ = 0, getNumOfBlockedMods() - 1 do
			local v116_, v117_, v118_, v119_ = getBlockedMod(v115_)
			if not MathUtil.getIsOutOfBounds(g_maxModDescVersion, v118_, v119_) then
				local v120_ = string.split(v117_, ".")
				for v121_, v122_ in ipairs(v120_) do
					local v123_ = string.match
					v120_[v121_] = tonumber(v123_(v122_, "%d+")) or 0
				end
				v114_[v116_] = v120_
			end
		end
		self.showBlockedError = false
	else
		v114_ = g_outdatedMods
	end
	local v124_ = g_modManager:getMods()
	for _, v125_ in ipairs(v124_) do
		if self:shouldShowModInList(v125_) then
			local v126_ = v114_[v125_.modName]
			if v126_ ~= nil then
				local v127_ = string.split(v125_.version, ".")
				for v128_, v129_ in ipairs(v127_) do
					local v130_ = string.match
					v127_[v128_] = tonumber(v130_(v129_, "%d+")) or 0
				end
				if Utils.compareVersions(v127_, v126_) < 1 then
					self.blockedMods[v125_] = true
					if v113_ then
						printError("Error: Mod \'" .. v125_.modName .. "\' in version \'" .. v125_.version .. "\' and lower is outdated and not working properly. Please update the mod to resolve this!")
					end
				end
			end
			if v112_ then
				local v131_ = getModIdByFilename(v125_.modName)
				if v131_ ~= 0 then
					local v132_ = g_modHubController:getModInfo(v131_)
					local v133_ = v132_:getIsUpdate()
					local v134_ = v132_:getIsExternal()
					local v135_ = v125_.isDirectory
					if v132_ ~= nil and (v133_ and (not v134_ and (not v135_ and (Platform.isPC or not v132_:getIsDLC())))) then
						self.updatableMods[v125_] = v131_
						self.numUpdatableMods = self.numUpdatableMods + 1
					end
				end
			end
			local v136_ = self.availableMods
			table.insert(v136_, v125_)
			self.indexedSearch:addDocument({
				["title"] = v125_.title,
				["modName"] = string.gsub(v125_.modName, "FS25_", ""),
				["author"] = v125_.author
			}, v125_)
		end
	end
	self.indexedSearch:build()
	self.numAddedModsBesidesMap = 0
	self.numAddedMods = 0
	self:showMods(nil)
	for _, v137_ in ipairs(self.availableMods) do
		self:setItemState(v137_, false)
	end
end

-- Local values: changed, isSearching, success, title
function ModSelectionScreen:filter(name)
	local v140_ = string.isNilOrWhitespace(name) and "" or name
	if self.lastFilterValue ~= v140_ then
		local v_u_141_ = true
		if self.indexedSearch:search(v140_, function(p142_)
			-- upvalues: (ref) v_u_141_, (copy) self
			MessageDialog.hide()
			v_u_141_ = false
			local v143_
			if p142_ == nil then
				v143_ = nil
			else
				v143_ = {}
				for _, v144_ in ipairs(p142_) do
					v143_[v144_.ref] = v144_.score
				end
			end
			self:showMods(v143_)
		end) then
			if v_u_141_ then
				MessageDialog.show(g_i18n:getText("ui_storeSearching"))
			end
		else
			self:showMods(nil)
		end
		self.lastFilterValue = v140_
		local v145_ = self.defaultTitle
		if self.lastFilterValue ~= "" then
			v145_ = string.format("%s (\'%s\')", v145_, self.lastFilterValue)
		end
		self.title:setText(v145_)
	end
end

-- Local values: updateables, blocked, others, numMods, _, mod, sortMods, hasUpdatables
function ModSelectionScreen:showMods(mods)
	table.clear(self.sectionToData)
	local v148_ = {}
	local v149_ = {}
	local v150_ = 0
	local v151_ = {}
	for _, v152_ in ipairs(self.availableMods) do
		if mods == nil or mods[v152_] then
			if self.updatableMods[v152_] then
				table.insert(v148_, v152_)
			elseif self.blockedMods[v152_] then
				table.insert(v149_, v152_)
			else
				table.insert(v151_, v152_)
			end
			v150_ = v150_ + 1
		end
	end
	local function v161_(p153_, p154_)
		-- upvalues: (copy) mods, (copy) self
		local v155_ = p153_.isDLC or p153_.isFreeDLC
		local v156_ = p154_.isDLC or p154_.isFreeDLC
		if mods ~= nil then
			local v157_ = mods[p153_]
			local v158_ = mods[p154_]
			if v157_ and v158_ then
				if v158_ < v157_ then
					return true
				end
				if v157_ < v158_ then
					return false
				end
			end
		end
		if v155_ and not v156_ then
			return true
		elseif v155_ or not v156_ then
			local v159_ = self.blockedMods[p153_]
			local v160_ = self.blockedMods[p154_]
			if v159_ or not v160_ then
				if v159_ and not v160_ then
					return false
				elseif p153_.author == ModSelectionScreen.AUTHOR_NAME_GIANTS and p154_.author ~= ModSelectionScreen.AUTHOR_NAME_GIANTS then
					return true
				elseif p154_.author == ModSelectionScreen.AUTHOR_NAME_GIANTS and p153_.author ~= ModSelectionScreen.AUTHOR_NAME_GIANTS then
					return false
				else
					return p153_.title < p154_.title
				end
			else
				return true
			end
		else
			return false
		end
	end
	table.sort(v148_, v161_)
	table.sort(v149_, v161_)
	table.sort(v151_, v161_)
	if #v148_ > 0 then
		local v162_ = self.sectionToData
		local v163_ = {
			["title"] = g_i18n:getText("ui_modsUpdatesAvailable"),
			["mods"] = v148_
		}
		table.insert(v162_, v163_)
	end
	if #v149_ > 0 then
		local v164_ = self.sectionToData
		local v165_ = {
			["title"] = g_i18n:getText("ui_modsBlocked"),
			["mods"] = v149_
		}
		table.insert(v164_, v165_)
	end
	local v166_ = self.sectionToData
	local v167_ = {
		["title"] = g_i18n:getText("ui_modsInstalled"),
		["mods"] = v151_
	}
	table.insert(v166_, v167_)
	self.modList:reloadData()
	self.buttonSelect:setDisabled(v150_ == 0)
	self.buttonSelectAll:setDisabled(v150_ == 0)
	self.noModsDLCsElement:setVisible(v150_ == 0)
end

-- Local values: isNotUsedMap, section, index, cell
function ModSelectionScreen:setItemState(item, isSelected)
	if item ~= nil then
		if isSelected and self.blockedMods[item] then
			return false
		end
		if item.uniqueType ~= nil then
			if self.uniqueTypesInUse[item.uniqueType] == nil then
				if isSelected then
					self.uniqueTypesInUse[item.uniqueType] = item
				end
			else
				if isSelected then
					return false
				end
				self.uniqueTypesInUse[item.uniqueType] = nil
			end
		end
		local v171_ = self.mapModName == nil and true or item.modName ~= self.mapModName
		if isSelected then
			if self.selectedMods[item] == nil then
				if v171_ then
					self.numAddedModsBesidesMap = self.numAddedModsBesidesMap + 1
				end
				self.numAddedMods = self.numAddedMods + 1
			end
			self.selectedMods[item] = item
		elseif v171_ then
			if self.selectedMods[item] ~= nil then
				self.numAddedModsBesidesMap = self.numAddedModsBesidesMap - 1
				self.numAddedMods = self.numAddedMods - 1
			end
			self.selectedMods[item] = nil
		end
		if not v171_ then
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
		local v172_, v173_ = self:getSectionAndIndexForItem(item)
		if v173_ ~= nil then
			local v174_ = self.modList:getElementAtSectionIndex(v172_, v173_)
			if v174_ ~= nil and not v174_.isEmptyCell then
				if isSelected then
					v174_:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE_SELECTED)
					local v175_ = v174_:getAttribute("title")
					local v176_ = ModSelectionScreen.COLOR_MAIN_DARK
					v175_:setTextColor(unpack(v176_))
					local v177_ = v174_:getAttribute("version")
					local v178_ = ModSelectionScreen.COLOR_MAIN_DARK
					v177_:setTextColor(unpack(v178_))
				else
					v174_:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE)
					local v179_ = v174_:getAttribute("title")
					local v180_ = ModSelectionScreen.COLOR_MAIN_LIGHT
					v179_:setTextColor(unpack(v180_))
					local v181_ = v174_:getAttribute("version")
					local v182_ = ModSelectionScreen.COLOR_MAIN_LIGHT
					v181_:setTextColor(unpack(v182_))
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

-- Local values: section, data, k, mod
function ModSelectionScreen:getSectionAndIndexForItem(item)
	for v185_, v186_ in ipairs(self.sectionToData) do
		for v187_, v188_ in ipairs(v186_.mods) do
			if v188_ == item then
				return v185_, v187_
			end
		end
	end
	return nil, nil
end

function ModSelectionScreen:getIsModSelected(item)
	return self.selectedMods[item] ~= nil
end

-- Local values: sectionIndex, sections, index
function ModSelectionScreen:getSelectedMod()
	local v192_ = self.modList.selectedSectionIndex
	local v193_ = self.sectionToData[v192_]
	if v193_ == nil then
		return nil
	end
	local v194_ = self.modList.selectedIndex
	return v193_.mods[v194_]
end

-- Local values: canSelectAll, hasMods
function ModSelectionScreen:updateSelectButton()
	if self.selectedMods[self:getSelectedMod()] == nil then
		self.buttonSelect:setText(g_i18n:getText("button_select"))
	else
		self.buttonSelect:setText(g_i18n:getText("button_deselect"))
	end
	local v196_, v197_ = self:getCanSelectAll()
	if v197_ then
		if v196_ then
			self.buttonSelectAll:setText(g_i18n:getText("button_selectAll"))
			return
		end
		self.buttonSelectAll:setText(g_i18n:getText("button_deselectAll"))
	end
end

-- Local values: canSelectAll, hasMods, section, data, k, mod
function ModSelectionScreen:getCanSelectAll()
	local v199_ = false
	local v200_ = false
	for _, v201_ in ipairs(self.sectionToData) do
		for _, v202_ in ipairs(v201_.mods) do
			if self.blockedMods[v202_] == nil then
				v200_ = true
				if self.selectedMods[v202_] == nil then
					v199_ = true
					break
				end
			end
		end
	end
	return v199_, v200_
end

function ModSelectionScreen:getNumberOfSections(list)
	return #self.sectionToData
end

-- Local values: data
function ModSelectionScreen:getTitleForSectionHeader(list, section)
	return self.sectionToData[section].title
end

-- Local values: data
function ModSelectionScreen:getNumberOfItemsInSection(list, section)
	return #self.sectionToData[section].mods
end

-- Local values: data, mods, mod, isSelected, isBlocked, hasUpdate, markerElement, markerUpdate, markerBlocked
function ModSelectionScreen:populateCellForItemInSection(list, section, index, cell)
	local v212_ = self.sectionToData[section].mods[index]
	local v213_ = self.selectedMods[v212_]
	local v214_ = self.blockedMods[v212_]
	local v215_ = self.updatableMods[v212_]
	if v213_ then
		cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE_SELECTED)
		local v216_ = cell:getAttribute("title")
		local v217_ = ModSelectionScreen.COLOR_MAIN_DARK
		v216_:setTextColor(unpack(v217_))
		local v218_ = cell:getAttribute("version")
		local v219_ = ModSelectionScreen.COLOR_MAIN_DARK
		v218_:setTextColor(unpack(v219_))
	else
		cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE)
		local v220_ = cell:getAttribute("title")
		local v221_ = ModSelectionScreen.COLOR_MAIN_LIGHT
		v220_:setTextColor(unpack(v221_))
		local v222_ = cell:getAttribute("version")
		local v223_ = ModSelectionScreen.COLOR_MAIN_LIGHT
		v222_:setTextColor(unpack(v223_))
	end
	local v224_ = cell:getAttribute("markerBox")
	if v224_ ~= nil then
		local v225_ = v224_:getDescendantByName("markerUpdate")
		if v225_ ~= nil then
			v225_:setVisible(v215_)
		end
		local v226_ = v224_:getDescendantByName("markerBlocked")
		if v226_ ~= nil then
			v226_:setVisible(v214_)
		end
		cell:getAttribute("markerBox"):invalidateLayout()
	end
	if v214_ then
		cell:getAttribute("title"):setTextColor(0.1, 0.1, 0.1, 1)
		cell:getAttribute("version"):setTextColor(0.1, 0.1, 0.1, 1)
		cell:getAttribute("icon"):setImageColor(nil, 0.2, 0.2, 0.2, 1)
	else
		cell:getAttribute("icon"):setImageColor(1, 1, 1, 1)
	end
	cell:getAttribute("title"):setText(v212_.title)
	cell:getAttribute("version"):setText(g_i18n:getText("ui_modVersion") .. " " .. v212_.version)
	cell:getAttribute("dlcTag"):setVisible(v212_.isDLC or v212_.isFreeDLC)
	cell:getAttribute("icon"):setImageFilename(v212_.iconFilename)
	self.overlayCache:addOverlay(v212_.iconFilename)
end

function ModSelectionScreen:onListSelectionChanged(list, section, index)
	self:updateSelectButton()
end

-- Local values: dialogPrompt, imePrompt, confirmText
function ModSelectionScreen:onSearch()
	local v229_ = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	local v230_ = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	local v231_ = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	TextInputDialog.show(self.onSearchFinished, self, self.lastFilterValue, v229_, v230_, 40, v231_, nil, nil, false)
end

function ModSelectionScreen:onSearchFinished(text, ok)
	if ok then
		self:filter(text)
	else
		self:filter("")
	end
end

-- Local values: finishCallback
function ModSelectionScreen:installOrUpdateMods(modIds)
	g_modHubController:installOrUpdateMods(modIds, function(p236_)
		g_masterServerConnection:disconnectFromMasterServer()
		g_connectionManager:shutdownAll()
		g_modHubScreen:openDownloads()
		if p236_ > 0 then
			InfoDialog.show(g_i18n:getText("modHub_installFailed"))
		end
	end)
end
