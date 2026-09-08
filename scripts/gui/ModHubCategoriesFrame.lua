-- Local values: ModHubCategoriesFrame_mt, NO_CALLBACK
ModHubCategoriesFrame = {}
local ModHubCategoriesFrame_mt = Class(ModHubCategoriesFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
ModHubCategoriesFrame.SUB_CATEGORY = {
	["CATEGORIES"] = 1,
	["BEST"] = 2,
	["MOST_DOWNLOADED"] = 3,
	["LATEST"] = 4,
	["RECOMMENDED"] = 5
}
function ModHubCategoriesFrame.register()
	local v3_ = ModHubCategoriesFrame.new()
	g_gui:loadGui("dataS/gui/ModHubCategoriesFrame.xml", "ModHubCategoriesFrame", v3_, true)
end

-- Upvalues: ModHubCategoriesFrame_mt, NO_CALLBACK
-- Local values: self
function ModHubCategoriesFrame.new(target, custom_mt)
	-- upvalues: (copy) ModHubCategoriesFrame_mt, (copy) NO_CALLBACK
	local v6_ = TabbedMenuFrameElement.new(target, custom_mt or ModHubCategoriesFrame_mt)
	v6_.notifyActivatedCategoryCallback = NO_CALLBACK
	v6_.notifySearchCallback = NO_CALLBACK
	v6_.notifyToggleBetaCallback = NO_CALLBACK
	v6_.categories = {}
	v6_.categoryTypes = {}
	v6_.categoryName = ""
	v6_.notifyActivatedModItemCallback = NO_CALLBACK
	v6_.notifySelectedModItemCallback = NO_CALLBACK
	v6_.notifySearchCallback = NO_CALLBACK
	v6_.notifyToggleBetaCallback = NO_CALLBACK
	v6_.setModItems = nil
	v6_.mods = {}
	return v6_
end

-- Local values: newGui
function ModHubCategoriesFrame.createFromExistingGui(gui, guiName)
	local v9_ = ModHubCategoriesFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_, true)
	return v9_
end

-- Upvalues: NO_CALLBACK
-- Local values: index, button
function ModHubCategoriesFrame:initialize(categories, categoryClickedCallback, headerText, iconHeightWidthRatio)
	-- upvalues: (copy) NO_CALLBACK
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
		["text"] = g_i18n:getText(ModHubCategoriesFrame.L10N_SYMBOL.BUTTON_DETAILS),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonDetails()
		end
	}
	self.detailsButtonDisabledInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ModHubCategoriesFrame.L10N_SYMBOL.BUTTON_DETAILS),
		["callback"] = nil,
		["disabled"] = true
	}
	self.searchButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_2,
		["text"] = g_i18n:getText("button_search"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonSearch()
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
	self.iconHeightWidthRatio = iconHeightWidthRatio
	self.notifyActivatedCategoryCallback = categoryClickedCallback or NO_CALLBACK
	self:setCategories(categories)
	for v_u_14_, v15_ in pairs(self.subCategoryTabs) do
		v15_:getDescendantByName("background").getIsSelected = function()
			-- upvalues: (copy) v_u_14_, (copy) self
			return v_u_14_ == self.subCategoryPaging:getState()
		end
		function v15_.getIsSelected()
			-- upvalues: (copy) v_u_14_, (copy) self
			return v_u_14_ == self.subCategoryPaging:getState()
		end
	end
	if g_i18n:hasText("modHub_authorDisclaimer") then
		self.disclaimerLabel:setText(g_i18n:getText("modHub_abuse") .. " " .. g_i18n:getText("modHub_authorDisclaimer"))
	end
	self:updateSubCategoryPages(1)
end

function ModHubCategoriesFrame:setCategories(categories)
	self.categories = categories
	self.categoryTypes = g_modHubController:getCategoryTypes()
	self.categoryList:reloadData()
	self:setMenuButtonInfoDirty()
end

function ModHubCategoriesFrame:onFrameOpen()
	ModHubCategoriesFrame:superClass().onFrameOpen(self)
	self.isOpening = true
	self:updateSubCategoryPages(self.subCategoryPaging:getState())
	self.isOpening = false
	self:setMenuButtonInfoDirty()
	self.subCategoryBox:invalidateLayout()
	self.subCategoryPaging:setTexts(ModHubCategoriesFrame.HEADER_TITLES)
	self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
end

function ModHubCategoriesFrame:updateList()
	if self.forcedModItems == nil then
		self.mods = g_modHubController:getModsByCategory(self.categoryId, true)
	else
		self.mods = self.forcedModItems
	end
	self.itemList:reloadData(true)
	local v20_ = self.modAttributeBox
	local v21_
	if self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES then
		v21_ = false
	else
		v21_ = self.itemList:getItemCount() > 0
	end
	v20_:setVisible(v21_)
	self:setMenuButtonInfoDirty()
end

function ModHubCategoriesFrame:reload()
	if self.subCategoryPaging:getState() ~= ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES then
		self:updateList()
	end
end

function ModHubCategoriesFrame:reset()
	self:onClickCategories()
	self.categoryList:setSelectedItem(1, 1, nil, true)
	self.categoryList:makeCellVisible(1, 1)
end

function ModHubCategoriesFrame:getMainElementSize()
	return self.categoryList.size
end

function ModHubCategoriesFrame:getMainElementPosition()
	return self.categoryList.absPosition
end

-- Upvalues: NO_CALLBACK
-- Local values: buttons
function ModHubCategoriesFrame:getMenuButtonInfo()
	-- upvalues: (copy) NO_CALLBACK
	local v27_ = {}
	if #self.categories > 0 then
		if self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES or self.itemList:getItemCount() ~= 0 then
			local v28_ = self.detailsButtonInfo
			table.insert(v27_, v28_)
		else
			local v29_ = self.detailsButtonDisabledInfo
			table.insert(v27_, v29_)
		end
	end
	local v30_ = self.backButtonInfo
	table.insert(v27_, v30_)
	local v31_ = self.nextPageButtonInfo
	table.insert(v27_, v31_)
	local v32_ = self.prevPageButtonInfo
	table.insert(v27_, v32_)
	if self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES or self.notifySearchCallback ~= NO_CALLBACK then
		local v33_ = self.searchButtonInfo
		table.insert(v27_, v33_)
	end
	if Platform.allowsScriptMods then
		self.toggleTopButtonInfo.text = self.getBetaToggleText()
		local v34_ = self.toggleTopButtonInfo
		table.insert(v27_, v34_)
	end
	return v27_
end

-- Upvalues: NO_CALLBACK
function ModHubCategoriesFrame:setItemClickCallback(itemClickedCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.notifyActivatedModItemCallback = itemClickedCallback or NO_CALLBACK
end

-- Upvalues: NO_CALLBACK
function ModHubCategoriesFrame:setItemSelectCallback(itemSelectedCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.notifySelectedModItemCallback = itemSelectedCallback or NO_CALLBACK
end

function ModHubCategoriesFrame:setSearchCallback(searchCallback)
	self.notifySearchCallback = searchCallback
end

function ModHubCategoriesFrame:setToggleBetaCallback(callback)
	self.notifyToggleBetaCallback = callback
end

function ModHubCategoriesFrame:setBetaToggleTextCallback(callback)
	self.getBetaToggleText = callback
end

function ModHubCategoriesFrame:setCategory(categoryName)
	self.categoryName = categoryName
end

function ModHubCategoriesFrame:setCategoryId(categoryId)
	self.categoryId = categoryId
end

function ModHubCategoriesFrame:setModItems(modItems)
	self.forcedModItems = modItems
end

-- Local values: state
function ModHubCategoriesFrame:updateListSizeLimit(limit)
	local v52_ = self.subCategoryPaging:getState()
	if v52_ == ModHubCategoriesFrame.SUB_CATEGORY.BEST or (v52_ == ModHubCategoriesFrame.SUB_CATEGORY.LATEST or v52_ == ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED) then
		self.listSizeLimit = ModHubScreen.SPECIAL_LIST_LIMIT
	else
		self.listSizeLimit = nil
	end
end

-- Local values: modInfo
function ModHubCategoriesFrame:onActivateItem()
	local v54_ = self.mods[self.itemList.selectedIndex]
	if v54_ ~= nil then
		self.notifyActivatedModItemCallback(self, v54_.modId, self.categoryName)
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	end
end

-- Local values: category
function ModHubCategoriesFrame:onActivateCategory()
	local v56_ = self.categories[self.categoryList.selectedSectionIndex][self.categoryList.selectedIndex]
	self.notifyActivatedCategoryCallback(v56_.id, v56_.name)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end

-- Local values: modItem
function ModHubCategoriesFrame:onListSelectionChanged(list, section, index)
	if list == self.itemList then
		local v60_ = self.mods[index]
		if v60_ ~= nil then
			self.notifySelectedModItemCallback(self, v60_.modId)
		end
	end
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

-- Local values: isDLC, isTop, priceVisible, size, ratingScore, i, priceString
function ModHubCategoriesFrame:setModInfo(modInfo)
	if self.modAttributeName ~= nil then
		self.modAttributeName:setText(modInfo:getName(), true)
		self.modAttributeInfoAuthor:setText(modInfo:getAuthor(), true)
		self.modAttributeInfoVersion:setText(modInfo:getVersionString(), true)
		local v63_ = modInfo:getIsDLC()
		local v64_ = modInfo:getIsTop()
		if v63_ then
			local v65_ = modInfo:getPriceString()
			self.modAttributePrice:setText(v65_, true)
			if v65_:len() > 1 then
				v64_ = true
			else
				v64_ = false
			end
		else
			local v66_ = modInfo:getFilesize() / 1024 / 1024
			self.modAttributeInfoSize:setText(string.format("%.02f MB", v66_), true)
			local v67_ = modInfo:getRatingScore() / 100
			for v68_ = 1, 5 do
				local v69_ = self.modAttributeRatingStar[v68_].elements[1]
				local v70_
				if v68_ - 0.75 <= v67_ then
					v70_ = v67_ < v68_ - 0.25
				else
					v70_ = false
				end
				v69_:setVisible(v70_)
				if v68_ - 0.25 <= v67_ then
					self.modAttributeRatingStar[v68_]:applyProfile(ModHubCategoriesFrame.PROFILE.RATING_STAR_ACTIVE)
				else
					self.modAttributeRatingStar[v68_]:applyProfile(ModHubCategoriesFrame.PROFILE.RATING_STAR)
				end
			end
			self.modAttributePrice:setText(g_i18n:getText("modHub_flag_crossplay"), true)
		end
		self.modAttributeInfoSize:setVisible(not v63_)
		self.modAttributeInfoSizeSpace:setVisible(not v63_)
		self.modAttributeRatingBox:setVisible(not v63_)
		self.modAttributeInfoRatingSpace:setVisible(not v63_)
		self.modAttributePrice:setVisible(v64_)
		self.modAttributeInfoPriceSpace:setVisible(v64_)
		self.modAttributeBox:invalidateLayout()
	end
end

function ModHubCategoriesFrame:onButtonDetails()
	if self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES then
		self:onActivateCategory()
	else
		self:onActivateItem()
	end
end

function ModHubCategoriesFrame:onButtonSearch()
	self.notifySearchCallback()
end

function ModHubCategoriesFrame:onButtonShowToggle()
	self.notifyToggleBetaCallback(self)
end

-- Local values: isCategoriesPage, categoryName, category
function ModHubCategoriesFrame:updateSubCategoryPages(subCategoryIndex)
	self.categoryHeaderIcon:setImageSlice(nil, ModHubCategoriesFrame.HEADER_SLICES[subCategoryIndex])
	self.categoryHeaderTitle:setText(g_i18n:getText(ModHubCategoriesFrame.HEADER_TITLES[subCategoryIndex]))
	self.modAttributeBox:setVisible(self.subCategoryPaging:getState() ~= ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES)
	self:updateListSizeLimit()
	local v76_ = self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES
	self.categoryListContainer:setVisible(v76_)
	self.itemListContainer:setVisible(not v76_)
	if v76_ then
		g_modHubController:reload()
		self.categoryList:reloadData(true)
		self.slider:setDataElement(self.categoryList)
		if not self.isOpening then
			self.categoryList:setSelectedItem(1, 1, nil, true)
			self.categoryList:makeCellVisible(1, 1)
		end
	else
		local v77_ = ModHubCategoriesFrame.CATEGORY_IDS[subCategoryIndex]
		local v78_ = g_modHubController:getCategory(v77_)
		self:setCategory(v77_)
		self:setCategoryId(v78_.id)
		g_modHubController:loadCategory(v78_.id)
		self:updateList()
		self.slider:setDataElement(self.itemList)
		if not self.isOpening then
			self.itemList:setSelectedIndex(1, nil, true)
			self.itemList:makeCellVisible(1, 1)
		end
	end
	local v79_ = self.noModsElement
	local v80_ = not v76_
	if v80_ then
		v80_ = #self.mods == 0
	end
	v79_:setVisible(v80_)
end

function ModHubCategoriesFrame:onClickCategories()
	self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES, true)
end

function ModHubCategoriesFrame:onClickBest()
	self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.BEST, true)
end

function ModHubCategoriesFrame:onClickMostDownloaded()
	self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED, true)
end

function ModHubCategoriesFrame:onClickLatest()
	self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.LATEST, true)
end

function ModHubCategoriesFrame:onClickRecommended()
	self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.RECOMMENDED, true)
end

function ModHubCategoriesFrame:getNumberOfSections(list)
	return list == self.categoryList and #self.categoryTypes or 1
end

function ModHubCategoriesFrame:getTitleForSectionHeader(list, section)
	return g_modHubController.categoryTypeNameMapping[self.categoryTypes[section]] or ""
end

-- Local values: total
function ModHubCategoriesFrame:getNumberOfItemsInSection(list, section)
	if list == self.categoryList then
		return #self.categories[section]
	end
	local v93_ = #self.mods
	if self.listSizeLimit == nil then
		return v93_
	end
	local v94_ = self.listSizeLimit
	return math.min(v93_, v94_)
end

-- Local values: category, iconElement, modInfo, numUpdates, numNew, numConflicts, markerElement, iconElement
function ModHubCategoriesFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.categoryList then
		local v100_ = self.categories[section][index]
		cell:getAttribute("markerNew"):setVisible(v100_.numNewItems > 0)
		cell:getAttribute("markerUpdate"):setVisible(v100_.numAvailableUpdates > 0)
		cell:getAttribute("markerConflict"):setVisible(v100_.numConflictedItems > 0)
		cell:getAttribute("markerBox"):invalidateLayout()
		local v101_ = cell:getAttribute("image")
		v101_:setImageFilename(v100_.iconFilename)
		v101_:setSize(nil, v101_.size[2] * (self.iconHeightWidthRatio or 1))
		cell:getAttribute("text"):setText(v100_.label)
	else
		local v102_ = self.mods[index]
		local v103_ = v102_:getNumUpdates()
		local v104_ = v102_:getNumNew()
		local v105_ = v102_:getNumConflicts()
		local v106_ = cell:getAttribute("markerNew")
		v106_:setVisible((v103_ > 0 or v104_ > 0) and true or v105_ > 0)
		if v105_ > 0 then
			v106_:applyProfile("fs25_modHubMarkerConflict")
		elseif v103_ > 0 then
			v106_:applyProfile("fs25_modHubMarkerUpdate")
		elseif v104_ > 0 then
			v106_:applyProfile("fs25_modHubMarkerNew")
		end
		cell:getAttribute("markerBox"):invalidateLayout()
		local v107_ = cell:getAttribute("icon")
		v107_:setIsWebOverlay(not v102_:getIsIconLocal())
		v107_:setImageFilename(v102_:getIconFilename())
		cell:getAttribute("nameLabel"):setText(v102_:getName())
		cell:getAttribute("dlcTag"):setVisible(v102_:getIsDLC())
		cell:getAttribute("installedIcon"):setVisible(v102_:getIsInstalled())
	end
end
ModHubCategoriesFrame.HEADER_SLICES = {
	[ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES] = "gui.modhub_categories",
	[ModHubCategoriesFrame.SUB_CATEGORY.BEST] = "gui.modHub_best",
	[ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED] = "gui.modHub_mostDownloaded",
	[ModHubCategoriesFrame.SUB_CATEGORY.LATEST] = "gui.modHub_latest",
	[ModHubCategoriesFrame.SUB_CATEGORY.RECOMMENDED] = "gui.modHub_recommended"
}
ModHubCategoriesFrame.HEADER_TITLES = {
	[ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES] = "ui_modHubCategories",
	[ModHubCategoriesFrame.SUB_CATEGORY.BEST] = "modHub_best",
	[ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED] = "modHub_most_downloaded",
	[ModHubCategoriesFrame.SUB_CATEGORY.LATEST] = "modHub_latest",
	[ModHubCategoriesFrame.SUB_CATEGORY.RECOMMENDED] = "category_recommended"
}
ModHubCategoriesFrame.CATEGORY_IDS = {
	[ModHubCategoriesFrame.SUB_CATEGORY.BEST] = "best",
	[ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED] = "most_downloaded",
	[ModHubCategoriesFrame.SUB_CATEGORY.LATEST] = "latest",
	[ModHubCategoriesFrame.SUB_CATEGORY.RECOMMENDED] = "recommended"
}
ModHubCategoriesFrame.PROFILE = {
	["RATING_STAR_ACTIVE"] = "fs25_modHubAttributeRatingStarActive",
	["RATING_STAR"] = "fs25_modHubAttributeRatingStar"
}
ModHubCategoriesFrame.L10N_SYMBOL = {
	["STATUS_PENDING"] = "modHub_pending",
	["STATUS_UPDATE"] = "modHub_update",
	["STATUS_INSTALLED"] = "modHub_installed",
	["STATUS_FAILED"] = "modHub_failed",
	["BUTTON_DETAILS"] = "button_detail",
	["BUTTON_SHOW_ALL"] = "button_modHubShowAll",
	["BUTTON_SHOW_TOP"] = "button_modHubShowTop"
}
