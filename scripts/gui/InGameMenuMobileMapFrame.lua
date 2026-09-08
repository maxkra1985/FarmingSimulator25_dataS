-- Local values: InGameMenuMobileMapFrame_mt, NO_CALLBACK
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
InGameMenuMobileMapFrame.PAGE_ID = {
	["STATUS"] = 1,
	["VEHICLES"] = 2,
	["POINTS"] = 3,
	["FIELDS"] = 4,
	["AI"] = 5
}
InGameMenuMobileMapFrame.PAGE_NAMES = {
	[InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = "ui_inGameMenuVehicles",
	[InGameMenuMobileMapFrame.PAGE_ID.POINTS] = "ui_inGameMenuPointsOfInterest",
	[InGameMenuMobileMapFrame.PAGE_ID.STATUS] = "ui_inGameMenuFieldStatus",
	[InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = "ui_inGameMenuFields",
	[InGameMenuMobileMapFrame.PAGE_ID.AI] = "ui_helpers"
}
local v2_ = {
	["VEHICLES"] = { "ui_mapHotspotFilter_driveables", "ui_mapHotspotFilter_tools", "helpLine_Animals_Horses" },
	["POINTS"] = {
		"ui_mapHotspotFilter_buyingSelling",
		"ui_mapHotspotFilter_productionPoints",
		"ui_mapHotspotFilter_animals",
		"ui_mapHotspotFilter_others"
	},
	["FIELDS"] = { "ui_mapPageFields_ownedByYou", "ui_mapPageFields_availableToBuy" }
}
InGameMenuMobileMapFrame.SECTION_NAMES = v2_
InGameMenuMobileMapFrame.HOTSPOT_FILTERS = {
	["LOADING"] = 1,
	["PRODUCTIONS"] = 2,
	["ANIMALS"] = 3,
	["OTHER"] = 4
}
InGameMenuMobileMapFrame.FIELD_STATUS = { "ui_mapViewMode2", "ui_mapViewMode1", "ui_mapOverviewSoil" }
local v3_ = InGameMenuMobileMapFrame
local v4_ = {
	[InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = {
		[MapHotspot.CATEGORY_TOOL] = true,
		[MapHotspot.CATEGORY_TRAILER] = true,
		[MapHotspot.CATEGORY_COMBINE] = true,
		[MapHotspot.CATEGORY_STEERABLE] = true,
		[MapHotspot.CATEGORY_AI] = true
	},
	[InGameMenuMobileMapFrame.PAGE_ID.POINTS] = {
		[MapHotspot.CATEGORY_ANIMAL] = true,
		[MapHotspot.CATEGORY_LOADING] = true,
		[MapHotspot.CATEGORY_OTHER] = true
	},
	[InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = {
		[MapHotspot.CATEGORY_FIELD] = true
	},
	[InGameMenuMobileMapFrame.PAGE_ID.AI] = {
		[MapHotspot.CATEGORY_TOOL] = true,
		[MapHotspot.CATEGORY_TRAILER] = true,
		[MapHotspot.CATEGORY_COMBINE] = true,
		[MapHotspot.CATEGORY_STEERABLE] = true,
		[MapHotspot.CATEGORY_AI] = true,
		[MapHotspot.CATEGORY_ANIMAL] = true,
		[MapHotspot.CATEGORY_LOADING] = true,
		[MapHotspot.CATEGORY_OTHER] = true
	},
	[MapHotspot.CATEGORY_PLAYER] = true
}
v3_.HOTSPOT_SWITCH_CATEGORIES = v4_
InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO = {
	[InGameMenuMobileMapFrame.PAGE_ID.STATUS] = {
		MapHotspot.CATEGORY_FIELD,
		MapHotspot.CATEGORY_MISSION,
		MapHotspot.CATEGORY_TOUR,
		MapHotspot.CATEGORY_STEERABLE,
		MapHotspot.CATEGORY_COMBINE,
		MapHotspot.CATEGORY_TRAILER,
		MapHotspot.CATEGORY_TOOL,
		MapHotspot.CATEGORY_AI,
		MapHotspot.CATEGORY_ANIMAL,
		MapHotspot.CATEGORY_UNLOADING,
		MapHotspot.CATEGORY_LOADING,
		MapHotspot.CATEGORY_PRODUCTION,
		MapHotspot.CATEGORY_SHOP,
		MapHotspot.CATEGORY_OTHER,
		MapHotspot.CATEGORY_PLAYER
	},
	[InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = {
		MapHotspot.CATEGORY_FIELD,
		MapHotspot.CATEGORY_ANIMAL,
		MapHotspot.CATEGORY_MISSION,
		MapHotspot.CATEGORY_TOUR,
		MapHotspot.CATEGORY_UNLOADING,
		MapHotspot.CATEGORY_LOADING,
		MapHotspot.CATEGORY_PRODUCTION,
		MapHotspot.CATEGORY_SHOP,
		MapHotspot.CATEGORY_OTHER,
		MapHotspot.CATEGORY_STEERABLE,
		MapHotspot.CATEGORY_COMBINE,
		MapHotspot.CATEGORY_TRAILER,
		MapHotspot.CATEGORY_TOOL,
		MapHotspot.CATEGORY_AI,
		MapHotspot.CATEGORY_PLAYER
	},
	[InGameMenuMobileMapFrame.PAGE_ID.POINTS] = {
		MapHotspot.CATEGORY_FIELD,
		MapHotspot.CATEGORY_MISSION,
		MapHotspot.CATEGORY_TOUR,
		MapHotspot.CATEGORY_STEERABLE,
		MapHotspot.CATEGORY_COMBINE,
		MapHotspot.CATEGORY_TRAILER,
		MapHotspot.CATEGORY_TOOL,
		MapHotspot.CATEGORY_AI,
		MapHotspot.CATEGORY_ANIMAL,
		MapHotspot.CATEGORY_UNLOADING,
		MapHotspot.CATEGORY_LOADING,
		MapHotspot.CATEGORY_PRODUCTION,
		MapHotspot.CATEGORY_SHOP,
		MapHotspot.CATEGORY_OTHER,
		MapHotspot.CATEGORY_PLAYER
	},
	[InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = {
		MapHotspot.CATEGORY_MISSION,
		MapHotspot.CATEGORY_TOUR,
		MapHotspot.CATEGORY_OTHER,
		MapHotspot.CATEGORY_STEERABLE,
		MapHotspot.CATEGORY_COMBINE,
		MapHotspot.CATEGORY_TRAILER,
		MapHotspot.CATEGORY_TOOL,
		MapHotspot.CATEGORY_ANIMAL,
		MapHotspot.CATEGORY_UNLOADING,
		MapHotspot.CATEGORY_LOADING,
		MapHotspot.CATEGORY_PRODUCTION,
		MapHotspot.CATEGORY_SHOP,
		MapHotspot.CATEGORY_AI,
		MapHotspot.CATEGORY_FIELD,
		MapHotspot.CATEGORY_PLAYER
	},
	[InGameMenuMobileMapFrame.PAGE_ID.AI] = {
		MapHotspot.CATEGORY_FIELD,
		MapHotspot.CATEGORY_MISSION,
		MapHotspot.CATEGORY_TOUR,
		MapHotspot.CATEGORY_ANIMAL,
		MapHotspot.CATEGORY_UNLOADING,
		MapHotspot.CATEGORY_LOADING,
		MapHotspot.CATEGORY_PRODUCTION,
		MapHotspot.CATEGORY_SHOP,
		MapHotspot.CATEGORY_OTHER,
		MapHotspot.CATEGORY_STEERABLE,
		MapHotspot.CATEGORY_COMBINE,
		MapHotspot.CATEGORY_TRAILER,
		MapHotspot.CATEGORY_TOOL,
		MapHotspot.CATEGORY_AI,
		MapHotspot.CATEGORY_PLAYER
	}
}
InGameMenuMobileMapFrame.BUTTON_TEXTS = {
	["SET_MARKER"] = "action_tag",
	["REMOVE_MARKER"] = "action_untag",
	["VEHICLE_RESET"] = "button_reset",
	["DIALOG_VEHICLE_RESET_DONE"] = "ui_vehicleResetDone",
	["DIALOG_VEHICLE_RESET_FAILED"] = "ui_vehicleResetFailed",
	["DIALOG_VEHICLE_IN_USE"] = "shop_messageReturnVehicleInUse",
	["DIALOG_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionGeneral",
	["DIALOG_VEHICLE_RESET_CONFIRM"] = "ui_wantToResetVehicleText",
	["DIALOG_BUY_FARMLAND_TITLE"] = "shop_messageBuyFarmlandTitle",
	["DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY"] = "shop_messageNotEnoughMoneyToBuyFarmland",
	["MOBILE_BUY_FIELD_TEXT"] = "ui_mobile_buyFieldDialogText",
	["MOBILE_BUY_FIELD_TEXT_COINS"] = "ui_mobile_buyFieldDialogText_buyCoins",
	["BUTTON_CLOSE_MAP"] = "button_closeMap",
	["BUTTON_CANCEL"] = "button_cancel"
}
InGameMenuMobileMapFrame.CLEAR_INPUT_ACTIONS = {
	InputAction.MENU_ACCEPT,
	InputAction.MENU_ACTIVATE,
	InputAction.MENU_CANCEL,
	InputAction.MENU_EXTRA_1,
	InputAction.MENU_EXTRA_2,
	InputAction.SWITCH_VEHICLE,
	InputAction.SWITCH_VEHICLE_BACK,
	InputAction.CAMERA_ZOOM_IN_OUT,
	InputAction.MENU_AXIS_LEFT_RIGHT
}
InGameMenuMobileMapFrame.CLEAR_CLOSE_INPUT_ACTIONS = { InputAction.SWITCH_VEHICLE, InputAction.SWITCH_VEHICLE_BACK, InputAction.CAMERA_ZOOM_IN_OUT }
local function NO_CALLBACK() end
InGameMenuMobileMapFrame.INPUT_CONTEXT_NAME = "MENU_MOBILE_MAP"
function InGameMenuMobileMapFrame.register()
	if Platform.isMobile then
		local v6_ = InGameMenuMobileMapFrame.new()
		g_gui:loadGui("dataS/gui/InGameMenuMobileMapFrame.xml", "MobileMapFrame", v6_, true)
	end
end

-- Upvalues: InGameMenuMobileMapFrame_mt, NO_CALLBACK
-- Local values: self
function InGameMenuMobileMapFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuMobileMapFrame_mt, (copy) NO_CALLBACK
	local v_u_9_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMobileMapFrame_mt)
	v_u_9_.onClickBackCallback = NO_CALLBACK
	v_u_9_.client = nil
	v_u_9_.playerFarm = nil
	v_u_9_.statusMessages = {}
	v_u_9_.mode = InGameMenuMobileMapFrame.MODE_NONE
	v_u_9_.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	v_u_9_.fruitTypeFilter = {}
	v_u_9_.fruitTypeFilterMapping = {}
	v_u_9_.growthStateFilter = {}
	v_u_9_.soilStateFilter = {}
	v_u_9_.fieldStatusFilters = {
		[InGameMenuMobileMapFrame.MAP_FRUIT_TYPE] = v_u_9_.fruitTypeFilter,
		[InGameMenuMobileMapFrame.MAP_GROWTH] = v_u_9_.growthStateFilter,
		[InGameMenuMobileMapFrame.MAP_SOIL] = v_u_9_.soilStateFilter
	}
	v_u_9_.foliageStateOverlay = nil
	v_u_9_.foliageStateOverlayIsReady = false
	function v_u_9_.overviewOverlayFinishedCallback(p10_)
		-- upvalues: (copy) v_u_9_
		v_u_9_:onOverviewOverlayFinished(p10_)
	end
	v_u_9_.inGameMapBase = nil
	v_u_9_.needsSolidBackground = Platform.ingameMap.needsSolidBackground
	v_u_9_.isOpening = true
	v_u_9_.blockListSelectionEvents = false
	v_u_9_.hasFullScreenMap = true
	v_u_9_.goToMainOverview = false
	v_u_9_.pageLists = {}
	v_u_9_.vehicles = {}
	v_u_9_.fieldStatus = {}
	v_u_9_.fields = {}
	v_u_9_.hotspotsSorted = {}
	v_u_9_.hotspotFiltersActive = {
		true,
		true,
		true,
		true
	}
	v_u_9_.hotspotFiltersMapping = {}
	v_u_9_.marqueeBoxes = {}
	v_u_9_.clonedElements = {}
	v_u_9_.currentHotspot = nil
	v_u_9_.currentList = nil
	v_u_9_.currentListItem = nil
	v_u_9_.jobTypeInstances = {}
	v_u_9_.statusMessages = {}
	v_u_9_.currentJob = nil
	v_u_9_.hasPickedLocationTouch = false
	v_u_9_.hasPickedRotationTouch = false
	v_u_9_.lastTouchPosX = 0
	v_u_9_.lastTouchPosY = 0
	v_u_9_.updateTime = 0
	v_u_9_.aiTargetMapHotspot = AITargetHotspot.new()
	v_u_9_.pickingRotationSnapAngle = 0
	return v_u_9_
end

-- Local values: newGui
function InGameMenuMobileMapFrame.createFromExistingGui(gui, guiName)
	local v13_ = InGameMenuMobileMapFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v13_, true)
	return v13_
end

-- Upvalues: NO_CALLBACK
function InGameMenuMobileMapFrame:copyAttributes(src)
	-- upvalues: (copy) NO_CALLBACK
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

-- Upvalues: NO_CALLBACK
-- Local values: _, pageName, i, pageButton, _, status, i, button
function InGameMenuMobileMapFrame:initialize(onClickBackCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK
	self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
	self.buttonsResizeNeeded = {
		self.buttonSelectInGame,
		self.buttonEnterVehicle,
		self.buttonResetVehicle,
		self.buttonGoToJob,
		self.buttonCreateJob
	}
	self.pageLists = {
		[InGameMenuMobileMapFrame.PAGE_ID.STATUS] = self.statusList,
		[InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = self.vehiclesList,
		[InGameMenuMobileMapFrame.PAGE_ID.POINTS] = self.pointsList,
		[InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = self.fieldsList,
		[InGameMenuMobileMapFrame.PAGE_ID.AI] = self.aiWorkersList
	}
	self.currentList = self.statusList
	self.vehiclesList.detailsBox = self.vehicleDetailsBox
	self.pointsList.detailsBox = self.pointDetailsBox
	self.aiWorkersList.detailsBox = self.aiDetailsBox
	self.mapPageSelector.texts = {}
	for _, v19_ in pairs(InGameMenuMobileMapFrame.PAGE_NAMES) do
		local v20_ = self.mapPageSelector.texts
		local v21_ = g_i18n
		table.insert(v20_, v21_:getText(v19_))
	end
	for v_u_22_, v23_ in pairs(self.pagingElement.elements) do
		if v23_.getOverlayState ~= nil then
			function v23_.getOverlayState()
				-- upvalues: (copy) self, (copy) v_u_22_
				return self.mapPageSelector.state == v_u_22_ and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
			end
		end
	end
	self.mapPageSelector:setState(1)
	self.statusSelector.texts = {}
	for _, v24_ in pairs(InGameMenuMobileMapFrame.FIELD_STATUS) do
		local v25_ = self.statusSelector.texts
		local v26_ = g_i18n
		table.insert(v25_, v26_:getText(v24_))
	end
	self.statusSelector:setState(1)
	for v_u_27_, v28_ in pairs(self.pointsFilterButtonBox.elements) do
		function v28_.getOverlayState()
			-- upvalues: (copy) self, (copy) v_u_27_
			return self.hotspotFiltersActive[v_u_27_] and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
		end
	end
	function self.pointsFilterButtonGlyph.glyphElement.overlay.getIsVisible()
		-- upvalues: (copy) self
		local v29_
		if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
			v29_ = FocusManager:getFocusedElement() ~= self.pointsList
		else
			v29_ = false
		end
		return v29_
	end
	FocusManager:linkElements(self.pointsList, FocusManager.BOTTOM, nil)
	FocusManager:linkElements(self.pointsList, FocusManager.RIGHT, self.pointsFilterButtonBox)
	self.aiWorkersList.onClickCallback = self.onListSelectionChanged
end

function InGameMenuMobileMapFrame:reset()
	InGameMenuMobileMapFrame:superClass().reset(self)
	self.isInputContextActive = false
end

-- Local values: inGameMap, inGameMapBase, mapWidth, player, playerVehicle, slider
function InGameMenuMobileMapFrame:onFrameOpen()
	InGameMenuMobileMapFrame:superClass().onFrameOpen(self)
	self:loadFilters()
	self:setColorBlindMode(Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false))
	self:updateElementSizes()
	local v32_ = self.inGameMap
	local v33_ = self.inGameMapBase
	self:toggleMapInput(true)
	local v34_ = 1 - self.filterBoxContainer.absSize[1] - self.leftInset + 27 * g_aspectScaleX / g_referenceScreenWidth
	v33_.fullScreenLayout:setMapWidth(v34_)
	v33_.clipHotspots = true
	v33_:restoreDefaultFilter()
	v32_:onOpen()
	v32_:registerActionEvents()
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
	local v35_ = self.inGameMap:getPlayerHotspot(self.inGameMap.ingameMap.hotspotsSorted[true]):getVehicle()
	if v35_ ~= nil then
		self:selectHotspotInList(v35_:getMapHotspot(), self.vehiclesList)
		if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.VEHICLES or self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.AI then
			self:setMapSelectionItem(v35_:getMapHotspot())
		end
	end
	g_messageCenter:subscribe(MessageType.AI_JOB_STARTED, self.onAIJobStarted, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_STOPPED, self.onAIJobStopped, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_REMOVED, self.onAIJobRemoved, self)
	g_messageCenter:subscribe(MessageType.AI_TASK_SKIPPED, self.onAITaskSkipped, self)
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.onInsetsChanged, self)
	local v36_ = self.currentList.sliderElement
	if v36_ ~= nil then
		local v37_ = v36_.parent
		local v38_ = self.currentList.visible
		if v38_ then
			if self.currentList.totalItemCount > 0 then
				v38_ = v36_.needsSlider
			else
				v38_ = false
			end
		end
		v37_:setVisible(v38_)
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

-- Local values: fruitValue, index, state, fruitId, name, growthValue, i, state, soilValue, i, state
function InGameMenuMobileMapFrame:saveFilters()
	local v41_ = ""
	for v42_, _ in pairs(self.fruitTypeFilter) do
		if self.fruitTypeFilter[v42_] == false then
			local v43_ = self.fruitTypeFilterMapping[v42_]
			local v44_ = g_fruitTypeManager:getFruitTypeNameByIndex(v43_)
			if v41_ == "" then
				v41_ = v44_
			else
				v41_ = v41_ .. ";" .. v44_
			end
		end
	end
	local v45_ = 0
	for v46_, v47_ in ipairs(self.growthStateFilter) do
		if v47_ then
			v45_ = Utils.setBit(v45_, v46_)
		end
	end
	local v48_ = 0
	for v49_, v50_ in ipairs(self.soilStateFilter) do
		if v50_ then
			v48_ = Utils.setBit(v48_, v49_)
		end
	end
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER, v41_, false)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER, v45_, false)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER, v48_, true)
	self.statusMessages = {}
	self:updateStatusMessages()
end

-- Local values: fruitValue, fruitNames, inverseFruitTypeFilterMapping, index, key, _, fruitName, fruitDesc, growthValue, i, _, soilValue, i, _
function InGameMenuMobileMapFrame:loadFilters()
	local v52_ = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER):split(";")
	local v53_ = {}
	for v54_, v55_ in pairs(self.fruitTypeFilterMapping) do
		v53_[v55_] = v54_
	end
	for _, v56_ in ipairs(v52_) do
		local v57_ = g_fruitTypeManager:getFruitTypeByName(v56_)
		if v57_ ~= nil and v53_[v57_.index] ~= nil then
			self.fruitTypeFilter[v53_[v57_.index]] = false
		end
	end
	local v58_ = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER)
	for v59_, _ in pairs(self.displayGrowthStates) do
		self.growthStateFilter[v59_] = Utils.isBitSet(v58_, v59_)
	end
	local v60_ = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER)
	for v61_, _ in pairs(self.displaySoilStates) do
		self.soilStateFilter[v61_] = Utils.isBitSet(v60_, v61_)
	end
end

-- Local values: mapOverlayGenerator, i, cropType
function InGameMenuMobileMapFrame:onLoadMapFinished()
	local v63_ = g_currentMission.mapOverlayGenerator
	if v63_ ~= nil then
		self.displayCropTypes = v63_:getDisplayCropTypes()
		self.displayGrowthStates = v63_:getDisplayGrowthStates()
		self.displaySoilStates = v63_:getDisplaySoilStates()
	end
	local v64_ = self.fieldStatus
	local v65_ = self.displayCropTypes
	table.insert(v64_, v65_)
	local v66_ = self.fieldStatus
	local v67_ = self.displayGrowthStates
	table.insert(v66_, v67_)
	local v68_ = self.fieldStatus
	local v69_ = self.displaySoilStates
	table.insert(v68_, v69_)
	for v70_, v71_ in pairs(self.displayCropTypes) do
		self.fruitTypeFilter[v70_] = true
		self.fruitTypeFilterMapping[v70_] = v71_.fruitTypeIndex
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

-- Local values: localX, localY, worldX, worldZ, angle, numSteps
function InGameMenuMobileMapFrame:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self.isPickingRotation and not self.hasPickedRotationTouch then
		local v81_, v82_ = self.inGameMap:getLocalPosition(posX, posY)
		local v83_, v84_ = self.inGameMap:localToWorldPos(v81_, v82_)
		local v85_ = v83_ - self.pickingRotationOrigin[1]
		local v86_ = v84_ - self.pickingRotationOrigin[2]
		local v87_ = math.atan2(v85_, v86_) + 3.141592653589793
		if self.pickingRotationSnapAngle > 0 then
			v87_ = MathUtil.round(v87_ / self.pickingRotationSnapAngle, 0) * self.pickingRotationSnapAngle
		end
		self.aiTargetMapHotspot:setWorldRotation(v87_)
	end
	if isUp then
		self.lastTouchPosX = posX
		self.lastTouchPosY = posY
	end
	return InGameMenuMobileMapFrame:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed)
end

-- Local values: currentInputHelpMode, localX, localY, worldX, worldZ, angle, numSteps, hasChanged, i, removeTime
function InGameMenuMobileMapFrame:update(dt)
	InGameMenuMobileMapFrame:superClass().update(self, dt)
	self.isOpening = false
	local v90_ = g_inputBinding:getInputHelpMode()
	if v90_ ~= self.lastInputHelpMode then
		self.lastInputHelpMode = v90_
		self:refreshContextInput()
	end
	if v90_ == GS_INPUT_HELP_MODE_GAMEPAD then
		local v91_, v92_ = self.inGameMap:getLocalPointerTarget()
		if self.isPickingLocation then
			self:setTargetPointHotspotPosition(v91_, v92_)
		elseif self.isPickingRotation then
			local v93_, v94_ = self.inGameMap:localToWorldPos(v91_, v92_)
			local v95_ = v93_ - self.pickingRotationOrigin[1]
			local v96_ = v94_ - self.pickingRotationOrigin[2]
			local v97_ = math.atan2(v95_, v96_) + 3.141592653589793
			if self.pickingRotationSnapAngle > 0 then
				v97_ = MathUtil.round(v97_ / self.pickingRotationSnapAngle, 0) * self.pickingRotationSnapAngle
			end
			self.aiTargetMapHotspot:setWorldRotation(v97_)
		end
	end
	local v98_ = false
	for _ = 1, #self.statusMessages do
		if self.statusMessages[1].removeTime < g_time then
			table.remove(self.statusMessages, 1)
			v98_ = true
		end
	end
	if v98_ then
		self:updateStatusMessages()
	end
	self:updateMarqueeAnimation(dt)
end

-- Local values: worldX, worldZ
function InGameMenuMobileMapFrame:setTargetPointHotspotPosition(localX, localY)
	local v102_, v103_ = self.inGameMap:localToWorldPos(localX, localY)
	self.aiTargetMapHotspot:setWorldPosition(v102_, v103_)
end

-- Local values: currentPageIsNotAI, buttonNeedsCancelText, buttonCloseText
function InGameMenuMobileMapFrame:showContextInput(canEnter, canReset, canSetMarker, removeMarker, canBuy)
	local v110_ = self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.AI
	self.buttonEnterVehicle:setVisible(canEnter and v110_)
	self.buttonResetVehicle:setVisible(canReset and v110_)
	self.buttonSetMarker:setVisible(canSetMarker and v110_)
	self.buttonBuyField:setVisible(canBuy and v110_)
	self.buttonCancelJob:setVisible(self:getCanCancelJob())
	self.buttonGoToJob:setVisible(self:getCanGoTo())
	self.buttonCreateJob:setVisible(self:getCanCreateJob())
	self.buttonStartJob:setVisible(self:getCanStartJob())
	self.buttonSkipTask:setVisible(self:getCanSkipJobTask())
	self.buttonConfirmAITarget:setVisible(self:canConfirmAITarget())
	self:showContextMarker(canSetMarker, removeMarker)
	local v111_ = (self:getIsPicking() or self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB) and InGameMenuMobileMapFrame.BUTTON_TEXTS.BUTTON_CANCEL or InGameMenuMobileMapFrame.BUTTON_TEXTS.BUTTON_CLOSE_MAP
	self.buttonCloseMap:setText(g_i18n:getText(v111_))
	local v112_ = self.buttonSelectInGame
	local v113_
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		v113_ = self:getIsPicking() or self.mode ~= InGameMenuMobileMapFrame.MODE_CREATE_JOB
	else
		v113_ = false
	end
	v112_:setVisible(v113_)
	self.buttonBox:invalidateLayout()
end

-- Local values: currentPageIsAI
function InGameMenuMobileMapFrame:showContextInputAI(canGoTo, canCreateJob, canCancel, canSkipTask)
	local v119_ = self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.AI
	self.canGoTo = canGoTo and v119_
	self.canCreateJob = canCreateJob and v119_
	self.canCancel = canCancel and v119_
	self.canSkipTask = canSkipTask and v119_
end

-- Local values: markerText
function InGameMenuMobileMapFrame:showContextMarker(canSetMarker, removeMarker)
	if canSetMarker then
		local v123_
		if removeMarker then
			v123_ = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.REMOVE_MARKER)
		else
			v123_ = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.SET_MARKER)
		end
		self.buttonSetMarker:setText(v123_)
	end
end

function InGameMenuMobileMapFrame:getCanCancelJob()
	local v125_ = self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and not self:getIsPicking() and (self.canCancel and g_currentMission:getHasPlayerPermission("hireAssistant"))
	if v125_ then
		v125_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v125_
end

function InGameMenuMobileMapFrame:getCanCreateJob()
	local v127_ = self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and not self:getIsPicking() and (self.canCreateJob and g_currentMission:getHasPlayerPermission("hireAssistant"))
	if v127_ then
		v127_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v127_
end

function InGameMenuMobileMapFrame:getCanGoTo()
	local v129_ = self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and not self:getIsPicking() and (self.canGoTo and g_currentMission:getHasPlayerPermission("hireAssistant"))
	if v129_ then
		v129_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v129_
end

function InGameMenuMobileMapFrame:getCanStartJob()
	local v131_ = self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB and (not self:getIsPicking() and g_currentMission:getHasPlayerPermission("hireAssistant"))
	if v131_ then
		v131_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v131_
end

function InGameMenuMobileMapFrame:getCanSkipJobTask()
	local v133_ = self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and not self:getIsPicking() and (self.canSkipTask and g_currentMission:getHasPlayerPermission("hireAssistant"))
	if v133_ then
		v133_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v133_
end

function InGameMenuMobileMapFrame:getCanCloseMap()
	local v135_
	if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		v135_ = false
	else
		v135_ = not self:getIsPicking()
	end
	return v135_
end

function InGameMenuMobileMapFrame:canConfirmAITarget()
	local v137_ = self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH and (not self.aiTaskDialog.visible and (self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB or self:getIsPicking()))
	if v137_ then
		v137_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v137_
end

-- Local values: hotspot, vehicle, canGoTo, canCreateJob, canCancel, canSkipTask, typeIndex, instance, job, isVisible
function InGameMenuMobileMapFrame:refreshContextInput()
	local v139_ = self.currentHotspot
	local v140_ = InGameMenuMapUtil.getHotspotVehicle(v139_)
	local v141_ = false
	local v142_ = false
	local v143_ = false
	local v144_
	if v140_ == nil or (not g_currentMission.accessHandler:canPlayerAccess(v140_) or v140_.spec_aiJobVehicle == nil) then
		v144_ = false
	else
		v144_ = v140_:getIsAIActive()
		if v144_ then
			local v145_ = v140_:getJob()
			if v145_ ~= nil and v145_:getCanSkipTask() then
				v143_ = true
			end
		else
			v141_ = self.jobTypeInstances[AIJobType.GOTO]:getIsAvailableForVehicle(v140_)
			v142_ = false
			for _, v146_ in pairs(self.jobTypeInstances) do
				if v146_:getIsAvailableForVehicle(v140_) and not self:getIsPicking() then
					v142_ = true
					break
				end
			end
		end
	end
	local v147_ = not v142_
	if v147_ then
		v147_ = g_currentMission.aiSystem:getAILimitedReached()
	end
	self.limitReachedWarning:setVisible(v147_)
	self.limitReachedWarningBg:setVisible(v147_)
	self:showContextInputAI(v141_, v142_, v144_, v143_)
	self:showContextInput()
end

-- Local values: leftInset, sliderPosX, buttonBoxHeight, filterBoxWidth, uv1, uv2
function InGameMenuMobileMapFrame:updateElementSizes()
	local v149_ = getSafeFrameInsets()
	self.leftInset = v149_
	local v150_ = self.filterBoxContainer.absSize[1] - self.statusListSlider.absSize[1] * 1.5
	local v151_ = self.buttonBox.absSize[2]
	local v152_ = self.pagingElement.size[1]
	self.mapPageSelector:setPosition(v149_, nil)
	self.pagingElement:setPosition(v149_, nil)
	self.roundedTopContainer:setSize(v152_ + v149_, nil)
	self.roundedTopCenter:setSize(v152_ - 42 * g_pixelSizeX + v149_, nil)
	self.buttonCloseMapContainer:setSize(v152_ + v149_, nil)
	self.filterBoxContainer:setAnchors(0, 0, 0, 1 - self.pagingElement.absSize[2])
	self.filterBoxContainer:setPosition(v149_, nil)
	local v153_ = self.filterBoxContainer.absSize[1] * g_screenWidth
	local v154_ = self.filterBoxContainer.absSize[2] * g_screenHeight
	local v155_ = self.filterBoxContainer
	local v156_ = GuiUtils.getUVs
	v155_:setImageUVs(nil, unpack(v156_({
		v149_,
		0,
		v153_,
		v154_
	}, { 2048, 2048 })))
	self.filterBoxContainerBg:setAnchors(0, 0, 0, 1 - self.pagingElement.absSize[2])
	self.filterBoxContainerBg:updateAbsolutePosition()
	local v157_ = self.filterBoxContainerBg
	local v158_ = GuiUtils.getUVs
	v157_:setImageUVs(nil, unpack(v158_({
		0,
		0,
		v153_,
		v154_
	}, { 2048, 2048 })))
	self.inGameMap:setCursorCenter((self.filterBoxContainer.absSize[1] + self.leftInset) * 0.5, 0)
	self.buttonBox:setSize(1 - v152_ - v149_ - 50 * g_pixelSizeX)
	self.statusList:setAnchors(0, 0, v151_ + 20 * g_pixelSizeY, 1 + self.statusSelector.position[2] - self.statusSelector.absSize[2] - 30 * g_pixelSizeY)
	self.statusList:updateAbsolutePosition()
	self.statusListSlider:setAnchors(0, 0, v151_ + 20 * g_pixelSizeY, 1 + self.statusSelector.position[2] - self.statusSelector.absSize[2] - 30 * g_pixelSizeY)
	self.statusListSliderBar:setAnchors(0.5, 0.5, 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.statusListSlider:setPosition(v150_)
	self.statusListTopClipper:setPosition(0, self.statusList.absPosition[2] + self.statusList.absSize[2])
	self.statusListBottomClipper:setPosition(0, self.statusList.absPosition[2] - self.statusListBottomClipper.absSize[2])
	self.vehiclesList:setAnchors(0, 0, v151_ + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
	self.vehiclesList:updateAbsolutePosition()
	self.vehiclesListSlider:setAnchors(0, 0, v151_ + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
	self.vehiclesListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.vehiclesListSlider:setPosition(v150_)
	self.vehiclesListTopClipper:setPosition(0, self.vehiclesList.absPosition[2] + self.vehiclesList.absSize[2])
	self.vehiclesListBottomClipper:setPosition(0, self.vehiclesList.absPosition[2] - self.vehiclesListBottomClipper.absSize[2])
	self.pointsList:setAnchors(0, 0, v151_ + 20 * g_pixelSizeY, self.pointsFilterButtonBox.absPosition[2] - self.pointsFilterButtonBox.position[2] - 20 * g_pixelSizeY)
	self.pointsList:updateAbsolutePosition()
	self.pointsListSlider:setAnchors(0, 0, v151_ + 20 * g_pixelSizeY, self.pointsFilterButtonBox.absPosition[2] - self.pointsFilterButtonBox.position[2] - 20 * g_pixelSizeY)
	self.pointsListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.pointsListSlider:setPosition(v150_)
	self.pointsListTopClipper:setPosition(0, self.pointsList.absPosition[2] + self.pointsList.absSize[2])
	self.pointsListBottomClipper:setPosition(0, self.pointsList.absPosition[2] - self.pointsListBottomClipper.absSize[2])
	self.fieldsList:setAnchors(0, 0, v151_ + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
	self.fieldsList:updateAbsolutePosition()
	self.fieldsListSlider:setAnchors(0, 0, v151_ + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
	self.fieldsListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.fieldsListSlider:setPosition(v150_)
	self.fieldsListTopClipper:setPosition(0, self.fieldsList.absPosition[2] + self.fieldsList.absSize[2])
	self.fieldsListBottomClipper:setPosition(0, self.fieldsList.absPosition[2] - self.fieldsListBottomClipper.absSize[2])
	self.aiWorkersList:setAnchors(0, 0, v151_ + 15 * g_pixelSizeY, self.aiWorkersListTitle.absPosition[2] + 20 * g_pixelSizeY)
	self.aiWorkersList:updateAbsolutePosition()
	self.aiWorkersListSlider:setAnchors(0, 0, v151_ + 15 * g_pixelSizeY, self.aiWorkersListTitle.absPosition[2] + 20 * g_pixelSizeY)
	self.aiWorkersListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
	self.aiWorkersListSlider:setPosition(v150_)
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

-- Local values: partWidth, x, y, width, height, imageUVs, clones, i, newPart, _, clone
function InGameMenuMobileMapFrame:assignGroundStatusColors(colorElement, statusColors, listElement)
	local v170_ = colorElement.absSize[1] / #statusColors
	colorElement:setSize(v170_, nil)
	local v171_ = InGameMenuMobileMapFrame.STATUS_BG_COLOR_UVS
	local v172_, v173_, v174_, v175_ = unpack(v171_)
	local v176_ = v174_ / #statusColors
	local v177_ = GuiUtils.getUVs({
		v172_,
		v173_,
		v176_,
		v175_
	}, { 2048, 2048 })
	colorElement:setImageUVs(nil, unpack(v177_))
	local v178_ = GuiOverlay.setSelectedColor
	local v179_ = colorElement.overlay
	local v180_ = statusColors[1]
	v178_(v179_, unpack(v180_))
	if #statusColors > 1 then
		local v181_ = {}
		for v182_ = 2, #statusColors do
			local v183_ = colorElement:clone()
			table.insert(v181_, v183_)
			v183_:setSize(v170_, nil)
			local v184_ = GuiUtils.getUVs({
				v172_ + v176_ * (v182_ - 1),
				v173_,
				v176_,
				v175_
			}, { 2048, 2048 })
			v183_:setImageUVs(nil, unpack(v184_))
			v183_:setPosition((v182_ - 1) * v170_, 0)
			local v185_ = GuiOverlay.setSelectedColor
			local v186_ = v183_.overlay
			local v187_ = statusColors[v182_]
			v185_(v186_, unpack(v187_))
			function v183_.getOverlayState()
				-- upvalues: (copy) listElement
				return listElement.isStatusEnabled and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
			end
		end
		for _, v188_ in ipairs(v181_) do
			colorElement:addElement(v188_)
		end
	end
end

function InGameMenuMobileMapFrame:resetUIDeadzones()
	self.inGameMap:clearCursorDeadzones()
	if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB and not self:getIsPicking() then
		self.inGameMap:addCursorDeadzone(0, 0, 1, 1)
	else
		self.inGameMap:addCursorDeadzone(0, 0, self.filterBoxContainer.absPosition[1] + self.filterBoxContainer.absSize[1], self.filterBoxContainer.absPosition[2] + self.filterBoxContainer.absSize[2])
	end
end

function InGameMenuMobileMapFrame:onOverviewOverlayFinished(overlayId)
	self.foliageStateOverlay = overlayId
	self.foliageStateOverlayIsReady = true
	self.dynamicMapImageLoadingBg:setVisible(false)
end

-- Local values: mappedFruitTypeFilters, buttonIndex, fruitIndex, mapOverlayGenerator, currentMapFilter
function InGameMenuMobileMapFrame:generateOverviewOverlay()
	if self.foliageStateOverlay == nil then
		self.foliageStateOverlayIsReady = false
	end
	self.dynamicMapImageLoadingBg:setVisible(true)
	self.dynamicMapImageLoadingBg:setSize(self.dynamicMapImageLoading.absSize[1] + 80 * g_pixelSizeX)
	local v193_ = {}
	for v194_, v195_ in pairs(self.fruitTypeFilterMapping) do
		v193_[v195_] = self.fruitTypeFilter[v194_]
	end
	local v196_ = g_currentMission.mapOverlayGenerator
	if v196_ ~= nil then
		local v197_ = self.statusSelector:getState()
		if v197_ == InGameMenuMobileMapFrame.MAP_FRUIT_TYPE then
			v196_:generateFruitTypeOverlay(self.overviewOverlayFinishedCallback, v193_)
			return
		end
		if v197_ == InGameMenuMobileMapFrame.MAP_GROWTH then
			v196_:generateGrowthStateOverlay(self.overviewOverlayFinishedCallback, self.growthStateFilter, v193_)
			return
		end
		if v197_ == InGameMenuMobileMapFrame.MAP_SOIL then
			v196_:generateSoilStateOverlay(self.overviewOverlayFinishedCallback, self.soilStateFilter)
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

-- Local values: canEnter, canReset, canSetMarker, removeMarker, canBuy, name, imageFilename, vehicle, isHorse, mapPageSelectorState, brand, horse, dailyRiding, i, attachableContainer, attachable, attachableText, attachableIcon, i, placeable, slotSystem, slotLimit, displayItem, field
function InGameMenuMobileMapFrame:setMapSelectionItem(hotspot)
	self.inGameMapBase:setSelectedHotspot(hotspot)
	self.selectedField = nil
	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	if self.currentHotspot ~= nil then
		self.currentHotspot:setBlinking(false)
	end
	local v202_ = false
	local v203_ = false
	local v204_ = false
	local v205_ = false
	local v206_ = false
	local v207_ = nil
	local v208_ = nil
	local v209_ = self.mapPageSelector.state
	if hotspot == nil then
		self.currentHotspot = nil
	else
		local v210_ = InGameMenuMapUtil.getHotspotVehicle(hotspot)
		if v210_ == nil then
			if hotspot:isa(PlaceableHotspot) then
				v207_ = hotspot:getName()
				if v207_ ~= nil then
					if v209_ ~= InGameMenuMobileMapFrame.PAGE_ID.POINTS and v209_ ~= InGameMenuMobileMapFrame.PAGE_ID.AI then
						self.blockListSelectionEvents = true
						self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.POINTS, true)
						self.blockListSelectionEvents = false
					end
					self.currentHotspot = hotspot
					self.currentList = v209_ == InGameMenuMobileMapFrame.PAGE_ID.AI and self.aiWorkersList or self.pointsList
					local v211_ = hotspot:getPlaceable()
					if v211_ ~= nil then
						local v212_ = v211_:getImageFilename()
						self.pointDetailsImage:setImageFilename(v212_)
						self.pointDetailsName:setText(v207_)
						self.aiDetailsImage:setImageFilename(v212_)
						self.aiDetailsBrand:setVisible(false)
						self.aiDetailsName:setText(v207_)
						if v211_.storeItem ~= nil then
							local v213_ = g_currentMission.slotSystem
							local v214_ = v213_.slotLimit
							v213_.slotLimit = math.huge
							local v215_ = g_shopController:makeDisplayItem(v211_.storeItem)
							self:setDetailAttributes(v211_.storeItem, v215_)
							v213_.slotLimit = v214_
						end
					end
					v205_ = g_currentMission.currentMapTargetHotspot == hotspot
					v204_ = true
				end
			elseif hotspot:isa(FieldHotspot) then
				if v209_ ~= InGameMenuMobileMapFrame.PAGE_ID.FIELDS then
					self.blockListSelectionEvents = true
					self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.FIELDS, true)
					self.blockListSelectionEvents = false
					if self.currentHotspot ~= nil then
						self.currentHotspot:setBlinking(false)
					end
				end
				self.currentHotspot = hotspot
				self.currentList = self.fieldsList
				local v216_ = hotspot:getField()
				v206_ = not v216_:getHasOwner()
				self.selectedField = v216_:getId()
			end
		else
			if v209_ ~= InGameMenuMobileMapFrame.PAGE_ID.VEHICLES and v209_ ~= InGameMenuMobileMapFrame.PAGE_ID.AI then
				self.blockListSelectionEvents = true
				self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.VEHICLES, true)
				self.blockListSelectionEvents = false
			end
			self.currentHotspot = hotspot
			self.currentList = v209_ == InGameMenuMobileMapFrame.PAGE_ID.AI and self.aiWorkersList or self.vehiclesList
			v207_ = v210_:getName()
			local v217_ = v210_:getImageFilename()
			if g_currentMission.tourIconsBase == nil or g_currentMission.tourIconsBase.visible == false then
				if v210_.getIsEnterableFromMenu == nil then
					v202_ = false
				else
					v202_ = v210_:getIsEnterableFromMenu()
				end
				if not self.isResetPending and (v210_:getCanBeReset() and hotspot:getCategory() ~= MapHotspot.CATEGORY_AI) then
					v203_ = true
				end
			end
			v208_ = v210_.spec_rideable ~= nil
			self.vehicleDetailsImage:setImageFilename(v217_)
			local v218_ = g_brandManager:getBrandByIndex(v210_:getBrand())
			self.vehicleDetailsBrand:setImageFilename(v218_.image)
			self.vehicleDetailsName:setText(v207_)
			self.vehicleDetailsBrand:setVisible(not v208_)
			self.vehicleDetailsDailyRiding:setVisible(v208_)
			if v208_ then
				local v219_ = v210_:getCluster():getRidingFactor() * 100
				local v220_ = math.floor(v219_)
				self.vehicleDetailsDailyRiding:setText(string.format("%s: %s%%", g_i18n:getText("ui_horseDailyRiding"), v220_))
			end
			self.aiDetailsImage:setImageFilename(v217_)
			self.aiDetailsBrand:setVisible(true)
			self.aiDetailsBrand:setImageFilename(v218_.image)
			self.aiDetailsName:setText(v207_)
			for v221_, v222_ in pairs(self.vehicleDetailsAttachables) do
				local v223_ = v210_.childVehicles[v221_]
				if v223_ == nil then
					v222_:setVisible(false)
				else
					v222_:getDescendantByName("text"):setText(v223_:getName())
					local v224_ = v222_:getDescendantByName("icon")
					local v225_ = v223_.mapHotspot.icon.uvs
					v224_:setImageUVs(nil, unpack(v225_))
					v222_:setVisible(true)
				end
			end
			for v226_ = #v210_.childVehicles, 3 do
				self.vehicleDetailsAttachables[v226_]:setVisible(false)
			end
		end
	end
	if self.currentHotspot ~= nil then
		self.currentHotspot:setBlinking(true)
	end
	if v208_ then
		self.buttonEnterVehicle:setText(string.format(g_i18n:getText("action_rideAnimal"), v207_))
		self.buttonEnterVehicle.touchIcon.uvs = GuiUtils.getUVs(InGameMenuMobileMapFrame.UV.BUTTON_RIDE_HORSE)
	else
		self.buttonEnterVehicle:setText(g_i18n:getText("button_enterVehicle"))
		self.buttonEnterVehicle.touchIcon.uvs = GuiUtils.getUVs(InGameMenuMobileMapFrame.UV.BUTTON_ENTER_VEHICLE)
	end
	self.buttonEnterVehicle:setTextSize(self.buttonsResizeTextSize)
	self:refreshContextInput()
	self:showContextInput(v202_, v203_, v204_, v205_, v206_)
	self.canEnter = v202_
	self.canReset = v203_
	self.canSetMarker = v204_
	self.removeMarker = v205_
	self.canBuy = v206_
end

-- Local values: detailsBox, showList
function InGameMenuMobileMapFrame:showDetailsBox(showBox)
	local v229_ = self.currentList.detailsBox
	if not showBox then
		if self.currentList == self.aiWorkersList then
			showBox = self.currentHotspot ~= nil
		else
			showBox = false
		end
	end
	if v229_ ~= nil then
		v229_:setVisible(showBox)
	end
	local v230_ = not showBox or (v229_ == nil and true or self.currentList == self.aiWorkersList)
	self.currentList:setVisible(v230_)
	self.currentList:updateScrollClippers()
	if self.currentList.sliderElement ~= nil and (self.currentList.sliderElement.needsSlider and self.currentList.totalItemCount > 0) then
		self.currentList.sliderElement.parent:setVisible(v230_)
	end
	if self.currentList == self.pointsList then
		self.pointsFilterButtonBox:setVisible(v230_)
	end
end

-- Local values: needBg
function InGameMenuMobileMapFrame:showActionMessage(text, locaKey)
	local v234_ = false
	if text == nil then
		if locaKey == nil then
			self.actionMessageBg:setVisible(false)
		else
			self.actionMessage:setVisible(true)
			self.actionMessage:setLocaKey(locaKey)
			v234_ = true
		end
	else
		self.actionMessage:setVisible(true)
		self.actionMessage:setText(text)
		v234_ = true
	end
	if v234_ then
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

-- Local values: i, farmId, _, group, _, item, element, parameterType
function InGameMenuMobileMapFrame:setActiveJobTypeSelection(jobTypeIndex)
	if self.currentJob == nil or jobTypeIndex ~= self.currentJob.jobTypeIndex then
		for v239_ = #self.aiTaskDialogLayout.elements, 2, -1 do
			self.aiTaskDialogLayout.elements[v239_]:delete()
		end
		self.currentJob = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
		local v240_ = g_localPlayer == nil and 1 or g_localPlayer.farmId
		self.currentJob:applyCurrentState(self.currentJobVehicle, g_currentMission, v240_, false)
		self.currentJobElements = {}
		for _, v241_ in ipairs(self.currentJob:getGroupedParameters()) do
			for _, v242_ in ipairs(v241_:getParameters()) do
				local v243_ = nil
				local v244_ = v242_:getType()
				if v244_ == AIParameterType.TEXT then
					break
				end
				if v244_ == AIParameterType.POSITION then
					v243_ = self.aiTaskDialogPositionTemplate:clone(self.aiTaskDialogLayout)
					v243_:getDescendantByName("title"):setText(v241_:getTitle())
					v243_:getDescendantByName("button").aiParameter = v242_
				elseif v244_ == AIParameterType.POSITION_ANGLE then
					v243_ = self.aiTaskDialogPositionRotationTemplate:clone(self.aiTaskDialogLayout)
					v243_:getDescendantByName("title"):setText(v241_:getTitle())
					v243_:getDescendantByName("button").aiParameter = v242_
				elseif v244_ == AIParameterType.SELECTOR or (v244_ == AIParameterType.UNLOADING_STATION or (v244_ == AIParameterType.LOADING_STATION or v244_ == AIParameterType.FILLTYPE)) then
					v243_ = self.aiTaskDialogMultiOptionTemplate:clone(self.aiTaskDialogLayout)
					v243_:setDataSource(v242_)
					v243_:setLabel(v241_:getTitle())
				end
				v243_.aiParameter = v242_
				v243_:setDisabled(not v242_:getCanBeChanged())
				local v245_ = self.currentJobElements
				table.insert(v245_, v243_)
			end
		end
		self:updateParameterValueTexts()
		self:validateParameters()
		self.aiTaskDialogLayout:invalidateLayout()
	end
	self:refreshContextInput()
end

-- Local values: _, vehicle, item, name, brand, section, item, sortFunction, i
function InGameMenuMobileMapFrame:updateVehicles()
	self.vehicles = {
		{},
		{}
	}
	if g_localPlayer ~= nil then
		for _, v247_ in ipairs(g_currentMission.vehicleSystem.vehicles) do
			if g_currentMission.accessHandler:canPlayerAccess(v247_) then
				if v247_:getShowInVehiclesOverview() then
					local v248_ = {
						["vehicle"] = v247_
					}
					local v249_ = v247_:getName()
					local v250_ = g_brandManager:getBrandByIndex(v247_:getBrand())
					if v250_ ~= nil then
						v249_ = v250_.title .. " " .. v249_
					end
					v248_.name = v249_
					local v251_ = SpecializationUtil.hasSpecialization(Drivable, v247_.specializations) and 1 or 2
					if self.vehicles[v251_] == nil then
						self.vehicles[v251_] = {}
					end
					local v252_ = self.vehicles[v251_]
					table.insert(v252_, v248_)
				elseif SpecializationUtil.hasSpecialization(Rideable, v247_.specializations) then
					local v253_ = {
						["vehicle"] = v247_,
						["name"] = v247_:getName()
					}
					if self.vehicles[3] == nil then
						self.vehicles[3] = {}
					end
					local v254_ = self.vehicles[3]
					table.insert(v254_, v253_)
				end
			end
		end
	end
	local function v257_(p255_, p256_)
		if p255_ == nil then
			return true
		elseif p256_ == nil then
			return false
		else
			return p255_.name < p256_.name
		end
	end
	for v258_ = 1, #self.vehicles do
		table.sort(self.vehicles[v258_], v257_)
	end
end

-- Local values: sectionFunction, hotspots, section, _, hotspot, sortFunction, i
function InGameMenuMobileMapFrame:updatePoints()
	self.hotspotsSorted = {}
	local v260_ = self.inGameMap.ingameMap.hotspots
	local function v262_(p261_)
		if p261_ == nil or p261_.placeable == nil then
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER
		elseif SpecializationUtil.hasSpecialization(PlaceableProductionPoint, p261_.placeable.specializations) then
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS
		elseif SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, p261_.placeable.specializations) then
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS
		elseif SpecializationUtil.hasSpecialization(PlaceableSellingStation, p261_.placeable.specializations) or SpecializationUtil.hasSpecialization(PlaceableBuyingStation, p261_.placeable.specializations) then
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING
		else
			return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER
		end
	end
	for _, v263_ in pairs(v260_) do
		if v263_:isa(PlaceableHotspot) then
			local v264_ = v262_(v263_)
			if self.hotspotsSorted[v264_] == nil then
				self.hotspotsSorted[v264_] = {}
			end
			local v265_ = self.hotspotsSorted[v264_]
			table.insert(v265_, v263_)
		end
	end
	local function v268_(p266_, p267_)
		if p266_ == nil then
			return true
		elseif p267_ == nil then
			return false
		else
			return p266_:getName() < p267_:getName()
		end
	end
	for v269_ = 1, #self.hotspotsSorted do
		table.sort(self.hotspotsSorted[v269_], v268_)
	end
	self:updatePointsFilterMapping()
end

-- Local values: numActive, i, isActive
function InGameMenuMobileMapFrame:updatePointsFilterMapping()
	self.hotspotFiltersMapping = {}
	local v271_ = 1
	for v272_, v273_ in pairs(self.hotspotFiltersActive) do
		if v273_ then
			self.hotspotFiltersMapping[v271_] = v272_
			v271_ = v271_ + 1
		end
	end
	if v271_ == 1 then
		self.pointsListSlider:setVisible(false)
		self:setMapSelectionItem(nil)
	else
		self.pointsListSlider:setVisible(self.pointsList.visible)
	end
	self.pointsList:reloadData()
end

-- Local values: _, field, farmland, section, sortFunction, i
function InGameMenuMobileMapFrame:updateFields()
	self.fields = {}
	for _, v275_ in pairs(g_fieldManager:getFields()) do
		local v276_ = v275_.farmland
		local v277_ = g_farmlandManager:getFarmlandOwner(v276_.id) == g_currentMission:getFarmId() and 1 or 2
		if self.fields[v277_] == nil then
			self.fields[v277_] = {}
		end
		local v278_ = self.fields[v277_]
		table.insert(v278_, v275_)
	end
	local function v281_(p279_, p280_)
		return p279_:getId() < p280_:getId()
	end
	for v282_ = 1, #self.fields do
		table.sort(self.fields[v282_], v281_)
	end
end

-- Local values: _, jobType
function InGameMenuMobileMapFrame:generateJobTypes()
	for _, v284_ in pairs(AIJobType) do
		self.jobTypeInstances[v284_] = g_currentMission.aiJobTypeManager:createJob(v284_)
	end
end

-- Local values: job, success, errorMessage, callback
function InGameMenuMobileMapFrame:startGoToJob(vehicle, destX, destZ, angle)
	local v290_ = self.jobTypeInstances[AIJobType.GOTO]
	v290_.vehicleParameter:setVehicle(vehicle)
	v290_.positionAngleParameter:setPosition(destX, destZ)
	v290_.positionAngleParameter:setAngle(angle)
	v290_:setValues()
	local v291_, v292_ = v290_:validate(g_localPlayer.farmId)
	if not v291_ then
		InfoDialog.show(tostring(v292_), nil, nil, DialogElement.TYPE_WARNING)
		return false
	end
	FocusManager:setFocus(self.aiWorkersList)
	self:tryStartJob(v290_, g_localPlayer.farmId, function(p293_)
		-- upvalues: (copy) self
		if p293_ == AIJob.START_SUCCESS then
			self.jobTypeInstances[AIJobType.GOTO] = g_currentMission.aiJobTypeManager:createJob(AIJobType.GOTO)
		end
	end)
	return true
end

function InGameMenuMobileMapFrame:getIsPicking()
	return self.isPickingRotation or self.isPickingLocation
end
function InGameMenuMobileMapFrame.executePickingCallback(p295_, ...)
	p295_.inGameMap:setHotspotSelectionActive(true)
	p295_.isPickingLocation = false
	p295_.isPickingRotation = false
	p295_.inGameMap:unlockMapMovement()
	p295_:resetUIDeadzones()
	local v296_ = p295_.pickingCallback
	p295_.pickingCallback = nil
	if v296_ ~= nil then
		v296_(...)
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
	function self.pickingCallback(p300_, p301_, p302_)
		-- upvalues: (copy) self, (copy) parameter, (copy) callback
		self:showActionMessage()
		self.inGameMap:setIsCursorAvailable(true)
		self.hasPickedRotationTouch = false
		if p300_ then
			parameter:setValue(p301_, p302_)
			self.aiTargetMapHotspot:setWorldPosition(p301_, p302_)
		end
		callback(p300_, p301_, p302_, parameter)
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
	function self.pickingCallback(p306_, p_u_307_, p_u_308_)
		-- upvalues: (copy) self, (copy) parameter, (copy) callback
		self:showActionMessage()
		self.inGameMap:setIsCursorAvailable(true)
		self.hasPickedRotationTouch = false
		if p306_ then
			self.inGameMap:setHotspotSelectionActive(false)
			self.inGameMap:setIsCursorAvailable(false)
			self.aiTargetMapHotspot:setWorldPosition(p_u_307_, p_u_308_)
			self.isPickingRotation = true
			self.inGameMap:lockMapMovement()
			self.pickingRotationOrigin = { p_u_307_, p_u_308_ }
			self.pickingRotationSnapAngle = parameter:getSnappingAngle()
			self:showActionMessage(nil, "ui_ai_pickTargetRotation")
			self:resetUIDeadzones()
			function self.pickingCallback(p309_, p310_)
				-- upvalues: (ref) self, (ref) parameter, (copy) p_u_307_, (copy) p_u_308_, (ref) callback
				self:showActionMessage()
				self.inGameMap:setIsCursorAvailable(true)
				if p309_ then
					parameter:setPosition(p_u_307_, p_u_308_)
					parameter:setAngle(p310_)
					local v311_ = parameter:getAngle()
					if self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_TOUCH then
						self.aiTargetMapHotspot:setWorldRotation(v311_ + 3.141592653589793)
					end
					callback(true, p_u_307_, p_u_308_, p310_)
				else
					callback(false, p_u_307_, p_u_308_, nil)
				end
				self:validateParameters()
			end
		else
			callback(false, nil, nil, nil)
		end
		self:validateParameters()
	end
end

-- Local values: previousHotspot
function InGameMenuMobileMapFrame:onClickHotspot(element, hotspot)
	if self.mode ~= InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		local v314_ = self.currentHotspot
		self:setMapSelectionItem(hotspot)
		self:showDetailsBox(true)
		if InGameMenuMobileMapFrame.MODE_OVERVIEW or self.mode == InGameMenuMobileMapFrame.MODE_NONE and v314_ ~= hotspot then
			self:selectHotspotInList(hotspot, self.currentList)
		end
		self:resizeButtonTexts()
	end
end

-- Local values: localX, localY, angle
function InGameMenuMobileMapFrame:onClickMap(element, worldX, worldZ)
	if (self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW or self.mode == InGameMenuMobileMapFrame.MODE_NONE) and self.currentList.totalItemCount > 0 then
		self:showDetailsBox(false)
		FocusManager:setFocus(self.currentList)
	elseif self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE or self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		if self.isPickingLocation then
			if self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH then
				local v318_, v319_ = self.inGameMap:getLocalPosition(self.lastTouchPosX, self.lastTouchPosY)
				self:setTargetPointHotspotPosition(v318_, v319_)
			elseif not self.hasPickedLocationTouch then
				self:executePickingCallback(true, worldX, worldZ)
			end
		elseif self.isPickingRotation then
			local v320_ = worldX - self.pickingRotationOrigin[1]
			local v321_ = worldZ - self.pickingRotationOrigin[2]
			local v322_ = math.atan2(v320_, v321_)
			if self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH then
				self.aiTargetMapHotspot:setWorldRotation(v322_ + 3.141592653589793)
				self.hasPickedRotationTouch = true
			else
				self.inGameMap:panToHotspot(self.aiTargetMapHotspot)
				self:executePickingCallback(true, v322_)
			end
		end
		self:refreshContextInput()
	end
end

-- Local values: sectionIndex, index, listSelectionBlocked
function InGameMenuMobileMapFrame:selectHotspotInList(hotspot, hotspotList)
	local v326_, v327_ = self:findListItemForHotspot(hotspot, hotspotList)
	local v328_ = self.blockListSelectionEvents
	self.blockListSelectionEvents = true
	hotspotList:setSelectedItem(v326_, v327_)
	self.blockListSelectionEvents = v328_
end

-- Local values: list, sectionIndex, section, index, vehicle, listHotspot, field
function InGameMenuMobileMapFrame:findListItemForHotspot(hotspot, hotspotList)
	local v332_ = self.vehicles
	if hotspotList == self.pointsList then
		v332_ = self.hotspotsSorted
	elseif hotspotList == self.fieldsList then
		v332_ = self.fields
	end
	for v333_, v334_ in pairs(v332_) do
		for v335_ = 1, #v334_ do
			if hotspotList == self.vehiclesList then
				local v336_ = self.vehicles[v333_][v335_].vehicle
				if hotspot ~= nil and v336_ == hotspot.vehicle then
					return v333_, v335_
				end
			elseif hotspotList == self.pointsList then
				if hotspot == self.hotspotsSorted[self.hotspotFiltersMapping[v333_]][v335_] then
					return v333_, v335_
				end
			elseif hotspotList == self.fieldsList then
				local v337_ = self.fields[v333_][v335_]
				if hotspot ~= nil and hotspot.field == v337_ then
					return v333_, v335_
				end
			end
		end
	end
	return nil, nil
end

-- Local values: totalButtonWidth, _, button, _, button, _, button
function InGameMenuMobileMapFrame:resizeButtonTexts()
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		local v339_ = 0
		if self.buttonEnterVehicle.visible then
			v339_ = self.buttonSelectInGame.absSize[1] + self.buttonEnterVehicle.absSize[1] + self.buttonResetVehicle.absSize[1] + self.buttonBox.elementSpacing * 2
		elseif self.buttonGoToJob.visible then
			v339_ = self.buttonSelectInGame.absSize[1] + self.buttonGoToJob.absSize[1] + self.buttonCreateJob.absSize[1] + self.buttonBox.elementSpacing * 2
		else
			for _, v340_ in pairs(self.buttonsResizeNeeded) do
				v340_:setTextSize(v340_.defaultTextSize)
			end
			self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
		end
		while self.buttonBox.absSize[1] <= v339_ do
			for _, v341_ in pairs(self.buttonsResizeNeeded) do
				v341_:setTextSize(v341_.textSize - 1 * g_pixelSizeY)
			end
			self.buttonsResizeTextSize = self.buttonSelectInGame.textSize
			if self.buttonEnterVehicle.visible then
				v339_ = self.buttonSelectInGame.absSize[1] + self.buttonEnterVehicle.absSize[1] + self.buttonResetVehicle.absSize[1] + self.buttonBox.elementSpacing * 2
			elseif self.buttonGoToJob.visible then
				v339_ = self.buttonSelectInGame.absSize[1] + self.buttonGoToJob.absSize[1] + self.buttonCreateJob.absSize[1] + self.buttonBox.elementSpacing * 2
			end
		end
	else
		for _, v342_ in pairs(self.buttonsResizeNeeded) do
			v342_:setTextSize(v342_.defaultTextSize)
		end
		self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
	end
end

-- Local values: requiredProfile
function InGameMenuMobileMapFrame:onMoneyChanged(farmId, newBalance)
	if farmId == self.playerFarm.farmId and self.balanceText ~= nil then
		self.balanceText:setValue(newBalance)
		local v346_ = InGameMenuMobileMapFrame.PROFILE.MONEY_VALUE_NEUTRAL
		if math.floor(newBalance) <= -1 then
			v346_ = InGameMenuMobileMapFrame.PROFILE.MONEY_VALUE_NEGATIVE
		end
		self.balanceText:applyProfile(v346_)
		self.balanceText.parent:invalidateLayout()
	end
end

-- Local values: inGameMap, hotspots, aiHotspot, _, hotspot, vehicle, vehicleJob
function InGameMenuMobileMapFrame:onAIJobStarted(job, farmId)
	self.blockListSelectionEvents = true
	self.aiWorkersList:reloadData()
	FocusManager:setFocus(self.aiWorkersList)
	self.blockListSelectionEvents = false
	local v349_ = g_currentMission.hud:getIngameMap().hotspots
	local v350_ = nil
	for _, v351_ in pairs(v349_) do
		local v352_ = InGameMenuMapUtil.getHotspotVehicle(v351_)
		if v352_ ~= nil and v352_.getJob ~= nil then
			local v353_ = v352_:getJob()
			if v353_ ~= nil and (v351_:isa(AIHotspot) and job.jobId == v353_.jobId) then
				v350_ = v351_
			end
		end
	end
	self:setMapSelectionItem(v350_)
	InfoDialog.show(g_i18n:getText("ai_startStateSuccess"))
end

function InGameMenuMobileMapFrame:onAIJobRemoved(jobId)
	self.aiWorkersList:reloadData()
end

function InGameMenuMobileMapFrame:onAITaskSkipped()
	self:refreshContextInput()
end

-- Local values: text
function InGameMenuMobileMapFrame:onAIJobStopped(job, aiMessage)
	if aiMessage ~= nil and (job ~= nil and (g_localPlayer ~= nil and job.startedFarmId == g_localPlayer.farmId)) then
		self:addStatusMessage((aiMessage:getMessage(job)))
	end
end

function InGameMenuMobileMapFrame:onInsetsChanged()
	self:updateElementSizes()
end

-- Local values: width, height, x, y, filterBoxWidth, pixFilterBoxWidth, pixX, pixWidth, pixHeight, deltaX, u1, v1, u2, v2, u3, v3, u4, v4
function InGameMenuMobileMapFrame:onDrawPostIngameMap()
	if self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW and self.foliageStateOverlayIsReady then
		local v361_, v362_ = self.inGameMapBase.fullScreenLayout:getMapSize()
		local v363_, v364_ = self.inGameMapBase.fullScreenLayout:getMapPosition()
		local v365_ = self.filterBoxContainer.absSize[1] + self.leftInset
		local v366_ = v365_ * g_screenWidth
		local v367_ = v363_ * g_screenWidth
		local v368_ = v361_ * g_screenWidth
		local v369_ = v362_ * g_screenHeight
		local v370_ = v366_ - v367_
		local v371_ = GuiUtils.getUVs
		local v372_ = {
			v370_,
			0,
			v368_ + v370_,
			v369_
		}
		local v373_, v374_, v375_, v376_, v377_, v378_, v379_, v380_ = unpack(v371_(v372_, { v368_, v369_ }))
		setOverlayUVs(self.foliageStateOverlay, v373_, v374_, v375_, v376_, v377_, v378_, v379_, v380_)
		renderOverlay(self.foliageStateOverlay, v365_, v364_, v361_ + v365_ - v363_, v362_)
	end
end

-- Local values: isValid, errorText
function InGameMenuMobileMapFrame:validateParameters()
	local v382_, v383_
	if self.currentJob == nil then
		v382_ = ""
		v383_ = true
	else
		self.currentJob:setValues()
		v383_, v382_ = self.currentJob:validate(g_localPlayer.farmId)
		self:updateWarnings()
	end
	self.aiTaskDialogErrorMessage:setText(v382_)
	self.aiTaskDialogErrorMessageBg:setSize(self.aiTaskDialogErrorMessage.absSize[1] + 80 * g_pixelSizeX)
	self.aiTaskDialogErrorMessageBg:setVisible(not v383_)
end

-- Local values: _, element, param, invalidElement
function InGameMenuMobileMapFrame:updateWarnings()
	for _, v385_ in ipairs(self.currentJobElements) do
		local v386_ = v385_.aiParameter
		local v387_ = v385_:getDescendantByName("invalid")
		if v387_ ~= nil then
			v387_:setVisible(not v386_:getIsValid())
		end
	end
end

function InGameMenuMobileMapFrame:addStatusMessage(message)
	local v390_ = self.statusMessages
	local v391_ = {
		["removeTime"] = g_time + 5000,
		["text"] = message
	}
	table.insert(v390_, v391_)
	self:updateStatusMessages()
end

-- Local values: text, _, message, textSize, width, height
function InGameMenuMobileMapFrame:updateStatusMessages()
	local v393_ = ""
	for _, v394_ in ipairs(self.statusMessages) do
		v393_ = v393_ .. v394_.text .. "\n"
	end
	self.statusMessage:setText(v393_)
	self.statusMessageBg:setVisible(getTextLength(self.statusMessage.textSize, v393_, 99999) > 0)
	setTextBold(true)
	local v395_ = self.statusMessage.textSize
	local v396_ = getTextWidth(v395_, self.statusMessage.text) + 20 * g_pixelSizeX
	local v397_ = getTextHeight(v395_, self.statusMessage.text) + 14 * g_pixelSizeX
	setTextBold(false)
	self.statusMessageBg:setSize(v396_, v397_)
	self.statusMessageBg:setPosition(nil, self.statusMessage.absPosition[2] + v395_ * 0.5 - v397_ * 0.5)
end

-- Local values: parentBox, totalWidth, maxWidth, i, icon, parentSize
function InGameMenuMobileMapFrame:assignItemFillTypesData(baseIconProfile, iconFilenames, detailsIndex)
	local v402_ = self.pointDetailsIconsLayout[detailsIndex]
	if #self.pointDetailsValue < detailsIndex or #iconFilenames == 0 then
		v402_.parent:setVisible(false)
		return detailsIndex
	end
	local v403_ = self.pointDetailsLayout.absSize[1] * 0.75
	self.pointDetailsIcon[detailsIndex]:applyProfile(baseIconProfile)
	self.pointDetailsIcon[detailsIndex]:setVisible(true)
	v402_.parent:setVisible(true)
	self.pointDetailsValue[detailsIndex]:setVisible(false)
	local v404_ = 0
	for v405_ = 1, #iconFilenames do
		local v406_ = self.pointDetailsIconTemplate:clone(v402_)
		v406_:setVisible(true)
		local v407_ = self.clonedElements
		table.insert(v407_, v406_)
		v404_ = v404_ + v406_.absSize[1] + v406_.margin[1] + v406_.margin[3]
		v406_:applyProfile("inGameMenuMobileMapDetailsIconTemplate")
		v406_:setImageFilename(iconFilenames[v405_])
	end
	local v408_ = math.min(v403_, v404_)
	v402_.parent:setSize(v408_, nil)
	v402_:setPosition(0)
	v402_:setSize(v404_, nil)
	v402_:invalidateLayout()
	if v408_ < v404_ then
		self.marqueeBoxes[v402_] = 0
	else
		self.marqueeBoxes[v402_] = nil
	end
	return detailsIndex + 1
end

-- Local values: numDetailsUsed, i, detailsVisible, value, profile
function InGameMenuMobileMapFrame:assignItemTextData(storeItem, displayItem)
	local v411_ = 0
	for v412_ = 1, #self.pointDetailsValue do
		local v413_ = false
		if displayItem ~= nil and v412_ <= #displayItem.attributeValues then
			local v414_ = displayItem.attributeValues[v412_]
			local v415_ = tostring(v414_)
			local v416_ = displayItem.attributeIconProfiles[v412_]
			if v416_ ~= nil and v416_ ~= "" then
				self.pointDetailsValue[v412_]:setText(v415_)
				self.pointDetailsValue[v412_]:updateAbsolutePosition()
				if v416_:startsWith("shopListAttributeIcon") then
					v416_ = "inGameMenuMobileMapDetailsIcon" .. v416_:sub(22)
				end
				self.pointDetailsIcon[v412_]:applyProfile(v416_)
				if v415_ == nil then
					v413_ = false
				else
					v413_ = v415_ ~= ""
				end
			end
		end
		self.pointDetailsValue[v412_]:setVisible(v413_)
		self.pointDetailsIcon[v412_]:setVisible(v413_)
		self.pointDetailsIconsLayout[v412_].parent:setVisible(false)
		if v413_ then
			v411_ = v411_ + 1
		end
	end
	return v411_
end

-- Local values: k, clone, k, _, numDetailsUsed, nextDetailsIndex
function InGameMenuMobileMapFrame:setDetailAttributes(storeItem, displayItem)
	for v420_, v421_ in pairs(self.clonedElements) do
		v421_:delete()
		self.clonedElements[v420_] = nil
	end
	for v422_, _ in pairs(self.marqueeBoxes) do
		self.marqueeBoxes[v422_] = nil
	end
	local v423_ = self:assignItemTextData(storeItem, displayItem)
	if displayItem ~= nil then
		local v424_ = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconFillTypes", displayItem.fillTypeIconFilenames, v423_ + 1)
		local v425_ = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconFillTypes", displayItem.foodFillTypeIconFilenames, v424_)
		local v426_ = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconInput", displayItem.prodPointInputFillTypeIconFilenames, v425_)
		local v427_ = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconOutput", displayItem.prodPointOutputFillTypeIconFilenames, v426_)
		local v428_ = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconInput", displayItem.sellingStationFillTypesIconFilenames, v427_)
		self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconOutput", displayItem.buyingStationFillTypesIconFilenames, v428_)
	end
	self.pointDetailsLayout:invalidateLayout()
end

-- Local values: box, boxTime, contentWidth, visibleWidth, scrollAmount, scrollLengthFactor, scrollDuration, alpha, offset
function InGameMenuMobileMapFrame:updateMarqueeAnimation(dt)
	for v431_, v432_ in pairs(self.marqueeBoxes) do
		local v433_ = v431_.absSize[1]
		local v434_ = v431_.parent.absSize[1]
		local v435_ = v433_ - v434_
		local v436_ = 9000 * ((v435_ / v434_ - 1) * 0.5 + 1)
		local v437_ = v432_ + dt
		if v436_ <= v437_ then
			v437_ = -v436_
		end
		v431_:setPosition(-(v435_ * MathUtil.smoothstep(0.2, 0.8, math.abs(v437_) / v436_)))
		self.marqueeBoxes[v431_] = v437_
	end
end

function InGameMenuMobileMapFrame:onSlotUsageChanged()
	self:refreshDetails()
end

-- Local values: count, _, job
function InGameMenuMobileMapFrame:getNumberOfItemsInSection(list, section)
	if list == self.vehiclesList then
		return #self.vehicles[section]
	end
	if list == self.pointsList then
		return #self.hotspotsSorted[self.hotspotFiltersMapping[section]]
	end
	if list == self.statusList then
		return #self.fieldStatus[self.statusSelector.state]
	end
	if list == self.fieldsList then
		return self.fields[section] ~= nil and #self.fields[section] or 0
	end
	if list ~= self.aiWorkersList then
		return 0
	end
	local v442_ = 0
	for _, _ in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
		v442_ = v442_ + 1
	end
	return v442_
end

-- Local values: glyph, item, vehicle, icon, hotspot, icon, field, icon, count, currentJob, _, job
function InGameMenuMobileMapFrame:populateCellForItemInSection(list, section, index, cell)
	local v448_ = cell:getAttribute("glyph")
	if v448_ ~= nil then
		function v448_.glyphElement.overlay.getIsVisible()
			-- upvalues: (copy) self, (copy) cell, (copy) list
			local v449_ = self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and cell:getIsSelected()
			if v449_ then
				v449_ = FocusManager:getFocusedElement() == list
			end
			return v449_
		end
	end
	if list == self.vehiclesList then
		local v450_ = self.vehicles[section][index]
		local v451_ = v450_.vehicle
		local v452_ = cell:getAttribute("icon")
		local v453_ = v451_.mapHotspot.icon.uvs
		v452_:setImageUVs(nil, unpack(v453_))
		cell:getAttribute("text"):setText(v450_.name)
		return
	end
	if list == self.pointsList then
		local v454_ = self.hotspotsSorted[self.hotspotFiltersMapping[section]][index]
		cell:getAttribute("text"):setText(v454_:getName())
		local v455_ = cell:getAttribute("icon")
		local v456_ = v454_.icon.uvs
		v455_:setImageUVs(nil, unpack(v456_))
		return
	end
	if list == self.statusList then
		self:populateStatusCellForItemInSection(list, section, index, cell)
		return
	end
	if list == self.fieldsList then
		local v457_ = self.fields[section][index]
		cell:getAttribute("text"):setText(g_i18n:getText("ui_fieldNo") .. " " .. v457_:getId())
		cell:getAttribute("size"):setText(g_i18n:formatArea(v457_:getAreaHa(), 2))
		local v458_ = cell:getAttribute("icon")
		if section == 1 then
			v458_:applyProfile("inGameMenuMobileMapFieldsListIconOwned")
			cell:getAttribute("cost"):setText("")
		else
			v458_:applyProfile("inGameMenuMobileMapFieldsListIcon")
			cell:getAttribute("cost"):setText(g_i18n:formatMoney(v457_.farmland.price, 0, true, true))
		end
	end
	if list == self.aiWorkersList then
		local v459_ = 0
		local v460_ = nil
		for _, v461_ in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
			if v461_.startedFarmId == self.playerFarm.farmId then
				v459_ = v459_ + 1
				if v459_ == index then
					v460_ = v461_
					break
				end
			end
		end
		if v460_ ~= nil then
			cell:getAttribute("text"):setText(v460_:getDescription())
			cell:getAttribute("title"):setText(v460_:getTitle())
			cell:getAttribute("helper"):setText(v460_:getHelperName())
		end
	end
end

-- Local values: statusSelectorState, status, statusColors, iconBg, i, getIsSelectedFunc, i, icon
function InGameMenuMobileMapFrame:populateStatusCellForItemInSection(list, section, index, cell)
	if self.fieldStatusFilters[section][index] == nil then
		self.fieldStatusFilters[section][index] = true
	end
	local v466_ = self.statusSelector.state
	local v467_ = self.fieldStatus[v466_][index]
	cell:getAttribute("text"):setText(v467_.description)
	cell:getAttribute("text").getIsSelected = function()
		-- upvalues: (copy) self, (copy) index
		return self.fieldStatusFilters[self.statusSelector.state][index]
	end
	local v468_ = v467_.colors[self.isColorBlindMode]
	local v469_ = cell:getAttribute("iconBg")
	for v470_ = #v469_.elements, 1, -1 do
		v469_.elements[v470_]:delete()
	end
	v469_:applyProfile(InGameMenuMobileMapFrame.STATUS_BG_COLOR_PROFILE)
	if v466_ == 1 then
		GuiOverlay.setSelectedColor(v469_.overlay, unpack(v468_))
	else
		self:assignGroundStatusColors(v469_, v468_, cell)
	end
	local function v471_()
		-- upvalues: (copy) self, (copy) index
		return self.fieldStatusFilters[self.statusSelector.state][index] and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
	end
	v469_.getOverlayState = v471_
	for v472_ = #v469_.elements, 1, -1 do
		v469_.elements[v472_].getOverlayState = v471_
	end
	local v473_ = cell:getAttribute("icon")
	if v466_ == 1 then
		v473_:setVisible(true)
		v473_:setImageFilename(v467_.iconFilename)
		v473_.getOverlayState = v471_
	else
		v473_:setVisible(false)
	end
end

-- Local values: job, vehicle, hotspot, hotspot, vehicle
function InGameMenuMobileMapFrame:onListSelectionChanged(list, section, index)
	if not (self.isOpening or self.blockListSelectionEvents) then
		if list == self.aiWorkersList then
			local v478_ = g_currentMission.aiSystem:getJobByIndex(index)
			if v478_ ~= nil and v478_.vehicleParameter then
				local v479_ = v478_.vehicleParameter:getVehicle()
				if v479_ ~= nil then
					local v480_ = v479_:getMapHotspot()
					if self.blockPanToHotspot then
						self.blockPanToHotspot = false
					else
						self.inGameMap:panToHotspot(v480_)
					end
					self:setMapSelectionItem(v480_)
					return
				end
			end
		elseif list ~= self.statusList then
			local v481_ = nil
			if list == self.vehiclesList then
				v481_ = self.vehicles[section][index].vehicle:getMapHotspot()
			elseif list == self.pointsList then
				v481_ = self.hotspotsSorted[self.hotspotFiltersMapping[section]][index]
			else
				local _ = list == self.fieldsList
			end
			self.currentList = list
			self.currentListItemSectionIndex = list.selectedSectionIndex
			self.currentListItemIndex = list.selectedIndex
			if self.blockPanToHotspot then
				self.blockPanToHotspot = false
			else
				self.inGameMap:panToHotspot(v481_)
			end
			self:setMapSelectionItem(v481_)
		end
	end
end

function InGameMenuMobileMapFrame:getNumberOfSections(list)
	return list == self.vehiclesList and #self.vehicles or (list == self.pointsList and #self.hotspotFiltersMapping or (list == self.fieldsList and #self.fields or 1))
end

-- Local values: sectionTitle, balance
function InGameMenuMobileMapFrame:getTitleForSectionHeader(list, section)
	if list == self.vehiclesList then
		return g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.VEHICLES[section])
	end
	if list == self.pointsList then
		return g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.POINTS[self.hotspotFiltersMapping[section]])
	end
	if list ~= self.fieldsList then
		return ""
	end
	local v487_ = g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.FIELDS[section])
	if section == 2 then
		v487_ = v487_ .. "\n" .. g_i18n:getText("ui_balance") .. ": " .. g_i18n:formatMoney(self.playerFarm:getBalance(), 0, true, true)
	end
	return v487_
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

-- Local values: statusFilter
function InGameMenuMobileMapFrame:onClickStatusListItem(element)
	local v492_ = self.fieldStatusFilters[self.statusSelector.state]
	if not element.parent.wasScrolling then
		local v493_ = element.indexInSection
		local v494_
		if v492_[element.indexInSection] == nil then
			v494_ = false
		else
			v494_ = not v492_[element.indexInSection]
		end
		v492_[v493_] = v494_
	end
	self:generateOverviewOverlay()
	self:saveFilters()
end

-- Local values: jobTypeIndex
function InGameMenuMobileMapFrame:onJobTypeChanged(index)
	self:setActiveJobTypeSelection(self.currentJobTypes[index])
end

-- Local values: addedPositionHotspot, _, element, parameter, parameterType, title, x, z, angle
function InGameMenuMobileMapFrame:updateParameterValueTexts()
	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	for _, v498_ in ipairs(self.currentJobElements) do
		local v499_ = v498_.aiParameter
		local v500_ = v499_:getType()
		if v500_ == AIParameterType.TEXT then
			v498_:getDescendantByName("title"):setText(v499_:getString())
		elseif v500_ == AIParameterType.POSITION or v500_ == AIParameterType.POSITION_ANGLE then
			v498_:getDescendantByName("text"):setText(v499_:getString())
			g_currentMission:addMapHotspot(self.aiTargetMapHotspot)
			local v501_, v502_ = v499_:getPosition()
			self.aiTargetMapHotspot:setWorldPosition(v501_, v502_)
			if v500_ == AIParameterType.POSITION_ANGLE then
				local v503_ = v499_:getAngle() + 3.141592653589793
				self.aiTargetMapHotspot:setWorldRotation(v503_)
			end
		else
			v498_:updateTitle()
		end
	end
end

-- Local values: parameter
function InGameMenuMobileMapFrame:onClickMultiTextOptionParameter(index, element)
	if self.currentJob ~= nil then
		local v506_ = element.aiParameter
		self.currentJob:onParameterValueChanged(v506_)
		self:updateParameterValueTexts()
	end
	self:validateParameters()
end

-- Local values: parameter
function InGameMenuMobileMapFrame:onClickPositionParameter(element)
	local v_u_509_ = element.aiParameter
	self:startPickPosition(v_u_509_, function(p510_, _, _)
		-- upvalues: (copy) element, (copy) v_u_509_, (copy) self
		if p510_ then
			element:getDescendantByName("text"):setText(v_u_509_:getString())
		end
		self:setJobMenuVisible(true)
	end)
	self:setJobMenuVisible(false, true)
end

-- Local values: parameter
function InGameMenuMobileMapFrame:onClickPositionRotationParameter(element)
	local v_u_513_ = element.aiParameter
	self:startPickPositionAndRotation(v_u_513_, function(p514_, _, _, _)
		-- upvalues: (copy) element, (copy) v_u_513_, (copy) self
		if p514_ then
			element:getDescendantByName("text"):setText(v_u_513_:getString())
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

-- Local values: list, _, actionName
function InGameMenuMobileMapFrame:unregisterInput(customOnly)
	local v517_ = customOnly and InGameMenuMobileMapFrame.CLEAR_CLOSE_INPUT_ACTIONS or InGameMenuMobileMapFrame.CLEAR_INPUT_ACTIONS
	for _, v518_ in pairs(v517_) do
		g_inputBinding:removeActionEventsByActionName(v518_)
	end
end

-- Local values: focusElement, element
function InGameMenuMobileMapFrame:onMenuAccept()
	if self.mode == InGameMenuMobileMapFrame.MODE_NONE or self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW then
		if self.currentList == self.statusList then
			self:onClickStatusListItem(self.currentList.sections[self.currentList.selectedSectionIndex].cells[self.currentList.selectedIndex])
			return
		end
		if not self.currentList.visible then
			self:onDetailsButtonBack()
			return
		end
		local v520_ = FocusManager:getFocusedElement()
		if self.currentList == self.pointsList and (v520_ ~= self.pointsList and v520_.onClickCallback ~= nil) then
			v520_.onClickCallback(self)
			return
		end
		if self.currentList.totalItemCount > 0 then
			self:onClickListItem(self.currentList.sections[self.currentList.selectedSectionIndex].cells[self.currentList.selectedIndex])
			return
		end
	elseif self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		local v521_ = FocusManager:getFocusedElement()
		if v521_.name == "button" then
			v521_.onClickCallback(self, v521_)
		end
	end
end

function InGameMenuMobileMapFrame:onMenuActivate()
	if self.mode == InGameMenuMobileMapFrame.MODE_NONE and self.canEnter then
		self:onClickEnterVehicle()
		return
	elseif self.mode == InGameMenuMobileMapFrame.MODE_NONE and self.canBuy then
		self:onClickBuyField()
		return
	elseif self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and self:getCanCreateJob() then
		self:onCreateJob()
		return
	elseif self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and self:getCanCancelJob() then
		self:onCancelJob()
	elseif self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
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
			return
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
	if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.STATUS and math.abs(dir) > g_analogStickVTolerance then
		self:onStatusFilterChanged(actionName, dir)
	end
end

-- Local values: element
function InGameMenuMobileMapFrame:onMenuLeftRightContinuous(actionName, dir)
	if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.POINTS then
		FocusManager:inputEvent(InputAction.MENU_AXIS_LEFT_RIGHT, dir)
	elseif self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
		local v530_ = FocusManager:getFocusedElement()
		if v530_.inputEvent ~= nil then
			v530_:inputEvent(actionName, dir)
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

-- Local values: vehicle
function InGameMenuMobileMapFrame:onClickEnterVehicle()
	local v534_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if v534_ ~= nil and (v534_.getIsEnterableFromMenu ~= nil and v534_:getIsEnterableFromMenu()) then
		self.onClickBackCallback()
		g_localPlayer:requestToEnterVehicle(v534_)
	end
end

function InGameMenuMobileMapFrame:onClickResetVehicle()
	if not self.isResetPending and (g_currentMission.tourIconsBase == nil or not g_currentMission.tourIconsBase.visible) and self.currentHotspot ~= nil then
		YesNoDialog.show(self.onYesNoReset, self, g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_RESET_CONFIRM), g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.VEHICLE_RESET))
	end
end

-- Local values: vehicle
function InGameMenuMobileMapFrame:onYesNoReset(yes)
	if yes and self.currentHotspot ~= nil then
		local v538_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
		if v538_ ~= nil then
			self.buttonResetVehicle:setVisible(false)
			g_messageCenter:subscribe(ResetVehicleEvent, self.onVehicleReset, self)
			self.isResetPending = true
			g_client:getServerConnection():sendEvent(ResetVehicleEvent.new(v538_))
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
		local v541_ = self.vehiclesList.sliderElement.parent
		local v542_ = self.vehiclesList.visible
		if v542_ then
			if self.vehiclesList.totalItemCount > 0 then
				v542_ = self.vehiclesList.sliderElement.needsSlider
			else
				v542_ = false
			end
		end
		v541_:setVisible(v542_)
		self:showDetailsBox(false)
		self.blockListSelectionEvents = true
		self.vehiclesList:setSelectedItem(1, 1)
		self.blockListSelectionEvents = false
		self.blockPanToHotspot = true
		return
	elseif state == ResetVehicleEvent.STATE_FAILED then
		InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_RESET_FAILED))
		return
	elseif state == ResetVehicleEvent.STATE_IN_USE then
		InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_IN_USE))
	else
		InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_NO_PERMISSION))
	end
end

function InGameMenuMobileMapFrame:onClickTagPlace()
	if self.currentHotspot ~= nil and (self.currentHotspot.worldX ~= nil and self.currentHotspot.worldZ ~= nil) then
		if g_currentMission.currentMapTargetHotspot == self.currentHotspot then
			self.removeMarker = false
			g_currentMission:setMapTargetHotspot(nil)
			self.currentHotspot:setBlinking(true)
		else
			self.removeMarker = true
			g_currentMission:setMapTargetHotspot(self.currentHotspot)
		end
		self:showContextMarker(self.canSetMarker, self.removeMarker)
	end
end

-- Local values: field, farmland, money, price, text, title, callback, target, text, title, callback, target
function InGameMenuMobileMapFrame:onClickBuyField()
	local v545_ = self.currentHotspot:getField()
	local v546_ = v545_.farmland
	if g_farmlandManager:getFarmlandOwner(v546_.id) ~= g_currentMission:getFarmId() then
		local v547_ = self.playerFarm:getBalance()
		local v548_ = v546_.price
		if v548_ <= v547_ then
			local v549_ = string.format(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.MOBILE_BUY_FIELD_TEXT), g_i18n:formatMoney(v547_, 0, true, true), g_i18n:formatMoney(v548_, 0, true, true))
			local v550_ = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_TITLE)
			local v551_ = self.onYesNoBuyField
			YesNoDialog.show(v551_, self, v549_, v550_)
		elseif Platform.hasInAppPurchases and (g_inAppPurchaseController ~= nil and g_inAppPurchaseController:getIsAvailable()) then
			local v552_ = string.format(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.MOBILE_BUY_FIELD_TEXT_COINS), g_i18n:formatMoney(v547_, 0, true, true), g_i18n:formatMoney(v548_, 0, true, true))
			local v553_ = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_TITLE)
			local v554_ = self.onYesNoBuyCoins
			YesNoDialog.show(v554_, self, v552_, v553_)
			self.toBuyField = nil
		else
			InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY))
		end
	end
	self.toBuyField = v545_
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

-- Local values: worldX, worldZ, isReachable
function InGameMenuMobileMapFrame:onConfirmAITarget()
	if self.isPickingLocation then
		local v564_ = self.aiTargetMapHotspot.worldX
		local v565_ = self.aiTargetMapHotspot.worldZ
		if g_currentMission.aiSystem:getIsPositionReachable(v564_, 0, v565_) then
			self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmRotation"))
			self.hasPickedLocationTouch = true
			self.inGameMap.isTouchPickingRotation = true
			self:executePickingCallback(true, v564_, v565_)
		else
			InfoDialog.show(g_i18n:getText("ai_validationErrorBlockedPosition"), nil, nil, DialogElement.TYPE_WARNING)
		end
	else
		if self.isPickingRotation then
			self.inGameMap.isTouchPickingRotation = false
			self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
			self:executePickingCallback(true, self.aiTargetMapHotspot.worldRotation + 3.141592653589793)
		end
		return
	end
end

function InGameMenuMobileMapFrame:onCreateJob()
	if self:getCanCreateJob() then
		self:createJob()
	end
end

-- Local values: _, filterPage, mapPageId, listRecievedFocus
function InGameMenuMobileMapFrame:onMapPageSelected()
	self:showDetailsBox(false)
	for _, v568_ in pairs(self.filterBoxes) do
		v568_:setVisible(false)
	end
	local v569_ = self.mapPageSelector.state
	self.filterBoxes[v569_]:setVisible(true)
	self.inGameMapBase:applyCustomHotspotSortingOrder(InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO[v569_])
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
	elseif v569_ == InGameMenuMobileMapFrame.PAGE_ID.AI and self.previousMapPageId == InGameMenuMobileMapFrame.PAGE_ID.FIELDS then
		self:setMapSelectionItem(nil)
	end
	self.currentList = self.pageLists[v569_]
	local v570_ = FocusManager:setFocus(self.currentList)
	if not self.isOpening then
		self:showDetailsBox(false)
	end
	if v569_ == InGameMenuMobileMapFrame.PAGE_ID.STATUS then
		if self.mode ~= InGameMenuMobileMapFrame.MODE_OVERVIEW then
			self:setMode(InGameMenuMobileMapFrame.MODE_OVERVIEW)
		end
		self:setMapSelectionItem(nil)
	elseif v569_ == InGameMenuMobileMapFrame.PAGE_ID.AI then
		if self.mode ~= InGameMenuMobileMapFrame.MODE_AI_PAGE then
			self:setMode(InGameMenuMobileMapFrame.MODE_AI_PAGE)
		end
		self:refreshContextInput()
		if not v570_ then
			FocusManager:unsetFocus(FocusManager.currentFocusData.focusElement)
		end
	elseif self.mode ~= InGameMenuMobileMapFrame.MODE_NONE then
		self:setMode(InGameMenuMobileMapFrame.MODE_NONE)
	end
	self.previousMapPageId = v569_
end

-- Local values: newState
function InGameMenuMobileMapFrame:onPreviousPage()
	local v572_ = self.mapPageSelector.state - 1
	local v573_ = v572_ == 0 and #self.mapPageSelector.texts or v572_
	self.mapPageSelector:setState(v573_, true)
end

-- Local values: newState
function InGameMenuMobileMapFrame:onNextPage()
	local v575_ = self.mapPageSelector.state + 1
	local v576_ = #self.mapPageSelector.texts < v575_ and 1 or v575_
	self.mapPageSelector:setState(v576_, true)
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

-- Local values: newState, newState
function InGameMenuMobileMapFrame:onStatusFilterChanged(_, dir)
	if self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW then
		if dir < 0 then
			local v584_ = self.statusSelector.state - 1
			local v585_ = math.max(v584_, 1)
			self.statusSelector:setState(v585_, true)
		else
			local v586_ = self.statusSelector.state + 1
			local v587_ = #self.statusSelector.texts
			local v588_ = math.min(v586_, v587_)
			self.statusSelector:setState(v588_, true)
		end
		self:onStatusSelected()
	end
end

function InGameMenuMobileMapFrame:onStatusSelected()
	self.statusList:reloadData()
	self:generateOverviewOverlay()
end

-- Local values: _, hotspot
function InGameMenuMobileMapFrame:onClickFilterLoading()
	self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING]
	for _, v591_ in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING]) do
		v591_:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING])
	end
	self:updatePointsFilterMapping()
end

-- Local values: _, hotspot
function InGameMenuMobileMapFrame:onClickFilterProductions()
	self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS]
	for _, v593_ in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS]) do
		v593_:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS])
	end
	self:updatePointsFilterMapping()
end

-- Local values: _, hotspot
function InGameMenuMobileMapFrame:onClickFilterAnimals()
	self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS]
	for _, v595_ in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS]) do
		v595_:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS])
	end
	self:updatePointsFilterMapping()
end

-- Local values: _, hotspot
function InGameMenuMobileMapFrame:onClickFilterOther()
	self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER]
	for _, v597_ in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER]) do
		v597_:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER])
	end
	self:updatePointsFilterMapping()
end

function InGameMenuMobileMapFrame:onFilterButtonFocusEnter(button)
	button.overlay.color = {
		0,
		0,
		0,
		0
	}
	button.overlay.alpha = 0
	button.icon.color = {
		1,
		1,
		1,
		1
	}
	button.icon.alpha = 1
end

function InGameMenuMobileMapFrame:onFilterButtonFocusLeave(button)
	button.overlay.color = {
		1,
		1,
		1,
		1
	}
	button.overlay.alpha = 1
	button.icon.color = {
		0,
		0,
		0,
		0
	}
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

-- Local values: vehicle, currentJobTypesTexts, currentJobTypeIndex, currentIndex, lastJob, name, index
function InGameMenuMobileMapFrame:createJob()
	local v604_ = self.currentHotspot:getVehicle()
	if v604_ ~= nil then
		self.currentJobTypes = {}
		local v605_ = {}
		local v606_ = nil
		local v607_ = nil
		local v608_
		if v604_.getLastJob == nil then
			v608_ = nil
		else
			v608_ = v604_:getLastJob()
		end
		for _, v609_ in pairs(AIJobType) do
			if self.jobTypeInstances[v609_]:getIsAvailableForVehicle(v604_) then
				local v610_ = self.currentJobTypes
				table.insert(v610_, v609_)
				local v611_ = g_currentMission.aiJobTypeManager:getJobTypeByIndex(v609_).title
				table.insert(v605_, v611_)
				if v606_ == nil or v608_ ~= nil and v608_.class == self.jobTypeInstances[v609_].class then
					v607_ = #self.currentJobTypes
					v606_ = v609_
				end
			end
		end
		if #self.currentJobTypes == 0 then
			printError("Error: vehicle has no support for any jobs, so button should not have been shown!")
			return
		end
		self.aiTaskDialogJobTypeSelector:setTexts(v605_)
		self.aiTaskDialogJobTypeSelector:setState(v607_ or 1)
		self:setMode(InGameMenuMobileMapFrame.MODE_CREATE_JOB)
		self.currentJobVehicle = v604_
		self.currentJob = nil
		self:setJobMenuVisible(true)
		self.aiWorkersList.handleFocus = false
		FocusManager:setFocus(self.aiTaskDialogJobTypeSelector)
		self:setActiveJobTypeSelection(v606_)
	end
end

-- Local values: vehicle, job
function InGameMenuMobileMapFrame:tryStartGoToJob()
	if self.currentHotspot ~= nil then
		local v_u_613_ = self.currentHotspot:getVehicle()
		if v_u_613_ ~= nil then
			self:startPickPositionAndRotation(self.jobTypeInstances[AIJobType.GOTO].positionAngleParameter, function(p614_, p615_, p616_, p617_)
				-- upvalues: (copy) self, (copy) v_u_613_
				if p614_ then
					self:startGoToJob(v_u_613_, p615_, p616_, p617_)
				end
				self:refreshContextInput()
			end)
			self:refreshContextInput()
		end
	end
end

-- Local values: success, errorMessage, callback
function InGameMenuMobileMapFrame:startJob()
	if self.startJobPending then
		return
	else
		self.currentJob:setValues()
		local v619_, v620_ = self.currentJob:validate(g_localPlayer.farmId)
		if v619_ then
			self:tryStartJob(self.currentJob, g_localPlayer.farmId, function(p621_)
				-- upvalues: (copy) self
				if p621_ == AIJob.START_SUCCESS then
					self:setMode(InGameMenuMobileMapFrame.MODE_AI_PAGE)
					self.currentJob = nil
					self:setJobMenuVisible(false)
					self.aiWorkersList.handleFocus = true
				end
			end)
		else
			InfoDialog.show(tostring(v620_), nil, nil, DialogElement.TYPE_WARNING)
			self:updateWarnings()
		end
	end
end

-- Local values: vehicle
function InGameMenuMobileMapFrame:cancelJob()
	local v623_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if v623_ ~= nil and v623_:getIsAIActive() then
		v623_:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
	end
	self:refreshContextInput()
end

function InGameMenuMobileMapFrame:tryStartJob(job, farmId, callback)
	self.startJobPending = true
	g_messageCenter:subscribe(AIJobStartRequestEvent, self.onStartedJob, self, { callback })
	g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, farmId))
end

-- Local values: callback, jobType, text
function InGameMenuMobileMapFrame:onStartedJob(args, state, jobTypeIndex)
	local v632_ = args[1]
	self.startJobPending = false
	g_messageCenter:unsubscribe(AIJobStartRequestEvent, self)
	if state ~= AIJob.START_SUCCESS then
		local v633_ = g_currentMission.aiJobTypeManager:getJobTypeByIndex(jobTypeIndex).classObject.getIsStartErrorText(state)
		InfoDialog.show(v633_, nil, nil, DialogElement.TYPE_INFO)
	end
	v632_(state)
end

-- Local values: vehicle, job
function InGameMenuMobileMapFrame:skipCurrentTask()
	local v635_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if v635_ ~= nil and v635_:getIsAIActive() then
		local v636_ = v635_:getJob()
		if v636_ ~= nil then
			if v636_:getCanSkipTask() then
				v635_:skipCurrentTask()
				return
			end
			self:refreshContextInput()
		end
	end
end
InGameMenuMobileMapFrame.STATUS_BG_COLOR_PROFILE = "inGameMenuMobileMapStatusListIconBg"
InGameMenuMobileMapFrame.STATUS_BG_COLOR_UVS = {
	700,
	0,
	82,
	82
}
InGameMenuMobileMapFrame.COLOR = {
	["MAIN_MENU_BLUE"] = {
		0.0227,
		0.5346,
		0.8519,
		1
	}
}
InGameMenuMobileMapFrame.UV = {
	["BUTTON_RIDE_HORSE"] = {
		946,
		539,
		36,
		36
	},
	["BUTTON_ENTER_VEHICLE"] = {
		909,
		502,
		36,
		36
	}
}
