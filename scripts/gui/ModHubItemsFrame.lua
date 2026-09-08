-- Local values: ShopItemsFrame_mt, NO_CALLBACK
ModHubItemsFrame = {}
local ShopItemsFrame_mt = Class(ModHubItemsFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
function ModHubItemsFrame.register()
	local v3_ = ModHubItemsFrame.new()
	g_gui:loadGui("dataS/gui/ModHubItemsFrame.xml", "ModHubItemsFrame", v3_, true)
end

-- Upvalues: ShopItemsFrame_mt, NO_CALLBACK
-- Local values: self
function ModHubItemsFrame.new(target, custom_mt)
	-- upvalues: (copy) ShopItemsFrame_mt, (copy) NO_CALLBACK
	local v6_ = TabbedMenuFrameElement.new(target, custom_mt or ShopItemsFrame_mt)
	v6_.categoryName = ""
	v6_.updateModInterval = 1000
	v6_.updateModTimer = v6_.updateModInterval
	v6_.notifyActivatedModItemCallback = NO_CALLBACK
	v6_.notifySelectedModItemCallback = NO_CALLBACK
	v6_.notifySearchCallback = NO_CALLBACK
	v6_.notifyToggleBetaCallback = NO_CALLBACK
	v6_.setModItems = nil
	v6_.mods = {}
	return v6_
end

-- Local values: newGui
function ModHubItemsFrame.createFromExistingGui(gui, guiName)
	local v9_ = ModHubItemsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_, true)
	return v9_
end

function ModHubItemsFrame:initialize(headerIconSliceId)
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
	self.detailsButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ModHubItemsFrame.L10N_SYMBOL.BUTTON_DETAILS),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonDetails()
		end
	}
	self.searchButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_2,
		["text"] = g_i18n:getText("button_search"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonSearch()
		end
	}
	self.updateAllButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(ModHubItemsFrame.L10N_SYMBOL.BUTTON_UPDATE_ALL),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonUpdateAll()
		end
	}
	self.toggleTopButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_1,
		["text"] = "",
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonShowToggle()
		end
	}
	self.deleteAllButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_1,
		["text"] = "Delete All Mods",
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonDeleteAllMods()
		end
	}
	if headerIconSliceId ~= nil then
		self.headerIcon:setImageSlice(nil, headerIconSliceId)
	end
	if g_i18n:hasText("modHub_authorDisclaimer") then
		self.disclaimerLabel:setText(g_i18n:getText("modHub_abuse") .. " " .. g_i18n:getText("modHub_authorDisclaimer"))
	end
end

function ModHubItemsFrame:onFrameOpen()
	ModHubItemsFrame:superClass().onFrameOpen(self)
	if self.categoryId ~= nil then
		g_modHubController:loadCategory(self.categoryId)
	end
	self:updateList()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.itemsList)
	self:setSoundSuppressed(false)
	g_modHubController:setAddedToDownloadCallback(self.setMenuButtonInfoDirty, self)
end

-- Upvalues: NO_CALLBACK
-- Local values: buttons, _, modInfo
function ModHubItemsFrame:getMenuButtonInfo()
	-- upvalues: (copy) NO_CALLBACK
	local v14_ = {}
	if #self.mods > 0 then
		local v15_ = self.detailsButtonInfo
		table.insert(v14_, v15_)
	end
	local v16_ = self.backButtonInfo
	table.insert(v14_, v16_)
	local v17_ = self.nextPageButtonInfo
	table.insert(v14_, v17_)
	local v18_ = self.prevPageButtonInfo
	table.insert(v14_, v18_)
	if self.categoryName == "update" then
		for _, v19_ in pairs(self.mods) do
			if not v19_:getIsExternal() and (Platform.isPC or not v19_:getIsDLC()) then
				local v20_ = self.updateAllButtonInfo
				table.insert(v14_, v20_)
				break
			end
		end
	end
	if self.notifySearchCallback ~= NO_CALLBACK then
		local v21_ = self.searchButtonInfo
		table.insert(v14_, v21_)
	end
	if Platform.allowsScriptMods and (self.notifyToggleBetaCallback ~= NO_CALLBACK and (self.forcedModItems == nil and self.categoryName ~= "testing")) then
		self.toggleTopButtonInfo.text = self.getBetaToggleText()
		local v22_ = self.toggleTopButtonInfo
		table.insert(v14_, v22_)
	end
	if self.categoryName == "testing" then
		local v23_ = self.deleteAllButtonInfo
		table.insert(v14_, v23_)
	end
	return v14_
end

-- Upvalues: NO_CALLBACK
function ModHubItemsFrame:setItemClickCallback(itemClickedCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.notifyActivatedModItemCallback = itemClickedCallback or NO_CALLBACK
end

-- Upvalues: NO_CALLBACK
function ModHubItemsFrame:setItemSelectCallback(itemSelectedCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.notifySelectedModItemCallback = itemSelectedCallback or NO_CALLBACK
end

function ModHubItemsFrame:setSearchCallback(searchCallback)
	self.notifySearchCallback = searchCallback
end

function ModHubItemsFrame:setToggleBetaCallback(callback)
	self.notifyToggleBetaCallback = callback
end

function ModHubItemsFrame:setBetaToggleTextCallback(callback)
	self.getBetaToggleText = callback
end

function ModHubItemsFrame:setCategory(categoryName)
	self.categoryName = categoryName
	self.headerText:setText(g_modHubController:getCategory(categoryName).label)
end

function ModHubItemsFrame:setCategoryId(categoryId)
	self.categoryId = categoryId
end

function ModHubItemsFrame:setModItems(modItems)
	self.forcedModItems = modItems
end

function ModHubItemsFrame:setListSizeLimit(limit)
	self.listSizeLimit = limit
end

function ModHubItemsFrame:reload()
	self:updateList()
end

function ModHubItemsFrame:updateList()
	if self.forcedModItems == nil then
		self.mods = g_modHubController:getModsByCategory(self.categoryId, true)
	else
		self.mods = self.forcedModItems
	end
	self.itemsList:reloadData()
	self.modAttributeBox:setVisible(#self.mods > 0)
	self.noModsElement:setVisible(#self.mods == 0)
	self:setMenuButtonInfoDirty()
end

function ModHubItemsFrame:getMainElementSize()
	return self.modAttributeBox.size
end

function ModHubItemsFrame:getMainElementPosition()
	return self.modAttributeBox.absPosition
end

-- Local values: modInfo
function ModHubItemsFrame:onActivateItem(_, clickedElement)
	local v47_ = self.mods[self.itemsList.selectedIndex]
	self.notifyActivatedModItemCallback(self, v47_.modId, self.categoryName)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end

function ModHubItemsFrame:onButtonDetails()
	self:onActivateItem()
end

function ModHubItemsFrame:onClickLeft()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem - self.itemsList.itemsPerCol)
end

function ModHubItemsFrame:onClickRight()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol)
end

-- Local values: modItem
function ModHubItemsFrame:onListSelectionChanged(list, section, index)
	local v53_ = self.mods[index]
	if v53_ ~= nil then
		self.notifySelectedModItemCallback(self, v53_.modId)
	end
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

-- Local values: isInstalled, versionString, mod, isDLC, isTop, priceVisible, size, ratingScore, i, priceString
function ModHubItemsFrame:setModInfo(modInfo)
	if self.modAttributeName ~= nil then
		self.modAttributeName:setText(modInfo:getName(), true)
		self.modAttributeInfoAuthor:setText(modInfo:getAuthor(), true)
		local v56_ = modInfo:getIsInstalled()
		local v57_ = modInfo:getVersionString()
		if v56_ then
			local v58_ = g_modManager:getModByTitle(modInfo:getName())
			if v58_ ~= nil and v57_ ~= v58_.version then
				v57_ = v57_ .. " (" .. g_i18n:getText("ui_modsInstalled") .. ": " .. v58_.version .. ")"
			end
		end
		self.modAttributeInfoVersion:setText(v57_, true)
		local v59_ = modInfo:getIsDLC()
		local v60_ = modInfo:getIsTop()
		if v59_ then
			local v61_ = modInfo:getPriceString()
			self.modAttributePrice:setText(v61_, true)
			if v61_:len() > 1 then
				v60_ = true
			else
				v60_ = false
			end
		else
			local v62_ = modInfo:getFilesize() / 1024 / 1024
			self.modAttributeInfoSize:setText(string.format("%.02f MB", v62_), true)
			local v63_ = modInfo:getRatingScore() / 100
			for v64_ = 1, 5 do
				local v65_ = self.modAttributeRatingStar[v64_].elements[1]
				local v66_
				if v64_ - 0.75 <= v63_ then
					v66_ = v63_ < v64_ - 0.25
				else
					v66_ = false
				end
				v65_:setVisible(v66_)
				if v64_ - 0.25 <= v63_ then
					self.modAttributeRatingStar[v64_]:applyProfile(ModHubItemsFrame.PROFILE.RATING_STAR_ACTIVE)
				else
					self.modAttributeRatingStar[v64_]:applyProfile(ModHubItemsFrame.PROFILE.RATING_STAR)
				end
			end
			self.modAttributePrice:setText(g_i18n:getText("modHub_flag_crossplay"), true)
		end
		self.modAttributeInfoSize:setVisible(not v59_)
		self.modAttributeInfoSizeSpace:setVisible(not v59_)
		self.modAttributeRatingBox:setVisible(not v59_)
		self.modAttributeInfoRatingSpace:setVisible(not v59_)
		self.modAttributePrice:setVisible(v60_)
		self.modAttributeInfoPriceSpace:setVisible(v60_)
		self.modAttributeBox:invalidateLayout()
	end
end

function ModHubItemsFrame:onButtonSearch()
	self.notifySearchCallback(self.categoryId)
end

function ModHubItemsFrame:onButtonUpdateAll()
	YesNoDialog.show(self.onYesNoUpdateAll, self, g_i18n:getText("modHub_updateAllDialog"), g_i18n:getText("modHub_updateAll"))
end

-- Local values: _, modInfo
function ModHubItemsFrame:onYesNoUpdateAll(yes)
	if yes then
		for _, v71_ in pairs(self.mods) do
			if not v71_:getIsExternal() and (Platform.isPC or not v71_:getIsDLC()) then
				g_modHubController:update(v71_:getId())
			end
		end
	end
end

function ModHubItemsFrame:onButtonShowToggle()
	self.notifyToggleBetaCallback(self)
end

function ModHubItemsFrame:onButtonDeleteAllMods()
	YesNoDialog.show(self.onYesNoDeleteAllMods, self, "Are you sure you want to delete all mods? this will delete any mod installed on this device", "Delete all mods", nil, nil, DialogElement.TYPE_WARNING)
end

-- Local values: mods, dummy, _, mod
function ModHubItemsFrame:onYesNoDeleteAllMods(yes)
	if yes then
		local v76_ = g_modHubController:getModsByCategory(g_modHubController:getCategory("installed").id)
		local function v77_() end
		g_modHubController:setUninstallFailedCallback(v77_, nil)
		g_modHubController:setUninstalledCallback(v77_, nil)
		for _, v78_ in pairs(v76_) do
			g_modHubController:uninstall(v78_.modId)
		end
		self:reload()
	end
end

-- Local values: total
function ModHubItemsFrame:getNumberOfItemsInSection(list, section)
	local v80_ = #self.mods
	if self.listSizeLimit == nil then
		return v80_
	end
	local v81_ = self.listSizeLimit
	return math.min(v80_, v81_)
end

-- Local values: modInfo, numUpdates, numNew, numConflicts, markerElement, iconElement
function ModHubItemsFrame:populateCellForItemInSection(list, section, index, cell)
	local v85_ = self.mods[index]
	local v86_ = v85_:getNumUpdates()
	local v87_ = v85_:getNumNew()
	local v88_ = v85_:getNumConflicts()
	local v89_ = cell:getAttribute("markerNew")
	v89_:setVisible((v86_ > 0 or v87_ > 0) and true or v88_ > 0)
	if v88_ > 0 then
		v89_:applyProfile("fs25_modHubMarkerConflict")
	elseif v86_ > 0 then
		v89_:applyProfile("fs25_modHubMarkerUpdate")
	elseif v87_ > 0 then
		v89_:applyProfile("fs25_modHubMarkerNew")
	end
	cell:getAttribute("markerBox"):invalidateLayout()
	local v90_ = cell:getAttribute("icon")
	v90_:setIsWebOverlay(not v85_:getIsIconLocal())
	v90_:setImageFilename(v85_:getIconFilename())
	cell:getAttribute("nameLabel"):setText(v85_:getName())
	cell:getAttribute("dlcTag"):setVisible(v85_:getIsDLC())
	cell:getAttribute("installedIcon"):setVisible(v85_:getIsInstalled())
end
ModHubItemsFrame.PROFILE = {
	["LIST_ITEM_NEUTRAL"] = "modHubItemsListItem",
	["LIST_ITEM_SELECTED"] = "modHubItemsListItemSelected",
	["RATING_STAR_ACTIVE"] = "fs25_modHubAttributeRatingStarActive",
	["RATING_STAR"] = "fs25_modHubAttributeRatingStar"
}
ModHubItemsFrame.L10N_SYMBOL = {
	["STATUS_PENDING"] = "modHub_pending",
	["STATUS_UPDATE"] = "modHub_update",
	["STATUS_INSTALLED"] = "modHub_installed",
	["STATUS_FAILED"] = "modHub_failed",
	["BUTTON_DETAILS"] = "button_detail",
	["BUTTON_UPDATE_ALL"] = "modHub_updateAll",
	["BUTTON_SHOW_ALL"] = "button_modHubShowAll",
	["BUTTON_SHOW_TOP"] = "button_modHubShowTop"
}
