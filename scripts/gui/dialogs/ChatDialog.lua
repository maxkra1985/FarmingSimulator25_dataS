-- Local values: ChatDialog_mt
ChatDialog = {}
ChatDialog.SCROLL_DELAY = 500
local ChatDialog_mt = Class(ChatDialog, ScreenElement)
function ChatDialog.register()
	local v2_ = ChatDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ChatDialog.xml", "ChatDialog", v2_)
end

-- Upvalues: ChatDialog_mt
-- Local values: self
function ChatDialog.new(target, custom_mt)
	-- upvalues: (copy) ChatDialog_mt
	local v5_ = ScreenElement.new(target, custom_mt or ChatDialog_mt)
	v5_.lastScrollTime = 0
	return v5_
end

function ChatDialog:onGuiSetupFinished()
	ChatDialog:superClass().onGuiSetupFinished(self)
	self.defaultPosY = self.textElement.position[2]
end

-- Local values: newPosY
function ChatDialog:onOpen(element)
	ChatDialog:superClass().onOpen(self)
	g_currentMission.isPlayerFrozen = true
	self.textElement:openIme()
	self.textElement:setForcePressed(true)
	self.textElement:setText("")
	local v8_ = self.defaultPosY * g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v9_ = self.textElement
	local v10_ = self.defaultPosY
	v9_:setPosition(nil, (math.max(v10_, v8_)))
	g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_UP_DOWN, self, self.onMenuAxisUpDown, false, true, true, true)
end

function ChatDialog:onClose(element)
	ChatDialog:superClass().onClose(self)
	if g_currentMission ~= nil then
		g_currentMission:scrollChatMessages(-9999999)
		g_currentMission.isPlayerFrozen = false
	end
	self.textElement:abortIme()
	self.textElement:setForcePressed(false)
end

function ChatDialog:onCreateTextInput(element)
	self.textElement = element
end

-- Local values: nickname, farmId, isAllowed
function ChatDialog:onSendClick()
	if self.textElement.text ~= "" then
		local v15_ = g_currentMission.playerNickname
		local v16_ = g_currentMission:getFarmId()
		if getAllowTextCommunication() then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(ChatEvent.new(self.textElement.text, v15_, v16_, g_currentMission.playerUserId))
			else
				g_server:broadcastEvent(ChatEvent.new(self.textElement.text, v15_, v16_, g_currentMission.playerUserId))
			end
			g_currentMission:addChatMessage(v15_, self.textElement.text, v16_, g_currentMission.playerUserId)
		end
		self.textElement:setText("")
	end
	g_gui:showGui("")
end

-- Local values: delta
function ChatDialog:onMenuAxisUpDown(actionName, inputValue)
	local v19_ = inputValue > 0 and 1 or (inputValue < 0 and -1 or 0)
	if v19_ ~= 0 and self.lastScrollTime + ChatDialog.SCROLL_DELAY <= g_time then
		g_currentMission:scrollChatMessages(v19_)
		self.lastScrollTime = g_time
	end
end

function ChatDialog:update(dt)
	ChatDialog:superClass().update(self, dt)
	g_currentMission.hud:setChatDisplayVisible(true)
end

function ChatDialog:onEnterPressed()
	self:onSendClick()
end

function ChatDialog:onEscPressed()
	self.textElement:setText("")
	g_gui:showGui("")
end
