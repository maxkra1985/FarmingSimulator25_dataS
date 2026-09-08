-- Local values: ModHubExtraContentFrame_mt
ModHubExtraContentFrame = {}
local ModHubExtraContentFrame_mt = Class(ModHubExtraContentFrame, TabbedMenuFrameElement)
function ModHubExtraContentFrame.register()
	local v2_ = ModHubExtraContentFrame.new()
	g_gui:loadGui("dataS/gui/ModHubExtraContentFrame.xml", "ModHubExtraContentFrame", v2_, true)
end

-- Upvalues: ModHubExtraContentFrame_mt
-- Local values: self
function ModHubExtraContentFrame.new(target, custom_mt)
	-- upvalues: (copy) ModHubExtraContentFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or ModHubExtraContentFrame_mt)
	v5_.items = {}
	return v5_
end

-- Local values: newGui
function ModHubExtraContentFrame.createFromExistingGui(gui, guiName)
	local v8_ = ModHubExtraContentFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function ModHubExtraContentFrame:onGuiSetupFinished()
	ModHubExtraContentFrame:superClass().onGuiSetupFinished(self)
	self.itemsList:setDataSource(self)
	self.itemsList:setDelegate(self)
end

function ModHubExtraContentFrame:initialize(title)
	self.headerText:setText(title)
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
	self.unlockButton = {
		["inputAction"] = InputAction.MENU_EXTRA_2,
		["text"] = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.BUTTON_UNLOCK),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonUnlock()
		end
	}
end

function ModHubExtraContentFrame:onFrameOpen()
	ModHubExtraContentFrame:superClass().onFrameOpen(self)
	self:updateList()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.itemsList)
	self:setSoundSuppressed(false)
end

-- Local values: buttons
function ModHubExtraContentFrame:getMenuButtonInfo()
	local v14_ = {}
	local v15_ = self.backButtonInfo
	table.insert(v14_, v15_)
	local v16_ = self.nextPageButtonInfo
	table.insert(v14_, v16_)
	local v17_ = self.prevPageButtonInfo
	table.insert(v14_, v17_)
	if g_extraContentSystem:getHasLockedItems() then
		local v18_ = self.unlockButton
		table.insert(v14_, v18_)
	end
	return v14_
end

function ModHubExtraContentFrame:reload()
	self:updateList()
end

function ModHubExtraContentFrame:updateList()
	self.items = g_extraContentSystem:getUnlockedItems()
	self.itemsList:reloadData()
	self.modAttributeBox:setVisible(#self.items > 0)
	self.noItemsElement:setVisible(#self.items == 0)
	self:setMenuButtonInfoDirty()
end

function ModHubExtraContentFrame:getMainElementSize()
	return self.modAttributeBox.size
end

function ModHubExtraContentFrame:getMainElementPosition()
	return self.modAttributeBox.absPosition
end

function ModHubExtraContentFrame:onClickLeft()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem - self.itemsList.itemsPerCol)
end

function ModHubExtraContentFrame:onClickRight()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol)
end

-- Local values: item
function ModHubExtraContentFrame:onListSelectionChanged(list, section, index)
	local v27_ = self.items[index]
	if v27_ ~= nil then
		self.modAttributeName:setText(v27_.description)
		self.modAttributeBox:invalidateLayout()
	end
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

-- Local values: dialogPrompt, imePrompt, confirmText, keyLength
function ModHubExtraContentFrame:onButtonUnlock(defaultText)
	local v30_ = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM_KEY)
	local v31_ = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM_KEY)
	local v32_ = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM)
	local v33_ = GS_PLATFORM_PC and 24 or ExtraContentSystem.KEY_LENGTH
	TextInputDialog.show(self.onExtraContentKeyEntered, self, defaultText or "", v30_, v31_, v33_, v32_, nil, nil, false)
end

-- Local values: upperText, length, item, errorCode, message
function ModHubExtraContentFrame:onExtraContentKeyEntered(text, ok, categoryId)
	if ok then
		local v37_ = utf8ToUpper(text)
		local v38_ = utf8Strlen(text)
		if GS_PLATFORM_PC and (v38_ >= 20 and v38_ <= 24) then
			YesNoDialog.show(self.onEShopOpen, self, g_i18n:getText("extraContent_eshopWarning"), "", g_i18n:getText("extraContent_eshopVisitShop"), g_i18n:getText("button_back"), nil, nil, nil, text)
			return
		end
		local v39_, v40_ = g_extraContentSystem:unlockItem(v37_, false)
		if v40_ == ExtraContentSystem.UNLOCKED then
			self:updateList()
			InfoDialog.show(string.format(g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCKED_ITEM), v39_.title))
			return
		end
		local v41_
		if v40_ == ExtraContentSystem.ERROR_ALREADY_UNLOCKED then
			v41_ = string.format(g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.ALREADY_UNLOCKED_ITEM), v39_.title)
		elseif v40_ == ExtraContentSystem.ERROR_KEY_INVALID_FORMAT then
			v41_ = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.INVALID_KEY_FORMAT)
		else
			v41_ = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.INVALID_KEY)
		end
		InfoDialog.show(v41_, self.onButtonUnlock, self, nil, nil, nil, text)
	end
end

function ModHubExtraContentFrame:onEShopOpen(yes, text)
	if yes then
		openWebFile(Platform.urlEshop, "key=" .. text)
	else
		self:onButtonUnlock(text)
	end
end

-- Local values: total
function ModHubExtraContentFrame:getNumberOfItemsInSection(list, section)
	local v46_ = #self.items
	if self.listSizeLimit == nil then
		return v46_
	end
	local v47_ = self.listSizeLimit
	return math.min(v46_, v47_)
end

-- Local values: item, iconElement
function ModHubExtraContentFrame:populateCellForItemInSection(list, section, index, cell)
	local v51_ = self.items[index]
	cell:getAttribute("icon"):setImageFilename(v51_.imageFilename)
	cell:getAttribute("nameLabel"):setText(v51_.title)
end
ModHubExtraContentFrame.L10N_SYMBOL = {
	["BUTTON_UNLOCK"] = "modHub_unlock",
	["UNLOCK_ITEM"] = "modHub_unlock",
	["UNLOCK_ITEM_KEY"] = "modHub_unlock_key",
	["UNLOCKED_ITEM"] = "modHub_unlocked_item",
	["ALREADY_UNLOCKED_ITEM"] = "modHub_already_unlocked_item",
	["INVALID_KEY"] = "modHub_invalid_key",
	["INVALID_KEY_FORMAT"] = "modHub_invalid_key_format"
}
