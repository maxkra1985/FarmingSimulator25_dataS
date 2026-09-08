-- Local values: AIJobGoTo_mt
AIJobGoTo = {}
AIJobGoTo.START_ERROR_LIMIT_REACHED = 1
AIJobGoTo.START_ERROR_VEHICLE_DELETED = 2
AIJobGoTo.START_ERROR_NO_PERMISSION = 3
AIJobGoTo.START_ERROR_VEHICLE_IN_USE = 4
local AIJobGoTo_mt = Class(AIJobGoTo, AIJob)

-- Upvalues: AIJobGoTo_mt
-- Local values: self, vehicleGroup, positionGroup
function AIJobGoTo.new(isServer, customMt)
	-- upvalues: (copy) AIJobGoTo_mt
	local v4_ = AIJob.new(isServer, customMt or AIJobGoTo_mt)
	v4_.driveToTask = AITaskDriveTo.new(isServer, v4_)
	v4_:addTask(v4_.driveToTask)
	v4_.vehicleParameter = AIParameterVehicle.new()
	v4_.positionAngleParameter = AIParameterPositionAngle.new(0)
	v4_:addNamedParameter("vehicle", v4_.vehicleParameter)
	v4_:addNamedParameter("positionAngle", v4_.positionAngleParameter)
	local v5_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))
	v5_:addParameter(v4_.vehicleParameter)
	local v6_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitlePosition"))
	v6_:addParameter(v4_.positionAngleParameter)
	local v7_ = v4_.groupedParameters
	table.insert(v7_, v5_)
	local v8_ = v4_.groupedParameters
	table.insert(v8_, v6_)
	return v4_
end

-- Local values: vehicle
function AIJobGoTo:start(farmId)
	AIJobGoTo:superClass().start(self, farmId)
	local v11_ = self.vehicleParameter:getVehicle()
	if v11_ ~= nil then
		if self.isServer then
			v11_:createAgent(self.helperIndex)
		end
		v11_:aiJobStarted(self, self.helperIndex, farmId)
	end
end

-- Local values: vehicle
function AIJobGoTo:stop(aiMessage)
	local v14_ = self.vehicleParameter:getVehicle()
	if v14_ ~= nil then
		if self.isServer then
			v14_:deleteAgent()
		end
		v14_:aiJobFinished()
	end
	AIJobGoTo:superClass().stop(self, aiMessage)
end

function AIJobGoTo:getShowTarget()
	return true
end

-- Local values: angle
function AIJobGoTo:getTarget()
	local v16_
	if self.driveToTask.dirX == nil then
		v16_ = nil
	else
		v16_ = MathUtil.getYRotationFromDirection(self.driveToTask.dirX, self.driveToTask.dirZ)
	end
	return self.driveToTask.x, self.driveToTask.z, v16_
end

function AIJobGoTo:getIsAvailableForVehicle(vehicle)
	if vehicle.createAgent == nil or (vehicle.setAITarget == nil or not vehicle:getCanStartAIVehicle()) then
		return false
	else
		return vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self)) and true or false
	end
end

-- Local values: vehicle
function AIJobGoTo:getTitle()
	local v20_ = self.vehicleParameter:getVehicle()
	return v20_ == nil and "" or v20_:getName()
end

-- Local values: x, z, angle, _, lastJob, dirX, _, dirZ
function AIJobGoTo:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobGoTo:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)
	local v26_ = nil
	local v27_ = nil
	local v28_ = nil
	if vehicle.getLastJob ~= nil then
		local v29_ = vehicle:getLastJob()
		if not isDirectStart and (v29_ ~= nil and v29_:isa(AIJobGoTo)) then
			v26_, v27_ = v29_.positionAngleParameter:getPosition()
			v28_ = v29_.positionAngleParameter:getAngle()
		end
	end
	self.positionAngleParameter:setSnappingAngle(0)
	if v26_ == nil or v27_ == nil then
		local v30_
		v26_, v30_, v27_ = getWorldTranslation(vehicle.rootNode)
	end
	if v28_ == nil then
		local v31_, _, v32_ = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
		v28_ = MathUtil.getYRotationFromDirection(v31_, v32_)
	end
	self.positionAngleParameter:setPosition(v26_, v27_)
	self.positionAngleParameter:setAngle(v28_)
end

-- Local values: angle, x, z, dirX, dirZ
function AIJobGoTo:setValues()
	self:resetTasks()
	self.driveToTask:setVehicle(self.vehicleParameter:getVehicle())
	local v34_ = self.positionAngleParameter:getAngle()
	local v35_, v36_ = self.positionAngleParameter:getPosition()
	local v37_, v38_ = MathUtil.getDirectionFromYRotation(v34_)
	self.driveToTask:setTargetDirection(v37_, v38_)
	self.driveToTask:setTargetPosition(v35_, v36_)
end

-- Local values: isVehicleValid, errorMessageVehicle, isPositionValid, errorMessagePosition, isValid, errorMessage
function AIJobGoTo:validate(farmId)
	self:setParameterValid(true)
	local v40_, v41_ = self.vehicleParameter:validate()
	if not v40_ then
		self.vehicleParameter:setIsValid(false)
	end
	local v42_, v43_ = self.positionAngleParameter:validate()
	if not v42_ then
		self.positionAngleParameter:setIsValid(false)
	end
	return v40_ and v42_, v41_ or v43_
end

-- Local values: desc, nextTask
function AIJobGoTo:getDescription()
	local v45_ = AIJobGoTo:superClass().getDescription(self)
	if self:getTaskByIndex(self.currentTaskIndex) == self.driveToTask then
		v45_ = v45_ .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToTarget")
	end
	return v45_
end

-- Local values: vehicle
function AIJobGoTo:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobGoTo.START_ERROR_LIMIT_REACHED
	else
		local v48_ = self.vehicleParameter:getVehicle()
		if v48_ == nil then
			return false, AIJobGoTo.START_ERROR_VEHICLE_DELETED
		elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, v48_:getOwnerFarmId()) then
			if v48_:getIsInUse(connection) then
				return false, AIJobGoTo.START_ERROR_VEHICLE_IN_USE
			else
				return true, AIJob.START_SUCCESS
			end
		else
			return false, AIJobGoTo.START_ERROR_NO_PERMISSION
		end
	end
end

function AIJobGoTo.getIsStartErrorText(state)
	if state == AIJobGoTo.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobGoTo.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobGoTo.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobGoTo.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	else
		return g_i18n:getText("ai_startStateSuccess")
	end
end
