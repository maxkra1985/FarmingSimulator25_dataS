-- Local values: SmoothListElement_mt
SmoothListElement = {}
local SmoothListElement_mt = Class(SmoothListElement, GuiElement)
Gui.registerGuiElement("SmoothList", SmoothListElement)
Gui.registerGuiElementProcFunction("SmoothList", Gui.assignPlaySampleCallback)
SmoothListElement.CHECK_OFFSET_EPSILON = 0.0002
SmoothListElement.GAMEPAD_PAGE_START_END_TIME = 1000
SmoothListElement.ALIGN_START = 0
SmoothListElement.ALIGN_MIDDLE = 0.5
SmoothListElement.ALIGN_END = 1

-- Upvalues: SmoothListElement_mt
-- Local values: self
function SmoothListElement.new(target, custom_mt)
	-- upvalues: (copy) SmoothListElement_mt
	local v4_ = SmoothListElement:superClass().new(target, custom_mt or SmoothListElement_mt)
	v4_:include(IndexChangeSubjectMixin)
	v4_:include(PlaySampleMixin)
	v4_.dataSource = nil
	v4_.delegate = nil
	v4_.cellCache = {}
	v4_.sections = {}
	v4_.clipping = true
	v4_.isLoaded = false
	v4_.updateChildrenState = false
	v4_.sectionHeaderCellName = nil
	v4_.isHorizontalList = false
	v4_.useLateralFilling = false
	v4_.numLateralItems = 1
	v4_.listSectionSpacing = 0
	v4_.listItemSpacing = 0
	v4_.listItemLateralSpacing = 0
	v4_.listItemAlignment = SmoothListElement.ALIGN_START
	v4_.listItemAlignmentOffset = 0
	v4_.lengthAxis = 2
	v4_.widthAxis = 1
	v4_.viewOffset = 0
	v4_.targetViewOffset = 0
	v4_.contentSize = 0
	v4_.totalItemCount = 0
	v4_.scrollViewOffsetDelta = 0
	v4_.selectedIndex = 1
	v4_.selectedSectionIndex = 1
	v4_.supportsMouseScrolling = true
	v4_.doubleClickInterval = 400
	v4_.selectOnClick = false
	v4_.ignoreMouse = false
	v4_.showHighlights = false
	v4_.selectOnScroll = false
	v4_.itemizedScrollDelta = 0
	v4_.listSmoothingDisabled = false
	v4_.listSnappingEnabled = false
	v4_.selectedWithoutFocus = true
	v4_.selectionMarginItems = 0
	v4_.ignoreFocusActivate = false
	v4_.fillRowsWithEmptyItems = true
	v4_.canReceiveFocusWhileEmpty = false
	v4_.wrapAround = false
	v4_.lastTouchPosX = nil
	v4_.lastTouchPosY = nil
	v4_.usedTouchId = nil
	v4_.currentTouchDelta = 0
	v4_.scrollSpeed = 0
	v4_.initialScrollSpeed = 0
	if v4_.isHorizontalList then
		v4_.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeX
	else
		v4_.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeY
	end
	v4_.supportsTouchScrolling = Platform.hasTouchInput
	v4_.lastScrollDirection = 0
	v4_.emptyIndicatorElement = nil
	v4_.emptyIndicatorElementId = nil
	v4_.totalTouchMoveDistance = 0
	v4_.touchMoveDistanceThreshold = 30
	v4_.gamepadPageStartTime = nil
	v4_.gamepadPageStartTriggered = false
	v4_.gamepadPageEndTime = nil
	v4_.gamepadPageEndTriggered = false
	return v4_
end

-- Local values: alignment, delegateName, dataSourceName
function SmoothListElement:loadFromXML(xmlFile, key)
	SmoothListElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onScroll", "onScrollCallback")
	self:addCallback(xmlFile, key .. "#onDoubleClick", "onDoubleClickCallback")
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
	self:addCallback(xmlFile, key .. "#onPressed", "onPressedCallback")
	self.isHorizontalList = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHorizontalList"), self.isHorizontalList)
	self.lengthAxis = self.isHorizontalList and 1 or 2
	self.widthAxis = self.isHorizontalList and 2 or 1
	self.numLateralItems = getXMLInt(xmlFile, key .. "#numLateralItems") or self.numLateralItems
	self.listSectionSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#listSectionSpacing"), self.isHorizontalList, self.listSectionSpacing)
	self.listItemSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#listItemSpacing"), self.isHorizontalList, self.listItemSpacing)
	self.listItemLateralSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#listItemLateralSpacing"), not self.isHorizontalList, self.listItemLateralSpacing)
	self.useLateralFilling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useLateralFilling"), self.useLateralFilling)
	local v8_ = getXMLString(xmlFile, key .. "#listItemAlignment")
	if v8_ ~= nil then
		local v9_ = string.lower(v8_)
		if v9_ == "end" then
			self.listItemAlignment = SmoothListElement.ALIGN_END
		elseif v9_ == "middle" then
			self.listItemAlignment = SmoothListElement.ALIGN_MIDDLE
		else
			self.listItemAlignment = SmoothListElement.ALIGN_START
		end
	end
	self.supportsMouseScrolling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsMouseScrolling"), self.supportsMouseScrolling)
	self.supportsTouchScrolling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsTouchScrolling"), self.supportsTouchScrolling)
	self.doubleClickInterval = getXMLInt(xmlFile, key .. "#doubleClickInterval") or self.doubleClickInterval
	self.selectOnClick = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectOnClick"), self.selectOnClick)
	self.ignoreMouse = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreMouse"), self.ignoreMouse)
	self.showHighlights = Utils.getNoNil(getXMLBool(xmlFile, key .. "#showHighlights"), self.showHighlights)
	self.selectOnScroll = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectOnScroll"), self.selectOnScroll)
	self.itemizedScrollDelta = getXMLInt(xmlFile, key .. "#itemizedScrollDelta") or self.itemizedScrollDelta
	self.listSmoothingDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#listSmoothingDisabled"), self.listSmoothingDisabled)
	self.selectedWithoutFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectedWithoutFocus"), self.selectedWithoutFocus)
	self.selectionMarginItems = getXMLInt(xmlFile, key .. "#selectionMarginItems") or self.selectionMarginItems
	self.listSnappingEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#listSnappingEnabled"), self.listSnappingEnabled)
	self.ignoreFocusActivate = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreFocusActivate"), self.ignoreFocusActivate)
	self.fillRowsWithEmptyItems = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fillRowsWithEmptyItems"), self.fillRowsWithEmptyItems)
	self.canReceiveFocusWhileEmpty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canReceiveFocusWhileEmpty"), self.canReceiveFocusWhileEmpty)
	self.wrapAround = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrapAround"), self.wrapAround)
	self.emptyIndicatorElementId = getXMLString(xmlFile, key .. "#emptyIndicatorId") or self.emptyIndicatorElementId
	local v10_ = getXMLString(xmlFile, key .. "#listDelegate")
	if v10_ == nil or v10_ == "self" then
		self.delegate = self.target
	elseif v10_ ~= "nil" then
		self.delegate = self.target[v10_]
	end
	local v11_ = getXMLString(xmlFile, key .. "#listDataSource")
	if v11_ == nil or v11_ == "self" then
		self.dataSource = self.target
	elseif v10_ ~= "nil" then
		self.dataSource = self.target[v11_]
	end
	self.sectionHeaderCellName = getXMLString(xmlFile, key .. "#listSectionHeader")
	self.startClipperElementName = getXMLString(xmlFile, key .. "#startClipperElementName")
	self.endClipperElementName = getXMLString(xmlFile, key .. "#endClipperElementName")
end

-- Local values: alignment
function SmoothListElement:loadProfile(profile, applyProfile)
	SmoothListElement:superClass().loadProfile(self, profile, applyProfile)
	self.isHorizontalList = profile:getBool("isHorizontalList", self.isHorizontalList)
	self.lengthAxis = self.isHorizontalList and 1 or 2
	self.widthAxis = self.isHorizontalList and 2 or 1
	self.numLateralItems = profile:getNumber("numLateralItems", self.numLateralItems)
	self.listSectionSpacing = GuiUtils.getNormalizedValue(profile:getValue("listSectionSpacing"), self.isHorizontalList, self.listSectionSpacing)
	self.listItemSpacing = GuiUtils.getNormalizedValue(profile:getValue("listItemSpacing"), self.isHorizontalList, self.listItemSpacing)
	self.listItemLateralSpacing = GuiUtils.getNormalizedValue(profile:getValue("listItemLateralSpacing"), not self.isHorizontalList, self.listItemLateralSpacing)
	self.useLateralFilling = profile:getBool("useLateralFilling", self.useLateralFilling)
	local v15_ = profile:getValue("listItemAlignment")
	if v15_ ~= nil then
		local v16_ = string.lower(v15_)
		if v16_ == "end" then
			self.listItemAlignment = SmoothListElement.ALIGN_END
		elseif v16_ == "middle" then
			self.listItemAlignment = SmoothListElement.ALIGN_MIDDLE
		else
			self.listItemAlignment = SmoothListElement.ALIGN_START
		end
	end
	self.supportsMouseScrolling = profile:getBool("supportsMouseScrolling", self.supportsMouseScrolling)
	self.doubleClickInterval = profile:getNumber("doubleClickInterval", self.doubleClickInterval)
	self.selectOnClick = profile:getBool("selectOnClick", self.selectOnClick)
	self.ignoreMouse = profile:getBool("ignoreMouse", self.ignoreMouse)
	self.showHighlights = profile:getBool("showHighlights", self.showHighlights)
	self.selectOnScroll = profile:getBool("selectOnScroll", self.selectOnScroll)
	self.itemizedScrollDelta = profile:getNumber("itemizedScrollDelta", self.itemizedScrollDelta)
	self.listSmoothingDisabled = profile:getBool("listSmoothingDisabled", self.listSmoothingDisabled)
	self.selectedWithoutFocus = profile:getBool("selectedWithoutFocus", self.selectedWithoutFocus)
	self.selectionMarginItems = profile:getNumber("selectionMarginItems", self.selectionMarginItems)
	self.supportsTouchScrolling = profile:getBool("supportsTouchScrolling", self.supportsTouchScrolling)
	self.listSnappingEnabled = profile:getBool("listSnappingEnabled", self.listSnappingEnabled)
	self.emptyIndicatorElementId = profile:getValue("emptyIndicatorId", self.emptyIndicatorElementId)
	self.fillRowsWithEmptyItems = profile:getBool("fillRowsWithEmptyItems", self.fillRowsWithEmptyItems)
	self.canReceiveFocusWhileEmpty = profile:getBool("canReceiveFocusWhileEmpty", self.canReceiveFocusWhileEmpty)
	self.wrapAround = profile:getBool("wrapAround", self.wrapAround)
end

-- Local values: cloned, name, cell, name, _
function SmoothListElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	local v22_ = SmoothListElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	v22_.cellDatabase = {}
	for v23_, v24_ in pairs(self.cellDatabase) do
		v22_.cellDatabase[v23_] = v24_:clone(nil, nil, true)
	end
	for v25_, _ in pairs(self.cellCache) do
		v22_.cellCache[v25_] = {}
	end
	return v22_
end

function SmoothListElement:copyAttributes(src)
	SmoothListElement:superClass().copyAttributes(self, src)
	self.dataSource = src.dataSource
	self.delegate = src.delegate
	self.singularCellName = src.singularCellName
	self.sectionHeaderCellName = src.sectionHeaderCellName
	self.startClipperElementName = src.startClipperElementName
	self.endClipperElementName = src.endClipperElementName
	self.emptyIndicatorElementId = src.emptyIndicatorElementId
	self.isHorizontalList = src.isHorizontalList
	self.numLateralItems = src.numLateralItems
	self.listSectionSpacing = src.listSectionSpacing
	self.listItemSpacing = src.listItemSpacing
	self.listItemLateralSpacing = src.listItemLateralSpacing
	self.listItemAlignment = src.listItemAlignment
	self.useLateralFilling = src.useLateralFilling
	self.supportsMouseScrolling = src.supportsMouseScrolling
	self.doubleClickInterval = src.doubleClickInterval
	self.selectOnClick = src.selectOnClick
	self.ignoreMouse = src.ignoreMouse
	self.showHighlights = src.showHighlights
	self.itemizedScrollDelta = src.itemizedScrollDelta
	self.selectOnScroll = src.selectOnScroll
	self.listSmoothingDisabled = src.listSmoothingDisabled
	self.selectedWithoutFocus = src.selectedWithoutFocus
	self.selectionMarginItems = src.selectionMarginItems
	self.listSnappingEnabled = src.listSnappingEnabled
	self.fillRowsWithEmptyItems = src.fillRowsWithEmptyItems
	self.canReceiveFocusWhileEmpty = src.canReceiveFocusWhileEmpty
	self.wrapAround = src.wrapAround
	self.lengthAxis = src.lengthAxis
	self.widthAxis = src.widthAxis
	self.onScrollCallback = src.onScrollCallback
	self.onDoubleClickCallback = src.onDoubleClickCallback
	self.onClickCallback = src.onClickCallback
	self.onPressedCallback = src.onPressedCallback
	self.supportsTouchScrolling = src.supportsTouchScrolling
	self.isLoaded = src.isLoaded
	GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end

function SmoothListElement:onGuiSetupFinished()
	SmoothListElement:superClass().onGuiSetupFinished(self)
	if self.startClipperElementName ~= nil then
		self.startClipperElement = self.parent:getDescendantByName(self.startClipperElementName)
	end
	if self.endClipperElementName ~= nil then
		self.endClipperElement = self.parent:getDescendantByName(self.endClipperElementName)
	end
	if self.emptyIndicatorElementId ~= nil and self.target ~= nil then
		self.emptyIndicatorElement = self.target:getDescendantById(self.emptyIndicatorElementId)
		if self.emptyIndicatorElement ~= nil then
			self.emptyIndicatorElement:setVisible(true)
		end
	end
	if not self.isLoaded then
		self:buildCellDatabase()
		self.isLoaded = true
	end
end

-- Local values: numCellsInDatabase, i, element, name, name, cell
function SmoothListElement:buildCellDatabase()
	self.cellDatabase = {}
	local v30_ = 0
	for v31_ = #self.elements, 1, -1 do
		local v32_ = self.elements[v31_]
		local v33_ = v32_.name
		if v32_:isa(ListItemElement) then
			if v33_ == nil then
				v32_.name = "autoCell" .. v31_
				v33_ = v32_.name
			end
			self.cellDatabase[v33_] = v32_
			self.cellCache[v33_] = {}
			v30_ = v30_ + 1
		end
		v32_:unlinkElement()
		FocusManager:removeElement(v32_)
	end
	if self.sectionHeaderCellName ~= nil and self.cellDatabase[self.sectionHeaderCellName] == nil then
		Logging.warning("List section header with name \'%s\' does not exist on \'%s\'", self.sectionHeaderCellName, self.profile)
		self.sectionHeaderCellName = nil
	end
	if self.sectionHeaderCellName ~= nil then
		v30_ = v30_ - 1
	end
	if self.dataSource.getEmptyCellType ~= nil and self.cellDatabase[self.dataSource:getEmptyCellType(self)] ~= nil or self.cellDatabase.empty then
		v30_ = v30_ - 1
	end
	if v30_ == 1 then
		for v34_, _ in pairs(self.cellDatabase) do
			if v34_ ~= self.sectionHeaderCellName then
				self.singularCellName = v34_
				return
			end
		end
	end
end

-- Local values: _, cell, _, elements, i
function SmoothListElement:iterateOverDatabase(lambda)
	if self.cellDatabase ~= nil then
		for _, v37_ in pairs(self.cellDatabase) do
			lambda(v37_)
		end
	end
	if self.cellCache ~= nil then
		for _, v38_ in pairs(self.cellCache) do
			for v39_ = 1, #v38_ do
				lambda(v38_[v39_])
			end
		end
	end
end

-- Local values: name, elements, _, element, name, element
function SmoothListElement:delete()
	for _, v41_ in pairs(self.cellCache) do
		for _, v42_ in ipairs(v41_) do
			v42_:delete()
		end
	end
	for _, v43_ in pairs(self.cellDatabase) do
		v43_:delete()
	end
	SmoothListElement:superClass().delete(self)
end

function SmoothListElement:onOpen()
	if self.setNextOpenIndex ~= nil then
		self:setSoundSuppressed(true)
		self:setSelectedItem(self.setNextOpenSectionIndex, self.setNextOpenIndex, true, true)
		self.setNextOpenIndex = nil
		self.setNextOpenSectionIndex = nil
		self:setSoundSuppressed(false)
	end
end

function SmoothListElement:onClose()
	if self.isMovingToTarget then
		self:scrollTo(self.targetViewOffset)
	end
end

function SmoothListElement:setDataSource(dataSource)
	self.dataSource = dataSource
	if self.delegate == nil then
		self.delegate = dataSource
	end
end

function SmoothListElement:setDelegate(delegate)
	self.delegate = delegate
	if self.dataSource == nil then
		self.dataSource = delegate
	end
end

-- Local values: cell, cache
function SmoothListElement:dequeueReusableCell(name)
	if self.cellDatabase[name] == nil then
		return nil
	end
	local v52_ = self.cellCache[name]
	local v53_
	if #v52_ > 0 then
		v53_ = v52_[#v52_]
		v52_[#v52_] = nil
		self:addElement(v53_)
	else
		v53_ = self.cellDatabase[name]:clone(self)
		v53_.reusableName = name
	end
	FocusManager:loadElementFromCustomValues(v53_)
	return v53_
end

-- Local values: cache
function SmoothListElement:queueReusableCell(cell)
	if self.sections[cell.sectionIndex] ~= nil then
		self.sections[cell.sectionIndex].cells[cell.indexInSection] = nil
	end
	cell.sectionIndex = nil
	cell.indexInSection = nil
	local v56_ = self.cellCache[cell.reusableName]
	v56_[#v56_ + 1] = cell
	cell:unlinkElement()
	FocusManager:removeElement(cell)
end

function SmoothListElement:setTarget(target, originalTarget, callOnCreate)
	SmoothListElement:superClass().setTarget(self, target, originalTarget, callOnCreate)
	if self.delegate == originalTarget then
		self.delegate = target
	end
	if self.dataSource == originalTarget then
		self.dataSource = target
	end
	self:iterateOverDatabase(function(p61_)
		-- upvalues: (copy) target, (copy) originalTarget, (copy) callOnCreate
		p61_:setTarget(target, originalTarget, callOnCreate)
	end)
end

-- Local values: _, section, i, cell
function SmoothListElement:reloadData(forceCellTypeUpdate)
	if self.dataSource ~= nil then
		self:setSoundSuppressed(true)
		if forceCellTypeUpdate then
			for _, v64_ in pairs(self.sections) do
				for v65_ = #v64_.cells, 1, -1 do
					local v66_ = v64_.cells[v65_]
					if v66_ ~= nil then
						self:queueReusableCell(v66_)
					end
				end
			end
		end
		self:buildSectionInfo()
		self:updateView(nil, true)
		self:setSoundSuppressed(false)
	end
end

function SmoothListElement:reloadSection(section)
	self:reloadData()
end

-- Local values: total, numberOfSections, itemWidth, totalRows, currentLengthOffset, s, section, hasHeader, sectionOffset, lastRow, rowMaxLength, i, itemLength, row, column, needsAnotherRow, emptyCellName, emptyIndex, s, selectedSection, selectedIndex, sectionIndex, section, contentOffset, oldTotalItemCount
function SmoothListElement:buildSectionInfo()
	local v69_ = 0
	local v70_ = self.dataSource.getNumberOfSections == nil and 1 or self.dataSource:getNumberOfSections(self)
	local v71_ = self:getWidthOfItemFast(1, 1) + self.listItemLateralSpacing
	if self.useLateralFilling and v71_ > 0 then
		local v72_ = (self.absSize[self.widthAxis] + self.listItemLateralSpacing) / v71_
		local v73_ = math.floor(v72_)
		self.numLateralItems = math.max(v73_, 1)
	else
		v71_ = (self.absSize[self.widthAxis] - (self.numLateralItems - 1) * self.listItemLateralSpacing) / self.numLateralItems + self.listItemLateralSpacing
	end
	local v74_ = 0
	local v75_ = 0
	for v76_ = 1, v70_ do
		if self.sections[v76_] == nil then
			self.sections[v76_] = {
				["cells"] = {}
			}
		end
		local v77_ = self.sections[v76_]
		v77_.itemOffsets = {}
		v77_.itemLateralOffsets = {}
		local v78_ = self.sectionHeaderCellName ~= nil
		if self.dataSource.getTitleForSectionHeader ~= nil and self.dataSource:getTitleForSectionHeader(self, v76_) == nil then
			v78_ = false
		end
		local v79_ = v76_ > 1 and (self.listSectionSpacing or 0) or 0
		v77_.startOffset = v74_
		if v78_ then
			v77_.startOffset = v74_ + v79_
			v77_.itemOffsets[0] = v77_.startOffset
			v74_ = v74_ + self.cellDatabase[self.sectionHeaderCellName].size[self.lengthAxis] + self.listItemSpacing + v79_
		end
		v77_.numItems = self.dataSource:getNumberOfItemsInSection(self, v76_)
		local v80_ = 1
		local v81_ = 0
		for v82_ = 1, v77_.numItems do
			local v83_ = self:getLengthOfItemFast(v76_, v82_)
			local v84_ = (v82_ - 1) / self.numLateralItems
			local v85_ = math.floor(v84_) + 1
			local v86_ = (v82_ - 1) % self.numLateralItems + 1
			if v85_ < v77_.numItems / self.numLateralItems or v76_ < v70_ then
				v83_ = v83_ + self.listItemSpacing
			end
			if v85_ == v80_ then
				v81_ = math.max(v81_, v83_)
			else
				v74_ = v74_ + v81_
				v75_ = v75_ + 1
				v81_ = v83_
				v80_ = v85_
			end
			v77_.itemOffsets[v82_] = v74_
			v77_.itemLateralOffsets[v82_] = v71_ * (v86_ - 1)
			local v87_ = self.dataSource.getEmptyCellType == nil and "empty" or (self.dataSource:getEmptyCellType(self) or "empty")
			if self.numLateralItems > 1 and (v82_ == v77_.numItems and (self.fillRowsWithEmptyItems and self.cellDatabase[v87_] ~= nil)) then
				local v88_ = v82_ + 1
				while v88_ % self.numLateralItems ~= 1 do
					local v89_ = (v88_ - 1) % self.numLateralItems + 1
					v77_.itemOffsets[v88_] = v74_
					v77_.itemLateralOffsets[v88_] = v71_ * (v89_ - 1)
					v88_ = v88_ + 1
				end
			end
		end
		v74_ = v74_ + v81_
		v75_ = v75_ + 1
		v77_.endOffset = v74_
		v69_ = v69_ + v77_.numItems
		self.sections[v76_] = v77_
	end
	for v90_ = #self.sections, v70_ + 1, -1 do
		self.sections[v90_] = nil
	end
	local v91_ = self.selectedSectionIndex
	local v92_ = self.selectedIndex
	if #self.sections > 0 then
		local v93_ = #self.sections
		local v94_ = math.clamp(v91_, 1, v93_)
		if self.sections[v94_].numItems == 0 then
			for v95_, v96_ in ipairs(self.sections) do
				if v96_.numItems > 0 then
					local v97_ = v96_.numItems
					v92_ = math.clamp(v92_, 1, v97_)
					v94_ = v95_
					break
				end
			end
		else
			local v98_ = self.sections[v94_].numItems
			v92_ = math.clamp(v92_, 1, v98_)
		end
		if v92_ == 0 then
			self.selectedSectionIndex = 0
			self.selectedIndex = 0
		elseif self:getIsVisible() then
			self:setSelectedItem(v94_, v92_, true)
		else
			self.setNextOpenIndex = v92_
			self.setNextOpenSectionIndex = v94_
		end
	end
	if v75_ > 0 then
		if self.itemizedScrollDelta == nil or (self.itemizedScrollDelta <= 0 or (#self.sections ~= 1 or self.singularCellName == nil)) then
			local v99_ = v74_ / v75_ * 0.4
			local v100_ = self.absSize[self.lengthAxis] / 5
			self.scrollViewOffsetDelta = math.max(v99_, v100_)
		else
			self.scrollViewOffsetDelta = (v74_ + self.listItemSpacing) / v75_ * self.itemizedScrollDelta
		end
	else
		self.scrollViewOffsetDelta = 0
	end
	self.contentSize = v74_
	local v101_ = self.absSize[self.lengthAxis] - v74_
	if v101_ > 0 then
		self.listItemAlignmentOffset = v101_ * self.listItemAlignment
		if self.isHorizontalList then
			self.listItemAlignmentOffset = self.listItemAlignmentOffset * -1
		end
	end
	local v102_ = self.totalItemCount
	self.totalItemCount = v69_
	if self.emptyIndicatorElement == nil or (v102_ ~= 0 or self.totalItemCount <= 0) then
		if self.emptyIndicatorElement ~= nil and (self.totalItemCount == 0 and v102_ > 0) then
			self.emptyIndicatorElement:setVisible(true)
		end
	else
		self.emptyIndicatorElement:setVisible(false)
	end
	local v103_ = self.viewOffset
	local v104_ = self.contentSize - self.absSize[self.lengthAxis]
	local v105_ = math.min(v103_, v104_)
	self.viewOffset = math.max(v105_, 0)
	local v106_ = self.targetViewOffset
	local v107_ = self.contentSize - self.absSize[self.lengthAxis]
	local v108_ = math.min(v106_, v107_)
	self.targetViewOffset = math.max(v108_, 0)
	self:updateScrollClippers()
end

-- Local values: cellName, cell
function SmoothListElement:getLengthOfItemFast(section, index)
	local v112_ = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, section, index)
	return self.cellDatabase[v112_].size[self.lengthAxis]
end

-- Local values: cellName, cell
function SmoothListElement:getWidthOfItemFast(section, index)
	local v116_ = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, section, index)
	return self.cellDatabase[v116_].size[self.widthAxis]
end

-- Local values: viewEndOffset, firstSection, firstIndex, s, section, i, offset, itemLength, endOffset, lastSection, lastIndex, s, section, i, offset, e, element, s, i, currentOffset, section, element, titleAttribute, cellName, element, titleAttribute, emptyCellName, emptyIndex, emptyCell, _, cell
function SmoothListElement:updateView(updateSlider, repopulate)
	local v120_ = self.viewOffset + self.absSize[self.lengthAxis]
	local v121_ = 0
	local v122_ = 0
	for v123_ = 1, #self.sections do
		local v124_ = self.sections[v123_]
		if self.viewOffset < v124_.endOffset then
			v122_ = v123_
			for v125_ = 0, v124_.numItems do
				local v126_ = v124_.itemOffsets[v125_]
				local v127_ = self:getLengthOfItemFast(v123_, v125_) or 0
				if v126_ ~= nil then
					v127_ = v126_ + v127_ or v127_
				end
				if v126_ ~= nil and (v127_ ~= nil and self.viewOffset + SmoothListElement.CHECK_OFFSET_EPSILON < v127_) then
					v121_ = v125_
					break
				end
			end
			if v121_ == nil then
				v121_ = v124_.numItems
			end
		end
	end
	local v128_ = 1
	local v129_ = 0
	for v130_ = #self.sections, math.max(v122_, 1), -1 do
		local v131_ = self.sections[v130_]
		if v131_.startOffset < v120_ then
			for v132_ = v131_.numItems - 1, 0, -1 do
				local v133_ = v131_.itemOffsets[v132_ + 1]
				if v133_ ~= nil and v133_ < v120_ then
					v128_ = v132_ + 1
					break
				end
			end
			if v128_ == nil then
				v128_ = v131_.numItems
				v129_ = v130_
			else
				v129_ = v130_
			end
		end
	end
	for v134_ = #self.elements, 1, -1 do
		local v135_ = self.elements[v134_]
		if v135_.sectionIndex < v122_ or (v129_ < v135_.sectionIndex or v135_.sectionIndex == v122_ and v135_.indexInSection < v121_) or (not v135_.isEmptyCell and (v135_.sectionIndex == v129_ and v128_ < v135_.indexInSection) or (not v135_.isEmptyCell and self.sections[v135_.sectionIndex].numItems < v135_.indexInSection or v135_.isEmptyCell)) then
			self:queueReusableCell(v135_)
		end
	end
	if v122_ == 0 or v129_ == 0 then
		if updateSlider ~= false then
			self:raiseSliderUpdateEvent()
		end
		return
	end
	local v136_ = self.sections[v122_].itemOffsets[v121_]
	while v136_ - self.viewOffset < self.absSize[self.lengthAxis] do
		local v137_ = self.sections[v122_]
		if v121_ < v137_.numItems and (v137_.cells[v121_] ~= nil and v137_.cells[v121_].isEmptyCell) then
			self:queueReusableCell(v137_.cells[v121_])
			v137_.cells[v121_] = nil
		end
		if v137_.cells[v121_] == nil then
			local v138_ = nil
			if v121_ == 0 then
				if self.sectionHeaderCellName ~= nil then
					v138_ = self:dequeueReusableCell(self.sectionHeaderCellName)
					v138_.isHeader = true
					local v139_ = v138_:getAttribute("title")
					if v139_ == nil or self.dataSource.getTitleForSectionHeader == nil then
						if self.dataSource.populateSectionHeader ~= nil then
							self.dataSource:populateSectionHeader(self, v122_, v138_)
						end
					else
						v139_:setText(self.dataSource:getTitleForSectionHeader(self, v122_))
					end
				end
			else
				v138_ = self:dequeueReusableCell(self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, v122_, v121_))
				self.dataSource:populateCellForItemInSection(self, v122_, v121_, v138_)
				v138_:setAlternating(v121_ % 2 == 0)
			end
			v138_.sectionIndex = v122_
			v138_.indexInSection = v121_
			v137_.cells[v121_] = v138_
			local v140_
			if v122_ == self.selectedSectionIndex and v121_ == self.selectedIndex then
				v140_ = self.selectedWithoutFocus or FocusManager:getFocusedElement() == self
			else
				v140_ = false
			end
			v138_:setSelected(v140_)
		elseif repopulate then
			local v141_ = v137_.cells[v121_]
			if v121_ == 0 then
				local v142_ = v141_:getAttribute("title")
				if v142_ == nil or self.dataSource.getTitleForSectionHeader == nil then
					if self.dataSource.populateSectionHeader ~= nil then
						self.dataSource:populateSectionHeader(self, v122_, v141_)
					end
				else
					v142_:setText(self.dataSource:getTitleForSectionHeader(self, v122_))
				end
			elseif v121_ <= v137_.numItems then
				self.dataSource:populateCellForItemInSection(self, v122_, v121_, v141_)
				v141_:setAlternating(v121_ % 2 == 0)
				local v143_
				if v122_ == self.selectedSectionIndex and v121_ == self.selectedIndex then
					v143_ = self.selectedWithoutFocus or FocusManager:getFocusedElement() == self
				else
					v143_ = false
				end
				v141_:setSelected(v143_)
			end
		end
		v121_ = v121_ + 1
		local v144_ = self.dataSource.getEmptyCellType == nil and "empty" or (self.dataSource:getEmptyCellType(self) or "empty")
		if self.fillRowsWithEmptyItems and (self.cellDatabase[v144_] ~= nil and (v137_.numItems < v121_ and self.numLateralItems > 1)) then
			local v145_ = v121_
			while v121_ % self.numLateralItems ~= 1 do
				local v146_ = self:dequeueReusableCell(v144_)
				v146_.sectionIndex = v122_
				v146_.indexInSection = v121_
				v146_.isEmptyCell = true
				v146_.playHoverSoundOnFocus = false
				v137_.cells[v121_] = v146_
				v121_ = v121_ + 1
			end
			v121_ = v145_
		end
		if v122_ == v129_ and v128_ < v121_ then
			break
		end
		if v137_.numItems < v121_ then
			local v147_ = 0
			v122_ = v122_ + 1
			if v129_ < v122_ then
				break
			end
			v121_ = self.sections[v122_].itemOffsets[v147_] == nil and 1 or v147_
			v136_ = self.sections[v122_].startOffset
		else
			v136_ = v137_.itemOffsets[v121_]
		end
	end
	self.numVisibleItems = #self.elements
	for _, v148_ in pairs(self.elements) do
		self:updateCellPosition(v148_)
	end
	if updateSlider ~= false then
		self:raiseSliderUpdateEvent()
	end
	self:updateScrollClippers()
end

-- Local values: section, offset, lateralOffset, x, y, x, y
function SmoothListElement:updateCellPosition(element)
	local v151_ = self.sections[element.sectionIndex]
	local v152_, v153_
	if element.indexInSection == 0 then
		v152_ = v151_.startOffset
		v153_ = 0
	else
		v152_ = v151_.itemOffsets[element.indexInSection]
		v153_ = v151_.itemLateralOffsets[element.indexInSection]
	end
	if self.lengthAxis == 1 then
		local v154_, v155_ = GuiUtils.alignToScreenPixels(v152_ - self.viewOffset - self.listItemAlignmentOffset, -v153_)
		element:setPosition(v154_, v155_)
	else
		local v156_, v157_ = GuiUtils.alignToScreenPixels(v153_, self.viewOffset - v152_ - self.listItemAlignmentOffset)
		element:setPosition(v156_, v157_)
	end
end

function SmoothListElement:scrollTo(offset, updateSlider)
	local v161_ = self.contentSize - self.absSize[self.lengthAxis]
	local v162_ = math.min(offset, v161_)
	local v163_ = math.max(v162_, 0)
	if v163_ ~= self.viewOffset then
		self.viewOffset = v163_
		self.targetViewOffset = v163_
		self.isMovingToTarget = false
		self:updateView(updateSlider)
	end
end

function SmoothListElement:scrollToStartGamepad()
	if self.gamepadPageStartTime == nil then
		self.gamepadPageStartTime = g_time + SmoothListElement.GAMEPAD_PAGE_START_END_TIME
	end
	self.gamepadPageStartTriggered = true
	if g_time >= self.gamepadPageStartTime then
		self:scrollToStart()
		self.gamepadPageStartTime = math.huge
	end
end

function SmoothListElement:scrollToEndGamepad()
	if self.gamepadPageEndTime == nil then
		self.gamepadPageEndTime = g_time + SmoothListElement.GAMEPAD_PAGE_START_END_TIME
	end
	self.gamepadPageEndTriggered = true
	if g_time >= self.gamepadPageEndTime then
		self:scrollToEnd()
		self.gamepadPageEndTime = math.huge
	end
end

function SmoothListElement:scrollToStart()
	if #self.sections == 1 or (Input.isKeyPressed(Input.KEY_lctrl) or g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_KEYBOARD) then
		self:setSelectedItem(1, 1)
	else
		self:setSelectedItem(self.selectedSectionIndex, 1)
	end
end

-- Local values: numSections, lastCellIndex
function SmoothListElement:scrollToEnd()
	local v168_ = #self.sections
	local v169_ = self.sections[v168_].numItems
	if v168_ == 1 or (Input.isKeyPressed(Input.KEY_lctrl) or g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_KEYBOARD) then
		self:setSelectedItem(v168_, v169_)
	else
		local v170_ = self.sections[self.selectedSectionIndex].numItems
		self:setSelectedItem(self.selectedSectionIndex, v170_)
	end
end

-- Local values: spacing, viewEndOffset, targetOffset, foundTargetOffset, sectionIndex, section, cellIndex, cellOffset, sectionIndex, section, cellIndex, cellOffset
function SmoothListElement:scrollToPrevPage()
	local v172_ = self.isHorizontalList and self.listItemLateralSpacing or self.listItemSpacing
	local v173_ = self.viewOffset - v172_
	if #self.sections ~= 1 and not Input.isKeyPressed(Input.KEY_lctrl) then
		self:setSelectedItem(self.selectedSectionIndex - 1, 1)
		return
	end
	local v174_ = false
	local v175_ = nil
	for v176_, v177_ in pairs(self.sections) do
		if v173_ < v177_.endOffset or MathUtil.equalEpsilon(v177_.endOffset, self.viewOffset, SmoothListElement.CHECK_OFFSET_EPSILON) then
			for v178_, v179_ in pairs(v177_.itemOffsets) do
				v175_ = v179_ + self:getLengthOfItemFast(v176_, v178_) + v172_
				if v173_ + SmoothListElement.CHECK_OFFSET_EPSILON < v175_ then
					local v180_ = v175_ - self.absSize[self.lengthAxis] - v172_
					local v181_ = self.contentSize - self.absSize[self.lengthAxis]
					local v182_ = math.min(v180_, v181_)
					v175_ = math.max(v182_, 0)
					v174_ = true
					break
				end
			end
			if v174_ then
				break
			end
		end
	end
	for v183_, v184_ in pairs(self.sections) do
		if v175_ < v184_.endOffset or MathUtil.equalEpsilon(v184_.endOffset, v175_, SmoothListElement.CHECK_OFFSET_EPSILON) then
			for v185_, v186_ in pairs(v184_.itemOffsets) do
				if v175_ < v186_ or MathUtil.equalEpsilon(v186_, v175_, SmoothListElement.CHECK_OFFSET_EPSILON) then
					self:setSelectedItem(v183_, v185_)
					return
				end
			end
		end
	end
end

-- Local values: targetOffset, spacing, viewEndOffset, sectionIndex, section, cellIndex, cellOffset, firstElementIndex
function SmoothListElement:scrollToNextPage()
	if #self.sections == 1 or Input.isKeyPressed(Input.KEY_lctrl) then
		local v188_ = self.isHorizontalList and self.listItemLateralSpacing or self.listItemSpacing
		local v189_ = self.viewOffset + self.absSize[self.lengthAxis] + v188_
		for v190_, v191_ in pairs(self.sections) do
			if v189_ < v191_.endOffset or MathUtil.equalEpsilon(v191_.endOffset, v189_, SmoothListElement.CHECK_OFFSET_EPSILON) then
				for v192_, v194_ in pairs(v191_.itemOffsets) do
					if v194_ + self:getLengthOfItemFast(v190_, v192_) + v188_ > v189_ + SmoothListElement.CHECK_OFFSET_EPSILON then
						if v192_ - self.numLateralItems <= 0 and v191_.itemOffsets[0] ~= nil then
							local v194_ = v191_.itemOffsets[0]
						end
						self:setSelectedItem(v190_, v192_)
						self:smoothScrollTo(v194_)
						return
					end
				end
			elseif v190_ == #self.sections then
				self:setSelectedItem(v190_, self.sections[v190_].numItems)
			end
		end
	else
		self:setSelectedItem(self.selectedSectionIndex + 1, 1)
		local v195_ = self.sections[self.selectedSectionIndex].itemOffsets[0] == nil and 1 or 0
		self:smoothScrollTo(self.sections[self.selectedSectionIndex].itemOffsets[v195_])
	end
end

function SmoothListElement:smoothScrollTo(offset)
	if self.listSmoothingDisabled then
		self:scrollTo(offset)
	end
	local v198_ = self.contentSize - self.absSize[self.lengthAxis]
	local v199_ = math.min(offset, v198_)
	self.targetViewOffset = math.max(v199_, 0)
	self.isMovingToTarget = true
end

function SmoothListElement:setSelectedIndex(index, forceChangeEvent, fast)
	self:setSelectedItem(1, index, forceChangeEvent, fast)
end

-- Local values: element, hasChanged
function SmoothListElement:setSelectedItem(section, index, forceChangeEvent, fast)
	if index == nil or section == nil then
		return
	elseif #self.sections < section or section < 1 then
		return
	elseif self.sections[section].numItems < index then
		return
	else
		local v209_ = self:getElementAtSectionIndex(section, index)
		if v209_ == nil or v209_.allowSelected ~= false then
			local v210_ = self.selectedIndex ~= index and true or self.selectedSectionIndex ~= section
			local v211_ = index - self.selectedIndex
			self.lastScrollDirection = math.sign(v211_)
			self.selectedSectionIndex = section
			self.selectedIndex = index
			if v210_ then
				self:makeCellVisible(self.selectedSectionIndex, self.selectedIndex, fast)
			end
			if not self.soundDisabled and (v210_ and (g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_TOUCH or not (self.inputDown or self.isMovingToTarget))) then
				self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
			end
			if (v210_ or forceChangeEvent) and self.isLoaded then
				self:notifyIndexChange(index, self.sections[1].numItems)
				if self.delegate.onListSelectionChanged ~= nil then
					self.delegate:onListSelectionChanged(self, section, index)
				end
			end
			self:applyElementSelection()
		end
	end
end

-- Local values: hasChanged, section, index
function SmoothListElement:setHighlightedItem(element)
	if self.showHighlights then
		if self.highlightedElement ~= element then
			if self.highlightedElement ~= nil then
				FocusManager:unsetHighlight(self.highlightedElement)
			end
			self.highlightedElement = element
			if element ~= nil then
				FocusManager:setHighlight(element)
			end
			if self.delegate.onListHighlightChanged ~= nil then
				local v214_, v215_
				if element == nil then
					v214_ = nil
					v215_ = nil
				else
					v214_ = element.sectionIndex
					v215_ = element.indexInSection
				end
				self.delegate:onListHighlightChanged(self, v214_, v215_)
			end
		end
	end
end

-- Local values: focusAllowed, _, element
function SmoothListElement:applyElementSelection()
	local v217_ = self.selectedWithoutFocus or FocusManager:getFocusedElement() == self
	for _, v218_ in pairs(self.elements) do
		local v219_
		if v217_ then
			if v218_.sectionIndex == self.selectedSectionIndex then
				v219_ = v218_.indexInSection == self.selectedIndex
			else
				v219_ = false
			end
		else
			v219_ = v217_
		end
		v218_:setSelected(v219_)
	end
end

-- Local values: i, element
function SmoothListElement:clearElementSelection()
	for v221_ = 1, #self.elements do
		local v222_ = self.elements[v221_]
		if v222_.setSelected ~= nil then
			v222_:setSelected(false)
		end
	end
end

-- Local values: sectionInfo, showSectionHeader, cellStartOffset, row, firstOfNextRow, cellEndOffset, newOffset, viewSize, marginItemSize
function SmoothListElement:makeCellVisible(section, index, fast)
	local v227_ = self.sections[section]
	if v227_ == nil then
		return
	else
		local v228_
		if index <= self.numLateralItems then
			v228_ = v227_.itemOffsets[0] ~= nil
		else
			v228_ = false
		end
		local v229_ = v227_.itemOffsets[index]
		if v229_ ~= nil then
			local v230_ = (index - 1) / self.numLateralItems
			local v231_ = (math.floor(v230_) + 1) * self.numLateralItems + 1
			local v232_ = v227_.itemOffsets[v231_]
			if v232_ == nil then
				v232_ = v227_.endOffset
			elseif section < #self.sections or index < v227_.numItems then
				v232_ = v232_ - self.listItemSpacing
			end
			local _ = self.viewOffset
			local v233_ = self.absSize[self.lengthAxis]
			local v234_ = self.selectionMarginItems * (v232_ - v229_)
			local v235_
			if v229_ - v234_ < self.viewOffset then
				if v228_ then
					v235_ = v227_.itemOffsets[0]
				else
					v235_ = v229_ - v234_
				end
			else
				if v232_ + v234_ <= self.viewOffset + v233_ then
					return
				end
				v235_ = v232_ - v233_ + v234_
			end
			if not self.isMovingToTarget or self.targetViewOffset ~= v235_ then
				if fast then
					self:scrollTo(v235_)
					return
				end
				self:smoothScrollTo(v235_)
			end
		end
	end
end

function SmoothListElement:makeSelectedCellVisible()
	self:makeCellVisible(self.selectedSectionIndex, self.selectedIndex)
end

-- Local values: visible, visible
function SmoothListElement:updateScrollClippers(initial)
	if self.startClipperElement ~= nil then
		local v238_ = self.visible
		if v238_ then
			if self.contentSize > 0 then
				v238_ = self.viewOffset > 0.01
			else
				v238_ = false
			end
		end
		self.startClipperElement:setVisible(v238_)
	end
	if self.endClipperElement ~= nil then
		local v239_ = self.visible
		if v239_ then
			if self.contentSize > 0 then
				v239_ = self.viewOffset - (self.contentSize - self.absSize[self.lengthAxis]) < -0.01
			else
				v239_ = false
			end
		end
		self.endClipperElement:setVisible(v239_)
	end
end

-- Local values: isTouchActionActive, scrollSpeedAbs, delta, dir, speedToBreakRatio
function SmoothListElement:update(dt)
	SmoothListElement:superClass().update(self, dt)
	if self.isMovingToTarget then
		if self:getIsVisible() then
			self.viewOffset = self.viewOffset + (self.targetViewOffset - self.viewOffset) * 0.01 * dt
		else
			self.viewOffset = self.targetViewOffset
		end
		local v242_ = self.targetViewOffset - self.viewOffset
		if math.abs(v242_) < 0.0005 then
			self.viewOffset = self.targetViewOffset
			self.isMovingToTarget = false
		end
		self:updateView(true)
	end
	if self.supportsTouchScrolling then
		local v243_ = self.usedTouchId ~= nil
		local v244_ = self.scrollSpeed
		local v245_ = math.abs(v244_)
		if v243_ or v245_ > 0.0001 then
			local v246_ = 0
			if v243_ then
				self.scrollSpeed = self.currentTouchDelta / dt
				v246_ = self.currentTouchDelta
				if self.isHorizontalList then
					v246_ = -v246_
				end
			elseif self.listSnappingEnabled then
				self.scrollSpeed = 0
			else
				local v247_ = self.scrollSpeed
				local v248_ = math.sign(v247_)
				if self.isHorizontalList then
					v248_ = -v248_
				end
				local v249_ = self.scrollSpeed / self.initialScrollSpeed
				local v250_ = v245_ - dt * self.scrollSpeedInterval
				self.scrollSpeed = math.max(v250_, 0) * v248_
				v246_ = self.scrollSpeed * v249_ ^ 3 * dt
			end
			if v246_ ~= 0 then
				self:scrollTo(self.viewOffset + v246_)
			end
			self.currentTouchDelta = 0
		end
	end
	if self.inputDown then
		self.inputDownTimer = self.inputDownTimer + dt
		self:raiseCallback("onPressedCallback", self, self.inputDownTimer)
	end
	if self.gamepadPageStartTime ~= nil and not self.gamepadPageStartTriggered then
		self.gamepadPageStartTime = nil
	end
	if self.gamepadPageEndTime ~= nil and not self.gamepadPageEndTriggered then
		self.gamepadPageEndTime = nil
	end
	self.gamepadPageStartTriggered = false
	self.gamepadPageEndTriggered = false
end

function SmoothListElement:getSelectedElement()
	return self:getElementAtSectionIndex(self.selectedSectionIndex, self.selectedIndex)
end

function SmoothListElement:getItemCount()
	return self.totalItemCount
end

function SmoothListElement:getSelectedIndexInSection()
	return self.selectedIndex
end

function SmoothListElement:getSelectedSection()
	return self.selectedSectionIndex
end

function SmoothListElement:getSelectedPath()
	return self.selectedSectionIndex, self.selectedIndex
end

function SmoothListElement:getElementAtSectionIndex(section, index)
	if self.sections[section] == nil then
		return nil
	else
		return self.sections[section].cells[index]
	end
end

function SmoothListElement:raiseSliderUpdateEvent()
	if self.sliderElement ~= nil then
		self.sliderElement:onBindUpdate(self)
	end
end

-- Local values: newOffset, sliderDiff
function SmoothListElement:onSliderValueChanged(slider, newValue, immediateMode)
	if self.sections == nil then
		return
	else
		local v264_ = slider.maxValue - slider.minValue
		local v265_ = v264_ == 0 and 0 or (self.contentSize - self.absSize[self.lengthAxis]) / v264_ * (newValue - slider.minValue)
		if immediateMode then
			self:scrollTo(v265_, false)
		else
			self:smoothScrollTo(v265_)
		end
	end
end

-- Local values: size
function SmoothListElement:getViewOffsetPercentage()
	local v267_ = self.contentSize - self.absSize[self.lengthAxis]
	return v267_ == 0 and 1 or self.viewOffset / v267_
end

-- Local values: previousSection, previousIndex, clickedSection, clickedIndex, notified, wasScrolling, wasAlreadySelected
function SmoothListElement:activateInput()
	if self.inputOverElement == nil then
		self.lastClickTime = nil
	else
		local v269_ = self.selectedSectionIndex
		local v270_ = self.selectedIndex
		local v271_, v272_
		if self.listSnappingEnabled then
			v271_ = self.inputOverElement.sectionIndex
			v272_ = MathUtil.round(v270_ + 0.3 * self.lastScrollDirection, 0)
		else
			v271_ = self.inputOverElement.sectionIndex
			v272_ = self.inputOverElement.indexInSection
		end
		local v273_ = false
		if self.lastClickTime == nil or self.lastClickTime <= self.target.time - self.doubleClickInterval then
			self.lastClickTime = self.target.time
		else
			if v271_ == v269_ and v272_ == v270_ then
				self:notifyDoubleClick(v271_, v272_, self.inputOverElement)
				self.usedTouchId = nil
				v273_ = true
			end
			self.lastClickTime = nil
		end
		local v274_ = self.totalTouchMoveDistance > self.touchMoveDistanceThreshold
		self.wasScrolling = v274_
		local v275_ = self.selectedIndex == v272_
		if not v274_ or self.selectOnScroll then
			self:setSelectedItem(v271_, v272_)
		end
		if not (self.selectOnClick or (v273_ or v274_)) then
			self:notifyClick(v271_, v272_, self.inputOverElement, v275_)
			return
		end
	end
end

function SmoothListElement:onInputDown()
	self.inputDown = true
	self.inputDownTimer = 0
	FocusManager:setFocus(self)
end

function SmoothListElement:onInputUp()
	self.inputDown = false
	self.totalTouchMoveDistance = 0
end

function SmoothListElement:resetInput()
	self.lastClickTime = nil
	self.inputDown = false
	self.lastClickTime = nil
end

function SmoothListElement:notifyDoubleClick(section, index, element)
	self:raiseCallback("onDoubleClickCallback", self, section, index, element, true)
end

function SmoothListElement:notifyClick(section, index, element, wasAlreadySelected)
	self:raiseCallback("onClickCallback", self, section, index, element, wasAlreadySelected)
end

-- Local values: inputOverElement, deltaIndex, newIndex
function SmoothListElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() and not self.ignoreMouse then
		eventUsed = SmoothListElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed
		if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
			if self.inputOverElement ~= nil then
				self.inputOverElement = nil
				self:setHighlightedItem(nil)
			end
		else
			local v295_ = self:getElementAtScreenPosition(posX, posY)
			if v295_ ~= nil and (v295_.indexInSection == 0 or v295_.isEmptyCell) then
				v295_ = nil
			end
			if self.inputOverElement ~= v295_ then
				self:setHighlightedItem(v295_)
				self.inputOverElement = v295_
			end
			if isDown then
				if button == Input.MOUSE_BUTTON_LEFT then
					self:onInputDown()
					self:activateInput()
					eventUsed = self.inputOverElement ~= nil
				end
				if self.supportsMouseScrolling then
					local v296_ = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) and -1 or (Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) and 1 or 0)
					if v296_ ~= 0 then
						if self.selectOnScroll then
							if #self.sections == 1 then
								local v297_ = self.sections[1].numItems
								local v298_ = self.selectedIndex + v296_
								local v299_ = math.min(v297_, v298_)
								self:setSelectedItem(1, (math.max(1, v299_)))
								eventUsed = true
							else
								eventUsed = true
							end
						else
							self:smoothScrollTo(self.targetViewOffset + v296_ * self.scrollViewOffsetDelta)
							eventUsed = true
						end
					end
				end
			end
			if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.inputDown) then
				self:onInputUp()
				return self.inputOverElement ~= nil
			end
		end
	end
	return eventUsed
end

-- Local values: inputOverElement, wasScrolling, delta, lastTouchPosX, lastTouchPosY, distancePixels
function SmoothListElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsActive() then
		eventUsed = SmoothListElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) and true or eventUsed
		if not eventUsed and (self.usedTouchId == touchId or GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot)) then
			local v307_ = self:getElementAtScreenPosition(posX, posY)
			if v307_ ~= nil and (v307_.indexInSection == 0 or v307_.isEmptyCell) then
				v307_ = nil
			end
			if self.inputOverElement ~= v307_ then
				self:setHighlightedItem(v307_)
				self.inputOverElement = v307_
			end
			local v308_ = self.totalTouchMoveDistance > self.touchMoveDistanceThreshold
			self.wasScrolling = v308_
			if self.supportsTouchScrolling then
				if self.usedTouchId == nil then
					if not eventUsed and isDown then
						self.currentTouchDelta = 0
						self.lastTouchPosX = posX
						self.lastTouchPosY = posY
						self.usedTouchId = touchId
						eventUsed = true
					end
				elseif self.usedTouchId == touchId then
					if isUp then
						self.usedTouchId = nil
						self.initialScrollSpeed = self.scrollSpeed
					else
						local v309_ = self.lastTouchPosX or posX
						local v310_ = self.lastTouchPosY or posY
						local v311_
						if self.isHorizontalList then
							v311_ = posX - v309_
						else
							v311_ = posY - v310_
						end
						self.currentTouchDelta = (self.currentTouchDelta or 0) + v311_
						local v312_ = MathUtil.vector2Length((v309_ - posX) * g_screenWidth, (v310_ - posY) * g_screenHeight)
						self.totalTouchMoveDistance = self.totalTouchMoveDistance + v312_
						self.lastTouchPosX = posX
						self.lastTouchPosY = posY
					end
				end
			end
			if isDown then
				self:onInputDown()
				eventUsed = true
			end
			if isUp and self.inputDown then
				if not v308_ then
					self:activateInput()
				end
				self:onInputUp()
				eventUsed = true
			end
		end
	end
	return eventUsed
end

-- Local values: i, v
function SmoothListElement:getElementAtScreenPosition(x, y)
	for v316_ = #self.elements, 1, -1 do
		local v317_ = self.elements[v316_]
		if GuiUtils.checkOverlayOverlap(x, y, v317_.absPosition[1], v317_.absPosition[2], v317_.absSize[1], v317_.absSize[2], v317_.hotspot) then
			return v317_, v317_.sectionIndex, v317_.indexInSection
		end
	end
	return nil
end

-- Local values: sectionIndex, section, index, row, column, targetSection, targetIndex, s, nRows, lastColumn, numRows, itemsInRow, numRows, lastColumnLength
function SmoothListElement:shouldFocusChange(direction)
	if self.totalItemCount == 0 then
		return true
	end
	local v320_ = self.selectedSectionIndex
	local v321_ = #self.sections
	local v322_ = math.clamp(v320_, 1, v321_)
	local v323_ = self.sections[v322_]
	local v324_ = self.selectedIndex
	local v325_ = (v324_ - 1) / self.numLateralItems
	local v326_ = math.floor(v325_) + 1
	local v327_ = (v324_ - 1) % self.numLateralItems + 1
	if self.isHorizontalList then
		if direction == FocusManager.TOP then
			direction = FocusManager.LEFT
		elseif direction == FocusManager.BOTTOM then
			direction = FocusManager.RIGHT
		elseif direction == FocusManager.LEFT then
			direction = FocusManager.TOP
		elseif direction == FocusManager.RIGHT then
			direction = FocusManager.BOTTOM
		end
	end
	local v328_, v329_
	if direction == FocusManager.TOP then
		v328_ = v324_ - self.numLateralItems
		if v328_ < 1 then
			if v322_ > 1 then
				local v330_ = v322_
				while true do
					v329_ = v322_ - 1
					if v329_ == 0 then
						return true
					end
					local v331_ = self.sections[v329_]
					local v332_ = (v331_.numItems - 1) / self.numLateralItems
					local v333_ = math.floor(v332_)
					local v334_ = v331_.numItems % self.numLateralItems
					if v334_ == 0 then
						local v335_ = v331_.numItems
						local v336_ = self.numLateralItems
						v334_ = math.min(v335_, v336_)
					end
					v328_ = v333_ * self.numLateralItems + math.min(v334_, v327_)
					if v328_ > 0 then
						break
					end
					v322_ = v329_
				end
				v322_ = v330_
			elseif self.wrapAround then
				v329_ = #self.sections
				v328_ = self.sections[v329_] == nil and 0 or (self.sections[v329_].numItems or 0)
			elseif v324_ == 1 and self.sections[v322_].itemOffsets[1] > 0 then
				v329_ = v322_
				v328_ = 0
			else
				v328_ = v324_
				v329_ = v322_
			end
		else
			v329_ = v322_
		end
	elseif direction == FocusManager.BOTTOM then
		v328_ = v324_ + self.numLateralItems
		if v323_.numItems < v328_ then
			local v337_ = (v323_.numItems - 1) / self.numLateralItems
			local v338_ = math.floor(v337_) + 1
			if v323_.numItems % self.numLateralItems == 0 or v326_ >= v338_ then
				if v322_ < #self.sections then
					local v339_ = v322_
					while true do
						v329_ = v322_ + 1
						if #self.sections < v329_ then
							return true
						end
						local v340_ = self.sections[v329_].numItems
						v328_ = math.min(v340_, v327_)
						if v328_ ~= 0 then
							break
						end
						v322_ = v329_
					end
					v322_ = v339_
				elseif self.wrapAround then
					local v341_ = #self.sections
					v329_ = math.min(v341_, 1)
					v328_ = self.sections[v329_] == nil and 0 or 1
				else
					v328_ = v324_
					v329_ = v322_
				end
			else
				v328_ = v323_.numItems
				v329_ = v322_
			end
		else
			v329_ = v322_
		end
	elseif direction == FocusManager.LEFT then
		if v327_ > 1 then
			v328_ = v324_ - 1
			v329_ = v322_
		else
			v328_ = v324_
			v329_ = v322_
		end
	elseif direction == FocusManager.RIGHT then
		local v342_ = self.numLateralItems
		local v343_ = v323_.numItems / self.numLateralItems
		local v344_ = math.floor(v343_)
		local v345_ = v323_.numItems % self.numLateralItems
		if v345_ > 0 then
			v344_ = v344_ + 1
		else
			v345_ = self.numLateralItems
		end
		if v326_ ~= v344_ then
			v345_ = v342_
		end
		if v327_ < v345_ then
			v328_ = v324_ + 1
			v329_ = v322_
		else
			v328_ = v324_
			v329_ = v322_
		end
	else
		v328_ = v324_
		v329_ = v322_
	end
	if v329_ == v322_ and v328_ == v324_ then
		return true
	elseif v328_ == 0 then
		self:makeCellVisible(v329_, 0)
		return true
	else
		self:setSelectedItem(v329_, v328_)
		return false
	end
end

function SmoothListElement:canReceiveFocus()
	local v347_ = self:getIsVisible() and self.handleFocus
	if v347_ then
		v347_ = self.disabled and true or false or self.canReceiveFocusWhileEmpty or self.totalItemCount > 0
	end
	return v347_
end

function SmoothListElement:onFocusActivate()
	if self.totalItemCount == 0 then
		return
	elseif self.ignoreFocusActivate then
		return
	elseif self.onClickCallback == nil then
		if self.onDoubleClickCallback ~= nil then
			self:notifyDoubleClick(self.selectedSectionIndex, self.selectedIndex, nil)
		end
	else
		self:notifyClick(self.selectedSectionIndex, self.selectedIndex, self:getElementAtSectionIndex(self.selectedSectionIndex, self.selectedIndex))
		return
	end
end

function SmoothListElement:onFocusEnter()
	self:applyElementSelection()
	if self.delegate.onListSelectionChanged ~= nil then
		self.delegate:onListSelectionChanged(self, self.selectedSectionIndex, self.selectedIndex)
	end
end

function SmoothListElement:onFocusLeave()
	if not self.selectedWithoutFocus then
		self:clearElementSelection()
	end
	SmoothListElement:superClass().onFocusLeave(self)
end
