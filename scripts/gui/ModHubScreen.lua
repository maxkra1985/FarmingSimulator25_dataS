-- Local values: ModHubScreen_mt
ModHubScreen = {}
local ModHubScreen_mt = Class(ModHubScreen, TabbedMenuWithDetails)
ModHubScreen.SPECIAL_LIST_LIMIT = 42
function ModHubScreen.register()
	ModHubCategoriesFrame.register()
	ModHubDetailsFrame.register()
	ModHubExtraContentFrame.register()
	ModHubItemsFrame.register()
	ModHubLoadingFrame.register()
	local v2_ = ModHubScreen.new()
	g_gui:loadGui("dataS/gui/ModHubScreen.xml", "ModHubScreen", v2_)
	return v2_
end

-- Upvalues: ModHubScreen_mt
-- Local values: self
function ModHubScreen.new(target, custom_mt)
	-- upvalues: (copy) ModHubScreen_mt
	local v5_ = TabbedMenuWithDetails.new(target, custom_mt or ModHubScreen_mt)
	v5_.checkForLoaded = true
	v5_.isLoading = true
	v5_.showingAllMods = false
	v5_.updateModInterval = 1000
	v5_.updateModTimer = v5_.updateModInterval
	return v5_
end

-- Local values: newGui
function ModHubScreen.createFromExistingGui(gui, guiName)
	ModHubCategoriesFrame.createFromExistingGui(g_gui.frames.modHubCategories.target, "ModHubCategoriesFrame")
	ModHubDetailsFrame.createFromExistingGui(g_gui.frames.modHubDetails.target, "ModHubDetailsFrame")
	ModHubExtraContentFrame.createFromExistingGui(g_gui.frames.modHubExtraContent.target, "ModHubExtraContentFrame")
	ModHubItemsFrame.createFromExistingGui(g_gui.frames.modHubItems.target, "ModHubItemsFrame")
	local v8_ = ModHubScreen.new()
	g_gui.guis[gui.name].target:delete()
	g_gui.guis[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, false)
	return v8_
end

function ModHubScreen:onGuiSetupFinished()
	ModHubScreen:superClass().onGuiSetupFinished(self)
	self.showingAllMods = g_gameSettings:getValue(GameSettings.SETTING.SHOW_ALL_MODS)
	g_modHubController:setShowAllMods(self.showingAllMods)
	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
	self.clickNextCallback = self:makeSelfCallback(self.onPageNext)
	self.clickPrevCallback = self:makeSelfCallback(self.onPagePrevious)
	self:setupPages()
	self:setupMenuButtonInfo()
end

-- Local values: pagePredicate, contestPredicate, detailsPredicate, testingPredicate, orderedPages, i, pageDef, page, predicate, iconSliceId
function ModHubScreen:setupPages()
	local v11_ = self:makeIsModHubEnabledPredicate()
	local v12_ = self:makeIsContestEnabledPredicate()
	local v13_ = self:makeIsModHubItemsEnabledPredicate()
	local v14_ = self:makeIsTestingEnabledPredicate()
	local v15_ = {
		{ self.pageLoading, self:makeIsLoadingEnabledPredicate(), ModHubScreen.SLICE_ID.CATEGORIES },
		{ self.pageCategories, v11_, ModHubScreen.SLICE_ID.CATEGORIES },
		{ self.pageInstalled, v11_, ModHubScreen.SLICE_ID.INSTALLED },
		{ self.pageUpdates, v11_, ModHubScreen.SLICE_ID.UPDATES },
		{ self.pageDLCs, v11_, ModHubScreen.SLICE_ID.DLCS },
		{ self.pageExtraContent, v11_, ModHubScreen.SLICE_ID.EXTRA_CONTENT },
		{ self.pageContest, v12_, ModHubScreen.SLICE_ID.CONTEST },
		{ self.pageTesting, v14_, ModHubScreen.SLICE_ID.TESTING },
		{ self.pageItems, v13_, ModHubScreen.SLICE_ID.BEST },
		{ self.pageDetails, v13_, ModHubScreen.SLICE_ID.BEST },
		{ self.pageSearch, v13_, ModHubScreen.SLICE_ID.BEST }
	}
	for v16_, v17_ in ipairs(v15_) do
		local v18_, v19_, v20_ = unpack(v17_)
		self:registerPage(v18_, v16_, v19_)
		self:addPageTab(v18_, nil, nil, v20_)
	end
	self:rebuildTabList()
end

-- Local values: onButtonBackFunction, onButtonNextFunction, onButtonPrevFunction
function ModHubScreen:setupMenuButtonInfo()
	local v22_ = self.clickBackCallback
	local v23_ = self.clickNextCallback
	local v24_ = self.clickPrevCallback
	self.defaultMenuButtonInfo = {
		{
			["inputAction"] = InputAction.MENU_BACK,
			["text"] = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_BACK),
			["callback"] = v22_
		},
		{
			["inputAction"] = InputAction.MENU_PAGE_NEXT,
			["text"] = g_i18n:getText("ui_ingameMenuNext"),
			["callback"] = v23_
		},
		{
			["inputAction"] = InputAction.MENU_PAGE_PREV,
			["text"] = g_i18n:getText("ui_ingameMenuPrev"),
			["callback"] = v24_
		}
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_NEXT] = self.defaultMenuButtonInfo[2]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_PREV] = self.defaultMenuButtonInfo[3]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = v22_,
		[InputAction.MENU_PAGE_NEXT] = v23_,
		[InputAction.MENU_PAGE_PREV] = v24_
	}
	self:assignMenuButtonInfo(self.defaultMenuButtonInfo)
end

-- Local values: onSearchButtonCallback, onToggleCallback, getBetaToggleTextCallback, clickItemCallback, onSelectItemCallback, initCategoryPage
function ModHubScreen:initializePages()
	g_modHubController:setShowAllMods(self.showingAllMods)
	g_modHubController:load()
	g_modHubController:setDiscSpaceChangedCallback(self.updateDiscSpace, self)
	local v_u_26_ = self:makeSelfCallback(self.onSearchButton)
	local v_u_27_ = self:makeSelfCallback(self.onToggleBeta)
	local v_u_28_ = self:makeSelfCallback(self.getBetaToggleText)
	local v_u_29_ = self:makeClickItemCallback()
	local v_u_30_ = self:makeSelfCallback(self.onSelectItem)
	self.pageCategories:initialize(g_modHubController:getVisibleCategories(), self:makeSelfCallback(self.onClickCategory), g_i18n:getText(ModHubScreen.L10N_SYMBOL.HEADER_MOD_HUB), ModHubScreen.CATEGORY_IMAGE_HEIGHT_WIDTH_RATIO)
	self.pageCategories:setSearchCallback(v_u_26_)
	self.pageCategories:setToggleBetaCallback(v_u_27_)
	self.pageCategories:setBetaToggleTextCallback(v_u_28_)
	self.pageCategories:setItemSelectCallback(v_u_30_)
	self.pageCategories:setItemClickCallback(v_u_29_)
	self.pageExtraContent:initialize(g_i18n:getText(ModHubScreen.L10N_SYMBOL.HEADER_EXTRA_CONTENT))
	local function v35_(p31_, p32_, _, p33_)
		-- upvalues: (copy) v_u_29_, (copy) v_u_30_, (copy) v_u_26_, (copy) v_u_27_, (copy) v_u_28_
		local v34_ = g_modHubController:getCategory(p32_)
		if v34_ ~= nil then
			p31_:initialize(p33_)
			p31_:setCategoryId(v34_.id)
			p31_:setCategory(p32_)
			p31_:setItemClickCallback(v_u_29_)
			p31_:setItemSelectCallback(v_u_30_)
			p31_:setSearchCallback(v_u_26_)
			p31_:setToggleBetaCallback(v_u_27_)
			p31_:setBetaToggleTextCallback(v_u_28_)
		end
	end
	v35_(self.pageInstalled, "installed", nil, ModHubScreen.SLICE_ID.INSTALLED)
	v35_(self.pageUpdates, "update", nil, ModHubScreen.SLICE_ID.UPDATES)
	v35_(self.pageDLCs, "dlc", true, ModHubScreen.SLICE_ID.DLCS)
	v35_(self.pageContest, "contest", nil, ModHubScreen.SLICE_ID.CONTEST)
	v35_(self.pageTesting, "testing", nil, ModHubScreen.SLICE_ID.TESTING)
	self.pageSearch:initialize()
	self.pageSearch:setItemClickCallback(v_u_29_)
	self.pageSearch:setItemSelectCallback(v_u_30_)
	self.pageSearch.headerText:setText(g_i18n:getText("modHub_search"))
	self.pageItems:initialize()
	self.pageItems:setItemClickCallback(v_u_29_)
	self.pageItems:setItemSelectCallback(v_u_30_)
	self.pageItems:setSearchCallback(v_u_26_)
	self.pageItems:setToggleBetaCallback(v_u_27_)
	self.pageItems:setBetaToggleTextCallback(v_u_28_)
	self.pageDetails:initialize()
end

function ModHubScreen:reset()
	ModHubScreen:superClass().reset(self)
	g_modHubController:reset()
	self.showingAllMods = false
end

function ModHubScreen:onOpen(element)
	g_modHubController:startModification()
	if modDownloadManagerLoaded() then
		self:setIsLoading(false)
		self.checkForLoaded = false
		self:updateDownloadStates()
	else
		self:setIsLoading(true)
		self.checkForLoaded = true
	end
	ModHubScreen:superClass().onOpen(self)
	self.pageSelector:setState(1, true)
	if g_isDevelopmentVersion then
		addConsoleCommand("gsModHubUninstallAll", "Uninstalls all mods", "consoleCommandUninstallAll", self)
	end
end

function ModHubScreen:onClose(element)
	removeConsoleCommand("gsModHubUninstallAll")
	g_modHubController:endModification()
	self.pageCategories:reset()
	ModHubScreen:superClass().onClose(self)
end

function ModHubScreen:update(dt)
	ModHubScreen:superClass().update(self, dt)
	if getModDownloadAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		return
	elseif getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	else
		if self.checkForLoaded and modDownloadManagerLoaded() then
			self.checkForLoaded = false
			self:setIsLoading(false)
			self:updateDownloadStates()
			self:updatePages()
			self.pageSelector:setState(1, true)
		end
		self.updateModTimer = self.updateModTimer - dt
		if self.updateModTimer <= 0 then
			self:updateDownloadStates()
			self:updateDiscSpace(g_modHubController:getFreeModSpaceKb(), g_modHubController:getUsedModSpaceKb())
		end
	end
end

function ModHubScreen:setIsLoading(loading)
	self.isLoading = loading
	if not (loading or self.initialized) then
		self:initializePages()
		self.initialized = true
	end
end

function ModHubScreen:exitMenu()
	self:changeScreen(MainScreen)
end

-- Local values: category, activeDownloads, categoryId, _, modInfo
function ModHubScreen:updateDownloadStates()
	local v45_ = g_modHubController:getCategory("download")
	local v46_
	if v45_ == nil then
		v46_ = nil
	else
		local v47_ = v45_.id
		v46_ = g_modHubController:getModsByCategory(v47_, true)
		self.downloadFailedFound = false
		self.downloadActiveFound = false
		if #v46_ > 0 then
			for _, v48_ in ipairs(v46_) do
				self:updateModDownloadState(v48_)
			end
		end
	end
	local v49_ = self.buttonDownload
	local v50_
	if v46_ == nil then
		v50_ = false
	else
		v50_ = #v46_ > 0
	end
	v49_:setVisible(v50_)
	self.updateModTimer = self.updateModInterval
end

-- Local values: isFailed, isDownloading, isInstalled, isDownload, percent, downloaded, fileSize, minSize
function ModHubScreen:updateModDownloadState(modInfo)
	if self.downloadFailedFound then
		return
	else
		local v53_ = modInfo:getIsFailed()
		if not (v53_ or self.downloadActiveFound) then
			local v54_ = modInfo:getIsDownloading()
			local v55_ = modInfo:getIsInstalled()
			local v56_ = 0
			if v54_ or modInfo:getIsDownload() then
				local v57_ = modInfo:getDownloadedBytes()
				local v58_ = modInfo:getFilesize()
				if v58_ ~= 0 then
					local v59_ = v57_ / v58_
					v56_ = math.clamp(v59_, 0, 1) or v56_
				end
			else
				v56_ = v55_ and 1 or v56_
			end
			local v60_ = self.downloadStatusBar.startSize[1] + self.downloadStatusBar.endSize[1]
			local v61_ = self.downloadStatusBar
			local v62_ = self.downloadStatusBarBg.size[1] * v56_ + g_pixelSizeX
			v61_:setSize(math.max(v62_, v60_), nil)
			self.downloadTextFailed:setVisible(v53_)
			self.downloadStatusBarBg:setVisible(not v53_)
		end
	end
end

function ModHubScreen:onClickCategory(categoryId, categoryName)
	self.pageItems:setCategoryId(categoryId)
	self.pageItems:setCategory(categoryName)
	self:pushDetail(self.pageItems)
end

-- Local values: modInfo
function ModHubScreen:onSelectItem(page, modId)
	if not g_gui.currentlyReloading then
		page:setModInfo((g_modHubController:getModInfo(modId)))
	end
end

-- Local values: topFrame, total, used
function ModHubScreen:updateDiscSpace(freeSpaceKb, usedSpaceKb)
	local v71_ = self:getTopFrame()
	if v71_ ~= self.pageLoading and (v71_ ~= self.pageExtraContent and v71_.spaceUsageLabel ~= nil) then
		if Platform.hasLimitedModSpace then
			local v72_ = (freeSpaceKb + usedSpaceKb) / 1024
			local v73_ = usedSpaceKb / 1024
			v71_.spaceUsageLabel:setText(string.format("%s / %s Mb (%0.f%%)", g_i18n:formatNumber(v73_, 2, true), g_i18n:formatNumber(v72_, 2, true), v73_ / v72_ * 100))
			v71_.diskSpaceBox:setVisible(true)
			v71_.diskSpaceBoxBg:setVisible(true)
			v71_.diskSpaceBox:invalidateLayout()
			v71_.diskSpaceBoxBg:setSize(v71_.diskSpaceBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
			return
		end
		if v71_.diskSpaceBox ~= nil then
			v71_.diskSpaceBox:setVisible(false)
			v71_.diskSpaceBoxBg:setVisible(false)
		end
	end
end

-- Local values: dialogPrompt, imePrompt, confirmText
function ModHubScreen:onSearchButton(categoryId)
	local v76_ = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	local v77_ = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	local v78_ = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
	TextInputDialog.show(self.onSearchFinished, self, nil, v76_, v77_, 40, v78_, categoryId, nil, false)
end

-- Local values: result
function ModHubScreen:onSearchFinished(text, ok, categoryId)
	if ok and utf8Strlen(text) > 0 then
		local v83_ = g_modHubController:searchMods(categoryId, text)
		self.pageSearch:setModItems(v83_)
		self:pushDetail(self.pageSearch)
	end
end

function ModHubScreen:onDownloadButton()
	ModHubDownloadDialog.show()
end

function ModHubScreen:onToggleBeta(page)
	self.showingAllMods = not self.showingAllMods
	g_modHubController:setShowAllMods(self.showingAllMods)
	g_modHubController:reload()
	g_gameSettings:setValue(GameSettings.SETTING.SHOW_ALL_MODS, self.showingAllMods, true)
	self.pageCategories:setCategories(g_modHubController:getVisibleCategories())
	page:reload()
end

function ModHubScreen:getBetaToggleText()
	if self.showingAllMods then
		return g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SHOW_CROSSPLAY)
	else
		return g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SHOW_ALL)
	end
end
function ModHubScreen.onDetailOpened(p87_, ...)
	ModHubScreen:superClass().onDetailOpened(p87_, ...)
	p87_:updateDiscSpace(g_modHubController:getFreeModSpaceKb(), g_modHubController:getUsedModSpaceKb())
end
function ModHubScreen.onPageChange(p88_, ...)
	ModHubScreen:superClass().onPageChange(p88_, ...)
	for v89_ = 1, #p88_.enabledPages do
		p88_:updateModhubUpdateIcon(1, v89_, (p88_.pagingTabList:getElementAtSectionIndex(1, v89_)))
	end
	p88_:updateDiscSpace(g_modHubController:getFreeModSpaceKb(), g_modHubController:getUsedModSpaceKb())
end

function ModHubScreen:populateCellForItemInSection(list, section, index, cell)
	ModHubScreen:superClass().populateCellForItemInSection(self, list, section, index, cell)
	self:updateModhubUpdateIcon(section, index, cell)
end

-- Local values: _, numUpdates
function ModHubScreen:updateModhubUpdateIcon(section, index, cell)
	if modDownloadManagerLoaded() then
		local _, v98_, _ = g_modHubController:getCategoryData(ModHubController.CATEGORY_ID_UPDATE)
		local v99_ = cell:getAttribute("iconHasUpdates")
		local v100_
		if self.enabledPages[index] == self.pageUpdates then
			v100_ = v98_ > 0
		else
			v100_ = false
		end
		v99_:setVisible(v100_)
	end
end

function ModHubScreen:makeClickItemCallback()
	return function(_, p102_, _)
		-- upvalues: (copy) self
		local v103_ = g_modHubController:getModInfo(p102_)
		self.pageDetails:setModInfo(v103_)
		self:pushDetail(self.pageDetails)
	end
end

function ModHubScreen:makeIsLoadingEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		return self.isLoading
	end
end

function ModHubScreen:makeIsModHubEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v106_ = not self.isLoading
		if v106_ then
			v106_ = not self:getIsDetailMode()
		end
		return v106_
	end
end

function ModHubScreen:makeIsModHubItemsEnabledPredicate()
	return function()
		return false
	end
end

function ModHubScreen:makeIsContestEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v108_ = not (self.isLoading or self:getIsDetailMode())
		if v108_ then
			v108_ = g_modHubController:isContestEnabled()
		end
		return v108_
	end
end

function ModHubScreen:makeIsTestingEnabledPredicate()
	return function()
		return g_isDevelopmentVersion
	end
end

-- Local values: modInfo
function ModHubScreen:openWithModId(modId)
	local v111_ = g_modHubController:getModInfo(modId)
	if v111_ ~= nil then
		g_gui:showGui("ModHubScreen")
		self.pageDetails:setModInfo(v111_)
		self:pushDetail(self.pageDetails)
	end
end

function ModHubScreen:openDownloads()
	g_gui:showGui("ModHubScreen")
	ModHubDownloadDialog.show()
end

-- Local values: dummy, category, mods, _, modInfo
function ModHubScreen:consoleCommandUninstallAll()
	local function v112_() end
	g_modHubController:setUninstallFailedCallback(v112_, nil)
	g_modHubController:setUninstalledCallback(v112_, nil)
	local v113_ = g_modHubController:getCategory("installed")
	local v114_ = g_modHubController:getModsByCategory(v113_.id, true)
	for _, v115_ in ipairs(v114_) do
		g_modHubController:uninstall(v115_:getId())
	end
end
ModHubScreen.L10N_SYMBOL = {
	["HEADER_MOD_HUB"] = "modHub_title",
	["HEADER_EXTRA_CONTENT"] = "modHub_extraContent",
	["BUTTON_BACK"] = "button_back",
	["BUTTON_SEARCH"] = "modHub_search",
	["BUTTON_SHOW_ALL"] = "button_modHubShowAll",
	["BUTTON_SHOW_CROSSPLAY"] = "button_modHubShowCrossplay"
}
ModHubScreen.SLICE_ID = {
	["CATEGORIES"] = "gui.modhub_categories",
	["DLCS"] = "gui.modhub_dlcs",
	["BEST"] = "gui.modHub_best",
	["MOST_DOWNLOADED"] = "gui.modHub_mostDownloaded",
	["LATEST"] = "gui.modHub_latest",
	["CONTEST"] = "gui.modHub_winners",
	["RECOMMENDED"] = "gui.modHub_recommended",
	["DOWNLOADS"] = "gui.modHub_downloads",
	["UPDATES"] = "gui.modhub_updates",
	["INSTALLED"] = "gui.modhub_installed",
	["EXTRA_CONTENT"] = "gui.modhub_extraContent",
	["TESTING"] = "gui.modhub_testing"
}
ModHubScreen.CATEGORY_IMAGE_HEIGHT_WIDTH_RATIO = 1
