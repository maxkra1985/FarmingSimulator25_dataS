-- Local values: AIJobConveyor_mt
AIJobConveyor = {}
AIJobConveyor.START_ERROR_LIMIT_REACHED = 1
AIJobConveyor.START_ERROR_VEHICLE_DELETED = 2
AIJobConveyor.START_ERROR_NO_PERMISSION = 3
AIJobConveyor.START_ERROR_VEHICLE_IN_USE = 4
local AIJobConveyor_mt = Class(AIJobConveyor, AIJob)

-- Upvalues: AIJobConveyor_mt
-- Local values: self, vehicleGroup
function AIJobConveyor.new(isServer, customMt)
	-- upvalues: (copy) AIJobConveyor_mt
	local v4_ = AIJob.new(isServer, customMt or AIJobConveyor_mt)
	v4_.conveyorTask = AITaskConveyor.new(isServer, v4_)
	v4_:addTask(v4_.conveyorTask)
	v4_.vehicleParameter = AIParameterVehicle.new()
	v4_:addNamedParameter("vehicle", v4_.vehicleParameter)
	local v5_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))
	v5_:addParameter(v4_.vehicleParameter)
	local v6_ = v4_.groupedParameters
	table.insert(v6_, v5_)
	return v4_
end

function AIJobConveyor:getPricePerMs()
	return 0.00005
end

-- Local values: vehicle
function AIJobConveyor:start(farmId)
	AIJobConveyor:superClass().start(self, farmId)
	if self.isServer then
		self.vehicleParameter:getVehicle():aiJobStarted(self, self.helperIndex, farmId)
	end
end

-- Local values: vehicle
function AIJobConveyor:stop(aiMessage)
	if self.isServer then
		self.vehicleParameter:getVehicle():aiJobFinished()
	end
	AIJobConveyor:superClass().stop(self, aiMessage)
end

function AIJobConveyor:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobConveyor:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)
end

function AIJobConveyor:getIsAvailableForVehicle(vehicle)
	local v18_ = vehicle.spec_aiConveyorBelt ~= nil and vehicle:getCanStartAIVehicle()
	if v18_ then
		v18_ = vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self))
	end
	return v18_
end

-- Local values: vehicle
function AIJobConveyor:getTitle()
	local v20_ = self.vehicleParameter:getVehicle()
	return v20_ == nil and "" or v20_:getName()
end

function AIJobConveyor:setValues()
	self:resetTasks()
	self.conveyorTask:setVehicle(self.vehicleParameter:getVehicle())
end

-- Local values: isValid, errorMessage
function AIJobConveyor:validate(farmId)
	self:setParameterValid(true)
	local v23_, v24_ = self.vehicleParameter:validate(false)
	if not v23_ then
		self.vehicleParameter:setIsValid(false)
	end
	return v23_, v24_
end

-- Local values: vehicle
function AIJobConveyor:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobConveyor.START_ERROR_LIMIT_REACHED
	else
		local v27_ = self.vehicleParameter:getVehicle()
		if v27_ == nil then
			return false, AIJobConveyor.START_ERROR_VEHICLE_DELETED
		elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, v27_:getOwnerFarmId()) then
			if v27_:getIsInUse(connection) then
				return false, AIJobConveyor.START_ERROR_VEHICLE_IN_USE
			else
				return true, AIJob.START_SUCCESS
			end
		else
			return false, AIJobConveyor.START_ERROR_NO_PERMISSION
		end
	end
end

function AIJobConveyor.getIsStartErrorText(state)
	if state == AIJobConveyor.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobConveyor.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobConveyor.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobConveyor.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	else
		return g_i18n:getText("ai_startStateSuccess")
	end
end
