-- Local values: ShopItemsFrame_mt, NO_CALLBACK
ShopItemsFrame = {}
local ShopItemsFrame_mt = Class(ShopItemsFrame, TabbedMenuFrameElement)
ShopItemsFrame.CELL_NAME_DETAIL = "detailTemplate"
ShopItemsFrame.CELL_NAME_VALUE = "valueTemplate"
ShopItemsFrame.CELL_NAME_FILL_TYPES = "fillTypesTemplate"
local function NO_CALLBACK() end
function ShopItemsFrame.register()
	local v3_ = ShopItemsFrame.new()
	g_gui:loadGui("dataS/gui/ShopItemsFrame.xml", "ShopItemsFrame", v3_, true)
end

-- Upvalues: ShopItemsFrame_mt, NO_CALLBACK
-- Local values: self
function ShopItemsFrame.new(target, custom_mt)
	-- upvalues: (copy) ShopItemsFrame_mt, (copy) NO_CALLBACK
	local v6_ = ShopItemsFrame:superClass().new(target, custom_mt or ShopItemsFrame_mt)
	v6_.notifyActivatedDisplayItemCallback = NO_CALLBACK
	v6_.notifySelectedDisplayItemCallback = NO_CALLBACK
	v6_.displayItems = {}
	v6_.detailsCache = {}
	v6_.detailsTemplates = {}
	v6_.clonedElements = {}
	v6_.marqueeBoxes = {}
	v6_.overlayCache = OverlayCache.new()
	return v6_
end

-- Local values: newGui
function ShopItemsFrame.createFromExistingGui(gui, guiName)
	local v9_ = ShopItemsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_, true)
	return v9_
end

-- Local values: slotsVisible
function ShopItemsFrame:initialize()
	local v11_ = g_currentMission.slotSystem:getAreSlotsVisible()
	self.shopSlotsIcon:setVisible(v11_)
	self.shopSlotsText:setVisible(v11_)
	self:buildCellDatabase()
end

-- Local values: k, clone, k, clone, k, cell, l, clone
function ShopItemsFrame:delete()
	for v13_, v14_ in pairs(self.clonedElements) do
		v14_:delete()
		self.clonedElements[v13_] = nil
	end
	for v15_, v16_ in pairs(self.detailsTemplates) do
		v16_:delete()
		self.detailsTemplates[v15_] = nil
	end
	for v17_, v18_ in pairs(self.detailsCache) do
		for v19_, v20_ in pairs(v18_) do
			v20_:delete()
			self.detailsCache[v17_][v19_] = nil
		end
		self.detailsCache[v17_] = nil
	end
	ShopItemsFrame:superClass().delete(self)
end

function ShopItemsFrame:onFrameOpen()
	ShopItemsFrame:superClass().onFrameOpen(self)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.itemsList)
	self:setSoundSuppressed(false)
	self.detailBox:setVisible(#self.displayItems > 0)
	self.noItemsText:setVisible(#self.displayItems == 0)
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
		self.itemsHeaderText:setSize(self.itemsHeaderText.parent.absSize[1] - self.shopMoneyBoxBg.absSize[1] - 180 * g_pixelSizeScaledX)
	end
end

function ShopItemsFrame:onFrameClose()
	ShopItemsFrame:superClass().onFrameClose(self)
	self.overlayCache:clearCache()
end

-- Upvalues: NO_CALLBACK
function ShopItemsFrame:setItemClickCallback(itemClickedCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.notifyActivatedDisplayItemCallback = itemClickedCallback or NO_CALLBACK
end

-- Upvalues: NO_CALLBACK
function ShopItemsFrame:setItemSelectCallback(itemSelectedCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.notifySelectedDisplayItemCallback = itemSelectedCallback or NO_CALLBACK
end

function ShopItemsFrame:setHeader(headerText, headerIconSlice)
	self.itemsHeaderText:setText(headerText)
	self.itemsHeaderText:updateAbsolutePosition()
	self.itemsHeaderIcon:setImageSlice(nil, headerIconSlice)
end

function ShopItemsFrame:setCategory(rootName, categoryName, categorySliceId, secondaryCategoryName, headerTitleOverride)
	self:setHeader(headerTitleOverride or (secondaryCategoryName or categoryName), categorySliceId)
	if self.categoryName ~= categoryName then
		self.itemsList.setNextOpenIndex = 1
	end
	self.rootName = rootName
	self.categoryName = categoryName
	self.secondaryCategoryName = secondaryCategoryName
	self:setTitle(headerTitleOverride or (secondaryCategoryName or categoryName))
end

function ShopItemsFrame:setShowBalance(doShowBalance)
	self.currentBalanceLabel:setVisible(doShowBalance)
	self.currentBalanceText:setVisible(doShowBalance)
end

function ShopItemsFrame:setShowNavigation(doShowNavigation)
	if self.breadcrumbs ~= nil then
		self.breadcrumbs:setVisible(doShowNavigation)
	end
end

-- Local values: balanceProfile
function ShopItemsFrame:setCurrentBalance(balance, balanceString)
	local v43_ = ShopMenu.GUI_PROFILE.SHOP_MONEY
	if math.floor(balance) <= -1 then
		v43_ = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
	end
	self.currentBalanceText:applyProfile(v43_, nil, true)
	self.currentBalanceText:setText(balanceString)
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end

-- Local values: slotsVisible, text, profile
function ShopItemsFrame:setSlotsUsage(slotsUsage, maxSlots)
	local v47_ = g_currentMission.slotSystem:getAreSlotsVisible()
	if v47_ then
		local v48_ = string.format("%0d / %0d", slotsUsage, maxSlots)
		local v49_ = ShopMenu.GUI_PROFILE.SHOP_MONEY
		if slotsUsage / maxSlots >= ShopMenu.SLOTS_USAGE_CRITICAL_THRESHOLD then
			v49_ = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
		end
		if self.shopSlotsText.profile ~= v49_ then
			self.shopSlotsText:applyProfile(v49_)
		end
		self.shopSlotsText:setText(v48_)
	end
	self.shopSlotsIcon:setVisible(v47_)
	self.shopSlotsText:setVisible(v47_)
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end

function ShopItemsFrame:setDisplayItems(displayItems)
	self:setSoundSuppressed(true)
	self.displayItems = displayItems or {}
	self.itemsList:reloadData()
	self.detailBox:setVisible(#self.displayItems > 0)
	self.noItemsText:setVisible(#self.displayItems == 0)
end

-- Local values: priceStr, price
function ShopItemsFrame:getStoreItemDisplayPrice(storeItem, saleItem)
	if saleItem ~= nil then
		return g_i18n:formatMoney(saleItem.price, 0, true, true)
	end
	if storeItem.isInAppPurchase then
		return storeItem.price
	end
	local v54_ = g_currentMission.economyManager:getBuyPrice(storeItem)
	return g_i18n:formatMoney(v54_, 0, true, true)
end

-- Local values: layoutsToInvalidate, k, clone, layout, _, k, _, i, name, brand
function ShopItemsFrame:assignItemAttributeData(displayItem)
	local v57_ = {}
	for v58_, v59_ in pairs(self.clonedElements) do
		if v57_[v59_.parent] == nil then
			v57_[v59_.parent] = true
		end
		v59_:delete()
		self.clonedElements[v58_] = nil
	end
	for v60_, _ in pairs(v57_) do
		v60_:invalidateLayout()
	end
	for v61_, _ in pairs(self.marqueeBoxes) do
		self.marqueeBoxes[v61_] = nil
	end
	for v62_ = #self.attributesLayout.elements, 1, -1 do
		self:queueDetailsCell(self.attributesLayout.elements[v62_])
	end
	self:assignItemTextData(displayItem)
	self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.fillTypeIconFilenames)
	self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.foodFillTypeIconFilenames)
	self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_SEED_FILL_TYPES, displayItem.seedTypeIconFilenames)
	local v63_ = displayItem.storeItem.name
	if displayItem.concreteItem ~= nil and displayItem.concreteItem.getName ~= nil then
		v63_ = displayItem.concreteItem:getName()
	end
	local v64_ = g_brandManager:getBrandByIndex(displayItem.storeItem.brandIndex)
	if displayItem.concreteItem ~= nil and displayItem.concreteItem.getBrand ~= nil then
		v64_ = g_brandManager:getBrandByIndex(displayItem.concreteItem:getBrand())
	end
	if v64_ ~= nil and v64_.name ~= "NONE" then
		v63_ = v64_.title .. " " .. v63_
	end
	self.itemDetailsName:setText(v63_)
	self.itemDetailsDescription:setText(displayItem.functionText)
	self.itemDetailsOwned:setText(displayItem.numOwned or "")
	self.itemDetailsLeased:setText(displayItem.numLeased or "")
	self.itemDetailsAmountBox:setVisible(self.itemDetailsLeased.text ~= "")
	self.attributesLayout:invalidateLayout()
end

-- Local values: storeItem, i, value, cell, icon, text, profile
function ShopItemsFrame:assignItemTextData(displayItem)
	if Platform.isMobile and self.attrVehicleValue ~= nil then
		local v67_ = displayItem.storeItem
		self.attrVehicleValue:setText(self:getStoreItemDisplayPrice(v67_))
		self.attrVehicleValue:setVisible(not v67_.isInAppPurchase)
		self.attrVehicleValueIcon:setVisible(not v67_.isInAppPurchase)
	end
	for v68_, v69_ in pairs(displayItem.attributeValues) do
		local v70_ = self:dequeueDetailsCell(ShopItemsFrame.CELL_NAME_DETAIL)
		local v71_ = v70_:getDescendantByName("icon")
		local v72_ = v70_:getDescendantByName("text")
		local v73_ = displayItem.attributeIconProfiles[v68_]
		if v73_ ~= nil and v73_ ~= "" then
			v72_:setText(v69_)
			v71_:applyProfile(v73_)
		end
		v70_:setSize(v71_.absSize[1] + v71_.margin[1] + v72_.absSize[1], nil)
	end
end

-- Local values: totalWidth, cell, cellIcon, iconsLayout, _, iconFilename, icon, maxWidth, parentSize, iconsLayoutSize
function ShopItemsFrame:assignItemFillTypesData(baseIconProfile, iconFilenames)
	if #iconFilenames > 0 then
		local v77_ = self:dequeueDetailsCell(ShopItemsFrame.CELL_NAME_FILL_TYPES)
		local v78_ = v77_:getDescendantByName("icon")
		local v79_ = v77_:getDescendantByName("iconsLayout")
		v78_:applyProfile(baseIconProfile)
		local v80_ = 0
		for _, v81_ in pairs(iconFilenames) do
			local v82_ = self.fruitIconTemplate:clone(v79_)
			v82_:setVisible(true)
			local v83_ = self.clonedElements
			table.insert(v83_, v82_)
			v82_:applyProfile(ShopItemsFrame.PROFILE.ICON_FRUIT_TYPE)
			v82_:setImageFilename(v81_)
			self.overlayCache:addOverlay(v81_)
			v80_ = v80_ + v82_.absSize[1] + v82_.margin[1] + v82_.margin[3]
		end
		local v84_ = self.attributesLayout.absSize[1] * 0.91
		local v85_ = math.min(v84_, v80_)
		local v86_ = v85_ + v78_.absSize[1] + v78_.margin[1]
		v79_:setSize(v80_, nil)
		v79_:setPosition(0, nil)
		v79_.parent:setSize(v85_, nil)
		v79_:invalidateLayout()
		if v86_ < v80_ then
			self.marqueeBoxes[v79_] = 0
			return
		end
		self.marqueeBoxes[v79_] = nil
	end
end

-- Local values: displayItem, lastInputMode
function ShopItemsFrame:onOpenItem(list, section, index, element, wasAlreadySelected)
	local v89_ = self.displayItems[self.itemsList.selectedIndex]
	local v90_ = g_inputBinding:getLastInputMode()
	if v89_ ~= nil and (v90_ == GS_INPUT_HELP_MODE_TOUCH and wasAlreadySelected or v90_ ~= GS_INPUT_HELP_MODE_TOUCH) then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		self.notifyActivatedDisplayItemCallback(v89_)
	end
end

function ShopItemsFrame:onListSelectionChanged(list, section, index)
	self:updateItemAttributeData(index)
end

-- Local values: displayItem
function ShopItemsFrame:updateItemAttributeData(index)
	local v95_ = index or self.itemsList.selectedIndex
	local v96_ = self.displayItems[v95_]
	if v96_ ~= nil and self:getIsVisible() then
		self:assignItemAttributeData(v96_)
		self.notifySelectedDisplayItemCallback(v96_, v95_)
	end
end

function ShopItemsFrame:getSelectedDisplayItem()
	return self.displayItems[self.itemsList.selectedIndex]
end

function ShopItemsFrame:getNumberOfItemsInSection(list, section)
	return #self.displayItems
end

-- Local values: displayItem, storeItem, brandIcon, brandIndex, itemBrand, priceTagElement, priceTagTextElement, elementWidth, imageFilename, saleItem, title, defaultPrice, discount, priceStr
function ShopItemsFrame:populateCellForItemInSection(list, section, index, cell)
	local v102_ = self.displayItems[index]
	local v103_ = v102_.storeItem
	if v103_.brandIndex == nil then
		cell:getAttribute("brandIcon"):setVisible(false)
		cell:getAttribute("icon"):applyProfile("fs25_shopItemsListItemImageWithoutBrand")
	else
		local v104_ = cell:getAttribute("brandIcon")
		local v105_ = v103_.brandIndex
		if v102_.concreteItem.getBrand ~= nil then
			v105_ = v102_.concreteItem:getBrand()
		end
		local v106_ = g_brandManager:getBrandByIndex(v105_)
		v104_:setImageFilename(v103_.customBrandIcon or v106_.image)
		v104_:setVisible(true)
		self.overlayCache:addOverlay(v103_.customBrandIcon or v106_.image)
		cell:getAttribute("icon"):applyProfile("fs25_shopItemsListItemImage")
	end
	if v103_.isInAppPurchase then
		local v107_ = cell:getAttribute("priceTag")
		local v108_ = cell:getAttribute("priceTagText")
		cell:getAttribute("icon"):setImageFilename(v103_.imageFilename)
		cell:getAttribute("title"):setText(v103_.title)
		if v103_.canBeRecovered then
			v107_:applyProfile("fs25_shopItemsListItemPriceTagRecoverable")
		else
			v107_:applyProfile("fs25_shopItemsListItemPriceTag")
		end
		local v109_ = getTextWidth(v108_.textSize, v103_.priceText) + CORNER_WIDTH * 2
		v107_:setSize(v109_)
		v107_:setVisible(true)
		v108_:setSize(v109_)
		v108_:setText(v103_.priceText)
	else
		local v110_ = v103_.imageFilename
		local v111_ = v102_.saleItem
		if v102_.concreteItem.getImageFilename ~= nil then
			v110_ = v102_.concreteItem:getImageFilename()
		end
		cell:getAttribute("icon"):setImageFilename(v110_)
		self.overlayCache:addOverlay(v110_)
		local v112_ = v103_.name
		if v102_.concreteItem.getName ~= nil then
			v112_ = v102_.concreteItem:getName()
		end
		cell:getAttribute("title"):setText(v112_)
		if Platform.isMobile then
			cell:getAttribute("value"):setVisible(false)
		else
			cell:getAttribute("value"):setText(self:getStoreItemDisplayPrice(v103_, v111_))
		end
		if v103_.isMod and v103_.dlcTitle == nil then
			cell:getAttribute("modDlc"):setText("Mod")
		elseif v103_.isMod and v103_.dlcTitle ~= nil then
			cell:getAttribute("modDlc"):setText(v103_.dlcTitle .. " (Mod)")
		elseif v103_.dlcTitle == nil then
			cell:getAttribute("modDlc"):setText("")
		else
			cell:getAttribute("modDlc"):setText(v103_.dlcTitle)
		end
		if v111_ ~= nil then
			local v113_ = StoreItemUtil.getPriceWithBoughtConfigurations(v103_, v111_.boughtConfigurations, "price")
			local v114_ = v113_ <= 0 and 0 or -(1 - v111_.price / v113_) * 100
			local v115_ = string.format("%d%%", v114_)
			cell:getAttribute("priceTagText"):setText(v115_)
		end
		cell:getAttribute("priceTag"):setVisible(v111_ ~= nil)
	end
end

function ShopItemsFrame:resetListSelection()
	self:setSoundSuppressed(true)
	self.itemsList:setSelectedIndex(1, nil, true)
	self.itemsList:makeCellVisible(1, 1, true)
	self:setSoundSuppressed(false)
end

-- Local values: k, clone, i, element, name
function ShopItemsFrame:buildCellDatabase()
	for v118_, v119_ in pairs(self.detailsTemplates) do
		v119_:delete()
		self.detailsTemplates[v118_] = nil
	end
	self.detailsTemplates = {}
	for v120_ = #self.attributesLayout.elements, 1, -1 do
		local v121_ = self.attributesLayout.elements[v120_]
		local v122_ = v121_.name
		self.detailsTemplates[v122_] = v121_:clone()
		self.detailsCache[v122_] = {}
	end
end

-- Local values: cell, cache
function ShopItemsFrame:dequeueDetailsCell(name)
	if self.detailsTemplates[name] == nil then
		return nil
	end
	local v125_ = self.detailsCache[name]
	local v126_
	if #v125_ > 0 then
		v126_ = v125_[#v125_]
		v125_[#v125_] = nil
	else
		v126_ = self.detailsTemplates[name]:clone()
	end
	self.attributesLayout:addElement(v126_)
	return v126_
end

-- Local values: cache
function ShopItemsFrame:queueDetailsCell(cell)
	local v129_ = self.detailsCache[cell.name]
	v129_[#v129_ + 1] = cell
	self.attributesLayout:removeElement(cell)
	cell:unlinkElement()
end

function ShopItemsFrame:update(dt)
	ShopItemsFrame:superClass().update(self, dt)
	self:updateMarqueeAnimation(dt)
end

-- Local values: box, time, contentWidth, visibleWidth, scrollAmount, scrollLengthFactor, scrollDuration, alpha, offset
function ShopItemsFrame:updateMarqueeAnimation(dt)
	for v134_, v135_ in pairs(self.marqueeBoxes) do
		local v136_ = v134_.absSize[1]
		local v137_ = v134_.parent.absSize[1]
		local v138_ = v136_ - v137_
		local v139_ = 5000 * (v136_ / v137_)
		local v140_ = v135_ + dt
		if v139_ <= v140_ then
			v140_ = -v139_
		end
		v134_:setPosition(-(v138_ * MathUtil.smoothstep(0.1, 0.9, math.abs(v140_) / v139_)))
		self.marqueeBoxes[v134_] = v140_
	end
end
ShopItemsFrame.PROFILE = {
	["ICON_FRUIT_TYPE"] = "fs25_itemDetailsFruitIcon",
	["ICON_FILL_TYPES"] = "shopListAttributeIconFillTypes",
	["ICON_SEED_FILL_TYPES"] = "shopListAttributeIconSeeds",
	["ICON_INPUT"] = "shopListAttributeIconInput",
	["ICON_OUTPUT"] = "shopListAttributeIconOutput"
}
