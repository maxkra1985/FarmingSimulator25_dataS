-- Local values: YarderTowerSetupActivatable_mt
YarderTowerSetupActivatable = {}
local YarderTowerSetupActivatable_mt = Class(YarderTowerSetupActivatable)

-- Upvalues: YarderTowerSetupActivatable_mt
-- Local values: self
function YarderTowerSetupActivatable.new(vehicle)
	-- upvalues: (copy) YarderTowerSetupActivatable_mt
	local v3_ = {}
	local v4_ = YarderTowerSetupActivatable_mt
	setmetatable(v3_, v4_)
	v3_.vehicle = vehicle
	v3_.activateText = ""
	return v3_
end

-- Local values: _
function YarderTowerSetupActivatable:registerCustomInput(inputContext)
	local _, v6_ = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_OBJECT, self, self.onToggleSetupMode, false, true, false, true)
	self.actionEventIdToggle = v6_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdToggle, GS_PRIO_VERY_HIGH)
	local _, v7_ = g_inputBinding:registerActionEvent(InputAction.YARDER_SETUP_ROPE, self, self.onSetTarget, false, true, false, true)
	self.actionEventIdSetTarget = v7_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdSetTarget, GS_PRIO_VERY_HIGH)
	self:updateActionEventTexts()
end

function YarderTowerSetupActivatable:removeCustomInput(inputContext)
	g_inputBinding:removeActionEventsByTarget(self)
end

-- Local values: spec, isAllowed, warning
function YarderTowerSetupActivatable:onToggleSetupMode()
	if self.vehicle.spec_yarderTower.mainRope.isActive then
		self.vehicle:setYarderTargetActive(false)
		return
	else
		local v10_, v11_ = self.vehicle:getIsSetupModeChangeAllowed()
		if v10_ then
			self.vehicle:setYarderSetupModeState(nil, true)
		elseif v11_ ~= nil then
			g_currentMission:showBlinkingWarning(v11_, 2000)
		end
	end
end

function YarderTowerSetupActivatable:onSetTarget()
	self.vehicle:setYarderTargetActive(true)
end

-- Local values: spec, setTargetIsActive
function YarderTowerSetupActivatable:updateActionEventTexts()
	local v14_ = self.vehicle.spec_yarderTower
	local v15_
	if v14_.setupModeState then
		v15_ = v14_.mainRope.isValid
		g_inputBinding:setActionEventText(self.actionEventIdToggle, v14_.texts.actionCancelSetup)
		g_inputBinding:setActionEventText(self.actionEventIdSetTarget, v14_.texts.actionSetTargetTree)
	else
		v15_ = false
		if v14_.mainRope.isActive then
			g_inputBinding:setActionEventText(self.actionEventIdToggle, v14_.texts.actionRemoveYarder)
		else
			g_inputBinding:setActionEventText(self.actionEventIdToggle, v14_.texts.actionStartSetup)
		end
	end
	g_inputBinding:setActionEventActive(self.actionEventIdSetTarget, v15_)
end

function YarderTowerSetupActivatable:getIsActivatable()
	return self.vehicle:getIsPlayerInYarderRange()
end

function YarderTowerSetupActivatable:activate() end

function YarderTowerSetupActivatable:deactivate() end

-- Local values: tx, ty, tz
function YarderTowerSetupActivatable:getDistance(x, y, z)
	if self.vehicle.spec_yarderTower.controlTriggerNode == nil then
		return math.huge
	end
	local v21_, v22_, v23_ = getWorldTranslation(self.vehicle.spec_yarderTower.controlTriggerNode)
	return MathUtil.vector3Length(x - v21_, y - v22_, z - v23_)
end

function YarderTowerSetupActivatable:draw() end
