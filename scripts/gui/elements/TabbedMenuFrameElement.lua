-- Local values: TabbedMenuFrameElement_mt, NO_CALLBACK
TabbedMenuFrameElement = {}
local TabbedMenuFrameElement_mt = Class(TabbedMenuFrameElement, FrameElement)
local function NO_CALLBACK() end

-- Upvalues: TabbedMenuFrameElement_mt, NO_CALLBACK
-- Local values: self
function TabbedMenuFrameElement.new(target, customMt)
	-- upvalues: (copy) TabbedMenuFrameElement_mt, (copy) NO_CALLBACK
	local v5_ = FrameElement.new(target, customMt or TabbedMenuFrameElement_mt)
	v5_.hasCustomMenuButtons = false
	v5_.menuButtonInfo = {}
	v5_.menuButtonsDirty = false
	v5_.title = nil
	v5_.tabbingMenuVisibleDirty = false
	v5_.tabbingMenuVisible = true
	v5_.currentPage = 1
	v5_:setNumberOfPages(1)
	v5_.requestCloseCallback = NO_CALLBACK
	return v5_
end
function TabbedMenuFrameElement.initialize(_, ...) end

function TabbedMenuFrameElement:getHasCustomMenuButtons()
	return self.hasCustomMenuButtons
end

function TabbedMenuFrameElement:getMenuButtonInfo()
	return self.menuButtonInfo
end

function TabbedMenuFrameElement:setMenuButtonInfo(menuButtonInfo)
	self.menuButtonInfo = menuButtonInfo
	self.hasCustomMenuButtons = menuButtonInfo ~= nil
end

function TabbedMenuFrameElement:setMenuButtonInfoDirty()
	self.menuButtonsDirty = true
end

function TabbedMenuFrameElement:isMenuButtonInfoDirty()
	return self.menuButtonsDirty
end

function TabbedMenuFrameElement:clearMenuButtonInfoDirty()
	self.menuButtonsDirty = false
end

function TabbedMenuFrameElement:getMainElementSize()
	return { 1, 1 }
end

function TabbedMenuFrameElement:getMainElementPosition()
	return { 0, 0 }
end

-- Upvalues: NO_CALLBACK
function TabbedMenuFrameElement:requestClose(callback)
	-- upvalues: (copy) NO_CALLBACK
	self.requestCloseCallback = callback or NO_CALLBACK
	return true
end

function TabbedMenuFrameElement:onFrameOpen()
	TabbedMenuFrameElement:superClass().onOpen(self)
	self:updatePagingButtons()
end

function TabbedMenuFrameElement:onFrameClose()
	TabbedMenuFrameElement:superClass().onClose(self)
end

function TabbedMenuFrameElement:setTitle(title)
	self.title = title
	if self.pagingTitle ~= nil then
		self.pagingTitle:setText(title)
	end
end

function TabbedMenuFrameElement:getTitle()
	return self.title
end

function TabbedMenuFrameElement:setTabbingMenuVisible(visible)
	self.tabbingMenuVisible = visible
	self.tabbingMenuVisibleDirty = true
end

function TabbedMenuFrameElement:getTabbingMenuVisible()
	local v23_ = self.tabbingMenuVisible
	if v23_ then
		v23_ = not GS_IS_MOBILE_VERSION
	end
	return v23_
end

function TabbedMenuFrameElement:isTabbingMenuVisibleDirty()
	return self.tabbingMenuVisibleDirty
end

-- Local values: pagingElement, index
function TabbedMenuFrameElement:onNextPage()
	if Platform.isMobile then
		local v26_ = self.parent
		local v27_ = v26_.currentPageMappingIndex + 1
		local v28_ = #v26_.pageMapping < v27_ and 1 or v27_
		v26_.target:onClickPageSelection(v28_)
	elseif self.currentPage < self.numberOfPages then
		self.currentPage = self.currentPage + 1
		self:onPageChanged(self.currentPage, self.currentPage - 1)
	end
end

-- Local values: pagingElement, index
function TabbedMenuFrameElement:onPreviousPage()
	if Platform.isMobile then
		local v30_ = self.parent
		local v31_ = v30_.currentPageMappingIndex - 1
		if v31_ < 1 then
			v31_ = v30_.pageMapping[#v30_.pageMapping]
		end
		v30_.target:onClickPageSelection(v31_)
	elseif self.currentPage > 1 then
		self.currentPage = self.currentPage - 1
		self:onPageChanged(self.currentPage, self.currentPage + 1)
	end
end

function TabbedMenuFrameElement:getHasNextPage()
	if Platform.isMobile then
		return #self.parent.pageMapping > 1
	else
		return self.currentPage < self.numberOfPages
	end
end

function TabbedMenuFrameElement:getHasPreviousPage()
	if Platform.isMobile then
		return #self.parent.pageMapping > 1
	else
		return self.currentPage > 1
	end
end

-- Local values: oldPage
function TabbedMenuFrameElement:setNumberOfPages(num)
	self.numberOfPages = math.max(num, 1)
	local v36_ = self.currentPage
	local v37_ = self.currentPage
	local v38_ = math.min(v37_, num)
	self.currentPage = math.max(v38_, 1)
	if self.pagingIndexState ~= nil then
		self.pagingIndexState:setPageCount(self.numberOfPages, self.currentPage)
	end
	if v36_ == self.currentPage then
		self:updatePagingButtons()
	else
		self:onPageChanged(self.currentPage, self.currentPage)
	end
end

function TabbedMenuFrameElement:onPageChanged(page, pageFrom)
	if self.pagingIndexState ~= nil then
		self.pagingIndexState:setPageIndex(page)
	end
	self:updatePagingButtons()
end

-- Local values: showButtons
function TabbedMenuFrameElement:updatePagingButtons()
	if self.subPagingButtonLeft ~= nil then
		local v42_
		if self.numberOfPages == 1 then
			v42_ = false
		else
			v42_ = not self.pagingButtonsDisabled
		end
		self.subPagingButtonLeft:setDisabled(not v42_ or self.currentPage == 1)
		self.subPagingButtonRight:setDisabled(not v42_ or self.currentPage == self.numberOfPages)
	end
end

function TabbedMenuFrameElement:setPagingButtonsDisabled(disabled)
	self.pagingButtonsDisabled = disabled
	self:updatePagingButtons()
end

function TabbedMenuFrameElement:setPagingButtonsDirty()
	self:updatePagingButtons()
end

function TabbedMenuFrameElement:getCurrentPage()
	return self.currentPage
end
