-- Local values: WardrobeColorsFrame_mt
WardrobeColorsFrame = {}
local WardrobeColorsFrame_mt = Class(WardrobeColorsFrame, TabbedMenuFrameElement)
function WardrobeColorsFrame.register()
	local v2_ = WardrobeColorsFrame.new()
	g_gui:loadGui("dataS/gui/WardrobeColorsFrame.xml", "WardrobeColorsFrame", v2_, true)
end

-- Upvalues: WardrobeColorsFrame_mt
-- Local values: self
function WardrobeColorsFrame.new(target, custom_mt)
	-- upvalues: (copy) WardrobeColorsFrame_mt
	local v_u_5_ = TabbedMenuFrameElement.new(target, custom_mt or WardrobeColorsFrame_mt)
	v_u_5_.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
		["callback"] = function()
			-- upvalues: (copy) v_u_5_
			v_u_5_:onClickBack()
		end
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
	v_u_5_.hasCustomMenuButtons = true
	v_u_5_.menuButtonInfo = {
		v_u_5_.backButtonInfo,
		v_u_5_.nextPageButtonInfo,
		v_u_5_.prevPageButtonInfo,
		v_u_5_.equipButtonInfo
	}
	return v_u_5_
end

-- Local values: newGui
function WardrobeColorsFrame.createFromExistingGui(gui, guiName)
	local v8_ = WardrobeColorsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function WardrobeColorsFrame:onGuiSetupFinished()
	WardrobeColorsFrame:superClass().onGuiSetupFinished(self)
	self.primaryList:setDataSource(self)
	self.primaryList:setDelegate(self)
end

function WardrobeColorsFrame:initialize(delegate)
	self.delegate = delegate
end

function WardrobeColorsFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
	self.playerStyle = playerStyle
	self.savedPlayerStyle = savedPlayerStyle
end

function WardrobeColorsFrame:setConfigAndItem(configName, item)
	self.configName = configName
	self.item = item
	self.primaryList:reloadData()
	FocusManager:setFocus(self.primaryList)
	self.primaryList:setSelectedIndex(self.playerStyle.configs[self.configName].selectedColorIndex)
end

function WardrobeColorsFrame:onFrameOpen()
	WardrobeColorsFrame:superClass().onFrameOpen(self)
end

function WardrobeColorsFrame:getNumberOfItemsInSection(list, section)
	return (self.delegate == nil or self.item == nil) and 0 or #self.item.possibleColors
end

-- Local values: color
function WardrobeColorsFrame:populateCellForItemInSection(list, section, index, cell)
	local v23_ = self.item.possibleColors[index].primary
	cell:getAttribute("icon"):setImageColor(nil, v23_.r, v23_.g, v23_.b, 1)
	local v24_ = cell:getAttribute("selected")
	local v25_
	if self.savedPlayerStyle.configs[self.configName].selectedItemIndex == self.item.itemIndex then
		v25_ = self.savedPlayerStyle.configs[self.configName].selectedColorIndex == index
	else
		v25_ = false
	end
	v24_:setVisible(v25_)
end

-- Local values: config
function WardrobeColorsFrame:onListSelectionChanged(list, section, index)
	self.playerStyle.configs[self.configName]:setSelectedColorIndex(index)
	self.delegate:onColorSelectionChanged()
end

-- Local values: config
function WardrobeColorsFrame:onListHighlightChanged(list, section, index)
	if index == nil then
		self.delegate:onColorSelectionCancelled(true)
	else
		self.playerStyle.configs[self.configName]:setSelectedColorIndex(index)
		self.delegate:onColorSelectionChanged()
	end
end

function WardrobeColorsFrame:onClickSelect()
	self.delegate:onColorSelectionConfirmed(true)
	self.primaryList:reloadData()
end

function WardrobeColorsFrame:onDoubleClickSelect()
	self.delegate:onColorSelectionConfirmed()
end

function WardrobeColorsFrame:onClickBack()
	self.delegate:onColorSelectionCancelled()
end
