-- Local values: ShopCategoriesFrame_mt, NO_CALLBACK
ShopCategoriesFrame = {}
local ShopCategoriesFrame_mt = Class(ShopCategoriesFrame, TabbedMenuFrameElement)
function ShopCategoriesFrame.register()
	local v2_ = ShopCategoriesFrame.new()
	g_gui:loadGui("dataS/gui/ShopCategoriesFrame.xml", "ShopCategoriesFrame", v2_, true)
end
local function NO_CALLBACK() end

-- Upvalues: ShopCategoriesFrame_mt, NO_CALLBACK
-- Local values: self
function ShopCategoriesFrame.new(target, custom_mt)
	-- upvalues: (copy) ShopCategoriesFrame_mt, (copy) NO_CALLBACK
	local v6_ = TabbedMenuFrameElement.new(target, custom_mt or ShopCategoriesFrame_mt)
	v6_.notifyActivatedCategoryCallback = NO_CALLBACK
	v6_.headerLabelText = ""
	v6_.categories = {}
	v6_.categoryTypes = {}
	v6_.useSections = true
	v6_.overlayCache = OverlayCache.new()
	return v6_
end

-- Local values: newGui
function ShopCategoriesFrame.createFromExistingGui(gui, guiName)
	local v9_ = ShopCategoriesFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_, true)
	return v9_
end

-- Upvalues: NO_CALLBACK
-- Local values: slotsVisible
function ShopCategoriesFrame:initialize(categoryTypes, categories, categoryClickedCallback, categorySelectedCallback, headerText, headerIconSlice, listCellName, listEmptyCellName)
	-- upvalues: (copy) NO_CALLBACK
	self.headerLabelText = headerText
	self.headerIconSlice = headerIconSlice
	self.listCellName = listCellName
	self.listEmptyCellName = listEmptyCellName
	self:setCategories(categoryTypes, categories, false)
	self.notifyActivatedCategoryCallback = categoryClickedCallback or NO_CALLBACK
	self.notifySelectedCategoryCallback = categorySelectedCallback or NO_CALLBACK
	if self.categoryHeaderText ~= nil then
		self.categoryHeaderText:setText(headerText)
		self.categoryHeaderText:updateAbsolutePosition()
		self.categoryHeaderIcon:setImageSlice(nil, headerIconSlice)
	end
	self:setTitle(headerText)
	local v19_ = g_currentMission.slotSystem:getAreSlotsVisible()
	self.shopSlotsIcon:setVisible(v19_)
	self.shopSlotsText:setVisible(v19_)
end

-- Local values: _, category
function ShopCategoriesFrame:setCategories(categoryTypes, categories, doReloadList)
	for _, v24_ in pairs(categoryTypes) do
		if categories[v24_.name] ~= nil then
			local v25_ = self.categoryTypes
			table.insert(v25_, v24_)
		end
	end
	self.categories = categories
	if doReloadList == nil or doReloadList == true then
		self.categoryList:reloadData()
	end
end

function ShopCategoriesFrame:onFrameOpen()
	ShopCategoriesFrame:superClass().onFrameOpen(self)
	self.notifySelectedCategoryCallback(nil)
	self.categoryList:reloadData()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.categoryList)
	self:setSoundSuppressed(false)
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end

-- Local values: balanceProfile
function ShopCategoriesFrame:setCurrentBalance(balance, balanceString)
	local v30_ = ShopMenu.GUI_PROFILE.SHOP_MONEY
	if math.floor(balance) <= -1 then
		v30_ = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
	end
	self.currentBalanceText:applyProfile(v30_, nil, true)
	self.currentBalanceText:setText(balanceString)
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end

-- Local values: slotsVisible, text, profile
function ShopCategoriesFrame:setSlotsUsage(slotsUsage, maxSlots)
	local v34_ = g_currentMission.slotSystem:getAreSlotsVisible()
	if v34_ then
		local v35_ = string.format("%0d / %0d", slotsUsage, maxSlots)
		local v36_ = ShopMenu.GUI_PROFILE.SHOP_MONEY
		if slotsUsage / maxSlots >= ShopMenu.SLOTS_USAGE_CRITICAL_THRESHOLD then
			v36_ = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
		end
		if self.shopSlotsText.profile ~= v36_ then
			self.shopSlotsText:applyProfile(v36_)
		end
		self.shopSlotsText:setText(v35_)
	end
	self.shopSlotsIcon:setVisible(v34_)
	self.shopSlotsText:setVisible(v34_)
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end

-- Local values: categoryTypeName, categoryType, category
function ShopCategoriesFrame:onOpenCategory()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	local v38_ = self.categoryTypes[self.categoryList.selectedSectionIndex].name
	local v39_ = self.categories[v38_]
	if v39_ ~= nil then
		local v40_ = v39_[self.categoryList.selectedIndex]
		if v40_ ~= nil then
			self.notifyActivatedCategoryCallback(v40_.id, self.headerLabelText, v40_.label, self.headerIconSlice, self.filter)
		end
	end
end

function ShopCategoriesFrame:onListSelectionChanged(list, section, index)
	self.notifySelectedCategoryCallback(self.categories[self.categoryTypes[section].name][index])
end

-- Local values: firstIndex
function ShopCategoriesFrame:onPageChanged(page, fromPage)
	ShopCategoriesFrame:superClass().onPageChanged(self, page, fromPage)
	local v47_ = (page - 1) * (self.categoryList.numVisibleItems * self.categoryList.itemsPerCol) + 1
	self.categoryList:scrollTo(v47_)
end

function ShopCategoriesFrame:getNumberOfSections(list)
	return #self.categoryTypes
end

function ShopCategoriesFrame:getNumberOfItemsInSection(list, section)
	return self.categories[self.categoryTypes[section].name] ~= nil and #self.categories[self.categoryTypes[section].name] or 0
end

-- Local values: category, attr
function ShopCategoriesFrame:populateCellForItemInSection(list, section, index, cell)
	local v55_ = self.categories[self.categoryTypes[section].name][index]
	if Platform.isMobile then
		if self.id == "pageShopVehicles" then
			cell:getAttribute("icon"):applyProfile("shopCategoryItemImageVehicle")
		else
			cell:getAttribute("icon"):applyProfile("shopCategoryItemImageBrand")
		end
	end
	cell:getAttribute("title"):setText(v55_.label)
	cell:getAttribute("icon"):setImageFilename(v55_.iconFilename)
	self.overlayCache:addOverlay(v55_.iconFilename)
	local v56_ = cell:getAttribute("coinBg")
	if v56_ ~= nil then
		local v57_ = Platform.hasInAppPurchases
		if v57_ then
			v57_ = v55_.id == "COINS"
		end
		v56_:setVisible(v57_)
	end
end

function ShopCategoriesFrame:getTitleForSectionHeader(list, section)
	return self.categoryTypes[section].title or self.categoryTypes[section].name or ""
end

function ShopCategoriesFrame:getCellTypeForItemInSection(list, section, index)
	return self.listCellName
end

function ShopCategoriesFrame:getEmptyCellType(list)
	if list == self.categoryList then
		return self.listEmptyCellName
	else
		return nil
	end
end
