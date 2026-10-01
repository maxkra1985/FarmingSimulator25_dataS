TabbedMenu = {}
local TabbedMenu_mt = Class(TabbedMenu, ScreenElement)
TabbedMenu.PAGE_TAB_TEMPLATE_BUTTON_NAME = "tabButton"
TabbedMenu.NO_BUTTON_INFO = {}
TabbedMenu.DEFAULT_BUTTON_ACTIONS = { [InputAction.MENU_ACCEPT] = true, [InputAction.MENU_ACTIVATE] = true, [InputAction.MENU_CANCEL] = true, [InputAction.MENU_BACK] = true, [InputAction.MENU_EXTRA_1] = true, [InputAction.MENU_EXTRA_2] = true }
TabbedMenu.PAUSE_ACTIONS = { [InputAction.MENU_BACK] = true, [InputAction.MENU_PAGE_NEXT] = true, [InputAction.MENU_PAGE_PREV] = true }
TabbedMenu.MONEY_UPDATE_INTERVAL = 300
local NO_CALLBACK = function() end
function TabbedMenu.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or TabbedMenu_mt)
	self.pageFrames = {}
	self.pageTabs = {}
	self.pageTypeControllers = {}
	self.pageRoots = {}
	self.pageEnablingPredicates = {}
	self.disabledPages = {}
	self.enabledPages = {}
	self.currentPageId = 1
	self.currentPageListIndex = 1
	self.currentPage = nil
	self.restorePageIndex = 1
	self.restorePageScrollOffset = 0
	self.buttonActionCallbacks = {}
	self.defaultButtonActionCallbacks = {}
	self.defaultMenuButtonInfoByActions = {}
	self.customButtonEvents = {}
	self.clickBackCallback = NO_CALLBACK
	self.frameClosePageNextCallback = self:makeSelfCallback(self.onPageNext)
	self.frameClosePagePreviousCallback = self:makeSelfCallback(self.onPagePrevious)
	self.performBackgroundBlur = false
	return self
end
function TabbedMenu:delete()
	g_messageCenter:unsubscribeAll(self)
	TabbedMenu:superClass().delete(self)
end
function TabbedMenu:onGuiSetupFinished()
	TabbedMenu:superClass().onGuiSetupFinished(self)
	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
	self:setupMenuButtonInfo()
	if self.pagingElement.profile == "uiInGameMenuPaging" then
		self.pagingElement:setSize(1 - self.header.absSize[1])
	end
end
function TabbedMenu:exitMenu()
	self:changeScreen(nil)
end
function TabbedMenu:reset()
	TabbedMenu:superClass().reset(self)
	self.currentPageId = 1
	self.currentPage = nil
	self.restorePageIndex = 1
	self.restorePageScrollOffset = 0
end
function TabbedMenu:onOpen(element)
	TabbedMenu:superClass().onOpen(self)
	if self.performBackgroundBlur then
		g_depthOfFieldManager:pushArea(0, 0, 1, 1)
	end
	if not self.muteSound then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
	end
	if self.gameState ~= nil then
		g_gameStateManager:setGameState(self.gameState)
	end
	self:setSoundSuppressed(true)
	self:updatePages()
	if self.restorePageIndex ~= nil then
		self.currentPage = self.restorePage
		self.pageSelector:setState(self.restorePageIndex, true)
		if self.pagingTabList ~= nil then
			self.pagingTabList:scrollTo(self.restorePageScrollOffset)
		end
	end
	self:setSoundSuppressed(false)
	self:onMenuOpened()
end
function TabbedMenu:onClose(element)
	if self.currentPage ~= nil then
		self.currentPage:onFrameClose()
	end
	TabbedMenu:superClass().onClose(self)
	if self.performBackgroundBlur then
		g_depthOfFieldManager:popArea()
	end
	g_inputBinding:storeEventBindings()
	self:clearMenuButtonActions()
	self.restorePage = self.currentPage
	self.restorePageIndex = self.pageSelector:getState()
	if self.pagingTabList ~= nil then
		self.restorePageScrollOffset = self.pagingTabList.viewOffset
	end
	self.currentPage = nil
	self.currentPageId = nil
	if self.gameState ~= nil then
		g_currentMission:resetGameState()
	end
end
function TabbedMenu:update(dt)
	TabbedMenu:superClass().update(self, dt)
	if self.currentPage ~= nil and (FocusManager.currentGui ~= self.currentPage.name and not g_gui:getIsDialogVisible()) then
		FocusManager:setGui(self.currentPage.name)
	end
	if self.currentPage ~= nil then
		local listenerName = g_gui.currentListener ~= nil and g_gui.currentListener.name or nil
		if self.currentPage:isMenuButtonInfoDirty() and listenerName == self.name then
			self:assignMenuButtonInfo(self.currentPage:getMenuButtonInfo())
			self.currentPage:clearMenuButtonInfoDirty()
		end
		if self.currentPage:isTabbingMenuVisibleDirty() then
			self:updatePagingVisibility(self.currentPage:getTabbingMenuVisible())
		end
	end
end
function TabbedMenu:setupMenuButtonInfo() end
function TabbedMenu:addPageTab(frameController, iconFilename, iconUVs, iconSliceId, soundId)
	local tab = {}
	self.pageTabs[frameController] = tab
	tab.iconFilename = iconFilename
	tab.iconUVs = iconUVs
	tab.iconSliceId = iconSliceId
	tab.soundId = soundId
	function tab.onClickCallback()
		self:onPageClicked(self.activeDetailPage)
		local pageId = self.pagingElement:getPageIdByElement(frameController)
		local pageMappingIndex = self.pagingElement:getPageMappingIndex(pageId)
		if self.currentPage:requestClose(tab.onClickCallback) then
			self.pageSelector:setState(pageMappingIndex, true)
		end
	end
end
function TabbedMenu:onPageClicked(oldPage) end
function TabbedMenu:setPageTabEnabled(pageController, isEnabled, blockListReload)
	self.pageTabs[pageController].isDisabled = not isEnabled
	if not blockListReload then
		self.pagingTabList:reloadData()
	end
end
function TabbedMenu:rebuildTabList()
	self.enabledPages = {}
	for i, page in ipairs(self.pageFrames) do
		local pageId = self.pagingElement:getPageIdByElement(page)
		local enabled = not self.pagingElement:getIsPageDisabled(pageId)
		if enabled then
			table.insert(self.enabledPages, page)
		end
	end
	self.pagingTabList:reloadData()
	self.pagingTabList:setSelectedIndex(self.currentPageListIndex)
end
function TabbedMenu:getNumberOfItemsInSection(list, section)
	return #self.enabledPages
end
function TabbedMenu:populateCellForItemInSection(list, section, index, cell)
	local button = cell:getAttribute("tabButton")
	local tab = self.pageTabs[self.enabledPages[index]]
	button:setImageFilename(nil, tab.iconFilename)
	button:setImageUVs(nil, tab.iconUVs)
	button:setImageSlice(nil, tab.iconSliceId)
	if tab.soundId == nil then
		button:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
	else
		button:setClickSound(tab.soundId)
	end
	button.onClickCallback = tab.onClickCallback
end
function TabbedMenu:updatePages()
	for pageElement, predicate in pairs(self.pageEnablingPredicates) do
		local pageId = self.pagingElement:getPageIdByElement(pageElement)
		local enable = false
		if self.disabledPages[pageElement] == nil then
			enable = predicate()
		end
		self.pagingElement.neuterPageUpdates = true
		self.pagingElement:setPageIdDisabled(pageId, not enable)
		self.pagingElement.neuterPageUpdates = false
		self:setPageTabEnabled(pageElement, enable, true)
	end
	self:rebuildTabList()
	self:setPageSelectorTitles()
end
function TabbedMenu:clearMenuButtonActions()
	for k in pairs(self.buttonActionCallbacks) do
		self.buttonActionCallbacks[k] = nil
	end
	for i in ipairs(self.customButtonEvents) do
		g_inputBinding:removeActionEvent(self.customButtonEvents[i])
		self.customButtonEvents[i] = nil
	end
end
function TabbedMenu:assignMenuButtonInfo(menuButtonInfo)
	self:clearMenuButtonActions()
	for i, button in ipairs(self.menuButton) do
		local info = menuButtonInfo[i]
		local hasInfo = info ~= nil
		button:setVisible(hasInfo)
		if hasInfo then
			if info.inputAction == nil or InputAction[info.inputAction] == nil then
				continue
			end
			button:setInputAction(info.inputAction)
			if Platform.isMobile then
				if info.profile ~= nil then
					button:applyProfile(info.profile)
				else
					button:applyProfile("buttonBack")
				end
			end
			local buttonText = info.text
			if buttonText == nil and self.defaultMenuButtonInfoByActions[info.inputAction] ~= nil then
				buttonText = self.defaultMenuButtonInfoByActions[info.inputAction].text
			end
			button:setText(buttonText)
			local buttonClickCallback = info.callback or self.defaultButtonActionCallbacks[info.inputAction] or NO_CALLBACK
			local sound = GuiSoundPlayer.SOUND_SAMPLES.CLICK
			if info.inputAction == InputAction.MENU_BACK then
				sound = GuiSoundPlayer.SOUND_SAMPLES.BACK
			end
			if info.clickSound ~= nil then
				if info.clickSound ~= sound then
					sound = info.clickSound
					local oldButtonClickCallback = buttonClickCallback
					function buttonClickCallback(...)
						self:playSample(sound)
						self:setNextScreenClickSoundMuted()
						return oldButtonClickCallback(...)
					end
					button:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.NONE)
				else
					button:setClickSound(sound)
				end
			end
			local showForGameState = Platform.isMobile or not self.paused or info.showWhenPaused
			local showForCurrentState = showForGameState or TabbedMenu.PAUSE_ACTIONS[info.inputAction] ~= nil
			local disabled = info.disabled or not showForCurrentState
			if not disabled then
				if not TabbedMenu.DEFAULT_BUTTON_ACTIONS[info.inputAction] then
					local _, eventId = g_inputBinding:registerActionEvent(info.inputAction, nil, buttonClickCallback, false, true, false, true)
					g_inputBinding:setActionEventTextVisibility(eventId, false)
					table.insert(self.customButtonEvents, eventId)
				else
					self.buttonActionCallbacks[info.inputAction] = buttonClickCallback
				end
			end
			button.onClickCallback = buttonClickCallback
			button:setDisabled(disabled)
			local separator = button:getDescendantByName("separator")
			if separator ~= nil then
				separator:setVisible(i ~= 1)
			end
		end
	end
	if self.buttonActionCallbacks[InputAction.MENU_BACK] == nil then
		self.buttonActionCallbacks[InputAction.MENU_BACK] = self.clickBackCallback
	end
	self.buttonsPanel:invalidateLayout()
end
function TabbedMenu:setPageSelectorTitles()
	local texts = self.pagingElement:getPageTitles()
	self.pageSelector:setTexts(texts)
	self.pageSelector:setDisabled(#texts == 1)
	local id = self.pagingElement:getCurrentPageId()
	self.pageSelector.state = self.pagingElement:getPageMappingIndex(id)
end
function TabbedMenu:goToPage(page, muteSound)
	local oldMute = self.muteSound
	self.muteSound = muteSound
	local index = self.pagingElement:getPageMappingIndexByElement(page)
	if index ~= nil then
		self.pageSelector:setState(index, true)
	end
	self.muteSound = oldMute
end
function TabbedMenu:updatePagingVisibility(visible)
	self.header:setVisible(visible)
end
function TabbedMenu:onMenuActionClick(menuActionName)
	local buttonCallback = self.buttonActionCallbacks[menuActionName]
	if buttonCallback ~= nil and buttonCallback ~= NO_CALLBACK then
		return buttonCallback() or false
	end
	return true
end
function TabbedMenu:onClickOk()
	local eventUnused = self:onMenuActionClick(InputAction.MENU_ACCEPT)
	return eventUnused
end
function TabbedMenu:onClickBack()
	local eventUnused = true
	if self.currentPage == nil or self.currentPage:requestClose(self.clickBackCallback) then
		eventUnused = TabbedMenu:superClass().onClickBack(self) and self:onMenuActionClick(InputAction.MENU_BACK)
	end
	return eventUnused
end
function TabbedMenu:onClickCancel()
	local eventUnused = TabbedMenu:superClass().onClickCancel(self) and self:onMenuActionClick(InputAction.MENU_CANCEL)
	return eventUnused
end
function TabbedMenu:onClickActivate()
	local eventUnused = TabbedMenu:superClass().onClickActivate(self) and self:onMenuActionClick(InputAction.MENU_ACTIVATE)
	return eventUnused
end
function TabbedMenu:onClickMenuExtra1()
	local eventUnused = TabbedMenu:superClass().onClickMenuExtra1(self) and self:onMenuActionClick(InputAction.MENU_EXTRA_1)
	return eventUnused
end
function TabbedMenu:onClickMenuExtra2()
	local eventUnused = TabbedMenu:superClass().onClickMenuExtra2(self) and self:onMenuActionClick(InputAction.MENU_EXTRA_2)
	return eventUnused
end
function TabbedMenu:onClickPageSelection(state)
	if self.pagingElement:setPage(state) and not self.muteSound then
		local soundId = GuiSoundPlayer.SOUND_SAMPLES.CLICK
		if self.pageTabs[self.currentPage] ~= nil and self.pageTabs[self.currentPage].soundId ~= nil then
			soundId = self.pageTabs[self.currentPage].soundId
		end
		self:playSample(soundId)
	end
end
function TabbedMenu:onPagePrevious()
	if Platform.isMobile then
		if self.currentPage:getHasPreviousPage() then
			self.currentPage:onPreviousPage()
		end
	elseif self.currentPage:requestClose(self.frameClosePagePreviousCallback) then
		TabbedMenu:superClass().onPagePrevious(self)
	end
end
function TabbedMenu:onPageNext()
	if Platform.isMobile then
		if self.currentPage:getHasNextPage() then
			self.currentPage:onNextPage()
		end
	elseif self.currentPage:requestClose(self.frameClosePageNextCallback) then
		TabbedMenu:superClass().onPageNext(self)
	end
end
function TabbedMenu:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	if self.currentPage ~= nil then
		self.currentPage:onFrameClose()
		self.currentPage:setVisible(false)
	end
	g_inputBinding:storeEventBindings()
	local page = self.pagingElement:getPageElementByIndex(pageIndex)
	self.currentPage = page
	self.currentPageListIndex = pageMappingIndex
	if not skipTabVisualUpdate then
		self.currentPageId = pageIndex
		if self.pagingTabList ~= nil then
			self.pagingTabList:setSelectedIndex(pageMappingIndex)
		end
	end
	page:setVisible(true)
	page:setSoundSuppressed(true)
	FocusManager:setGui(page.name)
	page:setSoundSuppressed(false)
	self:updateButtonsPanel(page)
	self:updateTabDisplay()
	page:onFrameOpen()
end
function TabbedMenu:onTabMenuSelectionChanged() end
function TabbedMenu:onTabMenuScroll()
	self:updateTabDisplay()
end
function TabbedMenu:updateButtonsPanel(page)
	local buttonInfo = self:getPageButtonInfo(page)
	self:assignMenuButtonInfo(buttonInfo)
	if page.buttonBox ~= nil then
		page.buttonBox.parent:addElement(page.buttonBox)
	end
end
function TabbedMenu:updateTabDisplay()
	if Platform.isMobile then
		return
	else
		local list = self.pagingTabList
		if self.pagingTabPrevious ~= nil then
			local isFirstItemVisible = 0 < list.totalItemCount and list.sections[1].cells[1] ~= nil
			self.pagingTabPrevious:setVisible(not isFirstItemVisible)
			if not isFirstItemVisible then
				local itemToShow = list.firstVisibleItem - 1
				local prevElement = list.listItems[itemToShow].elements[1]
				self.pagingTabPrevious.elements[1]:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(prevElement.icon.uvs))
				self.pagingTabPrevious.elements[1]:setImageFilename(prevElement.icon.filename)
			end
		end
		if self.pagingTabNext ~= nil then
			local lastSection = list.sections[#list.sections]
			local isLastItemVisible = 0 < list.totalItemCount and lastSection.cells[lastSection.numItems] ~= nil
			self.pagingTabNext:setVisible(not isLastItemVisible)
			if not isLastItemVisible then
				local itemToShow = list.firstVisibleItem + list.visibleItems
				local nextElement = list.listItems[itemToShow].elements[1]
				self.pagingTabNext.elements[1]:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(nextElement.icon.uvs))
				self.pagingTabNext.elements[1]:setImageFilename(nextElement.icon.filename)
			end
		end
	end
end
function TabbedMenu:getPageButtonInfo(page)
	local buttonInfo = nil
	if page:getHasCustomMenuButtons() then
		buttonInfo = page:getMenuButtonInfo()
		return buttonInfo
	else
		buttonInfo = self.defaultMenuButtonInfo
		return buttonInfo
	end
end
function TabbedMenu:onPageUpdate() end
function TabbedMenu:onButtonBack()
	self:exitMenu()
end
function TabbedMenu:onMenuOpened() end
function TabbedMenu:registerPage(pageFrameElement, position, enablingPredicateFunction)
	if position == nil then
		position = #self.pageFrames + 1
	else
		position = math.max(1, math.min(#self.pageFrames + 1, position))
	end
	table.insert(self.pageFrames, position, pageFrameElement)
	self.pageTypeControllers[pageFrameElement:class()] = pageFrameElement
	local pageRoot = pageFrameElement.elements[1]
	self.pageRoots[pageFrameElement] = pageRoot
	self.pageEnablingPredicates[pageFrameElement] = enablingPredicateFunction
	pageFrameElement:setVisible(false)
	return pageRoot, position
end
function TabbedMenu:unregisterPage(pageFrameClass)
	local pageController = self.pageTypeControllers[pageFrameClass]
	local pageTab = nil
	local pageRoot = nil
	if pageController ~= nil then
		local pageRemoveIndex = -1
		for i, page in ipairs(self.pageFrames) do
			if page == pageController then
				pageRemoveIndex = i
				break
			end
		end
		table.remove(self.pageFrames, pageRemoveIndex)
		pageRoot = self.pageRoots[pageController]
		self.pageRoots[pageController] = nil
		self.pageTypeControllers[pageFrameClass] = nil
		self.pageEnablingPredicates[pageController] = nil
		self.pageTabs[pageController] = nil
	end
	return pageController ~= nil, pageController, pageRoot, nil
end
function TabbedMenu:addPage(pageFrameElement, position, tabIconFilename, tabIconUVs, enablingPredicateFunction)
	local pageRoot, actualPosition = self:registerPage(pageFrameElement, position, enablingPredicateFunction)
	self:addPageTab(pageFrameElement, tabIconFilename, GuiUtils.getUVs(tabIconUVs))
	local name = pageRoot.title
	if name == nil then
		name = g_i18n:getText("ui_" .. pageRoot.name)
	end
	self.pagingElement:addPage(string.upper(pageRoot.name), pageRoot, name, actualPosition)
end
function TabbedMenu:removePage(pageFrameClass)
	local defaultPage = self.pageTypeControllers[pageFrameClass]
	if self.defaultPageElementIDs[defaultPage] ~= nil then
		self:setPageEnabled(pageFrameClass, false)
	else
		local needDelete, pageController, pageRoot, pageTab = self:unregisterPage(pageFrameClass)
		if needDelete then
			self.pagingElement:removeElement(pageRoot)
			pageRoot:delete()
			pageController:delete()
			if self.pagingTabList ~= nil then
				self.pagingTabList:removeElement(pageTab)
			end
			pageTab:delete()
		end
	end
end
function TabbedMenu:setPageEnabled(pageFrameClass, isEnabled)
	local pageController = self.pageTypeControllers[pageFrameClass]
	if pageController ~= nil then
		local pageId = self.pagingElement:getPageIdByElement(pageController)
		self.pagingElement:setPageIdDisabled(pageId, not isEnabled)
		pageController:setDisabled(not isEnabled)
		if not isEnabled then
			self.disabledPages[pageController] = pageController
		else
			self.disabledPages[pageController] = nil
		end
		self:setPageTabEnabled(pageController, isEnabled)
		if self.pagingTabList ~= nil then
			self.pagingTabList:updateView()
		end
	end
end
function TabbedMenu:makeSelfCallback(func)
	return function(...)
		return func(self, ...)
	end
end
TabbedMenu.PROFILE = { PAGE_TAB = "uiTabbedMenuPageTab", PAGE_TAB_ACTIVE = "uiTabbedMenuPageTabActive" }
