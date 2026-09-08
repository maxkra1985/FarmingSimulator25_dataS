-- Local values: AnimalScreen_mt
AnimalScreen = {}
AnimalScreen.TRANSPORTATION_FEE = 200
AnimalScreen.SELECTION_SOURCE = 1
AnimalScreen.SELECTION_TARGET = 2
AnimalScreen.SELECTION_AMOUNT = 3
AnimalScreen.INPUT_CONTEXT = "AnimalScreen"
local AnimalScreen_mt = Class(AnimalScreen, ScreenElement)

function AnimalScreen.show(husbandry, loadingVehicle, isDealer)
	g_animalScreen:setController(husbandry, loadingVehicle, isDealer)
	g_gui:showGui("AnimalScreen")
end
function AnimalScreen.register()
	local v5_ = AnimalScreen.new()
	g_gui:loadGui("dataS/gui/AnimalScreen.xml", "AnimalScreen", v5_)
	return v5_
end

-- Upvalues: AnimalScreen_mt
-- Local values: self
function AnimalScreen.new(custom_mt)
	-- upvalues: (copy) AnimalScreen_mt
	local v7_ = ScreenElement.new(nil, custom_mt or AnimalScreen_mt)
	v7_.isBuyMode = true
	v7_.isSourceSelected = true
	v7_.isOpen = false
	v7_.lastBalance = 0
	v7_.numAnimals = 0
	v7_.selectionState = nil
	v7_.sourceSelectorStateToAnimalType = {}
	return v7_
end

-- Local values: newGui, controller
function AnimalScreen.createFromExistingGui(gui, guiName)
	local v10_ = AnimalScreen.new()
	local v11_ = gui:getController()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v10_)
	v10_:setController(v11_.husbandry, v11_.loadingVehicle, gui.isDealer)
	g_animalScreen = v10_
	return v10_
end

-- Local values: controller
function AnimalScreen:setController(husbandry, loadingVehicle, isDealer)
	self.isDealer = isDealer
	local v16_
	if husbandry == nil then
		if loadingVehicle == nil then
			v16_ = AnimalScreenDealer.new()
		elseif isDealer then
			v16_ = AnimalScreenDealerTrailer.new(loadingVehicle)
		else
			v16_ = AnimalScreenTrailer.new(loadingVehicle)
		end
	elseif loadingVehicle == nil then
		v16_ = AnimalScreenDealerFarm.new(husbandry)
	else
		v16_ = AnimalScreenTrailerFarm.new(husbandry, loadingVehicle)
	end
	v16_:init()
	self.controller = v16_
	self.controller:setAnimalsChangedCallback(self.onAnimalsChanged, self)
	self.controller:setActionTypeCallback(self.onActionTypeChanged, self)
	self.controller:setSourceActionFinishedCallback(self.onSourceActionFinished, self)
	self.controller:setTargetActionFinishedCallback(self.onTargetActionFinished, self)
	self.controller:setErrorCallback(self.onError, self)
	self.sourceList:reloadData(true)
end

function AnimalScreen:getController()
	return self.controller
end

function AnimalScreen:onGuiSetupFinished()
	AnimalScreen:superClass().onGuiSetupFinished(self)
	if GS_IS_MOBILE_VERSION then
		self.infoIcon = self.infoIconMobile
		self.infoName = self.infoNameMobile
		self.infoValue = self.infoValueMobile
		self.infoTitle = self.infoTitleMobile
		self.infoDescription = self.infoDescriptionMobile
		self.buttonSelect:delete()
		self.buttonSelect = nil
		self.buttonApply:delete()
		self.buttonApply = nil
		self.numAnimalsElement = nil
	end
	if not Platform.isMobile then
		self.numAnimalsElement:setTexts({ "1" })
	end
	self.sourceDotTemplate:unlinkElement()
	FocusManager:removeElement(self.sourceDotTemplate)
	FocusManager:linkElements(self.sourceList, FocusManager.TOP, self.sourceSelector)
	FocusManager:linkElements(self.sourceList, FocusManager.BOTTOM, nil)
end

-- Local values: k, clone
function AnimalScreen:delete()
	for v20_, v21_ in pairs(self.sourceDotBox.elements) do
		v21_:delete()
		self.sourceDotBox.elements[v20_] = nil
	end
	self.sourceDotTemplate:delete()
	AnimalScreen:superClass().delete(self)
end

function AnimalScreen:onOpen()
	AnimalScreen:superClass().onOpen(self)
	self.isOpen = true
	g_gameStateManager:setGameState(GameState.MENU_ANIMAL_SHOP)
	self:onClickBuyMode(true)
	if self.sourceList:getItemCount() == 0 then
		self:onClickSellMode(true)
		if self.sourceList:getItemCount() == 0 then
			g_gui:changeScreen(nil)
			InfoDialog.show(g_i18n:getText("ui_noAnimalsToSell"))
			return
		end
	end
	self:onMoneyChange()
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
	self:toggleCustomInputContext(true, AnimalScreen.INPUT_CONTEXT)
	self:registerActionEvents()
end

-- Local values: i, dot, animalTypeTexts, index, animalType, dot
function AnimalScreen:initSubcategories()
	for v24_, v25_ in pairs(self.sourceDotBox.elements) do
		v25_:delete()
		self.sourceDotBox.elements[v24_] = nil
	end
	self.sourceSelectorStateToAnimalType = {}
	local v26_ = {}
	for v_u_27_, v28_ in pairs(self.controller:getSourceAnimalTypes(self.isBuyMode)) do
		self.sourceDotTemplate:clone(self.sourceDotBox).getIsSelected = function()
			-- upvalues: (copy) self, (copy) v_u_27_
			return self.sourceSelector:getState() == v_u_27_
		end
		local v29_ = v28_.groupTitle
		table.insert(v26_, v29_)
		self.sourceSelectorStateToAnimalType[v_u_27_] = v28_.typeIndex
	end
	self.sourceSelector:setTexts(v26_)
	self.sourceDotBox:invalidateLayout()
	self.sourceDotBox:setVisible(#v26_ > 1)
end

function AnimalScreen:onClose(element)
	AnimalScreen:superClass().onClose(self)
	self.controller:reset()
	self:removeActionEvents()
	self:toggleCustomInputContext(false, AnimalScreen.INPUT_CONTEXT)
	g_currentMission:resetGameState()
	g_currentMission:showMoneyChange(MoneyType.NEW_ANIMALS_COST)
	g_currentMission:showMoneyChange(MoneyType.SOLD_ANIMALS)
	g_messageCenter:unsubscribeAll(self)
	g_inputBinding:removeActionEventsByTarget(self)
	self.isOpen = false
end

function AnimalScreen:onVehicleLeftTrigger()
	if self.isOpen then
		InfoDialog.show(g_i18n:getText(AnimalScreen.SYMBOL_L10N.ERROR_TRAILER_LEFT), self.onClickOkVehicleLeft, self)
	end
end

function AnimalScreen:onClickOkVehicleLeft()
	self:onClickBack()
end

function AnimalScreen:setSelectionState(state, forceUpdate)
	if state == AnimalScreen.SELECTION_TARGET and #self.targetSelector.texts == 0 then
		return false
	elseif state == AnimalScreen.SELECTION_TARGET and (#self.targetSelector.texts == 1 and not self.targetSlider.needsSlider) then
		if self.selectionState == AnimalScreen.SELECTION_SOURCE then
			self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
		else
			self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
		end
	elseif state == AnimalScreen.SELECTION_AMOUNT and not self.numAnimalsBox:getIsVisible() then
		if #self.targetSelector.texts == 1 and not self.targetSlider.needsSlider then
			self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
		else
			self:setSelectionState(AnimalScreen.SELECTION_TARGET)
		end
	else
		self.sourceBoxBg:setSelected(state == AnimalScreen.SELECTION_SOURCE, true)
		self.sourceBoxArrow:setSelected(state == AnimalScreen.SELECTION_SOURCE, true)
		self.targetBoxBg:setSelected(state == AnimalScreen.SELECTION_TARGET)
		self.numAnimalsBoxBg:setSelected(state == AnimalScreen.SELECTION_AMOUNT)
		self.isAutoUpdatingList = true
		if state == AnimalScreen.SELECTION_SOURCE then
			if self.selectionState ~= state then
				if self.sourceList:getItemCount() > 0 then
					FocusManager:setFocus(self.sourceList)
				else
					FocusManager:setFocus(self.sourceSelector)
				end
			end
		elseif state == AnimalScreen.SELECTION_TARGET then
			if self.targetSlider.needsSlider then
				FocusManager:setFocus(self.targetSlider)
				FocusManager:linkElements(self.targetSlider, FocusManager.RIGHT, self.numAnimalsElement)
				FocusManager:linkElements(self.targetSlider, FocusManager.TOP, self.targetSelector)
				FocusManager:linkElements(self.targetSelector, FocusManager.BOTTOM, self.targetSlider)
				if #self.targetSelector.texts > 1 then
					FocusManager:linkElements(self.targetSlider, FocusManager.LEFT, self.targetSelector)
				elseif self.sourceList:getItemCount() > 0 then
					FocusManager:linkElements(self.targetSlider, FocusManager.LEFT, self.sourceList)
				else
					FocusManager:linkElements(self.targetSlider, FocusManager.TOP, self.sourceSelector)
				end
				if self.sourceList:getItemCount() > 0 then
					FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceList)
				else
					FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceSelector)
				end
			else
				FocusManager:setFocus(self.targetSelector)
				FocusManager:linkElements(self.targetSelector, FocusManager.BOTTOM, self.numAnimalsElement)
				if self.sourceList:getItemCount() > 0 then
					FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceList)
				else
					FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceSelector)
				end
			end
		else
			FocusManager:setFocus(self.numAnimalsElement)
			if self.targetSlider.needsSlider then
				FocusManager:linkElements(self.numAnimalsElement, FocusManager.TOP, self.targetSlider)
				FocusManager:linkElements(self.numAnimalsElement, FocusManager.BOTTOM, self.targetSlider)
			elseif #self.targetSelector.texts > 1 then
				FocusManager:linkElements(self.numAnimalsElement, FocusManager.TOP, self.targetSelector)
				FocusManager:linkElements(self.numAnimalsElement, FocusManager.BOTTOM, self.targetSelector)
			else
				FocusManager:linkElements(self.numAnimalsElement, FocusManager.TOP, self.sourceList)
				FocusManager:linkElements(self.numAnimalsElement, FocusManager.BOTTOM, self.sourceList)
			end
		end
		self.isAutoUpdatingList = false
		self.selectionState = state
		if self.isBuyMode then
			if self.buttonApply == nil then
				if self.buttonBuy ~= nil then
					self.buttonBuy:setText(self.controller:getSourceActionText())
				end
			else
				self.buttonApply:setText(self.controller:getSourceActionText())
			end
		elseif self.buttonApply == nil then
			if self.buttonSell ~= nil then
				self.buttonSell:setText(self.controller:getTargetActionText())
			end
		else
			self.buttonApply:setText(self.controller:getTargetActionText())
		end
		local v35_ = self.noHusbandriesTextBox
		local v36_
		if #self.targetSelector.texts == 0 then
			v36_ = self.isBuyMode
		else
			v36_ = false
		end
		v35_:setVisible(v36_)
		local v37_ = self.targetListEmptyText
		local v38_
		if #self.targetSelector.texts > 0 then
			v38_ = self.targetList:getItemCount() == 0
		else
			v38_ = false
		end
		v37_:setVisible(v38_)
		self.targetIcon:setVisible(#self.targetSelector.texts > 0)
		self.targetSelector:setVisible(#self.targetSelector.texts > 0)
		self.targetText:setVisible(#self.targetSelector.texts > 0)
		local v39_ = self.targetListContainer
		local v40_ = self.isBuyMode
		if v40_ then
			v40_ = self.controller.husbandry == nil and true or self.controller.trailer == nil
		end
		v39_:setVisible(v40_)
		local v41_ = self.buttonBuy
		local v42_
		if state == AnimalScreen.SELECTION_AMOUNT then
			v42_ = self.isBuyMode
		else
			v42_ = false
		end
		v41_:setVisible(v42_)
		local v43_ = self.buttonSell
		local v44_
		if state == AnimalScreen.SELECTION_AMOUNT then
			v44_ = not self.isBuyMode
		else
			v44_ = false
		end
		v43_:setVisible(v44_)
		local v45_ = self.buttonSelect
		local v46_ = state < AnimalScreen.SELECTION_AMOUNT and self.sourceList:getItemCount() > 0 and (self.targetContainer:getIsVisible() or not self.isBuyMode)
		if v46_ then
			v46_ = self.numAnimalsElement:getIsVisible()
		end
		v45_:setVisible(v46_)
		self.buttonsPanel:invalidateLayout()
		return true
	end
end

-- Local values: hasCosts, price, fee, total
function AnimalScreen:updatePrice()
	local v48_, v49_, v50_, v51_ = self:getPrice(self.numAnimalsElement:getState())
	self.infoPrice:setValue(0)
	self.infoFee:setValue(0)
	self.infoTotal:setValue(0)
	self.infoPrice:setFormat(v48_ and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoFee:setFormat(v48_ and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoTotal:setFormat(v48_ and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoPrice:setValue(v48_ and v49_ and v49_ or "-")
	self.infoFee:setValue(v48_ and v50_ and v50_ or "-")
	self.infoTotal:setValue(v48_ and v51_ and v51_ or "-")
end

-- Local values: item, animalTypeIndex, subType, itemName, infos, k, infoTitle, info, infoValue
function AnimalScreen:updateInfoBox(isSourceSelected)
	if not g_gui.currentlyReloading then
		if isSourceSelected == nil then
			local _ = self.isSourceSelected
		end
		local v54_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
		local v55_
		if self.isBuyMode then
			v55_ = self.controller:getSourceItems(v54_, self.isBuyMode)[self.sourceList.selectedIndex]
		else
			v55_ = self.controller:getTargetItems()[self.sourceList.selectedIndex]
		end
		self.infoIcon:setVisible(v55_ ~= nil)
		self.infoName:setVisible(v55_ ~= nil)
		if v55_ ~= nil then
			self.infoIcon:setImageFilename(v55_:getFilename())
			self.infoDescription:setText(v55_:getDescription())
			local v56_ = g_currentMission.animalSystem:getSubTypeByIndex(v55_:getSubTypeIndex())
			local v57_ = g_fillTypeManager:getFillTypeTitleByIndex(v56_.fillTypeIndex)
			self.infoName:setText(v57_)
			local v58_ = v55_:getInfos()
			for v59_, v60_ in ipairs(self.infoTitle) do
				local v61_ = v58_[v59_]
				local v62_ = self.infoValue[v59_]
				v60_:setVisible(v61_ ~= nil)
				v62_:setVisible(v61_ ~= nil)
				if v61_ ~= nil then
					v60_:setText(v58_[v59_].title)
					v62_:setText(v58_[v59_].value)
				end
			end
			if not Platform.isMobile then
				self:updatePrice()
			end
		end
	end
end

-- Local values: hasCosts, price, fee, total, animalIndex, animalTypeIndex
function AnimalScreen:getPrice(numAnimals)
	local v65_ = self.sourceList.selectedIndex
	local v66_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
	if self.isBuyMode then
		local v67_, v68_, v69_, v70_ = self.controller:getSourcePrice(v66_, v65_, numAnimals)
		return v67_, v68_, v69_, v70_
	else
		local v71_, v72_, v73_, v74_ = self.controller:getTargetPrice(v66_, v65_, numAnimals)
		return v71_, v72_, v73_, v74_
	end
end

-- Local values: targets, text, targetSelection, _, target, animalType, numAnimalsText, hasSourceItems
function AnimalScreen:updateScreen(blockTargetUpdate)
	self.isAutoUpdatingList = true
	self.sourceList:reloadData(true)
	self.isAutoUpdatingList = false
	local v77_, v78_
	if self.isBuyMode then
		v77_, v78_ = self.controller:getSourceData(self.sourceSelector:getState())
	else
		v77_, v78_ = self.controller:getTargetData(self.sourceSelector:getState())
	end
	self.targetText:setText(v78_)
	self.targetItems = v77_
	local v79_ = {}
	for _, v80_ in pairs(v77_) do
		local v81_ = g_currentMission.animalSystem:getTypeByIndex(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()])
		local v82_ = " (" .. v80_:getNumOfAnimals() .. "/" .. v80_:getMaxNumOfAnimals(v81_) .. ")"
		local v83_ = v80_:getName() .. v82_
		table.insert(v79_, v83_)
	end
	self.targetSelector:setTexts(v79_)
	if blockTargetUpdate ~= true and #v77_ > 0 then
		self.targetSelector:setState(1)
	end
	self:onTargetSelectionChanged(true)
	self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
	local v84_ = self.sourceList:getItemCount() > 0
	self.detailsContainer:setVisible(v84_)
	if v84_ then
		self:updatePrice()
		self:updateInfoBox()
	end
	self.tabBuy:setSelected(self.isBuyMode)
	self.tabSell:setSelected(not self.isBuyMode)
end

-- Local values: infos, index, row, info, valueText
function AnimalScreen:updateConditionDisplay(husbandry)
	if husbandry == nil then
		self.husbandryInfoContainer:setVisible(false)
	else
		self.husbandryInfoContainer:setVisible(true)
		local v87_ = husbandry:getConditionInfos()
		for v88_, v89_ in ipairs(self.conditionRow) do
			local v90_ = v87_[v88_]
			v89_:setVisible(v90_ ~= nil)
			if v90_ ~= nil then
				local v91_ = v90_.valueText or g_i18n:formatVolume(v90_.value, 0, v90_.customUnitText)
				self.conditionLabel[v88_]:setText(v90_.title)
				self.conditionValue[v88_]:setText(v91_)
				self:setStatusBarValue(self.conditionStatusBar[v88_], v90_.ratio, v90_.invertedBar)
			end
		end
	end
end

-- Local values: infos, totalCapacity, totalValue, index, row, info, valueText, totalValueText, totalRatio
function AnimalScreen:updateFoodDisplay(husbandry)
	if husbandry == nil then
		self.husbandryInfoContainer:setVisible(false)
	else
		self.husbandryInfoContainer:setVisible(true)
		local v94_ = husbandry:getFoodInfos()
		local v95_ = 0
		local v96_ = 0
		for v97_, v98_ in ipairs(self.foodRow) do
			local v99_ = v94_[v97_]
			v98_:setVisible(v99_ ~= nil)
			if v99_ ~= nil then
				local v100_ = g_i18n:formatVolume(v99_.value, 0)
				local v101_ = v99_.capacity
				v95_ = math.max(v101_, v95_)
				v96_ = v96_ + v99_.value
				self.foodLabel[v97_]:setText(v99_.title)
				self.foodValue[v97_]:setText(v100_)
				self:setStatusBarValue(self.foodStatusBar[v97_], v99_.ratio, v99_.invertedBar)
			end
		end
		local v102_ = g_i18n:formatVolume(v96_, 0)
		local v103_ = v95_ <= 0 and 0 or v96_ / v95_
		self.foodRowTotalValue:setText(v102_)
		self:setStatusBarValue(self.foodRowTotalStatusBar, v103_, false)
		self.foodHeader:setText(string.format("%s (%s)", g_i18n:getText("ui_silos_totalCapacity"), g_i18n:getText("animals_foodMixEffectiveness")))
	end
end

-- Local values: testValue, fullWidth, minSize
function AnimalScreen:setStatusBarValue(statusBarElement, value, invertedBar, disabled)
	local v108_
	if invertedBar then
		v108_ = 1 - value
	else
		v108_ = value
	end
	if InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM < v108_ and v108_ <= InGameMenuAnimalsFrame.STATUS_BAR_HIGH then
		statusBarElement:setImageColor(AnimalScreen.COLOR.ORANGE)
	elseif InGameMenuAnimalsFrame.STATUS_BAR_HIGH < v108_ then
		statusBarElement:setImageColor(AnimalScreen.COLOR.RED)
	else
		statusBarElement:setImageColor(AnimalScreen.COLOR.GREEN)
	end
	local v109_ = statusBarElement.parent.size[1] - statusBarElement.margin[1] * 2
	local v110_ = statusBarElement.startSize == nil and 0 or statusBarElement.startSize[1] + statusBarElement.endSize[1]
	local v111_ = v109_ * math.min(1, value)
	statusBarElement:setSize(math.max(v110_, v111_), nil)
	statusBarElement:setDisabled((Utils.getNoNil(disabled, false)))
end

-- Local values: farm, moneyText
function AnimalScreen:onMoneyChange()
	if g_localPlayer ~= nil then
		local v113_ = g_farmManager:getFarmById(g_localPlayer.farmId)
		if v113_.money <= -1 then
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
		else
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
		end
		local v114_ = g_i18n:formatMoney(v113_.money, 0, true, false)
		self.currentBalanceText:setText(v114_)
		if self.shopMoneyBox ~= nil then
			self.shopMoneyBox:invalidateLayout()
			self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
		end
	end
end

function AnimalScreen:onAnimalsChanged()
	self:initSubcategories()
	self:updateScreen(true)
	if self.sourceSelector:getState() == 0 or not self.isBuyMode and (self.sourceSelector:getState() == 1 and self.sourceList:getItemCount() == 0) then
		self:onPageNext()
	end
end

function AnimalScreen:onFocusTargetSelection()
	if self.selectionState ~= AnimalScreen.SELECTION_TARGET then
		self:setSelectionState(AnimalScreen.SELECTION_TARGET)
	end
end

-- Local values: sourceSelectorState, targetSelectorState, animalTypeIndex, husbandryId, trailerStoreItem
function AnimalScreen:onTargetSelectionChanged(blockSelectionStateUpdate)
	if not blockSelectionStateUpdate and (self.isBuyMode and self.selectionState ~= AnimalScreen.SELECTION_TARGET) then
		self:setSelectionState(AnimalScreen.SELECTION_TARGET)
	end
	local v119_ = self.sourceSelector:getState()
	local v120_ = self.targetSelector:getState()
	local v121_ = self.sourceSelectorStateToAnimalType[v119_]
	if self.isBuyMode or not (self.isDealer and v119_) then
		v119_ = v120_
	end
	self.controller:setCurrentHusbandry(v121_, v119_, self.isBuyMode)
	if self.isBuyMode then
		self.husbandryInfoContainer:setVisible(false)
	else
		self:updateFoodDisplay(self.controller.husbandry)
		self:updateConditionDisplay(self.controller.husbandry)
		self.husbandryRequirementsLayout:invalidateLayout()
	end
	if v120_ > 0 then
		if self.targetItems[v120_].storeItem == nil then
			local v122_ = g_storeManager:getItemByXMLFilename(self.targetItems[v120_].xmlFile.filename)
			if v122_ ~= nil then
				self.targetIcon:setImageFilename(v122_.imageFilename)
			end
		else
			self.targetIcon:setImageFilename(self.targetItems[v120_].storeItem.imageFilename)
		end
	end
	if self.isBuyMode then
		self.targetList:reloadData()
	else
		self.sourceList:reloadData(true)
	end
	self:setMaxNumAnimals(v121_)
	FocusManager:linkElements(self.targetSlider, FocusManager.RIGHT, self.numAnimalsElement)
	if #self.targetSelector.texts > 1 then
		FocusManager:linkElements(self.targetSlider, FocusManager.LEFT, self.targetSelector)
	elseif self.sourceList:getItemCount() > 0 then
		FocusManager:linkElements(self.targetSlider, FocusManager.LEFT, self.sourceList)
	else
		FocusManager:linkElements(self.targetSlider, FocusManager.TOP, self.sourceSelector)
	end
	if self.targetSlider.needsSlider then
		FocusManager:linkElements(self.targetSelector, FocusManager.BOTTOM, self.targetSlider)
	else
		FocusManager:linkElements(self.targetSelector, FocusManager.BOTTOM, self.numAnimalsElement)
	end
	if self.sourceList:getItemCount() > 0 then
		FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceList)
	else
		FocusManager:linkElements(self.targetSelector, FocusManager.TOP, self.sourceSelector)
	end
end

-- Local values: maxElements, animalIndex, hasTargetItems, texts, i
function AnimalScreen:setMaxNumAnimals(animalTypeIndex)
	local v125_ = self.controller:getMaxNumAnimals()
	local v126_ = self.sourceList.selectedIndex
	local v127_ = self.isBuyMode or #self.controller:getTargetItems() > 0
	local v128_
	if self.isBuyMode then
		if v127_ then
			local v129_ = self.controller
			local v130_ = math.min(v125_, v129_:getSourceMaxNumAnimals(animalTypeIndex, v126_))
			v128_ = math.max(0, v130_) or 0
		else
			v128_ = 0
		end
	elseif v127_ then
		local v131_ = self.controller
		local v132_ = math.min(v125_, v131_:getTargetMaxNumAnimals(v126_))
		v128_ = math.max(0, v132_) or 0
	else
		v128_ = 0
	end
	local v133_ = {}
	for v134_ = 1, v128_ do
		local v135_ = tostring(v134_)
		table.insert(v133_, v135_)
	end
	self.numAnimalsElement:setTexts(v133_)
	if #v133_ >= 1 then
		self.numAnimalsElement:setState(1)
	end
	self.numAnimalsBox:setVisible(#v133_ >= 1)
	self.infoBox:setVisible(#v133_ >= 1)
	if v127_ then
		self:updatePrice()
	end
	local v136_ = self.buttonSelect
	local v137_ = self.sourceList:getItemCount() > 0 and (self.targetContainer:getIsVisible() or not self.isBuyMode)
	if v137_ then
		v137_ = #v133_ >= 1
	end
	v136_:setVisible(v137_)
	self.buttonsPanel:invalidateLayout()
end

function AnimalScreen:onActionTypeChanged(actionType, text)
	if text == nil then
		MessageDialog.hide()
	else
		MessageDialog.show(text)
	end
end

-- Local values: msgType
function AnimalScreen:onSourceActionFinished(isWarning, text)
	local v142_ = DialogElement.TYPE_INFO
	if isWarning then
		v142_ = DialogElement.TYPE_WARNING
	end
	InfoDialog.show(text, self.updateScreen, self, v142_, nil, nil, true)
end

-- Local values: msgType
function AnimalScreen:onTargetActionFinished(isWarning, text)
	local v146_ = DialogElement.TYPE_INFO
	if isWarning then
		v146_ = DialogElement.TYPE_WARNING
	end
	InfoDialog.show(text, self.updateScreen, self, v146_, nil, nil, true)
end

function AnimalScreen:onError(text)
	InfoDialog.show(text, nil, nil, DialogElement.TYPE_WARNING)
end

function AnimalScreen:onClickBack()
	AnimalScreen:superClass().onClickBack(self)
	if Platform.isMobile or self.selectionState <= AnimalScreen.SELECTION_SOURCE then
		self:changeScreen(nil)
		return
	elseif self.isBuyMode then
		self:setSelectionState(self.selectionState - 1)
	else
		self:setSelectionState(self.selectionState - 2)
	end
end

function AnimalScreen:onClickSelect()
	if self.selectionState < AnimalScreen.SELECTION_AMOUNT then
		if self.isBuyMode then
			self:setSelectionState(self.selectionState + 1)
		else
			self:setSelectionState(self.selectionState + 2)
		end
	end
	return true
end

function AnimalScreen:onAnimalsTradedCallback(buying, tradeAccepted, animalTypeIndex, animalIndex, numAnimals)
	self.numAnimals = numAnimals
	if not tradeAccepted then
		return false
	end
	if buying then
		YesNoDialog.show(self.onYesNoSource, self, self.controller:getApplySourceConfirmationText(animalTypeIndex, animalIndex, numAnimals))
	else
		YesNoDialog.show(self.onYesNoTarget, self, self.controller:getApplyTargetConfirmationText(animalTypeIndex, animalIndex, numAnimals))
	end
	return true
end

function AnimalScreen:onClickBuyMode(isAutoUpdatingList, isRecursion)
	self.isBuyMode = true
	self.targetSelector.leftButtonElement:setVisible(true)
	self.targetSelector.rightButtonElement:setVisible(true)
	self:initSubcategories()
	self.sourceList:setSelectedItem(1, 1, nil, true)
	self.sourceSelector:setState(1, true)
	self.isAutoUpdatingList = isAutoUpdatingList
	self:updateScreen()
	self.isAutoUpdatingList = false
	self:setSelectionState(AnimalScreen.SELECTION_SOURCE, true)
	if #self.sourceSelector.texts == 0 or #self.sourceSelector.texts == 1 and self.sourceList:getItemCount() == 0 then
		if isRecursion ~= true then
			self:onClickSellMode(isAutoUpdatingList, true)
		end
		if #self.targetSelector.texts == 0 or #self.targetSelector.texts == 1 and self.sourceList:getItemCount() == 0 then
			g_gui:changeScreen(nil)
		end
		if isAutoUpdatingList ~= true then
			InfoDialog.show(g_i18n:getText("ui_noAnimalsToSell"))
		end
	end
end

function AnimalScreen:onClickSellMode(isAutoUpdatingList, isRecursion)
	self.isBuyMode = false
	self.targetSelector.leftButtonElement:setVisible(false)
	self.targetSelector.rightButtonElement:setVisible(false)
	self:initSubcategories()
	self.sourceList:setSelectedItem(1, 1)
	self.sourceSelector:setState(1, true)
	self.isAutoUpdatingList = isAutoUpdatingList
	self:updateScreen()
	self.isAutoUpdatingList = false
	self:setSelectionState(AnimalScreen.SELECTION_SOURCE, true)
	if #self.targetSelector.texts == 0 or #self.targetSelector.texts == 1 and self.sourceList:getItemCount() == 0 then
		if isRecursion ~= true then
			self:onClickBuyMode(isAutoUpdatingList, true)
		end
		if #self.sourceSelector.texts == 0 or #self.sourceSelector.texts == 1 and self.sourceList:getItemCount() == 0 then
			g_gui:changeScreen(nil)
		end
		if isAutoUpdatingList ~= true then
			InfoDialog.show(g_i18n:getText("ui_noAnimalsToSell"))
		end
	end
end

function AnimalScreen:onPagePrevious()
	if self.isBuyMode then
		self:onClickSellMode()
	else
		self:onClickBuyMode()
	end
end

function AnimalScreen:onPageNext()
	if self.isBuyMode then
		self:onClickSellMode()
	else
		self:onClickBuyMode()
	end
end

-- Local values: animalIndex, animalTypeIndex, text, buttonText
function AnimalScreen:onClickBuy()
	self.numAnimals = self.numAnimalsElement:getState()
	local v165_ = self.sourceList.selectedIndex
	local v166_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
	local v167_ = self.controller:getApplySourceConfirmationText(v166_, v165_, self.numAnimals)
	local v168_ = self.controller:getSourceActionText()
	YesNoDialog.show(self.onYesNoSource, self, v167_, g_i18n:getText("ui_attention"), v168_, g_i18n:getText("button_back"))
	return true
end

-- Local values: animalIndex, animalTypeIndex, text, buttonText
function AnimalScreen:onClickSell()
	self.numAnimals = self.numAnimalsElement:getState()
	local v170_ = self.sourceList.selectedIndex
	local v171_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
	local v172_ = self.controller:getApplyTargetConfirmationText(v171_, v170_, self.numAnimals)
	local v173_ = self.controller:getTargetActionText()
	YesNoDialog.show(self.onYesNoTarget, self, v172_, g_i18n:getText("ui_attention"), v173_, g_i18n:getText("button_back"))
	return true
end

-- Local values: animalIndex, animalTypeIndex
function AnimalScreen:onYesNoSource(yes)
	if yes then
		local v176_ = self.sourceList.selectedIndex
		local v177_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
		self.controller:applySource(v177_, v176_, self.numAnimals)
	end
end

-- Local values: animalIndex, animalTypeIndex
function AnimalScreen:onYesNoTarget(yes)
	if yes then
		local v180_ = self.sourceList.selectedIndex
		local v181_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
		self.controller:applyTarget(v181_, v180_, self.numAnimals)
	end
end

function AnimalScreen:registerActionEvents()
	g_inputBinding:registerActionEvent(InputAction.AXIS_MTO_SCROLL, self, self.onInputScrollMTO, false, false, true, true)
end

function AnimalScreen:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end

function AnimalScreen:onInputScrollMTO(_, inputValue)
	if inputValue ~= 0 and self.selectionState == AnimalScreen.SELECTION_AMOUNT then
		self.numAnimalsElement:setState(self.numAnimalsElement:getState() + inputValue)
		self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
		self:updatePrice()
	end
end

function AnimalScreen:onFocusEnterList(isEnteringSourceList, enteredList, previousList)
	if enteredList:getItemCount() == 0 then
		if previousList:getItemCount() > 0 then
			FocusManager:setFocus(previousList)
		end
	else
		FocusManager:unsetFocus(previousList)
		self.isSourceSelected = isEnteringSourceList
		self:updateInfoBox(isEnteringSourceList)
		if enteredList.selectedIndex == 0 then
			enteredList:setSelectedIndex(1)
		end
	end
end

-- Local values: sourceItems, animalTypeIndex, item, prevItem
function AnimalScreen:getCellTypeForItemInSection(list, section, index)
	if list ~= self.sourceList then
		return nil
	end
	local v193_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
	local v194_
	if self.isBuyMode then
		v194_ = self.controller:getSourceItems(v193_, self.isBuyMode)
	else
		v194_ = self.controller:getTargetItems()
	end
	local v195_ = v194_[index]
	local v196_ = v194_[index - 1]
	return (v196_ == nil or v195_:getSubTypeIndex() ~= v196_:getSubTypeIndex()) and "sectionCell" or "defaultCell"
end

-- Local values: animalTypeIndex
function AnimalScreen:getNumberOfItemsInSection(list, section)
	if not self.isOpen then
		return 0
	end
	local v199_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
	return list == self.sourceList and (self.isBuyMode and #self.controller:getSourceItems(v199_, self.isBuyMode) or #self.controller:getTargetItems()) or (self.isBuyMode and #self.controller:getTargetItems() or 0)
end

-- Local values: item, animalTypeIndex, subType, subType
function AnimalScreen:populateCellForItemInSection(list, section, index, cell)
	local v204_ = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
	if list == self.sourceList then
		local v205_
		if self.isBuyMode then
			v205_ = self.controller:getSourceItems(v204_, self.isBuyMode)[index]
		else
			v205_ = self.controller:getTargetItems()[index]
		end
		local v206_ = g_currentMission.animalSystem:getSubTypeByIndex(v205_:getSubTypeIndex())
		self.isHorse = v206_.typeIndex == AnimalType.HORSE
		if cell.name == "sectionCell" then
			cell:getAttribute("title"):setText(g_fillTypeManager:getFillTypeTitleByIndex(v206_.fillTypeIndex))
		end
		cell:getAttribute("icon"):setImageFilename(v205_:getFilename())
		cell:getAttribute("name"):setText(v205_:getName())
		cell:getAttribute("price"):setValue(v205_:getPrice())
		if self.isHorse then
			cell:getAttribute("amount"):setValue("")
		else
			cell:getAttribute("amount"):setText(v205_.cluster == nil and "" or ("x" .. v205_.cluster.numAnimals or ""))
		end
	else
		if list == self.targetList then
			local v207_
			if self.isBuyMode then
				v207_ = self.controller:getTargetItems()[index]
			else
				v207_ = self.controller:getSourceItems(v204_, self.isBuyMode)[index]
			end
			self.isHorse = g_currentMission.animalSystem:getSubTypeByIndex(v207_:getSubTypeIndex()).typeIndex == AnimalType.HORSE
			cell:getAttribute("icon"):setImageFilename(v207_:getFilename())
			cell:getAttribute("name"):setText(v207_:getName())
			cell:getAttribute("separator"):setVisible(index > 1)
			if self.isHorse then
				cell:getAttribute("amount"):setValue("")
				return
			end
			cell:getAttribute("amount"):setText(v207_.cluster == nil and "" or ("x" .. v207_.cluster.numAnimals or ""))
		end
		return
	end
end

-- Local values: sourceSelectorState, animalTypeIndex
function AnimalScreen:onListSelectionChanged(list, section, index)
	if not self.isAutoUpdatingList then
		if list == self.sourceList then
			self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
			local v210_ = self.sourceSelector:getState()
			self:setMaxNumAnimals(self.sourceSelectorStateToAnimalType[v210_])
		end
		self:updateInfoBox()
	end
end

function AnimalScreen:onDoubleClickSourceList(list, section, index)
	self:setSelectionState(AnimalScreen.SELECTION_TARGET)
end

function AnimalScreen:onDoubleClickTargetList(list, section, index)
	self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
end

function AnimalScreen:onClickNumAnimals()
	if self.selectionState ~= AnimalScreen.SELECTION_AMOUNT then
		self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
	end
	self:updatePrice()
end

function AnimalScreen:onFocusNumAnimals()
	if self.selectionState ~= AnimalScreen.SELECTION_AMOUNT then
		self:setSelectionState(AnimalScreen.SELECTION_AMOUNT)
	end
end

function AnimalScreen:updateChangedList(listElement, fallbackListElement, restoreSelection)
	self.isAutoUpdatingList = true
	listElement:reloadData()
	self.isAutoUpdatingList = false
	if listElement:getItemCount() == 0 then
		FocusManager:setFocus(fallbackListElement)
		fallbackListElement:setSelectedIndex(1)
	end
	self:updateInfoBox()
	if not Platform.isMobile then
		self:updatePrice()
	end
end
AnimalScreen.SYMBOL_L10N = {
	["TEXT_BUY"] = "button_buy",
	["TEXT_SELL"] = "button_sell",
	["TEXT_LOAD"] = "button_load",
	["TEXT_UNLOAD"] = "button_unload",
	["TEXT_PIECES"] = "unit_pieces",
	["ERROR_TRAILER_LEFT"] = "animals_transportTargetLeftTrigger"
}
AnimalScreen.COLOR = {
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
