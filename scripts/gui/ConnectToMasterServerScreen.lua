-- Local values: ConnectToMasterServerScreen_mt
ConnectToMasterServerScreen = {}
local ConnectToMasterServerScreen_mt = Class(ConnectToMasterServerScreen, ScreenElement)
function ConnectToMasterServerScreen.register()
	local v2_ = ConnectToMasterServerScreen.new()
	g_gui:loadGui("dataS/gui/ConnectToMasterServerScreen.xml", "ConnectToMasterServerScreen", v2_)
	return v2_
end

-- Upvalues: ConnectToMasterServerScreen_mt
-- Local values: self
function ConnectToMasterServerScreen.new(target, custom_mt)
	-- upvalues: (copy) ConnectToMasterServerScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or ConnectToMasterServerScreen_mt)
	v5_.isBackAllowed = false
	return v5_
end

-- Local values: controller, newGui
function ConnectToMasterServerScreen.createFromExistingGui(gui, guiName)
	local v8_ = gui:getController()
	local v9_ = ConnectToMasterServerScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	v9_:setController(v8_)
	g_gui:loadGui(gui.xmlFilename, guiName, v9_)
	return v9_
end

-- Local values: text, dialogType
function ConnectToMasterServerScreen:onOpen()
	ConnectToMasterServerScreen:superClass().onOpen(self)
	self.mainBox:setVisible(g_deepLinkingInfo == nil)
	if g_deepLinkingInfo == nil then
		MessageDialog.hide()
	else
		local v11_ = g_i18n:getText("ui_connectingPleaseWait")
		local v12_ = DialogElement.TYPE_LOADING
		MessageDialog.show(v11_, nil, nil, v12_)
	end
	g_masterServerConnection:setCallbackTarget(self)
end

function ConnectToMasterServerScreen:onClickCancel()
	ConnectToMasterServerScreen:superClass().onClickCancel(self)
	ConnectToMasterServerScreen.goBackCleanup()
	g_startMissionInfo.canStart = false
	if g_startMissionInfo.createGame then
		self:changeScreen(self.prevScreenClass or CreateGameScreen)
	else
		self:changeScreen(self.prevScreenClass or MultiplayerScreen)
	end
end

function ConnectToMasterServerScreen:setNextScreenClass(nextScreenClass)
	self.nextScreenClass = nextScreenClass
end

function ConnectToMasterServerScreen:setPrevScreenClass(prevScreenClass)
	self.prevScreenClass = prevScreenClass
end

function ConnectToMasterServerScreen:connectToFront()
	g_masterServerConnection:connectToMasterServerFront()
end

function ConnectToMasterServerScreen:connectToBack(index)
	g_masterServerConnection:disconnectFromMasterServer()
	g_masterServerConnection:connectToMasterServer(index)
end

function ConnectToMasterServerScreen:onMasterServerListStart(numMasterServers)
	self.numMasterServers = numMasterServers
end

function ConnectToMasterServerScreen:onMasterServerList(name, id) end

function ConnectToMasterServerScreen:onMasterServerListEnd()
	if self.numMasterServers == 1 then
		self:connectToBack(0)
	end
end

function ConnectToMasterServerScreen:onMasterServerConnectionFailed(reason)
	self.mainBox:setVisible(false)
	g_startMissionInfo.canStart = false
	ConnectToMasterServerScreen.goBackCleanup()
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, ClassUtil.getClassName(self.prevScreenClass))
end

-- Local values: screen
function ConnectToMasterServerScreen:onMasterServerConnectionReady()
	g_gui:changeScreen(nil, self.nextScreenClass, self.prevScreenClass).target:onMasterServerConnectionReady()
end
function ConnectToMasterServerScreen.goBackCleanup()
	g_asyncTaskManager:flushAllTasks()
	saveReadSavegameFinish("", ConnectToMasterServerScreen)
	g_deepLinkingInfo = nil
	g_masterServerConnection:disconnectFromMasterServer()
	g_mpLoadingScreen:unloadGameRelatedData()
	if g_client ~= nil then
		g_client:delete()
		g_client = nil
	end
	if g_server == nil then
		g_connectionManager:shutdownAll()
	else
		g_server:delete()
		g_server = nil
	end
end
