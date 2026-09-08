-- Local values: BoxLayoutElement_mt
BoxLayoutElement = {}
local BoxLayoutElement_mt = Class(BoxLayoutElement, BitmapElement)
Gui.registerGuiElement("BoxLayout", BoxLayoutElement)
BoxLayoutElement.ALIGN_LEFT = 0
BoxLayoutElement.ALIGN_CENTER = 0.5
BoxLayoutElement.ALIGN_RIGHT = 1
BoxLayoutElement.ALIGN_TOP = 1
BoxLayoutElement.ALIGN_MIDDLE = 0.5
BoxLayoutElement.ALIGN_BOTTOM = 0
BoxLayoutElement.FLOW_VERTICAL = "vertical"
BoxLayoutElement.FLOW_HORIZONTAL = "horizontal"
BoxLayoutElement.FLOW_NONE = "none"
BoxLayoutElement.FILL_DIRECTION_LEFT_TO_RIGHT = 1
BoxLayoutElement.FILL_DIRECTION_RIGHT_TO_LEFT = -1
BoxLayoutElement.FILL_DIRECTION_BOTTOM_TO_TOP = 1
BoxLayoutElement.FILL_DIRECTION_TOP_TO_BOTTOM = -1
BoxLayoutElement.LAYOUT_TOLERANCE = 0.1
local v2_ = BoxLayoutElement
local v3_ = {
	[BoxLayoutElement.FLOW_VERTICAL] = {
		["FLOW_MARGIN_LOWER"] = GuiElement.MARGIN_LEFT,
		["FLOW_MARGIN_UPPER"] = GuiElement.MARGIN_RIGHT,
		["ELEMENT_SIZE"] = 2,
		["ELEMENT_MARGIN_LOWER"] = GuiElement.MARGIN_TOP,
		["ELEMENT_MARGIN_UPPER"] = GuiElement.MARGIN_BOTTOM,
		["LAYOUT_FLOW_SIZE"] = 2
	},
	[BoxLayoutElement.FLOW_HORIZONTAL] = {
		["FLOW_MARGIN_LOWER"] = GuiElement.MARGIN_TOP,
		["FLOW_MARGIN_UPPER"] = GuiElement.MARGIN_BOTTOM,
		["ELEMENT_SIZE"] = 1,
		["ELEMENT_MARGIN_LOWER"] = GuiElement.MARGIN_LEFT,
		["ELEMENT_MARGIN_UPPER"] = GuiElement.MARGIN_RIGHT,
		["LAYOUT_FLOW_SIZE"] = 1
	}
}
v2_.FLOW_INDICES = v3_
BoxLayoutElement.FLOW_LATERAL_TABLE = {
	[BoxLayoutElement.FLOW_VERTICAL] = BoxLayoutElement.FLOW_HORIZONTAL,
	[BoxLayoutElement.FLOW_HORIZONTAL] = BoxLayoutElement.FLOW_VERTICAL
}

-- Upvalues: BoxLayoutElement_mt
-- Local values: self
function BoxLayoutElement.new(target, custom_mt)
	-- upvalues: (copy) BoxLayoutElement_mt
	if custom_mt == nil then
		custom_mt = BoxLayoutElement_mt
	end
	local v6_ = BitmapElement.new(target, custom_mt)
	v6_.autoValidateLayout = false
	v6_.useFullVisibility = true
	v6_.wrapAround = false
	v6_.alignment = { BoxLayoutElement.ALIGN_LEFT, BoxLayoutElement.ALIGN_TOP }
	v6_.flowDirection = BoxLayoutElement.FLOW_HORIZONTAL
	v6_.fillDirections = { BoxLayoutElement.FILL_DIRECTION_LEFT_TO_RIGHT, BoxLayoutElement.FILL_DIRECTION_TOP_TO_BOTTOM }
	v6_.numFlows = 1
	v6_.lateralFlowSize = 0
	v6_.fitFlowToElements = true
	v6_.layoutToleranceX = 0
	v6_.layoutToleranceY = 0
	v6_.rememberLastFocus = false
	v6_.lastFocusElement = nil
	v6_.incomingFocusTargets = {}
	v6_.defaultFocusTarget = nil
	v6_.cells = {}
	v6_.flowSizes = {}
	v6_.lateralFlowSizes = {}
	v6_.totalLateralSize = 0
	v6_.maxFlowSize = 0
	v6_.elementSpacing = 0
	return v6_
end

-- Local values: alignmentX, alignmentY, fillDirectionX, fillDirectionY, isXValue
function BoxLayoutElement:loadFromXML(xmlFile, key)
	BoxLayoutElement:superClass().loadFromXML(self, xmlFile, key)
	local v10_ = getXMLString(xmlFile, key .. "#alignmentX")
	if v10_ ~= nil then
		local v11_ = string.lower(v10_)
		if v11_ == "right" then
			self.alignment[1] = BoxLayoutElement.ALIGN_RIGHT
		elseif v11_ == "center" then
			self.alignment[1] = BoxLayoutElement.ALIGN_CENTER
		else
			self.alignment[1] = BoxLayoutElement.ALIGN_LEFT
		end
	end
	local v12_ = getXMLString(xmlFile, key .. "#alignmentY")
	if v12_ ~= nil then
		local v13_ = string.lower(v12_)
		if v13_ == "bottom" then
			self.alignment[2] = BoxLayoutElement.ALIGN_BOTTOM
		elseif v13_ == "middle" then
			self.alignment[2] = BoxLayoutElement.ALIGN_MIDDLE
		else
			self.alignment[2] = BoxLayoutElement.ALIGN_TOP
		end
	end
	local v14_ = getXMLString(xmlFile, key .. "#fillDirectionX")
	if v14_ ~= nil then
		if v14_ == "leftToRight" then
			self.fillDirections[1] = BoxLayoutElement.FILL_DIRECTION_LEFT_TO_RIGHT
		elseif v14_ == "rightToLeft" then
			self.fillDirections[1] = BoxLayoutElement.FILL_DIRECTION_RIGHT_TO_LEFT
		end
	end
	local v15_ = getXMLString(xmlFile, key .. "#fillDirectionY")
	if v15_ ~= nil then
		if v15_ == "topToBottom" then
			self.fillDirections[2] = BoxLayoutElement.FILL_DIRECTION_TOP_TO_BOTTOM
		elseif v15_ == "bottomToTop" then
			self.fillDirections[2] = BoxLayoutElement.FILL_DIRECTION_BOTTOM_TO_TOP
		end
	end
	self.flowDirection = getXMLString(xmlFile, key .. "#flowDirection") or self.flowDirection
	self.focusDirection = getXMLString(xmlFile, key .. "#focusDirection") or self.flowDirection
	self.numFlows = getXMLInt(xmlFile, key .. "#numFlows") or self.numFlows
	local v16_ = self.flowDirection == BoxLayoutElement.FLOW_HORIZONTAL
	self.elementSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#elementSpacing"), v16_) or self.elementSpacing
	self.lateralFlowSize = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#lateralFlowSize"), not v16_) or self.lateralFlowSize
	self.fitFlowToElements = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fitFlowToElements"), self.lateralFlowSize == 0)
	self.autoValidateLayout = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoValidateLayout"), self.autoValidateLayout)
	self.useFullVisibility = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useFullVisibility"), self.useFullVisibility)
	self.wrapAround = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrapAround"), self.wrapAround)
	self.rememberLastFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rememberLastFocus"), self.rememberLastFocus)
end

-- Local values: alignmentX, alignmentY, fillDirectionX, fillDirectionY, isXValue
function BoxLayoutElement:loadProfile(profile, applyProfile)
	BoxLayoutElement:superClass().loadProfile(self, profile, applyProfile)
	local v20_ = profile:getValue("alignmentX")
	if v20_ ~= nil then
		local v21_ = string.lower(v20_)
		if v21_ == "right" then
			self.alignment[1] = BoxLayoutElement.ALIGN_RIGHT
		elseif v21_ == "center" then
			self.alignment[1] = BoxLayoutElement.ALIGN_CENTER
		else
			self.alignment[1] = BoxLayoutElement.ALIGN_LEFT
		end
	end
	local v22_ = profile:getValue("alignmentY")
	if v22_ ~= nil then
		local v23_ = string.lower(v22_)
		if v23_ == "bottom" then
			self.alignment[2] = BoxLayoutElement.ALIGN_BOTTOM
		elseif v23_ == "middle" then
			self.alignment[2] = BoxLayoutElement.ALIGN_MIDDLE
		else
			self.alignment[2] = BoxLayoutElement.ALIGN_TOP
		end
	end
	local v24_ = profile:getValue("fillDirectionX")
	if v24_ ~= nil then
		if v24_ == "leftToRight" then
			self.fillDirections[1] = BoxLayoutElement.FILL_DIRECTION_LEFT_TO_RIGHT
		elseif v24_ == "rightToLeft" then
			self.fillDirections[1] = BoxLayoutElement.FILL_DIRECTION_RIGHT_TO_LEFT
		end
	end
	local v25_ = profile:getValue("fillDirectionY")
	if v25_ ~= nil then
		if v25_ == "topToBottom" then
			self.fillDirections[2] = BoxLayoutElement.FILL_DIRECTION_TOP_TO_BOTTOM
		elseif v25_ == "bottomToTop" then
			self.fillDirections[2] = BoxLayoutElement.FILL_DIRECTION_BOTTOM_TO_TOP
		end
	end
	self.autoValidateLayout = profile:getBool("autoValidateLayout", self.autoValidateLayout)
	self.useFullVisibility = profile:getBool("useFullVisibility", self.useFullVisibility)
	self.flowDirection = profile:getValue("flowDirection") or self.flowDirection
	self.focusDirection = profile:getValue("focusDirection", self.flowDirection)
	self.numFlows = profile:getNumber("numFlows", self.numFlows)
	local v26_ = self.flowDirection == BoxLayoutElement.FLOW_HORIZONTAL
	self.elementSpacing = GuiUtils.getNormalizedValue(profile:getValue("elementSpacing", self.elementSpacing), v26_)
	self.lateralFlowSize = GuiUtils.getNormalizedValue(profile:getValue("lateralFlowSize", self.lateralFlowSize), not v26_)
	self.fitFlowToElements = profile:getBool("fitFlowToElements", self.lateralFlowSize == 0)
	self.wrapAround = profile:getBool("wrapAround", self.wrapAround)
	self.rememberLastFocus = profile:getBool("rememberLastFocus", self.rememberLastFocus)
end

function BoxLayoutElement:copyAttributes(src)
	BoxLayoutElement:superClass().copyAttributes(self, src)
	self.alignment = table.clone(src.alignment)
	self.fillDirections = table.clone(src.fillDirections)
	self.autoValidateLayout = src.autoValidateLayout
	self.useFullVisibility = src.useFullVisibility
	self.layoutToleranceX = src.layoutToleranceX
	self.layoutToleranceY = src.layoutToleranceY
	self.flowDirection = src.flowDirection
	self.focusDirection = src.focusDirection
	self.numFlows = src.numFlows
	self.lateralFlowSize = src.lateralFlowSize
	self.fitFlowToElements = src.fitFlowToElements
	self.elementSpacing = src.elementSpacing
	self.wrapAround = src.wrapAround
	self.rememberLastFocus = src.rememberLastFocus
end

function BoxLayoutElement:onGuiSetupFinished()
	BoxLayoutElement:superClass().onGuiSetupFinished(self)
	self.layoutToleranceX = BoxLayoutElement.LAYOUT_TOLERANCE * g_pixelSizeX
	self.layoutToleranceY = BoxLayoutElement.LAYOUT_TOLERANCE * g_pixelSizeY
	self:invalidateLayout()
end

function BoxLayoutElement:addElement(element)
	BoxLayoutElement:superClass().addElement(self, element)
	element:setAnchor(0, 0)
	element:setPivot(0, 0)
	if self.autoValidateLayout then
		self:invalidateLayout()
	end
end

function BoxLayoutElement:removeElement(element)
	BoxLayoutElement:superClass().removeElement(self, element)
	if self.autoValidateLayout then
		self:invalidateLayout()
	end
end

function BoxLayoutElement:getIsElementIncluded(element, ignoreVisibility)
	local v37_ = ((element.ignoreLayout or not ignoreVisibility) and not (element:getIsVisibleNonRec() and self.useFullVisibility) and true or false) and element.visible
	if v37_ then
		v37_ = not self.useFullVisibility
	end
	return v37_
end

-- Local values: indices, lateralIndices, flowTolerance, lateralTolerance, currentFlowSize, maxLateralSize, currentFlow, count, i, element, elementFlowSize, elementLateralSize, lateralFlowSize, _, size
function BoxLayoutElement:updateLayoutCells(ignoreVisibility)
	self.cells = {
		{}
	}
	local v40_ = BoxLayoutElement.FLOW_INDICES[self.flowDirection]
	local v41_ = BoxLayoutElement.FLOW_INDICES[BoxLayoutElement.FLOW_LATERAL_TABLE[self.flowDirection]]
	local v42_ = self.layoutToleranceX
	local v43_ = self.layoutToleranceY
	if self.flowDirection == BoxLayoutElement.FLOW_VERTICAL then
		v42_ = v43_
	end
	self.flowSizes = {}
	self.lateralFlowSizes = {}
	self.maxFlowSize = 0
	self.totalLateralSize = 0
	local v44_ = 0
	local v45_ = 1
	local v46_ = 0
	local v47_ = 1
	for _, v48_ in ipairs(self.elements) do
		if self:getIsElementIncluded(v48_, ignoreVisibility) then
			local v49_ = v48_.absSize[v40_.ELEMENT_SIZE] + v48_.margin[v40_.ELEMENT_MARGIN_LOWER] + v48_.margin[v40_.ELEMENT_MARGIN_UPPER]
			local v50_ = v48_.absSize[v41_.ELEMENT_SIZE] + v48_.margin[v41_.ELEMENT_MARGIN_LOWER] + v48_.margin[v41_.ELEMENT_MARGIN_UPPER]
			if v44_ + v49_ + self.elementSpacing - v42_ > self.absSize[v40_.LAYOUT_FLOW_SIZE] and (self.numFlows == 0 or v45_ < self.numFlows) then
				v45_ = v45_ + 1
				local v51_ = self.cells
				table.insert(v51_, {})
				v46_ = 0
				v47_ = 1
				v44_ = 0
			end
			self.cells[v45_][v47_] = v48_
			local v52_ = v44_ + v49_
			self.flowSizes[v45_] = v52_
			v44_ = v52_ + self.elementSpacing
			local v53_ = self.maxFlowSize
			self.maxFlowSize = math.max(v53_, v44_)
			local v54_ = self.fitFlowToElements and v50_ and v50_ or self.lateralFlowSize
			v46_ = math.max(v46_, v54_)
			self.lateralFlowSizes[v45_] = v46_
			v47_ = v47_ + 1
		end
	end
	for _, v55_ in pairs(self.lateralFlowSizes) do
		self.totalLateralSize = self.totalLateralSize + v55_
	end
end

-- Local values: offsets, flowDirection, lateralDirection, flowOffset, flowIndexStart, flowIndexEnd, flowDir, flowIndex, flow, cellIndexStart, cellIndexEnd, cellDir, cellOffset, cellIndex, cell, cellLateralOffset, cellLateralSize, cellPos
function BoxLayoutElement:applyCellPositions(offsetX, offsetY)
	local v59_ = { offsetX or 0, offsetY or 0 }
	local v60_ = self.flowDirection == BoxLayoutElement.FLOW_VERTICAL and 2 or 1
	local v61_ = self.flowDirection == BoxLayoutElement.FLOW_VERTICAL and 1 or 2
	local v62_ = self.alignment[v61_] * (self.absSize[v61_] - self.totalLateralSize) + v59_[v61_]
	local v63_ = 1
	local v64_ = #self.cells
	local v65_ = self.fillDirections[v61_]
	if v65_ ~= -1 then
		local v66_ = v63_
		v63_ = v64_
		v64_ = v66_
	end
	for v67_ = v64_, v63_, v65_ do
		local v68_ = self.cells[v67_]
		if v68_ == nil or #v68_ == 0 then
			break
		end
		local v69_ = 1
		local v70_ = #v68_
		local v71_ = self.fillDirections[v60_]
		if v71_ ~= -1 then
			local v72_ = v69_
			v69_ = v70_
			v70_ = v72_
		end
		local v73_ = self.alignment[v60_] * (self.absSize[v60_] - self.flowSizes[v67_]) + v59_[v60_]
		for v74_ = v70_, v69_, v71_ do
			local v75_ = v68_[v74_]
			if v75_ == nil then
				break
			end
			v75_:setAnchor(0, 0)
			v75_:setPivot(0, 0)
			local v76_
			if self.fitFlowToElements then
				local v77_ = v75_.absSize[v61_] + v75_.margin[v61_] + v75_.margin[v61_ + 2]
				v76_ = v62_ + self.alignment[v61_] * (self.lateralFlowSizes[v67_] - v77_)
			else
				v76_ = v62_
			end
			local v78_ = { v73_, v76_ }
			v75_:setPosition(v78_[v60_] + v75_.margin[1], v78_[v61_] + v75_.margin[4])
			v73_ = v73_ + v75_.absSize[v60_] + self.elementSpacing + v75_.margin[v60_] + v75_.margin[v60_ + 2]
		end
		v62_ = v62_ + self.lateralFlowSizes[v67_]
	end
end

-- Local values: prevElement, firstElement, lastElement, _, flow, _, cell, _, flow, _, cell, element
function BoxLayoutElement:focusLinkCells()
	self.defaultFocusTarget = nil
	local v80_ = nil
	local v81_ = nil
	local v82_ = nil
	for _, v83_ in pairs(self.cells) do
		for _, v84_ in pairs(v83_) do
			if v80_ then
				v82_ = v84_:findFirstFocusable(true)
			else
				v80_ = v84_:findFirstFocusable(true)
				if v80_:canReceiveFocus() then
					self.defaultFocusTarget = v80_
				else
					v80_ = nil
				end
			end
		end
	end
	self.incomingFocusTargets = {}
	for _, v85_ in pairs(self.cells) do
		for _, v86_ in pairs(v85_) do
			local v87_ = v86_:findFirstFocusable(true)
			if v87_:canReceiveFocus() then
				self:focusLinkChildElement(v87_, v81_, v80_, v82_)
				v81_ = v87_
			end
		end
	end
end

-- Local values: previousDirection, nextDirection
function BoxLayoutElement:focusLinkChildElement(element, previousElement, firstElement, lastElement)
	local v93_ = FocusManager.TOP
	local v94_ = FocusManager.BOTTOM
	if self.focusDirection == BoxLayoutElement.FLOW_HORIZONTAL then
		v93_ = FocusManager.LEFT
		v94_ = FocusManager.RIGHT
	end
	if previousElement then
		FocusManager:linkElements(previousElement, v94_, element)
		FocusManager:linkElements(element, v93_, previousElement)
	end
	if element == firstElement then
		self.incomingFocusTargets[v93_] = element
		if not self.wrapAround then
			element.focusChangeOverride = FocusManager:getFocusOverrideFunction({ v93_ }, self, true)
		end
	end
	if element == lastElement then
		self.incomingFocusTargets[v94_] = element
		if self.wrapAround then
			FocusManager:linkElements(element, v94_, firstElement)
			FocusManager:linkElements(firstElement, v93_, element)
		else
			element.focusChangeOverride = FocusManager:getFocusOverrideFunction({ v94_ }, self, true)
		end
	else
		if element ~= firstElement then
			element.focusChangeOverride = nil
		end
		return
	end
end

-- Local values: needsUpdate
function BoxLayoutElement:invalidateLayout(ignoreVisibility, blockLayoutUpdate)
	local v98_ = not blockLayoutUpdate
	if v98_ then
		self:updateLayoutCells(ignoreVisibility)
	end
	self:applyCellPositions()
	if self.handleFocus and (self.focusDirection ~= BoxLayoutElement.FLOW_NONE and v98_) then
		self:focusLinkCells(self.cells)
	end
	return self.maxFlowSize
end

-- Local values: _, v
function BoxLayoutElement:canReceiveFocus()
	if self.handleFocus then
		for _, v100_ in ipairs(self.elements) do
			if v100_:canReceiveFocus() then
				return true
			end
		end
	end
	return false
end

-- Local values: focus, _, element, focusTarget, checkCount, next
function BoxLayoutElement:getFocusTarget(incomingDirection, moveDirection)
	local v104_ = self.firstDefaultFocusTarget
	if not (v104_ and v104_:canReceiveFocus()) then
		for _, v105_ in ipairs(self.elements) do
			if v105_:canReceiveFocus() then
				v104_ = v105_
				break
			end
		end
	end
	if v104_ then
		if not v104_:canReceiveFocus() then
			v104_ = self
		end
	else
		v104_ = self
	end
	if self.rememberLastFocus and (self.lastFocusElement ~= nil and self.lastFocusElement:canReceiveFocus()) then
		return self.lastFocusElement
	end
	local v106_ = self.incomingFocusTargets[incomingDirection]
	local v107_ = 0
	while v106_ ~= nil and (not v106_:canReceiveFocus() and v107_ < #self.elements) do
		v106_ = FocusManager:getElementById(v106_.focusChangeData[moveDirection])
		v107_ = v107_ + 1
	end
	return v106_ or v104_
end

-- Local values: lastFocus
function BoxLayoutElement:onFocusLeave()
	BoxLayoutElement:superClass().onFocusLeave(self)
	if self.rememberLastFocus then
		local v109_ = FocusManager:getFocusedElement()
		if v109_:isChildOf(self) then
			self.lastFocusElement = v109_
		end
	end
end

function BoxLayoutElement:updateAbsolutePosition()
	BoxLayoutElement:superClass().updateAbsolutePosition(self)
	self:applyCellPositions()
end
