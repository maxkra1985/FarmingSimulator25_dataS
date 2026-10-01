ModHubDetailsFrame = {}
local ModHubDetailsFrame_mt = Class(ModHubDetailsFrame, TabbedMenuFrameElement)
function ModHubDetailsFrame.register()
	local modHubDetailsFrame = ModHubDetailsFrame.new()
	g_gui:loadGui("dataS/gui/ModHubDetailsFrame.xml", "ModHubDetailsFrame", modHubDetailsFrame, true)
end
function ModHubDetailsFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or ModHubDetailsFrame_mt)
	self.hasCustomMenuButtons = true
	self.currentModInfo = nil
	self.scrollInputDelay = 0
	self.scrollInputDelayDir = 0
	return self
end
function ModHubDetailsFrame.createFromExistingGui(gui, guiName)
	local newGui = ModHubDetailsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	newGui.hasCustomMenuButtons = gui.hasCustomMenuButtons
	return newGui
end
function ModHubDetailsFrame:initialize()
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
	self.buyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_BUY),
		callback = function()
			self:onButtonBuy()
		end,
	}
	self.installFreeDLCButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_INSTALL),
		callback = function()
			self:onButtonBuy()
		end,
	}
	self.installButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_INSTALL),
		callback = function()
			self:onButtonInstall()
		end,
	}
	self.uninstallButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_UNINSTALL),
		callback = function()
			self:onButtonUninstall()
		end,
	}
	self.updateButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_UPDATE),
		callback = function()
			self:onButtonUpdate()
		end,
	}
	self.downloadButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_DOWNLOAD),
		callback = function()
			self:onButtonDownload()
		end,
	}
	self.voteButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_2,
		text = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_VOTE),
		callback = function()
			self:onButtonVote()
		end,
	}
	self.screenshotsButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_SCREENSHOTS),
		callback = function()
			self:onButtonScreenshots()
		end,
	}
end
function ModHubDetailsFrame:onFrameOpen()
	ModHubDetailsFrame:superClass().onFrameOpen(self)
	FocusManager:setFocus(self.itemsList)
	g_modHubController:setModInstallFailedCallback(self.onModInstallFailed, self)
	g_modHubController:setDependentModInstallFailedCallback(self.onDependentModInstallFailed, self)
	g_modHubController:setAddedToDownloadCallback(self.onAddedToDownload, self)
	g_modHubController:setUninstallFailedCallback(self.onUninstallFailed, self)
	g_modHubController:setUninstalledCallback(self.onUninstalled, self)
	g_modHubController:setVotedCallback(self.onVoted, self)
end
function ModHubDetailsFrame:getMenuButtonInfo()
	local buttons = {}
	local modInfo = g_modHubController:getModInfo(self.currentModInfo:getId())
	local isUpdate = modInfo:getIsUpdate()
	local isInstalled = modInfo:getIsInstalled()
	local isDownload = modInfo:getIsDownload()
	local isDLC = modInfo:getIsDLC()
	if not modInfo:getIsExternal() and (not modInfo:getIsFailed() and (not isDownload and (isInstalled and isUpdate))) then
		if isUpdate then
			if not isDLC or not GS_IS_CONSOLE_VERSION then
				table.insert(buttons, self.updateButtonInfo)
			end
		elseif isDLC then
			local priceString = modInfo:getPriceString()
			if priceString == "Free" then
				table.insert(buttons, self.installFreeDLCButtonInfo)
			elseif 1 < priceString:len() then
				table.insert(buttons, self.buyButtonInfo)
			end
		else
			table.insert(buttons, self.installButtonInfo)
		end
	end
	table.insert(buttons, self.backButtonInfo)
	table.insert(buttons, self.nextPageButtonInfo)
	table.insert(buttons, self.prevPageButtonInfo)
	if not modInfo:getIsExternal() and (isInstalled and not isDLC) then
		table.insert(buttons, self.voteButtonInfo)
	end
	if (isInstalled or isDownload) and not isDLC then
		table.insert(buttons, self.uninstallButtonInfo)
	end
	if modInfo:getScreenshots() ~= nil and 0 < #modInfo:getScreenshots() then
		table.insert(buttons, self.screenshotsButtonInfo)
	end
	return buttons
end
function ModHubDetailsFrame:setModInfo(modInfo)
	self.currentModInfo = modInfo
	self.modDescription:setText(modInfo:getDescription())
	local totalHeight, _numLines = self.modDescription:getTextHeight()
	self.modDescription:setSize(nil, totalHeight)
	self.modDescription.parent:invalidateLayout()
	self.descriptionLayout:scrollTo(0, true)
	self.modAuthor:setText(modInfo:getAuthor())
	local isDLC = modInfo:getIsDLC()
	self.modInfoSize:setVisible(not isDLC)
	local hash = modInfo:getHash()
	if not isDLC then
		local showHash = false
		if hash ~= "" then
			showHash = not GS_IS_CONSOLE_VERSION
		end
	end
	self.modInfoHash:setVisible(showHash)
	self.modInfoHash:setText(hash)
	local filename = modInfo:getFilename()
	self.modInfoFilename:setVisible(modInfo:getIsInstalled())
	self.modAttributeInfoFilenameSpace:setVisible(modInfo:getIsInstalled())
	self.modInfoFilename:setText(filename)
	if not isDLC then
		local size = modInfo:getFilesize() / 1024 / 1024
		self.modInfoSize:setText(string.format("%.02f MB", size))
		local ratingScore = modInfo:getRatingScore() / 100
		for i = 1, 5 do
			self.modAttributeRatingStar[i].elements[1]:setVisible(i - 0.75 <= ratingScore and ratingScore < i - 0.25)
			if i - 0.25 <= ratingScore then
				self.modAttributeRatingStar[i]:applyProfile(ModHubCategoriesFrame.PROFILE.RATING_STAR_ACTIVE)
			else
				self.modAttributeRatingStar[i]:applyProfile(ModHubCategoriesFrame.PROFILE.RATING_STAR)
			end
		end
	end
	local isInstalled = modInfo:getIsInstalled()
	local versionString = modInfo:getVersionString()
	if isInstalled then
		local mod = g_modManager:getModByTitle(modInfo:getName())
		if mod ~= nil and versionString ~= mod.version then
			versionString = versionString .. " (" .. g_i18n:getText("ui_modsInstalled") .. ": " .. mod.version .. ")"
		end
	end
	self.modAttributeInfoVersion:setText(versionString, true)
	self.title = modInfo:getName()
	self.headerText:setText(self.title)
	for index, image in pairs(self.modPreviewImage) do
		self:setImage(image, modInfo:getScreenshot(index))
	end
	self.modAttributeInfoSizeSpace:setVisible(not isDLC)
	self.modAttributeInfoHashSpace:setVisible(showHash)
	self.modAttributeRatingBox:setVisible(not isDLC)
	self.modAttributeInfoRatingSpace:setVisible(not isDLC)
	self.modInfoBox:invalidateLayout()
end
function ModHubDetailsFrame:setImage(element, image)
	if image ~= nil then
		element:setImageFilename(image)
		element:setVisible(true)
	else
		element:setVisible(false)
	end
end
function ModHubDetailsFrame:getMainElementSize()
	return self.pageInformation.size
end
function ModHubDetailsFrame:getMainElementPosition()
	return self.pageInformation.absPosition
end
function ModHubDetailsFrame:onButtonBuy()
	self:openShop(false)
end
function ModHubDetailsFrame:openShop(isUpdate)
	local modInfo = self.currentModInfo
	local url = modInfo:getDLCLink()
	if GS_IS_STEAM_VERSION then
		url = modInfo:getDLCSteamLink()
	end
	if storeHasNativeGUI() then
		if not storeShow(url) then
			InfoDialog.show(g_i18n:getText("ui_dlcStoreNotConnected"), self.onStoreFailedOk, self)
		end
	else
		if isUpdate then
			url = "updates.php"
		end
		openWebFile(url, "")
	end
end
function ModHubDetailsFrame:onButtonInstall()
	local dependendMods = g_modHubController:getDependentMods(self.currentModInfo:getId())
	local dependendModNames = ""
	if 0 < #dependendMods then
		for _, modInfo in ipairs(dependendMods) do
			if modInfo:getIsInstalled() then
				continue
			end
			if dependendModNames ~= "" then
				dependendModNames = dependendModNames .. ", "
			end
			dependendModNames = dependendModNames .. modInfo:getName()
		end
	end
	if dependendModNames ~= "" then
		InfoDialog.show(string.format(g_i18n:getText("modHub_dependenciesText"), dependendModNames), self.installCurrentMod, self, DialogElement.TYPE_INFO)
	else
		self:installCurrentMod()
	end
end
function ModHubDetailsFrame:onButtonUninstall()
	local modInfo = self.currentModInfo
	if (modInfo:getIsInstalled() or modInfo:getIsDownload()) and not modInfo:getIsDLC() then
		YesNoDialog.show(ModHubDetailsFrame.uninstallYesNo, self, string.format(g_i18n:getText("modHub_uninstallModText"), modInfo:getName()), g_i18n:getText("modHub_uninstallModTitle"))
	end
end
function ModHubDetailsFrame:uninstallYesNo(yes)
	if yes then
		local modInfo = self.currentModInfo
		g_modHubController:uninstall(modInfo:getId())
	end
end
function ModHubDetailsFrame:onButtonUpdate()
	if self.currentModInfo:getIsDLC() then
		self:openShop(true)
	else
		g_modHubController:update(self.currentModInfo:getId())
	end
end
function ModHubDetailsFrame:installCurrentMod()
	local modInfo = self.currentModInfo
	local totalFilesizeKb = g_modHubController:getTotalFilesizeKb(modInfo:getId())
	local freeSpaceKb = g_modHubController:getFreeModSpaceKb()
	if freeSpaceKb < totalFilesizeKb then
		InfoDialog.show(string.format(g_i18n:getText("modHub_installNoFreeSpace"), totalFilesizeKb, freeSpaceKb))
	else
		g_modHubController:install(modInfo:getId())
	end
end
function ModHubDetailsFrame:onModInstallFailed()
	InfoDialog.show(g_i18n:getText("modHub_installFailed"))
	self:setMenuButtonInfoDirty()
end
function ModHubDetailsFrame:onDependentModInstallFailed(dependendMods)
	local failedNames = ""
	for _, dependendModInfo in ipairs(dependendMods) do
		if failedNames ~= "" then
			failedNames = failedNames .. ", "
		end
		failedNames = failedNames .. dependendModInfo:getName()
	end
	InfoDialog.show(string.format(g_i18n:getText("modHub_installDependenciesFailed"), failedNames))
end
function ModHubDetailsFrame:onAddedToDownload()
	InfoDialog.show(string.format(g_i18n:getText("modHub_addedToDownloads"), self.currentModInfo:getName()), nil, nil, DialogElement.TYPE_INFO)
	self:setMenuButtonInfoDirty()
end
function ModHubDetailsFrame:onStoreFailedOk()
	self:changeScreen(ModHubScreen)
end
function ModHubDetailsFrame:onUninstallFailed()
	InfoDialog.show(g_i18n:getText("modHub_uninstallModFailed"))
end
function ModHubDetailsFrame:onUninstalled()
	InfoDialog.show(g_i18n:getText("modHub_uninstallModSuccess"), nil, nil, DialogElement.TYPE_INFO)
	self:setMenuButtonInfoDirty()
end
function ModHubDetailsFrame:onButtonVote()
	local knownVote = g_modHubController:getVote(self.currentModInfo:getId())
	local value = knownVote ~= 0 and knownVote or 0
	VoteDialog.show(self.onVote, self, value)
end
function ModHubDetailsFrame:onButtonDownload() end
function ModHubDetailsFrame:onVote(value)
	if value ~= nil then
		g_modHubController:vote(self.currentModInfo:getId(), value)
	end
end
function ModHubDetailsFrame:onVoted()
	InfoDialog.show(g_i18n:getText("modHub_rateSuccess"))
end
function ModHubDetailsFrame:onButtonScreenshots()
	ModHubScreenshotDialog.show(self.currentModInfo)
end
ModHubDetailsFrame.L10N_SYMBOL = { BUTTON_INSTALL = "button_modHubInstall", BUTTON_UNINSTALL = "button_modHubUninstall", BUTTON_UPDATE = "button_modHubUpdate", BUTTON_BUY = "button_modHubBuy", BUTTON_DOWNLOAD = "button_modHubDownload", BUTTON_VOTE = "button_rate", BUTTON_SCREENSHOTS = "button_screenshots" }
