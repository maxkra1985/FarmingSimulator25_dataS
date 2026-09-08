-- Local values: ScreenElement_mt
ScreenElement = {}
local ScreenElement_mt = Class(ScreenElement, FrameElement)

-- Upvalues: ScreenElement_mt
-- Local values: self
function ScreenElement.new(target, custom_mt)
	-- upvalues: (copy) ScreenElement_mt
	local v4_ = FrameElement.new(target, custom_mt or ScreenElement_mt)
	v4_.isBackAllowed = true
	v4_.handleCursorVisibility = true
	v4_.returnScreenClass = nil
	v4_.isOpen = false
	v4_.lastMouseCursorState = false
	v4_.isInitialized = false
	v4_.nextClickSoundMuted = false
	return v4_
end

function ScreenElement:onOpen()
	if not self.isInitialized then
		self:initializeScreen()
	end
	self.lastMouseCursorState = g_inputBinding:getShowMouseCursor()
	g_inputBinding:setShowMouseCursor(true)
	self.isOpen = true
end

function ScreenElement:initializeScreen()
	self.isInitialized = true
	if self.pageSelector ~= nil and self.pageSelector.disableButtonSounds ~= nil then
		self.pageSelector:disableButtonSounds()
	end
end

function ScreenElement:onClose()
	if self.handleCursorVisibility then
		g_inputBinding:setShowMouseCursor(self.lastMouseCursorState)
	end
	self.isOpen = false
end

function ScreenElement:onClickOk()
	return true
end

function ScreenElement:onClickActivate()
	return true
end

function ScreenElement:onClickCancel()
	return true
end

function ScreenElement:onClickMenuExtra1()
	return true
end

function ScreenElement:onClickMenuExtra2()
	return true
end

function ScreenElement:onClickMenu()
	return true
end

function ScreenElement:onClickShop()
	return true
end

function ScreenElement:onPagePrevious()
	self.pageSelector:inputLeft(true, nil, true)
end

function ScreenElement:onPageNext()
	self.pageSelector:inputRight(true, nil, true)
end

-- Local values: eventUnused
function ScreenElement:onClickBack(forceBack, usedMenuButton)
	local v12_
	if (self.isBackAllowed or forceBack) and self.returnScreenClass ~= nil then
		self:changeScreen(self.returnScreenClass)
		v12_ = false
	else
		v12_ = true
	end
	return v12_
end

function ScreenElement:onBackAction()
	return self:onClickBack()
end

function ScreenElement:invalidateScreen() end

-- Local values: i, element
function ScreenElement.callButtonsWithAction(list, action)
	for v16_ = 1, #list do
		local v17_ = list[v16_]
		if v17_:isa(ButtonElement) and (v17_.isTriggerableByGlobalAction and (v17_:getIsActive() and v17_.inputActionName == action)) then
			v17_:sendAction()
			return true
		end
		if ScreenElement.callButtonsWithAction(v17_.elements, action) then
			return true
		end
	end
	return false
end

-- Local values: focusElement, nameAction
function ScreenElement:inputEvent(action, value, eventUsed)
	local v22_ = ScreenElement:superClass().inputEvent(self, action, value, eventUsed)
	if self.inputDisableTime <= 0 then
		if self.pageSelector ~= nil and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
			if action == InputAction.MENU_PAGE_PREV then
				self:onPagePrevious()
				v22_ = true
			elseif action == InputAction.MENU_PAGE_NEXT then
				self:onPageNext()
				v22_ = true
			else
				v22_ = true
			end
		end
		if not v22_ then
			local v23_ = FocusManager:getFocusedElement()
			local v24_ = g_inputBinding.nameActions[action]
			if v23_ ~= nil and v24_:getNumActiveBindings() > 0 then
				if action == InputAction.MENU_LIST_PAGE_START then
					if v23_.scrollToStart ~= nil then
						v23_:scrollToStart()
						v22_ = true
					end
				elseif action == InputAction.MENU_LIST_PAGE_END and v23_.scrollToEnd ~= nil then
					v23_:scrollToEnd()
					v22_ = true
				end
				if action == InputAction.MENU_LIST_PAGE_PREV then
					if v23_.scrollToPrevPage ~= nil then
						v23_:scrollToPrevPage()
						v22_ = true
					end
				elseif action == InputAction.MENU_LIST_PAGE_NEXT and v23_.scrollToNextPage ~= nil then
					v23_:scrollToNextPage()
					v22_ = true
				end
				if action == InputAction.MENU_LIST_PAGE_START_GAMEPAD then
					if v23_.scrollToStartGamepad ~= nil then
						v23_:scrollToStartGamepad()
						v22_ = true
					end
				elseif action == InputAction.MENU_LIST_PAGE_END_GAMEPAD and v23_.scrollToEndGamepad ~= nil then
					v23_:scrollToEndGamepad()
					v22_ = true
				end
			end
		end
		v22_ = v22_ or ScreenElement.callButtonsWithAction(self.elements, action)
	end
	return v22_
end

function ScreenElement:inputReleaseEvent(action, value, eventUsed)
	local v29_ = ScreenElement:superClass().inputReleaseEvent(self, action, value, eventUsed)
	if self.pageSelector == nil or action ~= InputAction.MENU_PAGE_PREV and action ~= InputAction.MENU_PAGE_NEXT then
		return v29_
	end
	self.pageSelector.leftDelayTime = 0
	self.pageSelector.rightDelayTime = 0
	return true
end

function ScreenElement:setReturnScreenClass(returnScreenClass)
	self.returnScreenClass = returnScreenClass
end

function ScreenElement:getIsOpen()
	return self.isOpen
end

-- Local values: i
function ScreenElement:canReceiveFocus()
	if not self.visible then
		return false
	end
	for v34_ = 1, #self.elements do
		if not self.elements[v34_]:canReceiveFocus() then
			return false
		end
	end
	return true
end

function ScreenElement:setNextScreenClickSoundMuted(value)
	self.nextClickSoundMuted = value == nil and true or value
end
