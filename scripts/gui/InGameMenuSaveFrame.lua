-- Local values: InGameMenuSaveFrame_mt
InGameMenuSaveFrame = {}
InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS = 4
local InGameMenuSaveFrame_mt = Class(InGameMenuSaveFrame, TabbedMenuFrameElement)
function InGameMenuSaveFrame.register()
	local v2_ = InGameMenuSaveFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuSaveFrame.xml", "SaveFrame", v2_, true)
end

-- Upvalues: InGameMenuSaveFrame_mt
-- Local values: self
function InGameMenuSaveFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuSaveFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuSaveFrame_mt)
	v5_.hasMasterRights = false
	v5_.hasCustomMenuButtons = true
	v5_.gameplayHintsInitialized = false
	v5_.gameplayHintDuration = 6500
	v5_.gameplayHintTime = v5_.gameplayHintDuration
	return v5_
end

-- Local values: newGui
function InGameMenuSaveFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuSaveFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function InGameMenuSaveFrame:initialize()
	InGameMenuSaveFrame:superClass().initialize(self)
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
	self.selectButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText("button_select"),
		["callback"] = self.onMenuAccept,
		["showWhenPaused"] = true
	}
	self.saveButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("button_saveGame"),
		["callback"] = self.onButtonSaveGame,
		["showWhenPaused"] = true
	}
	self.quitButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_quit"),
		["callback"] = self.onButtonQuit,
		["showWhenPaused"] = true
	}
	self.menuButtonInfo = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo,
		self.selectButtonInfo,
		self.saveButtonInfo,
		self.quitButtonInfo
	}
	self.buttonOpenControls:setVisible(Platform.canChangeControls)
	self.buttonsLayout:invalidateLayout()
end

function InGameMenuSaveFrame:onFrameOpen()
	InGameMenuSaveFrame:superClass().onFrameOpen(self)
	if self.saveButton:getIsDisabled() ~= not self.hasMasterRights then
		self.saveButton:setDisabled(not self.hasMasterRights)
	end
	if self.saveButton:getIsDisabled() then
		FocusManager:setFocus(self.gameSettingsButton)
	end
	self:updateMenuButtons()
end

function InGameMenuSaveFrame:onFrameClose()
	InGameMenuSaveFrame:superClass().onFrameClose(self)
	self.gameplayHintsInitialized = false
end

function InGameMenuSaveFrame:setHasMasterRights(hasMasterRights)
	self.hasMasterRights = hasMasterRights
	if self.saveButton:getIsDisabled() ~= not self.hasMasterRights then
		self.saveButton:setDisabled(not self.hasMasterRights)
	end
	self:updateMenuButtons()
end

-- Local values: hints, texts, _, hint, text
function InGameMenuSaveFrame:update(dt)
	InGameMenuSaveFrame:superClass().update(self, dt)
	if self.gameplayHintsInitialized then
		self.gameplayHintTime = self.gameplayHintTime - dt
		if self.gameplayHintTime <= 0 then
			self.gameplayHintTime = self.gameplayHintDuration
			self.gameplayHintSelector.soundDisabled = true
			self.gameplayHintSelector:onRightButtonClicked(nil, true)
			self.gameplayHintSelector.soundDisabled = false
			return
		end
	elseif g_gameplayHintManager:getIsLoaded() then
		local v16_ = g_gameplayHintManager:getRandomGameplayHint(InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS)
		if v16_ ~= nil then
			local v17_ = {}
			for _, v18_ in ipairs(v16_) do
				local v19_ = string.gsub(v18_, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
				table.insert(v17_, v19_)
			end
			self.gameplayHintsInitialized = true
			self.gameplayHintSelector:setTexts(v17_)
			self.hintStateBox:setPageCount(InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS)
		end
		self.gameplayHintTime = self.gameplayHintDuration
	end
end

function InGameMenuSaveFrame:updateMenuButtons()
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if not self.gameplayHintSelector:getIsFocused() then
		local v21_ = self.menuButtonInfo
		local v22_ = self.selectButtonInfo
		table.insert(v21_, v22_)
	end
	if self.hasMasterRights then
		local v23_ = self.menuButtonInfo
		local v24_ = self.saveButtonInfo
		table.insert(v23_, v24_)
	end
	local v25_ = self.menuButtonInfo
	local v26_ = self.quitButtonInfo
	table.insert(v25_, v26_)
	self:setMenuButtonInfoDirty()
end

function InGameMenuSaveFrame:onButtonFocused(button)
	if not g_gui.currentlyReloading then
		FocusManager:linkElements(self.gameplayHintSelector, FocusManager.TOP, button)
		FocusManager:linkElements(self.gameplayHintSelector, FocusManager.BOTTOM, button)
	end
end

-- Local values: focusedButton
function InGameMenuSaveFrame:onMenuAccept()
	local v29_ = FocusManager:getFocusedElement()
	if v29_.onClickCallback ~= nil then
		v29_:onClickCallback()
	end
end

function InGameMenuSaveFrame:onButtonSaveGame()
	g_inGameMenu:onButtonSaveGame()
end

function InGameMenuSaveFrame:onButtonGameSettings()
	g_inGameMenu:openGameSettingsScreen()
end

function InGameMenuSaveFrame:onButtonControls()
	g_inGameMenu:openControlsScreen()
	g_inGameMenu.pageSettings.controlsList:makeCellVisible(1, 1)
	local v30_ = g_inGameMenu.pageSettings
	local v31_ = g_inGameMenu.pageSettings
	v30_.nextFocusSection = 1
	v31_.nextFocusCell = 1
end

function InGameMenuSaveFrame:onButtonHelp()
	g_inGameMenu:openHelpLine()
end

function InGameMenuSaveFrame:onButtonQuit()
	g_inGameMenu:onButtonQuit()
end
