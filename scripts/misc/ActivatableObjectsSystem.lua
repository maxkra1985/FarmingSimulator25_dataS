-- Local values: ActivatableObjectsSystem_mt
ActivatableObjectsSystem = {}
local ActivatableObjectsSystem_mt = Class(ActivatableObjectsSystem)

-- Upvalues: ActivatableObjectsSystem_mt
-- Local values: self
function ActivatableObjectsSystem.new(mission, customMt)
	-- upvalues: (copy) ActivatableObjectsSystem_mt
	local v4_ = customMt or ActivatableObjectsSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.mission = mission
	v5_.objects = {}
	v5_.currentActivatableObject = nil
	v5_.inputContext = nil
	v5_.actionEventId = nil
	return v5_
end

function ActivatableObjectsSystem:activate(context)
	self.inputContext = context
	self.isActive = true
	self:updateObjects()
end

function ActivatableObjectsSystem:deactivate(context)
	self:removeInput(context)
	if self.currentActivatableObject ~= nil and self.currentActivatableObject.deactivate ~= nil then
		self.currentActivatableObject:deactivate()
	end
	self.currentActivatableObject = nil
	self.isActive = false
end

function ActivatableObjectsSystem:setPosition(x, y, z)
	self.posX = x
	self.posY = y
	self.posZ = z
end

function ActivatableObjectsSystem:setDirection(dirX, dirY, dirZ)
	self.dirX = dirX
	self.dirY = dirY
	self.dirZ = dirZ
end

function ActivatableObjectsSystem:update(dt)
	if self.isActive then
		self:updateObjects(dt)
	end
end

-- Local values: index, _, object, isActivatable, hasAccess, distance, text, farmId, isActive
function ActivatableObjectsSystem:draw()
	setTextBold(false)
	renderText(0.02, 0.6, 0.015, "ActivatableObjectsSystem")
	renderText(0.02, 0.58, 0.015, string.format(" isActive: %s", self.isActive))
	renderText(0.02, 0.56, 0.015, string.format(" pos: %.2f %.2f %.2f", self.posX, self.posY, self.posZ))
	renderText(0.02, 0.54, 0.015, string.format(" dir: %.2f %.2f %.2f", self.dirX, self.dirY, self.dirZ))
	local v21_ = 0
	for _, v22_ in pairs(self.objects) do
		local v23_ = v22_.getIsActivatable == nil and true or v22_:getIsActivatable(self.dirX, self.dirY, self.dirZ)
		local v24_ = v22_.getHasAccess == nil and true or v22_:getHasAccess(g_currentMission:getFarmId())
		local v25_ = (v22_.getDistance == nil or self.posX == nil) and math.huge or (v22_:getDistance(self.posX, self.posY, self.posZ) or math.huge)
		local v26_ = v22_.activateText
		if string.isNilOrWhitespace(v26_) and v22_.animatedObject then
			v26_ = string.format("%s \'%s\'|\'%s\'", v22_.animatedObject.saveId, v22_.animatedObject.controls.posActionText, v22_.animatedObject.controls.negActionText)
		end
		local v27_ = v22_.animatedObject and (v22_.animatedObject.ownerFarmId or "?") or "?"
		local v28_ = self.currentActivatableObject == v22_
		if v28_ then
			setTextColor(0, 0.5, 0, 1)
		end
		renderText(0.02, 0.52 - v21_ * 0.02, 0.015, string.format("    Object: %s (isActivatable: %s, hasAccess: %s, distance: %.2fm, farmId: %s)%s", v26_, v23_, v24_, v25_, v27_, v28_ and " Active" or ""))
		setTextColor(1, 1, 1, 1)
		v21_ = v21_ + 1
	end
end

-- Local values: nearestObject, nearestDistance, farmId, _, object, distance
function ActivatableObjectsSystem:updateObjects(dt)
	local v31_ = g_currentMission:getFarmId()
	local v32_ = nil
	local v33_ = math.huge
	for _, v34_ in pairs(self.objects) do
		if (v34_.getIsActivatable == nil or v34_:getIsActivatable(self.dirX, self.dirY, self.dirZ)) and (v34_.getHasAccess == nil or v34_:getHasAccess(v31_)) then
			local v35_ = (v34_.getDistance == nil or self.posX == nil) and math.huge or v34_:getDistance(self.posX, self.posY, self.posZ)
			if v32_ == nil or v35_ < v33_ then
				v33_ = v35_
				v32_ = v34_
			end
		end
	end
	if v32_ ~= self.currentActivatableObject then
		self:removeInput(self.inputContext)
		if self.currentActivatableObject ~= nil and self.currentActivatableObject.deactivate ~= nil then
			self.currentActivatableObject:deactivate()
		end
		self.currentActivatableObject = v32_
		if v32_ ~= nil then
			if v32_.activate ~= nil then
				v32_:activate()
			end
			self:registerInput(self.inputContext)
		end
	end
	if v32_ ~= nil then
		if self.actionEventId ~= nil then
			g_inputBinding:setActionEventText(self.actionEventId, v32_.activateText)
		end
		if v32_.update ~= nil then
			v32_:update(dt)
		end
	end
end

function ActivatableObjectsSystem:removeInput(inputContext)
	if inputContext ~= nil then
		g_inputBinding:beginActionEventsModification(inputContext)
	end
	if self.currentActivatableObject ~= nil and self.currentActivatableObject.removeCustomInput ~= nil then
		self.currentActivatableObject:removeCustomInput()
	end
	if self.actionEventId ~= nil then
		g_inputBinding:removeActionEvent(self.actionEventId)
		self.actionEventId = nil
	end
	if inputContext ~= nil then
		g_inputBinding:endActionEventsModification()
	end
end

-- Local values: currentObject, _, actionEventId
function ActivatableObjectsSystem:registerInput(inputContext)
	local v40_ = self.currentActivatableObject
	if v40_ ~= nil then
		if inputContext ~= nil then
			g_inputBinding:beginActionEventsModification(inputContext)
		end
		if v40_.registerCustomInput == nil or Platform.isMobile then
			local _, v41_ = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_OBJECT, self, self.onActivateObjectInput, false, true, false, true, nil, true, false)
			g_inputBinding:setActionEventText(v41_, v40_.activateText)
			g_inputBinding:setActionEventTextPriority(v41_, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventTextVisibility(v41_, true)
			self.actionEventId = v41_
		else
			v40_:registerCustomInput(inputContext)
		end
		if inputContext ~= nil then
			g_inputBinding:endActionEventsModification()
		end
	end
end

function ActivatableObjectsSystem:getActivatable()
	return self.currentActivatableObject
end

function ActivatableObjectsSystem:addActivatable(object)
	if object.activateText == nil then
		Logging.error("Given activatable object has no activateText")
		printCallstack()
	elseif self.objects[object] == nil then
		self.objects[object] = object
	end
end

function ActivatableObjectsSystem:removeActivatable(object)
	if object ~= nil then
		self.objects[object] = nil
		if object == self.currentActivatableObject then
			if object.deactivate ~= nil then
				object:deactivate()
			end
			self:removeInput(self.inputContext)
			self.currentActivatableObject = nil
		end
	end
end

function ActivatableObjectsSystem:onActivateObjectInput(actionName, inputValue, callbackState, isAnalog)
	if self.currentActivatableObject ~= nil then
		self.currentActivatableObject:run()
	end
end
function ActivatableObjectsSystem.consoleCommandDebugState()
	if g_currentMission:getHasDrawable(g_currentMission.activatableObjectsSystem) then
		g_currentMission:removeDrawable(g_currentMission.activatableObjectsSystem)
		Logging.info("ActivatableObjectsSystem Debug Disabled")
	else
		g_currentMission:addDrawable(g_currentMission.activatableObjectsSystem)
		Logging.info("ActivatableObjectsSystem Debug Enabled")
	end
end
addConsoleCommand("gsActivatableObjectsSystemToggleDebug", "Toggle ActivatableObjectsSystem Debug", "consoleCommandDebugState", ActivatableObjectsSystem)
