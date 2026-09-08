-- Local values: AIJobFieldWork_mt
AIJobFieldWork = {}
AIJobFieldWork.START_ERROR_LIMIT_REACHED = 1
AIJobFieldWork.START_ERROR_VEHICLE_DELETED = 2
AIJobFieldWork.START_ERROR_NO_PERMISSION = 3
AIJobFieldWork.START_ERROR_VEHICLE_IN_USE = 4
local AIJobFieldWork_mt = Class(AIJobFieldWork, AIJob)

-- Upvalues: AIJobFieldWork_mt
-- Local values: self, vehicleGroup, positionGroup
function AIJobFieldWork.new(isServer, customMt)
	-- upvalues: (copy) AIJobFieldWork_mt
	local v4_ = AIJob.new(isServer, customMt or AIJobFieldWork_mt)
	v4_.driveToTask = AITaskDriveTo.new(isServer, v4_)
	v4_.fieldWorkTask = AITaskFieldWork.new(isServer, v4_)
	v4_:addTask(v4_.driveToTask)
	v4_:addTask(v4_.fieldWorkTask)
	v4_.isDirectStart = false
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

function AIJobFieldWork:readStream(streamId, connection)
	AIJobFieldWork:superClass().readStream(self, streamId, connection)
	if streamReadBool(streamId) then
		self.pendingData = AIModeSelection.readAIModeSettingsFromStream(streamId, connection)
		self.pendingVehicle = true
	end
end

-- Local values: vehicle
function AIJobFieldWork:writeStream(streamId, connection)
	AIJobFieldWork:superClass().writeStream(self, streamId, connection)
	local v15_ = self.vehicleParameter:getVehicle()
	if streamWriteBool(streamId, v15_ ~= nil) then
		v15_:writeAIModeSettingsToStream(streamId, connection)
	end
end

-- Local values: vehicle
function AIJobFieldWork:update(dt)
	if self.pendingVehicle then
		local v18_ = self.vehicleParameter:getVehicle()
		if v18_ ~= nil then
			self.driveToTask:setVehicle(v18_)
			self.fieldWorkTask:setVehicle(v18_)
			v18_:applyReadAIModeSettingsFromStream(self.pendingData)
			self.pendingData = nil
			self.pendingVehicle = nil
		end
	end
	AIJobFieldWork:superClass().update(self, dt)
end

-- Local values: vehicle, x, _, z, tx, tz, targetReached
function AIJobFieldWork:getStartTaskIndex()
	if self.isDirectStart then
		return 2
	end
	local v20_ = self.vehicleParameter:getVehicle()
	local v21_, _, v22_ = getWorldTranslation(v20_.rootNode)
	local v23_, v24_ = self.positionAngleParameter:getPosition()
	return MathUtil.vector2Length(v21_ - v23_, v22_ - v24_) < 3 and 2 or 1
end

-- Local values: vehicle
function AIJobFieldWork:start(farmId)
	AIJobFieldWork:superClass().start(self, farmId)
	if self.isServer then
		local v27_ = self.vehicleParameter:getVehicle()
		v27_:createAgent(self.helperIndex)
		v27_:aiJobStarted(self, self.helperIndex, farmId)
	end
end

-- Local values: vehicle
function AIJobFieldWork:stop(aiMessage)
	if self.isServer then
		local v30_ = self.vehicleParameter:getVehicle()
		v30_:deleteAgent()
		v30_:aiJobFinished()
	end
	AIJobFieldWork:superClass().stop(self, aiMessage)
end

-- Local values: x, z, angle, _, lastJob, snappingAngle, terrainAngle, dirX, _, dirZ
function AIJobFieldWork:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobFieldWork:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)
	local v36_ = nil
	local v37_ = nil
	local v38_ = nil
	if vehicle.getLastJob ~= nil then
		local v39_ = vehicle:getLastJob()
		if not isDirectStart and (v39_ ~= nil and v39_:isa(AIJobFieldWork)) then
			v36_, v37_ = v39_.positionAngleParameter:getPosition()
			v38_ = v39_.positionAngleParameter:getAngle()
		end
	end
	local v40_ = vehicle:getDirectionSnapAngle()
	local v41_ = g_currentMission.fieldGroundSystem:getGroundAngleMaxValue() + 1
	local v42_ = 3.141592653589793 / math.max(v41_, 4)
	local v43_ = math.max(v40_, v42_)
	self.positionAngleParameter:setSnappingAngle(v43_)
	if v36_ == nil or v37_ == nil then
		local v44_
		v36_, v44_, v37_ = getWorldTranslation(vehicle.rootNode)
	end
	if v38_ == nil then
		local v45_, _, v46_ = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
		v38_ = MathUtil.getYRotationFromDirection(v45_, v46_)
	end
	self.positionAngleParameter:setPosition(v36_, v37_)
	self.positionAngleParameter:setAngle(v38_)
end

function AIJobFieldWork:getIsAvailableForVehicle(vehicle)
	local v49_ = vehicle.getCanStartFieldWork and vehicle:getCanStartFieldWork()
	if v49_ then
		v49_ = vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self))
	end
	return v49_
end

function AIJobFieldWork:getShowTarget()
	return self.currentTaskIndex == 1
end

-- Local values: angle
function AIJobFieldWork:getTarget()
	local v52_ = self.driveToTask.dirX == nil and 0 or MathUtil.getYRotationFromDirection(self.driveToTask.dirX, self.driveToTask.dirZ)
	return self.driveToTask.x, self.driveToTask.z, v52_
end

-- Local values: vehicle
function AIJobFieldWork:getTitle()
	local v54_ = self.vehicleParameter:getVehicle()
	return v54_ == nil and "" or v54_:getName()
end

-- Local values: vehicle, angle, x, z, dirX, dirZ
function AIJobFieldWork:setValues()
	self:resetTasks()
	local v56_ = self.vehicleParameter:getVehicle()
	self.driveToTask:setVehicle(v56_)
	self.fieldWorkTask:setVehicle(v56_)
	local v57_ = self.positionAngleParameter:getAngle()
	local v58_, v59_ = self.positionAngleParameter:getPosition()
	local v60_, v61_ = MathUtil.getDirectionFromYRotation(v57_)
	self.driveToTask:setTargetDirection(v60_, v61_)
	self.driveToTask:setTargetPosition(v58_, v59_)
end

-- Local values: isValid, errorMessage
function AIJobFieldWork:validate(farmId)
	self:setParameterValid(true)
	local v63_, v64_ = self.vehicleParameter:validate()
	if not v63_ then
		self.vehicleParameter:setIsValid(false)
	end
	return v63_, v64_
end

-- Local values: desc, nextTask
function AIJobFieldWork:getDescription()
	local v66_ = AIJobFieldWork:superClass().getDescription(self)
	local v67_ = self:getTaskByIndex(self.currentTaskIndex)
	if v67_ == self.driveToTask then
		return v66_ .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToField")
	end
	if v67_ == self.fieldWorkTask then
		v66_ = v66_ .. " - " .. g_i18n:getText("ai_taskDescriptionFieldWork")
	end
	return v66_
end

-- Local values: vehicle
function AIJobFieldWork:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobFieldWork.START_ERROR_LIMIT_REACHED
	else
		local v70_ = self.vehicleParameter:getVehicle()
		if v70_ == nil then
			return false, AIJobFieldWork.START_ERROR_VEHICLE_DELETED
		elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, v70_:getOwnerFarmId()) then
			if v70_:getIsInUse(connection) then
				return false, AIJobFieldWork.START_ERROR_VEHICLE_IN_USE
			else
				return true, AIJob.START_SUCCESS
			end
		else
			return false, AIJobFieldWork.START_ERROR_NO_PERMISSION
		end
	end
end

function AIJobFieldWork.getIsStartErrorText(state)
	if state == AIJobFieldWork.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobFieldWork.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobFieldWork.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobFieldWork.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	else
		return g_i18n:getText("ai_startStateSuccess")
	end
end

function AIJobFieldWork:getPricePerMs()
	return 0.0005
end
