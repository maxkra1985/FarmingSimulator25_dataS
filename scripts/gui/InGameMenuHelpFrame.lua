InGameMenuHelpFrame = {}
local InGameMenuHelpFrame_mt = Class(InGameMenuHelpFrame, TabbedMenuFrameElement)
function InGameMenuHelpFrame.register()
	local inGameMenuHelpFrame = InGameMenuHelpFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuHelpFrame.xml", "HelpFrame", inGameMenuHelpFrame, true)
end
function InGameMenuHelpFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuHelpFrame_mt)
	return self
end
function InGameMenuHelpFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuHelpFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function InGameMenuHelpFrame:initialize()
	InGameMenuHelpFrame:superClass().initialize(self)
	self.helpLineDotTemplate:unlinkElement()
	FocusManager:removeElement(self.helpLineDotTemplate)
end
function InGameMenuHelpFrame:delete()
	self.helpLineContentItem:delete()
	self.helpLineContentItemTitle:delete()
	for k, clone in pairs(self.helpLineDotBox.elements) do
		clone:delete()
		self.helpLineDotBox.elements[k] = nil
	end
	self.helpLineDotTemplate:delete()
	InGameMenuHelpFrame:superClass().delete(self)
end
function InGameMenuHelpFrame:onFrameOpen()
	InGameMenuHelpFrame:superClass().onFrameOpen(self)
	self.customEnvironments = g_helpLineManager:getCustomEnvironmentNames()
	local texts = {}
	for index, env in ipairs(self.customEnvironments) do
		if string.isNilOrWhitespace(env) then
			table.insert(texts, g_i18n:getText("ui_helpLine_baseGame"))
		else
			local mod = g_modManager:getModByName(env)
			if mod ~= nil then
				table.insert(texts, mod.title)
			else
				table.insert(texts, "Unknown")
			end
		end
	end
	self.helpLineSelector:setTexts(texts)
	for i, dot in pairs(self.helpLineDotBox.elements) do
		dot:delete()
		self.helpLineDotBox.elements[i] = nil
	end
	if 1 < #self.helpLineSelector.texts then
		for index, _ in ipairs(self.helpLineSelector.texts) do
			local dot = self.helpLineDotTemplate:clone(self.helpLineDotBox)
			function dot.getIsSelected()
				return self.helpLineSelector:getState() == index
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
function InGameMenuHelpFrame:updateContents(page)
	self.helpLineContentItem:unlinkElement()
	self.helpLineContentItemTitle:unlinkElement()
	for i = #self.helpLineContentBox.elements, 1, -1 do
		self.helpLineContentBox.elements[i]:delete()
	end
	if page == nil then
		return
	else
		self.helpLineTitleElement:setText(g_helpLineManager:convertText(page.title, page.customEnvironment))
		for _, paragraph in ipairs(page.paragraphs) do
			if paragraph.title ~= nil then
				local titleElement = self.helpLineContentItemTitle:clone(self.helpLineContentBox)
				titleElement:setText(g_helpLineManager:convertText(paragraph.title, paragraph.customEnvironment))
			end
			local row = self.helpLineContentItem:clone(self.helpLineContentBox)
			local textElement = row:getDescendantByName("text")
			local textFullElement = row:getDescendantByName("textFullWidth")
			local imageElement = row:getDescendantByName("image")
			local textHeight = 0
			local textHeightFullHeight = 0
			if paragraph.noSpacing then
				row.margin = { 0, 0, 0, 0 }
			end
			if paragraph.image ~= nil then
				textFullElement:setVisible(false)
				if paragraph.text ~= nil then
					textElement:setText(g_helpLineManager:convertText(paragraph.text, paragraph.customEnvironment))
					textHeight = textElement:getTextHeight(true)
					textElement:setSize(nil, textHeight)
				end
				local filename = Utils.getFilename(paragraph.image.filename, page.baseDirectory)
				imageElement:setImageFilename(filename)
				imageElement:setImageUVs(nil, unpack(paragraph.image.uvs))
				if imageElement.originalWidth == nil then
					imageElement.originalWidth = imageElement.absSize[1]
				end
				if paragraph.image.displaySize ~= nil then
					imageElement:setSize(paragraph.image.displaySize[1], paragraph.image.displaySize[2])
				elseif paragraph.text == nil then
					imageElement:setSize(row.absSize[1], row.absSize[1] * paragraph.image.aspectRatio * g_screenAspectRatio)
				else
					imageElement:setSize(imageElement.originalWidth, nil)
				end
				if paragraph.text ~= nil and paragraph.alignToImage then
					textElement:setSize(nil, imageElement.size[2])
					textElement.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT.MIDDLE
				end
			else
				textElement:setVisible(false)
				imageElement:setVisible(false)
				if paragraph.text ~= nil then
					textFullElement:setText(g_helpLineManager:convertText(paragraph.text, paragraph.customEnvironment))
				end
				textHeightFullHeight = textFullElement:getTextHeight(true)
				textFullElement:setSize(nil, textHeightFullHeight)
			end
			local imageHeight = paragraph.image ~= nil and imageElement.absSize[2] or 0
			row:setSize(nil, math.max(textHeight, textHeightFullHeight, imageHeight))
			row:invalidateLayout()
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
function InGameMenuHelpFrame:getNumberOfSections()
	local customEnvironment = self.customEnvironments[self.helpLineSelector:getState()]
	return #g_helpLineManager:getCategories(customEnvironment)
end
function InGameMenuHelpFrame:getNumberOfItemsInSection(list, section)
	local customEnvironment = self.customEnvironments[self.helpLineSelector:getState()]
	local category = g_helpLineManager:getCategory(customEnvironment, section)
	return #category.pages
end
function InGameMenuHelpFrame:getTitleForSectionHeader(list, section)
	local customEnvironment = self.customEnvironments[self.helpLineSelector:getState()]
	local category = g_helpLineManager:getCategory(customEnvironment, section)
	return g_i18n:convertText(category.title, category.customEnvironment)
end
function InGameMenuHelpFrame:populateCellForItemInSection(list, section, index, cell)
	local page = self:getPage(section, index)
	cell:getAttribute("title"):setText(g_i18n:convertText(page.title, page.customEnvironment))
	local icon = cell:getAttribute("icon")
	if page.iconSliceId ~= nil then
		icon:setVisible(true)
		icon:setImageSlice(nil, page.iconSliceId)
	else
		icon:setVisible(false)
	end
end
function InGameMenuHelpFrame:getPage(categoryIndex, pageIndex)
	local customEnvironment = self.customEnvironments[self.helpLineSelector:getState()]
	local category = g_helpLineManager:getCategory(customEnvironment, categoryIndex)
	return category.pages[pageIndex]
end
function InGameMenuHelpFrame:openPage(categoryIndex, pageIndex, customEnvironment)
	local customEnvironmentIndex = 1
	if self.customEnvironments ~= nil then
		for i, env in ipairs(self.customEnvironments) do
			if env == customEnvironment then
				customEnvironmentIndex = i
				break
			end
		end
	end
	self.helpLineSelector:setState(customEnvironmentIndex)
	self.helpLineList:reloadData()
	self:setSoundSuppressed(true)
	self.helpLineList:setSelectedItem(categoryIndex, pageIndex, true, 1)
	self:setSoundSuppressed(false)
end
