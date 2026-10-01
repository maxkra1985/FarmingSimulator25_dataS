UnBanDialog = {}
local UnBanDialog_mt = Class(UnBanDialog, DialogElement)
local NO_CALLBACK = function() end
function UnBanDialog.register()
	local unBanDialog = UnBanDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/UnBanDialog.xml", "UnBanDialog", unBanDialog)
	UnBanDialog.INSTANCE = unBanDialog
end
function UnBanDialog.show(callback, target, useLocal)
	if UnBanDialog.INSTANCE ~= nil then
		local dialog = UnBanDialog.INSTANCE
		dialog:setCallback(callback, target)
		dialog:setUseLocalList(useLocal or false)
		g_gui:showDialog("UnBanDialog")
	end
end
function UnBanDialog.new(target, custom_mt)
	local self = DialogElement.new(target, custom_mt or UnBanDialog_mt)
	self.blockedPlayers = {}
	self.callbackFunc = NO_CALLBACK
	self.target = nil
	return self
end
function UnBanDialog.createFromExistingGui(gui, guiName)
	UnBanDialog.register()
	local useLocal = gui.useLocal
	local callback = gui.callbackFunc
	local target = gui.target
	UnBanDialog.show(callback, target, useLocal)
end
function UnBanDialog:updateButtons()
	self.unblockButton:setVisible(0 < #self.blockedPlayers)
	self.buttonLayout:invalidateLayout()
end
function UnBanDialog:setUseLocalList(useLocal)
	self.useLocal = useLocal
	self:reloadData()
end
function UnBanDialog:setCallback(callbackFunc, target)
	self.callbackFunc = callbackFunc or NO_CALLBACK
	self.target = target
end
function UnBanDialog:closeAndCallback()
	if self.inputDelay < self.time then
		self:close()
		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target)
			else
				self.callbackFunc()
			end
		end
		return false
	else
		return true
	end
end
function UnBanDialog:onOpen()
	UnBanDialog:superClass().onOpen(self)
	self.inputDelay = self.time + 250
	self:updateButtons()
end
function UnBanDialog:onClose()
	UnBanDialog:superClass().onClose(self)
	g_messageCenter:unsubscribeAll(self)
end
function UnBanDialog:onClickBack(_, _)
	self:closeAndCallback()
	return false
end
function UnBanDialog:onClickUnblock()
	if 0 < #self.blockedPlayers then
		local ban = self.blockedPlayers[self.banList.selectedIndex]
		if ban.isLocal then
			setIsUserBlocked(ban.uniqueUserId, ban.platformUserId, ban.platformId, false, "")
			self:reloadData()
			g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
		else
			g_client:getServerConnection():sendEvent(UnbanEvent.new(ban.uniqueUserId))
			g_client:getServerConnection():sendEvent(GetBansEvent.new())
			self.loadingText:setVisible(true)
		end
	end
	self:updateButtons()
end
function UnBanDialog:onServerBansUpdated(bans)
	self.blockedPlayers = bans
	self.loadingText:setVisible(false)
	self.noBansText:setVisible(#self.blockedPlayers == 0)
	self.banList:reloadData()
	self:updateButtons()
end
function UnBanDialog:reloadData()
	self.blockedPlayers = {}
	if self.useLocal or g_currentMission ~= nil and g_currentMission:getIsServer() then
		for i = 0, getNumOfBlockedUsers() - 1 do
			local uniqueUserId, platformUserId, platformId, displayName = getBlockedUser(i)
			table.insert(self.blockedPlayers, { uniqueUserId = uniqueUserId, platformUserId = platformUserId, platformId = platformId, displayName = displayName, isLocal = true })
		end
		self.noBansText:setVisible(#self.blockedPlayers == 0)
		self.loadingText:setVisible(false)
		self.banList:reloadData()
		self:updateButtons()
		return
	end
	g_messageCenter:subscribe(GetBansEvent, self.onServerBansUpdated, self)
	g_client:getServerConnection():sendEvent(GetBansEvent.new())
	self.loadingText:setVisible(true)
	self.noBansText:setVisible(false)
	self:updateButtons()
end
function UnBanDialog:getNumberOfItemsInSection(list, section)
	return #self.blockedPlayers
end
function UnBanDialog:populateCellForItemInSection(list, section, index, cell)
	local ban = self.blockedPlayers[index]
	cell:getAttribute("name"):setText(ban.displayName)
end
