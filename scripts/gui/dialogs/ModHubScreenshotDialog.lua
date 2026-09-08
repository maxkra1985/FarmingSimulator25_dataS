-- Local values: ModHubScreenshotDialog_mt
ModHubScreenshotDialog = {}
local ModHubScreenshotDialog_mt = Class(ModHubScreenshotDialog, DialogElement)
function ModHubScreenshotDialog.register()
	local v2_ = ModHubScreenshotDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ModHubScreenshotDialog.xml", "ModHubScreenshotDialog", v2_)
	ModHubScreenshotDialog.INSTANCE = v2_
end

-- Local values: dialog
function ModHubScreenshotDialog.show(modInfo)
	if ModHubScreenshotDialog.INSTANCE ~= nil then
		ModHubScreenshotDialog.INSTANCE:setModInfo(modInfo)
		g_gui:showDialog("ModHubScreenshotDialog")
	end
end

-- Upvalues: ModHubScreenshotDialog_mt
-- Local values: self
function ModHubScreenshotDialog.new(target, custom_mt)
	-- upvalues: (copy) ModHubScreenshotDialog_mt
	return DialogElement.new(target, custom_mt or ModHubScreenshotDialog_mt)
end

-- Local values: modInfo
function ModHubScreenshotDialog.createFromExistingGui(gui, guiName)
	ModHubScreenshotDialog.register()
	local v7_ = gui.modInfo
	ModHubScreenshotDialog.show(v7_)
end

-- Local values: oldSliderFunc
function ModHubScreenshotDialog:onCreate()
	local v_u_9_ = self.list.onSliderValueChanged
	function self.list.onSliderValueChanged(p10_, p11_, p12_, p13_)
		-- upvalues: (copy) v_u_9_, (copy) self
		v_u_9_(p10_, p11_, p12_, p13_)
		p10_:setSelectedItem(1, self.listSlider.currentValue)
	end
end

function ModHubScreenshotDialog:onOpen()
	ModHubScreenshotDialog:superClass().onOpen(self)
	self.list:setSelectedIndex(1)
end

function ModHubScreenshotDialog:onClose()
	ModHubScreenshotDialog:superClass().onClose(self)
end

function ModHubScreenshotDialog:setModInfo(modInfo)
	self.filenames = modInfo:getScreenshots()
	self.list:reloadData()
	self.modInfo = modInfo
end

function ModHubScreenshotDialog:getNumberOfItemsInSection(list, section)
	return #self.filenames
end

function ModHubScreenshotDialog:populateCellForItemInSection(list, section, index, cell)
	cell:getAttribute("image"):setImageFilename(self.filenames[index])
end

function ModHubScreenshotDialog:onListSelectionChanged(list, section, index)
	self:updateSelectors()
end

-- Local values: curIndex
function ModHubScreenshotDialog:inputEvent(action, value, eventUsed)
	local v27_ = ModHubScreenshotDialog:superClass().inputEvent(self, action, value, eventUsed)
	if not v27_ and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
		local v28_ = self.list.selectedIndex
		if action == InputAction.MENU_PAGE_PREV then
			local v29_ = self.list
			local v30_ = v28_ - 1
			v29_:setSelectedIndex((math.max(v30_, 1)))
		else
			self.list:setSelectedIndex(v28_ + 1)
		end
		self:updateSelectors()
		v27_ = true
	end
	return v27_
end

function ModHubScreenshotDialog:updateSelectors()
	self.selectorLeftGamepad:setVisible(self.list.selectedIndex ~= 1)
	self.selectorRightGamepad:setVisible(self.list.selectedIndex ~= #self.filenames)
end

function ModHubScreenshotDialog:onClickBack(forceBack, usedMenuButton)
	return usedMenuButton and true or self:close()
end
