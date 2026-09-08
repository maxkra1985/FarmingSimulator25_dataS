-- Local values: InGameMenuContractsFrame_mt
InGameMenuContractsFrame = {}
local InGameMenuContractsFrame_mt = Class(InGameMenuContractsFrame, TabbedMenuFrameElement)
InGameMenuContractsFrame.CONTRACT_STATE = {
	["NEW"] = 1,
	["ACTIVE"] = 2,
	["FINISHED"] = 3
}
InGameMenuContractsFrame.BUTTON_STATE = {
	["POSSIBLE"] = 0,
	["ACTIVE"] = 1,
	["FINISHED"] = 2,
	["EMPTY"] = 3
}
InGameMenuContractsFrame.CONTRACT_STATE_TEXTS = { "ui_contractsNew", "ui_contractsActive" }
function InGameMenuContractsFrame.register()
	local v2_ = InGameMenuContractsFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuContractsFrame.xml", "ContractsFrame", v2_, true)
end

-- Upvalues: InGameMenuContractsFrame_mt
-- Local values: self
function InGameMenuContractsFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuContractsFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuContractsFrame_mt)
	v5_.hasCustomMenuButtons = true
	v5_.vehicleElements = {}
	v5_.contracts = {}
	v5_.sectionContracts = {}
	v5_.updateTime = 0
	v5_.marqueeTime = 0
	return v5_
end

-- Local values: newGui
function InGameMenuContractsFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuContractsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

-- Local values: selectorTexts, index, text, dot
function InGameMenuContractsFrame:initialize()
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
	self.acceptButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("button_acceptContract"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonAccept()
		end
	}
	self.leaseButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_borrowItems"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonLease()
		end
	}
	self.dismissButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("button_contract_complete"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonDismiss()
		end
	}
	self.cancelButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_cancel"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonCancel()
		end
	}
	self.vehicleTemplate:unlinkElement()
	local v10_ = {}
	for v_u_11_, v12_ in ipairs(InGameMenuContractsFrame.CONTRACT_STATE_TEXTS) do
		self.subCategoryDotTemplate:clone(self.subCategoryDotBox).getIsSelected = function()
			-- upvalues: (copy) self, (copy) v_u_11_
			return self.subCategorySelector:getState() == v_u_11_
		end
		local v13_ = g_i18n
		table.insert(v10_, v13_:getText(v12_))
	end
	self.subCategoryDotBox:invalidateLayout()
	self.subCategorySelector:setTexts(v10_)
	g_messageCenter:subscribe(MessageType.MISSION_DELETED, self.onMissionDeleted, self)
end

function InGameMenuContractsFrame:delete()
	if self.vehicleTemplate ~= nil then
		self.vehicleTemplate:delete()
	end
	InGameMenuContractsFrame:superClass().delete(self)
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: mission, missionTime, section, index
function InGameMenuContractsFrame:update(dt)
	InGameMenuContractsFrame:superClass().update(self, dt)
	local v17_ = g_currentMission.time
	if self.updateTime < v17_ then
		self.updateTime = v17_ + 5000
		local v18_, v19_ = self.contractsList:getSelectedPath()
		self:updateDetailContents(v18_, v19_)
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

-- Local values: section, index
function InGameMenuContractsFrame:updateButtonsForPermissions()
	local v25_, v26_ = self.contractsList:getSelectedPath()
	self:updateDetailContents(v25_, v26_)
end

-- Local values: info, currentMission, hasPermission
function InGameMenuContractsFrame:setButtonsForState(state, canLease)
	local v30_ = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	local v31_ = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_CONTRACTS)
	if state == InGameMenuContractsFrame.BUTTON_STATE.FINISHED then
		local v32_ = self.dismissButtonInfo
		table.insert(v30_, v32_)
		self.dismissButtonInfo.disabled = not v31_
	elseif state == InGameMenuContractsFrame.BUTTON_STATE.ACTIVE then
		local v33_ = self.cancelButtonInfo
		table.insert(v30_, v33_)
		self.cancelButtonInfo.disabled = not v31_
	elseif self.contractsList:getItemCount() > 0 then
		local v34_ = self.acceptButtonInfo
		table.insert(v30_, v34_)
		self.acceptButtonInfo.disabled = not v31_
		if canLease then
			local v35_ = self.leaseButtonInfo
			table.insert(v30_, v35_)
			self.leaseButtonInfo.disabled = not v31_
		end
	end
	self.menuButtonInfo = v30_
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

-- Local values: currentMission, list, hasMissions, selectedContract, _, mission, sameFarm, status, isActive, isPreparing, isFinished, isPossible, contract
function InGameMenuContractsFrame:updateList()
	local v41_ = g_currentMission
	local v42_ = g_missionManager:getMissionsByFarmId(v41_:getFarmId())
	local v43_ = #v42_ ~= 0
	self.contractsListBox:setVisible(v43_)
	self.detailsList:setVisible(v43_)
	local v44_ = self:getSelectedContract()
	if v44_ == nil then
		self.storedSelected = nil
	else
		self.storedSelected = v44_.mission.generationTime
	end
	self.contracts = {}
	for _, v45_ in ipairs(v42_) do
		local v46_
		if g_localPlayer == nil then
			v46_ = false
		else
			v46_ = v45_.farmId == g_localPlayer:getFarmId()
		end
		local v47_ = v45_.status
		local v48_ = v47_ == MissionStatus.RUNNING and true or v47_ == MissionStatus.PREPARING
		local v49_ = v47_ == MissionStatus.PREPARING
		local v50_ = v47_ == MissionStatus.FINISHED and true or v47_ == MissionStatus.DISMISSED
		local v51_ = v47_ == MissionStatus.CREATED
		if not v45_:getWasStarted() or v46_ then
			local v52_ = self.contracts
			table.insert(v52_, {
				["mission"] = v45_,
				["active"] = v48_,
				["isPreparing"] = v49_,
				["finished"] = v50_,
				["possible"] = v51_
			})
		end
	end
	self:sortList()
	self.contractsList:reloadData()
	self.contentContainer:setVisible(self.contractsList:getItemCount() > 0)
end

-- Local values: fullWidth
function InGameMenuContractsFrame:updateProgressBar(value)
	local v55_ = self.progressBarBg.size[1] - self.progressBar.margin[1] * 2
	local v56_ = self.progressBar.startSize[1] * 2 / v55_
	local v57_ = math.max(value, v56_)
	self.progressBar:setSize(v55_ * math.min(v57_, 1), nil)
end

-- Local values: mission, hotspots, _, hotspot
function InGameMenuContractsFrame:onDrawPostIngameMapHotspots()
	if self.currentContract ~= nil then
		local v59_ = self.currentContract.mission:getMapHotspots()
		if v59_ ~= nil then
			for _, v60_ in ipairs(v59_) do
				self.ingameMap:drawHotspot(v60_, false)
			end
		end
	end
end

-- Local values: contract, sectionContracts, mission, hotspots, _, hotspot, _, elem, mission, reward, hasLeasing, vehicleCosts, leaseCost, vehicleText, totalWidth, vehicles, i, v, storeItem, imageFilename, configName, _, configId, config, element, worldPosX, worldPosZ, hotspots, width, height, minX, maxX, minZ, maxZ, _, hotspot, x, z, safeFrame, minX, maxX, minZ, maxZ
function InGameMenuContractsFrame:updateDetailContents(section, index)
	local v64_ = self.sectionContracts[self.subCategorySelector:getState()][section]
	local v65_
	if v64_ == nil then
		v65_ = nil
	else
		v65_ = v64_.contracts[index]
		self.currentContract = v65_
		local v66_ = v65_.mission:getMapHotspots()
		if v66_ ~= nil then
			for _, v67_ in ipairs(v66_) do
				v67_:postUpdate(9999)
			end
		end
		self.detailsList:reloadData()
	end
	for _, v68_ in pairs(self.vehicleElements) do
		v68_:delete()
	end
	self.vehicleElements = {}
	self.vehiclesBox:invalidateLayout()
	if v65_ == nil then
		self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.EMPTY)
	else
		local v69_ = v65_.mission
		self:updateFarmersBox(v69_.field, v69_:getNPC())
		local v70_ = v69_:getReward()
		self.titleText:setText(v69_:getTitle())
		self.contractDescriptionText:setText(v69_:getDescription())
		self.rewardTitle:setText(g_i18n:getText("contract_reward"))
		self.equipmentBox:setVisible(v65_.possible)
		self.progressBox:setVisible(v65_.active)
		self.mapBox:setVisible(not v65_.finshed)
		self.collectRewardsBox:setVisible(v65_.finshed)
		if v65_.active then
			self.progressText:setText(string.format("%.0f%%", v69_.completion * 100))
			self.extraProgressText:setText(v69_:getExtraProgressText())
			self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.ACTIVE)
			self:updateProgressBar(v69_.completion)
		elseif v65_.possible then
			local v71_ = v69_:hasLeasableVehicles()
			self.useOwnEquipementText:setVisible(v71_)
			self.equipmentTitle:setVisible(v71_)
			if v71_ then
				local v72_ = v69_:getVehicleCosts()
				local v73_ = g_i18n:formatMoney(v72_, 0, true, true)
				local v74_ = string.format(g_i18n:getText("contract_desc_useOwnEquipment"), v73_)
				self.useOwnEquipementText:setText(v74_)
				local v75_ = v69_.vehiclesToLoad
				local v76_ = 0
				for _, v77_ in ipairs(v75_) do
					local v78_ = g_storeManager:getItemByXMLFilename(v77_.filename)
					if v78_ == nil then
						Logging.error("Mission uses non-existent vehicle at \'%s\'", v77_.filename)
					end
					local v79_ = v78_.imageFilename
					if v77_.configurations ~= nil and v78_.configurations ~= nil then
						for v80_, _ in pairs(v78_.configurations) do
							local v81_ = v77_.configurations[v80_]
							local v82_ = v78_.configurations[v80_][v81_]
							if v82_ ~= nil and (v82_.vehicleIcon ~= nil and v82_.vehicleIcon ~= "") then
								v79_ = v82_.vehicleIcon
								break
							end
						end
					end
					local v83_ = self.vehicleTemplate:clone(self.vehiclesBox)
					v83_:setImageFilename(v79_)
					v83_:setImageColor(nil, nil, nil, nil, 1)
					v76_ = v76_ + v83_.absSize[1] + v83_.margin[1] + v83_.margin[3]
					local v84_ = self.vehicleElements
					table.insert(v84_, v83_)
				end
				self.vehiclesBox:setSize(v76_)
				self.vehiclesBox:invalidateLayout()
				if self.vehiclesBox.maxFlowSize > self.vehiclesBox.parent.absSize[1] and self.vehiclesBox.pivot[1] ~= 0 then
					self.vehiclesBox:setPivot(0, 0.5)
				elseif self.vehiclesBox.maxFlowSize <= self.vehiclesBox.parent.absSize[1] and self.vehiclesBox.pivot[1] ~= 0.5 then
					self.vehiclesBox:setPivot(0.5, 0.5)
				end
				self.vehiclesBox:setPosition(0)
			end
			self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.POSSIBLE, v71_)
		elseif v65_.finished then
			self.rewardTitle:setText(g_i18n:getText("contract_total"))
			self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.FINISHED)
			v70_ = v69_:getTotalReward()
		end
		self.rewardText:setText(g_i18n:formatMoney(v70_, 0, true, true))
		if v70_ > 0 then
			self.rewardText:applyProfile("fs25_contractsContractRewardValue")
		else
			self.rewardText:applyProfile("fs25_contractsContractRewardValueNegative")
		end
		if self.isOpen then
			local v85_, v86_ = v69_:getWorldPosition()
			local v87_ = v69_:getMapHotspots()
			local v88_ = 650
			local v89_ = 650
			if v87_ ~= nil and #v87_ > 0 then
				local v90_ = 0
				local v91_ = 0
				local v92_ = -math.huge
				local v93_ = -math.huge
				local v94_ = math.huge
				local v95_ = math.huge
				for _, v96_ in ipairs(v87_) do
					local v97_, v98_ = v96_:getWorldPosition()
					v90_ = v90_ + v97_
					v91_ = v91_ + v98_
					v92_ = math.max(v97_, v92_)
					v93_ = math.max(v98_, v93_)
					v94_ = math.min(v97_, v94_)
					v95_ = math.min(v98_, v95_)
				end
				v85_ = v90_ / #v87_
				v86_ = v91_ / #v87_
				local v99_ = v94_ - v92_
				local v100_ = math.abs(v99_) + 100
				v88_ = math.max(v100_, v88_)
				local v101_ = v95_ - v93_
				local v102_ = math.abs(v101_) + 100
				v89_ = math.max(v102_, v89_)
			end
			if v85_ ~= nil then
				local v103_ = v85_ - v88_ * 0.5
				local v104_ = v85_ + v88_ * 0.5
				local v105_ = v86_ - v89_ * 0.5
				local v106_ = v86_ + v89_ * 0.5
				self.ingameMap:fitToBoundary(v103_, v104_, v105_, v106_, 0.1)
				self.ingameMap:setCenterToWorldPosition(v85_, v86_)
				return
			end
		end
	end
end

function InGameMenuContractsFrame:updateFarmersBox(field, npc)
	self.farmerBox:setVisible(npc ~= nil)
	if npc ~= nil then
		self.farmerName:setText(npc.title)
		self.farmerImage:setImageFilename(npc.imageFilename)
	end
end

-- Local values: section, index, sectionContracts
function InGameMenuContractsFrame:getSelectedContract()
	if self.sectionContracts[self.subCategorySelector:getState()] == nil then
		return nil
	else
		local v110_, v111_ = self.contractsList:getSelectedPath()
		local v112_ = self.sectionContracts[self.subCategorySelector:getState()][v110_]
		if v112_ == nil then
			return nil
		else
			return v112_.contracts[v111_]
		end
	end
end

-- Local values: contract, currentMission, farmId
function InGameMenuContractsFrame:startContract(leaseVehicles)
	local v115_ = self:getSelectedContract()
	if v115_ == nil then
		return
	else
		local v116_ = g_currentMission:getFarmId()
		if leaseVehicles and not v115_.mission:isSpawnSpaceAvailable() then
			InfoDialog.show(g_i18n:getText("warning_noFreeMissionSpace"), nil, nil, DialogElement.TYPE_WARNING)
		else
			g_messageCenter:subscribe(MissionStartEvent, self.onMissionStarted, self)
			g_client:getServerConnection():sendEvent(MissionStartEvent.new(v115_.mission, v116_, leaseVehicles))
		end
	end
end

-- Local values: changeSubcategoryFunc
function InGameMenuContractsFrame:onMissionStarted(startState, leaseVehicles)
	g_messageCenter:unsubscribe(MissionStartEvent, self)
	local function v124_()
		-- upvalues: (copy) self
		self.subCategorySelector:setState(2, true)
		for v120_, v121_ in pairs(self.sectionContracts[2]) do
			for v122_, v123_ in pairs(v121_.contracts) do
				if v123_.mission == self.lastStartedMission then
					self.contractsList:setSelectedItem(v120_, v122_)
					self.needsListFocus = true
				end
			end
		end
	end
	if startState == MissionStartState.OK then
		if leaseVehicles then
			InfoDialog.show(g_i18n:getText("contract_vehiclesAtShop"), v124_, nil, DialogElement.TYPE_INFO)
		else
			InfoDialog.show(g_i18n:getText("contract_started"), v124_, nil, DialogElement.TYPE_INFO)
		end
	elseif startState == MissionStartState.LIMIT_REACHED then
		InfoDialog.show(g_i18n:getText("contract_limitedReached"), nil, nil, DialogElement.TYPE_WARNING)
		return
	elseif startState == MissionStartState.ALREADY_STARTED then
		InfoDialog.show(g_i18n:getText("contract_alreadyStarted"), nil, nil, DialogElement.TYPE_WARNING)
		return
	elseif startState == MissionStartState.NOT_AVAILABLE_ANYMORE then
		InfoDialog.show(g_i18n:getText("contract_notAvailableAnymore"), nil, nil, DialogElement.TYPE_WARNING)
		return
	elseif startState == MissionStartState.NO_ACCESS then
		InfoDialog.show(g_i18n:getText("contract_noAccess"), nil, nil, DialogElement.TYPE_WARNING)
		return
	elseif startState == MissionStartState.CANNOT_BE_STARTED_NOW then
		InfoDialog.show(g_i18n:getText("contract_cannotBeStartedNow"), nil, nil, DialogElement.TYPE_WARNING)
		return
	elseif startState == MissionStartState.PENDING_MISSION then
		InfoDialog.show(g_i18n:getText("contract_pendingMissionStart"), nil, nil, DialogElement.TYPE_WARNING)
		return
	elseif startState == MissionStartState.NO_PERMISSION then
		InfoDialog.show(g_i18n:getText("contract_noPermission"), nil, nil, DialogElement.TYPE_WARNING)
	else
		InfoDialog.show(g_i18n:getText("contract_startFailed"), nil, nil, DialogElement.TYPE_WARNING)
	end
end

-- Local values: sortFunc, selectorTexts, _, text, lastTitle, _, contract, stateIndex, title
function InGameMenuContractsFrame:sortList()
	table.sort(self.contracts, function(p126_, p127_)
		if p126_.active == p127_.active then
			if p126_.finished == p127_.finished then
				local v128_ = p126_.mission
				local v129_ = p127_.mission
				if v128_.type == v129_.type then
					local v130_ = v128_.field
					local v131_ = v129_.field
					local v132_ = v130_ and v130_:getName() or v128_.farmlandId
					local v133_ = v131_ and v131_:getName() or v128_.farmlandId
					if v132_ == nil or v133_ == nil then
						return v128_.id < v129_.id
					else
						return v132_ < v133_
					end
				else
					return v128_:getTitle() < v129_:getTitle()
				end
			else
				return p126_.finished
			end
		else
			return p126_.active
		end
	end)
	self.sectionContracts = {}
	local v134_ = {}
	for _, v135_ in ipairs(InGameMenuContractsFrame.CONTRACT_STATE_TEXTS) do
		local v136_ = self.sectionContracts
		table.insert(v136_, {})
		local v137_ = g_i18n
		table.insert(v134_, v137_:getText(v135_))
	end
	local v138_ = {}
	for _, v139_ in ipairs(self.contracts) do
		local v140_ = InGameMenuContractsFrame.CONTRACT_STATE.NEW
		if v139_.active or v139_.finished then
			v140_ = InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE
		end
		local v141_ = v139_.mission:getTitle()
		if v138_[v140_] ~= v141_ then
			local v142_ = self.sectionContracts[v140_]
			table.insert(v142_, {
				["title"] = v141_,
				["contracts"] = {}
			})
			v138_[v140_] = v141_
		end
		local v143_ = self.sectionContracts[v140_][#self.sectionContracts[v140_]].contracts
		table.insert(v143_, v139_)
	end
	if #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.NEW] == 0 then
		if #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE] > 0 then
			self.subCategorySelector:setState(InGameMenuContractsFrame.CONTRACT_STATE.ACTIVE)
		elseif self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.FINISHED] ~= nil and #self.sectionContracts[InGameMenuContractsFrame.CONTRACT_STATE.FINISHED] > 0 then
			self.subCategorySelector:setState(InGameMenuContractsFrame.CONTRACT_STATE.FINISHED)
		end
	end
	self.subCategorySelector:setTexts(v134_)
end

-- Local values: contentWidth, visibleWidth, scrollAmount, scrollLengthFactor, scrollDuration, alpha, offset
function InGameMenuContractsFrame:updateMarqueeAnimation(dt)
	local v146_ = self.vehiclesBox.absSize[1]
	local v147_ = self.vehiclesBox.parent.absSize[1]
	local v148_ = v146_ - v147_
	local v149_ = v146_ / v147_
	if v149_ > 1 then
		local v150_ = 5000 * v149_
		self.marqueeTime = self.marqueeTime + dt
		if v150_ <= self.marqueeTime then
			self.marqueeTime = -v150_
		end
		local v151_ = MathUtil.smoothstep
		local v152_ = self.marqueeTime
		local v153_ = v148_ * v151_(0.2, 0.8, math.abs(v152_) / v150_)
		self.vehiclesBox:setPosition(-v153_)
	end
end

function InGameMenuContractsFrame:getNumberOfSections(list)
	return list == self.detailsList and 1 or #self.sectionContracts[self.subCategorySelector:getState()]
end

-- Local values: mission, isFinished
function InGameMenuContractsFrame:getNumberOfItemsInSection(list, section)
	if list ~= self.detailsList then
		return #self.sectionContracts[self.subCategorySelector:getState()][section].contracts
	end
	local v159_ = self.currentContract.mission
	return v159_:getIsFinished() and #v159_:getFinishedDetails() or #v159_:getDetails()
end

function InGameMenuContractsFrame:getTitleForSectionHeader(list, section)
	return list == self.detailsList and "" or self.sectionContracts[self.subCategorySelector:getState()][section].title
end

-- Local values: mission, isFinished, details, detail, contract, mission, npc, timeText, minutesLeft
function InGameMenuContractsFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.detailsList then
		local v168_ = self.currentContract.mission
		local v169_
		if v168_:getIsFinished() then
			v169_ = v168_:getFinishedDetails()
		else
			v169_ = v168_:getDetails()
		end
		local v170_ = v169_[index]
		cell:getAttribute("title"):setText(v170_.title)
		cell:getAttribute("info"):setText(v170_.value)
	else
		local v171_ = self.sectionContracts[self.subCategorySelector:getState()][section].contracts[index]
		local v172_ = v171_.mission
		if v172_ ~= nil then
			local v173_ = v172_:getNPC()
			cell:getAttribute("icon"):setVisible(v173_ ~= nil)
			if v173_ ~= nil then
				cell:getAttribute("icon"):setImageFilename(v173_.imageFilename)
			end
			cell:getAttribute("field"):setText(v172_:getLocation())
			cell:getAttribute("reward"):setText(g_i18n:formatMoney(v172_:getReward(), 0, true, true))
			local v174_ = cell:getAttribute("reward")
			local v175_ = not v171_.finished
			if v175_ then
				v175_ = not v171_.isPreparing
			end
			v174_:setVisible(v175_)
			local v176_ = nil
			local v177_ = v172_:getMinutesLeft()
			if v171_.isPreparing then
				v176_ = g_i18n:getText("contract_preparing")
			elseif v177_ ~= nil and (not v171_.finished and v172_.finishState ~= MissionFinishState.SUCCESS) then
				v176_ = g_i18n:formatMinutes(v177_)
			end
			cell:getAttribute("time"):setVisible(v176_ ~= nil)
			if v176_ ~= nil then
				cell:getAttribute("time"):setText(v176_)
			end
			local v178_ = cell:getAttribute("indicatorFinished")
			local v179_ = v171_.finished
			if v179_ then
				v179_ = v172_.finishState == MissionFinishState.SUCCESS
			end
			v178_:setVisible(v179_)
			local v180_ = cell:getAttribute("indicatorFailed")
			local v181_ = v171_.finished
			if v181_ then
				v181_ = v172_.finishState == MissionFinishState.FAILED
			end
			v180_:setVisible(v181_)
			local v182_ = cell:getAttribute("indicatorTimedOut")
			local v183_ = v171_.finished
			if v183_ then
				v183_ = v172_.finishState == MissionFinishState.TIMED_OUT
			end
			v182_:setVisible(v183_)
			local v184_ = cell:getAttribute("indicatorCanceled")
			local v185_ = v171_.finished
			if v185_ then
				v185_ = v172_.finishState == MissionFinishState.CANCELED
			end
			v184_:setVisible(v185_)
		end
	end
end

function InGameMenuContractsFrame:onButtonAccept()
	self:startContract(false)
end

function InGameMenuContractsFrame:onButtonLease()
	self:startContract(true)
end

-- Local values: contract
function InGameMenuContractsFrame:onButtonDismiss()
	local v189_ = self:getSelectedContract()
	if v189_ ~= nil then
		g_messageCenter:subscribe(MissionDismissEvent, self.onMissionDismissed, self)
		g_client:getServerConnection():sendEvent(MissionDismissEvent.new(v189_.mission))
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

-- Local values: contract
function InGameMenuContractsFrame:onCancelDialog(yes)
	if yes then
		local v195_ = self:getSelectedContract()
		if v195_ ~= nil then
			g_messageCenter:subscribe(MissionCancelEvent, self.onMissionCanceled, self)
			g_client:getServerConnection():sendEvent(MissionCancelEvent.new(v195_.mission))
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

-- Local values: sectionContracts
function InGameMenuContractsFrame:onListSelectionChanged(list, section, index)
	if not g_gui.currentlyReloading and list ~= self.detailsList then
		local v202_ = self.sectionContracts[self.subCategorySelector:getState()][section]
		if v202_ ~= nil and v202_.contracts[index] ~= nil then
			self:updateDetailContents(section, index)
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
			self.marqueeTime = 0
		end
	end
end

function InGameMenuContractsFrame:onChangeSubCategory()
	self.contractsList:reloadData()
	self.contentContainer:setVisible(self.contractsList:getItemCount() > 0)
	self:updateDetailContents(self.contractsList:getSelectedPath())
end
