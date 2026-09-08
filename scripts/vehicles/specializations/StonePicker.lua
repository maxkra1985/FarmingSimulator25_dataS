StonePicker = {}
StonePicker.CLIENT_DM_UPDATE_RADIUS = 50
function StonePicker.initSpecialization()
	AIFieldWorker.registerDriveStrategy(function(p1_)
		return SpecializationUtil.hasSpecialization(StonePicker, p1_.specializations)
	end, AIDriveStrategyStonePicker)
	g_workAreaTypeManager:addWorkAreaType("stonePicker", true, true, true)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("StonePicker")
	v2_:register(XMLValueType.INT, "vehicle.stonePicker#fillUnitIndex", "Index of fillunit to be used for picked stones")
	v2_:register(XMLValueType.INT, "vehicle.stonePicker#loadInfoIndex", "Index of load info to use")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.stonePicker.directionNode#node", "Direction node")
	v2_:register(XMLValueType.BOOL, "vehicle.stonePicker.onlyActiveWhenLowered#value", "Only active when lowered", true)
	v2_:register(XMLValueType.BOOL, "vehicle.stonePicker.needsActivation#value", "Needs activation", true)
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.stonePicker.effects")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.stonePicker.soilEffects")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.stonePicker.sounds", "work")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.stonePicker.sounds", "stone")
	v2_:setXMLSpecializationType()
end

function StonePicker.prerequisitesPresent(specializations)
	local v4_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	if v4_ then
		v4_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
	return v4_
end

function StonePicker.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processStonePickerArea", StonePicker.processStonePickerArea)
	SpecializationUtil.registerFunction(vehicleType, "setStonePickerEffectsState", StonePicker.setStonePickerEffectsState)
end

function StonePicker.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", StonePicker.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", StonePicker.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", StonePicker.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", StonePicker.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", StonePicker.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", StonePicker.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", StonePicker.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", StonePicker.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", StonePicker.getCanToggleTurnedOn)
end

function StonePicker.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", StonePicker)
end

-- Local values: spec, firstSowableValue, lastSowableValue, stoneMapId, stoneFirstChannel, stoneNumChannels, minValue, maxValue
function StonePicker:onLoad(savegame)
	if self:getGroundReferenceNodeFromIndex(1) == nil then
		printWarning("Warning: No ground reference nodes in  " .. self.configFileName)
	end
	local v9_ = self.spec_stonePicker
	if self.isClient then
		v9_.samples = {}
		v9_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stonePicker.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.samples.stone = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stonePicker.sounds", "stone", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.isWorkSamplePlaying = false
		v9_.isStoneSamplePlaying = false
		v9_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.stonePicker.effects", self.components, self, self.i3dMappings)
		v9_.soilEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.stonePicker.soilEffects", self.components, self, self.i3dMappings)
	end
	v9_.fillUnitIndex = self.xmlFile:getValue("vehicle.stonePicker#fillUnitIndex", 1)
	v9_.loadInfoIndex = self.xmlFile:getValue("vehicle.stonePicker#loadInfoIndex", 1)
	v9_.directionNode = self.xmlFile:getValue("vehicle.stonePicker.directionNode#node", self.components[1].node, self.components, self.i3dMappings)
	v9_.onlyActiveWhenLowered = self.xmlFile:getValue("vehicle.stonePicker.onlyActiveWhenLowered#value", true)
	v9_.needsActivation = self.xmlFile:getValue("vehicle.stonePicker.needsActivation#value", true)
	v9_.startActivationTimeout = 2000
	v9_.startActivationTime = 0
	v9_.hasGroundContact = false
	v9_.isWorking = false
	v9_.isEffectActive = false
	v9_.effectGrowthState = 1
	v9_.isSoilEffectActive = false
	v9_.texts = {}
	v9_.texts.warningToolIsFull = g_i18n:getText("warning_toolIsFull")
	v9_.workAreaParameters = {}
	v9_.workAreaParameters.angle = 0
	v9_.workAreaParameters.pickedLiters = 0
	v9_.workAreaParameters.lastChangedArea = 0
	v9_.workAreaParameters.lastChangedAreaTime = -math.huge
	v9_.workAreaParameters.lastGrowthState = 1
	v9_.workAreaParameters.lastStatsArea = 0
	v9_.workAreaParameters.lastTotalArea = 0
	if self.isServer then
		local v10_, v11_ = g_currentMission.fieldGroundSystem:getSowableRange()
		self:addAITerrainDetailRequiredRange(v10_, v11_)
		if g_currentMission.stoneSystem ~= nil then
			local v12_, v13_, v14_ = g_currentMission.stoneSystem:getDensityMapData()
			local v15_, v16_ = g_currentMission.stoneSystem:getMinMaxValues()
			self:addAIFruitRequirement(nil, v15_, v16_, v12_, v13_, v14_)
		end
	end
	v9_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec
function StonePicker:onDelete()
	local v18_ = self.spec_stonePicker
	g_soundManager:deleteSamples(v18_.samples)
	g_effectManager:deleteEffects(v18_.effects)
	g_effectManager:deleteEffects(v18_.soilEffects)
end

-- Local values: state, growthState, stateSoil
function StonePicker:onReadStream(streamId, connection)
	self:setStonePickerEffectsState(streamReadBool(streamId), streamReadUIntN(streamId, 2), (streamReadBool(streamId)))
end

-- Local values: spec
function StonePicker:onWriteStream(streamId, connection)
	local v23_ = self.spec_stonePicker
	streamWriteBool(streamId, v23_.isEffectActive)
	streamWriteUIntN(streamId, v23_.effectGrowthState, 2)
	streamWriteBool(streamId, v23_.isSoilEffectActive)
end

-- Local values: state, growthState, stateSoil
function StonePicker:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer and streamReadBool(streamId) then
		self:setStonePickerEffectsState(streamReadBool(streamId), streamReadUIntN(streamId, 2), (streamReadBool(streamId)))
	end
end

-- Local values: spec
function StonePicker:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local v31_ = self.spec_stonePicker
		local v32_ = streamWriteBool
		local v33_ = v31_.dirtyFlag
		if v32_(streamId, bit32.band(dirtyMask, v33_) ~= 0) then
			streamWriteBool(streamId, v31_.isEffectActive)
			streamWriteUIntN(streamId, v31_.effectGrowthState, 2)
			streamWriteBool(streamId, v31_.isSoilEffectActive)
		end
	end
end

-- Local values: spec, xs, _, zs, xw, _, zw, xh, _, zh, params, stoneFactor, touchedArea, totalArea, litersPerSqm, sqm, liters
function StonePicker:processStonePickerArea(workArea, dt)
	local v36_ = self.spec_stonePicker
	if not v36_.workAreaParameters.isActive then
		return 0, 0
	end
	local v37_, _, v38_ = getWorldTranslation(workArea.start)
	local v39_, _, v40_ = getWorldTranslation(workArea.width)
	local v41_, _, v42_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v37_, v38_, v39_, v40_, v41_, v42_)
	if not self.isServer and self.currentUpdateDistance > StonePicker.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v43_ = v36_.workAreaParameters
	local v44_, v45_, v46_ = FSDensityMapUtil.updateStonePickerArea(v37_, v38_, v39_, v40_, v41_, v42_, v43_.angle)
	local v47_ = g_currentMission.stoneSystem:getLitersPerSqm()
	local v48_ = g_currentMission:getFruitPixelsToSqm() * v45_ * v47_ * v44_
	v43_.pickedLiters = v43_.pickedLiters + v48_
	v43_.lastChangedArea = v43_.lastChangedArea + v45_
	v43_.lastStatsArea = v43_.lastStatsArea + v45_
	v43_.lastTotalArea = v43_.lastTotalArea + v46_
	if v45_ > 0 then
		v43_.lastChangedAreaTime = g_time
		local v49_ = v44_ + 0.49
		local v50_ = math.floor(v49_)
		v43_.lastGrowthState = math.clamp(v50_, 1, 3)
	end
	v36_.isWorking = self:getLastSpeed() > 0.5
	return v45_, v46_
end

-- Local values: spec
function StonePicker:setStonePickerEffectsState(state, growthState, stateSoil)
	local v55_ = self.spec_stonePicker
	if state ~= v55_.isEffectActive or (growthState ~= v55_.effectGrowthState or stateSoil ~= v55_.isSoilEffectActive) then
		v55_.isEffectActive = state
		v55_.effectGrowthState = growthState
		v55_.isSoilEffectActive = stateSoil
		if self.isClient then
			if state then
				g_effectManager:setEffectTypeInfo(v55_.effects, FillType.STONE, nil, growthState)
				g_effectManager:startEffects(v55_.effects)
				if not v55_.isStoneSamplePlaying then
					g_soundManager:playSample(v55_.samples.stone)
					v55_.isStoneSamplePlaying = true
				end
			else
				g_effectManager:stopEffects(v55_.effects)
				if v55_.isStoneSamplePlaying then
					g_soundManager:stopSample(v55_.samples.stone)
					v55_.isStoneSamplePlaying = false
				end
			end
			if stateSoil then
				g_effectManager:startEffects(v55_.soilEffects)
				if not v55_.isWorkSamplePlaying then
					g_soundManager:playSample(v55_.samples.work)
					v55_.isWorkSamplePlaying = true
					return
				end
			else
				g_effectManager:stopEffects(v55_.soilEffects)
				if v55_.isWorkSamplePlaying then
					g_soundManager:stopSample(v55_.samples.work)
					v55_.isWorkSamplePlaying = false
				end
			end
		end
	end
end

-- Local values: spec
function StonePicker:doCheckSpeedLimit(superFunc)
	local v58_ = self.spec_stonePicker
	local v59_ = not superFunc(self) and self:getIsImplementChainLowered()
	if v59_ then
		v59_ = not v58_.needsActivation or self:getIsTurnedOn()
	end
	return v59_
end

-- Local values: spec
function StonePicker:getDoGroundManipulation(superFunc)
	if self.spec_stonePicker.isWorking then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec, multiplier
function StonePicker:getDirtMultiplier(superFunc)
	local v64_ = self.spec_stonePicker
	local v65_ = superFunc(self)
	if self.movingDirection > 0 and (v64_.isWorking and (not v64_.needsActivation or self:getIsTurnedOn())) then
		v65_ = v65_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / v64_.speedLimit
	end
	return v65_
end

-- Local values: spec, multiplier
function StonePicker:getWearMultiplier(superFunc)
	local v68_ = self.spec_stonePicker
	local v69_ = superFunc(self)
	if self.movingDirection > 0 and (v68_.isWorking and (not v68_.needsActivation or self:getIsTurnedOn())) then
		v69_ = v69_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v69_
end

-- Local values: retValue
function StonePicker:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v75_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.STONEPICKER
	end
	return v75_
end

-- Local values: spec, freeCapacity
function StonePicker:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.STONEPICKER then
		local v79_ = self.spec_stonePicker
		if v79_.startActivationTime > g_currentMission.time then
			return false
		end
		if v79_.onlyActiveWhenLowered and (self.getIsLowered ~= nil and not self:getIsLowered(false)) then
			return false
		end
		if self:getFillUnitFreeCapacity(v79_.fillUnitIndex) <= 0 and not self:getIsAIActive() then
			return false
		end
	end
	return superFunc(self, workArea)
end

-- Local values: spec, freeCapacity
function StonePicker:getCanBeTurnedOn(superFunc)
	if self:getFillUnitFreeCapacity(self.spec_stonePicker.fillUnitIndex) <= 0 and not self:getIsAIActive() then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec, freeCapacity
function StonePicker:getTurnedOnNotAllowedWarning(superFunc)
	local v84_ = self.spec_stonePicker
	if self:getFillUnitFreeCapacity(v84_.fillUnitIndex) <= 0 and not self:getIsAIActive() then
		return v84_.texts.warningToolIsFull
	else
		return superFunc(self)
	end
end

-- Local values: spec
function StonePicker:getCanToggleTurnedOn(superFunc)
	if self.spec_stonePicker.needsActivation then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec, freeCapacity
function StonePicker:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local v89_ = self.spec_stonePicker
	if self.isServer and (v89_.fillUnitIndex == fillUnitIndex and (self:getFillUnitFreeCapacity(v89_.fillUnitIndex) <= 0 and (self:getIsTurnedOn() and not self:getIsAIActive()))) then
		self:setIsTurnedOn(false, false)
	end
end

function StonePicker:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	fieldCourseSettings.headlandsFirst = true
	fieldCourseSettings.workInitialSegment = true
	fieldCourseSettings.segmentSplitDistance = 50
	fieldCourseSettings.toolAlwaysActive = true
end

-- Local values: spec
function StonePicker:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local v92_ = self.spec_stonePicker
	v92_.startActivationTime = g_currentMission.time + v92_.startActivationTimeout
end

-- Local values: spec
function StonePicker:onDeactivate()
	if self.isClient then
		local v94_ = self.spec_stonePicker
		g_soundManager:stopSamples(v94_.samples)
		v94_.isWorkSamplePlaying = false
	end
end

-- Local values: spec, dx, _, dz, angle
function StonePicker:onStartWorkAreaProcessing(dt)
	local v96_ = self.spec_stonePicker
	v96_.isWorking = false
	local v97_, _, v98_ = localDirectionToWorld(v96_.directionNode, 0, 0, 1)
	local v99_ = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(v97_, v98_), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	v96_.workAreaParameters.isActive = not v96_.needsActivation or self:getIsTurnedOn()
	v96_.workAreaParameters.angle = v99_
	v96_.workAreaParameters.pickedLiters = 0
	v96_.workAreaParameters.lastChangedArea = 0
	v96_.workAreaParameters.lastStatsArea = 0
	v96_.workAreaParameters.lastTotalArea = 0
end

-- Local values: spec, params, lastStatsArea, state, soilState, loadInfo
function StonePicker:onEndWorkAreaProcessing(dt)
	local v101_ = self.spec_stonePicker
	local v102_ = v101_.workAreaParameters
	if self.isServer then
		local v103_ = v101_.workAreaParameters.lastStatsArea
		if v103_ > 0 then
			self:updateLastWorkedArea(v103_)
		end
		local v104_ = g_time - v101_.workAreaParameters.lastChangedAreaTime < 500
		local v105_ = v101_.isWorking
		if v105_ then
			v105_ = self.isOnField
		end
		if v101_.isEffectActive ~= v104_ or (v101_.effectGrowthState ~= v101_.workAreaParameters.lastGrowthState or v105_ ~= v101_.isSoilEffectActive) then
			self:setStonePickerEffectsState(v104_, v101_.workAreaParameters.lastGrowthState, v105_)
			self:raiseDirtyFlags(v101_.dirtyFlag)
		end
		if v102_.pickedLiters > 0 then
			local v106_ = self:getFillVolumeLoadInfo(v101_.loadInfoIndex)
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v101_.fillUnitIndex, v102_.pickedLiters, FillType.STONE, ToolType.UNDEFINED, v106_)
		end
	end
end
function StonePicker.getDefaultSpeedLimit()
	return 10
end
