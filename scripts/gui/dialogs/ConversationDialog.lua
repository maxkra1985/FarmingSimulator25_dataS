-- Local values: ConversationDialog_mt
ConversationDialog = {}
local ConversationDialog_mt = Class(ConversationDialog, MessageDialog)
function ConversationDialog.register()
	local v2_ = ConversationDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ConversationDialog.xml", "ConversationDialog", v2_)
	ConversationDialog.INSTANCE = v2_
end

-- Local values: dialog
function ConversationDialog.show(npcName, text, options, duration, callback, target, callbackArgs)
	if ConversationDialog.INSTANCE ~= nil then
		local v10_ = ConversationDialog.INSTANCE
		v10_:setVisible(true)
		v10_:setNpcName(npcName)
		v10_:setText(text)
		v10_:setOptions(options)
		if duration ~= nil and #options > 0 then
			Logging.devWarning("Not allowed to have a duration of options are available")
			duration = 0
		end
		v10_:setDuration(duration)
		v10_:setCallback(callback, target, callbackArgs)
		if not v10_.isOpen then
			g_gui:showDialog("ConversationDialog")
		end
	end
end
function ConversationDialog.hide()
	if ConversationDialog.INSTANCE ~= nil then
		ConversationDialog.INSTANCE:close()
	end
end

-- Upvalues: ConversationDialog_mt
-- Local values: self
function ConversationDialog.new(target, custom_mt)
	-- upvalues: (copy) ConversationDialog_mt
	local v13_ = MessageDialog.new(target, custom_mt or ConversationDialog_mt)
	v13_.buttonAction = InputAction.MENU_ACCEPT
	v13_.isBackAllowed = false
	v13_.inputDelay = 250
	v13_.duration = math.huge
	v13_.disableOpenSound = true
	v13_.isOpen = false
	v13_.buttonOptionMapping = {}
	return v13_
end

function ConversationDialog:delete()
	self.optionButtonTemplate:delete()
	ConversationDialog:superClass().delete(self)
end

-- Local values: text, options, callback, target, callbackArgs, npcName
function ConversationDialog.createFromExistingGui(gui, guiName)
	ConversationDialog.register()
	local v16_ = gui.text
	local v17_ = gui.options
	local v18_ = gui.callbackFunc
	local v19_ = gui.target
	local v20_ = gui.args
	local v21_ = gui.npcName
	ConversationDialog.show(v21_, v16_, v17_, v18_, v19_, v20_)
end

-- Local values: button
function ConversationDialog:onGuiSetupFinished()
	ConversationDialog:superClass().onGuiSetupFinished(self)
	self.backgroundHeightOffset = self.optionBoxBackground.size[2] - self.optionsBox.size[2]
	self.boxOffset = self.box.size[2] - self.optionBoxBackground.size[2] - self.textBox.size[2]
	local v23_ = self.optionButtonTemplate:getDescendantByName("text")
	self.borderHeight = self.optionButtonTemplate.size[2] - v23_.size[2]
	self.optionButtonTemplate:unlinkElement()
	FocusManager:removeElement(self.optionButtonTemplate)
end

function ConversationDialog:update(dt)
	ConversationDialog:superClass().update(self, dt)
	if self.duration ~= nil then
		self.duration = self.duration - dt
		if self.duration < 0 then
			self:onClickOption(false, 0)
			self.duration = nil
		end
	end
end

-- Local values: _, eventId
function ConversationDialog:onOpen()
	ConversationDialog:superClass().onOpen(self)
	if self.options == nil or #self.options == 0 then
		local _, v27_ = g_inputBinding:registerActionEvent(InputAction.CONVERSATION_SKIP, self, self.onSkip, false, true, false, true)
		self.skipEventId = v27_
	end
	self.inputDelay = self.time + 250
	self.isOpen = true
end

function ConversationDialog:onClose()
	ConversationDialog:superClass().onClose(self)
	self.duration = nil
	self.isOpen = false
	if self.skipEventId ~= nil then
		g_inputBinding:removeActionEvent(self.skipEventId)
		self.skipEventId = nil
	end
end

-- Local values: height
function ConversationDialog:setText(text)
	self.textBox:setVisible(text ~= nil)
	if text ~= nil then
		self.textElement:setText(text)
		self.text = text
		local v31_ = self.textElement:getTextHeight()
		self.textBox:setSize(nil, v31_ + self.textBox.margin[2] + self.textBox.margin[2])
	end
	self:invalidateOptionsBox()
end

-- Local values: identation
function ConversationDialog:setNpcName(npcName)
	self.npcNameElement:setText(npcName .. ": ")
	self.npcName = npcName
	local v34_ = self.npcNameElement:getTextWidth()
	self.textElement:setFirstLineIndentation(v34_ + self.textElement.margin[3])
end

-- Local values: i, element, firstButton, k, option, background, button, height
function ConversationDialog:setOptions(options)
	self.options = options
	for v37_ = #self.optionsBox.elements, 1, -1 do
		self.optionsBox.elements[v37_]:delete()
	end
	if self.options ~= nil then
		local v38_ = nil
		for v_u_39_, v40_ in ipairs(self.options) do
			local v_u_41_ = self.optionButtonTemplate:clone(self.optionsBox)
			local v42_ = v_u_41_:getDescendantByName("text")
			v42_:setText(v40_)
			v_u_41_:setSize(nil, v42_:getTextHeight() + self.borderHeight)
			function v42_.onClickCallback()
				-- upvalues: (copy) self, (copy) v_u_39_
				self:onClickOption(false, v_u_39_)
			end
			function v42_.onFocusCallback()
				-- upvalues: (copy) v_u_41_
				v_u_41_.focused = true
			end
			function v42_.onLeaveCallback()
				-- upvalues: (copy) v_u_41_
				v_u_41_.focused = false
			end
			function v42_.onHighlightCallback()
				-- upvalues: (copy) v_u_41_
				v_u_41_.highlighted = true
			end
			function v42_.onHighlightRemoveCallback()
				-- upvalues: (copy) v_u_41_
				v_u_41_.highlighted = false
			end
			if v38_ == nil then
				v38_ = v42_
			end
		end
		self:invalidateOptionsBox()
		if v38_ ~= nil then
			FocusManager:setFocus(v38_)
			FocusManager:setHighlight(v38_)
		end
	end
end

-- Local values: sizeY, boxSizeY
function ConversationDialog:invalidateOptionsBox()
	local v44_ = self.optionsBox:invalidateLayout()
	local v45_ = self.textBox.size[2]
	if self.options ~= nil and #self.options > 0 then
		self.optionsBox:setSize(nil, v44_)
		local v46_ = v44_ + self.optionsBox.margin[2] + self.optionsBox.margin[4]
		self.optionBoxBackground:setSize(nil, v46_ + self.backgroundHeightOffset)
		v45_ = v45_ + self.optionBoxBackground.size[2] + self.boxOffset
	end
	local v47_ = self.optionBoxBackground
	local v48_
	if self.options == nil then
		v48_ = false
	else
		v48_ = #self.options > 0
	end
	v47_:setVisible(v48_)
	self.box:setSize(nil, v45_)
end

function ConversationDialog:onClickOption(canceled, optionIndex)
	if self.inputDelay >= self.time then
		return true
	end
	self:setVisible(false)
	if self.callbackFunc ~= nil then
		if self.callbackTarget == nil then
			self.callbackFunc(canceled, optionIndex, self.callbackArgs)
		else
			self.callbackFunc(self.callbackTarget, canceled, optionIndex, self.callbackArgs)
		end
		self.callbackFunc = nil
		self.callbackTarget = nil
		self.callbackArgs = nil
	end
	return false
end

function ConversationDialog:inputEvent(action, value, eventUsed)
	local v56_ = ConversationDialog:superClass().inputEvent(self, action, value, eventUsed)
	if self:getIsVisible() and not v56_ then
		if action == InputAction.MENU_BACK then
			self:onClickBack()
			return v56_
		end
		if action == InputAction.MENU_ACCEPT and (self.options == nil or #self.options == 0) then
			self:onClickOk()
		end
	end
	return v56_
end

function ConversationDialog:setDuration(duration)
	self.duration = duration
end

function ConversationDialog:setCallback(callbackFunc, callbackTarget, callbackArgs)
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
	self.callbackArgs = callbackArgs
end

function ConversationDialog:onClickOk()
	self:onClickOption(false, 0)
end

function ConversationDialog:onSkip()
	if self.options == nil or #self.options == 0 then
		self:onClickOption(false, 0)
	end
end

function ConversationDialog:onClickBack()
	self:onClickOption(true, nil)
end
