ModHubController = {}
local ModHubController_mt = Class(ModHubController)
ModHubController.CATEGORY_ID_CONTEST = 8
ModHubController.CATEGORY_ID_DOWNLOAD = 2
ModHubController.CATEGORY_ID_UPDATE = 3
ModHubController.HIDDEN_CATEGORY = "hidden"
local setModHubRatingLocal = setModHubRating
local getModHubRatingLocal = getModHubRating
function ModHubController.new()
	local self = setmetatable({}, ModHubController_mt)
	self.isInitialized = false
	self.categories = {}
	self.modIdToInfo = {}
	self.categoryTypeMapping = {}
	self.categoryNameMapping = {}
	self.hasChanges = false
	self.hasTriggedUUIDInEngine = false
	self.priceMapping = { en = "DLCPriceEUR", de = "DLCPriceEUR", pl = "DLCPriceEUR", cz = "DLCPriceEUR", fr = "DLCPriceEUR", es = "DLCPriceEUR", it = "DLCPriceEUR", pt = "DLCPriceEUR", hu = "DLCPriceEUR", nl = "DLCPriceEUR", da = "DLCPriceEUR", fi = "DLCPriceEUR", no = "DLCPriceEUR", sv = "DLCPriceEUR", jp = "DLCPriceUSD", ru = "DLCPriceUSD", cs = "DLCPriceUSD", ct = "DLCPriceUSD", br = "DLCPriceUSD", tr = "DLCPriceUSD", ro = "DLCPriceUSD", kr = "DLCPriceUSD", ea = "DLCPriceUSD", fc = "DLCPriceUSD", uk = "DLCPriceUSD", vi = "DLCPriceUSD", id = "DLCPriceUSD" }
	local numLanguages = getNumOfLanguages()
	for i = 0, numLanguages - 1 do
		local code = getLanguageCode(i)
		if self.priceMapping[code] == nil then
			Logging.devError("ModHubController: Missing price mapping for '%s'", code)
			self.priceMapping[g_languageShort] = "DLCPriceUSD"
		end
	end
	g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.userProfileChanged, self)
	self.categoryTypeNameMapping = {}
	self.localCategories = {}
	self.categoryTypes = {}
	self.localCategoriesSorted = {}
	self:loadCategoriesFromXML()
	return self
end
function ModHubController:loadCategoriesFromXML()
	local xmlFile = loadXMLFile("configFile", "dataS/modHub.xml")
	local i = 0
	while true do
		local key = string.format("modHub.categories.types.type(%d)", i)
		if not hasXMLProperty(xmlFile, key) then
			break
		end
		local name = getXMLString(xmlFile, key .. "#name")
		local title = getXMLString(xmlFile, key .. "#title")
		if title ~= nil then
			title = g_i18n:convertText(title)
		end
		self.categoryTypeNameMapping[name] = title
		i = i + 1
	end
	i = 0
	while true do
		local key = string.format("modHub.categories.category(%d)", i)
		if not hasXMLProperty(xmlFile, key) then
			break
		end
		local name = getXMLString(xmlFile, key .. "#name")
		local categoryType = getXMLString(xmlFile, key .. "#type") or name
		local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")
		if name ~= nil and imageFilename ~= nil then
			local localCategory = { name = name, categoryType = categoryType, imageFilename = imageFilename }
			localCategory.isTab = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTab"), false)
			localCategory.isHidden = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHidden"), false)
			localCategory.title = getXMLString(xmlFile, key .. "#title")
			self.localCategories[name] = localCategory
			if localCategory.isTab or localCategory.isHidden then
				categoryType = ModHubController.HIDDEN_CATEGORY
			end
			if self.localCategoriesSorted[categoryType] == nil then
				self.localCategoriesSorted[categoryType] = {}
				table.insert(self.categoryTypes, categoryType)
			end
			table.insert(self.localCategoriesSorted[categoryType], name)
		end
		i = i + 1
	end
	delete(xmlFile)
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
function ModHubController:load()
	if not self.isInitialized then
		local numCategories = getNumModCategories()
		if g_isDevelopmentVersion then
			ModHubController.CATEGORY_ID_TESTING = numCategories + 1
			numCategories = numCategories + 1
		end
		for i = 1, numCategories do
			self:loadCategory(i)
		end
		for typeIndex, categoryType in ipairs(self.categoryTypes) do
			local typeTable = {}
			for _, categoryName in ipairs(self.localCategoriesSorted[categoryType]) do
				local categoryInfo = self.categoryNameMapping[categoryName]
				if categoryInfo == nil then
					continue
				end
				table.insert(typeTable, categoryInfo)
			end
			self.categoryTypeMapping[categoryType] = typeIndex
			table.insert(self.categories, typeTable)
		end
		self.isInitialized = true
	end
end
function ModHubController:loadCategory(categoryId)
	local isTestingCategory = g_isDevelopmentVersion and categoryId == ModHubController.CATEGORY_ID_TESTING
	if categoryId ~= ModHubController.CATEGORY_ID_CONTEST or not GS_IS_CONSOLE_VERSION and 0 < getNumOfMods(categoryId - 1) or isTestingCategory then
		local categoryName = nil
		if not isTestingCategory then
			categoryName = getModCategoryName(categoryId - 1)
		else
			categoryName = "testing"
		end
		local localCategory = self.localCategories[categoryName]
		if localCategory ~= nil then
			local iconFilename = localCategory.imageFilename
			local isHidden = localCategory.isTab or localCategory.isHidden
			local title = nil
			if localCategory.title ~= nil then
				title = g_i18n:convertText(localCategory.title)
			end
			if title == nil then
				title = g_i18n:getText("modHub_" .. categoryName)
			end
			local numNewItems, numAvailableUpdates, numConflictedItems = self:getCategoryData(categoryId)
			local categoryInfo = self.categoryNameMapping[categoryName]
			if categoryInfo ~= nil then
				categoryInfo:updateInfo(categoryId, title, iconFilename, categoryName, isHidden)
			else
				categoryInfo = ModCategoryInfo.new(categoryId, title, iconFilename, categoryName, isHidden)
				self.categoryNameMapping[categoryName] = categoryInfo
			end
			categoryInfo:setNumAvailableUpdates(numAvailableUpdates)
			categoryInfo:setNumNewItems(numNewItems)
			categoryInfo:setNumConflictedItems(numConflictedItems)
			return
		end
		Logging.warning("Could not find modhub category %s in modHub.xml", categoryName)
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
function ModHubController:getCategoryTypes()
	local visibleTypes = {}
	for typeIndex, categoryType in pairs(self.categoryTypes) do
		if categoryType == ModHubController.HIDDEN_CATEGORY then
			continue
		end
		for _, categoryName in pairs(self.localCategoriesSorted[categoryType]) do
			local category = self.categoryNameMapping[categoryName]
			if category == nil or category.isHidden then
				continue
			end
			if 0 < category:getNumMods() then
				table.insert(visibleTypes, categoryType)
				break
			end
		end
	end
	return visibleTypes
end
function ModHubController:getVisibleCategories()
	local list = {}
	for typeIndex, categoryType in pairs(self.categoryTypes) do
		if categoryType == ModHubController.HIDDEN_CATEGORY then
			continue
		end
		local typeList = {}
		for _, categoryName in pairs(self.localCategoriesSorted[categoryType]) do
			local category = self.categoryNameMapping[categoryName]
			if category == nil or category.isHidden then
				continue
			end
			if 0 < category:getNumMods() then
				table.insert(typeList, category)
			end
		end
		if 0 < #typeList then
			table.insert(list, typeList)
		end
	end
	return list
end
function ModHubController:getCategoryData(categoryId)
	if categoryId == ModHubController.CATEGORY_ID_TESTING then
		return 0, 0, 0
	end
	local numOfMods = 0
	if 0 < categoryId then
		numOfMods = getNumOfMods(categoryId - 1)
	end
	local numNewItems = 0
	local numUpdates = 0
	local numConflicts = 0
	if categoryId == ModHubController.CATEGORY_ID_DOWNLOAD then
		numNewItems = numOfMods
		return numNewItems, numUpdates, numConflicts
	elseif categoryId == ModHubController.CATEGORY_ID_UPDATE then
		numUpdates = numOfMods
		return numNewItems, numUpdates, numConflicts
	else
		if 0 < numOfMods then
			for i = 0, numOfMods - 1 do
				local modId = getModId(categoryId - 1, i)
				local modInfo = self:getModInfo(modId)
				if not modInfo:getIsDLC() or 1 < modInfo:getPriceString():len() or modInfo:getIsInstalled() then
					numUpdates = numUpdates + modInfo:getNumUpdates()
					numConflicts = numConflicts + modInfo:getNumConflicts()
					numNewItems = numNewItems + modInfo:getNumNew()
				end
			end
		end
		return numNewItems, numUpdates, numConflicts
	end
end
function ModHubController:getModsByCategory(categoryId, visibleOnly)
	if g_isDevelopmentVersion then
		local isTestingCategory = categoryId == ModHubController.CATEGORY_ID_TESTING
		if isTestingCategory then
			local testingMods = {}
			for _, modInfo in pairs(self.modIdToInfo) do
				if modInfo:getIsTesting() then
					table.insert(testingMods, modInfo)
				end
			end
			table.sort(testingMods, function(a, b)
				return a:getName() < b:getName()
			end)
			return testingMods
		end
	end
	if categoryId == ModHubController.CATEGORY_ID_UPDATE then
		local updateMods = {}
		local numOfMods = getNumOfMods(categoryId - 1)
		if 0 < numOfMods then
			for i = 0, numOfMods - 1 do
				local modId = getModId(categoryId - 1, i)
				local modInfo = self:getModInfo(modId)
				if modId < 0 then
					Logging.devError("external/non-modhub mod included in 'UPDATE' category: id:%d %s %s size:%d", modInfo:getId(), modInfo:getName(), modInfo:getFilename(), modInfo:getFilesize())
				end
				table.insert(updateMods, modInfo)
			end
		end
		return updateMods
	else
		local mods = {}
		local numOfMods = getNumOfMods(categoryId - 1)
		if 0 < numOfMods then
			for i = 0, numOfMods - 1 do
				local modId = getModId(categoryId - 1, i)
				local modInfo = self:getModInfo(modId)
				if not visibleOnly or not modInfo:getIsDLC() or 1 < modInfo:getPriceString():len() or modInfo:getIsInstalled() then
					table.insert(mods, modInfo)
				end
			end
		end
		return mods
	end
end
function ModHubController:getCategory(name)
	return self.categoryNameMapping[name]
end
function ModHubController:getModInfo(modId)
	local modInfo = self.modIdToInfo[modId]
	if modInfo == nil then
		if type(modId) ~= "number" then
			return nil
		end
		modInfo = ModInfo.new(modId, self:getPostFix(), self.priceMapping[g_languageShort])
		self.modIdToInfo[modId] = modInfo
	end
	return modInfo
end
function ModHubController:getDependentMods(modId)
	local dependendMods = {}
	for i = 0, getModNumDependencies(modId) - 1 do
		local dependendModId = getModDependency(modId, i)
		local modInfo = self:getModInfo(dependendModId)
		table.insert(dependendMods, modInfo)
	end
	return dependendMods
end
function ModHubController:getPostFix()
	if g_languageShort == "de" or g_languageShort == "fr" then
		return g_languageShort
	end
	return "en"
end
function ModHubController:getTotalFilesizeKb(modId)
	local modInfo = self:getModInfo(modId)
	local dependendMods = self:getDependentMods(modId)
	local totalFilesizeKb = math.floor((modInfo:getFilesize() + 1023) / 1024)
	for _, dependendMod in ipairs(dependendMods) do
		if dependendMod.isInstalled then
			continue
		end
		totalFilesizeKb = totalFilesizeKb + math.floor((dependendMod:getFilesize() + 1023) / 1024)
	end
	return totalFilesizeKb
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
	else
		if self.isContestEnabledStored == nil then
			self.isContestEnabledStored = 0 < getNumOfMods(ModHubController.CATEGORY_ID_CONTEST - 1)
		end
		return self.isContestEnabledStored
	end
end
function ModHubController:install(modId)
	local success = installMod(modId)
	if success then
		local dependendMods = self:getDependentMods(modId)
		local numFailed = 0
		local failedDependentMods = {}
		for _, dependendMod in ipairs(dependendMods) do
			if dependendMod.isInstalled then
				continue
			end
			local dependendSuccess = installMod(dependendMod.modId)
			if dependendSuccess then
				continue
			end
			table.insert(failedDependentMods, dependendMod)
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
		callback(target)
	end
end
function ModHubController:setDependentModInstallFailedCallback(callback, target)
	function self.dependendModInstallFailedCallback(failedDependentMods)
		callback(target, failedDependentMods)
	end
end
function ModHubController:setAddedToDownloadCallback(callback, target)
	function self.addedToDownloadCallback()
		callback(target)
	end
end
function ModHubController:installOrUpdateMods(modIds, finishCallback)
	self:startModification()
	local numToGo = #modIds
	local numFailed = 0
	local failure = function()
		numToGo = numToGo - 1
		numFailed = numFailed + 1
		if numToGo == 0 then
			finishCallback(numFailed)
		end
	end
	local added = function()
		numToGo = numToGo - 1
		if numToGo == 0 then
			finishCallback(numFailed)
		end
	end
	self:setModInstallFailedCallback(failure, self)
	self:setDependentModInstallFailedCallback(failure, self)
	self:setAddedToDownloadCallback(added, self)
	for _, modId in ipairs(modIds) do
		if getModMetaAttributeBool(modId, "isUpdate") then
			self:update(modId)
		else
			self:install(modId)
		end
	end
end
function ModHubController:update(modId)
	local success = updateMod(modId)
	if success then
		local numFailed = 0
		local failedDependentMods = {}
		local dependendMods = self:getDependentMods(modId)
		for _, dependendMod in ipairs(dependendMods) do
			if dependendMod.isUpdate then
				local dependendSuccess = updateMod(modId)
				if dependendSuccess then
					continue
				end
				table.insert(failedDependentMods, dependendMod)
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
function ModHubController:uninstall(modId)
	local mod = self:getModInfo(modId)
	local hash = mod.hash
	local success = uninstallMod(modId)
	if success then
		self.hasChanges = true
		mod = g_modManager:getModByFileHash(hash)
		if mod ~= nil then
			g_modManager:removeMod(mod)
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
		callback(target)
	end
end
function ModHubController:setUninstalledCallback(callback, target)
	function self.uninstalledCallback()
		callback(target)
	end
end
function ModHubController:setDiscSpaceChangedCallback(callback, target)
	function self.discSpaceChangedCallback()
		local freeSpaceKb = getModFreeSpaceKb()
		local usedSpaceKb = getModUsedSpaceKb()
		callback(target, freeSpaceKb, usedSpaceKb)
	end
end
function ModHubController:vote(modId, value)
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
		callback(target)
	end
end
function ModHubController:getVote(modId)
	if not self.hasTriggedUUIDInEngine then
		getUniqueUserId()
		self.hasTriggedUUIDInEngine = true
	end
	local ratingValue, httpReturnCode = getModHubRatingLocal(modId)
	if httpReturnCode == 0 then
		return 0
	else
		return ratingValue
	end
end
function ModHubController:setShowAllMods(showAll)
	setEnableBetaMods(showAll)
end
function ModHubController:searchMods(categoryId, text)
	text = string.lower(text)
	local hits = {}
	if categoryId ~= nil then
		self:searchInCategory(hits, categoryId, text)
	else
		for _, categories in ipairs(self.categories) do
			for _, category in ipairs(categories) do
				if self:isCategorySearchable(category) then
					hits = self:searchInCategory(hits, category.id, text)
				end
			end
		end
	end
	local list = {}
	for _, info in pairs(hits) do
		table.insert(list, info)
	end
	table.sort(list, function(a, b)
		return b[2] < a[2]
	end)
	for i, info in ipairs(list) do
		list[i] = info[1]
	end
	return list
end
function ModHubController:isCategorySearchable(category)
	return not category.isHidden or category.name == "contest" or category.name == "dlc"
end
function ModHubController:searchInCategory(list, categoryId, text)
	local numOfMods = getNumOfMods(categoryId - 1)
	local postFix = self:getPostFix()
	if 0 < numOfMods then
		for i = 0, numOfMods - 1 do
			local modId = getModId(categoryId - 1, i)
			if list[modId] == nil then
				local hit = false
				local score = 0
				local title = getModMetaAttributeString(modId, "title_" .. postFix)
				local titleLower = utf8ToLower(title)
				local sStart, sEnd = string.find(titleLower, text, nil, true)
				if sStart ~= nil then
					score = self:generateSearchScore(text, title, sStart, sEnd)
					hit = true
				else
					local author = getModMetaAttributeString(modId, "author")
					local authorLower = utf8ToLower(author)
					sStart, sEnd = string.find(authorLower, text, nil, true)
					if sStart ~= nil then
						score = self:generateSearchScore(text, author, sStart, sEnd)
						hit = true
					end
				end
				if hit then
					list[modId] = { self:getModInfo(modId), score }
				end
			end
		end
	end
	return list
end
function ModHubController:generateSearchScore(input, result, start, finish)
	local resultLength = utf8Strlen(result)
	return 0.8 * (utf8Strlen(input) / resultLength) + 0.2 * (1 - start / resultLength)
end
function ModHubController:userProfileChanged()
	self.hasTriggedUUIDInEngine = false
	self:updateRecommendationSystem()
end
function ModHubController:updateRecommendationSystem()
	local usesHelpWindow = g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)
	local isLastUsedCharacterMale = g_gameSettings:getValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE)
	local playedMultiplayer = g_gameSettings:getValue(GameSettings.SETTING.PLAYED_MULTIPLAYER)
	local totalPlayedHours = math.max(0, math.floor(g_gameSettings:getValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS) / 3600))
	local numTutorialsPlayed = g_gameSettings:getValue(GameSettings.SETTING.STARTED_GUIDED_TOUR) and 1 or 0
	setModDownloadManagerRecommenderParams(usesHelpWindow, playedMultiplayer, isLastUsedCharacterMale, totalPlayedHours, numTutorialsPlayed)
end
