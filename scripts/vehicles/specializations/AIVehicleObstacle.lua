AIVehicleObstacle = {}

function AIVehicleObstacle.prerequisitesPresent(self)
	return true
end

function AIVehicleObstacle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "createAIVehicleObstacle", AIVehicleObstacle.createAIVehicleObstacle)
	SpecializationUtil.registerFunction(vehicleType, "removeAIVehicleObstacle", AIVehicleObstacle.removeAIVehicleObstacle)
	SpecializationUtil.registerFunction(vehicleType, "updateAIVehicleObstacleState", AIVehicleObstacle.updateAIVehicleObstacleState)
	SpecializationUtil.registerFunction(vehicleType, "getCanHaveAIVehicleObstacle", AIVehicleObstacle.getCanHaveAIVehicleObstacle)
	SpecializationUtil.registerFunction(vehicleType, "getNeedAIVehicleObstacle", AIVehicleObstacle.getNeedAIVehicleObstacle)
	SpecializationUtil.registerFunction(vehicleType, "getAIVehicleObstacleMaxBrakeAcceleration", AIVehicleObstacle.getAIVehicleObstacleMaxBrakeAcceleration)
	SpecializationUtil.registerFunction(vehicleType, "setAIVehicleObstacleStateDirty", AIVehicleObstacle.setAIVehicleObstacleStateDirty)
	SpecializationUtil.registerFunction(vehicleType, "getAIVehicleObstacleIsPassable", AIVehicleObstacle.getAIVehicleObstacleIsPassable)
end

function AIVehicleObstacle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AIVehicleObstacle.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AIVehicleObstacle.removeFromPhysics)
end

function AIVehicleObstacle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIVehicleObstacle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIVehicleObstacle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIVehicleObstacle)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", AIVehicleObstacle)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIVehicleObstacle)
end

-- Local values: spec
function AIVehicleObstacle:onLoad(savegame)
	self.spec_aiVehicleObstacle.needsUpdate = false
end

function AIVehicleObstacle:onDelete()
	self:removeAIVehicleObstacle()
end

-- Local values: spec
function AIVehicleObstacle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v7_ = self.spec_aiVehicleObstacle
	if self.isServer and v7_.needsUpdate then
		self:updateAIVehicleObstacleState()
		v7_.needsUpdate = false
	end
end

-- Local values: maxBrakeAcceleration, _, component
function AIVehicleObstacle:createAIVehicleObstacle()
	if self.isAddedToPhysics then
		local v9_ = self:getAIVehicleObstacleMaxBrakeAcceleration()
		for _, v10_ in ipairs(self.components) do
			if v10_.obstacleId == nil then
				g_currentMission.aiSystem:addObstacle(v10_.node, 0, 0, 0, 0, 0, 0, v9_)
				v10_.obstacleId = v10_.node
			end
			g_currentMission.aiSystem:setObstacleIsPassable(v10_.node, self:getAIVehicleObstacleIsPassable())
		end
	end
end

-- Local values: _, component
function AIVehicleObstacle:removeAIVehicleObstacle()
	if self.components ~= nil then
		for _, v12_ in ipairs(self.components) do
			if v12_.obstacleId ~= nil then
				g_currentMission.aiSystem:removeObstacle(v12_.node)
				v12_.obstacleId = nil
			end
		end
	end
end

function AIVehicleObstacle:updateAIVehicleObstacleState()
	if self.isServer then
		if self:getCanHaveAIVehicleObstacle() then
			if self:getNeedAIVehicleObstacle() then
				self:createAIVehicleObstacle()
				return
			end
		else
			self:removeAIVehicleObstacle()
		end
	end
end

function AIVehicleObstacle:setAIVehicleObstacleStateDirty()
	self.spec_aiVehicleObstacle.needsUpdate = true
	self:raiseActive()
end

function AIVehicleObstacle:getCanHaveAIVehicleObstacle()
	if self.isAddedToPhysics then
		if self.propertyState == VehiclePropertyState.SHOP_CONFIG then
			return false
		else
			return (self.rootVehicle == self or (self.rootVehicle.getCanHaveAIVehicleObstacle == nil or self.rootVehicle:getCanHaveAIVehicleObstacle())) and true or false
		end
	else
		return false
	end
end

function AIVehicleObstacle.getNeedAIVehicleObstacle(self)
	return true
end

function AIVehicleObstacle:getAIVehicleObstacleIsPassable()
	return self.getIsControlled == nil and true or not self:getIsControlled()
end

function AIVehicleObstacle:getAIVehicleObstacleMaxBrakeAcceleration()
	return 5
end

function AIVehicleObstacle:onEnterVehicle(isControlling)
	self:setAIVehicleObstacleStateDirty()
end

function AIVehicleObstacle:onLeaveVehicle()
	self:setAIVehicleObstacleStateDirty()
end

function AIVehicleObstacle:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	self:setAIVehicleObstacleStateDirty()
	return true
end

function AIVehicleObstacle:removeFromPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	self:setAIVehicleObstacleStateDirty()
	return true
end
