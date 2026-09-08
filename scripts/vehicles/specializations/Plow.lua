source("dataS/scripts/vehicles/specializations/events/PlowRotationCenterEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PlowRotationEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PlowLimitToFieldEvent.lua")
Plow = {}
Plow.AI_REQUIRED_GROUND_TYPES = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.CULTIVATED,
	FieldGroundType.SEEDBED,
	FieldGroundType.ROLLED_SEEDBED,
	FieldGroundType.RIDGE,
	FieldGroundType.SOWN,
	FieldGroundType.DIRECT_SOWN,
	FieldGroundType.PLANTED,
	FieldGroundType.RIDGE_SOWN,
	FieldGroundType.ROLLER_LINES,
	FieldGroundType.HARVEST_READY,
	FieldGroundType.HARVEST_READY_OTHER,
	FieldGroundType.GRASS,
	FieldGroundType.GRASS_CUT
}
Plow.AI_OUTPUT_GROUND_TYPES = { FieldGroundType.PLOWED }
Plow.CLIENT_DM_UPDATE_RADIUS = 50
function Plow.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("plow", g_i18n:getText("configuration_design"), "plow", VehicleConfigurationItem)
	g_workAreaTypeManager:addWorkAreaType("plow", true, true, true)
	g_workAreaTypeManager:addWorkAreaType("plowShare", true, false, false)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Plow")
	Plow.registerXMLPaths(v1_, "vehicle.plow")
	Plow.registerXMLPaths(v1_, "vehicle.plow.plowConfigurations.plowConfiguration(?)")
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#disableOnTurn", "Disable while turning", true)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#turnAnimLimit", "Turn animation limit", 0)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#turnAnimLimitSide", "Turn animation limit side", 0)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#invertDirectionOnRotation", "Invert direction on rotation", true)
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.BOOL, "vehicles.vehicle(?).plow#rotationMax", "Rotation max.")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).plow#turnAnimTime", "Turn animation time")
end

function Plow.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".rotationPart#turnAnimationName", "Turn animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldMinLimit", "Fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldMaxLimit", "Fold max. limit", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".rotationPart#limitFoldRotationMax", "Block folding if in max state")
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldRotationMinLimit", "Fold allow if inbetween this limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldRotationMaxLimit", "Fold allow if inbetween this limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#rotationFoldMinLimit", "Rotation allow if fold time inbetween this limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#rotationFoldMaxLimit", "Rotation allow if fold time inbetween this limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#detachMinLimit", "Detach is allowed if turn animation between these values", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#detachMaxLimit", "Detach is allowed if turn animation between these values", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".rotationPart#rotationAllowedIfLowered", "Allow plow rotation if lowered", true)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".rotationPart#detachWarning", "Warning to be displayed if not in correct turn state for detach", "warning_detachNotAllowedPlowTurn")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".directionNode#node", "Plow direction node")
	schema:register(XMLValueType.FLOAT, basePath .. ".ai#centerPosition", "Center position", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".ai#rotateToCenterHeadlandPos", "Rotate to center headland position", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".ai#rotateCompletelyHeadlandPos", "Rotate completely headland position", 0.5)
	schema:register(XMLValueType.BOOL, basePath .. ".ai#stopDuringTurn", "Stop the vehicle while the plow is turning", true)
	schema:register(XMLValueType.BOOL, basePath .. ".ai#allowTurnWhileReversing", "Allow the turn of the plow while we are reversing", true)
	schema:register(XMLValueType.BOOL, basePath .. ".rotateLeftToMax#value", "Rotate left to max", true)
	schema:register(XMLValueType.BOOL, basePath .. ".onlyActiveWhenLowered#value", "Only active when lowered", true)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "turn(?)")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "work(?)")
end

function Plow.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end

function Plow.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processPlowArea", Plow.processPlowArea)
	SpecializationUtil.registerFunction(vehicleType, "processPlowShareArea", Plow.processPlowShareArea)
	SpecializationUtil.registerFunction(vehicleType, "setRotationMax", Plow.setRotationMax)
	SpecializationUtil.registerFunction(vehicleType, "setRotationCenter", Plow.setRotationCenter)
	SpecializationUtil.registerFunction(vehicleType, "setPlowLimitToField", Plow.setPlowLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlowRotationAllowed", Plow.getIsPlowRotationAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getCanTogglePlowRotation", Plow.getCanTogglePlowRotation)
	SpecializationUtil.registerFunction(vehicleType, "getPlowLimitToField", Plow.getPlowLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "getPlowForceLimitToField", Plow.getPlowForceLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "setPlowAIRequirements", Plow.setPlowAIRequirements)
end

function Plow.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Plow.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldMiddleAllowed", Plow.getIsFoldMiddleAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Plow.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Plow.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Plow.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Plow.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSpeedRotatingPartDirection", Plow.getSpeedRotatingPartDirection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Plow.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Plow.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Plow.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Plow.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIInvertMarkersOnTurn", Plow.getAIInvertMarkersOnTurn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Plow.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Plow.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", Plow.getAllowsLowering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", Plow.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", Plow.getIsAIPreparingToDrive)
end

function Plow.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStartTurn", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementTurnProgress", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEndTurn", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementSideOffsetChanged", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onStartAnimation", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Plow)
end

-- Local values: plowConfigurationId, configKey, spec
function Plow:onLoad(savegame)
	if self:getGroundReferenceNodeFromIndex(1) == nil then
		printWarning("Warning: No ground reference nodes in " .. self.configFileName)
	end
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rotationPart", "vehicle.plow.rotationPart")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ploughDirectionNode#index", "vehicle.plow.directionNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rotateLeftToMax#value", "vehicle.plow.rotateLeftToMax#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.animTimeCenterPosition#value", "vehicle.plow.ai#centerPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.aiPlough#rotateEarly", "vehicle.plow.ai#rotateCompletelyHeadlandPos")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.onlyActiveWhenLowered#value", "vehicle.plow.onlyActiveWhenLowered#value")
	local v10_ = self.configurations.plow or 1
	local v11_ = string.format("vehicle.plow.plowConfigurations.plowConfiguration(%d)", v10_ - 1)
	local v12_ = not self.xmlFile:hasProperty(v11_) and "vehicle.plow" or v11_
	local v13_ = self.spec_plow
	v13_.rotationPart = {}
	v13_.rotationPart.turnAnimation = self.xmlFile:getValue(v12_ .. ".rotationPart#turnAnimationName")
	v13_.rotationPart.foldMinLimit = self.xmlFile:getValue(v12_ .. ".rotationPart#foldMinLimit", 0)
	v13_.rotationPart.foldMaxLimit = self.xmlFile:getValue(v12_ .. ".rotationPart#foldMaxLimit", 1)
	v13_.rotationPart.limitFoldRotationMax = self.xmlFile:getValue(v12_ .. ".rotationPart#limitFoldRotationMax")
	v13_.rotationPart.foldRotationMinLimit = self.xmlFile:getValue(v12_ .. ".rotationPart#foldRotationMinLimit", 0)
	v13_.rotationPart.foldRotationMaxLimit = self.xmlFile:getValue(v12_ .. ".rotationPart#foldRotationMaxLimit", 1)
	v13_.rotationPart.rotationFoldMinLimit = self.xmlFile:getValue(v12_ .. ".rotationPart#rotationFoldMinLimit", 0)
	v13_.rotationPart.rotationFoldMaxLimit = self.xmlFile:getValue(v12_ .. ".rotationPart#rotationFoldMaxLimit", 1)
	v13_.rotationPart.detachMinLimit = self.xmlFile:getValue(v12_ .. ".rotationPart#detachMinLimit", 0)
	v13_.rotationPart.detachMaxLimit = self.xmlFile:getValue(v12_ .. ".rotationPart#detachMaxLimit", 1)
	v13_.rotationPart.rotationAllowedIfLowered = self.xmlFile:getValue(v12_ .. ".rotationPart#rotationAllowedIfLowered", true)
	v13_.rotationPart.detachWarning = string.format(self.xmlFile:getValue(v12_ .. ".rotationPart#detachWarning", "warning_detachNotAllowedPlowTurn", self.customEnvironment, false))
	v13_.directionNode = self.xmlFile:getValue(v12_ .. ".directionNode#node", self.components[1].node, self.components, self.i3dMappings)
	self:setPlowAIRequirements()
	v13_.ai = {}
	v13_.ai.centerPosition = self.xmlFile:getValue(v12_ .. ".ai#centerPosition", 0.5)
	v13_.ai.rotateToCenterHeadlandPos = self.xmlFile:getValue(v12_ .. ".ai#rotateToCenterHeadlandPos", 0.5)
	v13_.ai.rotateCompletelyHeadlandPos = self.xmlFile:getValue(v12_ .. ".ai#rotateCompletelyHeadlandPos", 0.5)
	v13_.ai.stopDuringTurn = self.xmlFile:getValue(v12_ .. ".ai#stopDuringTurn", true)
	v13_.ai.allowTurnWhileReversing = self.xmlFile:getValue(v12_ .. ".ai#allowTurnWhileReversing", true)
	v13_.ai.lastHeadlandPosition = 0
	v13_.rotateLeftToMax = self.xmlFile:getValue(v12_ .. ".rotateLeftToMax#value", true)
	v13_.onlyActiveWhenLowered = self.xmlFile:getValue(v12_ .. ".onlyActiveWhenLowered#value", true)
	v13_.rotationMax = false
	v13_.startActivationTimeout = 2000
	v13_.startActivationTime = 0
	v13_.lastPlowArea = 0
	v13_.limitToField = true
	v13_.forceLimitToField = false
	v13_.wasTurnAnimationStopped = false
	v13_.isWorking = false
	if self.isClient then
		v13_.samples = {}
		v13_.samples.turn = g_soundManager:loadSamplesFromXML(self.xmlFile, v12_ .. ".sounds", "turn", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v13_.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, v12_ .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v13_.isWorkSamplePlaying = false
	end
	v13_.texts = {}
	v13_.texts.warningFoldingLowered = g_i18n:getText("warning_foldingNotWhileLowered")
	v13_.texts.warningFoldingPlowTurned = g_i18n:getText("warning_foldingNotWhilePlowTurned")
	v13_.texts.turnPlow = g_i18n:getText("action_turnPlow")
	v13_.texts.allowCreateFields = g_i18n:getText("action_allowCreateFields")
	v13_.texts.limitToFields = g_i18n:getText("action_limitToFields")
	v13_.workAreaParameters = {}
	v13_.workAreaParameters.limitToField = self:getPlowLimitToField()
	v13_.workAreaParameters.forceLimitToField = self:getPlowForceLimitToField()
	v13_.workAreaParameters.angle = 0
	v13_.workAreaParameters.lastChangedArea = 0
	v13_.workAreaParameters.lastStatsArea = 0
	v13_.workAreaParameters.lastTotalArea = 0
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdate", Plow)
	end
end

-- Local values: rotationMax, plowTurnAnimTime
function Plow:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local v16_ = savegame.xmlFile:getValue(savegame.key .. ".plow#rotationMax")
		if v16_ ~= nil and self:getIsPlowRotationAllowed() then
			self:setRotationMax(v16_, true, (savegame.xmlFile:getValue(savegame.key .. ".plow#turnAnimTime")))
			if self.updateCylinderedInitial ~= nil then
				self:updateCylinderedInitial(false)
			end
		end
	end
end

-- Local values: spec
function Plow:onDelete()
	local v18_ = self.spec_plow
	if v18_.samples ~= nil then
		g_soundManager:deleteSamples(v18_.samples.turn)
		g_soundManager:deleteSamples(v18_.samples.work)
	end
end

-- Local values: spec, turnAnimTime
function Plow:saveToXMLFile(xmlFile, key, usedModNames)
	local v22_ = self.spec_plow
	xmlFile:setValue(key .. "#rotationMax", v22_.rotationMax)
	if v22_.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
		local v23_ = self:getAnimationTime(v22_.rotationPart.turnAnimation)
		xmlFile:setValue(key .. "#turnAnimTime", v23_)
	end
end

-- Local values: spec, rotationMax, turnAnimTime
function Plow:onReadStream(streamId, connection)
	local v26_ = self.spec_plow
	local v27_ = streamReadBool(streamId)
	local v28_
	if v26_.rotationPart.turnAnimation == nil or self.playAnimation == nil then
		v28_ = nil
	else
		v28_ = streamReadFloat32(streamId)
	end
	self:setRotationMax(v27_, true, v28_)
	if self.updateCylinderedInitial ~= nil then
		self:updateCylinderedInitial(false)
	end
end

-- Local values: spec, turnAnimTime
function Plow:onWriteStream(streamId, connection)
	local v31_ = self.spec_plow
	streamWriteBool(streamId, v31_.rotationMax)
	if v31_.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
		local v32_ = self:getAnimationTime(v31_.rotationPart.turnAnimation)
		streamWriteFloat32(streamId, v32_)
	end
end

-- Local values: spec, actionEvent
function Plow:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v34_ = self.spec_plow
		local v35_ = v34_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
		if v35_ ~= nil then
			if self:getPlowForceLimitToField() or not g_currentMission:getHasPlayerPermission("createFields", self:getOwnerConnection()) then
				g_inputBinding:setActionEventActive(v35_.actionEventId, false)
			else
				g_inputBinding:setActionEventActive(v35_.actionEventId, true)
				if self:getPlowLimitToField() then
					g_inputBinding:setActionEventText(v35_.actionEventId, v34_.texts.allowCreateFields)
				else
					g_inputBinding:setActionEventText(v35_.actionEventId, v34_.texts.limitToFields)
				end
			end
		end
		if v34_.rotationPart.turnAnimation ~= nil then
			local v36_ = v34_.actionEvents[InputAction.IMPLEMENT_EXTRA]
			if v36_ ~= nil then
				g_inputBinding:setActionEventActive(v36_.actionEventId, self:getCanTogglePlowRotation())
			end
		end
	end
end

-- Local values: spec, xs, _, zs, xw, _, zw, xh, _, zh, params, changedArea, totalArea
function Plow:processPlowArea(workArea, dt)
	local v39_ = self.spec_plow
	local v40_, _, v41_ = getWorldTranslation(workArea.start)
	local v42_, _, v43_ = getWorldTranslation(workArea.width)
	local v44_, _, v45_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v40_, v41_, v42_, v43_, v44_, v45_)
	if not self.isServer and self.currentUpdateDistance > Plow.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v46_ = v39_.workAreaParameters
	local v47_, v48_
	if self.tailwaterDepth < 0.1 then
		local v49_
		v49_, v47_ = FSDensityMapUtil.updatePlowArea(v40_, v41_, v42_, v43_, v44_, v45_, not v46_.limitToField, v46_.limitFruitDestructionToField, v46_.angle)
		v48_ = v49_ + FSDensityMapUtil.updateVineCultivatorArea(v40_, v41_, v42_, v43_, v44_, v45_)
	else
		v48_ = 0
		v47_ = 0
	end
	v46_.lastChangedArea = v46_.lastChangedArea + v48_
	v46_.lastStatsArea = v46_.lastStatsArea + v48_
	v46_.lastTotalArea = v46_.lastTotalArea + v47_
	v39_.isWorking = self:getLastSpeed() > 0.5
	return v48_, v47_
end

-- Local values: spec, params, xs, _, zs, xw, _, zw, xh, _, zh
function Plow:processPlowShareArea(workArea, dt)
	local v52_ = self.spec_plow.workAreaParameters
	if not self.isServer and self.currentUpdateDistance > Plow.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v53_, _, v54_ = getWorldTranslation(workArea.start)
	local v55_, _, v56_ = getWorldTranslation(workArea.width)
	local v57_, _, v58_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.updatePlowShareArea(v53_, v54_, v55_, v56_, v57_, v58_, not v52_.limitToField, v52_.limitFruitDestructionToField, 0.5)
	return 0, 0
end

-- Local values: spec, animTime
function Plow:setRotationMax(rotationMax, noEventSend, turnAnimationTime)
	PlowRotationEvent.sendEvent(self, rotationMax, noEventSend)
	local v63_ = self.spec_plow
	v63_.rotationMax = rotationMax
	if v63_.rotationPart.turnAnimation ~= nil then
		if turnAnimationTime == nil then
			local v64_ = self:getAnimationTime(v63_.rotationPart.turnAnimation)
			if v63_.rotationMax then
				self:playAnimation(v63_.rotationPart.turnAnimation, 1, v64_, true)
			else
				self:playAnimation(v63_.rotationPart.turnAnimation, -1, v64_, true)
			end
		end
		self:setAnimationTime(v63_.rotationPart.turnAnimation, turnAnimationTime, true)
	end
end

-- Local values: spec, animTime
function Plow:setRotationCenter(noEventSend)
	local v67_ = self.spec_plow
	if v67_.rotationPart.turnAnimation ~= nil then
		local v68_ = self:getAnimationTime(v67_.rotationPart.turnAnimation)
		if v68_ ~= v67_.ai.centerPosition then
			self:setAnimationStopTime(v67_.rotationPart.turnAnimation, v67_.ai.centerPosition)
			if v68_ < v67_.ai.centerPosition then
				self:playAnimation(v67_.rotationPart.turnAnimation, 1, v68_, true)
			elseif v67_.ai.centerPosition < v68_ then
				self:playAnimation(v67_.rotationPart.turnAnimation, -1, v68_, true)
			end
		end
	end
	PlowRotationCenterEvent.sendEvent(self, noEventSend)
end

-- Local values: spec, actionEvent, text
function Plow:setPlowLimitToField(plowLimitToField, noEventSend)
	local v72_ = self.spec_plow
	if v72_.limitToField ~= plowLimitToField then
		if noEventSend == nil or noEventSend == false then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(PlowLimitToFieldEvent.new(self, plowLimitToField))
			else
				g_server:broadcastEvent(PlowLimitToFieldEvent.new(self, plowLimitToField), nil, nil, self)
			end
		end
		v72_.limitToField = plowLimitToField
		local v73_ = v72_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
		if v73_ ~= nil then
			local v74_
			if v72_.limitToField then
				v74_ = v72_.texts.allowCreateFields
			else
				v74_ = v72_.texts.limitToFields
			end
			g_inputBinding:setActionEventText(v73_.actionEventId, v74_)
		end
	end
end

-- Local values: spec, foldAnimTime
function Plow:getIsPlowRotationAllowed()
	local v76_ = self.spec_plow
	if self.getFoldAnimTime ~= nil then
		local v77_ = self:getFoldAnimTime()
		if v76_.rotationPart.rotationFoldMaxLimit < v77_ or v77_ < v76_.rotationPart.rotationFoldMinLimit then
			return false
		end
	end
	return true
end

-- Local values: spec
function Plow:getCanTogglePlowRotation()
	local v79_ = self.spec_plow
	if self:getIsPlowRotationAllowed() then
		if v79_.rotationPart.rotationAllowedIfLowered or (self.getIsLowered == nil or not self:getIsLowered()) then
			return self:getIsPowered() and true or false
		else
			return false
		end
	else
		return false
	end
end

function Plow:getPlowLimitToField()
	return self.spec_plow.limitToField
end

function Plow:getPlowForceLimitToField()
	return self.spec_plow.forceLimitToField or not Platform.gameplay.canCreateFields
end

function Plow:setPlowAIRequirements(excludedGroundTypes)
	if self.clearAITerrainDetailRequiredRange ~= nil then
		self:clearAITerrainDetailRequiredRange()
		if excludedGroundTypes == nil then
			self:addAIGroundTypeRequirements(Plow.AI_REQUIRED_GROUND_TYPES)
		else
			self:addAIGroundTypeRequirements(Plow.AI_REQUIRED_GROUND_TYPES, unpack(excludedGroundTypes))
		end
		self:setAIImplementVariableSideOffset(true)
	end
end

-- Local values: spec, rotationTime
function Plow:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v88_ = self.spec_plow
	if v88_.rotationPart.limitFoldRotationMax == nil or v88_.rotationPart.limitFoldRotationMax ~= v88_.rotationMax then
		if v88_.rotationPart.turnAnimation ~= nil and self.getAnimationTime ~= nil then
			local v89_ = self:getAnimationTime(v88_.rotationPart.turnAnimation)
			if v88_.rotationPart.foldRotationMaxLimit < v89_ or v89_ < v88_.rotationPart.foldRotationMinLimit then
				return false, v88_.texts.warningFoldingPlowTurned
			end
		end
		if v88_.rotationPart.rotationAllowedIfLowered or (self.getIsLowered == nil or not self:getIsLowered()) then
			return superFunc(self, direction, onAiTurnOn)
		else
			return false, v88_.texts.warningFoldingLowered
		end
	else
		return false, v88_.texts.warningFoldingPlowTurned
	end
end

-- Local values: spec, rotationTime
function Plow:getIsFoldMiddleAllowed(superFunc)
	local v92_ = self.spec_plow
	if v92_.rotationPart.limitFoldRotationMax ~= nil and v92_.rotationPart.limitFoldRotationMax == v92_.rotationMax then
		return false
	end
	if v92_.rotationPart.turnAnimation ~= nil and self.getAnimationTime ~= nil then
		local v93_ = self:getAnimationTime(v92_.rotationPart.turnAnimation)
		if v92_.rotationPart.foldRotationMaxLimit < v93_ or v93_ < v92_.rotationPart.foldRotationMinLimit then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: multiplier, spec
function Plow:getDirtMultiplier(superFunc)
	local v96_ = superFunc(self)
	if self.spec_plow.isWorking then
		v96_ = v96_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v96_
end

-- Local values: multiplier, spec
function Plow:getWearMultiplier(superFunc)
	local v99_ = superFunc(self)
	if self.spec_plow.isWorking then
		v99_ = v99_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v99_
end

function Plow:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end
	speedRotatingPart.disableOnTurn = xmlFile:getValue(key .. "#disableOnTurn", true)
	speedRotatingPart.turnAnimLimit = xmlFile:getValue(key .. "#turnAnimLimit", 0)
	speedRotatingPart.turnAnimLimitSide = xmlFile:getValue(key .. "#turnAnimLimitSide", 0)
	speedRotatingPart.invertDirectionOnRotation = xmlFile:getValue(key .. "#invertDirectionOnRotation", true)
	return true
end

-- Local values: spec, turnAnimTime, enabled
function Plow:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local v108_ = self.spec_plow
	if v108_.rotationPart.turnAnimation ~= nil and speedRotatingPart.disableOnTurn then
		local v109_ = self:getAnimationTime(v108_.rotationPart.turnAnimation)
		if v109_ ~= nil then
			local v110_
			if speedRotatingPart.turnAnimLimitSide < 0 then
				v110_ = v109_ <= speedRotatingPart.turnAnimLimit
			elseif speedRotatingPart.turnAnimLimitSide > 0 then
				v110_ = 1 - v109_ <= speedRotatingPart.turnAnimLimit
			else
				v110_ = v109_ <= speedRotatingPart.turnAnimLimit and true or 1 - v109_ <= speedRotatingPart.turnAnimLimit
			end
			if not v110_ then
				return false
			end
		end
	end
	return superFunc(self, speedRotatingPart)
end

-- Local values: spec, turnAnimTime
function Plow:getSpeedRotatingPartDirection(superFunc, speedRotatingPart)
	local v114_ = self.spec_plow
	return v114_.rotationPart.turnAnimation ~= nil and (self:getAnimationTime(v114_.rotationPart.turnAnimation) > 0.5 and speedRotatingPart.invertDirectionOnRotation) and -1 or superFunc(self, speedRotatingPart)
end

function Plow:doCheckSpeedLimit(superFunc)
	local v117_ = not superFunc(self) and self.spec_plow.onlyActiveWhenLowered
	if v117_ then
		v117_ = self:getIsImplementChainLowered()
	end
	return v117_
end

-- Local values: retValue
function Plow:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v123_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.PLOW
	end
	return v123_
end
function Plow.getDefaultSpeedLimit()
	return 15
end

-- Local values: spec
function Plow:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.PLOW then
		local v127_ = self.spec_plow
		if v127_.startActivationTime > g_currentMission.time then
			return false
		end
		if v127_.onlyActiveWhenLowered and (self.getIsLowered ~= nil and not self:getIsLowered(false)) then
			return false
		end
	end
	return superFunc(self, workArea)
end

-- Local values: canContinue, stopAI, stopReason, spec
function Plow:getCanAIImplementContinueWork(superFunc, isTurning)
	local v131_, v132_, v133_ = superFunc(self, isTurning)
	if not v131_ then
		return false, v132_, v133_
	end
	local v134_ = self.spec_plow
	return not v134_.ai.stopDuringTurn and isTurning and true or not self:getIsAnimationPlaying(v134_.rotationPart.turnAnimation)
end

-- Local values: spec
function Plow:getAIInvertMarkersOnTurn(superFunc, turnLeft)
	local v137_ = self.spec_plow
	if v137_.rotationPart.turnAnimation == nil then
		return false
	elseif turnLeft then
		return v137_.rotationMax == v137_.rotateLeftToMax
	else
		return v137_.rotationMax ~= v137_.rotateLeftToMax
	end
end

function Plow:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec, animTime
function Plow:isDetachAllowed(superFunc)
	local v140_ = self.spec_plow
	if self:getIsAnimationPlaying(v140_.rotationPart.turnAnimation) then
		return false
	end
	if v140_.rotationPart.turnAnimation ~= nil then
		local v141_ = self:getAnimationTime(v140_.rotationPart.turnAnimation)
		if v141_ < v140_.rotationPart.detachMinLimit or v140_.rotationPart.detachMaxLimit < v141_ then
			return false, v140_.rotationPart.detachWarning, true
		end
	end
	return superFunc(self)
end

-- Local values: spec
function Plow:getAllowsLowering(superFunc)
	if self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation) then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Plow:getIsAIReadyToDrive(superFunc)
	local v146_ = self.spec_plow
	if v146_.rotationMax or self:getIsAnimationPlaying(v146_.rotationPart.turnAnimation) then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Plow:getIsAIPreparingToDrive(superFunc)
	return self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation) and true or superFunc(self)
end

-- Local values: spec, _, actionEventId, _, actionEventId
function Plow:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v151_ = self.spec_plow
		self:clearActionEventsTable(v151_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if v151_.rotationPart.turnAnimation ~= nil then
				local _, v152_ = self:addPoweredActionEvent(v151_.actionEvents, InputAction.IMPLEMENT_EXTRA, self, Plow.actionEventTurn, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v152_, GS_PRIO_HIGH)
				g_inputBinding:setActionEventText(v152_, v151_.texts.turnPlow)
			end
			local _, v153_ = self:addActionEvent(v151_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Plow.actionEventLimitToField, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v153_, GS_PRIO_NORMAL)
		end
	end
end

-- Local values: spec, limitToField, limitFruitDestructionToField, dx, _, dz, angle
function Plow:onStartWorkAreaProcessing(dt)
	local v155_ = self.spec_plow
	v155_.isWorking = false
	local v156_ = self:getPlowLimitToField()
	local v157_
	if g_currentMission:getHasPlayerPermission("createFields", self:getOwnerConnection(), nil, true) then
		v157_ = v156_
	else
		v156_ = true
		v157_ = true
	end
	local v158_, _, v159_ = localDirectionToWorld(v155_.directionNode, 0, 0, 1)
	local v160_ = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(v158_, v159_), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	v155_.workAreaParameters.limitToField = v156_
	v155_.workAreaParameters.limitFruitDestructionToField = v157_
	v155_.workAreaParameters.angle = v160_
	v155_.workAreaParameters.lastChangedArea = 0
	v155_.workAreaParameters.lastStatsArea = 0
	v155_.workAreaParameters.lastTotalArea = 0
end

-- Local values: spec, farmId, lastStatsArea, ha
function Plow:onEndWorkAreaProcessing(dt)
	local v163_ = self.spec_plow
	if self.isServer then
		local v164_ = self:getLastTouchedFarmlandFarmId()
		local v165_ = v163_.workAreaParameters.lastStatsArea
		if v165_ > 0 then
			local v166_ = MathUtil.areaToHa(v165_, g_currentMission:getFruitPixelsToSqm())
			g_farmManager:updateFarmStats(v164_, "plowedHectares", v166_)
			self:updateLastWorkedArea(v165_)
		end
		if v163_.isWorking then
			g_farmManager:updateFarmStats(v164_, "plowedTime", dt / 60000)
		end
	end
	if self.isClient then
		if v163_.isWorking then
			if not v163_.isWorkSamplePlaying then
				g_soundManager:playSamples(v163_.samples.work)
				v163_.isWorkSamplePlaying = true
				return
			end
		elseif v163_.isWorkSamplePlaying then
			g_soundManager:stopSamples(v163_.samples.work)
			v163_.isWorkSamplePlaying = false
		end
	end
end

-- Local values: spec, dir
function Plow:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local v168_ = self.spec_plow
	v168_.startActivationTime = g_currentMission.time + v168_.startActivationTimeout
	if v168_.wasTurnAnimationStopped then
		local v169_ = v168_.rotationMax and 1 or -1
		self:playAnimation(v168_.rotationPart.turnAnimation, v169_, self:getAnimationTime(v168_.rotationPart.turnAnimation), true)
		v168_.wasTurnAnimationStopped = false
	end
end

-- Local values: spec
function Plow:onPreDetach(attacherVehicle, implement)
	local v171_ = self.spec_plow
	v171_.limitToField = true
	if self:getIsAnimationPlaying(v171_.rotationPart.turnAnimation) then
		self:stopAnimation(v171_.rotationPart.turnAnimation, true)
		v171_.wasTurnAnimationStopped = true
	end
end

-- Local values: spec
function Plow:onDeactivate()
	if self.isClient then
		local v173_ = self.spec_plow
		g_soundManager:stopSamples(v173_.samples.work)
		g_soundManager:stopSamples(v173_.samples.turn)
		v173_.isWorkSamplePlaying = false
	end
end

function Plow:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	fieldCourseSettings.toolFullOverlap = true
	fieldCourseSettings.toolFullOverlapInside = true
	fieldCourseSettings.segmentSplitAngle = 25
end

function Plow:onAIImplementStartTurn(isLeft)
	self.spec_plow.ai.lastHeadlandPosition = 0
end

-- Local values: spec
function Plow:onAIImplementTurnProgress(progress, isLeft, movingDirection)
	local v180_ = self.spec_plow
	if movingDirection > 0 or v180_.ai.allowTurnWhileReversing then
		if v180_.ai.lastHeadlandPosition <= v180_.ai.rotateToCenterHeadlandPos and (v180_.ai.rotateToCenterHeadlandPos < progress and progress < v180_.ai.rotateCompletelyHeadlandPos) then
			self:setRotationCenter()
		elseif v180_.ai.lastHeadlandPosition < v180_.ai.rotateCompletelyHeadlandPos and v180_.ai.rotateCompletelyHeadlandPos < progress then
			self:setRotationMax(isLeft)
		end
		v180_.ai.lastHeadlandPosition = progress
	end
end

function Plow:onAIImplementEndTurn(isLeft)
	self:setRotationMax(isLeft)
end

-- Local values: spec
function Plow:onAIImplementSideOffsetChanged(isLeft, isInitial)
	if isInitial then
		local v186_ = self.spec_plow
		if self:getIsPlowRotationAllowed() then
			self:setRotationMax(isLeft)
			return
		end
		v186_.ai.rotationMaxToSet = isLeft
	end
end

function Plow:onAIImplementEnd()
	self.spec_plow.ai.rotationMaxToSet = nil
end

-- Local values: spec
function Plow:onStartAnimation(animName)
	local v190_ = self.spec_plow
	if animName == v190_.rotationPart.turnAnimation then
		g_soundManager:playSamples(v190_.samples.turn)
	end
end

-- Local values: spec
function Plow:onFinishAnimation(animName)
	local v193_ = self.spec_plow
	if animName == v193_.rotationPart.turnAnimation then
		g_soundManager:stopSamples(v193_.samples.turn)
	end
end

-- Local values: spec
function Plow:onFoldTimeChanged(foldAnimTime)
	if self.isServer then
		local v195_ = self.spec_plow
		if v195_.ai.rotationMaxToSet ~= nil and self:getIsPlowRotationAllowed() then
			self:setRotationMax(v195_.ai.rotationMaxToSet)
			v195_.ai.rotationMaxToSet = nil
		end
	end
end

-- Local values: spec, specFoldable, actionController, actionController
function Plow:onRootVehicleChanged(rootVehicle)
	local v_u_198_ = self.spec_plow
	local v199_ = self.spec_foldable
	if v199_ ~= nil and #v199_.foldingParts > 0 then
		local v200_ = rootVehicle.actionController
		if v200_ == nil then
			if v_u_198_.controlledActionRotateBack ~= nil then
				v_u_198_.controlledActionRotateBack:remove()
				v_u_198_.controlledActionRotateBack = nil
			end
		else
			if v_u_198_.controlledActionRotateBack ~= nil then
				v_u_198_.controlledActionRotateBack:updateParent(v200_)
				return
			end
			v_u_198_.controlledActionRotateBack = v200_:registerAction("rotateBackPlow", nil, 3)
			v_u_198_.controlledActionRotateBack:setCallback(self, Plow.actionControllerRotateBackEvent)
			v_u_198_.controlledActionRotateBack:addAIEventListener(self, "onAIImplementPrepareForTransport", -1, true)
		end
	end
	local v201_ = rootVehicle.actionController
	if v201_ == nil then
		if v_u_198_.controlledActionRotate ~= nil then
			v_u_198_.controlledActionRotate:remove()
			v_u_198_.controlledActionRotate = nil
		end
		return
	elseif v_u_198_.controlledActionRotate == nil then
		v_u_198_.controlledActionRotate = v201_:registerAction("rotatePlow", nil, 3)
		v_u_198_.controlledActionRotate:setCallback(self, Plow.actionControllerRotateEvent)
		v_u_198_.controlledActionRotate:setFinishedFunctions(self, function(_)
			-- upvalues: (copy) self, (copy) v_u_198_
			return self:getIsAnimationPlaying(v_u_198_.rotationPart.turnAnimation)
		end, false, false)
		v_u_198_.controlledActionRotate:addAIEventListener(self, "onAIImplementStart", 1, true)
		v_u_198_.controlledActionRotate:setResetOnDeactivation(false)
	else
		v_u_198_.controlledActionRotate:updateParent(v201_)
	end
end

-- Local values: spec
function Plow:actionEventTurn(actionName, inputValue, callbackState, isAnalog)
	local v203_ = self.spec_plow
	if v203_.rotationPart.turnAnimation ~= nil and self:getCanTogglePlowRotation() then
		self:setRotationMax(not v203_.rotationMax)
	end
end

-- Local values: spec
function Plow:actionEventLimitToField(actionName, inputValue, callbackState, isAnalog)
	local v205_ = self.spec_plow
	if not self:getPlowForceLimitToField() then
		self:setPlowLimitToField(not v205_.limitToField)
	end
end

-- Local values: spec
function Plow:actionControllerRotateBackEvent(direction, isAIEvent)
	if not isAIEvent then
		return false
	end
	local v208_ = self.spec_plow
	if v208_.rotationPart.turnAnimation ~= nil and (self:getCanTogglePlowRotation() and v208_.rotationMax) then
		self:setRotationMax(false)
	end
	return true
end

-- Local values: spec, animationTime
function Plow:actionControllerRotateEvent(direction, isAIEvent)
	local v211_ = self.spec_plow
	if v211_.rotationPart.turnAnimation ~= nil and self:getCanTogglePlowRotation() then
		if direction < 0 then
			self:setRotationMax(not v211_.rotationMax)
		elseif not self:getIsAnimationPlaying(v211_.rotationPart.turnAnimation) then
			local v212_ = self:getAnimationTime(v211_.rotationPart.turnAnimation)
			if v212_ > 0 and v212_ < 1 then
				self:setRotationMax(v211_.rotationMax)
			end
		end
	end
	return true
end
