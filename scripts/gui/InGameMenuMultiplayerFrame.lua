-- Local values: InGameMenuMultiplayerFrame_mt
InGameMenuMultiplayerFrame = {}
local InGameMenuMultiplayerFrame_mt = Class(InGameMenuMultiplayerFrame, TabbedMenuFrameElement)
InGameMenuMultiplayerFrame.ELEMENT_NAME = {
	["ROW_PLAYER_NAME"] = "playerName",
	["ROW_FARM_NAME"] = "farmName",
	["ROW_FARM_COLOR"] = "farmColor"
}
InGameMenuMultiplayerFrame.TRANSFER_AMOUNT = {
	["SMALL"] = 5000,
	["MEDIUM"] = 50000,
	["LARGE"] = 250000
}
InGameMenuMultiplayerFrame.ELEMENT_NAME = {
	["ROW_PLAYER_NAME"] = "playerName",
	["ROW_FARM_NAME"] = "farmName",
	["ROW_FARM_COLOR"] = "farmColor"
}
InGameMenuMultiplayerFrame.TRANSFER_AMOUNT = {
	["SMALL"] = 5000,
	["MEDIUM"] = 50000,
	["LARGE"] = 250000
}
InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS = 1
InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS = 2
function InGameMenuMultiplayerFrame.register()
	local v2_ = InGameMenuMultiplayerFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuMultiplayerFrame.xml", "MultiplayerFrame", v2_, true)
end

-- Upvalues: InGameMenuMultiplayerFrame_mt
-- Local values: self
function InGameMenuMultiplayerFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuMultiplayerFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMultiplayerFrame_mt)
	v5_.currentUser = User.new()
	v5_.playerFarm = nil
	v5_.player = nil
	v5_.playerFarm = nil
	v5_.hasAskedForPassword = false
	v5_.timeSinceLastMoneyUpdate = 0
	v5_.elementFarmIdMap = {}
	v5_.farmIdBalanceMap = {}
	v5_.farmIdPlayerCountMap = {}
	v5_.newFarmListIndex = 0
	v5_.hasCustomMenuButtons = true
	v5_.menuButtonInfo = {}
	v5_.selectedUserId = nil
	v5_.selectedUserFarm = nil
	v5_.isNavigatingUsers = false
	v5_.users = {}
	v5_.listRowUser = {}
	v5_.permissionCheckboxes = {}
	v5_.checkboxPermissions = {}
	v5_.timeSinceLastRefresh = 0
	return v5_
end

-- Local values: newGui
function InGameMenuMultiplayerFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuMultiplayerFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

-- Local values: subCategories, index, button, k, v
function InGameMenuMultiplayerFrame:initialize()
	InGameMenuMultiplayerFrame:superClass().initialize(self)
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
	self.joinMenuButton = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_JOIN_FARM),
		["callback"] = function()
			-- upvalues: (copy) self
			self:joinFarm(self.selectedFarmId)
		end
	}
	self.leaveMenuButton = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM),
		["callback"] = function()
			-- upvalues: (copy) self
			self:leaveFarm()
		end
	}
	self.editMenuButton = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_EDIT_FARM),
		["callback"] = function()
			-- upvalues: (copy) self
			self:editFarm(self.selectedFarmId)
		end
	}
	self.createMenuButton = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_CREATE_FARM),
		["callback"] = function()
			-- upvalues: (copy) self
			self:createFarm()
		end
	}
	self.deleteMenuButton = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_DELETE_FARM),
		["callback"] = function()
			-- upvalues: (copy) self
			self:deleteFarm(self.selectedFarmId)
		end
	}
	self.playerNameTemplate:unlinkElement()
	local v10_ = {}
	for v_u_11_, v12_ in pairs(self.subCategoryTabs) do
		v12_:getDescendantByName("background").getIsSelected = function()
			-- upvalues: (copy) v_u_11_, (copy) self
			return v_u_11_ == self.subCategoryPaging:getState()
		end
		function v12_.getIsSelected()
			-- upvalues: (copy) v_u_11_, (copy) self
			return v_u_11_ == self.subCategoryPaging:getState()
		end
		local v13_ = tostring(v_u_11_)
		table.insert(v10_, v13_)
	end
	self.subCategoryPaging:setTexts(v10_)
	self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
	self:setupUserListFocusContext()
	self.unblockButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_1,
		["text"] = g_i18n:getText("button_blocklist"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonUnBan()
		end
	}
	self.unblockRemoteButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_blocklist"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonUnBanRemote()
		end
	}
	self.adminButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("button_adminLogin"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonAdminLogin()
		end
	}
	self.inviteFriendsInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_2,
		["text"] = g_i18n:getText("ui_inviteScreen"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonInviteFriends()
		end
	}
	self.permissionCheckboxes = {
		[Farm.PERMISSION.BUY_VEHICLE] = self.buyVehiclePermissionCheckbox,
		[Farm.PERMISSION.SELL_VEHICLE] = self.sellVehiclePermissionCheckbox,
		[Farm.PERMISSION.RESET_VEHICLE] = self.resetVehiclePermissionCheckbox,
		[Farm.PERMISSION.BUY_PLACEABLE] = self.buyPlaceablePermissionCheckbox,
		[Farm.PERMISSION.SELL_PLACEABLE] = self.sellPlaceablePermissionCheckbox,
		[Farm.PERMISSION.HIRE_ASSISTANT] = self.hireAssistantPermissionCheckbox,
		[Farm.PERMISSION.MANAGE_CONTRACTS] = self.manageMissionsPermissionCheckbox,
		[Farm.PERMISSION.MANAGE_PRODUCTIONS] = self.manageProductionsPermissionCheckbox,
		[Farm.PERMISSION.TRADE_ANIMALS] = self.tradeAnimalsPermissionCheckbox,
		[Farm.PERMISSION.CUT_TREES] = self.cutTreesPermissionCheckbox,
		[Farm.PERMISSION.CREATE_FIELDS] = self.createFieldsPermissionCheckbox,
		[Farm.PERMISSION.LANDSCAPING] = self.landscapingPermissionCheckbox
	}
	self.reportReasons = {
		[ReportUserReason.PLAYER_NAME + 1] = g_i18n:getText("ui_reportPlayer_reason_name"),
		[ReportUserReason.VOICE_CHAT + 1] = g_i18n:getText("ui_reportPlayer_reason_voice"),
		[ReportUserReason.TEXT_CHAT + 1] = g_i18n:getText("ui_reportPlayer_reason_text"),
		[ReportUserReason.BEHAVIOR + 1] = g_i18n:getText("ui_reportPlayer_reason_behavior"),
		[ReportUserReason.CHEATING + 1] = g_i18n:getText("ui_reportPlayer_reason_cheating")
	}
	self.checkboxPermissions = {}
	for v14_, v15_ in pairs(self.permissionCheckboxes) do
		self.checkboxPermissions[v15_] = v14_
	end
end

function InGameMenuMultiplayerFrame:delete()
	self.playerNameTemplate:delete()
	InGameMenuMultiplayerFrame:superClass().delete(self)
end

-- Local values: listIndex
function InGameMenuMultiplayerFrame:onFrameOpen()
	InGameMenuMultiplayerFrame:superClass().onFrameOpen(self)
	g_messageCenter:subscribe(MessageType.FARM_CREATED, self.onFarmCreated, self)
	g_messageCenter:subscribe(MessageType.FARM_SETTINGS_CHANGED, self.onFarmsChanged, self)
	g_messageCenter:subscribe(MessageType.FARM_DELETED, self.onFarmsChanged, self)
	g_messageCenter:subscribe(MessageType.PLAYER_NICKNAME_CHANGED, self.onFarmsChanged, self)
	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onFarmMoneyChanged, self)
	g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	g_messageCenter:subscribe(PlayerSetFarmAnswerEvent, self.onPlayerSetFarmAnswer, self)
	g_messageCenter:subscribe(PlayerPermissionsEvent, self.onPermissionChanged, self)
	g_messageCenter:subscribe(GetAdminAnswerEvent, self.onAdminLoginSuccess, self)
	g_messageCenter:subscribe(ContractingStateEvent, self.onContractingStateChanged, self)
	g_messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
	g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
	self:setCurrentUserId(g_currentMission.playerUserId)
	self.subCategoryPaging:setState(1, true)
	self.selectedFarmId = nil
	if self.farmList:getItemCount() > 0 then
		local v18_ = self.playerFarm == nil and 1 or self:getListFarmIndex(self.playerFarm.farmId)
		self.farmList:setSelectedIndex(v18_, true)
		FocusManager:setFocus(self.farmList)
	else
		self.farmList:setDisabled(true)
		FocusManager:setFocus(self.subCategoryPaging)
	end
end

function InGameMenuMultiplayerFrame:onFrameClose()
	self.farms = {}
	g_messageCenter:unsubscribeAll(self)
	InGameMenuMultiplayerFrame:superClass().onFrameClose(self)
end

function InGameMenuMultiplayerFrame:reset()
	InGameMenuMultiplayerFrame:superClass().reset(self)
	self.currentUser = User.new()
	self.users = {}
	self.player = nil
	self.playerFarm = nil
	self.hasAskedForPassword = false
	self.elementFarmIdMap = {}
	self.farmIdBalanceMap = {}
	self.farmIdPlayerCountMap = {}
	self.newFarmListIndex = 0
end

function InGameMenuMultiplayerFrame:setupUserListFocusContext()
	function self.userList.onFocusEnter()
		-- upvalues: (copy) self
		self.isNavigatingUsers = true
		self:updateMenuButtons()
	end
	function self.userList.onFocusLeave()
		-- upvalues: (copy) self
		self.isNavigatingUsers = false
		self:updateMenuButtons()
	end
end

function InGameMenuMultiplayerFrame:setCurrentUserId(currentUserId)
	self.currentUserId = currentUserId
	self.currentUser = g_currentMission.userManager:getUserByUserId(currentUserId) or self.currentUser
	self:updateMenuButtons()
end

-- Local values: sortedUsers
function InGameMenuMultiplayerFrame:setUsers(users)
	self.users = self:getSortedUsers(users)
	self.shouldRebuildUserList = true
	self:updateMenuButtons()
end

-- Local values: sortedUsers, _, user, groupSortUsers
function InGameMenuMultiplayerFrame:getSortedUsers(users)
	local v28_ = {}
	for _, v29_ in pairs(users) do
		if not g_currentMission.connectedToDedicatedServer or v29_:getId() ~= g_currentMission:getServerUserId() then
			table.insert(v28_, v29_)
		end
	end
	table.sort(v28_, function(p30_, p31_)
		-- upvalues: (copy) self
		local v32_ = p30_:getId()
		local v33_ = p31_:getId()
		if v32_ == nil and v33_ == nil then
			return false
		else
			local v34_ = g_farmManager:getFarmByUserId(v32_)
			local v35_ = g_farmManager:getFarmByUserId(v33_)
			if v34_ == nil and v35_ == nil then
				if v32_ == nil then
					return false
				else
					return v33_ == nil and true or v32_ < v33_
				end
			else
				if v34_ == nil then
					return false
				end
				if v35_ == nil then
					return true
				end
				local v36_ = v34_.farmId
				local v37_ = v35_.farmId
				local v38_ = self.playerFarm ~= nil and v36_ == self.playerFarm.farmId and -math.huge or v36_
				local v39_ = self.playerFarm ~= nil and v37_ == self.playerFarm.farmId and -math.huge or v37_
				local v40_ = v38_ == FarmManager.SPECTATOR_FARM_ID and math.huge or v38_
				local v41_ = v39_ == FarmManager.SPECTATOR_FARM_ID and math.huge or v39_
				if v40_ ~= v41_ then
					return v40_ < v41_
				end
				local v42_ = p30_:getNickname()
				local v43_ = p31_:getNickname()
				return v42_ == v43_ and true or v42_ < v43_
			end
		end
	end)
	return v28_
end

function InGameMenuMultiplayerFrame:setPlayer(player)
	self.player = player
end

function InGameMenuMultiplayerFrame:setPlayerFarm(farm)
	self.playerFarm = farm
end

-- Local values: index, i, farm
function InGameMenuMultiplayerFrame:getListFarmIndex(farmId)
	local v50_ = 1
	if farmId ~= FarmManager.SPECTATOR_FARM_ID then
		for v51_, v52_ in ipairs(self.farms) do
			if v52_.farmId == farmId then
				return v51_
			end
		end
	end
	return v50_
end

-- Local values: farm
function InGameMenuMultiplayerFrame:setFarmBalance(farmId, balance)
	if balance == nil then
		balance = g_farmManager:getFarmById(farmId):getBalance()
	end
	if self.farmIdBalanceMap[farmId] ~= nil then
		self.farmIdBalanceMap[farmId]:setValue(balance)
	end
end

-- Local values: list, farms, spectatorFarm, _, farm
function InGameMenuMultiplayerFrame:getSortedFarmList()
	local v57_ = {}
	local v58_ = g_farmManager:getFarms()
	local v59_ = self.playerFarm
	table.insert(v57_, v59_)
	local v60_ = nil
	for _, v61_ in pairs(v58_) do
		if not v61_.isSpectator and (v61_ ~= self.playerFarm and v61_.showInFarmScreen) then
			table.insert(v57_, v61_)
		end
		if v61_.isSpectator then
			v60_ = v61_
		end
	end
	if v60_:getNumActivePlayers() > 0 and v60_ ~= self.playerFarm then
		table.insert(v57_, v60_)
	end
	return v57_
end

-- Local values: isFarmManager, hasHighPrivilege, isOwnFarmSelected, isSpectatorSelected, isSelfSelected, isSelectedUserFarmManager, canManageSelectedFarm, isOtherAdminSelected, selectionIsUser, user, isContracting, texts, volumeText, i, rawVolume, canChangePermissions, permissions, permissionKey, checkbox
function InGameMenuMultiplayerFrame:updateElements()
	local v63_ = self.playerFarm:isUserFarmManager(self.currentUserId)
	local v64_ = v63_ or self.currentUser:getIsMasterUser()
	local v65_ = self.selectedUserFarm == self.playerFarm
	local v66_ = self.selectedUserFarm.isSpectator
	local v67_ = self.selectedUserId == self.currentUserId
	local v68_
	if self.selectedUserId == nil then
		v68_ = false
	else
		v68_ = self.selectedUserFarm:isUserFarmManager(self.selectedUserId)
	end
	local v69_ = v63_ and v65_ and v65_ or self.currentUser:getIsMasterUser()
	local v70_ = self.selectedUserId ~= nil
	local v71_, v72_
	if v70_ then
		v71_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		if v71_ == nil or self.selectedUserId == self.currentUserId then
			v72_ = false
		else
			v72_ = v71_:getIsMasterUser()
		end
	else
		v71_ = nil
		v72_ = false
	end
	local v73_ = self.transferButton
	local v74_ = not (v70_ or v65_)
	if v74_ then
		if v63_ then
			v63_ = not v66_
		end
	else
		v63_ = v74_
	end
	v73_:setVisible(v63_)
	local v75_ = self.removeButton
	local v76_ = v71_ ~= nil and (v70_ and (v69_ and not (v67_ or v66_)))
	if v76_ then
		local v77_ = v71_:getIsMasterUser()
		if v77_ then
			v77_ = not self.currentUser:getIsMasterUser()
		end
		v76_ = not v77_
	end
	v75_:setVisible(v76_)
	local v78_ = self.promoteButton
	local v79_
	if v70_ then
		if v69_ then
			v79_ = not v66_
			if v79_ then
				v79_ = not v72_
			end
		else
			v79_ = v69_
		end
	else
		v79_ = v70_
	end
	v78_:setVisible(v79_)
	self.promoteButton:setText(g_i18n:getText(v68_ and "button_mp_dimiss" or "button_mp_promote"))
	local v80_ = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)
	local v81_ = self.contractorButton
	local v82_ = not v70_ and (v64_ and not (v65_ or v66_))
	if v82_ then
		v82_ = not self.playerFarm.isSpectator
	end
	v81_:setVisible(v82_)
	self.contractorButton:setText(g_i18n:getText(v80_ and "button_mp_ungrant" or "button_mp_grant"))
	local v83_ = self.kickButton
	local v84_ = v70_ and not v67_
	if v84_ then
		v84_ = self.currentUser:getIsMasterUser()
	end
	v83_:setVisible(v84_)
	local v85_ = self.blockFromServerButton
	local v86_ = v70_ and not v67_ and (self.currentUser:getIsMasterUser() and not g_currentMission:getIsServer())
	if v86_ then
		v86_ = self.selectedUserId ~= g_currentMission:getServerUserId()
	end
	v85_:setVisible(v86_)
	local v87_ = self.blockButton
	local v88_
	if v70_ then
		v88_ = not v67_
	else
		v88_ = v70_
	end
	v87_:setVisible(v88_)
	if v70_ then
		self.blockButton:setText(g_i18n:getText((v71_ == nil or not v71_:getIsBlocked()) and "button_block" or "button_unblock"))
	end
	local v89_ = self.muteButton
	local v90_ = v70_ and (v67_ and VoiceChatUtil.getHasRecordingDevice())
	if v90_ then
		v90_ = not VoiceChatUtil.getIsVoiceRestricted()
	end
	v89_:setVisible(v90_)
	if v70_ then
		self.muteButton:setText(g_i18n:getText((v71_ == nil or not v71_:getVoiceMuted()) and "button_mute" or "button_unmute"))
	end
	local v91_ = self.peerVolumeOption
	local v92_ = v70_ and not v67_
	if v92_ then
		v92_ = not VoiceChatUtil.getIsVoiceRestricted()
	end
	v91_:setVisible(v92_)
	if v70_ then
		local v93_ = { g_i18n:getText("button_mute") }
		local v94_ = g_i18n:getText("ui_volumeSound")
		for v95_ = 1, 10 do
			local v96_ = string.format
			local v97_ = v95_ * 10
			table.insert(v93_, v96_("%s: %d%%", v94_, v97_))
		end
		self.peerVolumeOption:setTexts(v93_)
		local v98_ = v71_ == nil and 0 or (v71_:getVoiceVolume() or 0)
		self.peerVolumeOption:setState(MathUtil.round(v98_ / 0.1 + 1, 0))
	end
	if v70_ and v71_ ~= nil then
		local v99_ = self.showProfileButton
		local v100_ = Platform.hasNativeProfiles
		if v100_ then
			v100_ = getPlatformIdsAreCompatible(v71_:getPlatformId(), getPlatformId())
		end
		v99_:setVisible(v100_)
		local v101_ = self.reportButton
		local v102_ = not v67_
		if v102_ then
			v102_ = not (Platform.hasNativeProfiles and getPlatformIdsAreCompatible(v71_:getPlatformId(), getPlatformId()))
		end
		v101_:setVisible(v102_)
	else
		self.showProfileButton:setVisible(false)
		self.reportButton:setVisible(false)
	end
	if v70_ and v71_ ~= nil then
		local v103_ = not v66_ and (v69_ and not v68_)
		if v103_ then
			v103_ = not v71_:getIsMasterUser()
		end
		local v104_ = self.selectedUserFarm:getUserPermissions(self.selectedUserId)
		for v105_, v106_ in pairs(self.permissionCheckboxes) do
			v106_:setIsChecked(v104_[v105_] or v71_:getIsMasterUser(), true)
			v106_:setDisabled(not v103_)
		end
		self.permissionsBox:setVisible(true)
		self.permissionsTitle:setVisible(true)
		if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS then
			self.multiplayerSlider:setVisible(true)
		end
	else
		self.permissionsBox:setVisible(false)
		self.permissionsTitle:setVisible(false)
		if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS then
			self.multiplayerSlider:setVisible(false)
		end
	end
	self.actionsBox:invalidateLayout()
	self.permissionsBox:invalidateLayout()
end

function InGameMenuMultiplayerFrame:updateMenuButtons()
	if not g_gui.currentlyReloading then
		self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
		if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS then
			if self.farmList:getIsFocused() then
				if self.selectedFarmId == nil then
					if self.currentUser:getIsMasterUser() then
						local v108_ = self.menuButtonInfo
						local v109_ = self.createMenuButton
						table.insert(v108_, v109_)
					elseif g_currentMission ~= nil and (g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser()) then
						local v110_ = self.menuButtonInfo
						local v111_ = self.adminButtonInfo
						table.insert(v110_, v111_)
					end
				else
					if self.selectedFarmId == self.playerFarm.farmId then
						local v112_ = self.menuButtonInfo
						local v113_ = self.leaveMenuButton
						table.insert(v112_, v113_)
					else
						local v114_ = self.menuButtonInfo
						local v115_ = self.joinMenuButton
						table.insert(v114_, v115_)
					end
					if self.currentUser:getIsMasterUser() then
						local v116_ = self.menuButtonInfo
						local v117_ = self.editMenuButton
						table.insert(v116_, v117_)
						local v118_ = self.menuButtonInfo
						local v119_ = self.deleteMenuButton
						table.insert(v118_, v119_)
					elseif g_currentMission ~= nil and (g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser()) then
						local v120_ = self.menuButtonInfo
						local v121_ = self.adminButtonInfo
						table.insert(v120_, v121_)
					end
				end
			end
		else
			if getNumOfBlockedUsers() > 0 then
				local v122_ = self.menuButtonInfo
				local v123_ = self.unblockButtonInfo
				table.insert(v122_, v123_)
			end
			if g_currentMission ~= nil then
				if self.currentUser:getIsMasterUser() then
					if g_currentMission.connectedToDedicatedServer then
						local v124_ = self.menuButtonInfo
						local v125_ = self.unblockRemoteButtonInfo
						table.insert(v124_, v125_)
					end
				elseif g_currentMission ~= nil and (g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser()) then
					local v126_ = self.menuButtonInfo
					local v127_ = self.adminButtonInfo
					table.insert(v126_, v127_)
				end
				if Platform.hasFriendInvitation and PlatformPrivilegeUtil.getCanInvitePlayer(g_currentMission) then
					local v128_ = self.menuButtonInfo
					local v129_ = self.inviteFriendsInfo
					table.insert(v128_, v129_)
				end
			end
		end
		self:setMenuButtonInfoDirty()
	end
end

function InGameMenuMultiplayerFrame:update(dt)
	InGameMenuMultiplayerFrame:superClass().update(self, dt)
	if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS then
		if self.timeSinceLastRefresh > 1000 then
			self.shouldRebuildUserList = true
		end
		self.timeSinceLastRefresh = self.timeSinceLastRefresh + dt
		if self.shouldRebuildUserList then
			self.shouldRebuildUserList = false
			self.timeSinceLastRefresh = 0
			self.sortedFarms = self:getSortedFarmList()
			self.isAutoReloading = true
			self.userList:reloadData()
			self.isAutoReloading = false
		end
	end
end

function InGameMenuMultiplayerFrame:updateDisplay()
	self.sortedFarms = self:getSortedFarmList()
	self.userList:reloadData()
	if self.selectedUserId ~= nil and self.selectedUserFarm ~= nil then
		if not self.isAutoReloading then
			self:updateElements()
		end
		self:updateMenuButtons()
	end
end

-- Local values: currentFarmId, text, title, callback, target
function InGameMenuMultiplayerFrame:joinFarm(farmId)
	local v135_ = self.playerFarm.farmId
	if self.playerFarm ~= nil and farmId ~= v135_ then
		if v135_ ~= FarmManager.SPECTATOR_FARM_ID then
			local v136_ = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.LEAVE_FARM_CONFIRM), self.playerFarm.name)
			local v137_ = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM)
			local v138_ = self.doJoinFarm
			YesNoDialog.show(v138_, self, v136_, v137_)
			return
		end
		self:doJoinFarm(true, farmId)
	end
end

-- Local values: farm
function InGameMenuMultiplayerFrame:doJoinFarm(yesNo)
	if yesNo then
		local v141_ = g_farmManager:getFarmById(self.selectedFarmId)
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, self.selectedFarmId, v141_.password))
	end
end

-- Local values: text, title, callback, target
function InGameMenuMultiplayerFrame:leaveFarm()
	local v143_ = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.LEAVE_FARM_CONFIRM), self.playerFarm.name)
	local v144_ = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM)
	local v145_ = self.doLeaveFarm
	YesNoDialog.show(v145_, self, v143_, v144_)
end

function InGameMenuMultiplayerFrame:doLeaveFarm(yesNo)
	if yesNo then
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, FarmManager.SPECTATOR_FARM_ID))
	end
end

-- Local values: farm, canDestroy, messageCannotDestroy, text, title, callback, target
function InGameMenuMultiplayerFrame:deleteFarm(farmId)
	local v150_, v151_ = g_farmManager:getFarmById(farmId):canBeDestroyed()
	if v150_ then
		local v152_ = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DELETE_FARM_CONFIRM)
		local v153_ = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_DELETE_FARM)
		local v154_ = self.onDeleteFarmYesNo
		YesNoDialog.show(v154_, self, v152_, v153_)
	else
		InfoDialog.show(g_i18n:getText(v151_))
	end
end

function InGameMenuMultiplayerFrame:editFarm(farmId)
	EditFarmDialog.show(farmId)
end

function InGameMenuMultiplayerFrame:createFarm()
	EditFarmDialog.show()
end

-- Local values: farms, _, farm
function InGameMenuMultiplayerFrame:reloadFarms()
	self.farms = {}
	local v157_ = g_farmManager:getFarms()
	for _, v158_ in ipairs(v157_) do
		if v158_.showInFarmScreen then
			local v159_ = self.farms
			table.insert(v159_, v158_)
		end
	end
	self.farmList:reloadData()
	if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS then
		if self.farmList:getItemCount() == 0 then
			self.farmList:setVisible(false)
			self.farmList:setDisabled(true)
			self.multiplayerSlider:setVisible(false)
		else
			self.farmList:setVisible(true)
			self.farmList:setDisabled(false)
			self.multiplayerSlider:setVisible(true)
		end
		local v160_ = self.noFarmsText
		local v161_
		if #self.farms == 0 then
			v161_ = not self.currentUser:getIsMasterUser()
		else
			v161_ = false
		end
		v160_:setVisible(v161_)
	end
end

-- Local values: joinedFarm
function InGameMenuMultiplayerFrame:onPlayerSetFarmAnswer(answerState, farmId, password)
	if answerState == PlayerSetFarmAnswerEvent.STATE.OK then
		g_farmManager:getFarmById(farmId).password = password
		self.hasAskedForPassword = false
		self.farmList:setSelectedIndex(self:getListFarmIndex(farmId))
	elseif answerState == PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED then
		if not self.hasAskedForPassword then
			self.hasAskedForPassword = true
			PasswordDialog.show(self.onFarmPasswordEntered, self, farmId, "", g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_JOIN_FARM))
			return
		end
		InfoDialog.show(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.WRONG_PASSWORD))
		self.hasAskedForPassword = false
	end
end

function InGameMenuMultiplayerFrame:onFarmPasswordEntered(password, hasConfirmed, farmId)
	if hasConfirmed then
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, farmId, password))
	else
		self.hasAskedForPassword = false
	end
end

function InGameMenuMultiplayerFrame:onPermissionChanged(userId)
	if userId == self.currentUserId then
		self:updateMenuButtons()
	end
	self:updateDisplay()
end

-- Local values: newIndex
function InGameMenuMultiplayerFrame:onFarmCreated(newFarmId)
	self:reloadFarms()
	if self.currentUser:getIsMasterUser() then
		local v174_ = self:getListFarmIndex(newFarmId)
		self.farmList:setSelectedIndex(v174_, true)
	end
end

function InGameMenuMultiplayerFrame:onFarmsChanged(farmId)
	self:reloadFarms()
	self:updateDisplay()
	self:onListSelectionChanged(self.userList, self.userList:getSelectedPath())
end

function InGameMenuMultiplayerFrame:onPlayerFarmChanged(player)
	self:reloadFarms()
	self:updateDisplay()
	self:updateMenuButtons()
end

function InGameMenuMultiplayerFrame:onFarmMoneyChanged(farmId, balance)
	if self.farmIdBalanceMap[farmId] ~= nil then
		self.farmIdBalanceMap[farmId]:setValue(balance)
	end
end

function InGameMenuMultiplayerFrame:onMasterUserAdded(user)
	self:reloadFarms()
	self:updateDisplay()
	self:updateMenuButtons()
end

-- Local values: farm
function InGameMenuMultiplayerFrame:onDoubleClickFarm(list, section, index)
	if index == self.newFarmListIndex then
		self:createFarm()
		return
	else
		local v183_ = self.farms[index]
		if v183_ == nil then
			Logging.warning("Farm does not exist anymore")
		else
			self.selectedFarmId = v183_.farmId
			self:joinFarm(self.selectedFarmId)
		end
	end
end

-- Local values: farm
function InGameMenuMultiplayerFrame:onDeleteFarmYesNo(yes)
	if yes and g_farmManager:getFarmById(self.selectedFarmId):canBeDestroyed() then
		g_client:getServerConnection():sendEvent(FarmDestroyEvent.new(self.selectedFarmId))
	end
end

function InGameMenuMultiplayerFrame:onClickUsers()
	self.subCategoryPaging:setState(InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS, true)
	FocusManager:setFocus(self.userList)
end

function InGameMenuMultiplayerFrame:onClickFarms()
	self.subCategoryPaging:setState(InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS, true)
	if self.farmList:getItemCount() > 0 then
		FocusManager:setFocus(self.farmList)
	else
		FocusManager:setFocus(self.subCategoryPaging)
	end
end

-- Local values: index, page
function InGameMenuMultiplayerFrame:updateSubCategoryPages(subCategoryIndex)
	for v190_, v191_ in pairs(self.subCategoryPages) do
		v191_:setVisible(v190_ == subCategoryIndex)
	end
	self:reloadFarms()
	self:updateDisplay()
	if subCategoryIndex == InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS then
		self.multiplayerSlider:applyProfile("fs25_sliderDocked")
		self.multiplayerSlider:setDataElement(self.farmList)
	else
		self.multiplayerSlider:applyProfile("fs25_multiplayerSliderDocked")
		self.multiplayerSlider:setDataElement(self.permissionsBox)
	end
	self:updateMenuButtons()
end

-- Local values: user, text, title, callback, target
function InGameMenuMultiplayerFrame:onButtonKick()
	if self.selectedUserId == nil or self.selectedUserId == g_currentMission:getServerUserId() then
		InfoDialog.show(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.INFO_CANNOT_KICK_SERVER))
	else
		local v193_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local v194_ = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_KICK_CONFIRM), v193_:getNickname())
		local v195_ = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_KICK_TITLE)
		local v196_ = self.onYesNoKick
		YesNoDialog.show(v196_, self, v194_, v195_)
	end
end

function InGameMenuMultiplayerFrame:onYesNoKick(yes)
	if yes then
		g_client:getServerConnection():sendEvent(KickBanEvent.new(true, self.selectedUserId))
	end
end

-- Local values: callbackFunc
function InGameMenuMultiplayerFrame:onButtonUnBan()
	UnBanDialog.show(function()
		-- upvalues: (copy) self
		self:updateElements()
		self:updateMenuButtons()
	end, self, true)
end

-- Local values: callbackFunc
function InGameMenuMultiplayerFrame:onButtonUnBanRemote()
	UnBanDialog.show(function()
		-- upvalues: (copy) self
		self:updateElements()
		self:updateMenuButtons()
	end, self, false)
end

-- Local values: user, nickname
function InGameMenuMultiplayerFrame:onButtonShowProfile()
	if self.selectedUserId ~= nil then
		local v202_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local v203_ = v202_:getPlatformUserId()
		if v203_ == "" then
			v203_ = v202_:getNickname()
		end
		showUserProfile(v203_)
	end
end

function InGameMenuMultiplayerFrame:onButtonInviteFriends()
	if Platform.hasFriendInvitation then
		if g_currentMission ~= nil then
			openMpFriendInvitation(#g_currentMission.userManager:getUsers(), g_currentMission.missionDynamicInfo.capacity)
			return
		end
		openMpFriendInvitation(1, 6)
	end
end

function InGameMenuMultiplayerFrame:onButtonAdminLogin()
	PasswordDialog.show(self.onAdminPassword, self, nil, "", g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.PROMPT_ADMIN_PASSWORD))
end

-- Local values: permission
function InGameMenuMultiplayerFrame:onClickPermission(state, binaryOption, isLeftButton)
	local v208_ = self.checkboxPermissions[binaryOption]
	self.selectedUserFarm:setUserPermission(self.selectedUserId, v208_, not isLeftButton)
end

function InGameMenuMultiplayerFrame:onClickTransferButton()
	TransferMoneyDialog.show(self.transferMoney, self, self.selectedUserFarm)
end

function InGameMenuMultiplayerFrame:transferMoney(amount)
	if amount > 0 then
		g_farmManager:transferMoney(self.selectedUserFarm, amount)
	end
end

-- Local values: user, text, title, callback, target
function InGameMenuMultiplayerFrame:onClickRemoveFromFarm()
	local v213_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	local v214_ = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_REMOVE_CONFIRM), v213_:getNickname())
	local v215_ = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_REMOVE_TITLE)
	local v216_ = self.onYesNoRemoveFromFarm
	YesNoDialog.show(v216_, self, v214_, v215_)
end

function InGameMenuMultiplayerFrame:onYesNoRemoveFromFarm(yes)
	if yes then
		g_farmManager:removeUserFromFarm(self.selectedUserId)
	end
end

-- Local values: user, text, title, callback, target
function InGameMenuMultiplayerFrame:onClickPromote()
	if self.selectedUserFarm:isUserFarmManager(self.selectedUserId) then
		self.selectedUserFarm:demoteUser(self.selectedUserId)
		self:updateElements()
	else
		local v220_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local v221_ = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_PROMOTE_CONFIRM), v220_:getNickname())
		local v222_ = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_PROMOTE_TITLE)
		local v223_ = self.onYesNoPromoteToFarmManager
		YesNoDialog.show(v223_, self, v221_, v222_)
	end
end

function InGameMenuMultiplayerFrame:onYesNoPromoteToFarmManager(yes)
	if yes then
		self.selectedUserFarm:promoteUser(self.selectedUserId)
		self:updateElements()
	end
end

-- Local values: isContracting, confirmTextTemplateSymbol, text, title, callback, target
function InGameMenuMultiplayerFrame:onClickContractor()
	local v227_
	if self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId) then
		v227_ = InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_DENY_CONTRACTOR_CONFIRM
	else
		v227_ = InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_GRANT_CONTRACTOR_CONFIRM
	end
	local v228_ = string.format(g_i18n:getText(v227_), self.selectedUserFarm.name)
	local v229_ = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_CONTRACTOR_STATE_TITLE)
	local v230_ = self.onYesNoToggleContractorState
	YesNoDialog.show(v230_, self, v228_, v229_)
end

-- Local values: isContracting
function InGameMenuMultiplayerFrame:onYesNoToggleContractorState(yes)
	if yes then
		local v233_ = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)
		self.selectedUserFarm:setIsContractingFor(self.playerFarm.farmId, not v233_, false)
	end
end

function InGameMenuMultiplayerFrame:onUserAdded()
	self:updateDisplay()
end

function InGameMenuMultiplayerFrame:onUserRemoved()
	self:reloadFarms()
	self:updateDisplay()
end

function InGameMenuMultiplayerFrame:onContractingStateChanged()
	self:updateDisplay()
end

function InGameMenuMultiplayerFrame:onAdminPassword(password, yes)
	if yes then
		g_client:getServerConnection():sendEvent(GetAdminEvent.new(password))
	end
end

function InGameMenuMultiplayerFrame:onAdminLoginSuccess()
	self:updateDisplay()
	if self.playerFarm ~= nil and self.playerFarm.farmId ~= FarmManager.SPECTATOR_FARM_ID then
		self.playerFarm:promoteUser(self.currentUserId)
	end
end

-- Local values: user, title, text, callback
function InGameMenuMultiplayerFrame:onButtonBlock()
	local v_u_241_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	if v_u_241_:getIsBlocked() then
		v_u_241_:unblock()
		self:updateDisplay()
		return
	elseif Platform.hasNativeProfiles and getPlatformIdsAreCompatible(v_u_241_:getPlatformId(), getPlatformId()) then
		v_u_241_:block()
	else
		local v242_ = g_i18n:getText("ui_doYouWantToBlockThisServer_title")
		local v243_ = string.format(g_i18n:getText("ui_blockPlayerConfirm"), v_u_241_:getNickname())
		YesNoDialog.show(function(p244_)
			-- upvalues: (copy) v_u_241_, (copy) self
			if p244_ then
				g_currentMission:banUser(v_u_241_)
				self:updateDisplay()
			end
		end, nil, v243_, v242_)
	end
end

-- Local values: user, text, title, callback
function InGameMenuMultiplayerFrame:onButtonBlockFromServer()
	local v246_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	local v247_ = string.format(g_i18n:getText("ui_banConfirm"), v246_:getNickname())
	local v248_ = g_i18n:getText("ui_banTitle")
	YesNoDialog.show(function(p249_)
		-- upvalues: (copy) self
		if p249_ then
			g_client:getServerConnection():sendEvent(KickBanEvent.new(false, self.selectedUserId))
		end
	end, nil, v247_, v248_)
end

-- Local values: user, title, text, options, callback
function InGameMenuMultiplayerFrame:onButtonReport()
	local v_u_251_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	local v252_ = g_i18n:getText("ui_reportPlayer_title")
	local v253_ = string.format(g_i18n:getText("ui_reportPlayer_confirm"), v_u_251_:getNickname())
	local v254_ = self.reportReasons
	OptionDialog.show(function(p255_)
		-- upvalues: (copy) v_u_251_
		if p255_ > 0 then
			v_u_251_:report(p255_ - 1)
		end
	end, v253_, v252_, v254_)
end

-- Local values: user
function InGameMenuMultiplayerFrame:onButtonMute()
	local v257_ = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	if v257_:getVoiceMuted() then
		v257_:setVoiceMuted(false)
	else
		v257_:setVoiceMuted(true)
	end
	self:updateDisplay()
end

-- Local values: volume, user
function InGameMenuMultiplayerFrame:onPeerVolumeChanged(state)
	local v260_ = (state - 1) * 0.1
	g_currentMission.userManager:getUserByUserId(self.selectedUserId):setVoiceVolume(v260_)
end

function InGameMenuMultiplayerFrame:getNumberOfSections(list)
	return list == self.userList and #self.sortedFarms or 1
end

function InGameMenuMultiplayerFrame:getCellTypeForItemInSection(list, section, index)
	return list == self.userList and (index == 1 and "farm" or "user") or nil
end

-- Local values: numFarms, farm
function InGameMenuMultiplayerFrame:getNumberOfItemsInSection(list, section)
	if list ~= self.farmList then
		return #self.sortedFarms[section]:getActiveUsers() + 1
	end
	local v269_ = #self.farms
	self.newFarmListIndex = nil
	if v269_ < FarmManager.MAX_NUM_FARMS and self.currentUser:getIsMasterUser() then
		v269_ = v269_ + 1
		self.newFarmListIndex = v269_
	end
	return v269_
end

-- Local values: farm, farmId, playerNameLayout, i, _, player, userId, user, nickname, item, farm, userInfos, userInfo, user, isFarmManager, noMic
function InGameMenuMultiplayerFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.farmList then
		local v275_ = self.farms[index]
		cell:getAttribute("existingFarm"):setVisible(v275_ ~= nil)
		cell:getAttribute("newFarm"):setVisible(v275_ == nil)
		if v275_ ~= nil then
			local v276_ = self.elementFarmIdMap[cell]
			if v276_ ~= nil then
				self.farmIdBalanceMap[v276_] = nil
			end
			cell:getAttribute("farmName"):setText(v275_.name)
			cell:getAttribute("farmIcon"):setImageSlice(nil, v275_:getIconSliceId())
			self.farmIdBalanceMap[v275_.farmId] = cell:getAttribute("farmBalance")
			cell:getAttribute("farmBalance"):setValue(v275_:getBalance())
			local v277_ = cell:getAttribute("playerNameLayout")
			v277_:updateAbsolutePosition()
			for _ = 1, #v277_.elements do
				v277_.elements[1]:delete()
			end
			for _, v278_ in ipairs(v275_:getActiveUsers()) do
				local v279_ = v278_.userId
				local v280_ = g_currentMission.userManager:getUserByUserId(v279_)
				if v280_ ~= nil then
					local v281_ = v280_:getNickname()
					self.playerNameTemplate:clone(v277_):setText(v281_)
				end
			end
			v277_:invalidateLayout()
			self.elementFarmIdMap[cell] = v275_.farmId
			return
		end
	else
		local v282_ = self.sortedFarms[section]
		if index == 1 then
			if v282_.farmId == FarmManager.SPECTATOR_FARM_ID then
				cell:getAttribute("title"):setText(g_i18n:getText("ui_noFarm"))
				cell:getAttribute("farmBalance"):setVisible(false)
			else
				cell:getAttribute("title"):setText(v282_.name)
				cell:getAttribute("farmBalance"):setVisible(true)
				cell:getAttribute("farmBalance"):setValue(v282_:getBalance())
			end
			cell:getAttribute("dot").color = v282_:getColor()
			return
		end
		local v283_ = v282_:getActiveUsers()[index - 1]
		local v284_ = g_currentMission.userManager:getUserByUserId(v283_.userId)
		if v284_ == nil then
			return
		end
		cell:getAttribute("playerName"):setText(v284_:getNickname())
		cell:getAttribute("platform"):setPlatformId(v284_:getPlatformId())
		if not g_currentMission.connectedToDedicatedServer or v284_:getId() ~= g_currentMission:getServerUserId() then
			local v285_ = v282_:isUserFarmManager(v284_:getId())
			local v286_ = voiceChatGetConnectionStatus(v284_:getUniqueUserId()) == VoiceChatConnectionStatus.UNAVAILABLE
			cell:getAttribute("noMicrophone"):setVisible(v286_)
			local v287_ = cell:getAttribute("muted")
			local v288_ = not v286_
			if v288_ then
				v288_ = v284_:getVoiceMuted()
			end
			v287_:setVisible(v288_)
			cell:getAttribute("farmManager"):setVisible(v285_)
			cell:getAttribute("admin"):setVisible(v284_:getIsMasterUser())
			cell:getAttribute("admin").parent:invalidateLayout()
		end
	end
end

-- Local values: farm, farm, user
function InGameMenuMultiplayerFrame:onListSelectionChanged(list, section, index)
	if list == self.farmList then
		self.selectedFarmId = nil
		if index ~= self.newFarmListIndex then
			local v293_ = self.farms[index]
			if v293_ ~= nil then
				self.selectedFarmId = v293_.farmId
			end
		end
	else
		local v294_ = self.sortedFarms[section]
		self.actionsTitle:setVisible(false)
		if index == 1 then
			self.selectedUserId = nil
			self.selectedUserFarm = v294_
		else
			local v295_ = v294_:getActiveUsers()[index - 1]
			if v295_ ~= nil then
				self.selectedUserId = v295_.userId
				self.selectedUserFarm = v294_
				if v295_.lastNickname == nil and v294_ ~= nil then
					v294_:updateLastNickname(v295_.userId)
				end
				self.actionsTitle:setVisible(true)
				self.actionsTitle:setText(v295_.lastNickname)
			end
		end
		if self.selectedUserFarm ~= nil and not self.isAutoReloading then
			self:updateElements()
		end
	end
	self:updateMenuButtons()
end
InGameMenuMultiplayerFrame.L10N_SYMBOL = {
	["PLAYER_COUNT"] = "ui_players",
	["DELETE_FARM_CONFIRM"] = "ui_farmDeleteConfirmation",
	["WRONG_PASSWORD"] = "ui_wrongPassword",
	["BUTTON_CREATE_FARM"] = "button_mp_createFarm",
	["BUTTON_JOIN_FARM"] = "button_mp_joinFarm",
	["BUTTON_LEAVE_FARM"] = "button_mp_leaveFarm",
	["BUTTON_DELETE_FARM"] = "button_mp_deleteFarm",
	["BUTTON_EDIT_FARM"] = "button_mp_editFarm",
	["LEAVE_FARM_CONFIRM"] = "ui_farmLeaveConfirmation",
	["MONEY_BUTTON_TEMPLATE"] = "button_mp_transferMoney",
	["BUTTON_UNBAN"] = "button_unban",
	["BUTTON_ADMIN"] = "button_adminLogin",
	["BUTTON_CONTRACT"] = "button_mp_grant",
	["BUTTON_UNCONTRACT"] = "button_mp_ungrant",
	["BUTTON_INVITE_FRIENDS"] = "ui_inviteScreen",
	["PROMPT_ADMIN_PASSWORD"] = "button_adminLogin",
	["INFO_CANNOT_BAN_SERVER"] = "ui_serverCannotBeBanned",
	["INFO_CANNOT_KICK_SERVER"] = "ui_serverCannotBeKicked",
	["DIALOG_KICK_TITLE"] = "ui_kickTitle",
	["DIALOG_KICK_CONFIRM"] = "ui_kickConfirm",
	["DIALOG_REMOVE_TITLE"] = "ui_removeFromFarmTitle",
	["DIALOG_REMOVE_CONFIRM"] = "ui_removeFromFarmConfirm",
	["DIALOG_PROMOTE_CONFIRM"] = "ui_promoteToFarmManagerConfirm",
	["DIALOG_PROMOTE_TITLE"] = "ui_promoteToFarmManagerTitle",
	["DIALOG_CONTRACTOR_STATE_TITLE"] = "ui_contractorStateChangeTitle",
	["DIALOG_GRANT_CONTRACTOR_CONFIRM"] = "ui_contractorGrantConfirm",
	["DIALOG_DENY_CONTRACTOR_CONFIRM"] = "ui_contractorUngrantConfirm"
}
InGameMenuMultiplayerFrame.PROFILE = {
	["BALANCE_POSITIVE"] = "shopMoney",
	["BALANCE_NEGATIVE"] = "shopMoneyNeg",
	["CURRENT_PLAYER_TEXT"] = "ingameMenuMPUsersListRowTextCurrentPlayer"
}
