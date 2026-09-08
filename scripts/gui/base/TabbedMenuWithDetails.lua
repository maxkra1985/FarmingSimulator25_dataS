-- Local values: TabbedMenuWithDetails_mt
TabbedMenuWithDetails = {}
local TabbedMenuWithDetails_mt = Class(TabbedMenuWithDetails, TabbedMenu)

-- Upvalues: TabbedMenuWithDetails_mt
-- Local values: self
function TabbedMenuWithDetails.new(target, custom_mt)
	-- upvalues: (copy) TabbedMenuWithDetails_mt
	local v4_ = TabbedMenu.new(target, custom_mt or TabbedMenuWithDetails_mt)
	v4_.stacks = {}
	return v4_
end

function TabbedMenuWithDetails:reset()
	TabbedMenuWithDetails:superClass().reset(self)
	self.stacks = {}
end

function TabbedMenuWithDetails:getIsDetailMode()
	return not self:isAtRoot()
end

function TabbedMenuWithDetails:exitMenu()
	self:popToRoot()
	TabbedMenuWithDetails:superClass().exitMenu(self)
end

-- Local values: top
function TabbedMenuWithDetails:onOpen(element)
	TabbedMenu:superClass().onOpen(self)
	if self.performBackgroundBlur then
		g_depthOfFieldManager:pushArea(0, 0, 1, 1)
	end
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
	if self.gameState ~= nil then
		g_gameStateManager:setGameState(self.gameState)
	end
	self:setSoundSuppressed(true)
	self.currentPage = self.currentPage or self.restorePage
	local v9_ = self:getTopFrame()
	if self:isAtRoot() then
		self:updatePages()
		self.pageSelector:setState(self.restorePageIndex, true)
	else
		v9_:onFrameOpen()
		self:updateButtonsPanel(v9_)
	end
	self:setSoundSuppressed(false)
	self:onMenuOpened()
end

function TabbedMenuWithDetails:onPageClicked(oldPage)
	self:popToRoot()
end

function TabbedMenuWithDetails:onDetailClosed(detailPage) end

function TabbedMenuWithDetails:onDetailOpened(detailPage) end

function TabbedMenuWithDetails:onButtonBack()
	if self:isAtRoot() then
		self:exitMenu()
	else
		self:popDetail()
	end
end

function TabbedMenuWithDetails:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	if self.isChangingDetail then
		skipTabVisualUpdate = true
	else
		self:popToRoot()
	end
	TabbedMenuWithDetails:superClass().onPageChange(self, pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
end

-- Local values: pageId, root
function TabbedMenuWithDetails:getStack(page)
	local v19_ = self.currentPageId or self.restorePageIndex
	if page == nil then
		page = self.pagingElement:getPageElementByIndex(v19_)
	else
		v19_ = self.pagingElement:getPageIndexByElement(page)
	end
	if self.stacks[v19_] == nil then
		self.stacks[v19_] = {}
		local v20_ = self.stacks[v19_]
		table.insert(v20_, {
			["page"] = page,
			["pageId"] = v19_,
			["isRoot"] = true
		})
	end
	return self.stacks[v19_]
end

function TabbedMenuWithDetails:isAtRoot()
	return #self:getStack() == 1
end

-- Local values: stack
function TabbedMenuWithDetails:getTopFrame()
	local v23_ = self:getStack()
	return v23_[#v23_].page
end

-- Local values: pageId
function TabbedMenuWithDetails:setPageDisabled(page, disabled)
	local v27_ = self.pagingElement:getPageIdByElement(page)
	self.pagingElement:setPageIdDisabled(v27_, disabled)
end

-- Local values: stack, closingPage, context
function TabbedMenuWithDetails:pushDetail(detailPage)
	local v30_ = self:getStack()
	self.isChangingDetail = true
	if not self:isAtRoot() then
		local v31_ = v30_[#v30_].page
		detailPage:setVisible(false)
		detailPage:onFrameClose()
		self:setPageDisabled(detailPage, true)
		self:onDetailClosed(v31_)
	end
	table.insert(v30_, {
		["page"] = detailPage
	})
	self:setPageDisabled(detailPage, false)
	detailPage:setSoundSuppressed(true)
	self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(detailPage))
	detailPage:setSoundSuppressed(false)
	self:onDetailOpened(detailPage)
	self.isChangingDetail = false
end

-- Local values: stack, closingPage, detailPage
function TabbedMenuWithDetails:popDetail()
	local v33_ = self:getStack()
	self.isChangingDetail = true
	if #v33_ == 1 then
		Logging.error("Cannot pop from view stack at root")
	else
		local v34_ = v33_[#v33_].page
		table.remove(v33_)
		v34_:setVisible(false)
		v34_:onFrameClose()
		self.pagingElement.neuterPageUpdates = true
		self:setPageDisabled(v34_, true)
		self:onDetailClosed(v34_)
		self.pagingElement.neuterPageUpdates = false
		if #v33_ == 1 then
			self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(v33_[1].page))
		else
			local v35_ = v33_[#v33_].page
			v35_:onFrameOpen()
			self:setPageDisabled(v35_, false)
			v35_:setSoundSuppressed(true)
			self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(v35_))
			v35_:setSoundSuppressed(false)
			self:onDetailOpened(v35_)
		end
		self.isChangingDetail = false
	end
end

-- Local values: stack, _
function TabbedMenuWithDetails:popToRoot()
	local v37_ = self:getStack()
	if #v37_ > 1 then
		for _ = #v37_, 2, -1 do
			self:popDetail()
		end
	end
end

function TabbedMenuWithDetails:replaceDetail(detailPage)
	self:popDetail()
	self:pushDetail(detailPage)
end

-- Local values: list, _, item
function TabbedMenuWithDetails:getBreadcrumbs(page)
	local v42_ = {}
	for _, v43_ in ipairs(self:getStack(page)) do
		local v44_ = v43_.page.title or ""
		table.insert(v42_, v44_)
	end
	return v42_
end
