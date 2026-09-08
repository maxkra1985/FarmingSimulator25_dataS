-- Local values: WardrobeOutfitsFrame_mt
WardrobeOutfitsFrame = {}
local WardrobeOutfitsFrame_mt = Class(WardrobeOutfitsFrame, TabbedMenuFrameElement)
function WardrobeOutfitsFrame.register()
	local v2_ = WardrobeOutfitsFrame.new()
	g_gui:loadGui("dataS/gui/WardrobeOutfitsFrame.xml", "WardrobeOutfitsFrame", v2_, true)
end

-- Upvalues: WardrobeOutfitsFrame_mt
-- Local values: self
function WardrobeOutfitsFrame.new(target, custom_mt)
	-- upvalues: (copy) WardrobeOutfitsFrame_mt
	local v_u_5_ = TabbedMenuFrameElement.new(target, custom_mt or WardrobeOutfitsFrame_mt)
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
		v_u_5_.equipButtonInfo
	}
	v_u_5_.indexMapping = {}
	v_u_5_.isShowingColors = false
	return v_u_5_
end

-- Local values: newGui
function WardrobeOutfitsFrame.createFromExistingGui(gui, guiName)
	local v8_ = WardrobeOutfitsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
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

-- Local values: selectedIndex, selectedSection, i, preset, section, isCurrentSelection
function WardrobeOutfitsFrame:resetList()
	if self.playerStyle ~= nil then
		self.indexMapping = {
			{ -1 },
			{}
		}
		self.currentlyUsedPreset = self:getCurrentlySelectedPresetIndex()
		local v18_ = 1
		local v19_ = 1
		for v20_, v21_ in ipairs(self.playerStyle.presets) do
			if v21_.brandName ~= nil then
				v21_.brand = g_brandManager:getBrandByName(v21_.brandName)
				if v21_.brand ~= nil then
					v21_.brandName = nil
				end
			end
			local v22_ = v21_.brand == nil and 1 or 2
			local v23_ = self.currentlyUsedPreset == v20_
			if v21_.isSelectable and (v23_ or (v21_.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(v21_.extraContentId))) then
				local v24_ = self.indexMapping[v22_]
				table.insert(v24_, v20_)
				if v23_ then
					v19_ = #self.indexMapping[v22_]
					v18_ = v22_
				end
			end
		end
		self.itemList:reloadData()
		self.itemList:setSelectedItem(v18_, v19_)
	end
end

-- Local values: i, preset
function WardrobeOutfitsFrame:getCurrentlySelectedPresetIndex()
	for v26_, v27_ in ipairs(self.playerStyle.presets) do
		if v27_:getDoesStyleUse(self.savedPlayerStyle) then
			return v26_
		end
	end
	return -1
end

-- Local values: _, cell
function WardrobeOutfitsFrame:onFrameClose()
	if not self.isShowingColors then
		for _, v29_ in ipairs(self.itemList.elements) do
			if not v29_.isHeader and v29_:getAttribute("icon") ~= nil then
				v29_:getAttribute("icon"):setImageFilename(g_baseUIFilename)
			end
		end
	end
	WardrobeOutfitsFrame:superClass().onFrameClose(self)
end

-- Local values: item, hasColors
function WardrobeOutfitsFrame:updateSelectionButton()
	local v31_ = self:getSelectedPreset()
	local v32_
	if v31_ == nil then
		v32_ = false
	else
		v32_ = self:getPresetHasColors(v31_)
	end
	local v33_ = {}
	local v34_ = self.backButtonInfo
	local v35_ = self.nextPageButtonInfo
	local v36_ = self.prevPageButtonInfo
	local v37_ = self.equipButtonInfo
	local v38_
	if v32_ then
		v38_ = self.colorButtonInfo or nil
	else
		v38_ = nil
	end
	__set_list(v33_, 1, {v34_, v35_, v36_, v37_, v38_})
	self.menuButtonInfo = v33_
	self:setMenuButtonInfoDirty()
end

function WardrobeOutfitsFrame:getNumberOfSections()
	return #self.indexMapping[2] > 0 and 2 or 1
end

function WardrobeOutfitsFrame:getTitleForSectionHeader(list, section)
	if section == 2 then
		return g_i18n:getText("character_section_branded")
	else
		return self:getNumberOfItemsInSection(list, section) > 0 and "" or nil
	end
end

function WardrobeOutfitsFrame:getNumberOfItemsInSection(list, section)
	return #self.indexMapping[section]
end

-- Local values: presetIndex, getIsSelectedFunc, getIsFocusedFunc, preset
function WardrobeOutfitsFrame:populateCellForItemInSection(list, section, index, cell)
	local v_u_49_ = self.indexMapping[section][index]
	local function v50_()
		-- upvalues: (copy) self, (copy) v_u_49_
		return self.currentlyUsedPreset == v_u_49_
	end
	local function v52_()
		-- upvalues: (copy) cell, (copy) self, (copy) section, (copy) index
		local v51_ = cell.selected
		if not v51_ then
			if self.currentHoveredSection == section then
				v51_ = self.currentHoveredIndex == index
			else
				v51_ = false
			end
		end
		return v51_
	end
	if v_u_49_ == -1 then
		cell:getAttribute("icon"):setVisible(false)
		cell:getAttribute("hasColors"):setVisible(false)
		cell:getAttribute("background").getIsSelected = function()
			-- upvalues: (copy) self
			return self.currentlyUsedPreset == -1
		end
		cell:getAttribute("background").getIsFocused = v52_
	else
		local v53_ = self.playerStyle.presets[v_u_49_]
		if v53_ ~= nil then
			cell:getAttribute("icon"):setImageFilename(v53_.iconFilename)
			cell:getAttribute("icon"):setVisible(v53_.iconFilename ~= nil)
			cell:getAttribute("icon").getIsSelected = v50_
			cell:getAttribute("background").getIsSelected = v50_
			cell:getAttribute("background").getIsFocused = v52_
			cell:getAttribute("hasColors"):setVisible(self:getPresetHasColors(v53_))
			cell:getAttribute("hasColors").getIsSelected = v50_
			return
		end
	end
end

-- Local values: preset, presetIndex
function WardrobeOutfitsFrame:onListSelectionChanged(list, section, index)
	if not g_gui.currentlyReloading then
		local v57_ = self:getPresetFromItem(section, index)
		if v57_ == nil then
			if self.currentlyUsedPreset == -1 or self.lastPlayerStyle == nil then
				self.delegate:onItemSelectionCancelled()
			else
				self.playerStyle:copyFrom(self.lastPlayerStyle)
				self.delegate:onItemSelectionChanged()
			end
		else
			local v58_ = self.indexMapping[section][index]
			v57_:applyToStyle(self.playerStyle, self.currentlyUsedPreset ~= v58_)
			self.delegate:onItemSelectionChanged()
		end
		self:updateSelectionButton()
	end
end

-- Local values: preset
function WardrobeOutfitsFrame:onListHighlightChanged(list, section, index)
	self.currentHoveredSection = section
	self.currentHoveredIndex = index
	if index == nil then
		self.delegate:onItemSelectionCancelled()
		return
	else
		local v62_ = self:getPresetFromItem(section, index)
		if v62_ == nil then
			if self.currentlyUsedPreset == -1 then
				self.delegate:onItemSelectionCancelled()
			else
				self.playerStyle:copyFrom(self.lastPlayerStyle)
				self.delegate:onItemSelectionChanged()
			end
		else
			v62_:applyToStyle(self.playerStyle, self.currentlyUsedPreset ~= self:getCurrentlySelectedPresetIndex())
			self.delegate:onItemSelectionChanged()
			return
		end
	end
end

function WardrobeOutfitsFrame:onClickSelect()
	self.delegate:onItemSelectionConfirmed()
	self.currentlyUsedPreset = self:getCurrentlySelectedPresetIndex()
	self.itemList:reloadData()
end

-- Local values: preset, item, originalColor
function WardrobeOutfitsFrame:onClickSelectColor()
	local v65_ = self:getSelectedPreset()
	self.isShowingColors = true
	local v66_
	if v65_.configs.onepiece == nil or string.isNilOrWhitespace(v65_.configs.onepiece.selectionName) then
		v66_ = nil
	else
		v66_ = self.playerStyle.configs.onepiece.itemsByName[v65_.configs.onepiece.selectionName]
	end
	local v_u_67_ = self.playerStyle.configs.onepiece.selectedColorIndex
	self.delegate:onItemShowColors("onepiece", v66_, function(p68_, p69_)
		-- upvalues: (copy) self, (ref) v_u_67_
		if not p69_ then
			self.isShowingColors = false
		end
		if p68_ then
			v_u_67_ = self.playerStyle.configs.onepiece.selectedColorIndex
		else
			self.playerStyle.configs.onepiece:setSelectedColorIndex(v_u_67_)
			self.delegate:onItemSelectionChanged()
		end
	end)
end

function WardrobeOutfitsFrame:getSelectedPreset()
	return self:getPresetFromItem(self.itemList.selectedSectionIndex, self.itemList.selectedIndex)
end

-- Local values: presetIndex
function WardrobeOutfitsFrame:getPresetFromItem(section, index)
	local v74_ = self.indexMapping[section][index]
	if v74_ == -1 then
		return nil
	else
		return self.playerStyle.presets[v74_]
	end
end

-- Local values: onepiece
function WardrobeOutfitsFrame:getPresetHasColors(preset)
	if preset.configs.onepiece ~= nil and not string.isNilOrWhitespace(preset.configs.onepiece.selectionName) then
		local v77_ = self.playerStyle.configs.onepiece.itemsByName[preset.configs.onepiece.selectionName]
		if v77_ ~= nil then
			return v77_.colorableSlots > 0
		end
	end
	return false
end
