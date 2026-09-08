PlaceableHusbandryMeadow = {}
PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS = 22
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryMeadowCreateEvent.lua")
source("dataS/scripts/animals/husbandry/placeables/MeadowCreationTask.lua")

function PlaceableHusbandryMeadow.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(PlaceableHusbandryFood, specializations) and SpecializationUtil.hasSpecialization(PlaceableHusbandryFence, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
	end
	return v2_
end

function PlaceableHusbandryMeadow.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "startMeadowGrowthUpdate", PlaceableHusbandryMeadow.startMeadowGrowthUpdate)
	SpecializationUtil.registerFunction(placeableType, "finishMeadowGrowthUpdate", PlaceableHusbandryMeadow.finishMeadowGrowthUpdate)
	SpecializationUtil.registerFunction(placeableType, "getMeadowVisualFillLevels", PlaceableHusbandryMeadow.getMeadowVisualFillLevels)
	SpecializationUtil.registerFunction(placeableType, "createMeadow", PlaceableHusbandryMeadow.createMeadow)
	SpecializationUtil.registerFunction(placeableType, "getCanCreateMeadow", PlaceableHusbandryMeadow.getCanCreateMeadow)
	SpecializationUtil.registerFunction(placeableType, "finishedMeadow", PlaceableHusbandryMeadow.finishedMeadow)
	SpecializationUtil.registerFunction(placeableType, "updateMeadowVisuals", PlaceableHusbandryMeadow.updateMeadowVisuals)
	SpecializationUtil.registerFunction(placeableType, "updateMeadowInfo", PlaceableHusbandryMeadow.updateMeadowInfo)
end

function PlaceableHusbandryMeadow.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryMeadow.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getFoodInfos", PlaceableHusbandryMeadow.getFoodInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getAvailableFood", PlaceableHusbandryMeadow.getAvailableFood)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "removeFood", PlaceableHusbandryMeadow.removeFood)
end

function PlaceableHusbandryMeadow.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onFinishedFeeding", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryMeadow)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryFenceCustomizingUserLeft", PlaceableHusbandryMeadow)
end

function PlaceableHusbandryMeadow.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v8_ = basePath .. ".husbandry.meadow"
	schema:register(XMLValueType.STRING, v8_ .. ".fruitType(?)#name", "Name of the supported fruitType")
	schema:register(XMLValueType.STRING, v8_ .. ".fruitType(?)#eatableStartGrowthState", "Fruit type eatable start growth state name")
	schema:register(XMLValueType.STRING, v8_ .. ".fruitType(?)#eatableEndGrowthState", "Fruit type eatable end growth state name")
	schema:register(XMLValueType.STRING, v8_ .. ".fruitType(?)#eatenGrowthState", "Fruit type eaten growth state name")
	MeadowCreationTask.registerXMLPaths(schema, v8_ .. ".createTask")
	MeadowCreationTask.registerXMLPaths(schema, v8_ .. ".clearTask")
	schema:register(XMLValueType.NODE_INDEX, v8_ .. ".clearTask.polygon.node(?)#node", "Polygon node", nil, false)
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryMeadow.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	MeadowCreationTask.registerXMLPaths(schema, basePath .. ".createTask")
	MeadowCreationTask.registerXMLPaths(schema, basePath .. ".clearTask")
	schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Meadow filltype name")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#fillLevel", "Meadow fillevel")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#capacity", "Meadow capacity")
	schema:setXMLSpecializationType()
end

-- Local values: spec, _, fruitTypeKey, name, fruitTypeDesc, windrowFillTypeIndex, eatableStartGrowthStateName, eatableStartGrowthState, eatableEndGrowthStateName, eatableEndGrowthState, eatenGrowthStateName, eatenGrowthState, fruitTypeInfo, createTask, nodes, _, nodeKey, node, area, clearTask
function PlaceableHusbandryMeadow:onLoad(savegame)
	local v12_ = self.spec_husbandryMeadow
	v12_.canCreateMeadow = false
	v12_.foodInfo = {
		["title"] = "",
		["value"] = 0,
		["capacity"] = 0,
		["ratio"] = 0,
		["ignoreCapacity"] = true
	}
	v12_.info = {
		["title"] = g_i18n:getText("animals_husbandryMeadowFood"),
		["value"] = 0,
		["capacity"] = 0,
		["ratio"] = 0
	}
	v12_.fillLevels = {}
	v12_.dirtyFillLevels = {}
	v12_.capacities = {}
	v12_.productionWeight = 0
	v12_.dirtyFlag = self:getNextDirtyFlag()
	v12_.fruitTypeInfos = {}
	v12_.fruitTypeEatFilters = {}
	v12_.eatFilterMaxValue = 10000
	for _, v13_ in self.xmlFile:iterator("placeable.husbandry.meadow.fruitType") do
		local v14_ = self.xmlFile:getValue(v13_ .. "#name")
		local v15_ = g_fruitTypeManager:getFruitTypeByName(v14_)
		if v15_ ~= nil then
			local v16_ = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(v15_.index)
			v12_.fillLevels[v16_] = 0
			v12_.capacities[v16_] = 0
			local v17_ = self.xmlFile:getValue(v13_ .. "#eatableStartGrowthState")
			if v17_ == nil then
				Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableStartGrowthState missing!")
			else
				local v18_ = v15_:getGrowthStateByName(v17_)
				if v18_ == nil then
					Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableStartGrowthState \'%s\' not defined!", v17_)
				else
					local v19_ = self.xmlFile:getValue(v13_ .. "#eatableEndGrowthState")
					if v19_ == nil then
						Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableEndGrowthState missing!")
					else
						local v20_ = v15_:getGrowthStateByName(v19_)
						if v20_ == nil then
							Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableEndGrowthState \'%s\' not defined!", v19_)
						else
							local v21_ = self.xmlFile:getValue(v13_ .. "#eatenGrowthState")
							if v21_ == nil then
								Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatenGrowthState missing!")
							else
								local v22_ = v15_:getGrowthStateByName(v21_)
								if v22_ == nil then
									Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatenGrowthState \'%s\' not defined!", v21_)
								else
									local v23_ = v12_.fruitTypeInfos
									table.insert(v23_, {
										["fruitType"] = v15_,
										["eatableStartGrowthState"] = v18_,
										["eatableEndGrowthState"] = v20_,
										["eatenGrowthState"] = v22_,
										["fillTypeIndex"] = v16_
									})
								end
							end
						end
					end
				end
			end
		end
	end
	if self.xmlFile:hasProperty("placeable.husbandry.meadow.createTask") then
		local v24_ = MeadowCreationTask.new()
		if v24_:loadFromXMLFile(self.xmlFile, "placeable.husbandry.meadow.createTask") then
			v24_:setName("HusbandryMeadowCreate")
			v24_:setNeedsSaving(false)
			v12_.createTask = v24_
		end
		v12_.canCreateMeadow = true
	end
	if self.xmlFile:hasProperty("placeable.husbandry.meadow.clearTask") then
		local v25_ = {}
		for _, v26_ in self.xmlFile:iterator("placeable.husbandry.meadow.clearTask.polygon.node") do
			local v27_ = self.xmlFile:getValue(v26_ .. "#node", nil, self.components, self.i3dMappings)
			if v27_ ~= nil then
				table.insert(v25_, v27_)
			end
		end
		local v28_ = DensityMapPolygon.createFromNodes(v25_)
		if v28_ ~= nil then
			local v29_ = MeadowCreationTask.new()
			v29_:setArea(v28_)
			if v29_:loadFromXMLFile(self.xmlFile, "placeable.husbandry.meadow.clearTask") then
				v29_:setName("HusbandryMeadowClear")
				v29_:setNeedsSaving(false)
				v12_.clearTask = v29_
				v12_.canCreateMeadow = true
			end
		end
	end
end

-- Local values: spec, productionWeight, animalTypeIndex, animalType, animalFood, i, fruitTypeInfo, found, _, foodGroup, _, fillTypeIndex
function PlaceableHusbandryMeadow:onPostLoad()
	local v31_ = self.spec_husbandryMeadow
	local v32_ = nil
	local v33_ = self:getAnimalTypeIndex()
	local v34_ = g_currentMission.animalSystem:getTypeByIndex(v33_)
	local v35_ = g_currentMission.animalFoodSystem:getAnimalFood(v33_)
	if v35_ ~= nil then
		for v36_ = #v31_.fruitTypeInfos, 1, -1 do
			local v37_ = v31_.fruitTypeInfos[v36_]
			local v38_ = false
			for _, v39_ in pairs(v35_.groups) do
				for _, v40_ in pairs(v39_.fillTypes) do
					if v40_ == v37_.fillTypeIndex then
						if v32_ == nil then
							v32_ = v39_.productionWeight
						end
						local v41_ = v39_.productionWeight
						v32_ = math.min(v32_, v41_)
						v38_ = true
					end
				end
				if v38_ then
					break
				end
			end
			if not v38_ then
				Logging.devWarning("FruitType \'%s\' is not supported by animal type \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(v37_.fillTypeIndex), v34_.groupTitle)
				table.remove(v31_.fruitTypes, v36_)
			end
		end
	end
	if v32_ ~= nil and v32_ > 0 then
		v31_.productionWeight = v32_
		v31_.foodInfo.title = string.format("%s (%d%%)", g_i18n:getText("animals_husbandryMeadowFood"), MathUtil.round(v31_.productionWeight * 100))
	end
end

-- Local values: spec
function PlaceableHusbandryMeadow:onDelete()
	local v43_ = self.spec_husbandryMeadow
	if v43_.pendingCreateTask ~= nil then
		v43_.pendingCreateTask:cancel()
	end
	if v43_.pendingClearTask ~= nil then
		v43_.pendingClearTask:cancel()
	end
	g_messageCenter:unsubscribe(MessageType.START_GROWTH_PERIOD, self)
	g_messageCenter:unsubscribe(MessageType.FINISHED_GROWTH_PERIOD, self)
end

-- Local values: spec, numBits, fillTypeIndex, filLLevel
function PlaceableHusbandryMeadow:onReadStream(streamId, connection)
	local v46_ = self.spec_husbandryMeadow
	local v47_ = PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS
	for v48_, _ in pairs(v46_.fillLevels) do
		v46_.fillLevels[v48_] = streamReadUIntN(streamId, v47_)
		v46_.capacities[v48_] = streamReadUIntN(streamId, v47_)
	end
	self:updateMeadowInfo()
end

-- Local values: spec, numBits, fillTypeIndex, fillLevel
function PlaceableHusbandryMeadow:onWriteStream(streamId, connection)
	local v51_ = self.spec_husbandryMeadow
	local v52_ = PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS
	for v53_, v54_ in pairs(v51_.fillLevels) do
		streamWriteUIntN(streamId, v54_, v52_)
		streamWriteUIntN(streamId, v51_.capacities[v53_], v52_)
	end
end

-- Local values: spec, numBits, fillTypeIndex, filLLevel
function PlaceableHusbandryMeadow:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v58_ = self.spec_husbandryMeadow
		if streamReadBool(streamId) then
			local v59_ = PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS
			for v60_, _ in pairs(v58_.fillLevels) do
				v58_.fillLevels[v60_] = streamReadUIntN(streamId, v59_)
				v58_.capacities[v60_] = streamReadUIntN(streamId, v59_)
			end
			self:updateMeadowInfo()
		end
	end
end

-- Local values: spec, numBits, fillTypeIndex, fillLevel
function PlaceableHusbandryMeadow:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v65_ = self.spec_husbandryMeadow
		local v66_ = streamWriteBool
		local v67_ = v65_.dirtyFlag
		if v66_(streamId, bit32.band(dirtyMask, v67_) ~= 0) then
			local v68_ = PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS
			for v69_, v70_ in pairs(v65_.fillLevels) do
				streamWriteUIntN(streamId, v70_, v68_)
				streamWriteUIntN(streamId, v65_.capacities[v69_], v68_)
			end
		end
	end
end

-- Local values: spec, found, _, fillLevelKey, fillTypeName, fillTypeIndex, fillLevel, capacity, fieldTaskKey, createTask, clearTaskKey, clearTask
function PlaceableHusbandryMeadow:loadFromXMLFile(xmlFile, key)
	local v74_ = self.spec_husbandryMeadow
	local v75_ = false
	for _, v76_ in xmlFile:iterator(key .. ".fillType") do
		local v77_ = xmlFile:getValue(v76_ .. "#name")
		if v77_ ~= nil then
			local v78_ = g_fillTypeManager:getFillTypeIndexByName(v77_)
			if v78_ ~= nil and v74_.fillLevels[v78_] ~= nil then
				local v79_ = xmlFile:getValue(v76_ .. "#fillLevel")
				local v80_ = xmlFile:getValue(v76_ .. "#capacity")
				v74_.fillLevels[v78_] = v79_ or v74_.fillLevels[v78_]
				v74_.capacities[v78_] = v80_ or v74_.capacities[v78_]
				v75_ = true
			end
		end
	end
	v74_.isMeadowInfoDirty = not v75_
	self:updateMeadowInfo()
	local v81_ = key .. ".createTask"
	if xmlFile:hasProperty(v81_) then
		local v82_ = MeadowCreationTask.new()
		if v82_:loadFromXMLFile(xmlFile, v81_) then
			v82_:setNeedsSaving(false)
			v82_:enqueue()
			v74_.pendingCreateTask = v82_
		end
	end
	local v83_ = key .. ".clearTask"
	if xmlFile:hasProperty(v83_) then
		local v84_ = MeadowCreationTask.new()
		if v84_:loadFromXMLFile(xmlFile, v83_) then
			v84_:setNeedsSaving(false)
			v84_:enqueue()
			v74_.pendingClearTask = v84_
		end
	end
	if v74_.pendingCreateTask == nil and v74_.pendingClearTask == nil then
		g_messageCenter:subscribe(MessageType.START_GROWTH_PERIOD, self.startMeadowGrowthUpdate, self)
		g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.finishMeadowGrowthUpdate, self)
	end
end

-- Local values: spec, index, fillTypeIndex, fillLevel, fillTypeName, fillLevelKey
function PlaceableHusbandryMeadow:saveToXMLFile(xmlFile, key, usedModNames)
	local v88_ = self.spec_husbandryMeadow
	local v89_ = 0
	for v90_, v91_ in pairs(v88_.fillLevels) do
		local v92_ = g_fillTypeManager:getFillTypeNameByIndex(v90_)
		if v92_ ~= nil then
			local v93_ = string.format("%s.fillType(%d)", key, v89_)
			xmlFile:setValue(v93_ .. "#name", v92_)
			xmlFile:setValue(v93_ .. "#fillLevel", v91_)
			xmlFile:setValue(v93_ .. "#capacity", v88_.capacities[v90_] or 0)
			v89_ = v89_ + 1
		end
	end
	if v88_.pendingCreateTask ~= nil then
		v88_.pendingCreateTask:saveToXMLFile(xmlFile, key .. ".createTask")
	end
	if v88_.pendingClearTask ~= nil then
		v88_.pendingClearTask:saveToXMLFile(xmlFile, key .. ".clearTask")
	end
end

-- Local values: spec
function PlaceableHusbandryMeadow:onUpdate(dt)
	if self.isServer then
		local v95_ = self.spec_husbandryMeadow
		if v95_.pendingCreateTask ~= nil then
			if v95_.pendingCreateTask:getIsFinished() then
				v95_.pendingCreateTask = nil
				if v95_.clearTask == nil then
					self:finishedMeadow()
				else
					v95_.pendingClearTask = v95_.clearTask
					v95_.pendingClearTask:enqueue()
				end
			end
			self:raiseActive()
		end
		if v95_.pendingClearTask ~= nil then
			if v95_.pendingClearTask:getIsFinished() then
				v95_.pendingClearTask = nil
				self:finishedMeadow()
			end
			self:raiseActive()
		end
	end
end

-- Local values: spec
function PlaceableHusbandryMeadow:getCanCreateMeadow()
	return self.spec_husbandryMeadow.canCreateMeadow
end

-- Local values: spec, polygon, createTask, enlargedPolygon, densityMapPolygon, tipCollisionFilter
function PlaceableHusbandryMeadow:createMeadow(doCreateMeadow, noEventSend)
	HusbandryMeadowCreateEvent.sendEvent(self, doCreateMeadow, noEventSend)
	if doCreateMeadow then
		if self.isServer then
			local v100_ = self.spec_husbandryMeadow
			local v101_ = self:getOutdoorContourPolygon()
			local v102_ = v100_.createTask
			if v101_ ~= nil and v102_ ~= nil then
				local v103_ = v101_:getOffsetPolygon(0.5)
				if v103_ == nil then
					Logging.warning("PlaceableHusbandryMeadow.createMeadow: Could not shrink polygon for creation task. Please double check order of fence segments and direction")
				else
					local v104_ = DensityMapPolygon.new()
					v104_:updateFromPolygon2D(v103_)
					DensityMapFilter.new(g_densityMapHeightManager.tipCollisionMap, 0, 2):setValueCompareParams(DensityValueCompareType.EQUAL, 0)
					v102_:setArea(v104_)
					if PlaceableHusbandryAnimals and PlaceableHusbandryAnimals.debugEnabled then
						v104_:visualize(120000, "PlaceableHusbandryMeadow")
					end
					v102_:enqueue()
					v100_.pendingCreateTask = v102_
					self:raiseActive()
				end
			end
			self:finishedMeadow()
		end
	else
		self:finishedMeadow()
	end
end

-- Local values: spec, fillLevels, capacities, fillTypeIndex, fillLevel
function PlaceableHusbandryMeadow:finishedMeadow()
	if self.isServer then
		local v106_ = self.spec_husbandryMeadow
		local v107_, v108_ = self:getMeadowVisualFillLevels()
		if v107_ ~= nil then
			for v109_, v110_ in pairs(v107_) do
				v106_.fillLevels[v109_] = v110_
				v106_.capacities[v109_] = v108_[v109_]
			end
		end
		self:updateMeadowInfo()
		self:raiseDirtyFlags(v106_.dirtyFlag)
		g_messageCenter:subscribe(MessageType.START_GROWTH_PERIOD, self.startMeadowGrowthUpdate, self)
		g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.finishMeadowGrowthUpdate, self)
	end
end

-- Local values: spec, fillLevels, capacities, fillTypeIndex, fillLevel
function PlaceableHusbandryMeadow:onHusbandryAnimalsCreated()
	local v112_ = self.spec_husbandryMeadow
	if v112_.isMeadowInfoDirty then
		local v113_, v114_ = self:getMeadowVisualFillLevels()
		if v113_ ~= nil then
			for v115_, v116_ in pairs(v113_) do
				v112_.fillLevels[v115_] = v116_
				v112_.capacities[v115_] = v114_[v115_]
			end
			self:updateMeadowInfo()
		end
	end
end

function PlaceableHusbandryMeadow:onHusbandryFenceCustomizingUserLeft()
	self:createMeadow(true)
end

-- Local values: spec
function PlaceableHusbandryMeadow:startMeadowGrowthUpdate()
	if self.isServer then
		local v119_ = self.spec_husbandryMeadow
		local v120_, v121_ = self:getMeadowVisualFillLevels()
		v119_.growthStartFillLevels = v120_
		v119_.growthStartCapacities = v121_
	end
end

-- Local values: spec, growthEndFillLevels, growthEndCapacities, fillTypeIndex, fillLevel, delta
function PlaceableHusbandryMeadow:finishMeadowGrowthUpdate()
	if self.isServer then
		local v123_ = self.spec_husbandryMeadow
		local v124_, v125_ = self:getMeadowVisualFillLevels()
		if v123_.growthStartFillLevels ~= nil and v124_ ~= nil then
			for v126_, v127_ in pairs(v124_) do
				local v128_ = v127_ - v123_.growthStartFillLevels[v126_]
				if v127_ == v125_[v126_] then
					v128_ = v125_[v126_]
				end
				local v129_ = v123_.fillLevels
				local v130_ = v123_.fillLevels[v126_] + v128_
				local v131_ = v125_[v126_]
				v129_[v126_] = math.clamp(v130_, 0, v131_)
			end
			self:updateMeadowInfo()
		end
	end
end

-- Local values: spec, polygon, densityMapPolygon, capacities, fillLevels, _, fruitTypeInfo, fruitType, fillTypeIndex, modifier, filter, _, pixels, _, fruitCapacity, fruitFillLevel, _, eatablePixels, _
function PlaceableHusbandryMeadow:getMeadowVisualFillLevels()
	local v133_ = self.spec_husbandryMeadow
	local v134_ = self:getOutdoorContourPolygon()
	if v134_ == nil then
		return nil, nil
	end
	local v135_ = DensityMapPolygon.new()
	v135_:updateFromPolygon2D(v134_)
	local v136_ = {}
	local v137_ = {}
	for _, v138_ in ipairs(v133_.fruitTypeInfos) do
		local v139_ = v138_.fruitType
		local v140_ = v138_.fillTypeIndex
		if v136_[v140_] == nil then
			v136_[v140_] = 0
			v137_[v140_] = 0
		end
		local v141_ = v139_:getModifier()
		if v141_ ~= nil then
			local v142_ = DensityMapFilter.new(v141_)
			v142_:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, v138_.eatableEndGrowthState)
			v135_:applyToModifier(v141_)
			local _, v143_, _ = v141_:executeGet(v142_)
			local v144_ = g_fruitTypeManager:getFruitTypeAreaLiters(v139_.index, v143_, true)
			v137_[v140_] = v137_[v140_] + v144_
			local v145_
			if v144_ > 0 then
				v142_:setValueCompareParams(DensityValueCompareType.BETWEEN, v138_.eatableStartGrowthState, v138_.eatableEndGrowthState)
				local _, v146_, _ = v141_:executeGet(v142_)
				v145_ = g_fruitTypeManager:getFruitTypeAreaLiters(v139_.index, v146_, true)
			else
				v145_ = 0
			end
			v136_[v140_] = v136_[v140_] + v145_
		end
	end
	return v136_, v137_
end

function PlaceableHusbandryMeadow:onMeadowFinishedGrowthPeriod()
	self:updateMeadowCapacity()
end
function PlaceableHusbandryMeadow.removeFood(p148_, p149_, p150_, p151_)
	local v152_ = p149_(p148_, p150_, p151_)
	local v153_ = p150_ - v152_
	if v153_ > 0 then
		local v154_ = p148_.spec_husbandryMeadow
		local v155_ = v154_.fillLevels[p151_]
		if v155_ ~= nil then
			local v156_ = math.min(v155_, v153_)
			v154_.fillLevels[p151_] = v155_ - v156_
			v152_ = v152_ + v156_
			v154_.dirtyFillLevels[p151_] = true
			p148_:raiseDirtyFlags(v154_.dirtyFlag)
			p148_:updateMeadowInfo()
		end
	end
	return v152_
end

-- Local values: spec, fillLevel, capacity, fillTypeIndex, level, ratio, foodInfo, info
function PlaceableHusbandryMeadow:updateMeadowInfo()
	local v158_ = self.spec_husbandryMeadow
	local v159_ = 0
	local v160_ = 0
	for v161_, v162_ in pairs(v158_.fillLevels) do
		v159_ = v159_ + v162_
		v160_ = v160_ + v158_.capacities[v161_]
	end
	local v163_ = v160_ <= 0 and 0 or v159_ / v160_
	local v164_ = v158_.foodInfo
	v164_.value = v159_
	v164_.capacity = v160_
	v164_.ratio = v163_
	local v165_ = v158_.info
	v165_.value = v159_
	v165_.capacity = v160_
	v165_.ratio = v163_
	v165_.text = string.format("%d l", v159_)
end

function PlaceableHusbandryMeadow:onFinishedFeeding()
	if self.isServer then
		self:updateMeadowVisuals()
	end
end

-- Local values: polygon, densityMapPolygon, updatedFillTypes, spec, _, fruitTypeInfo, fruitType, fruitTypeIndex, fillTypeIndex, fillLevel, capacity, ratio, modifier, filter, eatFilter, maxFilterValue, fillTypeIndex, _
function PlaceableHusbandryMeadow:updateMeadowVisuals()
	local v168_ = self:getOutdoorContourPolygon()
	if v168_ ~= nil then
		local v169_ = DensityMapPolygon.new()
		v169_:updateFromPolygon2D(v168_)
		local v170_ = self.spec_husbandryMeadow
		local v171_ = {}
		for _, v172_ in ipairs(v170_.fruitTypeInfos) do
			local v173_ = v172_.fruitType
			local v174_ = v173_.index
			local v175_ = v172_.fillTypeIndex
			if v170_.dirtyFillLevels[v175_] then
				local v176_ = v170_.fillLevels[v175_]
				local v177_ = v170_.capacities[v175_]
				if v177_ > 0 then
					local v178_ = 1 - v176_ / v177_
					local v179_ = v173_:getModifier()
					v169_:applyToModifier(v179_)
					if v179_ ~= nil then
						local v180_ = DensityMapFilter.new(v179_)
						v180_:setValueCompareParams(DensityValueCompareType.BETWEEN, v172_.eatableStartGrowthState, v172_.eatableEndGrowthState)
						local v181_ = v170_.fruitTypeEatFilters[v174_]
						if v181_ == nil then
							v181_ = PerlinNoiseFilter.new(v179_, 11, 1, 0.5, math.random(0, 10000))
							v170_.fruitTypeEatFilters[v174_] = v181_
						end
						local v182_ = v178_ * v170_.eatFilterMaxValue
						local v183_ = math.ceil(v182_)
						v181_:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, v183_)
						v179_:executeSet(v172_.eatenGrowthState, v180_, v181_)
					end
				end
				v171_[v175_] = true
			end
		end
		for v184_, _ in pairs(v171_) do
			v170_.dirtyFillLevels[v184_] = nil
		end
	end
end

-- Local values: spec, fillLevel, meadowFillLevel
function PlaceableHusbandryMeadow:getAvailableFood(superFunc, fillTypeIndex)
	local v188_ = self.spec_husbandryMeadow
	local v189_ = superFunc(self, fillTypeIndex)
	local v190_ = v188_.fillLevels[fillTypeIndex]
	if v190_ ~= nil then
		v189_ = (v189_ or 0) + v190_
	end
	return v189_
end

-- Local values: foodInfos, spec
function PlaceableHusbandryMeadow:getFoodInfos(superFunc)
	local v193_ = superFunc(self)
	local v194_ = self.spec_husbandryMeadow
	if #v194_.fruitTypeInfos > 0 then
		local v195_ = v194_.foodInfo
		table.insert(v193_, v195_)
	end
	return v193_
end

-- Local values: spec
function PlaceableHusbandryMeadow:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v199_ = self.spec_husbandryMeadow
	if #v199_.fruitTypeInfos > 0 then
		local v200_ = v199_.info
		table.insert(infoTable, v200_)
	end
end
