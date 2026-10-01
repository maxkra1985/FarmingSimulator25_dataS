WardrobeOutfitsFrame = {}
local WardrobeOutfitsFrame_mt = Class(WardrobeOutfitsFrame, TabbedMenuFrameElement)
function WardrobeOutfitsFrame.register()
	local wardrobeOutfitsFrame = WardrobeOutfitsFrame.new()
	g_gui:loadGui("dataS/gui/WardrobeOutfitsFrame.xml", "WardrobeOutfitsFrame", wardrobeOutfitsFrame, true)
end
function WardrobeOutfitsFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or WardrobeOutfitsFrame_mt)
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK, text = g_i18n:getText("button_confirm") }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
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
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo, self.equipButtonInfo }
	self.indexMapping = {}
	self.isShowingColors = false
	return self
end
function WardrobeOutfitsFrame.createFromExistingGui(gui, guiName)
	local newGui = WardrobeOutfitsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function WardrobeOutfitsFrame:initialize(delegate, titleKey, sliceId)
	self.delegate = delegate
	self.title:setLocaKey(titleKey)
	self.headerIcon:setImageSlice(nil, sliceId)
end
function WardrobeOutfitsFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
	self.playerStyle = playerStyle
	self.savedPlayerStyle = savedPlayerStyle
	self:resetList()
end
function WardrobeOutfitsFrame:onFrameOpen()
	WardrobeOutfitsFrame:superClass().onFrameOpen(self)
	if self.lastPlayerStyle == nil then
		self.lastPlayerStyle = PlayerStyle.new()
	end
	self.lastPlayerStyle:copyFrom(self.savedPlayerStyle)
	if not self.isShowingColors then
		self.delegate:onItemSelectionStart()
		self:resetList()
	end
end
function WardrobeOutfitsFrame:resetList()
	if self.playerStyle ~= nil then
		self.indexMapping = { { -1 }, {} }
		self.currentlyUsedPreset = self:getCurrentlySelectedPresetIndex()
		local selectedIndex = 1
		local selectedSection = 1
		for i, preset in ipairs(self.playerStyle.presets) do
			if preset.brandName ~= nil then
				preset.brand = g_brandManager:getBrandByName(preset.brandName)
				if preset.brand ~= nil then
					preset.brandName = nil
				end
			end
			local section = preset.brand ~= nil and 2 or 1
			local isCurrentSelection = self.currentlyUsedPreset == i
			if preset.isSelectable and (isCurrentSelection or preset.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(preset.extraContentId)) then
				table.insert(self.indexMapping[section], i)
				if isCurrentSelection then
					selectedIndex = #self.indexMapping[section]
					selectedSection = section
				end
			end
		end
		self.itemList:reloadData()
		self.itemList:setSelectedItem(selectedSection, selectedIndex)
	end
end
function WardrobeOutfitsFrame:getCurrentlySelectedPresetIndex()
	for i, preset in ipairs(self.playerStyle.presets) do
		if preset:getDoesStyleUse(self.savedPlayerStyle) then
			return i
		end
	end
	return -1
end
function WardrobeOutfitsFrame:onFrameClose()
	if not self.isShowingColors then
		for _, cell in ipairs(self.itemList.elements) do
			if cell.isHeader or cell:getAttribute("icon") == nil then
				continue
			end
			cell:getAttribute("icon"):setImageFilename(g_baseUIFilename)
		end
	end
	WardrobeOutfitsFrame:superClass().onFrameClose(self)
end
function WardrobeOutfitsFrame:updateSelectionButton()
	local item = self:getSelectedPreset()
	local hasColors = false
	if item ~= nil then
		hasColors = self:getPresetHasColors(item)
	end
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo, self.equipButtonInfo, hasColors and self.colorButtonInfo or nil }
	self:setMenuButtonInfoDirty()
end
function WardrobeOutfitsFrame:getNumberOfSections()
	if 0 < #self.indexMapping[2] then
		return 2
	else
		return 1
	end
end
function WardrobeOutfitsFrame:getTitleForSectionHeader(list, section)
	if section == 2 then
		return g_i18n:getText("character_section_branded")
	elseif 0 < self:getNumberOfItemsInSection(list, section) then
		return ""
	else
		return nil
	end
end
function WardrobeOutfitsFrame:getNumberOfItemsInSection(list, section)
	return #self.indexMapping[section]
end
function WardrobeOutfitsFrame:populateCellForItemInSection(list, section, index, cell)
	local presetIndex = self.indexMapping[section][index]
	local getIsSelectedFunc = function()
		return self.currentlyUsedPreset == presetIndex
	end
	local getIsFocusedFunc = function()
		return cell.selected or self.currentHoveredSection ~= section or self.currentHoveredIndex == index
	end
	if presetIndex ~= -1 then
		local preset = self.playerStyle.presets[presetIndex]
		if preset ~= nil then
			cell:getAttribute("icon"):setImageFilename(preset.iconFilename)
			cell:getAttribute("icon"):setVisible(preset.iconFilename ~= nil)
			cell:getAttribute("icon").getIsSelected = getIsSelectedFunc
			cell:getAttribute("background").getIsSelected = getIsSelectedFunc
			cell:getAttribute("background").getIsFocused = getIsFocusedFunc
			cell:getAttribute("hasColors"):setVisible(self:getPresetHasColors(preset))
			cell:getAttribute("hasColors").getIsSelected = getIsSelectedFunc
		end
	else
		cell:getAttribute("icon"):setVisible(false)
		cell:getAttribute("hasColors"):setVisible(false)
		cell:getAttribute("background").getIsSelected = function()
			return self.currentlyUsedPreset == -1
		end
		cell:getAttribute("background").getIsFocused = getIsFocusedFunc
	end
end
function WardrobeOutfitsFrame:onListSelectionChanged(list, section, index)
	if g_gui.currentlyReloading then
		return
	else
		local preset = self:getPresetFromItem(section, index)
		if preset == nil then
			if self.currentlyUsedPreset ~= -1 then
				if self.lastPlayerStyle ~= nil then
					self.playerStyle:copyFrom(self.lastPlayerStyle)
					self.delegate:onItemSelectionChanged()
				else
					self.delegate:onItemSelectionCancelled()
				end
			end
		else
			local presetIndex = self.indexMapping[section][index]
			preset:applyToStyle(self.playerStyle, self.currentlyUsedPreset ~= presetIndex)
			self.delegate:onItemSelectionChanged()
		end
		self:updateSelectionButton()
	end
end
function WardrobeOutfitsFrame:onListHighlightChanged(list, section, index)
	self.currentHoveredSection = section
	self.currentHoveredIndex = index
	if index == nil then
		self.delegate:onItemSelectionCancelled()
	else
		local preset = self:getPresetFromItem(section, index)
		if preset == nil then
			if self.currentlyUsedPreset ~= -1 then
				self.playerStyle:copyFrom(self.lastPlayerStyle)
				self.delegate:onItemSelectionChanged()
				return
			else
				self.delegate:onItemSelectionCancelled()
				return
			end
		end
		preset:applyToStyle(self.playerStyle, self.currentlyUsedPreset ~= self:getCurrentlySelectedPresetIndex())
		self.delegate:onItemSelectionChanged()
	end
end
function WardrobeOutfitsFrame:onClickSelect()
	self.delegate:onItemSelectionConfirmed()
	self.currentlyUsedPreset = self:getCurrentlySelectedPresetIndex()
	self.itemList:reloadData()
end
function WardrobeOutfitsFrame:onClickSelectColor()
	local preset = self:getSelectedPreset()
	self.isShowingColors = true
	local item = nil
	if preset.configs.onepiece ~= nil and not string.isNilOrWhitespace(preset.configs.onepiece.selectionName) then
		item = self.playerStyle.configs.onepiece.itemsByName[preset.configs.onepiece.selectionName]
	end
	local originalColor = self.playerStyle.configs.onepiece.selectedColorIndex
	self.delegate:onItemShowColors("onepiece", item, function(confirmed, keepOpen)
		if not keepOpen then
			self.isShowingColors = false
		end
		if not confirmed then
			self.playerStyle.configs.onepiece:setSelectedColorIndex(originalColor)
			self.delegate:onItemSelectionChanged()
		else
			originalColor = self.playerStyle.configs.onepiece.selectedColorIndex
		end
	end)
end
function WardrobeOutfitsFrame:getSelectedPreset()
	return self:getPresetFromItem(self.itemList.selectedSectionIndex, self.itemList.selectedIndex)
end
function WardrobeOutfitsFrame:getPresetFromItem(section, index)
	local presetIndex = self.indexMapping[section][index]
	if presetIndex == -1 then
		return nil
	else
		return self.playerStyle.presets[presetIndex]
	end
end
function WardrobeOutfitsFrame:getPresetHasColors(preset)
	if preset.configs.onepiece ~= nil and not string.isNilOrWhitespace(preset.configs.onepiece.selectionName) then
		local onepiece = self.playerStyle.configs.onepiece.itemsByName[preset.configs.onepiece.selectionName]
		if onepiece ~= nil then
			return 0 < onepiece.colorableSlots
		end
	end
	return false
end
