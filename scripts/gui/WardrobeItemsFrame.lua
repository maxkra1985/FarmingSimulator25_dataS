-- Local values: WardrobeItemsFrame_mt
WardrobeItemsFrame = {}
local WardrobeItemsFrame_mt = Class(WardrobeItemsFrame, TabbedMenuFrameElement)
function WardrobeItemsFrame.register()
	local v2_ = WardrobeItemsFrame.new()
	g_gui:loadGui("dataS/gui/WardrobeItemsFrame.xml", "PricesFrame", v2_, true)
end

-- Upvalues: WardrobeItemsFrame_mt
-- Local values: self
function WardrobeItemsFrame.new(target, custom_mt)
	-- upvalues: (copy) WardrobeItemsFrame_mt
	local v_u_5_ = TabbedMenuFrameElement.new(target, custom_mt or WardrobeItemsFrame_mt)
	v_u_5_.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK,
		["text"] = g_i18n:getText("button_confirm")
	}
	v_u_5_.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = v_u_5_.onPageNext
	}
	v_u_5_.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = v_u_5_.onPagePrevious
	}
	v_u_5_.selectButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText("button_select"),
		["callback"] = function()
			-- upvalues: (copy) v_u_5_
			v_u_5_:onClickSelect()
		end
	}
	v_u_5_.equipButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText("button_select"),
		["callback"] = function()
			-- upvalues: (copy) v_u_5_
			v_u_5_:onClickSelect()
		end
	}
	v_u_5_.colorButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_selectColor"),
		["callback"] = function()
			-- upvalues: (copy) v_u_5_
			v_u_5_:onClickSelectColor()
		end
	}
	v_u_5_.hasCustomMenuButtons = true
	v_u_5_.menuButtonInfo = {
		v_u_5_.backButtonInfo,
		v_u_5_.nextPageButtonInfo,
		v_u_5_.prevPageButtonInfo,
		v_u_5_.selectButtonInfo
	}
	v_u_5_.indexMapping = {}
	v_u_5_.isShowingColors = false
	return v_u_5_
end

-- Local values: newGui
function WardrobeItemsFrame.createFromExistingGui(gui, guiName)
	local v8_ = WardrobeItemsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
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

-- Local values: config, totalItems, selectedIndex, selectedSection, possibleItemIndices, index, itemIndex, item, isCurrentSelection, section
function WardrobeItemsFrame:resetList()
	self.indexMapping = {
		{},
		{}
	}
	if self.playerStyle ~= nil and self.configName ~= nil then
		local v19_ = self.playerStyle.configs[self.configName]
		if v19_.items[0] ~= nil and self.playerStyle.disabledOptionsForSelection[self.configName] == nil then
			self.indexMapping[1][1] = 0
		end
		local v20_ = v19_:getPossibleItemIndices()
		local v21_ = 0
		local v22_ = 1
		local v23_ = 1
		for _, v24_ in ipairs(v20_) do
			local v25_ = v19_.items[v24_]
			local v26_ = v19_.selectedItemIndex == v24_
			if v25_ ~= nil and v25_.brandName ~= nil then
				v25_.brand = g_brandManager:getBrandByName(v25_.brandName)
				if v25_.brand ~= nil then
					v25_.brandName = nil
				end
			end
			if v25_.isSelectable and (v26_ or (v25_.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(v25_.extraContentId))) then
				local v27_ = v25_.brand == nil and 1 or 2
				local v28_ = self.indexMapping[v27_]
				table.insert(v28_, v24_)
				v21_ = v21_ + 1
				if v26_ then
					v23_ = #self.indexMapping[v27_]
					v22_ = v27_
				end
			end
		end
		if v21_ == 0 then
			if self.configName == "beard" then
				self.infoText:setLocaKey("ui_noItemsAvailable")
			else
				self.infoText:setLocaKey("ui_noItemsAvailable_onepieceSelected")
			end
		else
			self.infoText:setLocaKey()
		end
		self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
		if v21_ > 0 then
			local v29_ = self.menuButtonInfo
			local v30_ = self.selectButtonInfo
			table.insert(v29_, v30_)
		end
		self:setMenuButtonInfoDirty()
		self.itemList:reloadData()
		self.itemList:setSelectedItem(v22_, v23_)
		if v21_ > 0 then
			FocusManager:setFocus(self.itemList)
		end
	end
end

-- Local values: _, cell
function WardrobeItemsFrame:onFrameClose()
	if not self.isShowingColors then
		for _, v32_ in ipairs(self.itemList.elements) do
			if not v32_.isHeader and v32_:getAttribute("icon") ~= nil then
				v32_:getAttribute("icon"):setImageFilename(g_baseUIFilename)
			end
		end
	end
	WardrobeItemsFrame:superClass().onFrameClose(self)
end

-- Local values: item, isEquipping
function WardrobeItemsFrame:updateSelectionButton()
	local v34_ = self:getSelectedItem()
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if v34_ ~= nil then
		local v35_ = self.menuButtonInfo
		local v36_ = self.equipButtonInfo or self.selectButtonInfo
		table.insert(v35_, v36_)
		if v34_.colorableSlots > 0 then
			local v37_ = self.menuButtonInfo
			local v38_ = self.colorButtonInfo
			table.insert(v37_, v38_)
		end
	end
	self:setMenuButtonInfoDirty()
end

function WardrobeItemsFrame:getNumberOfSections()
	return #self.indexMapping[2] > 0 and 2 or 1
end

function WardrobeItemsFrame:getTitleForSectionHeader(list, section)
	if section == 2 then
		return g_i18n:getText("character_section_branded")
	else
		return self:getNumberOfItemsInSection(list, section) > 0 and "" or nil
	end
end

function WardrobeItemsFrame:getNumberOfItemsInSection(list, section)
	return #self.indexMapping[section]
end

-- Local values: itemIndex, item, getIsSelectedFunc, getIsFocusedFunc
function WardrobeItemsFrame:populateCellForItemInSection(list, section, index, cell)
	local v_u_49_ = self.indexMapping[section][index]
	local v50_ = self.playerStyle.configs[self.configName].items[v_u_49_]
	local function v51_()
		-- upvalues: (copy) self, (copy) v_u_49_
		return self.savedPlayerStyle.configs[self.configName].selectedItemIndex == v_u_49_
	end
	cell:getAttribute("icon"):setImageFilename(v50_.iconFilename)
	cell:getAttribute("icon"):setVisible(v50_.iconFilename ~= nil)
	cell:getAttribute("icon").getIsSelected = v51_
	cell:getAttribute("background").getIsSelected = v51_
	cell:getAttribute("background").getIsFocused = function()
		-- upvalues: (copy) cell, (copy) self, (copy) section, (copy) index
		local v52_ = cell.selected
		if not v52_ then
			if self.currentHoveredSection == section then
				v52_ = self.currentHoveredIndex == index
			else
				v52_ = false
			end
		end
		return v52_
	end
	cell:getAttribute("hasColors"):setVisible(v50_.colorableSlots > 0)
	cell:getAttribute("hasColors").getIsSelected = v51_
end

function WardrobeItemsFrame:onListSelectionChanged(list, section, index)
	if not g_gui.currentlyReloading then
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

-- Local values: itemIndex, config, savedConfig
function WardrobeItemsFrame:setItemToIndex(section, index)
	local v62_ = self.indexMapping[section][index]
	local v63_ = self.playerStyle.configs[self.configName]
	v63_:setSelectedItemIndex(v62_)
	local v64_ = self.savedPlayerStyle.configs[self.configName]
	if v64_.selectedItemIndex == v62_ and (v63_.items[v62_] ~= nil and v63_.items[v62_].colorableSlots > 0) then
		v63_:setSelectedColorIndex(v64_.selectedColorIndex)
	end
end

function WardrobeItemsFrame:onClickSelect()
	self:setItemToIndex(self.itemList.selectedSectionIndex, self.itemList.selectedIndex)
	self.delegate:onItemSelectionConfirmed()
end

-- Local values: item, originalColor
function WardrobeItemsFrame:onClickSelectColor()
	local v67_ = self:getSelectedItem()
	self.isShowingColors = true
	local v_u_68_ = self.playerStyle.configs[self.configName].selectedColorIndex
	self.delegate:onItemShowColors(self.configName, v67_, function(p69_, p70_)
		-- upvalues: (copy) self, (ref) v_u_68_
		if not p70_ then
			self.isShowingColors = false
		end
		if p69_ then
			v_u_68_ = self.playerStyle.configs[self.configName].selectedColorIndex
		else
			self.playerStyle.configs[self.configName]:setSelectedColorIndex(v_u_68_)
			self.delegate:onItemSelectionChanged()
		end
	end)
end

-- Local values: itemIndex
function WardrobeItemsFrame:getSelectedItem()
	local v72_ = self.indexMapping[self.itemList.selectedSectionIndex][self.itemList.selectedIndex]
	return self.playerStyle.configs[self.configName].items[v72_]
end
