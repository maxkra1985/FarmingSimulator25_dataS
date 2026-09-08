-- Local values: WinchControlRopeActivatable_mt
WinchControlRopeActivatable = {}
WinchControlRopeActivatable.SUB_ATTACH_ADDITIONAL_RANGE = 2
local WinchControlRopeActivatable_mt = Class(WinchControlRopeActivatable)

-- Upvalues: WinchControlRopeActivatable_mt
-- Local values: self
function WinchControlRopeActivatable.new(vehicle, rope)
	-- upvalues: (copy) WinchControlRopeActivatable_mt
	local v4_ = {}
	local v5_ = WinchControlRopeActivatable_mt
	setmetatable(v4_, v5_)
	v4_.vehicle = vehicle
	v4_.texts = vehicle.spec_winch.texts
	v4_.ropes = vehicle.spec_winch.ropes
	v4_.rope = rope
	v4_.activateText = ""
	return v4_
end

-- Local values: _
function WinchControlRopeActivatable:registerCustomInput(inputContext)
	local _, v7_ = g_inputBinding:registerActionEvent(InputAction.WINCH_CONTROL, self, self.onControlWinch, false, true, true, true)
	self.actionEventIdControl = v7_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdControl, GS_PRIO_VERY_HIGH)
	g_inputBinding:setActionEventText(self.actionEventIdControl, self.texts.control)
	local _, v8_ = g_inputBinding:registerActionEvent(InputAction.WINCH_DETACH, self, self.onDetachTree, false, true, false, true)
	self.actionEventIdDetachTree = v8_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdDetachTree, GS_PRIO_VERY_HIGH)
	g_inputBinding:setActionEventText(self.actionEventIdDetachTree, self.texts.detachTree)
	local _, v9_ = g_inputBinding:registerActionEvent(InputAction.WINCH_ATTACH_MODE, self, self.onAttachMode, false, true, false, true)
	self.actionEventIdAttachMode = v9_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdAttachMode, GS_PRIO_VERY_HIGH)
	g_inputBinding:setActionEventText(self.actionEventIdAttachMode, self.texts.attachAnotherTree)
end

function WinchControlRopeActivatable:removeCustomInput(inputContext)
	g_inputBinding:removeActionEventsByTarget(self)
end

function WinchControlRopeActivatable:onControlWinch(actionName, inputValue, callbackState, isAnalog)
	self.vehicle:setWinchControlInput(self.rope.index, inputValue)
end

function WinchControlRopeActivatable:onDetachTree(actionName, inputValue, callbackState, isAnalog)
	self.vehicle:detachTreeFromWinch(self.rope.index)
end

function WinchControlRopeActivatable:onAttachMode(actionName, inputValue, callbackState, isAnalog)
	if #self.rope.attachedTrees < self.rope.maxNumTrees then
		self.vehicle:setWinchTreeAttachMode(self.rope)
	else
		g_currentMission:showBlinkingWarning(self.texts.warningMaxNumTreesReached, 2500)
	end
end

-- Local values: x1, _, z1, x2, _, z2, distance
function WinchControlRopeActivatable:update(dt)
	if g_localPlayer ~= nil then
		local v16_, _, v17_ = getWorldTranslation(g_localPlayer.rootNode)
		local v18_, _, v19_ = getWorldTranslation(self.rope.attachedTrees[1].activeHookData.hookId)
		local v20_ = MathUtil.vector2Length(v16_ - v18_, v17_ - v19_)
		g_inputBinding:setActionEventActive(self.actionEventIdAttachMode, v20_ < self.rope.maxSubLength + WinchControlRopeActivatable.SUB_ATTACH_ADDITIONAL_RANGE)
	end
end

-- Local values: i, player, distance
function WinchControlRopeActivatable:getIsActivatable()
	if self.vehicle:getOwnerFarmId() ~= g_currentMission:getFarmId() then
		return false
	end
	for v22_ = 1, #self.ropes do
		if self.rope ~= self.ropes[v22_] and self.ropes[v22_].isPlayerInRange then
			return false
		end
		if self.ropes[v22_].isAttachModeActive then
			return false
		end
	end
	local v23_ = g_localPlayer
	return v23_ ~= nil and (v23_.currentHandtool == nil and (v23_.isControlled and self:getDistance(getWorldTranslation(v23_.rootNode)) < Winch.CONTROL_RANGE)) and true or false
end

function WinchControlRopeActivatable:activate() end

function WinchControlRopeActivatable:deactivate() end

-- Local values: i, x1, _, z1, hookId, x2, _, z2, tx, _, tz
function WinchControlRopeActivatable:getDistance(x, y, z)
	for v27_ = 1, #self.ropes do
		if self.rope ~= self.ropes[v27_] and self.ropes[v27_].isPlayerInRange then
			return math.huge
		end
		if self.ropes[v27_].isAttachModeActive then
			return math.huge
		end
	end
	if #self.rope.attachedTrees == 0 then
		return math.huge
	end
	local v28_, _, v29_ = getWorldTranslation(self.rope.ropeNode)
	local v30_ = self.rope.attachedTrees[1].activeHookData.hookId
	if not entityExists(v30_) then
		return math.huge
	end
	local v31_, _, v32_ = getWorldTranslation(v30_)
	local v33_, _, v34_ = MathUtil.getClosestPointOnLineSegment(v28_, 0, v29_, v31_, 0, v32_, x, 0, z)
	return MathUtil.vector2Length(x - v33_, z - v34_)
end

function WinchControlRopeActivatable:draw() end
