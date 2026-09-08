-- Local values: InGameMenuAnimalsFrame_mt, sortClusters, sortHusbandries
InGameMenuAnimalsFrame = {}
local InGameMenuAnimalsFrame_mt = Class(InGameMenuAnimalsFrame, TabbedMenuFrameElement)
InGameMenuAnimalsFrame.UPDATE_INTERVAL = 5000
InGameMenuAnimalsFrame.HORSE_TYPE = "HORSE"
InGameMenuAnimalsFrame.CHICKEN_TYPE = "CHICKEN"
InGameMenuAnimalsFrame.ANIMAL_PRODUCT_FILL_TYPES = {
	["MILK"] = "MILK",
	["WOOL"] = "WOOL",
	["EGG"] = "EGG"
}
InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH = 16
function InGameMenuAnimalsFrame.register()
	local v2_ = InGameMenuAnimalsFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuAnimalsFrame.xml", "AnimalsFrame", v2_, true)
end

-- Upvalues: InGameMenuAnimalsFrame_mt
-- Local values: self
function InGameMenuAnimalsFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuAnimalsFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuAnimalsFrame_mt)
	v5_.sortedHusbandries = {}
	v5_.selectedClusterIsHorse = false
	v5_.selectedCluster = nil
	v5_.selectedHusbandry = nil
	v5_.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
	v5_.hasCustomMenuButtons = true
	v5_.renameButtonInfo = {}
	return v5_
end

-- Local values: newGui
function InGameMenuAnimalsFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuAnimalsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

-- Local values: k, clone
function InGameMenuAnimalsFrame:delete()
	for v10_, v11_ in pairs(self.subCategoryDotBox.elements) do
		v11_:delete()
		self.subCategoryDotBox.elements[v10_] = nil
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
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}
	self.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = self.onPageNext
	}
	self.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = self.onPagePrevious
	}
	self.renameButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_RENAME),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonRename()
		end,
		["profile"] = "buttonRename"
	}
	self.hotspotButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonHotspot()
		end,
		["profile"] = "buttonHotspot"
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
local function v_u_27_(p20_, p21_)
	local v22_ = g_currentMission.animalSystem
	local v23_ = v22_:getSubTypeByIndex(p20_:getSubTypeIndex())
	local v24_ = v22_:getSubTypeByIndex(p21_:getSubTypeIndex())
	local v25_ = g_fillTypeManager:getFillTypeTitleByIndex(v23_.fillTypeIndex)
	local v26_ = g_fillTypeManager:getFillTypeTitleByIndex(v24_.fillTypeIndex)
	if v25_ == v26_ then
		return p20_:getAge() > p21_:getAge()
	else
		return v26_ < v25_
	end
end
local function v_u_38_(p28_, p29_)
	local v30_ = p28_:getAnimalTypeIndex()
	local v31_ = p29_:getAnimalTypeIndex()
	if v30_ ~= v31_ then
		if v30_ == AnimalType.HORSE then
			return false
		end
		if v31_ == AnimalType.HORSE then
			return true
		end
	end
	local v32_ = nil
	local v33_
	if p28_.getHotspot == nil then
		v33_ = nil
	else
		v33_ = p28_:getHotspot(1)
	end
	if p29_.getHotspot ~= nil then
		v32_ = p29_:getHotspot(1)
	end
	local v34_, v35_ = v33_:getWorldPosition()
	local v36_, v37_ = v32_:getWorldPosition()
	if v34_ == v36_ then
		return v35_ < v37_
	else
		return v34_ < v36_
	end
end

-- Upvalues: sortHusbandries, sortClusters
-- Local values: husbandryNames, i, dot, index, husbandry, clusters, _, cluster, dot
function InGameMenuAnimalsFrame:updateHusbandries()
	-- upvalues: (copy) v_u_38_, (copy) v_u_27_
	self.sortedHusbandries = g_currentMission.husbandrySystem:getPlaceablesByFarm(self.playerFarm.farmId)
	table.sort(self.sortedHusbandries, v_u_38_)
	local v40_ = {}
	for v41_, v42_ in pairs(self.subCategoryDotBox.elements) do
		v42_:delete()
		self.subCategoryDotBox.elements[v41_] = nil
	end
	for v_u_43_, v44_ in ipairs(self.sortedHusbandries) do
		local v45_ = {}
		for _, v46_ in ipairs(v44_:getClusters()) do
			table.insert(v45_, v46_)
		end
		table.sort(v45_, v_u_27_)
		v44_.sortedClusters = v45_
		table.insert(v40_, v44_:getName())
		self.subCategoryDotTemplate:clone(self.subCategoryDotBox).getIsSelected = function()
			-- upvalues: (copy) self, (copy) v_u_43_
			return self.subCategorySelector:getState() == v_u_43_
		end
	end
	self:updateAnimalData()
	self.subCategorySelector:setTexts(v40_)
	self.subCategoryDotBox:invalidateLayout()
	self.subCategoryDotBox:setVisible(#v40_ > 1)
end

function InGameMenuAnimalsFrame:updateAnimalData()
	self:reloadList()
end

-- Local values: testValue, fullWidth, minSize
function InGameMenuAnimalsFrame:setStatusBarValue(statusBarElement, value, invertedBar, disabled)
	local v52_
	if invertedBar then
		v52_ = 1 - value
	else
		v52_ = value
	end
	if InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM < v52_ and v52_ <= InGameMenuAnimalsFrame.STATUS_BAR_HIGH then
		statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.ORANGE)
	elseif InGameMenuAnimalsFrame.STATUS_BAR_HIGH < v52_ then
		statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.RED)
	else
		statusBarElement:setImageColor(InGameMenuAnimalsFrame.COLOR.GREEN)
	end
	local v53_ = statusBarElement.parent.size[1] - statusBarElement.margin[1] * 2
	local v54_ = statusBarElement.startSize == nil and 0 or statusBarElement.startSize[1] + statusBarElement.endSize[1]
	local v55_ = v53_ * math.min(1, value)
	statusBarElement:setSize(math.max(v54_, v55_), nil)
	statusBarElement:setDisabled((Utils.getNoNil(disabled, false)))
end

-- Local values: infos, index, row, info, valueText, foodInfos, totalCapacity, totalValue, index, row, info, valueText, totalValueText, totalRatio
function InGameMenuAnimalsFrame:updateHusbandryDisplay(husbandry)
	self.husbandryBox:setVisible(husbandry ~= nil)
	if husbandry ~= nil then
		self.husbandryIcon:setImageFilename(husbandry.storeItem.imageFilename)
		local v58_ = husbandry:getConditionInfos()
		for v59_, v60_ in ipairs(self.conditionRow) do
			local v61_ = v58_[v59_]
			v60_:setVisible(v61_ ~= nil)
			if v61_ ~= nil then
				local v62_ = v61_.valueText or g_i18n:formatVolume(v61_.value, 0, v61_.customUnitText)
				self.conditionLabel[v59_]:setText(v61_.title)
				self.conditionValue[v59_]:setText(v62_)
				self:setStatusBarValue(self.conditionStatusBar[v59_], v61_.ratio, v61_.invertedBar, v61_.disabled)
			end
		end
		local v63_ = husbandry:getFoodInfos()
		local v64_ = 0
		local v65_ = 0
		for v66_, v67_ in ipairs(self.foodRow) do
			local v68_ = v63_[v66_]
			v67_:setVisible(v68_ ~= nil)
			if v68_ ~= nil then
				local v69_ = g_i18n:formatVolume(v68_.value, 0)
				if not v68_.ignoreCapacity then
					local v70_ = v68_.capacity
					v64_ = math.max(v70_, v64_)
					v65_ = v65_ + v68_.value
				end
				self.foodLabel[v66_]:setText(v68_.title)
				self.foodValue[v66_]:setText(v69_)
				self:setStatusBarValue(self.foodStatusBar[v66_], v68_.ratio, v68_.invertedBar, v68_.disabled)
			end
		end
		local v71_ = g_i18n:formatVolume(v65_, 0)
		local v72_ = v64_ <= 0 and 0 or v65_ / v64_
		self.foodRowTotalValue:setText(v71_)
		self:setStatusBarValue(self.foodRowTotalStatusBar, v72_, false)
		self.requirementsLayout:invalidateLayout()
		self.foodHeader:setText(string.format("%s (%s)", g_i18n:getText("ui_silos_totalCapacity"), g_i18n:getText("animals_foodMixEffectiveness")))
	end
end

-- Local values: subTypeIndex, age, visual, subType, name, ageText, infos, index, row, info, valueText, animalDescriptionText
function InGameMenuAnimalsFrame:displayCluster(cluster, husbandry)
	if cluster ~= nil and husbandry ~= nil then
		local v76_ = cluster:getSubTypeIndex()
		local v77_ = cluster:getAge()
		local v78_ = g_currentMission.animalSystem:getVisualByAge(v76_, v77_)
		if v78_ ~= nil then
			local v79_ = g_currentMission.animalSystem:getSubTypeByIndex(v76_)
			local v80_ = g_fillTypeManager:getFillTypeTitleByIndex(v79_.fillTypeIndex)
			if cluster.getName ~= nil then
				v80_ = cluster:getName()
			end
			self.animalDetailTypeNameText:setText(v80_)
			self.animalDetailTypeImage:setImageFilename(v78_.store.imageFilename)
			local v81_ = g_i18n:formatNumMonth(v77_)
			self.animalAgeText:setText(v81_)
			local v82_ = husbandry:getAnimalInfos(cluster)
			for v83_, v84_ in ipairs(self.infoRow) do
				local v85_ = v82_[v83_]
				v84_:setVisible(v85_ ~= nil)
				if v85_ ~= nil then
					local v86_ = v85_.valueText or g_i18n:formatVolume(v85_.value, 0, v85_.customUnitText)
					self.infoLabel[v83_]:setText(v85_.title)
					self.infoValue[v83_]:setText(v86_)
					self:setStatusBarValue(self.infoStatusBar[v83_], v85_.ratio, v85_.invertedBar, v85_.disabled)
				end
			end
			local v87_ = husbandry:getAnimalDescription(cluster)
			self.detailDescriptionText:setText(v87_)
		end
	end
end

-- Local values: hotspot
function InGameMenuAnimalsFrame:updateMenuButtons()
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if self.selectedHusbandry ~= nil then
		local v89_
		if self.selectedHusbandry.getHotspot == nil then
			v89_ = nil
		else
			v89_ = self.selectedHusbandry:getHotspot(1)
		end
		if v89_ ~= nil then
			if v89_ == g_currentMission.currentMapTargetHotspot then
				self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.REMOVE_MARKER)
			else
				self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.SET_MARKER)
			end
			local v90_ = self.menuButtonInfo
			local v91_ = self.hotspotButtonInfo
			table.insert(v90_, v91_)
		end
	end
	if self.selectedClusterIsHorse and Platform.gameplay.canRenameHorses then
		local v92_ = self.menuButtonInfo
		local v93_ = self.renameButtonInfo
		table.insert(v92_, v93_)
	end
	self:setMenuButtonInfoDirty()
end

function InGameMenuAnimalsFrame:renameCurrentHorse(newName, hasConfirmed)
	if hasConfirmed and (self.selectedClusterIsHorse and Platform.gameplay.canRenameHorses) then
		self.selectedHusbandry:renameAnimal(self.selectedCluster.id, newName)
	end
end

-- Local values: animalFood, consumptionType, foodDescription
function InGameMenuAnimalsFrame:getFoodDescription(animalTypeIndex)
	if g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex).consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL then
		return g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_PARALLEL)
	else
		return g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_SERIAL)
	end
end

-- Local values: selectorState, husbandry, index, cluster, subTypeIndex, hasAnimals
function InGameMenuAnimalsFrame:reloadList()
	local v99_ = self.subCategorySelector:getState()
	local v100_ = self.sortedHusbandries[v99_]
	self.husbandrySubTypes = {}
	self.subTypeIndexToClusters = {}
	if v100_ ~= nil then
		for _, v101_ in ipairs(v100_.sortedClusters) do
			local v102_ = v101_:getSubTypeIndex()
			table.addElement(self.husbandrySubTypes, v102_)
			if self.subTypeIndexToClusters[v102_] == nil then
				self.subTypeIndexToClusters[v102_] = {}
			end
			local v103_ = self.subTypeIndexToClusters[v102_]
			table.insert(v103_, v101_)
		end
	end
	self.detailsBox:setVisible(v100_ ~= nil)
	self.noHusbandriesText:setVisible(v100_ == nil)
	self:updateHusbandryDisplay(v100_)
	self.list:reloadData()
	local v104_ = #self.husbandrySubTypes > 0
	self.animalBox:setVisible(v104_)
	self.detailDescriptionText:setVisible(v104_)
	local v105_ = self.noAnimalsText
	local v106_
	if v100_ == nil then
		v106_ = false
	else
		v106_ = not v104_
	end
	v105_:setVisible(v106_)
end

function InGameMenuAnimalsFrame:getNumberOfSections(list)
	return #self.husbandrySubTypes
end

-- Local values: subTypeIndex, subType, subTypeName
function InGameMenuAnimalsFrame:getTitleForSectionHeader(list, section)
	local v110_ = self.husbandrySubTypes[section]
	local v111_ = g_currentMission.animalSystem:getSubTypeByIndex(v110_)
	return g_fillTypeManager:getFillTypeTitleByIndex(v111_.fillTypeIndex)
end

-- Local values: subTypeIndex, clusters
function InGameMenuAnimalsFrame:getNumberOfItemsInSection(list, section)
	local v114_ = self.husbandrySubTypes[section]
	return #self.subTypeIndexToClusters[v114_]
end

-- Local values: subTypeIndex, clusters, cluster, age, visual, subType, name, price, priceText
function InGameMenuAnimalsFrame:populateCellForItemInSection(list, section, index, cell)
	local v119_ = self.husbandrySubTypes[section]
	local v120_ = self.subTypeIndexToClusters[v119_][index]
	local v121_ = v120_:getAge()
	local v122_ = g_currentMission.animalSystem:getVisualByAge(v119_, v121_)
	local v123_ = g_currentMission.animalSystem:getSubTypeByIndex(v119_)
	if v122_ ~= nil then
		local v124_
		if v120_.getName == nil then
			v124_ = g_i18n:formatNumMonth(v121_)
		else
			v124_ = v120_:getName()
		end
		local v125_ = v120_:getSellPrice()
		local v126_ = g_i18n:formatMoney(v125_, 0, true, true)
		cell:getAttribute("priceValue"):setText(v126_)
		cell:getAttribute("count"):setText(v120_ == nil and "" or ("x" .. v120_.numAnimals or ""))
		cell:getAttribute("count"):setVisible(v123_.typeIndex ~= AnimalType.HORSE)
		cell:getAttribute("name"):setText(v124_)
		cell:getAttribute("typeIcon"):setImageFilename(v122_.store.imageFilename)
	end
end

-- Local values: husbandry
function InGameMenuAnimalsFrame:onHusbandryChanged(index)
	self.selectedCluster = nil
	self:updateAnimalData()
	local v129_ = self.sortedHusbandries[index]
	if v129_ ~= nil then
		self.selectedHusbandry = v129_
		self:updateMenuButtons()
		self.list:setSelectedIndex(1)
	end
end

-- Local values: promptText, imePromptText, confirmText
function InGameMenuAnimalsFrame:onButtonRename()
	if Platform.gameplay.canRenameHorses then
		local v131_ = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.PROMPT_RENAME)
		local v132_ = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.IME_PROMPT_RENAME)
		local v133_ = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_CONFIRM)
		TextInputDialog.show(self.renameCurrentHorse, self, self.selectedCluster:getName(), v131_, v132_, InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH, v133_, nil, nil, true)
	end
end

-- Local values: husbandry, hotspot
function InGameMenuAnimalsFrame:onButtonHotspot()
	local v135_ = self.selectedHusbandry
	local v136_
	if self.selectedHusbandry.getHotspot == nil then
		v136_ = nil
	else
		v136_ = self.selectedHusbandry:getHotspot(1)
	end
	if v135_ and v136_ ~= nil then
		if v136_ == g_currentMission.currentMapTargetHotspot then
			g_currentMission:setMapTargetHotspot()
		else
			g_currentMission:setMapTargetHotspot(v136_)
		end
		self:updateMenuButtons()
	end
end

function InGameMenuAnimalsFrame:onButtonInfo()
	InfoDialog.show(self.detailDescriptionText.text)
end

-- Local values: subTypeIndex, clusters, cluster, husbandry, subType, isHorse
function InGameMenuAnimalsFrame:onListSelectionChanged(list, section, index)
	if g_gui.currentlyReloading == false then
		local v141_ = self.husbandrySubTypes[section]
		local v142_ = self.subTypeIndexToClusters[v141_][index]
		local v143_ = self.sortedHusbandries[self.subCategorySelector:getState()]
		self.selectedClusterIsHorse = g_currentMission.animalSystem:getSubTypeByIndex(v142_:getSubTypeIndex()).typeIndex == AnimalType.HORSE
		self.selectedCluster = v142_
		self:displayCluster(self.selectedCluster, v143_)
		self.livestockAttributesLayout:invalidateLayout()
		self:updateMenuButtons()
	end
end
InGameMenuAnimalsFrame.FILL_TYPE_SEPARATOR = " / "
InGameMenuAnimalsFrame.L10N_SYMBOL = {
	["HORSE_FITNESS"] = "ui_horseFitness",
	["CLEANLINESS"] = "statistic_cleanliness",
	["WATER"] = "statistic_water",
	["STRAW"] = "statistic_strawStorage",
	["BUTTON_RENAME"] = "button_rename",
	["BUTTON_CONFIRM"] = "button_confirm",
	["BUTTON_HOTSPOT"] = "button_showOnMap",
	["SET_MARKER"] = "action_tag",
	["REMOVE_MARKER"] = "action_untag",
	["PROMPT_RENAME"] = "ui_enterHorseName",
	["IME_PROMPT_RENAME"] = "ui_horseName",
	["FOOD_MIX_QUANITITY"] = "animals_foodMixQuantity",
	["FOOD_DESCRIPTION_PARALLEL"] = "animals_foodMixDescriptionParallel",
	["FOOD_DESCRIPTION_SERIAL"] = "animals_foodMixDescriptionSerial"
}
InGameMenuAnimalsFrame.STATUS_BAR_HIGH = 0.66
InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM = 0.33
InGameMenuAnimalsFrame.COLOR = {
	["GREEN"] = {
		0.3763,
		0.6038,
		0.0782,
		1
	},
	["ORANGE"] = {
		0.8,
		0.4,
		0,
		1
	},
	["RED"] = {
		0.8069,
		0.0097,
		0.0097,
		1
	}
}
