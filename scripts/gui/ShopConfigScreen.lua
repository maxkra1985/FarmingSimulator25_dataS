ShopConfigScreen = {}
local ShopConfigScreen_mt = Class(ShopConfigScreen, ScreenElement)
ShopConfigScreen.INPUT_CONTEXT_NAME = "MENU_SHOP_CONFIG"
ShopConfigScreen.FADE_TEXTURE_PATH = "dataS/menu/base/graph_pixel.png"
ShopConfigScreen.WORKSHOP_PATH = "$data/maps/textures/shared/uiStore.i3d"
ShopConfigScreen.NEAR_CLIP_DISTANCE = 0.2
ShopConfigScreen.MIN_CAMERA_HEIGHT = 0.1
ShopConfigScreen.MAX_CAMERA_HEIGHT = 9
ShopConfigScreen.MAX_CAMERA_DISTANCE = 17
ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR = 3
ShopConfigScreen.DEFAULT_PREVIEW_SIZE = 5.2
ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR = 0.8
ShopConfigScreen.FAR_BLUR_END_DISTANCE = 100
ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MIN = 0
ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MAX = 0.08726646259971647
ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MIN = 4.5
ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MAX = 2
ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MIN = -2.530727415391778
ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MAX = -2.007128639793479
ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MIN = 3
ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MAX = 15
ShopConfigScreen.MOUSE_SPEED_MULTIPLIER = 2
ShopConfigScreen.MIN_MOUSE_DRAG_INPUT = 0.02 * InputBinding.MOUSE_MOVE_BASE_FACTOR
ShopConfigScreen.NO_VEHICLE = { delete = function() end }
ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG = "motor"
ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG = "fillUnit"
local NO_CALLBACK = function() end
function ShopConfigScreen.register()
	local shopConfigScreen = ShopConfigScreen.new()
	g_gui:loadGui("dataS/gui/ShopConfigScreen.xml", "ShopConfigScreen", shopConfigScreen)
	return shopConfigScreen
end
function ShopConfigScreen.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or ShopConfigScreen_mt)
	self.loadRequestIdWorkshop = nil
	self.fadeOverlay = Overlay.new(ShopConfigScreen.FADE_TEXTURE_PATH, 0, 0, 1, 1)
	self.fadeOverlay:setColor(0, 0, 0, 0)
	self.fadeInAnimation = TweenSequence.NO_SEQUENCE
	self.fadeOutAnimation = TweenSequence.NO_SEQUENCE
	self.rotateInputGlyph = nil
	self.zoomInputGlyph = nil
	self.lastInputHelpMode = nil
	self:createInputGlyphs()
	self.isOwnWorkshop = false
	self.totalPrice = 0
	self.initialLeasingCosts = 0
	self.lastMoney = 0
	self.displayableOptionCount = 0
	self.displayableColorCount = 0
	self.callbackFunc = nil
	self.requestExitCallback = NO_CALLBACK
	self.workshopWorldPosition = { 0, 0, 0 }
	self.workshopRootNode = nil
	self.workshopNode = nil
	self.cameraDistance = 10
	self.cameraMaxDistance = 20
	self.cameraMinDistance = 1
	self.zoomTarget = self.cameraDistance
	self.rotX = 0
	self.rotY = 0
	self.rotMinX = -0.17453292519943295
	self.rotMaxX = 1.2217304763960306
	self.focusY = 0
	self.vehicleSizeX = 1
	self.vehicleSizeY = 1
	self.vehicleSizeZ = 1
	self.rotateNode = nil
	self.cameraNode = nil
	self.previousCamera = nil
	self:createCamera()
	self:resetCamera()
	self.isLoadingInitial = false
	self.previewVehicleSize = 0
	self.previewVehicles = {}
	self.previousVehicles = {}
	self.loadingDelayFrames = 0
	self.loadingDelayTime = 0
	self.configItemCache = {}
	self.configItemCacheLarge = {}
	self.configurationToListElement = {}
	self.inputHorizontal = 0
	self.inputVertical = 0
	self.inputZoom = 0
	self.eventIdUpDownController = ""
	self.eventIdLeftRightController = ""
	self.eventIdUpDownMouse = ""
	self.eventIdLeftRightMouse = ""
	self.inputDragging = false
	self.isDragging = false
	self.accumDraggingInput = 0
	self.lastInputMode = g_inputBinding:getLastInputMode()
	self.lastInputHelpMode = g_inputBinding:getInputHelpMode()
	self.currentConfigSet = 1
	self:createFadeAnimations()
	g_messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBought, self)
	g_messageCenter:subscribe(MessageType.STORE_ITEMS_RELOADED, self.onStoreItemsReloaded, self)
	self.openCounter = 0
	addConsoleCommand("gsShopUIToggle", "Toggle shop config screen UI visibility", "consoleCommandUIToggle", self)
	return self
end
function ShopConfigScreen.createFromExistingGui(gui, guiName)
	removeConsoleCommand("gsShopUIToggle")
	local newGui = ShopConfigScreen.new()
	local returnScreenClass = gui.returnScreenClass
	local target = gui.target
	local callback = gui.callbackFunc
	local storeItem = gui.storeItem
	local saleItem = gui.saleItem
	local configurations = gui.configurations
	local x, y, z = unpack(gui.workshopWorldPosition)
	newGui.workshopFilename = gui.workshopFilename
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	g_shopConfigScreen = newGui
	newGui:createWorkshop(newGui.workshopFilename, x, y, z)
	newGui.openCounter = 1
	newGui:setReturnScreenClass(returnScreenClass)
	newGui:setStoreItem(storeItem, nil, saleItem, nil, configurations)
	newGui.openCounter = 0
	newGui:setCallbacks(callback, target)
	return newGui
end
function ShopConfigScreen:createInputGlyphs()
	local iconWidth, iconHeight = getNormalizedScreenValues(unpack(ShopConfigScreen.SIZE.INPUT_GLYPH))
	self.rotateInputGlyph = InputGlyphElement.new(g_inputDisplayManager, iconWidth, iconHeight)
	self.rotateInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
	self.zoomInputGlyph = InputGlyphElement.new(g_inputDisplayManager, iconWidth, iconHeight)
	self.zoomInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
end
function ShopConfigScreen:createFadeAnimations()
	local fadeInAnimation = TweenSequence.new(self)
	local fadeIn = Tween.new(self.fadeScreen, 1, 0, 300)
	fadeInAnimation:addTween(fadeIn)
	self.fadeInAnimation = fadeInAnimation
	local fadeOutAnimation = TweenSequence.new(self)
	local fadeOut = Tween.new(self.fadeScreen, 0, 1, 300)
	fadeOutAnimation:addTween(fadeOut)
	self.fadeOutAnimation = fadeOutAnimation
end
function ShopConfigScreen:fadeScreen(alpha)
	self.fadeOverlay:setColor(nil, nil, nil, alpha)
end
function ShopConfigScreen:createWorkshop(assetPath, posX, posY, posZ)
	self.workshopWorldPosition = { posX, posY, posZ }
	self.workshopRootNode = createTransformGroup("ShopConfigWorkshop")
	link(getRootNode(), self.workshopRootNode)
	setTranslation(self.workshopRootNode, posX, posY, posZ)
	setVisibility(self.workshopRootNode, false)
	self.loadRequestIdWorkshop = g_i3DManager:loadI3DFileAsync(assetPath, false, true, self.onWorkshopLoaded, self, nil)
end
function ShopConfigScreen:onWorkshopLoaded(node, failedReason, args)
	if node ~= 0 then
		self.loadRequestIdWorkshop = nil
		self.workshopNode = node
		removeFromPhysics(self.workshopNode)
		setTranslation(self.workshopNode, 0, 0, 0)
		link(self.workshopRootNode, self.workshopNode)
		addToPhysics(self.workshopNode)
		self.workshopColorNodes = {}
		I3DUtil.getNodesByShaderParam(node, "colorScale", self.workshopColorNodes, true)
		if 0 < #self.workshopColorNodes then
			self.workshopDefaultColor = { getShaderParameter(self.workshopColorNodes[1], "colorScale") }
		end
	end
	local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()
	self.shopSlotsIcon:setVisible(slotsVisible)
	self.shopSlotsText:setVisible(slotsVisible)
end
function ShopConfigScreen:onLicensePlateBoxLoaded(node, failedReason, args)
	if node ~= 0 then
		self.creationBox = node
		setVisibility(node, false)
	end
end
function ShopConfigScreen:createCamera()
	self.rotateNode = createTransformGroup("VehicleConfigCameraTarget")
	link(getRootNode(), self.rotateNode)
	setRotation(self.rotateNode, 0, 3.141592653589793, 0)
	setTranslation(self.rotateNode, 0, 0, 0)
	self.cameraPositionNode = createTransformGroup("VehicleConfigCameraOffsetNode")
	setTranslation(self.cameraPositionNode, 0, 0, -self.cameraDistance)
	setRotation(self.cameraPositionNode, 0, 3.141592653589793, 0)
	link(self.rotateNode, self.cameraPositionNode)
	self.cameraNode = createCamera("VehicleConfigCamera", 1.0471975511965976, ShopConfigScreen.NEAR_CLIP_DISTANCE, 100)
	local dofInfo = g_depthOfFieldManager:createInfo(1, 1, 0.8, 15, 100, true)
	g_cameraManager:addCamera(self.cameraNode, nil, false, nil, dofInfo, false)
	link(self.cameraPositionNode, self.cameraNode)
end
function ShopConfigScreen:resetCamera()
	local alphaX = MathUtil.inverseLerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MAX, self.vehicleSizeY)
	local alphaY = MathUtil.inverseLerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MAX, self.vehicleSizeX)
	self.rotX = MathUtil.lerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MAX, alphaX)
	self.rotY = MathUtil.lerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MAX, alphaY)
	self.cameraDistance = (self.cameraMinDistance + self.cameraMaxDistance) * 0.5
end
function ShopConfigScreen:delete()
	g_messageCenter:unsubscribeAll(self)
	self.rotateInputGlyph:delete()
	self.zoomInputGlyph:delete()
	self.fadeOverlay:delete()
	self.configurationItemTemplate:delete()
	self.configurationItemTemplateLarge:delete()
	self.configurationItemPlate:delete()
	self.attributeItem:delete()
	self:deletePreviewVehicles()
	if self.workshopNode ~= nil then
		delete(self.workshopNode)
		self.workshopNode = nil
	end
	if self.creationBox ~= nil then
		delete(self.creationBox)
		self.creationBox = nil
	end
	if self.workshopRootNode ~= nil then
		delete(self.workshopRootNode)
		self.workshopRootNode = nil
	end
	if self.cameraNode ~= nil then
		g_cameraManager:removeCamera(self.cameraNode)
		self.cameraNode = nil
	end
	if self.rotateNode ~= nil then
		delete(self.rotateNode)
		self.rotateNode = nil
	end
	if self.loadRequestIdWorkshop ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestIdWorkshop)
	end
	for _, element in ipairs(self.configItemCache) do
		element:delete()
	end
	self.configItemCache = {}
	for _, element in ipairs(self.configItemCacheLarge) do
		element:delete()
	end
	self.configItemCacheLarge = {}
	removeConsoleCommand("gsShopUIToggle")
	ShopConfigScreen:superClass().delete(self)
end
function ShopConfigScreen:onGuiSetupFinished()
	ShopConfigScreen:superClass().onGuiSetupFinished(self)
	self.configurationItemTemplate:unlinkElement()
	FocusManager:removeElement(self.configurationItemTemplate)
	self.configurationItemTemplateLarge:unlinkElement()
	FocusManager:removeElement(self.configurationItemTemplateLarge)
	self.attributeItem:unlinkElement()
	self.configurationItemPlate:unlinkElement()
	FocusManager:removeElement(self.configurationItemPlate)
end
function ShopConfigScreen:updateBalanceText()
	local money = g_currentMission:getMoney()
	self.lastMoney = money
	self.currentBalanceText:setValue(money)
	if money <= -1 then
		self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE)
	else
		self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY)
	end
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end
function ShopConfigScreen:onMoneyChange()
	if g_localPlayer ~= nil then
		local farm = g_farmManager:getFarmById(g_localPlayer.farmId)
		if farm.money <= -1 then
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
		else
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
		end
		local moneyText = g_i18n:formatMoney(farm.money, 0, true, false)
		self.currentBalanceText:setText(moneyText)
		if self.shopMoneyBox ~= nil then
			self.shopMoneyBox:invalidateLayout()
			self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
		end
	end
end
function ShopConfigScreen:onSlotUsageChanged(slotsUsage, maxSlots)
	local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()
	if slotsVisible then
		local text = string.format("%0d / %0d", slotsUsage, maxSlots)
		local profile = ShopMenu.GUI_PROFILE.SHOP_MONEY
		if ShopMenu.SLOTS_USAGE_CRITICAL_THRESHOLD <= slotsUsage / maxSlots then
			profile = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
		end
		self.shopSlotsText:applyProfile(profile)
		self.shopSlotsText:setText(text)
	end
	self.shopSlotsIcon:setVisible(slotsVisible)
	self.shopSlotsText:setVisible(slotsVisible)
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end
function ShopConfigScreen:processStoreItemUpkeep(storeItem, realItem, saleItem)
	local dailyUpkeep = 0
	if storeItem.dailyUpkeep ~= nil then
		dailyUpkeep = storeItem.dailyUpkeep
		for name, id in pairs(self.configurations) do
			local configs = storeItem.configurations[name]
			if configs == nil or configs[id] == nil then
				continue
			end
			dailyUpkeep = dailyUpkeep + configs[id].dailyUpkeep
		end
	end
	return dailyUpkeep
end
function ShopConfigScreen:processStoreItemPowerOutput(storeItem, realItem, saleItem)
	local power = 0
	if storeItem.specs ~= nil and storeItem.specs.power ~= nil then
		power = storeItem.specs.power
		if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
			local configId = self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]
			power = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][configId].power, power)
		end
	end
	return power
end
function ShopConfigScreen:processStoreItemFuelCapacity(storeItem, realItem, saleItem, fuelFillType)
	return Motorized.getSpecValueFuel(storeItem, realItem, self.configurations, fuelFillType, true) or 0
end
function ShopConfigScreen:processStoreItemCapacity(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.capacity ~= nil then
		return FillUnit.getSpecValueCapacity(storeItem, realItem, self.configurations, saleItem, true)
	end
	return 0, nil
end
function ShopConfigScreen:processStoreItemWeight(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.weight ~= nil then
		local baseWeight = Vehicle.getSpecValueWeight(storeItem, realItem, nil, saleItem, true)
		local additionalWeight = 0
		if storeItem.specs.additionalWeight ~= nil then
			additionalWeight = Vehicle.getSpecValueAdditionalWeight(storeItem, realItem, nil, saleItem, true)
		end
		return baseWeight, additionalWeight
	end
	return 0, 0
end
function ShopConfigScreen:processStoreItemWorkingWidth(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil then
		if storeItem.specs.workingWidth ~= nil then
			return storeItem.specs.workingWidth.minWidth, storeItem.specs.workingWidth.width
		end
		if storeItem.specs.workingWidthConfig ~= nil then
			local width = Vehicle.getSpecValueWorkingWidthConfig(storeItem, realItem, self.configurations, saleItem, true) or 0
			return width, width
		end
	end
	return nil, nil
end
function ShopConfigScreen:processStoreItemWorkingSpeed(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.speedLimit ~= nil then
		return storeItem.specs.speedLimit
	end
	return 0
end
function ShopConfigScreen:processStoreItemPowerNeeded(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.neededPower ~= nil then
		local configValue = storeItem.specs.neededPower.config[self.configurations.powerConsumer]
		return configValue or storeItem.specs.neededPower.base or 0
	end
	return 0
end
function ShopConfigScreen:processStoreItemBalerBaleSize(storeItem)
	if storeItem.specs ~= nil then
		local balerBaleSize = storeItem.specs.balerBaleSizeRound or storeItem.specs.balerBaleSizeSquare
		if balerBaleSize ~= nil then
			local size = Baler.getSpecValueBaleSize(storeItem, nil, nil, nil, false, false, balerBaleSize.isRoundBaler)
			if balerBaleSize.isRoundBaler then
				return size, ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND
			else
				return size, ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE
			end
		end
	end
	return ""
end
function ShopConfigScreen:processStoreItemBaleWrapperBaleSize(storeItem)
	if storeItem.specs ~= nil then
		local roundBaleSize = BaleWrapper.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false)
		local squareBaleSize = BaleWrapper.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
		if roundBaleSize == nil and squareBaleSize == nil then
			roundBaleSize = InlineWrapper.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false)
			squareBaleSize = InlineWrapper.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
		end
		return roundBaleSize, squareBaleSize
	else
		return nil, nil
	end
end
function ShopConfigScreen:processStoreItemBaleLoaderBaleSize(storeItem)
	if storeItem.specs ~= nil then
		local roundBaleSize = BaleLoader.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false)
		local squareBaleSize = BaleLoader.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
		return roundBaleSize, squareBaleSize
	else
		return nil, nil
	end
end
function ShopConfigScreen:processStoreItemWoodHarvesterMaxTreeSize(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.woodHarvesterMaxTreeSize ~= nil then
		return WoodHarvester.getSpecValueMaxTreeSize(storeItem, realItem, self.configurations, saleItem, false)
	end
	return nil
end
function ShopConfigScreen:processAttributeData(storeItem, vehicle, saleItem)
	local dailyUpkeep = 0
	local powerOutput = 0
	local transmissionName = nil
	local fuelCapacity = 0
	local electricCapacity = 0
	local methaneCapacity = 0
	local defCapacity = 0
	local maxSpeed = 0
	local capacity = 0
	local capacityUnit = nil
	local weight = 0
	local additionalWeight = 0
	local workingWidthMin = math.huge
	local workingWidthMax = -math.huge
	local workingSpeed = 0
	local powerNeeded = 0
	local wheelNames = ""
	local baleSize = ""
	local baleSizeProfile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND
	local wrapperBaleSizeRound = nil
	local wrapperBaleSizeSquare = nil
	local loaderBaleSizeRound = nil
	local loaderBaleSizeSquare = nil
	local woodHarvesterMaxTreeSize = nil
	local fellerBuncherMaxRadius = 0
	local baleGrabMaxSizeRound = nil
	local baleGrabMaxSizeSquare = nil
	local maxYarderLength = 0
	local maxYarderTreeMass = 0
	local maxWinchMass = 0
	local storeItems = nil
	if storeItem.bundleInfo == nil then
		storeItems = { storeItem }
	else
		storeItems = {}
		for i = 1, #storeItem.bundleInfo.bundleItems do
			table.insert(storeItems, storeItem.bundleInfo.bundleItems[i].item)
		end
	end
	for itemIndex, item in ipairs(storeItems) do
		StoreItemUtil.loadSpecsFromXML(item)
		local realItem = self.previewVehicles[itemIndex] or vehicle
		dailyUpkeep = dailyUpkeep + self:processStoreItemUpkeep(item, realItem, saleItem)
		powerOutput = powerOutput + self:processStoreItemPowerOutput(item, realItem, saleItem)
		transmissionName = transmissionName or Motorized.getSpecValueTransmission(storeItem, realItem, nil, saleItem)
		fuelCapacity = fuelCapacity + self:processStoreItemFuelCapacity(item, realItem, saleItem, FillType.DIESEL)
		electricCapacity = electricCapacity + self:processStoreItemFuelCapacity(item, realItem, saleItem, FillType.ELECTRICCHARGE)
		methaneCapacity = methaneCapacity + self:processStoreItemFuelCapacity(item, realItem, saleItem, FillType.METHANE)
		defCapacity = defCapacity + self:processStoreItemFuelCapacity(item, realItem, saleItem, FillType.DEF)
		local itemCapacity, itemCapacityUnit = self:processStoreItemCapacity(item, realItem, saleItem)
		if capacityUnit ~= nil and (itemCapacityUnit ~= nil and itemCapacityUnit ~= capacityUnit) then
			printWarning("Warning: Bundled store items have different fill capacity units. Check " .. tostring(storeItem.xmlFilename))
		end
		capacity = capacity + itemCapacity
		capacityUnit = capacityUnit or itemCapacityUnit
		local itemWeight, itemAdditionalWeight = self:processStoreItemWeight(item, realItem, saleItem)
		weight = weight + (itemWeight or 0)
		additionalWeight = additionalWeight + (itemAdditionalWeight or 0)
		local itemMinWidth, itemMaxWidth = self:processStoreItemWorkingWidth(item, realItem, saleItem)
		if itemMinWidth ~= nil and itemMaxWidth ~= nil then
			workingWidthMin = math.min(workingWidthMin, itemMinWidth)
			workingWidthMax = math.max(workingWidthMax, itemMaxWidth)
		end
		workingSpeed = math.max(workingSpeed, self:processStoreItemWorkingSpeed(item, realItem, saleItem))
		maxSpeed = math.max(maxSpeed, Motorized.getSpecValueMaxSpeed(storeItem, realItem, self.configurations, saleItem, true, false) or 0)
		powerNeeded = powerNeeded + self:processStoreItemPowerNeeded(item, realItem, saleItem)
		local itemBaleSize, itemBaleSizeProfile = self:processStoreItemBalerBaleSize(item)
		if baleSize == "" then
			baleSize = itemBaleSize
			baleSizeProfile = itemBaleSizeProfile
		end
		local roundSize, squareSize = self:processStoreItemBaleWrapperBaleSize(item)
		wrapperBaleSizeRound = wrapperBaleSizeRound or roundSize
		wrapperBaleSizeSquare = wrapperBaleSizeSquare or squareSize
		roundSize, squareSize = self:processStoreItemBaleLoaderBaleSize(item)
		loaderBaleSizeRound = loaderBaleSizeRound or roundSize
		loaderBaleSizeSquare = loaderBaleSizeSquare or squareSize
		baleGrabMaxSizeRound = BaleGrab.getSpecValueMaxSizeRound(storeItem, realItem, self.configurations, saleItem, false, false) or baleGrabMaxSizeRound
		baleGrabMaxSizeSquare = BaleGrab.getSpecValueMaxSizeSquare(storeItem, realItem, self.configurations, saleItem, false, false) or baleGrabMaxSizeSquare
		woodHarvesterMaxTreeSize = self:processStoreItemWoodHarvesterMaxTreeSize(item)
		local radius, _ = FellerBuncher.getSpecValueMaxTreeSize(storeItem, realItem, self.configurations, saleItem, true, false)
		fellerBuncherMaxRadius = math.max(radius or 0, fellerBuncherMaxRadius)
		maxYarderLength = math.max(YarderTower.getSpecValueMaxLength(storeItem, realItem, self.configurations, saleItem, true, false) or 0, maxYarderLength)
		maxYarderTreeMass = math.max(YarderTower.getSpecValueMaxMass(storeItem, realItem, self.configurations, saleItem, true, false) or 0, maxYarderTreeMass)
		maxWinchMass = math.max(Winch.getSpecValueMaxMass(storeItem, realItem, self.configurations, saleItem, true, false) or 0, maxWinchMass)
	end
	if vehicle ~= nil then
		local tireNames = Wheels.getTireNames(vehicle)
		if tireNames ~= nil then
			wheelNames = table.concatKeys(tireNames, " / ")
		end
	end
	local values = {}
	if dailyUpkeep ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.MAINTENANCE_COST, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.MAINTENANCE_COST), g_i18n:formatMoney(dailyUpkeep, 2)) })
	end
	if powerOutput ~= 0 then
		local hp, kw = g_i18n:getPower(powerOutput)
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.POWER, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.POWER), MathUtil.round(kw), MathUtil.round(hp)) })
	end
	if transmissionName ~= nil then
		table.insert(values, { value = transmissionName, profile = ShopConfigScreen.GUI_PROFILE.TRANSMISSION })
	end
	if fuelCapacity ~= 0 then
		if defCapacity == 0 then
			table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.FUEL, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), fuelCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER)) })
		elseif 0 < defCapacity then
			table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.FUEL, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL_DEF), fuelCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), defCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.DEF_SHORT)) })
		end
	elseif electricCapacity ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.ELECTRICCHARGE, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), electricCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_KW)) })
	elseif methaneCapacity ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.METHANE, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), methaneCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_KG)) })
	end
	if maxSpeed ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.MAX_SPEED, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.MAX_SPEED), string.format("%1d", g_i18n:getSpeed(maxSpeed)), g_i18n:getSpeedMeasuringUnit()) })
	end
	if capacity ~= 0 and capacityUnit ~= nil then
		if capacityUnit:sub(1, 6) == "$l10n_" then
			capacityUnit = capacityUnit:sub(7)
		end
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.CAPACITY, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CAPACITY), capacity, g_i18n:getText(capacityUnit)) })
	end
	if weight ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.WEIGHT, value = g_i18n:formatMass(weight) })
	end
	if additionalWeight ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.ADDITIONAL_WEIGHT, value = g_i18n:formatMass(additionalWeight) })
	end
	if powerNeeded ~= 0 then
		local hp, kw = g_i18n:getPower(powerNeeded)
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.POWER_REQUIREMENT, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.POWER_REQUIREMENT), MathUtil.round(kw), MathUtil.round(hp)) })
	end
	if workingWidthMin ~= math.huge and workingWidthMax ~= -math.huge then
		local text = nil
		if workingWidthMin == workingWidthMax then
			text = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_WIDTH), g_i18n:formatNumber(workingWidthMax, 1, true))
		else
			text = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_WIDTH), string.format("%s-%s", g_i18n:formatNumber(workingWidthMin, 1, true), g_i18n:formatNumber(workingWidthMax, 1, true)))
		end
		table.insert(values, { value = text, profile = ShopConfigScreen.GUI_PROFILE.WORKING_WIDTH })
	end
	if workingSpeed ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.WORKING_SPEED, value = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_SPEED), string.format("%1d", g_i18n:getSpeed(workingSpeed)), g_i18n:getSpeedMeasuringUnit()) })
	end
	if wheelNames ~= "" then
		table.insert(values, { value = wheelNames, profile = ShopConfigScreen.GUI_PROFILE.WHEELS })
	end
	if baleSize ~= nil and baleSize ~= "" then
		table.insert(values, { profile = baleSizeProfile, value = baleSize })
	end
	if wrapperBaleSizeRound ~= nil then
		table.insert(values, { value = wrapperBaleSizeRound, profile = ShopConfigScreen.GUI_PROFILE.BALEWRAPPER_SIZE_ROUND })
	end
	if wrapperBaleSizeSquare ~= nil then
		table.insert(values, { value = wrapperBaleSizeSquare, profile = ShopConfigScreen.GUI_PROFILE.BALEWRAPPER_SIZE_SQUARE })
	end
	if loaderBaleSizeRound ~= nil then
		table.insert(values, { value = loaderBaleSizeRound, profile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND })
	end
	if loaderBaleSizeSquare ~= nil then
		table.insert(values, { value = loaderBaleSizeSquare, profile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE })
	end
	if baleGrabMaxSizeRound ~= nil then
		table.insert(values, { value = baleGrabMaxSizeRound, profile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND })
	end
	if baleGrabMaxSizeSquare ~= nil then
		table.insert(values, { value = baleGrabMaxSizeSquare, profile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE })
	end
	if woodHarvesterMaxTreeSize ~= nil then
		table.insert(values, { value = woodHarvesterMaxTreeSize, profile = ShopConfigScreen.GUI_PROFILE.MAX_TREE_SIZE })
	end
	if fellerBuncherMaxRadius ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.MAX_TREE_SIZE, value = string.format("%d%s", MathUtil.round(fellerBuncherMaxRadius), g_i18n:getText("unit_cmShort")) })
	end
	if maxYarderLength ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.YARDER_MAX_LENGTH, value = string.format("%d%s", maxYarderLength, g_i18n:getText("unit_mShort")) })
	end
	if maxYarderTreeMass ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.MAX_TREE_MASS, value = string.format("%.1f%s", maxYarderTreeMass, g_i18n:getText("unit_tonsShort")) })
	end
	if maxWinchMass ~= 0 then
		table.insert(values, { profile = ShopConfigScreen.GUI_PROFILE.MAX_TREE_MASS, value = string.format("%.1f%s", maxWinchMass, g_i18n:getText("unit_tonsShort")) })
	end
	self:registerCustomSpecValues(values, storeItems, vehicle, saleItem)
	for _ = 1, #self.attributesLayout.elements do
		self.attributesLayout.elements[1]:delete()
	end
	for i, item in ipairs(values) do
		local itemElement = self.attributeItem:clone(self.attributesLayout)
		local iconElement = itemElement:getDescendantByName("icon")
		local textElement = itemElement:getDescendantByName("text")
		iconElement:applyProfile(item.profile)
		textElement:setText(item.value)
	end
	self.attributesLayout:invalidateLayout()
end
function ShopConfigScreen:registerCustomSpecValues(values, storeItems, vehicle, saleItem) end
function ShopConfigScreen:getConfigurationCostsAndChanges(storeItem, vehicle, saleItem)
	local basePrice = 0
	local upgradePrice = 0
	local hasChanges = false
	if vehicle ~= nil then
		local serviceFee, configurationPrice, hasConfigurationChanges = g_currentMission.economyManager:getConfigurationChangePrice(storeItem, vehicle, self.configurations, self.isOwnWorkshop)
		upgradePrice = configurationPrice
		hasChanges = hasConfigurationChanges
		if ConfigurationUtil.getConfigurationDataHasChanged(vehicle.configFileName, self.configurationData, vehicle.configurationData) then
			hasChanges = true
		end
		if hasChanges then
			basePrice = serviceFee
		end
		if vehicle.getLicensePlatesDataIsEqual ~= nil and not vehicle:getLicensePlatesDataIsEqual(self.licensePlateData) then
			hasChanges = true
			return basePrice, upgradePrice, hasChanges
		end
	else
		if saleItem ~= nil then
			hasChanges = true
			basePrice, upgradePrice = g_currentMission.economyManager:getBuyPrice(storeItem, self.configurations, saleItem)
			basePrice = basePrice - upgradePrice
			return basePrice, upgradePrice, hasChanges
		end
		if storeItem ~= nil then
			hasChanges = true
			basePrice, upgradePrice = g_currentMission.economyManager:getBuyPrice(storeItem, self.configurations)
			basePrice = basePrice - upgradePrice
		end
	end
	return basePrice, upgradePrice, hasChanges
end
function ShopConfigScreen:updatePriceData(basePrice, upgradePrice)
	self.totalPrice = basePrice + upgradePrice
	self.initialLeasingCosts = 0
	self.initialLeasingCosts = g_currentMission.economyManager:getInitialLeasingPrice(self.totalPrice)
	self.basePriceText:setText(g_i18n:formatMoney(basePrice, 0, true, false))
	self.upgradesPriceText:setText("+ " .. g_i18n:formatMoney(upgradePrice, 0, true, false))
	self.totalPriceText:setText(g_i18n:formatMoney(self.totalPrice, 0, true, false))
end
function ShopConfigScreen:updateData(storeItem, vehicle, saleItem)
	local basePrice, upgradePrice, hasChanges = self:getConfigurationCostsAndChanges(storeItem, vehicle, saleItem)
	self:updatePriceData(basePrice, upgradePrice)
	self.buyButton:setDisabled(not hasChanges)
	self:loadCurrentConfiguration(storeItem)
end
function ShopConfigScreen:getDefaultConfigurationColorIndex(configName, configItems, vehicle)
	local index = nil
	for k, item in pairs(configItems) do
		if item.isDefault then
			index = k
			break
		end
	end
	if vehicle ~= nil then
		index = vehicle.configurations[configName]
	end
	if index == nil then
		index = 1
	end
	return index
end
function ShopConfigScreen:updateButtons(storeItem, vehicle, saleItem)
	self.leaseButton:setVisible(vehicle == nil and storeItem.allowLeasing and saleItem == nil)
	local buyButtonText = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_BUY)
	if vehicle ~= nil then
		buyButtonText = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_CONFIGURE)
	end
	self.buyButton:setText(buyButtonText)
	self.buyButton:updateAbsolutePosition()
	self.buttonsPanel:invalidateLayout()
end
function ShopConfigScreen:loadCurrentConfiguration(storeItem)
	if self.currentVehicleLoading ~= nil then
		self.currentVehicleLoading:cancelLoading()
	end
	local data = VehicleLoadingData.new()
	data:setPosition(self.workshopWorldPosition[1], self.workshopWorldPosition[2], self.workshopWorldPosition[3])
	if not storeItem.shopIgnoreLastComponentPositions then
		for _, preVehicle in ipairs(self.previewVehicles) do
			if preVehicle.configFileName == storeItem.xmlFilename then
				data:setComponentPositionData(preVehicle)
			end
		end
	end
	data:setStoreItem(storeItem)
	data:setConfigurations(self.configurations)
	data:setConfigurationData(self.configurationData)
	data:setPropertyState(VehiclePropertyState.SHOP_CONFIG)
	data:setCustomParameter("foldableInvertFoldState", MathUtil.round(storeItem.shopFoldingState, 0) == 1)
	data:setCustomParameter("foldableFoldingTime", storeItem.shopFoldingTime)
	data:setForceServer(true)
	data:setIsRegistered(false)
	data:setIsSaved(false)
	data:setSaleItem(self.saleItem)
	self.currentVehicleLoading = data
	self.loadingAnimation:setVisible(true)
	data:load(self.onVehiclesLoaded, self, { openCounter = self.openCounter })
end
function ShopConfigScreen:onVehiclesLoaded(vehicles, loadingState, asyncArguments)
	self.currentVehicleLoading = nil
	if loadingState == VehicleLoadingState.CANCELED then
		return
	else
		if loadingState == VehicleLoadingState.OK then
			if asyncArguments.openCounter ~= self.openCounter then
				for _, vehicle in ipairs(vehicles) do
					vehicle:delete()
				end
				return
			else
				if self.isLoadingInitial or self.isOpen then
					for _, vehicle in ipairs(self.previewVehicles) do
						vehicle:removeFromPhysics()
						table.insert(self.previousVehicles, vehicle)
					end
					self.previewVehicles = vehicles
					for index, vehicle in ipairs(vehicles) do
						vehicle:setVisibility(false)
						vehicle.forceIsActive = true
					end
					for index, vehicle in ipairs(vehicles) do
						self:processAttributeData(self.storeItem, vehicle)
						if vehicle.setLicensePlatesData ~= nil and (vehicle.getHasLicensePlates ~= nil and vehicle:getHasLicensePlates()) then
							local defaultPlacementIndex, hasFrontPlate = vehicle:getLicensePlateDialogSettings()
							self.licensePlateData.defaultPlacementIndex = defaultPlacementIndex
							self.licensePlateData.hasFrontPlate = hasFrontPlate
							if not self.licensePlateData.customized and defaultPlacementIndex ~= nil then
								self.licensePlateData.placementIndex = defaultPlacementIndex
							end
							vehicle:setLicensePlatesData(self.licensePlateData)
							self:updateLicensePlateGraphics()
						end
						if vehicle.addDamageAmount ~= nil and vehicle.addWearAmount ~= nil then
							if self.saleItem ~= nil then
								vehicle:addDamageAmount(self.saleItem.damage or 0, true)
								vehicle:addWearAmount(self.saleItem.wear or 0, true)
							elseif self.vehicle ~= nil then
								if self.vehicle.getDamageAmount ~= nil and self.vehicle.getWearTotalAmount ~= nil then
									vehicle:addDamageAmount(self.vehicle:getDamageAmount(), true)
									vehicle:addWearAmount(self.vehicle:getWearTotalAmount(), true)
								end
							end
						end
						if vehicle.setDirtAmount == nil or self.vehicle == nil or self.vehicle.getDirtAmount == nil then
							continue
						end
						vehicle:setDirtAmount(self.vehicle:getDirtAmount())
					end
					local loadingDelayTime = 0
					if self.isLoadingInitial then
						loadingDelayTime = self.storeItem.shopInitialLoadingDelay or loadingDelayTime
					else
						loadingDelayTime = self.storeItem.shopConfigLoadingDelay or loadingDelayTime
					end
					self.loadingDelayTime = loadingDelayTime
					self.loadingDelayFrames = 3
					return
				end
				for _, vehicle in ipairs(vehicles) do
					vehicle:delete()
				end
				self.previewVehicles = {}
				return
			end
		end
		if g_currentMission ~= nil then
			Logging.error("Could not load vehicle defined in [%s]. Check vehicle configuration and mods.", tostring(self.storeItem.xmlFilename))
			self.callbackFunc = nil
			self:onClickBack()
		end
	end
end
function ShopConfigScreen:onFinishedLoading()
	local numVehicles = #self.previousVehicles
	for i = numVehicles, 1, -1 do
		self.previousVehicles[i]:delete()
		self.previousVehicles[i] = nil
	end
	for _, loadedVehicle in pairs(self.previewVehicles) do
		loadedVehicle:setVisibility(true)
	end
	if numVehicles == 0 then
		self.vehicleSizeY = 1
		self.previewVehicleSize = 0
		local minX = math.huge
		local maxX = -math.huge
		local minZ = math.huge
		local maxZ = -math.huge
		for _, vehicle in pairs(self.previewVehicles) do
			local largestDimension = math.max(vehicle.size.width, vehicle.size.length, self.storeItem.shopHeight * 1.5)
			self.previewVehicleSize = self.previewVehicleSize + largestDimension
			self.vehicleSizeY = math.max(self.vehicleSizeY, vehicle.size.height)
			local halfWidth = vehicle.size.width * 0.5
			local halfLength = vehicle.size.length * 0.5
			local x1, _, z1 = localToLocal(vehicle.rootNode, self.workshopRootNode, halfWidth + vehicle.size.widthOffset, 0, halfLength + vehicle.size.lengthOffset)
			local x2, _, z2 = localToLocal(vehicle.rootNode, self.workshopRootNode, halfWidth + vehicle.size.widthOffset, 0, -halfLength + vehicle.size.lengthOffset)
			local x3, _, z3 = localToLocal(vehicle.rootNode, self.workshopRootNode, -halfWidth + vehicle.size.widthOffset, 0, -halfLength + vehicle.size.lengthOffset)
			local x4, _, z4 = localToLocal(vehicle.rootNode, self.workshopRootNode, -halfWidth + vehicle.size.widthOffset, 0, halfLength + vehicle.size.lengthOffset)
			minX = math.min(x1, x2, x3, x4, minX)
			maxX = math.max(x1, x2, x3, x4, maxX)
			minZ = math.min(z1, z2, z3, z4, minZ)
			maxZ = math.max(z1, z2, z3, z4, maxZ)
		end
		self.vehicleSizeX = math.max(maxX - minX, 1)
		self.vehicleSizeZ = math.max(maxZ - minZ, 1)
		self.focusY = self.vehicleSizeY * 0.4
	end
	if self.previewVehicleSize == 0 then
		self.previewVehicleSize = ShopConfigScreen.DEFAULT_PREVIEW_SIZE
	end
	self.cameraMaxDistance = math.min(self.previewVehicleSize * ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR, ShopConfigScreen.MAX_CAMERA_DISTANCE)
	self.cameraMinDistance = math.min(self.previewVehicleSize * ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR + ShopConfigScreen.NEAR_CLIP_DISTANCE, self.cameraMaxDistance)
	if self.isLoadingInitial then
		local defaultOffset = 1
		defaultOffset = self.vehicleSizeX < self.vehicleSizeY and math.max(self.vehicleSizeX, self.vehicleSizeY) * 0.35 or math.max(self.vehicleSizeZ, self.vehicleSizeY) * 0.35
		self.cameraDistance = math.min(self.cameraMinDistance + defaultOffset, self.cameraMaxDistance)
		self.zoomTarget = self.cameraDistance
		self:resetCamera()
	end
	if self.storeItem.shopDynamicTitle then
		local vehicle = self.previewVehicles[1]
		if vehicle ~= nil then
			local brand = g_brandManager:getBrandByIndex(vehicle:getBrand() or self.storeItem.brandIndex)
			self.shopConfigBrandIcon:setImageFilename(self.storeItem.customBrandIcon or brand.image)
			self.shopConfigItemName:setText(vehicle:getName() or self.storeItem.name)
		end
	end
	self.isLoadingInitial = false
	self.loadingAnimation:setVisible(false)
end
function ShopConfigScreen:updateDisplay(storeItem, vehicle, saleItem, doNotReload)
	local brandIndex = storeItem.brandIndex
	local vehicleName = storeItem.name
	if storeItem.shopDynamicTitle and vehicle ~= nil then
		brandIndex = vehicle:getBrand()
		vehicleName = vehicle:getName()
	end
	local brand = g_brandManager:getBrandByIndex(brandIndex)
	if self.shopConfigBrandIcon == nil then
		printCallstack()
	end
	self.shopConfigBrandIcon:setImageFilename(storeItem.customBrandIcon or brand.image)
	self.shopConfigItemName:setText(vehicleName)
	self:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
	self:updateButtons(storeItem, vehicle, saleItem)
	if not doNotReload then
		self:updateData(storeItem, vehicle, saleItem)
	end
end
function ShopConfigScreen:setCurrentMission(currentMission) end
function ShopConfigScreen:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	if not GS_IS_MOBILE_VERSION then
		local shopConfigFilename = getXMLString(mapXMLFile, "map.shop#filename") or "$data/store/ui/shop.xml"
		shopConfigFilename = Utils.getFilename(shopConfigFilename, baseDirectory)
		local xmlFile = XMLFile.load("shopXml", shopConfigFilename)
		self.workshopFilename = Utils.getFilename(xmlFile:getString("shop.filename") or ShopConfigScreen.WORKSHOP_PATH, baseDirectory)
		local x = xmlFile:getFloat("shop.position#xMapPos") or 0
		local y = xmlFile:getFloat("shop.position#yMapPos") or 0
		local z = xmlFile:getFloat("shop.position#zMapPos") or 0
		local isLightingStatic = Utils.getNoNil(xmlFile:getBool("shop.lighting#isStatic"), false)
		if isLightingStatic then
			self.shopLighting = LightingStatic.new()
		else
			self.shopLighting = Lighting.new()
		end
		self.shopLighting:load(xmlFile, "shop.lighting", g_currentMission.baseDirectory)
		xmlFile:delete()
		self:createWorkshop(self.workshopFilename, x, y, z)
		if self.licensePlateRender ~= nil then
			self.licensePlateRender:createScene()
		end
	end
end
function ShopConfigScreen:unloadMapData()
	if self.workshopNode ~= nil then
		delete(self.workshopNode)
	end
	if self.workshopRootNode ~= nil then
		delete(self.workshopRootNode)
	end
	if self.shopLighting ~= nil then
		self.shopLighting:delete()
	end
	if self.creationBox ~= nil then
		delete(self.creationBox)
		self.creationBox = nil
	end
	if self.loadRequestIdWorkshop ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestIdWorkshop)
		self.loadRequestIdWorkshop = nil
	end
	if self.licensePlateRender ~= nil then
		self.licensePlateRender:destroyScene()
		self.licensePlateRender = nil
	end
	self.shopLighting = nil
	self.workshopNode = nil
	self.workshopRootNode = nil
end
function ShopConfigScreen:setWorkshopWorldPosition(posX, posY, posZ)
	self.workshopWorldPosition = { posX, posY, posZ }
end
function ShopConfigScreen:setCallbacks(callbackFunc, target)
	self.callbackFunc = callbackFunc
	self.target = target
end
function ShopConfigScreen:deletePreviewVehicles()
	for _, vehicle in pairs(self.previewVehicles) do
		vehicle:delete()
	end
	self.previewVehicles = {}
end
function ShopConfigScreen:setStoreItem(storeItem, vehicle, saleItem, isOwnWorkshop, configurations)
	self:deletePreviewVehicles()
	self.storeItem = storeItem
	self.vehicle = vehicle
	self.saleItem = saleItem
	self.isOwnWorkshop = isOwnWorkshop == true
	if configurations == nil then
		configurations = {}
		if storeItem.defaultConfigurationIds ~= nil then
			for configName, index in pairs(storeItem.defaultConfigurationIds) do
				configurations[configName] = index
			end
		end
		if vehicle ~= nil and vehicle.configurations ~= nil then
			for configName, index in pairs(vehicle.configurations) do
				configurations[configName] = index
			end
		end
		if saleItem ~= nil and saleItem.boughtConfigurations ~= nil then
			for configName, boughtItems in pairs(saleItem.boughtConfigurations) do
				for index, value in pairs(boughtItems) do
					if value then
						configurations[configName] = index
					end
				end
			end
		end
	end
	self.configurations = configurations
	if vehicle ~= nil then
		self.configurationData = table.clone(vehicle.configurationData, math.huge)
		self.boughtConfigurations = table.clone(vehicle.boughtConfigurations, math.huge)
	else
		self.configurationData = {}
		self.boughtConfigurations = {}
	end
	self.subConfigurations = {}
	self.currentConfigSet = 1
	self.isLoadingInitial = true
	if g_licensePlateManager:getAreLicensePlatesAvailable() then
		if vehicle ~= nil then
			if vehicle.getLicensePlatesData ~= nil then
				local data = vehicle:getLicensePlatesData()
				if data ~= nil then
					if data.characters ~= nil then
						self.licensePlateData = {}
						self.licensePlateData.variation = data.variation
						self.licensePlateData.colorIndex = data.colorIndex
						self.licensePlateData.placementIndex = data.placementIndex
						self.licensePlateData.characters = table.clone(data.characters)
						local defaultPlacementIndex, hasFrontPlate = vehicle:getLicensePlateDialogSettings()
						self.licensePlateData.defaultPlacementIndex = defaultPlacementIndex
						self.licensePlateData.hasFrontPlate = hasFrontPlate
					else
						self.licensePlateData = g_currentMission:getLastCreatedLicensePlate() or g_licensePlateManager:getRandomLicensePlateData()
					end
				end
			end
		else
			self.licensePlateData = g_currentMission:getLastCreatedLicensePlate() or g_licensePlateManager:getRandomLicensePlateData()
		end
	end
	self:processStoreItemConfigurations(storeItem, vehicle, saleItem)
	self:updateDisplay(storeItem, vehicle, saleItem)
	self:resetCamera()
end
function ShopConfigScreen:setRequestExitCallback(callback)
	self.requestExitCallback = callback or NO_CALLBACK
end
function ShopConfigScreen:setConfigPrice(configName, configIndex, priceTextElement, vehicle)
	local configItems = self.storeItem.configurations[configName]
	local price = configItems[configIndex].price
	if vehicle ~= nil then
		if ConfigurationUtil.hasBoughtConfiguration(vehicle, configName, configIndex) then
			price = 0
		end
	elseif self.saleItem ~= nil then
		if ConfigurationUtil.hasBoughtConfiguration(self.saleItem, configName, configIndex) then
			price = 0
		end
	end
	priceTextElement:setText("+" .. g_i18n:formatMoney(price) .. "")
	priceTextElement:setVisible(true)
end
function ShopConfigScreen:onPickColor(colorIndex, args, customColor, noUpdate)
	local configName = args.configName
	local colorOptionIndex = args.colorOptionIndex
	local element = self.colorElements[colorOptionIndex]
	if customColor ~= nil then
		local isValid = true
		local configItems = self.storeItem.configurations[configName]
		for index, configItem in pairs(configItems) do
			if configItem.isCustomColor then
				colorIndex = index
				isValid = true
				break
			end
		end
		if isValid then
			if self.configurationData[configName] == nil then
				self.configurationData[configName] = {}
			end
			self.configurationData[configName][colorIndex] = {}
			self.configurationData[configName][colorIndex].color = { customColor.customColor[1], customColor.customColor[2], customColor.customColor[3] }
			self.configurationData[configName][colorIndex].materialTemplateName = customColor.templateName
		end
	end
	if colorIndex ~= nil then
		self.configurations[configName] = colorIndex
		local config = self.storeItem.configurations[configName][colorIndex]
		local color = config.uiColor or config.color
		local materialTemplateName = config.materialTemplateName
		if self.configurationData[configName] ~= nil then
			local data = self.configurationData[configName][colorIndex]
			if data ~= nil then
				color = data.color or color
				materialTemplateName = data.materialTemplateName or materialTemplateName
			end
		end
		local isMetallic, isMat = g_vehicleMaterialManager:getMaterialTemplateFinish(materialTemplateName)
		isMetallic = isMetallic or config.isMetallic
		isMat = isMat or config.isMat
		element:getDescendantByName("colorImageGlossy"):setVisible(not (isMetallic or isMat))
		element:getDescendantByName("colorImageMetallic"):setVisible(isMetallic)
		element:getDescendantByName("colorImageMatte"):setVisible(isMat)
		if ColorPickButtonElement.BRIGHTNESS_THRESHOLD <= MathUtil.getBrightnessFromColor(unpack(color)) then
			element:getDescendantByName("colorImageGlossy"):setImageColor(nil, 0, 0, 0)
			element:getDescendantByName("colorImageMetallic"):setImageColor(nil, 0, 0, 0)
			element:getDescendantByName("colorImageMatte"):setImageColor(nil, 0, 0, 0)
		else
			element:getDescendantByName("colorImageGlossy"):setImageColor(nil, 1, 1, 1)
			element:getDescendantByName("colorImageMetallic"):setImageColor(nil, 1, 1, 1)
			element:getDescendantByName("colorImageMatte"):setImageColor(nil, 1, 1, 1)
		end
		local r, g, b = unpack(color)
		element:getDescendantByName("colorImage"):setImageColor(nil, math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
		local priceElement = element.parent:getDescendantByName("price")
		self:setConfigPrice(configName, colorIndex, priceElement, self.vehicle)
		if not noUpdate then
			self:updateData(self.storeItem, self.vehicle, self.saleItem)
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
		end
	end
end
function ShopConfigScreen:selectFirstConfig()
	local _v1 = self.configurationLayout
	local firstElement = _v1.elements[1]
	if firstElement ~= nil then
		local focusElement = firstElement:getDescendantByName("option")
		focusElement = _v1
		if focusElement == nil or not focusElement:getIsVisible() then
			focusElement = firstElement:getDescendantByName("yesNoOption")
		end
		focusElement = focusElement ~= nil and focusElement:getIsVisible() or firstElement:getDescendantByName("color")
		focusElement:getIsVisible()
		firstElement:getDescendantByName("button")
		FocusManager:unsetFocus(focusElement)
		FocusManager:setFocus(focusElement)
	else
		FocusManager:unsetFocus(FocusManager:getFocusedElement())
		FocusManager.currentFocusData.focusElement = nil
	end
end
function ShopConfigScreen:processStoreItemConfigurationSet(storeItem, configSet, vehicle, saleItem)
	local options = {}
	local configurationTypes = g_vehicleConfigurationManager:getSortedConfigurationTypes()
	for _, configName in ipairs(configurationTypes) do
		if g_vehicleConfigurationManager:getConfigurationSelectorType(configName) == ConfigurationUtil.SELECTOR_COLOR then
			continue
		end
		local items = storeItem.configurations[configName]
		local subConfigItems = storeItem.subConfigurations[configName]
		if subConfigItems ~= nil then
			if 1 < #subConfigItems.subConfigValues then
				local option = self:processStoreItemSubConfigurationOption(storeItem, configName, vehicle, saleItem)
				table.insert(options, option)
			else
				if items == nil then
					continue
				end
				if 1 < #items and configSet.configurations[configName] == nil then
					local option = self:processStoreItemConfigurationOption(storeItem, configName, items, vehicle, nil, saleItem)
					table.insert(options, option)
				end
			end
		end
	end
	return options
end
function ShopConfigScreen:processStoreItemSubConfigurationOption(storeItem, configName, vehicle, saleItem)
	local subConfig = storeItem.subConfigurations[configName]
	local texts = {}
	local icons = {}
	local subConfigOptions = {}
	local subConfigSelection = { name = configName, texts = texts, subConfigOptions = subConfigOptions }
	subConfigSelection.title = g_vehicleConfigurationManager:getConfigurationDescByName(configName).subConfigurationTitle
	subConfigSelection.selectedIndex = 1
	subConfigSelection.isSubConfiguration = true
	local initialIndex = StoreItemUtil.getSubConfigurationIndex(storeItem, configName, self.configurations[configName] or 1)
	if vehicle ~= nil then
		initialIndex = StoreItemUtil.getSubConfigurationIndex(storeItem, configName, vehicle.configurations[configName])
	end
	subConfigSelection.selectedIndex = initialIndex
	self.subConfigurations[configName] = initialIndex
	for i, name in pairs(subConfig.subConfigValues) do
		if type(name) == "table" then
			table.insert(subConfigSelection.texts, name.title)
			table.insert(icons, name.icon)
		else
			table.insert(subConfigSelection.texts, name)
		end
		local items = StoreItemUtil.getSubConfigurationItems(storeItem, configName, i)
		local subConfigOption = self:processStoreItemConfigurationOption(storeItem, configName, items, vehicle, true, saleItem)
		table.insert(subConfigSelection.subConfigOptions, subConfigOption)
	end
	if 0 < #icons then
		subConfigSelection.icons = icons
	end
	return subConfigSelection
end
function ShopConfigScreen:processStoreItemConfigurationOption(storeItem, configName, configItems, vehicle, isSubConfigOption)
	local configOption = { name = configName }
	configOption.title = g_vehicleConfigurationManager:getConfigurationAttribute(configName, "title")
	configOption.texts = {}
	configOption.icons = {}
	configOption.options = {}
	configOption.defaultIndex = 1
	local initialIndex = 1
	local overwrittenTitle = nil
	local hasValidIcons = false
	local index = 1
	for _, item in ipairs(configItems) do
		if item.isDefault then
			initialIndex = index
			configOption.defaultIndex = index
		end
		local isSelectable = item.isSelectable
		if storeItem.bundleInfo ~= nil then
			for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
				if bundleItem.preSelectedConfigurations == nil or bundleItem.preSelectedConfigurations[configName] == nil then
					continue
				end
				local preSelectedOption = bundleItem.preSelectedConfigurations[configName]
				if item.index == preSelectedOption.configValue then
					isSelectable = true
					initialIndex = index
					configOption.defaultIndex = index
				end
				if not preSelectedOption.allowChange then
					configOption.isDisabled = true
				end
				if preSelectedOption.hideOption then
					return
				end
			end
		end
		for _, otherConfigItems in pairs(storeItem.configurations) do
			for _, configItem in pairs(otherConfigItems) do
				if configItem.dependentConfigurations == nil then
					continue
				end
				for _, dependentConfiguration in pairs(configItem.dependentConfigurations) do
					if dependentConfiguration.name == configName then
						return
					end
				end
			end
		end
		overwrittenTitle = overwrittenTitle or item.overwrittenTitle
		if isSelectable then
			table.insert(configOption.texts, item.name)
			table.insert(configOption.options, item)
			if item.brandIndex ~= nil then
				local iconFilename = g_brandManager:getBrandIconByIndex(item.brandIndex)
				if iconFilename ~= nil then
					table.insert(configOption.icons, iconFilename)
					hasValidIcons = true
				end
			end
			if #configOption.icons ~= #configOption.texts then
				table.insert(configOption.icons, item.name)
			end
			index = index + 1
		end
	end
	if vehicle ~= nil then
		local vehicleConfigIndex = vehicle.configurations[configName]
		for i, item in ipairs(configItems) do
			if item.index == vehicleConfigIndex then
				initialIndex = i
				break
			end
		end
	end
	configOption.defaultIndex = initialIndex
	configOption.title = overwrittenTitle or configOption.title
	if not hasValidIcons then
		configOption.icons = nil
	end
	if #configOption.options <= 1 and not isSubConfigOption then
		return
	end
	return configOption
end
function ShopConfigScreen:processStoreItemColorOption(storeItem, configName, colorItems, colorPickerIndex, vehicle, saleItem)
	local overwrittenTitle = nil
	for _, item in ipairs(colorItems) do
		overwrittenTitle = overwrittenTitle or item.overwrittenTitle
	end
	table.insert(self.colorPickers, { configName = configName, colorItems = colorItems, title = overwrittenTitle or g_vehicleConfigurationManager:getConfigurationAttribute(configName, "title") })
end
function ShopConfigScreen:processStoreItemConfigurations(storeItem, vehicle, saleItem)
	self.configSelection = { title = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIGURATION_LABEL), texts = {}, prices = {}, options = {} }
	self.currentConfigSet = 1
	local configSets = storeItem.configurationSets
	if #configSets == 0 then
		local defaultSet = { name = "", configurations = {}, isDefault = true }
		configSets = { defaultSet }
	end
	if storeItem.configurations ~= nil then
		for i, configSet in ipairs(configSets) do
			if configSet.isDefault then
				self.currentConfigSet = i
			end
			if configSet.overwrittenTitle ~= nil then
				self.configSelection.title = configSet.overwrittenTitle
			end
			local price = 0
			for name, index in pairs(configSet.configurations) do
				local alreadyInOwnedVehicle = false
				if self.vehicle ~= nil then
					alreadyInOwnedVehicle = ConfigurationUtil.hasBoughtConfiguration(self.vehicle, name, index)
				end
				local alreadyInSaleVehicle = false
				if self.saleItem ~= nil then
					alreadyInSaleVehicle = ConfigurationUtil.hasBoughtConfiguration(self.saleItem, name, index)
				end
				if alreadyInOwnedVehicle or alreadyInSaleVehicle then
					continue
				end
				price = price + storeItem.configurations[name][index].price
			end
			table.insert(self.configSelection.prices, price)
			table.insert(self.configSelection.texts, configSet.name)
			local setOptions = self:processStoreItemConfigurationSet(storeItem, configSet, vehicle, saleItem)
			table.insert(self.configSelection.options, setOptions)
		end
		if 0 < #configSets then
			if saleItem ~= nil then
				self.currentConfigSet = saleItem.configSetIndex or self.currentConfigSet
			end
			if vehicle ~= nil then
				local closestSet, _ = ConfigurationUtil.getClosestConfigurationSet(vehicle.configurations, configSets)
				if closestSet ~= nil then
					self.currentConfigSet = closestSet.index
				end
			end
		end
		for name, index in pairs(configSets[self.currentConfigSet].configurations) do
			self.configurations[name] = index
		end
		self.colorPickers = {}
		local colorPickerIndex = 1
		local configurations = g_vehicleConfigurationManager:getSortedConfigurationTypes()
		for i = 1, #configurations do
			local configName = configurations[i]
			local configItems = storeItem.configurations[configName]
			if storeItem.configurations[configName] == nil then
				continue
			end
			local isColor = g_vehicleConfigurationManager:getConfigurationSelectorType(configName) == ConfigurationUtil.SELECTOR_COLOR
			if 1 < #configItems and isColor then
				self:processStoreItemColorOption(storeItem, configName, configItems, colorPickerIndex, vehicle, saleItem)
				colorPickerIndex = colorPickerIndex + 1
			end
		end
		self.displayableColorCount = colorPickerIndex - 1
	else
		table.insert(self.configSelection.options, {})
		self.displayableColorCount = 0
	end
	if storeItem.bundleInfo ~= nil then
		for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
			if bundleItem.preSelectedConfigurations == nil then
				continue
			end
			for configName, preSelectedOption in pairs(bundleItem.preSelectedConfigurations) do
				self.configurations[configName] = preSelectedOption.configValue
			end
		end
	end
end
function ShopConfigScreen:getOrCreateConfigItem(type)
	local item = nil
	if #self.configItemCache == 0 then
		item = self.configurationItemTemplate:clone(self.configurationLayout)
	else
		item = self.configItemCache[#self.configItemCache]
		self.configItemCache[#self.configItemCache] = nil
		self.configurationLayout:addElement(item)
	end
	item.isLargeConfigItem = false
	item:setVisible(true)
	item.focusId = nil
	local option = false
	local color = false
	local yesNoOption = false
	local price = true
	local focusableElement = nil
	if type == "option" then
		option = true
		focusableElement = item:getDescendantByName("option")
	elseif type == "color" then
		color = true
		focusableElement = item:getDescendantByName("color")
	elseif type == "yesNoOption" then
		yesNoOption = true
		focusableElement = item:getDescendantByName("yesNoOption")
	end
	item:getDescendantByName("option"):setVisible(option)
	item:getDescendantByName("color"):setVisible(color)
	item:getDescendantByName("yesNoOption"):setVisible(yesNoOption)
	item:getDescendantByName("price"):setVisible(true)
	if focusableElement ~= nil then
		focusableElement.forceFocusScrollToTop = self.focusableElementForScroll == nil
		self.focusableElementForScroll = focusableElement
		item:getDescendantByName("title").getIsSelected = function()
			return focusableElement:getIsFocused()
		end
	end
	return item
end
function ShopConfigScreen:getOrCreateLargeConfigItem(type)
	local item = nil
	if #self.configItemCacheLarge == 0 then
		item = self.configurationItemTemplateLarge:clone(self.configurationLayout)
	else
		item = self.configItemCacheLarge[#self.configItemCacheLarge]
		self.configItemCacheLarge[#self.configItemCacheLarge] = nil
		self.configurationLayout:addElement(item)
	end
	item.isLargeConfigItem = true
	item:setVisible(true)
	item.focusId = nil
	local focusableElement = item:getDescendantByName("option")
	focusableElement.forceFocusScrollToTop = self.focusableElementForScroll == nil
	self.focusableElementForScroll = focusableElement
	item:getDescendantByName("title").getIsSelected = function()
		return focusableElement:getIsFocused()
	end
	return item
end
function ShopConfigScreen:getDefaultConfigIndexByName(configName) end
function ShopConfigScreen:updateConfigSetOptionElement(configElementIndex, storeItem, vehicle, saleItem)
	local isYesNoOption = false
	if 1 < #storeItem.configurationSets then
		isYesNoOption = storeItem.configurationSets[1].isYesNoOption
	end
	local listElement = self:getOrCreateConfigItem(isYesNoOption and "yesNoOption" or "option")
	local optionElement = nil
	if isYesNoOption then
		optionElement = listElement:getDescendantByName("yesNoOption")
		optionElement:setIsChecked(self.currentConfigSet ~= 1, true)
		optionElement:setTexts(self.configSelection.texts)
	else
		optionElement = listElement:getDescendantByName("option")
		optionElement:setTexts(self.configSelection.texts)
		optionElement:setState(self.currentConfigSet)
	end
	optionElement:setDisabled(false)
	function optionElement.onClickCallback(_, configSetIndex)
		for name, _ in pairs(storeItem.configurationSets[self.currentConfigSet].configurations) do
			self.configurations[name] = ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[name])
		end
		for name, index in pairs(storeItem.configurationSets[configSetIndex].configurations) do
			self.configurations[name] = index
		end
		self.currentConfigSet = configSetIndex
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateDisplay(storeItem, vehicle, saleItem)
		self:selectFirstConfig()
	end
	listElement:getDescendantByName("title"):setText(self.configSelection.title)
	local price = self.configSelection.prices[self.currentConfigSet]
	listElement:getDescendantByName("price"):setText("+" .. g_i18n:formatMoney(price))
end
function ShopConfigScreen:updateConfigOptionElement(configElementIndex, option, storeItem, vehicle, saleItem)
	local hasIcons = option.icons ~= nil
	local hasText = not hasIcons
	local isYesNoOption = false
	if 1 < #option.options then
		isYesNoOption = option.options[1].isYesNoOption
		if isYesNoOption then
			hasIcons = false
			hasText = false
		end
	end
	local listElement = nil
	if hasIcons then
		listElement = self:getOrCreateLargeConfigItem("option")
	elseif hasText then
		listElement = self:getOrCreateConfigItem("option")
	elseif isYesNoOption then
		listElement = self:getOrCreateConfigItem("yesNoOption")
	end
	local optionElement = listElement:getDescendantByName(isYesNoOption and "yesNoOption" or "option")
	optionElement:setVisible(true)
	optionElement:setDisabled(true)
	if hasIcons then
		optionElement:setIcons(option.icons)
	elseif hasText then
		optionElement:setTexts(option.texts)
	elseif isYesNoOption then
		optionElement:setTexts(option.texts)
	end
	local priceElement = listElement:getDescendantByName("price")
	local configName = option.name
	local configIndex = 0
	for i, item in pairs(option.options) do
		if item.index == self.configurations[configName] then
			configIndex = i
			break
		end
	end
	if configIndex == 0 or option.options[configIndex] == nil then
		configIndex = option.defaultIndex
	end
	if isYesNoOption then
		optionElement:setIsChecked(configIndex ~= 1, true)
	else
		optionElement:setState(configIndex)
	end
	function optionElement.onClickCallback(_, optionIndex)
		local selectedConfigIndex = option.options[optionIndex].index
		self:setConfigPrice(configName, selectedConfigIndex, priceElement, vehicle)
		self.configurations[configName] = selectedConfigIndex
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateData(storeItem, self.vehicle, self.saleItem)
	end
	local index = nil
	if option.options[configIndex] ~= nil then
		index = option.options[configIndex].index
	else
		index = option.defaultIndex
	end
	self.configurations[configName] = index
	self.configurationToListElement[configName] = listElement
	listElement:getDescendantByName("title"):setText(option.title)
	self:setConfigPrice(configName, index, priceElement, vehicle)
end
function ShopConfigScreen:updateSubConfigOptionElement(configElementIndex, option, storeItem, vehicle, saleItem)
	local hasIcons = option.icons ~= nil
	local listElement = nil
	if hasIcons then
		listElement = self:getOrCreateLargeConfigItem("option")
	else
		listElement = self:getOrCreateConfigItem("option")
	end
	local optionElement = listElement:getDescendantByName("option")
	optionElement:setVisible(true)
	optionElement:setDisabled(false)
	if hasIcons then
		optionElement:setIcons(option.icons)
	else
		optionElement:setTexts(option.texts)
	end
	local configName = option.name
	local subConfigIndex = self.subConfigurations[configName] or option.defaultIndex
	self.subConfigurations[configName] = subConfigIndex
	option.selectedIndex = subConfigIndex
	optionElement:setState(subConfigIndex)
	function optionElement.onClickCallback(_, state)
		self.subConfigurations[configName] = state
		option.selectedIndex = state
		local subConfigOptionIndex = option.subConfigOptions[state].defaultIndex
		self.configurations[configName] = subConfigOptionIndex
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
		self:updateData(storeItem, self.vehicle, saleItem)
		FocusManager:unsetFocus(optionElement)
		FocusManager:setFocus(optionElement)
	end
	listElement:getDescendantByName("price"):setVisible(false)
	listElement:getDescendantByName("title"):setText(option.title)
end
function ShopConfigScreen:updateConfigOptionsData(storeItem, vehicle, saleItem)
	if self.licensePlate ~= nil then
		self.licensePlate:delete()
		self.licensePlate = nil
	end
	self.configurationToListElement = {}
	local displayableOptionCount = 0
	local count = 0
	for i = #self.configurationLayout.elements, 1, -1 do
		local item = self.configurationLayout.elements[i]
		item:setVisible(false)
		FocusManager:removeElement(item)
		item:unlinkElement()
		if item == self.configurationItemPlate then
			continue
		end
		if item.isLargeConfigItem then
			table.insert(self.configItemCacheLarge, item)
		else
			table.insert(self.configItemCache, item)
		end
	end
	self.focusableElementForScroll = nil
	if 1 < #self.configSelection.options then
		displayableOptionCount = displayableOptionCount + 1
		count = 1
		self:updateConfigSetOptionElement(1, storeItem, vehicle, saleItem)
	end
	local optionData = self.configSelection.options[self.currentConfigSet]
	for _, option in ipairs(optionData) do
		displayableOptionCount = displayableOptionCount + 1
		count = count + 1
		if option.isSubConfiguration then
			self:updateSubConfigOptionElement(count, option, storeItem, vehicle, saleItem)
		else
			self:updateConfigOptionElement(count, option, storeItem, vehicle, saleItem)
		end
		if option.isSubConfiguration then
			displayableOptionCount = displayableOptionCount + 1
			count = count + 1
			local subOption = option.subConfigOptions[option.selectedIndex]
			self:updateConfigOptionElement(count, subOption, storeItem, vehicle, saleItem)
		end
	end
	local configSets = storeItem.configurationSets
	local currentConfigSet = configSets[self.currentConfigSet]
	self.colorElements = {}
	if 0 < self.displayableColorCount then
		for i, option in ipairs(self.colorPickers) do
			local visibility = true
			if currentConfigSet ~= nil and currentConfigSet.configurations[option.configName] ~= nil then
				visibility = false
			end
			if storeItem.bundleInfo ~= nil then
				for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
					if bundleItem.preSelectedConfigurations == nil or bundleItem.preSelectedConfigurations[option.configName] == nil then
						continue
					end
					local preSelectedOption = bundleItem.preSelectedConfigurations[option.configName]
					if preSelectedOption.hideOption then
						visibility = false
					end
				end
			end
			local itemsToDisplay = 0
			local hasCustomColorSupport = false
			for j = 1, #option.colorItems do
				if option.colorItems[j].isSelectable ~= false then
					itemsToDisplay = itemsToDisplay + 1
				end
				if option.colorItems[j].isCustomColor then
					hasCustomColorSupport = true
				end
			end
			visibility = visibility and 1 < itemsToDisplay
			if visibility then
				local listElement = self:getOrCreateConfigItem("color")
				local colorElement = listElement:getDescendantByName("color")
				self.colorElements[i] = colorElement
				local colorItems = option.colorItems
				function colorElement.onClickCallback(sourceElement)
					local configIndex = self.configurations[option.configName]
					local customColor = nil
					local customMaterialTemplateName = nil
					local data = self.configurationData[option.configName]
					if data ~= nil and data[configIndex] ~= nil then
						customColor = data[configIndex].color or customColor
						customMaterialTemplateName = data[configIndex].materialTemplateName
						configIndex = nil
					end
					g_inputBinding:setShowMouseCursor(true)
					ColorPickerDialog.show(self.onPickColor, self, { configName = option.configName, colorOptionIndex = i }, colorItems, configIndex, customMaterialTemplateName, customColor, hasCustomColorSupport, true)
				end
				local defaultColorIndex = self.configurations[option.configName] or self:getDefaultConfigurationColorIndex(option.configName, colorItems, vehicle)
				self:onPickColor(defaultColorIndex, { colorOptionIndex = i, configName = option.configName }, nil, true)
				listElement:getDescendantByName("title"):setText(option.title)
				count = count + 1
			end
		end
	end
	if storeItem.hasLicensePlates and g_licensePlateManager:getAreLicensePlatesAvailable() then
		self.configurationLayout:addElement(self.configurationItemPlate)
		self.configurationItemPlate:setVisible(true)
		self.configurationItemPlate:reloadFocusHandling(true)
		self:updateLicensePlate()
		local focusableElement = self.configurationItemPlate:getDescendantByName("button")
		if focusableElement ~= nil then
			focusableElement.forceFocusScrollToTop = self.focusableElementForScroll == nil
			self.focusableElementForScroll = focusableElement
			self.configurationItemPlate:getDescendantByName("title").getIsSelected = function()
				return focusableElement:getIsFocused()
			end
		end
		count = count + 1
	end
	self.displayableOptionCount = displayableOptionCount
	return count
end
function ShopConfigScreen:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
	local current = FocusManager.currentGui
	FocusManager:setGui("ShopConfigScreen")
	local num = self:updateConfigOptionsData(storeItem, vehicle, saleItem)
	self.configurationsTitle:setVisible(0 < num)
	self.startClipper:setVisible(0 < num)
	self.endClipper:setVisible(0 < num)
	self.configSlider.parent:setVisible(0 < num)
	self.configurationLayout:invalidateLayout()
	FocusManager:setGui(current)
	if self.needsRefocus then
		self:selectFirstConfig()
		self.needsRefocus = false
	end
end
function ShopConfigScreen:update(dt)
	ShopConfigScreen:superClass().update(self, dt)
	if self.vehicle ~= nil and self.vehicle.isDeleted then
		self:onClickBack()
		self.vehicle = nil
		return
	end
	if not self.fadeInAnimation:getFinished() then
		self.fadeInAnimation:update(dt)
	end
	if not self.fadeOutAnimation:getFinished() then
		self.fadeOutAnimation:update()
	end
	if self.lastMoney ~= g_currentMission:getMoney() then
		self:updateBalanceText()
	end
	if 0 < self.loadingDelayTime or 0 < self.loadingDelayFrames then
		self.loadingDelayFrames = math.max(self.loadingDelayFrames - 1, 0)
		self.loadingDelayTime = math.max(self.loadingDelayTime - dt, 0)
		if self.loadingDelayTime <= 0 and self.loadingDelayFrames <= 0 then
			self:onFinishedLoading()
		end
	end
	for _, vehicle in pairs(self.previewVehicles) do
		vehicle:update(dt)
		vehicle:updateTick(dt)
	end
	g_shopController:update(dt)
	self:updateInput(dt)
	self:updateCamera(dt)
	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		for i, vehicle in pairs(self.previewVehicles) do
			local component = vehicle.components[1]
			if component == nil then
				continue
			end
			local x, y, z = getWorldTranslation(component.node)
			local rx, ry, rz = getWorldRotation(component.node)
			renderText(0.35, 0.05 + (i - 1) * 0.02, 0.015, string.format("Vehicle Position: Translation: %.3f %.3f %.3f Rotation: %.3f %.3f %.3f (%s)", x, y + 100, z, math.deg(rx), math.deg(ry), math.deg(rz), vehicle:getName()))
		end
	else
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			for _, vehicle in pairs(self.previewVehicles) do
				if vehicle.updateAIMarkerWidth == nil then
					continue
				end
				vehicle:updateAIMarkerWidth()
				local _, _, _, _, aiMarkerWidth = vehicle:getAIMarkers()
				local canTurnBackward = AIVehicleUtil.getAttachedImplementsAllowTurnBackward(vehicle)
				local allowStraightReversing = vehicle:getAIToolReverserDirectionNode() ~= nil
				setTextBold(true)
				renderText(0.35, 0.11, 0.015, "Field Course:")
				if 0 < aiMarkerWidth then
					renderText(0.35, 0.09, 0.015, string.format("Width: %.1f", aiMarkerWidth))
					if canTurnBackward then
						setTextColor(0, 1, 0, 1)
					elseif not allowStraightReversing then
						setTextColor(1, 0, 0, 1)
					else
						setTextColor(1, 1, 1, 1)
					end
					renderText(0.35, 0.07, 0.015, string.format("Turn Backward: %s", canTurnBackward and "Yes" or "No"))
					if allowStraightReversing then
						setTextColor(0, 1, 0, 1)
					elseif not canTurnBackward then
						setTextColor(1, 0, 0, 1)
					else
						setTextColor(1, 1, 1, 1)
					end
					renderText(0.35, 0.05, 0.015, string.format("Straight Reversing: %s", allowStraightReversing and "Yes" or "No"))
				else
					renderText(0.35, 0.09, 0.015, "Not supported")
				end
				setTextColor(1, 1, 1, 1)
				setTextBold(false)
			end
		end
	end
end
function ShopConfigScreen:updateCamera(dt)
	setTranslation(self.rotateNode, self.workshopWorldPosition[1], self.workshopWorldPosition[2] + self.focusY, self.workshopWorldPosition[3])
	setRotation(self.rotateNode, self.rotX, self.rotY, 0)
	local camPosX, camPosY, camPosZ = getWorldTranslation(self.cameraPositionNode)
	local targetPosX, targetPosY, targetPosZ = getWorldTranslation(self.rotateNode)
	local dx, dy, dz = MathUtil.vector3Normalize(targetPosX - camPosX, targetPosY - camPosY, targetPosZ - camPosZ)
	local posX = targetPosX - dx * self.cameraDistance
	local posY = targetPosY - dy * self.cameraDistance
	local posZ = targetPosZ - dz * self.cameraDistance
	local lx, ly, lz = worldToLocal(self.rotateNode, posX, posY, posZ)
	setTranslation(self.cameraPositionNode, lx, ly, lz)
	local projectionOffsetX = -0.15625
	if not self.shopConfigContent.parent:getIsVisible() then
		projectionOffsetX = 0
	end
	local direction = 1
	local ratio = self.vehicleSizeX / self.vehicleSizeZ
	if self.vehicleSizeZ < self.vehicleSizeX then
		direction = -1
		ratio = self.vehicleSizeZ / self.vehicleSizeX
	end
	ratio = 1 - math.clamp(ratio, 0, 1)
	local doublePi = 6.283185307179586
	local cameraAlpha = self.rotY % 6.283185307179586 / 6.283185307179586
	local offsetFactor = 0
	if 0 <= cameraAlpha then
		if cameraAlpha < 0.25 then
			offsetFactor = cameraAlpha / 0.125
			if 1 < offsetFactor then
				offsetFactor = 1 - (offsetFactor - 1)
			end
		elseif 0.25 <= cameraAlpha then
			if cameraAlpha < 0.5 then
				offsetFactor = (cameraAlpha - 0.25) / 0.125
				if 1 < offsetFactor then
					offsetFactor = 1 - (offsetFactor - 1)
				end
				offsetFactor = -offsetFactor
			elseif 0.5 <= cameraAlpha then
				if cameraAlpha < 0.75 then
					offsetFactor = (cameraAlpha - 0.5) / 0.125
					if 1 < offsetFactor then
						offsetFactor = 1 - (offsetFactor - 1)
					end
				elseif 0.75 <= cameraAlpha then
					if cameraAlpha < 1 then
						offsetFactor = (cameraAlpha - 0.75) / 0.125
						if 1 < offsetFactor then
							offsetFactor = 1 - (offsetFactor - 1)
						end
						offsetFactor = -offsetFactor
					end
				end
			end
		end
	end
	projectionOffsetX = projectionOffsetX - offsetFactor * 0.1 * direction * ratio
	setProjectionOffset(self.cameraNode, projectionOffsetX, 0.07)
end
function ShopConfigScreen:draw()
	ShopConfigScreen:superClass().draw(self)
	if self.fadeOverlay.visible then
		self.fadeOverlay:render()
	end
end
function ShopConfigScreen:onRenderLoad(scene, overlay)
	setName(scene, "ShopConfigScreen_" .. getName(scene))
	self.licensePlaceLinkNode = I3DUtil.indexToObject(scene, "0|0")
end
function ShopConfigScreen:updateLicensePlate()
	if self.licensePlateRender ~= nil and self.licensePlaceLinkNode ~= nil then
		local licensePlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
		if licensePlate ~= nil then
			link(self.licensePlaceLinkNode, licensePlate.node)
			setTranslation(licensePlate.node, 0, 0, 0)
			setRotation(licensePlate.node, 0, 0, 0)
			if self.licensePlate ~= nil then
				self.licensePlate:delete()
			end
			self.licensePlate = licensePlate
			self:updateLicensePlateGraphics()
			local cameraNode = I3DUtil.indexToObject(self.licensePlateRender.scene, self.licensePlateRender.cameraPath)
			if cameraNode ~= nil then
				local fovY = getFovY(cameraNode)
				local tolerance = 0.005
				local distance = (self.licensePlate.width / 2 + 0.005) / math.tan(fovY / 2) / (self.licensePlateRender.absSize[1] * (licensePlate.width / licensePlate.height / 5) / self.licensePlateRender.absSize[2] * g_screenAspectRatio)
				setTranslation(cameraNode, 0, 0, distance)
			end
		end
	end
end
function ShopConfigScreen:updateLicensePlateGraphics()
	local currentVariation = self.licensePlateData.variation or 1
	local currentColorIndex = self.licensePlateData.colorIndex or 1
	local currentCharacters = table.clone(self.licensePlateData.characters, math.huge)
	if self.licensePlate ~= nil then
		self.licensePlate:updateData(currentVariation, LicensePlateManager.PLATE_POSITION.BACK, table.concat(currentCharacters, ""))
		self.licensePlate:setColorIndex(currentColorIndex)
		self.licensePlateRender:setRenderDirty()
	end
	if #self.previewVehicles == 0 then
		self.licensePlateRender.parent:setText("")
		self.licensePlateRender:setVisible(false)
	elseif self.licensePlateData.placementIndex == LicensePlateManager.PLATE_POSITION.NONE then
		self.licensePlateRender.parent:setText(g_i18n:getText("configuration_valueLicensePlateNone"))
		self.licensePlateRender:setVisible(false)
	else
		self.licensePlateRender.parent:setText("")
		self.licensePlateRender:setVisible(true)
	end
end
function ShopConfigScreen:onOpen(element)
	ShopConfigScreen:superClass().onOpen(self)
	self.openCounter = self.openCounter + 1
	local posX, posY = unpack(self.configurationsBox.absPosition)
	local width, height = unpack(self.configurationsBox.absSize)
	g_depthOfFieldManager:pushArea(posX, posY, width, height)
	self:onMoneyChange()
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
	g_gameStateManager:setGameState(GameState.MENU_SHOP_CONFIG)
	g_currentMission.environment:setCustomLighting(self.shopLighting)
	g_currentMission.environment:setSunVisibility(false)
	setVisibility(self.workshopRootNode, true)
	self.previousCamera = g_cameraManager:getActiveCamera()
	g_cameraManager:setActiveCamera(self.cameraNode)
	self:updateInputGlyphs()
	self:toggleCustomInputContext(true, ShopConfigScreen.INPUT_CONTEXT_NAME)
	self:registerInputActions()
	self.needsRefocus = true
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end
function ShopConfigScreen:onClose()
	self.isLoadingInitial = false
	ShopConfigScreen:superClass().onClose(self)
	g_currentMission.environment:setSunVisibility(true)
	g_currentMission.environment:setCustomLighting(nil)
	g_cameraManager:setActiveCamera(self.previousCamera)
	setVisibility(self.workshopRootNode, false)
	self:deletePreviewVehicles()
	if self.licensePlate ~= nil then
		self.licensePlate:delete()
		self.licensePlate = nil
	end
	self.vehicle = nil
	self.loadingDelayFrames = 0
	self.loadingDelayTime = 0
	g_currentMission:resetGameState()
	self.fadeInAnimation:reset()
	g_depthOfFieldManager:popArea()
	g_messageCenter:unsubscribe(MessageType.MONEY_CHANGED, self)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, true)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, true)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, true)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, true)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, true)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, true)
	self:toggleCustomInputContext(false)
end
function ShopConfigScreen:onClickBuy()
	local _, _, hasChanges = self:getConfigurationCostsAndChanges(self.storeItem, self.vehicle, self.saleItem)
	if not hasChanges then
		return
	end
	local enoughMoney = 0 >= self.totalPrice or self.totalPrice <= g_currentMission:getMoney()
	local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(self.storeItem)
	g_inputBinding:setShowMouseCursor(true)
	if not enoughMoney then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY), nil, nil, DialogElement.TYPE_WARNING, nil, nil, nil, true)
	elseif not enoughSlots then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS), nil, nil, DialogElement.TYPE_WARNING, nil, nil, nil, true)
	else
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		local text = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), g_i18n:formatMoney(self.totalPrice, 0, true, true))
		local callback = self.onYesNoBuy
		YesNoDialog.show(callback, self, text, nil, nil, nil, nil, nil, nil, nil, true)
	end
end
function ShopConfigScreen:onClickConfigAction()
	if self.focusedColorElement ~= nil then
		self.focusedColorElement:onFocusActivate()
	else
		if self.focusedButtonElement ~= nil then
			self.focusedButtonElement:onFocusActivate()
		end
	end
end
function ShopConfigScreen:onClickLicensePlate()
	LicensePlateDialog.show(self.licensePlateData, self.onChangeLicensePlate, self)
end
function ShopConfigScreen:onChangeLicensePlate(licensePlateData)
	if licensePlateData ~= nil then
		self.licensePlateData = licensePlateData
		self.licensePlateData.customized = true
		for i = 1, #self.previewVehicles do
			local vehicle = self.previewVehicles[i]
			if vehicle.setLicensePlatesData == nil then
				continue
			end
			vehicle:setLicensePlatesData(self.licensePlateData)
		end
		self:updateLicensePlateGraphics()
		self:updateData(self.storeItem, self.vehicle, self.saleItem)
	end
end
function ShopConfigScreen:onFocusConfigurationOption(element)
	self.focusedColorElement = nil
	self.focusedButtonElement = nil
	self.focusedOptionElement = nil
	if element.name == "button" then
		self.focusedButtonElement = element
	elseif element.name == "color" then
		self.focusedColorElement = element
	elseif element.name == "option" then
		self.focusedOptionElement = element
	elseif element.name == "yesNoOption" then
		self.focusedOptionElement = element
	end
	self:updateConfigurationButton()
end
function ShopConfigScreen:onLeaveConfigurationOption(element)
	self.focusedColorElement = nil
	self.focusedButtonElement = nil
	self.focusedOptionElement = nil
	self:updateConfigurationButton()
end
function ShopConfigScreen:updateConfigurationButton()
	local visible = self.focusedButtonElement ~= nil or self.focusedColorElement ~= nil
	self.configButton:setVisible(visible)
	self.buttonsPanel:invalidateLayout()
end
function ShopConfigScreen:onYesNoBuy(yes)
	if yes then
		self:onCallback(false)
	end
end
function ShopConfigScreen:onVehicleBought()
	if not GS_IS_CONSOLE_VERSION then
		FocusManager:setFocus(self.buyButton)
	else
		self:selectFirstConfig()
	end
end
function ShopConfigScreen:onStoreItemsReloaded()
	if self.storeItem ~= nil and g_gui.currentGuiName == "ShopConfigScreen" then
		self.needsRefocus = true
		self.storeItem = g_storeManager:getItemByXMLFilename(self.storeItem.xmlFilename)
		self:setStoreItem(self.storeItem, nil, nil, nil, self.configurations)
	end
end
function ShopConfigScreen:onClickLease()
	if self.vehicle ~= nil then
		return
	end
	if not self.storeItem.allowLeasing then
		return
	end
	local enoughMoney = self.initialLeasingCosts <= g_currentMission:getMoney()
	local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(self.storeItem)
	g_inputBinding:setShowMouseCursor(true)
	if not enoughMoney then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_LEASE), nil, nil, DialogElement.TYPE_WARNING)
	elseif not enoughSlots then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS), nil, nil, DialogElement.TYPE_WARNING)
	else
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		local costsBase = self.totalPrice * EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR
		local initialCosts = self.initialLeasingCosts
		local costsPerOperatingHour = self.totalPrice * EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR
		local costsPerDay = self.totalPrice * EconomyManager.PER_DAY_LEASING_FACTOR
		LeaseYesNoDialog.show(self.onYesNoLease, self, costsBase, initialCosts, costsPerOperatingHour, costsPerDay)
	end
end
function ShopConfigScreen:onYesNoLease(yes)
	if yes then
		self:onCallback(true)
	end
end
function ShopConfigScreen:onClickShop()
	local eventUnused = ShopConfigScreen:superClass().onClickShop(self)
	if eventUnused then
		self:requestExitCallback()
		eventUnused = false
	end
	return eventUnused
end
function ShopConfigScreen:onCallback(leaseItem)
	local vehicleBuyData = BuyVehicleData.new()
	vehicleBuyData:setStoreItem(self.storeItem)
	vehicleBuyData:setConfigurations(self.configurations, self.boughtConfigurations)
	vehicleBuyData:setConfigurationData(self.configurationData)
	vehicleBuyData:setLeaseVehicle(leaseItem)
	vehicleBuyData:setOwnerFarmId(g_shopController.playerFarmId)
	vehicleBuyData:setLicensePlateData(self.licensePlateData)
	vehicleBuyData:setSaleItem(self.saleItem)
	vehicleBuyData:setPrice(leaseItem and 0 or self.totalPrice)
	local vehicleId = NetworkUtil.getObjectId(self.vehicle)
	if self.callbackFunc ~= nil then
		if self.target ~= nil then
			self.callbackFunc(self.target, vehicleBuyData, vehicleId)
		else
			self.callbackFunc(vehicleBuyData, vehicleId)
		end
		self.configurations = table.clone(self.configurations)
	end
end
function ShopConfigScreen:updateInputGlyphs()
	self.zoomGlyph:setActions({ InputAction.AXIS_MAP_ZOOM_IN, InputAction.AXIS_MAP_ZOOM_OUT })
	local platformActions = nil
	platformActions = self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and { InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, InputAction.AXIS_LOOK_UPDOWN_VEHICLE } or { InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, InputAction.AXIS_LOOK_UPDOWN_DRAG }
	self.lookGlyph:setActions(platformActions)
end
function ShopConfigScreen:toggleHUDVisible()
	local isVisible = self.shopConfigContent.parent:getIsVisible()
	if isVisible then
		g_depthOfFieldManager:popArea()
	else
		local posX, posY = unpack(self.configurationsBox.absPosition)
		local width, height = unpack(self.configurationsBox.absSize)
		g_depthOfFieldManager:pushArea(posX, posY, width, height)
	end
	self.shopConfigContent.parent:setVisible(not isVisible)
end
function ShopConfigScreen:registerInputActions()
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, false)
	local isController = g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD
	local _ = nil
	_, self.eventIdUpDownController = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, self.onCameraUpDown, false, false, true, isController)
	_, self.eventIdLeftRightController = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onCameraLeftRight, false, false, true, isController)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_IN, self, self.onCameraZoom, false, false, true, true, -1)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_OUT, self, self.onCameraZoom, false, false, true, true, 1)
	_, self.eventIdUpDownMouse = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_DRAG, self, self.onCameraUpDown, false, false, true, not isController)
	_, self.eventIdLeftRightMouse = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, self, self.onCameraLeftRight, false, false, true, not isController)
end
function ShopConfigScreen:onCameraLeftRight(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE then
		self.inputHorizontal = inputValue * -1 * 0.001 * g_currentDt
	else
		if not self.configSlider.mouseDown then
			local dragValue = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
			self.accumDraggingInput = self.accumDraggingInput + math.abs(dragValue * g_screenAspectRatio)
			if ShopConfigScreen.MIN_MOUSE_DRAG_INPUT <= self.accumDraggingInput then
				self.inputDragging = true
				self.inputHorizontal = dragValue * 0.001 * 16.666
				return
			end
			self.inputHorizontal = 0
		end
	end
end
function ShopConfigScreen:onCameraUpDown(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.AXIS_LOOK_UPDOWN_VEHICLE then
		self.inputVertical = inputValue * 0.001 * g_currentDt
	else
		if not self.configSlider.mouseDown then
			local dragValue = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
			self.accumDraggingInput = self.accumDraggingInput + math.abs(dragValue)
			if ShopConfigScreen.MIN_MOUSE_DRAG_INPUT <= self.accumDraggingInput then
				self.inputDragging = true
				self.inputVertical = dragValue * 0.001 * 16.666
				return
			end
			self.inputVertical = 0
		end
	end
end
function ShopConfigScreen:onCameraZoom(actionName, inputValue, direction, isAnalog, isMouse)
	if isMouse and self.configSlider:getIsVisible() then
		local mouseX, mouseY = g_inputBinding:getMousePosition()
		local cursorOnSlider = GuiUtils.checkOverlayOverlap(mouseX, mouseY, self.configSlider.absPosition[1], self.configSlider.absPosition[2], self.configSlider.size[1], self.configSlider.size[2])
		if cursorOnSlider then
			return
		end
		local cursorInList = GuiUtils.checkOverlayOverlap(mouseX, mouseY, self.configurationLayout.absPosition[1], self.configurationLayout.absPosition[2], self.configurationLayout.size[1], self.configurationLayout.size[2])
		if cursorInList then
			return
		end
	end
	local modifier = 0.05 * direction
	if not isAnalog then
		modifier = 0.2 * direction
		if isMouse then
			modifier = modifier * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
		end
	end
	self.inputZoom = self.inputZoom + inputValue * modifier
end
function ShopConfigScreen:updateInput(dt)
	self:updateInputContext()
	if self.inputVertical ~= 0 then
		local value = self.inputVertical
		self.inputVertical = 0
		self.rotX = self.rotX - value
	end
	if self.inputHorizontal ~= 0 then
		local value = self.inputHorizontal
		self.inputHorizontal = 0
		self.rotY = self.rotY - value
	end
	if self.inputZoom ~= 0 then
		local minDistance = self.cameraMinDistance
		local maxDistance = self.cameraMaxDistance
		self.zoomTarget = self.zoomTarget + dt * self.inputZoom * 0.1
		self.zoomTarget = math.clamp(self.zoomTarget, minDistance, maxDistance)
		self.inputZoom = 0
	end
	self.cameraDistance = self.zoomTarget + math.pow(0.99579, dt) * (self.cameraDistance - self.zoomTarget)
	self.rotX = self:limitXRotation(self.rotX)
	local inputHelpMode = g_inputBinding:getInputHelpMode()
	if inputHelpMode ~= self.lastInputHelpMode then
		self.lastInputHelpMode = inputHelpMode
		self:updateInputGlyphs()
	end
	if not self.isDragging then
		if self.inputDragging then
			self.isDragging = true
			g_inputBinding:setShowMouseCursor(false, true)
		elseif self.isDragging then
			if not self.inputDragging then
				self.isDragging = false
				g_inputBinding:setShowMouseCursor(true)
				self.accumDraggingInput = 0
			end
		end
	end
	self.inputDragging = false
end
function ShopConfigScreen:limitXRotation(currentXRotation)
	local camHeight = self.cameraDistance * math.sin(currentXRotation) + self.focusY
	local maxHeight = math.min(camHeight, ShopConfigScreen.MAX_CAMERA_HEIGHT - self.focusY)
	local rotMinX = self.rotMinX
	local rotMaxX = self.rotMaxX
	if maxHeight <= self.cameraDistance then
		rotMaxX = math.min(rotMaxX, math.asin(maxHeight / self.cameraDistance))
	end
	local minHeight = ShopConfigScreen.MIN_CAMERA_HEIGHT - self.focusY
	rotMinX = math.max(rotMinX, math.asin(minHeight / self.cameraDistance))
	return math.max(rotMinX, math.min(rotMaxX, currentXRotation))
end
function ShopConfigScreen:updateInputContext()
	local currentInputMode = g_inputBinding:getLastInputMode()
	if currentInputMode ~= self.lastInputMode then
		local isController = currentInputMode == GS_INPUT_HELP_MODE_GAMEPAD
		g_inputBinding:setActionEventActive(self.eventIdUpDownController, isController)
		g_inputBinding:setActionEventActive(self.eventIdLeftRightController, isController)
		g_inputBinding:setActionEventActive(self.eventIdUpDownMouse, not isController)
		g_inputBinding:setActionEventActive(self.eventIdLeftRightMouse, not isController)
		self.lastInputMode = currentInputMode
		self.isDragging = false
		g_inputBinding:setShowMouseCursor(true)
	end
end
function ShopConfigScreen:consoleCommandUIToggle()
	self:toggleHUDVisible()
	return "ShopConfigScreen hudVisible=" .. tostring(self.shopConfigContent:getIsVisible())
end
function ShopConfigScreen:inputEvent(action, value, eventUsed)
	eventUsed = ShopConfigScreen:superClass().inputEvent(self, action, value, eventUsed)
	if not eventUsed and action == InputAction.TOGGLE_STORE then
		self:onClickBack()
		self.target:onClickBack()
		g_gui:changeScreen(nil)
		eventUsed = true
	end
	return eventUsed
end
ShopConfigScreen.GUI_PROFILE = {
	MAINTENANCE_COST = "shopConfigAttributeIconMaintenanceCosts",
	POWER = "shopConfigAttributeIconPower",
	TRANSMISSION = "shopConfigAttributeIconTransmission",
	FUEL = "shopConfigAttributeIconFuel",
	ELECTRICCHARGE = "shopConfigAttributeIconElectricCharge",
	METHANE = "shopConfigAttributeIconMethane",
	MAX_SPEED = "shopConfigAttributeIconMaxSpeed",
	CAPACITY = "shopConfigAttributeIconCapacity",
	WEIGHT = "shopConfigAttributeIconWeight",
	ADDITIONAL_WEIGHT = "shopConfigAttributeIconAdditionalWeight",
	WORKING_WIDTH = "shopConfigAttributeIconWorkingWidth",
	WORKING_SPEED = "shopConfigAttributeIconWorkSpeed",
	POWER_REQUIREMENT = "shopConfigAttributeIconPowerReq",
	WHEELS = "shopConfigAttributeIconWheels",
	BALE_SIZE_ROUND = "shopConfigAttributeIconBaleSizeRound",
	BALE_SIZE_SQUARE = "shopConfigAttributeIconBaleSizeSquare",
	BALEWRAPPER_SIZE_ROUND = "shopConfigAttributeIconBaleWrapperBaleSizeRound",
	BALEWRAPPER_SIZE_SQUARE = "shopConfigAttributeIconBaleWrapperBaleSizeSquare",
	MAX_TREE_SIZE = "shopConfigAttributeIconMaxTreeSize",
	MAX_TREE_MASS = "shopConfigAttributeIconMaxTreeMass",
	YARDER_MAX_LENGTH = "shopConfigAttributeIconYarderMaxLength",
	BUTTON_BUY = "buttonBuy",
}
ShopConfigScreen.L10N_SYMBOL = { MAINTENANCE_COST = "shop_maintenanceValue", POWER = "shopConfig_maxPowerValue", FUEL = "shop_fuelValue", FUEL_DEF = "shopConfig_fuelDefValue", MAX_SPEED = "shop_maxSpeed", CAPACITY = "shop_capacityValue", WORKING_WIDTH = "shop_workingWidthValue", WORKING_SPEED = "shop_maxSpeed", POWER_REQUIREMENT = "shopConfig_neededPowerValue", BUTTON_BUY = "button_buy", BUTTON_CONFIGURE = "button_configurate", UNIT_LITER = "unit_literShort", UNIT_KW = "unit_kw", UNIT_KG = "unit_kg", DEF_SHORT = "fillType_def_short", NOT_ENOUGH_MONEY_BUY = "shop_messageNotEnoughMoneyToBuy", NOT_ENOUGH_MONEY_LEASE = "shop_messageNotEnoughMoneyToLease", TOO_FEW_SLOTS = "shop_messageNotEnoughSlotsToBuy", CONFIRM_BUY = "shop_doYouWantToBuy", CONFIRM_LEASE = "shop_doYouWantToLease", CONFIGURATION_LABEL = "shop_configuration" }
ShopConfigScreen.SIZE = { INPUT_GLYPH = { 48, 48 } }
