source("dataS/scripts/vehicles/specializations/events/MowerToggleWindrowDropEvent.lua")
Mower = {}
Mower.CLIENT_DM_UPDATE_RADIUS = 50
function Mower.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("mower", false, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Mower")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.mower.animationNodes")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.mower.cutterEffects")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.mower.dropEffects.dropEffect(?)")
	v1_:register(XMLValueType.INT, "vehicle.mower.dropEffects.dropEffect(?)#dropAreaIndex", "Drop area index", 1)
	v1_:register(XMLValueType.INT, "vehicle.mower.dropEffects.dropEffect(?)#workAreaIndex", "Work area index", 1)
	v1_:register(XMLValueType.STRING, "vehicle.mower#fruitTypeConverter", "Fruit type converter name")
	v1_:register(XMLValueType.INT, "vehicle.mower#fillUnitIndex", "Fill unit index")
	v1_:register(XMLValueType.FLOAT, "vehicle.mower#pickupFillScale", "Pickup fill scale", 1)
	v1_:register(XMLValueType.L10N_STRING, "vehicle.mower.toggleWindrowDrop#enableText", "Enable windrow drop text")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.mower.toggleWindrowDrop#disableText", "Disable windrow drop text")
	v1_:register(XMLValueType.STRING, "vehicle.mower.toggleWindrowDrop#animationName", "Windrow drop animation name")
	v1_:register(XMLValueType.FLOAT, "vehicle.mower.toggleWindrowDrop#animationEnableSpeed", "Animation enable speed", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.mower.toggleWindrowDrop#animationDisableSpeed", "Animation disable speed", "inversed \'animationEnableSpeed\'")
	v1_:register(XMLValueType.BOOL, "vehicle.mower.toggleWindrowDrop#startEnabled", "Start windrow drop enabled", false)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.mower.sounds", "cut(?)")
	v1_:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_KEY .. ".mower#dropWindrow", "Drop windrow", true)
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".mower#dropAreaIndex", "Drop area index", 1)
	v1_:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".mower#dropWindrow", "Drop windrow", true)
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".mower#dropAreaIndex", "Drop area index", 1)
	v1_:setXMLSpecializationType()
end

function Mower.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(FruitExtraObjects, specializations)
	end
	return v3_
end

function Mower.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processMowerArea", Mower.processMowerArea)
	SpecializationUtil.registerFunction(vehicleType, "processDropArea", Mower.processDropArea)
	SpecializationUtil.registerFunction(vehicleType, "getDropArea", Mower.getDropArea)
	SpecializationUtil.registerFunction(vehicleType, "setDropEffectEnabled", Mower.setDropEffectEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setCutSoundEnabled", Mower.setCutSoundEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setUseMowerWindrowDropAreas", Mower.setUseMowerWindrowDropAreas)
end

function Mower.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Mower.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Mower.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Mower.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Mower.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Mower.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFruitExtraObjectTypeData", Mower.getFruitExtraObjectTypeData)
end

function Mower.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Mower)
end

-- Local values: spec, converter, data, input, converted, mission, _, groundTypeFirstChannel, groundTypeNumChannels, grassValue, sowingValue, harvestReady, harvestReadyOther, inputFruitType, _, desc
function Mower:onLoad(savegame)
	local v_u_8_ = self.spec_mower
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerEffects.mowerEffect", "vehicle.mower.dropEffects.dropEffect")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerEffects.mowerEffect#mowerCutArea", "vehicle.mower.dropEffects.dropEffect#dropAreaIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.mower.turnOnNodes.turnOnNode", "mower")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerStartSound", "vehicle.turnOnVehicle.sounds.start")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerStopSound", "vehicle.turnOnVehicle.sounds.stop")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerSound", "vehicle.turnOnVehicle.sounds.work")
	if self.isClient then
		v_u_8_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mower.animationNodes", self.components, self, self.i3dMappings)
		v_u_8_.samples = {}
		v_u_8_.samples.cut = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.mower.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v_u_8_.dropEffects = {}
	self.xmlFile:iterate("vehicle.mower.dropEffects.dropEffect", function(_, p9_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v10_ = g_effectManager:loadEffect(self.xmlFile, p9_, self.components, self, self.i3dMappings)
		if v10_ ~= nil then
			local v11_ = {
				["effects"] = v10_,
				["dropAreaIndex"] = self.xmlFile:getValue(p9_ .. "#dropAreaIndex", 1),
				["workAreaIndex"] = self.xmlFile:getValue(p9_ .. "#workAreaIndex", 1)
			}
			if self:getWorkAreaByIndex(v11_.dropAreaIndex) ~= nil then
				if self:getWorkAreaByIndex(v11_.workAreaIndex) == nil then
					Logging.xmlWarning(self.xmlFile, "Invalid workAreaIndex \'%s\' in \'%s\'", v11_.workAreaIndex, p9_)
				else
					v11_.activeTime = -1
					v11_.activeTimeDuration = 750
					v11_.isActive = false
					v11_.isActiveSent = false
					local v12_ = v_u_8_.dropEffects
					table.insert(v12_, v11_)
				end
			end
			Logging.xmlWarning(self.xmlFile, "Invalid dropAreaIndex \'%s\' in \'%s\'", v11_.dropAreaIndex, p9_)
		end
	end)
	v_u_8_.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.mower.cutterEffects", self.components, self, self.i3dMappings)
	if v_u_8_.dropAreas == nil then
		v_u_8_.dropAreas = {}
	end
	v_u_8_.fruitTypeConverters = {}
	local v13_ = self.xmlFile:getValue("vehicle.mower#fruitTypeConverter")
	if v13_ == nil then
		printWarning(string.format("Warning: Missing fruit type converter in \'%s\'", self.configFileName))
	else
		local v14_ = g_fruitTypeManager:getConverterDataByName(v13_)
		if v14_ ~= nil then
			for v15_, v16_ in pairs(v14_) do
				v_u_8_.fruitTypeConverters[v15_] = v16_
			end
		end
	end
	v_u_8_.fillUnitIndex = self.xmlFile:getValue("vehicle.mower#fillUnitIndex")
	v_u_8_.pickupFillScale = self.xmlFile:getValue("vehicle.mower#pickupFillScale", 1)
	v_u_8_.toggleWindrowDropEnableText = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#enableText", nil, self.customEnvironment, false)
	v_u_8_.toggleWindrowDropDisableText = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#disableText", nil, self.customEnvironment, false)
	v_u_8_.toggleWindrowDropAnimation = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#animationName")
	v_u_8_.enableWindrowDropAnimationSpeed = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#animationEnableSpeed", 1)
	v_u_8_.disableWindrowDropAnimationSpeed = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#animationDisableSpeed", -v_u_8_.enableWindrowDropAnimationSpeed)
	v_u_8_.useWindrowDropAreas = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#startEnabled", false)
	v_u_8_.workAreaParameters = {}
	v_u_8_.workAreaParameters.lastChangedArea = 0
	v_u_8_.workAreaParameters.lastStatsArea = 0
	v_u_8_.workAreaParameters.lastTotalArea = 0
	v_u_8_.workAreaParameters.lastUsedAreas = 0
	v_u_8_.workAreaParameters.lastUsedAreasSum = 0
	v_u_8_.workAreaParameters.lastUsedAreasPct = 0
	v_u_8_.workAreaParameters.lastUsedAreasTime = 0
	v_u_8_.workAreaParameters.lastCutTime = -math.huge
	v_u_8_.workAreaParameters.lastInputFruitType = FruitType.UNKNOWN
	v_u_8_.workAreaParameters.lastInputGrowthState = 0
	v_u_8_.isWorking = false
	v_u_8_.isCutting = false
	v_u_8_.lastDropTime = -math.huge
	v_u_8_.effectsAreRunning = false
	v_u_8_.lastFruitTypeIndex = FruitType.UNKNOWN
	v_u_8_.lastFruitGrowthState = 0
	v_u_8_.stoneLastState = 0
	v_u_8_.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("MOWER")
	v_u_8_.dirtyFlag = self:getNextDirtyFlag()
	v_u_8_.effectDirtyFlag = self:getNextDirtyFlag()
	if self.addAITerrainDetailRequiredRange ~= nil then
		local _, v17_, v18_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v19_ = FieldGroundType.getValueByType(FieldGroundType.GRASS)
		self:addAITerrainDetailRequiredRange(v19_, v19_, v17_, v18_)
		local v20_ = FieldGroundType.getValueByType(FieldGroundType.SOWN)
		self:addAITerrainDetailRequiredRange(v20_, v20_, v17_, v18_)
		local v21_ = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY)
		self:addAITerrainDetailRequiredRange(v21_, v21_, v17_, v18_)
		local v22_ = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY_OTHER)
		self:addAITerrainDetailRequiredRange(v22_, v22_, v17_, v18_)
	end
	if self.addAIFruitRequirement ~= nil then
		for v23_, _ in pairs(v_u_8_.fruitTypeConverters) do
			local v24_ = g_fruitTypeManager:getFruitTypeByIndex(v23_)
			self:addAIFruitRequirement(v24_.index, v24_.minHarvestingGrowthState, v24_.maxHarvestingGrowthState)
		end
	end
	if #v_u_8_.cutterEffects == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", Mower)
	end
end

-- Local values: spec, i, workArea, _, dropEffect
function Mower:onPostLoad(savegame)
	local v26_ = self.spec_mower
	v26_.workAreas = self:getTypedWorkAreas(WorkAreaType.MOWER)
	for v27_ = 1, #v26_.workAreas do
		local v28_ = v26_.workAreas[v27_]
		v28_.dropEffects = {}
		for _, v29_ in pairs(v26_.dropEffects) do
			if v29_.workAreaIndex == v28_.index then
				local v30_ = v28_.dropEffects
				table.insert(v30_, v29_)
			end
		end
	end
end

-- Local values: spec, _, dropEffect
function Mower:onDelete()
	local v32_ = self.spec_mower
	if self.isClient then
		g_animationManager:deleteAnimations(v32_.animationNodes)
		if v32_.samples ~= nil then
			g_soundManager:deleteSamples(v32_.samples.cut)
		end
	end
	if v32_.dropEffects ~= nil then
		for _, v33_ in pairs(v32_.dropEffects) do
			g_effectManager:deleteEffects(v33_.effects)
		end
	end
	g_effectManager:deleteEffects(v32_.cutterEffects)
end

-- Local values: spec, useMowerWindrowDropAreas
function Mower:onReadStream(streamId, connection)
	local v36_ = self.spec_mower
	if v36_.toggleWindrowDropEnableText ~= nil and v36_.toggleWindrowDropDisableText ~= nil then
		self:setUseMowerWindrowDropAreas(streamReadBool(streamId), true)
	end
end

-- Local values: spec
function Mower:onWriteStream(streamId, connection)
	local v39_ = self.spec_mower
	if v39_.toggleWindrowDropEnableText ~= nil and v39_.toggleWindrowDropDisableText ~= nil then
		streamWriteBool(streamId, v39_.useWindrowDropAreas)
	end
end

-- Local values: spec, _, dropEffect, effectsAreRunning, inputFruitType
function Mower:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v43_ = self.spec_mower
		if #v43_.dropEffects > 0 then
			if streamReadBool(streamId) then
				for _, v44_ in ipairs(v43_.dropEffects) do
					v44_.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
					self:setDropEffectEnabled(v44_, streamReadBool(streamId))
				end
			end
		else
			self:setCutSoundEnabled(streamReadBool(streamId))
		end
		if streamReadBool(streamId) then
			local v45_ = streamReadBool(streamId)
			if v45_ then
				v43_.lastFruitGrowthState = streamReadUIntN(streamId, 4)
				local v46_ = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
				if v46_ ~= v43_.lastFruitTypeIndex then
					self:updateFruitExtraObjects()
					v43_.lastFruitTypeIndex = v46_
				end
				self:setTestAreaRequirements(v43_.lastFruitTypeIndex)
			end
			if v45_ ~= v43_.effectsAreRunning then
				v43_.effectsAreRunning = v45_
				if not v45_ then
					g_effectManager:stopEffects(v43_.cutterEffects)
				end
			end
		end
	end
end

-- Local values: spec, _, dropEffect
function Mower:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v51_ = self.spec_mower
		if #v51_.dropEffects > 0 then
			local v52_ = streamWriteBool
			local v53_ = v51_.dirtyFlag
			if v52_(streamId, bit32.band(dirtyMask, v53_) ~= 0) then
				for _, v54_ in ipairs(v51_.dropEffects) do
					streamWriteUIntN(streamId, v54_.fillType or FillType.UNKNOWN, FillTypeManager.SEND_NUM_BITS)
					streamWriteBool(streamId, v54_.isActiveSent)
				end
			end
		else
			streamWriteBool(streamId, v51_.isCutting)
		end
		local v55_ = streamWriteBool
		local v56_ = v51_.effectDirtyFlag
		if v55_(streamId, bit32.band(dirtyMask, v56_) ~= 0) and streamWriteBool(streamId, v51_.effectsAreRunning) then
			streamWriteUIntN(streamId, v51_.lastFruitGrowthState, 4)
			streamWriteUIntN(streamId, v51_.lastFruitTypeIndex, FruitTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX, reset, t, inputFruitType, inputGrowthState, isActive
function Mower:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v58_ = self.spec_mower
	if self:getIsTurnedOn() and self:getLastSpeed() > 0.5 then
		local v59_, v60_, v61_, v62_ = self:getTestAreaWidthByWorkAreaIndex(1)
		local v63_
		if v59_ == -math.huge and v60_ == math.huge then
			v59_ = 0
			v60_ = 0
			v63_ = true
		else
			v63_ = false
		end
		local v64_
		if self.movingDirection > 0 then
			v64_ = v59_ * -1
			v59_ = v60_ * -1
			if v59_ >= v64_ then
				local v65_ = v64_
				v64_ = v59_
				v59_ = v65_
			end
		else
			v64_ = v60_
		end
		local v66_, v67_, v68_
		if self.isServer then
			v66_ = FruitType.UNKNOWN
			if g_time - v58_.workAreaParameters.lastCutTime < 500 then
				v66_ = v58_.workAreaParameters.lastInputFruitType
				v67_ = v58_.workAreaParameters.lastInputGrowthState
			else
				v67_ = 3
			end
			v68_ = not v63_
			if v68_ then
				if v66_ == nil then
					v68_ = false
				else
					v68_ = v66_ ~= FruitType.UNKNOWN
				end
			end
			if v68_ then
				if not v58_.effectsAreRunning then
					v58_.effectsAreRunning = true
					self:raiseDirtyFlags(v58_.effectDirtyFlag)
				end
			elseif v58_.effectsAreRunning then
				g_effectManager:stopEffects(v58_.cutterEffects)
				v58_.effectsAreRunning = false
				self:raiseDirtyFlags(v58_.effectDirtyFlag)
			end
			if v66_ ~= v58_.lastFruitTypeIndex then
				v58_.lastFruitTypeIndex = v66_
				self:updateFruitExtraObjects()
			end
			v58_.lastFruitGrowthState = v67_
		else
			v66_ = v58_.lastFruitTypeIndex
			v67_ = v58_.lastFruitGrowthState
			v68_ = v58_.effectsAreRunning
			if v68_ then
				v68_ = v58_.lastFruitTypeIndex ~= FruitType.UNKNOWN
			end
		end
		if v68_ then
			g_effectManager:setEffectTypeInfo(v58_.cutterEffects, nil, v66_, v67_)
			g_effectManager:setMinMaxWidth(v58_.cutterEffects, v59_, v64_, v59_ / v61_, v64_ / v62_, v63_)
			g_effectManager:startEffects(v58_.cutterEffects)
			return
		end
	elseif v58_.effectsAreRunning then
		g_effectManager:stopEffects(v58_.cutterEffects)
		v58_.effectsAreRunning = false
		self:raiseDirtyFlags(v58_.effectDirtyFlag)
	end
end

-- Local values: spec, xs, _, zs, xw, _, zw, xh, _, zh, workAreaChanged, workAreaTotal, limitToField, inputFruitType, converterData, changedArea, totalArea, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPerc, growthState, _, multiplier, litersToDrop, dropArea, lsx, lsy, lsz, lex, ley, lez, radius, pickup
function Mower:processMowerArea(workArea, dt)
	local v71_ = self.spec_mower
	if not self.isServer and self.currentUpdateDistance > Mower.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v72_, _, v73_ = getWorldTranslation(workArea.start)
	local v74_, _, v75_ = getWorldTranslation(workArea.width)
	local v76_, _, v77_ = getWorldTranslation(workArea.height)
	if self:getLastSpeed() > 1 then
		v71_.isWorking = true
		v71_.stoneLastState = FSDensityMapUtil.getStoneArea(v72_, v73_, v74_, v75_, v76_, v77_)
	else
		v71_.stoneLastState = 0
	end
	local v78_ = self:getIsAIActive()
	local v79_ = 0
	local v80_ = 0
	for v81_, v82_ in pairs(v71_.fruitTypeConverters) do
		local v83_, v84_, v85_, v86_, v87_, v88_, v89_, v90_, v91_, v92_, _ = FSDensityMapUtil.updateMowerArea(v81_, v72_, v73_, v74_, v75_, v76_, v77_, v78_)
		if v83_ > 0 then
			local v93_ = g_currentMission:getHarvestScaleMultiplier(v81_, v85_, v86_, v87_, v88_, v89_, v90_, v91_)
			local v94_ = g_fruitTypeManager:getFruitTypeAreaLiters(v81_, v83_, true) * v93_ * v82_.conversionFactor
			workArea.lastPickupLiters = v94_
			workArea.pickedUpLiters = v94_
			local v95_ = self:getDropArea(workArea)
			if v95_ == nil then
				if v71_.fillUnitIndex ~= nil and self.isServer then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v71_.fillUnitIndex, v94_, v82_.fillTypeIndex, ToolType.UNDEFINED)
				end
			else
				v95_.litersToDrop = v95_.litersToDrop + v94_
				v95_.fillType = v82_.fillTypeIndex
				v95_.workAreaIndex = workArea.index
				if v95_.fillType == FillType.GRASS_WINDROW then
					local v96_, v97_, v98_, v99_, v100_, v101_, v102_ = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height, true)
					local v103_, v104_ = DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, FillType.DRYGRASS_WINDROW, v96_, v97_, v98_, v99_, v100_, v101_, v102_, nil, workArea.lineOffset or 0, false, nil, false)
					workArea.lineOffset = v104_
					v95_.litersToDrop = v95_.litersToDrop - v103_
				end
				local v105_ = v95_.litersToDrop
				v95_.litersToDrop = math.min(v105_, 1000)
			end
			v71_.workAreaParameters.lastInputFruitType = v81_
			v71_.workAreaParameters.lastInputGrowthState = v92_
			v71_.workAreaParameters.lastCutTime = g_time
			v71_.workAreaParameters.lastChangedArea = v71_.workAreaParameters.lastChangedArea + v83_
			v71_.workAreaParameters.lastStatsArea = v71_.workAreaParameters.lastStatsArea + v84_
			v71_.workAreaParameters.lastTotalArea = v71_.workAreaParameters.lastTotalArea + v84_
			v71_.workAreaParameters.lastUsedAreas = v71_.workAreaParameters.lastUsedAreas + 1
			v79_ = v79_ + v83_
			self:setTestAreaRequirements(v81_)
			v80_ = v84_
		end
	end
	v71_.workAreaParameters.lastUsedAreasSum = v71_.workAreaParameters.lastUsedAreasSum + 1
	return v79_, v80_
end

-- Local values: dropped, lineOffset, xs, _, zs, xw, _, zw, xh, _, zh, f, sx, sz, sy, ex, ez, ey
function Mower:processDropArea(dropArea, dt)
	if self.isServer or self.currentUpdateDistance <= Mower.CLIENT_DM_UPDATE_RADIUS then
		if dropArea.litersToDrop > g_densityMapHeightManager:getMinValidLiterValue(dropArea.fillType) then
			local v108_, _, v109_ = getWorldTranslation(dropArea.start)
			local v110_, _, v111_ = getWorldTranslation(dropArea.width)
			local v112_, _, v113_ = getWorldTranslation(dropArea.height)
			local v114_ = math.random()
			local v115_ = v108_ + v114_ * (v112_ - v108_)
			local v116_ = v109_ + v114_ * (v113_ - v109_)
			local v117_ = getTerrainHeightAtWorldPos(g_terrainNode, v115_, 0, v116_)
			local v118_ = math.random()
			local v119_ = v110_ + v118_ * (v112_ - v108_)
			local v120_ = v111_ + v118_ * (v113_ - v109_)
			local v121_ = getTerrainHeightAtWorldPos(g_terrainNode, v119_, 0, v120_)
			local v122_, v123_ = DensityMapHeightUtil.tipToGroundAroundLine(self, dropArea.litersToDrop, dropArea.fillType, v115_, v117_, v116_, v119_, v121_, v120_, 0, nil, dropArea.dropLineOffset, false, nil, false)
			dropArea.litersToDrop = dropArea.litersToDrop - v122_
			dropArea.dropLineOffset = v123_
			if v122_ ~= 0 then
				self.spec_mower.lastDropTime = g_time
			end
		end
	end
end

-- Local values: dropArea
function Mower:getDropArea(workArea)
	if not workArea.dropWindrow then
		return nil
	end
	local v126_
	if workArea.dropAreaIndex == nil then
		v126_ = nil
	else
		v126_ = self.spec_workArea.workAreas[workArea.dropAreaIndex]
		if v126_ == nil then
			local v127_ = printWarning
			local v128_ = workArea.dropAreaIndex
			local v129_ = tostring(v128_)
			local v130_ = self.configFileName
			v127_("Warning: Invalid dropAreaIndex \'" .. v129_ .. "\' in \'" .. tostring(v130_) .. "\'!")
			workArea.dropAreaIndex = nil
		end
		if v126_.type ~= WorkAreaType.AUXILIARY then
			Logging.xmlWarning(self.xmlFile, "Invalid dropAreaIndex \'%s\'. Drop area type needs to be \'AUXILIARY\'!", workArea.dropAreaIndex)
			workArea.dropAreaIndex = nil
			v126_ = nil
		end
	end
	return v126_
end

function Mower:setDropEffectEnabled(dropEffect, isActive)
	dropEffect.isActive = isActive
	if self.isClient then
		if isActive then
			g_effectManager:setEffectTypeInfo(dropEffect.effects, dropEffect.fillType)
			g_effectManager:startEffects(dropEffect.effects)
			return
		end
		g_effectManager:stopEffects(dropEffect.effects)
	end
end

-- Local values: spec, i, i
function Mower:setCutSoundEnabled(isActive)
	if self.isClient then
		local v136_ = self.spec_mower
		if isActive then
			for v137_ = 1, #v136_.samples.cut do
				if not g_soundManager:getIsSamplePlaying(v136_.samples.cut[v137_]) then
					g_soundManager:playSample(v136_.samples.cut[v137_])
				end
			end
			return
		end
		for v138_ = 1, #v136_.samples.cut do
			if g_soundManager:getIsSamplePlaying(v136_.samples.cut[v138_]) then
				g_soundManager:stopSample(v136_.samples.cut[v138_])
			end
		end
	end
end

-- Local values: spec, speed
function Mower:setUseMowerWindrowDropAreas(useMowerWindrowDropAreas, noEventSend)
	local v142_ = self.spec_mower
	if useMowerWindrowDropAreas ~= v142_.useWindrowDropAreas then
		MowerToggleWindrowDropEvent.sendEvent(self, useMowerWindrowDropAreas, noEventSend)
		v142_.useWindrowDropAreas = useMowerWindrowDropAreas
		if v142_.toggleWindrowDropAnimation ~= nil and self.playAnimation ~= nil then
			local v143_ = v142_.enableWindrowDropAnimationSpeed
			if not useMowerWindrowDropAreas then
				v143_ = v142_.disableWindrowDropAnimationSpeed
			end
			self:playAnimation(v142_.toggleWindrowDropAnimation, v143_, nil, true)
		end
	end
end

-- Local values: retValue
function Mower:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v149_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.MOWER
	end
	if workArea.type == WorkAreaType.MOWER then
		workArea.dropWindrow = xmlFile:getValue(key .. ".mower#dropWindrow", true)
		workArea.dropAreaIndex = xmlFile:getValue(key .. ".mower#dropAreaIndex", 1)
		workArea.lastPickupLiters = 0
		workArea.pickedUpLiters = 0
	end
	if workArea.type == WorkAreaType.AUXILIARY then
		workArea.litersToDrop = 0
		if self.spec_mower.dropAreas == nil then
			self.spec_mower.dropAreas = {}
		end
		local v150_ = self.spec_mower.dropAreas
		table.insert(v150_, workArea)
	end
	return v149_
end

-- Local values: spec, _, actionEventId
function Mower:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v153_ = self.spec_mower
		self:clearActionEventsTable(v153_.actionEvents)
		if isActiveForInputIgnoreSelection and (v153_.toggleWindrowDropEnableText ~= nil and v153_.toggleWindrowDropDisableText ~= nil) then
			local _, v154_ = self:addActionEvent(v153_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Mower.actionEventToggleDrop, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v154_, GS_PRIO_LOW)
			Mower.updateActionEventToggleDrop(self)
		end
	end
end

function Mower:doCheckSpeedLimit(superFunc)
	local v157_ = not superFunc(self) and self:getIsTurnedOn()
	if v157_ then
		v157_ = self.getIsLowered == nil and true or self:getIsLowered()
	end
	return v157_
end

function Mower:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec, multiplier
function Mower:getDirtMultiplier(superFunc)
	local v160_ = self.spec_mower
	local v161_ = superFunc(self)
	if v160_.isWorking then
		v161_ = v161_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v161_
end

-- Local values: spec, multiplier, stoneMultiplier
function Mower:getWearMultiplier(superFunc)
	local v164_ = self.spec_mower
	local v165_ = superFunc(self)
	if v164_.isWorking then
		local v166_ = (v164_.stoneLastState == 0 or v164_.stoneWearMultiplierData == nil) and 1 or (v164_.stoneWearMultiplierData[v164_.stoneLastState] or 1)
		v165_ = v165_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * v166_
	end
	return v165_
end

function Mower:getFruitExtraObjectTypeData(superFunc)
	return self.spec_mower.lastFruitTypeIndex, nil
end

-- Local values: spec
function Mower:onTurnedOn()
	if self.isClient then
		local v169_ = self.spec_mower
		g_animationManager:startAnimations(v169_.animationNodes)
	end
end

-- Local values: spec, _, dropEffect
function Mower:onTurnedOff()
	local v171_ = self.spec_mower
	if self.isClient then
		for _, v172_ in pairs(v171_.dropEffects) do
			self:setDropEffectEnabled(v172_, false)
		end
		g_animationManager:stopAnimations(v171_.animationNodes)
	end
	g_effectManager:stopEffects(v171_.cutterEffects)
	v171_.effectsAreRunning = false
end

-- Local values: spec, _, dropEffect, workAreas, i, workArea
function Mower:onStartWorkAreaProcessing(dt)
	local v174_ = self.spec_mower
	if self.isServer then
		for _, v175_ in pairs(v174_.dropEffects) do
			if v175_.isActive ~= v175_.isActiveSent then
				v175_.isActiveSent = v175_.isActive
				self:setDropEffectEnabled(v175_, v175_.isActiveSent)
				self:raiseDirtyFlags(v174_.dirtyFlag)
			end
			v175_.isActive = false
		end
	end
	local v176_ = self:getTypedWorkAreas(WorkAreaType.MOWER)
	for v177_ = 1, #v176_ do
		v176_[v177_].pickedUpLiters = 0
	end
	v174_.workAreaParameters.lastChangedArea = 0
	v174_.workAreaParameters.lastStatsArea = 0
	v174_.workAreaParameters.lastTotalArea = 0
	v174_.isWorking = false
end

-- Local values: spec, _, dropArea, i, workArea, j, dropEffect, dropArea, lastStatsArea, ha, isCutting
function Mower:onEndWorkAreaProcessing(dt, hasProcessed)
	local v180_ = self.spec_mower
	for _, v181_ in ipairs(v180_.dropAreas) do
		self:processDropArea(v181_, dt)
	end
	for v182_ = 1, #v180_.workAreas do
		local v183_ = v180_.workAreas[v182_]
		for v184_ = 1, #v183_.dropEffects do
			local v185_ = v183_.dropEffects[v184_]
			local v186_ = self:getDropArea(v183_)
			if v186_ ~= nil and v185_.dropAreaIndex == v186_.index then
				if v183_.pickedUpLiters > 0 then
					if v185_.fillType ~= v186_.fillType then
						v185_.fillType = v186_.fillType
						g_effectManager:setEffectTypeInfo(v185_.effects, v185_.fillType)
					end
					v185_.activeTime = v185_.activeTimeDuration
					v185_.isActive = true
				else
					local v187_ = v185_.activeTime - dt
					v185_.activeTime = math.max(v187_, 0)
					if v185_.activeTime > 0 then
						v185_.isActive = true
					end
				end
			end
		end
	end
	if self.isServer then
		local v188_ = v180_.workAreaParameters.lastStatsArea
		if v188_ > 0 then
			local v189_ = MathUtil.areaToHa(v188_, g_currentMission:getFruitPixelsToSqm())
			g_farmManager:updateFarmStats(self:getLastTouchedFarmlandFarmId(), "threshedHectares", v189_)
			self:updateLastWorkedArea(v188_)
		end
		local v190_ = g_time - v180_.lastDropTime < 500
		if v180_.isCutting ~= v190_ then
			v180_.isCutting = v190_
			self:raiseDirtyFlags(v180_.dirtyFlag)
			self:setCutSoundEnabled(v180_.isCutting)
		end
	end
	v180_.workAreaParameters.lastUsedAreasTime = v180_.workAreaParameters.lastUsedAreasTime + dt
	if v180_.workAreaParameters.lastUsedAreasTime > 500 then
		local v191_ = v180_.workAreaParameters
		local v192_ = v180_.workAreaParameters.lastUsedAreas
		local v193_ = v180_.workAreaParameters.lastUsedAreasSum
		v191_.lastUsedAreasPct = v192_ / math.max(v193_, 0.01)
		v180_.workAreaParameters.lastUsedAreas = 0
		v180_.workAreaParameters.lastUsedAreasSum = 0
		v180_.workAreaParameters.lastUsedAreasTime = 0
	end
end

function Mower:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	fieldCourseSettings.headlandsFirst = true
	fieldCourseSettings.workInitialSegment = true
	fieldCourseSettings.cornerCutOutSupported = true
end

function Mower:getMowerLoadPercentage()
	return self.spec_mower == nil and 0 or self.spec_mower.workAreaParameters.lastUsedAreasPct
end
g_soundManager:registerModifierType("MOWER_LOAD", Mower.getMowerLoadPercentage)
function Mower.getDefaultSpeedLimit()
	return 20
end

-- Local values: spec
function Mower:actionEventToggleDrop(actionName, inputValue, callbackState, isAnalog)
	self:setUseMowerWindrowDropAreas(not self.spec_mower.useWindrowDropAreas)
end

-- Local values: spec, actionEvent, text
function Mower:updateActionEventToggleDrop()
	local v198_ = self.spec_mower
	local v199_ = v198_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
	if v199_ ~= nil then
		local v200_ = string.format(v198_.toggleWindrowDropDisableText, self.typeDesc)
		if not v198_.useWindrowDropAreas then
			v200_ = string.format(v198_.toggleWindrowDropEnableText, self.typeDesc)
		end
		g_inputBinding:setActionEventText(v199_.actionEventId, v200_)
	end
end
