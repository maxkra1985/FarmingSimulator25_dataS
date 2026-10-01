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
local NO_CALLBACK = function() end
function InGameMenuMapFrame.register()
	local inGameMenuMapFrame = InGameMenuMapFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuMapFrame.xml", "MapFrame", inGameMenuMapFrame, true)
end
function InGameMenuMapFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMapFrame_mt)
	self.onClickBackCallback = NO_CALLBACK
	self.client = nil
	self.playerFarm = nil
	self.contextActions = {}
	self.contextActionMapping = {}
	self.fruitTypeFilter = {}
	self.growthStateFilter = {}
	self.soilStateFilter = {}
	self.hotspotStateFilter = { {}, {} }
	self.filterStates = { self.fruitTypeFilter, self.growthStateFilter, self.soilStateFilter, self.hotspotStateFilter }
	self.numSelectedFilters = { 0, 0, 0, 0 }
	self.hasFullScreenMap = true
	self.dataTables = {}
	self.farmlandItems = {}
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	self.isMapOverviewInitialized = false
	self.lastInputHelpMode = 0
	self.isInputContextActive = false
	self.nextMoneyUpdateTime = 0
	self.foliageStateOverlay = nil
	self.foliageStateOverlayIsReady = false
	self.farmlandStateOverlay = nil
	self.farmlandStateOverlayIsReady = false
	function self.overviewOverlayFinishedCallback(overlayId)
		self:onOverviewOverlayFinished(overlayId)
	end
	function self.farmlandOverlayFinishedCallback(overlayId)
		self:onFarmlandOverlayFinished(overlayId)
	end
	self.hotspotModeActive = false
	self.currentHotspot = nil
	self.ingameMapBase = nil
	self.staticUIDeadzone = { 0, 0, 0, 0 }
	self.needsSolidBackground = Platform.ingameMap.needsSolidBackground
	self.selectedFarmland = nil
	self.selectedVehicle = nil
	self.previousSubCategoryState = 1
	self.showIntroductionHud = false
	self.showIntroHudIfNotSaving = false
	self.goToMainOverview = false
	self.jobTypeInstances = {}
	self.statusMessages = {}
	self.playerFarmActiveJobs = {}
	self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
	self.lastMousePosX = 0
	self.lastMousePosY = 0
	self.updateTime = 0
	self.aiTargetMapHotspot = AITargetHotspot.new()
	self.aiLoadingMarkerHotspot = AIPlaceableMarkerHotspot.new()
	self.aiUnloadingMarkerHotspot = AIPlaceableMarkerHotspot.new()
	self.lastInputTime = 0
	return self
end
function InGameMenuMapFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuMapFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	g_messageCenter:unsubscribeAll(newGui)
	return newGui
end
function InGameMenuMapFrame:copyAttributes(src)
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
function InGameMenuMapFrame:initialize(onClickBackCallback)
	self:updateInputGlyphs()
	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK
	for index, dot in pairs(self.subCategoryDotBox.elements) do
		function dot.getIsSelected()
			return self.mapOverviewSelector:getState() == index
		end
	end
	local filterList = self.filterList
	function filterList.mouseEvent(list, posX, posY, isDown, isUp, button, eventUsed)
		SmoothListElement.mouseEvent(list, posX, posY, isDown, isUp, button, eventUsed)
		if isDown and (button == Input.MOUSE_BUTTON_RIGHT and GuiUtils.checkOverlayOverlap(posX, posY, filterList.absPosition[1], filterList.absPosition[2], filterList.absSize[1], filterList.absSize[2])) then
			local _, section, index = filterList:getElementAtScreenPosition(posX, posY)
			self:onClickDeselectAll(section, index)
			filterList:setSelectedItem(section, index)
		end
	end
	self:initializeContextActions()
	self.zoomText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_ZOOM_MAP)
	self.moveCursorText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_MOVE_CURSOR)
	self.panMapText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_PAN_MAP)
	function self.buttonDeselectAllText.getIsFocused()
		return self.buttonDeselectAll:getIsFocused()
	end
	function self.buttonDeselectAllText.getIsHighlighted()
		return self.buttonDeselectAll:getIsHighlighted()
	end
	function self.buttonStartJobText.getIsFocused()
		return self.buttonStartJob:getIsFocused()
	end
	function self.buttonStartJobText.getIsHighlighted()
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
	self.contextActions = {
		[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE] = { text = "button_enterVehicle", callback = self.onClickEnterVehicle, isActive = false },
		[InGameMenuMapFrame.ACTIONS.RESET_VEHICLE] = { text = "button_reset", callback = self.onClickResetVehicle, isActive = false },
		[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE] = { text = "button_sell", callback = self.onClickSellVehicle, isActive = false },
		[InGameMenuMapFrame.ACTIONS.BUY] = { text = "button_buy", callback = self.onClickBuy, isActive = false },
		[InGameMenuMapFrame.ACTIONS.SELL] = { text = "button_sell", callback = self.onClickSell, isActive = false },
		[InGameMenuMapFrame.ACTIONS.VISIT_PLACE] = { text = "action_visit", callback = self.onClickVisitPlace, isActive = false },
		[InGameMenuMapFrame.ACTIONS.SET_MARKER] = { text = "action_tag", callback = self.onClickTagPlace, isActive = false },
		[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER] = { text = "action_untag", callback = self.onClickTagPlace, isActive = false },
		[InGameMenuMapFrame.ACTIONS.MANAGE] = { text = "action_manage", callback = self.onClickManage, isActive = false },
		[InGameMenuMapFrame.ACTIONS.GOTO_JOB] = { text = "button_gotoJob", callback = self.onStartGoToJob, isActive = false },
		[InGameMenuMapFrame.ACTIONS.CREATE_JOB] = { text = "button_createJob", callback = self.onCreateJob, isActive = false },
		[InGameMenuMapFrame.ACTIONS.START_JOB] = { text = "button_startJob", callback = self.onStartCancelJob, isActive = false },
		[InGameMenuMapFrame.ACTIONS.CANCEL_JOB] = { text = "button_cancelJob", callback = self.onStartCancelJob, isActive = false },
		[InGameMenuMapFrame.ACTIONS.SKIP_TASK] = { text = "button_skipTask", callback = self.onSkipJobTask, isActive = false },
	}
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
		local x, _, z = g_localPlayer:getPosition()
		self.ingameMap:setCenterToWorldPosition(x, z)
	end
	self:generateJobTypes()
	self:setJobMenuVisible(false)
	self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
	self.playerFarmActiveJobs = {}
	local farmId = 1
	if g_localPlayer ~= nil then
		farmId = g_localPlayer.farmId
	end
	local mission = g_currentMission
	for _, job in ipairs(mission.aiSystem:getActiveJobs()) do
		if job.startedFarmId == farmId then
			table.insert(self.playerFarmActiveJobs, job.jobId)
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
function InGameMenuMapFrame:onFrameClose()
	g_messageCenter:unsubscribeAll(self)
	if self.previousSubCategoryState == InGameMenuMapFrame.AI_CREATE_JOB then
		for _, hotspot in pairs(self.ingameMap.ingameMap.hotspots) do
			if hotspot:isa(VehicleHotspot) or hotspot:isa(AIHotspot) then
				hotspot:setVisible(hotspot.oldVisibility)
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
	local mission = g_currentMission
	mission:removeMapHotspot(self.aiTargetMapHotspot)
	mission:removeMapHotspot(self.aiLoadingMarkerHotspot)
	mission:removeMapHotspot(self.aiUnloadingMarkerHotspot)
	self.statusMessages = {}
	self:updateStatusMessages()
	InGameMenuMapFrame:superClass().onFrameClose(self)
	self.ingameMap:onClose()
	self:toggleMapInput(false)
	self.ingameMapBase:restoreDefaultFilter()
end
function InGameMenuMapFrame:saveFilters()
	local fruitValue = ""
	for fruitId, state in pairs(self.fruitTypeFilter) do
		if state then
			continue
		end
		local name = g_fruitTypeManager:getFillTypeNameByFruitTypeIndex(fruitId)
		if fruitValue ~= "" then
			fruitValue = fruitValue .. ";" .. name
		else
			fruitValue = name
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
	local hotspotValue = 0
	for i, state in ipairs(self.hotspotStateFilter[1]) do
		if state then
			hotspotValue = Utils.setBit(hotspotValue, i)
		end
	end
	for i, state in ipairs(self.hotspotStateFilter[2]) do
		if state then
			hotspotValue = Utils.setBit(hotspotValue, i + #self.hotspotStateFilter[1])
		end
	end
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER, fruitValue, false)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER, growthValue, false)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER, soilValue, true)
	g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER, hotspotValue, true)
end
function InGameMenuMapFrame:loadFilters()
	local numInactiveFilters = 0
	local fruitValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER)
	for _, fruitName in ipairs(fruitValue:split(";")) do
		local fruitDesc = g_fruitTypeManager:getFruitTypeByName(fruitName)
		if fruitDesc == nil then
			continue
		end
		self.fruitTypeFilter[fruitDesc.index] = false
		numInactiveFilters = numInactiveFilters + 1
	end
	for _, fruitDesc in pairs(self.displayCropTypes) do
		if self.fruitTypeFilter[fruitDesc.fruitTypeIndex] == nil then
			self.fruitTypeFilter[fruitDesc.fruitTypeIndex] = true
		end
	end
	self.numSelectedFilters[1] = math.max(#self.displayCropTypes - numInactiveFilters, 0)
	if self.numSelectedFilters[1] == 0 then
		self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
	end
	local growthValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER)
	for i, _ in pairs(self.displayGrowthStates) do
		local isBitSet = Utils.isBitSet(growthValue, i)
		self.growthStateFilter[i] = isBitSet
		if isBitSet then
			self.numSelectedFilters[2] = self.numSelectedFilters[2] + 1
		end
	end
	local lastSoilFilter = 1
	local soilValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER)
	for _, state in pairs(self.displaySoilStateMapping) do
		local index = state.soilStateIndex
		local isBitSet = Utils.isBitSet(soilValue, index)
		self.soilStateFilter[index] = isBitSet
		if isBitSet then
			self.numSelectedFilters[3] = self.numSelectedFilters[3] + 1
		end
		lastSoilFilter = index
	end
	for i = 1, lastSoilFilter do
		if self.displaySoilStates[i] == nil then
			self.soilStateFilter[i] = false
		end
	end
	local hotspotValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER)
	for i, hotspotCategory in pairs(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1]) do
		local isBitSet = Utils.isBitSet(hotspotValue, i)
		self.hotspotStateFilter[1][i] = isBitSet
		self.ingameMapBase:setDefaultFilterValue(hotspotCategory.id, isBitSet)
		if isBitSet then
			self.numSelectedFilters[4] = self.numSelectedFilters[4] + 1
		end
	end
	for i, hotspotCategory in pairs(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[2]) do
		local isBitSet = Utils.isBitSet(hotspotValue, i + #self.hotspotStateFilter[1])
		self.hotspotStateFilter[2][i] = isBitSet
		self.ingameMapBase:setDefaultFilterValue(hotspotCategory.id, isBitSet)
		if isBitSet then
			self.numSelectedFilters[4] = self.numSelectedFilters[4] + 1
		end
	end
end
function InGameMenuMapFrame:onLoadMapFinished()
	local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
	self.displaySoilStateMapping = {}
	if mapOverlayGenerator ~= nil then
		self.displayCropTypes = mapOverlayGenerator:getDisplayCropTypes()
		self.displayGrowthStates = mapOverlayGenerator:getDisplayGrowthStates()
		self.displaySoilStates = mapOverlayGenerator:getDisplaySoilStates()
		for index, state in pairs(self.displaySoilStates) do
			if state.isActive then
				state.soilStateIndex = index
				table.insert(self.displaySoilStateMapping, state)
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
function InGameMenuMapFrame:onSoilSettingChanged()
	local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
	self.displaySoilStateMapping = {}
	if mapOverlayGenerator ~= nil then
		mapOverlayGenerator:updateStates()
		self.displaySoilStates = mapOverlayGenerator:getDisplaySoilStates()
		for index, state in pairs(self.displaySoilStates) do
			if state.isActive then
				state.soilStateIndex = index
				table.insert(self.displaySoilStateMapping, state)
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
function InGameMenuMapFrame:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self.isPickingRotation then
		local localX, localY = self.ingameMap:getLocalPosition(posX, posY)
		local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
		local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
		angle = angle + 3.141592653589793
		if 0 < self.pickingRotationSnapAngle then
			local numSteps = MathUtil.round(angle / self.pickingRotationSnapAngle, 0)
			angle = numSteps * self.pickingRotationSnapAngle
		end
		self.aiTargetMapHotspot:setWorldRotation(angle)
	end
	self.lastMousePosX = posX
	self.lastMousePoxY = posY
	if self.isPickingLocation then
		local localX, localY = self.ingameMap:getLocalPosition(self.lastMousePosX, self.lastMousePoxY)
		if self.filterBox.absPosition[1] + self.filterBox.absSize[1] < posX and self.buttonBox.absPosition[2] + self.buttonBox.absSize[2] < posY then
			self:setTargetPointHotspotPosition(localX, localY)
		end
	end
	self.lastInputTime = g_time
	return InGameMenuMapFrame:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
end
function InGameMenuMapFrame:inputEvent(action, value, eventUsed)
	self.lastInputTime = g_time
	return InGameMenuMapFrame:superClass().inputEvent(self, action, value, eventUsed)
end
function InGameMenuMapFrame:update(dt)
	InGameMenuMapFrame:superClass().update(self, dt)
	if self.elementToFocus ~= nil and (not g_gui:getIsDialogVisible() and FocusManager:setFocus(self.elementToFocus)) then
		self.elementToFocus = nil
	end
	local currentInputHelpMode = g_inputBinding:getInputHelpMode()
	if currentInputHelpMode ~= self.lastInputHelpMode then
		self.lastInputHelpMode = currentInputHelpMode
		self.buttonSelectIngame:setVisible(currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD)
		self:updateContextInputBarVisibility()
		g_inputBinding:setShowMouseCursor(currentInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD)
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
			local mission = g_currentMission
			if mission.introductionHelpSystem:getIsActive() then
				mission.introductionHelpSystem:showHelp("helpZoomMap")
				mission.introductionHelpSystem:showHelp("helpPanMap")
			end
			self.showIntroHudIfNotSaving = false
		end
	end
	if self.showIntroductionHud and not g_savegameController:getIsSaving() then
		self.showIntroductionHud = false
		self.showIntroHudIfNotSaving = true
	end
	if currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		local localX, localY = self.ingameMap:getLocalPointerTarget()
		if self.isPickingLocation then
			self:setTargetPointHotspotPosition(localX, localY)
		elseif self.isPickingRotation then
			local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
			local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
			angle = angle + 3.141592653589793
			if 0 < self.pickingRotationSnapAngle then
				local numSteps = MathUtil.round(angle / self.pickingRotationSnapAngle, 0)
				angle = numSteps * self.pickingRotationSnapAngle
			end
			self.aiTargetMapHotspot:setWorldRotation(angle)
		end
	end
	if self.updateTime < g_time then
		local mission = g_currentMission
		local aiSystem = mission.aiSystem
		for i = 1, self.activeWorkerList:getItemCount() do
			local element = self.activeWorkerList:getElementAtSectionIndex(1, i)
			if element == nil then
				continue
			end
			local job = aiSystem:getJobById(self.playerFarmActiveJobs[i])
			local textElement = element:getAttribute("text")
			if job == nil or textElement:getText() == job:getDescription() then
				continue
			end
			textElement:setText(job:getDescription())
		end
		self.updateTime = g_time + 1000
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
	self.blockListSelectionUpdates = false
	if g_gui:getIsDialogVisible() then
		self.lastInputTime = g_time
	end
	if InGameMenuMapFrame.FIELD_INFO_DELAY < g_time - self.lastInputTime then
		local fieldInfoBox = self.fieldInfoBox
		if self.currentHotspot == nil and not fieldInfoBox:getIsVisible() then
			local screenX = nil
			local screenY = nil
			if currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
				screenX, screenY = self.mapCursor:getCenter()
			else
				screenX = g_lastMousePosX
				screenY = g_lastMousePosY
			end
			self:clearFieldInfoBox()
			if self:updateFieldInfoBox(screenX, screenY) then
				fieldInfoBox:setVisible(true)
				local backgroundTop = fieldInfoBox:getDescendantByName("backgroundTop")
				local backgroundBottom = fieldInfoBox:getDescendantByName("backgroundBottom")
				local layout = fieldInfoBox:getDescendantByName("layout")
				layout:invalidateLayout()
				local baseSize = InGameMenuMapFrame.FIELD_INFO_LAYOUT_BASE_SIZE * g_pixelSizeScaledY
				fieldInfoBox:setSize(nil, backgroundTop.absSize[2] - backgroundTop.position[2] + backgroundBottom.absSize[2] + backgroundBottom.position[2] + math.max(layout.maxFlowSize - baseSize, 0))
				InGameMenuMapUtil.updateFieldInfoBoxPosition(self.fieldInfoBox, screenX, screenY)
			end
		end
	else
		self.fieldInfoBox:setVisible(false)
	end
end
function InGameMenuMapFrame:clearFieldInfoBox()
	local layout = self.fieldInfoBox:getDescendantByName("layout")
	for i = #layout.elements, 1, -1 do
		layout.elements[i]:delete()
		layout.elements[i] = nil
	end
end
function InGameMenuMapFrame:addFieldInfoKeyValue(key, value)
	local layout = self.fieldInfoBox:getDescendantByName("layout")
	local template = self.fieldInfoKeyValueTemplate
	local clonedElement = template:clone(layout)
	local title = clonedElement:getDescendantByName("title")
	local text = clonedElement:getDescendantByName("text")
	title:setText(key)
	text:setText(value)
end
function InGameMenuMapFrame:addFieldInfoWarning(text)
	local layout = self.fieldInfoBox:getDescendantByName("layout")
	local template = self.fieldInfoWarningTemplate
	local clonedElement = template:clone(layout)
	local warning = clonedElement:getDescendantByName("warning")
	warning:setText(text)
end
function InGameMenuMapFrame:updateFieldInfoBox(screenX, screenY)
	local localX, localY = self.ingameMap:getLocalPosition(screenX, screenY)
	local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
	if self.fieldInfo == nil then
		self.fieldInfo = FieldState.new()
	end
	local fieldInfo = self.fieldInfo
	fieldInfo:update(worldX, worldZ)
	if fieldInfo.groundType == FieldGroundType.NONE then
		return false
	else
		local farmName = nil
		local ownedByYou = false
		local ownerFarmId = fieldInfo.ownerFarmId
		if ownerFarmId == g_currentMission:getFarmId() then
			if ownerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
				farmName = g_i18n:getText("fieldInfo_ownerYou")
				ownedByYou = true
			elseif ownerFarmId == AccessHandler.EVERYONE or ownerFarmId == AccessHandler.NOBODY then
				local farmland = g_farmlandManager:getFarmlandById(fieldInfo.farmlandId)
				if farmland == nil then
					farmName = g_i18n:getText("fieldInfo_ownerNobody")
				else
					local npc = farmland:getNPC()
					farmName = npc ~= nil and npc.title or "Unknown"
				end
			else
				local farm = g_farmManager:getFarmById(ownerFarmId)
				farmName = farm ~= nil and farm.name or "Unknown"
			end
		end
		self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_farmland"), tostring(fieldInfo.farmlandId))
		if Platform.playerInfo.showNPCNames then
			self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), farmName)
		elseif ownedByYou then
			self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_owned"))
		else
			self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_notOwned"))
		end
		local fruitTypeIndex = fieldInfo.fruitTypeIndex
		local growthState = fieldInfo.growthState
		local isGrowing = false
		if fruitTypeIndex ~= FruitType.UNKNOWN then
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
			self:addFieldInfoKeyValue(g_i18n:getText("statistic_fillType"), fruitTypeDesc.fillType.title)
			local text = nil
			if fruitTypeDesc:getIsCut(growthState) then
				text = g_i18n:getText("ui_growthMapCut")
			elseif fruitTypeDesc:getIsWithered(growthState) then
				text = g_i18n:getText("ui_growthMapWithered")
			elseif fruitTypeDesc:getIsGrowing(growthState) then
				text = g_i18n:getText("ui_growthMapGrowing")
				isGrowing = true
			elseif fruitTypeDesc:getIsPreparable(growthState) then
				text = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
				isGrowing = true
			elseif fruitTypeDesc:getIsHarvestable(growthState) then
				text = g_i18n:getText("ui_growthMapReadyToHarvest")
				isGrowing = true
			end
			if text ~= nil then
				self:addFieldInfoKeyValue(g_i18n:getText("ui_mapOverviewGrowth"), text)
			end
		end
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		if isGrowing then
			local harvestMultiplier = fieldInfo:getHarvestScaleMultiplier()
			harvestMultiplier = harvestMultiplier - 1
			harvestMultiplier = MathUtil.round(harvestMultiplier * 100)
			self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_yieldBonus"), string.format("+ %d %%", harvestMultiplier))
		end
		if 0 <= fieldInfo.sprayLevel then
			local sprayLevelMax = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
			local sprayFactor = fieldInfo.sprayLevel / sprayLevelMax
			self:addFieldInfoKeyValue(g_i18n:getText("ui_growthMapFertilized"), string.format("%d %%", sprayFactor * 100))
		end
		local missionInfo = g_currentMission.missionInfo
		if Platform.gameplay.useLimeCounter and (missionInfo.limeRequired and fieldInfo.limeLevel == 0) then
			self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsLime"))
		end
		if fieldInfo.plowLevel == 0 and missionInfo.plowingRequiredEnabled then
			self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsPlowing"))
		end
		if Platform.gameplay.useRolling and 0 < fieldInfo.rollerLevel then
			self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsRolling"))
		end
		if g_currentMission.missionInfo.weedsEnabled then
			local weedSystem = g_currentMission.weedSystem
			local fieldInfoStates = weedSystem:getFieldInfoStates()
			local weedState = fieldInfo.weedState
			local toolName = nil
			if 0 < weedState then
				local fruitTypeDesc = nil
				if fruitTypeIndex ~= nil then
					fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
				end
				if Platform.gameplay.hasWeeder then
					if fruitTypeDesc == nil or fruitTypeDesc:getIsWeedable(growthState) then
						local weederReplacements = weedSystem:getWeederReplacements(false)
						local weed = weederReplacements.weed
						local targetState = weed.replacements[weedState]
						if targetState == 0 then
							toolName = g_i18n:getText("weed_destruction_weeder")
						end
					end
					if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsHoeable(growthState)) then
						local hoeReplacements = weedSystem:getWeederReplacements(true)
						local weed = hoeReplacements.weed
						local targetState = weed.replacements[weedState]
						if targetState == 0 then
							toolName = g_i18n:getText("weed_destruction_hoe")
						end
					end
				end
				if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsGrowing(growthState)) then
					toolName = g_i18n:getText("weed_destruction_herbicide")
				end
				local title = fieldInfoStates[weedState]
				if title ~= nil then
					self:addFieldInfoKeyValue(title, toolName or "")
				end
			end
		end
		return true
	end
end
function InGameMenuMapFrame:setTargetPointHotspotPosition(localX, localY)
	local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
	self.aiTargetMapHotspot:setWorldPosition(worldX, worldZ)
end
function InGameMenuMapFrame:getCanCancelJob()
	local mission = g_currentMission
	local _v10 = false
	if self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW then
		_v10 = not self:getIsPicking() and self.canCancel and mission:getHasPlayerPermission("hireAssistant") and not g_guidedTourManager:getIsTourRunning()
	end
	return _v10
end
function InGameMenuMapFrame:getCanCreateJob()
	local mission = g_currentMission
	local _v10 = false
	if self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW then
		_v10 = not self:getIsPicking() and self.canCreateJob and mission:getHasPlayerPermission("hireAssistant") and not g_guidedTourManager:getIsTourRunning()
	end
	return _v10
end
function InGameMenuMapFrame:getCanGoTo()
	local mission = g_currentMission
	local _v10 = false
	if self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW then
		_v10 = not self:getIsPicking() and self.canGoTo and mission:getHasPlayerPermission("hireAssistant") and not g_guidedTourManager:getIsTourRunning()
	end
	return _v10
end
function InGameMenuMapFrame:getCanStartJob()
	local mission = g_currentMission
	local _v10 = false
	if self.mode == InGameMenuMapFrame.AI_MODE_CREATE then
		_v10 = not self:getIsPicking() and mission:getHasPlayerPermission("hireAssistant") and not g_guidedTourManager:getIsTourRunning()
	end
	return _v10
end
function InGameMenuMapFrame:getCanSkipJobTask()
	local mission = g_currentMission
	local _v10 = false
	if self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW then
		_v10 = not self:getIsPicking() and self.canSkipTask and mission:getHasPlayerPermission("hireAssistant") and not g_guidedTourManager:getIsTourRunning()
	end
	return _v10
end
function InGameMenuMapFrame:getCanGoBack()
	if self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() then
		if not false then
			local _v21 = false
		end
	end
	return false
end
function InGameMenuMapFrame:setAIInputContext(canGoTo, canCreateJob, canCancel, canSkipTask, canEnter, canReset, canSell, isVehicleContext)
	self.canGoTo = canGoTo
	self.canCreateJob = canCreateJob
	self.canCancel = canCancel
	self.canSkipTask = canSkipTask
	local showContextButtons = false
	if self.mode ~= InGameMenuMapFrame.AI_MODE_WORKER_LIST then
		showContextButtons = isVehicleContext and not g_guidedTourManager:getIsTourRunning()
	end
	self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].isActive = showContextButtons and canEnter
	self.contextActions[InGameMenuMapFrame.ACTIONS.RESET_VEHICLE].isActive = showContextButtons and canReset
	self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].isActive = showContextButtons and canSell
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
function InGameMenuMapFrame:refreshContextInput()
	local hotspot = self.currentHotspot
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
	local mission = g_currentMission
	local showContextButtons = not mission.paused and self.mode ~= InGameMenuMapFrame.AI_MODE_WORKER_LIST
	local canGoTo = false
	local canCreateJob = false
	local canCancel = false
	local canSkipTask = false
	local canReset = false
	local canSell = false
	local canEnter = false
	if vehicle ~= nil then
		if vehicle.getIsEnterableFromMenu ~= nil then
			vehicle:getIsEnterableFromMenu()
		end
		canEnter = false
		if not self.isResetPending and (vehicle:getCanBeReset() and (hotspot:getCategory() ~= MapHotspot.CATEGORY_AI and (mission:getHasPlayerPermission(Farm.PERMISSION.RESET_VEHICLE) and vehicle:getOwnerFarmId() == self.playerFarm.farmId))) then
			canReset = not mission.paused
		end
		if mission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and (vehicle:getOwnerFarmId() == self.playerFarm.farmId and vehicle:getCanBeSold()) then
			canSell = false
			if vehicle.propertyState == VehiclePropertyState.LEASED then
				self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_return"
			else
				self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_sell"
			end
		end
		if mission.accessHandler:canPlayerAccess(vehicle) and vehicle.spec_aiJobVehicle ~= nil then
			canCancel = vehicle:getIsAIActive()
			if canCancel then
				local job = vehicle:getJob()
				if job ~= nil and job:getCanSkipTask() then
					canSkipTask = showContextButtons
				end
				canCancel = showContextButtons
			else
				canGoTo = self.jobTypeInstances[AIJobType.GOTO]:getIsAvailableForVehicle(vehicle) and showContextButtons
				canCreateJob = false
				for typeIndex, instance in pairs(self.jobTypeInstances) do
					if instance:getIsAvailableForVehicle(vehicle) then
						canCreateJob = showContextButtons
						break
					end
				end
			end
		end
	end
	local isVisible = not canCreateJob and mission.aiSystem:getAILimitedReached()
	self.limitReachedWarning:setVisible(isVisible)
	self:setAIInputContext(canGoTo, canCreateJob, canCancel, canSkipTask, canEnter, canReset, canSell, vehicle ~= nil)
end
function InGameMenuMapFrame:updateContextInputBarVisibility()
	local mission = g_currentMission
	local currentInputHelpMode = g_inputBinding:getInputHelpMode()
	local isSelectAvailable = currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD
	local isPicking = self:getIsPicking()
	self.buttonSelectIngame:setVisible(isSelectAvailable and not isPicking and self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW)
	local _v25 = mission.paused
	if not _v25 and self.mode ~= InGameMenuMapFrame.AI_MODE_WORKER_LIST then
		g_guidedTourManager:getIsTourRunning()
	end
	local isButtonEnabled = not _v25
	self.contextActions[InGameMenuMapFrame.ACTIONS.GOTO_JOB].isActive = self:getCanGoTo() and isButtonEnabled
	self.contextActions[InGameMenuMapFrame.ACTIONS.CREATE_JOB].isActive = self:getCanCreateJob() and isButtonEnabled
	self.contextActions[InGameMenuMapFrame.ACTIONS.START_JOB].isActive = self:getCanStartJob() and isButtonEnabled
	self.contextActions[InGameMenuMapFrame.ACTIONS.CANCEL_JOB].isActive = self:getCanCancelJob() and isButtonEnabled
	self.contextActions[InGameMenuMapFrame.ACTIONS.SKIP_TASK].isActive = self:getCanSkipJobTask() and isButtonEnabled
	self.contextButtonList:reloadData()
	self.contextButtonListFarmland:reloadData()
	self.contextButtonList:setHandleFocus(0 < self.contextButtonList:getItemCount())
	self.contextButtonListFarmland:setHandleFocus(0 < self.contextButtonListFarmland:getItemCount())
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
function InGameMenuMapFrame:setAIVehicle(vehicle)
	local hotspot = vehicle:getMapHotspot()
	self:setMapSelectionItem(hotspot)
	self.ingameMap:panToHotspot(hotspot)
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
	table.insert(self.mapSelectorTexts, string.format(g_i18n:getText("ui_mapOverviewFruitTypes"), ""))
	table.insert(self.mapSelectorTexts, g_i18n:getText("ui_mapOverviewGrowth"))
	table.insert(self.mapSelectorTexts, g_i18n:getText("ui_mapOverviewSoil"))
	table.insert(self.mapSelectorTexts, g_i18n:getText("ui_mapOverviewHotspots"))
	table.insert(self.mapSelectorTexts, g_i18n:getText("ui_farmlandScreen"))
	table.insert(self.mapSelectorTexts, g_i18n:getText("button_createJob"))
	table.insert(self.mapSelectorTexts, g_i18n:getText("ui_activeAIJobs"))
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
function InGameMenuMapFrame:generateOverviewOverlay()
	if self.isMapOverviewInitialized then
		if self.foliageStateOverlay == nil then
			self.foliageStateOverlayIsReady = false
		end
		self.dynamicMapImageLoadingBg:setVisible(true)
		local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
		if mapOverlayGenerator ~= nil then
			local state = self.mapOverviewSelector:getState()
			if state == InGameMenuMapFrame.MAP_FRUIT_TYPE or InGameMenuMapFrame.MAP_HOTSPOTS <= state then
				mapOverlayGenerator:generateFruitTypeOverlay(self.overviewOverlayFinishedCallback, self.fruitTypeFilter)
				return
			end
			if state == InGameMenuMapFrame.MAP_GROWTH then
				mapOverlayGenerator:generateGrowthStateOverlay(self.overviewOverlayFinishedCallback, self.growthStateFilter, self.fruitTypeFilter)
				return
			end
			if state == InGameMenuMapFrame.MAP_SOIL then
				mapOverlayGenerator:generateSoilStateOverlay(self.overviewOverlayFinishedCallback, self.soilStateFilter)
			end
		end
	end
end
function InGameMenuMapFrame:generateFarmlandOverlay(selectedFarmland)
	local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
	if mapOverlayGenerator ~= nil then
		if self.isMapOverviewInitialized then
			if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
				mapOverlayGenerator:generateFarmlandOverlay(self.farmlandOverlayFinishedCallback, selectedFarmland)
				return
			elseif selectedFarmland ~= nil then
				mapOverlayGenerator:generateSingleFarmlandOverlay(self.farmlandOverlayFinishedCallback, selectedFarmland)
				return
			else
				self.farmlandStateOverlayIsReady = false
				return
			end
		end
		self.farmlandStateOverlayIsReady = false
	end
end
function InGameMenuMapFrame:onDrawPostIngameMapHotspots()
	if self.currentContextBox ~= nil then
		InGameMenuMapUtil.updateContextBoxPosition(self.currentContextBox, self.currentHotspot)
	end
	if self.aiTargetMapHotspot ~= nil then
		local icon = self.aiTargetMapHotspot.icon
		self.actionMessage:setAbsolutePosition(self.aiTargetMapHotspot.lastScreenPositionX + icon.width * 0.5, self.aiTargetMapHotspot.lastScreenPositionY + icon.height * 0.5)
	end
end
function InGameMenuMapFrame:setMapSelectionItem(hotspot)
	if hotspot ~= nil then
		local x, _ = hotspot:getWorldPosition()
		if x == nil then
			hotspot = nil
		end
	end
	if self.ingameMapBase ~= nil then
		self.ingameMapBase:setSelectedHotspot(hotspot)
	end
	self.selectedFarmland = nil
	local mission = g_currentMission
	local isPlaceable = false
	local isVehicle = false
	local isFarmland = false
	local isPlayer = false
	local canEnter = false
	local canReset = false
	local canSellVehicle = false
	local canVisit = false
	local canSetMarker = false
	local removeMarker = false
	local canBuy = false
	local canSell = false
	local canManage = false
	local name = nil
	local imageFilename = nil
	local uvs = nil
	local vehicle = nil
	local farmId = nil
	local playerName = nil
	if not self.isPickingLocation and not self.isPickingRotation then
		mission:removeMapHotspot(self.aiTargetMapHotspot)
		mission:removeMapHotspot(self.aiLoadingMarkerHotspot)
		mission:removeMapHotspot(self.aiUnloadingMarkerHotspot)
	end
	local showContextBox = hotspot ~= nil
	if hotspot ~= nil then
		vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
		if hotspot:isa(PlayerHotspot) then
			local player = hotspot:getPlayer()
			if player ~= nil then
				playerName = player:getNickname()
				farmId = player:getFarmId()
			end
		end
		if hotspot:isa(PlayerHotspot) then
			if vehicle == nil then
				if mission.missionDynamicInfo.isMultiplayer then
					isPlayer = true
					self.currentHotspot = hotspot
				else
					self.currentHotspot = nil
					showContextBox = false
				end
			elseif vehicle ~= nil then
				farmId = vehicle:getOwnerFarmId()
				name = vehicle:getName()
				imageFilename = vehicle:getImageFilename()
				uvs = Overlay.DEFAULT_UVS
				self.currentHotspot = hotspot
				if mission.tourIconsBase == nil or not mission.tourIconsBase.visible then
					if vehicle.getIsEnterableFromMenu ~= nil then
						vehicle:getIsEnterableFromMenu()
					end
					canEnter = false
					if not self.isResetPending and (vehicle:getCanBeReset() and hotspot:getCategory() ~= MapHotspot.CATEGORY_AI) then
						canReset = true
					end
				end
				isVehicle = true
				if vehicle.spec_rideable ~= nil then
					self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].text = "action_rideAnimal"
				else
					self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].text = "button_enterVehicle"
				end
				if mission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and (farmId == self.playerFarm.farmId and vehicle:getCanBeSold()) then
					canSellVehicle = vehicle.propertyState ~= VehiclePropertyState.MISSION
					if vehicle.propertyState == VehiclePropertyState.LEASED then
						self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_return"
					else
						self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_sell"
					end
				end
				if vehicle.getJob ~= nil then
					local job = vehicle:getJob()
					if job ~= nil then
						if job.getTarget ~= nil and job:getShowTarget() then
							local x, z, rot = job:getTarget()
							self.aiTargetMapHotspot:setWorldPosition(x, z)
							if rot ~= nil then
								self.aiTargetMapHotspot:setWorldRotation(rot + 3.141592653589793)
							end
							mission:addMapHotspot(self.aiTargetMapHotspot)
						end
						if job.unloadingStationParameter ~= nil then
							local unloadingStation = job.unloadingStationParameter:getUnloadingStation()
							if unloadingStation ~= nil then
								local placeable = unloadingStation.owningPlaceable
								if placeable ~= nil and placeable.getHotspot ~= nil then
									local unloadingHotspot = placeable:getHotspot(1)
									local x, z = unloadingHotspot:getWorldPosition()
									self.aiUnloadingMarkerHotspot:setWorldPosition(x, z)
									if not self.isLoadingStationParameterClick then
										self.ingameMap:panToHotspot(self.aiUnloadingMarkerHotspot)
									end
									mission:addMapHotspot(self.aiUnloadingMarkerHotspot)
								end
							end
						end
						if job.loadingStationParameter ~= nil then
							local loadingStation = job.loadingStationParameter:getLoadingStation()
							if loadingStation ~= nil then
								local placeable = loadingStation.owningPlaceable
								if placeable ~= nil and placeable.getHotspot ~= nil then
									local loadingHotspot = placeable:getHotspot(1)
									local x, z = loadingHotspot:getWorldPosition()
									self.aiLoadingMarkerHotspot:setWorldPosition(x, z)
									if not self.isLoadAndDeliverParameter then
										self.ingameMap:panToHotspot(self.aiLoadingMarkerHotspot)
									end
									mission:addMapHotspot(self.aiLoadingMarkerHotspot)
								end
							end
						end
					end
				end
			elseif hotspot:isa(PlaceableHotspot) then
				name = hotspot:getName()
				if name ~= nil then
					local placeable = hotspot:getPlaceable()
					if placeable == nil or not placeable:getIsBeingDeleted() then
						if placeable ~= nil then
							farmId = placeable:getOwnerFarmId()
							imageFilename = placeable:getImageFilename()
							uvs = Overlay.DEFAULT_UVS
							isPlaceable = placeable.customImageFilename == nil
							if g_currentMission.accessHandler:canPlayerAccess(placeable) then
								canManage = SpecializationUtil.hasSpecialization(PlaceableProductionPoint, placeable.specializations)
								local _v140 = placeable:canBeSold()
								if _v140 and (placeable.storeItem.canBeSold and g_currentMission:getFarmId() == farmId) then
									g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_PLACEABLE)
								end
								canSell = _v140
								if placeable.spec_productionPoint ~= nil then
									local productionPoint = placeable.spec_productionPoint.productionPoint
									local ownerFarmId = productionPoint:getOwnerFarmId()
									if not placeable.spec_productionPoint.isFinalized then
										ownerFarmId = farmId
									end
									canBuy = false
								elseif placeable.spec_factory ~= nil then
									local ownerFarmId = placeable:getOwnerFarmId()
									canBuy = ownerFarmId == AccessHandler.EVERYONE
								end
							end
						end
						canSetMarker = mission.currentMapTargetHotspot ~= hotspot
						removeMarker = mission.currentMapTargetHotspot == hotspot
						canVisit = hotspot:getBeVisited()
						self.currentHotspot = hotspot
					else
						showContextBox = false
						self.currentHotspot = nil
					end
				end
			elseif hotspot:isa(NPCHotspot) then
				name = hotspot:getName()
				imageFilename = hotspot:getImageFilename()
				canVisit = hotspot:getBeVisited()
				uvs = Overlay.DEFAULT_UVS
				canSetMarker = mission.currentMapTargetHotspot == hotspot
				removeMarker = mission.currentMapTargetHotspot == hotspot
				self.currentHotspot = hotspot
			elseif hotspot:isa(FarmlandHotspot) then
				if hotspot ~= self.currentHotspot then
					self.needsOverlayUpdate = true
				end
				isFarmland = true
				self.currentHotspot = hotspot
				self.selectedFarmland = hotspot:getFarmland()
				local ownerFarmId = g_farmlandManager:getFarmlandOwner(self.selectedFarmland.id)
				local playerIsFarmManager = mission:getHasPlayerPermission("farmManager")
				if g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID then
					canBuy = false
					canSell = false
				end
				canVisit = true
				canSetMarker = mission.currentMapTargetHotspot ~= hotspot
				removeMarker = mission.currentMapTargetHotspot == hotspot
			end
		end
	else
		if self.currentHotspot ~= nil then
			self.needsOverlayUpdate = true
		end
		self.currentHotspot = nil
	end
	local _v157 = mission.paused
	if not _v157 and self.mode ~= InGameMenuMapFrame.AI_MODE_WORKER_LIST then
		g_guidedTourManager:getIsTourRunning()
	end
	local isButtonEnabled = not _v157
	canEnter = canEnter and isButtonEnabled
	canReset = canReset and isButtonEnabled
	canSellVehicle = canSellVehicle and isButtonEnabled
	canVisit = canVisit and isButtonEnabled
	canBuy = canBuy and isButtonEnabled
	canSell = canSell and isButtonEnabled
	canManage = canManage and isButtonEnabled
	self:setMapInputContext(canEnter, canReset, canSellVehicle, canVisit, canSetMarker, removeMarker, canBuy, canSell, canManage)
	self:refreshContextInput()
	if showContextBox then
		InGameMenuMapUtil.hideContextBox(self.contextBox)
		InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
		InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
		local contextBox = self.contextBox
		local contextButtonList = self.contextButtonList
		if isPlayer then
			contextBox = self.contextBoxPlayer
			InGameMenuMapUtil.showPlayerContextBox(contextBox, playerName, farmId)
		else
			if isFarmland then
				contextBox = self.contextBoxFarmland
				contextButtonList = self.contextButtonListFarmland
			elseif self.mapOverviewSelector:getState() <= InGameMenuMapFrame.MAP_HOTSPOTS then
				self:setHotspotModeActive(true)
			end
			InGameMenuMapUtil.showContextBox(contextBox, hotspot, name, imageFilename, uvs, farmId, playerName, isPlaceable, isVehicle, isFarmland)
		end
		self.currentContextBox = contextBox
		if self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW or self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST and self.activeWorkerList:getItemCount() == 0 and not isPlayer then
			FocusManager:setFocus(contextButtonList)
		end
	else
		if self.hotspotModeActive then
			self:setHotspotModeActive(false)
		end
		local state = self.mapOverviewSelector:getState()
		local focusChanged = not self.currentContextBox:getIsVisible()
		InGameMenuMapUtil.hideContextBox(self.contextBox)
		InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
		InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
		if state == InGameMenuMapFrame.AI_WORKER_LIST then
			self.blockListSelectionUpdates = true
			FocusManager:setFocus(self.activeWorkerList)
			FocusManager:getFocusedElement()
			focusChanged = false
			self.blockListSelectionUpdates = false
		elseif InGameMenuMapFrame.MAP_HOTSPOTS < state then
			FocusManager:setFocus(self.jobMenuLayout)
			focusChanged = false
		end
		if not focusChanged then
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
function InGameMenuMapFrame:updateMapSelectionFilterNavigation()
	local targetButtonTop = nil
	local targetButtonBottom = nil
	if self.mapSelectionPreviousItem.visible then
		targetButtonTop = self.mapSelectionPreviousItem
	elseif self.mapSelectionNextItem.visible then
		targetButtonTop = self.mapSelectionNextItem
	end
	if targetButtonBottom == nil then
		if self.mapSelectionEnter.visible then
			targetButtonBottom = self.mapSelectionEnter
		elseif self.mapSelectionReset.visible then
			targetButtonBottom = self.mapSelectionReset
		elseif self.mapSelectionVisit.visible then
			targetButtonBottom = self.mapSelectionVisit
		elseif self.mapSelectionTag.visible then
			targetButtonBottom = self.mapSelectionTag
		end
	end
	targetButtonTop = Utils.getNoNil(targetButtonTop, self.mapSelectionPreviousItem)
	targetButtonBottom = Utils.getNoNil(targetButtonBottom, self.mapSelectionEnter)
	for _, elem in pairs(self.mapOverviewFilters) do
		elem.focusChangeData[FocusManager.BOTTOM] = targetButtonTop.focusId
	end
	targetButtonTop.focusChangeData[FocusManager.BOTTOM] = targetButtonBottom.focusId
	targetButtonBottom.focusChangeData[FocusManager.TOP] = targetButtonTop.focusId
end
function InGameMenuMapFrame:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive
		self.filterList:reloadData()
		self:generateOverviewOverlay()
	end
end
function InGameMenuMapFrame:showActionMessage(locaKey)
	if locaKey ~= nil then
		self.actionMessage:setVisible(true)
		self.actionMessage:setLocaKey(locaKey)
	else
		self.actionMessage:setVisible(false)
	end
end
function InGameMenuMapFrame:generateJobTypes()
	local mission = g_currentMission
	local aiJobTypeManager = mission.aiJobTypeManager
	for _, jobType in pairs(AIJobType) do
		self.jobTypeInstances[jobType] = aiJobTypeManager:createJob(jobType)
	end
end
function InGameMenuMapFrame:startGoToJob(vehicle, destX, destZ, angle)
	local job = self.jobTypeInstances[AIJobType.GOTO]
	job.vehicleParameter:setVehicle(vehicle)
	job.positionAngleParameter:setPosition(destX, destZ)
	job.positionAngleParameter:setAngle(angle)
	job:setValues()
	local success, errorMessage = job:validate(g_localPlayer.farmId)
	if success then
		local callback = function(state)
			if state == AIJob.START_SUCCESS then
				local mission = g_currentMission
				local aiJobTypeManager = mission.aiJobTypeManager
				self.jobTypeInstances[AIJobType.GOTO] = aiJobTypeManager:createJob(AIJobType.GOTO)
				self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
				self:refreshContextInput()
			end
		end
		self:tryStartJob(job, g_localPlayer.farmId, callback)
		return true
	else
		InfoDialog.show(tostring(errorMessage), nil, nil, DialogElement.TYPE_WARNING)
		return false
	end
end
function InGameMenuMapFrame:startJob()
	if self.startJobPending then
		return
	end
	self.currentJob:setValues()
	local success, errorMessage = self.currentJob:validate(g_localPlayer.farmId)
	if success then
		local callback = function(state)
			if state == AIJob.START_SUCCESS then
				self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
				self.currentJob = nil
				self:setJobMenuVisible(false)
				self:refreshContextInput()
			end
		end
		self:tryStartJob(self.currentJob, g_localPlayer.farmId, callback)
	else
		InfoDialog.show(tostring(errorMessage), nil, nil, DialogElement.TYPE_WARNING)
		self:updateWarnings()
	end
end
function InGameMenuMapFrame:cancelJob()
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
	if vehicle ~= nil and vehicle:getIsAIActive() then
		vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
		local mission = g_currentMission
		mission:removeMapHotspot(self.aiTargetMapHotspot)
	end
end
function InGameMenuMapFrame:setActiveJobTypeSelection(jobTypeIndex)
	if self.currentJob == nil or jobTypeIndex ~= self.currentJob.jobTypeIndex then
		for i = #self.jobMenuLayout.elements, 1, -1 do
			self.jobMenuLayout.elements[i]:delete()
		end
		local mission = g_currentMission
		self.currentJob = mission.aiJobTypeManager:createJob(jobTypeIndex)
		local farmId = 1
		if g_localPlayer ~= nil then
			farmId = g_localPlayer.farmId
		end
		self.currentJob:applyCurrentState(self.currentJobVehicle, mission, farmId, false)
		self.currentJobElements = {}
		for _, group in ipairs(self.currentJob:getGroupedParameters()) do
			local titleElement = self.createTitleTemplate:clone(self.jobMenuLayout)
			titleElement:setText(group:getTitle())
			local invalidElement = nil
			for index, item in ipairs(group:getParameters()) do
				local element = nil
				local parameterType = item:getType()
				if parameterType == AIParameterType.TEXT then
					element = self.createTextTemplate:clone(self.jobMenuLayout)
				elseif parameterType == AIParameterType.POSITION then
					element = self.createPositionTemplate:clone(self.jobMenuLayout)
					element:updateAbsolutePosition()
				elseif parameterType == AIParameterType.POSITION_ANGLE then
					element = self.createPositionRotationTemplate:clone(self.jobMenuLayout)
					element:updateAbsolutePosition()
				elseif parameterType == AIParameterType.SELECTOR or parameterType == AIParameterType.UNLOADING_STATION or parameterType == AIParameterType.LOADING_STATION or parameterType == AIParameterType.FILLTYPE then
					element = self.createMultiOptionTemplate:clone(self.jobMenuLayout)
					element:setDataSource(item)
					if index == 1 then
						invalidElement = element:getDescendantByName("invalid")
					else
						element:getDescendantByName("invalid"):setPosition(invalidElement.absPosition[1], invalidElement.absPosition[2])
					end
				end
				element.aiParameter = item
				element:setDisabled(not item:getCanBeChanged())
				table.insert(self.currentJobElements, element)
			end
		end
		self:updateParameterValueTexts()
		self:validateParameters()
		self.jobMenuLayout:invalidateLayout()
		FocusManager:setFocus(self.jobTypeElement)
	end
	self:refreshContextInput()
end
function InGameMenuMapFrame:onMoneyChange()
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
function InGameMenuMapFrame:onAIVehicleStateChanged(isActive, vehicle)
	if vehicle ~= nil and self.currentHotspot ~= nil then
		local selectedVehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
		if selectedVehicle == vehicle then
			self:refreshContextInput()
		end
	end
end
function InGameMenuMapFrame:onVehicleEntered(vehicle, player)
	if self.currentHotspot == nil then
		return
	end
	local playerHotspot = false
	if player ~= nil then
		playerHotspot = player.playerHotspot
	end
	local vehicleHotspot = false
	if vehicle ~= nil then
		vehicleHotspot = vehicle.mapHotspot
	end
	if self.currentHotspot == playerHotspot then
		self:setMapSelectionItem(playerHotspot)
	else
		if self.currentHotspot == vehicleHotspot then
			self:setMapSelectionItem(playerHotspot)
		end
	end
end
function InGameMenuMapFrame:onVehicleLeft(vehicle, player)
	if self.currentHotspot == nil then
		return
	else
		local playerHotspot = false
		if player ~= nil then
			playerHotspot = player.playerHotspot
		end
		if self.currentHotspot == playerHotspot then
			self:setMapSelectionItem(playerHotspot)
		end
	end
end
function InGameMenuMapFrame:onAITaskSkipped()
	self:refreshContextInput()
end
function InGameMenuMapFrame:onDrawPostIngameMap(element, ingameMap)
	if self.hideContentOverlay then
		return
	else
		local width, height = self.ingameMapBase.fullScreenLayout:getMapSize()
		local x, y = self.ingameMapBase.fullScreenLayout:getMapPosition()
		local overlayX = x + width * 0.25
		local overlayY = y + height * 0.25
		if self.foliageStateOverlay ~= nil and (self.foliageStateOverlay ~= 0 and self.foliageStateOverlayIsReady) then
			renderOverlay(self.foliageStateOverlay, overlayX, overlayY, width * 0.5, height * 0.5)
		end
		if self.farmlandStateOverlay ~= nil and (self.farmlandStateOverlay ~= 0 and self.farmlandStateOverlayIsReady) then
			renderOverlay(self.farmlandStateOverlay, overlayX, overlayY, width * 0.5, height * 0.5)
		end
	end
end
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
	for _, hotspot in pairs(self.ingameMap.ingameMap.hotspots) do
		if hotspot:isa(VehicleHotspot) or hotspot:isa(AIHotspot) then
			if state == InGameMenuMapFrame.AI_CREATE_JOB then
				hotspot.oldVisibility = hotspot:getIsVisible()
				local vehicle = hotspot:getVehicle()
				hotspot:setVisible(hotspot.getVehicle ~= nil and vehicle.spec_aiJobVehicle ~= nil and vehicle.spec_aiJobVehicle.supportsAIJobs and vehicle:getJob() == nil and false == hotspot:isa(AIHotspot))
			elseif self.previousSubCategoryState == InGameMenuMapFrame.AI_CREATE_JOB then
				hotspot:setVisible(hotspot.oldVisibility)
			end
		end
	end
	if state == InGameMenuMapFrame.MAP_FARMLANDS then
		self.farmlandItems = {}
		local farms = g_farmManager:getFarms()
		local localPlayerFarm = g_farmManager:getFarmByUserId(g_localPlayer.userId)
		table.insert(self.farmlandItems, { name = g_i18n:getText("ui_farmlandUnowned"), color = MapOverlayGenerator.COLOR.FIELD_UNOWNED })
		table.insert(self.farmlandItems, { name = g_i18n:getText("ui_farmlandsCurrentlySelected"), color = MapOverlayGenerator.COLOR.FIELD_SELECTED })
		table.insert(self.farmlandItems, { name = localPlayerFarm.name, color = localPlayerFarm:getColor() })
		for index, farm in pairs(farms) do
			if farm == localPlayerFarm then
				continue
			end
			if farm.showInFarmScreen then
				table.insert(self.farmlandItems, { name = farm.name, color = farm:getColor() })
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
function InGameMenuMapFrame:onClickHotspot(element, hotspot)
	local worldX = hotspot.worldX
	local worldZ = hotspot.worldZ
	if self.isPickingLocation then
		self:executePickingCallback(true, worldX, worldZ)
	elseif self.isPickingRotation then
		local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
		self:executePickingCallback(true, angle)
	elseif self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW then
		if self.currentHotspot ~= hotspot and hotspot ~= self.anywhereHotspot then
			self:setMapSelectionItem(hotspot)
		end
	end
	self:refreshContextInput()
end
function InGameMenuMapFrame:onClickMap(element, worldX, worldZ)
	if self.isPickingLocation then
		self:executePickingCallback(true, worldX, worldZ)
	elseif self.isPickingRotation then
		local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
		self:executePickingCallback(true, angle)
	else
		if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
			local farmland = g_farmlandManager:getFarmlandAtWorldPosition(worldX, worldZ)
			if farmland ~= nil and farmland.showOnFarmlandsScreen then
				self:setMapSelectionItem(farmland ~= nil and farmland:getMapHotspot() or nil)
			end
		elseif self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW or self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST then
			self:setMapSelectionItem(nil)
		end
	end
end
function InGameMenuMapFrame:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
	self:selectFirstHotspot()
end
function InGameMenuMapFrame:onPauseChanged(isActive)
	self:setMapSelectionItem(self.currentHotspot)
end
function InGameMenuMapFrame:selectFirstHotspot()
	local firstHotspot = self.ingameMapBase:cycleVisibleHotspot(nil, InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES, 1)
	self:setMapSelectionItem(firstHotspot)
end
function InGameMenuMapFrame:onVehicleReset(state)
	self.isResetPending = false
	g_messageCenter:unsubscribe(ResetVehicleEvent, self)
	if state == ResetVehicleEvent.STATE_SUCCESS then
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_DONE), nil, nil, DialogElement.TYPE_INFO)
		self:selectFirstHotspot()
	elseif state == ResetVehicleEvent.STATE_FAILED then
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_FAILED))
	elseif state == ResetVehicleEvent.STATE_IN_USE then
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_IN_USE))
	else
		InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_NO_PERMISSION))
	end
end
function InGameMenuMapFrame:onClickResetVehicle()
	local mission = g_currentMission
	if not self.isResetPending and ((mission.tourIconsBase == nil or not mission.tourIconsBase.visible) and self.currentHotspot ~= nil) then
		YesNoDialog.show(self.onYesNoReset, self, g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_CONFIRM), g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.VEHICLE_RESET))
	end
	return true
end
function InGameMenuMapFrame:onClickVisitPlace()
	if self.currentHotspot ~= nil then
		if self.currentHotspot:isa(NPCHotspot) then
			local npc = self.currentHotspot:getNPC()
			if npc ~= nil then
				self.onClickBackCallback()
				if g_localPlayer:getCurrentVehicle() ~= nil then
					g_localPlayer:leaveVehicle()
				end
				g_localPlayer:teleportToNPC(npc)
			end
		else
			local x = nil
			local y = nil
			local z = nil
			if self.currentHotspot:isa(FarmlandHotspot) then
				x, z = self.currentHotspot:getWorldPosition()
				y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
			else
				x, y, z = self.currentHotspot:getTeleportWorldPosition()
			end
			if x ~= nil and (y ~= nil and z ~= nil) then
				self.onClickBackCallback()
				if g_localPlayer:getCurrentVehicle() ~= nil then
					g_localPlayer:leaveVehicle()
				end
				g_localPlayer:teleportTo(x, y, z)
			end
		end
	end
	return true
end
function InGameMenuMapFrame:onClickTagPlace()
	if self.currentHotspot ~= nil and (self.currentHotspot.worldX ~= nil and self.currentHotspot.worldZ ~= nil) then
		local mission = g_currentMission
		if mission.currentMapTargetHotspot ~= self.currentHotspot then
			self.contextActions[InGameMenuMapFrame.ACTIONS.SET_MARKER].isActive = false
			self.contextActions[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER].isActive = true
			mission:setMapTargetHotspot(self.currentHotspot)
		else
			self.contextActions[InGameMenuMapFrame.ACTIONS.SET_MARKER].isActive = true
			self.contextActions[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER].isActive = false
			mission:setMapTargetHotspot(nil)
		end
		self:refreshContextInput()
	end
	return true
end
function InGameMenuMapFrame:onClickManage()
	if self.currentHotspot ~= nil then
		local placeable = self.currentHotspot:getPlaceable()
		local productionPoint = nil
		if placeable ~= nil and placeable.spec_productionPoint ~= nil then
			productionPoint = placeable.spec_productionPoint.productionPoint
		end
		g_inGameMenu:openProductionScreen(productionPoint)
	end
end
function InGameMenuMapFrame:onClickEnterVehicle()
	local mission = g_currentMission
	if not mission.isPlayerFrozen then
		local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot) or InGameMenuMapUtil.getHotspotVehicle(self.currentVehicleHotspot)
		if vehicle ~= nil and (vehicle.getIsEnterableFromMenu ~= nil and vehicle:getIsEnterableFromMenu()) then
			self.onClickBackCallback()
			g_localPlayer:requestToEnterVehicle(vehicle)
		end
	end
	return true
end
function InGameMenuMapFrame:onClickSellVehicle()
	local mission = g_currentMission
	if not mission.isPlayerFrozen then
		local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot) or InGameMenuMapUtil.getHotspotVehicle(self.currentVehicleHotspot)
		local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
		g_shopController:sell(storeItem, vehicle)
		self:setMapSelectionItem(nil)
	end
	return true
end
function InGameMenuMapFrame:onClickBuy()
	if self.selectedFarmland ~= nil then
		if g_missionManager:getIsMissionRunningOnFarmland(self.selectedFarmland) then
			InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_ACTIVE_MISSION))
			return false
		end
		if self.selectedFarmland.price <= self.playerFarm:getBalance() then
			local text = string.format(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND), g_i18n:formatMoney(self.selectedFarmland.price, 0, true, true))
			local title = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE)
			local callback = self.onYesNoBuyFarmland
			YesNoDialog.show(callback, self, text, title)
		else
			InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY), nil, nil, DialogElement.TYPE_WARNING)
		end
	else
		local placeable = self.currentHotspot:getPlaceable()
		if placeable ~= nil then
			if placeable.spec_productionPoint ~= nil then
				placeable.spec_productionPoint.productionPoint:buyRequest(self.onYesNoBuyOrSellPlaceable, self)
			elseif placeable.spec_factory ~= nil then
				placeable:buyRequest(self.onYesNoBuyOrSellPlaceable, self)
			end
		end
	end
	return true
end
function InGameMenuMapFrame:onClickSell()
	if self.selectedFarmland ~= nil then
		local mission = g_currentMission
		if mission.placeableSystem:getArePlaceablesOnFarmland(g_localPlayer.farmId, self.selectedFarmland.id) then
			InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_CANNOT_SELL_WTIH_PLACEABLES))
		else
			local price = self.selectedFarmland.price
			local text = string.format(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND), g_i18n:formatMoney(price, 0, true, true))
			local title = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND_TITLE)
			local callback = self.onYesNoSellFarmland
			YesNoDialog.show(callback, self, text, title)
		end
	else
		local placeable = self.currentHotspot:getPlaceable()
		local price, forFullPrice = placeable:getSellPrice()
		local text = string.format(g_i18n:getText("ui_constructionSellConfirmation"), placeable:getName(), g_i18n:formatMoney(price, 0, true, true))
		local callback = function(yes)
			if yes then
				g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(placeable, nil, forFullPrice))
			end
			self:onYesNoBuyOrSellPlaceable(yes)
		end
		YesNoDialog.show(callback, nil, text)
		self:setMapSelectionItem(nil)
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
	elseif self.mapOverviewSelector:getState() == InGameMenuMapFrame.AI_WORKER_LIST then
		if self.currentHotspot ~= nil then
			self:setMapSelectionItem(nil)
		elseif self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
			if self.selectedFarmland ~= nil then
				self:setMapSelectionItem(nil)
			end
		end
	end
	return true
end
function InGameMenuMapFrame:onStartGoToJob()
	local mission = g_currentMission
	if not mission.paused and self:getCanGoTo() then
		self:tryStartGoToJob()
	end
	return true
end
function InGameMenuMapFrame:onStartCancelJob()
	local mission = g_currentMission
	if not mission.paused then
		if self:getCanCancelJob() then
			self:cancelJob()
		elseif self:getCanStartJob() then
			self:startJob()
		end
	end
	return true
end
function InGameMenuMapFrame:onSkipJobTask()
	local mission = g_currentMission
	if not mission.paused and self:getCanSkipJobTask() then
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
function InGameMenuMapFrame:onClickDeselectAll(exceptionSection, exceptionIndex)
	if self.hotspotModeActive then
		self:setHotspotModeActive(false)
	end
	local overviewIndex = self.mapOverviewSelector:getState()
	local selectAll = self.numSelectedFilters[overviewIndex] == 0
	if selectAll then
		self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
		self.numSelectedFilters[overviewIndex] = #self.displayCropTypes
	else
		self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
		self.numSelectedFilters[overviewIndex] = 0
	end
	if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
		local currentFilterTable = self.dataTables[overviewIndex][1]
		local currentFilterState = self.filterStates[overviewIndex][1]
		for index, filter in pairs(currentFilterTable) do
			if exceptionSection == 1 then
				if exceptionIndex == index then
					currentFilterState[index] = not selectAll
					self.numSelectedFilters[overviewIndex] = 1
					self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
					self.ingameMapBase:setDefaultFilterValue(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1][index].id, not selectAll)
				else
					currentFilterState[index] = selectAll
					self.ingameMapBase:setDefaultFilterValue(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1][index].id, selectAll)
				end
			end
		end
		currentFilterTable = self.dataTables[overviewIndex][2]
		currentFilterState = self.filterStates[overviewIndex][2]
		for index, filter in pairs(currentFilterTable) do
			local hotspotCategory = InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[2][index].id
			if exceptionSection == 2 then
				if exceptionIndex == index then
					currentFilterState[index] = not selectAll
					self.numSelectedFilters[overviewIndex] = 1
					self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
					self.ingameMapBase:setDefaultFilterValue(hotspotCategory, not selectAll)
					if hotspotCategory == MapHotspot.CATEGORY_OTHER then
						self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, not selectAll)
					end
				else
					currentFilterState[index] = selectAll
					self.ingameMapBase:setDefaultFilterValue(hotspotCategory, selectAll)
					if hotspotCategory == MapHotspot.CATEGORY_OTHER then
						self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, selectAll)
					end
				end
			end
		end
	else
		local currentFilterTable = self.dataTables[overviewIndex]
		local currentFilterState = self.filterStates[overviewIndex]
		for index, filter in pairs(currentFilterTable) do
			local stateIndex = index
			if filter.soilStateIndex ~= nil then
				stateIndex = filter.soilStateIndex
			end
			if overviewIndex == InGameMenuMapFrame.MAP_FRUIT_TYPE then
				local fruitTypeDesc = self.displayCropTypes[index]
				stateIndex = fruitTypeDesc.fruitTypeIndex
			end
			if exceptionIndex == index then
				currentFilterState[stateIndex] = not selectAll
				self.numSelectedFilters[overviewIndex] = 1
				self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
			else
				currentFilterState[stateIndex] = selectAll
			end
		end
	end
	self:generateOverviewOverlay()
	self:saveFilters()
end
function InGameMenuMapFrame:onYesNoReset(yes)
	if yes then
		if self.currentHotspot ~= nil then
			local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
			if vehicle ~= nil then
				self:setMapSelectionItem(nil)
				g_messageCenter:subscribe(ResetVehicleEvent, self.onVehicleReset, self)
				self.isResetPending = true
				g_client:getServerConnection():sendEvent(ResetVehicleEvent.new(vehicle))
			end
		end
	else
		self.elementToFocus = self.contextButtonList
	end
end
function InGameMenuMapFrame:onYesNoBuyFarmland(yes)
	if yes then
		local price = self.selectedFarmland.price
		if price <= self.playerFarm:getBalance() then
			local mission = g_currentMission
			self.client:getServerConnection():sendEvent(FarmlandStateEvent.new(self.selectedFarmland.id, mission:getFarmId(), price))
			self:setMapSelectionItem()
			InGameMenuMapUtil.hideContextBox(self.contextBox)
			InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
			InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
		end
	else
		self.elementToFocus = self.contextButtonListFarmland
	end
end
function InGameMenuMapFrame:onYesNoSellFarmland(yes)
	if yes then
		local price = self.selectedFarmland.price
		self.client:getServerConnection():sendEvent(FarmlandStateEvent.new(self.selectedFarmland.id, FarmlandManager.NO_OWNER_FARM_ID, price))
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
	if self.currentHotspot ~= nil then
		self.elementToFocus = self.contextButtonList
	else
		self.elementToFocus = self.filterList
	end
end
function InGameMenuMapFrame:onCreateJob()
	local mission = g_currentMission
	if self:getCanCreateJob() and not mission.paused then
		self:createJob()
	end
	return true
end
function InGameMenuMapFrame:updateInputGlyphs()
	local moveActions = nil
	local moveText = nil
	local isGamepadContext = self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD
	if isGamepadContext then
		moveText = self.moveCursorText
		moveActions = { InputAction.AXIS_MAP_SCROLL_LEFT_RIGHT, InputAction.AXIS_MAP_SCROLL_UP_DOWN }
	else
		moveText = self.panMapText
		moveActions = { InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, InputAction.AXIS_LOOK_UPDOWN_DRAG }
	end
	self.mapMoveGlyph:setActions(moveActions, nil, nil, true)
	self.mapZoomGlyph:setActions({ InputAction.AXIS_MAP_ZOOM_OUT, InputAction.AXIS_MAP_ZOOM_IN }, nil, nil, false)
	self.mapMoveGlyphText:setText(moveText)
	self.mapZoomGlyphText:setText(self.zoomText)
	self.switchVehicleGlyph:setVisible(self.hotspotModeActive and isGamepadContext)
	self.switchVehicleGlyphText:setVisible(self.hotspotModeActive and isGamepadContext)
	self.switchVehicleGlyph:setActions({ InputAction.SWITCH_VEHICLE, InputAction.SWITCH_VEHICLE_BACK })
	self.buttonBox:invalidateLayout()
end
function InGameMenuMapFrame:validateParameters()
	local isValid = true
	local errorText = ""
	if self.currentJob ~= nil then
		self.currentJob:setValues()
		isValid, errorText = self.currentJob:validate(g_localPlayer.farmId)
		self:updateWarnings()
	end
	self.errorMessage:setText(errorText)
	self.errorMessage:setVisible(not isValid)
end
function InGameMenuMapFrame:updateWarnings()
	for _, element in ipairs(self.currentJobElements) do
		local param = element.aiParameter
		local invalidElement = element:getDescendantByName("invalid")
		if invalidElement == nil then
			continue
		end
		invalidElement:setVisible(not param:getIsValid())
	end
end
function InGameMenuMapFrame:addStatusMessage(message)
	table.insert(self.statusMessages, { text = message, removeTime = g_time + 5000 })
	self:updateStatusMessages()
end
function InGameMenuMapFrame:updateStatusMessages()
	local text = ""
	for _, message in ipairs(self.statusMessages) do
		text = text .. message.text .. "\n"
	end
	self.statusMessage:setText(text)
end
function InGameMenuMapFrame:onJobTypeChanged(index)
	local jobTypeIndex = self.currentJobTypes[index]
	self:setActiveJobTypeSelection(jobTypeIndex)
end
function InGameMenuMapFrame:onAIJobStarted(job, farmId)
	if g_localPlayer ~= nil and farmId == g_localPlayer.farmId then
		table.insert(self.playerFarmActiveJobs, job.jobId)
	end
	self.activeWorkerList:reloadData()
	self.createJobEmptyText:setVisible(not self.createJobContainer:getIsVisible() and self.activeWorkerList:getItemCount() == 0)
end
function InGameMenuMapFrame:onAIJobRemoved(jobId)
	table.removeElement(self.playerFarmActiveJobs, jobId)
	self.activeWorkerList:reloadData()
	self.createJobEmptyText:setVisible(false)
	InGameMenuMapUtil.hideContextBox(self.contextBox)
	InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
	InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
end
function InGameMenuMapFrame:onAIJobStopped(job, aiMessage)
	if aiMessage ~= nil and (job ~= nil and (g_localPlayer ~= nil and job.startedFarmId == g_localPlayer.farmId)) then
		local text = aiMessage:getMessage(job)
		self:addStatusMessage(text)
	end
end
function InGameMenuMapFrame:updateParameterValueTexts()
	local mission = g_currentMission
	mission:removeMapHotspot(self.aiTargetMapHotspot)
	mission:removeMapHotspot(self.aiLoadingMarkerHotspot)
	mission:removeMapHotspot(self.aiUnloadingMarkerHotspot)
	local addedPositionHotspot = false
	for _, element in ipairs(self.currentJobElements) do
		local parameter = element.aiParameter
		local parameterType = parameter:getType()
		if parameterType == AIParameterType.TEXT then
			local title = element:getDescendantByName("title")
			title:setText(parameter:getString())
		elseif parameterType == AIParameterType.POSITION or parameterType == AIParameterType.POSITION_ANGLE then
			element:setText(parameter:getString())
			mission:addMapHotspot(self.aiTargetMapHotspot)
			local x, z = parameter:getPosition()
			self.aiTargetMapHotspot:setWorldPosition(x, z)
			if parameterType == AIParameterType.POSITION_ANGLE then
				local angle = parameter:getAngle() + 3.141592653589793
				self.aiTargetMapHotspot:setWorldRotation(angle)
			end
		else
			element:updateTitle()
			if parameterType == AIParameterType.UNLOADING_STATION then
				local unloadingStation = parameter:getUnloadingStation()
				if unloadingStation == nil then
					continue
				end
				local placeable = unloadingStation.owningPlaceable
				if placeable == nil or placeable.getHotspot == nil then
					continue
				end
				local hotspot = placeable:getHotspot(1)
				if hotspot == nil then
					continue
				end
				local x, z = hotspot:getWorldPosition()
				self.aiUnloadingMarkerHotspot:setWorldPosition(x, z)
				if not self.isLoadAndDeliverParameter then
					self.ingameMap:panToHotspot(self.aiUnloadingMarkerHotspot)
				end
				mission:addMapHotspot(self.aiUnloadingMarkerHotspot)
			elseif parameterType == AIParameterType.LOADING_STATION then
				local loadingStation = parameter:getLoadingStation()
				if loadingStation == nil then
					continue
				end
				local placeable = loadingStation.owningPlaceable
				if placeable == nil or placeable.getHotspot == nil then
					continue
				end
				local hotspot = placeable:getHotspot(1)
				if hotspot == nil then
					continue
				end
				local x, z = hotspot:getWorldPosition()
				self.aiLoadingMarkerHotspot:setWorldPosition(x, z)
				if self.isLoadingStationParameterClick then
					self.ingameMap:panToHotspot(self.aiLoadingMarkerHotspot)
				end
				mission:addMapHotspot(self.aiLoadingMarkerHotspot)
			end
		end
	end
end
function InGameMenuMapFrame:onClickMultiTextOptionParameter(index, element)
	if self.currentJob ~= nil then
		local parameter = element.aiParameter
		self.currentJob:onParameterValueChanged(parameter)
		self.isLoadingStationParameterClick = parameter:getType() == AIParameterType.LOADING_STATION
		self:updateParameterValueTexts()
	end
	self:validateParameters()
end
function InGameMenuMapFrame:onClickPositionParameter(element)
	local parameter = element.aiParameter
	self:startPickPosition(parameter, function(success, x, z)
		if success then
			element:setText(parameter:getString())
		end
	end)
end
function InGameMenuMapFrame:onClickPositionRotationParameter(element)
	local parameter = element.aiParameter
	self:startPickPositionAndRotation(parameter, function(success, x, z, angle)
		if success then
			element:setText(parameter:getString())
		end
	end)
end
function InGameMenuMapFrame:getNumberOfSections(list)
	if list == self.filterList and self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS then
		return 2
	end
	return 1
end
function InGameMenuMapFrame:getTitleForSectionHeader(list, section)
	if list == self.filterList and self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS then
		return section == 1 and g_i18n:getText("ui_mapHotspotFilter_vehicles") or g_i18n:getText("construction_category_buildings")
	end
	return ""
end
function InGameMenuMapFrame:getNumberOfItemsInSection(list, section)
	if list == self.filterList then
		if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
			return #self.farmlandItems
		end
		if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS then
			return #InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[section]
		end
		local state = self.mapOverviewSelector:getState()
		local data = self.dataTables[state]
		if data == nil then
			Logging.devError("No data found for map overlay selector state '%s'", state)
			if g_showDevelopmentWarnings then
				printCallstack()
			end
			return 0
		else
			return #data
		end
	end
	if list == self.contextButtonList or list == self.contextButtonListFarmland then
		if self.mode == InGameMenuMapFrame.AI_MODE_CREATE then
			return 0
		else
			self.contextActionMapping = {}
			for index, action in ipairs(self.contextActions) do
				if action.isActive then
					table.insert(self.contextActionMapping, index)
				end
			end
			return #self.contextActionMapping
		end
	end
	if list == self.activeWorkerList and g_currentMission ~= nil then
		return #self.playerFarmActiveJobs
	end
	return 0
end
function InGameMenuMapFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.filterList then
		local overviewIndex = self.mapOverviewSelector:getState()
		if overviewIndex == InGameMenuMapFrame.MAP_FARMLANDS then
			cell:getAttribute("icon"):setVisible(false)
			local iconBg = cell:getAttribute("iconBg")
			local farmlandsFarm = self.farmlandItems[index]
			function iconBg.getIsSelected()
				return true
			end
			self:assignItemColors(iconBg, { farmlandsFarm.color })
			cell:getAttribute("name"):setText(farmlandsFarm.name)
			return
		else
			local selectionIndex = index
			if overviewIndex == InGameMenuMapFrame.MAP_SOIL then
				selectionIndex = self.displaySoilStateMapping[index].soilStateIndex
			end
			local getIsSelectedFunc = function()
				return self.filterStates[overviewIndex][selectionIndex]
			end
			if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
				function getIsSelectedFunc()
					return self.filterStates[overviewIndex][section][selectionIndex]
				end
			elseif overviewIndex == InGameMenuMapFrame.MAP_FRUIT_TYPE then
				function getIsSelectedFunc()
					local fruitTypeDesc = self.displayCropTypes[selectionIndex]
					return self.filterStates[overviewIndex][fruitTypeDesc.fruitTypeIndex]
				end
			end
			local icon = cell:getAttribute("icon")
			icon:setVisible(true)
			icon.getIsSelected = getIsSelectedFunc
			local iconBg = cell:getAttribute("iconBg")
			iconBg.getIsSelected = getIsSelectedFunc
			local status = self.dataTables[overviewIndex][index]
			if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS then
				status = self.dataTables[overviewIndex][section][index]
			end
			if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
				cell:getAttribute("name"):setText(g_i18n:getText(status.name))
				icon:setImageSlice(nil, status.sliceId)
				self:assignItemColors(iconBg, status.color)
			else
				local statusColor = status.colors[self.isColorBlindMode]
				cell:getAttribute("name"):setText(status.description)
				if overviewIndex == InGameMenuMapFrame.MAP_FRUIT_TYPE then
					self:assignItemColors(iconBg, { { statusColor.r, statusColor.g, statusColor.b, statusColor.a } })
					icon:setImageFilename(status.iconFilename)
					icon:setImageUVs(nil, unpack(Overlay.DEFAULT_UVS))
				else
					self:assignItemColors(iconBg, statusColor, cell:getAttribute("colorTemplate"), getIsSelectedFunc)
					icon:setVisible(false)
				end
			end
			return
		end
	end
	if list == self.contextButtonList or list == self.contextButtonListFarmland then
		local buttonInfo = self.contextActions[self.contextActionMapping[index]]
		cell:getAttribute("text"):setText(buttonInfo.title or g_i18n:getText(buttonInfo.text))
		cell.onClickCallback = buttonInfo.callback
		if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
			cell:getAttribute("button"):applyProfile(InGameMenuMapFrame.PROFILE.CONTEXT_BUTTON_GAMEPAD)
			return
		else
			cell:getAttribute("button"):applyProfile(InGameMenuMapFrame.PROFILE.CONTEXT_BUTTON)
			return
		end
	end
	if list == self.activeWorkerList then
		local count = 0
		local currentJob = nil
		local farmId = 1
		if g_localPlayer ~= nil then
			farmId = g_localPlayer.farmId
		end
		local mission = g_currentMission
		for _, job in ipairs(mission.aiSystem:getActiveJobs()) do
			if job.startedFarmId == farmId then
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
function InGameMenuMapFrame:assignItemColors(colorElement, stateColors, colorTemplate, selectedFunc)
	for i = #colorElement.elements, 1, -1 do
		colorElement.elements[i]:delete()
	end
	local partWidth = colorElement.size[1] / #stateColors
	colorElement:setImageColor(GuiOverlay.STATE_SELECTED, unpack(stateColors[1]))
	if 1 < #stateColors then
		for i = 2, #stateColors do
			local newPart = colorTemplate:clone(colorElement)
			newPart:setSize(partWidth, nil)
			newPart:setPosition((i - 1) * partWidth, 0)
			newPart:setImageColor(GuiOverlay.STATE_SELECTED, unpack(stateColors[i]))
			newPart.getIsSelected = selectedFunc
		end
	end
end
function InGameMenuMapFrame:getHasChangeableFilterList()
	return self.mapOverviewSelector:getState() <= InGameMenuMapFrame.MAP_HOTSPOTS
end
function InGameMenuMapFrame:onClickList(list, section, index, listElement)
	local overviewIndex = self.mapOverviewSelector:getState()
	if list == self.filterList and self:getHasChangeableFilterList() then
		if self.hotspotModeActive then
			self:setHotspotModeActive(false)
		end
		local statusFilter = self.filterStates[overviewIndex]
		if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
			statusFilter = self.filterStates[overviewIndex][section]
		end
		if overviewIndex == InGameMenuMapFrame.MAP_SOIL then
			index = self.displaySoilStateMapping[index].soilStateIndex
		end
		local filterIndex = index
		if overviewIndex == InGameMenuMapFrame.MAP_FRUIT_TYPE then
			local fruitTypeDesc = self.displayCropTypes[index]
			filterIndex = fruitTypeDesc.fruitTypeIndex
		end
		statusFilter[filterIndex] = not statusFilter[filterIndex]
		if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
			local hotspotCategory = self.dataTables[overviewIndex][section][index].id
			self.ingameMapBase:toggleDefaultFilter(hotspotCategory)
			if hotspotCategory == MapHotspot.CATEGORY_OTHER then
				self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, self.ingameMapBase:getDefaultFilterValue(MapHotspot.CATEGORY_OTHER))
			end
			self:setMapSelectionItem(nil)
		else
			self:generateOverviewOverlay()
		end
		self:saveFilters()
		if statusFilter[filterIndex] then
			self.numSelectedFilters[overviewIndex] = self.numSelectedFilters[overviewIndex] + 1
		else
			self.numSelectedFilters[overviewIndex] = self.numSelectedFilters[overviewIndex] - 1
		end
		if self.numSelectedFilters[overviewIndex] == 0 then
			self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
			return
		else
			self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
			return
		end
	end
	if list == self.contextButtonList or list == self.contextButtonListFarmland then
		listElement.onClickCallback(self)
		return
	end
	if list == self.activeWorkerList then
		local mission = g_currentMission
		local job = mission.aiSystem:getJobById(self.playerFarmActiveJobs[index])
		if job ~= nil and job.vehicleParameter then
			local vehicle = job.vehicleParameter:getVehicle()
			if vehicle ~= nil then
				local hotspot = vehicle:getMapHotspot()
				self:setMapSelectionItem(hotspot)
				self.ingameMap:panToHotspot(hotspot)
			end
		end
	end
end
function InGameMenuMapFrame:onListSelectionChanged(list, section, index)
	if list == self.activeWorkerList and not self.blockListSelectionUpdates then
		local mission = g_currentMission
		local job = mission.aiSystem:getJobById(self.playerFarmActiveJobs[index])
		if job ~= nil and job.vehicleParameter then
			local vehicle = job.vehicleParameter:getVehicle()
			if vehicle ~= nil then
				local hotspot = vehicle:getMapHotspot()
				self.mode = InGameMenuMapFrame.AI_MODE_WORKER_LIST
				self:setMapSelectionItem(hotspot)
				self.ingameMap:panToHotspot(hotspot)
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
function InGameMenuMapFrame:unregisterInput(customOnly)
	local list = customOnly and InGameMenuMapFrame.CLEAR_CLOSE_INPUT_ACTIONS or InGameMenuMapFrame.CLEAR_INPUT_ACTIONS
	for _, actionName in pairs(list) do
		g_inputBinding:removeActionEventsByActionName(actionName)
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
	else
		if self.buttonStartJobContainer:getIsVisible() then
			self:onStartCancelJob()
		end
	end
end
function InGameMenuMapFrame:onSwitchVehicle(_, value, direction)
	if self.contextBoxFarmland:getIsVisible() then
		self:setMapSelectionItem(nil)
	end
	local newHotspot = self.ingameMapBase:cycleVisibleHotspot(self.currentHotspot, InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES, direction)
	self:setMapSelectionItem(newHotspot)
	self.ingameMap:panToHotspot(newHotspot, self.filterBox.absSize[1] * 0.5)
end
function InGameMenuMapFrame:getIsPicking()
	return self.isPickingRotation or self.isPickingLocation
end
function InGameMenuMapFrame:executePickingCallback(...)
	self.ingameMap:setHotspotSelectionActive(true)
	self.isPickingLocation = false
	self.isPickingRotation = false
	self.ingameMap:unlockMapMovement()
	local cb = self.pickingCallback
	self.pickingCallback = nil
	if cb ~= nil then
		cb(...)
	end
end
function InGameMenuMapFrame:startPickPosition(parameter, callback)
	self.ingameMap:setHotspotSelectionActive(false)
	self.ingameMap:setIsCursorAvailable(false)
	self.isPickingLocation = true
	self:showActionMessage("ui_ai_pickTargetLocation")
	local mission = g_currentMission
	mission:removeMapHotspot(self.aiTargetMapHotspot)
	mission:addMapHotspot(self.aiTargetMapHotspot)
	self.contextBox:setVisible(false)
	function self.pickingCallback(success, x, z)
		self:showActionMessage()
		self.ingameMap:setIsCursorAvailable(true)
		self.hasPickedRotationTouch = false
		self.contextBox:setVisible(true)
		if success then
			parameter:setValue(x, z)
			self.aiTargetMapHotspot:setWorldPosition(x, z)
		end
		callback(success, x, z, parameter)
		self:validateParameters()
	end
end
function InGameMenuMapFrame:startPickPositionAndRotation(parameter, callback)
	self.isPickingLocation = true
	self.ingameMap:setHotspotSelectionActive(false)
	self.ingameMap:setIsCursorAvailable(false)
	self:showActionMessage("ui_ai_pickTargetLocation")
	local mission = g_currentMission
	mission:removeMapHotspot(self.aiTargetMapHotspot)
	mission:addMapHotspot(self.aiTargetMapHotspot)
	self.contextBox:setVisible(false)
	function self.pickingCallback(success, x, z)
		self:showActionMessage()
		self.ingameMap:setIsCursorAvailable(true)
		self.hasPickedRotationTouch = false
		self.contextBox:setVisible(true)
		if success then
			self.ingameMap:setHotspotSelectionActive(false)
			self.ingameMap:setIsCursorAvailable(false)
			self.aiTargetMapHotspot:setWorldPosition(x, z)
			self.isPickingRotation = true
			self.ingameMap:lockMapMovement()
			self.pickingRotationOrigin = { x, z }
			self.pickingRotationSnapAngle = parameter:getSnappingAngle()
			self:showActionMessage("ui_ai_pickTargetRotation")
			self.contextBox:setVisible(false)
			function self.pickingCallback(successRotation, angle)
				self:showActionMessage()
				self.ingameMap:setIsCursorAvailable(true)
				self.contextBox:setVisible(true)
				if successRotation then
					parameter:setPosition(x, z)
					parameter:setAngle(angle)
					local convertedAngle = parameter:getAngle()
					self.aiTargetMapHotspot:setWorldRotation(convertedAngle + 3.141592653589793)
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
		for i = #self.jobMenuLayout.elements, 1, -1 do
			self.jobMenuLayout.elements[i]:delete()
		end
		self.currentJobElements = {}
		self.jobMenuLayout:invalidateLayout()
		self.jobTypeElement:setTexts({})
		self.createJobContainer:setVisible(false)
		FocusManager:setFocus(self.mapOverviewSelector)
	end
	self.createJobContainer:setVisible(isVisible)
	self.createJobEmptyText:setVisible(not isVisible and self.activeWorkerList:getItemCount() == 0)
	self.mapOverviewSelector:setDisabled(isVisible)
end
function InGameMenuMapFrame:createJob()
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
		local mission = g_currentMission
		local aiJobTypeManager = mission.aiJobTypeManager
		for name, index in pairs(AIJobType) do
			if self.jobTypeInstances[index]:getIsAvailableForVehicle(vehicle) then
				table.insert(self.currentJobTypes, index)
				table.insert(currentJobTypesTexts, aiJobTypeManager:getJobTypeByIndex(index).title)
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
		self.jobTypeElement:setTexts(currentJobTypesTexts)
		self.jobTypeElement:setState(currentIndex or 1)
		self.mode = InGameMenuMapFrame.AI_MODE_CREATE
		self.currentJobVehicle = vehicle
		self.currentJob = nil
		self:setJobMenuVisible(true)
		FocusManager:setFocus(self.jobTypeElement)
		self:setActiveJobTypeSelection(currentJobTypeIndex)
	end
end
function InGameMenuMapFrame:tryStartGoToJob()
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
		end
	end
end
function InGameMenuMapFrame:tryStartJob(job, farmId, callback)
	self.startJobPending = true
	g_messageCenter:subscribe(AIJobStartRequestEvent, self.onStartedJob, self, { callback })
	g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, farmId))
end
function InGameMenuMapFrame:onStartedJob(args, state, jobTypeIndex)
	local callback = args[1]
	self.startJobPending = false
	g_messageCenter:unsubscribe(AIJobStartRequestEvent, self)
	if state == AIJob.START_SUCCESS then
		self.mapOverviewSelector:setState(InGameMenuMapFrame.AI_WORKER_LIST, true)
		FocusManager:setFocus(self.activeWorkerList)
	else
		local mission = g_currentMission
		local jobType = mission.aiJobTypeManager:getJobTypeByIndex(jobTypeIndex)
		local text = jobType.classObject.getIsStartErrorText(state)
		InfoDialog.show(text, nil, nil, DialogElement.TYPE_INFO)
	end
	callback(state)
end
function InGameMenuMapFrame:skipCurrentTask()
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
InGameMenuMapFrame.INPUT_CONTEXT_NAME = "MENU_MAP_OVERVIEW"
InGameMenuMapFrame.CLEAR_INPUT_ACTIONS = { InputAction.MENU_ACTIVATE, InputAction.MENU_CANCEL, InputAction.MENU_EXTRA_2, InputAction.CAMERA_ZOOM_IN_OUT }
InGameMenuMapFrame.CLEAR_CLOSE_INPUT_ACTIONS = { InputAction.CAMERA_ZOOM_IN_OUT }
InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES = { [MapHotspot.CATEGORY_STEERABLE] = true, [MapHotspot.CATEGORY_COMBINE] = true, [MapHotspot.CATEGORY_TRAILER] = true, [MapHotspot.CATEGORY_TOOL] = true, [MapHotspot.CATEGORY_OTHER] = false, [MapHotspot.CATEGORY_AI] = true, [MapHotspot.CATEGORY_PLAYER] = false }
InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES = {
	{ { id = MapHotspot.CATEGORY_STEERABLE, sliceId = "gui.ingameMap_vehicles", name = "ui_mapHotspotFilter_vehicles", color = { { 0.13, 0.13, 0.13, 1 } } }, { id = MapHotspot.CATEGORY_COMBINE, sliceId = "gui.ingameMap_harvester", name = "ui_mapHotspotFilter_combines", color = { { 0.13, 0.13, 0.13, 1 } } }, { id = MapHotspot.CATEGORY_TRAILER, sliceId = "gui.ingameMap_trailer", name = "ui_mapHotspotFilter_trailers", color = { { 0.13, 0.13, 0.13, 1 } } }, { id = MapHotspot.CATEGORY_TOOL, sliceId = "gui.ingameMap_tools", name = "ui_mapHotspotFilter_tools", color = { { 0.13, 0.13, 0.13, 1 } } }, { id = MapHotspot.CATEGORY_AI, sliceId = "gui.ingameMap_helper", name = "ui_mapHotspotFilter_ai", color = { { 0.13, 0.13, 0.13, 1 } } } },
	{ { id = MapHotspot.CATEGORY_UNLOADING, sliceId = "gui.ingameMap_tippingStation", name = "ui_mapHotspotFilter_tipStations", color = { { 0.26635, 0.00477, 0.11443, 1 } } }, { id = MapHotspot.CATEGORY_LOADING, sliceId = "gui.ingameMap_loadingStation", name = "ui_mapHotspotFilter_loadingStations", color = { { 0.02028, 0.07036, 0.43415, 1 } } }, { id = MapHotspot.CATEGORY_PRODUCTION, sliceId = "gui.ingameMap_productionPoint", name = "ui_mapHotspotFilter_productionPoints", color = { { 0.00651, 0.56471, 0.57758, 1 } } }, { id = MapHotspot.CATEGORY_ANIMAL, sliceId = "gui.ingameMap_animals", name = "ui_mapHotspotFilter_animals", color = { { 0.00604, 0.14412, 0.11443, 1 } } }, { id = MapHotspot.CATEGORY_MISSION, sliceId = "gui.ingameMap_contracts", name = "ui_mapHotspotFilter_contracts", color = { { 0.00303, 0.20155, 0.01599, 1 } } }, { id = MapHotspot.CATEGORY_OTHER, sliceId = "gui.ingameMap_other", name = "ui_mapHotspotFilter_others", color = { { 0.61049, 0.56471, 0.00303, 1 } } } },
}
InGameMenuMapFrame.GLYPH_SIZE = { 36, 36 }
InGameMenuMapFrame.GLYPH_TEXT_SIZE = 20
InGameMenuMapFrame.GLYPH_COLOR = { 1, 1, 1, 1 }
InGameMenuMapFrame.L10N_SYMBOL = {
	VEHICLE_RESET = "button_reset",
	SELECT_ALL = "button_selectAll",
	DESELECT_ALL = "button_deselectAll",
	DIALOG_VEHICLE_RESET_DONE = "ui_vehicleResetDone",
	DIALOG_VEHICLE_RESET_FAILED = "ui_vehicleResetFailed",
	DIALOG_VEHICLE_IN_USE = "shop_messageReturnVehicleInUse",
	DIALOG_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionGeneral",
	DIALOG_VEHICLE_RESET_CONFIRM = "ui_wantToResetVehicleText",
	DIALOG_BUY_FARMLAND = "shop_messageBuyFarmlandText",
	DIALOG_BUY_FARMLAND_TITLE = "shop_messageBuyFarmlandTitle",
	DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY = "shop_messageNotEnoughMoneyToBuyFarmland",
	DIALOG_BUY_FARMLAND_ACTIVE_MISSION = "shop_messageBuyFarmlandMissionRunning",
	DIALOG_SELL_FARMLAND = "shop_messageSellFarmlandText",
	DIALOG_SELL_FARMLAND_TITLE = "shop_messageSellFarmlandTitle",
	DIALOG_CANNOT_SELL_WTIH_PLACEABLES = "shop_messageCannotSellFarmlandWithPlaceables",
	INPUT_MOVE_CURSOR = "ui_ingameMenuMapMoveCursor",
	INPUT_PAN_MAP = "ui_ingameMenuMapPan",
	INPUT_ZOOM_MAP = "ui_ingameMenuMapZoom",
}
InGameMenuMapFrame.PROFILE = { MONEY_VALUE_NEUTRAL = "ingameMenuMapMoneyValue", MONEY_VALUE_NEGATIVE = "ingameMenuMapMoneyValueNegative", CONTEXT_BUTTON = "fs25_mapContextButtonListItemButton", CONTEXT_BUTTON_GAMEPAD = "fs25_mapContextButtonListItemButtonGamepad" }
InGameMenuMapFrame.ACTIONS = { GOTO_JOB = 1, ENTER_VEHICLE = 2, CREATE_JOB = 3, START_JOB = 4, CANCEL_JOB = 5, SKIP_TASK = 6, RESET_VEHICLE = 7, SELL_VEHICLE = 8, VISIT_PLACE = 9, MANAGE = 10, BUY = 11, SELL = 12, SET_MARKER = 13, REMOVE_MARKER = 14 }
