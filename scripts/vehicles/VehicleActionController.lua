-- Local values: VehicleActionController_mt
VehicleActionController = {}
local VehicleActionController_mt = Class(VehicleActionController)
source("dataS/scripts/vehicles/VehicleActionControllerAction.lua")

-- Upvalues: VehicleActionController_mt
-- Local values: self
function VehicleActionController.new(vehicle, customMt)
	-- upvalues: (copy) VehicleActionController_mt
	local v4_ = customMt or VehicleActionController_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	v5_.actions = {}
	v5_.actionsByPrio = {}
	v5_.sortedActions = {}
	v5_.sortedActionsRev = {}
	v5_.currentSequenceActions = {}
	v5_.actionEvents = {}
	v5_.lastDirection = -1
	v5_.pendingControllerReactivation = false
	v5_.loadedNumActions = 0
	return v5_
end

-- Local values: i, _, action, actionKey
function VehicleActionController:saveToXMLFile(xmlFile, key, usedModNames)
	if #self.actions > 0 then
		xmlFile:setValue(key .. "#lastDirection", self.lastDirection)
		xmlFile:setValue(key .. "#numActions", #self.actions)
		local v9_ = 0
		for _, v10_ in ipairs(self.actions) do
			if v10_:getIsSaved() then
				local v11_ = string.format("%s.action(%d)", key, v9_)
				xmlFile:setValue(v11_ .. "#name", v10_.name)
				xmlFile:setValue(v11_ .. "#identifier", v10_.identifier)
				xmlFile:setValue(v11_ .. "#lastDirection", v10_:getLastDirection())
				v9_ = v9_ + 1
			end
		end
	end
end

-- Local values: needsToApply, i, baseKey, action
function VehicleActionController:load(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		self.lastDirection = savegame.xmlFile:getValue(savegame.key .. ".actionController#lastDirection", self.lastDirection)
		self.loadedNumActions = savegame.xmlFile:getValue(savegame.key .. ".actionController#numActions", 0)
		self.loadTime = g_time
		self.loadedActions = {}
		local v14_ = 0
		local v15_ = false
		while true do
			local v16_ = string.format("%s.actionController.action(%d)", savegame.key, v14_)
			if not savegame.xmlFile:hasProperty(v16_) then
				break
			end
			local v17_ = {
				["name"] = savegame.xmlFile:getValue(v16_ .. "#name"),
				["identifier"] = savegame.xmlFile:getValue(v16_ .. "#identifier"),
				["lastDirection"] = savegame.xmlFile:getValue(v16_ .. "#lastDirection")
			}
			v15_ = v17_.lastDirection > 0 and true or v15_
			local v18_ = self.loadedActions
			table.insert(v18_, v17_)
			v14_ = v14_ + 1
		end
		if not v15_ then
			self.loadedNumActions = 0
			self.loadedActions = {}
		end
	end
end

-- Local values: action
function VehicleActionController:registerAction(name, inputAction, prio)
	local v23_ = VehicleActionControllerAction.new(self, name, inputAction, prio)
	self:addAction(v23_)
	return v23_
end

function VehicleActionController:addAction(action)
	local v26_ = self.actions
	table.insert(v26_, action)
	self:updateSortedActions()
	self.actionsDirty = true
	self.vehicle:requestActionEventUpdate()
end

-- Local values: i, v
function VehicleActionController:removeAction(action)
	if Platform.gameplay.automaticVehicleControl and (action:getLastDirection() == 1 and action:getDoResetOnDeactivation()) then
		action:doAction()
	end
	for v29_, v30_ in ipairs(self.actions) do
		if v30_ == action then
			table.remove(self.actions, v29_)
			break
		end
	end
	if #self.actions == 0 then
		self.lastDirection = -1
	end
	self:updateSortedActions()
end

-- Local values: prioToActionTable, _, action, prioTable, sortFunc, sortFuncRev
function VehicleActionController:updateSortedActions()
	self.actionsByPrio = {}
	local v32_ = {}
	for _, v33_ in ipairs(self.actions) do
		if v32_[v33_.priority] == nil then
			local v34_ = { v33_ }
			local v35_ = self.actionsByPrio
			table.insert(v35_, v34_)
			v32_[v33_.priority] = v34_
		else
			local v36_ = v32_[v33_.priority]
			table.insert(v36_, v33_)
		end
	end
	self.sortedActions = table.clone(self.actionsByPrio)
	table.sort(self.sortedActions, function(p37_, p38_)
		return p37_[1].priority > p38_[1].priority
	end)
	self.sortedActionsRev = table.clone(self.actionsByPrio)
	table.sort(self.sortedActionsRev, function(p39_, p40_)
		return p39_[1].priority < p40_[1].priority
	end)
end

function VehicleActionController:activate()
	if self.pendingControllerReactivation then
		if self.vehicle == self.vehicle.rootVehicle then
			self.lastDirection = -self.lastDirection
			self:startActionSequence(true)
		end
		self.pendingControllerReactivation = false
	end
end

function VehicleActionController:deactivate()
	if self.vehicle == self.vehicle.rootVehicle and self.lastDirection > 0 then
		self.pendingControllerReactivation = true
	end
end

-- Local values: _, action, _, actionEventId, _
function VehicleActionController:registerActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if #self.actions > 0 and self.vehicle.rootVehicle == self.vehicle then
		self.vehicle:clearActionEventsTable(self.actionEvents)
		for _, v46_ in ipairs(self.actions) do
			v46_:registerActionEvents(self, self.vehicle, self.actionEvents, isActiveForInput, isActiveForInputIgnoreSelection)
		end
		if self.actionEventId ~= nil then
			g_inputBinding:removeActionEvent(self.actionEventId)
		end
		local _, v47_, _ = g_inputBinding:registerActionEvent(InputAction.VEHICLE_ACTION_CONTROL, self, VehicleActionController.actionSequenceEvent, false, true, false, true)
		self.actionEventId = v47_
	end
end

function VehicleActionController:actionEvent(actionName, inputValue, actionIndex, isAnalog)
	self:doAction(actionIndex)
end

-- Local values: actions, retValue, _, action, success
function VehicleActionController:doAction(actionIndex, customTable, direction)
	local v54_ = self:getActionsByIndex(actionIndex, customTable)
	if v54_ == nil then
		return false
	end
	local v55_ = false
	for _, v56_ in ipairs(v54_) do
		v55_ = v55_ or v56_:doAction(direction)
	end
	return v55_
end

-- Local values: allowed, warning
function VehicleActionController:actionSequenceEvent()
	if self.loadedNumActions == 0 then
		if self.vehicle.getAreControlledActionsAccessible == nil or self.vehicle:getAreControlledActionsAccessible() then
			if self.vehicle.getAreControlledActionsAvailable ~= nil then
				if not self.vehicle:getAreControlledActionsAvailable() then
					return
				end
				local v58_, v59_ = self.vehicle:getAreControlledActionsAllowed()
				if not v58_ then
					if v59_ ~= nil then
						g_currentMission:showBlinkingWarning(v59_, 2500)
					end
					return
				end
			end
			self:startActionSequence()
		end
	else
		return
	end
end

-- Local values: direction, alreadyFinished, _, actions, _, action, finished
function VehicleActionController:startActionSequence(force)
	local v62_ = -self.lastDirection
	self.currentSequenceActions = self.sortedActionsRev
	if v62_ > 0 then
		self.currentSequenceActions = self.sortedActions
	end
	if not force then
		local v63_ = true
		for _, v64_ in ipairs(self.currentSequenceActions) do
			for _, v65_ in ipairs(v64_) do
				local v66_ = v65_.lastValidDirection == v62_
				v63_ = v63_ and v66_
			end
		end
		if v63_ then
			self.lastDirection = v62_
			self:startActionSequence(true)
			return
		end
	end
	if self.currentSequenceIndex == nil then
		self.currentSequenceIndex = 1
		self.currentMaxSequenceIndex = #self.currentSequenceActions
	else
		self.currentSequenceIndex = self.currentMaxSequenceIndex - (self.currentSequenceIndex - 1)
	end
	self.lastDirection = v62_
	if not self:doAction(self.currentSequenceIndex, self.currentSequenceActions, self.lastDirection) then
		if self.currentMaxSequenceIndex == 1 then
			self.lastDirection = -v62_
			self:stopActionSequence()
			return
		end
		self:continueActionSequence()
	end
end

-- Local values: success
function VehicleActionController:continueActionSequence()
	self.currentSequenceIndex = self.currentSequenceIndex + 1
	local v68_ = self:doAction(self.currentSequenceIndex, self.currentSequenceActions, self.lastDirection)
	if self.currentSequenceIndex >= self.currentMaxSequenceIndex then
		self:stopActionSequence()
	elseif not v68_ then
		self:continueActionSequence()
	end
end

function VehicleActionController:stopActionSequence()
	self.currentSequenceActions = nil
	self.currentSequenceIndex = nil
	self.currentMaxSequenceIndex = nil
end

function VehicleActionController:getActionsByIndex(actionIndex, customTable)
	if customTable == nil then
		return self.actionsByPrio[actionIndex]
	else
		return customTable[actionIndex]
	end
end

-- Local values: i
function VehicleActionController:getAreControlledActionsAvailable()
	for v74_ = 1, #self.actions do
		if not self.actions[v74_]:isAvailable() then
			return false
		end
	end
	return #self.actions > 0
end

-- Local values: i
function VehicleActionController:getAreControlledActionsAccessible()
	for v76_ = 1, #self.actions do
		if not self.actions[v76_]:isAccessible() then
			return false
		end
	end
	return #self.actions > 0
end

-- Local values: i, iconPos, iconNeg, changeColor
function VehicleActionController:getControlledActionIcons()
	for v78_ = 1, #self.actions do
		local v79_, v80_, v81_ = self.actions[v78_]:getControlledActionIcons()
		if v79_ ~= nil then
			return v79_, v80_, v81_
		end
	end
	return nil
end

function VehicleActionController:playControlledActions()
	if self.loadedNumActions == 0 then
		self:startActionSequence()
	end
end

function VehicleActionController:resetCurrentState()
	self.lastDirection = -1
end

function VehicleActionController:getActionControllerDirection()
	return -self.lastDirection
end

-- Local values: actions, allFinished, _, action, _, action, isStarted, _, loadedAction, _, actionToCheck, _, action
function VehicleActionController:update(dt)
	if self.currentSequenceIndex ~= nil and self.currentSequenceIndex <= self.currentMaxSequenceIndex then
		local v87_ = self:getActionsByIndex(self.currentSequenceIndex, self.currentSequenceActions)
		if v87_ ~= nil then
			local v88_ = true
			for _, v89_ in ipairs(v87_) do
				if not v89_:getIsFinished(self.lastDirection) then
					v88_ = false
					break
				end
			end
			if v88_ then
				if self.currentSequenceIndex < self.currentMaxSequenceIndex then
					self:continueActionSequence()
				else
					self:stopActionSequence()
				end
			end
		end
	end
	for _, v90_ in ipairs(self.actions) do
		v90_:update(dt)
	end
	if self.loadedNumActions ~= 0 and (self.loadedNumActions == #self.actions and self.loadTime + 500 < g_time) and (self.vehicle.getIsMotorStarted == nil or self.vehicle:getIsMotorStarted()) then
		for _, v91_ in ipairs(self.loadedActions) do
			for _, v92_ in ipairs(self.actions) do
				if v92_.name == v91_.name and (v92_.identifier == v91_.identifier and v92_:getLastDirection() ~= v91_.lastDirection) then
					v92_:doAction()
				end
			end
		end
		self.loadedNumActions = 0
		self.actionsDirty = false
	end
	if self.actionsDirty and self.loadedNumActions == 0 then
		for _, v93_ in ipairs(self.actions) do
			if v93_:getLastDirection() ~= self.lastDirection then
				v93_:doAction()
			end
		end
		self.actionsDirty = nil
	end
end

-- Local values: _, action
function VehicleActionController:updateForAI(dt)
	for _, v96_ in ipairs(self.actions) do
		v96_:updateForAI(dt)
	end
end

-- Local values: _, action
function VehicleActionController:onAIEvent(sourceVehicle, eventName)
	for _, v100_ in ipairs(self.actions) do
		if v100_:getSourceVehicle() == sourceVehicle then
			v100_:onAIEvent(eventName)
		end
	end
end

-- Local values: renderTextVAC, drawActions, directionText
function VehicleActionController:drawDebugRendering()
	local function v_u_107_(p102_, p103_, p104_, p105_, p106_)
		setTextColor(0, 0, 0, 0.75)
		renderText(p102_, p103_ - 0.0015, p104_, p105_)
		setTextColor(unpack(p106_ or {
			1,
			1,
			1,
			1
		}))
		renderText(p102_, p103_, p104_, p105_)
	end
	local function v118_(p108_, p109_, p110_, p111_, p112_)
		-- upvalues: (copy) v_u_107_
		if p109_ ~= nil and #p109_ > 0 then
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_CENTER)
			local v113_ = 0
			for v114_ = #p109_, 1, -1 do
				local v115_ = p109_[v114_]
				setTextBold(p110_ == v114_)
				local v116_ = v114_ < p110_ and {
					0,
					1,
					0,
					1
				} or (v114_ == p110_ and {
					1,
					0.5,
					0,
					1
				} or nil)
				for _, v117_ in ipairs(v115_) do
					v_u_107_(p111_, p112_ + v113_, 0.012, v117_:getDebugText(), v116_)
					v113_ = v113_ + 0.014
				end
				v_u_107_(p111_, p112_ + v113_ + 0.007, 0.012, "__________________________")
				v113_ = v113_ + 0.014
			end
			v_u_107_(p111_, p112_ + v113_ + 0.007, 0.018000000000000002, p108_)
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
	end
	v118_(string.format("Controlled Actions (%s)", self.lastDirection == 1 and "On" or "Off"), self.sortedActions, -1, 0.2, 0.3)
	local v119_ = self.lastDirection == 1 and "TurnOn" or "TurnOff"
	v118_(string.format("Current Action Sequence (%s)", v119_), self.currentSequenceActions, self.currentSequenceIndex, 0.4, 0.3)
end

function VehicleActionController.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#lastDirection", "Last action controller direction")
	schema:register(XMLValueType.INT, basePath .. "#numActions", "Action controller actions")
	schema:register(XMLValueType.STRING, basePath .. ".action(?)#name", "Action name")
	schema:register(XMLValueType.STRING, basePath .. ".action(?)#identifier", "Action identifier")
	schema:register(XMLValueType.INT, basePath .. ".action(?)#lastDirection", "Last action direction")
end
