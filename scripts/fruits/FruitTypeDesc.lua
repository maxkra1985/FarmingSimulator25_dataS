-- Local values: FruitTypeDesc_mt
FruitTypeDesc = {}
local FruitTypeDesc_mt = Class(FruitTypeDesc)
g_xmlManager:addCreateSchemaFunction(function()
	FruitTypeDesc.xmlSchema = XMLSchema.new("foliageType")
	local v2_ = FruitTypeDesc.xmlSchema
	v2_.supportsParentFile = false
	v2_:register(XMLValueType.STRING, "foliageType.fruitType#name")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType#shownOnMap")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType#useForFieldMissions")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType#isCatchCrop")
	v2_:register(XMLValueType.VECTOR_4, "foliageType.fruitType.mapColors#default")
	v2_:register(XMLValueType.VECTOR_4, "foliageType.fruitType.mapColors#colorBlind")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.windrow#fillType")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.windrow#cutFillType")
	v2_:register(XMLValueType.FLOAT, "foliageType.fruitType.windrow#windrowCutFactor", "Additional yield factor while threshing the windrows", 1)
	v2_:register(XMLValueType.FLOAT, "foliageType.fruitType.windrow#litersPerSqm")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.harvest#chopperType")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.harvest#chopperUseHaulm", "true if chopper should use haulm layer instead of chopper spray type")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.harvest#groundType")
	v2_:register(XMLValueType.FLOAT, "foliageType.fruitType.harvest#litersPerSqm")
	v2_:register(XMLValueType.FLOAT, "foliageType.fruitType.harvest#cutHeight")
	v2_:register(XMLValueType.FLOAT, "foliageType.fruitType.harvest#forageCutHeight")
	v2_:register(XMLValueType.FLOAT, "foliageType.fruitType.harvest#beeYieldBonusPercentage")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.harvest.transition(?)#src")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.harvest.transition(?)#target")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.growth#resetsSpray")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.growth#growthRequiresLime")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.soil#lowDensityRequired")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.soil#increasesDensity")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.soil#consumesLime")
	v2_:register(XMLValueType.INT, "foliageType.fruitType.soil#startSprayLevel")
	v2_:register(XMLValueType.INT, "foliageType.fruitType.seeding#directionSnapAngle")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.seeding#needsRolling")
	v2_:register(XMLValueType.FLOAT, "foliageType.fruitType.seeding#litersPerSqm")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.seeding#isAvailable")
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.seeding#plantsWeed")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.seeding#defaultSowingGroundType")
	FieldType.registerXMLPath(v2_, "foliageType.fruitType.seeding#requiredFieldType", "Name of the field type", nil, false)
	v2_:register(XMLValueType.BOOL, "foliageType.fruitType.cultivation#isAllowed")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.mulcher#chopperType")
	v2_:register(XMLValueType.STRING, "foliageType.fruitType.haulm#layerName")
	v2_:register(XMLValueType.STRING, "foliageType.foliageLayer(?)#name")
	v2_:register(XMLValueType.STRING, "foliageType.foliageLayer(?)#distanceTexturePath", "optional path for distance textures")
	v2_:register(XMLValueType.INT, "foliageType.foliageLayer(?)#densityMapChannelOffset")
	v2_:register(XMLValueType.INT, "foliageType.foliageLayer(?)#numDensityMapChannels")
	v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)#numBlocksPerUnit", "default number of blocks per unit (rounded)")
	v2_:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)#plantOffset", "default X/Z offset for plant layout, in meters")
	v2_:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)#plantSeparation", "default X/Z separation for plant layout, in meters (not rounded) - overrides numBlocksPerUnit")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)#plantLayoutRotation", "allows the plant layout to rotate with the field - requires plantSeparation to be used instead of numBlocksPerUnit")
	v2_:register(XMLValueType.STRING, "foliageType.foliageLayer(?)#shapeSource")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)#debugMesh")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)#alignsToSun")
	for _, v3_ in ipairs({ "foliageStateDefaults", "foliageState(?)" }) do
		v2_:register(XMLValueType.INT, "foliageType.foliageLayer(?)." .. v3_ .. "#distanceMapLayer")
		v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. v3_ .. "#width")
		v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. v3_ .. "#height")
		v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. v3_ .. "#widthVariance")
		v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. v3_ .. "#heightVariance")
		v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. v3_ .. "#horizontalPositionVariance")
		v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)." .. v3_ .. "#debugMesh")
		v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. v3_ .. "#numBlocksPerUnit", "number of blocks per unit (rounded)")
		v2_:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)." .. v3_ .. "#plantOffset", "X/Z offset for plant layout, in meters")
		v2_:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)." .. v3_ .. "#plantSeparation", "X/Z separation for plant layout, in meters (not rounded) - overrides numBlocksPerUnit")
		v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)." .. v3_ .. "#plantLayoutRotation", "allows the plant layout to rotate with the field - requires plantSeparation to be used instead of numBlocksPerUnit")
	end
	v2_:register(XMLValueType.INT, "foliageType.foliageLayer(?).foliageLodDefaults(?)#lod")
	for _, v4_ in ipairs({ "foliageLodDefaults", "foliageState(?).foliageShape(?).foliageLod(?)" }) do
		v2_:register(XMLValueType.INT, "foliageType.foliageLayer(?)." .. v4_ .. "#viewDistance")
		v2_:register(XMLValueType.INT, "foliageType.foliageLayer(?)." .. v4_ .. "#blendOutDistance")
		v2_:register(XMLValueType.INT, "foliageType.foliageLayer(?)." .. v4_ .. "#atlasSize")
		v2_:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)." .. v4_ .. "#atlasOffset")
		v2_:register(XMLValueType.VECTOR_4, "foliageType.foliageLayer(?)." .. v4_ .. "#texCoords")
		v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)." .. v4_ .. "#debugMesh")
	end
	v2_:register(XMLValueType.STRING, "foliageType.foliageLayer(?).foliageState(?)#name")
	v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?).foliageState(?)#numBlocksPerUnit")
	v2_:register(XMLValueType.STRING, "foliageType.foliageLayer(?).foliageState(?)#distanceMap")
	v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#yieldScale")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isGrowing")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#allowsWeeding")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#allowsHoeing")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isPreparable")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isPrepared")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isHarvestReady")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isForageReady")
	v2_:register(XMLValueType.STRING, "foliageType.foliageLayer.foliageState(?)#groundType")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isCut")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isWithered")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isDestructibleByWheel", "Whether this state can be destructed by wheels, defines a range from first to last state where this is set to true")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isDestructedByWheel", "If wheel destruction occurs for the fruitType change to this state, can only be set for one state")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isDestructibleByDisaster", "Whether this state can be destructed by disaster, defines a range from first to last state where this is set to true")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isDestructedByDisaster", "If disaster occurs for the fruitType change to this state, can only be set for one state")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#cullCropsBelowFillHeight", "Foliage shape will be culled if tipAny/fillHeight at the pixel is higher than the LOD0", false)
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#regrowthStart")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isMulched")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isRolledCut")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isWeed")
	v2_:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isCultivatable")
	v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#minWaterLitersPerSqm", "Minimum water level in liters per squaremeter required for the state to grow without a yield reduction")
	v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#maxWaterLitersPerSqm", "Maximum water level in liters per squaremeter required for the state to grow without a yield reduction")
	v2_:register(XMLValueType.STRING, "foliageType.foliageLayer.foliageState(?)#penaltyStateName", "Name of the foliage state to change to if water level was incorrect")
	v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#penaltyPercentage", "Percentage of foliage to convert to penalty foliage if water level was incorrect")
	v2_:register(XMLValueType.STRING_LIST, "foliageType.foliageLayer.foliageState(?)#groundTypeMask", "Space separated list of ground type names")
	v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#fieldCourseLineHeight", "Height of the field course lines if this growth state is on the field", 0.15)
	v2_:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?).foliageState(?).foliageShape(?)#probability")
	v2_:register(XMLValueType.NODE_INDEX, "foliageType.foliageLayer(?).foliageState(?).foliageShape(?).foliageLod(?)#blockShape")
	v2_:register(XMLValueType.STRING, "foliageType.growth.seasonal#initialState")
	v2_:register(XMLValueType.STRING, "foliageType.growth.seasonal.period(?)#name")
	v2_:register(XMLValueType.STRING, "foliageType.growth.seasonal.period(?)#plantingAllowed")
	for _, v5_ in ipairs({ "seasonal.period(?)", "nonSeasonal" }) do
		v2_:register(XMLValueType.STRING, "foliageType.growth." .. v5_ .. ".update(?)#startState")
		v2_:register(XMLValueType.STRING, "foliageType.growth." .. v5_ .. ".update(?)#endState")
	end
end)

-- Upvalues: FruitTypeDesc_mt
-- Local values: self
function FruitTypeDesc.new(customMt)
	-- upvalues: (copy) FruitTypeDesc_mt
	local v7_ = customMt or FruitTypeDesc_mt
	local v8_ = setmetatable({}, v7_)
	v8_.index = nil
	v8_.modifier = nil
	v8_.name = nil
	v8_.layerName = nil
	v8_.shownOnMap = false
	v8_.useForFieldMissions = true
	v8_.missionMultiplier = 1
	v8_.growthStateToName = {}
	v8_.nameToGrowthState = {}
	v8_.startStateChannel = 0
	v8_.numStateChannels = 4
	v8_.startStateChannelHaulm = 0
	v8_.numStateChannelsHaulm = 1
	v8_.alignsToSun = false
	v8_.plantSpacing = 1
	v8_.fillType = nil
	v8_.defaultSowingGroundType = nil
	v8_.isCatchCrop = false
	v8_.yieldScales = {}
	v8_.minHarvestingGrowthState = 0
	v8_.maxHarvestingGrowthState = 0
	v8_.minForageGrowthState = 0
	v8_.maxForageGrowthState = 0
	v8_.cutState = 0
	v8_.cutStates = {}
	v8_.witheredState = nil
	v8_.harvestWeedState = -1
	v8_.mulchedState = 0
	v8_.rolledCutState = 0
	v8_.minWheelDestructionState = nil
	v8_.maxWheelDestructionState = nil
	v8_.wheelDestructionState = nil
	v8_.minDisasterDestructionState = nil
	v8_.maxDisasterDestructionState = nil
	v8_.disasterDestructionState = 0
	v8_.minPreparingGrowthState = -1
	v8_.maxPreparingGrowthState = -1
	v8_.preparedGrowthState = -1
	v8_.groundTypeChangeGrowthState = -1
	v8_.groundTypeChangeType = nil
	v8_.groundTypeChangeMaskTypes = {}
	v8_.minWeederState = 0
	v8_.maxWeederState = 0
	v8_.minWeederHoeState = 0
	v8_.maxWeederHoeState = 0
	v8_.regrows = false
	v8_.firstRegrowthState = 1
	return v8_
end

-- Local values: xmlFile, key, foliageKey, name, upperName, fillType, startStateChannelHaulm, numGrowthStates, cultivationStates, hasProhibitedCultivationStates, k, foliageStateKey, foliageStateName, groundTypeName, groundType, groundTypeChangeMaskString, groundTypeChangeMaskList, _, groundTypeMaskName, groundType, minWaterLitersPerSqm, maxWaterLitersPerSqm, penaltyStateName, penaltyPercentage, fieldCourseLineHeight, harvestGroundTypeName, groundType, chopperGroundTypeName, chopperType, requiredFieldType, fieldType, windrowFillTypeName, windrowFillType, windrowCutFillTypeName, windrowCutFillType, mulcherChopperTypeName, mulcherChopperType, transitions, _, transitionKey, srcStateName, targetStateName, srcState, targetState, i, i, harvestReadyTransitions, i
function FruitTypeDesc:loadFromFoliageXMLFile(xmlFilename)
	local v11_ = XMLFile.load("foliageXml", xmlFilename)
	if v11_ == nil then
		return false
	end
	local v12_ = v11_:getString("foliageType.fruitType#name")
	if v12_ == nil then
		Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Missing fruitType name")
		v11_:delete()
		return false
	end
	if not ClassUtil.getIsValidIndexName(v12_) then
		Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: \'%s\' is not a valid name for a fruitType. Ignoring fruitType!", self.name)
		v11_:delete()
		return false
	end
	local v13_ = string.upper(v12_)
	self.xmlFilename = xmlFilename
	self.name = v13_
	self.layerName = v12_
	local v14_ = g_fillTypeManager:getFillTypeByName(v13_)
	if v14_ == nil then
		Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Missing fillType \'%s\' for fruitType definition. Ignoring fruitType!", v12_)
		v11_:delete()
		return false
	end
	self.fillType = v14_
	self.shownOnMap = v11_:getBool("foliageType.fruitType#shownOnMap", true)
	self.useForFieldMissions = v11_:getBool("foliageType.fruitType#useForFieldMissions", true)
	self.missionMultiplier = v11_:getFloat("foliageType.fruitType#missionMultiplier", 1)
	self.isCatchCrop = v11_:getBool("foliageType.fruitType#isCatchCrop")
	self.defaultMapColor = Color.parseFromString(v11_:getString("foliageType.fruitType.mapColors#default", "1 1 1 1"))
	self.colorBlindMapColor = Color.parseFromString(v11_:getString("foliageType.fruitType.mapColors#colorBlind", "1 1 1 1"))
	self.startStateChannel = v11_:getInt("foliageType.foliageLayer(0)#densityMapChannelOffset", 0)
	self.numStateChannels = v11_:getInt("foliageType.foliageLayer(0)#numDensityMapChannels", 4)
	self.alignsToSun = v11_:getBool("foliageType.foliageLayer(0)#alignsToSun", false)
	self.numBlocksPerUnit = v11_:getFloat("foliageType.foliageLayer(0)#numBlocksPerUnit")
	self.plantSeparation = v11_:getVector("foliageType.foliageLayer(0)#plantSeparation", nil, 2)
	self.plantOffset = v11_:getVector("foliageType.foliageLayer(0)#plantOffset", nil, 2)
	self:updatePlantSpacing()
	local v15_ = v11_:getInt("foliageType.foliageLayer(1)#densityMapChannelOffset", nil)
	if v15_ ~= nil then
		self.startStateChannelHaulm = v15_ - self.numStateChannels
		self.numStateChannelsHaulm = v11_:getInt("foliageType.foliageLayer(1)#numDensityMapChannels", 1)
	end
	self.fieldCourseLineHeightByGrowthState = {}
	local v16_ = 0
	local v17_ = {}
	local v18_ = false
	for v19_, v20_ in v11_:iterator("foliageType.foliageLayer(0).foliageState") do
		local v21_ = v11_:getString(v20_ .. "#name")
		self.growthStateToName[v19_] = v21_
		self.nameToGrowthState[string.upper(v21_)] = v19_
		if v11_:getBool(v20_ .. "#isHarvestReady") then
			if self.minHarvestingGrowthState == 0 then
				self.minHarvestingGrowthState = v19_
			end
			self.maxHarvestingGrowthState = v19_
			self.yieldScales[v19_] = v11_:getFloat(v20_ .. "#yieldScale", 1)
		end
		if v11_:getBool(v20_ .. "#isForageReady") then
			if self.minForageGrowthState == 0 then
				self.minForageGrowthState = v19_
			end
			self.maxForageGrowthState = v19_
		end
		if v11_:getBool(v20_ .. "#isCut") then
			self.cutStates[v19_] = true
			self.cutState = v19_
		end
		if v11_:getBool(v20_ .. "#isWithered") then
			if self.witheredState ~= nil then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: WitheredState already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.witheredState], v21_)
			end
			self.witheredState = v19_
		end
		if v11_:getBool(v20_ .. "#isGrowing") then
			v16_ = v16_ + 1
		end
		local v22_ = v11_:getString(v20_ .. "#groundType")
		if v22_ ~= nil then
			local v23_ = FieldGroundType.getByName(v22_)
			if v23_ == nil then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid groundType name \'%s\' for foliage state \'%s\'. Ignoring it!", v22_, v21_)
			else
				if self.groundTypeChangeGrowthState ~= -1 then
					Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: GroundType change already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.groundTypeChangeGrowthState], v21_)
				end
				self.groundTypeChangeGrowthState = v19_
				self.groundTypeChangeType = v23_
			end
		end
		local v24_ = v11_:getString(v20_ .. "#groundTypeMask")
		if v24_ ~= nil then
			local v25_ = v24_:split(" ")
			for _, v26_ in ipairs(v25_) do
				local v27_ = FieldGroundType.getByName(v26_)
				if v27_ == nil then
					Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid groundTypeChangeMask name \'%s\' for foliage state \'%s\'. Ignoring it!", v26_, v21_)
				else
					local v28_ = self.groundTypeChangeMaskTypes
					table.insert(v28_, v27_)
				end
			end
		end
		if v11_:getBool(v20_ .. "#allowsWeeding") then
			if self.minWeederState == 0 then
				self.minWeederState = v19_
			end
			self.maxWeederState = v19_
		end
		if v11_:getBool(v20_ .. "#allowsHoeing") then
			if self.minWeederHoeState == 0 then
				self.minWeederHoeState = v19_
			end
			self.maxWeederHoeState = v19_
		end
		if v11_:getBool(v20_ .. "#regrowthStart") then
			if self.regrows then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: RegrowthStart already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.firstRegrowthState], v21_)
			end
			self.firstRegrowthState = v19_
			self.regrows = true
		end
		if v11_:getBool(v20_ .. "#isDestructibleByWheel") then
			if self.minWheelDestructionState == nil then
				self.minWheelDestructionState = v19_
			end
			self.maxWheelDestructionState = v19_
		end
		if v11_:getBool(v20_ .. "#isDestructedByWheel") then
			if self.wheelDestructionState ~= nil then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Wheel destructed state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.wheelDestructionState], v21_)
			end
			self.wheelDestructionState = v19_
		end
		if v11_:getBool(v20_ .. "#isDestructibleByDisaster") then
			if self.minDisasterDestructionState == nil then
				self.minDisasterDestructionState = v19_
			end
			self.maxDisasterDestructionState = v19_
		end
		if v11_:getBool(v20_ .. "#isDestructedByDisaster") then
			if self.disasterDestructionState ~= 0 then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Disaster destructed state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.disasterDestructionState], v21_)
			end
			self.disasterDestructionState = v19_
		end
		if v11_:getBool(v20_ .. "#isPreparable") then
			if self.minPreparingGrowthState == -1 then
				self.minPreparingGrowthState = v19_
			end
			self.maxPreparingGrowthState = v19_
		end
		if v11_:getBool(v20_ .. "#isPrepared") then
			if self.preparedGrowthState ~= -1 then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Prepared state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.preparedGrowthState], v21_)
			end
			self.preparedGrowthState = v19_
		end
		if v11_:getBool(v20_ .. "#isWeed") then
			if self.harvestWeedState ~= -1 then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Harvested weed state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.harvestWeedState], v21_)
			end
			self.harvestWeedState = v19_
		end
		if v11_:getBool(v20_ .. "#isMulched") then
			if self.mulchedState ~= 0 then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Mulched state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.mulchedState], v21_)
			end
			self.mulchedState = v19_
		end
		if v11_:getBool(v20_ .. "#isRolledCut") then
			if self.rolledCutState ~= 0 then
				Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Rolled cut state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.rolledCutState], v21_)
			end
			self.rolledCutState = v19_
		end
		if v11_:getBool(v20_ .. "#isCultivatable", true) then
			table.insert(v17_, v19_)
		else
			v18_ = true
		end
		local v29_ = v11_:getFloat(v20_ .. "#minWaterLitersPerSqm")
		if v29_ ~= nil then
			self.minWaterLitersPerSqm = self.minWaterLitersPerSqm or {}
			self.minWaterLitersPerSqm[v19_] = v29_
		end
		local v30_ = v11_:getFloat(v20_ .. "#maxWaterLitersPerSqm")
		if v30_ ~= nil then
			self.maxWaterLitersPerSqm = self.maxWaterLitersPerSqm or {}
			self.maxWaterLitersPerSqm[v19_] = v30_
		end
		local v31_ = v11_:getString(v20_ .. "#penaltyStateName")
		if v31_ ~= nil then
			self.penaltyStateName = self.penaltyStateName or {}
			self.penaltyStateName[v19_] = v31_
		end
		local v32_ = v11_:getFloat(v20_ .. "#penaltyPercentage")
		if v32_ ~= nil then
			self.penaltyPercentage = self.penaltyPercentage or {}
			self.penaltyPercentage[v19_] = v32_
		end
		local v33_ = v11_:getFloat(v20_ .. "#fieldCourseLineHeight")
		self.fieldCourseLineHeightByGrowthState[v19_] = v33_
	end
	self.numGrowthStates = v16_
	self.numFoliageStates = #self.growthStateToName
	if v18_ then
		self.cultivationStates = v17_
	end
	if self.maxWheelDestructionState ~= nil and self.wheelDestructionState == nil then
		Logging.xmlWarning(v11_, "Fruit has states where \'isDestructibleByWheel\' is true but does not specify a state where \'isDestructedByWheel\' (state to change to when destruction occurs) is true")
		self.minWheelDestructionState = nil
		self.maxWheelDestructionState = nil
	end
	if self.maxDisasterDestructionState ~= nil and self.disasterDestructionState == nil then
		Logging.xmlWarning(v11_, "Fruit has states where \'isDestructibleByDisaster\' is true but does not specify a state where \'isDestructedByDisaster\' (state to change to when disaster occurs) is true")
		self.minDisasterDestructionState = nil
		self.maxDisasterDestructionState = nil
	end
	self.literPerSqm = v11_:getFloat("foliageType.fruitType.harvest#litersPerSqm", 0)
	self.cutHeight = v11_:getFloat("foliageType.fruitType.harvest#cutHeight", 0.15)
	self.forageCutHeight = v11_:getFloat("foliageType.fruitType.harvest#forageCutHeight", self.forageCutHeight)
	self.beeYieldBonusPercentage = v11_:getFloat("foliageType.fruitType.harvest#beeYieldBonusPercentage", 0)
	local v34_ = v11_:getString("foliageType.fruitType.harvest#groundType")
	if v34_ ~= nil then
		local v35_ = FieldGroundType.getByName(v34_)
		if v35_ == nil then
			Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid harvest ground type name \'%s\'", v34_)
		else
			self.harvestGroundType = v35_
		end
	end
	local v36_ = v11_:getString("foliageType.fruitType.harvest#chopperType")
	if v36_ ~= nil then
		local v37_ = FieldChopperType.getByName(v36_)
		if v37_ == nil then
			Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid chopperType name \'%s\'", v36_)
		else
			self.chopperType = v37_
		end
	end
	self.chopperUseHaulm = v11_:getBool("foliageType.fruitType.harvest#chopperUseHaulm", false)
	self.resetsSpray = v11_:getBool("foliageType.fruitType.growth#resetsSpray", true)
	self.growthRequiresLime = v11_:getBool("foliageType.fruitType.growth#requiresLime", true)
	self.increasesSoilDensity = v11_:getBool("foliageType.fruitType.soil#increasesDensity", false)
	self.lowSoilDensityRequired = v11_:getBool("foliageType.fruitType.soil#lowDensityRequired", true)
	self.consumesLime = v11_:getBool("foliageType.fruitType.soil#consumesLime", true)
	self.startSprayLevel = v11_:getInt("foliageType.fruitType.soil#startSprayLevel", 0)
	self.seedUsagePerSqm = v11_:getFloat("foliageType.fruitType.seeding#litersPerSqm", 0.1)
	self.allowsSeeding = v11_:getBool("foliageType.fruitType.seeding#isAvailable", true)
	self.needsRolling = v11_:getBool("foliageType.fruitType.seeding#needsRolling", true)
	local v38_ = v11_:getFloat("foliageType.fruitType.seeding#directionSnapAngle", 0)
	self.directionSnapAngle = math.rad(v38_)
	self.plantsWeed = v11_:getBool("foliageType.fruitType.seeding#plantsWeed", true)
	self.defaultSowingGroundType = v11_:getString("foliageType.fruitType.seeding#defaultSowingGroundType")
	local v39_ = v11_:getString("foliageType.fruitType.seeding#requiredFieldType", nil)
	local v40_ = FieldType.getByName(v39_)
	if v40_ ~= nil then
		self.seedRequiredFieldType = v40_
	end
	self.isCultivationAllowed = v11_:getBool("foliageType.fruitType.cultivation#isAllowed", true)
	self.limitDestructionToField = v11_:getBool("foliageType.fruitType.destruction#limitToField", true)
	local v41_ = v11_:getString("foliageType.fruitType.windrow#fillType")
	if v41_ ~= nil then
		local v42_ = g_fillTypeManager:getFillTypeByName(v41_)
		if v42_ == nil then
			Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: FruitType windrow fillType \'%s\' not defined for \'%s\'. Ignoring windrow!", v41_, "foliageType.fruitType")
		else
			self.hasWindrow = true
			self.windrowFillType = v42_
			self.windrowName = v42_.name
		end
	end
	local v43_ = v11_:getString("foliageType.fruitType.windrow#cutFillType")
	if v43_ ~= nil then
		local v44_ = g_fillTypeManager:getFillTypeByName(v43_)
		if v44_ == nil then
			Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: FruitType windrow cut fillType \'%s\' not defined for \'%s\'. Ignoring windrow!", v43_, "foliageType.fruitType")
		else
			self.windrowCutFillType = v44_
			self.windrowCutFactor = v11_:getFloat("foliageType.fruitType.windrow#windrowCutFactor", 1)
		end
	end
	self.windrowLiterPerSqm = v11_:getFloat("foliageType.fruitType.windrow#litersPerSqm")
	local v45_ = v11_:getString("foliageType.fruitType.mulcher#chopperType")
	if v45_ ~= nil then
		local v46_ = FieldChopperType.getByName(v45_)
		if v46_ == nil then
			Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid mulcher chopperTypeName name \'%s\'", v45_)
		else
			self.mulcherChopperType = v46_
		end
	end
	self.haulmLayerName = v11_:getString("foliageType.fruitType.haulm#layerName")
	local v47_ = nil
	for _, v48_ in v11_:iterator("foliageType.fruitType.harvest.transition") do
		local v49_ = v11_:getString(v48_ .. "#src")
		local v50_ = v11_:getString(v48_ .. "#target")
		local v51_ = self:getGrowthStateByName(v49_)
		if v51_ == nil then
			Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: foliage state \'%s\' is not defined for harvest transition \'%s\'", v49_, v48_)
			break
		end
		local v52_ = self:getGrowthStateByName(v50_)
		if v52_ == nil then
			Logging.xmlWarning(v11_, "FruitTypeDesc.loadFromFoliageXMLFile: foliage state \'%s\' is not defined for harvest transition \'%s\'", v50_, v48_)
			break
		end
		if v51_ ~= nil and v52_ ~= nil then
			v47_ = v47_ == nil and {} or v47_
			v47_[v51_] = v52_
		end
	end
	if v47_ == nil then
		v47_ = {}
		if self.minForageGrowthState ~= 0 then
			for v53_ = self.minForageGrowthState, self.maxForageGrowthState do
				v47_[v53_] = self.cutState
			end
		end
		if self.minHarvestingGrowthState ~= 0 then
			for v54_ = self.minHarvestingGrowthState, self.maxHarvestingGrowthState do
				v47_[v54_] = self.cutState
			end
		end
	end
	local v55_ = {}
	if self.minHarvestingGrowthState ~= 0 then
		for v56_ = self.minHarvestingGrowthState, self.maxHarvestingGrowthState do
			v55_[v56_] = self.cutState
		end
	end
	self.harvestTransitions = v47_
	self.harvestReadyTransitions = v55_
	self:loadGrowth(v11_, "foliageType.growth")
	v11_:delete()
	return true
end

-- Local values: maxStates, seasonalKey, initialStateName, initialState, growthDataSeasonal, _, periodKey, periodName, period, growthMapping, state, _, updateKey, startStateName, startState, endStateName, endState, periodInfo, period, periodInfo, state, offset, currentPeriod, currentPeriodInfo, mapping, nonSeasonalKey, growthMapping, state, _, updateKey, startStateName, startState, endStateName, endState, growthDataNonSeasonal
function FruitTypeDesc:loadGrowth(xmlFile, key)
	local v60_ = #self.growthStateToName
	if Platform.gameplay.supportSeasonalGrowth then
		local v61_ = key .. ".seasonal"
		local v62_ = xmlFile:getString(v61_ .. "#initialState")
		local v63_
		if v62_ == nil then
			v63_ = nil
		else
			v63_ = self:getGrowthStateByName(v62_)
			if v63_ == nil then
				Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Initial state \'%s\' not defined", v62_)
			end
		end
		local v64_ = {
			["initialState"] = v63_,
			["periods"] = {}
		}
		for _, v65_ in xmlFile:iterator(v61_ .. ".period") do
			local v66_ = xmlFile:getString(v65_ .. "#name")
			local v67_ = SeasonPeriod.getByName(v66_)
			if v67_ == nil then
				Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Period name \'%s\' not defined", v66_)
			end
			local v68_ = {}
			for v69_ = 1, v60_ do
				v68_[v69_] = v69_
			end
			for _, v70_ in xmlFile:iterator(v65_ .. ".update") do
				local v71_ = xmlFile:getString(v70_ .. "#startState")
				local v72_ = self:getGrowthStateByName(v71_)
				if v72_ == nil then
					Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Period \'%s\' update startState \'%s\' not defined", v66_, v71_)
					break
				end
				local v73_ = xmlFile:getString(v70_ .. "#endState")
				local v74_ = self:getGrowthStateByName(v73_)
				if v74_ == nil then
					Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Period \'%s\' update endState \'%s\' not defined", v66_, v73_)
					break
				end
				v68_[v72_] = v74_
			end
			local v75_ = {
				["isHarvestable"] = false,
				["growthMapping"] = v68_,
				["plantingAllowed"] = xmlFile:getBool(v65_ .. "#plantingAllowed", false)
			}
			v64_.periods[v67_] = v75_
		end
		for v76_ = 1, 12 do
			local v77_ = v64_.periods[v76_]
			if v77_ ~= nil and v77_.plantingAllowed then
				local v78_ = 1
				for v79_ = 0, 24 do
					local v80_ = (v76_ + v79_ - 1) % 12 + 1
					local v81_ = v64_.periods[v80_]
					if self:getIsHarvestReady(v78_) or self:getIsPreparable(v78_) then
						v81_.isHarvestable = true
					elseif v78_ == v60_ then
						break
					end
					v78_ = v81_.growthMapping[v78_]
				end
			end
		end
		self.growthDataSeasonal = v64_
	end
	local v82_ = key .. ".nonSeasonal"
	if xmlFile:hasProperty(v82_) then
		local v83_ = {}
		for v84_ = 1, v60_ do
			v83_[v84_] = v84_
		end
		for _, v85_ in xmlFile:iterator(v82_ .. ".update") do
			local v86_ = xmlFile:getString(v85_ .. "#startState")
			local v87_ = self:getGrowthStateByName(v86_)
			if v87_ == nil then
				Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Non-seasonal update startState \'%s\' not defined", v86_)
				break
			end
			local v88_ = xmlFile:getString(v85_ .. "#endState")
			local v89_ = self:getGrowthStateByName(v88_)
			if v89_ == nil then
				Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Non-seasonal update endState \'%s\' not defined", v88_)
				break
			end
			v83_[v87_] = v89_
		end
		self.growthDataNonSeasonal = {
			["growthMapping"] = v83_
		}
	end
end

function FruitTypeDesc:delete() end

function FruitTypeDesc:setTerrainDataPlane(id)
	self.terrainDataPlaneId = id
	self:updatePlantSpacing()
end

function FruitTypeDesc:setTerrainDataPlaneIndex(index)
	self.terrainDataPlaneIndex = index
end

function FruitTypeDesc:setTerrainDataPlaneHaulm(id)
	self.terrainDataPlaneIdHaulm = id
end

function FruitTypeDesc:setTerrainDataPlaneHaulmIndex(index)
	self.terrainDataPlaneHaulmIndex = index
end

function FruitTypeDesc:setFoliageTransformGroup(id)
	self.foliageTransformGroupId = id
end

function FruitTypeDesc:getDataPlaneInfo()
	return self.terrainDataPlaneId, self.startStateChannel, self.numStateChannels
end

-- Local values: cellSize, plantsPerCell
function FruitTypeDesc:updatePlantSpacing()
	if self.plantSeparation == nil then
		if self.numBlocksPerUnit ~= nil then
			local v102_ = self.terrainDataPlaneId == nil and 16 or getFoliageGraphicsCellSize(self.terrainDataPlaneId)
			local v103_ = v102_ * self.numBlocksPerUnit
			local v104_ = math.floor(v103_)
			if v104_ ~= 0 then
				self.plantSpacing = v102_ / v104_
			end
		end
	else
		self.plantSpacing = self.plantSeparation[1]
		return
	end
end

function FruitTypeDesc:getModifier()
	if self.modifier == nil and self.terrainDataPlaneId ~= nil then
		self.modifier = DensityMapModifier.new(self.terrainDataPlaneId, self.startStateChannel, self.numStateChannels, g_terrainNode)
	end
	return self.modifier
end

function FruitTypeDesc:getHaulmModifier()
	if self.haulmModifier == nil and self.terrainDataPlaneIdHaulm ~= nil then
		self.haulmModifier = DensityMapModifier.new(self.terrainDataPlaneIdHaulm, self.startStateChannelHaulm, self.numStateChannelsHaulm, g_terrainNode)
	end
	return self.haulmModifier
end

function FruitTypeDesc:getFilter()
	if self.filter == nil and self.terrainDataPlaneId ~= nil then
		self.filter = DensityMapFilter.new(self.terrainDataPlaneId, self.startStateChannel, self.numStateChannels)
	end
	return self.filter
end

function FruitTypeDesc:getLayerName()
	return self.layerName
end

function FruitTypeDesc:getHaulmLayerName()
	return self.haulmLayerName
end

function FruitTypeDesc:getGrowthStateName(state)
	return self.growthStateToName[state]
end

function FruitTypeDesc:getGrowthStateByName(name)
	local v114_ = self.nameToGrowthState
	if name then
		name = string.upper(name)
	end
	return v114_[name]
end

function FruitTypeDesc:getGrowthStateGroundType(growthState)
	if self.groundTypeChangeGrowthState == -1 or self.groundTypeChangeGrowthState > growthState then
		return nil
	else
		return self.groundTypeChangeType
	end
end

function FruitTypeDesc:getSeasonalGrowthData()
	return self.growthDataSeasonal
end

function FruitTypeDesc:getNonSeasonalGrowthData()
	return self.growthDataNonSeasonal
end

function FruitTypeDesc:getIsCatchCrop()
	return self.isCatchCrop
end

function FruitTypeDesc:getIsHarvestable(growthState)
	return self.harvestTransitions[growthState] ~= nil
end

function FruitTypeDesc:getIsHarvestReady(growthState)
	return self.harvestReadyTransitions[growthState] ~= nil
end

function FruitTypeDesc:getMinHarvestingGrowthState()
	return self.minHarvestingGrowthState
end

-- Local values: periodInfo
function FruitTypeDesc:getIsHarvestableInPeriod(growthMode, seasonPeriod)
	return growthMode ~= GrowthMode.SEASONAL and true or self.growthDataSeasonal.periods[seasonPeriod].isHarvestable
end

-- Local values: periodInfo
function FruitTypeDesc:getIsPlantableInPeriod(growthMode, seasonPeriod)
	return growthMode ~= GrowthMode.SEASONAL and true or self.growthDataSeasonal.periods[seasonPeriod].plantingAllowed
end

function FruitTypeDesc:getIsCut(growthState)
	return self.cutStates[growthState] ~= nil
end

-- Local values: maxGrowingState
function FruitTypeDesc:getIsGrowing(growthState)
	local v135_ = self.minHarvestingGrowthState - 1
	if self.minPreparingGrowthState >= 0 then
		local v136_ = self.minPreparingGrowthState - 1
		v135_ = math.min(v135_, v136_)
	end
	local v137_
	if growthState > 0 then
		v137_ = growthState <= v135_
	else
		v137_ = false
	end
	return v137_
end

function FruitTypeDesc:getIsPreparable(growthState)
	local v140_
	if self.minPreparingGrowthState <= growthState then
		v140_ = growthState <= self.maxPreparingGrowthState
	else
		v140_ = false
	end
	return v140_
end

function FruitTypeDesc:getIsWithered(growthState)
	local v143_
	if self.witheredState == nil then
		v143_ = false
	else
		v143_ = self.witheredState == growthState
	end
	return v143_
end

function FruitTypeDesc:getIsWeedable(growthState)
	local v146_
	if self.minWeederState <= growthState then
		v146_ = growthState <= self.maxWeederState
	else
		v146_ = false
	end
	return v146_
end

function FruitTypeDesc:getIsHoeable(growthState)
	local v149_
	if self.minWeederHoeState <= growthState then
		v149_ = growthState <= self.maxWeederHoeState
	else
		v149_ = false
	end
	return v149_
end

function FruitTypeDesc:getRandomInitialState(growthMode)
	if growthMode == GrowthMode.SEASONAL then
		return self.growthDataSeasonal.initialState
	else
		return math.random(1, self.numGrowthStates)
	end
end

function FruitTypeDesc:getAreaLiters(area, windrow)
	if windrow == true then
		return area * g_currentMission:getFruitPixelsToSqm() * (self.windrowLiterPerSqm or self.literPerSqm)
	else
		return area * g_currentMission:getFruitPixelsToSqm() * self.literPerSqm
	end
end

-- Local values: toFixedLengthString, str, str, name, str, str, literPerHa, str, str, seedsPerHa, str, str, numGrowthStages, str, str, easy, str, str, medium, str, str, hard, sellPrice, str, str, plantSpacing
function FruitTypeDesc:getStatsText()
	local v156_ = self.name:sub(0, 15)
	while string.len(v156_) < 15 do
		v156_ = v156_ .. " "
	end
	local v157_ = string.format("%dl", MathUtil.round(self.literPerSqm * 10000 * 2)):sub(0, 8)
	while string.len(v157_) < 8 do
		v157_ = v157_ .. " "
	end
	local v158_ = string.format("%dl", MathUtil.round(self.seedUsagePerSqm * 10000)):sub(0, 5)
	while string.len(v158_) < 5 do
		v158_ = v158_ .. " "
	end
	local v159_ = string.format("%d", self.numGrowthStates):sub(0, 2)
	while string.len(v159_) < 2 do
		v159_ = v159_ .. " "
	end
	local v160_ = string.format("Easy: %d ", self.fillType.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[1]):sub(0, 10)
	while string.len(v160_) < 10 do
		v160_ = v160_ .. " "
	end
	local v161_ = string.format("Medium: %d ", self.fillType.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[2]):sub(0, 12)
	while string.len(v161_) < 12 do
		v161_ = v161_ .. " "
	end
	local v162_ = string.format("Hard: %d ", self.fillType.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[3]):sub(0, 11)
	while string.len(v162_) < 11 do
		v162_ = v162_ .. " "
	end
	local v163_ = v160_ .. " - " .. v161_ .. " - " .. v162_
	local v164_ = string.format("%.1fcm", self.plantSpacing * 100):sub(0, 6)
	while string.len(v164_) < 6 do
		v164_ = v164_ .. " "
	end
	return string.format("%s: Yield per ha: %s | Seeds per ha: %s | Growth stages: %s | Sell price: %s | Plant spacing: %s", v156_, v157_, v158_, v159_, v163_, v164_)
end

-- Local values: text, i, allowWeeder, allowHoe
function FruitTypeDesc:getWeedingStateText()
	local v166_ = self.name:sub(0, 15)
	while string.len(v166_) < 15 do
		v166_ = v166_ .. " "
	end
	for v167_ = 1, self.numGrowthStates do
		local v168_
		if self.minWeederState <= v167_ then
			v168_ = v167_ <= self.maxWeederState
		else
			v168_ = false
		end
		local v169_
		if self.minWeederHoeState <= v167_ then
			v169_ = v167_ <= self.maxWeederHoeState
		else
			v169_ = false
		end
		if v168_ and v169_ then
			v166_ = v166_ .. "[W | H] "
		elseif v168_ then
			v166_ = v166_ .. "[W |  ] "
		elseif v169_ then
			v166_ = v166_ .. "[  | H] "
		else
			v166_ = v166_ .. "[  |  ] "
		end
	end
	return v166_
end

-- Local values: growthState
function FruitTypeDesc:getGrowthStateByDensityState(state)
	if state == nil then
		return nil
	end
	local v172_ = self.startStateChannel
	local v173_ = bit32.rshift(state, v172_)
	local v174_ = 2 ^ self.numStateChannels - 1
	return bit32.band(v173_, v174_)
end

function FruitTypeDesc:getYieldScale(growthState)
	return self.yieldScales[growthState] or 1
end

-- Local values: groundType
function FruitTypeDesc:getDefaultSowingGroundType()
	return FieldGroundType.getByName(self.defaultSowingGroundType) or FieldGroundType.SOWN
end
