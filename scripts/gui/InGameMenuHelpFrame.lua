-- Local values: InGameMenuHelpFrame_mt
InGameMenuHelpFrame = {}
local InGameMenuHelpFrame_mt = Class(InGameMenuHelpFrame, TabbedMenuFrameElement)
function InGameMenuHelpFrame.register()
	local v2_ = InGameMenuHelpFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuHelpFrame.xml", "HelpFrame", v2_, true)
end

-- Upvalues: InGameMenuHelpFrame_mt
-- Local values: self
function InGameMenuHelpFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuHelpFrame_mt
	return TabbedMenuFrameElement.new(target, custom_mt or InGameMenuHelpFrame_mt)
end

-- Local values: newGui
function InGameMenuHelpFrame.createFromExistingGui(gui, guiName)
	local v7_ = InGameMenuHelpFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v7_, true)
	return v7_
end

function InGameMenuHelpFrame:initialize()
	InGameMenuHelpFrame:superClass().initialize(self)
	self.helpLineDotTemplate:unlinkElement()
	FocusManager:removeElement(self.helpLineDotTemplate)
end

-- Local values: k, clone
function InGameMenuHelpFrame:delete()
	self.helpLineContentItem:delete()
	self.helpLineContentItemTitle:delete()
	for v10_, v11_ in pairs(self.helpLineDotBox.elements) do
		v11_:delete()
		self.helpLineDotBox.elements[v10_] = nil
	end
	self.helpLineDotTemplate:delete()
	InGameMenuHelpFrame:superClass().delete(self)
end

-- Local values: texts, index, env, mod, i, dot, index, _, dot
function InGameMenuHelpFrame:onFrameOpen()
	InGameMenuHelpFrame:superClass().onFrameOpen(self)
	self.customEnvironments = g_helpLineManager:getCustomEnvironmentNames()
	local v13_ = {}
	for _, v14_ in ipairs(self.customEnvironments) do
		if string.isNilOrWhitespace(v14_) then
			local v15_ = g_i18n
			table.insert(v13_, v15_:getText("ui_helpLine_baseGame"))
		else
			local v16_ = g_modManager:getModByName(v14_)
			if v16_ == nil then
				table.insert(v13_, "Unknown")
			else
				local v17_ = v16_.title
				table.insert(v13_, v17_)
			end
		end
	end
	self.helpLineSelector:setTexts(v13_)
	for v18_, v19_ in pairs(self.helpLineDotBox.elements) do
		v19_:delete()
		self.helpLineDotBox.elements[v18_] = nil
	end
	if #self.helpLineSelector.texts > 1 then
		for v_u_20_, _ in ipairs(self.helpLineSelector.texts) do
			self.helpLineDotTemplate:clone(self.helpLineDotBox).getIsSelected = function()
				-- upvalues: (copy) self, (copy) v_u_20_
				return self.helpLineSelector:getState() == v_u_20_
			end
		end
		self.helpLineDotBox:invalidateLayout()
		FocusManager:linkElements(self.helpLineSelector, FocusManager.TOP, self.helpLineList)
		FocusManager:linkElements(self.helpLineSelector, FocusManager.BOTTOM, self.helpLineList)
		FocusManager:linkElements(self.helpLineSelector, FocusManager.LEFT, self.helpLineList)
		FocusManager:linkElements(self.helpLineSelector, FocusManager.RIGHT, self.helpLineList)
		FocusManager:linkElements(self.helpLineList, FocusManager.TOP, self.helpLineSelector)
		FocusManager:linkElements(self.helpLineList, FocusManager.BOTTOM, self.helpLineSelector)
		FocusManager:linkElements(self.helpLineList, FocusManager.LEFT, self.helpLineSelector)
		FocusManager:linkElements(self.helpLineList, FocusManager.RIGHT, self.helpLineSelector)
	else
		FocusManager:linkElements(self.helpLineList, FocusManager.TOP, nil)
		FocusManager:linkElements(self.helpLineList, FocusManager.BOTTOM, nil)
	end
	self.helpLineList:reloadData()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.helpLineList)
	self:setSoundSuppressed(false)
	self.helpLineContentBox:registerActionEvents()
end

function InGameMenuHelpFrame:onFrameClose()
	self.helpLineContentBox:removeActionEvents()
	InGameMenuHelpFrame:superClass().onFrameClose(self)
end

-- Local values: i, _, paragraph, titleElement, row, textElement, textFullElement, imageElement, textHeight, textHeightFullHeight, filename, imageHeight
function InGameMenuHelpFrame:updateContents(page)
	self.helpLineContentItem:unlinkElement()
	self.helpLineContentItemTitle:unlinkElement()
	for v24_ = #self.helpLineContentBox.elements, 1, -1 do
		self.helpLineContentBox.elements[v24_]:delete()
	end
	if page ~= nil then
		self.helpLineTitleElement:setText(g_helpLineManager:convertText(page.title, page.customEnvironment))
		for _, v25_ in ipairs(page.paragraphs) do
			if v25_.title ~= nil then
				self.helpLineContentItemTitle:clone(self.helpLineContentBox):setText(g_helpLineManager:convertText(v25_.title, v25_.customEnvironment))
			end
			local v26_ = self.helpLineContentItem:clone(self.helpLineContentBox)
			local v27_ = v26_:getDescendantByName("text")
			local v28_ = v26_:getDescendantByName("textFullWidth")
			local v29_ = v26_:getDescendantByName("image")
			local v30_ = 0
			local v31_ = 0
			if v25_.noSpacing then
				v26_.margin = {
					0,
					0,
					0,
					0
				}
			end
			if v25_.image == nil then
				v27_:setVisible(false)
				v29_:setVisible(false)
				if v25_.text ~= nil then
					v28_:setText(g_helpLineManager:convertText(v25_.text, v25_.customEnvironment))
				end
				v31_ = v28_:getTextHeight(true)
				v28_:setSize(nil, v31_)
			else
				v28_:setVisible(false)
				if v25_.text ~= nil then
					v27_:setText(g_helpLineManager:convertText(v25_.text, v25_.customEnvironment))
					v30_ = v27_:getTextHeight(true)
					v27_:setSize(nil, v30_)
				end
				v29_:setImageFilename((Utils.getFilename(v25_.image.filename, page.baseDirectory)))
				local v32_ = v25_.image.uvs
				v29_:setImageUVs(nil, unpack(v32_))
				if v29_.originalWidth == nil then
					v29_.originalWidth = v29_.absSize[1]
				end
				if v25_.image.displaySize == nil then
					if v25_.text == nil then
						v29_:setSize(v26_.absSize[1], v26_.absSize[1] * v25_.image.aspectRatio * g_screenAspectRatio)
					else
						v29_:setSize(v29_.originalWidth, nil)
					end
				else
					v29_:setSize(v25_.image.displaySize[1], v25_.image.displaySize[2])
				end
				if v25_.text ~= nil and v25_.alignToImage then
					v27_:setSize(nil, v29_.size[2])
					v27_.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT.MIDDLE
				end
			end
			local v33_ = v25_.image == nil and 0 or (v29_.absSize[2] or 0)
			v26_:setSize(nil, (math.max(v30_, v31_, v33_)))
			v26_:invalidateLayout()
		end
		self.helpLineContentBox:invalidateLayout()
	end
end

function InGameMenuHelpFrame:onListSelectionChanged(list, section, index)
	if self.helpLineContentItem ~= nil then
		self:updateContents(self:getPage(section, index))
	end
end

function InGameMenuHelpFrame:onSelectorChanged()
	self.helpLineList:reloadData()
	self.helpLineList:setSelectedItem(1, 1)
end

-- Local values: customEnvironment
function InGameMenuHelpFrame:getNumberOfSections()
	local v39_ = self.customEnvironments[self.helpLineSelector:getState()]
	return #g_helpLineManager:getCategories(v39_)
end

-- Local values: customEnvironment, category
function InGameMenuHelpFrame:getNumberOfItemsInSection(list, section)
	local v42_ = self.customEnvironments[self.helpLineSelector:getState()]
	return #g_helpLineManager:getCategory(v42_, section).pages
end

-- Local values: customEnvironment, category
function InGameMenuHelpFrame:getTitleForSectionHeader(list, section)
	local v45_ = self.customEnvironments[self.helpLineSelector:getState()]
	local v46_ = g_helpLineManager:getCategory(v45_, section)
	return g_i18n:convertText(v46_.title, v46_.customEnvironment)
end

-- Local values: page, icon
function InGameMenuHelpFrame:populateCellForItemInSection(list, section, index, cell)
	local v51_ = self:getPage(section, index)
	cell:getAttribute("title"):setText(g_i18n:convertText(v51_.title, v51_.customEnvironment))
	local v52_ = cell:getAttribute("icon")
	if v51_.iconSliceId == nil then
		v52_:setVisible(false)
	else
		v52_:setVisible(true)
		v52_:setImageSlice(nil, v51_.iconSliceId)
	end
end

-- Local values: customEnvironment, category
function InGameMenuHelpFrame:getPage(categoryIndex, pageIndex)
	local v56_ = self.customEnvironments[self.helpLineSelector:getState()]
	return g_helpLineManager:getCategory(v56_, categoryIndex).pages[pageIndex]
end

-- Local values: customEnvironmentIndex, i, env
function InGameMenuHelpFrame:openPage(categoryIndex, pageIndex, customEnvironment)
	local v61_ = 1
	if self.customEnvironments ~= nil then
		for v62_, v63_ in ipairs(self.customEnvironments) do
			if v63_ == customEnvironment then
				v61_ = v62_
				break
			end
		end
	end
	self.helpLineSelector:setState(v61_)
	self.helpLineList:reloadData()
	self:setSoundSuppressed(true)
	self.helpLineList:setSelectedItem(categoryIndex, pageIndex, true, 1)
	self:setSoundSuppressed(false)
end
