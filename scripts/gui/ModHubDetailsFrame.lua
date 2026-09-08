-- Local values: ModHubDetailsFrame_mt
ModHubDetailsFrame = {}
local ModHubDetailsFrame_mt = Class(ModHubDetailsFrame, TabbedMenuFrameElement)
function ModHubDetailsFrame.register()
	local v2_ = ModHubDetailsFrame.new()
	g_gui:loadGui("dataS/gui/ModHubDetailsFrame.xml", "ModHubDetailsFrame", v2_, true)
end

-- Upvalues: ModHubDetailsFrame_mt
-- Local values: self
function ModHubDetailsFrame.new(target, custom_mt)
	-- upvalues: (copy) ModHubDetailsFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or ModHubDetailsFrame_mt)
	v5_.hasCustomMenuButtons = true
	v5_.currentModInfo = nil
	v5_.scrollInputDelay = 0
	v5_.scrollInputDelayDir = 0
	return v5_
end

-- Local values: newGui
function ModHubDetailsFrame.createFromExistingGui(gui, guiName)
	local v8_ = ModHubDetailsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	v8_.hasCustomMenuButtons = gui.hasCustomMenuButtons
	return v8_
end

function ModHubDetailsFrame:initialize()
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}
	self.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = self.onPageNext
	}
	self.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = self.onPagePrevious
	}
	self.buyButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_BUY),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonBuy()
		end
	}
	self.installFreeDLCButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_INSTALL),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonBuy()
		end
	}
	self.installButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_INSTALL),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonInstall()
		end
	}
	self.uninstallButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_UNINSTALL),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonUninstall()
		end
	}
	self.updateButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_UPDATE),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonUpdate()
		end
	}
	self.downloadButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_DOWNLOAD),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonDownload()
		end
	}
	self.voteButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_2,
		["text"] = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_VOTE),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonVote()
		end
	}
	self.screenshotsButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_1,
		["text"] = g_i18n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_SCREENSHOTS),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonScreenshots()
		end
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

-- Local values: buttons, modInfo, isUpdate, isInstalled, isDownload, isDLC, priceString
function ModHubDetailsFrame:getMenuButtonInfo()
	local v12_ = {}
	local v13_ = g_modHubController:getModInfo(self.currentModInfo:getId())
	local v14_ = v13_:getIsUpdate()
	local v15_ = v13_:getIsInstalled()
	local v16_ = v13_:getIsDownload()
	local v17_ = v13_:getIsDLC()
	if not v13_:getIsExternal() and (v13_:getIsFailed() or not v16_ and (not v15_ or v14_)) then
		if v14_ then
			if not (v17_ and GS_IS_CONSOLE_VERSION) then
				local v18_ = self.updateButtonInfo
				table.insert(v12_, v18_)
			end
		elseif v17_ then
			local v19_ = v13_:getPriceString()
			if v19_ == "Free" then
				local v20_ = self.installFreeDLCButtonInfo
				table.insert(v12_, v20_)
			elseif v19_:len() > 1 then
				local v21_ = self.buyButtonInfo
				table.insert(v12_, v21_)
			end
		else
			local v22_ = self.installButtonInfo
			table.insert(v12_, v22_)
		end
	end
	local v23_ = self.backButtonInfo
	table.insert(v12_, v23_)
	local v24_ = self.nextPageButtonInfo
	table.insert(v12_, v24_)
	local v25_ = self.prevPageButtonInfo
	table.insert(v12_, v25_)
	if not v13_:getIsExternal() and (v15_ and not v17_) then
		local v26_ = self.voteButtonInfo
		table.insert(v12_, v26_)
	end
	if (v15_ or v16_) and not v17_ then
		local v27_ = self.uninstallButtonInfo
		table.insert(v12_, v27_)
	end
	if v13_:getScreenshots() ~= nil and #v13_:getScreenshots() > 0 then
		local v28_ = self.screenshotsButtonInfo
		table.insert(v12_, v28_)
	end
	return v12_
end

-- Local values: totalHeight, _numLines, isDLC, hash, showHash, filename, size, ratingScore, i, isInstalled, versionString, mod, index, image
function ModHubDetailsFrame:setModInfo(modInfo)
	self.currentModInfo = modInfo
	self.modDescription:setText(modInfo:getDescription())
	local v31_, _ = self.modDescription:getTextHeight()
	self.modDescription:setSize(nil, v31_)
	self.modDescription.parent:invalidateLayout()
	self.descriptionLayout:scrollTo(0, true)
	self.modAuthor:setText(modInfo:getAuthor())
	local v32_ = modInfo:getIsDLC()
	self.modInfoSize:setVisible(not v32_)
	local v33_ = modInfo:getHash()
	local v34_ = not v32_
	if v34_ then
		if v33_ == "" then
			v34_ = false
		else
			v34_ = not GS_IS_CONSOLE_VERSION
		end
	end
	self.modInfoHash:setVisible(v34_)
	self.modInfoHash:setText(v33_)
	local v35_ = modInfo:getFilename()
	self.modInfoFilename:setVisible(modInfo:getIsInstalled())
	self.modAttributeInfoFilenameSpace:setVisible(modInfo:getIsInstalled())
	self.modInfoFilename:setText(v35_)
	if not v32_ then
		local v36_ = modInfo:getFilesize() / 1024 / 1024
		self.modInfoSize:setText(string.format("%.02f MB", v36_))
		local v37_ = modInfo:getRatingScore() / 100
		for v38_ = 1, 5 do
			local v39_ = self.modAttributeRatingStar[v38_].elements[1]
			local v40_
			if v38_ - 0.75 <= v37_ then
				v40_ = v37_ < v38_ - 0.25
			else
				v40_ = false
			end
			v39_:setVisible(v40_)
			if v38_ - 0.25 <= v37_ then
				self.modAttributeRatingStar[v38_]:applyProfile(ModHubCategoriesFrame.PROFILE.RATING_STAR_ACTIVE)
			else
				self.modAttributeRatingStar[v38_]:applyProfile(ModHubCategoriesFrame.PROFILE.RATING_STAR)
			end
		end
	end
	local v41_ = modInfo:getIsInstalled()
	local v42_ = modInfo:getVersionString()
	if v41_ then
		local v43_ = g_modManager:getModByTitle(modInfo:getName())
		if v43_ ~= nil and v42_ ~= v43_.version then
			v42_ = v42_ .. " (" .. g_i18n:getText("ui_modsInstalled") .. ": " .. v43_.version .. ")"
		end
	end
	self.modAttributeInfoVersion:setText(v42_, true)
	self.title = modInfo:getName()
	self.headerText:setText(self.title)
	for v44_, v45_ in pairs(self.modPreviewImage) do
		self:setImage(v45_, modInfo:getScreenshot(v44_))
	end
	self.modAttributeInfoSizeSpace:setVisible(not v32_)
	self.modAttributeInfoHashSpace:setVisible(v34_)
	self.modAttributeRatingBox:setVisible(not v32_)
	self.modAttributeInfoRatingSpace:setVisible(not v32_)
	self.modInfoBox:invalidateLayout()
end

function ModHubDetailsFrame:setImage(element, image)
	if image == nil then
		element:setVisible(false)
	else
		element:setImageFilename(image)
		element:setVisible(true)
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

-- Local values: modInfo, url
function ModHubDetailsFrame:openShop(isUpdate)
	local v53_ = self.currentModInfo
	local v54_ = v53_:getDLCLink()
	if GS_IS_STEAM_VERSION then
		v54_ = v53_:getDLCSteamLink()
	end
	if storeHasNativeGUI() then
		if not storeShow(v54_) then
			InfoDialog.show(g_i18n:getText("ui_dlcStoreNotConnected"), self.onStoreFailedOk, self)
			return
		end
	else
		openWebFile(isUpdate and "updates.php" or v54_, "")
	end
end

-- Local values: dependendMods, dependendModNames, _, modInfo
function ModHubDetailsFrame:onButtonInstall()
	local v56_ = g_modHubController:getDependentMods(self.currentModInfo:getId())
	local v57_ = ""
	if #v56_ > 0 then
		for _, v58_ in ipairs(v56_) do
			if not v58_:getIsInstalled() then
				if v57_ ~= "" then
					v57_ = v57_ .. ", "
				end
				v57_ = v57_ .. v58_:getName()
			end
		end
	end
	if v57_ == "" then
		self:installCurrentMod()
	else
		InfoDialog.show(string.format(g_i18n:getText("modHub_dependenciesText"), v57_), self.installCurrentMod, self, DialogElement.TYPE_INFO)
	end
end

-- Local values: modInfo
function ModHubDetailsFrame:onButtonUninstall()
	local v60_ = self.currentModInfo
	if (v60_:getIsInstalled() or v60_:getIsDownload()) and not v60_:getIsDLC() then
		YesNoDialog.show(ModHubDetailsFrame.uninstallYesNo, self, string.format(g_i18n:getText("modHub_uninstallModText"), v60_:getName()), g_i18n:getText("modHub_uninstallModTitle"))
	end
end

-- Local values: modInfo
function ModHubDetailsFrame:uninstallYesNo(yes)
	if yes then
		local v63_ = self.currentModInfo
		g_modHubController:uninstall(v63_:getId())
	end
end

function ModHubDetailsFrame:onButtonUpdate()
	if self.currentModInfo:getIsDLC() then
		self:openShop(true)
	else
		g_modHubController:update(self.currentModInfo:getId())
	end
end

-- Local values: modInfo, totalFilesizeKb, freeSpaceKb
function ModHubDetailsFrame:installCurrentMod()
	local v66_ = self.currentModInfo
	local v67_ = g_modHubController:getTotalFilesizeKb(v66_:getId())
	local v68_ = g_modHubController:getFreeModSpaceKb()
	if v68_ < v67_ then
		InfoDialog.show(string.format(g_i18n:getText("modHub_installNoFreeSpace"), v67_, v68_))
	else
		g_modHubController:install(v66_:getId())
	end
end

function ModHubDetailsFrame:onModInstallFailed()
	InfoDialog.show(g_i18n:getText("modHub_installFailed"))
	self:setMenuButtonInfoDirty()
end

-- Local values: failedNames, _, dependendModInfo
function ModHubDetailsFrame:onDependentModInstallFailed(dependendMods)
	local v71_ = ""
	for _, v72_ in ipairs(dependendMods) do
		if v71_ ~= "" then
			v71_ = v71_ .. ", "
		end
		v71_ = v71_ .. v72_:getName()
	end
	InfoDialog.show(string.format(g_i18n:getText("modHub_installDependenciesFailed"), v71_))
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

-- Local values: knownVote, value
function ModHubDetailsFrame:onButtonVote()
	local v77_ = g_modHubController:getVote(self.currentModInfo:getId())
	local v78_ = (v77_ == 0 or not v77_) and 0 or v77_
	VoteDialog.show(self.onVote, self, v78_)
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
ModHubDetailsFrame.L10N_SYMBOL = {
	["BUTTON_INSTALL"] = "button_modHubInstall",
	["BUTTON_UNINSTALL"] = "button_modHubUninstall",
	["BUTTON_UPDATE"] = "button_modHubUpdate",
	["BUTTON_BUY"] = "button_modHubBuy",
	["BUTTON_DOWNLOAD"] = "button_modHubDownload",
	["BUTTON_VOTE"] = "button_rate",
	["BUTTON_SCREENSHOTS"] = "button_screenshots"
}
