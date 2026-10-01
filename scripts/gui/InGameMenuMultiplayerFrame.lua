InGameMenuMultiplayerFrame = {}
local InGameMenuMultiplayerFrame_mt = Class(InGameMenuMultiplayerFrame, TabbedMenuFrameElement)
InGameMenuMultiplayerFrame.ELEMENT_NAME = { ROW_PLAYER_NAME = "playerName", ROW_FARM_NAME = "farmName", ROW_FARM_COLOR = "farmColor" }
InGameMenuMultiplayerFrame.TRANSFER_AMOUNT = { SMALL = 5000, MEDIUM = 50000, LARGE = 250000 }
InGameMenuMultiplayerFrame.ELEMENT_NAME = { ROW_PLAYER_NAME = "playerName", ROW_FARM_NAME = "farmName", ROW_FARM_COLOR = "farmColor" }
InGameMenuMultiplayerFrame.TRANSFER_AMOUNT = { SMALL = 5000, MEDIUM = 50000, LARGE = 250000 }
InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS = 1
InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS = 2
function InGameMenuMultiplayerFrame.register()
	local inGameMenuMultiplayerFrame = InGameMenuMultiplayerFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuMultiplayerFrame.xml", "MultiplayerFrame", inGameMenuMultiplayerFrame, true)
end
function InGameMenuMultiplayerFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMultiplayerFrame_mt)
	self.currentUser = User.new()
	self.playerFarm = nil
	self.player = nil
	self.playerFarm = nil
	self.hasAskedForPassword = false
	self.timeSinceLastMoneyUpdate = 0
	self.elementFarmIdMap = {}
	self.farmIdBalanceMap = {}
	self.farmIdPlayerCountMap = {}
	self.newFarmListIndex = 0
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {}
	self.selectedUserId = nil
	self.selectedUserFarm = nil
	self.isNavigatingUsers = false
	self.users = {}
	self.listRowUser = {}
	self.permissionCheckboxes = {}
	self.checkboxPermissions = {}
	self.timeSinceLastRefresh = 0
	return self
end
function InGameMenuMultiplayerFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuMultiplayerFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function InGameMenuMultiplayerFrame:initialize()
	InGameMenuMultiplayerFrame:superClass().initialize(self)
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
	self.joinMenuButton = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_JOIN_FARM),
		callback = function()
			self:joinFarm(self.selectedFarmId)
		end,
	}
	self.leaveMenuButton = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM),
		callback = function()
			self:leaveFarm()
		end,
	}
	self.editMenuButton = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_EDIT_FARM),
		callback = function()
			self:editFarm(self.selectedFarmId)
		end,
	}
	self.createMenuButton = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_CREATE_FARM),
		callback = function()
			self:createFarm()
		end,
	}
	self.deleteMenuButton = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_DELETE_FARM),
		callback = function()
			self:deleteFarm(self.selectedFarmId)
		end,
	}
	self.playerNameTemplate:unlinkElement()
	local subCategories = {}
	for index, button in pairs(self.subCategoryTabs) do
		button:getDescendantByName("background").getIsSelected = function()
			return index == self.subCategoryPaging:getState()
		end
		function button.getIsSelected()
			return index == self.subCategoryPaging:getState()
		end
		table.insert(subCategories, tostring(index))
	end
	self.subCategoryPaging:setTexts(subCategories)
	self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
	self:setupUserListFocusContext()
	self.unblockButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = g_i18n:getText("button_blocklist"),
		callback = function()
			self:onButtonUnBan()
		end,
	}
	self.unblockRemoteButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText("button_blocklist"),
		callback = function()
			self:onButtonUnBanRemote()
		end,
	}
	self.adminButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText("button_adminLogin"),
		callback = function()
			self:onButtonAdminLogin()
		end,
	}
	self.inviteFriendsInfo = {
		inputAction = InputAction.MENU_EXTRA_2,
		text = g_i18n:getText("ui_inviteScreen"),
		callback = function()
			self:onButtonInviteFriends()
		end,
	}
	self.permissionCheckboxes = { [Farm.PERMISSION.BUY_VEHICLE] = self.buyVehiclePermissionCheckbox, [Farm.PERMISSION.SELL_VEHICLE] = self.sellVehiclePermissionCheckbox, [Farm.PERMISSION.RESET_VEHICLE] = self.resetVehiclePermissionCheckbox, [Farm.PERMISSION.BUY_PLACEABLE] = self.buyPlaceablePermissionCheckbox, [Farm.PERMISSION.SELL_PLACEABLE] = self.sellPlaceablePermissionCheckbox, [Farm.PERMISSION.HIRE_ASSISTANT] = self.hireAssistantPermissionCheckbox, [Farm.PERMISSION.MANAGE_CONTRACTS] = self.manageMissionsPermissionCheckbox, [Farm.PERMISSION.MANAGE_PRODUCTIONS] = self.manageProductionsPermissionCheckbox, [Farm.PERMISSION.TRADE_ANIMALS] = self.tradeAnimalsPermissionCheckbox, [Farm.PERMISSION.CUT_TREES] = self.cutTreesPermissionCheckbox, [Farm.PERMISSION.CREATE_FIELDS] = self.createFieldsPermissionCheckbox, [Farm.PERMISSION.LANDSCAPING] = self.landscapingPermissionCheckbox }
	self.reportReasons = { [ReportUserReason.PLAYER_NAME + 1] = g_i18n:getText("ui_reportPlayer_reason_name"), [ReportUserReason.VOICE_CHAT + 1] = g_i18n:getText("ui_reportPlayer_reason_voice"), [ReportUserReason.TEXT_CHAT + 1] = g_i18n:getText("ui_reportPlayer_reason_text"), [ReportUserReason.BEHAVIOR + 1] = g_i18n:getText("ui_reportPlayer_reason_behavior"), [ReportUserReason.CHEATING + 1] = g_i18n:getText("ui_reportPlayer_reason_cheating") }
	self.checkboxPermissions = {}
	for k, v in pairs(self.permissionCheckboxes) do
		self.checkboxPermissions[v] = k
	end
end
function InGameMenuMultiplayerFrame:delete()
	self.playerNameTemplate:delete()
	InGameMenuMultiplayerFrame:superClass().delete(self)
end
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
	if 0 < self.farmList:getItemCount() then
		local listIndex = 1
		if self.playerFarm ~= nil then
			listIndex = self:getListFarmIndex(self.playerFarm.farmId)
		end
		self.farmList:setSelectedIndex(listIndex, true)
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
		self.isNavigatingUsers = true
		self:updateMenuButtons()
	end
	function self.userList.onFocusLeave()
		self.isNavigatingUsers = false
		self:updateMenuButtons()
	end
end
function InGameMenuMultiplayerFrame:setCurrentUserId(currentUserId)
	self.currentUserId = currentUserId
	self.currentUser = g_currentMission.userManager:getUserByUserId(currentUserId) or self.currentUser
	self:updateMenuButtons()
end
function InGameMenuMultiplayerFrame:setUsers(users)
	local sortedUsers = self:getSortedUsers(users)
	self.users = sortedUsers
	self.shouldRebuildUserList = true
	self:updateMenuButtons()
end
function InGameMenuMultiplayerFrame:getSortedUsers(users)
	local sortedUsers = {}
	for _, user in pairs(users) do
		if not g_currentMission.connectedToDedicatedServer or user:getId() ~= g_currentMission:getServerUserId() then
			table.insert(sortedUsers, user)
		end
	end
	local groupSortUsers = function(user1, user2)
		local user1Id = user1:getId()
		local user2Id = user2:getId()
		if user1Id == nil and user2Id == nil then
			return false
		end
		local farm1 = g_farmManager:getFarmByUserId(user1Id)
		local farm2 = g_farmManager:getFarmByUserId(user2Id)
		if farm1 == nil and farm2 == nil then
			if user1Id == nil then
				return false
			elseif user2Id == nil then
				return true
			else
				return user1Id < user2Id
			end
		end
		if farm1 == nil then
			return false
		end
		if farm2 == nil then
			return true
		end
		local farm1Id = farm1.farmId
		local farm2Id = farm2.farmId
		if self.playerFarm ~= nil and farm1Id == self.playerFarm.farmId then
			farm1Id = -math.huge
		end
		if self.playerFarm ~= nil and farm2Id == self.playerFarm.farmId then
			farm2Id = -math.huge
		end
		if farm1Id == FarmManager.SPECTATOR_FARM_ID then
			farm1Id = math.huge
		end
		if farm2Id == FarmManager.SPECTATOR_FARM_ID then
			farm2Id = math.huge
		end
		if farm1Id ~= farm2Id then
			return farm1Id < farm2Id
		end
		local nickname1 = user1:getNickname()
		local nickname2 = user2:getNickname()
		if nickname1 ~= nickname2 then
			return nickname1 < nickname2
		else
			return true
		end
	end
	table.sort(sortedUsers, groupSortUsers)
	return sortedUsers
end
function InGameMenuMultiplayerFrame:setPlayer(player)
	self.player = player
end
function InGameMenuMultiplayerFrame:setPlayerFarm(farm)
	self.playerFarm = farm
end
function InGameMenuMultiplayerFrame:getListFarmIndex(farmId)
	local index = 1
	if farmId ~= FarmManager.SPECTATOR_FARM_ID then
		for i, farm in ipairs(self.farms) do
			if farm.farmId == farmId then
				return i
			end
		end
	end
	return index
end
function InGameMenuMultiplayerFrame:setFarmBalance(farmId, balance)
	if balance == nil then
		local farm = g_farmManager:getFarmById(farmId)
		balance = farm:getBalance()
	end
	if self.farmIdBalanceMap[farmId] ~= nil then
		self.farmIdBalanceMap[farmId]:setValue(balance)
	end
end
function InGameMenuMultiplayerFrame:getSortedFarmList()
	local list = {}
	local farms = g_farmManager:getFarms()
	local spectatorFarm = nil
	table.insert(list, self.playerFarm)
	for _, farm in pairs(farms) do
		if not farm.isSpectator and (farm ~= self.playerFarm and farm.showInFarmScreen) then
			table.insert(list, farm)
		end
		if farm.isSpectator then
			spectatorFarm = farm
		end
	end
	if 0 < spectatorFarm:getNumActivePlayers() and spectatorFarm ~= self.playerFarm then
		table.insert(list, spectatorFarm)
	end
	return list
end
function InGameMenuMultiplayerFrame:updateElements()
	local isFarmManager = self.playerFarm:isUserFarmManager(self.currentUserId)
	local hasHighPrivilege = isFarmManager or self.currentUser:getIsMasterUser()
	local isOwnFarmSelected = self.selectedUserFarm == self.playerFarm
	local isSpectatorSelected = self.selectedUserFarm.isSpectator
	local isSelfSelected = self.selectedUserId == self.currentUserId
	local isSelectedUserFarmManager = false
	if self.selectedUserId ~= nil then
		isSelectedUserFarmManager = self.selectedUserFarm:isUserFarmManager(self.selectedUserId)
	end
	local canManageSelectedFarm = isFarmManager and isOwnFarmSelected or self.currentUser:getIsMasterUser()
	local isOtherAdminSelected = false
	local selectionIsUser = self.selectedUserId ~= nil
	local user = nil
	if selectionIsUser then
		user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		if user ~= nil and self.selectedUserId ~= self.currentUserId then
			user:getIsMasterUser()
		end
		isOtherAdminSelected = false
	end
	self.transferButton:setVisible(not selectionIsUser and not isOwnFarmSelected and isFarmManager and not isSpectatorSelected)
	self.removeButton:setVisible(false)
	self.promoteButton:setVisible(selectionIsUser and canManageSelectedFarm and not isSpectatorSelected and not isOtherAdminSelected)
	self.promoteButton:setText(g_i18n:getText(isSelectedUserFarmManager and "button_mp_dimiss" or "button_mp_promote"))
	local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)
	self.contractorButton:setVisible(not selectionIsUser and hasHighPrivilege and not isOwnFarmSelected and not isSpectatorSelected and not self.playerFarm.isSpectator)
	self.contractorButton:setText(g_i18n:getText(isContracting and "button_mp_ungrant" or "button_mp_grant"))
	self.kickButton:setVisible(selectionIsUser and not isSelfSelected and self.currentUser:getIsMasterUser())
	self.blockFromServerButton:setVisible(selectionIsUser and not isSelfSelected and self.currentUser:getIsMasterUser() and not g_currentMission:getIsServer() and self.selectedUserId ~= g_currentMission:getServerUserId())
	self.blockButton:setVisible(selectionIsUser and not isSelfSelected)
	if selectionIsUser then
		if user ~= nil then
			self.blockButton:setText(g_i18n:getText(user:getIsBlocked() and "button_unblock" or "button_block"))
		end
	end
	self.muteButton:setVisible(selectionIsUser and isSelfSelected and VoiceChatUtil.getHasRecordingDevice() and not VoiceChatUtil.getIsVoiceRestricted())
	if selectionIsUser then
		if user ~= nil then
			self.muteButton:setText(g_i18n:getText(user:getVoiceMuted() and "button_unmute" or "button_mute"))
		end
	end
	self.peerVolumeOption:setVisible(selectionIsUser and not isSelfSelected and not VoiceChatUtil.getIsVoiceRestricted())
	if selectionIsUser then
		local texts = { g_i18n:getText("button_mute") }
		local volumeText = g_i18n:getText("ui_volumeSound")
		for i = 1, 10 do
			table.insert(texts, string.format("%s: %d%%", volumeText, i * 10))
		end
		self.peerVolumeOption:setTexts(texts)
		local rawVolume = user ~= nil and user:getVoiceVolume() or 0
		self.peerVolumeOption:setState(MathUtil.round(rawVolume / 0.1 + 1, 0))
	end
	if selectionIsUser then
		if user ~= nil then
			self.showProfileButton:setVisible(Platform.hasNativeProfiles and getPlatformIdsAreCompatible(user:getPlatformId(), getPlatformId()))
			self.reportButton:setVisible(not isSelfSelected)
		else
			self.showProfileButton:setVisible(false)
			self.reportButton:setVisible(false)
		end
	end
	if selectionIsUser then
		if user ~= nil then
			local canChangePermissions = not isSpectatorSelected and canManageSelectedFarm and not isSelectedUserFarmManager and not user:getIsMasterUser()
			local permissions = self.selectedUserFarm:getUserPermissions(self.selectedUserId)
			for permissionKey, checkbox in pairs(self.permissionCheckboxes) do
				checkbox:setIsChecked(permissions[permissionKey] or user:getIsMasterUser(), true)
				checkbox:setDisabled(not canChangePermissions)
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
	end
	self.actionsBox:invalidateLayout()
	self.permissionsBox:invalidateLayout()
end
function InGameMenuMultiplayerFrame:updateMenuButtons()
	if g_gui.currentlyReloading then
		return
	else
		self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
		if self.subCategoryPaging:getState() == InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS then
			if self.farmList:getIsFocused() then
				if self.selectedFarmId ~= nil then
					if self.selectedFarmId == self.playerFarm.farmId then
						table.insert(self.menuButtonInfo, self.leaveMenuButton)
					else
						table.insert(self.menuButtonInfo, self.joinMenuButton)
					end
					if self.currentUser:getIsMasterUser() then
						table.insert(self.menuButtonInfo, self.editMenuButton)
						table.insert(self.menuButtonInfo, self.deleteMenuButton)
					elseif g_currentMission ~= nil then
						if g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser() then
							table.insert(self.menuButtonInfo, self.adminButtonInfo)
						end
					end
				elseif self.currentUser:getIsMasterUser() then
					table.insert(self.menuButtonInfo, self.createMenuButton)
				elseif g_currentMission ~= nil then
					if g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser() then
						table.insert(self.menuButtonInfo, self.adminButtonInfo)
					end
				end
			end
		else
			if 0 < getNumOfBlockedUsers() then
				table.insert(self.menuButtonInfo, self.unblockButtonInfo)
			end
			if g_currentMission ~= nil then
				if self.currentUser:getIsMasterUser() then
					if g_currentMission.connectedToDedicatedServer then
						table.insert(self.menuButtonInfo, self.unblockRemoteButtonInfo)
					end
				elseif g_currentMission ~= nil then
					if g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser() then
						table.insert(self.menuButtonInfo, self.adminButtonInfo)
					end
				end
				if Platform.hasFriendInvitation and PlatformPrivilegeUtil.getCanInvitePlayer(g_currentMission) then
					table.insert(self.menuButtonInfo, self.inviteFriendsInfo)
				end
			end
		end
		self:setMenuButtonInfoDirty()
	end
end
function InGameMenuMultiplayerFrame:update(dt)
	InGameMenuMultiplayerFrame:superClass().update(self, dt)
	if self.subCategoryPaging:getState() ~= InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS then
		return
	else
		if 1000 < self.timeSinceLastRefresh then
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
function InGameMenuMultiplayerFrame:joinFarm(farmId)
	local currentFarmId = self.playerFarm.farmId
	if self.playerFarm ~= nil and farmId ~= currentFarmId then
		if currentFarmId ~= FarmManager.SPECTATOR_FARM_ID then
			local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.LEAVE_FARM_CONFIRM), self.playerFarm.name)
			local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM)
			local callback = self.doJoinFarm
			YesNoDialog.show(callback, self, text, title)
			return
		end
		self:doJoinFarm(true, farmId)
	end
end
function InGameMenuMultiplayerFrame:doJoinFarm(yesNo)
	if yesNo then
		local farm = g_farmManager:getFarmById(self.selectedFarmId)
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, self.selectedFarmId, farm.password))
	end
end
function InGameMenuMultiplayerFrame:leaveFarm()
	local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.LEAVE_FARM_CONFIRM), self.playerFarm.name)
	local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM)
	local callback = self.doLeaveFarm
	YesNoDialog.show(callback, self, text, title)
end
function InGameMenuMultiplayerFrame:doLeaveFarm(yesNo)
	if yesNo then
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, FarmManager.SPECTATOR_FARM_ID))
	end
end
function InGameMenuMultiplayerFrame:deleteFarm(farmId)
	local farm = g_farmManager:getFarmById(farmId)
	local canDestroy, messageCannotDestroy = farm:canBeDestroyed()
	if canDestroy then
		local text = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DELETE_FARM_CONFIRM)
		local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_DELETE_FARM)
		local callback = self.onDeleteFarmYesNo
		YesNoDialog.show(callback, self, text, title)
	else
		InfoDialog.show(g_i18n:getText(messageCannotDestroy))
	end
end
function InGameMenuMultiplayerFrame:editFarm(farmId)
	EditFarmDialog.show(farmId)
end
function InGameMenuMultiplayerFrame:createFarm()
	EditFarmDialog.show()
end
function InGameMenuMultiplayerFrame:reloadFarms()
	self.farms = {}
	local farms = g_farmManager:getFarms()
	for _, farm in ipairs(farms) do
		if farm.showInFarmScreen then
			table.insert(self.farms, farm)
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
		self.noFarmsText:setVisible(false)
	end
end
function InGameMenuMultiplayerFrame:onPlayerSetFarmAnswer(answerState, farmId, password)
	if answerState == PlayerSetFarmAnswerEvent.STATE.OK then
		local joinedFarm = g_farmManager:getFarmById(farmId)
		joinedFarm.password = password
		self.hasAskedForPassword = false
		self.farmList:setSelectedIndex(self:getListFarmIndex(farmId))
	else
		if answerState == PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED then
			if not self.hasAskedForPassword then
				self.hasAskedForPassword = true
				PasswordDialog.show(self.onFarmPasswordEntered, self, farmId, "", g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.BUTTON_JOIN_FARM))
				return
			end
			InfoDialog.show(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.WRONG_PASSWORD))
			self.hasAskedForPassword = false
		end
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
function InGameMenuMultiplayerFrame:onFarmCreated(newFarmId)
	self:reloadFarms()
	if self.currentUser:getIsMasterUser() then
		local newIndex = self:getListFarmIndex(newFarmId)
		self.farmList:setSelectedIndex(newIndex, true)
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
function InGameMenuMultiplayerFrame:onDoubleClickFarm(list, section, index)
	if index == self.newFarmListIndex then
		self:createFarm()
		return
	end
	local farm = self.farms[index]
	if farm ~= nil then
		self.selectedFarmId = farm.farmId
		self:joinFarm(self.selectedFarmId)
	else
		Logging.warning("Farm does not exist anymore")
	end
end
function InGameMenuMultiplayerFrame:onDeleteFarmYesNo(yes)
	if yes then
		local farm = g_farmManager:getFarmById(self.selectedFarmId)
		if farm:canBeDestroyed() then
			g_client:getServerConnection():sendEvent(FarmDestroyEvent.new(self.selectedFarmId))
		end
	end
end
function InGameMenuMultiplayerFrame:onClickUsers()
	self.subCategoryPaging:setState(InGameMenuMultiplayerFrame.SUB_CATEGORY_USERS, true)
	FocusManager:setFocus(self.userList)
end
function InGameMenuMultiplayerFrame:onClickFarms()
	self.subCategoryPaging:setState(InGameMenuMultiplayerFrame.SUB_CATEGORY_FARMS, true)
	if 0 < self.farmList:getItemCount() then
		FocusManager:setFocus(self.farmList)
	else
		FocusManager:setFocus(self.subCategoryPaging)
	end
end
function InGameMenuMultiplayerFrame:updateSubCategoryPages(subCategoryIndex)
	for index, page in pairs(self.subCategoryPages) do
		page:setVisible(index == subCategoryIndex)
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
function InGameMenuMultiplayerFrame:onButtonKick()
	if self.selectedUserId ~= nil and self.selectedUserId ~= g_currentMission:getServerUserId() then
		local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_KICK_CONFIRM), user:getNickname())
		local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_KICK_TITLE)
		local callback = self.onYesNoKick
		YesNoDialog.show(callback, self, text, title)
		return
	end
	InfoDialog.show(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.INFO_CANNOT_KICK_SERVER))
end
function InGameMenuMultiplayerFrame:onYesNoKick(yes)
	if yes then
		g_client:getServerConnection():sendEvent(KickBanEvent.new(true, self.selectedUserId))
	end
end
function InGameMenuMultiplayerFrame:onButtonUnBan()
	local callbackFunc = function()
		self:updateElements()
		self:updateMenuButtons()
	end
	UnBanDialog.show(callbackFunc, self, true)
end
function InGameMenuMultiplayerFrame:onButtonUnBanRemote()
	local callbackFunc = function()
		self:updateElements()
		self:updateMenuButtons()
	end
	UnBanDialog.show(callbackFunc, self, false)
end
function InGameMenuMultiplayerFrame:onButtonShowProfile()
	if self.selectedUserId ~= nil then
		local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local nickname = user:getPlatformUserId()
		if nickname == "" then
			nickname = user:getNickname()
		end
		showUserProfile(nickname)
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
function InGameMenuMultiplayerFrame:onClickPermission(state, binaryOption, isLeftButton)
	local permission = self.checkboxPermissions[binaryOption]
	self.selectedUserFarm:setUserPermission(self.selectedUserId, permission, not isLeftButton)
end
function InGameMenuMultiplayerFrame:onClickTransferButton()
	TransferMoneyDialog.show(self.transferMoney, self, self.selectedUserFarm)
end
function InGameMenuMultiplayerFrame:transferMoney(amount)
	if 0 < amount then
		g_farmManager:transferMoney(self.selectedUserFarm, amount)
	end
end
function InGameMenuMultiplayerFrame:onClickRemoveFromFarm()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_REMOVE_CONFIRM), user:getNickname())
	local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_REMOVE_TITLE)
	local callback = self.onYesNoRemoveFromFarm
	YesNoDialog.show(callback, self, text, title)
end
function InGameMenuMultiplayerFrame:onYesNoRemoveFromFarm(yes)
	if yes then
		g_farmManager:removeUserFromFarm(self.selectedUserId)
	end
end
function InGameMenuMultiplayerFrame:onClickPromote()
	if not self.selectedUserFarm:isUserFarmManager(self.selectedUserId) then
		local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local text = string.format(g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_PROMOTE_CONFIRM), user:getNickname())
		local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_PROMOTE_TITLE)
		local callback = self.onYesNoPromoteToFarmManager
		YesNoDialog.show(callback, self, text, title)
	else
		self.selectedUserFarm:demoteUser(self.selectedUserId)
		self:updateElements()
	end
end
function InGameMenuMultiplayerFrame:onYesNoPromoteToFarmManager(yes)
	if yes then
		self.selectedUserFarm:promoteUser(self.selectedUserId)
		self:updateElements()
	end
end
function InGameMenuMultiplayerFrame:onClickContractor()
	local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)
	local confirmTextTemplateSymbol = nil
	if isContracting then
		confirmTextTemplateSymbol = InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_DENY_CONTRACTOR_CONFIRM
	else
		confirmTextTemplateSymbol = InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_GRANT_CONTRACTOR_CONFIRM
	end
	local text = string.format(g_i18n:getText(confirmTextTemplateSymbol), self.selectedUserFarm.name)
	local title = g_i18n:getText(InGameMenuMultiplayerFrame.L10N_SYMBOL.DIALOG_CONTRACTOR_STATE_TITLE)
	local callback = self.onYesNoToggleContractorState
	YesNoDialog.show(callback, self, text, title)
end
function InGameMenuMultiplayerFrame:onYesNoToggleContractorState(yes)
	if yes then
		local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)
		self.selectedUserFarm:setIsContractingFor(self.playerFarm.farmId, not isContracting, false)
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
function InGameMenuMultiplayerFrame:onButtonBlock()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	if user:getIsBlocked() then
		user:unblock()
		self:updateDisplay()
	else
		if Platform.hasNativeProfiles and getPlatformIdsAreCompatible(user:getPlatformId(), getPlatformId()) then
			user:block()
			return
		end
		local title = g_i18n:getText("ui_doYouWantToBlockThisServer_title")
		local text = string.format(g_i18n:getText("ui_blockPlayerConfirm"), user:getNickname())
		local callback = function(yes)
			if yes then
				g_currentMission:banUser(user)
				self:updateDisplay()
			end
		end
		YesNoDialog.show(callback, nil, text, title)
	end
end
function InGameMenuMultiplayerFrame:onButtonBlockFromServer()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	local text = string.format(g_i18n:getText("ui_banConfirm"), user:getNickname())
	local title = g_i18n:getText("ui_banTitle")
	local callback = function(yes)
		if yes then
			g_client:getServerConnection():sendEvent(KickBanEvent.new(false, self.selectedUserId))
		end
	end
	YesNoDialog.show(callback, nil, text, title)
end
function InGameMenuMultiplayerFrame:onButtonReport()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	local title = g_i18n:getText("ui_reportPlayer_title")
	local text = string.format(g_i18n:getText("ui_reportPlayer_confirm"), user:getNickname())
	local options = self.reportReasons
	local callback = function(item)
		if 0 < item then
			user:report(item - 1)
		end
	end
	OptionDialog.show(callback, text, title, options)
end
function InGameMenuMultiplayerFrame:onButtonMute()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	if user:getVoiceMuted() then
		user:setVoiceMuted(false)
	else
		user:setVoiceMuted(true)
	end
	self:updateDisplay()
end
function InGameMenuMultiplayerFrame:onPeerVolumeChanged(state)
	local volume = (state - 1) * 0.1
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	user:setVoiceVolume(volume)
end
function InGameMenuMultiplayerFrame:getNumberOfSections(list)
	if list == self.userList then
		return #self.sortedFarms
	else
		return 1
	end
end
function InGameMenuMultiplayerFrame:getCellTypeForItemInSection(list, section, index)
	if list == self.userList then
		if index == 1 then
			return "farm"
		else
			return "user"
		end
	end
	return nil
end
function InGameMenuMultiplayerFrame:getNumberOfItemsInSection(list, section)
	if list == self.farmList then
		local numFarms = #self.farms
		self.newFarmListIndex = nil
		if numFarms < FarmManager.MAX_NUM_FARMS and self.currentUser:getIsMasterUser() then
			numFarms = numFarms + 1
			self.newFarmListIndex = numFarms
		end
		return numFarms
	else
		local farm = self.sortedFarms[section]
		return #farm:getActiveUsers() + 1
	end
end
function InGameMenuMultiplayerFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.farmList then
		local farm = self.farms[index]
		cell:getAttribute("existingFarm"):setVisible(farm ~= nil)
		cell:getAttribute("newFarm"):setVisible(farm == nil)
		if farm ~= nil then
			local farmId = self.elementFarmIdMap[cell]
			if farmId ~= nil then
				self.farmIdBalanceMap[farmId] = nil
			end
			cell:getAttribute("farmName"):setText(farm.name)
			cell:getAttribute("farmIcon"):setImageSlice(nil, farm:getIconSliceId())
			self.farmIdBalanceMap[farm.farmId] = cell:getAttribute("farmBalance")
			cell:getAttribute("farmBalance"):setValue(farm:getBalance())
			local playerNameLayout = cell:getAttribute("playerNameLayout")
			playerNameLayout:updateAbsolutePosition()
			for i = 1, #playerNameLayout.elements do
				playerNameLayout.elements[1]:delete()
			end
			for _, player in ipairs(farm:getActiveUsers()) do
				local userId = player.userId
				local user = g_currentMission.userManager:getUserByUserId(userId)
				if user == nil then
					continue
				end
				local nickname = user:getNickname()
				local item = self.playerNameTemplate:clone(playerNameLayout)
				item:setText(nickname)
			end
			playerNameLayout:invalidateLayout()
			self.elementFarmIdMap[cell] = farm.farmId
		end
	else
		local farm = self.sortedFarms[section]
		if index == 1 then
			if farm.farmId == FarmManager.SPECTATOR_FARM_ID then
				cell:getAttribute("title"):setText(g_i18n:getText("ui_noFarm"))
				cell:getAttribute("farmBalance"):setVisible(false)
			else
				cell:getAttribute("title"):setText(farm.name)
				cell:getAttribute("farmBalance"):setVisible(true)
				cell:getAttribute("farmBalance"):setValue(farm:getBalance())
			end
			cell:getAttribute("dot").color = farm:getColor()
			return
		end
		local userInfos = farm:getActiveUsers()
		local userInfo = userInfos[index - 1]
		local user = g_currentMission.userManager:getUserByUserId(userInfo.userId)
		if user == nil then
			return
		end
		cell:getAttribute("playerName"):setText(user:getNickname())
		cell:getAttribute("platform"):setPlatformId(user:getPlatformId())
		if not g_currentMission.connectedToDedicatedServer or user:getId() ~= g_currentMission:getServerUserId() then
			local isFarmManager = farm:isUserFarmManager(user:getId())
			local noMic = voiceChatGetConnectionStatus(user:getUniqueUserId()) == VoiceChatConnectionStatus.UNAVAILABLE
			cell:getAttribute("noMicrophone"):setVisible(noMic)
			cell:getAttribute("muted"):setVisible(not noMic and user:getVoiceMuted())
			cell:getAttribute("farmManager"):setVisible(isFarmManager)
			cell:getAttribute("admin"):setVisible(user:getIsMasterUser())
			cell:getAttribute("admin").parent:invalidateLayout()
		end
	end
end
function InGameMenuMultiplayerFrame:onListSelectionChanged(list, section, index)
	if list == self.farmList then
		self.selectedFarmId = nil
		if index ~= self.newFarmListIndex then
			local farm = self.farms[index]
			if farm ~= nil then
				self.selectedFarmId = farm.farmId
			end
		end
	else
		local farm = self.sortedFarms[section]
		self.actionsTitle:setVisible(false)
		if index == 1 then
			self.selectedUserId = nil
			self.selectedUserFarm = farm
		else
			local user = farm:getActiveUsers()[index - 1]
			if user ~= nil then
				self.selectedUserId = user.userId
				self.selectedUserFarm = farm
				if user.lastNickname == nil and farm ~= nil then
					farm:updateLastNickname(user.userId)
				end
				self.actionsTitle:setVisible(true)
				self.actionsTitle:setText(user.lastNickname)
			end
		end
		if self.selectedUserFarm ~= nil and not self.isAutoReloading then
			self:updateElements()
		end
	end
	self:updateMenuButtons()
end
InGameMenuMultiplayerFrame.L10N_SYMBOL = {
	PLAYER_COUNT = "ui_players",
	DELETE_FARM_CONFIRM = "ui_farmDeleteConfirmation",
	WRONG_PASSWORD = "ui_wrongPassword",
	BUTTON_CREATE_FARM = "button_mp_createFarm",
	BUTTON_JOIN_FARM = "button_mp_joinFarm",
	BUTTON_LEAVE_FARM = "button_mp_leaveFarm",
	BUTTON_DELETE_FARM = "button_mp_deleteFarm",
	BUTTON_EDIT_FARM = "button_mp_editFarm",
	LEAVE_FARM_CONFIRM = "ui_farmLeaveConfirmation",
	MONEY_BUTTON_TEMPLATE = "button_mp_transferMoney",
	BUTTON_UNBAN = "button_unban",
	BUTTON_ADMIN = "button_adminLogin",
	BUTTON_CONTRACT = "button_mp_grant",
	BUTTON_UNCONTRACT = "button_mp_ungrant",
	BUTTON_INVITE_FRIENDS = "ui_inviteScreen",
	PROMPT_ADMIN_PASSWORD = "button_adminLogin",
	INFO_CANNOT_BAN_SERVER = "ui_serverCannotBeBanned",
	INFO_CANNOT_KICK_SERVER = "ui_serverCannotBeKicked",
	DIALOG_KICK_TITLE = "ui_kickTitle",
	DIALOG_KICK_CONFIRM = "ui_kickConfirm",
	DIALOG_REMOVE_TITLE = "ui_removeFromFarmTitle",
	DIALOG_REMOVE_CONFIRM = "ui_removeFromFarmConfirm",
	DIALOG_PROMOTE_CONFIRM = "ui_promoteToFarmManagerConfirm",
	DIALOG_PROMOTE_TITLE = "ui_promoteToFarmManagerTitle",
	DIALOG_CONTRACTOR_STATE_TITLE = "ui_contractorStateChangeTitle",
	DIALOG_GRANT_CONTRACTOR_CONFIRM = "ui_contractorGrantConfirm",
	DIALOG_DENY_CONTRACTOR_CONFIRM = "ui_contractorUngrantConfirm",
}
InGameMenuMultiplayerFrame.PROFILE = { BALANCE_POSITIVE = "shopMoney", BALANCE_NEGATIVE = "shopMoneyNeg", CURRENT_PLAYER_TEXT = "ingameMenuMPUsersListRowTextCurrentPlayer" }
