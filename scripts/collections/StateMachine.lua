-- Local values: StateMachine_mt
StateMachine = {}
local StateMachine_mt = Class(StateMachine)
StateMachine.STATE_INDEX_NUM_BITS = 5

-- Upvalues: StateMachine_mt
-- Local values: self
function StateMachine.new(custom_mt)
	-- upvalues: (copy) StateMachine_mt
	local v3_ = custom_mt or StateMachine_mt
	local v4_ = setmetatable({}, v3_)
	v4_.currentState = nil
	v4_.defaultState = nil
	v4_.isPassive = false
	v4_.states = {}
	v4_.sortedStates = nil
	return v4_
end

function StateMachine:delete()
	if self.currentState ~= nil then
		self.currentState:onStateExited(nil)
	end
end

-- Local values: stateName, state
function StateMachine:createStateIndexNameMapping(isForced)
	if isForced or not self:getHasMappings() then
		self.sortedStates = {}
		for _, v8_ in pairs(self.states) do
			if string.isNilOrWhitespace(v8_.name) then
				self:initialiseStateNames()
			end
			local v9_ = self.sortedStates
			table.insert(v9_, v8_)
		end
		table.sort(self.sortedStates, function(p10_, p11_)
			return p10_.name < p11_.name
		end)
	end
end

-- Local values: name, value
function StateMachine:implementStateInterface()
	for v13_, v14_ in pairs(BaseStateMachineState) do
		if not self[v13_] then
			self[v13_] = v14_
		end
	end
end
function StateMachine.changeState(p15_, p16_, ...)
	local v17_ = p15_.currentState
	p15_.currentState = p16_
	v17_:onStateExited(p16_)
	p16_:onStateEntered(v17_, ...)
end

-- Local values: stateName, state
function StateMachine:initialiseStateNames()
	for v19_, v20_ in pairs(self.states) do
		if string.isNilOrWhitespace(v20_.name) then
			v20_.name = v19_
		end
	end
end
function StateMachine.initialiseStateTransitions(p21_, ...)
	for _, v22_ in pairs(p21_.states) do
		v22_:createTransitions(...)
	end
end

-- Local values: _, state
function StateMachine:determineState()
	for _, v24_ in pairs(self.states) do
		if v24_:calculateIfValidEntryState() then
			self:changeState(v24_)
			return
		end
	end
	self:changeState(self.defaultState)
end

function StateMachine:resolveCurrentState()
	return self.currentState.resolveCurrentState ~= nil and self.currentState:resolveCurrentState() or self.currentState
end

function StateMachine:getCurrentStateName()
	return self:getNameOfState(self.currentState)
end

function StateMachine:getNameOfState(state)
	if state == nil then
		return "No state"
	end
	if string.isNilOrWhitespace(state.name) then
		self:initialiseStateNames()
	end
	return state.name
end

function StateMachine:getCurrentStateIndex()
	return self:getIndexOfState(self.currentState)
end

-- Local values: i, otherState
function StateMachine:getIndexOfState(state)
	if not self:getHasMappings() then
		self:createStateIndexNameMapping()
	end
	for v32_, v33_ in ipairs(self.sortedStates) do
		if v33_ == state then
			return v32_
		end
	end
	return nil
end

-- Local values: state
function StateMachine:getStateByIndex(index)
	if not self:getHasMappings() then
		self:createStateIndexNameMapping()
	end
	return self.sortedStates[index]
end

function StateMachine:getHasMappings()
	return self.sortedStates ~= nil
end

function StateMachine:getIsPassive()
	return self.isPassive
end

function StateMachine:setIsPassive(isPassive)
	self.isPassive = isPassive == true
end

-- Local values: _, state, _, state
function StateMachine:update(dt)
	if not self:getIsPassive() then
		for _, v42_ in pairs(self.states) do
			if v42_:calculateIfShouldBeForced() and v42_ ~= self.currentState then
				self:changeState(v42_)
				break
			end
		end
	end
	for _, v43_ in pairs(self.states) do
		if v43_ == self.currentState then
			v43_:updateAsCurrent(dt)
		else
			v43_:updateAsInactive(dt)
		end
	end
end
function StateMachine.callStateFunction(p44_, p45_, ...)
	for _, v46_ in pairs(p44_.states) do
		if v46_[p45_] ~= nil then
			v46_[p45_](v46_, ...)
		end
	end
end
