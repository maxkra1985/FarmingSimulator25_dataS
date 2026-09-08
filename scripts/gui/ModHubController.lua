-- Local values: ModHubController_mt, setModHubRatingLocal, getModHubRatingLocal
ModHubController = {}
local ModHubController_mt = Class(ModHubController)
ModHubController.CATEGORY_ID_CONTEST = 8
ModHubController.CATEGORY_ID_DOWNLOAD = 2
ModHubController.CATEGORY_ID_UPDATE = 3
ModHubController.HIDDEN_CATEGORY = "hidden"
local setModHubRatingLocal = setModHubRating
local getModHubRatingLocal = getModHubRating
function ModHubController.new()
	-- upvalues: (copy) ModHubController_mt
	local v4_ = ModHubController_mt
	local v5_ = setmetatable({}, v4_)
	v5_.isInitialized = false
	v5_.categories = {}
	v5_.modIdToInfo = {}
	v5_.categoryTypeMapping = {}
	v5_.categoryNameMapping = {}
	v5_.hasChanges = false
	v5_.hasTriggedUUIDInEngine = false
	v5_.priceMapping = {
		["en"] = "DLCPriceEUR",
		["de"] = "DLCPriceEUR",
		["pl"] = "DLCPriceEUR",
		["cz"] = "DLCPriceEUR",
		["fr"] = "DLCPriceEUR",
		["es"] = "DLCPriceEUR",
		["it"] = "DLCPriceEUR",
		["pt"] = "DLCPriceEUR",
		["hu"] = "DLCPriceEUR",
		["nl"] = "DLCPriceEUR",
		["da"] = "DLCPriceEUR",
		["fi"] = "DLCPriceEUR",
		["no"] = "DLCPriceEUR",
		["sv"] = "DLCPriceEUR",
		["jp"] = "DLCPriceUSD",
		["ru"] = "DLCPriceUSD",
		["cs"] = "DLCPriceUSD",
		["ct"] = "DLCPriceUSD",
		["br"] = "DLCPriceUSD",
		["tr"] = "DLCPriceUSD",
		["ro"] = "DLCPriceUSD",
		["kr"] = "DLCPriceUSD",
		["ea"] = "DLCPriceUSD",
		["fc"] = "DLCPriceUSD",
		["uk"] = "DLCPriceUSD",
		["vi"] = "DLCPriceUSD",
		["id"] = "DLCPriceUSD"
	}
	for v6_ = 0, getNumOfLanguages() - 1 do
		local v7_ = getLanguageCode(v6_)
		if v5_.priceMapping[v7_] == nil then
			Logging.devError("ModHubController: Missing price mapping for \'%s\'", v7_)
			v5_.priceMapping[g_languageShort] = "DLCPriceUSD"
		end
	end
	g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, v5_.userProfileChanged, v5_)
	v5_.categoryTypeNameMapping = {}
	v5_.localCategories = {}
	v5_.categoryTypes = {}
	v5_.localCategoriesSorted = {}
	v5_:loadCategoriesFromXML()
	return v5_
end

-- Local values: xmlFile, i, key, name, title, key, name, categoryType, imageFilename, localCategory
function ModHubController:loadCategoriesFromXML()
	local v9_ = loadXMLFile("configFile", "dataS/modHub.xml")
	local v10_ = 0
	while true do
		local v11_ = string.format("modHub.categories.types.type(%d)", v10_)
		if not hasXMLProperty(v9_, v11_) then
			break
		end
		local v12_ = getXMLString(v9_, v11_ .. "#name")
		local v13_ = getXMLString(v9_, v11_ .. "#title")
		if v13_ ~= nil then
			v13_ = g_i18n:convertText(v13_)
		end
		self.categoryTypeNameMapping[v12_] = v13_
		v10_ = v10_ + 1
	end
	local v14_ = 0
	while true do
		local v15_ = string.format("modHub.categories.category(%d)", v14_)
		if not hasXMLProperty(v9_, v15_) then
			break
		end
		local v16_ = getXMLString(v9_, v15_ .. "#name")
		local v17_ = getXMLString(v9_, v15_ .. "#type") or v16_
		local v18_ = getXMLString(v9_, v15_ .. "#imageFilename")
		if v16_ ~= nil and v18_ ~= nil then
			local v19_ = {
				["name"] = v16_,
				["categoryType"] = v17_,
				["imageFilename"] = v18_,
				["isTab"] = Utils.getNoNil(getXMLBool(v9_, v15_ .. "#isTab"), false),
				["isHidden"] = Utils.getNoNil(getXMLBool(v9_, v15_ .. "#isHidden"), false),
				["title"] = getXMLString(v9_, v15_ .. "#title")
			}
			self.localCategories[v16_] = v19_
			if v19_.isTab or v19_.isHidden then
				v17_ = ModHubController.HIDDEN_CATEGORY
			end
			if self.localCategoriesSorted[v17_] == nil then
				self.localCategoriesSorted[v17_] = {}
				local v20_ = self.categoryTypes
				table.insert(v20_, v17_)
			end
			local v21_ = self.localCategoriesSorted[v17_]
			table.insert(v21_, v16_)
		end
		v14_ = v14_ + 1
	end
	delete(v9_)
end

function ModHubController:reset()
	self.isInitialized = false
	self.categories = {}
	self.modIdToInfo = {}
	self.categoryNameMapping = {}
	self.categoryTypeMapping = {}
end

function ModHubController:delete()
	g_messageCenter:unsubscribeAll(self)
end

function ModHubController:startModification()
	self.hasChanges = false
end

function ModHubController:endModification()
	if self.hasChanges then
		reloadDlcsAndMods()
	end
	self.hasChanges = false
end

-- Local values: numCategories, i, typeIndex, categoryType, typeTable, _, categoryName, categoryInfo
function ModHubController:load()
	if not self.isInitialized then
		local v27_ = getNumModCategories()
		if g_isDevelopmentVersion then
			ModHubController.CATEGORY_ID_TESTING = v27_ + 1
			v27_ = v27_ + 1
		end
		for v28_ = 1, v27_ do
			self:loadCategory(v28_)
		end
		for v29_, v30_ in ipairs(self.categoryTypes) do
			local v31_ = {}
			for _, v32_ in ipairs(self.localCategoriesSorted[v30_]) do
				local v33_ = self.categoryNameMapping[v32_]
				if v33_ ~= nil then
					table.insert(v31_, v33_)
				end
			end
			self.categoryTypeMapping[v30_] = v29_
			local v34_ = self.categories
			table.insert(v34_, v31_)
		end
		self.isInitialized = true
	end
end

-- Local values: isTestingCategory, categoryName, localCategory, iconFilename, isHidden, title, numNewItems, numAvailableUpdates, numConflictedItems, categoryInfo
function ModHubController:loadCategory(categoryId)
	local v37_ = g_isDevelopmentVersion
	if v37_ then
		v37_ = categoryId == ModHubController.CATEGORY_ID_TESTING
	end
	if categoryId ~= ModHubController.CATEGORY_ID_CONTEST or not GS_IS_CONSOLE_VERSION and getNumOfMods(categoryId - 1) > 0 or v37_ then
		local v38_ = v37_ and "testing" or getModCategoryName(categoryId - 1)
		local v39_ = self.localCategories[v38_]
		if v39_ ~= nil then
			local v40_ = v39_.imageFilename
			local v41_ = v39_.isTab or v39_.isHidden
			local v42_
			if v39_.title == nil then
				v42_ = nil
			else
				v42_ = g_i18n:convertText(v39_.title)
			end
			if v42_ == nil then
				v42_ = g_i18n:getText("modHub_" .. v38_)
			end
			local v43_, v44_, v45_ = self:getCategoryData(categoryId)
			local v46_ = self.categoryNameMapping[v38_]
			if v46_ == nil then
				v46_ = ModCategoryInfo.new(categoryId, v42_, v40_, v38_, v41_)
				self.categoryNameMapping[v38_] = v46_
			else
				v46_:updateInfo(categoryId, v42_, v40_, v38_, v41_)
			end
			v46_:setNumAvailableUpdates(v44_)
			v46_:setNumNewItems(v43_)
			v46_:setNumConflictedItems(v45_)
			return
		end
		Logging.warning("Could not find modhub category %s in modHub.xml", v38_)
	end
end

function ModHubController:reload()
	self.categoryNameMapping = {}
	self.categories = {}
	self.isInitialized = false
	self:load()
end

function ModHubController:getCategories()
	return self.categories
end

-- Local values: visibleTypes, typeIndex, categoryType, _, categoryName, category
function ModHubController:getCategoryTypes()
	local v50_ = {}
	for _, v51_ in pairs(self.categoryTypes) do
		if v51_ ~= ModHubController.HIDDEN_CATEGORY then
			for _, v52_ in pairs(self.localCategoriesSorted[v51_]) do
				local v53_ = self.categoryNameMapping[v52_]
				if v53_ ~= nil and (not v53_.isHidden and v53_:getNumMods() > 0) then
					table.insert(v50_, v51_)
					break
				end
			end
		end
	end
	return v50_
end

-- Local values: list, typeIndex, categoryType, typeList, _, categoryName, category
function ModHubController:getVisibleCategories()
	local v55_ = {}
	for _, v56_ in pairs(self.categoryTypes) do
		if v56_ ~= ModHubController.HIDDEN_CATEGORY then
			local v57_ = {}
			for _, v58_ in pairs(self.localCategoriesSorted[v56_]) do
				local v59_ = self.categoryNameMapping[v58_]
				if v59_ ~= nil and (not v59_.isHidden and v59_:getNumMods() > 0) then
					table.insert(v57_, v59_)
				end
			end
			if #v57_ > 0 then
				table.insert(v55_, v57_)
			end
		end
	end
	return v55_
end

-- Local values: numOfMods, numNewItems, numUpdates, numConflicts, i, modId, modInfo
function ModHubController:getCategoryData(categoryId)
	if categoryId == ModHubController.CATEGORY_ID_TESTING then
		return 0, 0, 0
	end
	local v62_ = categoryId <= 0 and 0 or getNumOfMods(categoryId - 1)
	local v63_ = 0
	local v64_ = 0
	local v65_ = 0
	if categoryId == ModHubController.CATEGORY_ID_DOWNLOAD then
		return v62_, v64_, v65_
	end
	if categoryId == ModHubController.CATEGORY_ID_UPDATE then
		return v63_, v62_, v65_
	end
	if v62_ > 0 then
		for v66_ = 0, v62_ - 1 do
			local v67_ = self:getModInfo((getModId(categoryId - 1, v66_)))
			if not v67_:getIsDLC() or (v67_:getPriceString():len() > 1 or v67_:getIsInstalled()) then
				v64_ = v64_ + v67_:getNumUpdates()
				v65_ = v65_ + v67_:getNumConflicts()
				v63_ = v63_ + v67_:getNumNew()
			end
		end
	end
	return v63_, v64_, v65_
end

-- Local values: isTestingCategory, testingMods, _, modInfo, updateMods, numOfMods, i, modId, modInfo, mods, numOfMods, i, modId, modInfo
function ModHubController:getModsByCategory(categoryId, visibleOnly)
	if g_isDevelopmentVersion and categoryId == ModHubController.CATEGORY_ID_TESTING then
		local v71_ = {}
		for _, v72_ in pairs(self.modIdToInfo) do
			if v72_:getIsTesting() then
				table.insert(v71_, v72_)
			end
		end
		table.sort(v71_, function(p73_, p74_)
			return p73_:getName() < p74_:getName()
		end)
		return v71_
	elseif categoryId == ModHubController.CATEGORY_ID_UPDATE then
		local v75_ = {}
		local v76_ = getNumOfMods(categoryId - 1)
		if v76_ > 0 then
			for v77_ = 0, v76_ - 1 do
				local v78_ = getModId(categoryId - 1, v77_)
				local v79_ = self:getModInfo(v78_)
				if v78_ < 0 then
					Logging.devError("external/non-modhub mod included in \'UPDATE\' category: id:%d %s %s size:%d", v79_:getId(), v79_:getName(), v79_:getFilename(), v79_:getFilesize())
				end
				table.insert(v75_, v79_)
			end
		end
		return v75_
	else
		local v80_ = {}
		local v81_ = getNumOfMods(categoryId - 1)
		if v81_ > 0 then
			for v82_ = 0, v81_ - 1 do
				local v83_ = self:getModInfo((getModId(categoryId - 1, v82_)))
				if not visibleOnly or (not v83_:getIsDLC() or (v83_:getPriceString():len() > 1 or v83_:getIsInstalled())) then
					table.insert(v80_, v83_)
				end
			end
		end
		return v80_
	end
end

function ModHubController:getCategory(name)
	return self.categoryNameMapping[name]
end

-- Local values: modInfo
function ModHubController:getModInfo(modId)
	local v88_ = self.modIdToInfo[modId]
	if v88_ == nil then
		if type(modId) ~= "number" then
			return nil
		end
		v88_ = ModInfo.new(modId, self:getPostFix(), self.priceMapping[g_languageShort])
		self.modIdToInfo[modId] = v88_
	end
	return v88_
end

-- Local values: dependendMods, i, dependendModId, modInfo
function ModHubController:getDependentMods(modId)
	local v91_ = {}
	for v92_ = 0, getModNumDependencies(modId) - 1 do
		local v93_ = self:getModInfo((getModDependency(modId, v92_)))
		table.insert(v91_, v93_)
	end
	return v91_
end

function ModHubController:getPostFix()
	return g_languageShort ~= "de" and g_languageShort ~= "fr" and "en" or g_languageShort
end

-- Local values: modInfo, dependendMods, totalFilesizeKb, _, dependendMod
function ModHubController:getTotalFilesizeKb(modId)
	local v96_ = self:getModInfo(modId)
	local v97_ = self:getDependentMods(modId)
	local v98_ = (v96_:getFilesize() + 1023) / 1024
	local v99_ = math.floor(v98_)
	for _, v100_ in ipairs(v97_) do
		if not v100_.isInstalled then
			local v101_ = (v100_:getFilesize() + 1023) / 1024
			v99_ = v99_ + math.floor(v101_)
		end
	end
	return v99_
end

function ModHubController:getFreeModSpaceKb()
	return getModFreeSpaceKb()
end

function ModHubController:getUsedModSpaceKb()
	return getModUsedSpaceKb()
end

function ModHubController:getTotalModSpaceKb()
	return getModFreeSpaceKb() + getModUsedSpaceKb()
end

function ModHubController:isContestEnabled()
	if not self.isInitialized then
		return false
	end
	if self.isContestEnabledStored == nil then
		self.isContestEnabledStored = getNumOfMods(ModHubController.CATEGORY_ID_CONTEST - 1) > 0
	end
	return self.isContestEnabledStored
end

-- Local values: success, dependendMods, numFailed, failedDependentMods, _, dependendMod, dependendSuccess
function ModHubController:install(modId)
	if installMod(modId) then
		local v105_ = self:getDependentMods(modId)
		local v106_ = {}
		for _, v107_ in ipairs(v105_) do
			if not (v107_.isInstalled or installMod(v107_.modId)) then
				table.insert(v106_, v107_)
			end
		end
		self.addedToDownloadCallback()
	else
		self.modInstallFailedCallback()
	end
	if self.discSpaceChangedCallback ~= nil then
		self.discSpaceChangedCallback()
	end
end

function ModHubController:setModInstallFailedCallback(callback, target)
	function self.modInstallFailedCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

function ModHubController:setDependentModInstallFailedCallback(callback, target)
	function self.dependendModInstallFailedCallback(p114_)
		-- upvalues: (copy) callback, (copy) target
		callback(target, p114_)
	end
end

function ModHubController:setAddedToDownloadCallback(callback, target)
	function self.addedToDownloadCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

-- Local values: numToGo, numFailed, failure, added, _, modId
function ModHubController:installOrUpdateMods(modIds, finishCallback)
	self:startModification()
	local v_u_121_ = #modIds
	local v_u_122_ = 0
	local function v123_()
		-- upvalues: (ref) v_u_121_, (ref) v_u_122_, (copy) finishCallback
		v_u_121_ = v_u_121_ - 1
		v_u_122_ = v_u_122_ + 1
		if v_u_121_ == 0 then
			finishCallback(v_u_122_)
		end
	end
	local function v124_()
		-- upvalues: (ref) v_u_121_, (copy) finishCallback, (ref) v_u_122_
		v_u_121_ = v_u_121_ - 1
		if v_u_121_ == 0 then
			finishCallback(v_u_122_)
		end
	end
	self:setModInstallFailedCallback(v123_, self)
	self:setDependentModInstallFailedCallback(v123_, self)
	self:setAddedToDownloadCallback(v124_, self)
	for _, v125_ in ipairs(modIds) do
		if getModMetaAttributeBool(v125_, "isUpdate") then
			self:update(v125_)
		else
			self:install(v125_)
		end
	end
end

-- Local values: success, numFailed, failedDependentMods, dependendMods, _, dependendMod, dependendSuccess
function ModHubController:update(modId)
	if updateMod(modId) then
		local v128_ = self:getDependentMods(modId)
		local v129_ = {}
		for _, v130_ in ipairs(v128_) do
			if v130_.isUpdate and not updateMod(modId) then
				table.insert(v129_, v130_)
			end
		end
		self.addedToDownloadCallback()
	else
		self.modInstallFailedCallback()
	end
	if self.discSpaceChangedCallback ~= nil then
		self.discSpaceChangedCallback()
	end
end

-- Local values: mod, hash, success
function ModHubController:uninstall(modId)
	local v133_ = self:getModInfo(modId).hash
	if uninstallMod(modId) then
		self.hasChanges = true
		local v134_ = g_modManager:getModByFileHash(v133_)
		if v134_ ~= nil then
			g_modManager:removeMod(v134_)
		end
		self.uninstalledCallback()
	else
		self.uninstallFailedCallback()
	end
	if self.discSpaceChangedCallback ~= nil then
		self.discSpaceChangedCallback()
	end
end

function ModHubController:setUninstallFailedCallback(callback, target)
	function self.uninstallFailedCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

function ModHubController:setUninstalledCallback(callback, target)
	function self.uninstalledCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

function ModHubController:setDiscSpaceChangedCallback(callback, target)
	function self.discSpaceChangedCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target, getModFreeSpaceKb(), (getModUsedSpaceKb()))
	end
end

-- Upvalues: setModHubRatingLocal
function ModHubController:vote(modId, value)
	-- upvalues: (copy) setModHubRatingLocal
	if not self.hasTriggedUUIDInEngine then
		getUniqueUserId()
		self.hasTriggedUUIDInEngine = true
	end
	setModHubRatingLocal(modId, value)
	if self.votedCallback ~= nil then
		self.votedCallback()
	end
end

function ModHubController:setVotedCallback(callback, target)
	function self.votedCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

-- Upvalues: getModHubRatingLocal
-- Local values: ratingValue, httpReturnCode
function ModHubController:getVote(modId)
	-- upvalues: (copy) getModHubRatingLocal
	if not self.hasTriggedUUIDInEngine then
		getUniqueUserId()
		self.hasTriggedUUIDInEngine = true
	end
	local v152_, v153_ = getModHubRatingLocal(modId)
	return v153_ == 0 and 0 or v152_
end

function ModHubController:setShowAllMods(showAll)
	setEnableBetaMods(showAll)
end

-- Local values: hits, _, categories, _, category, list, _, info, i, info
function ModHubController:searchMods(categoryId, text)
	local v158_ = string.lower(text)
	local v159_ = {}
	if categoryId == nil then
		for _, v160_ in ipairs(self.categories) do
			for _, v161_ in ipairs(v160_) do
				if self:isCategorySearchable(v161_) then
					v159_ = self:searchInCategory(v159_, v161_.id, v158_)
				end
			end
		end
	else
		self:searchInCategory(v159_, categoryId, v158_)
	end
	local v162_ = {}
	for _, v163_ in pairs(v159_) do
		table.insert(v162_, v163_)
	end
	table.sort(v162_, function(p164_, p165_)
		return p164_[2] > p165_[2]
	end)
	for v166_, v167_ in ipairs(v162_) do
		v162_[v166_] = v167_[1]
	end
	return v162_
end

function ModHubController:isCategorySearchable(category)
	return not category.isHidden or (category.name == "contest" and true or category.name == "dlc")
end

-- Local values: numOfMods, postFix, i, modId, hit, score, title, titleLower, sStart, sEnd, author, authorLower
function ModHubController:searchInCategory(list, categoryId, text)
	local v173_ = getNumOfMods(categoryId - 1)
	local v174_ = self:getPostFix()
	if v173_ > 0 then
		for v175_ = 0, v173_ - 1 do
			local v176_ = getModId(categoryId - 1, v175_)
			if list[v176_] == nil then
				local v177_ = false
				local v178_ = 0
				local v179_ = getModMetaAttributeString(v176_, "title_" .. v174_)
				local v180_ = utf8ToLower(v179_)
				local v181_, v182_ = string.find(v180_, text, nil, true)
				if v181_ == nil then
					local v183_ = getModMetaAttributeString(v176_, "author")
					local v184_ = utf8ToLower(v183_)
					local v185_, v186_ = string.find(v184_, text, nil, true)
					if v185_ ~= nil then
						v178_ = self:generateSearchScore(text, v183_, v185_, v186_)
						v177_ = true
					end
				else
					v178_ = self:generateSearchScore(text, v179_, v181_, v182_)
					v177_ = true
				end
				if v177_ then
					list[v176_] = { self:getModInfo(v176_), v178_ }
				end
			end
		end
	end
	return list
end

-- Local values: resultLength
function ModHubController:generateSearchScore(input, result, start, finish)
	local v190_ = utf8Strlen(result)
	return 0.8 * (utf8Strlen(input) / v190_) + 0.2 * (1 - start / v190_)
end

function ModHubController:userProfileChanged()
	self.hasTriggedUUIDInEngine = false
	self:updateRecommendationSystem()
end

-- Local values: usesHelpWindow, isLastUsedCharacterMale, playedMultiplayer, totalPlayedHours, startedGuidedTour, numTutorialsPlayed
function ModHubController:updateRecommendationSystem()
	local v192_ = g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)
	local v193_ = g_gameSettings:getValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE)
	local v194_ = g_gameSettings:getValue(GameSettings.SETTING.PLAYED_MULTIPLAYER)
	local v195_ = g_gameSettings:getValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS) / 3600
	local v196_ = math.floor(v195_)
	local v197_ = math.max(0, v196_)
	local v198_ = g_gameSettings:getValue(GameSettings.SETTING.STARTED_GUIDED_TOUR) and 1 or 0
	setModDownloadManagerRecommenderParams(v192_, v194_, v193_, v197_, v198_)
end
