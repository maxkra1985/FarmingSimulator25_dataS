-- Local values: InGameMenuMainFrame_mt
InGameMenuMainFrame = {}
local InGameMenuMainFrame_mt = Class(InGameMenuMainFrame, TabbedMenuFrameElement)
function InGameMenuMainFrame.register()
	local v2_ = InGameMenuMainFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuMainFrame.xml", "MainFrame", v2_, true)
end

-- Upvalues: InGameMenuMainFrame_mt
-- Local values: self
function InGameMenuMainFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuMainFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMainFrame_mt)
	v5_.lastFocusedButton = nil
	v5_.goToMainOverview = false
	return v5_
end

-- Local values: newGui
function InGameMenuMainFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuMainFrame.new(nil)
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function InGameMenuMainFrame:initialize()
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}
	self.quitButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["profile"] = "buttonQuitGame",
		["text"] = g_i18n:getText(InGameMenu.L10N_SYMBOL.BUTTON_CANCEL_GAME)
	}
end

-- Local values: isTourActive
function InGameMenuMainFrame:onFrameOpen(element)
	InGameMenuMainFrame:superClass().onFrameOpen(self)
	local v11_ = g_guidedTourManager:getIsTourRunning()
	self.tourButton:setVisible(v11_)
	self.hintsButton:setVisible(not v11_)
	self.updateButtonsForTour = true
	self.menuButtonInfo = { self.backButtonInfo, self.quitButtonInfo }
	self.calendarButton:setVisible(g_currentMission.missionInfo.growthMode == GrowthMode.SEASONAL)
	self.container:invalidateLayout()
	self:setMenuButtonInfoDirty()
	self.setInitialFocus = false
	if self.lastFocusedButton == nil then
		self.lastFocusedButton = FocusManager.currentFocusData.initialFocusElement
	end
end

function InGameMenuMainFrame:onPreviousPage()
	if not Platform.isMobile then
		InGameMenuMainFrame:superClass().onPreviousPage(self)
	end
end

function InGameMenuMainFrame:onNextPage()
	if not Platform.isMobile then
		InGameMenuMainFrame:superClass().onNextPage(self)
	end
end

function InGameMenuMainFrame:getMainElementSize()
	return self.container.size
end

function InGameMenuMainFrame:getMainElementPosition()
	return self.container.absPosition
end

-- Local values: isTourActive, resetInitialFocus
function InGameMenuMainFrame:update(dt)
	InGameMenuMainFrame:superClass().update(self, dt)
	if self.updateButtonsForTour then
		local v18_ = g_guidedTourManager:getIsTourRunning()
		self.weatherButton:setDisabled(v18_)
		self.pricesButton:setDisabled(v18_)
		self.vehicleButton:setDisabled(v18_)
		self.financesButton:setDisabled(v18_)
		self.animalsButton:setDisabled(v18_)
		self.productionButton:setDisabled(v18_)
		self.statisticsButton:setDisabled(v18_)
		self.settingsButton:setDisabled(v18_)
		self.hintsButton:setDisabled(v18_)
		self.tourButton:setDisabled(not v18_)
		self.updateButtonsForTour = false
	end
	if self.setInitialFocus and not g_savegameController:getIsSaving() then
		if self.lastFocusedButton.disabled then
			self.lastFocusedButton = self.helpButton
		end
		if g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_GAMEPAD and true or FocusManager:setFocus(self.lastFocusedButton) or self.lastFocusedButton == self.weatherButton then
			self.setInitialFocus = nil
			return
		end
	elseif self.setInitialFocus == false then
		self.setInitialFocus = true
	end
end

function InGameMenuMainFrame:onClickCalendar()
	self.lastFocusedButton = self.calendarButton
	g_inGameMenu:goToPage(g_inGameMenu.pageCalendar, true)
end

function InGameMenuMainFrame:onClickPrices()
	self.lastFocusedButton = self.pricesButton
	g_inGameMenu:goToPage(g_inGameMenu.pageStatistics, true)
end

function InGameMenuMainFrame:onClickVehicles()
	self.lastFocusedButton = self.vehicleButton
	g_inGameMenu:goToPage(g_inGameMenu.pageStatistics, true)
end

function InGameMenuMainFrame:onClickSettings()
	self.lastFocusedButton = self.settingsButton
	g_inGameMenu:goToPage(g_inGameMenu.pageSettingsMobile, true)
end

function InGameMenuMainFrame:onClickAnimals()
	self.lastFocusedButton = self.animalsButton
	g_inGameMenu:goToPage(g_inGameMenu.pageAnimals, true)
end

function InGameMenuMainFrame:onClickProduction()
	self.lastFocusedButton = self.productionButton
	g_inGameMenu:goToPage(g_inGameMenu.pageProduction, true)
end

function InGameMenuMainFrame:onClickStatistics()
	self.lastFocusedButton = self.statisticsButton
	g_inGameMenu:goToPage(g_inGameMenu.pageStatistics, true)
end

function InGameMenuMainFrame:onClickHelp()
	self.lastFocusedButton = self.helpButton
	g_inGameMenu:goToPage(g_inGameMenu.pageHelpLine, true)
end

function InGameMenuMainFrame:onClickHints()
	self.lastFocusedButton = self.hintsButton
	g_inGameMenu:goToPage(g_inGameMenu.pageHint, true)
end

function InGameMenuMainFrame:onClickTour()
	self.lastFocusedButton = self.tourButton
	g_inGameMenu:goToPage(g_inGameMenu.pageTour, true)
end
