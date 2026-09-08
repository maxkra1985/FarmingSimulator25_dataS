-- Local values: PagingElement_mt
PagingElement = {}
local PagingElement_mt = Class(PagingElement, GuiElement)
Gui.registerGuiElement("Paging", PagingElement)

-- Upvalues: PagingElement_mt
-- Local values: self
function PagingElement.new(target, custom_mt)
	-- upvalues: (copy) PagingElement_mt
	if custom_mt == nil then
		custom_mt = PagingElement_mt
	end
	local v4_ = GuiElement.new(target, custom_mt)
	v4_:include(IndexChangeSubjectMixin)
	v4_.pageIdCount = 1
	v4_.pages = {}
	v4_.idPageHash = {}
	v4_.pageMapping = {}
	v4_.currentPageIndex = 1
	v4_.currentPageMappingIndex = 1
	return v4_
end

function PagingElement:loadFromXML(xmlFile, key)
	PagingElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onPageChange", "onPageChangeCallback")
	self:addCallback(xmlFile, key .. "#onPageUpdate", "onPageUpdateCallback")
end

function PagingElement:copyAttributes(src)
	PagingElement:superClass().copyAttributes(self, src)
	self.onPageChangeCallback = src.onPageChangeCallback
	self.onPageUpdateCallback = src.onPageUpdateCallback
	GuiMixin.cloneMixin(IndexChangeSubjectMixin, src, self)
end

function PagingElement:onGuiSetupFinished()
	PagingElement:superClass().onGuiSetupFinished(self)
	self:updatePageMapping()
end

-- Local values: _, page, prevIndex, hasChange
function PagingElement:setPage(pageMappingIndex)
	for _, v13_ in pairs(self.pages) do
		v13_.element:setVisible(false)
	end
	local v14_ = #self.pageMapping
	local v15_ = math.clamp(pageMappingIndex, 1, v14_)
	self.currentPageMappingIndex = v15_
	local v16_ = self.currentPageIndex
	self.currentPageIndex = self.pageMapping[v15_]
	local v17_ = v16_ ~= self.currentPageIndex
	self.pages[self.currentPageIndex].element:setVisible(true)
	self:raiseCallback("onPageChangeCallback", self.currentPageIndex, self.currentPageMappingIndex, self)
	self:notifyIndexChange(self.currentPageMappingIndex, #self.pageMapping)
	return v17_
end

function PagingElement:addElement(element)
	PagingElement:superClass().addElement(self, element)
	if element.name == nil or not g_i18n:hasText("ui_" .. element.name) then
		self:addPage(tostring(element), element, "")
	else
		self:addPage(string.upper(element.name), element, g_i18n:getText("ui_" .. element.name))
	end
end

-- Local values: id
function PagingElement:getNextID()
	local v21_ = self.pageIdCount
	self.pageIdCount = self.pageIdCount + 1
	return v21_
end

-- Local values: newIndex, page, insertIndex
function PagingElement:addPage(id, element, title, index)
	local v27_ = self:getNextID()
	if self.currentPageIndex == nil then
		self.currentPageIndex = v27_
		self.currentPageMappingIndex = self.currentPageIndex
	end
	local v28_ = {
		["id"] = v27_,
		["mappingIndex"] = 0,
		["idName"] = id,
		["element"] = element,
		["title"] = title,
		["disabled"] = false
	}
	local v29_ = index or #self.pages + 1
	local v30_ = self.pages
	table.insert(v30_, v29_, v28_)
	self.idPageHash[v28_.id] = v28_
	element:setVisible(false)
	self:updatePageMapping()
	return v28_
end

function PagingElement:getVisiblePagesCount()
	return #self.pageMapping
end

-- Local values: _, page
function PagingElement:getPageIdByElement(element)
	for _, v34_ in pairs(self.pages) do
		if v34_.element == element then
			return v34_.id
		end
	end
	return nil
end

-- Local values: element, page
function PagingElement:getPageElementByIndex(pageIndex)
	local v37_ = self.pages[pageIndex]
	local v38_
	if v37_ then
		v38_ = v37_.element
	else
		v38_ = nil
	end
	return v38_
end

-- Local values: i, page
function PagingElement:getPageIndexByElement(element)
	for v41_, v42_ in ipairs(self.pages) do
		if v42_.element == element then
			return v41_
		end
	end
	return nil
end

-- Local values: _, page
function PagingElement:getPageMappingIndexByElement(element)
	for _, v45_ in ipairs(self.pages) do
		if v45_.element == element then
			return v45_.mappingIndex
		end
	end
	return nil
end

-- Local values: removeIndex, removeId, i, page, removedElement
function PagingElement:removePageByElement(pageElement)
	local v48_ = -1
	local v49_ = -1
	for v50_, v51_ in ipairs(self.pages) do
		if v51_.element == pageElement then
			v49_ = v51_.id
			v48_ = v50_
			break
		end
	end
	if table.remove(self.pages, v48_) then
		self.currentPageIndex = 1
		self.idPageHash[v49_] = nil
		self:updatePageMapping()
	end
end

function PagingElement:removeElement(element)
	PagingElement:superClass().removeElement(self, element)
	self:removePageByElement(element)
end

function PagingElement:getCurrentPageId()
	return self.pages[self.currentPageIndex].id
end

function PagingElement:getPageMappingIndex(pageId)
	return self.idPageHash[pageId].mappingIndex
end

function PagingElement:getIsPageDisabled(pageId)
	return self.idPageHash[pageId].disabled
end

function PagingElement:getPageById(pageId)
	return self.idPageHash[pageId]
end

function PagingElement:setPageDisabled(page, disabled)
	if page ~= nil then
		page.disabled = disabled
		self:updatePageMapping()
		self:raiseCallback("onPageUpdateCallback", page, self)
	end
end

function PagingElement:setPageIdDisabled(pageId, disabled)
	if self.idPageHash[pageId] ~= nil then
		self:setPageDisabled(self.idPageHash[pageId], disabled)
	end
end

-- Local values: currentPage, i, page
function PagingElement:updatePageMapping()
	self.pageMapping = {}
	self.pageTitles = {}
	local v68_ = self.pages[self.currentPageIndex]
	for v69_, v70_ in ipairs(self.pages) do
		if v70_.disabled then
			if v70_ == v68_ then
				v68_ = nil
			end
			v70_.mappingIndex = 1
		else
			local v71_ = self.pageMapping
			table.insert(v71_, v69_)
			local v72_ = self.pageTitles
			local v73_ = v70_.title
			table.insert(v72_, v73_)
			v70_.mappingIndex = #self.pageMapping
		end
	end
	if v68_ == nil then
		if not self.neuterPageUpdates and #self.pageMapping > 0 then
			local v74_ = self.currentPageMappingIndex
			local v75_ = #self.pageMapping
			self.currentPageMappingIndex = math.clamp(v74_, 1, v75_)
			self:setPage(self.currentPageMappingIndex)
			return
		end
	else
		self:notifyIndexChange(self.currentPageMappingIndex, #self.pageMapping)
	end
end

function PagingElement:getPageTitles()
	return self.pageTitles
end

-- Local values: child
function PagingElement:onOpen()
	self:raiseCallback("onOpenCallback", self)
	self.pages[self.currentPageIndex].element:onOpen()
end

-- Local values: child
function PagingElement:onClose()
	self:raiseCallback("onCloseCallback", self)
	self.pages[self.currentPageIndex].element:onClose()
end
