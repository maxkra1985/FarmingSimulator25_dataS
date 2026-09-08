-- Local values: TabbedMenu_mt, NO_CALLBACK
TabbedMenu = {}
local TabbedMenu_mt = Class(TabbedMenu, ScreenElement)
TabbedMenu.PAGE_TAB_TEMPLATE_BUTTON_NAME = "tabButton"
TabbedMenu.NO_BUTTON_INFO = {}
TabbedMenu.DEFAULT_BUTTON_ACTIONS = {
	[InputAction.MENU_ACCEPT] = true,
	[InputAction.MENU_ACTIVATE] = true,
	[InputAction.MENU_CANCEL] = true,
	[InputAction.MENU_BACK] = true,
	[InputAction.MENU_EXTRA_1] = true,
	[InputAction.MENU_EXTRA_2] = true
}
TabbedMenu.PAUSE_ACTIONS = {
	[InputAction.MENU_BACK] = true,
	[InputAction.MENU_PAGE_NEXT] = true,
	[InputAction.MENU_PAGE_PREV] = true
}
TabbedMenu.MONEY_UPDATE_INTERVAL = 300
local function NO_CALLBACK() end

-- Upvalues: TabbedMenu_mt, NO_CALLBACK
-- Local values: self
function TabbedMenu.new(target, custom_mt)
	-- upvalues: (copy) TabbedMenu_mt, (copy) NO_CALLBACK
	local v5_ = ScreenElement.new(target, custom_mt or TabbedMenu_mt)
	v5_.pageFrames = {}
	v5_.pageTabs = {}
	v5_.pageTypeControllers = {}
	v5_.pageRoots = {}
	v5_.pageEnablingPredicates = {}
	v5_.disabledPages = {}
	v5_.enabledPages = {}
	v5_.currentPageId = 1
	v5_.currentPageListIndex = 1
	v5_.currentPage = nil
	v5_.restorePageIndex = 1
	v5_.restorePageScrollOffset = 0
	v5_.buttonActionCallbacks = {}
	v5_.defaultButtonActionCallbacks = {}
	v5_.defaultMenuButtonInfoByActions = {}
	v5_.customButtonEvents = {}
	v5_.clickBackCallback = NO_CALLBACK
	v5_.frameClosePageNextCallback = v5_:makeSelfCallback(v5_.onPageNext)
	v5_.frameClosePagePreviousCallback = v5_:makeSelfCallback(v5_.onPagePrevious)
	v5_.performBackgroundBlur = false
	return v5_
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

-- Local values: listenerName
function TabbedMenu:update(dt)
	TabbedMenu:superClass().update(self, dt)
	if self.currentPage ~= nil and (FocusManager.currentGui ~= self.currentPage.name and not g_gui:getIsDialogVisible()) then
		FocusManager:setGui(self.currentPage.name)
	end
	if self.currentPage ~= nil then
		local v14_
		if g_gui.currentListener == nil then
			v14_ = nil
		else
			v14_ = g_gui.currentListener.name or nil
		end
		if self.currentPage:isMenuButtonInfoDirty() and v14_ == self.name then
			self:assignMenuButtonInfo(self.currentPage:getMenuButtonInfo())
			self.currentPage:clearMenuButtonInfoDirty()
		end
		if self.currentPage:isTabbingMenuVisibleDirty() then
			self:updatePagingVisibility(self.currentPage:getTabbingMenuVisible())
		end
	end
end

function TabbedMenu:setupMenuButtonInfo() end

-- Local values: tab
function TabbedMenu:addPageTab(frameController, iconFilename, iconUVs, iconSliceId, soundId)
	local v_u_21_ = {}
	self.pageTabs[frameController] = v_u_21_
	v_u_21_.iconFilename = iconFilename
	v_u_21_.iconUVs = iconUVs
	v_u_21_.iconSliceId = iconSliceId
	v_u_21_.soundId = soundId
	function v_u_21_.onClickCallback()
		-- upvalues: (copy) self, (copy) frameController, (copy) v_u_21_
		self:onPageClicked(self.activeDetailPage)
		local v22_ = self.pagingElement:getPageIdByElement(frameController)
		local v23_ = self.pagingElement:getPageMappingIndex(v22_)
		if self.currentPage:requestClose(v_u_21_.onClickCallback) then
			self.pageSelector:setState(v23_, true)
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

-- Local values: i, page, pageId, enabled
function TabbedMenu:rebuildTabList()
	self.enabledPages = {}
	for _, v29_ in ipairs(self.pageFrames) do
		local v30_ = self.pagingElement:getPageIdByElement(v29_)
		if not self.pagingElement:getIsPageDisabled(v30_) then
			local v31_ = self.enabledPages
			table.insert(v31_, v29_)
		end
	end
	self.pagingTabList:reloadData()
	self.pagingTabList:setSelectedIndex(self.currentPageListIndex)
end

function TabbedMenu:getNumberOfItemsInSection(list, section)
	return #self.enabledPages
end

-- Local values: button, tab
function TabbedMenu:populateCellForItemInSection(list, section, index, cell)
	local v36_ = cell:getAttribute("tabButton")
	local v37_ = self.pageTabs[self.enabledPages[index]]
	v36_:setImageFilename(nil, v37_.iconFilename)
	v36_:setImageUVs(nil, v37_.iconUVs)
	v36_:setImageSlice(nil, v37_.iconSliceId)
	if v37_.soundId == nil then
		v36_:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
	else
		v36_:setClickSound(v37_.soundId)
	end
	v36_.onClickCallback = v37_.onClickCallback
end

-- Local values: pageElement, predicate, pageId, enable
function TabbedMenu:updatePages()
	for v39_, v40_ in pairs(self.pageEnablingPredicates) do
		local v41_ = self.pagingElement:getPageIdByElement(v39_)
		local v42_
		if self.disabledPages[v39_] == nil then
			v42_ = v40_()
		else
			v42_ = false
		end
		self.pagingElement.neuterPageUpdates = true
		self.pagingElement:setPageIdDisabled(v41_, not v42_)
		self.pagingElement.neuterPageUpdates = false
		self:setPageTabEnabled(v39_, v42_, true)
	end
	self:rebuildTabList()
	self:setPageSelectorTitles()
end

-- Local values: k, i
function TabbedMenu:clearMenuButtonActions()
	for v44_ in pairs(self.buttonActionCallbacks) do
		self.buttonActionCallbacks[v44_] = nil
	end
	for v45_ in ipairs(self.customButtonEvents) do
		g_inputBinding:removeActionEvent(self.customButtonEvents[v45_])
		self.customButtonEvents[v45_] = nil
	end
end

-- Upvalues: NO_CALLBACK
-- Local values: i, button, info, hasInfo, buttonText, buttonClickCallback, sound, oldButtonClickCallback, showForGameState, showForCurrentState, disabled, _, eventId, separator
function TabbedMenu:assignMenuButtonInfo(menuButtonInfo)
	-- upvalues: (copy) NO_CALLBACK
	self:clearMenuButtonActions()
	for v48_, v49_ in ipairs(self.menuButton) do
		local v50_ = menuButtonInfo[v48_]
		local v51_ = v50_ ~= nil
		v49_:setVisible(v51_)
		if v51_ and (v50_.inputAction ~= nil and InputAction[v50_.inputAction] ~= nil) then
			v49_:setInputAction(v50_.inputAction)
			if Platform.isMobile then
				if v50_.profile == nil then
					v49_:applyProfile("buttonBack")
				else
					v49_:applyProfile(v50_.profile)
				end
			end
			local v52_ = v50_.text
			if v52_ == nil and self.defaultMenuButtonInfoByActions[v50_.inputAction] ~= nil then
				v52_ = self.defaultMenuButtonInfoByActions[v50_.inputAction].text
			end
			v49_:setText(v52_)
			local v_u_53_ = v50_.callback or (self.defaultButtonActionCallbacks[v50_.inputAction] or NO_CALLBACK)
			local v54_ = GuiSoundPlayer.SOUND_SAMPLES.CLICK
			if v50_.inputAction == InputAction.MENU_BACK then
				v54_ = GuiSoundPlayer.SOUND_SAMPLES.BACK
			end
			if v50_.clickSound == nil or v50_.clickSound == v54_ then
				v49_:setClickSound(v54_)
			else
				local v_u_55_ = v50_.clickSound
				v_u_53_ = function(...)
					-- upvalues: (copy) self, (ref) v_u_55_, (copy) v_u_53_
					self:playSample(v_u_55_)
					self:setNextScreenClickSoundMuted()
					return v_u_53_(...)
				end
				v49_:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.NONE)
			end
			local v56_ = Platform.isMobile or (not self.paused or v50_.showWhenPaused) or TabbedMenu.PAUSE_ACTIONS[v50_.inputAction] ~= nil
			local v57_ = v50_.disabled or not v56_
			if not v57_ then
				if TabbedMenu.DEFAULT_BUTTON_ACTIONS[v50_.inputAction] then
					self.buttonActionCallbacks[v50_.inputAction] = v_u_53_
				else
					local _, v58_ = g_inputBinding:registerActionEvent(v50_.inputAction, nil, v_u_53_, false, true, false, true)
					g_inputBinding:setActionEventTextVisibility(v58_, false)
					local v59_ = self.customButtonEvents
					table.insert(v59_, v58_)
				end
			end
			v49_.onClickCallback = v_u_53_
			v49_:setDisabled(v57_)
			local v60_ = v49_:getDescendantByName("separator")
			if v60_ ~= nil then
				v60_:setVisible(v48_ ~= 1)
			end
		end
	end
	if self.buttonActionCallbacks[InputAction.MENU_BACK] == nil then
		self.buttonActionCallbacks[InputAction.MENU_BACK] = self.clickBackCallback
	end
	self.buttonsPanel:invalidateLayout()
end

-- Local values: texts, id
function TabbedMenu:setPageSelectorTitles()
	local v62_ = self.pagingElement:getPageTitles()
	self.pageSelector:setTexts(v62_)
	self.pageSelector:setDisabled(#v62_ == 1)
	local v63_ = self.pagingElement:getCurrentPageId()
	self.pageSelector.state = self.pagingElement:getPageMappingIndex(v63_)
end

-- Local values: oldMute, index
function TabbedMenu:goToPage(page, muteSound)
	local v67_ = self.muteSound
	self.muteSound = muteSound
	local v68_ = self.pagingElement:getPageMappingIndexByElement(page)
	if v68_ ~= nil then
		self.pageSelector:setState(v68_, true)
	end
	self.muteSound = v67_
end

function TabbedMenu:updatePagingVisibility(visible)
	self.header:setVisible(visible)
end

-- Upvalues: NO_CALLBACK
-- Local values: buttonCallback
function TabbedMenu:onMenuActionClick(menuActionName)
	-- upvalues: (copy) NO_CALLBACK
	local v73_ = self.buttonActionCallbacks[menuActionName]
	return (v73_ == nil or v73_ == NO_CALLBACK) and true or (v73_() or false)
end

-- Local values: eventUnused
function TabbedMenu:onClickOk()
	return self:onMenuActionClick(InputAction.MENU_ACCEPT)
end

-- Local values: eventUnused
function TabbedMenu:onClickBack()
	local v76_ = (self.currentPage == nil or self.currentPage:requestClose(self.clickBackCallback)) and TabbedMenu:superClass().onClickBack(self)
	if v76_ then
		v76_ = self:onMenuActionClick(InputAction.MENU_BACK)
	end
	return v76_
end

-- Local values: eventUnused
function TabbedMenu:onClickCancel()
	local v78_ = TabbedMenu:superClass().onClickCancel(self)
	if v78_ then
		v78_ = self:onMenuActionClick(InputAction.MENU_CANCEL)
	end
	return v78_
end

-- Local values: eventUnused
function TabbedMenu:onClickActivate()
	local v80_ = TabbedMenu:superClass().onClickActivate(self)
	if v80_ then
		v80_ = self:onMenuActionClick(InputAction.MENU_ACTIVATE)
	end
	return v80_
end

-- Local values: eventUnused
function TabbedMenu:onClickMenuExtra1()
	local v82_ = TabbedMenu:superClass().onClickMenuExtra1(self)
	if v82_ then
		v82_ = self:onMenuActionClick(InputAction.MENU_EXTRA_1)
	end
	return v82_
end

-- Local values: eventUnused
function TabbedMenu:onClickMenuExtra2()
	local v84_ = TabbedMenu:superClass().onClickMenuExtra2(self)
	if v84_ then
		v84_ = self:onMenuActionClick(InputAction.MENU_EXTRA_2)
	end
	return v84_
end

-- Local values: soundId
function TabbedMenu:onClickPageSelection(state)
	if self.pagingElement:setPage(state) and not self.muteSound then
		local v87_ = GuiSoundPlayer.SOUND_SAMPLES.CLICK
		if self.pageTabs[self.currentPage] ~= nil and self.pageTabs[self.currentPage].soundId ~= nil then
			v87_ = self.pageTabs[self.currentPage].soundId
		end
		self:playSample(v87_)
	end
end

function TabbedMenu:onPagePrevious()
	if Platform.isMobile then
		if self.currentPage:getHasPreviousPage() then
			self.currentPage:onPreviousPage()
			return
		end
	elseif self.currentPage:requestClose(self.frameClosePagePreviousCallback) then
		TabbedMenu:superClass().onPagePrevious(self)
	end
end

function TabbedMenu:onPageNext()
	if Platform.isMobile then
		if self.currentPage:getHasNextPage() then
			self.currentPage:onNextPage()
			return
		end
	elseif self.currentPage:requestClose(self.frameClosePageNextCallback) then
		TabbedMenu:superClass().onPageNext(self)
	end
end

-- Local values: page
function TabbedMenu:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	if self.currentPage ~= nil then
		self.currentPage:onFrameClose()
		self.currentPage:setVisible(false)
	end
	g_inputBinding:storeEventBindings()
	local v94_ = self.pagingElement:getPageElementByIndex(pageIndex)
	self.currentPage = v94_
	self.currentPageListIndex = pageMappingIndex
	if not skipTabVisualUpdate then
		self.currentPageId = pageIndex
		if self.pagingTabList ~= nil then
			self.pagingTabList:setSelectedIndex(pageMappingIndex)
		end
	end
	v94_:setVisible(true)
	v94_:setSoundSuppressed(true)
	FocusManager:setGui(v94_.name)
	v94_:setSoundSuppressed(false)
	self:updateButtonsPanel(v94_)
	self:updateTabDisplay()
	v94_:onFrameOpen()
end

function TabbedMenu:onTabMenuSelectionChanged() end

function TabbedMenu:onTabMenuScroll()
	self:updateTabDisplay()
end

-- Local values: buttonInfo
function TabbedMenu:updateButtonsPanel(page)
	self:assignMenuButtonInfo((self:getPageButtonInfo(page)))
	if page.buttonBox ~= nil then
		page.buttonBox.parent:addElement(page.buttonBox)
	end
end

-- Local values: list, isFirstItemVisible, itemToShow, prevElement, lastSection, isLastItemVisible, itemToShow, nextElement
function TabbedMenu:updateTabDisplay()
	if not Platform.isMobile then
		local v99_ = self.pagingTabList
		if self.pagingTabPrevious ~= nil then
			local v100_
			if v99_.totalItemCount > 0 then
				v100_ = v99_.sections[1].cells[1] ~= nil
			else
				v100_ = false
			end
			self.pagingTabPrevious:setVisible(not v100_)
			if not v100_ then
				local v101_ = v99_.firstVisibleItem - 1
				local v102_ = v99_.listItems[v101_].elements[1]
				local v103_ = self.pagingTabPrevious.elements[1]
				local v104_ = GuiOverlay.STATE_NORMAL
				local v105_ = v102_.icon.uvs
				v103_:setImageUVs(v104_, unpack(v105_))
				self.pagingTabPrevious.elements[1]:setImageFilename(v102_.icon.filename)
			end
		end
		if self.pagingTabNext ~= nil then
			local v106_ = v99_.sections[#v99_.sections]
			local v107_
			if v99_.totalItemCount > 0 then
				v107_ = v106_.cells[v106_.numItems] ~= nil
			else
				v107_ = false
			end
			self.pagingTabNext:setVisible(not v107_)
			if not v107_ then
				local v108_ = v99_.firstVisibleItem + v99_.visibleItems
				local v109_ = v99_.listItems[v108_].elements[1]
				local v110_ = self.pagingTabNext.elements[1]
				local v111_ = GuiOverlay.STATE_NORMAL
				local v112_ = v109_.icon.uvs
				v110_:setImageUVs(v111_, unpack(v112_))
				self.pagingTabNext.elements[1]:setImageFilename(v109_.icon.filename)
			end
		end
	end
end

-- Local values: buttonInfo
function TabbedMenu:getPageButtonInfo(page)
	if page:getHasCustomMenuButtons() then
		return page:getMenuButtonInfo()
	else
		return self.defaultMenuButtonInfo
	end
end

function TabbedMenu:onPageUpdate() end

function TabbedMenu:onButtonBack()
	self:exitMenu()
end

function TabbedMenu:onMenuOpened() end

-- Local values: pageRoot
function TabbedMenu:registerPage(pageFrameElement, position, enablingPredicateFunction)
	local v120_
	if position == nil then
		v120_ = #self.pageFrames + 1
	else
		local v121_ = #self.pageFrames + 1
		local v122_ = math.min(v121_, position)
		v120_ = math.max(1, v122_)
	end
	local v123_ = self.pageFrames
	table.insert(v123_, v120_, pageFrameElement)
	self.pageTypeControllers[pageFrameElement:class()] = pageFrameElement
	local v124_ = pageFrameElement.elements[1]
	self.pageRoots[pageFrameElement] = v124_
	self.pageEnablingPredicates[pageFrameElement] = enablingPredicateFunction
	pageFrameElement:setVisible(false)
	return v124_, v120_
end

-- Local values: pageController, pageTab, pageRoot, pageRemoveIndex, i, page
function TabbedMenu:unregisterPage(pageFrameClass)
	local v127_ = self.pageTypeControllers[pageFrameClass]
	local v128_
	if v127_ == nil then
		v128_ = nil
	else
		local v129_ = -1
		for v130_, v131_ in ipairs(self.pageFrames) do
			if v131_ == v127_ then
				v129_ = v130_
				break
			end
		end
		table.remove(self.pageFrames, v129_)
		v128_ = self.pageRoots[v127_]
		self.pageRoots[v127_] = nil
		self.pageTypeControllers[pageFrameClass] = nil
		self.pageEnablingPredicates[v127_] = nil
		self.pageTabs[v127_] = nil
	end
	return v127_ ~= nil, v127_, v128_, nil
end

-- Local values: pageRoot, actualPosition, name
function TabbedMenu:addPage(pageFrameElement, position, tabIconFilename, tabIconUVs, enablingPredicateFunction)
	local v138_, v139_ = self:registerPage(pageFrameElement, position, enablingPredicateFunction)
	self:addPageTab(pageFrameElement, tabIconFilename, GuiUtils.getUVs(tabIconUVs))
	local v140_ = v138_.title
	if v140_ == nil then
		v140_ = g_i18n:getText("ui_" .. v138_.name)
	end
	self.pagingElement:addPage(string.upper(v138_.name), v138_, v140_, v139_)
end

-- Local values: defaultPage, needDelete, pageController, pageRoot, pageTab
function TabbedMenu:removePage(pageFrameClass)
	local v143_ = self.pageTypeControllers[pageFrameClass]
	if self.defaultPageElementIDs[v143_] == nil then
		local v144_, v145_, v146_, v147_ = self:unregisterPage(pageFrameClass)
		if v144_ then
			self.pagingElement:removeElement(v146_)
			v146_:delete()
			v145_:delete()
			if self.pagingTabList ~= nil then
				self.pagingTabList:removeElement(v147_)
			end
			v147_:delete()
		end
	else
		self:setPageEnabled(pageFrameClass, false)
	end
end

-- Local values: pageController, pageId
function TabbedMenu:setPageEnabled(pageFrameClass, isEnabled)
	local v151_ = self.pageTypeControllers[pageFrameClass]
	if v151_ ~= nil then
		local v152_ = self.pagingElement:getPageIdByElement(v151_)
		self.pagingElement:setPageIdDisabled(v152_, not isEnabled)
		v151_:setDisabled(not isEnabled)
		if isEnabled then
			self.disabledPages[v151_] = nil
		else
			self.disabledPages[v151_] = v151_
		end
		self:setPageTabEnabled(v151_, isEnabled)
		if self.pagingTabList ~= nil then
			self.pagingTabList:updateView()
		end
	end
end

function TabbedMenu:makeSelfCallback(func)
	return function(...)
		-- upvalues: (copy) func, (copy) self
		return func(self, ...)
	end
end
TabbedMenu.PROFILE = {
	["PAGE_TAB"] = "uiTabbedMenuPageTab",
	["PAGE_TAB_ACTIVE"] = "uiTabbedMenuPageTabActive"
}
