InGameMenuProductionFrame = {}
local InGameMenuProductionFrame_mt = Class(InGameMenuProductionFrame, TabbedMenuFrameElement)
InGameMenuProductionFrame.UPDATE_INTERVAL = 5000
InGameMenuProductionFrame.STATUS_BAR_LOW = 0.2
InGameMenuProductionFrame.STATUS_BAR_HIGH = 0.8
InGameMenuProductionFrame.POINTS_OWNED = 1
InGameMenuProductionFrame.POINTS_UNOWNED = 2
function InGameMenuProductionFrame.register()
	local inGameMenuProductionFrame = InGameMenuProductionFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuProductionFrame.xml", "ProductionFrame", inGameMenuProductionFrame, true)
end
function InGameMenuProductionFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuProductionFrame_mt)
	self.hasCustomMenuButtons = true
	self.timeSinceLastStateUpdate = 0
	self.productionPoints = {}
	return self
end
function InGameMenuProductionFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuProductionFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function InGameMenuProductionFrame:delete()
	self.recipeItemTemplate:delete()
	InGameMenuProductionFrame:superClass().delete(self)
end
function InGameMenuProductionFrame:initialize()
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	self.recipeItemTemplate:unlinkElement()
	self.hotspotButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		callback = function()
			self:onButtonHotspot()
		end,
		profile = "buttonHotspot",
	}
	self.visitButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText("action_visit"),
		callback = function()
			self:onButtonVisit()
		end,
		profile = "buttonVisitPlace",
	}
	self.activateButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_activate"),
		callback = function()
			self:onButtonActivate()
		end,
		profile = "buttonOK",
	}
	self.toggleStorageModeButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText("ui_production_changeOutputMode"),
		callback = function()
			self:onButtonToggleOutputMode()
		end,
		profile = "buttonOK",
	}
	self.pointsSelector:setTexts({ g_i18n:getText(InGameMenuProductionFrame.SYMBOL_L10N.TEXT_OWNED), g_i18n:getText(InGameMenuProductionFrame.SYMBOL_L10N.TEXT_UNOWNED) })
	for i = 1, 2 do
		local dot = self.pointsDotBox.elements[i]
		function dot.getIsSelected()
			return self.pointsSelector:getState() == i
		end
	end
	self.pointsDotBox:invalidateLayout()
	FocusManager:linkElements(self.pointsList, FocusManager.LEFT, nil)
	FocusManager:linkElements(self.pointsList, FocusManager.RIGHT, self.productsList)
	FocusManager:linkElements(self.pointsList, FocusManager.TOP, self.pointsSelector)
	FocusManager:linkElements(self.pointsList, FocusManager.BOTTOM, nil)
	FocusManager:linkElements(self.productsList, FocusManager.LEFT, self.pointsList)
	FocusManager:linkElements(self.productsList, FocusManager.RIGHT, self.detailsSlider)
	FocusManager:linkElements(self.productsList, FocusManager.TOP, nil)
	FocusManager:linkElements(self.productsList, FocusManager.BOTTOM, nil)
	FocusManager:linkElements(self.detailsSlider, FocusManager.LEFT, self.productsList)
	FocusManager:linkElements(self.detailsSlider, FocusManager.RIGHT, nil)
	FocusManager:linkElements(self.detailsSlider, FocusManager.TOP, nil)
	FocusManager:linkElements(self.detailsSlider, FocusManager.BOTTOM, nil)
	local isNotReloading = not self.isReloading and not g_gui.currentlyReloading
	function self.pointsBoxBg.getIsSelected()
		return self.pointsList:getIsFocused() and isNotReloading
	end
	function self.pointsBoxArrow.getIsSelected()
		return self.pointsList:getIsFocused() and isNotReloading
	end
	function self.productsBoxBg.getIsSelected()
		return self.productsList:getIsFocused() and isNotReloading
	end
	function self.productsBoxBgTop.getIsSelected()
		return self.productsList:getIsFocused() and isNotReloading
	end
	function self.productsBoxBgArrow.getIsSelected()
		return self.productsList:getIsFocused() and isNotReloading
	end
	function self.detailsBoxBg.getIsSelected()
		return self.detailsSlider:getIsFocused() and isNotReloading
	end
	function self.detailsBoxBgTop.getIsSelected()
		return self.detailsSlider:getIsFocused() and isNotReloading
	end
end
function InGameMenuProductionFrame:onFrameOpen()
	InGameMenuProductionFrame:superClass().onFrameOpen(self)
	self.chainManager = g_currentMission.productionChainManager
	self:updateProductionLists()
	if #self.productionPoints == 0 then
		self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_UNOWNED, true)
	end
	if 0 < self.pointsList:getItemCount() then
		FocusManager:setFocus(self.pointsList)
	else
		FocusManager:setFocus(self.pointsSelector)
	end
end
function InGameMenuProductionFrame:unloadMapData()
	self.selectedProductionPoint = nil
end
function InGameMenuProductionFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
end
function InGameMenuProductionFrame:getProductionPoints()
	return self.productionPoints
end
function InGameMenuProductionFrame:setSelectedProductionPoint(productionPoint)
	local productions = nil
	if productionPoint.isOwned then
		self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_OWNED, true)
		productions = self.productionPoints
	else
		self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_UNOWNED, true)
		productions = self.unownedProductionPoints
	end
	for index, listProdPoint in ipairs(productions) do
		if listProdPoint == productionPoint then
			self.pointsList:setSelectedIndex(index)
			return
		end
	end
end
function InGameMenuProductionFrame:updateMenuButtons()
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if self.pointsList:getIsFocused() then
		local _, productionPoint = self:getSelectedProduction()
		if productionPoint ~= nil then
			local hotspot = nil
			if productionPoint.owningPlaceable ~= nil then
				hotspot = productionPoint.owningPlaceable:getHotspot()
			end
			if hotspot == nil and productionPoint.getHotspot ~= nil then
				hotspot = productionPoint:getHotspot()
			end
			if hotspot ~= nil then
				if hotspot == g_currentMission.currentMapTargetHotspot then
					self.hotspotButtonInfo.text = g_i18n:getText("action_untag")
				else
					self.hotspotButtonInfo.text = g_i18n:getText("action_tag")
				end
				table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
				if hotspot:getBeVisited() and Platform.gameplay.canVisitPOI then
					table.insert(self.menuButtonInfo, self.visitButtonInfo)
				end
			end
		end
	elseif self.productsList:getIsFocused() or self.detailsSlider:getIsFocused() then
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
			local production, productionPoint = self:getSelectedProduction()
			if production ~= nil and not production.outputs[1].isFactory then
				if productionPoint.getIsProductionEnabled ~= nil then
					self.activateButtonInfo.text = productionPoint:getIsProductionEnabled(production.id) and g_i18n:getText("button_deactivate") or g_i18n:getText("button_activate")
					table.insert(self.menuButtonInfo, self.activateButtonInfo)
				end
				if production.primaryProductFillType ~= FillType.UNKNOWN then
					table.insert(self.menuButtonInfo, self.toggleStorageModeButtonInfo)
				end
			end
		end
	end
	self:setMenuButtonInfoDirty()
end
function InGameMenuProductionFrame:getSelectedProduction()
	return self.selectedProduction, self.selectedProductionPoint
end
function InGameMenuProductionFrame:update(dt)
	InGameMenuProductionFrame:superClass().update(self, dt)
	self.timeSinceLastStateUpdate = self.timeSinceLastStateUpdate + dt
	if InGameMenuProductionFrame.UPDATE_INTERVAL <= self.timeSinceLastStateUpdate then
		self.timeSinceLastStateUpdate = 0
		self:updateProductionLists()
	end
end
function InGameMenuProductionFrame:getNumberOfSections(list, section)
	if list == self.detailsList then
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
			if self.selectedProduction.outputs[1].isFactory then
				return 3
			else
				return 4
			end
		end
		return 2
	else
		return 1
	end
end
function InGameMenuProductionFrame:getTitleForSectionHeader(list, section)
	if list == self.detailsList then
		local isUnowned = false
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED then
			isUnowned = true
		end
		if isUnowned then
			if section == 1 then
				return g_i18n:getText("ui_productions_outgoingProducts")
			end
			if section == 2 then
				local production = self:getSelectedProduction()
				local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(production.primaryProductFillType)
				local name = production.name or fillTypeDesc.title
				return g_i18n:getText("ui_productions_recipe") .. ": " .. name
			end
		else
			if section == 1 then
				return g_i18n:getText("ui_productions_incomingMaterials")
			end
			if section == 2 and not self.selectedProduction.outputs[1].isFactory then
				return g_i18n:getText("ui_productions_outgoingProducts")
			end
			if section == 4 or section == 3 and self.selectedProduction.outputs[1].isFactory then
				local production = self:getSelectedProduction()
				local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(production.primaryProductFillType)
				local name = production.name or fillTypeDesc.title
				return g_i18n:getText("ui_productions_recipe") .. ": " .. name
			end
		end
	end
	return nil
end
function InGameMenuProductionFrame:getNumberOfItemsInSection(list, section)
	if list == self.pointsList then
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
			return #self.productionPoints
		else
			return #self.unownedProductionPoints
		end
	elseif list == self.productsList then
		local _, productionPoint = self:getSelectedProduction()
		return productionPoint ~= nil and #productionPoint.sortedProductions or 0
	elseif list == self.detailsList then
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
			if section == 1 then
				return #self.selectedProductionPoint.sortedInputFillTypes
			elseif section == 2 then
				return #self.selectedProductionPoint.sortedOutputFillTypes
			else
				return 1
			end
		end
		return 1
	else
		return 0
	end
end
function InGameMenuProductionFrame:getCellTypeForItemInSection(list, section, index)
	if list == self.detailsList then
		local isOwned = true
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED then
			section = section + 2
			isOwned = false
		end
		if self.selectedProduction.outputs[1].isFactory and isOwned then
			if section == 1 then
				return "fillTypeCell"
			elseif section == 2 then
				return "detailsCell"
			elseif section == 3 then
				return "recipeCell"
			else
				return nil
			end
		end
		if section <= 2 then
			return "fillTypeCell"
		end
		if section == 3 then
			return "detailsCell"
		end
		if section == 4 then
			return "recipeCell"
		end
	end
end
function InGameMenuProductionFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.pointsList then
		local productionPoint = self.productionPoints[index]
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED then
			productionPoint = self.unownedProductionPoints[index]
		end
		cell:getAttribute("name"):setText(productionPoint:getName())
		local filename = nil
		local isPreplaced = false
		if productionPoint.owningPlaceable ~= nil then
			filename = productionPoint.owningPlaceable:getImageFilename()
			isPreplaced = productionPoint.owningPlaceable.customImageFilename ~= nil
		else
			filename = productionPoint:getImageFilename()
			isPreplaced = productionPoint.customImageFilename ~= nil
		end
		local icon = cell:getAttribute("icon")
		icon:setVisible(false)
		local iconPreplaced = cell:getAttribute("iconPreplaced")
		iconPreplaced:setVisible(false)
		if isPreplaced then
			iconPreplaced:setImageFilename(filename)
		else
			icon:setImageFilename(filename)
		end
	elseif list == self.productsList then
		local _, productionPoint = self:getSelectedProduction()
		local production = productionPoint.sortedProductions[index]
		local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(production.primaryProductFillType)
		if fillTypeDesc ~= nil then
			cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
		end
		cell:getAttribute("icon"):setVisible(fillTypeDesc ~= nil)
		cell:getAttribute("icon").getIsSelected = function()
			return production.status ~= ProductionPoint.PROD_STATUS.INACTIVE
		end
		local warning = cell:getAttribute("warning")
		function warning.getDoRenderText()
			local status = production.status
			local isError = status == ProductionPoint.PROD_STATUS.MISSING_INPUTS or status == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE
			return isError
		end
		cell:getAttribute("name"):setText(production.name or fillTypeDesc.title)
		local outputModeText = ""
		local fillType = production.primaryProductFillType
		if productionPoint.getOutputDistributionMode ~= nil then
			local outputMode = productionPoint:getOutputDistributionMode(fillType)
			outputModeText = g_i18n:getText("ui_production_output_storing")
			if outputMode == ProductionPoint.OUTPUT_MODE.DIRECT_SELL then
				outputModeText = g_i18n:getText("ui_production_output_selling")
			elseif outputMode == ProductionPoint.OUTPUT_MODE.AUTO_DELIVER then
				outputModeText = g_i18n:getText("ui_production_output_distributing")
			end
		end
		cell:getAttribute("activity"):setText(outputModeText)
	else
		if list == self.detailsList then
			local production, productionPoint = self:getSelectedProduction()
			local fillType = production.primaryProductFillType
			if cell.name == "fillTypeCell" then
				if section == 1 then
					fillType = productionPoint.sortedInputFillTypes[index]
				else
					fillType = productionPoint.sortedOutputFillTypes[index]
				end
			end
			local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
			if fillType ~= FillType.UNKNOWN then
				if cell.name == "recipeCell" then
					local fillLayoutFunc = function(layout, list)
						for i = 1, #layout.elements do
							layout.elements[1]:delete()
						end
						for index, item in pairs(list) do
							local template = self.recipeItemTemplate:clone(layout)
							local recipeFillType = g_fillTypeManager:getFillTypeByIndex(item.type)
							template:getDescendantByName("amount"):setText(g_i18n:formatNumber(item.amount, 2))
							template:getDescendantByName("name"):setText("x " .. recipeFillType.title)
							template:getDescendantByName("icon"):setImageFilename(recipeFillType.hudOverlayFilename)
						end
					end
					local inputLayout = cell:getAttribute("inputLayout")
					fillLayoutFunc(inputLayout, production.inputs)
					inputLayout:invalidateLayout()
					cell:setSize(nil, inputLayout.maxFlowSize)
					self.detailsList.cellDatabase.recipeCell.size[2] = inputLayout.maxFlowSize
					cell:getAttribute("arrowLayout"):invalidateLayout()
					local outputLayout = cell:getAttribute("outputLayout")
					fillLayoutFunc(outputLayout, production.outputs)
					outputLayout:invalidateLayout()
					if inputLayout.maxFlowSize < outputLayout.maxFlowSize then
						cell:setSize(nil, outputLayout.maxFlowSize)
						self.detailsList.cellDatabase.recipeCell.size[2] = outputLayout.maxFlowSize
						inputLayout:invalidateLayout()
						cell:getAttribute("arrowLayout"):invalidateLayout()
						outputLayout:invalidateLayout()
					end
					self.detailsList:buildSectionInfo()
					return
				end
				if cell.name == "fillTypeCell" then
					cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
					cell:getAttribute("fillType"):setText(fillTypeDesc.title)
					local fillLevel = productionPoint:getFillLevel(fillType)
					local capacity = productionPoint:getCapacity(fillType)
					cell:getAttribute("fillLevel"):setText(g_i18n:formatVolume(fillLevel, 0) .. " / " .. g_i18n:formatVolume(capacity, 0))
					if 1 <= capacity then
						cell:getAttribute("fillPercent"):setText(g_i18n:formatNumber(fillLevel / capacity * 100, 0) .. "%")
						self:setStatusBarValue(cell:getAttribute("bar"), fillLevel / capacity, true)
						return
					else
						cell:getAttribute("fillPercent"):setText("0%")
						self:setStatusBarValue(cell:getAttribute("bar"), 0, true)
						return
					end
				end
				if cell.name == "detailsCell" then
					cell:getAttribute("separator"):setVisible(section ~= 1)
					cell:getAttribute("iconLarge"):setImageFilename(fillTypeDesc.hudOverlayFilename)
					local status = production.status
					local statusKey = ProductionPoint.PROD_STATUS_TO_L10N[production.status] or ProductionPoint.PROD_STATUS_TO_L10N[ProductionPoint.PROD_STATUS.RUNNING]
					local isError = status == ProductionPoint.PROD_STATUS.MISSING_INPUTS or status == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE or status == ProductionPoint.PROD_STATUS.INACTIVE
					cell:getAttribute("infoStatus").getIsSelected = function()
						return isError
					end
					cell:getAttribute("infoStatus"):setLocaKey(statusKey)
					cell:getAttribute("infoCycles"):setText(MathUtil.round(production.cyclesPerMonth, 2))
					cell:getAttribute("infoCosts"):setValue(g_i18n:formatMoney(production.costsPerActiveMonth, 0, true))
				end
			end
		end
	end
end
function InGameMenuProductionFrame:setStatusBarValue(statusBarElement, value, lowIsDanger)
	local profile = InGameMenuProductionFrame.PROFILES.STATUS_BAR
	if lowIsDanger and (value < InGameMenuProductionFrame.STATUS_BAR_LOW or not lowIsDanger and InGameMenuProductionFrame.STATUS_BAR_HIGH < value) then
		profile = InGameMenuProductionFrame.PROFILES.STATUS_BAR_DANGER
	end
	statusBarElement:applyProfile(profile)
	local fullWidth = statusBarElement.parent.absSize[1] - statusBarElement.margin[1] * 2
	local minSize = 0
	if statusBarElement.startSize ~= nil then
		minSize = statusBarElement.startSize[1] + statusBarElement.endSize[1]
	end
	statusBarElement:setSize(math.max(minSize, fullWidth * math.min(1, value)), nil)
end
function InGameMenuProductionFrame:onListSelectionChanged(list, section, index)
	if list == self.pointsList then
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
			self.selectedProductionPoint = self.productionPoints[index]
		else
			self.selectedProductionPoint = self.unownedProductionPoints[index]
		end
		if self.selectedProductionPoint ~= nil then
			self.selectedProduction = self.selectedProductionPoint.sortedProductions[self.productsList:getSelectedIndexInSection()]
			self.selectedStorage = nil
			self.productsList:reloadData()
			if not self.isReloading then
				self.productsList:setSelectedIndex(1)
			end
		end
	elseif list == self.productsList then
		if self.selectedProductionPoint ~= nil then
			self.selectedProduction = self.selectedProductionPoint.sortedProductions[self.productsList:getSelectedIndexInSection()]
			self.selectedStorage = nil
			for e = #self.detailsList.elements, 1, -1 do
				local cell = self.detailsList.elements[e]
				self.detailsList:queueReusableCell(cell)
			end
			self.detailsList:buildSectionInfo()
			self.detailsList:updateView()
		end
	end
	if self.selectedProductionPoint ~= nil then
		if self.selectedProductionPoint.storage ~= nil then
			self.selectedStorage = self.selectedProductionPoint.storage.sortedFillTypes[index]
		elseif self.selectedProductionPoint.spec_factory ~= nil then
			self.selectedStorage = self.selectedProductionPoint.spec_factory.storage.sortedFillTypes[index]
		end
		self:updateMenuButtons()
	end
end
function InGameMenuProductionFrame:onButtonActivate()
	if not g_currentMission:getHasPlayerPermission("manageProductions") then
		InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"), nil, nil, DialogElement.TYPE_WARNING)
	else
		local production, productionPoint = self:getSelectedProduction()
		if production ~= nil then
			local state = productionPoint:getIsProductionEnabled(production.id)
			productionPoint:setProductionState(production.id, not state)
			self:updateProductionLists()
		end
	end
end
function InGameMenuProductionFrame:onButtonToggleOutputMode()
	if not g_currentMission:getHasPlayerPermission("manageProductions") then
		InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"), nil, nil, DialogElement.TYPE_WARNING)
	else
		local production, productionPoint = self:getSelectedProduction()
		local fillType = production.primaryProductFillType
		if fillType ~= FillType.UNKNOWN then
			productionPoint:toggleOutputDistributionMode(fillType)
			self.productsList:reloadData()
		end
	end
end
function InGameMenuProductionFrame:onButtonHotspot()
	local _, productionPoint = self:getSelectedProduction()
	if productionPoint ~= nil then
		local hotspot = productionPoint.owningPlaceable ~= nil and productionPoint.owningPlaceable:getHotspot() or productionPoint:getHotspot()
		if hotspot ~= nil then
			if g_currentMission.currentMapTargetHotspot == hotspot then
				g_currentMission:setMapTargetHotspot(nil)
			else
				g_currentMission:setMapTargetHotspot(hotspot)
			end
			self:updateMenuButtons()
			return
		end
		g_currentMission:setMapTargetHotspot(nil)
	end
end
function InGameMenuProductionFrame:onButtonVisit()
	local _, productionPoint = self:getSelectedProduction()
	if productionPoint ~= nil then
		local hotspot = productionPoint.owningPlaceable ~= nil and productionPoint.owningPlaceable:getHotspot() or productionPoint:getHotspot()
		if hotspot ~= nil then
			local x, y, z = hotspot:getTeleportWorldPosition()
			if x ~= nil and (y ~= nil and z ~= nil) then
				if g_localPlayer:getCurrentVehicle() ~= nil then
					g_localPlayer:leaveVehicle()
				end
				g_localPlayer:teleportTo(x, y, z)
				g_gui:changeScreen(nil)
			end
		end
	end
end
function InGameMenuProductionFrame:updateProductionLists()
	local productionPoints = table.copyIndex(self.chainManager:getProductionPointsForFarmId(self.playerFarm.farmId))
	self.productionPoints = {}
	local unownedProductionPoints = table.copyIndex(self.chainManager:getUnownedProductionPoints())
	self.unownedProductionPoints = {}
	local factories = self.chainManager:getFactoriesForFarmId(self.playerFarm.farmId)
	for _, factory in pairs(factories) do
		table.insert(productionPoints, factory)
	end
	local unownedFactories = self.chainManager:getUnownedFactories()
	for _, factory in pairs(unownedFactories) do
		table.insert(unownedProductionPoints, factory)
	end
	local pointSortFunc = function(pointsTable, targetTable)
		for _, productionPoint in ipairs(pointsTable) do
			table.insert(targetTable, productionPoint)
			productionPoint.sortedProductions = {}
			if productionPoint.productions == nil then
				continue
			end
			for _, production in ipairs(productionPoint.productions) do
				table.insert(productionPoint.sortedProductions, production)
			end
			table.sort(productionPoint.sortedProductions, function(productionA, productionB)
				local nameA = productionA.name
				if nameA == nil then
					nameA = g_fillTypeManager:getFillTypeTitleByIndex(productionA.primaryProductFillType)
				end
				local nameB = productionB.name
				if nameB == nil then
					nameB = g_fillTypeManager:getFillTypeTitleByIndex(productionB.primaryProductFillType)
				end
				return nameA < nameB
			end)
			productionPoint.sortedInputFillTypes = {}
			productionPoint.sortedOutputFillTypes = {}
			for _, fillType in ipairs(productionPoint.inputFillTypeIdsArray) do
				table.insert(productionPoint.sortedInputFillTypes, fillType)
			end
			table.sort(productionPoint.sortedInputFillTypes, function(a, b)
				local titleA = g_fillTypeManager:getFillTypeTitleByIndex(a)
				local titleB = g_fillTypeManager:getFillTypeTitleByIndex(b)
				return titleA < titleB
			end)
			for _, fillType in ipairs(productionPoint.outputFillTypeIdsArray) do
				table.insert(productionPoint.sortedOutputFillTypes, fillType)
			end
			table.sort(productionPoint.sortedOutputFillTypes, function(a, b)
				local titleA = g_fillTypeManager:getFillTypeTitleByIndex(a)
				local titleB = g_fillTypeManager:getFillTypeTitleByIndex(b)
				return titleA < titleB
			end)
		end
	end
	pointSortFunc(productionPoints, self.productionPoints)
	pointSortFunc(unownedProductionPoints, self.unownedProductionPoints)
	table.sort(self.productionPoints, function(a, b)
		return a:getName() < b:getName()
	end)
	table.sort(self.unownedProductionPoints, function(a, b)
		return a:getName() < b:getName()
	end)
	self.isReloading = true
	self.pointsList:reloadData()
	local hasPoints = 0 < self.pointsList:getItemCount()
	self.productsBoxBg:setVisible(hasPoints)
	self.productsContainer:setVisible(hasPoints)
	self.noPointsOwnedText:setVisible(not hasPoints and self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED)
	self.allPointsBoughtText:setVisible(not hasPoints and self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED)
	if hasPoints then
		self.productsList:reloadData()
	end
	self.detailsBoxBg:setVisible(hasPoints)
	self.detailsContainer:setVisible(hasPoints)
	self.isReloading = false
	self:updateMenuButtons()
end
InGameMenuProductionFrame.SYMBOL_L10N = { TEXT_OWNED = "ui_productionsOwned", TEXT_UNOWNED = "ui_productionsAvailable", TEXT_NO_POINTS = "ui_noProductionPoints", TEXT_ALL_POINTS_OWNED = "ui_allProductionPointsOwned", TEXT_STORAGE = "statistic_storage", TEXT_OUTGOING = "ui_productionsOutgoing", TEXT_DEACTIVATED = "ui_productionsDeactivated" }
InGameMenuProductionFrame.PROFILES = { STATUS_BAR = "fs25_productionDetailsListItemBar", STATUS_BAR_DANGER = "fs25_productionDetailsListItemBarDanger" }
