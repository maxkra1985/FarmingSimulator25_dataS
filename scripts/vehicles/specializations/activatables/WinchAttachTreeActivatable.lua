WinchAttachTreeActivatable = {}
local WinchAttachTreeActivatable_mt = Class(WinchAttachTreeActivatable)
function WinchAttachTreeActivatable.new(vehicle, rope)
	local self = {}
	setmetatable(self, WinchAttachTreeActivatable_mt)
	self.vehicle = vehicle
	self.texts = vehicle.spec_winch.texts
	self.ropes = vehicle.spec_winch.ropes
	self.rope = rope
	self.activateText = ""
	return self
end
function WinchAttachTreeActivatable:registerCustomInput(inputContext)
	local _ = nil
	_, self.actionEventIdToggle = g_inputBinding:registerActionEvent(InputAction.WINCH_ATTACH_MODE, self, self.onToggleAttachTreeMode, false, true, false, true)
	g_inputBinding:setActionEventTextPriority(self.actionEventIdToggle, GS_PRIO_VERY_HIGH)
	_, self.actionEventIdAttachTree = g_inputBinding:registerActionEvent(InputAction.WINCH_ATTACH, self, self.onAttachTree, false, true, false, true)
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
function WinchAttachTreeActivatable:getIsActivatable()
	if self.vehicle:getOwnerFarmId() ~= g_currentMission:getFarmId() then
		return false
	elseif self.rope.maxNumTrees <= #self.rope.attachedTrees then
		return false
	else
		for i = 1, #self.ropes do
			if self.ropes[i] == self.rope then
				continue
			end
			if self.ropes[i].isAttachModeActive then
				return false
			end
		end
		return true
	end
end
function WinchAttachTreeActivatable:activate() end
function WinchAttachTreeActivatable:deactivate() end
function WinchAttachTreeActivatable:getDistance(x, y, z)
	if self.rope.isAttachModeActive then
		return 0
	else
		local tx, ty, tz = getWorldTranslation(self.rope.ropeNode)
		return MathUtil.vector3Length(x - tx, y - ty, z - tz)
	end
end
function WinchAttachTreeActivatable:draw() end
