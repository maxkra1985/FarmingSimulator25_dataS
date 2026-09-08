-- Local values: TableHeaderElement_mt
TableHeaderElement = {
	["SORTING_OFF"] = 1,
	["SORTING_ASC"] = 2,
	["SORTING_DESC"] = 3,
	["NAME_ASC_ICON"] = "iconAscending",
	["NAME_DESC_ICON"] = "iconDescending"
}
local TableHeaderElement_mt = Class(TableHeaderElement, ButtonElement)
Gui.registerGuiElement("TableHeader", TableHeaderElement)

-- Upvalues: TableHeaderElement_mt
-- Local values: self
function TableHeaderElement.new(target, custom_mt)
	-- upvalues: (copy) TableHeaderElement_mt
	local v4_ = ButtonElement.new(target, custom_mt or TableHeaderElement_mt)
	v4_.allowedSortingStates = {
		[TableHeaderElement.SORTING_OFF] = true,
		[TableHeaderElement.SORTING_ASC] = false,
		[TableHeaderElement.SORTING_DESC] = false
	}
	v4_.sortingOrder = TableHeaderElement.SORTING_OFF
	v4_.sortingIcons = {
		[TableHeaderElement.SORTING_OFF] = nil,
		[TableHeaderElement.SORTING_ASC] = nil,
		[TableHeaderElement.SORTING_DESC] = nil
	}
	v4_.targetTableId = ""
	v4_.columnName = ""
	return v4_
end

-- Local values: allowAscendingSort, allowDescendingSort
function TableHeaderElement:loadFromXML(xmlFile, key)
	TableHeaderElement:superClass().loadFromXML(self, xmlFile, key)
	self.targetTableId = getXMLString(xmlFile, key .. "#targetTableId") or self.targetTableId
	self.columnName = getXMLString(xmlFile, key .. "#columnName") or self.columnName
	local v8_ = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowSortingAsc"), self.allowedSortingStates[TableHeaderElement.SORTING_ASC])
	local v9_ = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowSortingDesc"), self.allowedSortingStates[TableHeaderElement.SORTING_DESC])
	self.allowedSortingStates[TableHeaderElement.SORTING_ASC] = v8_
	self.allowedSortingStates[TableHeaderElement.SORTING_DESC] = v9_
end

function TableHeaderElement:loadProfile(profile, applyProfile)
	TableHeaderElement:superClass().loadProfile(self, profile, applyProfile)
	self.columnName = profile:getValue("columnName", self.columnName)
	self.allowedSortingStates[TableHeaderElement.SORTING_ASC] = profile:getBool("allowSortingAsc", self.allowedSortingStates[TableHeaderElement.SORTING_ASC])
	self.allowedSortingStates[TableHeaderElement.SORTING_DESC] = profile:getBool("allowSortingDesc", self.allowedSortingStates[TableHeaderElement.SORTING_DESC])
end

function TableHeaderElement:copyAttributes(src)
	TableHeaderElement:superClass().copyAttributes(self, src)
	self.targetTableId = src.targetTableId
	self.columnName = src.columnName
	local v15_ = {}
	local v16_ = src.allowedSortingStates
	__set_list(v15_, 1, {unpack(v16_)})
	self.allowedSortingStates = v15_
end

-- Local values: _, child
function TableHeaderElement:onGuiSetupFinished()
	TableHeaderElement:superClass().onGuiSetupFinished(self)
	for _, v18_ in pairs(self.elements) do
		if v18_.name == TableHeaderElement.NAME_ASC_ICON then
			self.sortingIcons[TableHeaderElement.SORTING_ASC] = v18_
		end
		if v18_.name == TableHeaderElement.NAME_DESC_ICON then
			self.sortingIcons[TableHeaderElement.SORTING_DESC] = v18_
		end
	end
end

-- Local values: prevOrderIndex
function TableHeaderElement:toggleSorting()
	local v20_ = self.sortingOrder
	repeat
		self.sortingOrder = self.sortingOrder % #self.allowedSortingStates + 1
	until self.allowedSortingStates[self.sortingOrder]
	if v20_ ~= self.sortingOrder then
		self:updateSortingDisplay()
	end
	return self.sortingOrder
end

function TableHeaderElement:disableSorting()
	self.sortingOrder = TableHeaderElement.SORTING_OFF
	self:updateSortingDisplay()
end

-- Local values: sortOrderIndex, icon
function TableHeaderElement:updateSortingDisplay()
	for v23_, v24_ in pairs(self.sortingIcons) do
		if v23_ == self.sortingOrder then
			v24_:setVisible(true)
		else
			v24_:setVisible(false)
		end
	end
end
