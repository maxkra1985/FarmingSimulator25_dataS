InGameMenuContractsFrame = {}
local InGameMenuContractsFrame_mt = Class(InGameMenuContractsFrame, TabbedMenuFrameElement)
InGameMenuContractsFrame.CONTRACT_STATE = { NEW = 1, ACTIVE = 2, FINISHED = 3 }
InGameMenuContractsFrame.BUTTON_STATE = { POSSIBLE = 0, ACTIVE = 1, FINISHED = 2, EMPTY = 3 }
InGameMenuContractsFrame.CONTRACT_STATE_TEXTS = { "ui_contractsNew", "ui_contractsActive" }
function InGameMenuContractsFrame.register()
	local inGameMenuContractsFrame = InGameMenuContractsFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuContractsFrame.xml", "ContractsFrame", inGameMenuContractsFrame, true)
end
function InGameMenuContractsFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuContractsFrame_mt)
	self.hasCustomMenuButtons = true
	self.vehicleElements = {}
	self.contracts = {}
	self.sectionContracts = {}
	self.updateTime = 0
	self.marqueeTime = 0
	return self
end
function InGameMenuContractsFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuContractsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function InGameMenuContractsFrame:initialize()
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
	self.acceptButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText("button_acceptContract"),
		callback = function()
			self:onButtonAccept()
		end,
	}
	self.leaseButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText("button_borrowItems"),
		callback = function()
			self:onButtonLease()
		end,
	}
	self.dismissButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText("button_contract_complete"),
		callback = function()
			self:onButtonDismiss()
		end,
	}
	self.cancelButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText("button_cancel"),
		callback = function()
			self:onButtonCancel()
		end,
	}
	self.vehicleTemplate:unlinkElement()
	local selectorTexts = {}
	for index, text in ipairs(InGameMenuContractsFrame.CONTRACT_STATE_TEXTS) do
		local dot = self.subCategoryDotTemplate:clone(self.subCategoryDotBox)
		function dot.getIsSelected()
			return self.subCategorySelector:getState() == index
		end
		table.insert(selectorTexts, g_i18n:getText(text))
	end
	self.subCategoryDotBox:invalidateLayout()
	self.subCategorySelector:setTexts(selectorTexts)
	g_messageCenter:subscribe(MessageType.MISSION_DELETED, self.onMissionDeleted, self)
end
function InGameMenuContractsFrame:delete()
	if self.vehicleTemplate ~= nil then
		self.vehicleTemplate:delete()
	end
	InGameMenuContractsFrame:superClass().delete(self)
	g_messageCenter:unsubscribeAll(self)
end
function InGameMenuContractsFrame:update(dt)
	InGameMenuContractsFrame:superClass().update(self, dt)
	local mission = g_currentMission
	local missionTime = mission.time
	if self.updateTime < missionTime then
		self.updateTime = missionTime + 5000
		local section, index = self.contractsList:getSelectedPath()
		self:updateDetailContents(section, index)
	end
	self:updateMarqueeAnimation(dt)
	if self.needsListFocus and FocusManager.currentGui == self.name then
		FocusManager:setFocus(self.contractsList)
		self.needsListFocus = false
	end
end
function InGameMenuContractsFrame:onFrameOpen(element)
	InGameMenuContractsFrame:superClass().onFrameOpen(self)
	g_messageCenter:subscribe(MissionStartedEvent, self.onMissionStart, self)
	g_messageCenter:subscribe(MessageType.MISSION_GENERATED, self.updateList, self)
	g_messageCenter:subscribe(MessageType.MISSION_DELETED, self.updateList, self)
	g_messageCenter:subscribe(MessageType.MISSION_STATUS_CHANGED, self.updateList, self)
	g_messageCenter:subscribe(PlayerPermissionsEvent, self.updateButtonsForPermissions, self)
	self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.POSSIBLE)
	self:setSoundSuppressed(true)
	self:updateList()
	FocusManager:setFocus(self.contractsList)
	self:setSoundSuppressed(false)
	self.ingameMap:onOpen()
	if self.customFilter ~= nil then
		self.ingameMapBase:applyCustomFilter(self.customFilter)
	end
	self.isOpen = true
end
function InGameMenuContractsFrame:onFrameClose(element)
	InGameMenuContractsFrame:superClass().onFrameClose(self)
	self.isOpen = false
	self.contracts = {}
	self.sectionContracts = {}
	self.ingameMap:onClose()
	self.ingameMapBase:restoreDefaultFilter()
	g_messageCenter:unsubscribe(MissionStartedEvent, self)
	g_messageCenter:unsubscribe(MessageType.MISSION_GENERATED, self)
	g_messageCenter:unsubscribe(MessageType.MISSION_DELETED, self, self.updateList)
	g_messageCenter:unsubscribe(MessageType.MISSION_STATUS_CHANGED, self)
	g_messageCenter:unsubscribe(PlayerPermissionsEvent, self)
end
function InGameMenuContractsFrame:setInGameMap(ingameMap)
	self.ingameMap:setIngameMap(ingameMap)
	self.ingameMapBase = ingameMap
	if ingameMap ~= nil then
		self.customFilter = ingameMap:createCustomFilter(true)
		self.customFilter[MapHotspot.CATEGORY_MISSION] = false
	end
end
function InGameMenuContractsFrame:updateButtonsForPermissions()
	local section, index = self.contractsList:getSelectedPath()
	self:updateDetailContents(section, index)
end
function InGameMenuContractsFrame:setButtonsForState(state, canLease)
	local info = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	local currentMission = g_currentMission
	local hasPermission = currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_CONTRACTS)
	if state == InGameMenuContractsFrame.BUTTON_STATE.FINISHED then
		table.insert(info, self.dismissButtonInfo)
		self.dismissButtonInfo.disabled = not hasPermission
	elseif state == InGameMenuContractsFrame.BUTTON_STATE.ACTIVE then
		table.insert(info, self.cancelButtonInfo)
		self.cancelButtonInfo.disabled = not hasPermission
	elseif 0 < self.contractsList:getItemCount() then
		table.insert(info, self.acceptButtonInfo)
		self.acceptButtonInfo.disabled = not hasPermission
		if canLease then
			table.insert(info, self.leaseButtonInfo)
			self.leaseButtonInfo.disabled = not hasPermission
		end
	end
	self.menuButtonInfo = info
	self:setMenuButtonInfoDirty()
end
function InGameMenuContractsFrame:onContractsChanged()
	self.contractsList:updateView()
end
function InGameMenuContractsFrame:onMissionDeleted(mission)
	if self.lastStartedMission == mission then
		self.lastStartedMission = nil
	end
	if self.currentContract ~= nil and self.currentContract.mission == mission then
		self.currentContract = nil
	end
end
function InGameMenuContractsFrame:onMissionStart()
	if self.currentContract ~= nil then
		self.lastStartedMission = self.currentContract.mission
	end
	self:updateList()
end
function InGameMenuContractsFrame:updateList()
	local currentMission = g_currentMission
	local list = g_missionManager:getMissionsByFarmId(currentMission:getFarmId())
	local hasMissions = #list ~= 0
	self.contractsListBox:setVisible(hasMissions)
	self.detailsList:setVisible(hasMissions)
	local selectedContract = self:getSelectedContract()
	if selectedContract ~= nil then
		self.storedSelected = selectedContract.mission.generationTime
	else
		self.storedSelected = nil
	end
	self.contracts = {}
	for _, mission in ipairs(list) do
		local sameFarm = g_localPlayer ~= nil and mission.farmId == g_localPlayer:getFarmId()
		local status = mission.status
		local isActive = status == MissionStatus.RUNNING or status == MissionStatus.PREPARING
		local isPreparing = status == MissionStatus.PREPARING
		local isFinished = status == MissionStatus.FINISHED or status == MissionStatus.DISMISSED
		local isPossible = status == MissionStatus.CREATED
		if not mission:getWasStarted() or sameFarm then
			local contract = { mission = mission, active = isActive, isPreparing = isPreparing, finished = isFinished, possible = isPossible }
			table.insert(self.contracts, contract)
		end
	end
	self:sortList()
	self.contractsList:reloadData()
	self.contentContainer:setVisible(0 < self.contractsList:getItemCount())
end
function InGameMenuContractsFrame:updateProgressBar(value)
	local fullWidth = self.progressBarBg.size[1] - self.progressBar.margin[1] * 2
	value = math.max(value, self.progressBar.startSize[1] * 2 / fullWidth)
	self.progressBar:setSize(fullWidth * math.min(value, 1), nil)
end
function InGameMenuContractsFrame:onDrawPostIngameMapHotspots()
	if self.currentContract ~= nil then
		local mission = self.currentContract.mission
		local hotspots = mission:getMapHotspots()
		if hotspots ~= nil then
			for _, hotspot in ipairs(hotspots) do
				self.ingameMap:drawHotspot(hotspot, false)
			end
		end
	end
end
function InGameMenuContractsFrame:updateDetailContents(section, index)
	local contract = nil
	local sectionContracts = self.sectionContracts[self.subCategorySelector:getState()][section]
	if sectionContracts ~= nil then
		contract = sectionContracts.contracts[index]
		self.currentContract = contract
		local mission = contract.mission
		local hotspots = mission:getMapHotspots()
		if hotspots ~= nil then
			for _, hotspot in ipairs(hotspots) do
				hotspot:postUpdate(9999)
			end
		end
		self.detailsList:reloadData()
	end
	for _, elem in pairs(self.vehicleElements) do
		elem:delete()
	end
	self.vehicleElements = {}
	self.vehiclesBox:invalidateLayout()
	if contract ~= nil then
		local mission = contract.mission
		self:updateFarmersBox(mission.field, mission:getNPC())
		local reward = mission:getReward()
		self.titleText:setText(mission:getTitle())
		self.contractDescriptionText:setText(mission:getDescription())
		self.rewardTitle:setText(g_i18n:getText("contract_reward"))
		self.equipmentBox:setVisible(contract.possible)
		self.progressBox:setVisible(contract.active)
		self.mapBox:setVisible(not contract.finshed)
		self.collectRewardsBox:setVisible(contract.finshed)
		if contract.active then
			self.progressText:setText(string.format("%.0f%%", mission.completion * 100))
			self.extraProgressText:setText(mission:getExtraProgressText())
			self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.ACTIVE)
			self:updateProgressBar(mission.completion)
		elseif contract.possible then
			local hasLeasing = mission:hasLeasableVehicles()
			self.useOwnEquipementText:setVisible(hasLeasing)
			self.equipmentTitle:setVisible(hasLeasing)
			if hasLeasing then
				local vehicleCosts = mission:getVehicleCosts()
				local leaseCost = g_i18n:formatMoney(vehicleCosts, 0, true, true)
				local vehicleText = string.format(g_i18n:getText("contract_desc_useOwnEquipment"), leaseCost)
				self.useOwnEquipementText:setText(vehicleText)
				local totalWidth = 0
				local vehicles = mission.vehiclesToLoad
				for i, v in ipairs(vehicles) do
					local storeItem = g_storeManager:getItemByXMLFilename(v.filename)
					if storeItem == nil then
						Logging.error("Mission uses non-existent vehicle at '%s'", v.filename)
						break
					end
					local imageFilename = storeItem.imageFilename
					if v.configurations ~= nil and storeItem.configurations ~= nil then
						for configName, _ in pairs(storeItem.configurations) do
							local configId = v.configurations[configName]
							local config = storeItem.configurations[configName][configId]
							if config == nil or config.vehicleIcon == nil then
								continue
							end
							if config.vehicleIcon ~= "" then
								imageFilename = config.vehicleIcon
								break
							end
						end
					end
					local element = self.vehicleTemplate:clone(self.vehiclesBox)
					element:setImageFilename(imageFilename)
					element:setImageColor(nil, nil, nil, nil, 1)
					totalWidth = totalWidth + element.absSize[1] + element.margin[1] + element.margin[3]
					table.insert(self.vehicleElements, element)
				end
				self.vehiclesBox:setSize(totalWidth)
				self.vehiclesBox:invalidateLayout()
				if self.vehiclesBox.parent.absSize[1] < self.vehiclesBox.maxFlowSize then
					if self.vehiclesBox.pivot[1] ~= 0 then
						self.vehiclesBox:setPivot(0, 0.5)
					elseif self.vehiclesBox.maxFlowSize <= self.vehiclesBox.parent.absSize[1] then
						if self.vehiclesBox.pivot[1] ~= 0.5 then
							self.vehiclesBox:setPivot(0.5, 0.5)
						end
					end
				end
				self.vehiclesBox:setPosition(0)
			end
			self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.POSSIBLE, hasLeasing)
		elseif contract.finished then
			self.rewardTitle:setText(g_i18n:getText("contract_total"))
			self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.FINISHED)
			reward = mission:getTotalReward()
		end
		self.rewardText:setText(g_i18n:formatMoney(reward, 0, true, true))
		if 0 < reward then
			self.rewardText:applyProfile("fs25_contractsContractRewardValue")
		else
			self.rewardText:applyProfile("fs25_contractsContractRewardValueNegative")
		end
		if self.isOpen then
			local worldPosX, worldPosZ = mission:getWorldPosition()
			local hotspots = mission:getMapHotspots()
			local width = 650
			local height = 650
			if hotspots ~= nil and 0 < #hotspots then
				local minX = -math.huge
				local maxX = math.huge
				local minZ = -math.huge
				local maxZ = math.huge
				worldPosX = 0
				worldPosZ = 0
				for _, hotspot in ipairs(hotspots) do
					local x, z = hotspot:getWorldPosition()
					worldPosX = worldPosX + x
					worldPosZ = worldPosZ + z
					minX = math.max(x, minX)
					minZ = math.max(z, minZ)
					maxX = math.min(x, maxX)
					maxZ = math.min(z, maxZ)
				end
				worldPosX = worldPosX / #hotspots
				worldPosZ = worldPosZ / #hotspots
				local safeFrame = 100
				width = math.max(math.abs(maxX - minX) + 100, width)
				height = math.max(math.abs(maxZ - minZ) + 100, height)
			end
			if worldPosX ~= nil then
				local minX = worldPosX - width * 0.5
				local maxX = worldPosX + width * 0.5
				local minZ = worldPosZ - height * 0.5
				local maxZ = worldPosZ + height * 0.5
				self.ingameMap:fitToBoundary(minX, maxX, minZ, maxZ, 0.1)
				self.ingameMap:setCenterToWorldPosition(worldPosX, worldPosZ)
			end
		end
	else
		self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.EMPTY)
	end
end
function InGameMenuContractsFrame:updateFarmersBox(field, npc)
	self.farmerBox:setVisible(npc ~= nil)
	if npc ~= nil then
		self.farmerName:setText(npc.title)
		self.farmerImage:setImageFilename(npc.imageFilename)
	end
end
function InGameMenuContractsFrame:getSelectedContract()
	if self.sectionContracts[self.subCategorySelector:getState()] == nil then
		return nil
	end
	local section, index = self.contractsList:getSelectedPath()
	local sectionContracts = self.sectionContracts[self.subCategorySelector:getState()][section]
	if sectionContracts == nil then
		return nil
	else
		return sectionContracts.contracts[index]
	end
end
function InGameMenuContractsFrame:startContract(leaseVehicles)
	local contract = self:getSelectedContract()
	if contract == nil then
		return
	else
		local currentMission = g_currentMission
		local farmId = currentMission:getFarmId()
		if leaseVehicles and not contract.mission:isSpawnSpaceAvailable() then
			InfoDialog.show(g_i18n:getText("warning_noFreeMissionSpace"), nil, nil, DialogElement.TYPE_WARNING)
			return
		end
		g_messageCenter:subscribe(MissionStartEvent, self.onMissionStarted, self)
		g_client:getServerConnection():sendEvent(MissionStartEvent.new(contract.mission, farmId, leaseVehicles))
	end
end
function InGameMenuContractsFrame:onMissionStarted(startState, leaseVehicles)
	g_messageCenter:unsubscribe(MissionStartEvent, self)
	local changeSubcategoryFunc = function()
		self.subCategorySelector:setState(2, true)
		for section, sectionContract in pairs(self.sectionContracts[2]) do
			for index, contract in pairs(sectionContract.contracts) do
				if contract.mission == self.lastStartedMission then
					self.contractsList:setSelectedItem(section, index)
					self.needsListFocus = true
				end
			end
		end
	end
	if startState == MissionStartState.OK then
		if leaseVehicles then
			InfoDialog.show(g_i18n:getText("contract_vehiclesAtShop"), changeSubcategoryFunc, nil, DialogElement.TYPE_INFO)
		else
			InfoDialog.show(g_i18n:getText("contract_started"), changeSubcategoryFunc, nil, DialogElement.TYPE_INFO)
		end
	elseif startState == MissionStartState.LIMIT_REACHED then
		InfoDialog.show(g_i18n:getText("contract_limitedReached"), nil, nil, DialogElement.TYPE_WARNING)
	elseif startState == MissionStartState.ALREADY_STARTED then
		InfoDialog.show(g_i18n:getText("contract_alreadyStarted"), nil, nil, DialogElement.TYPE_WARNING)
	elseif startState == MissionStartState.NOT_AVAILABLE_ANYMORE then
		InfoDialog.show(g_i18n:getText("contract_notAvailableAnymore"), nil, nil, DialogElement.TYPE_WARNING)
	elseif startState == MissionStartState.NO_ACCESS then
		InfoDialog.show(g_i18n:getText("contract_noAccess"), nil, nil, DialogElement.TYPE_WARNING)
	elseif startState == MissionStartState.CANNOT_BE_STARTED_NOW then
		InfoDialog.show(g_i18n:getText("contract_cannotBeStartedNow"), nil, nil, DialogElement.TYPE_WARNING)
	elseif startState == MissionStartState.PENDING_MISSION then
		InfoDialog.show(g_i18n:getText("contract_pendingMissionStart"), nil, nil, DialogElement.TYPE_WARNING)
	elseif startState == MissionStartState.NO_PERMISSION then
		InfoDialog.show(g_i18n:getText("contract_noPermission"), nil, nil, DialogElement.TYPE_WARNING)
	else
		InfoDialog.show(g_i18n:getText("contract_startFailed"), nil, nil, DialogElement.TYPE_WARNING)
	end
end
function InGameMenuContractsFrame:sortList()
	local sortFunc = function(a, b)
		if a.active ~= b.active then
			return a.active
		end
		if a.finished ~= b.finished then
			return a.finished
		end
		local aMission = a.mission
		local bMission = b.mission
		if aMission.type ~= bMission.type then
			return aMission:getTitle() < bMission:getTitle()
		else
			local fieldB = bMission.field
			local fieldNameA = aMission.field and fieldA:getName() or aMission.farmlandId
			if fieldB then
				local fieldNameB = fieldB:getName() or aMission.farmlandId
			end
			if fieldNameA ~= nil and fieldNameB ~= nil then
				return fieldNameA < fieldNameB
			end
			return aMission.id < bMission.id
		end
	end
	table.sort(self.contracts, sortFunc)
	local selectorTexts = {}
	self.sectionContracts = {}
	for _, text in ipairs(InGameMenuContractsFrame.CONTRACT_STATE_TEXTS) do
		table.insert(self.sectionContracts, {})
		table.insert(selectorTexts, g_i18n:getText(text))
	end
	local lastTitle = {}
	for _, contract in ipairs(self.contracts) do
		local stateIndex = InGameMenuContractsFrame.CONTRACT_STATE.NEW
		if contract.active or contract.finished then
			stateIndex = InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE
		end
		local title = contract.mission:getTitle()
		if lastTitle[stateIndex] ~= title then
			table.insert(self.sectionContracts[stateIndex], { title = title, contracts = {} })
			lastTitle[stateIndex] = title
		end
		table.insert(self.sectionContracts[stateIndex][#self.sectionContracts[stateIndex]].contracts, contract)
	end
	if #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.NEW] == 0 then
		if 0 < #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE] then
			self.subCategorySelector:setState(InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE)
		elseif self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.FINISHED] ~= nil then
			if 0 < #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.FINISHED] then
				self.subCategorySelector:setState(InGameMenuContractsFrame.CONTRACT_STATE.FINISHED)
			end
		end
	end
	self.subCategorySelector:setTexts(selectorTexts)
end
function InGameMenuContractsFrame:updateMarqueeAnimation(dt)
	local contentWidth = self.vehiclesBox.absSize[1]
	local visibleWidth = self.vehiclesBox.parent.absSize[1]
	local scrollAmount = contentWidth - visibleWidth
	local scrollLengthFactor = contentWidth / visibleWidth
	if scrollLengthFactor <= 1 then
		return
	else
		local scrollDuration = 5000 * scrollLengthFactor
		self.marqueeTime = self.marqueeTime + dt
		if scrollDuration <= self.marqueeTime then
			self.marqueeTime = -scrollDuration
		end
		local alpha = MathUtil.smoothstep(0.2, 0.8, math.abs(self.marqueeTime) / scrollDuration)
		local offset = scrollAmount * alpha
		self.vehiclesBox:setPosition(-offset)
	end
end
function InGameMenuContractsFrame:getNumberOfSections(list)
	if list == self.detailsList then
		return 1
	else
		return #self.sectionContracts[self.subCategorySelector:getState()]
	end
end
function InGameMenuContractsFrame:getNumberOfItemsInSection(list, section)
	if list == self.detailsList then
		local mission = self.currentContract.mission
		local isFinished = mission:getIsFinished()
		if isFinished then
			return #mission:getFinishedDetails()
		else
			return #mission:getDetails()
		end
	end
	return #self.sectionContracts[self.subCategorySelector:getState()][section].contracts
end
function InGameMenuContractsFrame:getTitleForSectionHeader(list, section)
	if list == self.detailsList then
		return ""
	else
		return self.sectionContracts[self.subCategorySelector:getState()][section].title
	end
end
function InGameMenuContractsFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.detailsList then
		local mission = self.currentContract.mission
		local isFinished = mission:getIsFinished()
		local details = nil
		if isFinished then
			details = mission:getFinishedDetails()
		else
			details = mission:getDetails()
		end
		local detail = details[index]
		cell:getAttribute("title"):setText(detail.title)
		cell:getAttribute("info"):setText(detail.value)
	else
		local contract = self.sectionContracts[self.subCategorySelector:getState()][section].contracts[index]
		local mission = contract.mission
		if mission ~= nil then
			local npc = mission:getNPC()
			cell:getAttribute("icon"):setVisible(npc ~= nil)
			if npc ~= nil then
				cell:getAttribute("icon"):setImageFilename(npc.imageFilename)
			end
			cell:getAttribute("field"):setText(mission:getLocation())
			cell:getAttribute("reward"):setText(g_i18n:formatMoney(mission:getReward(), 0, true, true))
			cell:getAttribute("reward"):setVisible(not contract.finished and not contract.isPreparing)
			local timeText = nil
			local minutesLeft = mission:getMinutesLeft()
			if contract.isPreparing then
				timeText = g_i18n:getText("contract_preparing")
			elseif minutesLeft ~= nil then
				if not contract.finished and mission.finishState ~= MissionFinishState.SUCCESS then
					timeText = g_i18n:formatMinutes(minutesLeft)
				end
			end
			cell:getAttribute("time"):setVisible(timeText ~= nil)
			if timeText ~= nil then
				cell:getAttribute("time"):setText(timeText)
			end
			cell:getAttribute("indicatorFinished"):setVisible(contract.finished and mission.finishState == MissionFinishState.SUCCESS)
			cell:getAttribute("indicatorFailed"):setVisible(contract.finished and mission.finishState == MissionFinishState.FAILED)
			cell:getAttribute("indicatorTimedOut"):setVisible(contract.finished and mission.finishState == MissionFinishState.TIMED_OUT)
			cell:getAttribute("indicatorCanceled"):setVisible(contract.finished and mission.finishState == MissionFinishState.CANCELED)
		end
	end
end
function InGameMenuContractsFrame:onButtonAccept()
	self:startContract(false)
end
function InGameMenuContractsFrame:onButtonLease()
	self:startContract(true)
end
function InGameMenuContractsFrame:onButtonDismiss()
	local contract = self:getSelectedContract()
	if contract ~= nil then
		g_messageCenter:subscribe(MissionDismissEvent, self.onMissionDismissed, self)
		g_client:getServerConnection():sendEvent(MissionDismissEvent.new(contract.mission))
	end
end
function InGameMenuContractsFrame:onMissionDismissed(success)
	g_messageCenter:unsubscribe(MissionDismissEvent, self)
	if success then
		InfoDialog.show(g_i18n:getText("contract_missionDismissSuccess"), nil, nil, DialogElement.TYPE_INFO)
	else
		InfoDialog.show(g_i18n:getText("contract_missionDismissFailed"), nil, nil, DialogElement.TYPE_INFO)
	end
	self:updateList()
	self:updateDetailContents(self.contractsList:getSelectedPath())
end
function InGameMenuContractsFrame:onButtonCancel()
	YesNoDialog.show(self.onCancelDialog, self, g_i18n:getText("contract_end"))
end
function InGameMenuContractsFrame:onCancelDialog(yes)
	if yes then
		local contract = self:getSelectedContract()
		if contract ~= nil then
			g_messageCenter:subscribe(MissionCancelEvent, self.onMissionCanceled, self)
			g_client:getServerConnection():sendEvent(MissionCancelEvent.new(contract.mission))
		end
	end
end
function InGameMenuContractsFrame:onMissionCanceled(success)
	g_messageCenter:unsubscribe(MissionCancelEvent, self)
	if success then
		InfoDialog.show(g_i18n:getText("contract_missionCancelSuccess"), nil, nil, DialogElement.TYPE_INFO)
	else
		InfoDialog.show(g_i18n:getText("contract_missionCancelFailed"), nil, nil, DialogElement.TYPE_INFO)
	end
	self:updateList()
end
function InGameMenuContractsFrame:onListSelectionChanged(list, section, index)
	if g_gui.currentlyReloading or list == self.detailsList then
		return
	end
	local sectionContracts = self.sectionContracts[self.subCategorySelector:getState()][section]
	if sectionContracts ~= nil and sectionContracts.contracts[index] ~= nil then
		self:updateDetailContents(section, index)
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
		self.marqueeTime = 0
	end
end
function InGameMenuContractsFrame:onChangeSubCategory()
	self.contractsList:reloadData()
	self.contentContainer:setVisible(0 < self.contractsList:getItemCount())
	self:updateDetailContents(self.contractsList:getSelectedPath())
end
