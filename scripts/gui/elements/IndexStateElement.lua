-- Local values: IndexStateElement_mt
IndexStateElement = {}
local IndexStateElement_mt = Class(IndexStateElement, BoxLayoutElement)
Gui.registerGuiElement("IndexState", IndexStateElement)

-- Upvalues: IndexStateElement_mt
-- Local values: self
function IndexStateElement.new(target, custom_mt)
	-- upvalues: (copy) IndexStateElement_mt
	if custom_mt == nil then
		custom_mt = IndexStateElement_mt
	end
	local v4_ = BoxLayoutElement.new(target, custom_mt)
	v4_.pageElements = {}
	v4_.currentPageIndex = 1
	v4_.indexableElementId = nil
	v4_.indexableElement = nil
	v4_.stateElementTemplateId = nil
	v4_.stateElementTemplate = nil
	v4_.reverseElements = false
	v4_.indexMinimizeWidth = false
	return v4_
end

function IndexStateElement:delete()
	if self.stateElementTemplate ~= nil then
		self.stateElementTemplate:delete()
	end
	IndexStateElement:superClass().delete(self)
end

function IndexStateElement:loadFromXML(xmlFile, key)
	IndexStateElement:superClass().loadFromXML(self, xmlFile, key)
	self.stateElementTemplateId = getXMLString(xmlFile, key .. "#stateElementTemplateId")
	self.indexableElementId = getXMLString(xmlFile, key .. "#indexableElementId")
	self.reverseElements = Utils.getNoNil(getXMLBool(xmlFile, key .. "#reverseElements"), self.reverseElements)
	self.indexMinimizeWidth = Utils.getNoNil(getXMLBool(xmlFile, key .. "#indexMinimizeWidth"), self.indexMinimizeWidth)
end

function IndexStateElement:loadProfile(profile, applyProfile)
	IndexStateElement:superClass().loadProfile(self, profile, applyProfile)
	self.reverseElements = profile:getBool("reverseElements", self.reverseElements)
	self.indexMinimizeWidth = profile:getBool("indexMinimizeWidth", self.indexMinimizeWidth)
end

function IndexStateElement:copyAttributes(src)
	IndexStateElement:superClass().copyAttributes(self, src)
	self.stateElementTemplate = src.stateElementTemplate:clone()
	self.indexableElement = src.indexableElement
	self.indexableElementId = src.indexableElementId
	self.reverseElements = src.reverseElements
	self.indexMinimizeWidth = src.indexMinimizeWidth
	self:locateIndexableElement()
end

function IndexStateElement:onGuiSetupFinished()
	IndexStateElement:superClass().onGuiSetupFinished(self)
	if not self.stateElementTemplate then
		self:locateStateElementTemplate()
	end
	if not self.indexableElement and self.indexableElementId ~= nil then
		self:locateIndexableElement()
	end
end

function IndexStateElement:locateStateElementTemplate()
	self.stateElementTemplate = self.parent:getDescendantById(self.stateElementTemplateId)
	if self.stateElementTemplate then
		self.stateElementTemplate:setVisible(false)
		self.stateElementTemplate:setHandleFocus(false)
		self.stateElementTemplate:unlinkElement()
	else
		local v16_ = printWarning
		local v17_ = tostring(self)
		local v18_ = self.stateElementTemplateId
		v16_("Warning: IndexStateElement " .. v17_ .. " could not find state element template with ID [" .. tostring(v18_) .. "]. Check configuration.")
	end
end

-- Local values: root, levels
function IndexStateElement:locateIndexableElement()
	if self.indexableElementId then
		local v20_ = self.parent
		local v21_ = 20
		while v20_.parent and v21_ > 0 do
			v20_ = v20_.parent
			v21_ = v21_ - 1
		end
		self.indexableElement = v20_:getDescendantById(self.indexableElementId)
		if self.indexableElement then
			if self.indexableElement:hasIncluded(IndexChangeSubjectMixin) then
				self.indexableElement:addIndexChangeObserver(self, self.onIndexChange)
			else
				local v22_ = printWarning
				local v23_ = self.indexableElement
				v22_("Warning: Element " .. tostring(v23_) .. " does not support index change observers and is not valid to be targeted by IndexStateElement " .. tostring(self) .. ". Check configuration.")
			end
		end
		local v24_ = printWarning
		local v25_ = tostring(self)
		local v26_ = self.indexableElementId
		v24_("Warning: IndexStateElement " .. v25_ .. " could not find valid indexable element with ID [" .. tostring(v26_) .. "]. Check configuration.")
	end
end

function IndexStateElement:onIndexChange(index, count)
	if count ~= #self.pageElements then
		self:setPageCount(count, index)
	end
	self:setPageIndex(index)
end

-- Local values: _, element, _, stateElement
function IndexStateElement:setPageCount(count, initialIndex)
	if not self.stateElementTemplate then
		self:locateStateElementTemplate()
	end
	if count ~= #self.pageElements then
		for _, v33_ in pairs(self.pageElements) do
			self:removeElement(v33_)
			v33_:delete()
		end
		self.pageElements = {}
		for _ = 1, count do
			local v34_ = self.stateElementTemplate:clone(self)
			v34_:setVisible(true)
			local v35_ = self.pageElements
			table.insert(v35_, v34_)
		end
		self:invalidateLayout()
		if initialIndex then
			self:setPageIndex(initialIndex)
		end
		self:updateSize()
	end
end

function IndexStateElement:updateSize()
	if self.indexMinimizeWidth then
		self:updateLayoutCells()
		self:setSize(self.flowSize, nil)
		if self.parent ~= nil and self.parent.invalidateLayout ~= nil then
			self.parent:invalidateLayout()
		end
	end
end

-- Local values: i, element
function IndexStateElement:setPageIndex(index)
	if self.reverseElements then
		index = #self.pageElements - index + 1
	end
	local v39_ = #self.pageElements
	self.currentPageIndex = math.clamp(index, 1, v39_)
	for v40_, v41_ in ipairs(self.pageElements) do
		v41_:setSelected(v40_ == self.currentPageIndex)
	end
end
