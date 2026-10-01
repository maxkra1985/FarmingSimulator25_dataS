InGameMenuMobileMapFrame = {}
local InGameMenuMobileMapFrame_mt = Class(InGameMenuMobileMapFrame, TabbedMenuFrameElement)
InGameMenuMobileMapFrame.MODE_NONE = 0
InGameMenuMobileMapFrame.MODE_OVERVIEW = 1
InGameMenuMobileMapFrame.MODE_AI_PAGE = 2
InGameMenuMobileMapFrame.MODE_CREATE_JOB = 3
InGameMenuMobileMapFrame.MAP_FRUIT_TYPE = 1
InGameMenuMobileMapFrame.MAP_GROWTH = 2
InGameMenuMobileMapFrame.MAP_SOIL = 3
InGameMenuMobileMapFrame.MAP_HOTSPOTS = InGameMenuMobileMapFrame.MAP_FRUIT_TYPE
InGameMenuMobileMapFrame.PAGE_ID = { STATUS = 1, VEHICLES = 2, POINTS = 3, FIELDS = 4, AI = 5 }
InGameMenuMobileMapFrame.PAGE_NAMES = { [InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = "ui_inGameMenuVehicles", [InGameMenuMobileMapFrame.PAGE_ID.POINTS] = "ui_inGameMenuPointsOfInterest", [InGameMenuMobileMapFrame.PAGE_ID.STATUS] = "ui_inGameMenuFieldStatus", [InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = "ui_inGameMenuFields", [InGameMenuMobileMapFrame.PAGE_ID.AI] = "ui_helpers" }
InGameMenuMobileMapFrame.SECTION_NAMES = { VEHICLES = { "ui_mapHotspotFilter_driveables", "ui_mapHotspotFilter_tools", "helpLine_Animals_Horses" }, POINTS = { "ui_mapHotspotFilter_buyingSelling", "ui_mapHotspotFilter_productionPoints", "ui_mapHotspotFilter_animals", "ui_mapHotspotFilter_others" }, FIELDS = { "ui_mapPageFields_ownedByYou", "ui_mapPageFields_availableToBuy" } }
InGameMenuMobileMapFrame.HOTSPOT_FILTERS = { LOADING = 1, PRODUCTIONS = 2, ANIMALS = 3, OTHER = 4 }
InGameMenuMobileMapFrame.FIELD_STATUS = { "ui_mapViewMode2", "ui_mapViewMode1", "ui_mapOverviewSoil" }
InGameMenuMobileMapFrame.HOTSPOT_SWITCH_CATEGORIES = { [InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = { [MapHotspot.CATEGORY_TOOL] = true, [MapHotspot.CATEGORY_TRAILER] = true, [MapHotspot.CATEGORY_COMBINE] = true, [MapHotspot.CATEGORY_STEERABLE] = true, [MapHotspot.CATEGORY_AI] = true }, [InGameMenuMobileMapFrame.PAGE_ID.POINTS] = { [MapHotspot.CATEGORY_ANIMAL] = true, [MapHotspot.CATEGORY_LOADING] = true, [MapHotspot.CATEGORY_OTHER] = true }, [InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = { [MapHotspot.CATEGORY_FIELD] = true }, [InGameMenuMobileMapFrame.PAGE_ID.AI] = { [MapHotspot.CATEGORY_TOOL] = true, [MapHotspot.CATEGORY_TRAILER] = true, [MapHotspot.CATEGORY_COMBINE] = true, [MapHotspot.CATEGORY_STEERABLE] = true, [MapHotspot.CATEGORY_AI] = true, [MapHotspot.CATEGORY_ANIMAL] = true, [MapHotspot.CATEGORY_LOADING] = true, [MapHotspot.CATEGORY_OTHER] = true }, [MapHotspot.CATEGORY_PLAYER] = true }
InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO = {
	[InGameMenuMobileMapFrame.PAGE_ID.STATUS] = { MapHotspot.CATEGORY_FIELD, MapHotspot.CATEGORY_MISSION, MapHotspot.CATEGORY_TOUR, MapHotspot.CATEGORY_STEERABLE, MapHotspot.CATEGORY_COMBINE, MapHotspot.CATEGORY_TRAILER, MapHotspot.CATEGORY_TOOL, MapHotspot.CATEGORY_AI, MapHotspot.CATEGORY_ANIMAL, MapHotspot.CATEGORY_UNLOADING, MapHotspot.CATEGORY_LOADING, MapHotspot.CATEGORY_PRODUCTION, MapHotspot.CATEGORY_SHOP, MapHotspot.CATEGORY_OTHER, MapHotspot.CATEGORY_PLAYER },
	[InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = { MapHotspot.CATEGORY_FIELD, MapHotspot.CATEGORY_ANIMAL, MapHotspot.CATEGORY_MISSION, MapHotspot.CATEGORY_TOUR, MapHotspot.CATEGORY_UNLOADING, MapHotspot.CATEGORY_LOADING, MapHotspot.CATEGORY_PRODUCTION, MapHotspot.CATEGORY_SHOP, MapHotspot.CATEGORY_OTHER, MapHotspot.CATEGORY_STEERABLE, MapHotspot.CATEGORY_COMBINE, MapHotspot.CATEGORY_TRAILER, MapHotspot.CATEGORY_TOOL, MapHotspot.CATEGORY_AI, MapHotspot.CATEGORY_PLAYER },
	[InGameMenuMobileMapFrame.PAGE_ID.POINTS] = { MapHotspot.CATEGORY_FIELD, MapHotspot.CATEGORY_MISSION, MapHotspot.CATEGORY_TOUR, MapHotspot.CATEGORY_STEERABLE, MapHotspot.CATEGORY_COMBINE, MapHotspot.CATEGORY_TRAILER, MapHotspot.CATEGORY_TOOL, MapHotspot.CATEGORY_AI, MapHotspot.CATEGORY_ANIMAL, MapHotspot.CATEGORY_UNLOADING, MapHotspot.CATEGORY_LOADING, MapHotspot.CATEGORY_PRODUCTION, MapHotspot.CATEGORY_SHOP, MapHotspot.CATEGORY_OTHER, MapHotspot.CATEGORY_PLAYER },
	[InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = { MapHotspot.CATEGORY_MISSION, MapHotspot.CATEGORY_TOUR, MapHotspot.CATEGORY_OTHER, MapHotspot.CATEGORY_STEERABLE, MapHotspot.CATEGORY_COMBINE, MapHotspot.CATEGORY_TRAILER, MapHotspot.CATEGORY_TOOL, MapHotspot.CATEGORY_ANIMAL, MapHotspot.CATEGORY_UNLOADING, MapHotspot.CATEGORY_LOADING, MapHotspot.CATEGORY_PRODUCTION, MapHotspot.CATEGORY_SHOP, MapHotspot.CATEGORY_AI, MapHotspot.CATEGORY_FIELD, MapHotspot.CATEGORY_PLAYER },
	[InGameMenuMobileMapFrame.PAGE_ID.AI] = { MapHotspot.CATEGORY_FIELD, MapHotspot.CATEGORY_MISSION, MapHotspot.CATEGORY_TOUR, MapHotspot.CATEGORY_ANIMAL, MapHotspot.CATEGORY_UNLOADING, MapHotspot.CATEGORY_LOADING, MapHotspot.CATEGORY_PRODUCTION, MapHotspot.CATEGORY_SHOP, MapHotspot.CATEGORY_OTHER, MapHotspot.CATEGORY_STEERABLE, MapHotspot.CATEGORY_COMBINE, MapHotspot.CATEGORY_TRAILER, MapHotspot.CATEGORY_TOOL, MapHotspot.CATEGORY_AI, MapHotspot.CATEGORY_PLAYER },
}
InGameMenuMobileMapFrame.BUTTON_TEXTS = { SET_MARKER = "action_tag", REMOVE_MARKER = "action_untag", VEHICLE_RESET = "button_reset", DIALOG_VEHICLE_RESET_DONE = "ui_vehicleResetDone", DIALOG_VEHICLE_RESET_FAILED = "ui_vehicleResetFailed", DIALOG_VEHICLE_IN_USE = "shop_messageReturnVehicleInUse", DIALOG_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionGeneral", DIALOG_VEHICLE_RESET_CONFIRM = "ui_wantToResetVehicleText", DIALOG_BUY_FARMLAND_TITLE = "shop_messageBuyFarmlandTitle", DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY = "shop_messageNotEnoughMoneyToBuyFarmland", MOBILE_BUY_FIELD_TEXT = "ui_mobile_buyFieldDialogText", MOBILE_BUY_FIELD_TEXT_COINS = "ui_mobile_buyFieldDialogText_buyCoins", BUTTON_CLOSE_MAP = "button_closeMap", BUTTON_CANCEL = "button_cancel" }
InGameMenuMobileMapFrame.CLEAR_INPUT_ACTIONS = { InputAction.MENU_ACCEPT, InputAction.MENU_ACTIVATE, InputAction.MENU_CANCEL, InputAction.MENU_EXTRA_1, InputAction.MENU_EXTRA_2, InputAction.SWITCH_VEHICLE, InputAction.SWITCH_VEHICLE_BACK, InputAction.CAMERA_ZOOM_IN_OUT, InputAction.MENU_AXIS_LEFT_RIGHT }
InGameMenuMobileMapFrame.CLEAR_CLOSE_INPUT_ACTIONS = { InputAction.SWITCH_VEHICLE, InputAction.SWITCH_VEHICLE_BACK, InputAction.CAMERA_ZOOM_IN_OUT }
local NO_CALLBACK = function() end
InGameMenuMobileMapFrame.INPUT_CONTEXT_NAME = "MENU_MOBILE_MAP"
function InGameMenuMobileMapFrame.register()
	if Platform.isMobile then
		local inGameMenuMobileMapFrame = InGameMenuMobileMapFrame.new()
		g_gui:loadGui("dataS/gui/InGameMenuMobileMapFrame.xml", "MobileMapFrame", inGameMenuMobileMapFrame, true)
	end
end
function InGameMenuMobileMapFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMobileMapFrame_mt)
	self.onClickBackCallback = NO_CALLBACK
	self.client = nil
	self.playerFarm = nil
	self.statusMessages = {}
	self.mode = InGameMenuMobileMapFrame.MODE_NONE
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	self.fruitTypeFilter = {}
	self.fruitTypeFilterMapping = {}
	self.growthStateFilter = {}
	self.soilStateFilter = {}
	self.fieldStatusFilters = { [InGameMenuMobileMapFrame.MAP_FRUIT_TYPE] = self.fruitTypeFilter, [InGameMenuMobileMapFrame.MAP_GROWTH] = self.growthStateFilter, [InGameMenuMobileMapFrame.MAP_SOIL] = self.soilStateFilter }
	self.foliageStateOverlay = nil
	self.foliageStateOverlayIsReady = false
	function self.overviewOverlayFinishedCallback(overlayId)
		self:onOverviewOverlayFinished(overlayId)
	end
	self.inGameMapBase = nil
	self.needsSolidBackground = Platform.ingameMap.needsSolidBackground
	self.isOpening = true
	self.blockListSelectionEvents = false
	self.hasFullScreenMap = true
	self.goToMainOverview = false
	self.pageLists = {}
	self.vehicles = {}
	self.fieldStatus = {}
	self.fields = {}
	self.hotspotsSorted = {}
	self.hotspotFiltersActive = { true, true, true, true }
	self.hotspotFiltersMapping = {}
	self.marqueeBoxes = {}
	self.clonedElements = {}
	self.currentHotspot = nil
	self.currentList = nil
	self.currentListItem = nil
	self.jobTypeInstances = {}
	self.statusMessages = {}
	self.currentJob = nil
	self.hasPickedLocationTouch = false
	self.hasPickedRotationTouch = false
	self.lastTouchPosX = 0
	self.lastTouchPosY = 0
	self.updateTime = 0
	self.aiTargetMapHotspot = AITargetHotspot.new()
	self.pickingRotationSnapAngle = 0
	return self
end
function InGameMenuMobileMapFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuMobileMapFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function InGameMenuMobileMapFrame:copyAttributes(src)
	InGameMenuMobileMapFrame:superClass().copyAttributes(self, src)
	self.onClickBackCallback = src.onClickBackCallback or NO_CALLBACK
end
function InGameMenuMobileMapFrame:delete()
	InGameMenuMobileMapFrame:superClass().delete(self)
	if self.aiTargetMapHotspot ~= nil then
		self.aiTargetMapHotspot:delete()
		self.aiTargetMapHotspot = nil
	end
end
function InGameMenuMobileMapFrame:initialize(onClickBackCallback)
	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK
	self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
	self.buttonsResizeNeeded = { self.buttonSelectInGame, self.buttonEnterVehicle, self.buttonResetVehicle, self.buttonGoToJob, self.buttonCreateJob }
	self.pageLists = { [InGameMenuMobileMapFrame.PAGE_ID.STATUS] = self.statusList, [InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = self.vehiclesList, [InGameMenuMobileMapFrame.PAGE_ID.POINTS] = self.pointsList, [InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = self.fieldsList, [InGameMenuMobileMapFrame.PAGE_ID.AI] = self.aiWorkersList }
	self.currentList = self.statusList
	self.vehiclesList.detailsBox = self.vehicleDetailsBox
	self.pointsList.detailsBox = self.pointDetailsBox
	self.aiWorkersList.detailsBox = self.aiDetailsBox
	self.mapPageSelector.texts = {}
	for _, pageName in pairs(InGameMenuMobileMapFrame.PAGE_NAMES) do
		table.insert(self.mapPageSelector.texts, g_i18n:getText(pageName))
	end
	for i, pageButton in pairs(self.pagingElement.elements) do
		if pageButton.getOverlayState == nil then
			continue
		end
		function pageButton.getOverlayState()
			return self.mapPageSelector.state == i and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
		end
	end
	self.mapPageSelector:setState(1)
	self.statusSelector.texts = {}
	for _, status in pairs(InGameMenuMobileMapFrame.FIELD_STATUS) do
		table.insert(self.statusSelector.texts, g_i18n:getText(status))
	end
	self.statusSelector:setState(1)
	for i, button in pairs(self.pointsFilterButtonBox.elements) do
		function button.getOverlayState()
			return self.hotspotFiltersActive[i] and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
		end
	end
	function self.pointsFilterButtonGlyph.glyphElement.overlay.getIsVisible()
		return self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and FocusManager:getFocusedElement() ~= self.pointsList
	end
	FocusManager:linkElements(self.pointsList, FocusManager.BOTTOM, nil)
	FocusManager:linkElements(self.pointsList, FocusManager.RIGHT, self.pointsFilterButtonBox)
	self.aiWorkersList.onClickCallback = self.onListSelectionChanged
end
function InGameMenuMobileMapFrame:reset()
	InGameMenuMobileMapFrame:superClass().reset(self)
	self.isInputContextActive = false
end
function InGameMenuMobileMapFrame:onFrameOpen()
	InGameMenuMobileMapFrame:superClass().onFrameOpen(self)
	self:loadFilters()
	self:setColorBlindMode(Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false))
	self:updateElementSizes()
	local inGameMap = self.inGameMap
	local inGameMapBase = self.inGameMapBase
	self:toggleMapInput(true)
	local mapWidth = 1 - self.filterBoxContainer.absSize[1] - self.leftInset + 27 * g_aspectScaleX / g_referenceScreenWidth
	inGameMapBase.fullScreenLayout:setMapWidth(mapWidth)
	inGameMapBase.clipHotspots = true
	inGameMapBase:restoreDefaultFilter()
	inGameMap:onOpen()
	inGameMap:registerActionEvents()
	self:generateOverviewOverlay()
	self.statusList:reloadData()
	self:updateVehicles()
	self.vehiclesList:reloadData()
	self:updatePoints()
	self.pointsList:reloadData()
	self:updateFields()
	self.fieldsList:reloadData()
	self:setJobMenuVisible(false)
	self:generateJobTypes()
	self.aiWorkersList:reloadData()
	self.inGameMap.ingameMap:updateHotspotSorting()
	local player = self.inGameMap:getPlayerHotspot(self.inGameMap.ingameMap.hotspotsSorted[true])
	local playerVehicle = player:getVehicle()
	if playerVehicle ~= nil then
		self:selectHotspotInList(playerVehicle:getMapHotspot(), self.vehiclesList)
		if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.VEHICLES or self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.AI then
			self:setMapSelectionItem(playerVehicle:getMapHotspot())
		end
	end
	g_messageCenter:subscribe(MessageType.AI_JOB_STARTED, self.onAIJobStarted, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_STOPPED, self.onAIJobStopped, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_REMOVED, self.onAIJobRemoved, self)
	g_messageCenter:subscribe(MessageType.AI_TASK_SKIPPED, self.onAITaskSkipped, self)
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.onInsetsChanged, self)
	local slider = self.currentList.sliderElement
	if slider ~= nil then
		slider.parent:setVisible(self.currentList.visible)
	end
	self:onMapPageSelected()
end
function InGameMenuMobileMapFrame:onFrameClose()
	g_messageCenter:unsubscribeAll(self)
	InGameMenuMobileMapFrame:superClass().onFrameClose(self)
	self.inGameMap:onClose()
	self:toggleMapInput(false)
	self.inGameMapBase:restoreDefaultFilter()
	self.inGameMapBase:applyCustomHotspotSortingOrder(InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO[InGameMenuMobileMapFrame.PAGE_ID.STATUS])
	self.inGameMapBase.clipHotspots = false
	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	self.isOpening = true
end
function InGameMenuMobileMapFrame:saveFilters()
	local fruitValue = ""
	for index, state in pairs(self.fruitTypeFilter) do
		if self.fruitTypeFilter[index] == false then
			local fruitId = self.fruitTypeFilterMapping[index]
			local name = g_fruitTypeManager:getFruitTypeNameByIndex(fruitId)
			if fruitValue ~= "" then
				fruitValue = fruitValue .. ";" .. name
			else
				fruitValue = name
			end
		end
	end
	local growthValue = 0
	for i, state in ipairs(self.growthStateFilter) do
		if state then
			growthValue = Utils.setBit(growthValue, i)
		end
	end
	local soilValue = 0
	for i, state in ipairs(self.soilStateFilter) do
		if state then
			soilValue = Utils.setBit(soilValue, i)
		end
	end
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER, fruitValue, false)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER, growthValue, false)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER, soilValue, true)
	self.statusMessages = {}
	self:updateStatusMessages()
end
function InGameMenuMobileMapFrame:loadFilters()
	local fruitValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER)
	local fruitNames = fruitValue:split(";")
	local inverseFruitTypeFilterMapping = {}
	for index, key in pairs(self.fruitTypeFilterMapping) do
		inverseFruitTypeFilterMapping[key] = index
	end
	for _, fruitName in ipairs(fruitNames) do
		local fruitDesc = g_fruitTypeManager:getFruitTypeByName(fruitName)
		if fruitDesc == nil or inverseFruitTypeFilterMapping[fruitDesc.index] == nil then
			continue
		end
		self.fruitTypeFilter[inverseFruitTypeFilterMapping[fruitDesc.index]] = false
	end
	local growthValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER)
	for i, _ in pairs(self.displayGrowthStates) do
		self.growthStateFilter[i] = Utils.isBitSet(growthValue, i)
	end
	local soilValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER)
	for i, _ in pairs(self.displaySoilStates) do
		self.soilStateFilter[i] = Utils.isBitSet(soilValue, i)
	end
end
function InGameMenuMobileMapFrame:onLoadMapFinished()
	local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
	if mapOverlayGenerator ~= nil then
		self.displayCropTypes = mapOverlayGenerator:getDisplayCropTypes()
		self.displayGrowthStates = mapOverlayGenerator:getDisplayGrowthStates()
		self.displaySoilStates = mapOverlayGenerator:getDisplaySoilStates()
	end
	table.insert(self.fieldStatus, self.displayCropTypes)
	table.insert(self.fieldStatus, self.displayGrowthStates)
	table.insert(self.fieldStatus, self.displaySoilStates)
	for i, cropType in pairs(self.displayCropTypes) do
		self.fruitTypeFilter[i] = true
		self.fruitTypeFilterMapping[i] = cropType.fruitTypeIndex
	end
	self.inGameMapBase:applyCustomHotspotSortingOrder(InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO[InGameMenuMobileMapFrame.PAGE_ID.STATUS])
	self:setMapSelectionItem(nil)
end
function InGameMenuMobileMapFrame:toggleMapInput(isActive)
	if self.isInputContextActive ~= isActive then
		self.isInputContextActive = isActive
		self:toggleCustomInputContext(isActive, InGameMenuMobileMapFrame.INPUT_CONTEXT_NAME)
		if isActive then
			self:registerInput()
			return
		end
		self:unregisterInput(true)
	end
end
function InGameMenuMobileMapFrame:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self.isPickingRotation and not self.hasPickedRotationTouch then
		local localX, localY = self.inGameMap:getLocalPosition(posX, posY)
		local worldX, worldZ = self.inGameMap:localToWorldPos(localX, localY)
		local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
		angle = angle + 3.141592653589793
		if 0 < self.pickingRotationSnapAngle then
			local numSteps = MathUtil.round(angle / self.pickingRotationSnapAngle, 0)
			angle = numSteps * self.pickingRotationSnapAngle
		end
		self.aiTargetMapHotspot:setWorldRotation(angle)
	end
	if isUp then
		self.lastTouchPosX = posX
		self.lastTouchPosY = posY
	end
	return InGameMenuMobileMapFrame:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed)
end
function InGameMenuMobileMapFrame:update(dt)
	InGameMenuMobileMapFrame:superClass().update(self, dt)
	self.isOpening = false
	local currentInputHelpMode = g_inputBinding:getInputHelpMode()
	if currentInputHelpMode ~= self.lastInputHelpMode then
		self.lastInputHelpMode = currentInputHelpMode
		self:refreshContextInput()
	end
	if currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		local localX, localY = self.inGameMap:getLocalPointerTarget()
		if self.isPickingLocation then
			self:setTargetPointHotspotPosition(localX, localY)
		elseif self.isPickingRotation then
			local worldX, worldZ = self.inGameMap:localToWorldPos(localX, localY)
			local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
			angle = angle + 3.141592653589793
			if 0 < self.pickingRotationSnapAngle then
				local numSteps = MathUtil.round(angle / self.pickingRotationSnapAngle, 0)
				angle = numSteps * self.pickingRotationSnapAngle
			end
			self.aiTargetMapHotspot:setWorldRotation(angle)
		end
	end
	local hasChanged = false
	for i = 1, #self.statusMessages do
		local removeTime = self.statusMessages[1].removeTime
		if removeTime < g_time then
			table.remove(self.statusMessages, 1)
			hasChanged = true
		end
	end
	if hasChanged then
		self:updateStatusMessages()
	end
	self:updateMarqueeAnimation(dt)
end
function InGameMenuMobileMapFrame:setTargetPointHotspotPosition(localX, localY)
	local worldX, worldZ = self.inGameMap:localToWorldPos(localX, localY)
	self.aiTargetMapHotspot:setWorldPosition(worldX, worldZ)
end
function InGameMenuMobileMapFrame:showContextInput(canEnter, canReset, canSetMarker, removeMarker, canBuy)
	local currentPageIsNotAI = self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.AI
	self.buttonEnterVehicle:setVisible(canEnter and currentPageIsNotAI)
	self.buttonResetVehicle:setVisible(canReset and currentPageIsNotAI)
	self.buttonSetMarker:setVisible(canSetMarker and currentPageIsNotAI)
	self.buttonBuyField:setVisible(canBuy and currentPageIsNotAI)
	self.buttonCancelJob:setVisible(self:getCanCancelJob())
	self.buttonGoToJob:setVisible(self:getCanGoTo())
	self.buttonCreateJob:setVisible(self:getCanCreateJob())
	self.buttonStartJob:setVisible(self:getCanStartJob())
	self.buttonSkipTask:setVisible(self:getCanSkipJobTask())
	self.buttonConfirmAITarget:setVisible(self:canConfirmAITarget())
	self:showContextMarker(canSetMarker, removeMarker)
	local buttonNeedsCancelText = self:getIsPicking()
	local buttonCloseText = false and InGameMenuMobileMapFrame.BUTTON_TEXTS.BUTTON_CANCEL or InGameMenuMobileMapFrame.BUTTON_TEXTS.BUTTON_CLOSE_MAP
	self.buttonCloseMap:setText(g_i18n:getText(buttonCloseText))
	self.buttonSelectInGame:setVisible(self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and not self:getIsPicking() and self.mode ~= InGameMenuMobileMapFrame.MODE_CREATE_JOB)
	self.buttonBox:invalidateLayout()
end
function InGameMenuMobileMapFrame:showContextInputAI(canGoTo, canCreateJob, canCancel, canSkipTask)
	local currentPageIsAI = self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.AI
	self.canGoTo = canGoTo and currentPageIsAI
	self.canCreateJob = canCreateJob and currentPageIsAI
	self.canCancel = canCancel and currentPageIsAI
	self.canSkipTask = canSkipTask and currentPageIsAI
end
function InGameMenuMobileMapFrame:showContextMarker(canSetMarker, removeMarker)
	if canSetMarker then
		local markerText = nil
		if removeMarker then
			markerText = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.REMOVE_MARKER)
		else
			markerText = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.SET_MARKER)
		end
		self.buttonSetMarker:setText(markerText)
	end
end
function InGameMenuMobileMapFrame:getCanCancelJob()
	if self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE then
		self:getIsPicking()
		g_currentMission:getHasPlayerPermission("hireAssistant")
		g_guidedTourManager:getIsTourRunning()
	end
	return false
end
function InGameMenuMobileMapFrame:getCanCreateJob()
	if self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE then
		self:getIsPicking()
		g_currentMission:getHasPlayerPermission("hireAssistant")
		g_guidedTourManager:getIsTourRunning()
	end
	return false
end
function InGameMenuMobileMapFrame:getCanGoTo()
	if self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE then
		self:getIsPicking()
		g_currentMission:getHasPlayerPermission("hireAssistant")
		g_guidedTourManager:getIsTourRunning()
	end
	return false
end
function InGameMenuMobileMapFrame:getCanStartJob()
	if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		self:getIsPicking()
		g_currentMission:getHasPlayerPermission("hireAssistant")
		g_guidedTourManager:getIsTourRunning()
	end
	return false
end
function InGameMenuMobileMapFrame:getCanSkipJobTask()
	if self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE then
		self:getIsPicking()
		g_currentMission:getHasPlayerPermission("hireAssistant")
		g_guidedTourManager:getIsTourRunning()
	end
	return false
end
function InGameMenuMobileMapFrame:getCanCloseMap()
	local _v2 = false
	if self.mode ~= InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		_v2 = not self:getIsPicking()
	end
	return _v2
end
function InGameMenuMobileMapFrame:canConfirmAITarget()
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH then
		local _v5 = not self.aiTaskDialog.visible
		if _v5 then
			local _v12 = g_guidedTourManager:getIsTourRunning()
			if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB or _v5 then
				_v12 = g_guidedTourManager:getIsTourRunning()
			end
		end
	end
	return false
end
function InGameMenuMobileMapFrame:refreshContextInput()
	local hotspot = self.currentHotspot
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
	local canGoTo = false
	local canCreateJob = false
	local canCancel = false
	local canSkipTask = false
	if vehicle ~= nil and (g_currentMission.accessHandler:canPlayerAccess(vehicle) and vehicle.spec_aiJobVehicle ~= nil) then
		canCancel = vehicle:getIsAIActive()
		if not canCancel then
			canGoTo = self.jobTypeInstances[AIJobType.GOTO]:getIsAvailableForVehicle(vehicle)
			canCreateJob = false
			for typeIndex, instance in pairs(self.jobTypeInstances) do
				if instance:getIsAvailableForVehicle(vehicle) then
					if self:getIsPicking() then
						continue
					end
					canCreateJob = true
					local isVisible = not canCreateJob and g_currentMission.aiSystem:getAILimitedReached()
					self.limitReachedWarning:setVisible(isVisible)
					self.limitReachedWarningBg:setVisible(isVisible)
					self:showContextInputAI(canGoTo, canCreateJob, canCancel, canSkipTask)
					self:showContextInput()
					return
				end
			end
		else
			local job = vehicle:getJob()
			if job ~= nil and job:getCanSkipTask() then
				canSkipTask = true
			end
		end
	end
end
function InGameMenuMobileMapFrame:updateElementSizes()
	local leftInset = getSafeFrameInsets()
	self.leftInset = leftInset
	local sliderPosX = self.filterBoxContainer.absSize[1] - self.statusListSlider.absSize[1] * 1.5
	local buttonBoxHeight = self.buttonBox.absSize[2]
	local filterBoxWidth = self.pagingElement.size[1]
	self.mapPageSelector:setPosition(leftInset, nil)
	self.pagingElement:setPosition(leftInset, nil)
	self.roundedTopContainer:setSize(filterBoxWidth + leftInset, nil)
	self.roundedTopCenter:setSize(filterBoxWidth - 42 * g_pixelSizeX + leftInset, nil)
	self.buttonCloseMapContainer:setSize(filterBoxWidth + leftInset, nil)
	self.filterBoxContainer:setAnchors(0, 0, 0, 1 - self.pagingElement.absSize[2])
	self.filterBoxContainer:setPosition(leftInset, nil)
	local uv1 = self.filterBoxContainer.absSize[1] * g_screenWidth
	local uv2 = self.filterBoxContainer.absSize[2] * g_screenHeight
	self.filterBoxContainer:setImageUVs(nil, unpack(GuiUtils.getUVs({ leftInset, 0, uv1, uv2 }, { 2048, 2048 })))
	self.filterBoxContainerBg:setAnchors(0, 0, 0, 1 - self.pagingElement.absSize[2])
	self.filterBoxContainerBg:updateAbsolutePosition()
	self.filterBoxContainerBg:setImageUVs(nil, unpack(GuiUtils.getUVs({ 0, 0, uv1, uv2 }, { 2048, 2048 })))
	self.inGameMap:setCursorCenter((self.filterBoxContainer.absSize[1] + self.leftInset) * 0.5, 0)
	self.buttonBox:setSize(1 - filterBoxWidth - leftInset - 50 * g_pixelSizeX)
	self.statusList:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 + self.statusSelector.position[2] - self.statusSelector.absSize[2] - 30 * g_pixelSizeY)
	self.statusList:updateAbsolutePosition()
	self.statusListSlider:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 + self.statusSelector.position[2] - self.statusSelector.absSize[2] - 30 * g_pixelSizeY)
	self.statusListSliderBar:setAnchors(0.5, 0.5, 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.statusListSlider:setPosition(sliderPosX)
	self.statusListTopClipper:setPosition(0, self.statusList.absPosition[2] + self.statusList.absSize[2])
	self.statusListBottomClipper:setPosition(0, self.statusList.absPosition[2] - self.statusListBottomClipper.absSize[2])
	self.vehiclesList:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
	self.vehiclesList:updateAbsolutePosition()
	self.vehiclesListSlider:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
	self.vehiclesListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.vehiclesListSlider:setPosition(sliderPosX)
	self.vehiclesListTopClipper:setPosition(0, self.vehiclesList.absPosition[2] + self.vehiclesList.absSize[2])
	self.vehiclesListBottomClipper:setPosition(0, self.vehiclesList.absPosition[2] - self.vehiclesListBottomClipper.absSize[2])
	self.pointsList:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, self.pointsFilterButtonBox.absPosition[2] - self.pointsFilterButtonBox.position[2] - 20 * g_pixelSizeY)
	self.pointsList:updateAbsolutePosition()
	self.pointsListSlider:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, self.pointsFilterButtonBox.absPosition[2] - self.pointsFilterButtonBox.position[2] - 20 * g_pixelSizeY)
	self.pointsListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.pointsListSlider:setPosition(sliderPosX)
	self.pointsListTopClipper:setPosition(0, self.pointsList.absPosition[2] + self.pointsList.absSize[2])
	self.pointsListBottomClipper:setPosition(0, self.pointsList.absPosition[2] - self.pointsListBottomClipper.absSize[2])
	self.fieldsList:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
	self.fieldsList:updateAbsolutePosition()
	self.fieldsListSlider:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
	self.fieldsListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.fieldsListSlider:setPosition(sliderPosX)
	self.fieldsListTopClipper:setPosition(0, self.fieldsList.absPosition[2] + self.fieldsList.absSize[2])
	self.fieldsListBottomClipper:setPosition(0, self.fieldsList.absPosition[2] - self.fieldsListBottomClipper.absSize[2])
	self.aiWorkersList:setAnchors(0, 0, buttonBoxHeight + 15 * g_pixelSizeY, self.aiWorkersListTitle.absPosition[2] + 20 * g_pixelSizeY)
	self.aiWorkersList:updateAbsolutePosition()
	self.aiWorkersListSlider:setAnchors(0, 0, buttonBoxHeight + 15 * g_pixelSizeY, self.aiWorkersListTitle.absPosition[2] + 20 * g_pixelSizeY)
	self.aiWorkersListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.aiWorkersListSlider:setPosition(sliderPosX)
	self.aiWorkersListTopClipper:setPosition(0, self.aiWorkersList.absPosition[2] + self.aiWorkersList.absSize[2])
	self.aiWorkersListBottomClipper:setPosition(0, self.aiWorkersList.absPosition[2] - self.aiWorkersListBottomClipper.absSize[2])
end
function InGameMenuMobileMapFrame:setInGameMap(inGameMap)
	self.inGameMapBase = inGameMap
	self.inGameMap:setIngameMap(inGameMap)
	if inGameMap ~= nil then
		self.customFilterFarmlands = inGameMap:createCustomFilter(false)
	end
end
function InGameMenuMobileMapFrame:setTerrainSize(terrainSize)
	self.inGameMap:setTerrainSize(terrainSize)
end
function InGameMenuMobileMapFrame:setClient(client)
	self.client = client
end
function InGameMenuMobileMapFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
end
function InGameMenuMobileMapFrame:assignGroundStatusColors(colorElement, statusColors, listElement)
	local partWidth = colorElement.absSize[1] / #statusColors
	colorElement:setSize(partWidth, nil)
	local x, y, width, height = unpack(InGameMenuMobileMapFrame.STATUS_BG_COLOR_UVS)
	width = width / #statusColors
	local imageUVs = GuiUtils.getUVs({ x, y, width, height }, { 2048, 2048 })
	colorElement:setImageUVs(nil, unpack(imageUVs))
	GuiOverlay.setSelectedColor(colorElement.overlay, unpack(statusColors[1]))
	if 1 < #statusColors then
		local clones = {}
		for i = 2, #statusColors do
			local newPart = colorElement:clone()
			table.insert(clones, newPart)
			newPart:setSize(partWidth, nil)
			imageUVs = GuiUtils.getUVs({ x + width * (i - 1), y, width, height }, { 2048, 2048 })
			newPart:setImageUVs(nil, unpack(imageUVs))
			newPart:setPosition((i - 1) * partWidth, 0)
			GuiOverlay.setSelectedColor(newPart.overlay, unpack(statusColors[i]))
			function newPart.getOverlayState()
				return listElement.isStatusEnabled and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
			end
		end
		for _, clone in ipairs(clones) do
			colorElement:addElement(clone)
		end
	end
end
function InGameMenuMobileMapFrame:resetUIDeadzones()
	self.inGameMap:clearCursorDeadzones()
	if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB and not self:getIsPicking() then
		self.inGameMap:addCursorDeadzone(0, 0, 1, 1)
		return
	end
	self.inGameMap:addCursorDeadzone(0, 0, self.filterBoxContainer.absPosition[1] + self.filterBoxContainer.absSize[1], self.filterBoxContainer.absPosition[2] + self.filterBoxContainer.absSize[2])
end
function InGameMenuMobileMapFrame:onOverviewOverlayFinished(overlayId)
	self.foliageStateOverlay = overlayId
	self.foliageStateOverlayIsReady = true
	self.dynamicMapImageLoadingBg:setVisible(false)
end
function InGameMenuMobileMapFrame:generateOverviewOverlay()
	if self.foliageStateOverlay == nil then
		self.foliageStateOverlayIsReady = false
	end
	self.dynamicMapImageLoadingBg:setVisible(true)
	self.dynamicMapImageLoadingBg:setSize(self.dynamicMapImageLoading.absSize[1] + 80 * g_pixelSizeX)
	local mappedFruitTypeFilters = {}
	for buttonIndex, fruitIndex in pairs(self.fruitTypeFilterMapping) do
		mappedFruitTypeFilters[fruitIndex] = self.fruitTypeFilter[buttonIndex]
	end
	local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
	if mapOverlayGenerator ~= nil then
		local currentMapFilter = self.statusSelector:getState()
		if currentMapFilter == InGameMenuMobileMapFrame.MAP_FRUIT_TYPE then
			mapOverlayGenerator:generateFruitTypeOverlay(self.overviewOverlayFinishedCallback, mappedFruitTypeFilters)
			return
		end
		if currentMapFilter == InGameMenuMobileMapFrame.MAP_GROWTH then
			mapOverlayGenerator:generateGrowthStateOverlay(self.overviewOverlayFinishedCallback, self.growthStateFilter, mappedFruitTypeFilters)
			return
		end
		if currentMapFilter == InGameMenuMobileMapFrame.MAP_SOIL then
			mapOverlayGenerator:generateSoilStateOverlay(self.overviewOverlayFinishedCallback, self.soilStateFilter)
		end
	end
end
function InGameMenuMobileMapFrame:setMode(mode)
	self.mode = mode
	if mode ~= InGameMenuMobileMapFrame.MODE_NONE then
		self:generateOverviewOverlay()
	end
	self.inGameMapBase:restoreDefaultFilter()
	self:resetUIDeadzones()
end
function InGameMenuMobileMapFrame:setMapSelectionItem(hotspot)
	self.inGameMapBase:setSelectedHotspot(hotspot)
	self.selectedField = nil
	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	if self.currentHotspot ~= nil then
		self.currentHotspot:setBlinking(false)
	end
	local canEnter = false
	local canReset = false
	local canSetMarker = false
	local removeMarker = false
	local canBuy = false
	local name = nil
	local imageFilename = nil
	local vehicle = nil
	local isHorse = nil
	local mapPageSelectorState = self.mapPageSelector.state
	if hotspot ~= nil then
		vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
		if vehicle ~= nil then
			if mapPageSelectorState ~= InGameMenuMobileMapFrame.PAGE_ID.VEHICLES and mapPageSelectorState ~= InGameMenuMobileMapFrame.PAGE_ID.AI then
				self.blockListSelectionEvents = true
				self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.VEHICLES, true)
				self.blockListSelectionEvents = false
			end
			self.currentHotspot = hotspot
			self.currentList = mapPageSelectorState == InGameMenuMobileMapFrame.PAGE_ID.AI and self.aiWorkersList or self.vehiclesList
			name = vehicle:getName()
			imageFilename = vehicle:getImageFilename()
			if g_currentMission.tourIconsBase == nil or g_currentMission.tourIconsBase.visible == false then
				if vehicle.getIsEnterableFromMenu ~= nil then
					vehicle:getIsEnterableFromMenu()
				end
				canEnter = false
				if not self.isResetPending and (vehicle:getCanBeReset() and hotspot:getCategory() ~= MapHotspot.CATEGORY_AI) then
					canReset = true
				end
			end
			isHorse = vehicle.spec_rideable ~= nil
			self.vehicleDetailsImage:setImageFilename(imageFilename)
			local brand = g_brandManager:getBrandByIndex(vehicle:getBrand())
			self.vehicleDetailsBrand:setImageFilename(brand.image)
			self.vehicleDetailsName:setText(name)
			self.vehicleDetailsBrand:setVisible(not isHorse)
			self.vehicleDetailsDailyRiding:setVisible(isHorse)
			if isHorse then
				local horse = vehicle:getCluster()
				local dailyRiding = math.floor(horse:getRidingFactor() * 100)
				self.vehicleDetailsDailyRiding:setText(string.format("%s: %s%%", g_i18n:getText("ui_horseDailyRiding"), dailyRiding))
			end
			self.aiDetailsImage:setImageFilename(imageFilename)
			self.aiDetailsBrand:setVisible(true)
			self.aiDetailsBrand:setImageFilename(brand.image)
			self.aiDetailsName:setText(name)
			for i, attachableContainer in pairs(self.vehicleDetailsAttachables) do
				local attachable = vehicle.childVehicles[i]
				if attachable ~= nil then
					local attachableText = attachableContainer:getDescendantByName("text")
					attachableText:setText(attachable:getName())
					local attachableIcon = attachableContainer:getDescendantByName("icon")
					attachableIcon:setImageUVs(nil, unpack(attachable.mapHotspot.icon.uvs))
					attachableContainer:setVisible(true)
				else
					attachableContainer:setVisible(false)
				end
			end
			for i = #vehicle.childVehicles, 3 do
				self.vehicleDetailsAttachables[i]:setVisible(false)
			end
		elseif hotspot:isa(PlaceableHotspot) then
			name = hotspot:getName()
			if name ~= nil then
				if mapPageSelectorState ~= InGameMenuMobileMapFrame.PAGE_ID.POINTS and mapPageSelectorState ~= InGameMenuMobileMapFrame.PAGE_ID.AI then
					self.blockListSelectionEvents = true
					self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.POINTS, true)
					self.blockListSelectionEvents = false
				end
				self.currentHotspot = hotspot
				self.currentList = mapPageSelectorState == InGameMenuMobileMapFrame.PAGE_ID.AI and self.aiWorkersList or self.pointsList
				local placeable = hotspot:getPlaceable()
				if placeable ~= nil then
					imageFilename = placeable:getImageFilename()
					self.pointDetailsImage:setImageFilename(imageFilename)
					self.pointDetailsName:setText(name)
					self.aiDetailsImage:setImageFilename(imageFilename)
					self.aiDetailsBrand:setVisible(false)
					self.aiDetailsName:setText(name)
					if placeable.storeItem ~= nil then
						local slotSystem = g_currentMission.slotSystem
						local slotLimit = slotSystem.slotLimit
						slotSystem.slotLimit = math.huge
						local displayItem = g_shopController:makeDisplayItem(placeable.storeItem)
						self:setDetailAttributes(placeable.storeItem, displayItem)
						slotSystem.slotLimit = slotLimit
					end
				end
				canSetMarker = true
				removeMarker = g_currentMission.currentMapTargetHotspot == hotspot
			end
		elseif hotspot:isa(FieldHotspot) then
			if mapPageSelectorState ~= InGameMenuMobileMapFrame.PAGE_ID.FIELDS then
				self.blockListSelectionEvents = true
				self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.FIELDS, true)
				self.blockListSelectionEvents = false
				if self.currentHotspot ~= nil then
					self.currentHotspot:setBlinking(false)
				end
			end
			self.currentHotspot = hotspot
			self.currentList = self.fieldsList
			local field = hotspot:getField()
			canBuy = not field:getHasOwner()
			self.selectedField = field:getId()
		end
	else
		self.currentHotspot = nil
	end
	if self.currentHotspot ~= nil then
		self.currentHotspot:setBlinking(true)
	end
	if isHorse then
		self.buttonEnterVehicle:setText(string.format(g_i18n:getText("action_rideAnimal"), name))
		self.buttonEnterVehicle.touchIcon.uvs = GuiUtils.getUVs(InGameMenuMobileMapFrame.UV.BUTTON_RIDE_HORSE)
	else
		self.buttonEnterVehicle:setText(g_i18n:getText("button_enterVehicle"))
		self.buttonEnterVehicle.touchIcon.uvs = GuiUtils.getUVs(InGameMenuMobileMapFrame.UV.BUTTON_ENTER_VEHICLE)
	end
	self.buttonEnterVehicle:setTextSize(self.buttonsResizeTextSize)
	self:refreshContextInput()
	self:showContextInput(canEnter, canReset, canSetMarker, removeMarker, canBuy)
	self.canEnter = canEnter
	self.canReset = canReset
	self.canSetMarker = canSetMarker
	self.removeMarker = removeMarker
	self.canBuy = canBuy
end
function InGameMenuMobileMapFrame:showDetailsBox(showBox)
	local detailsBox = self.currentList.detailsBox
	showBox = showBox or self.currentList ~= self.aiWorkersList or self.currentHotspot ~= nil
	if detailsBox ~= nil then
		detailsBox:setVisible(showBox)
	end
	local showList = not showBox or detailsBox == nil or self.currentList == self.aiWorkersList
	self.currentList:setVisible(showList)
	self.currentList:updateScrollClippers()
	if self.currentList.sliderElement ~= nil and (self.currentList.sliderElement.needsSlider and 0 < self.currentList.totalItemCount) then
		self.currentList.sliderElement.parent:setVisible(showList)
	end
	if self.currentList == self.pointsList then
		self.pointsFilterButtonBox:setVisible(showList)
	end
end
function InGameMenuMobileMapFrame:showActionMessage(text, locaKey)
	local needBg = false
	if text ~= nil then
		self.actionMessage:setVisible(true)
		self.actionMessage:setText(text)
		needBg = true
	elseif locaKey ~= nil then
		self.actionMessage:setVisible(true)
		self.actionMessage:setLocaKey(locaKey)
		needBg = true
	else
		self.actionMessageBg:setVisible(false)
	end
	if needBg then
		self.actionMessageBg:setVisible(true)
		self.actionMessageBg:setSize(self.actionMessage.absSize[1] + 80 * g_pixelSizeX)
	end
end
function InGameMenuMobileMapFrame:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive
		self.statusList:reloadData()
		self:generateOverviewOverlay()
	end
end
function InGameMenuMobileMapFrame:setActiveJobTypeSelection(jobTypeIndex)
	if self.currentJob == nil or jobTypeIndex ~= self.currentJob.jobTypeIndex then
		for i = #self.aiTaskDialogLayout.elements, 2, -1 do
			self.aiTaskDialogLayout.elements[i]:delete()
		end
		self.currentJob = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
		local farmId = 1
		if g_localPlayer ~= nil then
			farmId = g_localPlayer.farmId
		end
		self.currentJob:applyCurrentState(self.currentJobVehicle, g_currentMission, farmId, false)
		self.currentJobElements = {}
		for _, group in ipairs(self.currentJob:getGroupedParameters()) do
			for _, item in ipairs(group:getParameters()) do
				local element = nil
				local parameterType = item:getType()
				if parameterType == AIParameterType.TEXT then
					break
				end
				if parameterType == AIParameterType.POSITION then
					element = self.aiTaskDialogPositionTemplate:clone(self.aiTaskDialogLayout)
					element:getDescendantByName("title"):setText(group:getTitle())
					element:getDescendantByName("button").aiParameter = item
				elseif parameterType == AIParameterType.POSITION_ANGLE then
					element = self.aiTaskDialogPositionRotationTemplate:clone(self.aiTaskDialogLayout)
					element:getDescendantByName("title"):setText(group:getTitle())
					element:getDescendantByName("button").aiParameter = item
				elseif parameterType == AIParameterType.SELECTOR or parameterType == AIParameterType.UNLOADING_STATION or parameterType == AIParameterType.LOADING_STATION or parameterType == AIParameterType.FILLTYPE then
					element = self.aiTaskDialogMultiOptionTemplate:clone(self.aiTaskDialogLayout)
					element:setDataSource(item)
					element:setLabel(group:getTitle())
				end
				element.aiParameter = item
				element:setDisabled(not item:getCanBeChanged())
				table.insert(self.currentJobElements, element)
			end
		end
		self:updateParameterValueTexts()
		self:validateParameters()
		self.aiTaskDialogLayout:invalidateLayout()
	end
	self:refreshContextInput()
end
function InGameMenuMobileMapFrame:updateVehicles()
	self.vehicles = { {}, {} }
	if g_localPlayer ~= nil then
		for _, vehicle in ipairs(g_currentMission.vehicleSystem.vehicles) do
			if g_currentMission.accessHandler:canPlayerAccess(vehicle) then
				if vehicle:getShowInVehiclesOverview() then
					local item = {}
					item.vehicle = vehicle
					local name = vehicle:getName()
					local brand = g_brandManager:getBrandByIndex(vehicle:getBrand())
					if brand ~= nil then
						name = brand.title .. " " .. name
					end
					item.name = name
					local section = SpecializationUtil.hasSpecialization(Drivable, vehicle.specializations) and 1 or 2
					if self.vehicles[section] == nil then
						self.vehicles[section] = {}
					end
					table.insert(self.vehicles[section], item)
				elseif SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations) then
					local item = {}
					item.vehicle = vehicle
					item.name = vehicle:getName()
					if self.vehicles[3] == nil then
						self.vehicles[3] = {}
					end
					table.insert(self.vehicles[3], item)
				end
			end
		end
	end
	local sortFunction = function(vehicle1, vehicle2)
		if vehicle1 == nil then
			return true
		elseif vehicle2 == nil then
			return false
		else
			return vehicle1.name < vehicle2.name
		end
	end
	for i = 1, #self.vehicles do
		table.sort(self.vehicles[i], sortFunction)
	end
end
function InGameMenuMobileMapFrame:updatePoints()
	self.hotspotsSorted = {}
	local sectionFunction = function(hotspot)
		if hotspot == nil or hotspot.placeable == nil then
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER
		end
		if SpecializationUtil.hasSpecialization(PlaceableProductionPoint, hotspot.placeable.specializations) then
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS
		elseif SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, hotspot.placeable.specializations) then
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS
		else
			if SpecializationUtil.hasSpecialization(PlaceableSellingStation, hotspot.placeable.specializations) or SpecializationUtil.hasSpecialization(PlaceableBuyingStation, hotspot.placeable.specializations) then
				return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING
			end
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER
		end
	end
	local hotspots = self.inGameMap.ingameMap.hotspots
	local section = nil
	for _, hotspot in pairs(hotspots) do
		if hotspot:isa(PlaceableHotspot) then
			section = sectionFunction(hotspot)
			if self.hotspotsSorted[section] == nil then
				self.hotspotsSorted[section] = {}
			end
			table.insert(self.hotspotsSorted[section], hotspot)
		end
	end
	local sortFunction = function(hotspot1, hotspot2)
		if hotspot1 == nil then
			return true
		elseif hotspot2 == nil then
			return false
		else
			return hotspot1:getName() < hotspot2:getName()
		end
	end
	for i = 1, #self.hotspotsSorted do
		table.sort(self.hotspotsSorted[i], sortFunction)
	end
	self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:updatePointsFilterMapping()
	self.hotspotFiltersMapping = {}
	local numActive = 1
	for i, isActive in pairs(self.hotspotFiltersActive) do
		if isActive then
			self.hotspotFiltersMapping[numActive] = i
			numActive = numActive + 1
		end
	end
	if numActive == 1 then
		self.pointsListSlider:setVisible(false)
		self:setMapSelectionItem(nil)
	else
		self.pointsListSlider:setVisible(self.pointsList.visible)
	end
	self.pointsList:reloadData()
end
function InGameMenuMobileMapFrame:updateFields()
	self.fields = {}
	for _, field in pairs(g_fieldManager:getFields()) do
		local farmland = field.farmland
		local section = g_farmlandManager:getFarmlandOwner(farmland.id) == g_currentMission:getFarmId() and 1 or 2
		if self.fields[section] == nil then
			self.fields[section] = {}
		end
		table.insert(self.fields[section], field)
	end
	local sortFunction = function(field1, field2)
		return field1:getId() < field2:getId()
	end
	for i = 1, #self.fields do
		table.sort(self.fields[i], sortFunction)
	end
end
function InGameMenuMobileMapFrame:generateJobTypes()
	for _, jobType in pairs(AIJobType) do
		self.jobTypeInstances[jobType] = g_currentMission.aiJobTypeManager:createJob(jobType)
	end
end
function InGameMenuMobileMapFrame:startGoToJob(vehicle, destX, destZ, angle)
	local job = self.jobTypeInstances[AIJobType.GOTO]
	job.vehicleParameter:setVehicle(vehicle)
	job.positionAngleParameter:setPosition(destX, destZ)
	job.positionAngleParameter:setAngle(angle)
	job:setValues()
	local success, errorMessage = job:validate(g_localPlayer.farmId)
	if success then
		local callback = function(state)
			if state == AIJob.START_SUCCESS then
				self.jobTypeInstances[AIJobType.GOTO] = g_currentMission.aiJobTypeManager:createJob(AIJobType.GOTO)
			end
		end
		FocusManager:setFocus(self.aiWorkersList)
		self:tryStartJob(job, g_localPlayer.farmId, callback)
		return true
	else
		InfoDialog.show(tostring(errorMessage), nil, nil, DialogElement.TYPE_WARNING)
		return false
	end
end
function InGameMenuMobileMapFrame:getIsPicking()
	return self.isPickingRotation or self.isPickingLocation
end
function InGameMenuMobileMapFrame:executePickingCallback(...)
	self.inGameMap:setHotspotSelectionActive(true)
	self.isPickingLocation = false
	self.isPickingRotation = false
	self.inGameMap:unlockMapMovement()
	self:resetUIDeadzones()
	local cb = self.pickingCallback
	self.pickingCallback = nil
	if cb ~= nil then
		cb(...)
	end
end
function InGameMenuMobileMapFrame:startPickPosition(parameter, callback)
	self.inGameMap:setHotspotSelectionActive(false)
	self.inGameMap:setIsCursorAvailable(false)
	self.isPickingLocation = true
	self.hasPickedLocationTouch = false
	self:showActionMessage(nil, "ui_ai_pickTargetLocation")
	self:resetUIDeadzones()
	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	g_currentMission:addMapHotspot(self.aiTargetMapHotspot)
	function self.pickingCallback(success, x, z)
		self:showActionMessage()
		self.inGameMap:setIsCursorAvailable(true)
		self.hasPickedRotationTouch = false
		if success then
			parameter:setValue(x, z)
			self.aiTargetMapHotspot:setWorldPosition(x, z)
		end
		callback(success, x, z, parameter)
		self:validateParameters()
	end
end
function InGameMenuMobileMapFrame:startPickPositionAndRotation(parameter, callback)
	self.isPickingLocation = true
	self.hasPickedLocationTouch = false
	self.inGameMap:setHotspotSelectionActive(false)
	self.inGameMap:setIsCursorAvailable(false)
	self:showActionMessage(nil, "ui_ai_pickTargetLocation")
	self:resetUIDeadzones()
	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	g_currentMission:addMapHotspot(self.aiTargetMapHotspot)
	function self.pickingCallback(success, x, z)
		self:showActionMessage()
		self.inGameMap:setIsCursorAvailable(true)
		self.hasPickedRotationTouch = false
		if success then
			self.inGameMap:setHotspotSelectionActive(false)
			self.inGameMap:setIsCursorAvailable(false)
			self.aiTargetMapHotspot:setWorldPosition(x, z)
			self.isPickingRotation = true
			self.inGameMap:lockMapMovement()
			self.pickingRotationOrigin = { x, z }
			self.pickingRotationSnapAngle = parameter:getSnappingAngle()
			self:showActionMessage(nil, "ui_ai_pickTargetRotation")
			self:resetUIDeadzones()
			function self.pickingCallback(successRotation, angle)
				self:showActionMessage()
				self.inGameMap:setIsCursorAvailable(true)
				if successRotation then
					parameter:setPosition(x, z)
					parameter:setAngle(angle)
					local convertedAngle = parameter:getAngle()
					if self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_TOUCH then
						self.aiTargetMapHotspot:setWorldRotation(convertedAngle + 3.141592653589793)
					end
					callback(true, x, z, angle)
				else
					callback(false, x, z, nil)
				end
				self:validateParameters()
			end
		else
			callback(false, nil, nil, nil)
		end
		self:validateParameters()
	end
end
function InGameMenuMobileMapFrame:onClickHotspot(element, hotspot)
	if self.mode ~= InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		local previousHotspot = self.currentHotspot
		self:setMapSelectionItem(hotspot)
		self:showDetailsBox(true)
		if InGameMenuMobileMapFrame.MODE_OVERVIEW or self.mode == InGameMenuMobileMapFrame.MODE_NONE and previousHotspot ~= hotspot then
			self:selectHotspotInList(hotspot, self.currentList)
		end
		self:resizeButtonTexts()
	end
end
function InGameMenuMobileMapFrame:onClickMap(element, worldX, worldZ)
	if (self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW or self.mode == InGameMenuMobileMapFrame.MODE_NONE) and 0 < self.currentList.totalItemCount then
		self:showDetailsBox(false)
		FocusManager:setFocus(self.currentList)
		return
	end
	if self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE or self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		if self.isPickingLocation then
			if self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH then
				local localX, localY = self.inGameMap:getLocalPosition(self.lastTouchPosX, self.lastTouchPosY)
				self:setTargetPointHotspotPosition(localX, localY)
			elseif not self.hasPickedLocationTouch then
				self:executePickingCallback(true, worldX, worldZ)
			end
		elseif self.isPickingRotation then
			local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
			if self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH then
				self.aiTargetMapHotspot:setWorldRotation(angle + 3.141592653589793)
				self.hasPickedRotationTouch = true
			else
				self.inGameMap:panToHotspot(self.aiTargetMapHotspot)
				self:executePickingCallback(true, angle)
			end
		end
		self:refreshContextInput()
	end
end
function InGameMenuMobileMapFrame:selectHotspotInList(hotspot, hotspotList)
	local sectionIndex, index = self:findListItemForHotspot(hotspot, hotspotList)
	local listSelectionBlocked = self.blockListSelectionEvents
	self.blockListSelectionEvents = true
	hotspotList:setSelectedItem(sectionIndex, index)
	self.blockListSelectionEvents = listSelectionBlocked
end
function InGameMenuMobileMapFrame:findListItemForHotspot(hotspot, hotspotList)
	local list = self.vehicles
	if hotspotList == self.pointsList then
		list = self.hotspotsSorted
	elseif hotspotList == self.fieldsList then
		list = self.fields
	end
	for sectionIndex, section in pairs(list) do
		for index = 1, #section do
			if hotspotList == self.vehiclesList then
				local vehicle = self.vehicles[sectionIndex][index].vehicle
				if hotspot == nil then
					continue
				end
				if vehicle == hotspot.vehicle then
					return sectionIndex, index
				end
			elseif hotspotList == self.pointsList then
				local listHotspot = self.hotspotsSorted[self.hotspotFiltersMapping[sectionIndex]][index]
				if hotspot == listHotspot then
					return sectionIndex, index
				end
			elseif hotspotList == self.fieldsList then
				local field = self.fields[sectionIndex][index]
				if hotspot == nil then
					continue
				end
				if hotspot.field == field then
					return sectionIndex, index
				end
			end
		end
	end
	return nil, nil
end
function InGameMenuMobileMapFrame:resizeButtonTexts()
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		local totalButtonWidth = 0
		if self.buttonEnterVehicle.visible then
			totalButtonWidth = self.buttonSelectInGame.absSize[1] + self.buttonEnterVehicle.absSize[1] + self.buttonResetVehicle.absSize[1] + self.buttonBox.elementSpacing * 2
		elseif self.buttonGoToJob.visible then
			totalButtonWidth = self.buttonSelectInGame.absSize[1] + self.buttonGoToJob.absSize[1] + self.buttonCreateJob.absSize[1] + self.buttonBox.elementSpacing * 2
		else
			for _, button in pairs(self.buttonsResizeNeeded) do
				button:setTextSize(button.defaultTextSize)
			end
			self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
		end
		while self.buttonBox.absSize[1] <= totalButtonWidth do
			for _, button in pairs(self.buttonsResizeNeeded) do
				button:setTextSize(button.textSize - 1 * g_pixelSizeY)
			end
			self.buttonsResizeTextSize = self.buttonSelectInGame.textSize
			if self.buttonEnterVehicle.visible then
				totalButtonWidth = self.buttonSelectInGame.absSize[1] + self.buttonEnterVehicle.absSize[1] + self.buttonResetVehicle.absSize[1] + self.buttonBox.elementSpacing * 2
			elseif self.buttonGoToJob.visible then
				totalButtonWidth = self.buttonSelectInGame.absSize[1] + self.buttonGoToJob.absSize[1] + self.buttonCreateJob.absSize[1] + self.buttonBox.elementSpacing * 2
			end
		end
	else
		for _, button in pairs(self.buttonsResizeNeeded) do
			button:setTextSize(button.defaultTextSize)
		end
		self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
	end
end
function InGameMenuMobileMapFrame:onMoneyChanged(farmId, newBalance)
	if farmId == self.playerFarm.farmId and self.balanceText ~= nil then
		self.balanceText:setValue(newBalance)
		local requiredProfile = InGameMenuMobileMapFrame.PROFILE.MONEY_VALUE_NEUTRAL
		if math.floor(newBalance) <= -1 then
			requiredProfile = InGameMenuMobileMapFrame.PROFILE.MONEY_VALUE_NEGATIVE
		end
		self.balanceText:applyProfile(requiredProfile)
		self.balanceText.parent:invalidateLayout()
	end
end
function InGameMenuMobileMapFrame:onAIJobStarted(job, farmId)
	self.blockListSelectionEvents = true
	self.aiWorkersList:reloadData()
	FocusManager:setFocus(self.aiWorkersList)
	self.blockListSelectionEvents = false
	local inGameMap = g_currentMission.hud:getIngameMap()
	local hotspots = inGameMap.hotspots
	local aiHotspot = nil
	for _, hotspot in pairs(hotspots) do
		local vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
		if vehicle == nil or vehicle.getJob == nil then
			continue
		end
		local vehicleJob = vehicle:getJob()
		if vehicleJob == nil then
			continue
		end
		if hotspot:isa(AIHotspot) and job.jobId == vehicleJob.jobId then
			aiHotspot = hotspot
		end
	end
	self:setMapSelectionItem(aiHotspot)
	InfoDialog.show(g_i18n:getText("ai_startStateSuccess"))
end
function InGameMenuMobileMapFrame:onAIJobRemoved(jobId)
	self.aiWorkersList:reloadData()
end
function InGameMenuMobileMapFrame:onAITaskSkipped()
	self:refreshContextInput()
end
function InGameMenuMobileMapFrame:onAIJobStopped(job, aiMessage)
	if aiMessage ~= nil and (job ~= nil and (g_localPlayer ~= nil and job.startedFarmId == g_localPlayer.farmId)) then
		local text = aiMessage:getMessage(job)
		self:addStatusMessage(text)
	end
end
function InGameMenuMobileMapFrame:onInsetsChanged()
	self:updateElementSizes()
end
function InGameMenuMobileMapFrame:onDrawPostIngameMap()
	if self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW and self.foliageStateOverlayIsReady then
		local width, height = self.inGameMapBase.fullScreenLayout:getMapSize()
		local x, y = self.inGameMapBase.fullScreenLayout:getMapPosition()
		local filterBoxWidth = self.filterBoxContainer.absSize[1] + self.leftInset
		local pixFilterBoxWidth = filterBoxWidth * g_screenWidth
		local pixX = x * g_screenWidth
		local pixWidth = width * g_screenWidth
		local pixHeight = height * g_screenHeight
		local deltaX = pixFilterBoxWidth - pixX
		local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(GuiUtils.getUVs({ deltaX, 0, pixWidth + deltaX, pixHeight }, { pixWidth, pixHeight }))
		setOverlayUVs(self.foliageStateOverlay, u1, v1, u2, v2, u3, v3, u4, v4)
		renderOverlay(self.foliageStateOverlay, filterBoxWidth, y, width + filterBoxWidth - x, height)
	end
end
function InGameMenuMobileMapFrame:validateParameters()
	local isValid = true
	local errorText = ""
	if self.currentJob ~= nil then
		self.currentJob:setValues()
		isValid, errorText = self.currentJob:validate(g_localPlayer.farmId)
		self:updateWarnings()
	end
	self.aiTaskDialogErrorMessage:setText(errorText)
	self.aiTaskDialogErrorMessageBg:setSize(self.aiTaskDialogErrorMessage.absSize[1] + 80 * g_pixelSizeX)
	self.aiTaskDialogErrorMessageBg:setVisible(not isValid)
end
function InGameMenuMobileMapFrame:updateWarnings()
	for _, element in ipairs(self.currentJobElements) do
		local param = element.aiParameter
		local invalidElement = element:getDescendantByName("invalid")
		if invalidElement == nil then
			continue
		end
		invalidElement:setVisible(not param:getIsValid())
	end
end
function InGameMenuMobileMapFrame:addStatusMessage(message)
	table.insert(self.statusMessages, { text = message, removeTime = g_time + 5000 })
	self:updateStatusMessages()
end
function InGameMenuMobileMapFrame:updateStatusMessages()
	local text = ""
	for _, message in ipairs(self.statusMessages) do
		text = text .. message.text .. "\n"
	end
	self.statusMessage:setText(text)
	self.statusMessageBg:setVisible(0 < getTextLength(self.statusMessage.textSize, text, 99999))
	setTextBold(true)
	local textSize = self.statusMessage.textSize
	local width = getTextWidth(textSize, self.statusMessage.text) + 20 * g_pixelSizeX
	local height = getTextHeight(textSize, self.statusMessage.text) + 14 * g_pixelSizeX
	setTextBold(false)
	self.statusMessageBg:setSize(width, height)
	self.statusMessageBg:setPosition(nil, self.statusMessage.absPosition[2] + textSize * 0.5 - height * 0.5)
end
function InGameMenuMobileMapFrame:assignItemFillTypesData(baseIconProfile, iconFilenames, detailsIndex)
	local parentBox = self.pointDetailsIconsLayout[detailsIndex]
	if #self.pointDetailsValue < detailsIndex or #iconFilenames == 0 then
		parentBox.parent:setVisible(false)
		return detailsIndex
	end
	local totalWidth = 0
	local maxWidth = self.pointDetailsLayout.absSize[1] * 0.75
	self.pointDetailsIcon[detailsIndex]:applyProfile(baseIconProfile)
	self.pointDetailsIcon[detailsIndex]:setVisible(true)
	parentBox.parent:setVisible(true)
	self.pointDetailsValue[detailsIndex]:setVisible(false)
	for i = 1, #iconFilenames do
		local icon = self.pointDetailsIconTemplate:clone(parentBox)
		icon:setVisible(true)
		table.insert(self.clonedElements, icon)
		totalWidth = totalWidth + icon.absSize[1] + icon.margin[1] + icon.margin[3]
		icon:applyProfile("inGameMenuMobileMapDetailsIconTemplate")
		icon:setImageFilename(iconFilenames[i])
	end
	local parentSize = math.min(maxWidth, totalWidth)
	parentBox.parent:setSize(parentSize, nil)
	parentBox:setPosition(0)
	parentBox:setSize(totalWidth, nil)
	parentBox:invalidateLayout()
	if parentSize < totalWidth then
		self.marqueeBoxes[parentBox] = 0
	else
		self.marqueeBoxes[parentBox] = nil
	end
	return detailsIndex + 1
end
function InGameMenuMobileMapFrame:assignItemTextData(storeItem, displayItem)
	local numDetailsUsed = 0
	for i = 1, #self.pointDetailsValue do
		local detailsVisible = false
		if displayItem ~= nil and i <= #displayItem.attributeValues then
			local value = tostring(displayItem.attributeValues[i])
			local profile = displayItem.attributeIconProfiles[i]
			if profile ~= nil and profile ~= "" then
				self.pointDetailsValue[i]:setText(value)
				self.pointDetailsValue[i]:updateAbsolutePosition()
				if profile:startsWith("shopListAttributeIcon") then
					profile = "inGameMenuMobileMapDetailsIcon" .. profile:sub(22)
				end
				self.pointDetailsIcon[i]:applyProfile(profile)
				detailsVisible = value ~= nil and value ~= ""
			end
		end
		self.pointDetailsValue[i]:setVisible(detailsVisible)
		self.pointDetailsIcon[i]:setVisible(detailsVisible)
		self.pointDetailsIconsLayout[i].parent:setVisible(false)
		if detailsVisible then
			numDetailsUsed = numDetailsUsed + 1
		end
	end
	return numDetailsUsed
end
function InGameMenuMobileMapFrame:setDetailAttributes(storeItem, displayItem)
	for k, clone in pairs(self.clonedElements) do
		clone:delete()
		self.clonedElements[k] = nil
	end
	for k, _ in pairs(self.marqueeBoxes) do
		self.marqueeBoxes[k] = nil
	end
	local numDetailsUsed = self:assignItemTextData(storeItem, displayItem)
	if displayItem ~= nil then
		local nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconFillTypes", displayItem.fillTypeIconFilenames, numDetailsUsed + 1)
		nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconFillTypes", displayItem.foodFillTypeIconFilenames, nextDetailsIndex)
		nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconInput", displayItem.prodPointInputFillTypeIconFilenames, nextDetailsIndex)
		nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconOutput", displayItem.prodPointOutputFillTypeIconFilenames, nextDetailsIndex)
		nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconInput", displayItem.sellingStationFillTypesIconFilenames, nextDetailsIndex)
		self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconOutput", displayItem.buyingStationFillTypesIconFilenames, nextDetailsIndex)
	end
	self.pointDetailsLayout:invalidateLayout()
end
function InGameMenuMobileMapFrame:updateMarqueeAnimation(dt)
	for box, boxTime in pairs(self.marqueeBoxes) do
		local contentWidth = box.absSize[1]
		local visibleWidth = box.parent.absSize[1]
		local scrollAmount = contentWidth - visibleWidth
		local scrollLengthFactor = scrollAmount / visibleWidth
		local scrollDuration = 9000 * ((scrollLengthFactor - 1) * 0.5 + 1)
		local boxTime = boxTime + dt
		if scrollDuration <= boxTime then
			boxTime = -scrollDuration
		end
		local alpha = MathUtil.smoothstep(0.2, 0.8, math.abs(boxTime) / scrollDuration)
		local offset = scrollAmount * alpha
		box:setPosition(-offset)
		self.marqueeBoxes[box] = boxTime
	end
end
function InGameMenuMobileMapFrame:onSlotUsageChanged()
	self:refreshDetails()
end
function InGameMenuMobileMapFrame:getNumberOfItemsInSection(list, section)
	if list == self.vehiclesList then
		return #self.vehicles[section]
	elseif list == self.pointsList then
		return #self.hotspotsSorted[self.hotspotFiltersMapping[section]]
	elseif list == self.statusList then
		return #self.fieldStatus[self.statusSelector.state]
	elseif list == self.fieldsList then
		return self.fields[section] ~= nil and #self.fields[section] or 0
	elseif list == self.aiWorkersList then
		local count = 0
		for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
			count = count + 1
		end
		return count
	else
		return 0
	end
end
function InGameMenuMobileMapFrame:populateCellForItemInSection(list, section, index, cell)
	local glyph = cell:getAttribute("glyph")
	if glyph ~= nil then
		function glyph.glyphElement.overlay.getIsVisible()
			return self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and cell:getIsSelected() and FocusManager:getFocusedElement() == list
		end
	end
	if list == self.vehiclesList then
		local item = self.vehicles[section][index]
		local vehicle = item.vehicle
		local icon = cell:getAttribute("icon")
		icon:setImageUVs(nil, unpack(vehicle.mapHotspot.icon.uvs))
		cell:getAttribute("text"):setText(item.name)
	elseif list == self.pointsList then
		local hotspot = self.hotspotsSorted[self.hotspotFiltersMapping[section]][index]
		cell:getAttribute("text"):setText(hotspot:getName())
		local icon = cell:getAttribute("icon")
		icon:setImageUVs(nil, unpack(hotspot.icon.uvs))
	elseif list == self.statusList then
		self:populateStatusCellForItemInSection(list, section, index, cell)
	else
		if list == self.fieldsList then
			local field = self.fields[section][index]
			cell:getAttribute("text"):setText(g_i18n:getText("ui_fieldNo") .. " " .. field:getId())
			cell:getAttribute("size"):setText(g_i18n:formatArea(field:getAreaHa(), 2))
			local icon = cell:getAttribute("icon")
			if section == 1 then
				icon:applyProfile("inGameMenuMobileMapFieldsListIconOwned")
				cell:getAttribute("cost"):setText("")
				return
			else
				icon:applyProfile("inGameMenuMobileMapFieldsListIcon")
				cell:getAttribute("cost"):setText(g_i18n:formatMoney(field.farmland.price, 0, true, true))
				return
			end
		end
		if list == self.aiWorkersList then
			local count = 0
			local currentJob = nil
			for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
				if job.startedFarmId == self.playerFarm.farmId then
					count = count + 1
					if count == index then
						currentJob = job
						break
					end
				end
			end
			if currentJob ~= nil then
				cell:getAttribute("text"):setText(currentJob:getDescription())
				cell:getAttribute("title"):setText(currentJob:getTitle())
				cell:getAttribute("helper"):setText(currentJob:getHelperName())
			end
		end
	end
end
function InGameMenuMobileMapFrame:populateStatusCellForItemInSection(list, section, index, cell)
	if self.fieldStatusFilters[section][index] == nil then
		self.fieldStatusFilters[section][index] = true
	end
	local statusSelectorState = self.statusSelector.state
	local status = self.fieldStatus[statusSelectorState][index]
	cell:getAttribute("text"):setText(status.description)
	cell:getAttribute("text").getIsSelected = function()
		return self.fieldStatusFilters[self.statusSelector.state][index]
	end
	local statusColors = status.colors[self.isColorBlindMode]
	local iconBg = cell:getAttribute("iconBg")
	for i = #iconBg.elements, 1, -1 do
		iconBg.elements[i]:delete()
	end
	iconBg:applyProfile(InGameMenuMobileMapFrame.STATUS_BG_COLOR_PROFILE)
	if statusSelectorState == 1 then
		GuiOverlay.setSelectedColor(iconBg.overlay, unpack(statusColors))
	else
		self:assignGroundStatusColors(iconBg, statusColors, cell)
	end
	local getIsSelectedFunc = function()
		return self.fieldStatusFilters[self.statusSelector.state][index] and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
	end
	iconBg.getOverlayState = getIsSelectedFunc
	for i = #iconBg.elements, 1, -1 do
		iconBg.elements[i].getOverlayState = getIsSelectedFunc
	end
	local icon = cell:getAttribute("icon")
	if statusSelectorState == 1 then
		icon:setVisible(true)
		icon:setImageFilename(status.iconFilename)
		icon.getOverlayState = getIsSelectedFunc
	else
		icon:setVisible(false)
	end
end
function InGameMenuMobileMapFrame:onListSelectionChanged(list, section, index)
	if not self.isOpening and not self.blockListSelectionEvents then
		if list == self.aiWorkersList then
			local job = g_currentMission.aiSystem:getJobByIndex(index)
			if job ~= nil and job.vehicleParameter then
				local vehicle = job.vehicleParameter:getVehicle()
				if vehicle ~= nil then
					local hotspot = vehicle:getMapHotspot()
					if self.blockPanToHotspot then
						self.blockPanToHotspot = false
					else
						self.inGameMap:panToHotspot(hotspot)
					end
					self:setMapSelectionItem(hotspot)
				end
			end
		elseif list ~= self.statusList then
			local hotspot = nil
			if list == self.vehiclesList then
				local vehicle = self.vehicles[section][index]
				vehicle = vehicle.vehicle
				hotspot = vehicle:getMapHotspot()
			elseif list == self.pointsList then
				hotspot = self.hotspotsSorted[self.hotspotFiltersMapping[section]][index]
			else
				self.currentList = list
				self.currentListItemSectionIndex = list.selectedSectionIndex
				self.currentListItemIndex = list.selectedIndex
				if list == self.fieldsList and self.blockPanToHotspot or self.blockPanToHotspot then
					self.blockPanToHotspot = false
					self:setMapSelectionItem(hotspot)
				else
					self.inGameMap:panToHotspot(hotspot)
				end
			end
		end
	end
end
function InGameMenuMobileMapFrame:getNumberOfSections(list)
	if list == self.vehiclesList then
		return #self.vehicles
	elseif list == self.pointsList then
		return #self.hotspotFiltersMapping
	elseif list == self.fieldsList then
		return #self.fields
	else
		return 1
	end
end
function InGameMenuMobileMapFrame:getTitleForSectionHeader(list, section)
	if list == self.vehiclesList then
		return g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.VEHICLES[section])
	elseif list == self.pointsList then
		return g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.POINTS[self.hotspotFiltersMapping[section]])
	elseif list == self.fieldsList then
		local sectionTitle = g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.FIELDS[section])
		if section == 2 then
			local balance = g_i18n:getText("ui_balance") .. ": " .. g_i18n:formatMoney(self.playerFarm:getBalance(), 0, true, true)
			sectionTitle = sectionTitle .. "\n" .. balance
		end
		return sectionTitle
	else
		return ""
	end
end
function InGameMenuMobileMapFrame:onClickListItem(element)
	if not element.parent.wasScrolling then
		if element.indexInSection == self.currentListItemIndex and element.sectionIndex == self.currentListItemSectionIndex then
			self:showDetailsBox(true)
			return
		end
		self.currentListItem = element
	end
end
function InGameMenuMobileMapFrame:onClickStatusListItem(element)
	local statusFilter = self.fieldStatusFilters[self.statusSelector.state]
	if not element.parent.wasScrolling then
		statusFilter[element.indexInSection] = false
	end
	self:generateOverviewOverlay()
	self:saveFilters()
end
function InGameMenuMobileMapFrame:onJobTypeChanged(index)
	local jobTypeIndex = self.currentJobTypes[index]
	self:setActiveJobTypeSelection(jobTypeIndex)
end
function InGameMenuMobileMapFrame:updateParameterValueTexts()
	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	local addedPositionHotspot = false
	for _, element in ipairs(self.currentJobElements) do
		local parameter = element.aiParameter
		local parameterType = parameter:getType()
		if parameterType == AIParameterType.TEXT then
			local title = element:getDescendantByName("title")
			title:setText(parameter:getString())
		elseif parameterType == AIParameterType.POSITION or parameterType == AIParameterType.POSITION_ANGLE then
			element:getDescendantByName("text"):setText(parameter:getString())
			g_currentMission:addMapHotspot(self.aiTargetMapHotspot)
			local x, z = parameter:getPosition()
			self.aiTargetMapHotspot:setWorldPosition(x, z)
			if parameterType == AIParameterType.POSITION_ANGLE then
				local angle = parameter:getAngle() + 3.141592653589793
				self.aiTargetMapHotspot:setWorldRotation(angle)
			end
		else
			element:updateTitle()
		end
	end
end
function InGameMenuMobileMapFrame:onClickMultiTextOptionParameter(index, element)
	if self.currentJob ~= nil then
		local parameter = element.aiParameter
		self.currentJob:onParameterValueChanged(parameter)
		self:updateParameterValueTexts()
	end
	self:validateParameters()
end
function InGameMenuMobileMapFrame:onClickPositionParameter(element)
	local parameter = element.aiParameter
	self:startPickPosition(parameter, function(success, x, z)
		if success then
			element:getDescendantByName("text"):setText(parameter:getString())
		end
		self:setJobMenuVisible(true)
	end)
	self:setJobMenuVisible(false, true)
end
function InGameMenuMobileMapFrame:onClickPositionRotationParameter(element)
	local parameter = element.aiParameter
	self:startPickPositionAndRotation(parameter, function(success, x, z, angle)
		if success then
			element:getDescendantByName("text"):setText(parameter:getString())
		end
		self:setJobMenuVisible(true)
	end)
	self:setJobMenuVisible(false, true)
end
function InGameMenuMobileMapFrame:registerInput()
	self:unregisterInput()
	g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onMenuAccept, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.MENU_ACTIVATE, self, self.onMenuActivate, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.MENU_CANCEL, self, self.onMenuCancel, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_LEFT_RIGHT, self, self.onMenuLeftRightContinuous, false, false, true, true)
end
function InGameMenuMobileMapFrame:unregisterInput(customOnly)
	local list = customOnly and InGameMenuMobileMapFrame.CLEAR_CLOSE_INPUT_ACTIONS or InGameMenuMobileMapFrame.CLEAR_INPUT_ACTIONS
	for _, actionName in pairs(list) do
		g_inputBinding:removeActionEventsByActionName(actionName)
	end
end
function InGameMenuMobileMapFrame:onMenuAccept()
	if self.mode == InGameMenuMobileMapFrame.MODE_NONE or self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW then
		if self.currentList == self.statusList then
			self:onClickStatusListItem(self.currentList.sections[self.currentList.selectedSectionIndex].cells[self.currentList.selectedIndex])
			return
		else
			if self.currentList.visible then
				local focusElement = FocusManager:getFocusedElement()
				if self.currentList == self.pointsList and (focusElement ~= self.pointsList and focusElement.onClickCallback ~= nil) then
					focusElement.onClickCallback(self)
					return
				end
				if 0 < self.currentList.totalItemCount then
					self:onClickListItem(self.currentList.sections[self.currentList.selectedSectionIndex].cells[self.currentList.selectedIndex])
					return
				end
			end
			self:onDetailsButtonBack()
			return
		end
	end
	if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		local element = FocusManager:getFocusedElement()
		if element.name == "button" then
			element.onClickCallback(self, element)
		end
	end
end
function InGameMenuMobileMapFrame:onMenuActivate()
	if self.mode == InGameMenuMobileMapFrame.MODE_NONE and self.canEnter then
		self:onClickEnterVehicle()
		return
	end
	if self.mode == InGameMenuMobileMapFrame.MODE_NONE and self.canBuy then
		self:onClickBuyField()
		return
	end
	if self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and self:getCanCreateJob() then
		self:onCreateJob()
		return
	end
	if self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and self:getCanCancelJob() then
		self:onCancelJob()
		return
	end
	if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		self:onStartJob()
	end
end
function InGameMenuMobileMapFrame:onMenuCancel()
	if self.mode == InGameMenuMobileMapFrame.MODE_NONE then
		if self.canSetMarker then
			self:onClickTagPlace()
			return
		end
		if self.canReset then
			self:onClickResetVehicle()
		end
	elseif self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE then
		if self:getCanGoTo() then
			self:onStartGoToJob()
			return
		end
		self:onSkipJobTask()
	end
end
function InGameMenuMobileMapFrame:onMenuLeftRight(actionName, dir)
	if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.STATUS and g_analogStickVTolerance < math.abs(dir) then
		self:onStatusFilterChanged(actionName, dir)
	end
end
function InGameMenuMobileMapFrame:onMenuLeftRightContinuous(actionName, dir)
	if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.POINTS then
		FocusManager:inputEvent(InputAction.MENU_AXIS_LEFT_RIGHT, dir)
	else
		if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
			local element = FocusManager:getFocusedElement()
			if element.inputEvent ~= nil then
				element:inputEvent(actionName, dir)
			end
		end
	end
end
function InGameMenuMobileMapFrame:onDetailsButtonBack()
	self:showDetailsBox(false)
	FocusManager:setFocus(self.currentList)
end
function InGameMenuMobileMapFrame:onClickCloseMap()
	if self:getCanCloseMap() then
		self:onClickBackCallback()
	end
	if self:getIsPicking() then
		self:executePickingCallback(false)
		self:refreshContextInput()
		g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
		self.inGameMap.isTouchPickingRotation = false
		self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
	end
	if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		self:setMode(InGameMenuMobileMapFrame.MODE_AI_PAGE)
		self:setJobMenuVisible(false)
		self.aiWorkersList.handleFocus = true
		FocusManager:setFocus(self.aiWorkersList)
	end
end
function InGameMenuMobileMapFrame:onClickEnterVehicle()
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if vehicle ~= nil and (vehicle.getIsEnterableFromMenu ~= nil and vehicle:getIsEnterableFromMenu()) then
		self.onClickBackCallback()
		g_localPlayer:requestToEnterVehicle(vehicle)
	end
end
function InGameMenuMobileMapFrame:onClickResetVehicle()
	if not self.isResetPending and ((g_currentMission.tourIconsBase == nil or not g_currentMission.tourIconsBase.visible) and self.currentHotspot ~= nil) then
		YesNoDialog.show(self.onYesNoReset, self, g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_RESET_CONFIRM), g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.VEHICLE_RESET))
	end
end
function InGameMenuMobileMapFrame:onYesNoReset(yes)
	if yes and self.currentHotspot ~= nil then
		local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
		if vehicle ~= nil then
			self.buttonResetVehicle:setVisible(false)
			g_messageCenter:subscribe(ResetVehicleEvent, self.onVehicleReset, self)
			self.isResetPending = true
			g_client:getServerConnection():sendEvent(ResetVehicleEvent.new(vehicle))
		end
	end
end
function InGameMenuMobileMapFrame:onVehicleReset(state)
	self.isResetPending = false
	g_messageCenter:unsubscribe(ResetVehicleEvent, self)
	if state == ResetVehicleEvent.STATE_SUCCESS then
		InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_RESET_DONE), nil, nil, DialogElement.TYPE_INFO)
		self:updateVehicles()
		self.vehiclesList:reloadData()
		self.vehiclesList.sliderElement.parent:setVisible(self.vehiclesList.visible)
		self:showDetailsBox(false)
		self.blockListSelectionEvents = true
		self.vehiclesList:setSelectedItem(1, 1)
		self.blockListSelectionEvents = false
		self.blockPanToHotspot = true
	elseif state == ResetVehicleEvent.STATE_FAILED then
		InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_RESET_FAILED))
	elseif state == ResetVehicleEvent.STATE_IN_USE then
		InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_IN_USE))
	else
		InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_NO_PERMISSION))
	end
end
function InGameMenuMobileMapFrame:onClickTagPlace()
	if self.currentHotspot ~= nil and (self.currentHotspot.worldX ~= nil and self.currentHotspot.worldZ ~= nil) then
		if g_currentMission.currentMapTargetHotspot ~= self.currentHotspot then
			self.removeMarker = true
			g_currentMission:setMapTargetHotspot(self.currentHotspot)
		else
			self.removeMarker = false
			g_currentMission:setMapTargetHotspot(nil)
			self.currentHotspot:setBlinking(true)
		end
		self:showContextMarker(self.canSetMarker, self.removeMarker)
	end
end
function InGameMenuMobileMapFrame:onClickBuyField()
	local field = self.currentHotspot:getField()
	local farmland = field.farmland
	if g_farmlandManager:getFarmlandOwner(farmland.id) ~= g_currentMission:getFarmId() then
		local money = self.playerFarm:getBalance()
		local price = farmland.price
		if price <= money then
			local text = string.format(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.MOBILE_BUY_FIELD_TEXT), g_i18n:formatMoney(money, 0, true, true), g_i18n:formatMoney(price, 0, true, true))
			local title = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_TITLE)
			local callback = self.onYesNoBuyField
			YesNoDialog.show(callback, self, text, title)
		elseif Platform.hasInAppPurchases then
			if g_inAppPurchaseController ~= nil then
				if g_inAppPurchaseController:getIsAvailable() then
					local text = string.format(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.MOBILE_BUY_FIELD_TEXT_COINS), g_i18n:formatMoney(money, 0, true, true), g_i18n:formatMoney(price, 0, true, true))
					local title = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_TITLE)
					local callback = self.onYesNoBuyCoins
					YesNoDialog.show(callback, self, text, title)
					self.toBuyField = nil
				else
					InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY))
				end
			end
		end
	end
	self.toBuyField = field
end
function InGameMenuMobileMapFrame:onYesNoBuyField(yes)
	if yes then
		self.client:getServerConnection():sendEvent(FarmlandStateEvent.new(self.toBuyField.farmland.id, g_currentMission:getFarmId(), self.toBuyField.farmland.price))
		self:setMapSelectionItem(self.currentHotspot)
		self:updateFields()
		self.fieldsList:reloadData()
	end
	self.toBuyField = nil
end
function InGameMenuMobileMapFrame:onYesNoBuyCoins(yes)
	if yes then
		self.onClickBackCallback()
		g_shopMenu:showCoinShop()
	end
end
function InGameMenuMobileMapFrame:onStartGoToJob()
	if self:getCanGoTo() then
		self:tryStartGoToJob()
	end
end
function InGameMenuMobileMapFrame:onStartJob()
	if self:getCanStartJob() then
		self:startJob()
	end
end
function InGameMenuMobileMapFrame:onCancelJob()
	if self:getCanCancelJob() then
		self:cancelJob()
	end
end
function InGameMenuMobileMapFrame:onSkipJobTask()
	if self:getCanSkipJobTask() then
		self:skipCurrentTask()
	end
end
function InGameMenuMobileMapFrame:onConfirmAITarget()
	if self.isPickingLocation then
		local worldX = self.aiTargetMapHotspot.worldX
		local worldZ = self.aiTargetMapHotspot.worldZ
		local isReachable = g_currentMission.aiSystem:getIsPositionReachable(worldX, 0, worldZ)
		if isReachable then
			self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmRotation"))
			self.hasPickedLocationTouch = true
			self.inGameMap.isTouchPickingRotation = true
			self:executePickingCallback(true, worldX, worldZ)
			return
		else
			InfoDialog.show(g_i18n:getText("ai_validationErrorBlockedPosition"), nil, nil, DialogElement.TYPE_WARNING)
			return
		end
	end
	if self.isPickingRotation then
		self.inGameMap.isTouchPickingRotation = false
		self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
		self:executePickingCallback(true, self.aiTargetMapHotspot.worldRotation + 3.141592653589793)
	end
end
function InGameMenuMobileMapFrame:onCreateJob()
	if self:getCanCreateJob() then
		self:createJob()
	end
end
function InGameMenuMobileMapFrame:onMapPageSelected()
	self:showDetailsBox(false)
	for _, filterPage in pairs(self.filterBoxes) do
		filterPage:setVisible(false)
	end
	local mapPageId = self.mapPageSelector.state
	self.filterBoxes[mapPageId]:setVisible(true)
	self.inGameMapBase:applyCustomHotspotSortingOrder(InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO[mapPageId])
	if self.previousMapPageId == InGameMenuMobileMapFrame.PAGE_ID.AI then
		if self:getIsPicking() then
			self:executePickingCallback(false)
			g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
			self.inGameMap.isTouchPickingRotation = false
			self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
		end
		self:refreshContextInput()
		self:showContextInput(self.canEnter, self.canReset, self.canSetMarker, self.removeMarker, self.canBuy)
		self:selectHotspotInList(self.currentHotspot, self.currentList)
		if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
			self:onClickCloseMap()
		end
	elseif mapPageId == InGameMenuMobileMapFrame.PAGE_ID.AI then
		if self.previousMapPageId == InGameMenuMobileMapFrame.PAGE_ID.FIELDS then
			self:setMapSelectionItem(nil)
		end
	end
	self.currentList = self.pageLists[mapPageId]
	local listRecievedFocus = FocusManager:setFocus(self.currentList)
	if not self.isOpening then
		self:showDetailsBox(false)
	end
	if mapPageId == InGameMenuMobileMapFrame.PAGE_ID.STATUS then
		if self.mode ~= InGameMenuMobileMapFrame.MODE_OVERVIEW then
			self:setMode(InGameMenuMobileMapFrame.MODE_OVERVIEW)
		end
		self:setMapSelectionItem(nil)
	elseif mapPageId == InGameMenuMobileMapFrame.PAGE_ID.AI then
		if self.mode ~= InGameMenuMobileMapFrame.MODE_AI_PAGE then
			self:setMode(InGameMenuMobileMapFrame.MODE_AI_PAGE)
		end
		self:refreshContextInput()
		if not listRecievedFocus then
			FocusManager:unsetFocus(FocusManager.currentFocusData.focusElement)
		end
	elseif self.mode ~= InGameMenuMobileMapFrame.MODE_NONE then
		self:setMode(InGameMenuMobileMapFrame.MODE_NONE)
	end
	self.previousMapPageId = mapPageId
end
function InGameMenuMobileMapFrame:onPreviousPage()
	local newState = self.mapPageSelector.state - 1
	if newState == 0 then
		newState = #self.mapPageSelector.texts
	end
	self.mapPageSelector:setState(newState, true)
end
function InGameMenuMobileMapFrame:onNextPage()
	local newState = self.mapPageSelector.state + 1
	if #self.mapPageSelector.texts < newState then
		newState = 1
	end
	self.mapPageSelector:setState(newState, true)
end
function InGameMenuMobileMapFrame:onClickPagingStatus()
	if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.STATUS then
		self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.STATUS, true)
	end
end
function InGameMenuMobileMapFrame:onClickPagingVehicles()
	if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.VEHICLES then
		self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.VEHICLES, true)
	end
end
function InGameMenuMobileMapFrame:onClickPagingPoints()
	if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.POINTS then
		self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.POINTS, true)
	end
end
function InGameMenuMobileMapFrame:onClickPagingFields()
	if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.FIELDS then
		self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.FIELDS, true)
	end
end
function InGameMenuMobileMapFrame:onClickPagingAI()
	if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.AI then
		self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.AI, true)
	end
end
function InGameMenuMobileMapFrame:onStatusFilterChanged(_, dir)
	if self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW then
		if dir < 0 then
			local newState = math.max(self.statusSelector.state - 1, 1)
			self.statusSelector:setState(newState, true)
		else
			local newState = math.min(self.statusSelector.state + 1, #self.statusSelector.texts)
			self.statusSelector:setState(newState, true)
		end
		self:onStatusSelected()
	end
end
function InGameMenuMobileMapFrame:onStatusSelected()
	self.statusList:reloadData()
	self:generateOverviewOverlay()
end
function InGameMenuMobileMapFrame:onClickFilterLoading()
	self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING]
	for _, hotspot in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING]) do
		hotspot:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING])
	end
	self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:onClickFilterProductions()
	self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS]
	for _, hotspot in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS]) do
		hotspot:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS])
	end
	self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:onClickFilterAnimals()
	self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS]
	for _, hotspot in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS]) do
		hotspot:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS])
	end
	self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:onClickFilterOther()
	self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER]
	for _, hotspot in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER]) do
		hotspot:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER])
	end
	self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:onFilterButtonFocusEnter(button)
	button.overlay.color = { 0, 0, 0, 0 }
	button.overlay.alpha = 0
	button.icon.color = { 1, 1, 1, 1 }
	button.icon.alpha = 1
end
function InGameMenuMobileMapFrame:onFilterButtonFocusLeave(button)
	button.overlay.color = { 1, 1, 1, 1 }
	button.overlay.alpha = 1
	button.icon.color = { 0, 0, 0, 0 }
	button.icon.alpha = 0
end
function InGameMenuMobileMapFrame:setJobMenuVisible(isVisible, ignoreActionMessage)
	self.aiTaskDialogErrorMessage:setText("")
	self.aiTaskDialogErrorMessageBg:setVisible(false)
	if not ignoreActionMessage then
		self.actionMessage:setText("")
		self.actionMessageBg:setVisible(false)
	end
	self.aiTaskDialog:setVisible(isVisible)
	self:refreshContextInput()
end
function InGameMenuMobileMapFrame:createJob()
	local vehicle = self.currentHotspot:getVehicle()
	if vehicle ~= nil then
		self.currentJobTypes = {}
		local currentJobTypesTexts = {}
		local currentJobTypeIndex = nil
		local currentIndex = nil
		local lastJob = nil
		if vehicle.getLastJob ~= nil then
			lastJob = vehicle:getLastJob()
		end
		for name, index in pairs(AIJobType) do
			if self.jobTypeInstances[index]:getIsAvailableForVehicle(vehicle) then
				table.insert(self.currentJobTypes, index)
				table.insert(currentJobTypesTexts, g_currentMission.aiJobTypeManager:getJobTypeByIndex(index).title)
				if currentJobTypeIndex == nil or lastJob ~= nil and lastJob.class == self.jobTypeInstances[index].class then
					currentJobTypeIndex = index
					currentIndex = #self.currentJobTypes
				end
			end
		end
		if #self.currentJobTypes == 0 then
			printError("Error: vehicle has no support for any jobs, so button should not have been shown!")
			return
		end
		self.aiTaskDialogJobTypeSelector:setTexts(currentJobTypesTexts)
		self.aiTaskDialogJobTypeSelector:setState(currentIndex or 1)
		self:setMode(InGameMenuMobileMapFrame.MODE_CREATE_JOB)
		self.currentJobVehicle = vehicle
		self.currentJob = nil
		self:setJobMenuVisible(true)
		self.aiWorkersList.handleFocus = false
		FocusManager:setFocus(self.aiTaskDialogJobTypeSelector)
		self:setActiveJobTypeSelection(currentJobTypeIndex)
	end
end
function InGameMenuMobileMapFrame:tryStartGoToJob()
	if self.currentHotspot ~= nil then
		local vehicle = self.currentHotspot:getVehicle()
		if vehicle ~= nil then
			local job = self.jobTypeInstances[AIJobType.GOTO]
			self:startPickPositionAndRotation(job.positionAngleParameter, function(success, x, z, angle)
				if success then
					self:startGoToJob(vehicle, x, z, angle)
				end
				self:refreshContextInput()
			end)
			self:refreshContextInput()
		end
	end
end
function InGameMenuMobileMapFrame:startJob()
	if self.startJobPending then
		return
	end
	self.currentJob:setValues()
	local success, errorMessage = self.currentJob:validate(g_localPlayer.farmId)
	if success then
		local callback = function(state)
			if state == AIJob.START_SUCCESS then
				self:setMode(InGameMenuMobileMapFrame.MODE_AI_PAGE)
				self.currentJob = nil
				self:setJobMenuVisible(false)
				self.aiWorkersList.handleFocus = true
			end
		end
		self:tryStartJob(self.currentJob, g_localPlayer.farmId, callback)
	else
		InfoDialog.show(tostring(errorMessage), nil, nil, DialogElement.TYPE_WARNING)
		self:updateWarnings()
	end
end
function InGameMenuMobileMapFrame:cancelJob()
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if vehicle ~= nil and vehicle:getIsAIActive() then
		vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
	end
	self:refreshContextInput()
end
function InGameMenuMobileMapFrame:tryStartJob(job, farmId, callback)
	self.startJobPending = true
	g_messageCenter:subscribe(AIJobStartRequestEvent, self.onStartedJob, self, { callback })
	g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, farmId))
end
function InGameMenuMobileMapFrame:onStartedJob(args, state, jobTypeIndex)
	local callback = args[1]
	self.startJobPending = false
	g_messageCenter:unsubscribe(AIJobStartRequestEvent, self)
	if state ~= AIJob.START_SUCCESS then
		local jobType = g_currentMission.aiJobTypeManager:getJobTypeByIndex(jobTypeIndex)
		local text = jobType.classObject.getIsStartErrorText(state)
		InfoDialog.show(text, nil, nil, DialogElement.TYPE_INFO)
	end
	callback(state)
end
function InGameMenuMobileMapFrame:skipCurrentTask()
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if vehicle ~= nil and vehicle:getIsAIActive() then
		local job = vehicle:getJob()
		if job ~= nil then
			if job:getCanSkipTask() then
				vehicle:skipCurrentTask()
				return
			end
			self:refreshContextInput()
		end
	end
end
InGameMenuMobileMapFrame.STATUS_BG_COLOR_PROFILE = "inGameMenuMobileMapStatusListIconBg"
InGameMenuMobileMapFrame.STATUS_BG_COLOR_UVS = { 700, 0, 82, 82 }
InGameMenuMobileMapFrame.COLOR = { MAIN_MENU_BLUE = { 0.0227, 0.5346, 0.8519, 1 } }
InGameMenuMobileMapFrame.UV = { BUTTON_RIDE_HORSE = { 946, 539, 36, 36 }, BUTTON_ENTER_VEHICLE = { 909, 502, 36, 36 } }
