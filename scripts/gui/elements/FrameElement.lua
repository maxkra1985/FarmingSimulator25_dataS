-- Local values: FrameElement_mt, NO_CALLBACK
FrameElement = {}
local FrameElement_mt = Class(FrameElement, GuiElement)
local function NO_CALLBACK() end

-- Upvalues: FrameElement_mt, NO_CALLBACK
-- Local values: self
function FrameElement.new(target, customMt)
	-- upvalues: (copy) FrameElement_mt, (copy) NO_CALLBACK
	local v5_ = GuiElement.new(target, customMt or FrameElement_mt)
	v5_.controlIDs = {}
	v5_.changeScreenCallback = NO_CALLBACK
	v5_.toggleCustomInputContextCallback = NO_CALLBACK
	v5_.playSampleCallback = NO_CALLBACK
	v5_.hasCustomInputContext = false
	v5_.time = 0
	v5_.inputDisableTime = 0
	v5_.playHoverSoundOnFocus = false
	return v5_
end

-- Local values: ret
function FrameElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	local v11_ = FrameElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	v11_:exposeControlsAsFields(self.name)
	v11_.changeScreenCallback = self.changeScreenCallback
	v11_.toggleCustomInputContextCallback = self.toggleCustomInputContextCallback
	v11_.playSampleCallback = self.playSampleCallback
	v11_.hasCustomInputContext = self.hasCustomInputContext
	return v11_
end

-- Local values: k, _
function FrameElement:copyAttributes(src)
	FrameElement:superClass().copyAttributes(self, src)
	for v14_, _ in pairs(src.controlIDs) do
		self.controlIDs[v14_] = false
	end
end

-- Local values: k, _
function FrameElement:delete()
	FrameElement:superClass().delete(self)
	for v16_, _ in pairs(self.controlIDs) do
		self.controlIDs[v16_] = nil
		self[v16_] = nil
	end
end

-- Local values: newRoot
function FrameElement:getRootElement()
	if #self.elements > 0 then
		return self.elements[1]
	end
	local v18_ = GuiElement.new()
	self:addElement(v18_)
	return v18_
end

-- Local values: allChildren, _, element, index, varName, id, isResolved
function FrameElement:exposeControlsAsFields(viewName)
	local v21_ = self:getDescendants()
	for _, v22_ in pairs(v21_) do
		if v22_.id and v22_.id ~= "" then
			local v23_, v24_ = GuiElement.extractIndexAndNameFromID(v22_.id)
			if v23_ then
				if not self[v24_] then
					self[v24_] = {}
				end
				self[v24_][v23_] = v22_
			else
				self[v24_] = v22_
			end
			self.controlIDs[v24_] = true
		end
	end
	if self.debugEnabled or g_uiDebugEnabled then
		for v25_, v26_ in pairs(self.controlIDs) do
			if not v26_ then
				Logging.warning("FrameElement for GUI view \'%s\' could not resolve registered control element ID \'%s\'. Check configuration.", tostring(viewName), (tostring(v25_)))
			end
		end
	end
end

function FrameElement:disableInputForDuration(duration)
	self.inputDisableTime = math.clamp(duration, 0, 10000)
end

function FrameElement:isInputDisabled()
	return self.inputDisableTime > 0
end

function FrameElement:update(dt)
	FrameElement:superClass().update(self, dt)
	self.time = self.time + dt
	if self.inputDisableTime > 0 then
		self.inputDisableTime = self.inputDisableTime - dt
	end
end

-- Upvalues: NO_CALLBACK
function FrameElement:setChangeScreenCallback(callback)
	-- upvalues: (copy) NO_CALLBACK
	self.changeScreenCallback = callback or NO_CALLBACK
end

-- Upvalues: NO_CALLBACK
function FrameElement:setInputContextCallback(callback)
	-- upvalues: (copy) NO_CALLBACK
	self.toggleCustomInputContextCallback = callback or NO_CALLBACK
end

-- Upvalues: NO_CALLBACK
function FrameElement:setPlaySampleCallback(callback)
	-- upvalues: (copy) NO_CALLBACK
	self.playSampleCallback = callback or NO_CALLBACK
end

function FrameElement:changeScreen(targetScreenClass, returnScreenClass)
	self.changeScreenCallback(self, targetScreenClass, returnScreenClass)
end

function FrameElement:toggleCustomInputContext(isContextActive, contextName)
	if self.hasCustomInputContext and not isContextActive or not self.hasCustomInputContext and isContextActive then
		self.toggleCustomInputContextCallback(isContextActive, contextName)
		self.hasCustomInputContext = isContextActive
	end
end

function FrameElement:playSample(sampleName)
	if not self:getSoundSuppressed() then
		self.playSampleCallback(sampleName)
	end
end
