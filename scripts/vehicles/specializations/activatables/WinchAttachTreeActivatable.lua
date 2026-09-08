-- Local values: WinchAttachTreeActivatable_mt
WinchAttachTreeActivatable = {}
local WinchAttachTreeActivatable_mt = Class(WinchAttachTreeActivatable)

-- Upvalues: WinchAttachTreeActivatable_mt
-- Local values: self
function WinchAttachTreeActivatable.new(vehicle, rope)
	-- upvalues: (copy) WinchAttachTreeActivatable_mt
	local v4_ = {}
	local v5_ = WinchAttachTreeActivatable_mt
	setmetatable(v4_, v5_)
	v4_.vehicle = vehicle
	v4_.texts = vehicle.spec_winch.texts
	v4_.ropes = vehicle.spec_winch.ropes
	v4_.rope = rope
	v4_.activateText = ""
	return v4_
end

-- Local values: _
function WinchAttachTreeActivatable:registerCustomInput(inputContext)
	local _, v7_ = g_inputBinding:registerActionEvent(InputAction.WINCH_ATTACH_MODE, self, self.onToggleAttachTreeMode, false, true, false, true)
	self.actionEventIdToggle = v7_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdToggle, GS_PRIO_VERY_HIGH)
	local _, v8_ = g_inputBinding:registerActionEvent(InputAction.WINCH_ATTACH, self, self.onAttachTree, false, true, false, true)
	self.actionEventIdAttachTree = v8_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdAttachTree, GS_PRIO_VERY_HIGH)
	g_inputBinding:setActionEventText(self.actionEventIdAttachTree, self.texts.attachTree)
	self:update(9999)
end

function WinchAttachTreeActivatable:removeCustomInput(inputContext)
	g_inputBinding:removeActionEventsByTarget(self)
end

function WinchAttachTreeActivatable:onToggleAttachTreeMode()
	self.vehicle:setWinchTreeAttachMode(self.rope)
end

function WinchAttachTreeActivatable:onAttachTree()
	if self.vehicle:getCanAttachWinchTree(self.rope) then
		self.vehicle:onAttachTreeInputEvent(self.rope)
	end
end

function WinchAttachTreeActivatable:update(dt)
	g_inputBinding:setActionEventText(self.actionEventIdToggle, self.vehicle:getIsWinchAttachModeActive(self.rope) and self.texts.stopAttachMode or self.texts.startAttachMode)
	g_inputBinding:setActionEventActive(self.actionEventIdAttachTree, self.vehicle:getCanAttachWinchTree(self.rope))
end

-- Local values: i
function WinchAttachTreeActivatable:getIsActivatable()
	if self.vehicle:getOwnerFarmId() ~= g_currentMission:getFarmId() then
		return false
	end
	if #self.rope.attachedTrees >= self.rope.maxNumTrees then
		return false
	end
	for v14_ = 1, #self.ropes do
		if self.ropes[v14_] ~= self.rope and self.ropes[v14_].isAttachModeActive then
			return false
		end
	end
	return true
end

function WinchAttachTreeActivatable:activate() end

function WinchAttachTreeActivatable:deactivate() end

-- Local values: tx, ty, tz
function WinchAttachTreeActivatable:getDistance(x, y, z)
	if self.rope.isAttachModeActive then
		return 0
	end
	local v19_, v20_, v21_ = getWorldTranslation(self.rope.ropeNode)
	return MathUtil.vector3Length(x - v19_, y - v20_, z - v21_)
end

function WinchAttachTreeActivatable:draw() end
