Weeder = {}
Weeder.CLIENT_DM_UPDATE_RADIUS = 50
function Weeder.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("weeder", true, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Weeder")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.weeder.sounds", "work(?)")
	v1_:register(XMLValueType.BOOL, "vehicle.weeder#isHoe", "Is hoe weeder", false)
	v1_:register(XMLValueType.BOOL, "vehicle.weeder#isGrasslandWeeder", "Is a grassland weeder (grass fertilizer state + grass growth reset)", false)
	v1_:register(XMLValueType.BOOL, WorkParticles.PARTICLE_MAPPING_XML_PATH .. "#adjustColor", "Adjust color", false)
	v1_:setXMLSpecializationType()
end

function Weeder.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	end
	return v3_
end

function Weeder.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processWeederArea", Weeder.processWeederArea)
	SpecializationUtil.registerFunction(vehicleType, "updateWeederAIRequirements", Weeder.updateWeederAIRequirements)
end

function Weeder.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Weeder.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Weeder.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Weeder.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Weeder.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Weeder.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundParticleMapping", Weeder.loadGroundParticleMapping)
end

function Weeder.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Weeder)
end

-- Local values: spec
function Weeder:onLoad(savegame)
	local v8_ = self.spec_weeder
	if self.isClient then
		v8_.samples = {}
		v8_.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.weeder.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.isWorkSamplePlaying = false
	end
	v8_.startActivationTimeout = 2000
	v8_.startActivationTime = 0
	v8_.isHoeWeeder = self.xmlFile:getValue("vehicle.weeder#isHoe", false)
	v8_.isGrasslandWeeder = self.xmlFile:getValue("vehicle.weeder#isGrasslandWeeder", false)
	v8_.workAreaParameters = {}
	v8_.workAreaParameters.lastArea = 0
	v8_.workAreaParameters.lastStatsArea = 0
	v8_.isWorking = false
	v8_.stoneLastState = 0
	v8_.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("WEEDER")
	self:updateWeederAIRequirements()
end

-- Local values: spec
function Weeder:onDelete()
	local v10_ = self.spec_weeder
	if v10_.samples ~= nil then
		g_soundManager:deleteSamples(v10_.samples.work)
	end
end

-- Local values: spec, _, mapping, wx, wy, wz, isOnField, densityBits
function Weeder:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v13_ = self.spec_weeder
	if v13_.isWorking and v13_.colorParticleSystems ~= nil then
		for _, v14_ in ipairs(v13_.colorParticleSystems) do
			local v15_, v16_, v17_ = getWorldTranslation(v14_.node)
			local v18_, v19_ = FSDensityMapUtil.getFieldDataAtWorldPosition(v15_, v16_, v17_)
			if v18_ then
				local v20_ = v14_.lastColor
				local v21_ = v14_.lastColor
				local v22_ = v14_.lastColor
				local v23_, v24_, v25_, _ = g_currentMission.fieldGroundSystem:getFieldGroundTyreTrackColor(v19_)
				v20_[1] = v23_
				v21_[2] = v24_
				v22_[3] = v25_
			else
				local v26_ = v14_.lastColor
				local v27_ = v14_.lastColor
				local v28_ = v14_.lastColor
				local v29_, v30_, v31_, _, _ = getTerrainAttributesAtWorldPos(g_terrainNode, v15_, v16_, v17_, true, true, true, true, false)
				v26_[1] = v29_
				v27_[2] = v30_
				v28_[3] = v31_
			end
			if v14_.targetColor == nil then
				v14_.targetColor = { v14_.lastColor[1], v14_.lastColor[2], v14_.lastColor[3] }
				v14_.currentColor = { v14_.lastColor[1], v14_.lastColor[2], v14_.lastColor[3] }
				v14_.alpha = 1
			end
			if v14_.alpha ~= 1 then
				local v32_ = v14_.alpha + dt / 1000
				v14_.alpha = math.min(v32_, 1)
				v14_.currentColor = { MathUtil.vector3ArrayLerp(v14_.lastColor, v14_.targetColor, v14_.alpha) }
				if v14_.alpha == 1 then
					v14_.lastColor = { v14_.currentColor[1], v14_.currentColor[2], v14_.currentColor[3] }
				end
			end
			if v14_.alpha == 1 and (v14_.lastColor[1] ~= v14_.targetColor[1] and (v14_.lastColor[2] ~= v14_.targetColor[2] and v14_.lastColor[3] ~= v14_.targetColor[3])) then
				v14_.alpha = 0
				v14_.targetColor = { v14_.lastColor[1], v14_.lastColor[2], v14_.lastColor[3] }
			end
			setShaderParameter(v14_.particleSystem.shape, "psColor", v14_.currentColor[1], v14_.currentColor[2], v14_.currentColor[3], 1, false)
		end
	end
end

-- Local values: spec, xs, _, zs, xw, _, zw, xh, _, zh, area, _area
function Weeder:processWeederArea(workArea, dt)
	local v35_ = self.spec_weeder
	if not self.isServer and self.currentUpdateDistance > Weeder.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v36_, _, v37_ = getWorldTranslation(workArea.start)
	local v38_, _, v39_ = getWorldTranslation(workArea.width)
	local v40_, _, v41_ = getWorldTranslation(workArea.height)
	local v42_ = FSDensityMapUtil.updateWeederArea(v36_, v37_, v38_, v39_, v40_, v41_, v35_.isHoeWeeder)
	if v35_.isGrasslandWeeder then
		local v43_ = FSDensityMapUtil.updateGrassRollerArea(v36_, v37_, v38_, v39_, v40_, v41_, false)
		v42_ = math.max(v42_, v43_)
	end
	v35_.workAreaParameters.lastArea = v35_.workAreaParameters.lastArea + v42_
	v35_.workAreaParameters.lastStatsArea = v35_.workAreaParameters.lastStatsArea + v42_
	v35_.isWorking = self:getLastSpeed() > 0.5
	if v35_.isWorking then
		v35_.stoneLastState = FSDensityMapUtil.getStoneArea(v36_, v37_, v38_, v39_, v40_, v41_)
	else
		v35_.stoneLastState = 0
	end
	return v42_, v42_
end

-- Local values: spec, hasSowingMachine, vehicles, i, weedSystem, weedMapId, weedFirstChannel, weedNumChannels, replacementData, startState, lastState, sourceState, targetState
function Weeder:updateWeederAIRequirements()
	local v45_ = self.spec_weeder
	if self.addAITerrainDetailRequiredRange ~= nil then
		local v46_ = self.rootVehicle:getChildVehicles()
		local v47_ = false
		for v48_ = 1, #v46_ do
			if SpecializationUtil.hasSpecialization(SowingMachine, v46_[v48_].specializations) and v46_[v48_]:getUseSowingMachineAIRequirements() then
				v47_ = true
			end
		end
		self:clearAIFruitRequirements()
		if not v47_ then
			local v49_ = g_currentMission.weedSystem
			if v49_ ~= nil then
				local v50_, v51_, v52_ = v49_:getDensityMapData()
				local v53_ = v49_:getWeederReplacements(v45_.isHoeWeeder)
				if v53_.weed ~= nil then
					local v54_ = -1
					local v55_ = -1
					for v56_, _ in pairs(v53_.weed.replacements) do
						if v54_ == -1 then
							v54_ = v56_
						elseif v56_ ~= v55_ + 1 then
							self:addAIFruitRequirement(nil, v54_, v55_, v50_, v51_, v52_)
							v54_ = v56_
						end
						v55_ = v56_
					end
					if v54_ ~= -1 then
						self:addAIFruitRequirement(nil, v54_, v55_, v50_, v51_, v52_)
					end
				end
			end
		end
	end
end

function Weeder:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.WEEDER
	end
	return superFunc(self, workArea, xmlFile, key)
end

-- Local values: isActive
function Weeder:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type ~= WorkAreaType.WEEDER then
		return superFunc(self, workArea)
	end
	local v65_ = true
	if workArea.requiresGroundContact and workArea.groundReferenceNode ~= nil then
		if v65_ then
			v65_ = self:getIsGroundReferenceNodeActive(workArea.groundReferenceNode)
		end
	end
	if v65_ and workArea.disableBackwards then
		if v65_ then
			v65_ = self.movingDirection > 0
		end
	end
	return v65_
end

function Weeder:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsImplementChainLowered()
end

-- Local values: spec, multiplier
function Weeder:getDirtMultiplier(superFunc)
	local v70_ = self.spec_weeder
	local v71_ = superFunc(self)
	if v70_.isWorking then
		v71_ = v71_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v71_
end

-- Local values: spec, multiplier, stoneMultiplier
function Weeder:getWearMultiplier(superFunc)
	local v74_ = self.spec_weeder
	local v75_ = superFunc(self)
	if v74_.isWorking then
		local v76_ = (v74_.stoneLastState == 0 or v74_.stoneWearMultiplierData == nil) and 1 or (v74_.stoneWearMultiplierData[v74_.stoneLastState] or 1)
		v75_ = v75_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * v76_
	end
	return v75_
end

-- Local values: spec
function Weeder:loadGroundParticleMapping(superFunc, xmlFile, key, mapping, index, i3dNode)
	if not superFunc(self, xmlFile, key, mapping, index, i3dNode) then
		return false
	end
	mapping.adjustColor = xmlFile:getValue(key .. "#adjustColor", false)
	if mapping.adjustColor then
		local v84_ = self.spec_weeder
		if v84_.colorParticleSystems == nil then
			v84_.colorParticleSystems = {}
		end
		mapping.lastColor = {}
		local v85_ = v84_.colorParticleSystems
		table.insert(v85_, mapping)
	end
	return true
end

-- Local values: spec
function Weeder:onStartWorkAreaProcessing(dt)
	local v87_ = self.spec_weeder
	v87_.isWorking = false
	v87_.workAreaParameters.lastArea = 0
	v87_.workAreaParameters.lastStatsArea = 0
end

-- Local values: spec
function Weeder:onEndWorkAreaProcessing(dt, hasProcessed)
	local v89_ = self.spec_weeder
	if self.isServer and v89_.workAreaParameters.lastStatsArea > 0 then
		self:updateLastWorkedArea(v89_.workAreaParameters.lastStatsArea)
	end
	if self.isClient then
		if v89_.isWorking then
			if not v89_.isWorkSamplePlaying then
				g_soundManager:playSamples(v89_.samples.work)
				v89_.isWorkSamplePlaying = true
				return
			end
		elseif v89_.isWorkSamplePlaying then
			g_soundManager:stopSamples(v89_.samples.work)
			v89_.isWorkSamplePlaying = false
		end
	end
end

function Weeder:onStateChange(state, data)
	if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
		self:updateWeederAIRequirements()
	end
end

-- Local values: spec
function Weeder:onDeactivate()
	if self.isClient then
		local v93_ = self.spec_weeder
		g_soundManager:stopSamples(v93_.samples.work)
		v93_.isWorkSamplePlaying = false
	end
end

-- Local values: spec
function Weeder:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local v95_ = self.spec_weeder
	v95_.startActivationTime = g_currentMission.time + v95_.startActivationTimeout
end
function Weeder.getDefaultSpeedLimit()
	return 15
end
