-- Local values: ShopConfigScreen_mt, NO_CALLBACK
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
ShopConfigScreen.NO_VEHICLE = {
	["delete"] = function() end
}
ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG = "motor"
ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG = "fillUnit"
local function NO_CALLBACK() end
function ShopConfigScreen.register()
	local v3_ = ShopConfigScreen.new()
	g_gui:loadGui("dataS/gui/ShopConfigScreen.xml", "ShopConfigScreen", v3_)
	return v3_
end

-- Upvalues: ShopConfigScreen_mt, NO_CALLBACK
-- Local values: self
function ShopConfigScreen.new(target, custom_mt)
	-- upvalues: (copy) ShopConfigScreen_mt, (copy) NO_CALLBACK
	local v6_ = ScreenElement.new(target, custom_mt or ShopConfigScreen_mt)
	v6_.loadRequestIdWorkshop = nil
	v6_.fadeOverlay = Overlay.new(ShopConfigScreen.FADE_TEXTURE_PATH, 0, 0, 1, 1)
	v6_.fadeOverlay:setColor(0, 0, 0, 0)
	v6_.fadeInAnimation = TweenSequence.NO_SEQUENCE
	v6_.fadeOutAnimation = TweenSequence.NO_SEQUENCE
	v6_.rotateInputGlyph = nil
	v6_.zoomInputGlyph = nil
	v6_.lastInputHelpMode = nil
	v6_:createInputGlyphs()
	v6_.configBasePrice = 0
	v6_.totalPrice = 0
	v6_.initialLeasingCosts = 0
	v6_.lastMoney = 0
	v6_.displayableOptionCount = 0
	v6_.displayableColorCount = 0
	v6_.callbackFunc = nil
	v6_.requestExitCallback = NO_CALLBACK
	v6_.workshopWorldPosition = { 0, 0, 0 }
	v6_.workshopRootNode = nil
	v6_.workshopNode = nil
	v6_.cameraDistance = 10
	v6_.cameraMaxDistance = 20
	v6_.cameraMinDistance = 1
	v6_.zoomTarget = v6_.cameraDistance
	v6_.rotX = 0
	v6_.rotY = 0
	v6_.rotMinX = -0.17453292519943295
	v6_.rotMaxX = 1.2217304763960306
	v6_.focusY = 0
	v6_.vehicleSizeX = 1
	v6_.vehicleSizeY = 1
	v6_.vehicleSizeZ = 1
	v6_.rotateNode = nil
	v6_.cameraNode = nil
	v6_.previousCamera = nil
	v6_:createCamera()
	v6_:resetCamera()
	v6_.isLoadingInitial = false
	v6_.previewVehicleSize = 0
	v6_.previewVehicles = {}
	v6_.previousVehicles = {}
	v6_.loadingDelayFrames = 0
	v6_.loadingDelayTime = 0
	v6_.configItemCache = {}
	v6_.configItemCacheLarge = {}
	v6_.configurationToListElement = {}
	v6_.inputHorizontal = 0
	v6_.inputVertical = 0
	v6_.inputZoom = 0
	v6_.eventIdUpDownController = ""
	v6_.eventIdLeftRightController = ""
	v6_.eventIdUpDownMouse = ""
	v6_.eventIdLeftRightMouse = ""
	v6_.inputDragging = false
	v6_.isDragging = false
	v6_.accumDraggingInput = 0
	v6_.lastInputMode = g_inputBinding:getLastInputMode()
	v6_.lastInputHelpMode = g_inputBinding:getInputHelpMode()
	v6_.currentConfigSet = 1
	v6_:createFadeAnimations()
	g_messageCenter:subscribe(BuyVehicleEvent, v6_.onVehicleBought, v6_)
	g_messageCenter:subscribe(MessageType.STORE_ITEMS_RELOADED, v6_.onStoreItemsReloaded, v6_)
	v6_.openCounter = 0
	addConsoleCommand("gsShopUIToggle", "Toggle shop config screen UI visibility", "consoleCommandUIToggle", v6_)
	return v6_
end

-- Local values: newGui, returnScreenClass, target, callback, storeItem, saleItem, configurations, x, y, z
function ShopConfigScreen.createFromExistingGui(gui, guiName)
	removeConsoleCommand("gsShopUIToggle")
	local v9_ = ShopConfigScreen.new()
	local v10_ = gui.returnScreenClass
	local v11_ = gui.target
	local v12_ = gui.callbackFunc
	local v13_ = gui.storeItem
	local v14_ = gui.saleItem
	local v15_ = gui.configurations
	local v16_ = gui.workshopWorldPosition
	local v17_, v18_, v19_ = unpack(v16_)
	v9_.workshopFilename = gui.workshopFilename
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_)
	g_shopConfigScreen = v9_
	v9_:createWorkshop(v9_.workshopFilename, v17_, v18_, v19_)
	v9_.openCounter = 1
	v9_:setReturnScreenClass(v10_)
	v9_:setStoreItem(v13_, nil, v14_, nil, v15_)
	v9_.openCounter = 0
	v9_:setCallbacks(v12_, v11_)
	return v9_
end

-- Local values: iconWidth, iconHeight
function ShopConfigScreen:createInputGlyphs()
	local v21_ = getNormalizedScreenValues
	local v22_ = ShopConfigScreen.SIZE.INPUT_GLYPH
	local v23_, v24_ = v21_(unpack(v22_))
	self.rotateInputGlyph = InputGlyphElement.new(g_inputDisplayManager, v23_, v24_)
	self.rotateInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
	self.zoomInputGlyph = InputGlyphElement.new(g_inputDisplayManager, v23_, v24_)
	self.zoomInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
end

-- Local values: fadeInAnimation, fadeIn, fadeOutAnimation, fadeOut
function ShopConfigScreen:createFadeAnimations()
	local v26_ = TweenSequence.new(self)
	v26_:addTween((Tween.new(self.fadeScreen, 1, 0, 300)))
	self.fadeInAnimation = v26_
	local v27_ = TweenSequence.new(self)
	v27_:addTween((Tween.new(self.fadeScreen, 0, 1, 300)))
	self.fadeOutAnimation = v27_
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

-- Local values: slotsVisible
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
		if #self.workshopColorNodes > 0 then
			self.workshopDefaultColor = { getShaderParameter(self.workshopColorNodes[1], "colorScale") }
		end
	end
	local v37_ = g_currentMission.slotSystem:getAreSlotsVisible()
	self.shopSlotsIcon:setVisible(v37_)
	self.shopSlotsText:setVisible(v37_)
end

function ShopConfigScreen:onLicensePlateBoxLoaded(node, failedReason, args)
	if node ~= 0 then
		self.creationBox = node
		setVisibility(node, false)
	end
end

-- Local values: dofInfo
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
	local v41_ = g_depthOfFieldManager:createInfo(1, 1, 0.8, 15, 100, true)
	g_cameraManager:addCamera(self.cameraNode, nil, false, nil, v41_, false)
	link(self.cameraPositionNode, self.cameraNode)
end

-- Local values: alphaX, alphaY
function ShopConfigScreen:resetCamera()
	local v43_ = MathUtil.inverseLerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MAX, self.vehicleSizeY)
	local v44_ = MathUtil.inverseLerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MAX, self.vehicleSizeX)
	self.rotX = MathUtil.lerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MAX, v43_)
	self.rotY = MathUtil.lerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MAX, v44_)
	self.cameraDistance = (self.cameraMinDistance + self.cameraMaxDistance) * 0.5
end

-- Local values: _, element, _, element
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
	for _, v46_ in ipairs(self.configItemCache) do
		v46_:delete()
	end
	self.configItemCache = {}
	for _, v47_ in ipairs(self.configItemCacheLarge) do
		v47_:delete()
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

-- Local values: money
function ShopConfigScreen:updateBalanceText()
	local v50_ = g_currentMission:getMoney()
	self.lastMoney = v50_
	self.currentBalanceText:setValue(v50_)
	if v50_ <= -1 then
		self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE)
	else
		self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY)
	end
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end

-- Local values: farm, moneyText
function ShopConfigScreen:onMoneyChange()
	if g_localPlayer ~= nil then
		local v52_ = g_farmManager:getFarmById(g_localPlayer.farmId)
		if v52_.money <= -1 then
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
		else
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
		end
		local v53_ = g_i18n:formatMoney(v52_.money, 0, true, false)
		self.currentBalanceText:setText(v53_)
		if self.shopMoneyBox ~= nil then
			self.shopMoneyBox:invalidateLayout()
			self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
		end
	end
end

-- Local values: slotsVisible, text, profile
function ShopConfigScreen:onSlotUsageChanged(slotsUsage, maxSlots)
	local v57_ = g_currentMission.slotSystem:getAreSlotsVisible()
	if v57_ then
		local v58_ = string.format("%0d / %0d", slotsUsage, maxSlots)
		local v59_ = ShopMenu.GUI_PROFILE.SHOP_MONEY
		if slotsUsage / maxSlots >= ShopMenu.SLOTS_USAGE_CRITICAL_THRESHOLD then
			v59_ = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
		end
		self.shopSlotsText:applyProfile(v59_)
		self.shopSlotsText:setText(v58_)
	end
	self.shopSlotsIcon:setVisible(v57_)
	self.shopSlotsText:setVisible(v57_)
	if self.shopMoneyBox ~= nil then
		self.shopMoneyBox:invalidateLayout()
		self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end

-- Local values: dailyUpkeep, name, id, configs
function ShopConfigScreen:processStoreItemUpkeep(storeItem, realItem, saleItem)
	local v62_
	if storeItem.dailyUpkeep == nil then
		v62_ = 0
	else
		v62_ = storeItem.dailyUpkeep
		for v63_, v64_ in pairs(self.configurations) do
			local v65_ = storeItem.configurations[v63_]
			if v65_ ~= nil and v65_[v64_] ~= nil then
				v62_ = v62_ + v65_[v64_].dailyUpkeep
			end
		end
	end
	return v62_
end

-- Local values: power, configId
function ShopConfigScreen:processStoreItemPowerOutput(storeItem, realItem, saleItem)
	local v68_
	if storeItem.specs == nil or storeItem.specs.power == nil then
		v68_ = 0
	else
		v68_ = storeItem.specs.power
		if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
			local v69_ = self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]
			v68_ = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][v69_].power, v68_)
		end
	end
	return v68_
end

function ShopConfigScreen:processStoreItemFuelCapacity(storeItem, realItem, saleItem, fuelFillType)
	return Motorized.getSpecValueFuel(storeItem, realItem, self.configurations, fuelFillType, true) or 0
end

function ShopConfigScreen:processStoreItemCapacity(storeItem, realItem, saleItem)
	if storeItem.specs == nil or storeItem.specs.capacity == nil then
		return 0, nil
	else
		return FillUnit.getSpecValueCapacity(storeItem, realItem, self.configurations, saleItem, true)
	end
end

-- Local values: baseWeight, additionalWeight
function ShopConfigScreen:processStoreItemWeight(storeItem, realItem, saleItem)
	if storeItem.specs == nil or storeItem.specs.weight == nil then
		return 0, 0
	else
		return Vehicle.getSpecValueWeight(storeItem, realItem, nil, saleItem, true), storeItem.specs.additionalWeight == nil and 0 or Vehicle.getSpecValueAdditionalWeight(storeItem, realItem, nil, saleItem, true)
	end
end

-- Local values: width
function ShopConfigScreen:processStoreItemWorkingWidth(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil then
		if storeItem.specs.workingWidth ~= nil then
			return storeItem.specs.workingWidth.minWidth, storeItem.specs.workingWidth.width
		end
		if storeItem.specs.workingWidthConfig ~= nil then
			local v85_ = Vehicle.getSpecValueWorkingWidthConfig(storeItem, realItem, self.configurations, saleItem, true) or 0
			return v85_, v85_
		end
	end
	return nil, nil
end

function ShopConfigScreen:processStoreItemWorkingSpeed(storeItem, realItem, saleItem)
	return (storeItem.specs == nil or storeItem.specs.speedLimit == nil) and 0 or storeItem.specs.speedLimit
end

-- Local values: configValue
function ShopConfigScreen:processStoreItemPowerNeeded(storeItem, realItem, saleItem)
	return (storeItem.specs == nil or storeItem.specs.neededPower == nil) and 0 or (storeItem.specs.neededPower.config[self.configurations.powerConsumer] or storeItem.specs.neededPower.base or 0)
end

-- Local values: balerBaleSize, size
function ShopConfigScreen:processStoreItemBalerBaleSize(storeItem)
	if storeItem.specs ~= nil then
		local v90_ = storeItem.specs.balerBaleSizeRound or storeItem.specs.balerBaleSizeSquare
		if v90_ ~= nil then
			local v91_ = Baler.getSpecValueBaleSize(storeItem, nil, nil, nil, false, false, v90_.isRoundBaler)
			if v90_.isRoundBaler then
				return v91_, ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND
			else
				return v91_, ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE
			end
		end
	end
	return ""
end

-- Local values: roundBaleSize, squareBaleSize
function ShopConfigScreen:processStoreItemBaleWrapperBaleSize(storeItem)
	if storeItem.specs == nil then
		return nil, nil
	end
	local v93_ = BaleWrapper.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false)
	local v94_ = BaleWrapper.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
	if v93_ == nil and v94_ == nil then
		v93_ = InlineWrapper.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false)
		v94_ = InlineWrapper.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
	end
	return v93_, v94_
end

-- Local values: roundBaleSize, squareBaleSize
function ShopConfigScreen:processStoreItemBaleLoaderBaleSize(storeItem)
	if storeItem.specs == nil then
		return nil, nil
	else
		return BaleLoader.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false), BaleLoader.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
	end
end

function ShopConfigScreen:processStoreItemWoodHarvesterMaxTreeSize(storeItem, realItem, saleItem)
	if storeItem.specs == nil or storeItem.specs.woodHarvesterMaxTreeSize == nil then
		return nil
	else
		return WoodHarvester.getSpecValueMaxTreeSize(storeItem, realItem, self.configurations, saleItem, false)
	end
end

-- Local values: dailyUpkeep, powerOutput, transmissionName, fuelCapacity, electricCapacity, methaneCapacity, defCapacity, maxSpeed, capacity, capacityUnit, weight, additionalWeight, workingWidthMin, workingWidthMax, workingSpeed, powerNeeded, wheelNames, baleSize, baleSizeProfile, wrapperBaleSizeRound, wrapperBaleSizeSquare, loaderBaleSizeRound, loaderBaleSizeSquare, woodHarvesterMaxTreeSize, fellerBuncherMaxRadius, baleGrabMaxSizeRound, baleGrabMaxSizeSquare, maxYarderLength, maxYarderTreeMass, maxWinchMass, storeItems, i, itemIndex, item, realItem, itemCapacity, itemCapacityUnit, itemWeight, itemAdditionalWeight, itemMinWidth, itemMaxWidth, itemBaleSize, itemBaleSizeProfile, roundSize, squareSize, radius, _, tireNames, values, hp, kw, hp, kw, text, _, i, item, itemElement, iconElement, textElement
function ShopConfigScreen:processAttributeData(storeItem, vehicle, saleItem)
	local v104_ = 0
	local v105_ = 0
	local v106_ = nil
	local v107_ = 0
	local v108_ = 0
	local v109_ = 0
	local v110_ = 0
	local v111_ = 0
	local v112_ = 0
	local v113_ = nil
	local v114_ = 0
	local v115_ = 0
	local v116_ = math.huge
	local v117_ = -math.huge
	local v118_ = 0
	local v119_ = 0
	local v120_ = ""
	local v121_ = ""
	local v122_ = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND
	local v123_ = nil
	local v124_ = nil
	local v125_ = nil
	local v126_ = nil
	local v127_ = nil
	local v128_ = 0
	local v129_ = nil
	local v130_ = nil
	local v131_ = 0
	local v132_ = 0
	local v133_ = 0
	local v134_
	if storeItem.bundleInfo == nil then
		v134_ = { storeItem }
	else
		v134_ = {}
		for v135_ = 1, #storeItem.bundleInfo.bundleItems do
			local v136_ = storeItem.bundleInfo.bundleItems[v135_].item
			table.insert(v134_, v136_)
		end
	end
	for v137_, v138_ in ipairs(v134_) do
		StoreItemUtil.loadSpecsFromXML(v138_)
		local v139_ = self.previewVehicles[v137_] or vehicle
		v104_ = v104_ + self:processStoreItemUpkeep(v138_, v139_, saleItem)
		v105_ = v105_ + self:processStoreItemPowerOutput(v138_, v139_, saleItem)
		v106_ = v106_ or Motorized.getSpecValueTransmission(storeItem, v139_, nil, saleItem)
		v107_ = v107_ + self:processStoreItemFuelCapacity(v138_, v139_, saleItem, FillType.DIESEL)
		v108_ = v108_ + self:processStoreItemFuelCapacity(v138_, v139_, saleItem, FillType.ELECTRICCHARGE)
		v109_ = v109_ + self:processStoreItemFuelCapacity(v138_, v139_, saleItem, FillType.METHANE)
		v110_ = v110_ + self:processStoreItemFuelCapacity(v138_, v139_, saleItem, FillType.DEF)
		local v140_, v141_ = self:processStoreItemCapacity(v138_, v139_, saleItem)
		if v113_ ~= nil and (v141_ ~= nil and v141_ ~= v113_) then
			local v142_ = printWarning
			local v143_ = storeItem.xmlFilename
			v142_("Warning: Bundled store items have different fill capacity units. Check " .. tostring(v143_))
		end
		v112_ = v112_ + v140_
		v113_ = v113_ or v141_
		local v144_, v145_ = self:processStoreItemWeight(v138_, v139_, saleItem)
		v114_ = v114_ + (v144_ or 0)
		v115_ = v115_ + (v145_ or 0)
		local v146_, v147_ = self:processStoreItemWorkingWidth(v138_, v139_, saleItem)
		if v146_ ~= nil and v147_ ~= nil then
			v116_ = math.min(v116_, v146_)
			v117_ = math.max(v117_, v147_)
		end
		v118_ = math.max(v118_, self:processStoreItemWorkingSpeed(v138_, v139_, saleItem))
		local v148_ = Motorized.getSpecValueMaxSpeed(storeItem, v139_, self.configurations, saleItem, true, false) or 0
		v111_ = math.max(v111_, v148_)
		v119_ = v119_ + self:processStoreItemPowerNeeded(v138_, v139_, saleItem)
		local v149_, v150_ = self:processStoreItemBalerBaleSize(v138_)
		if v121_ ~= "" then
			v150_ = v122_
			v149_ = v121_
		end
		local v151_, v152_ = self:processStoreItemBaleWrapperBaleSize(v138_)
		local v153_, v154_ = self:processStoreItemBaleLoaderBaleSize(v138_)
		v125_ = v125_ or v153_
		v126_ = v126_ or v154_
		v129_ = BaleGrab.getSpecValueMaxSizeRound(storeItem, v139_, self.configurations, saleItem, false, false) or v129_
		v130_ = BaleGrab.getSpecValueMaxSizeSquare(storeItem, v139_, self.configurations, saleItem, false, false) or v130_
		v127_ = self:processStoreItemWoodHarvesterMaxTreeSize(v138_)
		local v155_, _ = FellerBuncher.getSpecValueMaxTreeSize(storeItem, v139_, self.configurations, saleItem, true, false)
		v128_ = math.max(v155_ or 0, v128_)
		local v156_ = YarderTower.getSpecValueMaxLength(storeItem, v139_, self.configurations, saleItem, true, false) or 0
		v131_ = math.max(v156_, v131_)
		local v157_ = YarderTower.getSpecValueMaxMass(storeItem, v139_, self.configurations, saleItem, true, false) or 0
		v132_ = math.max(v157_, v132_)
		local v158_ = Winch.getSpecValueMaxMass(storeItem, v139_, self.configurations, saleItem, true, false) or 0
		v133_ = math.max(v158_, v133_)
		v122_ = v150_
		v121_ = v149_
		v123_ = v123_ or v151_
		v124_ = v124_ or v152_
	end
	if vehicle ~= nil then
		local v159_ = Wheels.getTireNames(vehicle)
		if v159_ ~= nil then
			v120_ = table.concatKeys(v159_, " / ")
		end
	end
	local v160_ = {}
	if v104_ ~= 0 then
		local v161_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.MAINTENANCE_COST,
			["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.MAINTENANCE_COST), g_i18n:formatMoney(v104_, 2))
		}
		table.insert(v160_, v161_)
	end
	if v105_ ~= 0 then
		local v162_, v163_ = g_i18n:getPower(v105_)
		local v164_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.POWER,
			["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.POWER), MathUtil.round(v163_), MathUtil.round(v162_))
		}
		table.insert(v160_, v164_)
	end
	if v106_ ~= nil then
		local v165_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.TRANSMISSION,
			["value"] = v106_
		}
		table.insert(v160_, v165_)
	end
	if v107_ == 0 then
		if v108_ == 0 then
			if v109_ ~= 0 then
				local v166_ = {
					["profile"] = ShopConfigScreen.GUI_PROFILE.METHANE,
					["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), v109_, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_KG))
				}
				table.insert(v160_, v166_)
			end
		else
			local v167_ = {
				["profile"] = ShopConfigScreen.GUI_PROFILE.ELECTRICCHARGE,
				["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), v108_, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_KW))
			}
			table.insert(v160_, v167_)
		end
	elseif v110_ == 0 then
		local v168_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.FUEL,
			["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), v107_, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER))
		}
		table.insert(v160_, v168_)
	elseif v110_ > 0 then
		local v169_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.FUEL,
			["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL_DEF), v107_, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), v110_, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.DEF_SHORT))
		}
		table.insert(v160_, v169_)
	end
	if v111_ ~= 0 then
		local v170_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_SPEED,
			["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.MAX_SPEED), string.format("%1d", g_i18n:getSpeed(v111_)), g_i18n:getSpeedMeasuringUnit())
		}
		table.insert(v160_, v170_)
	end
	if v112_ ~= 0 and v113_ ~= nil then
		if v113_:sub(1, 6) == "$l10n_" then
			v113_ = v113_:sub(7)
		end
		local v171_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.CAPACITY,
			["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CAPACITY), v112_, g_i18n:getText(v113_))
		}
		table.insert(v160_, v171_)
	end
	if v114_ ~= 0 then
		local v172_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.WEIGHT,
			["value"] = g_i18n:formatMass(v114_)
		}
		table.insert(v160_, v172_)
	end
	if v115_ ~= 0 then
		local v173_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.ADDITIONAL_WEIGHT,
			["value"] = g_i18n:formatMass(v115_)
		}
		table.insert(v160_, v173_)
	end
	if v119_ ~= 0 then
		local v174_, v175_ = g_i18n:getPower(v119_)
		local v176_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.POWER_REQUIREMENT,
			["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.POWER_REQUIREMENT), MathUtil.round(v175_), MathUtil.round(v174_))
		}
		table.insert(v160_, v176_)
	end
	if v116_ ~= math.huge and v117_ ~= -math.huge then
		local v177_
		if v116_ == v117_ then
			v177_ = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_WIDTH), g_i18n:formatNumber(v117_, 1, true))
		else
			v177_ = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_WIDTH), string.format("%s-%s", g_i18n:formatNumber(v116_, 1, true), g_i18n:formatNumber(v117_, 1, true)))
		end
		local v178_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.WORKING_WIDTH,
			["value"] = v177_
		}
		table.insert(v160_, v178_)
	end
	if v118_ ~= 0 then
		local v179_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.WORKING_SPEED,
			["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_SPEED), string.format("%1d", g_i18n:getSpeed(v118_)), g_i18n:getSpeedMeasuringUnit())
		}
		table.insert(v160_, v179_)
	end
	if v120_ ~= "" then
		local v180_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.WHEELS,
			["value"] = v120_
		}
		table.insert(v160_, v180_)
	end
	if v121_ ~= nil and v121_ ~= "" then
		table.insert(v160_, {
			["profile"] = v122_,
			["value"] = v121_
		})
	end
	if v123_ ~= nil then
		local v181_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.BALEWRAPPER_SIZE_ROUND,
			["value"] = v123_
		}
		table.insert(v160_, v181_)
	end
	if v124_ ~= nil then
		local v182_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.BALEWRAPPER_SIZE_SQUARE,
			["value"] = v124_
		}
		table.insert(v160_, v182_)
	end
	if v125_ ~= nil then
		local v183_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND,
			["value"] = v125_
		}
		table.insert(v160_, v183_)
	end
	if v126_ ~= nil then
		local v184_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE,
			["value"] = v126_
		}
		table.insert(v160_, v184_)
	end
	if v129_ ~= nil then
		local v185_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND,
			["value"] = v129_
		}
		table.insert(v160_, v185_)
	end
	if v130_ ~= nil then
		local v186_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE,
			["value"] = v130_
		}
		table.insert(v160_, v186_)
	end
	if v127_ ~= nil then
		local v187_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_TREE_SIZE,
			["value"] = v127_
		}
		table.insert(v160_, v187_)
	end
	if v128_ ~= 0 then
		local v188_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_TREE_SIZE,
			["value"] = string.format("%d%s", MathUtil.round(v128_), g_i18n:getText("unit_cmShort"))
		}
		table.insert(v160_, v188_)
	end
	if v131_ ~= 0 then
		local v189_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.YARDER_MAX_LENGTH,
			["value"] = string.format("%d%s", v131_, g_i18n:getText("unit_mShort"))
		}
		table.insert(v160_, v189_)
	end
	if v132_ ~= 0 then
		local v190_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_TREE_MASS,
			["value"] = string.format("%.1f%s", v132_, g_i18n:getText("unit_tonsShort"))
		}
		table.insert(v160_, v190_)
	end
	if v133_ ~= 0 then
		local v191_ = {
			["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_TREE_MASS,
			["value"] = string.format("%.1f%s", v133_, g_i18n:getText("unit_tonsShort"))
		}
		table.insert(v160_, v191_)
	end
	self:registerCustomSpecValues(v160_, v134_, vehicle, saleItem)
	for _ = 1, #self.attributesLayout.elements do
		self.attributesLayout.elements[1]:delete()
	end
	for _, v192_ in ipairs(v160_) do
		local v193_ = self.attributeItem:clone(self.attributesLayout)
		local v194_ = v193_:getDescendantByName("icon")
		local v195_ = v193_:getDescendantByName("text")
		v194_:applyProfile(v192_.profile)
		v195_:setText(v192_.value)
	end
	self.attributesLayout:invalidateLayout()
end

function ShopConfigScreen:registerCustomSpecValues(values, storeItems, vehicle, saleItem) end

-- Local values: basePrice, upgradePrice, hasChanges, name, id, configs
function ShopConfigScreen:getConfigurationCostsAndChanges(storeItem, vehicle, saleItem)
	local v200_ = 0
	local v201_ = 0
	local v202_ = false
	if vehicle == nil then
		if saleItem ~= nil then
			local v203_, v204_ = g_currentMission.economyManager:getBuyPrice(storeItem, self.configurations, saleItem)
			return v203_ - v204_, v204_, true
		end
		if storeItem ~= nil then
			local v205_
			v205_, v201_ = g_currentMission.economyManager:getBuyPrice(storeItem, self.configurations)
			v200_ = v205_ - v201_
			v202_ = true
		end
	else
		for v206_, v207_ in pairs(self.configurations) do
			if vehicle.configurations[v206_] ~= v207_ then
				v202_ = true
				if not ConfigurationUtil.hasBoughtConfiguration(self.vehicle, v206_, v207_) then
					v201_ = v201_ + storeItem.configurations[v206_][v207_].price
				end
			end
		end
		v202_ = ConfigurationUtil.getConfigurationDataHasChanged(self.vehicle.configFileName, self.configurationData, vehicle.configurationData) and true or v202_
		if self.vehicle.getLicensePlatesDataIsEqual ~= nil and not self.vehicle:getLicensePlatesDataIsEqual(self.licensePlateData) then
			return v200_, v201_, true
		end
	end
	return v200_, v201_, v202_
end

function ShopConfigScreen:updatePriceData(basePrice, upgradePrice)
	self.totalPrice = basePrice + upgradePrice
	self.initialLeasingCosts = 0
	self.initialLeasingCosts = g_currentMission.economyManager:getInitialLeasingPrice(self.totalPrice)
	self.basePriceText:setText(g_i18n:formatMoney(basePrice, 0, true, false))
	self.upgradesPriceText:setText("+ " .. g_i18n:formatMoney(upgradePrice, 0, true, false))
	self.totalPriceText:setText(g_i18n:formatMoney(self.totalPrice, 0, true, false))
end

-- Local values: basePrice, upgradePrice, hasChanges
function ShopConfigScreen:updateData(storeItem, vehicle, saleItem)
	local v215_, v216_, v217_ = self:getConfigurationCostsAndChanges(storeItem, vehicle, saleItem)
	self:updatePriceData(v215_, v216_)
	self.buyButton:setDisabled(not v217_)
	self:loadCurrentConfiguration(storeItem)
end

-- Local values: index, k, item
function ShopConfigScreen:getDefaultConfigurationColorIndex(configName, configItems, vehicle)
	local v221_ = nil
	for v222_, v223_ in pairs(configItems) do
		if v223_.isDefault then
			v221_ = v222_
			break
		end
	end
	if vehicle ~= nil then
		v221_ = vehicle.configurations[configName]
	end
	return v221_ == nil and 1 or v221_
end

-- Local values: buyButtonText
function ShopConfigScreen:updateButtons(storeItem, vehicle, saleItem)
	local v228_ = self.leaseButton
	local v229_ = vehicle == nil and storeItem.allowLeasing
	if v229_ then
		v229_ = saleItem == nil
	end
	v228_:setVisible(v229_)
	local v230_ = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_BUY)
	if vehicle ~= nil then
		v230_ = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_CONFIGURE)
	end
	self.buyButton:setText(v230_)
	self.buyButton:updateAbsolutePosition()
	self.buttonsPanel:invalidateLayout()
end

-- Local values: data, _, preVehicle
function ShopConfigScreen:loadCurrentConfiguration(storeItem)
	if self.currentVehicleLoading ~= nil then
		self.currentVehicleLoading:cancelLoading()
	end
	local v233_ = VehicleLoadingData.new()
	v233_:setPosition(self.workshopWorldPosition[1], self.workshopWorldPosition[2], self.workshopWorldPosition[3])
	if not storeItem.shopIgnoreLastComponentPositions then
		for _, v234_ in ipairs(self.previewVehicles) do
			if v234_.configFileName == storeItem.xmlFilename then
				v233_:setComponentPositionData(v234_)
			end
		end
	end
	v233_:setStoreItem(storeItem)
	v233_:setConfigurations(self.configurations)
	v233_:setConfigurationData(self.configurationData)
	v233_:setPropertyState(VehiclePropertyState.SHOP_CONFIG)
	v233_:setCustomParameter("foldableInvertFoldState", MathUtil.round(storeItem.shopFoldingState, 0) == 1)
	v233_:setCustomParameter("foldableFoldingTime", storeItem.shopFoldingTime)
	v233_:setForceServer(true)
	v233_:setIsRegistered(false)
	v233_:setIsSaved(false)
	v233_:setSaleItem(self.saleItem)
	self.currentVehicleLoading = v233_
	self.loadingAnimation:setVisible(true)
	v233_:load(self.onVehiclesLoaded, self, {
		["openCounter"] = self.openCounter
	})
end

-- Local values: _, vehicle, _, vehicle, index, vehicle, _, vehicle, index, vehicle, defaultPlacementIndex, hasFrontPlate, loadingDelayTime
function ShopConfigScreen:onVehiclesLoaded(vehicles, loadingState, asyncArguments)
	self.currentVehicleLoading = nil
	if loadingState == VehicleLoadingState.CANCELED then
		return
	elseif loadingState == VehicleLoadingState.OK then
		if asyncArguments.openCounter == self.openCounter then
			if self.isLoadingInitial or self.isOpen then
				for _, v239_ in ipairs(self.previewVehicles) do
					v239_:removeFromPhysics()
					local v240_ = self.previousVehicles
					table.insert(v240_, v239_)
				end
				self.previewVehicles = vehicles
				for _, v241_ in ipairs(vehicles) do
					v241_:setVisibility(false)
					v241_.forceIsActive = true
				end
				for _, v242_ in ipairs(vehicles) do
					self:processAttributeData(self.storeItem, v242_)
					if v242_.setLicensePlatesData ~= nil and (v242_.getHasLicensePlates ~= nil and v242_:getHasLicensePlates()) then
						local v243_, v244_ = v242_:getLicensePlateDialogSettings()
						self.licensePlateData.defaultPlacementIndex = v243_
						self.licensePlateData.hasFrontPlate = v244_
						if not self.licensePlateData.customized and v243_ ~= nil then
							self.licensePlateData.placementIndex = v243_
						end
						v242_:setLicensePlatesData(self.licensePlateData)
						self:updateLicensePlateGraphics()
					end
					if v242_.addDamageAmount ~= nil and v242_.addWearAmount ~= nil then
						if self.saleItem == nil then
							if self.vehicle ~= nil and (self.vehicle.getDamageAmount ~= nil and self.vehicle.getWearTotalAmount ~= nil) then
								v242_:addDamageAmount(self.vehicle:getDamageAmount(), true)
								v242_:addWearAmount(self.vehicle:getWearTotalAmount(), true)
							end
						else
							v242_:addDamageAmount(self.saleItem.damage or 0, true)
							v242_:addWearAmount(self.saleItem.wear or 0, true)
						end
					end
					if v242_.setDirtAmount ~= nil and (self.vehicle ~= nil and self.vehicle.getDirtAmount ~= nil) then
						v242_:setDirtAmount(self.vehicle:getDirtAmount())
					end
				end
				local v245_ = 0
				local v246_
				if self.isLoadingInitial then
					v246_ = self.storeItem.shopInitialLoadingDelay or v245_
				else
					v246_ = self.storeItem.shopConfigLoadingDelay or v245_
				end
				self.loadingDelayTime = v246_
				self.loadingDelayFrames = 3
			else
				for _, v247_ in ipairs(vehicles) do
					v247_:delete()
				end
				self.previewVehicles = {}
			end
		else
			for _, v248_ in ipairs(vehicles) do
				v248_:delete()
			end
			return
		end
	else
		if g_currentMission ~= nil then
			local v249_ = Logging.error
			local v250_ = self.storeItem.xmlFilename
			v249_("Could not load vehicle defined in [%s]. Check vehicle configuration and mods.", (tostring(v250_)))
			self.callbackFunc = nil
			self:onClickBack()
		end
		return
	end
end

-- Local values: numVehicles, i, _, loadedVehicle, minX, maxX, minZ, maxZ, _, vehicle, largestDimension, halfWidth, halfLength, x1, _, z1, x2, _, z2, x3, _, z3, x4, _, z4, defaultOffset, vehicle, brand
function ShopConfigScreen:onFinishedLoading()
	local v252_ = #self.previousVehicles
	for v253_ = v252_, 1, -1 do
		self.previousVehicles[v253_]:delete()
		self.previousVehicles[v253_] = nil
	end
	for _, v254_ in pairs(self.previewVehicles) do
		v254_:setVisibility(true)
	end
	if v252_ == 0 then
		self.vehicleSizeY = 1
		self.previewVehicleSize = 0
		local v255_ = math.huge
		local v256_ = -math.huge
		local v257_ = math.huge
		local v258_ = -math.huge
		for _, v259_ in pairs(self.previewVehicles) do
			local v260_ = v259_.size.width
			local v261_ = v259_.size.length
			local v262_ = self.storeItem.shopHeight * 1.5
			local v263_ = math.max(v260_, v261_, v262_)
			self.previewVehicleSize = self.previewVehicleSize + v263_
			local v264_ = self.vehicleSizeY
			local v265_ = v259_.size.height
			self.vehicleSizeY = math.max(v264_, v265_)
			local v266_ = v259_.size.width * 0.5
			local v267_ = v259_.size.length * 0.5
			local v268_, _, v269_ = localToLocal(v259_.rootNode, self.workshopRootNode, v266_ + v259_.size.widthOffset, 0, v267_ + v259_.size.lengthOffset)
			local v270_, _, v271_ = localToLocal(v259_.rootNode, self.workshopRootNode, v266_ + v259_.size.widthOffset, 0, -v267_ + v259_.size.lengthOffset)
			local v272_, _, v273_ = localToLocal(v259_.rootNode, self.workshopRootNode, -v266_ + v259_.size.widthOffset, 0, -v267_ + v259_.size.lengthOffset)
			local v274_, _, v275_ = localToLocal(v259_.rootNode, self.workshopRootNode, -v266_ + v259_.size.widthOffset, 0, v267_ + v259_.size.lengthOffset)
			v255_ = math.min(v268_, v270_, v272_, v274_, v255_)
			v256_ = math.max(v268_, v270_, v272_, v274_, v256_)
			v257_ = math.min(v269_, v271_, v273_, v275_, v257_)
			v258_ = math.max(v269_, v271_, v273_, v275_, v258_)
		end
		local v276_ = v256_ - v255_
		self.vehicleSizeX = math.max(v276_, 1)
		local v277_ = v258_ - v257_
		self.vehicleSizeZ = math.max(v277_, 1)
		self.focusY = self.vehicleSizeY * 0.4
	end
	if self.previewVehicleSize == 0 then
		self.previewVehicleSize = ShopConfigScreen.DEFAULT_PREVIEW_SIZE
	end
	local v278_ = self.previewVehicleSize * ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR
	local v279_ = ShopConfigScreen.MAX_CAMERA_DISTANCE
	self.cameraMaxDistance = math.min(v278_, v279_)
	local v280_ = self.previewVehicleSize * ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR + ShopConfigScreen.NEAR_CLIP_DISTANCE
	local v281_ = self.cameraMaxDistance
	self.cameraMinDistance = math.min(v280_, v281_)
	if self.isLoadingInitial then
		local v282_
		if self.vehicleSizeX < self.vehicleSizeY then
			local v283_ = self.vehicleSizeX
			local v284_ = self.vehicleSizeY
			v282_ = math.max(v283_, v284_) * 0.35
		else
			local v285_ = self.vehicleSizeZ
			local v286_ = self.vehicleSizeY
			v282_ = math.max(v285_, v286_) * 0.35
		end
		local v287_ = self.cameraMinDistance + v282_
		local v288_ = self.cameraMaxDistance
		self.cameraDistance = math.min(v287_, v288_)
		self.zoomTarget = self.cameraDistance
		self:resetCamera()
	end
	if self.storeItem.shopDynamicTitle then
		local v289_ = self.previewVehicles[1]
		if v289_ ~= nil then
			local v290_ = g_brandManager:getBrandByIndex(v289_:getBrand() or self.storeItem.brandIndex)
			self.shopConfigBrandIcon:setImageFilename(self.storeItem.customBrandIcon or v290_.image)
			self.shopConfigItemName:setText(v289_:getName() or self.storeItem.name)
		end
	end
	self.isLoadingInitial = false
	self.loadingAnimation:setVisible(false)
end

-- Local values: brandIndex, vehicleName, brand
function ShopConfigScreen:updateDisplay(storeItem, vehicle, saleItem, doNotReload)
	local v296_ = storeItem.brandIndex
	local v297_ = storeItem.name
	if storeItem.shopDynamicTitle and vehicle ~= nil then
		v296_ = vehicle:getBrand()
		v297_ = vehicle:getName()
	end
	local v298_ = g_brandManager:getBrandByIndex(v296_)
	if self.shopConfigBrandIcon == nil then
		printCallstack()
	end
	self.shopConfigBrandIcon:setImageFilename(storeItem.customBrandIcon or v298_.image)
	self.shopConfigItemName:setText(v297_)
	self:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
	self:updateButtons(storeItem, vehicle, saleItem)
	if not doNotReload then
		self:updateData(storeItem, vehicle, saleItem)
	end
end

function ShopConfigScreen:setCurrentMission(currentMission) end

-- Local values: shopConfigFilename, xmlFile, x, y, z, isLightingStatic
function ShopConfigScreen:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	if not GS_IS_MOBILE_VERSION then
		local v302_ = getXMLString(mapXMLFile, "map.shop#filename") or "$data/store/ui/shop.xml"
		local v303_ = Utils.getFilename(v302_, baseDirectory)
		local v304_ = XMLFile.load("shopXml", v303_)
		self.workshopFilename = Utils.getFilename(v304_:getString("shop.filename") or ShopConfigScreen.WORKSHOP_PATH, baseDirectory)
		local v305_ = v304_:getFloat("shop.position#xMapPos") or 0
		local v306_ = v304_:getFloat("shop.position#yMapPos") or 0
		local v307_ = v304_:getFloat("shop.position#zMapPos") or 0
		if Utils.getNoNil(v304_:getBool("shop.lighting#isStatic"), false) then
			self.shopLighting = LightingStatic.new()
		else
			self.shopLighting = Lighting.new()
		end
		self.shopLighting:load(v304_, "shop.lighting", g_currentMission.baseDirectory)
		v304_:delete()
		self:createWorkshop(self.workshopFilename, v305_, v306_, v307_)
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

-- Local values: _, vehicle
function ShopConfigScreen:deletePreviewVehicles()
	for _, v317_ in pairs(self.previewVehicles) do
		v317_:delete()
	end
	self.previewVehicles = {}
end

-- Local values: configName, index, configName, index, configName, boughtItems, index, value, data, defaultPlacementIndex, hasFrontPlate
function ShopConfigScreen:setStoreItem(storeItem, vehicle, saleItem, configBasePrice, configurations)
	self:deletePreviewVehicles()
	self.storeItem = storeItem
	self.vehicle = vehicle
	self.saleItem = saleItem
	self.configBasePrice = Utils.getNoNil(configBasePrice, 0)
	if configurations == nil then
		configurations = {}
		if storeItem.defaultConfigurationIds ~= nil then
			for v324_, v325_ in pairs(storeItem.defaultConfigurationIds) do
				configurations[v324_] = v325_
			end
		end
		if vehicle ~= nil and vehicle.configurations ~= nil then
			for v326_, v327_ in pairs(vehicle.configurations) do
				configurations[v326_] = v327_
			end
		end
		if saleItem ~= nil and saleItem.boughtConfigurations ~= nil then
			for v328_, v329_ in pairs(saleItem.boughtConfigurations) do
				for v330_, v331_ in pairs(v329_) do
					if v331_ then
						configurations[v328_] = v330_
					end
				end
			end
		end
	end
	self.configurations = configurations
	if vehicle == nil then
		self.configurationData = {}
		self.boughtConfigurations = {}
	else
		self.configurationData = table.clone(vehicle.configurationData, math.huge)
		self.boughtConfigurations = table.clone(vehicle.boughtConfigurations, math.huge)
	end
	self.subConfigurations = {}
	self.currentConfigSet = 1
	self.isLoadingInitial = true
	if g_licensePlateManager:getAreLicensePlatesAvailable() then
		if vehicle == nil then
			self.licensePlateData = g_currentMission:getLastCreatedLicensePlate() or g_licensePlateManager:getRandomLicensePlateData()
		elseif vehicle.getLicensePlatesData ~= nil then
			local v332_ = vehicle:getLicensePlatesData()
			if v332_ == nil or v332_.characters == nil then
				self.licensePlateData = g_currentMission:getLastCreatedLicensePlate() or g_licensePlateManager:getRandomLicensePlateData()
			else
				self.licensePlateData = {}
				self.licensePlateData.variation = v332_.variation
				self.licensePlateData.colorIndex = v332_.colorIndex
				self.licensePlateData.placementIndex = v332_.placementIndex
				self.licensePlateData.characters = table.clone(v332_.characters)
				local v333_, v334_ = vehicle:getLicensePlateDialogSettings()
				self.licensePlateData.defaultPlacementIndex = v333_
				self.licensePlateData.hasFrontPlate = v334_
			end
		end
	end
	self:processStoreItemConfigurations(storeItem, vehicle, saleItem)
	self:updateDisplay(storeItem, vehicle, saleItem)
	self:resetCamera()
end

-- Upvalues: NO_CALLBACK
function ShopConfigScreen:setRequestExitCallback(callback)
	-- upvalues: (copy) NO_CALLBACK
	self.requestExitCallback = callback or NO_CALLBACK
end

-- Local values: configItems, price
function ShopConfigScreen:setConfigPrice(configName, configIndex, priceTextElement, vehicle)
	local v342_ = self.storeItem.configurations[configName][configIndex].price
	local v343_
	if vehicle == nil then
		v343_ = self.saleItem ~= nil and ConfigurationUtil.hasBoughtConfiguration(self.saleItem, configName, configIndex) and 0 or v342_
	else
		v343_ = ConfigurationUtil.hasBoughtConfiguration(vehicle, configName, configIndex) and 0 or v342_
	end
	priceTextElement:setText("+" .. g_i18n:formatMoney(v343_) .. "")
	priceTextElement:setVisible(true)
end

-- Local values: configName, colorOptionIndex, element, isValid, configItems, index, configItem, config, color, materialTemplateName, data, isMetallic, isMat, r, g, b, priceElement
function ShopConfigScreen:onPickColor(colorIndex, args, customColor, noUpdate)
	local v349_ = args.configName
	local v350_ = args.colorOptionIndex
	local v351_ = self.colorElements[v350_]
	if customColor ~= nil then
		local v352_ = self.storeItem.configurations[v349_]
		local v353_ = true
		for v354_, v355_ in pairs(v352_) do
			if v355_.isCustomColor then
				colorIndex = v354_
				v353_ = true
				break
			end
		end
		if v353_ then
			if self.configurationData[v349_] == nil then
				self.configurationData[v349_] = {}
			end
			self.configurationData[v349_][colorIndex] = {}
			self.configurationData[v349_][colorIndex].color = { customColor.customColor[1], customColor.customColor[2], customColor.customColor[3] }
			self.configurationData[v349_][colorIndex].materialTemplateName = customColor.templateName
		end
	end
	if colorIndex ~= nil then
		self.configurations[v349_] = colorIndex
		local v356_ = self.storeItem.configurations[v349_][colorIndex]
		local v357_ = v356_.uiColor or v356_.color
		local v358_ = v356_.materialTemplateName
		if self.configurationData[v349_] ~= nil then
			local v359_ = self.configurationData[v349_][colorIndex]
			if v359_ ~= nil then
				v357_ = v359_.color or v357_
				v358_ = v359_.materialTemplateName or v358_
			end
		end
		local v360_, v361_ = g_vehicleMaterialManager:getMaterialTemplateFinish(v358_)
		local v362_ = v360_ or v356_.isMetallic
		local v363_ = v361_ or v356_.isMat
		v351_:getDescendantByName("colorImageGlossy"):setVisible(not (v362_ or v363_))
		v351_:getDescendantByName("colorImageMetallic"):setVisible(v362_)
		v351_:getDescendantByName("colorImageMatte"):setVisible(v363_)
		if MathUtil.getBrightnessFromColor(unpack(v357_)) >= ColorPickButtonElement.BRIGHTNESS_THRESHOLD then
			v351_:getDescendantByName("colorImageGlossy"):setImageColor(nil, 0, 0, 0)
			v351_:getDescendantByName("colorImageMetallic"):setImageColor(nil, 0, 0, 0)
			v351_:getDescendantByName("colorImageMatte"):setImageColor(nil, 0, 0, 0)
		else
			v351_:getDescendantByName("colorImageGlossy"):setImageColor(nil, 1, 1, 1)
			v351_:getDescendantByName("colorImageMetallic"):setImageColor(nil, 1, 1, 1)
			v351_:getDescendantByName("colorImageMatte"):setImageColor(nil, 1, 1, 1)
		end
		local v364_, v365_, v366_ = unpack(v357_)
		v351_:getDescendantByName("colorImage"):setImageColor(nil, math.clamp(v364_, 0, 1), math.clamp(v365_, 0, 1), (math.clamp(v366_, 0, 1)))
		self:setConfigPrice(v349_, colorIndex, v351_.parent:getDescendantByName("price"), self.vehicle)
		if not noUpdate then
			self:updateData(self.storeItem, self.vehicle, self.saleItem)
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
		end
	end
end

-- Local values: firstElement, focusElement
function ShopConfigScreen:selectFirstConfig()
	local v368_ = self.configurationLayout.elements[1]
	if v368_ == nil then
		FocusManager:unsetFocus(FocusManager:getFocusedElement())
		FocusManager.currentFocusData.focusElement = nil
	else
		local v369_ = v368_:getDescendantByName("option")
		if v369_ == nil or not v369_:getIsVisible() then
			v369_ = v368_:getDescendantByName("color")
		end
		if v369_ == nil or not v369_:getIsVisible() then
			v369_ = v368_:getDescendantByName("yesNoOption")
		end
		if v369_ == nil or not v369_:getIsVisible() then
			v369_ = v368_:getDescendantByName("button")
		end
		FocusManager:unsetFocus(v369_)
		FocusManager:setFocus(v369_)
	end
end

-- Local values: options, configurationTypes, _, configName, items, subConfigItems, option, option
function ShopConfigScreen:processStoreItemConfigurationSet(storeItem, configSet, vehicle, saleItem)
	local v375_ = g_vehicleConfigurationManager:getSortedConfigurationTypes()
	local v376_ = {}
	for _, v377_ in ipairs(v375_) do
		if g_vehicleConfigurationManager:getConfigurationSelectorType(v377_) ~= ConfigurationUtil.SELECTOR_COLOR then
			local v378_ = storeItem.configurations[v377_]
			local v379_ = storeItem.subConfigurations[v377_]
			if v379_ == nil or #v379_.subConfigValues <= 1 then
				if v378_ ~= nil and (#v378_ > 1 and configSet.configurations[v377_] == nil) then
					local v380_ = self:processStoreItemConfigurationOption(storeItem, v377_, v378_, vehicle, nil, saleItem)
					table.insert(v376_, v380_)
				end
			else
				local v381_ = self:processStoreItemSubConfigurationOption(storeItem, v377_, vehicle, saleItem)
				table.insert(v376_, v381_)
			end
		end
	end
	return v376_
end

-- Local values: subConfig, texts, icons, subConfigOptions, subConfigSelection, initialIndex, i, name, items, subConfigOption
function ShopConfigScreen:processStoreItemSubConfigurationOption(storeItem, configName, vehicle, saleItem)
	local v387_ = storeItem.subConfigurations[configName]
	local v388_ = {}
	local v389_ = {
		["name"] = configName,
		["title"] = g_vehicleConfigurationManager:getConfigurationDescByName(configName).subConfigurationTitle,
		["texts"] = {},
		["subConfigOptions"] = {},
		["selectedIndex"] = 1,
		["isSubConfiguration"] = true
	}
	local v390_ = StoreItemUtil.getSubConfigurationIndex(storeItem, configName, self.configurations[configName] or 1)
	if vehicle ~= nil then
		v390_ = StoreItemUtil.getSubConfigurationIndex(storeItem, configName, vehicle.configurations[configName])
	end
	v389_.selectedIndex = v390_
	self.subConfigurations[configName] = v390_
	for v391_, v392_ in pairs(v387_.subConfigValues) do
		if type(v392_) == "table" then
			local v393_ = v389_.texts
			local v394_ = v392_.title
			table.insert(v393_, v394_)
			local v395_ = v392_.icon
			table.insert(v388_, v395_)
		else
			local v396_ = v389_.texts
			table.insert(v396_, v392_)
		end
		local v397_ = self:processStoreItemConfigurationOption(storeItem, configName, StoreItemUtil.getSubConfigurationItems(storeItem, configName, v391_), vehicle, true, saleItem)
		local v398_ = v389_.subConfigOptions
		table.insert(v398_, v397_)
	end
	if #v388_ > 0 then
		v389_.icons = v388_
	end
	return v389_
end

-- Local values: configOption, initialIndex, overwrittenTitle, hasValidIcons, index, _, item, isSelectable, _, bundleItem, preSelectedOption, _, otherConfigItems, _, configItem, _, dependentConfiguration, iconFilename, vehicleConfigIndex, i, item
function ShopConfigScreen:processStoreItemConfigurationOption(storeItem, configName, configItems, vehicle, isSubConfigOption)
	local v404_ = {
		["name"] = configName,
		["title"] = g_vehicleConfigurationManager:getConfigurationAttribute(configName, "title"),
		["texts"] = {},
		["icons"] = {},
		["options"] = {},
		["defaultIndex"] = 1
	}
	local v405_ = 1
	local v406_ = nil
	local v407_ = 1
	local v408_ = false
	for _, v409_ in ipairs(configItems) do
		if v409_.isDefault then
			v404_.defaultIndex = v405_
			v407_ = v405_
		end
		local v410_ = v409_.isSelectable
		if storeItem.bundleInfo ~= nil then
			for _, v411_ in ipairs(storeItem.bundleInfo.bundleItems) do
				if v411_.preSelectedConfigurations ~= nil and v411_.preSelectedConfigurations[configName] ~= nil then
					local v412_ = v411_.preSelectedConfigurations[configName]
					if v409_.index == v412_.configValue then
						v404_.defaultIndex = v405_
						v407_ = v405_
						v410_ = true
					end
					if not v412_.allowChange then
						v404_.isDisabled = true
					end
					if v412_.hideOption then
						return
					end
				end
			end
		end
		for _, v413_ in pairs(storeItem.configurations) do
			for _, v414_ in pairs(v413_) do
				if v414_.dependentConfigurations ~= nil then
					for _, v415_ in pairs(v414_.dependentConfigurations) do
						if v415_.name == configName then
							return
						end
					end
				end
			end
		end
		v406_ = v406_ or v409_.overwrittenTitle
		if v410_ then
			local v416_ = v404_.texts
			local v417_ = v409_.name
			table.insert(v416_, v417_)
			local v418_ = v404_.options
			table.insert(v418_, v409_)
			if v409_.brandIndex ~= nil then
				local v419_ = g_brandManager:getBrandIconByIndex(v409_.brandIndex)
				if v419_ ~= nil then
					local v420_ = v404_.icons
					table.insert(v420_, v419_)
					v408_ = true
				end
			end
			if #v404_.icons ~= #v404_.texts then
				local v421_ = v404_.icons
				local v422_ = v409_.name
				table.insert(v421_, v422_)
			end
			v405_ = v405_ + 1
		end
	end
	if vehicle ~= nil then
		local v423_ = vehicle.configurations[configName]
		for v424_, v425_ in ipairs(configItems) do
			if v425_.index == v423_ then
				v407_ = v424_
				break
			end
		end
	end
	v404_.defaultIndex = v407_
	v404_.title = v406_ or v404_.title
	if not v408_ then
		v404_.icons = nil
	end
	if #v404_.options > 1 or isSubConfigOption then
		return v404_
	end
end

-- Local values: overwrittenTitle, _, item
function ShopConfigScreen:processStoreItemColorOption(storeItem, configName, colorItems, colorPickerIndex, vehicle, saleItem)
	local v429_ = nil
	for _, v430_ in ipairs(colorItems) do
		v429_ = v429_ or v430_.overwrittenTitle
	end
	local v431_ = self.colorPickers
	local v432_ = {
		["title"] = v429_ or g_vehicleConfigurationManager:getConfigurationAttribute(configName, "title"),
		["configName"] = configName,
		["colorItems"] = colorItems
	}
	table.insert(v431_, v432_)
end

-- Local values: configSets, defaultSet, i, configSet, price, name, index, alreadyInOwnedVehicle, alreadyInSaleVehicle, setOptions, closestSet, _, name, index, colorPickerIndex, configurations, i, configName, configItems, isColor, _, bundleItem, configName, preSelectedOption
function ShopConfigScreen:processStoreItemConfigurations(storeItem, vehicle, saleItem)
	self.configSelection = {
		["title"] = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIGURATION_LABEL),
		["texts"] = {},
		["prices"] = {},
		["options"] = {}
	}
	self.currentConfigSet = 1
	local v437_ = storeItem.configurationSets
	local v438_ = #v437_ == 0 and {
		{
			["name"] = "",
			["configurations"] = {},
			["isDefault"] = true
		}
	} or v437_
	if storeItem.configurations == nil then
		local v439_ = self.configSelection.options
		table.insert(v439_, {})
		self.displayableColorCount = 0
	else
		for v440_, v441_ in ipairs(v438_) do
			if v441_.isDefault then
				self.currentConfigSet = v440_
			end
			if v441_.overwrittenTitle ~= nil then
				self.configSelection.title = v441_.overwrittenTitle
			end
			local v442_ = 0
			for v443_, v444_ in pairs(v441_.configurations) do
				local v445_
				if self.vehicle == nil then
					v445_ = false
				else
					v445_ = ConfigurationUtil.hasBoughtConfiguration(self.vehicle, v443_, v444_)
				end
				local v446_
				if self.saleItem == nil then
					v446_ = false
				else
					v446_ = ConfigurationUtil.hasBoughtConfiguration(self.saleItem, v443_, v444_)
				end
				if not (v445_ or v446_) then
					v442_ = v442_ + storeItem.configurations[v443_][v444_].price
				end
			end
			local v447_ = self.configSelection.prices
			table.insert(v447_, v442_)
			local v448_ = self.configSelection.texts
			local v449_ = v441_.name
			table.insert(v448_, v449_)
			local v450_ = self:processStoreItemConfigurationSet(storeItem, v441_, vehicle, saleItem)
			local v451_ = self.configSelection.options
			table.insert(v451_, v450_)
		end
		if #v438_ > 0 then
			if saleItem ~= nil then
				self.currentConfigSet = saleItem.configSetIndex or self.currentConfigSet
			end
			if vehicle ~= nil then
				local v452_, _ = ConfigurationUtil.getClosestConfigurationSet(vehicle.configurations, v438_)
				if v452_ ~= nil then
					self.currentConfigSet = v452_.index
				end
			end
		end
		for v453_, v454_ in pairs(v438_[self.currentConfigSet].configurations) do
			self.configurations[v453_] = v454_
		end
		self.colorPickers = {}
		local v455_ = g_vehicleConfigurationManager:getSortedConfigurationTypes()
		local v456_ = 1
		for v457_ = 1, #v455_ do
			local v458_ = v455_[v457_]
			local v459_ = storeItem.configurations[v458_]
			if storeItem.configurations[v458_] ~= nil then
				local v460_ = g_vehicleConfigurationManager:getConfigurationSelectorType(v458_) == ConfigurationUtil.SELECTOR_COLOR
				if #v459_ > 1 and v460_ then
					self:processStoreItemColorOption(storeItem, v458_, v459_, v456_, vehicle, saleItem)
					v456_ = v456_ + 1
				end
			end
		end
		self.displayableColorCount = v456_ - 1
	end
	if storeItem.bundleInfo ~= nil then
		for _, v461_ in ipairs(storeItem.bundleInfo.bundleItems) do
			if v461_.preSelectedConfigurations ~= nil then
				for v462_, v463_ in pairs(v461_.preSelectedConfigurations) do
					self.configurations[v462_] = v463_.configValue
				end
			end
		end
	end
end

-- Local values: item, option, color, yesNoOption, price, focusableElement
function ShopConfigScreen:getOrCreateConfigItem(type)
	local v466_
	if #self.configItemCache == 0 then
		v466_ = self.configurationItemTemplate:clone(self.configurationLayout)
	else
		v466_ = self.configItemCache[#self.configItemCache]
		self.configItemCache[#self.configItemCache] = nil
		self.configurationLayout:addElement(v466_)
	end
	v466_.isLargeConfigItem = false
	v466_:setVisible(true)
	v466_.focusId = nil
	local v467_ = false
	local v468_ = false
	local v469_ = false
	local v_u_470_ = nil
	if type == "option" then
		v_u_470_ = v466_:getDescendantByName("option")
		v467_ = true
	elseif type == "color" then
		v_u_470_ = v466_:getDescendantByName("color")
		v468_ = true
	elseif type == "yesNoOption" then
		v_u_470_ = v466_:getDescendantByName("yesNoOption")
		v469_ = true
	end
	v466_:getDescendantByName("option"):setVisible(v467_)
	v466_:getDescendantByName("color"):setVisible(v468_)
	v466_:getDescendantByName("yesNoOption"):setVisible(v469_)
	v466_:getDescendantByName("price"):setVisible(true)
	if v_u_470_ ~= nil then
		v_u_470_.forceFocusScrollToTop = self.focusableElementForScroll == nil
		self.focusableElementForScroll = v_u_470_
		v466_:getDescendantByName("title").getIsSelected = function()
			-- upvalues: (ref) v_u_470_
			return v_u_470_:getIsFocused()
		end
	end
	return v466_
end

-- Local values: item, focusableElement
function ShopConfigScreen:getOrCreateLargeConfigItem(type)
	local v472_
	if #self.configItemCacheLarge == 0 then
		v472_ = self.configurationItemTemplateLarge:clone(self.configurationLayout)
	else
		v472_ = self.configItemCacheLarge[#self.configItemCacheLarge]
		self.configItemCacheLarge[#self.configItemCacheLarge] = nil
		self.configurationLayout:addElement(v472_)
	end
	v472_.isLargeConfigItem = true
	v472_:setVisible(true)
	v472_.focusId = nil
	local v_u_473_ = v472_:getDescendantByName("option")
	v_u_473_.forceFocusScrollToTop = self.focusableElementForScroll == nil
	self.focusableElementForScroll = v_u_473_
	v472_:getDescendantByName("title").getIsSelected = function()
		-- upvalues: (copy) v_u_473_
		return v_u_473_:getIsFocused()
	end
	return v472_
end

function ShopConfigScreen:getDefaultConfigIndexByName(configName) end

-- Local values: isYesNoOption, listElement, optionElement, price
function ShopConfigScreen:updateConfigSetOptionElement(configElementIndex, storeItem, vehicle, saleItem)
	local v478_
	if #storeItem.configurationSets > 1 then
		v478_ = storeItem.configurationSets[1].isYesNoOption
	else
		v478_ = false
	end
	local v479_ = self:getOrCreateConfigItem(v478_ and "yesNoOption" or "option")
	local v480_
	if v478_ then
		v480_ = v479_:getDescendantByName("yesNoOption")
		v480_:setIsChecked(self.currentConfigSet ~= 1, true)
		v480_:setTexts(self.configSelection.texts)
	else
		v480_ = v479_:getDescendantByName("option")
		v480_:setTexts(self.configSelection.texts)
		v480_:setState(self.currentConfigSet)
	end
	v480_:setDisabled(false)
	function v480_.onClickCallback(_, p481_)
		-- upvalues: (copy) storeItem, (copy) self, (copy) vehicle, (copy) saleItem
		for v482_, _ in pairs(storeItem.configurationSets[self.currentConfigSet].configurations) do
			self.configurations[v482_] = ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[v482_])
		end
		for v483_, v484_ in pairs(storeItem.configurationSets[p481_].configurations) do
			self.configurations[v483_] = v484_
		end
		self.currentConfigSet = p481_
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateDisplay(storeItem, vehicle, saleItem)
		self:selectFirstConfig()
	end
	v479_:getDescendantByName("title"):setText(self.configSelection.title)
	local v485_ = self.configSelection.prices[self.currentConfigSet]
	v479_:getDescendantByName("price"):setText("+" .. g_i18n:formatMoney(v485_))
end

-- Local values: hasIcons, hasText, isYesNoOption, listElement, optionElement, priceElement, configName, configIndex, i, item, index
function ShopConfigScreen:updateConfigOptionElement(configElementIndex, option, storeItem, vehicle, saleItem)
	local v490_ = option.icons ~= nil
	local v491_ = not v490_
	local v492_
	if #option.options > 1 then
		v492_ = option.options[1].isYesNoOption
		if v492_ then
			v490_ = false
			v491_ = false
		end
	else
		v492_ = false
	end
	local v493_ = nil
	if v490_ then
		v493_ = self:getOrCreateLargeConfigItem("option")
	elseif v491_ then
		v493_ = self:getOrCreateConfigItem("option")
	elseif v492_ then
		v493_ = self:getOrCreateConfigItem("yesNoOption")
	end
	local v494_ = v493_:getDescendantByName(v492_ and "yesNoOption" or "option")
	v494_:setVisible(true)
	v494_:setDisabled(#option.options <= 1 and true or option.isDisabled)
	if v490_ then
		v494_:setIcons(option.icons)
	elseif v491_ then
		v494_:setTexts(option.texts)
	elseif v492_ then
		v494_:setTexts(option.texts)
	end
	local v_u_495_ = v493_:getDescendantByName("price")
	local v_u_496_ = option.name
	local v497_ = 0
	for v498_, v499_ in pairs(option.options) do
		if v499_.index == self.configurations[v_u_496_] then
			v497_ = v498_
			break
		end
	end
	if v497_ == 0 or option.options[v497_] == nil then
		v497_ = option.defaultIndex
	end
	if v492_ then
		v494_:setIsChecked(v497_ ~= 1, true)
	else
		v494_:setState(v497_)
	end
	function v494_.onClickCallback(_, p500_)
		-- upvalues: (copy) option, (copy) self, (copy) v_u_496_, (copy) v_u_495_, (copy) vehicle, (copy) storeItem
		local v501_ = option.options[p500_].index
		self:setConfigPrice(v_u_496_, v501_, v_u_495_, vehicle)
		self.configurations[v_u_496_] = v501_
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateData(storeItem, self.vehicle, self.saleItem)
	end
	local v502_
	if option.options[v497_] == nil then
		v502_ = option.defaultIndex
	else
		v502_ = option.options[v497_].index
	end
	self.configurations[v_u_496_] = v502_
	self.configurationToListElement[v_u_496_] = v493_
	v493_:getDescendantByName("title"):setText(option.title)
	self:setConfigPrice(v_u_496_, v502_, v_u_495_, vehicle)
end

-- Local values: hasIcons, listElement, optionElement, configName, subConfigIndex
function ShopConfigScreen:updateSubConfigOptionElement(configElementIndex, option, storeItem, vehicle, saleItem)
	local v508_ = option.icons ~= nil
	local v509_
	if v508_ then
		v509_ = self:getOrCreateLargeConfigItem("option")
	else
		v509_ = self:getOrCreateConfigItem("option")
	end
	local v_u_510_ = v509_:getDescendantByName("option")
	v_u_510_:setVisible(true)
	v_u_510_:setDisabled(false)
	if v508_ then
		v_u_510_:setIcons(option.icons)
	else
		v_u_510_:setTexts(option.texts)
	end
	local v_u_511_ = option.name
	local v512_ = self.subConfigurations[v_u_511_] or option.defaultIndex
	self.subConfigurations[v_u_511_] = v512_
	option.selectedIndex = v512_
	v_u_510_:setState(v512_)
	function v_u_510_.onClickCallback(_, p513_)
		-- upvalues: (copy) self, (copy) v_u_511_, (copy) option, (copy) storeItem, (copy) vehicle, (copy) saleItem, (copy) v_u_510_
		self.subConfigurations[v_u_511_] = p513_
		option.selectedIndex = p513_
		local v514_ = option.subConfigOptions[p513_].defaultIndex
		self.configurations[v_u_511_] = v514_
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
		self:updateData(storeItem, self.vehicle, saleItem)
		FocusManager:unsetFocus(v_u_510_)
		FocusManager:setFocus(v_u_510_)
	end
	v509_:getDescendantByName("price"):setVisible(false)
	v509_:getDescendantByName("title"):setText(option.title)
end

-- Local values: displayableOptionCount, count, i, item, optionData, _, option, subOption, configSets, currentConfigSet, i, option, visibility, _, bundleItem, preSelectedOption, itemsToDisplay, hasCustomColorSupport, j, listElement, colorElement, colorItems, defaultColorIndex, focusableElement
function ShopConfigScreen:updateConfigOptionsData(storeItem, vehicle, saleItem)
	if self.licensePlate ~= nil then
		self.licensePlate:delete()
		self.licensePlate = nil
	end
	self.configurationToListElement = {}
	local v519_ = 0
	local v520_ = 0
	for v521_ = #self.configurationLayout.elements, 1, -1 do
		local v522_ = self.configurationLayout.elements[v521_]
		v522_:setVisible(false)
		FocusManager:removeElement(v522_)
		v522_:unlinkElement()
		if v522_ ~= self.configurationItemPlate then
			if v522_.isLargeConfigItem then
				local v523_ = self.configItemCacheLarge
				table.insert(v523_, v522_)
			else
				local v524_ = self.configItemCache
				table.insert(v524_, v522_)
			end
		end
	end
	self.focusableElementForScroll = nil
	if #self.configSelection.options > 1 then
		v519_ = v519_ + 1
		self:updateConfigSetOptionElement(1, storeItem, vehicle, saleItem)
		v520_ = 1
	end
	local v525_ = self.configSelection.options[self.currentConfigSet]
	for _, v526_ in ipairs(v525_) do
		v519_ = v519_ + 1
		v520_ = v520_ + 1
		if v526_.isSubConfiguration then
			self:updateSubConfigOptionElement(v520_, v526_, storeItem, vehicle, saleItem)
		else
			self:updateConfigOptionElement(v520_, v526_, storeItem, vehicle, saleItem)
		end
		if v526_.isSubConfiguration then
			v519_ = v519_ + 1
			v520_ = v520_ + 1
			self:updateConfigOptionElement(v520_, v526_.subConfigOptions[v526_.selectedIndex], storeItem, vehicle, saleItem)
		end
	end
	local v527_ = storeItem.configurationSets[self.currentConfigSet]
	self.colorElements = {}
	if self.displayableColorCount > 0 then
		for v_u_528_, v_u_529_ in ipairs(self.colorPickers) do
			local v530_ = v527_ == nil or v527_.configurations[v_u_529_.configName] == nil
			if storeItem.bundleInfo ~= nil then
				for _, v531_ in ipairs(storeItem.bundleInfo.bundleItems) do
					if v531_.preSelectedConfigurations ~= nil and (v531_.preSelectedConfigurations[v_u_529_.configName] ~= nil and v531_.preSelectedConfigurations[v_u_529_.configName].hideOption) then
						v530_ = false
					end
				end
			end
			local v532_ = 0
			local v_u_533_ = false
			for v534_ = 1, #v_u_529_.colorItems do
				if v_u_529_.colorItems[v534_].isSelectable ~= false then
					v532_ = v532_ + 1
				end
				if v_u_529_.colorItems[v534_].isCustomColor then
					v_u_533_ = true
				end
			end
			if v530_ then
				v530_ = v532_ > 1
			end
			if v530_ then
				local v535_ = self:getOrCreateConfigItem("color")
				local v536_ = v535_:getDescendantByName("color")
				self.colorElements[v_u_528_] = v536_
				local v_u_537_ = v_u_529_.colorItems
				function v536_.onClickCallback(_)
					-- upvalues: (copy) self, (copy) v_u_529_, (copy) v_u_528_, (copy) v_u_537_, (ref) v_u_533_
					local v538_ = self.configurations[v_u_529_.configName]
					local v539_ = nil
					local v540_ = self.configurationData[v_u_529_.configName]
					local v541_
					if v540_ == nil or v540_[v538_] == nil then
						v541_ = nil
					else
						v539_ = v540_[v538_].color or v539_
						v541_ = v540_[v538_].materialTemplateName
						v538_ = nil
					end
					g_inputBinding:setShowMouseCursor(true)
					ColorPickerDialog.show(self.onPickColor, self, {
						["configName"] = v_u_529_.configName,
						["colorOptionIndex"] = v_u_528_
					}, v_u_537_, v538_, v541_, v539_, v_u_533_, true)
				end
				self:onPickColor(self.configurations[v_u_529_.configName] or self:getDefaultConfigurationColorIndex(v_u_529_.configName, v_u_537_, vehicle), {
					["configName"] = v_u_529_.configName,
					["colorOptionIndex"] = v_u_528_
				}, nil, true)
				v535_:getDescendantByName("title"):setText(v_u_529_.title)
				v520_ = v520_ + 1
			end
		end
	end
	if storeItem.hasLicensePlates and g_licensePlateManager:getAreLicensePlatesAvailable() then
		self.configurationLayout:addElement(self.configurationItemPlate)
		self.configurationItemPlate:setVisible(true)
		self.configurationItemPlate:reloadFocusHandling(true)
		self:updateLicensePlate()
		local v_u_542_ = self.configurationItemPlate:getDescendantByName("button")
		if v_u_542_ ~= nil then
			v_u_542_.forceFocusScrollToTop = self.focusableElementForScroll == nil
			self.focusableElementForScroll = v_u_542_
			self.configurationItemPlate:getDescendantByName("title").getIsSelected = function()
				-- upvalues: (copy) v_u_542_
				return v_u_542_:getIsFocused()
			end
		end
		v520_ = v520_ + 1
	end
	self.displayableOptionCount = v519_
	return v520_
end

-- Local values: current, num
function ShopConfigScreen:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
	local v547_ = FocusManager.currentGui
	FocusManager:setGui("ShopConfigScreen")
	local v548_ = self:updateConfigOptionsData(storeItem, vehicle, saleItem)
	self.configurationsTitle:setVisible(v548_ > 0)
	self.startClipper:setVisible(v548_ > 0)
	self.endClipper:setVisible(v548_ > 0)
	self.configSlider.parent:setVisible(v548_ > 0)
	self.configurationLayout:invalidateLayout()
	FocusManager:setGui(v547_)
	if self.needsRefocus then
		self:selectFirstConfig()
		self.needsRefocus = false
	end
end

-- Local values: _, vehicle, i, vehicle, component, x, y, z, rx, ry, rz, _, vehicle, _, _, _, _, aiMarkerWidth, canTurnBackward, allowStraightReversing
function ShopConfigScreen:update(dt)
	ShopConfigScreen:superClass().update(self, dt)
	if self.vehicle == nil or not self.vehicle.isDeleted then
		if not self.fadeInAnimation:getFinished() then
			self.fadeInAnimation:update(dt)
		end
		if not self.fadeOutAnimation:getFinished() then
			self.fadeOutAnimation:update()
		end
		if self.lastMoney ~= g_configName:getMoney() then
			self:updateBalanceText()
		end
		if self.loadingDelayTime > 0 or self.loadingDelayFrames > 0 then
			local v551_ = self.loadingDelayFrames - 1
			self.loadingDelayFrames = math.max(v551_, 0)
			local v552_ = self.loadingDelayTime - dt
			self.loadingDelayTime = math.max(v552_, 0)
			if self.loadingDelayTime <= 0 and self.loadingDelayFrames <= 0 then
				self:onFinishedLoading()
			end
		end
		for _, v553_ in pairs(self.previewVehicles) do
			v553_:update(dt)
			v553_:updateTick(dt)
		end
		g_shopController:update(dt)
		self:updateInput(dt)
		self:updateCamera(dt)
		if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
			for v554_, v555_ in pairs(self.previewVehicles) do
				local v556_ = v555_.components[1]
				if v556_ ~= nil then
					local v557_, v558_, v559_ = getWorldTranslation(v556_.node)
					local v560_, v561_, v562_ = getWorldRotation(v556_.node)
					renderText(0.35, 0.05 + (v554_ - 1) * 0.02, 0.015, string.format("Vehicle Position: Translation: %.3f %.3f %.3f Rotation: %.3f %.3f %.3f (%s)", v557_, v558_ + 100, v559_, math.deg(v560_), math.deg(v561_), math.deg(v562_), v555_:getName()))
				end
			end
		elseif VehicleDebug.state == VehicleDebug.DEBUG_AI then
			for _, v563_ in pairs(self.previewVehicles) do
				if v563_.updateAIMarkerWidth ~= nil then
					v563_:updateAIMarkerWidth()
					local _, _, _, _, v564_ = v563_:getAIMarkers()
					local v565_ = AIVehicleUtil.getAttachedImplementsAllowTurnBackward(v563_)
					local v566_ = v563_:getAIToolReverserDirectionNode() ~= nil
					setTextBold(true)
					renderText(0.35, 0.11, 0.015, "Field Course:")
					if v564_ > 0 then
						renderText(0.35, 0.09, 0.015, string.format("Width: %.1f", v564_))
						if v565_ then
							setTextColor(0, 1, 0, 1)
						elseif v566_ then
							setTextColor(1, 1, 1, 1)
						else
							setTextColor(1, 0, 0, 1)
						end
						renderText(0.35, 0.07, 0.015, string.format("Turn Backward: %s", v565_ and "Yes" or "No"))
						if v566_ then
							setTextColor(0, 1, 0, 1)
						elseif v565_ then
							setTextColor(1, 1, 1, 1)
						else
							setTextColor(1, 0, 0, 1)
						end
						renderText(0.35, 0.05, 0.015, string.format("Straight Reversing: %s", v566_ and "Yes" or "No"))
					else
						renderText(0.35, 0.09, 0.015, "Not supported")
					end
					setTextColor(1, 1, 1, 1)
					setTextBold(false)
				end
			end
		end
	else
		self:onClickBack()
		self.vehicle = nil
		return
	end
end

-- Local values: camPosX, camPosY, camPosZ, targetPosX, targetPosY, targetPosZ, dx, dy, dz, posX, posY, posZ, lx, ly, lz, projectionOffsetX, direction, ratio, doublePi, cameraAlpha, offsetFactor
function ShopConfigScreen:updateCamera(dt)
	setTranslation(self.rotateNode, self.workshopWorldPosition[1], self.workshopWorldPosition[2] + self.focusY, self.workshopWorldPosition[3])
	setRotation(self.rotateNode, self.rotX, self.rotY, 0)
	local v568_, v569_, v570_ = getWorldTranslation(self.cameraPositionNode)
	local v571_, v572_, v573_ = getWorldTranslation(self.rotateNode)
	local v574_, v575_, v576_ = MathUtil.vector3Normalize(v571_ - v568_, v572_ - v569_, v573_ - v570_)
	local v577_ = v571_ - v574_ * self.cameraDistance
	local v578_ = v572_ - v575_ * self.cameraDistance
	local v579_ = v573_ - v576_ * self.cameraDistance
	local v580_, v581_, v582_ = worldToLocal(self.rotateNode, v577_, v578_, v579_)
	setTranslation(self.cameraPositionNode, v580_, v581_, v582_)
	local v583_ = self.shopConfigContent.parent:getIsVisible() and -0.15625 or 0
	local v584_ = self.vehicleSizeX / self.vehicleSizeZ
	local v585_
	if self.vehicleSizeX > self.vehicleSizeZ then
		v584_ = self.vehicleSizeZ / self.vehicleSizeX
		v585_ = -1
	else
		v585_ = 1
	end
	local v586_ = 1 - math.clamp(v584_, 0, 1)
	local v587_ = self.rotY % 6.283185307179586 / 6.283185307179586
	local v588_ = 0
	if v587_ >= 0 and v587_ < 0.25 then
		v588_ = v587_ / 0.125
		if v588_ > 1 then
			v588_ = 1 - (v588_ - 1)
		end
	elseif v587_ >= 0.25 and v587_ < 0.5 then
		local v589_ = (v587_ - 0.25) / 0.125
		if v589_ > 1 then
			v589_ = 1 - (v589_ - 1)
		end
		v588_ = -v589_
	elseif v587_ >= 0.5 and v587_ < 0.75 then
		v588_ = (v587_ - 0.5) / 0.125
		if v588_ > 1 then
			v588_ = 1 - (v588_ - 1)
		end
	elseif v587_ >= 0.75 and v587_ < 1 then
		local v590_ = (v587_ - 0.75) / 0.125
		if v590_ > 1 then
			v590_ = 1 - (v590_ - 1)
		end
		v588_ = -v590_
	end
	local v591_ = v583_ - v588_ * 0.1 * v585_ * v586_
	setProjectionOffset(self.cameraNode, v591_, 0.07)
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

-- Local values: licensePlate, cameraNode, fovY, tolerance, distance
function ShopConfigScreen:updateLicensePlate()
	if self.licensePlateRender ~= nil and self.licensePlaceLinkNode ~= nil then
		local v596_ = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
		if v596_ ~= nil then
			link(self.licensePlaceLinkNode, v596_.node)
			setTranslation(v596_.node, 0, 0, 0)
			setRotation(v596_.node, 0, 0, 0)
			if self.licensePlate ~= nil then
				self.licensePlate:delete()
			end
			self.licensePlate = v596_
			self:updateLicensePlateGraphics()
			local v597_ = I3DUtil.indexToObject(self.licensePlateRender.scene, self.licensePlateRender.cameraPath)
			if v597_ ~= nil then
				local v598_ = getFovY(v597_)
				local v599_ = self.licensePlate.width / 2 + 0.005
				local v600_ = v598_ / 2
				local v601_ = v599_ / math.tan(v600_) / (self.licensePlateRender.absSize[1] * (v596_.width / v596_.height / 5) / self.licensePlateRender.absSize[2] * g_screenAspectRatio)
				setTranslation(v597_, 0, 0, v601_)
			end
		end
	end
end

-- Local values: currentVariation, currentColorIndex, currentCharacters
function ShopConfigScreen:updateLicensePlateGraphics()
	local v603_ = self.licensePlateData.variation or 1
	local v604_ = self.licensePlateData.colorIndex or 1
	local v605_ = table.clone(self.licensePlateData.characters, math.huge)
	if self.licensePlate ~= nil then
		self.licensePlate:updateData(v603_, LicensePlateManager.PLATE_POSITION.BACK, table.concat(v605_, ""))
		self.licensePlate:setColorIndex(v604_)
		self.licensePlateRender:setRenderDirty()
	end
	if #self.previewVehicles == 0 then
		self.licensePlateRender.parent:setText("")
		self.licensePlateRender:setVisible(false)
		return
	elseif self.licensePlateData.placementIndex == LicensePlateManager.PLATE_POSITION.NONE then
		self.licensePlateRender.parent:setText(g_i18n:getText("configuration_valueLicensePlateNone"))
		self.licensePlateRender:setVisible(false)
	else
		self.licensePlateRender.parent:setText("")
		self.licensePlateRender:setVisible(true)
	end
end

-- Local values: posX, posY, width, height
function ShopConfigScreen:onOpen(element)
	ShopConfigScreen:superClass().onOpen(self)
	self.openCounter = self.openCounter + 1
	local v607_ = self.configurationsBox.absPosition
	local v608_, v609_ = unpack(v607_)
	local v610_ = self.configurationsBox.absSize
	local v611_, v612_ = unpack(v610_)
	g_depthOfFieldManager:pushArea(v608_, v609_, v611_, v612_)
	self:onMoneyChange()
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
	g_gameStateManager:setGameState(GameState.MENU_SHOP_CONFIG)
	g_configName.environment:setCustomLighting(self.shopLighting)
	g_configName.environment:setSunVisibility(false)
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
	g_configName.environment:setSunVisibility(true)
	g_configName.environment:setCustomLighting(nil)
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
	g_configName:resetGameState()
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

-- Local values: _, _, hasChanges, enoughMoney, enoughSlots, text, callback, target
function ShopConfigScreen:onClickBuy()
	local _, _, v615_ = self:getConfigurationCostsAndChanges(self.storeItem, self.vehicle, self.saleItem)
	if v615_ then
		local v616_ = self.totalPrice <= 0 and true or g_configName:getMoney() >= self.totalPrice
		local v617_ = g_configName.slotSystem:hasEnoughSlots(self.storeItem)
		g_inputBinding:setShowMouseCursor(true)
		if v616_ then
			if v617_ then
				self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
				local v618_ = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), g_i18n:formatMoney(self.totalPrice, 0, true, true))
				local v619_ = self.onYesNoBuy
				YesNoDialog.show(v619_, self, v618_, nil, nil, nil, nil, nil, nil, nil, true)
			else
				self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
				InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS), nil, nil, DialogElement.TYPE_WARNING, nil, nil, nil, true)
			end
		else
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
			InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY), nil, nil, DialogElement.TYPE_WARNING, nil, nil, nil, true)
			return
		end
	else
		return
	end
end

function ShopConfigScreen:onClickConfigAction()
	if self.focusedColorElement == nil then
		if self.focusedButtonElement ~= nil then
			self.focusedButtonElement:onFocusActivate()
		end
	else
		self.focusedColorElement:onFocusActivate()
	end
end

function ShopConfigScreen:onClickLicensePlate()
	LicensePlateDialog.show(self.licensePlateData, self.onChangeLicensePlate, self)
end

-- Local values: i, vehicle
function ShopConfigScreen:onChangeLicensePlate(licensePlateData)
	if licensePlateData ~= nil then
		self.licensePlateData = licensePlateData
		self.licensePlateData.customized = true
		for v624_ = 1, #self.previewVehicles do
			local v625_ = self.previewVehicles[v624_]
			if v625_.setLicensePlatesData ~= nil then
				v625_:setLicensePlatesData(self.licensePlateData)
			end
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

-- Local values: visible
function ShopConfigScreen:updateConfigurationButton()
	local v630_ = self.focusedButtonElement ~= nil and true or self.focusedColorElement ~= nil
	self.configButton:setVisible(v630_)
	self.buttonsPanel:invalidateLayout()
end

function ShopConfigScreen:onYesNoBuy(yes)
	if yes then
		self:onCallback(false)
	end
end

function ShopConfigScreen:onVehicleBought()
	if GS_IS_CONSOLE_VERSION then
		self:selectFirstConfig()
	else
		FocusManager:setFocus(self.buyButton)
	end
end

function ShopConfigScreen:onStoreItemsReloaded()
	if self.storeItem ~= nil and g_gui.currentGuiName == "ShopConfigScreen" then
		self.needsRefocus = true
		self.storeItem = g_storeManager:getItemByXMLFilename(self.storeItem.xmlFilename)
		self:setStoreItem(self.storeItem, nil, nil, nil, self.configurations)
	end
end

-- Local values: enoughMoney, enoughSlots, costsBase, initialCosts, costsPerOperatingHour, costsPerDay
function ShopConfigScreen:onClickLease()
	if self.vehicle == nil then
		if self.storeItem.allowLeasing then
			local v636_ = g_configName:getMoney() >= self.initialLeasingCosts
			local v637_ = g_configName.slotSystem:hasEnoughSlots(self.storeItem)
			g_inputBinding:setShowMouseCursor(true)
			if v636_ then
				if v637_ then
					self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
					local v638_ = self.totalPrice * EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR
					local v639_ = self.initialLeasingCosts
					local v640_ = self.totalPrice * EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR
					local v641_ = self.totalPrice * EconomyManager.PER_DAY_LEASING_FACTOR
					LeaseYesNoDialog.show(self.onYesNoLease, self, v638_, v639_, v640_, v641_)
				else
					self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
					InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS), nil, nil, DialogElement.TYPE_WARNING)
				end
			else
				self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
				InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_LEASE), nil, nil, DialogElement.TYPE_WARNING)
				return
			end
		else
			return
		end
	else
		return
	end
end

function ShopConfigScreen:onYesNoLease(yes)
	if yes then
		self:onCallback(true)
	end
end

-- Local values: eventUnused
function ShopConfigScreen:onClickShop()
	local v645_ = ShopConfigScreen:superClass().onClickShop(self)
	if v645_ then
		self:requestExitCallback()
		v645_ = false
	end
	return v645_
end

-- Local values: vehicleBuyData, vehicleId
function ShopConfigScreen:onCallback(leaseItem)
	local v648_ = BuyVehicleData.new()
	v648_:setStoreItem(self.storeItem)
	v648_:setConfigurations(self.configurations, self.boughtConfigurations)
	v648_:setConfigurationData(self.configurationData)
	v648_:setLeaseVehicle(leaseItem)
	v648_:setOwnerFarmId(g_shopController.playerFarmId)
	v648_:setLicensePlateData(self.licensePlateData)
	v648_:setSaleItem(self.saleItem)
	v648_:setPrice(leaseItem and 0 or self.totalPrice)
	local v649_ = NetworkUtil.getObjectId(self.vehicle)
	if self.callbackFunc ~= nil then
		if self.target == nil then
			self.callbackFunc(v648_, v649_)
		else
			self.callbackFunc(self.target, v648_, v649_)
		end
		self.configurations = table.clone(self.configurations)
	end
end

-- Local values: platformActions
function ShopConfigScreen:updateInputGlyphs()
	self.zoomGlyph:setActions({ InputAction.AXIS_MAP_ZOOM_IN, InputAction.AXIS_MAP_ZOOM_OUT })
	local v651_
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		v651_ = { InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, InputAction.AXIS_LOOK_UPDOWN_VEHICLE }
	else
		v651_ = { InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, InputAction.AXIS_LOOK_UPDOWN_DRAG }
	end
	self.lookGlyph:setActions(v651_)
end

-- Local values: isVisible, posX, posY, width, height
function ShopConfigScreen:toggleHUDVisible()
	local v653_ = self.shopConfigContent.parent:getIsVisible()
	if v653_ then
		g_depthOfFieldManager:popArea()
	else
		local v654_ = self.configurationsBox.absPosition
		local v655_, v656_ = unpack(v654_)
		local v657_ = self.configurationsBox.absSize
		local v658_, v659_ = unpack(v657_)
		g_depthOfFieldManager:pushArea(v655_, v656_, v658_, v659_)
	end
	self.shopConfigContent.parent:setVisible(not v653_)
end

-- Local values: isController, _
function ShopConfigScreen:registerInputActions()
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, false)
	g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, false)
	local v661_ = g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD
	local _, v662_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, self.onCameraUpDown, false, false, true, v661_)
	self.eventIdUpDownController = v662_
	local _, v663_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onCameraLeftRight, false, false, true, v661_)
	self.eventIdLeftRightController = v663_
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_IN, self, self.onCameraZoom, false, false, true, true, -1)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_OUT, self, self.onCameraZoom, false, false, true, true, 1)
	local _, v664_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_DRAG, self, self.onCameraUpDown, false, false, true, not v661_)
	self.eventIdUpDownMouse = v664_
	local _, v665_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, self, self.onCameraLeftRight, false, false, true, not v661_)
	self.eventIdLeftRightMouse = v665_
end

-- Local values: dragValue
function ShopConfigScreen:onCameraLeftRight(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE then
		self.inputHorizontal = inputValue * -1 * 0.001 * g_currentDt
	elseif not self.configSlider.mouseDown then
		local v669_ = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
		local v670_ = self.accumDraggingInput
		local v671_ = v669_ * g_screenAspectRatio
		self.accumDraggingInput = v670_ + math.abs(v671_)
		if self.accumDraggingInput >= ShopConfigScreen.MIN_MOUSE_DRAG_INPUT then
			self.inputDragging = true
			self.inputHorizontal = v669_ * 0.001 * 16.666
			return
		end
		self.inputHorizontal = 0
	end
end

-- Local values: dragValue
function ShopConfigScreen:onCameraUpDown(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.AXIS_LOOK_UPDOWN_VEHICLE then
		self.inputVertical = inputValue * 0.001 * g_currentDt
	elseif not self.configSlider.mouseDown then
		local v675_ = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
		self.accumDraggingInput = self.accumDraggingInput + math.abs(v675_)
		if self.accumDraggingInput >= ShopConfigScreen.MIN_MOUSE_DRAG_INPUT then
			self.inputDragging = true
			self.inputVertical = v675_ * 0.001 * 16.666
			return
		end
		self.inputVertical = 0
	end
end

-- Local values: mouseX, mouseY, cursorOnSlider, cursorInList, modifier
function ShopConfigScreen:onCameraZoom(actionName, inputValue, direction, isAnalog, isMouse)
	if isMouse and self.configSlider:getIsVisible() then
		local v681_, v682_ = g_inputBinding:getMousePosition()
		if GuiUtils.checkOverlayOverlap(v681_, v682_, self.configSlider.absPosition[1], self.configSlider.absPosition[2], self.configSlider.size[1], self.configSlider.size[2]) then
			return
		end
		if GuiUtils.checkOverlayOverlap(v681_, v682_, self.configurationLayout.absPosition[1], self.configurationLayout.absPosition[2], self.configurationLayout.size[1], self.configurationLayout.size[2]) then
			return
		end
	end
	local v683_ = 0.05 * direction
	if not isAnalog then
		v683_ = 0.2 * direction
		if isMouse then
			v683_ = v683_ * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
		end
	end
	self.inputZoom = self.inputZoom + inputValue * v683_
end

-- Local values: value, value, minDistance, maxDistance, inputHelpMode
function ShopConfigScreen:updateInput(dt)
	self:updateInputContext()
	if self.inputVertical ~= 0 then
		local v686_ = self.inputVertical
		self.inputVertical = 0
		self.rotX = self.rotX - v686_
	end
	if self.inputHorizontal ~= 0 then
		local v687_ = self.inputHorizontal
		self.inputHorizontal = 0
		self.rotY = self.rotY - v687_
	end
	if self.inputZoom ~= 0 then
		local v688_ = self.cameraMinDistance
		local v689_ = self.cameraMaxDistance
		self.zoomTarget = self.zoomTarget + dt * self.inputZoom * 0.1
		local v690_ = self.zoomTarget
		self.zoomTarget = math.clamp(v690_, v688_, v689_)
		self.inputZoom = 0
	end
	self.cameraDistance = self.zoomTarget + math.pow(0.99579, dt) * (self.cameraDistance - self.zoomTarget)
	self.rotX = self:limitXRotation(self.rotX)
	local v691_ = g_inputBinding:getInputHelpMode()
	if v691_ ~= self.lastInputHelpMode then
		self.lastInputHelpMode = v691_
		self:updateInputGlyphs()
	end
	if self.isDragging or not self.inputDragging then
		if self.isDragging and not self.inputDragging then
			self.isDragging = false
			g_inputBinding:setShowMouseCursor(true)
			self.accumDraggingInput = 0
		end
	else
		self.isDragging = true
		g_inputBinding:setShowMouseCursor(false, true)
	end
	self.inputDragging = false
end

-- Local values: camHeight, maxHeight, rotMinX, rotMaxX, minHeight
function ShopConfigScreen:limitXRotation(currentXRotation)
	local v694_ = self.cameraDistance * math.sin(currentXRotation) + self.focusY
	local v695_ = ShopConfigScreen.MAX_CAMERA_HEIGHT - self.focusY
	local v696_ = math.min(v694_, v695_)
	local v697_ = self.rotMinX
	local v698_ = self.rotMaxX
	if v696_ <= self.cameraDistance then
		local v699_ = v696_ / self.cameraDistance
		local v700_ = math.asin(v699_)
		v698_ = math.min(v698_, v700_)
	end
	local v701_ = (ShopConfigScreen.MIN_CAMERA_HEIGHT - self.focusY) / self.cameraDistance
	local v702_ = math.asin(v701_)
	local v703_ = math.max(v697_, v702_)
	local v704_ = math.min(v698_, currentXRotation)
	return math.max(v703_, v704_)
end

-- Local values: currentInputMode, isController
function ShopConfigScreen:updateInputContext()
	local v706_ = g_inputBinding:getLastInputMode()
	if v706_ ~= self.lastInputMode then
		local v707_ = v706_ == GS_INPUT_HELP_MODE_GAMEPAD
		g_inputBinding:setActionEventActive(self.eventIdUpDownController, v707_)
		g_inputBinding:setActionEventActive(self.eventIdLeftRightController, v707_)
		g_inputBinding:setActionEventActive(self.eventIdUpDownMouse, not v707_)
		g_inputBinding:setActionEventActive(self.eventIdLeftRightMouse, not v707_)
		self.lastInputMode = v706_
		self.isDragging = false
		g_inputBinding:setShowMouseCursor(true)
	end
end

function ShopConfigScreen:consoleCommandUIToggle()
	self:toggleHUDVisible()
	local v709_ = self.shopConfigContent
	return "ShopConfigScreen hudVisible=" .. tostring(v709_:getIsVisible())
end

function ShopConfigScreen:inputEvent(action, value, eventUsed)
	local v714_ = ShopConfigScreen:superClass().inputEvent(self, action, value, eventUsed)
	if not v714_ and action == InputAction.TOGGLE_STORE then
		self:onClickBack()
		self.target:onClickBack()
		g_gui:changeScreen(nil)
		v714_ = true
	end
	return v714_
end
ShopConfigScreen.GUI_PROFILE = {
	["MAINTENANCE_COST"] = "shopConfigAttributeIconMaintenanceCosts",
	["POWER"] = "shopConfigAttributeIconPower",
	["TRANSMISSION"] = "shopConfigAttributeIconTransmission",
	["FUEL"] = "shopConfigAttributeIconFuel",
	["ELECTRICCHARGE"] = "shopConfigAttributeIconElectricCharge",
	["METHANE"] = "shopConfigAttributeIconMethane",
	["MAX_SPEED"] = "shopConfigAttributeIconMaxSpeed",
	["CAPACITY"] = "shopConfigAttributeIconCapacity",
	["WEIGHT"] = "shopConfigAttributeIconWeight",
	["ADDITIONAL_WEIGHT"] = "shopConfigAttributeIconAdditionalWeight",
	["WORKING_WIDTH"] = "shopConfigAttributeIconWorkingWidth",
	["WORKING_SPEED"] = "shopConfigAttributeIconWorkSpeed",
	["POWER_REQUIREMENT"] = "shopConfigAttributeIconPowerReq",
	["WHEELS"] = "shopConfigAttributeIconWheels",
	["BALE_SIZE_ROUND"] = "shopConfigAttributeIconBaleSizeRound",
	["BALE_SIZE_SQUARE"] = "shopConfigAttributeIconBaleSizeSquare",
	["BALEWRAPPER_SIZE_ROUND"] = "shopConfigAttributeIconBaleWrapperBaleSizeRound",
	["BALEWRAPPER_SIZE_SQUARE"] = "shopConfigAttributeIconBaleWrapperBaleSizeSquare",
	["MAX_TREE_SIZE"] = "shopConfigAttributeIconMaxTreeSize",
	["MAX_TREE_MASS"] = "shopConfigAttributeIconMaxTreeMass",
	["YARDER_MAX_LENGTH"] = "shopConfigAttributeIconYarderMaxLength",
	["BUTTON_BUY"] = "buttonBuy"
}
ShopConfigScreen.L10N_SYMBOL = {
	["MAINTENANCE_COST"] = "shop_maintenanceValue",
	["POWER"] = "shopConfig_maxPowerValue",
	["FUEL"] = "shop_fuelValue",
	["FUEL_DEF"] = "shopConfig_fuelDefValue",
	["MAX_SPEED"] = "shop_maxSpeed",
	["CAPACITY"] = "shop_capacityValue",
	["WORKING_WIDTH"] = "shop_workingWidthValue",
	["WORKING_SPEED"] = "shop_maxSpeed",
	["POWER_REQUIREMENT"] = "shopConfig_neededPowerValue",
	["BUTTON_BUY"] = "button_buy",
	["BUTTON_CONFIGURE"] = "button_configurate",
	["UNIT_LITER"] = "unit_literShort",
	["UNIT_KW"] = "unit_kw",
	["UNIT_KG"] = "unit_kg",
	["DEF_SHORT"] = "fillType_def_short",
	["NOT_ENOUGH_MONEY_BUY"] = "shop_messageNotEnoughMoneyToBuy",
	["NOT_ENOUGH_MONEY_LEASE"] = "shop_messageNotEnoughMoneyToLease",
	["TOO_FEW_SLOTS"] = "shop_messageNotEnoughSlotsToBuy",
	["CONFIRM_BUY"] = "shop_doYouWantToBuy",
	["CONFIRM_LEASE"] = "shop_doYouWantToLease",
	["CONFIGURATION_LABEL"] = "shop_configuration"
}
ShopConfigScreen.SIZE = {
	["INPUT_GLYPH"] = { 48, 48 }
}
