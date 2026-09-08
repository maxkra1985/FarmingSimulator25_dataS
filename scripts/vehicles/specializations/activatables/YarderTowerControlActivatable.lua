-- Local values: YarderTowerControlActivatable_mt
YarderTowerControlActivatable = {}
local YarderTowerControlActivatable_mt = Class(YarderTowerControlActivatable)

-- Upvalues: YarderTowerControlActivatable_mt
-- Local values: self
function YarderTowerControlActivatable.new(vehicle)
	-- upvalues: (copy) YarderTowerControlActivatable_mt
	local v3_ = {}
	local v4_ = YarderTowerControlActivatable_mt
	setmetatable(v3_, v4_)
	v3_.vehicle = vehicle
	v3_.activateText = ""
	return v3_
end

-- Local values: _
function YarderTowerControlActivatable:registerCustomInput(inputContext)
	local _, v6_ = g_inputBinding:registerActionEvent(InputAction.YARDER_FOLLOW_ME, self, self.onToggleFollowMeMode, false, true, false, true)
	self.actionEventIdFollowMe = v6_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdFollowMe, GS_PRIO_VERY_HIGH)
	local _, v7_ = g_inputBinding:registerActionEvent(InputAction.YARDER_FOLLOW_HOME, self, self.onToggleFollowHome, false, true, false, true)
	self.actionEventIdFollowHome = v7_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdFollowHome, GS_PRIO_VERY_HIGH)
	local _, v8_ = g_inputBinding:registerActionEvent(InputAction.YARDER_FOLLOW_PICKUP, self, self.onToggleFollowPickup, false, true, false, true)
	self.actionEventIdFollowPickup = v8_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdFollowPickup, GS_PRIO_VERY_HIGH)
	local _, v9_ = g_inputBinding:registerActionEvent(InputAction.YARDER_CONTROL_LEFTRIGHT, self, self.onManualControlLeftRight, false, false, true, true)
	self.actionEventIdManualControl = v9_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdManualControl, GS_PRIO_VERY_HIGH)
	g_inputBinding:setActionEventText(self.actionEventIdManualControl, self.vehicle.spec_yarderTower.texts.actionCarriageManualControl)
	local _, v10_ = g_inputBinding:registerActionEvent(InputAction.YARDER_CONTROL_UPDOWN, self, self.onManualControlUpDown, false, false, true, true)
	self.actionEventIdLiftLower = v10_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdLiftLower, GS_PRIO_VERY_HIGH)
	g_inputBinding:setActionEventText(self.actionEventIdLiftLower, self.vehicle.spec_yarderTower.texts.actionCarriageLiftLower)
	local _, v11_ = g_inputBinding:registerActionEvent(InputAction.YARDER_ATTACH, self, self.onTreeAttach, false, true, false, true)
	self.actionEventIdAttach = v11_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdAttach, GS_PRIO_VERY_HIGH)
	g_inputBinding:setActionEventText(self.actionEventIdAttach, self.vehicle.spec_yarderTower.texts.actionCarriageAttachTree)
	local _, v12_ = g_inputBinding:registerActionEvent(InputAction.YARDER_DETACH, self, self.onTreeDetach, false, true, false, true)
	self.actionEventIdDetach = v12_
	g_inputBinding:setActionEventTextPriority(self.actionEventIdDetach, GS_PRIO_VERY_HIGH)
	g_inputBinding:setActionEventText(self.actionEventIdDetach, self.vehicle.spec_yarderTower.texts.actionCarriageDetachTree)
	self:updateActionEventTexts()
end

function YarderTowerControlActivatable:removeCustomInput(inputContext)
	g_inputBinding:removeActionEventsByTarget(self)
end

-- Local values: spec
function YarderTowerControlActivatable:onToggleFollowMeMode()
	if self.vehicle.spec_yarderTower.carriage.followModeState == YarderTower.FOLLOW_MODE_ME then
		self.vehicle:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_NONE)
	else
		self.vehicle:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_ME)
	end
end

function YarderTowerControlActivatable:onToggleFollowHome()
	self.vehicle:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_HOME)
end

function YarderTowerControlActivatable:onToggleFollowPickup()
	self.vehicle:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_PICKUP)
end

function YarderTowerControlActivatable:onManualControlLeftRight(actionName, inputValue, callbackState, isAnalog, isMouse)
	self.vehicle:setYarderCarriageMoveInput(inputValue)
end

function YarderTowerControlActivatable:onManualControlUpDown(actionName, inputValue, callbackState, isAnalog, isMouse)
	self.vehicle:setYarderCarriageLiftInput(inputValue)
end

function YarderTowerControlActivatable:onTreeAttach(actionName, inputValue, callbackState, isAnalog, isMouse)
	self.vehicle:onYarderCarriageAttach()
end

function YarderTowerControlActivatable:onTreeDetach(actionName, inputValue, callbackState, isAnalog, isMouse)
	self.vehicle:onYarderCarriageDetach(inputValue)
end

-- Local values: carriage, treesAttached
function YarderTowerControlActivatable:update(dt)
	local v25_ = self.vehicle.spec_yarderTower.carriage.vehicle
	if v25_ ~= nil then
		g_inputBinding:setActionEventActive(self.actionEventIdAttach, v25_:getIsTreeInMountRange())
		local v26_ = v25_:getNumAttachedTrees() > 0
		g_inputBinding:setActionEventActive(self.actionEventIdDetach, v26_)
		g_inputBinding:setActionEventActive(self.actionEventIdLiftLower, v26_)
	end
end

-- Local values: spec, ropeLength, offset
function YarderTowerControlActivatable:updateActionEventTexts()
	local v28_ = self.vehicle.spec_yarderTower
	local v29_ = self.vehicle:getYarderMainRopeLength()
	g_inputBinding:setActionEventText(self.actionEventIdFollowMe, v28_.carriage.followModeState == YarderTower.FOLLOW_MODE_ME and v28_.texts.actionCarriageFollowModeDisable or v28_.texts.actionCarriageFollowModeEnable)
	if v28_.carriage.followModeState == YarderTower.FOLLOW_MODE_NONE then
		g_inputBinding:setActionEventActive(self.actionEventIdFollowHome, v28_.carriage.lastPosition * v29_ > 5)
		if v28_.carriage.followModePickupPosition == 0 then
			g_inputBinding:setActionEventActive(self.actionEventIdFollowPickup, false)
		else
			local v30_ = v28_.carriage.lastPosition - v28_.carriage.followModePickupPosition
			local v31_ = math.abs(v30_) * v29_
			g_inputBinding:setActionEventActive(self.actionEventIdFollowPickup, v31_ > 5)
		end
	else
		g_inputBinding:setActionEventActive(self.actionEventIdFollowHome, false)
		g_inputBinding:setActionEventActive(self.actionEventIdFollowPickup, false)
		return
	end
end

-- Local values: isInRange, _
function YarderTowerControlActivatable:getIsActivatable()
	local v33_, _ = self.vehicle:getIsPlayerInYarderControlRange()
	return v33_
end

function YarderTowerControlActivatable:activate() end

function YarderTowerControlActivatable:deactivate() end

-- Local values: _, distance
function YarderTowerControlActivatable:getDistance(x, y, z)
	local _, v35_ = self.vehicle:getIsPlayerInYarderControlRange()
	return v35_
end

function YarderTowerControlActivatable:draw() end
