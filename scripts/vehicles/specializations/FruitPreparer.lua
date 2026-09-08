FruitPreparer = {}
FruitPreparer.CLIENT_DM_UPDATE_RADIUS = 50
function FruitPreparer.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("fruitPreparer", false, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("FruitPreparer")
	v1_:register(XMLValueType.STRING, "vehicle.fruitPreparer#fruitType", "Fruit type")
	v1_:register(XMLValueType.STRING_LIST, "vehicle.fruitPreparer#fruitTypes", "List of preparing fruit types separated by whitespace")
	v1_:register(XMLValueType.BOOL, "vehicle.fruitPreparer#aiUsePreparedState", "AI uses prepared state instead of unprepared state", "true if vehicle has also the Cutter specialization")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".fruitPreparer#dropWorkAreaIndex", "Drop area index")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".fruitPreparer#dropWorkAreaIndex", "Drop area index")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.fruitPreparer.animationNodes")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.fruitPreparer.sounds", "work")
	v1_:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#moveOnlyIfPreparerCut", "Move only if fruit preparer cuts something", false)
	v1_:setXMLSpecializationType()
end

function FruitPreparer.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
	return v3_
end

function FruitPreparer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processFruitPreparerArea", FruitPreparer.processFruitPreparerArea)
end

function FruitPreparer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", FruitPreparer.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", FruitPreparer.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", FruitPreparer.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowCutterAIFruitRequirements", FruitPreparer.getAllowCutterAIFruitRequirements)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", FruitPreparer.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", FruitPreparer.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadRandomlyMovingPartFromXML", FruitPreparer.loadRandomlyMovingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsRandomlyMovingPartActive", FruitPreparer.getIsRandomlyMovingPartActive)
end

function FruitPreparer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", FruitPreparer)
end

-- Local values: spec, fruitTypes, fruitType, _, fruitType, desc, aiUsePreparedState, minState
function FruitPreparer:onLoad(savegame)
	local v8_ = self.spec_fruitPreparer
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnAnimation#name", "vehicle.turnOnVehicle.turnedAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnAnimation#speed", "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fruitPreparer#useReelStateToTurnOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fruitPreparer#onlyActiveWhenLowered")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.vehicle.fruitPreparerSound", "vehicle.fruitPreparer.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.fruitPreparer.animationNodes.animationNode", "fruitPreparer")
	if self.isClient then
		v8_.samples = {}
		v8_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fruitPreparer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.fruitPreparer.animationNodes", self.components, self, self.i3dMappings)
	end
	v8_.fruitTypes = {}
	local v9_ = self.xmlFile:getValue("vehicle.fruitPreparer#fruitTypes", {}, true)
	local v10_ = self.xmlFile:getValue("vehicle.fruitPreparer#fruitType")
	if v10_ ~= nil then
		table.insert(v9_, v10_)
	end
	if #v9_ > 0 then
		for _, v11_ in ipairs(v9_) do
			local v12_ = g_fruitTypeManager:getFruitTypeByName(v11_)
			if v12_ == nil then
				Logging.xmlWarning(self.xmlFile, "Unable to find fruitType \'%s\' in fruitPreparer", v11_)
			else
				local v13_ = v8_.fruitTypes
				local v14_ = v12_.index
				table.insert(v13_, v14_)
				if self.setAIFruitRequirements ~= nil then
					if v12_.minPreparingGrowthState == -1 then
						local v15_ = v8_.allowsForageGrowthState and v12_.minForageGrowthState or v12_.minHarvestingGrowthState
						self:addAIFruitRequirement(v12_.index, v15_, v12_.maxHarvestingGrowthState)
					else
						self:setAIFruitRequirements(v12_.index, v12_.minPreparingGrowthState, v12_.maxPreparingGrowthState)
						if self.xmlFile:getValue("vehicle.fruitPreparer#aiUsePreparedState", self.spec_cutter ~= nil) then
							self:addAIFruitRequirement(v12_.index, v12_.preparedGrowthState, v12_.preparedGrowthState)
						end
					end
				end
			end
		end
	else
		Logging.xmlWarning(self.xmlFile, "Missing fruitType in fruitPreparer")
	end
	v8_.isWorking = false
	v8_.lastWorkTime = -math.huge
	v8_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec
function FruitPreparer:onDelete()
	local v17_ = self.spec_fruitPreparer
	g_soundManager:deleteSamples(v17_.samples)
	g_animationManager:deleteAnimations(v17_.animationNodes)
end

-- Local values: spec
function FruitPreparer:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		self.spec_fruitPreparer.isWorking = streamReadBool(streamId)
	end
end

-- Local values: spec
function FruitPreparer:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v24_ = self.spec_fruitPreparer
		streamWriteBool(streamId, v24_.isWorking)
	end
end

-- Local values: spec
function FruitPreparer:onTurnedOn()
	if self.isClient then
		local v26_ = self.spec_fruitPreparer
		g_soundManager:playSample(v26_.samples.work)
		g_animationManager:startAnimations(v26_.animationNodes)
	end
end

-- Local values: spec
function FruitPreparer:onTurnedOff()
	if self.isClient then
		local v28_ = self.spec_fruitPreparer
		g_soundManager:stopSamples(v28_.samples)
		g_animationManager:stopAnimations(v28_.animationNodes)
	end
end

-- Local values: retValue
function FruitPreparer:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v34_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.FRUITPREPARER then
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#dropStartIndex", key .. ".fruitPreparer#dropWorkAreaIndex")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#dropWidthIndex", key .. ".fruitPreparer#dropWorkAreaIndex")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#dropHeightIndex", key .. ".fruitPreparer#dropWorkAreaIndex")
		workArea.dropWorkAreaIndex = xmlFile:getValue(key .. ".fruitPreparer#dropWorkAreaIndex")
	end
	return v34_
end

-- Local values: spec
function FruitPreparer:getDoGroundManipulation(superFunc)
	local v37_ = self.spec_fruitPreparer
	local v38_ = superFunc(self)
	if v38_ then
		v38_ = v37_.isWorking
	end
	return v38_
end

function FruitPreparer:doCheckSpeedLimit(superFunc)
	local v41_ = not superFunc(self) and self:getIsTurnedOn()
	if v41_ then
		v41_ = self.getIsImplementChainLowered == nil and true or self:getIsImplementChainLowered()
	end
	return v41_
end

function FruitPreparer:getAllowCutterAIFruitRequirements(superFunc)
	return false
end

-- Local values: spec
function FruitPreparer:getDirtMultiplier(superFunc)
	if self.spec_fruitPreparer.isWorking then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	else
		return superFunc(self)
	end
end

-- Local values: spec
function FruitPreparer:getWearMultiplier(superFunc)
	if self.spec_fruitPreparer.isWorking then
		return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	else
		return superFunc(self)
	end
end

-- Local values: retValue
function FruitPreparer:loadRandomlyMovingPartFromXML(superFunc, part, xmlFile, key)
	local v51_ = superFunc(self, part, xmlFile, key)
	part.moveOnlyIfPreparerCut = xmlFile:getValue(key .. "#moveOnlyIfPreparerCut", false)
	return v51_
end

-- Local values: retValue
function FruitPreparer:getIsRandomlyMovingPartActive(superFunc, part)
	local v55_ = superFunc(self, part)
	if part.moveOnlyIfPreparerCut then
		if v55_ then
			v55_ = self.spec_fruitPreparer.isWorking
		end
	end
	return v55_
end
function FruitPreparer.getDefaultSpeedLimit()
	return 15
end

-- Local values: spec, isWorking
function FruitPreparer:onEndWorkAreaProcessing(dt)
	if self.isServer then
		local v57_ = self.spec_fruitPreparer
		local v58_ = g_time - v57_.lastWorkTime < 500
		if v58_ ~= v57_.isWorking then
			self:raiseDirtyFlags(v57_.dirtyFlag)
			v57_.isWorking = v58_
		end
	end
end

function FruitPreparer:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	fieldCourseSettings.headlandsFirst = true
	fieldCourseSettings.workInitialSegment = true
end

-- Local values: spec, workAreaSpec, xs, _, zs, xw, _, zw, xh, _, zh, dxs, dzs, dxw, dzw, dxh, dzh, limitToFruit, dropArea, workedArea, _, fruitType, area
function FruitPreparer:processFruitPreparerArea(workArea)
	local v62_ = self.spec_fruitPreparer
	local v63_ = self.spec_workArea
	if not self.isServer and self.currentUpdateDistance > FruitPreparer.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v64_, _, v65_ = getWorldTranslation(workArea.start)
	local v66_, _, v67_ = getWorldTranslation(workArea.width)
	local v68_, _, v69_ = getWorldTranslation(workArea.height)
	local v70_ = true
	local v71_, v72_, v73_, v74_, v75_, v76_
	if workArea.dropWorkAreaIndex == nil then
		v71_ = v66_
		v72_ = v65_
		v73_ = v64_
		v74_ = v69_
		v75_ = v68_
		v76_ = v67_
	else
		local v77_ = v63_.workAreas[workArea.dropWorkAreaIndex]
		if v77_ == nil then
			v71_ = v66_
			v72_ = v65_
			v73_ = v64_
			v74_ = v69_
			v75_ = v68_
			v76_ = v67_
		else
			local v78_
			v73_, v78_, v72_ = getWorldTranslation(v77_.start)
			local v79_
			v71_, v79_, v76_ = getWorldTranslation(v77_.width)
			local v80_
			v75_, v80_, v74_ = getWorldTranslation(v77_.height)
			v70_ = false
		end
	end
	local v81_ = 0
	for _, v82_ in ipairs(v62_.fruitTypes) do
		local v83_ = FSDensityMapUtil.updateFruitPreparerArea(v82_, v64_, v65_, v66_, v67_, v68_, v69_, v73_, v72_, v71_, v76_, v75_, v74_, v70_)
		if v83_ > 0 then
			v62_.lastWorkTime = g_time
			v81_ = v83_
		end
	end
	return 0, v81_
end
