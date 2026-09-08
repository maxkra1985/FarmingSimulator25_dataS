Cultivator = {}
Cultivator.CLIENT_DM_UPDATE_RADIUS = 50
Cultivator.AI_REQUIRED_GROUND_TYPES_FLAT = {
	FieldGroundType.CULTIVATED,
	FieldGroundType.PLOWED,
	FieldGroundType.ROLLED_SEEDBED,
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
Cultivator.AI_REQUIRED_GROUND_TYPES_DEEP = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.SEEDBED,
	FieldGroundType.PLOWED,
	FieldGroundType.ROLLED_SEEDBED,
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
Cultivator.AI_OUTPUT_GROUND_TYPES = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.CULTIVATED,
	FieldGroundType.SEEDBED,
	FieldGroundType.RIDGE,
	FieldGroundType.ROLLED_SEEDBED
}
function Cultivator.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("cultivator", true, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Cultivator")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.cultivator.directionNode#node", "Direction node")
	v1_:register(XMLValueType.BOOL, "vehicle.cultivator.onlyActiveWhenLowered#value", "Only active when lowered", true)
	v1_:register(XMLValueType.BOOL, "vehicle.cultivator#isSubsoiler", "Is subsoiler", false)
	v1_:register(XMLValueType.BOOL, "vehicle.cultivator#useDeepMode", "If true the implement acts like a cultivator. If false it\'s a discharrow or seedbed combination", true)
	v1_:register(XMLValueType.BOOL, "vehicle.cultivator#isPowerHarrow", "If this is set the cultivator works standalone like a cultivator, but as soon as a sowing machine is attached to it, it\'s only using the sowing machine", false)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.cultivator.sounds", "work(?)")
	v1_:addDelayedRegistrationFunc("WorkMode:workMode", function(p2_, p3_)
		p2_:register(XMLValueType.BOOL, p3_ .. "#useDeepMode", "If true the implement acts like a cultivator. If false it\'s a discharrow or seedbed combination")
	end)
	v1_:setXMLSpecializationType()
end

function Cultivator.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end

function Cultivator.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processCultivatorArea", Cultivator.processCultivatorArea)
	SpecializationUtil.registerFunction(vehicleType, "processVineCultivatorArea", Cultivator.processVineCultivatorArea)
	SpecializationUtil.registerFunction(vehicleType, "getCultivatorLimitToField", Cultivator.getCultivatorLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "getUseCultivatorAIRequirements", Cultivator.getUseCultivatorAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "updateCultivatorAIRequirements", Cultivator.updateCultivatorAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "updateCultivatorEnabledState", Cultivator.updateCultivatorEnabledState)
	SpecializationUtil.registerFunction(vehicleType, "getIsCultivationEnabled", Cultivator.getIsCultivationEnabled)
end

function Cultivator.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Cultivator.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Cultivator.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cultivator.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Cultivator.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Cultivator.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkModeFromXML", Cultivator.loadWorkModeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", Cultivator.getAIImplementUseVineSegment)
end

function Cultivator.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onWorkModeChanged", Cultivator)
end

-- Local values: spec
function Cultivator:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cultivator.directionNode#index", "vehicle.cultivator.directionNode#node")
	if self:getGroundReferenceNodeFromIndex(1) == nil then
		printWarning("Warning: No ground reference nodes in  " .. self.configFileName)
	end
	local v9_ = self.spec_cultivator
	if self.isClient then
		v9_.samples = {}
		v9_.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.cultivator.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.isWorkSamplePlaying = false
	end
	v9_.directionNode = self.xmlFile:getValue("vehicle.cultivator.directionNode#node", self.components[1].node, self.components, self.i3dMappings)
	v9_.onlyActiveWhenLowered = self.xmlFile:getValue("vehicle.cultivator.onlyActiveWhenLowered#value", true)
	v9_.isSubsoiler = self.xmlFile:getValue("vehicle.cultivator#isSubsoiler", false)
	v9_.isPowerHarrow = self.xmlFile:getValue("vehicle.cultivator#isPowerHarrow", false)
	v9_.useDeepMode = self.xmlFile:getValue("vehicle.cultivator#useDeepMode", true)
	self:updateCultivatorAIRequirements()
	v9_.isEnabled = true
	v9_.startActivationTimeout = 2000
	v9_.startActivationTime = 0
	v9_.hasGroundContact = false
	v9_.isWorking = false
	v9_.limitToField = true
	v9_.workAreaParameters = {}
	v9_.workAreaParameters.limitToField = self:getCultivatorLimitToField()
	v9_.workAreaParameters.angle = 0
	v9_.workAreaParameters.lastChangedArea = 0
	v9_.workAreaParameters.lastStatsArea = 0
	v9_.workAreaParameters.lastTotalArea = 0
end

-- Local values: spec
function Cultivator:onDelete()
	local v11_ = self.spec_cultivator
	if v11_.samples ~= nil then
		g_soundManager:deleteSamples(v11_.samples.work)
	end
end

-- Local values: spec, realArea, area, xs, _, zs, xw, _, zw, xh, _, zh, params
function Cultivator:processCultivatorArea(workArea, dt)
	local v14_ = self.spec_cultivator
	local v15_ = 0
	local v16_ = 0
	local v17_, _, v18_ = getWorldTranslation(workArea.start)
	local v19_, _, v20_ = getWorldTranslation(workArea.width)
	local v21_, _, v22_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v17_, v18_, v19_, v20_, v21_, v22_)
	if not self.isServer and self.currentUpdateDistance > Cultivator.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	if v14_.isEnabled then
		local v23_ = v14_.workAreaParameters
		if v14_.useDeepMode then
			local v24_
			v24_, v16_ = FSDensityMapUtil.updateCultivatorArea(v17_, v18_, v19_, v20_, v21_, v22_, not v23_.limitToField, v23_.limitFruitDestructionToField, v23_.angle, nil)
			v15_ = v24_ + FSDensityMapUtil.updateVineCultivatorArea(v17_, v18_, v19_, v20_, v21_, v22_, true)
		else
			local v25_
			v25_, v16_ = FSDensityMapUtil.updateDiscHarrowArea(v17_, v18_, v19_, v20_, v21_, v22_, not v23_.limitToField, v23_.limitFruitDestructionToField, v23_.angle, nil)
			v15_ = v25_ + FSDensityMapUtil.updateVineCultivatorArea(v17_, v18_, v19_, v20_, v21_, v22_, true)
		end
		v23_.lastChangedArea = v23_.lastChangedArea + v15_
		v23_.lastStatsArea = v23_.lastStatsArea + v15_
		v23_.lastTotalArea = v23_.lastTotalArea + v16_
	end
	if v14_.isSubsoiler then
		FSDensityMapUtil.updateSubsoilerArea(v17_, v18_, v19_, v20_, v21_, v22_)
	end
	v14_.isWorking = self:getLastSpeed() > 0.5
	return v15_, v16_
end

-- Local values: spec, xs, _, zs, xw, _, zw, xh, _, zh
function Cultivator:processVineCultivatorArea(workArea, dt)
	local v28_ = self.spec_cultivator
	if not self.isServer and self.currentUpdateDistance > Cultivator.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	if v28_.isEnabled then
		local v29_, _, v30_ = getWorldTranslation(workArea.start)
		local v31_, _, v32_ = getWorldTranslation(workArea.width)
		local v33_, _, v34_ = getWorldTranslation(workArea.height)
		FSDensityMapUtil.updateVineCultivatorArea(v29_, v30_, v31_, v32_, v33_, v34_, false)
	end
	return 0, 0
end

function Cultivator:getCultivatorLimitToField()
	return self.spec_cultivator.limitToField
end

function Cultivator:getUseCultivatorAIRequirements()
	return true
end

-- Local values: hasSowingMachine, excludedType1, excludedType2, vehicles, i, vehicles, i
function Cultivator:updateCultivatorAIRequirements()
	if self:getUseCultivatorAIRequirements() and self.addAITerrainDetailRequiredRange ~= nil then
		local v37_ = self:getChildVehicles()
		local v38_ = false
		local v39_ = nil
		local v40_ = nil
		for v41_ = 1, #v37_ do
			if SpecializationUtil.hasSpecialization(SowingMachine, v37_[v41_].specializations) and (v37_[v41_]:getAIRequiresTurnOn() or v37_[v41_]:getUseSowingMachineAIRequirements()) then
				v38_ = true
			end
		end
		local v42_ = self.rootVehicle:getChildVehicles()
		for v43_ = 1, #v42_ do
			if SpecializationUtil.hasSpecialization(Roller, v42_[v43_].specializations) then
				v39_ = FieldGroundType.ROLLER_LINES
				v40_ = FieldGroundType.ROLLED_SEEDBED
			end
		end
		if not v38_ then
			if self.spec_cultivator.useDeepMode then
				self:addAIGroundTypeRequirements(Cultivator.AI_REQUIRED_GROUND_TYPES_DEEP, v39_, v40_)
			else
				self:addAIGroundTypeRequirements(Cultivator.AI_REQUIRED_GROUND_TYPES_FLAT, v39_, v40_)
			end
		end
		self:clearAITerrainDetailRequiredRange()
	end
end

-- Local values: spec, vehicles, i
function Cultivator:updateCultivatorEnabledState()
	local v45_ = self.spec_cultivator
	if v45_.isPowerHarrow then
		local v46_ = self:getChildVehicles()
		for v47_ = 1, #v46_ do
			if SpecializationUtil.hasSpecialization(SowingMachine, v46_[v47_].specializations) then
				v45_.isEnabled = false
				return
			end
		end
	elseif SpecializationUtil.hasSpecialization(SowingMachine, self.specializations) and (self:getUseSowingMachineAIRequirements() and self.spec_sowingMachine.useDirectPlanting) then
		if self.spec_sowingMachine.workAreaParameters.seedsVehicle ~= nil then
			v45_.isEnabled = false
			return
		end
		if self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds then
			v45_.isEnabled = false
			return
		end
	end
	v45_.isEnabled = true
end

function Cultivator:getIsCultivationEnabled()
	return self.spec_cultivator.isEnabled
end

function Cultivator:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsImplementChainLowered()
end

-- Local values: spec, multiplier
function Cultivator:getDirtMultiplier(superFunc)
	local v53_ = self.spec_cultivator
	local v54_ = superFunc(self)
	if v53_.isWorking then
		v54_ = v54_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / v53_.speedLimit
	end
	return v54_
end

-- Local values: spec, multiplier
function Cultivator:getWearMultiplier(superFunc)
	local v57_ = self.spec_cultivator
	local v58_ = superFunc(self)
	if v57_.isWorking then
		v58_ = v58_ + self:getWorkWearMultiplier() * self:getLastSpeed() / v57_.speedLimit
	end
	return v58_
end

-- Local values: retValue
function Cultivator:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v64_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.CULTIVATOR
	end
	return v64_
end

-- Local values: spec
function Cultivator:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.CULTIVATOR then
		local v68_ = self.spec_cultivator
		if v68_.startActivationTime > g_currentMission.time then
			return false
		end
		if v68_.onlyActiveWhenLowered and (self.getIsLowered ~= nil and not self:getIsLowered(false)) then
			return false
		end
	end
	return superFunc(self, workArea)
end

function Cultivator:loadWorkModeFromXML(superFunc, xmlFile, key, workMode)
	if not superFunc(self, xmlFile, key, workMode) then
		return false
	end
	workMode.useDeepMode = xmlFile:getValue(key .. "#useDeepMode")
	return true
end

-- Local values: startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, area, areaTotal
function Cultivator:getAIImplementUseVineSegment(superFunc, placeable, segment, segmentSide)
	local v78_, v79_, v80_, v81_, v82_, v83_ = placeable:getSegmentSideArea(segment, segmentSide)
	local v84_, v85_ = AIVehicleUtil.getAIAreaOfVehicle(self, v78_, v79_, v80_, v81_, v82_, v83_)
	if v85_ > 0 then
		return v84_ / v85_ > 0.01
	else
		return false
	end
end

-- Local values: spec
function Cultivator:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local v87_ = self.spec_cultivator
	v87_.startActivationTime = g_currentMission.time + v87_.startActivationTimeout
end

-- Local values: spec
function Cultivator:onDeactivate()
	if self.isClient then
		local v89_ = self.spec_cultivator
		g_soundManager:stopSamples(v89_.samples.work)
		v89_.isWorkSamplePlaying = false
	end
end

-- Local values: spec, limitToField, limitFruitDestructionToField, dx, _, dz, angle
function Cultivator:onStartWorkAreaProcessing(dt)
	local v91_ = self.spec_cultivator
	v91_.isWorking = false
	local v92_ = self:getCultivatorLimitToField()
	local v93_
	if g_currentMission:getHasPlayerPermission("createFields", self:getOwnerConnection()) then
		v93_ = v92_
	else
		v92_ = true
		v93_ = true
	end
	local v94_, _, v95_ = localDirectionToWorld(v91_.directionNode, 0, 0, 1)
	local v96_ = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(v94_, v95_), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	v91_.workAreaParameters.limitToField = v92_
	v91_.workAreaParameters.limitFruitDestructionToField = v93_
	v91_.workAreaParameters.angle = v96_
	v91_.workAreaParameters.lastChangedArea = 0
	v91_.workAreaParameters.lastStatsArea = 0
	v91_.workAreaParameters.lastTotalArea = 0
end

-- Local values: spec, farmId, lastStatsArea, ha
function Cultivator:onEndWorkAreaProcessing(dt)
	local v99_ = self.spec_cultivator
	if self.isServer then
		local v100_ = self:getLastTouchedFarmlandFarmId()
		local v101_ = v99_.workAreaParameters.lastStatsArea
		if v101_ > 0 then
			local v102_ = MathUtil.areaToHa(v101_, g_currentMission:getFruitPixelsToSqm())
			g_farmManager:updateFarmStats(v100_, "cultivatedHectares", v102_)
			self:updateLastWorkedArea(v101_)
		end
		if v99_.isWorking then
			g_farmManager:updateFarmStats(v100_, "cultivatedTime", dt / 60000)
		end
	end
	if self.isClient then
		if v99_.isWorking then
			if not v99_.isWorkSamplePlaying then
				g_soundManager:playSamples(v99_.samples.work)
				v99_.isWorkSamplePlaying = true
				return
			end
		elseif v99_.isWorkSamplePlaying then
			g_soundManager:stopSamples(v99_.samples.work)
			v99_.isWorkSamplePlaying = false
		end
	end
end

-- Local values: spec, _, implement, vehicle, attacherVehicle
function Cultivator:onStateChange(state, data)
	if state == VehicleStateChange.ATTACH or (state == VehicleStateChange.DETACH or state == VehicleStateChange.AI_START_LINE) then
		self:updateCultivatorAIRequirements()
		self:updateCultivatorEnabledState()
	end
	if self.isServer and (state == VehicleStateChange.TURN_ON or state == VehicleStateChange.TURN_OFF) and self.spec_cultivator.isPowerHarrow then
		if data == self and self.getAttachedImplements ~= nil then
			for _, v106_ in pairs(self:getAttachedImplements()) do
				local v107_ = v106_.object
				if v107_ ~= nil then
					if state == VehicleStateChange.TURN_ON then
						v107_:setIsTurnedOn(true)
					elseif v107_:getIsTurnedOn() then
						v107_:setIsTurnedOn(false)
					end
				end
			end
			return
		end
		if data.getAttacherVehicle ~= nil then
			local v108_ = data:getAttacherVehicle()
			if v108_ ~= nil and v108_ == self then
				if state == VehicleStateChange.TURN_ON then
					self:setIsTurnedOn(true)
					return
				end
				if self:getIsTurnedOn() then
					self:setIsTurnedOn(false)
				end
			end
		end
	end
end

function Cultivator:onWorkModeChanged(workMode, oldWorkMode)
	if workMode.useDeepMode ~= nil then
		self.spec_cultivator.useDeepMode = workMode.useDeepMode
		self:updateCultivatorAIRequirements()
	end
end
function Cultivator.getDefaultSpeedLimit()
	return 15
end
