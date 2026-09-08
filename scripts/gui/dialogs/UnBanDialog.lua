-- Local values: UnBanDialog_mt, NO_CALLBACK
UnBanDialog = {}
local UnBanDialog_mt = Class(UnBanDialog, DialogElement)
local function NO_CALLBACK() end
function UnBanDialog.register()
	local v3_ = UnBanDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/UnBanDialog.xml", "UnBanDialog", v3_)
	UnBanDialog.INSTANCE = v3_
end

-- Local values: dialog
function UnBanDialog.show(callback, target, useLocal)
	if UnBanDialog.INSTANCE ~= nil then
		local v7_ = UnBanDialog.INSTANCE
		v7_:setCallback(callback, target)
		v7_:setUseLocalList(useLocal or false)
		g_gui:showDialog("UnBanDialog")
	end
end

-- Upvalues: UnBanDialog_mt, NO_CALLBACK
-- Local values: self
function UnBanDialog.new(target, custom_mt)
	-- upvalues: (copy) UnBanDialog_mt, (copy) NO_CALLBACK
	local v10_ = DialogElement.new(target, custom_mt or UnBanDialog_mt)
	v10_.blockedPlayers = {}
	v10_.callbackFunc = NO_CALLBACK
	v10_.target = nil
	return v10_
end

-- Local values: useLocal, callback, target
function UnBanDialog.createFromExistingGui(gui, guiName)
	UnBanDialog.register()
	local v12_ = gui.useLocal
	local v13_ = gui.callbackFunc
	local v14_ = gui.target
	UnBanDialog.show(v13_, v14_, v12_)
end

function UnBanDialog:updateButtons()
	self.unblockButton:setVisible(#self.blockedPlayers > 0)
	self.buttonLayout:invalidateLayout()
end

function UnBanDialog:setUseLocalList(useLocal)
	self.useLocal = useLocal
	self:reloadData()
end

-- Upvalues: NO_CALLBACK
function UnBanDialog:setCallback(callbackFunc, target)
	-- upvalues: (copy) NO_CALLBACK
	self.callbackFunc = callbackFunc or NO_CALLBACK
	self.target = target
end

function UnBanDialog:closeAndCallback()
	if self.inputDelay >= self.time then
		return true
	end
	self:close()
	if self.callbackFunc ~= nil then
		if self.target == nil then
			self.callbackFunc()
		else
			self.callbackFunc(self.target)
		end
	end
	return false
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

-- Local values: ban
function UnBanDialog:onClickUnblock()
	if #self.blockedPlayers > 0 then
		local v26_ = self.blockedPlayers[self.banList.selectedIndex]
		if v26_.isLocal then
			setIsUserBlocked(v26_.uniqueUserId, v26_.platformUserId, v26_.platformId, false, "")
			self:reloadData()
			g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
		else
			g_client:getServerConnection():sendEvent(UnbanEvent.new(v26_.uniqueUserId))
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

-- Local values: i, uniqueUserId, platformUserId, platformId, displayName
function UnBanDialog:reloadData()
	self.blockedPlayers = {}
	if self.useLocal or g_currentMission ~= nil and g_currentMission:getIsServer() then
		for v30_ = 0, getNumOfBlockedUsers() - 1 do
			local v31_, v32_, v33_, v34_ = getBlockedUser(v30_)
			local v35_ = self.blockedPlayers
			table.insert(v35_, {
				["uniqueUserId"] = v31_,
				["platformUserId"] = v32_,
				["platformId"] = v33_,
				["displayName"] = v34_,
				["isLocal"] = true
			})
		end
		self.noBansText:setVisible(#self.blockedPlayers == 0)
		self.loadingText:setVisible(false)
		self.banList:reloadData()
		self:updateButtons()
	else
		g_messageCenter:subscribe(GetBansEvent, self.onServerBansUpdated, self)
		g_client:getServerConnection():sendEvent(GetBansEvent.new())
		self.loadingText:setVisible(true)
		self.noBansText:setVisible(false)
		self:updateButtons()
	end
end

function UnBanDialog:getNumberOfItemsInSection(list, section)
	return #self.blockedPlayers
end

-- Local values: ban
function UnBanDialog:populateCellForItemInSection(list, section, index, cell)
	local v40_ = self.blockedPlayers[index]
	cell:getAttribute("name"):setText(v40_.displayName)
end
