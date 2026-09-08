-- Local values: InGameMenuMapFrame_mt, NO_CALLBACK
InGameMenuMapFrame = {}
local InGameMenuMapFrame_mt = Class(InGameMenuMapFrame, TabbedMenuFrameElement)
InGameMenuMapFrame.MAP_FRUIT_TYPE = 1
InGameMenuMapFrame.MAP_GROWTH = 2
InGameMenuMapFrame.MAP_SOIL = 3
InGameMenuMapFrame.MAP_HOTSPOTS = 4
InGameMenuMapFrame.MAP_FARMLANDS = 5
InGameMenuMapFrame.AI_CREATE_JOB = 6
InGameMenuMapFrame.AI_WORKER_LIST = 7
InGameMenuMapFrame.AI_MODE_OVERVIEW = 1
InGameMenuMapFrame.AI_MODE_CREATE = 2
InGameMenuMapFrame.AI_MODE_WORKER_LIST = 3
InGameMenuMapFrame.BUTTON_FRAME_SIDE = GuiElement.FRAME_RIGHT
InGameMenuMapFrame.FIELD_INFO_DELAY = 1500
InGameMenuMapFrame.FIELD_INFO_LAYOUT_BASE_SIZE = 125
local function NO_CALLBACK() end
function InGameMenuMapFrame.register()
	local v3_ = InGameMenuMapFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuMapFrame.xml", "MapFrame", v3_, true)
end

-- Upvalues: InGameMenuMapFrame_mt, NO_CALLBACK
-- Local values: self
function InGameMenuMapFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuMapFrame_mt, (copy) NO_CALLBACK
	local v_u_6_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMapFrame_mt)
	v_u_6_.onClickBackCallback = NO_CALLBACK
	v_u_6_.client = nil
	v_u_6_.playerFarm = nil
	v_u_6_.contextActions = {}
	v_u_6_.contextActionMapping = {}
	v_u_6_.fruitTypeFilter = {}
	v_u_6_.growthStateFilter = {}
	v_u_6_.soilStateFilter = {}
	v_u_6_.hotspotStateFilter = {
		{},
		{}
	}
	v_u_6_.filterStates = {
		v_u_6_.fruitTypeFilter,
		v_u_6_.growthStateFilter,
		v_u_6_.soilStateFilter,
		v_u_6_.hotspotStateFilter
	}
	v_u_6_.numSelectedFilters = {
		0,
		0,
		0,
		0
	}
	v_u_6_.hasFullScreenMap = true
	v_u_6_.dataTables = {}
	v_u_6_.farmlandItems = {}
	v_u_6_.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	v_u_6_.isMapOverviewInitialized = false
	v_u_6_.lastInputHelpMode = 0
	v_u_6_.isInputContextActive = false
	v_u_6_.nextMoneyUpdateTime = 0
	v_u_6_.foliageStateOverlay = nil
	v_u_6_.foliageStateOverlayIsReady = false
	v_u_6_.farmlandStateOverlay = nil
	v_u_6_.farmlandStateOverlayIsReady = false
	function v_u_6_.overviewOverlayFinishedCallback(p7_)
		-- upvalues: (copy) v_u_6_
		v_u_6_:onOverviewOverlayFinished(p7_)
	end
	function v_u_6_.farmlandOverlayFinishedCallback(p8_)
		-- upvalues: (copy) v_u_6_
		v_u_6_:onFarmlandOverlayFinished(p8_)
	end
	v_u_6_.hotspotModeActive = false
	v_u_6_.currentHotspot = nil
	v_u_6_.ingameMapBase = nil
	v_u_6_.staticUIDeadzone = {
		0,
		0,
		0,
		0
	}
	v_u_6_.needsSolidBackground = Platform.ingameMap.needsSolidBackground
	v_u_6_.selectedFarmland = nil
	v_u_6_.selectedVehicle = nil
	v_u_6_.previousSubCategoryState = 1
	v_u_6_.showIntroductionHud = false
	v_u_6_.showIntroHudIfNotSaving = false
	v_u_6_.goToMainOverview = false
	v_u_6_.jobTypeInstances = {}
	v_u_6_.statusMessages = {}
	v_u_6_.playerFarmActiveJobs = {}
	v_u_6_.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
	v_u_6_.lastMousePosX = 0
	v_u_6_.lastMousePosY = 0
	v_u_6_.updateTime = 0
	v_u_6_.aiTargetMapHotspot = AITargetHotspot.new()
	v_u_6_.aiLoadingMarkerHotspot = AIPlaceableMarkerHotspot.new()
	v_u_6_.aiUnloadingMarkerHotspot = AIPlaceableMarkerHotspot.new()
	v_u_6_.lastInputTime = 0
	return v_u_6_
end

-- Local values: newGui
function InGameMenuMapFrame.createFromExistingGui(gui, guiName)
	local v11_ = InGameMenuMapFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v11_, true)
	g_messageCenter:unsubscribeAll(v11_)
	return v11_
end

-- Upvalues: NO_CALLBACK
function InGameMenuMapFrame:copyAttributes(src)
	-- upvalues: (copy) NO_CALLBACK
	InGameMenuMapFrame:superClass().copyAttributes(self, src)
	self.onClickBackCallback = src.onClickBackCallback or NO_CALLBACK
end

function InGameMenuMapFrame:delete()
	g_messageCenter:unsubscribeAll(self)
	self.createMultiOptionTemplate:delete()
	self.createTextTemplate:delete()
	self.createTitleTemplate:delete()
	self.createPositionTemplate:delete()
	self.createPositionRotationTemplate:delete()
	self.fieldInfoKeyValueTemplate:delete()
	self.fieldInfoWarningTemplate:delete()
	if self.aiTargetMapHotspot ~= nil then
		self.aiTargetMapHotspot:delete()
		self.aiTargetMapHotspot = nil
	end
	if self.aiLoadingMarkerHotspot ~= nil then
		self.aiLoadingMarkerHotspot:delete()
		self.aiLoadingMarkerHotspot = nil
	end
	if self.aiUnloadingMarkerHotspot ~= nil then
		self.aiUnloadingMarkerHotspot:delete()
		self.aiUnloadingMarkerHotspot = nil
	end
	InGameMenuMapFrame:superClass().delete(self)
end

-- Upvalues: NO_CALLBACK
-- Local values: index, dot, filterList
function InGameMenuMapFrame:initialize(onClickBackCallback)
	-- upvalues: (copy) NO_CALLBACK
	self:updateInputGlyphs()
	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK
	for v_u_17_, v18_ in pairs(self.subCategoryDotBox.elements) do
		function v18_.getIsSelected()
			-- upvalues: (copy) self, (copy) v_u_17_
			return self.mapOverviewSelector:getState() == v_u_17_
		end
	end
	local v_u_19_ = self.filterList
	
-- Local values: localX, localY, worldX, worldZ, angle, numSteps, localX, localY
function v_u_19_:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
		-- upvalues: (copy) v_u_19_, (copy) self
		SmoothListElement.mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
		if isDown and (button == Input.MOUSE_BUTTON_RIGHT and GuiUtils.checkOverlayOverlap(posX, posY, v_u_19_.absPosition[1], v_u_19_.absPosition[2], v_u_19_.absSize[1], v_u_19_.absSize[2])) then
			local _, v27_, v28_ = v_u_19_:getElementAtScreenPosition(posX, posY)
			self:onClickDeselectAll(v27_, v28_)
			v_u_19_:setSelectedItem(v27_, v28_)
		end
	end
	self:initializeContextActions()
	self.zoomText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_ZOOM_MAP)
	self.moveCursorText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_MOVE_CURSOR)
	self.panMapText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_PAN_MAP)
	function self.buttonDeselectAllText.getIsFocused()
		-- upvalues: (copy) self
		return self.buttonDeselectAll:getIsFocused()
	end
	function self.buttonDeselectAllText.getIsHighlighted()
		-- upvalues: (copy) self
		return self.buttonDeselectAll:getIsHighlighted()
	end
	function self.buttonStartJobText.getIsFocused()
		-- upvalues: (copy) self
		return self.buttonStartJob:getIsFocused()
	end
	function self.buttonStartJobText.getIsHighlighted()
		-- upvalues: (copy) self
		return self.buttonStartJob:getIsHighlighted()
	end
	self.createMultiOptionTemplate:unlinkElement()
	FocusManager:removeElement(self.createMultiOptionTemplate)
	self.createTextTemplate:unlinkElement()
	FocusManager:removeElement(self.createTextTemplate)
	self.createTitleTemplate:unlinkElement()
	FocusManager:removeElement(self.createTitleTemplate)
	self.createPositionTemplate:unlinkElement()
	FocusManager:removeElement(self.createPositionTemplate)
	self.createPositionRotationTemplate:unlinkElement()
	FocusManager:removeElement(self.createPositionRotationTemplate)
	self.fieldInfoKeyValueTemplate:unlinkElement()
	FocusManager:removeElement(self.fieldInfoKeyValueTemplate)
	self.fieldInfoWarningTemplate:unlinkElement()
	FocusManager:removeElement(self.fieldInfoWarningTemplate)
	self.fieldInfoLayout:invalidateLayout()
	self.currentContextBox = self.contextBox
end

function InGameMenuMapFrame:initializeContextActions()
	local v30_ = {
		[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE] = {
			["text"] = "button_enterVehicle",
			["callback"] = self.onClickEnterVehicle,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.RESET_VEHICLE] = {
			["text"] = "button_reset",
			["callback"] = self.onClickResetVehicle,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE] = {
			["text"] = "button_sell",
			["callback"] = self.onClickSellVehicle,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.BUY] = {
			["text"] = "button_buy",
			["callback"] = self.onClickBuy,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.SELL] = {
			["text"] = "button_sell",
			["callback"] = self.onClickSell,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.VISIT_PLACE] = {
			["text"] = "action_visit",
			["callback"] = self.onClickVisitPlace,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.SET_MARKER] = {
			["text"] = "action_tag",
			["callback"] = self.onClickTagPlace,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER] = {
			["text"] = "action_untag",
			["callback"] = self.onClickTagPlace,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.MANAGE] = {
			["text"] = "action_manage",
			["callback"] = self.onClickManage,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.GOTO_JOB] = {
			["text"] = "button_gotoJob",
			["callback"] = self.onStartGoToJob,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.CREATE_JOB] = {
			["text"] = "button_createJob",
			["callback"] = self.onCreateJob,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.START_JOB] = {
			["text"] = "button_startJob",
			["callback"] = self.onStartCancelJob,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.CANCEL_JOB] = {
			["text"] = "button_cancelJob",
			["callback"] = self.onStartCancelJob,
			["isActive"] = false
		},
		[InGameMenuMapFrame.ACTIONS.SKIP_TASK] = {
			["text"] = "button_skipTask",
			["callback"] = self.onSkipJobTask,
			["isActive"] = false
		}
	}
	self.contextActions = v30_
	FocusManager:linkElements(self.contextButtonList, FocusManager.TOP, nil)
	FocusManager:linkElements(self.contextButtonList, FocusManager.BOTTOM, nil)
	FocusManager:linkElements(self.contextButtonList, FocusManager.LEFT, nil)
	FocusManager:linkElements(self.contextButtonList, FocusManager.RIGHT, nil)
	FocusManager:linkElements(self.contextButtonListFarmland, FocusManager.TOP, nil)
	FocusManager:linkElements(self.contextButtonListFarmland, FocusManager.BOTTOM, nil)
	FocusManager:linkElements(self.contextButtonListFarmland, FocusManager.LEFT, nil)
	FocusManager:linkElements(self.contextButtonListFarmland, FocusManager.RIGHT, nil)
	FocusManager:linkElements(self.filterList, FocusManager.LEFT, nil)
	FocusManager:linkElements(self.filterList, FocusManager.RIGHT, nil)
	FocusManager:linkElements(self.filterList, FocusManager.BOTTOM, nil)
end

-- Local values: x, _, z, farmId, mission, _, job
function InGameMenuMapFrame:onFrameOpen()
	InGameMenuMapFrame:superClass().onFrameOpen(self)
	self:loadFilters()
	self:setColorBlindMode(Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false))
	self:toggleMapInput(true)
	self.ingameMap:onOpen()
	self.ingameMap:registerActionEvents()
	self.ingameMapBase:restoreDefaultFilter()
	if self.visible and not self.isMapOverviewInitialized then
		self:setupMapOverview()
		self.filterList:reloadData()
		self.mapOverviewSelector:setState(1, true)
	end
	self:setMapSelectionItem(nil)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.mapOverviewSelector)
	self:setSoundSuppressed(false)
	self:updateInputGlyphs()
	self.ingameMap:setCursorCenter(self.filterBox.absSize[1] * 0.5, self.buttonBox.absSize[2] * 0.5)
	if g_localPlayer ~= nil then
		local v32_, _, v33_ = g_localPlayer:getPosition()
		self.ingameMap:setCenterToWorldPosition(v32_, v33_)
	end
	self:generateJobTypes()
	self:setJobMenuVisible(false)
	self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
	self.playerFarmActiveJobs = {}
	local v34_ = g_localPlayer == nil and 1 or g_localPlayer.farmId
	local v35_ = g_currentMission
	for _, v36_ in ipairs(v35_.aiSystem:getActiveJobs()) do
		if v36_.startedFarmId == v34_ then
			local v37_ = self.playerFarmActiveJobs
			local v38_ = v36_.jobId
			table.insert(v37_, v38_)
		end
	end
	self.activeWorkerList:reloadData()
	self:onMoneyChange()
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
	g_messageCenter:subscribe(MessageType.AI_VEHICLE_STATE_CHANGE, self.onAIVehicleStateChanged, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_STARTED, self.onAIJobStarted, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_STOPPED, self.onAIJobStopped, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_REMOVED, self.onAIJobRemoved, self)
	g_messageCenter:subscribe(MessageType.AI_TASK_SKIPPED, self.onAITaskSkipped, self)
	g_messageCenter:subscribe(MessageType.PAUSE, self.onPauseChanged, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_PLAYER_ENTERED, self.onVehicleEntered, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_PLAYER_LEFT, self.onVehicleLeft, self)
	self:onClickMapOverviewSelector(self.mapOverviewSelector:getState())
	self.blockListSelectionUpdates = self.mapOverviewSelector:getState() ~= InGameMenuMapFrame.AI_WORKER_LIST
	self.lastInputTime = g_time
end

-- Local values: _, hotspot, mission
function InGameMenuMapFrame:onFrameClose()
	g_messageCenter:unsubscribeAll(self)
	if self.previousSubCategoryState == InGameMenuMapFrame.AI_CREATE_JOB then
		for _, v40_ in pairs(self.ingameMap.ingameMap.hotspots) do
			if v40_:isa(VehicleHotspot) or v40_:isa(AIHotspot) then
				v40_:setVisible(v40_.oldVisibility)
			end
		end
	end
	self.isResetPending = false
	self.startJobPending = false
	if self:getIsPicking() then
		self:executePickingCallback(false)
		self:refreshContextInput()
	end
	if self.hotspotModeActive then
		self:setHotspotModeActive(false)
	end
	local v41_ = g_currentMission
	v41_:removeMapHotspot(self.aiTargetMapHotspot)
	v41_:removeMapHotspot(self.aiLoadingMarkerHotspot)
	v41_:removeMapHotspot(self.aiUnloadingMarkerHotspot)
	self.statusMessages = {}
	self:updateStatusMessages()
	InGameMenuMapFrame:superClass().onFrameClose(self)
	self.ingameMap:onClose()
	self:toggleMapInput(false)
	self.ingameMapBase:restoreDefaultFilter()
end

-- Local values: fruitValue, fruitId, state, name, growthValue, i, state, soilValue, i, state, hotspotValue, i, state, i, state
function InGameMenuMapFrame:saveFilters()
	local v43_ = ""
	for v44_, v45_ in pairs(self.fruitTypeFilter) do
		if not v45_ then
			local v46_ = g_fruitTypeManager:getFillTypeNameByFruitTypeIndex(v44_)
			if v43_ == "" then
				v43_ = v46_
			else
				v43_ = v43_ .. ";" .. v46_
			end
		end
	end
	local v47_ = 0
	for v48_, v49_ in ipairs(self.growthStateFilter) do
		if v49_ then
			v47_ = Utils.setBit(v47_, v48_)
		end
	end
	local v50_ = 0
	for v51_, v52_ in ipairs(self.soilStateFilter) do
		if v52_ then
			v50_ = Utils.setBit(v50_, v51_)
		end
	end
	local v53_ = 0
	for v54_, v55_ in ipairs(self.hotspotStateFilter[1]) do
		if v55_ then
			v53_ = Utils.setBit(v53_, v54_)
		end
	end
	for v56_, v57_ in ipairs(self.hotspotStateFilter[2]) do
		if v57_ then
			v53_ = Utils.setBit(v53_, v56_ + #self.hotspotStateFilter[1])
		end
	end
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER, v43_, false)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER, v47_, false)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER, v50_, true)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER, v53_, true)
end

-- Local values: numInactiveFilters, fruitValue, _, fruitName, fruitDesc, _, fruitDesc, growthValue, i, _, isBitSet, lastSoilFilter, soilValue, _, state, index, isBitSet, i, hotspotValue, i, hotspotCategory, isBitSet, i, hotspotCategory, isBitSet
function InGameMenuMapFrame:loadFilters()
	local v59_ = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER)
	local v60_ = 0
	for _, v61_ in ipairs(v59_:split(";")) do
		local v62_ = g_fruitTypeManager:getFruitTypeByName(v61_)
		if v62_ ~= nil then
			self.fruitTypeFilter[v62_.index] = false
			v60_ = v60_ + 1
		end
	end
	for _, v63_ in pairs(self.displayCropTypes) do
		if self.fruitTypeFilter[v63_.fruitTypeIndex] == nil then
			self.fruitTypeFilter[v63_.fruitTypeIndex] = true
		end
	end
	local v64_ = self.numSelectedFilters
	local v65_ = #self.displayCropTypes - v60_
	v64_[1] = math.max(v65_, 0)
	if self.numSelectedFilters[1] == 0 then
		self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
	end
	local v66_ = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER)
	for v67_, _ in pairs(self.displayGrowthStates) do
		local v68_ = Utils.isBitSet(v66_, v67_)
		self.growthStateFilter[v67_] = v68_
		if v68_ then
			self.numSelectedFilters[2] = self.numSelectedFilters[2] + 1
		end
	end
	local v69_ = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER)
	local v70_ = 1
	for _, v71_ in pairs(self.displaySoilStateMapping) do
		v70_ = v71_.soilStateIndex
		local v72_ = Utils.isBitSet(v69_, v70_)
		self.soilStateFilter[v70_] = v72_
		if v72_ then
			self.numSelectedFilters[3] = self.numSelectedFilters[3] + 1
		end
	end
	for v73_ = 1, v70_ do
		if self.displaySoilStates[v73_] == nil then
			self.soilStateFilter[v73_] = false
		end
	end
	local v74_ = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER)
	for v75_, v76_ in pairs(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1]) do
		local v77_ = Utils.isBitSet(v74_, v75_)
		self.hotspotStateFilter[1][v75_] = v77_
		self.ingameMapBase:setDefaultFilterValue(v76_.id, v77_)
		if v77_ then
			self.numSelectedFilters[4] = self.numSelectedFilters[4] + 1
		end
	end
	for v78_, v79_ in pairs(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[2]) do
		local v80_ = Utils.isBitSet(v74_, v78_ + #self.hotspotStateFilter[1])
		self.hotspotStateFilter[2][v78_] = v80_
		self.ingameMapBase:setDefaultFilterValue(v79_.id, v80_)
		if v80_ then
			self.numSelectedFilters[4] = self.numSelectedFilters[4] + 1
		end
	end
end

-- Local values: mapOverlayGenerator, index, state
function InGameMenuMapFrame:onLoadMapFinished()
	local v82_ = g_currentMission.mapOverlayGenerator
	self.displaySoilStateMapping = {}
	if v82_ ~= nil then
		self.displayCropTypes = v82_:getDisplayCropTypes()
		self.displayGrowthStates = v82_:getDisplayGrowthStates()
		self.displaySoilStates = v82_:getDisplaySoilStates()
		for v83_, v84_ in pairs(self.displaySoilStates) do
			if v84_.isActive then
				v84_.soilStateIndex = v83_
				local v85_ = self.displaySoilStateMapping
				table.insert(v85_, v84_)
			end
		end
	end
	self.dataTables[InGameMenuMapFrame.MAP_SOIL] = self.displaySoilStateMapping or {}
	self.dataTables[InGameMenuMapFrame.MAP_FRUIT_TYPE] = self.displayCropTypes or {}
	self.dataTables[InGameMenuMapFrame.MAP_GROWTH] = self.displayGrowthStates or {}
	self.dataTables[InGameMenuMapFrame.MAP_HOTSPOTS] = InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES or {}
	self.dataTables[InGameMenuMapFrame.MAP_FARMLANDS] = self.farmlandItems or {}
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER, 4294967295, true)
	if g_terrainNode ~= nil then
		self.filterList:reloadData()
	end
end

-- Local values: mapOverlayGenerator, index, state
function InGameMenuMapFrame:onSoilSettingChanged()
	local v87_ = g_currentMission.mapOverlayGenerator
	self.displaySoilStateMapping = {}
	if v87_ ~= nil then
		v87_:updateStates()
		self.displaySoilStates = v87_:getDisplaySoilStates()
		for v88_, v89_ in pairs(self.displaySoilStates) do
			if v89_.isActive then
				v89_.soilStateIndex = v88_
				local v90_ = self.displaySoilStateMapping
				table.insert(v90_, v89_)
			end
		end
	end
	self.dataTables[InGameMenuMapFrame.MAP_SOIL] = self.displaySoilStateMapping
	self.filterList:reloadData()
end

function InGameMenuMapFrame:toggleMapInput(isActive)
	if self.isInputContextActive ~= isActive then
		self.isInputContextActive = isActive
		self:toggleCustomInputContext(isActive, InGameMenuMapFrame.INPUT_CONTEXT_NAME)
		if isActive then
			self:registerInput()
			return
		end
		self:unregisterInput(true)
	end
end

function InGameMenuMapFrame:reset()
	InGameMenuMapFrame:superClass().reset(self)
	self.foliageStateOverlayIsReady = false
	self.farmlandStateOverlayIsReady = false
	self.isMapOverviewInitialized = false
	self.isInputContextActive = false
	self:setMapSelectionItem(nil)
end
function InGameMenuMapFrame.mouseEvent(p94_, p95_, p96_, p97_, p98_, p99_, p100_)
	if p94_.isPickingRotation then
		local v101_, v102_ = p94_.ingameMap:getLocalPosition(p95_, p96_)
		local v103_, v104_ = p94_.ingameMap:localToWorldPos(v101_, v102_)
		local v105_ = v103_ - p94_.pickingRotationOrigin[1]
		local v106_ = v104_ - p94_.pickingRotationOrigin[2]
		local v107_ = math.atan2(v105_, v106_) + 3.141592653589793
		if p94_.pickingRotationSnapAngle > 0 then
			v107_ = MathUtil.round(v107_ / p94_.pickingRotationSnapAngle, 0) * p94_.pickingRotationSnapAngle
		end
		p94_.aiTargetMapHotspot:setWorldRotation(v107_)
	end
	p94_.lastMousePosX = p95_
	p94_.lastMousePoxY = p96_
	if p94_.isPickingLocation then
		local v108_, v109_ = p94_.ingameMap:getLocalPosition(p94_.lastMousePosX, p94_.lastMousePoxY)
		if p94_.filterBox.absPosition[1] + p94_.filterBox.absSize[1] < p95_ and p94_.buttonBox.absPosition[2] + p94_.buttonBox.absSize[2] < p96_ then
			p94_:setTargetPointHotspotPosition(v108_, v109_)
		end
	end
	p94_.lastInputTime = g_time
	return InGameMenuMapFrame:superClass().mouseEvent(p94_, p95_, p96_, p97_, p98_, p99_, p100_)
end

function InGameMenuMapFrame:inputEvent(action, value, eventUsed)
	self.lastInputTime = g_time
	return InGameMenuMapFrame:superClass().inputEvent(self, action, value, eventUsed)
end

-- Local values: currentInputHelpMode, mission, localX, localY, worldX, worldZ, angle, numSteps, mission, aiSystem, i, element, job, textElement, hasChanged, i, removeTime, fieldInfoBox, screenX, screenY, backgroundTop, backgroundBottom, layout, baseSize
function InGameMenuMapFrame:update(dt)
	InGameMenuMapFrame:superClass().update(self, dt)
	if self.elementToFocus ~= nil and (not g_gui:getIsDialogVisible() and FocusManager:setFocus(self.elementToFocus)) then
		self.elementToFocus = nil
	end
	local v116_ = g_inputBinding:getInputHelpMode()
	if v116_ ~= self.lastInputHelpMode then
		self.lastInputHelpMode = v116_
		self.buttonSelectIngame:setVisible(v116_ == GS_INPUT_HELP_MODE_GAMEPAD)
		self:updateContextInputBarVisibility()
		g_inputBinding:setShowMouseCursor(v116_ ~= GS_INPUT_HELP_MODE_GAMEPAD)
		self:updateInputGlyphs()
		self.contextButtonList:reloadData()
	end
	if self.needsOverlayUpdate then
		self:generateFarmlandOverlay(self.selectedFarmland)
		self.needsOverlayUpdate = false
	end
	if self.showIntroHudIfNotSaving then
		if g_savegameController:getIsSaving() then
			self.showIntroductionHud = true
			self.showIntroHudIfNotSaving = false
		else
			local v117_ = g_currentMission
			if v117_.introductionHelpSystem:getIsActive() then
				v117_.introductionHelpSystem:showHelp("helpZoomMap")
				v117_.introductionHelpSystem:showHelp("helpPanMap")
			end
			self.showIntroHudIfNotSaving = false
		end
	end
	if self.showIntroductionHud and not g_savegameController:getIsSaving() then
		self.showIntroductionHud = false
		self.showIntroHudIfNotSaving = true
	end
	if v116_ == GS_INPUT_HELP_MODE_GAMEPAD then
		local v118_, v119_ = self.ingameMap:getLocalPointerTarget()
		if self.isPickingLocation then
			self:setTargetPointHotspotPosition(v118_, v119_)
		elseif self.isPickingRotation then
			local v120_, v121_ = self.ingameMap:localToWorldPos(v118_, v119_)
			local v122_ = v120_ - self.pickingRotationOrigin[1]
			local v123_ = v121_ - self.pickingRotationOrigin[2]
			local v124_ = math.atan2(v122_, v123_) + 3.141592653589793
			if self.pickingRotationSnapAngle > 0 then
				v124_ = MathUtil.round(v124_ / self.pickingRotationSnapAngle, 0) * self.pickingRotationSnapAngle
			end
			self.aiTargetMapHotspot:setWorldRotation(v124_)
		end
	end
	if self.updateTime < g_time then
		local v125_ = g_currentMission.aiSystem
		for v126_ = 1, self.activeWorkerList:getItemCount() do
			local v127_ = self.activeWorkerList:getElementAtSectionIndex(1, v126_)
			if v127_ ~= nil then
				local v128_ = v125_:getJobById(self.playerFarmActiveJobs[v126_])
				local v129_ = v127_:getAttribute("text")
				if v128_ ~= nil and v129_:getText() ~= v128_:getDescription() then
					v129_:setText(v128_:getDescription())
				end
			end
		end
		self.updateTime = g_time + 1000
	end
	local v130_ = false
	for _ = 1, #self.statusMessages do
		if self.statusMessages[1].removeTime < g_time then
			table.remove(self.statusMessages, 1)
			v130_ = true
		end
	end
	if v130_ then
		self:updateStatusMessages()
	end
	self.blockListSelectionUpdates = false
	if g_gui:getIsDialogVisible() then
		self.lastInputTime = g_time
	end
	if g_time - self.lastInputTime > InGameMenuMapFrame.FIELD_INFO_DELAY then
		local v131_ = self.fieldInfoBox
		if self.currentHotspot == nil and not v131_:getIsVisible() then
			local v132_, v133_
			if v116_ == GS_INPUT_HELP_MODE_GAMEPAD then
				v132_, v133_ = self.mapCursor:getCenter()
			else
				v132_ = g_lastMousePosX
				v133_ = g_lastMousePosY
			end
			self:clearFieldInfoBox()
			if self:updateFieldInfoBox(v132_, v133_) then
				v131_:setVisible(true)
				local v134_ = v131_:getDescendantByName("backgroundTop")
				local v135_ = v131_:getDescendantByName("backgroundBottom")
				local v136_ = v131_:getDescendantByName("layout")
				v136_:invalidateLayout()
				local v137_ = InGameMenuMapFrame.FIELD_INFO_LAYOUT_BASE_SIZE * g_pixelSizeScaledY
				local v138_ = v134_.absSize[2] - v134_.position[2] + v135_.absSize[2] + v135_.position[2]
				local v139_ = v136_.maxFlowSize - v137_
				v131_:setSize(nil, v138_ + math.max(v139_, 0))
				InGameMenuMapUtil.updateFieldInfoBoxPosition(self.fieldInfoBox, v132_, v133_)
				return
			end
		end
	else
		self.fieldInfoBox:setVisible(false)
	end
end

-- Local values: layout, i
function InGameMenuMapFrame:clearFieldInfoBox()
	local v141_ = self.fieldInfoBox:getDescendantByName("layout")
	for v142_ = #v141_.elements, 1, -1 do
		v141_.elements[v142_]:delete()
		v141_.elements[v142_] = nil
	end
end

-- Local values: layout, template, clonedElement, title, text
function InGameMenuMapFrame:addFieldInfoKeyValue(key, value)
	local v146_ = self.fieldInfoBox:getDescendantByName("layout")
	local v147_ = self.fieldInfoKeyValueTemplate:clone(v146_)
	local v148_ = v147_:getDescendantByName("title")
	local v149_ = v147_:getDescendantByName("text")
	v148_:setText(key)
	v149_:setText(value)
end

-- Local values: layout, template, clonedElement, warning
function InGameMenuMapFrame:addFieldInfoWarning(text)
	local v152_ = self.fieldInfoBox:getDescendantByName("layout")
	self.fieldInfoWarningTemplate:clone(v152_):getDescendantByName("warning"):setText(text)
end

-- Local values: localX, localY, worldX, worldZ, fieldInfo, farmName, ownedByYou, ownerFarmId, farmland, npc, farm, fruitTypeIndex, growthState, isGrowing, fruitTypeDesc, text, fieldGroundSystem, harvestMultiplier, sprayLevelMax, sprayFactor, missionInfo, weedSystem, fieldInfoStates, weedState, toolName, fruitTypeDesc, weederReplacements, weed, targetState, hoeReplacements, weed, targetState, title
function InGameMenuMapFrame:updateFieldInfoBox(screenX, screenY)
	local v156_, v157_ = self.ingameMap:getLocalPosition(screenX, screenY)
	local v158_, v159_ = self.ingameMap:localToWorldPos(v156_, v157_)
	if self.fieldInfo == nil then
		self.fieldInfo = FieldState.new()
	end
	local v160_ = self.fieldInfo
	v160_:update(v158_, v159_)
	if v160_.groundType == FieldGroundType.NONE then
		return false
	end
	local v161_ = false
	local v162_ = v160_.ownerFarmId
	local v163_
	if v162_ == g_currentMission:getFarmId() and v162_ ~= FarmManager.SPECTATOR_FARM_ID then
		v163_ = g_i18n:getText("fieldInfo_ownerYou")
		v161_ = true
	elseif v162_ == AccessHandler.EVERYONE or v162_ == AccessHandler.NOBODY then
		local v164_ = g_farmlandManager:getFarmlandById(v160_.farmlandId)
		if v164_ == nil then
			v163_ = g_i18n:getText("fieldInfo_ownerNobody")
		else
			local v165_ = v164_:getNPC()
			v163_ = v165_ ~= nil and v165_.title or "Unknown"
		end
	else
		local v166_ = g_farmManager:getFarmById(v162_)
		if v166_ == nil then
			v163_ = "Unknown"
		else
			v163_ = v166_.name
		end
	end
	local v167_ = g_i18n:getText("fieldInfo_farmland")
	local v168_ = v160_.farmlandId
	self:addFieldInfoKeyValue(v167_, (tostring(v168_)))
	if Platform.playerInfo.showNPCNames then
		self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), v163_)
	elseif v161_ then
		self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_owned"))
	else
		self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_notOwned"))
	end
	local v169_ = v160_.fruitTypeIndex
	local v170_ = v160_.growthState
	local v171_ = false
	if v169_ ~= FruitType.UNKNOWN then
		local v172_ = g_fruitTypeManager:getFruitTypeByIndex(v169_)
		self:addFieldInfoKeyValue(g_i18n:getText("statistic_fillType"), v172_.fillType.title)
		local v173_ = nil
		if v172_:getIsCut(v170_) then
			v173_ = g_i18n:getText("ui_growthMapCut")
		elseif v172_:getIsWithered(v170_) then
			v173_ = g_i18n:getText("ui_growthMapWithered")
		elseif v172_:getIsGrowing(v170_) then
			v173_ = g_i18n:getText("ui_growthMapGrowing")
			v171_ = true
		elseif v172_:getIsPreparable(v170_) then
			v173_ = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
			v171_ = true
		elseif v172_:getIsHarvestable(v170_) then
			v173_ = g_i18n:getText("ui_growthMapReadyToHarvest")
			v171_ = true
		end
		if v173_ ~= nil then
			self:addFieldInfoKeyValue(g_i18n:getText("ui_mapOverviewGrowth"), v173_)
		end
	end
	local v174_ = g_currentMission.fieldGroundSystem
	if v171_ then
		local v175_ = v160_:getHarvestScaleMultiplier() - 1
		local v176_ = MathUtil.round(v175_ * 100)
		self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_yieldBonus"), string.format("+ %d %%", v176_))
	end
	if v160_.sprayLevel >= 0 then
		local v177_ = v174_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local v178_ = v160_.sprayLevel / v177_
		self:addFieldInfoKeyValue(g_i18n:getText("ui_growthMapFertilized"), string.format("%d %%", v178_ * 100))
	end
	local v179_ = g_currentMission.missionInfo
	if Platform.gameplay.useLimeCounter and (v179_.limeRequired and v160_.limeLevel == 0) then
		self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsLime"))
	end
	if v160_.plowLevel == 0 and v179_.plowingRequiredEnabled then
		self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsPlowing"))
	end
	if Platform.gameplay.useRolling and v160_.rollerLevel > 0 then
		self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsRolling"))
	end
	if g_currentMission.missionInfo.weedsEnabled then
		local v180_ = g_currentMission.weedSystem
		local v181_ = v180_:getFieldInfoStates()
		local v182_ = v160_.weedState
		local v183_ = nil
		if v182_ > 0 then
			local v184_
			if v169_ == nil then
				v184_ = nil
			else
				v184_ = g_fruitTypeManager:getFruitTypeByIndex(v169_)
			end
			if Platform.gameplay.hasWeeder then
				if (v184_ == nil or v184_:getIsWeedable(v170_)) and v180_:getWeederReplacements(false).weed.replacements[v182_] == 0 then
					v183_ = g_i18n:getText("weed_destruction_weeder")
				end
				if v183_ == nil and (v184_ == nil or v184_:getIsHoeable(v170_)) and v180_:getWeederReplacements(true).weed.replacements[v182_] == 0 then
					v183_ = g_i18n:getText("weed_destruction_hoe")
				end
			end
			if v183_ == nil and (v184_ == nil or v184_:getIsGrowing(v170_)) then
				v183_ = g_i18n:getText("weed_destruction_herbicide")
			end
			local v185_ = v181_[v182_]
			if v185_ ~= nil then
				self:addFieldInfoKeyValue(v185_, v183_ or "")
			end
		end
	end
	return true
end

-- Local values: worldX, worldZ
function InGameMenuMapFrame:setTargetPointHotspotPosition(localX, localY)
	local v189_, v190_ = self.ingameMap:localToWorldPos(localX, localY)
	self.aiTargetMapHotspot:setWorldPosition(v189_, v190_)
end

-- Local values: mission
function InGameMenuMapFrame:getCanCancelJob()
	local v192_ = g_currentMission
	local v193_ = self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (self.canCancel and v192_:getHasPlayerPermission("hireAssistant"))
	if v193_ then
		v193_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v193_
end

-- Local values: mission
function InGameMenuMapFrame:getCanCreateJob()
	local v195_ = g_currentMission
	local v196_ = self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (self.canCreateJob and v195_:getHasPlayerPermission("hireAssistant"))
	if v196_ then
		v196_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v196_
end

-- Local values: mission
function InGameMenuMapFrame:getCanGoTo()
	local v198_ = g_currentMission
	local v199_ = self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (self.canGoTo and v198_:getHasPlayerPermission("hireAssistant"))
	if v199_ then
		v199_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v199_
end

-- Local values: mission
function InGameMenuMapFrame:getCanStartJob()
	local v201_ = g_currentMission
	local v202_ = self.mode == InGameMenuMapFrame.AI_MODE_CREATE and (not self:getIsPicking() and v201_:getHasPlayerPermission("hireAssistant"))
	if v202_ then
		v202_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v202_
end

-- Local values: mission
function InGameMenuMapFrame:getCanSkipJobTask()
	local v204_ = g_currentMission
	local v205_ = self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (self.canSkipTask and v204_:getHasPlayerPermission("hireAssistant"))
	if v205_ then
		v205_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v205_
end

function InGameMenuMapFrame:getCanGoBack()
	local v207_ = self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking()
	if v207_ then
		local v208_
		if self.mapOverviewSelector:getState() == InGameMenuMapFrame.AI_WORKER_LIST then
			v208_ = self.currentHotspot ~= nil
		else
			v208_ = false
		end
		v207_ = not v208_
		if v207_ then
			local v209_
			if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
				v209_ = self.selectedFarmland ~= nil
			else
				v209_ = false
			end
			v207_ = not v209_
			if v207_ then
				v207_ = not self.hotspotModeActive
			end
		end
	end
	return v207_
end

-- Local values: showContextButtons
function InGameMenuMapFrame:setAIInputContext(canGoTo, canCreateJob, canCancel, canSkipTask, canEnter, canReset, canSell, isVehicleContext)
	self.canGoTo = canGoTo
	self.canCreateJob = canCreateJob
	self.canCancel = canCancel
	self.canSkipTask = canSkipTask
	if self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST then
		isVehicleContext = false
	elseif isVehicleContext then
		isVehicleContext = not g_guidedTourManager:getIsTourRunning()
	end
	self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].isActive = isVehicleContext and canEnter
	self.contextActions[InGameMenuMapFrame.ACTIONS.RESET_VEHICLE].isActive = isVehicleContext and canReset
	self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].isActive = isVehicleContext and canSell
	self:updateContextInputBarVisibility()
end

function InGameMenuMapFrame:setMapInputContext(canEnter, canReset, canSellVehicle, canVisit, canSetMarker, removeMarker, canBuy, canSell, canManage)
	self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].isActive = canEnter
	self.contextActions[InGameMenuMapFrame.ACTIONS.RESET_VEHICLE].isActive = canReset
	self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].isActive = canSellVehicle
	self.contextActions[InGameMenuMapFrame.ACTIONS.BUY].isActive = canBuy
	self.contextActions[InGameMenuMapFrame.ACTIONS.SELL].isActive = canSell
	self.contextActions[InGameMenuMapFrame.ACTIONS.VISIT_PLACE].isActive = canVisit
	self.contextActions[InGameMenuMapFrame.ACTIONS.SET_MARKER].isActive = canSetMarker
	self.contextActions[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER].isActive = removeMarker
	self.contextActions[InGameMenuMapFrame.ACTIONS.MANAGE].isActive = canManage
	self:updateContextInputBarVisibility()
end
function InGameMenuMapFrame.refreshContextInput()
	-- failed to decompile
end

-- Local values: mission, currentInputHelpMode, isSelectAvailable, isPicking, isButtonEnabled
function InGameMenuMapFrame:updateContextInputBarVisibility()
	local v230_ = g_currentMission
	local v231_ = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
	local v232_ = self:getIsPicking()
	local v233_ = self.buttonSelectIngame
	if v231_ then
		v231_ = v232_ or self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW
	end
	v233_:setVisible(v231_)
	local v234_ = not v230_.paused and (self.mode ~= InGameMenuMapFrame.AI_MODE_WORKER_LIST and not g_guidedTourManager:getIsTourRunning()) and true or false
	self.contextActions[InGameMenuMapFrame.ACTIONS.GOTO_JOB].isActive = self:getCanGoTo() and v234_
	self.contextActions[InGameMenuMapFrame.ACTIONS.CREATE_JOB].isActive = self:getCanCreateJob() and v234_
	self.contextActions[InGameMenuMapFrame.ACTIONS.START_JOB].isActive = self:getCanStartJob() and v234_
	self.contextActions[InGameMenuMapFrame.ACTIONS.CANCEL_JOB].isActive = self:getCanCancelJob() and v234_
	self.contextActions[InGameMenuMapFrame.ACTIONS.SKIP_TASK].isActive = self:getCanSkipJobTask() and v234_
	self.contextButtonList:reloadData()
	self.contextButtonListFarmland:reloadData()
	self.contextButtonList:setHandleFocus(self.contextButtonList:getItemCount() > 0)
	self.contextButtonListFarmland:setHandleFocus(self.contextButtonListFarmland:getItemCount() > 0)
end

function InGameMenuMapFrame:setInGameMap(ingameMap)
	self.ingameMapBase = ingameMap
	self.ingameMap:setIngameMap(ingameMap)
	if ingameMap ~= nil then
		self.customFilterFarmlands = ingameMap:createCustomFilter(false)
	end
end

function InGameMenuMapFrame:setTerrainSize(terrainSize)
	self.ingameMap:setTerrainSize(terrainSize)
end

function InGameMenuMapFrame:setClient(client)
	self.client = client
end

function InGameMenuMapFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
end

-- Local values: hotspot
function InGameMenuMapFrame:setAIVehicle(vehicle)
	local v245_ = vehicle:getMapHotspot()
	self:setMapSelectionItem(v245_)
	self.ingameMap:panToHotspot(v245_)
	self:onCreateJob()
	self.createJobEmptyText:setVisible(false)
end

function InGameMenuMapFrame:resetUIDeadzones()
	self.ingameMap:clearCursorDeadzones()
	self.ingameMap:addCursorDeadzone(0, 0, self.filterBox.absPosition[1] + self.filterBox.absSize[1], 1)
	self.ingameMap:addCursorDeadzone(0, 0, 1, self.buttonBox.absSize[2])
	self.ingameMap.zoomMin = (g_screenHeight - g_screenHeight * self.buttonBox.absSize[2]) / (g_screenWidth - g_screenWidth * (self.filterBox.absPosition[1] + self.filterBox.absSize[1]))
end

function InGameMenuMapFrame:setupMapOverview()
	self.mapSelectorTexts = {}
	local v248_ = self.mapSelectorTexts
	local v249_ = string.format
	local v250_ = g_i18n:getText("ui_mapOverviewFruitTypes")
	table.insert(v248_, v249_(v250_, ""))
	local v251_ = self.mapSelectorTexts
	local v252_ = g_i18n
	table.insert(v251_, v252_:getText("ui_mapOverviewGrowth"))
	local v253_ = self.mapSelectorTexts
	local v254_ = g_i18n
	table.insert(v253_, v254_:getText("ui_mapOverviewSoil"))
	local v255_ = self.mapSelectorTexts
	local v256_ = g_i18n
	table.insert(v255_, v256_:getText("ui_mapOverviewHotspots"))
	local v257_ = self.mapSelectorTexts
	local v258_ = g_i18n
	table.insert(v257_, v258_:getText("ui_farmlandScreen"))
	local v259_ = self.mapSelectorTexts
	local v260_ = g_i18n
	table.insert(v259_, v260_:getText("button_createJob"))
	local v261_ = self.mapSelectorTexts
	local v262_ = g_i18n
	table.insert(v261_, v262_:getText("ui_activeAIJobs"))
	self.mapOverviewSelector:setTexts(self.mapSelectorTexts)
	self.isMapOverviewInitialized = true
end

function InGameMenuMapFrame:onOverviewOverlayFinished(overlayId)
	self.foliageStateOverlay = overlayId
	self.foliageStateOverlayIsReady = true
	self.dynamicMapImageLoadingBg:setVisible(false)
end

function InGameMenuMapFrame:onFarmlandOverlayFinished(overlayId)
	self.farmlandStateOverlay = overlayId
	self.farmlandStateOverlayIsReady = true
	self.dynamicMapImageLoadingBg:setVisible(false)
end

-- Local values: mapOverlayGenerator, state
function InGameMenuMapFrame:generateOverviewOverlay()
	if self.isMapOverviewInitialized then
		if self.foliageStateOverlay == nil then
			self.foliageStateOverlayIsReady = false
		end
		self.dynamicMapImageLoadingBg:setVisible(true)
		local v268_ = g_currentMission.mapOverlayGenerator
		if v268_ ~= nil then
			local v269_ = self.mapOverviewSelector:getState()
			if v269_ == InGameMenuMapFrame.MAP_FRUIT_TYPE or InGameMenuMapFrame.MAP_HOTSPOTS <= v269_ then
				v268_:generateFruitTypeOverlay(self.overviewOverlayFinishedCallback, self.fruitTypeFilter)
				return
			end
			if v269_ == InGameMenuMapFrame.MAP_GROWTH then
				v268_:generateGrowthStateOverlay(self.overviewOverlayFinishedCallback, self.growthStateFilter, self.fruitTypeFilter)
				return
			end
			if v269_ == InGameMenuMapFrame.MAP_SOIL then
				v268_:generateSoilStateOverlay(self.overviewOverlayFinishedCallback, self.soilStateFilter)
			end
		end
	end
end

-- Local values: mapOverlayGenerator
function InGameMenuMapFrame:generateFarmlandOverlay(selectedFarmland)
	local v272_ = g_currentMission.mapOverlayGenerator
	if v272_ ~= nil then
		if self.isMapOverviewInitialized then
			if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
				v272_:generateFarmlandOverlay(self.farmlandOverlayFinishedCallback, selectedFarmland)
				return
			elseif selectedFarmland == nil then
				self.farmlandStateOverlayIsReady = false
			else
				v272_:generateSingleFarmlandOverlay(self.farmlandOverlayFinishedCallback, selectedFarmland)
			end
		end
		self.farmlandStateOverlayIsReady = false
	end
end

-- Local values: icon
function InGameMenuMapFrame:onDrawPostIngameMapHotspots()
	if self.currentContextBox ~= nil then
		InGameMenuMapUtil.updateContextBoxPosition(self.currentContextBox, self.currentHotspot)
	end
	if self.aiTargetMapHotspot ~= nil then
		local v274_ = self.aiTargetMapHotspot.icon
		self.actionMessage:setAbsolutePosition(self.aiTargetMapHotspot.lastScreenPositionX + v274_.width * 0.5, self.aiTargetMapHotspot.lastScreenPositionY + v274_.height * 0.5)
	end
end

-- Local values: x, _, mission, isPlaceable, isVehicle, isFarmland, isPlayer, canEnter, canReset, canSellVehicle, canVisit, canSetMarker, removeMarker, canBuy, canSell, canManage, name, imageFilename, uvs, vehicle, farmId, playerName, showContextBox, player, job, x, z, rot, unloadingStation, placeable, unloadingHotspot, x, z, loadingStation, placeable, loadingHotspot, x, z, placeable, productionPoint, ownerFarmId, ownerFarmId, ownerFarmId, playerIsFarmManager, isButtonEnabled, contextBox, contextButtonList, state, focusChanged
function InGameMenuMapFrame:setMapSelectionItem(hotspot)
	if hotspot ~= nil then
		local v277_, _ = hotspot:getWorldPosition()
		if v277_ == nil then
			hotspot = nil
		end
	end
	if self.ingameMapBase ~= nil then
		self.ingameMapBase:setSelectedHotspot(hotspot)
	end
	self.selectedFarmland = nil
	local v278_ = g_currentMission
	local v279_ = false
	local v280_ = false
	local v281_ = false
	local v282_ = false
	local v283_ = false
	local v284_ = false
	local v285_ = false
	local v286_ = false
	local v287_ = false
	local v288_ = false
	local v289_ = false
	local v290_ = false
	local v291_ = false
	local v292_ = nil
	local v293_ = nil
	local v294_ = nil
	local v295_ = nil
	local v296_ = nil
	if not (self.isPickingLocation or self.isPickingRotation) then
		v278_:removeMapHotspot(self.aiTargetMapHotspot)
		v278_:removeMapHotspot(self.aiLoadingMarkerHotspot)
		v278_:removeMapHotspot(self.aiUnloadingMarkerHotspot)
	end
	local v297_ = hotspot ~= nil
	if hotspot == nil then
		if self.currentHotspot ~= nil then
			self.needsOverlayUpdate = true
		end
		self.currentHotspot = nil
	else
		local v298_ = InGameMenuMapUtil.getHotspotVehicle(hotspot)
		if hotspot:isa(PlayerHotspot) then
			local v299_ = hotspot:getPlayer()
			if v299_ ~= nil then
				v296_ = v299_:getNickname()
				v295_ = v299_:getFarmId()
			end
		end
		if hotspot:isa(PlayerHotspot) and v298_ == nil then
			if v278_.missionDynamicInfo.isMultiplayer then
				self.currentHotspot = hotspot
				v282_ = true
			else
				self.currentHotspot = nil
				v297_ = false
			end
		elseif v298_ == nil then
			if hotspot:isa(PlaceableHotspot) then
				v292_ = hotspot:getName()
				if v292_ ~= nil then
					local v300_ = hotspot:getPlaceable()
					if v300_ == nil or not v300_:getIsBeingDeleted() then
						if v300_ ~= nil then
							v295_ = v300_:getOwnerFarmId()
							v293_ = v300_:getImageFilename()
							v294_ = Overlay.DEFAULT_UVS
							v279_ = v300_.customImageFilename == nil
							if g_currentMission.accessHandler:canPlayerAccess(v300_) then
								v291_ = SpecializationUtil.hasSpecialization(PlaceableProductionPoint, v300_.specializations)
								v290_ = v300_:canBeSold() and v300_.storeItem.canBeSold
								if v290_ then
									if g_currentMission:getFarmId() == v295_ then
										v290_ = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_PLACEABLE)
									else
										v290_ = false
									end
								end
								if v300_.spec_productionPoint == nil then
									if v300_.spec_factory ~= nil then
										if v300_:getOwnerFarmId() == AccessHandler.EVERYONE then
											v289_ = true
										else
											v289_ = false
										end
									end
								else
									local v301_ = v300_.spec_productionPoint.productionPoint
									v295_ = v301_:getOwnerFarmId()
									local _ = v300_.spec_productionPoint.isFinalized
									if v295_ == AccessHandler.EVERYONE then
										v289_ = v301_.useInteractionTriggerForBuying
									else
										v289_ = false
									end
								end
							end
						end
						v287_ = v278_.currentMapTargetHotspot ~= hotspot
						v288_ = v278_.currentMapTargetHotspot == hotspot
						v286_ = hotspot:getBeVisited()
						self.currentHotspot = hotspot
					else
						self.currentHotspot = nil
						v297_ = false
					end
				end
			elseif hotspot:isa(NPCHotspot) then
				v292_ = hotspot:getName()
				v293_ = hotspot:getImageFilename()
				v286_ = hotspot:getBeVisited()
				v294_ = Overlay.DEFAULT_UVS
				v287_ = v278_.currentMapTargetHotspot == hotspot
				v288_ = v278_.currentMapTargetHotspot == hotspot
				self.currentHotspot = hotspot
			elseif hotspot:isa(FarmlandHotspot) then
				if hotspot ~= self.currentHotspot then
					self.needsOverlayUpdate = true
				end
				v281_ = true
				self.currentHotspot = hotspot
				self.selectedFarmland = hotspot:getFarmland()
				local v302_ = g_farmlandManager:getFarmlandOwner(self.selectedFarmland.id)
				local v303_ = v278_:getHasPlayerPermission("farmManager")
				if g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID then
					if v302_ == FarmlandManager.NO_OWNER_FARM_ID then
						if v303_ then
							v289_ = self.selectedFarmland.showOnFarmlandsScreen
						else
							v289_ = v303_
						end
					else
						v289_ = false
					end
					if v302_ == self.playerFarm.farmId then
						if v303_ then
							v290_ = self.selectedFarmland.showOnFarmlandsScreen
						else
							v290_ = v303_
						end
					else
						v290_ = false
					end
				end
				v287_ = v278_.currentMapTargetHotspot ~= hotspot
				v288_ = v278_.currentMapTargetHotspot == hotspot
				v286_ = true
			end
		else
			v295_ = v298_:getOwnerFarmId()
			v292_ = v298_:getName()
			v293_ = v298_:getImageFilename()
			v294_ = Overlay.DEFAULT_UVS
			self.currentHotspot = hotspot
			if v278_.tourIconsBase == nil or not v278_.tourIconsBase.visible then
				if v298_.getIsEnterableFromMenu == nil then
					v283_ = false
				else
					v283_ = v298_:getIsEnterableFromMenu()
				end
				if not self.isResetPending and (v298_:getCanBeReset() and hotspot:getCategory() ~= MapHotspot.CATEGORY_AI) then
					v284_ = true
				end
			end
			v280_ = true
			if v298_.spec_rideable == nil then
				self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].text = "button_enterVehicle"
			else
				self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].text = "action_rideAnimal"
			end
			if v278_:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and (v295_ == self.playerFarm.farmId and v298_:getCanBeSold()) then
				v285_ = v298_.propertyState ~= VehiclePropertyState.MISSION
				if v298_.propertyState == VehiclePropertyState.LEASED then
					self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_return"
				else
					self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_sell"
				end
			end
			if v298_.getJob ~= nil then
				local v304_ = v298_:getJob()
				if v304_ ~= nil then
					if v304_.getTarget ~= nil and v304_:getShowTarget() then
						local v305_, v306_, v307_ = v304_:getTarget()
						self.aiTargetMapHotspot:setWorldPosition(v305_, v306_)
						if v307_ ~= nil then
							self.aiTargetMapHotspot:setWorldRotation(v307_ + 3.141592653589793)
						end
						v278_:addMapHotspot(self.aiTargetMapHotspot)
					end
					if v304_.unloadingStationParameter ~= nil then
						local v308_ = v304_.unloadingStationParameter:getUnloadingStation()
						if v308_ ~= nil then
							local v309_ = v308_.owningPlaceable
							if v309_ ~= nil and v309_.getHotspot ~= nil then
								local v310_, v311_ = v309_:getHotspot(1):getWorldPosition()
								self.aiUnloadingMarkerHotspot:setWorldPosition(v310_, v311_)
								if not self.isLoadingStationParameterClick then
									self.ingameMap:panToHotspot(self.aiUnloadingMarkerHotspot)
								end
								v278_:addMapHotspot(self.aiUnloadingMarkerHotspot)
							end
						end
					end
					if v304_.loadingStationParameter ~= nil then
						local v312_ = v304_.loadingStationParameter:getLoadingStation()
						if v312_ ~= nil then
							local v313_ = v312_.owningPlaceable
							if v313_ ~= nil and v313_.getHotspot ~= nil then
								local v314_, v315_ = v313_:getHotspot(1):getWorldPosition()
								self.aiLoadingMarkerHotspot:setWorldPosition(v314_, v315_)
								if not self.isLoadAndDeliverParameter then
									self.ingameMap:panToHotspot(self.aiLoadingMarkerHotspot)
								end
								v278_:addMapHotspot(self.aiLoadingMarkerHotspot)
							end
						end
					end
				end
			end
		end
	end
	local v316_ = not v278_.paused and (self.mode ~= InGameMenuMapFrame.AI_MODE_WORKER_LIST and not g_guidedTourManager:getIsTourRunning()) and true or false
	self:setMapInputContext(v283_ and v316_, v284_ and v316_, v285_ and v316_, v286_ and v316_, v287_, v288_, v289_ and v316_, v290_ and v316_, v291_ and v316_)
	self:refreshContextInput()
	if v297_ then
		InGameMenuMapUtil.hideContextBox(self.contextBox)
		InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
		InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
		local v317_ = self.contextBox
		local v318_ = self.contextButtonList
		if v282_ then
			v317_ = self.contextBoxPlayer
			InGameMenuMapUtil.showPlayerContextBox(v317_, v296_, v295_)
		else
			if v281_ then
				v317_ = self.contextBoxFarmland
				v318_ = self.contextButtonListFarmland
			elseif self.mapOverviewSelector:getState() <= InGameMenuMapFrame.MAP_HOTSPOTS then
				self:setHotspotModeActive(true)
			end
			InGameMenuMapUtil.showContextBox(v317_, hotspot, v292_, v293_, v294_, v295_, v296_, v279_, v280_, v281_)
		end
		self.currentContextBox = v317_
		if self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW or self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST and (self.activeWorkerList:getItemCount() == 0 and not v282_) then
			FocusManager:setFocus(v318_)
		end
	else
		if self.hotspotModeActive then
			self:setHotspotModeActive(false)
		end
		local v319_ = self.mapOverviewSelector:getState()
		local v320_ = not self.currentContextBox:getIsVisible()
		InGameMenuMapUtil.hideContextBox(self.contextBox)
		InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
		InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
		if v319_ == InGameMenuMapFrame.AI_WORKER_LIST then
			self.blockListSelectionUpdates = true
			v320_ = FocusManager:setFocus(self.activeWorkerList) or FocusManager:getFocusedElement() == self.activeWorkerList
			self.blockListSelectionUpdates = false
		elseif InGameMenuMapFrame.MAP_HOTSPOTS < v319_ then
			v320_ = FocusManager:setFocus(self.jobMenuLayout) or FocusManager:getFocusedElement() == self.jobMenuLayout
		end
		if not v320_ then
			FocusManager:setFocus(self.mapOverviewSelector)
		end
	end
	self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
end

function InGameMenuMapFrame:showMapHotspot(hotspot)
	self:onClickHotspot(nil, hotspot)
	self.ingameMap:panToHotspot(hotspot)
end

function InGameMenuMapFrame:setHotspotModeActive(isActive)
	self.hotspotModeActive = isActive
	self.filterList:setHandleFocus(not isActive)
	self.filterList.selectedWithoutFocus = not isActive
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.SWITCH_VEHICLE, isActive)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.SWITCH_VEHICLE_BACK, isActive)
	self:updateInputGlyphs()
	if isActive then
		self.blockHotspotModeUpdate = true
		self.mapOverviewSelector:setState(InGameMenuMapFrame.MAP_HOTSPOTS, true)
		self.blockHotspotModeUpdate = false
	else
		self.filterList:setSelectedIndex(self.filterList.selectedSectionIndex)
		if self.currentHotspot ~= nil and self.mode ~= InGameMenuMapFrame.AI_MODE_CREATE then
			self:setMapSelectionItem(nil)
		end
	end
end

-- Local values: targetButtonTop, targetButtonBottom, _, elem
function InGameMenuMapFrame:updateMapSelectionFilterNavigation()
	local v326_ = nil
	local v327_ = nil
	if self.mapSelectionPreviousItem.visible then
		v326_ = self.mapSelectionPreviousItem
	elseif self.mapSelectionNextItem.visible then
		v326_ = self.mapSelectionNextItem
	end
	if v327_ == nil then
		if self.mapSelectionEnter.visible then
			v327_ = self.mapSelectionEnter
		elseif self.mapSelectionReset.visible then
			v327_ = self.mapSelectionReset
		elseif self.mapSelectionVisit.visible then
			v327_ = self.mapSelectionVisit
		elseif self.mapSelectionTag.visible then
			v327_ = self.mapSelectionTag
		end
	end
	local v328_ = Utils.getNoNil(v326_, self.mapSelectionPreviousItem)
	local v329_ = Utils.getNoNil(v327_, self.mapSelectionEnter)
	for _, v330_ in pairs(self.mapOverviewFilters) do
		v330_.focusChangeData[FocusManager.BOTTOM] = v328_.focusId
	end
	v328_.focusChangeData[FocusManager.BOTTOM] = v329_.focusId
	v329_.focusChangeData[FocusManager.TOP] = v328_.focusId
end

function InGameMenuMapFrame:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive
		self.filterList:reloadData()
		self:generateOverviewOverlay()
	end
end

function InGameMenuMapFrame:showActionMessage(locaKey)
	if locaKey == nil then
		self.actionMessage:setVisible(false)
	else
		self.actionMessage:setVisible(true)
		self.actionMessage:setLocaKey(locaKey)
	end
end

-- Local values: mission, aiJobTypeManager, _, jobType
function InGameMenuMapFrame:generateJobTypes()
	local v336_ = g_currentMission.aiJobTypeManager
	for _, v337_ in pairs(AIJobType) do
		self.jobTypeInstances[v337_] = v336_:createJob(v337_)
	end
end

-- Local values: job, success, errorMessage, callback
function InGameMenuMapFrame:startGoToJob(vehicle, destX, destZ, angle)
	local v343_ = self.jobTypeInstances[AIJobType.GOTO]
	v343_.vehicleParameter:setVehicle(vehicle)
	v343_.positionAngleParameter:setPosition(destX, destZ)
	v343_.positionAngleParameter:setAngle(angle)
	v343_:setValues()
	local v344_, v345_ = v343_:validate(g_localPlayer.farmId)
	if v344_ then
		self:tryStartJob(v343_, g_localPlayer.farmId, function(p346_)
			-- upvalues: (copy) self
			if p346_ == AIJob.START_SUCCESS then
				local v347_ = g_currentMission.aiJobTypeManager
				self.jobTypeInstances[AIJobType.GOTO] = v347_:createJob(AIJobType.GOTO)
				self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
				self:refreshContextInput()
			end
		end)
		return true
	else
		InfoDialog.show(tostring(v345_), nil, nil, DialogElement.TYPE_WARNING)
		return false
	end
end

-- Local values: success, errorMessage, callback
function InGameMenuMapFrame:startJob()
	if self.startJobPending then
		return
	else
		self.currentJob:setValues()
		local v349_, v350_ = self.currentJob:validate(g_localPlayer.farmId)
		if v349_ then
			self:tryStartJob(self.currentJob, g_localPlayer.farmId, function(p351_)
				-- upvalues: (copy) self
				if p351_ == AIJob.START_SUCCESS then
					self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
					self.currentJob = nil
					self:setJobMenuVisible(false)
					self:refreshContextInput()
				end
			end)
		else
			InfoDialog.show(tostring(v350_), nil, nil, DialogElement.TYPE_WARNING)
			self:updateWarnings()
		end
	end
end

-- Local values: vehicle, mission
function InGameMenuMapFrame:cancelJob()
	local v353_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if v353_ ~= nil and v353_:getIsAIActive() then
		v353_:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
		g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	end
end

-- Local values: i, mission, farmId, _, group, titleElement, invalidElement, index, item, element, parameterType
function InGameMenuMapFrame:setActiveJobTypeSelection(jobTypeIndex)
	if self.currentJob == nil or jobTypeIndex ~= self.currentJob.jobTypeIndex then
		for v356_ = #self.jobMenuLayout.elements, 1, -1 do
			self.jobMenuLayout.elements[v356_]:delete()
		end
		local v357_ = g_currentMission
		self.currentJob = v357_.aiJobTypeManager:createJob(jobTypeIndex)
		local v358_ = g_localPlayer == nil and 1 or g_localPlayer.farmId
		self.currentJob:applyCurrentState(self.currentJobVehicle, v357_, v358_, false)
		self.currentJobElements = {}
		for _, v359_ in ipairs(self.currentJob:getGroupedParameters()) do
			self.createTitleTemplate:clone(self.jobMenuLayout):setText(v359_:getTitle())
			local v360_ = nil
			for v361_, v362_ in ipairs(v359_:getParameters()) do
				local v363_ = nil
				local v364_ = v362_:getType()
				if v364_ == AIParameterType.TEXT then
					v363_ = self.createTextTemplate:clone(self.jobMenuLayout)
				elseif v364_ == AIParameterType.POSITION then
					v363_ = self.createPositionTemplate:clone(self.jobMenuLayout)
					v363_:updateAbsolutePosition()
				elseif v364_ == AIParameterType.POSITION_ANGLE then
					v363_ = self.createPositionRotationTemplate:clone(self.jobMenuLayout)
					v363_:updateAbsolutePosition()
				elseif v364_ == AIParameterType.SELECTOR or (v364_ == AIParameterType.UNLOADING_STATION or (v364_ == AIParameterType.LOADING_STATION or v364_ == AIParameterType.FILLTYPE)) then
					v363_ = self.createMultiOptionTemplate:clone(self.jobMenuLayout)
					v363_:setDataSource(v362_)
					if v361_ == 1 then
						v360_ = v363_:getDescendantByName("invalid")
					else
						v363_:getDescendantByName("invalid"):setPosition(v360_.absPosition[1], v360_.absPosition[2])
					end
				end
				v363_.aiParameter = v362_
				v363_:setDisabled(not v362_:getCanBeChanged())
				local v365_ = self.currentJobElements
				table.insert(v365_, v363_)
			end
		end
		self:updateParameterValueTexts()
		self:validateParameters()
		self.jobMenuLayout:invalidateLayout()
		FocusManager:setFocus(self.jobTypeElement)
	end
	self:refreshContextInput()
end

-- Local values: farm, moneyText
function InGameMenuMapFrame:onMoneyChange()
	if g_localPlayer ~= nil then
		local v367_ = g_farmManager:getFarmById(g_localPlayer.farmId)
		if v367_.money <= -1 then
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
		else
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
		end
		local v368_ = g_i18n:formatMoney(v367_.money, 0, true, false)
		self.currentBalanceText:setText(v368_)
		if self.shopMoneyBox ~= nil then
			self.shopMoneyBox:invalidateLayout()
			self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
		end
	end
end

-- Local values: selectedVehicle
function InGameMenuMapFrame:onAIVehicleStateChanged(isActive, vehicle)
	if vehicle ~= nil and (self.currentHotspot ~= nil and InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot) == vehicle) then
		self:refreshContextInput()
	end
end

-- Local values: playerHotspot, vehicleHotspot
function InGameMenuMapFrame:onVehicleEntered(vehicle, player)
	if self.currentHotspot == nil then
		return
	else
		local v374_
		if player == nil then
			v374_ = false
		else
			v374_ = player.playerHotspot
		end
		local v375_
		if vehicle == nil then
			v375_ = false
		else
			v375_ = vehicle.mapHotspot
		end
		if self.currentHotspot == v374_ then
			self:setMapSelectionItem(v374_)
		elseif self.currentHotspot == v375_ then
			self:setMapSelectionItem(v374_)
		end
	end
end

-- Local values: playerHotspot
function InGameMenuMapFrame:onVehicleLeft(vehicle, player)
	if self.currentHotspot ~= nil then
		local v378_
		if player == nil then
			v378_ = false
		else
			v378_ = player.playerHotspot
		end
		if self.currentHotspot == v378_ then
			self:setMapSelectionItem(v378_)
		end
	end
end

function InGameMenuMapFrame:onAITaskSkipped()
	self:refreshContextInput()
end

-- Local values: width, height, x, y, overlayX, overlayY
function InGameMenuMapFrame:onDrawPostIngameMap(element, ingameMap)
	if not self.hideContentOverlay then
		local v381_, v382_ = self.ingameMapBase.fullScreenLayout:getMapSize()
		local v383_, v384_ = self.ingameMapBase.fullScreenLayout:getMapPosition()
		local v385_ = v383_ + v381_ * 0.25
		local v386_ = v384_ + v382_ * 0.25
		if self.foliageStateOverlay ~= nil and (self.foliageStateOverlay ~= 0 and self.foliageStateOverlayIsReady) then
			renderOverlay(self.foliageStateOverlay, v385_, v386_, v381_ * 0.5, v382_ * 0.5)
		end
		if self.farmlandStateOverlay ~= nil and (self.farmlandStateOverlay ~= 0 and self.farmlandStateOverlayIsReady) then
			renderOverlay(self.farmlandStateOverlay, v385_, v386_, v381_ * 0.5, v382_ * 0.5)
		end
	end
end

-- Local values: _, hotspot, vehicle, farms, localPlayerFarm, index, farm
function InGameMenuMapFrame:onClickMapOverviewSelector(state)
	self:generateOverviewOverlay()
	if self.previousSubCategoryState <= InGameMenuMapFrame.MAP_HOTSPOTS then
		if self.hotspotModeActive and not self.blockHotspotModeUpdate then
			self:setHotspotModeActive(false)
		end
	elseif self.previousSubCategoryState == InGameMenuMapFrame.MAP_FARMLANDS then
		self.filterList:setHandleFocus(true)
		self.filterList.showHighlights = true
		self.filterList.selectedWithoutFocus = true
	end
	if state <= InGameMenuMapFrame.MAP_HOTSPOTS then
		self.filterList:reloadData()
	end
	if self.numSelectedFilters[state] == 0 then
		self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
	else
		self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
	end
	self.buttonDeselectAllContainer:setVisible(state <= InGameMenuMapFrame.MAP_HOTSPOTS)
	self.filterListContainer:setVisible(state <= InGameMenuMapFrame.MAP_FARMLANDS)
	self.createJobEmptyText:setVisible(state == InGameMenuMapFrame.AI_CREATE_JOB)
	self.workerListContainer:setVisible(state == InGameMenuMapFrame.AI_WORKER_LIST)
	if self:getIsPicking() then
		self:executePickingCallback(false)
		self:refreshContextInput()
	end
	if state ~= InGameMenuMapFrame.AI_CREATE_JOB and not self.hotspotModeActive then
		self:setMapSelectionItem(nil)
	end
	for _, v389_ in pairs(self.ingameMap.ingameMap.hotspots) do
		if v389_:isa(VehicleHotspot) or v389_:isa(AIHotspot) then
			if state == InGameMenuMapFrame.AI_CREATE_JOB then
				v389_.oldVisibility = v389_:getIsVisible()
				local v390_ = v389_:getVehicle()
				local v391_ = v389_.getVehicle ~= nil and v390_.spec_aiJobVehicle ~= nil and v390_.spec_aiJobVehicle.supportsAIJobs
				if v391_ then
					v391_ = v390_:getJob() ~= nil == v389_:isa(AIHotspot)
				end
				v389_:setVisible(v391_)
			elseif self.previousSubCategoryState == InGameMenuMapFrame.AI_CREATE_JOB then
				v389_:setVisible(v389_.oldVisibility)
			end
		end
	end
	if state == InGameMenuMapFrame.MAP_FARMLANDS then
		self.farmlandItems = {}
		local v392_ = g_farmManager:getFarms()
		local v393_ = g_farmManager:getFarmByUserId(g_localPlayer.userId)
		local v394_ = self.farmlandItems
		local v395_ = {
			["name"] = g_i18n:getText("ui_farmlandUnowned"),
			["color"] = MapOverlayGenerator.COLOR.FIELD_UNOWNED
		}
		table.insert(v394_, v395_)
		local v396_ = self.farmlandItems
		local v397_ = {
			["name"] = g_i18n:getText("ui_farmlandsCurrentlySelected"),
			["color"] = MapOverlayGenerator.COLOR.FIELD_SELECTED
		}
		table.insert(v396_, v397_)
		local v398_ = self.farmlandItems
		local v399_ = {
			["name"] = v393_.name,
			["color"] = v393_:getColor()
		}
		table.insert(v398_, v399_)
		for _, v400_ in pairs(v392_) do
			if v400_ ~= v393_ and v400_.showInFarmScreen then
				local v401_ = self.farmlandItems
				local v402_ = {
					["name"] = v400_.name,
					["color"] = v400_:getColor()
				}
				table.insert(v401_, v402_)
			end
		end
		self.filterList:reloadData()
		self.filterList:setHandleFocus(false)
		self.filterList.showHighlights = false
		self.filterList.selectedWithoutFocus = false
		self.filterList:setSelectedIndex(1)
		self.needsOverlayUpdate = true
		self.isShowingFarmlandsOverlay = true
	elseif self.isShowingFarmlandsOverlay then
		self.needsOverlayUpdate = true
		self.isShowingFarmlandsOverlay = false
	end
	self.previousSubCategoryState = state
end

-- Local values: worldX, worldZ, angle
function InGameMenuMapFrame:onClickHotspot(element, hotspot)
	local v405_ = hotspot.worldX
	local v406_ = hotspot.worldZ
	if self.isPickingLocation then
		self:executePickingCallback(true, v405_, v406_)
	elseif self.isPickingRotation then
		local v407_ = v405_ - self.pickingRotationOrigin[1]
		local v408_ = v406_ - self.pickingRotationOrigin[2]
		self:executePickingCallback(true, (math.atan2(v407_, v408_)))
	elseif self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and (self.currentHotspot ~= hotspot and hotspot ~= self.anywhereHotspot) then
		self:setMapSelectionItem(hotspot)
	end
	self:refreshContextInput()
end

-- Local values: angle, farmland
function InGameMenuMapFrame:onClickMap(element, worldX, worldZ)
	if self.isPickingLocation then
		self:executePickingCallback(true, worldX, worldZ)
		return
	elseif self.isPickingRotation then
		local v412_ = worldX - self.pickingRotationOrigin[1]
		local v413_ = worldZ - self.pickingRotationOrigin[2]
		self:executePickingCallback(true, (math.atan2(v412_, v413_)))
	elseif self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
		local v414_ = g_farmlandManager:getFarmlandAtWorldPosition(worldX, worldZ)
		if v414_ ~= nil and v414_.showOnFarmlandsScreen then
			local v415_
			if v414_ == nil then
				v415_ = nil
			else
				v415_ = v414_:getMapHotspot() or nil
			end
			self:setMapSelectionItem(v415_)
			return
		end
	elseif self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW or self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST then
		self:setMapSelectionItem(nil)
	end
end

function InGameMenuMapFrame:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onPauseChanged(isActive)
	self:setMapSelectionItem(self.currentHotspot)
end

-- Local values: firstHotspot
function InGameMenuMapFrame:selectFirstHotspot()
	self:setMapSelectionItem((self.ingameMapBase:cycleVisibleHotspot(nil, InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES, 1)))
end

function InGameMenuMapFrame:onVehicleReset(state)
	self.isResetPending = false
	g_messageCenter:unsubscribe(ResetVehicleEvent, self)
	if state == ResetVehicleEvent.STATE_SUCCESS then
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_DONE), nil, nil, DialogElement.TYPE_INFO)
		self:selectFirstHotspot()
		return
	elseif state == ResetVehicleEvent.STATE_FAILED then
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_FAILED))
		return
	elseif state == ResetVehicleEvent.STATE_IN_USE then
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_IN_USE))
	else
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_NO_PERMISSION))
	end
end

-- Local values: mission
function InGameMenuMapFrame:onClickResetVehicle()
	local v422_ = g_currentMission
	if not self.isResetPending and (v422_.tourIconsBase == nil or not v422_.tourIconsBase.visible) and self.currentHotspot ~= nil then
		YesNoDialog.show(self.onYesNoReset, self, g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_CONFIRM), g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.VEHICLE_RESET))
	end
	return true
end

-- Local values: npc, x, y, z
function InGameMenuMapFrame:onClickVisitPlace()
	if self.currentHotspot ~= nil then
		if self.currentHotspot:isa(NPCHotspot) then
			local v424_ = self.currentHotspot:getNPC()
			if v424_ ~= nil then
				self.onClickBackCallback()
				if g_localPlayer:getCurrentVehicle() ~= nil then
					g_localPlayer:leaveVehicle()
				end
				g_localPlayer:teleportToNPC(v424_)
			end
		else
			local v425_, v426_, v427_
			if self.currentHotspot:isa(FarmlandHotspot) then
				v425_, v426_ = self.currentHotspot:getWorldPosition()
				v427_ = getTerrainHeightAtWorldPos(g_terrainNode, v425_, 0, v426_)
			else
				v425_, v427_, v426_ = self.currentHotspot:getTeleportWorldPosition()
			end
			if v425_ ~= nil and (v427_ ~= nil and v426_ ~= nil) then
				self.onClickBackCallback()
				if g_localPlayer:getCurrentVehicle() ~= nil then
					g_localPlayer:leaveVehicle()
				end
				g_localPlayer:teleportTo(v425_, v427_, v426_)
			end
		end
	end
	return true
end

-- Local values: mission
function InGameMenuMapFrame:onClickTagPlace()
	if self.currentHotspot ~= nil and (self.currentHotspot.worldX ~= nil and self.currentHotspot.worldZ ~= nil) then
		local v429_ = g_currentMission
		if v429_.currentMapTargetHotspot == self.currentHotspot then
			self.contextActions[InGameMenuMapFrame.ACTIONS.SET_MARKER].isActive = true
			self.contextActions[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER].isActive = false
			v429_:setMapTargetHotspot(nil)
		else
			self.contextActions[InGameMenuMapFrame.ACTIONS.SET_MARKER].isActive = false
			self.contextActions[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER].isActive = true
			v429_:setMapTargetHotspot(self.currentHotspot)
		end
		self:refreshContextInput()
	end
	return true
end

-- Local values: placeable, productionPoint
function InGameMenuMapFrame:onClickManage()
	if self.currentHotspot ~= nil then
		local v431_ = self.currentHotspot:getPlaceable()
		local v432_
		if v431_ == nil or v431_.spec_productionPoint == nil then
			v432_ = nil
		else
			v432_ = v431_.spec_productionPoint.productionPoint
		end
		g_inGameMenu:openProductionScreen(v432_)
	end
end

-- Local values: mission, vehicle
function InGameMenuMapFrame:onClickEnterVehicle()
	if not g_currentMission.isPlayerFrozen then
		local v434_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot) or InGameMenuMapUtil.getHotspotVehicle(self.currentVehicleHotspot)
		if v434_ ~= nil and (v434_.getIsEnterableFromMenu ~= nil and v434_:getIsEnterableFromMenu()) then
			self.onClickBackCallback()
			g_localPlayer:requestToEnterVehicle(v434_)
		end
	end
	return true
end

-- Local values: mission, vehicle, storeItem
function InGameMenuMapFrame:onClickSellVehicle()
	if not g_currentMission.isPlayerFrozen then
		local v436_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot) or InGameMenuMapUtil.getHotspotVehicle(self.currentVehicleHotspot)
		local v437_ = g_storeManager:getItemByXMLFilename(v436_.configFileName)
		g_shopController:sell(v437_, v436_)
		self:setMapSelectionItem(nil)
	end
	return true
end

-- Local values: text, title, callback, target, placeable
function InGameMenuMapFrame:onClickBuy()
	if self.selectedFarmland == nil then
		local v439_ = self.currentHotspot:getPlaceable()
		if v439_ ~= nil then
			if v439_.spec_productionPoint == nil then
				if v439_.spec_factory ~= nil then
					v439_:buyRequest(self.onYesNoBuyOrSellPlaceable, self)
				end
			else
				v439_.spec_productionPoint.productionPoint:buyRequest(self.onYesNoBuyOrSellPlaceable, self)
			end
		end
	else
		if g_missionManager:getIsMissionRunningOnFarmland(self.selectedFarmland) then
			InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_ACTIVE_MISSION))
			return false
		end
		if self.playerFarm:getBalance() >= self.selectedFarmland.price then
			local v440_ = string.format(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND), g_i18n:formatMoney(self.selectedFarmland.price, 0, true, true))
			local v441_ = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE)
			local v442_ = self.onYesNoBuyFarmland
			YesNoDialog.show(v442_, self, v440_, v441_)
		else
			InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY), nil, nil, DialogElement.TYPE_WARNING)
		end
	end
	return true
end

-- Local values: mission, price, text, title, callback, target, placeable, price, forFullPrice, text, callback
function InGameMenuMapFrame:onClickSell()
	if self.selectedFarmland == nil then
		local v_u_444_ = self.currentHotspot:getPlaceable()
		local v445_, v_u_446_ = v_u_444_:getSellPrice()
		local v447_ = string.format(g_i18n:getText("ui_constructionSellConfirmation"), v_u_444_:getName(), g_i18n:formatMoney(v445_, 0, true, true))
		YesNoDialog.show(function(p448_)
			-- upvalues: (copy) v_u_444_, (copy) v_u_446_, (copy) self
			if p448_ then
				g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(v_u_444_, nil, v_u_446_))
			end
			self:onYesNoBuyOrSellPlaceable(p448_)
		end, nil, v447_)
		self:setMapSelectionItem(nil)
	elseif g_currentMission.placeableSystem:getArePlaceablesOnFarmland(g_localPlayer.farmId, self.selectedFarmland.id) then
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_CANNOT_SELL_WTIH_PLACEABLES))
	else
		local v449_ = self.selectedFarmland.price
		local v450_ = string.format(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND), g_i18n:formatMoney(v449_, 0, true, true))
		local v451_ = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND_TITLE)
		local v452_ = self.onYesNoSellFarmland
		YesNoDialog.show(v452_, self, v450_, v451_)
	end
	return true
end

function InGameMenuMapFrame:onClickBack()
	if self:getCanGoBack() then
		self:onClickBackCallback()
	elseif self:getIsPicking() then
		self:executePickingCallback(false)
		self:refreshContextInput()
		self.ingameMap.isTouchPickingRotation = false
		if self.buttonConfirmAITarget ~= nil then
			self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
		end
	elseif self.mode == InGameMenuMapFrame.AI_MODE_CREATE then
		self.currentJob:resetTasks()
		self.currentJobVehicle = nil
		self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
		self:setJobMenuVisible(false)
		self:refreshContextInput()
		FocusManager:setFocus(self.contextButtonList)
	elseif self.hotspotModeActive then
		self:setHotspotModeActive(false)
	elseif self.mapOverviewSelector:getState() == InGameMenuMapFrame.AI_WORKER_LIST and self.currentHotspot ~= nil then
		self:setMapSelectionItem(nil)
	elseif self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS and self.selectedFarmland ~= nil then
		self:setMapSelectionItem(nil)
	end
	return true
end

-- Local values: mission
function InGameMenuMapFrame:onStartGoToJob()
	if not g_currentMission.paused and self:getCanGoTo() then
		self:tryStartGoToJob()
	end
	return true
end

-- Local values: mission
function InGameMenuMapFrame:onStartCancelJob()
	if not g_currentMission.paused then
		if self:getCanCancelJob() then
			self:cancelJob()
		elseif self:getCanStartJob() then
			self:startJob()
		end
	end
	return true
end

-- Local values: mission
function InGameMenuMapFrame:onSkipJobTask()
	if not g_currentMission.paused and self:getCanSkipJobTask() then
		self:skipCurrentTask()
	end
	return true
end

function InGameMenuMapFrame:onPageNext()
	g_inGameMenu:onPageNext()
end

function InGameMenuMapFrame:onPagePrevious()
	g_inGameMenu:onPagePrevious()
end

-- Local values: overviewIndex, selectAll, currentFilterTable, currentFilterState, index, filter, index, filter, hotspotCategory, currentFilterTable, currentFilterState, index, filter, stateIndex, fruitTypeDesc
function InGameMenuMapFrame:onClickDeselectAll(exceptionSection, exceptionIndex)
	if self.hotspotModeActive then
		self:setHotspotModeActive(false)
	end
	local v460_ = self.mapOverviewSelector:getState()
	local v461_ = self.numSelectedFilters[v460_] == 0
	if v461_ then
		self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
		self.numSelectedFilters[v460_] = #self.displayCropTypes
	else
		self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
		self.numSelectedFilters[v460_] = 0
	end
	if v460_ == InGameMenuMapFrame.MAP_HOTSPOTS then
		local v462_ = self.dataTables[v460_][1]
		local v463_ = self.filterStates[v460_][1]
		for v464_, _ in pairs(v462_) do
			if exceptionSection == 1 and exceptionIndex == v464_ then
				v463_[v464_] = not v461_
				self.numSelectedFilters[v460_] = 1
				self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
				self.ingameMapBase:setDefaultFilterValue(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1][v464_].id, not v461_)
			else
				v463_[v464_] = v461_
				self.ingameMapBase:setDefaultFilterValue(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1][v464_].id, v461_)
			end
		end
		local v465_ = self.dataTables[v460_][2]
		local v466_ = self.filterStates[v460_][2]
		for v467_, _ in pairs(v465_) do
			local v468_ = InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[2][v467_].id
			if exceptionSection == 2 and exceptionIndex == v467_ then
				v466_[v467_] = not v461_
				self.numSelectedFilters[v460_] = 1
				self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
				self.ingameMapBase:setDefaultFilterValue(v468_, not v461_)
				if v468_ == MapHotspot.CATEGORY_OTHER then
					self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, not v461_)
				end
			else
				v466_[v467_] = v461_
				self.ingameMapBase:setDefaultFilterValue(v468_, v461_)
				if v468_ == MapHotspot.CATEGORY_OTHER then
					self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, v461_)
				end
			end
		end
	else
		local v469_ = self.dataTables[v460_]
		local v470_ = self.filterStates[v460_]
		for v471_, v472_ in pairs(v469_) do
			local v473_
			if v472_.soilStateIndex == nil then
				v473_ = v471_
			else
				v473_ = v472_.soilStateIndex
			end
			if v460_ == InGameMenuMapFrame.MAP_FRUIT_TYPE then
				v473_ = self.displayCropTypes[v471_].fruitTypeIndex
			end
			if exceptionIndex == v471_ then
				v470_[v473_] = not v461_
				self.numSelectedFilters[v460_] = 1
				self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
			else
				v470_[v473_] = v461_
			end
		end
	end
	self:generateOverviewOverlay()
	self:saveFilters()
end

-- Local values: vehicle
function InGameMenuMapFrame:onYesNoReset(yes)
	if yes then
		if self.currentHotspot ~= nil then
			local v476_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
			if v476_ ~= nil then
				self:setMapSelectionItem(nil)
				g_messageCenter:subscribe(ResetVehicleEvent, self.onVehicleReset, self)
				self.isResetPending = true
				g_client:getServerConnection():sendEvent(ResetVehicleEvent.new(v476_))
				return
			end
		end
	else
		self.elementToFocus = self.contextButtonList
	end
end

-- Local values: price, mission
function InGameMenuMapFrame:onYesNoBuyFarmland(yes)
	if yes then
		local v479_ = self.selectedFarmland.price
		if v479_ <= self.playerFarm:getBalance() then
			local v480_ = g_currentMission
			self.client:getServerConnection():sendEvent(FarmlandStateEvent.new(self.selectedFarmland.id, v480_:getFarmId(), v479_))
			self:setMapSelectionItem()
			InGameMenuMapUtil.hideContextBox(self.contextBox)
			InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
			InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
			return
		end
	else
		self.elementToFocus = self.contextButtonListFarmland
	end
end

-- Local values: price
function InGameMenuMapFrame:onYesNoSellFarmland(yes)
	if yes then
		local v483_ = self.selectedFarmland.price
		self.client:getServerConnection():sendEvent(FarmlandStateEvent.new(self.selectedFarmland.id, FarmlandManager.NO_OWNER_FARM_ID, v483_))
		self:setMapSelectionItem(nil)
		InGameMenuMapUtil.hideContextBox(self.contextBox)
		InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
		InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
	else
		self.elementToFocus = self.contextButtonListFarmland
	end
end

function InGameMenuMapFrame:onYesNoBuyOrSellPlaceable(yes)
	if yes then
		self:setMapSelectionItem(self.currentHotspot)
	end
	if self.currentHotspot == nil then
		self.elementToFocus = self.filterList
	else
		self.elementToFocus = self.contextButtonList
	end
end

-- Local values: mission
function InGameMenuMapFrame:onCreateJob()
	local v487_ = g_currentMission
	if self:getCanCreateJob() and not v487_.paused then
		self:createJob()
	end
	return true
end

-- Local values: moveActions, moveText, isGamepadContext
function InGameMenuMapFrame:updateInputGlyphs()
	local v489_ = self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD
	local v490_, v491_
	if v489_ then
		v490_ = self.moveCursorText
		v491_ = { InputAction.AXIS_MAP_SCROLL_LEFT_RIGHT, InputAction.AXIS_MAP_SCROLL_UP_DOWN }
	else
		v490_ = self.panMapText
		v491_ = { InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, InputAction.AXIS_LOOK_UPDOWN_DRAG }
	end
	self.mapMoveGlyph:setActions(v491_, nil, nil, true)
	self.mapZoomGlyph:setActions({ InputAction.AXIS_MAP_ZOOM_OUT, InputAction.AXIS_MAP_ZOOM_IN }, nil, nil, false)
	self.mapMoveGlyphText:setText(v490_)
	self.mapZoomGlyphText:setText(self.zoomText)
	self.switchVehicleGlyph:setVisible(self.hotspotModeActive and v489_)
	self.switchVehicleGlyphText:setVisible(self.hotspotModeActive and v489_)
	self.switchVehicleGlyph:setActions({ InputAction.SWITCH_VEHICLE, InputAction.SWITCH_VEHICLE_BACK })
	self.buttonBox:invalidateLayout()
end

-- Local values: isValid, errorText
function InGameMenuMapFrame:validateParameters()
	local v493_, v494_
	if self.currentJob == nil then
		v493_ = ""
		v494_ = true
	else
		self.currentJob:setValues()
		v494_, v493_ = self.currentJob:validate(g_localPlayer.farmId)
		self:updateWarnings()
	end
	self.errorMessage:setText(v493_)
	self.errorMessage:setVisible(not v494_)
end

-- Local values: _, element, param, invalidElement
function InGameMenuMapFrame:updateWarnings()
	for _, v496_ in ipairs(self.currentJobElements) do
		local v497_ = v496_.aiParameter
		local v498_ = v496_:getDescendantByName("invalid")
		if v498_ ~= nil then
			v498_:setVisible(not v497_:getIsValid())
		end
	end
end

function InGameMenuMapFrame:addStatusMessage(message)
	local v501_ = self.statusMessages
	local v502_ = {
		["removeTime"] = g_time + 5000,
		["text"] = message
	}
	table.insert(v501_, v502_)
	self:updateStatusMessages()
end

-- Local values: text, _, message
function InGameMenuMapFrame:updateStatusMessages()
	local v504_ = ""
	for _, v505_ in ipairs(self.statusMessages) do
		v504_ = v504_ .. v505_.text .. "\n"
	end
	self.statusMessage:setText(v504_)
end

-- Local values: jobTypeIndex
function InGameMenuMapFrame:onJobTypeChanged(index)
	self:setActiveJobTypeSelection(self.currentJobTypes[index])
end

function InGameMenuMapFrame:onAIJobStarted(job, farmId)
	if g_localPlayer ~= nil and farmId == g_localPlayer.farmId then
		local v511_ = self.playerFarmActiveJobs
		local v512_ = job.jobId
		table.insert(v511_, v512_)
	end
	self.activeWorkerList:reloadData()
	local v513_ = self.createJobEmptyText
	local v514_ = not self.createJobContainer:getIsVisible()
	if v514_ then
		v514_ = self.activeWorkerList:getItemCount() == 0
	end
	v513_:setVisible(v514_)
end

function InGameMenuMapFrame:onAIJobRemoved(jobId)
	table.removeElement(self.playerFarmActiveJobs, jobId)
	self.activeWorkerList:reloadData()
	local v517_ = self.createJobEmptyText
	local v518_ = self.mapOverviewSelector:getState() == InGameMenuMapFrame.AI_CREATE_JOB and not self.createJobContainer:getIsVisible()
	if v518_ then
		v518_ = self.activeWorkerList:getItemCount() == 0
	end
	v517_:setVisible(v518_)
	InGameMenuMapUtil.hideContextBox(self.contextBox)
	InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
	InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
end

-- Local values: text
function InGameMenuMapFrame:onAIJobStopped(job, aiMessage)
	if aiMessage ~= nil and (job ~= nil and (g_localPlayer ~= nil and job.startedFarmId == g_localPlayer.farmId)) then
		self:addStatusMessage((aiMessage:getMessage(job)))
	end
end

-- Local values: mission, addedPositionHotspot, _, element, parameter, parameterType, title, x, z, angle, unloadingStation, placeable, hotspot, x, z, loadingStation, placeable, hotspot, x, z
function InGameMenuMapFrame:updateParameterValueTexts()
	local v523_ = g_currentMission
	v523_:removeMapHotspot(self.aiTargetMapHotspot)
	v523_:removeMapHotspot(self.aiLoadingMarkerHotspot)
	v523_:removeMapHotspot(self.aiUnloadingMarkerHotspot)
	for _, v524_ in ipairs(self.currentJobElements) do
		local v525_ = v524_.aiParameter
		local v526_ = v525_:getType()
		if v526_ == AIParameterType.TEXT then
			v524_:getDescendantByName("title"):setText(v525_:getString())
		elseif v526_ == AIParameterType.POSITION or v526_ == AIParameterType.POSITION_ANGLE then
			v524_:setText(v525_:getString())
			v523_:addMapHotspot(self.aiTargetMapHotspot)
			local v527_, v528_ = v525_:getPosition()
			self.aiTargetMapHotspot:setWorldPosition(v527_, v528_)
			if v526_ == AIParameterType.POSITION_ANGLE then
				local v529_ = v525_:getAngle() + 3.141592653589793
				self.aiTargetMapHotspot:setWorldRotation(v529_)
			end
		else
			v524_:updateTitle()
			if v526_ == AIParameterType.UNLOADING_STATION then
				local v530_ = v525_:getUnloadingStation()
				if v530_ ~= nil then
					local v531_ = v530_.owningPlaceable
					if v531_ ~= nil and v531_.getHotspot ~= nil then
						local v532_ = v531_:getHotspot(1)
						if v532_ ~= nil then
							local v533_, v534_ = v532_:getWorldPosition()
							self.aiUnloadingMarkerHotspot:setWorldPosition(v533_, v534_)
							if not self.isLoadAndDeliverParameter then
								self.ingameMap:panToHotspot(self.aiUnloadingMarkerHotspot)
							end
							v523_:addMapHotspot(self.aiUnloadingMarkerHotspot)
						end
					end
				end
			elseif v526_ == AIParameterType.LOADING_STATION then
				local v535_ = v525_:getLoadingStation()
				if v535_ ~= nil then
					local v536_ = v535_.owningPlaceable
					if v536_ ~= nil and v536_.getHotspot ~= nil then
						local v537_ = v536_:getHotspot(1)
						if v537_ ~= nil then
							local v538_, v539_ = v537_:getWorldPosition()
							self.aiLoadingMarkerHotspot:setWorldPosition(v538_, v539_)
							if self.isLoadingStationParameterClick then
								self.ingameMap:panToHotspot(self.aiLoadingMarkerHotspot)
							end
							v523_:addMapHotspot(self.aiLoadingMarkerHotspot)
						end
					end
				end
			end
		end
	end
end

-- Local values: parameter
function InGameMenuMapFrame:onClickMultiTextOptionParameter(index, element)
	if self.currentJob ~= nil then
		local v542_ = element.aiParameter
		self.currentJob:onParameterValueChanged(v542_)
		self.isLoadingStationParameterClick = v542_:getType() == AIParameterType.LOADING_STATION
		self:updateParameterValueTexts()
	end
	self:validateParameters()
end

-- Local values: parameter
function InGameMenuMapFrame:onClickPositionParameter(element)
	local v_u_545_ = element.aiParameter
	self:startPickPosition(v_u_545_, function(p546_, _, _)
		-- upvalues: (copy) element, (copy) v_u_545_
		if p546_ then
			element:setText(v_u_545_:getString())
		end
	end)
end

-- Local values: parameter
function InGameMenuMapFrame:onClickPositionRotationParameter(element)
	local v_u_549_ = element.aiParameter
	self:startPickPositionAndRotation(v_u_549_, function(p550_, _, _, _)
		-- upvalues: (copy) element, (copy) v_u_549_
		if p550_ then
			element:setText(v_u_549_:getString())
		end
	end)
end

function InGameMenuMapFrame:getNumberOfSections(list)
	return list == self.filterList and self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS and 2 or 1
end

function InGameMenuMapFrame:getTitleForSectionHeader(list, section)
	return (list ~= self.filterList or self.mapOverviewSelector:getState() ~= InGameMenuMapFrame.MAP_HOTSPOTS) and "" or (section == 1 and g_i18n:getText("ui_mapHotspotFilter_vehicles") or g_i18n:getText("construction_category_buildings"))
end

-- Local values: state, data, index, action
function InGameMenuMapFrame:getNumberOfItemsInSection(list, section)
	if list ~= self.filterList then
		if list ~= self.contextButtonList and list ~= self.contextButtonListFarmland then
			return list == self.activeWorkerList and g_currentMission ~= nil and #self.playerFarmActiveJobs or 0
		end
		if self.mode == InGameMenuMapFrame.AI_MODE_CREATE then
			return 0
		end
		self.contextActionMapping = {}
		for v559_, v560_ in ipairs(self.contextActions) do
			if v560_.isActive then
				local v561_ = self.contextActionMapping
				table.insert(v561_, v559_)
			end
		end
		return #self.contextActionMapping
	end
	if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
		return #self.farmlandItems
	end
	if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS then
		return #InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[section]
	end
	local v562_ = self.mapOverviewSelector:getState()
	local v563_ = self.dataTables[v562_]
	if v563_ ~= nil then
		return #v563_
	end
	Logging.devError("No data found for map overlay selector state \'%s\'", v562_)
	if g_showDevelopmentWarnings then
		printCallstack()
	end
	return 0
end

-- Local values: overviewIndex, iconBg, farmlandsFarm, selectionIndex, getIsSelectedFunc, icon, iconBg, status, statusColor, buttonInfo, count, currentJob, farmId, mission, _, job
function InGameMenuMapFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.filterList then
		local v_u_569_ = self.mapOverviewSelector:getState()
		if v_u_569_ == InGameMenuMapFrame.MAP_FARMLANDS then
			cell:getAttribute("icon"):setVisible(false)
			local v570_ = cell:getAttribute("iconBg")
			local v571_ = self.farmlandItems[index]
			function v570_.getIsSelected()
				return true
			end
			self:assignItemColors(v570_, { v571_.color })
			cell:getAttribute("name"):setText(v571_.name)
		else
			local v_u_572_
			if v_u_569_ == InGameMenuMapFrame.MAP_SOIL then
				v_u_572_ = self.displaySoilStateMapping[index].soilStateIndex
			else
				v_u_572_ = index
			end
			local function v573_()
				-- upvalues: (copy) self, (copy) v_u_569_, (ref) v_u_572_
				return self.filterStates[v_u_569_][v_u_572_]
			end
			local v574_
			if v_u_569_ == InGameMenuMapFrame.MAP_HOTSPOTS then
				v574_ = function()
					-- upvalues: (copy) self, (copy) v_u_569_, (copy) section, (ref) v_u_572_
					return self.filterStates[v_u_569_][section][v_u_572_]
				end
			else
				v574_ = v_u_569_ == InGameMenuMapFrame.MAP_FRUIT_TYPE and function()
					-- upvalues: (copy) self, (ref) v_u_572_, (copy) v_u_569_
					local v575_ = self.displayCropTypes[v_u_572_]
					return self.filterStates[v_u_569_][v575_.fruitTypeIndex]
				end or v573_
			end
			local v576_ = cell:getAttribute("icon")
			v576_:setVisible(true)
			v576_.getIsSelected = v574_
			local v577_ = cell:getAttribute("iconBg")
			v577_.getIsSelected = v574_
			local v578_ = self.dataTables[v_u_569_][index]
			if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS then
				v578_ = self.dataTables[v_u_569_][section][index]
			end
			if v_u_569_ == InGameMenuMapFrame.MAP_HOTSPOTS then
				cell:getAttribute("name"):setText(g_i18n:getText(v578_.name))
				v576_:setImageSlice(nil, v578_.sliceId)
				self:assignItemColors(v577_, v578_.color)
			else
				local v579_ = v578_.colors[self.isColorBlindMode]
				cell:getAttribute("name"):setText(v578_.description)
				if v_u_569_ == InGameMenuMapFrame.MAP_FRUIT_TYPE then
					self:assignItemColors(v577_, {
						{
							v579_.r,
							v579_.g,
							v579_.b,
							v579_.a
						}
					})
					v576_:setImageFilename(v578_.iconFilename)
					local v580_ = Overlay.DEFAULT_UVS
					v576_:setImageUVs(nil, unpack(v580_))
				else
					self:assignItemColors(v577_, v579_, cell:getAttribute("colorTemplate"), v574_)
					v576_:setVisible(false)
				end
			end
		end
	end
	if list == self.contextButtonList or list == self.contextButtonListFarmland then
		local v581_ = self.contextActions[self.contextActionMapping[index]]
		cell:getAttribute("text"):setText(v581_.title or g_i18n:getText(v581_.text))
		cell.onClickCallback = v581_.callback
		if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
			cell:getAttribute("button"):applyProfile(InGameMenuMapFrame.PROFILE.CONTEXT_BUTTON_GAMEPAD)
		else
			cell:getAttribute("button"):applyProfile(InGameMenuMapFrame.PROFILE.CONTEXT_BUTTON)
		end
	end
	if list == self.activeWorkerList then
		local v582_ = g_localPlayer == nil and 1 or g_localPlayer.farmId
		local v583_ = g_currentMission
		local v584_ = 0
		local v585_ = nil
		for _, v586_ in ipairs(v583_.aiSystem:getActiveJobs()) do
			if v586_.startedFarmId == v582_ then
				v584_ = v584_ + 1
				if v584_ == index then
					v585_ = v586_
					break
				end
			end
		end
		if v585_ ~= nil then
			cell:getAttribute("text"):setText(v585_:getDescription())
			cell:getAttribute("title"):setText(v585_:getTitle())
			cell:getAttribute("helper"):setText(v585_:getHelperName())
		end
	end
end

-- Local values: i, partWidth, i, newPart
function InGameMenuMapFrame:assignItemColors(colorElement, stateColors, colorTemplate, selectedFunc)
	for v591_ = #colorElement.elements, 1, -1 do
		colorElement.elements[v591_]:delete()
	end
	local v592_ = colorElement.size[1] / #stateColors
	local v593_ = GuiOverlay.STATE_SELECTED
	local v594_ = stateColors[1]
	colorElement:setImageColor(v593_, unpack(v594_))
	if #stateColors > 1 then
		for v595_ = 2, #stateColors do
			local v596_ = colorTemplate:clone(colorElement)
			v596_:setSize(v592_, nil)
			v596_:setPosition((v595_ - 1) * v592_, 0)
			local v597_ = GuiOverlay.STATE_SELECTED
			local v598_ = stateColors[v595_]
			v596_:setImageColor(v597_, unpack(v598_))
			v596_.getIsSelected = selectedFunc
		end
	end
end

function InGameMenuMapFrame:getHasChangeableFilterList()
	return self.mapOverviewSelector:getState() <= InGameMenuMapFrame.MAP_HOTSPOTS
end

-- Local values: overviewIndex, statusFilter, filterIndex, fruitTypeDesc, hotspotCategory, mission, job, vehicle, hotspot
function InGameMenuMapFrame:onClickList(list, section, index, listElement)
	local v605_ = self.mapOverviewSelector:getState()
	if list == self.filterList and self:getHasChangeableFilterList() then
		if self.hotspotModeActive then
			self:setHotspotModeActive(false)
		end
		local v606_ = self.filterStates[v605_]
		if v605_ == InGameMenuMapFrame.MAP_HOTSPOTS then
			v606_ = self.filterStates[v605_][section]
		end
		if v605_ == InGameMenuMapFrame.MAP_SOIL then
			index = self.displaySoilStateMapping[index].soilStateIndex
		end
		local v607_
		if v605_ == InGameMenuMapFrame.MAP_FRUIT_TYPE then
			v607_ = self.displayCropTypes[index].fruitTypeIndex
		else
			v607_ = index
		end
		v606_[v607_] = not v606_[v607_]
		if v605_ == InGameMenuMapFrame.MAP_HOTSPOTS then
			local v608_ = self.dataTables[v605_][section][index].id
			self.ingameMapBase:toggleDefaultFilter(v608_)
			if v608_ == MapHotspot.CATEGORY_OTHER then
				self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, self.ingameMapBase:getDefaultFilterValue(MapHotspot.CATEGORY_OTHER))
			end
			self:setMapSelectionItem(nil)
		else
			self:generateOverviewOverlay()
		end
		self:saveFilters()
		if v606_[v607_] then
			self.numSelectedFilters[v605_] = self.numSelectedFilters[v605_] + 1
		else
			self.numSelectedFilters[v605_] = self.numSelectedFilters[v605_] - 1
		end
		if self.numSelectedFilters[v605_] == 0 then
			self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
		else
			self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
		end
	elseif list == self.contextButtonList or list == self.contextButtonListFarmland then
		listElement.onClickCallback(self)
	elseif list == self.activeWorkerList then
		local v609_ = g_currentMission.aiSystem:getJobById(self.playerFarmActiveJobs[index])
		if v609_ ~= nil and v609_.vehicleParameter then
			local v610_ = v609_.vehicleParameter:getVehicle()
			if v610_ ~= nil then
				local v611_ = v610_:getMapHotspot()
				self:setMapSelectionItem(v611_)
				self.ingameMap:panToHotspot(v611_)
			end
		end
	end
end

-- Local values: mission, job, vehicle, hotspot
function InGameMenuMapFrame:onListSelectionChanged(list, section, index)
	if list == self.activeWorkerList and not self.blockListSelectionUpdates then
		local v615_ = g_currentMission.aiSystem:getJobById(self.playerFarmActiveJobs[index])
		if v615_ ~= nil and v615_.vehicleParameter then
			local v616_ = v615_.vehicleParameter:getVehicle()
			if v616_ ~= nil then
				local v617_ = v616_:getMapHotspot()
				self.mode = InGameMenuMapFrame.AI_MODE_WORKER_LIST
				self:setMapSelectionItem(v617_)
				self.ingameMap:panToHotspot(v617_)
			end
		end
	end
end

function InGameMenuMapFrame:registerInput()
	self:unregisterInput()
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, false)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, false)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, false)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, false)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, false)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, false)
	g_inputBinding:registerActionEvent(InputAction.MENU_MAP_ACTION_1, self, self.onMenuMapAction1, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onSwitchVehicle, false, true, false, false, 1)
	g_inputBinding:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onSwitchVehicle, false, true, false, false, -1)
end

-- Local values: list, _, actionName
function InGameMenuMapFrame:unregisterInput(customOnly)
	local v620_ = customOnly and InGameMenuMapFrame.CLEAR_CLOSE_INPUT_ACTIONS or InGameMenuMapFrame.CLEAR_INPUT_ACTIONS
	for _, v621_ in pairs(v620_) do
		g_inputBinding:removeActionEventsByActionName(v621_)
	end
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, true)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, true)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, true)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, true)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, true)
	g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, true)
end

function InGameMenuMapFrame:onMenuMapAction1()
	if self.buttonDeselectAll:getIsVisible() then
		self:onClickDeselectAll()
	elseif self.buttonStartJobContainer:getIsVisible() then
		self:onStartCancelJob()
	end
end

-- Local values: newHotspot
function InGameMenuMapFrame:onSwitchVehicle(_, value, direction)
	if self.contextBoxFarmland:getIsVisible() then
		self:setMapSelectionItem(nil)
	end
	local v625_ = self.ingameMapBase:cycleVisibleHotspot(self.currentHotspot, InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES, direction)
	self:setMapSelectionItem(v625_)
	self.ingameMap:panToHotspot(v625_, self.filterBox.absSize[1] * 0.5)
end

function InGameMenuMapFrame:getIsPicking()
	return self.isPickingRotation or self.isPickingLocation
end
function InGameMenuMapFrame.executePickingCallback(p627_, ...)
	p627_.ingameMap:setHotspotSelectionActive(true)
	p627_.isPickingLocation = false
	p627_.isPickingRotation = false
	p627_.ingameMap:unlockMapMovement()
	local v628_ = p627_.pickingCallback
	p627_.pickingCallback = nil
	if v628_ ~= nil then
		v628_(...)
	end
end

-- Local values: mission
function InGameMenuMapFrame:startPickPosition(parameter, callback)
	self.ingameMap:setHotspotSelectionActive(false)
	self.ingameMap:setIsCursorAvailable(false)
	self.isPickingLocation = true
	self:showActionMessage("ui_ai_pickTargetLocation")
	local v632_ = g_currentMission
	v632_:removeMapHotspot(self.aiTargetMapHotspot)
	v632_:addMapHotspot(self.aiTargetMapHotspot)
	self.contextBox:setVisible(false)
	function self.pickingCallback(p633_, p634_, p635_)
		-- upvalues: (copy) self, (copy) parameter, (copy) callback
		self:showActionMessage()
		self.ingameMap:setIsCursorAvailable(true)
		self.hasPickedRotationTouch = false
		self.contextBox:setVisible(true)
		if p633_ then
			parameter:setValue(p634_, p635_)
			self.aiTargetMapHotspot:setWorldPosition(p634_, p635_)
		end
		callback(p633_, p634_, p635_, parameter)
		self:validateParameters()
	end
end

-- Local values: mission
function InGameMenuMapFrame:startPickPositionAndRotation(parameter, callback)
	self.isPickingLocation = true
	self.ingameMap:setHotspotSelectionActive(false)
	self.ingameMap:setIsCursorAvailable(false)
	self:showActionMessage("ui_ai_pickTargetLocation")
	local v639_ = g_currentMission
	v639_:removeMapHotspot(self.aiTargetMapHotspot)
	v639_:addMapHotspot(self.aiTargetMapHotspot)
	self.contextBox:setVisible(false)
	function self.pickingCallback(p640_, p_u_641_, p_u_642_)
		-- upvalues: (copy) self, (copy) parameter, (copy) callback
		self:showActionMessage()
		self.ingameMap:setIsCursorAvailable(true)
		self.hasPickedRotationTouch = false
		self.contextBox:setVisible(true)
		if p640_ then
			self.ingameMap:setHotspotSelectionActive(false)
			self.ingameMap:setIsCursorAvailable(false)
			self.aiTargetMapHotspot:setWorldPosition(p_u_641_, p_u_642_)
			self.isPickingRotation = true
			self.ingameMap:lockMapMovement()
			self.pickingRotationOrigin = { p_u_641_, p_u_642_ }
			self.pickingRotationSnapAngle = parameter:getSnappingAngle()
			self:showActionMessage("ui_ai_pickTargetRotation")
			self.contextBox:setVisible(false)
			function self.pickingCallback(p643_, p644_)
				-- upvalues: (ref) self, (ref) parameter, (copy) p_u_641_, (copy) p_u_642_, (ref) callback
				self:showActionMessage()
				self.ingameMap:setIsCursorAvailable(true)
				self.contextBox:setVisible(true)
				if p643_ then
					parameter:setPosition(p_u_641_, p_u_642_)
					parameter:setAngle(p644_)
					local v645_ = parameter:getAngle()
					self.aiTargetMapHotspot:setWorldRotation(v645_ + 3.141592653589793)
					callback(true, p_u_641_, p_u_642_, p644_)
				else
					callback(false, p_u_641_, p_u_642_, nil)
				end
				self:validateParameters()
			end
		else
			callback(false, nil, nil, nil)
		end
		self:validateParameters()
	end
end

-- Local values: i
function InGameMenuMapFrame:setJobMenuVisible(isVisible)
	g_inputBinding:setActionEventActive(self.eventIdSwitchVehicle, not isVisible)
	g_inputBinding:setActionEventActive(self.eventIdSwitchVehicleBack, not isVisible)
	self.errorMessage:setText("")
	self.actionMessage:setText("")
	if self.hotspotModeActive then
		self:setHotspotModeActive(false)
	end
	if isVisible then
		self.createJobContainer:setVisible(false)
		self.mapOverviewSelector:setState(InGameMenuMapFrame.AI_CREATE_JOB, true)
	else
		for v648_ = #self.jobMenuLayout.elements, 1, -1 do
			self.jobMenuLayout.elements[v648_]:delete()
		end
		self.currentJobElements = {}
		self.jobMenuLayout:invalidateLayout()
		self.jobTypeElement:setTexts({})
		self.createJobContainer:setVisible(false)
		FocusManager:setFocus(self.mapOverviewSelector)
	end
	self.createJobContainer:setVisible(isVisible)
	local v649_ = self.createJobEmptyText
	local v650_ = not isVisible
	if v650_ then
		v650_ = self.activeWorkerList:getItemCount() == 0
	end
	v649_:setVisible(v650_)
	self.mapOverviewSelector:setDisabled(isVisible)
end

-- Local values: vehicle, currentJobTypesTexts, currentJobTypeIndex, currentIndex, lastJob, mission, aiJobTypeManager, name, index
function InGameMenuMapFrame:createJob()
	local v652_ = self.currentHotspot:getVehicle()
	if v652_ ~= nil then
		self.currentJobTypes = {}
		local v653_ = {}
		local v654_ = nil
		local v655_ = nil
		local v656_
		if v652_.getLastJob == nil then
			v656_ = nil
		else
			v656_ = v652_:getLastJob()
		end
		local v657_ = g_currentMission.aiJobTypeManager
		for _, v658_ in pairs(AIJobType) do
			if self.jobTypeInstances[v658_]:getIsAvailableForVehicle(v652_) then
				local v659_ = self.currentJobTypes
				table.insert(v659_, v658_)
				local v660_ = v657_:getJobTypeByIndex(v658_).title
				table.insert(v653_, v660_)
				if v654_ == nil or v656_ ~= nil and v656_.class == self.jobTypeInstances[v658_].class then
					v655_ = #self.currentJobTypes
					v654_ = v658_
				end
			end
		end
		if #self.currentJobTypes == 0 then
			printError("Error: vehicle has no support for any jobs, so button should not have been shown!")
			return
		end
		self.jobTypeElement:setTexts(v653_)
		self.jobTypeElement:setState(v655_ or 1)
		self.mode = InGameMenuMapFrame.AI_MODE_CREATE
		self.currentJobVehicle = v652_
		self.currentJob = nil
		self:setJobMenuVisible(true)
		FocusManager:setFocus(self.jobTypeElement)
		self:setActiveJobTypeSelection(v654_)
	end
end

-- Local values: vehicle, job
function InGameMenuMapFrame:tryStartGoToJob()
	if self.currentHotspot ~= nil then
		local v_u_662_ = self.currentHotspot:getVehicle()
		if v_u_662_ ~= nil then
			self:startPickPositionAndRotation(self.jobTypeInstances[AIJobType.GOTO].positionAngleParameter, function(p663_, p664_, p665_, p666_)
				-- upvalues: (copy) self, (copy) v_u_662_
				if p663_ then
					self:startGoToJob(v_u_662_, p664_, p665_, p666_)
				end
				self:refreshContextInput()
			end)
		end
	end
end

function InGameMenuMapFrame:tryStartJob(job, farmId, callback)
	self.startJobPending = true
	g_messageCenter:subscribe(AIJobStartRequestEvent, self.onStartedJob, self, { callback })
	g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, farmId))
end

-- Local values: callback, mission, jobType, text
function InGameMenuMapFrame:onStartedJob(args, state, jobTypeIndex)
	local v675_ = args[1]
	self.startJobPending = false
	g_messageCenter:unsubscribe(AIJobStartRequestEvent, self)
	if state == AIJob.START_SUCCESS then
		self.mapOverviewSelector:setState(InGameMenuMapFrame.AI_WORKER_LIST, true)
		FocusManager:setFocus(self.activeWorkerList)
	else
		local v676_ = g_currentMission.aiJobTypeManager:getJobTypeByIndex(jobTypeIndex).classObject.getIsStartErrorText(state)
		InfoDialog.show(v676_, nil, nil, DialogElement.TYPE_INFO)
	end
	v675_(state)
end

-- Local values: vehicle, job
function InGameMenuMapFrame:skipCurrentTask()
	local v678_ = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if v678_ ~= nil and v678_:getIsAIActive() then
		local v679_ = v678_:getJob()
		if v679_ ~= nil then
			if v679_:getCanSkipTask() then
				v678_:skipCurrentTask()
				return
			end
			self:refreshContextInput()
		end
	end
end
InGameMenuMapFrame.INPUT_CONTEXT_NAME = "MENU_MAP_OVERVIEW"
InGameMenuMapFrame.CLEAR_INPUT_ACTIONS = {
	InputAction.MENU_ACTIVATE,
	InputAction.MENU_CANCEL,
	InputAction.MENU_EXTRA_2,
	InputAction.CAMERA_ZOOM_IN_OUT
}
InGameMenuMapFrame.CLEAR_CLOSE_INPUT_ACTIONS = { InputAction.CAMERA_ZOOM_IN_OUT }
InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES = {
	[MapHotspot.CATEGORY_STEERABLE] = true,
	[MapHotspot.CATEGORY_COMBINE] = true,
	[MapHotspot.CATEGORY_TRAILER] = true,
	[MapHotspot.CATEGORY_TOOL] = true,
	[MapHotspot.CATEGORY_OTHER] = false,
	[MapHotspot.CATEGORY_AI] = true,
	[MapHotspot.CATEGORY_PLAYER] = false
}
local v680_ = InGameMenuMapFrame
local v681_ = {
	{
		{
			["id"] = MapHotspot.CATEGORY_STEERABLE,
			["sliceId"] = "gui.ingameMap_vehicles",
			["name"] = "ui_mapHotspotFilter_vehicles",
			["color"] = {
				{
					0.13,
					0.13,
					0.13,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_COMBINE,
			["sliceId"] = "gui.ingameMap_harvester",
			["name"] = "ui_mapHotspotFilter_combines",
			["color"] = {
				{
					0.13,
					0.13,
					0.13,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_TRAILER,
			["sliceId"] = "gui.ingameMap_trailer",
			["name"] = "ui_mapHotspotFilter_trailers",
			["color"] = {
				{
					0.13,
					0.13,
					0.13,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_TOOL,
			["sliceId"] = "gui.ingameMap_tools",
			["name"] = "ui_mapHotspotFilter_tools",
			["color"] = {
				{
					0.13,
					0.13,
					0.13,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_AI,
			["sliceId"] = "gui.ingameMap_helper",
			["name"] = "ui_mapHotspotFilter_ai",
			["color"] = {
				{
					0.13,
					0.13,
					0.13,
					1
				}
			}
		}
	},
	{
		{
			["id"] = MapHotspot.CATEGORY_UNLOADING,
			["sliceId"] = "gui.ingameMap_tippingStation",
			["name"] = "ui_mapHotspotFilter_tipStations",
			["color"] = {
				{
					0.26635,
					0.00477,
					0.11443,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_LOADING,
			["sliceId"] = "gui.ingameMap_loadingStation",
			["name"] = "ui_mapHotspotFilter_loadingStations",
			["color"] = {
				{
					0.02028,
					0.07036,
					0.43415,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_PRODUCTION,
			["sliceId"] = "gui.ingameMap_productionPoint",
			["name"] = "ui_mapHotspotFilter_productionPoints",
			["color"] = {
				{
					0.00651,
					0.56471,
					0.57758,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_ANIMAL,
			["sliceId"] = "gui.ingameMap_animals",
			["name"] = "ui_mapHotspotFilter_animals",
			["color"] = {
				{
					0.00604,
					0.14412,
					0.11443,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_MISSION,
			["sliceId"] = "gui.ingameMap_contracts",
			["name"] = "ui_mapHotspotFilter_contracts",
			["color"] = {
				{
					0.00303,
					0.20155,
					0.01599,
					1
				}
			}
		},
		{
			["id"] = MapHotspot.CATEGORY_OTHER,
			["sliceId"] = "gui.ingameMap_other",
			["name"] = "ui_mapHotspotFilter_others",
			["color"] = {
				{
					0.61049,
					0.56471,
					0.00303,
					1
				}
			}
		}
	}
}
v680_.HOTSPOT_FILTER_CATEGORIES = v681_
InGameMenuMapFrame.GLYPH_SIZE = { 36, 36 }
InGameMenuMapFrame.GLYPH_TEXT_SIZE = 20
InGameMenuMapFrame.GLYPH_COLOR = {
	1,
	1,
	1,
	1
}
InGameMenuMapFrame.L10N_SYMBOL = {
	["VEHICLE_RESET"] = "button_reset",
	["SELECT_ALL"] = "button_selectAll",
	["DESELECT_ALL"] = "button_deselectAll",
	["DIALOG_VEHICLE_RESET_DONE"] = "ui_vehicleResetDone",
	["DIALOG_VEHICLE_RESET_FAILED"] = "ui_vehicleResetFailed",
	["DIALOG_VEHICLE_IN_USE"] = "shop_messageReturnVehicleInUse",
	["DIALOG_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionGeneral",
	["DIALOG_VEHICLE_RESET_CONFIRM"] = "ui_wantToResetVehicleText",
	["DIALOG_BUY_FARMLAND"] = "shop_messageBuyFarmlandText",
	["DIALOG_BUY_FARMLAND_TITLE"] = "shop_messageBuyFarmlandTitle",
	["DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY"] = "shop_messageNotEnoughMoneyToBuyFarmland",
	["DIALOG_BUY_FARMLAND_ACTIVE_MISSION"] = "shop_messageBuyFarmlandMissionRunning",
	["DIALOG_SELL_FARMLAND"] = "shop_messageSellFarmlandText",
	["DIALOG_SELL_FARMLAND_TITLE"] = "shop_messageSellFarmlandTitle",
	["DIALOG_CANNOT_SELL_WTIH_PLACEABLES"] = "shop_messageCannotSellFarmlandWithPlaceables",
	["INPUT_MOVE_CURSOR"] = "ui_ingameMenuMapMoveCursor",
	["INPUT_PAN_MAP"] = "ui_ingameMenuMapPan",
	["INPUT_ZOOM_MAP"] = "ui_ingameMenuMapZoom"
}
InGameMenuMapFrame.PROFILE = {
	["MONEY_VALUE_NEUTRAL"] = "ingameMenuMapMoneyValue",
	["MONEY_VALUE_NEGATIVE"] = "ingameMenuMapMoneyValueNegative",
	["CONTEXT_BUTTON"] = "fs25_mapContextButtonListItemButton",
	["CONTEXT_BUTTON_GAMEPAD"] = "fs25_mapContextButtonListItemButtonGamepad"
}
InGameMenuMapFrame.ACTIONS = {
	["GOTO_JOB"] = 1,
	["ENTER_VEHICLE"] = 2,
	["CREATE_JOB"] = 3,
	["START_JOB"] = 4,
	["CANCEL_JOB"] = 5,
	["SKIP_TASK"] = 6,
	["RESET_VEHICLE"] = 7,
	["SELL_VEHICLE"] = 8,
	["VISIT_PLACE"] = 9,
	["MANAGE"] = 10,
	["BUY"] = 11,
	["SELL"] = 12,
	["SET_MARKER"] = 13,
	["REMOVE_MARKER"] = 14
}
