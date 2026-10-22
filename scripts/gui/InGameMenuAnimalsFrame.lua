InGameMenuAnimalsFrame = {}
local InGameMenuAnimalsFrame_mt = Class(InGameMenuAnimalsFrame, TabbedMenuFrameElement)
InGameMenuAnimalsFrame.UPDATE_INTERVAL = 5000
InGameMenuAnimalsFrame.HORSE_TYPE = "HORSE"
InGameMenuAnimalsFrame.CHICKEN_TYPE = "CHICKEN"
InGameMenuAnimalsFrame.ANIMAL_PRODUCT_FILL_TYPES = { MILK = "MILK", WOOL = "WOOL", EGG = "EGG" }
InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH = 16
function InGameMenuAnimalsFrame.register()
	local inGameMenuAnimalsFrame = InGameMenuAnimalsFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuAnimalsFrame.xml", "AnimalsFrame", inGameMenuAnimalsFrame, true)
end
function InGameMenuAnimalsFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuAnimalsFrame_mt)
	self.sortedHusbandries = {}
	self.selectedClusterCanBeRenamed = false
	self.selectedCluster = nil
	self.selectedHusbandry = nil
	self.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
	self.hasCustomMenuButtons = true
	self.renameButtonInfo = {}
	return self
end
function InGameMenuAnimalsFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuAnimalsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function InGameMenuAnimalsFrame:delete()
	for k, clone in pairs(self.subCategoryDotBox.elements) do
		clone:delete()
		self.subCategoryDotBox.elements[k] = nil
	end
	self.subCategoryDotTemplate:delete()
	InGameMenuAnimalsFrame:superClass().delete(self)
end
function InGameMenuAnimalsFrame:onFrameOpen()
	InGameMenuAnimalsFrame:superClass().onFrameOpen(self)
	g_messageCenter:subscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.onAnimalDataChanged, self)
	g_messageCenter:subscribe(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE, self.updateHusbandries, self)
	g_messageCenter:subscribe(MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE, self.updateHusbandries, self)
	self:updateHusbandries()
	self:updateMenuButtons()
	self.subCategorySelector:setState(self.subCategorySelector:getState(), true)
	if self.list:getItemCount() == 0 then
		FocusManager:setFocus(self.subCategorySelector)
	else
		FocusManager:setFocus(self.list)
	end
end
function InGameMenuAnimalsFrame:onFrameClose()
	g_messageCenter:unsubscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self)
	g_messageCenter:unsubscribe(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE, self)
	g_messageCenter:unsubscribe(MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE, self)
	self.selectedHusbandry = nil
	InGameMenuAnimalsFrame:superClass().onFrameClose(self)
end
function InGameMenuAnimalsFrame:initialize()
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
	self.renameButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_RENAME),
		callback = function()
			self:onButtonRename()
		end,
		profile = "buttonRename",
	}
	self.hotspotButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		callback = function()
			self:onButtonHotspot()
		end,
		profile = "buttonHotspot",
	}
	self.animalWorkerButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_ANIMAL_WORKER),
		callback = function()
			self:onButtonAnimalWorker()
		end,
	}
	self.subCategoryDotTemplate:unlinkElement()
	FocusManager:removeElement(self.subCategoryDotTemplate)
	FocusManager:linkElements(self.list, FocusManager.LEFT, nil)
	FocusManager:linkElements(self.list, FocusManager.RIGHT, nil)
	FocusManager:linkElements(self.list, FocusManager.BOTTOM, nil)
	self.subCategorySelector:setState(1, true)
end
function InGameMenuAnimalsFrame:onAnimalDataChanged()
	self:updateAnimalData()
end
function InGameMenuAnimalsFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
	self:updateAnimalData()
end
function InGameMenuAnimalsFrame:update(dt)
	InGameMenuAnimalsFrame:superClass().update(self, dt)
	if self.selectedHusbandry ~= nil and self.selectedCluster ~= nil then
		self.animalDataUpdateTime = self.animalDataUpdateTime - dt
		if self.animalDataUpdateTime < 0 then
			self:updateAnimalData()
			self:displayCluster(self.selectedCluster, self.selectedHusbandry)
			self.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
		end
	end
end
local sortClusters = function(a, b)
	local animalSystem = g_currentMission.animalSystem
	local aSubType = animalSystem:getSubTypeByIndex(a:getSubTypeIndex())
	local bSubType = animalSystem:getSubTypeByIndex(b:getSubTypeIndex())
	local aName = g_fillTypeManager:getFillTypeTitleByIndex(aSubType.fillTypeIndex)
	local bName = g_fillTypeManager:getFillTypeTitleByIndex(bSubType.fillTypeIndex)
	if aName == bName then
		return b:getAge() < a:getAge()
	else
		return bName < aName
	end
end
local sortHusbandries = function(a, b)
	local aX = nil
	local aZ = nil
	local bX = nil
	local bZ = nil
	local aTypeIndex = a:getAnimalTypeIndex()
	local bTypeIndex = b:getAnimalTypeIndex()
	if aTypeIndex ~= bTypeIndex then
		if aTypeIndex == AnimalType.HORSE then
			return false
		end
		if bTypeIndex == AnimalType.HORSE then
			return true
		end
	end
	local aHotspot = nil
	local bHotspot = nil
	if a.getHotspot ~= nil then
		aHotspot = a:getHotspot(1)
	end
	if b.getHotspot ~= nil then
		bHotspot = b:getHotspot(1)
	end
	aX, aZ = aHotspot:getWorldPosition()
	bX, bZ = bHotspot:getWorldPosition()
	if aX == bX then
		return aZ < bZ
	else
		return aX < bX
	end
end
function InGameMenuAnimalsFrame:updateHusbandries()
	self.sortedHusbandries = g_currentMission.husbandrySystem:getPlaceablesByFarm(self.playerFarm.farmId)
	table.sort(self.sortedHusbandries, sortHusbandries)
	local husbandryNames = {}
	for i, dot in pairs(self.subCategoryDotBox.elements) do
		dot:delete()
		self.subCategoryDotBox.elements[i] = nil
	end
	for index, husbandry in ipairs(self.sortedHusbandries) do
		local clusters = {}
		for _, cluster in ipairs(husbandry:getClusters()) do
			table.insert(clusters, cluster)
		end
		table.sort(clusters, sortClusters)
		husbandry.sortedClusters = clusters
		table.insert(husbandryNames, husbandry:getName())
		local dot = self.subCategoryDotTemplate:clone(self.subCategoryDotBox)
		function dot.getIsSelected()
			return self.subCategorySelector:getState() == index
		end
	end
	self:updateAnimalData()
	self.subCategorySelector:setTexts(husbandryNames)
	self.subCategoryDotBox:invalidateLayout()
	self.subCategoryDotBox:setVisible(1 < #husbandryNames)
end
function InGameMenuAnimalsFrame:updateAnimalData()
	self:reloadList()
end
function InGameMenuAnimalsFrame:setStatusBarValue(statusBarElement, value, invertedBar, disabled)
	local testValue = value
	if invertedBar then
		testValue = 1 - value
	end
	if InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM < testValue then
		if testValue <= InGameMenuAnimalsFrame.STATUS_BAR_HIGH then
			statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.ORANGE)
		elseif InGameMenuAnimalsFrame.STATUS_BAR_HIGH < testValue then
			statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.RED)
		else
			statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.GREEN)
		end
	end
	local fullWidth = statusBarElement.parent.size[1] - statusBarElement.margin[1] * 2
	local minSize = 0
	if statusBarElement.startSize ~= nil then
		minSize = statusBarElement.startSize[1] + statusBarElement.endSize[1]
	end
	statusBarElement:setSize(math.max(minSize, fullWidth * math.min(1, value)), nil)
	disabled = Utils.getNoNil(disabled, false)
	statusBarElement:setDisabled(disabled)
end
function InGameMenuAnimalsFrame:updateHusbandryDisplay(husbandry)
	self.husbandryBox:setVisible(husbandry ~= nil)
	if husbandry == nil then
		return
	else
		self.husbandryIcon:setImageFilename(husbandry.storeItem.imageFilename)
		local infos = husbandry:getConditionInfos()
		for index, row in ipairs(self.conditionRow) do
			local info = infos[index]
			row:setVisible(info ~= nil)
			if info == nil then
				continue
			end
			local valueText = info.valueText or g_i18n:formatVolume(info.value, 0, info.customUnitText)
			self.conditionLabel[index]:setText(info.title)
			self.conditionValue[index]:setText(valueText)
			self:setStatusBarValue(self.conditionStatusBar[index], info.ratio, info.invertedBar, info.disabled)
		end
		local foodInfos = husbandry:getFoodInfos()
		local totalCapacity = 0
		local totalValue = 0
		for index, row in ipairs(self.foodRow) do
			local info = foodInfos[index]
			row:setVisible(info ~= nil)
			if info == nil then
				continue
			end
			local valueText = g_i18n:formatVolume(info.value, 0)
			if not info.ignoreCapacity then
				totalCapacity = math.max(info.capacity, totalCapacity)
				totalValue = totalValue + info.value
			end
			self.foodLabel[index]:setText(info.title)
			self.foodValue[index]:setText(valueText)
			self:setStatusBarValue(self.foodStatusBar[index], info.ratio, info.invertedBar, info.disabled)
		end
		local totalValueText = g_i18n:formatVolume(totalValue, 0)
		local totalRatio = 0
		if 0 < totalCapacity then
			totalRatio = totalValue / totalCapacity
		end
		self.foodRowTotalValue:setText(totalValueText)
		self:setStatusBarValue(self.foodRowTotalStatusBar, totalRatio, false)
		self.requirementsLayout:invalidateLayout()
		self.foodHeader:setText(string.format("%s (%s)", g_i18n:getText("ui_silos_totalCapacity"), g_i18n:getText("animals_foodMixEffectiveness")))
	end
end
function InGameMenuAnimalsFrame:displayCluster(cluster, husbandry)
	if cluster == nil or husbandry == nil then
		return
	end
	local subTypeIndex = cluster:getSubTypeIndex()
	local age = cluster:getAge()
	local visual = cluster:getVisual()
	if visual ~= nil then
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
		local name = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
		if cluster.getName ~= nil then
			name = cluster:getName()
		end
		self.animalDetailTypeNameText:setText(name)
		self.animalDetailTypeImage:setImageFilename(visual.store.imageFilename)
		local ageText = g_i18n:formatNumMonth(age)
		self.animalAgeText:setText(ageText)
		local infos = husbandry:getAnimalInfos(cluster)
		for index, row in ipairs(self.infoRow) do
			local info = infos[index]
			row:setVisible(info ~= nil)
			if info == nil then
				continue
			end
			local valueText = info.valueText or g_i18n:formatVolume(info.value, 0, info.customUnitText)
			self.infoLabel[index]:setText(info.title)
			self.infoValue[index]:setText(valueText)
			self:setStatusBarValue(self.infoStatusBar[index], info.ratio, info.invertedBar, info.disabled)
		end
		local animalDescriptionText = husbandry:getAnimalDescription(cluster)
		self.detailDescriptionText:setText(animalDescriptionText)
	end
end
function InGameMenuAnimalsFrame:updateMenuButtons()
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if self.selectedHusbandry ~= nil then
		local hotspot = nil
		if self.selectedHusbandry.getHotspot ~= nil then
			hotspot = self.selectedHusbandry:getHotspot(1)
		end
		if hotspot ~= nil then
			if hotspot == g_currentMission.currentMapTargetHotspot then
				self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.REMOVE_MARKER)
			else
				self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.SET_MARKER)
			end
			table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
		end
	end
	if self.selectedClusterCanBeRenamed and Platform.gameplay.canRenameAnimals then
		table.insert(self.menuButtonInfo, self.renameButtonInfo)
	end
	if self:getSelectedAnimalWorkerHusbandry() ~= nil then
		table.insert(self.menuButtonInfo, self.animalWorkerButtonInfo)
	end
	self:setMenuButtonInfoDirty()
end
function InGameMenuAnimalsFrame:getSelectedAnimalWorkerHusbandry()
	local husbandry = self.selectedHusbandry
	if husbandry == nil or husbandry.getAnimalWorkerAvailableTasks == nil then
		return nil
	end
	if g_localPlayer == nil or husbandry:getOwnerFarmId() ~= g_localPlayer.farmId then
		return nil
	end
	if not g_currentMission:getHasPlayerPermission(Farm.PERMISSION.HIRE_ASSISTANT) then
		return nil
	elseif #husbandry:getAnimalWorkerAvailableTasks() ~= 0 then
		return husbandry
	else
		return nil
	end
end
function InGameMenuAnimalsFrame:onButtonAnimalWorker()
	local husbandry = self:getSelectedAnimalWorkerHusbandry()
	if husbandry == nil then
		return
	else
		AnimalWorkerDialog.show(husbandry, self.onAnimalWorkerStateSelected, self.onAnimalWorkerPerform, self)
	end
end
function InGameMenuAnimalsFrame:onAnimalWorkerStateSelected(husbandry, task, enabled)
	if g_server ~= nil then
		local applied = husbandry:applyAnimalWorkerStateFromEvent(task, enabled)
		g_server:broadcastEvent(PlaceableHusbandryAnimalWorkerStateEvent.newServerToClient(husbandry, task, applied))
	else
		g_client:getServerConnection():sendEvent(PlaceableHusbandryAnimalWorkerStateEvent.newClientToServer(husbandry, task, enabled))
	end
	self:updateMenuButtons()
end
function InGameMenuAnimalsFrame:onAnimalWorkerPerform(husbandry, task)
	if g_server == nil then
		g_client:getServerConnection():sendEvent(PlaceableHusbandryAnimalWorkerPerformEvent.new(husbandry, task))
		return nil, nil
	else
		local numHandled, cost = husbandry:performAnimalWorkerTask(task)
		return numHandled, cost
	end
end
function InGameMenuAnimalsFrame:renameSelectedAnimal(newName, hasConfirmed)
	if hasConfirmed and (self.selectedClusterCanBeRenamed and Platform.gameplay.canRenameAnimals) then
		self.selectedHusbandry:renameAnimal(self.selectedCluster.id, newName)
	end
end
function InGameMenuAnimalsFrame:getFoodDescription(animalTypeIndex)
	local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex)
	local consumptionType = animalFood.consumptionType
	local foodDescription = nil
	if consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL then
		foodDescription = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_PARALLEL)
		return foodDescription
	else
		foodDescription = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_SERIAL)
		return foodDescription
	end
end
function InGameMenuAnimalsFrame:reloadList()
	local selectorState = self.subCategorySelector:getState()
	local husbandry = self.sortedHusbandries[selectorState]
	self.husbandrySubTypes = {}
	self.subTypeIndexToClusters = {}
	if husbandry ~= nil then
		for index, cluster in ipairs(husbandry.sortedClusters) do
			local subTypeIndex = cluster:getSubTypeIndex()
			table.addElement(self.husbandrySubTypes, subTypeIndex)
			if self.subTypeIndexToClusters[subTypeIndex] == nil then
				self.subTypeIndexToClusters[subTypeIndex] = {}
			end
			table.insert(self.subTypeIndexToClusters[subTypeIndex], cluster)
		end
	end
	self.detailsBox:setVisible(husbandry ~= nil)
	self.noHusbandriesText:setVisible(false)
	self:updateHusbandryDisplay(husbandry)
	self.list:reloadData()
	local hasAnimals = 0 < #self.husbandrySubTypes
	self.animalBox:setVisible(hasAnimals)
	self.detailDescriptionText:setVisible(hasAnimals)
	self.noAnimalsText:setVisible(false)
end
function InGameMenuAnimalsFrame:getNumberOfSections(list)
	return #self.husbandrySubTypes
end
function InGameMenuAnimalsFrame:getTitleForSectionHeader(list, section)
	local subTypeIndex = self.husbandrySubTypes[section]
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
	local subTypeName = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
	return subTypeName
end
function InGameMenuAnimalsFrame:getNumberOfItemsInSection(list, section)
	local subTypeIndex = self.husbandrySubTypes[section]
	local clusters = self.subTypeIndexToClusters[subTypeIndex]
	return #clusters
end
function InGameMenuAnimalsFrame:populateCellForItemInSection(list, section, index, cell)
	local subTypeIndex = self.husbandrySubTypes[section]
	local clusters = self.subTypeIndexToClusters[subTypeIndex]
	local cluster = clusters[index]
	local age = cluster:getAge()
	local visual = cluster:getVisual()
	if visual ~= nil then
		local name = nil
		if cluster.getName ~= nil then
			name = cluster:getName()
		else
			name = g_i18n:formatNumMonth(age)
		end
		local price = cluster:getSellPrice()
		local priceText = g_i18n:formatMoney(price, 0, true, true)
		cell:getAttribute("priceValue"):setText(priceText)
		cell:getAttribute("count"):setText(cluster ~= nil and "x" .. cluster.numAnimals or "")
		cell:getAttribute("count"):setVisible(1 < cluster:getMaxNumAnimals())
		cell:getAttribute("name"):setText(name)
		cell:getAttribute("typeIcon"):setImageFilename(visual.store.imageFilename)
	end
end
function InGameMenuAnimalsFrame:onHusbandryChanged(index)
	self.selectedCluster = nil
	self:updateAnimalData()
	local husbandry = self.sortedHusbandries[index]
	if husbandry == nil then
		return
	else
		self.selectedHusbandry = husbandry
		self:updateMenuButtons()
		self.list:setSelectedIndex(1)
	end
end
function InGameMenuAnimalsFrame:onButtonRename()
	if not Platform.gameplay.canRenameAnimals then
		return
	else
		local promptText = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.PROMPT_RENAME)
		local imePromptText = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.IME_PROMPT_RENAME)
		local confirmText = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_CONFIRM)
		TextInputDialog.show(self.renameSelectedAnimal, self, self.selectedCluster:getName(), promptText, imePromptText, InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH, confirmText, nil, nil, true)
	end
end
function InGameMenuAnimalsFrame:onButtonHotspot()
	local husbandry = self.selectedHusbandry
	local hotspot = nil
	if self.selectedHusbandry.getHotspot ~= nil then
		hotspot = self.selectedHusbandry:getHotspot(1)
	end
	if husbandry and hotspot ~= nil then
		if hotspot == g_currentMission.currentMapTargetHotspot then
			g_currentMission:setMapTargetHotspot()
		else
			g_currentMission:setMapTargetHotspot(hotspot)
		end
		self:updateMenuButtons()
	end
end
function InGameMenuAnimalsFrame:onButtonInfo()
	InfoDialog.show(self.detailDescriptionText.text)
end
function InGameMenuAnimalsFrame:onListSelectionChanged(list, section, index)
	if g_gui.currentlyReloading == false then
		local subTypeIndex = self.husbandrySubTypes[section]
		local clusters = self.subTypeIndexToClusters[subTypeIndex]
		local cluster = clusters[index]
		local husbandry = self.sortedHusbandries[self.subCategorySelector:getState()]
		local canBeRenamed = cluster.getName ~= nil and cluster.setName ~= nil
		self.selectedClusterCanBeRenamed = canBeRenamed
		self.selectedCluster = cluster
		self:displayCluster(self.selectedCluster, husbandry)
		self.livestockAttributesLayout:invalidateLayout()
		self:updateMenuButtons()
	end
end
InGameMenuAnimalsFrame.FILL_TYPE_SEPARATOR = " / "
InGameMenuAnimalsFrame.L10N_SYMBOL = { HORSE_FITNESS = "ui_horseFitness", CLEANLINESS = "statistic_cleanliness", WATER = "statistic_water", STRAW = "statistic_strawStorage", BUTTON_ANIMAL_WORKER = "ui_animalWorker_manage", BUTTON_RENAME = "button_rename", BUTTON_CONFIRM = "button_confirm", BUTTON_HOTSPOT = "button_showOnMap", SET_MARKER = "action_tag", REMOVE_MARKER = "action_untag", PROMPT_RENAME = "ui_enterName", IME_PROMPT_RENAME = "ui_name", FOOD_MIX_QUANITITY = "animals_foodMixQuantity", FOOD_DESCRIPTION_PARALLEL = "animals_foodMixDescriptionParallel", FOOD_DESCRIPTION_SERIAL = "animals_foodMixDescriptionSerial" }
InGameMenuAnimalsFrame.STATUS_BAR_HIGH = 0.66
InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM = 0.33
InGameMenuAnimalsFrame.COLOR = { GREEN = { 0.3763, 0.6038, 0.0782, 1 }, ORANGE = { 0.8, 0.4, 0, 1 }, RED = { 0.8069, 0.0097, 0.0097, 1 } }
