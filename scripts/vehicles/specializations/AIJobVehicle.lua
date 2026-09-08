source("dataS/scripts/vehicles/specializations/events/AIJobVehicleStateEvent.lua")
AIJobVehicle = {}

function AIJobVehicle.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AIVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Drivable, specializations)
	end
	return v2_
end
function AIJobVehicle.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("AIJobVehicle")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.ai.steeringNode#node", "Steering node")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.ai.reverserNode#node", "Reverser node")
	v3_:register(XMLValueType.FLOAT, "vehicle.ai.steeringSpeed", "Speed of steering", 1)
	v3_:register(XMLValueType.BOOL, "vehicle.ai#supportsAIJobs", "If true vehicle supports ai jobs", true)
	v3_:register(XMLValueType.STRING_LIST, "vehicle.ai#supportedJobTypes", "List of job names that are supported (AIJobConveyor, AIJobDeliver, AIJobGoTo, AIJobLoadAndDeliver, AIJobFieldWork)", "all jobs if no names are given")
	v3_:setXMLSpecializationType()
	local v4_ = Vehicle.xmlSchemaSavegame
	v4_:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiJobVehicle#isAIStartAllowed", "If ai start is allowed", true)
	v4_:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiJobVehicle#isAIStopAllowed", "If ai stop is allowed", true)
	v4_:register(XMLValueType.STRING, "vehicles.vehicle(?).aiJobVehicle.lastJob#type", "Last job name", nil)
end

function AIJobVehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIJobStarted")
	SpecializationUtil.registerEvent(vehicleType, "onAIJobFinished")
	SpecializationUtil.registerEvent(vehicleType, "onAIJobVehicleBlock")
	SpecializationUtil.registerEvent(vehicleType, "onAIJobVehicleContinue")
end

function AIJobVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getShowAIToggleActionEvent", AIJobVehicle.getShowAIToggleActionEvent)
	SpecializationUtil.registerFunction(vehicleType, "stopCurrentAIJob", AIJobVehicle.stopCurrentAIJob)
	SpecializationUtil.registerFunction(vehicleType, "skipCurrentTask", AIJobVehicle.skipCurrentTask)
	SpecializationUtil.registerFunction(vehicleType, "aiJobStarted", AIJobVehicle.aiJobStarted)
	SpecializationUtil.registerFunction(vehicleType, "aiJobFinished", AIJobVehicle.aiJobFinished)
	SpecializationUtil.registerFunction(vehicleType, "toggleAIVehicle", AIJobVehicle.toggleAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleAIVehicle", AIJobVehicle.getCanToggleAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCanStartAIVehicle", AIJobVehicle.getCanStartAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCanStopAIVehicle", AIJobVehicle.getCanStopAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIJobSupported", AIJobVehicle.getIsAIJobSupported)
	SpecializationUtil.registerFunction(vehicleType, "setAIMapHotspotBlinking", AIJobVehicle.setAIMapHotspotBlinking)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentHelper", AIJobVehicle.getCurrentHelper)
	SpecializationUtil.registerFunction(vehicleType, "aiBlock", AIJobVehicle.aiBlock)
	SpecializationUtil.registerFunction(vehicleType, "aiContinue", AIJobVehicle.aiContinue)
	SpecializationUtil.registerFunction(vehicleType, "getAIDirectionNode", AIJobVehicle.getAIDirectionNode)
	SpecializationUtil.registerFunction(vehicleType, "getAISteeringNode", AIJobVehicle.getAISteeringNode)
	SpecializationUtil.registerFunction(vehicleType, "getAIReverserNode", AIJobVehicle.getAIReverserNode)
	SpecializationUtil.registerFunction(vehicleType, "getAISteeringSpeed", AIJobVehicle.getAISteeringSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getAIJobFarmId", AIJobVehicle.getAIJobFarmId)
	SpecializationUtil.registerFunction(vehicleType, "getStartableAIJob", AIJobVehicle.getStartableAIJob)
	SpecializationUtil.registerFunction(vehicleType, "getHasStartableAIJob", AIJobVehicle.getHasStartableAIJob)
	SpecializationUtil.registerFunction(vehicleType, "getStartAIJobText", AIJobVehicle.getStartAIJobText)
	SpecializationUtil.registerFunction(vehicleType, "getJob", AIJobVehicle.getJob)
	SpecializationUtil.registerFunction(vehicleType, "getLastJob", AIJobVehicle.getLastJob)
	SpecializationUtil.registerFunction(vehicleType, "setIsAIStartAllowed", AIJobVehicle.setIsAIStartAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setIsAIStopAllowed", AIJobVehicle.setIsAIStopAllowed)
end

function AIJobVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer", AIJobVehicle.getIsVehicleControlledByPlayer)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", AIJobVehicle.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIActive", AIJobVehicle.getIsAIActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowTireTracks", AIJobVehicle.getAllowTireTracks)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", AIJobVehicle.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStopMotorOnLeave", AIJobVehicle.getStopMotorOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDisableVehicleCharacterOnLeave", AIJobVehicle.getDisableVehicleCharacterOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName", AIJobVehicle.getFullName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", AIJobVehicle.getActiveFarm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", AIJobVehicle.getIsMapHotspotVisible)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMapHotspot", AIJobVehicle.getMapHotspot)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateLightsOnLeave", AIJobVehicle.getDeactivateLightsOnLeave)
end

function AIJobVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onAIModeChanged", AIJobVehicle)
end

-- Local values: spec, aiJobTypeManager, savegameKey, jobKey, jobTypeName, jobTypeIndex, job
function AIJobVehicle:onLoad(savegame)
	local v11_ = self.spec_aiJobVehicle
	v11_.actionEvents = {}
	v11_.job = nil
	v11_.lastJob = nil
	v11_.startedFarmId = nil
	v11_.aiSteeringSpeed = self.xmlFile:getValue("vehicle.ai.steeringSpeed", 1) * 0.001
	v11_.steeringNode = self.xmlFile:getValue("vehicle.ai.steeringNode#node", nil, self.components, self.i3dMappings)
	v11_.reverserNode = self.xmlFile:getValue("vehicle.ai.reverserNode#node", nil, self.components, self.i3dMappings)
	v11_.supportsAIJobs = self.xmlFile:getValue("vehicle.ai#supportsAIJobs", true)
	v11_.supportedJobTypes = self.xmlFile:getValue("vehicle.ai#supportedJobTypes", nil)
	v11_.isAIStartAllowed = true
	v11_.isAIStopAllowed = true
	v11_.texts = {}
	v11_.texts.dismissEmployee = g_i18n:getText("action_dismissEmployee")
	v11_.texts.openHelperMenu = g_i18n:getText("action_openHelperMenu")
	v11_.texts.hireEmployee = g_i18n:getText("action_hireEmployee")
	if savegame ~= nil then
		local v12_ = g_currentMission.aiJobTypeManager
		local v13_ = savegame.key .. ".aiJobVehicle"
		local v14_ = v13_ .. ".lastJob"
		local v15_ = v12_:getJobTypeIndexByName((savegame.xmlFile:getString(v14_ .. "#type")))
		if v15_ ~= nil then
			local v16_ = v12_:createJob(v15_)
			if v16_ ~= nil and v16_.loadFromXMLFile ~= nil then
				v16_:loadFromXMLFile(savegame.xmlFile, v14_)
				v11_.lastJob = v16_
			end
		end
		v11_.isAIStartAllowed = savegame.xmlFile:getValue(v13_ .. "#isAIStartAllowed", v11_.isAIStartAllowed)
		v11_.isAIStopAllowed = savegame.xmlFile:getValue(v13_ .. "#isAIStopAllowed", v11_.isAIStopAllowed)
	end
end

-- Local values: spec
function AIJobVehicle:onDelete()
	local v18_ = self.spec_aiJobVehicle
	if self.isServer and v18_.job ~= nil then
		self:stopCurrentAIJob()
	end
	if v18_.mapAIHotspot ~= nil then
		v18_.mapAIHotspot:delete()
		v18_.mapAIHotspot = nil
	end
end

-- Local values: hasJob, jobId, startedFarmId, helperIndex, job, hasLastJob, jobTypeIndex, spec
function AIJobVehicle:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		local v22_ = streamReadInt32(streamId)
		local v23_ = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local v24_ = streamReadUInt8(streamId)
		self:aiJobStarted(g_currentMission.aiSystem:getJobById(v22_), v24_, v23_)
	end
	if streamReadBool(streamId) then
		local v25_ = streamReadInt32(streamId)
		local v26_ = self.spec_aiJobVehicle
		v26_.lastJob = g_currentMission.aiJobTypeManager:createJob(v25_)
		v26_.lastJob:readStream(streamId, connection)
	end
end

-- Local values: spec, jobTypeIndex
function AIJobVehicle:onWriteStream(streamId, connection)
	local v30_ = self.spec_aiJobVehicle
	if streamWriteBool(streamId, v30_.job ~= nil) then
		streamWriteInt32(streamId, v30_.job.jobId)
		streamWriteUIntN(streamId, v30_.startedFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteUInt8(streamId, v30_.currentHelper.index)
	end
	if streamWriteBool(streamId, v30_.lastJob ~= nil) then
		local v31_ = g_currentMission.aiJobTypeManager:getJobTypeIndex(v30_.lastJob)
		streamWriteInt32(streamId, v31_)
		v30_.lastJob:writeStream(streamId, connection)
	end
end

-- Local values: spec
function AIJobVehicle:onAIModeChanged(aiMode)
	if aiMode ~= AIModeSelection.MODE.WORKER and self.spec_aiJobVehicle.job ~= nil then
		self:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
	end
end

function AIJobVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsAIActive() then
		self:raiseActive()
	end
end

function AIJobVehicle:getShowAIToggleActionEvent()
	if self:getAIDirectionNode() == nil then
		return false
	elseif g_currentMission.disableAIVehicle then
		return false
	elseif g_currentMission:getHasPlayerPermission("hireAssistant") then
		return (self:getIsAIActive() or not g_currentMission.aiSystem:getAILimitedReached()) and true or false
	else
		return false
	end
end

-- Local values: spec
function AIJobVehicle:stopCurrentAIJob(aiMessage)
	local v38_ = self.spec_aiJobVehicle
	if v38_.job ~= nil then
		g_currentMission.aiSystem:stopJob(v38_.job, aiMessage)
	end
end

-- Local values: spec
function AIJobVehicle:skipCurrentTask()
	local v40_ = self.spec_aiJobVehicle
	if v40_.job ~= nil then
		g_currentMission.aiSystem:skipCurrentTask(v40_.job)
	end
end

-- Local values: spec
function AIJobVehicle:aiJobStarted(job, helperIndex, startedFarmId)
	local v45_ = self.spec_aiJobVehicle
	if not self:getIsAIActive() then
		if self.isServer then
			g_server:broadcastEvent(AIJobVehicleStateEvent.new(self, job, helperIndex, startedFarmId))
			g_currentMission.aiSystem:addJobVehicle(self)
		end
		v45_.job = job
		v45_.lastJob = job
		v45_.startedFarmId = startedFarmId
		v45_.currentHelperIndex = helperIndex
		v45_.currentHelper = g_helperManager:getHelperByIndex(helperIndex)
		g_helperManager:useHelper(v45_.currentHelper)
		if self.isServer then
			g_farmManager:updateFarmStats(startedFarmId, "workersHired", 1)
		end
		if self.setRandomVehicleCharacter ~= nil then
			self:setRandomVehicleCharacter(v45_.currentHelper)
		end
		if v45_.mapAIHotspot == nil then
			v45_.mapAIHotspot = AIHotspot.new()
			v45_.mapAIHotspot:setVehicle(self)
		end
		v45_.mapAIHotspot:setAIHelperName(v45_.currentHelper.name)
		g_currentMission:addMapHotspot(v45_.mapAIHotspot)
		if Platform.isMobile then
			self:updateMapHotspot()
		end
		SpecializationUtil.raiseEvent(self, "onAIJobStarted", job)
		self:requestActionEventUpdate()
		self:raiseActive()
	end
	g_messageCenter:publish(MessageType.AI_VEHICLE_STATE_CHANGE, true, self)
end

-- Local values: spec
function AIJobVehicle:aiJobFinished()
	local v47_ = self.spec_aiJobVehicle
	if self:getIsAIActive() then
		if self.isServer then
			g_server:broadcastEvent(AIJobVehicleStateEvent.new(self, nil, nil, nil))
			g_currentMission.aiSystem:removeJobVehicle(self)
		end
		g_helperManager:releaseHelper(v47_.currentHelper)
		v47_.currentHelperIndex = nil
		v47_.currentHelper = nil
		if self.isServer then
			g_farmManager:updateFarmStats(v47_.startedFarmId, "workersHired", -1)
		end
		if self.restoreVehicleCharacter ~= nil then
			self:restoreVehicleCharacter()
		end
		if v47_.mapAIHotspot ~= nil then
			g_currentMission:removeMapHotspot(v47_.mapAIHotspot)
		end
		SpecializationUtil.raiseEvent(self, "onAIJobFinished", v47_.job)
		v47_.job = nil
		if Platform.isMobile then
			self:updateMapHotspot()
		end
		self:requestActionEventUpdate()
	end
	g_messageCenter:publish(MessageType.AI_VEHICLE_STATE_CHANGE, false, self)
end

function AIJobVehicle:getIsVehicleControlledByPlayer(superFunc)
	if superFunc(self) then
		return self.spec_aiJobVehicle.job == nil
	else
		return false
	end
end

function AIJobVehicle:getIsInUse(superFunc, connection)
	return self:getIsAIActive() and true or superFunc(self, connection)
end

function AIJobVehicle:getIsActive(superFunc)
	return self:getIsAIActive() and true or superFunc(self)
end

function AIJobVehicle:getAIJobFarmId()
	return self.spec_aiJobVehicle.startedFarmId
end

function AIJobVehicle:getIsAIActive(superFunc)
	return superFunc(self) or self.spec_aiJobVehicle.job ~= nil
end

function AIJobVehicle:getStartableAIJob()
	return nil
end

function AIJobVehicle:getHasStartableAIJob()
	return false
end

-- Local values: spec, hasJob
function AIJobVehicle:getStartAIJobText()
	local v59_ = self.spec_aiJobVehicle
	if self:getHasStartableAIJob() then
		return v59_.texts.hireEmployee
	else
		return v59_.texts.openHelperMenu
	end
end

function AIJobVehicle:getJob()
	return self.spec_aiJobVehicle.job
end

function AIJobVehicle:getLastJob()
	return self.spec_aiJobVehicle.lastJob
end

-- Local values: startableJob, inGameMap, playerHotspot
function AIJobVehicle:toggleAIVehicle()
	if self:getIsAIActive() then
		self:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
		return
	else
		local v63_ = self:getStartableAIJob()
		if v63_ == nil then
			if g_guidedTourManager:getIsTourRunning() then
				return
			elseif Platform.isMobile then
				g_gui:changeScreen(nil, InGameMenu)
				g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self)
				local v64_ = g_currentMission.hud:getIngameMap()
				v64_:updateHotspotSorting()
				local v65_ = g_inGameMenu.pageMapMobile.inGameMap:getPlayerHotspot(v64_.hotspotsSorted[true])
				g_inGameMenu.pageMapMobile:onClickHotspot(nil, v65_)
				g_inGameMenu.pageMapMobile:onClickPagingAI()
			else
				g_gui:showGui("InGameMenu")
				g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self)
			end
		else
			g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(v63_, self:getOwnerFarmId()))
			return
		end
	end
end

function AIJobVehicle:getCanToggleAIVehicle()
	if self:getIsAIActive() then
		return self:getCanStopAIVehicle()
	else
		return self:getCanStartAIVehicle()
	end
end

-- Local values: spec
function AIJobVehicle:getCanStopAIVehicle()
	return self.spec_aiJobVehicle.isAIStopAllowed and true or false
end

-- Local values: spec
function AIJobVehicle:getCanStartAIVehicle()
	if g_currentMission.disableAIVehicle then
		return false
	elseif self:getOwnerFarmId() == AccessHandler.EVERYONE then
		return false
	else
		local v69_ = self.spec_aiJobVehicle
		if v69_.supportsAIJobs then
			if v69_.isAIStartAllowed then
				if self:getAIDirectionNode() == nil then
					return false
				elseif g_currentMission.aiSystem:getAILimitedReached() then
					return false
				elseif self:getIsAIActive() then
					return false
				else
					return not self.isBroken
				end
			else
				return false
			end
		else
			return false
		end
	end
end

-- Local values: spec, _, supportedJobName
function AIJobVehicle:getIsAIJobSupported(aiJobName)
	local v72_ = self.spec_aiJobVehicle
	if v72_.supportedJobTypes == nil then
		return true
	end
	for _, v73_ in ipairs(v72_.supportedJobTypes) do
		if string.lower(v73_) == string.lower(aiJobName) then
			return true
		end
	end
	return false
end

function AIJobVehicle:setIsAIStartAllowed(isAllowed)
	self.spec_aiJobVehicle.isAIStartAllowed = isAllowed
end

function AIJobVehicle:setIsAIStopAllowed(isAllowed)
	self.spec_aiJobVehicle.isAIStopAllowed = isAllowed
end

-- Local values: spec
function AIJobVehicle:setAIMapHotspotBlinking(isBlinking)
	local v80_ = self.spec_aiJobVehicle
	if v80_.mapAIHotspot ~= nil then
		v80_.mapAIHotspot:setBlinking(isBlinking)
	end
end

-- Local values: spec
function AIJobVehicle:getMapHotspot(superFunc)
	local v83_ = self.spec_aiJobVehicle
	if self:getIsAIActive() and v83_.mapAIHotspot ~= nil then
		return v83_.mapAIHotspot
	else
		return superFunc(self)
	end
end

function AIJobVehicle:getDeactivateLightsOnLeave(superFunc)
	local v86_ = superFunc(self)
	if v86_ then
		v86_ = not self:getIsAIActive()
	end
	return v86_
end

function AIJobVehicle:onSetBroken()
	if self:getIsAIActive() then
		self:stopCurrentAIJob(AIMessageErrorVehicleBroken.new())
	end
end

function AIJobVehicle:getDeactivateOnLeave(superFunc)
	local v90_ = superFunc(self)
	if v90_ then
		v90_ = not self:getIsAIActive()
	end
	return v90_
end

function AIJobVehicle:getStopMotorOnLeave(superFunc)
	local v93_ = superFunc(self)
	if v93_ then
		v93_ = not self:getIsAIActive()
	end
	return v93_
end

function AIJobVehicle:getDisableVehicleCharacterOnLeave(superFunc)
	local v96_ = superFunc(self)
	if v96_ then
		v96_ = not self:getIsAIActive()
	end
	return v96_
end

function AIJobVehicle:getAllowTireTracks(superFunc)
	local v99_ = superFunc(self)
	if v99_ then
		v99_ = not self:getIsAIActive()
	end
	return v99_
end

function AIJobVehicle:getCurrentHelper()
	return self.spec_aiJobVehicle.currentHelper
end

-- Local values: name, helperName, currentHelper
function AIJobVehicle:getFullName(superFunc)
	local v103_ = superFunc(self)
	if self:getIsAIActive() then
		local v104_ = g_i18n:getText("ui_helper")
		local v105_ = self:getCurrentHelper()
		if v105_ ~= nil then
			v104_ = v104_ .. " " .. v105_.name
		end
		v103_ = v103_ .. " (" .. v104_ .. ")"
	end
	return v103_
end

-- Local values: currentHelper, name, text
function AIJobVehicle:aiBlock()
	if self.isClient and g_localPlayer.farmId == self:getAIJobFarmId() then
		local v107_ = self:getCurrentHelper()
		local v108_ = v107_ == nil and "" or v107_.name
		local v109_ = string.format(g_i18n:getText("ai_messageErrorBlockedByObject"), v108_)
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, v109_)
	end
	self:raiseAIEvent("onAIJobVehicleBlock", "onAIImplementJobVehicleBlock")
end

function AIJobVehicle:aiContinue()
	self:raiseAIEvent("onAIJobVehicleContinue", "onAIImplementJobVehicleContinue")
end

function AIJobVehicle:getAIDirectionNode()
	return self.components[1].node
end

function AIJobVehicle:getAISteeringNode()
	return self.spec_aiJobVehicle.steeringNode or self:getAIDirectionNode()
end

function AIJobVehicle:getAIReverserNode()
	return self.spec_aiJobVehicle.reverserNode or self:getAISteeringNode()
end

function AIJobVehicle:getAISteeringSpeed()
	return self.spec_aiJobVehicle.aiSteeringSpeed
end

-- Local values: spec, jobTypeIndex, jobType
function AIJobVehicle:saveToXMLFile(xmlFile, key, usedModNames)
	local v119_ = self.spec_aiJobVehicle
	if v119_.lastJob ~= nil then
		local v120_ = v119_.lastJob.jobTypeIndex
		local v121_ = g_currentMission.aiJobTypeManager:getJobTypeByIndex(v120_)
		xmlFile:setString(key .. ".lastJob#type", v121_.name)
		v119_.lastJob:saveToXMLFile(xmlFile, key .. ".lastJob", usedModNames)
	end
	xmlFile:setValue(key .. "#isAIStartAllowed", v119_.isAIStartAllowed)
end

function AIJobVehicle:saveStatsToXMLFile(xmlFile, key)
	setXMLBool(xmlFile, key .. "#isAIActive", self:getIsAIActive())
end

-- Local values: starter
function AIJobVehicle:getActiveFarm(superFunc)
	local v127_ = self:getAIJobFarmId()
	if v127_ == nil then
		return superFunc(self)
	else
		return v127_
	end
end

function AIJobVehicle:getIsMapHotspotVisible(superFunc)
	if superFunc(self) then
		return not self:getIsAIActive()
	else
		return false
	end
end
