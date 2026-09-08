Mulcher = {}
Mulcher.AI_REQUIRED_GROUND_TYPES = {
	FieldGroundType.SOWN,
	FieldGroundType.DIRECT_SOWN,
	FieldGroundType.PLANTED,
	FieldGroundType.RIDGE_SOWN,
	FieldGroundType.HARVEST_READY,
	FieldGroundType.HARVEST_READY_OTHER,
	FieldGroundType.GRASS,
	FieldGroundType.GRASS_CUT
}
Mulcher.CLIENT_DM_UPDATE_RADIUS = 50
function Mulcher.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("mulcher", true, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Mulcher")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.mulcher.effects.effect(?)")
	v1_:register(XMLValueType.INT, "vehicle.mulcher.effects.effect(?)#workAreaIndex", "Work area index", 1)
	v1_:register(XMLValueType.INT, "vehicle.mulcher.effects.effect(?)#activeDirection", "If vehicle is driving into this direction the effect will be activated (0 = any direction)", 0)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.mulcher.sounds", "idle(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.mulcher.sounds", "work(?)")
	v1_:setXMLSpecializationType()
end

function Mulcher.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(GroundReference, specializations)
	end
	return v3_
end

function Mulcher.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processMulcherArea", Mulcher.processMulcherArea)
end

function Mulcher.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Mulcher.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", Mulcher.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Mulcher.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Mulcher.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", Mulcher.getAIImplementUseVineSegment)
end

function Mulcher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Mulcher)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Mulcher)
end

-- Local values: spec, i, key, effects, effect, _, effectObject, _, fruitType, weedSystem, replacementData, _, data, fruitType, sourceState, targetState
function Mulcher:onLoad(savegame)
	if self:getGroundReferenceNodeFromIndex(1) == nil then
		printWarning("Warning: No ground reference nodes in  " .. self.configFileName)
	end
	local v8_ = self.spec_mulcher
	if self.isClient then
		v8_.samples = {}
		v8_.samples.idle = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.mulcher.sounds", "idle", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.mulcher.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.isWorkSamplePlaying = false
		v8_.isIdleSamplePlaying = false
	end
	v8_.effects = {}
	v8_.workAreaToEffects = {}
	local v9_ = 0
	while true do
		local v10_ = string.format("vehicle.mulcher.effects.effect(%d)", v9_)
		if not self.xmlFile:hasProperty(v10_) then
			break
		end
		local v11_ = g_effectManager:loadEffect(self.xmlFile, v10_, self.components, self, self.i3dMappings)
		if v11_ ~= nil then
			local v12_ = {
				["effects"] = v11_,
				["workAreaIndex"] = self.xmlFile:getValue(v10_ .. "#workAreaIndex", 1),
				["activeDirection"] = self.xmlFile:getValue(v10_ .. "#activeDirection", 0),
				["activeTime"] = -1,
				["activeTimeDuration"] = 250,
				["isActive"] = false,
				["isActiveSent"] = false
			}
			for _, v13_ in ipairs(v11_) do
				if v13_:isa(CultivatorMotionPathEffect) then
					v13_.autoTurnOffSpeed = -math.huge
				end
			end
			local v14_ = v8_.effects
			table.insert(v14_, v12_)
		end
		v9_ = v9_ + 1
	end
	v8_.effectFillType = FillType.WHEAT
	if self.addAIGroundTypeRequirements ~= nil then
		self:addAIGroundTypeRequirements(Mulcher.AI_REQUIRED_GROUND_TYPES)
		self:clearAIFruitRequirements()
		for _, v15_ in ipairs(g_fruitTypeManager:getFruitTypes()) do
			if v15_.isCultivationAllowed then
				if v15_.mulchedState > v15_.cutState then
					self:addAIFruitRequirement(v15_.index, 2, v15_.mulchedState - 1)
				else
					self:addAIFruitRequirement(v15_.index, 2, 15)
				end
			end
		end
		local v16_ = g_currentMission.weedSystem
		if v16_ ~= nil then
			local v17_ = v16_:getMulcherReplacements()
			if v17_.custom ~= nil then
				for _, v18_ in ipairs(v17_.custom) do
					local v19_ = v18_.fruitType
					if v19_.terrainDataPlaneId ~= nil then
						for v20_, _ in pairs(v18_.replacements) do
							self:addAIFruitRequirement(v19_.index, v20_, v20_)
						end
					end
				end
			end
		end
	end
	v8_.isWorking = false
	v8_.isWorkingIdle = false
	v8_.lastWorkTime = -math.huge
	v8_.stoneLastState = 0
	v8_.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("MULCHER")
	v8_.effectDirtyFlag = self:getNextDirtyFlag()
	if not self.isClient or #v8_.effects == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Mulcher)
	end
end

-- Local values: spec, i, effect, workArea
function Mulcher:onPostLoad(savegame)
	local v22_ = self.spec_mulcher
	for v23_ = #v22_.effects, 1, -1 do
		local v24_ = v22_.effects[v23_]
		local v25_ = self:getWorkAreaByIndex(v24_.workAreaIndex)
		if v25_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid workAreaIndex \'%d\' for effect \'vehicle.mulcher.effects.effect(%d)\'!", v24_.workAreaIndex, v23_)
			table.remove(v22_.effects, v23_)
		else
			if v22_.workAreaToEffects[v25_.index] == nil then
				v22_.workAreaToEffects[v25_.index] = {}
			end
			local v26_ = v22_.workAreaToEffects[v25_.index]
			table.insert(v26_, v24_)
		end
	end
end

-- Local values: spec, _, effect
function Mulcher:onDelete()
	local v28_ = self.spec_mulcher
	if v28_.samples ~= nil then
		g_soundManager:deleteSamples(v28_.samples.idle)
		g_soundManager:deleteSamples(v28_.samples.work)
	end
	if v28_.effects ~= nil then
		for _, v29_ in ipairs(v28_.effects) do
			g_effectManager:deleteEffects(v29_.effects)
		end
	end
end

-- Local values: spec, _, effect
function Mulcher:onReadStream(streamId, connection)
	local v32_ = self.spec_mulcher
	for _, v33_ in ipairs(v32_.effects) do
		if streamReadBool(streamId) then
			g_effectManager:setEffectTypeInfo(v33_.effects, v32_.effectFillType)
			g_effectManager:startEffects(v33_.effects)
		else
			g_effectManager:stopEffects(v33_.effects)
		end
	end
end

-- Local values: spec, _, effect
function Mulcher:onWriteStream(streamId, connection)
	local v36_ = self.spec_mulcher
	for _, v37_ in ipairs(v36_.effects) do
		streamWriteBool(streamId, v37_.isActive)
	end
end

-- Local values: spec, _, effect
function Mulcher:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v41_ = self.spec_mulcher
		if streamReadBool(streamId) then
			for _, v42_ in ipairs(v41_.effects) do
				if streamReadBool(streamId) then
					g_effectManager:setEffectTypeInfo(v42_.effects, v41_.effectFillType)
					g_effectManager:startEffects(v42_.effects)
				else
					g_effectManager:stopEffects(v42_.effects)
				end
			end
		end
	end
end

-- Local values: spec, _, effect
function Mulcher:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v47_ = self.spec_mulcher
		local v48_ = streamWriteBool
		local v49_ = v47_.effectDirtyFlag
		if v48_(streamId, bit32.band(dirtyMask, v49_) ~= 0) then
			for _, v50_ in ipairs(v47_.effects) do
				streamWriteBool(streamId, v50_.isActive)
			end
		end
	end
end

-- Local values: spec, _, effect
function Mulcher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v52_ = self.spec_mulcher
		for _, v53_ in ipairs(v52_.effects) do
			if v53_.isActive and g_currentMission.time > v53_.activeTime then
				v53_.isActive = false
				self:raiseDirtyFlags(v52_.effectDirtyFlag)
				g_effectManager:stopEffects(v53_.effects)
			end
		end
	end
end

-- Local values: spec, xs, _, zs, xw, _, zw, xh, _, zh, realArea, area, effects, _, effect
function Mulcher:processMulcherArea(workArea, dt)
	local v56_ = self.spec_mulcher
	v56_.isWorkingIdle = self:getLastSpeed() > 0.5
	local v57_, _, v58_ = getWorldTranslation(workArea.start)
	local v59_, _, v60_ = getWorldTranslation(workArea.width)
	local v61_, _, v62_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v57_, v58_, v59_, v60_, v61_, v62_)
	if self.isServer or self.currentUpdateDistance <= Mulcher.CLIENT_DM_UPDATE_RADIUS then
		local v63_, v64_ = FSDensityMapUtil.updateMulcherArea(v57_, v58_, v59_, v60_, v61_, v62_)
		if v63_ > 0 and v56_.isWorkingIdle then
			local v65_ = v56_.workAreaToEffects[workArea.index]
			if v65_ ~= nil then
				for _, v66_ in ipairs(v65_) do
					if v66_.activeDirection == 0 or self.movingDirection == v66_.activeDirection then
						v66_.activeTime = g_currentMission.time + v66_.activeTimeDuration
						if not v66_.isActive then
							g_effectManager:setEffectTypeInfo(v66_.effects, v56_.effectFillType)
							g_effectManager:startEffects(v66_.effects)
							v66_.isActive = true
							self:raiseDirtyFlags(v56_.effectDirtyFlag)
						end
					end
				end
			end
			v56_.lastWorkTime = g_time
		end
		v56_.isWorking = g_time - v56_.lastWorkTime < 500
		if v56_.isWorking then
			v56_.stoneLastState = FSDensityMapUtil.getStoneArea(v57_, v58_, v59_, v60_, v61_, v62_)
			return v63_, v64_
		else
			v56_.stoneLastState = 0
			return v63_, v64_
		end
	else
		return 0, 0
	end
end

function Mulcher:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsImplementChainLowered()
end

-- Local values: spec
function Mulcher:getDoGroundManipulation(superFunc)
	if self.spec_mulcher.isWorking then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec, multiplier
function Mulcher:getDirtMultiplier(superFunc)
	local v73_ = self.spec_mulcher
	local v74_ = superFunc(self)
	if v73_.isWorking then
		v74_ = v74_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / v73_.speedLimit
	end
	return v74_
end

-- Local values: spec, multiplier, stoneMultiplier
function Mulcher:getWearMultiplier(superFunc)
	local v77_ = self.spec_mulcher
	local v78_ = superFunc(self)
	if v77_.isWorking then
		local v79_ = (v77_.stoneLastState == 0 or v77_.stoneWearMultiplierData == nil) and 1 or (v77_.stoneWearMultiplierData[v77_.stoneLastState] or 1)
		v78_ = v78_ + self:getWorkWearMultiplier() * self:getLastSpeed() / v77_.speedLimit * v79_
	end
	return v78_
end

-- Local values: startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, area, areaTotal
function Mulcher:getAIImplementUseVineSegment(superFunc, placeable, segment, segmentSide)
	local v84_, v85_, v86_, v87_, v88_, v89_ = placeable:getSegmentSideArea(segment, segmentSide)
	local v90_, v91_ = AIVehicleUtil.getAIAreaOfVehicle(self, v84_, v85_, v86_, v87_, v88_, v89_)
	if v91_ > 0 then
		return v90_ / v91_ > 0.01
	else
		return false
	end
end

-- Local values: retValue
function Mulcher:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v97_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.MULCHER
	end
	return v97_
end

-- Local values: spec, _, effect
function Mulcher:onDeactivate()
	local v99_ = self.spec_mulcher
	if self.isClient then
		g_soundManager:stopSamples(v99_.samples.idle)
		g_soundManager:stopSamples(v99_.samples.work)
		v99_.isWorkSamplePlaying = false
		v99_.isIdleSamplePlaying = false
	end
	for _, v100_ in ipairs(v99_.effects) do
		g_effectManager:stopEffects(v100_.effects)
	end
end

-- Local values: spec
function Mulcher:onStartWorkAreaProcessing(dt)
	local v102_ = self.spec_mulcher
	v102_.isWorking = false
	v102_.isWorkingIdle = false
end

-- Local values: spec
function Mulcher:onEndWorkAreaProcessing(dt)
	local v104_ = self.spec_mulcher
	if self.isClient then
		if v104_.isWorking then
			if not v104_.isWorkSamplePlaying then
				g_soundManager:playSamples(v104_.samples.work)
				v104_.isWorkSamplePlaying = true
			end
		elseif v104_.isWorkSamplePlaying then
			g_soundManager:stopSamples(v104_.samples.work)
			v104_.isWorkSamplePlaying = false
		end
		if v104_.isWorkingIdle then
			if not v104_.isIdleSamplePlaying then
				g_soundManager:playSamples(v104_.samples.idle)
				v104_.isIdleSamplePlaying = true
				return
			end
		elseif v104_.isIdleSamplePlaying then
			g_soundManager:stopSamples(v104_.samples.idle)
			v104_.isIdleSamplePlaying = false
		end
	end
end

function Mulcher:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	fieldCourseSettings.headlandsFirst = true
	fieldCourseSettings.workInitialSegment = true
end
function Mulcher.getDefaultSpeedLimit()
	return 15
end
