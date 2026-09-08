Roller = {}
Roller.AI_REQUIRED_GROUND_TYPES = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.CULTIVATED,
	FieldGroundType.SEEDBED,
	FieldGroundType.PLOWED,
	FieldGroundType.RIDGE,
	FieldGroundType.SOWN,
	FieldGroundType.DIRECT_SOWN,
	FieldGroundType.PLANTED,
	FieldGroundType.RIDGE_SOWN,
	FieldGroundType.CULTIVATED
}
Roller.AI_REQUIRED_GROUND_TYPES_GRASS = { FieldGroundType.GRASS, FieldGroundType.GRASS_CUT }
Roller.CLIENT_DM_UPDATE_RADIUS = 50
function Roller.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("roller", g_i18n:getText("configuration_design"), "roller", VehicleConfigurationItem)
	g_workAreaTypeManager:addWorkAreaType("roller", false, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Roller")
	Roller.registerRollerXMLPaths(v1_, "vehicle.roller")
	Roller.registerRollerXMLPaths(v1_, "vehicle.roller.rollerConfigurations.rollerConfiguration(?).roller")
	v1_:setXMLSpecializationType()
end

function Roller.registerRollerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".directionNode#node", "Roller direction node")
	schema:register(XMLValueType.BOOL, basePath .. "#onlyActiveWhenLowered", "Only active when lowered", true)
	schema:register(XMLValueType.BOOL, basePath .. "#isSoilRoller", "If roller is for soil", true)
	schema:register(XMLValueType.BOOL, basePath .. "#isGrassRoller", "If roller is for grassland", false)
	schema:register(XMLValueType.BOOL, basePath .. "#usingAIRequirements", "Tool using roller ai requirements", true)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "work")
end

function Roller.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end

function Roller.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processRollerArea", Roller.processRollerArea)
	SpecializationUtil.registerFunction(vehicleType, "updateRollerAIRequirements", Roller.updateRollerAIRequirements)
end

function Roller.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Roller.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", Roller.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Roller.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Roller.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Roller.getIsWorkAreaActive)
end

function Roller.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Roller)
end

-- Local values: spec, rollerConfigurationId, configKey
function Roller:onLoad(savegame)
	local v9_ = self.spec_roller
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rollerSound", "vehicle.roller.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.onlyActiveWhenLowered#value", "vehicle.roller#onlyActiveWhenLowered")
	local v10_ = Utils.getNoNil(self.configurations.roller, 1)
	local v11_ = string.format("vehicle.roller.rollerConfigurations.rollerConfiguration(%d).roller", v10_ - 1)
	local v12_ = not self.xmlFile:hasProperty(v11_) and "vehicle.roller" or v11_
	v9_.directionNode = self.xmlFile:getValue(v12_ .. ".directionNode#node", self.components[1].node, self.components, self.i3dMappings)
	if self.isClient then
		v9_.samples = {}
		v9_.isWorkSamplePlaying = false
		v9_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, v12_ .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v9_.isSoilRoller = self.xmlFile:getValue(v12_ .. "#isSoilRoller")
	v9_.isGrassRoller = self.xmlFile:getValue(v12_ .. "#isGrassRoller")
	if v9_.isSoilRoller == nil and v9_.isGrassRoller == nil then
		v9_.isSoilRoller = true
		v9_.isGrassRoller = false
	else
		if v9_.isGrassRoller == nil then
			v9_.isGrassRoller = false
		end
		if v9_.isSoilRoller == nil then
			v9_.isSoilRoller = false
		end
	end
	v9_.grassFruitTypes = { FruitType.GRASS, FruitType.MEADOW }
	v9_.usingAIRequirements = self.xmlFile:getValue(v12_ .. "#usingAIRequirements", true)
	v9_.onlyActiveWhenLowered = self.xmlFile:getValue(v12_ .. "#onlyActiveWhenLowered", true)
	v9_.startActivationTimeout = 2000
	v9_.startActivationTime = 0
	v9_.isWorking = false
	v9_.angle = 0
	self:updateRollerAIRequirements()
	v9_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec
function Roller:onDelete()
	local v14_ = self.spec_roller
	g_soundManager:deleteSamples(v14_.samples)
end

-- Local values: spec, xs, _, zs, xw, _, zw, xh, _, zh, realArea
function Roller:processRollerArea(workArea, dt)
	local v17_ = self.spec_roller
	local v18_, _, v19_ = getWorldTranslation(workArea.start)
	local v20_, _, v21_ = getWorldTranslation(workArea.width)
	local v22_, _, v23_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v18_, v19_, v20_, v21_, v22_, v23_)
	if not self.isServer and self.currentUpdateDistance > Roller.CLIENT_DM_UPDATE_RADIUS then
		return 0
	end
	local v24_
	if v17_.isGrassRoller then
		local v25_
		v24_, v25_ = FSDensityMapUtil.updateGrassRollerArea(v18_, v19_, v20_, v21_, v22_, v23_, not v17_.isSoilRoller)
	else
		v24_ = nil
	end
	if v17_.isSoilRoller then
		local v26_
		v24_, v26_ = FSDensityMapUtil.updateRollerArea(v18_, v19_, v20_, v21_, v22_, v23_, v17_.angle)
	end
	v17_.isWorking = self:getLastSpeed() > 0.5
	return v24_
end

-- Local values: spec, hasSowingMachine, i, fruitTypeDesc, fruitTypeIndex, fruitType, i, fruitTypeDesc
function Roller:updateRollerAIRequirements()
	if self.clearAITerrainDetailRequiredRange ~= nil then
		local v28_ = self.spec_roller
		if not v28_.usingAIRequirements then
			return
		end
		local v29_ = SpecializationUtil.hasSpecialization(SowingMachine, self.specializations) and self:getUseSowingMachineAIRequirements() and true or false
		self:clearAIFruitRequirements()
		self:clearAIFruitProhibitions()
		self:clearAITerrainDetailRequiredRange()
		if not v29_ then
			if v28_.isGrassRoller and not v28_.isSoilRoller then
				self:addAIGroundTypeRequirements(Roller.AI_REQUIRED_GROUND_TYPES_GRASS)
				for v30_ = 1, #v28_.grassFruitTypes do
					local v31_ = g_fruitTypeManager:getFruitTypeByIndex(v28_.grassFruitTypes[v30_])
					if v31_ ~= nil and v31_.terrainDataPlaneId ~= nil then
						self:addAIFruitRequirement(v31_.index, 2, v31_.cutState + 1)
					end
				end
			end
			if v28_.isSoilRoller then
				self:addAIGroundTypeRequirements(Roller.AI_REQUIRED_GROUND_TYPES)
				for v32_, v33_ in pairs(g_fruitTypeManager:getFruitTypes()) do
					if v33_.terrainDataPlaneId ~= nil and (not v28_.isGrassRoller or v32_ ~= FruitType.GRASS) then
						self:addAIFruitProhibitions(v33_.index, 2, 15)
					end
				end
				if v28_.isGrassRoller then
					self:addAIGroundTypeRequirements(Roller.AI_REQUIRED_GROUND_TYPES_GRASS)
					for v34_ = 1, #v28_.grassFruitTypes do
						local v35_ = g_fruitTypeManager:getFruitTypeByIndex(v28_.grassFruitTypes[v34_])
						if v35_ ~= nil and v35_.terrainDataPlaneId ~= nil then
							self:addAIFruitProhibitions(v35_.index, 1, 1)
						end
					end
				end
			end
		end
	end
end

-- Local values: spec
function Roller:doCheckSpeedLimit(superFunc)
	local v38_ = self.spec_roller
	return superFunc(self) or v38_.isWorking
end

-- Local values: spec
function Roller:getDoGroundManipulation(superFunc)
	local v41_ = self.spec_roller
	local v42_ = superFunc(self)
	if v42_ then
		v42_ = v41_.isWorking
	end
	return v42_
end

-- Local values: spec, multiplier
function Roller:getDirtMultiplier(superFunc)
	local v45_ = self.spec_roller
	local v46_ = superFunc(self)
	if v45_.isWorking then
		v46_ = v46_ + self:getWorkDirtMultiplier()
	end
	return v46_
end

-- Local values: spec, multiplier
function Roller:getWearMultiplier(superFunc)
	local v49_ = self.spec_roller
	local v50_ = superFunc(self)
	if v49_.isWorking then
		v50_ = v50_ + self:getWorkWearMultiplier()
	end
	return v50_
end

-- Local values: spec
function Roller:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.ROLLER then
		local v54_ = self.spec_roller
		if v54_.startActivationTime > g_currentMission.time then
			return false
		end
		if v54_.onlyActiveWhenLowered and not self:getIsLowered() then
			return false
		end
	end
	return superFunc(self, workArea)
end

-- Local values: spec, dx, _, dz
function Roller:onStartWorkAreaProcessing(dt)
	local v56_ = self.spec_roller
	local v57_, _, v58_ = localDirectionToWorld(v56_.directionNode, 0, 0, 1)
	v56_.angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(v57_, v58_), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	v56_.isWorking = false
end

-- Local values: spec
function Roller:onEndWorkAreaProcessing(dt, hasProcessed)
	local v60_ = self.spec_roller
	if self.isClient then
		if v60_.isWorking then
			if not v60_.isWorkSamplePlaying then
				g_soundManager:playSample(v60_.samples.work)
				v60_.isWorkSamplePlaying = true
				return
			end
		elseif v60_.isWorkSamplePlaying then
			g_soundManager:stopSample(v60_.samples.work)
			v60_.isWorkSamplePlaying = false
		end
	end
end

-- Local values: spec
function Roller:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local v62_ = self.spec_roller
	v62_.startActivationTime = g_currentMission.time + v62_.startActivationTimeout
end

-- Local values: spec
function Roller:onDeactivate()
	local v64_ = self.spec_roller
	g_soundManager:stopSample(v64_.samples.work)
	v64_.isWorkSamplePlaying = false
end
function Roller.getDefaultSpeedLimit()
	return 15
end
