WardrobeItemsFrame = {}
local WardrobeItemsFrame_mt = Class(WardrobeItemsFrame, TabbedMenuFrameElement)
function WardrobeItemsFrame.register()
	local wardrobeItemsFrame = WardrobeItemsFrame.new()
	g_gui:loadGui("dataS/gui/WardrobeItemsFrame.xml", "PricesFrame", wardrobeItemsFrame, true)
end
function WardrobeItemsFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or WardrobeItemsFrame_mt)
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK, text = g_i18n:getText("button_confirm") }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
	self.selectButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_select"),
		callback = function()
			self:onClickSelect()
		end,
	}
	self.equipButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_select"),
		callback = function()
			self:onClickSelect()
		end,
	}
	self.colorButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText("button_selectColor"),
		callback = function()
			self:onClickSelectColor()
		end,
	}
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo, self.selectButtonInfo }
	self.indexMapping = {}
	self.isShowingColors = false
	return self
end
function WardrobeItemsFrame.createFromExistingGui(gui, guiName)
	local newGui = WardrobeItemsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function WardrobeItemsFrame:initialize(configName, delegate, titleKey, sliceId)
	self.configName = configName
	self.delegate = delegate
	self.title:setLocaKey(titleKey)
	self.headerIcon:setImageSlice(nil, sliceId)
end
function WardrobeItemsFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
	self.playerStyle = playerStyle
	self.savedPlayerStyle = savedPlayerStyle
	self:resetList()
end
function WardrobeItemsFrame:onFrameOpen()
	WardrobeItemsFrame:superClass().onFrameOpen(self)
	if not self.isShowingColors then
		self.delegate:onItemSelectionStart()
		self:resetList()
	end
end
function WardrobeItemsFrame:resetList()
	self.indexMapping = { {}, {} }
	if self.playerStyle ~= nil and self.configName ~= nil then
		local config = self.playerStyle.configs[self.configName]
		if config.items[0] ~= nil and self.playerStyle.disabledOptionsForSelection[self.configName] == nil then
			self.indexMapping[1][1] = 0
		end
		local totalItems = 0
		local selectedIndex = 1
		local selectedSection = 1
		local possibleItemIndices = config:getPossibleItemIndices()
		for index, itemIndex in ipairs(possibleItemIndices) do
			local item = config.items[itemIndex]
			local isCurrentSelection = config.selectedItemIndex == itemIndex
			if item ~= nil and item.brandName ~= nil then
				item.brand = g_brandManager:getBrandByName(item.brandName)
				if item.brand ~= nil then
					item.brandName = nil
				end
			end
			if item.isSelectable and (isCurrentSelection or item.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(item.extraContentId)) then
				local section = item.brand ~= nil and 2 or 1
				table.insert(self.indexMapping[section], itemIndex)
				totalItems = totalItems + 1
				if isCurrentSelection then
					selectedIndex = #self.indexMapping[section]
					selectedSection = section
				end
			end
		end
		if totalItems ~= 0 then
			self.infoText:setLocaKey()
		elseif self.configName ~= "beard" then
			self.infoText:setLocaKey("ui_noItemsAvailable_onepieceSelected")
		else
			self.infoText:setLocaKey("ui_noItemsAvailable")
		end
		self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
		if 0 < totalItems then
			table.insert(self.menuButtonInfo, self.selectButtonInfo)
		end
		self:setMenuButtonInfoDirty()
		self.itemList:reloadData()
		self.itemList:setSelectedItem(selectedSection, selectedIndex)
		if 0 < totalItems then
			FocusManager:setFocus(self.itemList)
		end
	end
end
function WardrobeItemsFrame:onFrameClose()
	if not self.isShowingColors then
		for _, cell in ipairs(self.itemList.elements) do
			if cell.isHeader or cell:getAttribute("icon") == nil then
				continue
			end
			cell:getAttribute("icon"):setImageFilename(g_baseUIFilename)
		end
	end
	WardrobeItemsFrame:superClass().onFrameClose(self)
end
function WardrobeItemsFrame:updateSelectionButton()
	local item = self:getSelectedItem()
	local isEquipping = true
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if item ~= nil then
		table.insert(self.menuButtonInfo, self.equipButtonInfo or self.selectButtonInfo)
		if 0 < item.colorableSlots then
			table.insert(self.menuButtonInfo, self.colorButtonInfo)
		end
	end
	self:setMenuButtonInfoDirty()
end
function WardrobeItemsFrame:getNumberOfSections()
	if 0 < #self.indexMapping[2] then
		return 2
	else
		return 1
	end
end
function WardrobeItemsFrame:getTitleForSectionHeader(list, section)
	if section == 2 then
		return g_i18n:getText("character_section_branded")
	elseif 0 < self:getNumberOfItemsInSection(list, section) then
		return ""
	else
		return nil
	end
end
function WardrobeItemsFrame:getNumberOfItemsInSection(list, section)
	return #self.indexMapping[section]
end
function WardrobeItemsFrame:populateCellForItemInSection(list, section, index, cell)
	local itemIndex = self.indexMapping[section][index]
	local item = self.playerStyle.configs[self.configName].items[itemIndex]
	local getIsSelectedFunc = function()
		return self.savedPlayerStyle.configs[self.configName].selectedItemIndex == itemIndex
	end
	local getIsFocusedFunc = function()
		return cell.selected or self.currentHoveredSection ~= section or self.currentHoveredIndex == index
	end
	cell:getAttribute("icon"):setImageFilename(item.iconFilename)
	cell:getAttribute("icon"):setVisible(item.iconFilename ~= nil)
	cell:getAttribute("icon").getIsSelected = getIsSelectedFunc
	cell:getAttribute("background").getIsSelected = getIsSelectedFunc
	cell:getAttribute("background").getIsFocused = getIsFocusedFunc
	cell:getAttribute("hasColors"):setVisible(0 < item.colorableSlots)
	cell:getAttribute("hasColors").getIsSelected = getIsSelectedFunc
end
function WardrobeItemsFrame:onListSelectionChanged(list, section, index)
	if g_gui.currentlyReloading then
		return
	else
		self:setItemToIndex(section, index)
		self.delegate:onItemSelectionChanged()
		self:updateSelectionButton()
	end
end
function WardrobeItemsFrame:onListHighlightChanged(list, section, index)
	self.currentHoveredSection = section
	self.currentHoveredIndex = index
	if index == nil then
		self.delegate:onItemSelectionCancelled()
	else
		self:setItemToIndex(section, index)
		self.delegate:onItemSelectionChanged()
	end
end
function WardrobeItemsFrame:setItemToIndex(section, index)
	local itemIndex = self.indexMapping[section][index]
	local config = self.playerStyle.configs[self.configName]
	config:setSelectedItemIndex(itemIndex)
	local savedConfig = self.savedPlayerStyle.configs[self.configName]
	if savedConfig.selectedItemIndex == itemIndex and (config.items[itemIndex] ~= nil and 0 < config.items[itemIndex].colorableSlots) then
		config:setSelectedColorIndex(savedConfig.selectedColorIndex)
	end
end
function WardrobeItemsFrame:onClickSelect()
	self:setItemToIndex(self.itemList.selectedSectionIndex, self.itemList.selectedIndex)
	self.delegate:onItemSelectionConfirmed()
end
function WardrobeItemsFrame:onClickSelectColor()
	local item = self:getSelectedItem()
	self.isShowingColors = true
	local originalColor = self.playerStyle.configs[self.configName].selectedColorIndex
	self.delegate:onItemShowColors(self.configName, item, function(confirmed, keepOpen)
		if not keepOpen then
			self.isShowingColors = false
		end
		if not confirmed then
			self.playerStyle.configs[self.configName]:setSelectedColorIndex(originalColor)
			self.delegate:onItemSelectionChanged()
		else
			originalColor = self.playerStyle.configs[self.configName].selectedColorIndex
		end
	end)
end
function WardrobeItemsFrame:getSelectedItem()
	local itemIndex = self.indexMapping[self.itemList.selectedSectionIndex][self.itemList.selectedIndex]
	return self.playerStyle.configs[self.configName].items[itemIndex]
end
