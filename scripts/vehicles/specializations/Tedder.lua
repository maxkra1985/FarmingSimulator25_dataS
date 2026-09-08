Tedder = {}
Tedder.CLIENT_DM_UPDATE_RADIUS = 50
function Tedder.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("tedder", false, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Tedder")
	v1_:register(XMLValueType.STRING, "vehicle.tedder#fillTypeConverter", "Fill type converter name")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.tedder.effects.effect(?)")
	v1_:register(XMLValueType.INT, "vehicle.tedder.effects.effect(?)#workAreaIndex", "Work area index", 1)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.tedder.effects.effect(?).sounds", "work")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.tedder.animationNodes")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.tedder.sounds", "work(?)")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".tedder#dropWindrowWorkAreaIndex", "Drop work area index", 1)
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".tedder#dropWindrowWorkAreaIndex", "Drop work area index", 1)
	v1_:setXMLSpecializationType()
end

function Tedder.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
	return v3_
end

function Tedder.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "preprocessTedderArea", Tedder.preprocessTedderArea)
	SpecializationUtil.registerFunction(vehicleType, "processTedderArea", Tedder.processTedderArea)
	SpecializationUtil.registerFunction(vehicleType, "processDropArea", Tedder.processDropArea)
end

function Tedder.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Tedder.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Tedder.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Tedder.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Tedder.doCheckSpeedLimit)
end

function Tedder.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Tedder)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Tedder)
end

-- Local values: spec, converter, data, input, converted, i, key, effects, effect
function Tedder:onLoad(savegame)
	local v8_ = self.spec_tedder
	v8_.fillTypeConverters = {}
	v8_.fillTypeConvertersReverse = {}
	local v9_ = self.xmlFile:getValue("vehicle.tedder#fillTypeConverter")
	if v9_ == nil then
		printWarning(string.format("Warning: Missing fill type converter in \'%s\'", self.configFileName))
	else
		local v10_ = g_fillTypeManager:getConverterDataByName(v9_)
		if v10_ ~= nil then
			for v11_, v12_ in pairs(v10_) do
				v8_.fillTypeConverters[v11_] = v12_
				if v8_.fillTypeConvertersReverse[v12_.targetFillTypeIndex] == nil then
					v8_.fillTypeConvertersReverse[v12_.targetFillTypeIndex] = {}
				end
				local v13_ = v8_.fillTypeConvertersReverse[v12_.targetFillTypeIndex]
				table.insert(v13_, v11_)
			end
		end
	end
	if self.isClient then
		v8_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.tedder.animationNodes", self.components, self, self.i3dMappings)
		v8_.effects = {}
		v8_.workAreaToEffects = {}
		local v14_ = 0
		while true do
			local v15_ = string.format("vehicle.tedder.effects.effect(%d)", v14_)
			if not self.xmlFile:hasProperty(v15_) then
				break
			end
			local v16_ = g_effectManager:loadEffect(self.xmlFile, v15_, self.components, self, self.i3dMappings)
			if v16_ ~= nil then
				local v17_ = {
					["effects"] = v16_,
					["workAreaIndex"] = self.xmlFile:getValue(v15_ .. "#workAreaIndex", 1),
					["activeTime"] = -1,
					["activeTimeDuration"] = 250,
					["isActive"] = false,
					["isActiveSent"] = false,
					["samples"] = {}
				}
				v17_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, v15_ .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
				local v18_ = v8_.effects
				table.insert(v18_, v17_)
			end
			v14_ = v14_ + 1
		end
		v8_.samples = {}
		v8_.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.tedder.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v8_.lastDroppedLiters = 0
	v8_.stoneLastState = 0
	v8_.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("TEDDER")
	v8_.fillTypesDirtyFlag = self:getNextDirtyFlag()
	v8_.effectDirtyFlag = self:getNextDirtyFlag()
	if self.addAIDensityHeightTypeRequirement ~= nil then
		self:addAIDensityHeightTypeRequirement(FillType.GRASS_WINDROW)
	end
end

-- Local values: spec, i, effect, workArea
function Tedder:onPostLoad(savegame)
	local v20_ = self.spec_tedder
	for v21_ = #v20_.effects, 1, -1 do
		local v22_ = v20_.effects[v21_]
		local v23_ = self:getWorkAreaByIndex(v22_.workAreaIndex)
		if v23_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid workAreaIndex \'%d\' for effect \'vehicle.tedder.effects.effect(%d)\'!", v22_.workAreaIndex, v21_)
			local v24_ = v20_.effects
			table.insert(v24_, v21_)
		else
			v22_.tedderWorkAreaFillTypeIndex = v23_.tedderWorkAreaIndex
			if v20_.workAreaToEffects[v23_.index] == nil then
				v20_.workAreaToEffects[v23_.index] = {}
			end
			local v25_ = v20_.workAreaToEffects[v23_.index]
			table.insert(v25_, v22_)
		end
	end
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Tedder)
	end
end

-- Local values: spec, _, effect
function Tedder:onDelete()
	local v27_ = self.spec_tedder
	if v27_.effects ~= nil then
		for _, v28_ in ipairs(v27_.effects) do
			g_effectManager:deleteEffects(v28_.effects)
			if v28_.samples ~= nil then
				g_soundManager:deleteSample(v28_.samples.work)
			end
		end
	end
	if v27_.samples ~= nil then
		g_soundManager:deleteSamples(v27_.samples.work)
	end
	g_animationManager:deleteAnimations(v27_.animationNodes)
end

-- Local values: spec, index, _, fillType, _, effect, fillType
function Tedder:onReadStream(streamId, connection)
	local v31_ = self.spec_tedder
	for v32_, _ in ipairs(v31_.tedderWorkAreaFillTypes) do
		local v33_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		v31_.tedderWorkAreaFillTypes[v32_] = v33_
	end
	for _, v34_ in ipairs(v31_.effects) do
		if streamReadBool(streamId) then
			local v35_ = v31_.tedderWorkAreaFillTypes[v34_.tedderWorkAreaFillTypeIndex]
			g_effectManager:setEffectTypeInfo(v34_.effects, v35_)
			g_effectManager:startEffects(v34_.effects)
		else
			g_effectManager:stopEffects(v34_.effects)
		end
	end
end

-- Local values: spec, _, fillTypeIndex, _, effect
function Tedder:onWriteStream(streamId, connection)
	local v38_ = self.spec_tedder
	for _, v39_ in ipairs(v38_.tedderWorkAreaFillTypes) do
		streamWriteUIntN(streamId, v39_, FillTypeManager.SEND_NUM_BITS)
	end
	for _, v40_ in ipairs(v38_.effects) do
		streamWriteBool(streamId, v40_.isActiveSent)
	end
end

-- Local values: spec, index, _, fillType, anyEffectActive, _, effect, fillType
function Tedder:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v44_ = self.spec_tedder
		if streamReadBool(streamId) then
			for v45_, _ in ipairs(v44_.tedderWorkAreaFillTypes) do
				local v46_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
				v44_.tedderWorkAreaFillTypes[v45_] = v46_
			end
		end
		if streamReadBool(streamId) then
			local v47_ = false
			for _, v48_ in ipairs(v44_.effects) do
				if streamReadBool(streamId) then
					local v49_ = v44_.tedderWorkAreaFillTypes[v48_.tedderWorkAreaFillTypeIndex]
					g_effectManager:setEffectTypeInfo(v48_.effects, v49_)
					g_effectManager:startEffects(v48_.effects)
					v47_ = true
					if not g_soundManager:getIsSamplePlaying(v48_.samples.work) then
						g_soundManager:playSample(v48_.samples.work)
					end
				else
					g_effectManager:stopEffects(v48_.effects)
					g_soundManager:stopSample(v48_.samples.work)
				end
			end
			if v47_ then
				if not g_soundManager:getIsSamplePlaying(v44_.samples.work[1]) then
					g_soundManager:playSamples(v44_.samples.work)
					return
				end
			else
				g_soundManager:stopSamples(v44_.samples.work)
			end
		end
	end
end

-- Local values: spec, _, fillTypeIndex, _, effect
function Tedder:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v54_ = self.spec_tedder
		local v55_ = streamWriteBool
		local v56_ = v54_.fillTypesDirtyFlag
		if v55_(streamId, bit32.band(dirtyMask, v56_) ~= 0) then
			for _, v57_ in ipairs(v54_.tedderWorkAreaFillTypes) do
				streamWriteUIntN(streamId, v57_, FillTypeManager.SEND_NUM_BITS)
			end
		end
		local v58_ = streamWriteBool
		local v59_ = v54_.effectDirtyFlag
		if v58_(streamId, bit32.band(dirtyMask, v59_) ~= 0) then
			for _, v60_ in ipairs(v54_.effects) do
				streamWriteBool(streamId, v60_.isActiveSent)
			end
		end
	end
end

-- Local values: spec, anyEffectActive, _, effect
function Tedder:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v62_ = self.spec_tedder
	if self.isServer then
		local v63_ = false
		for _, v64_ in ipairs(v62_.effects) do
			if v64_.isActive and g_currentMission.time > v64_.activeTime then
				v64_.isActive = false
				if v64_.isActiveSent then
					v64_.isActiveSent = false
					self:raiseDirtyFlags(v62_.effectDirtyFlag)
				end
				if self.isClient then
					g_effectManager:stopEffects(v64_.effects)
					g_soundManager:stopSample(v64_.samples.work)
				end
			end
			v63_ = v63_ or v64_.isActive
		end
		if self.isClient and not v63_ then
			g_soundManager:stopSamples(v62_.samples.work)
		end
	end
end

-- Local values: retValue, spec
function Tedder:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v70_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.TEDDER
	end
	if workArea.type == WorkAreaType.TEDDER then
		workArea.dropWindrowWorkAreaIndex = xmlFile:getValue(key .. ".tedder#dropWindrowWorkAreaIndex", 1)
		workArea.litersToDrop = 0
		workArea.lastPickupLiters = 0
		workArea.lastDropFillType = FillType.UNKNOWN
		workArea.lastDroppedLiters = 0
		workArea.tedderParticlesActive = false
		workArea.tedderParticlesActiveSent = false
		local v71_ = self.spec_tedder
		if v71_.tedderWorkAreaFillTypes == nil then
			v71_.tedderWorkAreaFillTypes = {}
		end
		local v72_ = v71_.tedderWorkAreaFillTypes
		local v73_ = FruitType.UNKNOWN
		table.insert(v72_, v73_)
		workArea.tedderWorkAreaIndex = #v71_.tedderWorkAreaFillTypes
	end
	return v70_
end

-- Local values: spec, multiplier
function Tedder:getDirtMultiplier(superFunc)
	local v76_ = self.spec_tedder
	local v77_ = superFunc(self)
	if v76_.isWorking then
		v77_ = v77_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v77_
end

-- Local values: spec, multiplier, stoneMultiplier
function Tedder:getWearMultiplier(superFunc)
	local v80_ = self.spec_tedder
	local v81_ = superFunc(self)
	if v80_.isWorking then
		local v82_ = (v80_.stoneLastState == 0 or v80_.stoneWearMultiplierData == nil) and 1 or (v80_.stoneWearMultiplierData[v80_.stoneLastState] or 1)
		v81_ = v81_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * v82_
	end
	return v81_
end

function Tedder:doCheckSpeedLimit(superFunc)
	local v85_ = not superFunc(self) and self:getIsTurnedOn()
	if v85_ then
		v85_ = self:getIsImplementChainLowered()
	end
	return v85_
end

function Tedder:preprocessTedderArea(workArea)
	workArea.lastPickupLiters = 0
	workArea.lastDroppedLiters = 0
end

-- Local values: spec, workAreaSpec, sx, sy, sz, wx, wy, wz, hx, hy, hz, lsx, lsy, lsz, lex, ley, lez, lineRadius, targetFillType, inputFillTypes, pickedUpLiters, _, inputFillType, dropArea, dropped, lastSpeed, changedFillType, effects, _, effect, areaWidth, area
function Tedder:processTedderArea(workArea, dt)
	local v89_ = self.spec_tedder
	local v90_ = self.spec_workArea
	if not self.isServer and self.currentUpdateDistance > Tedder.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v91_, v92_, v93_ = getWorldTranslation(workArea.start)
	local v94_, v95_, v96_ = getWorldTranslation(workArea.width)
	local v97_, v98_, v99_ = getWorldTranslation(workArea.height)
	local v100_, v101_, v102_, v103_, v104_, v105_, v106_ = DensityMapHeightUtil.getLineByAreaDimensions(v91_, v92_, v93_, v94_, v95_, v96_, v97_, v98_, v99_, true)
	for v111_, v108_ in pairs(v89_.fillTypeConvertersReverse) do
		local v109_ = 0
		for _, v110_ in ipairs(v108_) do
			v109_ = v109_ + DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, v110_, v100_, v101_, v102_, v103_, v104_, v105_, v106_, nil, nil, false, nil)
		end
		if v109_ == 0 and workArea.lastDropFillType ~= FillType.UNKNOWN then
			local v111_ = workArea.lastDropFillType
		end
		workArea.lastPickupLiters = -v109_
		workArea.litersToDrop = workArea.litersToDrop + workArea.lastPickupLiters
		local v112_ = v90_.workAreas[workArea.dropWindrowWorkAreaIndex]
		if v112_ ~= nil and workArea.litersToDrop > 0 then
			local v113_ = self:processDropArea(v112_, v111_, workArea.litersToDrop)
			workArea.lastDropFillType = v111_
			workArea.lastDroppedLiters = v113_
			v89_.lastDroppedLiters = v89_.lastDroppedLiters + v113_
			workArea.litersToDrop = workArea.litersToDrop - v113_
			if self.isServer then
				local v114_ = self:getLastSpeed(true)
				if v113_ > 0 and v114_ > 0.5 then
					local v115_
					if v89_.tedderWorkAreaFillTypes[workArea.tedderWorkAreaIndex] == v111_ then
						v115_ = false
					else
						v89_.tedderWorkAreaFillTypes[workArea.tedderWorkAreaIndex] = v111_
						self:raiseDirtyFlags(v89_.fillTypesDirtyFlag)
						v115_ = true
					end
					local v116_ = v89_.workAreaToEffects[workArea.index]
					if v116_ ~= nil then
						for _, v117_ in ipairs(v116_) do
							v117_.activeTime = g_currentMission.time + v117_.activeTimeDuration
							if not v117_.isActiveSent then
								v117_.isActiveSent = true
								self:raiseDirtyFlags(v89_.effectDirtyFlag)
							end
							if self.isClient then
								if v115_ then
									g_effectManager:setEffectTypeInfo(v117_.effects, v111_)
								end
								if not v117_.isActive then
									g_effectManager:setEffectTypeInfo(v117_.effects, v111_)
									g_effectManager:startEffects(v117_.effects)
									g_soundManager:playSample(v117_.samples.work)
									if not g_soundManager:getIsSamplePlaying(v89_.samples.work[1]) then
										g_soundManager:playSamples(v89_.samples.work)
									end
								end
								local v118_ = g_effectManager
								local v119_ = v117_.effects
								local v120_ = v114_ / self:getSpeedLimit()
								v118_:setDensity(v119_, (math.max(v120_, 0.6)))
							end
							v117_.isActive = true
						end
					end
				end
			end
		end
	end
	if self:getLastSpeed() > 0.5 then
		v89_.stoneLastState = FSDensityMapUtil.getStoneArea(v91_, v93_, v94_, v96_, v97_, v99_)
	else
		v89_.stoneLastState = 0
	end
	local v121_ = MathUtil.vector3Length(v100_ - v103_, v101_ - v104_, v102_ - v105_) * self.lastMovedDistance
	return v121_, v121_
end

-- Local values: lsx, lsy, lsz, lex, ley, lez, lineRadius, dropped, lineOffset
function Tedder:processDropArea(dropArea, fillType, litersToDrop)
	if not self.isServer and self.currentUpdateDistance > Tedder.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v126_, v127_, v128_, v129_, v130_, v131_, v132_ = DensityMapHeightUtil.getLineByArea(dropArea.start, dropArea.width, dropArea.height, true)
	local v133_, v134_ = DensityMapHeightUtil.tipToGroundAroundLine(self, litersToDrop, fillType, v126_, v127_, v128_, v129_, v130_, v131_, v132_, nil, dropArea.lineOffset, false, nil, false)
	dropArea.lineOffset = v134_
	return v133_
end

-- Local values: spec
function Tedder:onStartWorkAreaProcessing(dt)
	self.spec_tedder.lastDroppedLiters = 0
end

-- Local values: spec
function Tedder:onEndWorkAreaProcessing(dt, hasProcessed)
	local v137_ = self.spec_tedder
	v137_.isWorking = v137_.lastDroppedLiters > 0
end

-- Local values: spec
function Tedder:onTurnedOn()
	if self.isClient then
		local v139_ = self.spec_tedder
		g_animationManager:startAnimations(v139_.animationNodes)
	end
end

-- Local values: spec, _, effect
function Tedder:onTurnedOff()
	if self.isClient then
		local v141_ = self.spec_tedder
		g_animationManager:stopAnimations(v141_.animationNodes)
		for _, v142_ in ipairs(v141_.effects) do
			g_effectManager:stopEffects(v142_.effects)
		end
	end
end

function Tedder:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	fieldCourseSettings.headlandsFirst = true
	fieldCourseSettings.workInitialSegment = true
end

-- Local values: spec, _, effect
function Tedder:onDeactivate()
	if self.isClient then
		local v145_ = self.spec_tedder
		for _, v146_ in ipairs(v145_.effects) do
			g_effectManager:stopEffects(v146_.effects)
		end
	end
end
function Tedder.getDefaultSpeedLimit()
	return 15
end
