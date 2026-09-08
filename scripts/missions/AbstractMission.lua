-- Local values: AbstractMission_mt
AbstractMission = {}
local AbstractMission_mt = Class(AbstractMission, Object)
InitStaticObjectClass(AbstractMission, "AbstractMission")
AbstractMission.SUCCESS_FACTOR = 0.98
AbstractMission.VEHICLE_USE_COST = 200
AbstractMission.REIMBURSEMENT_FACTOR = 0.95

function AbstractMission.registerXMLPaths(xmlFile, baseDirectory) end

function AbstractMission.registerSavegameXMLPaths(xmlFile, baseDirectory)
	schema:register(XMLValueType.STRING, key .. "#uniqueId", "Mission unique id")
	MissionStatus.registerXMLPath(schema, key .. "#status", "Status of the mission", nil, false)
	MissionFinishState.registerXMLPath(schema, key .. "#finishState", "Finish state of the mission", nil, false)
	schema:register(XMLValueType.INT, key .. "#farmId", "FarmId of the mission")
	schema:register(XMLValueType.INT, key .. "#activeId", "Name active id")
	schema:register(XMLValueType.INT, key .. ".info#reward", "Reward of the mission")
	schema:register(XMLValueType.FLOAT, key .. ".info#reimbursement", "Reimbursement of the mission")
	schema:register(XMLValueType.FLOAT, key .. ".info#stealingCost", "Stealing costs")
	schema:register(XMLValueType.FLOAT, key .. ".info#completion", "Completion factor of the mission")
	schema:register(XMLValueType.INT, key .. ".vehicles#group", "Vehicle group id")
	schema:register(XMLValueType.BOOL, key .. ".vehicles#spawned", "If vehicles were spawned")
	schema:register(XMLValueType.STRING, key .. ".vehicles.vehicle(?)#uniqueId", "Vehicle unique id")
	schema:register(XMLValueType.INT, key .. ".endDate#endDay", "End day of the mission")
	schema:register(XMLValueType.INT, key .. ".endDate#endDayTime", "End daytime of the mission")
end

function AbstractMission.registerMetaXMLPaths(xmlFile, baseDirectory) end

-- Upvalues: AbstractMission_mt
-- Local values: self, data
function AbstractMission.new(isServer, isClient, title, description, customMt)
	-- upvalues: (copy) AbstractMission_mt
	local v9_ = Object.new(isServer, isClient, customMt or AbstractMission_mt)
	v9_.title = title
	v9_.progressTitle = title
	v9_.description = description
	v9_.status = MissionStatus.CREATED
	v9_.finishState = MissionFinishState.NONE
	v9_.reward = 0
	v9_.reimbursement = 0
	v9_.completion = 0
	v9_.vehicles = {}
	v9_.info = {}
	v9_.pendingVehicleLoadingData = {}
	v9_.spawnedVehicles = false
	v9_.uniqueId = nil
	v9_.missionDirtyFlag = v9_:getNextDirtyFlag()
	g_messageCenter:subscribe(MessageType.FARM_DELETED, v9_.farmDestroyed, v9_)
	g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, v9_.onSavegameLoaded, v9_, nil, false)
	local v10_ = g_missionManager:getMissionTypeDataByName(v9_:getMissionTypeName())
	v10_.numInstances = v10_.numInstances + 1
	return v9_
end

function AbstractMission:init()
	local v12_, v13_ = self:getVehicleGroup()
	self.vehiclesToLoad = v12_
	self.vehicleGroupIdentifier = v13_
	return true
end

function AbstractMission:failedToLoadFromXMLFile()
	g_messageCenter:unsubscribe(MessageType.SAVEGAME_LOADED, self)
end

function AbstractMission:onSavegameLoaded()
	if self:getWasStarted() then
		self:reactivate()
	end
end

function AbstractMission:reactivate()
	if self.spawnedVehicles then
		g_messageCenter:subscribe(MessageType.VEHICLE_RESET, self.onVehicleReset, self)
	end
end

function AbstractMission:getMapHotspots()
	return nil
end

-- Local values: data
function AbstractMission:delete()
	AbstractMission:superClass().delete(self)
	self:removeAccess()
	g_messageCenter:unsubscribeAll(self)
	g_missionManager:removeMission(self)
	g_messageCenter:publish(MessageType.MISSION_DELETED, self)
	local v18_ = g_missionManager:getMissionTypeDataByName(self:getMissionTypeName())
	if v18_ ~= nil then
		local v19_ = v18_.numInstances - 1
		v18_.numInstances = math.max(v19_, 0)
	end
end

-- Local values: k, vehicle
function AbstractMission:saveToXMLFile(xmlFile, key)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	MissionStatus.saveToXMLFile(xmlFile, key .. "#status", self.status)
	MissionFinishState.saveToXMLFile(xmlFile, key .. "#finishState", self.finishState)
	if self.farmId ~= nil then
		xmlFile:setValue(key .. "#farmId", self.farmId)
	end
	if self.activeMissionId ~= nil then
		xmlFile:setValue(key .. "#activeId", self.activeMissionId)
	end
	xmlFile:setValue(key .. ".info#reward", self.reward)
	xmlFile:setValue(key .. ".info#reimbursement", self.reimbursement)
	xmlFile:setValue(key .. ".info#completion", self.completion)
	if self.stealingCost ~= nil then
		xmlFile:setValue(key .. ".info#stealingCost", self.stealingCost)
	end
	xmlFile:setValue(key .. ".vehicles#spawned", self.spawnedVehicles)
	xmlFile:setValue(key .. ".vehicles#group", self.vehicleGroupIdentifier)
	for v23_, v24_ in ipairs(self.vehicles) do
		xmlFile:setValue(string.format(key .. ".vehicles.vehicle(%d)#uniqueId", v23_ - 1), v24_.uniqueId)
	end
	if self.endDate ~= nil then
		xmlFile:setValue(key .. ".endDate#endDay", self.endDate.endDay)
		xmlFile:setValue(key .. ".endDate#endDayTime", self.endDate.endDayTime)
	end
end

-- Local values: uniqueId, endDay, endDayTime, vehicleGroup, _, vehicleVariant, _, vehicleKey, vehicleUniqueId
function AbstractMission:loadFromXMLFile(xmlFile, key)
	self.activeMissionId = xmlFile:getValue(key .. "#activeId")
	self.status = MissionStatus.loadFromXMLFile(xmlFile, key .. "#status")
	if self.status == nil then
		Logging.xmlError(xmlFile, "Invalid mission status for \'%s\'", key)
		return false
	end
	self.finishState = MissionFinishState.loadFromXMLFile(xmlFile, key .. "#finishState") or MissionFinishState.NONE
	local v28_ = xmlFile:getValue(key .. "#uniqueId", nil)
	if v28_ ~= nil then
		self:setUniqueId(v28_)
	end
	self.farmId = xmlFile:getValue(key .. "#farmId")
	self.reward = xmlFile:getValue(key .. ".info#reward") or self.reward
	self.reimbursement = xmlFile:getValue(key .. ".info#reimbursement") or self.reimbursement
	self.completion = xmlFile:getValue(key .. ".info#completion") or self.completion
	self.stealingCost = xmlFile:getValue(key .. ".info#stealingCost")
	local v29_ = xmlFile:getValue(key .. ".endDate#endDay")
	local v30_ = xmlFile:getValue(key .. ".endDate#endDayTime")
	if v29_ ~= nil and v30_ ~= nil then
		self:setEndDate(v29_, v30_)
	end
	self.spawnedVehicles = xmlFile:getValue(key .. ".vehicles#spawned", self.spawnedVehicles)
	self.vehicleGroupIdentifier = xmlFile:getValue(key .. ".vehicles#group")
	local v31_, _, _, v32_ = self:getVehicleGroupFromIdentifier(self.vehicleGroupIdentifier)
	self.vehiclesToLoad = v31_
	local v33_ = self:getVehicleVariant()
	if v33_ ~= nil and (v32_ ~= nil and v32_.variant ~= v33_) then
		Logging.xmlWarning(xmlFile, "Loading vehicle group identifier does not match mission variant anymore. Skipping mission \'%s\'", key)
		return false
	end
	if self.vehiclesToLoad == nil then
		local v34_, v35_ = self:getVehicleGroup()
		self.vehiclesToLoad = v34_
		self.vehicleGroupIdentifier = v35_
		if self.vehiclesToLoad == nil then
			Logging.xmlWarning(xmlFile, "Loading vehicle group failed. Skipping mission \'%s\'", key)
			return false
		end
	end
	if self.spawnedVehicles and (self.status ~= MissionStatus.FINISHED and self.status ~= MissionStatus.DISMISSED) then
		self.tryToAddMissingVehicles = true
	end
	for _, v36_ in xmlFile:iterator(key .. ".vehicles.vehicle") do
		local v37_ = xmlFile:getValue(v36_ .. "#uniqueId")
		if self.pendingVehicleUniqueIds == nil then
			self.pendingVehicleUniqueIds = {}
		end
		local v38_ = self.pendingVehicleUniqueIds
		table.insert(v38_, v37_)
	end
	return true
end

function AbstractMission:writeStream(streamId, connection)
	AbstractMission:superClass().writeStream(self, streamId, connection)
	streamWriteUInt8(streamId, self.type.typeId)
	streamWriteFloat32(streamId, self.reward)
	streamWriteFloat32(streamId, self.reimbursement)
	MissionStatus.writeStream(streamId, self.status)
	streamWriteBool(streamId, self.spawnedVehicles)
	streamWriteInt32(streamId, self.vehicleGroupIdentifier)
	if self:getWasStarted() then
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
	if self.status == MissionStatus.RUNNING or self.status == MissionStatus.PREPARING then
		streamWriteInt32(streamId, self.activeMissionId)
	elseif self.status == MissionStatus.FINISHED then
		streamWriteFloat32(streamId, self.stealingCost or 0)
		MissionFinishState.writeStream(streamId, self.finishState)
	end
	if streamWriteBool(streamId, self.endDate ~= nil) then
		streamWriteInt32(streamId, self.endDate.endDay)
		streamWriteFloat32(streamId, self.endDate.endDayTime)
	end
end

-- Local values: endDay, endDayTime
function AbstractMission:readStream(streamId, connection)
	AbstractMission:superClass().readStream(self, streamId, connection)
	self.type = g_missionManager:getMissionTypeById(streamReadUInt8(streamId))
	self.reward = streamReadFloat32(streamId)
	self.reimbursement = streamReadFloat32(streamId)
	self.status = MissionStatus.readStream(streamId)
	self.spawnedVehicles = streamReadBool(streamId)
	self.vehicleGroupIdentifier = streamReadInt32(streamId)
	self.vehiclesToLoad = self:getVehicleGroupFromIdentifier(self.vehicleGroupIdentifier)
	if self:getWasStarted() then
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
	if self.status == MissionStatus.RUNNING or self.status == MissionStatus.PREPARING then
		self.activeMissionId = streamReadInt32(streamId)
	elseif self.status == MissionStatus.FINISHED then
		self.stealingCost = streamReadFloat32(streamId)
		self.finishState = MissionFinishState.readStream(streamId)
	end
	if streamReadBool(streamId) then
		self:setEndDate(streamReadInt32(streamId), (streamReadFloat32(streamId)))
	end
	g_missionManager:assignGenerationTime(self)
	local v45_ = g_missionManager.missions
	table.insert(v45_, self)
	g_messageCenter:publishDelayed(MessageType.MISSION_GENERATED, self)
end

function AbstractMission:writeUpdateStream(streamId, connection, dirtyMask)
	MissionStatus.writeStream(streamId, self.status)
	streamWriteFloat32(streamId, self.completion)
end

-- Local values: status
function AbstractMission:readUpdateStream(streamId, timestamp, connection)
	self:setStatus((MissionStatus.readStream(streamId)))
	self.completion = streamReadFloat32(streamId)
end

function AbstractMission:writeStreamMissionStartedInfo(streamId, connection)
	MissionStatus.writeStream(streamId, self.status)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.activeMissionId)
	streamWriteBool(streamId, self.spawnedVehicles)
end

function AbstractMission:readStreamMissionStartedInfo(streamId, connection)
	self.status = MissionStatus.readStream(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.activeMissionId = streamReadInt32(streamId)
	self.spawnedVehicles = streamReadBool(streamId)
end

-- Local values: mission, i, uniqueId, vehicle, _, info, found, _, vehicle
function AbstractMission:update(dt)
	local v55_ = g_currentMission
	if self.pendingVehicleUniqueIds ~= nil then
		for v56_ = #self.pendingVehicleUniqueIds, 1, -1 do
			local v57_ = self.pendingVehicleUniqueIds[v56_]
			local v58_ = v55_.vehicleSystem:getVehicleByUniqueId(v57_)
			if v58_ ~= nil then
				table.remove(self.pendingVehicleUniqueIds, v56_)
				local v59_ = self.vehicles
				table.insert(v59_, v58_)
			end
		end
		if #self.pendingVehicleUniqueIds == 0 then
			self.pendingVehicleUniqueIds = nil
		end
	end
	if self.tryToAddMissingVehicles and self.pendingVehicleUniqueIds == nil then
		if #self.vehicles ~= #self.vehiclesToLoad then
			for _, v60_ in ipairs(self.vehiclesToLoad) do
				local v61_ = false
				for _, v62_ in ipairs(self.vehicles) do
					if v60_.filename == v62_.configFileName then
						v61_ = true
						break
					end
				end
				if not v61_ then
					self:spawnVehicle(v60_)
				end
			end
		end
		self.tryToAddMissingVehicles = false
	end
	if self.isServer and self.status == MissionStatus.PREPARING then
		if self:getIsPrepared() then
			self:finishedPreparing()
		end
		if self.failedToLoadVehicles and #self.pendingVehicleLoadingData == 0 then
			self:finish(MissionFinishState.FAILED)
		end
	end
	if self.status == MissionStatus.RUNNING and self.isServer then
		if self:isTimedOut() then
			self:finish(MissionFinishState.TIMED_OUT)
		elseif not self:validate() then
			self:finish(MissionFinishState.FAILED)
		end
	end
	if (self.status == MissionStatus.RUNNING or self.status == MissionStatus.FINISHED) and (g_localPlayer ~= nil and g_localPlayer.farmId == self.farmId) then
		if self.progressBar == nil then
			self.progressBar = v55_.hud:addSideNotificationProgressBar(g_i18n:getText("contract_title"), self.progressTitle, self.completion)
		end
		self.progressBar.progress = self.completion
		v55_.hud:markSideNotificationProgressBarForDrawing(self.progressBar)
	end
	if self.status == MissionStatus.RUNNING or self.status == MissionStatus.PREPARING then
		self:raiseActive()
	end
end

-- Local values: mission
function AbstractMission:updateTick(dt)
	if self.isServer and self.status == MissionStatus.RUNNING then
		local v64_ = g_currentMission
		if self.lastCompletion == nil then
			self.lastCompletion = v64_.time
		elseif self.lastCompletion < v64_.time - 2500 then
			self.completion = self:getCompletion()
			if self.completion >= 0.995 then
				self:finish(MissionFinishState.SUCCESS)
			end
		end
		if self.lastCompletion ~= self.completion then
			self:raiseDirtyFlags(self.missionDirtyFlag)
		end
	end
end

function AbstractMission:start(spawnVehicles)
	self:prepare(spawnVehicles)
	self:raiseActive()
	g_server:broadcastEvent(MissionStartedEvent.new(self))
	return true
end

function AbstractMission:prepare(spawnVehicles)
	self:setStatus(MissionStatus.PREPARING)
	if self.isServer and (spawnVehicles and self.vehiclesToLoad ~= nil) then
		self:spawnVehicles()
		g_messageCenter:subscribe(MessageType.VEHICLE_RESET, self.onVehicleReset, self)
	end
end

function AbstractMission:getIsPrepared()
	return not self.spawnedVehicles and true or #self.vehiclesToLoad == #self.vehicles
end

function AbstractMission:finishedPreparing()
	self:setStatus(MissionStatus.RUNNING)
end

function AbstractMission:started() end

-- Local values: mission
function AbstractMission:finish(finishState)
	self:setStatus(MissionStatus.FINISHED)
	self.finishState = finishState
	if finishState ~= MissionFinishState.SUCCESS then
		self:removeAccess()
	end
	local v73_ = g_currentMission
	if v73_:getIsServer() then
		if finishState == MissionFinishState.SUCCESS then
			g_farmManager:getFarmById(self.farmId).stats:updateMissionDone()
		end
		self.stealingCost = self:calculateStealingCost()
		g_server:broadcastEvent(MissionFinishedEvent.new(self, finishState, self.stealingCost))
	end
	v73_.hud:removeSideNotificationProgressBar(self.progressBar)
	g_messageCenter:publish(MissionFinishedEvent, self, finishState)
end

-- Local values: change, mission
function AbstractMission:dismiss()
	if self.status ~= MissionStatus.DISMISSED then
		self:setStatus(MissionStatus.DISMISSED)
		if self.finishState == MissionFinishState.SUCCESS then
			self:removeAccess()
		end
		if self.isServer then
			local v75_ = self:getTotalReward()
			if v75_ ~= 0 then
				g_currentMission:addMoney(v75_, self.farmId, MoneyType.MISSIONS, true, true)
			end
		end
	end
end

function AbstractMission:setStatus(status)
	if self.status ~= status then
		self.status = status
		g_messageCenter:publishDelayed(MessageType.MISSION_STATUS_CHANGED, self, status)
	end
end

function AbstractMission:calculateStealingCost()
	return 0
end

function AbstractMission:getUniqueId()
	return self.uniqueId
end

function AbstractMission:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end

-- Local values: _, info
function AbstractMission:spawnVehicles()
	for _, v82_ in ipairs(self.vehiclesToLoad) do
		self:spawnVehicle(v82_)
	end
	self.spawnedVehicles = #self.vehiclesToLoad > 0
end

-- Local values: data, mission, loadingInfo
function AbstractMission:spawnVehicle(info)
	local v85_ = VehicleLoadingData.new()
	v85_:setFilename(info.filename)
	if v85_.isValid then
		if info.configurations ~= nil then
			v85_:setConfigurations(info.configurations)
		end
		local v86_ = g_currentMission
		v85_:setLoadingPlace(v86_.storeSpawnPlaces, v86_.usedStorePlaces)
		v85_:setPropertyState(VehiclePropertyState.MISSION)
		v85_:setOwnerFarmId(self.farmId)
		local v87_ = self.pendingVehicleLoadingData
		table.insert(v87_, v85_)
		v85_:load(self.onSpawnedVehicle, self, {
			["loadingData"] = v85_,
			["vehicleInfo"] = info
		})
	end
end

-- Local values: _, vehicle, _, vehicle, _, vehicle, _, loadingData, _, vehicle
function AbstractMission:onSpawnedVehicle(vehicles, vehicleLoadState, loadingInfo)
	table.removeElement(self.pendingVehicleLoadingData, loadingInfo.loadingData)
	if self.failedToLoadVehicles then
		for _, v92_ in ipairs(vehicles) do
			v92_:delete()
		end
		return
	elseif vehicleLoadState == VehicleLoadingState.OK then
		for _, v93_ in ipairs(vehicles) do
			v93_:addWearAmount(math.random() * 0.3 + 0.1)
			v93_:setOperatingTime(3600000 * (math.random() * 40 + 30))
			local v94_ = self.vehicles
			table.insert(v94_, v93_)
		end
	else
		self.failedToLoadVehicles = true
		for _, v95_ in ipairs(vehicles) do
			v95_:delete()
		end
		for _, v96_ in ipairs(self.pendingVehicleLoadingData) do
			v96_:cancelLoading()
		end
		table.clear(self.pendingVehicleLoadingData)
		table.clear(self.vehiclesToLoad)
		self.spawnedVehicles = false
		for _, v97_ in ipairs(self.vehicles) do
			v97_:delete()
		end
		table.clear(self.vehicles)
	end
end

function AbstractMission:getStealingCosts()
	return 0
end

-- Local values: numVehicles, mission, difficultyMultiplier, vehicleCosts
function AbstractMission:getVehicleCosts()
	if self.vehiclesToLoad == nil then
		return 0
	end
	local v99_ = #self.vehiclesToLoad
	local v100_ = 0.7 + 0.3 * g_currentMission.missionInfo.economicDifficulty
	return v99_ * AbstractMission.VEHICLE_USE_COST * v100_
end

function AbstractMission:getReward()
	return 0
end

function AbstractMission:getReimbursement()
	return self.reimbursement
end

function AbstractMission:calculateReimbursement() end

function AbstractMission:getActualVehicleCosts()
	return not self.spawnedVehicles and 0 or self:getVehicleCosts()
end

function AbstractMission:getActualReward()
	return self.finishState ~= MissionFinishState.SUCCESS and 0 or self:getReward()
end

function AbstractMission:getActualStealingCosts()
	return self:getStealingCosts()
end

-- Local values: reward, vehicleCosts, stealingCosts, reimbursement
function AbstractMission:getTotalReward()
	local v106_ = self:getActualReward()
	local v107_ = self:getActualVehicleCosts()
	local v108_ = self:getActualStealingCosts()
	local v109_ = self:getReimbursement()
	return v106_ - v107_ - v108_ + v109_
end

-- Local values: isTimedOut
function AbstractMission:validate(event)
	return not self:isTimedOut()
end

-- Local values: minutesLeft
function AbstractMission:isTimedOut()
	local v112_ = self:getMinutesLeft()
	if v112_ == nil then
		return false
	else
		return v112_ <= 0
	end
end

-- Local values: endDate, mission, environment, currentMonotonicDay, dayTime, totalDayTime, endDay, endDayTime, dayTimeDelta, minutesLeft
function AbstractMission:getMinutesLeft()
	local v114_ = self.endDate
	if v114_ == nil then
		return nil
	end
	local v115_ = g_currentMission.environment
	local v116_ = v115_.currentMonotonicDay
	local v117_ = v115_.dayTime
	local v118_ = v114_.endDay
	local v119_ = v114_.endDayTime
	local v120_ = 0
	if v117_ < v119_ then
		v120_ = v119_ - v117_
	elseif v116_ < v118_ then
		v120_ = v117_ + (86400000 - v119_)
		v116_ = v116_ + 1
	end
	return (v120_ + (v118_ - v116_) * 86400000) / 60000
end

-- Local values: mission, environment, currentMonotonicDay, daysPerPeriod, dayInPeriod, endDay, endDayTime
function AbstractMission:setDefaultEndDate()
	local v122_ = g_currentMission.environment
	local v123_ = v122_.currentMonotonicDay
	self:setEndDate(v123_ + (v122_.daysPerPeriod - v122_:getDayInPeriodFromDay(v123_)), 86399999)
end

-- Local values: mission, environment, currentMonotonicDay, endDay, endDayTime
function AbstractMission:setEndDateByOffset(dayTimeOffset)
	local v126_ = g_currentMission.environment
	local v127_, v128_ = v126_:getDayAndDayTime(dayTimeOffset, v126_.currentMonotonicDay)
	self:setEndDate(v127_, v128_)
end

function AbstractMission:setEndDate(endDay, endDayTime)
	self.endDate = {
		["endDay"] = endDay,
		["endDayTime"] = endDayTime
	}
end

function AbstractMission:getIsInProgress()
	return self.status == MissionStatus.PREPARING and true or self.status == MissionStatus.RUNNING
end

function AbstractMission:getIsRunning()
	return self.status == MissionStatus.RUNNING
end

function AbstractMission:getWasRunning()
	return (self.status == MissionStatus.RUNNING or self.status == MissionStatus.FINISHED) and true or self.status == MissionStatus.DISMISSED
end

function AbstractMission:getIsReadyToStart()
	return self.status == MissionStatus.CREATED
end

function AbstractMission:getWasStarted()
	return self.status ~= MissionStatus.CREATED
end

function AbstractMission:getIsFinished()
	return self.status == MissionStatus.FINISHED
end

function AbstractMission:getInfo()
	return self.info
end

function AbstractMission:getLocation()
	return ""
end

function AbstractMission:getDescription()
	return self.description
end

-- Local values: details
function AbstractMission:getDetails()
	local v141_ = {}
	if not self:getWasStarted() or self.spawnedVehicles then
		local v142_ = {
			["title"] = g_i18n:getText("contract_vehicleCosts"),
			["value"] = g_i18n:formatMoney(self:getVehicleCosts(), 0, true, true)
		}
		table.insert(v141_, v142_)
	end
	return v141_
end

-- Local values: details
function AbstractMission:getFinishedDetails()
	local v144_ = {}
	local v145_ = {
		["title"] = g_i18n:getText("contract_reward"),
		["value"] = g_i18n:formatMoney(self:getActualReward(), 0, true, true)
	}
	table.insert(v144_, v145_)
	local v146_ = {
		["title"] = g_i18n:getText("contract_reimbursement"),
		["value"] = g_i18n:formatMoney(self:getReimbursement(), 0, true, true)
	}
	table.insert(v144_, v146_)
	local v147_ = {
		["title"] = g_i18n:getText("contract_vehicleCosts"),
		["value"] = g_i18n:formatMoney(-self:getActualVehicleCosts(), 0, true, true)
	}
	table.insert(v144_, v147_)
	local v148_ = {
		["title"] = g_i18n:getText("contract_stealing"),
		["value"] = g_i18n:formatMoney(-self:getActualStealingCosts(), 0, true, true)
	}
	table.insert(v144_, v148_)
	return v144_
end

function AbstractMission:getTitle()
	return self.title
end

function AbstractMission:getNPC()
	return nil
end

function AbstractMission:getExtraProgressText()
	return ""
end

function AbstractMission:getCompletion()
	return 0
end

function AbstractMission:farmDestroyed(farmId)
	if farmId == self.farmId then
		g_missionManager:markMissionForDeletion(self)
	end
end

function AbstractMission:getMissionTypeName()
	return nil
end

-- Local values: wasMissionVehicle
function AbstractMission:onVehicleReset(oldVehicle, newVehicle)
	if self.isServer and table.removeElement(self.vehicles, oldVehicle) then
		table.addElement(self.vehicles, newVehicle)
	end
end

function AbstractMission:getVehicleSize()
	return "small"
end

function AbstractMission:getVehicleGroupFromIdentifier(identifier)
	return g_missionManager:getVehicleGroupFromIdentifier(self.type.name, self:getVehicleSize(), identifier)
end

function AbstractMission:getVehicleGroup()
	return g_missionManager:getRandomVehicleGroup(self:getMissionTypeName(), self:getVehicleSize(), self:getVehicleVariant())
end

function AbstractMission:getVehicleVariant()
	return nil
end

function AbstractMission:getVariant()
	return nil
end

-- Local values: _, vehicle
function AbstractMission:removeAccess()
	if self.isServer then
		self:calculateReimbursement()
		for _, v159_ in ipairs(self.vehicles) do
			if not v159_:getIsBeingDeleted() then
				v159_:delete()
			end
		end
		self.vehicles = {}
	end
end

function AbstractMission:hasLeasableVehicles()
	return self.vehiclesToLoad ~= nil
end

-- Local values: result, mission, places, usedPlaces, placesFilled, _, v, storeItem, size, x, _, _, place, width, _, _, place
function AbstractMission:isSpawnSpaceAvailable()
	local v162_ = g_currentMission
	local v163_ = v162_.storeSpawnPlaces
	local v164_ = v162_.usedStorePlaces
	local v165_ = {}
	local v166_ = true
	for _, v167_ in ipairs(self.vehiclesToLoad) do
		local v168_ = g_storeManager:getItemByXMLFilename(v167_.filename)
		local v169_ = StoreItemUtil.getSizeValues(v167_.filename, "vehicle", v168_.rotation, v167_.configurations)
		local v170_ = v169_.width
		local v171_ = VehicleLoadingData.MIN_SPAWN_PLACE_WIDTH
		v169_.width = math.max(v170_, v171_)
		local v172_ = v169_.length
		local v173_ = VehicleLoadingData.MIN_SPAWN_PLACE_LENGTH
		v169_.length = math.max(v172_, v173_)
		local v174_ = v169_.height
		local v175_ = VehicleLoadingData.MIN_SPAWN_PLACE_HEIGHT
		v169_.height = math.max(v174_, v175_)
		v169_.width = v169_.width + VehicleLoadingData.SPAWN_WIDTH_OFFSET
		local v176_, _, _, v177_, v178_, _ = PlacementUtil.getPlace(v163_, v169_, v164_)
		if v176_ == nil then
			v166_ = false
			break
		end
		PlacementUtil.markPlaceUsed(v164_, v177_, v178_)
		table.insert(v165_, v177_)
	end
	for _, v179_ in ipairs(v165_) do
		PlacementUtil.unmarkPlaceUsed(v164_, v179_)
	end
	return v166_
end

function AbstractMission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)
	return true
end

function AbstractMission:getWorldPosition()
	return 0, 0
end

function AbstractMission.loadMapData(xmlFile, baseDirectory) end
function AbstractMission.unloadMapData() end
function AbstractMission.tryGenerateMission() end
function AbstractMission.canRun() end
